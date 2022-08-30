// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./interfaces/IStarknetCore.sol";


contract L1ReceiveMsgFromL2 {
    // The StarkNet core contract.
    IStarknetCore starknetCore;

    constructor(
        address starknetCore_
    ) public {
        starknetCore = IStarknetCore(starknetCore_);
    }

    // The address of the L2 contract that interacts with this L1 contract
    uint256 public l2MessengerContractAddress = 0x595bfeb84a5f95de3471fc66929710e92c12cce2b652cd91a6fef4c5c09cd99;
    event messageReceivedFromStarkNet(string stringMessage);
    
    //******* ********//
    function customizedBytes32ToString(bytes32 _bytes32) 
    public 
    pure 
    returns (string memory) 
    {
        uint8 i = 0;
        while(i < 32 && _bytes32[i] != 0) {
            i++;
        }
        uint offset = i;
        bytes memory bytesArray = new bytes(32-offset);
        for (i = 0; i < 32-offset; i++) {
            bytesArray[i] = _bytes32[i+offset];
        }
        return string(bytesArray);
    }
    //******* ********//

     /**
      Consumes a message that was sent from an L2 contract.
     */
    function consumeMessage(bytes32 messageToKhaL1) public {

        // Construct the withdrawal message's payload.
        uint256[] memory payload = new uint256[](1);
        payload[0] = uint256(messageToKhaL1);

        // Consume the message from the StarkNet core contract.
        // This will revert the (Ethereum) transaction if the message does not exist.
        starknetCore.consumeMessageFromL2(l2MessengerContractAddress, payload);
        emit messageReceivedFromStarkNet(customizedBytes32ToString(messageToKhaL1));

    }
        
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

interface IStarknetCore {
    /**
      Sends a message to an L2 contract.

      Returns the hash of the message.
    */
    function sendMessageToL2(
        uint256 to_address,
        uint256 selector,
        uint256[] calldata payload
    ) external returns (bytes32);

    /**
      Consumes a message that was sent from an L2 contract.

      Returns the hash of the message.
    */
    function consumeMessageFromL2(
        uint256 fromAddress,
        uint256[] calldata payload
    ) external returns (bytes32);

    function l2ToL1Messages(bytes32 msgHash) external view returns (uint256);
}