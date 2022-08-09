/**
 *Submitted for verification at Etherscan.io on 2022-08-09
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.14;


interface IERC20 {

    function totalSupply() external view returns (uint256);
    
    function symbol() external view returns(string memory);
    
    function name() external view returns(string memory);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);
    
    /**
     * @dev Returns the number of decimal places
     */
    function decimals() external view returns (uint8);

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

contract TokenLocker {

    // List Of Token Lock Information
    struct TokenLockInfo {
        address token;
        address lockAddress;
        uint256 lockAmount;
        uint256 lockExpiration;
    }

    // ID -> Token Lock Info
    mapping ( uint256 => TokenLockInfo ) public lockInfo;

    // User -> ID[]
    mapping ( address => uint256[] ) public userInfo;

    // ID -> Index In User Array
    mapping ( uint256 => uint256 ) private IDIndex;

    // Global Nonce
    uint256 public nonce;

    // Events
    event Locked(address token, uint256 amount, uint256 ID, uint256 duration, address unlockRecipient);
    event Unlocked(address token, uint256 amount, uint256 ID);
    event Relocked(address token, uint256 amount, uint256 ID, uint256 newDuration);


    /**
        Locks `amount` of `token` for `duration` in blocks
        When unlocked, tokens are sent to the `msg.sender`
     */
    function lock(address token, uint256 amount, uint256 duration) external returns (uint256 ID) {
        return _lock(msg.sender, token, amount, duration);
    }

    /**
        Unlocks ID And Lock Data Associated
     */
    function unlock(uint256 ID) external {
        
        // Fetch Data From ID
        address unlocker   = lockInfo[ID].lockAddress;
        uint256 lockAmount = lockInfo[ID].lockAmount;
        uint256 lockExpiry = lockInfo[ID].lockExpiration;
        address lockToken  = lockInfo[ID].token;

        // Require Conditions Are Met
        require(
            msg.sender == unlocker,
            'Only Unlocker Can Unlock'
        );
        require(
            lockExpiry <= block.number,
            'Lock Has Not Expired'
        );
        require(
            lockAmount > 0,
            'Nothing To Unlock'
        );
        require(
            lockToken != address(0),
            'Zero Address'
        );
        
        // remove ID from user's list of lock IDs
        _removeID(unlocker, ID);

        // remove data
        delete lockInfo[ID];

        // transfer locked tokens to unlocker address
        require(
            IERC20(lockToken).transfer(
                unlocker,
                lockAmount
            ),
            'Failure On Token Transfer'
        );

        // emit Unlocked Event
        emit Unlocked(lockToken, lockAmount, ID);
    }

    /**
        Re Locks ID And Lock Data Associated
     */
    function relock(uint256 ID, uint256 newLockDuration) external {

        // Fetch Data From ID
        address unlocker   = lockInfo[ID].lockAddress;
        uint256 lockAmount = lockInfo[ID].lockAmount;
        uint256 lockExpiry = lockInfo[ID].lockExpiration;

        // Require Conditions Are Met
        require(
            msg.sender == unlocker,
            'Only Unlocker Can Relock'
        );
        require(
            lockExpiry <= block.number,
            'Lock Has Not Expired'
        );
        require(
            lockAmount > 0,
            'Nothing To ReLock'
        );

        // set new expiration date
        lockInfo[ID].lockExpiration = block.number + newLockDuration;

        // emit Relocked Event
        emit Relocked(lockInfo[ID].token, lockAmount, ID, newLockDuration);
    }


    /**
        Locks `amount` of `token` for `duration` in blocks
        When unlocked, tokens are sent to the `unlocker`
     */
    function _lock(address unlocker, address token, uint256 amount, uint256 duration) internal returns (uint256 ID) {

        // zero validation checks
        require(
            token != address(0) &&
            unlocker != address(0) &&
            amount > 0 &&
            duration > 0,
            'Zero Fields'
        );

        // transfer in locked token
        uint received = _transferIn(token, amount);

        // Set Lock Info For ID
        lockInfo[nonce].token = token;
        lockInfo[nonce].lockAddress = unlocker;
        lockInfo[nonce].lockAmount = received;
        lockInfo[nonce].lockExpiration = block.number + duration;

        // Add To User's List Of Lock IDs
        IDIndex[nonce] = userInfo[unlocker].length;
        userInfo[unlocker].push(nonce);
        
        // emit Lock Event
        emit Locked(token, received, nonce, duration, unlocker);

        // Increment Nonce
        nonce++;

        // return ID Used
        return nonce - 1;
    }


    function _transferIn(address token, uint256 amount) internal returns (uint256) {
        uint before = IERC20(token).balanceOf(address(this));
        require(
            IERC20(token).transferFrom(
                msg.sender,
                address(this),
                amount
            ),
            'Error On Transfer From'
        );
        uint After = IERC20(token).balanceOf(address(this));
        require(
            After > before,
            'Zero Tokens Received'
        );
        return After - before;
    }

    function _removeID(address user, uint256 ID) internal {
        require(
            userInfo[user][IDIndex[ID]] == ID,
            'ID Not Found'
        );

        IDIndex[
            userInfo[user][userInfo[user].length - 1]
        ] = IDIndex[ID];

        userInfo[user][IDIndex[ID]] = userInfo[user][userInfo[user].length - 1];
        userInfo[user].pop();
        delete IDIndex[ID];
    }

    function timeUntilUnlock(uint256 ID) public view returns (uint256) {
        uint unlocksAt = lockInfo[ID].lockExpiration;
        return unlocksAt > block.number ? unlocksAt - block.number : 0;
    }

    function listLockIDs(address user) external view returns (uint256[] memory) {
        return userInfo[user];
    }

    function listLockDataForUser(address user) external view returns (address[] memory, uint256[] memory, uint256[] memory) {
        uint len = userInfo[user].length;
        address[] memory tokens = new address[](len);
        uint256[] memory amounts = new uint256[](len);
        uint256[] memory expirationDates = new uint256[](len);
        for (uint i = 0; i < len; i++) {
            tokens[i] = lockInfo[userInfo[user][i]].token;
            amounts[i] = lockInfo[userInfo[user][i]].lockAmount;
            expirationDates[i] = lockInfo[userInfo[user][i]].lockExpiration;
        }
        return(tokens, amounts, expirationDates);
    }

    function listIDsAndLockDataForUser(address user) external view returns (uint256[] memory, address[] memory, uint256[] memory, uint256[] memory) {
        uint len = userInfo[user].length;
        address[] memory tokens = new address[](len);
        uint256[] memory amounts = new uint256[](len);
        uint256[] memory expirationDates = new uint256[](len);
        uint256[] memory IDs = new uint256[](len);
        for (uint i = 0; i < len; i++) {
            IDs[i] = userInfo[user][i];
            tokens[i] = lockInfo[userInfo[user][i]].token;
            amounts[i] = lockInfo[userInfo[user][i]].lockAmount;
            expirationDates[i] = lockInfo[userInfo[user][i]].lockExpiration;
        }
        return(IDs, tokens, amounts, expirationDates);
    }

    function listIDsAndLockDataForUserWithNames(address user) external view returns (uint256[] memory, string[] memory, uint256[] memory, uint256[] memory) {
        uint len = userInfo[user].length;
        string[] memory tokens = new string[](len);
        uint256[] memory amounts = new uint256[](len);
        uint256[] memory expirationDates = new uint256[](len);
        for (uint i = 0; i < len; i++) {
            tokens[i] = IERC20(lockInfo[userInfo[user][i]].token).symbol();
            amounts[i] = lockInfo[userInfo[user][i]].lockAmount;
            expirationDates[i] = lockInfo[userInfo[user][i]].lockExpiration;
        }
        return(userInfo[user], tokens, amounts, expirationDates);
    }

    function listIDsAndLockDataForUserWithNamesAndAddresses(address user) external view returns (uint256[] memory, string[] memory, uint8[] memory, address[] memory, uint256[] memory, uint256[] memory) {
        address user_ = user;
        uint len = userInfo[user_].length;
        string[] memory tokens = new string[](len);
        uint8[] memory tokenDecimals = new uint8[](len);
        address[] memory tokenAddresses = new address[](len);
        uint256[] memory amounts = new uint256[](len);
        uint256[] memory unlockTimes = new uint256[](len);
        for (uint i = 0; i < len; i++) {
            tokens[i] = IERC20(lockInfo[userInfo[user_][i]].token).symbol();
            tokenDecimals[i] = IERC20(lockInfo[userInfo[user_][i]].token).decimals();
            tokenAddresses[i] = lockInfo[userInfo[user_][i]].token;
            amounts[i] = lockInfo[userInfo[user_][i]].lockAmount;
            unlockTimes[i] = timeUntilUnlock(userInfo[user_][i]);
        }
        return(userInfo[user_], tokens, tokenDecimals, tokenAddresses, amounts, unlockTimes);
    }

}