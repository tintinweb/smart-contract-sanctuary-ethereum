/**
 *Submitted for verification at Etherscan.io on 2022-07-25
*/

// File: contracts_ETH/main/libraries/Math.sol


// OpenZeppelin Contracts v4.4.1 (utils/math/Math.sol)

pragma solidity ^0.8.4;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }

    /**
     * @dev Returns the absolute unsigned value of a signed value.
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
        }
    }
}
// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: contracts_ETH/main/libraries/SafeERC20.sol


pragma solidity ^0.8.4;


library SafeERC20 {
    function safeSymbol(IERC20 token) internal view returns (string memory) {
        (bool success, bytes memory data) = address(token).staticcall(
            abi.encodeWithSelector(0x95d89b41)
        );
        return success && data.length > 0 ? abi.decode(data, (string)) : "???";
    }

    function safeName(IERC20 token) internal view returns (string memory) {
        (bool success, bytes memory data) = address(token).staticcall(
            abi.encodeWithSelector(0x06fdde03)
        );
        return success && data.length > 0 ? abi.decode(data, (string)) : "???";
    }

    function safeDecimals(IERC20 token) public view returns (uint8) {
        (bool success, bytes memory data) = address(token).staticcall(
            abi.encodeWithSelector(0x313ce567)
        );
        return success && data.length == 32 ? abi.decode(data, (uint8)) : 18;
    }

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(0xa9059cbb, to, amount)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "SafeERC20: Transfer failed"
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(0x23b872dd, from, to, amount)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "SafeERC20: TransferFrom failed"
        );
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

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

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

// File: contracts_ETH/main/Token.sol


pragma solidity ^0.8.4;




/** 
* @author Formation.Fi.
* @notice  A common Implementation for tokens ALPHA, BETA and GAMMA.
*/

