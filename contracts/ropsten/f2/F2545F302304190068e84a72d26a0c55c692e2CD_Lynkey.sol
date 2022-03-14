/**
 *Submitted for verification at Etherscan.io on 2022-03-14
*/

// SPDX-License-Identifier: MIT


// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)
pragma solidity ^0.8.10;

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

pragma solidity ^0.8.10;

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

pragma solidity ^0.8.10;


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



pragma solidity ^0.8.10;
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


pragma solidity ^0.8.10;
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 currentAllowance = allowance(account, _msgSender());
        require(currentAllowance >= amount, "ERC20: burn amount exceeds allowance");
        unchecked {
            _approve(account, _msgSender(), currentAllowance - amount);
        }
        _burn(account, amount);
    }
}

// File: contracts/lynkey.sol
pragma solidity ^0.8.10;


contract Lynkey is ERC20Burnable {
    event event_lockSystemWallet(address _caller, address _wallet, uint256 _amountSum, uint256 _startTime, uint8 _forHowManyPeriods, uint256 _periodInSeconds);
    event event_transferAndLock(address _caller, address _receiver, uint256 _amount, uint256 _releaseTime);
    event event_transfer_by_admin(address _caller, address _receiver, uint256 _amount);
    event event_initCrowdsaleStage(CrowdsaleStage _name, uint256 _startTime, uint256 _endTime, uint _amount);
    event event_lockInvestorWallet(address _receiver, uint256 _amount);
    
    
    address private _owner;

    address ecosystemWallet; 
	address crowdsaleWallet; 
	address stakingRewardWallet;
	address reserveLiquidityWallet;
	address teamWallet;
	address partnerWallet;
	
    // #tokens at at issuance; actual token supply tokenSupply() may be less due to possible future token burning 
	uint256 private totalSupplyAtBirth; 
    
    struct LockItem {
        uint256  releaseTime;
        uint256  amount;
    }
    mapping (address => LockItem[]) public lockList;

    enum CrowdsaleStage { Angel, Private, Pre, IDO}
    struct StageItem {
        CrowdsaleStage stage;
        uint256  startTime;
        uint256  endTime;
        uint  amount;
        uint  totalVestingMonth;
        uint  firstVestingMonth;
        uint  firstVestingPercent;
        uint  lastVestingMonth;
        uint  lastVestingPercent;
    }
    mapping (uint => StageItem) public stageList;
    StageItem public stage;
    uint256 public listingDate = 1651413600;
    
    
    function decimals() public pure override returns (uint8) {
        return 8;
    }
    
	constructor(
	    address _crowdsaleWallet,
	    address _ecosystemWallet,
	    address _stakingRewardWallet,
	    address _reserveLiquidityWallet,
	    address _teamWallet,
	    address _partnerWallet) ERC20("Lynkey", "LYNK") {  

        // all these system addresses will be multi-sig when deploying the contract  
        require(
            _crowdsaleWallet != address(0) && 
            _ecosystemWallet != address(0) &&
            _stakingRewardWallet != address(0) &&
            _reserveLiquidityWallet != address(0) &&
            _teamWallet != address(0) &&
            _partnerWallet != address(0),
            "Wallet address must be valid"
        );

       
        crowdsaleWallet = _crowdsaleWallet;
	    ecosystemWallet = _ecosystemWallet;
	    stakingRewardWallet = _stakingRewardWallet;
	    reserveLiquidityWallet = _reserveLiquidityWallet;
	    teamWallet = _teamWallet;
	    partnerWallet = _partnerWallet;
	        
        _owner = msg.sender;

        totalSupplyAtBirth = 1000000000 * 10 ** uint256(decimals());

        uint256 amountCrowdsale = totalSupplyAtBirth  * 25/100;
        uint256 amountEcosystem = totalSupplyAtBirth  * 20/100;
        uint256 amountReserveLiquidity = totalSupplyAtBirth  * 23/100;
        uint256 amountTeam = totalSupplyAtBirth  * 12/100;
        uint256 amountPartner = totalSupplyAtBirth  * 10/100;
        uint256 amountStakingReward = totalSupplyAtBirth  * 10/100;

        // allocate tokens to the system main wallets according to the Token Allocation
        _mint(crowdsaleWallet, amountCrowdsale); // 25% allocation
        _mint(ecosystemWallet,  amountEcosystem); // 20%
        _mint(reserveLiquidityWallet,  amountReserveLiquidity); // 23%
        _mint(teamWallet,  amountTeam); // 12%
        _mint(partnerWallet,  amountPartner); // 10%
        _mint(stakingRewardWallet,  amountStakingReward); // 10%
        
        uint256 starttime = block.timestamp;
        uint8 numOfPeriods = 12;
        uint256 periodInSeconds = 7884000;

        // releasing linearly quarterly for the next 12 quarterly periods (3 years)
        lockSystemWallet(ecosystemWallet,  amountEcosystem, starttime, numOfPeriods, periodInSeconds); 
        lockSystemWallet(reserveLiquidityWallet, amountReserveLiquidity, starttime, numOfPeriods, periodInSeconds); 
        lockSystemWallet(teamWallet, amountTeam, starttime, numOfPeriods, periodInSeconds); 
        lockSystemWallet(partnerWallet, amountPartner, starttime, numOfPeriods, periodInSeconds); 
        lockSystemWallet(stakingRewardWallet, amountStakingReward, starttime, numOfPeriods, periodInSeconds); 

        //
        initCrowdsaleStage();
    }

    /**
     * @dev allocate tokens and lock to release periodically
     * allocate tokens from owner to system wallets when smart contract is deployed
     */
    function lockSystemWallet(address _wallet, uint256 _amountSum, uint256 _startTime, uint8 _forHowManyPeriods, uint256 _periodInSeconds) private {        
        uint256 amount = _amountSum/_forHowManyPeriods;
        for(uint8 i = 0; i< _forHowManyPeriods; i++) {
            uint256 releaseTime = _startTime + uint256(i)*_periodInSeconds; 
            if (i==_forHowManyPeriods-1) {
                // last month includes all the rest
                amount += (_amountSum - amount * _forHowManyPeriods); // all the rest
            }
    	    lockFund(_wallet, amount, releaseTime);
         }
         emit event_lockSystemWallet(msg.sender, _wallet,  _amountSum,  _startTime,  _forHowManyPeriods,  _periodInSeconds);
    }

    function initCrowdsaleStage() private {        
        StageItem memory item = StageItem({stage:CrowdsaleStage.Angel, startTime:1637848800, endTime:1638637199, amount: 50000000, totalVestingMonth:16, firstVestingMonth: 10, firstVestingPercent: 5, lastVestingMonth:6, lastVestingPercent:800});
        addCrowdStage(item);
        item = StageItem({stage:CrowdsaleStage.Private, startTime:1638712800, endTime:1641315599, amount: 80000000, totalVestingMonth:14, firstVestingMonth: 10, firstVestingPercent: 5, lastVestingMonth:4, lastVestingPercent:1250});
        addCrowdStage(item);
        item = StageItem({stage:CrowdsaleStage.Pre, startTime:1641391200, endTime:1648659599, amount: 100000000, totalVestingMonth:12, firstVestingMonth: 10, firstVestingPercent: 5, lastVestingMonth:2, lastVestingPercent:2500});
        addCrowdStage(item);
        //item = StageItem({stage:CrowdsaleStage.IDO, startTime:1648821600, endTime:1651337999, amount: 20000000, firstVestingMonth: 0, firstVestingPercent: 0, lastVestingMonth:0, lastVestingPercent:0});
        //addCrowdStage(item);
    }

    function addCrowdStage(StageItem memory item) private {
        stageList[uint(item.stage)] = item;         
        emit event_initCrowdsaleStage(item.stage, item.startTime,  item.endTime, item.amount);
    }

    /**
    * @dev Allows admin to update the crowdsale stage
    * @param _stage Crowdsale stage
    */
    function setCrowdsaleStage(uint _stage) public {
        require(msg.sender == _owner, "not owner");
        if(_stage > 0){
            stage = stageList[_stage - 1];
        }else{
            StageItem memory newStage;
            stage = newStage;
        }
    }
	
	/**
     * @dev Returns the address of the current owner.
     */
    function owner() external view returns (address) {
        return _owner;
    }
	
	receive () payable external {   
        revert();
    }
    
    fallback () payable external {   
        revert();
    }
    
    
    /**
     * @dev check if this address is one of the system's reserve wallets
     * @return the bool true if success.
     * @param _addr The address to verify.
     */
    function isAdminWallet(address _addr) private view returns (bool) {
        return (
            _addr == crowdsaleWallet || 
            _addr == ecosystemWallet ||
            _addr == stakingRewardWallet ||
            _addr == reserveLiquidityWallet ||
            _addr == teamWallet ||
            _addr == partnerWallet 
        );
    }


    function lockInvestorWallet(address _wallet, uint256 _amount) private{        
        if (stage.startTime == 0){
            return;
        }
        uint256 idx = 1;
        uint256 totalAmount = 0;
        uint256 amount = 0;
        uint256 timePerMonth = 2628000;
        while (idx <= stage.totalVestingMonth){
            uint256 releaseTime = listingDate + (idx-1)*timePerMonth;
            if (idx <= stage.firstVestingMonth) {
                amount = _amount*stage.firstVestingPercent/10000;
                totalAmount += amount;
            }else if(idx < stage.totalVestingMonth){
                amount = _amount*stage.lastVestingPercent/10000;
                totalAmount += amount;
            }else{
                amount = _amount - totalAmount;
            }
            lockFund(_wallet, amount, releaseTime);
        }
        emit event_lockInvestorWallet(_wallet, _amount);
    }

     /**
     * @dev transfer of token to another address.
     * always require the sender has enough balance
     * @return the bool true if success. 
     * @param _receiver The address to transfer to.
     * @param _amount The amount to be transferred.
     */
     
	function transfer(address _receiver, uint256 _amount) public override returns (bool) {
	    require(_amount > 0, "amount must be larger than 0");
        require(_receiver != address(0), "cannot send to the zero address");
        require(msg.sender != _receiver, "receiver cannot be the same as sender");
	    require(_amount <= getAvailableBalance(msg.sender), "not enough enough fund to transfer");

        if (isAdminWallet(msg.sender)) {
            emit event_transfer_by_admin(msg.sender, _receiver, _amount);
        }

        ERC20.transfer(_receiver, _amount);
        lockInvestorWallet(_receiver, _amount);
        return true;
	}
	
	/**
     * @dev transfer of token on behalf of the owner to another address. 
     * always require the owner has enough balance and the sender is allowed to transfer the given amount
     * @return the bool true if success. 
     * @param _from The address to transfer from.
     * @param _receiver The address to transfer to.
     * @param _amount The amount to be transferred.
     */
    function transferFrom(address _from, address _receiver, uint256 _amount) public override  returns (bool) {
        require(_amount > 0, "amount must be larger than 0");
        require(_receiver != address(0), "cannot send to the zero address");
        require(_from != _receiver, "receiver cannot be the same as sender");
        require(_amount <= getAvailableBalance(_from), "not enough enough fund to transfer");

        ERC20.transferFrom(_from, _receiver, _amount);
        lockInvestorWallet(_receiver, _amount);
        return true;
    }

    /**
     * @dev transfer to a given address a given amount and lock this fund until a given time
     * used by system wallets for sending fund to team members, partners, etc who needs to be locked for certain time
     * @return the bool true if success.
     * @param _receiver The address to transfer to.
     * @param _amount The amount to transfer.
     * @param _releaseTime The date to release token.
     */
	
	function transferAndLock(address _receiver, uint256 _amount, uint256 _releaseTime) external  returns (bool) {
	    require(isAdminWallet(msg.sender), "Only system wallets can have permission to transfer and lock");
	    require(_amount > 0, "amount must be larger than 0");
        require(_receiver != address(0), "cannot send to the zero address");
        require(msg.sender != _receiver, "receiver cannot be the same as sender");
        require(_amount <= getAvailableBalance(msg.sender), "not enough enough fund to transfer");
        
	    ERC20.transfer(_receiver,_amount);
    	lockFund(_receiver, _amount, _releaseTime);
		
        emit event_transferAndLock(msg.sender, _receiver,   _amount,   _releaseTime);

        return true;
	}
	
	
	/**
     * @dev set a lock to free a given amount only to release at given time
     */
	function lockFund(address _addr, uint256 _amount, uint256 _releaseTime) private {
    	LockItem memory item = LockItem({amount:_amount, releaseTime:_releaseTime});
		lockList[_addr].push(item);
	} 
	
	
    /**
     * @return the total amount of locked funds of a given address.
     * @param lockedAddress The address to check.
     */
	function getLockedAmount(address lockedAddress) private view returns(uint256) {
	    uint256 lockedAmount =0;
	    for(uint256 j = 0; j<lockList[lockedAddress].length; j++) {
	        if(block.timestamp < lockList[lockedAddress][j].releaseTime) {
	            uint256 temp = lockList[lockedAddress][j].amount;
	            lockedAmount += temp;
	        }
	    }
	    return lockedAmount;
	}
	
	/**
     * @return the total amount of locked funds of a given address.
     * @param lockedAddress The address to check.
     */
	function getAvailableBalance(address lockedAddress) public view returns(uint256) {
	    uint256 bal = balanceOf(lockedAddress);
	    uint256 locked = getLockedAmount(lockedAddress);
        if (bal <= locked) return 0;
	    return bal-locked;
	}

	    
}