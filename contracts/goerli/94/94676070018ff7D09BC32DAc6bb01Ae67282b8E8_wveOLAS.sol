// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// Structure for veOLAS points
struct PointVoting {
    int128 bias;
    int128 slope;
    uint64 ts;
    uint64 blockNumber;
    uint128 balance;
}

interface IVEOLAS {
    /// @dev Gets the total number of supply points.
    /// @return numPoints Number of supply points.
    function totalNumPoints() external view returns (uint256 numPoints);

    /// @dev Gets the supply point of a specified index.
    /// @param idx Supply point number.
    /// @return sPoint Supply point.
    function mapSupplyPoints(uint256 idx) external view returns (PointVoting memory sPoint);

    /// @dev Gets the most recently recorded user point for `account`.
    /// @param account Account address.
    /// @return pv Last checkpoint.
    function getLastUserPoint(address account) external view returns (PointVoting memory pv);

    /// @dev Gets the number of user points.
    /// @param account Account address.
    /// @return userNumPoints Number of user points.
    function getNumUserPoints(address account) external view returns (uint256 userNumPoints);

    /// @dev Gets the checkpoint structure at number `idx` for `account`.
    /// @notice The out of bound condition is treated by the default code generation check.
    /// @param account User wallet address.
    /// @param idx User point number.
    /// @return uPoint The requested user point.
    function getUserPoint(address account, uint256 idx) external view returns (PointVoting memory uPoint);

    /// @dev Gets voting power at a specific block number.
    /// @param account Account address.
    /// @param blockNumber Block number.
    /// @return balance Voting balance / power.
    function getPastVotes(address account, uint256 blockNumber) external view returns (uint256 balance);

    /// @dev Gets the account balance in native token.
    /// @param account Account address.
    /// @return balance Account balance.
    function balanceOf(address account) external view returns (uint256 balance);

    /// @dev Gets the account balance at a specific block number.
    /// @param account Account address.
    /// @param blockNumber Block number.
    /// @return balance Account balance.
    function balanceOfAt(address account, uint256 blockNumber) external view returns (uint256 balance);

    /// @dev Gets the `account`'s lock end time.
    /// @param account Account address.
    /// @return unlockTime Lock end time.
    function lockedEnd(address account) external view returns (uint256 unlockTime);

    /// @dev Gets the voting power.
    /// @param account Account address.
    /// @return balance Account balance.
    function getVotes(address account) external view returns (uint256 balance);

    /// @dev Gets total token supply.
    /// @return supply Total token supply.
    function totalSupply() external view returns (uint256 supply);

    /// @dev Gets total token supply at a specific block number.
    /// @param blockNumber Block number.
    /// @return supplyAt Supply at the specified block number.
    function totalSupplyAt(uint256 blockNumber) external view returns (uint256 supplyAt);

    /// @dev Calculates total voting power at time `ts`.
    /// @param ts Time to get total voting power at.
    /// @return vPower Total voting power.
    function totalSupplyLockedAtT(uint256 ts) external view returns (uint256 vPower);

    /// @dev Calculates current total voting power.
    /// @return vPower Total voting power.
    function totalSupplyLocked() external view returns (uint256 vPower);

    /// @dev Calculate total voting power at some point in the past.
    /// @param blockNumber Block number to calculate the total voting power at.
    /// @return vPower Total voting power.
    function getPastTotalSupply(uint256 blockNumber) external view returns (uint256 vPower);

    /// @dev Gets information about the interface support.
    /// @param interfaceId A specified interface Id.
    /// @return True if this contract implements the interface defined by interfaceId.
    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    /// @dev Reverts the allowance of this token.
    function allowance(address owner, address spender) external view returns (uint256);

    /// @dev Reverts delegates of this token.
    function delegates(address account) external view returns (address);
}

/// @dev Zero veOLAS address.
error ZeroAddress();

/// @dev Provided wrong timestamp.
/// @param minTimeStamp Minimum timestamp.
/// @param providedTimeStamp Provided timestamp.
error WrongTimestamp(uint256 minTimeStamp, uint256 providedTimeStamp);

