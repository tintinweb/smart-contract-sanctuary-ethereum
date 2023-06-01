/**
 *Submitted for verification at Etherscan.io on 2023-06-01
*/

// SPDX-License-Identifier: MIT
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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

// File: contracts/Crowdsale.sol


pragma solidity ^0.8.0;



interface IVesting {
    struct VestingScheduleStruct {
        address beneficiaryAddress;
        uint256 icoStartDate;
        uint256 numberOfCliff;
        uint256 numberOfVesting;
        uint256 unlockRate;
        bool revoked;
        uint256 cliffAndVestingAllocation;
        uint256 vestingAllocation;
        uint256 claimedTokenAmount;
        bool tgeVested;
        uint256 releasedPeriod;
        uint256 icoType;
        uint256 investedUSDT;
    }

    function getBeneficiaryVesting(address beneficiary, uint256 icoType)
        external 
        view
        returns (VestingScheduleStruct memory);

    function createVestingSchedule(
        address _beneficiary,
        uint256 _numberOfCliffMonths,
        uint256 _numberOfVestingMonths,
        uint256 _unlockRate,
        uint256 _allocation,
        uint256 _IcoType,
        uint256 _investedUsdt,
        uint256 _icoStartDate
    ) external;

    function vestingRevocation(
        address _beneficiary, 
        uint256 _icoType,
        uint256 notVestedTokenAllocation
    ) external;

    function updateBuyTokens(
        address _beneficiary,
        uint256 _icoType,
        uint256 _tokenAmount,
        uint256 _totalVestingAllocation,
        uint256 _usdtAmount
    ) external;

    function getReleasableAmount(address _beneficiary, uint256 _icoType)
        external
        returns (uint256);
    
}

