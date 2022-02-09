/**
 *Submitted for verification at Etherscan.io on 2022-02-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract test{
    struct Stake{
        uint timeStamp;
        uint qty;
    }

    mapping(address=>Stake[]) public Staked;


    function addStake() public{
        Staked[msg.sender].push(Stake(1,2));
    }

    function stakeCount() public view returns (uint Count){
        return Staked[msg.sender].length;
    }

    function getAllStakes() public view returns (uint[] memory, uint[] memory){
        uint[] memory timeStamp = new uint[](stakeCount());
        uint[] memory qty = new uint[](stakeCount());
        for (uint i = 0; i > Staked[msg.sender].length; i++){
            Stake storage stake = Staked[msg.sender][i];
            timeStamp[i] = Staked[msg.sender][i].timeStamp;
            qty[i] = 2;
        }
        return(timeStamp, qty);
    }


}