/**
 *Submitted for verification at Etherscan.io on 2023-03-06
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 * @custom:dev-run-script ./scripts/deploy_with_ethers.ts
 */
contract PublicChat {

    mapping (address => string) a_to_n;
    address[] addresses;
    string[] names;

    address host;
    string[] chatLog;
    string[] chatterLog;

    constructor() {
        host = msg.sender;
        addresses.push(msg.sender);
        names.push("Bas");
        a_to_n[msg.sender] = "Bas";
    }


    function addMe(string calldata _name) public {
        bool address_exists = false;
        for (uint i = 0; i< addresses.length; i++) {
            if (msg.sender == addresses[i]) {
                address_exists = true;
                break;
            }
        }
        require(address_exists == false, "Address known");

        addresses.push(msg.sender);
        names.push(_name);
        a_to_n[msg.sender] = _name;
    }

    function post(string calldata _message) public {
        bool address_exists = false;
        for (uint i = 0; i< addresses.length; i++) {
            if (msg.sender == addresses[i]) {
                address_exists = true;
                break;
            }
        }
        require(address_exists == true, "Address unknown");

        chatterLog.push(a_to_n[msg.sender]);
        chatLog.push(_message);
    }

    function showLastMessages(uint256 nr_of_messages) public view returns (string memory) {
        string memory chat = "";
        if (chatLog.length == 0) {
            return "This chat sure looks empty";
        }
        require(chatLog.length >= nr_of_messages, "Too far back");
        for (uint i = chatLog.length - nr_of_messages; i < chatLog.length; i++) {
            string memory line = string.concat(chatterLog[i], ": ", chatLog[i]);
            chat = string.concat(chat, line, "; ");
        }
        return chat;
    }

    function showChat() public view returns (string memory) {
        return showLastMessages(chatLog.length);
    }

    function showPeople() public view returns (string[] memory) {
        return names;
    }    

}