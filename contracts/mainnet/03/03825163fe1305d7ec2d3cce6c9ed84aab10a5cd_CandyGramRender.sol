// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
pragma experimental ABIEncoderV2;


import "@openzeppelin/[email protected]/access/Ownable.sol";
import "@openzeppelin/[email protected]/utils/Base64.sol";
import "@openzeppelin/[email protected]/utils/Strings.sol";

contract CandyGramRender is Ownable {

    string public externalBaseUrl = "https://dotmaps.wtf/candygram/token/";
    string public imageBaseUrl = "https://dotmaps.wtf/workers/cg/v1/";
    string public animBaseUrl = "";
    bool public enableAnim = false;

    function setExternalBaseUrl(string calldata url) public onlyOwner {
        externalBaseUrl = url;
    }

    function setImageBaseUrl(string calldata url) public onlyOwner {
        imageBaseUrl = url;
    }

    function setAnimBaseUrl(string calldata url,bool enable) public onlyOwner {
        animBaseUrl = url;
        enableAnim = enable;
    }

    // all colors start at 0 then randomly increase variance the longer held
    function colorKey(RenderData calldata d,uint8 salt) internal pure returns (string memory) {
        uint variance = 64+(d.renderBlock - d.lastTransferBlock)/7163 + 1; // 7163 blocks per day
        if(variance > 255){
            variance = 255;
        }
        uint8 gramColor = uint8(uint256(keccak256(abi.encodePacked(d.gramStartBlock,salt))) % 256);

        unchecked { gramColor += uint8(variance); }
         
        return Strings.toString(gramColor);
    }

    function tiledKey(uint256 addressTokenCount) internal view returns (string memory) {
        if(addressTokenCount>4){
            return "1";
        }
        return tiledKeys[addressTokenCount];
    }

    function adjKey(bytes32 rk,uint8 salt) internal pure returns (string memory) {
        return Strings.toString(uint8(uint256(keccak256(abi.encodePacked(rk,salt))) % 16));
    }

    function fgImgKey(bytes32 rk) internal view returns (string memory) {
        return fgImageNames[uint8(uint256(keccak256(abi.encodePacked(rk,"fg"))) % fgImageNames.length)];
    }

    function bgImgKey(bytes32 rk, address owner) internal view returns (string memory) {
        return bgImageNames[uint8(uint256(keccak256(abi.encodePacked(rk,owner,"bg"))) % bgImageNames.length)];
    }

    function rotationKey(bytes32 rk) internal pure returns (string memory) {
        uint8 b = uint8(uint256(keccak256(abi.encodePacked(rk,"rotation"))) % 1024);
        if(b < 1008){
            return "0";
        }else if(b < 1016){
            return "90";
        }else if(b < 1022){
            return "270";
        }else{
            return "180";
        }
    }


    struct RenderData {
        uint256 tokenId; 
        uint8 gramId;
        string gramName;
        uint256 gramStartBlock;
        uint256 gramStopBlock;
        uint256 tweetId;
        bytes32 renderKey;
        uint256 renderBlock;
        uint256 mintBlock;
        address owner;
        uint256 lastTransferBlock;
        int256 addressTokenCount;
        uint256 totalTokenCount;
    }


    function render(RenderData calldata d) 
        public 
        view
        returns (string memory)
    {
        string memory renderVal = "";
        string memory imgData = string(abi.encodePacked(Strings.toString(d.gramId)));

        string memory output = string(abi.encodePacked(R_TOKEN_OPEN,Strings.toString(d.tokenId),R_TOKEN_DESCR_1,Strings.toString(d.tokenId)));
        output = string(abi.encodePacked(output,R_TOKEN_DESCR_2,Strings.toString(d.gramId)));
        output = string(abi.encodePacked(output,R_TOKEN_TWEET,Strings.toString(d.tweetId),R_TOKEN_ATTR_1_SOURCE_NAME,d.gramName));

        if(d.renderKey != 0x0){
            // Foreground Image of is based off the render key
            renderVal = fgImgKey(d.renderKey);
            output = string(abi.encodePacked(output,R_TOKEN_ATTR_2_FG_IMG,renderVal));
            imgData = string(abi.encodePacked(imgData,URL_DATA_SPLIT,renderVal));

            // Rotation is based off of the render key
            renderVal = rotationKey(d.renderKey);
            output = string(abi.encodePacked(output,R_TOKEN_ATTR_3_ROTATION,renderVal));
            imgData = string(abi.encodePacked(imgData,URL_DATA_SPLIT,renderVal));

            // Background Image is based off of how early the DCG was minted in the gram chain
            renderVal = bgImgKey(d.renderKey,d.owner);
            output = string(abi.encodePacked(output,R_TOKEN_ATTR_4_BG_IMG,renderVal));
            imgData = string(abi.encodePacked(imgData,URL_DATA_SPLIT,renderVal));
        }else{
            imgData = string(abi.encodePacked(imgData,URL_DATA_SPLIT,"pre-reveal"));
        }

        //uint8 colorVar = colorVariance(d.renderBlock,d.lastTransferBlock);
        // BG color render values are based on the token and the owner address 
        // so they change ever time a token is transfered.
        //renderVal = colorKey(d.renderKey,d.owner,colorVar,d.totalTokenCount,0);
        renderVal = colorKey(d,0);
        //output = string(abi.encodePacked(output,R_TOKEN_ATTR_7_BG_C_R,renderVal));
        imgData = string(abi.encodePacked(imgData,URL_DATA_SPLIT,renderVal));

        renderVal = colorKey(d,1);
        //output = string(abi.encodePacked(output,R_TOKEN_ATTR_8_BG_C_G,renderVal));
        imgData = string(abi.encodePacked(imgData,URL_DATA_SPLIT,renderVal));

        renderVal = colorKey(d,2);
        //output = string(abi.encodePacked(output,R_TOKEN_ATTR_9_BG_C_B,renderVal));
        imgData = string(abi.encodePacked(imgData,URL_DATA_SPLIT,renderVal));

        if(d.renderKey != 0x0){
            // Adjustments render based on the render key (Brightness, Contrast, Gamma)
            renderVal = adjKey(d.renderKey,3);
            output = string(abi.encodePacked(output,R_TOKEN_ATTR_5_BRIGHTNESS,renderVal));
            imgData = string(abi.encodePacked(imgData,URL_DATA_SPLIT,renderVal));

            renderVal = adjKey(d.renderKey,4);
            output = string(abi.encodePacked(output,R_TOKEN_ATTR_6_CONTRAST,renderVal));
            imgData = string(abi.encodePacked(imgData,URL_DATA_SPLIT,renderVal));

            renderVal = adjKey(d.renderKey,5);
            output = string(abi.encodePacked(output,R_TOKEN_ATTR_7_GAMMA,renderVal));
            imgData = string(abi.encodePacked(imgData,URL_DATA_SPLIT,renderVal));
        }

        renderVal = tiledKey(uint256(d.addressTokenCount));
        imgData = string(abi.encodePacked(imgData,URL_DATA_SPLIT,renderVal));

        // close attributes tag
        output = string(abi.encodePacked(output,R_TOKEN_ATTR_CLOSE));

        // image link
        output = string(abi.encodePacked(output,R_TOKEN_IMAGE_OPEN,imageBaseUrl,imgData,URL_PATH_SPLIT));
        output = string(abi.encodePacked(output,Strings.toString(d.tokenId),URL_FILE_TYPE,R_TOKEN_IMAGE_CLOSE));
        
        // external link
        output = string(abi.encodePacked(output,R_TOKEN_EXTERNAL_OPEN,externalBaseUrl,Strings.toString(d.tokenId),R_TOKEN_EXTERNAL_CLOSE));

        if(enableAnim){
            // animation link
            output = string(abi.encodePacked(output,R_TOKEN_ANIM_OPEN,animBaseUrl,Strings.toString(d.tokenId),URL_PATH_SPLIT)); 
            output = string(abi.encodePacked(output,Strings.toString(d.tweetId),URL_PATH_SPLIT,imgData,R_TOKEN_ANIM_CLOSE)); 
        }

        output = string(abi.encodePacked(output,R_TOKEN_CLOSE));
        
        return string(abi.encodePacked(R_TOKEN_DATA,Base64.encode(bytes(string(abi.encodePacked(output))))));
    }

    string[8] private fgImageNames = ["Raw","Empty","Build","Growth","Abstract","Polish","Color","Complete"];
    string[128] private bgImageNames = ["Ability","Country","Goal","Meaning","Problem","Television","Activity","Data","Growth","Meat","Product","Temperature","Addition","Decision","Health","Media","Quality","Thanks","Analysis","Definition","History","Medicine","Reading","Theory","Area","Department","Idea","Method","Reality","Thing","Army","Development","Income","Moment","Road","Thought","Art","Direction","Industry","Mood","Safety","Truth","Article","Disk","Information","Movie","Science","Unit","Audience","Distribution","Instance","Nation","Security","University","Basis","Driver","Internet","Nature","Series","User","Bird","Economics","Knowledge","News","Shopping","Variety","Blood","Education","Lake","Night","Skill","Video","Boyfriend","Energy","Language","Organization","Society","War","Camera","Equipment","Law","Oven","Software","Week","Cell","Event","Length","Paper","Soup","Wood","Chemistry","Exam","Library","People","Story","World","Child","Fact","Location","Person","Strategy","Writing","Combination","Failure","Love","Philosophy","Student","Community","Family","Management","Physics","Success","Computer","Fishing","Marketing","Player","System","Context","Food","Marriage","Policy","Teacher","Control","Freedom","Math","Power","Technology","Depth"];
    string[6] private tiledKeys = ["6","5","4","3","2"];
    
    string constant URL_PATH_SPLIT = "/";
    string constant URL_DATA_SPLIT = "_";
    string constant URL_FILE_PREFIX = "token-";
    string constant URL_FILE_TYPE = ".png";

    string constant R_TOKEN_DATA = 'data:application/json;base64,';
    string constant R_TOKEN_OPEN = '{"name":"#';
    string constant R_TOKEN_DESCR_1 = '","description":"Token #';
    string constant R_TOKEN_DESCR_2 = ' minted from CandyGram #';
    string constant R_TOKEN_TWEET = '","tweet_id":"';
    string constant R_TOKEN_ATTR_1_SOURCE_NAME = '","attributes":[{"trait_type":"Origin","value":"';
    string constant R_TOKEN_ATTR_2_FG_IMG = '"},{"trait_type":"Image","value":"';
    string constant R_TOKEN_ATTR_3_ROTATION = '"},{"trait_type":"Rotation","value":"';
    string constant R_TOKEN_ATTR_4_BG_IMG = '"},{"trait_type":"Pattern","value":"';
    string constant R_TOKEN_ATTR_5_BRIGHTNESS = '"},{"trait_type":"Brightness Level","value":"';
    string constant R_TOKEN_ATTR_6_CONTRAST = '"},{"trait_type":"Contrast Level","value":"';
    string constant R_TOKEN_ATTR_7_GAMMA = '"},{"trait_type":"Gamma Level","value":"';
    string constant R_TOKEN_ATTR_CLOSE = '"}]';

    string constant R_TOKEN_IMAGE_OPEN = ',"image":"';
    string constant R_TOKEN_IMAGE_CLOSE = '"';

    string constant R_TOKEN_EXTERNAL_OPEN = ',"external_url":"';
    string constant R_TOKEN_EXTERNAL_CLOSE = '"';

    string constant R_TOKEN_ANIM_OPEN = ',"animation_url":"';
    string constant R_TOKEN_ANIM_CLOSE = '"';

    string constant R_TOKEN_CLOSE = '}';
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