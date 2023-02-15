// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;
import "./Base64.sol";

contract SvgBuildTest{
    
    struct tokenData {
        string SVG;      
        
    }

    mapping (uint => tokenData) public tokens;  

    string public collectionDescription = "bitGANs on-chained";
    string public collectionName = "chainGANs by Pindar Van Arman";

    function setTokenInfo(uint _tokenId, string memory _SVG) public { 
        
        //tokens[_tokenId].name = _name;
        //tokens[_tokenId].trait = _trait;
        tokens[_tokenId].SVG = _SVG;
        //tokens[_tokenId].updated = true;
    }

    function getTokenInfo(uint _tokenId) public view returns (string memory) {
        return (tokens[_tokenId].SVG);
    }

    function buildImage(uint256 _tokenId) public view returns(string memory) {      
      return Base64.encode(bytes(
          abi.encodePacked(tokens[_tokenId].SVG)
      ));
    }

    function buildMetadata(uint256 _tokenId) public view returns(string memory) {

        return string(abi.encodePacked(
         'data:application/json;base64,', Base64.encode(bytes(abi.encodePacked(
                          '{"description":"', 
                          collectionDescription,
                          '", "image": "', 
                          'data:image/svg+xml;base64,', 
                          buildImage(_tokenId),
                          '"}'))))); 
             
      
    }

    function tokenURI(uint256 _tokenId) public view virtual returns (string memory) {      
      return buildMetadata(_tokenId);
    } 
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides a function for encoding some bytes in base64
library Base64 {
    string internal constant TABLE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';
        
        // load the table into memory
        string memory table = TABLE;

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
               dataPtr := add(dataPtr, 3)
               
               // read 3 bytes
               let input := mload(dataPtr)
               
               // write 4 characters
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr( 6, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(        input,  0x3F)))))
               resultPtr := add(resultPtr, 1)
            }
            
            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }
        
        return result;
    }
}