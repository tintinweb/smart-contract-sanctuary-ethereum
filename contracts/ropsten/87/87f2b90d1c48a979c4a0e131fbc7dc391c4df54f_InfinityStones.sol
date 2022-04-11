/**
 *Submitted for verification at Etherscan.io on 2022-04-11
*/

//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.7.0;

contract InfinityStones {
    string public name = "Infinity Stones";
    string public symbol = "Stones";
    bool public stonesOnGauntlet = false;

    address public thanos;
    address public proximaMidnight;
    address public corvusGlaive;

    mapping(address => uint256) balances;

    constructor(address _proximaMidnight, address _corvusGlaive) {
        balances[msg.sender] = 4;
        balances[_proximaMidnight] = 1;
        balances[corvusGlaive] = 1;
        stonesOnGauntlet = false;
        thanos = msg.sender;
        proximaMidnight = _proximaMidnight;
        corvusGlaive = _corvusGlaive;
    }

    function activate() public {
        require(msg.sender == thanos, "Stones are very powerful, only thanos has ability to wear all the stones.");
        stonesOnGauntlet = true;
    }

    // Avengers need a method to transfer stones to each other.
    // You know because Thanos is trying to steal your stones back! If you have any?
    function transfer(address to) external {
        require(stonesOnGauntlet, "Thanos has not put on all the stones on the Gaunlet yet. Dr. Strange says wait, Ironman!!");
        require(balances[msg.sender] >= 1, "You do not have any stones!");

        balances[to] += 1;

        // Stones are very precious. We need to give a callback before we confirm anything or do we? Look closely.
        msg.sender.call("check");
        balances[msg.sender] -= 1;
    }

    function balanceOf(address account) external view returns (uint256) {
        return balances[account];
    }

    // Thanos being thanos have made an funtionality to destroy all the stones.
    // He will destroy stones so that no one can use stones to reverse his actions.
    function destroy(address payable _to) public {
        require(msg.sender == thanos, "Stones are very powerful, only thanos can destory them. Even if it will almost kill him.");
        selfdestruct(_to);
    }
}