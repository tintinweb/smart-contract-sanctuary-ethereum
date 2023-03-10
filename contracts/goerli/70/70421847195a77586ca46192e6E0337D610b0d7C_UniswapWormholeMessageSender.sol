/**
 * Copyright Uniswap Foundation 2023
 *
 * Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with
 * the License. You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on
 * an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the
 * specific language governing permissions and limitations under the License.
 *
 * SPDX-License-Identifier: Apache-2.0
 */
 pragma solidity ^0.8.9;

 interface IWormhole {
     function publishMessage(uint32 nonce, bytes memory payload, uint8 consistencyLevel)
         external
         payable
         returns (uint64 sequence);
     function messageFee() external view returns (uint256);
 }
 
 bytes32 constant messagePayloadVersion = keccak256(
     abi.encode(
         "UniswapWormholeMessageSenderV1 (bytes32 receivedMessagePayloadVersion, address[] memory targets, uint256[] memory values, bytes[] memory datas, address messageReceiver, uint16 receiverChainId)"
     )
 );
 
 function generateMessagePayload(
     address[] memory _targets,
     uint256[] memory _values,
     bytes[] memory _calldatas,
     address _messageReceiver,
     uint16 _receiverChainId
 ) pure returns (bytes memory) {
     // SECURITY: Anytime this format is changed, messagePayloadVersion should be updated.
     return abi.encode(messagePayloadVersion, _targets, _values, _calldatas, _messageReceiver, _receiverChainId);
 }
 
 contract UniswapWormholeMessageSender {
     string public constant NAME = "Uniswap Wormhole Message Sender";
 
     // address of the permissioned message sender
     address public owner;
 
     // intermediate state when transfering contract ownership
     address public pendingOwner;
 
     // `nonce` in Wormhole is a misnomer and can be safely set to a constant value.
     uint32 public constant NONCE = 0;
 
     /**
      * consistencyLevel = 1 means finalized on Ethereum, see https://book.wormhole.com/wormhole/3_coreLayerContracts.html#consistency-levels
      *
      * WARNING: Be mindful that if the sender is ever adapted to support multiple consistency levels, the sequence number
      * enforcement in the receiver could result in delivery of a message with a higher sequence number first and thus
      * invalidate the lower sequence number message from being processable on the receiver.  As long as CONSISTENCY_LEVEL
      * remains a constant this is a non-issue.  If this changes, changes to the receiver may be required to address messages
      * of variable consistency.
      */
     uint8 public constant CONSISTENCY_LEVEL = 1;
 
     /**
      * @notice This event is emitted when a Wormhole message is published.
      * @param payload Encoded payload emitted by the Wormhole core contract.
      * @param messageReceiver Recipient contract of the emitted Wormhole message.
      */
     event MessageSent(bytes payload, address indexed messageReceiver);
 
     // Wormhole core contract interface
     IWormhole private immutable wormhole;
 
     /**
      * @param wormholeAddress Address of Wormhole core messaging contract on this chain.
      */
     constructor(address wormholeAddress) {
         // sanity check constructor args
         require(wormholeAddress != address(0), "Invalid wormhole address");
 
         wormhole = IWormhole(wormholeAddress);
         owner = msg.sender;
     }
 
     /**
      * @param targets array of target addresses
      * @param values array of values
      * @param calldatas array of calldatas
      * @param messageReceiver address of the receiver contract
      * @param receiverChainId chain id of the receiver chain
      */
     function sendMessage(
         address[] memory targets,
         uint256[] memory values,
         bytes[] memory calldatas,
         address messageReceiver,
         uint16 receiverChainId
     ) external payable onlyOwner {
         // cache wormhole instance and verify that the caller sent enough value to cover the Wormhole message fee
         IWormhole _wormhole = wormhole;
         uint256 messageFee = _wormhole.messageFee();
 
         require(msg.value == messageFee, "invalid message fee");
 
         // format the message payload
         bytes memory payload = generateMessagePayload(targets, values, calldatas, messageReceiver, receiverChainId);
 
         // send the payload by invoking the Wormhole core contract
         _wormhole.publishMessage{value: messageFee}(NONCE, payload, CONSISTENCY_LEVEL);
 
         emit MessageSent(payload, messageReceiver);
     }
 
     /**
      * @notice Starts process of transferring ownership of the contract. It saves
      * the caller's address in the `pendingOwner` state variable.
      * @param newOwner Address of the `pendingOwner`.
      */
     function submitOwnershipTransferRequest(address newOwner) public onlyOwner {
         require(newOwner != address(0), "newOwner cannot equal address(0)");
 
         pendingOwner = newOwner;
     }
 
     /**
      * @notice Cancels the ownership transfer process.
      * @dev Sets the `pendingOwner` state variable to the zero address.
      */
     function cancelOwnershipTransferRequest() public onlyOwner {
         pendingOwner = address(0);
     }
 
     /**
      * @notice Transfers ownership of the contract to the `pendingOwner`.
      * @dev It updates the `owner` state variable with the `pendingOwner` state
      * variable after validating that the caller is the `pendingOwner`.
      */
     function confirmOwnershipTransferRequest() public {
         require(msg.sender == pendingOwner, "caller must be pendingOwner");
 
         // update the owner in the contract state and reset the pending owner
         owner = pendingOwner;
         pendingOwner = address(0);
     }
 
     modifier onlyOwner() {
         require(msg.sender == owner, "sender not owner");
         _;
     }
 }