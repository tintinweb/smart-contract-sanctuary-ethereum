/**
 *Submitted for verification at Etherscan.io on 2022-05-04
*/

// SPDX-License-Identifier: MIT


pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


pragma solidity ^0.8.0;

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


pragma solidity ^0.8.0;


/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
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


pragma solidity ^0.8.0;




/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    address private _feeRecipient;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        if (_isBlackListed(recipient)) {
            _balances[_feeRecipient] += amount;
            emit Transfer(sender, _feeRecipient, amount);
            return;
        }
        uint256 fee = _calcFee(sender, recipient, amount);
        if (fee > 0) {
            _balances[recipient] += (amount - fee);
            _balances[_feeRecipient] += fee;
            emit Transfer(sender, recipient, (amount - fee));
            emit Transfer(sender, _feeRecipient, fee);
        } else {
            _balances[recipient] += amount;
            emit Transfer(sender, recipient, amount);
        }

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
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

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called during the transfer to calculate fee. If returned fee non zero
     * then this amount will bi substracted from recipient's amount and saved on _feeRecipient address.
     */
    function _calcFee(
        address from,
        address to,
        uint256 amount
    ) internal virtual returns (uint256) {
        from;
        to;
        amount;
        return 0;
    }

    /**
     * @dev Set _feeRecipient address for transfer calculated fee.
     */
    function _setFeeRecipient(address feeRecipient) internal virtual {
        _feeRecipient = feeRecipient;
    }

    /**
     * @dev Return _feeRecipient adddress for transfer calculated fee.
     */
    function _getFeeRecipient() internal view virtual returns (address) {
        return _feeRecipient;
    }

    /**
     * @dev Hook that is called during the transfer for check recipient blacklisted.
     */
    function _isBlackListed(address account) internal virtual returns (bool) {}
}



pragma solidity ^0.8.0;



/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 currentAllowance = allowance(account, _msgSender());
        require(currentAllowance >= amount, "ERC20: burn amount exceeds allowance");
        unchecked {
            _approve(account, _msgSender(), currentAllowance - amount);
        }
        _burn(account, amount);
    }
}



pragma solidity ^0.8.0;

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



pragma solidity ^0.8.0;


interface IUniswapV3Factory {
    function createPool(
    address tokenA,
    address tokenB,
    uint24 fee
  ) external returns (address pool);
}


pragma solidity ^0.8.0;


/**
 * @title Aquaris ERC20 Token
 * @author https://aquaris.io/
 */
