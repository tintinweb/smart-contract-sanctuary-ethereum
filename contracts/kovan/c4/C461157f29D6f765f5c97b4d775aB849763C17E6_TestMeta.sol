/**
 *Submitted for verification at Etherscan.io on 2022-08-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


contract TestMeta {

    event score(address playerAddress, uint256 score);
    
    mapping (address => uint256) public replayNonce;

    address public signer = 0xFac3570Ee799Ac83437Fea1c7B3d89d8c9ae62Cf;

    function scored(
    uint8 v,
    bytes32 r,
    bytes32 s,
    address scorer,
    uint256 _score,
    uint256 nonce
  ) external {
    uint chainId;
    assembly {
      chainId := chainid()
    }
    bytes32 eip712DomainHash = keccak256(
        abi.encode(
            keccak256(
                "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
            ),
            keccak256(bytes("TestMeta")),
            keccak256(bytes("1")),
            chainId,
            address(this)
        )
    );  

    bytes32 hashStruct = keccak256(
      abi.encode(
          keccak256("set(address scorer,uint256 score,uint256 nonce)"),
          scorer,
          _score,
          nonce
        )
    );

    bytes32 hash = keccak256(abi.encodePacked("\x19\x01", eip712DomainHash, hashStruct));
    address transactionSigner = ecrecover(hash, v, r, s);
    require(msg.sender == scorer, "each player is allowed to submit for themself.");
    require(transactionSigner == signer, "MyFunction: invalid signature");
    require(transactionSigner != address(0), "ECDSA: invalid signature");
    require(nonce == replayNonce[scorer], "Nonce is not valid");
    replayNonce[scorer]++;
    emit score( scorer, _score);
  }

}