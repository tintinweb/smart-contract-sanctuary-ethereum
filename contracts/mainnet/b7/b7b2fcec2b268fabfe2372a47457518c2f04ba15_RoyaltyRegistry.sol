// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./RoyaltyStorage.sol";
import "../interfaces/IFormula.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract RoyaltyRegistry is RoyaltyStorage {
    /// @dev emitted when royalties set for token.
    event RoyaltySetForCollection(address indexed _token, uint96 _royaltyRate);

    event ReceiverUpdated(address oldReceiver, address newReceiver);

    event ModelFactoryUpdated(address oldFactory, address newFactory);

    event DefaultRoyaltyRatePercentageUpdated(uint96 oldRate, uint96 newRate);

    event CollectionManagerUpdated(address indexed _oldAddress, address _newAddress);

    event CollectionAuthorizedSignerAddressUpdated(address indexed _oldAddress, address _newAddress);

    event CollectionOwnerUpdated(address indexed _oldAddress, address _newAddress);

    event BaseContractURIUpdated(string oldBaseContractURI, string newBaseContractURI);

    event NFTFormulaUpdated(address indexed _oldAddress, address _newAddress);

    modifier onlyOwnerOrFactory() {
        require(msg.sender == owner() || msg.sender == modelFactory, "Unauthorized");
        _;
    }

    /**
     * @notice Initialization for upgradeable contract.
     *
     * @param _receiver receiver address.
     * @param _defaultRateRoyaltyPercentage default royalty percentage.
     *
     */
    function initialize(
        address _receiver,
        uint96 _defaultRateRoyaltyPercentage,
        address _collectionOwner,
        address _collectionManager,
        address _collectionAuthorizedSignerAddress
    ) external initializer {
        require(_receiver != address(0), "Invalid receiver address");
        require(_collectionOwner != address(0), "Invalid owner address");
        require(_collectionManager != address(0), "Invalid manager address");
        require(_collectionAuthorizedSignerAddress != address(0), "Invalid signer address");

        receiver = _receiver;
        defaultRoyaltyRatePercentage = _defaultRateRoyaltyPercentage;
        collectionOwner = _collectionOwner;
        collectionManager = _collectionManager;
        collectionAuthorizedSignerAddress = _collectionAuthorizedSignerAddress;

        __Ownable_init_unchained();
    }

    /**
     * @dev setter for receiver address.
     *
     * @param _newReceiver new Receiver address
     *
     */
    function changeReceiver(address _newReceiver) external onlyOwner {
        require(_newReceiver != address(0), "Invalid address");
        address oldReceiver = receiver;
        receiver = _newReceiver;

        emit ReceiverUpdated(oldReceiver, receiver);
    }

    /**
     * @dev setter for model factory address.
     *
     * @param _newModelFactory new Receiver address
     *
     */
    function changeModelFactory(address _newModelFactory) external onlyOwner {
        require(_newModelFactory != address(0), "Invalid address");
        address oldModelFactory = modelFactory;
        modelFactory = _newModelFactory;

        emit ModelFactoryUpdated(oldModelFactory, modelFactory);
    }

    /**
     * @dev setter for nft formula address.
     *
     * @param _newNftFormula new address of nft formula
     */
    function changeNFTFormula(address _newNftFormula) external onlyOwner {
        require(_newNftFormula != address(0), "Invalid nft formula address");
        address oldNftFormula = nftFormula;
        nftFormula = _newNftFormula;

        emit NFTFormulaUpdated(oldNftFormula, nftFormula);
    }

    /**
     * @dev setter for defaultRoyaltyRatePercentage
     * @notice the deafult royalty rate can be 0.
     *
     * @param _newDefaultRate new default rate for royalty.
     *
     */
    function changeDefaultRoyaltyRatePercentage(uint96 _newDefaultRate) external onlyOwner {
        require(_newDefaultRate <= MAX_RATE_ROYALTY, "Invalid Rate");
        uint96 oldDefaultRoyaltyRatePercentage = defaultRoyaltyRatePercentage;
        defaultRoyaltyRatePercentage = _newDefaultRate;

        emit DefaultRoyaltyRatePercentageUpdated(oldDefaultRoyaltyRatePercentage, defaultRoyaltyRatePercentage);
    }

    /**
     * @dev set royalty rate for specific collection. Support multiple set. The length of array between tokens & rates must exactly the same.
     * @notice the rate will be applied to all of token ids inside the collection.
     * @notice only owner can call the multiple set.
     *
     * @param _tokens array of token address.
     * @param _royaltyRates array of royalty rates.
     */
    function setRoyaltyRateForCollections(
        address[] calldata _tokens,
        uint96[] calldata _royaltyRates,
        address[] calldata _royaltyReceivers
    ) external onlyOwner {
        require(_tokens.length == _royaltyRates.length, "Mismatch royaltyRates length");
        require(_tokens.length == _royaltyReceivers.length, "Mismatch royaltyReceivers length");

        for (uint256 i = 0; i < _tokens.length; i++) {
            _setRoyaltyForCollection(_tokens[i], _royaltyRates[i], _royaltyReceivers[i]);
        }
    }

    /**
     * @dev set royalty rate for specific collection. Support multiple set. The length of array between tokens & rates must exactly the same.
     * @notice the rate will be applied to all of token ids inside the collection.
     * @notice Owner or factory can perform this function call.
     *
     * @param _token token address.
     * @param _royaltyRate royalty rate.
     */
    function setRoyaltyRateForCollection(
        address _token,
        uint96 _royaltyRate,
        address _royaltyReceiver
    ) external onlyOwnerOrFactory {
        _setRoyaltyForCollection(_token, _royaltyRate, _royaltyReceiver);
    }

    /**
     * @dev internal setter royalty rate for collection.
     *
     * @param _token token / collection address.
     * @param _royaltyRate royalty rate for that particular collection.
     */
    function _setRoyaltyForCollection(
        address _token,
        uint96 _royaltyRate,
        address _royaltyReceiver
    ) private {
        require(_token != address(0), "Invalid token");
        require(_royaltyReceiver != address(0), "Invalid receiver address");
        require(_royaltyRate <= MAX_RATE_ROYALTY, "Invalid Rate");

        RoyaltySet memory _royaltySet = RoyaltySet({
            isSet: true,
            royaltyRateForCollection: _royaltyRate,
            royaltyReceiver: _royaltyReceiver
        });

        royaltiesSet[_token] = _royaltySet;

        emit RoyaltySetForCollection(_token, _royaltyRate);
    }

    /**
     * @dev royalty info for specific token / collection.
     * @dev It will return custom rate for the token, otherwise will return the default one.
     *
     * @param _token address of token / collection.
     *
     * @return _receiver receiver address.
     * @return _royaltyRatePercentage royalty rate percentage.
     */
    function getRoyaltyInfo(address _token) external view returns (address _receiver, uint96 _royaltyRatePercentage) {
        RoyaltySet memory _royaltySet = royaltiesSet[_token];
        return (
            _royaltySet.royaltyReceiver != address(0) ? _royaltySet.royaltyReceiver : receiver,
            _royaltySet.isSet ? _royaltySet.royaltyRateForCollection : defaultRoyaltyRatePercentage
        );
    }

    /**
     * @dev Update the authorized signer address.
     *
     * @param _collectionSignerAddress new authorized signer address.
     */
    function changeCollectionAuthorizedSignerAddress(address _collectionSignerAddress) external onlyOwner {
        require(_collectionSignerAddress != address(0), "Invalid address");
        address oldSignerAddress = collectionAuthorizedSignerAddress;
        collectionAuthorizedSignerAddress = _collectionSignerAddress;
        emit CollectionAuthorizedSignerAddressUpdated(oldSignerAddress, collectionAuthorizedSignerAddress);
    }

    /**
     * @notice Setter for manager address.
     * @dev Can be called only by the current manager.
     *
     * @param _collectionManager new manager address.
     */
    function changeCollectionManager(address _collectionManager) external onlyOwner {
        require(_collectionManager != address(0), "Invalid address");
        address oldManagerAddress = collectionManager;
        collectionManager = _collectionManager;

        emit CollectionManagerUpdated(oldManagerAddress, collectionManager);
    }

    /**
     * @dev Update the authorized signer address.
     *
     * @param _collectionOwner new authorized signer address.
     */
    function changeCollectionOwner(address _collectionOwner) external onlyOwner {
        require(_collectionOwner != address(0), "Invalid address");
        address oldOwner = collectionOwner;
        collectionOwner = _collectionOwner;
        emit CollectionOwnerUpdated(oldOwner, collectionOwner);
    }

    /**
     * @dev Update baseContractURI.
     *
     * @param _baseContractURI new base contract URI.
     */
    function changeContractURI(string memory _baseContractURI) external onlyOwner {
        string memory oldBaseContractURI = baseContractURI;
        baseContractURI = _baseContractURI;
        emit BaseContractURIUpdated(oldBaseContractURI, baseContractURI);
    }

    /**
     * @dev full contract URI based on collection contract.
     *
     * @return string of full contract uri.
     */
    function getContractURIForToken() external view returns (string memory) {
        return string(abi.encodePacked(baseContractURI, Strings.toHexString(msg.sender)));
    }

    /**
     * @dev get token price of collection address
     *
     * @param _formulaType the formula type
     *
     * @return _price of the collection address based on formula type
     */
    function getTokenPrice(uint256 _formulaType) external view returns (uint256 _price) {
        return IFormula(nftFormula).getTokenPrice(_formulaType, msg.sender);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract RoyaltyStorage is OwnableUpgradeable {
    struct RoyaltySet {
        bool isSet;
        uint96 royaltyRateForCollection;
        address royaltyReceiver;
    }

    /// @dev storing royalty amount percentages for particular collection.
    mapping(address => RoyaltySet) public royaltiesSet;

    /// @dev default royalty percentage;
    uint96 public defaultRoyaltyRatePercentage;

    /// @dev receiver address of royalty.
    address public receiver;

    /// @dev model factory address.
    address public modelFactory;

    uint96 public constant MAX_RATE_ROYALTY = 1000;

    /// @notice the authorized address who can change some configuration of collections.
    address public collectionManager;

    /// @dev authorized address who can sign the arbitrary data to allow minting for collections.
    address public collectionAuthorizedSignerAddress;

    /// @dev owner for collections.
    address public collectionOwner;

    /// @dev custom metadata to be used for opensea
    string public baseContractURI;

    /// @dev address for NFT formula to get the price
    address public nftFormula;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IFormula {
    function getTokenPrice(uint256 _formulaType, address _collectionAddress) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

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
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
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
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
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
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
}