pragma solidity ^0.8.0;

interface VoteEscrow {
    struct LockedBalance {
        uint amount;
        uint end;
    }
    function balanceOf(address) external view returns (uint);
    function locked(address user) external view returns (LockedBalance memory);
}

contract VeYfiPositionHelper {

    struct Position {
        uint balance; 
        uint depositAmount;
        uint withdrawable;
        uint penalty;
        uint unlockTime;
        uint timeRemaining;
    }

    uint constant internal WEEK = 7 days;
    VoteEscrow constant public VEYFI = VoteEscrow(0x90c1f9220d90d3966FbeE24045EDd73E1d588aD5);
    uint constant internal MAX_LOCK_DURATION = 4 * 365 days / WEEK * WEEK; // 4 years
    uint constant internal SCALE = 10 ** 18;
    uint constant internal MAX_PENALTY_RATIO = SCALE * 3 / 4;  // 75% for early exit of max lock
    
    constructor() {}

    /// @notice Returns user position details
    /// @param user Address 
    /// @return position 
    ///     balance - current balanceOf
    ///     depositAmount - original deposit amount
    ///     withdrawable - Amount if withdraw is called at current block
    ///     penalty - Amount penalt if withdraw is called at current block
    ///     unlockTime - timestamp of scheduled lock end
    ///     timeRemaining - seconds until lock ends
    function getPositionDetails(address user) external view returns (Position memory position) {
        position.penalty = calculatePenalty(user);
        position.balance = VEYFI.balanceOf(user);
        position.depositAmount = VEYFI.locked(user).amount;
        position.withdrawable = position.depositAmount - position.penalty;
        position.unlockTime = VEYFI.locked(user).end;
        if (block.timestamp > position.unlockTime){
            position.timeRemaining = 0;
        }
        else {
            position.timeRemaining = position.unlockTime - block.timestamp;
        }
        return position;
    }

    function calculatePenalty(address user) internal view returns (uint) {
        VoteEscrow.LockedBalance memory lockInfo = VEYFI.locked(user);
        if (lockInfo.amount == 0) return 0;
        if (lockInfo.end > block.timestamp){
            uint timeLeft = min(lockInfo.end - block.timestamp, MAX_LOCK_DURATION);
            uint penaltyRatio = min(timeLeft * SCALE / MAX_LOCK_DURATION, MAX_PENALTY_RATIO);
            return lockInfo.amount * penaltyRatio / SCALE;
        }
        return 0;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}