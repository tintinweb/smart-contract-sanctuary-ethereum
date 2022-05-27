/**
 *Submitted for verification at Etherscan.io on 2022-05-27
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

contract Token {

    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;

    uint public totalSupply = 1000 * 10 ** 18;
    string public name;
    string public symbol;
    uint public decimals;

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);

    address admin;

    address charityWallet; //I put my wallets here but I deleted them for now
    address burnWallet;

    uint charityFee = 0;
    uint burnFee = 0;
    uint taxFee = 500;
    uint totalFee = 500;
    bool charityFlag;
    
    uint taxedCoins;

    function initializer(
        address wallet, 
        address wallet2,
        string calldata _wrappedTokenName,
        string calldata _wrappedTokenTicker,
        uint8 _wrappedTokenDecimals
    ) public {
        name = _wrappedTokenName;
        symbol = _wrappedTokenTicker;
        decimals = _wrappedTokenDecimals;
        balances[msg.sender] = totalSupply;
        admin = msg.sender;
        charityWallet = wallet;
        burnWallet = wallet2;
        charityFlag = false;
    }
    constructor(address wallet, address wallet2) {
        
    }

    function balanceOf(address owner) public view returns(uint) {
        uint actualBalance = balances[owner] + ((balances[owner] * taxedCoins) / totalSupply);
        return actualBalance;
    }
    
    function transfer(address to, uint value) public returns(bool) {
        require(balanceOf(msg.sender) >= value, "Balance is too low");
        uint _charityFee = 0;
        uint _burnFee = 0;
        uint _taxFee = 0;
        uint _totalFee = 0;
        if(charityFlag) {
            _charityFee = charityFee;
            _burnFee = burnFee;
            _taxFee = taxFee;
            _totalFee = totalFee;
        }
        balances[charityWallet] += (_charityFee * value) / 10000;
        balances[burnWallet] += (_burnFee * value) / 10000;

        taxedCoins += (_taxFee * value) / 10000;

        balances[to] += (value * (10000 - _totalFee)) / 10000;
        if (value <= balances[msg.sender]) {
            balances[msg.sender] -= value;
        } else {
            uint leftoverCoins = value - balances[msg.sender];
            balances[msg.sender] = 0;
            taxedCoins -= leftoverCoins;
        }
        
        emit Transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint value) public returns(bool) {
        require(balanceOf(from) >= value, "Balance is too low");
        require(allowance[from][msg.sender] >= value, "Allowance is too low");
        uint _charityFee = 0;
        uint _burnFee = 0;
        uint _taxFee = 0;
        uint _totalFee = 0;
        if(charityFlag) {
            _charityFee = charityFee;
            _burnFee = burnFee;
            _taxFee = taxFee;
            _totalFee = totalFee;
        }
        balances[charityWallet] += (_charityFee * value) / 10000;
        balances[burnWallet] += (_burnFee * value) / 10000;

        taxedCoins += (_taxFee * value) / 10000;

        balances[to] += (value * (10000 - _totalFee)) / 10000;
        if (value <= balances[from]) {
            balances[from] -= value;
        } else {
            uint leftoverCoins = value - balances[from];
            balances[from] = 0;
            taxedCoins -= leftoverCoins;
        }
        
        emit Transfer(from, to, value);
        return true;
    }

    function approve(address spender, uint value) public returns(bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function getNumberOfTaxedCoins() public view returns(uint) {
        return taxedCoins;
    }

    function getTaxFee() public view returns(uint) {
        return taxFee;
    }

    function changeCharityWallet(address _charityWallet, address _burnWallet) public {
        require(msg.sender == admin, "Only admin is allowed to change the Wallets");
        charityWallet = _charityWallet;
        burnWallet = _burnWallet;
    }

    function setFlag(bool flag) public {
        require(msg.sender == admin, "Only admin is allowed to change the Wallets");
        charityFlag = flag;
    }

    function burn(uint256 amount) public {
        // require(msg.sender == admin, "Only admin is allowed to change the Wallets");
        require(msg.sender != address(0), "ERC20: burn from the zero address");
        require(balances[msg.sender] >= amount, "ERC20: burn amount exceeds balance");
        balances[msg.sender] -= amount;
        balances[address(0)] += amount;
        totalSupply -= amount; 
    }
}