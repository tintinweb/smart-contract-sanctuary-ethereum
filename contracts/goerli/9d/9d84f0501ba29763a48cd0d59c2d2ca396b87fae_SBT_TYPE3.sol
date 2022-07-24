/**
 *Submitted for verification at Etherscan.io on 2022-07-24
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

contract SBT_TYPE3{

  string constant _baseURI = "https://ukishima.github.io/metadata/";

  string public name = "SBT-TYPE3";
  string public symbol = "WSBT"; 
  mapping(uint256 => address) public ownerOf;
  //mapping(address => uint256) public balanceOf;

  event registerd(address indexed owner, uint256 indexed tokenId);



  function supportsInterface(bytes4 interfaceId) public pure returns (bool) {
    return interfaceId == 0x5b5e139f ||
    interfaceId == 0x80ac58cd;
  }

  function mint(uint256 userid,uint256 salt,bytes memory signature) external returns(bytes32){
    bytes32 messagehash = keccak256(abi.encode(msg.sender,userid,salt));
    require(verify(messagehash,signature),"INVAILED SIGNATUER");
    ownerOf[userid] = msg.sender;
    emit registerd(msg.sender,userid);
    return messagehash;
  }

  function regist(uint256 userid,uint256 salt,bytes memory signature) external returns(bytes32){
    bytes32 messagehash = keccak256(abi.encode(msg.sender,userid,salt));
    require(verify(messagehash,signature),"INVAILED SIGNATUER");
    emit registerd(msg.sender,userid);
    return messagehash;
  }

  function tokenURI(uint256 _tokenId) external pure returns (string memory){
      return string(abi.encodePacked(_baseURI,toString(_tokenId),".json")); 
  }

   function verify(bytes32 hash,bytes memory sig) public pure returns (bool) {
        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
        return keccak256(abi.encodePacked(ecrecover(hash, v, r, s))) == 0xddc8e02dcd816f76b8a3f185785cd995996e1d01d976b1d4c05a9bc7718a3b1d;
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