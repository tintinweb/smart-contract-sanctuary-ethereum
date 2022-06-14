// SPDX-License-Identifier: Apache 2.0
// Immutable Solidity Contracts v0.1.0
pragma solidity ^0.8.4;
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "immutablex/ethereum/starknet/core/interfaces/IStarknetCore.sol";
import "immutablex/ethereum/starknet/core/libraries/StarknetUtilities.sol";
import "./interfaces/IERC721Bridge.sol";
import "./interfaces/IERC721Escrow.sol";
import "./interfaces/IBridgeRegistry.sol";

contract StandardERC721Bridge is
    Initializable,
    IERC721Bridge,
    OwnableUpgradeable
{
    using StarknetUtilities for uint256;
    using AddressUpgradeable for address;

    /**
     * @dev Cairo selector for the 'handle_deposit' function, used in deposit messages to L2
     */
    uint256 public constant DEPOSIT_HANDLER =
        1285101517810983806491589552491143496277809242732141897358598292095611420389;

    /**
     * @dev Number of array slots reserved when generating payload to starknet. The reserved slots
     * are for [ MESSAGING_type, SenderL1Address, TokenAddress, NumberOfTokenIds ]
     */
    uint256 public constant PAYLOAD_PREFIX_SIZE = 4;

    IBridgeRegistry private bridgeRegistry;
    IStarknetCore private starknetMessaging;
    IERC721Escrow private escrowContract;

    /**
     * @dev mapping from hash of a deposit to the depositor's address
     */
    mapping(bytes32 => address) private deposits;

    function initialize(
        IStarknetCore _starknetMessaging,
        IERC721Escrow _escrowContract
    ) external initializer {
        require(
            address(_starknetMessaging).isContract(),
            "starknet messaging is not a contract"
        );

        require(
            address(_escrowContract).isContract(),
            "erc721 escrow address is not a contract"
        );
        starknetMessaging = _starknetMessaging;
        escrowContract = _escrowContract;
        __Ownable_init();
    }

    /**
     * @dev return the L2 recipient of the message being sent to L2
     */
    function getL2MessageRecipient() internal view returns (uint256) {
        return bridgeRegistry.getStandardTokenBridge().l2BridgeAddress;
    }

    /**
     * @dev set the bridge registry address
     */
    function setBridgeRegistry(IBridgeRegistry _bridgeRegistry)
        external
        onlyOwner
    {
        require(
            address(_bridgeRegistry).isContract(),
            "bridge registry address is not a contract"
        );
        require(
            address(bridgeRegistry) == address(0),
            "bridge registry already set"
        );
        bridgeRegistry = _bridgeRegistry;
    }

    /**
     * @inheritdoc IERC721Bridge
     */
    function isWithdrawable(
        IERC721 _token,
        uint256[] calldata _tokenIds,
        address withdrawer
    ) external view override returns (bool) {
        uint256 l2TokenAddress = getL2TokenOrRevert(address(_token));

        uint256[] memory payload = _createPayloadFromL2(
            _token,
            _tokenIds.length,
            withdrawer,
            l2TokenAddress
        );
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            // split uint256 into uint128 low and high
            uint256 payloadIndex = i << 1;
            payload[PAYLOAD_PREFIX_SIZE + payloadIndex] = uint128(_tokenIds[i]);
            payload[PAYLOAD_PREFIX_SIZE + payloadIndex + 1] = uint128(
                _tokenIds[i] >> 128
            );
        }

        bytes32 msgHash = keccak256(
            abi.encodePacked(
                getL2MessageRecipient(),
                uint256(uint160(address(this))),
                payload.length,
                payload
            )
        );
        return starknetMessaging.l2ToL1Messages(msgHash) > 0;
    }

    /**
     * @inheritdoc IERC721Bridge
     */
    function deposit(
        IERC721 _token,
        uint256[] calldata _tokenIds,
        uint256 _senderL2Address
    ) external override {
        uint256 l2TokenAddress = getL2TokenOrRevert(address(_token));

        uint256[] memory payload = _createPayloadToL2(
            _token,
            _tokenIds.length,
            _senderL2Address,
            l2TokenAddress
        );

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            uint256 tokenId = _tokenIds[i];
            _token.transferFrom(msg.sender, address(escrowContract), tokenId);
            uint256 payloadIndex = i << 1;
            payload[PAYLOAD_PREFIX_SIZE + payloadIndex] = uint128(tokenId);
            payload[PAYLOAD_PREFIX_SIZE + payloadIndex + 1] = uint128(
                tokenId >> 128
            );
        }

        uint256 starknetNonce = starknetMessaging.l1ToL2MessageNonce();

        bytes32 messageHash = starknetMessaging.sendMessageToL2(
            getL2MessageRecipient(),
            DEPOSIT_HANDLER,
            payload
        );

        deposits[messageHash] = msg.sender;

        emit Deposit(
            msg.sender,
            address(_token),
            _tokenIds,
            _senderL2Address,
            starknetNonce
        );
    }

    /**
     * @inheritdoc IERC721Bridge
     */
    function withdraw(
        IERC721 _token,
        uint256[] calldata _tokenIds,
        address _recipient
    ) external override {
        uint256 l2TokenAddress = getL2TokenOrRevert(address(_token));

        uint256[] memory payload = _createPayloadFromL2(
            _token,
            _tokenIds.length,
            msg.sender,
            l2TokenAddress
        );
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            uint256 tokenId = _tokenIds[i];
            escrowContract.approveForWithdraw(address(_token), tokenId);
            // split uint256 into uint128 low and high
            uint256 payloadIndex = i << 1;
            payload[PAYLOAD_PREFIX_SIZE + payloadIndex] = uint128(tokenId);
            payload[PAYLOAD_PREFIX_SIZE + payloadIndex + 1] = uint128(
                tokenId >> 128
            );
            // optimistically transfer
            _token.transferFrom(address(escrowContract), _recipient, tokenId);
        }
        starknetMessaging.consumeMessageFromL2(
            getL2MessageRecipient(),
            payload
        );

        emit Withdraw(msg.sender, address(_token), _tokenIds);
    }

    /**
     * @inheritdoc IERC721Bridge
     */
    function initiateCancelDeposit(
        IERC721 _token,
        uint256[] calldata _tokenIds,
        uint256 _senderL2Address,
        uint256 _nonce
    ) external override {
        uint256 l2TokenAddress = getL2TokenOrRevert(address(_token));

        uint256[] memory payload = _createPayloadToL2(
            _token,
            _tokenIds.length,
            _senderL2Address,
            l2TokenAddress
        );

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            uint256 tokenId = _tokenIds[i];
            uint256 payloadIndex = i << 1;
            payload[PAYLOAD_PREFIX_SIZE + payloadIndex] = uint128(tokenId);
            payload[PAYLOAD_PREFIX_SIZE + payloadIndex + 1] = uint128(
                tokenId >> 128
            );
        }

        bytes32 msgHash = StarknetUtilities.getL1ToL2MsgHash(
            getL2MessageRecipient(),
            DEPOSIT_HANDLER,
            payload,
            address(this),
            _nonce
        );

        require(
            deposits[msgHash] == msg.sender,
            "tokens were not deposited by sender"
        );

        starknetMessaging.startL1ToL2MessageCancellation(
            getL2MessageRecipient(),
            DEPOSIT_HANDLER,
            payload,
            _nonce
        );

        emit DepositCancelInitiated(
            msg.sender,
            address(_token),
            _tokenIds,
            _senderL2Address,
            _nonce
        );
    }

    /**
     * @inheritdoc IERC721Bridge
     * @dev TODO Allow users to set their recipient address
     */
    function completeCancelDeposit(
        IERC721 _token,
        uint256[] calldata _tokenIds,
        uint256 _senderL2Address,
        uint256 _nonce,
        address _recipient
    ) external override {
        uint256 l2TokenAddress = getL2TokenOrRevert(address(_token));

        uint256[] memory payload = _createPayloadToL2(
            _token,
            _tokenIds.length,
            _senderL2Address,
            l2TokenAddress
        );

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            uint256 tokenId = _tokenIds[i];
            uint256 payloadIndex = i << 1;
            payload[PAYLOAD_PREFIX_SIZE + payloadIndex] = uint128(tokenId);
            payload[PAYLOAD_PREFIX_SIZE + payloadIndex + 1] = uint128(
                tokenId >> 128
            );
            escrowContract.approveForWithdraw(address(_token), tokenId);
            _token.transferFrom(address(escrowContract), _recipient, tokenId);
        }

        bytes32 msgHash = StarknetUtilities.getL1ToL2MsgHash(
            getL2MessageRecipient(),
            DEPOSIT_HANDLER,
            payload,
            address(this),
            _nonce
        );

        require(
            deposits[msgHash] == msg.sender,
            "tokens were not deposited by sender"
        );

        starknetMessaging.cancelL1ToL2Message(
            getL2MessageRecipient(),
            DEPOSIT_HANDLER,
            payload,
            _nonce
        );

        // refund gas
        delete deposits[msgHash];

        emit DepositCancelled(
            msg.sender,
            address(_token),
            _tokenIds,
            _senderL2Address,
            _nonce
        );
    }

    function _createPayloadToL2(
        IERC721 _token,
        uint256 _numTokenIds,
        uint256 _senderL2Address,
        uint256 _l2TokenAddress
    ) private pure returns (uint256[] memory) {
        require(_numTokenIds > 0, "_tokenIds must not be empty");
        require(
            _senderL2Address.isValidL2Address(),
            "_senderL2Address is invalid"
        );
        uint256 tokenIdsLen = _numTokenIds << 1;

        uint256[] memory payload = new uint256[](
            PAYLOAD_PREFIX_SIZE + tokenIdsLen
        );
        payload[0] = _l2TokenAddress;
        payload[1] = _senderL2Address;
        payload[2] = uint256(uint160(address(_token)));
        payload[3] = tokenIdsLen;
        return payload;
    }

    function _createPayloadFromL2(
        IERC721 _token,
        uint256 _numTokenIds,
        address _senderL1Address,
        uint256 _l2TokenAddress
    ) private pure returns (uint256[] memory) {
        require(_numTokenIds > 0, "_tokenIds must not be empty");

        uint256 tokenIdsLen = _numTokenIds << 1;

        uint256[] memory payload = new uint256[](
            PAYLOAD_PREFIX_SIZE + tokenIdsLen
        );
        payload[0] = _l2TokenAddress;
        payload[1] = uint256(uint160(_senderL1Address));
        payload[2] = uint256(uint160(address(_token)));
        payload[3] = tokenIdsLen;
        return payload;
    }

    function getL2TokenOrRevert(address _l1Token)
        internal
        view
        returns (uint256)
    {
        uint256 l2TokenAddress = bridgeRegistry.getL2Token(_l1Token);
        require(l2TokenAddress != 0, "token is not registered");
        return l2TokenAddress;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
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
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
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
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

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

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// SPDX-License-Identifier: Apache 2.0
// Immutable Solidity Contracts v0.1.0
pragma solidity ^0.8.4;

import "./IStarknetMessaging.sol";

/**
 * This interface is required as IStarknetMessaging does not expose the external functions in StarknetMessaging
 * We create this interface as we do not wish to modify StarknetMessaging and IStarknetMessaging
 */
interface IStarknetCore is IStarknetMessaging {
    /**
     *returns > 0 if there is a message ready for consumption with the given msgHash
     */
    function l2ToL1Messages(bytes32 msgHash) external view returns (uint256);

    /**
     * returns the current nonce counter of the starknet messaging contract
     * This is actually defined as a public function in implementation
     */
    function l1ToL2MessageNonce() external view returns (uint256);
}

// SPDX-License-Identifier: Apache 2.0
// Immutable Solidity Contracts v0.1.0
pragma solidity ^0.8.4;

import "./CairoConstants.sol";

library StarknetUtilities {
    function isValidL2Address(uint256 l2Address) internal pure returns (bool) {
        return (l2Address != 0) && (l2Address < CairoConstants.FIELD_PRIME);
    }

    function getL1ToL2MsgHash(
        uint256 toAddress,
        uint256 selector,
        uint256[] memory payload,
        address sender,
        uint256 nonce
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    uint256(uint160(address(sender))),
                    toAddress,
                    nonce,
                    selector,
                    payload.length,
                    payload
                )
            );
    }
}

