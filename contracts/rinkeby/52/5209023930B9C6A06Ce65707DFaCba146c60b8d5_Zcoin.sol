// SPDX-License-Identifier: MIT
// compiler version must be greater than or equal to 0.8.13 and less than 0.9.0
pragma solidity ^0.8.13;

contract Zcoin {

    string private constant NAME = "SUPER ERC20 TOKEN";
    string private constant SYMBOL = "ZCOIN";
    uint8 private constant DECIMALS = 18;

    uint256 private total;
    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private approved;
    address private owner;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor() {
        owner = msg.sender;
    }

    function name() public pure returns (string memory) {
        return NAME;
    }

    function symbol() public pure returns (string memory) {
        return SYMBOL;
    }

    function decimals() public pure returns (uint8) {
        return DECIMALS;
    }

    function totalSupply() public view returns (uint256) {
        return total;
    }

    function balanceOf(address _address) public view returns (uint256 balance) {
        return balances[_address];
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balanceOf(msg.sender) >= _value, "account does not have enough tokens");

        balances[msg.sender] -= _value;
        balances[_to] += _value;

        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(balanceOf(_from) >= _value, "account does not have enough tokens");
        require(approved[_from][_to] >= _value, "transfer of this number of tokens is not allowed");

        approved[_from][_to] -= _value;
        balances[_from] -= _value;
        balances[_to] += _value;

        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        approved[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _tokenOwner, address _spender) public view returns (uint256 remaining) {
        return approved[_tokenOwner][_spender]; 
    }

    function mint(address _to, uint256 _value) public onlyOwner {
        balances[_to] += _value;
        total += _value;

        emit Transfer(address(0), _to, _value);
    }

    function burn(address _from, uint256 _value) public onlyOwner {
        require(balanceOf(_from) >= _value, "account balance does not have enough tokens to burn");
        
        balances[_from] -= _value;
        total -= _value;

        emit Transfer(_from, address(0), _value);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }
}