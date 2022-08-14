// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import "./Pool.sol";
import "./ICO.sol";

contract Router {
    error DeadlinePassed();
    error InsufficientReserves();
    error InvalidAmount();
    error AddSpcFailed();
    error AddEthFailed();
    error MinSpcNotMet();
    error MinEthNotMet();
    error RefundFailed();
    error TransferPoolTokensFailed();

    ICO private immutable ico; // my ICO contract `is SpaceToken`
    Pool public immutable pool;

    uint16 public FEE_MULTIPLE_TAKE = 990; // 1% relative to FEE_MULTIPLE
    uint16 public FEE_MULTIPLE = 1000; // 1% relative to FEE_MULTIPLE

    modifier beforeDeadline(uint256 time) {
        if (time <= block.timestamp) revert DeadlinePassed();
        _;
    }

    constructor(address _icoAddress, Pool _pool) {
        ico = ICO(_icoAddress);
        pool = _pool;
    }

    function addLiquidity(
        uint256 amountDesiredSpc,
        uint256 amountMinSpc,
        uint256 amountMinEth,
        address to,
        uint256 deadline)
    external payable beforeDeadline(deadline) {
        uint256 ethAmt = msg.value;
        uint256 spcAmt = amountDesiredSpc;

        (uint256 ethReserve, uint256 spcReserve) = getReserves();

        if (!(ethReserve == 0 && spcReserve == 0)) {
            uint256 spcOptimal = quote(msg.value, ethReserve, spcReserve);
            uint256 ethOptimal = quote(amountDesiredSpc, spcReserve, ethReserve);

            if (spcOptimal <= amountDesiredSpc) {
                if (amountMinSpc > spcOptimal) revert MinSpcNotMet();
                spcAmt = spcOptimal;
            } else {
                assert(ethOptimal <= msg.value);
                if (amountMinEth > ethOptimal) revert MinEthNotMet();
                ethAmt = ethOptimal;
            }
        }

        bool result = ico.transferFrom(msg.sender, address(pool), spcAmt);
        if (!result) revert AddSpcFailed();

        (bool resultEth, ) = address(pool).call{value: ethAmt}("");
        if (!resultEth) revert AddEthFailed();

        pool.mint(to);

        if (msg.value > ethAmt) {
            (bool resultRefund, ) = msg.sender.call{value: msg.value - ethAmt}("");
            if (!resultRefund) revert RefundFailed();
        }
    }

    function removeLiquidity(
        uint256 liquidity,
        uint256 amountMinSpc,
        uint256 amountMinEth,
        address to,
        uint256 deadline
    ) external beforeDeadline(deadline) {
        bool result = pool.transferFrom(msg.sender, address(pool), liquidity);
        if (!result) revert TransferPoolTokensFailed();
        (uint256 spcAmount, uint256 etherAmount) = pool.burn(to);
        if (spcAmount < amountMinSpc) revert MinSpcNotMet();
        if (etherAmount < amountMinEth) revert MinEthNotMet();
    }

    function _swap(
        bool ethIn,
        address to
    ) internal {
        (uint256 ethReserve, uint256 spcReserve) = getReserves();
        uint256 ethOut;
        uint256 spcOut;
        uint256 ethAmountIn;
        uint256 spcAmountIn;

        if (ethIn) {
            ethAmountIn = address(pool).balance - ethReserve;
            spcOut = getAmountOut(ethAmountIn, ethReserve, spcReserve);
        } else {
            spcAmountIn = ico.balanceOf(address(pool)) - spcReserve;
            ethOut = getAmountOut(spcAmountIn, spcReserve, ethReserve);
        }

        pool.swap(ethOut, spcOut, to);
    }

    function swapEthForSpc(
        uint256 spcOutMin,
        address to,
        uint256 deadline
    ) external payable beforeDeadline(deadline) {
        (bool resultEth, ) = address(pool).call{value: msg.value}("");
        if (!resultEth) revert AddEthFailed();

        uint256 balance = ico.balanceOf(to);
        _swap(true, to);
        if (ico.balanceOf(to) - balance < spcOutMin) revert MinSpcNotMet();
    }

    function swapSpcForEth(
        uint256 spcIn,
        uint256 ethOutMin,
        address to,
        uint256 deadline
    ) external beforeDeadline(deadline) {
        bool result = ico.transferFrom(msg.sender, address(pool), spcIn);
        if (!result) revert AddSpcFailed();

        uint256 balance = to.balance;
        _swap(false, to);
        if (to.balance - balance < ethOutMin) revert MinEthNotMet();
    }

    function quote(uint256 amountA, uint256 reserveA, uint256 reserveB) internal pure returns (uint256){
        if (amountA == 0) revert InvalidAmount();
        if (reserveA == 0 || reserveB == 0) revert InsufficientReserves();
        return amountA * reserveB / reserveA;
    }

    function getReserves() internal view returns (uint256 ethReserve, uint256 spcReserve) {
        return (pool.etherReserve(), pool.spcReserve());
    }

    function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut) internal view returns(uint256){
        if (amountIn == 0) revert InvalidAmount();
        if (reserveIn == 0 || reserveOut == 0) revert InsufficientReserves();

        uint256 amountInFee = FEE_MULTIPLE_TAKE * amountIn;
        uint256 num = amountInFee * reserveOut;
        uint256 denom = reserveIn * FEE_MULTIPLE + amountInFee;

        return num / denom;
    }

    function spcToEthPrice() external view returns (uint256) {
        return quote(1 ether, pool.etherReserve(), pool.spcReserve());
    }
}

