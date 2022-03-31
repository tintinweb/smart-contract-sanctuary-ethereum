// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;

import "./interfaces/IRiskProviderRegistry.sol";
import "./shared/SpoolOwnable.sol";

import "./interfaces/IFeeHandler.sol";

/**
 * @dev Implementation of the {IRiskProviderRegistry} interface.
 *
 * @notice
 * This implementation acts as a simple registry contract permitting a
 * designated party (the owner) to toggle the validity of providers within
 * it.
 *
 * In turn, these providers are able to set a risk score for the strategies
 * they want that needs to be in the range [-10.0, 10.0].
 */
contract RiskProviderRegistry is IRiskProviderRegistry, SpoolOwnable {
    /* ========== CONSTANTS ========== */

    /// @notice Maximum strategy risk score
    /// @dev Risk score has 1 decimal accuracy, so value 100 represents 10.0
    uint8 public constant MAX_RISK_SCORE = 100;

    /* ========== STATE VARIABLES ========== */

    /// @notice fee handler contracts, to manage the risk provider fees
    IFeeHandler public immutable feeHandler;

    /// @notice Association of a risk provider to a strategy and finally to a risk score [0, 100]
    mapping(address => mapping(address => uint8)) private _risk;

    /// @notice Status of a risk provider
    mapping(address => bool) private _provider;

    /* ========== CONSTRUCTOR ========== */

    /**
     * @notice Initialize contract, set spool owner
     *
     * @param _feeHandler to manage the risk provider fees
     * @param _spoolOwner the spool owner contract
     */
    constructor(
        IFeeHandler _feeHandler,
        ISpoolOwner _spoolOwner
    )
        SpoolOwnable(_spoolOwner)
    {
        require(address(_feeHandler) != address(0), "RiskProviderRegistry::constructor: Fee Handler address cannot be 0");
        feeHandler = _feeHandler;
    }

    /* ========== VIEWS ========== */

    /**
     * @notice Returns whether or not a particular address is a risk provider.
     *
     * @param provider provider address to check
     *
     * @return boolean indicating entry in _provider
     */
    function isProvider(address provider) public view override returns (bool) {
        return _provider[provider];
    }

    /**
     * @notice Returns the risk scores of strateg(s) as defined by
     * the provided risk provider.
     *
     * @param riskProvider risk provider to get risk scores for 
     * @param strategies list of strategies that the risk provider has set risks for
     *
     * @return risk scores
     */
    function getRisks(address riskProvider, address[] memory strategies)
        external
        view
        override
        returns (uint8[] memory)
    {
        uint8[] memory riskScores = new uint8[](strategies.length);
        for (uint256 i = 0; i < strategies.length; i++) {
            riskScores[i] = _risk[riskProvider][strategies[i]];
        }

        return riskScores;
    }

    /**
     * @notice Returns the risk score of a particular strategy as defined by
     * the provided risk provider.
     *
     * @param riskProvider risk provider to get risk scores for 
     * @param strategy strategy that the risk provider has set risk for
     *
     * @return risk score
     */
    function getRisk(address riskProvider, address strategy)
        external
        view
        override
        returns (uint8)
    {
        return _risk[riskProvider][strategy];
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
     * @notice Allows the risk score of multiple strategies to be set.
     *
     * @dev
     * Requirements:
     * - the caller must be a risk provider
     * - input arrays must have the same length
     *
     * @param strategies list of strategies to set risk scores for
     * @param riskScores list of risk scores to set on each strategy
     */
    function setRisks(address[] memory strategies, uint8[] memory riskScores) external {
        require(
            isProvider(msg.sender),
            "RiskProviderRegistry::setRisks: Insufficient Privileges"
        );

        require(
            strategies.length == riskScores.length,
            "RiskProviderRegistry::setRisks: Strategies and risk scores lengths don't match"
        );    

        for (uint i = 0; i < strategies.length; i++) {
            _setRisk(strategies[i], riskScores[i]);
        }
    }

    /**
     * @notice Allows the risk score of a strategy to be set.
     *
     * @dev
     * Requirements:
     * - the caller must be a valid risk provider
     *
     * @param strategy strategy to set risk score for
     * @param riskScore risk score to set on the strategy
     */
    function setRisk(address strategy, uint8 riskScore) external {
        require(
            isProvider(msg.sender),
            "RiskProviderRegistry::setRisk: Insufficient Privileges"
        );

        _setRisk(strategy, riskScore);
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    /**
     * @notice Allows the inclusion of a new provider to the registry.
     *
     * @dev
     * Emits a {ProviderAdded} event indicating the newly added provider.
     *
     * Requirements:
     * - the caller must be the owner of the contract
     * - the provider must not already exist in the registry
     *
     * @param provider provider to add
     * @param fee fee to go to provider
     */
    function addProvider(address provider, uint16 fee) external onlyOwner {
        require(
            !_provider[provider],
            "RiskProviderRegistry::addProvider: Provider already exists"
        );

        _provider[provider] = true;
        feeHandler.setRiskProviderFee(provider, fee);

        emit ProviderAdded(provider);
    }

    /**
     * @notice Allows the removal of an existing provider to the registry.
     *
     * @dev
     * Emits a {ProviderRemoved} event indicating the address of the removed provider.
     * provider fee is also set to 0.
     *
     * Requirements:
     *
     * - the caller must be the owner of the contract
     * - the provider must already exist in the registry
     *
     * @param provider provider to remove
     */
    function removeProvider(address provider) external onlyOwner {
        require(
            _provider[provider],
            "RiskProviderRegistry::removeProvider: Provider does not exist"
        );

        _provider[provider] = false;
        feeHandler.setRiskProviderFee(provider, 0);

        emit ProviderRemoved(provider);
    }

    /* ========== PRIVATE FUNCTIONS ========== */

    /**
     * @notice Allows the risk score of a strategy to be set (internal)
     *
     * @dev
     * Emits a {RiskAssessed} event indicating the assessor of the score and the
     * newly set risk score of the strategy
     *
     * Requirements:
     *
     * - the risk score must be less than 100
     *
     * @param strategy strategy to set risk score for
     * @param riskScore risk score to set on the strategy
     */
    function _setRisk(address strategy, uint8 riskScore) private {
        require(riskScore <= MAX_RISK_SCORE, "RiskProviderRegistry::_setRisk: Risk score too big");

        _risk[msg.sender][strategy] = riskScore;

        emit RiskAssessed(msg.sender, strategy, riskScore);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;

import "../external/@openzeppelin/token/ERC20/IERC20.sol";

interface IFeeHandler {
    function payFees(
        IERC20 underlying,
        uint256 profit,
        address riskProvider,
        address vaultOwner,
        uint16 vaultFee
    ) external returns (uint256 feesPaid);

    function setRiskProviderFee(address riskProvider, uint16 fee) external;

    /* ========== EVENTS ========== */

    event FeesPaid(address indexed vault, uint profit, uint ecosystemCollected, uint treasuryCollected, uint riskProviderColected, uint vaultFeeCollected);
    event RiskProviderFeeUpdated(address indexed riskProvider, uint indexed fee);
    event EcosystemFeeUpdated(uint indexed fee);
    event TreasuryFeeUpdated(uint indexed fee);
    event EcosystemCollectorUpdated(address indexed collector);
    event TreasuryCollectorUpdated(address indexed collector);
    event FeeCollected(address indexed collector, IERC20 indexed underlying, uint amount);
    event EcosystemFeeCollected(IERC20 indexed underlying, uint amount);
    event TreasuryFeeCollected(IERC20 indexed underlying, uint amount);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;

import "../external/@openzeppelin/token/ERC20/IERC20.sol";

interface IRiskProviderRegistry {
    /* ========== FUNCTIONS ========== */

    function isProvider(address provider) external view returns (bool);

    function getRisk(address riskProvider, address strategy) external view returns (uint8);

    function getRisks(address riskProvider, address[] memory strategies) external view returns (uint8[] memory);

    /* ========== EVENTS ========== */

    event RiskAssessed(address indexed provider, address indexed strategy, uint8 riskScore);
    event ProviderAdded(address provider);
    event ProviderRemoved(address provider);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;

interface ISpoolOwner {
    function isSpoolOwner(address user) external view returns(bool);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;

import "../interfaces/ISpoolOwner.sol";

/// @title Logic to help check whether the caller is the Spool owner
abstract contract SpoolOwnable {
    /// @notice Contract that checks if address is Spool owner
    ISpoolOwner internal immutable spoolOwner;

    /**
     * @notice Sets correct initial values
     * @param _spoolOwner Spool owner contract address
     */
    constructor(ISpoolOwner _spoolOwner) {
        require(
            address(_spoolOwner) != address(0),
            "SpoolOwnable::constructor: Spool owner contract address cannot be 0"
        );

        spoolOwner = _spoolOwner;
    }

    /**
     * @notice Checks if caller is Spool owner
     * @return True if caller is Spool owner, false otherwise
     */
    function isSpoolOwner() internal view returns(bool) {
        return spoolOwner.isSpoolOwner(msg.sender);
    }


    /// @notice Checks and throws if caller is not Spool owner
    function _onlyOwner() private view {
        require(isSpoolOwner(), "SpoolOwnable::onlyOwner: Caller is not the Spool owner");
    }

    /// @notice Checks and throws if caller is not Spool owner
    modifier onlyOwner() {
        _onlyOwner();
        _;
    }
}