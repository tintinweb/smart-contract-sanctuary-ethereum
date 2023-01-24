// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "../wagers/IWagerModule.sol";

interface IWagerOracle {
    // -- methods --
    function getResult(Wager memory wager) external returns (bytes memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "../oracles/IWagerOracle.sol";

// -- structs --
struct Wager {
    address partyOne;
    bytes partyOneWager;
    address partyTwo;
    bytes partyTwoWager;
    uint256 partyWagerAmount;
    uint256 createdBlock;
    uint80 expirationBlock;
    WagerState state;
    IWagerModule wagerModule; // wager semantics
    IWagerOracle oracleImpl; // oracle impl
}

// -- wager states
enum WagerState {
    active,
    created,
    completed,
    voided
}

interface IWagerModule {
    // -- methods --
    function calculateWinner(Wager memory wager) external returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "../../interfaces/wagers/IWagerModule.sol";

/**
 @title HighLowWagerModule
 @author Henry Wrightman

 @notice wager module for the 1:1 'high-low' strategy
 */

contract HighLowWagerModule is IWagerModule {
    /// @notice calculateWinner
    /// @dev
    /// @param wager wager who's to be settled & their winner calculated
    /// @return address wager winner's address
    function calculateWinner(
        Wager memory wager
    ) external override returns (address) {
        bytes memory result = IWagerOracle(wager.oracleImpl).getResult(wager);
        int256 price = int(abi.decode(result, (uint256)));

        (
            uint256 partyOneWagerDirection,
            int256 partyOneWagerInitialPrice
        ) = decodeHighLowWager(wager.partyOneWager);
        (
            uint256 partyTwoWagerDirection,
            int256 partyTwoWagerInitialPrice
        ) = decodeHighLowWager(wager.partyTwoWager);

        if (partyOneWagerDirection == 1) {
            // partyOne bet high
            if (partyOneWagerInitialPrice >= price) {
                //partyOne wins
                return wager.partyOne;
            }
            return wager.partyTwo;
        } else {
            // partyTwo bet high
            if (partyTwoWagerInitialPrice >= price) {
                // partyTwo wins
                return wager.partyTwo;
            }
            return wager.partyOne;
        }
    }

    /// @notice decodeHighLowWager
    /// @dev HighLow wager data consists of <wagerDirection> (0 or 1 for high low) and <initialPrice> to compare against
    /// @param data supplemental data for HighLow wager's to be decoded
    /// @return wagerDirection wager direction (1 || 0)
    /// @return initialPrice initial price
    function decodeHighLowWager(
        bytes memory data
    ) public pure returns (uint256 wagerDirection, int256 initialPrice) {
        (wagerDirection, initialPrice) = abi.decode(data, (uint256, int256));
    }
}