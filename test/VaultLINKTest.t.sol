// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {VaultLINK} from "../src/pool/vault/VaultLINK.sol";
import {VaultLINKV2} from "./mock/VaultLINKV2.sol";
import {TestSetupLocalHelpers} from "./helpers/TestSetupLocalHelpers.s.sol";
import {IAccessManaged} from "@openzeppelin/contracts/access/manager/IAccessManaged.sol";
import {VAULT_ADMIN, INITIAL_ADMIN} from "../src/helpers/Constants.sol";
import {Roles} from "../src/helpers/Roles.sol";
import {ETH_ADDRESS} from "../src/helpers/Constants.sol";
import {ColToken} from "../src/pool/tokenization/ColToken.sol";
import {StakingRouterLINK} from "../src/pool/router/StakingRouterLINK.sol";
import {IVault} from "../src/interfaces/vault/IVault.sol";
import {ProtocolAccessManager} from "../src/pool/manager/ProtocolAccessManager.sol";
import {MockERC20} from "./helpers/TestMockHelpers.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";

contract VaultLINKTest is Test {
    MockERC20 private linkToken;
    VaultLINK private vaultLINK;
    ColToken private colLINK;
    StakingRouterLINK private routerLINK;
    ProtocolAccessManager private accessManager;

    address public alice = makeAddr("alice");
    address public bob = makeAddr("bob");
    address public vaultAdmin = VAULT_ADMIN;
    address public initialAdmin = INITIAL_ADMIN;

    function setUp() public {
        TestSetupLocalHelpers setup = new TestSetupLocalHelpers();

        (
            TestSetupLocalHelpers.CoreContracts memory coreContracts,
            TestSetupLocalHelpers.TokenizationContracts
                memory tokenizationContracts,
            TestSetupLocalHelpers.VaultContracts memory vaultContracts,
            TestSetupLocalHelpers.StakingRouters memory stakingRouters,
            TestSetupLocalHelpers.MockContracts memory mockContracts
        ) = setup.deployAll();

        vaultLINK = vaultContracts.vaultLINK;
        colLINK = tokenizationContracts.colLINK;
        routerLINK = stakingRouters.stakingRouterLINK;
        accessManager = coreContracts.accessManager;
        linkToken = mockContracts.linkToken;
    }

    function _setUpAccess() internal {
        // Setup role in VaultLINK contract for a vaultAdmin
        vm.startPrank(initialAdmin);
        accessManager.grantRole(
            Roles.VAULT_LOCK_COLLATERAL_ROLE,
            vaultAdmin,
            0
        );

        bytes4[] memory selectors = new bytes4[](1);
        selectors[0] = UUPSUpgradeable.upgradeToAndCall.selector;

        accessManager.setTargetFunctionRole(
            address(vaultLINK),
            selectors,
            Roles.VAULT_SETUP_ROLE
        );

        vm.stopPrank();
    }

    function test_addStakingRouter() public {
        vm.startPrank(vaultAdmin);
        vaultLINK.removeStakingRouter(address(routerLINK));

        vm.expectEmit(true, true, true, true);
        emit IVault.StakingRouterAdded(address(routerLINK));
        vaultLINK.addStakingRouter(address(routerLINK));
        vm.stopPrank();
    }

    function test_removeStakingRouter() public {
        vm.startPrank(vaultAdmin);
        vm.expectEmit(true, true, true, true);
        emit IVault.StakingRouterRemoved(address(routerLINK));
        vaultLINK.removeStakingRouter(address(routerLINK));
        vm.stopPrank();
    }

    function test_updateCurrentStakingRouter() public {
        vm.startPrank(vaultAdmin);
        vm.expectEmit(true, true, true, true);
        emit IVault.CurrentStakingRouterUpdated(address(routerLINK));
        vaultLINK.updateCurrentStakingRouter(address(routerLINK));
        vm.stopPrank();
    }

    function test_updateCurrentUnstakingRouter() public {
        vm.startPrank(vaultAdmin);
        vm.expectEmit(true, true, true, true);
        emit IVault.CurrentUnstakingRouterUpdated(address(routerLINK));
        vaultLINK.updateCurrentUnstakingRouter(address(routerLINK));
        vm.stopPrank();
    }

    function test_getCurrentStakingRouter() public view {
        assertEq(vaultLINK.getCurrentStakingRouter(), address(routerLINK));
    }

    function test_getCurrentUnstakingRouter() public view {
        assertEq(vaultLINK.getCurrentUnstakingRouter(), address(routerLINK));
    }

    function test_getStakingRouter() public view {
        address[] memory stakingRouters = vaultLINK.getStakingRouters();
        assertEq(stakingRouters[0], address(routerLINK));
    }

    function test_rebalance() public {
        _setUpAccess();
        vm.startPrank(vaultAdmin);
        vaultLINK.rebalance();
        vm.stopPrank();
    }

    function test_Upgrade() public {
        // Grant role to alice
        vm.startPrank(initialAdmin);
        VaultLINKV2 newVaultLINKImpl = new VaultLINKV2();
        vaultLINK.upgradeToAndCall(address(newVaultLINKImpl), "");

        VaultLINKV2 newVaultLINK = VaultLINKV2(address(vaultLINK));
        assertEq(newVaultLINK.getVersion(), 2);

        vm.stopPrank();
    }

    function testRevert_UpgradeNotAdmin() public {
        vm.startPrank(alice);

        VaultLINKV2 newVaultLINKImpl = new VaultLINKV2();

        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessManaged.AccessManagedUnauthorized.selector,
                alice
            )
        );
        vaultLINK.upgradeToAndCall(address(newVaultLINKImpl), "");

        vm.stopPrank();
    }

    function testRevert_AddStakingRouterNotAdmin() public {
        vm.startPrank(vaultAdmin);
        vaultLINK.removeStakingRouter(address(routerLINK));
        vm.stopPrank();

        vm.startPrank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessManaged.AccessManagedUnauthorized.selector,
                alice
            )
        );
        vaultLINK.addStakingRouter(address(routerLINK));
        vm.stopPrank();
    }

    function testRevert_RemoveStakingRouterNotAdmin() public {
        vm.startPrank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessManaged.AccessManagedUnauthorized.selector,
                alice
            )
        );
        vaultLINK.removeStakingRouter(address(routerLINK));
        vm.stopPrank();
    }

    function testRevert_UpdateCurrentStakingRouterNotAdmin() public {
        vm.startPrank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessManaged.AccessManagedUnauthorized.selector,
                alice
            )
        );
        vaultLINK.updateCurrentStakingRouter(address(routerLINK));
        vm.stopPrank();
    }

    function testRevert_UpdateCurrentUnstakingRouterNotAdmin() public {
        vm.startPrank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessManaged.AccessManagedUnauthorized.selector,
                alice
            )
        );
        vaultLINK.updateCurrentUnstakingRouter(address(routerLINK));
        vm.stopPrank();
    }

    function testRevert_LockCollateralNotAdmin() public {
        vm.startPrank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessManaged.AccessManagedUnauthorized.selector,
                alice
            )
        );
        vaultLINK.lockCollateral(alice, 100 ether);
        vm.stopPrank();
    }

    function testRevert_UnlockCollateralNotAdmin() public {
        vm.startPrank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessManaged.AccessManagedUnauthorized.selector,
                alice
            )
        );
        vaultLINK.unlockCollateral(alice, 100 ether);
        vm.stopPrank();
    }

    function testRevert_RebalanceNotAdmin() public {
        vm.startPrank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessManaged.AccessManagedUnauthorized.selector,
                alice
            )
        );
        vaultLINK.rebalance();
        vm.stopPrank();
    }
}
