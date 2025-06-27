// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {AccessManagedUpgradeable} from "@openzeppelin/contracts-upgradeable/access/manager/AccessManagedUpgradeable.sol";
import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {ERC20PermitUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20PermitUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {ERC4626Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC4626Upgradeable.sol";
import {IPool} from "../../interfaces/pool/IPool.sol";

contract ColEUR is
    Initializable,
    AccessManagedUpgradeable,
    ERC4626Upgradeable,
    ERC20PermitUpgradeable,
    UUPSUpgradeable
{
    using SafeERC20 for IERC20;

    /// @custom:storage-location erc7201:Zeur.storage.ColEUR
    struct ColEURStorage {
        IPool _pool;
    }

    // keccak256(abi.encode(uint256(keccak256("Zeur.storage.ColEUR")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant ColEURStorageLocation =
        0xd4cd727e9732e147334cab66ea647bdf582d7e5ddb3a56e1957e6b5f21f8b900;

    function _getColEURStorage()
        private
        pure
        returns (ColEURStorage storage $)
    {
        assembly {
            $.slot := ColEURStorageLocation
        }
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address initialAuthority,
        string memory name,
        string memory symbol,
        IERC20 asset,
        address pool
    ) public initializer {
        __AccessManaged_init(initialAuthority);
        __ERC4626_init(asset);
        __ERC20_init(name, symbol);
        __ERC20Permit_init(name);
        __UUPSUpgradeable_init();

        ColEURStorage storage $ = _getColEURStorage();
        $._pool = IPool(pool);
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override restricted {}

    function decimals()
        public
        view
        override(ERC20Upgradeable, ERC4626Upgradeable)
        returns (uint8)
    {
        return IERC20Metadata(asset()).decimals(); // ColEUR has the same decimals as the underlying asset
    }

    function mint(
        uint256 shares,
        address receiver
    ) public override restricted returns (uint256) {
        return super.mint(shares, receiver);
    }

    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) public virtual override restricted returns (uint256) {
        return super.redeem(shares, receiver, owner);
    }

    function deposit(
        uint256 assets,
        address receiver
    ) public override restricted returns (uint256) {
        return super.deposit(assets, receiver);
    }

    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) public override restricted returns (uint256) {
        return super.withdraw(assets, receiver, owner);
    }

    function totalAssets() public view override returns (uint256) {
        ColEURStorage storage $ = _getColEURStorage();
        IPool.DebtConfiguration memory debtConfiguration = $
            ._pool
            .getDebtAssetConfiguration(this.asset());
        uint256 totalAssetOnColEUR = super.totalAssets();
        uint256 totalAssetBorrowed = IERC20(debtConfiguration.debtToken)
            .totalSupply();

        // Total EURC is total EURC balance of this ERC4626 and total EURC loaned out
        return totalAssetOnColEUR + totalAssetBorrowed;
    }

    // Function used by Pool contract to transfer the underlying token to borrower
    function transferTokenTo(address to, uint256 amount) external restricted {
        IERC20(asset()).safeTransfer(to, amount);
    }
}
