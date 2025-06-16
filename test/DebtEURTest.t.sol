// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {ProtocolAccessManager} from "../src/pool/manager/ProtocolAccessManager.sol";
import {DebtEUR} from "../src/pool/tokenization/DebtEUR.sol";
import {TestSetupLocalHelpers} from "./helpers/TestSetupLocalHelpers.s.sol";
import {IAccessManaged} from "@openzeppelin/contracts/access/manager/IAccessManaged.sol";
import {INITIAL_ADMIN} from "../src/helpers/Constants.sol";
import {Roles} from "../src/helpers/Roles.sol";

contract DebtEURTest is Test {
    DebtEUR private debtEUR;
    ProtocolAccessManager private accessManager;

    address public alice = makeAddr("alice");
    address public bob = makeAddr("bob");
    address public debtEURAdmin = makeAddr("debtEURAdmin");
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

        debtEUR = tokenizationContracts.debtEUR;
        accessManager = coreContracts.accessManager;
    }

    function _setUpAccess() internal {
        // Setup role in DebtEUR contract for a debtEURAdmin
        vm.startPrank(initialAdmin);
        accessManager.grantRole(Roles.MINTER_BURNER_ROLE, debtEURAdmin, 0);

        accessManager.setTargetFunctionRole(
            address(debtEUR),
            Roles.getMinterDebtEURSelectors(),
            Roles.MINTER_BURNER_ROLE
        );

        vm.stopPrank();
    }

    function test_Mint() public {
        _setUpAccess();

        vm.startPrank(debtEURAdmin);
        debtEUR.mint(alice, 1000);
        vm.stopPrank();

        assertEq(debtEUR.balanceOf(alice), 1000);
    }

    function test_Burn() public {
        _setUpAccess();

        vm.startPrank(debtEURAdmin);
        debtEUR.mint(alice, 1000);
        debtEUR.burn(alice, 1000);
        vm.stopPrank();

        assertEq(debtEUR.balanceOf(alice), 0);
    }

    function test_Decimals() public {
        assertEq(debtEUR.decimals(), 6);
    }

    function testRevert_MintNotAdmin() public {
        vm.startPrank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessManaged.AccessManagedUnauthorized.selector,
                alice
            )
        );
        debtEUR.mint(alice, 1000);
        vm.stopPrank();
    }

    function testRevert_BurnNotAdmin() public {
        vm.startPrank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessManaged.AccessManagedUnauthorized.selector,
                alice
            )
        );
        debtEUR.burn(alice, 1000);
        vm.stopPrank();
    }

    function testRevert_Transfer() public {
        vm.startPrank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(DebtEUR.DebtEUR_OperationNotAllowed.selector)
        );
        debtEUR.transfer(bob, 1000);
        vm.stopPrank();
    }

    function testRevert_TransferFrom() public {
        vm.startPrank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(DebtEUR.DebtEUR_OperationNotAllowed.selector)
        );
        debtEUR.transferFrom(alice, bob, 1000);
        vm.stopPrank();
    }

    function testRevert_Approve() public {
        vm.startPrank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(DebtEUR.DebtEUR_OperationNotAllowed.selector)
        );
        debtEUR.approve(bob, 1000);
        vm.stopPrank();
    }
}
