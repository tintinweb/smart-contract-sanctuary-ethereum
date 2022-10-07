//SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.9;

import "./SpaceLP.sol";
import "./SpaceCoin.sol";

error SpaceRouter__ZeroLiquidityAddNotAllowed();
error SpaceRouter__EthTransferFailed();
error SpaceRouter__MinimumSPCOutMustBeGreaterThanZero();
error SpaceRouter__MinimumSpcInAndEthOutMustBeProvided();
error SpaceRouter__ExceedsLPTokensOwned();
error SpaceRouter__InsufficientSPCBalanceToSwap();
error SpaceRouter__SwapResultsInLessThanMinimumRequestedEth();
error SpaceRouter__SwapResultsInLessThanMinimumRequestedSPC();
error SpaceRouter__InsufficientLiquidity();
error SpaceRouter__MustProvideAmountGreaterThanZero();
error SpaceRouter__SpcMustBeGreaterThanZero();
error SpaceRouter__EthMustBeGreaterThanZero();

contract SpaceRouter {
    SpaceLP public immutable spaceLP;
    SpaceCoin public immutable spaceCoin;

    constructor(SpaceLP _spaceLP, SpaceCoin _spaceCoin) {
        spaceLP = _spaceLP;
        spaceCoin = _spaceCoin;
    }

    /// @notice Provides ETH-SPC liquidity to LP contract
    /// @param spc The amount of SPC to be deposited
    function addLiquidity(uint256 spc) external payable {
        /// @notice calculate liquidity to send to LP
        (uint256 ethOut, uint256 spcOut) = _calculateLiquidity(spc);

        /// @notice transfer SPC and eth to LP
        spaceCoin.transferFrom(msg.sender, address(spaceLP), spcOut);
        spaceLP.deposit{value: ethOut}(msg.sender);

        /// @notice refund any extra eth sent in
        if (msg.value > ethOut) {
            (bool success, ) = payable(msg.sender).call{
                value: msg.value - ethOut
            }("");
            if (!success) revert SpaceRouter__EthTransferFailed();
        }
    }

    /// @notice Removes ETH-SPC liquidity from LP contract
    /// @param lpToken The amount of LP tokens being returned
    function removeLiquidity(uint256 lpToken) external {
        if (lpToken == 0)
            revert SpaceRouter__MustProvideAmountGreaterThanZero();
        if (spaceLP.balanceOf(msg.sender) < lpToken)
            revert SpaceRouter__ExceedsLPTokensOwned();

        spaceLP.transferFrom(msg.sender, address(spaceLP), lpToken);
        spaceLP.withdraw(msg.sender);
    }

    /// @notice Swaps ETH for SPC in LP contract
    /// @param spcOutMin The minimum acceptable amout of SPC to be received
    function swapETHForSPC(uint256 spcOutMin) external payable {
        if (spcOutMin == 0)
            revert SpaceRouter__MinimumSPCOutMustBeGreaterThanZero();

        uint256 spcReserves = spaceLP.spcReserves();

        if (spcReserves == 0) revert SpaceRouter__InsufficientLiquidity();

        spaceLP.swap{value: msg.value}(msg.sender);

        uint256 spcOut = spcReserves - spaceCoin.balanceOf(address(spaceLP));

        if (spcOut < spcOutMin)
            revert SpaceRouter__SwapResultsInLessThanMinimumRequestedSPC();
    }

    /// @notice Swaps SPC for ETH in LP contract
    /// @param spcIn The amount of inbound SPC to be swapped
    /// @param ethOutMin The minimum acceptable amount of ETH to be received
    function swapSPCForETH(uint256 spcIn, uint256 ethOutMin) external {
        /// @notice we require user to set a minimum ethOut
        if (spcIn == 0 || ethOutMin == 0)
            revert SpaceRouter__MinimumSpcInAndEthOutMustBeProvided();

        if (spaceCoin.balanceOf(msg.sender) < spcIn)
            revert SpaceRouter__InsufficientSPCBalanceToSwap();

        uint256 ethReserves = spaceLP.ethReserves();

        if (ethReserves == 0) revert SpaceRouter__InsufficientLiquidity();

        spaceCoin.transferFrom(msg.sender, address(spaceLP), spcIn);
        spaceLP.swap(msg.sender);

        uint256 ethOut = ethReserves - address(spaceLP).balance;

        if (ethOut < ethOutMin)
            revert SpaceRouter__SwapResultsInLessThanMinimumRequestedEth();
    }

    /// @notice helper function to calculate liquidity to send to LP contract
    /// @param spc amount of SPC provided by caller
    function _calculateLiquidity(uint256 spc)
        private
        returns (uint256 ethOut, uint256 spcOut)
    {
        /// @notice current reserves
        uint256 spcReserves = spaceLP.spcReserves();
        uint256 ethReserves = spaceLP.ethReserves();

        /// @notice we apply the tax rate to the below calculations if it is enabled
        uint256 taxRate = spaceCoin.isTaxEnabled() ? spaceCoin.TAX_RATE() : 0;

        /** @notice logic to return amount of liquidity given status of initial liquidity, tax, and provided tokens
         * @dev if this is the initial liquidity addition (both spcReserves and ethReserves are equal to 0), then we
         * simply send through the provided amounts.
         *
         * Otherwise, we check how the provided tokens are balanced compared to the existing reserves. if the SPC/ETH ratio
         * is less than or equal to the existing ratio (which means insufficient SPC tokens were provided - or the exact correct amount),
         * then we calculate the amount of eth that should be sent to the LP contract, refunding the excess eth.
         *
         * If the SPC/ETH ratio is greater than the existing ratio, meaning too many SPC tokens were provided, we reduce the amount
         * of SPC we transfer, while the Eth amount remains the same. No refund is necssary in this case.
         */
        if (spcReserves == 0 && ethReserves == 0) {
            (ethOut, spcOut) = (msg.value, spc);
        } else {
            if (spc == 0) revert SpaceRouter__SpcMustBeGreaterThanZero();
            if (msg.value == 0) revert SpaceRouter__EthMustBeGreaterThanZero();

            if (spc / msg.value <= spcReserves / ethReserves) {
                (ethOut, spcOut) = (
                    ((spc - (spc * taxRate) / 10_000) * ethReserves) /
                        spcReserves,
                    spc
                );
            } else {
                (ethOut, spcOut) = (
                    msg.value,
                    (msg.value * (spcReserves / ethReserves) * 10_000) /
                        (10_000 - taxRate)
                );
            }
        }
    }
}

//SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./SpaceCoin.sol";

error SpaceLP__Locked();
error SpaceLP__EthTransferFailed();
error SpaceLP__NoTokensToSwap();
error SpaceLP__ProjectedKLessThanCurrentK();
error SpaceLP__InsufficientLiquidityToWithdraw();
error SpaceLP__BalancesOutOfSyncWithReserves();
error SpaceLP__NoLPTokensToMint();
error SpaceLP__InsufficientLiquidity();

contract SpaceLP is ERC20 {
    uint256 public constant FEE = 100;
    SpaceCoin public immutable spaceCoin;
    uint256 public ethReserves;
    uint256 public spcReserves;

    bool locked;
    modifier lock() {
        if (locked) revert SpaceLP__Locked();
        locked = true;
        _;
        locked = false;
    }

    event LiquidityAdded(address indexed provider, uint256 lpTokensMinted);
    event LiquidityRemoved(address indexed provider, uint256 lpTokensBurned);
    event Swap(
        address indexed provider,
        uint256 spcIn,
        uint256 spcOut,
        uint256 ethIn,
        uint256 ethOut
    );

    constructor(SpaceCoin _spaceCoin) ERC20("ETH-SPC LP", "ESLP") {
        spaceCoin = _spaceCoin;
    }

    /// @notice Adds ETH-SPC liquidity to LP contract
    /// @param to The address that will receive the LP tokens
    function deposit(address to) external payable lock {
        /// @notice get current balances
        uint256 ethBalance = address(this).balance;
        uint256 spcBalance = spaceCoin.balanceOf(address(this));

        /// @notice difference between current balances and reserves is amount deposited
        uint256 ethAdded = ethBalance - ethReserves;
        uint256 spcAdded = spcBalance - spcReserves;

        uint256 totalLPSupply = totalSupply();

        /// @notice if not initial liquidity event, LP tokens are minted
        /// based on proportional addition of eth
        /// if initial liquidity, just equal to amount of eth added
        uint256 lpTokensToMint;
        if (spcReserves == 0 && ethReserves == 0) {
            lpTokensToMint = ethAdded;
        } else {
            /// @notice calculate the amount of eth that should have been added given SPC added
            uint256 expectedEth = (spcAdded * ethReserves) / spcReserves;

            /// @notice give LP token credit based on lesser of actual eth added and expected
            /// @dev this penalizes unbalanced deposits
            ethAdded = ethAdded < expectedEth ? ethAdded : expectedEth;
            lpTokensToMint = (ethAdded * totalLPSupply) / ethReserves;
        }

        if (lpTokensToMint == 0) revert SpaceLP__NoLPTokensToMint();

        /// @notice mint LP tokens
        _mint(to, lpTokensToMint);

        /// @notice call _update, which sets reserves to new SPC and Eth balances
        _update();

        emit LiquidityAdded(to, lpTokensToMint);
    }

    /// @notice Returns ETH-SPC liquidity to liquidity provider
    /// @param to The address that will receive the outbound token pair
    function withdraw(address to) external lock {
        uint256 ethBalance = address(this).balance;
        uint256 spcBalance = spaceCoin.balanceOf(address(this));
        uint256 totalLpSupply = totalSupply();

        /// @notice router contract should have transferred LP tokens to SpaceLP
        uint256 currentLiquidity = balanceOf(address(this));

        /// @notice get proportional share of eth and spc owed to liquidity provider
        uint256 ethOut = (currentLiquidity * ethBalance) / totalLpSupply;
        uint256 spcOut = (currentLiquidity * spcBalance) / totalLpSupply;

        if (ethOut == 0 || spcOut == 0)
            revert SpaceLP__InsufficientLiquidityToWithdraw();

        /// @notice burn LP tokens
        _burn(address(this), currentLiquidity);

        /// @notice transfer spc and eth out
        spaceCoin.transfer(to, spcOut);
        (bool success, ) = payable(to).call{value: ethOut}("");
        if (!success) revert SpaceLP__EthTransferFailed();

        /// @notice update reserves with new balances
        _update();

        emit LiquidityRemoved(to, currentLiquidity);
    }

    /// @notice Swaps ETH for SPC, or SPC for ETH
    /// @param to The address that will receive the outbound SPC or ETH
    function swap(address to) external payable lock {
        /// @notice validate that balances are in sync using this private function
        _validateSwap();

        /// @notice if msg.value is greater than 0, we assume this is an ETH for SPC swap
        /// @dev returns amount of tokens in to calculate fees for projected k calculation
        (uint256 ethIn, uint256 ethOut, uint256 spcIn, uint256 spcOut) = msg
            .value > 0
            ? _swapETHForSPC(to)
            : _swapSPCForEth(to);

        /// @notice current eth balance less fees earned on swap
        uint256 ethBalanceExFees = address(this).balance -
            ((ethIn * FEE) / 10_000);

        /// @notice current spc balance less fees earned on swap
        uint256 spcBalanceExFees = spaceCoin.balanceOf(address(this)) -
            ((spcIn * FEE) / 10_000);

        /// @notice current k based on reserves
        uint256 currentK = ethReserves * spcReserves;

        /// @notice projected k based on new balance (excluding impact of fees)
        uint256 projectedK = ethBalanceExFees * spcBalanceExFees;

        /// @notice revert if for some reason projected k is less than current k
        if (projectedK < currentK) revert SpaceLP__ProjectedKLessThanCurrentK();

        /// @notice call _update, which sets reserves to new SPC and Eth balances
        _update();

        emit Swap(to, spcIn, spcOut, ethIn, ethOut);
    }

    /// @notice sets current reserves to current balances; to be called in
    /// event that swaps are unavailable because both Eth and SPC reserves
    /// are out of sync with actual balances
    function sync() external lock {
        _update();
    }

    function _swapETHForSPC(address to)
        private
        returns (
            uint256 ethIn,
            uint256 ethOut,
            uint256 spcIn,
            uint256 spcOut
        )
    {
        ethIn = msg.value;
        spcIn = 0;

        /// @notice calculate how much SPC should be sent out
        spcOut = _getTokensOut(msg.value, ethReserves, spcReserves, FEE);
        ethOut = 0;

        /// @notice transfer the SPC
        spaceCoin.transfer(to, spcOut);
    }

    function _swapSPCForEth(address to)
        private
        returns (
            uint256 ethIn,
            uint256 ethOut,
            uint256 spcIn,
            uint256 spcOut
        )
    {
        spcIn = spaceCoin.balanceOf(address(this)) - spcReserves;
        ethIn = 0;

        /// @notice revert immediately if no change in SPC balance
        if (spcIn == 0) revert SpaceLP__NoTokensToSwap();

        ethOut = _getTokensOut(spcIn, spcReserves, ethReserves, FEE);
        spcOut = 0;

        /// @notice transfer the ETH
        (bool success, ) = payable(to).call{value: ethOut}("");
        if (!success) revert SpaceLP__EthTransferFailed();
    }

    function _update() private {
        ethReserves = address(this).balance;
        spcReserves = spaceCoin.balanceOf(address(this));
    }

    function _validateSwap() private view {
        uint256 ethBalance = address(this).balance;
        uint256 spcBalance = spaceCoin.balanceOf(address(this));

        if (ethBalance != ethReserves && spcBalance != spcReserves)
            revert SpaceLP__BalancesOutOfSyncWithReserves();

        if (ethReserves == 0 || spcReserves == 0) {
            revert SpaceLP__InsufficientLiquidity();
        }
    }

    function _getTokensOut(
        uint256 tokenInAmount,
        uint256 tokenInReserves,
        uint256 tokenOutReserves,
        uint256 _feeInBasisPoints
    ) private pure returns (uint256) {
        uint256 fee = (tokenInAmount * _feeInBasisPoints) / 10_000;
        uint256 tokenInAfterFee = tokenInAmount - fee;

        return
            (tokenOutReserves * tokenInAfterFee) /
            (tokenInReserves + tokenInAfterFee);
    }
}

//SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

error SpaceCoin__TaxNotActive();
error SpaceCoin__NotOwner();
error SpaceCoin__TaxAlreadyEnabled();
error SpaceCoin__TaxAlreadyDisabled();

/** @title SpaceCoin Token
 * @author Maks Pazuniak
 * @notice The total supply is minted at deployment via the constructor function.
 * 150,000 SPC is allocated to the ICO and 350,000 to the Treasury.
 */
contract SpaceCoin is ERC20 {
    uint256 public constant TREASURY_INITIAL_SUPPLY = 350_000e18;
    uint256 public constant ICO_INITIAL_SUPPLY = 150_000e18;
    uint256 public constant TAX_RATE = 200; // basis points, equal to 2%
    address public immutable treasury;
    address public immutable owner;
    bool public isTaxEnabled; // defaults to false

    event TaxEnabled();
    event TaxDisabled();

    /** @notice The total supply is also minted via the constructor function. There is
     * no callable `mint` function, ensuring a fixed total supply of 500,000 SPC tokens.
     * @dev treasury and owner state variables are set via the constructor.
     */
    constructor(
        address _treasury,
        address _ico,
        address _owner,
        string memory _name,
        string memory _symbol
    ) ERC20(_name, _symbol) {
        treasury = _treasury;
        owner = _owner;

        _mint(_treasury, TREASURY_INITIAL_SUPPLY);
        _mint(_ico, ICO_INITIAL_SUPPLY);
    }

    modifier onlyOwner() {
        if (msg.sender != owner) revert SpaceCoin__NotOwner();
        _;
    }

    /// @dev the owner of the contract can enable tax
    function enableTax() external onlyOwner {
        if (isTaxEnabled) revert SpaceCoin__TaxAlreadyEnabled();
        isTaxEnabled = true;

        emit TaxEnabled();
    }

    /// @dev the owner of the contract can disable the tax
    function disableTax() external onlyOwner {
        if (!isTaxEnabled) revert SpaceCoin__TaxAlreadyDisabled();
        isTaxEnabled = false;

        emit TaxDisabled();
    }

    /** @dev this function overrides the inherited ERC-20
     * `_transfer` implementation. Whenever external `transfer` or `transferFrom`
     * function calls are made, they will call this function after ,
     * ensuring tax payments are accounted for on all transfers.
     *
     * After handling tax adjustments, the inherited _transfer is called via `super`
     * with the desired amount, ensuring proper balance accounting and event
     * emissions.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        /** @dev if tax is enabled, tokens are transferred to the treasury on each transfer.
         * Otherwise, the inherited `_transfer` function is simply called without any adjustments.
         */
        if (isTaxEnabled) {
            /// @dev tax is calculated via a private function
            uint256 taxAmount = _calculateTax(amount);
            super._transfer(from, treasury, taxAmount);
            amount -= taxAmount;
        }
        super._transfer(from, to, amount);
    }

    function _calculateTax(uint256 _amount) private pure returns (uint256) {
        return (_amount * TAX_RATE) / 10_000;
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