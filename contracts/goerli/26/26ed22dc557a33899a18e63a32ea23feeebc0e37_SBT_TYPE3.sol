/**
 *Submitted for verification at Etherscan.io on 2022-08-10
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

contract SBT_TYPE3{

  string baseURI = "https://ukishima.github.io/metadata/";
  bytes32 validator = 0xddc8e02dcd816f76b8a3f185785cd995996e1d01d976b1d4c05a9bc7718a3b1d;

  string public name = "SBT-TYPE3";
  string public symbol = "WSBT"; 
  mapping(uint256 => address) public ownerOf;
  mapping(bytes32 => address) public usedSignature;

  event registerd(uint256 indexed owner, address indexed tokenId);
  event changedValidator(bytes32 newValidatorHash, address operator);
  event changedBaseURI(string newURI, address operator);



  function supportsInterface(bytes4 interfaceId) public pure returns (bool) {
    return interfaceId == 0x5b5e139f ||
    interfaceId == 0x80ac58cd;
  }

  function mint(address owner,uint256 userid,uint256 salt,bytes calldata signature) external{
    require(msg.sender==owner,"WRONG ADDRESS");
    bytes32 messagehash = keccak256(abi.encode(owner,userid,salt));
    require(verify(messagehash,signature),"INVAILED");
    ownerOf[userid] = owner;
    emit registerd(userid,owner);
  }

  function regist(address owner,uint256 userid,uint256 salt,bytes calldata signature) external{
    require(msg.sender==owner,"WRONG ADDRESS");
    bytes32 messagehash = keccak256(abi.encode(owner,userid,salt));
    require(verify(messagehash,signature),"INVAILED");
    emit registerd(userid,owner);
  }

  function burn(uint256 userid) external{
    require(msg.sender==ownerOf[userid],"OWNER ONLY");
    ownerOf[userid] = address(0);
    emit registerd(userid,address(0));
  }


  function tokenURI(uint256 _tokenId) external view returns (string memory){
      return string(abi.encodePacked(baseURI,toString(_tokenId),".json")); 
  }

/*
   function gethash(address owner,uint256 userid,uint256 salt) external pure returns (bytes32){
       bytes32 messagehash = keccak256(abi.encode(owner,userid,salt));
       return messagehash;

   }
*/

   function setValidator(bytes32 newValidatorHash,uint256 salt,bytes calldata signature) external{
      bytes32 messagehash = keccak256(abi.encode(newValidatorHash,salt));
      require(verify(messagehash,signature),"INVAILED");
      require(usedSignature[messagehash] == address(0),"REUSED");
      validator = newValidatorHash;
      usedSignature[messagehash] = msg.sender;
      emit changedValidator(newValidatorHash,msg.sender);
   }

   function setBaseURI(string calldata newURI,uint256 salt,bytes calldata signature) external{
      bytes32 messagehash = keccak256(abi.encode(newURI,salt));
      require(verify(messagehash,signature),"INVAILED");
      require(usedSignature[messagehash] == address(0),"REUSED");
       baseURI = newURI;
       usedSignature[messagehash] = msg.sender;
       emit changedBaseURI(newURI,msg.sender);
   }

   function IsValidator(address operator) public view returns(bool){
        return keccak256(abi.encodePacked(operator)) == validator;
   }

   function verify(bytes32 hash,bytes memory sig) public view returns (bool) {
        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
        return keccak256(abi.encodePacked(ecrecover(hash, v, r, s))) == validator;
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