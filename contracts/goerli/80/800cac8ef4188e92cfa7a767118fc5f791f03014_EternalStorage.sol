/**
 *Submitted for verification at Etherscan.io on 2022-04-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract EternalStorage{
    mapping(bytes32 => uint256) internal uintStorage;
}

contract Token_V0 is EternalStorage{

    function totalSupply() public view returns (uint256) {
        return uintStorage[keccak256("2022041301.totalSupply")];
    }

    function setTotalSupply() public virtual  returns (bool) {
       uintStorage[keccak256("2022041301.totalSupply")]=uintStorage[keccak256("2022041301.totalSupply")]+10;
        return true;
    }

}