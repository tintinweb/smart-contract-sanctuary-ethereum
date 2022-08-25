// SPDX-License-Identifier: MIT
// @unsupported: ovm

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/arbitrum/messengers/IInbox.sol";
import "../interfaces/arbitrum/messengers/IBridge.sol";
import "../interfaces/arbitrum/messengers/IOutbox.sol";
import "./MessengerWrapper.sol";

/**
 * @dev A MessengerWrapper for Arbitrum - https://developer.offchainlabs.com/
 * @notice Deployed on layer-1
 */

contract ArbitrumMessengerWrapper is MessengerWrapper, Ownable {

    IInbox public immutable l1MessengerAddress;
    address public l2BridgeAddress;

    constructor(
        address _l1BridgeAddress,
        address _l2BridgeAddress,
        IInbox _l1MessengerAddress,
        uint256 _l2ChainId
    )
        public
        MessengerWrapper(_l1BridgeAddress, _l2ChainId)
    {
        l2BridgeAddress = _l2BridgeAddress;
        l1MessengerAddress = _l1MessengerAddress;
    }

    receive() external payable {}

    /** 
     * @dev Sends a message to the l2BridgeAddress from layer-1
     * @param _calldata The data that l2BridgeAddress will be called with
     */
    function sendCrossDomainMessage(bytes memory _calldata) public override onlyL1Bridge {
        uint256 submissionFee = l1MessengerAddress.calculateRetryableSubmissionFee(_calldata.length, 0);
        l1MessengerAddress.unsafeCreateRetryableTicket{value: submissionFee}(
            l2BridgeAddress,
            0,
            submissionFee,
            address(0),
            address(0),
            0,
            0,
            _calldata
        );
    }

    function verifySender(address l1BridgeCaller, bytes memory /*_data*/) public override {
        if (isRootConfirmation) return;

        // Reference: https://github.com/OffchainLabs/arbitrum/blob/5c06d89daf8fa6088bcdba292ffa6ed0c72afab2/packages/arb-bridge-peripherals/contracts/tokenbridge/ethereum/L1ArbitrumMessenger.sol#L89
        IBridge arbBridge = l1MessengerAddress.bridge();
        IOutbox outbox = IOutbox(arbBridge.activeOutbox());
        address l2ToL1Sender = outbox.l2ToL1Sender();

        require(l1BridgeCaller == address(arbBridge), "ARB_MSG_WPR: Caller is not the bridge");
        require(l2ToL1Sender == l2BridgeAddress, "ARB_MSG_WPR: Invalid cross-domain sender");
    }

    /**
     * @dev Claim excess funds
     * @param recipient The recipient to send to
     * @param amount The amount to claim
     */
    function claimFunds(address payable recipient, uint256 amount) public onlyOwner {
        recipient.transfer(amount);
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

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.6.11;

import "./IBridge.sol";

interface IInbox {
    function sendL2Message(bytes calldata messageData) external returns (uint256);
    function bridge() external view returns (IBridge);
    function unsafeCreateRetryableTicket(
        address to,
        uint256 l2CallValue,
        uint256 maxSubmissionCost,
        address excessFeeRefundAddress,
        address callValueRefundAddress,
        uint256 gasLimit,
        uint256 maxFeePerGas,
        bytes calldata data
    ) external payable returns (uint256);
    function calculateRetryableSubmissionFee(uint256 dataLength, uint256 baseFee) external returns (uint256);
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.6.11;

interface IBridge {
    function activeOutbox() external view returns (address);
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.6.11;

interface IOutbox {
    function l2ToL1Sender() external view returns (address);
}

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