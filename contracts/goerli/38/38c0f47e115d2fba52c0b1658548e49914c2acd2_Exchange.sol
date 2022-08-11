/**
 *Submitted for verification at Etherscan.io on 2022-08-11
*/

// Sources flattened with hardhat v2.10.1 https://hardhat.org

// File @openzeppelin/contracts-upgradeable/utils/[email protected]

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


// File @openzeppelin/contracts-upgradeable/proxy/utils/[email protected]


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


// File contracts/exchange/lib/Whitelist.sol


pragma solidity 0.8.4;

/// @title For whitelisting addresses
abstract contract Whitelist {
    event MemberAdded(address member);
    event MemberRemoved(address member);

    mapping(address => bool) members;

    function initializeWhitelist(address sender) internal {
        members[sender] = true;
        emit MemberAdded(sender);
    }

    modifier onlyWhitelist() {
        require(isMember(msg.sender), "Only whitelisted.");
        _;
    }

    /// @notice Checks if supplied address is member or not
    /// @param _member Address to be checked
    /// @return Returns boolean
    function isMember(address _member) public view returns (bool) {
        return members[_member];
    }

    /// @notice Adds new address as whitelist member
    /// @param _member Address to be whitelisted
    function addMember(address _member) external onlyWhitelist {
        require(!isMember(_member), "Address is member already.");

        members[_member] = true;
        emit MemberAdded(_member);
    }

    /// @notice Removed existing address from whitelist
    /// @param _member Address to be removed
    function removeMember(address _member) external onlyWhitelist {
        require(isMember(_member), "Not member of whitelist.");

        delete members[_member];
        emit MemberRemoved(_member);
    }
}


// File contracts/exchange/ExchangeAdmin.sol


pragma solidity 0.8.4;

/// @title Contract with only admin methods
contract ExchangeAdmin is Whitelist {
    /// @dev In the form of exchange fee percent * 100
    /// @dev Example: 2.5% should be 250 (In order to support upto two decimal precisions, we multiply actual value by 100)
    uint16 public exchangeFee;
    /// @dev The account which receives fees. Default address is the contract deployer
    address public feeReceiver;

    /// @notice Emitted when the fee receiver is changed
    event FeeReceiverChanged(
        address indexed _prevFeeReceiver,
        address indexed _newFeeReceiver
    );

    /// @notice Emitted when the exchange fee is updated
    event ExchangeFeeUpdated(
        uint256 indexed _prevExchangeFee,
        uint256 indexed _newExchangeFee
    );

    /// @notice Emitted when the ETH in exchange contract is transferred to the fee receivers
    event TransferredEthToReceiver(uint256 _amount);

    /// @notice Initializer for setting up exchange fee and fee receiver
    /// @dev Default fee receiver is the msg.sender
    /// @param _exchangeFee Exchange fee that will be deducted for each transaction
    function __Exchange_Admin_init_unchained(uint16 _exchangeFee) internal {
        exchangeFee = _exchangeFee;
        feeReceiver = msg.sender;
    }

    /// @notice Update fee receiver to new address
    /// @param _newReceiver New fee receiver address
    /// @custom:modifier Only whitelist member can update the fee receiver address
    function changeFeeReceiver(address _newReceiver) external onlyWhitelist {
        require(_newReceiver != address(0), "Fee receiver can not be null");

        address _feeReceiver = feeReceiver;
        feeReceiver = _newReceiver;
        emit FeeReceiverChanged(_feeReceiver, _newReceiver);
    }

    /// @notice Update exchange fee to new fee
    /// @param _newExchangeFee New exchange fee in the form of fee * 100 to support two decimal precisions
    /// @custom:modifier Only whitelist member can update the exchange fee
    function updateExchangeFee(uint16 _newExchangeFee) external onlyWhitelist {
        uint16 _exchangeFee = exchangeFee;
        exchangeFee = _newExchangeFee;
        emit ExchangeFeeUpdated(_exchangeFee, exchangeFee);
    }

    /// @notice Transfer ETH from contract to the fee receiver address
    /// @param _amount Amount of eth that is to be transferred from contract to the fee receiver
    function transferEthToReceiver(uint256 _amount) external {
        require(msg.sender != address(0), "Null address check");
        emit TransferredEthToReceiver(_amount);
        payable(feeReceiver).transfer(_amount);
    }
}


