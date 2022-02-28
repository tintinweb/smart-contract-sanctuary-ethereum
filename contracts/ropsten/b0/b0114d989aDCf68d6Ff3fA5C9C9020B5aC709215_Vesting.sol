// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Vesting is Ownable {

    mapping(address => bool) proxyToApproved; // proxy allowance for interaction with contract
    address[] public Admins;
    mapping(address => bool) public AdminByAddr;

    struct Beneficiary {
        uint256 lastClaimDate;
        uint256 vestingAmount;
        uint256 start;
    }

    // beneficiary of tokens after they are released
    mapping(address => Beneficiary) public Beneficiaries;
    mapping(uint256 => address) public BeneficiaryWallets;
    mapping(address => uint256) public ClaimedBalance;
    uint256 public beneficiaryCount;
    uint256 public vestingPeriod; // seconds
    uint256 public claimInterval; // seconds

    ERC20 public token;

    // _vestingPeriod and _claimInterval are input in weeks
    constructor(uint256 _vestingPeriod, uint256 _claimInterval, address _token) {
        vestingPeriod = _vestingPeriod * 1 weeks;
        token = ERC20(_token);
        claimInterval = _claimInterval * 1 weeks;
    }     

    function deposit() external {
        require(Beneficiaries[_msgSender()].vestingAmount == 0, "DEPOSIT_EXISTS");
        uint256 bal = token.balanceOf(_msgSender());
        require(bal > 999000000000000000000, "BALANCE_TOO_LOW");
        if (bal > 19999000000000000000000) {        //20,000
            bal = bal * 90 / 100; // lock 90%
        } else if (bal > 9999000000000000000000) {  //10,000
            bal = bal * 80 / 100; // lock 80%
        } else if (bal > 4999000000000000000000) {  //5,000
            bal = bal * 75 / 100; // lock 75%
        } else if (bal > 1999000000000000000000) {  //2,000
            bal = bal * 50 / 100; // lock 50%
        } else if (bal > 999000000000000000000) {   //1,000
            bal = bal * 25 / 100; // lock 25%
        }
        token.transferFrom(_msgSender(), address(this), bal);
        Beneficiaries[_msgSender()] = Beneficiary({
            lastClaimDate: 0,
            vestingAmount: bal,
            start: block.timestamp
        });       
        beneficiaryCount++;
        BeneficiaryWallets[beneficiaryCount] = _msgSender();
        emit Deposit(_msgSender(), bal); 
    }

    function depositAmount(uint256 amount) external {
        require(Beneficiaries[_msgSender()].vestingAmount == 0, "DEPOSIT_EXISTS");
        token.transferFrom(_msgSender(), address(this), amount);
        Beneficiaries[_msgSender()] = Beneficiary({
            lastClaimDate: 0,
            vestingAmount: amount,
            start: block.timestamp
        });       
        beneficiaryCount++;
        BeneficiaryWallets[beneficiaryCount] = _msgSender();
        emit DepositAmount(_msgSender(), amount);         
    }    

    function claim(address _address) external {
        require(_msgSender() == _address || proxyToApproved[_msgSender()], "NOT_APPROVED");
        Beneficiary storage beneficiary = Beneficiaries[_address];
        require(beneficiary.vestingAmount > 0, "USER_NOT_BENEFICIARY");
        uint256 beneficiaryAccrualEnd = beneficiary.start + vestingPeriod;
        uint256 accrualEndCalculation = block.timestamp >= beneficiaryAccrualEnd
            ? beneficiaryAccrualEnd
            : block.timestamp;
        uint256 checkBalance = 
            (((accrualEndCalculation - (beneficiary.lastClaimDate == 0
            ? beneficiary.start : beneficiary.lastClaimDate)) / claimInterval) * claimInterval * beneficiary.vestingAmount) /
            vestingPeriod;
        require(checkBalance > 0, "NO_BALANCE_ACCRUED");
        uint256 passedClaimIntervals = block.timestamp >= beneficiary.start + vestingPeriod
            ? vestingPeriod
            : (block.timestamp - beneficiary.start) / claimInterval;
        beneficiary.lastClaimDate =
            beneficiary.start +
            passedClaimIntervals *
            claimInterval;
        token.transfer(_address, checkBalance);
        ClaimedBalance[_address] += checkBalance;
        emit Claim(_msgSender(), _address, checkBalance);
    }

    function accruedBalanceOf(address beneficiaryAddress) public view returns (uint256) {
        Beneficiary memory beneficiary = Beneficiaries[beneficiaryAddress];
        require(beneficiary.vestingAmount > 0, "USER_NOT_BENEFICIARY");
        uint256 beneficiaryAccrualEnd = beneficiary.start + vestingPeriod;
        uint256 accrualEndCalculation = block.timestamp >= beneficiaryAccrualEnd
            ? beneficiaryAccrualEnd
            : block.timestamp;
        return
            (((accrualEndCalculation - (beneficiary.lastClaimDate == 0
            ? beneficiary.start : beneficiary.lastClaimDate)) / claimInterval) * claimInterval * beneficiary.vestingAmount) /
            vestingPeriod;
    }

    function isBeneficiary(address beneficiaryAddress) external view returns(bool) {
        return Beneficiaries[beneficiaryAddress].vestingAmount > 0;
    }

    // seconds until next claim
    function getPendingInterval(address beneficiaryAddress) external view returns(uint256) {
        Beneficiary memory beneficiary = Beneficiaries[beneficiaryAddress];
        uint256 passedClaimIntervals = block.timestamp >= beneficiary.start + vestingPeriod
            ? vestingPeriod
            : (block.timestamp - beneficiary.start) / claimInterval;
        uint256 nextClaim = claimInterval * passedClaimIntervals + beneficiary.start + claimInterval;
        return block.timestamp > nextClaim - block.timestamp
            ? nextClaim - block.timestamp : 0;
    }

    /****************/
    /*   SETTERS    */
    /****************/

    // set vesting period; set to 0 to make all tokens claimable
    function setVestingPeriod(uint256 _period) external onlyAdmin {
        require(_period < vestingPeriod, "CANNOT_INCREASE_PERIOD");
        vestingPeriod = _period;
        emit SetVestingPeriod(_msgSender(), _period);
    }

    function setClaimInterval(uint256 _interval) external onlyAdmin {
        claimInterval = _interval;
        emit SetClaimInterval(_msgSender(), _interval);
    }

    function setToken(address _token) external onlyAdmin {
        token = ERC20(_token);
        emit SetToken(_msgSender(), _token);
    }

    function flipProxyState(address proxyAddress) public onlyAdmin {
        proxyToApproved[proxyAddress] = !proxyToApproved[proxyAddress];
        emit FlipProxyState(_msgSender(), proxyAddress, proxyToApproved[proxyAddress]);
    }

    function releaseVesting(address beneficiaryAddress) external onlyAdmin {
        require(Beneficiaries[beneficiaryAddress].vestingAmount > 0, "USER_NOT_BENEFICIARY");
        uint256 balance = Beneficiaries[beneficiaryAddress].vestingAmount - ClaimedBalance[beneficiaryAddress];
        if (balance > 0) {
            token.transfer(beneficiaryAddress, balance);
            ClaimedBalance[beneficiaryAddress] = Beneficiaries[beneficiaryAddress].vestingAmount;            
        }
        emit ReleaseVesting(_msgSender(), beneficiaryAddress, balance);
    }

    function setAdmins(address[] memory _Admins) external onlyAdmin {
        _setAdmins(_Admins);
    }

    function _setAdmins(address[] memory _Admins) internal {
        for (uint256 i = 0; i < Admins.length; i++) {
            AdminByAddr[Admins[i]] = false;
        }

        for (uint256 j = 0; j < _Admins.length; j++) {
            AdminByAddr[_Admins[j]] = true;
        }
        Admins = _Admins;
        emit SetAdmins(_Admins);
    }

    function getAdmins() external view returns (address[] memory) {
        return Admins;
    }    

    modifier onlyAdmin() {
        require(AdminByAddr[_msgSender()] == true || _msgSender() == owner(), "onlyAdmin");
        _;
    }    

    event Deposit(address indexed user, uint256 indexed bal);
    event DepositAmount(address indexed user, uint256 indexed amount);
    event Claim(address indexed user, address indexed beneficiary, uint256 indexed checkBalance);
    event SetVestingPeriod(address indexed user, uint256 indexed _period);
    event SetClaimInterval(address indexed user, uint256 indexed interval);
    event SetToken(address indexed user, address indexed _token);
    event FlipProxyState(address indexed user, address indexed proxyAddress, bool indexed newState);
    event ReleaseVesting(address indexed user, address indexed beneficiary, uint256 indexed amount);
    event SetAdmins(address[] Admins);
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