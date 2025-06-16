// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {VaultETH} from "../src/pool/vault/VaultETH.sol";
import {VaultETHV2} from "./mock/VaultETHV2.sol";
import {TestSetupLocalHelpers} from "./TestSetupLocalHelpers.s.sol";
import {IAccessManaged} from "@openzeppelin/contracts/access/manager/IAccessManaged.sol";
import {INITIAL_ADMIN} from "../src/helpers/Constants.sol";
import {Roles} from "../src/helpers/Roles.sol";
import {ETH_ADDRESS} from "../src/helpers/Constants.sol";
import {ColToken} from "../src/pool/tokenization/ColToken.sol";

contract VaultETHTest is Test {
    VaultETH private vaultETH;
    ColToken private colETH;

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

        vaultETH = vaultContracts.vaultETH;
        colETH = tokenizationContracts.colETH;
        stakingRouter = stakingRouters.stakingRouterETHEtherfi;
    }

    function test_addStakingRouter() public {
        vm.startPrank(initialAdmin);
        vaultETH.addStakingRouter(
            address(stakingRouters.stakingRouterETHEtherfi)
        );
        vm.stopPrank();
    }

    function test_removeStakingRouter() public {
        vm.startPrank(initialAdmin);
        vaultETH.removeStakingRouter(
            address(stakingRouters.stakingRouterETHEtherfi)
        );
        vm.stopPrank();
    }

    function test_updateCurrentStakingRouter() public {
        vm.startPrank(initialAdmin);
        vaultETH.updateCurrentStakingRouter(
            address(stakingRouters.stakingRouterETHEtherfi)
        );
        vm.stopPrank();
    }

    function test_updateCurrentUnstakingRouter() public {
        vm.startPrank(initialAdmin);
        vaultETH.updateCurrentUnstakingRouter(
            address(stakingRouters.stakingRouterETHEtherfi)
        );
        vm.stopPrank();
    }

    function test_getCurrentStakingRouter() public view {
        assertEq(
            vaultETH.getCurrentStakingRouter(),
            address(stakingRouters.stakingRouterETHEtherfi)
        );
    }

    function test_getCurrentUnstakingRouter() public view {
        assertEq(
            vaultETH.getCurrentUnstakingRouter(),
            address(stakingRouters.stakingRouterETHEtherfi)
        );
    }

    function test_getStakingRouter() public view {
        assertEq(
            vaultETH.getStakingRouter(
                address(stakingRouters.stakingRouterETHEtherfi)
            ),
            address(stakingRouters.stakingRouterETHEtherfi)
        );
    }

    function test_lockCollateral() public {
        vm.startPrank(alice);
        vaultETH.lockCollateral(alice, 100 ether);
        vm.stopPrank();
    }

    function test_unlockCollateral() public {
        vm.startPrank(alice);
        vaultETH.unlockCollateral(alice, 100 ether);
        vm.stopPrank();
    }

    function test_rebalance() public {
        vm.startPrank(alice);
        vaultETH.rebalance(alice, 100 ether);
        vm.stopPrank();
    }

    function test_Upgrade() public {
        // Grant role to alice
        vm.startPrank(initialAdmin);
        VaultETHV2 newVaultETHImpl = new VaultETHV2();
        vaultETH.upgradeToAndCall(address(newVaultETHImpl), "");

        VaultETHV2 newVaultETH = VaultETHV2(address(vaultETH));
        assertEq(newVaultETH.getVersion(), 2);

        vm.stopPrank();
    }

    function testRevert_UpgradeNotAdmin() public {
        vm.startPrank(alice);

        VaultETHV2 newVaultETHImpl = new VaultETHV2();

        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessManaged.AccessManagedUnauthorized.selector,
                alice
            )
        );
        vaultETH.upgradeToAndCall(address(newVaultETHImpl), "");

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
        vaultETH.addStakingRouter(
            address(stakingRouters.stakingRouterETHEtherfi)
        );
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
        vaultETH.removeStakingRouter(
            address(stakingRouters.stakingRouterETHEtherfi)
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
        vaultETH.updateCurrentStakingRouter(
            address(stakingRouters.stakingRouterETHEtherfi)
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
        vaultETH.updateCurrentUnstakingRouter(
            address(stakingRouters.stakingRouterETHEtherfi)
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
        vaultETH.lockCollateral(alice, 100 ether);
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
        vaultETH.unlockCollateral(alice, 100 ether);
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
        vaultETH.rebalance(alice, 100 ether);
        vm.stopPrank();
    }
}
