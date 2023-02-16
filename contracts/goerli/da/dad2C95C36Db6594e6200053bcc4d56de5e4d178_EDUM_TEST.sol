/**
 *Submitted for verification at Etherscan.io on 2023-02-16
*/

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

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

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol


// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;




/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
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
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
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
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
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
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
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
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
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
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
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
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
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
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

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
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
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
}

// File: contracts/EDUM.sol


pragma solidity ^0.8.0;



contract EDUM_TEST is ERC20, Ownable {
    uint256 private constant TOTAL_SUPPLY = 2000000000;

    /**
     * @dev transferWithLocked 는 controller 만 호출 할 수 있음
     */
    modifier onlyController {
        // require(_isController[_msgSender()] || owner() == _msgSender());
        require(_isController[_msgSender()]);
        _;
    }

    /**
     * @dev Lockup event, Unlockup event 
     */   
    event Locked(address indexed addr, uint256 amount, uint timestamp);
    event Dummy(uint timestamp);

    /**
     * @dev lockup 수량과 release 날짜를 지정.
     * @param amount Lockup 수량
     * @param releaseTime Lockup 기간
     */
    struct TokenLockInfo {
        uint256 amount;                 // locked amount
        uint256 releaseTime;            // unix timestamp
    }

    struct TokenLockState {
        uint256 minReleaseTime;
        TokenLockInfo[] lockInfo;     // Multiple token locks can exist
    }

    // mapping for TokenLockState 
    mapping(address => TokenLockState) public _lockStates;
    event AddTokenLock(address indexed to, uint256 time, uint256 amount);

    // Mapping from controllers to controller status. [GLOBAL - NOT TOKEN-HOLDER-SPECIFIC]
    mapping(address => bool) internal _isController;

    // Array of controllers. [GLOBAL - NOT TOKEN-HOLDER-SPECIFIC]
    address[] internal _controllers;  

    /**
     * @dev Initialize EDUM.
     */
    constructor() ERC20('EDU-Metacore', 'EDUM') {
        _mint(_msgSender(), TOTAL_SUPPLY * 10**decimals());
    }

    /**
     * @dev Set list of controllers.
     * @param controllerList List of controller addresses.
     */
    function setControllers(address[] memory controllerList) public onlyOwner {
        uint ii;
        for (ii = 0; ii < _controllers.length; ii++) {
            _isController[_controllers[ii]] = false;
        }
        for (ii = 0; ii < controllerList.length; ii++) {
            _isController[controllerList[ii]] = true;
        }
        _controllers = controllerList;
    }    

    /**
     * @dev Get list of controllers.
     * @return List of address of all the controllers.
     */
    function controllers() public view returns(address[] memory) {
        return _controllers;
    }    

    /**
     * @dev don't send eth directly to token contract 
     */
    receive() external payable {
        revert("Don't accept ETH");
    }

   /**
    * @dev release 시간이 지난 lockInfo 삭제.
    * @param _addr Release 하고자 하는 address.
    */
    function releaseLockInfo(address _addr) internal {
        uint256 lockCount = 0;
        uint256 lockLength;

        // TokenLockState storage lockState = _lockStates[_addr];

        // Release 할 내용이 없으면 이후를 처리하지 않는다.
        if (_lockStates[_addr].minReleaseTime > block.timestamp) {
            return;
        }

        _lockStates[_addr].minReleaseTime = 0;
        lockLength = _lockStates[_addr].lockInfo.length; 
        // Release 된 LockInfo 를 삭제한다.
        for (uint256 ii = 0; ii < lockLength; /* unchecked inc */) {
            // 아직 Release 되지 않은 LockInfo 만 남겨둔다.
            if (_lockStates[_addr].lockInfo[ii].releaseTime > block.timestamp) {   
                // block.timestamp 기준으로 가장 근시간의 timestamp 를 기록한다.
                if ((_lockStates[_addr].minReleaseTime == 0) || 
                    (_lockStates[_addr].minReleaseTime > _lockStates[_addr].lockInfo[ii].releaseTime)) 
                {
                    _lockStates[_addr].minReleaseTime = _lockStates[_addr].lockInfo[ii].releaseTime;
                }
                _lockStates[_addr].lockInfo[lockCount] = _lockStates[_addr].lockInfo[ii];
                unchecked {
                    lockCount++;
                }
            }
            unchecked {
                ii++;
            }
        }

        if (lockCount == 0) {
            // 모든 lockupInfo 가 releaes 되었을 경우 lockInfo 삭제
            delete _lockStates[_addr];
        } else {
            // Release 된 lockInfo 갯수만큰 뒤에서 pop 함 
            uint256 removeCount = _lockStates[_addr].lockInfo.length - lockCount;            
            for (uint256 ii = 0; ii < removeCount; /* unchecked inc */) {
                 _lockStates[_addr].lockInfo.pop();
                unchecked {
                    ii++;
                }
            }
        }
    }

  /**
   * @dev Lockup 되어 있는 토큰 수량 조회 
   * @param _addr 조회하고자 하는 address.
   * @return totalLocked lock 되어 있는 amount.
   */
    function getLockedBalance(address _addr) public view returns (uint256) {
        uint256 totalLocked = 0;
        uint256 lockLength;
        // TokenLockState memory lockState = _lockStates[_addr];

        lockLength = _lockStates[_addr].lockInfo.length; 
        for (uint256 ii = 0; ii < lockLength; /* unchecked inc */) {
            if (_lockStates[_addr].lockInfo[ii].releaseTime > block.timestamp) {
                totalLocked += _lockStates[_addr].lockInfo[ii].amount;
            }
            unchecked {
                ii++;
            }
        }

        return totalLocked;
    }

   /**
    * @dev Hook that is called before any transfer of tokens. 
    * @param from The address to transfer from.
    * @param to The address to transfer to.
    * @param amount The amount to be transferred.
    */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override {
        super._beforeTokenTransfer(from, to, amount);

        // release 할 token 이 있을 경우에만 relaseLockInfo 함수를 호출한다만
        releaseLockInfo(from);

        // Transfer 가능한 token 수량이 있는지 확인. (mint 함수가 아닌 경우)
        if (from != address(0)) {
            uint256 locked = getLockedBalance(from);
            uint256 accountBalance = balanceOf(from);
            require(accountBalance >= amount, "ERC20: transfer amount exceeds balance");
            require(accountBalance - locked >= amount, "Timelock: some amount has locked.");
        }
    }

   /**
    * @dev Transfer token with lockup.
    * @param _addr The address to transfer to.
    * @param _amount The amount to be transferred.
    * @param _releaseTime The timestamp to unlock token.
    * @return The result of transferWithLocked
    */
    function transferWithLocked(address _addr, uint256[] memory _amount, uint256[] memory _releaseTime) 
        external
        onlyController 
        returns (bool)
    {
        require(_amount.length == _releaseTime.length, "amount and releaeTime must have save length");

        uint ii;
        uint256 totalAmount = 0;
        uint256 amountLength = 0;

        // TokenLockState storage lockState = _lockStates[_addr];
        amountLength = _amount.length; 
        for (ii = 0; ii < amountLength; /* unchecked inc */) {
            totalAmount += _amount[ii]; 

            // Lock 을 하려는 수량이 현재 시간보다 과거인 경우 오류 발생시킴.
            if (_releaseTime[ii] > 0) {
                require(_releaseTime[ii] > block.timestamp, "The releasTime must be later than the block.timestamp");

                // TokenLockInfo 정보를 추가한다.
                _lockStates[_addr].lockInfo.push(TokenLockInfo(_amount[ii], _releaseTime[ii]));

                // releaseTime 이 minReleaseTime 보다 이른 시간일 경우 minReleaseTime 를 갱신한다. 
                if (_lockStates[_addr].minReleaseTime > _releaseTime[ii]) {
                    _lockStates[_addr].minReleaseTime = _releaseTime[ii];
                }

                emit Locked(_addr, _amount[ii], _releaseTime[ii]);
            }
            unchecked {
                ii++;
            }
        }

        transfer(_addr, totalAmount);

        return true;
    }

   /**
    * @dev 여러 주소에 토큰 전송. 발행 지갑에서 모지갑으로 전송될때 사용 (onlyOwner)
    * @param _to 토큰을 전송할 주소 리스트 
    * @param _amount 전송할 토큰수량 리스트 
    */
    function multiTransfer(address[] memory _to, uint256[] memory _amount) external onlyOwner {
        uint transferCount = _to.length;

        require(_to.length == _amount.length, "to and amount must have save length");

        for (uint ii = 0; ii < transferCount; ) {
            transfer(_to[ii], _amount[ii]);
            unchecked {
                ii++;
            }
        }
    }

    function burn(address _account, uint256 _amount) public {
        _burn(_account, _amount);
    }
}