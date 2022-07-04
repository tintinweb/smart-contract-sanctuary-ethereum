// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./OMHERC20.sol";

contract StakingAlgo3 is ReentrancyGuard {
    struct UserInfo {
        uint256 depositedAmount; // total deposited amount for this user
        uint256 lockedTime; // locked period for claim of this user, ex: 1 year, 3 year
        uint256 totalRefersCount; // refer count this user has received
        uint256 receivedRefersCount; // refer count that has already been received reward from this user's total refer count
        uint256 rewardAtLastDeposit; // current available reward amount at last deposit time
        uint256 totalRewardAtLastDeposit; // total reward amount at last deposit time
        bool isAddRefer; // only 1 refer address can be added per user. if this value is true, you can't add refer anymore
    }

    uint256 public startDate;
    uint256 public totalSupply; // total deposited amount (user deposit)
    uint256 public totalReward; // total reward amount, not refer (admin + fee)
    uint256 public remainingReward; // reward amount remaining in pool at the moment (admin + fee - claimed)
    uint256 public totalRewardForRefer; // reward amount for refers to this contract (admin)

    // TODO: need to set rewardpercent (vip1RewardPercent, ) logic again
    uint256 public vip1MinAmount = 10000000; // 10m
    uint256 public vip1LockingPeriod = 60 * 60 * 24 * 365; // 1 year
    uint256 public vip1RewardPercent = 85; // 85% of totalReward
    uint256 public vip2MinAmount = 100000000; // 100m
    uint256 public vip2LockingPeriod = 60 * 60 * 24 * 365 * 3; // 3 year
    uint256 public vip2RewardPercent = 100; // 100% of totalReward
    uint256 public rewardPercent = 70; // 70% of totalReward

    uint256 public minDepositAmount = 10000;

    uint256 public constant depositFeePercent = 10; // 10%
    uint256 public constant withdrawFeePercent = 10; // 10%

    // to refer address, give instance 100 OMH reward
    uint256 public rewardPerRefer = 100;
    // when 10 refers, then give more 100*10 OMH rewards
    uint256 public rewardPer10Refer = 1000;
    // when 100 refers, then give more 100*100 OMH rewards
    uint256 public rewardPer100Refer = 10000;

    bool public pause = false;

    address public admin;
    OMHERC20 OMH;

    mapping(address => UserInfo) private userInfo;

    event Deposit(
        address indexed caller,
        address referAddress,
        uint256 inputDepositAmount,
        uint256 fee,
        uint256 createdAt
    );

    event Redeposit(
        address indexed caller,
        uint256 redepositAmount,
        uint256 fee,
        uint256 createdAt
    );

    event Withdraw(
        address indexed caller,
        uint256 withdrawAmount,
        uint256 fee,
        uint256 rewardAmount,
        uint256 createdAt
    );

    event Claim(
        address indexed caller,
        uint256 claimAmount,
        uint256 createdAt
    );

    modifier onlyAdmin {
        require(msg.sender == admin, "caller is not admin");
        _;
    }

    modifier checkActive {
        require(block.timestamp >= startDate && !pause, "can not do now");
        _;
    }

    // OMH-OMH staking pool
    constructor(uint256 _startDate, address _omh) {
        admin = msg.sender;
        startDate = _startDate;
        OMH = OMHERC20(_omh);
    }

    /** only admin functions */
    function changeAdmin(address _new) external onlyAdmin {
        require(_new != address(0), "invalid address");
        admin = _new;
    }

    function changeToken(address _newToken) external onlyAdmin {
        OMH = OMHERC20(_newToken);
    }

    function changeStartDate(uint256 _newDate) external onlyAdmin {
        startDate = _newDate;
    }

    function changeVip1(uint256 _minAmount, uint256 _lockingPeriod) external onlyAdmin {
        vip1MinAmount = _minAmount;
        vip1LockingPeriod = _lockingPeriod;
    }

    function changeVip2(uint256 _minAmount, uint256 _lockingPeriod) external onlyAdmin {
        vip2MinAmount = _minAmount;
        vip2LockingPeriod = _lockingPeriod;
    }

    function changeMinDepositAmount(uint256 _newAmount) external onlyAdmin {
        minDepositAmount = _newAmount;
    }

    function setRewardPercent(uint256 _regularPercent, uint256 _vip1Percent, uint256 _vip2Percent) external onlyAdmin {
        rewardPercent = _regularPercent;
        vip1RewardPercent = _vip1Percent;
        vip2RewardPercent = _vip2Percent;
    }

    function setPause(bool _status) external onlyAdmin {
        pause = _status;
    }

    /** external funtions */
    function addReward(uint256 _amount) external {
        OMH.transferFrom(msg.sender, address(this), _amount);
        totalReward += _amount;
        remainingReward += _amount;
    }

    function addRewardForRefer(uint256 _amount) external {
        OMH.transferFrom(msg.sender, address(this), _amount);
        totalRewardForRefer += _amount;
    }

    function deposit(uint256 _amount, address _refer) external {
        require(msg.sender != _refer, "can not refer to yourself");

        uint256 _timeNow = block.timestamp;
        OMH.transferFrom(msg.sender, address(this), _amount);
        // add refer address
        if (_refer != address(0) && !userInfo[msg.sender].isAddRefer && userInfo[_refer].depositedAmount > 0) {
            userInfo[_refer].totalRefersCount += 1;
            userInfo[msg.sender].isAddRefer = true;
        }

        // set new available reward amount before deposit
        userInfo[msg.sender].rewardAtLastDeposit = getRewardAmountNotRefer(msg.sender);

        uint256 _fee = depositOMH(_amount);

        uint256 _totalDepositedAmount = userInfo[msg.sender].depositedAmount;
        if (_totalDepositedAmount >= vip2MinAmount) {
            userInfo[msg.sender].lockedTime = _timeNow + vip2LockingPeriod;
        } else if (_totalDepositedAmount >= vip1MinAmount) {
            userInfo[msg.sender].lockedTime = _timeNow + vip1LockingPeriod;
        } else {
            userInfo[msg.sender].lockedTime = _timeNow;
        }

        emit Deposit(msg.sender, _refer, _amount, _fee, _timeNow);
    }

    function redeposit() external nonReentrant {
        uint256 _redepositAmount = claimReward();
        require(_redepositAmount > 0, "no reward");

        uint256 _fee = depositOMH(_redepositAmount);

        emit Redeposit(msg.sender, _redepositAmount, _fee, block.timestamp);
    }

    function withdraw() external nonReentrant checkActive {
        uint256 _withdrawAmount = userInfo[msg.sender].depositedAmount;
        require(_withdrawAmount > 0, "not depositer");
        require(block.timestamp > userInfo[msg.sender].lockedTime, "locked");

        uint256 _rewardAmount = claimReward();

        totalSupply -= _withdrawAmount;
        userInfo[msg.sender].depositedAmount = 0;
        userInfo[msg.sender].lockedTime = 0;
        userInfo[msg.sender].totalRewardAtLastDeposit = 0;
        userInfo[msg.sender].totalRefersCount = 0;
        userInfo[msg.sender].receivedRefersCount = 0;

        uint256 _withdrawFee = 0;
        if (_withdrawAmount < vip1MinAmount) {
            _withdrawFee = _withdrawAmount * withdrawFeePercent / 100;
            // reduce by withdrawal fee from the withdrawal amount
            _withdrawAmount -= _withdrawFee;
            // send withdrawal fee to admin
            OMH.transferFrom(address(this), admin, _withdrawFee);
        }
        OMH.transferFrom(address(this), msg.sender, _withdrawAmount + _rewardAmount);

        emit Withdraw(msg.sender, _withdrawAmount, _withdrawFee, _rewardAmount, block.timestamp);
    }

    function claim() external nonReentrant checkActive {
        uint256 _rewardAmount = claimReward();
        require(_rewardAmount > 0, "no reward");

        userInfo[msg.sender].totalRewardAtLastDeposit = totalReward;

        OMH.transferFrom(address(this), msg.sender, _rewardAmount);

        emit Claim(msg.sender, _rewardAmount, block.timestamp);
    }

    /** view functions */
    function getRewardAmountForRefer(address _user) public view returns (uint256) {
        // refers reward
        uint256 _refers = userInfo[_user].totalRefersCount;
        uint256 _receivedRefersCount = userInfo[_user].receivedRefersCount;
        uint256 _rewardForRefer = 0;

        if (_refers > _receivedRefersCount) {
            uint256 _rewardPer100Refer = rewardPer100Refer;
            uint256 _rewardPer10Refer = rewardPer10Refer;

            _rewardForRefer =
                (_refers / 100) * _rewardPer100Refer +
                (_refers / 10) * _rewardPer10Refer +
                (_refers - _receivedRefersCount) * rewardPerRefer -
                (_receivedRefersCount / 100) * _rewardPer100Refer -
                (_receivedRefersCount / 10) * _rewardPer10Refer;
        }

        return _rewardForRefer;
    }

    // get only reward amount, not refer
    function getRewardAmountNotRefer(address _user) public view returns (uint256) {
        require(_user != address(0), "invalid address");

        uint256 _depositedAmount = userInfo[_user].depositedAmount;
        uint256 _newReward = totalReward - userInfo[_user].totalRewardAtLastDeposit;
        uint256 _rewardAmount = userInfo[_user].rewardAtLastDeposit;

        if (_newReward > 0 && _depositedAmount > 0) {
            uint256 _rewardPercent =
                _depositedAmount >= vip2MinAmount ? vip2RewardPercent :
                _depositedAmount >= vip1MinAmount ? vip1RewardPercent : rewardPercent;

            _rewardAmount += _newReward * _rewardPercent * _depositedAmount / totalSupply / 100;
        }

        return _rewardAmount;
    }

    function getUserInfo(address _user) external view returns (uint256, uint256, uint256, bool) {
        return (
            userInfo[_user].depositedAmount,
            userInfo[_user].lockedTime,
            userInfo[_user].totalRefersCount,
            userInfo[_user].isAddRefer
        );
    }

    /** private functions */
    function depositOMH(uint256 _amount) private checkActive returns (uint256) {
        require(_amount >= minDepositAmount, "amount is less than min deposit amount");

        uint256 _vip1MinAmount = vip1MinAmount;
        // deposit fee
        uint256 fee = 0;
        if (_amount < _vip1MinAmount) {
            fee = _amount * depositFeePercent / 100;
            totalReward += fee;
            remainingReward += fee;
        }

        uint256 _newDepositAmount = _amount - fee;
        totalSupply += _newDepositAmount;

        userInfo[msg.sender].depositedAmount += _newDepositAmount;
        userInfo[msg.sender].totalRewardAtLastDeposit = totalReward;

        return fee;
    }

    function claimReward() private returns (uint256) {
        uint256 _rewardNotRefer = getRewardAmountNotRefer(msg.sender);
        remainingReward -= _rewardNotRefer;

        uint256 _rewardForRefer = getRewardAmountForRefer(msg.sender);

        if (_rewardForRefer > 0) {
            require(totalRewardForRefer >=_rewardForRefer, "not enough refers amount yet");
            userInfo[msg.sender].receivedRefersCount = userInfo[msg.sender].totalRefersCount;
            totalRewardForRefer -= _rewardForRefer;
        }

        userInfo[msg.sender].rewardAtLastDeposit = 0;

        return _rewardNotRefer + _rewardForRefer;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract OMHERC20 is ERC20, Ownable {
  uint256 public constant FEEDOMINATOR = 10000;
  uint32 public burnFee = 200;

  mapping(address => bool) public isExcludedFromBurn;

  constructor() ERC20("OMVERITAS", "OMH") {
    _mint(msg.sender, 17 * 10**9 * 10**18);   // 17 billion

    isExcludedFromBurn[msg.sender] = true;
  }

  function _transfer(address _from, address _to, uint256 _amount) internal override {
    if (_from.code.length == 0 && !isExcludedFromBurn[_from]) {
      uint256 burnAmount = calculateTokenFee(_amount, burnFee);
      uint256 tokensToTransfer = _amount - burnAmount;

      if (burnAmount > 0) 
        _burn(_from, burnAmount); 
      
      super._transfer(_from, _to, tokensToTransfer);
    } else {
      super._transfer(_from, _to, _amount);
    }
  }

  function calculateTokenFee(uint256 _amount, uint32 _fee) public pure returns (uint256 feeAmount) {
    feeAmount = (_amount * _fee) / FEEDOMINATOR;
  }

  function excludeFromBurn(address _account, bool _value) public onlyOwner {
    isExcludedFromBurn[_account] = _value;
  }

  function transferOwnership(address _newOwner) public override onlyOwner {
    super.transferOwnership(_newOwner);
    isExcludedFromBurn[_newOwner] = true;
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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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