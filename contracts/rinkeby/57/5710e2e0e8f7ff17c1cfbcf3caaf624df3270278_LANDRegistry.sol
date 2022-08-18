/**
 *Submitted for verification at Etherscan.io on 2022-08-18
*/

// File: @openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol


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

// File: @openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;


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

// File: @openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol


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

// File: @openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;



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

// File: lands.sol

//SPDX-License-Identifier:MIT
pragma solidity 0.8.13;


contract AssetRegistryStorage {

  string internal _name;
  string internal _symbol;
  string internal _description;


   // Stores the total count of assets managed by this registry
   
  uint256 internal _count;


   // Stores an array of assets owned by a given account
   
  mapping(address => uint256[]) internal _assetsOf;

  
   // Stores the current holder of an asset

  mapping(uint256 => address) internal _holderOf;

  
   // Stores the index of an asset in the `_assetsOf` array of its holder
   
  mapping(uint256 => uint256) internal _indexOfAsset;


   // Stores the data associated with an asset
   
  mapping(uint256 => string) internal _assetData;

  /*
    For a given account, for a given operator, store whether that operator is
    allowed to transfer and modify assets on behalf of them.*/
   
  mapping(address => mapping(address => bool)) internal _operators;

  
   //Approval array
   
  mapping(uint256 => address) internal _approval;
}

interface IEstateRegistry {
  function mint(address to, string memory  metadata) external returns (uint256);
  function ownerOf(uint256 _tokenId) external view returns (address _owner); // from ERC721

  // Events

  event CreateEstate(
    address indexed _owner,
    uint256 indexed _estateId,
    string _data
  );

  event AddLand(
    uint256 indexed _estateId,
    uint256 indexed _landId
  );

  event RemoveLand(
    uint256 indexed _estateId,
    uint256 indexed _landId,
    address indexed _destinatary
  );

  event Update(
    uint256 indexed _assetId,
    address indexed _holder,
    address indexed _operator,
    string _data
  );

  event UpdateOperator(
    uint256 indexed _estateId,
    address indexed _operator
  );

  event UpdateManager(
    address indexed _owner,
    address indexed _operator,
    address indexed _caller,
    bool _approved
  );

  event SetLANDRegistry(
    address indexed _registry
  );

  event SetEstateLandBalanceToken(
    address indexed _previousEstateLandBalance,
    address indexed _newEstateLandBalance
  );
}


interface IMiniMeToken {
////////////////
// Generate and destroy tokens
////////////////

    /// @notice Generates `_amount` tokens that are assigned to `_owner`
    /// @param _owner The address that will be assigned the new tokens
    /// @param _amount The quantity of tokens generated
    /// @return True if the tokens are generated correctly
    function generateTokens(address _owner, uint _amount) external returns (bool);


    /// @notice Burns `_amount` tokens from `_owner`
    /// @param _owner The address that will lose the tokens
    /// @param _amount The quantity of tokens to burn
    /// @return True if the tokens are burned correctly
    function destroyTokens(address _owner, uint _amount) external returns (bool);

    function balanceOf(address _owner) external view returns (uint256 balance);

    event Transfer(address indexed _from, address indexed _to, uint256 _amount);
}

contract LANDStorage {
  mapping (address => uint) public latestPing;

  uint256 constant clearLow = 0xffffffffffffffffffffffffffffffff00000000000000000000000000000000;
  uint256 constant clearHigh = 0x00000000000000000000000000000000ffffffffffffffffffffffffffffffff;
  uint256 constant factor = 0x100000000000000000000000000000000;

  mapping (address => bool) internal _deprecated_authorizedDeploy;

  mapping (uint256 => address) public updateOperator;

  IEstateRegistry public estateRegistry;

  mapping (address => bool) public authorizedDeploy;

  mapping(address => mapping(address => bool)) public updateManager;

  // Land balance minime token
  IMiniMeToken public landBalance;

  // Registered balance accounts
  mapping(address => bool) public registeredBalance;
}

// File: contracts/Storage.sol
contract Storage is  OwnableUpgradeable, AssetRegistryStorage, LANDStorage {
}

interface IERC721Base {
  function totalSupply() external view returns (uint256);

  // function exists(uint256 assetId) external view returns (bool);
  function ownerOf(uint256 assetId) external view returns (address);

  function balanceOf(address holder) external view returns (uint256);
//   function tokenURI(uint256) external view returns(string);

  function safeTransferFrom(address from, address to, uint256 assetId) external;
  function safeTransferFrom(address from, address to, uint256 assetId, bytes memory userData) external;

  function transferFrom(address from, address to, uint256 assetId) external;

  function approve(address operator, uint256 assetId) external;
  function setApprovalForAll(address operator, bool authorized) external;

  function getApprovedAddress(uint256 assetId) external view returns (address);
  function isApprovedForAll(address assetHolder, address operator) external view returns (bool);

  function isAuthorized(address operator, uint256 assetId) external view returns (bool);

