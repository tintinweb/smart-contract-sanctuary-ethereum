/**
 *Submitted for verification at Etherscan.io on 2022-07-07
*/

pragma solidity =0.8.13;

contract LiquidEvents{

    event collectionAdded(
        address NFT_CONTRACT_ADDRESS,
        uint256 timestamp
    );

    event depositFundsEvent(
        address indexed pool,
        address poolToken,
        address indexed user,
        uint256 amount,
        uint256 additionalShares,
        uint256 timestamp
    );

    event withdrawFundsInternalSharesEvent(
        address indexed pool,
        address poolToken,
        address indexed user,
        uint256 amount,
        uint256 shares,
        uint256 timeStamp
    );

    event withdrawFundsTokenizedSharesEvent(
        address indexed pool,
        address poolToken,
        address indexed user,
        uint256 amount,
        uint256 shares,
        uint256 timestamp
    );

    event updateCollectionRequestEvent(
        uint256 unlockTime,
        uint256 maxBorrowTokens,
        bytes32 merkleRoot,
        string Ipfs,
        address indexed caller,
        uint256 timestamp
    );

    event changeDiscountPercLiqudAndFeeEvent(
        address indexed pool,
        uint256 oldFactor,
        uint256 newFactor,
        uint256 timestamp
    );

    event borrowFundsEvent(
        address indexed NFT_CONTRACT_ADDRESS,
        address indexed borrower,
        uint256 tokenID,
        uint256 nextDueTime,
        uint256 amount,
        uint256 timestamp
    );

    event paybackFundsEvent(
        address indexed NFT_CONTRACT_ADDRESS,
        address indexed tokenOwner,
        uint256 totalPayment,
        uint256 nextDueTime,
        uint256 penaltyAmount,
        uint256 tokenID,
        uint256 timestamp
    );

    event liquidateNFTEvent(
        address indexed NFT_CONTRACT_ADDRESS,
        address indexed previousOwner,
        address indexed liquidator,
        uint256 discountAmount,
        uint256 tokenID,
        uint256 timestamp
    );

    event liquidateNFTMultisigEvent(
        address indexed NFT_CONTRACT_ADDRESS,
        address indexed previousOwner,
        address multisig,
        uint256 indexed tokenID,
        uint256 timestamp
    );

    event putFundsBackFromSellingNFTEvent(
        address indexed NFT_CONTRACT_ADDRESS,
        uint256 indexed tokenID,
        uint256 amount,
        uint256 badDebt,
        uint256 timestamp
    );

    event decreaseBadDebtEvent(
        uint256 previousBadDebt,
        uint256 indexed newBadDebt,
        uint256 paybackAmount,
        uint256 timestamp
    );

    event finishUpdateCollectionEvent(
        address indexed NFT_CONTRACT_ADDRESS,
        bool indexed newCollection,
        bytes32 merkleRoot,
        string ipfsUrl,
        uint256 maxBorrowTokens,
        uint256 timestamp
    );

}

contract AccessControl {

    //Multisig address, has highest permissions, can set workers, can set self as worker
    address public multisig;
    //Mapping to bool that is true if an address is a worker
    mapping (address => bool) public workers;

    address constant ZERO_ADDRESS = address(0x0);

    event MultisigSet(
        address newMultisig
    );

    event WorkerAdded(
        address newWorker
    );

    event WorkerRemoved(
        address existingWorker
    );

    /**
     * @dev set the multisig to the msg.sender, set msg.sender as worker
     */
    constructor() {
        multisig = msg.sender;
        workers[msg.sender] = true;
        emit MultisigSet(
            msg.sender
        );
    }

    /**
     * @dev Revert if msg.sender if not multisig
     */
    modifier onlyMultisig() {
        require(
            msg.sender == multisig,
            "AccessControl: Not Multisig"
        );
        _;
    }

    /**
     * @dev require that sender is authorized in the worker mapping, revert otherwise
     */
    modifier onlyWorker() {
        require(
            workers[msg.sender],
            "AccessControl: Not Authorized"
        );
        _;
    }

    /**
     * @dev Transfer Multisig permission
     * Call internal function that does the work
     */
    function updateMultisig(
        address _newMultisig
    )
        external
        onlyMultisig
    {
        _updateMultisig(_newMultisig);
    }

    /**
     * @dev Internal function that handles the logic of updating the multisig
     */
    function _updateMultisig(
        address _newMultisig
    )
        internal
    {
        multisig = _newMultisig;

        emit MultisigSet(
            _newMultisig
        );
    }

    /**
     * @dev Destroy Multisig functionality
     */
    function revokeMultisig()
        external
        onlyMultisig
    {
        multisig = ZERO_ADDRESS;

        emit MultisigSet(
            ZERO_ADDRESS
        );
    }

    /**
     * @dev Add a worker address to the system. Set the bool for the worker to true
     * Only multisig can do this
     */
    function addWorker(
        address _newWorker
    )
        external
        onlyMultisig
    {
        workers[_newWorker] = true;

        emit WorkerAdded(
            _newWorker
        );
    }

    /**
    * @dev Remove a worker address from the system. Set the bool for the worker to false
     * Only multisig can do this
     */
    function removeWorker(
        address _worker
    )
        external
        onlyMultisig
    {
        workers[_worker] = false;

        emit WorkerRemoved(
            _worker
        );
    }


}


library Babylonian {

    function sqrt(
        uint256 x
    )
        internal
        pure
        returns (uint256)
    {
        if (x == 0) return 0;

        uint256 xx = x;
        uint256 r = 1;
        if (xx >= 0x100000000000000000000000000000000) {
            xx >>= 128;
            r <<= 64;
        }
        if (xx >= 0x10000000000000000) {
            xx >>= 64;
            r <<= 32;
        }
        if (xx >= 0x100000000) {
            xx >>= 32;
            r <<= 16;
        }
        if (xx >= 0x10000) {
            xx >>= 16;
            r <<= 8;
        }
        if (xx >= 0x100) {
            xx >>= 8;
            r <<= 4;
        }
        if (xx >= 0x10) {
            xx >>= 4;
            r <<= 2;
        }
        if (xx >= 0x8) {
            r <<= 1;
        }
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;

        uint256 r1 = x / r;
        return (r < r1 ? r : r1);
    }
}


