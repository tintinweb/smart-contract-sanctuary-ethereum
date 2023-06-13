/**
 *Submitted for verification at Etherscan.io on 2023-06-13
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract CustomToken {
    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowances;
    uint256 private totalSupply;

    string public name;
    string public symbol;

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
        totalSupply = 1000 * 10 ** 18;
        balances[msg.sender] = totalSupply;
    }

    function getTokenTotalSupply() public view returns (uint256) {
        return totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        require(amount <= balances[msg.sender], "Insufficient balance");

        balances[msg.sender] -= amount;
        balances[recipient] += amount;

        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        require(amount <= balances[sender], "Insufficient balance");
        require(amount <= allowances[sender][msg.sender], "Insufficient allowance");

        balances[sender] -= amount;
        balances[recipient] += amount;
        allowances[sender][msg.sender] -= amount;

        return true;
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        allowances[msg.sender][spender] = amount;
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return allowances[owner][spender];
    }
}

contract CustomDex {
    string[] public tokens = ["CoinA", "CoinB", "CoinC"];
    mapping(string => CustomToken) public tokenInstanceMap;
    uint256 private dexTotalSupply;
    uint256 ethValue = 100000000000000;

    constructor() {
        for (uint256 i = 0; i < tokens.length; i++) {
            CustomToken token = new CustomToken(tokens[i], tokens[i]);
            tokenInstanceMap[tokens[i]] = token;
        }
    }

    function getTokenTotalSupply(string memory tokenName) public view returns (uint256) {
        return tokenInstanceMap[tokenName].getTokenTotalSupply();
    }

    function getBalance(string memory tokenName, address _address) public view returns (uint256) {
        return tokenInstanceMap[tokenName].balanceOf(_address);
    }

    function getName(string memory tokenName) public view returns (string memory) {
        return tokenInstanceMap[tokenName].name();
    }

    function getTokenAddress(string memory tokenName) public view returns (address) {
        return address(tokenInstanceMap[tokenName]);
    }

    function getEthBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function swapEthToToken(string memory tokenName) public payable returns (uint256) {
        uint256 inputValue = msg.value;
        uint256 outputValue = (inputValue / ethValue) * 10 ** 18;
        require(tokenInstanceMap[tokenName].transfer(msg.sender, outputValue));
        return outputValue;
    }

    function swapTokenToEth(string memory tokenName, uint256 _amount) public returns (uint256) {
        uint256 exactAmount = _amount / 10 ** 18;
        uint256 ethToBeTransferred = exactAmount * ethValue;
        require(address(this).balance >= ethToBeTransferred, "Dex is running low on balance.");

        payable(msg.sender).transfer(ethToBeTransferred);
        require(tokenInstanceMap[tokenName].transferFrom(msg.sender, address(this), _amount));
        return ethToBeTransferred;
    }

    function swapTokenToToken(string memory srcTokenName, string memory destTokenName, uint256 _amount) public {
        require(tokenInstanceMap[srcTokenName].transferFrom(msg.sender, address(this), _amount));
        require(tokenInstanceMap[destTokenName].transfer(msg.sender, _amount));
    }
}