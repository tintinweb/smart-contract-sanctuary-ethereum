/**
 *Submitted for verification at Etherscan.io on 2022-03-18
*/

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.4;

/// @notice Safe ERC-20 transfer/from library that gracefully handles missing return values
/// @author Modified from Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// License-Identifier: AGPL-3.0-only
library SafeTransferTokenLib {
    error TransferFailed();
    error TransferFromFailed();

    function _safeTransfer(
        address token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // get a pointer to some free memory
            let freeMemoryPointer := mload(0x40)
            // write the abi-encoded calldata into memory, beginning with the function selector
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // append the 'to' argument
            mstore(add(freeMemoryPointer, 36), amount) // append the 'amount' argument

            success := and(
                // set success to whether the call reverted, if not we check it either
                // returned exactly 1 (not just any non-zero data), or had no return data
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // we use 68 because the length of our calldata totals up like so: 4 + 32 * 2
                // we use 0 and 32 to copy up to 32 bytes of return data into the scratch space
                // counterintuitively, this call must be positioned second to the addition in the
                // order of operations or else returndatasize() will be zero during the computation
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        if (!success) revert TransferFailed();
    }

    function _safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // get a pointer to some free memory
            let freeMemoryPointer := mload(0x40)

            // write the abi-encoded calldata into memory, beginning with the function selector
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), from) // append the 'from' argument
            mstore(add(freeMemoryPointer, 36), to) // append the 'to' argument
            mstore(add(freeMemoryPointer, 68), amount) // append the 'amount' argument

            success := and(
                // set success to whether the call reverted, if not we check it either
                // returned exactly 1 (not just any non-zero data), or had no return data
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // we use 100 because the length of our calldata totals up like so: 4 + 32 * 3
                // we use 0 and 32 to copy up to 32 bytes of return data into the scratch space
                // counterintuitively, this call must be positioned second to the addition in the
                // order of operations or else returndatasize() will be zero during the computation
                call(gas(), token, 0, freeMemoryPointer, 100, 0, 32)
            )
        }

        if (!success) revert TransferFromFailed();
    }
}

/// @notice Gas optimized reentrancy protection for smart contracts
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/ReentrancyGuard.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol)
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

/// @notice Escrow for justiciable bets. 
/// @author 0xfoobar
contract BetEscrow is ReentrancyGuard {
    /// -----------------------------------------------------------------------
    /// Library Usage
    /// -----------------------------------------------------------------------

    using SafeTransferTokenLib for address;

    /// -----------------------------------------------------------------------
    /// Events
    /// -----------------------------------------------------------------------

    event BetOffered(uint256 betId);

    /// -----------------------------------------------------------------------
    /// Errors
    /// -----------------------------------------------------------------------

    error NotPlayerA();
    error NotPlayerB();
    error NotAdjudicator();
    error NotOffered();
    error NotAccepted();

    /// -----------------------------------------------------------------------
    /// Bet Storage
    /// -----------------------------------------------------------------------

    uint256 private nextBetId = 1;

    mapping(uint256 => Bet) public bets;

    enum Status {
        Offered,
        Accepted,
        Settled
    }

    enum Outcome {
        A,
        B,
        Neutral
    }

    struct Bet {
        address playerA;
        address playerB;
        address adjudicator;
        address token;
        uint256 amount;
        Status status;
    }

    /// -----------------------------------------------------------------------
    /// Bet Offer
    /// -----------------------------------------------------------------------

    function offerBet(
        address playerB, 
        address adjudicator, 
        address token, 
        uint256 amount
    ) external payable nonReentrant returns (uint256 betId) {
        // this won't overflow on human timescales
        unchecked {
            betId = nextBetId++;
        }

        bets[betId] = Bet({
            playerA: msg.sender,
            playerB: playerB,
            adjudicator: adjudicator,
            token: token,
            amount: amount,
            status: Status.Offered
        });
        // deposit bet
        token._safeTransferFrom(msg.sender, address(this), amount);
        emit BetOffered(nextBetId);
    }

    function withdrawOffer(uint256 betId) external payable nonReentrant {
        Bet memory bet = bets[betId];
        if (msg.sender != bet.playerA) revert NotPlayerA();
        if (bet.status != Status.Offered) revert NotOffered();
        // refund bet
        bet.token._safeTransfer(msg.sender, bet.amount);
        delete bets[betId];
    }

    /// -----------------------------------------------------------------------
    /// Bet Acceptance
    /// -----------------------------------------------------------------------

    function acceptBet(uint256 betId) external payable {
        Bet memory bet = bets[betId];
        if (msg.sender != bet.playerB) revert NotPlayerB();
        if (bet.status != Status.Offered) revert NotOffered();
        // match bet
        bets[betId].status = Status.Accepted;
        bet.token._safeTransferFrom(msg.sender, address(this), bet.amount);
    }

    // -----------------------------------------------------------------------
    /// Bet Settlement
    /// -----------------------------------------------------------------------

    function settleBet(uint256 betId, Outcome outcome) external payable nonReentrant {
        Bet memory bet = bets[betId];
        if (msg.sender != bet.adjudicator) revert NotAdjudicator();
        if (bet.status != Status.Accepted) revert NotAccepted();
        // distribute bets
        if (outcome == Outcome.A) {
            bet.token._safeTransfer(bet.playerA, 2 * bet.amount);
        } else if (outcome == Outcome.B) {
            bet.token._safeTransfer(bet.playerB, 2 * bet.amount);
        } else {
            bet.token._safeTransfer(bet.playerA, bet.amount);
            bet.token._safeTransfer(bet.playerB, bet.amount);
        }

        bets[betId].status = Status.Settled;
    }
}