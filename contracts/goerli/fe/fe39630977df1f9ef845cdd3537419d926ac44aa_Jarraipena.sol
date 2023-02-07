/**
 *Submitted for verification at Etherscan.io on 2023-02-07
*/

// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;

contract Jarraipena{

    string[] hiriak;
    uint hiriKopurua;
    uint constant hiriMaximoa=10;

    constructor(){
        hiriKopurua=0;
        hiriak=new string[](hiriMaximoa);
    }

    function hiriBerria(string memory h) public {
        if(hiriKopurua < hiriMaximoa){
            hiriak.push(h);
            hiriKopurua++;
        }
    }

    function getHiriak () public view returns (string[] memory){
        return hiriak;
    }
}