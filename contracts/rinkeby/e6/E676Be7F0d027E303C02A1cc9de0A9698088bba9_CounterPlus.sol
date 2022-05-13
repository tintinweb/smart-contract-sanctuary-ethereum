/**
 *Submitted for verification at Etherscan.io on 2022-05-13
*/

pragma solidity 0.5.1;

contract CounterPlus {
    uint public count = 0;

    event Increment(uint value);
    event Decrement(uint value);

    function getCount() view public returns(uint){
        return count;
    }

    function increment(uint amount) public{
        count += amount;
        emit Increment(count);
    }

    function decrement(uint amount) public{
        count -= amount;
        emit Decrement(count);
    }
}