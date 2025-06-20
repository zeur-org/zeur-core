// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {StakingRouterLINK} from "../src/pool/router/StakingRouterLINK.sol";
import {StakingRouterLINKV2} from "./mock-v2/StakingRouterLINKV2.sol";
import {TestSetupLocalHelpers} from "./helpers/TestSetupLocalHelpers.s.sol";
import {IAccessManaged} from "@openzeppelin/contracts/access/manager/IAccessManaged.sol";
import {INITIAL_ADMIN} from "../src/helpers/Constants.sol";
import {Roles} from "../src/helpers/Roles.sol";
import {ETH_ADDRESS} from "../src/helpers/Constants.sol";
import {MockERC20} from "./helpers/TestMockHelpers.sol";
import {MockstLINK} from "../src/mock/MockStakeLink.sol";

contract StakingRouterLINKTest is Test {
    StakingRouterLINK private stakingRouter;
    MockERC20 linkToken; // Chainlink LINK token
    MockstLINK stLinkToken; // Stake.Link stLINK token

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
        linkToken = mockContracts.linkToken;
        stLinkToken = mockContracts.stLinkToken;
    }

    function test_getUnderlyingToken() public view {
        assertEq(stakingRouter.getUnderlyingToken(), address(linkToken));
    }

    function test_getTotalStakedUnderlying() public view {
        assertEq(stakingRouter.getTotalStakedUnderlying(), 0);
    }

    function test_getStakedToken() public view {
        assertEq(stakingRouter.getStakedToken(), address(stLinkToken));
    }

    function test_getExchangeRate() public view {
        assertEq(stakingRouter.getExchangeRate(), 1e18);
    }

    function test_getStakedTokenAndExchangeRate() public view {
        (address stakedToken, uint256 exchangeRate) = stakingRouter
            .getStakedTokenAndExchangeRate();
        assertEq(stakedToken, address(stLinkToken));
        assertEq(exchangeRate, 1e18);
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

    function testRevert_stakeNotAdmin() public {
        vm.startPrank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessManaged.AccessManagedUnauthorized.selector,
                alice
            )
        );
        stakingRouter.stake(alice, 100 ether);
        vm.stopPrank();
    }

    function testRevert_unstakeNotAdmin() public {
        vm.startPrank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessManaged.AccessManagedUnauthorized.selector,
                alice
            )
        );
        stakingRouter.unstake(alice, 100 ether);
        vm.stopPrank();
    }
}
