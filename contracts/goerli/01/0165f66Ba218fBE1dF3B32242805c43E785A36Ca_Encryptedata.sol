/**
 *Submitted for verification at Etherscan.io on 2023-06-01
*/

/**
 *Submitted for verification at Etherscan.io on 2023-05-11
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

contract Encryptedata {

    // string[] messages;
    mapping(address=>string) public publickeys;
    mapping (address=> string[]) public messageDetails;


    function sendPublicKey (string memory _pubkey) public {
    publickeys[msg.sender]=_pubkey;
    }

    function  viewPublickEY(address reciever) view public returns(string memory ){
    return publickeys[reciever];
    }


    function storeData(string memory _message,address reciever) public {
        messageDetails[reciever].push(_message);
    }

    function viewMessage(address reciever) view public returns(string[] memory){

    return messageDetails[reciever];
    }

    function viewMessageByIndex(uint _index,address reciever) view public returns (string memory){

// for (uint i=0; i <= messageDetails[reciever].length;++i){
    return messageDetails[reciever][_index];
// }
    }
}