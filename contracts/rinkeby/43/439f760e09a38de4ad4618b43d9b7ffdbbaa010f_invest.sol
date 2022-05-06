/**
 *Submitted for verification at Etherscan.io on 2022-05-06
*/

pragma solidity ^0.4.26;

contract invest{
    uint public investors = 0;

    // "payable" modifier : this function can transfer/receive money
    function pay() public payable{
        investors++;
       
    }
}