/**
 *Submitted for verification at Etherscan.io on 2023-06-13
*/

// SPDX-License-Identifier: MIT
	
	/**
	 * VladimirGav
	 * GitHub Website: https://vladimirgav.github.io/
	 * GitHub: https://github.com/VladimirGav
	 */
	
	/**
	 * It is example of a Token Buy and Sell Tax from VladimirGav
	 * This contract example contains the minimum number of functions required for the token to work.
	 * Contract SimpleToken: Read: _decimals, decimals, _name, name, _symbol, symbol, allowance, balanceOf, totalSupply; Write:  transfer, transferFrom, approve, decreaseAllowance, increaseAllowance.
	 * Contract Ownable: Read: getOwner, owner; Write:  onlyOwner: renounceOwnership, transferOwnership.
	 */
	
	pragma solidity >=0.8.19;
	
	interface IERC20 {
	    function totalSupply() external view returns (uint256);
	
	    function balanceOf(address account) external view returns (uint256);
	
	    function allowance(address owner, address spender) external view returns (uint256);
	
	    function transfer(address recipient, uint256 amount) external returns (bool);
	
	    function approve(address spender, uint256 amount) external returns (bool);
	
	    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
	
	    event Transfer(address indexed from, address indexed to, uint256 value);
	    event Approval(address indexed owner, address indexed spender, uint256 value);
	}
	
	// @dev Wrappers over Solidity's arithmetic operations with added overflow * checks.
	library SafeMath {
	    // Counterpart to Solidity's `+` operator.
	    function add(uint256 a, uint256 b) internal pure returns (uint256) {
	        uint256 c = a + b;
	        require(c >= a, "SafeMath: addition overflow");
	        return c;
	    }
	
	    // Counterpart to Solidity's `-` operator.
	    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
	        return sub(a, b, "SafeMath: subtraction overflow");
	    }
	
	    // Counterpart to Solidity's `-` operator.
	    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
	        require(b <= a, errorMessage);
	        uint256 c = a - b;
	        return c;
	    }
	
	    // Counterpart to Solidity's `*` operator.
	    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
	        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
	        // benefit is lost if 'b' is also tested.
	        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
	        if (a == 0) {
	            return 0;
	        }
	        uint256 c = a * b;
	        require(c / a == b, "SafeMath: multiplication overflow");
	        return c;
	    }
	
	    // Counterpart to Solidity's `/` operator.
	    function div(uint256 a, uint256 b) internal pure returns (uint256) {
	        return div(a, b, "SafeMath: division by zero");
	    }
	
	    // Counterpart to Solidity's `/` operator.
	    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
	        // Solidity only automatically asserts when dividing by 0
	        require(b > 0, errorMessage);
	        uint256 c = a / b;
	        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
	        return c;
	    }
	
	    // Counterpart to Solidity's `%` operator.
	    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
	        return mod(a, b, "SafeMath: modulo by zero");
	    }
	
	    // Counterpart to Solidity's `%` operator.
	    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
	        require(b != 0, errorMessage);
	        return a % b;
	    }
	}
	
	contract Context {
	    // Empty internal constructor, to prevent people from mistakenly deploying
	    // an instance of this contract, which should be used via inheritance.
	    constructor () { }
	
	    function _msgSender() internal view returns (address payable) {
	        return payable(msg.sender);
	    }
	
	    function _msgData() internal view returns (bytes memory) {
	        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
	        return msg.data;
	    }
	}
	
	contract Ownable is Context {
	    address private _owner;
	
	    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
	
	    constructor () {
	        address msgSender = _msgSender();
	        _owner = msgSender;
	        emit OwnershipTransferred(address(0), msgSender);
	    }
	
	    function owner() public view returns (address) {
	        return _owner;
	    }
	
	    modifier onlyOwner() {
	        require(_owner == _msgSender(), "onlyOwner");
	        _;
	    }
	
	    function renounceOwnership() public onlyOwner {
	        emit OwnershipTransferred(_owner, address(0));
	        _owner = address(0);
	    }
	
	    function transferOwnership(address newOwner) public onlyOwner {
	        _transferOwnership(newOwner);
	    }
	
	    function _transferOwnership(address newOwner) internal {
	        require(newOwner != address(0), "Ownable: new owner is the zero address");
	        emit OwnershipTransferred(_owner, newOwner);
	        _owner = newOwner;
	    }
	}
	
	contract SwapBlock is Ownable {
	    using SafeMath for uint256;
	
	    mapping(address=>bool) addressesLiquidity;
	
	    uint256[] private percentsTaxBuy;
	    uint256[] private percentsTaxSell;
	
	    address[] private addressesTaxBuy;
	    address[] private addressesTaxSell;
	
	    function getTaxSum(uint256[] memory _percentsTax) internal pure returns (uint256) {
	        uint256 TaxSum = 0;
	        for (uint i; i < _percentsTax.length; i++) {
	            TaxSum = TaxSum.add(_percentsTax[i]);
	        }
	        return TaxSum;
	    }
	
	    function getPercentsTaxBuy() public view returns (uint256[] memory) {
	        return percentsTaxBuy;
	    }
	
	    function getPercentsTaxSell() public view returns (uint256[] memory) {
	        return percentsTaxSell;
	    }
	
	    function getAddressesTaxBuy() public view returns (address[] memory) {
	        return addressesTaxBuy;
	    }
	
	    function getAddressesTaxSell() public view returns (address[] memory) {
	        return addressesTaxSell;
	    }
	
	    function checkAddressLiquidity(address _addressLiquidity) external view returns (bool) {
	        return addressesLiquidity[_addressLiquidity];
	    }
	
	    function addAddressLiquidity(address _addressLiquidity) public onlyOwner {
	        addressesLiquidity[_addressLiquidity] = true;
	    }
	
	    function removeAddressLiquidity (address _addressLiquidity) public onlyOwner {
	        addressesLiquidity[_addressLiquidity] = false;
	    }
	
	    function setTaxBuy(uint256[] memory _percentsTaxBuy, address[] memory _addressesTaxBuy) public onlyOwner {
	        require(_percentsTaxBuy.length == _addressesTaxBuy.length, "_percentsTaxBuy.length != _addressesTaxBuy.length");
	
	        uint256 TaxSum = getTaxSum(_percentsTaxBuy);
	        require(TaxSum <= 20, "TaxSum > 20"); // Set the maximum tax limit
	
	        percentsTaxBuy = _percentsTaxBuy;
	        addressesTaxBuy = _addressesTaxBuy;
	    }
	
	    function setTaxSell(uint256[] memory _percentsTaxSell, address[] memory _addressesTaxSell) public onlyOwner {
	        require(_percentsTaxSell.length == _addressesTaxSell.length, "_percentsTaxSell.length != _addressesTaxSell.length");
	
	        uint256 TaxSum = getTaxSum(_percentsTaxSell);
	        require(TaxSum <= 20, "TaxSum > 20"); // Set the maximum tax limit
	
	        percentsTaxSell = _percentsTaxSell;
	        addressesTaxSell = _addressesTaxSell;
	    }
	
	    function showTaxBuy() public view returns (uint[] memory, address[] memory) {
	        return (percentsTaxBuy, addressesTaxBuy);
	    }
	
	    function showTaxSell() public view returns (uint[] memory, address[] memory) {
	        return (percentsTaxSell, addressesTaxSell);
	    }
	
	    function showTaxBuySum() public view returns (uint) {
	        return getTaxSum(percentsTaxBuy);
	    }
	
	    function showTaxSellSum() public view returns (uint) {
	        return getTaxSum(percentsTaxSell);
	    }
	
	}
	
	contract SimpleToken is Context, Ownable, IERC20, SwapBlock {
	    using SafeMath for uint256;
	
	    mapping(address => uint256) private _balances;
	    mapping(address => mapping(address => uint256)) private _allowances;
	
	    uint256 private _totalSupply;
	    uint8 public _decimals;
	    string public _symbol;
	    string public _name;
	
	    constructor() {
	        _name = "DIVVY2";
	        _symbol = "DIV2";
	        _decimals = 18;
	        _totalSupply = 1000000 * 1000000000000000000;
	        _balances[msg.sender] = _totalSupply;
	
	        emit Transfer(address(0), msg.sender, _totalSupply);
	    }
	
	    function getOwner() external view returns (address) {
	        return owner();
	    }
	
	    function decimals() external view returns (uint8) {
	        return _decimals;
	    }
	
	    function symbol() external view returns (string memory) {
	        return _symbol;
	    }
	
	    function name() external view returns (string memory) {
	        return _name;
	    }
	
	    function totalSupply() external view returns (uint256) {
	        return _totalSupply;
	    }
	
	    function balanceOf(address account) external view returns (uint256) {
	        return _balances[account];
	    }
	
	    function transfer(address recipient, uint256 amount) external returns (bool) {
	        _transfer(msg.sender, recipient, amount);
	        return true;
	    }
	
	    function allowance(address addressOwner, address spender) external view returns (uint256) {
	        return _allowances[addressOwner][spender];
	    }
	
	    function approve(address spender, uint256 amount) external returns (bool) {
	        _approve(msg.sender, spender, amount);
	        return true;
	    }
	
	    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) {
	        _transfer(sender, recipient, amount);
	        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "Transfer amount exceeds allowance"));
	        return true;
	    }
	
	    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
	        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
	        return true;
	    }
	
	    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
	        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue, "Decreased allowance below zero"));
	        return true;
	    }
	
	    function _transfer(address sender, address recipient, uint256 amount) internal {
	        require(sender != address(0), "Transfer from the zero address");
	        require(recipient != address(0), "Transfer to the zero address");
	        require(amount <= _balances[sender], "Transfer amount exceeds balance");
	
	        _balances[sender] = _balances[sender].sub(amount);
	
	        uint256 amountRecipient = amount;
	        uint256 amountTax = 0;
	
	        if(addressesLiquidity[sender] && SwapBlock.getPercentsTaxBuy().length>0){
	
	            for (uint i; i < SwapBlock.getPercentsTaxBuy().length; i++) {
	                amountTax = amount.div(100).mul(SwapBlock.getPercentsTaxBuy()[i]);
	                amountRecipient = amountRecipient.sub(amountTax);
	                _balances[SwapBlock.getAddressesTaxBuy()[i]] = SafeMath.add(_balances[SwapBlock.getAddressesTaxBuy()[i]], amountTax);
	                emit Transfer(sender, SwapBlock.getAddressesTaxBuy()[i], amountTax);
	            }
	
	            _balances[recipient] = _balances[recipient].add(amountRecipient);
	            emit Transfer(sender, recipient, amountRecipient);
	
	        } else if(addressesLiquidity[recipient] && SwapBlock.getPercentsTaxSell().length>0){
	
	            for (uint i; i < SwapBlock.getPercentsTaxSell().length; i++) {
	                amountTax = amount.div(100).mul(SwapBlock.getPercentsTaxSell()[i]);
	                amountRecipient = amountRecipient.sub(amountTax);
	                _balances[SwapBlock.getAddressesTaxSell()[i]] = SafeMath.add(_balances[SwapBlock.getAddressesTaxSell()[i]], amountTax);
	                emit Transfer(sender, SwapBlock.getAddressesTaxSell()[i], amountTax);
	            }
	
	            _balances[recipient] = _balances[recipient].add(amountRecipient);
	            emit Transfer(sender, recipient, amountRecipient);
	
	        } else {
	            _balances[recipient] = _balances[recipient].add(amount);
	            emit Transfer(sender, recipient, amount);
	        }
	    }
	
	    function _approve(address addressOwner, address spender, uint256 amount) internal {
	        require(addressOwner != address(0), "Approve from the zero address");
	        require(spender != address(0), "Approve to the zero address");
	
	        _allowances[addressOwner][spender] = amount;
	        emit Approval(addressOwner, spender, amount);
	    }
	
	}