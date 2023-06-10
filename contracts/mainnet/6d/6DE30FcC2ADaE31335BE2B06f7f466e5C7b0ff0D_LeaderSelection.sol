// SPDX-License-Identifier: Apache-2.0
/// @dev Note, we want to use the 0.7.4 version to align with previous deployment.
pragma solidity =0.7.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../utils/GetCode.sol";
import "../utils/BytesLib.sol";

/// @notice The interface for the ITokenRelease contract.
interface ITokenRelease {
    function owner() external returns (address);
    function cliff() external returns (uint256);
    function beneficiary() external returns (address);
}

/// @notice The Fuel v1 interface.
interface IFuel_v1 {
    function commitBlock(uint32,bytes32,uint32,bytes32[] memory) external payable;
    function bondWithdraw(bytes memory) external;
    function operator() external returns (address);
    function commitWitness(bytes32 transactionId) external;
}

/// @notice The control Multisig for the Fuel v1.0 system.
interface IMultisig {
    /// @dev https://github.com/gnosis/MultiSigWallet/blob/master/contracts/MultiSigWallet.sol#L189
    function submitTransaction(address payable destination, uint value, bytes memory data)
        external
        returns (uint transactionId);
}

/// @notice The Fuel v1 Proxy contract bypass.
interface IProxy {
    /// @dev Transact bypass.
    function transact(address payable destination, uint256 value, bytes memory data) external payable;
}

