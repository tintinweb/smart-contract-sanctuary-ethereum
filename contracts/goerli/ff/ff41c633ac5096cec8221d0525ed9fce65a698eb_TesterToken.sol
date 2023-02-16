/**
 *Submitted for verification at Etherscan.io on 2023-02-16
*/

/**
 *Submitted for verification at Etherscan.io on 2023-02-12
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract TesterToken {
    string public name = "Tester Token";
    string public symbol = "TESTER";
    uint8 public decimals = 18;
    uint256 public totalSupply = 21000000 * 10**uint256(decimals);

    mapping(address => uint256) public balanceOf;
    address public owner;
    address public taxWallet;
    address public developerWallet;
    address public marketingWallet;
    uint256 public transactionLimit;

        constructor() {
        owner = msg.sender;
        balanceOf[owner] = totalSupply;
    }

    function setTaxWallet(address _taxWallet) public {
        require(msg.sender == owner, "Only the owner can set the tax wallet");
        taxWallet = _taxWallet;
    }

    function setDeveloperWallet(address _developerWallet) public {
        require(msg.sender == owner, "Only the owner can set the developer wallet");
        developerWallet = _developerWallet;
    }

    function setMarketingWallet(address _marketingWallet) public {
        require(msg.sender == owner, "Only the owner can set the marketing wallet");
        marketingWallet = _marketingWallet;
    }

    function setTransactionLimit(uint256 _transactionLimit) public {
        require(msg.sender == owner, "Only the owner can set the transaction limit");
        transactionLimit = _transactionLimit;
    }

    function burn(uint256 _value) public {
        require(msg.sender == owner, "Only the owner can burn tokens");
        require(_value <= balanceOf[owner], "Not enough tokens");
        balanceOf[owner] -= _value;
        totalSupply -= _value;
        emit Burn(_value);
    }

    function transfer(address _to, uint256 _value) public {
        require(_value <= balanceOf[msg.sender], "Not enough tokens");
        require(_value <= transactionLimit, "Transaction limit exceeded");
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
    }

    event Burn(uint256 value);
    event Transfer(address from, address to, uint256 value);
}