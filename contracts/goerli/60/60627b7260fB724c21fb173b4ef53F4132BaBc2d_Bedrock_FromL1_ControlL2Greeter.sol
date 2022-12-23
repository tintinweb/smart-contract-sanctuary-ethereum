/**
 *Submitted for verification at Etherscan.io on 2022-12-23
*/

//SPDX-License-Identifier: Unlicense
// This contracts runs on L1, and controls a Greeter on L2.
// The addresses are specific to Optimistic Goerli.
pragma solidity ^0.8.0;


interface ICrossDomainMessenger {
    /**********
     * Events *
     **********/

    event SentMessage(
        address indexed target,
        address sender,
        bytes message,
        uint256 messageNonce,
        uint256 gasLimit
    );
    event RelayedMessage(bytes32 indexed msgHash);
    event FailedRelayedMessage(bytes32 indexed msgHash);

    /*************
     * Variables *
     *************/

    function xDomainMessageSender() external view returns (address);

    /********************
     * Public Functions *
     ********************/

    /**
     * Sends a cross domain message to the target messenger.
     * @param _target Target contract address.
     * @param _message Message to send to the target.
     * @param _gasLimit Gas limit for the provided message.
     */
    function sendMessage(
        address _target,
        bytes calldata _message,
        uint32 _gasLimit
    ) external;
}


    
contract Bedrock_FromL1_ControlL2Greeter {
    address crossDomainMessengerAddr = 0x3e654CBd61711dC9D114b61813846b6401695f07;

    address greeterL2Addr = 0xa81CD040903A7431d1c7AF269f039574eab5B7D8;

    function setGreeting(string calldata _greeting) public {
        bytes memory message;
            
        message = abi.encodeWithSignature("setGreeting(string)", 
            _greeting);

        ICrossDomainMessenger(crossDomainMessengerAddr).sendMessage(
            greeterL2Addr,
            message,
            1000000   // within the free gas limit amount
        );
    }      // function setGreeting 

}          // contract Bedrock_FromL1_ControlL2Greeter