/**
 *Submitted for verification at Etherscan.io on 2022-07-08
*/

// File: contracts/interfaces/IMasterContract.sol


pragma solidity 0.8.7;

interface IMasterContract {
    /// @notice Init function that gets called from `BoringFactory.deploy`.
    /// Also kown as the constructor for cloned contracts.
    /// Any ETH send to `BoringFactory.deploy` ends up here.
    /// @param data Can be abi encoded arguments or anything else.
    function init(bytes calldata data) external payable;
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

// File: contracts/LendPool.sol

pragma solidity 0.8.7;




contract LENDPOOL is IMasterContract{

    
    ERC20 public collateral;
    IERC20 public borrowableToken;

    address public protocolFeePool;

    uint256 public constant CREATE_POOL_FEE= 0.0001 ether;

    uint256 public collaterizationRate;
    uint256 public liquidationPenalty;
    uint256 public maxCollateral=80;
    uint256 public borrowOpenigFee;
    uint256 public price;
    uint256 public basisPoint;
    uint256 public intrestRate;
    uint256 public numConfirmationsRequired;
    uint256 public totalPoolLiquidity;
    //intrest rate
    //basis point
    string public ticker;

    string [] public tokenList;
    address []public owners;
    address public admin;

  

    address  [] public lpProvidersArray;
    mapping(address => address) public masterContractOf;
    mapping(address=>uint256) public LpAmountProvided;
    mapping(address=>mapping(string=>uint256)) public supplyBalance;
    mapping(address=>uint256) public borrowBalance;
    mapping(address=>mapping(string=>uint256)) public collateralAmount;

    mapping(address=>uint256) public withdrawableCollateral;
    mapping (address=>bool) public isOwner;
    mapping(uint256=> mapping(address=>bool))public approved;
    mapping (string=>TOKEN)public tokenMapping;

    struct TRANSACTION{
        address to;
        uint256 value;
        string ticker;
        bytes data;
        bool executed;
    }

    struct LTRANSACTION{
        address to;
        uint256 value;
        bytes data;
        bool executed;
    }

    struct TOKEN{
        string ticker;
        address tokenAddress;
    }

    TRANSACTION [] public transactions;
    LTRANSACTION [] public ltransactions;

    

    error ALREADY_INITIALIZED();
    error FAILURE();
    error NOT_AUTHORISED();
    error YOU_DONT_HAVE_THAT_MUCH_LIQUIDITY();
    error NOT_ENOUGH_LIQUIDITY_TO_SUPPORT_YOUR_COLLATERAL();
    error CANT_SEND_ZERO();
    error NOT_ENOUGH_COLLATERAL();
    error CANT_BORROW_MORE_THAN_MAX_BORROW();
    error YOU_HAVE_NO_DEBT();
    error CANT_BE_LIQUIDATED(); 
    error INVALID_OWNER();
    error AMOUNT_HIGHER_THAN_AVAILABLE_LIQUIDATED_COLLATERAL();
    error AMOUNT_HIGHER_THAN_AVAILABLE_LIQUIDITY();
    error TRANSACTION_DOES_NOT_EXIST();
    error TRANSACTION_ALREADY_APPROVED();
    error TRANSACTION_ALREADY_EXECUTED();

    event LogDeploy(address indexed masterContract, bytes data, address indexed cloneAddress);
    event poolCreated(ERC20 colleteral, address borrowabletoken, string ticker);
    event liquidityAdded(address from, address to, uint256 amount);
    event liquidityWithdrawn(address from, address to, uint256 amount);
    event borrowed(address from, address to, uint256 amount);
    event repaid (address payer, uint256 amount);
    event repaidFor(address payer, address payee, uint256 amount);
    event liquidated(address liquidator, address liquidated, uint256 colleteralAmount, uint256 amountBorrowed);
    event addedToLiquidityProviders(address added);
    event removedFromLiquidityProviders(address removed);
    event withdrawn(address owner, uint256 amount);
    event transactionSubmitted(uint256 txId);
    event transactionConfirmed(address indexed owner, uint indexed txIndex);
    event transactionExecuted(uint256 txId);
    event transactionRevoked(uint256 txId, address owner);
    event numberConfirmationUpdated(uint256 num);
    event ownerRemoved(address owner);
    event updatedOwners(address owner);
     event tokenAdded(address addedBy, string ticker, address tokenAddress, uint timeOfTransaction);

    constructor(){
        admin=msg.sender;  
        owners.push(msg.sender);
    }

    modifier onlyOwners(){
        if (!isOwner[msg.sender]) revert NOT_AUTHORISED();
        _;
    }

    modifier onlyAdmin(){
        if (msg.sender!=admin) revert NOT_AUTHORISED();
        _;
    }

    modifier txExists(uint256 _txId){
        require(_txId < transactions.length, "tx does not exist");
        _;
    }

    modifier notApproved(uint256 _txId) {
        require(!approved[_txId][msg.sender], "tx already confirmed");
        _;
    }

    modifier notExecuted(uint256 _txId){
        if(!transactions[_txId].executed) revert TRANSACTION_ALREADY_EXECUTED();
        _;
    }

    modifier tokenExist(string memory _ticker){
        require (tokenMapping[_ticker].tokenAddress != address(0), "token does not exist");
        _;

    }

    function init(bytes calldata data) public payable override {
        if (address(collateral) != address(0)) revert ALREADY_INITIALIZED();
        (collateral, borrowableToken, ticker) = abi.decode(data, (ERC20, IERC20, string));
        require (keccak256 (bytes(collateral.symbol()))==keccak256 (bytes(ticker)));
        tokenList.push(ticker);
        require(address(collateral) != address(0), " bad pair");

    }

    function encode(ERC20 _colleteral, address _borrowabletoken, string calldata _ticker)internal pure returns (bytes memory){
        return abi.encode(_colleteral,_borrowabletoken, _ticker);

    }

    function createPool(ERC20 _collateral, address _borrowabletoken, string calldata _ticker)external payable{
        //(bool callSuccess, )=payable(msg.sender).call{value:CREATE_POOL_FEE} ("");
       // if (!callSuccess)revert FAILURE();
        require (keccak256 (bytes(_collateral.symbol()))==keccak256 (bytes(_ticker)));
        bytes memory data =encode( _collateral, _borrowabletoken, _ticker);
        deploy(address(this), data, true);

        emit poolCreated(_collateral, _borrowabletoken, _ticker );
    }

    function setMultiSig (address[] memory _owners, uint _numConfirmationsRequired) external{
        require(_owners.length > 0, "owners required");
        require(
            _numConfirmationsRequired > 0 &&
                _numConfirmationsRequired <= _owners.length,
            "invalid number of required confirmations"
        );

        for (uint i = 0; i < _owners.length; i++) {
            address owner = _owners[i];

            require(owner != address(0), "invalid owner");
            require(!isOwner[owner], "owner not unique");

            isOwner[owner] = true;
            owners.push(owner);
        }

        numConfirmationsRequired = _numConfirmationsRequired;
    }

    function updateNumberConfirmation(uint256 _Num)external onlyOwners{
        numConfirmationsRequired=_Num;
        emit numberConfirmationUpdated(_Num);
    }

    function updateOwners(address _newOwner)external onlyOwners{
        require(_newOwner != address(0), "invalid owner");
        require(!isOwner[_newOwner], "owner not unique");
        owners.push(_newOwner);
        emit updatedOwners(_newOwner);
    }

    function removeOwner(uint256 _ownersId)external{
        address _owner=owners[_ownersId];
        delete _owner;
        emit ownerRemoved(_owner);
    }

    function _reset(string memory _tokenName)internal{
        if(supplyBalance[msg.sender][_tokenName]==0){
            collateralAmount[msg.sender][_tokenName]=0;
        }
    }

    function addLiquidity(uint256 _amount)external payable{
        if(_amount<=0) revert CANT_SEND_ZERO();
        if(!isOwner[msg.sender]) revert INVALID_OWNER();
        borrowableToken.transferFrom(msg.sender, address(this),_amount);
        LpAmountProvided[msg.sender]+=_amount;
        totalPoolLiquidity+=_amount;
        emit liquidityAdded(msg.sender, address(this),_amount);
    }


    function addColleteral(uint256 _amount, string memory _ticker)external payable  {
        _reset(_ticker);
        if(_amount<=0) revert CANT_SEND_ZERO();
       if (_amount>totalPoolLiquidity)revert  NOT_ENOUGH_LIQUIDITY_TO_SUPPORT_YOUR_COLLATERAL();
        require(tokenMapping[_ticker].tokenAddress != address(0), "token does not exixts");
       IERC20(tokenMapping[_ticker].tokenAddress).transferFrom(msg.sender, address(this), _amount);
        collateralAmount[msg.sender][_ticker]+=_amount;
        supplyBalance[msg.sender][_ticker]+=_amount;
        
        emit borrowed(msg.sender, address(this),_amount);
    }

    function borrow(uint256 _amount, string memory _ticker)external tokenExist(_ticker){
        if(_amount<=0) revert CANT_SEND_ZERO();
        if(collateralAmount[msg.sender][_ticker]<=(maxCollateral*collateralAmount[msg.sender][_ticker])/100) revert CANT_BORROW_MORE_THAN_MAX_BORROW();
        if(supplyBalance[msg.sender][_ticker]<_amount) revert NOT_ENOUGH_COLLATERAL();
        borrowableToken.transfer(  msg.sender, _amount);
        supplyBalance[msg.sender][_ticker]-=_amount;
        borrowBalance[msg.sender]+=_amount;
        emit borrowed(msg.sender, address(this),(maxCollateral*collateralAmount[msg.sender][_ticker]/100));
    }

    function repay(uint256 _amount, string memory _ticker)external payable tokenExist(_ticker){
        if(supplyBalance[msg.sender][_ticker]==0) revert YOU_HAVE_NO_DEBT();
        borrowableToken.transferFrom( msg.sender, address(this), _amount);
        collateralAmount[msg.sender][_ticker]-=_amount;
        supplyBalance[msg.sender][_ticker]-=_amount;
        IERC20(tokenMapping[_ticker].tokenAddress).transfer(msg.sender, _amount);
        emit repaid(msg.sender,  _amount);
    }

    function liquidate(address _toLiquidate, string memory _ticker)external tokenExist(_ticker){
        uint256 healthFactor=supplyBalance[_toLiquidate][_ticker]*maxCollateral/borrowBalance[_toLiquidate]*100;
        if(healthFactor>1)revert CANT_BE_LIQUIDATED(); 
        withdrawableCollateral[admin]=collateralAmount[_toLiquidate][_ticker];
        supplyBalance[_toLiquidate][_ticker]=0;
        borrowBalance[_toLiquidate]=0;
        emit liquidated(msg.sender, _toLiquidate, supplyBalance[_toLiquidate][_ticker], borrowBalance[_toLiquidate]);

    }

    function submitTransactionCollateral(address _to, uint256 _value, string calldata _ticker, bytes calldata _data)external{
        if(withdrawableCollateral[admin]<=0) revert CANT_SEND_ZERO();
        if(withdrawableCollateral[admin]<_value) revert AMOUNT_HIGHER_THAN_AVAILABLE_LIQUIDATED_COLLATERAL();
        transactions.push(TRANSACTION({to:_to, value: _value, ticker:_ticker, data: _data, executed:true}) );
        emit transactionSubmitted(transactions.length-1);
    }

    function submitTransactionLiquidity(address _to, uint256 _value, bytes calldata _data)external{
        if(totalPoolLiquidity<=0) revert CANT_SEND_ZERO();
        if(totalPoolLiquidity<_value) revert AMOUNT_HIGHER_THAN_AVAILABLE_LIQUIDITY();
        ltransactions.push(LTRANSACTION({to:_to, value: _value, data: _data, executed:true}) );
        emit transactionSubmitted(transactions.length-1);
    }

    function approveTransaction(uint256 _txId)external onlyOwners 
    txExists(_txId) notApproved(_txId) notExecuted(_txId){
        approved[_txId][msg.sender]=true;
        emit transactionConfirmed(msg.sender, _txId);

    }

    function _getApprovalCount(uint256 _txId)private view returns(uint256 count){
        for (uint i; i <owners.length; i++){
            if(approved[_txId][owners[i]]){
                count++;
            }
        }
    }

    function executeTransactionCollateral(uint256 _txId)external txExists(_txId)  notExecuted(_txId){
        require(_getApprovalCount(_txId)>=numConfirmationsRequired, "approval less than required ");
        TRANSACTION storage transaction=transactions[_txId];
        transaction.executed=true;
        uint256 _collateralAmount = transaction.value;
        address _to=transaction.to;
        string memory _ticker=transaction.ticker;
        withdrawableCollateral[admin]-=_collateralAmount;
        IERC20(tokenMapping[_ticker].tokenAddress).transfer(_to, _collateralAmount);
        emit transactionExecuted (_txId);
    }

    function executeTransactionLiquidity(uint256 _txId)external txExists(_txId)  notExecuted(_txId){
        require(_getApprovalCount(_txId)>=numConfirmationsRequired, "approval less than required ");
        TRANSACTION storage transaction=transactions[_txId];
        transaction.executed=true;
        uint256 _Amount = transaction.value;
        address _to=transaction.to;
        borrowableToken.transfer( _to, _Amount);
        emit transactionExecuted (_txId);
    }


    function revokeTransaction(uint256 _txId)external onlyOwners txExists(_txId)  notExecuted(_txId) {
        require (approved[_txId][msg.sender], "tx not approved ");
        approved[_txId][msg.sender]=false;
        emit transactionRevoked(_txId, msg.sender);
    }

    function withdrawCollateral(string memory _ticker )external onlyOwners{
        require(owners.length==1, "NOT AUTHORISED");
        withdrawableCollateral[admin]=0;
        IERC20(tokenMapping[_ticker].tokenAddress).transfer(msg.sender, withdrawableCollateral[admin]);
        emit withdrawn(msg.sender, withdrawableCollateral[admin]);
    }

    function addToken(string memory _ticker, address _tokenAddress)external onlyOwners{
        for (uint256 i; i<tokenList.length; i++){
            require(keccak256(bytes(tokenList[i])) != keccak256(bytes(_ticker)), "cannot add duplicate tokens");
        }
        require(keccak256(bytes(ERC20(_tokenAddress).symbol())) == keccak256(bytes(_ticker)));
        tokenMapping[_ticker] = TOKEN(_ticker, _tokenAddress);
        
        tokenList.push(_ticker);
        
        emit tokenAdded(msg.sender, _ticker, _tokenAddress, block.timestamp);
    }



    function deploy(
        address masterContract,
        bytes memory data,
        bool useCreate2
    ) public payable returns (address cloneAddress) {
        
        (masterContract != address(0), "No masterContract");
        bytes20 targetBytes = bytes20(masterContract); 
        if (useCreate2) {
           
            bytes32 salt = keccak256(data);

           
            assembly {
                let clone := mload(0x40)
                mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
                mstore(add(clone, 0x14), targetBytes)
                mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
                cloneAddress := create2(0, clone, 0x37, salt)
            }
        } else {
            assembly {
                let clone := mload(0x40)
                mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
                mstore(add(clone, 0x14), targetBytes)
                mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
                cloneAddress := create(0, clone, 0x37)
            }
        }
        masterContractOf[cloneAddress] = masterContract;

       

        emit LogDeploy(masterContract, data, cloneAddress);
    }


    function withdrawableCollateralBalance()public view returns (uint256){
        return withdrawableCollateral[admin];
    }

    function getOwners()public view returns(address [] memory){
        return owners;
    }



}