// SPDX-License-Identifier: AGPL-3.0-only

/**
 *   DepositBoxERC20.sol - SKALE Interchain Messaging Agent
 *   Copyright (C) 2019-Present SKALE Labs
 *   @author Artem Payvin
 *
 *   SKALE IMA is free software: you can redistribute it and/or modify
 *   it under the terms of the GNU Affero General Public License as published
 *   by the Free Software Foundation, either version 3 of the License, or
 *   (at your option) any later version.
 *
 *   SKALE IMA is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU Affero General Public License for more details.
 *
 *   You should have received a copy of the GNU Affero General Public License
 *   along with SKALE IMA.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity 0.8.16;

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/DoubleEndedQueueUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@skalenetwork/ima-interfaces/mainnet/DepositBoxes/IDepositBoxERC20.sol";

import "../../Messages.sol";
import "../DepositBox.sol";

interface IERC20TransferVoid {
    function transferFrom(address _from, address _to, uint256 _amount) external;
    function transfer(address _to, uint256 _amount) external;
}


/**
 * @title DepositBoxERC20
 * @dev Runs on mainnet,
 * accepts messages from schain,
 * stores deposits of ERC20.
 */
contract DepositBoxERC20 is DepositBox, IDepositBoxERC20 {
    using AddressUpgradeable for address;
    using DoubleEndedQueueUpgradeable for DoubleEndedQueueUpgradeable.Bytes32Deque;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    using SafeERC20Upgradeable for IERC20MetadataUpgradeable;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    enum DelayedTransferStatus {
        DELAYED,
        ARBITRAGE,
        COMPLETED
    }

    struct DelayedTransfer {
        address receiver;
        bytes32 schainHash;
        address token;
        uint256 amount;
        uint256 untilTimestamp;
        DelayedTransferStatus status;
    }

    struct DelayConfig {
        // token address => value
        mapping(address => uint256) bigTransferThreshold;
        EnumerableSetUpgradeable.AddressSet trustedReceivers;
        uint256 transferDelay;
        uint256 arbitrageDuration;
    }

    uint256 private constant _QUEUE_PROCESSING_LIMIT = 10;

    bytes32 public constant ARBITER_ROLE = keccak256("ARBITER_ROLE");

    // schainHash => address of ERC20 on Mainnet
    // Deprecated
    // slither-disable-next-line unused-state
    mapping(bytes32 => mapping(address => bool)) private _deprecatedSchainToERC20;
    mapping(bytes32 => mapping(address => uint256)) public transferredAmount;
    mapping(bytes32 => EnumerableSetUpgradeable.AddressSet) private _schainToERC20;

    // exits delay configuration
    //   schainHash => delay config
    mapping(bytes32 => DelayConfig) private _delayConfig;

    uint256 public delayedTransfersSize;
    // delayed transfer id => delayed transfer
    mapping(uint256 => DelayedTransfer) public delayedTransfers;
    // receiver address => delayed transfers ids queue
    mapping(address => DoubleEndedQueueUpgradeable.Bytes32Deque) public delayedTransfersByReceiver;

    /**
     * @dev Emitted when token is mapped in DepositBoxERC20.
     */
    event ERC20TokenAdded(string schainName, address indexed contractOnMainnet);

    /**
     * @dev Emitted when token is received by DepositBox and is ready to be cloned
     * or transferred on SKALE chain.
     */
    event ERC20TokenReady(address indexed contractOnMainnet, uint256 amount);

    event TransferDelayed(uint256 id, address receiver, address token, uint256 amount);

    event Escalated(uint256 id);

    /**
     * @dev Emitted when token transfer is skipped due to internal token error
     */
    event TransferSkipped(uint256 id);

    /**
     * @dev Emitted when big transfer threshold is changed
     */
    event BigTransferThresholdIsChanged(
        bytes32 indexed schainHash,
        address indexed token,
        uint256 oldValue,
        uint256 newValue
    );

    /**
     * @dev Emitted when big transfer delay is changed
     */
    event BigTransferDelayIsChanged(
        bytes32 indexed schainHash,
        uint256 oldValue,
        uint256 newValue
    );

    /**
     * @dev Emitted when arbitrage duration is changed
     */
    event ArbitrageDurationIsChanged(
        bytes32 indexed schainHash,
        uint256 oldValue,
        uint256 newValue
    );

    /**
     * @dev Allows `msg.sender` to send ERC20 token from mainnet to schain
     *
     * Requirements:
     *
     * - Schain name must not be `Mainnet`.
     * - Receiver account on schain cannot be null.
     * - Schain that receives tokens should not be killed.
     * - Receiver contract should be defined.
     * - `msg.sender` should approve their tokens for DepositBoxERC20 address.
     */
    function depositERC20(
        string calldata schainName,
        address erc20OnMainnet,
        uint256 amount
    )
        external
        override
        rightTransaction(schainName, msg.sender)
        whenNotKilled(_schainHash(schainName))
    {
        bytes32 schainHash = _schainHash(schainName);
        address contractReceiver = schainLinks[schainHash];
        require(contractReceiver != address(0), "Unconnected chain");
        require(
            IERC20MetadataUpgradeable(erc20OnMainnet).allowance(msg.sender, address(this)) >= amount,
            "DepositBox was not approved for ERC20 token"
        );
        bytes memory data = _receiveERC20(
            schainName,
            erc20OnMainnet,
            msg.sender,
            amount
        );
        _saveTransferredAmount(schainHash, erc20OnMainnet, amount);
        IERC20MetadataUpgradeable(erc20OnMainnet).safeTransferFrom(msg.sender, address(this), amount);
        messageProxy.postOutgoingMessage(
            schainHash,
            contractReceiver,
            data
        );
    }

    /**
     * @dev Allows MessageProxyForMainnet contract to execute transferring ERC20 token from schain to mainnet.
     *
     * Requirements:
     *
     * - Schain from which the tokens came should not be killed.
     * - Sender contract should be defined and schain name cannot be `Mainnet`.
     * - Amount of tokens on DepositBoxERC20 should be equal or more than transferred amount.
     */
    function postMessage(
        bytes32 schainHash,
        address sender,
        bytes calldata data
    )
        external
        override
        onlyMessageProxy
        whenNotKilled(schainHash)
        checkReceiverChain(schainHash, sender)
    {
        Messages.TransferErc20Message memory message = Messages.decodeTransferErc20Message(data);
        require(message.token.isContract(), "Given address is not a contract");
        require(
            IERC20MetadataUpgradeable(message.token).balanceOf(address(this)) >= message.amount,
            "Not enough money"
        );
        _removeTransferredAmount(schainHash, message.token, message.amount);

        uint256 delay = _delayConfig[schainHash].transferDelay;
        if (
            delay > 0
            && _delayConfig[schainHash].bigTransferThreshold[message.token] <= message.amount
            && !isReceiverTrusted(schainHash, message.receiver)
        ) {
            _createDelayedTransfer(schainHash, message, delay);
        } else {
            IERC20MetadataUpgradeable(message.token).safeTransfer(message.receiver, message.amount);
        }
    }

    /**
     * @dev Allows Schain owner to add an ERC20 token to DepositBoxERC20.
     *
     * Emits an {ERC20TokenAdded} event.
     *
     * Requirements:
     *
     * - Schain should not be killed.
     * - Only owner of the schain able to run function.
     */
    function addERC20TokenByOwner(string calldata schainName, address erc20OnMainnet)
        external
        override
        onlySchainOwner(schainName)
        whenNotKilled(_schainHash(schainName))
    {
        _addERC20ForSchain(schainName, erc20OnMainnet);
    }

    /**
     * @dev Allows Schain owner to return each user their tokens.
     * The Schain owner decides which tokens to send to which address,
     * since the contract on mainnet does not store information about which tokens belong to whom.
     *
     * Requirements:
     *
     * - Amount of tokens on schain should be equal or more than transferred amount.
     * - msg.sender should be an owner of schain
     * - IMA transfers Mainnet <-> schain should be killed
     */
    function getFunds(string calldata schainName, address erc20OnMainnet, address receiver, uint amount)
        external
        override
        onlySchainOwner(schainName)
        whenKilled(_schainHash(schainName))
    {
        bytes32 schainHash = _schainHash(schainName);
        require(transferredAmount[schainHash][erc20OnMainnet] >= amount, "Incorrect amount");
        _removeTransferredAmount(schainHash, erc20OnMainnet, amount);
        IERC20MetadataUpgradeable(erc20OnMainnet).safeTransfer(receiver, amount);
    }

    /**
     * @dev Set a threshold amount of tokens.
     * If amount of tokens that exits IMA is bigger than the threshold
     * the transfer is delayed for configurable amount of time
     * and can be canceled by a voting
     *
     * Requirements:
     *
     * - msg.sender should be an owner of schain
     */
    function setBigTransferValue(
        string calldata schainName,
        address token,
        uint256 value
    )
        external
        override
        onlySchainOwner(schainName)
    {
        bytes32 schainHash = _schainHash(schainName);
        emit BigTransferThresholdIsChanged(
            schainHash,
            token,
            _delayConfig[schainHash].bigTransferThreshold[token],
            value
        );
        _delayConfig[schainHash].bigTransferThreshold[token] = value;
    }

    /**
     * @dev Set a time delay.
     * If amount of tokens that exits IMA is bigger than a threshold
     * the transfer is delayed for set amount of time
     * and can be canceled by a voting
     *
     * Requirements:
     *
     * - msg.sender should be an owner of schain
     */
    function setBigTransferDelay(
        string calldata schainName,
        uint256 delayInSeconds
    )
        external
        override
        onlySchainOwner(schainName)
    {
        bytes32 schainHash = _schainHash(schainName);
        // need to restrict big delays to avoid overflow
        require(delayInSeconds < 1e8, "Delay is too big"); // no more then ~ 3 years
        emit BigTransferDelayIsChanged(schainHash, _delayConfig[schainHash].transferDelay, delayInSeconds);
        _delayConfig[schainHash].transferDelay = delayInSeconds;
    }

    /**
     * @dev Set an arbitrage.
     * After escalation the transfer is locked for provided period of time.
     *
     * Requirements:
     *
     * - msg.sender should be an owner of schain
     */
    function setArbitrageDuration(
        string calldata schainName,
        uint256 delayInSeconds
    )
        external
        override
        onlySchainOwner(schainName)
    {
        bytes32 schainHash = _schainHash(schainName);
        // need to restrict big delays to avoid overflow
        require(delayInSeconds < 1e8, "Delay is too big"); // no more then ~ 3 years
        emit ArbitrageDurationIsChanged(schainHash, _delayConfig[schainHash].arbitrageDuration, delayInSeconds);
        _delayConfig[schainHash].arbitrageDuration = delayInSeconds;
    }

    /**
     * @dev Add the address to a whitelist of addresses that can do big transfers without delaying
     * Requirements:
     *
     * - msg.sender should be an owner of schain
     * - the address must not be in the whitelist
     */
    function trustReceiver(
        string calldata schainName,
        address receiver
    )
        external
        override
        onlySchainOwner(schainName)
    {
        require(
            _delayConfig[_schainHash(schainName)].trustedReceivers.add(receiver),
            "Receiver already is trusted"
        );
    }

    /**
     * @dev Remove the address from a whitelist of addresses that can do big transfers without delaying
     * Requirements:
     *
     * - msg.sender should be an owner of schain
     * - the address must be in the whitelist
     */
    function stopTrustingReceiver(
        string calldata schainName,
        address receiver
    )
        external
        override
        onlySchainOwner(schainName)
    {
        require(_delayConfig[_schainHash(schainName)].trustedReceivers.remove(receiver), "Receiver is not trusted");
    }

    /**
     * @dev Transfers tokens that was locked for delay during exit process.
     * Must be called by a receiver.
     */
    function retrieve() external override {
        retrieveFor(msg.sender);
    }

    /**
     * @dev Initialize arbitrage of a suspicious big transfer
     *
     * Requirements:
     *
     * - msg.sender should be an owner of schain or have ARBITER_ROLE role
     * - transfer must be delayed and arbitrage must not be started
     */
    function escalate(uint256 transferId) external override {
        bytes32 schainHash = delayedTransfers[transferId].schainHash;
        require(
            hasRole(ARBITER_ROLE, msg.sender) || isSchainOwner(msg.sender, schainHash),
            "Not enough permissions to request escalation"
        );
        require(delayedTransfers[transferId].status == DelayedTransferStatus.DELAYED, "The transfer has to be delayed");
        delayedTransfers[transferId].status = DelayedTransferStatus.ARBITRAGE;
        delayedTransfers[transferId].untilTimestamp = MathUpgradeable.max(
            delayedTransfers[transferId].untilTimestamp,
            block.timestamp + _delayConfig[schainHash].arbitrageDuration
        );
        emit Escalated(transferId);
    }

    /**
     * @dev Approve a big transfer and immidiately transfer tokens during arbitrage
     *
     * Requirements:
     *
     * - msg.sender should be an owner of schain
     * - arbitrage of the transfer must be started
     */
    function validateTransfer(
        uint transferId
    )
        external
        override
        onlySchainOwnerByHash(delayedTransfers[transferId].schainHash)
    {
        DelayedTransfer storage transfer = delayedTransfers[transferId];
        require(transfer.status == DelayedTransferStatus.ARBITRAGE, "Arbitrage has to be active");
        transfer.status = DelayedTransferStatus.COMPLETED;
        delete transfer.untilTimestamp;
        IERC20MetadataUpgradeable(transfer.token).safeTransfer(transfer.receiver, transfer.amount);
    }

    /**
     * @dev Reject a big transfer and transfer tokens to SKALE chain owner during arbitrage
     *
     * Requirements:
     *
     * - msg.sender should be an owner of schain
     * - arbitrage of the transfer must be started
     */
    function rejectTransfer(
        uint transferId
    )
        external
        override
        onlySchainOwnerByHash(delayedTransfers[transferId].schainHash)
    {
        DelayedTransfer storage transfer = delayedTransfers[transferId];
        require(transfer.status == DelayedTransferStatus.ARBITRAGE, "Arbitrage has to be active");
        transfer.status = DelayedTransferStatus.COMPLETED;
        delete transfer.untilTimestamp;
        // msg.sender is schain owner
        IERC20MetadataUpgradeable(transfer.token).safeTransfer(msg.sender, transfer.amount);
    }

    function doTransfer(address token, address receiver, uint256 amount) external override {
        require(msg.sender == address(this), "Internal use only");
        IERC20Upgradeable(token).safeTransfer(receiver, amount);
    }

    /**
     * @dev Returns receiver of message.
     *
     * Requirements:
     *
     * - Sender contract should be defined and schain name cannot be `Mainnet`.
     */
    function gasPayer(
        bytes32 schainHash,
        address sender,
        bytes calldata data
    )
        external
        view
        override
        checkReceiverChain(schainHash, sender)
        returns (address)
    {
        Messages.TransferErc20Message memory message = Messages.decodeTransferErc20Message(data);
        return message.receiver;
    }

    /**
     * @dev Should return true if token was added by Schain owner or
     * added automatically after sending to schain if whitelist was turned off.
     */
    function getSchainToERC20(
        string calldata schainName,
        address erc20OnMainnet
    )
        external
        view
        override
        returns (bool)
    {
        return _schainToERC20[_schainHash(schainName)].contains(erc20OnMainnet);
    }

    /**
     * @dev Should return length of a set of all mapped tokens which were added by Schain owner
     * or added automatically after sending to schain if whitelist was turned off.
     */
    function getSchainToAllERC20Length(string calldata schainName) external view override returns (uint256) {
        return _schainToERC20[_schainHash(schainName)].length();
    }

    /**
     * @dev Should return an array of range of tokens were added by Schain owner
     * or added automatically after sending to schain if whitelist was turned off.
     */
    function getSchainToAllERC20(
        string calldata schainName,
        uint256 from,
        uint256 to
    )
        external
        view
        override
        returns (address[] memory tokensInRange)
    {
        require(
            from < to && to - from <= 10 && to <= _schainToERC20[_schainHash(schainName)].length(),
            "Range is incorrect"
        );
        tokensInRange = new address[](to - from);
        for (uint256 i = from; i < to; i++) {
            tokensInRange[i - from] = _schainToERC20[_schainHash(schainName)].at(i);
        }
    }

    /**
     * @dev Get amount of tokens that are delayed for specified receiver
     */
    function getDelayedAmount(address receiver, address token) external view override returns (uint256 value) {
        uint256 delayedTransfersAmount = delayedTransfersByReceiver[receiver].length();
        for (uint256 i = 0; i < delayedTransfersAmount; ++i) {
            DelayedTransfer storage transfer = delayedTransfers[uint256(delayedTransfersByReceiver[receiver].at(i))];
            DelayedTransferStatus status = transfer.status;
            if (transfer.token == token) {
                if (status == DelayedTransferStatus.DELAYED || status == DelayedTransferStatus.ARBITRAGE) {
                    value += transfer.amount;
                }
            }
        }
    }

    /**
     * @dev Get timestamp of next unlock of tokens that are delayed for specified receiver
     */
    function getNextUnlockTimestamp(
        address receiver,
        address token
    )
        external
        view
        override
        returns (uint256 unlockTimestamp)
    {
        uint256 delayedTransfersAmount = delayedTransfersByReceiver[receiver].length();
        unlockTimestamp = type(uint256).max;
        for (uint256 i = 0; i < delayedTransfersAmount; ++i) {
            DelayedTransfer storage transfer = delayedTransfers[uint256(delayedTransfersByReceiver[receiver].at(i))];
            DelayedTransferStatus status = transfer.status;
            if (transfer.token == token) {
                if (status != DelayedTransferStatus.COMPLETED) {
                    unlockTimestamp = MathUpgradeable.min(unlockTimestamp, transfer.untilTimestamp);
                }
                if (status == DelayedTransferStatus.DELAYED) {
                    break;
                }
            }
        }
    }

    /**
     * @dev Get amount of addresses that are added to the whitelist
     */
    function getTrustedReceiversAmount(bytes32 schainHash) external view override returns (uint256) {
        return _delayConfig[schainHash].trustedReceivers.length();
    }

    /**
     * @dev Get i-th address of the whitelist
     */
    function getTrustedReceiver(string calldata schainName, uint256 index) external view override returns (address) {
        return _delayConfig[_schainHash(schainName)].trustedReceivers.at(index);
    }

    /**
     * @dev Get amount of tokens that are considered as a big transfer
     */
    function getBigTransferThreshold(bytes32 schainHash, address token) external view override returns (uint256) {
        return _delayConfig[schainHash].bigTransferThreshold[token];
    }

    /**
     * @dev Get time delay of big transfers
     */
    function getTimeDelay(bytes32 schainHash) external view override returns (uint256) {
        return _delayConfig[schainHash].transferDelay;
    }

    /**
     * @dev Get duration of an arbitrage
     */
    function getArbitrageDuration(bytes32 schainHash) external view override returns (uint256) {
        return _delayConfig[schainHash].arbitrageDuration;
    }

    /**
     * @dev Retrive tokens that were unlocked after delay for specified receiver
     */
    function retrieveFor(address receiver) public override {
        uint256 transfersAmount = MathUpgradeable.min(
            delayedTransfersByReceiver[receiver].length(),
            _QUEUE_PROCESSING_LIMIT
        );

        uint256 currentIndex = 0;
        bool retrieved = false;
        for (uint256 i = 0; i < transfersAmount; ++i) {
            uint256 transferId = uint256(delayedTransfersByReceiver[receiver].at(currentIndex));
            DelayedTransfer memory transfer = delayedTransfers[transferId];
            ++currentIndex;

            if (transfer.status != DelayedTransferStatus.COMPLETED) {
                if (block.timestamp < transfer.untilTimestamp) {
                    // disable detector untill slither fixes false positive
                    // https://github.com/crytic/slither/issues/778
                    // slither-disable-next-line incorrect-equality
                    if (transfer.status == DelayedTransferStatus.DELAYED) {
                        break;
                    } else {
                        // status is ARBITRAGE
                        continue;
                    }
                } else {
                    // it's time to unlock
                    if (currentIndex == 1) {
                        --currentIndex;
                        _removeOldestDelayedTransfer(receiver);
                    } else {
                        delayedTransfers[transferId].status = DelayedTransferStatus.COMPLETED;
                    }
                    retrieved = true;
                    try
                        this.doTransfer(transfer.token, transfer.receiver, transfer.amount)
                    // solhint-disable-next-line no-empty-blocks
                    {}
                    catch {
                        emit TransferSkipped(transferId);
                    }
                }
            } else {
                // status is COMPLETED
                if (currentIndex == 1) {
                    --currentIndex;
                    retrieved = true;
                    _removeOldestDelayedTransfer(receiver);
                }
            }
        }
        require(retrieved, "There are no transfers available for retrieving");
    }

    /**
     * @dev Creates a new DepositBoxERC20 contract.
     */
    function initialize(
        IContractManager contractManagerOfSkaleManagerValue,
        ILinker linkerValue,
        IMessageProxyForMainnet messageProxyValue
    )
        public
        override(DepositBox, IDepositBox)
        initializer
    {
        DepositBox.initialize(contractManagerOfSkaleManagerValue, linkerValue, messageProxyValue);
    }

    /**
     * @dev Check if the receiver is in the delay whitelist
     */
    function isReceiverTrusted(bytes32 schainHash, address receiver) public view override returns (bool) {
        return _delayConfig[schainHash].trustedReceivers.contains(receiver);
    }

    // private

    /**
     * @dev Saves amount of tokens that was transferred to schain.
     */
    function _saveTransferredAmount(bytes32 schainHash, address erc20Token, uint256 amount) private {
        transferredAmount[schainHash][erc20Token] += amount;
    }

    /**
     * @dev Removes amount of tokens that was transferred from schain.
     */
    function _removeTransferredAmount(bytes32 schainHash, address erc20Token, uint256 amount) private {
        transferredAmount[schainHash][erc20Token] -= amount;
    }

    /**
     * @dev Allows DepositBoxERC20 to receive ERC20 tokens.
     *
     * Emits an {ERC20TokenReady} event.
     *
     * Requirements:
     *
     * - Amount must be less than or equal to the total supply of the ERC20 contract.
     * - Whitelist should be turned off for auto adding tokens to DepositBoxERC20.
     */
    function _receiveERC20(
        string calldata schainName,
        address erc20OnMainnet,
        address to,
        uint256 amount
    )
        private
        returns (bytes memory data)
    {
        bytes32 schainHash = _schainHash(schainName);
        IERC20MetadataUpgradeable erc20 = IERC20MetadataUpgradeable(erc20OnMainnet);
        uint256 totalSupply = erc20.totalSupply();
        require(amount <= totalSupply, "Amount is incorrect");
        bool isERC20AddedToSchain = _schainToERC20[schainHash].contains(erc20OnMainnet);
        if (!isERC20AddedToSchain) {
            require(!isWhitelisted(schainName), "Whitelist is enabled");
            _addERC20ForSchain(schainName, erc20OnMainnet);
            data = Messages.encodeTransferErc20AndTokenInfoMessage(
                erc20OnMainnet,
                to,
                amount,
                _getErc20TotalSupply(erc20),
                _getErc20TokenInfo(erc20)
            );
        } else {
            data = Messages.encodeTransferErc20AndTotalSupplyMessage(
                erc20OnMainnet,
                to,
                amount,
                _getErc20TotalSupply(erc20)
            );
        }
        emit ERC20TokenReady(erc20OnMainnet, amount);
    }

    /**
     * @dev Adds an ERC20 token to DepositBoxERC20.
     *
     * Emits an {ERC20TokenAdded} event.
     *
     * Requirements:
     *
     * - Given address should be contract.
     */
    function _addERC20ForSchain(string calldata schainName, address erc20OnMainnet) private {
        bytes32 schainHash = _schainHash(schainName);
        require(erc20OnMainnet.isContract(), "Given address is not a contract");
        require(!_schainToERC20[schainHash].contains(erc20OnMainnet), "ERC20 Token was already added");
        _schainToERC20[schainHash].add(erc20OnMainnet);
        emit ERC20TokenAdded(schainName, erc20OnMainnet);
    }

    /**
     * @dev Add delayed transfer to receiver specific queue
     */
    function _addToDelayedQueue(
        address receiver,
        uint256 id,
        uint256 until
    )
        private
    {
        _addToDelayedQueueWithPriority(delayedTransfersByReceiver[receiver], id, until, _QUEUE_PROCESSING_LIMIT);
    }

    /**
     * @dev Add delayed transfer to receiver specific queue at the position
     * that maintains order from earlier unlocked to later unlocked.
     * If the position is located further than depthLimit from the back
     * the element is added at back - depthLimit index
     */
    function _addToDelayedQueueWithPriority(
        DoubleEndedQueueUpgradeable.Bytes32Deque storage queue,
        uint256 id,
        uint256 until,
        uint256 depthLimit
    )
        private
    {
        if (depthLimit == 0 || queue.empty()) {
            queue.pushBack(bytes32(id));
        } else {
            if (delayedTransfers[uint256(queue.back())].untilTimestamp <= until) {
                queue.pushBack(bytes32(id));
            } else {
                bytes32 lowPriorityValue = queue.popBack();
                _addToDelayedQueueWithPriority(queue, id, until, depthLimit - 1);
                queue.pushBack(lowPriorityValue);
            }
        }
    }

    /**
     * Create instance of DelayedTransfer and initialize all auxiliary fields.
     */
    function _createDelayedTransfer(
        bytes32 schainHash,
        Messages.TransferErc20Message memory message,
        uint256 delay
    )
        private
    {
        uint256 delayId = delayedTransfersSize++;
        delayedTransfers[delayId] = DelayedTransfer({
            receiver: message.receiver,
            schainHash: schainHash,
            token: message.token,
            amount: message.amount,
            untilTimestamp: block.timestamp + delay,
            status: DelayedTransferStatus.DELAYED
        });
        _addToDelayedQueue(message.receiver, delayId, block.timestamp + delay);
        emit TransferDelayed(delayId, message.receiver, message.token, message.amount);
    }

    /**
     * Remove instance of DelayedTransfer and clean auxiliary fields.
     */
    function _removeOldestDelayedTransfer(address receiver) private {
        uint256 transferId = uint256(delayedTransfersByReceiver[receiver].popFront());
        // For most cases the loop will have only 1 iteration.
        // In worst case the amount of iterations is limited by _QUEUE_PROCESSING_LIMIT
        // slither-disable-next-line costly-loop
        delete delayedTransfers[transferId];
    }

    /**
     * @dev Returns total supply of ERC20 token.
     */
    function _getErc20TotalSupply(IERC20MetadataUpgradeable erc20Token) private view returns (uint256) {
        return erc20Token.totalSupply();
    }

    /**
     * @dev Returns info about ERC20 token such as token name, decimals, symbol.
     */
    function _getErc20TokenInfo(IERC20MetadataUpgradeable erc20Token)
        private
        view
        returns (Messages.Erc20TokenInfo memory)
    {
        return Messages.Erc20TokenInfo({
            name: erc20Token.name(),
            decimals: erc20Token.decimals(),
            symbol: erc20Token.symbol()
        });
    }
}

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/Math.sol)

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
        return a >= b ? a : b;
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
     * @dev Returns the square root of a number. It the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`.
        // We also know that `k`, the position of the most significant bit, is such that `msb(a) = 2**k`.
        // This gives `2**k < a <= 2**(k+1)` → `2**(k/2) <= sqrt(a) < 2 ** (k/2+1)`.
        // Using an algorithm similar to the msb conmputation, we are able to compute `result = 2**(k/2)` which is a
        // good first aproximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1;
        uint256 x = a;
        if (x >> 128 > 0) {
            x >>= 128;
            result <<= 64;
        }
        if (x >> 64 > 0) {
            x >>= 64;
            result <<= 32;
        }
        if (x >> 32 > 0) {
            x >>= 32;
            result <<= 16;
        }
        if (x >> 16 > 0) {
            x >>= 16;
            result <<= 8;
        }
        if (x >> 8 > 0) {
            x >>= 8;
            result <<= 4;
        }
        if (x >> 4 > 0) {
            x >>= 4;
            result <<= 2;
        }
        if (x >> 2 > 0) {
            result <<= 1;
        }

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
        uint256 result = sqrt(a);
        if (rounding == Rounding.Up && result * result < a) {
            result += 1;
        }
        return result;
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
 * ====
 */
library EnumerableSetUpgradeable {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

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
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

/**
 *   IDepositBoxERC20.sol - SKALE Interchain Messaging Agent
 *   Copyright (C) 2021-Present SKALE Labs
 *   @author Dmytro Stebaiev
 *
 *   SKALE IMA is free software: you can redistribute it and/or modify
 *   it under the terms of the GNU Affero General Public License as published
 *   by the Free Software Foundation, either version 3 of the License, or
 *   (at your option) any later version.
 *
 *   SKALE IMA is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU Affero General Public License for more details.
 *
 *   You should have received a copy of the GNU Affero General Public License
 *   along with SKALE IMA.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity >=0.6.10 <0.9.0;

import "../IDepositBox.sol";


interface IDepositBoxERC20 is IDepositBox {
    function addERC20TokenByOwner(string calldata schainName, address erc20OnMainnet) external;
    function depositERC20(string calldata schainName, address erc20OnMainnet, uint256 amount) external;
    function doTransfer(address token, address receiver, uint256 amount) external;
    function escalate(uint256 transferId) external;
    function getFunds(string calldata schainName, address erc20OnMainnet, address receiver, uint amount) external;
    function rejectTransfer(uint transferId) external;
    function retrieve() external;
    function retrieveFor(address receiver) external;
    function setArbitrageDuration(string calldata schainName, uint256 delayInSeconds) external;
    function setBigTransferValue(string calldata schainName, address token, uint256 value) external;
    function setBigTransferDelay(string calldata schainName, uint256 delayInSeconds) external;
    function stopTrustingReceiver(string calldata schainName, address receiver) external;
    function trustReceiver(string calldata schainName, address receiver) external;
    function validateTransfer(uint transferId) external;
    function isReceiverTrusted(bytes32 schainHash, address receiver) external view returns (bool);
    function getArbitrageDuration(bytes32 schainHash) external view returns (uint256);
    function getBigTransferThreshold(bytes32 schainHash, address token) external view returns (uint256);
    function getDelayedAmount(address receiver, address token) external view returns (uint256 value);
    function getNextUnlockTimestamp(address receiver, address token) external view returns (uint256 unlockTimestamp);
    function getSchainToERC20(string calldata schainName, address erc20OnMainnet) external view returns (bool);
    function getSchainToAllERC20Length(string calldata schainName) external view returns (uint256);
    function getSchainToAllERC20(
        string calldata schainName,
        uint256 from,
        uint256 to
    )
        external
        view
        returns (address[] memory);
    function getTimeDelay(bytes32 schainHash) external view returns (uint256);
    function getTrustedReceiver(string calldata schainName, uint256 index) external view returns (address);
    function getTrustedReceiversAmount(bytes32 schainHash) external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0-only

/**
 *   Messages.sol - SKALE Interchain Messaging Agent
 *   Copyright (C) 2021-Present SKALE Labs
 *   @author Dmytro Stebaiev
 *
 *   SKALE IMA is free software: you can redistribute it and/or modify
 *   it under the terms of the GNU Affero General Public License as published
 *   by the Free Software Foundation, either version 3 of the License, or
 *   (at your option) any later version.
 *
 *   SKALE IMA is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU Affero General Public License for more details.
 *
 *   You should have received a copy of the GNU Affero General Public License
 *   along with SKALE IMA.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity 0.8.16;


/**
 * @title Messages
 * @dev Library for encoding and decoding messages
 * for transferring from Mainnet to Schain and vice versa.
 */
library Messages {

    /**
     * @dev Enumerator that describes all supported message types.
     */
    enum MessageType {
        EMPTY,
        TRANSFER_ETH,
        TRANSFER_ERC20,
        TRANSFER_ERC20_AND_TOTAL_SUPPLY,
        TRANSFER_ERC20_AND_TOKEN_INFO,
        TRANSFER_ERC721,
        TRANSFER_ERC721_AND_TOKEN_INFO,
        USER_STATUS,
        INTERCHAIN_CONNECTION,
        TRANSFER_ERC1155,
        TRANSFER_ERC1155_AND_TOKEN_INFO,
        TRANSFER_ERC1155_BATCH,
        TRANSFER_ERC1155_BATCH_AND_TOKEN_INFO,
        TRANSFER_ERC721_WITH_METADATA,
        TRANSFER_ERC721_WITH_METADATA_AND_TOKEN_INFO
    }

    /**
     * @dev Structure for base message.
     */
    struct BaseMessage {
        MessageType messageType;
    }

    /**
     * @dev Structure for describing ETH.
     */
    struct TransferEthMessage {
        BaseMessage message;
        address receiver;
        uint256 amount;
    }

    /**
     * @dev Structure for user status.
     */
    struct UserStatusMessage {
        BaseMessage message;
        address receiver;
        bool isActive;
    }

    /**
     * @dev Structure for describing ERC20 token.
     */
    struct TransferErc20Message {
        BaseMessage message;
        address token;
        address receiver;
        uint256 amount;
    }

    /**
     * @dev Structure for describing additional data for ERC20 token.
     */
    struct Erc20TokenInfo {
        string name;
        uint8 decimals;
        string symbol;
    }

    /**
     * @dev Structure for describing ERC20 with token supply.
     */
    struct TransferErc20AndTotalSupplyMessage {
        TransferErc20Message baseErc20transfer;
        uint256 totalSupply;
    }

    /**
     * @dev Structure for describing ERC20 with token info.
     */
    struct TransferErc20AndTokenInfoMessage {
        TransferErc20Message baseErc20transfer;
        uint256 totalSupply;
        Erc20TokenInfo tokenInfo;
    }

    /**
     * @dev Structure for describing base ERC721.
     */
    struct TransferErc721Message {
        BaseMessage message;
        address token;
        address receiver;
        uint256 tokenId;
    }

    /**
     * @dev Structure for describing base ERC721 with metadata.
     */
    struct TransferErc721MessageWithMetadata {
        TransferErc721Message erc721message;
        string tokenURI;
    }

    /**
     * @dev Structure for describing ERC20 with token info.
     */
    struct Erc721TokenInfo {
        string name;
        string symbol;
    }

    /**
     * @dev Structure for describing additional data for ERC721 token.
     */
    struct TransferErc721AndTokenInfoMessage {
        TransferErc721Message baseErc721transfer;
        Erc721TokenInfo tokenInfo;
    }

    /**
     * @dev Structure for describing additional data for ERC721 token with metadata.
     */
    struct TransferErc721WithMetadataAndTokenInfoMessage {
        TransferErc721MessageWithMetadata baseErc721transferWithMetadata;
        Erc721TokenInfo tokenInfo;
    }

    /**
     * @dev Structure for describing whether interchain connection is allowed.
     */
    struct InterchainConnectionMessage {
        BaseMessage message;
        bool isAllowed;
    }

    /**
     * @dev Structure for describing whether interchain connection is allowed.
     */
    struct TransferErc1155Message {
        BaseMessage message;
        address token;
        address receiver;
        uint256 id;
        uint256 amount;
    }

    /**
     * @dev Structure for describing ERC1155 token in batches.
     */
    struct TransferErc1155BatchMessage {
        BaseMessage message;
        address token;
        address receiver;
        uint256[] ids;
        uint256[] amounts;
    }

    /**
     * @dev Structure for describing ERC1155 token info.
     */
    struct Erc1155TokenInfo {
        string uri;
    }

    /**
     * @dev Structure for describing message for transferring ERC1155 token with info.
     */
    struct TransferErc1155AndTokenInfoMessage {
        TransferErc1155Message baseErc1155transfer;
        Erc1155TokenInfo tokenInfo;
    }

    /**
     * @dev Structure for describing message for transferring ERC1155 token in batches with info.
     */
    struct TransferErc1155BatchAndTokenInfoMessage {
        TransferErc1155BatchMessage baseErc1155Batchtransfer;
        Erc1155TokenInfo tokenInfo;
    }


    /**
     * @dev Returns type of message for encoded data.
     */
    function getMessageType(bytes calldata data) internal pure returns (MessageType) {
        uint256 firstWord = abi.decode(data, (uint256));
        if (firstWord % 32 == 0) {
            return getMessageType(data[firstWord:]);
        } else {
            return abi.decode(data, (Messages.MessageType));
        }
    }

    /**
     * @dev Encodes message for transferring ETH. Returns encoded message.
     */
    function encodeTransferEthMessage(address receiver, uint256 amount) internal pure returns (bytes memory) {
        TransferEthMessage memory message = TransferEthMessage(
            BaseMessage(MessageType.TRANSFER_ETH),
            receiver,
            amount
        );
        return abi.encode(message);
    }

    /**
     * @dev Decodes message for transferring ETH. Returns structure `TransferEthMessage`.
     */
    function decodeTransferEthMessage(
        bytes calldata data
    ) internal pure returns (TransferEthMessage memory) {
        require(getMessageType(data) == MessageType.TRANSFER_ETH, "Message type is not ETH transfer");
        return abi.decode(data, (TransferEthMessage));
    }

    /**
     * @dev Encodes message for transferring ETH. Returns encoded message.
     */
    function encodeTransferErc20Message(
        address token,
        address receiver,
        uint256 amount
    ) internal pure returns (bytes memory) {
        TransferErc20Message memory message = TransferErc20Message(
            BaseMessage(MessageType.TRANSFER_ERC20),
            token,
            receiver,
            amount
        );
        return abi.encode(message);
    }

    /**
     * @dev Encodes message for transferring ERC20 with total supply. Returns encoded message.
     */
    function encodeTransferErc20AndTotalSupplyMessage(
        address token,
        address receiver,
        uint256 amount,
        uint256 totalSupply
    ) internal pure returns (bytes memory) {
        TransferErc20AndTotalSupplyMessage memory message = TransferErc20AndTotalSupplyMessage(
            TransferErc20Message(
                BaseMessage(MessageType.TRANSFER_ERC20_AND_TOTAL_SUPPLY),
                token,
                receiver,
                amount
            ),
            totalSupply
        );
        return abi.encode(message);
    }

    /**
     * @dev Decodes message for transferring ERC20. Returns structure `TransferErc20Message`.
     */
    function decodeTransferErc20Message(
        bytes calldata data
    ) internal pure returns (TransferErc20Message memory) {
        require(getMessageType(data) == MessageType.TRANSFER_ERC20, "Message type is not ERC20 transfer");
        return abi.decode(data, (TransferErc20Message));
    }

    /**
     * @dev Decodes message for transferring ERC20 with total supply. 
     * Returns structure `TransferErc20AndTotalSupplyMessage`.
     */
    function decodeTransferErc20AndTotalSupplyMessage(
        bytes calldata data
    ) internal pure returns (TransferErc20AndTotalSupplyMessage memory) {
        require(
            getMessageType(data) == MessageType.TRANSFER_ERC20_AND_TOTAL_SUPPLY,
            "Message type is not ERC20 transfer and total supply"
        );
        return abi.decode(data, (TransferErc20AndTotalSupplyMessage));
    }

    /**
     * @dev Encodes message for transferring ERC20 with token info. 
     * Returns encoded message.
     */
    function encodeTransferErc20AndTokenInfoMessage(
        address token,
        address receiver,
        uint256 amount,
        uint256 totalSupply,
        Erc20TokenInfo memory tokenInfo
    ) internal pure returns (bytes memory) {
        TransferErc20AndTokenInfoMessage memory message = TransferErc20AndTokenInfoMessage(
            TransferErc20Message(
                BaseMessage(MessageType.TRANSFER_ERC20_AND_TOKEN_INFO),
                token,
                receiver,
                amount
            ),
            totalSupply,
            tokenInfo
        );
        return abi.encode(message);
    }

    /**
     * @dev Decodes message for transferring ERC20 with token info. 
     * Returns structure `TransferErc20AndTokenInfoMessage`.
     */
    function decodeTransferErc20AndTokenInfoMessage(
        bytes calldata data
    ) internal pure returns (TransferErc20AndTokenInfoMessage memory) {
        require(
            getMessageType(data) == MessageType.TRANSFER_ERC20_AND_TOKEN_INFO,
            "Message type is not ERC20 transfer with token info"
        );
        return abi.decode(data, (TransferErc20AndTokenInfoMessage));
    }

    /**
     * @dev Encodes message for transferring ERC721. 
     * Returns encoded message.
     */
    function encodeTransferErc721Message(
        address token,
        address receiver,
        uint256 tokenId
    ) internal pure returns (bytes memory) {
        TransferErc721Message memory message = TransferErc721Message(
            BaseMessage(MessageType.TRANSFER_ERC721),
            token,
            receiver,
            tokenId
        );
        return abi.encode(message);
    }

    /**
     * @dev Decodes message for transferring ERC721. 
     * Returns structure `TransferErc721Message`.
     */
    function decodeTransferErc721Message(
        bytes calldata data
    ) internal pure returns (TransferErc721Message memory) {
        require(getMessageType(data) == MessageType.TRANSFER_ERC721, "Message type is not ERC721 transfer");
        return abi.decode(data, (TransferErc721Message));
    }

    /**
     * @dev Encodes message for transferring ERC721 with token info. 
     * Returns encoded message.
     */
    function encodeTransferErc721AndTokenInfoMessage(
        address token,
        address receiver,
        uint256 tokenId,
        Erc721TokenInfo memory tokenInfo
    ) internal pure returns (bytes memory) {
        TransferErc721AndTokenInfoMessage memory message = TransferErc721AndTokenInfoMessage(
            TransferErc721Message(
                BaseMessage(MessageType.TRANSFER_ERC721_AND_TOKEN_INFO),
                token,
                receiver,
                tokenId
            ),
            tokenInfo
        );
        return abi.encode(message);
    }

    /**
     * @dev Decodes message for transferring ERC721 with token info. 
     * Returns structure `TransferErc721AndTokenInfoMessage`.
     */
    function decodeTransferErc721AndTokenInfoMessage(
        bytes calldata data
    ) internal pure returns (TransferErc721AndTokenInfoMessage memory) {
        require(
            getMessageType(data) == MessageType.TRANSFER_ERC721_AND_TOKEN_INFO,
            "Message type is not ERC721 transfer with token info"
        );
        return abi.decode(data, (TransferErc721AndTokenInfoMessage));
    }

    /**
     * @dev Encodes message for transferring ERC721. 
     * Returns encoded message.
     */
    function encodeTransferErc721MessageWithMetadata(
        address token,
        address receiver,
        uint256 tokenId,
        string memory tokenURI
    ) internal pure returns (bytes memory) {
        TransferErc721MessageWithMetadata memory message = TransferErc721MessageWithMetadata(
            TransferErc721Message(
                BaseMessage(MessageType.TRANSFER_ERC721_WITH_METADATA),
                token,
                receiver,
                tokenId
            ),
            tokenURI
        );
        return abi.encode(message);
    }

    /**
     * @dev Decodes message for transferring ERC721. 
     * Returns structure `TransferErc721MessageWithMetadata`.
     */
    function decodeTransferErc721MessageWithMetadata(
        bytes calldata data
    ) internal pure returns (TransferErc721MessageWithMetadata memory) {
        require(
            getMessageType(data) == MessageType.TRANSFER_ERC721_WITH_METADATA,
            "Message type is not ERC721 transfer"
        );
        return abi.decode(data, (TransferErc721MessageWithMetadata));
    }

    /**
     * @dev Encodes message for transferring ERC721 with token info. 
     * Returns encoded message.
     */
    function encodeTransferErc721WithMetadataAndTokenInfoMessage(
        address token,
        address receiver,
        uint256 tokenId,
        string memory tokenURI,
        Erc721TokenInfo memory tokenInfo
    ) internal pure returns (bytes memory) {
        TransferErc721WithMetadataAndTokenInfoMessage memory message = TransferErc721WithMetadataAndTokenInfoMessage(
            TransferErc721MessageWithMetadata(
                TransferErc721Message(
                    BaseMessage(MessageType.TRANSFER_ERC721_WITH_METADATA_AND_TOKEN_INFO),
                    token,
                    receiver,
                    tokenId
                ),
                tokenURI
            ),
            tokenInfo
        );
        return abi.encode(message);
    }

    /**
     * @dev Decodes message for transferring ERC721 with token info. 
     * Returns structure `TransferErc721WithMetadataAndTokenInfoMessage`.
     */
    function decodeTransferErc721WithMetadataAndTokenInfoMessage(
        bytes calldata data
    ) internal pure returns (TransferErc721WithMetadataAndTokenInfoMessage memory) {
        require(
            getMessageType(data) == MessageType.TRANSFER_ERC721_WITH_METADATA_AND_TOKEN_INFO,
            "Message type is not ERC721 transfer with token info"
        );
        return abi.decode(data, (TransferErc721WithMetadataAndTokenInfoMessage));
    }

    /**
     * @dev Encodes message for activating user on schain. 
     * Returns encoded message.
     */
    function encodeActivateUserMessage(address receiver) internal pure returns (bytes memory){
        return _encodeUserStatusMessage(receiver, true);
    }

    /**
     * @dev Encodes message for locking user on schain. 
     * Returns encoded message.
     */
    function encodeLockUserMessage(address receiver) internal pure returns (bytes memory){
        return _encodeUserStatusMessage(receiver, false);
    }

    /**
     * @dev Decodes message for user status. 
     * Returns structure UserStatusMessage.
     */
    function decodeUserStatusMessage(bytes calldata data) internal pure returns (UserStatusMessage memory) {
        require(getMessageType(data) == MessageType.USER_STATUS, "Message type is not User Status");
        return abi.decode(data, (UserStatusMessage));
    }


    /**
     * @dev Encodes message for allowing interchain connection.
     * Returns encoded message.
     */
    function encodeInterchainConnectionMessage(bool isAllowed) internal pure returns (bytes memory) {
        InterchainConnectionMessage memory message = InterchainConnectionMessage(
            BaseMessage(MessageType.INTERCHAIN_CONNECTION),
            isAllowed
        );
        return abi.encode(message);
    }

    /**
     * @dev Decodes message for allowing interchain connection.
     * Returns structure `InterchainConnectionMessage`.
     */
    function decodeInterchainConnectionMessage(bytes calldata data)
        internal
        pure
        returns (InterchainConnectionMessage memory)
    {
        require(getMessageType(data) == MessageType.INTERCHAIN_CONNECTION, "Message type is not Interchain connection");
        return abi.decode(data, (InterchainConnectionMessage));
    }

    /**
     * @dev Encodes message for transferring ERC1155 token.
     * Returns encoded message.
     */
    function encodeTransferErc1155Message(
        address token,
        address receiver,
        uint256 id,
        uint256 amount
    ) internal pure returns (bytes memory) {
        TransferErc1155Message memory message = TransferErc1155Message(
            BaseMessage(MessageType.TRANSFER_ERC1155),
            token,
            receiver,
            id,
            amount
        );
        return abi.encode(message);
    }

    /**
     * @dev Decodes message for transferring ERC1155 token.
     * Returns structure `TransferErc1155Message`.
     */
    function decodeTransferErc1155Message(
        bytes calldata data
    ) internal pure returns (TransferErc1155Message memory) {
        require(getMessageType(data) == MessageType.TRANSFER_ERC1155, "Message type is not ERC1155 transfer");
        return abi.decode(data, (TransferErc1155Message));
    }

    /**
     * @dev Encodes message for transferring ERC1155 with token info.
     * Returns encoded message.
     */
    function encodeTransferErc1155AndTokenInfoMessage(
        address token,
        address receiver,
        uint256 id,
        uint256 amount,
        Erc1155TokenInfo memory tokenInfo
    ) internal pure returns (bytes memory) {
        TransferErc1155AndTokenInfoMessage memory message = TransferErc1155AndTokenInfoMessage(
            TransferErc1155Message(
                BaseMessage(MessageType.TRANSFER_ERC1155_AND_TOKEN_INFO),
                token,
                receiver,
                id,
                amount
            ),
            tokenInfo
        );
        return abi.encode(message);
    }

    /**
     * @dev Decodes message for transferring ERC1155 with token info.
     * Returns structure `TransferErc1155AndTokenInfoMessage`.
     */
    function decodeTransferErc1155AndTokenInfoMessage(
        bytes calldata data
    ) internal pure returns (TransferErc1155AndTokenInfoMessage memory) {
        require(
            getMessageType(data) == MessageType.TRANSFER_ERC1155_AND_TOKEN_INFO,
            "Message type is not ERC1155AndTokenInfo transfer"
        );
        return abi.decode(data, (TransferErc1155AndTokenInfoMessage));
    }

    /**
     * @dev Encodes message for transferring ERC1155 token in batches.
     * Returns encoded message.
     */
    function encodeTransferErc1155BatchMessage(
        address token,
        address receiver,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal pure returns (bytes memory) {
        TransferErc1155BatchMessage memory message = TransferErc1155BatchMessage(
            BaseMessage(MessageType.TRANSFER_ERC1155_BATCH),
            token,
            receiver,
            ids,
            amounts
        );
        return abi.encode(message);
    }

    /**
     * @dev Decodes message for transferring ERC1155 token in batches.
     * Returns structure `TransferErc1155BatchMessage`.
     */
    function decodeTransferErc1155BatchMessage(
        bytes calldata data
    ) internal pure returns (TransferErc1155BatchMessage memory) {
        require(
            getMessageType(data) == MessageType.TRANSFER_ERC1155_BATCH,
            "Message type is not ERC1155Batch transfer"
        );
        return abi.decode(data, (TransferErc1155BatchMessage));
    }

    /**
     * @dev Encodes message for transferring ERC1155 token in batches with token info.
     * Returns encoded message.
     */
    function encodeTransferErc1155BatchAndTokenInfoMessage(
        address token,
        address receiver,
        uint256[] memory ids,
        uint256[] memory amounts,
        Erc1155TokenInfo memory tokenInfo
    ) internal pure returns (bytes memory) {
        TransferErc1155BatchAndTokenInfoMessage memory message = TransferErc1155BatchAndTokenInfoMessage(
            TransferErc1155BatchMessage(
                BaseMessage(MessageType.TRANSFER_ERC1155_BATCH_AND_TOKEN_INFO),
                token,
                receiver,
                ids,
                amounts
            ),
            tokenInfo
        );
        return abi.encode(message);
    }

    /**
     * @dev Decodes message for transferring ERC1155 token in batches with token info.
     * Returns structure `TransferErc1155BatchAndTokenInfoMessage`.
     */
    function decodeTransferErc1155BatchAndTokenInfoMessage(
        bytes calldata data
    ) internal pure returns (TransferErc1155BatchAndTokenInfoMessage memory) {
        require(
            getMessageType(data) == MessageType.TRANSFER_ERC1155_BATCH_AND_TOKEN_INFO,
            "Message type is not ERC1155BatchAndTokenInfo transfer"
        );
        return abi.decode(data, (TransferErc1155BatchAndTokenInfoMessage));
    }

    /**
     * @dev Encodes message for transferring user status on schain.
     * Returns encoded message.
     */
    function _encodeUserStatusMessage(address receiver, bool isActive) private pure returns (bytes memory) {
        UserStatusMessage memory message = UserStatusMessage(
            BaseMessage(MessageType.USER_STATUS),
            receiver,
            isActive
        );
        return abi.encode(message);
    }

}

// SPDX-License-Identifier: AGPL-3.0-only

/**
 *   DepositBox.sol - SKALE Interchain Messaging Agent
 *   Copyright (C) 2021-Present SKALE Labs
 *   @author Artem Payvin
 *   @author Dmytro Stebaiev
 *
 *   SKALE IMA is free software: you can redistribute it and/or modify
 *   it under the terms of the GNU Affero General Public License as published
 *   by the Free Software Foundation, either version 3 of the License, or
 *   (at your option) any later version.
 *
 *   SKALE IMA is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU Affero General Public License for more details.
 *
 *   You should have received a copy of the GNU Affero General Public License
 *   along with SKALE IMA.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity 0.8.16;

import "@skalenetwork/ima-interfaces/mainnet/IDepositBox.sol";

import "./Twin.sol";


/**
 * @title DepositBox
 * @dev Abstract contracts for DepositBoxes on mainnet.
 */
abstract contract DepositBox is IDepositBox, Twin {

    ILinker public linker;

    // schainHash => true if automatic deployment tokens on schain was enabled 
    mapping(bytes32 => bool) private _automaticDeploy;

    bytes32 public constant DEPOSIT_BOX_MANAGER_ROLE = keccak256("DEPOSIT_BOX_MANAGER_ROLE");

    /**
     * @dev Modifier for checking whether schain was not killed.
     */
    modifier whenNotKilled(bytes32 schainHash) {
        require(linker.isNotKilled(schainHash), "Schain is killed");
        _;
    }

    /**
     * @dev Modifier for checking whether schain was killed.
     */
    modifier whenKilled(bytes32 schainHash) {
        require(!linker.isNotKilled(schainHash), "Schain is not killed");
        _;
    }

    /**
     * @dev Modifier for checking whether schainName is not equal to `Mainnet` 
     * and address of receiver is not equal to null before transferring funds from mainnet to schain.
     */
    modifier rightTransaction(string memory schainName, address to) {
        require(
            keccak256(abi.encodePacked(schainName)) != keccak256(abi.encodePacked("Mainnet")),
            "SKALE chain name cannot be Mainnet"
        );
        require(to != address(0), "Receiver address cannot be null");
        _;
    }

    /**
     * @dev Modifier for checking whether schainHash is not equal to `Mainnet` 
     * and sender contract was added as contract processor on schain.
     */
    modifier checkReceiverChain(bytes32 schainHash, address sender) {
        require(
            schainHash != keccak256(abi.encodePacked("Mainnet")) &&
            sender == schainLinks[schainHash],
            "Receiver chain is incorrect"
        );
        _;
    }

    /**
     * @dev Allows Schain owner turn on whitelist of tokens.
     */
    function enableWhitelist(string memory schainName) external override onlySchainOwner(schainName) {
        _automaticDeploy[keccak256(abi.encodePacked(schainName))] = false;
    }

    /**
     * @dev Allows Schain owner turn off whitelist of tokens.
     */
    function disableWhitelist(string memory schainName) external override onlySchainOwner(schainName) {
        _automaticDeploy[keccak256(abi.encodePacked(schainName))] = true;
    }

    function initialize(
        IContractManager contractManagerOfSkaleManagerValue,
        ILinker newLinker,
        IMessageProxyForMainnet messageProxyValue
    )
        public
        override
        virtual
        initializer
    {
        Twin.initialize(contractManagerOfSkaleManagerValue, messageProxyValue);
        _setupRole(LINKER_ROLE, address(newLinker));
        linker = newLinker;
    }

    /**
     * @dev Returns is whitelist enabled on schain.
     */
    function isWhitelisted(string memory schainName) public view override returns (bool) {
        return !_automaticDeploy[keccak256(abi.encodePacked(schainName))];
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/SafeCast.sol)

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
    function toInt248(int256 value) internal pure returns (int248) {
        require(value >= type(int248).min && value <= type(int248).max, "SafeCast: value doesn't fit in 248 bits");
        return int248(value);
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
    function toInt240(int256 value) internal pure returns (int240) {
        require(value >= type(int240).min && value <= type(int240).max, "SafeCast: value doesn't fit in 240 bits");
        return int240(value);
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
    function toInt232(int256 value) internal pure returns (int232) {
        require(value >= type(int232).min && value <= type(int232).max, "SafeCast: value doesn't fit in 232 bits");
        return int232(value);
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
    function toInt224(int256 value) internal pure returns (int224) {
        require(value >= type(int224).min && value <= type(int224).max, "SafeCast: value doesn't fit in 224 bits");
        return int224(value);
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
    function toInt216(int256 value) internal pure returns (int216) {
        require(value >= type(int216).min && value <= type(int216).max, "SafeCast: value doesn't fit in 216 bits");
        return int216(value);
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
    function toInt208(int256 value) internal pure returns (int208) {
        require(value >= type(int208).min && value <= type(int208).max, "SafeCast: value doesn't fit in 208 bits");
        return int208(value);
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
    function toInt200(int256 value) internal pure returns (int200) {
        require(value >= type(int200).min && value <= type(int200).max, "SafeCast: value doesn't fit in 200 bits");
        return int200(value);
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
    function toInt192(int256 value) internal pure returns (int192) {
        require(value >= type(int192).min && value <= type(int192).max, "SafeCast: value doesn't fit in 192 bits");
        return int192(value);
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
    function toInt184(int256 value) internal pure returns (int184) {
        require(value >= type(int184).min && value <= type(int184).max, "SafeCast: value doesn't fit in 184 bits");
        return int184(value);
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
    function toInt176(int256 value) internal pure returns (int176) {
        require(value >= type(int176).min && value <= type(int176).max, "SafeCast: value doesn't fit in 176 bits");
        return int176(value);
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
    function toInt168(int256 value) internal pure returns (int168) {
        require(value >= type(int168).min && value <= type(int168).max, "SafeCast: value doesn't fit in 168 bits");
        return int168(value);
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
    function toInt160(int256 value) internal pure returns (int160) {
        require(value >= type(int160).min && value <= type(int160).max, "SafeCast: value doesn't fit in 160 bits");
        return int160(value);
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
    function toInt152(int256 value) internal pure returns (int152) {
        require(value >= type(int152).min && value <= type(int152).max, "SafeCast: value doesn't fit in 152 bits");
        return int152(value);
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
    function toInt144(int256 value) internal pure returns (int144) {
        require(value >= type(int144).min && value <= type(int144).max, "SafeCast: value doesn't fit in 144 bits");
        return int144(value);
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
    function toInt136(int256 value) internal pure returns (int136) {
        require(value >= type(int136).min && value <= type(int136).max, "SafeCast: value doesn't fit in 136 bits");
        return int136(value);
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
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
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
    function toInt120(int256 value) internal pure returns (int120) {
        require(value >= type(int120).min && value <= type(int120).max, "SafeCast: value doesn't fit in 120 bits");
        return int120(value);
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
    function toInt112(int256 value) internal pure returns (int112) {
        require(value >= type(int112).min && value <= type(int112).max, "SafeCast: value doesn't fit in 112 bits");
        return int112(value);
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
    function toInt104(int256 value) internal pure returns (int104) {
        require(value >= type(int104).min && value <= type(int104).max, "SafeCast: value doesn't fit in 104 bits");
        return int104(value);
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
    function toInt96(int256 value) internal pure returns (int96) {
        require(value >= type(int96).min && value <= type(int96).max, "SafeCast: value doesn't fit in 96 bits");
        return int96(value);
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
    function toInt88(int256 value) internal pure returns (int88) {
        require(value >= type(int88).min && value <= type(int88).max, "SafeCast: value doesn't fit in 88 bits");
        return int88(value);
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
    function toInt80(int256 value) internal pure returns (int80) {
        require(value >= type(int80).min && value <= type(int80).max, "SafeCast: value doesn't fit in 80 bits");
        return int80(value);
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
    function toInt72(int256 value) internal pure returns (int72) {
        require(value >= type(int72).min && value <= type(int72).max, "SafeCast: value doesn't fit in 72 bits");
        return int72(value);
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
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
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
    function toInt56(int256 value) internal pure returns (int56) {
        require(value >= type(int56).min && value <= type(int56).max, "SafeCast: value doesn't fit in 56 bits");
        return int56(value);
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
    function toInt48(int256 value) internal pure returns (int48) {
        require(value >= type(int48).min && value <= type(int48).max, "SafeCast: value doesn't fit in 48 bits");
        return int48(value);
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
    function toInt40(int256 value) internal pure returns (int40) {
        require(value >= type(int40).min && value <= type(int40).max, "SafeCast: value doesn't fit in 40 bits");
        return int40(value);
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
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
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
    function toInt24(int256 value) internal pure returns (int24) {
        require(value >= type(int24).min && value <= type(int24).max, "SafeCast: value doesn't fit in 24 bits");
        return int24(value);
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
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
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
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
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

// SPDX-License-Identifier: AGPL-3.0-only

/**
 *   IDepositBox.sol - SKALE Interchain Messaging Agent
 *   Copyright (C) 2021-Present SKALE Labs
 *   @author Dmytro Stebaiev
 *
 *   SKALE IMA is free software: you can redistribute it and/or modify
 *   it under the terms of the GNU Affero General Public License as published
 *   by the Free Software Foundation, either version 3 of the License, or
 *   (at your option) any later version.
 *
 *   SKALE IMA is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU Affero General Public License for more details.
 *
 *   You should have received a copy of the GNU Affero General Public License
 *   along with SKALE IMA.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity >=0.6.10 <0.9.0;

import "@skalenetwork/skale-manager-interfaces/IContractManager.sol";

import "../IGasReimbursable.sol";
import "../IMessageReceiver.sol";
import "./ILinker.sol";
import "./IMessageProxyForMainnet.sol";
import "./ITwin.sol";


interface IDepositBox is ITwin, IMessageReceiver, IGasReimbursable {
    function initialize(
        IContractManager contractManagerOfSkaleManagerValue,
        ILinker newLinker,
        IMessageProxyForMainnet messageProxyValue
    ) external;
    function enableWhitelist(string memory schainName) external;
    function disableWhitelist(string memory schainName) external;
    function isWhitelisted(string memory schainName) external view returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0-only

/*
    IContractManager.sol - SKALE Manager Interfaces
    Copyright (C) 2021-Present SKALE Labs
    @author Dmytro Stebaeiv

    SKALE Manager Interfaces is free software: you can redistribute it and/or modify
    it under the terms of the GNU Affero General Public License as published
    by the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    SKALE Manager Interfaces is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Affero General Public License for more details.

    You should have received a copy of the GNU Affero General Public License
    along with SKALE Manager Interfaces.  If not, see <https://www.gnu.org/licenses/>.
*/

pragma solidity >=0.6.10 <0.9.0;

interface IContractManager {
    /**
     * @dev Emitted when contract is upgraded.
     */
    event ContractUpgraded(string contractsName, address contractsAddress);

    function initialize() external;
    function setContractsAddress(string calldata contractsName, address newContractsAddress) external;
    function contracts(bytes32 nameHash) external view returns (address);
    function getDelegationPeriodManager() external view returns (address);
    function getBounty() external view returns (address);
    function getValidatorService() external view returns (address);
    function getTimeHelpers() external view returns (address);
    function getConstantsHolder() external view returns (address);
    function getSkaleToken() external view returns (address);
    function getTokenState() external view returns (address);
    function getPunisher() external view returns (address);
    function getContract(string calldata name) external view returns (address);
}

// SPDX-License-Identifier: AGPL-3.0-only

/**
 *   IGasReimbursable.sol - SKALE Interchain Messaging Agent
 *   Copyright (C) 2021-Present SKALE Labs
 *   @author Artem Payvin
 *
 *   SKALE IMA is free software: you can redistribute it and/or modify
 *   it under the terms of the GNU Affero General Public License as published
 *   by the Free Software Foundation, either version 3 of the License, or
 *   (at your option) any later version.
 *
 *   SKALE IMA is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU Affero General Public License for more details.
 *
 *   You should have received a copy of the GNU Affero General Public License
 *   along with SKALE IMA.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity >=0.6.10 <0.9.0;

import "./IMessageReceiver.sol";


interface IGasReimbursable is IMessageReceiver {
    function gasPayer(
        bytes32 schainHash,
        address sender,
        bytes calldata data
    )
        external
        returns (address);
}

// SPDX-License-Identifier: AGPL-3.0-only

/**
 *   IMessageReceiver.sol - SKALE Interchain Messaging Agent
 *   Copyright (C) 2021-Present SKALE Labs
 *   @author Dmytro Stebaiev
 *
 *   SKALE IMA is free software: you can redistribute it and/or modify
 *   it under the terms of the GNU Affero General Public License as published
 *   by the Free Software Foundation, either version 3 of the License, or
 *   (at your option) any later version.
 *
 *   SKALE IMA is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU Affero General Public License for more details.
 *
 *   You should have received a copy of the GNU Affero General Public License
 *   along with SKALE IMA.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity >=0.6.10 <0.9.0;


interface IMessageReceiver {
    function postMessage(
        bytes32 schainHash,
        address sender,
        bytes calldata data
    )
        external;
}

// SPDX-License-Identifier: AGPL-3.0-only

/**
 *   ILinker.sol - SKALE Interchain Messaging Agent
 *   Copyright (C) 2021-Present SKALE Labs
 *   @author Dmytro Stebaiev
 *
 *   SKALE IMA is free software: you can redistribute it and/or modify
 *   it under the terms of the GNU Affero General Public License as published
 *   by the Free Software Foundation, either version 3 of the License, or
 *   (at your option) any later version.
 *
 *   SKALE IMA is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU Affero General Public License for more details.
 *
 *   You should have received a copy of the GNU Affero General Public License
 *   along with SKALE IMA.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity >=0.6.10 <0.9.0;

import "./ITwin.sol";


interface ILinker is ITwin {
    function registerMainnetContract(address newMainnetContract) external;
    function removeMainnetContract(address mainnetContract) external;
    function connectSchain(string calldata schainName, address[] calldata schainContracts) external;
    function kill(string calldata schainName) external;
    function disconnectSchain(string calldata schainName) external;
    function isNotKilled(bytes32 schainHash) external view returns (bool);
    function hasMainnetContract(address mainnetContract) external view returns (bool);
    function hasSchain(string calldata schainName) external view returns (bool connected);
}

// SPDX-License-Identifier: AGPL-3.0-only

/**
 *   IMessageProxyForMainnet.sol - SKALE Interchain Messaging Agent
 *   Copyright (C) 2021-Present SKALE Labs
 *   @author Dmytro Stebaiev
 *
 *   SKALE IMA is free software: you can redistribute it and/or modify
 *   it under the terms of the GNU Affero General Public License as published
 *   by the Free Software Foundation, either version 3 of the License, or
 *   (at your option) any later version.
 *
 *   SKALE IMA is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU Affero General Public License for more details.
 *
 *   You should have received a copy of the GNU Affero General Public License
 *   along with SKALE IMA.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity >=0.6.10 <0.9.0;

import "../IMessageProxy.sol";
import "./ICommunityPool.sol";

interface IMessageProxyForMainnet is IMessageProxy {
    function setCommunityPool(ICommunityPool newCommunityPoolAddress) external;
    function setNewHeaderMessageGasCost(uint256 newHeaderMessageGasCost) external;
    function setNewMessageGasCost(uint256 newMessageGasCost) external;
    function pause(string calldata schainName) external;
    function resume(string calldata schainName) external;
    function addReimbursedContract(string memory schainName, address reimbursedContract) external;
    function removeReimbursedContract(string memory schainName, address reimbursedContract) external;
    function messageInProgress() external view returns (bool);
    function isPaused(bytes32 schainHash) external view returns (bool);
    function isReimbursedContract(bytes32 schainHash, address contractAddress) external view returns (bool);
    function getReimbursedContractsLength(bytes32 schainHash) external view returns (uint256);
    function getReimbursedContractsRange(
        bytes32 schainHash,
        uint256 from,
        uint256 to
    )
        external
        view
        returns (address[] memory contractsInRange);
}

// SPDX-License-Identifier: AGPL-3.0-only

/**
 *   ITwin.sol - SKALE Interchain Messaging Agent
 *   Copyright (C) 2021-Present SKALE Labs
 *   @author Dmytro Stebaiev
 *
 *   SKALE IMA is free software: you can redistribute it and/or modify
 *   it under the terms of the GNU Affero General Public License as published
 *   by the Free Software Foundation, either version 3 of the License, or
 *   (at your option) any later version.
 *
 *   SKALE IMA is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU Affero General Public License for more details.
 *
 *   You should have received a copy of the GNU Affero General Public License
 *   along with SKALE IMA.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity >=0.6.10 <0.9.0;

import "./ISkaleManagerClient.sol";

interface ITwin is ISkaleManagerClient {
    function addSchainContract(string calldata schainName, address contractReceiver) external;
    function removeSchainContract(string calldata schainName) external;
    function hasSchainContract(string calldata schainName) external view returns (bool);
    function getSchainContract(bytes32 schainHash) external view returns (address);
}

// SPDX-License-Identifier: AGPL-3.0-only

/**
 *   ISkaleManagerClient.sol - SKALE Interchain Messaging Agent
 *   Copyright (C) 2021-Present SKALE Labs
 *   @author Dmytro Stebaiev
 *
 *   SKALE IMA is free software: you can redistribute it and/or modify
 *   it under the terms of the GNU Affero General Public License as published
 *   by the Free Software Foundation, either version 3 of the License, or
 *   (at your option) any later version.
 *
 *   SKALE IMA is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU Affero General Public License for more details.
 *
 *   You should have received a copy of the GNU Affero General Public License
 *   along with SKALE IMA.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity >=0.6.10 <0.9.0;

import "@skalenetwork/skale-manager-interfaces/IContractManager.sol";


interface ISkaleManagerClient {
    function initialize(IContractManager newContractManagerOfSkaleManager) external;
    function isSchainOwner(address sender, bytes32 schainHash) external view returns (bool);
    function isAgentAuthorized(bytes32 schainHash, address sender) external view returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0-only

/**
 *   IMessageProxy.sol - SKALE Interchain Messaging Agent
 *   Copyright (C) 2021-Present SKALE Labs
 *   @author Dmytro Stebaiev
 *
 *   SKALE IMA is free software: you can redistribute it and/or modify
 *   it under the terms of the GNU Affero General Public License as published
 *   by the Free Software Foundation, either version 3 of the License, or
 *   (at your option) any later version.
 *
 *   SKALE IMA is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU Affero General Public License for more details.
 *
 *   You should have received a copy of the GNU Affero General Public License
 *   along with SKALE IMA.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity >=0.6.10 <0.9.0;


interface IMessageProxy {

    /**
     * @dev Structure that describes message. Should contain sender of message,
     * destination contract on schain that will receiver message,
     * data that contains all needed info about token or ETH.
     */
    struct Message {
        address sender;
        address destinationContract;
        bytes data;
    }

    /**
     * @dev Structure that contains fields for bls signature.
     */
    struct Signature {
        uint256[2] blsSignature;
        uint256 hashA;
        uint256 hashB;
        uint256 counter;
    }

    function addConnectedChain(string calldata schainName) external;
    function postIncomingMessages(
        string calldata fromSchainName,
        uint256 startingCounter,
        Message[] calldata messages,
        Signature calldata sign
    ) external;
    function setNewGasLimit(uint256 newGasLimit) external;
    function registerExtraContractForAll(address extraContract) external;
    function removeExtraContractForAll(address extraContract) external;    
    function removeConnectedChain(string memory schainName) external;
    function postOutgoingMessage(
        bytes32 targetChainHash,
        address targetContract,
        bytes memory data
    ) external;
    function registerExtraContract(string memory chainName, address extraContract) external;
    function removeExtraContract(string memory schainName, address extraContract) external;
    function setVersion(string calldata newVersion) external;
    function isContractRegistered(
        bytes32 schainHash,
        address contractAddress
    ) external view returns (bool);
    function getContractRegisteredLength(bytes32 schainHash) external view returns (uint256);
    function getContractRegisteredRange(
        bytes32 schainHash,
        uint256 from,
        uint256 to
    )
        external
        view
        returns (address[] memory);
    function getOutgoingMessagesCounter(string calldata targetSchainName) external view returns (uint256);
    function getIncomingMessagesCounter(string calldata fromSchainName) external view returns (uint256);
    function isConnectedChain(string memory schainName) external view returns (bool);
    function getLastOutgoingMessageBlockId(string memory targetSchainName) external view returns (uint);
}

// SPDX-License-Identifier: AGPL-3.0-only

/**
 *   ICommunityPool.sol - SKALE Interchain Messaging Agent
 *   Copyright (C) 2021-Present SKALE Labs
 *   @author Dmytro Stebaiev
 *
 *   SKALE IMA is free software: you can redistribute it and/or modify
 *   it under the terms of the GNU Affero General Public License as published
 *   by the Free Software Foundation, either version 3 of the License, or
 *   (at your option) any later version.
 *
 *   SKALE IMA is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU Affero General Public License for more details.
 *
 *   You should have received a copy of the GNU Affero General Public License
 *   along with SKALE IMA.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity >=0.6.10 <0.9.0;

import "@skalenetwork/skale-manager-interfaces/IContractManager.sol";


import "./ILinker.sol";
import "./IMessageProxyForMainnet.sol";
import "./ITwin.sol";


interface ICommunityPool is ITwin {
    function initialize(
        IContractManager contractManagerOfSkaleManagerValue,
        ILinker linker,
        IMessageProxyForMainnet messageProxyValue
    ) external;
    function refundGasByUser(bytes32 schainHash, address payable node, address user, uint gas) external returns (uint);
    function rechargeUserWallet(string calldata schainName, address user) external payable;
    function withdrawFunds(string calldata schainName, uint amount) external;
    function setMinTransactionGas(uint newMinTransactionGas) external;
    function setMultiplier(uint newMultiplierNumerator, uint newMultiplierDivider) external;
    function refundGasBySchainWallet(
        bytes32 schainHash,
        address payable node,
        uint gas
    ) external returns (bool);
    function getBalance(address user, string calldata schainName) external view returns (uint);
    function checkUserBalance(bytes32 schainHash, address receiver) external view returns (bool);
    function getRecommendedRechargeAmount(bytes32 schainHash, address receiver) external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0-only

/**
 *   Twin.sol - SKALE Interchain Messaging Agent
 *   Copyright (C) 2021-Present SKALE Labs
 *   @author Artem Payvin
 *   @author Dmytro Stebaiev
 *   @author Vadim Yavorsky
 *
 *   SKALE IMA is free software: you can redistribute it and/or modify
 *   it under the terms of the GNU Affero General Public License as published
 *   by the Free Software Foundation, either version 3 of the License, or
 *   (at your option) any later version.
 *
 *   SKALE IMA is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU Affero General Public License for more details.
 *
 *   You should have received a copy of the GNU Affero General Public License
 *   along with SKALE IMA.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity 0.8.16;

import "@skalenetwork/ima-interfaces/mainnet/ITwin.sol";

import "./MessageProxyForMainnet.sol";
import "./SkaleManagerClient.sol";

/**
 * @title Twin
 * @dev Runs on Mainnet,
 * contains logic for connecting paired contracts on Mainnet and on Schain.
 */
abstract contract Twin is SkaleManagerClient, ITwin {

    IMessageProxyForMainnet public messageProxy;
    mapping(bytes32 => address) public schainLinks;
    bytes32 public constant LINKER_ROLE = keccak256("LINKER_ROLE");

    /**
     * @dev Modifier for checking whether caller is MessageProxy contract.
     */
    modifier onlyMessageProxy() {
        require(msg.sender == address(messageProxy), "Sender is not a MessageProxy");
        _;
    }

    /**
     * @dev Binds a contract on mainnet with their twin on schain.
     *
     * Requirements:
     *
     * - `msg.sender` must be schain owner or has required role.
     * - SKALE chain must not already be added.
     * - Address of contract on schain must be non-zero.
     */
    function addSchainContract(string calldata schainName, address contractReceiver) external override {
        bytes32 schainHash = keccak256(abi.encodePacked(schainName));
        require(
            hasRole(LINKER_ROLE, msg.sender) ||
            isSchainOwner(msg.sender, schainHash), "Not authorized caller"
        );
        require(schainLinks[schainHash] == address(0), "SKALE chain is already set");
        require(contractReceiver != address(0), "Incorrect address of contract receiver on Schain");
        schainLinks[schainHash] = contractReceiver;
    }

    /**
     * @dev Removes connection with contract on schain.
     *
     * Requirements:
     *
     * - `msg.sender` must be schain owner or has required role.
     * - SKALE chain must already be set.
     */
    function removeSchainContract(string calldata schainName) external override {
        bytes32 schainHash = keccak256(abi.encodePacked(schainName));
        require(
            hasRole(LINKER_ROLE, msg.sender) ||
            isSchainOwner(msg.sender, schainHash), "Not authorized caller"
        );
        require(schainLinks[schainHash] != address(0), "SKALE chain is not set");
        delete schainLinks[schainHash];
    }

    /**
     * @dev Returns true if mainnet contract and schain contract are connected together for transferring messages.
     */
    function hasSchainContract(string calldata schainName) external view override returns (bool) {
        return schainLinks[keccak256(abi.encodePacked(schainName))] != address(0);
    }
    
    function initialize(
        IContractManager contractManagerOfSkaleManagerValue,
        IMessageProxyForMainnet newMessageProxy
    )
        public
        virtual
        initializer
    {
        SkaleManagerClient.initialize(contractManagerOfSkaleManagerValue);
        messageProxy = newMessageProxy;
    }

    function getSchainContract(bytes32 schainHash) public override view returns (address) {
        require(
            schainLinks[schainHash] != address(0),
            "Destination contract must be defined"
        );
        return schainLinks[schainHash];
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

/**
 *   MessageProxyForMainnet.sol - SKALE Interchain Messaging Agent
 *   Copyright (C) 2019-Present SKALE Labs
 *   @author Artem Payvin
 *
 *   SKALE IMA is free software: you can redistribute it and/or modify
 *   it under the terms of the GNU Affero General Public License as published
 *   by the Free Software Foundation, either version 3 of the License, or
 *   (at your option) any later version.
 *
 *   SKALE IMA is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU Affero General Public License for more details.
 *
 *   You should have received a copy of the GNU Affero General Public License
 *   along with SKALE IMA.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity 0.8.16;

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@skalenetwork/skale-manager-interfaces/IWallets.sol";
import "@skalenetwork/skale-manager-interfaces/ISchains.sol";
import "@skalenetwork/ima-interfaces/mainnet/IMessageProxyForMainnet.sol";
import "@skalenetwork/ima-interfaces/mainnet/ICommunityPool.sol";
import "@skalenetwork/skale-manager-interfaces/ISchainsInternal.sol";


import "../MessageProxy.sol";
import "./SkaleManagerClient.sol";
import "./CommunityPool.sol";


/**
 * @title Message Proxy for Mainnet
 * @dev Runs on Mainnet, contains functions to manage the incoming messages from
 * `targetSchainName` and outgoing messages to `fromSchainName`. Every SKALE chain with
 * IMA is therefore connected to MessageProxyForMainnet.
 *
 * Messages from SKALE chains are signed using BLS threshold signatures from the
 * nodes in the chain. Since Ethereum Mainnet has no BLS public key, mainnet
 * messages do not need to be signed.
 */
contract MessageProxyForMainnet is SkaleManagerClient, MessageProxy, IMessageProxyForMainnet {

    using AddressUpgradeable for address;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    struct Pause {
        bool paused;
    }

    bytes32 public constant PAUSABLE_ROLE = keccak256(abi.encodePacked("PAUSABLE_ROLE"));

    /**
     * 16 Agents
     * Synchronize time with time.nist.gov
     * Every agent checks if it is their time slot
     * Time slots are in increments of 10 seconds
     * At the start of their slot each agent:
     * For each connected schain:
     * Read incoming counter on the dst chain
     * Read outgoing counter on the src chain
     * Calculate the difference outgoing - incoming
     * Call postIncomingMessages function passing (un)signed message array
     * ID of this schain, Chain 0 represents ETH mainnet,
    */

    ICommunityPool public communityPool;

    uint256 public headerMessageGasCost;
    uint256 public messageGasCost;

    // disable detector until slither will fix this issue
    // https://github.com/crytic/slither/issues/456
    // slither-disable-next-line uninitialized-state
    mapping(bytes32 => EnumerableSetUpgradeable.AddressSet) private _registryContracts;
    string public version;
    bool public override messageInProgress;

    // schainHash   => Pause structure
    mapping(bytes32 => Pause) public pauseInfo;

    //   schainHash => Set of addresses of reimbursed contracts
    mapping(bytes32 => EnumerableSetUpgradeable.AddressSet) private _reimbursedContracts;

    /**
     * @dev Emitted when gas cost for message header was changed.
     */
    event GasCostMessageHeaderWasChanged(
        uint256 oldValue,
        uint256 newValue
    );

    /**
     * @dev Emitted when gas cost for message was changed.
     */
    event GasCostMessageWasChanged(
        uint256 oldValue,
        uint256 newValue
    );

    /**
     * @dev Emitted when the schain is paused
     */
    event SchainPaused(
        bytes32 indexed schainHash
    );

    /**
     * @dev Emitted when the schain is resumed
     */
    event SchainResumed(
        bytes32 indexed schainHash
    );

    /**
     * @dev Emitted when reimbursed contract was added
     */
    event ReimbursedContractAdded(
        bytes32 indexed schainHash,
        address contractAddress
    );

    /**
     * @dev Emitted when reimbursed contract was removed
     */
    event ReimbursedContractRemoved(
        bytes32 indexed schainHash,
        address contractAddress
    );

    /**
     * @dev Reentrancy guard for postIncomingMessages.
     */
    modifier messageInProgressLocker() {
        require(!messageInProgress, "Message is in progress");
        messageInProgress = true;
        _;
        messageInProgress = false;
    }

    /**
     * @dev Modifier to make a function callable only when IMA is active.
     */
    modifier whenNotPaused(bytes32 schainHash) {
        require(!isPaused(schainHash), "IMA is paused");
        _;
    }

    /**
     * @dev Allows `msg.sender` to connect schain with MessageProxyOnMainnet for transferring messages.
     *
     * Requirements:
     *
     * - Schain name must not be `Mainnet`.
     */
    function addConnectedChain(string calldata schainName) external override {
        bytes32 schainHash = keccak256(abi.encodePacked(schainName));
        require(ISchainsInternal(
            contractManagerOfSkaleManager.getContract("SchainsInternal")
        ).isSchainExist(schainHash), "SKALE chain must exist");
        _addConnectedChain(schainHash);
    }

    /**
     * @dev Allows owner of the contract to set CommunityPool address for gas reimbursement.
     *
     * Requirements:
     *
     * - `msg.sender` must be granted as DEFAULT_ADMIN_ROLE.
     * - Address of CommunityPool contract must not be null.
     */
    function setCommunityPool(ICommunityPool newCommunityPoolAddress) external override {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Not authorized caller");
        require(address(newCommunityPoolAddress) != address(0), "CommunityPool address has to be set");
        communityPool = newCommunityPoolAddress;
    }

    /**
     * @dev Allows `msg.sender` to register extra contract for being able to transfer messages from custom contracts.
     *
     * Requirements:
     *
     * - `msg.sender` must be granted as EXTRA_CONTRACT_REGISTRAR_ROLE.
     * - Schain name must not be `Mainnet`.
     */
    function registerExtraContract(string memory schainName, address extraContract) external override {
        bytes32 schainHash = keccak256(abi.encodePacked(schainName));
        require(
            hasRole(EXTRA_CONTRACT_REGISTRAR_ROLE, msg.sender) ||
            isSchainOwner(msg.sender, schainHash),
            "Not enough permissions to register extra contract"
        );
        require(schainHash != MAINNET_HASH, "Schain hash can not be equal Mainnet");
        _registerExtraContract(schainHash, extraContract);
    }

    /**
     * @dev Allows `msg.sender` to remove extra contract,
     * thus `extraContract` will no longer be available to transfer messages from mainnet to schain.
     *
     * Requirements:
     *
     * - `msg.sender` must be granted as EXTRA_CONTRACT_REGISTRAR_ROLE.
     * - Schain name must not be `Mainnet`.
     */
    function removeExtraContract(string memory schainName, address extraContract) external override {
        bytes32 schainHash = keccak256(abi.encodePacked(schainName));
        require(
            hasRole(EXTRA_CONTRACT_REGISTRAR_ROLE, msg.sender) ||
            isSchainOwner(msg.sender, schainHash),
            "Not enough permissions to register extra contract"
        );
        require(schainHash != MAINNET_HASH, "Schain hash can not be equal Mainnet");
        _removeExtraContract(schainHash, extraContract);
        if (_reimbursedContracts[schainHash].contains(extraContract)) {
            _removeReimbursedContract(schainHash, extraContract);
        }
    }

    /**
     * @dev Allows `msg.sender` to add reimbursed contract for being able to reimburse gas amount from CommunityPool
     * during message transfers from custom contracts.
     * 
     * Requirements:
     * 
     * - `msg.sender` must be granted as EXTRA_CONTRACT_REGISTRAR_ROLE or owner of given `schainName`.
     * - Schain name must not be `Mainnet`.
     * - `reimbursedContract` should be registered as extra contract
     */
    function addReimbursedContract(string memory schainName, address reimbursedContract) external override {
        bytes32 schainHash = keccak256(abi.encodePacked(schainName));
        require(schainHash != MAINNET_HASH, "Schain hash can not be equal Mainnet");        
        require(
            hasRole(EXTRA_CONTRACT_REGISTRAR_ROLE, msg.sender) ||
            isSchainOwner(msg.sender, schainHash),
            "Not enough permissions to add reimbursed contract"
        );
        require(reimbursedContract.isContract(), "Given address is not a contract");
        require(isContractRegistered(schainHash, reimbursedContract), "Contract is not registered");
        require(!_reimbursedContracts[schainHash].contains(reimbursedContract), "Reimbursed contract is already added");
        _reimbursedContracts[schainHash].add(reimbursedContract);
        emit ReimbursedContractAdded(schainHash, reimbursedContract);
    }

    /**
     * @dev Allows `msg.sender` to remove reimbursed contract,
     * thus `reimbursedContract` will no longer be available to reimburse gas amount from CommunityPool during
     * message transfers from mainnet to schain.
     * 
     * Requirements:
     * 
     * - `msg.sender` must be granted as EXTRA_CONTRACT_REGISTRAR_ROLE or owner of given `schainName`.
     * - Schain name must not be `Mainnet`.
     */
    function removeReimbursedContract(string memory schainName, address reimbursedContract) external override {
        bytes32 schainHash = keccak256(abi.encodePacked(schainName));
        require(schainHash != MAINNET_HASH, "Schain hash can not be equal Mainnet");
        require(
            hasRole(EXTRA_CONTRACT_REGISTRAR_ROLE, msg.sender) ||
            isSchainOwner(msg.sender, schainHash),
            "Not enough permissions to remove reimbursed contract"
        );
        require(_reimbursedContracts[schainHash].contains(reimbursedContract), "Reimbursed contract is not added");
        _removeReimbursedContract(schainHash, reimbursedContract);
    }

    /**
     * @dev Posts incoming message from `fromSchainName`.
     *
     * Requirements:
     *
     * - `msg.sender` must be authorized caller.
     * - `fromSchainName` must be initialized.
     * - `startingCounter` must be equal to the chain's incoming message counter.
     * - If destination chain is Mainnet, message signature must be valid.
     */
    function postIncomingMessages(
        string calldata fromSchainName,
        uint256 startingCounter,
        Message[] calldata messages,
        Signature calldata sign
    )
        external
        override(IMessageProxy, MessageProxy)
        messageInProgressLocker
        whenNotPaused(keccak256(abi.encodePacked(fromSchainName)))
    {
        uint256 gasTotal = gasleft();
        bytes32 fromSchainHash = keccak256(abi.encodePacked(fromSchainName));
        require(isAgentAuthorized(fromSchainHash, msg.sender), "Agent is not authorized");
        require(_checkSchainBalance(fromSchainHash), "Schain wallet has not enough funds");
        require(connectedChains[fromSchainHash].inited, "Chain is not initialized");
        require(messages.length <= MESSAGES_LENGTH, "Too many messages");
        require(
            startingCounter == connectedChains[fromSchainHash].incomingMessageCounter,
            "Starting counter is not equal to incoming message counter");

        require(_verifyMessages(
            fromSchainName,
            _hashedArray(messages, startingCounter, fromSchainName), sign),
            "Signature is not verified");
        uint additionalGasPerMessage =
            (gasTotal - gasleft() + headerMessageGasCost + messages.length * messageGasCost) / messages.length;
        uint notReimbursedGas = 0;
        connectedChains[fromSchainHash].incomingMessageCounter += messages.length;
        for (uint256 i = 0; i < messages.length; i++) {
            gasTotal = gasleft();
            if (isReimbursedContract(fromSchainHash, messages[i].destinationContract)) {
                address receiver = _getGasPayer(fromSchainHash, messages[i], startingCounter + i);
                _callReceiverContract(fromSchainHash, messages[i], startingCounter + i);
                notReimbursedGas += communityPool.refundGasByUser(
                    fromSchainHash,
                    payable(msg.sender),
                    receiver,
                    gasTotal - gasleft() + additionalGasPerMessage
                );
            } else {
                _callReceiverContract(fromSchainHash, messages[i], startingCounter + i);
                notReimbursedGas += gasTotal - gasleft() + additionalGasPerMessage;
            }
        }
        communityPool.refundGasBySchainWallet(fromSchainHash, payable(msg.sender), notReimbursedGas);
    }

    /**
     * @dev Sets headerMessageGasCost to a new value.
     *
     * Requirements:
     *
     * - `msg.sender` must be granted as CONSTANT_SETTER_ROLE.
     */
    function setNewHeaderMessageGasCost(uint256 newHeaderMessageGasCost) external override onlyConstantSetter {
        emit GasCostMessageHeaderWasChanged(headerMessageGasCost, newHeaderMessageGasCost);
        headerMessageGasCost = newHeaderMessageGasCost;
    }

    /**
     * @dev Sets messageGasCost to a new value.
     *
     * Requirements:
     *
     * - `msg.sender` must be granted as CONSTANT_SETTER_ROLE.
     */
    function setNewMessageGasCost(uint256 newMessageGasCost) external override onlyConstantSetter {
        emit GasCostMessageWasChanged(messageGasCost, newMessageGasCost);
        messageGasCost = newMessageGasCost;
    }

    /**
     * @dev Sets new version of contracts on mainnet
     *
     * Requirements:
     *
     * - `msg.sender` must be granted DEFAULT_ADMIN_ROLE.
     */
    function setVersion(string calldata newVersion) external override {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "DEFAULT_ADMIN_ROLE is required");
        emit VersionUpdated(version, newVersion);
        version = newVersion;
    }

    /**
     * @dev Allows PAUSABLE_ROLE to pause IMA bridge unlimited
     *
     * Requirements:
     *
     * - IMA bridge to current schain was not paused
     * - Sender should be PAUSABLE_ROLE
     */
    function pause(string calldata schainName) external override {
        bytes32 schainHash = keccak256(abi.encodePacked(schainName));
        require(hasRole(PAUSABLE_ROLE, msg.sender), "Incorrect sender");
        require(!pauseInfo[schainHash].paused, "Already paused");
        pauseInfo[schainHash].paused = true;
        emit SchainPaused(schainHash);
    }

/**
     * @dev Allows DEFAULT_ADMIN_ROLE or schain owner to resume IMA bridge
     *
     * Requirements:
     *
     * - IMA bridge to current schain was paused
     * - Sender should be DEFAULT_ADMIN_ROLE or schain owner
     */
    function resume(string calldata schainName) external override {
        bytes32 schainHash = keccak256(abi.encodePacked(schainName));
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender) || isSchainOwner(msg.sender, schainHash), "Incorrect sender");
        require(pauseInfo[schainHash].paused, "Already unpaused");
        pauseInfo[schainHash].paused = false;
        emit SchainResumed(schainHash);
    }

    /**
     * @dev Should return length of reimbursed contracts by schainHash.
     */
    function getReimbursedContractsLength(bytes32 schainHash) external view override returns (uint256) {
        return _reimbursedContracts[schainHash].length();
    }

    /**
     * @dev Should return a range of reimbursed contracts by schainHash.
     * 
     * Requirements:
     * range should be less or equal 10 contracts
     */
    function getReimbursedContractsRange(
        bytes32 schainHash,
        uint256 from,
        uint256 to
    )
        external
        view
        override
        returns (address[] memory contractsInRange)
    {
        require(
            from < to && to - from <= 10 && to <= _reimbursedContracts[schainHash].length(),
            "Range is incorrect"
        );
        contractsInRange = new address[](to - from);
        for (uint256 i = from; i < to; i++) {
            contractsInRange[i - from] = _reimbursedContracts[schainHash].at(i);
        }
    }

    /**
     * @dev Creates a new MessageProxyForMainnet contract.
     */
    function initialize(IContractManager contractManagerOfSkaleManagerValue) public virtual override initializer {
        SkaleManagerClient.initialize(contractManagerOfSkaleManagerValue);
        MessageProxy.initializeMessageProxy(1e6);
        headerMessageGasCost = 92251;
        messageGasCost = 9000;
    }

    /**
     * @dev PostOutgoingMessage function with whenNotPaused modifier
     */
    function postOutgoingMessage(
        bytes32 targetChainHash,
        address targetContract,
        bytes memory data
    )
        public
        override(IMessageProxy, MessageProxy)
        whenNotPaused(targetChainHash)
    {
        super.postOutgoingMessage(targetChainHash, targetContract, data);
    }

    /**
     * @dev Checks whether chain is currently connected.
     *
     * Note: Mainnet chain does not have a public key, and is implicitly
     * connected to MessageProxy.
     *
     * Requirements:
     *
     * - `schainName` must not be Mainnet.
     */
    function isConnectedChain(
        string memory schainName
    )
        public
        view
        override(IMessageProxy, MessageProxy)
        returns (bool)
    {
        require(keccak256(abi.encodePacked(schainName)) != MAINNET_HASH, "Schain id can not be equal Mainnet");
        return super.isConnectedChain(schainName);
    }

    /**
     * @dev Returns true if IMA to schain is paused.
     */
    function isPaused(bytes32 schainHash) public view override returns (bool) {
        return pauseInfo[schainHash].paused;
    }

    /**
     * @dev Returns true if message to the contract should be reimbursed from CommunityPool.
     */
    function isReimbursedContract(bytes32 schainHash, address contractAddress) public view override returns (bool) {
        return
            isContractRegistered(bytes32(0), contractAddress) ||
            _reimbursedContracts[schainHash].contains(contractAddress);
    }

    // private

    function _authorizeOutgoingMessageSender(bytes32 targetChainHash) internal view override {
        require(
            isContractRegistered(bytes32(0), msg.sender)
                || isContractRegistered(targetChainHash, msg.sender)
                || isSchainOwner(msg.sender, targetChainHash),
            "Sender contract is not registered"
        );
    }

    /**
     * @dev Converts calldata structure to memory structure and checks
     * whether message BLS signature is valid.
     */
    function _verifyMessages(
        string calldata fromSchainName,
        bytes32 hashedMessages,
        MessageProxyForMainnet.Signature calldata sign
    )
        internal
        view
        returns (bool)
    {
        return ISchains(
            contractManagerOfSkaleManager.getContract("Schains")
        ).verifySchainSignature(
            sign.blsSignature[0],
            sign.blsSignature[1],
            hashedMessages,
            sign.counter,
            sign.hashA,
            sign.hashB,
            fromSchainName
        );
    }

    /**
     * @dev Checks whether balance of schain wallet is sufficient for
     * for reimbursement custom message.
     */
    function _checkSchainBalance(bytes32 schainHash) internal view returns (bool) {
        return IWallets(
            payable(contractManagerOfSkaleManager.getContract("Wallets"))
        ).getSchainBalance(schainHash) >= (MESSAGES_LENGTH + 1) * gasLimit * tx.gasprice;
    }

    /**
     * @dev Returns list of registered custom extra contracts.
     */
    function _getRegistryContracts()
        internal
        view
        override
        returns (mapping(bytes32 => EnumerableSetUpgradeable.AddressSet) storage)
    {
        return _registryContracts;
    }


    function _removeReimbursedContract(bytes32 schainHash, address reimbursedContract) private {
        _reimbursedContracts[schainHash].remove(reimbursedContract);
        emit ReimbursedContractRemoved(schainHash, reimbursedContract);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

/**
 *   SkaleManagerClient.sol - SKALE Interchain Messaging Agent
 *   Copyright (C) 2021-Present SKALE Labs
 *   @author Artem Payvin
 *
 *   SKALE IMA is free software: you can redistribute it and/or modify
 *   it under the terms of the GNU Affero General Public License as published
 *   by the Free Software Foundation, either version 3 of the License, or
 *   (at your option) any later version.
 *
 *   SKALE IMA is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU Affero General Public License for more details.
 *
 *   You should have received a copy of the GNU Affero General Public License
 *   along with SKALE IMA.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity 0.8.16;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@skalenetwork/skale-manager-interfaces/IContractManager.sol";
import "@skalenetwork/skale-manager-interfaces/ISchainsInternal.sol";
import "@skalenetwork/ima-interfaces/mainnet/ISkaleManagerClient.sol";


/**
 * @title SkaleManagerClient - contract that knows ContractManager
 * and makes calls to SkaleManager contracts.
 */
contract SkaleManagerClient is Initializable, AccessControlEnumerableUpgradeable, ISkaleManagerClient {

    IContractManager public contractManagerOfSkaleManager;

    /**
     * @dev Modifier for checking whether caller is owner of SKALE chain.
     */
    modifier onlySchainOwner(string memory schainName) {
        require(
            isSchainOwner(msg.sender, _schainHash(schainName)),
            "Sender is not an Schain owner"
        );
        _;
    }

    /**
     * @dev Modifier for checking whether caller is owner of SKALE chain.
     */
    modifier onlySchainOwnerByHash(bytes32 schainHash) {
        require(
            isSchainOwner(msg.sender, schainHash),
            "Sender is not an Schain owner"
        );
        _;
    }

    /**
     * @dev initialize - sets current address of ContractManager of SkaleManager.
     * @param newContractManagerOfSkaleManager - current address of ContractManager of SkaleManager.
     */
    function initialize(
        IContractManager newContractManagerOfSkaleManager
    )
        public
        override
        virtual
        initializer
    {
        AccessControlEnumerableUpgradeable.__AccessControlEnumerable_init();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        contractManagerOfSkaleManager = newContractManagerOfSkaleManager;
    }

    /**
     * @dev Checks whether sender is owner of SKALE chain
     */
    function isSchainOwner(address sender, bytes32 schainHash) public view override returns (bool) {
        address skaleChainsInternal = contractManagerOfSkaleManager.getContract("SchainsInternal");
        return ISchainsInternal(skaleChainsInternal).isOwnerAddress(sender, schainHash);
    }

    function isAgentAuthorized(bytes32 schainHash, address sender) public view override returns (bool) {
        address skaleChainsInternal = contractManagerOfSkaleManager.getContract("SchainsInternal");
        return ISchainsInternal(skaleChainsInternal).isNodeAddressesInGroup(schainHash, sender);
    }

    function _schainHash(string memory schainName) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(schainName));
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

/*
    IWallets - SKALE Manager Interfaces
    Copyright (C) 2021-Present SKALE Labs
    @author Dmytro Stebaeiv

    SKALE Manager Interfaces is free software: you can redistribute it and/or modify
    it under the terms of the GNU Affero General Public License as published
    by the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    SKALE Manager Interfaces is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Affero General Public License for more details.

    You should have received a copy of the GNU Affero General Public License
    along with SKALE Manager Interfaces.  If not, see <https://www.gnu.org/licenses/>.
*/

pragma solidity >=0.6.10 <0.9.0;

interface IWallets {
    /**
     * @dev Emitted when the validator wallet was funded
     */
    event ValidatorWalletRecharged(address sponsor, uint amount, uint validatorId);

    /**
     * @dev Emitted when the schain wallet was funded
     */
    event SchainWalletRecharged(address sponsor, uint amount, bytes32 schainHash);

    /**
     * @dev Emitted when the node received a refund from validator to its wallet
     */
    event NodeRefundedByValidator(address node, uint validatorId, uint amount);

    /**
     * @dev Emitted when the node received a refund from schain to its wallet
     */
    event NodeRefundedBySchain(address node, bytes32 schainHash, uint amount);

    /**
     * @dev Emitted when the validator withdrawn funds from validator wallet
     */
    event WithdrawFromValidatorWallet(uint indexed validatorId, uint amount);

    /**
     * @dev Emitted when the schain owner withdrawn funds from schain wallet
     */
    event WithdrawFromSchainWallet(bytes32 indexed schainHash, uint amount);

    receive() external payable;
    function refundGasByValidator(uint validatorId, address payable spender, uint spentGas) external;
    function refundGasByValidatorToSchain(uint validatorId, bytes32 schainHash) external;
    function refundGasBySchain(bytes32 schainId, address payable spender, uint spentGas, bool isDebt) external;
    function withdrawFundsFromSchainWallet(address payable schainOwner, bytes32 schainHash) external;
    function withdrawFundsFromValidatorWallet(uint amount) external;
    function rechargeValidatorWallet(uint validatorId) external payable;
    function rechargeSchainWallet(bytes32 schainId) external payable;
    function getSchainBalance(bytes32 schainHash) external view returns (uint);
    function getValidatorBalance(uint validatorId) external view returns (uint);
}

// SPDX-License-Identifier: AGPL-3.0-only

/*
    ISchains.sol - SKALE Manager Interfaces
    Copyright (C) 2021-Present SKALE Labs
    @author Dmytro Stebaeiv

    SKALE Manager Interfaces is free software: you can redistribute it and/or modify
    it under the terms of the GNU Affero General Public License as published
    by the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    SKALE Manager Interfaces is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Affero General Public License for more details.

    You should have received a copy of the GNU Affero General Public License
    along with SKALE Manager Interfaces.  If not, see <https://www.gnu.org/licenses/>.
*/

pragma solidity >=0.6.10 <0.9.0;

interface ISchains {

    struct SchainOption {
        string name;
        bytes value;
    }
    
    /**
     * @dev Emitted when an schain is created.
     */
    event SchainCreated(
        string name,
        address owner,
        uint partOfNode,
        uint lifetime,
        uint numberOfNodes,
        uint deposit,
        uint16 nonce,
        bytes32 schainHash
    );

    /**
     * @dev Emitted when an schain is deleted.
     */
    event SchainDeleted(
        address owner,
        string name,
        bytes32 indexed schainHash
    );

    /**
     * @dev Emitted when a node in an schain is rotated.
     */
    event NodeRotated(
        bytes32 schainHash,
        uint oldNode,
        uint newNode
    );

    /**
     * @dev Emitted when a node is added to an schain.
     */
    event NodeAdded(
        bytes32 schainHash,
        uint newNode
    );

    /**
     * @dev Emitted when a group of nodes is created for an schain.
     */
    event SchainNodes(
        string name,
        bytes32 schainHash,
        uint[] nodesInGroup
    );

    function addSchain(address from, uint deposit, bytes calldata data) external;
    function addSchainByFoundation(
        uint lifetime,
        uint8 typeOfSchain,
        uint16 nonce,
        string calldata name,
        address schainOwner,
        address schainOriginator,
        SchainOption[] calldata options
    )
        external
        payable;
    function deleteSchain(address from, string calldata name) external;
    function deleteSchainByRoot(string calldata name) external;
    function restartSchainCreation(string calldata name) external;
    function verifySchainSignature(
        uint256 signA,
        uint256 signB,
        bytes32 hash,
        uint256 counter,
        uint256 hashA,
        uint256 hashB,
        string calldata schainName
    )
        external
        view
        returns (bool);
    function getSchainPrice(uint typeOfSchain, uint lifetime) external view returns (uint);
    function getOption(bytes32 schainHash, string calldata optionName) external view returns (bytes memory);
    function getOptions(bytes32 schainHash) external view returns (SchainOption[] memory);
}

// SPDX-License-Identifier: AGPL-3.0-only

/*
    ISchainsInternal - SKALE Manager Interfaces
    Copyright (C) 2021-Present SKALE Labs
    @author Dmytro Stebaeiv

    SKALE Manager Interfaces is free software: you can redistribute it and/or modify
    it under the terms of the GNU Affero General Public License as published
    by the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    SKALE Manager Interfaces is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Affero General Public License for more details.

    You should have received a copy of the GNU Affero General Public License
    along with SKALE Manager Interfaces.  If not, see <https://www.gnu.org/licenses/>.
*/

pragma solidity >=0.6.10 <0.9.0;

interface ISchainsInternal {
    struct Schain {
        string name;
        address owner;
        uint indexInOwnerList;
        uint8 partOfNode;
        uint lifetime;
        uint startDate;
        uint startBlock;
        uint deposit;
        uint64 index;
        uint generation;
        address originator;
    }

    struct SchainType {
        uint8 partOfNode;
        uint numberOfNodes;
    }

    /**
     * @dev Emitted when schain type added.
     */
    event SchainTypeAdded(uint indexed schainType, uint partOfNode, uint numberOfNodes);

    /**
     * @dev Emitted when schain type removed.
     */
    event SchainTypeRemoved(uint indexed schainType);

    function initializeSchain(
        string calldata name,
        address from,
        address originator,
        uint lifetime,
        uint deposit) external;
    function createGroupForSchain(
        bytes32 schainHash,
        uint numberOfNodes,
        uint8 partOfNode
    )
        external
        returns (uint[] memory);
    function changeLifetime(bytes32 schainHash, uint lifetime, uint deposit) external;
    function removeSchain(bytes32 schainHash, address from) external;
    function removeNodeFromSchain(uint nodeIndex, bytes32 schainHash) external;
    function deleteGroup(bytes32 schainHash) external;
    function setException(bytes32 schainHash, uint nodeIndex) external;
    function setNodeInGroup(bytes32 schainHash, uint nodeIndex) external;
    function removeHolesForSchain(bytes32 schainHash) external;
    function addSchainType(uint8 partOfNode, uint numberOfNodes) external;
    function removeSchainType(uint typeOfSchain) external;
    function setNumberOfSchainTypes(uint newNumberOfSchainTypes) external;
    function removeNodeFromAllExceptionSchains(uint nodeIndex) external;
    function removeAllNodesFromSchainExceptions(bytes32 schainHash) external;
    function makeSchainNodesInvisible(bytes32 schainHash) external;
    function makeSchainNodesVisible(bytes32 schainHash) external;
    function newGeneration() external;
    function addSchainForNode(uint nodeIndex, bytes32 schainHash) external;
    function removeSchainForNode(uint nodeIndex, uint schainIndex) external;
    function removeNodeFromExceptions(bytes32 schainHash, uint nodeIndex) external;
    function isSchainActive(bytes32 schainHash) external view returns (bool);
    function schainsAtSystem(uint index) external view returns (bytes32);
    function numberOfSchains() external view returns (uint64);
    function getSchains() external view returns (bytes32[] memory);
    function getSchainsPartOfNode(bytes32 schainHash) external view returns (uint8);
    function getSchainListSize(address from) external view returns (uint);
    function getSchainHashesByAddress(address from) external view returns (bytes32[] memory);
    function getSchainIdsByAddress(address from) external view returns (bytes32[] memory);
    function getSchainHashesForNode(uint nodeIndex) external view returns (bytes32[] memory);
    function getSchainIdsForNode(uint nodeIndex) external view returns (bytes32[] memory);
    function getSchainOwner(bytes32 schainHash) external view returns (address);
    function getSchainOriginator(bytes32 schainHash) external view returns (address);
    function isSchainNameAvailable(string calldata name) external view returns (bool);
    function isTimeExpired(bytes32 schainHash) external view returns (bool);
    function isOwnerAddress(address from, bytes32 schainId) external view returns (bool);
    function getSchainName(bytes32 schainHash) external view returns (string memory);
    function getActiveSchain(uint nodeIndex) external view returns (bytes32);
    function getActiveSchains(uint nodeIndex) external view returns (bytes32[] memory activeSchains);
    function getNumberOfNodesInGroup(bytes32 schainHash) external view returns (uint);
    function getNodesInGroup(bytes32 schainHash) external view returns (uint[] memory);
    function isNodeAddressesInGroup(bytes32 schainId, address sender) external view returns (bool);
    function getNodeIndexInGroup(bytes32 schainHash, uint nodeId) external view returns (uint);
    function isAnyFreeNode(bytes32 schainHash) external view returns (bool);
    function checkException(bytes32 schainHash, uint nodeIndex) external view returns (bool);
    function checkHoleForSchain(bytes32 schainHash, uint indexOfNode) external view returns (bool);
    function checkSchainOnNode(uint nodeIndex, bytes32 schainHash) external view returns (bool);
    function getSchainType(uint typeOfSchain) external view returns(uint8, uint);
    function getGeneration(bytes32 schainHash) external view returns (uint);
    function isSchainExist(bytes32 schainHash) external view returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0-only

/**
 *   MessageProxy.sol - SKALE Interchain Messaging Agent
 *   Copyright (C) 2021-Present SKALE Labs
 *   @author Dmytro Stebaiev
 *
 *   SKALE IMA is free software: you can redistribute it and/or modify
 *   it under the terms of the GNU Affero General Public License as published
 *   by the Free Software Foundation, either version 3 of the License, or
 *   (at your option) any later version.
 *
 *   SKALE IMA is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU Affero General Public License for more details.
 *
 *   You should have received a copy of the GNU Affero General Public License
 *   along with SKALE IMA.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity 0.8.16;

import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@skalenetwork/ima-interfaces/IGasReimbursable.sol";
import "@skalenetwork/ima-interfaces/IMessageProxy.sol";
import "@skalenetwork/ima-interfaces/IMessageReceiver.sol";


/**
 * @title MessageProxy
 * @dev Abstract contract for MessageProxyForMainnet and MessageProxyForSchain.
 */
abstract contract MessageProxy is AccessControlEnumerableUpgradeable, IMessageProxy {
    using AddressUpgradeable for address;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    /**
     * @dev Structure that stores counters for outgoing and incoming messages.
     */
    struct ConnectedChainInfo {
        // message counters start with 0
        uint256 incomingMessageCounter;
        uint256 outgoingMessageCounter;
        bool inited;
        uint256 lastOutgoingMessageBlockId;
    }

    bytes32 public constant MAINNET_HASH = keccak256(abi.encodePacked("Mainnet"));
    bytes32 public constant CHAIN_CONNECTOR_ROLE = keccak256("CHAIN_CONNECTOR_ROLE");
    bytes32 public constant EXTRA_CONTRACT_REGISTRAR_ROLE = keccak256("EXTRA_CONTRACT_REGISTRAR_ROLE");
    bytes32 public constant CONSTANT_SETTER_ROLE = keccak256("CONSTANT_SETTER_ROLE");
    uint256 public constant MESSAGES_LENGTH = 10;
    uint256 public constant REVERT_REASON_LENGTH = 64;

    //   schainHash => ConnectedChainInfo
    mapping(bytes32 => ConnectedChainInfo) public connectedChains;
    //   schainHash => contract address => allowed
    // solhint-disable-next-line private-vars-leading-underscore
    mapping(bytes32 => mapping(address => bool)) internal deprecatedRegistryContracts;

    uint256 public gasLimit;

    /**
     * @dev Emitted for every outgoing message to schain.
     */
    event OutgoingMessage(
        bytes32 indexed dstChainHash,
        uint256 indexed msgCounter,
        address indexed srcContract,
        address dstContract,
        bytes data
    );

    /**
     * @dev Emitted when function `postMessage` returns revert.
     *  Used to prevent stuck loop inside function `postIncomingMessages`.
     */
    event PostMessageError(
        uint256 indexed msgCounter,
        bytes message
    );

    /**
     * @dev Emitted when gas limit per one call of `postMessage` was changed.
     */
    event GasLimitWasChanged(
        uint256 oldValue,
        uint256 newValue
    );

    /**
     * @dev Emitted when the version was updated
     */
    event VersionUpdated(string oldVersion, string newVersion);

    /**
     * @dev Emitted when extra contract was added.
     */
    event ExtraContractRegistered(
        bytes32 indexed chainHash,
        address contractAddress
    );

    /**
     * @dev Emitted when extra contract was removed.
     */
    event ExtraContractRemoved(
        bytes32 indexed chainHash,
        address contractAddress
    );

    /**
     * @dev Emitted when referenced to previous outgoing message.
     */
    event PreviousMessageReference (
        uint256 currentMessage,
        uint256 previousOutgoingMessageBlockId
    );

    /**
     * @dev Modifier to make a function callable only if caller is granted with {CHAIN_CONNECTOR_ROLE}.
     */
    modifier onlyChainConnector() {
        require(hasRole(CHAIN_CONNECTOR_ROLE, msg.sender), "CHAIN_CONNECTOR_ROLE is required");
        _;
    }

    /**
     * @dev Modifier to make a function callable only if caller is granted with {EXTRA_CONTRACT_REGISTRAR_ROLE}.
     */
    modifier onlyExtraContractRegistrar() {
        require(hasRole(EXTRA_CONTRACT_REGISTRAR_ROLE, msg.sender), "EXTRA_CONTRACT_REGISTRAR_ROLE is required");
        _;
    }

    /**
     * @dev Modifier to make a function callable only if caller is granted with {CONSTANT_SETTER_ROLE}.
     */
    modifier onlyConstantSetter() {
        require(hasRole(CONSTANT_SETTER_ROLE, msg.sender), "Not enough permissions to set constant");
        _;
    }    

    /**
     * @dev Sets gasLimit to a new value.
     * 
     * Requirements:
     * 
     * - `msg.sender` must be granted CONSTANT_SETTER_ROLE.
     */
    function setNewGasLimit(uint256 newGasLimit) external override onlyConstantSetter {
        emit GasLimitWasChanged(gasLimit, newGasLimit);
        gasLimit = newGasLimit;
    }

    /**
     * @dev Virtual function for `postIncomingMessages`.
     */
    function postIncomingMessages(
        string calldata fromSchainName,
        uint256 startingCounter,
        Message[] calldata messages,
        Signature calldata sign
    )
        external
        virtual
        override;

    /**
     * @dev Allows `msg.sender` to register extra contract for all schains
     * for being able to transfer messages from custom contracts.
     * 
     * Requirements:
     * 
     * - `msg.sender` must be granted as EXTRA_CONTRACT_REGISTRAR_ROLE.
     * - Passed address should be contract.
     * - Extra contract must not be registered.
     */
    function registerExtraContractForAll(address extraContract) external override onlyExtraContractRegistrar {
        require(extraContract.isContract(), "Given address is not a contract");
        require(!_getRegistryContracts()[bytes32(0)].contains(extraContract), "Extra contract is already registered");
        _getRegistryContracts()[bytes32(0)].add(extraContract);
        emit ExtraContractRegistered(bytes32(0), extraContract);
    }

    /**
     * @dev Allows `msg.sender` to remove extra contract for all schains.
     * Extra contract will no longer be able to send messages through MessageProxy.
     * 
     * Requirements:
     * 
     * - `msg.sender` must be granted as EXTRA_CONTRACT_REGISTRAR_ROLE.
     */
    function removeExtraContractForAll(address extraContract) external override onlyExtraContractRegistrar {
        require(_getRegistryContracts()[bytes32(0)].contains(extraContract), "Extra contract is not registered");
        _getRegistryContracts()[bytes32(0)].remove(extraContract);
        emit ExtraContractRemoved(bytes32(0), extraContract);
    }

    /**
     * @dev Should return length of contract registered by schainHash.
     */
    function getContractRegisteredLength(bytes32 schainHash) external view override returns (uint256) {
        return _getRegistryContracts()[schainHash].length();
    }

    /**
     * @dev Should return a range of contracts registered by schainHash.
     * 
     * Requirements:
     * range should be less or equal 10 contracts
     */
    function getContractRegisteredRange(
        bytes32 schainHash,
        uint256 from,
        uint256 to
    )
        external
        view
        override
        returns (address[] memory contractsInRange)
    {
        require(
            from < to && to - from <= 10 && to <= _getRegistryContracts()[schainHash].length(),
            "Range is incorrect"
        );
        contractsInRange = new address[](to - from);
        for (uint256 i = from; i < to; i++) {
            contractsInRange[i - from] = _getRegistryContracts()[schainHash].at(i);
        }
    }

    /**
     * @dev Returns number of outgoing messages.
     * 
     * Requirements:
     * 
     * - Target schain  must be initialized.
     */
    function getOutgoingMessagesCounter(string calldata targetSchainName)
        external
        view
        override
        returns (uint256)
    {
        bytes32 dstChainHash = keccak256(abi.encodePacked(targetSchainName));
        require(connectedChains[dstChainHash].inited, "Destination chain is not initialized");
        return connectedChains[dstChainHash].outgoingMessageCounter;
    }


    /**
     * @dev Should return block number of the last message transferred to schain
     */
    function getLastOutgoingMessageBlockId(string memory targetSchainName) external view override returns (uint) {
        bytes32 dstChainHash = keccak256(abi.encodePacked(targetSchainName));
        require(connectedChains[dstChainHash].inited, "Destination chain is not initialized");
        return connectedChains[dstChainHash].lastOutgoingMessageBlockId;
    }

    /**
     * @dev Returns number of incoming messages.
     * 
     * Requirements:
     * 
     * - Source schain must be initialized.
     */
    function getIncomingMessagesCounter(string calldata fromSchainName)
        external
        view
        override
        returns (uint256)
    {
        bytes32 srcChainHash = keccak256(abi.encodePacked(fromSchainName));
        require(connectedChains[srcChainHash].inited, "Source chain is not initialized");
        return connectedChains[srcChainHash].incomingMessageCounter;
    }

    function initializeMessageProxy(uint newGasLimit) public initializer {
        AccessControlEnumerableUpgradeable.__AccessControlEnumerable_init();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(CHAIN_CONNECTOR_ROLE, msg.sender);
        _setupRole(EXTRA_CONTRACT_REGISTRAR_ROLE, msg.sender);
        _setupRole(CONSTANT_SETTER_ROLE, msg.sender);
        gasLimit = newGasLimit;
    }

    /**
     * @dev Posts message from this contract to `targetChainHash` MessageProxy contract.
     * This is called by a smart contract to make a cross-chain call.
     * 
     * Emits an {OutgoingMessage} event.
     *
     * Requirements:
     * 
     * - Target chain must be initialized.
     * - Target chain must be registered as external contract.
     */
    function postOutgoingMessage(
        bytes32 targetChainHash,
        address targetContract,
        bytes memory data
    )
        public
        override
        virtual
    {
        require(connectedChains[targetChainHash].inited, "Destination chain is not initialized");
        _authorizeOutgoingMessageSender(targetChainHash);
        
        uint outgoingMessageCounter = connectedChains[targetChainHash].outgoingMessageCounter;
        emit OutgoingMessage(
            targetChainHash,
            outgoingMessageCounter,
            msg.sender,
            targetContract,
            data
        );
        emit PreviousMessageReference(
            outgoingMessageCounter,
            connectedChains[targetChainHash].lastOutgoingMessageBlockId
        );
        connectedChains[targetChainHash].outgoingMessageCounter++;
        connectedChains[targetChainHash].lastOutgoingMessageBlockId = block.number;
    }

    /**
     * @dev Allows CHAIN_CONNECTOR_ROLE to remove connected chain from this contract.
     * 
     * Requirements:
     * 
     * - `msg.sender` must be granted CHAIN_CONNECTOR_ROLE.
     * - `schainName` must be initialized.
     */
    function removeConnectedChain(string memory schainName) public virtual override onlyChainConnector {
        bytes32 schainHash = keccak256(abi.encodePacked(schainName));
        require(connectedChains[schainHash].inited, "Chain is not initialized");
        delete connectedChains[schainHash];
    }    

    /**
     * @dev Checks whether chain is currently connected.
     */
    function isConnectedChain(
        string memory schainName
    )
        public
        view
        virtual
        override
        returns (bool)
    {
        return connectedChains[keccak256(abi.encodePacked(schainName))].inited;
    }

    /**
     * @dev Checks whether contract is currently registered as extra contract.
     */
    function isContractRegistered(
        bytes32 schainHash,
        address contractAddress
    )
        public
        view
        override
        returns (bool)
    {
        return _getRegistryContracts()[schainHash].contains(contractAddress);
    }

    /**
     * @dev Allows MessageProxy to register extra contract for being able to transfer messages from custom contracts.
     * 
     * Requirements:
     * 
     * - Extra contract address must be contract.
     * - Extra contract must not be registered.
     * - Extra contract must not be registered for all chains.
     */
    function _registerExtraContract(
        bytes32 chainHash,
        address extraContract
    )
        internal
    {      
        require(extraContract.isContract(), "Given address is not a contract");
        require(!_getRegistryContracts()[chainHash].contains(extraContract), "Extra contract is already registered");
        require(
            !_getRegistryContracts()[bytes32(0)].contains(extraContract),
            "Extra contract is already registered for all chains"
        );
        
        _getRegistryContracts()[chainHash].add(extraContract);
        emit ExtraContractRegistered(chainHash, extraContract);
    }

    /**
     * @dev Allows MessageProxy to remove extra contract,
     * thus `extraContract` will no longer be available to transfer messages from mainnet to schain.
     * 
     * Requirements:
     * 
     * - Extra contract must be registered.
     */
    function _removeExtraContract(
        bytes32 chainHash,
        address extraContract
    )
        internal
    {
        require(_getRegistryContracts()[chainHash].contains(extraContract), "Extra contract is not registered");
        _getRegistryContracts()[chainHash].remove(extraContract);
        emit ExtraContractRemoved(chainHash, extraContract);
    }

    /**
     * @dev Allows MessageProxy to connect schain with MessageProxyOnMainnet for transferring messages.
     * 
     * Requirements:
     * 
     * - `msg.sender` must be granted CHAIN_CONNECTOR_ROLE.
     * - SKALE chain must not be connected.
     */
    function _addConnectedChain(bytes32 schainHash) internal onlyChainConnector {
        require(!connectedChains[schainHash].inited,"Chain is already connected");
        connectedChains[schainHash] = ConnectedChainInfo({
            incomingMessageCounter: 0,
            outgoingMessageCounter: 0,
            inited: true,
            lastOutgoingMessageBlockId: 0
        });
    }

    /**
     * @dev Allows MessageProxy to send messages from schain to mainnet.
     * Destination contract must implement `postMessage` method.
     */
    function _callReceiverContract(
        bytes32 schainHash,
        Message calldata message,
        uint counter
    )
        internal
    {
        if (!message.destinationContract.isContract()) {
            emit PostMessageError(
                counter,
                "Destination contract is not a contract"
            );
            return;
        }
        try IMessageReceiver(message.destinationContract).postMessage{gas: gasLimit}(
            schainHash,
            message.sender,
            message.data
        ) {
            return;
        } catch Error(string memory reason) {
            emit PostMessageError(
                counter,
                _getSlice(bytes(reason), REVERT_REASON_LENGTH)
            );
        } catch Panic(uint errorCode) {
               emit PostMessageError(
                counter,
                abi.encodePacked(errorCode)
            );
        } catch (bytes memory revertData) {
            emit PostMessageError(
                counter,
                _getSlice(revertData, REVERT_REASON_LENGTH)
            );
        }
    }

    /**
     * @dev Returns receiver of message.
     */
    function _getGasPayer(
        bytes32 schainHash,
        Message calldata message,
        uint counter
    )
        internal
        returns (address)
    {
        try IGasReimbursable(message.destinationContract).gasPayer{gas: gasLimit}(
            schainHash,
            message.sender,
            message.data
        ) returns (address receiver) {
            return receiver;
        } catch Error(string memory reason) {
            emit PostMessageError(
                counter,
                _getSlice(bytes(reason), REVERT_REASON_LENGTH)
            );
            return address(0);
        } catch Panic(uint errorCode) {
               emit PostMessageError(
                counter,
                abi.encodePacked(errorCode)
            );
            return address(0);
        } catch (bytes memory revertData) {
            emit PostMessageError(
                counter,
                _getSlice(revertData, REVERT_REASON_LENGTH)
            );
            return address(0);
        }
    }

    /**
     * @dev Checks whether msg.sender is registered as custom extra contract.
     */
    function _authorizeOutgoingMessageSender(bytes32 targetChainHash) internal view virtual {
        require(
            isContractRegistered(bytes32(0), msg.sender) || isContractRegistered(targetChainHash, msg.sender),
            "Sender contract is not registered"
        );        
    }

    /**
     * @dev Returns list of registered custom extra contracts.
     */
    function _getRegistryContracts()
        internal
        view
        virtual
        returns (mapping(bytes32 => EnumerableSetUpgradeable.AddressSet) storage);

    /**
     * @dev Returns hash of message array.
     */
    function _hashedArray(
        Message[] calldata messages,
        uint256 startingCounter,
        string calldata fromChainName
    )
        internal
        pure
        returns (bytes32)
    {
        bytes32 sourceHash = keccak256(abi.encodePacked(fromChainName));
        bytes32 hash = keccak256(abi.encodePacked(sourceHash, bytes32(startingCounter)));
        for (uint256 i = 0; i < messages.length; i++) {
            hash = keccak256(
                abi.encodePacked(
                    abi.encode(
                        hash,
                        messages[i].sender,
                        messages[i].destinationContract
                    ),
                    messages[i].data
                )
            );
        }
        return hash;
    }

    function _getSlice(bytes memory text, uint end) private pure returns (bytes memory) {
        uint slicedEnd = end < text.length ? end : text.length;
        bytes memory sliced = new bytes(slicedEnd);
        for(uint i = 0; i < slicedEnd; i++){
            sliced[i] = text[i];
        }
        return sliced;    
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

/*
    CommunityPool.sol - SKALE Manager
    Copyright (C) 2021-Present SKALE Labs
    @author Dmytro Stebaiev
    @author Artem Payvin
    @author Vadim Yavorsky

    SKALE Manager is free software: you can redistribute it and/or modify
    it under the terms of the GNU Affero General Public License as published
    by the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    SKALE Manager is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Affero General Public License for more details.

    You should have received a copy of the GNU Affero General Public License
    along with SKALE Manager.  If not, see <https://www.gnu.org/licenses/>.
*/

pragma solidity 0.8.16;

import "@skalenetwork/ima-interfaces/mainnet/ICommunityPool.sol";
import "@skalenetwork/skale-manager-interfaces/IWallets.sol";

import "../Messages.sol";
import "./Twin.sol";


/**
 * @title CommunityPool
 * @dev Contract contains logic to perform automatic self-recharging ETH for nodes.
 */
contract CommunityPool is Twin, ICommunityPool {

    using AddressUpgradeable for address payable;

    bytes32 public constant CONSTANT_SETTER_ROLE = keccak256("CONSTANT_SETTER_ROLE");

    // address of user => schainHash => balance of gas wallet in ETH
    mapping(address => mapping(bytes32 => uint)) private _userWallets;

    // address of user => schainHash => true if unlocked for transferring
    mapping(address => mapping(bytes32 => bool)) public activeUsers;

    uint public minTransactionGas;

    uint public multiplierNumerator;
    uint public multiplierDivider;

    /**
     * @dev Emitted when minimal value in gas for transactions from schain to mainnet was changed 
     */
    event MinTransactionGasWasChanged(
        uint oldValue,
        uint newValue
    );

    /**
     * @dev Emitted when basefee multiplier was changed 
     */
    event MultiplierWasChanged(
        uint oldMultiplierNumerator,
        uint oldMultiplierDivider,
        uint newMultiplierNumerator,
        uint newMultiplierDivider
    );

    function initialize(
        IContractManager contractManagerOfSkaleManagerValue,
        ILinker linker,
        IMessageProxyForMainnet messageProxyValue
    )
        external
        override
        initializer
    {
        Twin.initialize(contractManagerOfSkaleManagerValue, messageProxyValue);
        _setupRole(LINKER_ROLE, address(linker));
        minTransactionGas = 1e6;
        multiplierNumerator = 3;
        multiplierDivider = 2;
    }

    /**
     * @dev Allows MessageProxyForMainnet to reimburse gas for transactions 
     * that transfer funds from schain to mainnet.
     * 
     * Requirements:
     * 
     * - User that receives funds should have enough funds in their gas wallet.
     * - Address that should be reimbursed for executing transaction must not be null.
     */
    function refundGasByUser(
        bytes32 schainHash,
        address payable node,
        address user,
        uint gas
    )
        external
        override
        onlyMessageProxy
        returns (uint)
    {
        require(node != address(0), "Node address must be set");
        if (!activeUsers[user][schainHash]) {
            return gas;
        }
        uint amount = tx.gasprice * gas;
        if (amount > _userWallets[user][schainHash]) {
            amount = _userWallets[user][schainHash];
        }
        _userWallets[user][schainHash] = _userWallets[user][schainHash] - amount;
        if (!_balanceIsSufficient(schainHash, user, 0)) {
            activeUsers[user][schainHash] = false;
            messageProxy.postOutgoingMessage(
                schainHash,
                getSchainContract(schainHash),
                Messages.encodeLockUserMessage(user)
            );
        }
        node.sendValue(amount);
        return (tx.gasprice * gas - amount) / tx.gasprice;
    }

    function refundGasBySchainWallet(
        bytes32 schainHash,
        address payable node,
        uint gas
    )
        external
        override
        onlyMessageProxy
        returns (bool)
    {
        if (gas > 0) {

            IWallets(payable(contractManagerOfSkaleManager.getContract("Wallets"))).refundGasBySchain(
                schainHash,
                node,
                gas,
                false
            );
        }
        return true;
    }

    /**
     * @dev Allows `msg.sender` to recharge their wallet for further gas reimbursement.
     * 
     * Requirements:
     * 
     * - 'msg.sender` should recharge their gas wallet for amount that enough to reimburse any 
     *   transaction from schain to mainnet.
     */
    function rechargeUserWallet(string calldata schainName, address user) external payable override {
        bytes32 schainHash = keccak256(abi.encodePacked(schainName));
        require(
            _balanceIsSufficient(schainHash, user, msg.value),
            "Not enough ETH for transaction"
        );
        _userWallets[user][schainHash] = _userWallets[user][schainHash] + msg.value;
        if (!activeUsers[user][schainHash]) {
            activeUsers[user][schainHash] = true;
            messageProxy.postOutgoingMessage(
                schainHash,
                getSchainContract(schainHash),
                Messages.encodeActivateUserMessage(user)
            );
        }
    }

    /**
     * @dev Allows `msg.sender` to withdraw funds from their gas wallet.
     * If `msg.sender` withdraws too much funds,
     * then he will no longer be able to transfer their tokens on ETH from schain to mainnet.
     * 
     * Requirements:
     * 
     * - 'msg.sender` must have sufficient amount of ETH on their gas wallet.
     */
    function withdrawFunds(string calldata schainName, uint amount) external override {
        bytes32 schainHash = keccak256(abi.encodePacked(schainName));
        require(amount <= _userWallets[msg.sender][schainHash], "Balance is too low");
        require(!messageProxy.messageInProgress(), "Message is in progress");
        _userWallets[msg.sender][schainHash] = _userWallets[msg.sender][schainHash] - amount;
        if (
            !_balanceIsSufficient(schainHash, msg.sender, 0) &&
            activeUsers[msg.sender][schainHash]
        ) {
            activeUsers[msg.sender][schainHash] = false;
            messageProxy.postOutgoingMessage(
                schainHash,
                getSchainContract(schainHash),
                Messages.encodeLockUserMessage(msg.sender)
            );
        }
        payable(msg.sender).sendValue(amount);
    }

    /**
     * @dev Allows `msg.sender` set the amount of gas that should be 
     * enough for reimbursing any transaction from schain to mainnet.
     * 
     * Requirements:
     * 
     * - 'msg.sender` must have sufficient amount of ETH on their gas wallet.
     */
    function setMinTransactionGas(uint newMinTransactionGas) external override {
        require(hasRole(CONSTANT_SETTER_ROLE, msg.sender), "CONSTANT_SETTER_ROLE is required");
        emit MinTransactionGasWasChanged(minTransactionGas, newMinTransactionGas);
        minTransactionGas = newMinTransactionGas;
    }

    /**
     * @dev Allows `msg.sender` set the amount of gas that should be 
     * enough for reimbursing any transaction from schain to mainnet.
     * 
     * Requirements:
     * 
     * - 'msg.sender` must have sufficient amount of ETH on their gas wallet.
     */
    function setMultiplier(uint newMultiplierNumerator, uint newMultiplierDivider) external override {
        require(hasRole(CONSTANT_SETTER_ROLE, msg.sender), "CONSTANT_SETTER_ROLE is required");
        require(newMultiplierDivider > 0, "Divider is zero");
        emit MultiplierWasChanged(
            multiplierNumerator,
            multiplierDivider,
            newMultiplierNumerator,
            newMultiplierDivider
        );
        multiplierNumerator = newMultiplierNumerator;
        multiplierDivider = newMultiplierDivider;
    }

    /**
     * @dev Returns the amount of ETH on gas wallet for particular user.
     */
    function getBalance(address user, string calldata schainName) external view override returns (uint) {
        return _userWallets[user][keccak256(abi.encodePacked(schainName))];
    }

    /**
     * @dev Checks whether user is active and wallet was recharged for sufficient amount.
     */
    function checkUserBalance(bytes32 schainHash, address receiver) external view override returns (bool) {
        return activeUsers[receiver][schainHash] && _balanceIsSufficient(schainHash, receiver, 0);
    }

    /**
     * @dev Checks whether passed amount is enough to recharge user wallet with current basefee.
     */
    function getRecommendedRechargeAmount(
        bytes32 schainHash,
        address receiver
    )
        external
        view
        override
        returns (uint256)
    {
        uint256 currentValue = _multiplyOnAdaptedBaseFee(minTransactionGas);
        if (currentValue  <= _userWallets[receiver][schainHash]) {
            return 0;
        }
        return currentValue - _userWallets[receiver][schainHash];
    }

    /**
     * @dev Checks whether user wallet was recharged for sufficient amount.
     */
    function _balanceIsSufficient(bytes32 schainHash, address receiver, uint256 delta) private view returns (bool) {
        return delta + _userWallets[receiver][schainHash] >= minTransactionGas * tx.gasprice;
    }

    function _multiplyOnAdaptedBaseFee(uint256 value) private view returns (uint256) {
        return value * block.basefee * multiplierNumerator / multiplierDivider;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControlEnumerableUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "../utils/structs/EnumerableSetUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerableUpgradeable is Initializable, IAccessControlEnumerableUpgradeable, AccessControlUpgradeable {
    function __AccessControlEnumerable_init() internal onlyInitializing {
    }

    function __AccessControlEnumerable_init_unchained() internal onlyInitializing {
    }
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    mapping(bytes32 => EnumerableSetUpgradeable.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerableUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view virtual override returns (address) {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view virtual override returns (uint256) {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {_grantRole} to track enumerable memberships
     */
    function _grantRole(bytes32 role, address account) internal virtual override {
        super._grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {_revokeRole} to track enumerable memberships
     */
    function _revokeRole(bytes32 role, address account) internal virtual override {
        super._revokeRole(role, account);
        _roleMembers[role].remove(account);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerableUpgradeable is IAccessControlUpgradeable {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

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
                        StringsUpgradeable.toHexString(uint160(account), 20),
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
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

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