  /**
  * @dev Deprecated transfer event. Now we use the standard with three parameters
  * It is only used in the ABI to get old transfer events. Do not remove
  */
  event Transfer(
    address indexed from,
    address indexed to,
    uint256 indexed assetId,
    address operator,
    bytes userData,
    bytes operatorData
  );
  /**
   * @dev Deprecated transfer event. Now we use the standard with three parameters
   * It is only used in the ABI to get old transfer events. Do not remove
   */
  event Transfer(
    address indexed from,
    address indexed to,
    uint256 indexed assetId,
    address operator,
    bytes userData
  );
  event Transfer(
    address indexed from,
    address indexed to,
    uint256 indexed assetId
  );
  event ApprovalForAll(
    address indexed holder,
    address indexed operator,
    bool authorized
  );
  event Approval(
    address indexed owner,
    address indexed operator,
    uint256 indexed assetId
  );
}

interface IERC721ReceiverUpgradeable {
  function onERC721Received(
    address _operator,
    address _from,
    uint256 _tokenId,
    bytes memory    _userData
  ) external returns (bytes4);
}
interface ERC165Upgradeable  {
  function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

contract ERC721Base is AssetRegistryStorage, IERC721Base, ERC165Upgradeable {


  // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
  bytes4 private constant ERC721_RECEIVED = 0x150b7a02;

  bytes4 private constant InterfaceId_ERC165 = 0x01ffc9a7;
  /*
   * 0x01ffc9a7 ===
   *   bytes4(keccak256('supportsInterface(bytes4)'))
   */

  bytes4 private constant Old_InterfaceId_ERC721 = 0x7c0633c6;
  bytes4 private constant InterfaceId_ERC721 = 0x80ac58cd;
   /*
   * 0x80ac58cd ===
   *   bytes4(keccak256('balanceOf(address)')) ^
   *   bytes4(keccak256('ownerOf(uint256)')) ^
   *   bytes4(keccak256('approve(address,uint256)')) ^
   *   bytes4(keccak256('getApproved(uint256)')) ^
   *   bytes4(keccak256('setApprovalForAll(address,bool)')) ^
   *   bytes4(keccak256('isApprovedForAll(address,address)')) ^
   *   bytes4(keccak256('transferFrom(address,address,uint256)')) ^
   *   bytes4(keccak256('safeTransferFrom(address,address,uint256)')) ^
   *   bytes4(keccak256('safeTransferFrom(address,address,uint256,bytes)'))
   */

  //
  // Global Getters
  //

  /**
   * @dev Gets the total amount of assets stored by the contract
   * @return uint256 representing the total amount of assets
   */
  function totalSupply() external view returns (uint256) {
    return _totalSupply();
  }
  function _totalSupply() internal view returns (uint256) {
    return _count;
  }

  //
  // Asset-centric getter functions
  //

  /**
   * @dev Queries what address owns an asset. This method does not throw.
   * In order to check if the asset exists, use the `exists` function or check if the
   * return value of this call is `0`.
   * @return uint256 the assetId
   */
  function ownerOf(uint256 assetId) external view returns (address) {
    return _ownerOf(assetId);
  }
  function _ownerOf(uint256 assetId) internal view returns (address) {
    return _holderOf[assetId];
  }

  //
  // Holder-centric getter functions
  //
  /**
   * @dev Gets the balance of the specified address
   * @param owner address to query the balance of
   * @return uint256 representing the amount owned by the passed address
   */
  function balanceOf(address owner) external view returns (uint256) {
    return _balanceOf(owner);
  }
  function _balanceOf(address owner) internal view returns (uint256) {
    return _assetsOf[owner].length;
  }

  //
  // Authorization getters
  //

  /**
   * @dev Query whether an address has been authorized to move any assets on behalf of someone else
   * @param operator the address that might be authorized
   * @param assetHolder the address that provided the authorization
   * @return bool true if the operator has been authorized to move any assets
   */
  function isApprovedForAll(address assetHolder, address operator)
    external view returns (bool)
  {
    return _isApprovedForAll(assetHolder, operator);
  }
  function _isApprovedForAll(address assetHolder, address operator)
    internal view returns (bool)
  {
    return _operators[assetHolder][operator];
  }

  /**
   * @dev Query what address has been particularly authorized to move an asset
   * @param assetId the asset to be queried for
   * @return bool true if the asset has been approved by the holder
   */
  function getApproved(uint256 assetId) external view returns (address) {
    return _getApprovedAddress(assetId);
  }
  function getApprovedAddress(uint256 assetId) external view returns (address) {
    return _getApprovedAddress(assetId);
  }
  function _getApprovedAddress(uint256 assetId) internal view returns (address) {
    return _approval[assetId];
  }

  /**
   * @dev Query if an operator can move an asset.
   * @param operator the address that might be authorized
   * @param assetId the asset that has been `approved` for transfer
   * @return bool true if the asset has been approved by the holder
   */
  function isAuthorized(address operator, uint256 assetId) external view returns (bool) {
    return _isAuthorized(operator, assetId);
  }
  function _isAuthorized(address operator, uint256 assetId) internal view returns (bool)
  {
    require(operator != address(0));
    address owner = _ownerOf(assetId);
    if (operator == owner) {
      return true;
    }
    return _isApprovedForAll(owner, operator) || _getApprovedAddress(assetId) == operator;
  }

  //
  // Authorization
  //

  /**
   * @dev Authorize a third party operator to manage (send) msg.sender's asset
   * @param operator address to be approved
   * @param authorized bool set to true to authorize, false to withdraw authorization
   */
  function setApprovalForAll(address operator, bool authorized) external {
    return _setApprovalForAll(operator, authorized);
  }
  function _setApprovalForAll(address operator, bool authorized) internal {
    if (authorized) {
      require(!_isApprovedForAll(msg.sender, operator));
      _addAuthorization(operator, msg.sender);
    } else {
      require(_isApprovedForAll(msg.sender, operator));
      _clearAuthorization(operator, msg.sender);
    }
    emit ApprovalForAll(msg.sender, operator, authorized);
  }

  /**
   * @dev Authorize a third party operator to manage one particular asset
   * @param operator address to be approved
   * @param assetId asset to approve
   */
  function approve(address operator, uint256 assetId) external {
    address holder = _ownerOf(assetId);
    require(msg.sender == holder || _isApprovedForAll(holder, msg.sender));
    require(operator != holder);

    if (_getApprovedAddress(assetId) != operator) {
      _approval[assetId] = operator;
      emit Approval(holder, operator, assetId);
    }
  }

  function _addAuthorization(address operator, address holder) private {
    _operators[holder][operator] = true;
  }

  function _clearAuthorization(address operator, address holder) private {
    _operators[holder][operator] = false;
  }

  //
  // Internal Operations
  //

  function _addAssetTo(address to, uint256 assetId) internal {

    _holderOf[assetId] = to;

    uint256 length = _balanceOf(to);

    _assetsOf[to].push(assetId);

    _indexOfAsset[assetId] = length;

    _count = _count +1;
  }

  function _removeAssetFrom(address from, uint256 assetId) internal {
    uint256 assetIndex = _indexOfAsset[assetId];
    uint256 lastAssetIndex = _balanceOf(from)-1;
    uint256 lastAssetId = _assetsOf[from][lastAssetIndex];

    _holderOf[assetId] = address(0);

    // Insert the last asset into the position previously occupied by the asset to be removed
    _assetsOf[from][assetIndex] = lastAssetId;

    // Resize the array
    _assetsOf[from][lastAssetIndex] = 0;
    _assetsOf[from].length-1;

    // Remove the array if no more assets are owned to prevent pollution
    if (_assetsOf[from].length == 0) {
      delete _assetsOf[from];
    }

    // Update the index of positions for the asset
    _indexOfAsset[assetId] = 0;
    _indexOfAsset[lastAssetId] = assetIndex;

    _count = _count-1;
  }

  function _clearApproval(address holder, uint256 assetId) internal {
    if (_ownerOf(assetId) == holder && _approval[assetId] != address(0)) {
      _approval[assetId] = address(0);
      emit Approval(holder, address(0), assetId);
    }
  }

  //
  // Supply-altering functions
  //

  function _generate(uint256 assetId, address beneficiary) internal {

    require(_holderOf[assetId] == address(0));

    _addAssetTo(beneficiary, assetId);

    emit Transfer(address(0), beneficiary, assetId);
  }

  function _destroy(uint256 assetId) internal {
    address holder = _holderOf[assetId];
    require(holder != address(0));

    _removeAssetFrom(holder, assetId);

    emit Transfer(holder, address(0), assetId);
  }

  //
  // Transaction related operations
  //

  modifier onlyHolder(uint256 assetId) {
    require(_ownerOf(assetId) == msg.sender);
    _;
  }

  modifier onlyAuthorized(uint256 assetId) {
    require(_isAuthorized(msg.sender, assetId));
    _;
  }

  modifier isCurrentOwner(address from, uint256 assetId) {
    require(_ownerOf(assetId) == from);
    _;
  }

  modifier isDestinataryDefined(address destinatary) {
    require(destinatary != address(0));
    _;
  }

  modifier destinataryIsNotHolder(uint256 assetId, address to) {
    require(_ownerOf(assetId) != to);
    _;
  }

  /**
   * @dev Alias of `safeTransferFrom(from, to, assetId, '')`
   *
   * @param from address that currently owns an asset
   * @param to address to receive the ownership of the asset
   * @param assetId uint256 ID of the asset to be transferred
   */
  function safeTransferFrom(address from, address to, uint256 assetId) external {
    return _doTransferFrom(from, to, assetId, '', true);
  }

  /**
   * @dev Securely transfers the ownership of a given asset from one address to
   * another address, calling the method `onNFTReceived` on the target address if
   * there's code associated with it
   *
   * @param from address that currently owns an asset
   * @param to address to receive the ownership of the asset
   * @param assetId uint256 ID of the asset to be transferred
   * @param userData bytes arbitrary user information to attach to this transfer
   */
  function safeTransferFrom(address from, address to, uint256 assetId, bytes memory  userData) external {
    return _doTransferFrom(from, to, assetId, userData, true);
  }

  /**
   * @dev Transfers the ownership of a given asset from one address to another address
   * Warning! This function does not attempt to verify that the target address can send
   * tokens.
   *
   * @param from address sending the asset
   * @param to address to receive the ownership of the asset
   * @param assetId uint256 ID of the asset to be transferred
   */
  function transferFrom(address from, address to, uint256 assetId) external  virtual {
    return _doTransferFrom(from, to, assetId, '', false);
  }

  function _doTransferFrom(
    address from,
    address to,
    uint256 assetId,
    bytes memory userData,
    bool doCheck
  )
    onlyAuthorized(assetId)
    internal virtual 
  {
    _moveToken(from, to, assetId, userData, doCheck);
  }

  function _moveToken(
    address from,
    address to,
    uint256 assetId,
    bytes memory userData,
    bool doCheck
  )
    isDestinataryDefined(to)
    destinataryIsNotHolder(assetId, to)
    isCurrentOwner(from, assetId)
    private
  {
    address holder = _holderOf[assetId];
    _clearApproval(holder, assetId);
    _removeAssetFrom(holder, assetId);
    _addAssetTo(to, assetId);
    emit Transfer(holder, to, assetId);

    if (doCheck && _isContract(to)) {
      // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))
      require(
        IERC721ReceiverUpgradeable(to).onERC721Received(
          msg.sender, holder, assetId, userData
        ) == ERC721_RECEIVED
      );
    }
  }

  /**
   * Internal function that moves an asset from one holder to another
   */

  /**
   * @dev Returns `true` if the contract implements `interfaceID` and `interfaceID` is not 0xffffffff, `false` otherwise
   * @param  _interfaceID The interface identifier, as specified in ERC-165
   */
  function supportsInterface(bytes4 _interfaceID) external pure returns (bool) {

    if (_interfaceID == 0xffffffff) {
      return false;
    }
    return _interfaceID == InterfaceId_ERC165 || _interfaceID == Old_InterfaceId_ERC721 || _interfaceID == InterfaceId_ERC721;
  }

  //
  // Utilities
  //

  function _isContract(address addr) internal virtual view returns (bool) {
    uint size;
    assembly { size := extcodesize(addr) }
    return size > 0;
  }
}

interface IERC721EnumerableUpgradeable {

