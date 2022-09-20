// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IMarketConfig {
    function burnFee() external view returns (uint256);

    function config()
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
    );

    function fees()
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
    );

    function periods()
        external
        view
        returns (
            uint256,
            uint256
    );

    function disputePeriod() external view returns (uint256);

    function disputePrice() external view returns (uint256);

    function feesSum() external view returns (uint256);

    function foundationFee() external view returns (uint256);

    function marketCreatorFee() external view returns (uint256);

    function verificationFee() external view returns (uint256);

    function verificationPeriod() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./IMarketConfig.sol";

contract MarketConfig is IMarketConfig{

    /// @notice Opening dispute price (FORE)
    /// @dev Used in order to disincentive spam
    uint256 public immutable override disputePrice;

    /// @notice Dispute period (in seconds)
    uint256 public immutable override disputePeriod;

    /// @notice Verification period (in seconds)
    uint256 public immutable override verificationPeriod;

    /// @notice Burn fee (1 = 0.01%)
    uint256 public immutable override burnFee;

    /// @notice Foundation fee (1 = 0.01%)
    uint256 public immutable override foundationFee;

    /// @notice Market creator fee (1 = 0.01%)
    uint256 public immutable override marketCreatorFee;

    /// @notice Verification fee (1 = 0.01%)
    uint256 public immutable override verificationFee;

    constructor(
        uint256 disputePriceP,
        uint256 disputePeriodP,
        uint256 verificationPeriodP,
        uint256 burnFeeP,
        uint256 foundationFeeP,
        uint256 marketCreatorFeeP,
        uint256 verificationFeeP
    ) {
        disputePrice = disputePriceP;
        disputePeriod = disputePeriodP;
        verificationPeriod = verificationPeriodP;
        burnFee = burnFeeP;
        foundationFee = foundationFeeP;
        marketCreatorFee = marketCreatorFeeP;
        verificationFee = verificationFeeP;
    }

    /**
     * @notice Returns all period values
     */
    function periods()
        external
        view
        override
        returns (
            uint256,
            uint256
        )
    {
        return (
            disputePeriod,
            verificationPeriod
        );
    }


    /**
     * @notice Returns all config values
     */
    function fees()
        external
        view
        override
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return (
            burnFee,
            foundationFee,
            marketCreatorFee,
            verificationFee
        );
    }

    /**
     * @notice Returns all fees values
     */
    function config()
        external
        view
        override
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return (
            disputePrice,
            disputePeriod,
            verificationPeriod,
            burnFee,
            foundationFee,
            marketCreatorFee,
            verificationFee
        );
    }

    /**
     * @notice Returns sum of all fees (1 = 0.01%)
     */
    function feesSum() external override view returns(uint256){
        return burnFee
            + foundationFee
            + marketCreatorFee
            + verificationFee;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./MarketConfig.sol";

contract ProtocolConfig is Ownable {
    event MarketConfigurationUpdated(MarketConfig marketConfig);
    event FoundationWalletChanged(address addr);
    event HighGuardChanged(address addr);
    event MarketplaceChanged(address addr);
    event VerifierMintPriceChanged(uint256 amount);
    event MarketCreationChanged(uint256 amount);
    event SetStatusForFactory(address indexed add, bool status);

    /// @notice Max fee (1 = 0.01%)
    uint256 public constant MAX_FEE = 500;

    /// @notice Max price (FORE)
    uint256 public constant MAX_PRICE = 1000 ether;

    /// @notice Current market configuration
    /// @dev Configuration for created market is immutable. New configuration will be used only in newly created markets
    MarketConfig public marketConfig;

    /// @notice Foundation account
    address public foundationWallet;

    /// @notice High guard account
    address public highGuard;

    /// @notice Marketplace contract address
    address public marketplace;

    /// @notice FORE token contract address
    address public immutable foreToken;

    /// @notice FORE verifiers NFT contract address
    address public immutable foreVerifiers;

    /// @notice Market creation price (FORE)
    uint256 public marketCreationPrice;

    /// @notice Minting verifiers NFT price (FORE)
    uint256 public verifierMintPrice;

    mapping(address => bool) public isFactoryWhitelisted;

    function addresses()
        external
        view
        returns (
            address,
            address,
            address,
            address,
            address,
            address
        )
    {
        return (
            address(marketConfig),
            foundationWallet,
            highGuard,
            marketplace,
            foreToken,
            foreVerifiers
        );
    }

    function roleAddresses()
        external
        view
        returns (
            address,
            address
        )
    {
        return (foundationWallet, highGuard);
    }

    function setFactoryStatus(
        address[] memory factoryAddresses,
        bool[] memory statuses
    ) external onlyOwner {
        uint256 len = factoryAddresses.length;
        require(len == statuses.length, "ProtocoConfig: Len mismatch ");
        for (uint256 i = 0; i < len; i++) {
            isFactoryWhitelisted[factoryAddresses[i]] = statuses[i];
            emit SetStatusForFactory(factoryAddresses[i], statuses[i]);
        }
    }

    constructor(
        address foundationWalletP,
        address highGuardP,
        address marketplaceP,
        address foreTokenP,
        address foreVerifiersP,
        uint256 marketCreationPriceP,
        uint256 verifierMintPriceP
    ) {
        _setConfig(
            1000 ether,
            1000 ether,
            1000 ether,
            1800,
            1800,
            100,
            150,
            50,
            200
        );

        foundationWallet = foundationWalletP;

        highGuard = highGuardP;

        marketplace = marketplaceP;
        foreToken = foreTokenP;
        foreVerifiers = foreVerifiersP;

        marketCreationPrice = marketCreationPriceP;
        verifierMintPrice = verifierMintPriceP;
    }

    /**
     * @dev Updates current configuration
     */
    function _setConfig(
        uint256 creationPriceP,
        uint256 verifierMintPriceP,
        uint256 disputePriceP,
        uint256 disputePeriodP,
        uint256 verificationPeriodP,
        uint256 burnFeeP,
        uint256 foundationFeeP,
        uint256 marketCreatorFeeP,
        uint256 verificationFeeP
    ) internal {
        uint256 feesSum = burnFeeP +
            foundationFeeP +
            marketCreatorFeeP +
            verificationFeeP;

        require(
            feesSum <= MAX_FEE &&
                disputePriceP <= MAX_PRICE &&
                creationPriceP <= MAX_PRICE &&
                verifierMintPriceP <= MAX_PRICE,
            "ForeFactory: Config limit"
        );

        MarketConfig createdMarketConfig = new MarketConfig(
            disputePriceP,
            disputePeriodP,
            verificationPeriodP,
            burnFeeP,
            foundationFeeP,
            marketCreatorFeeP,
            verificationFeeP
        );

        marketConfig = createdMarketConfig;

        emit MarketConfigurationUpdated(marketConfig);
    }

    /**
     * @notice Updates current configuration
     */
    function setMarketConfig(
        uint256 verifierMintPriceP,
        uint256 disputePriceP,
        uint256 creationPriceP,
        uint256 reportPeriodP,
        uint256 verificationPeriodP,
        uint256 burnFeeP,
        uint256 foundationFeeP,
        uint256 marketCreatorFeeP,
        uint256 verificationFeeP
    ) external onlyOwner {
        _setConfig(
            creationPriceP,
            verifierMintPriceP,
            disputePriceP,
            reportPeriodP,
            verificationPeriodP,
            burnFeeP,
            foundationFeeP,
            marketCreatorFeeP,
            verificationFeeP
        );
    }

    /**
     * @notice Changes foundation account
     * @param _newAddr New address
     */
    function setFoundationWallet(address _newAddr) external onlyOwner {
        foundationWallet = _newAddr;
        emit FoundationWalletChanged(_newAddr);
    }

    /**
     * @notice Changes high guard account
     * @param _newAddr New address
     */
    function setHighGuard(address _newAddr) external onlyOwner {
        highGuard = _newAddr;
        emit HighGuardChanged(_newAddr);
    }

    /**
     * @notice Changes marketplace contract address
     * @param _newAddr New address
     */
    function setMarketplace(address _newAddr) external onlyOwner {
        marketplace = _newAddr;
        emit MarketplaceChanged(_newAddr);
    }

    /**
     * @notice Changes verifier mint price
     * @param _amount Price (FORE)
     */
    function setVerifierMintPrice(uint256 _amount) external onlyOwner {
        require(_amount <= 1000 ether, "ProtocoConfig: Max price exceed");
        verifierMintPrice = _amount;
        emit VerifierMintPriceChanged(_amount);
    }

    /**
     * @notice Changes market creation price
     * @param _amount Price (FORE)
     */
    function setMarketCreationPrice(uint256 _amount) external onlyOwner {
        require(_amount <= 1000 ether, "ProtocoConfig: Max price exceed");
        marketCreationPrice = _amount;
        emit MarketCreationChanged(_amount);
    }
}