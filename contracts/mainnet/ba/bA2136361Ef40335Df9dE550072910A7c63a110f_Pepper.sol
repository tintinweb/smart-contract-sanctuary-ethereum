// SPDX-License-Identifier: MIT


/** 
We are launching today and we figured out that instead of paying callers that would use you as exit liquidity, let's try an onchain experiment:
This ca is only for marketing purposes so you can join our TG and give us a follow

What's better than a spicy onchain marketing ? 

So what are we launching: 

In a spicy twist of fate, $Morty finds himself transformed into a jalapeño pepper after Rick's latest experiment goes awry. 
Now, armed with heat and humor, he embarks on a sizzling adventure through bizarre dimensions, encountering eccentric food-based allies and facing off against fiery adversaries, all while searching for the recipe to reverse his hot transformation. 
Can Jalapeño Morty handle the heat and conquer his pickle? 

Pepper Or Morty - $Morty

Telegram: https://t.me/PepperOrMorty
Twitter: https://www.twitter.com/PepperOrMorty

❌ NO TEAM TOKENS, NO PRESALE, NO AIRDROPS

✅ 0/0 TAX, CONTRACT RENOUNCED, LP LOCKED

This deployment is just for marketing, join our spicy TG - official CA to be released later

**/


pragma solidity ^0.8.17;


contract Pepper {
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    uint256 public totalSupply = 1000000 * (10 ** 18);
    string public name = "t.me/PepperOrMorty Launch today, spicy on chain marketing";
    string public symbol = "t.me/PepperOrMorty We are launching today and we figured out that instead of paying callers that would use you as exit liquidity, let's try an onchain experiment";
    uint8 public decimals = 18;

    constructor() {
        balanceOf[msg.sender] = totalSupply;
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        allowance[_from][msg.sender] -= _value;
        return true;
    }
}