/**
 *Submitted for verification at Etherscan.io on 2022-10-11
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
pragma abicoder v2;






contract UlazyV6 {
 

    uint256 id = 0;
    mapping(uint256 => string) public src;
    mapping(uint256 => string[]) public matrix;


    function mint(string memory _src) external{
        src[id] = _src;
        id++;
    }

    //this will decode the encoded matrix array and tranform it back into the matrix array
    function dcd(uint256 _id, uint256 _position) public view returns(string memory) {
      
      string memory srcSample = src[_id];
      uint256 mLength = bytes(srcSample).length;
      string memory delim = "#"; //the character that marks the beginning or end of a unit of data
      string memory result;
      uint256 crrnt = 0;
      uint256 key = 0;

      ///we count delims
      
      while(crrnt < _position){
         for(uint256 i = 0; i < mLength; i++){
         if(keccak256(abi.encodePacked(substring(srcSample, i, i+1))) == keccak256(abi.encodePacked(delim))){
            crrnt++;
            key = i;
            if( crrnt == _position){
               result = substring(srcSample, i, i+7 );
               key = i;
              }
            }
          }
        }
     
      return result;
    
    }




    function decoder(uint _pos) public pure returns(string memory){
      uint snap = 7;
      uint shot = _pos * snap;
      string memory sample = "#123456#234567";

      return substring(sample, shot,shot + snap );
    }



       function buildSVG(uint256 _id) public view returns(string memory)  {
      
        uint256 w = 25;
        uint256 key = 0;
        string memory svg = '<svg width="625" height="625" xmlns="http://www.w3.org/2000/svg"><g shapeRendering="crispEdges">';
        string memory end = '</g></svg>';
        //uint snap = 7;
        string[ 625 ] memory gett = testerConstructor(_id);

        
        for(uint y = 0; y < w * w; y += w){
          for(uint x = 0; x < w * w; x += w){
            key++;
            svg = string(abi.encodePacked( svg, '<rect width="25" height="25" fill="',  gett[key]  ,'"  x="',  Strings.toString(x) , '" y="',  Strings.toString(y)  ,'" />'));
          }
        }
         return string.concat(svg,end) ;
        
      }

    function substring(string memory str, uint startIndex, uint endIndex) public pure returns (string memory) {
    bytes memory strBytes = bytes(str);
    bytes memory result = new bytes(endIndex-startIndex);
    for(uint i = startIndex; i < endIndex; i++) {
        result[i-startIndex] = strBytes[i];
    }
    return string(result);
}


 
  function testerConstructor(uint256 _id) public view returns(string[ 625 ] memory){
    string memory smple = src[_id];
    uint snap = 7;
    string[625] memory trx;
  
    
    for(uint i = 0; i < bytes(smple).length / snap ; i++){
      trx[i] = substring( smple, i*7, i*7 + 7 );
    }
    return trx;
  }

  /*function getter(uint256 _id) public view returns(string memory){
    string[ 625 ] memory gett = testerConstructor(_id);
    return  string(abi.encodePacked( gett[0] ));
  }*/
      

    


    

}