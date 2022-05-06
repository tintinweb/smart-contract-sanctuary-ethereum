// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.13;

import {VestingModule} from "./VestingModule.sol";
import {ClonesWithImmutableArgs} from "clones-with-immutable-args/ClonesWithImmutableArgs.sol";

///
/// @title VestingModuleFactory
/// @author 0xSplits <[email protected]>
/// @notice  A factory contract for cheaply deploying VestingModules.
/// @dev This factory uses our own extension of clones-with-immutable-args to avoid
/// `DELEGATECALL` inside `receive()` to accept hard gas-capped `sends` & `transfers`
/// for maximum backwards composability.
///
contract VestingModuleFactory {
    /// -----------------------------------------------------------------------
    /// errors
    /// -----------------------------------------------------------------------

    error InvalidBeneficiary();
    error InvalidVestingPeriod();

    /// -----------------------------------------------------------------------
    /// libraries
    /// -----------------------------------------------------------------------

    using ClonesWithImmutableArgs for address;

    /// -----------------------------------------------------------------------
    /// events
    /// -----------------------------------------------------------------------

    /// @notice New vesting integration contract deployed
    /// @param vestingModule Address of newly created VestingModule clone
    /// @param beneficiary Address to receive funds after vesting
    /// @param vestingPeriod Period of time for funds to vest
    event CreateVestingModule(
        address indexed vestingModule,
        address indexed beneficiary,
        uint256 vestingPeriod
    );

    /// -----------------------------------------------------------------------
    /// storage
    /// -----------------------------------------------------------------------

    VestingModule public implementation;

    /// -----------------------------------------------------------------------
    /// constructor
    /// -----------------------------------------------------------------------

    constructor() {
        implementation = new VestingModule();
    }

    /// -----------------------------------------------------------------------
    /// functions
    /// -----------------------------------------------------------------------

    /// -----------------------------------------------------------------------
    /// functions - public & external
    /// -----------------------------------------------------------------------

    /// @notice Creates new vesting module
    /// @param beneficiary Address to receive funds after vesting
    /// @param vestingPeriod Period of time for funds to vest
    /// @return vm Address of new vesting module
    function createVestingModule(address beneficiary, uint256 vestingPeriod)
        external
        returns (VestingModule vm)
    {
        /// checks
        if (beneficiary == address(0)) revert InvalidBeneficiary();
        if (vestingPeriod == 0) revert InvalidVestingPeriod();

        /// effects
        bytes memory data = abi.encodePacked(beneficiary, vestingPeriod);
        vm = VestingModule(
            address(implementation).cloneDeterministic(
                bytes32(bytes20(beneficiary)),
                data
            )
        );
        emit CreateVestingModule(address(vm), beneficiary, vestingPeriod);
    }

    /// -----------------------------------------------------------------------
    /// functions - views
    /// -----------------------------------------------------------------------

    /// @notice Predicts address of vesting module & returns whether it already exists
    /// @dev Will return (address(0), false) instead of reverting on invalid inputs
    /// @param beneficiary Address to receive funds after vesting
    /// @param vestingPeriod Period of time for funds to vest
    /// @return predictedAddress Predicted address of new vesting module
    /// @return exists Whether a vesting module already exists at {predictedAddress}
    function predictVestingModuleAddress(
        address beneficiary,
        uint256 vestingPeriod
    ) external view returns (address predictedAddress, bool exists) {
        // TODO: decide if view should revert; leaning toward no
        /// checks
        /* if (beneficiary == address(0)) revert InvalidBeneficiary(); */
        /* if (vestingPeriod == 0) revert InvalidVestingPeriod(); */
        if (beneficiary == address(0) || vestingPeriod == 0)
            return (address(0), false);

        bytes memory data = abi.encodePacked(beneficiary, vestingPeriod);
        (predictedAddress, exists) = address(implementation)
            .predictDeterministicAddress(bytes32(bytes20(beneficiary)), data);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.13;

import {Clone} from "clones-with-immutable-args/Clone.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {FullMath} from "./lib/FullMath.sol";

///
/// @title VestingModule
/// @author 0xSplits <[email protected]>
/// @notice A maximally-composable vesting contract allowing multiple isolated
/// streams of different tokens to reach a beneficiary over time. Streams share
/// a vesting period but may begin or have funds released independently.
/// @dev Funds pile up in the contract via `receive()` & simple ERC20 `transfer`
/// until a caller creates a new vesting stream. The funds then vest linearly
/// over {vestingPeriod} and may be withdrawn accordingly by anyone on behalf
/// of the {beneficiary}. There is no limit on the number of simultaneous
/// vesting streams which may be created, ongoing or withdrawn from in a single
/// tx.
/// This contract uses address(0) in some fns/events/mappings to refer to ETH.
///
contract VestingModule is Clone {
    /// -----------------------------------------------------------------------
    /// errors
    /// -----------------------------------------------------------------------

    error InvalidVestingStreamId(uint256 id);

    /// -----------------------------------------------------------------------
    /// libraries
    /// -----------------------------------------------------------------------

    using SafeTransferLib for address;
    using SafeTransferLib for ERC20;

    /// -----------------------------------------------------------------------
    /// events
    /// -----------------------------------------------------------------------

    /// @notice New vesting stream created
    /// @param id Id of vesting stream
    /// @param token Address of token to vest (0x0 for ETH)
    /// @param amount Amount to vest
    event CreateVestingStream(
        uint256 indexed id,
        address indexed token,
        uint256 amount
    );

    /// @notice Release from vesting stream
    /// @param id Id of vesting stream
    /// @param amount Amount released from stream
    event ReleaseFromVestingStream(uint256 indexed id, uint256 amount);

    /// @notice Emitted after each successful ETH transfer to proxy
    /// @param amount Amount of ETH received
    event ReceiveETH(uint256 amount);

    /// -----------------------------------------------------------------------
    /// structs
    /// -----------------------------------------------------------------------

    /// @notice holds vesting stream metadata
    struct VestingStream {
        address token;
        uint256 vestingStart;
        uint256 total;
        uint256 released;
    }

    /// -----------------------------------------------------------------------
    /// storage
    /// -----------------------------------------------------------------------

    /// Address to receive funds after vesting
    /// @dev equivalent to address public immutable beneficiary;
    function beneficiary() public pure returns (address) {
        return _getArgAddress(0);
    }

    /// Period of time for funds to vest (defaults to 365 days)
    /// @dev equivalent to uint256 public immutable vestingPeriod;
    function vestingPeriod() public pure returns (uint256) {
        return _getArgUint256(20);
    }

    /// Number of vesting streams
    /// @dev Used for sequential ids
    uint256 public numVestingStreams;

    /// Mapping from Id to vesting stream
    mapping(uint256 => VestingStream) internal vestingStreams;
    /// Mapping from token to amount vesting (includes current & previous)
    mapping(address => uint256) public vesting;
    /// Mapping from token to amount released
    mapping(address => uint256) public released;

    /// -----------------------------------------------------------------------
    /// constructor
    /// -----------------------------------------------------------------------

    // solhint-disable-next-line no-empty-blocks
    constructor() {}

    /// -----------------------------------------------------------------------
    /// functions
    /// -----------------------------------------------------------------------

    /// -----------------------------------------------------------------------
    /// functions - public & external
    /// -----------------------------------------------------------------------

    /// @notice receive ETH
    /// @dev receive with emitted event is implemented w/i clone bytecode
    /* receive() external payable { */
    /*     emit ReceiveETH(msg.value); */
    /* } */

    /// @notice Creates new vesting streams
    /// @param tokens Addresses of ETH (0x0) & ERC20s to begin vesting
    /// @return ids Ids of created vesting streams for {tokens}
    function createVestingStreams(address[] calldata tokens)
        external
        payable
        returns (uint256[] memory ids)
    {
        uint256 numTokens = tokens.length;
        ids = new uint256[](numTokens);
        // use count as first new sequential id
        uint256 vestingStreamId = numVestingStreams;

        unchecked {
            // overflow should be impossible in for-loop index
            for (uint256 i = 0; i < numTokens; ++i) {
                address token = tokens[i];
                // overflow should be impossible
                // shouldn't need to worry about re-entrancy from ERC20 view fn
                // recognizes 0x0 as ETH
                // user chooses tokens array, pernicious ERC20 can't cause DoS
                // slither-disable-next-line calls-loop
                uint256 pendingAmount = (
                    token != address(0)
                        ? ERC20(token).balanceOf(address(this))
                        : address(this).balance
                    // vesting >= released
                ) - (vesting[token] - released[token]);
                vesting[token] += pendingAmount;
                // overflow should be impossible
                vestingStreams[vestingStreamId] = VestingStream({
                    token: token,
                    vestingStart: block.timestamp, // solhint-disable-line not-rely-on-time
                    total: pendingAmount,
                    released: 0
                });
                emit CreateVestingStream(vestingStreamId, token, pendingAmount);
                ids[i] = vestingStreamId;
                ++vestingStreamId;
            }
            // use last created id as new count
            numVestingStreams = vestingStreamId;
        }
    }

    /// @notice Releases vested funds to the beneficiary
    /// @param ids Ids of vesting streams to release funds from
    /// @return releasedFunds Amounts of funds released from vesting streams {ids}
    function releaseFromVesting(uint256[] calldata ids)
        external
        payable
        returns (uint256[] memory releasedFunds)
    {
        uint256 numIds = ids.length;
        releasedFunds = new uint256[](numIds);

        unchecked {
            // overflow should be impossible in for-loop index
            for (uint256 i = 0; i < numIds; ++i) {
                uint256 id = ids[i];
                if (id >= numVestingStreams) revert InvalidVestingStreamId(id);
                VestingStream memory vs = vestingStreams[id];
                uint256 transferAmount = _vestedAndUnreleased(vs);
                address token = vs.token;
                // overflow should be impossible
                vestingStreams[id].released += transferAmount;
                // overflow should be impossible
                released[token] += transferAmount;
                // don't need to worry about re-entrancy; funds can't be stolen from beneficiary
                // pernicious ERC20s would only mess their own storage, not brick the balance of any ERC20 or ETH
                if (token != address(0)) {
                    ERC20(token).safeTransfer(beneficiary(), transferAmount);
                } else {
                    beneficiary().safeTransferETH(transferAmount);
                }

                emit ReleaseFromVestingStream(id, transferAmount);
                releasedFunds[i] = transferAmount;
            }
        }
    }

    /// -----------------------------------------------------------------------
    /// functions - views
    /// -----------------------------------------------------------------------

    /// @notice View vesting stream {id}
    /// @param id Id of vesting stream to view
    /// @return vs Vesting stream
    function vestingStream(uint256 id)
        external
        view
        returns (VestingStream memory vs)
    {
        vs = vestingStreams[id];
    }

    /// @notice View vested amount in vesting stream {id}
    /// @param id Id of vesting stream to get vested amount of
    /// @return Amount vested in vesting stream {id}
    function vested(uint256 id) external view returns (uint256) {
        VestingStream memory vs = vestingStreams[id];
        return _vested(vs);
    }

    /// @notice View vested-and-unreleased amount in vesting stream {id}
    /// @param id Id of vesting stream to get vested-and-unreleased amount of
    /// @return Amount vested-and-unreleased in vesting stream {id}
    function vestedAndUnreleased(uint256 id) external view returns (uint256) {
        VestingStream memory vs = vestingStreams[id];
        return _vestedAndUnreleased(vs);
    }

    /// -----------------------------------------------------------------------
    /// functions - private & internal
    /// -----------------------------------------------------------------------

    /// @notice View vested amount in vesting stream {vs}
    /// @param vs Vesting stream to get vested amount of
    /// @return Amount vested in vesting stream {vs}
    function _vested(VestingStream memory vs) internal view returns (uint256) {
        uint256 elapsedTime;
        unchecked {
            // block.timestamp >= vs.vestingStart for any existing stream
            // solhint-disable-next-line not-rely-on-time
            elapsedTime = block.timestamp - vs.vestingStart;
        }
        return
            elapsedTime >= vestingPeriod()
                ? vs.total
                : FullMath.mulDiv(vs.total, elapsedTime, vestingPeriod());
    }

    /// @notice View vested-and-unreleased amount in vesting stream {vs}
    /// @param vs Vesting stream to get vested-and-unreleased amount of
    /// @return Amount vested-and-unreleased in vesting stream {vs}
    function _vestedAndUnreleased(VestingStream memory vs)
        internal
        view
        returns (uint256)
    {
        unchecked {
            // underflow should be impossible
            return _vested(vs) - vs.released;
        }
    }
}

// SPDX-License-Identifier: BSD

pragma solidity ^0.8.4;

/// @title ClonesWithImmutableArgs
/// @author wighawag, zefram.eth
/// @notice Enables creating clone contracts with immutable args
/// @dev extended by [email protected] to add receive() without DELEGECALL & create2 support
/// (h/t WyseNynja https://github.com/wighawag/clones-with-immutable-args/issues/4)
library ClonesWithImmutableArgs {
    error CreateFail();

    /// @notice Creates a clone proxy of the implementation contract with immutable args
    /// @dev data cannot exceed 65535 bytes, since 2 bytes are used to store the data length
    /// @param implementation The implementation contract to clone
    /// @param data Encoded immutable args
    /// @return ptr The ptr to the clone's bytecode
    /// @return creationSize The size of the clone to be created
    function cloneCreationCode(address implementation, bytes memory data)
        internal
        pure
        returns (uint256 ptr, uint256 creationSize)
    {
        // unrealistic for memory ptr or data length to exceed 256 bits
        unchecked {
            uint256 extraLength = data.length + 2; // +2 bytes for telling how much data there is appended to the call
            creationSize = 0x71 + extraLength;
            uint256 runSize = creationSize - 10;
            uint256 dataPtr;
            // solhint-disable-next-line no-inline-assembly
            assembly {
                ptr := mload(0x40)

                // -------------------------------------------------------------------------------------------------------------
                // CREATION (10 bytes)
                // -------------------------------------------------------------------------------------------------------------

                // 61 runtime  | PUSH2 runtime (r)     | r                       | –
                mstore(
                    ptr,
                    0x6100000000000000000000000000000000000000000000000000000000000000
                )
                mstore(add(ptr, 0x01), shl(240, runSize)) // size of the contract running bytecode (16 bits)

                // creation size = 0a
                // 3d          | RETURNDATASIZE        | 0 r                     | –
                // 81          | DUP2                  | r 0 r                   | –
                // 60 creation | PUSH1 creation (c)    | c r 0 r                 | –
                // 3d          | RETURNDATASIZE        | 0 c r 0 r               | –
                // 39          | CODECOPY              | 0 r                     | [0-runSize): runtime code
                // f3          | RETURN                |                         | [0-runSize): runtime code

                // -------------------------------------------------------------------------------------------------------------
                // RUNTIME (103 bytes + extraLength)
                // -------------------------------------------------------------------------------------------------------------

                //     0x000     36       calldatasize      cds                  | -
                //     0x001     602f     push1 0x2f        0x2f cds             | -
                // ,=< 0x003     57       jumpi                                  | -
                // |   0x004     34       callvalue         cv                   | -
                // |   0x005     3d       returndatasize    0 cv                 | -
                // |   0x006     52       mstore                                 | [0, 0x20) = cv
                // |   0x007     7f245c.. push32 0x245c..   id                   | [0, 0x20) = cv
                // |   0x028     6020     push1 0x20        0x20 id              | [0, 0x20) = cv
                // |   0x02a     3d       returndatasize    0 0x20 id            | [0, 0x20) = cv
                // |   0x02b     a1       log1                                   | [0, 0x20) = cv
                // |   0x02c     3d       returndatasize    0                    | [0, 0x20) = cv
                // |   0x02d     3d       returndatasize    0 0                  | [0, 0x20) = cv
                // |   0x02e     f3       return
                // `-> 0x02f     5b       jumpdest

                // 3d          | RETURNDATASIZE        | 0                       | –
                // 3d          | RETURNDATASIZE        | 0 0                     | –
                // 3d          | RETURNDATASIZE        | 0 0 0                   | –
                // 3d          | RETURNDATASIZE        | 0 0 0 0                 | –
                // 36          | CALLDATASIZE          | cds 0 0 0 0             | –
                // 3d          | RETURNDATASIZE        | 0 cds 0 0 0 0           | –
                // 3d          | RETURNDATASIZE        | 0 0 cds 0 0 0 0         | –
                // 37          | CALLDATACOPY          | 0 0 0 0                 | [0, cds) = calldata
                // 61          | PUSH2 extra           | extra 0 0 0 0           | [0, cds) = calldata
                mstore(
                    add(ptr, 0x03),
                    0x3d81600a3d39f336602f57343d527f0000000000000000000000000000000000
                )
                mstore(
                    add(ptr, 0x12),
                    // = keccak256("ReceiveETH(uint256)")
                    0x9e4ac34f21c619cefc926c8bd93b54bf5a39c7ab2127a895af1cc0691d7e3dff
                )
                mstore(
                    add(ptr, 0x32),
                    0x60203da13d3df35b3d3d3d3d363d3d3761000000000000000000000000000000
                )
                mstore(add(ptr, 0x43), shl(240, extraLength))

                // 60 0x67     | PUSH1 0x67            | 0x67 extra 0 0 0 0      | [0, cds) = calldata // 0x67 (103) is runtime size - data
                // 36          | CALLDATASIZE          | cds 0x67 extra 0 0 0 0  | [0, cds) = calldata
                // 39          | CODECOPY              | 0 0 0 0                 | [0, cds) = calldata, [cds, cds+0x37) = extraData
                // 36          | CALLDATASIZE          | cds 0 0 0 0             | [0, cds) = calldata, [cds, cds+0x37) = extraData
                // 61 extra    | PUSH2 extra           | extra cds 0 0 0 0       | [0, cds) = calldata, [cds, cds+0x37) = extraData
                mstore(
                    add(ptr, 0x45),
                    0x6067363936610000000000000000000000000000000000000000000000000000
                )
                mstore(add(ptr, 0x4b), shl(240, extraLength))

                // 01          | ADD                   | cds+extra 0 0 0 0       | [0, cds) = calldata, [cds, cds+0x37) = extraData
                // 3d          | RETURNDATASIZE        | 0 cds 0 0 0 0           | [0, cds) = calldata, [cds, cds+0x37) = extraData
                // 73 addr     | PUSH20 0x123…         | addr 0 cds 0 0 0 0      | [0, cds) = calldata, [cds, cds+0x37) = extraData
                mstore(
                    add(ptr, 0x4d),
                    0x013d730000000000000000000000000000000000000000000000000000000000
                )
                mstore(add(ptr, 0x50), shl(0x60, implementation))

                // 5a          | GAS                   | gas addr 0 cds 0 0 0 0  | [0, cds) = calldata, [cds, cds+0x37) = extraData
                // f4          | DELEGATECALL          | success 0 0             | [0, cds) = calldata, [cds, cds+0x37) = extraData
                // 3d          | RETURNDATASIZE        | rds success 0 0         | [0, cds) = calldata, [cds, cds+0x37) = extraData
                // 3d          | RETURNDATASIZE        | rds rds success 0 0     | [0, cds) = calldata, [cds, cds+0x37) = extraData
                // 93          | SWAP4                 | 0 rds success 0 rds     | [0, cds) = calldata, [cds, cds+0x37) = extraData
                // 80          | DUP1                  | 0 0 rds success 0 rds   | [0, cds) = calldata, [cds, cds+0x37) = extraData
                // 3e          | RETURNDATACOPY        | success 0 rds           | [0, rds) = return data (there might be some irrelevant leftovers in memory [rds, cds+0x37) when rds < cds+0x37)
                // 60 0x65     | PUSH1 0x65            | 0x65 sucess 0 rds       | [0, rds) = return data
                // 57          | JUMPI                 | 0 rds                   | [0, rds) = return data
                // fd          | REVERT                | –                       | [0, rds) = return data
                // 5b          | JUMPDEST              | 0 rds                   | [0, rds) = return data
                // f3          | RETURN                | –                       | [0, rds) = return data
                mstore(
                    add(ptr, 0x64),
                    0x5af43d3d93803e606557fd5bf300000000000000000000000000000000000000
                )
            }

            // -------------------------------------------------------------------------------------------------------------
            // APPENDED DATA (Accessible from extcodecopy)
            // (but also send as appended data to the delegatecall)
            // -------------------------------------------------------------------------------------------------------------

            extraLength -= 2;
            uint256 counter = extraLength;
            uint256 copyPtr = ptr + 0x71;
            // solhint-disable-next-line no-inline-assembly
            assembly {
                dataPtr := add(data, 32)
            }
            for (; counter >= 32; counter -= 32) {
                // solhint-disable-next-line no-inline-assembly
                assembly {
                    mstore(copyPtr, mload(dataPtr))
                }

                copyPtr += 32;
                dataPtr += 32;
            }
            uint256 mask = ~(256**(32 - counter) - 1);
            // solhint-disable-next-line no-inline-assembly
            assembly {
                mstore(copyPtr, and(mload(dataPtr), mask))
            }
            copyPtr += counter;
            // solhint-disable-next-line no-inline-assembly
            assembly {
                mstore(copyPtr, shl(240, extraLength))
            }
        }
    }

    /// @notice Creates a clone proxy of the implementation contract with immutable args
    /// @dev data cannot exceed 65535 bytes, since 2 bytes are used to store the data length
    /// @param implementation The implementation contract to clone
    /// @param data Encoded immutable args
    /// @return instance The address of the created clone
    function clone(address implementation, bytes memory data)
        internal
        returns (address payable instance)
    {
        (uint256 creationPtr, uint256 creationSize) = cloneCreationCode(
            implementation,
            data
        );

        // solhint-disable-next-line no-inline-assembly
        assembly {
            instance := create(0, creationPtr, creationSize)
        }

        // if the create failed, the instance address won't be set
        if (instance == address(0)) {
            revert CreateFail();
        }
    }

    /// @notice Creates a clone proxy of the implementation contract with immutable args
    /// @dev data cannot exceed 65535 bytes, since 2 bytes are used to store the data length
    /// @param implementation The implementation contract to clone
    /// @param salt The salt for create2
    /// @param data Encoded immutable args
    /// @return instance The address of the created clone
    function cloneDeterministic(
        address implementation,
        bytes32 salt,
        bytes memory data
    ) internal returns (address payable instance) {
        (uint256 creationPtr, uint256 creationSize) = cloneCreationCode(
            implementation,
            data
        );

        // solhint-disable-next-line no-inline-assembly
        assembly {
            instance := create2(0, creationPtr, creationSize, salt)
        }

        // if the create failed, the instance address won't be set
        if (instance == address(0)) {
            revert CreateFail();
        }
    }

    /// @notice Predicts the address where a deterministic clone of implementation will be deployed
    /// @dev data cannot exceed 65535 bytes, since 2 bytes are used to store the data length
    /// @param implementation The implementation contract to clone
    /// @param salt The salt for create2
    /// @param data Encoded immutable args
    /// @return predicted The predicted address of the created clone
    /// @return exists Whether the clone already exists
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        bytes memory data
    ) internal view returns (address predicted, bool exists) {
        (uint256 creationPtr, uint256 creationSize) = cloneCreationCode(
            implementation,
            data
        );

        bytes32 creationHash;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            creationHash := keccak256(creationPtr, creationSize)
        }

        predicted = computeAddress(salt, creationHash, address(this));
        exists = predicted.code.length > 0;
    }

    /// @dev Returns the address where a contract will be stored if deployed via CREATE2 from a contract located at `deployer`.
    function computeAddress(
        bytes32 salt,
        bytes32 bytecodeHash,
        address deployer
    ) internal pure returns (address) {
        bytes32 _data = keccak256(
            abi.encodePacked(bytes1(0xff), deployer, salt, bytecodeHash)
        );
        return address(uint160(uint256(_data)));
    }
}

