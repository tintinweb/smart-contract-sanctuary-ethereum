// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {Guarded} from "fiat/utils/Guarded.sol";
import {wdiv} from "fiat/utils/Math.sol";

import {IChainlinkValidator} from "../interfaces/IChainlinkValidator.sol";
import {AggregatorV3Interface} from "../interfaces/AggregatorV3Interface.sol";
import {IValidator} from "../interfaces/IValidator.sol";

contract ChainlinkValidator is Guarded, IValidator, IChainlinkValidator {
    /// ======== Custom Errors ======== ///

    error ChainlinkValidator__value_feedNotFound(address token);
    error ChainlinkValidator__validate_feedNotFound(address token);
    error ChainlinkValidator__validate_disputeWindowElapsed();
    error ChainlinkValidator__value_invalidTimestamp();

    /// ======== Storage ======== ///

    /// @notice Seconds until a proposed value becomes outdated [seconds]
    uint256 public immutable proposeWindow;

    /// @notice Seconds until a proposed value can not be disputed anymore [seconds]
    uint256 public immutable disputeWindow;

    // @notice Chainlink Feeds
    // Token => Chainlink Feed
    mapping(address => address) public feeds;

    /// ======== Events ======== ///

    event FeedSet(address token, address feed);
    event FeedUnset(address token);
    event Validate(address token, uint256 proposedValue, uint256 computedValue);

    /// @param proposeWindow_ Seconds until a proposed value becomes outdated [seconds]
    /// @param disputeWindow_ Seconds until a proposed value can not be disputed anymore [seconds]
    constructor(uint256 proposeWindow_, uint256 disputeWindow_) {
        proposeWindow = proposeWindow_;
        disputeWindow = disputeWindow_;
    }

    /// ======== Feed Configuration ======== ///

    /// @notice Sets a Chainlink feed for given token
    /// @param token Address of the token corresponding to the Chainlink feed
    /// @param feed Address of the Chainlink feed
    function setFeed(address token, address feed) external checkCaller {
        feeds[token] = feed;
        emit FeedSet(token, feed);
    }

    /// @notice Unsets a Chainlink feed associated with `token`
    /// @param token Address of the token
    function unsetFeed(address token) external checkCaller {
        delete feeds[token];
        emit FeedUnset(token);
    }

    /// ======== Validator Implementation ======== ///

    /// @notice Checks that the shift operation can be performed by the OptimisticOracle given a `prevNonce` and `nonce`
    /// - `prevNonce` has to be greater than `disputeWindow` to confirm it has passed and the value
    /// - `nonce` has to be less than `proposeWindow`
    /// @param prevNonce Nonce of the previous proposal [(roundId, roundTimestamp)]
    /// @param nonce Nonce of the current proposal [(roundId, roundTimestamp)]
    /// @return canShift True if shift operation can be performed
    function canShift(bytes32 prevNonce, bytes32 nonce)
        external
        view
        override(IValidator)
        returns (bool)
    {
        if (prevNonce != 0 && canDispute(prevNonce)) {
            return false;
        }
        return canPropose(nonce);
    }

    /// @notice Checks that the dispute operation can be performed by the OptimisticOracle given `nonce`
    /// - `nonce` has to be less than `disputeWindow`
    /// @param nonce Nonce of the current proposal [(roundId, roundTimestamp)]
    /// @return canDispute True if dispute operation can be performed
    function canDispute(bytes32 nonce)
        public
        view
        override(IValidator)
        returns (bool)
    {
        return (block.timestamp - decodeRoundTimestamp(nonce) <= disputeWindow);
    }

    /// @notice Checks that the propose operation can be performed by the OptimisticOracle given `nonce`
    /// - `nonce` has to be less than `proposeWindow`
    /// @param nonce Nonce of the current proposal [(roundId, roundTimestamp)]
    /// @return canPropose True if propose operation can be performed
    function canPropose(bytes32 nonce)
        public
        view
        override(IValidator)
        returns (bool)
    {
        return (block.timestamp - decodeRoundTimestamp(nonce) <= proposeWindow);
    }

    /// @notice Retrieves the latest spot price for a token from the corresponding Chainlink feed
    /// @dev Reverts if there is no feed for a given `token`
    /// @param token Address of the token for which to retrieve the spot rate
    /// @return value_ Spot price retrieved from the latest round data [wad]
    /// @return nonce Encoded roundId and roundTimestamp [(roundId, roundTimestamp)]
    function value(address token)
        external
        view
        override(IChainlinkValidator)
        returns (uint256 value_, bytes32 nonce)
    {
        address dataFeed = feeds[token];
        if (dataFeed == address(0)) {
            revert ChainlinkValidator__value_feedNotFound(token);
        }

        (
            uint80 roundId,
            int256 feedValue,
            ,
            uint256 roundTimestamp,

        ) = AggregatorV3Interface(dataFeed).latestRoundData();

        if (roundTimestamp > type(uint176).max) {
            revert ChainlinkValidator__value_invalidTimestamp();
        }

        // Convert value from Chainlink feed to wad precision
        unchecked {
            value_ = wdiv(
                uint256(feedValue),
                10**AggregatorV3Interface(dataFeed).decimals()
            );
        }
        // Encode roundId and roundTimestamp as nonce
        nonce = encodeNonce(uint256(roundId), roundTimestamp);
    }

    /// @notice Validates a `proposedValue` for given `nonce` via the corresponding Chainlink feed
    /// @dev Reverts if there is no feed `token`
    /// @param proposedValue Value to be validated [wad]
    /// @param token Address of the token for the `value_`
    /// @param nonce Nonce of the `value_` [(roundId, roundTimestamp)]
    /// @return valid True if `value_` is equal to computed value
    /// @return computedValue Value that was retrieved from the Chainlink feed [wad]
    function validate(
        uint256 proposedValue,
        address token,
        bytes32 nonce
    )
        external
        override(IChainlinkValidator)
        returns (bool valid, uint256 computedValue)
    {
        // Check the validity of the data feed
        address dataFeed = feeds[token];
        if (dataFeed == address(0)) {
            revert ChainlinkValidator__validate_feedNotFound(token);
        }

        // Retrieve and scale the data from the chainlink feed
        (
            ,
            int256 roundValue,
            ,
            uint256 roundTimestamp,

        ) = AggregatorV3Interface(dataFeed).getRoundData(
                uint80(decodeRoundId(nonce))
            );

        // Check the nonce round timestamp matches the feed round timestamp
        bool validTimestamp = roundTimestamp == decodeRoundTimestamp(nonce);

        // If the timestamp was not validated then fetch the data from the latest chainlink feed
        if (!validTimestamp) {
            (, roundValue, , , ) = AggregatorV3Interface(dataFeed)
                .latestRoundData();
        }

        // Values outside the dispute window are considered valid
        if (validTimestamp && !canDispute(nonce)) {
            revert ChainlinkValidator__validate_disputeWindowElapsed();
        }

        // Convert value from Chainlink feed to wad precision
        unchecked {
            computedValue = wdiv(
                uint256(roundValue),
                10**AggregatorV3Interface(dataFeed).decimals()
            );
        }

        // Check that the feed timestamp matches the nonce
        valid = validTimestamp && (proposedValue == computedValue);

        emit Validate(token, proposedValue, computedValue);
    }

    /// ======== Helper Methods ======== ///

    /// @notice Encodes `roundId` and `roundTimestamp` as a nonce
    /// @param roundId RoundId [uint80]
    /// @param roundTimestamp RoundTimestamp [uint176]
    /// @return nonce Encoded nonce
    function encodeNonce(uint256 roundId, uint256 roundTimestamp)
        public
        pure
        returns (bytes32)
    {
        return bytes32((roundId << 176) + roundTimestamp);
    }

    /// @notice Decodes `roundId` from `nonce`
    /// @param nonce Nonce value
    /// @return roundId Decoded `roundId`
    function decodeRoundId(bytes32 nonce) public pure returns (uint256) {
        uint256 mask = 2**(80) - 1;
        return uint256(nonce >> 176) & mask;
    }

    /// @notice Decodes `roundTimestamp` from `nonce`
    /// @param nonce Nonce value
    /// @return roundTimestamp Decoded `roundTimestamp`
    function decodeRoundTimestamp(bytes32 nonce) public pure returns (uint256) {
        uint256 mask = 2**(176) - 1;
        return uint256(nonce) & mask;
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

import {IGuarded} from "../interfaces/IGuarded.sol";

/// @title Guarded
/// @notice Mixin implementing an authentication scheme on a method level
abstract contract Guarded is IGuarded {
    /// ======== Custom Errors ======== ///

    error Guarded__notRoot();
    error Guarded__notGranted();

    /// ======== Storage ======== ///

    /// @notice Wildcard for granting a caller to call every guarded method
    bytes32 public constant override ANY_SIG = keccak256("ANY_SIG");
    /// @notice Wildcard for granting a caller to call every guarded method
    address public constant override ANY_CALLER = address(uint160(uint256(bytes32(keccak256("ANY_CALLER")))));

    /// @notice Mapping storing who is granted to which method
    /// @dev Method Signature => Caller => Bool
    mapping(bytes32 => mapping(address => bool)) private _canCall;

    /// ======== Events ======== ///

    event AllowCaller(bytes32 sig, address who);
    event BlockCaller(bytes32 sig, address who);

    constructor() {
        // set root
        _setRoot(msg.sender);
    }

    /// ======== Auth ======== ///

    modifier callerIsRoot() {
        if (_canCall[ANY_SIG][msg.sender]) {
            _;
        } else revert Guarded__notRoot();
    }

    modifier checkCaller() {
        if (canCall(msg.sig, msg.sender)) {
            _;
        } else revert Guarded__notGranted();
    }

    /// @notice Grant the right to call method `sig` to `who`
    /// @dev Only the root user (granted `ANY_SIG`) is able to call this method
    /// @param sig Method signature (4Byte)
    /// @param who Address of who should be able to call `sig`
    function allowCaller(bytes32 sig, address who) public override callerIsRoot {
        _canCall[sig][who] = true;
        emit AllowCaller(sig, who);
    }

    /// @notice Revoke the right to call method `sig` from `who`
    /// @dev Only the root user (granted `ANY_SIG`) is able to call this method
    /// @param sig Method signature (4Byte)
    /// @param who Address of who should not be able to call `sig` anymore
    function blockCaller(bytes32 sig, address who) public override callerIsRoot {
        _canCall[sig][who] = false;
        emit BlockCaller(sig, who);
    }

    /// @notice Returns if `who` can call `sig`
    /// @param sig Method signature (4Byte)
    /// @param who Address of who should be able to call `sig`
    function canCall(bytes32 sig, address who) public view override returns (bool) {
        return (_canCall[sig][who] || _canCall[ANY_SIG][who] || _canCall[sig][ANY_CALLER]);
    }

    /// @notice Sets the root user (granted `ANY_SIG`)
    /// @param root Address of who should be set as root
    function _setRoot(address root) internal {
        _canCall[ANY_SIG][root] = true;
        emit AllowCaller(ANY_SIG, root);
    }

    /// @notice Unsets the root user (granted `ANY_SIG`)
    /// @param root Address of who should be unset as root
    function _unsetRoot(address root) internal {
        _canCall[ANY_SIG][root] = false;
        emit AllowCaller(ANY_SIG, root);
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2020 Maker Ecosystem Growth Holdings, INC.
pragma solidity ^0.8.4;

uint256 constant MLN = 10**6;
uint256 constant BLN = 10**9;
uint256 constant WAD = 10**18;
uint256 constant RAY = 10**18;
uint256 constant RAD = 10**18;

/* solhint-disable func-visibility, no-inline-assembly */

error Math__toInt256_overflow(uint256 x);

function toInt256(uint256 x) pure returns (int256) {
    if (x > uint256(type(int256).max)) revert Math__toInt256_overflow(x);
    return int256(x);
}

function min(uint256 x, uint256 y) pure returns (uint256 z) {
    unchecked {
        z = x <= y ? x : y;
    }
}

function max(uint256 x, uint256 y) pure returns (uint256 z) {
    unchecked {
        z = x >= y ? x : y;
    }
}

error Math__diff_overflow(uint256 x, uint256 y);

function diff(uint256 x, uint256 y) pure returns (int256 z) {
    unchecked {
        z = int256(x) - int256(y);
        if (!(int256(x) >= 0 && int256(y) >= 0)) revert Math__diff_overflow(x, y);
    }
}

error Math__add_overflow(uint256 x, uint256 y);

function add(uint256 x, uint256 y) pure returns (uint256 z) {
    unchecked {
        if ((z = x + y) < x) revert Math__add_overflow(x, y);
    }
}

error Math__add48_overflow(uint256 x, uint256 y);

function add48(uint48 x, uint48 y) pure returns (uint48 z) {
    unchecked {
        if ((z = x + y) < x) revert Math__add48_overflow(x, y);
    }
}

error Math__add_overflow_signed(uint256 x, int256 y);

function add(uint256 x, int256 y) pure returns (uint256 z) {
    unchecked {
        z = x + uint256(y);
        if (!(y >= 0 || z <= x)) revert Math__add_overflow_signed(x, y);
        if (!(y <= 0 || z >= x)) revert Math__add_overflow_signed(x, y);
    }
}

error Math__sub_overflow(uint256 x, uint256 y);

function sub(uint256 x, uint256 y) pure returns (uint256 z) {
    unchecked {
        if ((z = x - y) > x) revert Math__sub_overflow(x, y);
    }
}

error Math__sub_overflow_signed(uint256 x, int256 y);

function sub(uint256 x, int256 y) pure returns (uint256 z) {
    unchecked {
        z = x - uint256(y);
        if (!(y <= 0 || z <= x)) revert Math__sub_overflow_signed(x, y);
        if (!(y >= 0 || z >= x)) revert Math__sub_overflow_signed(x, y);
    }
}

error Math__mul_overflow(uint256 x, uint256 y);

function mul(uint256 x, uint256 y) pure returns (uint256 z) {
    unchecked {
        if (!(y == 0 || (z = x * y) / y == x)) revert Math__mul_overflow(x, y);
    }
}

error Math__mul_overflow_signed(uint256 x, int256 y);

function mul(uint256 x, int256 y) pure returns (int256 z) {
    unchecked {
        z = int256(x) * y;
        if (int256(x) < 0) revert Math__mul_overflow_signed(x, y);
        if (!(y == 0 || z / y == int256(x))) revert Math__mul_overflow_signed(x, y);
    }
}

function wmul(uint256 x, uint256 y) pure returns (uint256 z) {
    unchecked {
        z = mul(x, y) / WAD;
    }
}

function wmul(uint256 x, int256 y) pure returns (int256 z) {
    unchecked {
        z = mul(x, y) / int256(WAD);
    }
}

error Math__div_overflow(uint256 x, uint256 y);

function div(uint256 x, uint256 y) pure returns (uint256 z) {
    unchecked {
        if (y == 0) revert Math__div_overflow(x, y);
        return x / y;
    }
}

function wdiv(uint256 x, uint256 y) pure returns (uint256 z) {
    unchecked {
        z = mul(x, WAD) / y;
    }
}

// optimized version from dss PR #78
function wpow(
    uint256 x,
    uint256 n,
    uint256 b
) pure returns (uint256 z) {
    unchecked {
        assembly {
            switch n
            case 0 {
                z := b
            }
            default {
                switch x
                case 0 {
                    z := 0
                }
                default {
                    switch mod(n, 2)
                    case 0 {
                        z := b
                    }
                    default {
                        z := x
                    }
                    let half := div(b, 2) // for rounding.
                    for {
                        n := div(n, 2)
                    } n {
                        n := div(n, 2)
                    } {
                        let xx := mul(x, x)
                        if shr(128, x) {
                            revert(0, 0)
                        }
                        let xxRound := add(xx, half)
                        if lt(xxRound, xx) {
                            revert(0, 0)
                        }
                        x := div(xxRound, b)
                        if mod(n, 2) {
                            let zx := mul(z, x)
                            if and(iszero(iszero(x)), iszero(eq(div(zx, x), z))) {
                                revert(0, 0)
                            }
                            let zxRound := add(zx, half)
                            if lt(zxRound, zx) {
                                revert(0, 0)
                            }
                            z := div(zxRound, b)
                        }
                    }
                }
            }
        }
    }
}

/* solhint-disable func-visibility, no-inline-assembly */

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IValidator} from "./IValidator.sol";

interface IChainlinkValidator {
    function value(address token) external view returns (uint256, bytes32);

    function validate(
        uint256 value_,
        address token,
        bytes32 nonce
    ) external returns (bool, uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @notice Copied from:
/// https://github.com/smartcontractkit/chainlink/blob/develop/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol
/// at commit a64a7fc38b647c490416091bccf39e85ded3961d
interface AggregatorV3Interface {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    function getRoundData(uint80 _roundId)
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

interface IValidator {
    function canShift(bytes32 prevNonce, bytes32 nonce)
        external
        view
        returns (bool);

    function canPropose(bytes32 nonce) external view returns (bool);

    function canDispute(bytes32 nonce) external view returns (bool);
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.4;

interface IGuarded {
    function ANY_SIG() external view returns (bytes32);

    function ANY_CALLER() external view returns (address);

    function allowCaller(bytes32 sig, address who) external;

    function blockCaller(bytes32 sig, address who) external;

    function canCall(bytes32 sig, address who) external view returns (bool);
}