  /**
   * @notice Enumerate active tokens
   * @dev Throws if `index` >= `totalSupply()`, otherwise SHALL NOT throw.
   * @param index A counter less than `totalSupply()`
   * @return The identifier for the `index`th asset, (sort order not
   *  specified)
   */
  // TODO (eordano): Not implemented
  // function tokenByIndex(uint256 index) public view returns (uint256 _assetId);

  /**
   * @notice Count of owners which own at least one asset
   *  Must not throw.
   * @return A count of the number of owners which own asset
   */
  // TODO (eordano): Not implemented
  // function countOfOwners() public view returns (uint256 _count);

  /**
   * @notice Enumerate owners
   * @dev Throws if `index` >= `countOfOwners()`, otherwise must not throw.
   * @param index A counter less than `countOfOwners()`
   * @return The address of the `index`th owner (sort order not specified)
   */
  // TODO (eordano): Not implemented
  // function ownerByIndex(uint256 index) public view returns (address owner);

  /**
   * @notice Get all tokens of a given address
   * @dev This is not intended to be used on-chain
   * @param owner address of the owner to query
   * @return a list of all assetIds of a user
   */
  function tokensOf(address owner) external view returns (uint256[] memory );

 
  function tokenOfOwnerByIndex(
    address owner, uint256 index
  ) external view returns (uint256 tokenId);
}
contract ERC721EnumerableUpgradeable is AssetRegistryStorage, IERC721EnumerableUpgradeable {

  /**
   * @notice Get all tokens of a given address
   * @dev This is not intended to be used on-chain
   * @param owner address of the owner to query
   * @return a list of all assetIds of a user
   */
  function tokensOf(address owner) external view returns (uint256[] memory ) {
    return _assetsOf[owner];
  }

 
  function tokenOfOwnerByIndex(
    address owner, uint256 index
  )
    external
    view
    returns (uint256 assetId)
  {
    require(index < _assetsOf[owner].length);
    require(index < (1<<127));
    return _assetsOf[owner][index];
  }

}

interface  IERC721MetadataUpgradeable {

