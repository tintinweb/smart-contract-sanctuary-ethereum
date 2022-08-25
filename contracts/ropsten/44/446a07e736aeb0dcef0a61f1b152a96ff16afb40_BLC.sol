/**
 *Submitted for verification at Etherscan.io on 2022-08-24
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;
contract BLC {
    struct People{
        string  Name;
        uint Age;
        string Data;
    }
    People[] public peopels;
    mapping (uint =>address) IdAdress;
    function _set(string memory _Name , uint _Age , string  memory _Data)public returns(uint){
        peopels.push(People(_Name,_Age,_Data));
        uint id = peopels.length -1;
        IdAdress[id]=msg.sender;
        return id;
    }
    function _get(uint ID) public view returns(uint, string memory ,uint, string memory ){
        require(msg.sender==IdAdress[ID]);
        return (ID,"Milad",17,"I Am Milad");
    }
    }