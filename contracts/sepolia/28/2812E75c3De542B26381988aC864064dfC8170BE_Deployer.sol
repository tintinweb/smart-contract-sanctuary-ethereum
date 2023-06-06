// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.17;

contract DummyContract {
    uint256 public nonce;
}

contract Deployer {
    event Deployed(address);

    // This is the runtime code of the contract we would like to deploy
    // Example: `contract DummyContract { uint256 public nonce; }`
    bytes CONTRACT_RUNTIME_CODE =
        hex"6080604052348015600e575f80fd5b50600436106026575f3560e01c8063affed0e014602a575b5f80fd5b60315f5481565b60405190815260200160405180910390f3fea26469706673582212204f0a61f1ffa2241c100b63605cb049faa04babc79439f41ba60ac3e0b293ed3664736f6c63430008140033";

    // This handmade creation code is responsible of returning the creation code of dynamic length
    // ⚠️ It assumes the contract we would like to deploy doesn't have a constructor (!!)
    // ℹ️ If the size of the precompile is fixed, we can simplify the sequence
    bytes constant CREATION_CODE = hex"80_60_0E_60_00_39_60_00_F3";

    /*
      0x00    0x63         0x63XXXXXX  PUSH4 _code.length  size
      0x01    0x80         0x80        DUP1                size size
      0x02    0x60         0x600e      PUSH1 14            14 size size
      0x03    0x60         0x6000      PUSH1 00            0 14 size size
      0x04    0x39         0x39        CODECOPY            size
      0x05    0x60         0x6000      PUSH1 00            0 size
      0x06    0xf3         0xf3        RETURN
      <CODE>
    */
    function deploy(bytes calldata precompile) external returns (address addr) {
        uint256 finalRuntimeCodeLength = CONTRACT_RUNTIME_CODE.length + precompile.length;

        bytes memory bytecode = abi.encodePacked(
            hex"63", // PUSH4
            uint32(finalRuntimeCodeLength), // <length>
            // responsible of returning the dynamic runtime code
            CREATION_CODE,
            // concatenation of both runtime code
            bytes.concat(CONTRACT_RUNTIME_CODE, precompile)
        );

        assembly {
            addr := create(0, add(bytecode, 0x20), mload(bytecode))
            // if the `create` opcode fails, the address is equals to 0
            if iszero(extcodesize(addr)) {
                revert(0, 0)
            }
        }

        emit Deployed(addr);
    }

    function deploy(bytes calldata precompile, bytes32 salt)
        external
        returns (address addr)
    {
        uint256 finalRuntimeCodeLength = CONTRACT_RUNTIME_CODE.length + precompile.length;

        bytes memory bytecode = abi.encodePacked(
            hex"63", // PUSH4
            uint32(finalRuntimeCodeLength), // <length>
            // responsible of returning the dynamic runtime code
            CREATION_CODE,
            // concatenation of both runtime code
            bytes.concat(CONTRACT_RUNTIME_CODE, precompile)
        );

        assembly {
            addr := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
            // if the `create` opcode fails, the address is equals to 0
            if iszero(extcodesize(addr)) {
                revert(0, 0)
            }
        }

        emit Deployed(addr);
    }
}