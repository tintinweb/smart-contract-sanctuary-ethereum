// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Token.sol";

contract EthSwap {
    string public name ="Swap Instant Exchanges";
    Token public token;
    uint public rate=100;

    constructor(Token _token)  {
        token=_token;
    }

    function buyTokens() public payable {
        uint tokenAmount = msg.value * rate;

        // Require that EthSwap has enough tokens
        require(token.balanceOf(address(this))>= tokenAmount);

        token.transfer(msg.sender, tokenAmount);
    }

    function sellTokens(uint _amount) public {

        // User can't sell tokens more than what they have
        require(token.balanceOf(msg.sender)>= _amount);

        // Calculate the amount of Ether to redeem
        uint ethAmount = _amount / rate;

        // Require that EthSwap has enough Ether
        require(address(this).balance>=ethAmount);

        // Transfer the Token from the seller address to the swap address
        token.transferFrom(msg.sender,address(this), _amount);

        // Transfer ethereum token to the seller address
        payable(msg.sender).transfer(ethAmount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Token {
    string  public name = "Tuwaiq TOKEN";
    string  public symbol = "TUWAIQ";
    uint256 public totalSupply = 1000000;
    uint8   public decimals = 18;

    mapping(address => uint256) public balanceOf;
    
    constructor() {
        balanceOf[msg.sender] = totalSupply;
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= balanceOf[_from]);
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        return true;
    }
}