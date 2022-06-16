/**
 *Submitted for verification at Etherscan.io on 2022-06-15
*/

/**
 *Submitted for verification at polygonscan.com on 2022-02-10
*/

// File: @openzeppelin/contracts/utils/Counters.sol


// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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


// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

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

// File: contracts/staking.sol


pragma solidity 0.8.7;






contract StakingToken is  Ownable{

	IERC20 agro = IERC20(0x44e9eFFfcAc019E8442Fd6655D190834F4167486);

    using Counters for Counters.Counter;
    Counters.Counter private refererCounter;
    mapping(address => bool ) private refererMap;

    address admin;
    address refererRewardAccount ;
    uint256 public minimumInvestment ;
    uint256 public firstRefererReward ;
    uint256 public secondRefererReward ;

    uint256 public STARTERS_APY ;
    uint256 public RIDE_APY ;
    uint256 public FLIGHT_APY ;

    uint256 public STARTERS_time;
    uint256 public RIDE_time;
    uint256 public FLIGHT_time;

    uint256 private APY_time; // APY calculted on per  day/month/year basis
    mapping(address => user) private user_list;


    struct user {
        bool givenToReferer; 
        address referer;
        uint256 accumulatedReward;
        uint256 stakedAmount;
        uint256 starttime; // start of any stake
        uint256 rewardtime; // last reward withdrawal
        uint256 package; // { STARTERS , RIDE, FLIGHT } 0,1,2 
        uint256 timesReferred; // times this user was used as a referer

    }

    modifier onlyAdmin {
      require(msg.sender == admin, "Not an Admin");
      _;
    }






    constructor( )  { 
        admin = owner();
        refererRewardAccount = owner();
        minimumInvestment = 1000; // 1000 AMT tokens
        APY_time = 30 days; 
        firstRefererReward = 2; 
        secondRefererReward = 1;

        STARTERS_APY = 5 ;
        RIDE_APY = 7;
        FLIGHT_APY = 10 ;

        STARTERS_time = 90 days;
        RIDE_time = 180 days;
        FLIGHT_time = 365 days ;
        
    }



    function set_admin(address _admin) public onlyOwner {
        admin = _admin ;
    }

    function set_refererRewardAccount(address _refererRewardAccount) public onlyAdmin {
        refererRewardAccount = _refererRewardAccount ;
    }

    function set_lockup(uint256 _starter, uint256 _ride, uint256 _flight) public onlyAdmin {
        STARTERS_time = _starter;
        RIDE_time = _ride;
        FLIGHT_time = _flight ;
    }

    function set_apyCalculation(uint256 temp) public onlyAdmin {
        APY_time = temp;
    }
    function set_minimumInvestment(uint256 temp) public onlyAdmin {
        minimumInvestment = temp;
    }
    function set_firstRefererReward(uint256 temp) public onlyAdmin {
        firstRefererReward = temp;
    }
    function set_secondRefererReward(uint256 temp) public onlyAdmin {
        secondRefererReward = temp;
    }
    function set_apy(uint256 _STARTERS_APY, uint256 _RIDE_APY, uint256 _FLIGHT_APY) public onlyAdmin {
        STARTERS_APY = _STARTERS_APY;
        RIDE_APY = _RIDE_APY;
        FLIGHT_APY = _FLIGHT_APY;
    }

    function getStakeStartTime(address _user) public view returns(uint256) {
        return user_list[_user].starttime;
    }

    function getStakeEndTime(address _user) public view returns(uint256 temp) {
        if (user_list[_user].package==0)
            return user_list[_user].starttime+STARTERS_time;
            
        if (user_list[_user].package==1)
            return user_list[_user].starttime+RIDE_time;

        if (user_list[_user].package==2)
            return user_list[_user].starttime+FLIGHT_time;
    
    }

    // returns TVL in this contract
    function getTotalStaked() public view returns(uint256) {
        return agro.balanceOf(address(this) ) ;
    }

    // get total number of referers used in contract
    function getTotalReferers() public view returns(uint256) {
        return refererCounter.current();
    }

    // get number of times a user was used as a referrer
    function getTimesReferred(address _user) public view returns(uint256) {
        return user_list[_user].timesReferred  + user_list [ user_list[_user].referer ].timesReferred ;   
    }

    function getUnstakeStatus(address _user ) public view returns(bool) {
        if (isUnstakingBeforeLockup( _user ) == true ) 
            return true;
        else
            return false;
    }

    // get total stake of a particular account
    function stakeOf(address _stakeholder) public view returns(uint256) {
        return user_list[_stakeholder].stakedAmount;
    }

    function currentRewards(address _user ) public view returns(uint256) {

        return  user_list[_user].accumulatedReward + calculateReward(_user);
    }

    function withdrawRewards() public {
        uint256 w_reward = user_list[msg.sender].accumulatedReward + calculateReward(msg.sender);
        user_list[msg.sender].accumulatedReward = 0; 
        user_list[msg.sender].rewardtime = block.timestamp ;


        require(w_reward>0 , "No reward to withdraw");
        agro.transferFrom (admin, msg.sender, w_reward);

    }

    function stake(uint256 _stake, uint256 _package, address _referer) public {

        require ( _stake >= minimumInvestment, "Sent Less than Minimum investment");
        require ( agro.allowance(msg.sender, address(this)) >= _stake , "allowance not given");
        require ( (_package <3 && _package >= 0 ) , "Undefinded Package" ) ;
        if( _referer != address(0) )
            require ( user_list[_referer].givenToReferer == true , "Your Referer has not staked" ) ;
        
        if ( refererMap[_referer] == false ) {
            refererCounter.increment(); // increments when new referer is detected
            refererMap[_referer] = true ;
            }
        
        if ( user_list[msg.sender].givenToReferer == false ) // only gives reward to referer when false
        {
        user_list[msg.sender].referer = _referer;
        user_list[_referer].timesReferred++ ; // times this user was used as a referer

        distributeReward( _stake ); // gives reward to referer
        
        user_list[msg.sender].givenToReferer = true ; // turns it true when reward is given
        }


        agro.transferFrom (msg.sender, address(this), _stake); // transferring stake to contract
        agro.transfer ( admin, _stake*2/100); // 2% fee to Admin

        _stake = _stake - _stake*2/100 ; // recomputes stake after giving 2% fee
       





        if ( user_list[msg.sender].starttime > 0 ) // will not trigger for first time only
        user_list[msg.sender].accumulatedReward += calculateReward(msg.sender) ; // saves any not withdrawn rewards before staking again

        user_list[msg.sender].starttime = block.timestamp;
        user_list[msg.sender].rewardtime = block.timestamp;

        user_list[msg.sender].stakedAmount += _stake;
       
        user_list[msg.sender].package = _package;
    
        
    }


    function unStake(uint256 _stake) public {
        require ( stakeOf(msg.sender) > 0 , "Nothing staked" ) ;
        require( (user_list[msg.sender].stakedAmount - _stake) >= 0 , "Cant remove more than stake");

        if ( isUnstakingBeforeLockup(msg.sender) == true){
            

            agro.transfer (msg.sender, _stake*50/100); //50% to User
            agro.transfer (admin, _stake*50/100); //50% Fine given to Admin
            user_list[msg.sender].stakedAmount -= _stake;
            user_list[msg.sender].accumulatedReward = 0;
        
        }
        else{
        
        uint256 w_reward = user_list[msg.sender].accumulatedReward + calculateReward(msg.sender);

        user_list[msg.sender].rewardtime = block.timestamp;


    
        agro.transferFrom (admin, msg.sender, w_reward);
        agro.transfer (msg.sender, _stake);

        user_list[msg.sender].stakedAmount -= _stake;
        user_list[msg.sender].accumulatedReward = 0;
        }


    }


    // calculates rewards based on packages
    function calculateReward (address _stakeholder) view private returns (uint256){
            uint256 roi = 0;
            uint256 time = block.timestamp - user_list[_stakeholder].rewardtime;
            
            
            if (user_list[_stakeholder].package == 0 ) { // STARTERS 
                roi = time  * ( user_list[_stakeholder].stakedAmount * STARTERS_APY/100 )  ;
                roi = roi / APY_time;
            }
            if (user_list[_stakeholder].package == 1 ) { // RIDE
                 roi = time * ( user_list[_stakeholder].stakedAmount * RIDE_APY/100 ) ;
                 roi = roi / APY_time;
            }
            if (user_list[_stakeholder].package == 2 ) { // FLIGHT
                roi = time * ( user_list[_stakeholder].stakedAmount * FLIGHT_APY/100 ) ;
                roi = roi / APY_time;
            }

            return roi; 

       }



    // gives rewards to referer
    function distributeReward (uint256 _stake) private {
        address t_ref = user_list[msg.sender].referer ; 
        if ( t_ref != address(0)) {
            agro.transferFrom ( refererRewardAccount , t_ref , _stake * firstRefererReward /100 ); // referer of msg.sender
           


            t_ref = user_list[ t_ref ].referer ;

            if  ( t_ref != address(0) ){
                agro.transferFrom ( refererRewardAccount , t_ref , _stake * secondRefererReward /100 ); // referer of referer
                

            }
    
        }

    }       

    // returns TRUE if user is unstaking before lock-up else False
    function isUnstakingBeforeLockup(address _user) private view returns(bool temp){
        uint256 time = block.timestamp - user_list[_user].starttime;

         if (user_list[_user].package == 0 ) // STARTERS
            {
                if ( time >= STARTERS_time )  // 3 months lock up
                return false ;
                else
                return true;  

            }
        if (user_list[_user].package == 1 ) // RIDE
            {
                if ( time >= RIDE_time ) // 6 months lock up
                return false ;
                else
                return true;  

            }
        if (user_list[_user].package == 2 ) // FLIGHT
            {
                if ( time >= FLIGHT_time ) // 1 year lock up   
                return false ;
                else
                return true;  
            }

        return false;
    }
     



}