// SPDX-License-Identifier: Apache 2.0
// Immutable Solidity Contracts v0.1.0
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/interfaces/IERC721.sol";

interface IERC721Bridge {
    /**
     * @dev emitted on deposit
     */
    event Deposit(
        address indexed sender,
        address indexed token,
        uint256[] tokenIds,
        uint256 indexed senderL2Address,
        uint256 nonce
    );

    /**
     * @dev emitted on withdraw
     */
    event Withdraw(
        address indexed sender,
        address indexed token,
        uint256[] tokenIds
    );

    /**
     * @dev event emitted when a deposit is cancelled and NFTs are returned
     */
    event DepositCancelInitiated(
        address indexed sender,
        address indexed token,
        uint256[] tokenIds,
        uint256 indexed senderL2Address,
        uint256 nonce
    );

    /**
     * @dev event emitted when a deposit is cancelled and NFTs are returned
     */
    event DepositCancelled(
        address indexed sender,
        address indexed token,
        uint256[] tokenIds,
        uint256 indexed senderL2Address,
        uint256 nonce
    );

    /**
     * @dev transfers the NFTs from the caller to the contract, then sends a message to StarkNet signalling a deposit
     */
    function deposit(
        IERC721 _token,
        uint256[] memory _tokenIds,
        uint256 _senderL2Address
    ) external;

