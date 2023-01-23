/**
 *Submitted for verification at Etherscan.io on 2023-01-23
*/

// SPDX-License-Identifier: MIT

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.11;


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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.11;

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

pragma solidity ^0.8.11;


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


// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.11;




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

// File: FTC Test/AHSToken.sol


pragma solidity ^0.8.11;
pragma abicoder v2;


contract AHSToken is ERC20 {
     address public admin;

    mapping(address => uint256) public investors;
    mapping(address => uint256) internal acceptableTokens;
    address[] internal acceptableTokensList;


    uint256 internal penaltyPercentage;
    uint256 internal totalInvestment;
    uint256 internal totalInvestors;
    uint256 internal totalAllocatedProfit;
    uint256 internal maxPeriod = 730;

    uint256 internal minInvest = 100000000;
    uint256 internal minPeriod = 2;
    uint256 internal profitPerDayWithoutReferral = 10;
    uint256 internal profitPerDayWithReferral = 15;
    uint256 internal referralProfit = 100;
    uint256 internal monthlyCoeficient = 50;
    uint256 internal payProfitPeriod = 2;
    uint256 internal fee = 2;

    struct InvestingInfo {
        uint256 investedAt;
        uint256 endAt;
        uint256 amount;
        uint256 period;
        uint256 payProfitPeriod;
        address referral;
        uint256 lastSettlementAt;
        uint256 settledTill;
        uint256 receivedProfits;
        uint256 profitPercentPerDay;
        uint256 profitPercentPerExtraDays;
    }

    mapping(address => address) internal referrals;
    mapping(address => InvestingInfo[]) public investings;
    mapping(address => InvestingInfo[]) public investmentHistory;
    mapping(address => uint256) public withdrawable;
    mapping(address => uint256) public numOfReferrees;

    constructor(uint256 initialSupply) ERC20("ysh", "YSH") {
        _setOwner(msg.sender);
        _mint(msg.sender, initialSupply);
    }

    function decimals() public view virtual override returns (uint8) {
        return 6;
    }

    modifier isOwner() {
        _isOwner();
        _;
    }

    function _isOwner() internal view virtual {
        require(_msgSender() == _getOwner(), "Caller is not owner");
    }

    function _getOwner() internal view returns (address) {
        return admin;
    }

    function setOwner(address _address) external isOwner returns(bool _result){
        admin = _address;
        _result=true;
    }

    function _setOwner(address _address) internal {
        admin =_address;
    }

    modifier userExists(address _address) {
        _userExists(_address);
        _;
    }

    function _userExists(address _address) internal view virtual {
        require(investors[_address] != 0, "User is not registered!");
    }

    modifier tokenNotExists(address _address) {
        _tokenNotExists(_address);
        _;
    }

    function _tokenNotExists(address _address) internal view virtual {
        require(acceptableTokens[_address] == 0, "Already exists!");
    }


     modifier tokenExists(address _address) {
        _tokenExists(_address);
        _;
    }

    function _tokenExists(address _address) internal view virtual {
        require(acceptableTokens[_address] != 0, "Not exists!");
    }

    modifier notMe(address _address) {
        _notMe(_address);
        _;
    }

    function _notMe(address _address) internal view virtual {
        require(_msgSender() != _address, "You can not be your own referral!");
    }    

    function numOfActiveInvestings() external view returns (uint256 _num) {
        _num = investings[_msgSender()].length;
    }

    function numOfUserActiveInvestings(address address_)
        external
        view
        isOwner
        returns (uint256 _num)
    {
        _num = investings[address_].length;
    }


    function _getInvestingOverview(address address_)
        internal
        view
        returns (uint256 _totalInvestment, uint256 _totalReceivedProfit)
    {
        InvestingInfo[] memory tmp = investings[address_];
        for (uint256 i; i < tmp.length; ++i) {
            _totalInvestment += tmp[i].amount;
            _totalReceivedProfit += tmp[i].receivedProfits;
        }
    }

    function myInvestingOverview()
            external
            view
            userExists(_msgSender())
            returns (uint256 _totalInvestment, uint256 _totalReceivedProfit)
        {

            (_totalInvestment, _totalReceivedProfit) = _getInvestingOverview(
               _msgSender()
            );
        }


    function myInvestingInfo(uint256 i_)
        external
        view
        returns (
           
            address 
        )
    {
        return _msgSender();
        // _userExists(_msgSender());
        // InvestingInfo memory _info = investings[_msgSender()][i_];

        // _investedAt = _info.investedAt;
        // _endAt = _info.endAt;
    }

    function getInvestingInfo(address _address, uint256 i_)
        external
        view
        isOwner
        returns (
            uint256 _investedAt,
            uint256 _endAt
        )
    {
        InvestingInfo[] memory tmp = investings[_address];

        _investedAt = tmp[i_].investedAt;
        _endAt = tmp[i_].endAt;       
    }

    function getInvestingInfo_2(address _address, uint256 i_)
        external
        view
        isOwner
        returns (uint256 _investedAt, uint256 _endAt)
    {
        InvestingInfo[] memory tmp = investings[_address];

        _investedAt = tmp[i_].investedAt;
        _endAt = tmp[i_].endAt;
    }

    function getInvestingInfo_3(address _address, uint256 i_)
        external
        view
        returns (uint256 _investedAt, uint256 _endAt)
    {
        InvestingInfo[] memory tmp = investings[_address];

        _investedAt = tmp[i_].investedAt;
        _endAt = tmp[i_].endAt;
    }

    function getInvestingInfo_tuple(address _address, uint256 i_)
        external
        view
        isOwner
        returns (InvestingInfo memory _info)
    {
        _info = investings[_address][i_];
    }

    function getInvestingInfo_tuple22(address _address, uint256 i_)
        external
        view
        returns (InvestingInfo memory _info)
    {
        _info = investings[_address][i_];
    }



 function getInvestingInfo_tuple33(address _address) external view returns (uint256 ,uint256 ,uint256,uint256,uint256 ,InvestingInfo[] memory) {
        InvestingInfo[] memory _info = investings[_address];
        uint256 l = _info.length;
        uint256 l2 = investings[_address].length;
        InvestingInfo[] memory items = new InvestingInfo[](l);

        for (uint256 i = 0; i < l; i++) {
            items[i] = _info[i];
        }
        
        uint256 l3=items.length;
        uint256 l4=items[0].investedAt;
        uint256 l5=_info[0].endAt;
        return (l,l2,l3,l4,l5,items);
    }




    function getInvestingOverview(address address_)
        external
        view
        isOwner
        userExists(address_)
        returns (uint256 _totalInvestment, uint256 _totalReceivedProfit)
    {
        (_totalInvestment, _totalReceivedProfit) = _getInvestingOverview(
            address_
        );
    }

    

    function getMyWithdrawableBalance()
        external
        view
        returns (uint256 _withdrawable)
    {
        _withdrawable = _getUserWithdrawableBalance(_msgSender());
    }

    function getUserWithdrawableBalance(address address_)
        external
        view
        isOwner
        returns (uint256 _withdrawable)
    {
        _withdrawable = _getUserWithdrawableBalance(address_);
    }

    function _getUserWithdrawableBalance(address address_)
        internal
        view
        returns (uint256 _withdrawable)
    {
        _withdrawable = withdrawable[address_];
    }

    function getTotalAllocatedProfit()
        external
        view
        returns (uint256 _totalAllocatedProfit)
    {
        _totalAllocatedProfit = totalAllocatedProfit;
    }

    function getTotalInvestments()
        external
        view
        returns (uint256 _totalInvestments)
    {
        _totalInvestments = totalInvestment;
    }

    function getpenaltyPercentage()
        external
        view
        returns (uint256 _penaltyPercentage)
    {
        _penaltyPercentage = penaltyPercentage;
    }

    function setPenaltyPercentage(uint256 penaltyPercentage_)
        external
        isOwner
        returns (bool _result)
    {
        penaltyPercentage = penaltyPercentage_;
        _result = true;
    }

    function getTotalInvestors()
        external
        view
        isOwner
        returns (uint256 _totalInvestors)
    {
        _totalInvestors = totalInvestors;
    }

    function getSetting()
        external
        view
        returns (
            uint256 _minInvest,
            uint256 _minPeriod,
            uint256 _profitPerDayWithoutReferral,
            uint256 _profitPerDayWithReferral,
            uint256 _referralProfit,
            uint256 _monthlyCoeficient,
            uint256 _payProfitPeriod,
            uint256 _fee
        )
    {
        _minInvest = minInvest;
        _minPeriod = minPeriod;
        _profitPerDayWithoutReferral = profitPerDayWithoutReferral;
        _profitPerDayWithReferral = profitPerDayWithReferral;
        _referralProfit = referralProfit;
        _monthlyCoeficient = monthlyCoeficient;
        _payProfitPeriod = payProfitPeriod;
        _fee = fee;
    }

    function setMinInvest(uint256 minInvest_)
        external
        isOwner
        returns (bool _result)
    {
        minInvest = minInvest_;
        _result = true;
    }

    function setMinPeriod(uint256 minPeriod_)
        external
        isOwner
        returns (bool _result)
    {
        minPeriod = minPeriod_;
        _result = true;
    }

    function setProfitPerDayWithoutReferral(
        uint256 profitPerDayWithoutReferral_
    ) external isOwner returns (bool _result) {
        profitPerDayWithoutReferral = profitPerDayWithoutReferral_;
        _result = true;
    }

    function setProfitPerDayWithReferral(uint256 profitPerDayWithReferral_)
        external
        isOwner
        returns (bool _result)
    {
        profitPerDayWithReferral = profitPerDayWithReferral_;
        _result = true;
    }

    function setReferralProfit(uint256 referralProfit_)
        external
        isOwner
        returns (bool _result)
    {
        referralProfit = referralProfit_;
        _result = true;
    }

    function setMonthlyCoeficient(uint256 monthlyCoeficient_)
        external
        isOwner
        returns (bool _result)
    {
        monthlyCoeficient = monthlyCoeficient_;
        _result = true;
    }

    function setPayProfitPeriod(uint256 payProfitPeriod_)
        external
        isOwner
        returns (bool _result)
    {
        payProfitPeriod = payProfitPeriod_;
        _result = true;
    }

    function setFee(uint256 fee_) external isOwner returns (bool _result) {
        fee = fee_;
        _result = true;
    }

    function myInvestmentHistory()
        external
        view
        returns (InvestingInfo[] memory _history)
    {
        _history = getinvestmentHistory(_msgSender());
    }

    function getUserInvestmentHistory(address address_)
        external
        view
        isOwner
        returns (InvestingInfo[] memory _history)
    {
        _history = getinvestmentHistory(address_);
    }

    function getinvestmentHistory(address address_)
        internal
        view
        returns (InvestingInfo[] memory _history)
    {
        _history = investmentHistory[address_];
    }

    function checkReferral() external view returns (address _referral) {
        require(referrals[_msgSender()] != address(0), "Not set yet!");
        _referral = referrals[_msgSender()];
    }

    function addToken(address address_, uint256 rate_)
        external
        isOwner
        tokenNotExists(address_)
        returns (bool _result)
    {
        require(address_ != address(0), "Token is not acceptable!");
        require(rate_ != 0, "Rate is not acceptable!");

        acceptableTokens[address_] = rate_;
        acceptableTokensList.push(address_);
        _result = true;
    }

    function getAcceptableTokensList()
        external
        view
        returns (address[] memory _tokens)
    {
        _tokens = acceptableTokensList;
    }

    function getTokenRate(address address_)
        external
        view
        tokenExists(address_)
        returns (uint256 _rate)
    {
        _rate = acceptableTokens[address_];
    }

    function numOfMyReferrees() external view returns (uint256 _referees) {
        _referees = numOfUserReferrees(_msgSender());
    }

    function getNumOfUserReferrees(address address_)
        external
        view
        isOwner
        returns (uint256 _referees)
    {
        _referees = numOfUserReferrees(address_);
    }

    function numOfUserReferrees(address address_)
        internal
        view
        returns (uint256 _referees)
    {
        _referees = numOfReferrees[address_];
    }

    function changeTokenRate(address address_, uint256 rate_)
        external
        isOwner
        tokenExists(address_)
        returns (bool _result)
    {
        require(rate_ != 0, "Rate is not acceptable!");

        acceptableTokens[address_] = rate_;
        _result = true;
    }

    function buy(address tokenToSend_, uint256 amount_)
        external
        tokenExists(tokenToSend_)
        returns (bool _result)
    {
        require(amount_ != 0);
        IERC20 _token = IERC20(tokenToSend_);
        _token.transferFrom(_msgSender(), address(this), amount_);
        uint256 _qty = (amount_ * acceptableTokens[tokenToSend_]) / 10000;
        _transfer(address(this), _msgSender(), _qty);
        _result = true;
    }

    function sell(address tokenToGet_, uint256 amount_)
        external
        tokenExists(tokenToGet_)
        returns (bool _result)
    {
        require(amount_ != 0);
        IERC20 _token = IERC20(tokenToGet_);
        uint256 _qty = (10000 * amount_) / acceptableTokens[tokenToGet_];
        _transfer(_msgSender(), address(this), amount_);
        _token.transfer(_msgSender(), _qty);

        _result = true;
    }

    function withdrawMyBalance() external returns (bool _result) {
        require(withdrawable[_msgSender()] != 0);
        _transfer(address(this), _msgSender(), withdrawable[_msgSender()]);
        withdrawable[_msgSender()] = 0;
        _result = true;
    }

    function withdraw(address tokenToGet_, uint256 amount_)
        external
        isOwner
        returns (bool _result)
    {
        require(amount_ != 0);
        IERC20 _token = IERC20(tokenToGet_);
        _token.transfer(_msgSender(), amount_);
        _result = true;
    }

    function deposit(address tokenToSend_, uint256 amount_)
        external
        isOwner
        returns (bool _result)
    {
        require(amount_ != 0);
        IERC20 _token = IERC20(tokenToSend_);
        _token.transferFrom(_msgSender(), address(this), amount_);
        _result = true;
    }

    function calculateInvestmentRate(uint256 period_)
        external
        view
        returns (
            uint256 _profitPercentPerDay,
            uint256 _profitPercentPerExtraDays
        )
    {
        require(minPeriod <= period_, "Minimum investment period is 30 days!");
        require(maxPeriod >= period_, "Maximum investment period is 730 days!");

        (
            _profitPercentPerDay,
            _profitPercentPerExtraDays
        ) = _calculateInvestmentRate(period_);
    }

    function _calculateInvestmentRate(uint256 period_)
        internal
        view
        returns (
            uint256 _profitPercentPerDay,
            uint256 _profitPercentPerExtraDays
        )
    {
        address _referral = referrals[_msgSender()];
        if (_referral == address(0)) {
            _profitPercentPerDay = profitPerDayWithoutReferral;
        } else {
            _profitPercentPerDay = profitPerDayWithReferral;
        }
        _profitPercentPerExtraDays = _profitPercentPerDay;
        uint256 c = period_ / minPeriod;
        if (c > 1) {
            _profitPercentPerDay +=
                ((c - 1) * monthlyCoeficient) /
                (c * minPeriod);
        }
    }

    function invest(uint256 amount_, uint256 period_)
        external
        returns (bool _result)
    {
        require(amount_ != 0);
        require(minInvest <= amount_, "Investment amount is too low!");
        require(minPeriod <= period_, "Minimum investment period is 30 days!");
        require(maxPeriod >= period_, "Maximum investment period is 730 days!");

        if (investors[_msgSender()] == 0) {
            ++totalInvestors;
        }

        investors[_msgSender()] += amount_;
        address _referral = referrals[_msgSender()];
        (
            uint256 _profitPercentPerDay,
            uint256 _profitPercentPerExtraDays
        ) = _calculateInvestmentRate(period_);
        uint256 bt = block.timestamp;
        investings[_msgSender()].push(
            InvestingInfo({
                investedAt: bt,
                endAt: bt + period_ * 1 minutes,
                amount: amount_,
                period: period_,
                payProfitPeriod: payProfitPeriod,
                referral: _referral,
                lastSettlementAt: bt,
                settledTill: bt,
                receivedProfits: 0,
                profitPercentPerDay: _profitPercentPerDay,
                profitPercentPerExtraDays: _profitPercentPerExtraDays
            })
        );
        totalInvestment += amount_;
        _transfer(_msgSender(), address(this), amount_);
        _result = true;
    }
}