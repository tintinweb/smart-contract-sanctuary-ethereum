pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./DFWInvestment.sol";

contract DFWInvestment {

  // 项目信息设置
  string public name;
  address public admin;
  address public projectOwner;
  //  address public erc20Address;
  ERC20 public erc20;

  uint256 public startTime = 0;
  uint256 public endTime = 0;
  uint256 public investCap;
  uint256 public investMin = 0;
  uint256 public investMax = 0;

  struct Stage {
    uint32 rate; // 万分比
    uint256 startTime;
    uint256 endTime;

    uint256 voteStartTime;
    uint256 voteEndTime;

    uint256 secondVoteStartTime;
    uint256 secondVoteEndTime;

    // 阶段是否通过
    bool passed;
  }
  Stage[] public stages;
  int256 public _curStageId = -1;

  // 合约状态数据
  enum VoteType { None, Passed, Rejected }

  uint256 public investTotal = 0; // 总投资金额
  mapping (address => uint256) investments; // 每个用户投资金额
  address[] public investors;
  mapping (address => VoteType) votes; // 每个用户当前投票信息
  address[] public voters;
  bool public isSecondVote;

  // 事件定义
  event Invest(address indexed investor, uint256 amount);
  event InvestStart();
  event InvestEnd();

  event Release(uint256 amount);
  event Refund(address indexed investor, uint256 amount);

  event NextStage(bool passed);

  event Vote(uint256 indexed stage, address indexed voter, bool pass);
  event VoteStart(uint256 indexed stage);
  event VoteEnd(uint256 indexed stage, bool result);

  // 修饰器
  modifier onlyAdmin() {
    require(msg.sender == admin, "Caller is not the admin");
    _;
  }
  modifier onlyProjectOwner() {
    require(msg.sender == admin || msg.sender == projectOwner, "Caller is not the project owner");
    _;
  }
  modifier onlyInvestor() {
    require(investments[msg.sender] > 0, "Caller is not the investor");
    _;
  }
  modifier onlyAfter(uint256 time) {
    require(block.timestamp >= time, "Function called too early");
    _;
  }
  modifier onlyBefore(uint256 time) {
    if (time > 0)
      require(block.timestamp < time, "Function called too late");
    _;
  }

  // 构造函数
  constructor(string memory _name,
    address _admin, address _projectOwner,
  // 测试币：0xBA62BCfcAaFc6622853cca2BE6Ac7d845BC0f2Dc
  // 正式币（USDT）：0xdAC17F958D2ee523a2206206994597C13D831ec7
    address _erc20Address) {
    name = _name;
    admin = _admin;
    projectOwner = _projectOwner;
    erc20 = ERC20(_erc20Address);
  }

  // region 测试用

  function setupForTest(
    uint8 stageCnt,
    uint256 cap, uint256 min, uint256 max,
    uint256 timeRate)
  public onlyAdmin onlyBefore(startTime) {

    uint256 now = block.timestamp;
    uint256 start = now + 1 minutes * timeRate;
    uint256 end = now + 2 minutes * timeRate;
    uint32 rate = 10000 / stageCnt;

    clearStage();
    for (uint8 i = 0; i < stageCnt; i++) {
      uint256 stageStart = end + i * 2 minutes * timeRate;
      uint256 stageEnd = stageStart + 1 minutes * timeRate;
      uint256 voteStart = stageEnd;
      uint256 voteEnd = voteStart + 1 minutes * timeRate;
      uint256 secondVoteStart = voteEnd + 1 minutes * timeRate;
      uint256 secondVoteEnd = secondVoteStart + 1 minutes * timeRate;

      addStage(rate, start, end, voteStart, voteEnd, secondVoteStart, secondVoteEnd);
    }

    setInvestInfo(start, end, cap, min, max);
  }
  function setupForTest(
    uint8 stageCnt,
    uint256 cap, uint256 min, uint256 max)
  public onlyAdmin onlyBefore(startTime) {
    setupForTest(stageCnt, cap, min, max, 1);
  }

  function reset() public onlyAdmin {
    _curStageId = -1;
    delete investTotal;
    for (uint256 i = 0; i < investors.length; i++)
      investments[investors[i]] = 0;
    delete investors;
    for (uint256 i = 0; i < voters.length; i++)
      votes[voters[i]] = VoteType.None;
    delete voters;
    delete isSecondVote;
    delete startTime;
    delete endTime;
    delete investCap;
    delete investMin;
    delete investMax;
    for (uint8 i = 0; i < stages.length; i++)
      stages[i].passed = false;
  }

  // endregion

  // region 信息修改

  function clearStage()
  public onlyProjectOwner onlyBefore(startTime) {
    delete stages;
  }
  function addStage(uint32 rate,
    uint256 start, uint256 end,
    uint256 voteStart, uint256 voteEnd,
    uint256 secondVoteStart, uint256 secondVoteEnd)
  public onlyProjectOwner onlyBefore(startTime) {
    stages.push(Stage({
    rate: rate,
    startTime: start,
    endTime: end,
    voteStartTime: voteStart,
    voteEndTime: voteEnd,
    secondVoteStartTime: secondVoteStart,
    secondVoteEndTime: secondVoteEnd,
    passed: false
    }));
  }
  function setStageInfo(uint8 index, uint32 rate,
    uint256 start, uint256 end,
    uint256 voteStart, uint256 voteEnd,
    uint256 secondVoteStart, uint256 secondVoteEnd)
  public onlyProjectOwner onlyBefore(startTime) {
    stages[index].rate = rate;
    stages[index].startTime = start;
    stages[index].endTime = end;
    stages[index].voteStartTime = voteStart;
    stages[index].voteEndTime = voteEnd;
  }

  function setInvestInfo(
    uint256 start, uint256 end,
    uint256 cap, uint256 min, uint256 max)
  public onlyProjectOwner onlyBefore(startTime) {
    startTime = start;
    endTime = end;
    investCap = cap;
    investMin = min;
    investMax = max;
  }
  function setInvestInfo(
    uint256 start, uint256 end, uint256 cap, uint256 min)
  public onlyProjectOwner onlyBefore(startTime) {
    setInvestInfo(start, end, cap, min, 0);
  }
  function setInvestInfo(
    uint256 start, uint256 end, uint256 cap)
  public onlyProjectOwner onlyBefore(startTime) {
    setInvestInfo(start, end, cap, 0);
  }

  // endregion

  // region 信息获取

  function curStageId() public view returns(uint256) {
    require(_curStageId >= 0 && uint256(_curStageId) < stages.length, "Stage out of range");
    return uint256(_curStageId);
  }
  function curStage() public view returns(Stage memory) {
    return stages[curStageId()];
  }

  function curVoteStartTime() public view returns(uint256) {
    return isSecondVote ?
    curStage().secondVoteStartTime :
    curStage().voteStartTime;
  }
  function curVoteEndTime() public view returns(uint256) {
    return isSecondVote ?
    curStage().secondVoteEndTime :
    curStage().voteEndTime;
  }

  // endregion

  // region 状态更新

  function onInvestStart() public onlyProjectOwner onlyAfter(startTime) {
    emit InvestStart();
  }
  function onInvestEnd() public onlyProjectOwner onlyAfter(endTime) {
    _curStageId = 0;
    emit InvestEnd();
  }

  function onVoteStart() public
  onlyProjectOwner
  onlyAfter(curVoteStartTime()) {
    emit VoteStart(curStageId());
  }
  function onVoteEnd() public
  onlyProjectOwner
  onlyAfter(curVoteEndTime()) {
    bool passed = judgeVotePassed();

    // 如果通过，释放金额
    if (passed) { release(); nextStage(passed); }
    // 否则如果是第二次Vote，退款
    else if (isSecondVote) { refund(); nextStage(passed); }
    // 否则开始第二次投票
    else isSecondVote = true;

    emit VoteEnd(curStageId(), passed);
  }

  function judgeVotePassed() public view returns(bool) {
    int256 passed = 0;
    for (uint256 i = 0; i < voters.length; i++) {
      if (votes[voters[i]] == VoteType.Passed)
        passed++;
      else if (votes[voters[i]] == VoteType.Rejected)
        passed--;
    }
    return passed >= 0;
  }
  function nextStage(bool passed) private {
    for (uint256 i = 0; i < voters.length; i++)
      votes[voters[i]] = VoteType.None;
    _curStageId++;

    emit NextStage(curStage().passed = passed);
  }

  // endregion

  // region ERC20转移

  // 授权可转移的代币
  function approve(address _spender, uint256 _amount) external returns (bool) {
    require(msg.sender == admin, "Only admin can call this function");
    return erc20.approve(_spender, _amount);
  }

  // 转移代币
  function transfer(address _recipient, uint256 _amount) internal returns (bool) {
    return erc20.transfer(_recipient, _amount);
  }

  // 判断是否授权
  function allowance(address _owner, address _spender) external view returns (uint256) {
    return erc20.allowance(_owner, _spender);
  }

  // endregion

  // region 投资

  function invest(uint256 amount) public onlyAfter(startTime) onlyBefore(endTime) {
    require(amount >= investMin, "Invest value out of range");
    require(amount <= investMax || investMax == 0, "Invest value out of range");
    require(investTotal + amount <= investCap, "Total invest value exceed the cap");

    erc20.transferFrom(msg.sender, address(this), amount);

    investments[msg.sender] += amount;
    investors.push(msg.sender);
    investTotal += amount;

    if (investTotal == investCap) onInvestEnd();

    emit Invest(msg.sender, amount);
  }

  function release() private {
    // require(curStageId >= 0 && uint256(curStageId) < stages.length, "Stage out of range");
    // Stage memory stage = curStage();
    // Stage memory stage = curStage();

    // 计算释放金额
    uint256 amount = investTotal / 10000 * curStage().rate;
    require(amount <= erc20.balanceOf(address(this)), "Balance not enough!");

    // 转移代币到项目方账户
    erc20.transfer(projectOwner, amount);
    emit Release(amount);
  }

  function refund() private {
    // require(curStageId >= 0 && uint256(curStageId) < stages.length, "Stage out of range");
    // Stage memory stage = stages[uint256(curStageId)];
    // Stage memory stage = curStage();

    // 计算退款金额
    uint256 amount = investTotal / 10000 * curStage().rate;
    require(amount <= erc20.balanceOf(address(this)), "Balance not enough!");

    uint256 totalRefund = 0;
    for (uint256 i = 0; i < investors.length; i++) {
      address investor = investors[i];
      uint256 investValue = investments[investor];
      if (investValue > 0) {
        // 计算需要退还的金额
        uint256 refundAmount = amount * investValue / investTotal;
        erc20.transfer(investor, refundAmount);
        emit Refund(investor, refundAmount);
      }
    }
  }

  // endregion

  // region 投票

  function vote(VoteType vote) public onlyInvestor
  onlyAfter(curVoteStartTime())
  onlyBefore(curVoteEndTime()) {

    require(votes[msg.sender] == VoteType.None, "Already voted");

    votes[msg.sender] = vote;
    voters.push(msg.sender);

    emit Vote(curStageId(), msg.sender, vote == VoteType.Passed);
  }

  // endregion
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

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