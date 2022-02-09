// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "./IERC20.sol";
import "./SafeMath.sol";
import "./Pausable.sol";
import "./SwapAdmin.sol";

contract SwapTokenLocker is SwapAdmin, Pausable {
    using SafeMath for uint;

    IERC20 private token;
    struct LockInfo {
        uint256 amount;
        uint256 lockTimestamp; // lock time at block.timestamp
        uint256 lockHours;
        uint256 claimedAmount;
    }
    mapping (address => LockInfo) public lockData;
    
    constructor(address _token, address _admin) public SwapAdmin(_admin) {
        token = IERC20(_token);
    }
    
	function getLockData(address _user) public view returns(uint256, uint256, uint256, uint256) {
		return (lockData[_user].amount, lockData[_user].lockTimestamp, lockData[_user].lockHours, lockData[_user].claimedAmount);
	}

    function sendLockTokenMany(address[] calldata _users, uint256[] calldata _amounts, uint256[] calldata _lockTimestamps, uint256[] calldata _lockHours) external onlyAdmin {
        require(_users.length == _amounts.length, "array length not eq");
        require(_users.length == _lockHours.length, "array length not eq");
        require(_users.length == _lockTimestamps.length, "array length not eq");
        for (uint256 i=0; i < _users.length; i++) {
            sendLockToken(_users[i], _amounts[i], _lockTimestamps[i], _lockHours[i]);
        }
    }

    // 1. msg.sender/admin approve many token to this contract
    function sendLockToken(address _user, uint256 _amount, uint256 _lockTimestamp, uint256 _lockHours) public onlyAdmin returns (bool) {
        require(_amount > 0, "amount can not zero");
        require(lockData[_user].amount == 0, "this address has locked");
        require(_lockHours > 0, "lock hours need more than zero");
        require(_lockTimestamp > 0, "lock timestamp need more than zero");
        
        LockInfo memory lockinfo = LockInfo({
            amount: _amount,
            //lockTimestamp: block.timestamp,
            lockTimestamp: _lockTimestamp,
            lockHours: _lockHours,
            claimedAmount: 0
        });

        lockData[_user] = lockinfo;
        return true;
    }
    
    function claimToken(uint256 _amount) external returns (uint256) {
        require(_amount > 0, "Invalid parameter amount");
        address _user = msg.sender;
        require(lockData[_user].amount > 0, "No lock token to claim");

        uint256 passhours = block.timestamp.sub(lockData[_user].lockTimestamp).div(1 hours);
        require(passhours > 0, "need wait for one hour at least");

        uint256 available = 0;
        if (passhours >= lockData[_user].lockHours) {
            available = lockData[_user].amount;
        } else {
            available = lockData[_user].amount.div(lockData[_user].lockHours).mul(passhours);
        }
        available = available.sub(lockData[_user].claimedAmount);
        require(available > 0, "not available claim");
        //require(_amount <= available, "insufficient available");
        uint256 claim = _amount;
        if (_amount > available) { // claim as much as possible
            claim = available;
        }

        lockData[_user].claimedAmount = lockData[_user].claimedAmount.add(claim);

        token.transfer(_user, claim);

        return claim;
    }
}