/**
 *Submitted for verification at Etherscan.io on 2022-05-19
*/

pragma solidity ^0.8.6;

library StringLibrary {

    function compare(string memory s1, string memory s2) public pure returns (bool) {
             return keccak256(abi.encodePacked(s1)) == keccak256(abi.encodePacked(s2));
    }
    function stringToBytes32Hash(string memory source) pure public returns (bytes32   result) {
            return keccak256(abi.encodePacked(source));
    }

    function bytes32HashToString (bytes32   data) pure public  returns ( string memory ) {
                return string(abi.encodePacked(data));

    }



        function stringToBytes32(string memory source)  pure public returns (bytes32 result) {
            assembly {
            result := mload(add(source, 32))
            }
        }
/*
        function bytes32ToString (bytes32 data)  pure public returns (string) {
                    bytes memory bytesString = new bytes(32);
                    for (uint j=0; j<32; j++) {
                        byte char = byte(bytes32(uint(data) * 2 ** (8 * j)));
                        if (char != 0) {
                            bytesString[j] = char;
                        }
                    }
                    return string(bytesString);
                }
      */
          function bytes32ToString(bytes32 _bytes32) public pure returns (string memory) {
                  uint8 i = 0;
                  while(i < 32 && _bytes32[i] != 0) {
                      i++;
                  }
                  bytes memory bytesArray = new bytes(i);
                  for (i = 0; i < 32 && _bytes32[i] != 0; i++) {
                      bytesArray[i] = _bytes32[i];
                  }
                  return string(bytesArray);
              }

}