/**
 *Submitted for verification at Etherscan.io on 2023-06-01
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

interface IERC7017 {
    /// @notice Send a direct message to an address.
    /// @dev `from` must be equal to either the smart contract address
    /// or msg.sender. `to` must not be the zero address.
    event DirectMsg (address indexed from, address indexed to, bytes[] message, bool is_encrypted);
    
    /// @notice Broadcast a message to a general public.
    /// @dev `from` parameter must be equal to either the smart contract address
    /// or msg.sender.
    event BroadcastMsg (address indexed from, bytes[] message);
    
    /**
    * @dev Send a notification to an address from the address executing the function
    * @param to address to send a notification to
    * @param message to send: 
    * [subject, body, Is encrypred (0x01, 0x00), image url (optional),
    * transaction request (optional, ERC-681 format)]
    * @param is_encrypted 0 if message is not encrypted, 1 if it is
    */
    function walletDM (address to, bytes[] memory message, bool is_encrypted) external;

    /**
    * @dev Send a notification to an address from the smart contract
    * @param to address to send a notification to
    * @param message to send:
    * [subject, body, Is encrypred (0x01, 0x00), image url (optional),
    * transaction request (optional, ERC-681 format)]
    * @param is_encrypted 0 if message is not encrypted, 1 if it is
    */
    function contractDM (address to, bytes[] memory message, bool is_encrypted) external;
    
    /**
    * @dev Send a general notification from the address executing the function
    * @param message to broadcast:
    * [subject, body, attention level (1, 2 or 3), image url (optional),
    * transaction request (optional, ERC-681 format)]
    */
    function walletBroadcast (bytes[] memory message) external;

    /**
    * @dev Send a general notification from the address executing the function
    * @param message to broadcast:
    * [subject, body, attention level (1, 2 or 3), image url (optional),
    * transaction request (optional, ERC-681 format)]
    */
    function contractBroadcast (bytes[] memory message) external;
}




contract ERC7017 is IERC7017 {
    /**
    * @dev Send a notification to an address from the address executing the function
    * @param to address to send a notification to
    * @param message to send: 
    * [subject, body, Is encrypred (0x01, 0x00), image url (optional),
    * transaction request (optional, ERC-681 format)]
    */
    function walletDM (address to, bytes[] memory message, bool is_encrypted) external virtual override {
        emit DirectMsg(msg.sender, to, message, is_encrypted);
    }

    /**
    * @dev Send a notification to an address from the smart contract
    * @param to address to send a notification to
    * @param message to send: 
    * [subject, body, Is encrypred (0x01, 0x00), image url (optional),
    * transaction request (optional, ERC-681 format)]
    */
    function contractDM (address to, bytes[] memory message, bool is_encrypted) external virtual override {
        emit DirectMsg(address(this), to, message, is_encrypted);
    }
    
    /**
    * @dev Send a general notification from the address executing the function
    * @param message to broadcast:
    * [subject, body, attention level (1, 2 or 3), image url (optional),
    * transaction request (optional, ERC-681 format)]
    */
    function walletBroadcast (bytes[] memory message) external virtual override {
        emit BroadcastMsg (msg.sender, message);
    }

    /**
    * @dev Send a general notification from the address executing the function
    * @param message to broadcast:
    * [subject, body, attention level (1, 2 or 3), image url (optional),
    * transaction request (optional, ERC-681 format)]
    */
    function contractBroadcast (bytes[] memory message) external virtual override {
        emit BroadcastMsg (address(this), message);
    }
}