pragma solidity 0.8.9;


contract EtherSwap {

    struct Swap {
        address payable initiator;
        uint64 endTimeStamp;
        address payable recipient;
        uint256 value;
        uint256 expectedAmount;
    }

    mapping(bytes32 => Swap) public swapMap; // the key is the hashedSecret

    event SwapInitiatedEvent(bytes32 indexed hashedSecret, address initiator, address recipient, uint256 value, uint256 expectedAmount, uint64 endTimeStamp);
    event SwapSuccessEvent(bytes32 indexed hashedSecret, address recipient, uint256 value, address initiator);
    event SwapRefundedEvent(bytes32 indexed hashedSecret);

    event SwapRecipientAddedEvent(bytes32 indexed hashedSecret, address recipient);

    function commit(uint64 _lockTimeSec, bytes32 _hashedSecret, uint256 expectedAmount, address payable _recipient) external payable {
        require(swapMap[_hashedSecret].initiator == address(0x0), "Entry already exists");
        require(msg.value > 0, "Ether is required");

        swapMap[_hashedSecret].initiator = payable(msg.sender);
        swapMap[_hashedSecret].recipient = _recipient;
        swapMap[_hashedSecret].endTimeStamp = uint64(block.timestamp + _lockTimeSec);
        swapMap[_hashedSecret].value = msg.value;
        swapMap[_hashedSecret].expectedAmount = expectedAmount;

        emit SwapInitiatedEvent(_hashedSecret, msg.sender, _recipient, msg.value, expectedAmount, swapMap[_hashedSecret].endTimeStamp);
    }

    function addRecipient(bytes32 _hashedSecret, address payable _recipient) external {
        require(swapMap[_hashedSecret].recipient == address(0x0), "Recipient already added");

        swapMap[_hashedSecret].recipient = _recipient;

        emit SwapRecipientAddedEvent(_hashedSecret, _recipient);
    }

    function claim(bytes32 _proof) external {
        bytes32 hashedSecret = keccak256(abi.encode(_proof));
        require(swapMap[hashedSecret].initiator != address(0x0), "No entry found");
        require(swapMap[hashedSecret].endTimeStamp >= block.timestamp, "TimeStamp violation");
        require(swapMap[hashedSecret].recipient != address(0x0), "The entry has no recipient");

        address initiator = swapMap[hashedSecret].initiator;
        uint256 value = swapMap[hashedSecret].value;
        address payable recipient = swapMap[hashedSecret].recipient;

        clean(hashedSecret);
        recipient.transfer(value);
        emit SwapSuccessEvent(hashedSecret, recipient, value, initiator);
    }

    function refund(bytes32 _hashedSecret) external {
        require(swapMap[_hashedSecret].initiator != address(0x0), "No entry found");
        require(swapMap[_hashedSecret].endTimeStamp < block.timestamp, "TimeStamp violation");

        uint256 value = swapMap[_hashedSecret].value;
        address payable initiator = swapMap[_hashedSecret].initiator;
        clean(_hashedSecret);

        initiator.transfer(value);
        emit SwapRefundedEvent(_hashedSecret);
    }

    function clean(bytes32 _hashedSecret) private {
        Swap storage swap = swapMap[_hashedSecret];
        delete swap.initiator;
        delete swap.recipient;
        delete swap.endTimeStamp;
        delete swap.value;
        delete swap.expectedAmount;
        delete swapMap[_hashedSecret];
    }
}


// SPDX-License-Identifier: MIT