contract Token is ERC20, Ownable {
    struct Deposit{
        uint256 amount;
        uint256 time;
    }
    address public proxyInvestement;
    address private proxyAdmin;

    mapping(address => Deposit[]) public depositPerAddress;
    mapping(address => bool) public  whitelist;
    event SetProxyInvestement(address  _address);
    constructor(string memory _name, string memory _symbol) 
    ERC20(_name,  _symbol) {
    }

    modifier onlyProxy() {
        require(
            (proxyInvestement != address(0)) && (proxyAdmin != address(0)),
            "Formation.Fi: zero address"
        );

        require(
            (msg.sender == proxyInvestement) || (msg.sender == proxyAdmin),
             "Formation.Fi: not the proxy"
        );
        _;
    }
    modifier onlyProxyInvestement() {
        require(proxyInvestement != address(0),
            "Formation.Fi: zero address"
        );

        require(msg.sender == proxyInvestement,
             "Formation.Fi: not the proxy"
        );
        _;
    }

     /**
     * @dev Update the proxyInvestement.
     * @param _proxyInvestement.
     * @notice Emits a {SetProxyInvestement} event with `_proxyInvestement`.
     */
    function setProxyInvestement(address _proxyInvestement) external onlyOwner {
        require(
            _proxyInvestement!= address(0),
            "Formation.Fi: zero address"
        );

         proxyInvestement = _proxyInvestement;

        emit SetProxyInvestement( _proxyInvestement);

    } 

    /**
     * @dev Add a contract address to the whitelist
     * @param _contract The address of the contract.
     */
    function addToWhitelist(address _contract) external onlyOwner {
        require(
            _contract!= address(0),
            "Formation.Fi: zero address"
        );

        whitelist[_contract] = true;
    } 

    /**
     * @dev Remove a contract address from the whitelist
     * @param _contract The address of the contract.
     */
    function removeFromWhitelist(address _contract) external onlyOwner {
         require(
            whitelist[_contract] == true,
            "Formation.Fi: no whitelist"
        );
        require(
            _contract!= address(0),
            "Formation.Fi: zero address"
        );

        whitelist[_contract] = false;
    } 

    /**
     * @dev Update the proxyAdmin.
     * @param _proxyAdmin.
     */
    function setAdmin(address _proxyAdmin) external onlyOwner {
        require(
            _proxyAdmin!= address(0),
            "Formation.Fi: zero address"
        );
        
         proxyAdmin = _proxyAdmin;
    } 


    
    /**
     * @dev add user's deposit.
     * @param _account The user's address.
     * @param _amount The user's deposit amount.
     * @param _time The deposit time.
     */
    function addDeposit(address _account, uint256 _amount, uint256 _time) 
        external onlyProxyInvestement {
        require(
            _account!= address(0),
            "Formation.Fi: zero address"
        );

        require(
            _amount!= 0,
            "Formation.Fi: zero amount"
        );

        require(
            _time!= 0,
            "Formation.Fi: zero time"
        );
        Deposit memory _deposit = Deposit(_amount, _time); 
        depositPerAddress[_account].push(_deposit);
    } 

     /**
     * @dev mint the token product for the user.
     * @notice To receive the token product, the user has to deposit 
     * the required StableCoin in this product. 
     * @param _account The user's address.
     * @param _amount The amount to be minted.
     */
    function mint(address _account, uint256 _amount) external onlyProxy {
        require(
          _account!= address(0),
           "Formation.Fi: zero address"
        );

        require(
            _amount!= 0,
            "Formation.Fi: zero amount"
        );

       _mint(_account,  _amount);
   }

    /**
     * @dev burn the token product of the user.
     * @notice When the user withdraws his Stablecoins, his tokens 
     * product are burned. 
     * @param _account The user's address.
     * @param _amount The amount to be burned.
     */
    function burn(address _account, uint256 _amount) external onlyProxy {
        require(
            _account!= address(0),
            "Formation.Fi: zero address"
        );

         require(
            _amount!= 0,
            "Formation.Fi: zero amount"
        );

        _burn( _account, _amount);
    }
    
     /**
     * @dev Verify the lock up condition for a user's withdrawal request.
     * @param _account The user's address.
     * @param _amount The amount to be withdrawn.
     * @param _period The lock up period.
     * @return _success  is true if the lock up condition is satisfied.
     */
    function checklWithdrawalRequest(address _account, uint256 _amount, uint256 _period) 
        external view returns (bool _success){
        require(
            _account!= address(0),
            "Formation.Fi: zero address"
        );

        require(
           _amount!= 0,
            "Formation.Fi: zero amount"
        );

        Deposit[] memory _deposit = depositPerAddress[_account];
        uint256 _amountTotal = 0;
        for (uint256 i = 0; i < _deposit.length; i++) {
             require ((block.timestamp - _deposit[i].time) >= _period, 
            "Formation.Fi:  position locked");
            if (_amount<= (_amountTotal + _deposit[i].amount)){
                break; 
            }
            _amountTotal = _amountTotal + _deposit[i].amount;
        }
        _success= true;
    }


     /**
     * @dev update the user's token data.
     * @notice this function is called after each desposit request 
     * validation by the manager.
     * @param _account The user's address.
     * @param _amount The deposit amount validated by the manager.
     */
    function updateTokenData( address _account,  uint256 _amount) 
        external onlyProxyInvestement {
        _updateTokenData(_account,  _amount);
    }

    function _updateTokenData( address _account,  uint256 _amount) internal {
        require(
            _account!= address(0),
            "Formation.Fi: zero address"
        );

        require(
            _amount!= 0,
            "Formation.Fi: zero amount"
        );

        Deposit[] memory _deposit = depositPerAddress[_account];
        uint256 _amountlocal = 0;
        uint256 _amountTotal = 0;
        uint256 _newAmount;
        uint256 k =0;
        for (uint256 i = 0; i < _deposit.length; i++) {
            _amountlocal  = Math.min(_deposit[i].amount, _amount -  _amountTotal);
            _amountTotal = _amountTotal + _amountlocal;
            _newAmount = _deposit[i].amount - _amountlocal;
            depositPerAddress[_account][k].amount = _newAmount;
            if (_newAmount == 0){
               _deleteTokenData(_account, k);
            }
            else {
                k = k+1;
            }
            if (_amountTotal == _amount){
               break; 
            }
        }
    }
    
     /**
     * @dev delete the user's token data.
     * @notice This function is called when the user's withdrawal request is  
     * validated by the manager.
     * @param _account The user's address.
     * @param _index The index of the user in 'amountDepositPerAddress'.
     */
    function _deleteTokenData(address _account, uint256 _index) internal {
        require(
            _account!= address(0),
            "Formation.Fi: zero address"
        );
        uint256 _size = depositPerAddress[_account].length - 1;
        
        require( _index <= _size,
            "Formation.Fi: index is out"
        );
        for (uint256 i = _index; i< _size; i++){
            depositPerAddress[ _account][i] = depositPerAddress[ _account][i+1];
        }
        depositPerAddress[ _account].pop();   
    }
   
     /**
     * @dev update the token data of both the sender and the receiver 
       when the product token is transferred.
     * @param from The sender's address.
     * @param to The receiver's address.
     * @param amount The transferred amount.
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
      ) internal virtual override{
      
       if ((to != address(0)) && (to != proxyInvestement) 
       && (to != proxyAdmin) && (from != address(0)) && (!whitelist[to])){
          _updateTokenData(from, amount);
          Deposit memory _deposit = Deposit(amount, block.timestamp);
          depositPerAddress[to].push(_deposit);
         
        }
    }

}

// File: contracts_ETH/main/Admin.sol


pragma solidity ^0.8.4;





/** 
* @author Formation.Fi.
* @notice Implementation of the contract Admin.
*/

contract Admin is Ownable {
    using SafeERC20 for IERC20;
    uint256 public constant FACTOR_FEES_DECIMALS = 1e4; 
    uint256 public constant FACTOR_PRICE_DECIMALS = 1e6;
    uint256 public constant  SECONDES_PER_YEAR = 365 days; 
    uint256 public slippageTolerance = 200;
    uint256 public  amountScaleDecimals = 1; 
    uint256 public depositFeeRate = 50;  
    uint256 public depositFeeRateParity= 15; 
    uint256 public managementFeeRate = 200;
    uint256 public performanceFeeRate = 2000;
    uint256 public performanceFees;
    uint256 public managementFees;
    uint256 public managementFeesTime;
    uint256 public tokenPrice = 1e6;
    uint256 public tokenPriceMean = 1e6;
    uint256 public minAmount= 100 * 1e18;
    uint256 public lockupPeriodUser = 604800; 
    uint public netDepositInd;
    uint256 public netAmountEvent;
    address public manager;
    address public treasury;
    address public investement;
    address private safeHouse;
    bool public isCancel;
    Token public token;
    IERC20 public stableToken;


    constructor( address _manager, address _treasury,  address _stableTokenAddress,
     address _tokenAddress) {
        require(
            _manager != address(0),
            "Formation.Fi: zero address"
        );

        require(
           _treasury != address(0),
            "Formation.Fi:  zero address"
            );

        require(
            _stableTokenAddress != address(0),
            "Formation.Fi:  zero address"
        );

        require(
           _tokenAddress != address(0),
            "Formation.Fi:  zero address"
        );

        manager = _manager;
        treasury = _treasury; 
        stableToken = IERC20(_stableTokenAddress);
        token = Token(_tokenAddress);
        uint8 _stableTokenDecimals = ERC20( _stableTokenAddress).decimals();
        if ( _stableTokenDecimals == 6) {
            amountScaleDecimals= 1e12;
        }
    }

    modifier onlyInvestement() {
        require(investement != address(0),
            "Formation.Fi:  zero address"
        );

        require(msg.sender == investement,
             "Formation.Fi:  not investement"
        );
        _;
    }

    modifier onlyManager() {
        require(msg.sender == manager, 
        "Formation.Fi: not manager");
        _;
    }

     /**
     * @dev Setter functions to update the Portfolio Parameters.
     */
    function setTreasury(address _treasury) external onlyOwner {
        require(
            _treasury != address(0),
            "Formation.Fi: zero address"
        );

        treasury = _treasury;
    }

    function setManager(address _manager) external onlyOwner {
        require(
            _manager != address(0),
            "Formation.Fi: zero address"
        );

        manager = _manager;
    }

    function setInvestement(address _investement) external onlyOwner {
        require(
            _investement!= address(0),
            "Formation.Fi: zero address"
        );

        investement = _investement;
    } 

    function setSafeHouse(address _safeHouse) external onlyOwner {
        require(
            _safeHouse!= address(0),
            "Formation.Fi: zero address"
        );

        safeHouse = _safeHouse;
    } 

    function setCancel(bool _cancel) external onlyManager {
        isCancel= _cancel;
    }
  
    function setLockupPeriodUser(uint256 _lockupPeriodUser) external onlyManager {
        lockupPeriodUser = _lockupPeriodUser;
    }
 
    function setDepositFeeRate(uint256 _rate) external onlyManager {
        depositFeeRate= _rate;
    }

    function setDepositFeeRateParity(uint256 _rate) external onlyManager {
        depositFeeRateParity= _rate;
    }

    function setManagementFeeRate(uint256 _rate) external onlyManager {
        managementFeeRate = _rate;
    }

    function setPerformanceFeeRate(uint256 _rate) external onlyManager {
        performanceFeeRate  = _rate;
    }
    function setMinAmount(uint256 _minAmount) external onlyManager {
        minAmount= _minAmount;
     }

    function updateTokenPrice(uint256 _price) external onlyManager {
        require(
             _price > 0,
            "Formation.Fi: zero price"
        );

        tokenPrice = _price;
    }

    function updateTokenPriceMean(uint256 _price) external onlyInvestement {
        require(
             _price > 0,
            "Formation.Fi: zero price"
        );
        tokenPriceMean  = _price;
    }

    function updateManagementFeeTime(uint256 _time) external onlyInvestement {
        managementFeesTime = _time;
    }
    

     /**
     * @dev Calculate performance Fees.
     */
    function calculatePerformanceFees() external onlyManager {
        require(performanceFees == 0, "Formation.Fi: fees on pending");

        uint256 _deltaPrice = 0;
        if (tokenPrice > tokenPriceMean) {
            _deltaPrice = tokenPrice - tokenPriceMean;
            tokenPriceMean = tokenPrice;
            performanceFees = (token.totalSupply() *
            _deltaPrice * performanceFeeRate) / (tokenPrice * FACTOR_FEES_DECIMALS); 
        }
    }

    
     /**
     * @dev Calculate management Fees.
     */
    function calculateManagementFees() external onlyManager {
        require(managementFees == 0, "Formation.Fi: fees on pending");
        if (managementFeesTime!= 0){
           uint256 _deltaTime;
           _deltaTime = block.timestamp -  managementFeesTime; 
           managementFees = (token.totalSupply() * managementFeeRate * _deltaTime ) 
           /(FACTOR_FEES_DECIMALS * SECONDES_PER_YEAR);
           managementFeesTime = block.timestamp; 
        }
    }
     
    /**
     * @dev Mint Fees.
     */
    function mintFees() external onlyManager {
        require ((performanceFees + managementFees) > 0, "Formation.Fi: zero fees");

        token.mint(treasury, performanceFees + managementFees);
        performanceFees = 0;
        managementFees = 0;
    }

    /**
     * @dev Calculate net deposit indicator
     * @param _depositAmountTotal the total requested deposit amount by users.
     * @param  _withdrawalAmountTotal the total requested withdrawal amount by users.
     * @param _maxDepositAmount the maximum accepted deposit amount by event.
     * @param _maxWithdrawalAmount the maximum accepted withdrawal amount by event.
     * @return net Deposit indicator: 1 if net deposit case, 0 otherwise (net withdrawal case).
     */
    function calculateNetDepositInd(uint256 _depositAmountTotal, 
        uint256 _withdrawalAmountTotal, uint256 _maxDepositAmount, 
        uint256 _maxWithdrawalAmount) external onlyInvestement returns( uint256) {
        _depositAmountTotal = Math.min(  _depositAmountTotal,
         _maxDepositAmount);
        _withdrawalAmountTotal =  (_withdrawalAmountTotal * tokenPrice) / FACTOR_PRICE_DECIMALS;
        _withdrawalAmountTotal= Math.min(_withdrawalAmountTotal,
        _maxWithdrawalAmount);
        uint256  _depositAmountTotalAfterFees = _depositAmountTotal - 
        ( _depositAmountTotal * depositFeeRate)/ FACTOR_FEES_DECIMALS;
        if  ( _depositAmountTotalAfterFees >= _withdrawalAmountTotal) {
            netDepositInd = 1 ;
        }
        else {
            netDepositInd = 0;
        }
        return netDepositInd;
    }

    /**
     * @dev Calculate net amount 
     * @param _depositAmountTotal the total requested deposit amount by users.
     * @param _withdrawalAmountTotal the total requested withdrawal amount by users.
     * @param _maxDepositAmount the maximum accepted deposit amount by event.
     * @param _maxWithdrawalAmount the maximum accepted withdrawal amount by event.
     * @return net amount.
     */
    function calculateNetAmountEvent(uint256 _depositAmountTotal, 
        uint256 _withdrawalAmountTotal, uint256 _maxDepositAmount, 
        uint256 _maxWithdrawalAmount) external onlyInvestement returns(uint256) {
        _depositAmountTotal = Math.min(  _depositAmountTotal,
         _maxDepositAmount);
        _withdrawalAmountTotal =  (_withdrawalAmountTotal * tokenPrice) / FACTOR_PRICE_DECIMALS;
        _withdrawalAmountTotal= Math.min(_withdrawalAmountTotal,
        _maxWithdrawalAmount);
         uint256  _depositAmountTotalAfterFees = _depositAmountTotal - 
        ( _depositAmountTotal * depositFeeRate)/ FACTOR_FEES_DECIMALS;
        
        if (netDepositInd == 1) {
             netAmountEvent =  _depositAmountTotalAfterFees - _withdrawalAmountTotal;
        }
        else {
             netAmountEvent = _withdrawalAmountTotal - _depositAmountTotalAfterFees;
        
        }
        return netAmountEvent;
    }

    /**
     * @dev Protect against slippage due to assets sale.
     * @param _withdrawalAmount the value of sold assets in Stablecoin.
     * _withdrawalAmount has to be sent to the contract.
     * treasury has to approve the contract for both Stablecoin and token.
     * @return Missed amount to send to the contract due to slippage.
     */
    function protectAgainstSlippage(uint256 _withdrawalAmount) external onlyManager 
        returns (uint256) {
        require(_withdrawalAmount != 0, "Formation.Fi: zero amount");

        require(netDepositInd == 0, "Formation.Fi: no slippage");
       
       uint256 _amount = 0; 
       uint256 _deltaAmount =0;
       uint256 _slippage = 0;
       uint256  _tokenAmount = 0;
       uint256 _balanceTokenTreasury = token.balanceOf(treasury);
       uint256 _balanceStableTreasury = stableToken.balanceOf(treasury) * amountScaleDecimals;
      
        if (_withdrawalAmount< netAmountEvent){
            _amount = netAmountEvent - _withdrawalAmount;   
            _slippage = (_amount * FACTOR_FEES_DECIMALS ) / netAmountEvent;
            if (_slippage >= slippageTolerance) {
                return netAmountEvent;
            }
            else {
                 _deltaAmount = Math.min( _amount, _balanceStableTreasury);
                if ( _deltaAmount  > 0){
                    stableToken.safeTransferFrom(treasury, investement, _deltaAmount/amountScaleDecimals);
                    _tokenAmount = (_deltaAmount * FACTOR_PRICE_DECIMALS)/tokenPrice;
                    token.mint(treasury, _tokenAmount);
                    return _amount - _deltaAmount;
                }
                else {
                     return _amount; 
                }  
            }    
        
        }
        else  {
           _amount = _withdrawalAmount - netAmountEvent;   
          _tokenAmount = (_amount * FACTOR_PRICE_DECIMALS)/tokenPrice;
          _tokenAmount = Math.min(_tokenAmount, _balanceTokenTreasury);
          if (_tokenAmount >0) {
              _deltaAmount = (_tokenAmount * tokenPrice)/FACTOR_PRICE_DECIMALS;
              stableToken.safeTransfer(treasury, _deltaAmount/amountScaleDecimals);   
              token.burn( treasury, _tokenAmount);
            }
           if ((_amount - _deltaAmount) > 0) {
            
              stableToken.safeTransfer(safeHouse, (_amount - _deltaAmount)/amountScaleDecimals); 
            }
        }
        return 0;

    } 

     /**
     * @dev Send Stablecoin from the manager to the contract.
     * @param _amount  tha amount to send.
     */
    function sendStableTocontract(uint256 _amount) external 
     onlyManager {
      require( _amount > 0,  "Formation.Fi: zero amount");

      stableToken.safeTransferFrom(msg.sender, address(this),
       _amount/amountScaleDecimals);
    }

   
     /**
     * @dev Send Stablecoin from the contract to the contract Investement.
     */
    function sendStableFromcontract() external 
        onlyManager {
        require(investement != address(0),
            "Formation.Fi: zero address"
        );
         stableToken.safeTransfer(investement, stableToken.balanceOf(address(this)));
    }
  
}

// File: contracts_ETH/Gamma/AdminGamma.sol


pragma solidity ^0.8.4;


/** 
* @author Formation.Fi.
* @notice Implementation of the contract AdminGamma.
*/

contract AdminGamma is Admin {
    constructor(address _manager, address _treasury, address _stableToken,
     address _token) Admin(  _manager,  _treasury,  _stableToken,
     _token){
   }
}