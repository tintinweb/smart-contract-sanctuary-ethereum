/**
 *Submitted for verification at Etherscan.io on 2023-01-29
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

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

/*
    _   ______________   ____                           ____  ____   _____                                 
   / | / / ____/_  __/  / __ \_      ______  ___  _____/ __ \/ __/  / ___/_________ _____  ____  ___  _____
  /  |/ / /_    / /    / / / / | /| / / __ \/ _ \/ ___/ / / / /_    \__ \/ ___/ __ `/ __ \/ __ \/ _ \/ ___/
 / /|  / __/   / /    / /_/ /| |/ |/ / / / /  __/ /  / /_/ / __/   ___/ / /__/ /_/ / / / / / / /  __/ /    
/_/ |_/_/     /_/     \____/ |__/|__/_/ /_/\___/_/   \____/_/     /____/\___/\__,_/_/ /_/_/ /_/\___/_/     
-> Coded by JoeSoap8308(@joesoap8308), developer of the Wrapped Companions.
-> Created to loop through all owned NFT's and return in a text string. Useful for mass query of owned NFT's
-> NB!!! Ensure your Dapp removes the trailing "," off the end once the data is recieved!

*/

///Interfaces
interface NFT {
    function ownerOf(uint256 tokenId) external view returns (address);
    
}
///////Start of contract/////
contract NFTScanner
{
  ////Used to get uint256 -> String
  using Strings for uint256;
  constructor()
  {
    //Nothing to build at offset
  }
     //Returns a string of 
    function returnOwnersNFTS(address _holderaddress,address _projectaddress,uint _collectionamount) external view returns (string memory,uint _numofnfts)
    {
        string memory temp;
        string memory temp2;
        string memory comma = ",";
        uint _numof;
        for (uint256 s = 0; s <= _collectionamount; s += 1){
            try NFT(_projectaddress).ownerOf(s) returns(address _owner) {
           if (_owner==_holderaddress)
           {
            temp = string.concat(s.toString(),comma);
            temp2 = string.concat(temp2,temp);
            _numof++;
           }
            }
            catch
            {
                
            }
    }
        return (temp2,_numof);
    }

    

}