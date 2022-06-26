// SPDX-License-Identifier: MIT


pragma solidity ^0.6.6;
pragma experimental ABIEncoderV2;

contract Sharer {

    constructor() public{
        for (uint256 i = 0; i < 1000; i = i + 1){
            bytes[] storage new2;
            MessageRequests[i] = new2;
        }
    }

    struct PubKey {
       uint256 e;
       uint256 n;
    }

    mapping(uint256 => bytes[]) public MessageRequests;
    mapping(address => bytes) public publicKeys;



    //string[1000][] public MessageRequests;

    function addPublicKey(bytes memory b) public{
        publicKeys[msg.sender] = b;
    }

    function getPubKey(address add) public view returns(bytes memory){
        return publicKeys[add];
    }

    function checkUser(address add) public view returns(bool){
      if(publicKeys[msg.sender].length > 0){
            return true;
        }
        else{
            return false;
        }
    }

    function checkUser() public view returns(bool){
        if(publicKeys[msg.sender].length> 0){
            return true;
        }
        else{
            return false;
        }
    }

    function IwantToContact(bytes memory encryptedMessage, uint256 id) public {
        MessageRequests[id].push(encryptedMessage);
    }

    function hashAddress(address add) public pure returns(uint256){
        uint256 x = uint256(uint160(add));
        return x % 1000;
    }

    function getDataBasic() public view returns(bytes[] memory){
        uint256 myId = hashAddress(msg.sender);
        return MessageRequests[myId];
    }

    /*function getDataFrom(uint256 start) public view returns([] memory){
        uint256 myId = hashAddress(msg.sender);
        string[] memory lookingAt = MessageRequests[myId];
        uint256 numNew = lookingAt.length - start + 1;
        string[] memory out = new string[](numNew);
        uint256 counter = 0;
        for (uint256 i = start; i < lookingAt.length; i = i + 1){
            out[counter] = lookingAt[i];
            counter = counter + 1;
        }
        return out;
    }*/
}