/// @notice The Fuel v1 Optimistic Rollup leader selection.
/// @dev Each producer must create a Release schedule with a minimum amount of locked value.
/// @dev Leader selection is based on a list of releases and incrementation which resets.
contract LeaderSelection {
    // Constants.

    // Minimum required balance a TokenRelease must have to register as a producer.
    uint256 public constant minimumTokens = 32000 ether;

    // ITokenRelease code hash.
    bytes32 public constant releaseBytecodeHash = 0x2a7cfb605ecbaaebee7c515143b57775b198b4b26f09976132e4bed2fc6b1957;

    // ITokenRelease code size.
    uint256 public constant releaseBytecodeSize = 5794;

    // ITokenRelease code size.
    uint256 public constant releaseConstructorSize = 160;

    // The Fuel v1 bond value amount.
    uint256 public constant bondValue = .5 ether;

    // The reset window for leader id selection.
    // Note, each producer gets a 1/4 day to produce if they are the leader.
    uint256 public constant resetWindow = (1 days) / 4;

    // Immutable variables.

    // The Fuel v1 contract address.
    IFuel_v1 public immutable fuel;

    // The Fuel v1 contract address.
    IMultisig public immutable controlMultisig;

    // The Fuel v1 IProxy contract address.
    address public immutable proxy;

    // State variables.

    // The Fuel v2 multisignature wallet address.
    address public multisig;

    // The Fuel v2 DSToken contract address.
    IERC20 public token;

    // The block production leader index.
    uint32 public leaderId;

    // The next producer slot to be registered.
    uint32 public freeId;

    // The last time a new leader was selected.
    uint256 public lastSelected;

    // The total number of block releases registered.
    uint32 public numReleases;

    // The mapping from producer index to their address.
    mapping(uint32 => address) public releases;

    // The mapping from producer address to their index.
    mapping(address => uint32) public ids;

    // The mapping from the release address to block height to Ethereum block to is committed bool.
    mapping(address => mapping(uint256 => mapping(uint256 => bool))) public commitment;

    /// @notice Setup the multisig, fuel contract, initial producer and initial token.
    constructor(
        address initMultisig,
        IFuel_v1 initFuel,
        ITokenRelease initProducer,
        IERC20 initToken,
        IMultisig initControlMultisig
    ) {
        // Setup the constructor immutable variables.
        multisig = initMultisig;
        proxy = initFuel.operator();
        fuel = initFuel;
        token = initToken;
        controlMultisig = initControlMultisig;

        // Register the initial producer.
        register(initProducer);
    }

    /// @dev We want the commitBlock to do all the work for leaderId selection.
    /// @dev Below describes a model where leaderId management is done, checks and commitBlock.
    function commitBlock(
        uint32 minimum,
        bytes32 minimumHash,
        uint32 height,
        bytes32[] calldata roots
    ) payable external {
        // If a new leader needs to be selected.
        if ((block.timestamp - lastSelected) > resetWindow) {
            incrementLeaderId();
        }

        // Set the new leader.
        ITokenRelease release = ITokenRelease(releases[leaderId]);

        // If the leader is expired, skip ahead to the next leader and stop.
        if (block.timestamp >= release.cliff()) {
            // Set the free id to the leader id.
            freeId = leaderId;

            // Increment the leader id.
            incrementLeaderId();

            // Stop the commitment process here.
            return;
        }

        // Require the leader beneficiary is the message sender.
        require(msg.sender == release.beneficiary(), "beneficiary");

        // Require that the transaction has value.
        require(msg.value == bondValue, "bond-value");

        // Create the commit block data to send to the IProxy.
        // @dev https://github.com/FuelLabs/fuel/blob/master/src/Fuel.yulp#L113.
        bytes memory data = abi.encodeWithSelector(
            IFuel_v1.commitBlock.selector,
            minimum,
            minimumHash,
            height,
            roots
        );

        // Send commitBlock data to the IProxy, which will commit the block in Fuel.
        /// @dev no-rentrancy vector, as IProxy is pre-set.
        /// @dev https://github.com/FuelLabs/fuel/blob/master/src/OwnedProxy.yulp#L43
        IProxy(proxy).transact{ value: bondValue }(
            payable(address(fuel)),
            bondValue,
            data
        );

        // Notate commitment.
        commitment[msg.sender][height][block.number] = true;
    }

    /// @dev We want the current block leader to be able to use commitWitness to retrieve root fees.
    /// @dev If the leader doesn't retrieve their fees in their leader window, anyone else can.
    function commitWitness(
        bytes32 transactionId
    ) external {
        // Get the current release leader.
        ITokenRelease release = ITokenRelease(releases[leaderId]);

        // Require the leader beneficiary is the message sender.
        require(msg.sender == release.beneficiary(), "beneficiary");

        // Create the commitWitness data to send to the proxy.
        bytes memory data = abi.encodeWithSelector(
            IFuel_v1.commitWitness.selector,
            transactionId
        );

        // Send the commitWitness data to the proxy.
        IProxy(proxy).transact{ value: 0 }(
            payable(address(fuel)),
            0,
            data
        );
    }

    /// @dev Allow producers to retrieve their bonds.
    function bondWithdraw(
        bytes memory blockHeader
    ) external {
        // The parsed block height from the Block Header.
        address producer = BytesLib.toAddress(blockHeader, 0);

        // The block header producer is the proxy.
        require(producer == proxy, "producer-proxy");

        // The parsed block height from the Block Header.
        uint256 height = BytesLib.toUint256(blockHeader, 20 + 32);

        // The parsed block number from the Block Header.
        uint256 blockNumber = BytesLib.toUint256(blockHeader, 20 + 32 + 32);

        // Require that the commitment has been made.
        require(commitment[msg.sender][height][blockNumber], "block-commitment");

        // Nullify this commitment to ensure re-rentrancy prevention.
        commitment[msg.sender][height][blockNumber] = false;

        // Create the bondwithdraw data to send to the proxy.
        bytes memory data = abi.encodeWithSelector(
            IFuel_v1.bondWithdraw.selector,
            blockHeader
        );

        // Get the pre-proxy balance.
        uint256 preProxyBalance = proxy.balance;

        // Send the bond retrieval data to the proxy contract.
        // Re-entrancy note, if this is tried twice the Fuel v1.0 contract will throw.
        IProxy(proxy).transact{ value: 0 }(
            payable(address(fuel)),
            0,
            data
        );

        // Ensure the proxy balance is exactly bondValue higher after this withdrawal attempt.
        require(proxy.balance == preProxyBalance + bondValue, "bond-value");

        // Empty bytes.
        bytes memory emptyBytes;

        // Build the retrieval data for the proxy.
        bytes memory retrievalData = abi.encodeWithSelector(
            IProxy.transact.selector,
            payable(msg.sender),
            bondValue,
            emptyBytes
        );

        // Use the control multisig to withdraw the funds.
        controlMultisig.submitTransaction(
            payable(proxy),
            0,
            retrievalData
        );
    }

    /// @dev increment new leader id.
    function incrementLeaderId() internal {
        // Increment the leaderId.
        leaderId += 1;

        // Set the last selected timestamp.
        lastSelected = block.timestamp;

        // If leaderId is passed available releases, reset to start.
        if (leaderId >= numReleases) {
            leaderId = 0;
        }
    }

    /// @dev Register a token release contract.
    function register(ITokenRelease release) public {
        // Check the release contract to ensure it's valid.
        check(release);

        // Set producer and release.
        ids[address(release)] = freeId;

        // Set release.
        releases[freeId] = address(release);

        // Increase the number of releases.
        if (freeId == numReleases) {
            numReleases += 1;
        }

        // Reset the freeId to the numReleases.
        freeId = numReleases;
    }

    /// @dev Check that a release contract is the right code, setup and not registered.
    function check(ITokenRelease release) internal {
        // Ensure the release contract address is not empty.
        require(address(release) != address(0), "empty");

        // Get the bytecode of the token release contract in question.
        bytes memory bytecode = GetCode.at(address(release), releaseConstructorSize);

        // Ensure the bytecode for the release contract is the TokenRelease contract bytecode.
        require(keccak256(bytecode) == releaseBytecodeHash, "bytecode-hash");

        // Ensure the code size of the provided third-party contract is the correct TokenRelease contract size.
        require(
            GetCode.sizeAt(address(release)) == (releaseBytecodeSize + releaseConstructorSize),
            "code-length"
        );

        // Check that the owner is either null address (i.e. no owner) or the Fuel multisignature wallet.
        require(release.owner() == address(0)
            || release.owner() == multisig, "owner-check");

        // Ensure the balance of the release contract meets the minimum requirement.
        require(token.balanceOf(address(release)) >= minimumTokens, "minimum");

        // Ensure the release contract has not already been registered.
        require(ids[address(release)] == 0, "id-registered");

        // Ensure the release contract has not already been registered.
        // Need this check since EVM defaults mapping values to 0, so
        // ids[address(release)] == 0 alone doesn't guarantee no prior registration.
        require(releases[0] != address(release), "already-registered");
    }

    /// @notice This will nullify the multisig and give full ownership of Fuel v1 agg. prod. to this contract.
    /// @dev Token releases will no longer allow the Fuel multisig to be registered as the owner.
    function nullifyMultisig() external {
        // Require that the sender is the Fuel multisig.
        require(msg.sender == multisig, "multisig");

        // Nullify the multisig.
        multisig = address(0);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.7.4;

/// @notice Get code library from the Solidity docs.
library GetCode {
    /// @dev Get the size of the contract at a specific address.
    function sizeAt(address _addr) internal view returns (uint256 _size) {
        assembly {
            // retrieve the size of the code, this needs assembly
            _size := extcodesize(_addr)
        }
    }

    /// @dev Source from: https://github.com/ethereum/solidity/blob/v0.7.6/docs/assembly.rst#example
    function at(address _addr, uint256 sizeReduction) internal view returns (bytes memory o_code) {
        assembly {
            // retrieve the size of the code, this needs assembly
            let size := sub(extcodesize(_addr), sizeReduction) 
            // allocate output byte array - this could also be done without assembly
            // by using o_code = new bytes(size)
            o_code := mload(0x40)
            // new "memory end" including padding
            mstore(0x40, add(o_code, and(add(add(size, 0x20), 0x1f), not(0x1f))))
            // store length in memory
            mstore(o_code, size)
            // actually retrieve the code, this needs assembly
            extcodecopy(_addr, add(o_code, 0x20), 0, size)
        }
    }
}

// SPDX-License-Identifier: Unlicense
/*
 * @title Solidity Bytes Arrays Utils
 * @author Gonçalo Sá <[email protected]>
 *
 * @dev Bytes tightly packed arrays utility library for ethereum contracts written in Solidity.
 *      The library lets you concatenate, slice and type cast bytes arrays both in memory and storage.
 */
pragma solidity =0.7.4;


library BytesLib {
    function concat(
        bytes memory _preBytes,
        bytes memory _postBytes
    )
        internal
        pure
        returns (bytes memory)
    {
        bytes memory tempBytes;

        assembly {
            // Get a location of some free memory and store it in tempBytes as
            // Solidity does for memory variables.
            tempBytes := mload(0x40)

            // Store the length of the first bytes array at the beginning of
            // the memory for tempBytes.
            let length := mload(_preBytes)
            mstore(tempBytes, length)

            // Maintain a memory counter for the current write location in the
            // temp bytes array by adding the 32 bytes for the array length to
            // the starting location.
            let mc := add(tempBytes, 0x20)
            // Stop copying when the memory counter reaches the length of the
            // first bytes array.
            let end := add(mc, length)

            for {
                // Initialize a copy counter to the start of the _preBytes data,
                // 32 bytes into its memory.
                let cc := add(_preBytes, 0x20)
            } lt(mc, end) {
                // Increase both counters by 32 bytes each iteration.
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                // Write the _preBytes data into the tempBytes memory 32 bytes
                // at a time.
                mstore(mc, mload(cc))
            }

            // Add the length of _postBytes to the current length of tempBytes
            // and store it as the new length in the first 32 bytes of the
            // tempBytes memory.
            length := mload(_postBytes)
            mstore(tempBytes, add(length, mload(tempBytes)))

            // Move the memory counter back from a multiple of 0x20 to the
            // actual end of the _preBytes data.
            mc := end
            // Stop copying when the memory counter reaches the new combined
            // length of the arrays.
            end := add(mc, length)

            for {
                let cc := add(_postBytes, 0x20)
            } lt(mc, end) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                mstore(mc, mload(cc))
            }

            // Update the free-memory pointer by padding our last write location
            // to 32 bytes: add 31 bytes to the end of tempBytes to move to the
            // next 32 byte block, then round down to the nearest multiple of
            // 32. If the sum of the length of the two arrays is zero then add
            // one before rounding down to leave a blank 32 bytes (the length block with 0).
            mstore(0x40, and(
              add(add(end, iszero(add(length, mload(_preBytes)))), 31),
              not(31) // Round down to the nearest 32 bytes.
            ))
        }

        return tempBytes;
    }

    function slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    )
        internal
        pure
        returns (bytes memory)
    {
        require(_length + 31 >= _length, "slice_overflow");
        require(_start + _length >= _start, "slice_overflow");
        require(_bytes.length >= _start + _length, "slice_outOfBounds");

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
                // Get a location of some free memory and store it in tempBytes as
                // Solidity does for memory variables.
                tempBytes := mload(0x40)

                // The first word of the slice result is potentially a partial
                // word read from the original array. To read it, we calculate
                // the length of that partial word and start copying that many
                // bytes into the array. The first word we copy will start with
                // data we don't care about, but the last `lengthmod` bytes will
                // land at the beginning of the contents of the new array. When
                // we're done copying, we overwrite the full first word with
                // the actual length of the slice.
                let lengthmod := and(_length, 31)

                // The multiplication in the next line is necessary
                // because when slicing multiples of 32 bytes (lengthmod == 0)
                // the following copy loop was copying the origin's length
                // and then ending prematurely not copying everything it should.
                let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                let end := add(mc, _length)

                for {
                    // The multiplication in the next line has the same exact purpose
                    // as the one above.
                    let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, _length)

                //update free-memory pointer
                //allocating the array padded to 32 bytes like the compiler does now
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            //if we want a zero-length slice let's just return a zero-length array
            default {
                tempBytes := mload(0x40)
                //zero out the 32 bytes slice we are about to return
                //we need to do it because Solidity does not garbage collect
                mstore(tempBytes, 0)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }

    function toAddress(bytes memory _bytes, uint256 _start) internal pure returns (address) {
        require(_start + 20 >= _start, "toAddress_overflow");
        require(_bytes.length >= _start + 20, "toAddress_outOfBounds");
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }

    function toUint8(bytes memory _bytes, uint256 _start) internal pure returns (uint8) {
        require(_start + 1 >= _start, "toUint8_overflow");
        require(_bytes.length >= _start + 1 , "toUint8_outOfBounds");
        uint8 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x1), _start))
        }

        return tempUint;
    }

    function toUint16(bytes memory _bytes, uint256 _start) internal pure returns (uint16) {
        require(_start + 2 >= _start, "toUint16_overflow");
        require(_bytes.length >= _start + 2, "toUint16_outOfBounds");
        uint16 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x2), _start))
        }

        return tempUint;
    }

    function toUint32(bytes memory _bytes, uint256 _start) internal pure returns (uint32) {
        require(_start + 4 >= _start, "toUint32_overflow");
        require(_bytes.length >= _start + 4, "toUint32_outOfBounds");
        uint32 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x4), _start))
        }

        return tempUint;
    }

    function toUint64(bytes memory _bytes, uint256 _start) internal pure returns (uint64) {
        require(_start + 8 >= _start, "toUint64_overflow");
        require(_bytes.length >= _start + 8, "toUint64_outOfBounds");
        uint64 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x8), _start))
        }

        return tempUint;
    }

    function toUint96(bytes memory _bytes, uint256 _start) internal pure returns (uint96) {
        require(_start + 12 >= _start, "toUint96_overflow");
        require(_bytes.length >= _start + 12, "toUint96_outOfBounds");
        uint96 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0xc), _start))
        }

        return tempUint;
    }

    function toUint128(bytes memory _bytes, uint256 _start) internal pure returns (uint128) {
        require(_start + 16 >= _start, "toUint128_overflow");
        require(_bytes.length >= _start + 16, "toUint128_outOfBounds");
        uint128 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x10), _start))
        }

        return tempUint;
    }

    function toUint256(bytes memory _bytes, uint256 _start) internal pure returns (uint256) {
        require(_start + 32 >= _start, "toUint256_overflow");
        require(_bytes.length >= _start + 32, "toUint256_outOfBounds");
        uint256 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x20), _start))
        }

        return tempUint;
    }

    function toBytes32(bytes memory _bytes, uint256 _start) internal pure returns (bytes32) {
        require(_start + 32 >= _start, "toBytes32_overflow");
        require(_bytes.length >= _start + 32, "toBytes32_outOfBounds");
        bytes32 tempBytes32;

        assembly {
            tempBytes32 := mload(add(add(_bytes, 0x20), _start))
        }

        return tempBytes32;
    }

    function equal(bytes memory _preBytes, bytes memory _postBytes) internal pure returns (bool) {
        bool success = true;

        assembly {
            let length := mload(_preBytes)

            // if lengths don't match the arrays are not equal
            switch eq(length, mload(_postBytes))
            case 1 {
                // cb is a circuit breaker in the for loop since there's
                //  no said feature for inline assembly loops
                // cb = 1 - don't breaker
                // cb = 0 - break
                let cb := 1

                let mc := add(_preBytes, 0x20)
                let end := add(mc, length)

                for {
                    let cc := add(_postBytes, 0x20)
                // the next line is the loop condition:
                // while(uint256(mc < end) + cb == 2)
                } eq(add(lt(mc, end), cb), 2) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    // if any of these checks fails then arrays are not equal
                    if iszero(eq(mload(mc), mload(cc))) {
                        // unsuccess:
                        success := 0
                        cb := 0
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }
}