contract Crowdsale is Ownable {

    // Address where funds are collected as USDT
    address payable public usdtWallet;

    ERC20 public token;
    
    //usdt contract address
    IERC20 public usdt = IERC20(0x4C5DA3bF8A975D523baca06EeC71a24F8B9752DB);

    IVesting vestingContract;
    ICOdata[] private ICOdatas;

    uint256 private totalAllocation;
    uint256 private totalLeftover;

    mapping(uint256 => mapping(address => bool)) private whitelist;
    mapping(address => mapping(uint256 => bool)) private isIcoMember;
    mapping(uint256 => address[]) private icoMembers;
    
/*
* @EVENTS  
*/
//////////////////////////////////////////////////////////////////////////////////////////
    event processPurchaseTokenEvent(
        address _beneficiary,
        uint256 _icoType,
        uint256 releasedAmount
    );

    event priceChanged(string ICOname, uint256 oldPrice, uint256 newPrice);

    event createICOEvent(uint256 totalTokenAllocation, uint256 ICOsupply, uint256 totalTokenSupply);

    event updatePurchasingStateEvent(uint256 _icoType, string ICOname, uint256 ICOsupply, uint256 newICOtokenAllocated, uint256 tokenAmount, uint256 newICOusdtRaised, uint256 usdtAmount);
//////////////////////////////////////////////////////////////////////////////////////////

/*
* @MODIFIERS
*/
//////////////////////////////////////////////////////////////////////////////////////////

    //Checks whether the specific ICO sale is active or not
    modifier isSaleAvailable(uint256 _icoType) {
        ICOdata memory ico = ICOdatas[_icoType];
        require(ico.ICOstartDate != 0, "Ico does not exist !");
        require(
            ico.ICOstartDate >= block.timestamp,
            "ICO date expired."
        );
        require(
            ico.ICOstate == IcoState.active || ico.ICOstate == IcoState.onlyWhitelist,
            "Sale not available"
        );
        if (ico.ICOstate == IcoState.onlyWhitelist) {
            require(whitelist[_icoType][msg.sender], "Member is not in the whitelist");
        }
        _;
    }

    //Checks whether the specific sale is available or not
    modifier isClaimAvailable(uint256 _icoType) {
        ICOdata memory ico = ICOdatas[_icoType];

        require(ico.ICOstartDate != 0, "Ico does not exist !");
        
        require(
            ico.ICOstate != IcoState.nonActive,
            "Claim is currently stopped."
        );
        _;
    }

//////////////////////////////////////////////////////////////////////////////////////////

    //State of ICO sales
    enum IcoState {
        active,
        onlyWhitelist,
        nonActive,
        done
    }

    struct ICOdata {
        string ICOname;
        uint256 ICOsupply;
        uint256 ICOusdtRaised;
        uint256 ICOtokenAllocated;
        //total token claimed by beneficiaries
        uint256 ICOtokenSold;
        IcoState ICOstate;
        uint256 ICOnumberOfCliff;
        uint256 ICOnumberOfVesting;
        uint256 ICOunlockRate;
        uint256 ICOstartDate;
        //Absolute token price (tokenprice(USDT) * (10**6))
        uint256 TokenAbsoluteUsdtPrice;
        //If the team vesting data, should be free participation vesting for only to specific addresses
        uint256 IsFree;
    }

    struct VestingScheduleData {
        uint256 id;
        uint256 unlockDateTimestamp;
        uint256 tokenAmount;
        uint256 usdtAmount;
        uint256 vestingRate;
        bool collected;
    }

    /**
     * @param _token Address of the token being sold (token contract).
     * @param _usdtWallet Address where collected funds will be forwarded to.
     * @param _vestingContract Vesting contract address.
     */
    constructor(
        address _token,
        address payable _usdtWallet,
        address _vestingContract
    ) {
        require(
            address(_token) != address(0),
            "ERROR at Crowdsale constructor: Token contract address shouldn't be zero address."
        );
        require(
            _usdtWallet != address(0),
            "ERROR at Crowdsale constructor: USDT wallet address shouldn't be zero address."
        );
        require(
            _vestingContract != address(0),
            "ERROR at Crowdsale constructor: Vesting contract address shouldn't be zero address."
        );

        token = ERC20(_token);
        usdtWallet = _usdtWallet;
        totalAllocation = 0;
        vestingContract = IVesting(_vestingContract);
    }

    receive() external payable {}

    fallback() external payable {}

    function createICO(
        string calldata _name,
        uint256 _supply,
        uint256 _cliffMonths,
        uint256 _vestingMonths,
        uint8 _unlockRate,
        uint256 _startDate,
        uint256 _tokenAbsoluteUsdtPrice, //Absolute token price (tokenprice(USDT) * (10**6)), 0 if free
        uint256 _isFree //1 if free, 0 if not-free
    ) external onlyOwner {
        if (_isFree==0) {
            require(
                _tokenAbsoluteUsdtPrice > 0,
                "ERROR at createICO: Token price should be bigger than zero."
            );
        }
        require(
            _startDate >= block.timestamp,
            "ERROR at createICO: Start date must be greater than now."
        );
        require(
            totalAllocation + _supply <= (token.balanceOf(msg.sender)/(10**token.decimals())),
            "ERROR at createICO: Cannot create sale round because not sufficient tokens."
        );
        totalAllocation += _supply;

        ICOdatas.push(
            ICOdata({
                ICOname: _name,
                ICOsupply: _supply,
                ICOusdtRaised: 0,
                ICOtokenAllocated: 0,
                ICOtokenSold: 0,
                ICOstate: IcoState.nonActive,
                ICOnumberOfCliff: _cliffMonths,
                ICOnumberOfVesting: _vestingMonths,
                ICOunlockRate: _unlockRate,
                ICOstartDate: _startDate,
                TokenAbsoluteUsdtPrice: _tokenAbsoluteUsdtPrice,
                IsFree: _isFree
            })
        );
        emit createICOEvent(totalAllocation,_supply,token.balanceOf(msg.sender));
    }

    /**
     * @dev Client function. Buyer can buy tokens and personalized vesting schedule is created.
     * @param _icoType Ico type  ex.: 0=>seed, 1=>private
     * @param _usdtAmount Amount of invested USDT
     */
    function buyTokens(uint256 _icoType, uint256 _usdtAmount)
        public 
        isSaleAvailable(_icoType)
    {
        ICOdata memory ico = ICOdatas[_icoType];
        address beneficiary = msg.sender;

        require(
            ico.IsFree == 0,
            "ERROR at buyTokens: This token distribution is exclusive to the team only."
        );

        uint256 tokenAmount = _getTokenAmount(
            _usdtAmount,
            ico.TokenAbsoluteUsdtPrice
        );

        _preValidatePurchase(beneficiary, tokenAmount, _icoType);

        if (
            vestingContract
                .getBeneficiaryVesting(beneficiary, _icoType)
                .beneficiaryAddress == address(0x0)
        ) {
            vestingContract.createVestingSchedule(
                beneficiary,
                ico.ICOnumberOfCliff,
                ico.ICOnumberOfVesting,
                ico.ICOunlockRate,
                tokenAmount,
                _icoType,
                _usdtAmount,
                ico.ICOstartDate
            );
        } else {

            require(
                !vestingContract
                    .getBeneficiaryVesting(beneficiary, _icoType)
                    .revoked,
                "ERROR at additional buyTokens: Vesting Schedule is revoked."
            );

            uint256 totalVestingAllocation = (tokenAmount -
                (ico.ICOunlockRate * tokenAmount) /
                100);

            vestingContract.updateBuyTokens(
                beneficiary,
                _icoType,
                tokenAmount,
                totalVestingAllocation,
                _usdtAmount
            );

        }

        _updatePurchasingState(_usdtAmount, tokenAmount, _icoType);
        _forwardFunds(_usdtAmount);

        if (isIcoMember[beneficiary][_icoType] == false) {
            isIcoMember[beneficiary][_icoType] = true;
            icoMembers[_icoType].push(address(beneficiary));
        }
    }

    /**
     * @dev Owner function. Owner can specify vesting schedule properties through parameters and personalized vesting schedule is created.
     */
    function addingTeamMemberToVesting(
        address _beneficiary,
        uint256 _icoType,
        uint256 _tokenAmount
    ) public onlyOwner isSaleAvailable(_icoType) {
        ICOdata memory ico = ICOdatas[_icoType];
        
        require(
            ico.IsFree==1,
            "ERROR at addingTeamParticipant: Please give correct sale type."
        );
        
        _preValidatePurchase(_beneficiary, _tokenAmount, _icoType);
        
        require(
            !isIcoMember[_beneficiary][_icoType],
            "ERROR at addingTeamParticipant: Beneficiary has already own vesting schedule."
        );

        vestingContract.createVestingSchedule(
            _beneficiary,
            ico.ICOnumberOfCliff,
            ico.ICOnumberOfVesting,
            ico.ICOunlockRate,
            _tokenAmount,
            _icoType,
            0,
            ico.ICOstartDate
        );
        _updatePurchasingState(0, _tokenAmount, _icoType);
        isIcoMember[_beneficiary][_icoType] = true;
        icoMembers[_icoType].push(address(_beneficiary));

    }
    
    /**
     * @dev Client function. Buyer can claim vested tokens according to own vesting schedule.
     */
    function claimAsToken(uint256 _icoType)
        public
        isClaimAvailable(_icoType)
    {
        address beneficiary = msg.sender;

        require(
            isIcoMember[beneficiary][_icoType],
            "ERROR at claimAsToken: You are not the member of this sale."
        );
        require(
            !vestingContract
                .getBeneficiaryVesting(beneficiary, _icoType)
                .revoked,
            "ERROR at claimAsToken: Vesting Schedule is revoked."
        );
        uint256 releasableAmount = vestingContract.getReleasableAmount(
            beneficiary,
            _icoType
        );
        require(
            releasableAmount > 0,
            "ERROR at claimAsToken: Releasable amount is 0."
        );

        _processPurchaseToken(beneficiary, _icoType, releasableAmount);
        ICOdatas[_icoType].ICOtokenSold += releasableAmount;
    }

    
    function revoke(address _beneficiary, uint256 _icoType) external onlyOwner {
        IVesting.VestingScheduleStruct memory vestingSchedule = vestingContract.getBeneficiaryVesting(_beneficiary,_icoType);
        ICOdata storage icoData = ICOdatas[_icoType];
        
        require(
            vestingSchedule.icoStartDate != 0,
            "ERROR at revoke: Vesting does not exist."
        );

        require(
            !vestingSchedule.revoked,
            "ERROR at revoke: Vesting Schedule has already revoked."
        );

        uint256 notVestedTokenAllocation = 0;

        //ico is not started yet
        if(block.timestamp < vestingSchedule.icoStartDate){
            icoData.ICOtokenAllocated -= vestingSchedule.cliffAndVestingAllocation;
        }
        //ico is started, not vested amount calc must be done 
        else{
            uint256 releasableAmount = vestingContract.getReleasableAmount(_beneficiary, _icoType);

            //if any vested tokens exist, transfers
            if(releasableAmount > 0){
                _processPurchaseToken(_beneficiary, _icoType, releasableAmount);
                icoData.ICOtokenSold += releasableAmount;
            }

            //not vested tokens calculated to reallocate icodata allocation
            if(vestingSchedule.cliffAndVestingAllocation > vestingSchedule.claimedTokenAmount+releasableAmount){
                notVestedTokenAllocation += (vestingSchedule.cliffAndVestingAllocation - vestingSchedule.claimedTokenAmount - releasableAmount);
            }

            icoData.ICOtokenAllocated -= notVestedTokenAllocation;
            
            /*
            //to check any deviation 
            if(icoData.ICOtokenAllocated > notVestedTokenAllocation){
                icoData.ICOtokenAllocated -= notVestedTokenAllocation;
            }else{
                icoData.ICOtokenAllocated=0;
            }*/
        }
        //vesting schedule structında değişiklikler yapılmak üzere çağrılır.
        vestingContract.vestingRevocation(_beneficiary,_icoType,notVestedTokenAllocation);
    }

    /**
     * @dev Changes sale round state.
     */
    function changeIcoState(uint256 _icoType, IcoState _icoState)
        external
        onlyOwner
    {
        ICOdata storage ico = ICOdatas[_icoType];

        require(ico.ICOstartDate != 0, "Ico does not exist !");

        ico.ICOstate = _icoState;

        if (_icoState == IcoState.done) {
            uint256 saleLeftover= ico.ICOsupply -
                ico.ICOtokenAllocated;

            ico.ICOsupply -= saleLeftover;
            totalLeftover +=saleLeftover;
        }
    }

    /**
     * @dev Increments the supply of a specified type of ICO round.
     */
    function increaseIcoSupplyWithLeftover(uint256 _icoType, uint256 amount)
        external
        onlyOwner
    {
        require(
            ICOdatas[_icoType].ICOstartDate != 0,
            "ERROR at increaseIcoSupplyWithLeftover: Ico does not exist."
        );
        require(
            ICOdatas[_icoType].ICOstate != IcoState.done,
            "ERROR at increaseIcoSupplyWithLeftover: ICO is already done."
        );
        require(
            totalLeftover >= amount,
            "ERROR at increaseIcoSupplyWithLeftover: Not enough leftover."
        );
        ICOdatas[_icoType].ICOsupply += amount;
        totalLeftover -= amount;
    }

    /*
     * @dev Owner can add multiple addresses to whitelist.
     */
    function addToWhitelist(address[] calldata _beneficiaries, uint256 _icoType)
        external 
        onlyOwner
    {
        for (uint256 i = 0; i < _beneficiaries.length; i++) {
            require(!isWhitelisted(_beneficiaries[i], _icoType), "Already whitelisted");
            whitelist[_icoType][_beneficiaries[i]] = true;
        }
    }

    /**
     * @dev Owner function. Set usdt wallet address.
     * @param _usdtWallet New USDT wallet address.
     */
    function setUSDTWallet(address payable _usdtWallet)
        public
        onlyOwner
    {
        require(
            _usdtWallet != address(0),
            "ERROR at Crowdsale setUSDTWallet: USDT wallet address shouldn't be zero."
        );
        usdtWallet = _usdtWallet;
    }

    /**
     * @dev Owner function. Change IWPA token contract address.
     * @param _token New IWPA token contract address.
     */
    function setTokenContract(address _token) external onlyOwner {
        require(
            _token != address(0),
            "ERROR at Crowdsale setTokenContract: IWPA Token contract address shouldn't be zero."
        );
        token = ERC20(_token);
    }

    /**
     * @dev Owner function. Change vesting contract address.
     * @param _vesting New vesting contract address.
     */
    function setVestingContract(address _vesting)
        external
        onlyOwner
    {
        require(
            _vesting != address(0),
            "ERROR at Crowdsale setVestingContract: Vesting contract address shouldn't be zero address."
        );
        vestingContract = IVesting(_vesting);
    }

    function setUsdtContract(address _usdt)
        external
        onlyOwner
    {
        require(
            _usdt != address(0),
            "ERROR at Crowdsale setUsdtContract: Usdt contract address shouldn't be zero address."
        );
        usdt = ERC20(_usdt);
    }

/*
* @INTERNALS
*/
//////////////////////////////////////////////////////////////////////////////////////////

    /**
     * @dev Validation of an incoming purchase request. Use require statements to revert state when conditions are not met.
     * @param _beneficiary Address performing the token purchase
     * @param _tokenAmount Token amount that beneficiary can buy
     * @param _icoType To specify type of the ICO sale.
     */
    function _preValidatePurchase(
        address _beneficiary,
        uint256 _tokenAmount,
        uint256 _icoType
    ) internal view {
        require(_beneficiary != address(0));
        require(
            _tokenAmount > 0,
            "You need to send at least some USDT to buy tokens."
        );
        require(
            ICOdatas[_icoType].ICOtokenAllocated + _tokenAmount <=
                ICOdatas[_icoType].ICOsupply,
            "Not enough token in the ICO supply"
        );
    }

    /**
     * @dev Transferring vested tokens to the beneficiary.
     */
    function _processPurchaseToken(
        address _beneficiary,
        uint256 _icoType,
        uint256 _releasableAmount
    ) internal {
        token.transferFrom(owner(), _beneficiary, _releasableAmount*(10**token.decimals()));
        emit processPurchaseTokenEvent(_beneficiary, _icoType, _releasableAmount);
    }

    /**
     * @dev Update current beneficiary contributions to the ICO sale.
     * @param _usdtAmount Value in USDT involved in the purchase.
     * @param _tokenAmount Number of tokens to be purchased.
     * @param _icoType To specify type of the ICO sale.
     */
    function _updatePurchasingState(
        uint256 _usdtAmount,
        uint256 _tokenAmount,
        uint256 _icoType
    ) internal {
        ICOdata storage ico = ICOdatas[_icoType];
        ico.ICOtokenAllocated += _tokenAmount;
        ico.ICOusdtRaised += _usdtAmount;

        emit updatePurchasingStateEvent(_icoType, ico.ICOname, ico.ICOsupply, ico.ICOtokenAllocated, _tokenAmount, ico.ICOusdtRaised, _usdtAmount);
    }

    /**
     * @dev Returns token amount of the USDT investing.
     * @param _usdtAmount Value in USDT to be converted into tokens.
     * @param _absoluteUsdtPrice Absolute usdt value of token (Actual token usdt price * 10**6)
     * @return Number of tokens that can be purchased with the specified _usdtAmount.
     */
    function _getTokenAmount(uint256 _usdtAmount, uint256 _absoluteUsdtPrice)
        internal
        pure
        returns (uint256)
    {
        _usdtAmount = _usdtAmount * (10**6);
        _usdtAmount = _usdtAmount / _absoluteUsdtPrice;
        return _usdtAmount;
    }

    /**
     * @dev After buy tokens, beneficiary USDT amount transferring to the usdtwallet.
     */
    function _forwardFunds(uint usdtAmount) internal {
        usdt.transferFrom(msg.sender, usdtWallet, usdtAmount*(10**6));
    }

//////////////////////////////////////////////////////////////////////////////////////////

/*
 * @VIEWS
*/
//////////////////////////////////////////////////////////////////////////////////////////

    /**
     * @dev Returns the leftover value.
     */
    function getLeftover()
        external
        view
        returns (uint256)
    {
        return totalLeftover;
    }

    function isWhitelisted(address _beneficiary, uint256 _icoType)
        public
        view
        returns (bool)
    {
        return whitelist[_icoType][_beneficiary] == true;
    }

    /**
     * @dev Returns the members of the specified ICO round.
     */
    function getICOMembers(uint256 _icoType)
        external
        view
        returns (address[] memory)
    {
        require(icoMembers[_icoType].length > 0, "There is no member in this sale.");
        return icoMembers[_icoType];
    }

    /**
     * @dev Returns details of each vesting stages.
     */
    function getVestingList(address _beneficiary, uint256 _icoType)
        external
        view
        returns (VestingScheduleData[] memory)
    {
        require(isIcoMember[_beneficiary][_icoType] == true,"ERROR at getVestingList: You are not the member of this sale.");

        ICOdata memory icoData = ICOdatas[_icoType];

        require(icoData.ICOstartDate != 0, "ICO does not exist");
        
        uint256 size = icoData.ICOnumberOfVesting + 1;

        VestingScheduleData[] memory scheduleArr = new VestingScheduleData[](
            size
        );

        IVesting.VestingScheduleStruct memory vesting = vestingContract.getBeneficiaryVesting(
            _beneficiary,
            _icoType
        );

        uint256 cliffUnlockDateTimestamp = icoData.ICOstartDate;

        uint256 cliffTokenAllocation = (vesting.cliffAndVestingAllocation *
            icoData.ICOunlockRate) / 100;
        
        uint256 cliffUsdtAllocation = (cliffTokenAllocation *
            icoData.TokenAbsoluteUsdtPrice) / 10**6;
        
        scheduleArr[0] = VestingScheduleData({
            id: 0,
            unlockDateTimestamp: cliffUnlockDateTimestamp,
            tokenAmount: cliffTokenAllocation,
            usdtAmount: cliffUsdtAllocation,
            vestingRate: icoData.ICOunlockRate * 1000,
            collected: vesting.tgeVested
        });

        uint256 vestingRateAfterCliff = (1000 * (100 - icoData.ICOunlockRate)) /
            icoData.ICOnumberOfVesting;

        uint256 usdtAmountAfterCliff = (vesting.investedUSDT -
            cliffUsdtAllocation) / icoData.ICOnumberOfVesting;
        uint256 tokenAmountAfterCliff = vesting.vestingAllocation /
            icoData.ICOnumberOfVesting;
        cliffUnlockDateTimestamp += (30 days * icoData.ICOnumberOfCliff);
        
        for (uint256 i = 0; i < icoData.ICOnumberOfVesting; ++i) {
            bool isCollected=false;
            if(i<vesting.releasedPeriod){
                isCollected=true;
            }
            cliffUnlockDateTimestamp += 30 days;
            scheduleArr[i + 1] = VestingScheduleData({
                id: i + 1,
                unlockDateTimestamp: cliffUnlockDateTimestamp,
                tokenAmount: tokenAmountAfterCliff,
                usdtAmount: usdtAmountAfterCliff,
                vestingRate: vestingRateAfterCliff,
                collected: isCollected
            });
        }
        return scheduleArr;
    }

    /**
     * @dev Returns details of ICOs.
     */
    function getICODatas() external view returns (ICOdata[] memory) {
        return ICOdatas;
    }

//////////////////////////////////////////////////////////////////////////////////////////
}