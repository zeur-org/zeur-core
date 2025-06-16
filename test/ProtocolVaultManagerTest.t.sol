// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {ProtocolVaultManager} from "../src/pool/manager/ProtocolVaultManager.sol";
import {ProtocolVaultManagerV2} from "./mock/ProtocolVaultManagerV2.sol";
import {TestSetupLocalHelpers} from "./TestSetupLocalHelpers.s.sol";
import {IAccessManaged} from "@openzeppelin/contracts/access/manager/IAccessManaged.sol";
import {INITIAL_ADMIN} from "../src/helpers/Constants.sol";
import {Roles} from "../src/helpers/Roles.sol";

contract ProtocolVaultManagerTest is Test {
    ProtocolVaultManager private vaultManager;

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

        vaultManager = coreContracts.vaultManager;
    }

    function test_Upgrade() public {
        // Grant role to alice
        vm.startPrank(initialAdmin);
        ProtocolVaultManagerV2 newVaultManagerImpl = new ProtocolVaultManagerV2();
        vaultManager.upgradeToAndCall(address(newVaultManagerImpl), "");

        ProtocolVaultManagerV2 newVaultManager = ProtocolVaultManagerV2(
            address(vaultManager)
        );
        assertEq(newVaultManager.getVersion(), 2);

        vm.stopPrank();
    }

    function testRevert_UpgradeNotAdmin() public {
        vm.startPrank(alice);

        ProtocolVaultManagerV2 newVaultManagerImpl = new ProtocolVaultManagerV2();

        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessManaged.AccessManagedUnauthorized.selector,
                alice
            )
        );
        vaultManager.upgradeToAndCall(address(newVaultManagerImpl), "");

        vm.stopPrank();
    }
}
