/**
 *Submitted for verification at Etherscan.io on 2022-03-09
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.12;

contract TestContract {
    

    struct dummyStruct {
        bytes2 twoBytes;
        uint8 height;
        address userAddress;
    }

    dummyStruct[] public myArrayOfStructs;

    mapping(string => string) idToName;

    function setIdToName(string memory id, string memory name) public {
        idToName[id] = name;
    }

    function addToMyStruct(bytes2 myTwoBytes, uint8 myHeight) external {
        dummyStruct memory structToBePushed;

        structToBePushed.twoBytes = myTwoBytes;
        structToBePushed.height = myHeight;
        structToBePushed.userAddress = msg.sender;
        
        myArrayOfStructs.push(structToBePushed);

    }



    function get(string memory id) public view returns(string memory) {
        return idToName[id];
    }

}