// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {Roles} from "../src/helpers/Roles.sol";
import {ColEUR} from "../src/pool/tokenization/ColEUR.sol";
import {INITIAL_ADMIN} from "../src/helpers/Constants.sol";
import {ProtocolAccessManager} from "../src/pool/manager/ProtocolAccessManager.sol";
import {TestSetupLocalHelpers} from "./TestSetupLocalHelpers.s.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {IAccessManaged} from "@openzeppelin/contracts/access/manager/IAccessManaged.sol";
import {MockTokenEURC} from "../src/mock/MockTokenEURC.sol";

contract ColEURTest is Test {
    ColEUR private colEUR;
    MockTokenEURC private eurToken;
    ProtocolAccessManager private accessManager;

    address public alice = makeAddr("alice");
    address public bob = makeAddr("bob");
    address public colEURAdmin = makeAddr("colEURAdmin");
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

        colEUR = tokenizationContracts.colEUR;
        eurToken = mockContracts.eurToken;
        accessManager = coreContracts.accessManager;
    }

    function _setUpAccess() internal {
        // Setup role in ColEUR contract for a colEURAdmin
        vm.startPrank(initialAdmin);
        accessManager.grantRole(Roles.MINTER_BURNER_ROLE, colEURAdmin, 0);

        accessManager.setTargetFunctionRole(
            address(colEUR),
            Roles.getMinterColEURSelectors(),
            Roles.MINTER_BURNER_ROLE
        );

        eurToken.mint(colEURAdmin, 1000000 * 1e6);

        vm.stopPrank();
    }

    function test_Deposit() public {
        _setUpAccess();

        vm.startPrank(colEURAdmin);
        eurToken.approve(address(colEUR), 1000 * 1e6);
        colEUR.deposit(1000, alice);
        vm.stopPrank();

        assertEq(colEUR.balanceOf(alice), 1000);
        assertEq(colEUR.balanceOf(colEURAdmin), 0);
    }

    function test_Mint() public {
        _setUpAccess();

        vm.startPrank(colEURAdmin);
        eurToken.approve(address(colEUR), 1000 * 1e6);
        colEUR.mint(1000, alice);
        vm.stopPrank();

        assertEq(colEUR.balanceOf(alice), 1000);
        assertEq(eurToken.balanceOf(alice), 0);
    }

    function test_Withdraw() public {
        _setUpAccess();
        uint256 initialBalance = eurToken.balanceOf(alice);

        vm.startPrank(colEURAdmin);
        eurToken.approve(address(colEUR), 1000 * 1e6);
        colEUR.deposit(1000, colEURAdmin);
        colEUR.withdraw(1000, alice, colEURAdmin);
        vm.stopPrank();

        assertEq(colEUR.balanceOf(colEURAdmin), 0);
        assertEq(eurToken.balanceOf(alice), initialBalance + 1000);
    }

    function test_Redeem() public {
        _setUpAccess();

        uint256 initialBalance = eurToken.balanceOf(alice);

        vm.startPrank(colEURAdmin);
        eurToken.approve(address(colEUR), 1000 * 1e6);
        colEUR.deposit(1000, colEURAdmin);

        colEUR.redeem(1000, alice, colEURAdmin);
        vm.stopPrank();

        assertEq(eurToken.balanceOf(alice), initialBalance + 1000);
    }

    function testRevert_MintNotAdmin() public {
        _setUpAccess();

        vm.startPrank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessManaged.AccessManagedUnauthorized.selector,
                alice
            )
        );
        colEUR.mint(1000, alice);
        vm.stopPrank();
    }

    function testRevert_RedeemNotAdmin() public {
        _setUpAccess();

        vm.startPrank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessManaged.AccessManagedUnauthorized.selector,
                alice
            )
        );
        colEUR.redeem(1000, alice, alice);
        vm.stopPrank();
    }

    function testRevert_DepositNotAdmin() public {
        _setUpAccess();

        vm.startPrank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessManaged.AccessManagedUnauthorized.selector,
                alice
            )
        );
        colEUR.deposit(1000, alice);
        vm.stopPrank();
    }

    function testRevert_WithdrawNotAdmin() public {
        _setUpAccess();

        vm.startPrank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessManaged.AccessManagedUnauthorized.selector,
                alice
            )
        );
        colEUR.withdraw(1000, alice, alice);
        vm.stopPrank();
    }
}