contract PoolBase {

    constructor(
        address _factoryAddress,
        address _routerAddress
    )
    {
        FACTORY_ADDRESS = _factoryAddress;
        ROUTER_ADDRESS = _routerAddress;
    }

    // Global instant pool properties
    // ------------------------------

    // Address of factory that creates lockers
    address public immutable FACTORY_ADDRESS;

    // Address of router
    address public immutable ROUTER_ADDRESS;

    // ERC20 deposits and use for loans
    address public poolToken;

    // Maximal factor every NFT can be collateralized in this pool
    uint256 public maxCollateralFactor;

    // Discount percentage for the liquidator when buying the NFT
    uint256 public liquidationPercentage;

    // Current usage of the pool. 1E18 <=> 100 %
    uint256 public utilization;

    // Current actual number of token inside the contract
    uint256 public totalPool;

    //current borrow rate of the pool;
    uint256 public borrowRate;

    //current mean Markov value of the pool;
    uint256 public markovMean;

    //bad debt amount in terms of poolToken correct decimals
    uint256 public badDebt;

    // Borrow rates variables
    // ----------------------

    // Pool position of borrow rate functions (divergent at x = r) 1E18 <=> 1 and r > 1E18.
    uint256 public resonanceFactor;

    // Stepping size
    uint256 public deltaResonaceFactor;

    // Global minimum value for the resonanz factor
    uint256 public minResonaceFactor;

    // Global maximum value for the resonanz factor
    uint256 public maxResonaceFactor;

    // Individual multiplication factor scaling the y-axes (static after deployment of pool)
    uint256 public multiplicativeFactor;

    // Tracks the last interaction with the pool
    uint256 public timeStampLastInteraction;

    // Scaling algorithm variables
    // --------------------------

    // Tracks the resonanz factor which corresponds to maxValue
    uint256 public bestResonanceFactor;

    // Tracks the maximal value of shares the pool has ever reached
    uint256 public maxValue;

    //tracks the previous value of shares from the last round the
    //algorithm was executed
    uint256 public previousValue;

    // Tracks time when scaling algorithem has been triggerd last time
    uint256 public timeStampLastAlgorithm;

    // Switch for stepping directions
    bool public increaseResonanceFactor;

    bool public isExpandable;

    // Global constants
    // ----------------

    uint256 constant ONE_YEAR = 52 weeks;
    uint256 constant THREE_HOURS = 3 hours;
    uint256 constant FIVE_PERCENT = 5E18;

    uint256 constant NORM_FACTOR_SECONDS_IN_TWO_MONTH = 8 weeks;

    uint256 constant PRECISION_FACTOR_E18 = 1E18;
    uint256 constant PRECISION_FACTOR_E20 = 1E20;
    uint256 constant PRECISION_FACTOR_E36 = 1E36;

    uint256 constant ONE_HUNDRED = 100;
    uint256 constant SECONDS_IN_DAY = 86400;

    uint256 constant public maximumTimeBetweenPayments = 35 days;

    // Value determing weight of new value in markov chain (0.1 <=> 1E17)
    uint256 constant MARKOV_FRACTION = 2E16; //2%

    // Threshold for resetting resonanz factor
    uint256 constant THRESHOLD_RESET_RESONANZ_FACTOR = 75;

    // Threshold for reverting stepping cirection
    uint256 constant THRESHOLD_SWITCH_DIRECTION = 90;

    // Absulute max value for borrow rate
    uint256 constant UPPER_BOUND_MAX_RATE = 5E20;

    // Lower max value for borrow rate
    uint256 constant LOWER_BOUND_MAX_RATE = 15E19;

    uint256 constant NORM_FACTOR = 8 weeks;

    // Fee in percentage, scaled by 1e18 that will be taken on interest generated by the system for the wise ecosystem
    uint256 public fee = 20 * PRECISION_FACTOR_E18;

    // Minimum allowable fee if the fee is changed in the future by the multisig/worker
    uint256 public constant MIN_FEE = 1 * PRECISION_FACTOR_E18;

    // Maximum allowable fee if the fee is changed in the future by the multisig/worker
    uint256 public constant MAX_FEE = 50 * PRECISION_FACTOR_E18;

    // Tokens currently held by contract + all tokens out on loans
    uint256 public pseudoTotalTokensHeld;

    // Tokens currently being used in loans
    uint256 public totalTokensDue;

    // Shares representing tokens owed on a loan
    uint256 public totalBorrowShares;

    // Shares representing deposits that are not tokenized
    uint256 public totalInternalShares;

    mapping(address => bool) nftAddresses;
    mapping(address => bytes32) public merkleRoots; // nft address => merkle root
    mapping(address => string) public merkleIPFSURLs;

    // Maximum tokens that a nft is considered to be worth on a loan if not set higher by merkle tree

    mapping(address => uint256) public tokensPerNfts;

    // Minimum duration until user gets liquidated
    uint256 constant DEADLINE_DURATION = 7 days;

    // Minimum duration until the multisig/worker can manually grab the nft token for external auction
    uint256 constant DEADLINE_DURATION_MULTISIG = 9 days;

    //Datastructure that contains necessary information about a specific nft loan
    struct Loan {
        uint48 nextPaymentDueTime;
        uint48 lastPaidTime;
        address tokenOwner;
        uint256 borrowShares;
        uint256 principalTokens;
    }

    struct Collection {
        uint256 unlockTime;
        uint256 maxBorrowTokens;
        bytes32 merkleRoot;
        string ipfsUrl;
    }

    mapping(address => Collection) public pendingCollections;

    mapping(address => uint256) public internalShares;

    mapping(address => mapping(uint256 => Loan)) public currentLoans; // nft address => tokenID => loan data
}




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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol

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

    string internal _name;
    string internal _symbol;

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
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
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
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
    unchecked {
        _approve(sender, _msgSender(), currentAllowance - amount);
    }

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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
    unchecked {
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);
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
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
    unchecked {
        _balances[sender] = senderBalance - amount;
    }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
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

contract LiquidTransfer {

    //cryptoPunks contract address
    address constant PUNKS = 0x2f1dC6E3f732E2333A7073bc65335B90f07fE8b0;
    // ropsten : 0xEb59fE75AC86dF3997A990EDe100b90DDCf9a826;
    // mainnet : 0xb47e3cd837dDF8e4c57F05d70Ab865de6e193BBB;

    //cryptoKitties contract address
    address constant KITTIES = 0x06012c8cf97BEaD5deAe237070F9587f8E7A266d;

    /* @dev
    * Checks if contract is nonstandard, does transfer according to contract implementation
    */
    function _transferNFT(
        address _from,
        address _to,
        address _tokenAddress,
        uint256 _tokenId
    )
        internal
    {
        bytes memory data;

        if (_tokenAddress == KITTIES) {
            data = abi.encodeWithSignature(
                'transfer(address,uint256)',
                _to,
                _tokenId
            );
        } else if (_tokenAddress == PUNKS) {
            data = abi.encodeWithSignature(
                'transferPunk(address,uint256)',
                _to,
                _tokenId
            );
        } else {
            data = abi.encodeWithSignature(
                'safeTransferFrom(address,address,uint256)',
                _from,
                _to,
                _tokenId
            );
        }

        (bool success,) = address(_tokenAddress).call(
            data
        );

        require(
            success,
            'NFT_TRANSFER_FAILED'
        );
    }

    /* @dev
    * Checks if contract is nonstandard, does transferFrom according to contract implementation
    */
    function _transferFromNFT(
        address _from,
        address _to,
        address _tokenAddress,
        uint256 _tokenId
    )
        internal
    {
        bytes memory data;

        if (_tokenAddress == KITTIES) {

            data = abi.encodeWithSignature(
                'transferFrom(address,address,uint256)',
                _from,
                _to,
                _tokenId
            );

        } else if (_tokenAddress == PUNKS) {

            bytes memory punkIndexToAddress = abi.encodeWithSignature(
                'punkIndexToAddress(uint256)',
                _tokenId
            );

            (bool checkSuccess, bytes memory result) = address(_tokenAddress).staticcall(
                punkIndexToAddress
            );

            (address owner) = abi.decode(
                result,
                (address)
            );

            require(
                checkSuccess &&
                owner == msg.sender,
                'INVALID_OWNER'
            );

            bytes memory buyData = abi.encodeWithSignature(
                'buyPunk(uint256)',
                _tokenId
            );

            (bool buySuccess, bytes memory buyResultData) = address(_tokenAddress).call(
                buyData
            );

            require(
                buySuccess,
                string(buyResultData)
            );

            data = abi.encodeWithSignature(
                'transferPunk(address,uint256)',
                _to,
                _tokenId
            );

        } else {

            data = abi.encodeWithSignature(
                'safeTransferFrom(address,address,uint256)',
                _from,
                _to,
                _tokenId
            );
        }

        (bool success, bytes memory resultData) = address(_tokenAddress).call(
            data
        );

        require(
            success,
            string(resultData)
        );
    }

    event ERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes data
    );

    function onERC721Received(
        address _operator,
        address _from,
        uint256 _tokenId,
        bytes calldata _data
    )
        external
        returns (bytes4)
    {
        emit ERC721Received(
            _operator,
            _from,
            _tokenId,
            _data
        );

        return this.onERC721Received.selector;
    }


    /**
     * @dev encoding for transfer
     */
    bytes4 constant TRANSFER = bytes4(
        keccak256(
            bytes(
                'transfer(address,uint256)'
            )
        )
    );

    /**
     * @dev encoding for transferFrom
     */
    bytes4 constant TRANSFER_FROM = bytes4(
        keccak256(
            bytes(
                'transferFrom(address,address,uint256)'
            )
        )
    );

    /**
     * @dev encoding for balanceOf
     */
    bytes4 private constant BALANCE_OF = bytes4(
        keccak256(
            bytes(
                'balanceOf(address)' // ????? <--- update
            )
        )
    );

    /**
     * @dev does an erc20 transfer then check for success
     */
    function _safeTransfer(
        address _token,
        address _to,
        uint256 _value
    )
        internal
    {
        (bool success, bytes memory data) = _token.call(
            abi.encodeWithSelector(
                TRANSFER,
                _to,
                _value
            )
        );

        require(success && (data.length == 0 || abi.decode(data, (bool))),
            'PoolHelper: TRANSFER_FAILED'
        );
    }

    /**
     * @dev does an erc20 transferFrom then check for success
     */
    function _safeTransferFrom(
        address _token,
        address _from,
        address _to,
        uint256 _value
    )
        internal
    {
        (bool success, bytes memory data) = _token.call(
            abi.encodeWithSelector(
                TRANSFER_FROM,
                _from,
                _to,
                _value
            )
        );

        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'PoolHelper: TRANSFER_FROM_FAILED'
        );
    }

    /**
     * @dev does an erc20 balanceOf then check for success
     */
    function _safeBalanceOf(
        address _token,
        address _owner
    )
        internal
        returns (uint256)
    {
        (bool success, bytes memory data) = _token.call(
            abi.encodeWithSelector(
                BALANCE_OF,
                _owner
            )
        );

        if (success == false) return 0;

        return abi.decode(
            data,
            (uint256)
        );

    }
}

