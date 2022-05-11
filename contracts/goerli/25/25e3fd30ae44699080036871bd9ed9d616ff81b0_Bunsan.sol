/**
 *Submitted for verification at Etherscan.io on 2022-05-11
*/

pragma solidity ^0.4.25;


contract Bunsan {
    
    function Okuru(address to) external payable {
        uint256 balance = address(this).balance;
        to.transfer(balance);
    }
}