// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {ETH_ADDRESS} from "../../helpers/Constants.sol";
import {ILiquidityPool} from "../../interfaces/lst/etherfi/ILiquidityPool.sol";
import {IStakingRouter} from "../../interfaces/router/IStakingRouter.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {AccessManagedUpgradeable} from "@openzeppelin/contracts-upgradeable/access/manager/AccessManagedUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract StakingRouterETHEtherfi is
    Initializable,
    AccessManagedUpgradeable,
    UUPSUpgradeable,
    IStakingRouter
{
    using SafeERC20 for IERC20;

    /// @custom:storage-location erc7201:Zeur.storage.StakingRouterETHEtherfi
    struct StakingRouterETHEtherfiStorage {
        uint256 _totalStakedUnderlying;
        address _underlyingToken; // Underlying token
        IERC20 _eETH; // LST token
        ILiquidityPool _liquidityPool;
    }

    // keccak256(abi.encode(uint256(keccak256("Zeur.storage.StakingRouterETHEtherfi")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant StakingRouterETHEtherfiStorageLocation =
        0x29f638b2585ff610b30bee43f42505dcdeabddacb4fbb85bcba27eeeb7d6f100;

    function _getStakingRouterETHEtherfiStorage()
        private
        pure
        returns (StakingRouterETHEtherfiStorage storage $)
    {
        assembly {
            $.slot := StakingRouterETHEtherfiStorageLocation
        }
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address initialAuthority,
        address eETH,
        address liquidityPool
    ) public initializer {
        __AccessManaged_init(initialAuthority);
        __UUPSUpgradeable_init();

        StakingRouterETHEtherfiStorage
            storage $ = _getStakingRouterETHEtherfiStorage();

        $._underlyingToken = ETH_ADDRESS;
        $._eETH = IERC20(eETH);
        $._liquidityPool = ILiquidityPool(liquidityPool);
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override restricted {}

    function stake(address from, uint256 amount) external payable restricted {
        StakingRouterETHEtherfiStorage
            storage $ = _getStakingRouterETHEtherfiStorage();

        $._totalStakedUnderlying += amount;

        uint256 shares = $._liquidityPool.deposit{value: amount}();

        $._eETH.safeTransfer(from, shares);
    }

    function unstake(address to, uint256 amount) external restricted {
        StakingRouterETHEtherfiStorage
            storage $ = _getStakingRouterETHEtherfiStorage();

        $._totalStakedUnderlying -= amount;

        // Transfer eETH from VaultETH to the router
        $._eETH.safeTransferFrom(msg.sender, address(this), amount);

        // Approve then withdraw ETH to "to"
        $._eETH.forceApprove(address($._liquidityPool), amount);
        $._liquidityPool.withdraw(to, amount);
    }

    function getExchangeRate() external pure returns (uint256) {
        return 1e18; // 1 ETH = 1 eETH
    }

    function getStakedToken() external view returns (address) {
        StakingRouterETHEtherfiStorage
            storage $ = _getStakingRouterETHEtherfiStorage();

        return address($._eETH);
    }

    function getStakedTokenAndExchangeRate()
        external
        view
        returns (address, uint256)
    {
        StakingRouterETHEtherfiStorage
            storage $ = _getStakingRouterETHEtherfiStorage();

        return (address($._eETH), 1e18); // 1 ETH = 1 eETH
    }

    function getUnderlyingToken() external view returns (address) {
        StakingRouterETHEtherfiStorage
            storage $ = _getStakingRouterETHEtherfiStorage();

        return $._underlyingToken;
    }

    function getTotalStakedUnderlying() external view returns (uint256) {
        StakingRouterETHEtherfiStorage
            storage $ = _getStakingRouterETHEtherfiStorage();

        return $._totalStakedUnderlying;
    }
}
