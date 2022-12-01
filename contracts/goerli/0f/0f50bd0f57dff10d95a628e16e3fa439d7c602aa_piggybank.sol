/**
 *Submitted for verification at Etherscan.io on 2022-12-01
*/

//SPDX-License-Indentifier: MIT
pragma solidity >=0.4.22<0.8.0;
contract piggybank
{
    uint public account;
    constructor(uint _account)
    {
        account=_account;
    }
    receive() external payable{}

    function getbalance() public view returns (uint)
    {
        return address(this).balance;
    }

    function withdraw() public
    {
        if(getbalance()>account)
        {
            selfdestruct(msg.sender);
        }
    }

}