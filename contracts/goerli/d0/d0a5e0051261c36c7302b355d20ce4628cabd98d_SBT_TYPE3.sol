/**
 *Submitted for verification at Etherscan.io on 2022-07-17
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

contract SBT_TYPE3{

  string constant _baseURI = "https://ukishima.github.io/metadata/";

  string public name = "SBT-TYPE3";
  string public symbol = "WSBT"; 
  mapping(uint256 => address) public ownerOf;
  mapping(address => uint256) public balanceOf;



  function supportsInterface(bytes4 interfaceId) public pure returns (bool) {
    return interfaceId == 0x5b5e139f ||
    interfaceId == 0x80ac58cd;
  }

  function mint(uint256 discordId) external returns(bool){
    ownerOf[discordId] = msg.sender;
    balanceOf[msg.sender] = 1;
    return true;
  }

  function tokenURI(uint256 _tokenId) external pure returns (string memory){
      return string(abi.encodePacked(_baseURI,toString(_tokenId),".json")); 
  }


  function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            unchecked{
                digits++;
                temp /= 10;
            }

        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            unchecked{
                digits -= 1;
                buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
                value /= 10;
            }
        }
        return string(buffer);
   }

}