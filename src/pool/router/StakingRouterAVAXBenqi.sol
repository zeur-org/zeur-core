// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {IsAVAX} from "../../interfaces/lst/avax/IsAVAX.sol";
import {IStakingRouter} from "../../interfaces/router/IStakingRouter.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {AccessManagedUpgradeable} from "@openzeppelin/contracts-upgradeable/access/manager/AccessManagedUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract StakingRouterAVAXBenqi is
    Initializable,
    AccessManagedUpgradeable,
    UUPSUpgradeable,
    IStakingRouter
{
    using SafeERC20 for IERC20;

    // Convention address for handling native
    address public constant AVAX_ADDRESS =
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /// @custom:storage-location erc7201:Zeur.storage.StakingRouterAVAXBenqi
    struct StakingRouterAVAXBenqiStorage {
        uint256 _totalStakedUnderlying;
        address _underlyingToken; // Underlying token
        IsAVAX _sAVAX; // LST token
    }

    // keccak256(abi.encode(uint256(keccak256("Zeur.storage.StakingRouterAVAXBenqi")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant StakingRouterAVAXBenqiStorageLocation =
        0x281be2edb8cdbb8592a85c1295d30422d59cb8147b1daec11c5d40f93fd0a900;

    function _getStakingRouterAVAXBenqiStorage()
        private
        pure
        returns (StakingRouterAVAXBenqiStorage storage $)
    {
        assembly {
            $.slot := StakingRouterAVAXBenqiStorageLocation
        }
    }

    receive() external payable {}

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address initialAuthority,
        address stAVAX
    ) public initializer {
        __AccessManaged_init(initialAuthority);
        __UUPSUpgradeable_init();

        StakingRouterAVAXBenqiStorage
            storage $ = _getStakingRouterAVAXBenqiStorage();

        $._underlyingToken = AVAX_ADDRESS;
        $._sAVAX = IsAVAX(stAVAX);
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override restricted {}

    function stake(address from, uint256 amount) external payable restricted {
        StakingRouterAVAXBenqiStorage
            storage $ = _getStakingRouterAVAXBenqiStorage();

        $._totalStakedUnderlying += amount;

        uint256 stAVAXAmount = $._sAVAX.submit{value: amount}();

        IERC20(address($._sAVAX)).safeTransfer(from, stAVAXAmount);
    }

    function unstake(address to, uint256 amount) external restricted {
        StakingRouterAVAXBenqiStorage
            storage $ = _getStakingRouterAVAXBenqiStorage();

        $._totalStakedUnderlying -= amount;

        IERC20 stAVAX = IERC20(address($._sAVAX));

        stAVAX.safeTransferFrom(msg.sender, address(this), amount);

        $._sAVAX.withdraw(amount);

        // Transfer AVAX to user
        (bool success, ) = payable(to).call{value: amount}("");
        if (!success) revert StakingRouter_FailedToTransfer();
    }

    function getExchangeRate() external pure returns (uint256) {
        return 1e18; // 1 AVAX = 1 stAVAX
    }

    function getStakedToken() external view returns (address) {
        StakingRouterAVAXBenqiStorage
            storage $ = _getStakingRouterAVAXBenqiStorage();

        return address($._sAVAX);
    }

    function getStakedTokenAndExchangeRate()
        external
        view
        returns (address, uint256)
    {
        StakingRouterAVAXBenqiStorage
            storage $ = _getStakingRouterAVAXBenqiStorage();

        return (address($._sAVAX), 1e18); // 1 AVAX = 1 stAVAX
    }

    function getUnderlyingToken() external view returns (address) {
        StakingRouterAVAXBenqiStorage
            storage $ = _getStakingRouterAVAXBenqiStorage();

        return $._underlyingToken;
    }

    function getTotalStakedUnderlying() external view returns (uint256) {
        StakingRouterAVAXBenqiStorage
            storage $ = _getStakingRouterAVAXBenqiStorage();

        return $._totalStakedUnderlying;
    }
}