abstract contract PoolHelper is PoolBase, ERC20, LiquidTransfer {

    /**
     * @dev Pass along the constructor to pool base to set factory/router address
     */

    constructor(
        address _factoryAddress,
        address _routerAddress
    )
        PoolBase(
            _factoryAddress,
            _routerAddress
        )
    {
    }

    /**
     * @dev Helper function to add specified value to pseudoTotalTokensHeld
     */

    function _increasePseudoTotalTokens(
        uint256 _amount
    )
        internal
    {
        pseudoTotalTokensHeld =
        pseudoTotalTokensHeld + _amount;
    }

    /**
     * @dev Helper function to subtract specified value from pseudoTotalTokensHeld
     */

    function _decreasePseudoTotalTokens(
        uint256 _amount
    )
        internal
    {
        pseudoTotalTokensHeld =
        pseudoTotalTokensHeld - _amount;
    }

    /**
     * @dev Helper function to add specified value to totalPool
     */

    function _increaseTotalPool(
        uint256 _amount
    )
        internal
    {
        totalPool =
        totalPool + _amount;
    }

    /**
     * @dev Helper function to subtract specified value from totalPool
     */

    function _decreaseTotalPool(
        uint256 _amount
    )
        internal
    {
        totalPool =
        totalPool - _amount;
    }

    /**
     * @dev Helper function to add specified value to totalInternalShares
     */

    function _increaseTotalInternalShares(
        uint256 _amount
    )
        internal
    {
        totalInternalShares =
        totalInternalShares + _amount;
    }

    /**
     * @dev Helper function to subtract specified value from totalInternalShares
     */

    function _decreaseTotalInternalShares(
        uint256 _amount
    )
        internal
    {
        totalInternalShares =
        totalInternalShares - _amount;
    }

    /**
     * @dev Helper function to add value to a specific users internal shares
     */

    function _increaseInternalShares(
        uint256 _amount,
        address _user
    )
        internal
    {
        internalShares[_user] =
        internalShares[_user] + _amount;
    }

    /**
     * @dev Helper function to subtract value a specific users internal shares
     */

    function _decreaseInternalShares(
        uint256 _amount,
        address _user
    )
        internal
    {
        internalShares[_user] =
        internalShares[_user] - _amount;
    }

    /**
     * @dev Helper function to add specified value to totalBorrowShares
     */

    function _increaseTotalBorrowShares(
        uint256 _amount
    )
        internal
    {
        totalBorrowShares =
        totalBorrowShares + _amount;
    }

    /**
     * @dev Helper function to subtract specified value from totalBorrowShares
     */

    function _decreaseTotalBorrowShares(
        uint256 _amount
    )
        internal
    {
        totalBorrowShares =
        totalBorrowShares - _amount;
    }

    /**
     * @dev Helper function to add specified value to totalTokensDue
     */

    function _increaseTotalTokensDue(
        uint256 _amount
    )
        internal
    {
        totalTokensDue =
        totalTokensDue + _amount;
    }

    /**
     * @dev Helper function to subtract specified value from totalTokensDue
     */

    function _decreaseTotalTokensDue(
        uint256 _amount
    )
        internal
    {
        totalTokensDue =
        totalTokensDue - _amount;
    }

    /**
     * @dev Pure function that calculates how many borrow shares a specified amount of tokens are worth
     * Given the current number of shares and tokens in the pool.
     */
    function _calculateDepositShares(
        uint256 _amount,
        uint256 _currentPoolTokens,
        uint256 _currentPoolShares
    )
        internal
        pure
        returns (uint256)
    {

        return _amount
            * _currentPoolShares
            / _currentPoolTokens;
    }

    /**
     * @dev function for UI if user wants x amount in tokens to withdraw thus
     * calculates approriate shares to withdraw (in total including tokenized)
     */
    function calculateDepositSharesExternal(
        uint256 _amount
    )
        external
        view
        returns (uint256)
    {
        return _amount
            * getCurrentPoolShares()
            / pseudoTotalTokensHeld;
    }

    /**
     * @dev calculates the sum of tokenized and internal shares
     *
     */
    function getCurrentPoolShares()
        public
        view
        returns (uint256)
    {
        return totalSupply() + totalInternalShares;
    }

    /**
     * @dev Function to calculate how many tokens a specified amount of deposits shares is worth
     * Considers both internal and token shares in this calculation.
     */

    function calculateWithdrawAmount(
        uint256 _shares
    )
        public
        view
        returns (uint256)
    {
        uint256 currentPoolTokens = pseudoTotalTokensHeld;

        uint256 currentPoolShares = totalSupply()
            + totalInternalShares;

        return _shares
            * currentPoolTokens
            / currentPoolShares;
    }

    /**
    * @dev this functions is for helping UI
    */

    function maximumWithdrawableAmountByUser(
        address _user
    )
        external
        view
        returns (
            uint256,
            uint256
        )
    {
        uint256 amount = calculateWithdrawAmount(internalShares[_user]);
        uint256 returnValue = amount >= totalPool
            ? totalPool
            : amount;

        return (
            returnValue,
            amount
        );
    }

    /**
    * @dev this functions looks if user have mistakenly sent token directly to the contract.
    * if this is the case it gets compared to the tracked amount totalPool and
    * increases about the difference
    */

    function _cleanUp(
    )
        internal
    {
        uint256 amountContract = _safeBalanceOf(
            poolToken,
            address(this)
        );

        if (totalPool == amountContract) return;

        uint256 diff = amountContract > totalPool
            ? amountContract - totalPool
            : 0;

        _increasePseudoTotalTokens(
            diff
        );

        _increaseTotalPool(
            diff
        );
    }

    /**
    * @dev calculates the usage of the pool depending on the totalPool amount of token
    * inside the pool compared to the pseudoTotal amount
    */

    function _updateUtilization()
        internal
    {
        utilization = PRECISION_FACTOR_E18 - (
            PRECISION_FACTOR_E18
            * totalPool
            / pseudoTotalTokensHeld
        );
    }

    /**
    * @dev calculates new markovMean (recurisive formula)
    */

    function _newMarkovMean(
        uint256 _amount
    )
        internal
    {
        uint256 newValue = _amount
            * (PRECISION_FACTOR_E18 - MARKOV_FRACTION)
            + (markovMean * MARKOV_FRACTION);

        markovMean = newValue
            / PRECISION_FACTOR_E18;
    }

    /**
    * @dev sets and calculates the new borrow rate
    */

    function _newBorrowRate()
        internal
    {
        borrowRate = multiplicativeFactor
            * utilization
            * PRECISION_FACTOR_E18
            / ((resonanceFactor - utilization) * resonanceFactor);

        _newMarkovMean(
            borrowRate
        );
    }

    /**
    * @dev checking time threshold for scaling algorithm. Time bettwen to iterations >= 3 hours
    */

    function _aboveThreshold()
        internal
        view
        returns (bool)
    {
        return block.timestamp - timeStampLastAlgorithm >= THREE_HOURS;
    }

    /**
    * @dev increases the pseudo total amounts for loaned and deposited token
    * interest generated is the same for both pools. borrower have to pay back the
    * new interest amount and lender get this same amount as rewards
    */

    function _updatePseudoTotalAmounts(
        uint256 _now
    )
        internal
    {
        uint256 amount = borrowRate
            * totalTokensDue
            * (
                _now - timeStampLastInteraction
            )
            / ONE_YEAR
            / PRECISION_FACTOR_E20;

        _increasePseudoTotalTokens(
            amount
        );

        _increaseTotalTokensDue(
            amount
        );

        timeStampLastInteraction = _now;
    }

    /**
    * @dev combining several steps which are necessary for the borrowrate mechanism
    * want latest pseudo amounts to translate shares and amount in the right way
    */

    function _preparationPool()
        internal
    {
        _cleanUp();

        _updatePseudoTotalAmounts(
            block.timestamp
        );
    }

    /**
    * @dev function that tries to maximize totalDepositShares of the pool. Reacting to negative and positive
    * feedback by changing the resonanz factor of the pool. Method similar to one parameter monte carlo methods
    */

    function _scalingAlgorithm()
        internal
    {
        uint256 totalShares = totalSupply()
            + totalInternalShares;

        if (maxValue <= totalShares) {

            _newMaxValue(
                totalShares
            );

            _saveUp(
                totalShares
            );

            return;
        }

        _resetOrChange(totalShares) == true
            ? _resetresonanceFactor(totalShares)
            : _changeresonanceFactor(totalShares);

        _saveUp(
            totalShares
        );
    }

    function _saveUp(
        uint256 _totalShares
    )
        internal
    {
        previousValue = _totalShares;
        timeStampLastAlgorithm = block.timestamp;
    }

    /**
    * @dev sets the new max value in shares and saves the corresponding resonanz factor.
    */

    function _newMaxValue(
        uint256 _amount
    )
        internal
    {
        maxValue = _amount;
        bestResonanceFactor = resonanceFactor;
    }

    /**
    * @dev returns bool to determine if resonanz factor needs to be reset to last best value.
    */

    function _resetOrChange(
        uint256 _shareValue
    )
        internal
        view
        returns (bool)
    {
        return _shareValue < THRESHOLD_RESET_RESONANZ_FACTOR
            * maxValue
            / ONE_HUNDRED;
    }

    /**
    * @dev resettets resonanz factor to old best value when system evolves into too bad state.
    * sets current totalDepositShares amount to new maxValue to exclude eternal loops and that
    * unorganic peaks do not set maxValue forever
    */

    function _resetresonanceFactor(
        uint256 _value
    )
        internal
    {
        resonanceFactor = bestResonanceFactor;
        maxValue = _value;

        _revertDirectionSteppingState();
    }

    /**
     * @dev reverts the flag for stepping direction from scaling algorithm
     */
    function _revertDirectionSteppingState()
        internal
    {
        increaseResonanceFactor = !increaseResonanceFactor;
    }

    /**
     * @dev stepping function decresing the resonanz factor depending on the time past in the last
     * time interval. checks if current resonanz factor undergoes the min value. If this is the case
     * sets current value to minimal value
    */

    function _decreaseresonanceFactor()
        internal
    {
        uint256 delta = deltaResonaceFactor
            * (block.timestamp - timeStampLastAlgorithm);

        uint256 diff = resonanceFactor
            - delta;

        resonanceFactor = diff > minResonaceFactor
            ? diff
            : minResonaceFactor;
    }

    /**
     * @dev stepping function increasing the resonanz factor depending on the time past in the last
     * time interval. checks if current resonanz factor is bigger than max value. If this is the case
     * sets current value to maximal value
    */

    function _increaseResonanceFactor()
        internal
    {
        uint256 delta = deltaResonaceFactor
            * (block.timestamp - timeStampLastAlgorithm);

        uint256 sum = resonanceFactor
            + delta;

        resonanceFactor = sum < maxResonaceFactor
            ? sum
            : maxResonaceFactor;
    }

    /**
     * @dev does a revert stepping and swaps stepping state in opposite flag
    */

    function _reversedChangingresonanceFactor()
        internal
    {
        increaseResonanceFactor
            ? _decreaseresonanceFactor()
            : _increaseResonanceFactor();

        _revertDirectionSteppingState();
    }

    /**
     * @dev increasing or decresing resonanz factor depending on flag value
    */

    function _changingresonanceFactor()
        internal
    {
        increaseResonanceFactor
            ? _increaseResonanceFactor()
            : _decreaseresonanceFactor();
    }

    /**
     * @dev function combining all possible stepping scenarios. Depending
     * how share values has changed compared to last time
    */

    function _changeresonanceFactor(
        uint256 _shareValues
    )
        internal
    {
        _shareValues < THRESHOLD_SWITCH_DIRECTION * previousValue / ONE_HUNDRED
            ? _reversedChangingresonanceFactor()
            : _changingresonanceFactor();
    }

    /**
     * @dev converts token amount to borrow share amount
    */

    function getBorrowShareAmount(
        uint256 numTokensForLoan
    )
        public
        view
        returns (uint256)
    {
        return totalTokensDue == 0
            ? numTokensForLoan
            : numTokensForLoan * totalBorrowShares / totalTokensDue;
    }

    /**
     * @dev Math to convert borrow shares to tokens
     */

    function getTokensFromBorrowShareAmount(
        uint256 numBorrowShares
    )
        public
        view
        returns (uint256)
    {
        return numBorrowShares
            * totalTokensDue
            / totalBorrowShares;
    }

    /**
     * @dev Attempts transfer of all remaining balance of a user then returns nft to that user if successful.
     * Also update state variables appropriately for ending a loan.
     */

    function _endloan(
        uint256 _tokenId,
        Loan memory loanData,
        uint256 _penalty,
        address _nftAddress
    )
        internal
    {
        uint256 tokenPaymentAmount = getTokensFromBorrowShareAmount(
            loanData.borrowShares
        );

        _decreaseTotalBorrowShares(
            loanData.borrowShares
        );

        _decreaseTotalTokensDue(
            tokenPaymentAmount
        );

        _increaseTotalPool(
            tokenPaymentAmount + _penalty
        );

        _increasePseudoTotalTokens(
            _penalty
        );

        emit endLoanEvent(
            tokenPaymentAmount + _penalty,
            block.timestamp,
            _penalty,
            _tokenId,
            _nftAddress,
            currentLoans[_nftAddress][_tokenId].tokenOwner
        );

        delete currentLoans[_nftAddress][_tokenId];

        _transferNFT(
            address(this),
            loanData.tokenOwner,
            _nftAddress,
            _tokenId
        );
    }

    /**
     * @dev Calculate what we expect a loan's future value to be using our markovMean as the average interest rate
     * For more information look up markov chains
     */
    function predictFutureLoanValue(
        uint256 _tokenValue,
        uint256 _timeIncrease
    )
        public
        view
        returns (uint256)
    {
        return _tokenValue
            * _timeIncrease
            * markovMean
            / PRECISION_FACTOR_E20
            / ONE_YEAR
            + _tokenValue;
    }

    /**
     * @dev Returns either the input _timeIncrease or 35 days if _timeIncrease is greater than 35 days
     */

    function cutoffAtMaximumTimeIncrease(
        uint256 _timeIncrease
    )
        public
        pure
        returns (uint256)
    {
        if (_timeIncrease > maximumTimeBetweenPayments) {
            _timeIncrease = maximumTimeBetweenPayments;
        }

        return _timeIncrease;
    }

    /**
     * @dev Calculate penalties. .5% for first 4 days and 1% for each day after the 4th
     */

    function _getPenaltyAmount(
        uint256 _totalCollected,
        uint256 _lateDaysAmount
    )
        internal
        pure
        returns (uint256 penalty)
    {
        penalty = _totalCollected
            * _daysBase(_lateDaysAmount)
            / 200;
    }

    /**
     * @dev Helper for the days math of calcualte penalties.
     * Returns +1 per day before the 4th day and +2 for each day after the 4th day
     */

    function _daysBase(
        uint256 _daysAmount
    )
        internal
        pure
        returns (uint256 res)
    {
        // cap the maximum penalty amount to 10% after 7 days
        if (_daysAmount > 7) return 10;

        unchecked {
            res = _daysAmount > 4
            ? _daysAmount * 2 - 4
            : _daysAmount;
        }
    }

    /**
     * @dev Compute hashes to verify merkle proof for input price
     */

    function _verifyMerkleProof(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    )
        internal
        pure
        returns (bool)
    {
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {

            bytes32 proofElement = proof[i];

            computedHash = computedHash <= proofElement
                ? keccak256(abi.encodePacked(computedHash, proofElement))
                : keccak256(abi.encodePacked(proofElement, computedHash));
        }
        // Check if the computed hash (root) is equal to the provided root
        return computedHash == root;
    }

    /**
     * @dev Verify merkle proof for maxborrow if merkleRoot initialized,
     * otherwise take tokensPerNft as default loan price for collection
     */

    function getMaximumBorrow(
        address _nftAddress,
        uint256 _tokenId,
        uint256 _index,
        bytes32[] calldata merkleProof,
        uint256 merklePrice
    )
        public
        view
        returns (uint256)
    {

        uint256 res = getNftCollateralValue(
            _nftAddress,
            _tokenId,
            _index,
            merkleProof,
            merklePrice
        )
            * maxCollateralFactor
            / PRECISION_FACTOR_E20;

        return res;
    }

    function getNftCollateralValue(
        address _nftAddress,
        uint256 _tokenId,
        uint256 _index,
        bytes32[] calldata merkleProof,
        uint256 merklePrice
    )
        public
        view
        returns (uint256)
    {
        bytes32 node = keccak256(
            abi.encodePacked(
                _index,
                _tokenId,
                merklePrice
            )
        );

        if (_verifyMerkleProof(
                merkleProof,
                merkleRoots[_nftAddress],
                node
            )
        )
        {
            return merklePrice;
        }

        return tokensPerNfts[_nftAddress];
    }

    /**
     * @dev Check if a particular loan/borrower has not made a payment on their loan
     * within 7 days after the next due time. Used to determine if loans are eligible for liquidation.
     */

    function missedDeadline(
        address _nftAddress,
        uint256 _tokenId
    )
        public
        view
        returns (bool)
    {
        uint256 nextDueTime = currentLoans[_nftAddress][_tokenId].nextPaymentDueTime;

        return
            nextDueTime > 0 &&
            nextDueTime + DEADLINE_DURATION < block.timestamp;
    }

    /**
     * @dev Check if the multisig liquidation deadline has passed.
     * This is 9 days currently, meaning that there are 2 days for a loan to be liquidated naturally
     * before the multisig can call the multisig liquidate function to auction nft externally
     */

    function  deadlineMultisig(
        address _nftAddress,
        uint256 _tokenId
    )
        public
        view
        returns (bool)
    {
        uint256 nextDueTime = currentLoans[_nftAddress][_tokenId].nextPaymentDueTime;

        return
            nextDueTime > 0 &&
            nextDueTime + DEADLINE_DURATION_MULTISIG < block.timestamp;
    }

    /**
     * @dev Calculates how many tokens must be paid in order to liquidate a loan.
     * This is based on the maximum borrow allowed for the token, liquidation percentage, and how much in
     * penalties the loan has incurred
     */

    function getLiquidationAmounts(
        uint256 _borrowAmount,
        uint256 _paymentDueTime
    )
        public
        view
        returns (uint256)
    {
        return _borrowAmount
            * liquidationPercentage
            / ONE_HUNDRED
            + _getPenaltyAmount(
                _borrowAmount,
                (block.timestamp - _paymentDueTime)
                / SECONDS_IN_DAY
            );
    }

    /**
     * @dev Handles state updates if a token does not sell for as much as its expected value
     * when the multisig auctions it externally. The difference in value must be accounted for.
     * This is unfortunately a loss for the system when this happens, but must be accounted for in
     * all current defi lending and borrowing protocols.
     */

    function _badDebt(
        uint256 _amount,
        uint256 _openAmount
    )
        internal
        returns (uint256)
    {
        _increaseTotalPool(
            _amount
        );

        _increaseBadDebt(
            _openAmount - _amount
        );

        return _amount;
    }

    function _increaseBadDebt(
        uint256 _amount
    )
        internal
    {
        badDebt =
        badDebt + _amount;
    }

    function _decreaseBadDebt(
        uint256 _amount
    )
        internal
    {
        badDebt =
        badDebt - _amount;
    }


    /**
     * @dev Update state for a normal payback from multisig. If there are extra tokens from the sale,
     * the multisig liquidation will exactly pay off the number of tokens that are due for that loan,
     * and keep the rest.
     */

    function _payAllFundsBack(
        uint256 _amount
    )
        internal
        returns (uint256)
    {
        _increaseTotalPool(
            _amount
        );

        return _amount;
    }

    /**
     * @dev Helper function that updates the mapping to struct of a loan for a user.
     * Since a few operations happen here, this is a useful obfuscation for readability and reuse.
     */

    function _updateLoan(
        address _nftAddress,
        address _borrower,
        uint256 _tokenId,
        uint256 _timeIncrease,
        uint256 _newBorrowShares,
        uint256 _newPrincipalTokens,
        uint256 _blockTimestamp
    )
        internal
    {
        currentLoans[_nftAddress][_tokenId] = Loan({
            tokenOwner: _borrower,
            borrowShares: _newBorrowShares,
            principalTokens: _newPrincipalTokens,
            lastPaidTime: uint48(_blockTimestamp),
            nextPaymentDueTime: uint48(_timeIncrease + _blockTimestamp)
        });
    }

    function _updateLoanPayback(
        address _nftAddress,
        uint256 _tokenId,
        uint256 _timeIncrease,
        uint256 _borrowSharesToDestroy,
        uint256 _principalPayoff,
        uint256 _blockTimestamp
    )
        internal
    {
        Loan memory loanData = currentLoans[_nftAddress][_tokenId];

        currentLoans[_nftAddress][_tokenId] = Loan({
            tokenOwner: loanData.tokenOwner,
            borrowShares: loanData.borrowShares - _borrowSharesToDestroy,
            principalTokens: loanData.principalTokens - _principalPayoff,
            lastPaidTime: uint48(_blockTimestamp),
            nextPaymentDueTime: uint48(_timeIncrease + _blockTimestamp)
        });
    }
    // has to be here since poolhelper cant inherit liquidevents and inside payback the emit would cause stack too deep
    event endLoanEvent(
        uint256 totalPayment,
        uint256 timeStamp,
        uint256 penaltyAmount,
        uint256 tokenID,
        address indexed NFT_CONTRACT_ADDRESS,
        address indexed tokenOwner
    );
}

