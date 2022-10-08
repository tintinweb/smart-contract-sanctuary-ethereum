// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;
import '@openzeppelin/contracts/access/Ownable.sol';
import './MetadataGenerator.sol';

contract DeathClockDesciptor is Ownable, MetadataGenerator {
    struct TokenParams {
        uint8 cid;
        uint8 tid;
        uint8 bid;
    }

    struct MetadataPayload {
        uint256 id;
        uint256 minted;
        uint256 expDate;
        uint256 remnants;
        uint256 resets;
        address acct;
    }

    string private WEBAPP_URL = '';
    mapping(uint8 => bytes32) private colorNames;
    mapping(uint8 => bytes32) private imageNames;

    mapping(uint256 => TokenParams) private tokenParamsById;
    mapping(uint256 => string) public previewUrls;

    constructor(string memory _WEBAPP_URL) {
        WEBAPP_URL = _WEBAPP_URL;
    }

    function setWebAppUrl(string memory _WEBAPP_URL) external onlyOwner {
        WEBAPP_URL = _WEBAPP_URL;
    }

    function setColorNames(bytes32[] memory _colorNames) external onlyOwner {
        for (uint8 i = 0; i < _colorNames.length; i++) {
            colorNames[i] = _colorNames[i];
        }
    }

    function setImageNames(bytes32[] memory _imageNames) external onlyOwner {
        for (uint8 i = 0; i < _imageNames.length; i++) {
            imageNames[i] = _imageNames[i];
        }
    }

    function setPreviewUrls(string[] memory _previewUrls, uint256 startWith)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < _previewUrls.length; i++) {
            previewUrls[startWith + i] = _previewUrls[i];
        }
    }

    function setTokenParams(
        TokenParams[] memory _tokenParams,
        uint256 startWith
    ) external onlyOwner {
        for (uint256 i = 0; i < _tokenParams.length; i++) {
            tokenParamsById[startWith + i] = _tokenParams[i];
        }
    }

    function generateMetadataJSON(MetadataPayload calldata metadataPayload)
        external
        view
        returns (string memory)
    {
        uint256 tokenId = metadataPayload.id;
        address acct = metadataPayload.acct;
        TokenParams storage _tp = tokenParamsById[tokenId];
        uint256 previewId = tokenId;
        if (previewId > 500) {
            previewId = 500;
        }
        return
            generateMetadataJSON(
                MetadataGenerator.metadataPayload(
                    tokenId,
                    metadataPayload.minted,
                    metadataPayload.expDate,
                    _tp.cid,
                    _tp.tid,
                    _tp.bid,
                    imageNames[_tp.tid],
                    imageNames[_tp.bid],
                    metadataPayload.remnants,
                    metadataPayload.resets,
                    previewUrls[previewId],
                    WEBAPP_URL,
                    acct
                )
            );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import './JsonWriter.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/utils/Base64.sol';

contract MetadataGenerator {
    using JsonWriter for JsonWriter.Json;
    struct metadataPayload {
        uint256 id;
        uint256 minted;
        uint256 expDate;
        uint8 cid;
        uint8 tid;
        uint8 bid;
        bytes32 topImage;
        bytes32 bottomImage;
        uint256 remnants;
        uint256 resets;
        string imageUrl;
        string webAppUrl;
        address acct;
    }

    struct attrPayload {
        uint8 cid;
        string topImage;
        string bottomImage;
        uint256 remnants;
        uint256 resets;
        uint256 expDate;
        address acct;
    }

    function generateMetadataJSON(metadataPayload memory payload)
        internal
        pure
        returns (string memory)
    {
        JsonWriter.Json memory writer;
        writer = writer.writeStartObject();
        string memory idStr = Strings.toString(payload.id);
        writer = writer.writeStringProperty(
            'name',
            string.concat('DeathClock # ', idStr) //
        );
        writer = writer.writeStringProperty(
            'description',
            'Token description '
        );
        writer = writer.writeStringProperty('external_url', payload.webAppUrl);
        writer = writer.writeStringProperty(
            'image',
            string.concat('ipfs://', payload.imageUrl)
        );
        string memory cidStr = Strings.toString(payload.cid);
        string memory tidStr = Strings.toString(payload.tid);
        string memory bidStr = Strings.toString(payload.bid);
        string memory mintedStr = Strings.toString(payload.minted);
        string memory expDateStr = Strings.toString(payload.expDate);
        string memory params;
        if (bytes(cidStr).length > 0) {
            params = string.concat(
                '?cid=',
                cidStr,
                '&tid=',
                tidStr,
                '&bid=',
                bidStr,
                '&minted=',
                mintedStr,
                '&expDate=',
                expDateStr,
                '&acct=',
                string(abi.encodePacked(payload.acct))
            );
        } else {
            params = string.concat(
                '?tid=',
                tidStr,
                '&bid=',
                bidStr,
                '&minted=',
                mintedStr,
                '&expDate=',
                expDateStr,
                '&acct=',
                string(abi.encodePacked(payload.acct))
            );
        }

        writer = writer.writeStringProperty(
            'animation_url',
            string.concat(payload.webAppUrl, params)
        );

        writer = _generateAttributes(
            writer,
            attrPayload(
                payload.cid,
                string(abi.encodePacked(payload.topImage, '.jpg')),
                string(abi.encodePacked(payload.bottomImage, '.jpg')),
                payload.remnants,
                payload.resets,
                payload.expDate,
                payload.acct
            )
        );
        writer = writer.writeEndObject();
        return
            string(
                abi.encodePacked(
                    'data:application/json;base64,',
                    Base64.encode(abi.encodePacked(writer.value))
                )
            );
    }

    function _addStringAttribute(
        JsonWriter.Json memory _writer,
        string memory key,
        string memory value
    ) internal pure returns (JsonWriter.Json memory writer) {
        writer = _writer.writeStartObject();
        writer = writer.writeStringProperty('trait_type', key);
        writer = writer.writeStringProperty('value', value);
        writer = writer.writeEndObject();
    }

    function _addNumberAttribute(
        JsonWriter.Json memory _writer,
        string memory key,
        uint256 value
    ) internal pure returns (JsonWriter.Json memory writer) {
        writer = _writer.writeStartObject();
        writer = writer.writeStringProperty('trait_type', key);
        writer = writer.writeStringProperty('display_type', 'number');
        writer = writer.writeUintProperty('value', value);
        writer = writer.writeEndObject();
    }

    function _addDateAttribute(
        JsonWriter.Json memory _writer,
        string memory key,
        uint256 value
    ) internal pure returns (JsonWriter.Json memory writer) {
        writer = _writer.writeStartObject();
        writer = writer.writeStringProperty('trait_type', key);
        writer = writer.writeStringProperty('display_type', 'date');
        writer = writer.writeUintProperty('value', value);
        writer = writer.writeEndObject();
    }

    function _generateAttributes(
        JsonWriter.Json memory _writer,
        attrPayload memory payload
    ) internal pure returns (JsonWriter.Json memory writer) {
        writer = _writer.writeStartArray('attributes');
        _addDateAttribute(writer, 'Time of Death', payload.expDate);
        _addNumberAttribute(writer, 'Colorway', payload.cid);
        _addNumberAttribute(writer, 'Remnants', payload.remnants);
        _addNumberAttribute(writer, 'Resets', payload.resets);
        _addStringAttribute(writer, 'Image Top', payload.topImage);
        _addStringAttribute(writer, 'Image Botom', payload.bottomImage);
        _addStringAttribute(
            writer,
            'Future Departed',
            string(abi.encodePacked(payload.acct))
        );

        writer = writer.writeEndArray();
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

//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

library JsonWriter {
    using JsonWriter for string;

    struct Json {
        int256 depthBitTracker;
        string value;
    }

    bytes1 constant BACKSLASH = bytes1(uint8(92));
    bytes1 constant BACKSPACE = bytes1(uint8(8));
    bytes1 constant CARRIAGE_RETURN = bytes1(uint8(13));
    bytes1 constant DOUBLE_QUOTE = bytes1(uint8(34));
    bytes1 constant FORM_FEED = bytes1(uint8(12));
    bytes1 constant FRONTSLASH = bytes1(uint8(47));
    bytes1 constant HORIZONTAL_TAB = bytes1(uint8(9));
    bytes1 constant NEWLINE = bytes1(uint8(10));

    string constant TRUE = 'true';
    string constant FALSE = 'false';
    bytes1 constant OPEN_BRACE = '{';
    bytes1 constant CLOSED_BRACE = '}';
    bytes1 constant OPEN_BRACKET = '[';
    bytes1 constant CLOSED_BRACKET = ']';
    bytes1 constant LIST_SEPARATOR = ',';

    int256 constant MAX_INT256 = type(int256).max;

    /**
     * @dev Writes the beginning of a JSON array.
     */
    function writeStartArray(Json memory json)
        internal
        pure
        returns (Json memory)
    {
        return writeStart(json, OPEN_BRACKET);
    }

    /**
     * @dev Writes the beginning of a JSON array with a property name as the key.
     */
    function writeStartArray(Json memory json, string memory propertyName)
        internal
        pure
        returns (Json memory)
    {
        return writeStart(json, propertyName, OPEN_BRACKET);
    }

    /**
     * @dev Writes the beginning of a JSON object.
     */
    function writeStartObject(Json memory json)
        internal
        pure
        returns (Json memory)
    {
        return writeStart(json, OPEN_BRACE);
    }

    /**
     * @dev Writes the beginning of a JSON object with a property name as the key.
     */
    function writeStartObject(Json memory json, string memory propertyName)
        internal
        pure
        returns (Json memory)
    {
        return writeStart(json, propertyName, OPEN_BRACE);
    }

    /**
     * @dev Writes the end of a JSON array.
     */
    function writeEndArray(Json memory json)
        internal
        pure
        returns (Json memory)
    {
        return writeEnd(json, CLOSED_BRACKET);
    }

    /**
     * @dev Writes the end of a JSON object.
     */
    function writeEndObject(Json memory json)
        internal
        pure
        returns (Json memory)
    {
        return writeEnd(json, CLOSED_BRACE);
    }

    /**
     * @dev Writes the property name and address value (as a JSON string) as part of a name/value pair of a JSON object.
     */
    function writeAddressProperty(
        Json memory json,
        string memory propertyName,
        address value
    ) internal pure returns (Json memory) {
        if (json.depthBitTracker < 0) {
            json.value = string(
                abi.encodePacked(
                    json.value,
                    LIST_SEPARATOR,
                    '"',
                    propertyName,
                    '": "',
                    addressToString(value),
                    '"'
                )
            );
        } else {
            json.value = string(
                abi.encodePacked(
                    json.value,
                    '"',
                    propertyName,
                    '": "',
                    addressToString(value),
                    '"'
                )
            );
        }

        json.depthBitTracker = setListSeparatorFlag(json);

        return json;
    }

    /**
     * @dev Writes the address value (as a JSON string) as an element of a JSON array.
     */
    function writeAddressValue(Json memory json, address value)
        internal
        pure
        returns (Json memory)
    {
        if (json.depthBitTracker < 0) {
            json.value = string(
                abi.encodePacked(
                    json.value,
                    LIST_SEPARATOR,
                    '"',
                    addressToString(value),
                    '"'
                )
            );
        } else {
            json.value = string(
                abi.encodePacked(json.value, '"', addressToString(value), '"')
            );
        }

        json.depthBitTracker = setListSeparatorFlag(json);

        return json;
    }

    /**
     * @dev Writes the property name and boolean value (as a JSON literal "true" or "false") as part of a name/value pair of a JSON object.
     */
    function writeBooleanProperty(
        Json memory json,
        string memory propertyName,
        bool value
    ) internal pure returns (Json memory) {
        string memory strValue;
        if (value) {
            strValue = TRUE;
        } else {
            strValue = FALSE;
        }

        if (json.depthBitTracker < 0) {
            json.value = string(
                abi.encodePacked(
                    json.value,
                    LIST_SEPARATOR,
                    '"',
                    propertyName,
                    '": ',
                    strValue
                )
            );
        } else {
            json.value = string(
                abi.encodePacked(json.value, '"', propertyName, '": ', strValue)
            );
        }

        json.depthBitTracker = setListSeparatorFlag(json);

        return json;
    }

    /**
     * @dev Writes the boolean value (as a JSON literal "true" or "false") as an element of a JSON array.
     */
    function writeBooleanValue(Json memory json, bool value)
        internal
        pure
        returns (Json memory)
    {
        string memory strValue;
        if (value) {
            strValue = TRUE;
        } else {
            strValue = FALSE;
        }

        if (json.depthBitTracker < 0) {
            json.value = string(
                abi.encodePacked(json.value, LIST_SEPARATOR, strValue)
            );
        } else {
            json.value = string(abi.encodePacked(json.value, strValue));
        }

        json.depthBitTracker = setListSeparatorFlag(json);

        return json;
    }

    /**
     * @dev Writes the property name and int value (as a JSON number) as part of a name/value pair of a JSON object.
     */
    function writeIntProperty(
        Json memory json,
        string memory propertyName,
        int256 value
    ) internal pure returns (Json memory) {
        if (json.depthBitTracker < 0) {
            json.value = string(
                abi.encodePacked(
                    json.value,
                    LIST_SEPARATOR,
                    '"',
                    propertyName,
                    '": ',
                    intToString(value)
                )
            );
        } else {
            json.value = string(
                abi.encodePacked(
                    json.value,
                    '"',
                    propertyName,
                    '": ',
                    intToString(value)
                )
            );
        }

        json.depthBitTracker = setListSeparatorFlag(json);

        return json;
    }

    /**
     * @dev Writes the int value (as a JSON number) as an element of a JSON array.
     */
    function writeIntValue(Json memory json, int256 value)
        internal
        pure
        returns (Json memory)
    {
        if (json.depthBitTracker < 0) {
            json.value = string(
                abi.encodePacked(json.value, LIST_SEPARATOR, intToString(value))
            );
        } else {
            json.value = string(
                abi.encodePacked(json.value, intToString(value))
            );
        }

        json.depthBitTracker = setListSeparatorFlag(json);

        return json;
    }

    /**
     * @dev Writes the property name and value of null as part of a name/value pair of a JSON object.
     */
    function writeNullProperty(Json memory json, string memory propertyName)
        internal
        pure
        returns (Json memory)
    {
        if (json.depthBitTracker < 0) {
            json.value = string(
                abi.encodePacked(
                    json.value,
                    LIST_SEPARATOR,
                    '"',
                    propertyName,
                    '": null'
                )
            );
        } else {
            json.value = string(
                abi.encodePacked(json.value, '"', propertyName, '": null')
            );
        }

        json.depthBitTracker = setListSeparatorFlag(json);

        return json;
    }

    /**
     * @dev Writes the value of null as an element of a JSON array.
     */
    function writeNullValue(Json memory json)
        internal
        pure
        returns (Json memory)
    {
        if (json.depthBitTracker < 0) {
            json.value = string(
                abi.encodePacked(json.value, LIST_SEPARATOR, 'null')
            );
        } else {
            json.value = string(abi.encodePacked(json.value, 'null'));
        }

        json.depthBitTracker = setListSeparatorFlag(json);

        return json;
    }

    /**
     * @dev Writes the string text value (as a JSON string) as an element of a JSON array.
     */
    function writeStringProperty(
        Json memory json,
        string memory propertyName,
        string memory value
    ) internal pure returns (Json memory) {
        string memory jsonEscapedString = escapeJsonString(value);
        if (json.depthBitTracker < 0) {
            json.value = string(
                abi.encodePacked(
                    json.value,
                    LIST_SEPARATOR,
                    '"',
                    propertyName,
                    '": "',
                    jsonEscapedString,
                    '"'
                )
            );
        } else {
            json.value = string(
                abi.encodePacked(
                    json.value,
                    '"',
                    propertyName,
                    '": "',
                    jsonEscapedString,
                    '"'
                )
            );
        }

        json.depthBitTracker = setListSeparatorFlag(json);

        return json;
    }

    /**
     * @dev Writes the property name and string text value (as a JSON string) as part of a name/value pair of a JSON object.
     */
    function writeStringValue(Json memory json, string memory value)
        internal
        pure
        returns (Json memory)
    {
        string memory jsonEscapedString = escapeJsonString(value);
        if (json.depthBitTracker < 0) {
            json.value = string(
                abi.encodePacked(
                    json.value,
                    LIST_SEPARATOR,
                    '"',
                    jsonEscapedString,
                    '"'
                )
            );
        } else {
            json.value = string(
                abi.encodePacked(json.value, '"', jsonEscapedString, '"')
            );
        }

        json.depthBitTracker = setListSeparatorFlag(json);

        return json;
    }

    /**
     * @dev Writes the property name and uint value (as a JSON number) as part of a name/value pair of a JSON object.
     */
    function writeUintProperty(
        Json memory json,
        string memory propertyName,
        uint256 value
    ) internal pure returns (Json memory) {
        if (json.depthBitTracker < 0) {
            json.value = string(
                abi.encodePacked(
                    json.value,
                    LIST_SEPARATOR,
                    '"',
                    propertyName,
                    '": ',
                    uintToString(value)
                )
            );
        } else {
            json.value = string(
                abi.encodePacked(
                    json.value,
                    '"',
                    propertyName,
                    '": ',
                    uintToString(value)
                )
            );
        }

        json.depthBitTracker = setListSeparatorFlag(json);

        return json;
    }

    /**
     * @dev Writes the uint value (as a JSON number) as an element of a JSON array.
     */
    function writeUintValue(Json memory json, uint256 value)
        internal
        pure
        returns (Json memory)
    {
        if (json.depthBitTracker < 0) {
            json.value = string(
                abi.encodePacked(
                    json.value,
                    LIST_SEPARATOR,
                    uintToString(value)
                )
            );
        } else {
            json.value = string(
                abi.encodePacked(json.value, uintToString(value))
            );
        }

        json.depthBitTracker = setListSeparatorFlag(json);

        return json;
    }

    /**
     * @dev Writes the beginning of a JSON array or object based on the token parameter.
     */
    function writeStart(Json memory json, bytes1 token)
        private
        pure
        returns (Json memory)
    {
        if (json.depthBitTracker < 0) {
            json.value = string(
                abi.encodePacked(json.value, LIST_SEPARATOR, token)
            );
        } else {
            json.value = string(abi.encodePacked(json.value, token));
        }

        json.depthBitTracker &= MAX_INT256;
        json.depthBitTracker++;

        return json;
    }

    /**
     * @dev Writes the beginning of a JSON array or object based on the token parameter with a property name as the key.
     */
    function writeStart(
        Json memory json,
        string memory propertyName,
        bytes1 token
    ) private pure returns (Json memory) {
        if (json.depthBitTracker < 0) {
            json.value = string(
                abi.encodePacked(
                    json.value,
                    LIST_SEPARATOR,
                    '"',
                    propertyName,
                    '": ',
                    token
                )
            );
        } else {
            json.value = string(
                abi.encodePacked(json.value, '"', propertyName, '": ', token)
            );
        }

        json.depthBitTracker &= MAX_INT256;
        json.depthBitTracker++;

        return json;
    }

    /**
     * @dev Writes the end of a JSON array or object based on the token parameter.
     */
    function writeEnd(Json memory json, bytes1 token)
        private
        pure
        returns (Json memory)
    {
        json.value = string(abi.encodePacked(json.value, token));
        json.depthBitTracker = setListSeparatorFlag(json);

        if (getCurrentDepth(json) != 0) {
            json.depthBitTracker--;
        }

        return json;
    }

    /**
     * @dev Escapes any characters that required by JSON to be escaped.
     */
    function escapeJsonString(string memory value)
        private
        pure
        returns (string memory str)
    {
        bytes memory b = bytes(value);
        bool foundEscapeChars;

        for (uint256 i; i < b.length; i++) {
            if (b[i] == BACKSLASH) {
                foundEscapeChars = true;
                break;
            } else if (b[i] == DOUBLE_QUOTE) {
                foundEscapeChars = true;
                break;
            } else if (b[i] == FRONTSLASH) {
                foundEscapeChars = true;
                break;
            } else if (b[i] == HORIZONTAL_TAB) {
                foundEscapeChars = true;
                break;
            } else if (b[i] == FORM_FEED) {
                foundEscapeChars = true;
                break;
            } else if (b[i] == NEWLINE) {
                foundEscapeChars = true;
                break;
            } else if (b[i] == CARRIAGE_RETURN) {
                foundEscapeChars = true;
                break;
            } else if (b[i] == BACKSPACE) {
                foundEscapeChars = true;
                break;
            }
        }

        if (!foundEscapeChars) {
            return value;
        }

        for (uint256 i; i < b.length; i++) {
            if (b[i] == BACKSLASH) {
                str = string(abi.encodePacked(str, '\\\\'));
            } else if (b[i] == DOUBLE_QUOTE) {
                str = string(abi.encodePacked(str, '\\"'));
            } else if (b[i] == FRONTSLASH) {
                str = string(abi.encodePacked(str, '\\/'));
            } else if (b[i] == HORIZONTAL_TAB) {
                str = string(abi.encodePacked(str, '\\t'));
            } else if (b[i] == FORM_FEED) {
                str = string(abi.encodePacked(str, '\\f'));
            } else if (b[i] == NEWLINE) {
                str = string(abi.encodePacked(str, '\\n'));
            } else if (b[i] == CARRIAGE_RETURN) {
                str = string(abi.encodePacked(str, '\\r'));
            } else if (b[i] == BACKSPACE) {
                str = string(abi.encodePacked(str, '\\b'));
            } else {
                str = string(abi.encodePacked(str, b[i]));
            }
        }

        return str;
    }

    /**
     * @dev Tracks the recursive depth of the nested objects / arrays within the JSON text
     * written so far. This provides the depth of the current token.
     */
    function getCurrentDepth(Json memory json) private pure returns (int256) {
        return json.depthBitTracker & MAX_INT256;
    }

    /**
     * @dev The highest order bit of json.depthBitTracker is used to discern whether we are writing the first item in a list or not.
     * if (json.depthBitTracker >> 255) == 1, add a list separator before writing the item
     * else, no list separator is needed since we are writing the first item.
     */
    function setListSeparatorFlag(Json memory json)
        private
        pure
        returns (int256)
    {
        return json.depthBitTracker | (int256(1) << 255);
    }

    /**
     * @dev Converts an address to a string.
     */
    function addressToString(address _address)
        internal
        pure
        returns (string memory)
    {
        bytes32 value = bytes32(uint256(uint160(_address)));
        bytes16 alphabet = '0123456789abcdef';

        bytes memory str = new bytes(42);
        str[0] = '0';
        str[1] = 'x';
        for (uint256 i; i < 20; i++) {
            str[2 + i * 2] = alphabet[uint8(value[i + 12] >> 4)];
            str[3 + i * 2] = alphabet[uint8(value[i + 12] & 0x0f)];
        }

        return string(str);
    }

    /**
     * @dev Converts an int to a string.
     */
    function intToString(int256 i) internal pure returns (string memory) {
        if (i == 0) {
            return '0';
        }

        if (i == type(int256).min) {
            // hard-coded since int256 min value can't be converted to unsigned
            return
                '-57896044618658097711785492504343953926634992332820282019728792003956564819968';
        }

        bool negative = i < 0;
        uint256 len;
        uint256 j;
        if (!negative) {
            j = uint256(i);
        } else {
            j = uint256(-i);
            ++len; // make room for '-' sign
        }

        uint256 l = j;
        while (j != 0) {
            len++;
            j /= 10;
        }

        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (l != 0) {
            bstr[--k] = bytes1((48 + uint8(l - (l / 10) * 10)));
            l /= 10;
        }

        if (negative) {
            bstr[0] = '-'; // prepend '-'
        }

        return string(bstr);
    }

    /**
     * @dev Converts a uint to a string.
     */
    function uintToString(uint256 _i) internal pure returns (string memory) {
        if (_i == 0) {
            return '0';
        }

        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }

        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            bstr[--k] = bytes1((48 + uint8(_i - (_i / 10) * 10)));
            _i /= 10;
        }

        return string(bstr);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Base64.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides a set of functions to operate with Base64 strings.
 *
 * _Available since v4.5._
 */
library Base64 {
    /**
     * @dev Base64 Encoding/Decoding Table
     */
    string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /**
     * @dev Converts a `bytes` to its Bytes64 `string` representation.
     */
    function encode(bytes memory data) internal pure returns (string memory) {
        /**
         * Inspired by Brecht Devos (Brechtpd) implementation - MIT licence
         * https://github.com/Brechtpd/base64/blob/e78d9fd951e7b0977ddca77d92dc85183770daf4/base64.sol
         */
        if (data.length == 0) return "";

        // Loads the table into memory
        string memory table = _TABLE;

        // Encoding takes 3 bytes chunks of binary data from `bytes` data parameter
        // and split into 4 numbers of 6 bits.
        // The final Base64 length should be `bytes` data length multiplied by 4/3 rounded up
        // - `data.length + 2`  -> Round up
        // - `/ 3`              -> Number of 3-bytes chunks
        // - `4 *`              -> 4 characters for each chunk
        string memory result = new string(4 * ((data.length + 2) / 3));

        /// @solidity memory-safe-assembly
        assembly {
            // Prepare the lookup table (skip the first "length" byte)
            let tablePtr := add(table, 1)

            // Prepare result pointer, jump over length
            let resultPtr := add(result, 32)

            // Run over the input, 3 bytes at a time
            for {
                let dataPtr := data
                let endPtr := add(data, mload(data))
            } lt(dataPtr, endPtr) {

            } {
                // Advance 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // To write each character, shift the 3 bytes (18 bits) chunk
                // 4 times in blocks of 6 bits for each character (18, 12, 6, 0)
                // and apply logical AND with 0x3F which is the number of
                // the previous character in the ASCII table prior to the Base64 Table
                // The result is then added to the table to get the character to write,
                // and finally write it in the result pointer but with a left shift
                // of 256 (1 byte) - 8 (1 ASCII char) = 248 bits

                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance
            }

            // When data `bytes` is not exactly 3 bytes long
            // it is padded with `=` characters at the end
            switch mod(mload(data), 3)
            case 1 {
                mstore8(sub(resultPtr, 1), 0x3d)
                mstore8(sub(resultPtr, 2), 0x3d)
            }
            case 2 {
                mstore8(sub(resultPtr, 1), 0x3d)
            }
        }

        return result;
    }
}