// File contracts/exchange/lib/DataStruct.sol


pragma solidity 0.8.4;

/// @title Data structure for different structs used in the contract
library DataStruct {
    /// @dev Order structure
    /// @param Offerer The order creator i.e. seller or buyer address
    /// @param offeredAsset The asset offered by the offerer. Example ERC721/ERC1155 in case of seller, ERC20/ETH in case of buyer 
    /// @param expectedAsset The asset offered by the offerer. Example ERC20/ETH in case of seller, ERC721/ERC1155 in case of buyer 
    /// @param salt For making the object hash unique. 0 is sent when buyOrderSignature is not provided
    /// @param start The epoch time when the auction should start. 0 for fixed price trade.
    /// @param end The epoch time when the auction should end. 0 for fixed price trade.
    /// @param data Provided in case of ERC1155 transfer.
    struct Order {
        address offerer;
        Asset offeredAsset;
        Asset expectedAsset;
        uint salt;
        uint start;
        uint end;
        bytes data;
    }

    /// @dev Null address for addr and 0 as quantity, tokenId can be sent as per required condition
    /// @param assetType Can be one of the values from TokenType.sol in bytes form
    /// @param addr The address of the contract in case except ETH
    /// @param tokenId The id of the token in case of ERC721 and ERC1155
    /// @param quantity Amount of the token to be transferred. WEI in case of ETH/ERC20.
    struct Asset {
        bytes4 assetType;
        address addr;
        uint tokenId;
        uint quantity;
    }

    /// @dev Used in calculatePayment for returning calculated data in specific format
    /// @param royaltyReceiver The address of the royalty receiver
    /// @param royaltyAmount The amount of the royalty to be received by the royaltyReceiver
    /// @param netAmount The amount to be received by the seller
    /// @param feeAmount The amount to deducted by the exchange for handling the order
    /// @param callTradedMethod The boolean value for determining if the traded method is to be called on the collectibles or not
    struct PaymentDetail {
        address royaltyReceiver;
        uint royaltyAmount;
        uint netAmount;
        uint feeAmount;
        bool callTradedMethod;
    }
}


// File contracts/exchange/lib/KeccakHelper.sol


pragma solidity 0.8.4;

/// @title Helper to hash order, asset and eth hash them
contract KeccakHelper {
    /// @notice Method to eth sign the hash
    /// @param hash The hash value from either object or asset
    /// @return hash Eth signed hashed value
    function ethHash(bytes32 hash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /// @notice Method to hash the order data
    /// @param order Order struct formatted data
    /// @return hash Hashed value of the order
    function hashOrder(DataStruct.Order memory order) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(
                    order.offerer,
                    hashAsset(order.offeredAsset),
                    hashAsset(order.expectedAsset),
                    order.salt,
                    order.start,
                    order.end
                ));
    }

    /// @notice Method to hash the asset data
    /// @param asset Asset struct formatted data
    /// @return hash Hashed value of the asset
    function hashAsset(DataStruct.Asset memory asset) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(
            asset.assetType,
            asset.addr,
            asset.tokenId,
            asset.quantity
        ));
    }
}


// File contracts/exchange/lib/TokenType.sol


pragma solidity 0.8.4;

/// @title types of tokens supported in the exchange contract in bytes format
library TokenType {
    bytes4 constant public ETH = bytes4(keccak256("ETH"));
    bytes4 constant public ERC20 = bytes4(keccak256("ERC20"));
    bytes4 constant public ERC721 = bytes4(keccak256("ERC721"));
    bytes4 constant public ERC1155 = bytes4(keccak256("ERC1155"));
}


