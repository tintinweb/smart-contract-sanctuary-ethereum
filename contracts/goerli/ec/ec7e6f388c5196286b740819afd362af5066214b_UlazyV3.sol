/**
 *Submitted for verification at Etherscan.io on 2022-10-09
*/

// File: @openzeppelin/contracts/utils/Strings.sol


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

// File: Ulazy.sol


pragma solidity 0.8.12;




contract UlazyV3 {

    uint256 id = 0;
    mapping(uint256 => string) public sources;
    mapping(uint256 => string[]) public matrix;

    function mint(string memory _src) external{
        sources[id] = _src;
        id++;

    }

    function decode(string memory _data) internal  {
      //this will decode the encoded matrix array and tranform it back into an array
      
    }

       function buildSVG(uint256 _id) public view returns(string memory)  {
        matrix[_id];
        uint256 w = 33;
        uint256 key = 0;
        string memory svg = '<svg width="441" height="441" xmlns="http://www.w3.org/2000/svg"><g shapeRendering="crispEdges">';
        string memory end = '</g></svg>';

        for(uint y = 0; y < w * w; y += w){
          for(uint x = 0; x < w * w; x += w){
            key++;
            svg = string(abi.encodePacked( svg, '<rect width="21" height="21" fill="red"  x="',  Strings.toString(x) , '" y="',  Strings.toString(y)  ,'" />'));
          }
        }
         return string.concat(svg,end) ;
        
      }
      

    


    

}