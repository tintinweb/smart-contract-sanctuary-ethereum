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

import "./interfaces/IFixedPriceCollectionDropInitializer.sol";
import "./interfaces/ICollectionFactory.sol";
import "./interfaces/IProxyCall.sol";
import "./interfaces/IRoles.sol";

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title A factory to create NFT mint drops.
 * @notice Call this factory to create an NFT mint drop managed by a single creator.
 * @dev This creates and initializes an ERC-1165 minimal proxy pointing to the NFT mint drop contract template.
 */
contract FNDCollectionDropFactory is ICollectionFactory {
  using AddressUpgradeable for address;
  using AddressUpgradeable for address payable;
  using Clones for address;
  using Strings for uint256;

  /**
   * @notice The contract address which manages common roles.
   * @dev Used by the collections for a shared operator definition.
   */
  IRoles public rolesContract;

  /**
   * @notice The address of the template all new fixed price drop collections will leverage.
   */
  address public implementationFixedPrice;

  /**
   * @notice The address of the proxy call contract implementation.
   * @dev Used by the collections to safely call another contract with arbitrary call data.
   */
  IProxyCall public proxyCallContract;

  /**
   * @notice The implementation version new fixed price collections will use.
   * @dev This is auto-incremented each time the implementation is changed.
   */
  uint256 public versionFixedPrice;

  /**
   * @notice Emitted when a new fixed price drop collection is created from this factory.
   * @param fixedPriceDropContract The address of the new fixed price drop contract.
   * @param creator The address of the creator which owns the new collection.
   * @param version The implementation version used by the new fixed price drop collection.
   * @param name The name of the collection contract created.
   * @param symbol The symbol of the collection contract created.
   * @param tokenURIPreReveal The default uri used before the reveal.
   * @param revealedBaseURIHash The base uri used for the collection after the drop.
   * @param maxTokenId The max token count for the collection.
   * @param revealDeadlineDuration The duration from the start of the drop to the time it must revealed.
   * @param protocolBeneficiary The address of the protocol that receives royalties.
   * @param protocolFeeInBasisPoints The fee in basis points for the protocol royalty.
   * @param nonce The nonce used by the creator when creating the collection,
   * used to define the address of the collection.
   */
  event FixedPriceCollectionDropCreated(
    address indexed fixedPriceDropContract,
    address indexed creator,
    uint256 indexed version,
    string name,
    string symbol,
    string tokenURIPreReveal,
    bytes32 revealedBaseURIHash,
    uint256 maxTokenId,
    uint256 revealDeadlineDuration,
    address payable protocolBeneficiary,
    uint16 protocolFeeInBasisPoints,
    uint256 nonce
  );
  /**
   * @notice Emitted when the implementation contract used by new collections is updated.
   * @param implementationFixedPrice The new implementation contract address.
   * @param version The version of the new implementation, auto-incremented.
   */
  event ImplementationFixedPriceUpdated(address indexed implementationFixedPrice, uint256 indexed version);
  /**
   * @notice Emitted when the proxy call contract used by collections is updated.
   * @param proxyCallContract The new proxy call contract address.
   */
  event ProxyCallContractUpdated(address indexed proxyCallContract);
  /**
   * @notice Emitted when the contract defining roles is updated.
   * @param rolesContract The new roles contract address.
   */
  event RolesContractUpdated(address indexed rolesContract);

  modifier onlyAdmin() {
    require(rolesContract.isAdmin(msg.sender), "FNDCollectionDropFactory: Caller does not have the Admin role");
    _;
  }

  /**
   * @notice Defines requirements for the collection drop factory at deployment time.
   * @param _proxyCallContract The address of the proxy call contract implementation.
   * @param _rolesContract The address of the contract defining roles for collections to use.
   */
  constructor(address _proxyCallContract, address _rolesContract) {
    _updateRolesContract(_rolesContract);
    _updateProxyCallContract(_proxyCallContract);
  }

  /**
   * @notice Allows Foundation to change the collection implementation used for future collections.
   * This call will auto-increment the version.
   * Existing collections are not impacted.
   * @param _implementation The new collection implementation address.
   */
  function adminUpdateFixedPriceImplementation(address _implementation) external onlyAdmin {
    _updateFixedPriceImplementation(_implementation);
  }

  /**
   * @notice Allows Foundation to change the proxy call contract address.
   * @param _proxyCallContract The new proxy call contract address.
   */
  function adminUpdateProxyCallContract(address _proxyCallContract) external onlyAdmin {
    _updateProxyCallContract(_proxyCallContract);
  }

  /**
   * @notice Allows Foundation to change the admin role contract address.
   * @param _rolesContract The new admin role contract address.
   */
  function adminUpdateRolesContract(address _rolesContract) external onlyAdmin {
    _updateRolesContract(_rolesContract);
  }

  /**
   * @notice Create a new collection contract.
   * @dev The nonce is required and must be unique for the msg.sender + implementation version,
   * otherwise this call will revert.
   * @param name The name for the new collection being created.
   * @param symbol The symbol for the new collection being created.
   * @param tokenURIPreReveal The default uri used before the reveal.
   * @param revealedBaseURIHash The base uri hash used for the collection after the drop.
   * @param maxTokenId The max token count for the collection.
   * @param nonce An arbitrary value used to allow a creator to mint multiple collections.
   * @return fixedPriceCollectionDropAddress The address of the new fixed price drop collection contract.
   */
  function createFixedPriceCollectionDrop(
    string calldata name,
    string calldata symbol,
    string calldata tokenURIPreReveal,
    bytes32 revealedBaseURIHash,
    uint256 maxTokenId,
    uint256 revealDeadlineDuration,
    address payable protocolBeneficiary,
    uint16 protocolFeeInBasisPoints,
    uint256 nonce
  ) external returns (address fixedPriceCollectionDropAddress) {
    require(bytes(symbol).length != 0, "FNDCollectionDropFactory: Symbol is required");

    // This reverts if the NFT was previously created using this implementation version + msg.sender + nonce
    fixedPriceCollectionDropAddress = implementationFixedPrice.cloneDeterministic(_getSalt(msg.sender, nonce));

    IFixedPriceCollectionDropInitializer(fixedPriceCollectionDropAddress).initialize(
      payable(msg.sender),
      name,
      symbol,
      tokenURIPreReveal,
      revealedBaseURIHash,
      maxTokenId,
      revealDeadlineDuration,
      protocolBeneficiary,
      protocolFeeInBasisPoints
    );
    // TODO: Hack to get around stack too-deep err.
    _emitFixedPriceCollectionDropCreated(
      fixedPriceCollectionDropAddress,
      name,
      symbol,
      tokenURIPreReveal,
      revealedBaseURIHash,
      maxTokenId,
      revealDeadlineDuration,
      protocolBeneficiary,
      protocolFeeInBasisPoints,
      nonce
    );
  }

  function _emitFixedPriceCollectionDropCreated(
    address fixedPriceCollectionDropAddress,
    string memory name,
    string memory symbol,
    string memory tokenURIPreReveal,
    bytes32 revealedBaseURIHash,
    uint256 maxTokenId,
    uint256 revealDeadlineDuration,
    address payable protocolBeneficiary,
    uint16 protocolFeeInBasisPoints,
    uint256 nonce
  ) internal {
    emit FixedPriceCollectionDropCreated(
      fixedPriceCollectionDropAddress,
      msg.sender,
      versionFixedPrice,
      name,
      symbol,
      tokenURIPreReveal,
      revealedBaseURIHash,
      maxTokenId,
      revealDeadlineDuration,
      protocolBeneficiary,
      protocolFeeInBasisPoints,
      nonce
    );
  }

  function _updateRolesContract(address _rolesContract) private {
    require(_rolesContract.isContract(), "FNDCollectionDropFactory: RolesContract is not a contract");
    rolesContract = IRoles(_rolesContract);

    emit RolesContractUpdated(_rolesContract);
  }

  /**
   * @dev Updates the implementation address, increments the version, and initializes the template.
   * Since the template is initialized when set, implementations cannot be re-used.
   * To downgrade the implementation, deploy the same bytecode again and then update to that.
   */
  function _updateFixedPriceImplementation(address _implementation) private {
    require(_implementation.isContract(), "FNDCollectionDropFactory: Implementation is not a contract");
    implementationFixedPrice = _implementation;
    unchecked {
      // Version cannot overflow 256 bits.
      versionFixedPrice++;
    }

    // The implementation is initialized when assigned so that others may not claim it as their own.
    IFixedPriceCollectionDropInitializer(_implementation).initialize(
      payable(address(rolesContract)),
      string(abi.encodePacked("Foundation Fixed Price Collection Template v", versionFixedPrice.toString())),
      string(abi.encodePacked("FCTv", versionFixedPrice.toString())),
      string(abi.encodePacked("tokenURIPreveal v", versionFixedPrice.toString())),
      keccak256(abi.encodePacked("revealedBaseURIHash v", versionFixedPrice.toString())),
      0,
      0,
      payable(address(this)),
      0
    );

    emit ImplementationFixedPriceUpdated(_implementation, versionFixedPrice);
  }

  function _updateProxyCallContract(address _proxyCallContract) private {
    require(_proxyCallContract.isContract(), "FNDCollectionDropFactory: Proxy call address is not a contract");
    proxyCallContract = IProxyCall(_proxyCallContract);

    emit ProxyCallContractUpdated(_proxyCallContract);
  }

  /**
   * @notice Returns the address of a fixed price drop collection given the current
   * implementation version, creator, and nonce.
   * This will return the same address whether the collection has already been created or not.
   * @param creator The creator of the collection.
   * @param nonce An arbitrary value used to allow a creator to mint multiple collections.
   * @return fixedPriceCollectionAddress The address of the fixed price collection contract
   * that would be created by this nonce.
   */
  function predictFixedPriceCollectionAddress(address creator, uint256 nonce)
    external
    view
    returns (address fixedPriceCollectionAddress)
  {
    fixedPriceCollectionAddress = implementationFixedPrice.predictDeterministicAddress(_getSalt(creator, nonce));
  }

  function _getSalt(address creator, uint256 nonce) private pure returns (bytes32) {
    return keccak256(abi.encodePacked(creator, nonce));
  }
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

interface IFixedPriceCollectionDropInitializer {
  function initialize(
    address payable _creator,
    string memory _name,
    string memory _symbol,
    string memory _tokenURIPreReveal,
    bytes32 _revealedBaseURIHash,
    uint256 _maxTokenId,
    uint256 _revealDeadlineDuration,
    address payable _protocolBeneficiary,
    uint16 _protocolFeeInBasisPoints
  ) external;
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

import "./IRoles.sol";
import "./IProxyCall.sol";

interface ICollectionFactory {
  function rolesContract() external returns (IRoles);

  function proxyCallContract() external returns (IProxyCall);
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

interface IProxyCall {
  function proxyCallAndReturnAddress(address externalContract, bytes memory callData)
    external
    returns (address payable result);
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
// OpenZeppelin Contracts v4.4.1 (proxy/Clones.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
}