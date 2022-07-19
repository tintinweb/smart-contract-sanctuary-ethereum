/*
  ･
   *　★
      ･ ｡
        　･　ﾟ☆ ｡
  　　　 *　★ ﾟ･｡ *  ｡
          　　* ☆ ｡･ﾟ*.｡
      　　　ﾟ *.｡☆｡★　･
​
                      `                     .-:::::-.`              `-::---...```
                     `-:`               .:+ssssoooo++//:.`       .-/+shhhhhhhhhhhhhyyyssooo:
                    .--::.            .+ossso+/////++/:://-`   .////+shhhhhhhhhhhhhhhhhhhhhy
                  `-----::.         `/+////+++///+++/:--:/+/-  -////+shhhhhhhhhhhhhhhhhhhhhy
                 `------:::-`      `//-.``.-/+ooosso+:-.-/oso- -////+shhhhhhhhhhhhhhhhhhhhhy
                .--------:::-`     :+:.`  .-/osyyyyyyso++syhyo.-////+shhhhhhhhhhhhhhhhhhhhhy
              `-----------:::-.    +o+:-.-:/oyhhhhhhdhhhhhdddy:-////+shhhhhhhhhhhhhhhhhhhhhy
             .------------::::--  `oys+/::/+shhhhhhhdddddddddy/-////+shhhhhhhhhhhhhhhhhhhhhy
            .--------------:::::-` +ys+////+yhhhhhhhddddddddhy:-////+yhhhhhhhhhhhhhhhhhhhhhy
          `----------------::::::-`.ss+/:::+oyhhhhhhhhhhhhhhho`-////+shhhhhhhhhhhhhhhhhhhhhy
         .------------------:::::::.-so//::/+osyyyhhhhhhhhhys` -////+shhhhhhhhhhhhhhhhhhhhhy
       `.-------------------::/:::::..+o+////+oosssyyyyyyys+`  .////+shhhhhhhhhhhhhhhhhhhhhy
       .--------------------::/:::.`   -+o++++++oooosssss/.     `-//+shhhhhhhhhhhhhhhhhhhhyo
     .-------   ``````.......--`        `-/+ooooosso+/-`          `./++++///:::--...``hhhhyo
                                              `````
   *　
      ･ ｡
　　　　･　　ﾟ☆ ｡
  　　　 *　★ ﾟ･｡ *  ｡
          　　* ☆ ｡･ﾟ*.｡
      　　　ﾟ *.｡☆｡★　･
    *　　ﾟ｡·*･｡ ﾟ*
  　　　☆ﾟ･｡°*. ﾟ
　 ･ ﾟ*｡･ﾟ★｡
　　･ *ﾟ｡　　 *
　･ﾟ*｡★･
 ☆∴｡　*
･ ｡
*/

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./libraries/AddressLibrary.sol";
import "./mixins/OZ/ERC165Checker.sol";
import "./interfaces/IBatchMintAndRevealCollection.sol";
import "./interfaces/ICollectionContractInitializer.sol";
import "./interfaces/ICollectionFactory.sol";
import "./interfaces/IRoles.sol";

/**
 * @title A factory to create NFT collections.
 * @notice Call this factory to create a batch mint and reveal collection.
 * @dev This creates and initializes an ERC-1165 minimal proxy pointing to a NFT collection contract template.
 */
