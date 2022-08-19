/**
 *Submitted for verification at Etherscan.io on 2022-08-19
*/

/**
 *Submitted for verification at BscScan.com on 2022-08-18
*/

/**
 *Submitted for verification at BscScan.com on 2022-08-18
// */
//                   TOKENOMICS 
// ERC Wallet	       percentage	        amount
// Agartha	            24.14%	         GOL17,500,000.00
// Mining	            15.52%	         GOL11,250,000.00
// NFT	                17.24%	         GOL12,500,000.00
// Gol Blockchain	    27.59%	         GOL20,000,000.00
// Rest	                15.52%	         GOL11,250,000.00
// total ERC wallet	    25.00%	         GOL72,500,000.00








// ///File: contracts/IERC20.sol

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);

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

// File: contracts/Context.sol

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

// File: contracts/Errors.sol


pragma solidity ^0.8.0;

library Errors {
    string constant MINT_DISABLED = "Token: Minting is disabled";
    string constant BURN_DISABLED = "Token: Burning is disabled";
    string constant MINT_ALREADY_ENABLED = "Token: Minting is already enabled";
    string constant MINT_ALREADY_DISABLED = "Token: Minting is already disabled";
    string constant BURN_ALREADY_ENABLED = "Token: Burning is already enabled";
    string constant BURN_ALREADY_DISABLED = "Token: Burning is already disabled";
    string constant NON_ZERO_ADDRESS = "Token: Address can not be 0x0";
    string constant NOT_APPROVED = "Token: You are not approved to spend this amount of tokens";
    string constant TRANSFER_EXCEEDS_BALANCE = "Token: Transfer amount exceeds balance";
    string constant BURN_EXCEEDS_BALANCE = "Token: Burn amount exceeds balance";
    string constant INSUFFICIENT_ALLOWANCE = "Token: Insufficient allowance";
    string constant NOTHING_TO_WITHDRAW = "Token: The balance must be greater than 0";
    string constant ALLOWANCE_BELOW_ZERO = "Token: Decreased allowance below zero";
    string constant ABOVE_CAP = "Token: Amount is above the cap";

    string constant NOT_OWNER = "Ownable: Caller is not the owner";
    string constant OWNABLE_NON_ZERO_ADDRESS = "Ownable: Address can not be 0x0";

    string constant NOT_ORACLE_OR_HANDLER = "Oracle: Caller is not the oracle or handler";
    string constant ADDRESS_IS_HANDLER = "Oracle: Address is already a Bridge Handler";
    string constant ADDRESS_IS_NOT_HANDLER = "Oracle: Address is not a Bridge Handler";
    string constant TOKEN_NOT_ALLOWED_IN_BRIDGE = "Oracle: Your token is not allowed in JM Bridge";
    string constant SET_HANDLER_ORACLE_FIRST = "Oracle: Set the handler oracle address first";
    string constant ORACLE_NOT_SET = "Oracle: No oracle set";
    string constant IS_NOT_ORACLE = "Oracle: You are not the oracle";
    string constant NOT_ALLOWED_TO_EDIT_ORACLE = "Oracle: Not allowed to edit the Handler Oracle address";
    string constant NON_ZERO_ADDRESS_SENDER = "Oracle: Sender can not be 0x0";
}

// File: contracts/Ownable.sol

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
        require(owner() == _msgSender(), Errors.NOT_OWNER);
        _;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), Errors.OWNABLE_NON_ZERO_ADDRESS);
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

// File: contracts/BridgeOracle.sol


pragma solidity ^0.8.0;

interface HandlerOracle {
    function approveHandlerChange() external returns (bool);
    function approveManualMint() external returns (bool);
    function isTokenContract(address tokenContract) external view returns (bool);
    function isAllowedToChangeOracle(address tokenContract) external view returns (bool);
}

