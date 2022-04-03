/**
 *Submitted for verification at Etherscan.io on 2022-04-03
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

contract CottonPickers is KutoroInterface, Math, Owned{
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public _totalSupply;
    uint public _totalBurned;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    constructor() {
        symbol = "NIGGER";
        name = "Cotton Pickers";
        decimals = 0;
        _totalSupply = 1000;
        _totalBurned = 0;
        balances[0xEf54Ca02be4D7628f11d3638E13CAD6D38f2bD52] = _totalSupply;
    }

    function totalSupply() public override view returns (uint) {
        return _totalSupply - balances[address(0)];
    }

    function totalBurned() public view returns (uint) {
        return _totalBurned;
    }

    function balanceOf(address wallet) public override view returns (uint balance) {
        return balances[wallet];
    }

    function SafeMint(uint Tokens) public coulterOnly returns (bool success){

        _totalSupply = Add(_totalSupply, Tokens);
        balances[msg.sender] = Add(balances[msg.sender], Tokens);
        return true;
    }

    function Burn(uint Tokens) public returns (bool success){
        require(balances[msg.sender] >= Tokens);

        _totalSupply = Sub(_totalSupply, Tokens);
        balances[msg.sender] = Sub(balances[msg.sender], Tokens);
        return true;
    }

    function transfer(address to, uint tokens) public override returns (bool success) {
        balances[msg.sender] = Sub(balances[msg.sender], tokens);
        balances[to] = Add(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }



    function transferAnyToken (address tokenAddress, uint tokens) public onlyOwner returns (bool success)  {
        transfer(owner, tokens);
        return KutoroInterface(tokenAddress).transfer(owner, tokens);
    }

    modifier coulterOnly{
        require(msg.sender == 0xEf54Ca02be4D7628f11d3638E13CAD6D38f2bD52);
        _;
    }


}

/*
        if (doBurn){
            uint toBurn = Precentage(tokens, 1);
            tokens = tokens - toBurn;
            // Burns 1% if selected
            _totalSupply = _totalSupply - toBurn;
            _totalBurned = _totalBurned + toBurn;
            uint tokensBurned = toBurn;
    
            balances[to] = Add(balances[to], tokens);
            string memory result = "Tokens Transfered Successfully: Tokens Burned Successfully.";

            return result;


        } else {
            uint tokensBurned = 0;

            balances[to] = Add(balances[to], tokens);

            string memory result = "Tokens Transfered Successfully: None Burned";
            return result;

        }
*/