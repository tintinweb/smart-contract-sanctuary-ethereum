// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./LinkTokenInterface.sol";
import "./VRFCoordinatorV2Interface.sol";
import "./VRFConsumerBaseV2.sol";

interface senderContract {
    function receiveRandomness(uint requestId, uint randomNumber) external;
}

contract DeepRandomnessV2 is VRFConsumerBaseV2 {
    address public owner;

    constructor() VRFConsumerBaseV2(chainLinkVrfCoordinator) {
        owner = msg.sender;
        COORDINATOR = VRFCoordinatorV2Interface(chainLinkVrfCoordinator);
        LINKTOKEN = LinkTokenInterface(chainLinkLinkAddress);
    }

    // CHAIN LINK
    VRFCoordinatorV2Interface COORDINATOR;
    LinkTokenInterface LINKTOKEN;
    // TODO: SET DEFAULT BEFORE DEPLOY
    uint64 chainLinkSubscriptionId = 2411;
    address chainLinkVrfCoordinator = 0x6168499c0cFfCaCD319c818142124B7A15E857ab;
    address chainLinkLinkAddress = 0x01BE23585060835E02B77ef475b0Cc51aA1e0709;
    bytes32 chainLinkKeyHash = 0xd89b2bf150e3b9e13446986e571fb9cab24b13cea0a43ea20a6049a85cc807cc;
    uint32 chainLinkCallbackGasLimit = 400000;
    uint16 chainLinkRequestConfirmations = 3;
    uint32 numWords = 1;

    uint private randNonce = 0;

    struct LinkRequester {
        uint modulus;
        address senderAddress;
    }
    mapping(uint256 => LinkRequester) private LinkRequestSenderMapping;
    
    function getRandomNumber(address, uint _modulus) external returns (uint) {
        uint256 requestId = COORDINATOR.requestRandomWords(chainLinkKeyHash, chainLinkSubscriptionId, chainLinkRequestConfirmations, chainLinkCallbackGasLimit, 1);
        LinkRequestSenderMapping[requestId] = LinkRequester(_modulus ,msg.sender);
        return requestId;
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        senderContract(LinkRequestSenderMapping[requestId].senderAddress).receiveRandomness(requestId, randomWords[0]%LinkRequestSenderMapping[requestId].modulus);
    }
}