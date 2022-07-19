/**
 *Submitted for verification at Etherscan.io on 2022-07-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.5.0;

contract DoorLockContract{

    mapping (string => address) nftMappings;
    address admin;

    constructor() public{
      admin = msg.sender;
    }


    function map(address owner,string memory nft) public{
        require(msg.sender == admin);
        nftMappings[nft] = owner;
    }

    function unmap(string memory nft) public{
        require(msg.sender ==admin);
        delete nftMappings[nft];
    }

    function check_owner(address checkable,string memory nft) public view returns (bool) {
        if(nftMappings[nft] == checkable){
            return true;
        }else{
            return false;
        }
    }
}