abstract contract BridgeOracle is Ownable {
    HandlerOracle internal _handlerOracle;
    address private _bridgeHandler;

    event BridgeHandlerSet(address indexed added);

    /**
     * @dev Returns true if the address is a bridge handler.
     */
    function isBridgeHandler(address account) public view returns (bool) {
        return _bridgeHandler == account;
    }
    
    /**
     * @dev Throws if called by any account other than the oracle or a bridge handler.
     */
    modifier onlyOracleAndBridge() {
        require(_msgSender() != address(0), Errors.NON_ZERO_ADDRESS_SENDER);
        require(isBridgeHandler(_msgSender()) || address(_handlerOracle) == _msgSender(), Errors.NOT_ORACLE_OR_HANDLER);
        _;
    }
    
    modifier onlyHandlerOracle() {
        require(_msgSender() != address(0), Errors.ORACLE_NOT_SET);
        require(_msgSender() == address(_handlerOracle), Errors.IS_NOT_ORACLE);
        _;
    }

    function approveOracleToSetHandler() public onlyOwner returns (bool) {
        require(address(_handlerOracle) != address(0), Errors.SET_HANDLER_ORACLE_FIRST);
        require(_handlerOracle.isTokenContract(address(this)) == true, Errors.TOKEN_NOT_ALLOWED_IN_BRIDGE);

        return _handlerOracle.approveHandlerChange();
    }
    
    function approveOracleToManualMint() public onlyOwner returns (bool) {
        require(address(_handlerOracle) != address(0), Errors.SET_HANDLER_ORACLE_FIRST);
        require(_handlerOracle.isTokenContract(address(this)) == true, Errors.TOKEN_NOT_ALLOWED_IN_BRIDGE);

        return _handlerOracle.approveManualMint();
    }

    /**
     * @dev Add handler address (`account`) that can mint and burn.
     * Can only be called by the 'Handler Oracle Contract' after it was approved.
     */
    function setBridgeHandler(address account) public onlyHandlerOracle {
        require(account != address(0), Errors.OWNABLE_NON_ZERO_ADDRESS);
        require(!isBridgeHandler(account), Errors.ADDRESS_IS_HANDLER);

        emit BridgeHandlerSet(account);
        _bridgeHandler = account;
    }

    function setHandlerOracle(address newHandlerOracle) public onlyOwner {
        require(HandlerOracle(newHandlerOracle).isTokenContract(address(this)) == true, Errors.TOKEN_NOT_ALLOWED_IN_BRIDGE);

        if ( address(_handlerOracle) == address(0) ) {
            _handlerOracle = HandlerOracle(newHandlerOracle);
        } else {
            require(_handlerOracle.isAllowedToChangeOracle(address(this)) == true, Errors.NOT_ALLOWED_TO_EDIT_ORACLE);

            _handlerOracle = HandlerOracle(newHandlerOracle);
        }
    }
}

// File: contracts/GOLCOIN.sol

// @Title GOLCOIN Bridged Token
// @Author Team GOLCOIN

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
contract GOLCOIN is BridgeOracle, IERC20 {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private constant _max = 290000000 * 10**18;
    uint256 private _totalSupply;
    uint256 private _totalBurned;

    bool public isMintingEnabled = false;
    bool public isBurningEnabled = true;
    
    string private _name = "GOLCOIN";
    string private _symbol = "GOLC";
    uint8 private _decimals = 18;

    constructor() {
        uint256 initialAmount = 72500000 * 10**18;
        _totalSupply = initialAmount;
        _balances[_msgSender()] = initialAmount;
    }

    modifier mintingEnabled() {
        require(isMintingEnabled, Errors.MINT_DISABLED);
        _;
    }
    
    modifier burningEnabled() {
        require(isBurningEnabled, Errors.BURN_DISABLED);
        _;
    }
    
    modifier nonZeroAddress(address _account) {
        require(_account != address(0), Errors.NON_ZERO_ADDRESS);
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
    function _transfer(address from, address to, uint256 amount) internal nonZeroAddress(from) nonZeroAddress(to) {
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
    function _mint(address account, uint256 amount) internal mintingEnabled nonZeroAddress(account) belowCap(amount) {
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        address mintBy = _msgSender();
        if ( isBridgeHandler(mintBy) ) {
            emit BridgeMint(mintBy, account, amount);
        } else {
            emit ManualMint(mintBy, account, amount);
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
    function _burn(address account, uint256 amount) internal burningEnabled nonZeroAddress(account) {
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
    function _approve(address owner, address spender, uint256 amount) private nonZeroAddress(owner) nonZeroAddress(spender) {
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
    
    function withdrawBASE(address payable recipient) external onlyOwner nonZeroAddress(recipient) {
        require(address(this).balance > 0, Errors.NOTHING_TO_WITHDRAW);

        recipient.transfer(address(this).balance);
    }

    function withdrawERC20token(address _token, address payable recipient) external onlyOwner nonZeroAddress(recipient) returns (bool) {
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