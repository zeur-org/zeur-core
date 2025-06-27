// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {IPool} from "../../interfaces/pool/IPool.sol";
import {IVault} from "../../interfaces/vault/IVault.sol";
import {IProtocolVaultManager} from "../../interfaces/pool/IProtocolVaultManager.sol";
import {IStakingRouter} from "../../interfaces/router/IStakingRouter.sol";
import {ISwapRouter} from "../../interfaces/swap/ISwapRouter.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {AccessManagedUpgradeable} from "@openzeppelin/contracts-upgradeable/access/manager/AccessManagedUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract ProtocolVaultManager is
    Initializable,
    AccessManagedUpgradeable,
    UUPSUpgradeable,
    IProtocolVaultManager
{
    using SafeERC20 for IERC20;

    /// @custom:storage-location erc7201:Zeur.storage.ProtocolVaultManager
    struct ProtocolVaultManagerStorage {
        IPool _pool;
    }

    // keccak256(abi.encode(uint256(keccak256("Zeur.storage.ProtocolVaultManager")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant ProtocolVaultManagerStorageLocation =
        0x2df4395fe5d68f5ba01527b319bbde00044e704b1248be80415e6ccfb1598c00;

    function _getProtocolVaultManagerStorage()
        private
        pure
        returns (ProtocolVaultManagerStorage storage $)
    {
        assembly {
            $.slot := ProtocolVaultManagerStorageLocation
        }
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address initialAuthority,
        address pool
    ) public initializer {
        __AccessManaged_init(initialAuthority);
        __UUPSUpgradeable_init();

        ProtocolVaultManagerStorage
            storage $ = _getProtocolVaultManagerStorage();
        $._pool = IPool(pool);
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override restricted {}

    function distributeYield(address asset) external {
        ProtocolVaultManagerStorage
            storage $ = _getProtocolVaultManagerStorage();

        IPool.DebtConfiguration memory debtConfiguration = $
            ._pool
            .getDebtAssetConfiguration(asset);
        address colToken = debtConfiguration.colToken;

        if (colToken == address(0))
            revert ProtocolVaultManager__NotDebtAsset(asset);

        uint256 amount = IERC20(asset).balanceOf(address(this));
        IERC20(asset).safeTransfer(colToken, amount);

        emit YieldDistributed(address(this), asset, colToken, amount);
    }

    // TODO add restrict after testing
    function harvestYield(
        address router,
        address debtAsset,
        address swapRouter
    ) external returns (uint256 debtReceived) {
        // Check if the debt asset is supported
        ProtocolVaultManagerStorage
            storage $ = _getProtocolVaultManagerStorage();
        IPool.DebtConfiguration memory debtConfiguration = $
            ._pool
            .getDebtAssetConfiguration(debtAsset);

        address colToken = debtConfiguration.colToken;
        if (colToken == address(0))
            revert ProtocolVaultManager__NotDebtAsset(debtAsset);

        IVault vault = IVault(debtConfiguration.colToken);

        // Harvest yield from vaultETH
        (address lstToken, uint256 yieldAmount) = vault.harvestYield(router);
        if (yieldAmount == 0) return 0;

        // Swap yield amount of LST to EURC, then transfer EURC to colEURC
        // Perform the swap
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: lstToken,
                tokenOut: debtAsset,
                fee: 100, // Pool 0.01%
                recipient: colToken,
                deadline: block.timestamp + 300, // 5 minutes
                amountIn: yieldAmount,
                amountOutMinimum: 0, // Need slippage protection for prod
                sqrtPriceLimitX96: 0
            });

        // Approve LST for Uniswap router
        IERC20(lstToken).forceApprove(swapRouter, yieldAmount);

        try ISwapRouter(swapRouter).exactInputSingle(params) returns (
            uint256 amountOut
        ) {
            debtReceived = amountOut;
        } catch {
            revert ProtocolVaultManager__HarvestYieldFailed(
                router,
                debtAsset,
                swapRouter
            );
        }

        emit YieldDistributed(router, debtAsset, colToken, debtReceived);
    }

    function rebalance() external restricted {
        // TODO: Implement rebalance
    }
}
