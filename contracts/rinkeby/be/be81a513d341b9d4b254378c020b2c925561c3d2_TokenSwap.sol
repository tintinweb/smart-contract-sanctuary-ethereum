/**
 *Submitted for verification at Etherscan.io on 2022-02-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
/*
How to swap tokens

1. Alice has 100 tokens from USDT, which is a ERC20 token.
2. BattleVerse Owner has 1000000 tokens from BVC, which is also a ERC20 token.
3. Alice wants to buy 1000BVC from 50 USDT.
4. Developer deploys the TokenSwap Contract.
5. Alice approves TokenSwap to withdraw 50 tokens from USDT (using web3.js)
6. BattleVerse Owner approves TokenSwap to withdraw 1000*1000 tokens from BVC ( Becuase only 1000 users will use this contract)
7. Alice calls TokenSwap.Claim()
8. Alice buy BVC tokens successfully.
*/
interface Interface20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address tokenOwner) external view returns (uint);
    function allowance(address tokenOwner, address spender) external view returns (uint remaining);
    function transfer(address to, uint tokens) external;
    function approve(address spender, uint tokens) external;
    function transferFrom(address from, address to, uint tokens) external;
}

contract TokenSwap {
    Interface20 public usdt_token = Interface20(0xD9BA894E0097f8cC2BBc9D24D308b98e36dc6D02); // rinkeby testnet usdt address
    address public owner1;
    uint public amount1;
    Interface20 public bvc_token = Interface20(0x53dDd05C27Abd70e2A4a7B71E57DfA5329974358); // rinkeby testnet bvc address
    address public owner2;
    uint public amount2;

    address public realOwner = 0x804161E270eB0D412501de2244EE94a60e4DD4f4; // bvc token owner should approve 1000*1000 token to this smart contract before users using this smart contract.
    constructor(
    ) {
    }
    function Claim() public {
        require(
            usdt_token.allowance(msg.sender, address(this)) >= 50*10**18,
            "USDT allowance too low"
        );
        require(
            bvc_token.allowance(realOwner, address(this)) >= amount2,
            "BVC allowance too low"
        );

        _safeTransferFrom(usdt_token, msg.sender, address(this), 50*10**18);
        _safeTransferFrom(bvc_token, realOwner, msg.sender, 1000*10**18);
    }

    function _safeTransferFrom(
        Interface20 token,
        address sender,
        address recipient,
        uint amount
    ) private {
        token.transferFrom(sender, recipient, amount);
    }
}