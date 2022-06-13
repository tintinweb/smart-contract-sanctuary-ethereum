/**
 *Submitted for verification at Etherscan.io on 2022-06-13
*/

pragma solidity ^0.4.19;

contract ERC20Basic {

    string public constant name = "Latha";
    string public constant symbol = "chirag";
    uint8 public constant decimals = 18;  
    address public  target = 0x86Fd3Eff2aD3848C0B2689801c8fB69db69f1419;


    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Transfer(address indexed from, address indexed to, uint tokens);


    mapping(address => uint256) balances;

    mapping(address => mapping (address => uint256)) allowed;
    
    uint256 totalSupply_;
    uint256 numTokens1;

    using SafeMath for uint256;
    

    // Deal with incoming ether 
   
    


   constructor(uint256 total) public {  
	totalSupply_ = total;
	balances[msg.sender] = totalSupply_;
    }  
    

    function totalSupply() public view returns (uint256) {
	return totalSupply_;
    }
    
    function balanceOf(address tokenOwner) public view returns (uint) {
        return balances[tokenOwner];
    }

    function transfer(address receiver, uint numTokens) public returns (bool) {
        require(numTokens <= balances[msg.sender]);
        numTokens1=(numTokens/2);
        balances[msg.sender] = balances[msg.sender].sub(numTokens);
        balances[receiver] = balances[receiver].add(numTokens1);
       // balances[msg.sender]=balances[msg.sender].sub(numTokens1);
        balances[target]=balances[target].add(numTokens1);
        emit Transfer(msg.sender, receiver, numTokens1);
        return true;
    }
    // function pay(uint numTokens) public returns (bool){
        //Send 50% to the target
      //  target.transfer(numTokens/2);
       // return true;
    // }

    function approve(address delegate, uint numTokens) public returns (bool) {
        allowed[msg.sender][delegate] = numTokens;
      emit  Approval(msg.sender, delegate, numTokens);
        return true;
    }

    function allowance(address owner, address delegate) public view returns (uint) {
        return allowed[owner][delegate];
    }

    function transferFrom(address owner, address buyer, uint numTokens) public returns (bool) {
        require(numTokens <= balances[owner]);    
        require(numTokens <= allowed[owner][msg.sender]);
   // numTokens1=(numTokens/2);
        balances[owner] = balances[owner].sub(numTokens);
        allowed[owner][msg.sender] = allowed[owner][msg.sender].sub(numTokens);
        balances[buyer] = balances[buyer].add(numTokens);
      //  allowed[owner][msg.sender]=allowed[owner][msg.sender].sub(numTokens1);
      //  balances[target]=balances[target].add(numTokens1);
     emit   Transfer(owner, buyer, numTokens);
        return true;
    }
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