// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "./strings.sol";

abstract contract ReverseRegistrar {
  function node(address addr) public pure virtual returns (bytes32);
}

abstract contract ENS {
  function resolver(bytes32 node) public view virtual returns (address);
}

abstract contract Resolver {
  function name(bytes32 node) public view virtual returns (string memory);
}

contract EthBox is ERC165, IERC721, IERC721Metadata, Ownable {
    using Address for address;
    using Strings for uint256;
    using strings for *;

    ENS ens = ENS(0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e);

    ReverseRegistrar reverseRegistrar = ReverseRegistrar(0x084b1c3C81545d370f3634392De611CaaBFf8148);

    //ERC721 Variables
    string private _name;
    string private _symbol;
    mapping(address => bool) public minted;

    //Messaging Variable
    uint256 public constant defaultInboxSize = 3;
    uint256 public constant defaultDecayTime = 157784630; // 5 years in second
    uint8 public constant maxMessageLen = 141;
    uint256 public decayRoundOff;
    uint256 public sizeIncreaseFee;
    uint256 public sizeIncreaseFeeBPS;
    uint256 public messageFeeBPS;
    address public messageFeeRecipient;
    bool public airdropAllowed;
    struct Message {
        address from;
        uint256 timestamp;
        uint256 originalValue;
        string message;
    }
    
    // to allow for sender to unclaimed boxes to retrieve their eth if box is unminted
    struct MessageClaim {
        address from;
        uint256 timestamp;
        uint256 originalValue;
    }

    struct MessageInfo {
        address to;
        string visibility;
        Message message;
        uint256 index;
        uint256 maxSize;
    }

    mapping(address => Message[]) public inboxMessages;
    mapping(address => uint256) public inboxSizes;
    mapping(address => uint256) public inboxDecayTimes;
    mapping(address => address) public inboxPayoutRecipients;
    

    //Display and metadata variables
    string private desc;
    string private messageInsert;
    string private inboxInsert;

    constructor(){
        _name = "ETHBOX";
        _symbol = "ETHBOX";
        desc = "On-chain Ethereum messaging system backed by an ERC721 token assigned to all addresses to display your public inbox.";
        airdropAllowed = false;
        decayRoundOff = 1e9*1e9; // round off to gwei
        sizeIncreaseFee = 0.05 ether;
        sizeIncreaseFeeBPS = 2500;
        messageFeeBPS = 500;
        messageFeeRecipient = 0xfe07690c2bF326F0D22CaFde9F4DbC60D1b32501;
        messageInsert = 
        '<g id="message-${_INDEX}" style="display:${_VISIBILITY}" onclick="cycleMessage()"><foreignObject x="2.8%" y="y="2.5%"" width="97.1%" height="14.2%"><div class = "plain-text" xmlns="http://www.w3.org/1999/xhtml" style="color:white;font-family:monospace;font-size:0.9em">to: ${_TO}</div></foreignObject><foreignObject x="2.8%" y="5%" width="97.1%" height="14.2%"><div class = "plain-text" xmlns="http://www.w3.org/1999/xhtml" style="color:white;font-family:monospace;font-size:0.9em">from: ${_FROM} </div></foreignObject><foreignObject x="2.8%" y="10%" width="97.1%" height="90%"><div class = "plain-text" xmlns="http://www.w3.org/1999/xhtml" style="color:#4AF626;font-family:monospace;font-size:1.5em"> ${_MESSAGE} </div></foreignObject><foreignObject x="2.8%" y="85%" width="97.1%" height="90%"><div class = "plain-text" xmlns="http://www.w3.org/1999/xhtml" style="color:red;font-family:monospace;font-size:1.8em;text-align:left"> Bid: ${_VALUE} ETH </div></foreignObject><foreignObject x="82%" y="85%" width="97.1%" height="90%"><div class = "plain-text" xmlns="http://www.w3.org/1999/xhtml" style="color:red;font-family:monospace;font-size:1.5em;text-align:left">(${_POSITION})</div></foreignObject></g>';
        inboxInsert = 
        '<svg id= "wrapper" width="350px" height="350px" viewbox="0 0 100% 100%" xmlns="http://www.w3.org/2000/svg" xmlns:xlink= "http://www.w3.org/1999/xlink"><rect width="100%" height="100%" fill="black" /><text x="2.8%" y="95%" font-size="0.8em" fill="white" font-family="monospace"> Click or tap to cycle messages </text>${_MESSAGES}<script>var current_message = 0;var messages = document.querySelectorAll(\'[id^="message-"]\');document.getElementById("wrapper").setAttribute("width", "100%");document.getElementById("wrapper").setAttribute("height", "100%");function cycleMessage() {document.getElementById("message-" + current_message).style.display ="none";current_message = (current_message + 1) % messages.length;document.getElementById("message-" + current_message).style.display ="block";};</script></svg>';
    }

    ////////////////////////////////////////
    ////////////////////////////////////////
    // ERC721 functions //
    
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }
    function balanceOf(address _owner) public view override returns (uint256) {
        if (minted[_owner]) return 1;
        return 0;
    }

    function ownerOf(uint256 _tokenId) public view override returns (address) {
        address owner = address(uint160(_tokenId));
        require(minted[owner], "ERC721: invalid token ID");
        return owner;
    }

    function inboxOf(address _owner) public view returns (uint256) {
        require(minted[_owner], "Address has not minted");
        return uint256(uint160(_owner));
    }

    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(minted[address(uint160(_tokenId))]);
        return buildMetadata(_tokenId);
    }

    function getApproved(uint256 _tokenId) public view override returns(address) {
        require(minted[address(uint160(_tokenId))]);
        return address(0);
    }

    function isApprovedForAll(address, address) public pure override returns(bool) {
        return false;
    }

    function approve(address, uint256) public pure override {revert("disabled");}
    function setApprovalForAll(address, bool) public pure override{revert("disabled");}
    function transferFrom(address, address, uint256) public pure override {revert("disabled");}
    function safeTransferFrom(address, address, uint256) public pure override {revert("disabled");}
    function safeTransferFrom(address, address, uint256, bytes memory) public pure override {revert("disabled");}

    ////////////////////////////////////
    ////////////////////////////////////
    // Minting functions //

    function mintInboxFor(address _recipient) public {
        require(airdropAllowed);
        require(!minted[_recipient]);
        _mint(_recipient, uint256(uint160(msg.sender)));
        inboxSizes[_recipient] = defaultInboxSize;
    }

    function mintMyInbox() public {
        require(!minted[msg.sender]);
        _mint(msg.sender, uint256(uint160(msg.sender)));
        inboxSizes[msg.sender] = defaultInboxSize;
        inboxDecayTimes[msg.sender] = defaultDecayTime;
        inboxPayoutRecipients[msg.sender] = msg.sender;
        if (inboxMessages[msg.sender].length > 0){
            // pay for messages that have been in the inbox
            for (uint i = 0; i < inboxMessages[msg.sender].length; i++) {
                _payAll(msg.sender, inboxMessages[msg.sender][i].originalValue);
            }
        }
    }

    function flipAirdropAllowed() external onlyOwner {
        airdropAllowed = !airdropAllowed;
    }

    function _mint(address _to, uint256 _tokenId) internal {
        minted[_to] = true;
        emit Transfer(address(0), _to, _tokenId);
    }

    //////////////////////////////////////
    //////////////////////////////////////
    // Display and metadata functions //
    //todo : embed variables

    function setDesc(string memory _desc) external onlyOwner {
        desc = _desc;
    }

    function setMessageInsert(string memory _messageInsert) external onlyOwner {
        messageInsert = _messageInsert;
    }
    
    function setInboxInsert(string memory _inboxInsert) external onlyOwner {
        inboxInsert = _inboxInsert;
    }

    function valueToEthString(uint256 _value) public pure returns (string memory) {
        strings.slice memory eRep = Strings.toString(_value).toSlice();
        strings.slice memory zero = "0".toSlice();
        uint256 len = eRep.len();
        if (len > 18){ // more then 1eth, add a dot and remove trailing 0's
            uint256 roundEth = _value / 1 ether;
            strings.slice memory round = Strings.toString(roundEth).toSlice();
            eRep.split(round);
            while (eRep.endsWith(zero)){
                eRep.until(zero);
            }
            return string(abi.encodePacked(
                round.toString(),
                ".",
                eRep.toString()
            ));
        } else {
            uint256 diff = 18-len;
            strings.slice memory padding = "0.".toSlice();
            for (diff; diff != 0; diff--){
                padding = padding.concat(zero).toSlice();
            }
            while (eRep.endsWith(zero)){
                eRep.until(zero);
            }
            return string(abi.encodePacked(
                padding.toString(),
                eRep.toString()
            ));
        }
    }

    function addressToENS(address _address) public view returns (string memory) {
        bytes32 node = reverseRegistrar.node(_address);
        address resolverAddress = ens.resolver(node);

        // return 
        if (resolverAddress == address(0)) return Strings.toHexString(uint160(_address), 20);

        Resolver resolver = Resolver(resolverAddress);
        return resolver.name(node);
    }

    function buildInboxImage(address owner) public view returns (string memory) {
        Message[] memory messages = getOrderedMessages(owner);
        string memory svg = buildSVG(owner, messages, inboxSizes[owner]);
        return string(abi.encodePacked(
            "data:image/svg+xml;base64,",
            Base64.encode(bytes(svg))
        ));
    }
    function buildInboxHtml(address owner) public view returns (string memory) {
        Message[] memory messages = getOrderedMessages(owner);
        string memory svg = buildSVG(owner, messages, inboxSizes[owner]);
        return string(abi.encodePacked(
            "data:text/html;base64,",
            Base64.encode(bytes(string(abi.encodePacked("<html><body>",svg,"</body></html>"))))
        ));
    }

    function buildSingleMessageSVG(MessageInfo memory _display) private view returns (string memory) {
        strings.slice memory sliceMessage = messageInsert.toSlice();

        string memory output = string(abi.encodePacked(
            sliceMessage.split("${_INDEX}".toSlice()).toString(),
            Strings.toString(_display.index),
            sliceMessage.split("${_VISIBILITY}".toSlice()).toString(),
            _display.visibility,
            sliceMessage.split("${_TO}".toSlice()).toString(),
            Strings.toHexString(uint160(_display.to), 20),
            sliceMessage.split("${_FROM}".toSlice()).toString(),
            Strings.toHexString(uint160(_display.message.from), 20),
            sliceMessage.split("${_MESSAGE}".toSlice()).toString()
        ));

        output = string(abi.encodePacked(
            output,
            _display.message.message,
            sliceMessage.split("${_VALUE}".toSlice()).toString(),
            valueToEthString(_display.message.originalValue),
            sliceMessage.split("${_POSITION}".toSlice()).toString(),
            Strings.toString(_display.index+1),
            "/",
            Strings.toString(_display.maxSize),
            sliceMessage.toString()
        ));

        return output;
    }

    function buildSVG(address _to, Message[] memory _messages, uint256 _maxSize) private view returns (string memory) {
        strings.slice memory sliceInbox = inboxInsert.toSlice();
        string memory output = sliceInbox.split("${_MESSAGES}".toSlice()).toString();
        string memory visibility = "visible";
        for (uint i = 0; i < _messages.length; i++) {
            if (i == 1) {
                visibility = "none";
            }
            MessageInfo memory display = MessageInfo(_to, visibility, _messages[i], i, _maxSize);
            output = string(abi.encodePacked(
                output,
                buildSingleMessageSVG(display)
            ));
        }
        return string(abi.encodePacked(
            output,
            sliceInbox.toString()
        ));
    }

    function buildMetadata(uint256 _tokenId)
        private
        view
        returns (string memory)
    {
        address owner = address(uint160(_tokenId));
        Message[] memory messages = getOrderedMessages(owner);

        string memory output = string(abi.encodePacked(
            '{"name":"Ethbox of ',
            Strings.toHexString(uint160(owner), 20),
            '", "description":"',
            desc,
            '", "attributes": '
        ));

        string memory attributes = string(abi.encodePacked(
            '[{ "trait_type": "Max Capacity", "value": ',
            Strings.toString(inboxSizes[owner]),
            '},{ "trait_type": "Message Count", "value": ',
            Strings.toString(inboxMessages[owner].length),
            '}]'
        )); 

        output = string(abi.encodePacked(
            output,
            attributes,
            ', "image": "'
        ));
        string memory svg = buildSVG(owner, messages, inboxSizes[owner]);
        output = string(abi.encodePacked(
            output,
            "data:image/svg+xml;base64,",
            Base64.encode(bytes(svg)),
            '", "animation_url": "data:text/html;base64,',
            Base64.encode(bytes(string(abi.encodePacked("<html><body>",svg,"</body></html>")))),
            '"}'
        ));
        return string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            output
                        )
                    )
                )
            );
    }

    //////////////////////////////////////
    //////////////////////////////////////
    // Messaging Functions //
    // todo : dig more into string vs bytes32 and limitations of each
    // todo : add unminted messaging and overbidding on existing messages
    // todo : add inbox size change
    // todo : gas opt

    function setSizeIncreaseFee(uint256 _sizeIncreaseFee) external onlyOwner {
        sizeIncreaseFee = _sizeIncreaseFee;
    }

    function setSizeIncreaseFeeBPS(uint256 _sizeIncreaseFeeBPS) external onlyOwner {
        sizeIncreaseFeeBPS = _sizeIncreaseFeeBPS;
    }

    function setMessageFeeBPS(uint256 _messageFeeBPS) external onlyOwner {
        messageFeeBPS = _messageFeeBPS;
    }

    function setMessageFeeRecipient(address _messageFeeRecipient) external onlyOwner {
        messageFeeRecipient = _messageFeeRecipient;
    }


    function getCurrentBoxFill(address _to) public view returns(uint256 fill) {
        return inboxMessages[_to].length;
    }

    function getDecayedValue(uint256 _decayTime, uint256 _value, uint256 _timestamp) public view returns(uint256 _decayedValue) {
        uint256 elapsedSeconds = block.timestamp - _timestamp;
        if (elapsedSeconds == 0) return _value;
        uint256 percent = _decayTime / elapsedSeconds;
        uint256 subValue = _value / percent;
        return ((_value-subValue)/decayRoundOff);
    }

    //TODO : modify the flow of conditional statements to not be so redundant.
    function sendMessage(address _to, string calldata _message) public payable{
        require(bytes(_message).length < maxMessageLen);
        require(msg.value > 10000 || msg.value == 0);
        Message[] memory toMessages = inboxMessages[_to];
        uint256 dynamicBoxSize = toMessages.length;
        if (minted[_to]){
            if (dynamicBoxSize < inboxSizes[_to]) {
                _pushMessage(_to, msg.sender, _message, msg.value);
                _payAll(_to, msg.value);
            } else {
                (bool qualifies, uint256 indexToRemove) = _getIndexToReplace(toMessages, dynamicBoxSize, msg.value, inboxDecayTimes[_to]);
                if (qualifies){
                    _insertMessage(_to, msg.sender, _message, msg.value, indexToRemove);
                    _payAll(_to, msg.value);
                }
            }
        } else { // not minted inbox, hold payment
            if (dynamicBoxSize < defaultInboxSize) {
                _pushMessage(_to, msg.sender, _message, msg.value);
            } else {
                (bool qualifies, uint256 indexToRemove) = _getIndexToReplace(toMessages, dynamicBoxSize, msg.value, defaultDecayTime);
                if (qualifies) {
                    Message memory droppedMessage = toMessages[indexToRemove];
                    _refundSender(droppedMessage.from, droppedMessage.originalValue);
                    _insertMessage(_to, msg.sender, _message, msg.value, indexToRemove);
                }

            }
        }
    }

    function _getIndexToReplace(Message[] memory _toMessages, uint256 _boxSize, uint256 _value, uint256 _decayTime) private view returns (bool qualifies, uint256 indexToRemove) {
        uint256 lowIndex;
        uint256 lowValue = getDecayedValue(_decayTime,_toMessages[0].originalValue, _toMessages[0].timestamp);
        uint256 decayedValue;
        for (uint256 i=0; i< _boxSize; i++) {
            decayedValue = getDecayedValue(_decayTime, _toMessages[i].originalValue, _toMessages[i].timestamp);
            if (decayedValue < lowValue) {
                lowIndex = i;
                lowValue = decayedValue;
            }
            if ( qualifies == false && _value > decayedValue) {
                qualifies = true;
            }
        }
        return (qualifies, lowIndex);
    }

    function _pushMessage(address _to, address _from, string calldata _message, uint256 _value) private {
        inboxMessages[_to].push(Message(
            _from,
            block.timestamp,
            _value,
            _message
        ));
    }

    function _insertMessage(address _to, address _from, string calldata _message, uint256 _value, uint256 _index) private {
        inboxMessages[_to][_index] = Message(
            _from,
            block.timestamp,
            _value,
            _message
        );
    }

    function _removeMessage(address _to, uint256 _index) private {
        inboxMessages[_to][_index] = inboxMessages[_to][inboxMessages[_to].length - 1];
        inboxMessages[_to].pop();
    }


    function _payAll(address _to, uint256 _value) private {
        _payFees(_value);
        _payRecipient(_to, _value);
    }

    function _payFees(uint256 _value) private {
        (bool successFees, ) = messageFeeRecipient.call{value: (_value * messageFeeBPS) / 10000}("");
        require(successFees);
    }

    function _payRecipient(address _to, uint256 _value) private {
        (bool successRecipient, )= inboxPayoutRecipients[_to].call{value: (_value * (10000 - messageFeeBPS)) / 10000}("");
        require(successRecipient);
    }

    function _refundSender(address _from, uint256 _value) private {
        (bool successRefund, )= _from.call{value: _value }("");
        require(successRefund);
    }

    function getOrderedMessages(address _to) public view returns (Message[] memory) {
        Message[] memory messages = inboxMessages[_to];
        for (uint i = 1; i< messages.length; i++) {
            for (uint j = 0; j < i; j++) {
                if (messages[i].originalValue > messages[j].originalValue) {
                    Message memory x = messages[i];
                    messages[i] = messages[j];
                    messages[j] = x;
                }
            }
        }
        return messages;
    }

    function getRefundForMessage(address _to ,string calldata _message, uint256 _value) external {
        require(!minted[_to], "inbox has been minted, refunds not available");
        for (uint i = 0; i < inboxMessages[_to].length; i++) {
            strings.slice memory iMessage = inboxMessages[_to][i].message.toSlice();
            if (
                inboxMessages[_to][i].from == msg.sender && 
                iMessage.equals(_message.toSlice()) && 
                inboxMessages[_to][i].originalValue == _value
                ){
                    _removeMessage(_to, i);
                    _refundSender(msg.sender, _value);
                }
        }
    }

    function boostMessageValue(address _to, address _from, string calldata _message) external payable {
        require(minted[_to], "inbox needs to be minted");
        for (uint i = 0; i< inboxMessages[_to].length; i++) {
            strings.slice memory iMessage = inboxMessages[_to][i].message.toSlice();
            if (
                inboxMessages[_to][i].from == _from && 
                iMessage.equals(_message.toSlice())
                ){
                    inboxMessages[_to][i].originalValue += msg.value;
                }
        }
    }

    function changeInboxPayoutRecipient(address _recipient) external {
        require(minted[msg.sender], "inbox needs to be minted");
        inboxPayoutRecipients[msg.sender] = _recipient;
    }

    // TODO : should decay times have limits ?    
    function changeInboxDecayTime(uint256 _decayTime) external {
        require(minted[msg.sender], "inbox needs to be minted");
        inboxDecayTimes[msg.sender] = _decayTime;
    }

    function expandInboxSize(uint256 _size) external payable {
        require(minted[msg.sender], "inbox needs to be minted");
        uint256 currentSize = inboxSizes[msg.sender];
        require(_size > currentSize, "new size should be larger");
        uint256 total = 0;
        for (uint256 i = currentSize; i < _size; i++) {
            if (i == defaultInboxSize) {
                total += sizeIncreaseFee;
            } else {
                total += sizeIncreaseFee * ((sizeIncreaseFeeBPS+10000)**(i-defaultInboxSize)) / (10000**(i-defaultInboxSize));
            }
        }
        require(total == msg.value, total.toString());
        inboxSizes[msg.sender] = _size;
    }
}

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
        uint _len;
        uint _ptr;
    }

    function memcpy(uint dest, uint src, uint len) private pure {
        // Copy word-length chunks while possible
        for(; len >= 32; len -= 32) {
            assembly {
                mstore(dest, mload(src))
            }
            dest += 32;
            src += 32;
        }

        // Copy remaining bytes
        uint mask = type(uint).max;
        if (len > 0) {
            mask = 256 ** (32 - len) - 1;
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
        uint ptr;
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
    function len(bytes32 self) internal pure returns (uint) {
        uint ret;
        if (self == 0)
            return 0;
        if (uint(self) & type(uint128).max == 0) {
            ret += 16;
            self = bytes32(uint(self) / 0x100000000000000000000000000000000);
        }
        if (uint(self) & type(uint64).max == 0) {
            ret += 8;
            self = bytes32(uint(self) / 0x10000000000000000);
        }
        if (uint(self) & type(uint32).max == 0) {
            ret += 4;
            self = bytes32(uint(self) / 0x100000000);
        }
        if (uint(self) & type(uint16).max == 0) {
            ret += 2;
            self = bytes32(uint(self) / 0x10000);
        }
        if (uint(self) & type(uint8).max == 0) {
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
        uint retptr;
        assembly { retptr := add(ret, 32) }

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
    function len(slice memory self) internal pure returns (uint l) {
        // Starting at ptr-31 means the LSB will be the byte we care about
        uint ptr = self._ptr - 31;
        uint end = ptr + self._len;
        for (l = 0; ptr < end; l++) {
            uint8 b;
            assembly { b := and(mload(ptr), 0xFF) }
            if (b < 0x80) {
                ptr += 1;
            } else if(b < 0xE0) {
                ptr += 2;
            } else if(b < 0xF0) {
                ptr += 3;
            } else if(b < 0xF8) {
                ptr += 4;
            } else if(b < 0xFC) {
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
    function compare(slice memory self, slice memory other) internal pure returns (int) {
        uint shortest = self._len;
        if (other._len < self._len)
            shortest = other._len;

        uint selfptr = self._ptr;
        uint otherptr = other._ptr;
        for (uint idx = 0; idx < shortest; idx += 32) {
            uint a;
            uint b;
            assembly {
                a := mload(selfptr)
                b := mload(otherptr)
            }
            if (a != b) {
                // Mask out irrelevant bytes and check again
                uint mask = type(uint).max; // 0xffff...
                if(shortest < 32) {
                  mask = ~(2 ** (8 * (32 - shortest + idx)) - 1);
                }
                unchecked {
                    uint diff = (a & mask) - (b & mask);
                    if (diff != 0)
                        return int(diff);
                }
            }
            selfptr += 32;
            otherptr += 32;
        }
        return int(self._len) - int(other._len);
    }

    /*
     * @dev Returns true if the two slices contain the same text.
     * @param self The first slice to compare.
     * @param self The second slice to compare.
     * @return True if the slices are equal, false otherwise.
     */
    function equals(slice memory self, slice memory other) internal pure returns (bool) {
        return compare(self, other) == 0;
    }

    /*
     * @dev Extracts the first rune in the slice into `rune`, advancing the
     *      slice to point to the next rune and returning `self`.
     * @param self The slice to operate on.
     * @param rune The slice that will contain the first rune.
     * @return `rune`.
     */
    function nextRune(slice memory self, slice memory rune) internal pure returns (slice memory) {
        rune._ptr = self._ptr;

        if (self._len == 0) {
            rune._len = 0;
            return rune;
        }

        uint l;
        uint b;
        // Load the first byte of the rune into the LSBs of b
        assembly { b := and(mload(sub(mload(add(self, 32)), 31)), 0xFF) }
        if (b < 0x80) {
            l = 1;
        } else if(b < 0xE0) {
            l = 2;
        } else if(b < 0xF0) {
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
    function nextRune(slice memory self) internal pure returns (slice memory ret) {
        nextRune(self, ret);
    }

    /*
     * @dev Returns the number of the first codepoint in the slice.
     * @param self The slice to operate on.
     * @return The number of the first codepoint in the slice.
     */
    function ord(slice memory self) internal pure returns (uint ret) {
        if (self._len == 0) {
            return 0;
        }

        uint word;
        uint length;
        uint divisor = 2 ** 248;

        // Load the rune into the MSBs of b
        assembly { word:= mload(mload(add(self, 32))) }
        uint b = word / divisor;
        if (b < 0x80) {
            ret = b;
            length = 1;
        } else if(b < 0xE0) {
            ret = b & 0x1F;
            length = 2;
        } else if(b < 0xF0) {
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

        for (uint i = 1; i < length; i++) {
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
    function startsWith(slice memory self, slice memory needle) internal pure returns (bool) {
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
            equal := eq(keccak256(selfptr, length), keccak256(needleptr, length))
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
    function beyond(slice memory self, slice memory needle) internal pure returns (slice memory) {
        if (self._len < needle._len) {
            return self;
        }

        bool equal = true;
        if (self._ptr != needle._ptr) {
            assembly {
                let length := mload(needle)
                let selfptr := mload(add(self, 0x20))
                let needleptr := mload(add(needle, 0x20))
                equal := eq(keccak256(selfptr, length), keccak256(needleptr, length))
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
    function endsWith(slice memory self, slice memory needle) internal pure returns (bool) {
        if (self._len < needle._len) {
            return false;
        }

        uint selfptr = self._ptr + self._len - needle._len;

        if (selfptr == needle._ptr) {
            return true;
        }

        bool equal;
        assembly {
            let length := mload(needle)
            let needleptr := mload(add(needle, 0x20))
            equal := eq(keccak256(selfptr, length), keccak256(needleptr, length))
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
    function until(slice memory self, slice memory needle) internal pure returns (slice memory) {
        if (self._len < needle._len) {
            return self;
        }

        uint selfptr = self._ptr + self._len - needle._len;
        bool equal = true;
        if (selfptr != needle._ptr) {
            assembly {
                let length := mload(needle)
                let needleptr := mload(add(needle, 0x20))
                equal := eq(keccak256(selfptr, length), keccak256(needleptr, length))
            }
        }

        if (equal) {
            self._len -= needle._len;
        }

        return self;
    }

    // Returns the memory address of the first byte of the first occurrence of
    // `needle` in `self`, or the first byte after `self` if not found.
    function findPtr(uint selflen, uint selfptr, uint needlelen, uint needleptr) private pure returns (uint) {
        uint ptr = selfptr;
        uint idx;

        if (needlelen <= selflen) {
            if (needlelen <= 32) {
                bytes32 mask;
                if (needlelen > 0) {
                    mask = bytes32(~(2 ** (8 * (32 - needlelen)) - 1));
                }

                bytes32 needledata;
                assembly { needledata := and(mload(needleptr), mask) }

                uint end = selfptr + selflen - needlelen;
                bytes32 ptrdata;
                assembly { ptrdata := and(mload(ptr), mask) }

                while (ptrdata != needledata) {
                    if (ptr >= end)
                        return selfptr + selflen;
                    ptr++;
                    assembly { ptrdata := and(mload(ptr), mask) }
                }
                return ptr;
            } else {
                // For long needles, use hashing
                bytes32 hash;
                assembly { hash := keccak256(needleptr, needlelen) }

                for (idx = 0; idx <= selflen - needlelen; idx++) {
                    bytes32 testHash;
                    assembly { testHash := keccak256(ptr, needlelen) }
                    if (hash == testHash)
                        return ptr;
                    ptr += 1;
                }
            }
        }
        return selfptr + selflen;
    }

    // Returns the memory address of the first byte after the last occurrence of
    // `needle` in `self`, or the address of `self` if not found.
    function rfindPtr(uint selflen, uint selfptr, uint needlelen, uint needleptr) private pure returns (uint) {
        uint ptr;

        if (needlelen <= selflen) {
            if (needlelen <= 32) {
                bytes32 mask;
                if (needlelen > 0) {
                    mask = bytes32(~(2 ** (8 * (32 - needlelen)) - 1));
                }

                bytes32 needledata;
                assembly { needledata := and(mload(needleptr), mask) }

                ptr = selfptr + selflen - needlelen;
                bytes32 ptrdata;
                assembly { ptrdata := and(mload(ptr), mask) }

                while (ptrdata != needledata) {
                    if (ptr <= selfptr)
                        return selfptr;
                    ptr--;
                    assembly { ptrdata := and(mload(ptr), mask) }
                }
                return ptr + needlelen;
            } else {
                // For long needles, use hashing
                bytes32 hash;
                assembly { hash := keccak256(needleptr, needlelen) }
                ptr = selfptr + (selflen - needlelen);
                while (ptr >= selfptr) {
                    bytes32 testHash;
                    assembly { testHash := keccak256(ptr, needlelen) }
                    if (hash == testHash)
                        return ptr + needlelen;
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
    function find(slice memory self, slice memory needle) internal pure returns (slice memory) {
        uint ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr);
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
    function rfind(slice memory self, slice memory needle) internal pure returns (slice memory) {
        uint ptr = rfindPtr(self._len, self._ptr, needle._len, needle._ptr);
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
    function split(slice memory self, slice memory needle, slice memory token) internal pure returns (slice memory) {
        uint ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr);
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
    function split(slice memory self, slice memory needle) internal pure returns (slice memory token) {
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
    function rsplit(slice memory self, slice memory needle, slice memory token) internal pure returns (slice memory) {
        uint ptr = rfindPtr(self._len, self._ptr, needle._len, needle._ptr);
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
    function rsplit(slice memory self, slice memory needle) internal pure returns (slice memory token) {
        rsplit(self, needle, token);
    }

    /*
     * @dev Counts the number of nonoverlapping occurrences of `needle` in `self`.
     * @param self The slice to search.
     * @param needle The text to search for in `self`.
     * @return The number of occurrences of `needle` found in `self`.
     */
    function count(slice memory self, slice memory needle) internal pure returns (uint cnt) {
        uint ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr) + needle._len;
        while (ptr <= self._ptr + self._len) {
            cnt++;
            ptr = findPtr(self._len - (ptr - self._ptr), ptr, needle._len, needle._ptr) + needle._len;
        }
    }

    /*
     * @dev Returns True if `self` contains `needle`.
     * @param self The slice to search.
     * @param needle The text to search for in `self`.
     * @return True if `needle` is found in `self`, false otherwise.
     */
    function contains(slice memory self, slice memory needle) internal pure returns (bool) {
        return rfindPtr(self._len, self._ptr, needle._len, needle._ptr) != self._ptr;
    }

    /*
     * @dev Returns a newly allocated string containing the concatenation of
     *      `self` and `other`.
     * @param self The first slice to concatenate.
     * @param other The second slice to concatenate.
     * @return The concatenation of the two strings.
     */
    function concat(slice memory self, slice memory other) internal pure returns (string memory) {
        string memory ret = new string(self._len + other._len);
        uint retptr;
        assembly { retptr := add(ret, 32) }
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
    function join(slice memory self, slice[] memory parts) internal pure returns (string memory) {
        if (parts.length == 0)
            return "";

        uint length = self._len * (parts.length - 1);
        for(uint i = 0; i < parts.length; i++)
            length += parts[i]._len;

        string memory ret = new string(length);
        uint retptr;
        assembly { retptr := add(ret, 32) }

        for(uint i = 0; i < parts.length; i++) {
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