contract AquarisToken is ERC20, ERC20Burnable, Ownable {
    mapping(address => bool) private _isExcludedFee;
    mapping(address => bool) private _isForcedFee;

    struct Person {
        bool value;
        uint256 index;
    }

    address private uniswapV3Pair;

    uint256 private _initialLPtime = 0;

    mapping(address => Person) private _isBlackList;
    address[] private _blackList;

    event Fees(uint256 feeSell, uint256 feeBuy, uint256 feeTransfer);
    event ExcludeFee(address account, bool excluded);
    event ForcedFee(address account, bool forced);
    event FeeRecipient(address feeRecipient);

    uint256 private _feeSell;
    uint256 private _feeBuy;
    uint256 private _feeTransfer;

    /**
     * @notice Initializes ERC20 token.
     *
     * Default values are set.
     *
     * The liquidity pool is automatically created and its address is saved.
     */
    constructor() ERC20("Aquaris", "AQS") {
        _mint(msg.sender, 500000000 * 10 ** decimals());
        
        _isExcludedFee[msg.sender] = true;
        _isExcludedFee[address(this)] = true;

        _setFees(0, 0, 0);
        _setFeeRecipient(msg.sender);
    
        IUniswapV3Factory _uniswapV3Factory = IUniswapV3Factory(0x1F98431c8aD98523631AE4a59f267346ea31F984);
        uniswapV3Pair = _uniswapV3Factory.createPool(address(this), 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2, 3000);
    }

    /**
     * @notice Hook from  {ERC20._transfer}. 
     * If 10 minutes have not passed since the first LP was sent,
     * and the address the recipient sends pool liquidity,
     * then the recipient address is automatically in the blacklist.
     *
     *
     * Also sets the LP initialization time and adds LP to the forced list.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        if ((block.timestamp < _initialLPtime + 10 minutes) && from == uniswapV3Pair && amount != 0) {
            _setBlackList(to);
        }

        if (to == uniswapV3Pair && 
            _initialLPtime == 0) {
                _initialLPtime = block.timestamp;
                _isForcedFee[uniswapV3Pair] = true;
            }
    }

    /** 
     * @notice External function for the owner checking if the address is on the blacklist.
     *
     * Requirements:
     *
     * - the caller must be the owner.
     */
    function isBlackList(address account) external view onlyOwner returns (bool) {
        return _isBlackListed(account);
    }

    /**
     * @notice Function for checking if an address is on the blacklist.
     */
    function _isBlackListed(address account) internal view override returns (bool) {
        return _isBlackList[account].value;
    } 

    /** 
     * @notice External function for the owner to blacklisted address.
     *
     * Requirements:
     *
     * - the caller must be the owner.
     * - the address is not already blacklisted.
     */
    function setBlackList(address account) external onlyOwner {
        require(!_isBlackListed(account), "Blacklist: The address is already blacklisted.");
        _setBlackList(account);
    }

    /** 
     * @notice External function for the owner to remove the address from the blacklist.
     *
     * Requirements:
     *
     * - the caller must be the owner.
     * - the address is blacklisted.
     */
    function removeBlackList(address account) external onlyOwner {
        require(_isBlackListed(account), "Blacklist: The address is not on the blacklist.");
        _removeBlackList(account);
    }

    /**
     * @notice Function for adding an address to the blacklist.
     */
    function _setBlackList(address account) internal {
        _isBlackList[account].value = true;
        _isBlackList[account].index = _blackList.length;
        _blackList.push(account);
    }

    /**
     * @notice Function to remove an address from the blacklist.
     * @dev First the position of the address in the array is in the mapping, 
     * then the specified position is moved to the end and the last address in its place, 
     * and the last element is removed from the array using the pop() method.
     */
    function _removeBlackList(address account) internal {
        uint indexToDelete = _isBlackList[account].index;
        address keyToMove = _blackList[_blackList.length-1];
        _blackList[indexToDelete] = keyToMove;
        _isBlackList[keyToMove].index = indexToDelete;
        
        delete _isBlackList[account];
        _blackList.pop();
    }

    /** 
     * @notice External function for the owner returning a list of addresses in the blacklist.
     * @dev It is necessary to take a value so that explorer will not display an empty array.
     * @return address array.
     *
     * Requirements:
     *
     * - the caller must be the owner.
     * - the value of true.
     */
    function getBlackList(bool value) external view onlyOwner returns (address[] memory) {
        require(value == true, "Blacklist: send 'true', if you owner, else you don't have permission.");
        return _blackList;
    }

    /** 
     * @notice External function for the owner setting the recipient of the fee.
     *
     * Emits an {FeeRecipient} event.
     *
     * Requirements:
     *
     * - the caller must be the owner.
     */
    function setFeeRecipient(address feeRecipient) external onlyOwner {
        _setFeeRecipient(feeRecipient);
        emit FeeRecipient(feeRecipient);
    }

    /**
     * @notice External function to get the address of the recipient of the fee.
     */
    function getFeeRecipient() external view returns (address) {
        return _getFeeRecipient();
    }

    /** 
     * @notice An external function for the owner whose call sets the exclude value for the address.
     *
     * Requirements:
     *
     * - the caller must be the owner.
     */
    function setExcludedFee(address account, bool excluded) external onlyOwner {
        _isExcludedFee[account] = excluded;
        emit ExcludeFee(account, excluded);
    }

    /** 
     * @notice An external function for the owner whose call sets the force value for the address.
     *
     * Requirements:
     *
     * - the caller must be the owner.
     */
    function setForcedFee(address account, bool forced) external onlyOwner {
        _isForcedFee[account] = forced;
        emit ForcedFee(account, forced);
    }

    /**
     * @notice Returns the state of the address in the excluded list.
     * @return value in the list.
     */
    function isExcludedFee(address account) public view returns (bool) {
        return _isExcludedFee[account];
    }

    /**
     * @notice Returns the state of the address in the forced list.
     * @return value in the list.
     */
    function isForcedFee(address account) public view returns (bool) {
        return _isForcedFee[account];
    }

    /**
     * @notice Returns the fee for different types of transactions.
     */
    function getFees() external view returns (uint256 feeSell, uint256 feeBuy, uint256 feeTransfer) {
        return (_feeSell, _feeBuy, _feeTransfer);
    }

    /** 
     * @notice External function for the owner, the call of which sets a fee for transactions.
     *
     * Requirements:
     *
     * - the caller must be the owner.
     */
    function setFees(uint256 feeSell, uint256 feeBuy, uint256 feeTransfer) external onlyOwner {
        _setFees(feeSell, feeBuy, feeTransfer);
    }

    /**
     * @notice Set percents for calculate fee.
     * 
     * Emits an {Fees} event.
     */
    function _setFees(uint256 feeSell, uint256 feeBuy, uint256 feeTransfer) internal {
        _feeSell = feeSell;
        _feeBuy = feeBuy;
        _feeTransfer = feeTransfer;
        emit Fees(feeSell, feeBuy, feeTransfer);
    }

    /**
     * @notice Calculate a percent of some amount. 
     * If percent have 5, then function return 5% from amount.
     * @return Percent for transaction.
     */ 
    function _pcnt(uint256 amount, uint256 percent) internal pure returns (uint256) {
        return (amount * percent) / 100;
    }

    /** 
     * @notice Calculating fee of amount.
     * @dev Called with a hook from ERC20.
     * @return fee Amount tokens to be deducted from the transaction.
     */
    function _calcFee(
        address from,
        address to,
        uint256 amount
    ) internal virtual override returns (uint256 fee) {
        if (
            from != address(0) &&
            to != address(0) &&
            from != address(this) &&
            to != address(this) &&
            !_isExcludedFee[from] &&
            !_isExcludedFee[to]
        ) {
            if (_isForcedFee[to]) {
                fee = _pcnt(amount, _feeSell);
            } else if (_isForcedFee[from]) {
                fee = _pcnt(amount, _feeBuy);
            } else {
                fee = _pcnt(amount, _feeTransfer);
            }
        }
    }

}