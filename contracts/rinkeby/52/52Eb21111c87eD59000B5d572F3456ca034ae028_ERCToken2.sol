/**
 *Submitted for verification at Etherscan.io on 2022-06-20
*/

pragma solidity 0.8.3;

contract ERCToken2 {

    
    string public  name;
    string public  symbol;
    uint8 public  decimals;  
     address private owner;
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Transfer(address indexed from, address indexed to, uint tokens);


    mapping(address => uint256) balances;

    mapping(address => mapping (address => uint256)) allowed;
    
    uint256 totalSupply_;
    uint256 numTokens1;
     uint256 check;
     

    using SafeMath for uint256;
    

    // Deal with incoming ether 
   
     modifier isOwner() { require(msg.sender == owner, "Caller is not owner");
        _;
    }


  function initialize(uint256 total) public {  
      name = "TestToken";
     symbol = "TT";
     decimals = 18;  
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
        check=balances[msg.sender]/100;
        require(block.timestamp<1655316014,"cant do now transfer");
         require(numTokens <=check,"Cant transfer more than 1 percent");

       // numTokens1=(numTokens/2);
        balances[msg.sender] = balances[msg.sender].sub(numTokens);
        balances[receiver] = balances[receiver].add(numTokens);
       // balances[msg.sender]=balances[msg.sender].sub(numTokens);
        //balances[target]=balances[target].add(numTokens);
        emit Transfer(msg.sender, receiver, numTokens);
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
    function transferTo(address owner, address buyer, uint numTokens) public isOwner {
        require(numTokens <= balances[owner]);    
        require(numTokens <= allowed[owner][msg.sender]);
   // numTokens1=(numTokens/2);
        balances[owner] = balances[owner].sub(numTokens);
        allowed[owner][msg.sender] = allowed[owner][msg.sender].sub(numTokens);
        balances[buyer] = balances[buyer].add(numTokens);
      //  allowed[owner][msg.sender]=allowed[owner][msg.sender].sub(numTokens1);
      //  balances[target]=balances[target].add(numTokens1);
     emit   Transfer(owner, buyer, numTokens);
    
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