  /**
   * @notice A descriptive name for a collection of NFTs in this contract
   */
  function name() external view returns (string memory );

  /**
   * @notice An abbreviated name for NFTs in this contract
   */
  function symbol() external view returns (string memory );

  /**
   * @notice A description of what this DAR is used for
   */
  function description() external view returns (string memory );

  /**
   * Stores arbitrary info about a token
   */
  function tokenMetadata(uint256 assetId) external view returns (string memory);
}

contract ERC721MetadataUpgradeable is AssetRegistryStorage, IERC721MetadataUpgradeable {

  function name() external view returns (string memory) {
    return _name;
  }
  function symbol() external view returns (string memory ) {
    return _symbol;
  }
  function description() external view returns (string memory ) {
    return _description;
  }
  function tokenMetadata(uint256 assetId) external  virtual view returns (string memory) {
    return _assetData[assetId];
  }
  function _update(uint256 assetId, string memory  data) internal {
    _assetData[assetId] = data;
  }
}
contract FullAssetRegistry is ERC721Base, ERC721EnumerableUpgradeable, ERC721MetadataUpgradeable {
  /**
   * @dev Method to check if an asset identified by the given id exists under this DAR.
   * @return uint256 the assetId
   */
  function exists(uint256 assetId) external view returns (bool) {
    return _exists(assetId);
  }
  function _exists(uint256 assetId) internal view returns (bool) {
    return _holderOf[assetId] != address(0);
  }

  function decimals() external pure returns (uint256) {
    return 0;
  }
}


interface ILANDRegistry {

