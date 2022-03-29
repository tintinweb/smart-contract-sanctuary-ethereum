/**
 *Submitted for verification at Etherscan.io on 2022-03-29
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract Test {

    uint16[] public gen2StakeByToken = [100,200,300,400,500];
    uint16[] public gen2Hierarchy = [0,1,2,3,4];

    function unstake( uint16 _id ) public {
 
        uint16 lastStake = gen2StakeByToken[gen2StakeByToken.length - 1];
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
        gen2Hierarchy = [0,1,2,3,4];
    }

    function getStaked() public view returns ( uint16[] memory ) {
        return gen2StakeByToken;
    }

    function getHierarchy() public view returns ( uint16[] memory ) {
        return gen2Hierarchy;
    }
}