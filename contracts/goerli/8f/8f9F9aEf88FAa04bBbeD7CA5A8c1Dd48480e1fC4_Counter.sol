/**
 *Submitted for verification at Etherscan.io on 2022-07-23
*/

pragma solidity 0.8.15;
contract Counter{
    int public count = 0;
    function increment() public{
        count = count + 1;
    }
    function decrement() public{
        count = count - 1;
    }
}