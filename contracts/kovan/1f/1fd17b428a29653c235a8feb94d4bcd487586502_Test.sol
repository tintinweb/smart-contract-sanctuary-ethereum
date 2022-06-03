/**
 *Submitted for verification at Etherscan.io on 2022-06-03
*/

pragma solidity ^0.8.7;
contract Test{
    constructor() public{

    }
    function getResult() public view returns(uint256){
        address myAddress = 0xd9145CCE52D386f254917e481eB44e9943F39138;
        uint256 result = myAddress.balance;
        return result;
    }
}