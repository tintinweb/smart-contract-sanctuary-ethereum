// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/optimism/messengers/iOVM_L1CrossDomainMessenger.sol";
import "./MessengerWrapper.sol";

/**
 * @dev A MessengerWrapper for Optimism - https://community.optimism.io/docs/
 * @notice Deployed on layer-1
 */

contract OptimismMessengerWrapper is MessengerWrapper, Ownable {

    iOVM_L1CrossDomainMessenger public immutable l1MessengerAddress;
    address public immutable l2BridgeAddress;
    uint256 public defaultL2GasLimit;
    mapping (bytes4 => uint256) public l2GasLimitForSignature;

    constructor(
        address _l1BridgeAddress,
        address _l2BridgeAddress,
        iOVM_L1CrossDomainMessenger _l1MessengerAddress,
        uint256 _l2ChainId,
        uint256 _defaultL2GasLimit
    )
        public
        MessengerWrapper(_l1BridgeAddress, _l2ChainId)
    {
        l2BridgeAddress = _l2BridgeAddress;
        l1MessengerAddress = _l1MessengerAddress;
        defaultL2GasLimit = _defaultL2GasLimit;
    }

    /** 
     * @dev Sends a message to the l2BridgeAddress from layer-1
     * @param _calldata The data that l2BridgeAddress will be called with
     */
    function sendCrossDomainMessage(bytes memory _calldata) public override onlyL1Bridge {
        uint256 l2GasLimit = l2GasLimitForCalldata(_calldata);

        l1MessengerAddress.sendMessage(
            l2BridgeAddress,
            _calldata,
            uint32(l2GasLimit)
        );
    }

    function verifySender(address l1BridgeCaller, bytes memory /*_data*/) public override {
        if (isRootConfirmation) return;

        require(l1BridgeCaller == address(l1MessengerAddress), "OVM_MSG_WPR: Caller is not l1MessengerAddress");
        // Verify that cross-domain sender is l2BridgeAddress
        require(l1MessengerAddress.xDomainMessageSender() == l2BridgeAddress, "OVM_MSG_WPR: Invalid cross-domain sender");
    }

    function setDefaultL2GasLimit(uint256 _l2GasLimit) external onlyOwner {
        defaultL2GasLimit = _l2GasLimit;
    }

    function setL2GasLimitForSignature(uint256 _l2GasLimit, bytes4 signature) external onlyOwner {
        l2GasLimitForSignature[signature] = _l2GasLimit;
    }

    // Private functions

    function l2GasLimitForCalldata(bytes memory _calldata) private view returns (uint256) {
        uint256 l2GasLimit;

        if (_calldata.length >= 4) {
            bytes4 functionSignature = bytes4(toUint32(_calldata, 0));
            l2GasLimit = l2GasLimitForSignature[functionSignature];
        }

        if (l2GasLimit == 0) {
            l2GasLimit = defaultL2GasLimit;
        }

        return l2GasLimit;
    }

    // source: https://github.com/GNSPS/solidity-bytes-utils/blob/master/contracts/BytesLib.sol
    function toUint32(bytes memory _bytes, uint256 _start) private pure returns (uint32) {
        require(_bytes.length >= _start + 4, "OVM_MSG_WPR: out of bounds");
        uint32 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x4), _start))
        }

        return tempUint;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
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
}

// SPDX-License-Identifier: MIT
pragma solidity >0.5.0 <0.8.0;
pragma experimental ABIEncoderV2;

import { iOVM_BaseCrossDomainMessenger } from "./iOVM_BaseCrossDomainMessenger.sol";

/**
 * @title iOVM_L1CrossDomainMessenger
 */
interface iOVM_L1CrossDomainMessenger is iOVM_BaseCrossDomainMessenger {}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12 <=0.8.9;
pragma experimental ABIEncoderV2;

import "../interfaces/IMessengerWrapper.sol";

contract IL1Bridge {
    struct TransferBond {
        address bonder;
        uint256 createdAt;
        uint256 totalAmount;
        uint256 challengeStartTime;
        address challenger;
        bool challengeResolved;
    }
    uint256 public challengePeriod;
    mapping(bytes32 => TransferBond) public transferBonds;
    function getIsBonder(address maybeBonder) public view returns (bool) {}
    function getTransferRootId(bytes32 rootHash, uint256 totalAmount) public pure returns (bytes32) {}
    function confirmTransferRoot(
        uint256 originChainId,
        bytes32 rootHash,
        uint256 destinationChainId,
        uint256 totalAmount,
        uint256 rootCommittedAt
    )
        external
    {}
}