// File contracts/exchange/interfaces/IBalance.sol


pragma solidity 0.8.4;

interface IBalance {
    /// @dev Returns the amount of tokens owned by `account`. ERC20 tokens.
    function balanceOf(address account) external view returns (uint256);
    /// @dev Returns the owner of the `tokenId` token. ERC721 tokens.
    function ownerOf(uint256 tokenId) external view returns (address owner);
    /// @dev Returns the amount of tokens of token type `id` owned by `account`. ERC1155 tokens.
    function balanceOf(address account, uint256 id) external view returns (uint256);
}


// File contracts/exchange/interfaces/ITransfer.sol


pragma solidity 0.8.4;

interface ITransfer {
    /// @dev Emitted when token transferred. ERC20, ERC721, ERC1155
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    /// @dev Emitted when ERC1155 token transferred.
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /// @dev Returns tokens allowed by owner to spend by the spender. ERC20 tokens.
    function allowance(address owner, address spender) external view returns (uint256);
    /// @dev Returns if the owner has allowed the operator to transfer their token. ERC721 and ERC1155 tokens.
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /// @dev Transfer ERC20 tokens from one address to another
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    /// @dev Transfer ERC721 tokens from one address to another
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    /// @dev Transfer ERC1155 tokens from one address to another
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

    /// @dev Check whether the contract supports specific interface or not
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}


// File @openzeppelin/contracts-upgradeable/utils/[email protected]


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


// File @openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol[email protected]


// OpenZeppelin Contracts (last updated v4.7.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSAUpgradeable {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", StringsUpgradeable.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}


// File contracts/exchange/lib/Validator.sol


pragma solidity 0.8.4;






