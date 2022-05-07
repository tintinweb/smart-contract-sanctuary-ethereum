/**
 *Submitted for verification at Etherscan.io on 2022-05-07
*/

pragma solidity ^0.6.0;

contract Counter{
    uint count; // uint: unsigned integer, means always +ve

    constructor() public {
        count = 0;
    }

    function getCount() public view returns(uint){
        return count;
    }

    function incCount() public {
         count += 1;
    }
}