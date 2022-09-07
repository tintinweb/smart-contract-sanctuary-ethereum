// SPDX-License-Identifier: Unlicensed

pragma solidity 0.8.16;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./strings.sol";
import "./base64.sol";
import "./EthboxStructs.sol";

abstract contract EthboxMetadata {
    function buildMetadata(
        address owner,
        EthboxStructs.UnpackedMessage[] memory messages,
        uint256 ethboxSize,
        uint256 ethboxDrip
    ) public view virtual returns (string memory data);
}

contract EthboxV2 is ERC165, IERC721, IERC721Metadata, Initializable, OwnableUpgradeable, ReentrancyGuardUpgradeable, UUPSUpgradeable {
    using Strings for uint256;
    using strings for *;

    //--ERC721 Variables--//

    string private _name;
    string private _symbol;
    EthboxMetadata public metadata;

    /// @notice Mapping to keep track of whether an address has minted an ethbox.
    /// @dev Using a bool rather than number because an address can only mint one.
    mapping(address => bool) public minted;

    //--Messaging Variables--//

    /// @notice The default size an ethbox is set to at mint
    /// @dev This size can be increased for a fee, see { expandEthboxSize }
    uint256 public constant defaultEthboxSize = 3;

    /// @notice The default time it will take for a message to "expire". For example,
    /// someone sends a 1 ETH message, in four weeks all that ETH, minus our fee
    /// will be claimable by the ethbox owner.
    /// @dev This can be changed by ethbox owners, when their ethbox is empty.
    /// This change only affects their ethbox. See { changeEthboxDurationTime }
    uint256 public constant defaultDripTime = 4 weeks;

    /// @notice Max message length somebody can send, this will not change.
    uint256 public constant maxMessageLen = 141;

    /// @notice The initial cost of increasing ethbox size.
    /// @dev Settable by contract owner here { setSizeIncreaseFee }
    uint256 public sizeIncreaseFee;

    /// @notice The BPS increase in fee depending on how many slots the user
    /// already has
    /// @dev Settable by contract owner here { setSizeIncreaseFeeBPS }
    uint256 public sizeIncreaseFeeBPS;

    /// @notice The BPS fee charged by contract owner per message.
    /// @dev Settable by contract owner here { setMessageFeeBPS }
    uint256 public messageFeeBPS;

    /// @notice The recipient of these fees.
    /// @dev Settable by contract owner here { setMessageFeeRecipient }
    address public messageFeeRecipient;

    /// @notice Mapping to keep track of an address' messages.
    /// @dev See { EthboxStructs.Message }
    /// Note: address does not have to mint ethbox to recieve messages.
    /// An unminted ethbox with messages will claim all value upong minting.
    mapping(address => EthboxStructs.Message[]) public ethboxMessages;

    /// @notice Stores ethbox specific information in an address => uint256 mapping
    /// @dev Bits Layout:
    /// - [0..159]   `payoutRecipient`
    /// - [160..223] `drip (timestamp)`
    /// - [224]      `isLocked`
    /// - [225 - 232]  `size`
    /// - [233..255] Currently unused
    /// See { packEthboxInfo } and { unpackEthboxInfo } for implementation.
    mapping(address => uint256) packedEthboxInfo;

    /// @notice Mapping to keep track of remaining eth to be claimed from bumped messages
    /// An unminted ethbox with messages will claim all value upong minting.
    mapping(address => uint256) public bumpedClaimValue;

    //--Packing Constants--//

    /// @dev Bit position of drip timestamp in { packedEthboxInfo }
    /// see { unpackEthboxDrip }
    uint256 private constant BITPOS_ETHBOX_DRIP_TIMESTAMP = 160;

    /// @dev Bit position of ethbox locked boolean in { packedEthboxInfo }
    /// see { unpackEthboxLocked }
    uint256 private constant BITPOS_ETHBOX_LOCKED = 224;

    /// @dev Bit position of ethbox size in { packedEthboxInfo }
    /// see { unpackEthboxSize }
    uint256 private constant BITPOS_ETHBOX_SIZE = 225;

    // Packed message data bit positions. See { EthboxStructs.Message.data }
    // See { packMessageData } and { unpackMessageData } for implementation.

    /// @dev Bit position of timestamp sent in EthboxStructs.Message.data
    /// See { unpackMessageTimestamp }
    uint256 private constant BITPOS_MESSAGE_TIMESTAMP = 160;

    /// @dev Bit position of message index in EthboxStructs.Message.data
    /// See { unpackMessageIndex }
    uint256 private constant BITPOS_MESSAGE_INDEX = 224;

    /// @dev Bit position of message fee BPS in EthboxStructs.Message.data
    /// See { unpackMessageFeeBPS }
    uint256 private constant BITPOS_MESSAGE_FEEBPS = 232;

    /// TODO: Currently not being used.
    uint256 private constant BITMASK_RECIPIENT = (1 << 160) - 1;


    function initialize() public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        _name = "Ethbox";
        _symbol = "ETHBOX";
        sizeIncreaseFee = 0.05 ether;
        sizeIncreaseFeeBPS = 2500;
        messageFeeBPS = 250;
        messageFeeRecipient = 0x40543d76fb35c60ff578b648d723E14CcAb8b390;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    ////////////////////////////////////////
    // ERC721 functions //
    ////////////////////////////////////////

    /// @dev See {ERC721-supportsInterface}.
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /// @notice Returns ethbox balance.
    /// @dev Can only be 1 or 0. As ethboxes are soulbound, if the address
    /// has minted, we know their balance is 1.
    /// @param _owner The address to query.
    /// @return _balance uint256
    function balanceOf(address _owner) public view override returns (uint256) {
        if (minted[_owner]) return 1;
        return 0;
    }

    /// @notice Returns owner of an ethox tokenId.
    /// @dev TokenId is a uint256 casting of an address, so is unique to that address.
    /// Here we re-cast the uint256 to an address to get the owner if minted.
    /// @param _tokenId the tokenId to query.
    function ownerOf(uint256 _tokenId) public view override returns (address) {
        address owner = address(uint160(_tokenId));
        require(minted[owner], "ERC721: invalid token ID");
        return owner;
    }

    /// @notice Returns the ethbox tokenId associated with a given address.
    /// @dev Like { ownerOf } only returns if minted.
    /// We cast the address to a uint256 to generate a unique tokenId.
    /// @param _owner the address to query.
    function ethboxOf(address _owner) public view returns (uint256) {
        require(minted[_owner], "address has not minted their ethbox");
        return uint256(uint160(_owner));
    }

    /// @dev See { ERC721-name }.
    function name() public view override returns (string memory) {
        return _name;
    }

    /// @dev See { ERC721-symbol }.
    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    /// @notice Overridden version of { ERC721-tokenURI }.
    /// @dev First checks if the tokenId has been minted, then gets the owner's
    /// messages ordered by value and inbox size. Metadata contract uses these
    /// ordered messages and size to generate the SVG. See { EthboxMetadata }.
    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(minted[address(uint160(_tokenId))]);
        address owner = address(uint160(_tokenId));
        EthboxStructs.UnpackedMessage[] memory messages = getOrderedMessages(
            owner
        );
        uint256 eSize = unpackEthboxSize(owner);
        uint256 eDrip = unpackEthboxDrip(owner);
        return metadata.buildMetadata(owner, messages, eSize, eDrip);
    }

    /// @dev See { ERC721-getApproved }.
    function getApproved(uint256 _tokenId)
        public
        view
        override
        returns (address)
    {
        require(minted[address(uint160(_tokenId))]);
        return address(0);
    }

    /// @dev Always returns false as transferring is disabled.
    function isApprovedForAll(address, address)
        public
        pure
        override
        returns (bool)
    {
        return false;
    }

    /// @dev All the following functions are disabled to make ethboxes soulbound.

    function approve(address, uint256) public pure override {
        revert("disabled");
    }

    function setApprovalForAll(address, bool) public pure override {
        revert("disabled");
    }

    function transferFrom(
        address,
        address,
        uint256
    ) public pure override {
        revert("disabled");
    }

    function safeTransferFrom(
        address,
        address,
        uint256
    ) public pure override {
        revert("disabled");
    }

    function safeTransferFrom(
        address,
        address,
        uint256,
        bytes memory
    ) public pure override {
        revert("disabled");
    }

    ////////////////////////////////////
    // Minting function //
    ////////////////////////////////////

    /// @notice Function to mint an ethbox to a given address.
    /// Only one per address, no max supply.
    /// @dev We pack the default ethbox info into the { packedEthboxInfo } mapping.
    /// This saves a lot of gas having to set these values in a struct, or various
    /// different mappings.
    function mintMyEthbox() external onlyProxy {
        address sender = msg.sender;
        require(!minted[sender], "ethbox already minted");
        minted[sender] = true;

        packedEthboxInfo[sender] = packEthboxInfo(
            sender,
            defaultDripTime,
            defaultEthboxSize,
            false
        );

        emit Transfer(address(0), sender, uint256(uint160(sender)));
        if (ethboxMessages[sender].length > 0) {
            claimAll();
        }
    }

    //////////////////////////////////////
    // Messaging Functions //
    //////////////////////////////////////

    // @notice Set the base cost of increasing ethbox size.
    /// @param _sizeIncreaseFee The new base increase fee.
    function setSizeIncreaseFee(uint256 _sizeIncreaseFee) external onlyOwner {
        sizeIncreaseFee = _sizeIncreaseFee;
    }

    /// @notice Set the BPS increase in cost of increasing ethbox size depending
    /// on how many slots the ethbox has already bought.
    /// @param _sizeIncreaseFeeBPS The new BPS.
    function setSizeIncreaseFeeBPS(uint256 _sizeIncreaseFeeBPS) external onlyOwner {
        sizeIncreaseFeeBPS = _sizeIncreaseFeeBPS;
    }

    /// @notice Sets message fee in BPS taken by the messageFeeRecipient.
    /// @param _messageFeeBPS the new BPS.
    function setMessageFeeBPS(uint256 _messageFeeBPS) external onlyOwner {
        messageFeeBPS = _messageFeeBPS;
    }

    /// @notice Sets the recipient of the above fees.
    /// @param _messageFeeRecipient the new recipient.
    function setMessageFeeRecipient(address _messageFeeRecipient) external onlyOwner {
        messageFeeRecipient = _messageFeeRecipient;
    }

    /// @notice Sets the metadata contract that { tokenURI } points to.
    /// @dev We want this to be updatable for any future SVG changes or bugfixes.
    function setMetadataContract(address _metadata) external onlyOwner {
        metadata = EthboxMetadata(_metadata);
    }

    /// @notice Gets the claimable value of a message.
    /// @dev Using the timestamp the message was sent at, combined with the
    /// block.timestamp, we calculate how many seconds have elapesed since the
    /// message was sent. From there we can divide the elapsed seconds by the
    /// ethbox's duration (given elapsed seconds are smaller) to calculate the BPS.
    /// Finally we deduct fees from the orignal message value and multiply by BPS
    /// to get the claimable value of that message.
    /// @param _message The message struct to calculate value from.
    /// @param _drip The drip timestamp of the ethbox.
    function getClaimableValue(
        EthboxStructs.Message memory _message,
        uint256 _drip
    ) public view returns (uint256 _claimableValue) {
        uint256 elapsedSeconds = block.timestamp -
            unpackMessageTimestamp(_message.data);

        if (elapsedSeconds < 1) return 0;
        if (elapsedSeconds > _drip) return getRemainingOriginalValue(_message);
        uint256 bps = (elapsedSeconds * 100) / _drip;
        uint256 subValue = (getOriginalValueMinusFees(_message) * bps) / 100;
        return (subValue - _message.claimedValue);
    }

    /// @notice Deducts fees from the original message value.
    /// @dev Used in { getClaimableValue } and { getRemainingOriginalValue }
    /// @param _message The message struct to calculate value from.
    function getOriginalValueMinusFees(EthboxStructs.Message memory _message)
        private
        pure
        returns (uint256)
    {
        return ((_message.originalValue *
            (10000 - unpackMessageFeeBPS(_message.data))) / 10000);
    }

    /// @notice Used to refund message sender any remaining eth in their message
    /// if their message gets bumped out the inbox.
    /// @dev Used in { _refundSender }
    /// @param _message The message struct to calculate value from.
    function getRemainingOriginalValue(EthboxStructs.Message memory _message)
        private
        pure
        returns (uint256)
    {
        return (getOriginalValueMinusFees(_message) - _message.claimedValue);
    }

    /// @notice Function to send a message to an ethbox.
    /// @dev If the message has a high enough value, we bump out the lowest value
    /// message in the ethbox and replace it. But if the ethbox is not full, we
    /// just insert it.
    /// When bumping a message out of an ethbox, if that message has ETH left,
    /// we refund that ETH to the sender.
    /// @param _to The ethbox to send the message to.
    /// @param _message The message content.
    /// @param _drip The ethbox drip.
    function sendMessage(address _to, string calldata _message, uint256 _drip) public payable nonReentrant onlyProxy {
        require(bytes(_message).length < maxMessageLen, "message too long");

        EthboxStructs.EthboxInfo memory ethboxInfo = unpackEthboxInfo(_to);
        uint256 compBoxSize = defaultEthboxSize;
        uint256 compDrip = defaultDripTime;
        if (ethboxInfo.size != 0) {
            compBoxSize = ethboxInfo.size;
            compDrip = ethboxInfo.drip;
        }
        require(!ethboxInfo.locked, "ethbox is locked");
        require(msg.value > 10000 || msg.value == 0, "message value incorrect");
        require(compDrip == _drip, "message drip incorrect");

        EthboxStructs.Message[] memory toMessages = ethboxMessages[_to];

        uint256 dynamicBoxSize = toMessages.length;

        if (dynamicBoxSize < compBoxSize) {
            _pushMessage(
                _to,
                msg.sender,
                _message,
                msg.value,
                dynamicBoxSize
            );
        } else {
            (bool qualifies, uint256 indexToRemove) = _getIndexToReplace(
                toMessages,
                dynamicBoxSize,
                msg.value
            );
            if (qualifies) {
                EthboxStructs.Message memory droppedMessage = toMessages[
                    indexToRemove
                ];

                /// V2 
                /// instead of always adding the current claimValue to the bumpedClaim mapping,
                /// we instead only do that step if the ethbox is minted (and thus has a potentially active owner)
                /// this prevents eth being locked forever (and adding eth to a claimValue mapping) of non-
                /// active owners
                /// if the ethbox is not minted, the time spent in ethbox of messages is "virtually" free, unless an 
                /// owner mints (which could still happen at any time.)
                /// this change also gives more of an incentive for owners to mint/claim when messages are in their box
                /// 
                if (ethboxInfo.size != 0) {
                    uint256 claimValue = getClaimableValue(droppedMessage, compDrip);
                    droppedMessage.claimedValue += claimValue;
                    bumpedClaimValue[_to] += claimValue;
                }
                /// V2
                _refundSender(droppedMessage);
                _insertMessage(
                    _to,
                    msg.sender,
                    _message,
                    msg.value,
                    indexToRemove
                );
            } else {
                revert("message value too low");
            }
        }
        _payFees(msg.value);
    }

    /// @notice Finds the index to replace with a new message.
    /// @dev Used in { sendMessage }.
    /// Also checks if the message even qualifies for replacement - meaning, is
    /// the value of the message larger than at least one of the existing messages.
    /// @param _toMessages The existing messages in the ethbox.
    /// @param _boxSize The size of the ethbox. Used to iterate through.
    /// @param _value The value of the new message.
    /// @return qualifies Does the message qualifiy for replacement.
    /// @return indexToRemove The index to remove and insert the new message into.
    function _getIndexToReplace(
        EthboxStructs.Message[] memory _toMessages,
        uint256 _boxSize,
        uint256 _value
    ) private pure returns (bool qualifies, uint256 indexToRemove) {
        uint256 lowIndex;
        uint256 lowValue = _toMessages[0].originalValue;
        uint256 dripedValue;
        for (uint256 i = 0; i < _boxSize; i++) {
            dripedValue = _toMessages[i].originalValue;
            if (dripedValue < lowValue) {
                lowIndex = i;
                lowValue = dripedValue;
            }
            if (qualifies == false && _value > dripedValue) {
                qualifies = true;
            }
        }
        return (qualifies, lowIndex);
    }

    /// @notice Pushes a message into an ethbox. Used if an ethbox is not full.
    /// @dev Used in { sendMessage }.
    /// Packs message data into a "data" field in the Message struct using
    /// { packMessageData }
    /// @param _to The ethbox the message is being sent to.
    /// @param _from The address sending the message.
    /// @param _message The message content.
    /// @param _value The value of the message.
    /// @param _index The index of the message in the ethbox.
    function _pushMessage(
        address _to,
        address _from,
        string calldata _message,
        uint256 _value,
        uint256 _index
    ) private {
        EthboxStructs.Message memory message;

        message.data = packMessageData(
            _from,
            block.timestamp,
            _index,
            messageFeeBPS
        );

        message.message = _message;
        message.originalValue = _value;
        message.claimedValue = 0;

        ethboxMessages[_to].push(message);
    }

    /// @notice Inserts a message into an ethbox. Used if the ethbox is full.
    /// @dev Used in { sendMessage }.
    /// Packs message data just like { _pushMessage }.
    /// Instead of pushing, we insert the message at a given index.
    // @param _to The ethbox the message is being sent to.
    /// @param _from The address sending the message.
    /// @param _message The message content.
    /// @param _value The value of the message.
    /// @param _index The index to insert the message at and set in Message.data.
    function _insertMessage(
        address _to,
        address _from,
        string calldata _message,
        uint256 _value,
        uint256 _index
    ) private {
        EthboxStructs.Message memory message;

        message.data = packMessageData(
            _from,
            block.timestamp,
            _index,
            messageFeeBPS
        );

        message.message = _message;
        message.originalValue = _value;
        message.claimedValue = 0;

        ethboxMessages[_to][_index] = message;
    }

    /// @notice Removes a message from an ethbox.
    /// @dev Used in { removeOne }
    /// Sets the message to remove to the end of the array and pops it.
    /// Updates the index of the message that assumes the old index of the message
    /// we are deleting. We have to unpack and pack here to do this.
    /// @param _to The ethbox to remove a message from.
    /// @param _index The index to remove.
    function _removeMessage(address _to, uint256 _index) private {
        EthboxStructs.Message[] memory messages = ethboxMessages[_to];

        ethboxMessages[_to][_index] = messages[messages.length - 1];

        EthboxStructs.MessageData memory messageData = unpackMessageData(
            ethboxMessages[_to][_index].data
        );

        ethboxMessages[_to][_index].data = packMessageData(
            messageData.from,
            messageData.timestamp,
            _index,
            messageData.feeBPS
        );

        ethboxMessages[_to].pop();
    }

    /// @notice Removes multiple messages from an ethbox.
    /// @dev Used in { claimAll }
    /// Operates the same as { _removeMessage } but in a for loop.
    /// @param _to The ethbox to remove messages from.
    /// @param _indexes The indexes to remove.
    function _removeMessages(address _to, uint256[] memory _indexes) private {
        EthboxStructs.Message[] memory messages = ethboxMessages[_to];

        for (uint256 i = _indexes.length; i > 0; i--) {
            if (i != messages.length) {
                EthboxStructs.MessageData
                    memory messageData = unpackMessageData(messages[i].data);

                ethboxMessages[_to][_indexes[i - 1]] = messages[
                    messages.length - 1
                ];
                ethboxMessages[_to][_indexes[i - 1]].data = packMessageData(
                    messageData.from,
                    messageData.timestamp,
                    _indexes[i - 1],
                    messageData.feeBPS
                );
            }
            ethboxMessages[_to].pop();
        }
    }

    /// @notice Pays fees to the messageFeeRecipient.
    /// @dev Used in { sendMessage }.
    /// We take the value of the message and multiply by fee BPS to get the
    /// fee owed to the messageFeeRecipient.
    /// @param _value The value of the message.
    function _payFees(uint256 _value) private{
        (bool successFees, ) = messageFeeRecipient.call{
            value: (_value * messageFeeBPS) / 10000
        }("");
        require(successFees, "could not pay fees");
    }

    /// @notice Pays an ethbox owner some value.
    /// @dev Used in { claimOne }, { claimAll }, { removeOne } and { removeAll }.
    /// We need to unpack the fee recipient of the ethbox.
    /// Sends the value to that recipient.
    /// @param _value The value of the message.
    /// @param _to The ethbox owner.
    function _payRecipient(address _to, uint256 _value) private{
        address recipient = unpackEthboxAddress(_to);
        (bool successRecipient, ) = recipient.call{value: _value}("");
        require(successRecipient, "could not pay recipient");
    }

    /// @notice Refunds the sender of a message that has been bumped or removed.
    /// @dev Used in { removeAll }, { removeOne } and { sendMessage }.
    /// Need to unpack who sent the message from Message.data.
    /// @param _message The message used to calculate refundable value and who
    /// to send value to.
    function _refundSender(EthboxStructs.Message memory _message) private {
        uint256 refundValue = getRemainingOriginalValue(_message);
        address from = unpackMessageFrom(_message.data);
        (bool successRefund, ) = from.call{value: refundValue}("");
        require(successRefund);
    }

    /// @notice Orders the messages in an ethbox by value.
    /// @dev Only used in { tokenURI } for metadata purposes.
    /// Unpacks the messages into an UnpackedMessage struct.
    /// See { EthboxStructs.UnpackedMessage }.
    /// @param _to Ethbox owner to query.
    /// @return _messages Ordered messages.
    function getOrderedMessages(address _to)
        public
        view
        returns (EthboxStructs.UnpackedMessage[] memory)
    {
        EthboxStructs.Message[] memory messages = ethboxMessages[_to];

        for (uint256 i = 1; i < messages.length; i++) {
            for (uint256 j = 0; j < i; j++) {
                if (messages[i].originalValue > messages[j].originalValue) {
                    EthboxStructs.Message memory x = messages[i];
                    messages[i] = messages[j];
                    messages[j] = x;
                }
            }
        }
        EthboxStructs.UnpackedMessage[]
            memory unpackedMessages = new EthboxStructs.UnpackedMessage[](
                messages.length
            );
        EthboxStructs.MessageData memory unpackedData;
        for (uint256 k = 0; k < messages.length; k++) {
            EthboxStructs.UnpackedMessage memory newMessage;
            unpackedData = unpackMessageData(messages[k].data);
            newMessage.message = messages[k].message;
            newMessage.originalValue = messages[k].originalValue;
            newMessage.claimedValue = messages[k].claimedValue;
            newMessage.from = unpackedData.from;
            newMessage.timestamp = unpackedData.timestamp;
            newMessage.index = unpackedData.index;
            newMessage.feeBPS = unpackedData.feeBPS;
            unpackedMessages[k] = newMessage;
        }
        return unpackedMessages;
    }

    /// @dev Mimics { getOrderedMessages } without unpacking.
    function getOrderedPackedMessages(address _to)
        public
        view
        returns (EthboxStructs.Message[] memory)
    {
        EthboxStructs.Message[] memory messages = ethboxMessages[_to];

        for (uint256 i = 1; i < messages.length; i++) {
            for (uint256 j = 0; j < i; j++) {
                if (messages[i].originalValue > messages[j].originalValue) {
                    EthboxStructs.Message memory x = messages[i];
                    messages[i] = messages[j];
                    messages[j] = x;
                }
            }
        }
        return messages;
    }

    /// @notice Sets the locked state of an ethbox. If an ethbox is locked it
    /// cannot recieve messages.
    /// @dev We unpack and repack the sender's ethbox info with the new value.
    /// @param _isLocked The locked value to set their ethbox to.
    function changeEthboxLocked(bool _isLocked) external {
        EthboxStructs.EthboxInfo memory ethboxInfo = unpackEthboxInfo(
            msg.sender
        );
        require(ethboxInfo.size != 0, "ethbox needs to be minted");

        packedEthboxInfo[msg.sender] = packEthboxInfo(
            ethboxInfo.recipient,
            ethboxInfo.drip,
            ethboxInfo.size,
            _isLocked
        );
    }

    /// @notice Sets the payout recipient of the ethbox. Allows people to have
    /// their ethbox in cold storage, but get paid into a hot wallet.
    /// @dev We unpack and repack the sender's ethbox info with the new value.
    /// @param _recipient The new recipient of ethbox funds.
    function changeEthboxPayoutRecipient(address _recipient) external {
        EthboxStructs.EthboxInfo memory ethboxInfo = unpackEthboxInfo(
            msg.sender
        );
        require(ethboxInfo.size != 0, "ethbox needs to be minted");

        packedEthboxInfo[msg.sender] = packEthboxInfo(
            _recipient,
            ethboxInfo.drip,
            ethboxInfo.size,
            ethboxInfo.locked
        );
    }

    /// @notice Sets the drip time in an ethbox. This can only be done when the
    /// ethbox is locked and empty.
    /// @dev We unpack and repack the sender's ethbox info with the new value.
    /// @param _dripTime The new drip time of the ethbox's messages.
    function changeEthboxDripTime(uint256 _dripTime) external {
        EthboxStructs.EthboxInfo memory ethboxInfo = unpackEthboxInfo(
            msg.sender
        );
        require(ethboxInfo.size != 0, "ethbox needs to be minted");
        require(
            ethboxMessages[msg.sender].length == 0,
            "ethbox needs to be empty"
        );

        packedEthboxInfo[msg.sender] = packEthboxInfo(
            ethboxInfo.recipient,
            _dripTime,
            ethboxInfo.size,
            ethboxInfo.locked
        );
    }

    /// @notice Expands the ethbox size of the sender.
    /// @dev Sender must have minted.
    /// See { calculateSizeIncreaseCost } for how size increase is calculated.
    /// @param _size New ethbox size.
    function changeEthboxSize(uint256 _size) external payable {
        EthboxStructs.EthboxInfo memory ethboxInfo = unpackEthboxInfo(
            msg.sender
        );
        require(ethboxInfo.size != 0, "ethbox needs to be minted");
        uint256 total = calculateSizeIncreaseCost(_size, ethboxInfo.size);
        require(total == msg.value, total.toString());

        packedEthboxInfo[msg.sender] = packEthboxInfo(
            ethboxInfo.recipient,
            ethboxInfo.drip,
            _size,
            ethboxInfo.locked
        );
        (bool successFees, ) = messageFeeRecipient.call{value: msg.value}("");
        require(successFees);
    }

    /// @notice Calculates the cost of increasing ethbox size to a given value.
    /// @dev Used in { expandEthboxSize }.
    /// Uses { sizeIncreaseFee } and { sizeIncreaseFeeBPS } in calculation.
    /// @param _size The desired ethbox size.
    /// @param _currentSize The current size of the ethbox.
    /// @return total Cost of increasing inbox to desired size.
    function calculateSizeIncreaseCost(uint256 _size, uint256 _currentSize)
        public
        view
        returns (uint256 total)
    {
        require(_size > _currentSize, "new size should be larger");
        total = 0;
        for (uint256 i = _currentSize; i < _size; i++) {
            if (i == defaultEthboxSize) {
                total += sizeIncreaseFee;
            } else {
                total +=
                    (sizeIncreaseFee *
                        ((sizeIncreaseFeeBPS + 10000) **
                            (i - defaultEthboxSize))) /
                    (10000**(i - defaultEthboxSize));
            }
        }
        return total;
    }

    /// @notice Removes all messages from an ethbox.
    /// @dev An ethbox owner may call this so they can change the drip of their
    /// box. This calculates how much each message sender is owed and refunds them.
    /// The ethbox owner claims the remaining ETH.
    function removeAll() external nonReentrant {
        require(minted[msg.sender], "ethbox needs to be minted");
        uint256 claimValue = 0;
        uint256 totalValue = 0;

        EthboxStructs.Message[] memory messages = ethboxMessages[msg.sender];
        uint256 boxSize = messages.length;

        for (uint256 i = 0; i < boxSize; i++) {
            claimValue = getClaimableValue(
                messages[i],
                unpackEthboxDrip(msg.sender)
            );

            totalValue += claimValue;
            ethboxMessages[msg.sender][i].claimedValue += claimValue;
            _refundSender(ethboxMessages[msg.sender][i]);
        }
        delete ethboxMessages[msg.sender];
        _payRecipient(msg.sender, totalValue);
    }

    /// @notice Removes one of the messages in the ethbox.
    /// @dev An ethbox owner may not like a message they have recieved, they can
    /// use this to delete it. Like { removeAll } this calculates how much they
    /// can claim, and how much must be refunded.
    /// We are using the combination of these 3 parameters to guarantee that the ethbox
    /// owner will remove only the message they really intend to, without running the 
    /// risk of being front-run by a sendMessage transaction.
    /// @param _index The index of the message to delete.
    /// @param _messageValue the original value of the message to delete
    /// @param _from the sender of the message to delete
    function removeOne(uint256 _index, uint256 _messageValue, address _from) external nonReentrant {
        require(minted[msg.sender], "ethbox needs to be minted");

        EthboxStructs.Message memory message = ethboxMessages[msg.sender][_index];
        require(_messageValue == message.originalValue, "message at index does not match value");

        EthboxStructs.MessageData memory messageData = unpackMessageData(message.data);
        require(_from == messageData.from, "message at index does not match sender address");

        uint256 claimValue = getClaimableValue(
            message,
            unpackEthboxDrip(msg.sender)
        );

        message.claimedValue += claimValue;
        ethboxMessages[msg.sender][_index] = message;
        _removeMessage(msg.sender, _index);
        _refundSender(message);
        _payRecipient(msg.sender, claimValue);
    }

    /// @notice Function to claim all of the ETH owed to the sender's ethbox.
    /// @dev Calculates how much they are owed for each message and the claims
    /// the ETH. We update the claimed value of the message in the Message struct
    /// so that the owner cannot double claim.
    function claimAll() public nonReentrant {
        require(minted[msg.sender], "ethbox needs to be minted");
        uint256 claimValue = 0;
        uint256 totalValue = 0;

        EthboxStructs.Message[] memory messages = ethboxMessages[msg.sender];
        uint256 boxSize = messages.length;

        uint256[] memory removalIndexes = new uint256[](boxSize);
        uint256 removalCount = 0;

        uint256 dripTime = unpackEthboxDrip(msg.sender);

        for (uint256 i = 0; i < boxSize; i++) {
            EthboxStructs.Message memory message = messages[i];

            claimValue = getClaimableValue(message, dripTime);
            totalValue += claimValue;

            ethboxMessages[msg.sender][i].claimedValue += claimValue;

            if (
                (unpackMessageTimestamp(message.data) + dripTime) <
                block.timestamp
            ) {
                removalIndexes[removalCount] = i;
                removalCount++;
            }
        }

        uint256[] memory trimmedIndexes = new uint256[](removalCount);
        for (uint256 j = 0; j < trimmedIndexes.length; j++) {
            trimmedIndexes[j] = removalIndexes[j];
        }
        totalValue += bumpedClaimValue[msg.sender];
        bumpedClaimValue[msg.sender] = 0;
        _removeMessages(msg.sender, trimmedIndexes);
        _payRecipient(msg.sender, totalValue);
    }

    /// @notice Allows sender to claim ETH from one of their messages.
    /// @dev Uses { getClaimable value } on the message struct with the ethbox's
    /// drip to calculate.
    ///
    /// We are using the combination of these 3 parameters to guarantee that the ethbox
    /// owner will clalim only the message they really intend to, without running the 
    /// risk of being front-run by a sendMessage transaction.
    /// @param _index Index to claim ETH on.
    /// @param _messageValue the original value of the message to delete
    /// @param _from the sender of the message to delete
    function claimOne(uint256 _index, uint256 _messageValue, address _from) external nonReentrant {
        EthboxStructs.EthboxInfo memory ethboxInfo = unpackEthboxInfo(msg.sender);
        require(ethboxInfo.size != 0, "ethbox needs to be minted");

        EthboxStructs.Message memory message = ethboxMessages[msg.sender][_index];
        require(_messageValue == message.originalValue, "message at index does not match value");

        EthboxStructs.MessageData memory messageData = unpackMessageData(message.data);
        require(_from == messageData.from, "message at index does not match sender address");

        uint256 claimValue = getClaimableValue(
            message,
            unpackEthboxDrip(msg.sender)
        );
        if (messageData.timestamp + ethboxInfo.drip < block.timestamp){
            _removeMessage(msg.sender, messageData.index);
        }else {
            ethboxMessages[msg.sender][_index].claimedValue += claimValue;
        }
        _payRecipient(msg.sender, claimValue);
    }

    /// @notice A view function for external use in app or elsewhere.
    /// @dev Mimics how { claimAll } works, without making any payments.
    /// @param _ethboxAddress The ethbox address to query.
    /// @return value The claimable value of the ethbox.
    function getClaimableValueOfEthbox(address _ethboxAddress)
        public
        view
        returns (uint256)
    {
        EthboxStructs.Message[] memory messages = ethboxMessages[
            _ethboxAddress
        ];

        EthboxStructs.EthboxInfo memory ethboxInfo = unpackEthboxInfo(_ethboxAddress);

        uint256 boxSize = messages.length;
        uint256 claimValue = 0;
        uint256 totalValue = 0;
        uint256 realDrip = ethboxInfo.size == 0 ? defaultDripTime : ethboxInfo.drip;

        for (uint256 i = 0; i < boxSize; i++) {
            claimValue = getClaimableValue(
                messages[i],
                realDrip
            );
            totalValue += claimValue;
        }
        totalValue += bumpedClaimValue[_ethboxAddress];
        return totalValue;
    }

    //////////////////////////////////////
    //////////////////////////////////////
    // Packing & Unpacking Functions //
    //////////////////////////////////////
    //////////////////////////////////////

    /// @dev Unpacks the recipient in the packedEthboxInfo uint256.
    /// Used in { _payRecipient }
    /// @param _address The ethbox to query.
    /// @return recipient The payout recipient of the ethbox.
    function unpackEthboxAddress(address _address)
        private
        view
        returns (address)
    {
        return address(uint160(packedEthboxInfo[_address]));
    }

    /// @dev Unpacks the drip in the packedEthboxInfo uint256.
    /// Used in { claimOne }, { getClaimableValueOfEthbox }, { claimAll },
    /// { removeOne } and { removeAll }
    /// @param _address The ethbox to query.
    /// @return timestamp The drip timestamp of the ethbox.
    function unpackEthboxDrip(address _address) private view returns (uint64) {
        return
            uint64(packedEthboxInfo[_address] >> BITPOS_ETHBOX_DRIP_TIMESTAMP);
    }

    /// @dev Unpacks the size in the packedEthboxInfo uint256.
    /// Used in { tokenURI }
    /// @param _address The ethbox to query.
    /// @return size The size of the ethbox.
    function unpackEthboxSize(address _address) private view returns (uint8) {
        return uint8(packedEthboxInfo[_address] >> BITPOS_ETHBOX_SIZE);
    }

    /// @dev Unpacks the locked state in the packedEthboxInfo uint256.
    /// Not being used currently.
    /// @param _address The ethbox to query.
    /// @return isLocked Boolean reflecting whether the ethbox is locked or not.
    function unpackEthboxLocked(address _address) private view returns (bool) {
        uint256 flag = (packedEthboxInfo[_address] >> BITPOS_ETHBOX_LOCKED) &
            uint256(1);
        return flag != 0;
    }

    /// @dev Unpacks the entire packedEthboxInfo uint256 into an EthboxInfo struct.
    /// See { EthboxStructs.EthboxInfo }.
    /// Used in { expandEthboxSize }, { changeEthboxDurationTime },
    /// { changeEthboxPayoutRecipient }, { setEthboxIsLocked } and { sendMessage }.
    /// @param _address Address to unpack the ethbox of.
    /// @return ethbox The ethbox's info.
    function unpackEthboxInfo(address _address)
        public
        view
        returns (EthboxStructs.EthboxInfo memory ethbox)
    {
        uint256 packedEthbox = packedEthboxInfo[_address];
        ethbox.recipient = address(uint160(packedEthbox));
        ethbox.drip = uint64(packedEthbox >> BITPOS_ETHBOX_DRIP_TIMESTAMP);
        ethbox.size = uint8(packedEthbox >> BITPOS_ETHBOX_SIZE);
        ethbox.locked =
            ((packedEthbox >> BITPOS_ETHBOX_LOCKED) & uint256(1)) != 0;
    }

    /// @dev Packs an ethbox's info.
    /// Does this by casting each input to a specific part of a uint256.
    /// Used in all the same functions as { unpackEthboxInfo } and used by
    /// { mintMyEthbox }.
    /// @param _recipient Payout recipient of the ethbox.
    /// @param _drip Drip timestamp of the ethbox.
    /// @param _size Size of the ethbox.
    /// @param _locked Locked state of the ethbox.
    /// @return packed The packed ethbox info.
    function packEthboxInfo(
        address _recipient,
        uint256 _drip,
        uint256 _size,
        bool _locked
    ) private pure returns (uint256) {
        uint256 packedEthbox = uint256(uint160(_recipient));
        packedEthbox |=
            (_drip << BITPOS_ETHBOX_DRIP_TIMESTAMP) |
            (boolToUint(_locked) << BITPOS_ETHBOX_LOCKED) |
            (_size << BITPOS_ETHBOX_SIZE);
        return packedEthbox;
    }

    /// @dev Casts a boolean value to a uint256. True -> 1, False -> 0.
    /// Helper used in { packEthboxInfo }
    function boolToUint(bool _b) private pure returns (uint256) {
        uint256 _bInt;
        assembly {
            // SAFETY: Simple bool-to-int cast.
            _bInt := _b
        }
        return _bInt;
    }

    /// @dev Packs part of the Message struct into a "data" field.
    /// Used in { _removeMessage/s }, { _insertMessage } and { _pushMessage }.
    /// Using the same method as { packEthboxInfo }, we cast each input to a
    /// specific part of the uint256 we return.
    /// @param _from The from address of the message.
    /// @param _timestamp The timestamp the message was sent at.
    /// @param _index The index of the message in the ethbox.
    /// @param _feeBPS The global feeBPS at the time of the message being sent.
    /// @return packed The packed message data.
    function packMessageData(
        address _from,
        uint256 _timestamp,
        uint256 _index,
        uint256 _feeBPS
    ) private pure returns (uint256) {
        uint256 packedEthbox = uint256(uint160(_from));
        packedEthbox |=
            (_timestamp << BITPOS_MESSAGE_TIMESTAMP) |
            (_index << BITPOS_MESSAGE_INDEX) |
            (_feeBPS << BITPOS_MESSAGE_FEEBPS);
        return packedEthbox;
    }

    /// @dev Unpacks the message data into a MessageData stuct.
    /// See { EthboxStructs.MessageData }.
    /// Used in { _removeMessage/s }.
    /// Using the same method as { unpackEthboxInfo } we shift bits back to
    /// where they once were, and apply appropriate data types.
    /// @param _data Message data to unpack.
    /// @return messageData Unpacked message data.
    function unpackMessageData(uint256 _data)
        private
        pure
        returns (EthboxStructs.MessageData memory messageData)
    {
        messageData.from = address(uint160(_data));
        messageData.timestamp = uint64(_data >> BITPOS_MESSAGE_TIMESTAMP);
        messageData.index = uint8(_data >> BITPOS_MESSAGE_INDEX);
        messageData.feeBPS = uint24(_data >> BITPOS_MESSAGE_FEEBPS);
    }

    /// @dev Unpacks the sent timestamp in packed message data.
    /// Used in { claimAll } and { getClaimableValue }.
    /// @param _data Data to unpack.
    /// @return timestamp Timestamp the message was sent at.
    function unpackMessageTimestamp(uint256 _data)
        private
        pure
        returns (uint64)
    {
        return uint64(_data >> BITPOS_MESSAGE_TIMESTAMP);
    }

    /// @dev Unpacks the feeBPS in packed message data.
    /// Used in { getOriginalValueMinusFees }
    /// @param _data Data to unpack.
    /// @return feeBPS FeeBPS when the message was sent.
    function unpackMessageFeeBPS(uint256 _data) private pure returns (uint24) {
        return uint24(_data >> BITPOS_MESSAGE_FEEBPS);
    }

    /// @dev Unpacks the index in packed message data.
    /// Currently not being used.
    /// @param _data Data to unpack.
    /// @return index Index of the message in the ethbox.
    function unpackMessageIndex(uint256 _data) private pure returns (uint8) {
        return uint8(_data >> BITPOS_MESSAGE_INDEX);
    }

    /// @dev Unpacks the message sender in packed message data.
    /// Used in { _refundSender }
    /// @param _data Data to unpack.
    /// @return sender Sender of the message.
    function unpackMessageFrom(uint256 _data) private pure returns (address) {
        return address(uint160(_data));
    }

    //--External Unpacking Functions for Use In App and Elsewhere--//

    /// @dev These do the same as the above functions, but are just external.
    /// Please refer back to the documentation for { unpackEthboxInfo }.

    function ethboxDripTime(address _owner) external view returns (uint256) {
        if (minted[_owner]) return unpackEthboxInfo(_owner).drip;
        return defaultDripTime;
    }

    function ethboxPayoutRecipient(address _owner) external view returns (address) {
        if (minted[_owner]) return unpackEthboxInfo(_owner).recipient;
        return _owner;
        
    }

    function ethboxSize(address _owner) external view returns (uint256) {
        if (minted[_owner]) return unpackEthboxInfo(_owner).size;
        return defaultEthboxSize;
    }

    function ethboxLocked(address _owner) external view returns (bool) {
        if (minted[_owner]) return unpackEthboxInfo(_owner).locked;
        return false;
    }

    /// @dev Refunds the value of a message if the owner didn't mint
    /// V2
    /// @param _index The index of the message to delete and refund
    /// @param _messageValue the original value of the message to delete and refund
    /// @param _to the address of the targeted ethbox
    function getRefundForMessage(uint256 _index, uint256 _messageValue, address _to) external nonReentrant {
        require(!minted[_to], "ethbox needs to be not minted");

        EthboxStructs.Message memory message = ethboxMessages[_to][_index];
        require(_messageValue == message.originalValue, "message at index does not match value");

        EthboxStructs.MessageData memory messageData = unpackMessageData(message.data);
        require(msg.sender == messageData.from, "message at index does not match your address");

        uint256 elapsedSeconds = block.timestamp - messageData.timestamp;
        require(elapsedSeconds > defaultDripTime, "message needs to be expired");

        _removeMessage(_to, _index);
        _refundSender(message);
    }
}

