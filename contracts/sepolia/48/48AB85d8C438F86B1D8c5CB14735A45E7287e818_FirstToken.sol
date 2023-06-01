/**
 *Submitted for verification at Etherscan.io on 2023-06-01
*/

//SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

contract Ownable {
    address private _owner;
    event OwnerTransfer(address indexed previousOwner, address indexed newOwner);

    constructor(){
        _owner = msg.sender;
        emit OwnerTransfer(address(0), _owner);
    }

    function owner () public view returns (address){
        return _owner;
    }

    modifier onlyOwner () {
        require (_owner == msg.sender, "You are not the owner");
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner{
        require(newOwner != address(0),"Owner address cannot be zero!");
        emit OwnerTransfer(_owner, newOwner);
        _owner = newOwner;
    }
}


interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address sender) external view returns (uint256);
    function approve(address sender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns(bool);

    event Transfer (address indexed from, address indexed to, uint256 value);
    event Approval (address indexed owner, address indexed spender, uint256 value);
}





contract FirstToken is IERC20, Ownable{
    string public name;
    string public symbol;
    uint public totalTokenSupply;
    bytes32 private _password;

    mapping(address => uint) public balances;
    mapping (address => mapping(address => uint)) private _allownces;

    event AllowanceIncrease(address, address, uint);
    event AllowanceDecrease(address, address, uint);
    event TransferFrom(address spender,address from, address to, uint amount);


    constructor(
        string memory name_,
        string memory sym,
        uint totalTokenSupply_,
        bytes32 password
    ) {
        name = name_;
        symbol = sym;
        totalTokenSupply=totalTokenSupply_;
        balances[msg.sender] = totalTokenSupply_;
        _password = password;

        emit Transfer(address(0), msg.sender, totalTokenSupply_);
    }

    function totalSupply() public view override returns (uint256){
        return totalTokenSupply;
    }

    function balanceOf(address account) public view override returns(uint256){
        return balances[account];
    }

  function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "Cannot transfer from a zero address");
        require(recipient != address(0), "Cannot transfer to a zero address");
        require(balances[sender] >= amount, "Insufficient balance");
       
        balances[sender] -= amount;
        balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);

    }

    function transferFrom(address from, address to, uint amount) external override returns (bool){
        require (_allownces[from][msg.sender] >= amount,"Insufficient allowance");
        _transfer(from,to,amount);
        emit TransferFrom(msg.sender,from, to, amount);
        return true;

    }

  function getTokens(string memory password) public {
      require(bytes32(bytes(password)) == _password, "Invalid password");
        _transfer(owner(), msg.sender, 5);
    }

    function allowance(address owner, address spender) public view override returns (uint){
        return _allownces[owner][spender];
    }

    function increaseAllowance(address spender, uint amount) public {
        require (spender != address(0),"Address cannot be zero!");
        _allownces[msg.sender][spender] += amount;
        emit AllowanceIncrease(msg.sender,spender, amount);
    }

     function decreaseAllowance(address spender, uint amount) public {
        require (spender != address(0),"Address cannot be zero!");
        _allownces[msg.sender][spender] -= amount;
        emit AllowanceDecrease(msg.sender,spender, amount);
    }

    function burnToken(uint amount) public{
        require (amount <=balances[owner()],"Insufficient Balance!");
        balances[owner()] -= amount;
        totalTokenSupply -= amount; 
        emit Transfer(msg.sender,address(0),amount);
    }

    function approve(address spender, uint amount) public override returns(bool){
        _approve(msg.sender, spender, amount);
        return true;

    }

    function _approve (address owner, address spender, uint amount)internal {
        require (owner != address(0),"Approve from the zero address");
        require (spender != address(0),"Approve to the zero address");
        _allownces[owner][spender] = amount;
        emit Approval(owner,spender,amount);
    }

    function selfdestructContract() public onlyOwner {
        selfdestruct(payable(owner()));
    }

     fallback() external payable {    
    }

    receive() external payable {
    }

}