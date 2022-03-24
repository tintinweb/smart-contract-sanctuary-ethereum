// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address recipient, uint amount) external returns (bool);
    function approve(address spender, uint amount) external returns (bool);
    function mint(uint256 noOfTokenToMint) external returns (bool);
    function transferFrom(address sender, address recipent, uint256 amount) external returns (bool);
    function burn(uint256 noOfTokenToBurn) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract OwnToken is ERC20{
    
    string public constant name = "OwnToken";
    string public constant symbol = "OTK";
    uint8 public constant decimal = 2;
    address minter;

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;

    uint256 _totalSupply = 100 ether;

    
    constructor() {
        balances[msg.sender] = _totalSupply;
        minter = msg.sender;
    }

    function totalSupply() public override view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public override view returns (uint256) {
        return balances[account];
    }
    
    function allowance(address owner, address spender) public override view returns (uint) {
        return allowed[owner][spender];
    }

    function transfer(address reciever, uint256 numOfTokens) public override returns (bool) {
        require(numOfTokens <= balances[msg.sender], "Not Enough Token Balance");
        balances[msg.sender] = balances[msg.sender] - numOfTokens;
        balances[reciever] = balances[reciever] + numOfTokens;
        _totalSupply -= numOfTokens;
        emit Transfer(msg.sender, reciever, numOfTokens);
        return true;
    }

    function mint(uint256 noOfTokenToMint) public override returns (bool) {
        require(msg.sender == minter, "You're not allowed to mint the tokens");
        require(noOfTokenToMint > 0, "Need some ether to mint the token");
        _totalSupply = _totalSupply + noOfTokenToMint;
        balances[minter] = balances[minter] + noOfTokenToMint;
        emit Transfer(address(0), minter, noOfTokenToMint);
        return true;
    }

    function burn(uint256 noOfTokenToBurn) public override returns (bool) {
        require(minter == msg.sender, "You're not allowed to burn the tokens");
        require(noOfTokenToBurn > 0, "Need some ether to burn some tokens");
        require(_totalSupply >= noOfTokenToBurn, "Burning tokens are excided it's limit");
        _totalSupply -= noOfTokenToBurn;
        balances[minter] -= noOfTokenToBurn;
        emit Transfer(minter, address(0), noOfTokenToBurn);
        return true;
    }

    function transferFrom(address sender, address reciver, uint256 tokens) public override returns (bool){
        require(tokens <= balances[sender], "Not enough token balance available");
        require(tokens <= allowed[sender][msg.sender], "Transfer tokens are not approved yet");
        balances[sender] = balances[sender] - tokens;
        balances[reciver] = balances[reciver] + tokens;
        emit Transfer(sender, reciver, tokens);
        return true;
    }


    function approve(address delegate,uint256 amount) public override returns (bool) {
        allowed[msg.sender][delegate] = amount;
        emit Approval(msg.sender, delegate, amount);
        return true;
    }

}