// SPDX-License-Identifier: BSD
pragma solidity ^0.8.4;

/// @title Clone
/// @author zefram.eth
/// @notice Provides helper functions for reading immutable args from calldata
contract Clone {
    /// @notice Reads an immutable arg with type address
    /// @param argOffset The offset of the arg in the packed data
    /// @return arg The arg value
    function _getArgAddress(uint256 argOffset)
        internal
        pure
        returns (address arg)
    {
        uint256 offset = _getImmutableArgsOffset();
        // solhint-disable-next-line no-inline-assembly
        assembly {
            arg := shr(0x60, calldataload(add(offset, argOffset)))
        }
    }

    /// @notice Reads an immutable arg with type uint256
    /// @param argOffset The offset of the arg in the packed data
    /// @return arg The arg value
    function _getArgUint256(uint256 argOffset)
        internal
        pure
        returns (uint256 arg)
    {
        uint256 offset = _getImmutableArgsOffset();
        // solhint-disable-next-line no-inline-assembly
        assembly {
            arg := calldataload(add(offset, argOffset))
        }
    }

    /// @notice Reads a uint256 array stored in the immutable args.
    /// @param argOffset The offset of the arg in the packed data
    /// @param arrLen Number of elements in the array
    /// @return arr The array
    function _getArgUint256Array(uint256 argOffset, uint64 arrLen)
        internal
        pure
        returns (uint256[] memory arr)
    {
        uint256 offset = _getImmutableArgsOffset();
        uint256 el;
        arr = new uint256[](arrLen);
        for (uint64 i = 0; i < arrLen; i++) {
            // solhint-disable-next-line no-inline-assembly
            assembly {
                el := calldataload(add(add(offset, argOffset), mul(i, 32)))
            }
            arr[i] = el;
        }
        return arr;
    }

    /// @notice Reads an immutable arg with type uint64
    /// @param argOffset The offset of the arg in the packed data
    /// @return arg The arg value
    function _getArgUint64(uint256 argOffset)
        internal
        pure
        returns (uint64 arg)
    {
        uint256 offset = _getImmutableArgsOffset();
        // solhint-disable-next-line no-inline-assembly
        assembly {
            arg := shr(0xc0, calldataload(add(offset, argOffset)))
        }
    }

    /// @notice Reads an immutable arg with type uint8
    /// @param argOffset The offset of the arg in the packed data
    /// @return arg The arg value
    function _getArgUint8(uint256 argOffset) internal pure returns (uint8 arg) {
        uint256 offset = _getImmutableArgsOffset();
        // solhint-disable-next-line no-inline-assembly
        assembly {
            arg := shr(0xf8, calldataload(add(offset, argOffset)))
        }
    }

    /// @return offset The offset of the packed immutable args in calldata
    function _getImmutableArgsOffset() internal pure returns (uint256 offset) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            offset := sub(
                calldatasize(),
                add(shr(240, calldataload(sub(calldatasize(), 2))), 2)
            )
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20} from "../tokens/ERC20.sol";

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
/// @dev Note that none of the functions in this library check that a token has code at all! That responsibility is delegated to the caller.
library SafeTransferLib {
    event Debug(bool one, bool two, uint256 retsize);

    /*//////////////////////////////////////////////////////////////
                             ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool success;

        assembly {
            // Transfer the ETH and store if it succeeded or not.
            success := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(success, "ETH_TRANSFER_FAILED");
    }

    /*//////////////////////////////////////////////////////////////
                            ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), from) // Append the "from" argument.
            mstore(add(freeMemoryPointer, 36), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 100 because the length of our calldata totals up like so: 4 + 32 * 3.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 100, 0, 32)
            )
        }

        require(success, "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "TRANSFER_FAILED");
    }

    function safeApprove(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "APPROVE_FAILED");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
