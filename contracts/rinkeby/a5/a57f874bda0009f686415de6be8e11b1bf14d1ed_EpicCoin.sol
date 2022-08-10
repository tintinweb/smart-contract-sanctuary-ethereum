/**
 *Submitted for verification at Etherscan.io on 2022-08-09
*/

//SPDX_License-Identifier: MIT

pragma solidity >=0.7.0<0.9.0;

contract MyEpicCoin{

    uint availableSupply;
    uint maxSupply;

    constructor (uint _availableSupply, uint _maxSupply){

        availableSupply = _availableSupply;
        maxSupply = _maxSupply;
    }
}

contract EpicCoin is MyEpicCoin{

    constructor(uint ass, uint ms) MyEpicCoin(ass,ms){}

    function getas() public view returns(uint){
        return availableSupply;
    }

    function getms() public view returns(uint){
        return maxSupply;
    }
}