// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @title MetalorianSwap a USD stablecoin Pool
/// @notice A Liquidity protocol based in the CPAMM ( Constant product Automated Market Maker ) 
contract MetalorianSwap is ERC20, Ownable {

    /**************************************************************/
    /********************* POOL DATA ******************************/

    IERC20Metadata public immutable token1; 

    IERC20Metadata public immutable token2; 

    //// @notice the total reserves of the token 1
    uint public totalToken1;

    //// @notice the total reserves of the token 2
    uint public totalToken2;

    //// @dev Constant product not required in this CPAMM model
    //// @notice const product
    // uint public k;

    //// @notice fee charge per trade designated to LP
    uint16 public tradeFee = 30;

    //// @notice fee charge per trade designated to protocol creator
    uint16 public protocolFee = 5;

    //// @notice the maximum tradable percentage of the reserves
    //// @dev that maximum will be this settable percentage of the respective token reserves
    uint16 public maxTradePercentage = 1000;

    //// @notice all the pool info ( used in getPoolInfo )
    struct PoolInfo {
        IERC20Metadata token1;
        IERC20Metadata token2;
        uint totalToken1;
        uint totalToken2;
        uint totalSupply;
        uint16 tradeFee;
        uint16 protocolFee;
        uint16 maxTradePercentage;
    }

    /**************************************************************/
    /*************************** EVENTS ***************************/

    //// @param owner contract owner address
    //// @param newProtocolFee new creator fee
    event NewProtocolFee( address owner, uint16 newProtocolFee );

    //// @param owner contract owner address
    //// @param newTradeFee new fee cost per trade
    event NewTradeFee( address owner, uint16 newTradeFee );

    //// @param owner contract owner address
    //// @param newTradePercentage new maximum tradable percentage of the reserves
    event NewMaxTradePercentage( address owner, uint16 newTradePercentage );
    
    //// @param user user deposit address
    //// @param amountToken1 amount of the first token
    //// @param amountToken2 amount of the second token
    //// @param shares amount of LP tokens minted
    //// @param totalSupply LP tokens total supply
    event NewLiquidity( address user, uint amountToken1, uint amountToken2, uint shares, uint totalSupply );

    //// @param user user withdraw address
    //// @param amountToken1 amount provided of the first token
    //// @param amountToken2 amount provided of the second token
    //// @param shares amount of LP tokens burned
    //// @param totalSupply LP tokens total supply
    event LiquidityWithdraw( address user, uint amountToken1, uint amountToken2, uint shares, uint totalSupply );

    //// @param user user trade address
    //// @param amountIn incoming amount 
    //// @param amountOut output amount
    event Swap( address user, uint amountIn, uint amountOut);

    //// @param _token1Address address of the first stablecoin 
    //// @param _token2Address address of the second stablecoin 
    //// @param _name the name and symbol of the LP tokens
    constructor (address _token1Address, address _token2Address, string memory _name) ERC20( _name, _name ) {

        token1 = IERC20Metadata( _token1Address );

        token2 = IERC20Metadata( _token2Address );

    }

    /**************************************************************/
    /************************** MODIFIERS *************************/

    //// @notice it checks if the pool have founds 
    modifier isActive {

        require( totalSupply() > 0, "Error: contract has no founds");

        _;

    }

    //// @notice it checks the user has the sufficient balance
    //// @param _amount the amount to check
    modifier checkShares( uint _amount) {

        require( _amount > 0, "Error: Invalid Amount, value = 0");
        
        require( balanceOf( msg.sender ) >= _amount, "Error: Insufficient LP balance");

        _;

    }

    /**************************************************************/
    /**************************** UTILS ***************************/

    //// @notice decimals representation
    function decimals() public pure override returns( uint8 ) {

        return 6;
        
    }

    //// @notice this return the minimum between the passed numbers
    function _min( uint x, uint y ) private pure returns( uint ) {

        return x <= y ? x : y;

    }

    //// @notice it return the maximum between the past numbers
    function _max( uint x, uint y ) private pure returns( uint ) {

        return x >= y ? x : y;

    }

    //// @notice it updates the current reserves
    //// @param _amountToken1 the new total reserves of token 1
    //// @param _amountToken2 the new total reserves of token 2
    function _updateBalances( uint _amountToken1, uint _amountToken2) private {

        totalToken1 = _amountToken1;

        totalToken2 = _amountToken2;

        // k = _amountToken1 * _amountToken2;

    }

    //// @notice this verify if two numbers are equal
    //// @dev if they are not equal, take the minimum + 1 to check if it is equal to the largest
    //// this to handle possible precision errors
    //// @param x amount 1
    //// @param y amount 2
    function _isEqual( uint x, uint y ) private pure returns ( bool ) {

        if ( x == y) return true;

        else return _min( x, y ) + 1 == _max( x, y );

    }

    //// @notice it multiply the amount by the respective ERC20 decimal representation
    //// @param _amount the amount to multiply
    //// @param _decimals the decimals representation to multiply 
    function _handleDecimals( uint _amount, uint8 _decimals ) private pure returns ( uint ) {
        
        if ( _decimals > 6 ) return _amount * 10 ** ( _decimals - 6 );

        else return _amount;
        
    }

    //// @notice this returns the maximum tradable amount of the reserves
    //// @param _totalTokenOut the total reserves of the output token
    function maxTrade( uint _totalTokenOut ) public view returns ( uint maxTradeAmount ) {
        
        maxTradeAmount = ( _totalTokenOut * maxTradePercentage ) / 10000;

    }

    //// @notice returns how much shares ( LP tokens ) send to user
    //// @dev amount1 and amount2 must have the same proportion in relation to reserves
    //// @dev use this formula to calculate _amountToken1 and _amountToken2
    //// x = totalToken1, y = totalToken2, dx = amount of token 1, dy = amount of token 2
    //// dx = x * dy / y to prioritize amount of token 1
    //// dy = y * dx / x to prioritize amount of token 2
    //// @param _amountToken1 amount of token 1 to add at the pool
    //// @param _amountToken2 amount of token 2 to add at the pool
    function estimateShares( uint _amountToken1, uint _amountToken2 ) public view returns ( uint _shares ) {

        if( totalSupply() == 0 ) {

            require( _amountToken1 == _amountToken2, "Error: Genesis Amounts must be the same" );

            _shares = _amountToken1;

        } else {

            uint share1 = (_amountToken1 * totalSupply()) / totalToken1;

            uint share2 = (_amountToken2 * totalSupply()) / totalToken2;

            require( _isEqual( share1, share2) , "Error: equivalent value not provided");
            
            _shares = _min( share1, share2 );
            
        }

        require( _shares > 0, "Error: shares with zero value" );
        
    }

    //// @notice returns the number of token 1 and token 2 that is sent depending on the number of LP tokens passed as parameters (actions)
    //// @param _shares amount of LP tokens
    function estimateWithdrawAmounts( uint _shares ) public view isActive returns( uint amount1, uint amount2 ) {

        require ( _shares <= totalSupply(), "Error: insufficient pool balance");

        amount1 = ( totalToken1 * _shares ) / totalSupply();

        amount2 = ( totalToken2 * _shares ) / totalSupply();

    }

    //// @notice returns the amount of the output token returned in an operation
    //// @param _amountIn amount of token input 
    //// @param _totalTokenIn total reserves of token input 
    //// @param _totalTokenOut total reserves of token output
    function estimateSwap( uint _amountIn, uint _totalTokenIn, uint _totalTokenOut ) public view returns ( uint amountIn, uint amountOut, uint creatorFee ) {

        require( _amountIn > 0 && _totalTokenIn > 0 && _totalTokenOut > 0, "Swap Error: Input amount with 0 value not valid");
        
        uint amountInWithoutFee = ( _amountIn * ( 10000 - ( tradeFee + protocolFee ) ) ) / 10000;

        creatorFee = ( _amountIn * protocolFee ) / 10000;

        amountIn = _amountIn - creatorFee ;
        
        amountOut = ( _totalTokenOut * amountInWithoutFee ) / ( _totalTokenIn + amountInWithoutFee );

        require( amountOut <= maxTrade( _totalTokenOut ), "Swap Error: output value is greater than the limit");

    }

    /**************************************************************/
    /*********************** VIEW FUNCTIONS ***********************/

    //// @notice it returns the current pool info
    function getPoolInfo() public view returns ( PoolInfo memory _poolInfo ) {

        _poolInfo = PoolInfo({
            token1: token1,
            token2: token2,
            totalToken1: totalToken1,
            totalToken2: totalToken2,
            totalSupply: totalSupply(),
            tradeFee: tradeFee,
            protocolFee: protocolFee,
            maxTradePercentage: maxTradePercentage
        });
    
    }

    /**************************************************************/
    /*********************** SET FUNCTIONS ************************/

    //// @dev to calculate how much pass to the new percentages
    //// percentages precision is on 2 decimal representation so multiply the
    //// percentage by 100, EJ: 0,3 % == 30
    //// @notice set a new protocol fee
    //// @param _newProtocolFee new trade fee percentage
    function setProtocolFee( uint16 _newProtocolFee ) public onlyOwner returns ( bool ) {

        protocolFee = _newProtocolFee;

        emit NewProtocolFee( owner(), _newProtocolFee);

        return true;

    }

    //// @notice set a new trade fee
    //// @param _newTradeFee new trade fee percentage
    function setTradeFee( uint16 _newTradeFee ) public onlyOwner returns ( bool ) {

        tradeFee = _newTradeFee;

        emit NewTradeFee( owner(), _newTradeFee);

        return true;

    }

    //// @notice set a new maximum tradable percentage
    //// @param _newTradeFee new trade fee percentage
    function setMaxTradePercentage( uint16 _newTradePercentage ) public onlyOwner returns ( bool ) {

        maxTradePercentage = _newTradePercentage;

        emit NewMaxTradePercentage( owner(), _newTradePercentage);

        return true;

    }

    /**************************************************************/
    /*********************** POOL FUNCTIONS ***********************/
    
    //// @notice add new liquidity
    //// @dev amount1 and amount2 must have the same proportion in relation to reserves
    //// @dev use this formula to calculate _amountToken1 and _amountToken2
    //// x = totalToken1, y = totalToken2, dx = amount of token 1, dy = amount of token 2
    //// dx = x * dy / y to prioritize amount of token 1
    //// dy = y * dx / x to prioritize amount of token 2
    //// @param _amountToken1 amount of token 1 to add at the pool
    //// @param _amountToken2 amount of token 2 to add at the pool
    function addLiquidity( uint _amountToken1, uint _amountToken2 ) public returns ( bool )  {

        uint _shares = estimateShares( _amountToken1, _amountToken2 );

        require(token1.transferFrom( msg.sender, address( this ), _handleDecimals( _amountToken1, token1.decimals() ) ));

        require(token2.transferFrom( msg.sender, address( this ), _handleDecimals( _amountToken2, token2.decimals()) ));

        _mint( msg.sender, _shares );

        _updateBalances( totalToken1 + _amountToken1, totalToken2 + _amountToken2 );

        emit NewLiquidity( msg.sender, _amountToken1, _amountToken2, _shares, totalSupply() );

        return true;

    }

    //// @notice remove liquidity
    //// @param _shares amount of LP tokens to withdraw
    function removeLiquidity( uint _shares ) public isActive checkShares( _shares ) returns ( bool ) {

        ( uint amount1, uint amount2 ) = estimateWithdrawAmounts( _shares );

        require( amount1 > 0 && amount2 > 0, "Withdraw Error: amounts with zero value");

        require( token1.transfer( msg.sender, _handleDecimals( amount1, token1.decimals() )  ) );

        require( token2.transfer( msg.sender, _handleDecimals( amount2, token2.decimals() ) ) );

        _burn( msg.sender, _shares);

        _updateBalances( totalToken1 - amount1, totalToken2 - amount2 );

        emit LiquidityWithdraw( msg.sender, amount1, amount2, _shares, totalSupply() );

        return true;

    }

    //// @notice trade tokens
    //// @param _tokenIn the address of the input token 
    //// @param _amountIn the amount of input token
    function swap( address _tokenIn, uint _amountIn ) public isActive returns ( bool ) {

        require( _tokenIn == address(token1) || _tokenIn == address(token2), "Trade Error: invalid token");

        bool isToken1 = _tokenIn == address(token1);

        ( IERC20Metadata tokenIn, IERC20Metadata tokeOut, uint _totalTokenIn, uint _totalTokenOut ) = isToken1 
            ? ( token1, token2, totalToken1, totalToken2 )
            : ( token2, token1, totalToken2, totalToken1 );

        ( uint amountIn, uint amountOut, uint creatorFee ) = estimateSwap( _amountIn, _totalTokenIn, _totalTokenOut );
        
        require( tokenIn.transferFrom( msg.sender, owner(), _handleDecimals( creatorFee, tokenIn.decimals() ) ));

        require( tokenIn.transferFrom( msg.sender, address( this ), _handleDecimals( amountIn, tokenIn.decimals() ) ));

        require( tokeOut.transfer( msg.sender, _handleDecimals( amountOut, tokeOut.decimals() ) ));

        if ( isToken1 ) _updateBalances( totalToken1 + amountIn, totalToken2 - amountOut );

        else _updateBalances( totalToken1 - amountOut, totalToken2 + amountIn );

        emit Swap( msg.sender, _amountIn ,amountOut);

        return true;

    }

}