/**
 *Submitted for verification at Etherscan.io on 2022-09-11
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

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
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
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

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {


    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

   
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner,"Caller is Not owner");
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }
}


contract AlanFriday is ERC20, Ownable {
    using SafeMath for uint256;

    uint256 private _totalSupply = uint256(25100000).mul(1e18);
    uint256 public creationTime;
    uint256 internal lockInDuration = 300;
    address public STAKE_RESERVE;
    address public ECO_SYSTEM;
    address public ADVISORY;
    address public MARKETPLACE;
    address public LIQUIDITY;
    address public DEV_TEAM;

    mapping(address => bool) public whiteListedAccount;

    struct Phase{
        uint256 totalTokens;
        uint256 balanceTokens;
        uint256 exchangeRate;
    }
    mapping(uint256 => Phase) public phaseDetails; //Phase id --> phase
    uint256 public totalPhases = 5;

    struct LockUpData{
        uint256 start;
        uint256 end;
        uint256 tokens;
    }
    mapping(address => LockUpData) private lockUpDetails;

    event PhaseExchangeRateUpdated(uint256 phaseId, uint256 exchangeRate);
    event TokenBuy(address indexed owner, uint256 payableAmount, uint256 tokens, uint256 phaseId);
    event TokenLocked(address indexed owner, uint256 startDate, uint256 endDate, uint256 tokens);
   
    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(
        address _STAKE_RESERVE,
        address _ECO_SYSTEM,
        address _ADVISORY,
        address _MARKETPLACE,
        address _LIQUIDITY,
        address _DEV_TEAM
    ) ERC20("AlanFriday","ALFRI"){

        creationTime = block.timestamp;
    

        // Set Phase Details.
        phaseDetails[1] = Phase(uint256(1500000).mul(1e18), uint256(1500000).mul(1e18), 10000000000000);
        phaseDetails[2] = Phase(uint256(1500000).mul(1e18), uint256(1500000).mul(1e18), 20000000000000);
        phaseDetails[3] = Phase(uint256(1500000).mul(1e18), uint256(1500000).mul(1e18), 30000000000000);
        phaseDetails[4] = Phase(uint256(1500000).mul(1e18), uint256(1500000).mul(1e18), 40000000000000);
        phaseDetails[5] = Phase(uint256(1500000).mul(1e18), uint256(1500000).mul(1e18), 50000000000000);

        STAKE_RESERVE = _STAKE_RESERVE;
        ECO_SYSTEM = _ECO_SYSTEM;
        ADVISORY = _ADVISORY;
        MARKETPLACE = _MARKETPLACE;
        LIQUIDITY = _LIQUIDITY;
        DEV_TEAM = _DEV_TEAM;

        // Total Supply;
        _mint(address(this), _totalSupply);

        // PHASE RESERVE = 6% each
        _transfer(address(this),STAKE_RESERVE,uint256(7500000).mul(1e18));
        _transfer(address(this),ECO_SYSTEM,uint256(1000000).mul(1e18));
        _transfer(address(this),ADVISORY,uint256(1000000).mul(1e18));
        _transfer(address(this),MARKETPLACE,uint256(1000000).mul(1e18));
        _transfer(address(this),LIQUIDITY,uint256(1000000).mul(1e18));
        _transfer(address(this),DEV_TEAM,uint256(1000000).mul(1e18));
    }

    function setPhaseExchangeRate(uint256 _phaseId, uint256 _exchangeRate)
    external
    onlyOwner{
        require(checkPhaseExists(_phaseId),"Error: Phase does not exists!");
        require(_exchangeRate != 0,"Error: Exchange rate should not be zero!");
        
        phaseDetails[_phaseId].exchangeRate = _exchangeRate;

        emit PhaseExchangeRateUpdated(_phaseId, _exchangeRate);
    }

    // Get Active Phase
    function activePhase() public view returns (bool, uint256){

        for(uint256 _phaseId = 1; _phaseId <= totalPhases; _phaseId++){
            Phase memory _currentPhase =  phaseDetails[_phaseId];

            if(_currentPhase.balanceTokens > 0)
            {
                return (true,_phaseId);
            }
        }
        return (false,0);
    }  

    function buyToken()
    public
    payable{
        // Check Active Phase
        (bool _phaseStatus, uint256 _phaseId) = activePhase();

        // Check if Any Active Phase ongoing
        require(_msgSender() != STAKE_RESERVE,"Error: Cannot make purchase with the reserve address");
        require(_phaseStatus == true,"Error: No active phase");
        require(msg.value > 0,"Error: This action is payable");

        uint256 _paybleAmt = msg.value;
        uint256 _userTransferTokens = _paybleAmt.div(phaseDetails[_phaseId].exchangeRate);
        _userTransferTokens = _userTransferTokens.mul(1e18);// convert into wei

        /*In the given sale each user cannot buy more than 1000000*/

        uint256 _privateSaleUserBought = lockUpDetails[_msgSender()].tokens.add(_userTransferTokens);

        if(_privateSaleUserBought > uint256(1000000).mul(1e18)){
            revert("Error: User cannot buy more than 1000000 tokens in the Private Sale!");
        }

        // Check if the amount is greater than the available phase balance
        if(_userTransferTokens > phaseDetails[_phaseId].balanceTokens){

            // Get the remaining amount payable for getting the tokens based on next phase
            uint256 _newPayableAmt = (_userTransferTokens.sub(phaseDetails[_phaseId].balanceTokens)).mul(phaseDetails[_phaseId].exchangeRate);
            _userTransferTokens = phaseDetails[_phaseId].balanceTokens;
            
            // Check whether the next phase exists?
            uint256 _nextPhaseId = _phaseId.add(1);

            if(!checkPhaseExists(_nextPhaseId)){
                revert("Error: You cannot buy more than available tokens in current phase!");
            }

            uint256 _leftTransferTokens = _newPayableAmt.div(phaseDetails[_nextPhaseId].exchangeRate);
            
            phaseDetails[_phaseId].balanceTokens = phaseDetails[_phaseId].balanceTokens.sub(_userTransferTokens);
            phaseDetails[_nextPhaseId].balanceTokens = phaseDetails[_nextPhaseId].balanceTokens.sub(_leftTransferTokens);
            
            // Total transferable tokens as per both the phases
            _userTransferTokens = _userTransferTokens.add(_leftTransferTokens);
        }else{
            phaseDetails[_phaseId].balanceTokens = phaseDetails[_phaseId].balanceTokens.sub(_userTransferTokens);
        }
        
        if(lockUpDetails[_msgSender()].start == 0 && lockUpDetails[_msgSender()].end == 0){
            uint256 _startDate = block.timestamp;
            uint256 _endDate = _startDate.add(lockInDuration);
            lockUpDetails[_msgSender()].start = _startDate;
            lockUpDetails[_msgSender()].end = _endDate;

            emit TokenLocked(_msgSender(), _startDate, _endDate, _userTransferTokens);
        }
        lockUpDetails[_msgSender()].tokens = lockUpDetails[_msgSender()].tokens.add(_userTransferTokens);
        // Transfer token to user
        _transfer(STAKE_RESERVE,_msgSender(),_userTransferTokens);

        emit TokenBuy(_msgSender(), _paybleAmt, _userTransferTokens, _phaseId);
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
        validatePhase(_msgSender(),recipient, amount);

        _transfer(_msgSender(), recipient, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        validatePhase(from, to, amount);
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);

        return true;
    }

    function checkPhaseExists(uint256 _phaseId) public view returns (bool){
        bool _phaseIdValid = false;

        if(_phaseId > 0 && _phaseId <= totalPhases){
            _phaseIdValid = true;
        }

        return _phaseIdValid;

    }
    function validatePhase(address _sender, address _receiver, uint256 _amount) internal returns (bool) {
        if(lockUpDetails[_sender].start !=0 && lockUpDetails[_sender].end !=0){
            if(whiteListedAccount[_sender] == false){
                require(lockUpDetails[_sender].end < block.timestamp, "Error: Cannot transfer before 15 months lockup period");
            }
        }
        // Check if any phase is active
        (bool _phaseStatus, uint256 _phaseId) = activePhase();
        if(_phaseStatus){
            if(_sender == STAKE_RESERVE){
                if(_amount > phaseDetails[_phaseId].balanceTokens){
                    uint256 _leftTokens = _amount.sub(phaseDetails[_phaseId].balanceTokens);
                    // Check whether the next phase exists?
                    uint256 _nextPhaseId = _phaseId.add(1);

                    phaseDetails[_phaseId].balanceTokens = phaseDetails[_phaseId].balanceTokens.sub(_amount.sub(_leftTokens));

                    if(checkPhaseExists(_nextPhaseId)){
                        phaseDetails[_nextPhaseId].balanceTokens = phaseDetails[_nextPhaseId].balanceTokens.sub(_leftTokens);
                    }
                }else{
                    phaseDetails[_phaseId].balanceTokens = phaseDetails[_phaseId].balanceTokens.sub(_amount);
                }

                if(lockUpDetails[_receiver].start == 0 && lockUpDetails[_receiver].end == 0){
                    uint256 _startDate = block.timestamp;
                    uint256 _endDate = _startDate.add(lockInDuration);
                    lockUpDetails[_receiver].start = _startDate;
                    lockUpDetails[_receiver].end = _endDate;

                    emit TokenLocked(_receiver, _startDate, _endDate, _amount);
                }
                lockUpDetails[_receiver].tokens = lockUpDetails[_receiver].tokens.add(_amount);
            }
        }
        return true;
    }
    
    function burn(address account, uint256 amount) external returns (bool){
        require(account == _msgSender(),"Error: Only token owner can call this method!");

        _burn(account, amount);

        delete lockUpDetails[_msgSender()];

        return true;
    }
    
    // Add caller to whitelist, Allows the use to transfer amount in lockin period
    function addCallerToWhitelist(address _account) public onlyOwner returns(bool){
        whiteListedAccount[_account] = true;
        return true;
    }

    // Remove caller from whitelist, Prevents the user to transfer amount in lockin period
    function removeCallerFromWhitelist(address _account) public onlyOwner returns(bool){
        whiteListedAccount[_account] = false;
        return true;
    }

    // Authenticated transfer tokens
    function authenticatedTransfer(uint256 _amount) public onlyOwner returns (bool) {
        require(_amount > 0, "Error: Amount should be greater than 0!");
        require(balanceOf(address(this)) > 0 && balanceOf(address(this)) >= _amount, "Insufficient tokens!");
        _transfer(address(this),owner,_amount);
        
        return true;
    }

    // Panic withdrawal for tokens
    function panicWithdrawToken() public onlyOwner returns (bool) {
        require(balanceOf(address(this)) > 0, "Error: Insufficient tokens!");
        _transfer(address(this),owner,balanceOf(address(this)));
        
        return true;
    }

    // Panic withdrawal for chain token
    function panicWithdraw() public onlyOwner returns (bool) {
        require(address(this).balance > 0, "Error: Insufficient balance!");
        payable(owner).transfer(address(this).balance);
        return true;
    }

    // Disolve contract to be used only in case of emergency
    function disolve() external onlyOwner returns (bool) {
        // must add some flag check to prevent accidental dissolve
        address payable _owner = payable(owner);
        selfdestruct(_owner);
        return true;
    }
}