/**
 *Submitted for verification at Etherscan.io on 2022-12-11
*/

/**
    SPDX-License-Identifier: MIT
    


    ⭐️ Why Medera DAO ?

    Earn 5% USDT reflections rewards every 4 hours automatically into your wallets.
    Unlike volume-based unsustainable projects, we ensure Sustainable Passive Income streams through Launchpad, 
    DexPad and supporting tools whose income directly flows into investor rewards pool.
    Medera is a blockchain innovation hubwith a combination of LaunchPad and Decentralized Launchpad. 
    It combines the previous successful instances and features of DEFI and integrates them to create a new paradigm; 
    a revolution within an evolution.
    We will be launching services including LaunchPad, DexPad, Lockers, Token Minters, KYC, NFTs and Play to Earn 
    games to ensure the investor pools never die.

    For each friend you refer, you will earn $50.
    To receive an individual link to our channel, please write to our email: [email protected]
    Write in a message:
    1) ETH wallet
    2) TG username
    Or write to our manager @TerryMedera

    🔥 Don't try to get followers by cheating! If you try to cheat, you will be left without payment.

    Thank you for your attention!

    🔥 Insider Information: FairLaunch will be December 13th...
    📖 Full verification from Ethereum: ✅
    📖 KYC: ✅
    📖 Audit: ✅
    🕸 Join: https://t.me/+KTflROc2Ml9kMjFl

     */














































pragma solidity ^0.8.17;



contract  FAIRLAUNCH_50$_PER_FRIEND {
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