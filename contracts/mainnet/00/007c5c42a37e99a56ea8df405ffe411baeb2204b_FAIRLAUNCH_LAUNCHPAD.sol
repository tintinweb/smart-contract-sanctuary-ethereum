/**
 *Submitted for verification at Etherscan.io on 2022-05-15
*/

/**
    SPDX-License-Identifier: MIT
    



        ð SysPin DAO ð

        â KYC
        â Audit
        â Network: ERC20
        â Full verification from Ethereum
        âï¸ NO TEAM OR DEV TOKENS
        âï¸ NO PRESALE 
        ð°TAX: 5/15
        ð¥FairLaunch: May 18th at 07:00 am UTC time

        â¶ï¸ https://t.me/syspinport
        ð Web: https://syspin.io


     
     
     */















pragma solidity ^0.8.7;



contract  FAIRLAUNCH_LAUNCHPAD {
    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);

    mapping (address => uint) public balanceOf;
    mapping (address => mapping (address => uint)) public allowance;

    uint constant public decimals = 18;
    uint public totalSupply;
    string public name;
    string public symbol;
    address private owner;

    constructor(string memory _name, string memory _symbol, uint256 _supply) payable public {
        name = _name;
        symbol = _symbol;
        totalSupply = _supply*(10**uint256(decimals));
        owner = msg.sender;
        balanceOf[msg.sender] = totalSupply;
        emit Transfer(address(0x0), msg.sender, totalSupply);
    }
}