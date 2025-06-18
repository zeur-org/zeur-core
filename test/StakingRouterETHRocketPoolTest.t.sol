// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {StakingRouterETHRocketPool} from "../src/pool/router/StakingRouterETHRocketPool.sol";
import {StakingRouterETHRocketPoolV2} from "./mock-v2/StakingRouterETHRocketPoolV2.sol";
import {TestSetupLocalHelpers} from "./helpers/TestSetupLocalHelpers.s.sol";
import {IAccessManaged} from "@openzeppelin/contracts/access/manager/IAccessManaged.sol";
import {INITIAL_ADMIN} from "../src/helpers/Constants.sol";
import {Roles} from "../src/helpers/Roles.sol";
import {ETH_ADDRESS} from "../src/helpers/Constants.sol";
import {ColToken} from "../src/pool/tokenization/ColToken.sol";

contract StakingRouterETHRocketPoolTest is Test {
    StakingRouterETHRocketPool private stakingRouter;
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

        stakingRouter = stakingRouters.stakingRouterETHRocketPool;
        colETH = tokenizationContracts.colETH;
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
        assertEq(stakingRouter.getStakedToken(), address(colETH));
    }

    function test_getExchangeRate() public view {
        assertEq(stakingRouter.getExchangeRate(), 0);
    }

    function test_getStakedTokenAndExchangeRate() public view {
        (address stakedToken, uint256 exchangeRate) = stakingRouter
            .getStakedTokenAndExchangeRate();
        assertEq(stakedToken, address(colETH));
        assertEq(exchangeRate, 0);
    }

    function test_Upgrade() public {
        // Grant role to alice
        vm.startPrank(initialAdmin);
        StakingRouterETHRocketPoolV2 newStakingRouterImpl = new StakingRouterETHRocketPoolV2();
        stakingRouter.upgradeToAndCall(address(newStakingRouterImpl), "");

        StakingRouterETHRocketPoolV2 newStakingRouter = StakingRouterETHRocketPoolV2(
                address(stakingRouter)
            );
        assertEq(newStakingRouter.getVersion(), 2);

        vm.stopPrank();
    }

    function testRevert_UpgradeNotAdmin() public {
        vm.startPrank(alice);

        StakingRouterETHRocketPoolV2 newStakingRouterImpl = new StakingRouterETHRocketPoolV2();

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
