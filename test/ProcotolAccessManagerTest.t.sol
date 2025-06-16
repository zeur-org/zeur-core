// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {ProtocolAccessManager} from "../src/pool/manager/ProtocolAccessManager.sol";
import {ProtocolAccessManagerV2} from "./mock/ProtocolAccessManagerV2.sol";
import {TestSetupLocalHelpers} from "./helpers/TestSetupLocalHelpers.s.sol";
import {IAccessManaged} from "@openzeppelin/contracts/access/manager/IAccessManaged.sol";
import {INITIAL_ADMIN} from "../src/helpers/Constants.sol";
import {Roles} from "../src/helpers/Roles.sol";

contract ProtocolAccessManagerTest is Test {
    ProtocolAccessManager private accessManager;

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

        accessManager = coreContracts.accessManager;
    }

    function test_Upgrade() public {
        vm.startPrank(initialAdmin);
        ProtocolAccessManagerV2 newAccessManagerImpl = new ProtocolAccessManagerV2();
        accessManager.upgradeToAndCall(address(newAccessManagerImpl), "");

        ProtocolAccessManagerV2 newAccessManager = ProtocolAccessManagerV2(
            address(accessManager)
        );
        assertEq(newAccessManager.getVersion(), 2);

        vm.stopPrank();
    }

    function testRevert_UpgradeNotAdmin() public {
        vm.startPrank(alice);

        ProtocolAccessManagerV2 newAccessManagerImpl = new ProtocolAccessManagerV2();

        vm.expectRevert(
            abi.encodeWithSelector(
                ProtocolAccessManager.ProtocolAccessManager_NotAdmin.selector
            )
        );
        accessManager.upgradeToAndCall(address(newAccessManagerImpl), "");

        vm.stopPrank();
    }
}
