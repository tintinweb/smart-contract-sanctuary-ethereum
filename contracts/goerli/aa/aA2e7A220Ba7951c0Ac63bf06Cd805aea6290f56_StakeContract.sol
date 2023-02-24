/**
 *Submitted for verification at Etherscan.io on 2023-02-24
*/

// SPDX-License-Identifier: MIT

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

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

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

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

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
        }
        _balances[to] += amount;

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

// File: @openzeppelin/contracts/security/Pausable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

contract StakeContract is Pausable, Ownable, ReentrancyGuard {

    // the staking and reward token
    ERC20 USDCToken;
    ERC20 USDTToken;

    // the reward rate in percentage
    uint256 public rewardRate; 

    // the reward rate duration  
    // so the final reward rate will be re (rewardRate/rewardRateDuration)
    uint256 public rewardRateDuration; 
    
    // //percetage fee charged on staking amount
    // uint256 public stakeFee;
    // //percetage fee charged on unstaking amount
    // uint256 public unstakeFee;

    // Total stake amount
    uint256 public totalUSDCStakedAmount;
    uint256 public totalUSDTStakedAmount;
    
    struct StakeInfo {          
        uint256 amount; 
        uint256 timeOfLastUpdate;
        uint256 claimTime;
        uint256 rewards;
        uint256 claimAmount;
        uint256 approvedAmount;
    }
    
    struct RequestInfo{    
        address _address;      
        uint256 _amount;
    }

    mapping(address => StakeInfo) public USDCstakeInfos;
    mapping(address => StakeInfo) public USDTstakeInfos;

    mapping(uint256 => RequestInfo) public usdcRequerstList;
    mapping(uint256 => RequestInfo) public usdtRequerstList;

    uint256 public usdcRequestCount;
    uint256 public usdtRequestCount;

    address[] public usdcWalletList;
    address[] public usdtWalletList;

    /**************************************************/
    /******************** Events **********************/
    /**************************************************/    
    event Staked(address indexed from, uint256 amount, string _tokenType);
    event Unstake(address indexed from, uint256 amount, string _tokenType);
    event Claim(address indexed from, uint256 amount, string _tokenType);

    //constructor
    constructor(ERC20 _usdcAddress,ERC20 _usdtAddress, uint256 _rewardRate) {
        require(address(_usdcAddress) != address(0) && address(_usdtAddress) != address(0),"Token Address cannot be address 0");                
        USDCToken = _usdcAddress; 
        USDTToken = _usdtAddress; 
        rewardRate = (_rewardRate*1000); // 1% = 1*1000 
        rewardRateDuration = 365; // 365 days   
    }    

    /**************************************************/
    /*******************  Modifiers *******************/
    /**************************************************/
    modifier amountGreaterThenZero(uint256 amount){
        require(amount>0,"Amount can't be zero");
        _;
    }

    /**************************************************/
    /************** Public View Functions *************/
    /**************************************************/
    // helper function
    function _getPortion(uint256 _amount, uint256 _percentage) internal pure returns (uint256){
        return (_amount * _percentage) / 1000;
    }

    function _getTokenType(string memory _tokenType, address _staker) internal view returns (StakeInfo memory data){
        if(keccak256(bytes(_tokenType)) == keccak256(bytes("usdc"))){
            return USDCstakeInfos[_staker];
        }else{
            return USDTstakeInfos[_staker];
        }
    }

    function getCurrentTimeStamp() public view returns (uint256){
        return block.timestamp;
    }

    function getCurrentDateDiff(address _staker, string calldata _tokenType) public view returns (uint256){
        return (block.timestamp - _getTokenType(_tokenType,_staker).timeOfLastUpdate) / 60 / 60 / 24;
    }

    function calculateRewards(address _staker, string calldata _tokenType)
        internal
        view
        returns (uint256 _rewards)
    {   
            uint256 diff = (block.timestamp - _getTokenType(_tokenType,_staker).timeOfLastUpdate) / 60 / 60 / 24;
            return  (((_getTokenType(_tokenType, _staker).amount*(rewardRate/rewardRateDuration))/100)*diff)/1000;
            // return (_getPortion(_getTokenType(_tokenType, _staker).amount,rewardRate) * ((block.timestamp - _getTokenType(_tokenType,_staker).timeOfLastUpdate) / rewardRateDuration));
    }

    function getMyClaimRewardTillNow(address _staker, string calldata _tokenType) public view returns (uint256){
            return  _getTokenType(_tokenType, _staker).rewards + calculateRewards(_staker, _tokenType);
    }

    /**************************************************/
    /*************Owner Calling Functions *************/
    /**************************************************/
    
    // set the reward rate
    function setRewardRate(uint256 _rewardRate) external onlyOwner{
        // require(_rewardRate > 0, "Reward rate set more than 0");  
        rewardRate = (_rewardRate*1000);  
    }

    // set the reward rate duration
    function setRewardRateDuration(uint256 _rewardRateDuration) external onlyOwner{
        require(_rewardRateDuration > 0, "Duration set 1 or more than 1");  
        rewardRateDuration = _rewardRateDuration;  
    }

    // set the stake Fee
    // function setStakeFee(uint256 _stakeFee) external onlyOwner{
    //     stakeFee = _stakeFee;
    // }

    // // set the stake Fee
    // function setUnstakeFee(uint256 _unstakeFee) external onlyOwner{
    //     unstakeFee = _unstakeFee;
    // }

    // transfer token from this account to other
    function transferToken(address to,uint256 amount, string calldata _tokenType) external onlyOwner{
        require(USDCToken.balanceOf(owner()) >= amount, "insufficient token balance");  
        if(keccak256(bytes(_tokenType)) == keccak256(bytes("usdc"))){
            require(USDCToken.transfer(to, amount), "Token transfer failed!");  
        }else{
            require(USDTToken.transfer(to, amount), "Token transfer failed!");  
        }
    }

    // transfer token from this account to other
    function depositeToken(uint256 amount, string calldata _tokenType) external onlyOwner{
        require(amount > 0, "Invalid amount");
        if(keccak256(bytes(_tokenType)) == keccak256(bytes("usdc"))){
            require(USDCToken.transferFrom(_msgSender(), address(this), amount), "Token transfer failed!");  
        }else{
            require(USDTToken.transferFrom(_msgSender(), address(this), amount), "Token transfer failed!");  
        }
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function approveClaimAmount(uint256 _indexNum, string calldata _tokenType) public onlyOwner {
        if(keccak256(bytes(_tokenType)) == keccak256(bytes("usdc"))){
            USDCstakeInfos[_msgSender()].claimAmount -= usdcRequerstList[_indexNum]._amount;
            USDCstakeInfos[_msgSender()].approvedAmount += usdcRequerstList[_indexNum]._amount;
            delete usdcRequerstList[_indexNum];
        }else{
            USDTstakeInfos[_msgSender()].claimAmount -= usdtRequerstList[_indexNum]._amount;
            USDTstakeInfos[_msgSender()].approvedAmount += usdtRequerstList[_indexNum]._amount;
            delete usdtRequerstList[_indexNum];
        }
    }

    /**************************************************/
    /********** EXternal Contract Functions ***********/
    /**************************************************/
    function stakeToken(uint256 _stakeAmount, string calldata _tokenType) external whenNotPaused amountGreaterThenZero(_stakeAmount) nonReentrant{
        require(_stakeAmount > 0, "Invalid amount");
        if(keccak256(bytes(_tokenType)) == keccak256(bytes("usdc"))){
            require(USDCToken.balanceOf(_msgSender()) >= _stakeAmount, "Insufficient Balance");

            USDCToken.transferFrom(_msgSender(), address(this), _stakeAmount);
            // _stakeAmount = _stakeAmount - _getPortion(_stakeAmount, stakeFee);

            // If wallet has tokens staked, calculate the rewards before adding the new token
            if(USDCstakeInfos[_msgSender()].amount > 0){
                uint256 reward = calculateRewards(_msgSender(), _tokenType);
                USDCstakeInfos[_msgSender()].rewards += reward;
            }

            if(USDCstakeInfos[_msgSender()].timeOfLastUpdate == 0){
                usdcWalletList.push(msg.sender);
            }

            totalUSDCStakedAmount += _stakeAmount;
            USDCstakeInfos[_msgSender()].amount += _stakeAmount;
            USDCstakeInfos[_msgSender()].timeOfLastUpdate = block.timestamp;
            // USDCstakeInfos[_msgSender()].claimTime = 0;

        }else{

            require(USDTToken.balanceOf(_msgSender()) >= _stakeAmount, "Insufficient Balance");
            USDTToken.transferFrom(_msgSender(), address(this), _stakeAmount);

            if(USDTstakeInfos[_msgSender()].amount>0){
                uint256 reward = calculateRewards(_msgSender(), _tokenType);
                USDTstakeInfos[_msgSender()].rewards += reward;
            }

            if(USDTstakeInfos[_msgSender()].timeOfLastUpdate == 0){
                usdtWalletList.push(msg.sender);
            }

            totalUSDTStakedAmount += _stakeAmount;
            USDTstakeInfos[_msgSender()].amount += _stakeAmount;
            USDTstakeInfos[_msgSender()].timeOfLastUpdate = block.timestamp;
            // USDTstakeInfos[_msgSender()].claimTime = 0;

        }
        
        emit Staked(_msgSender(), _stakeAmount, _tokenType);
    }    

    function unstakeToken(uint256 _unstakeAmount, string calldata _tokenType) external whenNotPaused amountGreaterThenZero(_unstakeAmount) nonReentrant returns (bool){
        require(_unstakeAmount > 0, "Invalid amount");
        if(keccak256(bytes(_tokenType)) == keccak256(bytes("usdc"))){
            require(USDCstakeInfos[_msgSender()].amount >= _unstakeAmount, "Withdraw amount is greater than stak");
            require(USDCstakeInfos[_msgSender()].rewards+USDCstakeInfos[_msgSender()].amount >= USDCstakeInfos[_msgSender()].claimAmount+USDCstakeInfos[_msgSender()].approvedAmount+_unstakeAmount, "Withdraw amount is greater than stack");
        }else{
            require(USDTstakeInfos[_msgSender()].amount >= _unstakeAmount, "Withdraw amount is greater than stak");
            require(USDTstakeInfos[_msgSender()].rewards+USDTstakeInfos[_msgSender()].amount >= USDTstakeInfos[_msgSender()].claimAmount+USDTstakeInfos[_msgSender()].approvedAmount+_unstakeAmount, "Invalid unstake withdraw amount");
        }
        
        uint256 rewards = calculateRewards(_msgSender(), _tokenType);

        if(keccak256(bytes(_tokenType)) == keccak256(bytes("usdc"))){
                USDCstakeInfos[_msgSender()].rewards += rewards;

                if( USDCstakeInfos[_msgSender()].rewards >= _unstakeAmount){
                    USDCstakeInfos[_msgSender()].rewards -= _unstakeAmount;
                }else{
                    uint256 pendingAmount = _unstakeAmount - USDCstakeInfos[_msgSender()].rewards;
                    USDCstakeInfos[_msgSender()].rewards = 0; 
                    USDCstakeInfos[_msgSender()].amount -= pendingAmount;
                }

                USDCstakeInfos[_msgSender()].claimAmount += _unstakeAmount;

                // Update the timeOfLastUpdate for the withdrawer
                USDCstakeInfos[_msgSender()].timeOfLastUpdate = block.timestamp;
                USDCstakeInfos[_msgSender()].claimTime = block.timestamp;

                usdcRequerstList[usdcRequestCount] = RequestInfo(_msgSender(),_unstakeAmount);
                usdcRequestCount++;

                // reset stakced info
                
                //if full amount unstake
                if(USDCstakeInfos[_msgSender()].amount == 0){
                    // set stakced to false
                    USDCstakeInfos[_msgSender()].timeOfLastUpdate=0;
                }
                // transfer token
                // USDCToken.transferFrom(address(this), _msgSender(), _stakeAmount);
        }else{
                USDTstakeInfos[_msgSender()].rewards += rewards;

                if( USDTstakeInfos[_msgSender()].rewards >= _unstakeAmount){
                    USDTstakeInfos[_msgSender()].rewards -= _unstakeAmount;
                }else{
                    uint256 pendingAmount = _unstakeAmount - USDTstakeInfos[_msgSender()].rewards;
                    USDTstakeInfos[_msgSender()].rewards = 0; 
                    USDTstakeInfos[_msgSender()].amount -= pendingAmount;
                }

                USDTstakeInfos[_msgSender()].claimAmount += _unstakeAmount;

                // Update the timeOfLastUpdate for the withdrawer
                USDTstakeInfos[_msgSender()].timeOfLastUpdate = block.timestamp;
                USDTstakeInfos[_msgSender()].claimTime = block.timestamp;
            
                usdtRequerstList[usdtRequestCount] = RequestInfo(_msgSender(), _unstakeAmount);
                usdtRequestCount++;

                //if full amount unstake
                if(USDTstakeInfos[_msgSender()].amount==0){
                    // set stakced to false
                    USDTstakeInfos[_msgSender()].timeOfLastUpdate=0;
                }
                // transfer token
                // USDTToken.transferFrom(address(this), _msgSender(), _stakeAmount);
        }
        
        emit Unstake(_msgSender(), _unstakeAmount, _tokenType);

        return true;
    }

    function claimReward(string calldata _tokenType) external whenNotPaused nonReentrant returns (bool){
        // claimed reward should be grater then 0
        if(keccak256(bytes(_tokenType)) == keccak256(bytes("usdc"))){
            require(USDCstakeInfos[_msgSender()].approvedAmount > 0, "Already claimed");
            
            uint256 approvedAmount = USDCstakeInfos[_msgSender()].approvedAmount;
            USDCToken.transfer(_msgSender(), approvedAmount);

            totalUSDCStakedAmount -= approvedAmount;

            USDCstakeInfos[_msgSender()].approvedAmount = 0;
            USDCstakeInfos[_msgSender()].claimTime = 0;

            emit Claim(_msgSender(), approvedAmount, _tokenType);

        }else{
            require(USDTstakeInfos[_msgSender()].approvedAmount > 0, "Already claimed");
            
            uint256 approvedAmount = USDTstakeInfos[_msgSender()].approvedAmount;
            
            USDTToken.transfer(_msgSender(), approvedAmount);

            totalUSDTStakedAmount -= approvedAmount;

            USDTstakeInfos[_msgSender()].approvedAmount = 0;
            USDTstakeInfos[_msgSender()].claimTime = 0;

            emit Claim(_msgSender(), approvedAmount, _tokenType);
        }
        
        return true;
    }

    function getWalletList() public view returns (address[] memory _usdc, address[] memory _usdt){
        return (usdcWalletList, usdtWalletList);
    }

}