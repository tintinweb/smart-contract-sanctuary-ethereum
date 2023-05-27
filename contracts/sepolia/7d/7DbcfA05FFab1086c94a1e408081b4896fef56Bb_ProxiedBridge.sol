// SPDX-License-Identifier: MIT
//  _____     _ _         _         _
// |_   _|_ _(_) |_____  | |   __ _| |__ ___
//   | |/ _` | | / / _ \ | |__/ _` | '_ (_-<
//   |_|\__,_|_|_\_\___/ |____\__,_|_.__/__/

pragma solidity ^0.8.18;

import {AddressResolver} from "../common/AddressResolver.sol";
import {EssentialContract} from "../common/EssentialContract.sol";
import {Proxied} from "../common/Proxied.sol";
import {IBridge} from "./IBridge.sol";
import {BridgeErrors} from "./BridgeErrors.sol";
import {LibBridgeData} from "./libs/LibBridgeData.sol";
import {LibBridgeProcess} from "./libs/LibBridgeProcess.sol";
import {LibBridgeRelease} from "./libs/LibBridgeRelease.sol";
import {LibBridgeRetry} from "./libs/LibBridgeRetry.sol";
import {LibBridgeSend} from "./libs/LibBridgeSend.sol";
import {LibBridgeStatus} from "./libs/LibBridgeStatus.sol";

/**
 * Bridge contract which is deployed on both L1 and L2. Mostly a thin wrapper
 * which calls the library implementations. See _IBridge_ for more details.
 * @dev The code hash for the same address on L1 and L2 may be different.
 * @custom:security-contact [email protected]
 */
contract Bridge is EssentialContract, IBridge, BridgeErrors {
    using LibBridgeData for Message;

    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    LibBridgeData.State private _state; // 50 slots reserved

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event MessageStatusChanged(
        bytes32 indexed msgHash, LibBridgeStatus.MessageStatus status, address transactor
    );

    event DestChainEnabled(uint256 indexed chainId, bool enabled);

    /*//////////////////////////////////////////////////////////////
                         USER-FACING FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// Allow Bridge to receive ETH from the TaikoL1, TokenVault or EtherVault.
    receive() external payable {
        if (
            msg.sender != resolve("token_vault", true) && msg.sender != resolve("ether_vault", true)
                && msg.sender != resolve("taiko", true) && msg.sender != owner()
        ) {
            revert B_CANNOT_RECEIVE();
        }
    }

    /// @dev Initializer to be called after being deployed behind a proxy.
    function init(address _addressManager) external initializer {
        EssentialContract._init(_addressManager);
    }

    function sendMessage(Message calldata message)
        external
        payable
        nonReentrant
        returns (bytes32 msgHash)
    {
        return LibBridgeSend.sendMessage({
            state: _state,
            resolver: AddressResolver(this),
            message: message
        });
    }

    function releaseEther(IBridge.Message calldata message, bytes calldata proof)
        external
        nonReentrant
    {
        return LibBridgeRelease.releaseEther({
            state: _state,
            resolver: AddressResolver(this),
            message: message,
            proof: proof
        });
    }

    function processMessage(Message calldata message, bytes calldata proof) external nonReentrant {
        return LibBridgeProcess.processMessage({
            state: _state,
            resolver: AddressResolver(this),
            message: message,
            proof: proof
        });
    }

    function retryMessage(Message calldata message, bool isLastAttempt) external nonReentrant {
        return LibBridgeRetry.retryMessage({
            state: _state,
            resolver: AddressResolver(this),
            message: message,
            isLastAttempt: isLastAttempt
        });
    }

    function isMessageSent(bytes32 msgHash) public view virtual returns (bool) {
        return LibBridgeSend.isMessageSent(AddressResolver(this), msgHash);
    }

    function isMessageReceived(bytes32 msgHash, uint256 srcChainId, bytes calldata proof)
        public
        view
        virtual
        override
        returns (bool)
    {
        return LibBridgeSend.isMessageReceived({
            resolver: AddressResolver(this),
            msgHash: msgHash,
            srcChainId: srcChainId,
            proof: proof
        });
    }

    function isMessageFailed(bytes32 msgHash, uint256 destChainId, bytes calldata proof)
        public
        view
        virtual
        override
        returns (bool)
    {
        return LibBridgeStatus.isMessageFailed({
            resolver: AddressResolver(this),
            msgHash: msgHash,
            destChainId: destChainId,
            proof: proof
        });
    }

    function getMessageStatus(bytes32 msgHash)
        public
        view
        virtual
        returns (LibBridgeStatus.MessageStatus)
    {
        return LibBridgeStatus.getMessageStatus(msgHash);
    }

    function context() public view returns (Context memory) {
        return _state.ctx;
    }

    function isEtherReleased(bytes32 msgHash) public view returns (bool) {
        return _state.etherReleased[msgHash];
    }

    function isDestChainEnabled(uint256 _chainId) public view returns (bool enabled) {
        (enabled,) = LibBridgeSend.isDestChainEnabled(AddressResolver(this), _chainId);
    }

    function hashMessage(Message calldata message) public pure override returns (bytes32) {
        return LibBridgeData.hashMessage(message);
    }

    function getMessageStatusSlot(bytes32 msgHash) public pure returns (bytes32) {
        return LibBridgeStatus.getMessageStatusSlot(msgHash);
    }
}

contract ProxiedBridge is Proxied, Bridge {}

// SPDX-License-Identifier: MIT
//  _____     _ _         _         _
// |_   _|_ _(_) |_____  | |   __ _| |__ ___
//   | |/ _` | | / / _ \ | |__/ _` | '_ (_-<
//   |_|\__,_|_|_\_\___/ |____\__,_|_.__/__/

pragma solidity ^0.8.18;

import {
    IERC20Upgradeable,
    ERC20Upgradeable
} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {IERC20MetadataUpgradeable} from
    "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";

import {EssentialContract} from "../common/EssentialContract.sol";
import {Proxied} from "../common/Proxied.sol";
import {BridgeErrors} from "./BridgeErrors.sol";

/// @custom:security-contact [email protected]
contract BridgedERC20 is
    EssentialContract,
    IERC20Upgradeable,
    IERC20MetadataUpgradeable,
    ERC20Upgradeable,
    BridgeErrors
{
    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    address public srcToken;
    uint256 public srcChainId;
    uint8 private srcDecimals;
    uint256[47] private __gap;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event BridgeMint(address indexed account, uint256 amount);
    event BridgeBurn(address indexed account, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                         USER-FACING FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @dev Initializer to be called after being deployed behind a proxy.
    // Intention is for a different BridgedERC20 Contract to be deployed
    // per unique _srcToken i.e. one for USDC, one for USDT etc.
    function init(
        address _addressManager,
        address _srcToken,
        uint256 _srcChainId,
        uint8 _decimals,
        string memory _symbol,
        string memory _name
    ) external initializer {
        if (
            _srcToken == address(0) || _srcChainId == 0 || _srcChainId == block.chainid
                || bytes(_symbol).length == 0 || bytes(_name).length == 0
        ) {
            revert B_INIT_PARAM_ERROR();
        }
        EssentialContract._init(_addressManager);
        ERC20Upgradeable.__ERC20_init({name_: _name, symbol_: _symbol});
        srcToken = _srcToken;
        srcChainId = _srcChainId;
        srcDecimals = _decimals;
    }

    /// @dev only a TokenVault can call this function
    function bridgeMintTo(address account, uint256 amount) public onlyFromNamed("token_vault") {
        _mint(account, amount);
        emit BridgeMint(account, amount);
    }

    /// @dev only a TokenVault can call this function
    function bridgeBurnFrom(address account, uint256 amount) public onlyFromNamed("token_vault") {
        _burn(account, amount);
        emit BridgeBurn(account, amount);
    }

    /// @dev any address can call this
    // caller must have at least amount to call this
    function transfer(address to, uint256 amount)
        public
        override(ERC20Upgradeable, IERC20Upgradeable)
        returns (bool)
    {
        if (to == address(this)) {
            revert B_ERC20_CANNOT_RECEIVE();
        }
        return ERC20Upgradeable.transfer(to, amount);
    }

    /// @dev any address can call this
    // caller must have allowance of at least 'amount'
    // for 'from's tokens.
    function transferFrom(address from, address to, uint256 amount)
        public
        override(ERC20Upgradeable, IERC20Upgradeable)
        returns (bool)
    {
        if (to == address(this)) {
            revert B_ERC20_CANNOT_RECEIVE();
        }
        return ERC20Upgradeable.transferFrom(from, to, amount);
    }

    function decimals()
        public
        view
        override(ERC20Upgradeable, IERC20MetadataUpgradeable)
        returns (uint8)
    {
        return srcDecimals;
    }

    /// @dev returns the srcToken being bridged and the srcChainId
    // of the tokens being bridged
    function source() public view returns (address, uint256) {
        return (srcToken, srcChainId);
    }
}

contract ProxiedBridgedERC20 is Proxied, BridgedERC20 {}

// SPDX-License-Identifier: MIT
//  _____     _ _         _         _
// |_   _|_ _(_) |_____  | |   __ _| |__ ___
//   | |/ _` | | / / _ \ | |__/ _` | '_ (_-<
//   |_|\__,_|_|_\_\___/ |____\__,_|_.__/__/

pragma solidity ^0.8.18;

abstract contract BridgeErrors {
    error B_CANNOT_RECEIVE();
    error B_DENIED();
    error B_ERC20_CANNOT_RECEIVE();
    error B_ETHER_RELEASED_ALREADY();
    error B_EV_DO_NOT_BURN();
    error B_EV_NOT_AUTHORIZED();
    error B_EV_PARAM();
    error B_FAILED_TRANSFER();
    error B_FORBIDDEN();
    error B_GAS_LIMIT();
    error B_INCORRECT_VALUE();
    error B_INIT_PARAM_ERROR();
    error B_MSG_HASH_NULL();
    error B_MSG_NON_RETRIABLE();
    error B_MSG_NOT_FAILED();
    error B_NULL_APP_ADDR();
    error B_OWNER_IS_NULL();
    error B_SIGNAL_NOT_RECEIVED();
    error B_STATUS_MISMATCH();
    error B_WRONG_CHAIN_ID();
    error B_WRONG_TO_ADDRESS();
    error B_ZERO_SIGNAL();
}

// SPDX-License-Identifier: MIT
//  _____     _ _         _         _
// |_   _|_ _(_) |_____  | |   __ _| |__ ___
//   | |/ _` | | / / _ \ | |__/ _` | '_ (_-<
//   |_|\__,_|_|_\_\___/ |____\__,_|_.__/__/

pragma solidity ^0.8.18;

import {SafeERC20Upgradeable} from
    "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {Create2Upgradeable} from "lib/openzeppelin-contracts-upgradeable/contracts/utils/Create2Upgradeable.sol";
import {EssentialContract} from "../common/EssentialContract.sol";
import {Proxied} from "../common/Proxied.sol";
import {LibAddress} from "../libs/LibAddress.sol";
import {BridgeErrors} from "./BridgeErrors.sol";

/**
 * @custom:security-contact [email protected]
 * EtherVault is a special vault contract that:
 * - Is initialized with 2^128 Ether.
 * - Allows the contract owner to authorize addresses.
 * - Allows authorized addresses to send/release Ether.
 */
contract EtherVault is EssentialContract, BridgeErrors {
    using LibAddress for address;

    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    mapping(address addr => bool isAuthorized) private _authorizedAddrs;
    uint256[49] private __gap;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Authorized(address indexed addr, bool authorized);

    event EtherReleased(address indexed to, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                               MODIFIERS
    //////////////////////////////////////////////////////////////*/

    modifier onlyAuthorized() {
        if (!isAuthorized(msg.sender)) {
            revert B_EV_NOT_AUTHORIZED();
        }
        _;
    }

    /*//////////////////////////////////////////////////////////////
                         USER-FACING FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    receive() external payable {
        // EthVault's balance must == 0 OR the sender isAuthorized.
        if (address(this).balance != 0 && !isAuthorized(msg.sender)) {
            revert B_EV_NOT_AUTHORIZED();
        }
    }

    function init(address addressManager) external initializer {
        EssentialContract._init(addressManager);
    }

    /**
     * Transfer Ether from EtherVault to the sender, checking that the sender
     * is authorized.
     * @param amount Amount of Ether to send.
     */
    function releaseEther(uint256 amount) public onlyAuthorized nonReentrant {
        msg.sender.sendEther(amount);
        emit EtherReleased(msg.sender, amount);
    }

    /**
     * Transfer Ether from EtherVault to a designated address, checking that the
     * sender is authorized.
     * @param recipient Address to receive Ether.
     * @param amount Amount of ether to send.
     */
    function releaseEther(address recipient, uint256 amount) public onlyAuthorized nonReentrant {
        if (recipient == address(0)) {
            revert B_EV_DO_NOT_BURN();
        }
        recipient.sendEther(amount);
        emit EtherReleased(recipient, amount);
    }

    /**
     * Set the authorized status of an address, only the owner can call this.
     * @param addr Address to set the authorized status of.
     * @param authorized Authorized status to set.
     */
    function authorize(address addr, bool authorized) public onlyOwner {
        if (addr == address(0) || _authorizedAddrs[addr] == authorized) {
            revert B_EV_PARAM();
        }
        _authorizedAddrs[addr] = authorized;
        emit Authorized(addr, authorized);
    }

    /**
     * Get the authorized status of an address.
     * @param addr Address to get the authorized status of.
     */
    function isAuthorized(address addr) public view returns (bool) {
        return _authorizedAddrs[addr];
    }
}

contract ProxiedEtherVault is Proxied, EtherVault {}

// SPDX-License-Identifier: MIT
//  _____     _ _         _         _
// |_   _|_ _(_) |_____  | |   __ _| |__ ___
//   | |/ _` | | / / _ \ | |__/ _` | '_ (_-<
//   |_|\__,_|_|_\_\___/ |____\__,_|_.__/__/

pragma solidity ^0.8.18;

/**
 * Bridge interface.
 * @dev Ether is held by Bridges on L1 and by the EtherVault on L2,
 * not TokenVaults.
 */
interface IBridge {
    struct Message {
        // Message ID.
        uint256 id;
        // Message sender address (auto filled).
        address sender;
        // Source chain ID (auto filled).
        uint256 srcChainId;
        // Destination chain ID where the `to` address lives (auto filled).
        uint256 destChainId;
        // Owner address of the bridged asset.
        address owner;
        // Destination owner address.
        address to;
        // Alternate address to send any refund. If blank, defaults to owner.
        address refundAddress;
        // Deposited Ether minus the processingFee.
        uint256 depositValue;
        // callValue to invoke on the destination chain, for ERC20 transfers.
        uint256 callValue;
        // Processing fee for the relayer. Zero if owner will process themself.
        uint256 processingFee;
        // gasLimit to invoke on the destination chain, for ERC20 transfers.
        uint256 gasLimit;
        // callData to invoke on the destination chain, for ERC20 transfers.
        bytes data;
        // Optional memo.
        string memo;
    }

    struct Context {
        bytes32 msgHash; // messageHash
        address sender;
        uint256 srcChainId;
    }

    event SignalSent(address sender, bytes32 msgHash);
    event MessageSent(bytes32 indexed msgHash, Message message);
    event EtherReleased(bytes32 indexed msgHash, address to, uint256 amount);

    /// Sends a message to the destination chain and takes custody
    /// of Ether required in this contract. All extra Ether will be refunded.
    function sendMessage(Message memory message) external payable returns (bytes32 msgHash);

    // Release Ether with a proof that the message processing on the destination
    // chain has been failed.
    function releaseEther(IBridge.Message calldata message, bytes calldata proof) external;

    /// Checks if a msgHash has been stored on the bridge contract by the
    /// current address.
    function isMessageSent(bytes32 msgHash) external view returns (bool);

    /// Checks if a msgHash has been received on the destination chain and
    /// sent by the src chain.
    function isMessageReceived(bytes32 msgHash, uint256 srcChainId, bytes calldata proof)
        external
        view
        returns (bool);

    /// Checks if a msgHash has been failed on the destination chain.
    function isMessageFailed(bytes32 msgHash, uint256 destChainId, bytes calldata proof)
        external
        view
        returns (bool);

    /// Returns the bridge state context.
    function context() external view returns (Context memory context);

    function hashMessage(IBridge.Message calldata message) external pure returns (bytes32);
}

// SPDX-License-Identifier: MIT
//  _____     _ _         _         _
// |_   _|_ _(_) |_____  | |   __ _| |__ ___
//   | |/ _` | | / / _ \ | |__/ _` | '_ (_-<
//   |_|\__,_|_|_\_\___/ |____\__,_|_.__/__/

pragma solidity ^0.8.18;

import {AddressResolver} from "../../common/AddressResolver.sol";
import {BlockHeader} from "../../libs/LibBlockHeader.sol";
import {IBridge} from "../IBridge.sol";
import {LibAddress} from "../../libs/LibAddress.sol";
import {LibMath} from "../../libs/LibMath.sol";

/**
 * Stores message metadata on the Bridge.
 */
library LibBridgeData {
    struct State {
        uint256 nextMessageId;
        IBridge.Context ctx; // 3 slots
        mapping(bytes32 msgHash => bool released) etherReleased;
        uint256[45] __gap;
    }

    struct StatusProof {
        BlockHeader header;
        bytes proof;
    }

    bytes32 internal constant MESSAGE_HASH_PLACEHOLDER = bytes32(uint256(1));
    uint256 internal constant CHAINID_PLACEHOLDER = type(uint256).max;
    address internal constant SRC_CHAIN_SENDER_PLACEHOLDER = address(uint160(uint256(1)));

    // Note: These events must match the ones defined in Bridge.sol.
    event MessageSent(bytes32 indexed msgHash, IBridge.Message message);
    event DestChainEnabled(uint256 indexed chainId, bool enabled);

    /**
     * @return msgHash The keccak256 hash of the message.
     */
    function hashMessage(IBridge.Message memory message) internal pure returns (bytes32) {
        return keccak256(abi.encode(message));
    }
}

// SPDX-License-Identifier: MIT
//  _____     _ _         _         _
// |_   _|_ _(_) |_____  | |   __ _| |__ ___
//   | |/ _` | | / / _ \ | |__/ _` | '_ (_-<
//   |_|\__,_|_|_\_\___/ |____\__,_|_.__/__/

pragma solidity ^0.8.18;

import {IBridge} from "../IBridge.sol";
import {LibAddress} from "../../libs/LibAddress.sol";
import {LibBridgeData} from "./LibBridgeData.sol";

library LibBridgeInvoke {
    using LibAddress for address;
    using LibBridgeData for IBridge.Message;

    error B_GAS_LIMIT();

    /*//////////////////////////////////////////////////////////////
                           INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function invokeMessageCall(
        LibBridgeData.State storage state,
        IBridge.Message calldata message,
        bytes32 msgHash,
        uint256 gasLimit
    ) internal returns (bool success) {
        if (gasLimit == 0) {
            revert B_GAS_LIMIT();
        }

        state.ctx = IBridge.Context({
            msgHash: msgHash,
            sender: message.sender,
            srcChainId: message.srcChainId
        });

        (success,) = message.to.call{value: message.callValue, gas: gasLimit}(message.data);

        state.ctx = IBridge.Context({
            msgHash: LibBridgeData.MESSAGE_HASH_PLACEHOLDER,
            sender: LibBridgeData.SRC_CHAIN_SENDER_PLACEHOLDER,
            srcChainId: LibBridgeData.CHAINID_PLACEHOLDER
        });
    }
}

// SPDX-License-Identifier: MIT
//  _____     _ _         _         _
// |_   _|_ _(_) |_____  | |   __ _| |__ ___
//   | |/ _` | | / / _ \ | |__/ _` | '_ (_-<
//   |_|\__,_|_|_\_\___/ |____\__,_|_.__/__/

pragma solidity ^0.8.18;

import {AddressResolver} from "../../common/AddressResolver.sol";
import {EtherVault} from "../EtherVault.sol";
import {IBridge} from "../IBridge.sol";
import {ISignalService} from "../../signal/ISignalService.sol";
import {LibAddress} from "../../libs/LibAddress.sol";
import {LibBridgeData} from "./LibBridgeData.sol";
import {LibBridgeInvoke} from "./LibBridgeInvoke.sol";
import {LibBridgeStatus} from "./LibBridgeStatus.sol";
import {LibMath} from "../../libs/LibMath.sol";

/**
 * Process bridge messages on the destination chain.
 * @title LibBridgeProcess
 */
library LibBridgeProcess {
    using LibMath for uint256;
    using LibAddress for address;
    using LibBridgeData for IBridge.Message;
    using LibBridgeData for LibBridgeData.State;

    error B_FORBIDDEN();
    error B_SIGNAL_NOT_RECEIVED();
    error B_STATUS_MISMATCH();
    error B_WRONG_CHAIN_ID();

    /**
     * Process the bridge message on the destination chain. It can be called by
     * any address, including `message.owner`. It starts by hashing the message,
     * and doing a lookup in the bridge state to see if the status is "NEW". It
     * then takes custody of the ether from the EtherVault and attempts to
     * invoke the messageCall, changing the message's status accordingly.
     * Finally, it refunds the processing fee if needed.
     * @param state The bridge state.
     * @param resolver The address resolver.
     * @param message The message to process.
     * @param proof The msgHash proof from the source chain.
     */
    function processMessage(
        LibBridgeData.State storage state,
        AddressResolver resolver,
        IBridge.Message calldata message,
        bytes calldata proof
    ) internal {
        // If the gas limit is set to zero, only the owner can process the message.
        if (message.gasLimit == 0 && msg.sender != message.owner) {
            revert B_FORBIDDEN();
        }

        if (message.destChainId != block.chainid) {
            revert B_WRONG_CHAIN_ID();
        }

        // The message status must be "NEW"; "RETRIABLE" is handled in
        // LibBridgeRetry.sol.
        bytes32 msgHash = message.hashMessage();
        if (LibBridgeStatus.getMessageStatus(msgHash) != LibBridgeStatus.MessageStatus.NEW) {
            revert B_STATUS_MISMATCH();
        }
        // Message must have been "received" on the destChain (current chain)
        address srcBridge = resolver.resolve(message.srcChainId, "bridge", false);

        if (
            !ISignalService(resolver.resolve("signal_service", false)).isSignalReceived({
                srcChainId: message.srcChainId,
                app: srcBridge,
                signal: msgHash,
                proof: proof
            })
        ) {
            revert B_SIGNAL_NOT_RECEIVED();
        }

        uint256 allValue = message.depositValue + message.callValue + message.processingFee;
        // We retrieve the necessary ether from EtherVault if receiving on
        // Taiko, otherwise it is already available in this Bridge.
        address ethVault = resolver.resolve("ether_vault", true);
        if (ethVault != address(0) && (allValue > 0)) {
            EtherVault(payable(ethVault)).releaseEther(allValue);
        }
        // We send the Ether before the message call in case the call will
        // actually consume Ether.
        message.owner.sendEther(message.depositValue);

        LibBridgeStatus.MessageStatus status;
        uint256 refundAmount;

        // if the user is sending to the bridge or zero-address, just process as DONE
        // and refund the owner
        if (message.to == address(this) || message.to == address(0)) {
            // For these two special addresses, the call will not be actually
            // invoked but will be marked DONE. The callValue will be refunded.
            status = LibBridgeStatus.MessageStatus.DONE;
            refundAmount = message.callValue;
        } else {
            // use the specified message gas limit if not called by the owner
            uint256 gasLimit = msg.sender == message.owner ? gasleft() : message.gasLimit;

            bool success = LibBridgeInvoke.invokeMessageCall({
                state: state,
                message: message,
                msgHash: msgHash,
                gasLimit: gasLimit
            });

            if (success) {
                status = LibBridgeStatus.MessageStatus.DONE;
            } else {
                status = LibBridgeStatus.MessageStatus.RETRIABLE;
                ethVault.sendEther(message.callValue);
            }
        }

        // Mark the status as DONE or RETRIABLE.
        LibBridgeStatus.updateMessageStatus(msgHash, status);

        address refundAddress =
            message.refundAddress == address(0) ? message.owner : message.refundAddress;

        // if sender is the refundAddress
        if (msg.sender == refundAddress) {
            uint256 amount = message.processingFee + refundAmount;
            refundAddress.sendEther(amount);
        } else {
            // if sender is another address (eg. the relayer)
            // First attempt relayer is rewarded the processingFee
            // message.owner has to eat the cost
            msg.sender.sendEther(message.processingFee);
            refundAddress.sendEther(refundAmount);
        }
    }
}

// SPDX-License-Identifier: MIT
//  _____     _ _         _         _
// |_   _|_ _(_) |_____  | |   __ _| |__ ___
//   | |/ _` | | / / _ \ | |__/ _` | '_ (_-<
//   |_|\__,_|_|_\_\___/ |____\__,_|_.__/__/

pragma solidity ^0.8.18;

import {AddressResolver} from "../../common/AddressResolver.sol";
import {EtherVault} from "../EtherVault.sol";
import {IBridge} from "../IBridge.sol";
import {LibBridgeData} from "./LibBridgeData.sol";
import {LibBridgeStatus} from "./LibBridgeStatus.sol";

library LibBridgeRelease {
    using LibBridgeData for IBridge.Message;

    event EtherReleased(bytes32 indexed msgHash, address to, uint256 amount);

    error B_ETHER_RELEASED_ALREADY();
    error B_FAILED_TRANSFER();
    error B_MSG_NOT_FAILED();
    error B_OWNER_IS_NULL();
    error B_WRONG_CHAIN_ID();

    /**
     * Release Ether to the message owner, only if the Taiko Bridge state says:
     * - Ether for this message has not been released before.
     * - The message is in a failed state.
     */
    function releaseEther(
        LibBridgeData.State storage state,
        AddressResolver resolver,
        IBridge.Message calldata message,
        bytes calldata proof
    ) internal {
        if (message.owner == address(0)) {
            revert B_OWNER_IS_NULL();
        }

        if (message.srcChainId != block.chainid) {
            revert B_WRONG_CHAIN_ID();
        }

        bytes32 msgHash = message.hashMessage();

        if (state.etherReleased[msgHash] == true) {
            revert B_ETHER_RELEASED_ALREADY();
        }

        if (!LibBridgeStatus.isMessageFailed(resolver, msgHash, message.destChainId, proof)) {
            revert B_MSG_NOT_FAILED();
        }

        state.etherReleased[msgHash] = true;

        uint256 releaseAmount = message.depositValue + message.callValue;

        if (releaseAmount > 0) {
            address ethVault = resolver.resolve("ether_vault", true);
            // if on Taiko
            if (ethVault != address(0)) {
                EtherVault(payable(ethVault)).releaseEther(message.owner, releaseAmount);
            } else {
                // if on Ethereum
                (bool success,) = message.owner.call{value: releaseAmount}("");
                if (!success) {
                    revert B_FAILED_TRANSFER();
                }
            }
        }
        emit EtherReleased(msgHash, message.owner, releaseAmount);
    }
}

// SPDX-License-Identifier: MIT
//  _____     _ _         _         _
// |_   _|_ _(_) |_____  | |   __ _| |__ ___
//   | |/ _` | | / / _ \ | |__/ _` | '_ (_-<
//   |_|\__,_|_|_\_\___/ |____\__,_|_.__/__/

pragma solidity ^0.8.18;

import {AddressResolver} from "../../common/AddressResolver.sol";
import {EtherVault} from "../EtherVault.sol";
import {IBridge} from "../IBridge.sol";
import {LibAddress} from "../../libs/LibAddress.sol";
import {LibBridgeData} from "./LibBridgeData.sol";
import {LibBridgeInvoke} from "./LibBridgeInvoke.sol";
import {LibBridgeStatus} from "./LibBridgeStatus.sol";

/**
 * Retry bridge messages.
 * @title LibBridgeRetry
 */
library LibBridgeRetry {
    using LibAddress for address;
    using LibBridgeData for IBridge.Message;
    using LibBridgeData for LibBridgeData.State;

    error B_DENIED();
    error B_MSG_NON_RETRIABLE();

    /**
     * Retries to invoke the messageCall, the owner has already been sent Ether.
     * - This function can be called by any address, including `message.owner`.
     * - Can only be called on messages marked "RETRIABLE".
     * - It attempts to reinvoke the messageCall.
     * - If it succeeds, the message is marked as "DONE".
     * - If it fails and `isLastAttempt` is set to true, the message is marked
     *   as "FAILED" and cannot be retried.
     * @param state The bridge state.
     * @param resolver The address resolver.
     * @param message The message to retry.
     * @param isLastAttempt Specifies if this is the last attempt to retry the
     * message.
     */
    function retryMessage(
        LibBridgeData.State storage state,
        AddressResolver resolver,
        IBridge.Message calldata message,
        bool isLastAttempt
    ) internal {
        // If the gasLimit is not set to 0 or isLastAttempt is true, the
        // address calling this function must be message.owner.
        if (message.gasLimit == 0 || isLastAttempt) {
            if (msg.sender != message.owner) revert B_DENIED();
        }

        bytes32 msgHash = message.hashMessage();
        if (LibBridgeStatus.getMessageStatus(msgHash) != LibBridgeStatus.MessageStatus.RETRIABLE) {
            revert B_MSG_NON_RETRIABLE();
        }

        address ethVault = resolver.resolve("ether_vault", true);
        if (ethVault != address(0)) {
            EtherVault(payable(ethVault)).releaseEther(message.callValue);
        }

        // successful invocation
        if (
            LibBridgeInvoke
                // The message.gasLimit only apply for processMessage, if it fails
                // then whoever calls retryMessage will use the tx's gasLimit.
                .invokeMessageCall({
                state: state,
                message: message,
                msgHash: msgHash,
                gasLimit: gasleft()
            })
        ) {
            LibBridgeStatus.updateMessageStatus(msgHash, LibBridgeStatus.MessageStatus.DONE);
        } else if (isLastAttempt) {
            LibBridgeStatus.updateMessageStatus(msgHash, LibBridgeStatus.MessageStatus.FAILED);

            address refundAddress =
                message.refundAddress == address(0) ? message.owner : message.refundAddress;

            refundAddress.sendEther(message.callValue);
        } else {
            ethVault.sendEther(message.callValue);
        }
    }
}

// SPDX-License-Identifier: MIT
//  _____     _ _         _         _
// |_   _|_ _(_) |_____  | |   __ _| |__ ___
//   | |/ _` | | / / _ \ | |__/ _` | '_ (_-<
//   |_|\__,_|_|_\_\___/ |____\__,_|_.__/__/

pragma solidity ^0.8.18;

import {AddressResolver} from "../../common/AddressResolver.sol";
import {IBridge} from "../IBridge.sol";
import {ISignalService} from "../../signal/ISignalService.sol";
import {LibAddress} from "../../libs/LibAddress.sol";
import {LibBridgeData} from "./LibBridgeData.sol";

/**
 * Entry point for starting a bridge transaction.
 *
 * @title LibBridgeSend
 */
library LibBridgeSend {
    using LibAddress for address;
    using LibBridgeData for IBridge.Message;

    error B_INCORRECT_VALUE();
    error B_OWNER_IS_NULL();
    error B_WRONG_CHAIN_ID();
    error B_WRONG_TO_ADDRESS();

    /**
     * Send a message to the Bridge with the details of the request. The Bridge
     * takes custody of the funds, unless the source chain is Taiko, in which
     * the funds are sent to and managed by the EtherVault.
     *
     * @param message Specifies the `depositValue`, `callValue`,
     * and `processingFee`. These must sum to `msg.value`. It also specifies the
     * `destChainId` which must have a `bridge` address set on the
     * AddressResolver and differ from the current chain ID.
     *
     * @return msgHash The hash of message sent.
     * This is picked up by an off-chain relayer which indicates a
     * bridge message has been sent and is ready to be processed on the
     * destination chain.
     */
    function sendMessage(
        LibBridgeData.State storage state,
        AddressResolver resolver,
        IBridge.Message memory message
    ) internal returns (bytes32 msgHash) {
        if (message.owner == address(0)) {
            revert B_OWNER_IS_NULL();
        }

        (bool destChainEnabled, address destChain) =
            isDestChainEnabled(resolver, message.destChainId);

        if (!destChainEnabled || message.destChainId == block.chainid) {
            revert B_WRONG_CHAIN_ID();
        }
        if (message.to == address(0) || message.to == destChain) {
            revert B_WRONG_TO_ADDRESS();
        }

        uint256 expectedAmount = message.depositValue + message.callValue + message.processingFee;

        if (expectedAmount != msg.value) {
            revert B_INCORRECT_VALUE();
        }

        // If on Taiko, send the expectedAmount to the EtherVault. Otherwise,
        // store it here on the Bridge. Processing will release Ether from the
        // EtherVault or the Bridge on the destination chain.
        address ethVault = resolver.resolve("ether_vault", true);
        ethVault.sendEther(expectedAmount);

        message.id = state.nextMessageId++;
        message.sender = msg.sender;
        message.srcChainId = block.chainid;

        msgHash = message.hashMessage();
        // Store a key which is the hash of this contract address and the
        // msgHash, with a value of 1.
        ISignalService(resolver.resolve("signal_service", false)).sendSignal(msgHash);
        emit LibBridgeData.MessageSent(msgHash, message);
    }

    function isDestChainEnabled(AddressResolver resolver, uint256 chainId)
        internal
        view
        returns (bool enabled, address destBridge)
    {
        destBridge = resolver.resolve(chainId, "bridge", true);
        enabled = destBridge != address(0);
    }

    function isMessageSent(AddressResolver resolver, bytes32 msgHash)
        internal
        view
        returns (bool)
    {
        return ISignalService(resolver.resolve("signal_service", false)).isSignalSent({
            app: address(this),
            signal: msgHash
        });
    }

    function isMessageReceived(
        AddressResolver resolver,
        bytes32 msgHash,
        uint256 srcChainId,
        bytes calldata proof
    ) internal view returns (bool) {
        address srcBridge = resolver.resolve(srcChainId, "bridge", false);
        return ISignalService(resolver.resolve("signal_service", false)).isSignalReceived({
            srcChainId: srcChainId,
            app: srcBridge,
            signal: msgHash,
            proof: proof
        });
    }
}

// SPDX-License-Identifier: MIT
//  _____     _ _         _         _
// |_   _|_ _(_) |_____  | |   __ _| |__ ___
//   | |/ _` | | / / _ \ | |__/ _` | '_ (_-<
//   |_|\__,_|_|_\_\___/ |____\__,_|_.__/__/

pragma solidity ^0.8.18;

import {AddressResolver} from "../../common/AddressResolver.sol";
import {BlockHeader, LibBlockHeader} from "../../libs/LibBlockHeader.sol";
import {ICrossChainSync} from "../../common/ICrossChainSync.sol";
import {LibBridgeData} from "./LibBridgeData.sol";
import {LibTrieProof} from "../../libs/LibTrieProof.sol";

library LibBridgeStatus {
    using LibBlockHeader for BlockHeader;

    enum MessageStatus {
        NEW,
        RETRIABLE,
        DONE,
        FAILED
    }

    event MessageStatusChanged(bytes32 indexed msgHash, MessageStatus status, address transactor);

    error B_MSG_HASH_NULL();
    error B_WRONG_CHAIN_ID();

    /**
     * @dev If messageStatus is same as in the messageStatus mapping,
     *      does nothing.
     * @param msgHash The messageHash of the message.
     * @param status The status of the message.
     */
    function updateMessageStatus(bytes32 msgHash, MessageStatus status) internal {
        if (getMessageStatus(msgHash) != status) {
            _setMessageStatus(msgHash, status);
            emit MessageStatusChanged(msgHash, status, msg.sender);
        }
    }

    function getMessageStatus(bytes32 msgHash) internal view returns (MessageStatus) {
        bytes32 slot = getMessageStatusSlot(msgHash);
        uint256 value;
        assembly {
            value := sload(slot)
        }
        return MessageStatus(value);
    }

    function isMessageFailed(
        AddressResolver resolver,
        bytes32 msgHash,
        uint256 destChainId,
        bytes calldata proof
    ) internal view returns (bool) {
        if (destChainId == block.chainid) {
            revert B_WRONG_CHAIN_ID();
        }
        if (msgHash == 0x0) {
            revert B_MSG_HASH_NULL();
        }

        LibBridgeData.StatusProof memory sp = abi.decode(proof, (LibBridgeData.StatusProof));

        bytes32 syncedHeaderHash = ICrossChainSync(resolver.resolve("taiko", false))
            .getCrossChainBlockHash(sp.header.height);

        if (syncedHeaderHash == 0 || syncedHeaderHash != sp.header.hashBlockHeader()) {
            return false;
        }

        return LibTrieProof.verifyWithAccountProof({
            stateRoot: sp.header.stateRoot,
            addr: resolver.resolve(destChainId, "bridge", false),
            slot: getMessageStatusSlot(msgHash),
            value: bytes32(uint256(LibBridgeStatus.MessageStatus.FAILED)),
            mkproof: sp.proof
        });
    }

    function getMessageStatusSlot(bytes32 msgHash) internal pure returns (bytes32) {
        return keccak256(bytes.concat(bytes("MESSAGE_STATUS"), msgHash));
    }

    function _setMessageStatus(bytes32 msgHash, MessageStatus status) private {
        bytes32 slot = getMessageStatusSlot(msgHash);
        uint256 value = uint256(status);
        assembly {
            sstore(slot, value)
        }
    }
}

// SPDX-License-Identifier: MIT
//  _____     _ _         _         _
// |_   _|_ _(_) |_____  | |   __ _| |__ ___
//   | |/ _` | | / / _ \ | |__/ _` | '_ (_-<
//   |_|\__,_|_|_\_\___/ |____\__,_|_.__/__/

pragma solidity ^0.8.18;

import {
    IERC20Upgradeable,
    ERC20Upgradeable
} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {SafeERC20Upgradeable} from
    "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {Create2Upgradeable} from "lib/openzeppelin-contracts-upgradeable/contracts/utils/Create2Upgradeable.sol";
import {EssentialContract} from "../common/EssentialContract.sol";
import {Proxied} from "../common/Proxied.sol";
import {TaikoToken} from "../L1/TaikoToken.sol";
import {BridgedERC20} from "./BridgedERC20.sol";
import {IBridge} from "./IBridge.sol";
import {Strings} from "lib/openzeppelin-contracts/contracts/utils/Strings.sol";

/**
 * This vault holds all ERC20 tokens (but not Ether) that users have deposited.
 * It also manages the mapping between canonical ERC20 tokens and their bridged
 * tokens.
 * @dev Ether is held by Bridges on L1 and by the EtherVault on L2,
 *      not TokenVaults.
 * @custom:security-contact [email protected]
 */
contract TokenVault is EssentialContract {
    using SafeERC20Upgradeable for ERC20Upgradeable;

    /*//////////////////////////////////////////////////////////////
                                STRUCTS
    //////////////////////////////////////////////////////////////*/

    struct CanonicalERC20 {
        uint256 chainId;
        address addr;
        uint8 decimals;
        string symbol;
        string name;
    }

    struct MessageDeposit {
        address token;
        uint256 amount;
    }

    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    // Tracks if a token on the current chain is a canonical or bridged token.
    mapping(address tokenAddress => bool isBridged) public isBridgedToken;

    // Mappings from bridged tokens to their canonical tokens.
    mapping(address bridgedAddress => CanonicalERC20 canonicalErc20) public bridgedToCanonical;

    // Mappings from canonical tokens to their bridged tokens.
    // Also storing chainId for tokens across other chains aside from Ethereum.
    mapping(uint256 chainId => mapping(address canonicalAddress => address bridgedAddress)) public
        canonicalToBridged;

    // Tracks the token and amount associated with a message hash.
    mapping(bytes32 msgHash => MessageDeposit messageDeposit) public messageDeposits;

    uint256[47] private __gap;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event BridgedERC20Deployed(
        uint256 indexed srcChainId,
        address indexed canonicalToken,
        address indexed bridgedToken,
        string canonicalTokenSymbol,
        string canonicalTokenName,
        uint8 canonicalTokenDecimal
    );

    event EtherSent(
        bytes32 indexed msgHash,
        address indexed from,
        address indexed to,
        uint256 destChainId,
        uint256 amount
    );

    event ERC20Sent(
        bytes32 indexed msgHash,
        address indexed from,
        address indexed to,
        uint256 destChainId,
        address token,
        uint256 amount
    );

    event ERC20Released(
        bytes32 indexed msgHash, address indexed from, address token, uint256 amount
    );

    event ERC20Received(
        bytes32 indexed msgHash,
        address indexed from,
        address indexed to,
        uint256 srcChainId,
        address token,
        uint256 amount
    );

    /*//////////////////////////////////////////////////////////////
                             CUSTOM ERRORS
    //////////////////////////////////////////////////////////////*/

    error TOKENVAULT_INVALID_TO();
    error TOKENVAULT_INVALID_VALUE();
    error TOKENVAULT_INVALID_TOKEN();
    error TOKENVAULT_INVALID_AMOUNT();
    error TOKENVAULT_CANONICAL_TOKEN_NOT_FOUND();
    error TOKENVAULT_INVALID_OWNER();
    error TOKENVAULT_INVALID_SRC_CHAIN_ID();
    error TOKENVAULT_MESSAGE_NOT_FAILED();
    error TOKENVAULT_INVALID_SENDER();

    /*//////////////////////////////////////////////////////////////
                         USER-FACING FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function init(address addressManager) external initializer {
        EssentialContract._init(addressManager);
    }

    /**
     * Transfers ERC20 tokens to this vault and sends a message to the
     * destination chain so the user can receive the same amount of tokens
     * by invoking the message call.
     *
     * @param destChainId @custom:see IBridge.Message
     * @param to @custom:see IBridge.Message
     * @param token The address of the token to be sent.
     * @param amount The amount of token to be transferred.
     * @param gasLimit @custom:see IBridge.Message
     * @param processingFee @custom:see IBridge.Message
     * @param refundAddress @custom:see IBridge.Message
     * @param memo @custom:see IBridge.Message
     */
    function sendERC20(
        uint256 destChainId,
        address to,
        address token,
        uint256 amount,
        uint256 gasLimit,
        uint256 processingFee,
        address refundAddress,
        string memory memo
    ) external payable nonReentrant {
        if (to == address(0) || to == resolve(destChainId, "token_vault", false)) {
            revert TOKENVAULT_INVALID_TO();
        }

        if (token == address(0)) revert TOKENVAULT_INVALID_TOKEN();

        if (amount == 0) revert TOKENVAULT_INVALID_AMOUNT();

        CanonicalERC20 memory canonicalToken;
        uint256 _amount;

        // is a bridged token, meaning, it does not live on this chain
        if (isBridgedToken[token]) {
            BridgedERC20(token).bridgeBurnFrom(msg.sender, amount);
            canonicalToken = bridgedToCanonical[token];
            if (canonicalToken.addr == address(0)) {
                revert TOKENVAULT_CANONICAL_TOKEN_NOT_FOUND();
            }
            _amount = amount;
        } else {
            // is a canonical token, meaning, it lives on this chain
            ERC20Upgradeable t = ERC20Upgradeable(token);
            canonicalToken = CanonicalERC20({
                chainId: block.chainid,
                addr: token,
                decimals: t.decimals(),
                symbol: t.symbol(),
                name: t.name()
            });

            uint256 _balance = t.balanceOf(address(this));
            t.safeTransferFrom(msg.sender, address(this), amount);
            _amount = t.balanceOf(address(this)) - _balance;
        }

        IBridge.Message memory message;
        message.destChainId = destChainId;
        message.owner = msg.sender;
        message.to = resolve(destChainId, "token_vault", false);
        message.data = abi.encodeWithSelector(
            TokenVault.receiveERC20.selector, canonicalToken, message.owner, to, _amount
        );
        message.gasLimit = gasLimit;
        message.processingFee = processingFee;
        message.depositValue = msg.value - processingFee;
        message.refundAddress = refundAddress;
        message.memo = memo;

        bytes32 msgHash = IBridge(resolve("bridge", false)).sendMessage{value: msg.value}(message);

        // record the deposit for this message
        messageDeposits[msgHash] = MessageDeposit(token, _amount);

        emit ERC20Sent({
            msgHash: msgHash,
            from: message.owner,
            to: to,
            destChainId: destChainId,
            token: token,
            amount: _amount
        });
    }

    /**
     * Release deposited ERC20 back to the owner on the source TokenVault with
     * a proof that the message processing on the destination Bridge has failed.
     *
     * @param message The message that corresponds the ERC20 deposit on the
     * source chain.
     * @param proof The proof from the destination chain to show the message
     * has failed.
     */
    function releaseERC20(IBridge.Message calldata message, bytes calldata proof)
        external
        nonReentrant
    {
        if (message.owner == address(0)) revert TOKENVAULT_INVALID_OWNER();
        if (message.srcChainId != block.chainid) {
            revert TOKENVAULT_INVALID_SRC_CHAIN_ID();
        }

        IBridge bridge = IBridge(resolve("bridge", false));
        bytes32 msgHash = bridge.hashMessage(message);

        address token = messageDeposits[msgHash].token;
        uint256 amount = messageDeposits[msgHash].amount;
        if (token == address(0)) revert TOKENVAULT_INVALID_TOKEN();

        if (!bridge.isMessageFailed(msgHash, message.destChainId, proof)) {
            revert TOKENVAULT_MESSAGE_NOT_FAILED();
        }
        messageDeposits[msgHash] = MessageDeposit(address(0), 0);

        if (amount > 0) {
            if (isBridgedToken[token]) {
                BridgedERC20(token).bridgeMintTo(message.owner, amount);
            } else {
                ERC20Upgradeable(token).safeTransfer(message.owner, amount);
            }
        }

        emit ERC20Released({msgHash: msgHash, from: message.owner, token: token, amount: amount});
    }

    /**
     * @dev This function can only be called by the bridge contract while
     * invoking a message call. See sendERC20, which sets the data to invoke
     * this function.
     * @param canonicalToken The canonical ERC20 token which may or may not
     * live on this chain. If not, a BridgedERC20 contract will be
     * deployed.
     * @param from The source address.
     * @param to The destination address.
     * @param amount The amount of tokens to be sent. 0 is a valid value.
     */
    function receiveERC20(
        CanonicalERC20 calldata canonicalToken,
        address from,
        address to,
        uint256 amount
    ) external nonReentrant onlyFromNamed("bridge") {
        IBridge.Context memory ctx = IBridge(msg.sender).context();
        if (ctx.sender != resolve(ctx.srcChainId, "token_vault", false)) {
            revert TOKENVAULT_INVALID_SENDER();
        }

        address token;
        if (canonicalToken.chainId == block.chainid) {
            token = canonicalToken.addr;
            ERC20Upgradeable(token).safeTransfer(to, amount);
        } else {
            token = _getOrDeployBridgedToken(canonicalToken);
            BridgedERC20(token).bridgeMintTo(to, amount);
        }

        emit ERC20Received({
            msgHash: ctx.msgHash,
            from: from,
            to: to,
            srcChainId: ctx.srcChainId,
            token: token,
            amount: amount
        });
    }

    /*//////////////////////////////////////////////////////////////
                           PRIVATE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function _getOrDeployBridgedToken(CanonicalERC20 calldata canonicalToken)
        private
        returns (address)
    {
        address token = canonicalToBridged[canonicalToken.chainId][canonicalToken.addr];

        return token != address(0) ? token : _deployBridgedToken(canonicalToken);
    }

    /**
     * @dev Deploys a new BridgedERC20 contract and initializes it. This must be
     * called before the first time a bridged token is sent to this chain.
     */
    function _deployBridgedToken(CanonicalERC20 calldata canonicalToken)
        private
        returns (address bridgedToken)
    {
        bridgedToken = Create2Upgradeable.deploy(
            0, // amount of Ether to send
            keccak256(
                bytes.concat(
                    bytes32(canonicalToken.chainId), bytes32(uint256(uint160(canonicalToken.addr)))
                )
            ),
            type(BridgedERC20).creationCode
        );

        BridgedERC20(payable(bridgedToken)).init({
            _addressManager: address(_addressManager),
            _srcToken: canonicalToken.addr,
            _srcChainId: canonicalToken.chainId,
            _decimals: canonicalToken.decimals,
            _symbol: canonicalToken.symbol,
            _name: string.concat(
                canonicalToken.name,
                unicode"(bridged🌈",
                Strings.toString(canonicalToken.chainId),
                ")"
                )
        });

        isBridgedToken[bridgedToken] = true;
        bridgedToCanonical[bridgedToken] = canonicalToken;
        canonicalToBridged[canonicalToken.chainId][canonicalToken.addr] = bridgedToken;

        emit BridgedERC20Deployed({
            srcChainId: canonicalToken.chainId,
            canonicalToken: canonicalToken.addr,
            bridgedToken: bridgedToken,
            canonicalTokenSymbol: canonicalToken.symbol,
            canonicalTokenName: canonicalToken.name,
            canonicalTokenDecimal: canonicalToken.decimals
        });
    }
}

contract ProxiedTokenVault is Proxied, TokenVault {}

// SPDX-License-Identifier: MIT
//  _____     _ _         _         _
// |_   _|_ _(_) |_____  | |   __ _| |__ ___
//   | |/ _` | | / / _ \ | |__/ _` | '_ (_-<
//   |_|\__,_|_|_\_\___/ |____\__,_|_.__/__/

pragma solidity ^0.8.18;

import {OwnableUpgradeable} from "lib/openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import {Proxied} from "./Proxied.sol";

/**
 * @notice Interface to set and get an address for a name.
 */
interface IAddressManager {
    /**
     * Changes the address associated with a particular name.
     * @param domain Uint256 domain to assiciate an address with.
     * @param name Name to associate an address with.
     * @param newAddress Address to associate with the name.
     */
    function setAddress(uint256 domain, bytes32 name, address newAddress) external;

    /**
     * Retrieves the address associated with a given name.
     * @param domain Class to retrieve an address for.
     * @param name Name to retrieve an address for.
     * @return Address associated with the given name.
     */
    function getAddress(uint256 domain, bytes32 name) external view returns (address);
}

/// @custom:security-contact [email protected]
contract AddressManager is OwnableUpgradeable, IAddressManager {
    mapping(uint256 domain => mapping(bytes32 name => address addr)) private addresses;

    event AddressSet(
        uint256 indexed _domain, bytes32 indexed _name, address _newAddress, address _oldAddress
    );

    error EOAOwnerAddressNotAllowed();

    /// @dev Initializer to be called after being deployed behind a proxy.
    function init() external initializer {
        OwnableUpgradeable.__Ownable_init();
    }

    function setAddress(uint256 domain, bytes32 name, address newAddress)
        external
        virtual
        onlyOwner
    {
        // This is to prevent using the owner as named address
        if (newAddress.code.length == 0 && newAddress == msg.sender) {
            revert EOAOwnerAddressNotAllowed();
        }

        address oldAddress = addresses[domain][name];
        addresses[domain][name] = newAddress;
        emit AddressSet(domain, name, newAddress, oldAddress);
    }

    function getAddress(uint256 domain, bytes32 name)
        external
        view
        virtual
        returns (address addr)
    {
        addr = addresses[domain][name];
    }
}

contract ProxiedAddressManager is Proxied, AddressManager {}

// SPDX-License-Identifier: MIT
//  _____     _ _         _         _
// |_   _|_ _(_) |_____  | |   __ _| |__ ___
//   | |/ _` | | / / _ \ | |__/ _` | '_ (_-<
//   |_|\__,_|_|_\_\___/ |____\__,_|_.__/__/

pragma solidity ^0.8.18;

import {IAddressManager} from "./AddressManager.sol";
import {Strings} from "lib/openzeppelin-contracts/contracts/utils/Strings.sol";

/**
 * This abstract contract provides a name-to-address lookup. Under the hood,
 * it uses an AddressManager to manage the name-to-address mapping.
 *
 * @title AddressResolver
 */
abstract contract AddressResolver {
    IAddressManager internal _addressManager;

    uint256[49] private __gap;

    error RESOLVER_DENIED();
    error RESOLVER_INVALID_ADDR();
    error RESOLVER_ZERO_ADDR(uint256 chainId, bytes32 name);

    modifier onlyFromNamed(bytes32 name) {
        if (msg.sender != resolve(name, false)) revert RESOLVER_DENIED();
        _;
    }

    event AddressManagerChanged(address addressManager);

    /**
     * Resolves a name to an address on the current chain.
     *
     * @dev This function will throw if the resolved address is `address(0)`.
     * @param name The name to resolve.
     * @param allowZeroAddress True to allow zero address to be returned.
     * @return The name's corresponding address.
     */
    function resolve(bytes32 name, bool allowZeroAddress)
        public
        view
        virtual
        returns (address payable)
    {
        return _resolve(block.chainid, name, allowZeroAddress);
    }

    /**
     * Resolves a name to an address on the specified chain.
     *
     * @dev This function will throw if the resolved address is `address(0)`.
     * @param chainId The chainId.
     * @param name The name to resolve.
     * @param allowZeroAddress True to allow zero address to be returned.
     * @return The name's corresponding address.
     */
    function resolve(uint256 chainId, bytes32 name, bool allowZeroAddress)
        public
        view
        virtual
        returns (address payable)
    {
        return _resolve(chainId, name, allowZeroAddress);
    }

    /**
     * Returns the AddressManager's address.
     *
     * @return The AddressManager's address.
     */
    function addressManager() public view returns (address) {
        return address(_addressManager);
    }

    function _init(address addressManager_) internal virtual {
        if (addressManager_ == address(0)) revert RESOLVER_INVALID_ADDR();
        _addressManager = IAddressManager(addressManager_);
    }

    function _resolve(uint256 chainId, bytes32 name, bool allowZeroAddress)
        private
        view
        returns (address payable addr)
    {
        addr = payable(_addressManager.getAddress(chainId, name));

        if (!allowZeroAddress && addr == address(0)) {
            revert RESOLVER_ZERO_ADDR(chainId, name);
        }
    }
}

// SPDX-License-Identifier: MIT
//  _____     _ _         _         _
// |_   _|_ _(_) |_____  | |   __ _| |__ ___
//   | |/ _` | | / / _ \ | |__/ _` | '_ (_-<
//   |_|\__,_|_|_\_\___/ |____\__,_|_.__/__/

pragma solidity ^0.8.18;

import {IAddressManager} from "./AddressManager.sol";
import {OwnableUpgradeable} from "lib/openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from
    "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {AddressResolver} from "./AddressResolver.sol";

/**
 * @dev This abstract contract serves as the base contract for many core
 *      components in this package.
 */
abstract contract EssentialContract is
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable,
    AddressResolver
{
    function _init(address _addressManager) internal virtual override {
        ReentrancyGuardUpgradeable.__ReentrancyGuard_init();
        OwnableUpgradeable.__Ownable_init();
        AddressResolver._init(_addressManager);
    }

    /**
     * Sets a new AddressManager's address.
     *
     * @param newAddressManager New address manager contract address
     */
    function setAddressManager(address newAddressManager) external onlyOwner {
        if (newAddressManager == address(0)) revert RESOLVER_INVALID_ADDR();
        _addressManager = IAddressManager(newAddressManager);

        emit AddressManagerChanged(newAddressManager);
    }
}

// SPDX-License-Identifier: MIT
//  _____     _ _         _         _
// |_   _|_ _(_) |_____  | |   __ _| |__ ___
//   | |/ _` | | / / _ \ | |__/ _` | '_ (_-<
//   |_|\__,_|_|_\_\___/ |____\__,_|_.__/__/

pragma solidity ^0.8.18;

/**
 * Interface implemented by both the TaikoL1 and TaikoL2 contracts. It exposes
 * the methods needed to access the block hashes of the other chain.
 */

interface ICrossChainSync {
    event CrossChainSynced(uint256 indexed srcHeight, bytes32 blockHash, bytes32 signalRoot);

    /**
     * @notice Returns the cross-chain block hash at the given block number.
     * @param number The block number. Use 0 for the latest block.
     * @return The cross-chain block hash.
     */
    function getCrossChainBlockHash(uint256 number) external view returns (bytes32);

    /**
     * @notice Returns the cross-chain signal service storage root at the given
     *         block number.
     * @param number The block number. Use 0 for the latest block.
     * @return The cross-chain signal service storage root.
     */
    function getCrossChainSignalRoot(uint256 number) external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
//  _____     _ _         _         _
// |_   _|_ _(_) |_____  | |   __ _| |__ ___
//   | |/ _` | | / / _ \ | |__/ _` | '_ (_-<
//   |_|\__,_|_|_\_\___/ |____\__,_|_.__/__/

pragma solidity ^0.8.18;

import {IERC20Upgradeable} from
    "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface IMintableERC20 is IERC20Upgradeable {
    function mint(address account, uint256 amount) external;

    function burn(address account, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
//  _____     _ _         _         _
// |_   _|_ _(_) |_____  | |   __ _| |__ ___
//   | |/ _` | | / / _ \ | |__/ _` | '_ (_-<
//   |_|\__,_|_|_\_\___/ |____\__,_|_.__/__/

pragma solidity ^0.8.18;

import {Initializable} from "lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";

abstract contract Proxied is Initializable {
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }
}

// SPDX-License-Identifier: MIT
//  _____     _ _         _         _
// |_   _|_ _(_) |_____  | |   __ _| |__ ___
//   | |/ _` | | / / _ \ | |__/ _` | '_ (_-<
//   |_|\__,_|_|_\_\___/ |____\__,_|_.__/__/

pragma solidity ^0.8.18;

import {
    GovernorUpgradeable,
    IGovernorUpgradeable
} from "@openzeppelin/contracts-upgradeable/governance/GovernorUpgradeable.sol";
import {GovernorSettingsUpgradeable} from
    "@openzeppelin/contracts-upgradeable/governance/extensions/GovernorSettingsUpgradeable.sol";
import {GovernorCountingSimpleUpgradeable} from
    "@openzeppelin/contracts-upgradeable/governance/extensions/GovernorCountingSimpleUpgradeable.sol";
import {GovernorVotesUpgradeable} from
    "@openzeppelin/contracts-upgradeable/governance/extensions/GovernorVotesUpgradeable.sol";
import {
    GovernorVotesQuorumFractionUpgradeable,
    IVotesUpgradeable
} from
    "@openzeppelin/contracts-upgradeable/governance/extensions/GovernorVotesQuorumFractionUpgradeable.sol";
import {
    GovernorTimelockControlUpgradeable,
    TimelockControllerUpgradeable
} from
    "@openzeppelin/contracts-upgradeable/governance/extensions/GovernorTimelockControlUpgradeable.sol";
import {Initializable} from "lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "lib/openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";

import {LibTaikoTokenConfig} from "../L1/TaikoToken.sol";
import {EssentialContract} from "../common/EssentialContract.sol";
import {Proxied} from "../common/Proxied.sol";

/// @custom:security-contact [email protected]
contract TaikoGovernor is
    EssentialContract,
    GovernorUpgradeable,
    GovernorSettingsUpgradeable,
    GovernorCountingSimpleUpgradeable,
    GovernorVotesUpgradeable,
    GovernorVotesQuorumFractionUpgradeable,
    GovernorTimelockControlUpgradeable
{
    /*//////////////////////////////////////////////////////////////
                         USER-FACING FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function init(
        address _addressManager,
        IVotesUpgradeable _token,
        TimelockControllerUpgradeable _timelock
    ) public initializer {
        EssentialContract._init(_addressManager);

        __Governor_init("TaikoGovernor");
        __GovernorSettings_init(1, /* 1 block */ 100800, /* 2 week */ LibTaikoTokenConfig.DECIMALS);
        __GovernorCountingSimple_init();
        __GovernorVotes_init(_token);
        __GovernorVotesQuorumFraction_init(5);
        __GovernorTimelockControl_init(_timelock);
    }

    // The following functions are overrides required by Solidity.
    function propose(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        string memory description
    ) public override(GovernorUpgradeable, IGovernorUpgradeable) returns (uint256) {
        return super.propose(targets, values, calldatas, description);
    }

    function votingDelay()
        public
        view
        override(IGovernorUpgradeable, GovernorSettingsUpgradeable)
        returns (uint256)
    {
        return super.votingDelay();
    }

    function votingPeriod()
        public
        view
        override(IGovernorUpgradeable, GovernorSettingsUpgradeable)
        returns (uint256)
    {
        return super.votingPeriod();
    }

    function quorum(uint256 blockNumber)
        public
        view
        override(IGovernorUpgradeable, GovernorVotesQuorumFractionUpgradeable)
        returns (uint256)
    {
        return super.quorum(blockNumber);
    }

    function state(uint256 proposalId)
        public
        view
        override(GovernorUpgradeable, GovernorTimelockControlUpgradeable)
        returns (ProposalState)
    {
        return super.state(proposalId);
    }

    function proposalThreshold()
        public
        view
        override(GovernorUpgradeable, GovernorSettingsUpgradeable)
        returns (uint256)
    {
        return super.proposalThreshold();
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(GovernorUpgradeable, GovernorTimelockControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /*//////////////////////////////////////////////////////////////
                           INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function _execute(
        uint256 proposalId,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) internal override(GovernorUpgradeable, GovernorTimelockControlUpgradeable) {
        super._execute(proposalId, targets, values, calldatas, descriptionHash);
    }

    function _cancel(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    )
        internal
        override(GovernorUpgradeable, GovernorTimelockControlUpgradeable)
        returns (uint256)
    {
        return super._cancel(targets, values, calldatas, descriptionHash);
    }

    function _executor()
        internal
        view
        override(GovernorUpgradeable, GovernorTimelockControlUpgradeable)
        returns (address)
    {
        return super._executor();
    }
}

contract ProxiedTaikoGovernor is Proxied, TaikoGovernor {}

// SPDX-License-Identifier: MIT
//  _____     _ _         _         _
// |_   _|_ _(_) |_____  | |   __ _| |__ ___
//   | |/ _` | | / / _ \ | |__/ _` | '_ (_-<
//   |_|\__,_|_|_\_\___/ |____\__,_|_.__/__/

pragma solidity ^0.8.18;

import {LibAddress} from "../../libs/LibAddress.sol";
import {LibMath} from "../../libs/LibMath.sol";
import {AddressResolver} from "../../common/AddressResolver.sol";
import {SafeCastUpgradeable} from
    "@openzeppelin/contracts-upgradeable/utils/math/SafeCastUpgradeable.sol";
import {TaikoData} from "../TaikoData.sol";

library LibEthDepositing {
    using LibAddress for address;
    using LibMath for uint256;
    using SafeCastUpgradeable for uint256;

    event EthDeposited(TaikoData.EthDeposit deposit);

    error L1_INVALID_ETH_DEPOSIT();

    function depositEtherToL2(
        TaikoData.State storage state,
        TaikoData.Config memory config,
        AddressResolver resolver
    ) internal {
        if (msg.value < config.minEthDepositAmount || msg.value > config.maxEthDepositAmount) {
            revert L1_INVALID_ETH_DEPOSIT();
        }

        TaikoData.EthDeposit memory deposit =
            TaikoData.EthDeposit({recipient: msg.sender, amount: uint96(msg.value)});

        address to = resolver.resolve("ether_vault", true);
        if (to == address(0)) {
            to = resolver.resolve("bridge", false);
        }
        to.sendEther(msg.value);

        state.ethDeposits.push(deposit);
        emit EthDeposited(deposit);
    }

    function processDeposits(
        TaikoData.State storage state,
        TaikoData.Config memory config,
        address beneficiary
    ) internal returns (TaikoData.EthDeposit[] memory depositsProcessed) {
        // Allocate one extra slot for collecting fees on L2
        depositsProcessed = new TaikoData.EthDeposit[](
            config.maxEthDepositsPerBlock + 1
        );

        uint256 j; // number of deposits to process on L2
        if (
            state.ethDeposits.length
                >= state.nextEthDepositToProcess + config.minEthDepositsPerBlock
        ) {
            unchecked {
                // When maxEthDepositsPerBlock is 32, the average gas cost per
                // EthDeposit is about 2700 gas. We use 21000 so the proposer may
                // earn a small profit if there are 32 deposits included
                // in the block; if there are less EthDeposit to process, the
                // proposer may suffer a loss so the proposer should simply wait
                // for more EthDeposit be become available.
                uint96 feePerDeposit =
                    uint96(config.ethDepositMaxFee.min(block.basefee * config.ethDepositGas));
                uint96 totalFee;
                uint64 i = state.nextEthDepositToProcess;
                while (
                    i < state.ethDeposits.length
                        && i < state.nextEthDepositToProcess + config.maxEthDepositsPerBlock
                ) {
                    TaikoData.EthDeposit storage deposit = state.ethDeposits[i];
                    if (deposit.amount > feePerDeposit) {
                        totalFee += feePerDeposit;
                        depositsProcessed[j].recipient = deposit.recipient;
                        depositsProcessed[j].amount = deposit.amount - feePerDeposit;
                        ++j;
                    } else {
                        totalFee += deposit.amount;
                    }

                    // delete the deposit
                    deposit.recipient = address(0);
                    deposit.amount = 0;
                    ++i;
                }

                // Fee collecting deposit
                if (totalFee > 0) {
                    depositsProcessed[j].recipient = beneficiary;
                    depositsProcessed[j].amount = totalFee;
                    ++j;
                }
                // Advance cursor
                state.nextEthDepositToProcess = i;
            }
        }

        assembly {
            mstore(depositsProcessed, j)
        }
    }

    function hashEthDeposits(TaikoData.EthDeposit[] memory deposits)
        internal
        pure
        returns (bytes32)
    {
        bytes memory buffer = new bytes(32 * deposits.length);

        for (uint256 i; i < deposits.length;) {
            uint256 encoded =
                uint256(uint160(deposits[i].recipient)) << 96 | uint256(deposits[i].amount);
            assembly {
                mstore(add(buffer, mul(32, add(1, i))), encoded)
            }
            unchecked {
                ++i;
            }
        }

        return keccak256(buffer);
    }
}

// SPDX-License-Identifier: MIT
//  _____     _ _         _         _
// |_   _|_ _(_) |_____  | |   __ _| |__ ___
//   | |/ _` | | / / _ \ | |__/ _` | '_ (_-<
//   |_|\__,_|_|_\_\___/ |____\__,_|_.__/__/

pragma solidity ^0.8.18;

import {AddressResolver} from "../../common/AddressResolver.sol";
import {LibAddress} from "../../libs/LibAddress.sol";
import {LibEthDepositing} from "./LibEthDepositing.sol";
import {LibUtils} from "./LibUtils.sol";
import {SafeCastUpgradeable} from
    "@openzeppelin/contracts-upgradeable/utils/math/SafeCastUpgradeable.sol";
import {TaikoData} from "../TaikoData.sol";

library LibProposing {
    using SafeCastUpgradeable for uint256;
    using LibAddress for address;
    using LibAddress for address payable;
    using LibUtils for TaikoData.State;

    event BlockProposed(uint256 indexed id, TaikoData.BlockMetadata meta, uint64 blockFee);

    error L1_BLOCK_ID();
    error L1_INSUFFICIENT_TOKEN();
    error L1_INVALID_METADATA();
    error L1_TOO_MANY_BLOCKS();
    error L1_TX_LIST_NOT_EXIST();
    error L1_TX_LIST_HASH();
    error L1_TX_LIST_RANGE();
    error L1_TX_LIST();

    function proposeBlock(
        TaikoData.State storage state,
        TaikoData.Config memory config,
        AddressResolver resolver,
        TaikoData.BlockMetadataInput memory input,
        bytes calldata txList
    ) internal returns (TaikoData.BlockMetadata memory meta) {
        uint8 cacheTxListInfo =
            _validateBlock({state: state, config: config, input: input, txList: txList});

        if (cacheTxListInfo != 0) {
            state.txListInfo[input.txListHash] = TaikoData.TxListInfo({
                validSince: uint64(block.timestamp),
                size: uint24(txList.length)
            });
        }

        // After The Merge, L1 mixHash contains the prevrandao
        // from the beacon chain. Since multiple Taiko blocks
        // can be proposed in one Ethereum block, we need to
        // add salt to this random number as L2 mixHash

        meta.id = state.numBlocks;
        meta.txListHash = input.txListHash;
        meta.txListByteStart = input.txListByteStart;
        meta.txListByteEnd = input.txListByteEnd;
        meta.gasLimit = input.gasLimit;
        meta.beneficiary = input.beneficiary;
        meta.treasury = resolver.resolve(config.chainId, "treasury", false);
        meta.depositsProcessed = LibEthDepositing.processDeposits(state, config, input.beneficiary);

        unchecked {
            meta.timestamp = uint64(block.timestamp);
            meta.l1Height = uint64(block.number - 1);
            meta.l1Hash = blockhash(block.number - 1);
            meta.mixHash = bytes32(block.difficulty * state.numBlocks);
        }

        TaikoData.Block storage blk = state.blocks[state.numBlocks % config.ringBufferSize];

        blk.blockId = state.numBlocks;
        blk.proposedAt = meta.timestamp;
        blk.nextForkChoiceId = 1;
        blk.verifiedForkChoiceId = 0;
        blk.metaHash = LibUtils.hashMetadata(meta);
        blk.proposer = msg.sender;

        uint64 blockFee = state.blockFee;
        if (state.taikoTokenBalances[msg.sender] < blockFee) {
            revert L1_INSUFFICIENT_TOKEN();
        }

        unchecked {
            state.taikoTokenBalances[msg.sender] -= blockFee;
            state.accBlockFees += blockFee;
            state.accProposedAt += meta.timestamp;
        }

        emit BlockProposed(state.numBlocks, meta, blockFee);
        unchecked {
            ++state.numBlocks;
        }
    }

    function getBlock(
        TaikoData.State storage state,
        TaikoData.Config memory config,
        uint256 blockId
    ) internal view returns (TaikoData.Block storage blk) {
        blk = state.blocks[blockId % config.ringBufferSize];
        if (blk.blockId != blockId) revert L1_BLOCK_ID();
    }

    function _validateBlock(
        TaikoData.State storage state,
        TaikoData.Config memory config,
        TaikoData.BlockMetadataInput memory input,
        bytes calldata txList
    ) private view returns (uint8 cacheTxListInfo) {
        if (
            input.beneficiary == address(0) || input.gasLimit == 0
                || input.gasLimit > config.blockMaxGasLimit
        ) revert L1_INVALID_METADATA();

        if (state.numBlocks >= state.lastVerifiedBlockId + config.maxNumProposedBlocks + 1) {
            revert L1_TOO_MANY_BLOCKS();
        }

        uint64 timeNow = uint64(block.timestamp);
        // handling txList
        {
            uint24 size = uint24(txList.length);
            if (size > config.maxBytesPerTxList) revert L1_TX_LIST();

            if (input.txListByteStart > input.txListByteEnd) {
                revert L1_TX_LIST_RANGE();
            }

            if (config.txListCacheExpiry == 0) {
                // caching is disabled
                if (input.txListByteStart != 0 || input.txListByteEnd != size) {
                    revert L1_TX_LIST_RANGE();
                }
            } else {
                // caching is enabled
                if (size == 0) {
                    // This blob shall have been submitted earlier
                    TaikoData.TxListInfo memory info = state.txListInfo[input.txListHash];

                    if (input.txListByteEnd > info.size) {
                        revert L1_TX_LIST_RANGE();
                    }

                    if (info.size == 0 || info.validSince + config.txListCacheExpiry < timeNow) {
                        revert L1_TX_LIST_NOT_EXIST();
                    }
                } else {
                    if (input.txListByteEnd > size) revert L1_TX_LIST_RANGE();
                    if (input.txListHash != keccak256(txList)) {
                        revert L1_TX_LIST_HASH();
                    }

                    cacheTxListInfo = input.cacheTxListInfo;
                }
            }
        }
    }
}

// SPDX-License-Identifier: MIT
//  _____     _ _         _         _
// |_   _|_ _(_) |_____  | |   __ _| |__ ___
//   | |/ _` | | / / _ \ | |__/ _` | '_ (_-<
//   |_|\__,_|_|_\_\___/ |____\__,_|_.__/__/

pragma solidity ^0.8.18;

import {AddressResolver} from "../../common/AddressResolver.sol";
import {LibMath} from "../../libs/LibMath.sol";
import {LibUtils} from "./LibUtils.sol";
import {TaikoData} from "../../L1/TaikoData.sol";

library LibProving {
    using LibMath for uint256;
    using LibUtils for TaikoData.State;

    event BlockProven(
        uint256 indexed id,
        bytes32 parentHash,
        bytes32 blockHash,
        bytes32 signalRoot,
        address prover,
        uint32 parentGasUsed
    );

    error L1_ALREADY_PROVEN();
    error L1_BLOCK_ID();
    error L1_EVIDENCE_MISMATCH(bytes32 expected, bytes32 actual);
    error L1_FORK_CHOICE_NOT_FOUND();
    error L1_INVALID_EVIDENCE();
    error L1_INVALID_PROOF();
    error L1_INVALID_PROOF_OVERWRITE();
    error L1_NOT_SPECIAL_PROVER();
    error L1_ORACLE_PROVER_DISABLED();
    error L1_SAME_PROOF();
    error L1_SYSTEM_PROVER_DISABLED();
    error L1_SYSTEM_PROVER_PROHIBITED();

    function proveBlock(
        TaikoData.State storage state,
        TaikoData.Config memory config,
        AddressResolver resolver,
        uint256 blockId,
        TaikoData.BlockEvidence memory evidence
    ) internal {
        if (
            evidence.parentHash == 0 || evidence.blockHash == 0
                || evidence.blockHash == evidence.parentHash || evidence.signalRoot == 0
                || evidence.gasUsed == 0
        ) revert L1_INVALID_EVIDENCE();

        if (blockId <= state.lastVerifiedBlockId || blockId >= state.numBlocks) {
            revert L1_BLOCK_ID();
        }

        TaikoData.Block storage blk = state.blocks[blockId % config.ringBufferSize];

        // Check the metadata hash matches the proposed block's. This is
        // necessary to handle chain reorgs.
        if (blk.metaHash != evidence.metaHash) {
            revert L1_EVIDENCE_MISMATCH(blk.metaHash, evidence.metaHash);
        }

        // Separate between oracle proof (which needs to be overwritten)
        // and non-oracle but system proofs
        address specialProver;
        if (evidence.prover == address(0)) {
            specialProver = resolver.resolve("oracle_prover", true);
            if (specialProver == address(0)) {
                revert L1_ORACLE_PROVER_DISABLED();
            }
        } else if (evidence.prover == address(1)) {
            specialProver = resolver.resolve("system_prover", true);
            if (specialProver == address(0)) {
                revert L1_SYSTEM_PROVER_DISABLED();
            }

            if (config.realProofSkipSize <= 1 || blockId % config.realProofSkipSize == 0) {
                revert L1_SYSTEM_PROVER_PROHIBITED();
            }
        }

        if (specialProver != address(0) && msg.sender != specialProver) {
            if (evidence.proof.length != 64) {
                revert L1_NOT_SPECIAL_PROVER();
            } else {
                uint8 v = uint8(evidence.verifierId);
                bytes32 r;
                bytes32 s;
                bytes memory data = evidence.proof;
                assembly {
                    r := mload(add(data, 32))
                    s := mload(add(data, 64))
                }

                // clear the proof before hashing evidence
                evidence.verifierId = 0;
                evidence.proof = new bytes(0);

                if (specialProver != ecrecover(keccak256(abi.encode(evidence)), v, r, s)) {
                    revert L1_NOT_SPECIAL_PROVER();
                }
            }
        }

        TaikoData.ForkChoice storage fc;

        uint256 fcId =
            LibUtils.getForkChoiceId(state, blk, evidence.parentHash, evidence.parentGasUsed);

        if (fcId == 0) {
            fcId = blk.nextForkChoiceId;

            unchecked {
                ++blk.nextForkChoiceId;
            }

            fc = blk.forkChoices[fcId];

            if (fcId == 1) {
                // We only write the key when fcId is 1.
                fc.key = LibUtils.keyForForkChoice(evidence.parentHash, evidence.parentGasUsed);
            } else {
                state.forkChoiceIds[blk.blockId][evidence.parentHash][evidence.parentGasUsed] = fcId;
            }
        } else if (evidence.prover == address(0)) {
            // This is the branch the oracle prover is trying to overwrite
            fc = blk.forkChoices[fcId];
            if (
                fc.blockHash == evidence.blockHash && fc.signalRoot == evidence.signalRoot
                    && fc.gasUsed == evidence.gasUsed
            ) revert L1_SAME_PROOF();
        } else {
            // This is the branch provers trying to overwrite
            fc = blk.forkChoices[fcId];
            if (fc.prover != address(0) && fc.prover != address(1)) {
                revert L1_ALREADY_PROVEN();
            }

            if (
                fc.blockHash != evidence.blockHash || fc.signalRoot != evidence.signalRoot
                    || fc.gasUsed != evidence.gasUsed
            ) revert L1_INVALID_PROOF_OVERWRITE();
        }

        fc.blockHash = evidence.blockHash;
        fc.signalRoot = evidence.signalRoot;
        fc.gasUsed = evidence.gasUsed;
        fc.prover = evidence.prover;

        if (evidence.prover == address(1)) {
            fc.provenAt = uint64(block.timestamp.max(blk.proposedAt + state.proofTimeTarget));
        } else {
            fc.provenAt = uint64(block.timestamp);
        }

        if (evidence.prover != address(0) && evidence.prover != address(1)) {
            uint256[10] memory inputs;

            inputs[0] = uint256(uint160(address(resolver.resolve("signal_service", false))));
            inputs[1] =
                uint256(uint160(address(resolver.resolve(config.chainId, "signal_service", false))));
            inputs[2] = uint256(uint160(address(resolver.resolve(config.chainId, "taiko", false))));

            inputs[3] = uint256(evidence.metaHash);
            inputs[4] = uint256(evidence.parentHash);
            inputs[5] = uint256(evidence.blockHash);
            inputs[6] = uint256(evidence.signalRoot);
            inputs[7] = uint256(evidence.graffiti);
            inputs[8] = (uint256(uint160(evidence.prover)) << 96)
                | (uint256(evidence.parentGasUsed) << 64) | (uint256(evidence.gasUsed) << 32);

            // Also hash configs that will be used by circuits
            inputs[9] = uint256(config.blockMaxGasLimit) << 192
                | uint256(config.maxTransactionsPerBlock) << 128
                | uint256(config.maxBytesPerTxList) << 64;

            bytes32 instance;
            assembly {
                instance := keccak256(inputs, mul(32, 10))
            }

            (bool verified, bytes memory ret) = resolver.resolve(
                LibUtils.getVerifierName(evidence.verifierId), false
            ).staticcall(
                bytes.concat(
                    bytes16(0),
                    bytes16(instance), // left 16 bytes of the given instance
                    bytes16(0),
                    bytes16(uint128(uint256(instance))), // right 16 bytes of the given instance
                    evidence.proof
                )
            );

            if (!verified || ret.length != 32 || bytes32(ret) != keccak256("taiko")) {
                revert L1_INVALID_PROOF();
            }
        }

        emit BlockProven({
            id: blk.blockId,
            parentHash: evidence.parentHash,
            blockHash: evidence.blockHash,
            signalRoot: evidence.signalRoot,
            prover: evidence.prover,
            parentGasUsed: evidence.parentGasUsed
        });
    }

    function getForkChoice(
        TaikoData.State storage state,
        TaikoData.Config memory config,
        uint256 blockId,
        bytes32 parentHash,
        uint32 parentGasUsed
    ) internal view returns (TaikoData.ForkChoice storage fc) {
        TaikoData.Block storage blk = state.blocks[blockId % config.ringBufferSize];
        if (blk.blockId != blockId) revert L1_BLOCK_ID();

        uint256 fcId = LibUtils.getForkChoiceId(state, blk, parentHash, parentGasUsed);
        if (fcId == 0) revert L1_FORK_CHOICE_NOT_FOUND();
        fc = blk.forkChoices[fcId];
    }
}

// SPDX-License-Identifier: MIT
//  _____     _ _         _         _
// |_   _|_ _(_) |_____  | |   __ _| |__ ___
//   | |/ _` | | / / _ \ | |__/ _` | '_ (_-<
//   |_|\__,_|_|_\_\___/ |____\__,_|_.__/__/

pragma solidity ^0.8.18;

import {AddressResolver} from "../../common/AddressResolver.sol";
import {LibMath} from "../../libs/LibMath.sol";
import {SafeCastUpgradeable} from
    "@openzeppelin/contracts-upgradeable/utils/math/SafeCastUpgradeable.sol";
import {TaikoData} from "../TaikoData.sol";
import {TaikoToken} from "../TaikoToken.sol";
import {LibFixedPointMath as Math} from "../../thirdparty/LibFixedPointMath.sol";

library LibTokenomics {
    using LibMath for uint256;

    error L1_INSUFFICIENT_TOKEN();

    function withdrawTaikoToken(
        TaikoData.State storage state,
        AddressResolver resolver,
        uint256 amount
    ) internal {
        uint256 balance = state.taikoTokenBalances[msg.sender];
        if (balance < amount) revert L1_INSUFFICIENT_TOKEN();

        unchecked {
            state.taikoTokenBalances[msg.sender] -= amount;
        }

        TaikoToken(resolver.resolve("taiko_token", false)).mint(msg.sender, amount);
    }

    function depositTaikoToken(
        TaikoData.State storage state,
        AddressResolver resolver,
        uint256 amount
    ) internal {
        if (amount > 0) {
            TaikoToken(resolver.resolve("taiko_token", false)).burn(msg.sender, amount);
            state.taikoTokenBalances[msg.sender] += amount;
        }
    }

    /**
     * Get the block reward for a proof
     *
     * @param state The actual state data
     * @param proofTime The actual proof time
     * @return reward The reward given for the block proof
     */
    function getProofReward(TaikoData.State storage state, uint64 proofTime)
        internal
        view
        returns (uint64)
    {
        uint64 numBlocksUnverified = state.numBlocks - state.lastVerifiedBlockId - 1;

        if (numBlocksUnverified == 0) {
            return 0;
        } else {
            uint64 totalNumProvingSeconds =
                uint64(uint256(numBlocksUnverified) * block.timestamp - state.accProposedAt);
            // If block timestamp is equal to state.accProposedAt (not really,
            // but theoretically possible) there will be division by 0 error
            if (totalNumProvingSeconds == 0) {
                totalNumProvingSeconds = 1;
            }

            return uint64((uint256(state.accBlockFees) * proofTime) / totalNumProvingSeconds);
        }
    }

    /**
     * Calculate the newProofTimeIssued and blockFee
     *
     * @param state The actual state data
     * @param proofTime The actual proof time
     * @return newProofTimeIssued Accumulated proof time
     * @return blockFee New block fee
     */
    function getNewBlockFeeAndProofTimeIssued(TaikoData.State storage state, uint64 proofTime)
        internal
        view
        returns (uint64 newProofTimeIssued, uint64 blockFee)
    {
        newProofTimeIssued = (state.proofTimeIssued > state.proofTimeTarget)
            ? state.proofTimeIssued - state.proofTimeTarget
            : uint64(0);
        newProofTimeIssued += proofTime;

        uint256 x = (newProofTimeIssued * Math.SCALING_FACTOR_1E18)
            / (state.proofTimeTarget * state.adjustmentQuotient);

        if (Math.MAX_EXP_INPUT <= x) {
            x = Math.MAX_EXP_INPUT;
        }

        uint256 result = (uint256(Math.exp(int256(x))) / Math.SCALING_FACTOR_1E18)
            / (state.proofTimeTarget * state.adjustmentQuotient);

        blockFee = uint64(result.min(type(uint64).max));
    }
}

// SPDX-License-Identifier: MIT
//  _____     _ _         _         _
// |_   _|_ _(_) |_____  | |   __ _| |__ ___
//   | |/ _` | | / / _ \ | |__/ _` | '_ (_-<
//   |_|\__,_|_|_\_\___/ |____\__,_|_.__/__/

pragma solidity ^0.8.18;

import {LibMath} from "../../libs/LibMath.sol";
import {LibEthDepositing} from "./LibEthDepositing.sol";
import {SafeCastUpgradeable} from
    "@openzeppelin/contracts-upgradeable/utils/math/SafeCastUpgradeable.sol";
import {TaikoData} from "../TaikoData.sol";

library LibUtils {
    using LibMath for uint256;

    error L1_BLOCK_ID();

    function getL2ChainData(
        TaikoData.State storage state,
        TaikoData.Config memory config,
        uint256 blockId
    ) internal view returns (bool found, TaikoData.Block storage blk) {
        uint256 id = blockId == 0 ? state.lastVerifiedBlockId : blockId;
        blk = state.blocks[id % config.ringBufferSize];
        found = (blk.blockId == id && blk.verifiedForkChoiceId != 0);
    }

    function getForkChoiceId(
        TaikoData.State storage state,
        TaikoData.Block storage blk,
        bytes32 parentHash,
        uint32 parentGasUsed
    ) internal view returns (uint256 fcId) {
        if (blk.forkChoices[1].key == keyForForkChoice(parentHash, parentGasUsed)) {
            fcId = 1;
        } else {
            fcId = state.forkChoiceIds[blk.blockId][parentHash][parentGasUsed];
        }

        if (fcId >= blk.nextForkChoiceId) {
            fcId = 0;
        }
    }

    function getStateVariables(TaikoData.State storage state)
        internal
        view
        returns (TaikoData.StateVariables memory)
    {
        return TaikoData.StateVariables({
            blockFee: state.blockFee,
            accBlockFees: state.accBlockFees,
            genesisHeight: state.genesisHeight,
            genesisTimestamp: state.genesisTimestamp,
            numBlocks: state.numBlocks,
            proofTimeIssued: state.proofTimeIssued,
            proofTimeTarget: state.proofTimeTarget,
            lastVerifiedBlockId: state.lastVerifiedBlockId,
            accProposedAt: state.accProposedAt,
            nextEthDepositToProcess: state.nextEthDepositToProcess,
            numEthDeposits: uint64(state.ethDeposits.length)
        });
    }

    function movingAverage(uint256 maValue, uint256 newValue, uint256 maf)
        internal
        pure
        returns (uint256)
    {
        if (maValue == 0) {
            return newValue;
        }
        uint256 _ma = (maValue * (maf - 1) + newValue) / maf;
        return _ma > 0 ? _ma : maValue;
    }

    /// @dev Hashing the block metadata.
    function hashMetadata(TaikoData.BlockMetadata memory meta)
        internal
        pure
        returns (bytes32 hash)
    {
        uint256[7] memory inputs;

        inputs[0] = (uint256(meta.id) << 192) | (uint256(meta.timestamp) << 128)
            | (uint256(meta.l1Height) << 64);

        inputs[1] = uint256(meta.l1Hash);
        inputs[2] = uint256(meta.mixHash);
        inputs[3] = uint256(LibEthDepositing.hashEthDeposits(meta.depositsProcessed));
        inputs[4] = uint256(meta.txListHash);

        inputs[5] = (uint256(meta.txListByteStart) << 232) | (uint256(meta.txListByteEnd) << 208)
            | (uint256(meta.gasLimit) << 176) | (uint256(uint160(meta.beneficiary)) << 16);

        inputs[6] = (uint256(uint160(meta.treasury)) << 96);

        assembly {
            hash := keccak256(inputs, mul(7, 32))
        }
    }

    function keyForForkChoice(bytes32 parentHash, uint32 parentGasUsed)
        internal
        pure
        returns (bytes32 key)
    {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, parentGasUsed)
            mstore(add(ptr, 32), parentHash)
            key := keccak256(add(ptr, 28), 36)
            mstore(0x40, add(ptr, 64))
        }
    }

    function getVerifierName(uint16 id) internal pure returns (bytes32) {
        return bytes32(uint256(0x1000000) + id);
    }
}

// SPDX-License-Identifier: MIT
//  _____     _ _         _         _
// |_   _|_ _(_) |_____  | |   __ _| |__ ___
//   | |/ _` | | / / _ \ | |__/ _` | '_ (_-<
//   |_|\__,_|_|_\_\___/ |____\__,_|_.__/__/

pragma solidity ^0.8.18;

import {AddressResolver} from "../../common/AddressResolver.sol";
import {ISignalService} from "../../signal/ISignalService.sol";
import {LibTokenomics} from "./LibTokenomics.sol";
import {LibUtils} from "./LibUtils.sol";
import {SafeCastUpgradeable} from
    "@openzeppelin/contracts-upgradeable/utils/math/SafeCastUpgradeable.sol";
import {TaikoData} from "../../L1/TaikoData.sol";

library LibVerifying {
    using SafeCastUpgradeable for uint256;
    using LibUtils for TaikoData.State;

    event BlockVerified(uint256 indexed id, bytes32 blockHash, uint64 reward);

    event CrossChainSynced(uint256 indexed srcHeight, bytes32 blockHash, bytes32 signalRoot);

    error L1_INVALID_CONFIG();

    function init(
        TaikoData.State storage state,
        TaikoData.Config memory config,
        bytes32 genesisBlockHash,
        uint64 initBlockFee,
        uint64 initProofTimeTarget,
        uint64 initProofTimeIssued,
        uint16 adjustmentQuotient
    ) internal {
        if (
            config.chainId <= 1 || config.maxNumProposedBlocks == 1
                || config.ringBufferSize <= config.maxNumProposedBlocks + 1
                || config.blockMaxGasLimit == 0 || config.maxTransactionsPerBlock == 0
                || config.maxBytesPerTxList == 0
            // EIP-4844 blob size up to 128K
            || config.maxBytesPerTxList > 128 * 1024 || config.maxEthDepositsPerBlock == 0
                || config.maxEthDepositsPerBlock < config.minEthDepositsPerBlock
            // EIP-4844 blob deleted after 30 days
            || config.txListCacheExpiry > 30 * 24 hours || config.ethDepositGas == 0
                || config.ethDepositMaxFee == 0 || config.ethDepositMaxFee >= type(uint96).max
                || adjustmentQuotient == 0 || initProofTimeTarget == 0 || initProofTimeIssued == 0
        ) revert L1_INVALID_CONFIG();

        uint64 timeNow = uint64(block.timestamp);
        state.genesisHeight = uint64(block.number);
        state.genesisTimestamp = timeNow;

        state.blockFee = initBlockFee;
        state.proofTimeIssued = initProofTimeIssued;
        state.proofTimeTarget = initProofTimeTarget;
        state.adjustmentQuotient = adjustmentQuotient;
        state.numBlocks = 1;

        TaikoData.Block storage blk = state.blocks[0];
        blk.proposedAt = timeNow;
        blk.nextForkChoiceId = 2;
        blk.verifiedForkChoiceId = 1;

        TaikoData.ForkChoice storage fc = state.blocks[0].forkChoices[1];
        fc.blockHash = genesisBlockHash;
        fc.provenAt = timeNow;

        emit BlockVerified(0, genesisBlockHash, 0);
    }

    function verifyBlocks(
        TaikoData.State storage state,
        TaikoData.Config memory config,
        AddressResolver resolver,
        uint256 maxBlocks
    ) internal {
        uint256 i = state.lastVerifiedBlockId;
        TaikoData.Block storage blk = state.blocks[i % config.ringBufferSize];

        uint256 fcId = blk.verifiedForkChoiceId;
        assert(fcId > 0);
        bytes32 blockHash = blk.forkChoices[fcId].blockHash;
        uint32 gasUsed = blk.forkChoices[fcId].gasUsed;
        bytes32 signalRoot;

        uint64 processed;
        unchecked {
            ++i;
        }

        address systemProver = resolver.resolve("system_prover", true);
        while (i < state.numBlocks && processed < maxBlocks) {
            blk = state.blocks[i % config.ringBufferSize];
            assert(blk.blockId == i);

            fcId = LibUtils.getForkChoiceId(state, blk, blockHash, gasUsed);

            if (fcId == 0) break;

            TaikoData.ForkChoice storage fc = blk.forkChoices[fcId];

            if (fc.prover == address(0)) break;

            uint256 proofCooldownPeriod = fc.prover == address(1)
                ? config.systemProofCooldownPeriod
                : config.proofCooldownPeriod;

            if (block.timestamp < fc.provenAt + proofCooldownPeriod) break;

            blockHash = fc.blockHash;
            gasUsed = fc.gasUsed;
            signalRoot = fc.signalRoot;

            _markBlockVerified({
                state: state,
                blk: blk,
                fcId: uint24(fcId),
                fc: fc,
                systemProver: systemProver
            });

            unchecked {
                ++i;
                ++processed;
            }
        }

        if (processed > 0) {
            unchecked {
                state.lastVerifiedBlockId += processed;
            }

            if (config.relaySignalRoot) {
                // Send the L2's signal root to the signal service so other TaikoL1
                // deployments, if they share the same signal service, can relay the
                // signal to their corresponding TaikoL2 contract.
                ISignalService(resolver.resolve("signal_service", false)).sendSignal(signalRoot);
            }
            emit CrossChainSynced(state.lastVerifiedBlockId, blockHash, signalRoot);
        }
    }

    function _markBlockVerified(
        TaikoData.State storage state,
        TaikoData.Block storage blk,
        TaikoData.ForkChoice storage fc,
        uint24 fcId,
        address systemProver
    ) private {
        uint64 proofTime;
        unchecked {
            proofTime = uint64(fc.provenAt - blk.proposedAt);
        }

        uint64 reward = LibTokenomics.getProofReward(state, proofTime);

        (state.proofTimeIssued, state.blockFee) =
            LibTokenomics.getNewBlockFeeAndProofTimeIssued(state, proofTime);

        unchecked {
            state.accBlockFees -= reward;
            state.accProposedAt -= blk.proposedAt;
        }

        // reward the prover
        if (reward != 0) {
            address prover = fc.prover != address(1) ? fc.prover : systemProver;

            // systemProver may become address(0) after a block is proven
            if (prover != address(0)) {
                if (state.taikoTokenBalances[prover] == 0) {
                    // Reduce refund to 1 wei as a penalty if the proposer
                    // has 0 TKO outstanding balance.
                    state.taikoTokenBalances[prover] = 1;
                } else {
                    state.taikoTokenBalances[prover] += reward;
                }
            }
        }

        blk.nextForkChoiceId = 1;
        blk.verifiedForkChoiceId = fcId;

        emit BlockVerified(blk.blockId, fc.blockHash, reward);
    }
}

// SPDX-License-Identifier: MIT
//  _____     _ _         _         _
// |_   _|_ _(_) |_____  | |   __ _| |__ ___
//   | |/ _` | | / / _ \ | |__/ _` | '_ (_-<
//   |_|\__,_|_|_\_\___/ |____\__,_|_.__/__/

pragma solidity ^0.8.18;

import {TaikoData} from "../L1/TaikoData.sol";

library TaikoConfig {
    function getConfig() internal pure returns (TaikoData.Config memory) {
        return TaikoData.Config({
            chainId: 167005,
            // Two weeks if avg block time is 3 seconds
            maxNumProposedBlocks: 403200,
            ringBufferSize: 403200 + 10,
            // Each time one more block is verified, there will be ~20k
            // more gas cost.
            maxVerificationsPerTx: 10,
            // Set it to 6M, since its the upper limit of the Alpha-3
            // testnet's circuits.
            blockMaxGasLimit: 6000000,
            // Set it to 79  (+1 TaikoL2.anchor transaction = 80),
            // and 80 is the upper limit of the Alpha-3 testnet's circuits.
            maxTransactionsPerBlock: 79,
            minEthDepositsPerBlock: 1,
            maxEthDepositsPerBlock: 32,
            maxEthDepositAmount: 10000 ether,
            minEthDepositAmount: 0.1 ether,
            // Set it to 120KB, since 128KB is the upper size limit
            // of a geth transaction, so using 120KB for the proposed
            // transactions list calldata, 8K for the remaining tx fields.
            maxBytesPerTxList: 120000,
            proofCooldownPeriod: 30 minutes,
            systemProofCooldownPeriod: 15 minutes,
            // Only need 1 real zkp per 10 blocks.
            // If block number is N, then only when N % 10 == 0, the real ZKP
            // is needed. For mainnet, this must be 0 or 1.
            realProofSkipSize: 10,
            ethDepositGas: 21000,
            ethDepositMaxFee: 1 ether / 10,
            txListCacheExpiry: 0,
            relaySignalRoot: false
        });
    }
}

// SPDX-License-Identifier: MIT
//  _____     _ _         _         _
// |_   _|_ _(_) |_____  | |   __ _| |__ ___
//   | |/ _` | | / / _ \ | |__/ _` | '_ (_-<
//   |_|\__,_|_|_\_\___/ |____\__,_|_.__/__/

pragma solidity ^0.8.18;

library TaikoData {
    struct Config {
        uint256 chainId;
        uint256 maxNumProposedBlocks;
        uint256 ringBufferSize;
        // This number is calculated from maxNumProposedBlocks to make
        // the 'the maximum value of the multiplier' close to 20.0
        uint256 maxVerificationsPerTx;
        uint64 blockMaxGasLimit;
        uint64 maxTransactionsPerBlock;
        uint64 maxBytesPerTxList;
        uint256 txListCacheExpiry;
        uint256 proofCooldownPeriod;
        uint256 systemProofCooldownPeriod;
        uint256 realProofSkipSize;
        uint256 ethDepositGas;
        uint256 ethDepositMaxFee;
        uint64 minEthDepositsPerBlock;
        uint64 maxEthDepositsPerBlock;
        uint96 maxEthDepositAmount;
        uint96 minEthDepositAmount;
        bool relaySignalRoot;
    }

    struct StateVariables {
        uint64 blockFee;
        uint64 accBlockFees;
        uint64 genesisHeight;
        uint64 genesisTimestamp;
        uint64 numBlocks;
        uint64 proofTimeIssued;
        uint64 proofTimeTarget;
        uint64 lastVerifiedBlockId;
        uint64 accProposedAt;
        uint64 nextEthDepositToProcess;
        uint64 numEthDeposits;
    }

    // 3 slots
    struct BlockMetadataInput {
        bytes32 txListHash;
        address beneficiary;
        uint32 gasLimit;
        uint24 txListByteStart; // byte-wise start index (inclusive)
        uint24 txListByteEnd; // byte-wise end index (exclusive)
        uint8 cacheTxListInfo; // non-zero = True
    }

    // Changing this struct requires changing LibUtils.hashMetadata accordingly.
    struct BlockMetadata {
        uint64 id;
        uint64 timestamp;
        uint64 l1Height;
        bytes32 l1Hash;
        bytes32 mixHash;
        bytes32 txListHash;
        uint24 txListByteStart;
        uint24 txListByteEnd;
        uint32 gasLimit;
        address beneficiary;
        address treasury;
        TaikoData.EthDeposit[] depositsProcessed;
    }

    struct BlockEvidence {
        bytes32 metaHash;
        bytes32 parentHash;
        bytes32 blockHash;
        bytes32 signalRoot;
        bytes32 graffiti;
        address prover;
        uint32 parentGasUsed;
        uint32 gasUsed;
        uint16 verifierId;
        bytes proof;
    }

    // 4 slots
    struct ForkChoice {
        // Key is only written/read for the 1st fork choice.
        bytes32 key;
        bytes32 blockHash;
        bytes32 signalRoot;
        uint64 provenAt;
        address prover;
        uint32 gasUsed;
    }

    // 4 slots
    struct Block {
        // ForkChoice storage are reusable
        mapping(uint256 forkChoiceId => ForkChoice) forkChoices;
        uint64 blockId;
        uint64 proposedAt;
        uint24 nextForkChoiceId;
        uint24 verifiedForkChoiceId;
        bytes32 metaHash;
        address proposer;
    }

    // This struct takes 9 slots.
    struct TxListInfo {
        uint64 validSince;
        uint24 size;
    }

    // 1 slot
    struct EthDeposit {
        address recipient;
        uint96 amount;
    }

    struct State {
        // Ring buffer for proposed blocks and a some recent verified blocks.
        mapping(uint256 blockId_mode_ringBufferSize => Block) blocks;
        // solhint-disable-next-line max-line-length
        mapping(
            uint256 blockId
                => mapping(
                    bytes32 parentHash => mapping(uint32 parentGasUsed => uint256 forkChoiceId)
                )
            ) forkChoiceIds;
        mapping(address account => uint256 balance) taikoTokenBalances;
        mapping(bytes32 txListHash => TxListInfo) txListInfo;
        EthDeposit[] ethDeposits;
        // Never or rarely changed
        // Slot 7: never or rarely changed
        uint64 genesisHeight;
        uint64 genesisTimestamp;
        uint16 adjustmentQuotient;
        uint48 __reserved71;
        uint64 __reserved72;
        // Slot 8
        uint64 accProposedAt;
        uint64 accBlockFees;
        uint64 numBlocks;
        uint64 nextEthDepositToProcess;
        // Slot 9
        uint64 blockFee;
        uint64 proofTimeIssued;
        uint64 lastVerifiedBlockId;
        uint64 proofTimeTarget;
        // Reserved
        uint256[42] __gap;
    }
}

// SPDX-License-Identifier: MIT
//  _____     _ _         _         _
// |_   _|_ _(_) |_____  | |   __ _| |__ ___
//   | |/ _` | | / / _ \ | |__/ _` | '_ (_-<
//   |_|\__,_|_|_\_\___/ |____\__,_|_.__/__/

pragma solidity ^0.8.18;

abstract contract TaikoErrors {
    // The following custom errors must match the definitions in other V1 libraries.
    error L1_ALREADY_PROVEN();
    error L1_BLOCK_ID();
    error L1_EVIDENCE_MISMATCH(bytes32 expected, bytes32 actual);
    error L1_FORK_CHOICE_NOT_FOUND();
    error L1_INSUFFICIENT_TOKEN();
    error L1_INVALID_CONFIG();
    error L1_INVALID_ETH_DEPOSIT();
    error L1_INVALID_EVIDENCE();
    error L1_INVALID_METADATA();
    error L1_INVALID_PARAM();
    error L1_INVALID_PROOF();
    error L1_INVALID_PROOF_OVERWRITE();
    error L1_NOT_SPECIAL_PROVER();
    error L1_ORACLE_PROVER_DISABLED();
    error L1_SAME_PROOF();
    error L1_SYSTEM_PROVER_DISABLED();
    error L1_SYSTEM_PROVER_PROHIBITED();
    error L1_TOO_MANY_BLOCKS();
    error L1_TX_LIST_NOT_EXIST();
    error L1_TX_LIST_HASH();
    error L1_TX_LIST_RANGE();
    error L1_TX_LIST();
}

// SPDX-License-Identifier: MIT
//  _____     _ _         _         _
// |_   _|_ _(_) |_____  | |   __ _| |__ ___
//   | |/ _` | | / / _ \ | |__/ _` | '_ (_-<
//   |_|\__,_|_|_\_\___/ |____\__,_|_.__/__/

pragma solidity ^0.8.18;

import {TaikoData} from "./TaikoData.sol";

abstract contract TaikoEvents {
    // The following events must match the definitions in corresponding L1 libraries.
    event BlockProposed(uint256 indexed id, TaikoData.BlockMetadata meta, uint64 blockFee);

    event BlockProven(
        uint256 indexed id,
        bytes32 parentHash,
        bytes32 blockHash,
        bytes32 signalRoot,
        address prover,
        uint32 parentGasUsed
    );

    event BlockVerified(uint256 indexed id, bytes32 blockHash, uint64 reward);

    event EthDeposited(TaikoData.EthDeposit deposit);

    event ProofParamsChanged(
        uint64 proofTimeTarget, uint64 proofTimeIssued, uint64 blockFee, uint16 adjustmentQuotient
    );
}

// SPDX-License-Identifier: MIT
//  _____     _ _         _         _
// |_   _|_ _(_) |_____  | |   __ _| |__ ___
//   | |/ _` | | / / _ \ | |__/ _` | '_ (_-<
//   |_|\__,_|_|_\_\___/ |____\__,_|_.__/__/

pragma solidity ^0.8.18;

import {AddressResolver} from "../common/AddressResolver.sol";
import {EssentialContract} from "../common/EssentialContract.sol";
import {ICrossChainSync} from "../common/ICrossChainSync.sol";
import {Proxied} from "../common/Proxied.sol";
import {LibEthDepositing} from "./libs/LibEthDepositing.sol";
import {LibTokenomics} from "./libs/LibTokenomics.sol";
import {LibProposing} from "./libs/LibProposing.sol";
import {LibProving} from "./libs/LibProving.sol";
import {LibUtils} from "./libs/LibUtils.sol";
import {LibVerifying} from "./libs/LibVerifying.sol";
import {TaikoConfig} from "./TaikoConfig.sol";
import {TaikoErrors} from "./TaikoErrors.sol";
import {TaikoData} from "./TaikoData.sol";
import {TaikoEvents} from "./TaikoEvents.sol";

/// @custom:security-contact [email protected]
contract TaikoL1 is EssentialContract, ICrossChainSync, TaikoEvents, TaikoErrors {
    using LibUtils for TaikoData.State;

    TaikoData.State public state;
    uint256[100] private __gap;

    receive() external payable {
        depositEtherToL2();
    }

    /**
     * Initialize the rollup.
     *
     * @param _addressManager The AddressManager address.
     * @param _genesisBlockHash The block hash of the genesis block.
     * @param _initBlockFee Initial (reasonable) block fee value.
     * @param _initProofTimeTarget Initial (reasonable) proof submission time target.
     * @param _initProofTimeIssued Initial proof time issued corresponding
     *        with the initial block fee.
     * @param _adjustmentQuotient Block fee calculation adjustment quotient.
     */
    function init(
        address _addressManager,
        bytes32 _genesisBlockHash,
        uint64 _initBlockFee,
        uint64 _initProofTimeTarget,
        uint64 _initProofTimeIssued,
        uint16 _adjustmentQuotient
    ) external initializer {
        EssentialContract._init(_addressManager);
        LibVerifying.init({
            state: state,
            config: getConfig(),
            genesisBlockHash: _genesisBlockHash,
            initBlockFee: _initBlockFee,
            initProofTimeTarget: _initProofTimeTarget,
            initProofTimeIssued: _initProofTimeIssued,
            adjustmentQuotient: _adjustmentQuotient
        });
    }

    /**
     * Propose a Taiko L2 block.
     *
     * @param input An abi-encoded BlockMetadataInput that the actual L2
     *        block header must satisfy.
     * @param txList A list of transactions in this block, encoded with RLP.
     *        Note, in the corresponding L2 block an _anchor transaction_
     *        will be the first transaction in the block -- if there are
     *        `n` transactions in `txList`, then there will be up to `n + 1`
     *        transactions in the L2 block.
     */
    function proposeBlock(bytes calldata input, bytes calldata txList)
        external
        nonReentrant
        returns (TaikoData.BlockMetadata memory meta)
    {
        TaikoData.Config memory config = getConfig();
        meta = LibProposing.proposeBlock({
            state: state,
            config: config,
            resolver: AddressResolver(this),
            input: abi.decode(input, (TaikoData.BlockMetadataInput)),
            txList: txList
        });
        if (config.maxVerificationsPerTx > 0) {
            LibVerifying.verifyBlocks({
                state: state,
                config: config,
                resolver: AddressResolver(this),
                maxBlocks: config.maxVerificationsPerTx
            });
        }
    }

    /**
     * Prove a block with a zero-knowledge proof.
     *
     * @param blockId The index of the block to prove. This is also used
     *        to select the right implementation version.
     * @param input An abi-encoded TaikoData.BlockEvidence object.
     */
    function proveBlock(uint256 blockId, bytes calldata input) external nonReentrant {
        TaikoData.Config memory config = getConfig();
        LibProving.proveBlock({
            state: state,
            config: config,
            resolver: AddressResolver(this),
            blockId: blockId,
            evidence: abi.decode(input, (TaikoData.BlockEvidence))
        });
        if (config.maxVerificationsPerTx > 0) {
            LibVerifying.verifyBlocks({
                state: state,
                config: config,
                resolver: AddressResolver(this),
                maxBlocks: config.maxVerificationsPerTx
            });
        }
    }

    /**
     * Verify up to N blocks.
     * @param maxBlocks Max number of blocks to verify.
     */
    function verifyBlocks(uint256 maxBlocks) external nonReentrant {
        if (maxBlocks == 0) revert L1_INVALID_PARAM();
        LibVerifying.verifyBlocks({
            state: state,
            config: getConfig(),
            resolver: AddressResolver(this),
            maxBlocks: maxBlocks
        });
    }

    /**
     * Change proof parameters (time target and time issued) - to avoid complex/risky upgrades in case need to change relatively frequently.
     * @param newProofTimeTarget New proof time target.
     * @param newProofTimeIssued New proof time issued. If set to type(uint64).max, let it be unchanged.
     * @param newBlockFee New blockfee. If set to type(uint64).max, let it be unchanged.
     * @param newAdjustmentQuotient New adjustment quotient. If set to type(uint16).max, let it be unchanged.
     */
    function setProofParams(
        uint64 newProofTimeTarget,
        uint64 newProofTimeIssued,
        uint64 newBlockFee,
        uint16 newAdjustmentQuotient
    ) external onlyOwner {
        if (newProofTimeTarget == 0 || newProofTimeIssued == 0) {
            revert L1_INVALID_PARAM();
        }

        state.proofTimeTarget = newProofTimeTarget;
        // Special case in a way - that we leave the proofTimeIssued unchanged
        // because we think provers will adjust behavior.
        if (newProofTimeIssued != type(uint64).max) {
            state.proofTimeIssued = newProofTimeIssued;
        }
        // Special case in a way - that we leave the blockFee unchanged
        // because the level we are at is fine.
        if (newBlockFee != type(uint64).max) {
            state.blockFee = newBlockFee;
        }
        // Special case in a way - that we leave the adjustmentQuotient unchanged
        // because we the 'slowlyness' of the curve is fine.
        if (newAdjustmentQuotient != type(uint16).max) {
            state.adjustmentQuotient = newAdjustmentQuotient;
        }

        emit ProofParamsChanged(
            newProofTimeTarget, newProofTimeIssued, newBlockFee, newAdjustmentQuotient
        );
    }

    function depositTaikoToken(uint256 amount) external nonReentrant {
        LibTokenomics.depositTaikoToken(state, AddressResolver(this), amount);
    }

    function withdrawTaikoToken(uint256 amount) external nonReentrant {
        LibTokenomics.withdrawTaikoToken(state, AddressResolver(this), amount);
    }

    function depositEtherToL2() public payable {
        LibEthDepositing.depositEtherToL2(state, getConfig(), AddressResolver(this));
    }

    function getTaikoTokenBalance(address addr) public view returns (uint256) {
        return state.taikoTokenBalances[addr];
    }

    function getBlockFee() public view returns (uint64) {
        return state.blockFee;
    }

    function getProofReward(uint64 proofTime) public view returns (uint64) {
        return LibTokenomics.getProofReward(state, proofTime);
    }

    function getBlock(uint256 blockId)
        public
        view
        returns (bytes32 _metaHash, address _proposer, uint64 _proposedAt)
    {
        TaikoData.Block storage blk =
            LibProposing.getBlock({state: state, config: getConfig(), blockId: blockId});
        _metaHash = blk.metaHash;
        _proposer = blk.proposer;
        _proposedAt = blk.proposedAt;
    }

    function getForkChoice(uint256 blockId, bytes32 parentHash, uint32 parentGasUsed)
        public
        view
        returns (TaikoData.ForkChoice memory)
    {
        return LibProving.getForkChoice({
            state: state,
            config: getConfig(),
            blockId: blockId,
            parentHash: parentHash,
            parentGasUsed: parentGasUsed
        });
    }

    function getCrossChainBlockHash(uint256 blockId) public view override returns (bytes32) {
        (bool found, TaikoData.Block storage blk) =
            LibUtils.getL2ChainData({state: state, config: getConfig(), blockId: blockId});
        return found ? blk.forkChoices[blk.verifiedForkChoiceId].blockHash : bytes32(0);
    }

    function getCrossChainSignalRoot(uint256 blockId) public view override returns (bytes32) {
        (bool found, TaikoData.Block storage blk) =
            LibUtils.getL2ChainData({state: state, config: getConfig(), blockId: blockId});

        return found ? blk.forkChoices[blk.verifiedForkChoiceId].signalRoot : bytes32(0);
    }

    function getStateVariables() public view returns (TaikoData.StateVariables memory) {
        return state.getStateVariables();
    }

    function getConfig() public pure virtual returns (TaikoData.Config memory) {
        return TaikoConfig.getConfig();
    }

    function getVerifierName(uint16 id) public pure returns (bytes32) {
        return LibUtils.getVerifierName(id);
    }
}

contract ProxiedTaikoL1 is Proxied, TaikoL1 {}

// SPDX-License-Identifier: MIT
//  _____     _ _         _         _
// |_   _|_ _(_) |_____  | |   __ _| |__ ___
//   | |/ _` | | / / _ \ | |__/ _` | '_ (_-<
//   |_|\__,_|_|_\_\___/ |____\__,_|_.__/__/

pragma solidity ^0.8.18;

import {ERC20Upgradeable} from
    "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {ERC20BurnableUpgradeable} from
    "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import {ERC20SnapshotUpgradeable} from
    "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20SnapshotUpgradeable.sol";
import {PausableUpgradeable} from
    "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

import {ERC20PermitUpgradeable} from
    "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/draft-ERC20PermitUpgradeable.sol";
import {ERC20VotesUpgradeable} from
    "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20VotesUpgradeable.sol";
import {EssentialContract} from "../common/EssentialContract.sol";
import {Proxied} from "../common/Proxied.sol";

library LibTaikoTokenConfig {
    uint8 public constant DECIMALS = uint8(8);
}

/// @custom:security-contact [email protected]
contract TaikoToken is
    EssentialContract,
    ERC20Upgradeable,
    ERC20BurnableUpgradeable,
    ERC20SnapshotUpgradeable,
    PausableUpgradeable,
    ERC20PermitUpgradeable,
    ERC20VotesUpgradeable
{
    event Mint(address account, uint256 amount);
    event Burn(address account, uint256 amount);

    error TKO_INVALID_ADDR();
    error TKO_INVALID_PREMINT_PARAMS();
    error TKO_MINT_DISALLOWED();

    /*//////////////////////////////////////////////////////////////
                         USER-FACING FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function init(
        address _addressManager,
        string calldata _name,
        string calldata _symbol,
        address[] calldata _premintRecipients,
        uint256[] calldata _premintAmounts
    ) public initializer {
        EssentialContract._init(_addressManager);
        __ERC20_init(_name, _symbol);
        __ERC20Burnable_init();
        __ERC20Snapshot_init();
        __Pausable_init();
        __ERC20Permit_init(_name);
        __ERC20Votes_init();

        for (uint256 i = 0; i < _premintRecipients.length; ++i) {
            _mint(_premintRecipients[i], _premintAmounts[i]);
        }
    }

    function snapshot() public onlyOwner {
        _snapshot();
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function mint(address to, uint256 amount) public onlyFromNamed("proto_broker") {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) public onlyFromNamed("proto_broker") {
        _burn(from, amount);
    }

    function transfer(address to, uint256 amount) public override returns (bool) {
        if (to == address(this)) revert TKO_INVALID_ADDR();
        return ERC20Upgradeable.transfer(to, amount);
    }

    function transferFrom(address from, address to, uint256 amount)
        public
        override
        returns (bool)
    {
        if (to == address(this)) revert TKO_INVALID_ADDR();
        return ERC20Upgradeable.transferFrom(from, to, amount);
    }

    function decimals() public pure override returns (uint8) {
        return LibTaikoTokenConfig.DECIMALS;
    }

    /*//////////////////////////////////////////////////////////////
                           INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        override(ERC20Upgradeable, ERC20SnapshotUpgradeable)
        whenNotPaused
    {
        super._beforeTokenTransfer(from, to, amount);
    }

    // The following functions are overrides required by Solidity.
    function _afterTokenTransfer(address from, address to, uint256 amount)
        internal
        override(ERC20Upgradeable, ERC20VotesUpgradeable)
    {
        super._afterTokenTransfer(from, to, amount);
    }

    function _mint(address to, uint256 amount)
        internal
        override(ERC20Upgradeable, ERC20VotesUpgradeable)
    {
        super._mint(to, amount);

        // TODO: do we need the following check at all?
        if (totalSupply() > type(uint64).max) revert TKO_MINT_DISALLOWED();
        emit Mint(to, amount);
    }

    function _burn(address from, uint256 amount)
        internal
        override(ERC20Upgradeable, ERC20VotesUpgradeable)
    {
        super._burn(from, amount);
        emit Burn(from, amount);
    }
}

contract ProxiedTaikoToken is Proxied, TaikoToken {}

// SPDX-License-Identifier: MIT
//  _____     _ _         _         _
// |_   _|_ _(_) |_____  | |   __ _| |__ ___
//   | |/ _` | | / / _ \ | |__/ _` | '_ (_-<
//   |_|\__,_|_|_\_\___/ |____\__,_|_.__/__/

pragma solidity ^0.8.18;

library LibL2Consts {
    uint64 public constant ANCHOR_GAS_COST = 180000; // owner:david
}

// SPDX-License-Identifier: MIT
//  _____     _ _         _         _
// |_   _|_ _(_) |_____  | |   __ _| |__ ___
//   | |/ _` | | / / _ \ | |__/ _` | '_ (_-<
//   |_|\__,_|_|_\_\___/ |____\__,_|_.__/__/

pragma solidity ^0.8.18;

import {EssentialContract} from "../common/EssentialContract.sol";
import {Proxied} from "../common/Proxied.sol";
import {ICrossChainSync} from "../common/ICrossChainSync.sol";
import {LibL2Consts} from "./LibL2Consts.sol";
import {LibMath} from "../libs/LibMath.sol";
import {Lib1559Math} from "../libs/Lib1559Math.sol";
import {TaikoL2Signer} from "./TaikoL2Signer.sol";
import {SafeCastUpgradeable} from
    "@openzeppelin/contracts-upgradeable/utils/math/SafeCastUpgradeable.sol";

/// @custom:security-contact [email protected]
contract TaikoL2 is EssentialContract, TaikoL2Signer, ICrossChainSync {
    using SafeCastUpgradeable for uint256;
    using LibMath for uint256;

    struct VerifiedBlock {
        bytes32 blockHash;
        bytes32 signalRoot;
    }

    struct EIP1559Params {
        uint64 basefee;
        uint64 gasIssuedPerSecond;
        uint64 gasExcessMax;
        uint64 gasTarget;
        uint64 ratio2x1x;
    }

    struct EIP1559Config {
        uint128 yscale;
        uint64 xscale;
        uint64 gasIssuedPerSecond;
    }

    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    // Mapping from L2 block numbers to their block hashes.
    // All L2 block hashes will be saved in this mapping.
    mapping(uint256 blockNumber => bytes32 blockHash) private _l2Hashes;

    mapping(uint256 blockNumber => VerifiedBlock) private _l1VerifiedBlocks;

    // A hash to check the integrity of public inputs.
    bytes32 public publicInputHash;

    EIP1559Config private _eip1559Config;

    uint64 public parentTimestamp;
    uint64 public latestSyncedL1Height;
    uint64 public gasExcess;
    uint64 private __reserved1;

    uint256[45] private __gap;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    // Captures all block variables mentioned in
    // https://docs.soliditylang.org/en/v0.8.18/units-and-global-variables.html
    event Anchored(
        uint64 number,
        uint64 basefee,
        uint64 gaslimit,
        uint64 timestamp,
        bytes32 parentHash,
        uint256 prevrandao,
        address coinbase,
        uint32 chainid
    );

    /*//////////////////////////////////////////////////////////////
                             CUSTOM ERRORS
    //////////////////////////////////////////////////////////////*/

    error L2_BASEFEE_MISMATCH(uint64 expected, uint64 actual);
    error L2_INVALID_1559_PARAMS();
    error L2_INVALID_CHAIN_ID();
    error L2_INVALID_SENDER();
    error L2_PUBLIC_INPUT_HASH_MISMATCH(bytes32 expected, bytes32 actual);
    error L2_TOO_LATE();

    error M1559_UNEXPECTED_CHANGE(uint64 expected, uint64 actual);
    error M1559_OUT_OF_STOCK();

    /*//////////////////////////////////////////////////////////////
                         USER-FACING FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function init(address _addressManager, EIP1559Params calldata _param1559)
        external
        initializer
    {
        if (block.chainid <= 1 || block.chainid >= type(uint32).max) {
            revert L2_INVALID_CHAIN_ID();
        }
        if (block.number > 1) revert L2_TOO_LATE();

        if (_param1559.gasIssuedPerSecond != 0) {
            if (
                _param1559.basefee == 0 || _param1559.gasExcessMax == 0 || _param1559.gasTarget == 0
                    || _param1559.ratio2x1x == 0
            ) revert L2_INVALID_1559_PARAMS();

            (uint128 xscale, uint128 yscale) = Lib1559Math.calculateScales({
                xExcessMax: _param1559.gasExcessMax,
                price: _param1559.basefee,
                target: _param1559.gasTarget,
                ratio2x1x: _param1559.ratio2x1x
            });

            if (xscale == 0 || xscale >= type(uint64).max || yscale == 0) {
                revert L2_INVALID_1559_PARAMS();
            }
            _eip1559Config.yscale = yscale;
            _eip1559Config.xscale = uint64(xscale);
            _eip1559Config.gasIssuedPerSecond = _param1559.gasIssuedPerSecond;

            gasExcess = _param1559.gasExcessMax / 2;
        }

        parentTimestamp = uint64(block.timestamp);

        EssentialContract._init(_addressManager);

        (publicInputHash,) = _calcPublicInputHash(block.number);
        if (block.number > 0) {
            uint256 parentHeight = block.number - 1;
            _l2Hashes[parentHeight] = blockhash(parentHeight);
        }
    }

    /**
     * Persist the latest L1 block height and hash to L2 for cross-layer
     * message verification (eg. bridging). This function will also check
     * certain block-level global variables because they are not part of the
     * Trie structure.
     *
     * A circuit will verify the integrity among:
     * -  l1Hash, l1SignalRoot, and l1SignalServiceAddress
     * -  (l1Hash and l1SignalServiceAddress) are both hashed into of the
     *    ZKP's instance.
     *
     * This transaction shall be the first transaction in every L2 block.
     *
     * @param l1Hash The latest L1 block hash when this block was proposed.
     * @param l1SignalRoot The latest value of the L1 "signal service storage root".
     * @param l1Height The latest L1 block height when this block was proposed.
     * @param parentGasUsed the gas used in the parent block.
     */

    function anchor(bytes32 l1Hash, bytes32 l1SignalRoot, uint64 l1Height, uint64 parentGasUsed)
        external
    {
        if (msg.sender != GOLDEN_TOUCH_ADDRESS) revert L2_INVALID_SENDER();

        uint256 parentHeight = block.number - 1;
        bytes32 parentHash = blockhash(parentHeight);

        (bytes32 prevPIH, bytes32 currPIH) = _calcPublicInputHash(parentHeight);

        if (publicInputHash != prevPIH) {
            revert L2_PUBLIC_INPUT_HASH_MISMATCH(publicInputHash, prevPIH);
        }

        // replace the oldest block hash with the parent's blockhash
        publicInputHash = currPIH;
        _l2Hashes[parentHeight] = parentHash;

        latestSyncedL1Height = l1Height;
        _l1VerifiedBlocks[l1Height] = VerifiedBlock(l1Hash, l1SignalRoot);

        emit CrossChainSynced(l1Height, l1Hash, l1SignalRoot);

        // Check EIP-1559 basefee
        uint256 basefee;
        EIP1559Config memory config = getEIP1559Config();
        if (config.gasIssuedPerSecond != 0) {
            (basefee, gasExcess) = _calcBasefee(
                config, block.timestamp - parentTimestamp, uint64(block.gaslimit), parentGasUsed
            );
        }

        // On L2, basefee is not burnt, but sent to a treasury instead.
        // The circuits will need to verify the basefee recipient is the designated
        // address.
        if (block.basefee != basefee) {
            revert L2_BASEFEE_MISMATCH(uint64(basefee), uint64(block.basefee));
        }

        parentTimestamp = uint64(block.timestamp);

        // We emit this event so circuits can grab its data to verify block variables.
        // If plonk lookup table already has all these data, we can still use this
        // event for debugging purpose.
        emit Anchored({
            number: uint64(block.number),
            basefee: uint64(basefee),
            gaslimit: uint64(block.gaslimit),
            timestamp: uint64(block.timestamp),
            parentHash: parentHash,
            prevrandao: block.difficulty,
            coinbase: block.coinbase,
            chainid: uint32(block.chainid)
        });
    }

    function getBasefee(uint32 timeSinceParent, uint64 gasLimit, uint64 parentGasUsed)
        public
        view
        returns (uint256 _basefee)
    {
        (_basefee,) = _calcBasefee(getEIP1559Config(), timeSinceParent, gasLimit, parentGasUsed);
    }

    function getCrossChainBlockHash(uint256 number) public view override returns (bytes32) {
        uint256 _number = number == 0 ? latestSyncedL1Height : number;
        return _l1VerifiedBlocks[_number].blockHash;
    }

    function getCrossChainSignalRoot(uint256 number) public view override returns (bytes32) {
        uint256 _number = number == 0 ? latestSyncedL1Height : number;
        return _l1VerifiedBlocks[_number].signalRoot;
    }

    function getBlockHash(uint256 number) public view returns (bytes32) {
        if (number >= block.number) {
            return 0;
        } else if (number < block.number && number >= block.number - 256) {
            return blockhash(number);
        } else {
            return _l2Hashes[number];
        }
    }

    /// @dev Overide this funciton to return a constant EIP1559Config object
    // to avoid reading from storage to reduce gas cost.
    function getEIP1559Config() public view virtual returns (EIP1559Config memory) {
        return _eip1559Config;
    }

    /*//////////////////////////////////////////////////////////////
                           PRIVATE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function _calcPublicInputHash(uint256 blockNumber)
        private
        view
        returns (bytes32 prevPIH, bytes32 currPIH)
    {
        bytes32[256] memory inputs;
        unchecked {
            // put the previous 255 blockhashes (excluding the parent's) into a
            // ring buffer.
            for (uint256 i; i < 255 && blockNumber >= i + 1; ++i) {
                uint256 j = blockNumber - i - 1;
                inputs[j % 255] = blockhash(j);
            }
        }

        inputs[255] = bytes32(block.chainid);

        assembly {
            prevPIH := keccak256(inputs, mul(256, 32))
        }

        inputs[blockNumber % 255] = blockhash(blockNumber);
        assembly {
            currPIH := keccak256(inputs, mul(256, 32))
        }
    }

    function _calcBasefee(
        EIP1559Config memory config,
        uint256 timeSinceParent,
        uint64 gasLimit,
        uint64 parentGasUsed
    ) private view returns (uint256 _basefee, uint64 _gasExcess) {
        // Very important to cap _gasExcess uint64
        unchecked {
            uint64 parentGasUsedNet = parentGasUsed > LibL2Consts.ANCHOR_GAS_COST
                ? parentGasUsed - LibL2Consts.ANCHOR_GAS_COST
                : 0;

            uint256 a = uint256(gasExcess) + parentGasUsedNet;
            uint256 b = config.gasIssuedPerSecond * timeSinceParent;
            _gasExcess = uint64((a.max(b) - b).min(type(uint64).max));
        }

        _basefee = Lib1559Math.calculatePrice({
            xscale: config.xscale,
            yscale: config.yscale,
            xExcess: _gasExcess,
            xPurchase: gasLimit
        });
        if (_basefee == 0) {
            // To make sure when 1559 is enabled, the basefee is non-zero
            // (geth never use 0 values for basefee)
            _basefee = 1;
        }
    }
}

contract ProxiedTaikoL2 is Proxied, TaikoL2 {}

// SPDX-License-Identifier: MIT
//  _____     _ _         _         _
// |_   _|_ _(_) |_____  | |   __ _| |__ ___
//   | |/ _` | | / / _ \ | |__/ _` | '_ (_-<
//   |_|\__,_|_|_\_\___/ |____\__,_|_.__/__/

pragma solidity ^0.8.18;

import {LibUint512Math} from "../libs/LibUint512Math.sol";

abstract contract TaikoL2Signer {
    address public constant GOLDEN_TOUCH_ADDRESS = 0x0000777735367b36bC9B61C50022d9D0700dB4Ec;
    uint256 public constant GOLDEN_TOUCH_PRIVATEKEY =
        0x92954368afd3caa1f3ce3ead0069c1af414054aefe1ef9aeacc1bf426222ce38;

    uint256 private constant GX = 0x79BE667EF9DCBBAC55A06295CE870B07029BFCDB2DCE28D959F2815B16F81798;
    uint256 private constant GY = 0x483ADA7726A3C4655DA4FBFC0E1108A8FD17B448A68554199C47D08FFB10D4B8;

    uint256 private constant GX2 =
        0xc6047f9441ed7d6d3045406e95c07cd85c778e4b8cef3ca7abac09b95c709ee5;
    uint256 private constant GY2 =
        0x1ae168fea63dc339a3c58419466ceaeef7f632653266d0e1236431a950cfe52a;

    uint256 private constant N = 0xfffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141;

    // (
    //     uint256 GX_MUL_GOLDEN_TOUCH_PRIVATEKEY_LOW,
    //     uint256 GX_MUL_GOLDEN_TOUCH_PRIVATEKEY_HIGH
    // ) = LibUint512Math.mul(GX, GOLDEN_TOUCH_PRIVATEKEY);
    uint256 private constant GX_MUL_GOLDEN_TOUCH_PRIVATEKEY_LOW =
        0xb4a95509ce05fe8d45987859a067780d16a367c0e2cacf79cd301b93fb717940;
    uint256 private constant GX_MUL_GOLDEN_TOUCH_PRIVATEKEY_HIGH =
        0x45b59254b0320fd853f3f38ac574999e91bd75fd5e6cab9c22c5e71fc6d276e4;

    // (
    //     uint256 GX2_MUL_GOLDEN_TOUCH_PRIVATEKEY_LOW,
    //     uint256 GX2_MUL_GOLDEN_TOUCH_PRIVATEKEY_HIGH
    // ) = LibUint512Math.mul(GX2, GOLDEN_TOUCH_PRIVATEKEY);
    uint256 private constant GX2_MUL_GOLDEN_TOUCH_PRIVATEKEY_LOW =
        0xad77eceea844778cb4376153fc8f06f12f1695df4585bf75bfb17ec19ce90818;
    uint256 private constant GX2_MUL_GOLDEN_TOUCH_PRIVATEKEY_HIGH =
        0x71620584f61c57e688bbd3fd7a39a036e588d962c4c830f3dacbc15c917e02f2;

    // Invert K (= 2) in the field F(N)
    uint256 private constant K_2_INVM_N =
        0x7fffffffffffffffffffffffffffffff5d576e7357a4501ddfe92f46681b20a1;

    error L2_INVALID_GOLDEN_TOUCH_K();

    function signAnchor(bytes32 digest, uint8 k)
        public
        view
        returns (uint8 v, uint256 r, uint256 s)
    {
        if (k != 1 && k != 2) revert L2_INVALID_GOLDEN_TOUCH_K();

        r = k == 1 ? GX : GX2;

        uint256 low256 =
            k == 1 ? GX_MUL_GOLDEN_TOUCH_PRIVATEKEY_LOW : GX2_MUL_GOLDEN_TOUCH_PRIVATEKEY_LOW;

        uint256 high256 =
            k == 1 ? GX_MUL_GOLDEN_TOUCH_PRIVATEKEY_HIGH : GX2_MUL_GOLDEN_TOUCH_PRIVATEKEY_HIGH;

        (low256, high256) = LibUint512Math.add(low256, high256, uint256(digest), 0);

        if (k == 1) {
            s = _expmod(low256, high256, 1, N);
        } else {
            (low256, high256) = LibUint512Math.mul(K_2_INVM_N, _expmod(low256, high256, 1, N));
            s = _expmod(low256, high256, 1, N);
        }

        if (s > N >> 1) {
            s = N - s;
            v ^= 1;
        }
    }

    function _expmod(uint256 baseLow, uint256 baseHigh, uint256 e, uint256 m)
        private
        view
        returns (uint256 o)
    {
        assembly {
            // define pointer
            let p := mload(0x40)
            // store data assembly-favouring ways
            mstore(p, 0x40) // Length of Base
            mstore(add(p, 0x20), 0x20) // Length of Exponent
            mstore(add(p, 0x40), 0x20) // Length of Modulus
            mstore(add(p, 0x60), baseHigh) // BaseHigh
            mstore(add(p, 0x80), baseLow) // BaseLow
            mstore(add(p, 0xa0), e) // Exponent
            mstore(add(p, 0xc0), m) // Modulus

            if iszero(staticcall(sub(gas(), 2000), 0x05, p, 0xe0, p, 0x20)) { revert(0, 0) }
            // data
            o := mload(p)
        }
    }
}

// SPDX-License-Identifier: MIT
//  _____     _ _         _         _
// |_   _|_ _(_) |_____  | |   __ _| |__ ___
//   | |/ _` | | / / _ \ | |__/ _` | '_ (_-<
//   |_|\__,_|_|_\_\___/ |____\__,_|_.__/__/

pragma solidity ^0.8.18;

import {LibFixedPointMath} from "../thirdparty/LibFixedPointMath.sol";
import {SafeCastUpgradeable} from
    "@openzeppelin/contracts-upgradeable/utils/math/SafeCastUpgradeable.sol";

library Lib1559Math {
    using SafeCastUpgradeable for uint256;

    error M1559_UNEXPECTED_CHANGE(uint64 expected, uint64 actual);
    error M1559_OUT_OF_STOCK();

    function calculateScales(uint64 xExcessMax, uint64 price, uint64 target, uint64 ratio2x1x)
        internal
        pure
        returns (uint128 xscale, uint128 yscale)
    {
        assert(xExcessMax != 0);
        uint64 x = xExcessMax / 2;

        // calculate xscale
        xscale = LibFixedPointMath.MAX_EXP_INPUT / xExcessMax;

        // calculate yscale
        yscale = calculatePrice(xscale, price, x, target).toUint128();

        // Verify the gas price ratio between two blocks, one has
        // 2*target gas and the other one has target gas.
        uint256 price1x = calculatePrice(xscale, yscale, x, target);
        uint256 price2x = calculatePrice(xscale, yscale, x, target * 2);
        uint64 ratio = uint64((price2x * 10000) / price1x);

        if (ratio2x1x != ratio) {
            revert M1559_UNEXPECTED_CHANGE(ratio2x1x, ratio);
        }
    }

    function calculatePrice(uint128 xscale, uint128 yscale, uint64 xExcess, uint64 xPurchase)
        internal
        pure
        returns (uint256)
    {
        assert(xscale != 0 && yscale != 0);
        uint64 _xPurchase = xPurchase == 0 ? 1 : xPurchase;
        uint256 _before = _calcY(xExcess, xscale);
        uint256 _after = _calcY(xExcess + _xPurchase, xscale);
        return (_after - _before) / _xPurchase / yscale;
    }

    function _calcY(uint256 x, uint128 xscale) private pure returns (uint256) {
        uint256 _x = x * xscale;
        if (_x >= LibFixedPointMath.MAX_EXP_INPUT) {
            revert M1559_OUT_OF_STOCK();
        }
        return uint256(LibFixedPointMath.exp(int256(_x)));
    }
}

// SPDX-License-Identifier: MIT
//  _____     _ _         _         _
// |_   _|_ _(_) |_____  | |   __ _| |__ ___
//   | |/ _` | | / / _ \ | |__/ _` | '_ (_-<
//   |_|\__,_|_|_\_\___/ |____\__,_|_.__/__/

pragma solidity ^0.8.18;

/**
 * This library offers address-related methods.
 */
library LibAddress {
    /**
     * Sends Ether to an address. Zero-value will also be sent.
     * See more information at:
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now.
     * @param to The target address.
     * @param amount The amount of Ether to send.
     */
    function sendEther(address to, uint256 amount) internal {
        if (amount == 0 || to == address(0)) return;
        (bool success,) = payable(to).call{value: amount}("");
        require(success, "ETH transfer failed");
    }

    function codeHash(address addr) internal view returns (bytes32 codehash) {
        assembly {
            codehash := extcodehash(addr)
        }
    }
}

// SPDX-License-Identifier: MIT
//  _____     _ _         _         _
// |_   _|_ _(_) |_____  | |   __ _| |__ ___
//   | |/ _` | | / / _ \ | |__/ _` | '_ (_-<
//   |_|\__,_|_|_\_\___/ |____\__,_|_.__/__/

pragma solidity ^0.8.18;

import {LibRLPWriter} from "../thirdparty/LibRLPWriter.sol";

struct BlockHeader {
    bytes32 parentHash;
    bytes32 ommersHash;
    address beneficiary;
    bytes32 stateRoot;
    bytes32 transactionsRoot;
    bytes32 receiptsRoot;
    bytes32[8] logsBloom;
    uint256 difficulty;
    uint128 height;
    uint64 gasLimit;
    uint64 gasUsed;
    uint64 timestamp;
    bytes extraData;
    bytes32 mixHash;
    uint64 nonce;
    uint256 baseFeePerGas;
    bytes32 withdrawalsRoot;
}

library LibBlockHeader {
    bytes32 public constant EMPTY_OMMERS_HASH =
        0x1dcc4de8dec75d7aab85b567b6ccd41ad312451b948a7413f0a142fd40d49347;

    function hashBlockHeader(BlockHeader memory header) internal pure returns (bytes32) {
        bytes memory rlpHeader = LibRLPWriter.writeList(getBlockHeaderRLPItemsList(header, 0));
        return keccak256(rlpHeader);
    }

    function getBlockHeaderRLPItemsList(BlockHeader memory header, uint256 extraCapacity)
        internal
        pure
        returns (bytes[] memory list)
    {
        if (header.withdrawalsRoot != 0) {
            // EIP-4895 transaction
            list = new bytes[](17 + extraCapacity);
        } else if (header.baseFeePerGas != 0) {
            // EIP-1559 transaction
            list = new bytes[](16 + extraCapacity);
        } else {
            // non-EIP-1559 transaction
            list = new bytes[](15 + extraCapacity);
        }
        list[0] = LibRLPWriter.writeHash(header.parentHash);
        list[1] = LibRLPWriter.writeHash(header.ommersHash);
        list[2] = LibRLPWriter.writeAddress(header.beneficiary);
        list[3] = LibRLPWriter.writeHash(header.stateRoot);
        list[4] = LibRLPWriter.writeHash(header.transactionsRoot);
        list[5] = LibRLPWriter.writeHash(header.receiptsRoot);
        list[6] = LibRLPWriter.writeBytes(abi.encodePacked(header.logsBloom));
        list[7] = LibRLPWriter.writeUint(header.difficulty);
        list[8] = LibRLPWriter.writeUint(header.height);
        list[9] = LibRLPWriter.writeUint64(header.gasLimit);
        list[10] = LibRLPWriter.writeUint64(header.gasUsed);
        list[11] = LibRLPWriter.writeUint64(header.timestamp);
        list[12] = LibRLPWriter.writeBytes(header.extraData);
        list[13] = LibRLPWriter.writeHash(header.mixHash);
        // According to the ethereum yellow paper, we should treat `nonce`
        // as [8]byte when hashing the block.
        list[14] = LibRLPWriter.writeBytes(abi.encodePacked(header.nonce));
        if (header.baseFeePerGas != 0) {
            // EIP-1559 transaction
            list[15] = LibRLPWriter.writeUint(header.baseFeePerGas);
        }
        if (header.withdrawalsRoot != 0) {
            // EIP-4895 transaction
            list[16] = LibRLPWriter.writeHash(header.withdrawalsRoot);
        }
    }
}

// SPDX-License-Identifier: MIT
//  _____     _ _         _         _
// |_   _|_ _(_) |_____  | |   __ _| |__ ___
//   | |/ _` | | / / _ \ | |__/ _` | '_ (_-<
//   |_|\__,_|_|_\_\___/ |____\__,_|_.__/__/

pragma solidity ^0.8.18;

/**
 * @notice This library offers additional math functions for uint256.
 */

library LibMath {
    /**
     * @notice Returns the smaller value between the two given values.
     * @param a One of the two values.
     * @param b The other one of the two values.
     * @return The smaller value.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? b : a;
    }

    /**
     * @notice Returns the larger value between the two given values.
     * @param a One of the two values.
     * @param b The other one of the two values.
     * @return The larger value.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }
}

// SPDX-License-Identifier: MIT
//  _____     _ _         _         _
// |_   _|_ _(_) |_____  | |   __ _| |__ ___
//   | |/ _` | | / / _ \ | |__/ _` | '_ (_-<
//   |_|\__,_|_|_\_\___/ |____\__,_|_.__/__/

pragma solidity ^0.8.18;

import {LibRLPReader} from "../thirdparty/LibRLPReader.sol";
import {LibRLPWriter} from "../thirdparty/LibRLPWriter.sol";
import {LibSecureMerkleTrie} from "../thirdparty/LibSecureMerkleTrie.sol";

/**
 * @title LibTrieProof
 */
library LibTrieProof {
    /*//////////////////////////////////////////////////////////////
                               CONSTANTS
    //////////////////////////////////////////////////////////////*/

    // The consensus format representing account is RLP encoded in the
    // following order: nonce, balance, storageHash, codeHash.
    uint256 private constant ACCOUNT_FIELD_INDEX_STORAGE_HASH = 2;

    /*//////////////////////////////////////////////////////////////
                         USER-FACING FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * Verifies that the value of a slot in the storage of an account is value.
     *
     * @param stateRoot The merkle root of state tree..
     * @param slot The slot in the contract.
     * @param value The value to be verified.
     * @param mkproof The proof obtained by encoding storage proof.
     * @return verified The verification result.
     */
    function verifyWithAccountProof(
        bytes32 stateRoot,
        address addr,
        bytes32 slot,
        bytes32 value,
        bytes calldata mkproof
    ) public pure returns (bool verified) {
        (bytes memory accountProof, bytes memory storageProof) = abi.decode(mkproof, (bytes, bytes));

        (bool exists, bytes memory rlpAccount) =
            LibSecureMerkleTrie.get(abi.encodePacked(addr), accountProof, stateRoot);

        require(exists, "LTP:invalid account proof");

        LibRLPReader.RLPItem[] memory accountState = LibRLPReader.readList(rlpAccount);
        bytes32 storageRoot =
            LibRLPReader.readBytes32(accountState[ACCOUNT_FIELD_INDEX_STORAGE_HASH]);

        verified = LibSecureMerkleTrie.verifyInclusionProof(
            abi.encodePacked(slot), LibRLPWriter.writeBytes32(value), storageProof, storageRoot
        );
    }
}

// SPDX-License-Identifier: MIT
// The MIT License (MIT)
//
// Copyright (c) 2021 Remco Bloemen
// Copyright (c) 2022-2023 Taiko Labs
//
// Permission is hereby granted, free of charge, to any person obtaining
// a copy of this software and associated documentation files (the
// "Software"), to deal in the Software without restriction, including
// without limitation the rights to use, copy, modify, merge, publish,
// distribute, sublicense, and/or sell copies of the Software, and to
// permit persons to whom the Software is furnished to do so, subject to
// the following conditions:
//
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
// IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
// CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
// TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
// SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

pragma solidity ^0.8.18;

library LibUint512Math {
    /**
     * Optimized full 512 bit multiplication in Solidity.
     * Taken from: https://xn--2-umb.com/17/full-mul/index.html
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 r0, uint256 r1) {
        assembly {
            let mm := mulmod(a, b, not(0))
            r0 := mul(a, b)
            r1 := sub(sub(mm, r0), lt(mm, r0))
        }
    }

    /**
     * Simple 512-bit addition. Taken from:
     * https://xn--2-umb.com/17/512-bit-division/#add-subtract-two-512-bit-numbers
     */
    function add(uint256 a0, uint256 a1, uint256 b0, uint256 b1)
        internal
        pure
        returns (uint256 r0, uint256 r1)
    {
        assembly {
            r0 := add(a0, b0)
            r1 := add(add(a1, b1), lt(r0, a0))
        }
    }
}

// SPDX-License-Identifier: MIT
//  _____     _ _         _         _
// |_   _|_ _(_) |_____  | |   __ _| |__ ___
//   | |/ _` | | / / _ \ | |__/ _` | '_ (_-<
//   |_|\__,_|_|_\_\___/ |____\__,_|_.__/__/

pragma solidity ^0.8.18;

interface ISignalService {
    /**
     * Send a signal by storing the key with a value of 1.
     *
     * @param signal The signal to send.
     * @return storageSlot The slot in storage that this signal is persisted.
     */
    function sendSignal(bytes32 signal) external returns (bytes32 storageSlot);

    /**
     * Check if a signal has been sent (key stored with a value of 1).
     *
     * @param app The address that sent this message.
     * @param signal The signal to check.
     */
    function isSignalSent(address app, bytes32 signal) external view returns (bool);

    /**
     * Check if signal has been received on the destination chain (current).
     *
     * @param srcChainId The source chain ID.
     * @param app The address that sent this message.
     * @param signal The signal to check.
     * @param proof The proof of the signal being sent on the source chain.
     */
    function isSignalReceived(uint256 srcChainId, address app, bytes32 signal, bytes calldata proof)
        external
        view
        returns (bool);
}

// SPDX-License-Identifier: MIT
//  _____     _ _         _         _
// |_   _|_ _(_) |_____  | |   __ _| |__ ___
//   | |/ _` | | / / _ \ | |__/ _` | '_ (_-<
//   |_|\__,_|_|_\_\___/ |____\__,_|_.__/__/

pragma solidity ^0.8.18;

import {EssentialContract} from "../common/EssentialContract.sol";
import {Proxied} from "../common/Proxied.sol";
import {ISignalService} from "./ISignalService.sol";
import {ICrossChainSync} from "../common/ICrossChainSync.sol";
import {LibSecureMerkleTrie} from "../thirdparty/LibSecureMerkleTrie.sol";

/// @custom:security-contact [email protected]
contract SignalService is ISignalService, EssentialContract {
    struct SignalProof {
        uint256 height;
        bytes proof;
    }

    error B_ZERO_SIGNAL();
    error B_NULL_APP_ADDR();
    error B_WRONG_CHAIN_ID();

    /// @dev Initializer to be called after being deployed behind a proxy.
    function init(address _addressManager) external initializer {
        EssentialContract._init(_addressManager);
    }

    function sendSignal(bytes32 signal) public returns (bytes32 storageSlot) {
        if (signal == 0) {
            revert B_ZERO_SIGNAL();
        }

        storageSlot = getSignalSlot(msg.sender, signal);
        assembly {
            sstore(storageSlot, 1)
        }
    }

    function isSignalSent(address app, bytes32 signal) public view returns (bool) {
        if (app == address(0)) {
            revert B_NULL_APP_ADDR();
        }

        if (signal == 0) {
            revert B_ZERO_SIGNAL();
        }

        bytes32 slot = getSignalSlot(app, signal);
        uint256 value;
        assembly {
            value := sload(slot)
        }
        return value == 1;
    }

    function isSignalReceived(uint256 srcChainId, address app, bytes32 signal, bytes calldata proof)
        public
        view
        returns (bool)
    {
        if (srcChainId == block.chainid) revert B_WRONG_CHAIN_ID();
        if (app == address(0)) revert B_NULL_APP_ADDR();
        if (signal == 0) revert B_ZERO_SIGNAL();

        SignalProof memory sp = abi.decode(proof, (SignalProof));

        // Resolve the TaikoL1 or TaikoL2 contract if on Ethereum or Taiko.
        bytes32 syncedSignalRoot =
            ICrossChainSync(resolve("taiko", false)).getCrossChainSignalRoot(sp.height);

        return LibSecureMerkleTrie.verifyInclusionProof(
            bytes.concat(getSignalSlot(app, signal)), hex"01", sp.proof, syncedSignalRoot
        );
    }

    /**
     * @param app The srcAddress of the app (eg. the Bridge).
     * @param signal The signal to store.
     * @return signalSlot The storage key for the signal on the signal service.
     */
    function getSignalSlot(address app, bytes32 signal) public pure returns (bytes32 signalSlot) {
        // Equivilance to `keccak256(abi.encodePacked(app, signal))`
        assembly {
            // Load the free memory pointer and allocate memory for the concatenated arguments
            let ptr := mload(0x40)

            // Store the app address and signal bytes32 value in the allocated memory
            mstore(ptr, app)
            mstore(add(ptr, 32), signal)

            // Calculate the hash of the concatenated arguments using keccak256
            signalSlot := keccak256(add(ptr, 12), 52)

            // Update free memory pointer
            mstore(0x40, add(ptr, 64))
        }
    }
}

contract ProxiedSignalService is Proxied, SignalService {}

// SPDX-License-Identifier: MIT
//  _____     _ _         _         _
// |_   _|_ _(_) |_____  | |   __ _| |__ ___
//   | |/ _` | | / / _ \ | |__/ _` | '_ (_-<
//   |_|\__,_|_|_\_\___/ |____\__,_|_.__/__/

pragma solidity ^0.8.18;

import {LibBridgeData} from "../../../bridge/libs/LibBridgeData.sol";
import {LibBridgeStatus} from "../../../bridge/libs/LibBridgeStatus.sol";
import {IBridge} from "../../../bridge/IBridge.sol";

// TODO(roger): remove this file. If you need extra functionality in
// the Bridge contract, create a TestBridge.sol contract instead.
contract TestLibBridgeData {
    function updateMessageStatus(bytes32 signal, LibBridgeStatus.MessageStatus status) public {
        LibBridgeStatus.updateMessageStatus(signal, status);
    }

    function getMessageStatus(bytes32 signal) public view returns (LibBridgeStatus.MessageStatus) {
        return LibBridgeStatus.getMessageStatus(signal);
    }

    function hashMessage(IBridge.Message memory message) public pure returns (bytes32) {
        return LibBridgeData.hashMessage(message);
    }
}

// SPDX-License-Identifier: MIT
//  _____     _ _         _         _
// |_   _|_ _(_) |_____  | |   __ _| |__ ___
//   | |/ _` | | / / _ \ | |__/ _` | '_ (_-<
//   |_|\__,_|_|_\_\___/ |____\__,_|_.__/__/

pragma solidity ^0.8.18;

import {LibBridgeInvoke} from "../../../bridge/libs/LibBridgeInvoke.sol";
import {LibBridgeData} from "../../../bridge/libs/LibBridgeData.sol";
import {IBridge} from "../../../bridge/IBridge.sol";

// TODO(roger): remove this file. If you need extra functionality in
// the Bridge contract, create a TestBridge.sol contract instead.
contract TestLibBridgeInvoke {
    LibBridgeData.State public state;

    event MessageInvoked(bytes32 signal, bool success);

    function invokeMessageCall(IBridge.Message calldata message, bytes32 signal, uint256 gasLimit)
        public
        payable
    {
        bool success = LibBridgeInvoke.invokeMessageCall(state, message, signal, gasLimit);
        emit MessageInvoked(signal, success);
    }
}

// SPDX-License-Identifier: MIT
//  _____     _ _         _         _
// |_   _|_ _(_) |_____  | |   __ _| |__ ___
//   | |/ _` | | / / _ \ | |__/ _` | '_ (_-<
//   |_|\__,_|_|_\_\___/ |____\__,_|_.__/__/

pragma solidity ^0.8.18;

import {EssentialContract} from "../../../common/EssentialContract.sol";
import {LibBridgeProcess} from "../../../bridge/libs/LibBridgeProcess.sol";
import {LibBridgeData} from "../../../bridge/libs/LibBridgeData.sol";
import {IBridge} from "../../../bridge/IBridge.sol";
import {AddressResolver} from "../../../common/AddressResolver.sol";

// TODO(roger): remove this file. If you need extra functionality in
// the Bridge contract, create a TestBridge.sol contract instead.
contract TestLibBridgeProcess is EssentialContract {
    LibBridgeData.State public state;

    function init(address _addressManager) external initializer {
        EssentialContract._init(_addressManager);
    }

    function processMessage(IBridge.Message calldata message, bytes calldata proof)
        public
        payable
    {
        LibBridgeProcess.processMessage(state, AddressResolver(this), message, proof);
    }
}

// SPDX-License-Identifier: MIT
//  _____     _ _         _         _
// |_   _|_ _(_) |_____  | |   __ _| |__ ___
//   | |/ _` | | / / _ \ | |__/ _` | '_ (_-<
//   |_|\__,_|_|_\_\___/ |____\__,_|_.__/__/

pragma solidity ^0.8.18;

import {EssentialContract} from "../../../common/EssentialContract.sol";
import {LibBridgeData} from "../../../bridge/libs/LibBridgeData.sol";
import {LibBridgeRetry} from "../../../bridge/libs/LibBridgeRetry.sol";
import {IBridge} from "../../../bridge/IBridge.sol";
import {AddressResolver} from "../../../common/AddressResolver.sol";

// TODO(roger): remove this file. If you need extra functionality in
// the Bridge contract, create a TestBridge.sol contract instead.
contract TestLibBridgeRetry is EssentialContract {
    LibBridgeData.State public state;

    receive() external payable {}

    function init(address _addressManager) external initializer {
        EssentialContract._init(_addressManager);
    }

    function retryMessage(IBridge.Message calldata message, bool lastAttempt) public payable {
        LibBridgeRetry.retryMessage(state, AddressResolver(this), message, lastAttempt);
    }
}

// SPDX-License-Identifier: MIT
//  _____     _ _         _         _
// |_   _|_ _(_) |_____  | |   __ _| |__ ___
//   | |/ _` | | / / _ \ | |__/ _` | '_ (_-<
//   |_|\__,_|_|_\_\___/ |____\__,_|_.__/__/

pragma solidity ^0.8.18;

import {EssentialContract} from "../../../common/EssentialContract.sol";
import {LibBridgeSend} from "../../../bridge/libs/LibBridgeSend.sol";
import {AddressResolver} from "../../../common/AddressResolver.sol";
import {IBridge} from "../../../bridge/IBridge.sol";
import {LibBridgeData} from "../../../bridge/libs/LibBridgeData.sol";

// TODO(roger): remove this file. If you need extra functionality in
// the Bridge contract, create a TestBridge.sol contract instead.
contract TestLibBridgeSend is EssentialContract {
    LibBridgeData.State public state;

    function init(address _addressManager) external initializer {
        EssentialContract._init(_addressManager);
    }

    function sendMessage(IBridge.Message memory message) public payable returns (bytes32 signal) {
        return LibBridgeSend.sendMessage(state, AddressResolver(this), message);
    }
}

// SPDX-License-Identifier: MIT
//  _____     _ _         _         _
// |_   _|_ _(_) |_____  | |   __ _| |__ ___
//   | |/ _` | | / / _ \ | |__/ _` | '_ (_-<
//   |_|\__,_|_|_\_\___/ |____\__,_|_.__/__/

pragma solidity ^0.8.18;

contract TestReceiver {
    event Received(address from, uint256 amount);
    event Fallback(address from, uint256 amount);

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    fallback() external payable {
        emit Fallback(msg.sender, msg.value);
    }

    function receiveTokens(uint256 amt) external payable {
        emit Received(msg.sender, amt);
    }

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
}

// SPDX-License-Identifier: MIT
//  _____     _ _         _         _
// |_   _|_ _(_) |_____  | |   __ _| |__ ___
//   | |/ _` | | / / _ \ | |__/ _` | '_ (_-<
//   |_|\__,_|_|_\_\___/ |____\__,_|_.__/__/

pragma solidity ^0.8.18;

import {ICrossChainSync} from "../../common/ICrossChainSync.sol";

// TODO(roger): remove this file. If you need extra functionality in
// the Bridge contract, create a TestBridge.sol contract instead.
contract TestCrossChainSync is ICrossChainSync {
    bytes32 private _blockHash;
    bytes32 private _signalRoot;

    function setCrossChainBlockHeader(bytes32 blockHash) external {
        _blockHash = blockHash;
    }

    function setCrossChainSignalRoot(bytes32 signalRoot) external {
        _signalRoot = signalRoot;
    }

    function getCrossChainBlockHash(uint256) external view returns (bytes32) {
        return _blockHash;
    }

    function getCrossChainSignalRoot(uint256) external view returns (bytes32) {
        return _signalRoot;
    }
}

// SPDX-License-Identifier: MIT
//  _____     _ _         _         _
// |_   _|_ _(_) |_____  | |   __ _| |__ ___
//   | |/ _` | | / / _ \ | |__/ _` | '_ (_-<
//   |_|\__,_|_|_\_\___/ |____\__,_|_.__/__/

pragma solidity ^0.8.18;

import {ERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

// An ERC20 Token with a mint function anyone can call, for free, to receive
// 5 tokens.
contract FreeMintERC20 is ERC20 {
    mapping(address minter => bool hasMinted) public minters;

    error HasMinted();

    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

    function mint(address to) public {
        if (minters[to]) {
            revert HasMinted();
        }

        minters[to] = true;
        _mint(to, 50 * (10 ** decimals()));
    }
}

// SPDX-License-Identifier: MIT
//  _____     _ _         _         _
// |_   _|_ _(_) |_____  | |   __ _| |__ ___
//   | |/ _` | | / / _ \ | |__/ _` | '_ (_-<
//   |_|\__,_|_|_\_\___/ |____\__,_|_.__/__/

pragma solidity ^0.8.18;

import {ERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

// An ERC20 token for testing the Taiko Bridge on testnets.
// This token has 50% of failure on transfers so we can
// test the bridge's error handling.
contract MayFailFreeMintERC20 is ERC20 {
    mapping(address minter => bool hasMinted) public minters;

    error HasMinted();

    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

    function mint(address to) public {
        if (minters[msg.sender]) {
            revert HasMinted();
        }

        minters[msg.sender] = true;
        _mint(to, 50 * (10 ** decimals()));
    }

    function transfer(address to, uint256 amount) public override returns (bool) {
        _mayFail();
        return ERC20.transfer(to, amount);
    }

    function transferFrom(address from, address to, uint256 amount)
        public
        override
        returns (bool)
    {
        _mayFail();
        return ERC20.transferFrom(from, to, amount);
    }

    // Have a 50% change of failure.
    function _mayFail() private view {
        if (block.number % 2 == 0) {
            revert("Failed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {ERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract RegularERC20 is ERC20 {
    constructor(uint256 initialSupply) ERC20("RegularERC20", "RGL") {
        _mint(msg.sender, initialSupply);
    }
}

// SPDX-License-Identifier: MIT
//  _____     _ _         _         _
// |_   _|_ _(_) |_____  | |   __ _| |__ ___
//   | |/ _` | | / / _ \ | |__/ _` | '_ (_-<
//   |_|\__,_|_|_\_\___/ |____\__,_|_.__/__/

pragma solidity ^0.8.18;

import {AddressManager} from "../common/AddressManager.sol";

/**
 * @title ExampleStaticAddressManager
 * Such a static lookup AddressManager can be used to replace
 * existing storage-based lookup AddressManager so we can avoid
 * SSLOAD easily.
 */
contract ExampleStaticAddressManager is AddressManager {
    function setAddress(uint256, /*domain*/ bytes32, /*nameHash*/ address /*newAddress*/ )
        external
        pure
        override
    {
        revert("");
    }

    /// @dev This function must be a pure function in order to avoid
    /// reading from storage.
    function getAddress(uint256 domain, bytes32 nameHash)
        external
        pure
        override
        returns (address addr)
    {
        if (domain == 1) {
            if (nameHash == "ether_vault") addr = address(0x123);
        } else if (domain == 167) {
            if (nameHash == "taiko") addr = address(0x456);
        }
    }
}

// SPDX-License-Identifier: MIT
//  _____     _ _         _         _
// |_   _|_ _(_) |_____  | |   __ _| |__ ___
//   | |/ _` | | / / _ \ | |__/ _` | '_ (_-<
//   |_|\__,_|_|_\_\___/ |____\__,_|_.__/__/

pragma solidity ^0.8.18;

import {TaikoL1} from "../../L1/TaikoL1.sol";
import {TaikoData} from "../../L1/TaikoData.sol";
import {Strings} from "lib/openzeppelin-contracts/contracts/utils/Strings.sol";

contract TestTaikoL1 is TaikoL1 {
    function getConfig() public pure override returns (TaikoData.Config memory config) {
        config.chainId = 167;
        // up to 2048 pending blocks
        config.maxNumProposedBlocks = 4;
        config.ringBufferSize = 6;
        // This number is calculated from maxNumProposedBlocks to make
        // the 'the maximum value of the multiplier' close to 20.0
        config.maxVerificationsPerTx = 0;
        config.blockMaxGasLimit = 30000000;
        config.maxTransactionsPerBlock = 20;
        config.maxBytesPerTxList = 120000;
    }
}

// SPDX-License-Identifier: MIT
//  _____     _ _         _         _
// |_   _|_ _(_) |_____  | |   __ _| |__ ___
//   | |/ _` | | / / _ \ | |__/ _` | '_ (_-<
//   |_|\__,_|_|_\_\___/ |____\__,_|_.__/__/

pragma solidity ^0.8.18;

import {TaikoL1} from "../../L1/TaikoL1.sol";
import {TaikoData} from "../../L1/TaikoData.sol";
import {Strings} from "lib/openzeppelin-contracts/contracts/utils/Strings.sol";

contract TestTaikoL1EnableTokenomics is TaikoL1 {
    function getConfig() public pure override returns (TaikoData.Config memory config) {
        config.chainId = 167;
        // up to 2048 pending blocks
        config.maxNumProposedBlocks = 6;
        config.ringBufferSize = 8;
        // This number is calculated from maxNumProposedBlocks to make
        // the 'the maximum value of the multiplier' close to 20.0
        config.maxVerificationsPerTx = 0; // dont verify blocks automatically
        config.blockMaxGasLimit = 30000000;
        config.maxTransactionsPerBlock = 20;
        config.maxBytesPerTxList = 120000;
    }
}

// SPDX-License-Identifier: MIT
//  _____     _ _         _         _
// |_   _|_ _(_) |_____  | |   __ _| |__ ___
//   | |/ _` | | / / _ \ | |__/ _` | '_ (_-<
//   |_|\__,_|_|_\_\___/ |____\__,_|_.__/__/

pragma solidity ^0.8.18;

import {LibBlockHeader, BlockHeader} from "../../libs/LibBlockHeader.sol";
import {LibRLPWriter} from "../../thirdparty/LibRLPWriter.sol";

contract TestLibBlockHeader {
    function hashBlockHeader(BlockHeader calldata header) public pure returns (bytes32) {
        return LibBlockHeader.hashBlockHeader(header);
    }

    function rlpBlockHeader(BlockHeader calldata header) public pure returns (bytes memory) {
        bytes[] memory list = new bytes[](15);
        list[0] = LibRLPWriter.writeHash(header.parentHash);
        list[1] = LibRLPWriter.writeHash(header.ommersHash);
        list[2] = LibRLPWriter.writeAddress(header.beneficiary);
        list[3] = LibRLPWriter.writeHash(header.stateRoot);
        list[4] = LibRLPWriter.writeHash(header.transactionsRoot);
        list[5] = LibRLPWriter.writeHash(header.receiptsRoot);
        list[6] = LibRLPWriter.writeBytes(abi.encodePacked(header.logsBloom));
        list[7] = LibRLPWriter.writeUint(header.difficulty);
        list[8] = LibRLPWriter.writeUint(header.height);
        list[9] = LibRLPWriter.writeUint64(header.gasLimit);
        list[10] = LibRLPWriter.writeUint64(header.gasUsed);
        list[11] = LibRLPWriter.writeUint64(header.timestamp);
        list[12] = LibRLPWriter.writeBytes(header.extraData);
        list[13] = LibRLPWriter.writeHash(header.mixHash);
        // According to the ethereum yellow paper, we should treat `nonce`
        // as [8]byte when hashing the block.
        list[14] = LibRLPWriter.writeBytes(abi.encodePacked(header.nonce));

        bytes memory rlpHeader = LibRLPWriter.writeList(list);
        return rlpHeader;
    }
}

// SPDX-License-Identifier: MIT
//  _____     _ _         _         _
// |_   _|_ _(_) |_____  | |   __ _| |__ ___
//   | |/ _` | | / / _ \ | |__/ _` | '_ (_-<
//   |_|\__,_|_|_\_\___/ |____\__,_|_.__/__/

pragma solidity ^0.8.18;

import {LibTrieProof} from "../../libs/LibTrieProof.sol";

contract TestLibTrieProof {
    function writeStorageAt(bytes32 slot, bytes32 val) public {
        assembly {
            sstore(slot, val)
        }
    }
}

// SPDX-License-Identifier: MIT
//  _____     _ _         _         _
// |_   _|_ _(_) |_____  | |   __ _| |__ ___
//   | |/ _` | | / / _ \ | |__/ _` | '_ (_-<
//   |_|\__,_|_|_\_\___/ |____\__,_|_.__/__/

pragma solidity ^0.8.18;

import {ERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {SignalService} from "../signal/SignalService.sol";
import {TokenVault} from "../bridge/TokenVault.sol";
import {EtherVault} from "../bridge/EtherVault.sol";
import {BridgedERC20} from "../bridge/BridgedERC20.sol";
import {Bridge} from "../bridge/Bridge.sol";
import {TaikoToken} from "../L1/TaikoToken.sol";
import {Strings} from "lib/openzeppelin-contracts/contracts/utils/Strings.sol";

// The old implementation that is also used in hardhat tests.

contract TestERC20 is ERC20 {
    constructor(uint256 initialSupply) ERC20("TestERC20", "TEST") {
        _mint(msg.sender, initialSupply);
    }
}

contract TestSignalService is SignalService {}

contract TestTokenVault is TokenVault {}

contract TestEtherVault is EtherVault {}

contract TestBridgedERC20 is BridgedERC20 {}

contract TestBridge is Bridge {}

contract TestTaikoToken is TaikoToken {
    function mintAnyone(address account, uint256 amount) public {
        _mint(account, amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {LibMerkleTrie} from "../../thirdparty/LibMerkleTrie.sol";

/**
 * @title TestLibMerkleTrie
 */
contract TestLibMerkleTrie {
    function verifyInclusionProof(
        bytes memory _key,
        bytes memory _value,
        bytes memory _proof,
        bytes32 _root
    ) public pure returns (bool) {
        return LibMerkleTrie.verifyInclusionProof(_key, _value, _proof, _root);
    }

    function get(bytes memory _key, bytes memory _proof, bytes32 _root)
        public
        pure
        returns (bool, bytes memory)
    {
        return LibMerkleTrie.get(_key, _proof, _root);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {LibRLPReader} from "../../thirdparty/LibRLPReader.sol";

/**
 * @title TestLibRLPReader
 */
contract TestLibRLPReader {
    function readList(bytes memory _in) public pure returns (bytes[] memory) {
        LibRLPReader.RLPItem[] memory decoded = LibRLPReader.readList(_in);
        bytes[] memory out = new bytes[](decoded.length);
        for (uint256 i; i < out.length; ++i) {
            out[i] = LibRLPReader.readRawBytes(decoded[i]);
        }
        return out;
    }

    function readString(bytes memory _in) public pure returns (string memory) {
        return LibRLPReader.readString(_in);
    }

    function readBytes(bytes memory _in) public pure returns (bytes memory) {
        return LibRLPReader.readBytes(_in);
    }

    function readBytes32(bytes memory _in) public pure returns (bytes32) {
        return LibRLPReader.readBytes32(_in);
    }

    function readUint256(bytes memory _in) public pure returns (uint256) {
        return LibRLPReader.readUint256(_in);
    }

    function readBool(bytes memory _in) public pure returns (bool) {
        return LibRLPReader.readBool(_in);
    }

    function readAddress(bytes memory _in) public pure returns (address) {
        return LibRLPReader.readAddress(_in);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {LibRLPWriter} from "../../thirdparty/LibRLPWriter.sol";

/**
 * @title TestLibRLPWriter
 */
contract TestLibRLPWriter {
    function writeBytes(bytes memory _in) public pure returns (bytes memory _out) {
        return LibRLPWriter.writeBytes(_in);
    }

    function writeList(bytes[] memory _in) public pure returns (bytes memory _out) {
        return LibRLPWriter.writeList(_in);
    }

    function writeString(string memory _in) public pure returns (bytes memory _out) {
        return LibRLPWriter.writeString(_in);
    }

    function writeAddress(address _in) public pure returns (bytes memory _out) {
        return LibRLPWriter.writeAddress(_in);
    }

    function writeUint(uint256 _in) public pure returns (bytes memory _out) {
        return LibRLPWriter.writeUint(_in);
    }

    function writeBool(bool _in) public pure returns (bytes memory _out) {
        return LibRLPWriter.writeBool(_in);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

/* Library Imports */
import {LibSecureMerkleTrie} from "../../thirdparty/LibSecureMerkleTrie.sol";

/**
 * @title TestLibSecureMerkleTrie
 */
contract TestLibSecureMerkleTrie {
    function verifyInclusionProof(
        bytes memory _key,
        bytes memory _value,
        bytes memory _proof,
        bytes32 _root
    ) public pure returns (bool) {
        return LibSecureMerkleTrie.verifyInclusionProof(_key, _value, _proof, _root);
    }

    function get(bytes memory _key, bytes memory _proof, bytes32 _root)
        public
        pure
        returns (bool, bytes memory)
    {
        return LibSecureMerkleTrie.get(_key, _proof, _root);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {IBridge} from "../../bridge/IBridge.sol";

contract TestMessageSender {
    bytes32 public signal = 0x3fd54831f488a22b28398de0c567a3b064b937f54f81739ae9bd545967f3abab;

    function sendMessage(IBridge.Message calldata message) external payable returns (bytes32) {
        message;
        return signal;
    }
}

// SPDX-License-Identifier: MIT
// Taken from https://github.com/ethereum-optimism/optimism/blob/develop/packages/contracts/contracts/libraries/utils/LibBytesUtils.sol
// (The MIT License)
//
// Copyright 2020-2021 Optimism
// Copyright 2022-2023 Taiko Labs
//
// Permission is hereby granted, free of charge, to any person obtaining
// a copy of this software and associated documentation files (the
// "Software"), to deal in the Software without restriction, including
// without limitation the rights to use, copy, modify, merge, publish,
// distribute, sublicense, and/or sell copies of the Software, and to
// permit persons to whom the Software is furnished to do so, subject to
// the following conditions:
//
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
// IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
// CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
// TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
// SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

pragma solidity ^0.8.18;

/**
 * @title LibBytesUtils
 */
library LibBytesUtils {
    /*//////////////////////////////////////////////////////////////
                           INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function slice(bytes memory _bytes, uint256 _start, uint256 _length)
        internal
        pure
        returns (bytes memory)
    {
        require(_length + 31 >= _length, "slice_overflow");
        require(_start + _length >= _start, "slice_overflow");
        require(_bytes.length >= _start + _length, "slice_outOfBounds");

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
                // Get a location of some free memory and store it in tempBytes as
                // Solidity does for memory variables.
                tempBytes := mload(0x40)

                // The first word of the slice result is potentially a partial
                // word read from the original array. To read it, we calculate
                // the length of that partial word and start copying that many
                // bytes into the array. The first word we copy will start with
                // data we don't care about, but the last `lengthmod` bytes will
                // land at the beginning of the contents of the new array. When
                // we're done copying, we overwrite the full first word with
                // the actual length of the slice.
                let lengthmod := and(_length, 31)

                // The multiplication in the next line is necessary
                // because when slicing multiples of 32 bytes (lengthmod == 0)
                // the following copy loop was copying the origin's length
                // and then ending prematurely not copying everything it should.
                let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                let end := add(mc, _length)

                for {
                    // The multiplication in the next line has the same exact purpose
                    // as the one above.
                    let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } { mstore(mc, mload(cc)) }

                mstore(tempBytes, _length)

                //update free-memory pointer
                //allocating the array padded to 32 bytes like the compiler does now
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            //if we want a zero-length slice let's just return a zero-length array
            default {
                tempBytes := mload(0x40)

                //zero out the 32 bytes slice we are about to return
                //we need to do it because Solidity does not garbage collect
                mstore(tempBytes, 0)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }

    function slice(bytes memory _bytes, uint256 _start) internal pure returns (bytes memory) {
        if (_start >= _bytes.length) {
            return bytes("");
        }

        return slice(_bytes, _start, _bytes.length - _start);
    }

    function toBytes32(bytes memory _bytes) internal pure returns (bytes32) {
        if (_bytes.length < 32) {
            bytes32 ret;
            assembly {
                ret := mload(add(_bytes, 32))
            }
            return ret;
        }

        return abi.decode(_bytes, (bytes32)); // will truncate if input length > 32 bytes
    }

    function toUint256(bytes memory _bytes) internal pure returns (uint256) {
        return uint256(toBytes32(_bytes));
    }

    function toNibbles(bytes memory _bytes) internal pure returns (bytes memory) {
        bytes memory nibbles = new bytes(_bytes.length * 2);

        for (uint256 i; i < _bytes.length; ++i) {
            nibbles[i * 2] = _bytes[i] >> 4;
            nibbles[i * 2 + 1] = bytes1(uint8(_bytes[i]) % 16);
        }

        return nibbles;
    }

    function fromNibbles(bytes memory _bytes) internal pure returns (bytes memory) {
        bytes memory ret = new bytes(_bytes.length / 2);

        for (uint256 i; i < ret.length; ++i) {
            ret[i] = (_bytes[i * 2] << 4) | (_bytes[i * 2 + 1]);
        }

        return ret;
    }

    function equal(bytes memory _bytes, bytes memory _other) internal pure returns (bool) {
        return keccak256(_bytes) == keccak256(_other);
    }
}

// SPDX-License-Identifier: UNLICENSED
// Taken from: https://github.com/recmo/experiment-solexp/blob/main/src/FixedPointMathLib.sol
pragma solidity ^0.8.18;

library LibFixedPointMath {
    uint128 public constant MAX_EXP_INPUT = 135305999368893231588;
    uint256 public constant SCALING_FACTOR_1E18 = 1e18; // For fixed point representation factor

    error Overflow();

    // Computes e^x in 1e18 fixed point.
    function exp(int256 x) internal pure returns (int256 r) {
        unchecked {
            // Input x is in fixed point format, with scale factor 1/1e18.

            // When the result is < 0.5 we return zero. This happens when
            // x <= floor(log(0.5e18) * 1e18) ~ -42e18
            if (x <= -42139678854452767551) {
                return 0;
            }

            // When the result is > (2**255 - 1) / 1e18 we can not represent it
            // as an int256. This happens when x >= floor(log((2**255 -1) / 1e18) * 1e18) ~ 135.
            if (x >= 135305999368893231589) revert Overflow();

            // x is now in the range (-42, 136) * 1e18. Convert to (-42, 136) * 2**96
            // for more intermediate precision and a binary basis. This base conversion
            // is a multiplication by 1e18 / 2**96 = 5**18 / 2**78.
            x = (x << 78) / 5 ** 18;

            // Reduce range of x to (-½ ln 2, ½ ln 2) * 2**96 by factoring out powers of two
            // such that exp(x) = exp(x') * 2**k, where k is an integer.
            // Solving this gives k = round(x / log(2)) and x' = x - k * log(2).
            int256 k = ((x << 96) / 54916777467707473351141471128 + 2 ** 95) >> 96;
            x = x - k * 54916777467707473351141471128;
            // k is in the range [-61, 195].

            // Evaluate using a (6, 7)-term rational approximation
            // p is made monic, we will multiply by a scale factor later
            int256 p = x + 2772001395605857295435445496992;
            p = ((p * x) >> 96) + 44335888930127919016834873520032;
            p = ((p * x) >> 96) + 398888492587501845352592340339721;
            p = ((p * x) >> 96) + 1993839819670624470859228494792842;
            p = p * x + (4385272521454847904632057985693276 << 96);
            // We leave p in 2**192 basis so we don't need to scale it back up for the division.
            // Evaluate using using Knuth's scheme from p. 491.
            int256 z = x + 750530180792738023273180420736;
            z = ((z * x) >> 96) + 32788456221302202726307501949080;
            int256 w = x - 2218138959503481824038194425854;
            w = ((w * z) >> 96) + 892943633302991980437332862907700;
            int256 q = z + w - 78174809823045304726920794422040;
            q = ((q * w) >> 96) + 4203224763890128580604056984195872;
            assembly {
                // Div in assembly because solidity adds a zero check despite the `unchecked`.
                // The q polynomial is known not to have zeros in the domain. (All roots are complex)
                // No scaling required because p is already 2**96 too large.
                r := sdiv(p, q)
            }
            // r should be in the range (0.09, 0.25) * 2**96.

            // We now need to multiply r by
            //  * the scale factor s = ~6.031367120...,
            //  * the 2**k factor from the range reduction, and
            //  * the 1e18 / 2**96 factor for base converison.
            // We do all of this at once, with an intermediate result in 2**213 basis
            // so the final right shift is always by a positive amount.
            r = int256(
                (uint256(r) * 3822833074963236453042738258902158003155416615667) >> uint256(195 - k)
            );
        }
    }
}

// SPDX-License-Identifier: MIT
// Taken from https://github.com/ethereum-optimism/optimism/blob/develop/packages/contracts/contracts/libraries/trie/LibMerkleTrie.sol
// (The MIT License)
//
// Copyright 2020-2021 Optimism
// Copyright 2022-2023 Taiko Labs
//
// Permission is hereby granted, free of charge, to any person obtaining
// a copy of this software and associated documentation files (the
// "Software"), to deal in the Software without restriction, including
// without limitation the rights to use, copy, modify, merge, publish,
// distribute, sublicense, and/or sell copies of the Software, and to
// permit persons to whom the Software is furnished to do so, subject to
// the following conditions:
//
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
// IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
// CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
// TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
// SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

pragma solidity ^0.8.18;

/* Library Imports */
import {LibBytesUtils} from "./LibBytesUtils.sol";
import {LibRLPReader} from "./LibRLPReader.sol";
import {LibRLPWriter} from "./LibRLPWriter.sol";

/**
 * @title LibMerkleTrie
 */
library LibMerkleTrie {
    /*//////////////////////////////////////////////////////////////
                                 ENUMS
    //////////////////////////////////////////////////////////////*/

    enum NodeType {
        BranchNode,
        ExtensionNode,
        LeafNode
    }

    /*//////////////////////////////////////////////////////////////
                                STRUCTS
    //////////////////////////////////////////////////////////////*/

    struct TrieNode {
        LibRLPReader.RLPItem[] decoded;
        bytes encoded;
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTANTS
    //////////////////////////////////////////////////////////////*/

    // TREE_RADIX determines the number of elements per branch node.
    uint8 private constant TREE_RADIX = 16;
    // Branch nodes have TREE_RADIX elements plus an additional `value` slot.
    uint8 private constant BRANCH_NODE_LENGTH = TREE_RADIX + 1;
    // Leaf nodes and extension nodes always have two elements, a `path` and a `value`.
    uint8 private constant LEAF_OR_EXTENSION_NODE_LENGTH = 2;

    // Prefixes are prepended to the `path` within a leaf or extension node and
    // allow us to differentiate between the two node types. `ODD` or `EVEN` is
    // determined by the number of nibbles within the unprefixed `path`. If the
    // number of nibbles if even, we need to insert an extra padding nibble so
    // the resulting prefixed `path` has an even number of nibbles.
    uint8 private constant PREFIX_EXTENSION_EVEN = 0;
    uint8 private constant PREFIX_EXTENSION_ODD = 1;
    uint8 private constant PREFIX_LEAF_EVEN = 2;
    uint8 private constant PREFIX_LEAF_ODD = 3;

    // Just a utility constant. RLP represents `NULL` as 0x80.
    bytes1 private constant RLP_NULL = bytes1(0x80);

    /*//////////////////////////////////////////////////////////////
                           INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Verifies a proof that a given key/value pair is present in the
     * Merkle trie.
     * @param _key Key of the node to search for, as a hex string.
     * @param _value Value of the node to search for, as a hex string.
     * @param _proof Merkle trie inclusion proof for the desired node. Unlike
     * traditional Merkle trees, this proof is executed top-down and consists
     * of a list of RLP-encoded nodes that make a path down to the target node.
     * @param _root Known root of the Merkle trie. Used to verify that the
     * included proof is correctly constructed.
     * @return _verified `true` if the k/v pair exists in the trie, `false` otherwise.
     */
    function verifyInclusionProof(
        bytes memory _key,
        bytes memory _value,
        bytes memory _proof,
        bytes32 _root
    ) internal pure returns (bool _verified) {
        (bool exists, bytes memory value) = get(_key, _proof, _root);

        return (exists && LibBytesUtils.equal(_value, value));
    }

    /**
     * @notice Retrieves the value associated with a given key.
     * @param _key Key to search for, as hex bytes.
     * @param _proof Merkle trie inclusion proof for the key.
     * @param _root Known root of the Merkle trie.
     * @return _exists Whether or not the key exists.
     * @return _value Value of the key if it exists.
     */
    function get(bytes memory _key, bytes memory _proof, bytes32 _root)
        internal
        pure
        returns (bool _exists, bytes memory _value)
    {
        TrieNode[] memory proof = _parseProof(_proof);
        (uint256 pathLength, bytes memory keyRemainder, bool isFinalNode) =
            _walkNodePath(proof, _key, _root);

        bool exists = keyRemainder.length == 0;

        require(exists || isFinalNode, "Provided proof is invalid.");

        bytes memory value = exists ? _getNodeValue(proof[pathLength - 1]) : bytes("");

        return (exists, value);
    }

    /*//////////////////////////////////////////////////////////////
                           PRIVATE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Walks through a proof using a provided key.
     * @param _proof Inclusion proof to walk through.
     * @param _key Key to use for the walk.
     * @param _root Known root of the trie.
     * @return _pathLength Length of the final path
     * @return _keyRemainder Portion of the key remaining after the walk.
     * @return _isFinalNode Whether or not we've hit a dead end.
     */
    function _walkNodePath(TrieNode[] memory _proof, bytes memory _key, bytes32 _root)
        private
        pure
        returns (uint256 _pathLength, bytes memory _keyRemainder, bool _isFinalNode)
    {
        uint256 pathLength;
        bytes memory key = LibBytesUtils.toNibbles(_key);

        bytes32 currentNodeID = _root;
        uint256 currentKeyIndex = 0;
        uint256 currentKeyIncrement = 0;
        TrieNode memory currentNode;

        // Proof is top-down, so we start at the first element (root).
        for (uint256 i; i < _proof.length; ++i) {
            currentNode = _proof[i];
            currentKeyIndex += currentKeyIncrement;

            // Keep track of the proof elements we actually need.
            // It's expensive to resize arrays, so this simply reduces gas costs.
            pathLength += 1;

            if (currentKeyIndex == 0) {
                // First proof element is always the root node.
                require(keccak256(currentNode.encoded) == currentNodeID, "Invalid root hash");
            } else if (currentNode.encoded.length >= 32) {
                // Nodes 32 bytes or larger are hashed inside branch nodes.
                require(
                    keccak256(currentNode.encoded) == currentNodeID, "Invalid large internal hash"
                );
            } else {
                // Nodes smaller than 31 bytes aren't hashed.
                require(
                    LibBytesUtils.toBytes32(currentNode.encoded) == currentNodeID,
                    "Invalid internal node hash"
                );
            }

            if (currentNode.decoded.length == BRANCH_NODE_LENGTH) {
                if (currentKeyIndex == key.length) {
                    // We've hit the end of the key
                    // meaning the value should be within this branch node.
                    break;
                } else {
                    // We're not at the end of the key yet.
                    // Figure out what the next node ID should be and continue.
                    uint8 branchKey = uint8(key[currentKeyIndex]);
                    LibRLPReader.RLPItem memory nextNode = currentNode.decoded[branchKey];
                    currentNodeID = _getNodeID(nextNode);
                    currentKeyIncrement = 1;
                    continue;
                }
            } else if (currentNode.decoded.length == LEAF_OR_EXTENSION_NODE_LENGTH) {
                bytes memory path = _getNodePath(currentNode);
                uint8 prefix = uint8(path[0]);
                uint8 offset = 2 - (prefix % 2);
                bytes memory pathRemainder = LibBytesUtils.slice(path, offset);
                bytes memory keyRemainder = LibBytesUtils.slice(key, currentKeyIndex);
                uint256 sharedNibbleLength = _getSharedNibbleLength(pathRemainder, keyRemainder);

                if (prefix == PREFIX_LEAF_EVEN || prefix == PREFIX_LEAF_ODD) {
                    if (
                        pathRemainder.length == sharedNibbleLength
                            && keyRemainder.length == sharedNibbleLength
                    ) {
                        // The key within this leaf matches our key exactly.
                        // Increment the key index to reflect that we have no remainder.
                        currentKeyIndex += sharedNibbleLength;
                    }

                    // We've hit a leaf node, so our next node should be NULL.
                    currentNodeID = bytes32(RLP_NULL);
                    break;
                } else if (prefix == PREFIX_EXTENSION_EVEN || prefix == PREFIX_EXTENSION_ODD) {
                    if (sharedNibbleLength != pathRemainder.length) {
                        // Our extension node is not identical to the remainder.
                        // We've hit the end of this path
                        // updates will need to modify this extension.
                        currentNodeID = bytes32(RLP_NULL);
                        break;
                    } else {
                        // Our extension shares some nibbles.
                        // Carry on to the next node.
                        currentNodeID = _getNodeID(currentNode.decoded[1]);
                        currentKeyIncrement = sharedNibbleLength;
                        continue;
                    }
                } else {
                    revert("Received a node with an unknown prefix");
                }
            } else {
                revert("Received an unparseable node.");
            }
        }

        // If our node ID is NULL, then we're at a dead end.
        bool isFinalNode = currentNodeID == bytes32(RLP_NULL);
        return (pathLength, LibBytesUtils.slice(key, currentKeyIndex), isFinalNode);
    }

    /**
     * @notice Parses an RLP-encoded proof into something more useful.
     * @param _proof RLP-encoded proof to parse.
     * @return _parsed Proof parsed into easily accessible structs.
     */
    function _parseProof(bytes memory _proof) private pure returns (TrieNode[] memory _parsed) {
        LibRLPReader.RLPItem[] memory nodes = LibRLPReader.readList(_proof);
        TrieNode[] memory proof = new TrieNode[](nodes.length);

        for (uint256 i; i < nodes.length; ++i) {
            bytes memory encoded = LibRLPReader.readBytes(nodes[i]);
            proof[i] = TrieNode({encoded: encoded, decoded: LibRLPReader.readList(encoded)});
        }

        return proof;
    }

    /**
     * @notice Picks out the ID for a node. Node ID is referred to as the
     * "hash" within the specification, but nodes < 32 bytes are not actually
     * hashed.
     * @param _node Node to pull an ID for.
     * @return _nodeID ID for the node, depending on the size of its contents.
     */
    function _getNodeID(LibRLPReader.RLPItem memory _node) private pure returns (bytes32 _nodeID) {
        bytes memory nodeID;

        if (_node.length < 32) {
            // Nodes smaller than 32 bytes are RLP encoded.
            nodeID = LibRLPReader.readRawBytes(_node);
        } else {
            // Nodes 32 bytes or larger are hashed.
            nodeID = LibRLPReader.readBytes(_node);
        }

        return LibBytesUtils.toBytes32(nodeID);
    }

    /**
     * @notice Gets the path for a leaf or extension node.
     * @param _node Node to get a path for.
     * @return _path Node path, converted to an array of nibbles.
     */
    function _getNodePath(TrieNode memory _node) private pure returns (bytes memory _path) {
        return LibBytesUtils.toNibbles(LibRLPReader.readBytes(_node.decoded[0]));
    }

    /**
     * @notice Gets the path for a node.
     * @param _node Node to get a value for.
     * @return _value Node value, as hex bytes.
     */
    function _getNodeValue(TrieNode memory _node) private pure returns (bytes memory _value) {
        return LibRLPReader.readBytes(_node.decoded[_node.decoded.length - 1]);
    }

    /**
     * @notice Utility; determines the number of nibbles shared between two
     * nibble arrays.
     * @param _a First nibble array.
     * @param _b Second nibble array.
     * @return _shared Number of shared nibbles.
     */
    /**
     * @notice Utility; determines the number of nibbles shared between two
     * nibble arrays.
     * @param _a First nibble array.
     * @param _b Second nibble array.
     * @return _shared Number of shared nibbles.
     */
    function _getSharedNibbleLength(bytes memory _a, bytes memory _b)
        private
        pure
        returns (uint256 _shared)
    {
        uint256 i;
        while (_a.length > i && _b.length > i && _a[i] == _b[i]) {
            ++i;
        }
        return i;
    }
}

// SPDX-License-Identifier: MIT
// Taken from https://github.com/ethereum-optimism/optimism/blob/develop/packages/contracts/contracts/libraries/rlp/LibRLPReader.sol
// (The MIT License)
//
// Copyright 2020-2021 Optimism
// Copyright 2022-2023 Taiko Labs
//
// Permission is hereby granted, free of charge, to any person obtaining
// a copy of this software and associated documentation files (the
// "Software"), to deal in the Software without restriction, including
// without limitation the rights to use, copy, modify, merge, publish,
// distribute, sublicense, and/or sell copies of the Software, and to
// permit persons to whom the Software is furnished to do so, subject to
// the following conditions:
//
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
// IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
// CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
// TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
// SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

pragma solidity ^0.8.18;

/**
 * @title LibRLPReader
 * @dev Adapted from "RLPReader" by Hamdi Allam ([email protected]).
 */
library LibRLPReader {
    /*//////////////////////////////////////////////////////////////
                               CONSTANTS
    //////////////////////////////////////////////////////////////*/

    uint256 internal constant MAX_LIST_LENGTH = 32;

    /*//////////////////////////////////////////////////////////////
                                 ENUMS
    //////////////////////////////////////////////////////////////*/

    enum RLPItemType {
        DATA_ITEM,
        LIST_ITEM
    }

    /*//////////////////////////////////////////////////////////////
                                STRUCTS
    //////////////////////////////////////////////////////////////*/

    struct RLPItem {
        uint256 length;
        uint256 ptr;
    }

    /*//////////////////////////////////////////////////////////////
                           INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * Converts bytes to a reference to memory position and length.
     * @param _in Input bytes to convert.
     * @return Output memory reference.
     */
    function toRLPItem(bytes memory _in) internal pure returns (RLPItem memory) {
        uint256 ptr;
        assembly {
            ptr := add(_in, 32)
        }

        return RLPItem({length: _in.length, ptr: ptr});
    }

    /**
     * Reads an RLP list value into a list of RLP items.
     * @param _in RLP list value.
     * @return Decoded RLP list items.
     */
    function readList(RLPItem memory _in) internal pure returns (RLPItem[] memory) {
        (uint256 listOffset,, RLPItemType itemType) = _decodeLength(_in);

        require(itemType == RLPItemType.LIST_ITEM, "Invalid RLP list value.");

        // Solidity in-memory arrays can't be increased in size, but *can* be decreased in size by
        // writing to the length. Since we can't know the number of RLP items without looping over
        // the entire input, we'd have to loop twice to accurately size this array. It's easier to
        // simply set a reasonable maximum list length and decrease the size before we finish.
        RLPItem[] memory out = new RLPItem[](MAX_LIST_LENGTH);

        uint256 itemCount;
        uint256 offset = listOffset;
        while (offset < _in.length) {
            require(itemCount < MAX_LIST_LENGTH, "Provided RLP list exceeds max list length.");

            (uint256 itemOffset, uint256 itemLength,) =
                _decodeLength(RLPItem({length: _in.length - offset, ptr: _in.ptr + offset}));

            out[itemCount] = RLPItem({length: itemLength + itemOffset, ptr: _in.ptr + offset});

            itemCount += 1;
            offset += itemOffset + itemLength;
        }

        // Decrease the array size to match the actual item count.
        assembly {
            mstore(out, itemCount)
        }

        return out;
    }

    /**
     * Reads an RLP list value into a list of RLP items.
     * @param _in RLP list value.
     * @return Decoded RLP list items.
     */
    function readList(bytes memory _in) internal pure returns (RLPItem[] memory) {
        return readList(toRLPItem(_in));
    }

    /**
     * Reads an RLP bytes value into bytes.
     * @param _in RLP bytes value.
     * @return Decoded bytes.
     */
    function readBytes(RLPItem memory _in) internal pure returns (bytes memory) {
        (uint256 itemOffset, uint256 itemLength, RLPItemType itemType) = _decodeLength(_in);

        require(itemType == RLPItemType.DATA_ITEM, "Invalid RLP bytes value.");

        return _copy(_in.ptr, itemOffset, itemLength);
    }

    /**
     * Reads an RLP bytes value into bytes.
     * @param _in RLP bytes value.
     * @return Decoded bytes.
     */
    function readBytes(bytes memory _in) internal pure returns (bytes memory) {
        return readBytes(toRLPItem(_in));
    }

    /**
     * Reads an RLP string value into a string.
     * @param _in RLP string value.
     * @return Decoded string.
     */
    function readString(RLPItem memory _in) internal pure returns (string memory) {
        return string(readBytes(_in));
    }

    /**
     * Reads an RLP string value into a string.
     * @param _in RLP string value.
     * @return Decoded string.
     */
    function readString(bytes memory _in) internal pure returns (string memory) {
        return readString(toRLPItem(_in));
    }

    /**
     * Reads an RLP bytes32 value into a bytes32.
     * @param _in RLP bytes32 value.
     * @return Decoded bytes32.
     */
    function readBytes32(RLPItem memory _in) internal pure returns (bytes32) {
        require(_in.length <= 33, "Invalid RLP bytes32 value.");

        (uint256 itemOffset, uint256 itemLength, RLPItemType itemType) = _decodeLength(_in);

        require(itemType == RLPItemType.DATA_ITEM, "Invalid RLP bytes32 value.");

        uint256 ptr = _in.ptr + itemOffset;
        bytes32 out;
        assembly {
            out := mload(ptr)

            // Shift the bytes over to match the item size.
            if lt(itemLength, 32) { out := div(out, exp(256, sub(32, itemLength))) }
        }

        return out;
    }

    /**
     * Reads an RLP bytes32 value into a bytes32.
     * @param _in RLP bytes32 value.
     * @return Decoded bytes32.
     */
    function readBytes32(bytes memory _in) internal pure returns (bytes32) {
        return readBytes32(toRLPItem(_in));
    }

    /**
     * Reads an RLP uint256 value into a uint256.
     * @param _in RLP uint256 value.
     * @return Decoded uint256.
     */
    function readUint256(RLPItem memory _in) internal pure returns (uint256) {
        return uint256(readBytes32(_in));
    }

    /**
     * Reads an RLP uint256 value into a uint256.
     * @param _in RLP uint256 value.
     * @return Decoded uint256.
     */
    function readUint256(bytes memory _in) internal pure returns (uint256) {
        return readUint256(toRLPItem(_in));
    }

    /**
     * Reads an RLP bool value into a bool.
     * @param _in RLP bool value.
     * @return Decoded bool.
     */
    function readBool(RLPItem memory _in) internal pure returns (bool) {
        require(_in.length == 1, "Invalid RLP boolean value.");

        uint256 ptr = _in.ptr;
        uint256 out;
        assembly {
            out := byte(0, mload(ptr))
        }

        require(out == 0 || out == 1, "LibRLPReader: Invalid RLP boolean value, must be 0 or 1");

        return out != 0;
    }

    /**
     * Reads an RLP bool value into a bool.
     * @param _in RLP bool value.
     * @return Decoded bool.
     */
    function readBool(bytes memory _in) internal pure returns (bool) {
        return readBool(toRLPItem(_in));
    }

    /**
     * Reads an RLP address value into a address.
     * @param _in RLP address value.
     * @return Decoded address.
     */
    function readAddress(RLPItem memory _in) internal pure returns (address) {
        if (_in.length == 1) {
            return address(0);
        }

        require(_in.length == 21, "Invalid RLP address value.");

        return address(uint160(readUint256(_in)));
    }

    /**
     * Reads an RLP address value into a address.
     * @param _in RLP address value.
     * @return Decoded address.
     */
    function readAddress(bytes memory _in) internal pure returns (address) {
        return readAddress(toRLPItem(_in));
    }

    /**
     * Reads the raw bytes of an RLP item.
     * @param _in RLP item to read.
     * @return Raw RLP bytes.
     */
    function readRawBytes(RLPItem memory _in) internal pure returns (bytes memory) {
        return _copy(_in);
    }

    /*//////////////////////////////////////////////////////////////
                           PRIVATE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * Decodes the length of an RLP item.
     * @param _in RLP item to decode.
     * @return Offset of the encoded data.
     * @return Length of the encoded data.
     * @return RLP item type (LIST_ITEM or DATA_ITEM).
     */
    function _decodeLength(RLPItem memory _in)
        private
        pure
        returns (uint256, uint256, RLPItemType)
    {
        require(_in.length > 0, "RLP item cannot be null.");

        uint256 ptr = _in.ptr;
        uint256 prefix;
        assembly {
            prefix := byte(0, mload(ptr))
        }

        if (prefix <= 0x7f) {
            // Single byte.

            return (0, 1, RLPItemType.DATA_ITEM);
        } else if (prefix <= 0xb7) {
            // Short string.

            // slither-disable-next-line variable-scope
            uint256 strLen = prefix - 0x80;

            require(_in.length > strLen, "Invalid RLP short string.");

            return (1, strLen, RLPItemType.DATA_ITEM);
        } else if (prefix <= 0xbf) {
            // Long string.
            uint256 lenOfStrLen = prefix - 0xb7;

            require(_in.length > lenOfStrLen, "Invalid RLP long string length.");

            uint256 strLen;
            assembly {
                // Pick out the string length.
                strLen := div(mload(add(ptr, 1)), exp(256, sub(32, lenOfStrLen)))
            }

            require(_in.length > lenOfStrLen + strLen, "Invalid RLP long string.");

            return (1 + lenOfStrLen, strLen, RLPItemType.DATA_ITEM);
        } else if (prefix <= 0xf7) {
            // Short list.
            // slither-disable-next-line variable-scope
            uint256 listLen = prefix - 0xc0;

            require(_in.length > listLen, "Invalid RLP short list.");

            return (1, listLen, RLPItemType.LIST_ITEM);
        } else {
            // Long list.
            uint256 lenOfListLen = prefix - 0xf7;

            require(_in.length > lenOfListLen, "Invalid RLP long list length.");

            uint256 listLen;
            assembly {
                // Pick out the list length.
                listLen := div(mload(add(ptr, 1)), exp(256, sub(32, lenOfListLen)))
            }

            require(_in.length > lenOfListLen + listLen, "Invalid RLP long list.");

            return (1 + lenOfListLen, listLen, RLPItemType.LIST_ITEM);
        }
    }

    /**
     * Copies the bytes from a memory location.
     * @param _src Pointer to the location to read from.
     * @param _offset Offset to start reading from.
     * @param _length Number of bytes to read.
     * @return Copied bytes.
     */
    function _copy(uint256 _src, uint256 _offset, uint256 _length)
        internal
        pure
        returns (bytes memory)
    {
        bytes memory result = new bytes(_length);
        if (result.length == 0) {
            return result;
        }

        bytes memory src;
        bytes memory dst;
        assembly {
            src := add(_src, _offset)

            dst := add(result, 32)

            for { let i := 0 } lt(i, _length) { i := add(i, 32) } {
                mstore(add(dst, i), mload(add(src, i)))
            }
        }

        // Pick out the remaining bytes.
        uint256 mask;
        unchecked {
            mask = 256 ** (32 - (_length % 32)) - 1;
        }

        assembly {
            mstore(dst, or(and(mload(src), not(mask)), and(mload(dst), mask)))
        }

        return result;
    }

    /**
     * Copies an RLP item into bytes.
     * @param _in RLP item to copy.
     * @return Copied bytes.
     */
    function _copy(RLPItem memory _in) private pure returns (bytes memory) {
        return _copy(_in.ptr, 0, _in.length);
    }
}

// SPDX-License-Identifier: MIT
// Taken from https://github.com/ethereum-optimism/optimism/blob/develop/packages/contracts/contracts/libraries/rlp/LibRLPWriter.sol
// Modified to support writeBytes32/writeUint64
// (The MIT License)
//
// Copyright 2020-2021 Optimism
// Copyright 2022-2023 Taiko Labs
//
// Permission is hereby granted, free of charge, to any person obtaining
// a copy of this software and associated documentation files (the
// "Software"), to deal in the Software without restriction, including
// without limitation the rights to use, copy, modify, merge, publish,
// distribute, sublicense, and/or sell copies of the Software, and to
// permit persons to whom the Software is furnished to do so, subject to
// the following conditions:
//
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
// IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
// CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
// TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
// SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

pragma solidity ^0.8.18;

/**
 * @title LibRLPWriter
 * @author Bakaoh (with modifications)
 */
library LibRLPWriter {
    /*//////////////////////////////////////////////////////////////
                           INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * RLP encodes a byte string.
     * @param _in The byte string to encode.
     * @return The RLP encoded string in bytes.
     */
    function writeBytes(bytes memory _in) internal pure returns (bytes memory) {
        bytes memory encoded;

        if (_in.length == 1 && uint8(_in[0]) < 128) {
            encoded = _in;
        } else {
            encoded = abi.encodePacked(_writeLength(_in.length, 128), _in);
        }

        return encoded;
    }

    /**
     * RLP encodes a list of RLP encoded byte byte strings.
     * @param _in The list of RLP encoded byte strings.
     * @return The RLP encoded list of items in bytes.
     */
    function writeList(bytes[] memory _in) internal pure returns (bytes memory) {
        bytes memory list = _flatten(_in);
        return abi.encodePacked(_writeLength(list.length, 192), list);
    }

    /**
     * RLP encodes a string.
     * @param _in The string to encode.
     * @return The RLP encoded string in bytes.
     */
    function writeString(string memory _in) internal pure returns (bytes memory) {
        return writeBytes(bytes(_in));
    }

    /**
     * RLP encodes an address.
     * @param _in The address to encode.
     * @return The RLP encoded address in bytes.
     */
    function writeAddress(address _in) internal pure returns (bytes memory) {
        return writeBytes(abi.encodePacked(_in));
    }

    /**
     * RLP encodes a uint.
     * @param _in The uint256 to encode.
     * @return The RLP encoded uint256 in bytes.
     */
    function writeUint(uint256 _in) internal pure returns (bytes memory) {
        return writeBytes(_toBinary(_in));
    }

    function writeBytes32(bytes32 _in) internal pure returns (bytes memory) {
        return writeBytes(_toBinary(uint256(_in)));
    }

    /**
     * RLP encodes a hash, we should use this function but not writeBytes32 to
     * encode a hash, since writeBytes32 will remove the leading zeros of the
     * given bytes.
     * @param _in The hash to encode.
     * @return The RLP encoded hash in bytes.
     */
    function writeHash(bytes32 _in) internal pure returns (bytes memory) {
        return writeBytes(_toBinaryWithLeadingZeros(uint256(_in)));
    }

    function writeUint64(uint64 _in) internal pure returns (bytes memory) {
        return writeBytes(_toBinary(_in));
    }

    /**
     * RLP encodes a bool.
     * @param _in The bool to encode.
     * @return The RLP encoded bool in bytes.
     */
    function writeBool(bool _in) internal pure returns (bytes memory) {
        bytes memory encoded = new bytes(1);
        encoded[0] = (_in ? bytes1(0x01) : bytes1(0x80));
        return encoded;
    }

    /*//////////////////////////////////////////////////////////////
                           PRIVATE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * Encode the first byte, followed by the `len` in binary form if `length` is more than 55.
     * @param _len The length of the string or the payload.
     * @param _offset 128 if item is string, 192 if item is list.
     * @return RLP encoded bytes.
     */
    function _writeLength(uint256 _len, uint256 _offset) private pure returns (bytes memory) {
        bytes memory encoded;

        if (_len < 56) {
            encoded = new bytes(1);
            encoded[0] = bytes1(uint8(_len) + uint8(_offset));
        } else {
            uint256 lenLen;
            uint256 i = 1;
            while (_len / i != 0) {
                ++lenLen;
                i *= 256;
            }

            encoded = new bytes(lenLen + 1);
            encoded[0] = bytes1(uint8(lenLen) + uint8(_offset) + 55);
            for (i = 1; i <= lenLen; ++i) {
                encoded[i] = bytes1(uint8((_len / (256 ** (lenLen - i))) % 256));
            }
        }

        return encoded;
    }

    /**
     * Encode integer in big endian binary form with no leading zeroes.
     * @notice TODO: This should be optimized with assembly to save gas costs.
     * @param _x The integer to encode.
     * @return RLP encoded bytes.
     */
    function _toBinary(uint256 _x) private pure returns (bytes memory) {
        bytes memory b = abi.encodePacked(_x);

        uint256 i;
        for (; i < 32; ++i) {
            if (b[i] != 0) {
                break;
            }
        }

        bytes memory res = new bytes(32 - i);
        for (uint256 j; j < res.length; ++j) {
            res[j] = b[i++];
        }

        return res;
    }

    /**
     * Encode integer in big endian binary form with leading zeroes.
     * @notice TODO: This should be optimized with assembly to save gas costs.
     * @param _x The integer to encode.
     * @return RLP encoded bytes.
     */
    function _toBinaryWithLeadingZeros(uint256 _x) private pure returns (bytes memory) {
        bytes memory b = abi.encodePacked(_x);

        uint256 i;

        bytes memory res = new bytes(32);
        for (uint256 j; j < res.length; ++j) {
            res[j] = b[i++];
        }

        return res;
    }

    /**
     * Copies a piece of memory to another location.
     * @notice From: https://github.com/Arachnid/solidity-stringutils/blob/master/src/strings.sol.
     * @param _dest Destination location.
     * @param _src Source location.
     * @param _len Length of memory to copy.
     */
    function _memcpy(uint256 _dest, uint256 _src, uint256 _len) private pure {
        uint256 dest = _dest;
        uint256 src = _src;
        uint256 len = _len;

        for (; len >= 32; len -= 32) {
            assembly {
                mstore(dest, mload(src))
            }
            dest += 32;
            src += 32;
        }

        uint256 mask;
        unchecked {
            mask = 256 ** (32 - len) - 1;
        }
        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }
    }

    /**
     * Flattens a list of byte strings into one byte string.
     * @notice From: https://github.com/sammayo/solidity-rlp-encoder/blob/master/RLPEncode.sol.
     * @param _list List of byte strings to flatten.
     * @return The flattened byte string.
     */
    function _flatten(bytes[] memory _list) private pure returns (bytes memory) {
        if (_list.length == 0) {
            return new bytes(0);
        }

        uint256 len;
        uint256 i;
        for (; i < _list.length; ++i) {
            len += _list[i].length;
        }

        bytes memory flattened = new bytes(len);
        uint256 flattenedPtr;
        assembly {
            flattenedPtr := add(flattened, 0x20)
        }

        for (i = 0; i < _list.length; ++i) {
            bytes memory item = _list[i];

            uint256 listPtr;
            assembly {
                listPtr := add(item, 0x20)
            }

            _memcpy(flattenedPtr, listPtr, item.length);
            flattenedPtr += _list[i].length;
        }

        return flattened;
    }
}

// SPDX-License-Identifier: MIT
// Taken from https://github.com/ethereum-optimism/optimism/blob/develop/packages/contracts/contracts/libraries/trie/LibSecureMerkleTrie.sol
// (The MIT License)
//
// Copyright 2020-2021 Optimism
// Copyright 2022-2023 Taiko Labs
//
// Permission is hereby granted, free of charge, to any person obtaining
// a copy of this software and associated documentation files (the
// "Software"), to deal in the Software without restriction, including
// without limitation the rights to use, copy, modify, merge, publish,
// distribute, sublicense, and/or sell copies of the Software, and to
// permit persons to whom the Software is furnished to do so, subject to
// the following conditions:
//
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
// IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
// CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
// TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
// SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

pragma solidity ^0.8.18;

/* Library Imports */
import {LibMerkleTrie} from "./LibMerkleTrie.sol";

/**
 * @title LibSecureMerkleTrie
 */
library LibSecureMerkleTrie {
    /*//////////////////////////////////////////////////////////////
                           INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Verifies a proof that a given key/value pair is present in the
     * Merkle trie.
     * @param _key Key of the node to search for, as a hex string.
     * @param _value Value of the node to search for, as a hex string.
     * @param _proof Merkle trie inclusion proof for the desired node. Unlike
     * traditional Merkle trees, this proof is executed top-down and consists
     * of a list of RLP-encoded nodes that make a path down to the target node.
     * @param _root Known root of the Merkle trie. Used to verify that the
     * included proof is correctly constructed.
     * @return _verified `true` if the k/v pair exists in the trie, `false` otherwise.
     */
    function verifyInclusionProof(
        bytes memory _key,
        bytes memory _value,
        bytes memory _proof,
        bytes32 _root
    ) internal pure returns (bool _verified) {
        bytes memory key = _getSecureKey(_key);
        return LibMerkleTrie.verifyInclusionProof(key, _value, _proof, _root);
    }

    /**
     * @notice Retrieves the value associated with a given key.
     * @param _key Key to search for, as hex bytes.
     * @param _proof Merkle trie inclusion proof for the key.
     * @param _root Known root of the Merkle trie.
     * @return _exists Whether or not the key exists.
     * @return _value Value of the key if it exists.
     */
    function get(bytes memory _key, bytes memory _proof, bytes32 _root)
        internal
        pure
        returns (bool _exists, bytes memory _value)
    {
        bytes memory key = _getSecureKey(_key);
        return LibMerkleTrie.get(key, _proof, _root);
    }

    /*//////////////////////////////////////////////////////////////
                           PRIVATE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * Computes the secure counterpart to a key.
     * @param _key Key to get a secure key from.
     * @return _secureKey Secure version of the key.
     */
    function _getSecureKey(bytes memory _key) private pure returns (bytes memory _secureKey) {
        return bytes.concat(keccak256(_key));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/transparent/TransparentUpgradeableProxy.sol)

pragma solidity ^0.8.0;

import "lib/openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol";

/**
 * @dev This contract implements a proxy that is upgradeable by an admin.
 *
 * To avoid https://medium.com/nomic-labs-blog/malicious-backdoors-in-ethereum-proxies-62629adf3357[proxy selector
 * clashing], which can potentially be used in an attack, this contract uses the
 * https://blog.openzeppelin.com/the-transparent-proxy-pattern/[transparent proxy pattern]. This pattern implies two
 * things that go hand in hand:
 *
 * 1. If any account other than the admin calls the proxy, the call will be forwarded to the implementation, even if
 * that call matches one of the admin functions exposed by the proxy itself.
 * 2. If the admin calls the proxy, it can access the admin functions, but its calls will never be forwarded to the
 * implementation. If the admin tries to call a function on the implementation it will fail with an error that says
 * "admin cannot fallback to proxy target".
 *
 * These properties mean that the admin account can only be used for admin actions like upgrading the proxy or changing
 * the admin, so it's best if it's a dedicated account that is not used for anything else. This will avoid headaches due
 * to sudden errors when trying to call a function from the proxy implementation.
 *
 * Our recommendation is for the dedicated account to be an instance of the {ProxyAdmin} contract. If set up this way,
 * you should think of the `ProxyAdmin` instance as the real administrative interface of your proxy.
 */
contract TransparentUpgradeableProxy is ERC1967Proxy {
    /**
     * @dev Initializes an upgradeable proxy managed by `_admin`, backed by the implementation at `_logic`, and
     * optionally initialized with `_data` as explained in {ERC1967Proxy-constructor}.
     */
    constructor(address _logic, address admin_, bytes memory _data)
        payable
        ERC1967Proxy(_logic, _data)
    {
        _changeAdmin(admin_);
    }

    /**
     * @dev Modifier used internally that will delegate the call to the implementation unless the sender is the admin.
     */
    modifier ifAdmin() {
        if (msg.sender == _getAdmin()) {
            _;
        } else {
            _fallback();
        }
    }

    /**
     * @dev Returns the current admin.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-getProxyAdmin}.
     *
     * TIP: To get this value clients can read directly from the storage slot shown below (specified by EIP1967) using the
     * https://eth.wiki/json-rpc/API#eth_getstorageat[`eth_getStorageAt`] RPC call.
     * `0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103`
     */
    function admin() external ifAdmin returns (address admin_) {
        admin_ = _getAdmin();
    }

    /**
     * @dev Returns the current implementation.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-getProxyImplementation}.
     *
     * TIP: To get this value clients can read directly from the storage slot shown below (specified by EIP1967) using the
     * https://eth.wiki/json-rpc/API#eth_getstorageat[`eth_getStorageAt`] RPC call.
     * `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
     */
    function implementation() external ifAdmin returns (address implementation_) {
        implementation_ = _implementation();
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-changeProxyAdmin}.
     */
    function changeAdmin(address newAdmin) external virtual ifAdmin {
        _changeAdmin(newAdmin);
    }

    /**
     * @dev Upgrade the implementation of the proxy.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-upgrade}.
     */
    function upgradeTo(address newImplementation) external ifAdmin {
        _upgradeToAndCall(newImplementation, bytes(""), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy, and then call a function from the new implementation as specified
     * by `data`, which should be an encoded function call. This is useful to initialize new storage variables in the
     * proxied contract.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-upgradeAndCall}.
     */
    function upgradeToAndCall(address newImplementation, bytes calldata data)
        external
        payable
        ifAdmin
    {
        _upgradeToAndCall(newImplementation, data, true);
    }

    /**
     * @dev Returns the current admin.
     */
    function _admin() internal view virtual returns (address) {
        return _getAdmin();
    }

    /**
     * @dev Makes sure the admin cannot access the fallback function. See {Proxy-_beforeFallback}.
     */
    function _beforeFallback() internal virtual override {
        require(
            msg.sender != _getAdmin(),
            "TransparentUpgradeableProxy: admin cannot fallback to proxy target"
        );
        super._beforeFallback();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal onlyInitializing {
    }

    function __AccessControl_init_unchained() internal onlyInitializing {
    }
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(account),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
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
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
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
// OpenZeppelin Contracts (last updated v4.8.0) (governance/extensions/GovernorCountingSimple.sol)

pragma solidity ^0.8.0;

import "../GovernorUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Extension of {Governor} for simple, 3 options, vote counting.
 *
 * _Available since v4.3._
 */
abstract contract GovernorCountingSimpleUpgradeable is Initializable, GovernorUpgradeable {
    function __GovernorCountingSimple_init() internal onlyInitializing {
    }

    function __GovernorCountingSimple_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev Supported vote types. Matches Governor Bravo ordering.
     */
    enum VoteType {
        Against,
        For,
        Abstain
    }

    struct ProposalVote {
        uint256 againstVotes;
        uint256 forVotes;
        uint256 abstainVotes;
        mapping(address => bool) hasVoted;
    }

    mapping(uint256 => ProposalVote) private _proposalVotes;

    /**
     * @dev See {IGovernor-COUNTING_MODE}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function COUNTING_MODE() public pure virtual override returns (string memory) {
        return "support=bravo&quorum=for,abstain";
    }

    /**
     * @dev See {IGovernor-hasVoted}.
     */
    function hasVoted(uint256 proposalId, address account) public view virtual override returns (bool) {
        return _proposalVotes[proposalId].hasVoted[account];
    }

    /**
     * @dev Accessor to the internal vote counts.
     */
    function proposalVotes(uint256 proposalId)
        public
        view
        virtual
        returns (
            uint256 againstVotes,
            uint256 forVotes,
            uint256 abstainVotes
        )
    {
        ProposalVote storage proposalVote = _proposalVotes[proposalId];
        return (proposalVote.againstVotes, proposalVote.forVotes, proposalVote.abstainVotes);
    }

    /**
     * @dev See {Governor-_quorumReached}.
     */
    function _quorumReached(uint256 proposalId) internal view virtual override returns (bool) {
        ProposalVote storage proposalVote = _proposalVotes[proposalId];

        return quorum(proposalSnapshot(proposalId)) <= proposalVote.forVotes + proposalVote.abstainVotes;
    }

    /**
     * @dev See {Governor-_voteSucceeded}. In this module, the forVotes must be strictly over the againstVotes.
     */
    function _voteSucceeded(uint256 proposalId) internal view virtual override returns (bool) {
        ProposalVote storage proposalVote = _proposalVotes[proposalId];

        return proposalVote.forVotes > proposalVote.againstVotes;
    }

    /**
     * @dev See {Governor-_countVote}. In this module, the support follows the `VoteType` enum (from Governor Bravo).
     */
    function _countVote(
        uint256 proposalId,
        address account,
        uint8 support,
        uint256 weight,
        bytes memory // params
    ) internal virtual override {
        ProposalVote storage proposalVote = _proposalVotes[proposalId];

        require(!proposalVote.hasVoted[account], "GovernorVotingSimple: vote already cast");
        proposalVote.hasVoted[account] = true;

        if (support == uint8(VoteType.Against)) {
            proposalVote.againstVotes += weight;
        } else if (support == uint8(VoteType.For)) {
            proposalVote.forVotes += weight;
        } else if (support == uint8(VoteType.Abstain)) {
            proposalVote.abstainVotes += weight;
        } else {
            revert("GovernorVotingSimple: invalid value for enum VoteType");
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
// OpenZeppelin Contracts v4.4.1 (governance/extensions/GovernorSettings.sol)

pragma solidity ^0.8.0;

import "../GovernorUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Extension of {Governor} for settings updatable through governance.
 *
 * _Available since v4.4._
 */
abstract contract GovernorSettingsUpgradeable is Initializable, GovernorUpgradeable {
    uint256 private _votingDelay;
    uint256 private _votingPeriod;
    uint256 private _proposalThreshold;

    event VotingDelaySet(uint256 oldVotingDelay, uint256 newVotingDelay);
    event VotingPeriodSet(uint256 oldVotingPeriod, uint256 newVotingPeriod);
    event ProposalThresholdSet(uint256 oldProposalThreshold, uint256 newProposalThreshold);

    /**
     * @dev Initialize the governance parameters.
     */
    function __GovernorSettings_init(
        uint256 initialVotingDelay,
        uint256 initialVotingPeriod,
        uint256 initialProposalThreshold
    ) internal onlyInitializing {
        __GovernorSettings_init_unchained(initialVotingDelay, initialVotingPeriod, initialProposalThreshold);
    }

    function __GovernorSettings_init_unchained(
        uint256 initialVotingDelay,
        uint256 initialVotingPeriod,
        uint256 initialProposalThreshold
    ) internal onlyInitializing {
        _setVotingDelay(initialVotingDelay);
        _setVotingPeriod(initialVotingPeriod);
        _setProposalThreshold(initialProposalThreshold);
    }

    /**
     * @dev See {IGovernor-votingDelay}.
     */
    function votingDelay() public view virtual override returns (uint256) {
        return _votingDelay;
    }

    /**
     * @dev See {IGovernor-votingPeriod}.
     */
    function votingPeriod() public view virtual override returns (uint256) {
        return _votingPeriod;
    }

    /**
     * @dev See {Governor-proposalThreshold}.
     */
    function proposalThreshold() public view virtual override returns (uint256) {
        return _proposalThreshold;
    }

    /**
     * @dev Update the voting delay. This operation can only be performed through a governance proposal.
     *
     * Emits a {VotingDelaySet} event.
     */
    function setVotingDelay(uint256 newVotingDelay) public virtual onlyGovernance {
        _setVotingDelay(newVotingDelay);
    }

    /**
     * @dev Update the voting period. This operation can only be performed through a governance proposal.
     *
     * Emits a {VotingPeriodSet} event.
     */
    function setVotingPeriod(uint256 newVotingPeriod) public virtual onlyGovernance {
        _setVotingPeriod(newVotingPeriod);
    }

    /**
     * @dev Update the proposal threshold. This operation can only be performed through a governance proposal.
     *
     * Emits a {ProposalThresholdSet} event.
     */
    function setProposalThreshold(uint256 newProposalThreshold) public virtual onlyGovernance {
        _setProposalThreshold(newProposalThreshold);
    }

    /**
     * @dev Internal setter for the voting delay.
     *
     * Emits a {VotingDelaySet} event.
     */
    function _setVotingDelay(uint256 newVotingDelay) internal virtual {
        emit VotingDelaySet(_votingDelay, newVotingDelay);
        _votingDelay = newVotingDelay;
    }

    /**
     * @dev Internal setter for the voting period.
     *
     * Emits a {VotingPeriodSet} event.
     */
    function _setVotingPeriod(uint256 newVotingPeriod) internal virtual {
        // voting period must be at least one block long
        require(newVotingPeriod > 0, "GovernorSettings: voting period too low");
        emit VotingPeriodSet(_votingPeriod, newVotingPeriod);
        _votingPeriod = newVotingPeriod;
    }

    /**
     * @dev Internal setter for the proposal threshold.
     *
     * Emits a {ProposalThresholdSet} event.
     */
    function _setProposalThreshold(uint256 newProposalThreshold) internal virtual {
        emit ProposalThresholdSet(_proposalThreshold, newProposalThreshold);
        _proposalThreshold = newProposalThreshold;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[47] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (governance/extensions/GovernorTimelockControl.sol)

pragma solidity ^0.8.0;

import "./IGovernorTimelockUpgradeable.sol";
import "../GovernorUpgradeable.sol";
import "../TimelockControllerUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Extension of {Governor} that binds the execution process to an instance of {TimelockController}. This adds a
 * delay, enforced by the {TimelockController} to all successful proposal (in addition to the voting duration). The
 * {Governor} needs the proposer (and ideally the executor) roles for the {Governor} to work properly.
 *
 * Using this model means the proposal will be operated by the {TimelockController} and not by the {Governor}. Thus,
 * the assets and permissions must be attached to the {TimelockController}. Any asset sent to the {Governor} will be
 * inaccessible.
 *
 * WARNING: Setting up the TimelockController to have additional proposers besides the governor is very risky, as it
 * grants them powers that they must be trusted or known not to use: 1) {onlyGovernance} functions like {relay} are
 * available to them through the timelock, and 2) approved governance proposals can be blocked by them, effectively
 * executing a Denial of Service attack. This risk will be mitigated in a future release.
 *
 * _Available since v4.3._
 */
abstract contract GovernorTimelockControlUpgradeable is Initializable, IGovernorTimelockUpgradeable, GovernorUpgradeable {
    TimelockControllerUpgradeable private _timelock;
    mapping(uint256 => bytes32) private _timelockIds;

    /**
     * @dev Emitted when the timelock controller used for proposal execution is modified.
     */
    event TimelockChange(address oldTimelock, address newTimelock);

    /**
     * @dev Set the timelock.
     */
    function __GovernorTimelockControl_init(TimelockControllerUpgradeable timelockAddress) internal onlyInitializing {
        __GovernorTimelockControl_init_unchained(timelockAddress);
    }

    function __GovernorTimelockControl_init_unchained(TimelockControllerUpgradeable timelockAddress) internal onlyInitializing {
        _updateTimelock(timelockAddress);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165Upgradeable, GovernorUpgradeable) returns (bool) {
        return interfaceId == type(IGovernorTimelockUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Overridden version of the {Governor-state} function with added support for the `Queued` status.
     */
    function state(uint256 proposalId) public view virtual override(IGovernorUpgradeable, GovernorUpgradeable) returns (ProposalState) {
        ProposalState status = super.state(proposalId);

        if (status != ProposalState.Succeeded) {
            return status;
        }

        // core tracks execution, so we just have to check if successful proposal have been queued.
        bytes32 queueid = _timelockIds[proposalId];
        if (queueid == bytes32(0)) {
            return status;
        } else if (_timelock.isOperationDone(queueid)) {
            return ProposalState.Executed;
        } else if (_timelock.isOperationPending(queueid)) {
            return ProposalState.Queued;
        } else {
            return ProposalState.Canceled;
        }
    }

    /**
     * @dev Public accessor to check the address of the timelock
     */
    function timelock() public view virtual override returns (address) {
        return address(_timelock);
    }

    /**
     * @dev Public accessor to check the eta of a queued proposal
     */
    function proposalEta(uint256 proposalId) public view virtual override returns (uint256) {
        uint256 eta = _timelock.getTimestamp(_timelockIds[proposalId]);
        return eta == 1 ? 0 : eta; // _DONE_TIMESTAMP (1) should be replaced with a 0 value
    }

    /**
     * @dev Function to queue a proposal to the timelock.
     */
    function queue(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) public virtual override returns (uint256) {
        uint256 proposalId = hashProposal(targets, values, calldatas, descriptionHash);

        require(state(proposalId) == ProposalState.Succeeded, "Governor: proposal not successful");

        uint256 delay = _timelock.getMinDelay();
        _timelockIds[proposalId] = _timelock.hashOperationBatch(targets, values, calldatas, 0, descriptionHash);
        _timelock.scheduleBatch(targets, values, calldatas, 0, descriptionHash, delay);

        emit ProposalQueued(proposalId, block.timestamp + delay);

        return proposalId;
    }

    /**
     * @dev Overridden execute function that run the already queued proposal through the timelock.
     */
    function _execute(
        uint256, /* proposalId */
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) internal virtual override {
        _timelock.executeBatch{value: msg.value}(targets, values, calldatas, 0, descriptionHash);
    }

    /**
     * @dev Overridden version of the {Governor-_cancel} function to cancel the timelocked proposal if it as already
     * been queued.
     */
    // This function can reenter through the external call to the timelock, but we assume the timelock is trusted and
    // well behaved (according to TimelockController) and this will not happen.
    // slither-disable-next-line reentrancy-no-eth
    function _cancel(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) internal virtual override returns (uint256) {
        uint256 proposalId = super._cancel(targets, values, calldatas, descriptionHash);

        if (_timelockIds[proposalId] != 0) {
            _timelock.cancel(_timelockIds[proposalId]);
            delete _timelockIds[proposalId];
        }

        return proposalId;
    }

    /**
     * @dev Address through which the governor executes action. In this case, the timelock.
     */
    function _executor() internal view virtual override returns (address) {
        return address(_timelock);
    }

    /**
     * @dev Public endpoint to update the underlying timelock instance. Restricted to the timelock itself, so updates
     * must be proposed, scheduled, and executed through governance proposals.
     *
     * CAUTION: It is not recommended to change the timelock while there are other queued governance proposals.
     */
    function updateTimelock(TimelockControllerUpgradeable newTimelock) external virtual onlyGovernance {
        _updateTimelock(newTimelock);
    }

    function _updateTimelock(TimelockControllerUpgradeable newTimelock) private {
        emit TimelockChange(address(_timelock), address(newTimelock));
        _timelock = newTimelock;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[48] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (governance/extensions/GovernorVotesQuorumFraction.sol)

pragma solidity ^0.8.0;

import "./GovernorVotesUpgradeable.sol";
import "../../utils/CheckpointsUpgradeable.sol";
import "../../utils/math/SafeCastUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Extension of {Governor} for voting weight extraction from an {ERC20Votes} token and a quorum expressed as a
 * fraction of the total supply.
 *
 * _Available since v4.3._
 */
abstract contract GovernorVotesQuorumFractionUpgradeable is Initializable, GovernorVotesUpgradeable {
    using CheckpointsUpgradeable for CheckpointsUpgradeable.History;

    uint256 private _quorumNumerator; // DEPRECATED
    CheckpointsUpgradeable.History private _quorumNumeratorHistory;

    event QuorumNumeratorUpdated(uint256 oldQuorumNumerator, uint256 newQuorumNumerator);

    /**
     * @dev Initialize quorum as a fraction of the token's total supply.
     *
     * The fraction is specified as `numerator / denominator`. By default the denominator is 100, so quorum is
     * specified as a percent: a numerator of 10 corresponds to quorum being 10% of total supply. The denominator can be
     * customized by overriding {quorumDenominator}.
     */
    function __GovernorVotesQuorumFraction_init(uint256 quorumNumeratorValue) internal onlyInitializing {
        __GovernorVotesQuorumFraction_init_unchained(quorumNumeratorValue);
    }

    function __GovernorVotesQuorumFraction_init_unchained(uint256 quorumNumeratorValue) internal onlyInitializing {
        _updateQuorumNumerator(quorumNumeratorValue);
    }

    /**
     * @dev Returns the current quorum numerator. See {quorumDenominator}.
     */
    function quorumNumerator() public view virtual returns (uint256) {
        return _quorumNumeratorHistory._checkpoints.length == 0 ? _quorumNumerator : _quorumNumeratorHistory.latest();
    }

    /**
     * @dev Returns the quorum numerator at a specific block number. See {quorumDenominator}.
     */
    function quorumNumerator(uint256 blockNumber) public view virtual returns (uint256) {
        // If history is empty, fallback to old storage
        uint256 length = _quorumNumeratorHistory._checkpoints.length;
        if (length == 0) {
            return _quorumNumerator;
        }

        // Optimistic search, check the latest checkpoint
        CheckpointsUpgradeable.Checkpoint memory latest = _quorumNumeratorHistory._checkpoints[length - 1];
        if (latest._blockNumber <= blockNumber) {
            return latest._value;
        }

        // Otherwise, do the binary search
        return _quorumNumeratorHistory.getAtBlock(blockNumber);
    }

    /**
     * @dev Returns the quorum denominator. Defaults to 100, but may be overridden.
     */
    function quorumDenominator() public view virtual returns (uint256) {
        return 100;
    }

    /**
     * @dev Returns the quorum for a block number, in terms of number of votes: `supply * numerator / denominator`.
     */
    function quorum(uint256 blockNumber) public view virtual override returns (uint256) {
        return (token.getPastTotalSupply(blockNumber) * quorumNumerator(blockNumber)) / quorumDenominator();
    }

    /**
     * @dev Changes the quorum numerator.
     *
     * Emits a {QuorumNumeratorUpdated} event.
     *
     * Requirements:
     *
     * - Must be called through a governance proposal.
     * - New numerator must be smaller or equal to the denominator.
     */
    function updateQuorumNumerator(uint256 newQuorumNumerator) external virtual onlyGovernance {
        _updateQuorumNumerator(newQuorumNumerator);
    }

    /**
     * @dev Changes the quorum numerator.
     *
     * Emits a {QuorumNumeratorUpdated} event.
     *
     * Requirements:
     *
     * - New numerator must be smaller or equal to the denominator.
     */
    function _updateQuorumNumerator(uint256 newQuorumNumerator) internal virtual {
        require(
            newQuorumNumerator <= quorumDenominator(),
            "GovernorVotesQuorumFraction: quorumNumerator over quorumDenominator"
        );

        uint256 oldQuorumNumerator = quorumNumerator();

        // Make sure we keep track of the original numerator in contracts upgraded from a version without checkpoints.
        if (oldQuorumNumerator != 0 && _quorumNumeratorHistory._checkpoints.length == 0) {
            _quorumNumeratorHistory._checkpoints.push(
                CheckpointsUpgradeable.Checkpoint({_blockNumber: 0, _value: SafeCastUpgradeable.toUint224(oldQuorumNumerator)})
            );
        }

        // Set new quorum for future proposals
        _quorumNumeratorHistory.push(newQuorumNumerator);

        emit QuorumNumeratorUpdated(oldQuorumNumerator, newQuorumNumerator);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[48] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (governance/extensions/GovernorVotes.sol)

pragma solidity ^0.8.0;

import "../GovernorUpgradeable.sol";
import "../utils/IVotesUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Extension of {Governor} for voting weight extraction from an {ERC20Votes} token, or since v4.5 an {ERC721Votes} token.
 *
 * _Available since v4.3._
 *
 * @custom:storage-size 51
 */
abstract contract GovernorVotesUpgradeable is Initializable, GovernorUpgradeable {
    IVotesUpgradeable public token;

    function __GovernorVotes_init(IVotesUpgradeable tokenAddress) internal onlyInitializing {
        __GovernorVotes_init_unchained(tokenAddress);
    }

    function __GovernorVotes_init_unchained(IVotesUpgradeable tokenAddress) internal onlyInitializing {
        token = tokenAddress;
    }

    /**
     * Read the voting weight from the token's built in snapshot mechanism (see {Governor-_getVotes}).
     */
    function _getVotes(
        address account,
        uint256 blockNumber,
        bytes memory /*params*/
    ) internal view virtual override returns (uint256) {
        return token.getPastVotes(account, blockNumber);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (governance/extensions/IGovernorTimelock.sol)

pragma solidity ^0.8.0;

import "../IGovernorUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Extension of the {IGovernor} for timelock supporting modules.
 *
 * _Available since v4.3._
 */
abstract contract IGovernorTimelockUpgradeable is Initializable, IGovernorUpgradeable {
    function __IGovernorTimelock_init() internal onlyInitializing {
    }

    function __IGovernorTimelock_init_unchained() internal onlyInitializing {
    }
    event ProposalQueued(uint256 proposalId, uint256 eta);

    function timelock() public view virtual returns (address);

    function proposalEta(uint256 proposalId) public view virtual returns (uint256);

    function queue(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) public virtual returns (uint256 proposalId);

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (governance/Governor.sol)

pragma solidity ^0.8.0;

import "../token/ERC721/IERC721ReceiverUpgradeable.sol";
import "../token/ERC1155/IERC1155ReceiverUpgradeable.sol";
import "../utils/cryptography/ECDSAUpgradeable.sol";
import "../utils/cryptography/EIP712Upgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../utils/math/SafeCastUpgradeable.sol";
import "../utils/structs/DoubleEndedQueueUpgradeable.sol";
import "../utils/AddressUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/TimersUpgradeable.sol";
import "./IGovernorUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Core of the governance system, designed to be extended though various modules.
 *
 * This contract is abstract and requires several function to be implemented in various modules:
 *
 * - A counting module must implement {quorum}, {_quorumReached}, {_voteSucceeded} and {_countVote}
 * - A voting module must implement {_getVotes}
 * - Additionanly, the {votingPeriod} must also be implemented
 *
 * _Available since v4.3._
 */
abstract contract GovernorUpgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, EIP712Upgradeable, IGovernorUpgradeable, IERC721ReceiverUpgradeable, IERC1155ReceiverUpgradeable {
    using DoubleEndedQueueUpgradeable for DoubleEndedQueueUpgradeable.Bytes32Deque;
    using SafeCastUpgradeable for uint256;
    using TimersUpgradeable for TimersUpgradeable.BlockNumber;

    bytes32 public constant BALLOT_TYPEHASH = keccak256("Ballot(uint256 proposalId,uint8 support)");
    bytes32 public constant EXTENDED_BALLOT_TYPEHASH =
        keccak256("ExtendedBallot(uint256 proposalId,uint8 support,string reason,bytes params)");

    struct ProposalCore {
        TimersUpgradeable.BlockNumber voteStart;
        TimersUpgradeable.BlockNumber voteEnd;
        bool executed;
        bool canceled;
    }

    string private _name;

    mapping(uint256 => ProposalCore) private _proposals;

    // This queue keeps track of the governor operating on itself. Calls to functions protected by the
    // {onlyGovernance} modifier needs to be whitelisted in this queue. Whitelisting is set in {_beforeExecute},
    // consumed by the {onlyGovernance} modifier and eventually reset in {_afterExecute}. This ensures that the
    // execution of {onlyGovernance} protected calls can only be achieved through successful proposals.
    DoubleEndedQueueUpgradeable.Bytes32Deque private _governanceCall;

    /**
     * @dev Restricts a function so it can only be executed through governance proposals. For example, governance
     * parameter setters in {GovernorSettings} are protected using this modifier.
     *
     * The governance executing address may be different from the Governor's own address, for example it could be a
     * timelock. This can be customized by modules by overriding {_executor}. The executor is only able to invoke these
     * functions during the execution of the governor's {execute} function, and not under any other circumstances. Thus,
     * for example, additional timelock proposers are not able to change governance parameters without going through the
     * governance protocol (since v4.6).
     */
    modifier onlyGovernance() {
        require(_msgSender() == _executor(), "Governor: onlyGovernance");
        if (_executor() != address(this)) {
            bytes32 msgDataHash = keccak256(_msgData());
            // loop until popping the expected operation - throw if deque is empty (operation not authorized)
            while (_governanceCall.popFront() != msgDataHash) {}
        }
        _;
    }

    /**
     * @dev Sets the value for {name} and {version}
     */
    function __Governor_init(string memory name_) internal onlyInitializing {
        __EIP712_init_unchained(name_, version());
        __Governor_init_unchained(name_);
    }

    function __Governor_init_unchained(string memory name_) internal onlyInitializing {
        _name = name_;
    }

    /**
     * @dev Function to receive ETH that will be handled by the governor (disabled if executor is a third party contract)
     */
    receive() external payable virtual {
        require(_executor() == address(this));
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165Upgradeable, ERC165Upgradeable) returns (bool) {
        // In addition to the current interfaceId, also support previous version of the interfaceId that did not
        // include the castVoteWithReasonAndParams() function as standard
        return
            interfaceId ==
            (type(IGovernorUpgradeable).interfaceId ^
                this.castVoteWithReasonAndParams.selector ^
                this.castVoteWithReasonAndParamsBySig.selector ^
                this.getVotesWithParams.selector) ||
            interfaceId == type(IGovernorUpgradeable).interfaceId ||
            interfaceId == type(IERC1155ReceiverUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IGovernor-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IGovernor-version}.
     */
    function version() public view virtual override returns (string memory) {
        return "1";
    }

    /**
     * @dev See {IGovernor-hashProposal}.
     *
     * The proposal id is produced by hashing the ABI encoded `targets` array, the `values` array, the `calldatas` array
     * and the descriptionHash (bytes32 which itself is the keccak256 hash of the description string). This proposal id
     * can be produced from the proposal data which is part of the {ProposalCreated} event. It can even be computed in
     * advance, before the proposal is submitted.
     *
     * Note that the chainId and the governor address are not part of the proposal id computation. Consequently, the
     * same proposal (with same operation and same description) will have the same id if submitted on multiple governors
     * across multiple networks. This also means that in order to execute the same operation twice (on the same
     * governor) the proposer will have to change the description in order to avoid proposal id conflicts.
     */
    function hashProposal(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) public pure virtual override returns (uint256) {
        return uint256(keccak256(abi.encode(targets, values, calldatas, descriptionHash)));
    }

    /**
     * @dev See {IGovernor-state}.
     */
    function state(uint256 proposalId) public view virtual override returns (ProposalState) {
        ProposalCore storage proposal = _proposals[proposalId];

        if (proposal.executed) {
            return ProposalState.Executed;
        }

        if (proposal.canceled) {
            return ProposalState.Canceled;
        }

        uint256 snapshot = proposalSnapshot(proposalId);

        if (snapshot == 0) {
            revert("Governor: unknown proposal id");
        }

        if (snapshot >= block.number) {
            return ProposalState.Pending;
        }

        uint256 deadline = proposalDeadline(proposalId);

        if (deadline >= block.number) {
            return ProposalState.Active;
        }

        if (_quorumReached(proposalId) && _voteSucceeded(proposalId)) {
            return ProposalState.Succeeded;
        } else {
            return ProposalState.Defeated;
        }
    }

    /**
     * @dev See {IGovernor-proposalSnapshot}.
     */
    function proposalSnapshot(uint256 proposalId) public view virtual override returns (uint256) {
        return _proposals[proposalId].voteStart.getDeadline();
    }

    /**
     * @dev See {IGovernor-proposalDeadline}.
     */
    function proposalDeadline(uint256 proposalId) public view virtual override returns (uint256) {
        return _proposals[proposalId].voteEnd.getDeadline();
    }

    /**
     * @dev Part of the Governor Bravo's interface: _"The number of votes required in order for a voter to become a proposer"_.
     */
    function proposalThreshold() public view virtual returns (uint256) {
        return 0;
    }

    /**
     * @dev Amount of votes already cast passes the threshold limit.
     */
    function _quorumReached(uint256 proposalId) internal view virtual returns (bool);

    /**
     * @dev Is the proposal successful or not.
     */
    function _voteSucceeded(uint256 proposalId) internal view virtual returns (bool);

    /**
     * @dev Get the voting weight of `account` at a specific `blockNumber`, for a vote as described by `params`.
     */
    function _getVotes(
        address account,
        uint256 blockNumber,
        bytes memory params
    ) internal view virtual returns (uint256);

    /**
     * @dev Register a vote for `proposalId` by `account` with a given `support`, voting `weight` and voting `params`.
     *
     * Note: Support is generic and can represent various things depending on the voting system used.
     */
    function _countVote(
        uint256 proposalId,
        address account,
        uint8 support,
        uint256 weight,
        bytes memory params
    ) internal virtual;

    /**
     * @dev Default additional encoded parameters used by castVote methods that don't include them
     *
     * Note: Should be overridden by specific implementations to use an appropriate value, the
     * meaning of the additional params, in the context of that implementation
     */
    function _defaultParams() internal view virtual returns (bytes memory) {
        return "";
    }

    /**
     * @dev See {IGovernor-propose}.
     */
    function propose(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        string memory description
    ) public virtual override returns (uint256) {
        require(
            getVotes(_msgSender(), block.number - 1) >= proposalThreshold(),
            "Governor: proposer votes below proposal threshold"
        );

        uint256 proposalId = hashProposal(targets, values, calldatas, keccak256(bytes(description)));

        require(targets.length == values.length, "Governor: invalid proposal length");
        require(targets.length == calldatas.length, "Governor: invalid proposal length");
        require(targets.length > 0, "Governor: empty proposal");

        ProposalCore storage proposal = _proposals[proposalId];
        require(proposal.voteStart.isUnset(), "Governor: proposal already exists");

        uint64 snapshot = block.number.toUint64() + votingDelay().toUint64();
        uint64 deadline = snapshot + votingPeriod().toUint64();

        proposal.voteStart.setDeadline(snapshot);
        proposal.voteEnd.setDeadline(deadline);

        emit ProposalCreated(
            proposalId,
            _msgSender(),
            targets,
            values,
            new string[](targets.length),
            calldatas,
            snapshot,
            deadline,
            description
        );

        return proposalId;
    }

    /**
     * @dev See {IGovernor-execute}.
     */
    function execute(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) public payable virtual override returns (uint256) {
        uint256 proposalId = hashProposal(targets, values, calldatas, descriptionHash);

        ProposalState status = state(proposalId);
        require(
            status == ProposalState.Succeeded || status == ProposalState.Queued,
            "Governor: proposal not successful"
        );
        _proposals[proposalId].executed = true;

        emit ProposalExecuted(proposalId);

        _beforeExecute(proposalId, targets, values, calldatas, descriptionHash);
        _execute(proposalId, targets, values, calldatas, descriptionHash);
        _afterExecute(proposalId, targets, values, calldatas, descriptionHash);

        return proposalId;
    }

    /**
     * @dev Internal execution mechanism. Can be overridden to implement different execution mechanism
     */
    function _execute(
        uint256, /* proposalId */
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 /*descriptionHash*/
    ) internal virtual {
        string memory errorMessage = "Governor: call reverted without message";
        for (uint256 i = 0; i < targets.length; ++i) {
            (bool success, bytes memory returndata) = targets[i].call{value: values[i]}(calldatas[i]);
            AddressUpgradeable.verifyCallResult(success, returndata, errorMessage);
        }
    }

    /**
     * @dev Hook before execution is triggered.
     */
    function _beforeExecute(
        uint256, /* proposalId */
        address[] memory targets,
        uint256[] memory, /* values */
        bytes[] memory calldatas,
        bytes32 /*descriptionHash*/
    ) internal virtual {
        if (_executor() != address(this)) {
            for (uint256 i = 0; i < targets.length; ++i) {
                if (targets[i] == address(this)) {
                    _governanceCall.pushBack(keccak256(calldatas[i]));
                }
            }
        }
    }

    /**
     * @dev Hook after execution is triggered.
     */
    function _afterExecute(
        uint256, /* proposalId */
        address[] memory, /* targets */
        uint256[] memory, /* values */
        bytes[] memory, /* calldatas */
        bytes32 /*descriptionHash*/
    ) internal virtual {
        if (_executor() != address(this)) {
            if (!_governanceCall.empty()) {
                _governanceCall.clear();
            }
        }
    }

    /**
     * @dev Internal cancel mechanism: locks up the proposal timer, preventing it from being re-submitted. Marks it as
     * canceled to allow distinguishing it from executed proposals.
     *
     * Emits a {IGovernor-ProposalCanceled} event.
     */
    function _cancel(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) internal virtual returns (uint256) {
        uint256 proposalId = hashProposal(targets, values, calldatas, descriptionHash);
        ProposalState status = state(proposalId);

        require(
            status != ProposalState.Canceled && status != ProposalState.Expired && status != ProposalState.Executed,
            "Governor: proposal not active"
        );
        _proposals[proposalId].canceled = true;

        emit ProposalCanceled(proposalId);

        return proposalId;
    }

    /**
     * @dev See {IGovernor-getVotes}.
     */
    function getVotes(address account, uint256 blockNumber) public view virtual override returns (uint256) {
        return _getVotes(account, blockNumber, _defaultParams());
    }

    /**
     * @dev See {IGovernor-getVotesWithParams}.
     */
    function getVotesWithParams(
        address account,
        uint256 blockNumber,
        bytes memory params
    ) public view virtual override returns (uint256) {
        return _getVotes(account, blockNumber, params);
    }

    /**
     * @dev See {IGovernor-castVote}.
     */
    function castVote(uint256 proposalId, uint8 support) public virtual override returns (uint256) {
        address voter = _msgSender();
        return _castVote(proposalId, voter, support, "");
    }

    /**
     * @dev See {IGovernor-castVoteWithReason}.
     */
    function castVoteWithReason(
        uint256 proposalId,
        uint8 support,
        string calldata reason
    ) public virtual override returns (uint256) {
        address voter = _msgSender();
        return _castVote(proposalId, voter, support, reason);
    }

    /**
     * @dev See {IGovernor-castVoteWithReasonAndParams}.
     */
    function castVoteWithReasonAndParams(
        uint256 proposalId,
        uint8 support,
        string calldata reason,
        bytes memory params
    ) public virtual override returns (uint256) {
        address voter = _msgSender();
        return _castVote(proposalId, voter, support, reason, params);
    }

    /**
     * @dev See {IGovernor-castVoteBySig}.
     */
    function castVoteBySig(
        uint256 proposalId,
        uint8 support,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual override returns (uint256) {
        address voter = ECDSAUpgradeable.recover(
            _hashTypedDataV4(keccak256(abi.encode(BALLOT_TYPEHASH, proposalId, support))),
            v,
            r,
            s
        );
        return _castVote(proposalId, voter, support, "");
    }

    /**
     * @dev See {IGovernor-castVoteWithReasonAndParamsBySig}.
     */
    function castVoteWithReasonAndParamsBySig(
        uint256 proposalId,
        uint8 support,
        string calldata reason,
        bytes memory params,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual override returns (uint256) {
        address voter = ECDSAUpgradeable.recover(
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        EXTENDED_BALLOT_TYPEHASH,
                        proposalId,
                        support,
                        keccak256(bytes(reason)),
                        keccak256(params)
                    )
                )
            ),
            v,
            r,
            s
        );

        return _castVote(proposalId, voter, support, reason, params);
    }

    /**
     * @dev Internal vote casting mechanism: Check that the vote is pending, that it has not been cast yet, retrieve
     * voting weight using {IGovernor-getVotes} and call the {_countVote} internal function. Uses the _defaultParams().
     *
     * Emits a {IGovernor-VoteCast} event.
     */
    function _castVote(
        uint256 proposalId,
        address account,
        uint8 support,
        string memory reason
    ) internal virtual returns (uint256) {
        return _castVote(proposalId, account, support, reason, _defaultParams());
    }

    /**
     * @dev Internal vote casting mechanism: Check that the vote is pending, that it has not been cast yet, retrieve
     * voting weight using {IGovernor-getVotes} and call the {_countVote} internal function.
     *
     * Emits a {IGovernor-VoteCast} event.
     */
    function _castVote(
        uint256 proposalId,
        address account,
        uint8 support,
        string memory reason,
        bytes memory params
    ) internal virtual returns (uint256) {
        ProposalCore storage proposal = _proposals[proposalId];
        require(state(proposalId) == ProposalState.Active, "Governor: vote not currently active");

        uint256 weight = _getVotes(account, proposal.voteStart.getDeadline(), params);
        _countVote(proposalId, account, support, weight, params);

        if (params.length == 0) {
            emit VoteCast(account, proposalId, support, weight, reason);
        } else {
            emit VoteCastWithParams(account, proposalId, support, weight, reason, params);
        }

        return weight;
    }

    /**
     * @dev Relays a transaction or function call to an arbitrary target. In cases where the governance executor
     * is some contract other than the governor itself, like when using a timelock, this function can be invoked
     * in a governance proposal to recover tokens or Ether that was sent to the governor contract by mistake.
     * Note that if the executor is simply the governor itself, use of `relay` is redundant.
     */
    function relay(
        address target,
        uint256 value,
        bytes calldata data
    ) external payable virtual onlyGovernance {
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        AddressUpgradeable.verifyCallResult(success, returndata, "Governor: relay reverted without message");
    }

    /**
     * @dev Address through which the governor executes action. Will be overloaded by module that execute actions
     * through another contract such as a timelock.
     */
    function _executor() internal view virtual returns (address) {
        return address(this);
    }

    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    /**
     * @dev See {IERC1155Receiver-onERC1155Received}.
     */
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    /**
     * @dev See {IERC1155Receiver-onERC1155BatchReceived}.
     */
    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[46] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (governance/IGovernor.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Interface of the {Governor} core.
 *
 * _Available since v4.3._
 */
abstract contract IGovernorUpgradeable is Initializable, IERC165Upgradeable {
    function __IGovernor_init() internal onlyInitializing {
    }

    function __IGovernor_init_unchained() internal onlyInitializing {
    }
    enum ProposalState {
        Pending,
        Active,
        Canceled,
        Defeated,
        Succeeded,
        Queued,
        Expired,
        Executed
    }

    /**
     * @dev Emitted when a proposal is created.
     */
    event ProposalCreated(
        uint256 proposalId,
        address proposer,
        address[] targets,
        uint256[] values,
        string[] signatures,
        bytes[] calldatas,
        uint256 startBlock,
        uint256 endBlock,
        string description
    );

    /**
     * @dev Emitted when a proposal is canceled.
     */
    event ProposalCanceled(uint256 proposalId);

    /**
     * @dev Emitted when a proposal is executed.
     */
    event ProposalExecuted(uint256 proposalId);

    /**
     * @dev Emitted when a vote is cast without params.
     *
     * Note: `support` values should be seen as buckets. Their interpretation depends on the voting module used.
     */
    event VoteCast(address indexed voter, uint256 proposalId, uint8 support, uint256 weight, string reason);

    /**
     * @dev Emitted when a vote is cast with params.
     *
     * Note: `support` values should be seen as buckets. Their interpretation depends on the voting module used.
     * `params` are additional encoded parameters. Their intepepretation also depends on the voting module used.
     */
    event VoteCastWithParams(
        address indexed voter,
        uint256 proposalId,
        uint8 support,
        uint256 weight,
        string reason,
        bytes params
    );

    /**
     * @notice module:core
     * @dev Name of the governor instance (used in building the ERC712 domain separator).
     */
    function name() public view virtual returns (string memory);

    /**
     * @notice module:core
     * @dev Version of the governor instance (used in building the ERC712 domain separator). Default: "1"
     */
    function version() public view virtual returns (string memory);

    /**
     * @notice module:voting
     * @dev A description of the possible `support` values for {castVote} and the way these votes are counted, meant to
     * be consumed by UIs to show correct vote options and interpret the results. The string is a URL-encoded sequence of
     * key-value pairs that each describe one aspect, for example `support=bravo&quorum=for,abstain`.
     *
     * There are 2 standard keys: `support` and `quorum`.
     *
     * - `support=bravo` refers to the vote options 0 = Against, 1 = For, 2 = Abstain, as in `GovernorBravo`.
     * - `quorum=bravo` means that only For votes are counted towards quorum.
     * - `quorum=for,abstain` means that both For and Abstain votes are counted towards quorum.
     *
     * If a counting module makes use of encoded `params`, it should  include this under a `params` key with a unique
     * name that describes the behavior. For example:
     *
     * - `params=fractional` might refer to a scheme where votes are divided fractionally between for/against/abstain.
     * - `params=erc721` might refer to a scheme where specific NFTs are delegated to vote.
     *
     * NOTE: The string can be decoded by the standard
     * https://developer.mozilla.org/en-US/docs/Web/API/URLSearchParams[`URLSearchParams`]
     * JavaScript class.
     */
    // solhint-disable-next-line func-name-mixedcase
    function COUNTING_MODE() public pure virtual returns (string memory);

    /**
     * @notice module:core
     * @dev Hashing function used to (re)build the proposal id from the proposal details..
     */
    function hashProposal(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) public pure virtual returns (uint256);

    /**
     * @notice module:core
     * @dev Current state of a proposal, following Compound's convention
     */
    function state(uint256 proposalId) public view virtual returns (ProposalState);

    /**
     * @notice module:core
     * @dev Block number used to retrieve user's votes and quorum. As per Compound's Comp and OpenZeppelin's
     * ERC20Votes, the snapshot is performed at the end of this block. Hence, voting for this proposal starts at the
     * beginning of the following block.
     */
    function proposalSnapshot(uint256 proposalId) public view virtual returns (uint256);

    /**
     * @notice module:core
     * @dev Block number at which votes close. Votes close at the end of this block, so it is possible to cast a vote
     * during this block.
     */
    function proposalDeadline(uint256 proposalId) public view virtual returns (uint256);

    /**
     * @notice module:user-config
     * @dev Delay, in number of block, between the proposal is created and the vote starts. This can be increassed to
     * leave time for users to buy voting power, or delegate it, before the voting of a proposal starts.
     */
    function votingDelay() public view virtual returns (uint256);

    /**
     * @notice module:user-config
     * @dev Delay, in number of blocks, between the vote start and vote ends.
     *
     * NOTE: The {votingDelay} can delay the start of the vote. This must be considered when setting the voting
     * duration compared to the voting delay.
     */
    function votingPeriod() public view virtual returns (uint256);

    /**
     * @notice module:user-config
     * @dev Minimum number of cast voted required for a proposal to be successful.
     *
     * Note: The `blockNumber` parameter corresponds to the snapshot used for counting vote. This allows to scale the
     * quorum depending on values such as the totalSupply of a token at this block (see {ERC20Votes}).
     */
    function quorum(uint256 blockNumber) public view virtual returns (uint256);

    /**
     * @notice module:reputation
     * @dev Voting power of an `account` at a specific `blockNumber`.
     *
     * Note: this can be implemented in a number of ways, for example by reading the delegated balance from one (or
     * multiple), {ERC20Votes} tokens.
     */
    function getVotes(address account, uint256 blockNumber) public view virtual returns (uint256);

    /**
     * @notice module:reputation
     * @dev Voting power of an `account` at a specific `blockNumber` given additional encoded parameters.
     */
    function getVotesWithParams(
        address account,
        uint256 blockNumber,
        bytes memory params
    ) public view virtual returns (uint256);

    /**
     * @notice module:voting
     * @dev Returns whether `account` has cast a vote on `proposalId`.
     */
    function hasVoted(uint256 proposalId, address account) public view virtual returns (bool);

    /**
     * @dev Create a new proposal. Vote start {IGovernor-votingDelay} blocks after the proposal is created and ends
     * {IGovernor-votingPeriod} blocks after the voting starts.
     *
     * Emits a {ProposalCreated} event.
     */
    function propose(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        string memory description
    ) public virtual returns (uint256 proposalId);

    /**
     * @dev Execute a successful proposal. This requires the quorum to be reached, the vote to be successful, and the
     * deadline to be reached.
     *
     * Emits a {ProposalExecuted} event.
     *
     * Note: some module can modify the requirements for execution, for example by adding an additional timelock.
     */
    function execute(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) public payable virtual returns (uint256 proposalId);

    /**
     * @dev Cast a vote
     *
     * Emits a {VoteCast} event.
     */
    function castVote(uint256 proposalId, uint8 support) public virtual returns (uint256 balance);

    /**
     * @dev Cast a vote with a reason
     *
     * Emits a {VoteCast} event.
     */
    function castVoteWithReason(
        uint256 proposalId,
        uint8 support,
        string calldata reason
    ) public virtual returns (uint256 balance);

    /**
     * @dev Cast a vote with a reason and additional encoded parameters
     *
     * Emits a {VoteCast} or {VoteCastWithParams} event depending on the length of params.
     */
    function castVoteWithReasonAndParams(
        uint256 proposalId,
        uint8 support,
        string calldata reason,
        bytes memory params
    ) public virtual returns (uint256 balance);

    /**
     * @dev Cast a vote using the user's cryptographic signature.
     *
     * Emits a {VoteCast} event.
     */
    function castVoteBySig(
        uint256 proposalId,
        uint8 support,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual returns (uint256 balance);

    /**
     * @dev Cast a vote with a reason and additional encoded parameters using the user's cryptographic signature.
     *
     * Emits a {VoteCast} or {VoteCastWithParams} event depending on the length of params.
     */
    function castVoteWithReasonAndParamsBySig(
        uint256 proposalId,
        uint8 support,
        string calldata reason,
        bytes memory params,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual returns (uint256 balance);

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.2) (governance/TimelockController.sol)

pragma solidity ^0.8.0;

import "../access/AccessControlUpgradeable.sol";
import "../token/ERC721/IERC721ReceiverUpgradeable.sol";
import "../token/ERC1155/IERC1155ReceiverUpgradeable.sol";
import "../utils/AddressUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which acts as a timelocked controller. When set as the
 * owner of an `Ownable` smart contract, it enforces a timelock on all
 * `onlyOwner` maintenance operations. This gives time for users of the
 * controlled contract to exit before a potentially dangerous maintenance
 * operation is applied.
 *
 * By default, this contract is self administered, meaning administration tasks
 * have to go through the timelock process. The proposer (resp executor) role
 * is in charge of proposing (resp executing) operations. A common use case is
 * to position this {TimelockController} as the owner of a smart contract, with
 * a multisig or a DAO as the sole proposer.
 *
 * _Available since v3.3._
 */
contract TimelockControllerUpgradeable is Initializable, AccessControlUpgradeable, IERC721ReceiverUpgradeable, IERC1155ReceiverUpgradeable {
    bytes32 public constant TIMELOCK_ADMIN_ROLE = keccak256("TIMELOCK_ADMIN_ROLE");
    bytes32 public constant PROPOSER_ROLE = keccak256("PROPOSER_ROLE");
    bytes32 public constant EXECUTOR_ROLE = keccak256("EXECUTOR_ROLE");
    bytes32 public constant CANCELLER_ROLE = keccak256("CANCELLER_ROLE");
    uint256 internal constant _DONE_TIMESTAMP = uint256(1);

    mapping(bytes32 => uint256) private _timestamps;
    uint256 private _minDelay;

    /**
     * @dev Emitted when a call is scheduled as part of operation `id`.
     */
    event CallScheduled(
        bytes32 indexed id,
        uint256 indexed index,
        address target,
        uint256 value,
        bytes data,
        bytes32 predecessor,
        uint256 delay
    );

    /**
     * @dev Emitted when a call is performed as part of operation `id`.
     */
    event CallExecuted(bytes32 indexed id, uint256 indexed index, address target, uint256 value, bytes data);

    /**
     * @dev Emitted when operation `id` is cancelled.
     */
    event Cancelled(bytes32 indexed id);

    /**
     * @dev Emitted when the minimum delay for future operations is modified.
     */
    event MinDelayChange(uint256 oldDuration, uint256 newDuration);

    /**
     * @dev Initializes the contract with the following parameters:
     *
     * - `minDelay`: initial minimum delay for operations
     * - `proposers`: accounts to be granted proposer and canceller roles
     * - `executors`: accounts to be granted executor role
     * - `admin`: optional account to be granted admin role; disable with zero address
     *
     * IMPORTANT: The optional admin can aid with initial configuration of roles after deployment
     * without being subject to delay, but this role should be subsequently renounced in favor of
     * administration through timelocked proposals. Previous versions of this contract would assign
     * this admin to the deployer automatically and should be renounced as well.
     */
    function __TimelockController_init(
        uint256 minDelay,
        address[] memory proposers,
        address[] memory executors,
        address admin
    ) internal onlyInitializing {
        __TimelockController_init_unchained(minDelay, proposers, executors, admin);
    }

    function __TimelockController_init_unchained(
        uint256 minDelay,
        address[] memory proposers,
        address[] memory executors,
        address admin
    ) internal onlyInitializing {
        _setRoleAdmin(TIMELOCK_ADMIN_ROLE, TIMELOCK_ADMIN_ROLE);
        _setRoleAdmin(PROPOSER_ROLE, TIMELOCK_ADMIN_ROLE);
        _setRoleAdmin(EXECUTOR_ROLE, TIMELOCK_ADMIN_ROLE);
        _setRoleAdmin(CANCELLER_ROLE, TIMELOCK_ADMIN_ROLE);

        // self administration
        _setupRole(TIMELOCK_ADMIN_ROLE, address(this));

        // optional admin
        if (admin != address(0)) {
            _setupRole(TIMELOCK_ADMIN_ROLE, admin);
        }

        // register proposers and cancellers
        for (uint256 i = 0; i < proposers.length; ++i) {
            _setupRole(PROPOSER_ROLE, proposers[i]);
            _setupRole(CANCELLER_ROLE, proposers[i]);
        }

        // register executors
        for (uint256 i = 0; i < executors.length; ++i) {
            _setupRole(EXECUTOR_ROLE, executors[i]);
        }

        _minDelay = minDelay;
        emit MinDelayChange(0, minDelay);
    }

    /**
     * @dev Modifier to make a function callable only by a certain role. In
     * addition to checking the sender's role, `address(0)` 's role is also
     * considered. Granting a role to `address(0)` is equivalent to enabling
     * this role for everyone.
     */
    modifier onlyRoleOrOpenRole(bytes32 role) {
        if (!hasRole(role, address(0))) {
            _checkRole(role, _msgSender());
        }
        _;
    }

    /**
     * @dev Contract might receive/hold ETH as part of the maintenance process.
     */
    receive() external payable {}

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165Upgradeable, AccessControlUpgradeable) returns (bool) {
        return interfaceId == type(IERC1155ReceiverUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns whether an id correspond to a registered operation. This
     * includes both Pending, Ready and Done operations.
     */
    function isOperation(bytes32 id) public view virtual returns (bool registered) {
        return getTimestamp(id) > 0;
    }

    /**
     * @dev Returns whether an operation is pending or not.
     */
    function isOperationPending(bytes32 id) public view virtual returns (bool pending) {
        return getTimestamp(id) > _DONE_TIMESTAMP;
    }

    /**
     * @dev Returns whether an operation is ready or not.
     */
    function isOperationReady(bytes32 id) public view virtual returns (bool ready) {
        uint256 timestamp = getTimestamp(id);
        return timestamp > _DONE_TIMESTAMP && timestamp <= block.timestamp;
    }

    /**
     * @dev Returns whether an operation is done or not.
     */
    function isOperationDone(bytes32 id) public view virtual returns (bool done) {
        return getTimestamp(id) == _DONE_TIMESTAMP;
    }

    /**
     * @dev Returns the timestamp at with an operation becomes ready (0 for
     * unset operations, 1 for done operations).
     */
    function getTimestamp(bytes32 id) public view virtual returns (uint256 timestamp) {
        return _timestamps[id];
    }

    /**
     * @dev Returns the minimum delay for an operation to become valid.
     *
     * This value can be changed by executing an operation that calls `updateDelay`.
     */
    function getMinDelay() public view virtual returns (uint256 duration) {
        return _minDelay;
    }

    /**
     * @dev Returns the identifier of an operation containing a single
     * transaction.
     */
    function hashOperation(
        address target,
        uint256 value,
        bytes calldata data,
        bytes32 predecessor,
        bytes32 salt
    ) public pure virtual returns (bytes32 hash) {
        return keccak256(abi.encode(target, value, data, predecessor, salt));
    }

    /**
     * @dev Returns the identifier of an operation containing a batch of
     * transactions.
     */
    function hashOperationBatch(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata payloads,
        bytes32 predecessor,
        bytes32 salt
    ) public pure virtual returns (bytes32 hash) {
        return keccak256(abi.encode(targets, values, payloads, predecessor, salt));
    }

    /**
     * @dev Schedule an operation containing a single transaction.
     *
     * Emits a {CallScheduled} event.
     *
     * Requirements:
     *
     * - the caller must have the 'proposer' role.
     */
    function schedule(
        address target,
        uint256 value,
        bytes calldata data,
        bytes32 predecessor,
        bytes32 salt,
        uint256 delay
    ) public virtual onlyRole(PROPOSER_ROLE) {
        bytes32 id = hashOperation(target, value, data, predecessor, salt);
        _schedule(id, delay);
        emit CallScheduled(id, 0, target, value, data, predecessor, delay);
    }

    /**
     * @dev Schedule an operation containing a batch of transactions.
     *
     * Emits one {CallScheduled} event per transaction in the batch.
     *
     * Requirements:
     *
     * - the caller must have the 'proposer' role.
     */
    function scheduleBatch(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata payloads,
        bytes32 predecessor,
        bytes32 salt,
        uint256 delay
    ) public virtual onlyRole(PROPOSER_ROLE) {
        require(targets.length == values.length, "TimelockController: length mismatch");
        require(targets.length == payloads.length, "TimelockController: length mismatch");

        bytes32 id = hashOperationBatch(targets, values, payloads, predecessor, salt);
        _schedule(id, delay);
        for (uint256 i = 0; i < targets.length; ++i) {
            emit CallScheduled(id, i, targets[i], values[i], payloads[i], predecessor, delay);
        }
    }

    /**
     * @dev Schedule an operation that is to becomes valid after a given delay.
     */
    function _schedule(bytes32 id, uint256 delay) private {
        require(!isOperation(id), "TimelockController: operation already scheduled");
        require(delay >= getMinDelay(), "TimelockController: insufficient delay");
        _timestamps[id] = block.timestamp + delay;
    }

    /**
     * @dev Cancel an operation.
     *
     * Requirements:
     *
     * - the caller must have the 'canceller' role.
     */
    function cancel(bytes32 id) public virtual onlyRole(CANCELLER_ROLE) {
        require(isOperationPending(id), "TimelockController: operation cannot be cancelled");
        delete _timestamps[id];

        emit Cancelled(id);
    }

    /**
     * @dev Execute an (ready) operation containing a single transaction.
     *
     * Emits a {CallExecuted} event.
     *
     * Requirements:
     *
     * - the caller must have the 'executor' role.
     */
    // This function can reenter, but it doesn't pose a risk because _afterCall checks that the proposal is pending,
    // thus any modifications to the operation during reentrancy should be caught.
    // slither-disable-next-line reentrancy-eth
    function execute(
        address target,
        uint256 value,
        bytes calldata payload,
        bytes32 predecessor,
        bytes32 salt
    ) public payable virtual onlyRoleOrOpenRole(EXECUTOR_ROLE) {
        bytes32 id = hashOperation(target, value, payload, predecessor, salt);

        _beforeCall(id, predecessor);
        _execute(target, value, payload);
        emit CallExecuted(id, 0, target, value, payload);
        _afterCall(id);
    }

    /**
     * @dev Execute an (ready) operation containing a batch of transactions.
     *
     * Emits one {CallExecuted} event per transaction in the batch.
     *
     * Requirements:
     *
     * - the caller must have the 'executor' role.
     */
    // This function can reenter, but it doesn't pose a risk because _afterCall checks that the proposal is pending,
    // thus any modifications to the operation during reentrancy should be caught.
    // slither-disable-next-line reentrancy-eth
    function executeBatch(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata payloads,
        bytes32 predecessor,
        bytes32 salt
    ) public payable virtual onlyRoleOrOpenRole(EXECUTOR_ROLE) {
        require(targets.length == values.length, "TimelockController: length mismatch");
        require(targets.length == payloads.length, "TimelockController: length mismatch");

        bytes32 id = hashOperationBatch(targets, values, payloads, predecessor, salt);

        _beforeCall(id, predecessor);
        for (uint256 i = 0; i < targets.length; ++i) {
            address target = targets[i];
            uint256 value = values[i];
            bytes calldata payload = payloads[i];
            _execute(target, value, payload);
            emit CallExecuted(id, i, target, value, payload);
        }
        _afterCall(id);
    }

    /**
     * @dev Execute an operation's call.
     */
    function _execute(
        address target,
        uint256 value,
        bytes calldata data
    ) internal virtual {
        (bool success, ) = target.call{value: value}(data);
        require(success, "TimelockController: underlying transaction reverted");
    }

    /**
     * @dev Checks before execution of an operation's calls.
     */
    function _beforeCall(bytes32 id, bytes32 predecessor) private view {
        require(isOperationReady(id), "TimelockController: operation is not ready");
        require(predecessor == bytes32(0) || isOperationDone(predecessor), "TimelockController: missing dependency");
    }

    /**
     * @dev Checks after execution of an operation's calls.
     */
    function _afterCall(bytes32 id) private {
        require(isOperationReady(id), "TimelockController: operation is not ready");
        _timestamps[id] = _DONE_TIMESTAMP;
    }

    /**
     * @dev Changes the minimum timelock duration for future operations.
     *
     * Emits a {MinDelayChange} event.
     *
     * Requirements:
     *
     * - the caller must be the timelock itself. This can only be achieved by scheduling and later executing
     * an operation where the timelock is the target and the data is the ABI-encoded call to this function.
     */
    function updateDelay(uint256 newDelay) external virtual {
        require(msg.sender == address(this), "TimelockController: caller must be timelock");
        emit MinDelayChange(_minDelay, newDelay);
        _minDelay = newDelay;
    }

    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    /**
     * @dev See {IERC1155Receiver-onERC1155Received}.
     */
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    /**
     * @dev See {IERC1155Receiver-onERC1155BatchReceived}.
     */
    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[48] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (governance/utils/IVotes.sol)
pragma solidity ^0.8.0;

/**
 * @dev Common interface for {ERC20Votes}, {ERC721Votes}, and other {Votes}-enabled contracts.
 *
 * _Available since v4.5._
 */
interface IVotesUpgradeable {
    /**
     * @dev Emitted when an account changes their delegate.
     */
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    /**
     * @dev Emitted when a token transfer or delegate change results in changes to a delegate's number of votes.
     */
    event DelegateVotesChanged(address indexed delegate, uint256 previousBalance, uint256 newBalance);

    /**
     * @dev Returns the current amount of votes that `account` has.
     */
    function getVotes(address account) external view returns (uint256);

    /**
     * @dev Returns the amount of votes that `account` had at the end of a past block (`blockNumber`).
     */
    function getPastVotes(address account, uint256 blockNumber) external view returns (uint256);

    /**
     * @dev Returns the total supply of votes available at the end of a past block (`blockNumber`).
     *
     * NOTE: This value is the sum of all available votes, which is not necessarily the sum of all delegated votes.
     * Votes that have not been delegated are still part of total supply, even though they would not participate in a
     * vote.
     */
    function getPastTotalSupply(uint256 blockNumber) external view returns (uint256);

    /**
     * @dev Returns the delegate that `account` has chosen.
     */
    function delegates(address account) external view returns (address);

    /**
     * @dev Delegates votes from the sender to `delegatee`.
     */
    function delegate(address delegatee) external;

    /**
     * @dev Delegates votes from signer to `delegatee`.
     */
    function delegateBySig(
        address delegatee,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

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
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155ReceiverUpgradeable is IERC165Upgradeable {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./extensions/IERC20MetadataUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[45] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/extensions/draft-ERC20Permit.sol)

pragma solidity ^0.8.0;

import "./draft-IERC20PermitUpgradeable.sol";
import "../ERC20Upgradeable.sol";
import "../../../utils/cryptography/ECDSAUpgradeable.sol";
import "../../../utils/cryptography/EIP712Upgradeable.sol";
import "../../../utils/CountersUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on `{IERC20-approve}`, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 *
 * _Available since v3.4._
 *
 * @custom:storage-size 51
 */
abstract contract ERC20PermitUpgradeable is Initializable, ERC20Upgradeable, IERC20PermitUpgradeable, EIP712Upgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;

    mapping(address => CountersUpgradeable.Counter) private _nonces;

    // solhint-disable-next-line var-name-mixedcase
    bytes32 private constant _PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    /**
     * @dev In previous versions `_PERMIT_TYPEHASH` was declared as `immutable`.
     * However, to ensure consistency with the upgradeable transpiler, we will continue
     * to reserve a slot.
     * @custom:oz-renamed-from _PERMIT_TYPEHASH
     */
    // solhint-disable-next-line var-name-mixedcase
    bytes32 private _PERMIT_TYPEHASH_DEPRECATED_SLOT;

    /**
     * @dev Initializes the {EIP712} domain separator using the `name` parameter, and setting `version` to `"1"`.
     *
     * It's a good idea to use the same `name` that is defined as the ERC20 token name.
     */
    function __ERC20Permit_init(string memory name) internal onlyInitializing {
        __EIP712_init_unchained(name, "1");
    }

    function __ERC20Permit_init_unchained(string memory) internal onlyInitializing {}

    /**
     * @dev See {IERC20Permit-permit}.
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual override {
        require(block.timestamp <= deadline, "ERC20Permit: expired deadline");

        bytes32 structHash = keccak256(abi.encode(_PERMIT_TYPEHASH, owner, spender, value, _useNonce(owner), deadline));

        bytes32 hash = _hashTypedDataV4(structHash);

        address signer = ECDSAUpgradeable.recover(hash, v, r, s);
        require(signer == owner, "ERC20Permit: invalid signature");

        _approve(owner, spender, value);
    }

    /**
     * @dev See {IERC20Permit-nonces}.
     */
    function nonces(address owner) public view virtual override returns (uint256) {
        return _nonces[owner].current();
    }

    /**
     * @dev See {IERC20Permit-DOMAIN_SEPARATOR}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view override returns (bytes32) {
        return _domainSeparatorV4();
    }

    /**
     * @dev "Consume a nonce": return the current value and increment.
     *
     * _Available since v4.1._
     */
    function _useNonce(address owner) internal virtual returns (uint256 current) {
        CountersUpgradeable.Counter storage nonce = _nonces[owner];
        current = nonce.current();
        nonce.increment();
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20PermitUpgradeable {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/extensions/ERC20Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC20Upgradeable.sol";
import "../../../utils/ContextUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20BurnableUpgradeable is Initializable, ContextUpgradeable, ERC20Upgradeable {
    function __ERC20Burnable_init() internal onlyInitializing {
    }

    function __ERC20Burnable_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/extensions/ERC20Snapshot.sol)

pragma solidity ^0.8.0;

import "../ERC20Upgradeable.sol";
import "../../../utils/ArraysUpgradeable.sol";
import "../../../utils/CountersUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev This contract extends an ERC20 token with a snapshot mechanism. When a snapshot is created, the balances and
 * total supply at the time are recorded for later access.
 *
 * This can be used to safely create mechanisms based on token balances such as trustless dividends or weighted voting.
 * In naive implementations it's possible to perform a "double spend" attack by reusing the same balance from different
 * accounts. By using snapshots to calculate dividends or voting power, those attacks no longer apply. It can also be
 * used to create an efficient ERC20 forking mechanism.
 *
 * Snapshots are created by the internal {_snapshot} function, which will emit the {Snapshot} event and return a
 * snapshot id. To get the total supply at the time of a snapshot, call the function {totalSupplyAt} with the snapshot
 * id. To get the balance of an account at the time of a snapshot, call the {balanceOfAt} function with the snapshot id
 * and the account address.
 *
 * NOTE: Snapshot policy can be customized by overriding the {_getCurrentSnapshotId} method. For example, having it
 * return `block.number` will trigger the creation of snapshot at the beginning of each new block. When overriding this
 * function, be careful about the monotonicity of its result. Non-monotonic snapshot ids will break the contract.
 *
 * Implementing snapshots for every block using this method will incur significant gas costs. For a gas-efficient
 * alternative consider {ERC20Votes}.
 *
 * ==== Gas Costs
 *
 * Snapshots are efficient. Snapshot creation is _O(1)_. Retrieval of balances or total supply from a snapshot is _O(log
 * n)_ in the number of snapshots that have been created, although _n_ for a specific account will generally be much
 * smaller since identical balances in subsequent snapshots are stored as a single entry.
 *
 * There is a constant overhead for normal ERC20 transfers due to the additional snapshot bookkeeping. This overhead is
 * only significant for the first transfer that immediately follows a snapshot for a particular account. Subsequent
 * transfers will have normal cost until the next snapshot, and so on.
 */

abstract contract ERC20SnapshotUpgradeable is Initializable, ERC20Upgradeable {
    function __ERC20Snapshot_init() internal onlyInitializing {
    }

    function __ERC20Snapshot_init_unchained() internal onlyInitializing {
    }
    // Inspired by Jordi Baylina's MiniMeToken to record historical balances:
    // https://github.com/Giveth/minime/blob/ea04d950eea153a04c51fa510b068b9dded390cb/contracts/MiniMeToken.sol

    using ArraysUpgradeable for uint256[];
    using CountersUpgradeable for CountersUpgradeable.Counter;

    // Snapshotted values have arrays of ids and the value corresponding to that id. These could be an array of a
    // Snapshot struct, but that would impede usage of functions that work on an array.
    struct Snapshots {
        uint256[] ids;
        uint256[] values;
    }

    mapping(address => Snapshots) private _accountBalanceSnapshots;
    Snapshots private _totalSupplySnapshots;

    // Snapshot ids increase monotonically, with the first value being 1. An id of 0 is invalid.
    CountersUpgradeable.Counter private _currentSnapshotId;

    /**
     * @dev Emitted by {_snapshot} when a snapshot identified by `id` is created.
     */
    event Snapshot(uint256 id);

    /**
     * @dev Creates a new snapshot and returns its snapshot id.
     *
     * Emits a {Snapshot} event that contains the same id.
     *
     * {_snapshot} is `internal` and you have to decide how to expose it externally. Its usage may be restricted to a
     * set of accounts, for example using {AccessControl}, or it may be open to the public.
     *
     * [WARNING]
     * ====
     * While an open way of calling {_snapshot} is required for certain trust minimization mechanisms such as forking,
     * you must consider that it can potentially be used by attackers in two ways.
     *
     * First, it can be used to increase the cost of retrieval of values from snapshots, although it will grow
     * logarithmically thus rendering this attack ineffective in the long term. Second, it can be used to target
     * specific accounts and increase the cost of ERC20 transfers for them, in the ways specified in the Gas Costs
     * section above.
     *
     * We haven't measured the actual numbers; if this is something you're interested in please reach out to us.
     * ====
     */
    function _snapshot() internal virtual returns (uint256) {
        _currentSnapshotId.increment();

        uint256 currentId = _getCurrentSnapshotId();
        emit Snapshot(currentId);
        return currentId;
    }

    /**
     * @dev Get the current snapshotId
     */
    function _getCurrentSnapshotId() internal view virtual returns (uint256) {
        return _currentSnapshotId.current();
    }

    /**
     * @dev Retrieves the balance of `account` at the time `snapshotId` was created.
     */
    function balanceOfAt(address account, uint256 snapshotId) public view virtual returns (uint256) {
        (bool snapshotted, uint256 value) = _valueAt(snapshotId, _accountBalanceSnapshots[account]);

        return snapshotted ? value : balanceOf(account);
    }

    /**
     * @dev Retrieves the total supply at the time `snapshotId` was created.
     */
    function totalSupplyAt(uint256 snapshotId) public view virtual returns (uint256) {
        (bool snapshotted, uint256 value) = _valueAt(snapshotId, _totalSupplySnapshots);

        return snapshotted ? value : totalSupply();
    }

    // Update balance and/or total supply snapshots before the values are modified. This is implemented
    // in the _beforeTokenTransfer hook, which is executed for _mint, _burn, and _transfer operations.
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        if (from == address(0)) {
            // mint
            _updateAccountSnapshot(to);
            _updateTotalSupplySnapshot();
        } else if (to == address(0)) {
            // burn
            _updateAccountSnapshot(from);
            _updateTotalSupplySnapshot();
        } else {
            // transfer
            _updateAccountSnapshot(from);
            _updateAccountSnapshot(to);
        }
    }

    function _valueAt(uint256 snapshotId, Snapshots storage snapshots) private view returns (bool, uint256) {
        require(snapshotId > 0, "ERC20Snapshot: id is 0");
        require(snapshotId <= _getCurrentSnapshotId(), "ERC20Snapshot: nonexistent id");

        // When a valid snapshot is queried, there are three possibilities:
        //  a) The queried value was not modified after the snapshot was taken. Therefore, a snapshot entry was never
        //  created for this id, and all stored snapshot ids are smaller than the requested one. The value that corresponds
        //  to this id is the current one.
        //  b) The queried value was modified after the snapshot was taken. Therefore, there will be an entry with the
        //  requested id, and its value is the one to return.
        //  c) More snapshots were created after the requested one, and the queried value was later modified. There will be
        //  no entry for the requested id: the value that corresponds to it is that of the smallest snapshot id that is
        //  larger than the requested one.
        //
        // In summary, we need to find an element in an array, returning the index of the smallest value that is larger if
        // it is not found, unless said value doesn't exist (e.g. when all values are smaller). Arrays.findUpperBound does
        // exactly this.

        uint256 index = snapshots.ids.findUpperBound(snapshotId);

        if (index == snapshots.ids.length) {
            return (false, 0);
        } else {
            return (true, snapshots.values[index]);
        }
    }

    function _updateAccountSnapshot(address account) private {
        _updateSnapshot(_accountBalanceSnapshots[account], balanceOf(account));
    }

    function _updateTotalSupplySnapshot() private {
        _updateSnapshot(_totalSupplySnapshots, totalSupply());
    }

    function _updateSnapshot(Snapshots storage snapshots, uint256 currentValue) private {
        uint256 currentId = _getCurrentSnapshotId();
        if (_lastSnapshotId(snapshots.ids) < currentId) {
            snapshots.ids.push(currentId);
            snapshots.values.push(currentValue);
        }
    }

    function _lastSnapshotId(uint256[] storage ids) private view returns (uint256) {
        if (ids.length == 0) {
            return 0;
        } else {
            return ids[ids.length - 1];
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[46] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.1) (token/ERC20/extensions/ERC20Votes.sol)

pragma solidity ^0.8.0;

import "./draft-ERC20PermitUpgradeable.sol";
import "../../../utils/math/MathUpgradeable.sol";
import "../../../governance/utils/IVotesUpgradeable.sol";
import "../../../utils/math/SafeCastUpgradeable.sol";
import "../../../utils/cryptography/ECDSAUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev Extension of ERC20 to support Compound-like voting and delegation. This version is more generic than Compound's,
 * and supports token supply up to 2^224^ - 1, while COMP is limited to 2^96^ - 1.
 *
 * NOTE: If exact COMP compatibility is required, use the {ERC20VotesComp} variant of this module.
 *
 * This extension keeps a history (checkpoints) of each account's vote power. Vote power can be delegated either
 * by calling the {delegate} function directly, or by providing a signature to be used with {delegateBySig}. Voting
 * power can be queried through the public accessors {getVotes} and {getPastVotes}.
 *
 * By default, token balance does not account for voting power. This makes transfers cheaper. The downside is that it
 * requires users to delegate to themselves in order to activate checkpoints and have their voting power tracked.
 *
 * _Available since v4.2._
 */
abstract contract ERC20VotesUpgradeable is Initializable, IVotesUpgradeable, ERC20PermitUpgradeable {
    function __ERC20Votes_init() internal onlyInitializing {
    }

    function __ERC20Votes_init_unchained() internal onlyInitializing {
    }
    struct Checkpoint {
        uint32 fromBlock;
        uint224 votes;
    }

    bytes32 private constant _DELEGATION_TYPEHASH =
        keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

    mapping(address => address) private _delegates;
    mapping(address => Checkpoint[]) private _checkpoints;
    Checkpoint[] private _totalSupplyCheckpoints;

    /**
     * @dev Get the `pos`-th checkpoint for `account`.
     */
    function checkpoints(address account, uint32 pos) public view virtual returns (Checkpoint memory) {
        return _checkpoints[account][pos];
    }

    /**
     * @dev Get number of checkpoints for `account`.
     */
    function numCheckpoints(address account) public view virtual returns (uint32) {
        return SafeCastUpgradeable.toUint32(_checkpoints[account].length);
    }

    /**
     * @dev Get the address `account` is currently delegating to.
     */
    function delegates(address account) public view virtual override returns (address) {
        return _delegates[account];
    }

    /**
     * @dev Gets the current votes balance for `account`
     */
    function getVotes(address account) public view virtual override returns (uint256) {
        uint256 pos = _checkpoints[account].length;
        return pos == 0 ? 0 : _checkpoints[account][pos - 1].votes;
    }

    /**
     * @dev Retrieve the number of votes for `account` at the end of `blockNumber`.
     *
     * Requirements:
     *
     * - `blockNumber` must have been already mined
     */
    function getPastVotes(address account, uint256 blockNumber) public view virtual override returns (uint256) {
        require(blockNumber < block.number, "ERC20Votes: block not yet mined");
        return _checkpointsLookup(_checkpoints[account], blockNumber);
    }

    /**
     * @dev Retrieve the `totalSupply` at the end of `blockNumber`. Note, this value is the sum of all balances.
     * It is but NOT the sum of all the delegated votes!
     *
     * Requirements:
     *
     * - `blockNumber` must have been already mined
     */
    function getPastTotalSupply(uint256 blockNumber) public view virtual override returns (uint256) {
        require(blockNumber < block.number, "ERC20Votes: block not yet mined");
        return _checkpointsLookup(_totalSupplyCheckpoints, blockNumber);
    }

    /**
     * @dev Lookup a value in a list of (sorted) checkpoints.
     */
    function _checkpointsLookup(Checkpoint[] storage ckpts, uint256 blockNumber) private view returns (uint256) {
        // We run a binary search to look for the earliest checkpoint taken after `blockNumber`.
        //
        // Initially we check if the block is recent to narrow the search range.
        // During the loop, the index of the wanted checkpoint remains in the range [low-1, high).
        // With each iteration, either `low` or `high` is moved towards the middle of the range to maintain the invariant.
        // - If the middle checkpoint is after `blockNumber`, we look in [low, mid)
        // - If the middle checkpoint is before or equal to `blockNumber`, we look in [mid+1, high)
        // Once we reach a single value (when low == high), we've found the right checkpoint at the index high-1, if not
        // out of bounds (in which case we're looking too far in the past and the result is 0).
        // Note that if the latest checkpoint available is exactly for `blockNumber`, we end up with an index that is
        // past the end of the array, so we technically don't find a checkpoint after `blockNumber`, but it works out
        // the same.
        uint256 length = ckpts.length;

        uint256 low = 0;
        uint256 high = length;

        if (length > 5) {
            uint256 mid = length - MathUpgradeable.sqrt(length);
            if (_unsafeAccess(ckpts, mid).fromBlock > blockNumber) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        while (low < high) {
            uint256 mid = MathUpgradeable.average(low, high);
            if (_unsafeAccess(ckpts, mid).fromBlock > blockNumber) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        return high == 0 ? 0 : _unsafeAccess(ckpts, high - 1).votes;
    }

    /**
     * @dev Delegate votes from the sender to `delegatee`.
     */
    function delegate(address delegatee) public virtual override {
        _delegate(_msgSender(), delegatee);
    }

    /**
     * @dev Delegates votes from signer to `delegatee`
     */
    function delegateBySig(
        address delegatee,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual override {
        require(block.timestamp <= expiry, "ERC20Votes: signature expired");
        address signer = ECDSAUpgradeable.recover(
            _hashTypedDataV4(keccak256(abi.encode(_DELEGATION_TYPEHASH, delegatee, nonce, expiry))),
            v,
            r,
            s
        );
        require(nonce == _useNonce(signer), "ERC20Votes: invalid nonce");
        _delegate(signer, delegatee);
    }

    /**
     * @dev Maximum token supply. Defaults to `type(uint224).max` (2^224^ - 1).
     */
    function _maxSupply() internal view virtual returns (uint224) {
        return type(uint224).max;
    }

    /**
     * @dev Snapshots the totalSupply after it has been increased.
     */
    function _mint(address account, uint256 amount) internal virtual override {
        super._mint(account, amount);
        require(totalSupply() <= _maxSupply(), "ERC20Votes: total supply risks overflowing votes");

        _writeCheckpoint(_totalSupplyCheckpoints, _add, amount);
    }

    /**
     * @dev Snapshots the totalSupply after it has been decreased.
     */
    function _burn(address account, uint256 amount) internal virtual override {
        super._burn(account, amount);

        _writeCheckpoint(_totalSupplyCheckpoints, _subtract, amount);
    }

    /**
     * @dev Move voting power when tokens are transferred.
     *
     * Emits a {IVotes-DelegateVotesChanged} event.
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._afterTokenTransfer(from, to, amount);

        _moveVotingPower(delegates(from), delegates(to), amount);
    }

    /**
     * @dev Change delegation for `delegator` to `delegatee`.
     *
     * Emits events {IVotes-DelegateChanged} and {IVotes-DelegateVotesChanged}.
     */
    function _delegate(address delegator, address delegatee) internal virtual {
        address currentDelegate = delegates(delegator);
        uint256 delegatorBalance = balanceOf(delegator);
        _delegates[delegator] = delegatee;

        emit DelegateChanged(delegator, currentDelegate, delegatee);

        _moveVotingPower(currentDelegate, delegatee, delegatorBalance);
    }

    function _moveVotingPower(
        address src,
        address dst,
        uint256 amount
    ) private {
        if (src != dst && amount > 0) {
            if (src != address(0)) {
                (uint256 oldWeight, uint256 newWeight) = _writeCheckpoint(_checkpoints[src], _subtract, amount);
                emit DelegateVotesChanged(src, oldWeight, newWeight);
            }

            if (dst != address(0)) {
                (uint256 oldWeight, uint256 newWeight) = _writeCheckpoint(_checkpoints[dst], _add, amount);
                emit DelegateVotesChanged(dst, oldWeight, newWeight);
            }
        }
    }

    function _writeCheckpoint(
        Checkpoint[] storage ckpts,
        function(uint256, uint256) view returns (uint256) op,
        uint256 delta
    ) private returns (uint256 oldWeight, uint256 newWeight) {
        uint256 pos = ckpts.length;

        Checkpoint memory oldCkpt = pos == 0 ? Checkpoint(0, 0) : _unsafeAccess(ckpts, pos - 1);

        oldWeight = oldCkpt.votes;
        newWeight = op(oldWeight, delta);

        if (pos > 0 && oldCkpt.fromBlock == block.number) {
            _unsafeAccess(ckpts, pos - 1).votes = SafeCastUpgradeable.toUint224(newWeight);
        } else {
            ckpts.push(Checkpoint({fromBlock: SafeCastUpgradeable.toUint32(block.number), votes: SafeCastUpgradeable.toUint224(newWeight)}));
        }
    }

    function _add(uint256 a, uint256 b) private pure returns (uint256) {
        return a + b;
    }

    function _subtract(uint256 a, uint256 b) private pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Access an element of the array without performing bounds check. The position is assumed to be within bounds.
     */
    function _unsafeAccess(Checkpoint[] storage ckpts, uint256 pos) private pure returns (Checkpoint storage result) {
        assembly {
            mstore(0, ckpts.slot)
            result.slot := add(keccak256(0, 0x20), pos)
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[47] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../extensions/draft-IERC20PermitUpgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20PermitUpgradeable token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Arrays.sol)

pragma solidity ^0.8.0;

import "./StorageSlotUpgradeable.sol";
import "./math/MathUpgradeable.sol";

/**
 * @dev Collection of functions related to array types.
 */
library ArraysUpgradeable {
    using StorageSlotUpgradeable for bytes32;

    /**
     * @dev Searches a sorted `array` and returns the first index that contains
     * a value greater or equal to `element`. If no such index exists (i.e. all
     * values in the array are strictly less than `element`), the array length is
     * returned. Time complexity O(log n).
     *
     * `array` is expected to be sorted in ascending order, and to contain no
     * repeated elements.
     */
    function findUpperBound(uint256[] storage array, uint256 element) internal view returns (uint256) {
        if (array.length == 0) {
            return 0;
        }

        uint256 low = 0;
        uint256 high = array.length;

        while (low < high) {
            uint256 mid = MathUpgradeable.average(low, high);

            // Note that mid will always be strictly less than high (i.e. it will be a valid array index)
            // because Math.average rounds down (it does integer division with truncation).
            if (unsafeAccess(array, mid).value > element) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        // At this point `low` is the exclusive upper bound. We will return the inclusive upper bound.
        if (low > 0 && unsafeAccess(array, low - 1).value == element) {
            return low - 1;
        } else {
            return low;
        }
    }

    /**
     * @dev Access an array in an "unsafe" way. Skips solidity "index-out-of-range" check.
     *
     * WARNING: Only use if you are certain `pos` is lower than the array length.
     */
    function unsafeAccess(address[] storage arr, uint256 pos) internal pure returns (StorageSlotUpgradeable.AddressSlot storage) {
        bytes32 slot;
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0, arr.slot)
            slot := add(keccak256(0, 0x20), pos)
        }
        return slot.getAddressSlot();
    }

    /**
     * @dev Access an array in an "unsafe" way. Skips solidity "index-out-of-range" check.
     *
     * WARNING: Only use if you are certain `pos` is lower than the array length.
     */
    function unsafeAccess(bytes32[] storage arr, uint256 pos) internal pure returns (StorageSlotUpgradeable.Bytes32Slot storage) {
        bytes32 slot;
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0, arr.slot)
            slot := add(keccak256(0, 0x20), pos)
        }
        return slot.getBytes32Slot();
    }

    /**
     * @dev Access an array in an "unsafe" way. Skips solidity "index-out-of-range" check.
     *
     * WARNING: Only use if you are certain `pos` is lower than the array length.
     */
    function unsafeAccess(uint256[] storage arr, uint256 pos) internal pure returns (StorageSlotUpgradeable.Uint256Slot storage) {
        bytes32 slot;
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0, arr.slot)
            slot := add(keccak256(0, 0x20), pos)
        }
        return slot.getUint256Slot();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.1) (utils/Checkpoints.sol)
// This file was procedurally generated from scripts/generate/templates/Checkpoints.js.

pragma solidity ^0.8.0;

import "./math/MathUpgradeable.sol";
import "./math/SafeCastUpgradeable.sol";

/**
 * @dev This library defines the `History` struct, for checkpointing values as they change at different points in
 * time, and later looking up past values by block number. See {Votes} as an example.
 *
 * To create a history of checkpoints define a variable type `Checkpoints.History` in your contract, and store a new
 * checkpoint for the current transaction block using the {push} function.
 *
 * _Available since v4.5._
 */
library CheckpointsUpgradeable {
    struct History {
        Checkpoint[] _checkpoints;
    }

    struct Checkpoint {
        uint32 _blockNumber;
        uint224 _value;
    }

    /**
     * @dev Returns the value at a given block number. If a checkpoint is not available at that block, the closest one
     * before it is returned, or zero otherwise. Because the number returned corresponds to that at the end of the
     * block, the requested block number must be in the past, excluding the current block.
     */
    function getAtBlock(History storage self, uint256 blockNumber) internal view returns (uint256) {
        require(blockNumber < block.number, "Checkpoints: block not yet mined");
        uint32 key = SafeCastUpgradeable.toUint32(blockNumber);

        uint256 len = self._checkpoints.length;
        uint256 pos = _upperBinaryLookup(self._checkpoints, key, 0, len);
        return pos == 0 ? 0 : _unsafeAccess(self._checkpoints, pos - 1)._value;
    }

    /**
     * @dev Returns the value at a given block number. If a checkpoint is not available at that block, the closest one
     * before it is returned, or zero otherwise. Similar to {upperLookup} but optimized for the case when the searched
     * checkpoint is probably "recent", defined as being among the last sqrt(N) checkpoints where N is the number of
     * checkpoints.
     */
    function getAtProbablyRecentBlock(History storage self, uint256 blockNumber) internal view returns (uint256) {
        require(blockNumber < block.number, "Checkpoints: block not yet mined");
        uint32 key = SafeCastUpgradeable.toUint32(blockNumber);

        uint256 len = self._checkpoints.length;

        uint256 low = 0;
        uint256 high = len;

        if (len > 5) {
            uint256 mid = len - MathUpgradeable.sqrt(len);
            if (key < _unsafeAccess(self._checkpoints, mid)._blockNumber) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        uint256 pos = _upperBinaryLookup(self._checkpoints, key, low, high);

        return pos == 0 ? 0 : _unsafeAccess(self._checkpoints, pos - 1)._value;
    }

    /**
     * @dev Pushes a value onto a History so that it is stored as the checkpoint for the current block.
     *
     * Returns previous value and new value.
     */
    function push(History storage self, uint256 value) internal returns (uint256, uint256) {
        return _insert(self._checkpoints, SafeCastUpgradeable.toUint32(block.number), SafeCastUpgradeable.toUint224(value));
    }

    /**
     * @dev Pushes a value onto a History, by updating the latest value using binary operation `op`. The new value will
     * be set to `op(latest, delta)`.
     *
     * Returns previous value and new value.
     */
    function push(
        History storage self,
        function(uint256, uint256) view returns (uint256) op,
        uint256 delta
    ) internal returns (uint256, uint256) {
        return push(self, op(latest(self), delta));
    }

    /**
     * @dev Returns the value in the most recent checkpoint, or zero if there are no checkpoints.
     */
    function latest(History storage self) internal view returns (uint224) {
        uint256 pos = self._checkpoints.length;
        return pos == 0 ? 0 : _unsafeAccess(self._checkpoints, pos - 1)._value;
    }

    /**
     * @dev Returns whether there is a checkpoint in the structure (i.e. it is not empty), and if so the key and value
     * in the most recent checkpoint.
     */
    function latestCheckpoint(History storage self)
        internal
        view
        returns (
            bool exists,
            uint32 _blockNumber,
            uint224 _value
        )
    {
        uint256 pos = self._checkpoints.length;
        if (pos == 0) {
            return (false, 0, 0);
        } else {
            Checkpoint memory ckpt = _unsafeAccess(self._checkpoints, pos - 1);
            return (true, ckpt._blockNumber, ckpt._value);
        }
    }

    /**
     * @dev Returns the number of checkpoint.
     */
    function length(History storage self) internal view returns (uint256) {
        return self._checkpoints.length;
    }

    /**
     * @dev Pushes a (`key`, `value`) pair into an ordered list of checkpoints, either by inserting a new checkpoint,
     * or by updating the last one.
     */
    function _insert(
        Checkpoint[] storage self,
        uint32 key,
        uint224 value
    ) private returns (uint224, uint224) {
        uint256 pos = self.length;

        if (pos > 0) {
            // Copying to memory is important here.
            Checkpoint memory last = _unsafeAccess(self, pos - 1);

            // Checkpoints keys must be increasing.
            require(last._blockNumber <= key, "Checkpoint: invalid key");

            // Update or push new checkpoint
            if (last._blockNumber == key) {
                _unsafeAccess(self, pos - 1)._value = value;
            } else {
                self.push(Checkpoint({_blockNumber: key, _value: value}));
            }
            return (last._value, value);
        } else {
            self.push(Checkpoint({_blockNumber: key, _value: value}));
            return (0, value);
        }
    }

    /**
     * @dev Return the index of the oldest checkpoint whose key is greater than the search key, or `high` if there is none.
     * `low` and `high` define a section where to do the search, with inclusive `low` and exclusive `high`.
     *
     * WARNING: `high` should not be greater than the array's length.
     */
    function _upperBinaryLookup(
        Checkpoint[] storage self,
        uint32 key,
        uint256 low,
        uint256 high
    ) private view returns (uint256) {
        while (low < high) {
            uint256 mid = MathUpgradeable.average(low, high);
            if (_unsafeAccess(self, mid)._blockNumber > key) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }
        return high;
    }

    /**
     * @dev Return the index of the oldest checkpoint whose key is greater or equal than the search key, or `high` if there is none.
     * `low` and `high` define a section where to do the search, with inclusive `low` and exclusive `high`.
     *
     * WARNING: `high` should not be greater than the array's length.
     */
    function _lowerBinaryLookup(
        Checkpoint[] storage self,
        uint32 key,
        uint256 low,
        uint256 high
    ) private view returns (uint256) {
        while (low < high) {
            uint256 mid = MathUpgradeable.average(low, high);
            if (_unsafeAccess(self, mid)._blockNumber < key) {
                low = mid + 1;
            } else {
                high = mid;
            }
        }
        return high;
    }

    /**
     * @dev Access an element of the array without performing bounds check. The position is assumed to be within bounds.
     */
    function _unsafeAccess(Checkpoint[] storage self, uint256 pos) private pure returns (Checkpoint storage result) {
        assembly {
            mstore(0, self.slot)
            result.slot := add(keccak256(0, 0x20), pos)
        }
    }

    struct Trace224 {
        Checkpoint224[] _checkpoints;
    }

    struct Checkpoint224 {
        uint32 _key;
        uint224 _value;
    }

    /**
     * @dev Pushes a (`key`, `value`) pair into a Trace224 so that it is stored as the checkpoint.
     *
     * Returns previous value and new value.
     */
    function push(
        Trace224 storage self,
        uint32 key,
        uint224 value
    ) internal returns (uint224, uint224) {
        return _insert(self._checkpoints, key, value);
    }

    /**
     * @dev Returns the value in the oldest checkpoint with key greater or equal than the search key, or zero if there is none.
     */
    function lowerLookup(Trace224 storage self, uint32 key) internal view returns (uint224) {
        uint256 len = self._checkpoints.length;
        uint256 pos = _lowerBinaryLookup(self._checkpoints, key, 0, len);
        return pos == len ? 0 : _unsafeAccess(self._checkpoints, pos)._value;
    }

    /**
     * @dev Returns the value in the most recent checkpoint with key lower or equal than the search key.
     */
    function upperLookup(Trace224 storage self, uint32 key) internal view returns (uint224) {
        uint256 len = self._checkpoints.length;
        uint256 pos = _upperBinaryLookup(self._checkpoints, key, 0, len);
        return pos == 0 ? 0 : _unsafeAccess(self._checkpoints, pos - 1)._value;
    }

    /**
     * @dev Returns the value in the most recent checkpoint, or zero if there are no checkpoints.
     */
    function latest(Trace224 storage self) internal view returns (uint224) {
        uint256 pos = self._checkpoints.length;
        return pos == 0 ? 0 : _unsafeAccess(self._checkpoints, pos - 1)._value;
    }

    /**
     * @dev Returns whether there is a checkpoint in the structure (i.e. it is not empty), and if so the key and value
     * in the most recent checkpoint.
     */
    function latestCheckpoint(Trace224 storage self)
        internal
        view
        returns (
            bool exists,
            uint32 _key,
            uint224 _value
        )
    {
        uint256 pos = self._checkpoints.length;
        if (pos == 0) {
            return (false, 0, 0);
        } else {
            Checkpoint224 memory ckpt = _unsafeAccess(self._checkpoints, pos - 1);
            return (true, ckpt._key, ckpt._value);
        }
    }

    /**
     * @dev Returns the number of checkpoint.
     */
    function length(Trace224 storage self) internal view returns (uint256) {
        return self._checkpoints.length;
    }

    /**
     * @dev Pushes a (`key`, `value`) pair into an ordered list of checkpoints, either by inserting a new checkpoint,
     * or by updating the last one.
     */
    function _insert(
        Checkpoint224[] storage self,
        uint32 key,
        uint224 value
    ) private returns (uint224, uint224) {
        uint256 pos = self.length;

        if (pos > 0) {
            // Copying to memory is important here.
            Checkpoint224 memory last = _unsafeAccess(self, pos - 1);

            // Checkpoints keys must be increasing.
            require(last._key <= key, "Checkpoint: invalid key");

            // Update or push new checkpoint
            if (last._key == key) {
                _unsafeAccess(self, pos - 1)._value = value;
            } else {
                self.push(Checkpoint224({_key: key, _value: value}));
            }
            return (last._value, value);
        } else {
            self.push(Checkpoint224({_key: key, _value: value}));
            return (0, value);
        }
    }

    /**
     * @dev Return the index of the oldest checkpoint whose key is greater than the search key, or `high` if there is none.
     * `low` and `high` define a section where to do the search, with inclusive `low` and exclusive `high`.
     *
     * WARNING: `high` should not be greater than the array's length.
     */
    function _upperBinaryLookup(
        Checkpoint224[] storage self,
        uint32 key,
        uint256 low,
        uint256 high
    ) private view returns (uint256) {
        while (low < high) {
            uint256 mid = MathUpgradeable.average(low, high);
            if (_unsafeAccess(self, mid)._key > key) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }
        return high;
    }

    /**
     * @dev Return the index of the oldest checkpoint whose key is greater or equal than the search key, or `high` if there is none.
     * `low` and `high` define a section where to do the search, with inclusive `low` and exclusive `high`.
     *
     * WARNING: `high` should not be greater than the array's length.
     */
    function _lowerBinaryLookup(
        Checkpoint224[] storage self,
        uint32 key,
        uint256 low,
        uint256 high
    ) private view returns (uint256) {
        while (low < high) {
            uint256 mid = MathUpgradeable.average(low, high);
            if (_unsafeAccess(self, mid)._key < key) {
                low = mid + 1;
            } else {
                high = mid;
            }
        }
        return high;
    }

    /**
     * @dev Access an element of the array without performing bounds check. The position is assumed to be within bounds.
     */
    function _unsafeAccess(Checkpoint224[] storage self, uint256 pos)
        private
        pure
        returns (Checkpoint224 storage result)
    {
        assembly {
            mstore(0, self.slot)
            result.slot := add(keccak256(0, 0x20), pos)
        }
    }

    struct Trace160 {
        Checkpoint160[] _checkpoints;
    }

    struct Checkpoint160 {
        uint96 _key;
        uint160 _value;
    }

    /**
     * @dev Pushes a (`key`, `value`) pair into a Trace160 so that it is stored as the checkpoint.
     *
     * Returns previous value and new value.
     */
    function push(
        Trace160 storage self,
        uint96 key,
        uint160 value
    ) internal returns (uint160, uint160) {
        return _insert(self._checkpoints, key, value);
    }

    /**
     * @dev Returns the value in the oldest checkpoint with key greater or equal than the search key, or zero if there is none.
     */
    function lowerLookup(Trace160 storage self, uint96 key) internal view returns (uint160) {
        uint256 len = self._checkpoints.length;
        uint256 pos = _lowerBinaryLookup(self._checkpoints, key, 0, len);
        return pos == len ? 0 : _unsafeAccess(self._checkpoints, pos)._value;
    }

    /**
     * @dev Returns the value in the most recent checkpoint with key lower or equal than the search key.
     */
    function upperLookup(Trace160 storage self, uint96 key) internal view returns (uint160) {
        uint256 len = self._checkpoints.length;
        uint256 pos = _upperBinaryLookup(self._checkpoints, key, 0, len);
        return pos == 0 ? 0 : _unsafeAccess(self._checkpoints, pos - 1)._value;
    }

    /**
     * @dev Returns the value in the most recent checkpoint, or zero if there are no checkpoints.
     */
    function latest(Trace160 storage self) internal view returns (uint160) {
        uint256 pos = self._checkpoints.length;
        return pos == 0 ? 0 : _unsafeAccess(self._checkpoints, pos - 1)._value;
    }

    /**
     * @dev Returns whether there is a checkpoint in the structure (i.e. it is not empty), and if so the key and value
     * in the most recent checkpoint.
     */
    function latestCheckpoint(Trace160 storage self)
        internal
        view
        returns (
            bool exists,
            uint96 _key,
            uint160 _value
        )
    {
        uint256 pos = self._checkpoints.length;
        if (pos == 0) {
            return (false, 0, 0);
        } else {
            Checkpoint160 memory ckpt = _unsafeAccess(self._checkpoints, pos - 1);
            return (true, ckpt._key, ckpt._value);
        }
    }

    /**
     * @dev Returns the number of checkpoint.
     */
    function length(Trace160 storage self) internal view returns (uint256) {
        return self._checkpoints.length;
    }

    /**
     * @dev Pushes a (`key`, `value`) pair into an ordered list of checkpoints, either by inserting a new checkpoint,
     * or by updating the last one.
     */
    function _insert(
        Checkpoint160[] storage self,
        uint96 key,
        uint160 value
    ) private returns (uint160, uint160) {
        uint256 pos = self.length;

        if (pos > 0) {
            // Copying to memory is important here.
            Checkpoint160 memory last = _unsafeAccess(self, pos - 1);

            // Checkpoints keys must be increasing.
            require(last._key <= key, "Checkpoint: invalid key");

            // Update or push new checkpoint
            if (last._key == key) {
                _unsafeAccess(self, pos - 1)._value = value;
            } else {
                self.push(Checkpoint160({_key: key, _value: value}));
            }
            return (last._value, value);
        } else {
            self.push(Checkpoint160({_key: key, _value: value}));
            return (0, value);
        }
    }

    /**
     * @dev Return the index of the oldest checkpoint whose key is greater than the search key, or `high` if there is none.
     * `low` and `high` define a section where to do the search, with inclusive `low` and exclusive `high`.
     *
     * WARNING: `high` should not be greater than the array's length.
     */
    function _upperBinaryLookup(
        Checkpoint160[] storage self,
        uint96 key,
        uint256 low,
        uint256 high
    ) private view returns (uint256) {
        while (low < high) {
            uint256 mid = MathUpgradeable.average(low, high);
            if (_unsafeAccess(self, mid)._key > key) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }
        return high;
    }

    /**
     * @dev Return the index of the oldest checkpoint whose key is greater or equal than the search key, or `high` if there is none.
     * `low` and `high` define a section where to do the search, with inclusive `low` and exclusive `high`.
     *
     * WARNING: `high` should not be greater than the array's length.
     */
    function _lowerBinaryLookup(
        Checkpoint160[] storage self,
        uint96 key,
        uint256 low,
        uint256 high
    ) private view returns (uint256) {
        while (low < high) {
            uint256 mid = MathUpgradeable.average(low, high);
            if (_unsafeAccess(self, mid)._key < key) {
                low = mid + 1;
            } else {
                high = mid;
            }
        }
        return high;
    }

    /**
     * @dev Access an element of the array without performing bounds check. The position is assumed to be within bounds.
     */
    function _unsafeAccess(Checkpoint160[] storage self, uint256 pos)
        private
        pure
        returns (Checkpoint160 storage result)
    {
        assembly {
            mstore(0, self.slot)
            result.slot := add(keccak256(0, 0x20), pos)
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library CountersUpgradeable {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Create2.sol)

pragma solidity ^0.8.0;

/**
 * @dev Helper to make usage of the `CREATE2` EVM opcode easier and safer.
 * `CREATE2` can be used to compute in advance the address where a smart
 * contract will be deployed, which allows for interesting new mechanisms known
 * as 'counterfactual interactions'.
 *
 * See the https://eips.ethereum.org/EIPS/eip-1014#motivation[EIP] for more
 * information.
 */
library Create2Upgradeable {
    /**
     * @dev Deploys a contract using `CREATE2`. The address where the contract
     * will be deployed can be known in advance via {computeAddress}.
     *
     * The bytecode for a contract can be obtained from Solidity with
     * `type(contractName).creationCode`.
     *
     * Requirements:
     *
     * - `bytecode` must not be empty.
     * - `salt` must have not been used for `bytecode` already.
     * - the factory must have a balance of at least `amount`.
     * - if `amount` is non-zero, `bytecode` must have a `payable` constructor.
     */
    function deploy(
        uint256 amount,
        bytes32 salt,
        bytes memory bytecode
    ) internal returns (address addr) {
        require(address(this).balance >= amount, "Create2: insufficient balance");
        require(bytecode.length != 0, "Create2: bytecode length is zero");
        /// @solidity memory-safe-assembly
        assembly {
            addr := create2(amount, add(bytecode, 0x20), mload(bytecode), salt)
        }
        require(addr != address(0), "Create2: Failed on deploy");
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy}. Any change in the
     * `bytecodeHash` or `salt` will result in a new destination address.
     */
    function computeAddress(bytes32 salt, bytes32 bytecodeHash) internal view returns (address) {
        return computeAddress(salt, bytecodeHash, address(this));
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy} from a contract located at
     * `deployer`. If `deployer` is this contract's address, returns the same value as {computeAddress}.
     */
    function computeAddress(
        bytes32 salt,
        bytes32 bytecodeHash,
        address deployer
    ) internal pure returns (address addr) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40) // Get free memory pointer

            // |                   | ↓ ptr ...  ↓ ptr + 0x0B (start) ...  ↓ ptr + 0x20 ...  ↓ ptr + 0x40 ...   |
            // |-------------------|---------------------------------------------------------------------------|
            // | bytecodeHash      |                                                        CCCCCCCCCCCCC...CC |
            // | salt              |                                      BBBBBBBBBBBBB...BB                   |
            // | deployer          | 000000...0000AAAAAAAAAAAAAAAAAAA...AA                                     |
            // | 0xFF              |            FF                                                             |
            // |-------------------|---------------------------------------------------------------------------|
            // | memory            | 000000...00FFAAAAAAAAAAAAAAAAAAA...AABBBBBBBBBBBBB...BBCCCCCCCCCCCCC...CC |
            // | keccak(start, 85) |            ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑ |

            mstore(add(ptr, 0x40), bytecodeHash)
            mstore(add(ptr, 0x20), salt)
            mstore(ptr, deployer) // Right-aligned with 12 preceding garbage bytes
            let start := add(ptr, 0x0b) // The hashed data starts at the final garbage byte which we will set to 0xff
            mstore8(start, 0xff)
            addr := keccak256(start, 85)
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../StringsUpgradeable.sol";

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
        InvalidSignatureV // Deprecated in v4.8
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/EIP712.sol)

pragma solidity ^0.8.0;

import "./ECDSAUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
 *
 * @custom:storage-size 52
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
    function __EIP712_init(string memory name, string memory version) internal onlyInitializing {
        __EIP712_init_unchained(name, version);
    }

    function __EIP712_init_unchained(string memory name, string memory version) internal onlyInitializing {
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

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
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
        return ECDSAUpgradeable.toTypedDataHash(_domainSeparatorV4(), structHash);
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SafeCast.sol)
// This file was procedurally generated from scripts/generate/templates/SafeCast.js.

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCastUpgradeable {
    /**
     * @dev Returns the downcasted uint248 from uint256, reverting on
     * overflow (when the input is greater than largest uint248).
     *
     * Counterpart to Solidity's `uint248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toUint248(uint256 value) internal pure returns (uint248) {
        require(value <= type(uint248).max, "SafeCast: value doesn't fit in 248 bits");
        return uint248(value);
    }

    /**
     * @dev Returns the downcasted uint240 from uint256, reverting on
     * overflow (when the input is greater than largest uint240).
     *
     * Counterpart to Solidity's `uint240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toUint240(uint256 value) internal pure returns (uint240) {
        require(value <= type(uint240).max, "SafeCast: value doesn't fit in 240 bits");
        return uint240(value);
    }

    /**
     * @dev Returns the downcasted uint232 from uint256, reverting on
     * overflow (when the input is greater than largest uint232).
     *
     * Counterpart to Solidity's `uint232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toUint232(uint256 value) internal pure returns (uint232) {
        require(value <= type(uint232).max, "SafeCast: value doesn't fit in 232 bits");
        return uint232(value);
    }

    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.2._
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint216 from uint256, reverting on
     * overflow (when the input is greater than largest uint216).
     *
     * Counterpart to Solidity's `uint216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toUint216(uint256 value) internal pure returns (uint216) {
        require(value <= type(uint216).max, "SafeCast: value doesn't fit in 216 bits");
        return uint216(value);
    }

    /**
     * @dev Returns the downcasted uint208 from uint256, reverting on
     * overflow (when the input is greater than largest uint208).
     *
     * Counterpart to Solidity's `uint208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toUint208(uint256 value) internal pure returns (uint208) {
        require(value <= type(uint208).max, "SafeCast: value doesn't fit in 208 bits");
        return uint208(value);
    }

    /**
     * @dev Returns the downcasted uint200 from uint256, reverting on
     * overflow (when the input is greater than largest uint200).
     *
     * Counterpart to Solidity's `uint200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toUint200(uint256 value) internal pure returns (uint200) {
        require(value <= type(uint200).max, "SafeCast: value doesn't fit in 200 bits");
        return uint200(value);
    }

    /**
     * @dev Returns the downcasted uint192 from uint256, reverting on
     * overflow (when the input is greater than largest uint192).
     *
     * Counterpart to Solidity's `uint192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toUint192(uint256 value) internal pure returns (uint192) {
        require(value <= type(uint192).max, "SafeCast: value doesn't fit in 192 bits");
        return uint192(value);
    }

    /**
     * @dev Returns the downcasted uint184 from uint256, reverting on
     * overflow (when the input is greater than largest uint184).
     *
     * Counterpart to Solidity's `uint184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toUint184(uint256 value) internal pure returns (uint184) {
        require(value <= type(uint184).max, "SafeCast: value doesn't fit in 184 bits");
        return uint184(value);
    }

    /**
     * @dev Returns the downcasted uint176 from uint256, reverting on
     * overflow (when the input is greater than largest uint176).
     *
     * Counterpart to Solidity's `uint176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toUint176(uint256 value) internal pure returns (uint176) {
        require(value <= type(uint176).max, "SafeCast: value doesn't fit in 176 bits");
        return uint176(value);
    }

    /**
     * @dev Returns the downcasted uint168 from uint256, reverting on
     * overflow (when the input is greater than largest uint168).
     *
     * Counterpart to Solidity's `uint168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toUint168(uint256 value) internal pure returns (uint168) {
        require(value <= type(uint168).max, "SafeCast: value doesn't fit in 168 bits");
        return uint168(value);
    }

    /**
     * @dev Returns the downcasted uint160 from uint256, reverting on
     * overflow (when the input is greater than largest uint160).
     *
     * Counterpart to Solidity's `uint160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toUint160(uint256 value) internal pure returns (uint160) {
        require(value <= type(uint160).max, "SafeCast: value doesn't fit in 160 bits");
        return uint160(value);
    }

    /**
     * @dev Returns the downcasted uint152 from uint256, reverting on
     * overflow (when the input is greater than largest uint152).
     *
     * Counterpart to Solidity's `uint152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toUint152(uint256 value) internal pure returns (uint152) {
        require(value <= type(uint152).max, "SafeCast: value doesn't fit in 152 bits");
        return uint152(value);
    }

    /**
     * @dev Returns the downcasted uint144 from uint256, reverting on
     * overflow (when the input is greater than largest uint144).
     *
     * Counterpart to Solidity's `uint144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toUint144(uint256 value) internal pure returns (uint144) {
        require(value <= type(uint144).max, "SafeCast: value doesn't fit in 144 bits");
        return uint144(value);
    }

    /**
     * @dev Returns the downcasted uint136 from uint256, reverting on
     * overflow (when the input is greater than largest uint136).
     *
     * Counterpart to Solidity's `uint136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toUint136(uint256 value) internal pure returns (uint136) {
        require(value <= type(uint136).max, "SafeCast: value doesn't fit in 136 bits");
        return uint136(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v2.5._
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint120 from uint256, reverting on
     * overflow (when the input is greater than largest uint120).
     *
     * Counterpart to Solidity's `uint120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toUint120(uint256 value) internal pure returns (uint120) {
        require(value <= type(uint120).max, "SafeCast: value doesn't fit in 120 bits");
        return uint120(value);
    }

    /**
     * @dev Returns the downcasted uint112 from uint256, reverting on
     * overflow (when the input is greater than largest uint112).
     *
     * Counterpart to Solidity's `uint112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toUint112(uint256 value) internal pure returns (uint112) {
        require(value <= type(uint112).max, "SafeCast: value doesn't fit in 112 bits");
        return uint112(value);
    }

    /**
     * @dev Returns the downcasted uint104 from uint256, reverting on
     * overflow (when the input is greater than largest uint104).
     *
     * Counterpart to Solidity's `uint104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toUint104(uint256 value) internal pure returns (uint104) {
        require(value <= type(uint104).max, "SafeCast: value doesn't fit in 104 bits");
        return uint104(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.2._
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint88 from uint256, reverting on
     * overflow (when the input is greater than largest uint88).
     *
     * Counterpart to Solidity's `uint88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toUint88(uint256 value) internal pure returns (uint88) {
        require(value <= type(uint88).max, "SafeCast: value doesn't fit in 88 bits");
        return uint88(value);
    }

    /**
     * @dev Returns the downcasted uint80 from uint256, reverting on
     * overflow (when the input is greater than largest uint80).
     *
     * Counterpart to Solidity's `uint80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toUint80(uint256 value) internal pure returns (uint80) {
        require(value <= type(uint80).max, "SafeCast: value doesn't fit in 80 bits");
        return uint80(value);
    }

    /**
     * @dev Returns the downcasted uint72 from uint256, reverting on
     * overflow (when the input is greater than largest uint72).
     *
     * Counterpart to Solidity's `uint72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toUint72(uint256 value) internal pure returns (uint72) {
        require(value <= type(uint72).max, "SafeCast: value doesn't fit in 72 bits");
        return uint72(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v2.5._
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint56 from uint256, reverting on
     * overflow (when the input is greater than largest uint56).
     *
     * Counterpart to Solidity's `uint56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toUint56(uint256 value) internal pure returns (uint56) {
        require(value <= type(uint56).max, "SafeCast: value doesn't fit in 56 bits");
        return uint56(value);
    }

    /**
     * @dev Returns the downcasted uint48 from uint256, reverting on
     * overflow (when the input is greater than largest uint48).
     *
     * Counterpart to Solidity's `uint48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toUint48(uint256 value) internal pure returns (uint48) {
        require(value <= type(uint48).max, "SafeCast: value doesn't fit in 48 bits");
        return uint48(value);
    }

    /**
     * @dev Returns the downcasted uint40 from uint256, reverting on
     * overflow (when the input is greater than largest uint40).
     *
     * Counterpart to Solidity's `uint40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toUint40(uint256 value) internal pure returns (uint40) {
        require(value <= type(uint40).max, "SafeCast: value doesn't fit in 40 bits");
        return uint40(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v2.5._
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint24 from uint256, reverting on
     * overflow (when the input is greater than largest uint24).
     *
     * Counterpart to Solidity's `uint24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toUint24(uint256 value) internal pure returns (uint24) {
        require(value <= type(uint24).max, "SafeCast: value doesn't fit in 24 bits");
        return uint24(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v2.5._
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v2.5._
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     *
     * _Available since v3.0._
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int248 from int256, reverting on
     * overflow (when the input is less than smallest int248 or
     * greater than largest int248).
     *
     * Counterpart to Solidity's `int248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toInt248(int256 value) internal pure returns (int248 downcasted) {
        downcasted = int248(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 248 bits");
    }

    /**
     * @dev Returns the downcasted int240 from int256, reverting on
     * overflow (when the input is less than smallest int240 or
     * greater than largest int240).
     *
     * Counterpart to Solidity's `int240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toInt240(int256 value) internal pure returns (int240 downcasted) {
        downcasted = int240(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 240 bits");
    }

    /**
     * @dev Returns the downcasted int232 from int256, reverting on
     * overflow (when the input is less than smallest int232 or
     * greater than largest int232).
     *
     * Counterpart to Solidity's `int232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toInt232(int256 value) internal pure returns (int232 downcasted) {
        downcasted = int232(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 232 bits");
    }

    /**
     * @dev Returns the downcasted int224 from int256, reverting on
     * overflow (when the input is less than smallest int224 or
     * greater than largest int224).
     *
     * Counterpart to Solidity's `int224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.7._
     */
    function toInt224(int256 value) internal pure returns (int224 downcasted) {
        downcasted = int224(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 224 bits");
    }

    /**
     * @dev Returns the downcasted int216 from int256, reverting on
     * overflow (when the input is less than smallest int216 or
     * greater than largest int216).
     *
     * Counterpart to Solidity's `int216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toInt216(int256 value) internal pure returns (int216 downcasted) {
        downcasted = int216(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 216 bits");
    }

    /**
     * @dev Returns the downcasted int208 from int256, reverting on
     * overflow (when the input is less than smallest int208 or
     * greater than largest int208).
     *
     * Counterpart to Solidity's `int208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toInt208(int256 value) internal pure returns (int208 downcasted) {
        downcasted = int208(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 208 bits");
    }

    /**
     * @dev Returns the downcasted int200 from int256, reverting on
     * overflow (when the input is less than smallest int200 or
     * greater than largest int200).
     *
     * Counterpart to Solidity's `int200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toInt200(int256 value) internal pure returns (int200 downcasted) {
        downcasted = int200(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 200 bits");
    }

    /**
     * @dev Returns the downcasted int192 from int256, reverting on
     * overflow (when the input is less than smallest int192 or
     * greater than largest int192).
     *
     * Counterpart to Solidity's `int192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toInt192(int256 value) internal pure returns (int192 downcasted) {
        downcasted = int192(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 192 bits");
    }

    /**
     * @dev Returns the downcasted int184 from int256, reverting on
     * overflow (when the input is less than smallest int184 or
     * greater than largest int184).
     *
     * Counterpart to Solidity's `int184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toInt184(int256 value) internal pure returns (int184 downcasted) {
        downcasted = int184(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 184 bits");
    }

    /**
     * @dev Returns the downcasted int176 from int256, reverting on
     * overflow (when the input is less than smallest int176 or
     * greater than largest int176).
     *
     * Counterpart to Solidity's `int176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toInt176(int256 value) internal pure returns (int176 downcasted) {
        downcasted = int176(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 176 bits");
    }

    /**
     * @dev Returns the downcasted int168 from int256, reverting on
     * overflow (when the input is less than smallest int168 or
     * greater than largest int168).
     *
     * Counterpart to Solidity's `int168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toInt168(int256 value) internal pure returns (int168 downcasted) {
        downcasted = int168(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 168 bits");
    }

    /**
     * @dev Returns the downcasted int160 from int256, reverting on
     * overflow (when the input is less than smallest int160 or
     * greater than largest int160).
     *
     * Counterpart to Solidity's `int160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toInt160(int256 value) internal pure returns (int160 downcasted) {
        downcasted = int160(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 160 bits");
    }

    /**
     * @dev Returns the downcasted int152 from int256, reverting on
     * overflow (when the input is less than smallest int152 or
     * greater than largest int152).
     *
     * Counterpart to Solidity's `int152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toInt152(int256 value) internal pure returns (int152 downcasted) {
        downcasted = int152(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 152 bits");
    }

    /**
     * @dev Returns the downcasted int144 from int256, reverting on
     * overflow (when the input is less than smallest int144 or
     * greater than largest int144).
     *
     * Counterpart to Solidity's `int144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toInt144(int256 value) internal pure returns (int144 downcasted) {
        downcasted = int144(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 144 bits");
    }

    /**
     * @dev Returns the downcasted int136 from int256, reverting on
     * overflow (when the input is less than smallest int136 or
     * greater than largest int136).
     *
     * Counterpart to Solidity's `int136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toInt136(int256 value) internal pure returns (int136 downcasted) {
        downcasted = int136(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 136 bits");
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128 downcasted) {
        downcasted = int128(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 128 bits");
    }

    /**
     * @dev Returns the downcasted int120 from int256, reverting on
     * overflow (when the input is less than smallest int120 or
     * greater than largest int120).
     *
     * Counterpart to Solidity's `int120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toInt120(int256 value) internal pure returns (int120 downcasted) {
        downcasted = int120(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 120 bits");
    }

    /**
     * @dev Returns the downcasted int112 from int256, reverting on
     * overflow (when the input is less than smallest int112 or
     * greater than largest int112).
     *
     * Counterpart to Solidity's `int112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toInt112(int256 value) internal pure returns (int112 downcasted) {
        downcasted = int112(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 112 bits");
    }

    /**
     * @dev Returns the downcasted int104 from int256, reverting on
     * overflow (when the input is less than smallest int104 or
     * greater than largest int104).
     *
     * Counterpart to Solidity's `int104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toInt104(int256 value) internal pure returns (int104 downcasted) {
        downcasted = int104(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 104 bits");
    }

    /**
     * @dev Returns the downcasted int96 from int256, reverting on
     * overflow (when the input is less than smallest int96 or
     * greater than largest int96).
     *
     * Counterpart to Solidity's `int96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.7._
     */
    function toInt96(int256 value) internal pure returns (int96 downcasted) {
        downcasted = int96(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 96 bits");
    }

    /**
     * @dev Returns the downcasted int88 from int256, reverting on
     * overflow (when the input is less than smallest int88 or
     * greater than largest int88).
     *
     * Counterpart to Solidity's `int88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toInt88(int256 value) internal pure returns (int88 downcasted) {
        downcasted = int88(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 88 bits");
    }

    /**
     * @dev Returns the downcasted int80 from int256, reverting on
     * overflow (when the input is less than smallest int80 or
     * greater than largest int80).
     *
     * Counterpart to Solidity's `int80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toInt80(int256 value) internal pure returns (int80 downcasted) {
        downcasted = int80(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 80 bits");
    }

    /**
     * @dev Returns the downcasted int72 from int256, reverting on
     * overflow (when the input is less than smallest int72 or
     * greater than largest int72).
     *
     * Counterpart to Solidity's `int72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toInt72(int256 value) internal pure returns (int72 downcasted) {
        downcasted = int72(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 72 bits");
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64 downcasted) {
        downcasted = int64(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 64 bits");
    }

    /**
     * @dev Returns the downcasted int56 from int256, reverting on
     * overflow (when the input is less than smallest int56 or
     * greater than largest int56).
     *
     * Counterpart to Solidity's `int56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toInt56(int256 value) internal pure returns (int56 downcasted) {
        downcasted = int56(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 56 bits");
    }

    /**
     * @dev Returns the downcasted int48 from int256, reverting on
     * overflow (when the input is less than smallest int48 or
     * greater than largest int48).
     *
     * Counterpart to Solidity's `int48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toInt48(int256 value) internal pure returns (int48 downcasted) {
        downcasted = int48(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 48 bits");
    }

    /**
     * @dev Returns the downcasted int40 from int256, reverting on
     * overflow (when the input is less than smallest int40 or
     * greater than largest int40).
     *
     * Counterpart to Solidity's `int40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toInt40(int256 value) internal pure returns (int40 downcasted) {
        downcasted = int40(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 40 bits");
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32 downcasted) {
        downcasted = int32(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 32 bits");
    }

    /**
     * @dev Returns the downcasted int24 from int256, reverting on
     * overflow (when the input is less than smallest int24 or
     * greater than largest int24).
     *
     * Counterpart to Solidity's `int24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toInt24(int256 value) internal pure returns (int24 downcasted) {
        downcasted = int24(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 24 bits");
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16 downcasted) {
        downcasted = int16(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 16 bits");
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8 downcasted) {
        downcasted = int8(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 8 bits");
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     *
     * _Available since v3.0._
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/MathUpgradeable.sol";

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = MathUpgradeable.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, MathUpgradeable.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
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
// OpenZeppelin Contracts (last updated v4.6.0) (utils/structs/DoubleEndedQueue.sol)
pragma solidity ^0.8.4;

import "../math/SafeCastUpgradeable.sol";

/**
 * @dev A sequence of items with the ability to efficiently push and pop items (i.e. insert and remove) on both ends of
 * the sequence (called front and back). Among other access patterns, it can be used to implement efficient LIFO and
 * FIFO queues. Storage use is optimized, and all operations are O(1) constant time. This includes {clear}, given that
 * the existing queue contents are left in storage.
 *
 * The struct is called `Bytes32Deque`. Other types can be cast to and from `bytes32`. This data structure can only be
 * used in storage, and not in memory.
 * ```
 * DoubleEndedQueue.Bytes32Deque queue;
 * ```
 *
 * _Available since v4.6._
 */
library DoubleEndedQueueUpgradeable {
    /**
     * @dev An operation (e.g. {front}) couldn't be completed due to the queue being empty.
     */
    error Empty();

    /**
     * @dev An operation (e.g. {at}) couldn't be completed due to an index being out of bounds.
     */
    error OutOfBounds();

    /**
     * @dev Indices are signed integers because the queue can grow in any direction. They are 128 bits so begin and end
     * are packed in a single storage slot for efficient access. Since the items are added one at a time we can safely
     * assume that these 128-bit indices will not overflow, and use unchecked arithmetic.
     *
     * Struct members have an underscore prefix indicating that they are "private" and should not be read or written to
     * directly. Use the functions provided below instead. Modifying the struct manually may violate assumptions and
     * lead to unexpected behavior.
     *
     * Indices are in the range [begin, end) which means the first item is at data[begin] and the last item is at
     * data[end - 1].
     */
    struct Bytes32Deque {
        int128 _begin;
        int128 _end;
        mapping(int128 => bytes32) _data;
    }

    /**
     * @dev Inserts an item at the end of the queue.
     */
    function pushBack(Bytes32Deque storage deque, bytes32 value) internal {
        int128 backIndex = deque._end;
        deque._data[backIndex] = value;
        unchecked {
            deque._end = backIndex + 1;
        }
    }

    /**
     * @dev Removes the item at the end of the queue and returns it.
     *
     * Reverts with `Empty` if the queue is empty.
     */
    function popBack(Bytes32Deque storage deque) internal returns (bytes32 value) {
        if (empty(deque)) revert Empty();
        int128 backIndex;
        unchecked {
            backIndex = deque._end - 1;
        }
        value = deque._data[backIndex];
        delete deque._data[backIndex];
        deque._end = backIndex;
    }

    /**
     * @dev Inserts an item at the beginning of the queue.
     */
    function pushFront(Bytes32Deque storage deque, bytes32 value) internal {
        int128 frontIndex;
        unchecked {
            frontIndex = deque._begin - 1;
        }
        deque._data[frontIndex] = value;
        deque._begin = frontIndex;
    }

    /**
     * @dev Removes the item at the beginning of the queue and returns it.
     *
     * Reverts with `Empty` if the queue is empty.
     */
    function popFront(Bytes32Deque storage deque) internal returns (bytes32 value) {
        if (empty(deque)) revert Empty();
        int128 frontIndex = deque._begin;
        value = deque._data[frontIndex];
        delete deque._data[frontIndex];
        unchecked {
            deque._begin = frontIndex + 1;
        }
    }

    /**
     * @dev Returns the item at the beginning of the queue.
     *
     * Reverts with `Empty` if the queue is empty.
     */
    function front(Bytes32Deque storage deque) internal view returns (bytes32 value) {
        if (empty(deque)) revert Empty();
        int128 frontIndex = deque._begin;
        return deque._data[frontIndex];
    }

    /**
     * @dev Returns the item at the end of the queue.
     *
     * Reverts with `Empty` if the queue is empty.
     */
    function back(Bytes32Deque storage deque) internal view returns (bytes32 value) {
        if (empty(deque)) revert Empty();
        int128 backIndex;
        unchecked {
            backIndex = deque._end - 1;
        }
        return deque._data[backIndex];
    }

    /**
     * @dev Return the item at a position in the queue given by `index`, with the first item at 0 and last item at
     * `length(deque) - 1`.
     *
     * Reverts with `OutOfBounds` if the index is out of bounds.
     */
    function at(Bytes32Deque storage deque, uint256 index) internal view returns (bytes32 value) {
        // int256(deque._begin) is a safe upcast
        int128 idx = SafeCastUpgradeable.toInt128(int256(deque._begin) + SafeCastUpgradeable.toInt256(index));
        if (idx >= deque._end) revert OutOfBounds();
        return deque._data[idx];
    }

    /**
     * @dev Resets the queue back to being empty.
     *
     * NOTE: The current items are left behind in storage. This does not affect the functioning of the queue, but misses
     * out on potential gas refunds.
     */
    function clear(Bytes32Deque storage deque) internal {
        deque._begin = 0;
        deque._end = 0;
    }

    /**
     * @dev Returns the number of items in the queue.
     */
    function length(Bytes32Deque storage deque) internal view returns (uint256) {
        // The interface preserves the invariant that begin <= end so we assume this will not overflow.
        // We also assume there are at most int256.max items in the queue.
        unchecked {
            return uint256(int256(deque._end) - int256(deque._begin));
        }
    }

    /**
     * @dev Returns true if the queue is empty.
     */
    function empty(Bytes32Deque storage deque) internal view returns (bool) {
        return deque._end <= deque._begin;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Timers.sol)

pragma solidity ^0.8.0;

/**
 * @dev Tooling for timepoints, timers and delays
 */
library TimersUpgradeable {
    struct Timestamp {
        uint64 _deadline;
    }

    function getDeadline(Timestamp memory timer) internal pure returns (uint64) {
        return timer._deadline;
    }

    function setDeadline(Timestamp storage timer, uint64 timestamp) internal {
        timer._deadline = timestamp;
    }

    function reset(Timestamp storage timer) internal {
        timer._deadline = 0;
    }

    function isUnset(Timestamp memory timer) internal pure returns (bool) {
        return timer._deadline == 0;
    }

    function isStarted(Timestamp memory timer) internal pure returns (bool) {
        return timer._deadline > 0;
    }

    function isPending(Timestamp memory timer) internal view returns (bool) {
        return timer._deadline > block.timestamp;
    }

    function isExpired(Timestamp memory timer) internal view returns (bool) {
        return isStarted(timer) && timer._deadline <= block.timestamp;
    }

    struct BlockNumber {
        uint64 _deadline;
    }

    function getDeadline(BlockNumber memory timer) internal pure returns (uint64) {
        return timer._deadline;
    }

    function setDeadline(BlockNumber storage timer, uint64 timestamp) internal {
        timer._deadline = timestamp;
    }

    function reset(BlockNumber storage timer) internal {
        timer._deadline = 0;
    }

    function isUnset(BlockNumber memory timer) internal pure returns (bool) {
        return timer._deadline == 0;
    }

    function isStarted(BlockNumber memory timer) internal pure returns (bool) {
        return timer._deadline > 0;
    }

    function isPending(BlockNumber memory timer) internal view returns (bool) {
        return timer._deadline > block.number;
    }

    function isExpired(BlockNumber memory timer) internal view returns (bool) {
        return isStarted(timer) && timer._deadline <= block.number;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822Proxiable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeacon {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/ERC1967/ERC1967Proxy.sol)

pragma solidity ^0.8.0;

import "../Proxy.sol";
import "./ERC1967Upgrade.sol";

/**
 * @dev This contract implements an upgradeable proxy. It is upgradeable because calls are delegated to an
 * implementation address that can be changed. This address is stored in storage in the location specified by
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967], so that it doesn't conflict with the storage layout of the
 * implementation behind the proxy.
 */
contract ERC1967Proxy is Proxy, ERC1967Upgrade {
    /**
     * @dev Initializes the upgradeable proxy with an initial implementation specified by `_logic`.
     *
     * If `_data` is nonempty, it's used as data in a delegate call to `_logic`. This will typically be an encoded
     * function call, and allows initializing the storage of the proxy like a Solidity constructor.
     */
    constructor(address _logic, bytes memory _data) payable {
        _upgradeToAndCall(_logic, _data, false);
    }

    /**
     * @dev Returns the current implementation address.
     */
    function _implementation() internal view virtual override returns (address impl) {
        return ERC1967Upgrade._getImplementation();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeacon.sol";
import "../../interfaces/draft-IERC1822.sol";
import "../../utils/Address.sol";
import "../../utils/StorageSlot.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967Upgrade {
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlot.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822Proxiable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlot.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlot.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlot.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(Address.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            Address.isContract(IBeacon(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlot.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(IBeacon(newBeacon).implementation(), data);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/Proxy.sol)

pragma solidity ^0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @dev This is a virtual function that should be overridden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive() external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overridden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
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