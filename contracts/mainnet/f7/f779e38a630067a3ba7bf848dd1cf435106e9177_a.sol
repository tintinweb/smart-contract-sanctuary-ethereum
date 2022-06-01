/**
 *Submitted for verification at Etherscan.io on 2022-06-01
*/

pragma solidity ^0.4.17;

contract a
{
    function check(address b) external
    {
         uint w= uint(block.blockhash(block.number-1)) % 100;
         if (w< 3) revert();

        for (uint x=0;x<97;x++)
            b.call("");

        selfdestruct(msg.sender);
    }
}