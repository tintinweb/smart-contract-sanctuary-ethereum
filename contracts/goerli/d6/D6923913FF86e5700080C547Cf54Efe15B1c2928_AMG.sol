/**
 *Submitted for verification at Etherscan.io on 2023-02-14
*/

pragma solidity =0.8.6;

// SPDX-License-Identifier: SimPL-2.0

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

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

contract AMG is ERC20, Ownable {
    struct ConstructorParam {
        uint256 totalSupply; // 发行总量
        
        uint256 cashboxPreRatio; // 金库预释放比例
        uint256 cashboxLinearRatio; // 金库线性释放比例
        uint256 cashboxLinearStart; // 金库线性释放开始时间戳
        uint256 cashboxLinearDuration; // 金库线性释放天数
        address cashboxAccount; // 金库账号地址
        
        uint256 miningLinearRatio; // 挖矿线性释放比例
        uint256 miningLinearStart; // 挖矿线性释放开始时间戳
        uint256 miningLinearDuration; // 挖矿线性释放天数
        address miningAccount; // 挖矿账号地址
        
        uint256 teamPreRatio; // 团队预释放比例
        uint256 teamPreStart; // 团队预释放开始时间戳
        uint256 teamLinearRatio; // 团队线性释放比例
        uint256 teamLinearStart; // 团队线性释放开始时间戳
        uint256 teamLinearDuration; // 团队线性释放天数
        address teamAccount; // 团队账号地址
        
        uint256 priplacePreRatio; // 私募预释放比例
        uint256 priplacePreStart; // 私募预释放开始时间戳
        uint256 priplaceLinearRatio; // 私募线性释放比例
        uint256 priplaceLinearStart; // 私募线性释放开始时间戳
        uint256 priplaceLinearDuration; // 私募线性释放天数
        address priplaceAccount; // 私募账号地址
        
        uint256 launchpadRatio; // launchpad比例
        address launchpadAccount; // launchpad账号地址
    }
    
    event CashboxAccountChange(address indexed from, address indexed to);
    event MiningAccountChange(address indexed from, address indexed to);
    event TeamAccountChange(address indexed from, address indexed to);
    event PriplaceAccountChange(address indexed from, address indexed to);
    event LaunchpadAccountChange(address indexed from, address indexed to);
    
    uint256 private constant DENO = 1e18; // 所有比例的分母
    
    uint256 public cashboxPreTotal; // 金库预释放总量
    uint256 public cashboxLinearTotal; // 金库线性释放总量
    uint256 public cashboxLinearStart; // 金库线性释放开始日期
    uint256 public cashboxLinearDuration; // 金库线性释放天数
    address public cashboxAccount; // 金库账号地址
    uint256 public cashboxClaimed; // 金库已领取数量
    
    uint256 public miningLinearTotal; // 挖矿线性释放总量
    uint256 public miningLinearStart; // 挖矿线性释放开始日期
    uint256 public miningLinearDuration; // 挖矿线性释放天数
    address public miningAccount; // 挖矿账号地址
    uint256 public miningClaimedTotal; // 挖矿已领取总量
    uint256 public miningBurnedTotal; // 挖矿已燃烧总量
    uint256 public miningClaimedTime; // 挖矿上次领取日期
    uint256 public miningClaimedCurr; // 挖矿上次领取总量
    
    uint256 public teamPreTotal; // 团队预释放总量
    uint256 public teamPreStart; // 团队预释放开始日期
    uint256 public teamLinearTotal; // 团队线性释放总量
    uint256 public teamLinearStart; // 团队线性释放开始日期
    uint256 public teamLinearDuration; // 团队线性释放天数
    address public teamAccount; // 团队账号地址
    uint256 public teamClaimed; // 团队已领取数量
    
    uint256 public priplacePreTotal; // 私募预释放总量
    uint256 public priplacePreStart; // 私募预释放开始日期
    uint256 public priplaceLinearTotal; // 私募线性释放总量
    uint256 public priplaceLinearStart; // 私募线性释放开始日期
    uint256 public priplaceLinearDuration; // 私募线性释放天数
    address public priplaceAccount; // 私募账号地址
    uint256 public priplaceClaimed; // 私募已领取数量
    
    uint256 public launchpadTotal; // launchpad总量
    address public launchpadAccount; // launchpad账号地址
    uint256 public launchpadClaimed; // launchpad已领取数量
    
    constructor(string memory _name, string memory _symbol,
        ConstructorParam memory cp)
        ERC20(_name, _symbol) {
        
        cashboxPreTotal = cp.totalSupply * cp.cashboxPreRatio / DENO;
        cashboxLinearTotal = cp.totalSupply * cp.cashboxLinearRatio / DENO;
        cashboxLinearStart = getDay(cp.cashboxLinearStart);
        cashboxLinearDuration = cp.cashboxLinearDuration;
        _changeCashboxAccount(cp.cashboxAccount);
        
        miningLinearTotal = cp.totalSupply * cp.miningLinearRatio / DENO;
        miningLinearStart = getDay(cp.miningLinearStart);
        miningLinearDuration = cp.miningLinearDuration;
        _changeMiningAccount(cp.miningAccount);
        
        teamPreTotal = cp.totalSupply * cp.teamPreRatio / DENO;
        teamPreStart = getDay(cp.teamPreStart);
        teamLinearTotal = cp.totalSupply * cp.teamLinearRatio / DENO;
        teamLinearStart = getDay(cp.teamLinearStart);
        teamLinearDuration = cp.teamLinearDuration;
        _changeTeamAccount(cp.teamAccount);
        
        priplacePreTotal = cp.totalSupply * cp.priplacePreRatio / DENO;
        priplacePreStart = getDay(cp.priplacePreStart);
        priplaceLinearTotal = cp.totalSupply * cp.priplaceLinearRatio / DENO;
        priplaceLinearStart = getDay(cp.priplaceLinearStart);
        priplaceLinearDuration = cp.priplaceLinearDuration;
        _changePriplaceAccount(cp.priplaceAccount);
        
        launchpadTotal = cp.totalSupply * cp.launchpadRatio / DENO;
        _changeLaunchpadAccount(cp.launchpadAccount);
    }
    
    // 日期编号
    function getDay(uint256 timestamp) public pure returns(uint256) {
        return timestamp / 1 days;
    }
    
    function getDay() public view returns(uint256) {
        return getDay(block.timestamp);
    }
    
    // 金库已释放总量
    function getCashboxReleased() public view returns(uint256) {
        uint256 day = getDay();
        if (day < cashboxLinearStart) {
            return cashboxPreTotal;
        }
        
        // 每过一个周期减半释放
        uint256 released = cashboxPreTotal;
        uint256 duration = day + 1 - cashboxLinearStart;
        uint256 amount = cashboxLinearTotal / 2;
        
        while (duration > cashboxLinearDuration) {
            released += amount;
            duration -= cashboxLinearDuration;
            amount /= 2;
        }
        
        released += amount * duration / cashboxLinearDuration;
        
        return released;
    }
    
    // 金库当前可领取
    function getCashboxAvail() public view returns(uint256) {
        return getCashboxReleased() - cashboxClaimed;
    }
    
    // 领取金库
    function claimCashbox(uint256 amount) external {
        require(msg.sender == cashboxAccount, "invalid account");
        
        require(amount <= getCashboxAvail(), "too much");
        
        cashboxClaimed += amount;
        _mint(msg.sender, amount);
    }
    
    // 修改金库账号
    function _changeCashboxAccount(address to) private {
        emit CashboxAccountChange(cashboxAccount, to);
        cashboxAccount = to;
    }
    
    function changeCashboxAccount(address to) external onlyOwner {
        _changeCashboxAccount(to);
    }
    
    // 挖矿已释放总量
    function getMiningReleased() public view returns(uint256) {
        uint256 day = getDay();
        if (day < miningLinearStart) {
            return 0;
        }
        
        // 每过一个周期减半释放
        uint256 released = 0;
        uint256 duration = day + 1 - miningLinearStart;
        uint256 amount = miningLinearTotal / 2;
        
        while (duration > miningLinearDuration) {
            released += amount;
            duration -= miningLinearDuration;
            amount /= 2;
        }
        
        released += amount * duration / miningLinearDuration;
        
        return released;
    }
    
    // 挖矿当前可领取
    function getMiningAvail() public view returns(uint256) {
        uint256 day = getDay();
        if (day < miningLinearStart) {
            return 0;
        }
        
        uint256 duration = day + 1 - miningLinearStart;
        uint256 amount = miningLinearTotal / 2;
        
        while (duration > miningLinearDuration) {
            duration -= miningLinearDuration;
            amount /= 2;
        }
        
        uint256 avail = amount / miningLinearDuration;
        
        if (miningClaimedTime == day) {
            avail -= miningClaimedCurr;
        }
        
        return avail;
    }
    
    // 领取挖矿
    function claimMining(uint256 amount) external {
        require(msg.sender == miningAccount, "invalid account");
        
        uint256 avail = getMiningAvail();
        require(amount <= avail, "too much");
        
        uint256 burnAmount = getMiningReleased() - miningClaimedTotal
            - miningBurnedTotal - avail;
        
        miningClaimedTotal += amount;
        miningBurnedTotal += burnAmount;
        
        uint256 day = getDay();
        if (miningClaimedTime == day) {
            miningClaimedCurr += amount;
        } else {
            miningClaimedTime = day;
            miningClaimedCurr = amount;
        }
        
        // 之前未领取的要燃烧
        _mint(address(this), burnAmount);
        _burn(address(this), burnAmount);
        
        _mint(msg.sender, amount);
    }
    
    // 修改挖矿账号
    function _changeMiningAccount(address to) private {
        emit MiningAccountChange(miningAccount, to);
        miningAccount = to;
    }
    
    function changeMiningAccount(address to) external onlyOwner {
        _changeMiningAccount(to);
    }
    
    // 团队已释放总量
    function getTeamReleased() public view returns(uint256) {
        uint256 day = getDay();
        
        if (day < teamPreStart) {
            return 0;
        } else if (day < teamLinearStart) {
            return teamPreTotal;
        } else if (day >= teamLinearStart + teamLinearDuration) {
            return teamPreTotal + teamLinearTotal;
        } else {
            return teamPreTotal + teamLinearTotal *
                (day + 1 - teamLinearStart) / teamLinearDuration;
        }
    }
    
    // 团队可领取
    function getTeamAvail() public view returns(uint256) {
        return getTeamReleased() - teamClaimed;
    }
    
    // 领取团队
    function claimTeam(uint256 amount) external {
        require(msg.sender == teamAccount, "invalid account");
        
        require(amount <= getTeamAvail(), "too much");
        
        teamClaimed += amount;
        _mint(msg.sender, amount);
    }
    
    // 修改团队账号
    function _changeTeamAccount(address to) private {
        emit TeamAccountChange(teamAccount, to);
        teamAccount = to;
    }
    
    function changeTeamAccount(address to) external onlyOwner {
        _changeTeamAccount(to);
    }
    
    // 私募已释放总量
    function getPriplaceReleased() public view returns(uint256) {
        uint256 day = getDay();
        
        if (day < priplacePreStart) {
            return 0;
        } else if (day < priplaceLinearStart) {
            return priplacePreTotal;
        } else if (day >= priplaceLinearStart + priplaceLinearDuration) {
            return priplacePreTotal + priplaceLinearTotal;
        } else {
            return priplacePreTotal + priplaceLinearTotal *
                (day + 1 - priplaceLinearStart) / priplaceLinearDuration;
        }
    }
    
    // 私募可领取
    function getPriplaceAvail() public view returns(uint256) {
        return getPriplaceReleased() - priplaceClaimed;
    }
    
    // 领取私募
    function claimPriplace(uint256 amount) external {
        require(msg.sender == priplaceAccount, "invalid account");
        
        require(amount <= getPriplaceAvail(), "too much");
        
        priplaceClaimed += amount;
        _mint(msg.sender, amount);
    }
    
    // 修改私募账号
    function _changePriplaceAccount(address to) private {
        emit PriplaceAccountChange(priplaceAccount, to);
        priplaceAccount = to;
    }
    
    function changePriplaceAccount(address to) external onlyOwner {
        _changePriplaceAccount(to);
    }
    
    // launchpad可领取
    function getLaunchpadAvail() public view returns(uint256) {
        return launchpadTotal - launchpadClaimed;
    }
    
    // 领取launchpad
    function claimLaunchpad(uint256 amount) external {
        require(msg.sender == launchpadAccount, "invalid account");
        
        require(amount <= getLaunchpadAvail(), "too much");
        
        launchpadClaimed += amount;
        _mint(msg.sender, amount);
    }
    
    // 修改launchpad账号
    function _changeLaunchpadAccount(address to) private {
        emit LaunchpadAccountChange(launchpadAccount, to);
        launchpadAccount = to;
    }
    
    function changeLaunchpadAccount(address to) external onlyOwner {
        _changeLaunchpadAccount(to);
    }
}