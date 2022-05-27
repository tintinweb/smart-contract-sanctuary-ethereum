/**
 *Submitted for verification at Etherscan.io on 2022-05-26
*/

pragma solidity ^0.8.7;
// SPDX-License-Identifier: Unlicensed

/**
 * @dev BEP20 Token interface
 */
interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @dev Collection of functions related to the address type
 * 
 * from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol
 */
library Address {
    function isContract(address account) internal view returns (bool) { 
        uint256 size; 

        assembly { size := extcodesize(account) } 

        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");

        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) { return functionCall(target, data, "Address: low-level call failed"); }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) { return functionCallWithValue(target, data, 0, errorMessage); }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) { return functionCallWithValue(target, data, value, "Address: low-level call with value failed"); }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);

        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) { return functionStaticCall(target, data, "Address: low-level static call failed"); }

    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);

        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) { return functionDelegateCall(target, data, "Address: low-level delegate call failed"); }

    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);

        return verifyCallResult(success, returndata, errorMessage);
    }

    function verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) internal pure returns (bytes memory) {
        if (success) { 
            return returndata; 
        } else { 
            if (returndata.length > 0) { 
                assembly { 
                    let returndata_size := mload(returndata) revert(add(32, returndata), returndata_size) 
                } 
            } else { 
                revert(errorMessage);
            }
        }
    }
}

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 * 
 * from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeMath.sol
 */
library SafeMath {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) { 
        unchecked { 
            uint256 c = a + b; 

            if (c < a) return (false, 0);

            return (true, c); 
        }
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) { 
        unchecked { 
            if (b > a) return (false, 0);

            return (true, a - b);
        }
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) { 
        unchecked { 
            if (a == 0) return (true, 0); 

            uint256 c = a * b;

            if (c / a != b) return (false, 0); 

            return (true, c);
        }
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) { 
        unchecked { 
            if (b == 0) return (false, 0); 

            return (true, a / b);
        }
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) { 
        unchecked { 
            if (b == 0) return (false, 0); 

            return (true, a % b); 
        }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) { return a + b; }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) { return a - b; }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) { return a * b; }

    function div(uint256 a, uint256 b) internal pure returns (uint256) { return a / b; }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) { return a % b; }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) { 
        unchecked { 
            require(b <= a, errorMessage);

            return a - b;
        }
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) { 
        unchecked { 
            require(b > 0, errorMessage); 

            return a / b; 
        }
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) { 
        unchecked { 
            require(b > 0, errorMessage); 

            return a % b;
        }
    }
}

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol
 */
abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;

    constructor() { _status = _NOT_ENTERED; }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        _status = _ENTERED;
        _;
		_status = _NOT_ENTERED;
    }
}

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) { return payable(msg.sender); }

    function _msgData() internal view virtual returns (bytes memory) { 
        this;  
        return msg.data;
    }
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 */
contract Ownable is Context {
    address private _owner;

    constructor() {
        _owner = _msgSender();

        emit OwnershipTransferred(address(0), _owner);
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

	function owner() public view returns (address) { return _owner; }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");

        emit OwnershipTransferred(_owner, newOwner);

        _owner = newOwner;
    }

	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
}

/**
 * @dev Main Contract module
 */
