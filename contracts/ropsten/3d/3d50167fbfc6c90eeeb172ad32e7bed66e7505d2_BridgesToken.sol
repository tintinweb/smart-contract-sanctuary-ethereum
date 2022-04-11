/**
 *Submitted for verification at Etherscan.io on 2022-04-10
*/

pragma solidity ^0.4.0;

interface ERC20 {
    function totalSupply() external constant returns (uint _totalSupply);
    function balanceOf(address _owner) external constant returns (uint balance);
    function transfer(address _to, uint _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint _value) external returns (bool success);
    function approve(address _spender, uint _value) external returns (bool success);
    function allowance(address _owner, address _spender) external constant returns (uint remaining);
    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}

contract BridgesToken is ERC20 {

    string public constant _tokenName = "Bridges Token";
    string public constant _tokenSymbol = "AIP";
    uint8 public constant _tokenDecimal = 18;

    uint256 private constant _totalTokenSupply = 1337000000000000000000;

    mapping (address => uint256) public _balanceOf;
    mapping (address => mapping (address => uint256)) public _allowances;


    constructor() public {
        _balanceOf[msg.sender] = _totalTokenSupply;
    }


    function name() public constant returns (string tokenName) {
        tokenName = _tokenName;
    }

    function symbol() public constant returns (string tokenSymbol) {
        tokenSymbol = _tokenSymbol;
    }

    function decimals() public view returns (uint8 tokenDecimal) {
        tokenDecimal = _tokenDecimal;
    }

    function totalSupply() public view returns (uint256 totalTokenSupply) {
        totalTokenSupply = _totalTokenSupply;
    }

    function balanceOf(address addr) public constant returns (uint256 balance) {
        return _balanceOf[addr];
    }

    function transfer(address toAddr, uint256 value) public returns (bool success) {
        if (value > 0 && value <= balanceOf(msg.sender)) {
                _balanceOf[msg.sender] -= value;
                _balanceOf[toAddr] += value;
                return true;
        }
        return false;
    }

    function transferFrom(address fromAddr, address toAddr, uint256 value) public returns (bool success) {
        if (_allowances[fromAddr][msg.sender] > 0 &&
            value > 0 &&
            value <= _allowances[fromAddr][msg.sender] &&
            value <= _balanceOf[fromAddr]) {
                _balanceOf[fromAddr] -= value;
                _balanceOf[toAddr] += value;
                _allowances[fromAddr][msg.sender] -= value;
                return true;
        }
        return false;
    }

    function approve(address spender, uint256 value) public returns (bool success) {
        _allowances[msg.sender][spender] = value;
        return true;
    }

    function allowance(address owner, address spender) public constant returns (uint256 remaining) {
        return _allowances[owner][spender];
    }
}