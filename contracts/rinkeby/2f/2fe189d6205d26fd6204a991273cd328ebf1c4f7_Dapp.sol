/**
 *Submitted for verification at Etherscan.io on 2022-05-30
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Dapp {
    address public owner;
    mapping(string => string) public musicManage;
    mapping(string => address) public musicToaddress;

    event storeMusic(string name, string url,uint money);
    event transferOriginAddress(address origin, uint value);

    constructor()payable{
        require(msg.value <= 1000000 wei);
        owner = msg.sender;
    }

    function uploadMusic(string calldata name, string calldata ipfsHash)public payable{
       musicManage[name] = string(abi.encodePacked("https://ipfs.io/ipfs/",ipfsHash));
       musicToaddress[name]=msg.sender;
       emit storeMusic(name,string(abi.encodePacked("https://ipfs.io/ipfs/",ipfsHash)),20000);
    }

    function downloadMusic(string calldata name)public payable returns(string memory){
        payable(musicToaddress[name]).transfer(10000 wei);
        emit transferOriginAddress(musicToaddress[name],10000);
        return musicManage[name];
    }
}