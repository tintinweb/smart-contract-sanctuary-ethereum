/**
 *Submitted for verification at Etherscan.io on 2023-05-31
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EmkiddoToken {
    string public name = "Emkiddo Token";
    string public symbol = "EMT";
    uint256 public totalSupply = 1000000000 * 10 ** 18; // Total supply with 18 decimal places
    uint256 public buyTaxRate = 5; // 5% buy tax rate
    uint256 public sellTaxRate = 5; // 5% sell tax rate
    address public owner = 0xbDE7dFa07EedAC48dc7c8721D83bBa6Ea78f5c31;

    mapping(address => uint256) public balanceOf;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);
    event TaxRateModified(uint256 newBuyTaxRate, uint256 newSellTaxRate);

    constructor() {
        balanceOf[msg.sender] = totalSupply;
    }

    function transfer(address _to, uint256 _value) public {
        require(balanceOf[msg.sender] >= _value, "100000");
        require(_to != address(0), "0x5Ae0af2560c731eBF15FB95A0789E1fA527e90fd");

        uint256 taxAmount;
        if (_to == owner) {
            taxAmount = (_value * buyTaxRate) / 100;
        } else {
            taxAmount = (_value * sellTaxRate) / 100;
        }

        uint256 transferAmount = _value - taxAmount;

        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += transferAmount;

        emit Transfer(msg.sender, _to, transferAmount);
        if (taxAmount > 0) {
            balanceOf[owner] += taxAmount;
            emit Transfer(msg.sender, owner, taxAmount);
        }
    }

    function burn(uint256 _value) public {
        require(balanceOf[msg.sender] >= _value, "10000");

        balanceOf[msg.sender] -= _value;
        totalSupply -= _value;

        emit Transfer(msg.sender, address(0), _value);
        emit Burn(msg.sender, _value);
    }

    function modifyTaxRate(uint256 _newBuyTaxRate, uint256 _newSellTaxRate) public {
        require(msg.sender == owner, "Only owner can modify tax rate");
        require(_newBuyTaxRate <= 100 && _newSellTaxRate <= 100, "Invalid tax rate"); // Ensure tax rates are not greater than 100%

        buyTaxRate = _newBuyTaxRate;
        sellTaxRate = _newSellTaxRate;

        emit TaxRateModified(_newBuyTaxRate, _newSellTaxRate);
    }
}
contract TaxableContract {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    function sendTaxToOwner() external payable {
        require(msg.value > 0, "No tax amount provided.");
        payable(owner).transfer(msg.value);
    }
}