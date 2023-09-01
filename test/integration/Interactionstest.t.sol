//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {Raffle} from "../../src/Raffle.sol";
import {Test, console} from "forge-std/Test.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {Vm} from "forge-std/Vm.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import {CreateSubscription, AddConsumer, FundSubscription} from "../../script/Interactions.s.sol";
import {LinkToken} from "../../test/mocks/LinkToken.sol";

contract InteractionsTest is Test {
    DeployRaffle deployer;
    Raffle raffle;
    HelperConfig helperConfig;
    uint256 entranceFee;
    uint256 interval;
    address vrfCoordinator;
    bytes32 gasLane;
    uint64 subscriptionId;
    uint32 callBackGasLimit;
    address link;
    uint256 deployerKey;

    address public PLAYER = makeAddr("player");
    uint256 public constant STARTING_USER_BALANCE = 10 ether;

    function setUp() external {
        deployer = new DeployRaffle();
        (raffle, helperConfig) = deployer.run();
        (
            entranceFee,
            interval,
            vrfCoordinator,
            gasLane,
            subscriptionId,
            callBackGasLimit,
            link,

        ) = helperConfig.activeNetworkConfig();
        vm.deal(PLAYER, STARTING_USER_BALANCE);
    }

    ///////////////////////////////////
    /// DeployRaffle Helper Config ////
    //////////////////////////////////

    function testDeployRaffleGetsNetworkConfig() public {
        vm.prank(PLAYER);
        deployer = new DeployRaffle();

        (raffle, helperConfig) = deployer.run();
        (
            entranceFee,
            interval,
            vrfCoordinator,
            gasLane,
            subscriptionId,
            callBackGasLimit,
            link,

        ) = helperConfig.activeNetworkConfig();
        assertEq(subscriptionId, 0);
    }

    /////////////////////////////////////
    //     CreateSubscription     ///////
    ////////////////////////////////////

    function testCreateSubscriptionWorks() public {
        vm.prank(PLAYER);

        CreateSubscription createSubscription = new CreateSubscription();

        uint64 Id = createSubscription.createSubscription(
            vrfCoordinator,
            0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d
        );

        assert(Id != subscriptionId);
    }

    /////////////////////////////////////
    //  FundSubscription        /////////
    ////////////////////////////////////
    function testFundSubscriptionWorks() public {
        vm.prank(PLAYER);

        CreateSubscription createSubscription = new CreateSubscription();

        uint64 Id = createSubscription.createSubscription(
            vrfCoordinator,
            0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d
        );

        FundSubscription fundSubscription = new FundSubscription();

        fundSubscription.fundSubscription(
            vrfCoordinator,
            Id,
            link,
            0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d
        );
    }

    function testFundSubscriptionRevertsIfNotAValidSubscription() public {
        vm.prank(PLAYER);

        vm.expectRevert();
        VRFCoordinatorV2Mock(vrfCoordinator).fundSubscription(3, 0);
    }

    //////////////////////////////
    //  AddConsumer     /////////
    /////////////////////////////

    function testAddConsumerRevertsIfNoSubscription() public {
        vm.prank(PLAYER);
        AddConsumer addConsumer = new AddConsumer();
        vm.expectRevert();
        addConsumer.addConsumer(
            address(raffle),
            vrfCoordinator,
            0,
            0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d
        );
    }

    ///////////////////////
    //  LinkToken     /////
    //////////////////////
    function testLinkTokenWorks() public {
        uint96 FUND_AMOUNT = 3 ether;
        vm.prank(PLAYER);
        VRFCoordinatorV2Mock vrfCoordinatorMock = new VRFCoordinatorV2Mock(
            0.25 ether,
            1e9
        );
        LinkToken Link = new LinkToken();

        CreateSubscription createSubscription = new CreateSubscription();

        uint64 Id = createSubscription.createSubscription(
            address(vrfCoordinatorMock),
            0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d
        );

        // 0x70997970C51812dc3A010C7d01b50e0d17dc79C8 is owner  of subscription in VRFCoordinatorV2Mock
        LinkToken(address(Link)).transferAndCall(
            0x70997970C51812dc3A010C7d01b50e0d17dc79C8,
            FUND_AMOUNT,
            abi.encode(Id)
        );
    }

    ///////////////////////
    ///  HelperConfig /////
    ///////////////////////

    function testHelperConfig() public {
        HelperConfig helper = new HelperConfig();

        HelperConfig.NetworkConfig memory Values = helper
            .getOrCreateAnvilConfig();

        HelperConfig.NetworkConfig memory Values1 = helper
            .getSepoliaEthConfig();

        assert(Values.link != Values1.link);
        assert(Values.entranceFee == Values1.entranceFee);
    }
}
