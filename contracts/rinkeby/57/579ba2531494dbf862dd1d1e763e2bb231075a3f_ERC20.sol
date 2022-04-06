/**
 *Submitted for verification at Etherscan.io on 2022-04-06
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8;

contract ERC20{

    string public name_;
    string public symbol_;
    uint256 public decimals_ = 18;
    uint256 public totalSupply_;
    address public owner;

    mapping (address => uint256) public balances;
    mapping (address => mapping(address => uint256)) public allowance_;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    constructor(string memory _name, string memory _symbol, uint256 _amount){
        name_ = _name;
        symbol_ = _symbol;
        totalSupply_ = _amount * 10 ** decimals_;
        owner = msg.sender;
        balances[msg.sender] = totalSupply_;
    }

    function balanceOf(address _of) public view returns(uint256){
        require(_of != address(0), "INVALID ADDRESS");
        return balances[_of];
    }

    function name() public view returns(string memory){
        return name_;
    }

    function symbol() public view returns(string memory){
        return symbol_;
    }

    function decimal() public view returns(uint256){
        return decimals_;
    }

    function totalSupply() public view returns(uint256){
        return totalSupply_;
    }

    function transfer(address _to, uint256 _value) public returns (bool success){
        require(_to != address(0), "INVALID ADDRESS");
        require(balances[msg.sender] >= _value,"INSUFFICIENT BALANCE");
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success){
        require(_from != address(0), "INVALID ADDRESS OF FROM");
        require(_to != address(0), "INVALID ADDRESS OF TO");
        require(balances[_from] >= _value,"INSUFFICIENT BALANCE");
        require(_value <= allowance_[_from][msg.sender],"INSUFFICIENT ALLOWANCE");
        balances[_from] -= _value;
        balances[_to] += _value;
        allowance_[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success){
        require(_spender != address(0), "INVALID ADDRESS");
        require(balances[msg.sender] >= _value,"INSUFFICIENT BALANCE");
        allowance_[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;

    }

    function allowance(address _owner, address _spender) public view returns (uint256){
        require(_owner != address(0), "INVALID ADDRESS OF OWNER");
        require(_spender != address(0), "INVALID ADDRESS OF SPENDER");
        return allowance_[_owner][_spender];
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "NOT THE OWNER");
        _;
    }

    function mint(address _to, uint256 _value) public onlyOwner {
        totalSupply_ += _value;
        balances[_to] += _value;
    }

    function burn(address _from, uint256 _value) public {
        require(_from == msg.sender || _from == owner, "NOT ELIGIBLE TO BURN TOKEN");
        require(balances[_from] >= _value, "INSUFFICIENT BALANCE");
        balances[_from] -= _value;
        totalSupply_ -= _value;
    }

    function increaseAllowance(address _spender, uint256 _value) public {
        require(_spender != address(0), "INVALID ADDRESS");
        require(balances[msg.sender] >= _value,"INSUFFICIENT BALANCE");
        allowance_[msg.sender][_spender] += _value;
    }

    function decreaseAllowance(address _spender, uint256 _value) public {
        require(_spender != address(0), "INVALID ADDRESS");
        require(allowance_[msg.sender][_spender] >= _value,"INSUFFICIENT ALLOWANCE");
        allowance_[msg.sender][_spender] -= _value;
    }

}