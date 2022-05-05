/**
 *Submitted for verification at Etherscan.io on 2022-05-05
*/

pragma solidity ^0.5.17;
contract test{
    constructor() payable public{

    }
    uint public a=0;
    function test1() public{
        a+=1;
        test1();
    }
}