// SPDX-License-Identifier: Unlicensed

pragma solidity 0.8.16;

library EthboxStructs {
    struct Message {
        string message;
        uint256 originalValue;
        uint256 claimedValue;
        uint256 data;
    }

    struct MessageData {
        address from;
        uint64 timestamp;
        uint8 index;
        uint24 feeBPS;
    }

    struct UnpackedMessage {
        string message;
        uint256 originalValue;
        uint256 claimedValue;
        address from;
        uint64 timestamp;
        uint8 index;
        uint24 feeBPS;
    }

    struct MessageInfo {
        address to;
        string visibility;
        UnpackedMessage message;
        uint256 index;
        uint256 maxSize;
    }

    struct EthboxInfo {
        address recipient;
        uint8 size;
        bool locked;
        uint64 drip;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library Base64 {
    string internal constant TABLE_ENCODE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    bytes  internal constant TABLE_DECODE = hex"0000000000000000000000000000000000000000000000000000000000000000"
                                            hex"00000000000000000000003e0000003f3435363738393a3b3c3d000000000000"
                                            hex"00000102030405060708090a0b0c0d0e0f101112131415161718190000000000"
                                            hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';

        // load the table into memory
        string memory table = TABLE_ENCODE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {}
            {
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr( 6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(        input,  0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }

        return result;
    }

    function decode(string memory _data) internal pure returns (bytes memory) {
        bytes memory data = bytes(_data);

        if (data.length == 0) return new bytes(0);
        require(data.length % 4 == 0, "invalid base64 decoder input");

        // load the table into memory
        bytes memory table = TABLE_DECODE;

        // every 4 characters represent 3 bytes
        uint256 decodedLen = (data.length / 4) * 3;

        // add some extra buffer at the end required for the writing
        bytes memory result = new bytes(decodedLen + 32);

        assembly {
            // padding with '='
            let lastBytes := mload(add(data, mload(data)))
            if eq(and(lastBytes, 0xFF), 0x3d) {
                decodedLen := sub(decodedLen, 1)
                if eq(and(lastBytes, 0xFFFF), 0x3d3d) {
                    decodedLen := sub(decodedLen, 1)
                }
            }

            // set the actual output length
            mstore(result, decodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 4 characters at a time
            for {} lt(dataPtr, endPtr) {}
            {
               // read 4 characters
               dataPtr := add(dataPtr, 4)
               let input := mload(dataPtr)

               // write 3 bytes
               let output := add(
                   add(
                       shl(18, and(mload(add(tablePtr, and(shr(24, input), 0xFF))), 0xFF)),
                       shl(12, and(mload(add(tablePtr, and(shr(16, input), 0xFF))), 0xFF))),
                   add(
                       shl( 6, and(mload(add(tablePtr, and(shr( 8, input), 0xFF))), 0xFF)),
                               and(mload(add(tablePtr, and(        input , 0xFF))), 0xFF)
                    )
                )
                mstore(resultPtr, shl(232, output))
                resultPtr := add(resultPtr, 3)
            }
        }

        return result;
    }
}

/*
 * @title String & slice utility library for Solidity contracts.
 * @author Nick Johnson <[email protected]>
 *
 * @dev Functionality in this library is largely implemented using an
 *      abstraction called a 'slice'. A slice represents a part of a string -
 *      anything from the entire string to a single character, or even no
 *      characters at all (a 0-length slice). Since a slice only has to specify
 *      an offset and a length, copying and manipulating slices is a lot less
 *      expensive than copying and manipulating the strings they reference.
 *
 *      To further reduce gas costs, most functions on slice that need to return
 *      a slice modify the original one instead of allocating a new one; for
 *      instance, `s.split(".")` will return the text up to the first '.',
 *      modifying s to only contain the remainder of the string after the '.'.
 *      In situations where you do not want to modify the original slice, you
 *      can make a copy first with `.copy()`, for example:
 *      `s.copy().split(".")`. Try and avoid using this idiom in loops; since
 *      Solidity has no memory management, it will result in allocating many
 *      short-lived slices that are later discarded.
 *
 *      Functions that return two slices come in two versions: a non-allocating
 *      version that takes the second slice as an argument, modifying it in
 *      place, and an allocating version that allocates and returns the second
 *      slice; see `nextRune` for example.
 *
 *      Functions that have to copy string data will return strings rather than
 *      slices; these can be cast back to slices for further processing if
 *      required.
 *
 *      For convenience, some functions are provided with non-modifying
 *      variants that create a new slice and return both; for instance,
 *      `s.splitNew('.')` leaves s unmodified, and returns two values
 *      corresponding to the left and right parts of the string.
 */

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library strings {
    struct slice {
        uint256 _len;
        uint256 _ptr;
    }

    function memcpy(
        uint256 dest,
        uint256 src,
        uint256 length
    ) private pure {
        // Copy word-length chunks while possible
        for (; length >= 32; length -= 32) {
            assembly {
                mstore(dest, mload(src))
            }
            dest += 32;
            src += 32;
        }

        // Copy remaining bytes
        uint256 mask = type(uint256).max;
        if (length > 0) {
            mask = 256**(32 - length) - 1;
        }
        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }
    }

    /*
     * @dev Returns a slice containing the entire string.
     * @param self The string to make a slice from.
     * @return A newly allocated slice containing the entire string.
     */
    function toSlice(string memory self) internal pure returns (slice memory) {
        uint256 ptr;
        assembly {
            ptr := add(self, 0x20)
        }
        return slice(bytes(self).length, ptr);
    }

    /*
     * @dev Returns the length of a null-terminated bytes32 string.
     * @param self The value to find the length of.
     * @return The length of the string, from 0 to 32.
     */
    function len(bytes32 self) internal pure returns (uint256) {
        uint256 ret;
        if (self == 0) return 0;
        if (uint256(self) & type(uint128).max == 0) {
            ret += 16;
            self = bytes32(uint256(self) / 0x100000000000000000000000000000000);
        }
        if (uint256(self) & type(uint64).max == 0) {
            ret += 8;
            self = bytes32(uint256(self) / 0x10000000000000000);
        }
        if (uint256(self) & type(uint32).max == 0) {
            ret += 4;
            self = bytes32(uint256(self) / 0x100000000);
        }
        if (uint256(self) & type(uint16).max == 0) {
            ret += 2;
            self = bytes32(uint256(self) / 0x10000);
        }
        if (uint256(self) & type(uint8).max == 0) {
            ret += 1;
        }
        return 32 - ret;
    }

    /*
     * @dev Returns a slice containing the entire bytes32, interpreted as a
     *      null-terminated utf-8 string.
     * @param self The bytes32 value to convert to a slice.
     * @return A new slice containing the value of the input argument up to the
     *         first null.
     */
    function toSliceB32(bytes32 self) internal pure returns (slice memory ret) {
        // Allocate space for `self` in memory, copy it there, and point ret at it
        assembly {
            let ptr := mload(0x40)
            mstore(0x40, add(ptr, 0x20))
            mstore(ptr, self)
            mstore(add(ret, 0x20), ptr)
        }
        ret._len = len(self);
    }

    /*
     * @dev Returns a new slice containing the same data as the current slice.
     * @param self The slice to copy.
     * @return A new slice containing the same data as `self`.
     */
    function copy(slice memory self) internal pure returns (slice memory) {
        return slice(self._len, self._ptr);
    }

    /*
     * @dev Copies a slice to a new string.
     * @param self The slice to copy.
     * @return A newly allocated string containing the slice's text.
     */
    function toString(slice memory self) internal pure returns (string memory) {
        string memory ret = new string(self._len);
        uint256 retptr;
        assembly {
            retptr := add(ret, 32)
        }

        memcpy(retptr, self._ptr, self._len);
        return ret;
    }

    /*
     * @dev Returns the length in runes of the slice. Note that this operation
     *      takes time proportional to the length of the slice; avoid using it
     *      in loops, and call `slice.empty()` if you only need to know whether
     *      the slice is empty or not.
     * @param self The slice to operate on.
     * @return The length of the slice in runes.
     */
    function len(slice memory self) internal pure returns (uint256 l) {
        // Starting at ptr-31 means the LSB will be the byte we care about
        uint256 ptr = self._ptr - 31;
        uint256 end = ptr + self._len;
        for (l = 0; ptr < end; l++) {
            uint8 b;
            assembly {
                b := and(mload(ptr), 0xFF)
            }
            if (b < 0x80) {
                ptr += 1;
            } else if (b < 0xE0) {
                ptr += 2;
            } else if (b < 0xF0) {
                ptr += 3;
            } else if (b < 0xF8) {
                ptr += 4;
            } else if (b < 0xFC) {
                ptr += 5;
            } else {
                ptr += 6;
            }
        }
    }

    /*
     * @dev Returns true if the slice is empty (has a length of 0).
     * @param self The slice to operate on.
     * @return True if the slice is empty, False otherwise.
     */
    function empty(slice memory self) internal pure returns (bool) {
        return self._len == 0;
    }

    /*
     * @dev Returns a positive number if `other` comes lexicographically after
     *      `self`, a negative number if it comes before, or zero if the
     *      contents of the two slices are equal. Comparison is done per-rune,
     *      on unicode codepoints.
     * @param self The first slice to compare.
     * @param other The second slice to compare.
     * @return The result of the comparison.
     */
    function compare(slice memory self, slice memory other)
        internal
        pure
        returns (int256)
    {
        uint256 shortest = self._len;
        if (other._len < self._len) shortest = other._len;

        uint256 selfptr = self._ptr;
        uint256 otherptr = other._ptr;
        for (uint256 idx = 0; idx < shortest; idx += 32) {
            uint256 a;
            uint256 b;
            assembly {
                a := mload(selfptr)
                b := mload(otherptr)
            }
            if (a != b) {
                // Mask out irrelevant bytes and check again
                uint256 mask = type(uint256).max; // 0xffff...
                if (shortest < 32) {
                    mask = ~(2**(8 * (32 - shortest + idx)) - 1);
                }
                unchecked {
                    uint256 diff = (a & mask) - (b & mask);
                    if (diff != 0) return int256(diff);
                }
            }
            selfptr += 32;
            otherptr += 32;
        }
        return int256(self._len) - int256(other._len);
    }

    /*
     * @dev Returns true if the two slices contain the same text.
     * @param self The first slice to compare.
     * @param self The second slice to compare.
     * @return True if the slices are equal, false otherwise.
     */
    function equals(slice memory self, slice memory other)
        internal
        pure
        returns (bool)
    {
        return compare(self, other) == 0;
    }

    /*
     * @dev Extracts the first rune in the slice into `rune`, advancing the
     *      slice to point to the next rune and returning `self`.
     * @param self The slice to operate on.
     * @param rune The slice that will contain the first rune.
     * @return `rune`.
     */
    function nextRune(slice memory self, slice memory rune)
        internal
        pure
        returns (slice memory)
    {
        rune._ptr = self._ptr;

        if (self._len == 0) {
            rune._len = 0;
            return rune;
        }

        uint256 l;
        uint256 b;
        // Load the first byte of the rune into the LSBs of b
        assembly {
            b := and(mload(sub(mload(add(self, 32)), 31)), 0xFF)
        }
        if (b < 0x80) {
            l = 1;
        } else if (b < 0xE0) {
            l = 2;
        } else if (b < 0xF0) {
            l = 3;
        } else {
            l = 4;
        }

        // Check for truncated codepoints
        if (l > self._len) {
            rune._len = self._len;
            self._ptr += self._len;
            self._len = 0;
            return rune;
        }

        self._ptr += l;
        self._len -= l;
        rune._len = l;
        return rune;
    }

    /*
     * @dev Returns the first rune in the slice, advancing the slice to point
     *      to the next rune.
     * @param self The slice to operate on.
     * @return A slice containing only the first rune from `self`.
     */
    function nextRune(slice memory self)
        internal
        pure
        returns (slice memory ret)
    {
        nextRune(self, ret);
    }

    /*
     * @dev Returns the number of the first codepoint in the slice.
     * @param self The slice to operate on.
     * @return The number of the first codepoint in the slice.
     */
    function ord(slice memory self) internal pure returns (uint256 ret) {
        if (self._len == 0) {
            return 0;
        }

        uint256 word;
        uint256 length;
        uint256 divisor = 2**248;

        // Load the rune into the MSBs of b
        assembly {
            word := mload(mload(add(self, 32)))
        }
        uint256 b = word / divisor;
        if (b < 0x80) {
            ret = b;
            length = 1;
        } else if (b < 0xE0) {
            ret = b & 0x1F;
            length = 2;
        } else if (b < 0xF0) {
            ret = b & 0x0F;
            length = 3;
        } else {
            ret = b & 0x07;
            length = 4;
        }

        // Check for truncated codepoints
        if (length > self._len) {
            return 0;
        }

        for (uint256 i = 1; i < length; i++) {
            divisor = divisor / 256;
            b = (word / divisor) & 0xFF;
            if (b & 0xC0 != 0x80) {
                // Invalid UTF-8 sequence
                return 0;
            }
            ret = (ret * 64) | (b & 0x3F);
        }

        return ret;
    }

    /*
     * @dev Returns the keccak-256 hash of the slice.
     * @param self The slice to hash.
     * @return The hash of the slice.
     */
    function keccak(slice memory self) internal pure returns (bytes32 ret) {
        assembly {
            ret := keccak256(mload(add(self, 32)), mload(self))
        }
    }

    /*
     * @dev Returns true if `self` starts with `needle`.
     * @param self The slice to operate on.
     * @param needle The slice to search for.
     * @return True if the slice starts with the provided text, false otherwise.
     */
    function startsWith(slice memory self, slice memory needle)
        internal
        pure
        returns (bool)
    {
        if (self._len < needle._len) {
            return false;
        }

        if (self._ptr == needle._ptr) {
            return true;
        }

        bool equal;
        assembly {
            let length := mload(needle)
            let selfptr := mload(add(self, 0x20))
            let needleptr := mload(add(needle, 0x20))
            equal := eq(
                keccak256(selfptr, length),
                keccak256(needleptr, length)
            )
        }
        return equal;
    }

    /*
     * @dev If `self` starts with `needle`, `needle` is removed from the
     *      beginning of `self`. Otherwise, `self` is unmodified.
     * @param self The slice to operate on.
     * @param needle The slice to search for.
     * @return `self`
     */
    function beyond(slice memory self, slice memory needle)
        internal
        pure
        returns (slice memory)
    {
        if (self._len < needle._len) {
            return self;
        }

        bool equal = true;
        if (self._ptr != needle._ptr) {
            assembly {
                let length := mload(needle)
                let selfptr := mload(add(self, 0x20))
                let needleptr := mload(add(needle, 0x20))
                equal := eq(
                    keccak256(selfptr, length),
                    keccak256(needleptr, length)
                )
            }
        }

        if (equal) {
            self._len -= needle._len;
            self._ptr += needle._len;
        }

        return self;
    }

    /*
     * @dev Returns true if the slice ends with `needle`.
     * @param self The slice to operate on.
     * @param needle The slice to search for.
     * @return True if the slice starts with the provided text, false otherwise.
     */
    function endsWith(slice memory self, slice memory needle)
        internal
        pure
        returns (bool)
    {
        if (self._len < needle._len) {
            return false;
        }

        uint256 selfptr = self._ptr + self._len - needle._len;

        if (selfptr == needle._ptr) {
            return true;
        }

        bool equal;
        assembly {
            let length := mload(needle)
            let needleptr := mload(add(needle, 0x20))
            equal := eq(
                keccak256(selfptr, length),
                keccak256(needleptr, length)
            )
        }

        return equal;
    }

    /*
     * @dev If `self` ends with `needle`, `needle` is removed from the
     *      end of `self`. Otherwise, `self` is unmodified.
     * @param self The slice to operate on.
     * @param needle The slice to search for.
     * @return `self`
     */
    function until(slice memory self, slice memory needle)
        internal
        pure
        returns (slice memory)
    {
        if (self._len < needle._len) {
            return self;
        }

        uint256 selfptr = self._ptr + self._len - needle._len;
        bool equal = true;
        if (selfptr != needle._ptr) {
            assembly {
                let length := mload(needle)
                let needleptr := mload(add(needle, 0x20))
                equal := eq(
                    keccak256(selfptr, length),
                    keccak256(needleptr, length)
                )
            }
        }

        if (equal) {
            self._len -= needle._len;
        }

        return self;
    }

    // Returns the memory address of the first byte of the first occurrence of
    // `needle` in `self`, or the first byte after `self` if not found.
    function findPtr(
        uint256 selflen,
        uint256 selfptr,
        uint256 needlelen,
        uint256 needleptr
    ) private pure returns (uint256) {
        uint256 ptr = selfptr;
        uint256 idx;

        if (needlelen <= selflen) {
            if (needlelen <= 32) {
                bytes32 mask;
                if (needlelen > 0) {
                    mask = bytes32(~(2**(8 * (32 - needlelen)) - 1));
                }

                bytes32 needledata;
                assembly {
                    needledata := and(mload(needleptr), mask)
                }

                uint256 end = selfptr + selflen - needlelen;
                bytes32 ptrdata;
                assembly {
                    ptrdata := and(mload(ptr), mask)
                }

                while (ptrdata != needledata) {
                    if (ptr >= end) return selfptr + selflen;
                    ptr++;
                    assembly {
                        ptrdata := and(mload(ptr), mask)
                    }
                }
                return ptr;
            } else {
                // For long needles, use hashing
                bytes32 hash;
                assembly {
                    hash := keccak256(needleptr, needlelen)
                }

                for (idx = 0; idx <= selflen - needlelen; idx++) {
                    bytes32 testHash;
                    assembly {
                        testHash := keccak256(ptr, needlelen)
                    }
                    if (hash == testHash) return ptr;
                    ptr += 1;
                }
            }
        }
        return selfptr + selflen;
    }

    // Returns the memory address of the first byte after the last occurrence of
    // `needle` in `self`, or the address of `self` if not found.
    function rfindPtr(
        uint256 selflen,
        uint256 selfptr,
        uint256 needlelen,
        uint256 needleptr
    ) private pure returns (uint256) {
        uint256 ptr;

        if (needlelen <= selflen) {
            if (needlelen <= 32) {
                bytes32 mask;
                if (needlelen > 0) {
                    mask = bytes32(~(2**(8 * (32 - needlelen)) - 1));
                }

                bytes32 needledata;
                assembly {
                    needledata := and(mload(needleptr), mask)
                }

                ptr = selfptr + selflen - needlelen;
                bytes32 ptrdata;
                assembly {
                    ptrdata := and(mload(ptr), mask)
                }

                while (ptrdata != needledata) {
                    if (ptr <= selfptr) return selfptr;
                    ptr--;
                    assembly {
                        ptrdata := and(mload(ptr), mask)
                    }
                }
                return ptr + needlelen;
            } else {
                // For long needles, use hashing
                bytes32 hash;
                assembly {
                    hash := keccak256(needleptr, needlelen)
                }
                ptr = selfptr + (selflen - needlelen);
                while (ptr >= selfptr) {
                    bytes32 testHash;
                    assembly {
                        testHash := keccak256(ptr, needlelen)
                    }
                    if (hash == testHash) return ptr + needlelen;
                    ptr -= 1;
                }
            }
        }
        return selfptr;
    }

    /*
     * @dev Modifies `self` to contain everything from the first occurrence of
     *      `needle` to the end of the slice. `self` is set to the empty slice
     *      if `needle` is not found.
     * @param self The slice to search and modify.
     * @param needle The text to search for.
     * @return `self`.
     */
    function find(slice memory self, slice memory needle)
        internal
        pure
        returns (slice memory)
    {
        uint256 ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr);
        self._len -= ptr - self._ptr;
        self._ptr = ptr;
        return self;
    }

    /*
     * @dev Modifies `self` to contain the part of the string from the start of
     *      `self` to the end of the first occurrence of `needle`. If `needle`
     *      is not found, `self` is set to the empty slice.
     * @param self The slice to search and modify.
     * @param needle The text to search for.
     * @return `self`.
     */
    function rfind(slice memory self, slice memory needle)
        internal
        pure
        returns (slice memory)
    {
        uint256 ptr = rfindPtr(self._len, self._ptr, needle._len, needle._ptr);
        self._len = ptr - self._ptr;
        return self;
    }

    /*
     * @dev Splits the slice, setting `self` to everything after the first
     *      occurrence of `needle`, and `token` to everything before it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and `token` is set to the entirety of `self`.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @param token An output parameter to which the first token is written.
     * @return `token`.
     */
    function split(
        slice memory self,
        slice memory needle,
        slice memory token
    ) internal pure returns (slice memory) {
        uint256 ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr);
        token._ptr = self._ptr;
        token._len = ptr - self._ptr;
        if (ptr == self._ptr + self._len) {
            // Not found
            self._len = 0;
        } else {
            self._len -= token._len + needle._len;
            self._ptr = ptr + needle._len;
        }
        return token;
    }

    /*
     * @dev Splits the slice, setting `self` to everything after the first
     *      occurrence of `needle`, and returning everything before it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and the entirety of `self` is returned.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @return The part of `self` up to the first occurrence of `delim`.
     */
    function split(slice memory self, slice memory needle)
        internal
        pure
        returns (slice memory token)
    {
        split(self, needle, token);
    }

    /*
     * @dev Splits the slice, setting `self` to everything before the last
     *      occurrence of `needle`, and `token` to everything after it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and `token` is set to the entirety of `self`.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @param token An output parameter to which the first token is written.
     * @return `token`.
     */
    function rsplit(
        slice memory self,
        slice memory needle,
        slice memory token
    ) internal pure returns (slice memory) {
        uint256 ptr = rfindPtr(self._len, self._ptr, needle._len, needle._ptr);
        token._ptr = ptr;
        token._len = self._len - (ptr - self._ptr);
        if (ptr == self._ptr) {
            // Not found
            self._len = 0;
        } else {
            self._len -= token._len + needle._len;
        }
        return token;
    }

    /*
     * @dev Splits the slice, setting `self` to everything before the last
     *      occurrence of `needle`, and returning everything after it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and the entirety of `self` is returned.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @return The part of `self` after the last occurrence of `delim`.
     */
    function rsplit(slice memory self, slice memory needle)
        internal
        pure
        returns (slice memory token)
    {
        rsplit(self, needle, token);
    }

    /*
     * @dev Counts the number of nonoverlapping occurrences of `needle` in `self`.
     * @param self The slice to search.
     * @param needle The text to search for in `self`.
     * @return The number of occurrences of `needle` found in `self`.
     */
    function count(slice memory self, slice memory needle)
        internal
        pure
        returns (uint256 cnt)
    {
        uint256 ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr) +
            needle._len;
        while (ptr <= self._ptr + self._len) {
            cnt++;
            ptr =
                findPtr(
                    self._len - (ptr - self._ptr),
                    ptr,
                    needle._len,
                    needle._ptr
                ) +
                needle._len;
        }
    }

    /*
     * @dev Returns True if `self` contains `needle`.
     * @param self The slice to search.
     * @param needle The text to search for in `self`.
     * @return True if `needle` is found in `self`, false otherwise.
     */
    function contains(slice memory self, slice memory needle)
        internal
        pure
        returns (bool)
    {
        return
            rfindPtr(self._len, self._ptr, needle._len, needle._ptr) !=
            self._ptr;
    }

    /*
     * @dev Returns a newly allocated string containing the concatenation of
     *      `self` and `other`.
     * @param self The first slice to concatenate.
     * @param other The second slice to concatenate.
     * @return The concatenation of the two strings.
     */
    function concat(slice memory self, slice memory other)
        internal
        pure
        returns (string memory)
    {
        string memory ret = new string(self._len + other._len);
        uint256 retptr;
        assembly {
            retptr := add(ret, 32)
        }
        memcpy(retptr, self._ptr, self._len);
        memcpy(retptr + self._len, other._ptr, other._len);
        return ret;
    }

    /*
     * @dev Joins an array of slices, using `self` as a delimiter, returning a
     *      newly allocated string.
     * @param self The delimiter to use.
     * @param parts A list of slices to join.
     * @return A newly allocated string containing all the slices in `parts`,
     *         joined with `self`.
     */
    function join(slice memory self, slice[] memory parts)
        internal
        pure
        returns (string memory)
    {
        if (parts.length == 0) return "";

        uint256 length = self._len * (parts.length - 1);
        for (uint256 i = 0; i < parts.length; i++) length += parts[i]._len;

        string memory ret = new string(length);
        uint256 retptr;
        assembly {
            retptr := add(ret, 32)
        }

        for (uint256 i = 0; i < parts.length; i++) {
            memcpy(retptr, parts[i]._ptr, parts[i]._len);
            retptr += parts[i]._len;
            if (i < parts.length - 1) {
                memcpy(retptr, self._ptr, self._len);
                retptr += self._len;
            }
        }

        return ret;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

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
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, IERC1822ProxiableUpgradeable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate that the this implementation remains valid after an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

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
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal onlyInitializing {
    }

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {
    }
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
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
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
            _functionDelegateCall(newImplementation, data);
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
        if (StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822ProxiableUpgradeable(newImplementation).proxiableUUID() returns (bytes32 slot) {
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
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
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
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
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
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822ProxiableUpgradeable {
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
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}