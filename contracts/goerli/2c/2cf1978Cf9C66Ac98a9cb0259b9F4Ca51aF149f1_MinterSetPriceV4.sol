// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
abstract contract ReentrancyGuard {
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

    constructor() {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// SPDX-License-Identifier: LGPL-3.0-only
// Created By: Art Blocks Inc.

pragma solidity ^0.8.0;

interface IAdminACLV0 {
    /**
     * @notice Token ID `_tokenId` minted to `_to`.
     * @param previousSuperAdmin The previous superAdmin address.
     * @param newSuperAdmin The new superAdmin address.
     * @param genArt721CoreAddressesToUpdate Array of genArt721Core
     * addresses to update to the new superAdmin, for indexing purposes only.
     */
    event SuperAdminTransferred(
        address indexed previousSuperAdmin,
        address indexed newSuperAdmin,
        address[] genArt721CoreAddressesToUpdate
    );

    /// Type of the Admin ACL contract, e.g. "AdminACLV0"
    function AdminACLType() external view returns (string memory);

    /// super admin address
    function superAdmin() external view returns (address);

    /**
     * @notice Calls transferOwnership on other contract from this contract.
     * This is useful for updating to a new AdminACL contract.
     * @dev this function should be gated to only superAdmin-like addresses.
     */
    function transferOwnershipOn(
        address _contract,
        address _newAdminACL
    ) external;

    /**
     * @notice Calls renounceOwnership on other contract from this contract.
     * @dev this function should be gated to only superAdmin-like addresses.
     */
    function renounceOwnershipOn(address _contract) external;

    /**
     * @notice Checks if sender `_sender` is allowed to call function with selector
     * `_selector` on contract `_contract`.
     */
    function allowed(
        address _sender,
        address _contract,
        bytes4 _selector
    ) external returns (bool);
}

// SPDX-License-Identifier: LGPL-3.0-only
// Created By: Art Blocks Inc.

pragma solidity ^0.8.0;

interface IFilteredMinterV0 {
    /**
     * @notice Price per token in wei updated for project `_projectId` to
     * `_pricePerTokenInWei`.
     */
    event PricePerTokenInWeiUpdated(
        uint256 indexed _projectId,
        uint256 indexed _pricePerTokenInWei
    );

    /**
     * @notice Currency updated for project `_projectId` to symbol
     * `_currencySymbol` and address `_currencyAddress`.
     */
    event ProjectCurrencyInfoUpdated(
        uint256 indexed _projectId,
        address indexed _currencyAddress,
        string _currencySymbol
    );

    /// togglePurchaseToDisabled updated
    event PurchaseToDisabledUpdated(
        uint256 indexed _projectId,
        bool _purchaseToDisabled
    );

    // getter function of public variable
    function minterType() external view returns (string memory);

    function genArt721CoreAddress() external returns (address);

    function minterFilterAddress() external returns (address);

    // Triggers a purchase of a token from the desired project, to the
    // TX-sending address.
    function purchase(
        uint256 _projectId
    ) external payable returns (uint256 tokenId);

    // Triggers a purchase of a token from the desired project, to the specified
    // receiving address.
    function purchaseTo(
        address _to,
        uint256 _projectId
    ) external payable returns (uint256 tokenId);

    // Toggles the ability for `purchaseTo` to be called directly with a
    // specified receiving address that differs from the TX-sending address.
    function togglePurchaseToDisabled(uint256 _projectId) external;

    // Called to make the minter contract aware of the max invocations for a
    // given project.
    function setProjectMaxInvocations(uint256 _projectId) external;

    // Gets if token price is configured, token price in wei, currency symbol,
    // and currency address, assuming this is project's minter.
    // Supersedes any defined core price.
    function getPriceInfo(
        uint256 _projectId
    )
        external
        view
        returns (
            bool isConfigured,
            uint256 tokenPriceInWei,
            string memory currencySymbol,
            address currencyAddress
        );
}

// SPDX-License-Identifier: LGPL-3.0-only
// Created By: Art Blocks Inc.

import "./IFilteredMinterV0.sol";

pragma solidity ^0.8.0;

/**
 * @title This interface extends the IFilteredMinterV0 interface in order to
 * add support for generic project minter configuration updates.
 * @dev keys represent strings of finite length encoded in bytes32 to minimize
 * gas.
 * @author Art Blocks Inc.
 */
interface IFilteredMinterV1 is IFilteredMinterV0 {
    /// ANY
    /**
     * @notice Generic project minter configuration event. Removes key `_key`
     * for project `_projectId`.
     */
    event ConfigKeyRemoved(uint256 indexed _projectId, bytes32 _key);

    /// BOOL
    /**
     * @notice Generic project minter configuration event. Sets value of key
     * `_key` to `_value` for project `_projectId`.
     */
    event ConfigValueSet(uint256 indexed _projectId, bytes32 _key, bool _value);

    /// UINT256
    /**
     * @notice Generic project minter configuration event. Sets value of key
     * `_key` to `_value` for project `_projectId`.
     */
    event ConfigValueSet(
        uint256 indexed _projectId,
        bytes32 _key,
        uint256 _value
    );

    /**
     * @notice Generic project minter configuration event. Adds value `_value`
     * to the set of uint256 at key `_key` for project `_projectId`.
     */
    event ConfigValueAddedToSet(
        uint256 indexed _projectId,
        bytes32 _key,
        uint256 _value
    );

    /**
     * @notice Generic project minter configuration event. Removes value
     * `_value` to the set of uint256 at key `_key` for project `_projectId`.
     */
    event ConfigValueRemovedFromSet(
        uint256 indexed _projectId,
        bytes32 _key,
        uint256 _value
    );

    /// ADDRESS
    /**
     * @notice Generic project minter configuration event. Sets value of key
     * `_key` to `_value` for project `_projectId`.
     */
    event ConfigValueSet(
        uint256 indexed _projectId,
        bytes32 _key,
        address _value
    );

    /**
     * @notice Generic project minter configuration event. Adds value `_value`
     * to the set of addresses at key `_key` for project `_projectId`.
     */
    event ConfigValueAddedToSet(
        uint256 indexed _projectId,
        bytes32 _key,
        address _value
    );

    /**
     * @notice Generic project minter configuration event. Removes value
     * `_value` to the set of addresses at key `_key` for project `_projectId`.
     */
    event ConfigValueRemovedFromSet(
        uint256 indexed _projectId,
        bytes32 _key,
        address _value
    );

    /// BYTES32
    /**
     * @notice Generic project minter configuration event. Sets value of key
     * `_key` to `_value` for project `_projectId`.
     */
    event ConfigValueSet(
        uint256 indexed _projectId,
        bytes32 _key,
        bytes32 _value
    );

    /**
     * @notice Generic project minter configuration event. Adds value `_value`
     * to the set of bytes32 at key `_key` for project `_projectId`.
     */
    event ConfigValueAddedToSet(
        uint256 indexed _projectId,
        bytes32 _key,
        bytes32 _value
    );

    /**
     * @notice Generic project minter configuration event. Removes value
     * `_value` to the set of bytes32 at key `_key` for project `_projectId`.
     */
    event ConfigValueRemovedFromSet(
        uint256 indexed _projectId,
        bytes32 _key,
        bytes32 _value
    );

    /**
     * @dev Strings not supported. Recommend conversion of (short) strings to
     * bytes32 to remain gas-efficient.
     */
}

// SPDX-License-Identifier: LGPL-3.0-only
// Created By: Art Blocks Inc.

import "./IFilteredMinterV1.sol";

pragma solidity ^0.8.0;

/**
 * @title This interface extends the IFilteredMinterV1 interface in order to
 * add support for manually setting project max invocations.
 * @author Art Blocks Inc.
 */
interface IFilteredMinterV2 is IFilteredMinterV1 {
    /**
     * @notice Local max invocations for project `_projectId`, tied to core contract `_coreContractAddress`,
     * updated to `_maxInvocations`.
     */
    event ProjectMaxInvocationsLimitUpdated(
        uint256 indexed _projectId,
        uint256 _maxInvocations
    );

    // Sets the local max invocations for a given project, checking that the provided max invocations is
    // less than or equal to the global max invocations for the project set on the core contract.
    // This does not impact the max invocations value defined on the core contract.
    function manuallyLimitProjectMaxInvocations(
        uint256 _projectId,
        uint256 _maxInvocations
    ) external;
}

// SPDX-License-Identifier: LGPL-3.0-only
// Created By: Art Blocks Inc.

pragma solidity ^0.8.0;

import "./IAdminACLV0.sol";
/// use the Royalty Registry's IManifold interface for token royalties
import "./IManifold.sol";

/**
 * @title This interface is intended to house interface items that are common
 * across all GenArt721CoreContractV3 flagship and derivative implementations.
 * This interface extends the IManifold royalty interface in order to
 * add support the Royalty Registry by default.
 * @author Art Blocks Inc.
 */
interface IGenArt721CoreContractV3_Base is IManifold {
    /**
     * @notice Token ID `_tokenId` minted to `_to`.
     */
    event Mint(address indexed _to, uint256 indexed _tokenId);

    /**
     * @notice currentMinter updated to `_currentMinter`.
     * @dev Implemented starting with V3 core
     */
    event MinterUpdated(address indexed _currentMinter);

    /**
     * @notice Platform updated on bytes32-encoded field `_field`.
     */
    event PlatformUpdated(bytes32 indexed _field);

    /**
     * @notice Project ID `_projectId` updated on bytes32-encoded field
     * `_update`.
     */
    event ProjectUpdated(uint256 indexed _projectId, bytes32 indexed _update);

    event ProposedArtistAddressesAndSplits(
        uint256 indexed _projectId,
        address _artistAddress,
        address _additionalPayeePrimarySales,
        uint256 _additionalPayeePrimarySalesPercentage,
        address _additionalPayeeSecondarySales,
        uint256 _additionalPayeeSecondarySalesPercentage
    );

    event AcceptedArtistAddressesAndSplits(uint256 indexed _projectId);

    // version and type of the core contract
    // coreVersion is a string of the form "0.x.y"
    function coreVersion() external view returns (string memory);

    // coreType is a string of the form "GenArt721CoreV3"
    function coreType() external view returns (string memory);

    // owner (pre-V3 was named admin) of contract
    // this is expected to be an Admin ACL contract for V3
    function owner() external view returns (address);

    // Admin ACL contract for V3, will be at the address owner()
    function adminACLContract() external returns (IAdminACLV0);

    // backwards-compatible (pre-V3) admin - equal to owner()
    function admin() external view returns (address);

    /**
     * Function determining if _sender is allowed to call function with
     * selector _selector on contract `_contract`. Intended to be used with
     * peripheral contracts such as minters, as well as internally by the
     * core contract itself.
     */
    function adminACLAllowed(
        address _sender,
        address _contract,
        bytes4 _selector
    ) external returns (bool);

    // getter function of public variable
    function nextProjectId() external view returns (uint256);

    // getter function of public mapping
    function tokenIdToProjectId(
        uint256 tokenId
    ) external view returns (uint256 projectId);

    // @dev this is not available in V0
    function isMintWhitelisted(address minter) external view returns (bool);

    function projectIdToArtistAddress(
        uint256 _projectId
    ) external view returns (address payable);

    function projectIdToAdditionalPayeePrimarySales(
        uint256 _projectId
    ) external view returns (address payable);

    function projectIdToAdditionalPayeePrimarySalesPercentage(
        uint256 _projectId
    ) external view returns (uint256);

    // @dev new function in V3
    function projectStateData(
        uint256 _projectId
    )
        external
        view
        returns (
            uint256 invocations,
            uint256 maxInvocations,
            bool active,
            bool paused,
            uint256 completedTimestamp,
            bool locked
        );

    // function to set a token's hash (must be guarded)
    function setTokenHash_8PT(uint256 _tokenId, bytes32 _hash) external;

    // @dev gas-optimized signature in V3 for `mint`
    function mint_Ecf(
        address _to,
        uint256 _projectId,
        address _by
    ) external returns (uint256 tokenId);
}

// SPDX-License-Identifier: LGPL-3.0-only
// Created By: Art Blocks Inc.

pragma solidity ^0.8.0;

import "./IAdminACLV0.sol";
import "./IGenArt721CoreContractV3_Base.sol";

interface IGenArt721CoreContractV3_Engine is IGenArt721CoreContractV3_Base {
    // @dev new function in V3
    function getPrimaryRevenueSplits(
        uint256 _projectId,
        uint256 _price
    )
        external
        view
        returns (
            uint256 renderProviderRevenue_,
            address payable renderProviderAddress_,
            uint256 platformProviderRevenue_,
            address payable platformProviderAddress_,
            uint256 artistRevenue_,
            address payable artistAddress_,
            uint256 additionalPayeePrimaryRevenue_,
            address payable additionalPayeePrimaryAddress_
        );

    // @dev The render provider primary sales payment address
    function renderProviderPrimarySalesAddress()
        external
        view
        returns (address payable);

    // @dev The platform provider primary sales payment address
    function platformProviderPrimarySalesAddress()
        external
        view
        returns (address payable);

    // @dev Percentage of primary sales allocated to the render provider
    function renderProviderPrimarySalesPercentage()
        external
        view
        returns (uint256);

    // @dev Percentage of primary sales allocated to the platform provider
    function platformProviderPrimarySalesPercentage()
        external
        view
        returns (uint256);

    // @dev The render provider secondary sales royalties payment address
    function renderProviderSecondarySalesAddress()
        external
        view
        returns (address payable);

    // @dev The platform provider secondary sales royalties payment address
    function platformProviderSecondarySalesAddress()
        external
        view
        returns (address payable);

    // @dev Basis points of secondary sales allocated to the render provider
    function renderProviderSecondarySalesBPS() external view returns (uint256);

    // @dev Basis points of secondary sales allocated to the platform provider
    function platformProviderSecondarySalesBPS()
        external
        view
        returns (uint256);

    // function to read the hash for a given tokenId
    function tokenIdToHash(uint256 _tokenId) external view returns (bytes32);

    // function to read the hash-seed for a given tokenId
    function tokenIdToHashSeed(
        uint256 _tokenId
    ) external view returns (bytes12);
}

// SPDX-License-Identifier: LGPL-3.0-only
// Created By: Art Blocks Inc.

pragma solidity ^0.8.0;

import "./IAdminACLV0.sol";
import "./IGenArt721CoreContractV3_Base.sol";

/**
 * @title This interface extends IGenArt721CoreContractV3_Base with functions
 * that are part of the Art Blocks Flagship core contract.
 * @author Art Blocks Inc.
 */
// This interface extends IGenArt721CoreContractV3_Base with functions that are
// in part of the Art Blocks Flagship core contract.
interface IGenArt721CoreContractV3 is IGenArt721CoreContractV3_Base {
    // @dev new function in V3
    function getPrimaryRevenueSplits(
        uint256 _projectId,
        uint256 _price
    )
        external
        view
        returns (
            uint256 artblocksRevenue_,
            address payable artblocksAddress_,
            uint256 artistRevenue_,
            address payable artistAddress_,
            uint256 additionalPayeePrimaryRevenue_,
            address payable additionalPayeePrimaryAddress_
        );

    // @dev Art Blocks primary sales payment address
    function artblocksPrimarySalesAddress()
        external
        view
        returns (address payable);

    /**
     * @notice Backwards-compatible (pre-V3) function returning Art Blocks
     * primary sales payment address (now called artblocksPrimarySalesAddress).
     */
    function artblocksAddress() external view returns (address payable);

    // @dev Percentage of primary sales allocated to Art Blocks
    function artblocksPrimarySalesPercentage() external view returns (uint256);

    /**
     * @notice Backwards-compatible (pre-V3) function returning Art Blocks
     * primary sales percentage (now called artblocksPrimarySalesPercentage).
     */
    function artblocksPercentage() external view returns (uint256);

    // @dev Art Blocks secondary sales royalties payment address
    function artblocksSecondarySalesAddress()
        external
        view
        returns (address payable);

    // @dev Basis points of secondary sales allocated to Art Blocks
    function artblocksSecondarySalesBPS() external view returns (uint256);

    /**
     * @notice Backwards-compatible (pre-V3) function  that gets artist +
     * artist's additional payee royalty data for token ID `_tokenId`.
     * WARNING: Does not include Art Blocks portion of royalties.
     */
    function getRoyaltyData(
        uint256 _tokenId
    )
        external
        view
        returns (
            address artistAddress,
            address additionalPayee,
            uint256 additionalPayeePercentage,
            uint256 royaltyFeeByID
        );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @dev Royalty Registry interface, used to support the Royalty Registry.
/// @dev Source: https://github.com/manifoldxyz/royalty-registry-solidity/blob/main/contracts/specs/IManifold.sol

/// @author: manifold.xyz

/**
 * @dev Royalty interface for creator core classes
 */
interface IManifold {
    /**
     * @dev Get royalites of a token.  Returns list of receivers and basisPoints
     *
     *  bytes4(keccak256('getRoyalties(uint256)')) == 0xbb3bafd6
     *
     *  => 0xbb3bafd6 = 0xbb3bafd6
     */
    function getRoyalties(
        uint256 tokenId
    ) external view returns (address payable[] memory, uint256[] memory);
}

// SPDX-License-Identifier: LGPL-3.0-only
// Created By: Art Blocks Inc.

import "./IFilteredMinterV2.sol";

pragma solidity ^0.8.0;

/**
 * @title This interface defines any events or functions required for a minter
 * to conform to the MinterBase contract.
 * @dev The MinterBase contract was not implemented from the beginning of the
 * MinterSuite contract suite, therefore early versions of some minters may not
 * conform to this interface.
 * @author Art Blocks Inc.
 */
interface IMinterBaseV0 {
    // Function that returns if a minter is configured to integrate with a V3 flagship or V3 engine contract.
    // Returns true only if the minter is configured to integrate with an engine contract.
    function isEngine() external returns (bool isEngine);
}

// SPDX-License-Identifier: LGPL-3.0-only
// Created By: Art Blocks Inc.

pragma solidity ^0.8.0;

interface IMinterFilterV0 {
    /**
     * @notice Emitted when contract is deployed to notify indexing services
     * of the new contract deployment.
     */
    event Deployed();

    /**
     * @notice Approved minter `_minterAddress`.
     */
    event MinterApproved(address indexed _minterAddress, string _minterType);

    /**
     * @notice Revoked approval for minter `_minterAddress`
     */
    event MinterRevoked(address indexed _minterAddress);

    /**
     * @notice Minter `_minterAddress` of type `_minterType`
     * registered for project `_projectId`.
     */
    event ProjectMinterRegistered(
        uint256 indexed _projectId,
        address indexed _minterAddress,
        string _minterType
    );

    /**
     * @notice Any active minter removed for project `_projectId`.
     */
    event ProjectMinterRemoved(uint256 indexed _projectId);

    function genArt721CoreAddress() external returns (address);

    function setMinterForProject(uint256, address) external;

    function removeMinterForProject(uint256) external;

    function mint(
        address _to,
        uint256 _projectId,
        address sender
    ) external returns (uint256);

    function getMinterForProject(uint256) external view returns (address);

    function projectHasMinter(uint256) external view returns (bool);
}

// SPDX-License-Identifier: LGPL-3.0-only
// Created By: Art Blocks Inc.

import "../../interfaces/0.8.x/IMinterBaseV0.sol";
import "../../interfaces/0.8.x/IGenArt721CoreContractV3_Base.sol";
import "../../interfaces/0.8.x/IGenArt721CoreContractV3.sol";
import "../../interfaces/0.8.x/IGenArt721CoreContractV3_Engine.sol";

import "@openzeppelin-4.7/contracts/token/ERC20/IERC20.sol";

pragma solidity ^0.8.0;

/**
 * @title Art Blocks Minter Base Class
 * @notice A base class for Art Blocks minter contracts that provides common
 * functionality used across minter contracts.
 * This contract is not intended to be deployed directly, but rather to be
 * inherited by other minter contracts.
 * From a design perspective, this contract is intended to remain simple and
 * easy to understand. It is not intended to cause a complex inheritance tree,
 * and instead should keep minter contracts as readable as possible for
 * collectors and developers.
 * @dev Semantic versioning is used in the solidity file name, and is therefore
 * controlled by contracts importing the appropriate filename version.
 * @author Art Blocks Inc.
 */
abstract contract MinterBase is IMinterBaseV0 {
    /// state variable that tracks whether this contract's associated core
    /// contract is an Engine contract, where Engine contracts have an
    /// additional revenue split for the platform provider
    bool public immutable isEngine;

    // @dev we do not track an initialization state, as the only state variable
    // is immutable, which the compiler enforces to be assigned during
    // construction.

    /**
     * @notice Initializes contract to ensure state variable `isEngine` is set
     * appropriately based on the minter's associated core contract address.
     * @param genArt721Address Art Blocks core contract address for
     * which this contract will be a minter.
     */
    constructor(address genArt721Address) {
        // set state variable isEngine
        isEngine = _getV3CoreIsEngine(genArt721Address);
    }

    /**
     * @notice splits ETH funds between sender (if refund), providers,
     * artist, and artist's additional payee for a token purchased on
     * project `_projectId`.
     * WARNING: This function uses msg.value and msg.sender to determine
     * refund amounts, and therefore may not be applicable to all use cases
     * (e.g. do not use with Dutch Auctions with on-chain settlement).
     * @dev possible DoS during splits is acknowledged, and mitigated by
     * business practices, including end-to-end testing on mainnet, and
     * admin-accepted artist payment addresses.
     * @param projectId Project ID for which funds shall be split.
     * @param pricePerTokenInWei Current price of token, in Wei.
     */
    function splitFundsETH(
        uint256 projectId,
        uint256 pricePerTokenInWei,
        address genArt721CoreAddress
    ) internal {
        if (msg.value > 0) {
            bool success_;
            // send refund to sender
            uint256 refund = msg.value - pricePerTokenInWei;
            if (refund > 0) {
                (success_, ) = msg.sender.call{value: refund}("");
                require(success_, "Refund failed");
            }
            // split revenues
            splitRevenuesETH(
                projectId,
                pricePerTokenInWei,
                genArt721CoreAddress
            );
        }
    }

    /**
     * @notice splits ETH revenues between providers, artist, and artist's
     * additional payee for revenue generated by project `_projectId`.
     * @dev possible DoS during splits is acknowledged, and mitigated by
     * business practices, including end-to-end testing on mainnet, and
     * admin-accepted artist payment addresses.
     * @param projectId Project ID for which funds shall be split.
     * @param valueInWei Value to be split, in Wei.
     */
    function splitRevenuesETH(
        uint256 projectId,
        uint256 valueInWei,
        address genArtCoreContract
    ) internal {
        if (valueInWei <= 0) {
            return; // return early
        }
        bool success;
        // split funds between platforms, artist, and artist's
        // additional payee
        uint256 renderProviderRevenue_;
        address payable renderProviderAddress_;
        uint256 artistRevenue_;
        address payable artistAddress_;
        uint256 additionalPayeePrimaryRevenue_;
        address payable additionalPayeePrimaryAddress_;
        if (isEngine) {
            // get engine splits
            uint256 platformProviderRevenue_;
            address payable platformProviderAddress_;
            (
                renderProviderRevenue_,
                renderProviderAddress_,
                platformProviderRevenue_,
                platformProviderAddress_,
                artistRevenue_,
                artistAddress_,
                additionalPayeePrimaryRevenue_,
                additionalPayeePrimaryAddress_
            ) = IGenArt721CoreContractV3_Engine(genArtCoreContract)
                .getPrimaryRevenueSplits(projectId, valueInWei);
            // Platform Provider payment (only possible if engine)
            if (platformProviderRevenue_ > 0) {
                (success, ) = platformProviderAddress_.call{
                    value: platformProviderRevenue_
                }("");
                require(success, "Platform Provider payment failed");
            }
        } else {
            // get flagship splits
            (
                renderProviderRevenue_, // artblocks revenue
                renderProviderAddress_, // artblocks address
                artistRevenue_,
                artistAddress_,
                additionalPayeePrimaryRevenue_,
                additionalPayeePrimaryAddress_
            ) = IGenArt721CoreContractV3(genArtCoreContract)
                .getPrimaryRevenueSplits(projectId, valueInWei);
        }
        // Render Provider / Art Blocks payment
        if (renderProviderRevenue_ > 0) {
            (success, ) = renderProviderAddress_.call{
                value: renderProviderRevenue_
            }("");
            require(success, "Render Provider payment failed");
        }
        // artist payment
        if (artistRevenue_ > 0) {
            (success, ) = artistAddress_.call{value: artistRevenue_}("");
            require(success, "Artist payment failed");
        }
        // additional payee payment
        if (additionalPayeePrimaryRevenue_ > 0) {
            (success, ) = additionalPayeePrimaryAddress_.call{
                value: additionalPayeePrimaryRevenue_
            }("");
            require(success, "Additional Payee payment failed");
        }
    }

    /**
     * @notice splits ERC-20 funds between providers, artist, and artist's
     * additional payee, for a token purchased on project `_projectId`.
     * @dev possible DoS during splits is acknowledged, and mitigated by
     * business practices, including end-to-end testing on mainnet, and
     * admin-accepted artist payment addresses.
     */
    function splitFundsERC20(
        uint256 projectId,
        uint256 pricePerTokenInWei,
        address currencyAddress,
        address genArtCoreContract
    ) internal {
        IERC20 _projectCurrency = IERC20(currencyAddress);
        // split remaining funds between foundation, artist, and artist's
        // additional payee
        uint256 renderProviderRevenue_;
        address payable renderProviderAddress_;
        uint256 artistRevenue_;
        address payable artistAddress_;
        uint256 additionalPayeePrimaryRevenue_;
        address payable additionalPayeePrimaryAddress_;
        if (isEngine) {
            // get engine splits
            uint256 platformProviderRevenue_;
            address payable platformProviderAddress_;
            (
                renderProviderRevenue_,
                renderProviderAddress_,
                platformProviderRevenue_,
                platformProviderAddress_,
                artistRevenue_,
                artistAddress_,
                additionalPayeePrimaryRevenue_,
                additionalPayeePrimaryAddress_
            ) = IGenArt721CoreContractV3_Engine(genArtCoreContract)
                .getPrimaryRevenueSplits(projectId, pricePerTokenInWei);
            // Platform Provider payment (only possible if engine)
            if (platformProviderRevenue_ > 0) {
                _projectCurrency.transferFrom(
                    msg.sender,
                    platformProviderAddress_,
                    platformProviderRevenue_
                );
            }
        } else {
            // get flagship splits
            (
                renderProviderRevenue_, // artblocks revenue
                renderProviderAddress_, // artblocks address
                artistRevenue_,
                artistAddress_,
                additionalPayeePrimaryRevenue_,
                additionalPayeePrimaryAddress_
            ) = IGenArt721CoreContractV3(genArtCoreContract)
                .getPrimaryRevenueSplits(projectId, pricePerTokenInWei);
        }
        // Art Blocks payment
        if (renderProviderRevenue_ > 0) {
            _projectCurrency.transferFrom(
                msg.sender,
                renderProviderAddress_,
                renderProviderRevenue_
            );
        }
        // artist payment
        if (artistRevenue_ > 0) {
            _projectCurrency.transferFrom(
                msg.sender,
                artistAddress_,
                artistRevenue_
            );
        }
        // additional payee payment
        if (additionalPayeePrimaryRevenue_ > 0) {
            _projectCurrency.transferFrom(
                msg.sender,
                additionalPayeePrimaryAddress_,
                additionalPayeePrimaryRevenue_
            );
        }
    }

    /**
     * @notice Returns whether a V3 core contract is an Art Blocks Engine
     * contract or not. Return value of false indicates that the core is a
     * flagship contract.
     * @dev this function reverts if a core contract does not return the
     * expected number of return values from getPrimaryRevenueSplits() for
     * either a flagship or engine core contract.
     * @dev this function uses the length of the return data (in bytes) to
     * determine whether the core is an engine or not.
     * @param genArt721CoreV3 The address of the deployed core contract.
     */
    function _getV3CoreIsEngine(
        address genArt721CoreV3
    ) private returns (bool) {
        // call getPrimaryRevenueSplits() on core contract
        bytes memory payload = abi.encodeWithSignature(
            "getPrimaryRevenueSplits(uint256,uint256)",
            0,
            0
        );
        (bool success, bytes memory returnData) = genArt721CoreV3.call(payload);
        require(success, "getPrimaryRevenueSplits() call failed");
        // determine whether core is engine or not, based on return data length
        uint256 returnDataLength = returnData.length;
        if (returnDataLength == 6 * 32) {
            // 6 32-byte words returned if flagship (not engine)
            // @dev 6 32-byte words are expected because the non-engine core
            // contracts return a payout address and uint256 payment value for
            // the artist, and artist's additional payee, and Art Blocks.
            // also note that per Solidity ABI encoding, the address return
            // values are padded to 32 bytes.
            return false;
        } else if (returnDataLength == 8 * 32) {
            // 8 32-byte words returned if engine
            // @dev 8 32-byte words are expected because the engine core
            // contracts return a payout address and uint256 payment value for
            // the artist, artist's additional payee, render provider
            // typically Art Blocks, and platform provider (partner).
            // also note that per Solidity ABI encoding, the address return
            // values are padded to 32 bytes.
            return true;
        } else {
            // unexpected return value length
            revert("Unexpected revenue split bytes");
        }
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
// Created By: Art Blocks Inc.

import "../../interfaces/0.8.x/IGenArt721CoreContractV3_Base.sol";
import "../../interfaces/0.8.x/IMinterFilterV0.sol";
import "../../interfaces/0.8.x/IFilteredMinterV2.sol";
import "./MinterBase_v0_1_1.sol";

import "@openzeppelin-4.5/contracts/security/ReentrancyGuard.sol";

pragma solidity 0.8.17;

/**
 * @title Filtered Minter contract that allows tokens to be minted with ETH.
 * This is designed to be used with GenArt721CoreContractV3 flagship or
 * engine contracts.
 * @author Art Blocks Inc.
 * @notice Privileged Roles and Ownership:
 * This contract is designed to be managed, with limited powers.
 * Privileged roles and abilities are controlled by the project's artist, which
 * can be modified by the core contract's Admin ACL contract. Both of these
 * roles hold extensive power and can modify minter details.
 * Care must be taken to ensure that the admin ACL contract and artist
 * addresses are secure behind a multi-sig or other access control mechanism.
 * ----------------------------------------------------------------------------
 * The following functions are restricted to a project's artist:
 * - updatePricePerTokenInWei
 * - setProjectMaxInvocations
 * - manuallyLimitProjectMaxInvocations
 * ----------------------------------------------------------------------------
 * Additional admin and artist privileged roles may be described on other
 * contracts that this minter integrates with.
 */
contract MinterSetPriceV4 is ReentrancyGuard, MinterBase, IFilteredMinterV2 {
    /// Core contract address this minter interacts with
    address public immutable genArt721CoreAddress;

    /// The core contract integrates with V3 contracts
    IGenArt721CoreContractV3_Base private immutable genArtCoreContract_Base;

    /// Minter filter address this minter interacts with
    address public immutable minterFilterAddress;

    /// Minter filter this minter may interact with.
    IMinterFilterV0 private immutable minterFilter;

    /// minterType for this minter
    string public constant minterType = "MinterSetPriceV4";

    /// minter version for this minter
    string public constant minterVersion = "v4.1.0";

    uint256 constant ONE_MILLION = 1_000_000;

    struct ProjectConfig {
        bool maxHasBeenInvoked;
        bool priceIsConfigured;
        uint24 maxInvocations;
        uint256 pricePerTokenInWei;
    }

    mapping(uint256 => ProjectConfig) public projectConfig;

    function _onlyArtist(uint256 _projectId) internal view {
        require(
            msg.sender ==
                genArtCoreContract_Base.projectIdToArtistAddress(_projectId),
            "Only Artist"
        );
    }

    /**
     * @notice Initializes contract to be a Filtered Minter for
     * `_minterFilter`, integrated with Art Blocks core contract
     * at address `_genArt721Address`.
     * @param _genArt721Address Art Blocks core contract address for
     * which this contract will be a minter.
     * @param _minterFilter Minter filter for which this will be a
     * filtered minter.
     */
    constructor(
        address _genArt721Address,
        address _minterFilter
    ) ReentrancyGuard() MinterBase(_genArt721Address) {
        genArt721CoreAddress = _genArt721Address;
        // always populate immutable engine contracts, but only use appropriate
        // interface based on isEngine in the rest of the contract
        genArtCoreContract_Base = IGenArt721CoreContractV3_Base(
            _genArt721Address
        );
        minterFilterAddress = _minterFilter;
        minterFilter = IMinterFilterV0(_minterFilter);
        require(
            minterFilter.genArt721CoreAddress() == _genArt721Address,
            "Illegal contract pairing"
        );
    }

    /**
     * @notice Syncs local maximum invocations of project `_projectId` based on
     * the value currently defined in the core contract.
     * @param _projectId Project ID to set the maximum invocations for.
     * @dev this enables gas reduction after maxInvocations have been reached -
     * core contracts shall still enforce a maxInvocation check during mint.
     */
    function setProjectMaxInvocations(uint256 _projectId) public {
        _onlyArtist(_projectId);
        uint256 maxInvocations;
        uint256 invocations;
        (invocations, maxInvocations, , , , ) = genArtCoreContract_Base
            .projectStateData(_projectId);
        // update storage with results
        projectConfig[_projectId].maxInvocations = uint24(maxInvocations);

        // We need to ensure maxHasBeenInvoked is correctly set after manually syncing the
        // local maxInvocations value with the core contract's maxInvocations value.
        // This synced value of maxInvocations from the core contract will always be greater
        // than or equal to the previous value of maxInvocations stored locally.
        projectConfig[_projectId].maxHasBeenInvoked =
            invocations == maxInvocations;

        emit ProjectMaxInvocationsLimitUpdated(_projectId, maxInvocations);
    }

    /**
     * @notice Manually sets the local maximum invocations of project `_projectId`
     * with the provided `_maxInvocations`, checking that `_maxInvocations` is less
     * than or equal to the value of project `_project_id`'s maximum invocations that is
     * set on the core contract.
     * @dev Note that a `_maxInvocations` of 0 can only be set if the current `invocations`
     * value is also 0 and this would also set `maxHasBeenInvoked` to true, correctly short-circuiting
     * this minter's purchase function, avoiding extra gas costs from the core contract's maxInvocations check.
     * @param _projectId Project ID to set the maximum invocations for.
     * @param _maxInvocations Maximum invocations to set for the project.
     */
    function manuallyLimitProjectMaxInvocations(
        uint256 _projectId,
        uint256 _maxInvocations
    ) external {
        _onlyArtist(_projectId);
        // CHECKS
        // ensure that the manually set maxInvocations is not greater than what is set on the core contract
        uint256 maxInvocations;
        uint256 invocations;
        (invocations, maxInvocations, , , , ) = genArtCoreContract_Base
            .projectStateData(_projectId);
        require(
            _maxInvocations <= maxInvocations,
            "Cannot increase project max invocations above core contract set project max invocations"
        );
        require(
            _maxInvocations >= invocations,
            "Cannot set project max invocations to less than current invocations"
        );

        // EFFECTS
        // update storage with results
        projectConfig[_projectId].maxInvocations = uint24(_maxInvocations);
        // We need to ensure maxHasBeenInvoked is correctly set after manually setting the
        // local maxInvocations value.
        projectConfig[_projectId].maxHasBeenInvoked =
            invocations == _maxInvocations;

        emit ProjectMaxInvocationsLimitUpdated(_projectId, _maxInvocations);
    }

    /**
     * @notice Warning: Disabling purchaseTo is not supported on this minter.
     * This method exists purely for interface-conformance purposes.
     */
    function togglePurchaseToDisabled(uint256 _projectId) external view {
        _onlyArtist(_projectId);
        revert("Action not supported");
    }

    /**
     * @notice projectId => has project reached its maximum number of
     * invocations? Note that this returns a local cache of the core contract's
     * state, and may be out of sync with the core contract. This is
     * intentional, as it only enables gas optimization of mints after a
     * project's maximum invocations has been reached. A false negative will
     * only result in a gas cost increase, since the core contract will still
     * enforce a maxInvocation check during minting. A false positive is not
     * possible because the V3 core contract only allows maximum invocations
     * to be reduced, not increased. Based on this rationale, we intentionally
     * do not do input validation in this method as to whether or not the input
     * `_projectId` is an existing project ID.
     */
    function projectMaxHasBeenInvoked(
        uint256 _projectId
    ) external view returns (bool) {
        return projectConfig[_projectId].maxHasBeenInvoked;
    }

    /**
     * @notice projectId => project's maximum number of invocations.
     * Optionally synced with core contract value, for gas optimization.
     * Note that this returns a local cache of the core contract's
     * state, and may be out of sync with the core contract. This is
     * intentional, as it only enables gas optimization of mints after a
     * project's maximum invocations has been reached.
     * @dev A number greater than the core contract's project max invocations
     * will only result in a gas cost increase, since the core contract will
     * still enforce a maxInvocation check during minting. A number less than
     * the core contract's project max invocations is only possible when the
     * project's max invocations have not been synced on this minter, since the
     * V3 core contract only allows maximum invocations to be reduced, not
     * increased. When this happens, the minter will enable minting, allowing
     * the core contract to enforce the max invocations check. Based on this
     * rationale, we intentionally do not do input validation in this method as
     * to whether or not the input `_projectId` is an existing project ID.
     */
    function projectMaxInvocations(
        uint256 _projectId
    ) external view returns (uint256) {
        return uint256(projectConfig[_projectId].maxInvocations);
    }

    /**
     * @notice Updates this minter's price per token of project `_projectId`
     * to be '_pricePerTokenInWei`, in Wei.
     * This price supersedes any legacy core contract price per token value.
     * @dev Note that it is intentionally supported here that the configured
     * price may be explicitly set to `0`.
     */
    function updatePricePerTokenInWei(
        uint256 _projectId,
        uint256 _pricePerTokenInWei
    ) external {
        _onlyArtist(_projectId);
        ProjectConfig storage _projectConfig = projectConfig[_projectId];
        _projectConfig.pricePerTokenInWei = _pricePerTokenInWei;
        _projectConfig.priceIsConfigured = true;
        emit PricePerTokenInWeiUpdated(_projectId, _pricePerTokenInWei);

        // sync local max invocations if not initially populated
        // @dev if local max invocations and maxHasBeenInvoked are both
        // initial values, we know they have not been populated.
        if (
            _projectConfig.maxInvocations == 0 &&
            _projectConfig.maxHasBeenInvoked == false
        ) {
            setProjectMaxInvocations(_projectId);
        }
    }

    /**
     * @notice Purchases a token from project `_projectId`.
     * @param _projectId Project ID to mint a token on.
     * @return tokenId Token ID of minted token
     */
    function purchase(
        uint256 _projectId
    ) external payable returns (uint256 tokenId) {
        tokenId = purchaseTo_do6(msg.sender, _projectId);
        return tokenId;
    }

    /**
     * @notice gas-optimized version of purchase(uint256).
     */
    function purchase_H4M(
        uint256 _projectId
    ) external payable returns (uint256 tokenId) {
        tokenId = purchaseTo_do6(msg.sender, _projectId);
        return tokenId;
    }

    /**
     * @notice Purchases a token from project `_projectId` and sets
     * the token's owner to `_to`.
     * @param _to Address to be the new token's owner.
     * @param _projectId Project ID to mint a token on.
     * @return tokenId Token ID of minted token
     */
    function purchaseTo(
        address _to,
        uint256 _projectId
    ) external payable returns (uint256 tokenId) {
        return purchaseTo_do6(_to, _projectId);
    }

    /**
     * @notice gas-optimized version of purchaseTo(address, uint256).
     */
    function purchaseTo_do6(
        address _to,
        uint256 _projectId
    ) public payable nonReentrant returns (uint256 tokenId) {
        // CHECKS
        ProjectConfig storage _projectConfig = projectConfig[_projectId];

        // Note that `maxHasBeenInvoked` is only checked here to reduce gas
        // consumption after a project has been fully minted.
        // `_projectConfig.maxHasBeenInvoked` is locally cached to reduce
        // gas consumption, but if not in sync with the core contract's value,
        // the core contract also enforces its own max invocation check during
        // minting.
        require(
            !_projectConfig.maxHasBeenInvoked,
            "Maximum number of invocations reached"
        );

        // require artist to have configured price of token on this minter
        require(_projectConfig.priceIsConfigured, "Price not configured");

        // load price of token into memory
        uint256 pricePerTokenInWei = _projectConfig.pricePerTokenInWei;

        require(
            msg.value >= pricePerTokenInWei,
            "Must send minimum value to mint!"
        );

        // EFFECTS
        tokenId = minterFilter.mint(_to, _projectId, msg.sender);

        // invocation is token number plus one, and will never overflow due to
        // limit of 1e6 invocations per project. block scope for gas efficiency
        // (i.e. avoid an unnecessary var initialization to 0).
        unchecked {
            uint256 tokenInvocation = (tokenId % ONE_MILLION) + 1;
            uint256 localMaxInvocations = _projectConfig.maxInvocations;
            // handle the case where the token invocation == minter local max
            // invocations occurred on a different minter, and we have a stale
            // local maxHasBeenInvoked value returning a false negative.
            // @dev this is a CHECK after EFFECTS, so security was considered
            // in detail here.
            require(
                tokenInvocation <= localMaxInvocations,
                "Maximum invocations reached"
            );
            // in typical case, update the local maxHasBeenInvoked value
            // to true if the token invocation == minter local max invocations
            // (enables gas efficient reverts after sellout)
            if (tokenInvocation == localMaxInvocations) {
                _projectConfig.maxHasBeenInvoked = true;
            }
        }

        // INTERACTIONS
        splitFundsETH(_projectId, pricePerTokenInWei, genArt721CoreAddress);

        return tokenId;
    }

    /**
     * @notice Gets if price of token is configured, price of minting a
     * token on project `_projectId`, and currency symbol and address to be
     * used as payment. Supersedes any core contract price information.
     * @param _projectId Project ID to get price information for.
     * @return isConfigured true only if token price has been configured on
     * this minter
     * @return tokenPriceInWei current price of token on this minter - invalid
     * if price has not yet been configured
     * @return currencySymbol currency symbol for purchases of project on this
     * minter. This minter always returns "ETH"
     * @return currencyAddress currency address for purchases of project on
     * this minter. This minter always returns null address, reserved for ether
     */
    function getPriceInfo(
        uint256 _projectId
    )
        external
        view
        returns (
            bool isConfigured,
            uint256 tokenPriceInWei,
            string memory currencySymbol,
            address currencyAddress
        )
    {
        ProjectConfig storage _projectConfig = projectConfig[_projectId];
        isConfigured = _projectConfig.priceIsConfigured;
        tokenPriceInWei = _projectConfig.pricePerTokenInWei;
        currencySymbol = "ETH";
        currencyAddress = address(0);
    }
}