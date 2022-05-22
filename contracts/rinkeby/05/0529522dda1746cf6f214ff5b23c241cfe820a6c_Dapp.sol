/**
 *Submitted for verification at Etherscan.io on 2022-05-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract Dapp{

    address public owner;

    mapping(string => string) private pictureManage;
    event storePic(string name, string url);

    constructor(){
        owner = msg.sender;
    }

    function storePicture(string calldata name, string calldata ipfsHash)public{
        pictureManage[name]=ipfsHash;
        emit storePic(name,ipfsHash);
    }

    function callPic(string calldata name) view public returns(string memory){
        return pictureManage[name];
    }
}