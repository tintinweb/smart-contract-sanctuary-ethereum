/**
 *Submitted for verification at Etherscan.io on 2022-11-11
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

contract MorphModules {

    struct MvpContract{
        string ModuleInfo;
    }

    // key value pair of unique id and MvpContract obj
    mapping(uint => MvpContract) MvpContractObj;


    // function store Morph value
    function StoreMorphValue(uint256 workContractObjectiveId, string memory ModuleInfo) public{
        MvpContractObj[workContractObjectiveId] = MvpContract(ModuleInfo);
    }

    // function get Morph value
    function getMorphValue(uint256 workContractObjectiveId) public view returns(string memory){
        return MvpContractObj[workContractObjectiveId].ModuleInfo;
    }
}