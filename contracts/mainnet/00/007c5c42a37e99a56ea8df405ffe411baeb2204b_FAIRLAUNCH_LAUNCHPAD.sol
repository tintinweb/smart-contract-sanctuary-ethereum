/**
 *Submitted for verification at Etherscan.io on 2022-05-15
*/

/**
    SPDX-License-Identifier: MIT
    



        🌟 SysPin DAO 🌟

        ✅ KYC
        ✅ Audit
        ✅ Network: ERC20
        ✅ Full verification from Ethereum
        ⛔️ NO TEAM OR DEV TOKENS
        ⛔️ NO PRESALE 
        💰TAX: 5/15
        🔥FairLaunch: May 18th at 07:00 am UTC time

        ▶️ https://t.me/syspinport
        🌎 Web: https://syspin.io


     
     
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