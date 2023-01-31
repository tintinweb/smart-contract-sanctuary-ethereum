// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
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

pragma solidity 0.8.13;

import "@openzeppelin/contracts-4.5.0/access/Ownable.sol";
import "./MessageBusSender.sol";
import "./MessageBusReceiver.sol";

contract MessageBus is MessageBusSender, MessageBusReceiver {
    constructor(address _gasFeePricing, address _authVerifier)
        MessageBusSender(_gasFeePricing)
        MessageBusReceiver(_authVerifier)
    {}
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "@openzeppelin/contracts-4.5.0/access/Ownable.sol";
import "./interfaces/IAuthVerifier.sol";
import "./interfaces/ISynMessagingReceiver.sol";

contract MessageBusReceiver is Ownable {
    address public authVerifier;

    enum TxStatus {
        Null,
        Success,
        Fail
    }

    // Store all successfully executed messages
    mapping(bytes32 => TxStatus) executedMessages;

    // TODO: Rename to follow one standard convention -> Send -> Receive?
    event Executed(
        bytes32 indexed messageId,
        TxStatus status,
        address indexed _dstAddress,
        uint64 srcChainId,
        uint64 srcNonce
    );
    event CallReverted(string reason);

    constructor(address _authVerifier) {
        authVerifier = _authVerifier;
    }

    function getExecutedMessage(bytes32 _messageId)
        external
        view
        returns (TxStatus)
    {
        return executedMessages[_messageId];
    }

    /**
     * @notice Relayer executes messages through an authenticated method to the destination receiver
     based on the originating transaction on source chain
     * @param _srcChainId Originating chain ID - typically a standard EVM chain ID, but may refer to a Synapse-specific chain ID on nonEVM chains
     * @param _srcAddress Originating bytes32 address of the message sender on the srcChain
     * @param _dstAddress Destination address that the arbitrary message will be passed to
     * @param _gasLimit Gas limit to be passed alongside the message, depending on the fee paid on srcChain
     * @param _message Arbitrary message payload to pass to the destination chain receiver
     */
    function executeMessage(
        uint256 _srcChainId,
        bytes32 _srcAddress,
        address _dstAddress,
        uint256 _gasLimit,
        uint256 _nonce,
        bytes calldata _message,
        bytes32 _messageId
    ) external {
        // In order to guarentee that an individual message is only executed once, a messageId is passed
        // enforce that this message ID hasn't already been tried ever
        bytes32 messageId = _messageId;
        require(
            executedMessages[messageId] == TxStatus.Null,
            "Message already executed"
        );
        // Authenticate executeMessage, will revert if not authenticated
        IAuthVerifier(authVerifier).msgAuth(abi.encode(msg.sender));
        // Message is now in-flight, adjust status
        // executedMessages[messageId] = TxStatus.Pending;

        TxStatus status;
        try
            ISynMessagingReceiver(_dstAddress).executeMessage{gas: _gasLimit}(
                _srcAddress,
                _srcChainId,
                _message,
                msg.sender
            )
        {
            // Assuming success state if no revert
            status = TxStatus.Success;
        } catch (bytes memory reason) {
            // call hard reverted & failed
            emit CallReverted(getRevertMsg(reason));
            status = TxStatus.Fail;
        }

        executedMessages[messageId] = status;
        emit Executed(
            messageId,
            status,
            _dstAddress,
            uint64(_srcChainId),
            uint64(_nonce)
        );
    }

    /** HELPER VIEW FUNCTION */
    // https://ethereum.stackexchange.com/a/83577
    // https://github.com/Uniswap/v3-periphery/blob/v1.0.0/contracts/base/Multicall.sol
    function getRevertMsg(bytes memory _returnData)
        private
        pure
        returns (string memory)
    {
        // If the _res length is less than 68, then the transaction failed silently (without a revert message)
        if (_returnData.length < 68) return "Transaction reverted silently";
        assembly {
            // Slice the sighash.
            _returnData := add(_returnData, 0x04)
        }
        return abi.decode(_returnData, (string)); // All that remains is the revert string
    }

    /** CONTRACT CONFIG */

    function updateMessageStatus(bytes32 _messageId, TxStatus _status)
        public
        onlyOwner
    {
        executedMessages[_messageId] = _status;
    }

    function updateAuthVerifier(address _authVerifier) public onlyOwner {
        require(_authVerifier != address(0), "Cannot set to 0");
        authVerifier = _authVerifier;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "@openzeppelin/contracts-4.5.0/access/Ownable.sol";
import "./interfaces/IGasFeePricing.sol";

contract MessageBusSender is Ownable {
    address public gasFeePricing;
    uint64 public nonce;
    uint256 internal fees;

    constructor(address _gasFeePricing) {
        gasFeePricing = _gasFeePricing;
    }

    event MessageSent(
        address indexed sender,
        uint256 srcChainID,
        bytes32 receiver,
        uint256 indexed dstChainId,
        bytes message,
        uint64 nonce,
        bytes options,
        uint256 fee,
        bytes32 indexed messageId
    );

    function computeMessageIdSender(
        uint256 _srcChainId,
        address _srcAddress,
        uint256 _dstChainId,
        bytes32 _dstAddress,
        uint256 _nonce,
        bytes calldata _message
    ) public view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    _srcChainId,
                    _srcAddress,
                    _dstChainId,
                    _dstAddress,
                    _nonce,
                    _message
                )
            );
    }

    function estimateFee(uint256 _dstChainId, bytes calldata _options)
        public
        returns (uint256)
    {
        uint256 fee = IGasFeePricing(gasFeePricing).estimateGasFee(
            _dstChainId,
            _options
        );
        require(fee != 0, "Fee not set");
        return fee;
    }

    /**
     * @notice Sends a message to a receiving contract address on another chain.
     * Sender must make sure that the message is unique and not a duplicate message.
     * @param _receiver The bytes32 address of the destination contract to be called
     * @param _dstChainId The destination chain ID - typically, standard EVM chain ID, but differs on nonEVM chains
     * @param _message The arbitrary payload to pass to the destination chain receiver
     * @param _options Versioned struct used to instruct relayer on how to proceed with gas limits
     */
    function sendMessage(
        bytes32 _receiver,
        uint256 _dstChainId,
        bytes calldata _message,
        bytes calldata _options
    ) external payable {
        require(_dstChainId != block.chainid, "Invalid chainId");
        uint256 fee = estimateFee(_dstChainId, _options);
        require(msg.value >= fee, "Insuffient gas fee");
        bytes32 msgId = computeMessageIdSender(block.chainid, msg.sender,  _dstChainId, _receiver, nonce, _message);
        emit MessageSent(
            msg.sender,
            block.chainid,
            _receiver,
            _dstChainId,
            _message,
            nonce,
            _options,
            msg.value,
            msgId
        );
        fees += msg.value;
        ++nonce;
    }

    /**
     * @notice Withdraws accumulated fees in native gas token, based on fees variable.
     * @param to Address to withdraw gas fees to, which can be specified in the event owner() can't receive native gas
     */
    function withdrawGasFees(address payable to) external onlyOwner {
        uint256 withdrawAmount = fees;
        // Reset fees to 0
        to.transfer(withdrawAmount);
        delete fees;
    }

    function updateGasFeePricing(address _gasFeePricing) public onlyOwner {
        require(_gasFeePricing != address(0), "Cannot set to 0");
        gasFeePricing = _gasFeePricing;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

interface IAuthVerifier {
    /**
     * @notice Authentication library to allow the validator network to execute cross-chain messages.
     * @param _authData A bytes32 address encoded via abi.encode(address)
     * @return authenticated returns true if bytes data submitted and decoded to the address is correct
     */
    function msgAuth(bytes calldata _authData)
        external
        view
        returns (bool authenticated);

    /**
     * @notice Permissioned method to support upgrades to the library
     * @param _nodegroup address which has authentication to execute messages
     */
    function setNodeGroup(address _nodegroup) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

interface IGasFeePricing {
    
    /**
     * @notice Permissioned method to allow an off-chain party to set what each dstChain's
     * gas cost is priced in the srcChain's native gas currency. 
     * Example: call on ETH, setCostPerChain(43114, 30000000000, 25180000000000000)
     * chain ID 43114
     * Average of 30 gwei cost to transaction on 43114
     * AVAX/ETH = 0.02518, scaled to gas in wei = 25180000000000000
     * @param _dstChainId The destination chain ID - typically, standard EVM chain ID, but differs on nonEVM chains
     * @param _gasUnitPrice The estimated current gas price in wei of the destination chain
     * @param _gasTokenPriceRatio Gas ratio of dstGasToken / srcGasToken
     */
    function setCostPerChain(uint256 _dstChainId, uint256 _gasUnitPrice, uint256 _gasTokenPriceRatio) external;

    /**
     * @notice Returns srcGasToken fee to charge in wei for the cross-chain message based on the gas limit
     * @param _options Versioned struct used to instruct relayer on how to proceed with gas limits. Contains data on gas limit to submit tx with.
     */
    function estimateGasFee(uint256 _dstChainId, bytes calldata _options) external returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

interface ISynMessagingReceiver {

    // Maps chain ID to the bytes32 trusted addresses allowed to be source senders
    // mapping(uint256 => bytes32) internal trustedRemoteLookup;


    /** 
     * @notice MsgExecutionStatus state
     * @return Success execution succeeded, finalized
     * @return Fail // execution failed, finalized
     * @return Retry // execution failed or rejected, set to be retryable
    */ 
    enum MsgExecutionStatus {
        Success, 
        Fail
    }

     /**
     * @notice Called by MessageBus 
     * @dev MUST be permissioned to trusted source apps via trustedRemote
     * @param _srcAddress The bytes32 address of the source app contract
     * @param _srcChainId The source chain ID where the transfer is originated from
     * @param _message Arbitrary message bytes originated from and encoded by the source app contract
     * @param _executor Address who called the MessageBus execution function
     */
    function executeMessage(
        bytes32 _srcAddress,
        uint256 _srcChainId,
        bytes calldata _message,
        address _executor
    ) external returns (MsgExecutionStatus);
}