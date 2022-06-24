// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
import "./ECDSA.sol";
contract Migrations {
  function getEthSignedMessageHash(bytes32 messageHash) public pure returns (bytes32)
  {
      return
          keccak256(
              abi.encodePacked(
                  "\x19Ethereum Signed Message:\n32",
                  messageHash
              )
          );
  }
  function checkRoyalties(
    address buyer,
    address nft,
    address seller,
    uint tokenId,
    uint edition,
    uint validity,
    uint amount,
    uint volume,
    bytes memory tradeSign
  ) public view returns (address){
    uint time = block.timestamp;
    require(validity >= time,'Signature expired');
    address certifier = ECDSA.recover(getEthSignedMessageHash(keccak256(abi.encodePacked(
      buyer,
      nft,
      seller,
      tokenId,
      edition,
      validity,
      amount,
      volume))),
      tradeSign);
    return certifier;
  }
}