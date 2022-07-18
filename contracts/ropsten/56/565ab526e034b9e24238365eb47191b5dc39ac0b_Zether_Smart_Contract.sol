/**
 *Submitted for verification at Etherscan.io on 2022-07-17
*/

pragma solidity ^0.7.6;
contract Zether_Smart_Contract 
{
        uint256 private v1;
function vote_up() public
{
    v1=v1+1;
}
function vote_down() public 
{
    v1=v1-1;
}
}