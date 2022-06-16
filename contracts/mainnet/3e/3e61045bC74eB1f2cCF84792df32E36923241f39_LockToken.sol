pragma solidity ^0.4.24;
import "./StandardToken.sol";
import "./Ownable.sol";
import "./ERC1132.sol";

contract LockToken is StandardToken, Ownable, ERC1132 {

    string public constant name = "CoinCoffeeCoin2";
	string public constant symbol = "CCC2";
	uint256 public constant decimals = 18;
	uint256 public constant INITIAL_SUPPLY = 1000000000 * (10 ** decimals);
    
	constructor() public {
        totalSupply_ = INITIAL_SUPPLY;
		balances[msg.sender] = INITIAL_SUPPLY;
	}
	
    event Mint(address minter, uint256 value);
	event Burn(address burner, uint256 value);
    
	string internal constant INVALID_TOKEN_VALUES = 'Invalid token values';
	string internal constant NOT_ENOUGH_TOKENS = 'Not enough tokens';
	string internal constant ALREADY_LOCKED = 'Tokens already locked';
	string internal constant NOT_LOCKED = 'No tokens locked';
	string internal constant AMOUNT_ZERO = 'Amount can not be 0';


	function mint(address _to, uint256 _amount) public onlyOwner {
		require(_amount > 0, INVALID_TOKEN_VALUES);
		balances[_to] = balances[_to].add(_amount);
		totalSupply_ = totalSupply_.add(_amount);
		emit Mint(_to, _amount);
	}

	/**
	 * @dev Burn a specified amount of tokens in _of. Only available to the Owner.
	 * @param _of address to burn
	 * @param _amount an amount value to be burned
	 */
	function burn(address _of, uint256 _amount) public onlyOwner {
		require(_amount > 0, INVALID_TOKEN_VALUES);
		require(_amount <= balances[_of], NOT_ENOUGH_TOKENS);
		balances[_of] = balances[_of].sub(_amount);
		totalSupply_ = totalSupply_.sub(_amount);
		emit Burn(_of, _amount);
	}


   function lock(bytes32 _reason, uint256 _amount, uint256 _time, address _of) public onlyOwner returns (bool) {
    uint256 validUntil = now.add(_time); //solhint-disable-line

	// If tokens are already locked, then functions extendLock or
	// increaseLockAmount should be used to make any changes
	require(_amount <= balances[_of], NOT_ENOUGH_TOKENS); // 추가
	require(tokensLocked(_of, _reason) == 0, ALREADY_LOCKED);
	require(_amount != 0, AMOUNT_ZERO);

	if (locked[_of][_reason].amount == 0)
		lockReason[_of].push(_reason);

	balances[address(this)] = balances[address(this)].add(_amount);
	balances[_of] = balances[_of].sub(_amount);
	locked[_of][_reason] = lockToken(_amount, validUntil, false);

	emit Transfer(_of, address(this), _amount);
	emit Locked(_of, _reason, _amount, validUntil);
	return true;
    }

    /**
     * @dev Transfers and Locks a specified amount of tokens,
     *      for a specified reason and time
     * @param _to adress to which tokens are to be transfered
     * @param _reason The reason to lock tokens
     * @param _amount Number of tokens to be transfered and locked
     * @param _time Lock time in seconds
     */
    function transferWithLock(address _to, bytes32 _reason, uint256 _amount, uint256 _time)
        public
        returns (bool)
    {
        uint256 validUntil = now.add(_time); //solhint-disable-line

        require(tokensLocked(_to, _reason) == 0, ALREADY_LOCKED);
        require(_amount != 0, AMOUNT_ZERO);

        if (locked[_to][_reason].amount == 0)
            lockReason[_to].push(_reason);

        transfer(address(this), _amount);

        locked[_to][_reason] = lockToken(_amount, validUntil, false);
        
        emit Locked(_to, _reason, _amount, validUntil);
        return true;
    }

    /**
     * @dev Returns tokens locked for a specified address for a
     *      specified reason
     *
     * @param _of The address whose tokens are locked
     * @param _reason The reason to query the lock tokens for
     */
    function tokensLocked(address _of, bytes32 _reason)
        public
        view
        returns (uint256 amount)
    {
        if (!locked[_of][_reason].claimed)
            amount = locked[_of][_reason].amount;
    }
    
    /**
     * @dev Returns tokens locked for a specified address for a
     *      specified reason at a specific time
     *
     * @param _of The address whose tokens are locked
     * @param _reason The reason to query the lock tokens for
     * @param _time The timestamp to query the lock tokens for
     */
    function tokensLockedAtTime(address _of, bytes32 _reason, uint256 _time)
        public
        view
        returns (uint256 amount)
    {
        if (locked[_of][_reason].validity > _time)
            amount = locked[_of][_reason].amount;
    }

    /**
     * @dev Returns total tokens held by an address (locked + transferable)
     * @param _of The address to query the total balance of
     */
    function totalBalanceOf(address _of)
        public
        view
        returns (uint256 amount)
    {
        amount = balanceOf(_of);

        for (uint256 i = 0; i < lockReason[_of].length; i++) {
            amount = amount.add(tokensLocked(_of, lockReason[_of][i]));
        }   
    }    
    
    /**
     * @dev Extends lock for a specified reason and time
     * @param _reason The reason to lock tokens
     * @param _time Lock extension time in seconds
     */
    function extendLock(bytes32 _reason, uint256 _time ,address _of)
        public
        returns (bool)
    {
        require(tokensLocked(_of, _reason) > 0, NOT_LOCKED);

        locked[_of][_reason].validity = locked[_of][_reason].validity.add(_time);

        emit Locked(_of, _reason, locked[_of][_reason].amount, locked[_of][_reason].validity);
        return true;
    }
    
    /**
     * @dev Increase number of tokens locked for a specified reason
     * @param _reason The reason to lock tokens
     * @param _amount Number of tokens to be increased
     */
    function increaseLockAmount(bytes32 _reason, uint256 _amount, address _of)
        public
        returns (bool)
    {
        require(tokensLocked(_of, _reason) > 0, NOT_LOCKED);
        transfer(address(this), _amount);

        locked[_of][_reason].amount = locked[_of][_reason].amount.add(_amount);

        emit Locked(_of, _reason, locked[_of][_reason].amount, locked[_of][_reason].validity);
        return true;
    }

    /**
     * @dev Returns unlockable tokens for a specified address for a specified reason
     * @param _of The address to query the the unlockable token count of
     * @param _reason The reason to query the unlockable tokens for
     */
    function tokensUnlockable(address _of, bytes32 _reason)
        public
        view
        returns (uint256 amount)
    {
        if (locked[_of][_reason].validity <= now && !locked[_of][_reason].claimed) //solhint-disable-line
            amount = locked[_of][_reason].amount;
    }

    /**
     * @dev Unlocks the unlockable tokens of a specified address
     * @param _of Address of user, claiming back unlockable tokens
     */
    function unlock(address _of)
        public
        returns (uint256 unlockableTokens)
    {
        uint256 lockedTokens;

        for (uint256 i = 0; i < lockReason[_of].length; i++) {
            lockedTokens = tokensUnlockable(_of, lockReason[_of][i]);
            if (lockedTokens > 0) {
                unlockableTokens = unlockableTokens.add(lockedTokens);
                locked[_of][lockReason[_of][i]].claimed = true;
                emit Unlocked(_of, lockReason[_of][i], lockedTokens);
            }
        }  

        if (unlockableTokens > 0)
            this.transfer(_of, unlockableTokens);
    }

    /**
     * @dev Gets the unlockable tokens of a specified address
     * @param _of The address to query the the unlockable token count of
     */
    function getUnlockableTokens(address _of)
        public
        view
        returns (uint256 unlockableTokens)
    {
        for (uint256 i = 0; i < lockReason[_of].length; i++) {
            unlockableTokens = unlockableTokens.add(tokensUnlockable(_of, lockReason[_of][i]));
        }  
    }
	
}