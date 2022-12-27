/**
 *Submitted for verification at Etherscan.io on 2022-12-27
*/

// File: contracts/PUSH.sol

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

interface IPUSHCommInterface {
    function sendNotification(address _channel, address _recipient, bytes calldata _identity) external;
}

contract sendMsgNotification {


    address public  EPNS_COMM_ADDRESS = 0xb3971BCef2D791bc4027BbfedFb47319A4AAaaAa;
    address public channelAddress;

    constructor(address _channelAddress){
        channelAddress = _channelAddress;
    }
    
    function setChannelAddress(address _channelAddress) public {
        channelAddress = _channelAddress;
    }

                            // Wallet address you want to send msg. 
    function sendNotifications(address _to , string memory _msg1, string memory _msg2) public returns (bool) {
        
        IPUSHCommInterface(EPNS_COMM_ADDRESS).sendNotification(
            channelAddress , // Channel Address
            _to, 
            bytes(
                string(             
                    abi.encodePacked(
                        
                        "0", 
                        "+", 
                        "3", 
                        "+", 
                        "New Message!",
                        "+", 
                        "Hooray! ",
                        _msg1, 
                        " sent ",
                        _msg2, 
                        "Message Received!"
                    )
                )
            )
        );

        return true;
    }

}