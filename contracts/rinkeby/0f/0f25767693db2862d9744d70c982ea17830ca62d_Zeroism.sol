/**
 *Submitted for verification at Etherscan.io on 2022-03-23
*/

/**
 ________   _______ .______        ______    __       _______..___  ___. 
|       /  |   ____||   _  \      /  __  \  |  |     /       ||   \/   | 
`---/  /   |  |__   |  |_)  |    |  |  |  | |  |    |   (----`|  \  /  | 
   /  /    |   __|  |      /     |  |  |  | |  |     \   \    |  |\/|  | 
  /  /----.|  |____ |  |\  \----.|  `--'  | |  | .----)   |   |  |  |  | 
 /________||_______|| _| `._____| \______/  |__| |_______/    |__|  |__|                                                                     
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.9;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Zeroism {
    
    string public constant name = "Zeroism";
    string public constant symbol = "ZERM";
    uint8 public constant decimals = 9;
    uint256 _totalSupply;

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);

    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;

    constructor(){ 
        _totalSupply = 100000000000000 * 10 ** decimals;
        balances[msg.sender] = _totalSupply;
    }
    
    function totalSupply() public view returns (uint256) {     
        return _totalSupply;
    }
    
    function balanceOf(address tokenOwner) public view returns (uint){    
        return balances[tokenOwner];
    }
    
    function transfer(address receiver, uint numTokens) public returns(bool){
        require(numTokens <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender] - numTokens;
        balances[receiver] = balances[receiver] + numTokens;
        emit Transfer(msg.sender, receiver, numTokens);
        return true;
    }
    
    function approve(address delegate, uint numTokens) public returns (bool){
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }
    
    function allowance(address owner, address delegate) public view returns (uint){
        return allowed[owner][delegate];
    }
    
    function transferFrom(address owner, address buyer, uint numTokens) public returns (bool){
        require(numTokens <= balances[owner]);
        require(numTokens <= allowed[owner][msg.sender]);
        balances[owner] = balances[owner] - numTokens;
        allowed[owner][msg.sender] = allowed[owner][msg.sender] - numTokens;
        balances[buyer] = balances[buyer] + numTokens;
        emit Transfer(owner, buyer, numTokens);
        return true;   
    }
 }

abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}