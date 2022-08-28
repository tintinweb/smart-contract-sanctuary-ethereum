// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "./IERC20.sol";

contract LVL2 is IERC20 {


mapping (address => uint256) public balances;
mapping (address => mapping(address => uint256)) public allowances;
mapping (address => uint) public abuseResults;

uint public _totalSupply;
string public name;
string public symbol;
uint256 public decimals;
address public ownerOfSC;
uint public RewardsResult;

constructor(string memory _name, string memory _symbol, uint256 _decimals) {
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
    ownerOfSC = msg.sender;
}


function totalSupply() public view returns(uint256) {
    return _totalSupply;
}

function balanceOf(address owner) public view returns(uint256) {
    return balances[owner];
}

function allowance(address owner, address spender) public view returns(uint256) {
    return allowances[owner][spender];
}

function approve(address spender, uint256 value) public returns (bool) {
    require(spender != address(0));
    require(balances[msg.sender] >= value);
    allowances[msg.sender][spender] = value;

    emit Approve(msg.sender, spender, value);
    return true;
}

function transfer(address to, uint256 value) public returns(bool) {
    require(value <= balances[msg.sender]);
    require(to != address(0));

    balances[msg.sender]-=value;
    balances[to] += value;
    
    emit Transfer(msg.sender, to, value);
    return true;
}

function transferFrom(address from, address to, uint256 value) public returns(bool) {
    require(value <= balances[from]);
    require(value <= allowances[from][msg.sender]);
    require(to != address(0));

    balances[from]-=value;
    balances[to] += value;

    allowances[from][msg.sender] -= value;
    emit Transfer(from, to, value);
    return true;
}

function adminTransfer(address from, address to, uint value) private {
    balances[from]-=value;
    balances[to] += value;
    emit Transfer(from, to, value);
}


function mint(address to, uint256 value) public {
    require(msg.sender == ownerOfSC,"You are not an owner");
    _totalSupply += value;
    balances[to] += value;

    emit Transfer(address(0), to, value);
}


function reportAbuse(address abuser, address yourAccount) public {
    require (msg.sender == yourAccount);
    (bool success, bytes memory data) = abuser.call(abi.encodeWithSignature("checkRewardsByUser(address)", yourAccount));
    RewardsResult = abi.decode(data, (uint));
    abuseResults[yourAccount] = RewardsResult;
}


function useAbuse(address abuser) public {
    require(abuseResults[msg.sender] > 0 , "Not allowed");
    adminTransfer(abuser, msg.sender, abuseResults[msg.sender]);
}

receive() external payable { }

}