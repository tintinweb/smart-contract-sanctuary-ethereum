// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/drafts/EIP712Upgradeable.sol';
import '@openzeppelin/contracts/cryptography/ECDSA.sol';
import '../interfaces/IVerification.sol';
import '../interfaces/IVerifier.sol';

contract MockTwitterVerifier is Initializable, IVerifier, OwnableUpgradeable, EIP712Upgradeable {
    /**
     * @notice stores the verification contract instance
     */
    IVerification public verification;
    /**
     * @notice Structure for the user data
     */
    struct UserStructData {
        string twitterId;
        string tweetId;
    }

    /**
     * @notice stores the user metadata against their address
     */
    mapping(address => UserStructData) public userData;
    /**
     * @notice stores the user address against twitterId
     */
    mapping(string => address) public twitterIdMap;
    mapping(bytes32 => address) private hashAddressMap;
    /**
     * @notice stores the signer address
     */
    address public signerAddress;

    /**
     * @notice emitted when verification contract address is updated
     * @param verification address of the updated verification contract
     */
    event VerificationUpdated(address indexed verification);
    /**
     * @notice emitted when Signer address is updated
     * @param signerAddress address of the updated verification contract
     */
    event SignerUpdated(address indexed signerAddress);

    /// @notice Initializes the variables of the contract
    /// @dev Contract follows proxy pattern and this function is used to initialize the variables for the contract in the proxy
    /// @param _admin Admin of the verification contract who can add verifiers and remove masterAddresses deemed invalid
    /// @param _verification Verification contract address
    /// @param _signerAddress Address of the signer bot verifying users and signing off-chain messages
    /// @param _name name of the verifier (used in domain seperator)
    /// @param _version version of the verifier (used in domain seperator)
    function initialize(
        address _admin,
        address _verification,
        address _signerAddress,
        string memory _name,
        string memory _version
    ) external initializer {
        super.__Ownable_init();
        super.transferOwnership(_admin);
        _updateVerification(_verification);
        _updateSignerAddress(_signerAddress);
        __EIP712_init(_name, _version);
    }

    /**
     * @notice used to register user
     * @dev only owner can register users
     * @param _v int v
     * @param _r part signed message hash
     * @param _s part signed message hash
     * @param _timestamp timestamp for the signed message
     * @param _twitterId metadata related to user :  here "twitterId"
     * @param _tweetId metadata related to user :  here "tweetId"
     * @param _isMasterLinked should master address be linked to itself
     */

    function registerSelf(
        bool _isMasterLinked,
        uint8 _v,
        bytes32 _r,
        bytes32 _s,
        string memory _twitterId,
        string memory _tweetId,
        uint256 _timestamp
    ) external {
        require(bytes(userData[msg.sender].twitterId).length == 0, 'User already exists');
        require(twitterIdMap[_twitterId] == address(0), 'Signed message already used');
        require(block.timestamp < _timestamp + 86400, 'Signed transaction expired');

        bytes32 digest = keccak256(
            abi.encode(
                keccak256('set(string twitterId,string tweetId,address userAddr,uint256 timestamp)'),
                keccak256(bytes(_twitterId)),
                keccak256(bytes(_tweetId)),
                msg.sender,
                _timestamp
            )
        );
        require(hashAddressMap[digest] == address(0), 'Hash Already Used');

        bytes32 hash = _hashTypedDataV4(digest);
        address signer = ECDSA.recover(hash, _v, _r, _s);
        require(signer == signerAddress, 'Invalid signature');

        verification.registerMasterAddress(msg.sender, _isMasterLinked);
        userData[msg.sender] = UserStructData(_twitterId, _tweetId);
        twitterIdMap[_twitterId] = msg.sender;
        hashAddressMap[digest] = msg.sender;
        emit UserRegistered(msg.sender, _isMasterLinked, _twitterId);
    }

    function registerUserViaOwner(
        bool _isMasterLinked,
        address _user,
        string memory _twitterId,
        string memory _tweetId
    ) external onlyOwner {
        bytes32 digest = keccak256(
            abi.encode(
                keccak256('set(string twitterId,string tweetId,address userAddr,uint256 timestamp)'),
                keccak256(bytes(_twitterId)),
                keccak256(bytes(_tweetId)),
                _user,
                block.timestamp
            )
        );

        require(hashAddressMap[digest] == address(0), 'Hash Already Used');

        verification.registerMasterAddress(_user, _isMasterLinked);
        userData[_user] = UserStructData(_twitterId, _tweetId);
        twitterIdMap[_twitterId] = _user;
        hashAddressMap[digest] = _user;
        emit UserRegistered(_user, _isMasterLinked, _twitterId);
    }

    /**
     * @notice used to unregister self
     * @dev users themselves can unregister themself
     */
    function unregisterSelf() external {
        string memory _userdata = userData[msg.sender].twitterId;
        require(bytes(_userdata).length != 0, 'User doesnt exists');
        delete twitterIdMap[_userdata];
        delete userData[msg.sender];
        verification.unregisterMasterAddress(msg.sender, address(this));
        emit UserUnregistered(msg.sender);
    }

    /**
     * @notice used to unregister user
     * @dev owners can unregister users
     */
    function unregisterUser(address _user) external onlyOwner {
        string memory _userdata = userData[_user].twitterId;
        require(bytes(_userdata).length != 0, 'User does not exists');
        delete twitterIdMap[_userdata];
        delete userData[_user];
        verification.unregisterMasterAddress(_user, address(this));
        emit UserUnregistered(_user);
    }

    /**
     * @notice used to update verification contract address
     * @dev only owner can update
     * @param _verification address of the verification contract
     */
    function updateVerification(address _verification) external onlyOwner {
        _updateVerification(_verification);
    }

    function _updateVerification(address _verification) internal {
        verification = IVerification(_verification);
        emit VerificationUpdated(_verification);
    }

    /**
     * @notice used to update signer address
     * @dev only owner can update
     * @param _signerAddress address of the verification contract
     */
    function updateSignerAddress(address _signerAddress) external onlyOwner {
        _updateSignerAddress(_signerAddress);
    }

    function _updateSignerAddress(address _signerAddress) internal {
        signerAddress = _signerAddress;
        emit SignerUpdated(signerAddress);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/Initializable.sol";
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
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712Upgradeable is Initializable {
    /* solhint-disable var-name-mixedcase */
    bytes32 private _HASHED_NAME;
    bytes32 private _HASHED_VERSION;
    bytes32 private constant _TYPE_HASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    function __EIP712_init(string memory name, string memory version) internal initializer {
        __EIP712_init_unchained(name, version);
    }

    function __EIP712_init_unchained(string memory name, string memory version) internal initializer {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        return _buildDomainSeparator(_TYPE_HASH, _EIP712NameHash(), _EIP712VersionHash());
    }

    function _buildDomainSeparator(bytes32 typeHash, bytes32 name, bytes32 version) private view returns (bytes32) {
        return keccak256(
            abi.encode(
                typeHash,
                name,
                version,
                _getChainId(),
                address(this)
            )
        );
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", _domainSeparatorV4(), structHash));
    }

    function _getChainId() private view returns (uint256 chainId) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        // solhint-disable-next-line no-inline-assembly
        assembly {
            chainId := chainid()
        }
    }

    /**
     * @dev The hash of the name parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712NameHash() internal virtual view returns (bytes32) {
        return _HASHED_NAME;
    }

    /**
     * @dev The hash of the version parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712VersionHash() internal virtual view returns (bytes32) {
        return _HASHED_VERSION;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
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
        // Check the signature length
        if (signature.length != 65) {
            revert("ECDSA: invalid signature length");
        }

        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        return recover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover-bytes32-bytes-} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, "ECDSA: invalid signature 's' value");
        require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * replicates the behavior of the
     * https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_sign[`eth_sign`]
     * JSON-RPC method.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

interface IVerification {
    /// @notice Event emitted when a verifier is added as valid by admin
    /// @param verifier The address of the verifier contract to be added
    event VerifierAdded(address indexed verifier);

    /// @notice Event emitted when a verifier is to be marked as invalid by admin
    /// @param verifier The address of the verified contract to be marked as invalid
    event VerifierRemoved(address indexed verifier);

    /// @notice Event emitted when a master address is verified by a valid verifier
    /// @param masterAddress The masterAddress which is verifier by the verifier
    /// @param verifier The verifier which verified the masterAddress
    /// @param activatesAt Timestamp at which master address is considered active after the cooldown period
    event UserRegistered(address indexed masterAddress, address indexed verifier, uint256 activatesAt);

    /// @notice Event emitted when a master address is marked as invalid/unregisterd by a valid verifier
    /// @param masterAddress The masterAddress which is unregistered
    /// @param verifier The verifier which verified the masterAddress
    /// @param unregisteredBy The msg.sender by which the user was unregistered
    event UserUnregistered(address indexed masterAddress, address indexed verifier, address indexed unregisteredBy);

    /// @notice Event emitted when an address is linked to masterAddress
    /// @param linkedAddress The address which is linked to masterAddress
    /// @param masterAddress The masterAddress to which address is linked
    /// @param activatesAt Timestamp at which linked address is considered active after the cooldown period
    event AddressLinked(address indexed linkedAddress, address indexed masterAddress, uint256 activatesAt);

    /// @notice Event emitted when an address is unlinked from a masterAddress
    /// @param linkedAddress The address which is linked to masterAddress
    /// @param masterAddress The masterAddress to which address was linked
    event AddressUnlinked(address indexed linkedAddress, address indexed masterAddress);

    /// @notice Event emitted when master address placed a request to link another address to itself
    /// @param linkedAddress The address which is to be linked to masterAddress
    /// @param masterAddress The masterAddress to which address is to be linked
    event AddressLinkingRequested(address indexed linkedAddress, address indexed masterAddress);

    /// @notice Event emitted when master address cancels the request placed to link another address to itself
    /// @param linkedAddress The address which is to be linked to masterAddress
    /// @param masterAddress The masterAddress to which address is to be linked
    event AddressLinkingRequestCancelled(address indexed linkedAddress, address indexed masterAddress);

    /// @notice Event emitted when activation delay is updated
    /// @param activationDelay updated value of activationDelay in seconds
    event ActivationDelayUpdated(uint256 activationDelay);

    function isUser(address _user, address _verifier) external view returns (bool isMsgSenderUser);

    function registerMasterAddress(address _masterAddress, bool _isMasterLinked) external;

    function unregisterMasterAddress(address _masterAddress, address _verifier) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

interface IVerifier {
    /**
     * @notice emitted when a user is registered
     * @param user address of user registered
     * @param isMasterLinked if true, master address is also considered to be linked to itself
     * @param metadata any metadata related to registered user
     */
    event UserRegistered(address user, bool isMasterLinked, string metadata);

    /**
     * @notice emitted when a user is unregistered
     * @param user address of the user unregistered
     */
    event UserUnregistered(address user);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
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
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

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

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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