// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {ProtocolAccessManager} from "../src/pool/manager/ProtocolAccessManager.sol";
import {ColToken} from "../src/pool/tokenization/ColToken.sol";
import {TestSetupLocalHelpers} from "./helpers/TestSetupLocalHelpers.s.sol";
import {INITIAL_ADMIN} from "../src/helpers/Constants.sol";
import {Roles} from "../src/helpers/Roles.sol";
import {IAccessManaged} from "@openzeppelin/contracts/access/manager/IAccessManaged.sol";

contract ColTokenTest is Test {
    ColToken private colETH;
    ProtocolAccessManager private accessManager;

    address public alice = makeAddr("alice");
    address public bob = makeAddr("bob");
    address public colTokenAdmin = makeAddr("colTokenAdmin");
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

        colETH = tokenizationContracts.colETH;
        accessManager = coreContracts.accessManager;
    }

    function _setUpAccess() internal {
        // Setup role in ColToken contract for a colTokenAdmin
        vm.startPrank(initialAdmin);
        accessManager.grantRole(Roles.MINTER_BURNER_ROLE, colTokenAdmin, 0);

        accessManager.setTargetFunctionRole(
            address(colETH),
            Roles.getMinterColTokenSelectors(),
            Roles.MINTER_BURNER_ROLE
        );

        // Set transfer/transferFrom function roles to MINTER_BURNER_ROLE
        bytes4[] memory selectors = new bytes4[](2);
        selectors[0] = ColToken.transfer.selector;
        selectors[1] = ColToken.transferFrom.selector;
        accessManager.setTargetFunctionRole(
            address(colETH),
            selectors,
            Roles.MINTER_BURNER_ROLE
        );

        vm.stopPrank();
    }

    function test_Mint() public {
        _setUpAccess();

        vm.startPrank(colTokenAdmin);
        colETH.mint(alice, 1000);
        vm.stopPrank();

        assertEq(colETH.balanceOf(alice), 1000);
    }

    function test_Burn() public {
        _setUpAccess();

        vm.startPrank(colTokenAdmin);
        colETH.mint(alice, 1000);
        assertEq(colETH.balanceOf(alice), 1000);

        colETH.burn(alice, 1000);
        assertEq(colETH.balanceOf(alice), 0);

        vm.stopPrank();
    }

    function test_Transfer() public {
        _setUpAccess();

        vm.startPrank(colTokenAdmin);
        colETH.mint(colTokenAdmin, 1000);
        colETH.transfer(alice, 1000);
        vm.stopPrank();

        assertEq(colETH.balanceOf(alice), 1000);
        assertEq(colETH.balanceOf(colTokenAdmin), 0);
    }

    function test_TransferFrom() public {
        _setUpAccess();

        vm.startPrank(alice);
        colETH.approve(colTokenAdmin, 1000);
        vm.stopPrank();

        vm.startPrank(colTokenAdmin);
        colETH.mint(alice, 1000);

        colETH.transferFrom(alice, bob, 1000);

        assertEq(colETH.balanceOf(bob), 1000);
        assertEq(colETH.balanceOf(alice), 0);

        vm.stopPrank();
    }

    function testRevert_MintNotAdmin() public {
        vm.startPrank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessManaged.AccessManagedUnauthorized.selector,
                alice
            )
        );
        colETH.mint(alice, 1000);
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
        colETH.burn(alice, 1000);
        vm.stopPrank();
    }

    function testRevert_TransferNotAdmin() public {
        vm.startPrank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessManaged.AccessManagedUnauthorized.selector,
                alice
            )
        );
        colETH.transfer(bob, 1000);
        vm.stopPrank();
    }

    function testRevert_TransferFromNotAdmin() public {
        vm.startPrank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessManaged.AccessManagedUnauthorized.selector,
                alice
            )
        );
        colETH.transferFrom(alice, bob, 1000);
        vm.stopPrank();
    }
}
