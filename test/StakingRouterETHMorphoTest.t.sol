// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {StakingRouterETHMorpho} from "../src/pool/router/StakingRouterETHMorpho.sol";
import {StakingRouterETHMorphoV2} from "./mock-v2/StakingRouterETHMorphoV2.sol";
import {TestSetupLocalHelpers} from "./helpers/TestSetupLocalHelpers.s.sol";
import {IAccessManaged} from "@openzeppelin/contracts/access/manager/IAccessManaged.sol";
import {INITIAL_ADMIN} from "../src/helpers/Constants.sol";
import {Roles} from "../src/helpers/Roles.sol";
import {ETH_ADDRESS} from "../src/helpers/Constants.sol";
import {MockMorpho} from "../src/mock/MockMorpho.sol";
import {MockWETH} from "./helpers/TestMockHelpers.sol";

contract StakingRouterETHMorphoTest is Test {
    StakingRouterETHMorpho private stakingRouter;
    MockWETH private wETH;
    MockMorpho private morphoVault;

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

        stakingRouter = stakingRouters.stakingRouterETHMorpho;
        wETH = mockContracts.wETH;
        morphoVault = mockContracts.morphoVault;
    }

    function test_getUnderlyingToken() public view {
        assertEq(stakingRouter.getUnderlyingToken(), address(wETH));
    }

    function test_getTotalStakedUnderlying() public view {
        assertEq(stakingRouter.getTotalStakedUnderlying(), 0);
    }

    function test_getStakedToken() public view {
        assertEq(stakingRouter.getStakedToken(), address(morphoVault));
    }

    function test_getExchangeRate() public view {
        assertEq(stakingRouter.getExchangeRate(), 1e18);
    }

    function test_getStakedTokenAndExchangeRate() public view {
        (address stakedToken, uint256 exchangeRate) = stakingRouter
            .getStakedTokenAndExchangeRate();
        assertEq(stakedToken, address(morphoVault));
        assertEq(exchangeRate, 1e18);
    }

    function test_Upgrade() public {
        // Grant role to alice
        vm.startPrank(initialAdmin);
        StakingRouterETHMorphoV2 newStakingRouterImpl = new StakingRouterETHMorphoV2();
        stakingRouter.upgradeToAndCall(address(newStakingRouterImpl), "");

        StakingRouterETHMorphoV2 newStakingRouter = StakingRouterETHMorphoV2(
            payable(address(stakingRouter))
        );
        assertEq(newStakingRouter.getVersion(), 2);

        vm.stopPrank();
    }

    function testRevert_UpgradeNotAdmin() public {
        vm.startPrank(alice);

        StakingRouterETHMorphoV2 newStakingRouterImpl = new StakingRouterETHMorphoV2();

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
