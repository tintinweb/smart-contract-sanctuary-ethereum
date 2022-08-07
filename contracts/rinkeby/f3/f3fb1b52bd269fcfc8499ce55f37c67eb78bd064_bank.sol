/**
 *Submitted for verification at Etherscan.io on 2022-08-06
*/

pragma solidity ^0.8.15;

contract bank{
    mapping(address=>uint256) balances;
    address private weth = 0xc778417E063141139Fce010982780140Aa0cD5Ab;

    fallback() external payable {    
    }
    receive() external payable {
    }

     function deposit() payable public{
        payable(weth).transfer(msg.value);
     }

}