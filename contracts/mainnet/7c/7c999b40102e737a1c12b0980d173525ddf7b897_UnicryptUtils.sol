/**
 *Submitted for verification at Etherscan.io on 2022-12-26
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

struct TokenLock {
    uint256 lockDate; // the date the token was locked
    uint256 amount; // the amount of tokens still locked (initialAmount minus withdrawls)
    uint256 initialAmount; // the initial lock amount
    uint256 unlockDate; // the date the token can be withdrawn
    uint256 lockID; // lockID nonce per uni pair
    address owner;
}


// https://etherscan.io/address/0x663A5C229c09b049E36dCc11a9B0d4a8Eb9db214
// https://bscscan.com/address/0xC765bddB93b0D1c1A88282BA0fa6B2d00E3e0c83
interface IUnicryptLocker {
    
    function getNumLocksForToken (address _lpToken) external view returns (uint256);

    function tokenLocks(address _lpToken, uint256 index) external view returns (TokenLock memory lock);
}

struct TokenVesting {
    address tokenAddress; // The token address
    uint256 tokensDeposited; // the total amount of tokens deposited
    uint256 tokensWithdrawn; // amount of tokens withdrawn
    uint256 startEmission; // date token emission begins
    uint256 endEmission; // the date the tokens can be withdrawn
    uint256 lockID; // lock id per token lock
    address owner; // the owner who can edit or withdraw the lock
    address condition; // address(0) = no condition, otherwise the condition contract must implement IUnlockCondition
}

// https://etherscan.io/address/0xDba68f07d1b7Ca219f78ae8582C213d975c25cAf
interface IUnicryptTokenVesting {
    function getTokenLocksLength (address _token) external view returns (uint256);

    function getTokenLockIDAtIndex (address _token, uint256 _index) external view returns (uint256);

    function getLock (uint256 _lockID) external view 
        returns (
            uint256 lockID, 
            address tokenAddress, 
            uint256 tokensDeposited, 
            uint256 tokensWithdrawn, 
            uint256 sharesDeposited, 
            uint256 sharesWithdrawn, 
            //* startEmission = 0 : LockType 1   * startEmission != 0 : LockType 2 (linear scaling lock)
            uint256 startEmission, 
            uint256 endEmission, 
            address owner, 
            // address(0) = no condition, otherwise the condition must implement IUnlockCondition
            address condition); 
}

// Allows a seperate contract with a unlockTokens() function to be used to override unlock dates
interface IUnlockCondition {
    function unlockTokens() external view returns (bool);
}

contract UnicryptUtils {
    
    function getLockCounts(address _unicrypt, address _lpToken, bool isVesting) 
        public 
        view 
        returns (uint256 count) {
        if (isVesting) {
            IUnicryptTokenVesting unicryptLocker = IUnicryptTokenVesting(_unicrypt);
            count = unicryptLocker.getTokenLocksLength(_lpToken);
        } else {
            IUnicryptLocker unicryptLocker = IUnicryptLocker(_unicrypt);
            count = unicryptLocker.getNumLocksForToken(_lpToken);
        }
    }

    function getAllLocks(address _unicrypt, address _lpToken) 
        public 
        view 
        returns (uint256 count, TokenLock[] memory locks) {
        IUnicryptLocker unicryptLocker = IUnicryptLocker(_unicrypt);
        count = unicryptLocker.getNumLocksForToken(_lpToken);
        locks = new TokenLock[](count);
        for(uint256 i = 0; i < count; i++) {
            locks[i] = unicryptLocker.tokenLocks(_lpToken, i);
        }
    }

    function getLocks(address _unicrypt, address _lpToken, uint256 start, uint256 end) 
        public 
        view 
        returns (uint256 count, TokenLock[] memory locks){
        IUnicryptLocker unicryptLocker = IUnicryptLocker(_unicrypt);
        count = unicryptLocker.getNumLocksForToken(_lpToken);
        require(start < count, "start must less than total count");
        end = count > end ? end : count;
        locks = new TokenLock[](end - start);
        for(uint256 i = start; i < end; i++) {
            uint256 index = i - start;
            locks[index] = unicryptLocker.tokenLocks(_lpToken, i);
        }
    }

    function getAllVesting(address _unicryptVesting, address _lpToken) 
        public 
        view 
        returns (uint256 count, TokenVesting[] memory locks) {
        IUnicryptTokenVesting unicryptLocker = IUnicryptTokenVesting(_unicryptVesting);
        count = unicryptLocker.getTokenLocksLength(_lpToken);
        locks = new TokenVesting[](count);
        for(uint256 i = 0; i < count; i++) {
            uint256 lockId = unicryptLocker.getTokenLockIDAtIndex(_lpToken, i);
            ( uint256 lockID, 
                address tokenAddress, 
                uint256 tokensDeposited, 
                uint256 tokensWithdrawn, , , 
                //* startEmission = 0 : LockType 1   * startEmission != 0 : LockType 2 (linear scaling lock)
                uint256 startEmission, 
                uint256 endEmission, 
                address owner, 
                // address(0) = no condition, otherwise the condition must implement IUnlockCondition
                address condition ) = unicryptLocker.getLock(lockId);
            locks[i] = TokenVesting(tokenAddress, tokensDeposited, tokensWithdrawn, startEmission, endEmission, lockID, owner, condition);
        }
    }

    function getVesting(address _unicryptVesting, address _lpToken, uint256 start, uint256 end)
        public 
        view 
        returns (uint256 count, TokenVesting[] memory locks) {
        IUnicryptTokenVesting unicryptLocker = IUnicryptTokenVesting(_unicryptVesting);
        count = unicryptLocker.getTokenLocksLength(_lpToken);
        require(start < count, "start must less than total count");
        end = count > end ? end : count;
        locks = new TokenVesting[](end - start);
        for(uint256 i = start; i < end; i++) {
            uint256 lockId = unicryptLocker.getTokenLockIDAtIndex(_lpToken, i);
            ( uint256 lockID, 
                address tokenAddress, 
                uint256 tokensDeposited, 
                uint256 tokensWithdrawn, , , 
                //* startEmission = 0 : LockType 1   * startEmission != 0 : LockType 2 (linear scaling lock)
                uint256 startEmission, 
                uint256 endEmission, 
                address owner, 
                // address(0) = no condition, otherwise the condition must implement IUnlockCondition
                address condition ) = unicryptLocker.getLock(lockId);
            uint256 index = i - start;
            locks[index] = TokenVesting(tokenAddress, tokensDeposited, tokensWithdrawn, startEmission, endEmission, lockID, owner, condition);
        }
    }
}