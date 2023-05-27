// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

import "./ZExecution.sol";
import "./ZFallback.sol";

/// @notice Zipped contracts v1.0.0
/// @author Zipped Contracts (https://github.com/merklejerk/zipped-contracts)
contract Z is ZFallback {
    // ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒╟▒▒╟╟╟╟╟║║╟║║╟║╟╟║║╟║║║╟║║║║║║║║║║
    // ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▄▓▓▓▓▓▓▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒║╟║╟╠╠║╠▒║║║║▒║╠║║╟║║╟║║║║║║║▓
    // ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓▓▓▓▓▓▓▓▓▓▓▄▒▒▒▒▒▒▒╟▒▒║╢▒╟▓▒▒▒▒▒╚▒▒║▒▒║▒║║║║║║║╟╟║║╢
    // ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒║▓▓▓▓▓▓▓▓▓▓▓▓▓▓▄▒▒▒▒▒▒▒╟║▓▓▓║▒▒▒▒▒▒░░▒░▒▒▒▒║║║║╟╟╢▓▓▓╟╢
    // ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒╟▓╢║▓║╢▓▓▓▓▓▓▓▓▓▓▒▒▒▒▒▒╟▒║▓▓▌║║▓▓▒▒░░░▒▒▒▒░▒║║║║║╢▓▓▓▓╟╟
    // ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒║╢║▓▓╠▒▒░░░▒▒║▓▓▓▒▒▒▒▒╠╟║▓▓▓▓▓╫▓▒▒▒▒▒▒M▒▒▒░▒║║║║║▓▓▓▓▓▓▓
    // ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒║▓▓▓╢▓▄µ░╔▄Q▒▓▓▓▒╟╟╟╟╟║╟╫▓▓▓▓▓▓▒░╢▒▒░░▒╟▓▒║╟║║║▓▓▓▓▓▓▓▓
    // ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒╠█▓▒▒░▒░▒▒▒║▓▓╟╢╢╟╟╟╟╟╟║▓▓███▓▒▒╟▒▒▒▒▒╟▓║╢╢║║╢▓▓▓▓▓▓▓▓
    // ░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒║▓▓▓▓█▓▒▒╢░▒▒▒╫╟║║▓▓▓▓▓▓▓▓▓▓▓█████▓▄▒▒▒▒▒▒╙║╢║║╢║▓▓▓▓▓▓▓▓
    // ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓▓█▓▄▒║▓▓▓██▄▒╙╚▒▒▓▓▓▓║║║▓▓▓▓▓▓▓▓║▓▓████▓▒▒▒²  ,║║║║╢▓██▓▓▓▓▓▓
    // ▒▒▒▒▒▒▒▒▒▒▒▒▒▄▓██████████▓▓║▀███▄▄▓▓▓▓▓║▒▒╢║╚▒▒║▓▒╢▓▓▓▓▓▓╜║]`  √@║║║║║║║║║▓▓▓▓▓▓
    // ▒▒▒▒▒▒▒▒▒▒▒║██▓▓█▓███▓█▓▓▓▓▄]╙▓▓▓▓▓▓▓▓▓▒╢▒▒░░░²╙▒▒╫▓▓▓▓╟╟,`░  ,╢║╟║║║║║║║║║▓▓▓▓▓
    // ▒▒▒▒▒▒▒▒▒▒▒█▓▓▓▓█▓█▓▓▓▓▓▓▓▓▓▓ ░▓▓▓▓▓▓▓▓▓▓▒▒░░√µ▄▒▒▒▓▓▓▓▓▓▒ '√╢╟║╟╟║║╟║╟╟║║║║▓▓▓▓
    // ▒▒▒▒▒▒▒▒▒▒▓███▓▓▒▒▀▀▓▓▓▓▓▓▓▓▓h` ╙▓▓▓▓▓▓█▓▓▓║▒▒▒░░░▒▒K▓▓▓╠░  ║║║║║╟║║║║╢╠║╟║║▓▓▓▓
    // ▒▒▒▒▒▒▒▒▒▓█▓▓▓▓▓▒Nu░▒▒N▒▒▓▓▓▓, ░░~▀█▓▓▓▓█▓▒║╬░░░▒▒▒▒▓█▓╢▒░  ║╟║╟║║║║╟║║║║║╟║║▓▓▓
    // ▒▒▒▒▒▒▒╫▓▓███▓▓╠╙╙▒▒▒╙╙▒║╫██▓,░`~ ░╠▓██▓▓▓▒░▓▒√@░░░▒▀▓▓Ö`   ║║║║║║║║║║║╟║║╟╟║▓▓▓
    // ▒▒▒▒▒▒▒║▓▀▓▓██▓▓▒▒▒▒▒░▒▒╟██▓▒║▒▒æφ▓╢▒║▒▓███▄▒▒░░░▒▒░▒▒ ``«««╚▒▒╙▓▓▓╢║║▓║║╟║║║▓▓▓
    // ▒▒▒▒▒▒║╟▓▓▓▀███▓░▒ÑÑÑ▒░▒██▓▓▓▓▓▓▓▒▒░▒▒░▒▒║▀▀▓▓M▒▒░░░░h  ``,≤@ü▒▒▒▓▓▓▓▓▓▓▓╢╟║╟▓▓▓
    // ▒╠╟╟▒▒╣║▒▒▒╫▓▓▓▓▓▓▒▒ù▒╫███▓▓▓██▓▒▒]▄▀`  `   `'▓▒░░░░`     <M▒▒▒╢▒║▓╢▒░║║╢║║║║╢▓▓
    // ╟╟╫▓▓▓▒▒▒▒▒║▓▓▓▓▓▒▒▒▒▓▓▓▓▓▓▓▓█▓▒▒░▓▓]        `²▒░▒▒         ``▒▒║╝╜╨▓r║║║╟╢║╢▓▓▓
    // ╟▓▓▓▓Ñ▒▒░░║▒▓▓▓▓▓▓▒▒╠▄█▓▓▓▓▓▓▒▒╠╟▒▓░░▒░░       ▒░╜                ░║▓h▓╢╢▓▓▓▓▓▓▓
    // ▓▓▓▓▓▓▒▒▒▒█░║▓▓▓▓▓▒▒▓▓▓▓▓▓▓▓▌║▓║▒▒▒░░▒   `      ▓                 ░║▓▀▀▓▓▓▓▓▓▓▓▓
    // ▓▓▓▓▓▓▓▒▒╟▓▓▄▓▓▓▓▓▒║▓▓▓▓▓▓▓▓▓▒▓▓║▒Ñ▒⌐`]▒░      ░`                ` ]▄ ⁿ╨╝▓▓▓▓▓▓▓
    // ▓▓▓▓▓▓▓▒▒╫▓▓▓▓▓▓▓▓▒║▓▓▓▓▓▓▓▓▓▓▓▓▓█▄░   ░ª,     ]]        ░         ░`▄▌φ  ╢▓▓▓▓▓   
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

import "./Inflate2.sol";
import "./ZBase.sol";

/// @dev Execution functions for zipped contracts.
/// @author Zipped Contracts (https://github.com/merklejerk/zipped-contracts)
contract ZExecution is Inflate2, ZBase {
    error OnlyDelegateCallError();
    error CreationFailedError();
    error UnzippedHashMismatchError();
    error StaticContextError();
    error ZFail();
    error ZSuccess();

    // Revert if we are not in a delegatecall (from anyone but ourselves) context.
    modifier onlyDelegateCall() {
        if (address(this) == _IMPL) {
            revert OnlyDelegateCallError();
        }
        _;
    }

    // Revert if the current execution context is inside a staticcall().
    modifier noStaticContext() {
        {
            bool isStaticcall;
            bytes4 selector = this.__checkStaticContext.selector;
            address impl = _IMPL;
            assembly {
                mstore(0x00, selector)
                pop(call(1200, impl, 0, 0x00, 0x04, 0x00, 0x00))
                isStaticcall := iszero(eq(returndatasize(), 1))
            }
            if (isStaticcall) {
                revert StaticContextError();
            }
        }
        _;
    }

    /// @notice Make an arbitrary function call on a zipped contract.
    /// @dev The contract will be unzipped, deployed, then called.
    ///      All changes will be revert()ed to prevent permanently modifying state.
    ///      Performs a raw return of the result, as if the function was called directly.
    ///      Must be called via a delegatecall from the context of the zipped contract.
    /// @param zipped The address holding the zipped data. If different from address(this)
    ///               then a delegatecall() instead of a call() will be performed on
    ///               the unzipped contract.
    /// @param dataOffset The offset into `zipped`'s bytecode to start reading zipped data.
    /// @param dataSize The size of the zipped data.
    /// @param unzippedSize The size of the unzipped initcode.
    /// @param unzippedHash The hash of the unzipped initcode.
    /// @param callData ABI-encoded function call to make against the unzipped (and deployed) contract.
    function zcallWithRawResult(
        address zipped,
        uint256 dataOffset,
        uint256 dataSize,
        uint256 unzippedSize,
        bytes32 unzippedHash,
        bytes calldata callData
    )
        public
        onlyDelegateCall
        // Naked result of the call is returned.
    {
        bytes memory initCode;
        address unzipped = _computeZCallDeployAddress(address(this), unzippedHash);
        bool shouldDelegateCall = address(this) != zipped;
        // Allow the original msg.sender to be recovered by the unzipped contract by
        // appending it to the calldata.
        bytes memory callDataWithSender = abi.encodePacked(callData, uint256(uint160(msg.sender)));
        if (unzipped.code.length == 0) {
            //  Unzip initcode.
            initCode = _inflateAndCheck(
                zipped,
                dataOffset,
                dataSize,
                unzippedSize,
                unzippedHash
            );
            // Deploy and call without (permanently) altering state.
            (bool b, bytes memory r) = _IMPL.delegatecall(abi.encodeCall(
                this.__execZCall,
                (unzipped, shouldDelegateCall, initCode, callDataWithSender)
            ));
            assert(!b);
            _handleExecRevert(r); // Terminates.
        } else {
            // The contract was already unzipped and deployed earlier in the call stack.
            // We can just call it directly and let the top level zcall do the clean up.
            (bool b, bytes memory r) = shouldDelegateCall
                ? unzipped.delegatecall(callDataWithSender)
                : unzipped.call(callDataWithSender);
            if (!b) {
                assembly { revert(add(r, 0x20), mload(r)) }
            }
            assembly { return(add(r, 0x20), mload(r)) }
        }
    }

    function __execZCall(
        address unzipped,
        bool shouldDelegateCall,
        bytes memory initCode,
        bytes memory callData
    )
        external
        noStaticContext
    {
        if (unzipped.code.length == 0) {
            assembly {
                unzipped := create2(
                    0,
                    add(initCode, 0x20),
                    mload(initCode),
                    address()
                )
            }
            if (unzipped == address(0)) {
                revert CreationFailedError();
            }
        }
        (bool b, bytes memory r) = shouldDelegateCall
            ? unzipped.delegatecall(callData)
            : unzipped.call(callData);
        uint256 len = r.length;
        bytes4 selector = b ? ZSuccess.selector : ZFail.selector;
        assembly {
            mstore(r, shr(224, selector))
            revert(add(r, 28), add(len, 4))
        }
    }

    /// @notice Execute the initcode of a zipped contract.
    /// @dev The contract will be unzipped and deployed. The unzipped initcode should write (return())
    ///      its successful result data to its runtime bytecode.
    ///      All changes will be revert()ed to prevent permanently modifying state.
    ///      Performs a raw return of the result, as if the function was called directly.
    ///      Must be called via a delegatecall from the context of the zipped contract.
    /// @param zipped The address holding the zipped data.
    /// @param dataOffset The offset into `zipped`'s bytecode to start reading zipped data.
    /// @param dataSize The size of the zipped data.
    /// @param unzippedSize The size of the unzipped initcode.
    /// @param unzippedHash The hash of the unzipped initcode.
    /// @param initArgs ABI-encoded call data to pass to unzipped initcode during deployment.
    ///                 Function selector should be included but will be stripped.
    function zrunWithRawResult(
        address zipped,
        uint256 dataOffset,
        uint256 dataSize,
        uint256 unzippedSize,
        bytes32 unzippedHash,
        bytes calldata initArgs
    )
        public
        onlyDelegateCall
        // Naked runtime code is returned.
    {
        //  Unzip initcode.
        bytes memory initCode = _inflateAndCheck(
            zipped,
            dataOffset,
            dataSize,
            unzippedSize,
            unzippedHash
        );
        // Allow the original msg.sender to be recovered by the unzipped contract by
        // appending it to the initArgs.
        bytes memory initArgsWithSender = abi.encodePacked(initArgs, uint256(uint160(msg.sender)));
        // Deploy without (permanently) altering state.
        (bool b, bytes memory r) = _IMPL.delegatecall(abi.encodeCall(
            this.__execZRun,
            (initCode, initArgsWithSender)
        ));
        assert(!b);
        _handleExecRevert(r); // Terminates.
    }

    function __execZRun(
        bytes memory initCode,
        bytes calldata initArgs
    )
        external
        noStaticContext
    {
        address unzipped;
        {
            bytes memory initCodeWithArgs = abi.encodePacked(initCode, initArgs[4:]);
            assembly {
                unzipped := create2(
                    0,
                    add(initCodeWithArgs, 0x20),
                    mload(initCodeWithArgs),
                    address()
                )
            }
        }
        if (unzipped == address(0)) {
            revert CreationFailedError();
        }
        bytes memory runtime = unzipped.code;
        uint256 len = runtime.length;
        bytes4 selector = ZSuccess.selector;
        assembly {
            mstore(runtime, shr(224, selector))
            revert(add(runtime, 28), add(len, 4))
        }
    }

    function __checkStaticContext() external {
        assembly {
            log0(0x00, 0x00)
            revert(0x00, 0x01)
        }
    }

    function _inflateAndCheck(
        address zipped,
        uint256 dataOffset,
        uint256 dataSize,
        uint256 unzippedSize,
        bytes32 unzippedHash
    )
        private view
        returns (bytes memory unzipped)
    {
        unzipped = Inflate2(_IMPL).inflateFrom(
            zipped,
            dataOffset,
            dataSize,
            unzippedSize
        );
        if (unzippedHash != bytes32(0)) {
            if (bytes32(keccak256(unzipped)) != unzippedHash) {
                revert UnzippedHashMismatchError();
            }
        }
    }

    function _handleExecRevert(bytes memory r) private pure {
        if (r.length >= 4) {
            bytes4 selector;
            assembly ("memory-safe") { selector := mload(add(r, 0x20)) }
            if (selector == ZFail.selector) {
                assembly("memory-safe") {
                    revert(add(r, 0x24), sub(mload(r), 0x04))
                }
            } else if (selector == ZSuccess.selector) {
                assembly("memory-safe") {
                    return(add(r, 0x24), sub(mload(r), 0x04))
                }
            }
        }
        assembly ("memory-safe") {
            revert(add(r, 0x20), mload(r))
        }
    }

    function _computeZCallDeployAddress(address zipped, bytes32 initCodeHash)
        internal pure
        returns (address d)
    {
        return address(uint160(uint256(keccak256(abi.encodePacked(
            bytes1(0xff),
            zipped,
            uint256(uint160(zipped)),
            initCodeHash
        )))));
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

import "./ZExecution.sol";
import "./ZRuntimeConstants.sol";
import "./ZBase.sol";

/// @dev Fallback handlers for Self-extracting zipped contracts.
/// @author Zipped Contracts (https://github.com/merklejerk/zipped-contracts)
contract ZFallback is ZExecution {
    /// @dev The fallback handler for a self-extracting zcall contract.
    ///      The self-extracting zcall contract always delegatecalls this function when it receives
    ///      any call.
    ///      Although it takes no args, it expects the calldata from the self-extracting
    ///      contract's fallback to be appended to msg.data (our calldata).
    ///      selector: 0000009f
    function selfExtractingZCallFallback__fq1aqw47v() external {
       _handleSelfExtractingFallback(ZExecution.zcallWithRawResult.selector);
    }
    
    /// @dev The fallback handler for a self-extracting zrun contract.
    ///      The self-extracting zrun contract always delegatecalls this function when it receives
    ///      any call.
    ///      Although it takes no args, it expects the calldata from the self-extracting
    ///      contract's fallback to be appended to msg.data (our calldata).
    ///      selector: 0000000b
    function selfExtractingZRunFallback__wme3t() external {
        _handleSelfExtractingFallback(ZExecution.zrunWithRawResult.selector);
    }

    /// @notice Check if a caller to an unzipped contract is the zipped version of that contract.
    function isZippedCaller(address caller, address unzipped) external view returns (bool) {
        (, bytes32 unzippedHash) = _readMetadata(caller);
        return _computeZCallDeployAddress(caller, unzippedHash) == unzipped;
    }

    function _handleSelfExtractingFallback(bytes4 execSelector) private {
        uint256 ZIPPED_DATA_OFFSET = ZRuntimeConstants.ZIPPED_DATA_OFFSET;

        // The zipped contract handler will append its deployed address to the calldata.
        address zipped = abi.decode(msg.data[msg.data.length - 32:], (address));
        // The original calldata for zipped contract call is appended right
        // after ours.
        bytes calldata origCallData = msg.data[4:msg.data.length-32];
        uint256 zippedDataSize = zipped.code.length - ZIPPED_DATA_OFFSET;
        (uint24 unzippedSize, bytes32 unzippedHash) = _readMetadata(zipped);
        // Call the zip execute function.
        if (execSelector == ZExecution.zcallWithRawResult.selector) {
            zcallWithRawResult(
                zipped,
                ZIPPED_DATA_OFFSET,
                zippedDataSize,
                unzippedSize,
                unzippedHash,
                origCallData
            );
        } else { // ZExecution.zrunWithRawResult.selector
            zrunWithRawResult(
                zipped,
                ZIPPED_DATA_OFFSET,
                zippedDataSize,
                unzippedSize,
                unzippedHash,
                origCallData
            );
        }
    }

    function _readMetadata(address zipped)
        private view
        returns (uint24 unzippedSize, bytes32 unzippedHash)
    {
        uint256 FALLBACK_SIZE = ZRuntimeConstants.FALLBACK_SIZE;
        uint256 METADATA_SIZE = ZRuntimeConstants.METADATA_SIZE;
        // Read metadata from zipped contract's bytecode.
        assembly ("memory-safe") {
            let p := mload(0x40)
            // Metadata comes right after the fallback.
            extcodecopy(zipped, p, FALLBACK_SIZE, METADATA_SIZE)
            unzippedSize := shr(232, mload(p)) // 3 bytes
            unzippedHash := mload(add(p, 3)) // 32 bytes
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

/// @notice Solidity implementation of zlib deflate.
/// @dev Optimistic form of:
///      https://github.com/adlerjohn/inflate-sol/blob/2a88141f5226da9d0252be4a456a2e0b23ba3d0e/contracts/InflateLib.sol
/// @author Zipped Contracts (https://github.com/merklejerk/zipped-contracts)
/// @author @adlerjohn (https://github.com/adlerjohn/inflate-sol) (original)
contract Inflate2 {
    // Maximum bits in a code
    uint256 constant MAXBITS = 15;
    // Maximum number of literal/length codes
    uint256 constant MAXLCODES = 286;
    // Maximum number of distance codes
    uint256 constant MAXDCODES = 30;
    // Maximum codes lengths to read
    uint256 constant MAXCODES = (MAXLCODES + MAXDCODES);
    // Number of fixed literal/length codes
    uint256 constant FIXLCODES = 288;

    // Error codes
    error InvalidBlockTypeError(); // invalid block type (type == 3)
    error InvalidLengthOrDistanceCodeError(); // invalid literal/length or distance code in fixed or dynamic block

    // Input and output state
    struct State {
        //////////////////
        // Output state //
        //////////////////
        // Output buffer
        bytes output;
        // Bytes written to out so far
        uint256 outcnt;
        /////////////////
        // Input state //
        /////////////////
        // Bytes read so far
        uint256 incnt;
        ////////////////
        // Temp state //
        ////////////////
        // Bit buffer
        uint256 bitbuf;
        // Number of bits in bit buffer
        uint256 bitcnt;
        // Descriptor code lengths used by _build_dynamic()
        uint256[] tmpDynamicLengths;
        // Length and distance codes used by _build_dynamic()
        Huffman tmpLencode;
        Huffman tmpDistcode;
        //////////////////////////
        // Static Huffman codes //
        //////////////////////////
        Huffman fixedLencode;
        Huffman fixedDistcode;
        //////////////////////////
        // Constants (set in puff())
        //////////////////////////
        // Size base for length codes 257..285
        uint16[29] CODES_LENS;
        // Extra bits for length codes 257..285
        uint8[29] CODES_LEXT;
        // Offset base for distance codes 0..29
        uint16[30] CODES_DISTS;
        // Extra bits for distance codes 0..29
        uint8[30] CODES_DEXTS;
        // Permutation of code length codes
        uint8[19] BUILD_DYNAMIC_LENGTHS_ORDER;
    }
    
    // Huffman code decoding tables
    struct Huffman {
        uint256[] counts;
        uint256[] symbols;
    }

    function _readInputByte(uint256 i) private pure returns (uint8 b) {
        assembly {
            let o := add(0x04, calldataload(0x04))
            b := shr(248, calldataload(add(o, add(0x20, i))))
        }
    }
    
    function _bits(State memory s, uint256 need)
        private
        pure
        returns (uint256 ret)
    { unchecked {
        // Bit accumulator (can use up to 20 bits)
        uint256 val;

        // Load at least need bits into val
        val = s.bitbuf;
        while (s.bitcnt < need) {
            // Load eight bits
            val |= uint256(_readInputByte(s.incnt++)) << s.bitcnt;
            s.bitcnt += 8;
        }

        // Drop need bits and update buffer, always zero to seven bits left
        s.bitbuf = val >> need;
        s.bitcnt -= need;

        // Return need bits, zeroing the bits above that
        ret = (val & ((1 << need) - 1));
    } }

    function _stored(State memory s) private pure { unchecked {
        // Length of stored block
        uint256 len;

        // Discard leftover bits from current byte (assumes s.bitcnt < 8)
        s.bitbuf = 0;
        s.bitcnt = 0;

        // Get length and check against its one's complement
        len = uint256(_readInputByte(s.incnt++));
        len |= uint256(_readInputByte(s.incnt++)) << 8;
        s.incnt += 2;
        while (len != 0) {
            len -= 1;
            s.output[s.outcnt++] = bytes1(_readInputByte(s.incnt++));
        }
    } }

    function _decode(State memory s, Huffman memory h)
        private
        pure
        returns (uint256)
    { unchecked {
        // Current number of bits in code
        uint256 len;
        // Len bits being decoded
        uint256 code = 0;
        // First code of length len
        uint256 first = 0;
        // Number of codes of length len
        uint256 count;
        // Index of first code of length len in symbol table
        uint256 index = 0;

        for (len = 1; len <= MAXBITS; len++) {
            // Get next bit
            uint256 tempCode;
            tempCode = _bits(s, 1);
            code |= tempCode;
            count = h.counts[len];

            // If length len, return symbol
            if (code < first + count) {
                return h.symbols[index + (code - first)];
            }
            // Else update for next length
            index += count;
            first += count;
            first <<= 1;
            code <<= 1;
        }

        // Ran out of codes
        revert InvalidLengthOrDistanceCodeError();
    } }

    function _construct(
        Huffman memory h,
        uint256[] memory lengths,
        uint256 n,
        uint256 start
    ) private pure { unchecked {
        // Current symbol when stepping through lengths[]
        uint256 symbol;
        // Current length when stepping through h.counts[]
        uint256 len;
        // Number of possible codes left of current length
        uint256 left;
        // Offsets in symbol table for each length
        uint256[MAXBITS + 1] memory offs;

        // Count number of codes of each length
        for (len = 0; len <= MAXBITS; len++) {
            h.counts[len] = 0;
        }
        for (symbol = 0; symbol < n; symbol++) {
            // Assumes lengths are within bounds
            h.counts[lengths[start + symbol]]++;
        }
        // No codes!
        if (h.counts[0] == n) {
            // Complete, but decode() will fail
            return;
        }

        // Check for an over-subscribed or incomplete set of lengths

        // One possible code of zero length
        left = 1;
        
        offs[1] = 0;
        for (len = 1; len <= MAXBITS; len++) {
            // One more bit, double codes left
            left <<= 1;
            // Deduct count from possible codes

            left -= h.counts[len];
           
            // Generate offsets into symbol table for each length for sorting
            if (len < MAXBITS) {
                offs[len + 1] = offs[len] + h.counts[len];
            }
        }

        // Put symbols in table sorted by length, by symbol order within each length
        for (symbol = 0; symbol < n; symbol++) {
            if (lengths[start + symbol] != 0) {
                h.symbols[offs[lengths[start + symbol]]++] = symbol;
            }
        }
    } }

    function _codes(
        State memory s,
        Huffman memory lencode,
        Huffman memory distcode
    ) private pure { unchecked {
        // Decoded symbol
        uint256 symbol;
        // Length for copy
        uint256 len;
        // Distance for copy
        uint256 dist;
        // Size base for length codes 257..285
        uint16[29] memory lens = s.CODES_LENS;
        // Extra bits for length codes 257..285
        uint8[29] memory lext = s.CODES_LEXT;
        // Offset base for distance codes 0..29
        uint16[30] memory dists = s.CODES_DISTS;
        // Extra bits for distance codes 0..29
        uint8[30] memory dext = s.CODES_DEXTS;

        // Decode literals and length/distance pairs
        while (symbol != 256) {
            symbol = _decode(s, lencode);

            if (symbol < 256) {
                // Literal: symbol is the byte
                // Write out the literal
                s.output[s.outcnt] = bytes1(uint8(symbol));
                s.outcnt++;
            } else if (symbol > 256) {
                uint256 tempBits;
                // Length
                // Get and compute length
                symbol -= 257;

                tempBits = _bits(s, lext[symbol]);
                len = lens[symbol] + tempBits;

                // Get and check distance
                symbol = _decode(s, distcode);
                tempBits = _bits(s, dext[symbol]);
                dist = dists[symbol] + tempBits;

                // Copy length bytes from distance bytes back
                bytes memory output = s.output;
                uint256 outcnt = s.outcnt;
                s.outcnt += len;
                assembly ("memory-safe") {
                    let dst := add(output, add(0x20, outcnt))
                    switch gt(len, dist)
                        case 1 {
                            for {} iszero(iszero(len)) {} {
                                mstore(dst, mload(sub(dst, dist)))
                                len := sub(len, 0x01)
                                dst := add(dst, 0x01)
                            }
                        }
                        default {
                            for {} iszero(iszero(len)) {} {
                                mstore(dst, mload(sub(dst, dist)))
                                switch gt(len, 0x20)
                                    case 1 {
                                        len := sub(len, 0x20)
                                        dst := add(dst, 0x20)
                                    }
                                    default {
                                        len := 0
                                    }
                            }
                        }
                }
            } else {
                s.outcnt += len;
            }
        }
    } }

    function _build_fixed(State memory s) private pure { unchecked {
        // Build fixed Huffman tables
        // TODO this is all a compile-time constant
        uint256 symbol;
        uint256[] memory lengths = new uint256[](FIXLCODES);

        // Literal/length table
        for (symbol = 0; symbol < 144; symbol++) {
            lengths[symbol] = 8;
        }
        for (; symbol < 256; symbol++) {
            lengths[symbol] = 9;
        }
        for (; symbol < 280; symbol++) {
            lengths[symbol] = 7;
        }
        for (; symbol < FIXLCODES; symbol++) {
            lengths[symbol] = 8;
        }

        _construct(s.fixedLencode, lengths, FIXLCODES, 0);

        // Distance table
        for (symbol = 0; symbol < MAXDCODES; symbol++) {
            lengths[symbol] = 5;
        }

        _construct(s.fixedDistcode, lengths, MAXDCODES, 0);
    } }

    function _fixed(State memory s) private pure {
        // Decode data until end-of-block code
        _codes(s, s.fixedLencode, s.fixedDistcode);
    }

    function _build_dynamic_lengths(State memory s)
        private
        pure
        returns (uint256[] memory)
    { unchecked {
        uint256 ncode;
        // Index of lengths[]
        uint256 index;

        ncode = _bits(s, 4);
        ncode += 4;

        // Read code length code lengths (really), missing lengths are zero
        for (index = 0; index < ncode; index++) {
            s.tmpDynamicLengths[s.BUILD_DYNAMIC_LENGTHS_ORDER[index]] = _bits(s, 3);
        }
        for (; index < 19; index++) {
            s.tmpDynamicLengths[s.BUILD_DYNAMIC_LENGTHS_ORDER[index]] = 0;
        }

        return s.tmpDynamicLengths;
    } }

    function _build_dynamic(State memory s)
        private
        pure
        returns (
            Huffman memory,
            Huffman memory
        )
    { unchecked {
        // Number of lengths in descriptor
        uint256 nlen;
        uint256 ndist;
        // Length and distance codes
        Huffman memory lencode = s.tmpLencode;
        Huffman memory distcode = s.tmpDistcode;
        uint256 tempBits;
        
        // Get number of lengths in each table, check lengths
        nlen = _bits(s, 5);
        nlen += 257;
        ndist = _bits(s, 5);
        ndist += 1;
        
        // Descriptor code lengths
        uint256[] memory lengths = _build_dynamic_lengths(s);

        // Build huffman table for code lengths codes (use lencode temporarily)
        _construct(lencode, lengths, 19, 0);

        // Index of lengths[]
        uint256 index = 0;
        // Read length/literal and distance code length tables
        while (index < nlen + ndist) {
            // Decoded value
            uint256 symbol;
            // Last length to repeat
            uint256 len;

            symbol = _decode(s, lencode);

            if (symbol < 16) {
                // Length in 0..15
                lengths[index++] = symbol;
            } else {
                // Repeat instruction
                // Assume repeating zeros
                len = 0;
                if (symbol == 16) {
                    // Repeat last length 3..6 times
                    // Last length
                    len = lengths[index - 1];
                    tempBits = _bits(s, 2);
                    symbol = 3 + tempBits;
                } else if (symbol == 17) {
                    // Repeat zero 3..10 times
                    tempBits = _bits(s, 3);
                    symbol = 3 + tempBits;
                } else {
                    // == 18, repeat zero 11..138 times
                    tempBits = _bits(s, 7);
                    symbol = 11 + tempBits;
                }

                assembly ("memory-safe") {
                    let p := add(lengths, add(0x20, mul(index, 0x20)))
                    index := add(index, symbol)
                    for {} iszero(iszero(symbol)) {} {
                        mstore(p, len)
                        symbol := sub(symbol, 1)
                        p := add(p, 0x20)
                    }
                }
            }
        }

        // Build huffman table for literal/length codes
        _construct(lencode, lengths, nlen, 0);

        // Build huffman table for distance codes
        _construct(distcode, lengths, ndist, nlen);

        return (lencode, distcode);
    } }

    function _dynamic(State memory s) private pure {
        // Length and distance codes
        Huffman memory lencode;
        Huffman memory distcode;

        (lencode, distcode) = _build_dynamic(s);

        // Decode data until end-of-block code
        _codes(s, lencode, distcode);
    }

    function inflate(bytes calldata /* input */, uint256 outputSize)
        external 
        pure
        returns (bytes memory)
    {
        // Input/output state
        State memory s =
            State({
                output: new bytes(outputSize),
                outcnt: 0,
                incnt: 0,
                bitbuf: 0,
                bitcnt: 0,
                tmpDynamicLengths: new uint256[](MAXCODES),
                tmpLencode: Huffman(new uint256[](MAXBITS + 1), new uint256[](MAXCODES)),
                tmpDistcode: Huffman(new uint256[](MAXBITS + 1), new uint256[](MAXCODES)),
                fixedLencode: Huffman(new uint256[](MAXBITS + 1), new uint256[](FIXLCODES)),
                fixedDistcode: Huffman(new uint256[](MAXBITS + 1), new uint256[](MAXDCODES)),
                CODES_LENS: [ 3, 4, 5, 6, 7, 8, 9, 10, 11, 13, 15, 17, 19, 23, 27, 31, 35, 43, 51,
                    59, 67, 83, 99, 115, 131, 163, 195, 227, 258 ],
                CODES_LEXT: [ 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4,
                    4, 5, 5, 5, 5, 0 ],
                CODES_DISTS: [ 1, 2, 3, 4, 5, 7, 9, 13, 17, 25, 33, 49, 65, 97, 129, 193, 257, 385,
                    513, 769, 1025, 1537, 2049, 3073, 4097, 6145, 8193, 12289, 16385,
                    24577 ],
                CODES_DEXTS: [ 0, 0, 0, 0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 7, 7, 8, 8, 9, 9, 10,
                    10, 11, 11, 12, 12, 13, 13 ],
                BUILD_DYNAMIC_LENGTHS_ORDER: [16, 17, 18, 0, 8, 7, 9, 6, 10, 5, 11, 4, 12, 3, 13, 2, 14, 1, 15]
            });
        // Temp: last bit
        uint256 last;
        // Temp: block type bit
        uint256 t;

        // Build fixed Huffman tables
        _build_fixed(s);

        // Process blocks until last block or error
        while (last == 0) {
            // One if last block
            last = _bits(s, 1);

            // Block type 0..3
            t = _bits(s, 2);

            if (t == 0) {
                _stored(s);
            } else if (t == 1) {
                _fixed(s);
            } else if (t == 2) {
                _dynamic(s);
            } else {
                revert InvalidBlockTypeError();
            }
        }

        return s.output;
    }

    function inflateFrom(
        address dataAddr,
        uint256 dataOffset,
        uint256 dataSize,
        uint256 outputSize
    )
        external
        view
        returns (bytes memory)
    {
        bytes memory data = new bytes(dataSize);
        assembly ("memory-safe") {
            extcodecopy(dataAddr, add(data, 0x20), dataOffset, dataSize)
        }
        return this.inflate(data, outputSize);
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

import "./ZExecution.sol";
import "./ZRuntimeConstants.sol";

/// @author Zipped Contracts (https://github.com/merklejerk/zipped-contracts)
contract ZBase {
    address immutable internal _IMPL;

    constructor() {
        _IMPL = address(this);
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

import "./ZExecution.sol";

/// @dev Constants for self-extracting contracts.
/// @author Zipped Contracts (https://github.com/merklejerk/zipped-contracts)
library ZRuntimeConstants {
    uint256 internal constant FALLBACK_SIZE = 0x4E;
    uint256 internal constant METADATA_SIZE = 35;
    uint256 internal constant ZIPPED_DATA_OFFSET = FALLBACK_SIZE + METADATA_SIZE;
}