abstract contract MessengerWrapper is IMessengerWrapper {
    address public immutable l1BridgeAddress;
    uint256 public immutable l2ChainId;
    bool public isRootConfirmation = false;

    constructor(address _l1BridgeAddress, uint256 _l2ChainId) internal {
        l1BridgeAddress = _l1BridgeAddress;
        l2ChainId = _l2ChainId;
    }

    modifier onlyL1Bridge {
        require(msg.sender == l1BridgeAddress, "MW: Sender must be the L1 Bridge");
        _;
    }

    modifier rootConfirmation {
        isRootConfirmation = true;
        _;
        isRootConfirmation = false;
    }

    /**
     * @dev Confirm roots that have bonded on L1 and passed the challenge period
     * @param rootHashes The root hashes to confirm
     * @param destinationChainIds The destinationChainId of the roots to confirm
     * @param totalAmounts The totalAmount of the roots to confirm
     * @param rootCommittedAts The rootCommittedAt of the roots to confirm
     */
    function confirmRoots (
        bytes32[] calldata rootHashes,
        uint256[] calldata destinationChainIds,
        uint256[] calldata totalAmounts,
        uint256[] calldata rootCommittedAts
    ) external override rootConfirmation {
        IL1Bridge l1Bridge = IL1Bridge(l1BridgeAddress);
        require(l1Bridge.getIsBonder(msg.sender), "MW: Sender must be a bonder");
        require(rootHashes.length == totalAmounts.length, "MW: rootHashes and totalAmounts must be the same length");

        uint256 challengePeriod = l1Bridge.challengePeriod();
        for (uint i = 0; i < rootHashes.length; i++) {
            bool canConfirm = canConfirmRoot(l1Bridge, rootHashes[i], totalAmounts[i], challengePeriod);
            if (!canConfirm) {
                revert("MW: Root cannot be confirmed");
            }
            l1Bridge.confirmTransferRoot(
                l2ChainId,
                rootHashes[i],
                destinationChainIds[i],
                totalAmounts[i],
                rootCommittedAts[i]
            );
        }
    }
    
    function canConfirmRoot (IL1Bridge l1Bridge, bytes32 rootHash, uint256 totalAmount, uint256 challengePeriod) public view returns (bool) {
        bytes32 transferRootId = l1Bridge.getTransferRootId(rootHash, totalAmount);
        (,uint256 createdAt,,uint256 challengeStartTime,,) = l1Bridge.transferBonds(transferRootId);

        uint256 challengePeriodEnd = _safeAdd(createdAt, challengePeriod);
        if (
            createdAt != 0 &&
            challengeStartTime == 0 &&
            block.timestamp > challengePeriodEnd
        ) {
            return true;
        }

        return false;
    }

    function _safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "MW: Addition overflow");
        return c;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// +build ovm
pragma solidity >0.5.0 <0.8.0;
pragma experimental ABIEncoderV2;

/**
 * @title iOVM_BaseCrossDomainMessenger
 */
interface iOVM_BaseCrossDomainMessenger {

    /**********
     * Events *
     **********/
    event SentMessage(bytes message);
    event RelayedMessage(bytes32 msgHash);

    /**********************
     * Contract Variables *
     **********************/
    function xDomainMessageSender() external view returns (address);

    /********************
     * Public Functions *
     ********************/

    /**
     * Sends a cross domain message to the target messenger.
     * @param _target Target contract address.
     * @param _message Message to send to the target.
     * @param _gasLimit Gas limit for the provided message.
     */
    function sendMessage(
        address _target,
        bytes calldata _message,
        uint32 _gasLimit
    ) external;

    function deposit(
        address _depositor,
        uint256 _amount,
        bool _send
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12 <=0.8.9;
pragma experimental ABIEncoderV2;

interface IMessengerWrapper {
    function sendCrossDomainMessage(bytes memory _calldata) external;
    function verifySender(address l1BridgeCaller, bytes memory _data) external;
    function confirmRoots(
        bytes32[] calldata rootHashes,
        uint256[] calldata destinationChainIds,
        uint256[] calldata totalAmounts,
        uint256[] calldata rootCommittedAts
    ) external;
}