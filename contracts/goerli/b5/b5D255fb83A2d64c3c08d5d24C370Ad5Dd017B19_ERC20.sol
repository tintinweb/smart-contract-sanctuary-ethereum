// SPDX-License-Identifier: MIT

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

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
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    //////////////////////
    ////    Fields    ////
    //////////////////////

    ////    Standard ERC20 Fields    ////

    // name of token
    string private _name;

    // symbol of token
    string private _symbol;

    // total supply of toekn
    uint256 private _totalSupply;

    // token allowance of addresses
    mapping(address => mapping(address => uint256)) private _allowances;

    // token balance of addresses
    mapping(address => uint256) private _balances;

    ////    VanEck Token Fields    ////

    // owner
    address public _owner;

    // candidate owner
    address public _candidateOwner;

    // token supply supervisor
    address public _tokenSupplySupervisor;

    // candiate token supply supervisor
    address public _candidateTokenSupplySupervisor;

    // Supervisory account
    address public _accountSupervisor;

    // candidate supervisory account
    address public _candidateAccountSupervisor;

    // whitelist supervisor
    address public _whitelistSupervisor;

    // candidate whitelist supervisor
    address public _candidateWhitelistSupervisor;

    // whitelist addresses
    mapping(address => bool) _whitelistAddresses;

    // fee supervisor
    address public _feeSupervisor;

    // candidate fee supervisor
    address public _candidateFeeSupervisor;

    // fee recipient
    address public _feeRecipient;

    // candidate fee recipient
    address public _candidateFeeRecipient;

    // FreezAllTransactios
    bool public _FreezAllTransactions = false;

    // freezing specific accounts transactions
    mapping(address => bool) internal _freeze;

    // fee decimals
    uint256 public _feeDecimals;

    // createion fee
    uint256 public _creationFee;

    // redemption fee
    uint256 public _redemptionFee;

    // transfer fee
    uint256 public _transferFee;

    // other fee
    uint256 public _otherFee;

    // constructor
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _owner = msg.sender;
    }

    //////////////////////
    ////    Events    ////
    //////////////////////

    ////    Standard ERC20 Events    ////

    ////    VanEck Token Events    ////

    // freezing all transactions by owner
    event freezeAllTransactionsEvent(
        address indexed ownerAccount,
        uint256 indexed timestamp
    );

    // un-freeze all transactions by owner
    event unFreezeAllTransactionsEvent(
        address indexed ownerAccount,
        uint256 indexed timestamp
    );

    // freez an account event
    event freezeAccountEvent(
        address indexed AccountSupervisor,
        address indexed account,
        uint256 indexed timestamp
    );

    // un-freeze and account event
    event unFreezeAccountEvent(
        address indexed AccountSupervisor,
        address indexed account,
        uint256 indexed timestamp
    );

    // wipe frozen account event
    event wipeFrozenAccountEvent(
        address indexed AccountSupervisor,
        address indexed account,
        uint256 balance,
        uint256 indexed timestamp
    );

    // withdraw tokens send to contract address
    event withdrawContractTokensEvent(
        address indexed contractAddress,
        address indexed ownerAccount,
        uint256 amount,
        uint256 indexed timestamp
    );

    // set candiate owner
    event setCandidateOwnerEvent(
        address indexed owner,
        address indexed candidateOwner,
        uint256 indexed timestamp
    );

    // cancel candiate owner
    event cancelCandidateOwnerEvent(
        address indexed sender,
        address indexed candiateOwner,
        uint256 indexed timestamp
    );

    // update owner address
    event updateOwnerEvent(
        address indexed previousOwnerAddress,
        address indexed newOwnerAddress,
        uint256 indexed timestamp
    );

    // set canidate supply supervisor
    event setCandidateTokenSupplySupervisorEvent(
        address indexed owner,
        address indexed candiateTokenSupplySupervisor,
        uint256 indexed timestamp
    );

    // cancel candiate token supply supervisor account
    event cancelCandidateTokenSupplySupervisorEvent(
        address indexed sender,
        address indexed candiateTokenSupplySupervisor,
        uint256 indexed timestamp
    );

    // update token supply supervisor
    event updateTokenSupplySupervisorEvent(
        address indexed previousTokenSupplySupervisorAddress,
        address indexed newTokenSupplySupervisor,
        uint256 indexed timestamp
    );

    // increase total token supply
    event increaseTokenSupplyEvent(
        address indexed tokenSupplySupervisor,
        uint256 amount_,
        uint256 indexed timestamp
    );

    // decreate total tokne supply
    event decreaseTokenSupplyEvent(
        address indexed tokenSupplySupervisor,
        uint256 amount_,
        uint256 indexed timestamp
    );

    // set candidate account supervisor
    event setCandidateAccountSupervisorEvent(
        address indexed sender,
        address indexed candidateAccountSupervisor,
        uint256 indexed timestamp
    );

    // cancel candidate account supervisor
    event cancelCandidateAccountSupervisorEvent(
        address indexed sender,
        address indexed candiateAccountSupervisor,
        uint256 indexed timestamp
    );

    // update account supervisor acount
    event updateAccountSupervisorEvent(
        address indexed previousAccountSupervisorAddress,
        address indexed newAccountSupervisorAddress,
        uint256 indexed timestamp
    );

    // set candidate whitelist supervisor
    event setCandidateWhitelistSupervisorEvent(
        address indexed sender,
        address indexed candidateWhitelistSupervisor,
        uint256 indexed timestamp
    );

    // cancel candidate whitelist supervisor
    event cancelCandidateWhitelistSupervisorEvent(
        address indexed sender,
        address indexed candidateWhitelistSupervisor,
        uint256 indexed timestamp
    );

    // update whitelist supervisor address
    event updateWhitelistSupervisorEvent(
        address indexed previousWhitelistSupervisorAddress,
        address indexed newWhitelistSupervisor,
        uint256 indexed timestamp
    );

    // append account to whitelist addresses
    event appendToWhitelistEvent(
        address indexed whitelistSupervisor,
        address indexed account,
        uint256 indexed timestamp
    );

    // remove account from whitelist addresses
    event removeFromWhitelistEvent(
        address indexed whitelistSupervisor,
        address indexed account,
        uint256 indexed timestamp
    );

    // set candidate fee supervisor
    event setCandidateFeeSupervisorEvent(
        address indexed sender,
        address indexed candidateFeeSupervisor,
        uint256 indexed timestamp
    );

    // cancel candidate fee supervisor
    event cancelCandidateFeeSupervisorEvent(
        address indexed sender,
        address indexed candidateFeeSupervisor,
        uint256 indexed timestamp
    );

    // update fee supervisor
    event updateFeeSupervisorEvent(
        address indexed previousFeeSupervisorAddress,
        address indexed newFeeSupervisor,
        uint256 indexed timestamp
    );

    // set candidate fee recipient address
    event setCandidateFeeRecipientEvent(
        address indexed sender,
        address indexed candidateFeeRecipient,
        uint256 indexed timestamp
    );

    // cancel candidate fee recipient
    event cancelCandidateFeeRecipientEvent(
        address indexed sender,
        address indexed candidateFeeRecipient,
        uint256 indexed timestamp
    );

    // update fee recipient
    event updateFeeRecipientEvent(
        address indexed previousFeeRecipientAddress,
        address indexed newFeeRecipient,
        uint256 indexed timestamp
    );

    // set fee decimals
    event setFeeDecimalsEvent(
        address indexed sender,
        uint256 previousFeeDecimals,
        uint256 newFeeDecimals
    );

    /////////////////////////
    ////    Modifiers    ////
    /////////////////////////

    ////    Standard ERC20 Modifiers    ////

    ////    VanEck Token Modifiers    ////

    // All Transactions Not Frozen
    modifier AllTransactionsNotFrozen() {
        require(!_FreezAllTransactions, 'All transactions are frozen!');
        _;
    }

    // only Owner
    modifier onlyOwner() {
        require(msg.sender == _owner, 'Sender is not the owner address!');
        _;
    }

    // only candidate owner
    modifier onlyCandiateOwner() {
        require(
            msg.sender == _candidateOwner,
            'Sender is not candidate owner address!'
        );
        _;
    }

    // only Token Supply Supervisor
    modifier onlyTokenSupplySupervisor() {
        require(
            msg.sender == _tokenSupplySupervisor || msg.sender == _owner,
            'Sender is not the token supply supervisor address nor owner!'
        );
        _;
    }

    // only candiate Token Supply Supervisor
    modifier onlyCandiateTokenSupplySupervisor() {
        require(
            msg.sender == _candidateTokenSupplySupervisor,
            'Sender is not the candiate token supply supervisor address!'
        );
        _;
    }

    // only account supervisor
    modifier onlyAccountSupervisor() {
        require(
            msg.sender == _accountSupervisor || msg.sender == _owner,
            'Sender is not the account supervisor address!'
        );
        _;
    }

    // only candidate account supervisor
    modifier onlyCandiateAccountSupervisor() {
        require(
            msg.sender == _candidateAccountSupervisor,
            'Sender is not candidate account supervisor address!'
        );
        _;
    }

    // only whitelist supervisor
    modifier onlyWhitelistSupervisor() {
        require(
            msg.sender == _whitelistSupervisor,
            'Sender is not the whitelist supervisor address!'
        );
        _;
    }

    // only candidate whitelist supervisor
    modifier onlyCandidateWhitelistSupervisor() {
        require(
            msg.sender == _candidateWhitelistSupervisor,
            'Sender is not the candidate whitelist supervisor address!'
        );
        _;
    }

    // only fee supervisor
    modifier onlyFeeSupervisor() {
        require(
            msg.sender == _feeSupervisor,
            'Sender is not the fee supervisor address!'
        );
        _;
    }

    // only candidate fee supervisor
    modifier onlyCandidateFeeSupervisor() {
        require(
            msg.sender == _candidateFeeSupervisor,
            'Sender is not the candidate fee supervisor address!'
        );
        _;
    }

    // only fee recipient
    modifier onlyFeeRecipient() {
        require(
            msg.sender == _feeRecipient,
            'Sender is not the fee recipient address!'
        );
        _;
    }

    // only candidate fee recipient
    modifier onlyCandidateFeeRecipient() {
        require(
            msg.sender == _candidateFeeRecipient,
            'Sender is not the candidate fee recipient address!'
        );
        _;
    }
    // only one role for one address
    modifier onlyOneRole(address account_){
        require(
            account_ != _owner &&
            account_ != _candidateOwner &&
            account_ != _tokenSupplySupervisor &&
            account_ != _candidateTokenSupplySupervisor &&
            account_ != _accountSupervisor &&
            account_ != _candidateAccountSupervisor &&
            account_ != _whitelistSupervisor &&
            account_ != _candidateWhitelistSupervisor &&
            account_ != _feeSupervisor &&
            account_ != _candidateFeeSupervisor,
            'Account already has one role!'
        );
        _;
    }

    //////////////////////////////
    ////   Public Functions   ////
    //////////////////////////////

    ////    Standard ERC20    ////

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
    function balanceOf(address account_)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _balances[account_];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to_, uint256 amount_)
        public
        virtual
        override
        AllTransactionsNotFrozen
        returns (bool)
    {
        // require amount > 0
        require(amount_ > 0, 'Amount should be greater than zero!');

        // sender account
        address owner_ = _msgSender();

        // require sender be not frozen
        _requireNotFrozen(owner_);

        // require to be not frozen
        _requireNotFrozen(to_);

        // transfer amount from sender to to address
        _transfer(owner_, to_, amount_);

        // return
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner_, address spender_)
        public
        view
        virtual
        override
        AllTransactionsNotFrozen
        returns (uint256)
    {
        // require sender be not frozen
        _requireNotFrozen(owner_);

        // require spender be not frozen
        _requireNotFrozen(spender_);

        return _allowances[owner_][spender_];
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
    function approve(address spender_, uint256 amount_)
        public
        virtual
        override
        AllTransactionsNotFrozen
        returns (bool)
    {
        address owner_ = _msgSender();
        _approve(owner_, spender_, amount_);
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
        address from_,
        address to_,
        uint256 amount_
    ) public virtual override AllTransactionsNotFrozen returns (bool) {
        address spender_ = _msgSender();
        _spendAllowance(from_, spender_, amount_);
        _transfer(from_, to_, amount_);
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
    function increaseAllowance(address spender_, uint256 addedValue_)
        public
        virtual
        AllTransactionsNotFrozen
        returns (bool)
    {
        address owner_ = _msgSender();
        _approve(owner_, spender_, allowance(owner_, spender_) + addedValue_);
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
    function decreaseAllowance(address spender_, uint256 subtractedValue_)
        public
        virtual
        AllTransactionsNotFrozen
        returns (bool)
    {
        address owner_ = _msgSender();
        uint256 currentAllowance = allowance(owner_, spender_);
        require(
            currentAllowance >= subtractedValue_,
            'ERC20: decreased allowance below zero'
        );
        unchecked {
            _approve(owner_, spender_, currentAllowance - subtractedValue_);
        }

        return true;
    }

    //// VanEck Token Public Functions   ////

    // withdraw tokens from contract to owner account
    function withdrawContractTokens() external onlyOwner {}

    // freeze all transactions
    function freezeAllTransactions() public onlyOwner {}

    // un-freeze all transactions
    function unFreezeAllTransactions() public onlyOwner {}

    // freeze an account
    function freezeAccount(address account_) public onlyAccountSupervisor {
        _requireNotFrozen(account_);
        _freeze[account_] = true;
        emit freezeAccountEvent(_accountSupervisor, account_, block.timestamp);
    }

    // un-freeze and account
    function unFreezeAccount(address account_) public onlyAccountSupervisor {
        _requireFrozen(account_);
        _freeze[account_] = false;
        emit unFreezeAccountEvent(
            _accountSupervisor,
            account_,
            block.timestamp
        );
    }

    // wipe frozen account
    function wipeFrozenAccount(address account_) public onlyAccountSupervisor {
        _requireFrozen(account_);
        uint256 balance = _balances[account_];
        _burn(account_, balance);
        emit wipeFrozenAccountEvent(
            _accountSupervisor,
            account_,
            balance,
            block.timestamp
        );
    }

    // set candidate owner
    function setCandidateOwner(address candidateOwnerAddress_)
        public
        onlyOwner onlyOneRole(candidateOwnerAddress_)
    {
        require(
            candidateOwnerAddress_ != _owner,
            'That address is already set as OwnerAddress.'
        );
        require(
            candidateOwnerAddress_ != _candidateOwner,
            'That address is already set as CandidateOwnerAddress.'
        );
        _candidateOwner = candidateOwnerAddress_;
        emit setCandidateOwnerEvent(
            msg.sender,
            candidateOwnerAddress_,
            block.timestamp
        );
    }

    // cancel candidate owner
    function cancelCandidateOwner() public onlyOwner {
        require(
            _candidateOwner != address(0),
            'We can not cancel zero address.'
        );
        address oldCandidate = _candidateOwner;
        _candidateOwner = address(0);
        emit cancelCandidateOwnerEvent(
            msg.sender,
            oldCandidate,
            block.timestamp
        );
    }

    // update Owner
    function updateOwner() public onlyOwner {
        address oldOwner = _owner;
        _owner = _candidateOwner;
        _candidateOwner = address(0);
        emit updateOwnerEvent(oldOwner, _owner, block.timestamp);
    }

    // set candidate token supply supervisor
    function setCandidateTokenSupplySupervisor(
        address candidateTokenSupplySupervisor_
    ) public onlyOwner onlyOneRole(candidateTokenSupplySupervisor_){
        require(
            candidateTokenSupplySupervisor_ != _candidateTokenSupplySupervisor,
            'This address already set as CandidateTokenSupplySupervisor.'
        );
        require(
            candidateTokenSupplySupervisor_ != address(0),
            'CandidateTokenSupplySupervisor can not be zero address'
        );
        require(
            candidateTokenSupplySupervisor_ != _tokenSupplySupervisor,
            'This address already set as TokenSupplySupervisor.'
        );
        _candidateTokenSupplySupervisor = candidateTokenSupplySupervisor_;
        emit setCandidateTokenSupplySupervisorEvent(
            _owner,
            candidateTokenSupplySupervisor_,
            block.timestamp
        );
    }

    // cancel candidate token supply supervisor
    function cancelCandidateTokenSupplySupervisor() public onlyOwner {
        require(
            _candidateTokenSupplySupervisor != address(0),
            'We can not cancel zero address.'
        );
        address oldCandidate = _candidateTokenSupplySupervisor;
        _candidateTokenSupplySupervisor = address(0);
        emit cancelCandidateTokenSupplySupervisorEvent(
            _owner,
            oldCandidate,
            block.timestamp
        );
    }

    // update candidate token supply supervisor
    function updateTokenSupplySupervisor() public onlyOwner {
        address oldTokenSupplySupervisor = _tokenSupplySupervisor;
        _tokenSupplySupervisor = _candidateTokenSupplySupervisor;
        _candidateTokenSupplySupervisor = address(0);
        emit updateTokenSupplySupervisorEvent(
            oldTokenSupplySupervisor,
            _tokenSupplySupervisor,
            block.timestamp
        );
    }

    // increase total token supply
    function increaseTokenSupply(uint256 amount_)
        public
        onlyTokenSupplySupervisor
        returns (bool)
    {
        require(amount_ != 0, 'Amount can not be 0');
        _mint(msg.sender, amount_);
        emit increaseTokenSupplyEvent(msg.sender, amount_, block.timestamp);
        return true;
    }

    // decrease total token supply
    function decreaseTokenSupply(uint256 amount_)
        public
        onlyTokenSupplySupervisor
        returns (bool)
    {
        require(amount_ != 0, 'Amount can not be 0');
        require(
            amount_ <= _totalSupply,
            'Burn amount is greater than total supply'
        );
        _burn(msg.sender, amount_);
        emit decreaseTokenSupplyEvent(msg.sender, amount_, block.timestamp);
        return true;
    }

    // set candidate account supervisor
    function setCandidateAccountSupervisor(
        address candidateAccountSupervisorAddress_
    ) public onlyOwner onlyOneRole(candidateAccountSupervisorAddress_){
        require(
            candidateAccountSupervisorAddress_ != _candidateAccountSupervisor,
            'This address already set as CandidateAccountSupervisor'
        );
        require(
            candidateAccountSupervisorAddress_ != address(0),
            'CandidateAccountSupervisor Address can not be 0'
        );
        require(
            candidateAccountSupervisorAddress_ != _candidateAccountSupervisor,
            'This address already set as AccountSupervisor'
        );
        _candidateAccountSupervisor = candidateAccountSupervisorAddress_;
        emit setCandidateAccountSupervisorEvent(
            msg.sender,
            candidateAccountSupervisorAddress_,
            block.timestamp
        );
    }

    // cancel candidate account supervisor
    function cancelCandidateAccountSupervisor() public onlyOwner {
        require(
            _candidateAccountSupervisor != address(0),
            'We can not cancel zero address.'
        );
        address oldCandidate = _candidateAccountSupervisor;
        _candidateAccountSupervisor = address(0);
        emit cancelCandidateAccountSupervisorEvent(
            msg.sender,
            oldCandidate,
            block.timestamp
        );
    }

    // update account supervisor
    function updateAccountSupervisor() public onlyOwner {
        address oldAddress = _accountSupervisor;
        _accountSupervisor = _candidateAccountSupervisor;
        _candidateAccountSupervisor = address(0);
        emit updateAccountSupervisorEvent(
            oldAddress,
            _accountSupervisor,
            block.timestamp
        );
    }

    // set candidate whitelist supervisor
    function setCandidateWhitelistSupervisor(
        address candidateWhitelistSupervisorAddress_
    ) public {}

    // cancel candidate whitelist supervisor
    function cancelCandidateWhitelistSupervisor() public {}

    // update whitelist supervisor
    function updateWhitelistSupervisor() public onlyOwner {}

    // add account to whitelist
    function appendToWhitelist(address account_)
        public
        onlyWhitelistSupervisor
    {}

    // remove account from whitelist
    function removeFromWhitelist(address account_)
        public
        onlyWhitelistSupervisor
    {}

    // set candidate fee supervisor
    function setCandidateFeeSupervisor(address candidateFeeSupervisorAddress_)
        public
    {}

    // cancel candidate fee supervisor
    function cancelCandidateFeeSupervisor() public {}

    // update fee supervisor
    function updateFeeSupervisor() public onlyCandidateFeeSupervisor {}

    // set candidate fee recipient
    function setCandidateFeeRecipient(address candidateFeeRecipientAddress_)
        public
    {}

    // cancel candidate fee recipient
    function cancelCandidateFeeRecipient() public {}

    // update fee recipient
    function updateFeeRecipient() public onlyCandidateFeeRecipient {}

    // set fee decimals
    function setFeeDecimals(uint256 feeDecimals_) public onlyFeeSupervisor {}

    /////////////////////////////////
    ////   Internal Functions    ////
    /////////////////////////////////

    ////   Standard ERC20 Functions    ////

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
        address from_,
        address to_,
        uint256 amount_
    ) internal virtual {
        require(from_ != address(0), 'ERC20: transfer from the zero address');
        require(to_ != address(0), 'ERC20: transfer to the zero address');

        _beforeTokenTransfer(from_, to_, amount_);

        uint256 fromBalance = _balances[from_];
        require(
            fromBalance >= amount_,
            'ERC20: transfer amount exceeds balance'
        );
        unchecked {
            _balances[from_] = fromBalance - amount_;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to_] += amount_;
        }

        emit Transfer(from_, to_, amount_);

        _afterTokenTransfer(from_, to_, amount_);
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
    function _mint(address account_, uint256 amount_) internal virtual {
        require(account_ != address(0), 'ERC20: mint to the zero address');

        _beforeTokenTransfer(address(0), account_, amount_);

        _totalSupply += amount_;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account_] += amount_;
        }
        emit Transfer(address(0), account_, amount_);

        _afterTokenTransfer(address(0), account_, amount_);
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
    function _burn(address account_, uint256 amount_) internal virtual {
        require(account_ != address(0), 'ERC20: burn from the zero address');

        _beforeTokenTransfer(account_, address(0), amount_);

        uint256 accountBalance = _balances[account_];
        require(
            accountBalance >= amount_,
            'ERC20: burn amount exceeds balance'
        );
        unchecked {
            _balances[account_] = accountBalance - amount_;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount_;
        }

        emit Transfer(account_, address(0), amount_);

        _afterTokenTransfer(account_, address(0), amount_);
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
        address owner_,
        address spender_,
        uint256 amount_
    ) internal virtual {
        require(owner_ != address(0), 'ERC20: approve from the zero address');
        require(spender_ != address(0), 'ERC20: approve to the zero address');

        _allowances[owner_][spender_] = amount_;
        emit Approval(owner_, spender_, amount_);
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
        address owner_,
        address spender_,
        uint256 amount_
    ) internal virtual {
        uint256 currentAllowance = allowance(owner_, spender_);
        if (currentAllowance != type(uint256).max) {
            require(
                currentAllowance >= amount_,
                'ERC20: insufficient allowance'
            );
            unchecked {
                _approve(owner_, spender_, currentAllowance - amount_);
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
        address from_,
        address to_,
        uint256 amount_
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
        address from_,
        address to_,
        uint256 amount_
    ) internal virtual {}

    ////    VanEck Token Functions    ////

    // requireNotFrozen
    function _requireNotFrozen(address account_) internal view virtual {
        // require account be no zero
        require(account_ != address(0), 'Entered zero address');

        // require account not frozen
        require(!_freeze[account_], 'Account is frozen!');
    }

    // requireFrozen
    function _requireFrozen(address account_) internal view virtual {
        // require account be no zero
        require(account_ != address(0), 'Entered zero address');

        // require account not frozen
        require(_freeze[account_], 'Account is not frozen!');
    }
}