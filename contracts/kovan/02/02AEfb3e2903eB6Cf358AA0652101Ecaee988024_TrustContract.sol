// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract TrustContract {
  uint public storedData;

  string public AppName;

  string public AppVersion;

  bytes32 public salt;

  uint public chain;

  constructor(
    string memory AppName_,
    string memory AppVersion_
  ) {
    AppName = AppName_;
    AppVersion = AppVersion_;

    salt = keccak256(bytes("HelloWorld"));

    uint chainId;
    assembly {
      chainId := chainid()
    }

    chain = chainId;
  }

  function set(uint x) internal {
    storedData = x;
  }

  function get() public view returns (uint) {
    return storedData;
  }

  function executeSetIfSignatureMatch(
    uint8 v,
    bytes32 r,
    bytes32 s,
    address sender,
    uint256 deadline,
    uint x
  ) external {
    require(block.timestamp < deadline, "Signed transaction expired");

    bytes32 eip712DomainHash = keccak256(
        abi.encode(
            keccak256(
                bytes("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract,bytes32 salt)")
            ),
            keccak256(bytes(AppName)),
            keccak256(bytes(AppVersion)),
            chain,
            address(this),
            salt
        )
    );  

    bytes32 hashStruct = keccak256(
      abi.encode(
          keccak256("set(address sender,uint x,uint deadline)"),
          sender,
          x,
          deadline
        )
    );

    bytes32 hash = keccak256(abi.encodePacked("\x19\x01", eip712DomainHash, hashStruct));
    address signer = ecrecover(hash, v, r, s);
    require(signer == sender, "MyFunction: invalid signature");
    require(signer != address(0), "ECDSA: invalid signature");

    set(x);
  }
}