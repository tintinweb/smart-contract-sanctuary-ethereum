/**
 *Submitted for verification at Etherscan.io on 2022-03-29
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract Test {

    uint[] public gen2StakeByToken = [100,200,300,400,500];
    mapping(uint => uint) public gen2Hierarchy; 

    constructor() {
        gen2Hierarchy[0] = 0;
        gen2Hierarchy[1] = 1;
        gen2Hierarchy[2] = 2;
        gen2Hierarchy[3] = 3;
        gen2Hierarchy[4] = 4;
    }

    function unstake( uint _id ) public {
 
        uint lastStake = gen2StakeByToken[gen2StakeByToken.length - 1];
        gen2StakeByToken[gen2Hierarchy[_id]] = lastStake;
        gen2Hierarchy[gen2StakeByToken.length - 1] = gen2Hierarchy[_id];
        gen2StakeByToken.pop();
        delete gen2Hierarchy[_id];
    }

    function test() public {
        
        unstake(4);
        unstake(2);
        unstake(0);

    }

    function test2() public {
        
        unstake(3);
        unstake(1);

    }

    function reset() public {
        gen2StakeByToken = [100,200,300,400,500];
        gen2Hierarchy[0] = 0;
        gen2Hierarchy[1] = 1;
        gen2Hierarchy[2] = 2;
        gen2Hierarchy[3] = 3;
        gen2Hierarchy[4] = 4;
    }

    function getStaked() public view returns ( uint[] memory ) {
        return gen2StakeByToken;
    }

    function getHierarchyItem( uint index ) public view returns ( uint ) {
        uint item = gen2Hierarchy[index];
        return item;
    }
}