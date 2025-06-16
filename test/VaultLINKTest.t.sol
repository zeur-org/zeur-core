// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {VaultLINK} from "../src/pool/vault/VaultLINK.sol";
import {VaultLINKV2} from "./mock/VaultLINKV2.sol";
import {TestSetupLocalHelpers} from "./TestSetupLocalHelpers.s.sol";
import {IAccessManaged} from "@openzeppelin/contracts/access/manager/IAccessManaged.sol";
import {INITIAL_ADMIN} from "../src/helpers/Constants.sol";
import {Roles} from "../src/helpers/Roles.sol";
import {ETH_ADDRESS} from "../src/helpers/Constants.sol";
import {ColToken} from "../src/pool/tokenization/ColToken.sol";

contract VaultLINKTest is Test {
    VaultLINK private vaultLINK;
    ColToken private colLINK;

    address public alice = makeAddr("alice");
    address public bob = makeAddr("bob");
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
        stakingRouter = stakingRouters.stakingRouterLINK;
    }

    function test_addStakingRouter() public {
        vm.startPrank(initialAdmin);
        vaultLINK.addStakingRouter(address(stakingRouters.stakingRouterLINK));
        vm.stopPrank();
    }

    function test_removeStakingRouter() public {
        vm.startPrank(initialAdmin);
        vaultLINK.removeStakingRouter(
            address(stakingRouters.stakingRouterLINK)
        );
        vm.stopPrank();
    }

    function test_updateCurrentStakingRouter() public {
        vm.startPrank(initialAdmin);
        vaultLINK.updateCurrentStakingRouter(
            address(stakingRouters.stakingRouterLINK)
        );
        vm.stopPrank();
    }

    function test_updateCurrentUnstakingRouter() public {
        vm.startPrank(initialAdmin);
        vaultLINK.updateCurrentUnstakingRouter(
            address(stakingRouters.stakingRouterLINK)
        );
        vm.stopPrank();
    }

    function test_getCurrentStakingRouter() public view {
        assertEq(
            vaultLINK.getCurrentStakingRouter(),
            address(stakingRouters.stakingRouterLINK)
        );
    }

    function test_getCurrentUnstakingRouter() public view {
        assertEq(
            vaultLINK.getCurrentUnstakingRouter(),
            address(stakingRouters.stakingRouterLINK)
        );
    }

    function test_getStakingRouter() public view {
        assertEq(
            vaultLINK.getStakingRouter(
                address(stakingRouters.stakingRouterLINK)
            ),
            address(stakingRouters.stakingRouterLINK)
        );
    }

    function test_lockCollateral() public {
        vm.startPrank(alice);
        vaultLINK.lockCollateral(alice, 100 ether);
        vm.stopPrank();
    }

    function test_unlockCollateral() public {
        vm.startPrank(alice);
        vaultLINK.unlockCollateral(alice, 100 ether);
        vm.stopPrank();
    }

    function test_rebalance() public {
        vm.startPrank(alice);
        vaultLINK.rebalance(alice, 100 ether);
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
        vm.startPrank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessManaged.AccessManagedUnauthorized.selector,
                alice
            )
        );
        vaultLINK.addStakingRouter(address(stakingRouters.stakingRouterLINK));
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
        vaultLINK.removeStakingRouter(
            address(stakingRouters.stakingRouterLINK)
        );
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
        vaultLINK.updateCurrentStakingRouter(
            address(stakingRouters.stakingRouterLINK)
        );
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
        vaultLINK.updateCurrentUnstakingRouter(
            address(stakingRouters.stakingRouterLINK)
        );
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
        vaultLINK.rebalance(alice, 100 ether);
        vm.stopPrank();
    }
}