  // LAND can be assigned by the owner
//   function buyNewParcel(int x, int y, address beneficiary) external;
//   function buyMultipleParcels(int[] x, int[] y, address beneficiary) external;

  // After one year, LAND can be claimed from an inactive public key
  function ping() external;

  // LAND-centric getters
  function encodeTokenId(int x, int y) external pure returns (uint256);
  function decodeTokenId(uint value) external pure returns (int, int);
  function exists(int x, int y) external view returns (bool);
  function ownerOfLand(int x, int y) external view returns (address);
  function ownerOfLandMany(int[] memory  x, int[] memory  y) external view returns (address[] memory );
  function landOf(address owner) external view returns (int[] memory , int[] memory );
  function landData(int x, int y) external view returns (string memory );

  // Transfer LAND
  function transferLand(int x, int y, address to) external;
  function transferManyLand(int[] memory x, int[] memory  y, address to) external;

  // Update LAND
  function updateLandData(int x, int y, string memory  data) external;
  function updateManyLandData(int[] memory x, int[] memory y, string memory data) external;

  // Authorize an updateManager to manage parcel data
  function setUpdateManager(address _owner, address _operator, bool _approved) external;

  // Events

  event Update(
    uint256 indexed assetId,
    address indexed holder,
    address indexed operator,
    string data
  );

  event UpdateOperator(
    uint256 indexed assetId,
    address indexed operator
  );

  event UpdateManager(
    address indexed _owner,
    address indexed _operator,
    address indexed _caller,
    bool _approved
  );

  event DeployAuthorized(
    address indexed _caller,
    address indexed _deployer
  );

  event DeployForbidden(
    address indexed _caller,
    address indexed _deployer
  );