    /**
     * @dev transfers the NFTs from the contract to the caller after receiving the appropriate withdraw message from the user
     */
    function withdraw(
        IERC721 _token,
        uint256[] memory _tokenIds,
        address _recipient
    ) external;

    /**
     * @dev returns true if the NFT is ready to withdraw.
     * Used to prevent gas wasted on `withdraw`
     */
    function isWithdrawable(
        IERC721 _token,
        uint256[] memory _tokenIds,
        address withdrawer
    ) external view returns (bool);

    /**
     * @dev In the scenario that the deposit message was not
     * sent to L2 successfully, initiate cancel deposit to start the cancellation process
     */
    function initiateCancelDeposit(
        IERC721 _token,
        uint256[] memory _tokenIds,
        uint256 _senderL2Address,
        uint256 _nonce
    ) external;

    /**
     * @dev can be executed 5 days after intiateCancelDeposit. If successful, the caller will be returned their NFTs
     */
    function completeCancelDeposit(
        IERC721 _token,
        uint256[] memory _tokenIds,
        uint256 _senderL2Address,
        uint256 _nonce,
        address _recipient
    ) external;
}

// SPDX-License-Identifier: Apache 2.0
// Immutable Solidity Contracts v0.1.0
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/interfaces/IERC721.sol";

