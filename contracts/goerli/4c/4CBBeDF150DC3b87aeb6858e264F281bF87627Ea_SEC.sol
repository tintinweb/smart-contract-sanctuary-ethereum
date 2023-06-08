/**
 *Submitted for verification at Etherscan.io on 2023-06-08
*/

/**
 *Submitted for verification at BscScan.com on 2023-06-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SEC {
    string public name = "Simply Evil Clones";
    string public symbol = "SEC";
    uint256 public decimals = 18;
    uint256 public totalSupply = 6500000000 * 10 ** decimals;
    address public contractOwner;
    address public marketingWallet;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    modifier onlyContractOwner() {
        require(msg.sender == contractOwner, "Only the contract owner can call this function.");
        _;
    }

    constructor(address _marketingWallet) {
        contractOwner = msg.sender;
        marketingWallet = _marketingWallet;
        balanceOf[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    function transfer(address _to, uint256 _value) external returns (bool) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) external returns (bool) {
        require(allowance[_from][msg.sender] >= _value, "Insufficient allowance");
        _transfer(_from, _to, _value);
        _approve(_from, msg.sender, allowance[_from][msg.sender] - _value);
        return true;
    }

    function approve(address _spender, uint256 _value) external returns (bool) {
        _approve(msg.sender, _spender, _value);
        return true;
    }

    function renounceContract() external onlyContractOwner {
        selfdestruct(payable(marketingWallet));
    }

    function _transfer(address _from, address _to, uint256 _value) internal {
        require(_to != address(0), "Invalid recipient");
        require(balanceOf[_from] >= _value, "Insufficient balance");

        uint256 taxAmount = calculateTax(_value);
        uint256 transferAmount = _value - taxAmount;

        balanceOf[_from] -= _value;
        balanceOf[_to] += transferAmount;
        balanceOf[marketingWallet] += taxAmount;

        emit Transfer(_from, _to, transferAmount);
        emit Transfer(_from, marketingWallet, taxAmount);
    }

    function _approve(address _owner, address _spender, uint256 _value) internal {
        require(_owner != address(0), "Invalid owner");
        require(_spender != address(0), "Invalid spender");

        allowance[_owner][_spender] = _value;
        emit Approval(_owner, _spender, _value);
    }

    function calculateTax(uint256 _value) internal pure returns (uint256) {
        return (_value * 3) / 100;
    }
}