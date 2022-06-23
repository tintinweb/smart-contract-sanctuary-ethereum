/**
 *Submitted for verification at Etherscan.io on 2022-06-22
*/

// File: contracts/ERC20_Stuff.sol



pragma solidity ^0.8.0;



interface IHEX {

    function approve(address spender, uint256 amount) external returns (bool);



    function balanceOf(address account) external view returns (uint256);



    function currentDay() external view returns (uint256);



    function stakeCount(address stakerAddr) external view returns (uint256);



    function stakeEnd(uint256 stakeIndex, uint40 stakeIdParam) external;



    function stakeLists(address, uint256)

        external

        view

        returns (

            uint40 stakeId,

            uint72 stakedHearts,

            uint72 stakeShares,

            uint16 lockedDay,

            uint16 stakedDays,

            uint16 unlockedDay,

            bool isAutoStake

        );



    function stakeStart(uint256 newStakedHearts, uint256 newStakedDays) external;



    function transfer(address recipient, uint256 amount) external returns (bool);



    function transferFrom(

        address sender,

        address recipient,

        uint256 amount

    )external returns (bool);



    function globalInfo() external view returns (

        uint256,

        uint256,

        uint256,

        uint256,

        uint256,

        uint256

        

        // uint72 lockedHeartsTotal,

        // uint72 nextStakeSharesTotal,

        // uint40 shareRate,

        // uint72 stakePenaltyTotal,

        // uint16 dailyDataCount,

        // uint72 stakeSharesTotal,

        // uint40 latestStakeId,

        // uint128 claimStats

    );

    



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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)

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
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[owner][spender];
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
     * @dev Spend `amount` form the allowance of `owner` toward `spender`.
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

// File: @openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/extensions/ERC20Burnable.sol)

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
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }
}

// File: contracts/Tide.sol

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;














// We should check the rest of OZ imports to see if anything else could be helpful

// We should also read the documentation for the ones we're using to make sure we aren't missing anything

