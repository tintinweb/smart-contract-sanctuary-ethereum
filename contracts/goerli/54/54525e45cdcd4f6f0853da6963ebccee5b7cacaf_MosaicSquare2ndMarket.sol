// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

struct Member {
    address account;
    uint32 value;
  } // tuple(address, uint32)[]

interface IMoneypipeContractInitializer {
  function initialize(Member[] calldata memberData) external;
}

/*

                                                                                             ,,,

   ██████      ,██████                                                                    ▄███████
   ███████    ╔███████                                                                   ⌠█████████
   ████████▄ █████████    ,▄███████▄     ,▄████████▄   ,▄█████████µ   ▐████▌    ▄██████   ,▄██j████
   ███████████████████  ,█████████████  ╒█████▀▀████    ▀███▀▀██████  ▐████▌  ▄████████  ┌████j████
   ████▌ ██████▀ █████  █████     █████ ╟██████▄╖,        ,,,, ╟████b  ,,,,  ▐████▌
   ████▌  ╙███   █████  ████▌     ╟████  ╙▀█████████▄  ▄████████████b ▐████▌ ╟████▄
   ████▌    ▀    █████  █████▄,,,▄████▌  ╓█╓   ╙█████ ▐████    ╞████b ▐████▌  ██████▄▄███╖
   ████▌         █████   ╙███████████▀  ████████████▀  █████████████b ▐████▌   ▀█████████▀
   ▀▀▀▀¬         ▀▀▀▀▀      ╙▀▀▀▀▀╙       `▀▀▀▀▀▀▀      ╙▀▀▀▀▀ └▀▀▀▀  '▀▀▀▀       ╙▀▀▀▀

*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../Interfaces/IMSAdmin.sol";
import "../Interfaces/IMoneypipeContractInitializer.sol";

import "@openzeppelin/contracts-upgradeable/proxy/ClonesUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

contract MosaicSquareFactory {
  using AddressUpgradeable for address;

  bool private _initializing;
  address public contractAdmin;
  
  address public implementation_Moneypipe;
  uint256 public version_Moneypipe;

  event MoneypipeCreated(address indexed contractAddress, address indexed creator, uint256 indexed id, uint256 version);
  event UpdatedMoneypipe(address implementation, uint256 version);

  modifier onlyAdmin() {
    require(IMSAdmin(contractAdmin).isAdmin(msg.sender), "Admin: Only the admin can call this function");
    _;
  }
  modifier initializer() {
    require(!_initializing, "Initializable: contract is not initializing");
    _;
  }

/***************************************************************************************************
* @title Set initialization when creating contracts
****************************************************************************************************/
  constructor() {
    //_initializing = true;
  }

/***************************************************************************************************
* @notice Called once to configure the contract after the initial proxy deployment.
****************************************************************************************************/
  function initialize(address _contractAdmin) initializer external {
    require(_contractAdmin.isContract(), "Initializable: contract admin must be a contract");
    
    _initializing = true;
    contractAdmin = _contractAdmin;
  }
/***************************************************************************************************
* @notice Update the Admin contract.
****************************************************************************************************/
  function updateAdmin(address newContractAdmin) onlyAdmin external {
    contractAdmin = newContractAdmin;
  }
  
/***************************************************************************************************
* @notice Create a new Moneypipe contract.
****************************************************************************************************/
  function contractMoneypipe(uint256 id, Member[] calldata members) onlyAdmin external returns (address contractAddress) {
    require(version_Moneypipe > 0, "ContractMoneypipe: Moneypipe contract is not initialized");

    contractAddress = ClonesUpgradeable.clone(implementation_Moneypipe);
    IMoneypipeContractInitializer(contractAddress).initialize(members);

    emit MoneypipeCreated(contractAddress, msg.sender, id, version_Moneypipe);
  }

