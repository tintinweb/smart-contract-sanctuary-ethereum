// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;

import "./Token.sol";

contract EthSwap {
    string public name = "EthSwap Instant Exchange";
    Token public token;
    uint public rate = 100;

    event TokensPurchased(
        address account,
        address token,
        uint amount,
        uint rate
    );

    event TokensSold(
        address account,
        address token,
        uint amount,
        uint rate
    );

    constructor(Token _token) {
        token = _token;
    }

    function buyTokens() public payable {
        // Check if msg.sender transfer Ether(msg.value) to this contract or not
        uint tokenAmount = msg.value * rate; 
        require(token.balanceOf(address(this)) >= tokenAmount);
        // transfer tokens from this contract to msg.sender
        token.transfer(msg.sender, tokenAmount);
        emit TokensPurchased(msg.sender, address(token), tokenAmount, rate);
    }
    function sellTokens(uint _amount) public {
        require(token.balanceOf(msg.sender) >= _amount);
        uint etherAmount = _amount / rate;
        require(address(this).balance >= etherAmount);
        // transfer token from msg.sender to this contract (sell)
        token.transferFrom(msg.sender, address(this), _amount);
        // transfer(redeem) Ether from this contract to msg.sender
        payable (msg.sender).transfer(etherAmount);
        emit TokensSold(msg.sender, address(token), _amount, rate);
    }
}