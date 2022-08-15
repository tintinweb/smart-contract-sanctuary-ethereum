// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./libraries/Math.sol";
import "./SpaceCoin.sol";
import "./Errors.sol";

contract SpacePool is ERC20 {
    /// @notice amount fee to take
    uint8 public constant FEE = 1;

    /// @notice the reserve amount of eth
    uint256 public reserveEth;

    /// @notice the reserve amount of spc
    uint256 public reserveSPC;

    /// @notice the spaceCoin contract
    SpaceCoin spaceCoin;

    event Minted(address indexed minter, uint256 amount);
    event Burned(address indexed burner, uint256 amount);
    event Swapped(address indexed swapper, uint256 amountIn, uint256 amountOut);
    constructor(address _spaceCoin) ERC20("Space LP Token", "SPC-LP") {
        spaceCoin = SpaceCoin(_spaceCoin);
    }
    /**
     * @notice function to mint LP tokens given some eth and Spc amount.
     * @dev msg.value is what will be used as the eth amount to deposit
     * @param to address to mint to
     * @return amountToMint the amount of LP tokens minted
     */
    function mint(address to) external payable returns (uint256 amountToMint){
        uint256 spcAmount = spaceCoin.balanceOf(address(this)) - reserveSPC;
        if (spcAmount <= 0 || msg.value <= 0) revert InvalidAmounts(msg.value, spcAmount);
        if (totalSupply() == 0) {
            amountToMint = Math.sqrt(spcAmount * msg.value);
        } else {
            amountToMint = Math.min((totalSupply() * spcAmount) / reserveSPC, (totalSupply() * msg.value) / reserveEth);
        }
        reserveSPC += spcAmount;
        reserveEth += msg.value;
        _mint(to, amountToMint);

        emit Minted(to, amountToMint);
    }

    /**
     * @notice Burns whatever amount of SPC-LP tokens in this contract
     *  and returns eth and spc proportional to the LP share
     * @param to address to return eth and spc to
     */
    function burn(address to) external returns (uint256 spaceAmountToRefund, uint256 ethAmountToRefund) {
        uint256 amountToBurn = balanceOf(address(this));
        if (amountToBurn == 0) revert InvalidAmount(amountToBurn);

        spaceAmountToRefund = (reserveSPC * amountToBurn) / totalSupply();
        ethAmountToRefund = (reserveEth * amountToBurn) / totalSupply();

        reserveSPC -= spaceAmountToRefund;
        reserveEth -= ethAmountToRefund;
        _burn(address(this), amountToBurn);

        if(!spaceCoin.transfer(to, spaceAmountToRefund))
            revert TransferFailed();

        (bool success, ) = to.call{ value: ethAmountToRefund}(""); // TODO add an error handler
        if (!success) revert TransferFailed();

        emit Burned(to, amountToBurn);
    }

    /**
     * @notice swaps Eth for SPC, this function is payable
     * @param to address that is doing the swap
     * @param minSpc minimum amount of spc expected (used for slippage)
     */
    function swapEthForSpc(address to, uint256 minSpc) external payable {
        /// @dev amountIn expects eth to be transferred in already.
        uint256 amountIn = address(this).balance - reserveEth; 
        if (amountIn <= 0) revert InvalidAmount(amountIn);

        uint256 spaceAmountOut = getOutputAmount(amountIn, reserveEth, reserveSPC, FEE);
        if (spaceAmountOut < minSpc) revert InsufficientTokenAmounts(minSpc, spaceAmountOut);

        reserveEth += amountIn;
        reserveSPC -= spaceAmountOut;

        if(!spaceCoin.transfer(to, spaceAmountOut))
            revert TransferFailed();

        emit Swapped(to, amountIn, spaceAmountOut);
    }

    /**
     * @notice swaps SPC for Eth
     * @param to address that is doing the swap
     * @param minEth minimum amount of eth expected (used for slippage)
     * @dev expects to transfer the spc in first before running this function
     */
    function swapSpcForEth(address to, uint256 minEth) external returns (uint256 ethAmountOut){
        /// @dev amountIn expects SPC to be transferred in already.
        uint256 amountIn = spaceCoin.balanceOf(address(this)) - reserveSPC; 
        if (amountIn <= 0) revert InvalidAmount(amountIn);

        ethAmountOut = getOutputAmount(amountIn, reserveSPC, reserveEth, FEE);
        if (ethAmountOut < minEth) revert InsufficientTokenAmounts(minEth, ethAmountOut);

        reserveSPC += amountIn;
        reserveEth -= ethAmountOut;

        (bool success, ) = to.call{ value: ethAmountOut }("");
        if (!success) revert TransferFailed();

        emit Swapped(to, amountIn, ethAmountOut);
    }

    
    /**
     * @notice Helper function that returns the output token amount given an input token amount minus fee
     * 
     * Generally, this formula tells you how much of the other token you would receive given the input
     *
     * Based off of k = xy = (inputAmount + inputAmountDelta)(outputAmount - outputAmountDelta)
     * which can be derived as (outputAmount * inputAmountDelta) / (inputAmount + inputAmountDelta) = outputAmountDelta
     *
     * As a feature of constant product forumla, the higher the reserves liquidity, the closer to the actual output
     */
    function getOutputAmount(
        uint256 inputAmount,
        uint256 inputReserve,
        uint256 outputReserve,
        uint256 fee
    ) public pure returns (uint256) {
        uint256 inputAmountWithFee = inputAmount * (100 - fee);
        return (inputAmountWithFee * outputReserve) / (inputReserve * 100 + inputAmountWithFee);        
    }
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

pragma solidity ^0.8.9;


// a library for performing various math operations

library Math {
    function min(uint x, uint y) internal pure returns (uint z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./Errors.sol";

contract SpaceCoin is ERC20 {
    /// @notice The owner of this contract. Allows certain rights during ICO process
    address private immutable owner;

    /// @notice The address of the SPCE minter. Only this address can run mint(). 
    /// @dev Expected to be SpaceCoinICO contract
    address private immutable minter;

    /// @notice The treasury address. Used to deposit tax (if enabled)
    address public immutable treasury;

    /// @notice Max supply of SpaceCoin mintable
    uint256 public immutable maxSupply;

    /// @notice Percentage amount to tax
    uint8 public transferTaxPercentage = 0;

    modifier onlyOwner {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    modifier onlyMinter {
        if (msg.sender != minter) revert NotMinter();
        _;
    }

    event Contributed();
    event Minted();
    event TransferTaxChanged(uint8 percentage);
    event TransferTaxApplied(uint256 amount);

    constructor(address _owner, address _treasury, address _minter, uint256 _maxSupply) ERC20("SpaceCoin", "SPCE") { // TODO Will hardcode the name for now but changable later
        // TODO add address(0) checks
        owner = _owner;
        treasury = _treasury;
        minter = _minter;
        maxSupply = _maxSupply;
    }

    /**
     * @notice mints a new amount of tokens to an address
     * @param to address to mint to
     * @param amount amount to mint    
     */
    function mint(address to, uint256 amount) external onlyMinter {
        if((totalSupply() + amount > maxSupply)) revert MaxTokensMinted();
        _mint(to, amount);
        emit Minted();
    }

    /**
     * @notice Toggles the transferTaxPercentage between 0 and 2
     */
    function toggleTransferTax() external onlyOwner {
        transferTaxPercentage = transferTaxPercentage == 0 ? 2 : 0; // TODO  2% is hardcoded but potentially allow this be to changeable
        emit TransferTaxChanged(transferTaxPercentage);
    }

    /**
     * @notice Overrides the ERC20._afterTokenTransfer hook to filter for transfers
     * @param from tranferring from address
     * @param to transfer to address
     * @param amount amount to transfer
     * @dev As best practice, leave as internal virtual. Also, see https://docs.openzeppelin.com/contracts/3.x/extending-contracts#using-hooks
     */
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        /// @dev Done as best practice according to OZ. Does not do anything.
        super._afterTokenTransfer(from, to, amount);

        if (_isTokenTransfer(from, to, amount)) {
            if (transferTaxPercentage > 0) {
                _transferToTreasury(to, amount);
            }
        }
    }

    /**
     * @notice Helper function to determine if transfer. Excludes incoming treasury transfers 
     * @param from tranferring from address
     * @param to transfer to address
     * @param amount amount to transfer
     * @dev see openzeppelin docs
     */
    function _isTokenTransfer(address from, address to, uint256 amount) private view returns (bool) {
        return 
            from != address(0) && 
            to != address(0) && 
            to != treasury && // Excludes incoming treasury transfers 
            from != treasury && // Excludes outgoing treasury transfers 
            amount > 0;
    }

    /**
     * @notice Helper function to transfer an amount from an address to treasury
     * @param from transfer from address
     * @param amount amout to transfer
     * @dev see openzeppelin docs
     */
    function _transferToTreasury(address from, uint256 amount) private {
        uint256 amountForTreasury = amount * transferTaxPercentage / 100;
        _transfer(from, treasury, amountForTreasury);
        emit TransferTaxApplied(amount);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

error AddressAlreadySet();
error AddressZero();
error IndividualLimitHit();
error InvalidAmounts(uint256 ethAmount, uint256 spceAmount);
error InvalidAmount(uint256 amount);
error InsufficientTokenAmounts(uint256 expectedAmount, uint256 actualAmount);
error KHasBeenViolated(uint256 ethAmount, uint256 spceAmount);
error MaxTokensMinted();
error MaxPhaseReached();
error NothingToClaim();
error NotMinter();
error NotOwner();
error NotTreasury();
error NotEnoughTokens();
error NotWhitelisted();
error NotReadyToBeClaimed();
error OfferingPaused();
error PhaseLimitHit();
error TransferFailed();
error WrongPhase(uint8 current, uint8 lookingFor);

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