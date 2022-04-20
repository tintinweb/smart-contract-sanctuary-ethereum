// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import {SafeERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "./interfaces/badger/IVault.sol";
import "./interfaces/erc20/IERC20.sol";
import "./lib/GlobalAccessControlManaged.sol";
import "./lib/SafeERC20.sol";
import "./interfaces/citadel/IMedianOracle.sol";

/**
 * @notice Sells a token at a predetermined price to whitelisted buyers.
 * TODO: Better revert strings
 */
contract Funding is GlobalAccessControlManaged, ReentrancyGuardUpgradeable {
    using SafeERC20 for IERC20;

    // Roles used from GAC
    bytes32 public constant CONTRACT_GOVERNANCE_ROLE =
        keccak256("CONTRACT_GOVERNANCE_ROLE");
    bytes32 public constant POLICY_OPERATIONS_ROLE =
        keccak256("POLICY_OPERATIONS_ROLE");
    bytes32 public constant TREASURY_OPERATIONS_ROLE = keccak256("TREASURY_OPERATIONS_ROLE");
    bytes32 public constant TREASURY_VAULT_ROLE =
        keccak256("TREASURY_VAULT_ROLE");
    bytes32 public constant KEEPER_ROLE = keccak256("KEEPER_ROLE");

    uint256 public constant MAX_BPS = 10000;

    IERC20 public citadel; /// token to distribute (in vested xCitadel form)
    IVault public xCitadel; /// wrapped citadel form that is actually distributed
    IERC20 public asset; /// token to take in WBTC / bibbtc LP / CVX / bveCVX

    uint256 public citadelPriceInAsset; /// asset per citadel price eg. 1 WBTC (8 decimals) = 40,000 CTDL ==> price = 10^8 / 40,000
    uint256 public minCitadelPriceInAsset; /// Lower bound on expected citadel price in asset terms. Used as circuit breaker oracle.
    uint256 public maxCitadelPriceInAsset; /// Upper bound on expected citadel price in asset terms. Used as circuit breaker oracle.
    bool public citadelPriceFlag; /// Flag citadel price for review by guardian if it exceeds min and max bounds;

    uint256 public assetDecimalsNormalizationValue;

    address public citadelPriceInAssetOracle;
    address public saleRecipient;

    struct FundingParams {
        uint256 discount;
        uint256 minDiscount;
        uint256 maxDiscount;
        address discountManager;
        uint256 assetCumulativeFunded; /// persistent sum of asset amount in over lifetime of contract.
        uint256 assetCap; /// Max asset token that can be taken in by the contract (defines the cap for citadel sold)
    }

    FundingParams public funding;

    /// ==================
    /// ===== Events =====
    /// ==================

    // TODO: we should conform to some interface here
    event Deposit(
        address indexed buyer,
        uint256 assetIn,
        uint256 citadelOutValue
    );

    event CitadelPriceInAssetUpdated(uint256 citadelPrice);

    event CitadelPriceBoundsSet(uint256 minPrice, uint256 maxPrice);
    event CitadelPriceFlag(uint256 price, uint256 minPrice, uint256 maxPrice);

    event SaleRecipientUpdated(address indexed recipient);
    event AssetCapUpdated(uint256 assetCap);

    event Sweep(address indexed token, uint256 amount);
    event ClaimToTreasury(address indexed token, uint256 amount);

    modifier onlyCitadelPriceInAssetOracle() {
        require(
            msg.sender == citadelPriceInAssetOracle,
            "onlyCitadelPriceInAssetOracle"
        );
        _;
    }

    event DiscountLimitsSet(uint256 minDiscount, uint256 maxDiscount);
    event DiscountSet(uint256 discount);
    event DiscountManagerSet(address discountManager);

    /// =======================
    /// ===== Initializer =====
    /// =======================

    /**
     * @notice Initializer.
     * @param _gac Global access control
     * @param _citadel The token this contract will return in a trade
     * @param _asset The token this contract will receive in a trade
     * @param _xCitadel Staked citadel, citadel will be granted to funders in this form
     * @param _saleRecipient The address receiving the proceeds of the sale - will be citadel multisig
     * @param _assetCap The max asset that the contract can take
     */
    function initialize(
        address _gac,
        address _citadel,
        address _asset,
        address _xCitadel,
        address _saleRecipient,
        address _citadelPriceInAssetOracle,
        uint256 _assetCap
    ) external initializer {
        require(
            _saleRecipient != address(0),
            "Funding: 0 sale"
        );
        require(
            _citadelPriceInAssetOracle != address(0),
            "Funding: 0 oracle"
        );

        __GlobalAccessControlManaged_init(_gac);
        __ReentrancyGuard_init();

        citadel = IERC20(_citadel);
        xCitadel = IVault(_xCitadel);
        asset = IERC20(_asset);
        saleRecipient = _saleRecipient;

        citadelPriceInAssetOracle = _citadelPriceInAssetOracle;

        funding = FundingParams(0, 0, 0, address(0), 0, _assetCap);

        assetDecimalsNormalizationValue = 10**asset.decimals();

        // No circuit breaker on price by default
        minCitadelPriceInAsset = 0;
        maxCitadelPriceInAsset = type(uint256).max;

        // Allow to deposit in vault
        // Done last for reEntrancy concerns
        IERC20(_citadel).safeApprove(address(_xCitadel), type(uint256).max);
    }

    modifier onlyWhenPriceNotFlagged() {
        require(
            citadelPriceFlag == false,
            "Funding: citadel price from oracle flagged and pending review"
        );
        _;
    }

    /// ==========================
    /// ===== Public actions =====
    /// ==========================

    /**
     * @notice Exchange `_assetAmountIn` of `asset` for `citadel`
     * @param _assetAmountIn Amount of `asset` to give
     * @param _minCitadelOut ID of DAO to vote for
     * @return citadelAmount_ Amount of `xCitadel` bought
     */
    function deposit(uint256 _assetAmountIn, uint256 _minCitadelOut)
        external
        onlyWhenPriceNotFlagged
        gacPausable
        nonReentrant
        returns (uint256 citadelAmount_)
    {
        require(_assetAmountIn > 0, "_assetAmountIn must not be 0");
        require(
            funding.assetCumulativeFunded + _assetAmountIn <= funding.assetCap,
            "asset funding cap exceeded"
        );
        funding.assetCumulativeFunded = funding.assetCumulativeFunded + _assetAmountIn;
        // Take in asset from user
        citadelAmount_ = getAmountOut(_assetAmountIn);
        require(citadelAmount_ >= _minCitadelOut, "minCitadelOut");

        asset.safeTransferFrom(msg.sender, saleRecipient, _assetAmountIn);
        
        // Deposit xCitadel and send to user
        // TODO: Check gas costs. How does this relate to market buying if you do want to deposit to xCTDL?
        xCitadel.depositFor(msg.sender, citadelAmount_);

        emit Deposit(
            msg.sender,
            _assetAmountIn,
            citadelAmount_
        );
    }

    /// =======================
    /// ===== Public view =====
    /// =======================

    /**
     * @notice Get the amount received when exchanging `asset`
     * @param _assetAmountIn Amount of `asset` to exchange
     * @return citadelAmount_ Amount of `citadel` received
     */
    function getAmountOut(uint256 _assetAmountIn)
        public
        view
        returns (uint256 citadelAmount_)
    {
        uint256 citadelAmountWithoutDiscount = _assetAmountIn * citadelPriceInAsset;

        if (funding.discount > 0) {
            citadelAmount_ =
                (citadelAmountWithoutDiscount * MAX_BPS) /
                (MAX_BPS - funding.discount);
        } else {
            citadelAmount_ = citadelAmountWithoutDiscount;
        }

        // TODO: if discount is not set, citadelAmount_ in the right reference is 0
        citadelAmount_ = citadelAmount_ / assetDecimalsNormalizationValue;
    }

    /**
     * @notice Get the amount received when exchanging `asset`, in terms of xCitadel at current price per share
     * @param _assetAmountIn Amount of `asset` to exchange
     * @return xCitadelAmount_ Amount of `xCitadel` received at current price per share
     */
    function getStakedCitadelAmountOut(uint256 _assetAmountIn) public view returns (uint256 xCitadelAmount_) {
        uint citadelAmount = getAmountOut(_assetAmountIn);
        xCitadelAmount_ = citadelAmount * 10**citadel.decimals() / xCitadel.getPricePerFullShare();
    }

    /**
     * @notice Check how much `asset` can still be taken in, based on cap and cumulative amount funded
     * @return limitLeft_ Amount of `asset` that can still be exchanged for citadel
     */
    function getRemainingFundable() external view returns (uint256 limitLeft_) {
        uint256 assetCumulativeFunded = funding.assetCumulativeFunded;
        uint256 assetCap = funding.assetCap;
        if (assetCumulativeFunded < assetCap) {
            limitLeft_ = assetCap - assetCumulativeFunded;
        }
    }

    /**
     * @notice Get all funding params
     * @return funding all funding params
     */
    function getFundingParams() external view returns (FundingParams memory) {
        return funding;
    }

    /**
     * @notice Convenience function to get current discount rate
     * @return discount current discount rate
     */
    function getDiscount() external view returns (uint256) {
        return funding.discount;
    }

    /// ==============================
    /// ===== Policy Ops actions =====
    /// ==============================

    /**
     * @notice Set discount manually, within the constraints of min and max discount values
     * @dev managed by policy operations for rapid response to market conditions
     * @param _discount active discount (in bps)
     */
    function setDiscount(uint256 _discount)
        external
        gacPausable
        onlyRoleOrAddress(POLICY_OPERATIONS_ROLE, funding.discountManager)
    {
        require(_discount >= funding.minDiscount, "discount < minDiscount");
        require(_discount <= funding.maxDiscount, "discount > maxDiscount");

        funding.discount = _discount;

        emit DiscountSet(_discount);
    }

    function clearCitadelPriceFlag()
        external
        gacPausable
        onlyRole(POLICY_OPERATIONS_ROLE)
    {
        citadelPriceFlag = false;
    }

    /**
     * @notice Modify the max asset amount that this contract can take. Managed by policy governance.
     * @dev This is cumulative asset cap, so must take into account the asset amount already funded.
     * @param _assetCap New max cumulatiive amountIn
     */
    function setAssetCap(uint256 _assetCap)
        external
        gacPausable
        onlyRole(POLICY_OPERATIONS_ROLE)
    {
        require(
            _assetCap > funding.assetCumulativeFunded,
            "cannot decrease cap below global sum of assets in"
        );
        funding.assetCap = _assetCap;
        emit AssetCapUpdated(_assetCap);
    }

    /// ================================
    /// ===== Treasury Ops actions =====
    /// ================================

    /**
     * @notice Transfers out any tokens accidentally sent to the contract. Can only be called by owner
     * @dev The contract transfers all `asset` directly to `saleRecipient` during a sale so it's safe
     *      to sweep `asset`. For `citadel`, the function only sweeps the extra amount
     *      (current contract balance - amount left to be claimed)
     * @param _token The token to sweep
     */
    function sweep(address _token)
        external
        gacPausable
        nonReentrant
        onlyRole(TREASURY_OPERATIONS_ROLE)
    {
        uint256 amount = IERC20(_token).balanceOf(address(this));
        require(amount > 0, "nothing to sweep");
        require(
            _token != address(asset),
            "cannot sweep funding asset, use claimAssetToTreasury()"
        );

        emit Sweep(_token, amount);
        IERC20(_token).safeTransfer(saleRecipient, amount);
    }

    /// @notice Claim accumulated asset token to treasury
    /// @dev We let assets accumulate and batch transfer to treasury (rather than transfer atomically on each deposi)t for user gas savings
    function claimAssetToTreasury()
        external
        gacPausable
        onlyRole(TREASURY_OPERATIONS_ROLE)
    {
        uint256 amount = asset.balanceOf(address(this));
        require(amount > 0, "nothing to claim");
        asset.safeTransfer(saleRecipient, amount);

        emit ClaimToTreasury(address(asset), amount);
    }

    /// ==============================
    /// ===== Governance actions =====
    /// ==============================

    /**
     * @notice Set minimum and maximum discount
     * @dev managed by contract governance to place constraints around the parameter for policy operations to play within
     * @param _minDiscount minimum discount (in bps)
     * @param _maxDiscount maximum discount (in bps)
     */
    function setDiscountLimits(uint256 _minDiscount, uint256 _maxDiscount)
        external
        gacPausable
        onlyRole(CONTRACT_GOVERNANCE_ROLE)
    {
        require(_maxDiscount < MAX_BPS , "maxDiscount >= MAX_BPS");
        funding.minDiscount = _minDiscount;
        funding.maxDiscount = _maxDiscount;

        emit DiscountLimitsSet(_minDiscount, _maxDiscount);
    }

    /**
     * @notice Set a discount manager address
     * @dev This is intended to be used for an automated discount manager contract to supplement or replace manual calls
     * @param _discountManager discount manager address
     */
    function setDiscountManager(address _discountManager)
        external
        gacPausable
        onlyRole(CONTRACT_GOVERNANCE_ROLE)
    {
        funding.discountManager = _discountManager;

        emit DiscountManagerSet(_discountManager);
    }

    function setSaleRecipient(address _saleRecipient)
        external
        gacPausable
        onlyRole(CONTRACT_GOVERNANCE_ROLE)
    {
        require(
            _saleRecipient != address(0),
            "Funding: sale recipient should not be zero"
        );

        saleRecipient = _saleRecipient;
        emit SaleRecipientUpdated(_saleRecipient);
    }

    function setCitadelAssetPriceBounds(uint256 _minPrice, uint256 _maxPrice)
        external
        gacPausable
        onlyRole(CONTRACT_GOVERNANCE_ROLE)
    {
        minCitadelPriceInAsset = _minPrice;
        maxCitadelPriceInAsset = _maxPrice;

        emit CitadelPriceBoundsSet(_minPrice, _maxPrice);
    }

    /// ==========================
    /// ===== Oracle actions =====
    /// ==========================

    /// @notice Update citadel price in asset terms from oracle source
    /// @dev Note that the oracle mechanics are abstracted to the oracle address
    function updateCitadelPriceInAsset()
        external
        gacPausable
        onlyRole(KEEPER_ROLE)
    {   
        uint _citadelPriceInAsset;
        bool _valid;

        (_citadelPriceInAsset, _valid) = IMedianOracle(citadelPriceInAssetOracle).getData();

        require(_citadelPriceInAsset > 0, "citadel price must not be zero");
        require(_valid, "oracle data must be valid");

        if (
            _citadelPriceInAsset < minCitadelPriceInAsset ||
            _citadelPriceInAsset > maxCitadelPriceInAsset
        ) {
            citadelPriceFlag = true;
            emit CitadelPriceFlag(
                _citadelPriceInAsset,
                minCitadelPriceInAsset,
                maxCitadelPriceInAsset
            );
        } else {
            citadelPriceInAsset = _citadelPriceInAsset;
            emit CitadelPriceInAssetUpdated(_citadelPriceInAsset);
        }
    }


    /// @dev OUT OF AUDIT SCOPE: This is a test function that will be removed in final code
    /// @notice Update citadel price in asset terms from oracle source
    /// @dev Note that the oracle mechanics are abstracted to the oracle address
    function updateCitadelPriceInAsset(uint256 _citadelPriceInAsset)
        external
        gacPausable
        onlyCitadelPriceInAssetOracle
    {
        require(_citadelPriceInAsset > 0, "citadel price must not be zero");

        if (
            _citadelPriceInAsset < minCitadelPriceInAsset ||
            _citadelPriceInAsset > maxCitadelPriceInAsset
        ) {
            citadelPriceFlag = true;
            emit CitadelPriceFlag(
                _citadelPriceInAsset,
                minCitadelPriceInAsset,
                maxCitadelPriceInAsset
            );
        } else {
            citadelPriceInAsset = _citadelPriceInAsset;
            emit CitadelPriceInAssetUpdated(_citadelPriceInAsset);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >= 0.5.0 <= 0.9.0;

import {IERC20} from "../erc20/IERC20.sol";

interface IVault is IERC20 {
    function token() external view returns (address);

    function rewards() external view returns (address);

    function reportHarvest(uint256 _harvestedAmount) external;

    function reportAdditionalToken(address _token) external;

    // Fees
    function performanceFeeGovernance() external view returns (uint256);

    function performanceFeeStrategist() external view returns (uint256);

    function withdrawalFee() external view returns (uint256);

    function managementFee() external view returns (uint256);

    // Actors
    function governance() external view returns (address);

    function keeper() external view returns (address);

    function guardian() external view returns (address);

    function strategist() external view returns (address);

    // External
    function deposit(uint256 _amount) external;

    function depositFor(address _recipient, uint256 _amount) external;

    // View
    function getPricePerFullShare() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity >= 0.5.0 <= 0.9.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint256);

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "../interfaces/citadel/IGac.sol";

/**
 * @title Global Access Control Managed - Base Class
 * @notice allows inheriting contracts to leverage global access control permissions conveniently, as well as granting contract-specific pausing functionality
 */
contract GlobalAccessControlManaged is PausableUpgradeable {
    IGac public gac;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant UNPAUSER_ROLE = keccak256("UNPAUSER_ROLE");

    /// =======================
    /// ===== Initializer =====
    /// =======================

    /**
     * @notice Initializer
     * @dev this is assumed to be used in the initializer of the inhereiting contract
     * @param _globalAccessControl global access control which is pinged to allow / deny access to permissioned calls by role
     */
    function __GlobalAccessControlManaged_init(address _globalAccessControl)
        public
        onlyInitializing
    {
        __Pausable_init_unchained();
        gac = IGac(_globalAccessControl);
    }

    /// =====================
    /// ===== Modifiers =====
    /// =====================

    // @dev only holders of the given role on the GAC can call
    modifier onlyRole(bytes32 role) {
        require(gac.hasRole(role, msg.sender), "GAC: invalid-caller-role");
        _;
    }

    // @dev only holders of any of the given set of roles on the GAC can call
    modifier onlyRoles(bytes32[] memory roles) {
        bool validRoleFound = false;
        for (uint256 i = 0; i < roles.length; i++) {
            bytes32 role = roles[i];
            if (gac.hasRole(role, msg.sender)) {
                validRoleFound = true;
                break;
            }
        }
        require(validRoleFound, "GAC: invalid-caller-role");
        _;
    }

    // @dev only holders of the given role on the GAC can call, or a specified address
    // @dev used to faciliate extra contract-specific permissioned accounts
    modifier onlyRoleOrAddress(bytes32 role, address account) {
        require(
            gac.hasRole(role, msg.sender) || msg.sender == account,
            "GAC: invalid-caller-role-or-address"
        );
        _;
    }

    /// @dev can be pausable by GAC or local flag
    modifier gacPausable() {
        require(!gac.paused(), "global-paused");
        require(!paused(), "local-paused");
        _;
    }

    /// ================================
    /// ===== Permissioned actions =====
    /// ================================

    function pause() external {
        require(gac.hasRole(PAUSER_ROLE, msg.sender));
        _pause();
    }

    function unpause() external {
        require(gac.hasRole(UNPAUSER_ROLE, msg.sender));
        _unpause();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import {AddressUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "../interfaces/erc20/IERC20.sol";

// Modified dependencies to work with ERC20 interface that features name, symbol, decimals.

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {AddressUpgradeable.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

/// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0 <=0.9.0;

interface IMedianOracle {

    struct Report {
        uint256 timestamp;
        uint256 payload;
    }

    event ProviderAdded(address provider);
    event ProviderRemoved(address provider);
    event ReportTimestampOutOfRange(address provider);
    event ProviderReportPushed(address indexed provider, uint256 payload, uint256 timestamp);

    function reportExpirationTimeSec() external view returns(uint256);
    function getData() external view returns (uint256, bool);
    function providerReports(address provider) external view returns (Report[2] calldata);

    function pushReport(uint256 payload) external;
    
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

/// SPDX-License-Identifier: MIT

pragma solidity >= 0.5.0 <= 0.9.0;

interface IGac {
    function paused() external view returns (bool);

    function transferFromDisabled() external view returns (bool);

    function unpause() external;

    function pause() external;

    function enableTransferFrom() external;

    function disableTransferFrom() external;

    function grantRole(bytes32 role, address account) external;

    function hasRole(bytes32 role, address account)
        external
        view
        returns (bool);

    function getRoleMember(bytes32 role, uint256 index)
        external
        view
        returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}