interface IERC721Escrow {
    /**
     * @dev callable by an address with the WITHDRAWER role, initially only the StandardERC721Bridge
     */
    function approveForWithdraw(address token, uint256 _tokenId) external;
}

// SPDX-License-Identifier: Apache 2.0
// Immutable Solidity Contracts v0.1.0
pragma solidity ^0.8.4;

/**
 * @title A registry where Token Contract owners can register their custom Starknet bridge for discovery
 * @dev Implementers of this interface can be used to discover bridges for presentation to end users
 */
interface IBridgeRegistry {
    /**
     * @dev a struct to hold an L1 Ethereum bridge address and an L2 Starknet bridge address
     */
    struct BridgePair {
        address l1BridgeAddress;
        uint256 l2BridgeAddress;
    }

    /**
     * @dev event emitted when a token contract owner invokes setCustomTokenBridge
     */
    event RegisterToken(
        address indexed _from,
        address indexed _l1TokenAddress,
        uint256 indexed _l2TokenAddress
    );

    /**
     * @dev get the standard token bridge
     */
    function getStandardTokenBridge() external view returns (BridgePair memory);

    /**
     * @dev get the l2 token address for a given l2 token
     */
    function getL2Token(address l1TokenAddress) external view returns (uint256);

    /**
     * @dev set the l2 token address for a token. Can only be set by owner.
     */
    function registerToken(address l1TokenAddress, uint256 l2TokenAddress)
        external;
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

// SPDX-License-Identifier: Apache-2.0.
// Retrieved from https://github.com/starkware-libs/cairo-lang/blob/4e233516f52477ad158bc81a86ec2760471c1b65/src/starkware/starknet/eth/IStarknetMessaging.sol
pragma solidity ^0.8.4;

import "./IStarknetMessagingEvents.sol";

interface IStarknetMessaging is IStarknetMessagingEvents {
    /**
      Sends a message to an L2 contract.
      Returns the hash of the message.
    */
    function sendMessageToL2(
        uint256 toAddress,
        uint256 selector,
        uint256[] calldata payload
    ) external returns (bytes32);

