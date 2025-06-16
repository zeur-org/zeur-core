// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {StakingRouterLINK} from "../src/pool/router/StakingRouterLINK.sol";
import {StakingRouterLINKV2} from "./mock/StakingRouterLINKV2.sol";
import {TestSetupLocalHelpers} from "./TestSetupLocalHelpers.s.sol";
import {IAccessManaged} from "@openzeppelin/contracts/access/manager/IAccessManaged.sol";
import {INITIAL_ADMIN} from "../src/helpers/Constants.sol";
import {Roles} from "../src/helpers/Roles.sol";
import {ETH_ADDRESS} from "../src/helpers/Constants.sol";
import {ColToken} from "../src/pool/tokenization/ColToken.sol";

contract StakingRouterLINKTest is Test {
    StakingRouterLINK private stakingRouter;
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

        stakingRouter = stakingRouters.stakingRouterLINK;
        colLINK = tokenizationContracts.colLINK;
    }

    function test_stake() public {
        vm.startPrank(alice);
        stakingRouter.stake(alice, 100 ether);
        vm.stopPrank();
    }

    function test_unstake() public {
        vm.startPrank(alice);
        stakingRouter.unstake(alice, 100 ether);
        vm.stopPrank();
    }

    function test_getUnderlyingToken() public view {
        assertEq(stakingRouter.getUnderlyingToken(), ETH_ADDRESS);
    }

    function test_getTotalStakedUnderlying() public view {
        assertEq(stakingRouter.getTotalStakedUnderlying(), 0);
    }

    function test_getStakedToken() public view {
        assertEq(stakingRouter.getStakedToken(), address(colLINK));
    }

    function test_getExchangeRate() public view {
        assertEq(stakingRouter.getExchangeRate(), 0);
    }

    function test_getStakedTokenAndExchangeRate() public view {
        (address stakedToken, uint256 exchangeRate) = stakingRouter
            .getStakedTokenAndExchangeRate();
        assertEq(stakedToken, address(colLINK));
        assertEq(exchangeRate, 0);
    }

    function test_Upgrade() public {
        // Grant role to alice
        vm.startPrank(initialAdmin);
        StakingRouterLINKV2 newStakingRouterImpl = new StakingRouterLINKV2();
        stakingRouter.upgradeToAndCall(address(newStakingRouterImpl), "");

        StakingRouterLINKV2 newStakingRouter = StakingRouterLINKV2(
            address(stakingRouter)
        );
        assertEq(newStakingRouter.getVersion(), 2);

        vm.stopPrank();
    }

    function testRevert_UpgradeNotAdmin() public {
        vm.startPrank(alice);

        StakingRouterLINKV2 newStakingRouterImpl = new StakingRouterLINKV2();

        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessManaged.AccessManagedUnauthorized.selector,
                alice
            )
        );
        stakingRouter.upgradeToAndCall(address(newStakingRouterImpl), "");

        vm.stopPrank();
    }
}
