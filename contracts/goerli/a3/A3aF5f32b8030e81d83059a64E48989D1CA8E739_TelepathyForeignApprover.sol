pragma solidity 0.4.24;

contract TelepathyForeignApprover {
    bool public initialized = false;
    address public foreignTelepathyReceiver;
    address public homeOmnibridgeAMB;
    mapping(bytes32 => bool) public approvals;

    function initialize(address _foreignTelepathyReceiver, address _homeOmnibridgeAMB) external {
        require(!initialized);
        foreignTelepathyReceiver = _foreignTelepathyReceiver;
        homeOmnibridgeAMB = _homeOmnibridgeAMB;
        initialized = true;
    }

    function isApproved(bytes32 messageId) public view returns (bool) {
        return approvals[messageId];
    }

    function receiveSuccinct(address srcAddress, bytes message) external {
        require(msg.sender == foreignTelepathyReceiver);
        require(srcAddress == homeOmnibridgeAMB);
        bytes32 messageId = keccak256(message);
        approvals[messageId] = true;
    }
}