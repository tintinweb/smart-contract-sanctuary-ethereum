// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.11;

import { Trust } from "@sense-finance/v1-utils/src/Trust.sol";
import { Errors } from "@sense-finance/v1-utils/src/libs/Errors.sol";
import { IPriceFeed } from "../../abstract/IPriceFeed.sol";

/// @notice This contract gets prices from an available oracle address which must implement IPriceFeed.sol
/// If there's no oracle set, it will try getting the price from Chainlink's Oracle.
/// @author Inspired by: https://github.com/Rari-Capital/fuse-v1/blob/development/src/oracles/MasterPriceOracle.sol
contract MasterPriceOracle is IPriceFeed, Trust {
    address public senseChainlinkPriceOracle;

    /// @dev Maps underlying token addresses to oracle addresses.
    mapping(address => address) public oracles;

    /// @dev Constructor to initialize state variables.
    /// @param _chainlinkOracle The underlying ERC20 token addresses to link to `_oracles`.
    /// @param _underlyings The underlying ERC20 token addresses to link to `_oracles`.
    /// @param _oracles The `PriceOracle` contracts to be assigned to `underlyings`.
    constructor(
        address _chainlinkOracle,
        address[] memory _underlyings,
        address[] memory _oracles
    ) public Trust(msg.sender) {
        senseChainlinkPriceOracle = _chainlinkOracle;

        // Input validation
        if (_underlyings.length != _oracles.length) revert Errors.InvalidParam();

        // Initialize state variables
        for (uint256 i = 0; i < _underlyings.length; i++) oracles[_underlyings[i]] = _oracles[i];
    }

    /// @dev Sets `_oracles` for `underlyings`.
    /// Caller of this function must make sure that the oracles being added return non-stale, greater than 0
    /// prices for all underlying tokens.
    function add(address[] calldata _underlyings, address[] calldata _oracles) external requiresTrust {
        if (_underlyings.length <= 0 || _underlyings.length != _oracles.length) revert Errors.InvalidParam();

        for (uint256 i = 0; i < _underlyings.length; i++) {
            oracles[_underlyings[i]] = _oracles[i];
        }
    }

    /// @dev Attempts to return the price in ETH of `underlying` (implements `BasePriceOracle`).
    function price(address underlying) external view override returns (uint256) {
        if (underlying == 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2) return 1e18; // Return 1e18 for WETH

        address oracle = oracles[underlying];
        if (oracle != address(0)) {
            return IPriceFeed(oracle).price(underlying);
        } else {
            // Try token/ETH from Sense's Chainlink Oracle
            try IPriceFeed(senseChainlinkPriceOracle).price(underlying) returns (uint256 price) {
                return price;
            } catch {
                revert Errors.PriceOracleNotFound();
            }
        }
    }

    /// @dev Sets the `senseChainlinkPriceOracle`.
    function setSenseChainlinkPriceOracle(address _senseChainlinkPriceOracle) public requiresTrust {
        senseChainlinkPriceOracle = _senseChainlinkPriceOracle;
        emit SenseChainlinkPriceOracleChanged(senseChainlinkPriceOracle);
    }

    /* ========== LOGS ========== */
    event SenseChainlinkPriceOracleChanged(address indexed senseChainlinkPriceOracle);
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