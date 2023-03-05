// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

//create an ERC20 token
//***** state variables ******//
//token name
//token symbol
//decimal
//Total supply
//Owner

//****functions***//
/**
mint function
balanceOf
transfer
transferFrom
Approve
Allowance
burn
 */

contract ERC20 {
    string public tokenName;
    string public tokenSymbol;
    uint256 public decimal;
    uint256 public totalSupply;
    address public owner;

    mapping(address => uint256) public balanceOf;
    mapping(address => uint256) public approve;
    mapping(address => mapping(address => bool)) public allowance;

    event _mint(address indexed, uint256);
    event _transferToken(address indexed, uint256);

    constructor(string memory _tokenName, string memory _tokenSymbol) {
        owner = msg.sender;
        tokenName = _tokenName;
        tokenSymbol = _tokenSymbol;
        decimal = 1e18;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only contract owner can mint");
        _;
    }

    function getBalance(address _addr) public view returns (uint256) {
        return balanceOf[_addr];
    }

    function getTotalSupply() public view returns (uint256) {
        return totalSupply;
    }

    function mint(address to, uint256 _amount) public onlyOwner {
        require(to != address(0), "You can't mint to Address(0)");
        totalSupply += _amount;
        balanceOf[to] += _amount;
        emit _mint(to, _amount);
    }

    function transfer(address to, uint256 amount)
        public
        returns (bool success)
    {
        require(balanceOf[msg.sender] >= amount, "Insufficient Balance");
        require(to != address(0), "Invalid Address");
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        success = true;
        emit _transferToken(to, amount);
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public returns (bool success) {
        _transfer(from, to, amount);
        success = true;
        emit _transferToken(to, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal {
        require(to != address(0), "Invalid address");
        require(balanceOf[from] >= amount, "Insufficient Balance");
        require(
            approve[msg.sender] >= amount,
            "you don't have permission for this amount"
        );

        balanceOf[from] -= amount;
        balanceOf[to] += amount;
    }

    function _approve(address spender, uint256 amount)
        public
        returns (bool success)
    {
        require(balanceOf[msg.sender] >= amount, "Insufficient Balance");
        require(spender != address(0), "Invalid address");
        require(
            allowance[msg.sender][spender] == true,
            "You don't have permission"
        );

        approve[spender] += amount;
        success = true;
    }

    function _allowance(address _owner, address _spender)
        public
        returns (bool success)
    {
        require(_spender != address(0), "Invalid Spender");
        require(_owner == msg.sender, "only Account owner is permitted");
        allowance[_owner][_spender] = true;
        success = true;
    }

    function burn(uint256 amount) private onlyOwner {
        require(balanceOf[msg.sender] >= amount, "Insufficient fund");

        balanceOf[msg.sender] -= amount;
        totalSupply -= amount;
    }
}