/// @dev Called function is implemented in a specified veOLAS contract.
/// @param veToken Original veOLAS address.
error ImplementedIn(address veToken);

/// @dev veOLAS token is non-transferable.
/// @param veToken veOLAS token address.
error NonTransferable(address veToken);

/// @dev veOLAS token is non-delegatable.
/// @param veToken veOLAS token address.
error NonDelegatable(address veToken);

/// @title wveOLAS - Wrapper smart contract for view functions of veOLAS contract
/// @author AL
/// @author Aleksandr Kuperman - <[email protected]>
contract wveOLAS {
    // veOLAS address
    address public immutable ve;
    // OLAS address
    address public immutable token;
    // veOLAS token name
    string public constant name = "Voting Escrow OLAS";
    // veOLAS token symbol
    string public constant symbol = "veOLAS";
    // veOLAS token decimals
    uint8 public constant decimals = 18;

    /// @dev TokenomicsProxy constructor.
    /// @param _ve veOLAS address.
    /// @param _token OLAS address.
    constructor(address _ve, address _token) {
        // Check for the zero address
        if (_ve == address(0) || _token == address(0)) {
            revert ZeroAddress();
        }
        ve = _ve;
        token = _token;
    }

    /// @dev Gets the most recently recorded user point for `account`.
    /// @param account Account address.
    /// @return pv Last checkpoint.
    function getLastUserPoint(address account) external view returns (PointVoting memory pv) {
        pv = IVEOLAS(ve).getLastUserPoint(account);
    }

    /// @dev Gets the number of user points.
    /// @param account Account address.
    /// @return userNumPoints Number of user points.
    function getNumUserPoints(address account) external view returns (uint256 userNumPoints) {
        userNumPoints = IVEOLAS(ve).getNumUserPoints(account);
    }

    /// @dev Gets the checkpoint structure at number `idx` for `account`.
    /// @notice The out of bound condition is treated by the default code generation check.
    /// @param account User wallet address.
    /// @param idx User point number.
    /// @return uPoint The requested user point.
    function getUserPoint(address account, uint256 idx) public view returns (PointVoting memory uPoint) {
        // Get the number of user points
        uint256 userNumPoints = IVEOLAS(ve).getNumUserPoints(account);
        if (userNumPoints > 0) {
            uPoint = IVEOLAS(ve).getUserPoint(account, idx);
        }
    }

    /// @dev Gets the voting power.
    /// @param account Account address.
    function getVotes(address account) external view returns (uint256 balance) {
        balance = IVEOLAS(ve).getVotes(account);
    }

    /// @dev Gets voting power at a specific block number.
    /// @param account Account address.
    /// @param blockNumber Block number.
    /// @return balance Voting balance / power.
    function getPastVotes(address account, uint256 blockNumber) external view returns (uint256 balance) {
        // Get the zero account point
        PointVoting memory uPoint = getUserPoint(account, 0);
        // Check that the point exists and the zero point block number is not smaller than the specified blockNumber
        if (uPoint.blockNumber > 0 && blockNumber >= uPoint.blockNumber) {
            balance = IVEOLAS(ve).getPastVotes(account, blockNumber);
        }
    }

    /// @dev Gets the account balance in native token.
    /// @param account Account address.
    /// @return balance Account balance.
    function balanceOf(address account) external view returns (uint256 balance) {
        balance = IVEOLAS(ve).balanceOf(account);
    }

    /// @dev Gets the account balance at a specific block number.
    /// @param account Account address.
    /// @param blockNumber Block number.
    /// @return balance Account balance.
    function balanceOfAt(address account, uint256 blockNumber) external view returns (uint256 balance) {
        // Get the zero account point
        PointVoting memory uPoint = getUserPoint(account, 0);
        // Check that the zero point block number is not smaller than the specified blockNumber
        if (uPoint.blockNumber > 0 && blockNumber >= uPoint.blockNumber) {
            balance = IVEOLAS(ve).balanceOfAt(account, blockNumber);
        }
    }

    /// @dev Gets the `account`'s lock end time.
    /// @param account Account address.
    /// @return unlockTime Lock end time.
    function lockedEnd(address account) external view returns (uint256 unlockTime) {
        unlockTime = IVEOLAS(ve).lockedEnd(account);
    }

    /// @dev Gets total token supply.
    /// @return supply Total token supply.
    function totalSupply() external view returns (uint256 supply) {
        supply = IVEOLAS(ve).totalSupply();
    }

    /// @dev Gets total token supply at a specific block number.
    /// @param blockNumber Block number.
    /// @return supplyAt Supply at the specified block number.
    function totalSupplyAt(uint256 blockNumber) external view returns (uint256 supplyAt) {
        supplyAt = IVEOLAS(ve).totalSupplyAt(blockNumber);
    }

    /// @dev Calculates total voting power at time `ts` that must be greater than the last supply point timestamp.
    /// @param ts Time to get total voting power at.
    /// @return vPower Total voting power.
    function totalSupplyLockedAtT(uint256 ts) external view returns (uint256 vPower) {
        // Get the total number of supply points
        uint256 numPoints = IVEOLAS(ve).totalNumPoints();
        PointVoting memory sPoint = IVEOLAS(ve).mapSupplyPoints(numPoints);
        // Check the last supply point timestamp is not smaller than the specified ts
        if (ts >= sPoint.ts) {
            vPower = IVEOLAS(ve).totalSupplyLockedAtT(ts);
        } else {
            revert WrongTimestamp(sPoint.ts, ts);
        }
    }

    /// @dev Calculates current total voting power.
    /// @return vPower Total voting power.
    function totalSupplyLocked() external view returns (uint256 vPower) {
        vPower = IVEOLAS(ve).totalSupplyLocked();
    }

    /// @dev Calculate total voting power at some point in the past.
    /// @notice The requested block number must be at least equal to the veOLAS zero supply point block number.
    /// @param blockNumber Block number to calculate the total voting power at.
    /// @return vPower Total voting power.
    function getPastTotalSupply(uint256 blockNumber) external view returns (uint256 vPower) {
        vPower = IVEOLAS(ve).getPastTotalSupply(blockNumber);
    }

    /// @dev Gets the total number of supply points.
    /// @return numPoints Number of supply points.
    function totalNumPoints() external view returns (uint256 numPoints) {
        numPoints = IVEOLAS(ve).totalNumPoints();
    }

    /// @dev Gets information about the interface support.
    /// @param interfaceId A specified interface Id.
    /// @return True if this contract implements the interface defined by interfaceId.
    function supportsInterface(bytes4 interfaceId) external view returns (bool) {
        return IVEOLAS(ve).supportsInterface(interfaceId);
    }

    /// @dev Reverts the transfer of this token.
    function transfer(address, uint256) external returns (bool) {
        revert NonTransferable(ve);
    }

    /// @dev Reverts the approval of this token.
    function approve(address, uint256) external returns (bool) {
        revert NonTransferable(ve);
    }

    /// @dev Reverts the transferFrom of this token.
    function transferFrom(address, address, uint256) external returns (bool) {
        revert NonTransferable(ve);
    }

    /// @dev Reverts the allowance of this token.
    function allowance(address, address) external view returns (uint256) {
        revert NonTransferable(ve);
    }

    /// @dev Reverts delegates of this token.
    function delegates(address) external view returns (address) {
        revert NonDelegatable(ve);
    }

    /// @dev Reverts delegate for this token.
    function delegate(address) external
    {
        revert NonDelegatable(ve);
    }

    /// @dev Reverts delegateBySig for this token.
    function delegateBySig(address, uint256, uint256, uint8, bytes32, bytes32) external
    {
        revert NonDelegatable(ve);
    }

    /// @dev Reverts other calls such that the original veOLAS is used.
    fallback() external {
        revert ImplementedIn(ve);
    }
}