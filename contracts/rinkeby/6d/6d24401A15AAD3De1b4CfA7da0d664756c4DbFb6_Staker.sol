// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './Rengoku.sol';
import './Ownable.sol';

contract Staker is Ownable{
    
    address private _owner;
    Rengoku private rengoku;
    address[] public stakers;
    uint public tokenBuyPrice = 100;

    mapping(address => uint) public stakingBalance;
    mapping(address => bool) public hasStaked;
    mapping(address => uint) stakersArrayIndexes;

    constructor(Rengoku _rengoku) {
        rengoku = _rengoku;
        _owner = msg.sender;
        uint8 dec = rengoku._decimals();
        rengoku._mint(msg.sender, 1000 * 10 ** dec); 
    }

    function modifyTokenBuyPrice(uint newPrice) public onlyOwner {
        tokenBuyPrice = newPrice;
    }

    function removeElementfromStakers(uint index) public{
        stakers[index] = stakers[stakers.length - 1];
        stakersArrayIndexes[stakers[index]] = index;
        stakers.pop();
    }

    function buyToken() public payable {
        address receiver = msg.sender;
        uint value = msg.value * tokenBuyPrice;
        rengoku.buyToken(receiver, value);
    }

    function stakeToken(uint numOfTokens) public {
        require(numOfTokens <= rengoku.balanceOf(msg.sender), 'Not enough tokens');
        require(numOfTokens > 0, 'Supply value greater than zero');
        rengoku.transferFrom(msg.sender, address(this), numOfTokens);
        stakingBalance[msg.sender] += numOfTokens;
        if (!hasStaked[msg.sender]) {
            stakersArrayIndexes[msg.sender] = stakers.length;
            stakers.push(msg.sender);
            hasStaked[msg.sender] = true;
        }
    }

    function unstakeToken(uint numOfTokens) public {
        require(numOfTokens <= stakingBalance[msg.sender], "You haven't staked up to this amount before.");
        rengoku.transfer(msg.sender, numOfTokens);
        stakingBalance[msg.sender] -= numOfTokens;
        if (stakingBalance[msg.sender] == 0) {
            removeElementfromStakers(stakersArrayIndexes[msg.sender]);
            hasStaked[msg.sender] = false;
        }
    }

    function claimRewards() public {
        require(stakingBalance[msg.sender] > 0, "You don't have token staked");
        stakingBalance[msg.sender] += stakingBalance[msg.sender] / 100;
    }

    function issueToken() public onlyOwner {
        for (uint i = 0; i < stakers.length; i++) {
            rengoku.transferFrom(address(_owner), stakers[i], stakingBalance[stakers[i]]);
        }
    }

    function getTokenBalance() public view returns (uint) {
        return rengoku.balanceOf(msg.sender);
    }

    function getAmountStaked() public view returns (uint) {
        return stakingBalance[msg.sender];
    }


}