/// @title Contract responsbile for validating if the data passed are valid or not
contract Validator is KeccakHelper {

    /// @notice Validates data from all perspectives. Master method that calls other methods.
    /// @param sellOrder Order struct created by seller
    /// @param sellOrderSignature sellOrder signed by seller private key
    /// @param buyOrder Order struct created by buyer
    /// @param buyOrderSignature buyOrder signed by buyer private key
    /// @dev buyOrderSignature can be null in case of fixed order sell since the msg.sender will be present
	function validateFull(
        DataStruct.Order memory sellOrder,
        bytes memory sellOrderSignature,
        DataStruct.Order memory buyOrder,
        bytes memory buyOrderSignature
	) internal view {
		validateTimestamp(sellOrder);
		validateTimestamp(buyOrder);

        checkTokenOwnership(sellOrder.offeredAsset, sellOrder.offerer);
        checkTokenOwnership(buyOrder.offeredAsset, buyOrder.offerer);

        checkApprovals(sellOrder.offeredAsset, sellOrder.offerer);
        checkApprovals(buyOrder.offeredAsset, buyOrder.offerer);

		validateSignature(sellOrder, sellOrderSignature, false);
		validateSignature(buyOrder, buyOrderSignature, true);

        validateAssetType(sellOrder.offeredAsset, sellOrder.expectedAsset);

        validateOrderMatch(sellOrder, buyOrder);
	}

    /// @notice Validate if start and end present, current time should be within the given epoch time frames
	function validateTimestamp(DataStruct.Order memory order) internal view {
        require(order.start == 0 || order.start < block.timestamp, "Order start validation failed");
        require(order.end == 0 || order.end > block.timestamp, "Order end validation failed");
	}

    /// @notice Validate if the balance of the offerer is enough or if the token is owned by the offerer
    /// @param asset Asset data struct
    /// @param trader Offerer address
    function checkTokenOwnership(DataStruct.Asset memory asset, address trader) internal view {
        if (TokenType.ETH == asset.assetType) {
            require(msg.value == asset.quantity, "Not enough token sent");
        } else if (TokenType.ERC20 == asset.assetType) {
            require(IBalance(asset.addr).balanceOf(trader) >= asset.quantity, "Not enough ERC20 tokens");
        } else if (TokenType.ERC721 == asset.assetType) {
            require(IBalance(asset.addr).ownerOf(asset.tokenId) == trader, "Offerer is not token owner");
        } else if (TokenType.ERC1155 == asset.assetType) {
            require(IBalance(asset.addr).balanceOf(trader, asset.tokenId) >= asset.quantity, "Not enough ERC1155 tokens");
        }
    }

    /// @notice Validate if the offerer has approved the exchange the transfer their tokens in enough quantity
    /// @param asset Asset data struct
    /// @param trader Offerer address
    function checkApprovals(DataStruct.Asset memory asset, address trader) internal view {
        if (TokenType.ERC20 == asset.assetType) {
            require(ITransfer(asset.addr).allowance(trader, address(this)) == asset.quantity, "Not enough ERC20 tokens allowed to spend");
        } else if (TokenType.ERC721 == asset.assetType || TokenType.ERC1155 == asset.assetType) {
            require(
                ITransfer(asset.addr).isApprovedForAll(trader, address(this)), "ERC721 tokens not approved");
        } else if (TokenType.ETH != asset.assetType) {
            revert("Asset type not supported");
        }
    }

    /// @notice Check if the recovered signer from the signature is the offerer or not
    /// @param order Order data struct
    /// @param signature Hash signed by offerer private key
    /// @param isBuyOrder Salt 0 check only in case of buy order
    /// @dev If salt is 0 in buy order, the signature will not be checked
	function validateSignature(
        DataStruct.Order memory order,
        bytes memory signature,
        bool isBuyOrder
	) internal view {
        if (order.salt == 0 && isBuyOrder) {
            require(msg.sender == order.offerer, "Sender is not authorized");
        } else {
            bytes32 hashedOrder = hashOrder(order);
            address signer = recoverSigner(hashedOrder, signature);
            require(signer == order.offerer, "Signer is not the offerer");
        }
	}

    /// @notice Validate if the offered asset and expected asset have proper tokens as expected or not.
    /// @dev offeredAsset must have either ERC721 or ERC1155 and expectedAsset must have either ETH or ERC20
    function validateAssetType(DataStruct.Asset memory offeredAsset, DataStruct.Asset memory expectedAsset) internal pure {
        require (TokenType.ERC721 == offeredAsset.assetType || TokenType.ERC1155 == offeredAsset.assetType, "Asset type does not match");
        require (TokenType.ETH == expectedAsset.assetType || TokenType.ERC20 == expectedAsset.assetType, "Asset type does not match");
    }

    /// @notice Check if the offeredAsset and expectedAsset are exactly the same in hashed bytes format or not
    function validateOrderMatch(DataStruct.Order memory sellOrder, DataStruct.Order memory buyOrder) internal pure {
        require(sellOrder.offerer != buyOrder.offerer, "seller can not be buyer");
        
        require(
            hashAsset(sellOrder.offeredAsset) == hashAsset(buyOrder.expectedAsset) &&
            hashAsset(sellOrder.expectedAsset) == hashAsset(buyOrder.offeredAsset)
            , "Orders do not match"
        );
    }

    /// @notice Get original signer from order and signature
    /// @param hashedOrder Order data that has been hashed in the contract
    /// @param signature Order hashed signed passed by the caller
    function recoverSigner(
        bytes32 hashedOrder,
        bytes memory signature
    ) internal pure returns (address) {
        bytes32 ethHashedOrder = ethHash(hashedOrder);
        return ECDSAUpgradeable.recover(ethHashedOrder, signature);
    }
}


// File @openzeppelin/contracts/utils/introspection/[email protected]



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


// File contracts/exchange/interfaces/ITraded.sol



pragma solidity ^0.8.0;

interface ITraded is IERC165 {
    /// @notice Update traded value to true
    event UpdatedTraded(uint256 indexed _tokenId);

