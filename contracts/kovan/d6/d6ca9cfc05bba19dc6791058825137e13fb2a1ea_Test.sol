/**
 *Submitted for verification at Etherscan.io on 2022-06-03
*/

pragma solidity ^0.8.7;
contract Test{
    constructor() public{

    }
    function getResult(address input) public view returns(uint256){
        address myAddress = input;
        uint256 result = myAddress.balance;
        return result;
    }
}