contract FNDCollectionDropFactory is Initializable, ICollectionFactory {
  using AddressLibrary for address;
  using AddressUpgradeable for address;
  using AddressUpgradeable for address payable;
  using Clones for address;
  using OZERC165Checker for address;
  using Strings for uint256;

  /**
   * @notice The address of the template all new BatchMintAndRevealCollections will leverage.
   */
  address public implementationBatchMintAndReveal;

  /**
   * @notice The address of the template all new CollectionContract will leverage.
   */
  address public implementationCollection;

  /**
   * @notice The implementation version new BatchMintAndReveal collections will use.
   * @dev This is auto-incremented each time the implementation is changed.
   */
  uint256 public versionBatchMintAndReveal;

  /**
   * @notice The implementation version new CollectionContract collections will use.
   * @dev This is auto-incremented each time the implementation is changed.
   */
  uint256 public versionCollection;

  /**
   * @notice The contract address which manages common roles.
   * @dev Used by the collections for a shared operator definition.
   */
  IRoles public immutable rolesContract;

  /**
   * @notice Default sell referrer fee.
   * @dev Set to 2.5% of the sale.
   */
  uint16 private constant SELL_REFERRER_FEE_IN_BASIS_POINTS = 2500;

  /**
   * @notice Config used to create a BatchMintAndRevealCollection.
   */
  struct BatchMintAndRevealCollectionConfig {
    address additionalMinter;
    uint256 nonce;
    address payable paymentAddress;
    string name;
    string symbol;
    string baseURI;
    bytes32 baseURIHash;
    uint32 maxTokenId;
  }

  /**
   * @notice Emitted when a new BatchMintAndReveal collection is created from this factory.
   * @param batchMintAndRevealContract The address of the new BatchMintAndReveal contract.
   * @param creator The address of the creator which owns the new collection.
   * @param additionalMinter An additional address to grant MINTER_ROLE.
   * @param nonce The nonce used by the creator when creating the collection,
   * used to define the address of the collection.
   * @param paymentAddress The address to send the proceeds of the drop.
   * @param version The implementation version used by the new BatchMintAndReveal collection.
   * @param name The name of the collection contract created.
   * @param symbol The symbol of the collection contract created.
   * @param baseURI The full path to the pre-reveal image of the collection
   * or the base uri for revealed collection by default.
   * @param baseURIHash The hash of the revealed baseURI for the collection.
   * @param maxTokenId The max token id for this collection.
   */
  event BatchMintAndRevealCollectionCreated(
    address indexed batchMintAndRevealContract,
    address indexed creator,
    address indexed additionalMinter,
    uint256 nonce,
    address paymentAddress,
    uint256 version,
    string name,
    string symbol,
    string baseURI,
    bytes32 baseURIHash,
    uint256 maxTokenId
  );
  /**
   * @notice Emitted when a new CollectionContract is created from this factory.
   * @param collectionContract The address of the new NFT collection contract.
   * @param creator The address of the creator which owns the new collection.
   * @param version The implementation version used by the new collection.
   * @param name The name of the collection contract created.
   * @param symbol The symbol of the collection contract created.
   * @param nonce The nonce used by the creator when creating the collection,
   * used to define the address of the collection.
   */
  event CollectionCreated(
    address indexed collectionContract,
    address indexed creator,
    uint256 indexed version,
    string name,
    string symbol,
    uint256 nonce
  );
  /**
   * @notice Emitted when the implementation contract used by new collections is updated.
   * @param implementationBatchMintAndReveal The new implementation contract address.
   * @param version The version of the new implementation, auto-incremented.
   */
  event ImplementationBatchMintAndRevealUpdated(
    address indexed implementationBatchMintAndReveal,
    uint256 indexed version
  );
  /**
   * @notice Emitted when the implementation CollectionContract used by new collections is updated.
   * @param implementation The new implementation contract address.
   * @param version The version of the new implementation, auto-incremented.
   */
  event ImplementationCollectionUpdated(address indexed implementation, uint256 indexed version);

  modifier onlyAdmin() {
    require(rolesContract.isAdmin(msg.sender), "FNDCollectionDropFactory: Caller does not have the Admin role");
    _;
  }

  /**
   * @notice Defines requirements for the collection drop factory at deployment time.
   * @param _rolesContract The address of the contract defining roles for collections to use.
   */
  constructor(address _rolesContract) {
    require(_rolesContract.isContract(), "FNDCollectionDropFactory: RolesContract is not a contract");

    rolesContract = IRoles(_rolesContract);
  }

  /**
   * @notice Allows Foundation to change the collection implementation used for future collections.
   * This call will auto-increment the version.
   * Existing collections are not impacted.
   * @param _implementation The new BatchMintAndReveal collection implementation address.
   */
  function adminUpdateBatchMintAndRevealImplementation(address _implementation) external onlyAdmin {
    _updateBatchMintAndRevealImplementation(_implementation);
  }

  /**
   * @notice Allows Foundation to change the collection implementation used for future collections.
   * This call will auto-increment the version.
   * Existing collections are not impacted.
   * @param _implementation The new collection implementation address.
   */
  function adminUpdateCollectionImplementation(address _implementation) external onlyAdmin {
    _updateCollectionImplementation(_implementation);
  }

  /**
   * @notice Create a new collection contract.
   * @dev The nonce is required and must be unique for the msg.sender + implementation version,
   * otherwise this call will revert.
   * @param name The name for the new collection being created.
   * @param symbol The symbol for the new collection being created.
   * @param baseURIHash The hash of the revealed baseURI for the collection,
   * leave empty for collection revealed by default.
   * @param tokenURIPreReveal The full path to the pre-reveal image of the collection
   * or the base uri for revealed collection by default.
   * @param maxTokenId The max token id for this collection.
   * @param nonce An arbitrary value used to allow a creator to mint multiple collections.
   * @return batchMintAndRevealCollectionAddress The address of the new BatchMintAndReveal collection contract.
   */
  function createBatchMintAndRevealCollection(
    string memory name,
    string memory symbol,
    bytes32 baseURIHash,
    string memory tokenURIPreReveal,
    uint32 maxTokenId,
    address additionalMinterAddress,
    uint256 nonce
  ) external returns (address batchMintAndRevealCollectionAddress) {
    return
      _createBatchMintAndRevealCollection(
        BatchMintAndRevealCollectionConfig(
          additionalMinterAddress,
          nonce,
          payable(msg.sender),
          name,
          symbol,
          tokenURIPreReveal,
          baseURIHash,
          maxTokenId
        )
      );
  }

  /**
   * @notice Create a new collection contract with a custom payment address.
   * @param paymentAddress The address that will receive royalties and mint payments.
   * Notes:
   *   a) For rest of `params` see `createBatchMintAndRevealCollection` above.
   */
  function createBatchMintAndRevealCollectionWithPaymentAddress(
    string memory name,
    string memory symbol,
    address payable paymentAddress,
    bytes32 baseURIHash,
    string memory tokenURIPreReveal,
    uint32 maxTokenId,
    address additionalMinterAddress,
    uint256 nonce
  ) external returns (address batchMintAndRevealCollectionAddress) {
    return
      _createBatchMintAndRevealCollection(
        BatchMintAndRevealCollectionConfig(
          additionalMinterAddress,
          nonce,
          paymentAddress,
          name,
          symbol,
          tokenURIPreReveal,
          baseURIHash,
          maxTokenId
        )
      );
  }

  /**
   * @notice Create a new collection contract with a custom payment address derived from the factory.
   * @param paymentAddressFactory The contract to call which will return the address to use for payments.
   * @param paymentAddressCallData The call details to sent to the factory provided.
   * Notes:
   *   a) For rest of `params` see `createBatchMintAndRevealCollection` above.
   */
  function createBatchMintAndRevealCollectionWithPaymentFactory(
    string memory name,
    string memory symbol,
    bytes32 baseURIHash,
    string memory tokenURIPreReveal,
    uint32 maxTokenId,
    address additionalMinterAddress,
    uint256 nonce,
    address paymentAddressFactory,
    bytes calldata paymentAddressCallData
  ) external returns (address batchMintAndRevealCollectionAddress) {
    return
      _createBatchMintAndRevealCollection(
        BatchMintAndRevealCollectionConfig(
          additionalMinterAddress,
          nonce,
          paymentAddressFactory.callAndReturnContractAddress(paymentAddressCallData),
          name,
          symbol,
          tokenURIPreReveal,
          baseURIHash,
          maxTokenId
        )
      );
  }

  /**
   * @notice Create a new collection contract.
   * @dev The nonce is required and must be unique for the msg.sender + implementation version,
   * otherwise this call will revert.
   * @param name The name for the new collection being created.
   * @param symbol The symbol for the new collection being created.
   * @param nonce An arbitrary value used to allow a creator to mint multiple collections.
   * @return collectionAddress The address of the new collection contract.
   */
  function createCollection(
    string calldata name,
    string calldata symbol,
    uint256 nonce
  ) external returns (address collectionAddress) {
    require(bytes(symbol).length != 0, "FNDCollectionDropFactory: Symbol is required");

    // This reverts if the NFT was previously created using this implementation version + msg.sender + nonce
    collectionAddress = implementationCollection.cloneDeterministic(_getSalt(msg.sender, nonce));

    ICollectionContractInitializer(collectionAddress).initialize(payable(msg.sender), name, symbol);

    emit CollectionCreated(collectionAddress, msg.sender, versionCollection, name, symbol, nonce);
  }

  function _createBatchMintAndRevealCollection(BatchMintAndRevealCollectionConfig memory collectionConfig)
    internal
    returns (address batchMintAndRevealCollectionAddress)
  {
    // This reverts if the NFT was previously created using this implementation version + msg.sender + nonce
    batchMintAndRevealCollectionAddress = implementationBatchMintAndReveal.cloneDeterministic(
      _getSalt(msg.sender, collectionConfig.nonce)
    );

    IBatchMintAndRevealCollection(batchMintAndRevealCollectionAddress).initialize(
      msg.sender,
      collectionConfig.paymentAddress,
      collectionConfig.additionalMinter,
      collectionConfig.name,
      collectionConfig.symbol,
      collectionConfig.baseURIHash,
      collectionConfig.baseURI,
      collectionConfig.maxTokenId
    );

    emit BatchMintAndRevealCollectionCreated(
      batchMintAndRevealCollectionAddress,
      msg.sender,
      collectionConfig.additionalMinter,
      collectionConfig.nonce,
      collectionConfig.paymentAddress,
      versionBatchMintAndReveal,
      collectionConfig.name,
      collectionConfig.symbol,
      collectionConfig.baseURI,
      collectionConfig.baseURIHash,
      collectionConfig.maxTokenId
    );
  }

  /**
   * @dev Updates the implementation address, increments the version, and initializes the template.
   * Since the template is initialized when set, implementations cannot be re-used.
   * To downgrade the implementation, deploy the same bytecode again and then update to that.
   */
  function _updateBatchMintAndRevealImplementation(address _implementation) private {
    require(_implementation.isContract(), "FNDCollectionDropFactory: Implementation is not a contract");
    require(
      _implementation.supportsERC165Interface(type(IBatchMintAndRevealCollection).interfaceId) == true,
      "FNDCollectionDropFactory: Unsupported interface"
    );
    implementationBatchMintAndReveal = _implementation;
    unchecked {
      // Version cannot overflow 256 bits.
      versionBatchMintAndReveal++;
    }

    emit ImplementationBatchMintAndRevealUpdated(_implementation, versionBatchMintAndReveal);

    // The implementation is initialized when assigned so that others may not claim it as their own.
    IBatchMintAndRevealCollection(_implementation).initialize(
      payable(address(this)),
      payable(address(rolesContract)),
      address(0),
      "",
      string.concat("FCTv", versionBatchMintAndReveal.toString()),
      "",
      string.concat("ipfs://foundation.os.token.uri.preveal.content/v-", versionBatchMintAndReveal.toString()),
      1
    );
  }

  /**
   * @dev Updates the implementation address, increments the version,
   * and initializes the CollectionContract template.
   * Since the template is initialized when set, implementations cannot be re-used.
   * To downgrade the implementation, deploy the same bytecode again and then update to that.
   */
  function _updateCollectionImplementation(address _implementation) private {
    require(_implementation.isContract(), "FNDCollectionDropFactory: Implementation is not a contract");
    implementationCollection = _implementation;
    unchecked {
      // Version cannot overflow 256 bits.
      versionCollection++;
    }

    // The implementation is initialized when assigned so that others may not claim it as their own.
    ICollectionContractInitializer(_implementation).initialize(
      payable(address(rolesContract)),
      string.concat("Foundation Collection Template v", versionCollection.toString()),
      string.concat("FCTv", versionCollection.toString())
    );

    emit ImplementationCollectionUpdated(_implementation, versionCollection);
  }

  /**
   * @notice Returns the address of a BatchMintAndReveal collection given the current
   * implementation version, creator, and nonce.
   * This will return the same address whether the collection has already been created or not.
   * @param creator The creator of the collection.
   * @param nonce An arbitrary value used to allow a creator to mint multiple collections.
   * @return batchMintAndRevealCollectionAddress The address of the BatchMintAndReveal contract
   * that would be created by this nonce.
   */
  function predictBatchMintAndRevealCollectionAddress(address creator, uint256 nonce)
    external
    view
    returns (address batchMintAndRevealCollectionAddress)
  {
    batchMintAndRevealCollectionAddress = implementationBatchMintAndReveal.predictDeterministicAddress(
      _getSalt(creator, nonce)
    );
  }

  /**
   * @notice Returns the address of a collection given the current implementation version, creator, and nonce.
   * This will return the same address whether the collection has already been created or not.
   * @param creator The creator of the collection.
   * @param nonce An arbitrary value used to allow a creator to mint multiple collections.
   * @return collectionAddress The address of the collection contract that would be created by this nonce.
   */
  function predictCollectionAddress(address creator, uint256 nonce) external view returns (address collectionAddress) {
    collectionAddress = implementationCollection.predictDeterministicAddress(_getSalt(creator, nonce));
  }

  function _getSalt(address creator, uint256 nonce) private pure returns (bytes32) {
    return keccak256(abi.encodePacked(creator, nonce));
  }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
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

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

/**
 * @title A library for address helpers not already covered by the OZ library library.
 */
library AddressLibrary {
  using AddressUpgradeable for address;
  using AddressUpgradeable for address payable;

  /**
   * @notice Calls an external contract with arbitrary data and parse the return value into an address.
   * @param externalContract The address of the contract to call.
   * @param callData The data to send to the contract.
   * @return contractAddress The address of the contract returned by the call.
   */
  function callAndReturnContractAddress(address externalContract, bytes memory callData)
    internal
    returns (address payable contractAddress)
  {
    bytes memory returnData = externalContract.functionCall(callData);
    contractAddress = abi.decode(returnData, (address));
    require(contractAddress.isContract(), "InternalProxyCall: did not return a contract");
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * From https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.2.0/contracts/utils/introspection/ERC165.sol
 * Modified to allow checking multiple interfaces w/o checking general 165 support.
 */

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @title Library to query ERC165 support.
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library OZERC165Checker {
  // As per the EIP-165 spec, no interface should ever match 0xffffffff
  bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

  /**
   * @dev Returns true if `account` supports the {IERC165} interface,
   */
  function supportsERC165(address account) internal view returns (bool) {
    // Any contract that implements ERC165 must explicitly indicate support of
    // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
    return
      supportsERC165Interface(account, type(IERC165).interfaceId) &&
      !supportsERC165Interface(account, _INTERFACE_ID_INVALID);
  }

  /**
   * @dev Returns true if `account` supports the interface defined by
   * `interfaceId`. Support for {IERC165} itself is queried automatically.
   *
   * See {IERC165-supportsInterface}.
   */
  function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
    // query support of both ERC165 as per the spec and support of _interfaceId
    return supportsERC165(account) && supportsERC165Interface(account, interfaceId);
  }

  /**
   * @dev Returns a boolean array where each value corresponds to the
   * interfaces passed in and whether they're supported or not. This allows
   * you to batch check interfaces for a contract where your expectation
   * is that some interfaces may not be supported.
   *
   * See {IERC165-supportsInterface}.
   *
   * _Available since v3.4._
   */
  function getSupportedInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool[] memory) {
    // an array of booleans corresponding to interfaceIds and whether they're supported or not
    bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

    // query support of ERC165 itself
    if (supportsERC165(account)) {
      // query support of each interface in interfaceIds
      unchecked {
        for (uint256 i = 0; i < interfaceIds.length; ++i) {
          interfaceIdsSupported[i] = supportsERC165Interface(account, interfaceIds[i]);
        }
      }
    }

    return interfaceIdsSupported;
  }

  /**
   * @dev Returns true if `account` supports all the interfaces defined in
   * `interfaceIds`. Support for {IERC165} itself is queried automatically.
   *
   * Batch-querying can lead to gas savings by skipping repeated checks for
   * {IERC165} support.
   *
   * See {IERC165-supportsInterface}.
   */
  function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
    // query support of ERC165 itself
    if (!supportsERC165(account)) {
      return false;
    }

    // query support of each interface in _interfaceIds
    unchecked {
      for (uint256 i = 0; i < interfaceIds.length; ++i) {
        if (!supportsERC165Interface(account, interfaceIds[i])) {
          return false;
        }
      }
    }

    // all interfaces supported
    return true;
  }

  /**
   * @notice Query if a contract implements an interface, does not check ERC165 support
   * @param account The address of the contract to query for support of an interface
   * @param interfaceId The interface identifier, as specified in ERC-165
   * @return true if the contract at account indicates support of the interface with
   * identifier interfaceId, false otherwise
   * @dev Assumes that account contains a contract that supports ERC165, otherwise
   * the behavior of this method is undefined. This precondition can be checked
   * with {supportsERC165}.
   * Interface identification is specified in ERC-165.
   */
  function supportsERC165Interface(address account, bytes4 interfaceId) internal view returns (bool) {
    bytes memory encodedParams = abi.encodeWithSelector(IERC165(account).supportsInterface.selector, interfaceId);
    (bool success, bytes memory result) = account.staticcall{ gas: 30000 }(encodedParams);
    if (result.length < 32) return false;
    return success && abi.decode(result, (bool));
  }
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

import "./ICollectionMint.sol";

interface IBatchMintAndRevealCollection is ICollectionMint {
  function initialize(
    address _creator,
    address payable _paymentAddress,
    address _additionalMinterAddress,
    string memory _name,
    string memory _symbol,
    bytes32 _baseURIHash,
    string memory _tokenURIPreReveal,
    uint32 maxTokenId
  ) external;
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

interface ICollectionContractInitializer {
  function initialize(
    address payable _creator,
    string memory _name,
    string memory _symbol
  ) external;
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

import "./IRoles.sol";
import "./IProxyCall.sol";

interface ICollectionFactory {
  function rolesContract() external returns (IRoles);
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

/**
 * @notice Interface for a contract which implements admin roles.
 */
interface IRoles {
  function isAdmin(address account) external view returns (bool);

  function isOperator(address account) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

interface ICollectionMint {
  function mintCountFor(
    uint256 count,
    address to,
    address marketToApprove
  ) external returns (uint256 firstTokenId);

  function isSoldOut() external view returns (bool soldOut);
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

interface IProxyCall {
  function proxyCallAndReturnAddress(address externalContract, bytes memory callData)
    external
    returns (address payable result);
}