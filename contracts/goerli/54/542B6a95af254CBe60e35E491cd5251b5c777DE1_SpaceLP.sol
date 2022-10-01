// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./SpaceCoin.sol";

contract SpaceLP is ERC20 {

    // fills slot 1
    SpaceCoin spaceCoin;
    // These fill slot 2
    /// @dev These reserve values can be stored as a uint128 as each eth and spaceCoins max supply is much less than 2^128, and they are both commonly read/written at the same time
    /// @notice the last recorded amount of eth in this contract, gets updated after swap, deposit, withdraw, or sync is called
    uint128 public ethReserve;
    /// @notice the last recorded amount of spaceCoin in this contract, gets updated after swap, deposit, withdraw, or sync is called
    uint128 public spaceCoinReserve;

    constructor(SpaceCoin _spaceCoin)  ERC20("Space-ETH LP token", "SPACEETH-LP") {
        spaceCoin = _spaceCoin;
    }

    /// @dev Has no reentrancy guard because spaceCoin has no hooks
    /// @notice Swaps ETH for SPC, or SPC for ETH
    /// @param to The address that will receive the outbound SPC or ETH
    function swap(address to) external {
        // checks //
        // get the ETH Reserve, the contract's current ETH, the spaceCoin reserve, and the contract current spaceCoin into local memory
        (uint _ethReserve, uint currentEth, uint _spaceCoinReserve, uint currentSpaceCoin) = _getValues();
        // calculate the difference in current balance and reserves for both ETH and spaceCoin to determine how much of each was deposited
        uint ethDifference = currentEth - _ethReserve;
        uint spaceCoinDifference = currentSpaceCoin - _spaceCoinReserve;
        // both deposit amounts can't be zero
        if(ethDifference == 0 && spaceCoinDifference == 0) revert NothingToSwap();
        // only one deposit amount can be non-zero
        if(ethDifference > 0 && spaceCoinDifference > 0) revert OutOfSync();
        // calculate the k constant using the set reserves
        uint k = _spaceCoinReserve * _ethReserve;
        // values used to determine amount token to send to user
        uint denominator;
        uint resolver;
        uint amountSold;
        // flag determining the direction of the trade
        bool sellingCoin;
        // check which side a swap is going
        if(spaceCoinDifference > 0) {
            // selling spaceCoin for eth
            sellingCoin = true;
            // set denominator of equation {newReserve = constant k / denominator} where denominator is the new current amount of spaceCoin, minus a 1% fee of amountIn
            denominator = currentSpaceCoin - (spaceCoinDifference / 100);
            // resolver is the current reserve used to calculate amount of token to send based on a new reserve 
            resolver = _ethReserve;
            // used for Swap event
            amountSold = spaceCoinDifference;     
        } else {
            // selling eth for spaceCoin
            // set denominator of equation {newReserve = constant k / denominator} where denominator is the new current amount of ETH, minus a 1% fee of amountIn
            denominator = currentEth - (ethDifference / 100);
            // resolver is the current reserve used to calculate amount of token to send based on a new reserve           
            resolver = _spaceCoinReserve;
            // used for Swap event
            amountSold = ethDifference;
        }
        // new reserve satisfying the constant k after the change in balance
        uint newReserve = k / denominator;
        // amount to transfer to the provided 'to' address
        uint amountToTransfer = resolver - newReserve;
        emit Swap(to, sellingCoin, amountSold, amountToTransfer);
        // determine what direction to swap is occuring in order to use the right send method
        if(sellingCoin) {
            // effects //
            //update reserves, based on current amount previously grabbed, and subtracting the amount to transfer before the transfer occurs
            spaceCoinReserve = uint128(currentSpaceCoin);
            ethReserve = uint128(currentEth - amountToTransfer);

            // interactions //
            // send eth to address
            (bool success,) = to.call{value : amountToTransfer}("");
            if(success == false) revert EthSwapFailed();

        } else {
            // effects //
            //update reserves, based on current amount previously grabbed, and subtracting the amount to transfer before the transfer occurs
            ethReserve = uint128(currentEth);
            /// @dev spaceCoin will transfer normally, so can update reserve before interactions without issue
            spaceCoinReserve = uint128(currentSpaceCoin - amountToTransfer);

            // interactions //
            // send spaceCoin to address
            spaceCoin.transfer(to, amountToTransfer);
        }
    }

    /// @dev Has no reentrancy guard because there is no external call, and all other functions follow the checks/effects/interactions pattern
    /// @notice Adds ETH-SPC liquidity to LP contract
    /// @param to The address that will receive the LP tokens
    function deposit(address to) external {
        // get the ETH Reserve, the contract's current ETH, the spaceCoin reserve, and the contract current spaceCoin into local memory
        (uint _ethReserve, uint currentEth, uint _spaceCoinReserve, uint currentSpaceCoin) = _getValues();
        // calculate the difference in current balance and reserves for both ETH and spaceCoin to determine how much of each was deposited
        uint ethDifference = currentEth - _ethReserve;
        uint spaceCoinDifference = currentSpaceCoin - _spaceCoinReserve;
        // both coins have to be deposited
        if(spaceCoinDifference == 0 || ethDifference == 0) revert NothingDeposited(); 
        // get lp token supply in memory
        uint LPTokenSupply = totalSupply();
        // amount of lp tokens to mint, yet to be calculated
        uint toMint;
        // check if this is an initial deposit into the pool, or and additional deposit
        if(LPTokenSupply == 0) {
            // initial deposit
            /// @dev could use the geometric mean here, but is an unnecessary calculation in this case, so will just mint lp tokens equal to the amount of eth sent
            toMint = ethDifference;
        } else {
            // calculate percent of the liquidity added to get the amount of lp tokens to mint
            uint mintFromEthDeposit = (ethDifference * LPTokenSupply) / _ethReserve;
            uint mintFromSpaceCoinDeposit = (spaceCoinDifference * LPTokenSupply) / _spaceCoinReserve;
            //choose the smallest amount of lp tokens to mint, any extra is considered a donation to the pool
            toMint = mintFromEthDeposit > mintFromSpaceCoinDeposit ? mintFromSpaceCoinDeposit : mintFromEthDeposit;
        }
        // mint lp tokens to provided address
        _mint(to, toMint);
        //update reserves to previously grabbed current balance
        ethReserve = uint128(currentEth);
        spaceCoinReserve = uint128(currentSpaceCoin);
        emit Deposited(msg.sender, ethDifference, spaceCoinDifference, toMint);
    }

    /// @dev Has no reentrancy guard because spaceCoin has no hooks
    /// @notice Returns ETH-SPC liquidity to liquidity provider
    /// @param to The address that will receive the outbound token pair
    function withdraw(address to) external {
        // checks //
        // get contracts balance of lp tokens, assume all sent here were owned by the passed in 'to' address
        uint contractLpBalance = this.balanceOf(address(this));
        // revert if there is no balance of l tokens in this contract
        if(contractLpBalance == 0) revert NothingToWithdraw();
        // store the total supply of lp tokens in memory, as it will be used multiple times
        uint LPTokenSupply = totalSupply();
        // burn the tokens in this contract
        _burn(address(this), contractLpBalance);
        // store the reserves in memory as they will be used multiple times
        uint _ethReserve = ethReserve;
        uint _spaceCoinReserve = spaceCoinReserve;
        // calculate how much eth and spaceCoin to withdraw based on amount of lp tokens burned
        uint amountEthToWithdraw = (contractLpBalance * _ethReserve) / LPTokenSupply;
        uint amountSpaceCoinToWithdraw = (contractLpBalance * _spaceCoinReserve) / LPTokenSupply;

        // effects //
        // update reserves, make sure to pull the actual balances in case someone donated funds to pool directly
        ethReserve = uint128(address(this).balance - amountEthToWithdraw);
        /// @dev spaceCoin will transfer normally, so can update reserve before interactions without issue
        spaceCoinReserve = uint128(spaceCoin.balanceOf(address(this)) - amountSpaceCoinToWithdraw);
        emit Withdrawn(to, amountEthToWithdraw, amountSpaceCoinToWithdraw, contractLpBalance);

        // interactions //
        // transfer spaceCoin to the address supplied
        /// @dev spaceCoin doesn't have any hooks so it is reentrancy safe
        spaceCoin.transfer(to, amountSpaceCoinToWithdraw);
        // transfer eth to address supplied
        /// @dev this occurs last, after all effects have occured, so is reentrancy safe
        (bool success, ) = to.call{value : amountEthToWithdraw}("");
        if(success == false) revert EthWithdrawalFailed();
    }

    /// @dev retrieve ethReserve, the current ETH balance, spaceCoinReserve, and the current spaceCoin balance
    function _getValues() internal view returns(uint, uint, uint, uint) {
        return(ethReserve, address(this).balance, spaceCoinReserve, spaceCoin.balanceOf(address(this)));
    }
    
    /// @notice sync the pool's reserves to its current balance in the case it is unsynced
    function sync() external {
        ethReserve = uint128(address(this).balance);
        spaceCoinReserve = uint128(spaceCoin.balanceOf(address(this)));
    }

    /// @dev allows the retrieval of both reserve values from a single external call, useful for the router
    /// @notice returns both eth and spaceCoin reserves
    function getReserves() external view returns(uint, uint) {
        return(ethReserve, spaceCoinReserve);
    }

    /// @dev Allows anyone to send eth to the contract, including the router for depositing liquidity
    receive() payable external {}

    // Events //
    event Deposited(address indexed depositor, uint ethDeposited, uint spaceCoinDeposited, uint lpTokensMinted);
    event Withdrawn(address indexed withdrawer, uint ethWithdrawn, uint spacecoinWithdrawn, uint lpTokensBurned);
    event Swap(address indexed swapper, bool indexed coinSold, uint amountSold, uint amountRecieved);

    // Errors //
    error NothingDeposited();
    error NothingToWithdraw();
    error NothingToSwap();
    error EthWithdrawalFailed();
    error EthSwapFailed();
    error OutOfSync();
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract SpaceCoin is ERC20 {

    uint public constant TAXPERCENT = 2;

    address immutable public treasury;
    address immutable public owner;

    bool public toTax;

    modifier onlyOwner {

        if(msg.sender != owner) revert NotOwner();
        _;

    }
   
    constructor(address _treasury) ERC20("SpaceCoin", "SPACE") {

        treasury = _treasury;
        owner = msg.sender;

        _mint(_treasury, 500000 ether);

    }


    /// ERC20 Overridden functions
    function transfer(address to, uint256 amount) public override returns (bool) {

        handleTransfer(_msgSender(), to, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        handleTransfer(from, to, amount);
        return true;
    }

    /// @dev handles taxation if it is set
    function handleTransfer(address from, address to, uint256 amount) internal {

        if(toTax) {

            uint taxAmount = (amount * TAXPERCENT) / 100;

            _transfer(from, treasury, taxAmount);

            amount -= taxAmount;

        }

        _transfer(from, to, amount);

    }

    function toggleToTax() external onlyOwner {

        // store a local variable in memory to save gas as multiple SLOAD would be called otherwise
        bool tax = !toTax;

        toTax = tax;

        emit TaxChanged(tax);

    }


    /// Events ///
    event TaxChanged(bool value);

    /// ERRORS ///

    error NotOwner();

    
    
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

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