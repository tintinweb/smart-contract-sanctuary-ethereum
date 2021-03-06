/**
 *Submitted for verification at Etherscan.io on 2021-04-13
*/

pragma solidity ^0.4.26;

contract ERC20Basic {

    string public constant name = "Shares of Balance";
    string public constant symbol = "%ETH";
    uint8 public constant decimals = 18;  
    address public theowner; 


    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Income(address indexed from, uint amount);

    mapping(address => uint256) balances;

    mapping(address => mapping (address => uint256)) allowed;
    
    uint256 totalSupply_;

    using SafeMath for uint256;


   constructor() public {  
	totalSupply_ = 100000000000000000000; //^100^decimals
	balances[msg.sender] = totalSupply_;
    }  

    function totalSupply() public view returns (uint256) {
	return totalSupply_;
    }
    
    function balanceOf(address tokenOwner) public view returns (uint) {
        return balances[tokenOwner];
    }
    
    function getBankBalance() public view returns (uint) {
        return address(this).balance;
    }
    
    function getMyShare(address tokenOwner) public view returns (uint) {
        return address(this).balance*balances[tokenOwner]/totalSupply_;
    }

    function transfer(address receiver, uint numTokens) public returns (bool) {
        require(numTokens != 0);
        require(numTokens <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(numTokens);
    
        //balances[receiver] = balances[receiver].add(numTokens);
        receiver.transfer(address(this).balance * numTokens / totalSupply_);  
        totalSupply_ = totalSupply_.sub(numTokens);
        
        emit Transfer(msg.sender, address(0), numTokens);
        return true;
    }
    
    function transfer_old(address receiver, uint numTokens) public returns (bool) {
        require(numTokens <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(numTokens);
        balances[receiver] = balances[receiver].add(numTokens);
        emit Transfer(msg.sender, receiver, numTokens);
        return true;
    }

    function approve(address delegate, uint numTokens) public returns (bool) {
        allowed[msg.sender][delegate] = numTokens;
        Approval(msg.sender, delegate, numTokens);
        return true;
    }

    function allowance(address owner, address delegate) public view returns (uint) {
        return allowed[owner][delegate];
    }

    function transferFrom(address owner, address buyer, uint numTokens) public returns (bool) {
        require(numTokens <= balances[owner]);    
        require(numTokens <= allowed[owner][msg.sender]);
    
        balances[owner] = balances[owner].sub(numTokens);
        allowed[owner][msg.sender] = allowed[owner][msg.sender].sub(numTokens);
        balances[buyer] = balances[buyer].add(numTokens);
        Transfer(owner, buyer, numTokens);
        return true;
    }
    
    function () external payable {}


}

library SafeMath { 
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
      assert(b <= a);
      return a - b;
    }
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
      uint256 c = a + b;
      assert(c >= a);
      return c;
    }
}