contract KryptoRacePreSale is IBEP20, ReentrancyGuard, Context, Ownable {
	using Address for address;
	using SafeMath for uint256;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) public whitelisted;

    mapping(address => bool) public claimed;
    mapping(address => bool) public claimed2;
    mapping(address => bool) public claimed3;
    mapping(address => bool) public claimed4;
  

    string private constant _name         = "KryptoRace";
    string private constant _symbol       = "KRC";
	uint8 private constant _decimals      = 9;
	uint256 private constant _totalSupply = 100 * 10**6 * 10**_decimals; // 100M

	// variables for pre-sale system
	bool public isPreSaleEnabled = false;	
	uint256 private _sDivider;
    uint256 private _sPrice;
    uint256 private _sTotal;

    uint256 public phase = 1;	

	constructor() {
		// set totalSupply variable
		_balances[_msgSender()] = _totalSupply;

		emit Transfer(address(0), _msgSender(), _totalSupply);
    }

	// to receive BNBs
    receive() external payable {
	    revert();
	}

    function getOwner() external view override returns (address) { return owner(); }

    function name() external pure override returns (string memory) { return _name; }

    function symbol() external pure override returns (string memory) { return _symbol; }

    function decimals() external pure override returns (uint8) { return _decimals; }

    function totalSupply() external pure override returns (uint256) { return _totalSupply; }

    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _transfer(_msgSender(), recipient, amount);

        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "BEP20: transfer amount exceeds allowance"));

        return true;
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(_msgSender(), spender, amount);

        return true;
    }

    function allowance(address owner, address spender) external view override returns (uint256) { return _allowances[owner][spender]; }

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));

        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "BEP20: decreased allowance below zero"));

        return true;
    }

    function startPreSale(uint256 referPercent, uint256 salePrice, uint256 tokenAmount) external onlyOwner {
        require(!isPreSaleEnabled, "Pre-sale is already activated!");
		require(referPercent >= 0 && referPercent <= 100, "Value out of range: values between 0 and 100");
		require(salePrice > 0, "Sale price must be greater than zero");
		require(tokenAmount > 0 && tokenAmount <= balanceOf(owner()).div(10**_decimals), "Token amount must be greater than zero and less than or equal to balance of owner.");

		_sDivider         = referPercent;
		_sPrice           = salePrice;
		_sTotal           = 0;
		_transfer(owner(), address(this), tokenAmount.mul(10**_decimals));
		isPreSaleEnabled = true;
    }

	function stopPreSale() external onlyOwner {
		require(isPreSaleEnabled, "Pre-sale is not already activated!");

        isPreSaleEnabled = false;
		// Remove tokens left over from the pre-sales contract
		if (balanceOf(address(this)) > 0) _transfer(address(this), owner(), balanceOf(address(this)));
		// Send BNBs gives pre-sales
		if (address(this).balance > 0) payable(owner()).transfer(address(this).balance);
    }

	function tokenSale(address _refer) external payable returns (bool success) {
		require(isPreSaleEnabled, "Pre-sale is not available.");
        require(msg.value >= 10000000 gwei && msg.value <= 50 ether, "Value out of range: values between 0.01 and 50 BNB");

        uint256 _tokens = _sPrice.mul(msg.value).div(1 ether).mul(10**_decimals);

		if (_msgSender() != _refer && balanceOf(_refer) != 0 && _refer != address(0)) {
			uint256 referTokens = _tokens.mul(_sDivider).div(10**2);

            require((_tokens.add(referTokens)) <= balanceOf(address(this)), "Insufficient tokens for this sale");

			_transfer(address(this), _refer, referTokens);
			_transfer(address(this), _msgSender(), _tokens);
        } else {
            require(_tokens <= balanceOf(address(this)), "Insufficient tokens for this sale");

            _transfer(address(this), _msgSender(), _tokens);
        }
		_sTotal++;

		return true;
    }

    function clearTokens(uint256 amountPercent) external onlyOwner {
        require(amountPercent >= 0 && amountPercent <= 100, "Value out of range: values between 0 and 100");

		uint256 tokenAmount = balanceOf(address(this)); // gets the tokens accumulated in the contract

		if (tokenAmount > 0) {
		    _transfer(address(this), owner(), tokenAmount.mul(amountPercent).div(10**2));
		}
    }

    function claim() external payable {
       
        if(phase == 1){
             require(whitelisted[msg.sender] != false, "You are not whitelisted");
             require(claimed[msg.sender] != true, "Phase 1: already claimed");
             if(claimed[msg.sender] != true){
                uint256 tokenAmount = 50;
                _transfer(address(this), _msgSender(), tokenAmount);
                claimed[msg.sender] = true;
             }

        }else if(phase == 2){
             require(whitelisted[msg.sender] != false, "You are not whitelisted");
             require(claimed2[msg.sender] != true, "Phase 2: Already claimed");
             if(claimed2[msg.sender] != true){
              uint256 tokenAmount = 150;
             _transfer(address(this), _msgSender(), tokenAmount);
              claimed2[msg.sender] = true;
            }

        }
        else if(phase == 3){
             require(whitelisted[msg.sender] != false, "You are not whitelisted");
             require(claimed3[msg.sender] != true, "Phase 3: Already claimed");
             if(claimed3[msg.sender] != true){
              uint256 tokenAmount = 250;
             _transfer(address(this), _msgSender(), tokenAmount);
              claimed3[msg.sender] = true;
            }

        }
        else if(phase == 4){
             require(whitelisted[msg.sender] != false, "You are not whitelisted");
             require(claimed4[msg.sender] != true, "Phase 4: Already claimed");
             if(claimed4[msg.sender] != true){
              uint256 tokenAmount = 550;
             _transfer(address(this), _msgSender(), tokenAmount);
              claimed4[msg.sender] = true;
            }

        }
       
    }

    function activeDrop(uint256 number) public onlyOwner{
        phase = number;
    }

    function whitelistUser(address _user) public onlyOwner {
        whitelisted[_user] = true;
    }
    
    function removeWhitelistUser(address _user) public onlyOwner {
        whitelisted[_user] = false;
    }

    function clearBNB(uint256 amountPercent) external onlyOwner {
        require(amountPercent >= 0 && amountPercent <= 100, "Value out of range: values between 0 and 100");

		uint256 bnbAmount = address(this).balance; // gets the BNBs accumulated in the contract

		if (bnbAmount > 0) {
		    payable(owner()).transfer(bnbAmount.mul(amountPercent).div(10**2));
		}
    }

    function viewSale() external view returns (uint256 referPercent, uint256 SalePrice, uint256 SaleCap, uint256 remainingTokens, uint256 SaleCount) {
		require(isPreSaleEnabled, "Pre-sale is not available.");

		return (_sDivider, _sPrice, address(this).balance, balanceOf(address(this)), _sTotal);
    }

	function _transfer(address from, address to, uint256 amount) private nonReentrant {
        require(from != address(0), "BEP20: transfer from the zero address");
        require(to != address(0), "BEP20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        _balances[from] = _balances[from].sub(amount);
		_balances[to]   = _balances[to].add(amount);

        emit Transfer(from, to, amount);        
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[owner][spender] = amount;
 
        emit Approval(owner, spender, amount);
    }
}