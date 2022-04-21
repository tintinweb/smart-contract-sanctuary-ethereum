// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import {Base64} from "./base64.sol";
struct NFTDetails {
        bytes1 elementId;
        uint32 mass;
        uint32 immunity;
        uint32 power;
        uint32 experience;
    }

struct Element {
        bytes name;
     
        bytes1[] parents;
        uint32 supply;
        uint32 supplyMass;
        uint8 tier;
    }

library Meta {

    string public constant description= "The Game of Building, Fighting and Owning Powerful Creatures on 'Planet EO'.";

    function getMeta(uint256 tokenId,uint256 artWeight, NFTDetails memory metadata, Element memory element, string memory external_url, string memory meta_url) public pure returns (string memory) {
        bytes memory byteString  = abi.encodePacked("{");
        
        byteString = abi.encodePacked(
          byteString,
          _pushJsonStringAttribute("name", string(abi.encodePacked(string(element.name),' [',toString(metadata.mass),'] #', toString(tokenId)))  , true));
        byteString = abi.encodePacked(
          byteString,
          _pushJsonStringAttribute("description",string( description)  , true));
        byteString = abi.encodePacked(
          byteString,
          _pushJsonStringAttribute("external_url",string(external_url)  , true));

        // Image URls
        bytes memory elementFileName=isLowerCase(metadata.elementId)?abi.encodePacked("_",metadata.elementId):abi.encodePacked(metadata.elementId);
        string memory parameters=string(abi.encodePacked(
                "element=",elementFileName,
                "&experience=",toString(metadata.experience),
                "&mass=",toString(metadata.mass),
                "&immunity=",toString(metadata.immunity),
                "&power=",toString(metadata.power),
                "&level=",toString(artWeight),
                "&tier=",toString(element.tier)));
          byteString = abi.encodePacked(
          byteString,
          _pushJsonStringAttribute("animation_url",string(abi.encodePacked(meta_url,"html/",elementFileName,".html?",  parameters))  , true));

         
       // elementFileName=abi.encodePacked( elementFileName,"-", toString(artWeight));
         
        byteString = abi.encodePacked(
          byteString,
          _pushJsonStringAttribute("image",string(abi.encodePacked(meta_url,"images/",elementFileName,"-", toString(artWeight),".png"))  , true));
              
        // Attributes
        byteString = abi.encodePacked(byteString,'"attributes": [' );
        byteString = abi.encodePacked(
            byteString,
            _pushJsonTraitNumber("Mass", toString(metadata.mass) , true));
        byteString = abi.encodePacked(
            byteString,
            _pushJsonTraitNumber("Immunity", toString(metadata.immunity) , true));
        byteString = abi.encodePacked(
            byteString,
            _pushJsonTraitNumber("Power", toString(metadata.power) , true));
        byteString = abi.encodePacked(
            byteString,
            _pushJsonTraitNumber("Experience", toString(metadata.experience) , true));
        byteString = abi.encodePacked(
            byteString,
            '{"trait_type":"Tier", "value":', toString(element.tier),  ', "display_type":"number"},');
        byteString = abi.encodePacked(
            byteString,
            _pushJsonTraitString("Tier Name",string( abi.encodePacked("Tier ",toString(element.tier)) ), false));
         byteString = abi.encodePacked(byteString,']}' );

         string memory base64Json = Base64.encode(byteString);
        return string(abi.encodePacked('data:application/json;base64,', base64Json));
        // return string(byteString);
    }

     

    function _getString(string memory _str) private pure returns (string memory){
        return string(abi.encodePacked(_str));
    }
    function _getField(string memory _str) private pure returns (string memory){
        return string(abi.encodePacked(_str));
    }
    function _pushJsonStringAttribute(string memory key, string memory value, bool insertComma) private pure returns (string memory) {
        return string(abi.encodePacked('"', key, '": "', value, '"', insertComma ? ',' : ''));
    }
    function _pushJsonTraitNumber(string memory trait_type, string memory trait_value, bool insertComma) private pure returns (string memory) {
        return string(abi.encodePacked(
            '{"trait_type":"', trait_type, '", "value":', trait_value,   insertComma ? '},' : '}'
            ));
    }
    function _pushJsonTraitString(string memory trait_type, string memory trait_value, bool insertComma) private pure returns (string memory) {
        return string(abi.encodePacked(
            '{"trait_type":"', trait_type, '", "value":"', trait_value, '"' , insertComma ? '},' : '}'
            ));
    }

    function isLowerCase(bytes1 _id) public pure returns(bool){
        bytes memory allowed = bytes("abcdefghijklmnopqrstuvwxyz"); 
        for(uint j=0; j<allowed.length; j++){
            if(_id==allowed[j] ){
                return true;
            }
        }
        return false;
    }

    function toString(uint256 value) internal pure returns (string memory) {

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

 

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides a set of functions to operate with Base64 strings.
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