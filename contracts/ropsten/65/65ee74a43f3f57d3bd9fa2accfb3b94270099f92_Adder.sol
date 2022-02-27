/**
 *Submitted for verification at Etherscan.io on 2022-02-27
*/

pragma solidity >=0.8.2; 

contract Adder {
    uint public a;
    uint public b;
    uint public sum;

    function add(uint a_, uint b_) external returns (uint sum_) {
        a = a_;
        b = b_;
        sum_ = a_ + b_;
        return sum_;
    }
}