  event SetLandBalanceToken(
    address indexed _previousLandBalance,
    address indexed _newLandBalance
  );
}

interface IMetadataHolder is ERC165Upgradeable {
  function getMetadata(uint256 /* assetId */) external view returns (string memory);
}

contract LANDRegistry is Storage, FullAssetRegistry, ILANDRegistry {

    address public Operator;

  bytes4 constant public GET_METADATA = bytes4(keccak256("getMetadata(uint256)"));
  mapping(uint =>string) private __uris;
  address public proxyOwner;

  function initialize() external initializer{
    _name = "MetaBloqs Lands";
    _symbol = "BloqsLands";
    _description = "Contract that stores the  MetaBloqs Lands";
    proxyOwner=msg.sender; 
  }

  modifier onlyProxyOwner() {
    require(msg.sender == proxyOwner, "This function can only be called by the proxy owner");
    _;
  }

  modifier onlyDeployer() {
    require(
      msg.sender == proxyOwner || authorizedDeploy[msg.sender],
      "This function can only be called by an authorized deployer"
    );
    _;
  }

  modifier onlyOwnerOf(uint256 assetId) {
    require(
      msg.sender == _ownerOf(assetId),
      "This function can only be called by the owner of the asset"
    );
    _;
  }

  modifier onlyUpdateAuthorized(uint256 tokenId) {
    require(
      msg.sender == _ownerOf(tokenId) ||
      _isAuthorized(msg.sender, tokenId) ||
      _isUpdateAuthorized(msg.sender, tokenId),
      "msg.sender is not authorized to update"
    );
    _;
  }

  modifier canSetUpdateOperator(uint256 tokenId) {
    address owner = _ownerOf(tokenId);
    require(
      _isAuthorized(msg.sender, tokenId) || updateManager[owner][msg.sender],
      "unauthorized user"
    );
    _;
  }

  //
  // Authorization
  //

  function isUpdateAuthorized(address operator, uint256 assetId) external view returns (bool) {
    return _isUpdateAuthorized(operator, assetId);
  }

  function _isUpdateAuthorized(address operator, uint256 assetId) internal view returns (bool) {
    address owner = _ownerOf(assetId);

    return owner == operator  ||
      updateOperator[assetId] == operator ||
      updateManager[owner][operator];
  }

  function authorizeDeploy(address beneficiary) external onlyProxyOwner {
    require(beneficiary != address(0), "invalid address");
    require(authorizedDeploy[beneficiary] == false, "address is already authorized");

    authorizedDeploy[beneficiary] = true;
    emit DeployAuthorized(msg.sender, beneficiary);
  }

  function forbidDeploy(address beneficiary) external onlyProxyOwner {
    require(beneficiary != address(0), "invalid address");
    require(authorizedDeploy[beneficiary], "address is already forbidden");

    authorizedDeploy[beneficiary] = false;
    emit DeployForbidden(msg.sender, beneficiary);
  }

  //
  // LAND Create
  //

  function buyNewParcel(int x, int y, address beneficiary,string memory  uri) external returns(uint)  {
      require(Operator==msg.sender,"!No Permission");
    _generate(_encodeTokenId(x, y), beneficiary);
    __uris[_encodeTokenId(x, y)]=uri;
    _updateLandBalance(address(0), beneficiary);
    return _encodeTokenId(x,y);
 }

 
  function buyMultipleParcels(int[] memory x, int[] memory y, address beneficiary,string[] memory  uri) external {
      require(x.length==y.length,"Count Mismatch");
       require(Operator==msg.sender,"!No Permission");
    for (uint i = 0; i < x.length; i++){
      _generate(_encodeTokenId(x[i], y[i]), beneficiary);
       __uris[_encodeTokenId(x[i], y[i])]=uri[i];
      _updateLandBalance(address(0), beneficiary);
    }
  }
  

  //
  // Inactive keys after 1 year lose ownership
  //

  function ping() external {
    // solium-disable-next-line security/no-block-members
    latestPing[msg.sender] = block.timestamp;
  }

  function setLatestToNow(address user) external {
    require(msg.sender == proxyOwner || _isApprovedForAll(user, msg.sender), "Unauthorized user");
    // solium-disable-next-line security/no-block-members
    latestPing[user] = block.timestamp;
  }

  //
  // LAND Getters
  //

  function encodeTokenId(int x, int y) external pure returns (uint) {
    return _encodeTokenId(x, y);
  }

  function _encodeTokenId(int x, int y) internal pure returns (uint result) {
    require(
      -1000000 < x && x < 1000000 && -1000000 < y && y < 1000000,
      "The coordinates should be inside bounds"
    );
    return _unsafeEncodeTokenId(x, y);
  }

  function _unsafeEncodeTokenId(int x, int y) internal pure returns (uint) {
    return ((uint(x) * factor) & clearLow) | (uint(y) & clearHigh);
  }

  function decodeTokenId(uint value) external pure returns (int, int) {
    return _decodeTokenId(value);
  }

  function _unsafeDecodeTokenId(uint value) internal pure returns (int x, int y) {
    x = expandNegative128BitCast((value & clearLow) >> 128);
    y = expandNegative128BitCast(value & clearHigh);
  }

  function _decodeTokenId(uint value) internal pure returns (int x, int y) {
    (x, y) = _unsafeDecodeTokenId(value);
    require(
      -1000000 < x && x < 1000000 && -1000000 < y && y < 1000000,
      "The coordinates should be inside bounds"
    );
  }

  function expandNegative128BitCast(uint value) internal pure returns (int) {
    if (value & (1<<127) != 0) {
      return int(value | clearLow);
    }
    return int(value);
  }

  function exists(int x, int y) external view returns (bool) {
    return _exists(x, y);
  }

  function _exists(int x, int y) internal view returns (bool) {
    return _exists(_encodeTokenId(x, y));
  }

  function ownerOfLand(int x, int y) external view returns (address) {
    return _ownerOfLand(x, y);
  }

  function _ownerOfLand(int x, int y) internal view returns (address) {
    return _ownerOf(_encodeTokenId(x, y));
  }

  function ownerOfLandMany(int[] memory  x, int[] memory  y) external view returns (address[] memory) {
    require(x.length > 0, "You should supply at least one coordinate");
    require(x.length == y.length, "The coordinates should have the same length");

    address[] memory addrs = new address[](x.length);
    for (uint i = 0; i < x.length; i++) {
      addrs[i] = _ownerOfLand(x[i], y[i]);
    }

    return addrs;
  }

  function landOf(address owner) external view returns (int[] memory , int[] memory ) {
    uint256 len = _assetsOf[owner].length;
    int[] memory x = new int[](len);
    int[] memory y = new int[](len);

    int assetX;
    int assetY;
    for (uint i = 0; i < len; i++) {
      (assetX, assetY) = _decodeTokenId(_assetsOf[owner][i]);
      x[i] = assetX;
      y[i] = assetY;
    }

    return (x, y);
  }

  function tokenMetadata(uint256 assetId) external view override  returns (string memory ) {
    return _tokenMetadata(assetId);
  }

  function _tokenMetadata(uint256 assetId) internal view returns (string memory ) {
    address _owner = _ownerOf(assetId);
    if (_isContract(_owner) && _owner != address(estateRegistry)) {
      if ((ERC165Upgradeable(_owner)).supportsInterface(GET_METADATA)) {
        return IMetadataHolder(_owner).getMetadata(assetId);
      }
    }
    return _assetData[assetId];
  }

  function landData(int x, int y) external view returns (string memory) {
    return _tokenMetadata(_encodeTokenId(x, y));
  }

  //
  // LAND Transfer
  //

  function transferFrom(address from, address to, uint256 assetId) external override  {
    require(to != address(estateRegistry), "EstateRegistry unsafe transfers are not allowed");
    return _doTransferFrom(
      from,
      to,
      assetId,
      "",
      false
    );
  }

  function transferLand(int x, int y, address to) external {
    uint256 tokenId = _encodeTokenId(x, y);
    _doTransferFrom(
      _ownerOf(tokenId),
      to,
      tokenId,
      "",
      true
    );
  }

  function transferManyLand(int[] memory x, int[] memory  y, address to) external {
    require(x.length > 0, "You should supply at least one coordinate");
    require(x.length == y.length, "The coordinates should have the same length");

    for (uint i = 0; i < x.length; i++) {
      uint256 tokenId = _encodeTokenId(x[i], y[i]);
      _doTransferFrom(
        _ownerOf(tokenId),
        to,
        tokenId,
        "",
        true
      );
    }
  }

  function transferLandToEstate(int x, int y, uint256 estateId) external {
    require(
      estateRegistry.ownerOf(estateId) == msg.sender,
      "You must own the Estate you want to transfer to"
    );

    uint256 tokenId = _encodeTokenId(x, y);
    
    _doTransferFrom(
      _ownerOf(tokenId),
      address(estateRegistry),
      tokenId,
      toBytes(estateId),
      true
    );
  }

  function transferManyLandToEstate(int[] memory  x, int[] memory  y, uint256 estateId) external {
    require(x.length > 0, "You should supply at least one coordinate");
    require(x.length == y.length, "The coordinates should have the same length");
    require(
      estateRegistry.ownerOf(estateId) == msg.sender,
      "You must own the Estate you want to transfer to"
    );

    for (uint i = 0; i < x.length; i++) {
      uint256 tokenId = _encodeTokenId(x[i], y[i]);
      _doTransferFrom(
        _ownerOf(tokenId),
        address(estateRegistry),
        tokenId,
        toBytes(estateId),
        true
      );
    }
  }

  /**
   * @notice Set LAND updateOperator
   * @param assetId - LAND id
   * @param operator - address of the account to be set as the updateOperator
   */
  function setUpdateOperator(
    uint256 assetId,
    address operator
  )
    public
    canSetUpdateOperator(assetId)
  {
    updateOperator[assetId] = operator;

    emit UpdateOperator(assetId, operator);
  }

  /**
   * @notice Set many LAND updateOperator
   * @param _assetIds - LAND ids
   * @param _operator - address of the account to be set as the updateOperator
   */
  function setManyUpdateOperator(
    uint256[] memory  _assetIds,
    address _operator
  )
    public
  {
    for (uint i = 0; i < _assetIds.length; i++) {
      setUpdateOperator(_assetIds[i], _operator);
    }
  }

  /**
  * @dev Set an updateManager for an account
  * @param _owner - address of the account to set the updateManager
  * @param _operator - address of the account to be set as the updateManager
  * @param _approved - bool whether the address will be approved or not
  */
  function setUpdateManager(address _owner, address _operator, bool _approved) external {
    require(_operator != msg.sender, "The operator should be different from owner");
    require(
      _owner == msg.sender ||
      _isApprovedForAll(_owner, msg.sender),
      "Unauthorized user"
    );

    updateManager[_owner][_operator] = _approved;

    emit UpdateManager(
      _owner,
      _operator,
      msg.sender,
      _approved
    );
  }

  //
  // Estate generation
  //

  event EstateRegistrySet(address indexed registry);

  function setEstateRegistry(address registry) external onlyProxyOwner {
    estateRegistry = IEstateRegistry(registry);
    emit EstateRegistrySet(registry);
  }

  function createEstate(int[] memory x, int[] memory  y, address beneficiary) external returns (uint256) {
    // solium-disable-next-line arg-overflow
    return _createEstate(x, y, beneficiary, "");
  }

  function createEstateWithMetadata(
    int[] memory  x,
    int[] memory y,
    address beneficiary,
    string  memory metadata
  )
    external
    returns (uint256)
  {
    // solium-disable-next-line arg-overflow
    return _createEstate(x, y, beneficiary, metadata);
  }

  function _createEstate(
    int[] memory  x,
    int[] memory y,
    address beneficiary,
    string memory metadata
  )
    internal
    returns (uint256)
  {
    require(x.length > 0, "You should supply at least one coordinate");
    require(x.length == y.length, "The coordinates should have the same length");
    require(address(estateRegistry) != address(0), "The Estate registry should be set");

    uint256 estateTokenId = estateRegistry.mint(beneficiary, metadata);
    bytes memory estateTokenIdBytes = toBytes(estateTokenId);

    for (uint i = 0; i < x.length; i++) {
      uint256 tokenId = _encodeTokenId(x[i],y[i] );
      _doTransferFrom(
        _ownerOf(tokenId),
        address(estateRegistry),
        tokenId,
        estateTokenIdBytes,
        true
      );
    }

    return estateTokenId;
  }

  function toBytes(uint256 x) internal pure returns (bytes memory  b) {
    b = new bytes(32);
    // solium-disable-next-line security/no-inline-assembly
    assembly { mstore(add(b, 32), x) }
  }

  //
  // LAND Update
  //

  function updateLandData(
    int x,
    int y,
    string memory  data
  )
    external
  {
    return _updateLandData(x, y, data);
  }

  function _updateLandData(
    int x,
    int y,
    string memory  data
  )
    internal
    onlyUpdateAuthorized(_encodeTokenId(x, y))
  {
    uint256 assetId = _encodeTokenId(x, y);
    address owner = _holderOf[assetId];

    _update(assetId, data);

    emit Update(
      assetId,
      owner,
      msg.sender,
      data
    );
  }

  function updateManyLandData(int[] memory  x, int[] memory y, string memory data) external {
    require(x.length > 0, "You should supply at least one coordinate");
    require(x.length == y.length, "The coordinates should have the same length");
    for (uint i = 0; i < x.length; i++) {
      _updateLandData(x[i], y[i], data);
    }
  }

  /**
   * @dev Set a new land balance minime token
   * @notice Set new land balance token: `_newLandBalance`
   * @param _newLandBalance address of the new land balance token
   */
  function setLandBalanceToken(address _newLandBalance) onlyProxyOwner external {
    require(_newLandBalance != address(0), "New landBalance should not be zero address");
    landBalance = IMiniMeToken(_newLandBalance);
  }

   /**
   * @dev Register an account balance
   * @notice Register land Balance
   */
  function registerBalance() external {
    require(!registeredBalance[msg.sender], "Register Balance::The user is already registered");

    // Get balance of the sender
    uint256 currentBalance = landBalance.balanceOf(msg.sender);
    if (currentBalance > 0) {
      require(
        landBalance.destroyTokens(msg.sender, currentBalance),
        "Register Balance::Could not destroy tokens"
      );
    }

    // Set balance as registered
    registeredBalance[msg.sender] = true;

    // Get LAND balance
    uint256 newBalance = _balanceOf(msg.sender);

    // Generate Tokens
    require(
      landBalance.generateTokens(msg.sender, newBalance),
      "Register Balance::Could not generate tokens"
    );
  }

  /**
   * @dev Unregister an account balance
   * @notice Unregister land Balance
   */
  function unregisterBalance() external {
    require(registeredBalance[msg.sender], "Unregister Balance::The user not registered");

    // Set balance as unregistered
    registeredBalance[msg.sender] = false;

    // Get balance
    uint256 currentBalance = landBalance.balanceOf(msg.sender);

    // Destroy Tokens
    require(
      landBalance.destroyTokens(msg.sender, currentBalance),
      "Unregister Balance::Could not destroy tokens"
    );
  }

  function _doTransferFrom(
    address from,
    address to,
    uint256 assetId,
    bytes memory userData,
    bool doCheck
  )
    internal override 
  {
    updateOperator[assetId] = address(0);
    _updateLandBalance(from, to);
    super._doTransferFrom(
      from,
      to,
      assetId,
      userData,
      doCheck
    );
  }

  function _isContract(address addr) internal  override view returns (bool) {
    uint size;
    // solium-disable-next-line security/no-inline-assembly
    assembly { size := extcodesize(addr) }
    return size > 0;
  }

  /**
   * @dev Update account balances
   * @param _from account
   * @param _to account
   */
  function _updateLandBalance(address _from, address _to) internal {
    if (registeredBalance[_from]) {
      landBalance.destroyTokens(_from, 1);
    }

    if (registeredBalance[_to]) {
      landBalance.generateTokens(_to, 1);
    }
  }


  function tokenURI(uint256 tokenId) public view returns (string memory) {
   return __uris[tokenId];
  }
  function setOperator(address _OperatorAddress) external onlyProxyOwner{
      Operator=_OperatorAddress;
  }

}