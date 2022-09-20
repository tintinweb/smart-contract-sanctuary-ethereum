/**
 *Submitted for verification at Etherscan.io on 2022-09-20
*/

// SPDX-License-Identifier: MIT
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

// File: 11 - NewPublic.sol





contract Token is ERC20 {
    address internal admin; // Mandatory
    address internal vault; // Mandatory
    bool public paused; // Mandatory
    constructor() ERC20("Joomjoo","Joo") {
        admin = msg.sender;
        vault = msg.sender;
    }

    uint public tokensToReceive; // Mandatory
    uint public oneTokenPriceInWei = 1; // Mandatory
    mapping(address => AllUserContributionsTimestamp) public allPossibleContributions;
    mapping(address => AllClaimable) public hasClaimableTokens;
    mapping(address => AllUserTokensReceived) public allUserTokens;

    struct AllUserContributionsTimestamp {
        uint totalAmountPurchased;
        uint indexPurchaseNo;
        uint[] amountPurchased;
        uint[] timeOfPurchase;
    }
    struct AllClaimable {
        bool hasClaimable ;
        uint numberClaimableTokens;
    }
    struct AllUserTokensReceived {
        uint totalTokens;
        uint indexTokensReceived;
        uint[] tokensSuccesfullyClaimed;
        uint[] timeOfClaims;
    }

    function convertWeiSpentToTokenNo(uint _spent) internal returns(uint) {
        unchecked{tokensToReceive = (_spent / oneTokenPriceInWei)*(10**decimals());} 
        return(tokensToReceive);
    }

    function buy() public payable returns(bool){
        require(paused == false, "pausd");
        payable(vault).transfer(msg.value);
        unchecked{allPossibleContributions[msg.sender].totalAmountPurchased += msg.value;}
        unchecked{allPossibleContributions[msg.sender].indexPurchaseNo += 1;}
        allPossibleContributions[msg.sender].amountPurchased.push(msg.value);
        allPossibleContributions[msg.sender].timeOfPurchase.push(block.timestamp);
        hasClaimableTokens[msg.sender].hasClaimable = true;
        unchecked{hasClaimableTokens[msg.sender].numberClaimableTokens += convertWeiSpentToTokenNo(msg.value);}
        return true;
    }
    
    function claim() public returns(bool){
        require(paused == false, "paused");
        require(hasClaimableTokens[msg.sender].hasClaimable == true, "No claimables");
        _mint(msg.sender, hasClaimableTokens[msg.sender].numberClaimableTokens);    
        unchecked{allUserTokens[msg.sender].totalTokens += hasClaimableTokens[msg.sender].numberClaimableTokens;}
        unchecked{allUserTokens[msg.sender].indexTokensReceived += 1;}
        allUserTokens[msg.sender].tokensSuccesfullyClaimed.push(hasClaimableTokens[msg.sender].numberClaimableTokens);
        hasClaimableTokens[msg.sender].hasClaimable = false;
        hasClaimableTokens[msg.sender].numberClaimableTokens = 0;
        allUserTokens[msg.sender].timeOfClaims.push(block.timestamp);
        return true;
    }

    uint public stakeFeePriceInWei = 10;
    uint public unstakeFeePriceInWei = 10;
    uint256 public constant BASE_EPOCH_DURATION = 30;
    uint256 public constant BASE_FINAL_REWARD = 5;

    mapping(address => AllUserStakedTimestamp) internal allUserStakes;

    struct AllUserStakedTimestamp {
        uint _numberOfStakes;
        bool[] _wasUnstaked;
        bool[] _autoRenewal;
        uint[] _amountStaked;
        uint[] _timeOfStake;
        uint[] _timesOfRelease;
        uint[] _optionReleaseSelected; // 0-1-2
        uint[] _epochDuration;
        uint[] _rewardPerCycle;
        uint[] _finalStakeReward;
    }

    modifier allowedUserReleaseTimeSelectionRange(uint _userReleaseTimeSelection) {
        require(
        _userReleaseTimeSelection == 0 ||
        _userReleaseTimeSelection == 1 ||
        _userReleaseTimeSelection == 2, "only 0|1|2");
        _;
    }

    modifier ableToStake(uint256 _tokens) {
        require(paused == false, "paused");
        require(balanceOf(msg.sender) > 0, "no stakebles");
        require(_tokens <= balanceOf(msg.sender));
        _;
    }
    
    function giveMeNewTime(uint secondsAfter) public view returns(uint) {
        uint timeStampWanted = block.timestamp + (secondsAfter * 1 seconds);
        return(timeStampWanted);        
    }
    
    function stake(uint _tokens, uint _userReleaseTimeSelection, bool _autoRenewal)
        public
        payable
        allowedUserReleaseTimeSelectionRange(_userReleaseTimeSelection)
        ableToStake(_tokens)
        returns(bool) {
        payable(vault).transfer(stakeFeePriceInWei);
        uint256 epochDuration = BASE_EPOCH_DURATION * (_userReleaseTimeSelection + 1);
        uint256 finalChoice = giveMeNewTime(epochDuration);
        uint256 finalReward = BASE_FINAL_REWARD * (_userReleaseTimeSelection + 1);
        AllUserStakedTimestamp storage allUserStakedTimestamp = allUserStakes[msg.sender];
        allUserStakedTimestamp._wasUnstaked.push(false);
        allUserStakedTimestamp._autoRenewal.push(_autoRenewal);
        allUserStakedTimestamp._amountStaked.push(_tokens);
        allUserStakedTimestamp._timeOfStake.push(block.timestamp);
        allUserStakedTimestamp._timesOfRelease.push(finalChoice);
        allUserStakedTimestamp._optionReleaseSelected.push(_userReleaseTimeSelection);
        allUserStakedTimestamp._epochDuration.push(epochDuration);
        allUserStakedTimestamp._rewardPerCycle.push(finalReward);
        allUserStakedTimestamp._finalStakeReward.push(finalReward);
        allUserStakedTimestamp._numberOfStakes +=1;
        _burn(msg.sender, _tokens);
        return true;
    }
    
    function checkHowManyStakes(address _addr) public view returns(uint) {
        return allUserStakes[_addr]._numberOfStakes;
    }

    function checkStakeByIndex(address _addr, uint _stakeIndexNo) public view returns(
        string memory,                                                          // - 0 legend below:
        bool,                                                                   // - 1 WU  - was unstaked
        bool,                                                                   // - 2 AR  - automatic renewal
        uint,                                                                   // - 3 AS  - amount staked
        uint,                                                                   // - 4 TOS - time of stake
        uint                                                                    // - 5 TOR - time of release                                                                    // - 7 ED - epoch duration
        ){return(
        "1 - WU | 2 - AR | 3 - AS | 4 - TOS | 5 - TOR :",                       // - 0 legend below:
        allUserStakes[_addr]._wasUnstaked[_stakeIndexNo],                       // - 1 WU  - was unstaked
        allUserStakes[_addr]._autoRenewal[_stakeIndexNo],                       // - 2 AR  - automatic renewal
        allUserStakes[_addr]._amountStaked[_stakeIndexNo],                      // - 3 AS  - amount staked
        allUserStakes[_addr]._timeOfStake[_stakeIndexNo],                       // - 4 TOS - time of stake
        allUserStakes[_addr]._timesOfRelease[_stakeIndexNo]);                   // - 5 TOR - time of release                 
        }

    function checkStakeRewardByIndex(address _addr, uint _stakeIndexNo) public view returns(
        string memory,                                                          // - 0 legend below:
        uint,                                                                   // - 1 ORS - option release selected
        uint,                                                                   // - 2 ED  - epoch duration
        uint,                                                                   // - 3 RPC  - reward per cycle
        uint                                                                    // - 4 FSR - final stake reward
        ){return(
        "1 - ORS | 2 - ED | 3 - RPC | 4 - FSR :",                               // - 0 legend below:
        allUserStakes[_addr]._optionReleaseSelected[_stakeIndexNo],             // - 1 ORS - option release selected
        allUserStakes[_addr]._epochDuration[_stakeIndexNo],                     // - 2 ED  - epoch duration
        allUserStakes[_addr]._rewardPerCycle[_stakeIndexNo],                    // - 3 RPC  - reward per cycle
        allUserStakes[_addr]._finalStakeReward[_stakeIndexNo]);                 // - 4 FSR - final stake reward
        }

    function whatTimeIsIt() public view returns(int, int, int) {
        int release = int(allUserStakes[msg.sender]._timesOfRelease[0]);
        int timeNow = int(block.timestamp);
        int wait = release - timeNow;
        return (release, timeNow, wait);
    }

    function requestUnstake(uint _stakeIndexNo) internal returns(bool, uint) {
        require(paused == false, "paused"); 
        AllUserStakedTimestamp storage allUserStakedTimestamp = allUserStakes[msg.sender];
        uint[4] memory prm = [
            allUserStakedTimestamp._epochDuration[_stakeIndexNo], 
            allUserStakedTimestamp._timeOfStake[_stakeIndexNo],  
            allUserStakedTimestamp._timesOfRelease[_stakeIndexNo],
            allUserStakedTimestamp._rewardPerCycle[_stakeIndexNo] 
        ];
        bool autoReNew = allUserStakedTimestamp._autoRenewal[_stakeIndexNo]; 
        uint timeAtRequest = block.timestamp; 
        uint timeElapsed = timeAtRequest - prm[1]; 
        uint rewardCycles = timeElapsed / prm[0]; 
        uint currentCycleTimeElapsed = timeElapsed - (rewardCycles * prm[0]); 
        uint timeTillNextCycle = prm[0] - currentCycleTimeElapsed; 

        if(((autoReNew == false) && (prm[2] <= timeAtRequest))){
            return (true, allUserStakedTimestamp._finalStakeReward[_stakeIndexNo]) ;} 

        else if(((timeAtRequest - prm[2]) == (((timeAtRequest - prm[2]) / prm[0]) * prm[0])))
        {allUserStakedTimestamp._finalStakeReward[_stakeIndexNo] = rewardCycles * prm[3]; 
        return (true, allUserStakedTimestamp._finalStakeReward[_stakeIndexNo]);} 
        
        else {uint newTimeOfRelease = giveMeNewTime(timeTillNextCycle);
        allUserStakedTimestamp._timesOfRelease[_stakeIndexNo] = newTimeOfRelease;
        allUserStakedTimestamp._autoRenewal[_stakeIndexNo] = false;
        allUserStakedTimestamp._finalStakeReward[_stakeIndexNo] = (rewardCycles + 1) * prm[3]; 
        return (false, allUserStakedTimestamp._finalStakeReward[_stakeIndexNo]);} 
    }

    modifier ableToUnstake(uint256 _stakeIndexNo) {
        AllUserStakedTimestamp storage allUserStakedTimestamp = allUserStakes[msg.sender];
        require(paused == false, "paused");
        require(_stakeIndexNo <= allUserStakedTimestamp._wasUnstaked.length, "out of range");
        require(allUserStakedTimestamp._wasUnstaked[_stakeIndexNo] == false, "already unstaked");
        require(allUserStakedTimestamp._timesOfRelease[_stakeIndexNo] <= block.timestamp, "not yet");
        require(allUserStakedTimestamp._amountStaked[_stakeIndexNo] > 0, "no unstkables");
        _;
    }

    function unstake(uint _stakeIndexNo) public payable ableToUnstake(_stakeIndexNo) returns(bool _unstaked, string memory _msg, uint _time){
        AllUserStakedTimestamp storage allUserStakedTimestamp = allUserStakes[msg.sender];
        (bool b,) = requestUnstake(_stakeIndexNo);
        
        if(b == true){
            uint _tokens = allUserStakedTimestamp._amountStaked[_stakeIndexNo];
            uint reward = allUserStakedTimestamp._finalStakeReward[_stakeIndexNo];
            uint initialTokensPlusRewardOwed = _tokens + reward;
            _mint(msg.sender, initialTokensPlusRewardOwed);
            payable(vault).transfer(unstakeFeePriceInWei);
            allUserStakedTimestamp._wasUnstaked[_stakeIndexNo] = true;
            return (true, "unstkd at:", block.timestamp);
            }

        else if (b == false){
            return (false,"Req-Submted, come back at:", allUserStakedTimestamp._timesOfRelease[_stakeIndexNo]) ;
        }
    }

    uint private gCount;     
    mapping(uint => g) internal _gByIdx;
    
    struct g {
        string gName;
        bool gActive;
        bool gStarted;
        bool gClose;
        bool postable;
        bool _resA;
        bool _resB;
        bool _resC;
        uint gTime;
    }

    modifier admAct() {
        require(paused == false, "paused");
        require(admin == msg.sender, "u not adm!");
        _;
    }
 
    function creatG(string memory _gName) public admAct() returns(uint, string memory, bool, uint){
        _gByIdx[gCount].gName = _gName;
        _gByIdx[gCount].gTime = block.timestamp;
        gCount++;
        return((gCount-1), _gName, _gByIdx[gCount].gActive, block.timestamp);
    }

    function checkRes(uint _gIdx) public view returns(uint, string memory, bool, bool, bool, bool, uint) {
        require(_gIdx <= gCount -1, "out-range");
        return (_gIdx, _gByIdx[_gIdx].gName, _gByIdx[_gIdx].gActive, _gByIdx[_gIdx]._resA,
        _gByIdx[_gIdx]._resB, _gByIdx[_gIdx]._resC, block.timestamp);
    }

    function startG(uint _gIdx) public admAct() returns(bool) {
        require(_gByIdx[_gIdx].gStarted == false, "G alrdy startd");
        _gByIdx[_gIdx].gActive = true;
        _gByIdx[_gIdx].gStarted = true;
        return true;
    }

    function closeG(uint _gIdx) public admAct() returns(bool) {
        _gByIdx[_gIdx].gActive = false;
        _gByIdx[_gIdx].postable = true;
        return true;
    }

    function postRes(uint _gIdx, uint _res) public admAct() returns(uint, string memory, bool, bool, bool, bool,uint) { 
        require(_gByIdx[_gIdx].postable == true, "still-active or not-startd");
        require(_res == 1 || _res == 2 || _res == 3,"only 1,2 or 3");
        if (_res == 1) {_gByIdx[_gIdx]._resA = true;}
        else if (_res == 2) {_gByIdx[_gIdx]._resB = true;}
        else if (_res == 3) {_gByIdx[_gIdx]._resB = true;}
        else {revert("only1,2,3");}
        _gByIdx[_gIdx].gActive = false;
        _gByIdx[_gIdx].gClose = true;
        return (
            _gIdx,
            _gByIdx[_gIdx].gName, 
            _gByIdx[_gIdx].gActive, 
            _gByIdx[_gIdx]._resA,
            _gByIdx[_gIdx]._resB, 
            _gByIdx[_gIdx]._resC, 
            block.timestamp
            );
    }

    mapping (address => mapping(uint => bet)) internal bets;
    mapping (uint => totWaged) internal waged;

    struct bet {
        uint _bet;
        uint _gIdx;
        bool _winA;
        bool _winB;
        bool _winC;
    }

    struct totWaged {
        uint _totWaged;
        uint _totA;
        uint _totB;
        uint _totC;
        uint _toDistrib;
    }

    function betOn(uint _bet, uint _gIdx, uint _win) public returns (bool) { 
        bets[msg.sender][_gIdx]._bet += _bet;
        bets[msg.sender][_gIdx]._gIdx = _gIdx;
        _burn(msg.sender, _bet);
        if (_win == 1) {bets[msg.sender][_gIdx]._winA = true;}
        else if (_win == 2) {bets[msg.sender][_gIdx]._winB = true;}
        else if (_win == 3) {bets[msg.sender][_gIdx]._winC = true;}
        else {revert("only1,2,3");}
        waged[_gIdx]._totWaged += _bet;
        if (_win == 1) {waged[_gIdx]._totA += _bet;}
        else if (_win == 2) {waged[_gIdx]._totB += _bet;}
        else if (_win == 3) {waged[_gIdx]._totC += _bet;}
        return true;    
    }

    function checkIfWon(uint _gIdx) internal view returns(bool){
        if (bets[msg.sender][_gIdx]._winA == _gByIdx[_gIdx]._resA &&
        bets[msg.sender][_gIdx]._winB == _gByIdx[_gIdx]._resB &&
        bets[msg.sender][_gIdx]._winC == _gByIdx[_gIdx]._resC) 
        {return true;}
        else {return false;}
    }

    function gStats(uint _gIdx) internal view returns(uint){
        uint _losTotAmt;
        uint _winTotAmt;
        uint _distrLos;
        if (_gByIdx[_gIdx]._resA == true) {_winTotAmt += waged[_gIdx]._totA;}           
        else if (_gByIdx[_gIdx]._resB == true) {_winTotAmt += waged[_gIdx]._totB;}      
        else if (_gByIdx[_gIdx]._resC == true) {_winTotAmt += waged[_gIdx]._totC;}      
        else {revert("No valide results found!!!");}                                        
        _losTotAmt = waged[_gIdx]._totWaged - _winTotAmt;
        if (_losTotAmt == 0 || _winTotAmt == 0) {
            _distrLos = 0;
            return _distrLos;}
        else {
            _distrLos = (_losTotAmt*10**decimals()) / _winTotAmt;
            return _distrLos;} 
    }

    function cashOut(uint _gIdx) public returns (bool) {
        require(bets[msg.sender][_gIdx]._bet > 0 ,"u-no-bet");
        require(checkIfWon(_gIdx) == true, "u-lost");
        uint winnings = (gStats(_gIdx) * bets[msg.sender][_gIdx]._bet) / (10**decimals());
        uint toCashOut = winnings +  bets[msg.sender][_gIdx]._bet; 
        _mint(msg.sender, toCashOut);
        // Missing our fee as the house
        return true;
    }

}