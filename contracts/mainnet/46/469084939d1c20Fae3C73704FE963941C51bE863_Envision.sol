/**
 *Submitted for verification at Etherscan.io on 2022-03-04
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0; 

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}
/**
 * @dev Implementation of the DGMV Token
 *  
 */
contract Envision is Ownable, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;
    mapping (address => bool) private _isExcludedFromFee;
    mapping(address => mapping(address => uint256)) private _allowances;

    string constant private _name = "Envision";
    string constant private _symbol = "VIS";
    uint8  constant private _decimal = 18;
    uint256 private _totalSupply = 200000000 * (10 ** _decimal); // 200 million tokens
    uint256 constant public _taxBurn = 2;
    uint256 constant public _taxLiquidity = 5;
    address public teamWallet;
    uint256 public toBurnAmount = 0;

    event teamWalletChanged(address oldWalletAddress, address newWalletAddress);
    event feeCollected(address teamWallet, uint256 amount);
    event excludingAddressFromFee(address account);
    event includingAddressInFee(address account);

    modifier onlyTeamWallet() {
        require(teamWallet == _msgSender(), "Caller is not the teamwallet");
        _;
    }

    
    /**
     * @dev Sets the values for {name}, {symbol}, {total supply} and {decimal}.
     * Currently teamWallet will be Owner and can be changed later
     */
    constructor(address _teamWallet) {
        require(_teamWallet!=address(0), "Cannot set teamwallet as zero address");
        _balances[_msgSender()] = _totalSupply;
        _isExcludedFromFee[_msgSender()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_teamWallet] = true;
        teamWallet = _teamWallet;  
        emit Transfer(address(0), _msgSender(), _totalSupply);
    }
    
    /**
     * @dev Returns Name of the token
     */
    function name() external view virtual override returns (string memory) {
        return _name;
    }
    
    /**
     * @dev Returns the symbol of the token, usually a shorter version of the name.
     */
    function symbol() external view virtual override returns (string memory) {
        return _symbol;
    }
    
    /**
     * @dev Returns the number of decimals used to get its user representation
     */
    function decimals() external view virtual override returns (uint8) {
        return _decimal;
    }
    
    /**
     * @dev This will give the total number of tokens in existence.
     */
    function totalSupply() external view virtual override returns (uint256) {
        return _totalSupply;
    }
    
    /**
     * @dev Gets the balance of the specified address.
     */
    function balanceOf(address account) external view virtual override returns (uint256) {
        return _balances[account];
    }
    
    /**
     * @dev Returns collected fees of the token
     */
    function collectedFees() external view returns (uint256) {
        return _balances[address(this)];
    }

    /**
     * @dev Transfer token to a specified address and Emits a Transfer event.
     */
    function transfer(address recipient, uint256 amount) external virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    
    /**
     * @dev Function to check the number of tokens that an owner allowed to a spender
     */
    function allowance(address owner, address spender) external view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }
    
    /**
     * @dev Function to allow anyone to spend a token from your account and Emits an Approval event.
     */
    function approve(address spender, uint256 amount) external virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    /**
     * @dev owner can make exclude the account from paying fee on transfer
     */
    function excludeFromFee(address account) external onlyOwner {
        require(account!=address(0), "Excluding for the zero address");
        _isExcludedFromFee[account] = true;
        emit excludingAddressFromFee(account);
    }
    /**
     * @dev check if account is excluded from fee
     */
    function isExcludedFromFee(address account) external view returns(bool) {
        return _isExcludedFromFee[account];
    }

    /**
     * @dev owner can make the account pay fee on transfer.
     */
    function includeInFee(address account) external onlyOwner {
        require(account!=address(0), "Including for the zero address");
        _isExcludedFromFee[account] = false;
        emit includingAddressInFee(account);
    }

    /**
     * @dev owner can claim collected fees.
     */
    function collectFees() external onlyOwner {
        uint256 fees = _balances[address(this)];
        _transfer(address(this), teamWallet, _balances[address(this)]);
        emit feeCollected(teamWallet, fees);
    }

    /**
     * @dev teamWallet can burn collected burn fees.
     */
    function burnCollectedFees() external onlyTeamWallet {
        require(_balances[teamWallet] >= toBurnAmount, "Does not have the required amount of tokens to burn");
        _transfer(teamWallet, address(0), toBurnAmount);
        _totalSupply -= toBurnAmount;
        toBurnAmount = 0;
        emit feeCollected(address(0), toBurnAmount);
    }

    /**
     * @dev owner can update the collection team wallet
     */
    function updateTeamWallet(address _teamWallet) external onlyOwner {
        require(_teamWallet!=address(0), "Cannot set teamwallet as zero address");
        address oldWallet = teamWallet;
        teamWallet =  _teamWallet;
        _isExcludedFromFee[_teamWallet] = true;
        _isExcludedFromFee[oldWallet] = false;
        emit teamWalletChanged(oldWallet,_teamWallet);
    }
    
    /**
     * @dev Function to transfer allowed token from other's account
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }
    
    /**
     * @dev Function to increase the allowance of another account
     */
    function increaseAllowance(address spender, uint256 addedValue) external virtual returns (bool) {
        require(spender!=address(0), "Increasing allowance for zero address");
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }
    
    /**
     * @dev Function to decrease the allowance of another account
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) external virtual returns (bool) {
        require(spender!=address(0), "Decreasing allowance for zero address");
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }
        return true;
    }
    
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        if(_isExcludedFromFee[sender]) {
            unchecked {//condititon to exclude
                _balances[recipient] += amount;
            }
        }else{ 
            unchecked {
                uint256 burnFee =  (amount * _taxBurn) / 1000;
                uint256 tFee = (amount * (_taxBurn + _taxLiquidity)) / 1000;
                amount = amount - tFee;
                _balances[recipient] += amount;
                _balances[address(this)] +=  tFee;
                toBurnAmount += burnFee;
            }
        }
        emit Transfer(sender, recipient, amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    } 
}