/**
 *Submitted for verification at Etherscan.io on 2022-05-08
*/

/**
 *Submitted for verification at kovan-optimistic.etherscan.io on 2022-05-08
*/

/**
 *Submitted for verification at kovan-optimistic.etherscan.io on 2022-02-25
*/

//SPDX-License-Identifier: Unlicense
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

    
contract ControlL2Greeter {
    address crossDomainMessengerAddr = 0x4361d0F75A0186C05f971c566dC6bEa5957483fD;

    address greeterL2Addr = 0x758156653EE2cD504e054f12243Ce33b4F8e2913;

    function setGreeting(string calldata _greeting) public {
        bytes memory message;
            
        message = abi.encodeWithSignature("setGreeting(string,string)", 
            _greeting, _greeting);

        ICrossDomainMessenger(crossDomainMessengerAddr).sendMessage(
            greeterL2Addr,
            message,
            1000000   // within the free gas limit amount
        );
    }      // function setGreeting 

}          // contract ControlL2Greeter