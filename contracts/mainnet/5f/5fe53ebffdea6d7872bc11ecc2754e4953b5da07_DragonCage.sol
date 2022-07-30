/**
 *Submitted for verification at Etherscan.io on 2022-07-30
*/

//SPDX-License-Identifier: MIT
/*
    DragonCage - a perpetual liquidity & token locker for the Last Dragon Slayer

    Unlike traditional liquidity/token lockers, this smart contract creates 
    a lock with no pre-set unlock date, making the lock perpetual.

    Unlocking the tokens is only possible by starting an unlock timer 
    which is immutably set for 30 days from when the timer is activated.
    While the timer is running, the lock can be reinstated and timer is cancelled.

    This brings the best of both worlds for token holders and the project team:
        - Holders can be certain Liquidity/Tokens are locked and will always get
          at least 30 days notice if that were to ever change.
        - Team retains the ability to migrate liquidity/tokens in the future, 
          should such a need ever arise.

    The lock details are public to anyone on Etherscan (and blockchain directly):
        - if a specific token/liquidity CA is locked
        - if the unlock timer has been activated
        - how much time is left on the timer if it's been activated    
*/

pragma solidity 0.8.15;

interface IERC20 {
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

abstract contract Auth {
    address internal owner;
    constructor(address _owner) { owner = _owner; }
    modifier onlyOwner() { require(msg.sender == owner, "Only contract owner can call this function"); _; }
    function transferOwnership(address payable newOwner) external onlyOwner { owner = newOwner; emit OwnershipTransferred(newOwner); }
    event OwnershipTransferred(address owner);
}

contract DragonCage is Auth {
    uint256 unlockTimerSeconds = 30 * 24 * 3600; // 30 days expressed in seconds
    struct Lock {
        uint256 lockedOn;
        uint256 unlockTimerStart;
        uint256 unlockTimerEnd;
    }

    mapping(address => Lock) private lockInfo;
    
    event TokenLocked(address tokenCa, uint256 lockTimestamp);
    event UnlockTimerStarted(address tokenCa, uint256 timerStart, uint256 unlocksOn);
    event TokensRetrieved(address tokenCa, uint256 retrievedOn);
    
    constructor() Auth(msg.sender) {}

    /// @dev returns the owner of this lock contract - only address authorized to lock, start unlock timers and/or retrieve unlocked tokens    
    function contractOwner() external view returns(address) {
        return owner;
    }

    /// @dev Get detailed info about a specific CA lock
    /// @return tokenAddress How many tokens currently locked
    /// @return tokenName How many tokens currently locked
    /// @return tokenSymbol How many tokens currently locked
    /// @return tokenAmount How many tokens currently locked
    /// @return isLocked Is this CA under a lock?
    /// @return unlockTimerActive Has the unlock timer been started?
    /// @return secondsTillUnlock Remaining seconds until the unlock timer reaches maturity; returns 315360000 seconds (10 years) if locked but unlock timer isn't running
    /// @return daysTillUnlock Approximate amount of days remaining before timer reaches maturity; returns 3650 days if locked but unlock timer isn't running
    function getLockInfo(address tokenCa) external view returns( address tokenAddress, string memory tokenName, string memory tokenSymbol, uint256 tokenAmount, bool isLocked, bool unlockTimerActive, uint256 secondsTillUnlock, uint256 daysTillUnlock ) {
        bool _isLocked = isLockedCheck(lockInfo[tokenCa]);
        bool _unlockTimerActive = false;
        uint256 _timeTillUnlocked = 0;
        if (_isLocked) {
            _unlockTimerActive = lockInfo[tokenCa].unlockTimerStart > 0 ;
            if (!_unlockTimerActive) { _timeTillUnlocked = 10 * 365 * 24 * 3600 ; } // unlock timer not started, return 10 years
            else if (lockInfo[tokenCa].unlockTimerEnd > block.timestamp) { _timeTillUnlocked = lockInfo[tokenCa].unlockTimerEnd - block.timestamp; } // unlock timer running and is in the future, return remaining seconds
        }

        uint256 r_days = _timeTillUnlocked / 86400;
        IERC20 token = IERC20(tokenCa);
        return ( tokenCa, token.name(), token.symbol(), token.balanceOf(address(this)), _isLocked, _unlockTimerActive, _timeTillUnlocked, r_days );
    }

    /// @dev Get exact timestamps for a specific CA lock
    /// @return lockedOn Timestamp - When was this lock last activated? (zero if not locked)
    /// @return UnlockTimerStartedOn Timestamp - When was the unlock timer started (zero if timer isn't running)
    /// @return unlockTimerEnd Timestamp - When does the unlock timer finish and tokens can be retrieved (zero if timer isn't running)
    function getLockTimestamps(address tokenCa) external view returns( uint256 lockedOn, uint256 UnlockTimerStartedOn, uint256 unlockTimerEnd ) {
        uint256 _timeTillUnlocked = 0;
        if (lockInfo[tokenCa].unlockTimerEnd > block.timestamp) { _timeTillUnlocked = lockInfo[tokenCa].unlockTimerEnd - block.timestamp; }
        return ( lockInfo[tokenCa].lockedOn, lockInfo[tokenCa].unlockTimerStart, lockInfo[tokenCa].unlockTimerEnd );
    }

    /// @dev Owner can place the perpetual lock on any ERC20 token (regular or LP). All tokens owned by this locker contract will be under this lock regardless of when they were transferred in (before or after the lock was activated)
    function lockTokens(address tokenCa) external onlyOwner {
        IERC20 ercToken = IERC20(tokenCa);
        uint256 tokenAmount = ercToken.balanceOf(address(this));
        require(tokenAmount > 0, "No tokens to lock");
        Lock memory thisLock = lockInfo[tokenCa];
        thisLock.lockedOn = block.timestamp;
        thisLock.unlockTimerStart = 0;
        thisLock.unlockTimerEnd = 0;
        lockInfo[tokenCa] = thisLock;
        emit TokenLocked(tokenCa, block.timestamp);
    }

    /// @dev Tokens are perpetually locked with no unlock date unless an unlock timer is started. The unlock timer is always 30 days and can be cancelled at any point using the lockTokens() function again.
    function startUnlockTimer(address tokenCa) external onlyOwner {
        Lock memory thisLock = lockInfo[tokenCa];
        require(isLockedCheck(lockInfo[tokenCa]), "Token is not locked");
        require(thisLock.unlockTimerStart == 0,"Unlock timer already active");
        thisLock.unlockTimerStart = block.timestamp;
        thisLock.unlockTimerEnd = block.timestamp + unlockTimerSeconds;
        lockInfo[tokenCa] = thisLock;
        emit UnlockTimerStarted(tokenCa, thisLock.unlockTimerStart, thisLock.unlockTimerEnd);
    }

    function isLockedCheck(Lock memory tokenLockData) private view returns(bool lockResult) {
        bool locked = true;
        if (tokenLockData.lockedOn == 0) { locked = false; }
        else if (
            tokenLockData.unlockTimerStart > 0 
            && tokenLockData.unlockTimerEnd > tokenLockData.unlockTimerStart 
            && tokenLockData.unlockTimerEnd < block.timestamp) {
                locked = false; 
            }
        return locked;
    }

    /// @dev Tokens that are not locked can be retrieved to the owner's wallet. 
    function retrieveUnlockedTokens(address tokenCa) external onlyOwner {
        require(!isLockedCheck(lockInfo[tokenCa]), "Tokens locked!");

        IERC20 ercToken = IERC20(tokenCa);
        uint256 tokenAmount = ercToken.balanceOf(address(this));
        require(tokenAmount > 0, "No tokens to retrieve");
        ercToken.transfer(owner, tokenAmount);
        
        lockInfo[tokenCa].lockedOn = 0;
        lockInfo[tokenCa].unlockTimerStart = 0;
        lockInfo[tokenCa].unlockTimerEnd = 0;

        emit TokensRetrieved(tokenCa, block.timestamp);
    }
}