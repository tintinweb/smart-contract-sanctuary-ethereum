/**
 *Submitted for verification at Etherscan.io on 2022-09-11
*/

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
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


// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
contract ERC20 is Context, IERC20, IERC20Metadata, ReentrancyGuard {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;
    string private constant _name = "MoreBNB";
    string private constant _symbol = "MORE";

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    // constructor(string memory name_, string memory symbol_) {
    //     _name = name_;
    //     _symbol = symbol_;
    // }

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
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
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

contract MoreBNB is ERC20, Ownable {
    event UserStake(address indexed addr, uint256 timestamp, uint256 rawAmount, uint256 duration);
    event UserStakeCollect(address indexed addr, uint256 timestamp, uint256 rawAmount);
    event UserLobby(address indexed addr, uint256 timestamp, uint256 rawAmount);
    event UserLobbyCollect(address indexed addr, uint256 timestamp, uint256 rawAmount);
    event day_lobby_entry(uint256 timestamp, uint256 day, uint256 value);
	event member(address indexed user, address indexed sponsor);

    constructor() {
        _mint(msg.sender, 3000000 * 1e18);
    }
	
	uint256[10] public referrerBonus = [10000, 2000, 1000, 500, 250, 125, 100, 50, 25, 25];
	uint256[8] public pointRequired = [1 * 10**18, 10 * 10**18, 25 * 10**18, 50 * 10**18, 100 * 10**18, 250 * 10**18, 500 * 10**18, 1000 * 10**18];
	uint256[8] public bonus = [1 * 10**17, 1 * 10**18, 25 * 10**17, 5 * 10**18, 10 * 10**18, 25 * 10**18, 50 * 10**18, 100 * 10**18];
	
	address[5] public topSponsor = [address(0), address(0), address(0), address(0), address(0)];
	address public topDepositor;
	uint256 public topDepositorAmount;
	
	uint256 internal constant leaderpool_percentage = 400;
	uint256 internal constant topdepositor_percentage = 200;
    uint256 internal constant topsponsor_percentage = 250;      
    uint256 internal constant admin_percentage = 600;  
    uint256 internal constant tax_on_unstake = 1000;
	
    uint256 public LAUNCH_TIME = 1663092000;
	
    uint256 internal currentDay;
	
    uint256 public lastLobbyPool = 3000000 * 1e18;
	uint256 public lastLobbyPoolMinValue = 1000000 * 1e18;
	
    uint256 internal constant _LOBBY_POOL_DECREASE_PERCENTAGE = 10;  
    uint256 internal constant _BONUS_CALC_RATIO = 128;  
    uint256 internal constant _MAX_STAKE_DAYS = 300;  
    uint256 internal constant _DIVIDENDSPOOLCAPDAYS = 30;  
    bool public firstDayFlushed = false;  
	
    struct memberLobby_overallData {
        uint256 overall_collectedTokens;
        uint256 overall_lobbyEnteries;
        uint256 overall_stakedTokens;
        uint256 overall_collectedDivs;
        uint256 referrerPoint;
		uint256 referrerFund;
		uint256 referrerPointOverall;
		uint256 levelClaimed;
		address referrer;
    }
	
	struct Team{
      uint256 member;
    }
	
    mapping(address => memberLobby_overallData) public mapMemberLobby_overallData;
	mapping(address => Team[10]) mapTeam;

    uint256 public overall_lobbyEntry;
	uint256 public topSponsorFund;
	uint256 public leaderPoolFund;
	uint256 public topDepositorFund;
	
    uint256 public overall_stakedTokens;
    uint256 public overall_collectedTokens;
    uint256 public overall_collectedDivs;
    uint256 public overall_collectedBonusTokens;
    mapping(address => uint256) public referrerBonusesPaid;
    mapping(uint256 => uint256) public usersCountDaily;
	mapping(uint256 => uint256)public dayBNBPool;
    mapping(uint256 => uint256)public enterytokenMath;
    mapping(uint256 => uint256)public totalTokensInActiveStake;
	
    uint256 public usersCount = 0;
    uint256 public saveTotalToken;

   struct memberLobby{
        uint256 memberLobbyValue;
		uint256 memberLobbyEntryDay;
        uint256 sponsoredToday;
        bool hasCollected;
    }
	
    mapping(address => mapping(uint256 => memberLobby)) public mapMemberLobby;
    mapping(uint256 => uint256) public lobbyEntry;
	
    struct memberStake {
        address userAddress;
        uint256 tokenValue;
        uint256 startDay;
        uint256 endDay;
        uint256 stakeId;
        bool stakeCollected;
    }
	
    mapping(address => mapping(uint256 => memberStake)) public mapMemberStake;
    mapping(uint256 => uint256) public daysActiveInStakeTokens;
    mapping(uint256 => uint256) public daysActiveInStakeTokensIncrese;
    mapping(uint256 => uint256) public daysActiveInStakeTokensDecrase;
	mapping(address => uint256) public leaderEarnings;
	mapping(address => uint256) public downline;
	
    function flushFirstDayLobbyEntry() external onlyOwner() nonReentrant {
        require(firstDayFlushed == false, "already flushed");
        firstDayFlushed = true;
        payable(owner()).transfer((lobbyEntry[1] * 8550) /10000);  
    }
	
    function flushFirstDayLobbyEntrySwitch() external onlyOwner() {
        firstDayFlushed = true;
    }
	
    function _clcDay() public view returns (uint256) {
        return (block.timestamp - LAUNCH_TIME) / 1 days;
    }
	
    function _updateDaily() public {
        if (currentDay != _clcDay()) {
		
            if (currentDay < _DIVIDENDSPOOLCAPDAYS) 
			{
                for(uint256 _day = currentDay + 1 ; _day <= currentDay * 2 ; _day++)
				{
                    dayBNBPool[_day] += (lobbyEntry[currentDay] * 8550 ) / (currentDay * 10000);
                }
            } 
			else 
			{
                for(uint256 _day = currentDay + 1 ; _day <= currentDay + _DIVIDENDSPOOLCAPDAYS ; _day++)
				{
                    dayBNBPool[_day] += (lobbyEntry[currentDay] * 8550 ) / (_DIVIDENDSPOOLCAPDAYS * 10000);
                }
            }
			
            currentDay = _clcDay();
            _updateLobbyPool();
            _sendOwnerShare();
			_sendTopDepositorFund();
			_sendSponsorsShare();
            emit day_lobby_entry(block.timestamp, currentDay, lobbyEntry[currentDay -1]);
        }
    }
	
    function _updateLobbyPool() internal {
		uint256 newValue = lastLobbyPool - ((lastLobbyPool * _LOBBY_POOL_DECREASE_PERCENTAGE) /1000);
		if(lastLobbyPoolMinValue > newValue)
		{
		    lastLobbyPool = lastLobbyPoolMinValue;
		}
		else
		{
		    lastLobbyPool = newValue;
		}
    }
	
    function _sendOwnerShare() internal {
        require(currentDay > 0, "current day is less than or equal to zero");
        payable(owner()).transfer((lobbyEntry[currentDay - 1] * admin_percentage) /10000);
    }
	
	 function _sendTopDepositorFund() internal {
        require(currentDay > 0, "current day is less than or equal to zero");
		
		uint256 fundTosend = topDepositorFund * 10 / 100;
        payable(topDepositor).transfer(fundTosend);
		topDepositor = address(0);
		topDepositorAmount -= fundTosend;
    }
	
	function _sendSponsorsShare() internal {
        require(currentDay > 0, "current day is less than or equal to zero");
        uint256 percentage =  topSponsorFund * 10 / 100;
		
		if(topSponsor[0] != address(0) && percentage > 0)
		{
		   uint256 fundTosend = percentage * 40 / 100;
		   payable(topSponsor[0]).transfer(fundTosend);
		   topSponsorFund -= fundTosend;
		}
		
		if(topSponsor[1] != address(0) && percentage > 0)
		{
		   uint256 fundTosend = percentage * 30 / 100;
		   payable(topSponsor[1]).transfer(fundTosend);
		   topSponsorFund -= fundTosend;
		}
		
		if(topSponsor[2] != address(0) && percentage > 0)
		{
		   uint256 fundTosend = percentage * 20 / 100;
		   payable(topSponsor[2]).transfer(fundTosend);
		   topSponsorFund -= fundTosend;
		}
		
		if(topSponsor[3] != address(0) && percentage > 0)
		{
		   uint256 fundTosend = percentage * 10 / 100;
		   payable(topSponsor[3]).transfer(fundTosend);
		   topSponsorFund -= fundTosend;
		}
    }
	
    function EnterLobby(address referrerAddr) external payable {
        require(referrerAddr != address(0), 'zero address');
		uint256 rawAmount = msg.value;
        require(rawAmount > 0, "ERR: Amount required");
		require(referrerAddr != msg.sender, "ERR: referrer different required");
		
        _updateDaily();
        require(currentDay > 0, "current day is less than or equal to zero");
    
        if (mapMemberLobby[msg.sender][currentDay].memberLobbyValue == 0) 
		{
            usersCount++;
            usersCountDaily[currentDay]++;
        }
		
		if(mapMemberLobby_overallData[msg.sender].referrer == address(0)) 
		{
		    mapMemberLobby_overallData[msg.sender].referrer = referrerAddr;
			mapMemberLobby_overallData[referrerAddr].referrerFund += rawAmount; 
			enterTeam(msg.sender);
		}
		else
		{
		    mapMemberLobby_overallData[mapMemberLobby_overallData[msg.sender].referrer].referrerFund += rawAmount;  
		}
		
        lobbyEntry[currentDay] += rawAmount;
        overall_lobbyEntry += rawAmount;
		
		topSponsorFund += rawAmount * topsponsor_percentage / 10000;
		leaderPoolFund += rawAmount * leaderpool_percentage / 10000;
		topDepositorFund += rawAmount * topdepositor_percentage / 10000;
		
        mapMemberLobby[msg.sender][currentDay].memberLobbyValue += rawAmount; 
        mapMemberLobby[msg.sender][currentDay].memberLobbyEntryDay = currentDay;
        mapMemberLobby[msg.sender][currentDay].hasCollected = false;
		
		mapMemberLobby[mapMemberLobby_overallData[msg.sender].referrer][currentDay].sponsoredToday += rawAmount;
		
		if(mapMemberLobby[msg.sender][currentDay].memberLobbyValue > topDepositorAmount)
		{
		   topDepositor = msg.sender;
		   topDepositorAmount = mapMemberLobby[msg.sender][currentDay].memberLobbyValue;
		}
		
		referralUpdate(msg.sender, rawAmount);
		
        emit UserLobby(msg.sender, block.timestamp, rawAmount);
    }
	
	 function createTeam(address referrerAddr) external
	 {
	     require(referrerAddr != address(0), "zero address");
		 require(referrerAddr != msg.sender, "ERR: referrer different required");
		 
		 require(mapMemberLobby_overallData[msg.sender].referrer == address(0), "sponsor already exits");
		 mapMemberLobby_overallData[msg.sender].referrer = referrerAddr;
		 
		 enterTeam(msg.sender);
         emit member(msg.sender, referrerAddr);
    }
	
	function getTeam(address sponsor, uint256 level) external view returns(uint256){
       return mapTeam[sponsor][level].member;
    }
	
	function enterTeam(address sender) internal{
		address nextReferrer = mapMemberLobby_overallData[sender].referrer;
		uint256 i;
        for(i=0; i < 10; i++) {
			if(nextReferrer != address(0)) 
			{
				downline[nextReferrer] += 1;
				mapTeam[nextReferrer][i].member += 1; 
			}
			else 
			{
				 break;
			}
			nextReferrer = mapMemberLobby_overallData[nextReferrer].referrer;
		}
	}
	
	function referralUpdate(address _address, uint256 amount) private {
		address _nextReferrer = mapMemberLobby_overallData[_address].referrer;
		
		if(_nextReferrer != address(0))
		{
		    if(mapMemberLobby[_nextReferrer][currentDay].sponsoredToday > mapMemberLobby[topSponsor[0]][currentDay].sponsoredToday && topSponsor[0] != _nextReferrer)
			{
				topSponsor[4] = topSponsor[3];
				topSponsor[3] = topSponsor[2];
				topSponsor[2] = topSponsor[1];
				topSponsor[1] = topSponsor[0];
				topSponsor[0] = _nextReferrer;
				
				if(topSponsor[2] == _nextReferrer)
				{
					topSponsor[2] = topSponsor[3];
					topSponsor[3] = topSponsor[4];
				}
				else if(topSponsor[3] == _nextReferrer)
				{
				    topSponsor[3] = topSponsor[4];
				}
				else if(topSponsor[4] == _nextReferrer)
				{
					 topSponsor[4] = address(0);
				}
			}
			else if(mapMemberLobby[_nextReferrer][currentDay].sponsoredToday > mapMemberLobby[topSponsor[1]][currentDay].sponsoredToday && topSponsor[1] !=_nextReferrer)
			{
				topSponsor[4] = topSponsor[3];
				topSponsor[3] = topSponsor[2];
				topSponsor[2] = topSponsor[1];
				topSponsor[1] = _nextReferrer;
				
				if(topSponsor[3] == _nextReferrer)
				{
					topSponsor[3] = topSponsor[4];
				}
				else if(topSponsor[4] == _nextReferrer)
				{
					topSponsor[4] = address(0);
				}
			}
			else if(mapMemberLobby[_nextReferrer][currentDay].sponsoredToday > mapMemberLobby[topSponsor[2]][currentDay].sponsoredToday && topSponsor[2] !=_nextReferrer)
			{
				topSponsor[4] = topSponsor[3];
				topSponsor[3] = topSponsor[2];
				topSponsor[2] = _nextReferrer;
				
				if(topSponsor[4] == _nextReferrer)
				{
					topSponsor[4] = address(0);
				}
			}
			else if(mapMemberLobby[_nextReferrer][currentDay].sponsoredToday > mapMemberLobby[topSponsor[3]][currentDay].sponsoredToday && topSponsor[3] !=_nextReferrer)
			{
				topSponsor[4] = topSponsor[3];
				topSponsor[3] = _nextReferrer;
			}
			else if(mapMemberLobby[_nextReferrer][currentDay].sponsoredToday > mapMemberLobby[topSponsor[4]][currentDay].sponsoredToday && topSponsor[4] !=_nextReferrer)
			{
				 topSponsor[4] = _nextReferrer;
			}
		}
		
		uint i;
		for(i=0; i < 10; i++) 
		{
			if(_nextReferrer != address(0)) 
			{
				mapMemberLobby_overallData[_nextReferrer].referrerPoint += amount * referrerBonus[i] / 10000;
			    mapMemberLobby_overallData[_nextReferrer].referrerPointOverall += amount * referrerBonus[i] / 10000;
			}
			else 
			{
				 break;
			}
		    _nextReferrer = mapMemberLobby_overallData[_nextReferrer].referrer;
		}
    }
	
    function ExitLobby(uint256 targetDay) external {
        require(mapMemberLobby[msg.sender][targetDay].hasCollected == false, "ERR: Already collected");
        _updateDaily();
        require(targetDay < currentDay, "current day is less target day");

        uint256 tokensToPay = _clcTokenValue(msg.sender, targetDay);

        _mint(msg.sender, tokensToPay);
        mapMemberLobby[msg.sender][targetDay].hasCollected = true;
		
        overall_collectedTokens += tokensToPay;
        mapMemberLobby_overallData[msg.sender].overall_collectedTokens += tokensToPay;
		
        emit UserLobbyCollect(msg.sender, block.timestamp, tokensToPay);
    }
	
    function _clcTokenValue (address _address, uint256 _Day) public view returns (uint256) {
        require(_Day != 0, "ERR");
        uint256 _tokenVlaue;
        uint256 entryDay = mapMemberLobby[_address][_Day].memberLobbyEntryDay;
		
        if(entryDay != 0 && entryDay < currentDay) 
		{
            _tokenVlaue = ((lastLobbyPool) / lobbyEntry[entryDay]) * mapMemberLobby[_address][_Day].memberLobbyValue; 
        }
		else
		{
            _tokenVlaue = 0;
        }
        return _tokenVlaue;
    }
	
    function EnterStake(uint256 amount, uint256 stakingDays) external {
        require(stakingDays >= 1, 'Staking: Staking days < 1');
        require(stakingDays <= _MAX_STAKE_DAYS, 'Staking: Staking days > _MAX_STAKE_DAYS');
        require(balanceOf(msg.sender) >= amount, 'Not enough balance');
        
        _updateDaily();
        uint256 stakeId = calcStakeCount(msg.sender);

        overall_stakedTokens += amount;
        mapMemberLobby_overallData[msg.sender].overall_stakedTokens += amount;

        mapMemberStake[msg.sender][stakeId].stakeId = stakeId;
        mapMemberStake[msg.sender][stakeId].userAddress = msg.sender;
        mapMemberStake[msg.sender][stakeId].tokenValue = amount;
        mapMemberStake[msg.sender][stakeId].startDay = currentDay + 1 ;
        mapMemberStake[msg.sender][stakeId].endDay = currentDay + 1 + stakingDays;
        mapMemberStake[msg.sender][stakeId].stakeCollected = false;
        
        for (uint256 i = currentDay + 1; i <= currentDay + stakingDays; i++) {
            totalTokensInActiveStake[i] += amount;
        }
		
        saveTotalToken += amount;
        daysActiveInStakeTokensIncrese[currentDay + 1] += amount;
        daysActiveInStakeTokensDecrase[currentDay + stakingDays + 1] += amount;
		
        _burn(msg.sender, amount);
        emit UserStake (msg.sender, block.timestamp, amount, stakingDays);
    }
	
	function staking(uint256 amount, uint256 stakingDays, address users) internal {
        require(stakingDays >= 1, 'Staking: Staking days < 1');
        require(stakingDays <= _MAX_STAKE_DAYS, 'Staking: Staking days > _MAX_STAKE_DAYS');
        
        _updateDaily();
        uint256 stakeId = calcStakeCount(users);

        overall_stakedTokens += amount;
        mapMemberLobby_overallData[users].overall_stakedTokens += amount;

        mapMemberStake[users][stakeId].stakeId = stakeId;
        mapMemberStake[users][stakeId].userAddress = users;
        mapMemberStake[users][stakeId].tokenValue = amount;
        mapMemberStake[users][stakeId].startDay = currentDay + 1 ;
        mapMemberStake[users][stakeId].endDay = currentDay + 1 + stakingDays;
        mapMemberStake[users][stakeId].stakeCollected = false;
        
        for (uint256 i = currentDay + 1; i <= currentDay + stakingDays; i++) {
            totalTokensInActiveStake[i] += amount;
        }
		
        saveTotalToken += amount;
        daysActiveInStakeTokensIncrese[currentDay + 1] += amount;
        daysActiveInStakeTokensDecrase[currentDay + stakingDays + 1] += amount;
        emit UserStake (users, block.timestamp, amount, stakingDays);
    }
	
    function calcStakeCount(address _address) public view returns (uint256) {
	    require(_address != address(0), 'zero address');
        uint256 stakeCount = 0;
        for (uint256 i = 0; mapMemberStake[_address][i].userAddress == _address; i++) {
            stakeCount += 1;
        }
        return(stakeCount);
    }
	
    function EndStake(uint256 stakeId, bool restakes) external nonReentrant {
        _updateDaily();
		
		require(mapMemberStake[msg.sender][stakeId].endDay <= currentDay, 'Stakes end day not reached yet');
        require(mapMemberStake[msg.sender][stakeId].userAddress == msg.sender, 'Incorrect sender');
        require(mapMemberStake[msg.sender][stakeId].stakeCollected == false, 'Already collected');
		
        uint256 profit = calcStakeCollecting(msg.sender, stakeId);
        overall_collectedDivs += profit;
        mapMemberLobby_overallData[msg.sender].overall_collectedDivs += profit;

        mapMemberStake[msg.sender][stakeId].stakeCollected = true;
		
		if(!restakes)
		{
		    uint256 profitTax = profit * tax_on_unstake / 10000;
		    payable(msg.sender).transfer(profit - profitTax);
		    payable(owner()).transfer(profitTax);
		}
		else
		{
		    payable(msg.sender).transfer(profit);
		}
		
        uint256 stakeReturn = mapMemberStake[msg.sender][stakeId].tokenValue;
		
        if (stakeReturn != 0) {
            uint256 bonusAmount = calcBonusToken(mapMemberStake[msg.sender][stakeId].endDay - mapMemberStake[msg.sender][stakeId].startDay, stakeReturn);
			
			if(!restakes)
			{
			    uint256 bonusTax = (bonusAmount + stakeReturn) * tax_on_unstake / 10000;
			    overall_collectedBonusTokens += bonusAmount;
                _mint(msg.sender, stakeReturn + bonusAmount - bonusTax);
				_mint(owner(), bonusTax);
			}
			else
			{
			    overall_collectedBonusTokens += bonusAmount;
			    staking(stakeReturn + bonusAmount, mapMemberStake[msg.sender][stakeId].endDay - mapMemberStake[msg.sender][stakeId].startDay, msg.sender);
			}
        }
		
        emit UserStakeCollect(msg.sender, block.timestamp, profit);
    }
	
    function calcStakeCollecting(address _address , uint256 _stakeId) public view returns (uint256) {
        uint256 userDivs;
        uint256 _endDay = mapMemberStake[_address][_stakeId].endDay;
        uint256 _startDay = mapMemberStake[_address][_stakeId].startDay;
        uint256 _stakeValue = mapMemberStake[_address][_stakeId].tokenValue;
		
        for (uint256 _day = _startDay ; _day < _endDay && _day < currentDay; _day++) 
		{ 
            userDivs += (dayBNBPool[_day] * _stakeValue) / totalTokensInActiveStake[_day]  ;
        }
        return (userDivs);
    }
	
    function calcBonusToken (uint256 StakeDuration, uint256 StakeAmount) public pure returns (uint256) {
        require(StakeDuration <= _MAX_STAKE_DAYS, 'Staking: Staking days > _MAX_STAKE_DAYS');
        uint256 _bonusAmount = StakeAmount * ((StakeDuration **2) * _BONUS_CALC_RATIO);
        return _bonusAmount /1e7;
    }
	
	function claimBonus() external {
	    uint256 totalPoint = mapMemberLobby_overallData[msg.sender].referrerPoint;
		if(totalPoint > 0)
		{
		   if(totalPoint >= pointRequired[0] && 1 > mapMemberLobby_overallData[msg.sender].levelClaimed)
		   {
		       require(leaderPoolFund >= bonus[0], "insufficient bnb in pool");
			   
			   leaderPoolFund = leaderPoolFund - bonus[0];
			   mapMemberLobby_overallData[msg.sender].referrerPoint = mapMemberLobby_overallData[msg.sender].referrerPoint - pointRequired[0];
			   mapMemberLobby_overallData[msg.sender].levelClaimed = 1;
		       payable(msg.sender).transfer(bonus[0]);
			   
			   leaderEarnings[msg.sender] += bonus[0];
		   }
		   else if(totalPoint >= pointRequired[1] && 2 > mapMemberLobby_overallData[msg.sender].levelClaimed)
		   {
		       require(leaderPoolFund >= bonus[1], "insufficient bnb in pool");
			   
			   leaderPoolFund = leaderPoolFund - bonus[1];
			   mapMemberLobby_overallData[msg.sender].referrerPoint = mapMemberLobby_overallData[msg.sender].referrerPoint - pointRequired[1];
			   mapMemberLobby_overallData[msg.sender].levelClaimed = 2;
			   payable(msg.sender).transfer(bonus[1]);
			   
			   leaderEarnings[msg.sender] += bonus[1];
		   }
		   else if(totalPoint >= pointRequired[2] && 3 > mapMemberLobby_overallData[msg.sender].levelClaimed)
		   {
		       require(leaderPoolFund >= bonus[2], "insufficient bnb in pool");
			   
			   leaderPoolFund = leaderPoolFund - bonus[2];
			   mapMemberLobby_overallData[msg.sender].referrerPoint = mapMemberLobby_overallData[msg.sender].referrerPoint - pointRequired[2];
			   mapMemberLobby_overallData[msg.sender].levelClaimed = 3;
			   payable(msg.sender).transfer(bonus[2]);
			   
			   leaderEarnings[msg.sender] += bonus[2];
		   }
		   else if(totalPoint >= pointRequired[3] && 4 > mapMemberLobby_overallData[msg.sender].levelClaimed)
		   {
		       require(leaderPoolFund >= bonus[3], "insufficient bnb in pool");
			   
			   leaderPoolFund = leaderPoolFund - bonus[3];
			   mapMemberLobby_overallData[msg.sender].referrerPoint = mapMemberLobby_overallData[msg.sender].referrerPoint - pointRequired[3];
			   mapMemberLobby_overallData[msg.sender].levelClaimed = 4;
			   payable(msg.sender).transfer(bonus[3]);
			   
			   leaderEarnings[msg.sender] += bonus[3];
		   }
		   else if(totalPoint >= pointRequired[4] && 5 > mapMemberLobby_overallData[msg.sender].levelClaimed)
		   {
		       require(leaderPoolFund >= bonus[4], "insufficient bnb in pool");
			   
			   leaderPoolFund = leaderPoolFund - bonus[4];
			   mapMemberLobby_overallData[msg.sender].referrerPoint = mapMemberLobby_overallData[msg.sender].referrerPoint - pointRequired[4];
			   mapMemberLobby_overallData[msg.sender].levelClaimed = 5;
			   payable(msg.sender).transfer(bonus[4]);
			   
			   leaderEarnings[msg.sender] += bonus[4];
		   }
		   else if(totalPoint >= pointRequired[5] && 6 > mapMemberLobby_overallData[msg.sender].levelClaimed)
		   {
		       require(leaderPoolFund >= bonus[5], "insufficient bnb in pool");
			   
			   leaderPoolFund = leaderPoolFund - bonus[5];
			   mapMemberLobby_overallData[msg.sender].referrerPoint = mapMemberLobby_overallData[msg.sender].referrerPoint - pointRequired[5];
			   mapMemberLobby_overallData[msg.sender].levelClaimed = 6;
			   payable(msg.sender).transfer(bonus[5]);
			   
			   leaderEarnings[msg.sender] += bonus[5];
		   }
		   else if(totalPoint >= pointRequired[6] && 7 > mapMemberLobby_overallData[msg.sender].levelClaimed)
		   {
		       require(leaderPoolFund >= bonus[6], "insufficient bnb in pool");
			   
			   leaderPoolFund = leaderPoolFund - bonus[6];
			   mapMemberLobby_overallData[msg.sender].referrerPoint = mapMemberLobby_overallData[msg.sender].referrerPoint - pointRequired[6];
			   mapMemberLobby_overallData[msg.sender].levelClaimed = 7;
			   payable(msg.sender).transfer(bonus[6]);
			   
			   leaderEarnings[msg.sender] += bonus[6];
		   }
		   else if(totalPoint >= pointRequired[7] && 8 > mapMemberLobby_overallData[msg.sender].levelClaimed)
		   {
		       require(leaderPoolFund >= bonus[7], "insufficient bnb in pool");
			   
			   leaderPoolFund = leaderPoolFund - bonus[7];
			   mapMemberLobby_overallData[msg.sender].referrerPoint = mapMemberLobby_overallData[msg.sender].referrerPoint - pointRequired[7];
			   mapMemberLobby_overallData[msg.sender].levelClaimed = 8;
			   payable(msg.sender).transfer(bonus[7]);
			   
			   leaderEarnings[msg.sender] += bonus[7];
		   }
		}
    }
}