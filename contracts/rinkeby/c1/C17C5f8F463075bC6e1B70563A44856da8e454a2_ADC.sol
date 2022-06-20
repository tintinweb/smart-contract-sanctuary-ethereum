/**
 *Submitted for verification at Etherscan.io on 2022-06-20
*/

// File: Swap_token.sol


pragma solidity ^0.8.15;

contract ADC {
    uint256 costPopular = 0.051 ether;

    function check_cost() public view returns(uint256){
        return costPopular;
    }

    function set_cost(uint256 new_cost) public{
        costPopular = new_cost;
    }
}