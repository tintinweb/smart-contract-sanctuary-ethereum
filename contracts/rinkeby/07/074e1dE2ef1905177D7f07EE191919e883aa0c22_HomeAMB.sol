// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

import "./AsyncInformationProcessor.sol";

contract HomeAMB is AsyncInformationProcessor {
    event UserRequestForSignature(bytes32 indexed messageId, bytes encodedData);
    event AffirmationCompleted(
        address indexed sender,
        address indexed executor,
        bytes32 indexed messageId,
        bool status
    );

    function emitEventOnMessageRequest(bytes32 messageId, bytes memory encodedData) internal override{
        emit UserRequestForSignature(messageId, encodedData);
    }

    function emitEventOnMessageProcessed(
        address sender,
        address executor,
        bytes32 messageId,
        bool status
    ) internal override {
        emit AffirmationCompleted(sender, executor, messageId, status);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

import "../../interfaces/IAMBInformationReceiver.sol";
import "./BasicHomeAMB.sol";

/**
 * @title AsyncInformationProcessor
 * @dev Functionality for making and processing async calls on Home side of the AMB.
 */
abstract contract AsyncInformationProcessor is BasicHomeAMB {
    event UserRequestForInformation(
        bytes32 indexed messageId,
        bytes32 indexed requestSelector,
        address indexed sender,
        bytes data
    );
    event SignedForInformation(address indexed signer, bytes32 indexed messageId);
    event InformationRetrieved(bytes32 indexed messageId, bool status, bool callbackStatus);
    event EnabledAsyncRequestSelector(bytes32 indexed requestSelector, bool enable);

    /**
     * @dev Makes an asynchronous request to get information from the opposite network.
     * Call result will be returned later to the callee, by using the onInformationReceived(bytes) callback function.
     * @param _requestSelector selector for the async request.
     * @param _data payload for the given selector
     */
    function requireToGetInformation(bytes32 _requestSelector, bytes memory _data) external returns (bytes32) {
        // it is not allowed to pass messages while other messages are processed
        // if other is not explicitly configured
        require(messageId() == bytes32(0) || allowReentrantRequests());
        // only contracts are allowed to call this method, since EOA won't be able to receive a callback.
        require(Address.isContract(msg.sender));

        require(isAsyncRequestSelectorEnabled(_requestSelector));

        bytes32 _messageId = _getNewMessageId(sourceChainId());

        _setAsyncRequestSender(_messageId, msg.sender);

        emit UserRequestForInformation(_messageId, _requestSelector, msg.sender, _data);
        return _messageId;
    }

    /**
     * Tells if the specific async request selector is allowed to be used and supported by the bridge oracles.
     * @param _requestSelector selector for the async request.
     * @return true, if selector is allowed to be used.
     */
    function isAsyncRequestSelectorEnabled(bytes32 _requestSelector) public view returns (bool) {
        return boolStorage[keccak256(abi.encodePacked("enableRequestSelector", _requestSelector))];
    }

    /**
     * Enables or disables the specific async request selector.
     * Only owner can call this method.
     * @param _requestSelector selector for the async request.
     * @param _enable true, if the selector should be allowed.
     */
    function enableAsyncRequestSelector(bytes32 _requestSelector, bool _enable) external onlyOwner {
        boolStorage[keccak256(abi.encodePacked("enableRequestSelector", _requestSelector))] = _enable;

        emit EnabledAsyncRequestSelector(_requestSelector, _enable);
    }

    /**
     * @dev Submits result of the async call.
     * Only validators are allowed to call this method.
     * Once enough confirmations are collected, callback function is called.
     * @param _messageId unique id of the request that was previously made.
     * @param _status true, if JSON-RPC request succeeded, false otherwise.
     * @param _result call result returned by the other side of the bridge.
     */
    function confirmInformation(
        bytes32 _messageId,
        bool _status,
        bytes memory _result
    ) external onlyValidator {
        bytes32 hashMsg = keccak256(abi.encodePacked(_messageId, _status, _result));
        bytes32 hashSender = keccak256(abi.encodePacked(msg.sender, hashMsg));
        // Duplicated confirmations
        require(!affirmationsSigned(hashSender));
        setAffirmationsSigned(hashSender, true);

        uint256 signed = numAffirmationsSigned(hashMsg);
        require(!isAlreadyProcessed(signed));
        // the check above assumes that the case when the value could be overflew will not happen in the addition operation below
        signed = signed + 1;

        setNumAffirmationsSigned(hashMsg, signed);

        emit SignedForInformation(msg.sender, _messageId);

        if (signed >= requiredSignatures()) {
            setNumAffirmationsSigned(hashMsg, markAsProcessed(signed));
            address sender = _restoreAsyncRequestSender(_messageId);
            bytes memory data =
                abi.encodeWithSelector(
                    IAMBInformationReceiver(address(0)).onInformationReceived.selector,
                    _messageId,
                    _status,
                    _result
                );
            uint256 gas = maxGasPerTx();
            require((gasleft() * 63) / 64 > gas);

            (bool callbackStatus,) = sender.call{gas: gas}(data);

            emit InformationRetrieved(_messageId, _status, callbackStatus);
        }
    }

    /**
     * Internal function for saving async request sender for future use.
     * @param _messageId id of the sent async request.
     * @param _sender address of the request sender, receiver of the callback.
     */
    function _setAsyncRequestSender(bytes32 _messageId, address _sender) internal {
        addressStorage[keccak256(abi.encodePacked("asyncSender", _messageId))] = _sender;
    }

    /**
     * Internal function for restoring async request sender information.
     * @param _messageId id of the sent async request.
     * @return address of async request sender and callback receiver.
     */
    function _restoreAsyncRequestSender(bytes32 _messageId) internal returns (address) {
        bytes32 hash = keccak256(abi.encodePacked("asyncSender", _messageId));
        address sender = addressStorage[hash];

        require(sender != address(0));

        delete addressStorage[hash];
        return sender;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

interface IAMBInformationReceiver {
    function onInformationReceived(
        bytes32 messageId,
        bool status,
        bytes memory result
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

import "../../libraries/Message.sol";
import "../../libraries/ArbitraryMessage.sol";
import "./BasicAMB.sol";
import "./MessageDelivery.sol";

abstract contract BasicHomeAMB is BasicAMB, MessageDelivery {
    event SignedForUserRequest(address indexed signer, bytes32 messageHash);
    event SignedForAffirmation(address indexed signer, bytes32 messageHash);

    event CollectedSignatures(
        address authorityResponsibleForRelay,
        bytes32 messageHash,
        uint256 NumberOfCollectedSignatures
    );

    uint256 internal constant SEND_TO_MANUAL_LANE = 0x80;

    function executeAffirmation(bytes memory _message) external onlyValidator {
        bytes32 hashMsg = keccak256(abi.encodePacked(_message));
        bytes32 hashSender = keccak256(abi.encodePacked(msg.sender, hashMsg));
        // Duplicated affirmations
        require(!affirmationsSigned(hashSender));
        setAffirmationsSigned(hashSender, true);

        uint256 signed = numAffirmationsSigned(hashMsg);
        require(!isAlreadyProcessed(signed));
        // the check above assumes that the case when the value could be overflew will not happen in the addition operation below
        signed = signed + 1;

        setNumAffirmationsSigned(hashMsg, signed);

        emit SignedForAffirmation(msg.sender, hashMsg);

        if (signed >= requiredSignatures()) {
            setNumAffirmationsSigned(hashMsg, markAsProcessed(signed));
            handleMessage(_message);
        }
    }

    /**
     * @dev Requests message relay to the opposite network, message is sent to the manual lane.
     * @param _contract executor address on the other side.
     * @param _data calldata passed to the executor on the other side.
     * @param _gas gas limit used on the other network for executing a message.
     */
    function requireToConfirmMessage(
        address _contract,
        bytes memory _data,
        uint256 _gas
    ) public returns (bytes32) {
        return _sendMessage(_contract, _data, _gas, SEND_TO_MANUAL_LANE);
    }

    /**
     * Parses given message, processes a call inside it
     * @param _message relayed message
     */
    function handleMessage(bytes memory _message) internal {
        bytes32 messageId;
        address sender;
        address executor;
        uint32 gasLimit;
        uint8 dataType;
        uint256[2] memory chainIds;
        bytes memory data;

        (messageId, sender, executor, gasLimit, dataType, chainIds, data) = ArbitraryMessage.unpackData(_message);

        require(_isMessageVersionValid(messageId));
        require(_isDestinationChainIdValid(chainIds[1]));
        processMessage(sender, executor, messageId, gasLimit, dataType, chainIds[0], data);
    }

    function submitSignature(bytes memory _signature, bytes memory _message) external onlyValidator {
        // ensure that `signature` is really `message` signed by `msg.sender`
        require(msg.sender == Message.recoverAddressFromSignedMessage(_signature, _message, true));
        bytes32 hashMsg = keccak256(abi.encodePacked(_message));
        bytes32 hashSender = keccak256(abi.encodePacked(msg.sender, hashMsg));

        uint256 signed = numMessagesSigned(hashMsg);
        require(!isAlreadyProcessed(signed));
        // the check above assumes that the case when the value could be overflew
        // will not happen in the addition operation below
        signed = signed + 1;
        if (signed > 1) {
            // Duplicated signatures
            require(!messagesSigned(hashSender));
        } else {
            setMessages(hashMsg, _message);
        }
        setMessagesSigned(hashSender, true);

        bytes32 signIdx = keccak256(abi.encodePacked(hashMsg, (signed + 1)));
        setSignatures(signIdx, _signature);

        setNumMessagesSigned(hashMsg, signed);

        emit SignedForUserRequest(msg.sender, hashMsg);

        uint256 reqSigs = requiredSignatures();
        if (signed >= reqSigs) {
            setNumMessagesSigned(hashMsg, markAsProcessed(signed));
            emit CollectedSignatures(msg.sender, hashMsg, reqSigs);
        }
    }

    function isAlreadyProcessed(uint256 _number) public pure returns (bool) {
        return _number & (2**255) == 2**255;
    }

    function numMessagesSigned(bytes32 _message) public view returns (uint256) {
        return uintStorage[keccak256(abi.encodePacked("numMessagesSigned", _message))];
    }

    function signature(bytes32 _hash, uint256 _index) public view returns (bytes memory) {
        bytes32 signIdx = keccak256(abi.encodePacked(_hash, _index));
        return bytesStorage[keccak256(abi.encodePacked("signatures", signIdx))];
    }

    function messagesSigned(bytes32 _message) public view returns (bool) {
        return boolStorage[keccak256(abi.encodePacked("messagesSigned", _message))];
    }

    function message(bytes32 _hash) public view returns (bytes memory) {
        return messages(_hash);
    }

    function affirmationsSigned(bytes32 _hash) public view returns (bool) {
        return boolStorage[keccak256(abi.encodePacked("affirmationsSigned", _hash))];
    }

    function numAffirmationsSigned(bytes32 _hash) public view returns (uint256) {
        return uintStorage[keccak256(abi.encodePacked("numAffirmationsSigned", _hash))];
    }

    function setMessagesSigned(bytes32 _hash, bool _status) internal {
        boolStorage[keccak256(abi.encodePacked("messagesSigned", _hash))] = _status;
    }

    function messages(bytes32 _hash) internal view returns (bytes memory) {
        return bytesStorage[keccak256(abi.encodePacked("messages", _hash))];
    }

    function setSignatures(bytes32 _hash, bytes memory _signature) internal {
        bytesStorage[keccak256(abi.encodePacked("signatures", _hash))] = _signature;
    }

    function setMessages(bytes32 _hash, bytes memory _message) internal {
        bytesStorage[keccak256(abi.encodePacked("messages", _hash))] = _message;
    }

    function setNumMessagesSigned(bytes32 _message, uint256 _number) internal {
        uintStorage[keccak256(abi.encodePacked("numMessagesSigned", _message))] = _number;
    }

    function markAsProcessed(uint256 _v) internal pure returns (uint256) {
        return _v | (2**255);
    }

    function setAffirmationsSigned(bytes32 _hash, bool _status) internal {
        boolStorage[keccak256(abi.encodePacked("affirmationsSigned", _hash))] = _status;
    }

    function setNumAffirmationsSigned(bytes32 _hash, uint256 _number) internal {
        uintStorage[keccak256(abi.encodePacked("numAffirmationsSigned", _hash))] = _number;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;
import "../interfaces/IBridgeValidators.sol";

library Message {
    function addressArrayContains(address[] memory array, address value) internal pure returns (bool) {
        for (uint256 i = 0; i < array.length; i++) {
            if (array[i] == value) {
                return true;
            }
        }
        return false;
    }
    // layout of message :: bytes:
    // offset  0: 32 bytes :: uint256 - message length
    // offset 32: 20 bytes :: address - recipient address
    // offset 52: 32 bytes :: uint256 - value
    // offset 84: 32 bytes :: bytes32 - transaction hash
    // offset 116: 20 bytes :: address - contract address to prevent double spending

    // mload always reads 32 bytes.
    // so we can and have to start reading recipient at offset 20 instead of 32.
    // if we were to read at 32 the address would contain part of value and be corrupted.
    // when reading from offset 20 mload will read 12 bytes (most of them zeros) followed
    // by the 20 recipient address bytes and correctly convert it into an address.
    // this saves some storage/gas over the alternative solution
    // which is padding address to 32 bytes and reading recipient at offset 32.
    // for more details see discussion in:
    // https://github.com/paritytech/parity-bridge/issues/61
    function parseMessage(bytes memory message)
        internal
        pure
        returns (address recipient, uint256 amount, bytes32 txHash, address contractAddress)
    {
        require(isMessageValid(message));
        assembly {
            recipient := mload(add(message, 20))
            amount := mload(add(message, 52))
            txHash := mload(add(message, 84))
            contractAddress := mload(add(message, 104))
        }
    }

    function isMessageValid(bytes memory _msg) internal pure returns (bool) {
        return _msg.length == requiredMessageLength();
    }

    function requiredMessageLength() internal pure returns (uint256) {
        return 104;
    }

    function recoverAddressFromSignedMessage(bytes memory signature, bytes memory message, bool isAMBMessage)
        internal
        pure
        returns (address)
    {
        require(signature.length == 65);
        bytes32 r;
        bytes32 s;
        bytes1 v;

        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := mload(add(signature, 0x60))
        }
        require(uint8(v) == 27 || uint8(v) == 28);
        require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0);

        return ecrecover(hashMessage(message, isAMBMessage), uint8(v), r, s);
    }

    function hashMessage(bytes memory message, bool isAMBMessage) internal pure returns (bytes32) {
        bytes memory prefix = "\x19Ethereum Signed Message:\n";
        if (isAMBMessage) {
            return keccak256(abi.encodePacked(prefix, uintToString(message.length), message));
        } else {
            string memory msgLength = "104";
            return keccak256(abi.encodePacked(prefix, msgLength, message));
        }
    }

    /**
    * @dev Validates provided signatures, only first requiredSignatures() number
    * of signatures are going to be validated, these signatures should be from different validators.
    * @param _message bytes message used to generate signatures
    * @param _signatures bytes blob with signatures to be validated.
    * First byte X is a number of signatures in a blob,
    * next X bytes are v components of signatures,
    * next 32 * X bytes are r components of signatures,
    * next 32 * X bytes are s components of signatures.
    * @param _validatorContract contract, which conforms to the IBridgeValidators interface,
    * where info about current validators and required signatures is stored.
    * @param isAMBMessage true if _message is an AMB message with arbitrary length.
    */
    function hasEnoughValidSignatures(
        bytes memory _message,
        bytes memory _signatures,
        IBridgeValidators _validatorContract,
        bool isAMBMessage
    ) internal view {
        require(isAMBMessage || isMessageValid(_message));
        uint256 requiredSignatures = _validatorContract.requiredSignatures();
        uint256 amount;
        assembly {
            amount := and(mload(add(_signatures, 1)), 0xff)
        }
        require(amount >= requiredSignatures);
        bytes32 hash = hashMessage(_message, isAMBMessage);
        address[] memory encounteredAddresses = new address[](requiredSignatures);

        for (uint256 i = 0; i < requiredSignatures; i++) {
            uint8 v;
            bytes32 r;
            bytes32 s;
            uint256 posr = 33 + amount + 32 * i;
            uint256 poss = posr + 32 * amount;
            assembly {
                v := mload(add(_signatures, add(2, i)))
                r := mload(add(_signatures, posr))
                s := mload(add(_signatures, poss))
            }

            address recoveredAddress = ecrecover(hash, v, r, s);
            require(_validatorContract.isValidator(recoveredAddress));
            require(!addressArrayContains(encounteredAddresses, recoveredAddress));
            encounteredAddresses[i] = recoveredAddress;
        }
    }

    function uintToString(uint256 i) internal pure returns (string memory) {
        if (i == 0) return "0";
        uint256 j = i;
        uint256 length;
        while (j != 0) {
            length++;
            j /= 10;
        }
        bytes memory bstr = new bytes(length);
        uint256 k = length - 1;
        while (i != 0) {
            bstr[k--] = bytes1(uint8(48 + (i % 10)));
            i /= 10;
        }
        return string(bstr);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

library ArbitraryMessage {
    /**
    * @dev Unpacks data fields from AMB message
    * layout of message :: bytes:
    * offset  0              : 32 bytes :: uint256 - message length
    * offset 32              : 32 bytes :: bytes32 - messageId
    * offset 64              : 20 bytes :: address - sender address
    * offset 84              : 20 bytes :: address - executor contract
    * offset 104             : 4 bytes  :: uint32  - gasLimit
    * offset 108             : 1 bytes  :: uint8   - source chain id length (X)
    * offset 109             : 1 bytes  :: uint8   - destination chain id length (Y)
    * offset 110             : 1 bytes  :: uint8   - dataType
    * offset 111             : X bytes  :: bytes   - source chain id
    * offset 111 + X         : Y bytes  :: bytes   - destination chain id

    * NOTE: when message structure is changed, make sure that MESSAGE_PACKING_VERSION from VersionableAMB is updated as well
    * NOTE: assembly code uses calldatacopy, make sure that message is passed as the first argument in the calldata
    * @param _data encoded message
    */
    function unpackData(bytes memory _data)
        internal
        pure
        returns (
            bytes32 messageId,
            address sender,
            address executor,
            uint32 gasLimit,
            uint8 dataType,
            uint256[2] memory chainIds,
            bytes memory data
        )
    {
        // 32 (message id) + 20 (sender) + 20 (executor) + 4 (gasLimit) + 1 (source chain id length) + 1 (destination chain id length) + 1 (dataType)
        uint256 srcdataptr = 32 + 20 + 20 + 4 + 1 + 1 + 1;
        uint256 datasize;

        assembly {
            messageId := mload(add(_data, 32)) // 32 bytes
            sender := and(mload(add(_data, 52)), 0xffffffffffffffffffffffffffffffffffffffff) // 20 bytes

            // executor (20 bytes) + gasLimit (4 bytes) + srcChainIdLength (1 byte) + dstChainIdLength (1 bytes) + dataType (1 byte) + remainder (5 bytes)
            let blob := mload(add(_data, 84))

            // after bit shift left 12 bytes are zeros automatically
            executor := shr(96, blob)
            gasLimit := and(shr(64, blob), 0xffffffff)

            dataType := byte(26, blob)

            // load source chain id length
            let chainIdLength := byte(24, blob)

            // at this moment srcdataptr points to sourceChainId

            // mask for sourceChainId
            // e.g. length X -> (1 << (X * 8)) - 1
            let mask := sub(shl(shl(3, chainIdLength), 1), 1)

            // increase payload offset by length of source chain id
            srcdataptr := add(srcdataptr, chainIdLength)

            // write sourceChainId
            mstore(chainIds, and(mload(add(_data, srcdataptr)), mask))

            // at this moment srcdataptr points to destinationChainId

            // load destination chain id length
            chainIdLength := byte(25, blob)

            // mask for destinationChainId
            // e.g. length X -> (1 << (X * 8)) - 1
            mask := sub(shl(shl(3, chainIdLength), 1), 1)

            // increase payload offset by length of destination chain id
            srcdataptr := add(srcdataptr, chainIdLength)

            // write destinationChainId
            mstore(add(chainIds, 32), and(mload(add(_data, srcdataptr)), mask))

            // at this moment srcdataptr points to payload

            // datasize = message length - payload offset
            datasize := sub(mload(_data), srcdataptr)
        }

        data = new bytes(datasize);
        assembly {
            // 36 = 4 (selector) + 32 (bytes length header)
            srcdataptr := add(srcdataptr, 36)

            // calldataload(4) - offset of first bytes argument in the calldata
            calldatacopy(add(data, 32), add(calldataload(4), srcdataptr), datasize)
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

import "../BasicBridge.sol";
import "./VersionableAMB.sol";

contract BasicAMB is BasicBridge, VersionableAMB {
    bytes32 internal constant MAX_GAS_PER_TX = 0x2670ecc91ec356e32067fd27b36614132d727b84a1e03e08f412a4f2cf075974; // keccak256(abi.encodePacked("maxGasPerTx"))
    bytes32 internal constant NONCE = 0x7ab1577440dd7bedf920cb6de2f9fc6bf7ba98c78c85a3fa1f8311aac95e1759; // keccak256(abi.encodePacked("nonce"))
    bytes32 internal constant SOURCE_CHAIN_ID = 0x67d6f42a1ed69c62022f2d160ddc6f2f0acd37ad1db0c24f4702d7d3343a4add; // keccak256(abi.encodePacked("sourceChainId"))
    bytes32 internal constant SOURCE_CHAIN_ID_LENGTH =
        0xe504ae1fd6471eea80f18b8532a61a9bb91fba4f5b837f80a1cfb6752350af44; // keccak256(abi.encodePacked("sourceChainIdLength"))
    bytes32 internal constant DESTINATION_CHAIN_ID = 0xbbd454018e72a3f6c02bbd785bacc49e46292744f3f6761276723823aa332320; // keccak256(abi.encodePacked("destinationChainId"))
    bytes32 internal constant DESTINATION_CHAIN_ID_LENGTH =
        0xfb792ae4ad11102b93f26a51b3749c2b3667f8b561566a4806d4989692811594; // keccak256(abi.encodePacked("destinationChainIdLength"))
    bytes32 internal constant ALLOW_REENTRANT_REQUESTS =
        0xffa3a5a0e192028fc343362a39c5688e5a60819a4dc5ab3ee70c25bc25b78dd6; // keccak256(abi.encodePacked("allowReentrantRequests"))

    /**
     * Initializes AMB contract
     * @param _sourceChainId chain id of a network where this contract is deployed
     * @param _destinationChainId chain id of a network where all outgoing messages are directed
     * @param _validatorContract address of the validators contract
     * @param _maxGasPerTx maximum amount of gas per one message execution
     * @param _gasPrice default gas price used by oracles for sending transactions in this network
     * @param _requiredBlockConfirmations number of block confirmations oracle will wait before processing passed messages
     * @param _owner address of new bridge owner
     */
    function initialize(
        uint256 _sourceChainId,
        uint256 _destinationChainId,
        address _validatorContract,
        uint256 _maxGasPerTx,
        uint256 _gasPrice,
        uint256 _requiredBlockConfirmations,
        address _owner
    ) external onlyRelevantSender returns (bool) {
        require(!isInitialized());
        require(Address.isContract(_validatorContract));

        _setChainIds(_sourceChainId, _destinationChainId);
        addressStorage[VALIDATOR_CONTRACT] = _validatorContract;
        uintStorage[DEPLOYED_AT_BLOCK] = block.number;
        uintStorage[MAX_GAS_PER_TX] = _maxGasPerTx;
        _setGasPrice(_gasPrice);
        _setRequiredBlockConfirmations(_requiredBlockConfirmations);
        _setOwner(_owner);
        setInitialize();

        return isInitialized();
    }

    function getBridgeMode() external pure override returns (bytes4 _data) {
        return 0x2544fbb9; // bytes4(keccak256(abi.encodePacked("arbitrary-message-bridge-core")))
    }

    function maxGasPerTx() public view returns (uint256) {
        return uintStorage[MAX_GAS_PER_TX];
    }

    function setMaxGasPerTx(uint256 _maxGasPerTx) external onlyOwner {
        uintStorage[MAX_GAS_PER_TX] = _maxGasPerTx;
    }

    /**
     * Internal function for retrieving chain id for the source network
     * @return chain id for the current network
     */
    function sourceChainId() public view returns (uint256) {
        return uintStorage[SOURCE_CHAIN_ID];
    }

    /**
     * Internal function for retrieving chain id for the destination network
     * @return chain id for the destination network
     */
    function destinationChainId() public view returns (uint256) {
        return uintStorage[DESTINATION_CHAIN_ID];
    }

    /**
     * Updates chain ids of used networks
     * @param _sourceChainId chain id for current network
     * @param _destinationChainId chain id for opposite network
     */
    function setChainIds(uint256 _sourceChainId, uint256 _destinationChainId) external onlyOwner {
        _setChainIds(_sourceChainId, _destinationChainId);
    }

    /**
     * Sets the flag to allow passing new AMB requests in the opposite direction,
     * while other AMB message is being processed.
     * Only owner can call this method.
     * @param _enable true, if reentrant requests are allowed.
     */
    function setAllowReentrantRequests(bool _enable) external onlyOwner {
        boolStorage[ALLOW_REENTRANT_REQUESTS] = _enable;
    }

    /**
     * Tells if passing reentrant requests is allowed.
     * @return true, if reentrant requests are allowed.
     */
    function allowReentrantRequests() public view returns (bool) {
        return boolStorage[ALLOW_REENTRANT_REQUESTS];
    }

    /**
     * @dev Withdraws the erc20 tokens or native coins from this contract.
     * @param _token address of the claimed token or address(0) for native coins.
     * @param _to address of the tokens/coins receiver.
     */
    function claimTokens(address _token, address _to) external onlyIfUpgradeabilityOwner {
        claimValues(_token, _to);
    }

    /**
     * Internal function for retrieving current nonce value
     * @return nonce value
     */
    function _nonce() internal view returns (uint64) {
        return uint64(uintStorage[NONCE]);
    }

    /**
     * Internal function for updating nonce value
     * @param nonce new nonce value
     */
    function _setNonce(uint64 nonce) internal {
        uintStorage[NONCE] = uint256(nonce);
    }

    /**
     * Internal function for updating chain ids of used networks
     * @param _sourceChainId chain id for current network
     * @param _destinationChainId chain id for opposite network
     */
    function _setChainIds(uint256 _sourceChainId, uint256 _destinationChainId) internal {
        require(_sourceChainId > 0 && _destinationChainId > 0);
        require(_sourceChainId != _destinationChainId);

        // Length fields are needed further when encoding the message.
        // Chain ids are compressed, so that leading zero bytes are not preserved.
        // In order to save some gas during calls to MessageDelivery.c,
        // lengths of chain ids are precalculated and being saved in the storage.
        uint256 sourceChainIdLength = 0;
        uint256 destinationChainIdLength = 0;
        uint256 mask = 0xff;

        for (uint256 i = 1; sourceChainIdLength == 0 || destinationChainIdLength == 0; i++) {
            if (sourceChainIdLength == 0 && _sourceChainId & mask == _sourceChainId) {
                sourceChainIdLength = i;
            }
            if (destinationChainIdLength == 0 && _destinationChainId & mask == _destinationChainId) {
                destinationChainIdLength = i;
            }
            mask = (mask << 8) | 0xff;
        }

        uintStorage[SOURCE_CHAIN_ID] = _sourceChainId;
        uintStorage[SOURCE_CHAIN_ID_LENGTH] = sourceChainIdLength;
        uintStorage[DESTINATION_CHAIN_ID] = _destinationChainId;
        uintStorage[DESTINATION_CHAIN_ID_LENGTH] = destinationChainIdLength;
    }

    /**
     * Internal function for retrieving chain id length for the source network
     * @return chain id for the current network
     */
    function _sourceChainIdLength() internal view returns (uint256) {
        return uintStorage[SOURCE_CHAIN_ID_LENGTH];
    }

    /**
     * Internal function for retrieving chain id length for the destination network
     * @return chain id for the destination network
     */
    function _destinationChainIdLength() internal view returns (uint256) {
        return uintStorage[DESTINATION_CHAIN_ID_LENGTH];
    }

    /**
     * Internal function for validating version of the received message
     * @param _messageId id of the received message
     */
    function _isMessageVersionValid(bytes32 _messageId) internal pure returns (bool) {
        return
            _messageId & 0xffffffff00000000000000000000000000000000000000000000000000000000 == MESSAGE_PACKING_VERSION;
    }

    /**
     * Internal function for validating destination chain id of the received message
     * @param _chainId destination chain id of the received message
     */
    function _isDestinationChainIdValid(uint256 _chainId) internal view returns (bool res) {
        return _chainId == sourceChainId();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "./BasicAMB.sol";
import "./MessageProcessor.sol";
import "../../libraries/ArbitraryMessage.sol";
import "../../libraries/Bytes.sol";

abstract contract MessageDelivery is BasicAMB, MessageProcessor {
    using SafeMath for uint256;

    uint256 internal constant SEND_TO_ORACLE_DRIVEN_LANE = 0x00;
    // after EIP2929, call to warmed contract address costs 100 instead of 2600
    uint256 internal constant MIN_GAS_PER_CALL = 100;

    /**
     * @dev Requests message relay to the opposite network
     * @param _contract executor address on the other side
     * @param _data calldata passed to the executor on the other side
     * @param _gas gas limit used on the other network for executing a message
     */
    function requireToPassMessage(
        address _contract,
        bytes memory _data,
        uint256 _gas
    ) public virtual returns (bytes32) {
        return _sendMessage(_contract, _data, _gas, SEND_TO_ORACLE_DRIVEN_LANE);
    }

    /**
     * @dev Initiates sending of an AMB message to the opposite network
     * @param _contract executor address on the other side
     * @param _data calldata passed to the executor on the other side
     * @param _gas gas limit used on the other network for executing a message
     * @param _dataType AMB message dataType to be included as a part of the header
     */
    function _sendMessage(
        address _contract,
        bytes memory _data,
        uint256 _gas,
        uint256 _dataType
    ) internal returns (bytes32) {
        // it is not allowed to pass messages while other messages are processed
        // if other is not explicitly configured
        require(messageId() == bytes32(0) || allowReentrantRequests());
        require(_gas >= MIN_GAS_PER_CALL && _gas <= maxGasPerTx());

        uint256 selector;
        assembly {
            selector := and(mload(add(_data, 4)), 0xffffffff)
        }
        // In order to prevent possible unauthorized ERC20 withdrawals, the following function signatures are prohibited:
        // * transfer(address,uint256)
        // * approve(address,uint256)
        // * transferFrom(address,address,uint256)
        // * approveAndCall(address,uint256,bytes)
        // * transferAndCall(address,uint256,bytes)
        // See https://medium.com/immunefi/xdai-stake-arbitrary-call-method-bug-postmortem-f80a90ac56e3 for more details
        require(
            selector != 0xa9059cbb &&
                selector != 0x095ea7b3 &&
                selector != 0x23b872dd &&
                selector != 0x4000aea0 &&
                selector != 0xcae9ca51
        );

        (bytes32 _messageId, bytes memory header) = _packHeader(_contract, _gas, _dataType);

        bytes memory eventData = abi.encodePacked(header, _data);

        emitEventOnMessageRequest(_messageId, eventData);
        return _messageId;
    }

    /**
     * @dev Packs message header into a single bytes blob
     * @param _contract executor address on the other side
     * @param _gas gas limit used on the other network for executing a message
     * @param _dataType AMB message dataType to be included as a part of the header
     */
    function _packHeader(
        address _contract,
        uint256 _gas,
        uint256 _dataType
    ) internal returns (bytes32 _messageId, bytes memory header) {
        uint256 srcChainId = sourceChainId();
        uint256 srcChainIdLength = _sourceChainIdLength();
        uint256 dstChainId = destinationChainId();
        uint256 dstChainIdLength = _destinationChainIdLength();

        _messageId = _getNewMessageId(srcChainId);

        // 79 = 4 + 20 + 8 + 20 + 20 + 4 + 1 + 1 + 1
        header = new bytes(79 + srcChainIdLength + dstChainIdLength);

        // In order to save the gas, the header is packed in the reverse order.
        // With such approach, it is possible to store right-aligned values without any additional bit shifts.
        assembly {
            let ptr := add(header, mload(header)) // points to the last word of header
            mstore(ptr, dstChainId)
            mstore(sub(ptr, dstChainIdLength), srcChainId)

            mstore(add(header, 79), _dataType)
            mstore(add(header, 78), dstChainIdLength)
            mstore(add(header, 77), srcChainIdLength)
            mstore(add(header, 76), _gas)
            mstore(add(header, 72), _contract)
            mstore(add(header, 52), caller())
            mstore(add(header, 32), _messageId)
        }
    }

    /**
     * @dev Generates a new messageId for the passed request/message.
     * Increments the nonce accordingly.
     * @param _srcChainId source chain id of the newly created message. Should be a chain id of the current network.
     * @return unique message id to use for the new request/message.
     */
    function _getNewMessageId(uint256 _srcChainId) internal returns (bytes32) {
        uint64 nonce = _nonce();
        _setNonce(nonce + 1);

        // Bridge id is recalculated every time again and again, since it is still cheaper than using SLOAD opcode (800 gas)
        bytes32 bridgeId =
            keccak256(abi.encodePacked(_srcChainId, address(this))) &
                0x00000000ffffffffffffffffffffffffffffffffffffffff0000000000000000;

        return MESSAGE_PACKING_VERSION | bridgeId | bytes32(uint256(nonce));
    }

    /* solcov ignore next */
    function emitEventOnMessageRequest(bytes32 messageId, bytes memory encodedData) internal virtual;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

interface IBridgeValidators {
    function isValidator(address _validator) external view returns (bool);
    function requiredSignatures() external view returns (uint256);
    function owner() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

import "./Upgradeable.sol";
import "./InitializableBridge.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./Validatable.sol";
import "./Ownable.sol";
import "./Claimable.sol";
import "./VersionableBridge.sol";
import "./DecimalShiftBridge.sol";

abstract contract BasicBridge is
    InitializableBridge,
    Validatable,
    Ownable,
    Upgradeable,
    Claimable,
    VersionableBridge,
    DecimalShiftBridge
{
    event GasPriceChanged(uint256 gasPrice);
    event RequiredBlockConfirmationChanged(uint256 requiredBlockConfirmations);

    bytes32 internal constant GAS_PRICE = 0x55b3774520b5993024893d303890baa4e84b1244a43c60034d1ced2d3cf2b04b; // keccak256(abi.encodePacked("gasPrice"))
    bytes32 internal constant REQUIRED_BLOCK_CONFIRMATIONS = 0x916daedf6915000ff68ced2f0b6773fe6f2582237f92c3c95bb4d79407230071; // keccak256(abi.encodePacked("requiredBlockConfirmations"))

    /**
    * @dev Public setter for fallback gas price value. Only bridge owner can call this method.
    * @param _gasPrice new value for the gas price.
    */
    function setGasPrice(uint256 _gasPrice) external onlyOwner {
        _setGasPrice(_gasPrice);
    }

    function gasPrice() external view returns (uint256) {
        return uintStorage[GAS_PRICE];
    }

    function setRequiredBlockConfirmations(uint256 _blockConfirmations) external onlyOwner {
        _setRequiredBlockConfirmations(_blockConfirmations);
    }

    function _setRequiredBlockConfirmations(uint256 _blockConfirmations) internal {
        require(_blockConfirmations > 0);
        uintStorage[REQUIRED_BLOCK_CONFIRMATIONS] = _blockConfirmations;
        emit RequiredBlockConfirmationChanged(_blockConfirmations);
    }

    function requiredBlockConfirmations() external view returns (uint256) {
        return uintStorage[REQUIRED_BLOCK_CONFIRMATIONS];
    }

    /**
    * @dev Internal function for updating fallback gas price value.
    * @param _gasPrice new value for the gas price, zero gas price is allowed.
    */
    function _setGasPrice(uint256 _gasPrice) internal virtual {
        uintStorage[GAS_PRICE] = _gasPrice;
        emit GasPriceChanged(_gasPrice);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

import "../VersionableBridge.sol";

abstract contract VersionableAMB is VersionableBridge {
    // message format version as a single 4-bytes number padded to 32-bytes
    // value, included into every outgoing relay request
    //
    // the message version should be updated every time when
    // - new field appears
    // - some field removed
    // - fields order is changed
    bytes32 internal constant MESSAGE_PACKING_VERSION = bytes32(uint256(0x00050000 << 224));

    /**
     * Returns currently used bridge version
     */
    function getBridgeInterfacesVersion()
        external
        pure 
        override
        returns (
            uint64 major,
            uint64 minor,
            uint64 patch
        )
    {
        return (6, 2, 0);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

import "../interfaces/IUpgradeabilityOwnerStorage.sol";

contract Upgradeable {
    /**
     * @dev Throws if called by any account other than the upgradeability owner.
     */
    modifier onlyIfUpgradeabilityOwner() {
        _onlyIfUpgradeabilityOwner();
        _;
    }

    /**
     * @dev Internal function for reducing onlyIfUpgradeabilityOwner modifier bytecode overhead.
     */
    function _onlyIfUpgradeabilityOwner() internal view {
        require(msg.sender == IUpgradeabilityOwnerStorage(address(this)).upgradeabilityOwner());
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

import "./Initializable.sol";

contract InitializableBridge is Initializable {
    bytes32 internal constant DEPLOYED_AT_BLOCK = 0xb120ceec05576ad0c710bc6e85f1768535e27554458f05dcbb5c65b8c7a749b0; // keccak256(abi.encodePacked("deployedAtBlock"))

    function deployedAtBlock() external view returns (uint256) {
        return uintStorage[DEPLOYED_AT_BLOCK];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
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
        return _functionCallWithValue(target, data, 0, errorMessage);
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
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
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

// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

import "../interfaces/IBridgeValidators.sol";
import "../upgradeability/EternalStorage.sol";
import "./ValidatorStorage.sol";

contract Validatable is EternalStorage, ValidatorStorage {
    function validatorContract() public view returns (IBridgeValidators) {
        return IBridgeValidators(addressStorage[VALIDATOR_CONTRACT]);
    }

    modifier onlyValidator() {
        require(validatorContract().isValidator(msg.sender));
        /* solcov ignore next */
        _;
    }

    function requiredSignatures() public view returns (uint256) {
        return validatorContract().requiredSignatures();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

import "../upgradeability/EternalStorage.sol";
import "../interfaces/IUpgradeabilityOwnerStorage.sol";

/**
 * @title Ownable
 * @dev This contract has an owner address providing basic authorization control
 */
contract Ownable is EternalStorage {
    bytes4 internal constant UPGRADEABILITY_OWNER = 0x6fde8202; // upgradeabilityOwner()

    /**
     * @dev Event to show ownership has been transferred
     * @param previousOwner representing the address of the previous owner
     * @param newOwner representing the address of the new owner
     */
    event OwnershipTransferred(address previousOwner, address newOwner);

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _onlyOwner();
        _;
    }

    /**
     * @dev Internal function for reducing onlyOwner modifier bytecode overhead.
     */
    function _onlyOwner() internal view {
        require(msg.sender == owner());
    }

    /**
     * @dev Throws if called through proxy by any account other than contract itself or an upgradeability owner.
     */
    modifier onlyRelevantSender() {
        (bool isProxy, bytes memory returnData) =
            address(this).staticcall(abi.encodeWithSelector(UPGRADEABILITY_OWNER));
        require(
            !isProxy || // covers usage without calling through storage proxy
                (returnData.length == 32 && msg.sender == abi.decode(returnData, (address))) || // covers usage through regular proxy calls
                msg.sender == address(this) // covers calls through upgradeAndCall proxy method
        );
        _;
    }

    bytes32 internal constant OWNER = 0x02016836a56b71f0d02689e69e326f4f4c1b9057164ef592671cf0d37c8040c0; // keccak256(abi.encodePacked("owner"))

    /**
     * @dev Tells the address of the owner
     * @return the address of the owner
     */
    function owner() public view returns (address) {
        return addressStorage[OWNER];
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner the address to transfer ownership to.
     */
    function transferOwnership(address newOwner) external onlyOwner {
        _setOwner(newOwner);
    }

    /**
     * @dev Sets a new owner address
     */
    function _setOwner(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner(), newOwner);
        addressStorage[OWNER] = newOwner;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../libraries/AddressHelper.sol";

/**
 * @title Claimable
 * @dev Implementation of the claiming utils that can be useful for withdrawing accidentally sent tokens that are not used in bridge operations.
 */
contract Claimable {
    using SafeERC20 for IERC20;

    /**
     * Throws if a given address is equal to address(0)
     */
    modifier validAddress(address _to) {
        require(_to != address(0));
        _;
    }

    /**
     * @dev Withdraws the erc20 tokens or native coins from this contract.
     * Caller should additionally check that the claimed token is not a part of bridge operations (i.e. that token != erc20token()).
     * @param _token address of the claimed token or address(0) for native coins.
     * @param _to address of the tokens/coins receiver.
     */
    function claimValues(address _token, address _to) internal validAddress(_to) {
        if (_token == address(0)) {
            claimNativeCoins(_to);
        } else {
            claimErc20Tokens(_token, _to);
        }
    }

    /**
     * @dev Internal function for withdrawing all native coins from the contract.
     * @param _to address of the coins receiver.
     */
    function claimNativeCoins(address _to) internal {
        uint256 value = address(this).balance;
        AddressHelper.safeSendValue(payable(_to), value);
    }

    /**
     * @dev Internal function for withdrawing all tokens of some particular ERC20 contract from this contract.
     * @param _token address of the claimed ERC20 token.
     * @param _to address of the tokens receiver.
     */
    function claimErc20Tokens(address _token, address _to) internal {
        IERC20 token = IERC20(_token);
        uint256 balance = token.balanceOf(address(this));
        token.safeTransfer(_to, balance);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

abstract contract VersionableBridge {
    function getBridgeInterfacesVersion()
        external
        pure
        virtual
        returns (
            uint64 major,
            uint64 minor,
            uint64 patch
        );

    function getBridgeMode() external pure virtual returns (bytes4);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

import "../upgradeability/EternalStorage.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

contract DecimalShiftBridge is EternalStorage {
    using SafeMath for uint256;

    bytes32 internal constant DECIMAL_SHIFT = 0x1e8ecaafaddea96ed9ac6d2642dcdfe1bebe58a930b1085842d8fc122b371ee5; // keccak256(abi.encodePacked("decimalShift"))

    /**
    * @dev Internal function for setting the decimal shift for bridge operations.
    * Decimal shift can be positive, negative, or equal to zero.
    * It has the following meaning: N tokens in the foreign chain are equivalent to N * pow(10, shift) tokens on the home side.
    * @param _shift new value of decimal shift.
    */
    function _setDecimalShift(int256 _shift) internal {
        // since 1 wei * 10**77 > 2**255, it does not make any sense to use higher values
        require(_shift > -77 && _shift < 77);
        uintStorage[DECIMAL_SHIFT] = uint256(_shift);
    }

    /**
    * @dev Returns the value of foreign-to-home decimal shift.
    * @return decimal shift.
    */
    function decimalShift() public view returns (int256) {
        return int256(uintStorage[DECIMAL_SHIFT]);
    }

    /**
    * @dev Converts the amount of home tokens into the equivalent amount of foreign tokens.
    * @param _value amount of home tokens.
    * @return equivalent amount of foreign tokens.
    */
    function _unshiftValue(uint256 _value) internal view returns (uint256) {
        return _shiftUint(_value, -decimalShift());
    }

    /**
    * @dev Converts the amount of foreign tokens into the equivalent amount of home tokens.
    * @param _value amount of foreign tokens.
    * @return equivalent amount of home tokens.
    */
    function _shiftValue(uint256 _value) internal view returns (uint256) {
        return _shiftUint(_value, decimalShift());
    }

    /**
    * @dev Calculates _value * pow(10, _shift).
    * @param _value amount of tokens.
    * @param _shift decimal shift to apply.
    * @return shifted value.
    */
    function _shiftUint(uint256 _value, int256 _shift) private pure returns (uint256) {
        if (_shift == 0) {
            return _value;
        }
        if (_shift > 0) {
            return _value.mul(10**uint256(_shift));
        }
        return _value.div(10**uint256(-_shift));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

interface IUpgradeabilityOwnerStorage {
    function upgradeabilityOwner() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

import "../upgradeability/EternalStorage.sol";

contract Initializable is EternalStorage {
    bytes32 internal constant INITIALIZED = 0x0a6f646cd611241d8073675e00d1a1ff700fbf1b53fcf473de56d1e6e4b714ba; // keccak256(abi.encodePacked("isInitialized"))

    function setInitialize() internal {
        boolStorage[INITIALIZED] = true;
    }

    function isInitialized() public view returns (bool) {
        return boolStorage[INITIALIZED];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

/**
 * @title EternalStorage
 * @dev This contract holds all the necessary state variables to carry out the storage of any contract.
 */
contract EternalStorage {
    mapping(bytes32 => uint256) internal uintStorage;
    mapping(bytes32 => string) internal stringStorage;
    mapping(bytes32 => address) internal addressStorage;
    mapping(bytes32 => bytes) internal bytesStorage;
    mapping(bytes32 => bool) internal boolStorage;
    mapping(bytes32 => int256) internal intStorage;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

contract ValidatorStorage {
    bytes32 internal constant VALIDATOR_CONTRACT = 0x5a74bb7e202fb8e4bf311841c7d64ec19df195fee77d7e7ae749b27921b6ddfe; // keccak256(abi.encodePacked("validatorContract"))
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

import "../upgradeable_contracts/Sacrifice.sol";

/**
 * @title AddressHelper
 * @dev Helper methods for Address type.
 */
library AddressHelper {
    /**
     * @dev Try to send native tokens to the address. If it fails, it will force the transfer by creating a selfdestruct contract
     * @param _receiver address that will receive the native tokens
     * @param _value the amount of native tokens to send
     */
    function safeSendValue(address payable _receiver, uint256 _value) internal {
        if (!(_receiver).send(_value)) {
            new Sacrifice{ value: _value }(_receiver);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

contract Sacrifice {
    constructor(address payable _recipient) payable {
        selfdestruct(_recipient);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

import "../../upgradeability/EternalStorage.sol";
import "../../libraries/Bytes.sol";

abstract contract MessageProcessor is EternalStorage {
    /**
     * @dev Returns a status of the message that came from the other side.
     * @param _messageId id of the message from the other side that triggered a call.
     * @return true if call executed successfully.
     */
    function messageCallStatus(bytes32 _messageId) external view returns (bool) {
        return boolStorage[keccak256(abi.encodePacked("messageCallStatus", _messageId))];
    }

    /**
     * @dev Sets a status of the message that came from the other side.
     * @param _messageId id of the message from the other side that triggered a call.
     * @param _status execution status, true if executed successfully.
     */
    function setMessageCallStatus(bytes32 _messageId, bool _status) internal {
        boolStorage[keccak256(abi.encodePacked("messageCallStatus", _messageId))] = _status;
    }

    /**
     * @dev Returns a data hash of the failed message that came from the other side.
     * NOTE: dataHash was used previously to identify outgoing message before AMB message id was introduced.
     * It is kept for backwards compatibility with old mediators contracts.
     * @param _messageId id of the message from the other side that triggered a call.
     * @return keccak256 hash of message data.
     */
    function failedMessageDataHash(bytes32 _messageId) external view returns (bytes32) {
        return bytes32(uintStorage[keccak256(abi.encodePacked("failedMessageDataHash", _messageId))]);
    }

    /**
     * @dev Sets a data hash of the failed message that came from the other side.
     * NOTE: dataHash was used previously to identify outgoing message before AMB message id was introduced.
     * It is kept for backwards compatibility with old mediators contracts.
     * @param _messageId id of the message from the other side that triggered a call.
     * @param data of the processed message.
     */
    function setFailedMessageDataHash(bytes32 _messageId, bytes memory data) internal {
        uintStorage[keccak256(abi.encodePacked("failedMessageDataHash", _messageId))] = uint256(keccak256(data));
    }

    /**
     * @dev Returns a receiver address of the failed message that came from the other side.
     * @param _messageId id of the message from the other side that triggered a call.
     * @return receiver address.
     */
    function failedMessageReceiver(bytes32 _messageId) external view returns (address) {
        return addressStorage[keccak256(abi.encodePacked("failedMessageReceiver", _messageId))];
    }

    /**
     * @dev Sets a sender address of the failed message that came from the other side.
     * @param _messageId id of the message from the other side that triggered a call.
     * @param _receiver address of the receiver.
     */
    function setFailedMessageReceiver(bytes32 _messageId, address _receiver) internal {
        addressStorage[keccak256(abi.encodePacked("failedMessageReceiver", _messageId))] = _receiver;
    }

    /**
     * @dev Returns a sender address of the failed message that came from the other side.
     * @param _messageId id of the message from the other side that triggered a call.
     * @return sender address on the other side.
     */
    function failedMessageSender(bytes32 _messageId) external view returns (address) {
        return addressStorage[keccak256(abi.encodePacked("failedMessageSender", _messageId))];
    }

    /**
     * @dev Sets a sender address of the failed message that came from the other side.
     * @param _messageId id of the message from the other side that triggered a call.
     * @param _sender address of the sender on the other side.
     */
    function setFailedMessageSender(bytes32 _messageId, address _sender) internal {
        addressStorage[keccak256(abi.encodePacked("failedMessageSender", _messageId))] = _sender;
    }

    /**
     * @dev Returns an address of the sender on the other side for the currently processed message.
     * Can be used by executors for getting other side caller address.
     */
    function messageSender() external view returns (address sender) {
        assembly {
            // Even though this is not the same as addressStorage[keccak256(abi.encodePacked("messageSender"))],
            // since solidity mapping introduces another level of addressing, such slot change is safe
            // for temporary variables which are cleared at the end of the call execution.
            sender := sload(0x7b58b2a669d8e0992eae9eaef641092c0f686fd31070e7236865557fa1571b5b) // keccak256(abi.encodePacked("messageSender"))
        }
    }

    /**
     * @dev Sets an address of the sender on the other side for the currently processed message.
     * @param _sender address of the sender on the other side.
     */
    function setMessageSender(address _sender) internal {
        assembly {
            // Even though this is not the same as addressStorage[keccak256(abi.encodePacked("messageSender"))],
            // since solidity mapping introduces another level of addressing, such slot change is safe
            // for temporary variables which are cleared at the end of the call execution.
            sstore(0x7b58b2a669d8e0992eae9eaef641092c0f686fd31070e7236865557fa1571b5b, _sender) // keccak256(abi.encodePacked("messageSender"))
        }
    }

    /**
     * @dev Returns an id of the currently processed message.
     * @return id of the message that originated on the other side.
     */
    function messageId() public view returns (bytes32 id) {
        assembly {
            // Even though this is not the same as uintStorage[keccak256(abi.encodePacked("messageId"))],
            // since solidity mapping introduces another level of addressing, such slot change is safe
            // for temporary variables which are cleared at the end of the call execution.
            id := sload(0xe34bb2103dc34f2c144cc216c132d6ffb55dac57575c22e089161bbe65083304) // keccak256(abi.encodePacked("messageId"))
        }
    }

    /**
     * @dev Returns an id of the currently processed message.
     * NOTE: transactionHash was used previously to identify incoming message before AMB message id was introduced.
     * It is kept for backwards compatibility with old mediators contracts, although it doesn't return txHash anymore.
     * @return id of the message that originated on the other side.
     */
    function transactionHash() external view returns (bytes32) {
        return messageId();
    }

    /**
     * @dev Sets a message id of the currently processed message.
     * @param _messageId id of the message that originated on the other side.
     */
    function setMessageId(bytes32 _messageId) internal {
        assembly {
            // Even though this is not the same as uintStorage[keccak256(abi.encodePacked("messageId"))],
            // since solidity mapping introduces another level of addressing, such slot change is safe
            // for temporary variables which are cleared at the end of the call execution.
            sstore(0xe34bb2103dc34f2c144cc216c132d6ffb55dac57575c22e089161bbe65083304, _messageId) // keccak256(abi.encodePacked("messageId"))
        }
    }

    /**
     * @dev Returns an originating chain id of the currently processed message.
     */
    function messageSourceChainId() external view returns (uint256 id) {
        assembly {
            // Even though this is not the same as uintStorage[keccak256(abi.encodePacked("messageSourceChainId"))],
            // since solidity mapping introduces another level of addressing, such slot change is safe
            // for temporary variables which are cleared at the end of the call execution.
            id := sload(0x7f0fcd9e49860f055dd0c1682d635d309ecb5e3011654c716d9eb59a7ddec7d2) // keccak256(abi.encodePacked("messageSourceChainId"))
        }
    }

    /**
     * @dev Sets an originating chain id of the currently processed message.
     * @param _sourceChainId source chain id of the message that originated on the other side.
     */
    function setMessageSourceChainId(uint256 _sourceChainId) internal {
        assembly {
            // Even though this is not the same as uintStorage[keccak256(abi.encodePacked("messageSourceChainId"))],
            // since solidity mapping introduces another level of addressing, such slot change is safe
            // for temporary variables which are cleared at the end of the call execution.
            sstore(0x7f0fcd9e49860f055dd0c1682d635d309ecb5e3011654c716d9eb59a7ddec7d2, _sourceChainId) // keccak256(abi.encodePacked("messageSourceChainId"))
        }
    }

    /**
     * @dev Processes received message. Makes a call to the message executor,
     * sets dataHash, receive, sender variables for failed messages.
     * @param _sender sender address on the other side.
     * @param _executor address of an executor.
     * @param _messageId id of the processed message.
     * @param _gasLimit gas limit for a call to executor.
     * @param _sourceChainId source chain id is of the received message.
     * @param _data calldata for a call to executor.
     */
    function processMessage(
        address _sender,
        address _executor,
        bytes32 _messageId,
        uint256 _gasLimit,
        uint8, /* dataType */
        uint256 _sourceChainId,
        bytes memory _data
    ) internal {
        bool status = _passMessage(_sender, _executor, _data, _gasLimit, _messageId, _sourceChainId);

        setMessageCallStatus(_messageId, status);
        if (!status) {
            setFailedMessageDataHash(_messageId, _data);
            setFailedMessageReceiver(_messageId, _executor);
            setFailedMessageSender(_messageId, _sender);
        }
        emitEventOnMessageProcessed(_sender, _executor, _messageId, status);
    }

    /**
     * @dev Makes a call to the message executor.
     * @param _sender sender address on the other side.
     * @param _contract address of an executor contract.
     * @param _data calldata for a call to executor.
     * @param _gas gas limit for a call to executor. 2^32 - 1, if caller will pass all available gas for the execution.
     * @param _messageId id of the processed message.
     * @param _sourceChainId source chain id is of the received message.
     */
    function _passMessage(
        address _sender,
        address _contract,
        bytes memory _data,
        uint256 _gas,
        bytes32 _messageId,
        uint256 _sourceChainId
    ) internal returns (bool) {
        setMessageSender(_sender);
        setMessageId(_messageId);
        setMessageSourceChainId(_sourceChainId);

        // After EIP-150, max gas cost allowed to be passed to the internal call is equal to the 63/64 of total gas left.
        // In reality, min(gasLimit, 63/64 * gasleft()) will be used as the call gas limit.
        // Imagine a situation, when message requires 10000000 gas to be executed successfully.
        // Also suppose, that at this point, gasleft() is equal to 10158000, so the callee will receive ~ 10158000 * 63 / 64 = 9999300 gas.
        // That amount of gas is not enough, so the call will fail. At the same time,
        // even if the callee failed the bridge contract still has ~ 158000 gas to
        // finish its execution and it will be enough. The internal call fails but
        // only because the oracle provides incorrect gas limit for the transaction
        // This check is needed here in order to force contract to pass exactly the requested amount of gas.
        // Avoiding it may lead to the unwanted message failure in some extreme cases.
        require(_gas == 0xffffffff || (gasleft() * 63) / 64 > _gas);

        (bool status,) = _contract.call{gas: _gas}(_data);
        _validateExecutionStatus(status);
        setMessageSender(address(0));
        setMessageId(bytes32(0));
        setMessageSourceChainId(0);
        return status;
    }

    /**
     * @dev Validates message execution status. In simplest case, does nothing.
     * @param _status message execution status.
     */
    function _validateExecutionStatus(bool _status) internal virtual {
        (_status);
    }

    /* solcov ignore next */
    function emitEventOnMessageProcessed(
        address sender,
        address executor,
        bytes32 _messageId,
        bool status
    ) internal virtual;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

/**
 * @title Bytes
 * @dev Helper methods to transform bytes to other solidity types.
 */
library Bytes {
    /**
     * @dev Truncate bytes array if its size is more than 20 bytes.
     * NOTE: This function does not perform any checks on the received parameter.
     * Make sure that the _bytes argument has a correct length, not less than 20 bytes.
     * A case when _bytes has length less than 20 will lead to the undefined behaviour,
     * since assembly will read data from memory that is not related to the _bytes argument.
     * @param _bytes to be converted to address type
     * @return addr address included in the firsts 20 bytes of the bytes array in parameter.
     */
    function bytesToAddress(bytes memory _bytes) internal pure returns (address addr) {
        assembly {
            addr := mload(add(_bytes, 20))
        }
    }
}