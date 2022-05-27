/**
 *Submitted for verification at Etherscan.io on 2022-05-27
*/

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.4;

/// @notice Gas optimized reentrancy protection for smart contracts
/// @author Modified from Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/ReentrancyGuard.sol)
/// License-Identifier: AGPL-3.0-only
abstract contract ReentrancyGuard {
    error Reentrancy();
    
    uint256 private locked = 1;

    modifier nonReentrant() {
        if (locked != 1) revert Reentrancy();
        
        locked = 2;
        _;
        locked = 1;
    }
}

/// @notice Vesting contract for KaliDAO tokens.
contract KaliDAOvesting is ReentrancyGuard {
    event ExtensionSet(address indexed dao, address[] accounts, uint256[] amounts, uint256[] startTimes, uint256[] endTimes);

    event ExtensionCalled(address indexed dao, uint256 vestingId, address indexed member, uint256 indexed amountOut);

    error NoArrayParity();

    error InvalidTimespan();

    error InsufficientAmount();

    error AmountNotSpanMultiple();

    error NotDAO();

    error NotVestee();

    error VestNotStarted();

    error VestExceeded();

    uint256 vestingCount;

    mapping(uint256 => Vesting) public vestings;

    struct Vesting {
        address dao;
        address account;
        uint128 depositAmount;
        uint128 withdrawAmount;
        uint128 rate;
        uint64 startTime;
        uint64 endTime;
    }

    function setExtension(bytes calldata extensionData) public nonReentrant virtual {
        (address[] memory accounts, uint256[] memory amounts, uint256[] memory startTimes, uint256[] memory endTimes) 
            = abi.decode(extensionData, (address[], uint256[], uint256[], uint256[]));
        
        if (accounts.length != amounts.length 
            || amounts.length != startTimes.length 
            || startTimes.length != endTimes.length) 
            revert NoArrayParity();

        // this is reasonably safe from overflow because incrementing `i` loop beyond
        // 'type(uint256).max' is exceedingly unlikely compared to optimization benefits,
        // and `timeDifference` is checked by reversion
        unchecked {
            for (uint256 i; i < accounts.length; i++) {
                if (startTimes[i] > endTimes[i]) revert InvalidTimespan();

                uint256 timeDifference = endTimes[i] - startTimes[i];

                if (amounts[i] > timeDifference) revert InsufficientAmount();

                if (amounts[i] % timeDifference != 0) revert AmountNotSpanMultiple();

                uint256 rate = amounts[i] / timeDifference;

                uint256 vestingId = vestingCount++;

                vestings[vestingId] = Vesting({
                    dao: msg.sender,
                    account: accounts[i],
                    depositAmount: uint128(amounts[i]),
                    withdrawAmount: 0,
                    rate: uint128(rate),
                    startTime: uint64(startTimes[i]),
                    endTime: uint64(endTimes[i])
                });
            }
        }

        emit ExtensionSet(msg.sender, accounts, amounts, startTimes, endTimes);
    }

    function callExtension(
        address account, 
        uint256 amount, 
        bytes calldata extensionData
    ) public nonReentrant virtual returns (bool mint, uint256 amountOut) {
        uint256 vestingId = abi.decode(extensionData, (uint256));

        Vesting storage vest = vestings[vestingId];

        if (msg.sender != vest.dao) revert NotDAO();

        if (account != vest.account) revert NotVestee();

        if (block.timestamp < vest.startTime) revert VestNotStarted();

        unchecked {
            uint256 timeDelta = block.timestamp - vest.startTime;

            uint256 vesteeBalance = (vest.rate * timeDelta) - uint256(vest.withdrawAmount);

            if (amount > vesteeBalance) revert VestExceeded();
        }

        // this is safe as amount is checked in above reversion
        unchecked {
            vest.withdrawAmount += uint128(amount);
        }

        (mint, amountOut) = (true, amount);

        emit ExtensionCalled(msg.sender, vestingId, account, amount);
    }
}