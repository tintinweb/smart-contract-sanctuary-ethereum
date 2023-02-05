// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.17;

import "../interfaces/IBridgeSenderAdapter.sol";
import "../interfaces/Router/IRouterGateway.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract RouterSenderAdapter is IBridgeSenderAdapter, Ownable {
    /* ========== STATE VARIABLES ========== */

    string public constant name = "router";
    address public multiBridgeSender;
    IRouterGateway public immutable routerGateway;
    // dstChainId => receiverAdapter address
    mapping(uint64 => address) public receiverAdapters;

    /* ========== MODIFIERS ========== */

    modifier onlyMultiBridgeSender() {
        require(msg.sender == multiBridgeSender, "not multi-bridge msg sender");
        _;
    }

    /* ========== CONSTRUCTOR  ========== */

    constructor(address _routerGateway) {
        routerGateway = IRouterGateway(_routerGateway);
    }

    /* ========== EXTERNAL METHODS ========== */

    function getMessageFee(
        MessageStruct.Message memory //_message
    ) external view override returns (uint256) {
        return routerGateway.requestToDestDefaultFee();
    }

    function sendMessage(MessageStruct.Message memory _message) external payable override onlyMultiBridgeSender {
        _message.bridgeName = name;
        require(receiverAdapters[_message.dstChainId] != address(0), "no receiver adapter");

        Utils.DestinationChainParams memory destChainParams = Utils.DestinationChainParams(
            1000000,
            0,
            0,
            Strings.toString(uint256(_message.dstChainId))
        );

        bytes[] memory payloads = new bytes[](1);
        payloads[0] = abi.encode(_message);

        bytes[] memory destContractAddresses = new bytes[](1);
        destContractAddresses[0] = toBytes(receiverAdapters[_message.dstChainId]);

        routerGateway.requestToDest{value: msg.value}(
            type(uint64).max,
            false,
            Utils.AckType.NO_ACK,
            Utils.AckGasParams(0, 0),
            destChainParams,
            Utils.ContractCalls(payloads, destContractAddresses)
        );
    }

    /* ========== ADMIN METHODS ========== */

    function updateReceiverAdapter(uint64[] calldata _dstChainIds, address[] calldata _receiverAdapters)
        external
        onlyOwner
    {
        require(_dstChainIds.length == _receiverAdapters.length, "mismatch length");
        for (uint256 i = 0; i < _dstChainIds.length; i++) {
            receiverAdapters[_dstChainIds[i]] = _receiverAdapters[i];
        }
    }

    function setMultiBridgeSender(address _multiBridgeSender) external onlyOwner {
        multiBridgeSender = _multiBridgeSender;
    }

    /* ========== UTILS METHODS ========== */

    function toBytes(address a) public pure returns (bytes memory b) {
        assembly {
            let m := mload(0x40)
            a := and(a, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
            mstore(add(m, 20), xor(0x140000000000000000000000000000000000000000, a))
            mstore(0x40, add(m, 52))
            b := m
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.8.9;

import "../MessageStruct.sol";

/**
 * @dev Adapter that connects MultiBridgeSender and each message bridge.
 * Message bridge can implement their favourite encode&decode way for MessageStruct.Message.
 */
interface IBridgeSenderAdapter {
    /**
     * @dev Return native token amount in wei required by this message bridge for sending a MessageStruct.Message.
     */
    function getMessageFee(MessageStruct.Message memory _message) external view returns (uint256);

    /**
     * @dev Send a MessageStruct.Message through this message bridge.
     */
    function sendMessage(MessageStruct.Message memory _message) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

library Utils {
    struct AckGasParams {
        uint64 gasLimit;
        uint64 gasPrice;
    }

    struct DestinationChainParams {
        uint64 gasLimit;
        uint64 gasPrice;
        uint64 destChainType;
        string destChainId;
    }

    struct ContractCalls {
        bytes[] payloads;
        bytes[] destContractAddresses;
    }

    enum AckType {
        NO_ACK,
        ACK_ON_SUCCESS,
        ACK_ON_ERROR,
        ACK_ON_BOTH
    }
}

interface IRouterGateway {
    /// @notice Function to send a message to the destination chain
    /// @param expTimestamp the timestamp when the request ceases to be valid. If this timestamp has
    /// passed by, the request will fail on the destination chain.
    /// @param isAtomicCalls boolean value suggesting whether the calls are atomic. If true, either all the
    /// calls will be executed or none will be executed on the destination chain. If false, even if some calls
    /// fail, others will not be affected.
    /// @param ackType type of acknowledgement you want: ACK_ON_SUCCESS, ACK_ON_ERR, ACK_ON_BOTH.
    /// @param ackGasParams This includes the gas limit required for the execution of handler function for
    /// crosstalk acknowledgement on the source chain and the gas price of the source chain.
    /// @param destChainParams dest chain params include the destChainType, destChainId, the gas limit
    /// required to execute handler function on the destination chain and the gas price of destination chain.
    /// @param contractCalls Array of struct ContractCalls containing the multiple payloads to be sent to multiple
    /// contract addresses (in bytes format) on the destination chain.
    /// @return Returns the nonce from the gateway contract.
    function requestToDest(
        uint64 expTimestamp,
        bool isAtomicCalls,
        Utils.AckType ackType,
        Utils.AckGasParams memory ackGasParams,
        Utils.DestinationChainParams memory destChainParams,
        Utils.ContractCalls memory contractCalls
    ) external payable returns (uint64);

    /// @notice Function to fetch the fees for cross-chain message transfer.
    /// @return fees
    function requestToDestDefaultFee() external view returns (uint256 fees);
}

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

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.8.9;

library MessageStruct {
    /**
     * @dev Message indicates a remote call to target contract on destination chain.
     *
     * @param srcChainId is the id of chain where this message is sent from.
     * @param dstChainId is the id of chain where this message is sent to.
     * @param nonce is an incrementing number held by MultiBridgeSender to ensure msgId uniqueness
     * @param target is the contract to be called on dst chain.
     * @param callData is the data to be sent to target by low-level call(eg. address(target).call(callData)).
     * @param bridgeName is the message bridge name used for sending this message.
     */
    struct Message {
        uint64 srcChainId;
        uint64 dstChainId;
        uint32 nonce;
        address target;
        bytes callData;
        string bridgeName;
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