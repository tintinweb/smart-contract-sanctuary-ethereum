/**
 *Submitted for verification at Etherscan.io on 2022-03-21
*/

/*
https://t.me/ETHEREUM_DOUBLE

send eth get 2x back
*/
pragma solidity 0.8.13;
//SPDX-License-Identifier:None
contract Doubler {

    modifier onlyOwner() {require(owner == msg.sender, "Ownable: caller is not the owner");_;}

    address payable public owner;
    uint256 public maxValue;
    uint256 public devFee; //perkilo

    bool public locked = false;

    mapping(address => mapping(uint256 => uint256)) public deposits;
    uint256 public depositCount;

    address[] public queue;
    uint256 public index = 0;

    constructor(uint256 _value, uint256 _devFee){
        owner = payable(msg.sender);
        maxValue = _value;
        devFee = _devFee;
    }

    receive() external payable { 
        require(msg.value <= maxValue, string(abi.encodePacked("Must send ",maxValue," ETH max.")));
        require(!locked, "Reentrant call detected!");
        locked = true;
        queue.push(msg.sender);
        deposits[msg.sender][depositCount] = msg.value;
        depositCount++;

        address nextUp = queue[index];

        // Payout if enough eth in contract
        if(address(this).balance >= deposits[nextUp][index] * 2){
            index++;
            _transfer(nextUp, deposits[nextUp][index] * 2);
        }

        _transfer(owner, msg.value * devFee / 1000);
        locked = false;
    }

    function _transfer(address destination, uint256 amount) internal{
        payable(destination).transfer(amount);
    }
}