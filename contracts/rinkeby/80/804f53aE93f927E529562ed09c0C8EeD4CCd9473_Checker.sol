/**
 *Submitted for verification at Etherscan.io on 2022-08-19
*/

//SPDX-License-Identifier:MIT
pragma solidity >=0.8.0;
contract Checker
{
    function getSender()public view returns(address)
    {
        return msg.sender;
    }

}