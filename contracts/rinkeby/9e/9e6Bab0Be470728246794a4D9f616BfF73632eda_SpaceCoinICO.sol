// SPDX-License-Identifier: MIT
pragma solidity >=0.8.8;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./SPCRouter.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
/*
The smart contract aims to raise 30,000 Ether by performing an ICO.
The ICO should only be available to whitelisted private investors
starting in Phase Seed with a maximum total private contribution limit of 15,000 Ether
and an individual contribution limit of 1,500 Ether.
The ICO should become available to the general public during Phase General,
with a total contribution limit equal to 30,000 Ether,
inclusive of funds raised from the private phase. During this phase,
the individual contribution limit should be 1,000 Ether,until Phase Open,
at which point the individual contribution limit should be removed.
At that point, the ICO contract should immediately release ERC20-compatible tokens for all contributors
at an exchange rate of 5 tokens to 1 Ether. The owner of the contract
should have the ability to pause and resume fundraising at any time,
as well as move a phase forwards (but not backwards) at will.
*/

contract SpaceCoinICO is Ownable {
    // SafeERC20 throws if something unexpected happens in ERC20 functions
    using SafeERC20 for IERC20;

    // ICO ETH target
    uint256 public constant TARGET_ETH = 30_000 ether;
    // Seed round target
    uint256 public constant SEED_TARGET_ETH = 15_000 ether;
    // Amount a single whitelisted account can contribute in Seed round
    uint256 public constant SEED_CONT_AMOUNT_ETH = 1_500 ether;
    // Amount a single account can contribute in General round
    uint256 public constant GENERAL_CONT_AMOUNT_ETH = 1_000 ether;
    // ETH to SPC ratio that will be payed out
    uint256 public constant ETH_TO_SPC = 5;

  
    // Contract address of the token that will be offered in ICO
    address public tokenAddress;
    // Total raised ETH amount
    uint256 public totalRaised;
    // Total withdrawn from the contract
    uint256 public totalWithdrawn;
    // Current state of the ICO
    State public state;
    // Flag shows if the fundraising is paused
    bool public isPaused;

    // Mapping of the contributer addresses to ETH amounts they contributed
    mapping(address => uint256) public addressToETHcontributed;
    // Mapping of the contributer addresses to SPC amounts they alread claimed
    mapping(address => uint256) public addressToClaimedSPC;
    // Mapping of the whitelisted addresses
    mapping(address => bool) public whitelistedAddresses;

    // Enum for ICO state
    enum State {
        SEED,
        GENERAL,
        OPEN
    }

    // Modifier that can be applied to functions to check if the ICO is in certain state
    modifier inState(State _state) {
        require(state == _state, "WRONG_STATE");
        _;
    }

    // Functions marked by this modifier can not be called if the fundraising is paused
    modifier isLive() {
        require(!isPaused, "PAUSED");
        _;
    }

    // Event fired with every ICO state change
    event StateChanged(State _state);
    // Event fired when an account added or removed to whitelist
    event WhiteListToggle(address _address, bool _whitelisted);
    // Event fired when a contribution is received
    event ContributionReceived(address indexed _buyer, uint256 _amount, State _state);
    // Event fired when tokens are claimed by a user
    event TokenClaimed(address indexed _buyer, uint256 _amount);
    // Event fired when the owner supplied luqidity to the pool
    event LiquiditySupplied(uint256 _amountSPC, uint256 _amountETH, uint256 _liq);

    constructor() {
    }

    // Seed round buy function
    // Can be called by whitelisted accounts
    // Max total amount: 15_000 ETH
    // Max individual amount: 1_500 ETH
    function buySeed() external payable inState(State.SEED) isLive {
        require(whitelistedAddresses[msg.sender], "NOT_WHITELISTED");
        require(totalRaised + msg.value <= SEED_TARGET_ETH, "SEED_TARGET_EXC");
        require(addressToETHcontributed[msg.sender] + msg.value <= SEED_CONT_AMOUNT_ETH, "IND_SEED_TARGET_EXC");

        addressToETHcontributed[msg.sender] += msg.value;
        totalRaised += msg.value;

        emit ContributionReceived(msg.sender, msg.value, state);
    }

    // General round buy function
    // Can be called by all accounts
    // Max total amount: 30_000 ETH
    // Max individual amount: 1_000 ETH
    function buyGeneral() external payable inState(State.GENERAL) isLive {
        require(totalRaised + msg.value <= TARGET_ETH, "TARGET_EXC");
        require(addressToETHcontributed[msg.sender] + msg.value <= GENERAL_CONT_AMOUNT_ETH, "IND_GENERAL_TARGET_EXC");

        addressToETHcontributed[msg.sender] += msg.value;
        totalRaised += msg.value;

        emit ContributionReceived(msg.sender, msg.value, state);
    }

    // Open round buy function
    // Can be called by all accounts
    // Max total amount: 30_000 ETH
    // Max individual amount: No limits
    function buyOpen() external payable inState(State.OPEN) isLive {
        require(totalRaised + msg.value <= TARGET_ETH, "TARGET_EXC");

        addressToETHcontributed[msg.sender] += msg.value;
        totalRaised += msg.value;

        emit ContributionReceived(msg.sender, msg.value, state);
    }

    // Users can call to claim their SPC balance
    // Pays 5 SPC for each ETH deposited earlier
    // If the transer tax is active the amount received will be lower
    function claimSPC() external inState(State.OPEN) isLive {
        uint256 toBeSended = (addressToETHcontributed[msg.sender] * ETH_TO_SPC) - addressToClaimedSPC[msg.sender];
        require(toBeSended > 0, "NOTHING_TO_CLAIM");

        addressToClaimedSPC[msg.sender] += toBeSended;

        emit TokenClaimed(msg.sender, toBeSended);
        bool success = ERC20(tokenAddress).transfer(msg.sender, toBeSended);
        require(success, "TRANSFER_FAILED");
    }

    // Changes ICO step
    // Only owner can call
    function nextStep(State _next) external onlyOwner {
        if (state == State.SEED) {
            require(_next == State.GENERAL, "WRONG_STATE");
            state = State.GENERAL;
            emit StateChanged(state);
        } else if (state == State.GENERAL) {
            require(_next == State.OPEN, "WRONG_STATE");
            state = State.OPEN;
            emit StateChanged(state);
        }
    }

    // Toggels whitelist status of an account
    // Only owner can call
    function toggleWL(address _address) external onlyOwner {
        whitelistedAddresses[_address] = !whitelistedAddresses[_address];
        emit WhiteListToggle(_address, whitelistedAddresses[_address]);
    }

    // Pauses the fundraising
    // Only owner can call
    function togglePause() external onlyOwner {
        isPaused = !isPaused;
    }

    // Sets the contract address of the token sold in ICO
    // Only owner can call
    function setTokenAddress(address _tokenAddress) external onlyOwner {
        tokenAddress = _tokenAddress;
    }

    // Supply liquidity pool with SPC & ETH tokens
    // Only owner can call
    function supplyLP(uint256 _ethAmount, address payable _routerContract) external onlyOwner {
        require((totalRaised - totalWithdrawn) >= _ethAmount, "WRONG_AMOUNT");
        totalWithdrawn += _ethAmount;

        uint256 spcAmount = _ethAmount * ETH_TO_SPC;
        // approve router to transfer SPC
        bool success = ERC20(tokenAddress).approve(_routerContract, spcAmount);
        require(success, "TOKEN_APPROVE_FAILED");

        (uint256 amountSPC, uint256 amountETH, uint256 liquidity) = SPCRouter(_routerContract).addLiquidity{
            value: _ethAmount
        }(spcAmount, msg.sender);

        emit LiquiditySupplied(amountSPC, amountETH, liquidity);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.8;

import "./SPCxETHPool.sol";
import "./SpaceCoin.sol";
import "./SPCLib.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
contract SPCRouter is Ownable {
    // SPC token contract
    SpaceCoin public immutable tokenContract;
    // Pool contract for SPCxETH Pair
    SPCxETHPool public immutable poolContract;

    // -------------- Used By re-entrancy lock----------
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;

    //--------------------------------------------------
    event Received(address _sender, uint256 _amount);

    constructor(address _spcAddress) {
        _status = _NOT_ENTERED;
        tokenContract = SpaceCoin(_spcAddress);
        poolContract = new SPCxETHPool(_spcAddress);
    }

    // Adds liquidity to the pool
    // _amountSPC: SPC count that is send by the liquidity provider
    // _to: Address of the account LP tokens will be sent
    // The function is payable and ETH amount should be supplied as 'value'
    function addLiquidity(uint256 _amountSPC, address _to)
        external
        payable
        nonReentrant
        returns (
            uint256 finalAmountSPC,
            uint256 finalAmountETH,
            uint256 liquidity
        )
    {
        uint256 _amountETH = msg.value;
        // Get both current reserves from pool
        (uint256 reserveSPC, uint256 reserveETH) = poolContract.getReserves();

        if (reserveSPC == 0 && reserveETH == 0) {
            // if it is the initial supply amounts to be deposited should be exactly the same as
            // those the liquidity provider wants to provide.
            (finalAmountSPC, finalAmountETH) = (_amountSPC, _amountETH);
        } else {
            // calculate optimal amount of ETH using quote function
            // this is done to keep the pool in equilibrium
            uint256 optimalAmountETH = SPCLib.quote(_amountSPC, reserveSPC, reserveETH);
            if (optimalAmountETH <= _amountETH) {
                // if supplied ETH amount is bigger than optimal amount
                // don't use all ETH supplied
                (finalAmountSPC, finalAmountETH) = (_amountSPC, optimalAmountETH);
            } else {
                uint256 optimalAmountSPC = SPCLib.quote(_amountETH, reserveETH, reserveSPC);
                // if supplied ETH amount is lower than optimal amount
                // this means supplied SPC amount should be higher than optimal SPC amount
                assert(optimalAmountSPC <= _amountSPC);
                // in this case don't use all SPCs suplied
                (finalAmountSPC, finalAmountETH) = (optimalAmountSPC, _amountETH);
            }
        }
        // send calculated SPC and ETH amounts to pool
        SPCLib.safeTransferFrom(address(tokenContract), msg.sender, address(poolContract), finalAmountSPC);
        SPCLib.safeTransferETH(address(poolContract), finalAmountETH);
        // mint liquidity tokens to the liquidity supplier
        liquidity = poolContract.mint(_to);
        // if supplied ETH amount is bigger than final amount, refund the diff because it is not sent to the pool
        if (_amountETH > finalAmountETH) SPCLib.safeTransferETH(msg.sender, _amountETH - finalAmountETH);
    }

    // Removes liquidity from pool
    // _liquidity: amount of LP tokens that will be burned
    // _to: address that will receive removed liquidity
    function removeLiquidity(uint256 _liquidity, address _to)
        external
        nonReentrant
        returns (uint256 _amountSPC, uint256 _amountETH)
    {
        // transfer LP tokens to the pool contract
        SPCLib.safeTransferFrom(address(poolContract), msg.sender, address(poolContract), _liquidity);

        // call burn to burn LP tokens and get the amount which will be sent to the liquidity provider
        (_amountSPC, _amountETH) = poolContract.burn(_to);
    }

    // Swaps ETH for SPC
    // _amountOutMin: min amount of SPC accepted by the trader (slippage protection)
    // _to: address the SPCs will be sent
    // The function is payable and ETH amount should be supplied as 'value'
    // returns the final amount that is payed after swap
    function swapETHForSPC(uint256 _amountOutMin, address _to)
        external
        payable
        nonReentrant
        returns (uint256 _amountOut)
    {
        // current SPC balance of the trader
        uint256 senderBalanceSPC = tokenContract.balanceOf(msg.sender);
        // get current reserves from the pool
        (uint256 _reserveSPC, uint256 _reserveETH) = poolContract.getReserves();

        // transfer ETH to the pool
        SPCLib.safeTransferETH(address(poolContract), msg.value);

        // amountIn is used to calculate how much ETH received by the pool contract
        // instead of msg.value because sent amount will be slightly different than received(fee)
        uint256 amountIn = poolContract.balanceETH() - _reserveETH;
        // amount out is calculated using constant product formula and 1% fee
        uint256 amountOut = SPCLib.getAmountOut(amountIn, _reserveETH, _reserveSPC);

        // perform the swap
        poolContract.swap(amountOut, 0, _to);

        // take the difference of initial and final balanaces to get the final amount received by trader
        // we are calculating this seperately to avoid gettin wrong results because of tax
        // the user is calling the function with min amount they are willing to receive
        // it seems fair to calculate the exact amount they will receive
        // and revert if it is lower than what they initially aggreed
        // (although transer tax is not taken by LP)
        _amountOut = tokenContract.balanceOf(_to) - senderBalanceSPC;

        // if the slippage is higher than what the user is willing to pay revert swap
        require(_amountOut >= _amountOutMin, "SPCRouter: SLIPPAGE_TOO_HIGH");
    }

    // Swaps SPC for ETH
    // _amountIn: SPC amount sent by trader
    // _amountOutMin: min amount of ETH accepted by the trader (slippage protection)
    // _to: address the ETHs will be sent
    // returns the final amount that is payed after swap
    function swapSPCForETH(
        uint256 _amountIn,
        uint256 _amountOutMin,
        address _to
    ) external nonReentrant returns (uint256 _amountOut) {
        // current ETH balance of the trader
        uint256 senderBalanceETH = _to.balance;
        // get current reserves from the pool
        (uint256 _reserveSPC, uint256 _reserveETH) = poolContract.getReserves();

        // transfer SPC to the Pool
        SPCLib.safeTransferFrom(address(tokenContract), msg.sender, address(poolContract), _amountIn);

        // amountIn is used to calculate how much SPC received by the pool contract
        // instead of _amountIn because sent amount might be different than received when transfer tax applied
        uint256 amountIn = tokenContract.balanceOf(address(poolContract)) - _reserveSPC;
        // amount out is calculated using constant product formula and 1% fee
        uint256 amountOut = SPCLib.getAmountOut(amountIn, _reserveSPC, _reserveETH);

        // perform the swap
        poolContract.swap(0, amountOut, _to);

        // take the difference of initial and final balanaces to get the final amount sent
        // instead of amountOut we are calculating this seperately to avoid gettin wrong results
        _amountOut = _to.balance - senderBalanceETH;
        require(_amountOut >= _amountOutMin, "SPCRouter: SLIPPAGE_TOO_HIGH");
    }

    // OZ ReentrancyGuard implementation
    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.8;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./SpaceCoin.sol";
import "./SPCRouter.sol";
import "./SPCLib.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SPCxETHPool is ERC20, Ownable {
    // SPC token contract
    SpaceCoin public immutable tokenContract;
    // SPC router contract
    SPCRouter public immutable routerContract;

    // reserve SPC amount
    uint256 public reserveSPC;
    // reserve ETH amount
    uint256 public reserveETH;
    // contract ETH balance
    uint256 public balanceETH;

    // min liq that will be locked
    uint256 public constant MINIMUM_LIQUIDITY = 10**3;
    // ONE address will used to lock MINIMUM_LIQUIDITY
    // minting to zero address is bloced by OZ ERC20
    address private constant ONE_ADDRESS = 0x0000000000000000000000000000000000000001;

    // -------------- Used By re-entrancy lock----------
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;
    //---------------------------------------------------

    event Mint(address indexed _sender, uint256 _amountSPC, uint256 _amountETH, address _to);
    event Burn(address indexed _sender, uint256 _amountSPC, uint256 _amountETH, address _to);
    event Swap(
        address indexed _sender,
        uint256 _amountSPCIn,
        uint256 _amountETHIn,
        uint256 _amountSPCOut,
        uint256 _amountETHOut,
        address indexed _to
    );
    event Received(address _sender, uint256 _amount);

    constructor(address _spcAddress) ERC20("SPCxETH-LP", "SPCxETH") {
        tokenContract = SpaceCoin(_spcAddress);
        routerContract = SPCRouter(payable(address(msg.sender)));
        _status = _NOT_ENTERED;
    }

    // Mints LP tokens to the liquidity provider
    // _to: address the tokens will be minted
    // can be only called by router contract
    // returns the amount of lp tokens minted
    function mint(address _to) external onlyRouter nonReentrant returns (uint256 liquidity) {
        // current SPC balance of the pool contract
        uint256 balanceSPC = tokenContract.balanceOf(address(this));
        // SPC amount sent to the pool by the provider
        uint256 amountSPC = balanceSPC - reserveSPC;
        // ETH amount sent to the pool by the provider
        uint256 amountETH = balanceETH - reserveETH;
        // total supply of the LP tokens
        uint256 _totalSupply = totalSupply();

        if (_totalSupply == 0) {
            // In the time of the first deposit we don't know the relative value of the two tokens,
            // so we just multiply the amounts and take a square root,
            // assuming that the deposit provides us with equal value in both tokens.
            liquidity = SPCLib.sqrt(amountSPC * amountETH) - MINIMUM_LIQUIDITY;
            // Using ONE address to lock tokens. ERC20 does not allow minting to ZERO address
            _mint(ONE_ADDRESS, MINIMUM_LIQUIDITY);
        } else {
            // With every subsequent deposit we already know the exchange rate between the two assets,
            // and we expect liquidity providers to provide equal value in both.
            // If they don't, we give them liquidity tokens based on the lesser value they provided as a punishment.
            liquidity = SPCLib.min((amountSPC * _totalSupply) / reserveSPC, (amountETH * _totalSupply) / reserveETH);
        }

        require(liquidity > 0, "SPCxETHPool: LOW_LIQUIDITY");

        // mint correct amount of LP tokens to the lp provider
        _mint(_to, liquidity);

        // force reserves to be equal to be balances
        _syncReserves(balanceSPC, balanceETH);

        emit Mint(msg.sender, amountSPC, amountETH, _to);
    }

    // Burns LP tokens and transfer liquidity back to the owner
    // can be only called by router contract
    // returns the amount of SPC and ETH that will be transfered
    function burn(address _to) external onlyRouter nonReentrant returns (uint256 _amountSPC, uint256 _amountETH) {
        // current SPC balance of the pool contract
        uint256 balanceSPC = tokenContract.balanceOf(address(this));
        // LP token amount sent to the pool by the provider
        uint256 liquidity = balanceOf(address(this));
        // Total supply of the LP tokens
        uint256 totalSupply = totalSupply();

        // SPC share of the user, proportional to the supplied LP tokens
        _amountSPC = (liquidity * balanceSPC) / totalSupply;
        // ETH share of the user, proportional to the supplied LP tokens
        _amountETH = (liquidity * balanceETH) / totalSupply;

        require(_amountSPC > 0 && _amountETH > 0, "SPCxETHPool: INSUFFICIANT_LIQ_BURNED");

        // burn LP tokens currently in the pools custody
        _burn(address(this), liquidity);

        // transfer SPC amount to the liq provider
        SPCLib.safeTransfer(address(tokenContract), _to, _amountSPC);
        // transfer ETH amount to the liq provider
        SPCLib.safeTransferETH(_to, _amountETH);

        // reduce balanceETH to match current balance
        balanceETH -= _amountETH;
        balanceSPC = tokenContract.balanceOf(address(this));

        // force reserves to be equal to be balances
        _syncReserves(balanceSPC, balanceETH);

        emit Burn(msg.sender, _amountSPC, _amountETH, _to);
    }

    // makes swap, returns requested amounts
    // _amountSPCOut: calculated SPC amount
    // _amountETHOut: calculated ETH amount
    // _to: address the amounts will be sent
    function swap(
        uint256 _amountSPCOut,
        uint256 _amountETHOut,
        address _to
    ) external nonReentrant onlyRouter {
        require(_amountSPCOut > 0 || _amountETHOut > 0, "SPCxETHPool: INSUFFICIENT_OUTPUT_AMOUNT");
        (uint256 _reserveSPC, uint256 _reserveETH) = getReserves();
        require(_amountSPCOut < _reserveSPC && _amountETHOut < _reserveETH, "SPCxETHPool: INSUFFICIENT_LIQUIDITY");

        uint256 poolBalanceSPC;
        uint256 poolBalanceETH;
        {
            require(_to != address(tokenContract), "SPCxETHPool: INVALID_TO");
            // These transfers are optimistic, because we transfer before we are sure all the conditions are met.
            // This is OK in Ethereum because if the conditions aren't met later in the call we revert out of it.
            if (_amountSPCOut > 0) SPCLib.safeTransfer(address(tokenContract), _to, _amountSPCOut);
            if (_amountETHOut > 0) {
                SPCLib.safeTransferETH(_to, _amountETHOut);
                balanceETH -= _amountETHOut;
            }

            // save latest SPC and ETH balances of the pool
            poolBalanceSPC = tokenContract.balanceOf(address(this));
            poolBalanceETH = balanceETH;
        }

        // calculate amounts received in the contract
        uint256 amountSPCIn = poolBalanceSPC > _reserveSPC - _amountSPCOut
            ? poolBalanceSPC - (_reserveSPC - _amountSPCOut)
            : 0;
        uint256 amountETHIn = poolBalanceETH > _reserveETH - _amountETHOut
            ? poolBalanceETH - (_reserveETH - _amountETHOut)
            : 0;
        require(amountSPCIn > 0 || amountETHIn > 0, "SPCxETHPool: INSUFFICIENT_INPUT_AMOUNT");

        {
            uint256 balanceSPCAdjusted = poolBalanceSPC * 100 - amountSPCIn;
            uint256 balanceETHAdjusted = poolBalanceETH * 100 - amountETHIn;
            // This is a sanity check that assures the pool is not cheaten and does not lose anything from the swap
            // If balanceSPC * balanceETH is less than reserveSPC * reserveETH + FEEs
            // there is something wrong and swap should be reverted
            require(balanceSPCAdjusted * balanceETHAdjusted >= _reserveSPC * _reserveETH * 100**2, "SPCxETHPool: K");
        }

        // force sync reserves
        _syncReserves(poolBalanceSPC, poolBalanceETH);
        emit Swap(msg.sender, amountSPCIn, amountETHIn, _amountSPCOut, _amountETHOut, _to);
    }

    // gets two reserve values
    function getReserves() public view returns (uint256, uint256) {
        return (reserveSPC, reserveETH);
    }

    // should be called every time tokens are deposited or withdrawn to keep reserves and balances in sync
    function _syncReserves(uint256 _balanceSPC, uint256 _balanceETH) private {
        reserveSPC = _balanceSPC;
        reserveETH = _balanceETH;
    }

    // OZ ReentrancyGuard implementation
    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }

    modifier onlyRouter() {
        require(msg.sender == address(routerContract), "SPCxETHPool: ONLY_ROUTER");
        _;
    }

    // only router contract can transfer ETH to the Pool
    // this protects balance manipulation
    receive() external payable onlyRouter {
        balanceETH += msg.value;
        emit Received(msg.sender, msg.value);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.8;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
/*
ERC-20 SpaceCoin(SPC) implementation
500,000 max total supply
A 2% tax on every transfer that gets put into a treasury account
A flag that toggles this tax on/off, controllable by owner, initialized to false
*/
contract SpaceCoin is ERC20, Ownable{
    // Max total supply that can ever be minted
    uint256 public constant MAX_TOTAL_SUPPLY = 500_000 ether;

    // Tax rate will be deducted from from transfers and kept in the treasury account
    uint256 public constant TAX_RATE = 2;

    
    // Address of the ICO contract
    address public immutable icoAddress;
    // Address of the Treasury account
    address public immutable treasury;

    // Flag that indicats if the tax is applied to transfer
    bool public taxEnabled;


    // Inits the state and mints 150_000 tokens to the ICO contract
    constructor(address _icoAddress, address _treasury) ERC20("SpaceCoin", "SPC") {
        taxEnabled = false;
        icoAddress = _icoAddress;
        treasury = _treasury;
        _mint(icoAddress, MAX_TOTAL_SUPPLY);
    }

    // Toggles transfer tax
    // Only owner can call
    function toggleTax() external onlyOwner {
        taxEnabled = !taxEnabled;
    }

    // Overrides ERC20 transfer function to apply tax logic
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual override {
        if (taxEnabled) {
            uint256 tax = (amount * TAX_RATE) / 100;
            amount -= tax;
            super._transfer(sender, treasury, tax);
        }
        super._transfer(sender, recipient, amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.8;

// Lib methods are mostly taken from Uniswap-v2 //
library SPCLib {
    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "SPCLib: safeTransfer: transfer failed");
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "SPCLib: transferFrom: transferFrom failed");
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{ value: value }(new bytes(0));
        require(success, "SPCLib: safeTransferETH: ETH transfer failed");
    }

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountOut) {
        require(amountIn > 0, "SPCLib: INSUFFICIENT_INPUT_AMOUNT");
        require(reserveIn > 0 && reserveOut > 0, "SPCLib: INSUFFICIENT_LIQUIDITY");
        uint256 amountInWithFee = amountIn * 99;
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = reserveIn * 100 + amountInWithFee;
        amountOut = numerator / denominator;
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) internal pure returns (uint256 amountB) {
        require(amountA > 0, "SPC_LIB: INSUFFICIENT_AMOUNT");
        require(reserveA > 0 && reserveB > 0, "SPC_LIB: INSUFFICIENT_LIQUIDITY");
        amountB = (amountA * (reserveB)) / reserveA;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }
}