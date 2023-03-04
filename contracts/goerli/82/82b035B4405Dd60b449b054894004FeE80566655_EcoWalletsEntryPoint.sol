// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @notice Canonical entrypoint contract for Eco Wallet interactions.
contract EcoWalletsEntryPoint {
    /// @dev The logic contract for the current wallet.
    address private _currentExecRuntime;
    /// @dev The current calldata to execute on logic contract.
    bytes private _currentExecCallData;
    /// @notice Whether an execFrom nonce was consumed.
    mapping(address => mapping(uint248 => uint256)) public wasNonceUsed;

    error RuntimeDeployError();
    error RuntimeDestroyError();

    /// @notice Ephemerally execute a runtime from a wallet controlled by the caller.
    function exec(bytes calldata runtimeCode, bytes calldata callData, uint256 walletSalt)
        external payable
    {
        address runtime = _deployRuntime(runtimeCode);
        _exec(runtime, callData, msg.sender, walletSalt);
        {
            // Destroy the runtime contract by calling into it.
            _transferEth(runtime, 0);
        }
    }

    /// @notice Execute an existing runtime from a wallet controlled by the caller. 
    function reexec(address runtime, bytes calldata callData, uint256 walletSalt)
        external payable
    {
        _exec(runtime, callData, msg.sender, walletSalt);
    }

    /// @notice Return the current runtime contract and calldata being executed.
    function getExecuteInfo()
        external
        view
        returns (address runtime, bytes memory callData)
    {
        return (_currentExecRuntime, _currentExecCallData);
    }

    /// @notice Predict the address of a wallet given its owner and salt.
    function getWallet(address owner, uint256 walletSalt)
        external view
        returns (address)
    {
        return _toCreate2Address(
            keccak256(type(Wallet).creationCode),
            _getWalletCreateSalt(owner, walletSalt)
        );
    }

    /// @notice Predict the address of a runtime given its runtime code.
    function getRuntimeByRuntimeCode(bytes calldata runtimeCode)
        external view
        returns (address)
    {
        return _toCreate2Address(keccak256(_getRuntimeInitCode(runtimeCode)), 0);
    }

    uint256 private constant PATCH_SIZE = 5;

    function _getRuntimeInitCode(bytes calldata runtimeCode)
        internal view
        returns (bytes memory runtimeInitCode)
    {
        assembly {
            function processRuntimeCode(runtimeOffset, runtimeSize, bytesNeeded) -> ovwSize, codeSize {
                let opSize
                for { let i := 0 } lt(i, runtimeSize) { i := add(i, opSize) } {
                    let op := shr(248, calldataload(add(runtimeOffset, i)))
                    opSize := 1
                    switch op
                        case 0x5B {
                            if lt(ovwSize, bytesNeeded) {
                                // JUMPDESTs are not allowed in overwritten bytes.
                                mstore(0x00, 0x64616E6765726F75735F72756E74696D65000000000000000000000000000000)
                                revert(0x00, 0x20)
                            }
                        }
                        default {
                            if and(gt(op, 0x5F), lt(op, 0x80)) {
                                // PUSHX instruction
                                opSize := sub(op, 0x5E)
                            }
                        }
                    if gt(add(codeSize, opSize), runtimeSize) {
                        break
                    }
                    if lt(ovwSize, bytesNeeded) {
                        // Claim overwritten bytes.
                        ovwSize := add(ovwSize, opSize)
                    }
                    codeSize := add(codeSize, opSize)
                }
            }

            let ovwSize, origRuntimeSize := processRuntimeCode(runtimeCode.offset, runtimeCode.length, PATCH_SIZE)
            let patchedRuntimeSize := add(add(origRuntimeSize, 88), ovwSize)
            let initCodeSize := add(patchedRuntimeSize, 15)
            let p := mload(0x40)
            runtimeInitCode := p
            mstore(0x40, add(p, add(initCodeSize, 0x20)))
            mstore(p, initCodeSize)
            p := add(p, 0x20)

            /** Build up the following initCode:
            PUSH2 patchedRuntimeSize
            DUP1
            PUSH1 RUNTIME_OFFSET
            RETURNDATASIZE
            CODECOPY
            ADDRESS
            PUSH2 patchedRuntimeSize - 32
            MSTORE
            RETURNDATASIZE
            RETURN
            (^^ 15 bytes)
            PUSH2 :detour                   // start of runtime code
            JUMP
            ...<UNUSED: ovwSize - 5>
            JUMPDEST :resume               // @ 4 + (ovwSize - 5)
                ...<RUNTIME_CODE[ovwSize:]>
            JUMPDEST :detour               // @ origRuntimeSize
                PUSH1 32
                PUSH2 patchedRuntimeSize - 32
                RETURNDATASIZE
                CODECOPY
                RETURNDATASIZE
                MLOAD
                RETURNDATASIZE
                RETURNDATASIZE
                MSTORE
                ADDRESS
                EQ
                PUSH2 :non-delegatecall
                JUMPI
                ...<RUNTIME_CODE[:ovwSize]>
                PUSH2 :resume
                JUMP
            JUMPDEST :non-delegatecall // @ origRuntimeSize + ovwSize + 23
                PUSH20 ENTRY_POINT_ADDRESS
                CALLER
                EQ
                PUSH2 :kill
                JUMPI
                INVALID
            JUMPDEST :kill              // @ origRuntimeSize + ovwSize + 52
                ORIGIN
                SELFDESTRUCT
            INVALID
            ...<DEPLOYED_ADDRESS>
            (^^ 88 + runtimeSize + ovwSize bytes)
            **/
        
            // PUSH2 <RUNTIME_CODE_SIZE>
            mstore8(p, 0x61)
            p := add(p, 1)
            mstore(p, shl(240, patchedRuntimeSize))
            p := add(p, 2)
            // DUP1
            // PUSH1 15
            // RETURNDATASIZE
            // CODECOPY
            // ADDRESS
            // PUSH2 patchedRuntimeSize - 32
            mstore(p, hex"80_600F_3D_39_30_6100000000000000000000000000000000000000000000000000")
            p := add(p, 7)
            mstore(p, shl(240, sub(patchedRuntimeSize, 32)))
            p := add(p, 2)
            // MSTORE
            // RETURNDATASIZE
            // RETURN
            // PUSH2 :detour
            mstore(p, hex"52_3D_F3_6100000000000000000000000000000000000000000000000000000000")
            p := add(p, 4)
            mstore(p, shl(240, origRuntimeSize))
            p := add(p, 2)
            mstore8(p, 0x56) // JUMP
            p := add(p, add(1, sub(ovwSize, PATCH_SIZE)))
            mstore8(p, 0x5B) // JUMPDEST :resume
            p := add(p, 1)
            calldatacopy(p, add(runtimeCode.offset, ovwSize), sub(origRuntimeSize, ovwSize)) // <RUNTIME_CODE[ovwSize:]>
            p := add(p, sub(origRuntimeSize, ovwSize))

            // JUMPDEST :detour
            // PUSH1 32
            // PUSH2 patchedRuntimeSize - 32
            mstore(p, hex"5B_6020_6100000000000000000000000000000000000000000000000000000000")
            p := add(p, 4)
            mstore(p, shl(240, sub(patchedRuntimeSize, 32)))
            p := add(p, 2)
    
            //   RETURNDATASIZE
            //   CODECOPY
            //   RETURNDATASIZE
            //   MLOAD
            //   RETURNDATASIZE
            //   RETURNDATASIZE
            //   MSTORE
            //   ADDRESS
            //   EQ
            //   PUSH2 :non-delegatecall
            mstore(p, hex"3D_39_3D_51_3D_3D_52_30_14_6100000000000000000000000000000000000000000000")
            p := add(p, 10)
            mstore(p, shl(240, add(add(origRuntimeSize, ovwSize), 23)))
            p := add(p, 2)
            //   JUMPI
            mstore8(p, 0x57)
            p := add(p, 1)
            //   ...<RUNTIME_CODE[:ovwSize]>
            calldatacopy(p, runtimeCode.offset, ovwSize) // <RUNTIME_CODE[:ovwSize]>
            p := add(p, ovwSize)
            //   PUSH2 :resume
            mstore8(p, 0x61)
            p := add(p, 1)
            mstore(p, shl(240, sub(ovwSize, 1)))
            p := add(p, 2)
            //   JUMP
            //   JUMPDEST :non-delegatecall // @ origRuntimeSize + ovwSize + 23
            //      PUSH20 ENTRY_POINT_ADDRESS
            mstore(p, hex"56_5B_730000000000000000000000000000000000000000000000000000000000")
            p := add(p, 3)
            mstore(p, shl(96, address()))
            p := add(p, 20)
            //      CALLER
            //      EQ
            //      PUSH2 :kill
            mstore(p, hex"33_14_610000000000000000000000000000000000000000000000000000000000")
            p := add(p, 3)
            mstore(p, shl(240, add(add(origRuntimeSize, ovwSize), 52)))
            p := add(p, 2)
            //      JUMPI
            //      INVALID
            //  JUMPDEST :kill              // @ origRuntimeSize + ovwSize + 52
            //      ORIGIN
            //      SELFDESTRUCT
            //   INVALID
            mstore(p, hex"57_FE_5B_32_FF_FE_0000000000000000000000000000000000000000000000000000")
        }
    }

    /// @dev Deploy a runtime deterministically based on its bytecode and whether it's reusable.
    function _deployRuntime(bytes calldata runtimeCode)
        public
        // resetMemory
        returns (address runtime)
    {
        bytes memory runtimeInitCode = _getRuntimeInitCode(runtimeCode);
        runtime = _toCreate2Address(keccak256(runtimeInitCode), 0);
        if (runtime.code.length == 0) {
            assembly {
                runtime := create2(0, add(runtimeInitCode, 0x20), mload(runtimeInitCode), 0)
            }
            if (runtime == address(0)) {
                revert RuntimeDeployError();
            }
        }
    }

    /// @dev Execute a runtime as a wallet controlled by the owner.
    function _exec(address runtime, bytes calldata callData, address owner, uint256 accountSalt)
        private
    {
        // Store the runtime address for the wallet contract to
        // read.
        _currentExecRuntime = runtime;
        // Store the calldata for the wallet contract to read.
        _currentExecCallData = callData;
        // "Deploy" an Wallet contract.
        // It will selfdestruct immediately in its constructor so we
        // can keep deploying it to the same address over and over.
        bytes32 salt = _getWalletCreateSalt(owner, accountSalt);
        // This will also revert if the execution reverts.
        Wallet wallet = new Wallet{salt: salt, value: msg.value}();
        // No one needs these states anymore so score a refund.
        delete _currentExecRuntime;
        delete _currentExecCallData;
        // Because the Wallet contract selfdestructs immediately, any ETH
        // it held will be sent to this contract. Send any ETH we have right back.
        _transferAllEth(payable(address(wallet)));
    }

    /// @dev Transfer all ETH held by this contract to an address.
    function _transferAllEth(address to)
        private
    {
        if (address(this).balance != 0) {
            _transferEth(to, address(this).balance);
        }
    }

    function _transferEth(address to, uint256 value)
        private
    {
        assembly {
            let s := call(gas(), to, value, 0x00, 0x00, 0x00, 0x00)
            if iszero(s) {
                returndatacopy(0x00, 0x00, returndatasize())
                revert(0x00, returndatasize())
            }
        }
    }

    /// @dev Compute the create2 salt for a wallet.
    function _getWalletCreateSalt(address owner, uint256 accountSalt)
        private pure
        returns (bytes32 salt)
    {
        assembly {
            mstore(0x00, owner)
            mstore(0x20, accountSalt)
            salt := keccak256(0x00, 0x40)
        }
    }

    /// @dev Predict a generic create2 deployment address.
    function _toCreate2Address(bytes32 initCodeHash, bytes32 salt)
        private view
        returns (address addr)
    {
        assembly {
            let fmp := mload(0x40)
            mstore8(0x00, 0xFF)
            mstore(0x01, shl(96, address()))
            mstore(0x15, salt)
            mstore(0x35, initCodeHash)
            addr := and(keccak256(0x00, 0x55), 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
            mstore(0x40, fmp)
        }
    }
}

/// @notice Wallet instance.
/// @dev Only defines a constructor, because the entire lifecycle of a wallet
///      happens inside of it.
contract Wallet {
    constructor() payable {
        assembly {
            // Call getExecuteInfo() to retrieve current runtime address and calldata from the manager.
            mstore(0x00, 0x247394e300000000000000000000000000000000000000000000000000000000)
            pop(staticcall(gas(), caller(), 0x00, 0x04, 0x00, 0x00))
            // Return data will be address, callDataLength, callData
            returndatacopy(0x00, 0x00, returndatasize())
            // Delegatecall into runtime.
            if iszero(delegatecall(
                gas(),
                // runtime
                mload(0x00),
                // callDataStart
                0x60,
                // callDataLength
                mload(0x40),
                0x00,
                0x00
            )) {
                revert(0x00, 0x00)
            }
            if returndatasize() {
                // Log any result data.
                returndatacopy(0x00, 0x00, returndatasize())
                log0(0x00, returndatasize())
            }
            // Self destruct, sending ETH back to the manager, who will just transfer it back.
            selfdestruct(caller())
        }
    }
}