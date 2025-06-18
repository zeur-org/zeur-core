// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {VaultETH} from "../src/pool/vault/VaultETH.sol";
import {VaultETHV2} from "./mock-v2/VaultETHV2.sol";
import {TestSetupLocalHelpers} from "./helpers/TestSetupLocalHelpers.s.sol";
import {IAccessManaged} from "@openzeppelin/contracts/access/manager/IAccessManaged.sol";
import {INITIAL_ADMIN, VAULT_ADMIN} from "../src/helpers/Constants.sol";
import {Roles} from "../src/helpers/Roles.sol";
import {ETH_ADDRESS} from "../src/helpers/Constants.sol";
import {ColToken} from "../src/pool/tokenization/ColToken.sol";
import {StakingRouterETHEtherfi} from "../src/pool/router/StakingRouterETHEtherfi.sol";
import {StakingRouterETHLido} from "../src/pool/router/StakingRouterETHLido.sol";
import {ProtocolAccessManager} from "../src/pool/manager/ProtocolAccessManager.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import {IVault} from "../src/interfaces/vault/IVault.sol";

contract VaultETHTest is Test {
    VaultETH private vaultETH;
    ColToken private colETH;
    StakingRouterETHEtherfi private routerEtherfi;
    StakingRouterETHLido private routerLido;
    ProtocolAccessManager private accessManager;

    address public alice = makeAddr("alice");
    address public bob = makeAddr("bob");
    address public initialAdmin = INITIAL_ADMIN;
    address public vaultAdmin = VAULT_ADMIN;

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
        routerEtherfi = stakingRouters.stakingRouterETHEtherfi;
        routerLido = stakingRouters.stakingRouterETHLido;
        accessManager = coreContracts.accessManager;
    }

    function _setUpAccess() internal {
        vm.startPrank(initialAdmin);
        accessManager.grantRole(
            Roles.VAULT_LOCK_COLLATERAL_ROLE,
            vaultAdmin,
            0
        );

        bytes4[] memory selectors = new bytes4[](1);
        selectors[0] = UUPSUpgradeable.upgradeToAndCall.selector;

        accessManager.setTargetFunctionRole(
            address(vaultETH),
            selectors,
            Roles.VAULT_SETUP_ROLE
        );
    }

    function test_addStakingRouter() public {
        _setUpAccess();
        vm.startPrank(vaultAdmin);
        vaultETH.removeStakingRouter(address(routerEtherfi));

        vm.expectEmit(true, true, true, true);
        emit IVault.StakingRouterAdded(address(routerEtherfi));
        vaultETH.addStakingRouter(address(routerEtherfi));
        vm.stopPrank();
    }

    function test_removeStakingRouter() public {
        _setUpAccess();
        vm.startPrank(vaultAdmin);

        vm.expectEmit(true, true, true, true);
        emit IVault.StakingRouterRemoved(address(routerEtherfi));
        vaultETH.removeStakingRouter(address(routerEtherfi));
        vm.stopPrank();
    }

    function test_updateCurrentStakingRouter() public {
        _setUpAccess();
        vm.startPrank(vaultAdmin);

        vm.expectEmit(true, true, true, true);
        emit IVault.CurrentStakingRouterUpdated(address(routerEtherfi));
        vaultETH.updateCurrentStakingRouter(address(routerEtherfi));
        vm.stopPrank();
    }

    function test_updateCurrentUnstakingRouter() public {
        _setUpAccess();
        vm.startPrank(vaultAdmin);

        vm.expectEmit(true, true, true, true);
        emit IVault.CurrentUnstakingRouterUpdated(address(routerEtherfi));
        vaultETH.updateCurrentUnstakingRouter(address(routerEtherfi));
        vm.stopPrank();
    }

    function test_getCurrentStakingRouter() public view {
        assertEq(vaultETH.getCurrentStakingRouter(), address(routerLido));
    }

    function test_getCurrentUnstakingRouter() public view {
        assertEq(vaultETH.getCurrentUnstakingRouter(), address(routerLido));
    }

    function test_getStakingRouters() public view {
        address[] memory stakingRouters = vaultETH.getStakingRouters();
        assertEq(stakingRouters[0], address(routerLido));
        assertEq(stakingRouters[1], address(routerEtherfi));
    }

    function test_rebalance() public {
        _setUpAccess();
        vm.startPrank(vaultAdmin);
        vaultETH.rebalance();
        vm.stopPrank();
    }

    function test_Upgrade() public {
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
        vaultETH.addStakingRouter(address(routerEtherfi));
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
        vaultETH.removeStakingRouter(address(routerEtherfi));
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
        vaultETH.updateCurrentStakingRouter(address(routerEtherfi));
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
        vaultETH.updateCurrentUnstakingRouter(address(routerEtherfi));
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
        vaultETH.rebalance();
        vm.stopPrank();
    }
}
