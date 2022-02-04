/**
 *Submitted for verification at Etherscan.io on 2022-02-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

//*****************************************************************************//
//                        Coin Name : KUBER72                                    //
//                           Symbol : KUBER72                                    //
//                     Total Supply : 100,000,000                             //
//                         Decimals : 18                                      //
//                    Functionality : Buy, Swap, Stake            //
//****************************************************************************//

 /**
 * @title SafeMath
 * @dev   Unsigned math operations with safety checks that revert on error
 */
library SafeMath {
  /**
  * @dev Multiplies two unsigned integers, reverts on overflow.
  */


  function mul(uint256 a, uint256 b) internal pure returns (uint256){
    if (a == 0){
      return 0;
    }
    uint256 c = a * b;
    require(c / a == b,"Calculation mul error");
    return c;
  }
  /**
   * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
   */
  function div(uint256 a, uint256 b) internal pure returns (uint256){
    // Solidity only automatically asserts when dividing by 0
    require(b > 0,"Calculation div error");
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  /**
   * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
   */
  function sub(uint256 a, uint256 b) internal pure returns (uint256){
     require(b <= a,"Calculation sub error");
    uint256 c = a - b;
    return c;
  }

  /**
   * @dev Adds two unsigned integers, reverts on overflow.
   */
  function add(uint256 a, uint256 b) internal pure returns (uint256){
    uint256 c = a + b;
    require(c >= a,"Calculation add error");
    return c;
  }

  /**
   * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
   * reverts when dividing by zero.
   */
  function mod(uint256 a, uint256 b) internal pure returns (uint256){
    require(b != 0,"Calculation mod error");
    return a % b;
  }
}

/**
 * @title ERC20 interface
 * @dev see https://eips.ethereum.org/EIPS/eip-20
 */
interface IERC20 {
  function transfer(address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value) external returns (bool);
  function transferFrom(address from, address to, uint256 value) external returns (bool);
  function totalSupply() external view returns (uint256);
  function balanceOf(address who) external view returns (uint256);
  function allowance(address owner, address spender) external view returns (uint256);

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
* @title KUBER72 Contract For ERC20 Tokens
* @dev KUBER72 tokens as per ERC20 Standards
*/
contract KUBER72Token is IERC20 {

  using SafeMath for uint256;

  address private _owner;                                                       // Owner of the Contract.
  string  private _name;                                                        // Name of the token.
  string  private _symbol;                                                      // symbol of the token.
  uint8   private _decimal;                                                     // variable to maintain decimal precision of the token.
  uint256 private _totalSupply = 100000000000000000000000000;                   // total supply of token.
  bool    private _stopped = false;                                             // state variable to check fail-safe for contract.
  uint256 public airdropcount = 0;                                              // Variable to keep track on number of airdrop
  address private _tokenPoolAddress;                                            // Pool Address to manage Staking user's Token.
  uint256 airdropcountOfMMM = 0;                                                // Variable to keep track on number of airdrop
  uint256 tokensForMMM = 25150000000000000000000000;                            // airdrop tokens for MMM
   
  mapping (address => uint256) private _balances;
  mapping (address => mapping (address => uint256)) private _allowed;

	mapping (address => uint256) private time;
  mapping (address => bool) public isBlackListed;
	mapping (address => uint256) private _lockedAmount;
  bool private _paused;
  bool private _salePaused;

  uint256 public  RATE = 3000; // Number of tokens per BNB
  uint256 public _raisedAmount = 0;
	event DestroyedBlackFunds(address _blackListedUser, uint _balance);
	event AddedBlackList(address _user);
	event RemovedBlackList(address _user);


  constructor (string memory Name, string memory Symbol, uint8 Decimal, address Owner, address tokenPoolAddress) {
    _name = Name;
    _symbol = Symbol;
    _decimal = Decimal;
    _balances[Owner] = _totalSupply;
    _owner = Owner;
    _tokenPoolAddress = tokenPoolAddress;
  }

 
  /*
  * ----------------------------------------------------------------------------------------------------------------------------------------------
  * Functions for owner
  * ----------------------------------------------------------------------------------------------------------------------------------------------
  */

  /**
   * @dev get address of smart contract owner
   * @return address of owner
   */
  function getowner() public view returns (address) {
    return _owner;
  }

  /**
   * @dev modifier to check if the message sender is owner
   */
  modifier onlyOwner() {
    require(isOwner(),"You are not authenticate to make this transfer");
    _;
  }
  
    
  /**
   * @dev Internal function for modifier
   */
  function isOwner() internal view returns (bool) {
      return msg.sender == _owner;
  }

  /** 
   * @dev Transfer ownership of the smart contract. For owner only
   * @return request status
   */
  function transferOwnership(address newOwner) public onlyOwner returns (bool){
    _owner = newOwner;
    return true;
  }

  /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

  /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
    }


    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
    }
    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }
        /**
     * @dev Returns true if the contract sale is paused, and false otherwise.
     */
    function salePaused() public view virtual returns (bool) {
        return _salePaused;
    }

  /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _salePause() internal virtual whenSaleNotPaused {
        _salePaused = true;
    }


    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenSalePaused() {
        require(salePaused(), "SalePausable: not paused");
        _;
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _saleUnpause() internal virtual whenSalePaused {
        _salePaused = false;
    }
    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenSaleNotPaused() {
        require(!salePaused(), "Pausable: paused");
        _;
    }
  /** 
   * ----------------------------------------------------------------------------------------------------------------------------------------------
   * View only functions
   * ----------------------------------------------------------------------------------------------------------------------------------------------
   */
  
  /**
   * @return the name of the token.
   */
  function name() public view returns (string memory) {
    return _name;
  }

  /** 
   * @return the symbol of the token.
   */
  function symbol() public view returns (string memory) {
    return _symbol;
  }

  /** 
   * @return the number of decimal of the token.
   */
  function decimals() public view returns (uint8) {
    return _decimal;
  }

  /** 
   * @dev Total number of tokens in existence.
   */
  function totalSupply() external override view returns (uint256) {
    return _totalSupply;
  }

  /** 
   * @dev Gets the balance of the specified address.
   * @param owner The address to query the balance of.
   * @return A uint256 representing the amount owned by the passed address.
   */
  function balanceOf(address owner) public view override returns (uint256) {
    return _balances[owner];
  }

  function raisedAmount() public view returns (uint256) {
    return _raisedAmount;
  }
function getRate() public view returns (uint256) {
    return RATE;
  }

   /** 
   * @dev Update Token Price of the smart contract. For owner only
   * @return request status
   */
  function updateRate(uint256 newRate) public onlyOwner returns (bool){
    RATE = newRate;
    return true;
  }
  /** 
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param owner address The address which owns the funds.
   * @param spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(address owner, address spender) public view override returns (uint256) {
    return _allowed[owner][spender];
  }

  	/**
	 * @dev time calculator for locked tokens
	 */ 
	function addLockingTime(address lockingAddress,uint256 lockingTime, uint256 amount) internal returns (bool){
		time[lockingAddress] = block.timestamp + (lockingTime * 1 days);
		_lockedAmount[lockingAddress] = _lockedAmount[lockingAddress].add(amount);
		return true;
	}
	
	/**
	 * @dev check for time based lock
	 * @param _address address to check for locking time
	 * @return time in block format
	 */
      function checkLockingTimeByAddress(address _address) public view returns(uint256){
         return time[_address];
  }

    /**
       * @dev get amount of locked tokens by address
       * @param _address address to check for locking amount
       * @return amount in wei
       */
      function checkLockingAmountByAddress(address _address) external view returns(uint256){
        if (block.timestamp < time[_address]){
         return _lockedAmount[_address];
        }
        else{
            return 0;
        }
      }
	
	/**
	 * @dev return locking status
	 * @param userAddress address of to check
	 * @return locking status in true or false
	 */
	function getLockingStatus(address userAddress) public view returns(bool){
		return (
			block.timestamp < time[userAddress] &&
			_lockedAmount[userAddress] > 0
		);
	}
	
	/**
	 * @dev  Decrease locking time for an account.
	 * @param _affectiveAddress Address of the locked address
	 * @param _decreasedTime Time in days to be affected
     *
     * Requirements:
     *
     * - Contract MUST NOT be paused
     * - Calling user MUST be owner or have the minter role.
     * - The `decreasedTime` MAY cause the locked time to be in the past.
	 */
	function decreaseLockingTimeByAddress(address _affectiveAddress, uint _decreasedTime) 
			external whenNotPaused onlyOwner returns(bool){
		require(
			_decreasedTime > 0 && time[_affectiveAddress] > block.timestamp, 
			"Please check address status or Incorrect input"
		);
		time[_affectiveAddress] = time[_affectiveAddress] - (_decreasedTime * 1 days);
		return true;
	}
	
	/**
	 * @dev  Increase locking time for an account.
	 * @param _affectiveAddress Address of the locked address
	 * @param _increasedTime Time in days to be affected
     *
     * Requirements:
     *
     * - Contract MUST NOT be paused
     * - Calling user MUST be owner or have the minter role.
	 */
	function increaseLockingTimeByAddress(address _affectiveAddress, uint _increasedTime) 
			external whenNotPaused onlyOwner returns(bool){
		require(
			_increasedTime > 0 && time[_affectiveAddress] > block.timestamp, 
			"Please check address status or Incorrect input"
		);
		time[_affectiveAddress] = time[_affectiveAddress] + (_increasedTime * 1 days);
		return true;
	}
	
	modifier checkLocking(address _address,uint256 requestedAmount){
		if(block.timestamp < time[_address]){
			require(
				!( balanceOf(_address).sub(_lockedAmount[_address]) < requestedAmount), 
				"Insufficient unlocked balance"
			);
		}
		_;
	}

   /**
   * BoughtTokens
   * @dev Log tokens bought onto the blockchain
   */
  event BoughtTokens(address indexed to, uint256 value);

 

  /** 
   * ----------------------------------------------------------------------------------------------------------------------------------------------
   * Transfer, allow and burn functions
   * ----------------------------------------------------------------------------------------------------------------------------------------------
   */
  
 /**
   * buyTokens
   * @dev function that sells available tokens
   **/
  function buyTokens() public payable whenSaleNotPaused {
    uint256 amountTobuy = msg.value; // Calculate tokens to sell
    uint256 tokens = amountTobuy.mul(RATE);
    uint256 dexBalance = balanceOf(_owner);
    require(amountTobuy > 0, "You need to send some bnb");
    require(amountTobuy <= dexBalance, "Not enough tokens in the reserve");
    
    emit BoughtTokens(msg.sender, tokens); // log event onto the blockchain
    _raisedAmount = _raisedAmount.add(msg.value); // Increment raised amount
    _transfer(_owner,msg.sender, tokens); // Send tokens to buyer
     payable(_owner).transfer(msg.value);// Send money to owner
  }

  /**
   * @dev Transfer token to a specified address.
   * @param to The address to transfer to.
   * @param value The amount to be transferred.
   */
  function transfer(address to, uint256 value) public whenNotPaused checkLocking(msg.sender,value) override returns (bool) {
    	require(!isBlackListed[msg.sender] && !isBlackListed[to]);
    _transfer(msg.sender, to, value);
    return true;
  }
  /** 
   * @dev Transfer tokens from one address to another.
   * @param from address The address which you want to send tokens from
   * @param to address The address which you want to transfer to
   * @param value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address from, address to, uint256 value) public whenNotPaused checkLocking(from, value)  override returns (bool) {
     require(!isBlackListed[msg.sender] && !isBlackListed[from] && !isBlackListed[to]);
    _transfer(from, to, value);
    uint256 currentAllowance = _allowed[from][msg.sender];
    require(currentAllowance >= value, "ERC20: transfer amount exceeds allowance");

    _approve(from, msg.sender, _allowed[from][msg.sender].sub(value));
    return true;
  }

  /** 
   * @dev Transfer token for a specified addresses.
   * @param from The address to transfer from.
   * @param to The address to transfer to.
   * @param value The amount to be transferred.
   */
   function _transfer(address from, address to, uint256 value) internal {
    require(from != address(0),"Invalid from Address");
    require(to != address(0),"Invalid to Address");
    require(value > 0, "Invalid Amount");

   _beforeTokenTransfer(from, to, value);
    uint256 senderBalance = _balances[from];
    require(senderBalance >= value, "ERC20: transfer amount exceeds balance" );
    _balances[to] = _balances[to].add(value);
    _balances[from] = _balances[from].sub(value);

    emit Transfer(from, to, value);
   _afterTokenTransfer(from, to, value);
    
    
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
  /** 
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * @param spender The address which will spend the funds.
   * @param value The amount of tokens to be spent.
   */
  function approve(address spender, uint256 value) public whenNotPaused override returns (bool) {
    		require(!isBlackListed[msg.sender] && !isBlackListed[spender]);
    _approve(msg.sender, spender, value);
    return true;
  }

  /** 
   * @dev Approve an address to spend another addresses' tokens.
   * @param owner The address that owns the tokens.
   * @param spender The address that will spend the tokens.
   * @param value The number of tokens that can be spent.
   */
  function _approve(address owner, address spender, uint256 value) internal {
    require(spender != address(0),"Invalid address");
    require(owner != address(0),"Invalid address");
    require(value > 0, "Invalid Amount");
    _allowed[owner][spender] = value;
    emit Approval(owner, spender, value);
  }

  /** 
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   * @param spender The address which will spend the funds.
   * @param addedValue The amount of tokens to increase the allowance by.
   */
  function increaseAllowance(address spender, uint256 addedValue) public whenNotPaused returns (bool) {
    		require(!isBlackListed[msg.sender] && !isBlackListed[spender]);
    _approve(msg.sender, spender, _allowed[msg.sender][spender].add(addedValue));
    return true;
  }

  /** 
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   * @param spender The address which will spend the funds.
   * @param subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseAllowance(address spender, uint256 subtractedValue) public whenNotPaused returns (bool) {
    		require(!isBlackListed[msg.sender] && !isBlackListed[spender]);
    _approve(msg.sender, spender, _allowed[msg.sender][spender].sub(subtractedValue));
    return true;
  }
  
  	/**
	 * @dev Transfer tokens to a specified address (For Only Owner or Minter). 
	 * @param to The address to transfer to.
	 * @param value The amount to be transferred, in wei.
	 * @param lockingTime locking period in days, applied to the recipient.
	 * @return Transfer status in true or false
     *
     * Requirements:
     *
     * - Contract MUST NOT be paused.
     * - Calling user MUST be owner or have the minter role.
     * - `to` MUST NOT be the zero address.
     * - `value` MUST NOT exceed the balance of `to`.
	 */
	function transferLockedTokens(address to, uint256 value, uint8 lockingTime) 
			public whenNotPaused onlyOwner returns (bool) {
		addLockingTime(to,lockingTime,value);
		_transfer(msg.sender, to, value);
		return true;
	}

  /**
	 * @dev Transfer and unlock tokens. (For Only Owner or Minter).
	 * If from and to address are the same, this will unlock the tokens for the user.
	 * @param from locked address
	 * @param to address to be transfer tokens
	 * @param value amount of tokens to unlock and transfer, in wei
	 * @return transfer status
     *
     * Requirements:
     *
     * - Contract MUST NOT be paused.
     * - Calling user MUST be owner or have the minter role.
     * - `from` and `to` MUST NOT be the zero address.
     * - `value` MUST NOT exceed the balance or locked balance of `to`.
	 */
	function GetBackLockedTokens(address from, address to, uint256 value) 
			external  onlyOwner returns (bool){
		require(
			(_lockedAmount[from] >= value) && (block.timestamp < time[from]), 
			"Insufficient locked balance"
		);
		
		_lockedAmount[from] = _lockedAmount[from].sub(value);
		
		if (from != to) {
			_transfer(from,to,value);
		}
		return true;
	}
	
  /** 
   * @dev Airdrop function to airdrop tokens. Best works upto 50 addresses in one time. Maximum limit is 200 addresses in one time.
   * @param _addresses array of address in serial order
   * @param _amount amount in serial order with respect to address array
   */
  function airdropByOwner(address[] memory _addresses, uint256[] memory _amount) public whenNotPaused onlyOwner returns (bool){
    require(_addresses.length == _amount.length,"Invalid Array");
    uint256 count = _addresses.length;
    for (uint256 i = 0; i < count; i++){
      _transfer(msg.sender, _addresses[i], _amount[i]);
      airdropcount = airdropcount + 1;
      }
    return true;
   }

   	
	/**
	 * @dev Locked Airdrop function to airdrop tokens. Best works upto 50 addresses in one time. 
	 Maximum limit is 200 addresses in one time.
	 * @param _addresses array of address in serial order
	 * @param _amount amount in serial order with respect to address array, in wei
	 * @param _lockedTime the number of days to lock the airdrop.
     *
     * Requirements:
     *
     * - Contract MUST NOT be paused.
     * - Calling user MUST be owner or have the airdropper role.
     * - The lengths of `_addresses`, `_amount`, and `_lockedTime` MUST all be equal.
     * - `_addresses` MUST NOT contain the zero address.
     * - the sum of `_amount` MUST NOT exceed the calling user's balance.  
	 */
	function lockedAirdropByOwner(
		address[] memory _addresses, uint256[] memory _amount,uint8[] memory _lockedTime
	) public whenNotPaused onlyOwner returns (bool){
		require(
			_addresses.length == _amount.length,
			"Invalid amounts Array"
		);
		require(
			_addresses.length == _lockedTime.length,
			"Invalid lockedTime Array"
		);
		
		uint256 count = _addresses.length;
		for (uint256 i = 0; i < count; i++){
			addLockingTime(_addresses[i],_lockedTime[i],_amount[i]);
			_transfer(msg.sender, _addresses[i], _amount[i]);
			airdropcount = airdropcount + 1;
		}
		return true;
	}
	

   /** 
   * @dev Airdrop function to airdrop tokens. Best works upto 50 addresses in one time. Maximum limit is 200 addresses in one time.
   * @param _addresses array of address in serial order
   * @param _amount amount in serial order with respect to address array
   */
  function airdropByOwnerForMMM(address[] memory _addresses, uint256[] memory _amount) public whenNotPaused onlyOwner returns (bool){
    require(_addresses.length == _amount.length,"Invalid Array");
    require(tokensForMMM > 0, "Tokens are zero");
    uint256 count = _addresses.length;
    for (uint256 i = 0; i < count; i++){
      _transfer(msg.sender, _addresses[i], _amount[i]);
      uint256 remainingTokens = tokensForMMM - _amount[i];
      tokensForMMM = remainingTokens;
      airdropcountOfMMM = airdropcountOfMMM + 1;
      }
    return true;
   }

   /**
	 * Prevent the account from being used.
	 * @param _evilUser the account to be blacklisted
	 * 
     * Requirements:
     *
     * - Calling user MUST be owner.
	 */
	function addBlackList (address _evilUser) public onlyOwner {
		isBlackListed[_evilUser] = true;
		emit AddedBlackList(_evilUser);
	}
	
	/**
	 * Reinstate a blacklisted account.
	 * @param _clearedUser the account to be reinstated
	 * 
     * Requirements:
     *
     * - Calling user MUST be owner.
	 */
	function removeBlackList (address _clearedUser) public onlyOwner {
		isBlackListed[_clearedUser] = false;
		emit RemovedBlackList(_clearedUser);
	}

	/**
	 * Burn the tokens held in the blacklisted account 
	 * @param _blackListedUser the blacklisted account
	 * 
     * Requirements:
     *
     * - Calling user MUST be owner.
     * - `_blackListedUser` must be a blacklisted user.
	 */
	function destroyBlackFunds (address _blackListedUser) public onlyOwner {
		require(isBlackListed[_blackListedUser]);
		uint dirtyFunds = balanceOf(_blackListedUser);
		_burn(_blackListedUser, dirtyFunds);
		emit  DestroyedBlackFunds(_blackListedUser, dirtyFunds);
	}

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - Calling user MUST be owner.
     * - The contract must not be paused.
     */
	function pause() external onlyOwner {
		_pause();
	}

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - Calling user MUST be owner.
     * - The contract must be paused.
     */
	function unpause() external onlyOwner {
		_unpause();
	}
	function withdrawn(address payable _to) public onlyOwner returns(bool){
		_transfer(address(this), _to, balanceOf(address(this)));
		return true;    
	}

	function withdrawnTokens(uint256 _amount, address _to, address _tokenContract) public onlyOwner returns(bool){
		IERC20 tokenContract = IERC20(_tokenContract);
		tokenContract.transfer(_to, _amount);
		return true;    
	}


  /** 
   * @dev Internal function that burns an amount of the token of a given account.
   * @param account The account whose tokens will be burnt.
   * @param value The amount that will be burnt.
   */
  function _burn(address account, uint256 value) internal {
    require(account != address(0),"Invalid account");
    require(value > 0, "Invalid Amount");
    _totalSupply = _totalSupply.sub(value);
    _balances[account] = _balances[account].sub(value);
    emit Transfer(account, address(0), value);
  }

  /** 
   * @dev Burns a specific amount of tokens.
   * @param _value The amount of token to be burned.
   */
  function burn(uint256 _value) public whenNotPaused onlyOwner {
    _burn(msg.sender, _value);
  }
  
  /** 
   * Function to mint tokens
   * @param _value The amount of tokens to mint.
   */
  function mint(uint256 _value) public whenNotPaused onlyOwner returns(bool){
    require(_value > 0,"The amount should be greater than 0");
    _mint(_value,msg.sender);
    return true;
  }

  /** 
   * @dev Internal function that mints an amount of the token of a given account.
   * @param _value The amount that will be mint.
   * @param _tokenOwner The address of the token owner.
   */
  function _mint(uint256 _value,address _tokenOwner) internal returns(bool){
    _balances[_tokenOwner] = _balances[_tokenOwner].add(_value);
    _totalSupply = _totalSupply.add(_value);
    emit Transfer(address(0), _tokenOwner, _value);
    return true;
  }
  
  // Mapping for users with id => address Staked Address
  mapping (uint256 => address) private _stakerAddress;

  // Mapping for users with id => Tokens 
  mapping (uint256 => uint256) private _usersTokens;
  
  // Mapping for users with id => Staking Time
  mapping (uint256 => uint256) private _stakingStartTime;

  // Mapping for users with id => Status
  mapping (uint256 => bool) private _TokenTransactionstatus;  
 
  // Mapping to keep track of final withdraw value of staked token
  mapping(uint256=>uint256) private _finalWithdrawlStake;
  
  // Reward Percentage
  uint256 private _rewardPercentage= 15; 
  
  // Count of no of staking
  uint256 private _stakingCount = 0;

  // Withdraw Time limit
  uint256 _withdrawLimit = 2592000;

  
  /** 
   * @dev modifier to check the failsafe
   */
  modifier failSafe(){
    require(_stopped == false, "Fail Safe check failed");
    _;
  }

 /*
  * ------------------------------------------------------------------------------------
  * Owner functions of get value, set value, blacklist and withdraw BNB Functionality
  * ------------------------------------------------------------------------------------
  */

  /**
   * @dev Function to secure contract from fail by toggling _stopped variable
   */
  function toggleContractActive() public onlyOwner{
    _stopped = !_stopped;
  }


  /**
   * @dev Function to set token pool address
   * @param add Address for token pool that manages supplies for stakes.
   */
  function setTokenPoolAddress(address add) public onlyOwner returns(bool){
    require(add != address(0),"Invalid Address");
    _tokenPoolAddress = add;
    return true;
  }
  
 
  /**
   * @dev Function to get Token Pool addresss
   */
  function getTokenpoolAddress() public view returns(address){
    return _tokenPoolAddress;
  }


  /**
   * @dev Function for setting rewards percentage by owner
   * @param rewardsPercentage Reward percentage
   */
  function setRewardPercentage(uint256 rewardsPercentage) public onlyOwner returns(bool){
    require(rewardsPercentage > 0, "Invalid Percentage");
    _rewardPercentage = rewardsPercentage;
    return true;
  }

  /**
   * @dev Function for getting rewards percentage by owner
   */
  function getRewardPercentage() public view returns(uint256){
    return _rewardPercentage;
  }

  
  /**
   * @dev Function to blacklist any stake
   * @param status true/false
   * @param stakingId stake id for that particular stake
   */
  function blacklistStake(bool status,uint256 stakingId) external onlyOwner{
    _TokenTransactionstatus[stakingId] = status;
  }

  /**
   * @dev function to get total BNB in contract
   */
    function getContractBNBBalance() public view returns(uint256){
    return(address(this).balance);
    }

  /** 
   * @dev function to withdraw total BNB from contract
   */
    function withdrawBNB() external onlyOwner returns(bool){
    payable(msg.sender).transfer(address(this).balance);
    return true;
    }

 
/*
   * -------------------------------------------------------------------------------------
   * Functions for Staking Functionlaity
   * -------------------------------------------------------------------------------------
   */

  /**
   * @dev Function to get Final Withdraw Staked value
   * @param id stake id for the stake
   */
  function getFinalWithdrawlStake(uint256 id) public view returns(uint256){
    return _finalWithdrawlStake[id];
  }

  /**
   * @dev Function to get Staking address by id
   * @param id stake id for the stake
   */
  function getStakingAddressById(uint256 id) public view returns (address){
    require(id <= _stakingCount,"Unable to reterive data on specified id, Please try again!!");
    return _stakerAddress[id];
  }
  
  /**
   * @dev Function to get Staking Starting time by id
   * @param id stake id for the stake
   */
  function getStakingStartTimeById(uint256 id)public view returns(uint256){
    require(id <= _stakingCount,"Unable to reterive data on specified id, Please try again!!");
    return _stakingStartTime[id];
  }
  
  /**
   * @dev Function to get Staking tokens by id
   * @param id stake id for the stake
   */
  function getStakingTokenById(uint256 id)public view returns(uint256){
    require(id <= _stakingCount,"Unable to reterive data on specified id, Please try again!!");
    return _usersTokens[id];
  }
  
 /**
   * @dev Function to get active Staking tokens by id
   * @param id stake id for the stake
   */
  function getActiveStakesById(uint256 id)public view returns(address){
    return _stakerAddress[id];
  }

  /**
   * @dev Function to get Token lockstatus by id
   * @param id stake id for the stake
   */
  function getTokenStakeStatus(uint256 id)public view returns(bool){
    return _TokenTransactionstatus[id];
  }

  /**
   * @dev Function to get staking count
   */
  function getStakingCount() public view returns(uint256){
      return _stakingCount;
  }

  /**
   * @dev Function to get Rewards on the stake
   * @param id stake id for the stake
   */
  function getRewardsDetailsOfUserById(uint256 id) public view returns(uint256){
      return (_usersTokens[id].mul(_rewardPercentage).mul((block.timestamp - _stakingStartTime[id])/86400)).div(36500);
  }

  /**
   * @dev Function for setting withdraw time limit by owner
   * @param withdrawLimit Withdraw Limit
   */
  function setWithdrawLimit(uint256 withdrawLimit) public onlyOwner returns(bool){
    require(withdrawLimit > 0, "Invalid Time");
    _withdrawLimit = withdrawLimit;
    return true;
  }

  /**
   * @dev Function for getting withdraw limit by owner
   */
  function getWithdrawLimit() public view returns(uint256){
    return _withdrawLimit;
  }

  /**
   * @dev Function to performs staking for user tokens for a specific period of time
   * @param tokens number of tokens
   */
  function performStaking(uint256 tokens) public failSafe returns(bool,uint256){
    require(tokens > 0, "tokens cannot be zero");  
    _stakingCount = _stakingCount +1 ;
    _stakerAddress[_stakingCount] = msg.sender;
    _stakingStartTime[_stakingCount] = block.timestamp;
    _usersTokens[_stakingCount] = tokens;
    _TokenTransactionstatus[_stakingCount] = false;
    _transfer(msg.sender, _tokenPoolAddress, tokens);
    return (true , _stakingCount);
  }

  /**
   * @dev Function for withdrawing staked tokens
   * @param stakingId stake id for the stake
   */
  function withdrawStakedTokens(uint256 stakingId) public failSafe returns(bool){
    require(_stakerAddress[stakingId] == msg.sender,"No staked token found on this address and ID");
    require(_TokenTransactionstatus[stakingId] != true,"Either tokens are already withdrawn or blocked by admin");
    require(balanceOf(_tokenPoolAddress) >= _usersTokens[stakingId], "Pool is dry, can not perform transaction");
    _TokenTransactionstatus[stakingId] = true;
        if (block.timestamp > _stakingStartTime[stakingId].add(_withdrawLimit)){
          _finalWithdrawlStake[stakingId] = _usersTokens[stakingId] +getRewardsDetailsOfUserById(stakingId);
        _transfer(_tokenPoolAddress, msg.sender, _usersTokens[stakingId]);
        _transfer(_owner, msg.sender, getRewardsDetailsOfUserById(stakingId));
        }
        else {
         _transfer(_tokenPoolAddress, msg.sender, _usersTokens[stakingId]); 
        }
    return true;
  }


  mapping (address => uint256) public blocked;
  mapping (address => bool) public isBlocked;
 
  
  
/** 
 * @dev Modifier to check if a user account is blocked
 */
    modifier whenNotBlocked(address _account) {
      require(!isBlocked[_account]);
      _;
    }

/** 
 * @dev Function to blacklist any address
 * @param status true/false
 * @param _account _account address for that particular user
 */
  function blacklistAddresses(bool status, address _account) external onlyOwner {
    isBlocked[_account] = status;
  }


}