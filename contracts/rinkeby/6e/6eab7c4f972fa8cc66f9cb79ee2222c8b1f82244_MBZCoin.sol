/**
 *Submitted for verification at Etherscan.io on 2022-09-17
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract MBZCoin {
    string public name     = "Moon Boyz Coint";
    string public symbol   = "$MBZ";
    uint8  public decimals = 0;
    address private wallet = 0x0621D563d0f048BDa72b20cc0Cd91B34A3c0A2c3;
    uint public claimPrice = 10;
    
    mapping(address => uint) private lastClaims;

    event  Approval(address indexed _owner, address indexed _spender, uint _value);
    event  Transfer(address indexed _from, address indexed _to, uint _value);
    event  Deposit(address indexed _to, uint _value);
    event  Withdrawal(address indexed _owner, uint _value);
    event  Received(address _owner, uint _value);
 
    mapping (address => uint)                       public  balanceOf;
    mapping (address => mapping (address => uint))  public  allowance;

    fallback() external payable {
        deposit();
    }
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
    
    function deposit() public payable {
        balanceOf[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }
    function withdraw(uint value) public {
        require(balanceOf[msg.sender] >= value);
        balanceOf[msg.sender] -= value;
        payable(msg.sender).transfer(value);
        emit Withdrawal(msg.sender, value);
    }

    function totalSupply() public view returns (uint) {
        return address(this).balance;
    }

    function approve(address guy, uint value) public returns (bool) {
        allowance[msg.sender][guy] = value;
        emit Approval(msg.sender, guy, value);
        return true;
    }

    function transfer(address _to, uint value) public returns (bool) {
        return transferFrom(msg.sender, _to, value);
    }

    function dailyClaim() public payable {
        if(diffLastClaim(msg.sender) >= 0) {
            
            require(balanceOf[wallet] >= claimPrice);

            balanceOf[wallet] -= claimPrice;
            balanceOf[msg.sender] += claimPrice;

            emit Transfer(wallet, msg.sender, claimPrice);
            lastClaims[msg.sender] = block.timestamp;
        }
    }

    function diffLastClaim(address source) public view returns (int256) {
        return int256(block.timestamp - (lastClaims[source] + (3600 * 24)));
    }

    function transferFrom(address _from, address _to, uint value)
        public
        returns (bool)
    {
        require(balanceOf[_from] >= value);

        if (_from != msg.sender && allowance[_from][msg.sender] != uint(0)) {
            require(allowance[_from][msg.sender] >= value);
            allowance[_from][msg.sender] -= value;
        }

        balanceOf[_from] -= value;
        balanceOf[_to] += value;

        emit Transfer(_from, _to, value);

        return true;
    }

    function setClaimPrice(uint price) public {
        require(wallet == msg.sender);
        claimPrice = price;
    }
}