    /// @notice For check if the token has been traded before or not
    /// @dev Can be a simple mapping to return false as it would create the same getter
    /// @param _tokenId Id of the token to check if it has been traded before or not
    /// @return bool value
    function isTraded(uint256 _tokenId) external view returns (bool);

    /// @notice To update the value of the token as true. This means token has been traded.
    /// @dev Generally called by the marketplace where the token was traded
    /// @param _tokenId Id of the token which was traded
    function traded(uint256 _tokenId) external;
}


// File @openzeppelin/contracts/interfaces/[email protected]



pragma solidity ^0.8.0;


// File @openzeppelin/contracts/interfaces/[email protected]



pragma solidity ^0.8.0;

/**
 * @dev Interface for the NFT Royalty Standard
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Called with the sale price to determine how much royalty is owed and to whom.
     * @param tokenId - the NFT asset queried for royalty information
     * @param salePrice - the sale price of the NFT asset specified by `tokenId`
     * @return receiver - address of who should be sent the royalty payment
     * @return royaltyAmount - the royalty payment amount for `salePrice`
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}


// File contracts/exchange/lib/TransferManager.sol


pragma solidity 0.8.4;






/// @title Contract to handle all the transfer methods
/// @dev ExchangeAdmin is extended to get the fee amount and fee receiver
contract TransferManager is ExchangeAdmin {

	/// @notice Emitted when orders match successfully and the transfers are complete
	event OrdersMatched(
		address indexed buyer,
		address indexed seller,
		DataStruct.Asset offeredAsset,
		DataStruct.Asset expectedAsset,
		address royaltyReceiver,
		uint royaltyAmount,
		uint feeAmount,
		uint netAmount
	);

	/// @notice Method responsible for transferred tokens
	/// @param offeredAsset Asset to be sold
	/// @param expectedAsset Asset to be recevied in return
	/// @param seller Address of the seller
	/// @param buyer Address of the buyer
	/// @param data For ERC1155 transfer
	/// @dev Updates traded in collectibles
	function manageOrderTransfer(
		DataStruct.Asset memory offeredAsset,
		DataStruct.Asset memory expectedAsset,
		address seller,
		address buyer,
		bytes memory data
	) internal {
		DataStruct.PaymentDetail memory payment = calculatePayment(offeredAsset.addr, offeredAsset.tokenId, expectedAsset.quantity, seller);

        if (payment.callTradedMethod) {
            ITraded(offeredAsset.addr).traded(offeredAsset.tokenId);
        }

        if(TokenType.ERC721 == offeredAsset.assetType) {
        	ITransfer(offeredAsset.addr).safeTransferFrom(
	            seller,
	            buyer,
	            offeredAsset.tokenId
	        );
    	} else if(TokenType.ERC1155 == offeredAsset.assetType) {
        	ITransfer(offeredAsset.addr).safeTransferFrom(
	            seller,
	            buyer,
	            offeredAsset.tokenId,
	            offeredAsset.quantity,
	            data
	        );
    	}

        if(TokenType.ETH == expectedAsset.assetType) {
	        if (payment.royaltyReceiver != address(0)) {
	            payable(payment.royaltyReceiver).transfer(payment.royaltyAmount);
	        }

	        payable(seller).transfer(payment.netAmount);
    	} else if(TokenType.ERC20 == expectedAsset.assetType) {
	        if (payment.royaltyReceiver != address(0)) {
	            require(ITransfer(expectedAsset.addr).transferFrom(buyer, payment.royaltyReceiver, payment.royaltyAmount), 'Not able to send royalty');
	        }

	        require(ITransfer(expectedAsset.addr).transferFrom(buyer, seller, payment.netAmount), 'Failed to transfer amount to seller');
	        require(ITransfer(expectedAsset.addr).transferFrom(buyer, feeReceiver, payment.feeAmount), 'Failed to transfer fee to exchange');
    	}

    	emit OrdersMatched(buyer, seller, offeredAsset, expectedAsset, payment.royaltyReceiver, payment.royaltyAmount, payment.feeAmount, payment.netAmount);
	}

	/// @notice Calculates amount to be received by seller, exchange and creator
	/// @param offeredContract Address of the ERC721 or ERC1155 contract to get royalty
	/// @param offeredTokenId Token id of the ERC721 or ERC1155 token to get royalty
	/// @param seller Address of the seller to check if seller is the creator or not
	/// @dev If first traded value is false, the commisison percent is 40 and seller receives 60
	/// @return Payment struct type from DataStruct which contains amount to be receivable by each address
	function calculatePayment(
		address offeredContract,
		uint offeredTokenId,
		uint expectedQuantity,
		address seller
	)
	internal view
    returns (DataStruct.PaymentDetail memory)
	{
		DataStruct.PaymentDetail memory payment = DataStruct.PaymentDetail(address(0), 0, 0, 0, false);

        // Supports Traded Interface
        if (ITransfer(offeredContract).supportsInterface(0x40d8d24e) &&
        	!ITraded(offeredContract).isTraded(offeredTokenId)) {
	            payment.netAmount = (expectedQuantity * 60) / 100;
	            payment.feeAmount = expectedQuantity - payment.netAmount;

	            payment.callTradedMethod = true;
        } else {
            // Supports Royalty Interface
            if (ITransfer(offeredContract).supportsInterface(0x2a55205a)) {
                (payment.royaltyReceiver, payment.royaltyAmount) = IERC2981(offeredContract)
                    .royaltyInfo(offeredTokenId, expectedQuantity);
                if (payment.royaltyReceiver == seller || payment.royaltyAmount == 0) {
                    payment.royaltyReceiver = address(0);
                    payment.royaltyAmount = 0;
                }
            }

            payment.feeAmount = (expectedQuantity * exchangeFee) / 10000;
            payment.netAmount = expectedQuantity - payment.feeAmount - payment.royaltyAmount;
        }

        require(
            expectedQuantity >= (payment.netAmount + payment.royaltyAmount + payment.feeAmount),
            "Either commission or royalty is too high."
        );

        return payment;
	}
}


// File contracts/exchange/ExchangeCore.sol


pragma solidity 0.8.4;




/// @title Core contract with major exchange logic
contract ExchangeCore is ExchangeAdmin, Validator, TransferManager {
    /// @notice The method responsible for exchanging assets
    /// @param sellOrder Order struct created by seller
    /// @param sellOrderSignature sellOrder signed by seller private key
    /// @param buyOrder Order struct created by buyer
    /// @param buyOrderSignature buyOrder signed by buyer private key
    /// @dev buyOrderSignature can be null in case of fixed order sell since the msg.sender will be present
    function matchOrders(
        DataStruct.Order memory sellOrder,
        bytes memory sellOrderSignature,
        DataStruct.Order memory buyOrder,
        bytes memory buyOrderSignature
    ) external payable {
        validateFull(
            sellOrder,
            sellOrderSignature,
            buyOrder,
            buyOrderSignature
        );

        manageOrderTransfer(
            sellOrder.offeredAsset,
            sellOrder.expectedAsset,
            sellOrder.offerer,
            buyOrder.offerer,
            sellOrder.data
        );
    }
}


// File contracts/exchange/Exchange.sol


pragma solidity 0.8.4;

/// @dev For making the __Exchange_init method initializer


/// @title Trading contract for exchanging combination of ETH or ERC-20 and ERC-721 or ERC-1155
/// @dev All the data are previously off chain except the actual transaction
contract Exchange is Initializable, ExchangeCore {
    /// @notice Initializes whitelist and exchange fee
    /// @dev msg.sender is owner as well as whitelisted member by default
    /// @param _exchangeFee Exchange fee that will be deducted for each transaction
    function __Exchange_init(uint16 _exchangeFee) external initializer {
        initializeWhitelist(msg.sender);
        __Exchange_Admin_init_unchained(_exchangeFee);
    }
}