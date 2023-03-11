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

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IArbitraryMessageBridge {
    function messageSender() external view returns (address);
    function maxGasPerTx() external view returns (uint256);
    function transactionHash() external view returns (bytes32);
    function messageId() external view returns (bytes32);
    function messageSourceChainId() external view returns (bytes32);
    function messageCallStatus(bytes32 _messageId) external view returns (bool);
    function failedMessageDataHash(bytes32 _messageId) external view returns (bytes32);
    function failedMessageReceiver(bytes32 _messageId) external view returns (address);
    function failedMessageSender(bytes32 _messageId) external view returns (address);
    function requireToPassMessage(address _contract, bytes memory _data, uint256 _gas) external returns (bytes32);
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
     * @dev Confirm roots that have bonded on L1 and passed the challenge period with no challenge
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
        for (uint256 i = 0; i < rootHashes.length; i++) {
            bool canConfirm = canConfirmRoot(l1Bridge, rootHashes[i], totalAmounts[i], challengePeriod);
            require(canConfirm, "MW: Root cannot be confirmed");
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

        uint256 timeSinceBondCreation = block.timestamp - createdAt;
        if (
            createdAt != 0 &&
            challengeStartTime == 0 &&
            timeSinceBondCreation > challengePeriod
        ) {
            return true;
        }

        return false;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "../interfaces/xDai/messengers/IArbitraryMessageBridge.sol";
import "./MessengerWrapper.sol";

/**
 * @dev A MessengerWrapper for xDai - https://www.xdaichain.com/ (also see https://docs.tokenbridge.net/)
 * @notice Deployed on layer-1
 */

contract XDaiMessengerWrapper is MessengerWrapper {

    IArbitraryMessageBridge public l1MessengerAddress;
    address public ambBridge;
    address public immutable l2BridgeAddress;
    uint256 public immutable defaultGasLimit;

    constructor(
        address _l1BridgeAddress,
        address _l2BridgeAddress,
        IArbitraryMessageBridge _l1MessengerAddress,
        uint256 _l2ChainId,
        uint256 _defaultGasLimit,
        address _ambBridge
    )
        public
        MessengerWrapper(_l1BridgeAddress, _l2ChainId)
    {
        l2BridgeAddress = _l2BridgeAddress;
        l1MessengerAddress = _l1MessengerAddress;
        defaultGasLimit = _defaultGasLimit;
        ambBridge = _ambBridge;
    }

    /**
     * @dev Sends a message to the l2BridgeAddress from layer-1
     * @param _calldata The data that l2BridgeAddress will be called with
     */
    function sendCrossDomainMessage(bytes memory _calldata) public override onlyL1Bridge {
        l1MessengerAddress.requireToPassMessage(
            l2BridgeAddress,
            _calldata,
            defaultGasLimit
        );
    }

    /// @notice message data is not needed for message verification with the xDai AMB
    function verifySender(address l1BridgeCaller, bytes memory) public override {
        if (isRootConfirmation) return;

        require(l1MessengerAddress.messageSender() == l2BridgeAddress, "L2_XDAI_BRG: Invalid cross-domain sender");
        require(l1BridgeCaller == ambBridge, "L2_XDAI_BRG: Caller is not the expected sender");

        // With the xDai AMB, it is best practice to also check the source chainId
        // https://docs.tokenbridge.net/amb-bridge/how-to-develop-xchain-apps-by-amb#receive-a-method-call-from-the-amb-bridge
        // The xDai AMB uses bytes32 for chainId instead of uint256
        require(l1MessengerAddress.messageSourceChainId() == bytes32(l2ChainId), "L2_XDAI_BRG: Invalid source Chain ID");
    }
}