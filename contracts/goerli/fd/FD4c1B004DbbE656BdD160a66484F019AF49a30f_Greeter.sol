// SPDX-License-Identifier: MIT
pragma solidity >0.5.0 <0.9.0;

/**
 * @title ICrossDomainMessenger
 */
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

// SPDX-License-Identifier: GPL-3.0
// [Acknowledgement]
//     This contract was inspired by NomicFoundation/hardhat `Greeter.sol` 
//     and ethereum-optimism/optimism-tutorial `Greeter.sol`.
pragma solidity ^0.8.17;

import "@eth-optimism/contracts/libraries/bridge/ICrossDomainMessenger.sol";

contract Greeter {
    string public greeting;
    
    event GreetingUpdated(
        address msg_sender,
        address tx_origin,
        address xd_origin,
        string old_greeting,
        string new_greeting
    );
    
    constructor() {
        greeting = "Hello";
    }
    
    function setGreeting(string memory _greeting) public {
        emit GreetingUpdated(msg.sender, tx.origin, getXOrig(), greeting, _greeting);
        greeting = _greeting;
    }
    
    // Get the address of cross domain message sender or return `address(0)` 
    // if caller is not the cross domain messenger.
    function getXOrig() private view returns (address) {
        address cdm_address;
        
        assembly {
            switch chainid()
            // L1: Mainnet
            case 1   { cdm_address := 0x25ace71c97B33Cc4729CF772ae268934F7ab5fA1 }
            // L1: Goerli
            case 5   { cdm_address := 0x5086d1eEF304eb5284A0f6720f79403b4e9bE294 }
            // L2: Optimism Maninet
            case 10  { cdm_address := 0x4200000000000000000000000000000000000007 }
            // L2: Optimism Goerli
            case 420 { cdm_address := 0x4200000000000000000000000000000000000007 }
            default  { cdm_address := 0x0000000000000000000000000000000000000000 }
        }
        
        // If `msg.sender` is not the cross domain messenger
        if (msg.sender != cdm_address) {
            return address(0);
        }
        else {
            return ICrossDomainMessenger(cdm_address).xDomainMessageSender();
        }
    }
}