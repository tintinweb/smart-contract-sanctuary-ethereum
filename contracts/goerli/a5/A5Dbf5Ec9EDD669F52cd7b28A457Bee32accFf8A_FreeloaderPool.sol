/**
 *Submitted for verification at Etherscan.io on 2023-01-14
*/

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


// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;




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

// File: 合约案例/FreeloaderPool.sol



// 测试地址:
// SingleCoinMine:0xa457Dc010C72D2Cc55AC7486d87d38eF44b1112A
// ERC20Token:0xE0297CE92ab70E99B6DfAdfF4464548956E6f141

pragma solidity ^0.8.7;



/*          6种需求: 
    1. 质押稳定币A挖稳定币A
    2. 质押稳定币A挖稳定币B
    3. 质押稳定币A挖非稳定币C
    4. 质押非稳定币C挖稳定币A
    5. 质押非稳定币C挖非稳定币C
    6. 质押非稳定币C挖非稳定币D
*/

contract FreeloaderPool is Ownable {

    // 本合约所有挖矿对:
    string private minePair;

    // 定义结构体:质押代币的地址,质押奖励代币的地址:
    struct stakeAndReward {
        address stakeTokenAddr;
        address rewardTokenAddr;
    }

    // 定义结构体:质押挖矿的信息:
    struct mineInfo {
        stakeAndReward minePair;            // 挖矿对地址
        uint256 rewardTotalSupply;          // 收益代币总供给
        uint256 totalMineTime;              // 挖矿总时间
        uint256 startTimeStamp;             // 挖矿开始时间(要设置一个开启挖矿的最低总份额)
        uint256 alreadyMineTime;            // 实时已挖矿时间
        uint256 alreadyMineAmount;          // 矿池已挖收益代币总数量
        uint256 settlementCycle;            // 结算周期
        uint256 totalShare;                 // 实时总份额(就是实时质押代币数量)
        // 当前结算周期每份额产币量,这个是实时变动的,因为每个周期内都有人退出质押挖矿(在周期内新加入挖矿的要下一周期才能获取收益)
        // 因此你在某个结算周期内一直获取该变量的值,你会发现要么保持不变,要么一直升高,而不会下降
        uint256 rewardPerShare;           
        uint256 leastShare;                 // 总份额达到多少时开始挖矿,一旦开启挖矿,即使后来份额低于此也继续挖
        uint256 APR;                        // 实时年利率(币本位)
        uint256 APY;                        // 实时年溢率(币本位)
        address creator;                    // 挖矿创建人地址
    }

    // 此结构体记录质押用户单次质押或取消质押时的期数和数量:
    struct StakeRecord {
        bool stake;      // true代表质押代币,false代表取消质押
        uint256 cycle;   // 质押或取消质押时挖矿的结算期数
        uint256 amount;  // 质押或取消质押的数量
    }

    // 此结构体用来记录质押用户所有某挖矿对质押或取消质押时的期数和数量
    struct AllStakeRecord {
        StakeRecord[] allRecord;
    }

    // 映射:挖矿对的相关信息:  
    mapping(string => mapping(string => mineInfo)) private mineInfoMap;

    // 注意:挖矿结束后以下这两个映射不能删除,因为是用代币的symbol进行查询的,映射一旦删除,如果作恶者新发一个同名代币,这时会
    //      导致挖矿用户的累计实现收益和已提取收益出现混乱(两个价值不同的同名代币计算在一起)
    // 同时注意:如果要实现一组挖矿对重复挖矿(第二轮第三轮挖矿),需要引入一个映射来存储已挖矿结束的交易对,
    //         作用是提示收益代币提供者此挖矿对已创建,只需update就行了

    // 映射:用来判断已完成至少一轮挖矿活动的挖矿对:
    mapping(address => mapping(address => bool)) public alreadyFinish;

    // 映射:用来判断某挖矿对是否存在:
    mapping(string => mapping(string => bool)) public exsistMinePair;

    // 下面这些映射每轮挖矿活动结束后都可以删除(前提是所有的质押用户已完成收益提款)

    // 映射:某挖矿对所有的质押用户地址:
    mapping(string => mapping(string => address[])) private minerAddr;
    
    // 映射:某挖矿对某质押用户的份额:
    mapping(string => mapping(string => mapping(address => uint256))) public minerShareMap;

    // 映射:某挖矿对某质押用户的已提取收益:
    mapping(string => mapping(string => mapping(address => uint256))) private minerWithdrawMap;

    // 映射:某挖矿对每个结算周期新增的质押挖矿份额数量:
    mapping(string => mapping(string => mapping(uint256 => uint256))) public shareUpdateMap;

    // 映射:某挖矿对某用户质押与取消质押情况:
    mapping(string => mapping(string => mapping(address => AllStakeRecord))) private allStakeRecordMap;

    // 映射:某挖矿对某用户质押所在结算周期和质押数量记录:
    // 质押与取消质押可能出现以下这种情况:
    // 比如在第25结算周期内,某用户已经有了1500质押份额,然后又追加了500份额(这部分在第26结算周期才产生收益),
    // 但此时在第25结算周期内又取消质押了1600份额,
    // 而这1600份额中有1500份额是在本轮立刻停止产生收益,另外100份额是在第26结算周期内才产生收益的
    // 这将影响finalShareMap映射的记录情况
    mapping(string => mapping(string => mapping(address => mapping(uint256 => uint256)))) public stakeCycleRecordMap;

    // 映射:某挖矿对每个结算周期参与收益结算的总份额变化数:
    // 注意:如果要获取每个结算周期参与收益结算的总份额,就直接累加就可以了,有点UTXO获取比特币余额的意思了
    mapping(string => mapping(string => mapping(uint256 => int256))) public finalShareMap;

    // 映射:某挖矿对某用户每个结算周期参与收益结算的总份额变化数:
    // 注意:如果要获取某用户每个结算周期参与收益结算的总份额,就直接累加就可以了,有点UTXO获取比特币余额的意思了
    mapping(string => mapping(string => mapping(address => mapping(uint256 => int256)))) public finalShareByStakerMap;


    // 事件:
    event minePairCreator(address indexed _stakeToken, address indexed _rewardToken, address indexed _minePairCreator);
    event addMinePairRewardTotalSupply(address indexed _stakeToken, address indexed _rewardToken, uint256 indexed _rewardTotalSupply);
    event addMinePairTotalMineTime(address indexed _stakeToken, address indexed _rewardToken, uint256 indexed _totalMineTime);
    event addMinePairSettlementCycle(address indexed _stakeToken, address indexed _rewardToken, uint256 indexed _settlementCycle);
    event addMinePairLeastShare(address indexed _stakeToken, address indexed _rewardToken, uint256 indexed _leastShare);
    event stakeToken(string indexed _minePair, address indexed _staker, uint256 indexed _stakeAmount);
    event unStakeToken(string indexed _minePair, address indexed _unStaker, uint256 indexed _unStakeAmount);
    event withdrawToken(string indexed _minePair, address indexed _user, uint256 indexed _withdrawAmount);


    // 查询某挖矿对实时信息:
    function queryMineInfo(
        string memory _stakeSymbol, 
        string memory _rewardSymbol
        ) public virtual view returns(mineInfo memory) { 
        return(_queryMineInfo(_stakeSymbol, _rewardSymbol));
    } 


    // 查询某挖矿对某质押用户的份额:
    function queryMinerShare(
        string memory _stakeSymbol,
        string memory _rewardSymbol,
        address _address
        ) public virtual view returns(uint256) {
        return(_queryMinerShare(_stakeSymbol, _rewardSymbol, _address));
    }


    // 查询某挖矿对某用户的累计实现收益,可提取收益和已提取收益:
    function queryWithdrawInfo(
        string memory _stakeSymbol,
        string memory _rewardSymbol,
        address _address
        ) public virtual view returns(uint256, uint256, uint256) {
        return(_queryWithdrawInfo(_stakeSymbol, _rewardSymbol, _address));
    }    


    // 查询某挖矿对某用户所有的质押与取消质押情况:
    function queryAllStakeRecord(
        string memory _stakeSymbol,
        string memory _rewardSymbol,
        address _address
        ) public virtual view returns(AllStakeRecord memory) {
        return(_queryAllStakeRecord(_stakeSymbol, _rewardSymbol, _address));
    }


    // 查询某挖矿对某结算周期最终的计算收益的总份额数:
    function queryRewardShareByCycle(
        string memory _stakeSymbol, 
        string memory _rewardSymbol,
        uint256 _cycle
        ) public virtual view returns(int256) {
        return(_queryRewardShareByCycle(_stakeSymbol, _rewardSymbol, _cycle));
    }


    // 在本合约中添加挖矿对:
    function addMinePair(
        address _stakeToken, 
        address _rewardToken,
        uint256 _rewardTotalSupply,
        uint256 _totalMineTime,
        uint256 _settlementCycle,
        uint256 _leastShare
        ) public virtual {
        _addMinePair(_stakeToken, _rewardToken, _rewardTotalSupply, _totalMineTime, _settlementCycle, _leastShare);
    }


    // 质押挖矿:
    function stake(
        address _stakeToken,
        address _rewardToken,
        uint256 _amount
        ) public virtual {
        _stake(_stakeToken, _rewardToken, _amount);
    } 


    // 撤销质押挖矿:
    function unStake(
        address _stakeToken,
        address _rewardToken,
        uint256 _amount
        ) public virtual {
        _unStake(_stakeToken, _rewardToken, _amount);
    }


    // 提取收益:
    function withdraw(
        address _stakeToken,
        address _rewardToken,
        uint256 _amount
        ) public virtual {
        _withdraw(_stakeToken, _rewardToken, _amount);
    }
    

    // 内部辅助函数,用来查询某挖矿对实时信息:
    function _queryMineInfo(
        string memory _stakeSymbol,
        string memory _rewardSymbol
        ) public virtual view returns(mineInfo memory) {

        // 先检查该挖矿对是否存在:
        _minePairExsistOrNot(_stakeSymbol, _rewardSymbol);    
           
        // 实时总份额在用户stake和unstake的过程中是实时更新的,因此不需要计算,直接获取:

        // 计算实时当前已挖矿时间:
        uint256 _alreadyMineTime = _countAlreadyMineTime(_stakeSymbol, _rewardSymbol);

        // 计算某挖矿对截至最近一次结算周期时已经挖得的收益代币的总数量:
        uint256 _alreadyMineAmount = _countAlreadyMineAmount(_stakeSymbol, _rewardSymbol);

        // 计算当前结算周期每份额产币量:
        uint256 _rewardPerShare = _countRewardPerShare(_stakeSymbol, _rewardSymbol);
        
        // 计算实时年利率:
        uint256 _APR = 0;

        // 计算实时年溢率:
        uint256 _APY = 0;    
         
        // 获取挖矿对信息映射:
        mineInfo memory _info = mineInfoMap[_stakeSymbol][_rewardSymbol];

        // 创建mineInfo结构体:
        mineInfo memory _currentInfo;

        _currentInfo.minePair = _info.minePair;
        _currentInfo.rewardTotalSupply = _info.rewardTotalSupply;
        _currentInfo.totalMineTime = _info.totalMineTime;
        _currentInfo.startTimeStamp = _info.startTimeStamp;
        _currentInfo.alreadyMineTime = _alreadyMineTime;
        _currentInfo.alreadyMineAmount = _alreadyMineAmount;
        _currentInfo.settlementCycle = _info.settlementCycle;
        _currentInfo.totalShare = _info.totalShare;
        _currentInfo.rewardPerShare = _rewardPerShare;
        _currentInfo.leastShare = _info.leastShare;
        _currentInfo.APR = _APR;
        _currentInfo.APY = _APY;
        _currentInfo.creator = _info.creator;
        
        return _currentInfo;
    }


    // 内部辅助函数,用来计算当前已挖矿时间:
    function _countAlreadyMineTime(
        string memory _stakeSymbol,
        string memory _rewardSymbol
        ) public virtual view returns(uint256) {
        
        // 获取当前时间:
        uint256 _current = _getTimeStamp();

        // 获取挖矿对信息映射:
        mineInfo memory _info = mineInfoMap[_stakeSymbol][_rewardSymbol];

        // 获取挖矿开始时间:
        uint256 _startTime = _info.startTimeStamp;

        // 如果挖矿开始时间为0,则说明挖矿还未开始,已挖时间直接返回0即可,如果不为0,则作减法计算:
        if(_startTime == 0) {
            return 0;
        } 

        // 如果当前时间已超过挖矿结束时间,则返回总挖矿时间:
        if(_startTime + _info.totalMineTime <= _current) {
            return(_info.totalMineTime);
        }

        return (_current - _startTime);
    }


    // 内部辅助函数,用来计算某挖矿对截至最近一次结算周期时已经挖得的收益代币的总数量:
    function _countAlreadyMineAmount(
        string memory _stakeSymbol,
        string memory _rewardSymbol
        ) public virtual view returns(uint256) {

        // 计算已结算期数:
        uint256 _countCycle = _alreadyMineCycle(_stakeSymbol, _rewardSymbol);
        
        // 获取每个结算周期产币总数量:
        uint256 _rewardByCycle = _cycleReward(_stakeSymbol, _rewardSymbol);

        return(_countCycle * _rewardByCycle);   
    }   
   
    
    // 内部辅助函数,用来计算某挖矿对当前结算周期的每份额产币量(实时变动):
    // 注意:在当前结算周期内加入质押挖矿的用户不能得到本结算周期的份额收益,需要从下一结算周期开始计算:
    // 注意:在当前结算周期内退出质押挖矿的用户同样不能得到本结算周期的份额收益
    function _countRewardPerShare(
        string memory _stakeSymbol,
        string memory _rewardSymbol
        ) public virtual view returns(uint256) {

        // 获取每个结算周期收益代币的总产币数量:
        uint256 _totalCycleReward = _cycleReward(_stakeSymbol, _rewardSymbol);

        // 计算当前周期参与收益分配的总份额数:
        uint256 _shareByReward = _addUpShareByReward(_stakeSymbol, _rewardSymbol) / 1e18;

        // 计算当前结算周期的每份额累计产出:
        if(_shareByReward == 0) {  // 0不能作除数,单独讨论
            return 0;
        } else {
            return(_totalCycleReward / _shareByReward);           
        }
    }


    // 内部辅助函数,用来计算实时年利率(APR):


    // 内部辅助函数,用来计算实时年溢率(APY):


    // 内部辅助函数,用来计算当前已结算期数:
    function _alreadyMineCycle(
        string memory _stakeSymbol,
        string memory _rewardSymbol
        ) public virtual view returns(uint256) {
     
        // 计算当前已挖矿时间:
        uint256 _alreadyMineTime = _countAlreadyMineTime(_stakeSymbol, _rewardSymbol);

        // 获取挖矿对信息映射
        mineInfo memory _info = mineInfoMap[_stakeSymbol][_rewardSymbol];  

        // 已结算期数 = 已挖矿时间 / 结算周期, 其结果向下取整就是已结算期数
        return(_alreadyMineTime / _info.settlementCycle);
    }


    // 内部辅助函数,用来计算当前周期参与收益分配的总份额数:
    // 注意:在当前结算周期内加入质押挖矿的用户不能得到本结算周期的份额收益,需要从下一结算周期开始计算:
    // 注意:在当前结算周期内退出质押挖矿的用户同样不能得到本结算周期的份额收益
    function _addUpShareByReward(
        string memory _stakeSymbol,
        string memory _rewardSymbol
        ) public virtual view returns(uint256) {
        
        // 获取总份额:
        mineInfo memory _info = mineInfoMap[_stakeSymbol][_rewardSymbol];  
        uint256 _totalShare = _info.totalShare;

        // 获取已结算期数:
        uint256 _countMineCycle = _alreadyMineCycle(_stakeSymbol, _rewardSymbol);

        // 减去当前周期新加入的份额就是当前周期参与收益分配的总份额数:
        // 这里必须注意:在挖矿第一个结算周期内,已结算期数也是0(跟未开始挖矿时一样)
        // 在第一个结算周期内,收益是算给在未开始挖矿前就质押的用户的,不需要减去shareUpdateMap
        if(_countMineCycle == 0) {
            return _totalShare;
        }

        return(_totalShare - shareUpdateMap[_stakeSymbol][_rewardSymbol][_countMineCycle + 1]);
    }

    
    // 内部辅助函数,用来查询某挖矿对某用户的份额:
    function _queryMinerShare(
        string memory _stakeSymbol,
        string memory _rewardSymbol,
        address _address
        ) public virtual view returns(uint256) {

        // 先检查该挖矿对是否存在:
        _minePairExsistOrNot(_stakeSymbol, _rewardSymbol);    

        return(minerShareMap[_stakeSymbol][_rewardSymbol][_address]);
    }   

    
    // 内部辅助函数,用来查询某挖矿对某用户的累计实现收益,可提取收益和已提取收益:
    function _queryWithdrawInfo(
        string memory _stakeSymbol,
        string memory _rewardSymbol,
        address _address
        ) public virtual view returns(uint256, uint256, uint256) {
        
        // 先检查该挖矿对是否存在:
        _minePairExsistOrNot(_stakeSymbol, _rewardSymbol);  

        // 获取累计实现收益:
        uint256 _totalRewardByStaker = _getTotalReward(_stakeSymbol, _rewardSymbol, _address);

        // 获取可提取收益:
        uint256 _canWithdrawReward = _getCanWithdrawReward(_stakeSymbol, _rewardSymbol, _address);

        // 获取已提取收益:
        uint256 _totalWithdrawReward = _getAlreadyWithdrawReward(_stakeSymbol, _rewardSymbol, _address);

        return(_totalRewardByStaker, _canWithdrawReward, _totalWithdrawReward);
    }


    // 内部辅助函数,用来查询某挖矿对某用户所有的质押与取消质押情况:
    function _queryAllStakeRecord(
        string memory _stakeSymbol,
        string memory _rewardSymbol,
        address _address
        ) public virtual view returns(AllStakeRecord memory) {

        // 先检查该挖矿对是否存在:
        _minePairExsistOrNot(_stakeSymbol, _rewardSymbol);    

        return(allStakeRecordMap[_stakeSymbol][_rewardSymbol][_address]);
    }


    // 内部辅助函数,用来查询某挖矿对某结算周期最终的计算收益的总份额数:
    function _queryRewardShareByCycle(
        string memory _stakeSymbol,
        string memory _rewardSymbol,
        uint256 _cycle
        ) public virtual view returns(int256) {
            
        // 先检查该挖矿对是否存在:
        _minePairExsistOrNot(_stakeSymbol, _rewardSymbol);  

        return(finalShareMap[_stakeSymbol][_rewardSymbol][_cycle]);
    }


    // 内部辅助函数,用来添加挖矿对及其相关初始化信息:
    function _addMinePair(
        address _stakeToken, 
        address _rewardToken,
        uint256 _rewardTotalSupply,
        uint256 _totalMineTime,
        uint256 _settlementCycle,
        uint256 _leastShare
        ) public virtual {

        // 先检查待添加的挖矿对是否至少已完成一轮挖矿活动,如果是,则提示用户去调用update函数:
        _isFinishOrNotByAdd(_stakeToken, _rewardToken);

        // 获取质押代币和收益代币的symbol:
        string memory _stakeSymbol = _getTokenSymbol(_stakeToken);
        string memory _rewardSymbol = _getTokenSymbol(_rewardToken);

        // 再检查交易对Symbol是否存在:
        // 前面已经排除了挖矿对存在但挖矿活动已结束需要进行第N轮挖矿的情况
        // 因此如果挖矿对symbol存在,一定是出现了同Symbol的质押代币或收益代币
        // 例如:存在了A-B挖矿对,作恶分子发一个同symbol的A币,创建了A(假)-B挖矿对
        _minePairExsistOrNotByAdd(_stakeSymbol, _rewardSymbol);

        // 检查挖矿总时间是否是挖矿结算周期的整数倍:
        uint256 _totalCycle = _isIntMulAndReturnTotalCycle(_totalMineTime, _settlementCycle);

        // 检查挖矿对收益代币的总供给是否是挖矿结算总周期数的整数倍(保证每周期收益代币供给为整数):
        _checkIntMulOrNot(_rewardTotalSupply, _totalCycle);
        
        // 获取挖矿对创始人地址:
        address _creator = _msgSender();

        // 将创建人的收益代币转到本合约:
        // 注意需要先在ERC20合约中对本合约地址进行approve授权
        _transferRewardToken(_creator, _rewardToken, _rewardTotalSupply);

        // 新增已存在挖矿对的映射:
        exsistMinePair[_stakeSymbol][_rewardSymbol] = true;

        // 创建stakeAndReward结构体:
        stakeAndReward memory _addrInfo;
        _addrInfo.stakeTokenAddr = _stakeToken;
        _addrInfo.rewardTokenAddr = _rewardToken;
        
        // 创建mineInfo结构体:
        mineInfo memory _info; 
        _info.minePair = _addrInfo;
        _info.rewardTotalSupply = _rewardTotalSupply;
        _info.totalMineTime = _totalMineTime;
        _info.settlementCycle = _settlementCycle;
        _info.leastShare = _leastShare;
        _info.creator = _creator;

        // 创建挖矿对信息映射:
        mineInfoMap[_stakeSymbol][_rewardSymbol] = _info;

        emit minePairCreator(_stakeToken, _rewardToken, _creator);
        emit addMinePairRewardTotalSupply(_stakeToken, _rewardToken, _rewardTotalSupply);
        emit addMinePairTotalMineTime(_stakeToken, _rewardToken, _totalMineTime);
        emit addMinePairSettlementCycle(_stakeToken, _rewardToken, _settlementCycle);
        emit addMinePairLeastShare(_stakeToken, _rewardToken, _leastShare);
    }


    // 内部辅助函数,用来供用户进行质押挖矿:
    function _stake(
        address _stakeToken,
        address _rewardToken,
        uint256 _amount
        ) public virtual {

        // 获取质押代币和收益代币的symbol:
        string memory _stakeSymbol = _getTokenSymbol(_stakeToken);
        string memory _rewardSymbol = _getTokenSymbol(_rewardToken);
        
        // 先检查该挖矿对是否存在:
        _minePairExsistOrNot(_stakeSymbol, _rewardSymbol);    

        // 再检查该挖矿对是否已经结束挖矿:
        _isFinishOrNotByStake(_stakeToken, _rewardToken);

        // 检查当前是否已经是最后一个结算周期,如果是,则提示已不能参与质押:
        _isLastCycle(_stakeSymbol, _rewardSymbol);

        // 获取质押用户地址:
        address _staker = _msgSender();

        // 向合约转质押代币:
        _transferStakeTokenToContract(_stakeToken, _amount, _staker);

        // 更新对应的信息(包括份额,质押人信息):
        _updateStakeInfo(_stakeSymbol, _rewardSymbol, _amount, _staker);

        // 判断挖矿是否开始,如果未开始,看加上此质押用户的份额后是否达到开始条件,如果达到开始条件,则开始挖矿并更新相应实时信息:
        _isMineOrNot(_stakeSymbol, _rewardSymbol);

        // 拼接挖矿对:
        string memory _minePair = _jointMinePair(_stakeSymbol, _rewardSymbol);

        emit stakeToken(_minePair, _staker, _amount);
    }

    
    // 内部辅助函数,用来撤销质押挖矿:
    function _unStake(
        address _stakeToken,
        address _rewardToken,
        uint256 _amount
        ) public virtual {
        
        // 获取质押代币和收益代币的symbol:
        string memory _stakeSymbol = _getTokenSymbol(_stakeToken);
        string memory _rewardSymbol = _getTokenSymbol(_rewardToken);
        
        // 先检查该挖矿对是否存在:
        _minePairExsistOrNot(_stakeSymbol, _rewardSymbol);    

        // 获取质押用户地址:
        address _unStaker = _msgSender();

        // 再检查该挖矿对撤销者是否有至少_amount数量的份额:
        _isEnoughByUnStake(_stakeSymbol, _rewardSymbol, _amount, _unStaker);

        // 将撤销的质押代币转入撤销者账户:
        _transferStakeTokenToUnStaker(_stakeToken, _amount, _unStaker);

        // 更新对应的信息(包括份额,质押人信息)
        _updataUnStakeInfo(_stakeSymbol, _rewardSymbol, _amount, _unStaker);

        // 拼接挖矿对:
        string memory _minePair = _jointMinePair(_stakeSymbol, _rewardSymbol);

        emit unStakeToken(_minePair, _unStaker, _amount);
    }


    // 内部辅助函数,用来提取某挖矿对的收益:
    function _withdraw(
        address _stakeToken, 
        address _rewardToken,
        uint256 _amount
        ) public virtual {

        // 获取质押代币和收益代币的symbol:
        string memory _stakeSymbol = _getTokenSymbol(_stakeToken);
        string memory _rewardSymbol = _getTokenSymbol(_rewardToken);

        // 先检查该挖矿对是否存在:
        _minePairExsistOrNot(_stakeSymbol, _rewardSymbol);

        // 获取提币用户地址:
        address _user = _msgSender();   

        // 检查是否有足够数量的代币可供提取:
        _isEnoughByWithdraw(_stakeSymbol, _rewardSymbol, _amount, _user);

        // 提取代币:
        _withdrawRewardToken(_rewardToken, _amount, _user);

        // 更新minerWithdrawMap映射:
        minerWithdrawMap[_stakeSymbol][_rewardSymbol][_user] += _amount;   

        // 拼接挖矿对:
        string memory _minePair = _jointMinePair(_stakeSymbol, _rewardSymbol); 

        emit withdrawToken(_minePair, _user, _amount);
    }


    // 内部辅助函数,用来计算某挖矿对某质押用户的累计实现收益:
    function _getTotalReward(
        string memory _stakeSymbol,
        string memory _rewardSymbol,
        address _user
        ) public virtual view returns(uint256) {
        
        // 先检查该挖矿对是否存在:
        _minePairExsistOrNot(_stakeSymbol, _rewardSymbol);   

        // 获取当前已结算周期:
        uint256 _mineCycle = _alreadyMineCycle(_stakeSymbol, _rewardSymbol);

        uint256 _userTotalReward;

        // 遍历每轮用户的份额和总份额,计算占比,得出每轮收益:
        for(uint256 i = 1; i <= _mineCycle; i++) {
            uint256 _userCycleShare = _countCycleShareByStaker(_stakeSymbol, _rewardSymbol, i, _user);
            uint256 _totalCycleShare = _countShareByCycle(_stakeSymbol, _rewardSymbol, i);
            uint256 _userCycleReward = _countUserCycleReward(_stakeSymbol, _rewardSymbol, _userCycleShare, _totalCycleShare);
            _userTotalReward += _userCycleReward;
        }

        return _userTotalReward;
    }


    // 内部辅助函数,用来计算某挖矿对某质押用户的可提取收益:
    function _getCanWithdrawReward(
        string memory _stakeSymbol,
        string memory _rewardSymbol,
        address _user
        ) public virtual view returns(uint256) {
        
        // 先检查该挖矿对是否存在:
        _minePairExsistOrNot(_stakeSymbol, _rewardSymbol);  

        // 计算用户该挖矿对累计实现收益:
        uint256 _userTotalReward = _getTotalReward(_stakeSymbol, _rewardSymbol, _user);

        // 获取用户该挖矿对已提取收益:
        uint256 _userWithdrawReward = _getAlreadyWithdrawReward(_stakeSymbol, _rewardSymbol, _user);

        return(_userTotalReward - _userWithdrawReward);  
    }

    
    // 内部辅助函数,用来查询某挖矿对某质押用户的已提取收益:
    function _getAlreadyWithdrawReward(
        string memory _stakeSymbol,
        string memory _rewardSymbol,
        address _user
        ) public virtual view returns(uint256) {
        
        // 先检查该挖矿对是否存在:
        _minePairExsistOrNot(_stakeSymbol, _rewardSymbol);    

        return(minerWithdrawMap[_stakeSymbol][_rewardSymbol][_user]);
    }


    // 内部辅助函数,用来计算某挖矿对某用户单个结算周期收益:
    function _countUserCycleReward(
        string memory _stakeSymbol,
        string memory _rewardSymbol,
        uint256 _userCycleShare,
        uint256 _totalCycleShare
        ) public virtual view returns(uint256) {  
             
        // 先获取该挖矿对单个结算周期总收益:
        uint256 _totalReward = _cycleReward(_stakeSymbol, _rewardSymbol);

        // 计算用户单个结算周期收益
        return(_userCycleShare * _totalReward / _totalCycleShare);
    }


    // 内部辅助函数,用来将挖矿对创建人的收益代币转移到本合约:
    function _transferRewardToken(
        address _creator,
        address _rewardToken,
        uint256 _rewardTotalSupply
        ) public virtual {
        IERC20 _token = IERC20(_rewardToken);
        // 注意需要先在ERC20合约中对本合约地址进行approve授权
        _token.transferFrom(_creator, address(this), _rewardTotalSupply);
    }


    // 内部辅助函数,用来向本合约转质押代币
    // (记得先给本合约地址Approve至少_amount数量的代币):
    function _transferStakeTokenToContract(
        address _stakeToken,
        uint256 _amount,
        address _staker
        ) public virtual {
        IERC20 _token = IERC20(_stakeToken);
        _token.transferFrom(_staker, address(this), _amount);
    }


    // 内部辅助函数,用来将撤销的质押代币转入撤销者账户:
    function _transferStakeTokenToUnStaker(
        address _stakeToken,
        uint256 _amount,
        address _unStaker
        ) public virtual {
        IERC20 _token = IERC20(_stakeToken);
        _token.transfer(_unStaker, _amount);
    }


    // 内部辅助函数,用来实现收益代币的提取:
    function _withdrawRewardToken(
        address _rewardToken,
        uint256 _amount,
        address _user
        ) public virtual {
        IERC20 _token = IERC20(_rewardToken);
        _token.transfer(_user, _amount);
    }


    // 内部辅助函数,用来检查某挖矿对是否已至少完成一轮挖矿活动(供_addMinePair函数调用):
    function _isFinishOrNotByAdd(address _stakeToken, address _rewardToken) public virtual view {
        require(!alreadyFinish[_stakeToken][_rewardToken], 
                "Sorry, this minePair already completed at least a round of mining, please call the update function");
    }


    // 内部辅助函数,用来检查某挖矿对是否已经结束挖矿(供_stake函数调用):
    function _isFinishOrNotByStake(address _stakeToken, address _rewardToken) public virtual view {
        require(!alreadyFinish[_stakeToken][_rewardToken],
                "Sorry, this minePair has finished mining");
    }


    // 内部辅助函数,用来检查挖矿对是否已存在(供_addMinePair函数调用):
    function _minePairExsistOrNotByAdd(
        string memory _stakeSymbol, 
        string memory _rewardSymbol
        ) public virtual view {    
        require(!exsistMinePair[_stakeSymbol][_rewardSymbol],
                "Sorry, this minePair-Symbol has already exsisted, You can't add the same Symbol minePair");
    } 


    // 内部辅助函数,用来检查挖矿对是否已存在(供_stake/_unStake/_withdraw............函数调用):
    function _minePairExsistOrNot(
        string memory _stakeSymbol, 
        string memory _rewardSymbol
        ) public virtual view {
        require(exsistMinePair[_stakeSymbol][_rewardSymbol],
                "Sorry, this minePair isn't exsist");
    } 


    // 检查当前是否已经是最后一个结算周期,如果是,则提示已不能参与质押:
    function _isLastCycle(
        string memory _stakeSymbol,
        string memory _rewardSymbol
        ) public virtual view {

        // 获取已结算期数:
        uint256 _countMineCycle = _alreadyMineCycle(_stakeSymbol, _rewardSymbol);

        // 计算总期数:
        uint256 _totalCycle = _countTotalCycle(_stakeSymbol, _rewardSymbol);

        // 假如总结算周期为50,现在已结算期数为49(即现处于第50个结算周期内,那么则不能参与质押):
        require(_countMineCycle < _totalCycle - 1,
                "Sorry, this is the last settlement cycle, there will be no reward from participating now");
    }

    
    // 内部辅助函数,用来获取某代币的Symbol:
    function _getTokenSymbol(address _tokenAddr) public virtual view returns(string memory) {
        ERC20 _token = ERC20(_tokenAddr);
        return(_token.symbol());
    }

    
    // 内部辅助函数,用来检查设置的挖矿总时间是否是挖矿结算周期的整数倍:
    // 如果是整数倍,则计算结算总周期数并返回
    // 同时检查输入的_totalMineTime和_settlementCycle是否为0,如果是,则提示用户输入错误
    function _isIntMulAndReturnTotalCycle(
        uint256 _totalMineTime, 
        uint256 _settlementCycle
        ) public virtual pure returns(uint256) { 
        require(_totalMineTime != 0, "totalMineTime must be greater than 0");
        require(_settlementCycle != 0, "settlementCycle must be greater than 0");
        require(_totalMineTime % _settlementCycle == 0,
                "The total time must be an intergral multiple of the cycle");
        return(_totalMineTime / _settlementCycle);
    }


    // 内部辅助函数,用来检查挖矿对收益代币的总供给是否是挖矿结算总周期数的整数倍(保证每周期收益代币供给为整数):
    function _checkIntMulOrNot(uint256 _rewardTotalSupply, uint256 _totalCycle) public virtual pure {
        // 得检查挖矿对收益代币的总供给是否为0:
        require(_rewardTotalSupply != 0, "rewardTotalSupply must be greater than 0");     
        require(_rewardTotalSupply % _totalCycle == 0, 
                "The rewardSupply in every cycle must be an intergral multiple of the cycle");
    }


    // 内部辅助函数,用来获取当前时间戳:
    function  _getTimeStamp() public virtual view returns(uint256) {
        return block.timestamp;
    }


    // 内部辅助函数,用来将挖矿对拼接成一个string:
    function _jointMinePair(
        string memory _stakeSymbol,
        string memory _rewardSymbol
        ) public virtual pure returns(string memory) {
        string memory STR = string.concat(_stakeSymbol, "---");
        STR = string.concat(STR, _rewardSymbol);
        return STR;
    }


    // 内部辅助函数,用来计算某挖矿对每个挖矿结算周期的总收益:
    function _cycleReward(
        string memory _stakeSymbol,
        string memory _rewardSymbol
        ) public virtual view returns(uint256) {
        // 获取挖矿对信息映射
        mineInfo memory _info = mineInfoMap[_stakeSymbol][_rewardSymbol];
        return(_info.rewardTotalSupply / (_info.totalMineTime / _info.settlementCycle));
    }


    // 内部辅助函数,用来计算某挖矿对有多少个结算周期:
    function _countTotalCycle(
        string memory _stakeSymbol,
        string memory _rewardSymbol
        ) public virtual view returns(uint256) {
        // 获取挖矿对信息映射
        mineInfo memory _info = mineInfoMap[_stakeSymbol][_rewardSymbol];
        return(_info.totalMineTime / _info.settlementCycle);        
    }


    // 内部辅助函数,供_stake函数调用,用来更新质押信息:
    function _updateStakeInfo(
        string memory _stakeSymbol,
        string memory _rewardSymbol,
        uint256 _amount,
        address _staker
        ) public virtual {

        // 获取已结算期数:
        uint256 _countMineCycle = _alreadyMineCycle(_stakeSymbol, _rewardSymbol);

        // 更新finalShareMap映射,finalShareByStaker映射和stakeCycleRecordMap映射:
        _updateFinalShareByStake(_stakeSymbol, _rewardSymbol, _amount, _countMineCycle, _staker);
    
        // 更新allStakeRecordMap映射:
        _updateAllStakeRecordByStake(_stakeSymbol, _rewardSymbol, _amount, _countMineCycle, _staker);

        // 更新份额信息:
        minerShareMap[_stakeSymbol][_rewardSymbol][_staker] += _amount;
        shareUpdateMap[_stakeSymbol][_rewardSymbol][_countMineCycle + 1] += _amount;
        mineInfoMap[_stakeSymbol][_rewardSymbol].totalShare += _amount;

        // 挖矿对新增质押者:
        minerAddr[_stakeSymbol][_rewardSymbol].push(_staker);
    }


    // 内部辅助函数,供_unStake函数调用,用来更新撤销质押的信息(包括份额,质押人信息)
    function _updataUnStakeInfo(
        string memory _stakeSymbol,
        string memory _rewardSymbol,
        uint256 _amount,   
        address _unStaker
        ) public virtual {

        // 获取已结算期数:
        uint256 _countMineCycle = _alreadyMineCycle(_stakeSymbol, _rewardSymbol);     

        // 更新finalShareMap映射和finalShareByStakerMap映射:
        _updateFinalShareByUnStake(_stakeSymbol, _rewardSymbol, _amount, _countMineCycle, _unStaker);

        // 更新allStakeRecordMap映射:
        _updateAllStakeRecordByUnStake(_stakeSymbol, _rewardSymbol, _amount, _countMineCycle, _unStaker);  

        // 更新份额信息:
        minerShareMap[_stakeSymbol][_rewardSymbol][_unStaker] -= _amount;
        mineInfoMap[_stakeSymbol][_rewardSymbol].totalShare -= _amount;

        // 检查份额是否已为0,如果是,则撤销挖矿者信息:
        if(minerShareMap[_stakeSymbol][_rewardSymbol][_unStaker] == 0) {
            for(uint i = 0; i < minerAddr[_stakeSymbol][_rewardSymbol].length; i++) {
                if(minerAddr[_stakeSymbol][_rewardSymbol][i] == _unStaker) {
                    // 用数组最后一个地址进行覆盖,然后把数组最后一个pop掉,如果本来就是数组最后一个,则直接pop
                    if(i != minerAddr[_stakeSymbol][_rewardSymbol].length - 1) {
                        minerAddr[_stakeSymbol][_rewardSymbol][i] 
                      = minerAddr[_stakeSymbol][_rewardSymbol][minerAddr[_stakeSymbol][_rewardSymbol].length - 1];                       
                    }
                    minerAddr[_stakeSymbol][_rewardSymbol].pop(); 
                    break;
                }
            }   
        }
    }


    // 内部辅助函数,用来更新finalShareMap映射,finalShareByStaker映射和stakeCycleRecordMap映射(用于stake):
    function _updateFinalShareByStake(
        string memory _stakeSymbol,
        string memory _rewardSymbol,
        uint256 _amount,
        uint256 _countMineCycle,
        address _staker
        ) public virtual {
        
        // 如果已结算期数为0,要分挖矿是否开始讨论:
        if(_countMineCycle == 0) {
            bool _state = _checkStartOrNot(_stakeSymbol, _rewardSymbol);
            // 如果挖矿已开始,则新加入的质押份额要算在第2结算周期内;如果未开始,则算在第1结算周期内:
            if(_state) {
                finalShareMap[_stakeSymbol][_rewardSymbol][2] += int256(_amount);
                finalShareByStakerMap[_stakeSymbol][_rewardSymbol][_staker][2] += int256(_amount);
                stakeCycleRecordMap[_stakeSymbol][_rewardSymbol][_staker][2] += _amount;
            } else {
                finalShareMap[_stakeSymbol][_rewardSymbol][1] += int256(_amount);
                finalShareByStakerMap[_stakeSymbol][_rewardSymbol][_staker][1] += int256(_amount);
                stakeCycleRecordMap[_stakeSymbol][_rewardSymbol][_staker][1] += _amount;
            }
        } else {
            // 如果已结算期数不为0,则新加入的质押份额算在第_countMineCycle + 2结算周期内:
            finalShareMap[_stakeSymbol][_rewardSymbol][_countMineCycle + 2] += int256(_amount);     
            finalShareByStakerMap[_stakeSymbol][_rewardSymbol][_staker][_countMineCycle + 2] += int256(_amount);                 
            stakeCycleRecordMap[_stakeSymbol][_rewardSymbol][_staker][_countMineCycle + 2] += _amount;      
        }  
    }


    // 内部辅助函数,用来更新finalShareMap映射和finalShareByStakerMap映射(用于unStake):
    function _updateFinalShareByUnStake(
        string memory _stakeSymbol,
        string memory _rewardSymbol,
        uint256 _amount,
        uint256 _countMineCycle,
        address _unStaker
        ) public virtual {
        
        // 判断有没有当前周期质押然后又当前周期取消质押的情况:

        // 该用户总份额数:
        uint256 _totalShareByUnStaker = minerShareMap[_stakeSymbol][_rewardSymbol][_unStaker];
        // 下结算周期才产生收益的份额数量:
        uint256 _nextCycleShare = stakeCycleRecordMap[_stakeSymbol][_rewardSymbol][_unStaker][_countMineCycle + 2];

        // 如果取消质押的份额数量大于当前结算周期产生收益的份额,则说明当前结算周期才质押进去的份额有被取消质押的部分:
        if(_totalShareByUnStaker - _nextCycleShare < _amount) {
            uint256 _tmp = _totalShareByUnStaker - _nextCycleShare;
            finalShareMap[_stakeSymbol][_rewardSymbol][_countMineCycle + 1] -= int256(_tmp);     
            finalShareMap[_stakeSymbol][_rewardSymbol][_countMineCycle + 2] -= int256(_amount - _tmp);  
            finalShareByStakerMap[_stakeSymbol][_rewardSymbol][_unStaker][_countMineCycle + 1] -= int256(_tmp);
            finalShareByStakerMap[_stakeSymbol][_rewardSymbol][_unStaker][_countMineCycle + 2] -= int256(_amount - _tmp);  
        } else {
            finalShareMap[_stakeSymbol][_rewardSymbol][_countMineCycle + 2] -= int256(_amount);    
            finalShareByStakerMap[_stakeSymbol][_rewardSymbol][_unStaker][_countMineCycle + 2] -= int256(_amount);                  
        }
    }   


    // 内部辅助函数,用来更新allStakeRecordMap映射(用于stake):
    function _updateAllStakeRecordByStake(
        string memory _stakeSymbol,
        string memory _rewardSymbol, 
        uint256 _amount,
        uint256 _countMineCycle,
        address _staker
        ) public virtual {

        StakeRecord memory _newRecord;
        _newRecord.stake = true;
        _newRecord.amount = _amount;

        // 如果已结算期数为0,要分挖矿是否开始讨论:
        if(_countMineCycle == 0) {
            bool _state = _checkStartOrNot(_stakeSymbol, _rewardSymbol);
            // 如果挖矿已开始,则新加入的质押份额要算在第2结算周期内;如果未开始,则算在第1结算周期内:
            if(_state) {
                _newRecord.cycle = 2;
            } else {
                _newRecord.cycle = 1;
            }
        } else {
            // 如果已结算期数不为0,则新加入的质押份额算在第_countMineCycle + 2结算周期内:
            _newRecord.cycle = _countMineCycle + 2;
        }  

        allStakeRecordMap[_stakeSymbol][_rewardSymbol][_staker].allRecord.push(_newRecord);
    }


    // 内部辅助函数,用来更新allStakeRecordMap映射(用于unStake):
    function _updateAllStakeRecordByUnStake(
        string memory _stakeSymbol,
        string memory _rewardSymbol,
        uint256 _amount,
        uint256 _countMineCycle,
        address _unStaker 
        ) public virtual {
        StakeRecord memory _newRecord;
        _newRecord.stake = false;
        _newRecord.amount = _amount;
        _newRecord.cycle = _countMineCycle + 1;
        allStakeRecordMap[_stakeSymbol][_rewardSymbol][_unStaker].allRecord.push(_newRecord);
    }


    // 内部辅助函数,用来计算某挖矿对每个结算周期参与收益结算的总份额:
    function _countShareByCycle(
        string memory _stakeSymbol,
        string memory _rewardSymbol,
        uint256 _cycle
        ) public virtual view returns(uint256) {
        
        int256 _totalShareByCycle;
        
        // 遍历每个结算周期收益变动,然后累加:
        for(uint256 i = 1; i <= _cycle; i++) {
            int256 _singleCycleShare = finalShareMap[_stakeSymbol][_rewardSymbol][i];
            _totalShareByCycle += _singleCycleShare;
        }

        return uint256(_totalShareByCycle);
    }


    // 内部辅助函数,用来计算某挖矿对某用户每个结算周期参与收益结算的总份额:
    function _countCycleShareByStaker(
        string memory _stakeSymbol,
        string memory _rewardSymbol,
        uint256 _cycle,
        address _staker
        ) public virtual view returns(uint256) {

        int256 _totalShareByCycle;
        
        // 遍历每个结算周期收益变动,然后累加:
        for(uint256 i = 1; i <= _cycle; i++) {
            int256 _singleCycleShare = finalShareByStakerMap[_stakeSymbol][_rewardSymbol][_staker][i];
            _totalShareByCycle += _singleCycleShare;    
        }

        return uint256(_totalShareByCycle);
    }


    // 内部辅助函数,用来检查挖矿是否已开始:
    // 检查原理:看挖矿已挖时间是否为0
    function _checkStartOrNot(
        string memory _stakeSymbol,
        string memory _rewardSymbol
        ) public virtual view returns(bool) {
        
        // 获取挖矿已挖时间
        uint256 _mineTime = _countAlreadyMineTime(_stakeSymbol, _rewardSymbol);

        if(_mineTime > 0) {
            return true;
        }
        return false;
    }


    // 内部辅助函数,检查挖矿是否开始
    // 如果未开始,看加上此质押用户的份额后是否达到开始条件
    // 如果达到开始条件,则开始挖矿并更新相应实时信息:
    function _isMineOrNot(
        string memory _stakeSymbol,
        string memory _rewardSymbol
        ) public virtual {

        // 获取挖矿对信息映射
        mineInfo memory _info = mineInfoMap[_stakeSymbol][_rewardSymbol];  

        // 检查挖矿是否开始:
        // 如果挖矿开始时间戳为0,说明未开始挖矿
        if(_info.startTimeStamp == 0) {
            // 如果加上该质押者的份额后大于等于开始挖矿的最小份额,则开始挖矿
            if(_info.totalShare  >= _info.leastShare) {
                // 更新开始挖矿的时间
                mineInfoMap[_stakeSymbol][_rewardSymbol].startTimeStamp = _getTimeStamp();
            }
        }
    }


    // 内部辅助函数,用来检查撤销者是否有至少_amount数量的份额:
    function _isEnoughByUnStake(
        string memory _stakeSymbol,
        string memory _rewardSymbol,
        uint256 _amount,
        address _unStaker
        ) public virtual view {
        
        // 如果用户输入的_amount(撤销份额)为0,则报错提示用户需要输入一个大于0的值:
        require(_amount > 0, "unStakeShare must be greater than 0"); 

        // 如果用户不是质押用户,则报错提示:
        require(minerShareMap[_stakeSymbol][_rewardSymbol][_unStaker] != 0,
                "Sorry, you are not a staker");

        // 如果用户撤销的份额大于质押份额,则报错:
        require(minerShareMap[_stakeSymbol][_rewardSymbol][_unStaker] >= _amount,
                "Sorry, not enough share to revoke");
    }


    // 内部辅助函数,用来检查是否有足够数量的代币可供提取:
    function _isEnoughByWithdraw(
        string memory _stakeSymbol,
        string memory _rewardSymbol,
        uint256 _amount,
        address _user
        ) public virtual view {

        // 如果用户输入的_amount(提币数量)为0,则报错提示用户需要输入一个大于0的值:
        require(_amount > 0, "withdraw amount must be greater than 0"); 

        // 如果用户不是质押用户,则报错提示:
        require(minerShareMap[_stakeSymbol][_rewardSymbol][_user] != 0,
                "Sorry, you are not a staker");

        // 获取可提取收益:
        uint256 _canWithdrawReward = _getCanWithdrawReward(_stakeSymbol, _rewardSymbol, _user);

        // 如果用户提币的数量大于可提取收益,则报错:
        require(_canWithdrawReward >= _amount, "Sorry, you don't have so much reward to withdraw");
    }

}