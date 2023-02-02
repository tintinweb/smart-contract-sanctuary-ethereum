// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SignedMath.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard signed math utilities missing in the Solidity language.
 */
library SignedMath {
    /**
     * @dev Returns the largest of two signed numbers.
     */
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two signed numbers.
     */
    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two signed numbers without overflow.
     * The result is rounded towards zero.
     */
    function average(int256 a, int256 b) internal pure returns (int256) {
        // Formula from the book "Hacker's Delight"
        int256 x = (a & b) + ((a ^ b) >> 1);
        return x + (int256(uint256(x) >> 255) & (a ^ b));
    }

    /**
     * @dev Returns the absolute unsigned value of a signed value.
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
        }
    }
}

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
    bytes parties; // party data; |partyOne|partyTwo|
    bytes partyOneWagerData; // wager data; e.g |wagerStart|wagerValue|
    bytes partyTwoWagerData;
    uint256 wagerAmount;
    bytes blockData; // blocktime data; |created|expiration|enterLimit|
    bytes wagerOracleData; // ancillary wager data
    bytes supplumentalWagerOracleData; // supplumental wager data
    bytes result; // wager outcome
    WagerState state;
    IWagerModule wagerModule; // wager semantics
    IWagerOracle oracleModule; // oracle module semantics
    address oracleSource; // oracle source
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
    function settle(
        Wager memory wager
    ) external returns (Wager memory, address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "../../interfaces/wagers/IWagerModule.sol";
import "@openzeppelin/contracts/utils/math/SignedMath.sol";

/**
 @title NearestWagerModule
 @author Henry Wrightman

 @notice wager module for the 1:1 'nearest-price' strategy
 */

contract NearestWagerModule is IWagerModule {
    /// @notice settle
    /// @dev
    /// @param wager wager who's to be settled & their winner calculated
    /// @return wager wager with the result & winner, address of winner
    function settle(
        Wager memory wager
    ) external override returns (Wager memory, address) {
        bytes memory result = IWagerOracle(wager.oracleModule).getResult(wager);
        wager.result = result;
        int256 price = int(abi.decode(result, (uint256)));
        address winner;
        (address partyOne, address partyTwo) = abi.decode(
            wager.parties,
            (address, address)
        );

        uint256 partyOneWagerPrice = decodeNearestWager(
            wager.partyOneWagerData
        );
        uint256 partyTwoWagerPrice = decodeNearestWager(
            wager.partyTwoWagerData
        );

        uint256 wagerOneDiff = SignedMath.abs(price - int(partyOneWagerPrice));
        uint256 wagerTwoDiff = SignedMath.abs(price - int(partyTwoWagerPrice));

        if (wagerOneDiff <= wagerTwoDiff) {
            // wagerOne wins
            winner = partyOne;
        } else {
            // wagerTwo wins
            winner = partyTwo;
        }

        return (wager, winner);
    }

    /// @notice decodeNearestWager
    /// @dev Nearest wager data consists of <wagerPrice> or the player's guestimate price when the executionBlock is mined
    /// @param data supplemental data for Nearest wager's to be decoded
    /// @return wagerPrice wager price
    function decodeNearestWager(
        bytes memory data
    ) public pure returns (uint256 wagerPrice) {
        (wagerPrice) = abi.decode(data, (uint256));
    }
}