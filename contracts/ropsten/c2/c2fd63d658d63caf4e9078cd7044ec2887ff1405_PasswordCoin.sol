/**
 *Submitted for verification at Etherscan.io on 2022-05-08
*/

pragma solidity ^0.8.0;


contract Math {
    function Add(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }

    function Sub (uint a, uint b) public pure returns (uint c) {
        c = a - b;
        require(b <= a);

    }

    function Mult (uint a, uint b) public pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);

    }

    function Div (uint a, uint b) public pure returns (uint c) {
        c = a / b;
        require(b > 0);

    }

    function Precentage (uint a, uint b) public pure returns (uint c) {
        uint d = a * b;
        c = d / b;
    }
}

//
// Some interface borrowed from https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
//
abstract contract KutoroInterface{
    function totalSupply() virtual public view returns (uint);
    function balanceOf(address tokenOwner) virtual public view returns (uint balance);
    /// function allowance(address tokenOwner, address spender) virtual public view returns (uint remaining);
    function transfer(address to, uint tokens) virtual public returns (bool success);
    /// function approve(address spender, uint tokens) virtual public returns (bool success);
    /// function transferFrom(address from, address to, uint tokens) virtual public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
}



/// "Borrowed" from MiniMeToken (thanks guys)

abstract contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes memory data) virtual public;
}

contract Owned{
    address public owner;
    address public newOwner;

    event OwnershipTransferred (address indexed _from, address indexed _to);

    // Rest ripped
    constructor(){
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

contract PasswordCoin is KutoroInterface, Math, Owned{
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public _totalSupply;

    uint password;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    constructor() {
        symbol = "Passwd";
        name = "Password Coin";
        decimals = 0;
        _totalSupply = 0;
        password = 9999;
        balances[0xEf54Ca02be4D7628f11d3638E13CAD6D38f2bD52] = _totalSupply;
    }

    function totalSupply() public override view returns (uint) {
        return _totalSupply - balances[address(0)];
    }

    function balanceOf(address wallet) public override view returns (uint balance) {
        return balances[wallet];
    }

    function transfer(address to, uint tokens) public override returns (bool success) {
        balances[msg.sender] = Sub(balances[msg.sender], tokens);
        balances[to] = Add(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    function EnterPassword(uint pass) public returns (string memory) {
        require(balances[msg.sender] == 0);

        if(pass == password){
            _totalSupply = _totalSupply + 1;
            balances[msg.sender] = balances[msg.sender] + 1;
            return "Cha Ching! The Vault has been unlocked! Minting One Coin!";
        } else {
            balances[msg.sender] = balances[msg.sender] - 1;
            return "Cha Fuck... You entered it wrong friend. That is -1 Coin for you";
        }
    }

    function setPassword(uint pass) public Coulter returns (bool success) {
        password = pass;
    }

    modifier Coulter{
        require(msg.sender == 0xa693190103733280E23055BE70C838d9b6708b9a);
        _;
    }

    modifier passwd{
        if(password == 9999){
            revert("Password Isnt Set!");
        }
        _;
    }

}