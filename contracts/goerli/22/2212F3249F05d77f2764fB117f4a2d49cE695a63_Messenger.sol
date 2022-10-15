/**
 *Submitted for verification at Etherscan.io on 2022-10-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract Messenger{

    address [] public authorisedAddresses;

    struct User {
        address sender;
        string message;
    }
    constructor(){
        authorisedAddresses.push(msg.sender);
    }

    User[] internal user;

    function authoriseAddress(address _input) public {
        require(verifyAddress() == true, "User not authorised");
        authorisedAddresses.push(_input);
    }
    function writeMessage(string calldata _input) public {
        require(verifyAddress() == true, "User not authorised");
        user.push(User(msg.sender, _input));
    }
    function userLength() public view returns (uint) {
        return user.length;
    }
    function addressLength() internal view returns (uint) {
        return authorisedAddresses.length;
    }
    function verifyAddress() internal view returns (bool) {
        uint i = 0;
        while (i <= addressLength()){
            if (authorisedAddresses[i] == msg.sender) {
                return true;
            }
            ++i;
        }
        return false;
    }
    function lastMessage() public view returns (string memory) {
        require(verifyAddress() == true, "User not authorised");
        User storage text = user[userLength()-1];
            return text.message;
    }
    function viewMessages(uint _input) public view returns(address, string memory){
        require(verifyAddress() == true, "User not authorised");
        User storage text = user[_input];
            return (text.sender, text.message);
    }
}