pragma solidity ^0.8.13;

import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "./ICO.sol";

contract Pool is ERC20 {
    error NotRouter();
    error Reentrant();
    error LiquidityTooLow();
    error TransferSpcFailed();
    error TransferEthFailed();
    error InvalidK();
    error CantSwapToToken();
    error InsufficientAmountIn();
    error InsufficientAmountOut();
    error DoubleOut();

    event Mint(address indexed sender, address indexed to, uint256 spcAmount, uint256 etherAmount);
    event Burn(address indexed sender, address indexed to, uint256 spcAmount, uint256 etherAmount);
    event Swap(
        address indexed sender,
        address indexed to,
        uint256 spcAmountIn,
        uint256 etherAmountIn,
        uint256 spcAmountOut,
        uint256 etherAmountOut);

    uint256 public spcReserve;
    uint256 public etherReserve;

    ICO private ico;

    uint16 public FEE_TAKE = 10;
    uint16 public FEE_MULTIPLE = 1000;
    uint8 entered;

    modifier nonReentrant() {
        if (entered == 1) revert Reentrant();
        entered = 1;
        _;
        entered = 0;
    }

    receive() external payable {}

    constructor (string memory name, string memory symbol, ICO _ico) ERC20(name, symbol) {
        ico = _ico;
    }

    function mint(address to) external nonReentrant {
        uint256 liquidity;
        uint256 supply = totalSupply();
        uint256 _spcReserve = spcReserve;
        uint256 _etherReserve = etherReserve;

        uint256 spcBalance = ico.balanceOf(address(this));
        uint256 etherBalance = address(this).balance;

        uint256 spcAmount = spcBalance - _spcReserve;
        uint256 etherAmount = etherBalance - _etherReserve;

        if (supply > 0) {
            uint256 spcLiquidity = spcAmount * supply / _spcReserve;
            uint256 etherLiquidity = etherAmount * supply / _etherReserve;
            liquidity = spcLiquidity < etherLiquidity ? spcLiquidity : etherLiquidity;
        } else {
            liquidity = sqrt(spcAmount * etherAmount);
        }

        if (liquidity == 0) revert LiquidityTooLow();

        _mint(to, liquidity);
        _update(spcBalance, etherBalance);
        emit Mint(msg.sender, to, spcAmount, etherAmount);
    }

    function burn(address to) external nonReentrant returns(uint256 spcAmount, uint256 etherAmount) {
        uint256 supply = totalSupply();
        uint256 spcBalance = ico.balanceOf(address(this));
        uint256 etherBalance = address(this).balance;
        uint256 liquidity = balanceOf(address(this));

        spcAmount = liquidity * spcBalance / supply;
        etherAmount = liquidity * etherBalance / supply;

        bool result = ico.transfer(to, spcAmount);
        if (!result) revert TransferSpcFailed();
        (bool resultEth,) = to.call{value: etherAmount}("");
        if (!resultEth) revert TransferEthFailed();

        _burn(address(this), liquidity);
        // following transfers, pass in new balances to update reserves
        _update(ico.balanceOf(address(this)), address(this).balance);
        emit Burn(msg.sender, to, spcAmount, etherAmount);
    }

    function swap(uint256 ethOut, uint256 spcOut, address to) external nonReentrant {
        if (to == address(ico)) revert CantSwapToToken();
        if (ethOut == 0 && spcOut == 0) revert InsufficientAmountOut();
        if (ethOut > 0 && spcOut > 0) revert DoubleOut();

        uint256 _spcReserve = spcReserve;
        uint256 _etherReserve = etherReserve;
        if (_spcReserve <= spcOut || _etherReserve <= ethOut) revert LiquidityTooLow();

        uint256 spcAmountIn;
        uint256 ethAmountIn;
        uint256 spcBalance = ico.balanceOf(address(this));
        uint256 ethBalance = address(this).balance;

        if (ethOut > 0) {
            spcAmountIn = spcBalance - _spcReserve; // spcOut will be zero
        } else {
            ethAmountIn = ethBalance - _etherReserve; //ethOut will be zero
        }

        if (spcAmountIn == 0 && ethAmountIn == 0) revert InsufficientAmountIn();

        if (ethOut > 0){
            (bool result,) = to.call{value: ethOut}("");
            if (!result) revert TransferEthFailed();
            ethBalance -= ethOut;
        } else {
            bool result = ico.transfer(to, spcOut);
            if (!result) revert TransferSpcFailed();
            spcBalance -= spcOut; //could also call balanceOf
        }

        { // scoped to avoid CompilerError: Stack too deep.
            uint256 feeSpcBalance = spcBalance * FEE_MULTIPLE - spcAmountIn * FEE_TAKE;
            uint256 feeEthBalance = ethBalance * FEE_MULTIPLE - ethAmountIn * FEE_TAKE;
            if (feeEthBalance * feeSpcBalance < _spcReserve * _etherReserve * FEE_MULTIPLE * FEE_MULTIPLE) revert InvalidK();
        }

        _update(spcBalance, ethBalance);
        emit Swap(msg.sender, to, spcAmountIn, ethAmountIn, spcOut, ethOut);
    }

    function _update(uint256 spcBalance, uint256 etherBalance) internal {
        spcReserve = spcBalance;
        etherReserve = etherBalance;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) internal pure returns (uint z) {
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

}

pragma solidity ^0.8.13;

import "./SpaceToken.sol";

    error NotOwner();
    error CantAdvancePhase();
    error NotOnAllowlist();
    error CantAppendAllowlist();
    error ContributionsPaused();
    error CantPauseGoalMet();
    error NothingToWithdraw();
    error NotOpenPhase();
    error MustContribute();

    error MaxIndividualSeedExceeded();
    error MaxSeedExceeded();
    error MaxIndividualGeneralExceeded();
    error MaxExceeded();

contract ICO is SpaceToken {
    enum ICOPhase { SEED, GENERAL, OPEN }

    uint256 private constant TOTAL_ETH_LIMIT = 30_000 ether;
    uint256 private constant SEED_LIMIT = 15_000 ether;
    uint256 private constant SEED_INDIVIDUAL_LIMIT = 1_500 ether;
    uint256 private constant GENERAL_INDIVIDUAL_LIMIT = 1_000 ether;
    uint256 private constant TREASURY_SPC_AMOUNT = 350_000;
    uint256 private constant ICO_SPC_AMOUNT = 150_000;
    // Manually tracking the balance is needed to protect against `selfdestruct(address)` where someone could
    //force ETH into this contract forever trapping SPC within.
    uint256 private balance;
    uint8 private constant TOKEN_RATE = 5;
    uint8 private constant TAX_PERCENT = 2;

    ICOPhase public phase = ICOPhase.SEED;
    bool private paused;
    bool private taxOn;

    address private owner;
    address private treasury;

    mapping(address => uint256) private etherBalances;
    mapping(address => uint256) private tokensBought;

    mapping(address => bool) private allowlist;

    event Contribution(address indexed _contributor, uint256 ethAmount, uint256 spcAmount);
    event PhaseShift(ICOPhase phase);
    event TaxFlipped(bool on);
    event PauseFlipped(bool on);

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    constructor(address[] memory _allowed, address _owner, address _treasury) SpaceToken("SpaceToken", "SPC", address(this)) {
        //TODO: 0 checks on owner?
        owner = _owner;
        treasury = _treasury;

        _transfer(address(this), _treasury, TREASURY_SPC_AMOUNT * 10 ** decimals());

        for (uint i = 0; i < _allowed.length; i++) {
            allowlist[_allowed[i]] = true;
        }
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual override {
        if (taxOn) {
            uint256 tax = amount * TAX_PERCENT / 100;
            super._transfer(sender, treasury, tax);
            amount -= tax;
        }
        super._transfer(sender, recipient, amount);
    }

    //TODO: take current phase as arg
    function progressPhase() external onlyOwner {
        if (phase == ICOPhase.OPEN) revert CantAdvancePhase();

        if (phase == ICOPhase.SEED) {
            phase = ICOPhase.GENERAL;
            emit PhaseShift(ICOPhase.GENERAL);
        } else {
            phase = ICOPhase.OPEN;
            emit PhaseShift(ICOPhase.OPEN);
        }
    }

    //TODO: take current paused as arg
    function flipPaused() external onlyOwner {
        if (!paused && balance == TOTAL_ETH_LIMIT) revert CantPauseGoalMet();
        paused = !paused;
        emit PauseFlipped(paused);
    }

    //TODO: take current tax as arg
    function flipTax() external onlyOwner {
        taxOn = !taxOn;
        emit TaxFlipped(taxOn);
    }

    function showBalance() external view returns (uint256) {
        return tokensBought[msg.sender];
    }

    // I hope this doesn't count as an extra feature, this was included in the front end template so I wrote it
    function spcLeft() external view returns (uint256) {
        return (ICO_SPC_AMOUNT * 10 ** decimals()) - (balance * TOKEN_RATE);
    }

    function contribute() external payable {
        if (msg.value == 0) revert MustContribute();
        if (paused) revert ContributionsPaused();
        uint256 tempBalance = balance + msg.value;
        if (tempBalance > TOTAL_ETH_LIMIT) revert MaxExceeded();

        if (phase == ICOPhase.SEED) {
            if (tempBalance > SEED_LIMIT) {
                revert MaxSeedExceeded();
            } else if (!allowlist[msg.sender]) {
                revert NotOnAllowlist();
            } else if (etherBalances[msg.sender] + msg.value > SEED_INDIVIDUAL_LIMIT) {
                revert MaxIndividualSeedExceeded();
            }
        } else if (phase == ICOPhase.GENERAL && etherBalances[msg.sender] + msg.value > GENERAL_INDIVIDUAL_LIMIT) {
            revert MaxIndividualGeneralExceeded();
        }

        balance = tempBalance;
        etherBalances[msg.sender] += msg.value;
        uint256 tokenAmt = msg.value * TOKEN_RATE;
        tokensBought[msg.sender] += tokenAmt;
        emit Contribution(msg.sender, msg.value, tokenAmt);
    }

    function withdraw(address to) external {
        if (phase != ICOPhase.OPEN) revert NotOpenPhase();

        uint256 tokensToTransfer = tokensBought[msg.sender];
        if (tokensToTransfer == 0) revert NothingToWithdraw();

        tokensBought[msg.sender] = 0;

        // No event for withdraw because transfer fires an event
        _transfer(address(this), to, tokensToTransfer);
    }

    function ethWithdraw() external {
//        if (phase != ICOPhase.OPEN) revert NotOpenPhase();
        require(msg.sender == treasury, "ICO::ethWithdraw: msg.sender must be treasury");

        (bool success, ) = treasury.call{value : address(this).balance}("");
        require(success, "ICO::ethWithdraw: transfer failed");
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract SpaceToken is ERC20 {

    uint256 internal constant MAX_SUPPLY = 500_000;

    constructor(string memory name, string memory symbol, address to) ERC20(name, symbol) {
        _mint(to, MAX_SUPPLY * 10 ** decimals());
    }
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