// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.11;

import { Trust } from "@sense-finance/v1-utils/src/Trust.sol";
import { Errors } from "@sense-finance/v1-utils/src/libs/Errors.sol";
import { IPriceFeed } from "../../abstract/IPriceFeed.sol";
import { FixedMath } from "../../../external/FixedMath.sol";

interface FeedRegistryLike {
    function latestRoundData(address base, address quote)
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

    function decimals(address base, address quote) external view returns (uint8);
}

/// @title ChainlinkPriceOracle
/// @notice Returns prices from Chainlink.
/// @dev Implements `IPricefeed` and `Trust`.
/// @author Inspired by: https://github.com/Rari-Capital/fuse-v1/blob/development/src/oracles/ChainlinkPriceOracleV3.sol
contract ChainlinkPriceOracle is IPriceFeed, Trust {
    using FixedMath for uint256;

    // Chainlink's denominations
    address public constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address public constant BTC = 0xbBbBBBBbbBBBbbbBbbBbbbbBBbBbbbbBbBbbBBbB;
    address public constant USD = address(840);

    // The maxmimum number of seconds elapsed since the round was last updated before the price is considered stale. If set to 0, no limit is enforced.
    uint256 public maxSecondsBeforePriceIsStale;

    FeedRegistryLike public feedRegistry = FeedRegistryLike(0x47Fb2585D2C56Fe188D0E6ec628a38b74fCeeeDf); // Chainlink feed registry contract

    constructor(uint256 _maxSecondsBeforePriceIsStale) public Trust(msg.sender) {
        maxSecondsBeforePriceIsStale = _maxSecondsBeforePriceIsStale;
    }

    /// @dev Internal function returning the price in ETH of `underlying`.
    function _price(address underlying) internal view returns (uint256) {
        // Return 1e18 for WETH
        if (underlying == 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2) return 1e18;

        // Try token/ETH to get token/ETH
        try feedRegistry.latestRoundData(underlying, ETH) returns (
            uint80,
            int256 tokenEthPrice,
            uint256,
            uint256 updatedAt,
            uint80
        ) {
            if (tokenEthPrice <= 0) return 0;
            _validatePrice(updatedAt);
            return uint256(tokenEthPrice).fmul(1e18).fdiv(10**uint256(feedRegistry.decimals(underlying, ETH)));
        } catch Error(string memory reason) {
            if (keccak256(abi.encodePacked(reason)) != keccak256(abi.encodePacked("Feed not found")))
                revert Errors.AttemptFailed();
        }

        // Try token/USD to get token/ETH
        try feedRegistry.latestRoundData(underlying, USD) returns (
            uint80,
            int256 tokenUsdPrice,
            uint256,
            uint256 updatedAt,
            uint80
        ) {
            if (tokenUsdPrice <= 0) return 0;
            _validatePrice(updatedAt);

            int256 ethUsdPrice;
            (, ethUsdPrice, , updatedAt, ) = feedRegistry.latestRoundData(ETH, USD);
            if (ethUsdPrice <= 0) return 0;
            _validatePrice(updatedAt);
            return
                uint256(tokenUsdPrice).fmul(1e26).fdiv(10**uint256(feedRegistry.decimals(underlying, USD))).fdiv(
                    uint256(ethUsdPrice)
                );
        } catch Error(string memory reason) {
            if (keccak256(abi.encodePacked(reason)) != keccak256(abi.encodePacked("Feed not found")))
                revert Errors.AttemptFailed();
        }

        // Try token/BTC to get token/ETH
        try feedRegistry.latestRoundData(underlying, BTC) returns (
            uint80,
            int256 tokenBtcPrice,
            uint256,
            uint256 updatedAt,
            uint80
        ) {
            if (tokenBtcPrice <= 0) return 0;
            _validatePrice(updatedAt);

            int256 btcEthPrice;
            (, btcEthPrice, , updatedAt, ) = feedRegistry.latestRoundData(BTC, ETH);
            if (btcEthPrice <= 0) return 0;
            _validatePrice(updatedAt);

            return
                uint256(tokenBtcPrice).fmul(uint256(btcEthPrice)).fdiv(
                    10**uint256(feedRegistry.decimals(underlying, BTC))
                );
        } catch Error(string memory reason) {
            if (keccak256(abi.encodePacked(reason)) != keccak256(abi.encodePacked("Feed not found")))
                revert Errors.AttemptFailed();
        }

        // Revert if all else fails
        revert Errors.PriceOracleNotFound();
    }

    /// @dev validates the price returned from Chainlink
    function _validatePrice(uint256 _updatedAt) internal view {
        if (maxSecondsBeforePriceIsStale > 0 && block.timestamp <= _updatedAt + maxSecondsBeforePriceIsStale)
            revert Errors.InvalidPrice();
    }

    /// @dev Returns the price in ETH of `underlying` (implements `BasePriceOracle`).
    function price(address underlying) external view override returns (uint256) {
        return _price(underlying);
    }

    /// @dev Sets the `maxSecondsBeforePriceIsStale`.
    function setMaxSecondsBeforePriceIsStale(uint256 _maxSecondsBeforePriceIsStale) public requiresTrust {
        maxSecondsBeforePriceIsStale = _maxSecondsBeforePriceIsStale;
        emit MaxSecondsBeforePriceIsStaleChanged(maxSecondsBeforePriceIsStale);
    }

    /* ========== LOGS ========== */
    event MaxSecondsBeforePriceIsStaleChanged(uint256 indexed maxSecondsBeforePriceIsStale);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.7.0;

/// @notice Ultra minimal authorization logic for smart contracts.
/// @author From https://github.com/Rari-Capital/solmate/blob/fab107565a51674f3a3b5bfdaacc67f6179b1a9b/src/auth/Trust.sol
abstract contract Trust {
    event UserTrustUpdated(address indexed user, bool trusted);

    mapping(address => bool) public isTrusted;

    constructor(address initialUser) {
        isTrusted[initialUser] = true;

        emit UserTrustUpdated(initialUser, true);
    }

    function setIsTrusted(address user, bool trusted) public virtual requiresTrust {
        isTrusted[user] = trusted;

        emit UserTrustUpdated(user, trusted);
    }

    modifier requiresTrust() {
        require(isTrusted[msg.sender], "UNTRUSTED");

        _;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.4;

library Errors {
    // Auth
    error CombineRestricted();
    error IssuanceRestricted();
    error NotAuthorized();
    error OnlyYT();
    error OnlyDivider();
    error OnlyPeriphery();
    error OnlyPermissionless();
    error RedeemRestricted();
    error Untrusted();

    // Adapters
    error TokenNotSupported();
    error FlashCallbackFailed();
    error SenderNotEligible();
    error TargetMismatch();
    error TargetNotSupported();
    error InvalidAdapterType();
    error PriceOracleNotFound();

    // Divider
    error AlreadySettled();
    error CollectNotSettled();
    error GuardCapReached();
    error IssuanceFeeCapExceeded();
    error IssueOnSettle();
    error NotSettled();

    // Input & validations
    error AlreadyInitialized();
    error DuplicateSeries();
    error ExistingValue();
    error InvalidAdapter();
    error InvalidMaturity();
    error InvalidParam();
    error NotImplemented();
    error OutOfWindowBoundaries();
    error SeriesDoesNotExist();
    error SwapTooSmall();
    error TargetParamsNotSet();
    error PoolParamsNotSet();
    error PTParamsNotSet();
    error AttemptFailed();
    error InvalidPrice();
    error BadContractInteration();

    // Periphery
    error FactoryNotSupported();
    error FlashBorrowFailed();
    error FlashUntrustedBorrower();
    error FlashUntrustedLoanInitiator();
    error UnexpectedSwapAmount();
    error TooMuchLeftoverTarget();

    // Fuse
    error AdapterNotSet();
    error FailedBecomeAdmin();
    error FailedAddTargetMarket();
    error FailedToAddPTMarket();
    error FailedAddLpMarket();
    error OracleNotReady();
    error PoolAlreadyDeployed();
    error PoolNotDeployed();
    error PoolNotSet();
    error SeriesNotQueued();
    error TargetExists();
    error TargetNotInFuse();

    // Tokens
    error MintFailed();
    error RedeemFailed();
    error TransferFailed();
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.11;

/// @title IPriceFeed
/// @notice Returns prices of underlying tokens
/// @author Taken from: https://github.com/Rari-Capital/fuse-v1/blob/development/src/oracles/BasePriceOracle.sol
interface IPriceFeed {
    /// @notice Get the price of an underlying asset.
    /// @param underlying The underlying asset to get the price of.
    /// @return price The underlying asset price in ETH as a mantissa (scaled by 1e18).
    /// Zero means the price is unavailable.
    function price(address underlying) external view returns (uint256 price);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.11;

/// @title Fixed point arithmetic library
/// @author Taken from https://github.com/Rari-Capital/solmate/blob/main/src/utils/FixedPointMathLib.sol
library FixedMath {
    uint256 internal constant WAD = 1e18;
    uint256 internal constant RAY = 1e27;

    function fmul(
        uint256 x,
        uint256 y,
        uint256 baseUnit
    ) internal pure returns (uint256) {
        return mulDivDown(x, y, baseUnit); // Equivalent to (x * y) / baseUnit rounded down.
    }

    function fmul(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, y, WAD); // Equivalent to (x * y) / WAD rounded down.
    }

    function fmulUp(
        uint256 x,
        uint256 y,
        uint256 baseUnit
    ) internal pure returns (uint256) {
        return mulDivUp(x, y, baseUnit); // Equivalent to (x * y) / baseUnit rounded up.
    }

    function fmulUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, y, WAD); // Equivalent to (x * y) / WAD rounded up.
    }

    function fdiv(
        uint256 x,
        uint256 y,
        uint256 baseUnit
    ) internal pure returns (uint256) {
        return mulDivDown(x, baseUnit, y); // Equivalent to (x * baseUnit) / y rounded down.
    }

    function fdiv(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, WAD, y); // Equivalent to (x * WAD) / y rounded down.
    }

    function fdivUp(
        uint256 x,
        uint256 y,
        uint256 baseUnit
    ) internal pure returns (uint256) {
        return mulDivUp(x, baseUnit, y); // Equivalent to (x * baseUnit) / y rounded up.
    }

    function fdivUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, WAD, y); // Equivalent to (x * WAD) / y rounded up.
    }

    function mulDivDown(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
            if iszero(and(iszero(iszero(denominator)), or(iszero(x), eq(div(z, x), y)))) {
                revert(0, 0)
            }

            // Divide z by the denominator.
            z := div(z, denominator)
        }
    }

    function mulDivUp(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
            if iszero(and(iszero(iszero(denominator)), or(iszero(x), eq(div(z, x), y)))) {
                revert(0, 0)
            }

            // First, divide z - 1 by the denominator and add 1.
            // We allow z - 1 to underflow if z is 0, because we multiply the
            // end result by 0 if z is zero, ensuring we return 0 if z is zero.
            z := mul(iszero(iszero(z)), add(div(sub(z, 1), denominator), 1))
        }
    }
}