contract LiquidPool is PoolHelper, AccessControl, LiquidEvents {

    /**
     * @dev Only the factory address can call functions with this modifier
    */
    modifier onlyFromFactory() {
        require(
            msg.sender == FACTORY_ADDRESS,
            "LiquidPool: INVALID_FACTORY"
        );
        _;
    }

    /**
     * @dev Only the router address can call functions with this modifier
    */
    modifier onlyFromRouter() {
        require(
            msg.sender == ROUTER_ADDRESS,
            "LiquidPool: INVALID_ROUTER"
        );
        _;
    }

    /**
     * @dev Runs the LASA (Lending Automated Scaling Algorithm) algorithm when someone interacts with the contract to obtain a new interest rate
    */
    modifier updateBorrowRate() {
        _;
        _updateUtilization();
        _newBorrowRate();

        if (_aboveThreshold() == true) {
            _scalingAlgorithm();
        }
    }

    modifier isValidNftAddress(address _address) {
        require(
            nftAddresses[_address],
            "LIQUIDPOOL: Unsupported Collection"
        );
        _;
    }

    /**
     * @dev Sets the factory and router addresses on construction of contract. All contracts cloned by factory from
     * an implementation will also clone these values.
    */
    constructor(
        address _factoryAddress,
        address _routerAddress
    )
        ERC20(
            "None",
            "None"
        )
        PoolHelper(
            _factoryAddress,
            _routerAddress
        )
    {
    }

    /**
     * @dev This initialize call is called after cloning a new contract with our factory.
     * Because we are using create2 to clone contracts, this initialize function replaces the constructor for initializing variables
     * @param _poolToken - erc20 token to be used by the pool
     * @param _nftAddresses - nft contracts which users can take loans against
     * @param _multisig - address that has settings permissions and receives fees
     * @param _maxTokensPerNft - maximum allowed loan value in units of poolToken
     * @param _multiplicationFactor - used for LASA interest rate scaling algorithm
     * @param _maxCollateralFactor - percentage of the nft's value that can be borrowed
     * @param _merkleRoots - Roots of the merkle trees containing specific price data for nft traits
     * @param _ipfsURL - Ipfs file path containing the current merkle tree for nft token prices
     * @param _tokenName - Name of erc20 token issued by this contract to represent shares in pool
     * @param _tokenSymbol - Symbol of erc20 token issued by this contract to represent shares in pool
     * @param _isExpandable - bool for possibility of adding collections to a pool lateron
     */
    function initialize(
        address _poolToken,
        address[] memory _nftAddresses,
        address _multisig,
        uint256[] memory _maxTokensPerNft,
        uint256 _multiplicationFactor,  //Determine how quickly the interest rate changes with changes to utilization and resonanceFactor
        uint256 _maxCollateralFactor,       //Maximal factor every NFT can be collateralized in this pool
        bytes32[] memory _merkleRoots,            //The merkleroot of a merkletree containing information about the amount to borrow for specific nfts in collection
        string[] memory _ipfsURL,
        string memory _tokenName,       //Name for erc20 representing shares of this pool
        string memory _tokenSymbol,      //Symbol for erc20 representing shares of this pool
        bool _isExpandable
    )
        external
        onlyFromFactory
    {
        for (uint64 i = 0; i < _nftAddresses.length; i++) {
            nftAddresses[_nftAddresses[i]] = true;
            tokensPerNfts[_nftAddresses[i]] = _maxTokensPerNft[i];
            merkleRoots[_nftAddresses[i]] = _merkleRoots[i];
            merkleIPFSURLs[_nftAddresses[i]] = _ipfsURL[i];
            emit collectionAdded(
                _nftAddresses[i],
                block.timestamp
            );
        }

        isExpandable = _isExpandable;
        totalInternalShares = 1;
        pseudoTotalTokensHeld = 1;
        poolToken = _poolToken;
        multiplicativeFactor = _multiplicationFactor;
        maxCollateralFactor = _maxCollateralFactor;
        _name = _tokenName;
        _symbol = _tokenSymbol;

        //set multisig here because of factory cloning model
        _updateMultisig(
            _multisig
        );

        workers[_multisig] = true;
        workers[FACTORY_ADDRESS] = true;
        // Initializing variables for scaling algorithm and borrow rate calculation.
        // all numbers are of order 1E18

        // Depending on the individuel multiplication factor of each asset!
        // calculating lower bound for resonanz factor
        minResonaceFactor = PRECISION_FACTOR_E18
            / 2
            + Babylonian.sqrt(PRECISION_FACTOR_E36/4
                + _multiplicationFactor
                    * PRECISION_FACTOR_E36
                    / UPPER_BOUND_MAX_RATE
            );

        // Calculating upper bound for resonanz factor
        maxResonaceFactor = PRECISION_FACTOR_E18
            / 2
            + Babylonian.sqrt(PRECISION_FACTOR_E36/4
                + _multiplicationFactor
                    * PRECISION_FACTOR_E36
                    / LOWER_BOUND_MAX_RATE
            );

        // Calculating stepping size for algorithm
        deltaResonaceFactor = (maxResonaceFactor - minResonaceFactor)
            / NORM_FACTOR_SECONDS_IN_TWO_MONTH;

        // Setting start value as mean of min and max value
        resonanceFactor = (maxResonaceFactor + minResonaceFactor) / 2;

        // Initalize with 70%
        liquidationPercentage = 70;
    }
    /**
     * @dev
     * removes the ability to add collections to a global pool to decrease necessairy
     * trust levels
     */
    function renounceExpandability()
        onlyMultisig
        external
    {
        isExpandable = false;
    }

    /**
     * @dev
     * Multisig or worker can change the discount percentage for liqudation.
     * This results in a change of the overall liquidation fee which gets added on top the penalty amount.
     * Essentially this value is a factor with which the merkletree price evaulation gets multiplied.
     */

    function changeDiscountPercLiqudAndFee(
        uint256 _percentage
    )
        external
        onlyWorker
    {
        require(
            _percentage > (maxCollateralFactor + FIVE_PERCENT) / PRECISION_FACTOR_E18,
            "LiquidPool: INVALID_RANGE"
        );

        require(
            _percentage < 100,
            "LiquidPool: INVALID_RANGE"
        );

        emit changeDiscountPercLiqudAndFeeEvent(
            address(this),
            liquidationPercentage,
            _percentage,
            block.timestamp
        );

        liquidationPercentage = _percentage;
    }

    /**
     * @dev Function permissioned to only be called from the router to deposit funds
     * Calls internal deposit funds function that does the real work.
     * Router makes sure that the _depositor variable is always the msg.sender to the router
     */

    function depositFundsRouter(
        uint256 _amount,
        address _depositor
    )
        external
        onlyFromRouter
    {
        _depositFunds(
            _amount,
            _depositor
        );
    }

    /**
     * @dev External depositFunds function to directly deposit funds bypassing the router
     * Require explicit approval of tokens for this pool. Calls internal deposit funds function.
     */

    function depositFunds(
        uint256 _amount
    )
        external
    {
        _depositFunds(
            _amount,
            msg.sender
        );

        _safeTransferFrom(
            poolToken,
            msg.sender,
            address(this),
            _amount
        );
    }

    /**
     * @dev Add funds to the contract for other users to borrow.
     * Upon deposit user will receive internal shares representing their share of the pool
     * These shares can be tokenized later into an erc20 denomination if the user desires after a certain amount of time.
     * Share system keeps track of a users percentage of the tokens in the pool, so it grows as interest added.
     */

    function _depositFunds(
        uint256 _amount,
        address _depositor
    )
        internal
        updateBorrowRate
    {
        // Checking of tokens have falsely been sent directly to the contract
        // and update for latest interest gained
        _preparationPool();

        // local variables save gas over going function calls and storage accesses
        uint256 currentPoolTokens = pseudoTotalTokensHeld;
        uint256 currentPoolShares = totalSupply()
            + totalInternalShares;

        uint256 newShares = _calculateDepositShares(
                _amount,
                currentPoolTokens,
                currentPoolShares
            );

        _increaseInternalShares(
            newShares,
            _depositor
        );
        _increaseTotalInternalShares(
            newShares
        );
        _increaseTotalPool(
            _amount
        );
        _increasePseudoTotalTokens(
            _amount
        );

        emit depositFundsEvent(
            address(this),
            poolToken,
            _depositor,
            _amount,
            newShares,
            block.timestamp
        );
    }

    /**
     * @dev This function allows users to convert internal shares into tokenized shares for the pool.
     * Tokenized shares function the same as internal shares, but are explicitly represented by an erc20 token and tradable.
     */

    function tokenizeShares(
        uint256 _shares
    )
        external
    {
        _decreaseInternalShares(
            _shares,
            msg.sender
        );

        _decreaseTotalInternalShares(
            _shares
        );

        _mint(
            msg.sender,
            _shares
        );
    }

    function withdrawFundsSmart(
        uint256 _shares
    )
        external
    {
        _withdrawFundsSmart(
            _shares,
            msg.sender
        );
    }

    function withdrawFundsSmartRouter(
        uint256 _shares,
        address _user
    )
        external
        onlyFromRouter
    {
        _withdrawFundsSmart(
            _shares,
            _user
        );
    }

    function withdrawFundsInternalShares(
        uint256 _shares
    )
        external
    {
        _withdrawFundsInternalShares(
            _shares,
            msg.sender
        );
    }

    function withdrawFundsInternalSharesRouter(
        uint256 _shares,
        address _user
    )
        external
        onlyFromRouter
    {
        _withdrawFundsInternalShares(
            _shares,
            _user
        );
    }

    function withdrawFundsTokenShares(
        uint256 _shares
    )
        external
    {
        _withdrawFundsTokenShares(
            _shares,
            msg.sender
        );
    }

    function withdrawFundsTokenSharesRouter(
        uint256 _shares,
        address _user
    )
        external
        onlyFromRouter
    {
        _withdrawFundsTokenShares(
            _shares,
            _user
        );
    }

    /**
     * @dev Since we have both internal and tokenized shares, they need to be withdrawn differently.
     * This function will smartly withdraw from internal shares first, then take requested remainder
       calculated from tokenized shares.
     */

    function _withdrawFundsSmart(
        uint256 _shares,
        address _user
    )
        internal
    {
        uint256 userInternalShares = internalShares[_user];

        if (userInternalShares >= _shares) {

            _withdrawFundsInternalShares(
                _shares,
                _user
            );

            return;
        }

        _withdrawFundsInternalShares(
            userInternalShares,
            _user
        );

        _withdrawFundsTokenShares(
            _shares - userInternalShares,
            _user
        );
    }

    /**
     * @dev Withdraw funds from pool but only from internal shares, not token shares.
     */

    function _withdrawFundsInternalShares(
        uint256 _shares,
        address _user
    )
        internal
        updateBorrowRate
    {

        // checking if token have falsely been send directly to the contract
        // and update for latest interest gained
        _preparationPool();

        uint256 withdrawAmount = calculateWithdrawAmount(
            _shares
        );

        _decreaseInternalShares(
            _shares,
            _user
        );

        _decreaseTotalInternalShares(
            _shares
        );

        _decreasePseudoTotalTokens(
            withdrawAmount
        );

        _decreaseTotalPool(
            withdrawAmount
        );

        _safeTransfer(
            poolToken,
            _user,
            withdrawAmount
        );

        emit withdrawFundsInternalSharesEvent(
            address(this),
            poolToken,
            _user,
            withdrawAmount,
            _shares,
            block.timestamp
        );
    }

    /**
     * @dev Withdraw funds from pool but only from token shares, not internal shares.
     * Burns erc20 share tokens and transfers the deposit tokens to the user.
     */

    function _withdrawFundsTokenShares(
        uint256 _shares,
        address _user
    )
        internal
        updateBorrowRate
    {
        // checking if tokens have falsely been sent directly to the contract
        // and update for latest interest gained
        _preparationPool();

        uint256 withdrawAmount = calculateWithdrawAmount(
            _shares
        );

        _burn(
            _user,
            _shares
        );

        _decreasePseudoTotalTokens(
            withdrawAmount
        );

        _decreaseTotalPool(
            withdrawAmount
        );

        _safeTransfer(
            poolToken,
            _user,
            withdrawAmount
        );

        emit withdrawFundsTokenizedSharesEvent(
            address(this),
            poolToken,
            _user,
            withdrawAmount,
            _shares,
            block.timestamp
        );
    }

    /**
     * @dev Take out a loan against an nft. This is a wrapper external function that calls the internal borrow funds function.
     * Only the router can call this function. Depositor will always be the msg.sender of the router.
     */

    function borrowFundsRouter(
        uint256 _tokenAmountToBorrow,
        uint256 _timeIncrease,
        uint256 _tokenId,
        uint256 _index,
        bytes32[] calldata merkleProof,
        uint256 merklePrice,
        address _borrower,
        address _nftAddress
    )
        external
        onlyFromRouter
    {
        uint256[] memory args = new uint256[](5);

        args[0] = _tokenAmountToBorrow;
        args[1] = _timeIncrease;
        args[2] = _tokenId;
        args[3] = _index;
        args[4] = merklePrice;

        _borrowFunds(
            args,
            merkleProof,
            _borrower,
            _nftAddress
        );
    }

    /**
     * @dev External function for taking out a loan against an nft. Calls internal borrow funds.
     * Transfers nft from user before proceeding. Approval for for nft token to this specific pool is needed.
     */

    function borrowFunds(
        uint256 _tokenAmountToBorrow,
        uint256 _timeIncrease,
        uint256 _tokenId,
        uint256 _index,
        bytes32[] calldata merkleProof,
        uint256 merklePrice,
        address _nftAddress
    )
        external
    {
        _transferFromNFT(
            msg.sender,
            address(this),
            _nftAddress,
            _tokenId
        );

        uint256[] memory args = new uint256[](5);

        args[0] = _tokenAmountToBorrow;
        args[1] = _timeIncrease;
        args[2] = _tokenId;
        args[3] = _index;
        args[4] = merklePrice;

        _borrowFunds(
            args,
            merkleProof,
            msg.sender,
            _nftAddress
        );
    }

    /**
     * @dev Send a nft from the specified set to this contract in exchange for a loan.
     * Can use a merkle tree structure to verify price of individual tokens and traits of the nft set.
     * If merkle root is not initialized for the set then the tokensPerLoan variable is used to determine loan amount.
     * We predict the loans value at a specified date in the future using a markov chain. This uses a time series of
     * interest rates in this contract over time. Maximum time between payments is 35 days. This allows for monthly paybacks.
     * The loans predicted value for the specifed future date with _timeIncrease is not allowed to exceed the nft token's
     * collateralization value. (_timeIncrease is the number of seconds you want to increase by, capped at 35 days)
     * Can use a merkle tree structure to verify price of individual tokens and traits of the nft set
     * If merkle root is not initialized for the set then the tokensPerNft variable is used to determine loan amount.
     *
     * This function uses a parameters array instead of explicitly named local variables to avoid stack too deep errors.
     * The parameters in the parameters array are detailed below
     *
     *         uint256 _tokenAmountToBorrow, -> params[0]      --How many ERC20 tokens desired for the loan
     *         uint256 _timeIncrease,  -> params[1]            --How many seconds the user would like to request until their next payment is due
     *         uint256 _tokenId, -> params[2]                  --Identifier of nft token to borrow against
     *         uint256 _index, -> params[3]                    --Index of nft token in merkle tree
     *         uint256 _merklePrice, -> params[4]              --Price token of token in merkle tree. Must be correct in order for merkle tree to be verified
     */

    function _borrowFunds(
        uint256[] memory params,
        bytes32[] calldata merkleProof,
        address _borrower,
        address _nftAddress
    )
        internal
        updateBorrowRate
        isValidNftAddress(_nftAddress)
    {
        _preparationPool();

        params[1] = cutoffAtMaximumTimeIncrease(
            params[1] // _timeIncrease
        );

        {
        // Markov mean is relative to 1 year so divide by seconds
        uint256 predictedFutureLoanValue = predictFutureLoanValue(
            params[0], // _tokenAmountToBorrow
            params[1] // _timeIncrease
        );

        require(
            predictedFutureLoanValue <= getMaximumBorrow(
                _nftAddress,
                params[2],  // _tokenId
                params[3], // _index
                merkleProof,
                params[4] // _merklePrice
            ),
            "LiquidPool: LOAN_TOO_LARGE"
        );
        }

        uint256 borrowSharesGained = getBorrowShareAmount(
            params[0] // _tokenAmountToBorrow
        );

        _increaseTotalBorrowShares(
            borrowSharesGained
        );

        _increaseTotalTokensDue(
            params[0] // _tokenAmountToBorrow
        );

        _decreaseTotalPool(
            params[0] // _tokenAmountToBorrow
        );

        _updateLoan(
            _nftAddress,
            _borrower,
            params[2], // _tokenId
            params[1], // _timeIncrease
            borrowSharesGained,
            params[0], // _tokenAmountToBorrow
            block.timestamp
        );

        _safeTransfer(
            poolToken,
            _borrower,
            params[0] // _tokenAmountToBorrow
        );

        emit borrowFundsEvent(
            _nftAddress,
            _borrower,
            params[2],
            block.timestamp + params[1],
            params[0],
            block.timestamp
        );
    }

    function paybackFundsRouter(
        uint256 _principalPayoff,
        uint256 _timeIncrease,
        uint256 _tokenId,
        uint256 _index,
        bytes32[] calldata merkleProof,
        uint256 _merklePrice,
        address _nftAddress
    )
        external
        onlyFromRouter
        returns (uint256, uint256)
    {
        uint256[] memory args = new uint256[](5);

        args[0] = _principalPayoff;
        args[1] = _timeIncrease;
        args[2] = _tokenId;
        args[3] = _index;
        args[4] = _merklePrice;

        return _paybackFunds(
            args,
            merkleProof,
            _nftAddress
        );
    }

    function paybackFunds(
        uint256 _principalPayoff,
        uint256 _timeIncrease,
        uint256 _tokenId,
        uint256 _index,
        bytes32[] calldata merkleProof,
        uint256 _merklePrice,
        address _nftAddress
    )
        external
    {
        uint256[] memory args = new uint256[](5);

        args[0] = _principalPayoff;
        args[1] = _timeIncrease;
        args[2] = _tokenId;
        args[3] = _index;
        args[4] = _merklePrice;

        (uint256 totalPayment, uint256 feeAmount) = _paybackFunds(
            args,
            merkleProof,
            _nftAddress
        );

        _safeTransferFrom(
            poolToken,
            msg.sender,
            address(this),
            totalPayment
        );

        _safeTransferFrom(
            poolToken,
            msg.sender,
            multisig,
            feeAmount
        );
    }

    /**
     * @dev Interest on a loan must be paid back regularly.
     * This function will automatically make the user pay off the interest on a loan, with the option to also pay off some prinicipal as well
     * The maximum amount of time between payments will be set at 35 days to allow payments on the same day of each month.
     * The same prediction system described in borrow function documentation is used here as well,
     * predicted value of the nft at the specified time increase must not exceed collateralization value.
     * Time increase can be whatever a user wants, but funds must be payed back again by that many seconds into the future
     * or else the loan will start to go up for liquidation and incur penalties.
     * The maximum amount of time between payments will be set at 35 days to allow payments on the same day of each month
     *   uint256 _principalPayoff,   -> args[0]
     *   uint256 _timeIncrease,      -> args[1]
     *   uint256 _tokenId,           -> args[2]
     *   uint256 _index,             -> args[3]
     *   uint256 _merklePrice,        -> args[4]
     */

    function _paybackFunds(
        uint256[] memory args,
        bytes32[] calldata merkleProof,
        address _nftAddress
    )
        internal
        updateBorrowRate
        isValidNftAddress(_nftAddress)
        returns(
            uint256 totalPayment,
            uint256 feeAmount
        )
    {
        _preparationPool();

        uint256 borrowSharesToDestroy;
        uint256 penaltyAmount;

        {
            Loan memory loanData = currentLoans[_nftAddress][args[2]]; // _tokenId

            args[1] = cutoffAtMaximumTimeIncrease( // _timeIncrease
                args[1] // _timeIncrease
            );

            {
                uint256 currentLoanValue = getTokensFromBorrowShareAmount(
                    loanData.borrowShares
                );

                if (block.timestamp > loanData.nextPaymentDueTime) {
                    penaltyAmount = _getPenaltyAmount(
                        currentLoanValue,
                        (block.timestamp - loanData.nextPaymentDueTime) / SECONDS_IN_DAY
                    );
                }

                feeAmount = (currentLoanValue - loanData.principalTokens)
                    * fee
                    / PRECISION_FACTOR_E20;

                totalPayment = args[0] // _principalPayoff
                    + currentLoanValue
                    - loanData.principalTokens;


                borrowSharesToDestroy = getBorrowShareAmount(
                    totalPayment
                );

                if (borrowSharesToDestroy >= loanData.borrowShares) {

                    _endloan(
                        args[2], // _tokenId
                        loanData,
                        penaltyAmount,
                        _nftAddress
                    );

                    return (currentLoanValue + penaltyAmount, feeAmount);
                }
            }

            require(
                predictFutureLoanValue(
                    loanData.principalTokens - args[0], // _principalPayoff
                    args[1] // _timeIncrease
                )
                <= getMaximumBorrow(
                    _nftAddress,
                    args[2], // _tokenId
                    args[3], // _index
                    merkleProof,
                    args[4] // _merklePrice
                ),
                "LiquidPool: LOAN_TOO_LARGE"
            );

            _decreaseTotalBorrowShares(
                borrowSharesToDestroy
            );

            _decreaseTotalTokensDue(
                totalPayment
            );

            _increaseTotalPool(
                totalPayment + penaltyAmount
            );

            _increasePseudoTotalTokens(
                penaltyAmount
            );
        }

        _updateLoanPayback(
            _nftAddress,
            args[2], // _tokenId
            args[1], // _timeIncrease
            borrowSharesToDestroy,
            args[0], // _principalPayoff
            block.timestamp
        );

        emit paybackFundsEvent(
            _nftAddress,
            currentLoans[_nftAddress][args[2]].tokenOwner,
            totalPayment,
            block.timestamp + args[1],
            penaltyAmount,
            args[2],
            block.timestamp
        );

        return (
            totalPayment + penaltyAmount,
            feeAmount
        );
    }

    /**
     * @dev Liquidations of loans are allowed when a loan has no payment made for 7 days after their deadline.
     * These monthly regular payments help to keep liquid tokens flowing through the contract.
     * Handles the liquidation of a NFT loan with directly buying the NFT from the
     * pool. Liquidator gets the NFT for a discount price which is the sum
     * of the current borrow amount + penalties + liquidation fee.
     * Ideally this amount should be less as the actual NFT value so ppl
     * are incentivized to liquidate. User needs the token into her/his wallet.
     * After a period of two days the Multisig-Wallet can get the NFT with another function.
    */

    function liquidateNFT(
        uint256 _tokenId,
        uint256 _index,
        bytes32[] calldata merkleProof,
        uint256 merklePrice,
        address _nftAddress
    )
        external
        updateBorrowRate
    {
        require(
            missedDeadline(_nftAddress, _tokenId) == true,
            'LiquidPool: TOO_EARLY'
        );

        _preparationPool();

        Loan memory loanData = currentLoans[_nftAddress][_tokenId];

        uint256 openBorrowAmount = getTokensFromBorrowShareAmount(
            loanData.borrowShares
        );

        uint256 discountAmount = getLiquidationAmounts(
            getNftCollateralValue(
                _nftAddress,
                _tokenId,
                _index,
                merkleProof,
                merklePrice
            ),
            loanData.nextPaymentDueTime
        );

        require(
            discountAmount >= openBorrowAmount,
            "LIQUIDPOOL: Discount Too Large"
        );

        _decreaseTotalBorrowShares(
            loanData.borrowShares
        );

        _decreaseTotalTokensDue(
            openBorrowAmount
        );

        _increaseTotalPool(
            openBorrowAmount
        );

        emit liquidateNFTEvent(
            _nftAddress,
            currentLoans[_nftAddress][_tokenId].tokenOwner,
            msg.sender,
            discountAmount,
            _tokenId,
            block.timestamp
        );

        // Delete loan
        delete currentLoans[_nftAddress][_tokenId];

        // Liquidator pays discount for NFT
        _safeTransferFrom(
            poolToken,
            msg.sender,
            address(this),
            discountAmount
        );

        // Sending NFT to new owner
        _transferNFT(
            address(this),
            msg.sender,
            _nftAddress,
            _tokenId
        );

        // Sending fee + penalties from liquidation to multisig
        _safeTransfer(
            poolToken,
            multisig,
            discountAmount - openBorrowAmount
        );

    }

    /**
     * @dev After 9 days without payment or liquidation the multisig can take the nft token to auction on opensea.
     * Due to the signature nature of wyvern protocol and openseas use of it we cannot start an opensea listing directly from a contract.
     * Sending NFT to Multisig and changing loan owner to zero address.
     * This markes the loan as currently being auctioned externally.
     * This is a small point of centralization that is required to keep the contract functional in cases of bad debt,
     * and should only happen in rare cases.
    */

    function liquidateNFTMultisig(
        uint256 _tokenId,
        address _nftAddress
    )
        external
        onlyWorker
    {
        require(
            deadlineMultisig(_nftAddress, _tokenId) == true,
            'LiquidPool: TOO_EARLY'
        );

        emit liquidateNFTMultisigEvent(
            _nftAddress,
            currentLoans[_nftAddress][_tokenId].tokenOwner,
            multisig,
            _tokenId,
            block.timestamp
        );

        currentLoans[_nftAddress][_tokenId].tokenOwner = ZERO_ADDRESS;

        // Sending NFT to multisig
        _transferNFT(
            address(this),
            multisig,
            _nftAddress,
            _tokenId
        );

    }

    /**
     * @dev pays back bad debt which accrued if any did accumulate. Can be called
        by anyone since there is no downside in allowing public to payback baddebt.
    */

    function decreaseBadDebt(
        uint256 _amount
    )
        external
    {
        if (_amount == 0) revert("LiquidPool: AMOUNT_IS_ZERO");
        if (badDebt == 0) revert("LiquidPool: BAD_DEBT_IS_ZERO");

        uint256 amountToPayBack = _amount > badDebt
            ? badDebt
            : _amount;

        emit decreaseBadDebtEvent(
            badDebt,
            badDebt - amountToPayBack,
            amountToPayBack,
            block.timestamp
        );

        _increaseTotalPool(amountToPayBack);
        _decreaseBadDebt(amountToPayBack);
        _safeTransferFrom(
            poolToken,
            msg.sender,
            address(this),
            amountToPayBack
        );
    }

    /**
     * @dev Multisig returns funds from selling nft token externally, and contract update state variables.
    */

    function putFundsBackFromSellingNFT(
        uint256 _tokenId,
        uint256 _amount,
        address _nftAddress
    )
        external
        onlyWorker
        updateBorrowRate
    {
        _preparationPool();

        Loan memory loanData = currentLoans[_nftAddress][_tokenId];

        require(
            loanData.tokenOwner == ZERO_ADDRESS,
            'LiquidPool: LOAN_NOT_LIQUIDATED'
        );

        uint256 openAmount = getTokensFromBorrowShareAmount(
            loanData.borrowShares
        );

        // deleting all open shares as well as open
        // pseudo- and totalBorrow amount
        _decreaseTotalBorrowShares(
            loanData.borrowShares
        );

        _decreaseTotalTokensDue(
            openAmount
        );

        // dealing how lending side gets updated. Differs
        // between those two cases
        bool badDebtCondition = openAmount > _amount;

        uint256 badDebtAmount = badDebtCondition
            ? openAmount - _amount
            : 0;

        uint256 transferAmount = badDebtCondition
            ? _badDebt(_amount, openAmount)
            : _payAllFundsBack(openAmount);

        emit putFundsBackFromSellingNFTEvent(
            _nftAddress,
            _tokenId,
            transferAmount,
            badDebtAmount,
            block.timestamp
        );

        delete currentLoans[_nftAddress][_tokenId];

        // Paying back open funds from liquidation after selling NFT
        _safeTransferFrom(
            poolToken,
            msg.sender,
            address(this),
            transferAmount
        );
    }

    /**
     * @dev View function for returning the current apy of the system.
    */

    function getCurrentDepositAPY()
        public
        view
        returns (uint256)
    {
        return borrowRate
            * totalTokensDue
            / pseudoTotalTokensHeld;
    }

    function beginUpdateCollection(
        address _nftAddress,
        uint256 _tokenPerNft,
        bytes32 _merkleRoot,
        string memory _ipfsURL
    )
        external
        onlyWorker
    {
        //Pool must either be expandable or collection must already be allowed in this pool
        require(
            isExpandable || nftAddresses[_nftAddress],
            "LIQUIDPOOL: Update Forbidden"
        );

        pendingCollections[_nftAddress] = Collection({
            unlockTime : block.timestamp + DEADLINE_DURATION,
            maxBorrowTokens : _tokenPerNft,
            merkleRoot: _merkleRoot,
            ipfsUrl : _ipfsURL
        });

        emit updateCollectionRequestEvent(
            block.timestamp + DEADLINE_DURATION,
            _tokenPerNft,
            _merkleRoot,
            _ipfsURL,
            msg.sender,
            block.timestamp
        );
    }

    function finishUpdateCollection(
        address _nftAddress
    )
        external
    {
        Collection memory collectionToAdd = pendingCollections[_nftAddress];

        //Check unlock time is not uninitialized, or anyone could essentially add collections with bad data
        require(
            block.timestamp > collectionToAdd.unlockTime && collectionToAdd.unlockTime != 0,
            "LiquidPool: TOO_EARLY"
        );

        bool newCollection;

        if(!nftAddresses[_nftAddress]){
            nftAddresses[_nftAddress] = true;
            newCollection = true;

        }
        tokensPerNfts[_nftAddress] = collectionToAdd.maxBorrowTokens;
        merkleRoots[_nftAddress] = collectionToAdd.merkleRoot;
        merkleIPFSURLs[_nftAddress] = collectionToAdd.ipfsUrl;

        emit finishUpdateCollectionEvent(
            _nftAddress,
            newCollection,
            merkleRoots[_nftAddress],
            merkleIPFSURLs[_nftAddress],
            tokensPerNfts[_nftAddress],
            block.timestamp
        );

    }

    /**
     * @dev Updates the usage fee for the system within a certain range.
     * Can only be called by worker address.
    */

    function updateFee(
        uint256 _newFee
    )
        external
        onlyWorker
    {
        require(
            fee >= MIN_FEE,
            "LiquidPool: FEE_TOO_LOW"
        );

        require(
            fee <= MAX_FEE,
            "LiquidPool: FEE_TOO_HIGH"
        );

        fee = _newFee;
    }
}