// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/Address.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
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
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!Address.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initialized`
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initializing`
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import 'lib/openzeppelin-contracts/contracts/proxy/utils/Initializable.sol';

contract MarketplaceV1 is Initializable {
    struct Collection {
        bool listed;
        uint8 royalties;
        address collection;
    }

    struct Listing {
        bool active;
        address seller;
        uint256 price;
    }

    bool private lock;
    uint8 public percentageFee;
    address public owner;

    // Listed collections on marketplace - contract addresses
    address[] private collections;
    // collection contract address -> Collection
    mapping(address => Collection) private listedCollections;
    // collection contract address -> nftId -> Listing
    mapping(address => mapping(uint256 => Listing)) private listings;

    event Listed(address indexed collection, address indexed seller, uint256 nftId, uint256 price);
    event UpdateListing(address indexed collection, address indexed seller, uint256 nftId, uint256 newPrice);
    event CancelListing(address indexed collection, address indexed seller, uint256 nftId);
    event Bought(address indexed collection, address indexed buyer, uint256 nftId, uint256 price);

    error Unauthorized();
    error Locked();
    error AlreadyListed();
    error InvalidCollection();
    error NotListed();
    error InvalidPayment();
    error IsZeroAddress();

    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert Unauthorized();
        }
        _;
    }

    modifier locked() {
        if (lock) {
            revert Locked();
        }
        lock = true;
        _;
        lock = false;
    }

    /* ---------- EXTERNAL ----------  */

    function initialize(address newOwner, uint8 fee) external initializer {
        _assertIsNotZeroAddress(newOwner);

        owner = newOwner;
        percentageFee = fee;
    }

    /**
     * @notice Transfer ownership of the contract.
     *
     * @param newOwner The address of the new owner
     */
    function transferOwnership(address newOwner) external onlyOwner {
        _assertIsNotZeroAddress(newOwner);

        owner = newOwner;
    }

    /**
     * @notice Withdraw marketplace funds.
     */
    function withdraw() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}('');
        require(success);
    }

    /**
     * @notice Set marketplace fee
     *
     * @param fee The new marketplace fee
     */
    function setFee(uint8 fee) external onlyOwner {
        percentageFee = fee;
    }

    /**
     * @notice Updates `collection` creator royalties
     *
     * @param collection The contract address of the collection
     * @param royalties The new creator royalties percentage
     */
    function updateCollectionRoyalties(address collection, uint8 royalties) external onlyOwner {
        _assertIsValidCollection(collection);

        listedCollections[collection].royalties = royalties;
    }

    /**
     * @notice Allows to list a collection in marketplace
     *
     * @param collection The contract address of the collection
     * @param creator The address of the collection's creator
     * @param royalties The creator royalties percentage
     */
    function listInMarketplace(
        address collection,
        address creator,
        uint8 royalties
    ) external onlyOwner {
        _assertIsTheCollectionOwner(collection, creator);
        _assertIsNotListed(collection);

        listedCollections[collection] = Collection({listed: true, royalties: royalties, collection: collection});
        collections.push(collection);
    }

    /**
     * @notice Gets marketplace listed collections.
     *
     * @return address[] the list of collections
     */
    function getCollections() external view returns (address[] memory) {
        return collections;
    }

    /**
     * @notice Gets marketplace listed collections.
     *
     * @param collection The contract address of the collection
     *
     * @return uint8 the collection royalties percentage
     */
    function getCollectionRoyalties(address collection) external view returns (uint8) {
        _assertIsValidCollection(collection);

        return listedCollections[collection].royalties;
    }

    /**
     * @notice Allow an nft owner to list his nft
     *
     * @param collection The contract address of the collection
     * @param nftId The NFT ID
     * @param price The listing price
     */
    function list(
        address collection,
        uint256 nftId,
        uint256 price
    ) external locked {
        _assertIsValidCollection(collection);
        _assertIsNftOwner(collection, nftId);
        _assertNftIsNotListed(collection, nftId);

        _transferNftToMarketplace(collection, nftId);
        listings[collection][nftId] = Listing({active: true, seller: msg.sender, price: price});

        emit Listed(collection, msg.sender, nftId, price);
    }

    /**
     * @notice Allow an nft owner to update his listing
     *
     * @param collection The contract address of the collection
     * @param nftId The NFT ID
     * @param newPrice The listing price
     */
    function updateListing(
        address collection,
        uint256 nftId,
        uint256 newPrice
    ) external locked {
        _assertIsValidCollection(collection);
        _assertIsNftOwner(collection, nftId);
        _assertNftIsListed(collection, nftId);

        listings[collection][nftId].price = newPrice;

        emit UpdateListing(collection, msg.sender, nftId, newPrice);
    }

    /**
     * @notice Allow an nft owner to cancel the listing of his nft
     *
     * @param collection The contract address of the collection
     * @param nftId The NFT ID
     */
    function cancelListing(address collection, uint256 nftId) external locked {
        _assertIsValidCollection(collection);
        _assertIsNftOwner(collection, nftId);
        _assertNftIsListed(collection, nftId);

        delete listings[collection][nftId];
        _transferNftToUser(collection, nftId);

        emit CancelListing(collection, msg.sender, nftId);
    }

    /**
     * @notice Allow an nft owner to list his nft
     *
     * @param collection The contract address of the collection
     * @param nftId The NFT ID
     */
    function buy(address collection, uint256 nftId) external payable locked {
        _assertIsValidCollection(collection);
        _assertNftIsListed(collection, nftId);
        _assertIsNotSeller(collection, nftId);
        _assertPaymentIsCorrect(collection, nftId);

        Listing memory listing = listings[collection][nftId];
        delete listings[collection][nftId];
        _transferNftToUser(collection, nftId);

        uint256 creatorFee = _calculateFee(listing.price, listedCollections[collection].royalties);
        uint256 marketplaceFee = _calculateFee(listing.price, percentageFee);

        (bool sellerPayout, ) = payable(listing.seller).call{value: listing.price - creatorFee - marketplaceFee}('');
        require(sellerPayout);

        (bool creatorPayout, ) = payable(_getCollectionOwner(collection)).call{value: creatorFee}('');
        require(creatorPayout);

        emit Bought(collection, msg.sender, nftId, listing.price);
    }

    /* ---------- PRIVATE ---------- */

    /**
     * @notice Transfer `nftId` from `msg.sender` to marketplace
     * @dev It needs to be approved before call
     *
     * @param collection The contract address of the collection
     * @param nftId The NFT ID
     */
    function _transferNftToMarketplace(address collection, uint256 nftId) private {
        (bool success, ) = collection.call(
            abi.encodeWithSignature('transferFrom(address,address,uint256)', msg.sender, address(this), nftId)
        );
        require(success);
    }

    /**
     * @notice Transfer `nftId` from marketplace to `msg.sender`
     *
     * @param collection The contract address of the collection
     * @param nftId The NFT ID
     */
    function _transferNftToUser(address collection, uint256 nftId) private {
        (bool success, ) = collection.call(
            abi.encodeWithSignature('safeTransferFrom(address,address,uint256)', address(this), msg.sender, nftId)
        );
        require(success);
    }

    /**
     * @notice Calculate the total amount of fee for `price`
     *
     * @param price the price of the nft
     * @param fee the fee
     *
     * @return uint256 the fee value
     */
    function _calculateFee(uint256 price, uint8 fee) private pure returns (uint256) {
        return (price * fee) / 100;
    }

    /**
     * @notice Get the owner of a collection
     *
     * @param collection The contract address of the collection
     *
     * @return address the collection owner
     */
    function _getCollectionOwner(address collection) private returns (address) {
        (bool success, bytes memory result) = collection.call(abi.encodeWithSignature('owner()'));
        require(success);

        return abi.decode(result, (address));
    }

    /* ---------- PRIVATE - ASSERTIONS ---------- */

    /**
     * @notice Assert a contract owner
     * @dev Throws unless `msg.sender` is the `collection` owner
     *
     * @param collection The contract address of the collection
     * @param creator The address of the collection's creator
     */
    function _assertIsTheCollectionOwner(address collection, address creator) private {
        address result = _getCollectionOwner(collection);

        if (result == creator) {
            return;
        }

        revert Unauthorized();
    }

    /**
     * @notice Assert that a collection is still not listed in the marketplace
     * @dev Throws unless `collection` is not listed
     *
     * @param collection The contract address of the collection
     */
    function _assertIsNotListed(address collection) private view {
        if (!listedCollections[collection].listed) {
            return;
        }

        revert AlreadyListed();
    }

    /**
     * @notice Assert that a collection is valid - listed in the marketplace
     * @dev Throws unless `collection` is listed
     *
     * @param collection The contract address of the collection
     */
    function _assertIsValidCollection(address collection) private view {
        if (listedCollections[collection].listed) {
            return;
        }

        revert InvalidCollection();
    }

    /**
     * @notice Assert that `msg.sender` is the owner of `nftId` from `collecton`
     * @dev Throws unless `msg.sender` is the `nftId` owner
     *
     * @param collection The contract address of the collection
     * @param nftId The NFT ID
     */
    function _assertIsNftOwner(address collection, uint256 nftId) private {
        if (listings[collection][nftId].seller == msg.sender) {
            return;
        }

        (bool success, bytes memory result) = collection.call(abi.encodeWithSignature('ownerOf(uint256)', nftId));
        require(success);

        if (abi.decode(result, (address)) == msg.sender) {
            return;
        }

        revert Unauthorized();
    }

    /**
     * @notice Assert that `msg.sender` is not the seller of `nftId` from `collecton`
     * @dev Throws unless `msg.sender` is not the `nftId` owner
     *
     * @param collection The contract address of the collection
     * @param nftId The NFT ID
     */
    function _assertIsNotSeller(address collection, uint256 nftId) private view {
        if (listings[collection][nftId].seller != msg.sender) {
            return;
        }

        revert Unauthorized();
    }

    /**
     * @notice Assert that `nftId` is not already listed
     * @dev Throws unless `nftId` is not listed
     *
     * @param collection The contract address of the collection
     * @param nftId The NFT ID
     */
    function _assertNftIsNotListed(address collection, uint256 nftId) private view {
        if (!listings[collection][nftId].active) {
            return;
        }

        revert AlreadyListed();
    }

    /**
     * @notice Assert that `nftId` is listed
     * @dev Throws unless `nftId` is listed
     *
     * @param collection The contract address of the collection
     * @param nftId The NFT ID
     */
    function _assertNftIsListed(address collection, uint256 nftId) private view {
        if (listings[collection][nftId].active) {
            return;
        }

        revert NotListed();
    }

    /**
     * @notice Assert that `msg.value` is equal to the listing price
     * @dev Throws unless `msg.value` is equal to listing price
     *
     * @param collection The contract address of the collection
     * @param nftId The NFT ID
     */
    function _assertPaymentIsCorrect(address collection, uint256 nftId) private view {
        if (listings[collection][nftId].price == msg.value) {
            return;
        }

        revert InvalidPayment();
    }

    /**
     * @notice Assert that `target` is not the zero address
     * @dev Throws unless `target` is not the zero address
     *
     * @param target The address to verify
     */
    function _assertIsNotZeroAddress(address target) private pure {
        if (target != address(0)) {
            return;
        }

        revert IsZeroAddress();
    }
}