/// from https://github.com/ZeframLou/vested-erc20/blob/main/src/lib/FullMath.sol
library FullMath {
    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = a * b
            // Compute the product mod 2**256 and mod 2**256 - 1
            // then use the Chinese Remainder Theorem to reconstruct
            // the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2**256 + prod0
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(a, b, not(0))
                prod0 := mul(a, b)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division
            if (prod1 == 0) {
                require(denominator > 0);
                assembly {
                    result := div(prod0, denominator)
                }
                return result;
            }

            // Make sure the result is less than 2**256.
            // Also prevents denominator == 0
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0]
            // Compute remainder using mulmod
            uint256 remainder;
            assembly {
                remainder := mulmod(a, b, denominator)
            }
            // Subtract 256 bit number from 512 bit number
            assembly {
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator
            // Compute largest power of two divisor of denominator.
            // Always >= 1.
            uint256 twos = (type(uint256).max - denominator + 1) & denominator;
            // Divide denominator by power of two
            assembly {
                denominator := div(denominator, twos)
            }

            // Divide [prod1 prod0] by the factors of two
            assembly {
                prod0 := div(prod0, twos)
            }
            // Shift in bits from prod1 into prod0. For this we need
            // to flip `twos` such that it is 2**256 / twos.
            // If twos is zero, then it becomes one
            assembly {
                twos := add(div(sub(0, twos), twos), 1)
            }
            prod0 |= prod1 * twos;

            // Invert denominator mod 2**256
            // Now that denominator is an odd number, it has an inverse
            // modulo 2**256 such that denominator * inv = 1 mod 2**256.
            // Compute the inverse by starting with a seed that is correct
            // correct for four bits. That is, denominator * inv = 1 mod 2**4
            uint256 inv = (3 * denominator) ^ 2;
            // Now use Newton-Raphson iteration to improve the precision.
            // Thanks to Hensel's lifting lemma, this also works in modular
            // arithmetic, doubling the correct bits in each step.
            inv *= 2 - denominator * inv; // inverse mod 2**8
            inv *= 2 - denominator * inv; // inverse mod 2**16
            inv *= 2 - denominator * inv; // inverse mod 2**32
            inv *= 2 - denominator * inv; // inverse mod 2**64
            inv *= 2 - denominator * inv; // inverse mod 2**128
            inv *= 2 - denominator * inv; // inverse mod 2**256

            // Because the division is now exact we can divide by multiplying
            // with the modular inverse of denominator. This will give us the
            // correct result modulo 2**256. Since the precoditions guarantee
            // that the outcome is less than 2**256, this is the final result.
            // We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inv;
            return result;
        }
    }

    /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    function mulDivRoundingUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        result = mulDiv(a, b, denominator);
        unchecked {
            if (mulmod(a, b, denominator) > 0) {
                require(result < type(uint256).max);
                result++;
            }
        }
    }
}