    /**
      Consumes a message that was sent from an L2 contract.

      Returns the hash of the message.
    */
    function consumeMessageFromL2(
        uint256 fromAddress,
        uint256[] calldata payload
    ) external returns (bytes32);

    /**
      Starts the cancellation of an L1 to L2 message.
      A message can be canceled messageCancellationDelay() seconds after this function is called.

      Note: This function may only be called for a message that is currently pending and the caller
      must be the sender of the that message.
    */
    function startL1ToL2MessageCancellation(
        uint256 toAddress,
        uint256 selector,
        uint256[] calldata payload,
        uint256 nonce
    ) external;

    /**
      Cancels an L1 to L2 message, this function should be called messageCancellationDelay() seconds
      after the call to startL1ToL2MessageCancellation().
    */
    function cancelL1ToL2Message(
        uint256 toAddress,
        uint256 selector,
        uint256[] calldata payload,
        uint256 nonce
    ) external;
}

// SPDX-License-Identifier: Apache-2.0.
// Retrieved from https://github.com/starkware-libs/cairo-lang/blob/4e233516f52477ad158bc81a86ec2760471c1b65/src/starkware/starknet/eth/IStarknetMessagingEvents.sol
pragma solidity ^0.8.4;

interface IStarknetMessagingEvents {
    // This event needs to be compatible with the one defined in Output.sol.
    event LogMessageToL1(
        uint256 indexed fromAddress,
        address indexed toAddress,
        uint256[] payload
    );

    // An event that is raised when a message is sent from L1 to L2.
    event LogMessageToL2(
        address indexed fromAddress,
        uint256 indexed toAddress,
        uint256 indexed selector,
        uint256[] payload,
        uint256 nonce
    );

    // An event that is raised when a message from L2 to L1 is consumed.
    event ConsumedMessageToL1(
        uint256 indexed fromAddress,
        address indexed toAddress,
        uint256[] payload
    );

    // An event that is raised when a message from L1 to L2 is consumed.
    event ConsumedMessageToL2(
        address indexed fromAddress,
        uint256 indexed toAddress,
        uint256 indexed selector,
        uint256[] payload,
        uint256 nonce
    );

    // An event that is raised when a message from L1 to L2 Cancellation is started.
    event MessageToL2CancellationStarted(
        address indexed fromAddress,
        uint256 indexed toAddress,
        uint256 indexed selector,
        uint256[] payload,
        uint256 nonce
    );

    // An event that is raised when a message from L1 to L2 is canceled.
    event MessageToL2Canceled(
        address indexed fromAddress,
        uint256 indexed toAddress,
        uint256 indexed selector,
        uint256[] payload,
        uint256 nonce
    );
}

// SPDX-License-Identifier: Apache-2.0.
// Retrieved from https://github.com/starkware-libs/starkgate-contracts/blob/323111b26f97ce65c93faf4f38f0a3b304877e58/src/starkware/cairo/eth/CairoConstants.sol
pragma solidity ^0.8.4;

library CairoConstants {
    uint256 public constant FIELD_PRIME =
        0x800000000000011000000000000000000000000000000000000000000000001;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721.sol)

pragma solidity ^0.8.0;

import "../token/ERC721/IERC721.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
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
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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