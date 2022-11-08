// SPDX-License-Identifier: UNLICENSED
// @Title JustMoney Bridged Token
// @Author Team JustMoney

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./BridgeOracle.sol";
import "./ReentrancyGuard.sol";
import "./Address.sol";

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
contract ProspectiveToken is BridgeOracle, IERC20, ReentrancyGuard {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private constant _max = 1000000000 * (10**18);
    uint256 private _totalSupply;
    uint256 private _totalBurned;

    bool public isMintingEnabled = true;
    bool public isBurningEnabled = true;
    
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor() {
        _name = "Prospective";
        _symbol = "PROS";
        _decimals = 18;
    }

    modifier mintingEnabled() {
        require(isMintingEnabled, Errors.MINT_DISABLED);
        _;
    }
    
    modifier burningEnabled() {
        require(isBurningEnabled, Errors.BURN_DISABLED);
        _;
    }
    
    modifier notZeroAddress(address _account) {
        require(_account != address(0), Errors.NOT_ZERO_ADDRESS);
        _;
    }
    
    modifier belowCap(uint256 amount) {
        require(amount <= (_max - _totalSupply - _totalBurned), Errors.ABOVE_CAP);
        _;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view override returns (string memory) {
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
    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function totalBurned() public view returns (uint256) {
        return _totalBurned;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
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
    function transfer(address to, uint256 amount) public override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view override returns (uint256) {
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
    function approve(address spender, uint256 amount) public override returns (bool) {
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
    function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
        address spender = _msgSender();
        require(amount <= _allowances[from][spender], Errors.NOT_APPROVED);
        
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
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
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
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= subtractedValue, Errors.ALLOWANCE_BELOW_ZERO);
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }
    
    function enableMinting() public onlyHandlerOracle returns (string memory retMsg) {
        require(!isMintingEnabled, Errors.MINT_ALREADY_ENABLED);
        
        isMintingEnabled = true;
        emit MintingEnabled();
        retMsg = "Enabled Minting";
    }

    function disableMinting() public onlyHandlerOracle returns (string memory retMsg) {
        require(isMintingEnabled, Errors.MINT_ALREADY_DISABLED);
        
        isMintingEnabled = false;
        emit MintingDisabled();
        retMsg = "Disabled Minting";
    }
    
    function enableBurning() public onlyHandlerOracle returns (string memory retMsg) {
        require(!isBurningEnabled, Errors.BURN_ALREADY_ENABLED);
        
        isBurningEnabled = true;
        emit BurningEnabled();
        retMsg = "Enabled Burning";
    }

    function disableBurning() public onlyHandlerOracle returns (string memory retMsg) {
        require(isBurningEnabled, Errors.BURN_ALREADY_DISABLED);
        
        isBurningEnabled = false;
        emit BurningDisabled();
        retMsg = "Disabled Burning";
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
    function _transfer(address from, address to, uint256 amount) internal notZeroAddress(from) notZeroAddress(to) {
        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, Errors.TRANSFER_EXCEEDS_BALANCE);
        unchecked { _balances[from] = fromBalance - amount; }
        _balances[to] += amount;

        emit Transfer(from, to, amount);
    }
    
    /**
     * @dev Creates `amount` new tokens for `to`.
     *
     * See {ERC20-_mint}.
     *
     * Requirements:
     *
     * - the caller must be the bridge or owner.
     */
    function mint(address to, uint256 amount) public onlyOracleAndBridge {
        _mint(to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - minting and burning must be enabled.
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal mintingEnabled notZeroAddress(account) belowCap(amount) {
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        address mintBy = _msgSender();
        if ( isBridgeHandler(mintBy) ) {
            emit BridgeMint(mintBy, account, amount);
        } else {
            require(oracleApprovedToManualMint == true, Errors.NOT_APPROVED_TO_MANUAL_MINT);
            emit ManualMint(mintBy, account, amount);
            oracleApprovedToManualMint = false;
        }
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
    function _burn(address account, uint256 amount) internal burningEnabled notZeroAddress(account) {
        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, Errors.BURN_EXCEEDS_BALANCE);
        unchecked { _balances[account] = accountBalance - amount; }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        address burnBy = _msgSender();
        if ( isBridgeHandler(burnBy) || burnBy == address(_handlerOracle) ) {
            emit BridgeBurn(account, burnBy, amount);
        } else {
            unchecked { _totalBurned += amount; }
            emit NormalBurn(account, burnBy, amount);
        }
    }
    
    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This private function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) private notZeroAddress(owner) notZeroAddress(spender) {
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
    function _spendAllowance(address owner, address spender, uint256 amount) internal {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, Errors.INSUFFICIENT_ALLOWANCE);
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }
    
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public {
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
    function burnFrom(address account, uint256 amount) public {
        require(amount <= _allowances[account][_msgSender()], Errors.NOT_APPROVED);
        
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }
    
    function withdrawBASE(address payable recipient) external onlyOwner notZeroAddress(recipient) nonReentrant {
        require(address(this).balance > 0, Errors.NOTHING_TO_WITHDRAW);

        Address.sendValue(recipient, address(this).balance);
    }

    function withdrawERC20token(address _token, address payable recipient) external onlyOwner notZeroAddress(recipient) returns (bool) {
        uint256 bal = IERC20(_token).balanceOf(address(this));
        require(bal > 0, Errors.NOTHING_TO_WITHDRAW);

        return IERC20(_token).transfer(recipient, bal);
    }
    
    event BridgeMint(address indexed by, address indexed to, uint256 value);
    event ManualMint(address indexed by, address indexed to, uint256 value);
    event BridgeBurn(address indexed from, address indexed by, uint256 value);
    event NormalBurn(address indexed from, address indexed to, uint256 value);
    event MintingEnabled();
    event MintingDisabled();
    event BurningEnabled();
    event BurningDisabled();
}