/***************************************************************************************************
* @notice Update the Moneypipe contract.
****************************************************************************************************/
  function updateImplementation_Moneypipe(address implementation) onlyAdmin external {
    require(implementation.isContract(), "Implementation: must be a contract");
    implementation_Moneypipe = implementation;
    unchecked {
      version_Moneypipe++;
    }

    emit UpdatedMoneypipe(implementation, version_Moneypipe);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IMSAdmin{
    function isAdmin(address addr) external view returns (bool);
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
library ClonesUpgradeable {
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
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "../../Interfaces/IMSAdmin.sol";

abstract contract MSAdmins is Initializable, ContextUpgradeable {
    using AddressUpgradeable for address payable;

    address private _maker;
    address payable private _market1;
    address payable private _market2;
    address payable private _admin;

    event NFTMarketUpdated(address newMarketContract);
    event MosaicSquareAdminUpdated(address newMarketContract);

    //function initialize_admin(address payable admin_) initializer public {
    function __MSAdmin_init(address payable admin_) internal onlyInitializing {
        require (admin_.isContract(),"MosaicSquareAdmin Address must be a Contract");
        _admin = admin_;
        _maker = msg.sender;
    }

    modifier onlyAdmin() {
        require(isAdmin(msg.sender), "MosaicSquareAdmin: caller does not have the Admin role");
        _;
    }

    modifier adminOrMaker() {
        require(isAdmin(msg.sender)|| _maker == _msgSender(), "caller is not the admin");
        _;
    }

    function isAdmin(address sender) public view returns (bool) {
        return IMSAdmin(_admin).isAdmin(sender);
    }

    function get1stMarketAddress() internal view returns (address payable) {
        return _market1;
    }

    function get2ndMarketAddress() internal view returns (address payable) {
        return _market2;
    }

    function update1stMarketAddress(address payable market) external onlyAdmin {
      require (market.isContract(),  "MosaicSquare 1st Market address must be a Contract");
      _market1 = market;
      emit NFTMarketUpdated(market);
    }

    function update2ndMarketAddress(address payable market) external onlyAdmin {
      require (market.isContract(),  "MosaicSquare 2nd Market address must be a Contract");
      _market2 = market;
      emit NFTMarketUpdated(market);
    }

    function updateAdminAddress(address payable admin) external adminOrMaker {
      require (admin.isContract(),  "MosaicSquare Admin address must be a Contract");
      _admin = admin;
      emit MosaicSquareAdminUpdated(admin);
    }

    /**
    * @notice This empty reserved space is put in place to allow future versions to add new
    * variables without shifting down storage in the inheritance chain.
    * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
    */
    uint256[100] private __gap;
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

/*
                                                                                             ,,,

   ██████      ,██████                                                                    ▄███████
   ███████    ╔███████                                                                   ⌠█████████
   ████████▄ █████████    ,▄███████▄     ,▄████████▄   ,▄█████████µ   ▐████▌    ▄██████   ,▄██j████
   ███████████████████  ,█████████████  ╒█████▀▀████    ▀███▀▀██████  ▐████▌  ▄████████  ┌████j████
   ████▌ ██████▀ █████  █████     █████ ╟██████▄╖,        ,,,, ╟████b  ,,,,  ▐████▌
   ████▌  ╙███   █████  ████▌     ╟████  ╙▀█████████▄  ▄████████████b ▐████▌ ╟████▄
   ████▌    ▀    █████  █████▄,,,▄████▌  ╓█╓   ╙█████ ▐████    ╞████b ▐████▌  ██████▄▄███╖
   ████▌         █████   ╙███████████▀  ████████████▀  █████████████b ▐████▌   ▀█████████▀
   ▀▀▀▀¬         ▀▀▀▀▀      ╙▀▀▀▀▀╙       `▀▀▀▀▀▀▀      ╙▀▀▀▀▀ └▀▀▀▀  '▀▀▀▀       ╙▀▀▀▀
*/



// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../Core/MSRoyalty.sol";
import "../Core/MSAdmins.sol";
import "../../Interfaces/IMSTokens.sol";

contract MosaicSquare is 
    Initializable, 
    ERC721Upgradeable, 
    ERC721EnumerableUpgradeable, 
    ERC721URIStorageUpgradeable, 
    ERC721BurnableUpgradeable,
    MSAdmins,
    MSRoyalty
  {
    using AddressUpgradeable for address payable;

    // 0으로 초기화 되지만 id는 1부터 시작.
    uint256 private _tokenIdCounter;

    string private _baseUri;

    event Minted(address indexed creator, uint256 tokenId, string ipfsPath);
    event BaseURIUpdated(string beforeBaseURI, string afterBaseURI);

    //constructor(address payable adminContract) Admins(adminContract) { }

    function initialize(address payable adminContract) initializer public {
        __ERC721_init("MosaicSquare", "MSS");
        __ERC721Enumerable_init();
        __ERC721URIStorage_init();
        __ERC721Burnable_init();
        _baseUri = "ipfs://";
        __MSAdmin_init(adminContract);
        //__ReentrancyGuard_init();
    }

    function mintToMarketWithUriAndRoyalty(
      address creator, 
      address royaltyReceiver, 
      uint96 secondarySaleRoyaltyRatio, 
      string memory uri) 
      external onlyAdmin 
    {
      require(get1stMarketAddress() != address(0), "Need to set the market address");
      uint256 tokenId = _tokenIdCounter;
      while (_exists(++tokenId)) {
      }
      _setTokenRoyaltyAddress(tokenId, royaltyReceiver, secondarySaleRoyaltyRatio);
      _mintMS(tokenId, creator, uri);
       _tokenIdCounter = tokenId;
    }
    
    function mintManualTokenIdToMarketWithUriAndRoyalty( 
      uint256 tokenId, 
      address creator, 
      address royaltyReceiver, 
      uint96 secondarySaleRoyaltyRatio, 
      string memory uri) 
      external onlyAdmin 
    {
      require(!_exists(tokenId), "Already used");
      require(get1stMarketAddress() != address(0), "Need to set the market address");

      _setTokenRoyaltyAddress(tokenId, royaltyReceiver, secondarySaleRoyaltyRatio);
      _mintMS(tokenId, creator, uri);
    }

    function getLastTokenId() external view returns (uint256) {
      return _tokenIdCounter;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function updateBaseURI(string memory baseURI) 
      external onlyAdmin  {
      //string memory beforeBaseURI = _baseURI();
      _baseUri = baseURI;

      //emit BaseURIUpdated(beforeBaseURI, baseURI);
    }

    function burn(uint256 tokenId) public override {
        require( isAdmin(_msgSender()) || _isApprovedOrOwner(_msgSender(), tokenId), 
          "caller is not admin nor approved");
        _burn(tokenId);
    }

    function transferTo2ndMarket(address from, uint256 tokenId) external {
      require(get2ndMarketAddress() != address(0), "Need to set the market address");
      require (msg.sender == get2ndMarketAddress(), "caller is not market" );
      _transfer(from, get2ndMarketAddress(), tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view virtual
        override(MSRoyalty, ERC721Upgradeable, ERC721EnumerableUpgradeable)
        returns (bool)
    {
        if ( interfaceId == type(IMSTokens).interfaceId || 
             interfaceId == type(IMSAdmin).interfaceId ) {
            return true;
        } else {
            return super.supportsInterface(interfaceId);
        }
    }


    // internals
    function _mintMS(
      uint256 tokenId, 
      address creator,
      string memory uri) 
      internal 
    {
      _safeMint(creator, tokenId);
      _setTokenURI(tokenId, uri);
      _transferTo1stMarket(creator, tokenId);

      emit Minted(creator, tokenId, uri);
    }
    
    function _baseURI() internal view override returns (string memory) {
        return _baseUri;
    }

    function _transferTo1stMarket(address from, uint256 tokenId) internal {
      // 마켓이 onERC721Received 를 구현하지 않았어도 구매자에게 전송 가능한 함수가 있으니 safe를 사용할 필요가 없음.
      _transfer(from, get1stMarketAddress(), tokenId);
    }

    // The following functions are overrides required by Solidity
    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
    {
        super._burn(tokenId);
    }

    /**
    * @notice This empty reserved space is put in place to allow future versions to add new
    * variables without shifting down storage in the inheritance chain.
    * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
    */
    uint256[100] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721Upgradeable.sol";
import "./IERC721ReceiverUpgradeable.sol";
import "./extensions/IERC721MetadataUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../utils/StringsUpgradeable.sol";
import "../../utils/introspection/ERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC721Upgradeable, IERC721MetadataUpgradeable {
    using AddressUpgradeable for address;
    using StringsUpgradeable for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    function __ERC721_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC721_init_unchained(name_, symbol_);
    }

    function __ERC721_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return
            interfaceId == type(IERC721Upgradeable).interfaceId ||
            interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721Upgradeable.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721Upgradeable.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721Upgradeable.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721ReceiverUpgradeable(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721ReceiverUpgradeable.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[44] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../ERC721Upgradeable.sol";
import "./IERC721EnumerableUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721EnumerableUpgradeable is Initializable, ERC721Upgradeable, IERC721EnumerableUpgradeable {
    function __ERC721Enumerable_init() internal onlyInitializing {
    }

    function __ERC721Enumerable_init_unchained() internal onlyInitializing {
    }
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165Upgradeable, ERC721Upgradeable) returns (bool) {
        return interfaceId == type(IERC721EnumerableUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Upgradeable.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721EnumerableUpgradeable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721Upgradeable.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721Upgradeable.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[46] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/extensions/ERC721URIStorage.sol)

pragma solidity ^0.8.0;

import "../ERC721Upgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev ERC721 token with storage based token URI management.
 */
abstract contract ERC721URIStorageUpgradeable is Initializable, ERC721Upgradeable {
    function __ERC721URIStorage_init() internal onlyInitializing {
    }

    function __ERC721URIStorage_init_unchained() internal onlyInitializing {
    }
    using StringsUpgradeable for uint256;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev See {ERC721-_burn}. This override additionally checks to see if a
     * token-specific URI was set for the token, and if so, it deletes the token URI from
     * the storage mapping.
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/extensions/ERC721Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC721Upgradeable.sol";
import "../../../utils/ContextUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @title ERC721 Burnable Token
 * @dev ERC721 Token that can be burned (destroyed).
 */
abstract contract ERC721BurnableUpgradeable is Initializable, ContextUpgradeable, ERC721Upgradeable {
    function __ERC721Burnable_init() internal onlyInitializing {
    }

    function __ERC721Burnable_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev Burns `tokenId`. See {ERC721-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId) public virtual {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _burn(tokenId);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC2981Upgradeable.sol";
import "../Core/MSAdmins.sol";

abstract contract MSRoyalty is IERC2981Upgradeable, 
    ERC721Upgradeable, MSAdmins
{
    uint256 private constant ROYALTY_BASIS_POINTS = 10000;
    uint256 private constant ROYALTY_MARKET_RATIO = 500;
    uint256 private constant ROYALTY_DEFAULT_RATIO = 1000;
    struct RoyaltyInfo {
      address receiver;
      uint256 ratio;
    }
    mapping(uint256 => RoyaltyInfo) private _tokenRoyaltyInfo;

    event TokenRoyaltyAddressSet(address beforeAddress,address afterAddress, uint256 tokenId);
    event TokenRoyaltyRatioUpdated(uint256 ratio, uint256 tokenId);

    function _setTokenRoyaltyAddress(uint256 tokenId, address royaltyAddress, uint96 ratio) internal {
      if (royaltyAddress == address(0)) return;
      emit TokenRoyaltyAddressSet(_tokenRoyaltyInfo[tokenId].receiver, 
        royaltyAddress, tokenId);
      _tokenRoyaltyInfo[tokenId].receiver = royaltyAddress;
      _tokenRoyaltyInfo[tokenId].ratio = ratio;
    }

    function updateRoyaltyRatio(uint256 tokenId, uint96 ratio) external onlyAdmin {
      require(_exists(tokenId), "MSRoyalty: Invalid token ID");
      require(_tokenRoyaltyInfo[tokenId].receiver != address(0), "MSRoyalty: Invalid royalty info");

      _tokenRoyaltyInfo[tokenId].ratio = ratio;
      emit TokenRoyaltyRatioUpdated(ratio, tokenId);
    }

    function getRoyaltyAddress(uint256 tokenId)
      public
      view
      returns (address royaltyAddress, uint256 ratio)
    {
      require(_exists(tokenId), "MSRoyalty: Invalid token ID");
      royaltyAddress = _tokenRoyaltyInfo[tokenId].receiver;
      ratio = _tokenRoyaltyInfo[tokenId].ratio;
    }

    // ERC2981
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
      external
      view override
      returns (address receiver, uint256 royaltyAmount)
    {
      RoyaltyInfo memory royalty = _tokenRoyaltyInfo[tokenId];
      receiver = royalty.receiver;
      if (royalty.receiver == address(0)) {
        royaltyAmount = 0;
      } else {
        royaltyAmount = salePrice * royalty.ratio / ROYALTY_BASIS_POINTS;
      }
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view virtual override(IERC165Upgradeable, ERC721Upgradeable)
        returns (bool)
    {
        return interfaceId == type(IERC2981Upgradeable).interfaceId
             || super.supportsInterface(interfaceId);
    }
    /**
    * @notice This empty reserved space is put in place to allow future versions to add new
    * variables without shifting down storage in the inheritance chain.
    * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
    */
    uint256[100] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IMSTokens{
    function transferTo2ndMarket(address from, uint256 tokenId) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721MetadataUpgradeable is IERC721Upgradeable {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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
interface IERC165Upgradeable {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721EnumerableUpgradeable is IERC721Upgradeable {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981Upgradeable is IERC165Upgradeable {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165CheckerUpgradeable.sol";

import "./Constants.sol";

import "@openzeppelin/contracts-upgradeable/interfaces/IERC2981Upgradeable.sol";
import "../../Interfaces/IMSTokens.sol";

/***************************************************************************************************
* @title Interface for other contracts
****************************************************************************************************/
abstract contract SupportsInterfaces is Constants, ReentrancyGuardUpgradeable { // Adding this unused mixin to help with linearization 
  using ERC165CheckerUpgradeable for address;

/***************************************************************************************************
* @notice Looks up the royalty payment configuration for a given NFT.
****************************************************************************************************/
  function _getInterfacesCreatorPaymentInfo(address nftContract, uint256 tokenId) internal view returns (address payable recipient, uint256 royaltyPoints) {
    // 1st priority: ERC-2981
    if (nftContract.supportsInterface(type(IERC2981Upgradeable).interfaceId)) {
      (address receiver, uint256 points) = IERC2981Upgradeable(nftContract).royaltyInfo(tokenId, BASIS_POINTS);
      if (receiver != address(0)) {
        recipient = payable(receiver);
        royaltyPoints = points;
      }
    }
    return (recipient, royaltyPoints);
  }

/***************************************************************************************************
* @notice NFT Owner
****************************************************************************************************/
  function _getInterfacesOwnerOf(address nftContract, uint256 tokenId) internal view returns (address tokenOwner) {
    if (nftContract.supportsInterface(type(IERC721Upgradeable).interfaceId)) {
      tokenOwner = IERC721Upgradeable(nftContract).ownerOf(tokenId);
    } else {
      revert("supportsInterface: The contract is not ERC721");
    }
  }

/***************************************************************************************************
* @notice If it is MOSAIC SQUARE NFT, use the corresponding interface to call the TransferFrom function.
****************************************************************************************************/
  function _getInterfacestransferTo2ndMarket(address nftContract, uint256 tokenId) internal returns (bool) {
    if (nftContract.supportsInterface(type(IMSTokens).interfaceId)) {
      IMSTokens(nftContract).transferTo2ndMarket(msg.sender, tokenId);
      return true;
    }
    return false;
  }

/***************************************************************************************************
* @notice This empty reserved space is put in place to allow future versions to add new
* variables without shifting down storage in the inheritance chain.
* See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
****************************************************************************************************/
  uint256[100] private __gap;
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
// OpenZeppelin Contracts (last updated v4.7.2) (utils/introspection/ERC165Checker.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165CheckerUpgradeable {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface,
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            _supportsERC165Interface(account, type(IERC165Upgradeable).interfaceId) &&
            !_supportsERC165Interface(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && _supportsERC165Interface(account, interfaceId);
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
    function getSupportedInterfaces(address account, bytes4[] memory interfaceIds)
        internal
        view
        returns (bool[] memory)
    {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = _supportsERC165Interface(account, interfaceIds[i]);
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
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!_supportsERC165Interface(account, interfaceIds[i])) {
                return false;
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
    function _supportsERC165Interface(address account, bytes4 interfaceId) private view returns (bool) {
        // prepare call
        bytes memory encodedParams = abi.encodeWithSelector(IERC165Upgradeable.supportsInterface.selector, interfaceId);

        // perform static call
        bool success;
        uint256 returnSize;
        uint256 returnValue;
        assembly {
            success := staticcall(30000, account, add(encodedParams, 0x20), mload(encodedParams), 0x00, 0x20)
            returnSize := returndatasize()
            returnValue := mload(0x00)
        }

        return success && returnSize >= 0x20 && returnValue > 0;
    }
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

/***************************************************************************************************
* @title Constant values shared across mixins.
****************************************************************************************************/
abstract contract Constants {
  
  /// @notice 100% in basis points.
  uint256 internal constant BASIS_POINTS = 10000;
    /// @notice 마켓 수수료 최소 값
  uint16 internal constant MIN_MARKET_FEE_POINTS = 100; // 1%
  /// @notice 마켓 수수료 최대 값
  uint16 internal constant MAX_MARKET_FEE_POINTS = 5000; // 50%
  /// @notice 기본 마켓 수수료
  uint16 internal constant DEFAULT_MARKET_FEE_POINTS = 500; // 5%
  /// @notice 기본 로열티 수수료
  uint16 internal constant DEFAULT_ROYALTY_FEE_POINTS = 1000; // 10%

  /// @notice The minimum increase of 10% required when making an offer or placing a bid.
  uint16 internal constant MIN_PERCENT_INCREMENT_IN_POINTS = 1000; // 10%
  /// @notice If the amount of adaptation is more than 1ETH, the bid amount increases by 5%
  uint16 internal constant MAX_PERCENT_INCREMENT_IN_POINTS = 500; // 5%

  /// @notice The gas limit to send ETH to multiple recipients, enough for a 5-way split.
  uint256 internal constant SEND_VALUE_GAS_LIMIT_MULTIPLE_RECIPIENTS = 210000;

  /// @notice The gas limit to send ETH to a single recipient, enough for a contract with a simple receiver.
  uint256 internal constant SEND_VALUE_GAS_LIMIT_SINGLE_RECIPIENT = 20000;

  /// @notice The window for auction extensions, any bid placed in the final 15 minutes
  /// of an auction will reset the time remaining to 15 minutes.
  uint256 internal constant EXTENSION_DURATION = 10 minutes;

  /// @notice Caps the max duration that may be configured so that overflows will not occur.
  uint256 internal constant MAX_DURATION = 1000 days;
  /// @notice 오퍼 제안 시간 (FixedPrice 제안 시간 + 오퍼 제안 시간 으로 설정됨)
  uint256 internal constant DURATION_OFFER = 24 hours;
  
  /// @notice 판매 시작 금액
  uint256 internal constant MIN_START_PRICE = 0.01 ether;
  /// @notice Offer 최소 제안 가격 증가 값
  uint256 internal constant MIN_INCREMENT_OFFER = 0.001 ether;

/***************************************************************************************************
* @notice This empty reserved space is put in place to allow future versions to add new
* variables without shifting down storage in the inheritance chain.
* See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
****************************************************************************************************/
  uint256[100] private __gap;
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./MarketCore.sol";

import "../Utils/AdminTreasury.sol";
import "../Utils/Constants.sol";
import "../Utils/SupportsInterfaces.sol";
import "../Utils/SendValueWithFallbackWithdraw.sol";

/***************************************************************************************************
* @title A mixin to distribute funds when an NFT is sold.
****************************************************************************************************/
abstract contract MarketFees is Constants, Initializable, AdminTreasury, MarketCore, SupportsInterfaces, SendValueWithFallbackWithdraw {
  using AddressUpgradeable for address payable;
  
/***************************************************************************************************
* @notice Distributes funds to market, creator recipients, and NFT owner after a sale.
****************************************************************************************************/
  function _distributeFunds(address nftContract, uint256 tokenId, address payable seller, uint256 price, uint16 sendMarketFee) internal returns (uint256 marketFee, uint256 creatorFee, uint256 ownerRev)
  {
    address payable creatorRecipient;
    address payable ownerRevTo;
    (marketFee, creatorRecipient, creatorFee, ownerRevTo, ownerRev) = _getFees(nftContract, tokenId, seller, price, sendMarketFee);

    _sendValueWithFallbackWithdraw(nftContract, tokenId, treasury, marketFee, SEND_VALUE_GAS_LIMIT_SINGLE_RECIPIENT);

    if (creatorFee > 0 && creatorRecipient != address(0)) {
      _sendValueWithFallbackWithdraw(nftContract, tokenId, creatorRecipient, creatorFee, SEND_VALUE_GAS_LIMIT_MULTIPLE_RECIPIENTS);
    }
    _sendValueWithFallbackWithdraw(nftContract, tokenId, ownerRevTo, ownerRev, SEND_VALUE_GAS_LIMIT_SINGLE_RECIPIENT);
  }

/***************************************************************************************************
* @dev Calculates how funds should be distributed for the given sale details.
****************************************************************************************************/
  function _getFees(address nftContract, uint256 tokenId, address payable seller, uint256 price, uint16 sendMarketFee) private view
    returns (uint256 marketFee, address payable creatorRecipient, uint256 creatorRev, address payable ownerRevTo, uint256 ownerRev) {
    
    uint256 royaltyPoints = 0;
    (creatorRecipient, royaltyPoints)= _getInterfacesCreatorPaymentInfo(nftContract, tokenId);
    
    // Calculate the market fee
    marketFee = (price * sendMarketFee) / BASIS_POINTS;
    creatorRev = 0;

    if (creatorRecipient != address(0)) {
      // When sold by the creator, all revenue is split if applicable.
      if (royaltyPoints < DEFAULT_ROYALTY_FEE_POINTS) {
        creatorRev = (price * royaltyPoints) / BASIS_POINTS;
      } else {
        creatorRev = (price * DEFAULT_ROYALTY_FEE_POINTS) / BASIS_POINTS;
      }
    }
    ownerRevTo = seller;
    ownerRev = price - creatorRev - marketFee;
  }

/***************************************************************************************************
   * @notice This empty reserved space is put in place to allow future versions to add new
   * variables without shifting down storage in the inheritance chain.
   * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
****************************************************************************************************/
  uint256[100] private __gap;
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "../Utils/Constants.sol";

/***************************************************************************************************
* @title A place for common modifiers and functions used by various NFTMarket mixins, if any.
* @dev This also leaves a gap which can be used to add a new mixin to the top of the inheritance tree.
****************************************************************************************************/
abstract contract MarketCore is Constants, Initializable {
  using AddressUpgradeable for address;

  uint256 private minIncrement;
  uint16 public marketFee;

  mapping (uint256 => bool) private durationSettingPeriod;

/***************************************************************************************************
* @notice initialization
****************************************************************************************************/  
  function _initializeMarketCore() internal onlyInitializing {
    minIncrement = MIN_INCREMENT_OFFER;
    marketFee = DEFAULT_MARKET_FEE_POINTS;
    durationSettingPeriod[1 days] = true;
    durationSettingPeriod[3 days] = true;
    durationSettingPeriod[7 days] = true;
  }

/***************************************************************************************************
* @notice Transfers the NFT from escrow and clears any state tracking this escrowed NFT.
****************************************************************************************************/
  function _transferFromMarket(address nftContract, uint256 tokenId, address recipient) internal virtual {
    IERC721Upgradeable(nftContract).transferFrom(address(this), recipient, tokenId);
  }

/***************************************************************************************************
* @notice Transfers an NFT into escrow,
* if already there this requires the msg.sender is authorized to manage the sale of this NFT.
****************************************************************************************************/
  function _transferToMarket(address nftContract, uint256 tokenId) internal virtual {
    IERC721Upgradeable(nftContract).transferFrom(msg.sender, address(this), tokenId);
  }

/***************************************************************************************************
* @dev Determines the minimum amount when increasing an existing offer or bid.
****************************************************************************************************/
  function _getMinIncrement(uint256 currentAmount) internal view returns (uint256) {
    return minIncrement + currentAmount;
  }

/***************************************************************************************************
* @notice Set minimal increase value
****************************************************************************************************/
  function _updateMinIncrement(uint256 _minIncrement) internal {
    minIncrement = _minIncrement;
  }

/***************************************************************************************************
* @notice Market fee setting
****************************************************************************************************/
  function _updateMarketFee(uint16 _marketFee) internal {
    if (MIN_MARKET_FEE_POINTS > _marketFee || _marketFee > MAX_MARKET_FEE_POINTS) {
      revert("MarketCore: Market fee value error");
    }
    marketFee = _marketFee;
  }

/***************************************************************************************************
* @notice Duration setting period update
****************************************************************************************************/
  function _addDurationSettingPeriod(uint256 _period) internal {
    durationSettingPeriod[_period] = true;
  }

/***************************************************************************************************
* @notice Duration setting period remove
****************************************************************************************************/
  function _removeDurationSettingPeriod(uint256 _period) internal {
    delete durationSettingPeriod[_period];
  }

/***************************************************************************************************
* @notice Check duration setting period
****************************************************************************************************/
  function _checkDurationSettingPeriod(uint256 _period) internal view returns (bool) {
    return durationSettingPeriod[_period];
  }

/***************************************************************************************************
* @notice This empty reserved space is put in place to allow future versions to add new
* variables without shifting down storage in the inheritance chain.
* See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
* @dev 50 slots were consumed by adding `ReentrancyGuard`.
****************************************************************************************************/
  uint256[100] private __gap;
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

import "../../Interfaces/IMSAdmin.sol";

/***************************************************************************************************
* @title Wallet address and administrator account management to receive fees
****************************************************************************************************/
abstract contract AdminTreasury is Initializable {
  using AddressUpgradeable for address payable;
  using AddressUpgradeable for address;

  address payable public treasury; // The address of the treasury contract.
  address public contractAdmin; // The address of the admin contract.

/***************************************************************************************************
* @notice Manager check
****************************************************************************************************/  
  modifier onlyAdmin() {
    require(IMSAdmin(contractAdmin).isAdmin(msg.sender), "Admin: Only the admin can call this function");
    _;
  }

/***************************************************************************************************
* @notice Administrator address setting initialization
****************************************************************************************************/  
  function _initializeAdminTreasury(address _contractAdmin, address payable _treasury) internal onlyInitializing {
    require(_contractAdmin.isContract(), "AdminTreasury: The contract admin address must be a contract");
    require(!_treasury.isContract(), "AdminTreasury: The treasury address should not be a contract");
    
    contractAdmin = _contractAdmin;
    treasury = _treasury;
  }

/***************************************************************************************************
* @notice Set Treasury address.
****************************************************************************************************/
  function setTreasury(address payable _treasury) onlyAdmin external {
    require(!_treasury.isContract(), "AdminTreasury: The treasury address should not be a contract");
    treasury = _treasury;
  }

/***************************************************************************************************
* @notice Set Admin address.
****************************************************************************************************/
  function setAdmin(address _contractAdmin) onlyAdmin external {
    require(_contractAdmin.isContract(), "AdminTreasury: The contract admin address must be a contract");
    contractAdmin = _contractAdmin;
  }

/***************************************************************************************************
* @notice This empty reserved space is put in place to allow future versions to add new
* variables without shifting down storage in the inheritance chain.
* See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
****************************************************************************************************/
  uint256[100] private __gap;
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableMapUpgradeable.sol";

/***************************************************************************************************
* @title A mixin for sending ETH with a fallback withdraw mechanism.
* @notice Attempt to send ETH and if the transfer fails or runs out of gas, store the balance
* for future withdrawal instead.
****************************************************************************************************/
abstract contract SendValueWithFallbackWithdraw is ReentrancyGuardUpgradeable {
  using AddressUpgradeable for address payable;
  using EnumerableMapUpgradeable for EnumerableMapUpgradeable.AddressToUintMap;

  //address[] pendingWithdrawAddress;
  //mapping(address => uint256) private pendingWithdrawals; // Tracks the amount of ETH that is stored in escrow for future withdrawal.
  EnumerableMapUpgradeable.AddressToUintMap pendingWithdrawals;
  
/***************************************************************************************************
* @notice Emitted when an attempt to send ETH fails or runs out of gas and the value is stored in escrow instead.
* @param nftContract The address of the NFT contract.
* @param tokenId The ID of the token.
* @param user The account which has escrowed ETH to withdraw.
* @param amount The amount of ETH which has been added to the user's escrow balance.
****************************************************************************************************/
  event WithdrawPending(address indexed nftContract, uint256 indexed tokenId, address user, uint256 amount);
/***************************************************************************************************
* @notice Emitted when escrowed funds are withdrawn.
* @param user The account which has withdrawn ETH.
* @param amount The amount of ETH which has been withdrawn.
****************************************************************************************************/
  event Withdrawal(address indexed user, uint256 amount);
/***************************************************************************************************
* @notice Allows a user to manually withdraw funds which originally failed to transfer to themselves.
****************************************************************************************************/
  function withdraw() external {
    withdrawFor(payable(msg.sender));
  }

/***************************************************************************************************
* @notice Allows anyone to manually trigger a withdrawal of funds which originally failed to transfer for a user.
* @param user The account which has escrowed ETH to withdraw.
****************************************************************************************************/
  function withdrawFor(address payable user) public nonReentrant {
    (, uint256 amount) = pendingWithdrawals.tryGet(user);
    require(amount != 0, "SendValueWithFallbackWithdraw: No Funds Available"); 
    
    pendingWithdrawals.remove(user);
    user.sendValue(amount);
    
    emit Withdrawal(user, amount);
  }

/***************************************************************************************************
* @notice Withdrawal to all those who will be withdrawn
****************************************************************************************************/
  function _withdrawAll(uint256 gasLimit) internal nonReentrant {
    uint256 withdrawCount = pendingWithdrawals.length();
    for (uint256 i = 0; i < withdrawCount; i++) {
      (address user, uint256 amount) = pendingWithdrawals.at(0);
      pendingWithdrawals.remove(user);
      
      (bool success, ) = user.call{ value: amount, gas: gasLimit }("");
      if (!success) {
      // Record failed sends for a withdrawal later
      // Transfers could fail if sent to a multisig with non-trivial receiver logic
        unchecked {
          (, uint256 originalAmount) = pendingWithdrawals.tryGet(user);
          pendingWithdrawals.set(user, originalAmount + amount);
        }
        emit WithdrawPending(address(0), 0, user, amount);
        break; // 일단 멈추자
      } else {
        emit Withdrawal(user, amount);
      }
    }
  }

/***************************************************************************************************
* @dev Attempt to send a user or contract ETH and if it fails store the amount owned for later withdrawal.
****************************************************************************************************/
  function _sendValueWithFallbackWithdraw(address nftContract, uint256 tokenId, address payable user, uint256 amount, uint256 gasLimit) internal {
    if (amount == 0) {
      return;
    }
    // Cap the gas to prevent consuming all available gas to block a tx from completing successfully
    // solhint-disable-next-line avoid-low-level-calls
    (bool success, ) = user.call{ value: amount, gas: gasLimit }("");
    if (!success) {
      // Record failed sends for a withdrawal later
      // Transfers could fail if sent to a multisig with non-trivial receiver logic
      unchecked {
        (, uint256 originalAmount) = pendingWithdrawals.tryGet(user);
        pendingWithdrawals.set(user, originalAmount + amount);
      }
      
      emit WithdrawPending(nftContract, tokenId, user, amount);
    }
  }

/***************************************************************************************************
* @notice Returns how much funds are available for manual withdraw due to failed transfers.
* @param user The account to check the escrowed balance of.
* @return balance The amount of funds which are available for withdrawal for the given user.
****************************************************************************************************/
  function getPendingWithdrawal(address user) external view returns (uint256 balance) {
    (, balance) = pendingWithdrawals.tryGet(user);
    return balance;
  }

/***************************************************************************************************
* @notice Check if there are any users who are holding withdrawal
* @return count The number of users who are holding withdrawal.
****************************************************************************************************/
  function getPendingWithdrawalCount() external view returns (uint256 count) {
    return pendingWithdrawals.length();
  }

/***************************************************************************************************
* @notice Return to withdrawal
* @return balance This is the amount you need to withdraw.
****************************************************************************************************/
  function getPendingWithdrawalAmount() external view returns (uint256 balance) {
    for (uint256 i = 0; i < pendingWithdrawals.length(); i++) {
      (, uint256 amount) = pendingWithdrawals.at(i);
      balance += amount;
    }
    return balance;
  }

/***************************************************************************************************
* @notice Check if there are any users who are holding withdrawal
* @return count The number of users who are holding withdrawal.
****************************************************************************************************
  function getPendingWithdrawalIndex(uint256 index) external view returns (address user, uint256 amount) {
    (user, amount) = pendingWithdrawals.at(index);
    return (user, amount);
  }
/***************************************************************************************************
* @notice Check if there are any users who are holding withdrawal
* @return count The number of users who are holding withdrawal.
****************************************************************************************************
  function getPendingWithdrawalIndexRemove(uint256 index) public {
    (address user, ) = pendingWithdrawals.at(index);
    pendingWithdrawals.remove(user);
  }
/***************************************************************************************************
* @notice Check if there are any users who are holding withdrawal
* @return count The number of users who are holding withdrawal.
****************************************************************************************************
  function getPendingWithdrawalIndexRemoveSet(uint256 index) public {
    (address user, uint256 amount) = pendingWithdrawals.at(index);
    pendingWithdrawals.remove(user);

    (, uint256 originalAmount) = pendingWithdrawals.tryGet(user);
    pendingWithdrawals.set(user, originalAmount + amount);
  }

/***************************************************************************************************
* @notice This empty reserved space is put in place to allow future versions to add new
* variables without shifting down storage in the inheritance chain.
* See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
****************************************************************************************************/
  uint256[100] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableMap.sol)

pragma solidity ^0.8.0;

import "./EnumerableSetUpgradeable.sol";

/**
 * @dev Library for managing an enumerable variant of Solidity's
 * https://solidity.readthedocs.io/en/latest/types.html#mapping-types[`mapping`]
 * type.
 *
 * Maps have the following properties:
 *
 * - Entries are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Entries are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableMap for EnumerableMap.UintToAddressMap;
 *
 *     // Declare a set state variable
 *     EnumerableMap.UintToAddressMap private myMap;
 * }
 * ```
 *
 * The following map types are supported:
 *
 * - `uint256 -> address` (`UintToAddressMap`) since v3.0.0
 * - `address -> uint256` (`AddressToUintMap`) since v4.6.0
 * - `bytes32 -> bytes32` (`Bytes32ToBytes32`) since v4.6.0
 * - `uint256 -> uint256` (`UintToUintMap`) since v4.7.0
 * - `bytes32 -> uint256` (`Bytes32ToUintMap`) since v4.7.0
 *
 * [WARNING]
 * ====
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableMap, you can either remove all elements one by one or create a fresh instance using an array of EnumerableMap.
 * ====
 */
library EnumerableMapUpgradeable {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.Bytes32Set;

    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Map type with
    // bytes32 keys and values.
    // The Map implementation uses private functions, and user-facing
    // implementations (such as Uint256ToAddressMap) are just wrappers around
    // the underlying Map.
    // This means that we can only create new EnumerableMaps for types that fit
    // in bytes32.

    struct Bytes32ToBytes32Map {
        // Storage of keys
        EnumerableSetUpgradeable.Bytes32Set _keys;
        mapping(bytes32 => bytes32) _values;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        Bytes32ToBytes32Map storage map,
        bytes32 key,
        bytes32 value
    ) internal returns (bool) {
        map._values[key] = value;
        return map._keys.add(key);
    }

    /**
     * @dev Removes a key-value pair from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(Bytes32ToBytes32Map storage map, bytes32 key) internal returns (bool) {
        delete map._values[key];
        return map._keys.remove(key);
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(Bytes32ToBytes32Map storage map, bytes32 key) internal view returns (bool) {
        return map._keys.contains(key);
    }

    /**
     * @dev Returns the number of key-value pairs in the map. O(1).
     */
    function length(Bytes32ToBytes32Map storage map) internal view returns (uint256) {
        return map._keys.length();
    }

    /**
     * @dev Returns the key-value pair stored at position `index` in the map. O(1).
     *
     * Note that there are no guarantees on the ordering of entries inside the
     * array, and it may change when more entries are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32ToBytes32Map storage map, uint256 index) internal view returns (bytes32, bytes32) {
        bytes32 key = map._keys.at(index);
        return (key, map._values[key]);
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(Bytes32ToBytes32Map storage map, bytes32 key) internal view returns (bool, bytes32) {
        bytes32 value = map._values[key];
        if (value == bytes32(0)) {
            return (contains(map, key), bytes32(0));
        } else {
            return (true, value);
        }
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(Bytes32ToBytes32Map storage map, bytes32 key) internal view returns (bytes32) {
        bytes32 value = map._values[key];
        require(value != 0 || contains(map, key), "EnumerableMap: nonexistent key");
        return value;
    }

    /**
     * @dev Same as {_get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {_tryGet}.
     */
    function get(
        Bytes32ToBytes32Map storage map,
        bytes32 key,
        string memory errorMessage
    ) internal view returns (bytes32) {
        bytes32 value = map._values[key];
        require(value != 0 || contains(map, key), errorMessage);
        return value;
    }

    // UintToUintMap

    struct UintToUintMap {
        Bytes32ToBytes32Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        UintToUintMap storage map,
        uint256 key,
        uint256 value
    ) internal returns (bool) {
        return set(map._inner, bytes32(key), bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(UintToUintMap storage map, uint256 key) internal returns (bool) {
        return remove(map._inner, bytes32(key));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(UintToUintMap storage map, uint256 key) internal view returns (bool) {
        return contains(map._inner, bytes32(key));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(UintToUintMap storage map) internal view returns (uint256) {
        return length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintToUintMap storage map, uint256 index) internal view returns (uint256, uint256) {
        (bytes32 key, bytes32 value) = at(map._inner, index);
        return (uint256(key), uint256(value));
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(UintToUintMap storage map, uint256 key) internal view returns (bool, uint256) {
        (bool success, bytes32 value) = tryGet(map._inner, bytes32(key));
        return (success, uint256(value));
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(UintToUintMap storage map, uint256 key) internal view returns (uint256) {
        return uint256(get(map._inner, bytes32(key)));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        UintToUintMap storage map,
        uint256 key,
        string memory errorMessage
    ) internal view returns (uint256) {
        return uint256(get(map._inner, bytes32(key), errorMessage));
    }

    // UintToAddressMap

    struct UintToAddressMap {
        Bytes32ToBytes32Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        UintToAddressMap storage map,
        uint256 key,
        address value
    ) internal returns (bool) {
        return set(map._inner, bytes32(key), bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(UintToAddressMap storage map, uint256 key) internal returns (bool) {
        return remove(map._inner, bytes32(key));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(UintToAddressMap storage map, uint256 key) internal view returns (bool) {
        return contains(map._inner, bytes32(key));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(UintToAddressMap storage map) internal view returns (uint256) {
        return length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintToAddressMap storage map, uint256 index) internal view returns (uint256, address) {
        (bytes32 key, bytes32 value) = at(map._inner, index);
        return (uint256(key), address(uint160(uint256(value))));
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     *
     * _Available since v3.4._
     */
    function tryGet(UintToAddressMap storage map, uint256 key) internal view returns (bool, address) {
        (bool success, bytes32 value) = tryGet(map._inner, bytes32(key));
        return (success, address(uint160(uint256(value))));
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(UintToAddressMap storage map, uint256 key) internal view returns (address) {
        return address(uint160(uint256(get(map._inner, bytes32(key)))));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        UintToAddressMap storage map,
        uint256 key,
        string memory errorMessage
    ) internal view returns (address) {
        return address(uint160(uint256(get(map._inner, bytes32(key), errorMessage))));
    }

    // AddressToUintMap

    struct AddressToUintMap {
        Bytes32ToBytes32Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        AddressToUintMap storage map,
        address key,
        uint256 value
    ) internal returns (bool) {
        return set(map._inner, bytes32(uint256(uint160(key))), bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(AddressToUintMap storage map, address key) internal returns (bool) {
        return remove(map._inner, bytes32(uint256(uint160(key))));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(AddressToUintMap storage map, address key) internal view returns (bool) {
        return contains(map._inner, bytes32(uint256(uint160(key))));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(AddressToUintMap storage map) internal view returns (uint256) {
        return length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressToUintMap storage map, uint256 index) internal view returns (address, uint256) {
        (bytes32 key, bytes32 value) = at(map._inner, index);
        return (address(uint160(uint256(key))), uint256(value));
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(AddressToUintMap storage map, address key) internal view returns (bool, uint256) {
        (bool success, bytes32 value) = tryGet(map._inner, bytes32(uint256(uint160(key))));
        return (success, uint256(value));
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(AddressToUintMap storage map, address key) internal view returns (uint256) {
        return uint256(get(map._inner, bytes32(uint256(uint160(key)))));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        AddressToUintMap storage map,
        address key,
        string memory errorMessage
    ) internal view returns (uint256) {
        return uint256(get(map._inner, bytes32(uint256(uint160(key))), errorMessage));
    }

    // Bytes32ToUintMap

    struct Bytes32ToUintMap {
        Bytes32ToBytes32Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        Bytes32ToUintMap storage map,
        bytes32 key,
        uint256 value
    ) internal returns (bool) {
        return set(map._inner, key, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(Bytes32ToUintMap storage map, bytes32 key) internal returns (bool) {
        return remove(map._inner, key);
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(Bytes32ToUintMap storage map, bytes32 key) internal view returns (bool) {
        return contains(map._inner, key);
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(Bytes32ToUintMap storage map) internal view returns (uint256) {
        return length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32ToUintMap storage map, uint256 index) internal view returns (bytes32, uint256) {
        (bytes32 key, bytes32 value) = at(map._inner, index);
        return (key, uint256(value));
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(Bytes32ToUintMap storage map, bytes32 key) internal view returns (bool, uint256) {
        (bool success, bytes32 value) = tryGet(map._inner, key);
        return (success, uint256(value));
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(Bytes32ToUintMap storage map, bytes32 key) internal view returns (uint256) {
        return uint256(get(map._inner, key));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        Bytes32ToUintMap storage map,
        bytes32 key,
        string memory errorMessage
    ) internal view returns (uint256) {
        return uint256(get(map._inner, key, errorMessage));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
 * ====
 */
library EnumerableSetUpgradeable {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "./MarketCore.sol";
import "./MarketFees.sol";

import "../Utils/SendValueWithFallbackWithdraw.sol";

/***************************************************************************************************
* @title Allows collectors to make an offer for an NFT, valid
* @notice 
****************************************************************************************************/
abstract contract MarketOffer is MarketCore, ReentrancyGuardUpgradeable, SendValueWithFallbackWithdraw, MarketFees {
  using AddressUpgradeable for address;

  /// @notice Stores offer details for a specific NFT.
  struct Offer {
    address payable seller; // Seller's address
    uint256 endTime;        // The expiration timestamp of when this FixedPrice expires.
    uint256 amount;         // The amount, in wei, of the highest offer.
    address payable buyer;  // The address of the collector who made this offer.
    uint16 marketFee;       // Market fee in points
  }

  /// @notice Stores the highest offer for each NFT.
  mapping(address => mapping(uint256 => Offer)) private nftContractToTokenIdToOffer;

/***************************************************************************************************
* @notice Emitted when an offer is accepted,
* indicating that the NFT has been transferred and revenue from the sale distributed.
* @dev The accepted total offer amount is `mssFee` + `creatorFee` + `ownerRev`.
* @param nftContract The address of the NFT contract.
* @param tokenId The id of the NFT.
* @param buyer The address of the collector that made the offer which was accepted.
* @param seller The address of the seller which accepted the offer.
* @param value The value of the NFT.
* @param mssFee The amount of ETH that was sent to market for this sale.
* @param creatorFee The amount of ETH that was sent to the creator for this sale.
* @param ownerRev The amount of ETH that was sent to the owner for this sale.
****************************************************************************************************/
  event OfferAccepted(address indexed nftContract, uint256 indexed tokenId, address seller, address buyer, uint256 value, uint256 mssFee, uint256 creatorFee, uint256 ownerRev);
/***************************************************************************************************
* @notice Emitted when an offer is made.
* @param nftContract The address of the NFT contract.
* @param tokenId The id of the NFT.
* @param buyer The address of the collector that made the offer to buy this NFT.
* @param amount The amount, in wei, of the offer.
* @param originalBuyer The address of the original buyer of the NFT.
* @param originalAmount The amount, in wei, of the original offer.
****************************************************************************************************/
  event OfferMade(address indexed nftContract, uint256 indexed tokenId, address buyer, uint256 amount, address originalBuyer, uint256 originalAmount);
/***************************************************************************************************
* @notice Refunds the buyer if the offer is not accepted.
* @param nftContract The address of the NFT contract.
* @param tokenId The id of the NFT.
* @param buyer The address of the collector that made the offer which was not accepted.
* @param amount The amount of the NFT.
****************************************************************************************************/
  event OfferRefunded(address indexed nftContract, uint256 indexed tokenId, address buyer, uint256 amount);
/***************************************************************************************************
* @notice Accept the highest offer for an NFT.
* @dev The offer must not be expired and the NFT owned + approved by the seller or
* available in the market contract's escrow.
* @param nftContract The address of the NFT contract.
* @param tokenId The id of the NFT.
****************************************************************************************************/
  function acceptOffer(address nftContract, uint256 tokenId) external nonReentrant {
    Offer storage offer = nftContractToTokenIdToOffer[nftContract][tokenId];
    require(offer.seller != address(0), "MarketOffer: The offer is not activated");
    // Accept time is the endtime + DURATION_OFFER (24H) of FixedPrice
    require(offer.endTime + DURATION_OFFER >= block.timestamp, "MarketOffer: Offer rxpired");
    require(offer.seller == msg.sender, "MarketOffer: Only those NFT sellers can accept");

    _acceptOffer(nftContract, tokenId, offer.buyer, offer.amount);
  }

/***************************************************************************************************
* @notice Returns details about the current highest offer for an NFT.
* @dev Default values are returned if there is no offer or the offer has expired.
* @param nftContract The address of the NFT contract.
* @param tokenId The id of the NFT.
* @return buyer The address of the buyer that made the current highest offer.
* Returns `address(0)` if there is no offer or the most recent offer has expired.
* @return endTime The timestamp that the current highest offer expires.
* Returns `0` if there is no offer or the most recent offer has expired.
* @return amount The amount being offered for this NFT.
* Returns `0` if there is no offer or the most recent offer has expired.
****************************************************************************************************/
  function getOfferData(address nftContract, uint256 tokenId) external view returns (address seller, address buyer, uint256 endTime, uint256 amount) {
    Offer storage offer = nftContractToTokenIdToOffer[nftContract][tokenId];
    if (offer.endTime + DURATION_OFFER < block.timestamp) {
      // Offer not found or has expired
      return (address(0), address(0), 0, 0);
    }

    // An offer was found and it has not yet expired.
    return (offer.seller, offer.buyer, offer.endTime, offer.amount);
  }

/***************************************************************************************************
* @notice Returns the minimum amount a buyer must spend to participate in an offer.
* buyer must be greater than or equal to this value or they will revert.
* @param nftContract The address of the NFT contract.
* @param tokenId The id of the NFT.
* @return minimum The minimum amount for a offfer to be accepted.
****************************************************************************************************/
  function getMinOfferAmount(address nftContract, uint256 tokenId) external view returns (uint256 minimum) {
    Offer storage offer = nftContractToTokenIdToOffer[nftContract][tokenId];
    if (offer.buyer == address(0)) {
      return offer.amount;
    }
    return _getMinIncrement(offer.amount);
  }

/***************************************************************************************************
* @notice Accept the highest offer for an NFT from the `msg.sender` account.
* The NFT will be transferred to the buyer and revenue from the sale will be distributed.
* @dev The caller must validate the expiry and amount before calling this helper.
* This may invalidate other market tools, such as clearing the buy price if set.
****************************************************************************************************/
  function _acceptOffer(address nftContract, uint256 tokenId, address payable buyer, uint256 amount) internal {
    Offer memory offer = nftContractToTokenIdToOffer[nftContract][tokenId];
    require(offer.seller != address(0), "MarketOffer: The offer is not activated");
    // Remove offer
    delete nftContractToTokenIdToOffer[nftContract][tokenId];

    _transferFromMarket(nftContract, tokenId, buyer);
    (uint256 mssFee, uint256 creatorFee, uint256 ownerRev) = _distributeFunds(nftContract, tokenId, offer.seller, amount, offer.marketFee);

    emit OfferAccepted(nftContract, tokenId, offer.seller, buyer, amount, mssFee, creatorFee, ownerRev);
  }

/***************************************************************************************************
* @notice Make an offer for any NFT which is valid for 24 hours.
* If there is a buy price set at this price or lower, that will be accepted instead of making an offer.
* @param nftContract The address of the NFT contract.
* @param tokenId The id of the NFT.
****************************************************************************************************/
  function _makeOffer(address nftContract, uint256 tokenId) internal {
    Offer storage offer = nftContractToTokenIdToOffer[nftContract][tokenId];
    require(offer.seller != address(0), "MarketOffer: The offer is not activated");

    uint256 originalAmount = 0;
    address payable originalBuyer = payable(0);

    if (offer.buyer != address(0)) {
      // Check the minimum bidding amount
      require(msg.value >= _getMinIncrement(offer.amount), "MarketOffer: Less than the minimum proposal price");
      
      originalAmount = offer.amount;
      originalBuyer = offer.buyer;
      offer.amount = msg.value;
      offer.buyer = payable(msg.sender);

      // Refund the previous bidder
      _sendValueWithFallbackWithdraw(nftContract, tokenId, originalBuyer, originalAmount, SEND_VALUE_GAS_LIMIT_SINGLE_RECIPIENT);

    } else {
      // Check the minimum bidding amount
      require(msg.value >= offer.amount, "MarketOffer: Less than the minimum proposal price");

      offer.amount = msg.value;
      offer.buyer = payable(msg.sender);
    }

    emit OfferMade(nftContract, tokenId, msg.sender, msg.value, originalBuyer, originalAmount);
  }

/***************************************************************************************************
* @notice Allows market to cancel offers.
* and prevent the offer from being accepted.
* @dev This should only be used for extreme cases such as DMCA takedown requests.
* @param nftContracts The addresses of the NFT contracts to cancel. This must be the same length as `tokenIds`.
* @param tokenIds The ids of the NFTs to cancel. This must be the same length as `nftContracts`.
****************************************************************************************************/
  function _cancelOffer(address nftContract, uint256 tokenId) internal returns (bool){ /* nonReentrant */
    Offer memory offer = nftContractToTokenIdToOffer[nftContract][tokenId];
    delete nftContractToTokenIdToOffer[nftContract][tokenId];

    if (offer.buyer != address(0)) {
      require(offer.endTime + DURATION_OFFER < block.timestamp, "MarketOffer: The offer has not ended");

      _sendValueWithFallbackWithdraw(nftContract, tokenId, offer.buyer, offer.amount, SEND_VALUE_GAS_LIMIT_SINGLE_RECIPIENT);
      
      emit OfferRefunded(nftContract, tokenId, offer.buyer, offer.amount);
      
      return true;
    }
    return false;
  }

/***************************************************************************************************
* @notice Offer registration.Only registered offers can make the makeOffer
* @dev You must register together when registering FixedPrice.
* @param nftContract The address of the NFT contract.
* @param tokenId The id of the NFT.
* @param expiration The expiration timestamp for the offer.
****************************************************************************************************/
  function _createOffer(address nftContract, uint256 tokenId, address seller, uint256 amount, uint256 fixedPriceEndTime) internal {
    uint256 OfferEndTime = fixedPriceEndTime;
    nftContractToTokenIdToOffer[nftContract][tokenId] = Offer(payable(seller), OfferEndTime, amount, payable(0), marketFee);
  }

/***************************************************************************************************
* @inheritdoc MarketCore
* @dev Invalidates the highest offer if it's from the same user that purchased the NFT
* using a different market tool such as accepting the buy price.
****************************************************************************************************/
  function _transferFromMarket(address nftContract, uint256 tokenId, address recipient) internal virtual override {
    Offer memory offer = nftContractToTokenIdToOffer[nftContract][tokenId];
    if (offer.buyer != address(0)) {
      delete nftContractToTokenIdToOffer[nftContract][tokenId];

      _sendValueWithFallbackWithdraw(nftContract, tokenId, offer.buyer, offer.amount, SEND_VALUE_GAS_LIMIT_SINGLE_RECIPIENT);
    }
    // For other users, the offer remains valid for consideration by the new owner.
    super._transferFromMarket(nftContract, tokenId, recipient);
  }

/***************************************************************************************************
* @notice This empty reserved space is put in place to allow future versions to add new
* variables without shifting down storage in the inheritance chain.
* See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
****************************************************************************************************/
  uint256[100] private __gap;
}

/*

                                                                                             ,,,

   ██████      ,██████                                                                    ▄███████
   ███████    ╔███████                                                                   ⌠█████████
   ████████▄ █████████    ,▄███████▄     ,▄████████▄   ,▄█████████µ   ▐████▌    ▄██████   ,▄██j████
   ███████████████████  ,█████████████  ╒█████▀▀████    ▀███▀▀██████  ▐████▌  ▄████████  ┌████j████
   ████▌ ██████▀ █████  █████     █████ ╟██████▄╖,        ,,,, ╟████b  ,,,,  ▐████▌
   ████▌  ╙███   █████  ████▌     ╟████  ╙▀█████████▄  ▄████████████b ▐████▌ ╟████▄
   ████▌    ▀    █████  █████▄,,,▄████▌  ╓█╓   ╙█████ ▐████    ╞████b ▐████▌  ██████▄▄███╖
   ████▌         █████   ╙███████████▀  ████████████▀  █████████████b ▐████▌   ▀█████████▀
   ▀▀▀▀¬         ▀▀▀▀▀      ╙▀▀▀▀▀╙       `▀▀▀▀▀▀▀      ╙▀▀▀▀▀ └▀▀▀▀  '▀▀▀▀       ╙▀▀▀▀

*/

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "./2ndMarket/FixedPrice.sol";
import "./2ndMarket/Offer.sol";
import "./2ndMarket/MarketCore.sol";

import "./Utils/AdminTreasury.sol";
import "./Utils/Constants.sol";
import "./Utils/SendValueWithFallbackWithdraw.sol";

/***************************************************************************************************
* @title A 2nd market for MosaicSquare.
* @notice Notice 테스트 한글 123
* @dev 주석 주석
****************************************************************************************************/
contract MosaicSquare2ndMarket is Constants, Initializable, AdminTreasury, MarketCore, ReentrancyGuardUpgradeable, SendValueWithFallbackWithdraw, MarketFixedPrice, MarketOffer {

  mapping(address => mapping(uint256 => uint256)) private nftContractToTokenIdToAmount; /// @notice Offer Refund penalty

/***************************************************************************************************
* @notice Proposal amount increase value change event
* @param adminAddress Administrator address requested to change
* @param orginalMinIncrement Original minimal increase value
* @param newMinIncrement New minimal increase value
****************************************************************************************************/
  event UpdateMinIncrement(address indexed adminAddress, uint256 orginalMinIncrement, uint256 newMinIncrement);
/***************************************************************************************************
* @notice Market fee change
* @param adminAddress Administrator address requested to change
* @param originalMarketFee Original market fee
* @param newMarketFee New market fee
****************************************************************************************************/
  event UpdateMarketFee(address indexed adminAddress, uint16 originalMarketFee, uint16 newMarketFee);
/***************************************************************************************************
* @notice Duration add
* @param adminAddress Administrator address requested to change
* @param addDuration Add duration
****************************************************************************************************/
  event AddDuration(address indexed adminAddress, uint256 addDuration);
/***************************************************************************************************
* @notice Duration remove
* @param adminAddress Administrator address requested to change
* @param removeDuration Remove duration
****************************************************************************************************/
  event RemoveDuration(address indexed adminAddress, uint256 removeDuration);
/***************************************************************************************************
* @title Set initialization when creating contracts
****************************************************************************************************/
  constructor() {}

/***************************************************************************************************
* @notice Called once to configure the contract after the initial proxy deployment.
* @dev This farms the initialize call out to inherited contracts as needed to initialize mutable variables.
****************************************************************************************************/
  function initialize(address _contractAdmin, address payable _treasury) external initializer {
    _initializeAdminTreasury(_contractAdmin, _treasury);
    _initializeMarketCore();
  }

/***************************************************************************************************
* @inheritdoc MarketCore
* @dev This is a no-op function required to avoid compile errors.
****************************************************************************************************/
  function _transferFromMarket(address nftContract, uint256 tokenId, address recipient) internal override(MarketCore, MarketFixedPrice, MarketOffer) {
    super._transferFromMarket(nftContract, tokenId, recipient);
  }

/***************************************************************************************************
* @inheritdoc MarketCore
* @dev This is a no-op function required to avoid compile errors.
****************************************************************************************************/
  function _transferToMarket(address nftContract, uint256 tokenId) internal override(MarketCore, MarketFixedPrice) {
    super._transferToMarket(nftContract, tokenId);
  }

/***************************************************************************************************
* @notice Withdrawal to all those who will be withdrawn
****************************************************************************************************/
  function withdrawAll() external {
    _withdrawAll(SEND_VALUE_GAS_LIMIT_SINGLE_RECIPIENT);
  }

/***************************************************************************************************
* @notice Market registration
* @param nftContract NFT contract address
* @param tokenId NFT token id
* @param price Price of the NFT
* @param duration Duration of the NFT
* @param offerPrice Price of the offer
****************************************************************************************************/
  function createFixedPrice(address nftContract, uint256 tokenId, uint256 price, uint256 duration, uint256 offerPrice) public nonReentrant {
    require(_checkDurationSettingPeriod(duration), "MarketFixedPrice: The period setting is wrong");
    
    uint256 endTime = 0;
    endTime = block.timestamp + duration;

    _createFixedPrice(nftContract, tokenId, price, duration, endTime, offerPrice);

    if (offerPrice > 0) {
      require(price > offerPrice, "MarketFixedPrice: The offer start price should be lower than the Fixed Price price");

      _createOffer(nftContract, tokenId, msg.sender, offerPrice, endTime);
    }
  }

/***************************************************************************************************
* @notice Offer
* @param nftContract NFT contract address
* @param tokenId NFT token id
****************************************************************************************************/
  function makeOffer(address nftContract, uint256 tokenId) public payable nonReentrant {
    (address FixedPriceSeller, uint256 FixedPricePrice, uint256 FixedPriceEndTime) = getFixedPrice(nftContract, tokenId);

    require(FixedPriceSeller != address(0), "MarketFixedPrice: The FixedPrice is not registered");
    require(FixedPriceEndTime >= block.timestamp, "MarketOffer: Offer Expired");
    require(FixedPriceSeller != msg.sender, "MarketOffer: Cannot make an offer on your own NFT");

    if (FixedPricePrice > msg.value) {
      _makeOffer(nftContract, tokenId);
    } else {
      _acceptOffer(nftContract, tokenId, payable(msg.sender), msg.value);
    }
  }

/***************************************************************************************************
* @notice Delete registered FixedPrice and offer.
* @param nftContract NFT contract address
* @param tokenId NFT token id
****************************************************************************************************/
  function closeFixedPrice(address nftContract, uint256 tokenId) external payable nonReentrant {
    uint256 closeAmount = nftContractToTokenIdToAmount[nftContract][tokenId];
    require(closeAmount <= msg.value, "MarketFixedPrice: Lack of money");

    if (closeAmount > 0) {
      _cancelFixedPrice(nftContract, tokenId);
      delete nftContractToTokenIdToAmount[nftContract][tokenId];

      _sendValueWithFallbackWithdraw(nftContract, tokenId, treasury, msg.value, SEND_VALUE_GAS_LIMIT_SINGLE_RECIPIENT);
    } else {
      _cancelOffer(nftContract, tokenId);
      _cancelFixedPrice(nftContract, tokenId);
    }
  }

/***************************************************************************************************
* @notice Refund the buyer of an offer.
* @param nftContract The address of the NFT contract.
* @param tokenId The id of the NFT.
****************************************************************************************************/
  function refundOffer(address nftContract, uint256 tokenId) external nonReentrant {
    if (_cancelOffer(nftContract, tokenId)) {
      nftContractToTokenIdToAmount[nftContract][tokenId] = _getMinIncrement(0);
    }
  }

/***************************************************************************************************
* @notice Set minimal increase value
* @param _newMinIncrement New minimal increase value
****************************************************************************************************/
  function updateMinIncrement(uint256 _newMinIncrement) external onlyAdmin {
    uint256 orginalMinIncrement = _getMinIncrement(0);
    _updateMinIncrement(_newMinIncrement);

    emit UpdateMinIncrement(msg.sender, orginalMinIncrement, _newMinIncrement);
  }

/***************************************************************************************************
* @notice Market fee setting
* @param _newMarketFee New market fee
****************************************************************************************************/
  function updateMarketFee(uint16 _newMarketFee) external onlyAdmin {
    uint16 originalMarketFee = marketFee;
    _updateMarketFee(_newMarketFee);

    emit UpdateMarketFee(msg.sender, originalMarketFee, _newMarketFee);
  }

/***************************************************************************************************
* @notice Duration setting period update
* @param _addDuration Add duration
****************************************************************************************************/
  function addDuration(uint256 _addDuration) external onlyAdmin {
    _addDurationSettingPeriod(_addDuration);
    
    emit AddDuration(msg.sender, _addDuration);
  }

/***************************************************************************************************
* @notice Duration setting period remove
* @param _removeDuration Remove duration
****************************************************************************************************/
  function removeDuration(uint256 _removeDuration) external onlyAdmin {
    _removeDurationSettingPeriod(_removeDuration);
    
    emit RemoveDuration(msg.sender, _removeDuration);
  }
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "./MarketCore.sol";
import "./MarketFees.sol";

import "../Utils/SupportsInterfaces.sol";

/***************************************************************************************************
* @title Allows sellers to set a buy price of their NFTs that may be accepted and instantly transferred to the buyer.
* @notice NFTs with a buy price set are escrowed in the market contract.
****************************************************************************************************/
abstract contract MarketFixedPrice is MarketCore, SupportsInterfaces, MarketFees {
  using AddressUpgradeable for address payable;
/***************************************************************************************************
* @notice Stores the buy price details for a specific NFT.
* @dev The struct is packed into a single slot to optimize gas.
****************************************************************************************************/
  struct FixedPrice {
    address payable seller; // The current owner of this NFT which set a buy price. A zero price is acceptable so a non-zero address determines whether a price has been set.
    uint256 price;          // The current buy price set for this NFT.
    uint256 endTime;        // The time when the buy price will expire.
    uint16 marketFee;       // Market fee in points.
  }

  mapping(address => mapping(uint256 => FixedPrice)) private nftContractToTokenIdToFixedPrice; // Stores the current buy price for each NFT.

/***************************************************************************************************
* @notice Emitted when an NFT is bought by accepting the buy price,
* indicating that the NFT has been transferred and revenue from the sale distributed.
* @dev The total buy price that was accepted is `mssFee` + `creatorFee` + `ownerRev`.
* @param nftContract The address of the NFT contract.
* @param tokenId The id of the NFT.
* @param buyer The address of the collector that purchased the NFT using `buy`.
* @param seller The address of the seller which originally set the buy price.
* @param value The value of the NFT.
* @param mssFee The amount of ETH that was sent to market for this sale.
* @param creatorFee The amount of ETH that was sent to the creator for this sale.
* @param ownerRev The amount of ETH that was sent to the owner for this sale.
****************************************************************************************************/
  event FixedPriceSold(address indexed nftContract, uint256 indexed tokenId, address seller, address buyer, uint256 value, uint256 mssFee, uint256 creatorFee, uint256 ownerRev);
/***************************************************************************************************
* @notice Emitted when the buy price is removed by the owner of an NFT.
* @dev The NFT is transferred back to the owner unless it's still escrowed for another market tool,
* e.g. listed for sale in an auction.
* @param nftContract The address of the NFT contract.
* @param tokenId The id of the NFT.
****************************************************************************************************/
  event FixedPriceCanceled(address indexed nftContract, uint256 indexed tokenId);
/***************************************************************************************************
* @notice Emitted when a buy price is set by the owner of an NFT.
* @dev The NFT is transferred into the market contract for escrow unless it was already escrowed,
* e.g. for auction listing.
* @param nftContract The address of the NFT contract.
* @param tokenId The id of the NFT.
* @param seller The address of the NFT owner which set the buy price.
* @param price The price of the NFT.
* @param duration The duration of the buy price.
* @param endTime The time when the buy price will expire.
* @param offerPrice Offer minimum price
****************************************************************************************************/
  event FixedPriceSet(address indexed nftContract, uint256 indexed tokenId, address seller, uint256 price, uint256 duration, uint256 endTime, uint256 offerPrice);
/***************************************************************************************************
* @notice Buy the NFT at the set buy price.
* `msg.value` must be <= `maxPrice` and any delta will be taken from the account's available FETH balance.
* @dev `maxPrice` protects the buyer in case a the price is increased but allows the transaction to continue
* when the price is reduced (and any surplus funds provided are refunded).
* @param nftContract The address of the NFT contract.
* @param tokenId The id of the NFT.
* @param maxPrice The maximum price to pay for the NFT.
****************************************************************************************************/
  function fixedPriceBuy(address nftContract, uint256 tokenId) external payable {
    FixedPrice storage fixedPrice = nftContractToTokenIdToFixedPrice[nftContract][tokenId];
    
    require(fixedPrice.seller != address(0), "MarketFixedPrice: The FixedPrice is not registered");
    require(fixedPrice.endTime >= block.timestamp, "MarketFixedPrice: Buy price Expired");
    require(fixedPrice.seller != msg.sender, "MarketFixedPrice: Cannot buy own price");
   
    _buy(nftContract, tokenId);
  }

/***************************************************************************************************
* @notice Returns the buy price details for an NFT if one is available.
* @dev If no price is found, seller will be address(0) and price will be max uint256.
* @param nftContract The address of the NFT contract.
* @param tokenId The id of the NFT.
* @return seller The address of the owner that listed a buy price for this NFT.
* Returns `address(0)` if there is no buy price set for this NFT.
* @return price The price of the NFT.
* Returns `0` if there is no buy price set for this NFT.
****************************************************************************************************/
  function getFixedPrice(address nftContract, uint256 tokenId) public view returns (address seller, uint256 price, uint256 endTime) {
    FixedPrice storage fixedPrice = nftContractToTokenIdToFixedPrice[nftContract][tokenId];
    if (fixedPrice.seller == address(0)) {
      return (address(0), type(uint256).max, 0);
    }
    return (fixedPrice.seller, fixedPrice.price, fixedPrice.endTime);
  }

/***************************************************************************************************
* @notice Sets the buy price for an NFT and escrows it in the market contract.
* @dev If there is an offer for this amount or higher, that will be accepted instead of setting a buy price.
* @param nftContract The address of the NFT contract.
* @param tokenId The id of the NFT.
* @param price The price at which someone could buy this NFT.
* @param endTime The time when the buy price will expire.
* @param offerActivate activate the offer.
****************************************************************************************************/
  function _createFixedPrice(address nftContract, uint256 tokenId, uint256 price, uint256 duration, uint256 endTime, uint256 offerPrice) internal {
    require(price > 0, "MarketFixedPrice: Cannot set price of 0");
    
    FixedPrice storage fixedPrice = nftContractToTokenIdToFixedPrice[nftContract][tokenId];
    require(fixedPrice.seller == address(0), "MarketFixedPrice: The NFT is already registered");

    // Store the new price for this NFT.
    fixedPrice.price = price;
    fixedPrice.endTime = endTime;
    fixedPrice.marketFee = marketFee;

    if (!_getInterfacestransferTo2ndMarket(nftContract, tokenId)) {
        _transferToMarket(nftContract, tokenId);
    }
    // The price was not previously set for this NFT, store the seller.
    fixedPrice.seller = payable(msg.sender);

    emit FixedPriceSet(nftContract, tokenId, msg.sender, price, duration, fixedPrice.endTime, offerPrice);
  }

/***************************************************************************************************
* @notice Process the purchase of an NFT at the current buy price.
* @dev The caller must confirm that the seller != address(0) before calling this function.
***************************************************************************************************/
  function _buy(address nftContract, uint256 tokenId) private nonReentrant {
    FixedPrice memory fixedPrice = nftContractToTokenIdToFixedPrice[nftContract][tokenId];
    require(fixedPrice.price <= msg.value, "MarketFixedPrice: Not enough ETH to buy this NFT");
    // Remove the buy now
    delete nftContractToTokenIdToFixedPrice[nftContract][tokenId];

    // Transfer the NFT to the buyer.
    // This should revert if the `msg.sender` is not the owner of this NFT.
    _transferFromMarket(nftContract, tokenId, msg.sender);

    // Distribute revenue for this sale.
    (uint256 mssFee, uint256 creatorFee, uint256 ownerRev) = _distributeFunds(nftContract, tokenId, fixedPrice.seller, msg.value, fixedPrice.marketFee);

    emit FixedPriceSold(nftContract, tokenId, fixedPrice.seller, msg.sender, msg.value, mssFee, creatorFee, ownerRev);
  }

/***************************************************************************************************
* @notice Removes the buy price set for an NFT.
* @dev The NFT is transferred back to the owner unless it's still escrowed for another market tool,
* e.g. listed for sale in an auction.
* @param nftContract The address of the NFT contract.
* @param tokenId The id of the NFT.
****************************************************************************************************/
  function _cancelFixedPrice(address nftContract, uint256 tokenId) internal { /* nonReentrant */
    FixedPrice memory fixedPrice = nftContractToTokenIdToFixedPrice[nftContract][tokenId];

    require(fixedPrice.seller != address(0), "MarketFixedPrice: Cannot cancel unset price"); // This check is redundant with the next one, but done in order to provide a more clear error message.
    require(fixedPrice.seller == msg.sender, "MarketFixedPrice: Only owner can cancel price");

    // Remove the buy price
    delete nftContractToTokenIdToFixedPrice[nftContract][tokenId];

    // Transfer the NFT back to the owner if it is not listed in auction.
    _transferFromMarket(nftContract, tokenId, msg.sender);
  
    emit FixedPriceCanceled(nftContract, tokenId);
  }

/***************************************************************************************************
* @inheritdoc MarketCore
* @dev Invalidates the buy price if one is found before transferring the NFT.
* This will revert if there is a buy price set but the `msg.sender` is not the owner.
****************************************************************************************************/
  function _transferFromMarket(address nftContract, uint256 tokenId, address recipient) internal virtual override {
    FixedPrice memory fixedPrice = nftContractToTokenIdToFixedPrice[nftContract][tokenId];
    if (fixedPrice.seller != address(0)) {
      // Invalidate the buy price as the NFT will no longer be in escrow.
      delete nftContractToTokenIdToFixedPrice[nftContract][tokenId];
    }
    super._transferFromMarket(nftContract, tokenId, recipient);
  }

/***************************************************************************************************
* @inheritdoc MarketCore
* @dev Checks if the NFT is already in escrow for buy now.
****************************************************************************************************/
  function _transferToMarket(address nftContract, uint256 tokenId) internal virtual override {
    FixedPrice storage fixedPrice = nftContractToTokenIdToFixedPrice[nftContract][tokenId];
    if (fixedPrice.seller == address(0)) {
      // The NFT is not in escrow for buy now.
      super._transferToMarket(nftContract, tokenId);

    } else if (fixedPrice.seller != msg.sender) {
      // When there is a buy price set, the `fixedPrice.seller` is the owner of the NFT.
      revert ("MarketFixedPrice: Seller mismatch");
    }
  }

/***************************************************************************************************
* @notice This empty reserved space is put in place to allow future versions to add new
* variables without shifting down storage in the inheritance chain.
* See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
****************************************************************************************************/
  uint256[100] private __gap;
}

/*

                                                                                             ,,,

   ██████      ,██████                                                                    ▄███████
   ███████    ╔███████                                                                   ⌠█████████
   ████████▄ █████████    ,▄███████▄     ,▄████████▄   ,▄█████████µ   ▐████▌    ▄██████   ,▄██j████
   ███████████████████  ,█████████████  ╒█████▀▀████    ▀███▀▀██████  ▐████▌  ▄████████  ┌████j████
   ████▌ ██████▀ █████  █████     █████ ╟██████▄╖,        ,,,, ╟████b  ,,,,  ▐████▌
   ████▌  ╙███   █████  ████▌     ╟████  ╙▀█████████▄  ▄████████████b ▐████▌ ╟████▄
   ████▌    ▀    █████  █████▄,,,▄████▌  ╓█╓   ╙█████ ▐████    ╞████b ▐████▌  ██████▄▄███╖
   ████▌         █████   ╙███████████▀  ████████████▀  █████████████b ▐████▌   ▀█████████▀
   ▀▀▀▀¬         ▀▀▀▀▀      ╙▀▀▀▀▀╙       `▀▀▀▀▀▀▀      ╙▀▀▀▀▀ └▀▀▀▀  '▀▀▀▀       ╙▀▀▀▀

*/

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./1stMarket/MarketCore.sol";
import "./1stMarket/Auction.sol";
import "./1stMarket/FixedPrice.sol";

import "./Utils/AdminTreasury.sol";
import "./Utils/Constants.sol";
import "./Utils/SendValueWithFallbackWithdraw.sol";

/***************************************************************************************************
* @title A 1st market for MosaicSquare.
* @notice Notice 테스트 한글 123
* @dev 주석 주석 Code size is 26679 bytes
****************************************************************************************************/
contract MosaicSquare1stMarket is Constants, Initializable, AdminTreasury, MarketCore, SendValueWithFallbackWithdraw, MarketAuction, MarketFixedPrice {
/***************************************************************************************************
* @title Set initialization when creating contracts
****************************************************************************************************/
  constructor() {}

/***************************************************************************************************
* @notice Called once to configure the contract after the initial proxy deployment.
* @dev This farms the initialize call out to inherited contracts as needed to initialize mutable variables.
****************************************************************************************************/
  function initialize(address _contractAdmin, address payable _treasury) external initializer {
    _initializeAdminTreasury(_contractAdmin, _treasury);
  }

/***************************************************************************************************
* @inheritdoc MarketCore
* @dev This is a no-op function required to avoid compile errors.
****************************************************************************************************/
  function _checkRegisteredMarket(address nftContract, uint256 tokenId) internal override(MarketCore, MarketAuction, MarketFixedPrice) {
    super._checkRegisteredMarket(nftContract, tokenId); 
  }

/***************************************************************************************************
* @notice Withdrawal to all those who will be withdrawn
****************************************************************************************************/
  function withdrawAll() external {
    _withdrawAll(SEND_VALUE_GAS_LIMIT_SINGLE_RECIPIENT);
  }

/***************************************************************************************************
* @notice NFT Return
* @param nftContract address of the NFT contract
* @param tokenId NFT token id
* @param seller address of the seller
****************************************************************************************************/
  function returnNFT(address nftContract, uint256 tokenId, address seller) external onlyAdmin {
    _checkRegisteredMarket(nftContract, tokenId); // Check if it is registered in the market
    _transferFromMarket(nftContract, tokenId, seller);
  }
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

import "../Utils/Constants.sol";

/***************************************************************************************************
* @title A place for common modifiers and functions used by various NFTMarket mixins, if any.
* @dev This also leaves a gap which can be used to add a new mixin to the top of the inheritance tree.
****************************************************************************************************/
abstract contract MarketCore is Constants {
  using AddressUpgradeable for address;

/***************************************************************************************************
* @notice Transfers the NFT from escrow unless there is another reason for it to remain in escrow.
****************************************************************************************************/
  function _transferFromMarket(address nftContract, uint256 tokenId, address recipient) internal virtual {
    IERC721Upgradeable(nftContract).transferFrom(address(this), recipient, tokenId);
  }

/***************************************************************************************************
* @notice Check that the NFT is registered in the market
****************************************************************************************************/
  function _checkRegisteredMarket(address nftContract, uint256 tokenId) internal virtual {}

/***************************************************************************************************
* @dev Determines the minimum amount when increasing an existing offer or bid.
****************************************************************************************************/
  function _getMinIncrement(uint256 currentAmount) internal pure returns (uint256) {
    uint256 minIncrement = 0;
    if (currentAmount < 1 ether) {
      minIncrement = currentAmount * MIN_PERCENT_INCREMENT_IN_POINTS;
    } else {
      minIncrement = currentAmount * MAX_PERCENT_INCREMENT_IN_POINTS;
    }
    unchecked {
      minIncrement /= BASIS_POINTS;
      if (minIncrement == 0) {
        // Since minIncrement reduces from the currentAmount, this cannot overflow.
        // The next amount must be at least 1 wei greater than the current.
        return currentAmount + 1;
      }
    }

    return minIncrement + currentAmount;
  }

/***************************************************************************************************
* @notice This empty reserved space is put in place to allow future versions to add new
* variables without shifting down storage in the inheritance chain.
* See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
****************************************************************************************************/
  uint256[100] private __gap;
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0; 

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

import "./MarketCore.sol";
import "./MarketFees.sol";
//import "./ErrorMessage.sol";

import "../Utils/AdminTreasury.sol";
import "../Utils/Constants.sol";
import "../Utils/SendValueWithFallbackWithdraw.sol";
import "../Utils/SupportsInterfaces.sol";

/***************************************************************************************************
* @title A market for MosaicSquare.
* @notice Notice 테스트 한글 123
* @dev 주석 주석
****************************************************************************************************/
abstract contract MarketAuction is Constants, AdminTreasury, MarketCore, ReentrancyGuardUpgradeable, SupportsInterfaces, SendValueWithFallbackWithdraw, MarketFees {
  using AddressUpgradeable for address payable;
  using StringsUpgradeable for uint256;
/***************************************************************************************************
* @notice Stores the auction configuration for a specific NFT.
****************************************************************************************************/
  struct AuctionData {
    address payable seller; // The owner of the NFT which listed it in auction.
    uint256 startTime;      // Save the auction time in the form of Unix Timestamp.
    uint256 duration;       // Auction period setting value after the first beading
    uint256 endTime;        // The time at which this auction will not accept any new bids. This is `0` until the first bid is placed.
    uint16 marketFee;       // Market fee
    address payable bidder; // The current highest bidder in this auction. This is `address(0)` until the first bid is placed.
    uint256 amount;         // The latest price of the NFT in this auction. This is set to the reserve price, and then to the highest bid once the auction has started.
  }

  mapping(address => mapping(uint256 => AuctionData)) private nftContractTokenIdToAuctionData; // The auction configuration for a specific auction id.

/***************************************************************************************************
* @notice Emitted when a bid is placed.
* @param nftContract The address of the NFT
* @param tokenId The id of the NFT.
* @param bidder The address of the bidder.
* @param amount The amount of the bid.
* @param originalBidder The address of the original bidder.
* @param originalAmount The amount of the original bid.
* @param endTime The new end time of the auction (which may have been set or extended by this bid).
****************************************************************************************************/
  event AuctionBidPlaced(address indexed nftContract, uint256 indexed tokenId, address bidder, uint256 amount, address originalBidder, uint256 originalAmount, uint256 endTime);
/***************************************************************************************************
* @notice Emitted when an auction is cancelled.
* @dev This is only possible if the auction has not received any bids.
* @param nftContract The address of the NFT
* @param tokenId The id of the NFT.
* @param reason The reason for the cancellation.
****************************************************************************************************/
  event AuctionCanceled(address indexed nftContract, uint256 indexed tokenId, string reason);
/***************************************************************************************************
* @notice Emitted when an NFT is listed for auction.
* @param seller The address of the seller.
* @param nftContract The address of the NFT
* @param tokenId The id of the NFT.
* @param duration The duration of the auction (always 24-hours).
* @param extensionDuration The duration of the auction extension window (always 15-minutes).
* @param reservePrice The reserve price to kick off the auction.
****************************************************************************************************/
  event AuctionCreated(address indexed nftContract, uint256 indexed tokenId, address seller, uint256 duration, uint256 extensionDuration, uint256 reservePrice);
/***************************************************************************************************
* @notice Emitted when an auction that has already ended is finalized, 
* indicating that the NFT has been transferred and revenue from the sale distributed.
* @dev The amount of the highest bid / final sale price for this auction is `mssFee` + `creatorFee` + `ownerRev`.
* @param nftContract The address of the NFT
* @param tokenId The id of the NFT.
* @param seller The address of the seller.
* @param bidder The address of the highest bidder that won the NFT.
* @param value The value of the NFT.
* @param mssFee The amount of ETH that was sent to market for this sale.
* @param creatorFee The amount of ETH that was sent to the creator for this sale.
****************************************************************************************************/
  event AuctionFinalized(address indexed nftContract, uint256 indexed tokenId, address seller, address bidder, uint256 value, uint256 mssFee, uint256 creatorFee);
/***************************************************************************************************
* @notice Allows market to cancel an auction, refunding the bidder
* @param nftContract The address of the NFT contract.
* @param tokenId The id of the NFT.
* @param reason The reason for the cancellation (a required field).
****************************************************************************************************/
  function adminCancelAuction(address nftContract, uint256 tokenId, string calldata reason) external onlyAdmin {
    require(bytes(reason).length != 0, "MarketAuction: Cannot admin cancel without reason");
    
    AuctionData memory auction = nftContractTokenIdToAuctionData[nftContract][tokenId];
    require(auction.seller != address(0), "MarketAuction: Cannot cancel nonexistent auction");
    delete nftContractTokenIdToAuctionData[nftContract][tokenId];

    if (auction.bidder != address(0)) {
      // Refund the highest bidder if any bids were placed in this auction.
      _sendValueWithFallbackWithdraw(nftContract, tokenId, auction.bidder, auction.amount, SEND_VALUE_GAS_LIMIT_SINGLE_RECIPIENT);
    }

    emit AuctionCanceled(nftContract, tokenId, reason);
  }

/***************************************************************************************************  
* @notice Creates an auction for the given NFT.
* @dev Before this operation, the NFT owner must be the market.
* @param nftContract The address of the NFT contract.
* @param tokenId The id of the NFT.
* @param auctionPrice The initial reserve price for the auction.
****************************************************************************************************/
  function createAuction(address nftContract, uint256 tokenId, address seller, uint256 auctionPrice, uint256 startUnixTime, uint256 duration, uint16 marketFee) external onlyAdmin {
    require(auctionPrice >= MIN_START_PRICE, 
      string(abi.encodePacked("MarketAuction: Price must be greater than ", MIN_START_PRICE.toString(), " wei")));
    require(duration >= EXTENSION_DURATION, 
      string(abi.encodePacked("MarketAuction: Duration must be at least ", EXTENSION_DURATION.toString(), " seconds")));
    if (MIN_MARKET_FEE_POINTS > marketFee || marketFee > MAX_MARKET_FEE_POINTS) {
      revert(string(abi.encodePacked("MarketAuction: The market fees are between ",
           uint256(MIN_MARKET_FEE_POINTS).toString(), " to ", uint256(MAX_MARKET_FEE_POINTS).toString())));
    }
    _checkRegisteredMarket(nftContract, tokenId);

    // 이 컨트랙트가 소유자인지 확인하고 소유자가 아니면 에러
    require(address(this) == _getInterfacesOwnerOf(nftContract, tokenId), "MarketAuction: Only NFT contract owner can create auction");

    // 로열티 정보가 없으면 에러
    (address checkRoyaltyInfo,) = _getInterfacesCreatorPaymentInfo(nftContract, tokenId);
    require(checkRoyaltyInfo != address(0), "MarketAuction: Royalty info not found");

    // Store the auction details
    nftContractTokenIdToAuctionData[nftContract][tokenId] = AuctionData(
      payable(seller), startUnixTime, duration, 0, // endTime is only known once the reserve price is met
      marketFee, payable(0), // bidder is only known once a bid has been placed
      auctionPrice
    );

    emit AuctionCreated(nftContract, tokenId, seller, duration, EXTENSION_DURATION, auctionPrice);
  }

/***************************************************************************************************
* @notice Place a bid in an auction.
* A bidder may place a bid which is at least the value defined by `getMinBidAmount`.
* If this is the first bid on the auction, the countdown will begin.
* If there is already an outstanding bid, the previous bidder will be refunded at this time
* and if the bid is placed in the final moments of the auction, the countdown may be extended.
* @param nftContract The address of the NFT contract.
* @param tokenId The id of the NFT.
****************************************************************************************************/
  function placeBid(address nftContract, uint256 tokenId) external payable {
    AuctionData storage auction = nftContractTokenIdToAuctionData[nftContract][tokenId];
    require(auction.startTime <= block.timestamp, "MarketAuction: Cannot bid on an auction that has not been started");
    require(auction.seller != address(0), "MarketAuction: Cannot bid on nonexistent auction");
    require(auction.seller != msg.sender, "MarketAuction: Cannot bid on your own auction");

    uint256 originalAmount = 0;
    address payable originalBidder = payable(0);

    if (auction.endTime == 0) {
      // This is the first bid, kicking off the auction.
      require(msg.value >= auction.amount, "MarketAuction: Cannot bid lower than reserve price");

      // Store the bid details.
      auction.amount = msg.value;
      auction.bidder = payable(msg.sender);

      unchecked {
        auction.endTime =  block.timestamp + auction.duration;
      }
    } else {
      require(block.timestamp <= auction.endTime, "MarketAuction: Cannot bid on ended auction");
      require(auction.bidder != msg.sender, "MarketAuction: Cannot rebid over outstanding bid");
      require(msg.value >= _getMinIncrement(auction.amount), "MarketAuction: Bid must be at least min amount");
        
      // Cache and update bidder state
      originalAmount = auction.amount;
      originalBidder = auction.bidder;
      auction.amount = msg.value;
      auction.bidder = payable(msg.sender);

      unchecked {
        // When a bid outbids another, check to see if a time extension should apply.
        // We confirmed that the auction has not ended, so endTime is always >= the current timestamp.
        if (auction.endTime - block.timestamp < EXTENSION_DURATION) {
          // Current time plus extension duration (always 10 mins) cannot overflow.
          auction.endTime = block.timestamp + EXTENSION_DURATION;
        }
      }
      // Refund the previous bidder
      _sendValueWithFallbackWithdraw(nftContract, tokenId, originalBidder, originalAmount, SEND_VALUE_GAS_LIMIT_SINGLE_RECIPIENT);
    }

    emit AuctionBidPlaced(nftContract, tokenId, msg.sender, msg.value, originalBidder, originalAmount, auction.endTime);
  }

/***************************************************************************************************
* @notice Once the countdown has expired for an auction, anyone can settle the auction.
* This will send the NFT to the highest bidder and distribute revenue for this sale.
* @param nftContract The address of the NFT contract.
* @param tokenId The id of the NFT.
****************************************************************************************************/
  function finalizeAuction(address nftContract, uint256 tokenId) external nonReentrant {
    require(nftContractTokenIdToAuctionData[nftContract][tokenId].endTime != 0, "MarketAuction: Cannot finalize already settled auction");
    _finalizeAuction(nftContract, tokenId);
  }

/***************************************************************************************************
* @notice Returns the minimum amount a bidder must spend to participate in an auction.
* Bids must be greater than or equal to this value or they will revert.
* @param nftContract The address of the NFT contract.
* @param tokenId The id of the NFT.
* @return minimum The minimum amount for a bid to be accepted.
****************************************************************************************************/
  function getMinBidAmount(address nftContract, uint256 tokenId) external view returns (uint256 minimum) {
    AuctionData storage auction = nftContractTokenIdToAuctionData[nftContract][tokenId];
    if (auction.endTime == 0) {
      return auction.amount;
    }
    return _getMinIncrement(auction.amount);
  }

/***************************************************************************************************
* @notice Returns the auctionID for a given NFT, or 0 if no auction is found.
* @dev If an auction is canceled, it will not be returned. However the auction may be over and pending finalization.
* @param nftContract The address of the NFT contract.
* @param tokenId The id of the NFT.
* @return auction AuctionData struct for the given NFT.
****************************************************************************************************/
  function getAuctionData(address nftContract, uint256 tokenId) external view returns (AuctionData memory auction) {
    return nftContractTokenIdToAuctionData[nftContract][tokenId];
  }

/***************************************************************************************************
* @notice Settle an auction that has already ended.
* This will send the NFT to the highest bidder and distribute revenue for this sale.
****************************************************************************************************/
  function _finalizeAuction(address nftContract, uint256 tokenId) private {
    AuctionData memory auction = nftContractTokenIdToAuctionData[nftContract][tokenId];
    require(auction.endTime < block.timestamp, "MarketAuction: Cannot finalize auction in progress");
    // Remove the auction.
    delete nftContractTokenIdToAuctionData[nftContract][tokenId];

    _transferFromMarket(nftContract, tokenId, auction.bidder);
    // Distribute revenue for this sale.
    (uint256 mssFee, uint256 creatorFee) = _distributeFunds(nftContract, tokenId, auction.amount, auction.marketFee);

    emit AuctionFinalized(nftContract, tokenId, auction.seller, auction.bidder, auction.amount, mssFee, creatorFee);
  }

/***************************************************************************************************
* @inheritdoc MarketCore
* @dev If it is checked whether it is registered in another sales method, it will be invalidated.
****************************************************************************************************/
  function _checkRegisteredMarket(address nftContract, uint256 tokenId) internal virtual override {
    require(nftContractTokenIdToAuctionData[nftContract][tokenId].seller == address(0), "MarketAuction: Active auction");
    
    super._checkRegisteredMarket(nftContract, tokenId);
  }

/***************************************************************************************************
* @notice This empty reserved space is put in place to allow future versions to add new
* variables without shifting down storage in the inheritance chain.
* See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
****************************************************************************************************/
  uint256[1000] private __gap;
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

import "./MarketCore.sol";
import "./MarketFees.sol";
//import "./ErrorMessage.sol";

import "../Utils/SupportsInterfaces.sol";

/***************************************************************************************************
* @title Allows sellers to set a buy price of their NFTs that may be accepted and instantly transferred to the buyer.
* @notice NFTs with a buy price set are escrowed in the market contract.
****************************************************************************************************/
abstract contract MarketFixedPrice is MarketCore, SupportsInterfaces, MarketFees {
  using AddressUpgradeable for address payable;
  using StringsUpgradeable for uint256;

/***************************************************************************************************
* @notice Stores the buy price details for a specific NFT.
* @dev The struct is packed into a single slot to optimize gas.
****************************************************************************************************/
  struct FixedPrice {
    address payable seller; // The current owner of this NFT which set a buy price. A zero price is acceptable so a non-zero address determines whether a price has been set.
    uint256 startTime;      // BUY Save in the form of unix timestamp.
    uint256 price;          // The current buy price set for this NFT.
    uint16 marketFee;       // Market fee
  }

  mapping(address => mapping(uint256 => FixedPrice)) private nftContractToTokenIdToFixedPrice; // Stores the current buy price for each NFT.

/***************************************************************************************************
* @notice Emitted when an NFT is bought by accepting the buy price,
* indicating that the NFT has been transferred and revenue from the sale distributed.
* @dev The total buy price that was accepted is `mssFee` + `creatorFee` + `ownerRev`.
* @param nftContract The address of the NFT contract.
* @param tokenId The id of the NFT.
* @param buyer The address of the collector that purchased the NFT using `buy`.
* @param seller The address of the seller which originally set the buy price.
* @param value The amount of ETH that was transferred to the collector.
* @param mssFee The amount of ETH that was sent to market for this sale.
* @param creatorFee The amount of ETH that was sent to the creator for this sale.
****************************************************************************************************/
  event FixedPriceSold(address indexed nftContract, uint256 indexed tokenId, address seller, address buyer, uint256 value, uint256 mssFee, uint256 creatorFee);
/***************************************************************************************************
* @notice Emitted when the buy price is removed by the owner of an NFT.
* @dev The NFT is transferred back to the owner unless it's still escrowed for another market tool,
* e.g. listed for sale in an auction.
* @param nftContract The address of the NFT contract.
* @param tokenId The id of the NFT.
* @param reason The reason for the cancellation.
****************************************************************************************************/
  event FixedPriceCanceled(address indexed nftContract, uint256 indexed tokenId, string reason);
/***************************************************************************************************
* @notice Emitted when a buy price is set by the owner of an NFT.
* @param nftContract The address of the NFT contract.
* @param tokenId The id of the NFT.
* @param seller The address of the NFT owner which set the buy price.
* @param price The price of the NFT.
****************************************************************************************************/
  event FixedPriceSet(address indexed nftContract, uint256 indexed tokenId, address seller, uint256 price);
/***************************************************************************************************
* @notice Buy the NFT at the set buy price.
* when the price is reduced (and any surplus funds provided are refunded).
* @param nftContract The address of the NFT contract.
* @param tokenId The id of the NFT.
****************************************************************************************************/
  function FixedPriceBuy(address nftContract, uint256 tokenId) external payable {
    FixedPrice storage fixedPrice = nftContractToTokenIdToFixedPrice[nftContract][tokenId];
    
    require(fixedPrice.startTime <= block.timestamp, "MarketFixedPrice: startTime is not yet reached");
    require(fixedPrice.seller != address(0), "MarketFixedPrice: Cannot buy unset price");
    require(fixedPrice.seller != msg.sender, "MarketFixedPrice: Cannot buy own FixedPrice");
   
    _buy(nftContract, tokenId);
  }

/***************************************************************************************************
* @notice Removes the buy price set for an NFT.
* @param nftContract The address of the NFT contract.
* @param tokenId The id of the NFT.
****************************************************************************************************/
  function adminCancelFixedPrice(address nftContract, uint256 tokenId, string calldata reason) external onlyAdmin {
    require(bytes(reason).length != 0, "MarketFixedPrice: Cannot admin cancel without reason");

    FixedPrice memory fixedPrice = nftContractToTokenIdToFixedPrice[nftContract][tokenId];
    require(fixedPrice.seller != address(0), "MarketFixedPrice: Cannot cancel unset price"); // This check is redundant with the next one, but done in order to provide a more clear error message.
    // Remove the buy price
    delete nftContractToTokenIdToFixedPrice[nftContract][tokenId];
  
    emit FixedPriceCanceled(nftContract, tokenId, reason);
  }

/***************************************************************************************************
* @notice Sets the buy price for an NFT.
* @param nftContract The address of the NFT contract.
* @param tokenId The id of the NFT.
* @param price The price at which someone could buy this NFT.
****************************************************************************************************/
  function createFixedPrice(address nftContract, uint256 tokenId, address seller, uint256 price, uint256 startUnixTime, uint16 marketFee) external onlyAdmin {
    require(price > 0, "MarketFixedPrice: Cannot set price of 0");
    if (MIN_MARKET_FEE_POINTS > marketFee || marketFee > MAX_MARKET_FEE_POINTS) {
      revert(string(abi.encodePacked("MarketAuction: The market fees are between ",
           uint256(MIN_MARKET_FEE_POINTS).toString(), " to ", uint256(MAX_MARKET_FEE_POINTS).toString())));
    }
    _checkRegisteredMarket(nftContract, tokenId);
    // Check that this contract is the owner, and if you are not the owner, revert
    require(address(this) == _getInterfacesOwnerOf(nftContract, tokenId), "MarketFixedPrice: Only NFT contract owner can create auction");

    // If there is no royalty information, revert
    (address checkRoyaltyInfo,) = _getInterfacesCreatorPaymentInfo(nftContract, tokenId);
    require(checkRoyaltyInfo != address(0), "MarketFixedPrice: Royalty info not found");

    // Store the new price for this NFT.
    nftContractToTokenIdToFixedPrice[nftContract][tokenId] = FixedPrice(payable(seller), startUnixTime, price, marketFee);

    emit FixedPriceSet(nftContract, tokenId, seller, price);
  }

/***************************************************************************************************
* @notice Returns the buy price details for an NFT if one is available.
* @dev If no price is found, seller will be address(0) and price will be max uint256.
* @param nftContract The address of the NFT contract.
* @param tokenId The id of the NFT.
* @returns fixedPrice FixedPrice struct the given NFT.
****************************************************************************************************/
  function getFixedPrice(address nftContract, uint256 tokenId) external view returns (FixedPrice memory fixedPrice) {
    return nftContractToTokenIdToFixedPrice[nftContract][tokenId];
  }

/***************************************************************************************************
* @notice Process the purchase of an NFT at the current buy price.
* @dev The caller must confirm that the seller != address(0) before calling this function.
****************************************************************************************************/
  function _buy(address nftContract, uint256 tokenId) private nonReentrant {
    FixedPrice memory fixedPrice = nftContractToTokenIdToFixedPrice[nftContract][tokenId];
    require(fixedPrice.price <= msg.value, "MarketFixedPrice: Cannot buy at lower price");
    // Remove the buy now price
    delete nftContractToTokenIdToFixedPrice[nftContract][tokenId];
    // Transfer the NFT to the buyer.
    // This should revert if the `msg.sender` is not the owner of this NFT.
    _transferFromMarket(nftContract, tokenId, msg.sender);
    // Distribute revenue for this sale.
    (uint256 mssFee, uint256 creatorFee) = _distributeFunds(nftContract, tokenId, msg.value, fixedPrice.marketFee);

    emit FixedPriceSold(nftContract, tokenId, fixedPrice.seller, msg.sender, msg.value, mssFee, creatorFee);
  }

/***************************************************************************************************
* @inheritdoc MarketCore
* @dev If it is checked whether it is registered in another sales method, it will be invalidated.
****************************************************************************************************/
  function _checkRegisteredMarket(address nftContract, uint256 tokenId) internal virtual override {
    FixedPrice storage fixedPrice = nftContractToTokenIdToFixedPrice[nftContract][tokenId];
    require(fixedPrice.seller == address(0), "MarketFixedPrice: Active buy now");
    
    super._checkRegisteredMarket(nftContract, tokenId);
  }

/***************************************************************************************************
* @notice This empty reserved space is put in place to allow future versions to add new
* variables without shifting down storage in the inheritance chain.
* See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
****************************************************************************************************/
  uint256[100] private __gap;
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./MarketCore.sol";

import "../Utils/AdminTreasury.sol";
import "../Utils/Constants.sol";
import "../Utils/SupportsInterfaces.sol";
import "../Utils/SendValueWithFallbackWithdraw.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

/***************************************************************************************************
* @title A mixin to distribute funds when an NFT is sold.
****************************************************************************************************/
abstract contract MarketFees is Constants, Initializable, AdminTreasury, MarketCore, SupportsInterfaces, SendValueWithFallbackWithdraw {
  using AddressUpgradeable for address payable;
  
/***************************************************************************************************
* @notice Distributes funds to market, creator recipients, and NFT owner after a sale.
****************************************************************************************************/
  function _distributeFunds(address nftContract, uint256 tokenId, uint256 price, uint16 sendMarketFee) internal
    returns (uint256 marketFee, uint256 creatorFee) {
    address payable creatorRecipient;
    (marketFee, creatorRecipient, creatorFee) = _getFees(nftContract, tokenId, price, sendMarketFee);

    _sendValueWithFallbackWithdraw(nftContract, tokenId, treasury, marketFee, SEND_VALUE_GAS_LIMIT_SINGLE_RECIPIENT);

    if (creatorFee > 0 && creatorRecipient != address(0)) {
      _sendValueWithFallbackWithdraw(nftContract, tokenId, creatorRecipient, creatorFee, SEND_VALUE_GAS_LIMIT_MULTIPLE_RECIPIENTS);
    } else {
      revert("MarketFees: No creator fee to distribute");
    }
  }

/***************************************************************************************************
* @dev Calculates how funds should be distributed for the given sale details.
****************************************************************************************************/
  function _getFees(address nftContract, uint256 tokenId, uint256 price, uint16 sendMarketFee) private view
    returns (uint256 marketFee, address payable creatorRecipient, uint256 creatorRev) {
    // Bring the amount to be paid to the seller from the royalty address
    (creatorRecipient,) = _getInterfacesCreatorPaymentInfo(nftContract, tokenId);
    require(creatorRecipient != address(0), "MarketFees: Creator recipient is not set");
    // Calculate the market fee
    marketFee = (price * sendMarketFee) / BASIS_POINTS;
    creatorRev = price - marketFee;
  }

/***************************************************************************************************
   * @notice This empty reserved space is put in place to allow future versions to add new
   * variables without shifting down storage in the inheritance chain.
   * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
****************************************************************************************************/
  uint256[100] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)
// https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts-upgradeable/release-v4.7/contracts/access/AccessControlUpgradeable.sol

pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    function __AccessControl_init() internal onlyInitializing {
    }

    function __AccessControl_init_unchained() internal onlyInitializing {
    }
    struct RoleData {
        EnumerableSetUpgradeable.AddressSet members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 internal constant DEFAULT_ADMIN_ROLE = 0x00;

    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    function hasRole(bytes32 role, address account) internal view returns (bool) {
        return _roles[role].members.contains(account);
    }

    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    function getRoleMemberCount(bytes32 role) internal view returns (uint256) {
        return _roles[role].members.length();
    }

    function getRoleMember(bytes32 role, uint256 index) internal view returns (address) {
        return _roles[role].members.at(index);
    }

    function getRoleAdmin(bytes32 role) internal view returns (bytes32) {
        return _roles[role].adminRole;
    }

    function grantRole(bytes32 role, address account) internal onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    function revokeRole(bytes32 role, address account) internal onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    function _setupRole(bytes32 role, address account) internal {
        _grantRole(role, account);
    }

    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    function _grantRole(bytes32 role, address account) internal {
        if (!hasRole(role, account)) {
            _roles[role].members.add(account);
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) internal {
        if (hasRole(role, account)) {
            _roles[role].members.remove(account);
            emit RoleRevoked(role, account, _msgSender());
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/common/ERC2981.sol)

pragma solidity ^0.8.0;

import "../../interfaces/IERC2981Upgradeable.sol";
import "../../utils/introspection/ERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the NFT Royalty Standard, a standardized way to retrieve royalty payment information.
 *
 * Royalty information can be specified globally for all token ids via {_setDefaultRoyalty}, and/or individually for
 * specific token ids via {_setTokenRoyalty}. The latter takes precedence over the first.
 *
 * Royalty is specified as a fraction of sale price. {_feeDenominator} is overridable but defaults to 10000, meaning the
 * fee is specified in basis points by default.
 *
 * IMPORTANT: ERC-2981 only specifies a way to signal royalty information and does not enforce its payment. See
 * https://eips.ethereum.org/EIPS/eip-2981#optional-royalty-payments[Rationale] in the EIP. Marketplaces are expected to
 * voluntarily pay royalties together with sales, but note that this standard is not yet widely supported.
 *
 * _Available since v4.5._
 */
abstract contract ERC2981Upgradeable is Initializable, IERC2981Upgradeable, ERC165Upgradeable {
    function __ERC2981_init() internal onlyInitializing {
    }

    function __ERC2981_init_unchained() internal onlyInitializing {
    }
    struct RoyaltyInfo {
        address receiver;
        uint96 royaltyFraction;
    }

    RoyaltyInfo private _defaultRoyaltyInfo;
    mapping(uint256 => RoyaltyInfo) private _tokenRoyaltyInfo;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165Upgradeable, ERC165Upgradeable) returns (bool) {
        return interfaceId == type(IERC2981Upgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @inheritdoc IERC2981Upgradeable
     */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) public view virtual override returns (address, uint256) {
        RoyaltyInfo memory royalty = _tokenRoyaltyInfo[_tokenId];

        if (royalty.receiver == address(0)) {
            royalty = _defaultRoyaltyInfo;
        }

        uint256 royaltyAmount = (_salePrice * royalty.royaltyFraction) / _feeDenominator();

        return (royalty.receiver, royaltyAmount);
    }

    /**
     * @dev The denominator with which to interpret the fee set in {_setTokenRoyalty} and {_setDefaultRoyalty} as a
     * fraction of the sale price. Defaults to 10000 so fees are expressed in basis points, but may be customized by an
     * override.
     */
    function _feeDenominator() internal pure virtual returns (uint96) {
        return 10000;
    }

    /**
     * @dev Sets the royalty information that all ids in this contract will default to.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setDefaultRoyalty(address receiver, uint96 feeNumerator) internal virtual {
        require(feeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: invalid receiver");

        _defaultRoyaltyInfo = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Removes default royalty information.
     */
    function _deleteDefaultRoyalty() internal virtual {
        delete _defaultRoyaltyInfo;
    }

    /**
     * @dev Sets the royalty information for a specific token id, overriding the global default.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) internal virtual {
        require(feeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: Invalid parameters");

        _tokenRoyaltyInfo[tokenId] = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Resets royalty information for the token id back to the global default.
     */
    function _resetTokenRoyalty(uint256 tokenId) internal virtual {
        delete _tokenRoyaltyInfo[tokenId];
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[48] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";

/**
 * @title ERC721Mock
 * This mock just provides a public safeMint, mint, and burn functions for testing purposes
 */
contract OrderERC721RoyaltyMock is Initializable, ERC721Upgradeable, ERC2981Upgradeable {
    function __ERC721Mock_init(string memory name, string memory symbol) internal onlyInitializing {
        __ERC721_init_unchained(name, symbol);
    }

    function __ERC721Mock_init_unchained(string memory, string memory) internal onlyInitializing {}

    function baseURI() public view returns (string memory) {
        return _baseURI();
    }

    function exists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }

    function mint(address to, uint256 tokenId) public {
        _setTokenRoyalty(tokenId,to, 1000);
        _mint(to, tokenId);
    }

    function safeMint(address to, uint256 tokenId) public {
        _setTokenRoyalty(tokenId,to, 1000);
        _safeMint(to, tokenId);
    }

    function safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public {
        _safeMint(to, tokenId, _data);
    }

    function burn(uint256 tokenId) public {
        _burn(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view virtual
        override(ERC721Upgradeable, ERC2981Upgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @title ERC721Mock
 * This mock just provides a public safeMint, mint, and burn functions for testing purposes
 */
contract OrderERC721Mock is Initializable, ERC721Upgradeable {
    function __ERC721Mock_init(string memory name, string memory symbol) internal onlyInitializing {
        __ERC721_init_unchained(name, symbol);
    }

    function __ERC721Mock_init_unchained(string memory, string memory) internal onlyInitializing {}

    function baseURI() public view returns (string memory) {
        return _baseURI();
    }

    function exists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }

    function mint(address to, uint256 tokenId) public {
        _mint(to, tokenId);
    }

    function safeMint(address to, uint256 tokenId) public {
        _safeMint(to, tokenId);
    }

    function safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public {
        _safeMint(to, tokenId, _data);
    }

    function burn(uint256 tokenId) public {
        _burn(tokenId);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

/*
                                                                                             ,,,

   ██████      ,██████                                                                    ▄███████
   ███████    ╔███████                                                                   ⌠█████████
   ████████▄ █████████    ,▄███████▄     ,▄████████▄   ,▄█████████µ   ▐████▌    ▄██████   ,▄██j████
   ███████████████████  ,█████████████  ╒█████▀▀████    ▀███▀▀██████  ▐████▌  ▄████████  ┌████j████
   ████▌ ██████▀ █████  █████     █████ ╟██████▄╖,        ,,,, ╟████b  ,,,,  ▐████▌
   ████▌  ╙███   █████  ████▌     ╟████  ╙▀█████████▄  ▄████████████b ▐████▌ ╟████▄
   ████▌    ▀    █████  █████▄,,,▄████▌  ╓█╓   ╙█████ ▐████    ╞████b ▐████▌  ██████▄▄███╖
   ████▌         █████   ╙███████████▀  ████████████▀  █████████████b ▐████▌   ▀█████████▀
   ▀▀▀▀¬         ▀▀▀▀▀      ╙▀▀▀▀▀╙       `▀▀▀▀▀▀▀      ╙▀▀▀▀▀ └▀▀▀▀  '▀▀▀▀       ╙▀▀▀▀
*/



// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./OZAccessControl.sol";

contract MosaicSquareAdmin is Initializable, AccessControlUpgradeable {
  function _initializeAdminRole(address admin) internal onlyInitializing {
    AccessControlUpgradeable.__AccessControl_init();
    _setupRole(DEFAULT_ADMIN_ROLE, admin);
  }

  function initialize(address admin) external initializer {
    _initializeAdminRole(admin);
  }

  function grantAdmin(address account) external {
    grantRole(DEFAULT_ADMIN_ROLE, account);
  }

  function revokeAdmin(address account) external {
    require(getRoleMemberCount(DEFAULT_ADMIN_ROLE)>1, "At least 1 admin is required");
    revokeRole(DEFAULT_ADMIN_ROLE, account);
  }

  function isAdmin(address account) external view returns (bool) {
    return hasRole(DEFAULT_ADMIN_ROLE, account);
  }


  /**
   * @notice This empty reserved space is put in place to allow future versions to add new
   * variables without shifting down storage in the inheritance chain.
   * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
   */
  uint256[100] private __gap;
}