contract Tide is ERC20, ERC20Burnable, Ownable, ReentrancyGuard {



    IHEX public hex_contract;

    address manager;

    address constant HEX_ADDRESS = 0x2b591e99afE9f32eAA6214f7B7629768c40Eeb39;



    uint40 public stakes_started = 0;

    uint40 public stakes_ended = 0;

    uint public current_pool_amount = 0;

	uint16 public people_in_pool = 0;

	uint16 public people_in_lobby = 0;

    uint public total_TIDE_sent;

    uint public supplyBeforeBurn;

    uint public burntSupply;

    uint public hexFee;



    // event TransferSent(address _from, address _destAddr, uint _amount);

    // event HexReceived(address _from, uint _amount);

    // event TideMinted(address _to, uint _amount);

    // event StakeStarted(address _by, uint id);



    struct Stake {

        uint256 hearts;

        uint shares;

        uint start;

        uint end;

		uint16 people;

        uint40 id;

        bool has_ended;

    }



    struct Lobby {

        uint256 total_hex;

        uint256 total_tide;

		uint16 people;

    }

    

    constructor() ReentrancyGuard() ERC20("Tide", "TIDE") {

        hex_contract = IHEX(HEX_ADDRESS);

        manager = msg.sender;

    }



    mapping (uint => Stake) stakeID;

    mapping (address => mapping(uint => uint)) specific_TIDE_sent;

    mapping (address => mapping(uint => uint)) specific_HEX_sent;

    mapping (uint => Lobby) exit_lobby_conversion;





    modifier manager_function(){

    require(msg.sender==manager,"Only the manager can call this function");

    _;}

    

    // DEV FUNCTIONS

    function user_tide_balance() external view returns(uint count) {

        return balanceOf(msg.sender);

    }

 

    //number of decimals for TIDE, same as HEX

    function decimals() public pure override returns (uint8) {

        return 8;

    }



    // HEX INTO CONTRACT FUNCTIONS

    //User's can donate HEX and receive TIDE based on the T-Share Rate at the time of donation

    function pool(uint _amount) external payable nonReentrant(){

        require(_amount>0,"You have to send more than the minimum value!");

        hex_contract.transferFrom(msg.sender,address(this),_amount);



		if(specific_HEX_sent[msg.sender][stakes_started]==0){

			people_in_pool++;

		}



        hexFee += _amount / 20;

        uint hexAdded = _amount * 19 / 20;

        

        //hex_contract.transfer(address(0x50cF29C794C9f6EC4187Cf49cb538e526A09c161), hexFee);

        current_pool_amount = current_pool_amount + hexAdded;

        specific_HEX_sent[msg.sender][stakes_started] += hexAdded;



        hexAdded = 0;

        

    }



    /*function currentPool() public view returns (uint ){

        return current_pool_amount;

    }*/



        // This is an exact copy of the donate function but it just sends money to an arbitrary account

    /*function donate_fee(uint _amount) external payable{

        require(_amount>MINIMUM_VALUE,"You have to send more than the minimum value!");

        hex_contract.transferFrom(msg.sender,address(this),_amount);

        emit HexReceived(msg.sender,_amount);



        current_pool_amount = current_pool_amount + _amount/2;



        // the gas this adds is very insignifigant. We could send this to some arbitrary address or we could send it straight to 

        // the liquidity pool

        //hex_contract.transfer(0xD6bf7fD245FC2Cc848264eA8bEAD5558299f2601,_amount/2);

        

        //uint actual_amount = 1000000 * (_amount / get_tshare_rate());

        uint tide_due = 1000000 * _amount / tshare_rate();

        _mint(msg.sender, tide_due);

        emit TideMinted(msg.sender,tide_due);

    }*/



    // START/VIEW STAKE FUNCTIONS

    //Starts a stake if enough days have passed since the last one with all of the HEX sent into this pool

    function start_shit() public nonReentrant(){

        if (stakes_started != 0) {

            uint lastStart = stakeID[stakes_started - 1].start;

            require(get_day() >= lastStart + 3, "have to wait at least 4 days since the last stake was started");

        }

        require(current_pool_amount > 0, "Cannot stake zero HEX");

        

        hex_contract.stakeStart(current_pool_amount,4);



        (uint40 currentID,,uint currentshares,,,,) = hex_contract.stakeLists(address(this), stakes_started-stakes_ended);

        

        Stake memory stake = Stake({

            hearts: current_pool_amount,

            shares: currentshares,

            start: hex_contract.currentDay() + 1 ,

			//The 'end' below this used to have a +1 here, but if we want the MAX time to be 03:23:59, we have to get rid of it

            end: hex_contract.currentDay() + 4+1,

			people: people_in_pool,

            id: currentID,

            has_ended: false

        });



        stakeID[stakes_started] = stake;

        stakes_started++;

        supplyBeforeBurn += currentshares;

        _mint(address(0xD6bf7fD245FC2Cc848264eA8bEAD5558299f2601), currentshares * 100 * 1 / 19);



        current_pool_amount = 0;

        //currenttshares = 0;

        //currentID = 0;



        //emit StakeStarted(msg.sender, stakes_started);

    }



    //Returns how much Hex a user has sent into the current stake pool

    function currentPersonalPool() public view returns(uint){

        return specific_HEX_sent[msg.sender][stakes_started];

    }

    

    function fetchPersonalPools() public view returns (uint[] memory){

        uint totalPoolCount = stakes_started; 

        uint poolCount = 0;



        for(uint i = 0; i < totalPoolCount; i++){

            if(specific_HEX_sent[msg.sender][i] > 0){

                poolCount += 1; //total length

            }

        }



        uint currentIndex = 0;



        uint[] memory pools = new uint[](poolCount);



        for(uint i = 0; i < totalPoolCount; i++){

            if(specific_HEX_sent[msg.sender][i] > 0){

                //uint storage currentItem = i;

                pools[currentIndex] = i;

                currentIndex += 1;

            }

        }

        return pools;

    }



    function claim_All_Tide() public nonReentrant(){

        

        uint[] memory pools = fetchPersonalPools();

        require(pools.length>0,"You have no HEX to claim");

        

        uint tide_due;



        for (uint i = 0; i < pools.length; i++) {

            tide_due += specific_HEX_sent[msg.sender][pools[i]] * stakeID[pools[i]].shares * 18 / 19 * 100 / stakeID[pools[i]].hearts;

            specific_HEX_sent[msg.sender][pools[i]] = 1;

        }



		require(tide_due>100,"You don't have claimable tide!");

        

        _mint(msg.sender, tide_due);



    }



    function getClaimableTide() public view returns (uint){

        

        uint[] memory pools = fetchPersonalPools();

        

        uint tide_due;



        for (uint i = 0; i < pools.length; i++) {

            tide_due += specific_HEX_sent[msg.sender][pools[i]] * stakeID[pools[i]].shares * 18 / 19 *100 / stakeID[pools[i]].hearts;

        }

        

        return tide_due;

    }



    

    //Returns info about a specific Stake

    function get_stake_info(uint _index) public view returns(Stake memory stake){

        return stakeID[_index];

    }





    //Gets the current day from the HEX contract

    function get_day() public view returns (uint time){

        return hex_contract.currentDay();

    }



	function lobbyOpen() public view returns (bool){

		return stakeID[stakes_ended].end + 2 > get_day() && stakeID[stakes_ended].end <= get_day();

	}

    

    // EXIT LOBBY FUNCTIONS

    //User sends amount of TIDE they want to send to current exit lobby

    function enter_exit_lobby(uint256 _amount) public nonReentrant(){

        

        //requires that the user has the amount of tide they are claiming to have

        require(balanceOf(msg.sender)>=_amount, "You're claiming to have more TIDE than you actually have");

        // I change this to 7 so users can only enter the first 7 days

        require(lobbyOpen(), "Sorry the lobby is not open");



        if(specific_TIDE_sent[msg.sender][stakes_ended]==0){

			people_in_lobby++;

		}



        burn(_amount);

        // Say it's the first exit lobby, this mapps the user address to an ID of a stake that has an amount donated

        specific_TIDE_sent[msg.sender][stakes_ended] += _amount;



        // No need to make this a mapping, we're going to assign this value to a exit_lobby struct later

        total_TIDE_sent += _amount;

        burntSupply += _amount;

    }

    



	function specific_Exit_Info(uint _index) public view returns(Lobby memory lobby){

        return exit_lobby_conversion[_index];

    }



    //Returns how much TIDE a user has sent into the current exit lobby

    function currentPersonalExit() public view returns(uint){

        return specific_TIDE_sent[msg.sender][stakes_ended];

    }



	function stakeEndable() public view returns (bool){

		return stakeID[stakes_ended].end + 2 <= get_day() && stakeID[stakes_ended].end + 4 > get_day();

	}



    //Ends the stake that is currently ready to be ended

    function endStakeHEX() public nonReentrant(){

        //require that the stake has ended

        require(stakeEndable(), "the stake cannot be ended early or before the exit lobby has been open at least 2 days");

        // add a require statement on the tail end of the end stake as well?

        //I think this is what you mean, this requires that it cannot be ended 13 days after it expires

        // require(stakeID[stakes_ended].end + 4 > get_day(), "stake cannot be ended more than 4 days after it expires");



        // This makes sure the stake hasn't already been ended so the user doesn't waste gas

        require(stakeID[stakes_ended].has_ended==false,"This stake has already been ended");

		require(total_TIDE_sent>0,"Someone must enter TIDE for the stake to be ended!");

        

        uint balanceBefore = hex_contract.balanceOf(address(this));

        hex_contract.stakeEnd(0,stakeID[stakes_ended].id);

        uint end_stake_amount = hex_contract.balanceOf(address(this)) - balanceBefore;



        Lobby memory lobby = Lobby({

            total_hex: end_stake_amount,

            total_tide: total_TIDE_sent,

			people: people_in_lobby

        });

        

        exit_lobby_conversion[stakes_ended] = lobby;



        stakeID[stakes_ended].has_ended = true;



        stakes_ended++;

        //end_stake_amount=0;

        total_TIDE_sent = 0;

    }



    /*function claim_HEX(uint _endlobbyID) public {

        

        require(specific_TIDE_sent[msg.sender][_endlobbyID]>0,"You have no HEX to claim for this lobby!");

        uint hex_due = exit_lobby_conversion[_endlobbyID].total_hex * specific_TIDE_sent[msg.sender][_endlobbyID] / exit_lobby_conversion[_endlobbyID].total_tide;

        require(hex_contract.balanceOf(CONTRACT_ADDRESS) >= hex_due, "Somehow there isn't enough HEX");



        specific_TIDE_sent[msg.sender][_endlobbyID] = 0;

        hex_contract.transfer(msg.sender,hex_due);



    }*/





    function fetchPersonalLobbies() public view returns (uint[] memory){

        uint totalLobbyCount = stakes_ended; 

        uint lobbyCount = 0;

        for(uint i = 0; i < totalLobbyCount; i++){

            if(specific_TIDE_sent[msg.sender][i] >= 0){

                lobbyCount += 1; //total length

            }

        }



        uint currentIndex = 0;



        uint[] memory lobbies = new uint[](lobbyCount);



        for(uint i = 0; i < totalLobbyCount; i++){

            if(specific_TIDE_sent[msg.sender][i] >= 0 && exit_lobby_conversion[i].total_hex >= 0){

                //uint storage currentItem = i;

                lobbies[currentIndex] = i;

                currentIndex += 1;

            }

        }

        return lobbies;

    }



    function claim_All_HEX() public nonReentrant() {

        

        uint[] memory lobbies = fetchPersonalLobbies();

        require(lobbies.length>0,"You have no HEX to claim");

        

        uint hex_due;



        for (uint i = 0; i < lobbies.length; i++) {

            hex_due += exit_lobby_conversion[lobbies[i]].total_hex * specific_TIDE_sent[msg.sender][lobbies[i]] / exit_lobby_conversion[lobbies[i]].total_tide;

            specific_TIDE_sent[msg.sender][lobbies[i]] = 0;

        }

        

        require(hex_contract.balanceOf(address(this)) >= hex_due);

        hex_contract.transfer(msg.sender,hex_due);



    }



    function getClaimableHex() public view returns (uint){

        

        uint[] memory lobbies = fetchPersonalLobbies();

        

        uint hex_due = 0;



        for (uint i = 0; i < lobbies.length; i++) {

            hex_due += exit_lobby_conversion[lobbies[i]].total_hex * specific_TIDE_sent[msg.sender][lobbies[i]] / exit_lobby_conversion[lobbies[i]].total_tide;

        }

        

        return hex_due;

    }



    /*function beforeBurn() public view returns (uint) {

        return supplyBeforeBurn;

    }



    function afterBurn() public view returns (uint) {

        return burntSupply;

    }*/







	function tshare_rate() public view returns (uint) {

        (,,uint shareRate,,,)= hex_contract.globalInfo();

        return shareRate;

    }







    // MANAGER FUNCTIONS

    /*function withdraw_hex_fees() external manager_function(){

        hex_contract.transfer(msg.sender,hex_contract.balanceOf(CONTRACT_ADDRESS));

    }



    function withdraw_tide_fees() external manager_function(){

        transfer(msg.sender,balanceOf(CONTRACT_ADDRESS));

    }*/



    function managerEndStake() public manager_function{

        

        require(stakeID[stakes_ended].end + 4 <= get_day());

        require(stakeID[stakes_ended].has_ended == false);

        

        uint balanceBefore = hex_contract.balanceOf(address(this));



        hex_contract.stakeEnd(0,stakeID[stakes_ended].id);



        uint end_stake_amount = hex_contract.balanceOf(address(this)) - balanceBefore;

        hexFee += end_stake_amount;



        Lobby memory lobby = Lobby({

            total_hex: 0,

            total_tide: total_TIDE_sent,

			people: people_in_lobby

        });

        

        exit_lobby_conversion[stakes_ended] = lobby;

        stakeID[stakes_ended].has_ended = true;

        stakes_ended++;

        //end_stake_amount=0;

        total_TIDE_sent = 0;

        

     }



     function withdrawHexFee() public manager_function {



        hex_contract.transfer(msg.sender,hexFee);

        hexFee = 0;



     }



    

     // SHIT WE MIGHT NEED LATER



    // Do we just set the mapping of the ended stake to an empty stake?

    /*function forceEnd(uint256 testHex) public {

        

        uint balanceBefore = hex_contract.balanceOf(address(this));

        hex_contract.transferFrom(msg.sender, address(this), testHex);

        uint end_stake_amount = hex_contract.balanceOf(address(this)) - balanceBefore;



        Lobby memory lobby = Lobby({

            total_hex: end_stake_amount,

            total_tide: total_TIDE_sent

        });

        

        exit_lobby_conversion[stakes_ended] = lobby;



        stakeID[stakes_ended].has_ended = true;



        stakes_ended++;

        end_stake_amount=0;

        total_TIDE_sent = 0;

    }*/



    // function forceExitLobby(uint256 _amount) public nonReentrant(){

        

	// 	if(specific_TIDE_sent[msg.sender][stakes_ended]==0){

	// 		people_in_lobby++;

	// 	}

    //     //requires that the user has the amount of tide they are claiming to have

    //     uint user_balance = balanceOf(msg.sender);

    //     require(user_balance>=_amount,"");



    //     burn(_amount);

    //     // Say it's the first exit lobby, this mapps the user address to an ID of a stake that has an amount donated

    //     specific_TIDE_sent[msg.sender][stakes_ended] += _amount;



    //     // No need to make this a mapping, we're going to assign this value to a exit_lobby struct later

    //     total_TIDE_sent += _amount;

    //     burntSupply += _amount;

    // }



}