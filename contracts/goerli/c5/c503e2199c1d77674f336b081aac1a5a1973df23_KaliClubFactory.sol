// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.4;

/// @dev Contracts
import {
    Call, 
    Multicall, 
    KaliClub
} from "./KaliClub.sol";

/// @dev Libraries
import {ClonesWithImmutableArgs} from "./libraries/ClonesWithImmutableArgs.sol";

/// @notice Kali Club Factory
contract KaliClubFactory is Multicall {
    /// -----------------------------------------------------------------------
    /// LIBRARY USAGE
    /// -----------------------------------------------------------------------

    using ClonesWithImmutableArgs for address;

    /// -----------------------------------------------------------------------
    /// EVENTS
    /// -----------------------------------------------------------------------

    event ClubDeployed(
        Call[] calls,
        address[] signers,
        uint256 threshold,
        bytes32 name
    );

    /// -----------------------------------------------------------------------
    /// IMMUTABLES
    /// -----------------------------------------------------------------------
    
    KaliClub internal immutable clubMaster;

    /// -----------------------------------------------------------------------
    /// CONSTRUCTOR
    /// -----------------------------------------------------------------------

    constructor(KaliClub _clubMaster) payable {
        clubMaster = _clubMaster;
    }

    /// -----------------------------------------------------------------------
    /// DEPLOYMENT LOGIC
    /// -----------------------------------------------------------------------

    function determineClub(bytes32 name) external view returns (
        address club, bool deployed
    ) {   
        (club, deployed) = address(clubMaster)._predictDeterministicAddress(
            name, abi.encodePacked(name, uint40(block.chainid)));
    } 

    function deployClub(
        Call[] calldata calls,
        address[] calldata signers,
        uint256 threshold,
        bytes32 name // salt
    ) external payable {
        KaliClub club = KaliClub(
            address(clubMaster)._clone(
                name,
                abi.encodePacked(name, uint40(block.chainid))
            )
        );

        club.init{value: msg.value}(
            calls,
            signers,
            threshold
        );

        emit ClubDeployed(
            calls,
            signers,
            threshold,
            name
        );
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.4;

/// @dev Interfaces
import {IERC1271} from "./interfaces/IERC1271.sol";

/// @dev Contracts
import {ERC1155votes} from "./ERC1155votes.sol";
import {Multicall} from "./utils/Multicall.sol";
import {NFTreceiver} from "./utils/NFTreceiver.sol";

/// @title Kali Club
/// @notice EIP-712 multi-sig with ERC-1155 for signers
/// @author Modified from MultiSignatureWallet (https://github.com/SilentCicero/MultiSignatureWallet)
/// and LilGnosis (https://github.com/m1guelpf/lil-web3/blob/main/src/LilGnosis.sol)
/// @dev Lightweight implementation of Moloch v3 
/// (https://github.com/Moloch-Mystics/Baal/blob/main/contracts/Baal.sol)

enum Operation {
    call,
    delegatecall,
    create,
    create2
}

struct Call {
    Operation op;
    address to;
    uint256 value;
    bytes data;
}

struct Signature {
    uint8 v;
    bytes32 r;
    bytes32 s;
}

contract KaliClub is ERC1155votes, Multicall, NFTreceiver {
    /// -----------------------------------------------------------------------
    /// EVENTS
    /// -----------------------------------------------------------------------

    /// @notice Emitted when club executes call
    event Executed(
        Operation op,
        address indexed to, 
        uint256 value, 
        bytes data
    );

    /// @notice Emitted when club executes contract creation
    event ContractCreated(
        Operation op,
        address indexed deployment,
        uint256 value
    );

    /// @notice Emitted when quorum threshold is updated
    event QuorumSet(address indexed caller, uint256 threshold);

    /// @notice Emitted when admin access is set
    event AdminSet(address indexed to);

    /// @notice Emitted when governance access is updated
    event GovernanceSet(
        address indexed caller, 
        address indexed to, 
        bool approve
    );

    /// -----------------------------------------------------------------------
    /// ERRORS
    /// -----------------------------------------------------------------------

    /// @notice Throws if init() is called more than once
    error ALREADY_INIT();

    /// @notice Throws if quorum threshold exceeds totalSupply()
    error QUORUM_OVER_SUPPLY();

    /// @notice Throws if signature doesn't verify execute()
    error INVALID_SIG();

    /// @notice Throws if execute() doesn't complete operation
    error EXECUTE_FAILED();

    /// -----------------------------------------------------------------------
    /// CLUB STORAGE/LOGIC
    /// -----------------------------------------------------------------------
    
    /// @notice Renderer for metadata set in master contract
    KaliClub internal immutable uriFetcher;

    /// @notice Club tx counter
    uint64 public nonce;

    /// @notice Signature NFT threshold to execute tx
    uint64 public quorum;

    /// @notice Total signers minted 
    uint128 public totalSupply;

    /// @notice Initial club domain value 
    bytes32 internal _INITIAL_DOMAIN_SEPARATOR;

    /// @notice Admin access tracking
    mapping(address => bool) public admin;

    /// @notice Governance access tracking
    mapping(address => bool) public governance;

    /// @notice Token URI metadata tracking
    mapping(uint256 => string) internal _tokenURIs;

    /// @notice Access control for club and governance
    modifier onlyClubGovernance() {
        if (
            msg.sender != address(this) 
            && !governance[msg.sender]
            && !admin[msg.sender]
        )
            revert NOT_AUTHORIZED();

        _;
    }
    
    /// @notice Token URI metadata fetcher
    /// @dev Fetches external reference if no local
    function uri(uint256 id) external view returns (string memory) {
        if (bytes(_tokenURIs[id]).length == 0) return uriFetcher.uri(id);
        else return _tokenURIs[id];
    }

    /// -----------------------------------------------------------------------
    /// EIP-712 LOGIC
    /// -----------------------------------------------------------------------

    /// @notice Fetches unique club domain for signatures
    function DOMAIN_SEPARATOR() public view returns (bytes32) {
        return
            block.chainid == _INITIAL_CHAIN_ID()
                ? _INITIAL_DOMAIN_SEPARATOR
                : _computeDomainSeparator();
    }

    function _computeDomainSeparator() internal view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256(
                        'EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'
                    ),
                    keccak256(bytes('KaliClub')),
                    keccak256('1'),
                    block.chainid,
                    address(this)
                )
            );
    }

    function _INITIAL_CHAIN_ID() internal pure returns (uint256 chainId) {
        uint256 offset;

        assembly {
            offset := sub(
                calldatasize(),
                add(shr(240, calldataload(sub(calldatasize(), 2))), 2)
            )
        }
        
        assembly {
            chainId := calldataload(add(offset, 5))
        }
    }

    /// -----------------------------------------------------------------------
    /// INITIALIZER LOGIC
    /// -----------------------------------------------------------------------
    
    /// @notice Deploys master contract template
    /// @param _uriFetcher ID metadata manager
    constructor(KaliClub _uriFetcher) payable {
        uriFetcher = _uriFetcher;
    }

    /// @notice Initializes club configuration
    /// @param calls Initial club operations
    /// @param signers Initial signer set
    /// @param threshold Initial quorum
    function init(
        Call[] calldata calls,
        address[] calldata signers,
        uint256 threshold
    ) external payable {
        if (nonce != 0) revert ALREADY_INIT();

        assembly {
            if iszero(threshold) {
                revert(0, 0)
            }
        }

        if (threshold > signers.length) revert QUORUM_OVER_SUPPLY();

        if (calls.length != 0) {
            for (uint256 i; i < calls.length; ) {
                _execute(
                    calls[i].op, 
                    calls[i].to, 
                    calls[i].value, 
                    calls[i].data
                );

                // an array can't have a total length
                // larger than the max uint256 value
                unchecked {
                    ++i;
                }
            }
        }
        
        address signer;
        address prevAddr;
        uint128 supply;

        for (uint256 i; i < signers.length; ) {
            signer = signers[i];

            // prevent null and duplicate signers
            if (prevAddr >= signer) revert INVALID_SIG();

            prevAddr = signer;

            // won't realistically overflow
            unchecked {
                ++balanceOf[signer][0];

                ++supply;

                ++i;
            }

            emit TransferSingle(msg.sender, address(0), signer, 0, 1);
        }

        nonce = 1;
        quorum = uint64(threshold);
        totalSupply = supply;
        _INITIAL_DOMAIN_SEPARATOR = _computeDomainSeparator();
    }

    /// -----------------------------------------------------------------------
    /// OPERATIONAL LOGIC
    /// -----------------------------------------------------------------------

    /// @notice Fetches digest from club operation
    /// @param op The enum operation to execute
    /// @param to Address to send operation to
    /// @param value Amount of ETH to send in operation
    /// @param data Payload to send in operation
    /// @param txNonce Club tx index
    /// @return Digest for operation
    function getDigest(
        Operation op,
        address to,
        uint256 value,
        bytes calldata data,
        uint256 txNonce
    ) public view returns (bytes32) {
        return 
            keccak256(
                abi.encodePacked(
                    '\x19\x01',
                    DOMAIN_SEPARATOR(),
                    keccak256(
                        abi.encode(
                            keccak256(
                                'Exec(Operation op,address to,uint256 value,bytes data,uint256 txNonce)'
                            ),
                            op,
                            to,
                            value,
                            data,
                            txNonce
                        )
                    )
                )
            );
    }
    
    /// @notice Execute operation from club with signatures
    /// @param op The enum operation to execute
    /// @param to Address to send operation to
    /// @param value Amount of ETH to send in operation
    /// @param data Payload to send in operation
    /// @param sigs Array of signatures from NFT sorted in ascending order by addresses
    /// @dev Make sure signatures are sorted in ascending order - otherwise verification will fail
    /// @return success Whether operation succeeded
    function execute(
        Operation op,
        address to,
        uint256 value,
        bytes calldata data,
        Signature[] calldata sigs
    ) external payable returns (bool success) {
        // begin signature validation with call data
        bytes32 digest = getDigest(op, to, value, data, nonce);
        // start from null in loop to ensure ascending addresses
        address prevAddr;
        // validation is length of quorum threshold 
        uint256 threshold = quorum;

        for (uint256 i; i < threshold; ) {
            address signer = ecrecover(
                digest,
                sigs[i].v,
                sigs[i].r,
                sigs[i].s
            );

            // check contract signature using EIP-1271
            if (signer.code.length != 0) {
                if (
                    IERC1271(signer).isValidSignature(
                        digest,
                        abi.encodePacked(sigs[i].r, sigs[i].s, sigs[i].v)
                    ) != IERC1271.isValidSignature.selector
                ) revert INVALID_SIG();
            }

            // check NFT balance and duplicates
            if (balanceOf[signer][0] == 0 || prevAddr >= signer)
                revert INVALID_SIG();

            // set prevAddr to signer for next iteration until quorum
            prevAddr = signer;

            // won't realistically overflow
            unchecked {
                ++i;
            }
        }
        
        success = _execute(
            op,
            to, 
            value, 
            data
        );
    }
    
    /// @notice Execute operations from club with signed execute() or as governance
    /// @param calls Club operations as arrays of `op, to, value, data`
    /// @return successes Fetches whether operations succeeded
    function batchExecute(Call[] calldata calls) external payable onlyClubGovernance returns (bool[] memory successes) {
        successes = new bool[](calls.length);

        for (uint256 i; i < calls.length; ) {
            successes[i] = _execute(
                calls[i].op,
                calls[i].to, 
                calls[i].value, 
                calls[i].data
            );

            // an array can't have a total length
            // larger than the max uint256 value
            unchecked {
                ++i;
            }
        }
    }

    function _execute(
        Operation op,
        address to, 
        uint256 value, 
        bytes memory data
    ) internal returns (bool success) {
        // won't realistically overflow
        unchecked {
            ++nonce;
        }

        if (op == Operation.call) {
            assembly {
                success := call(
                    gas(),
                    to,
                    value,
                    add(data, 0x20),
                    mload(data),
                    0,
                    0
                )
            }

            emit Executed(op, to, value, data);
        } else if (op == Operation.delegatecall) {
            assembly {
                success := delegatecall(
                    gas(),
                    to,
                    add(data, 0x20),
                    mload(data),
                    0,
                    0
                )
            }

            emit Executed(op, to, value, data);
        } else if (op == Operation.create) {
            address deployment;

            assembly {
                deployment := create(value, add(data, 0x20), mload(data))

                if iszero(deployment) {
                    revert(0, 0)
                }
            }

            emit ContractCreated(op, deployment, value);
        } else {
            address deployment;

            bytes32 salt = bytes32(bytes20(to));

            assembly {
                deployment := create2(value, add(0x20, data), mload(data), salt)

                if iszero(deployment) {
                    revert(0, 0)
                }
            }

            emit ContractCreated(op, deployment, value);
        }

        if (!success) revert EXECUTE_FAILED();
    }
    
    /// @notice Update club quorum
    /// @param threshold Signature threshold to execute() operations
    function setQuorum(uint256 threshold) external payable onlyClubGovernance {
        // note: also make sure signers don't concentrate NFTs,
        // as this could cause issues in reaching quorum
        if (threshold > totalSupply) revert QUORUM_OVER_SUPPLY();

        quorum = _safeCastTo64(threshold);

        emit QuorumSet(msg.sender, threshold);
    }

    /// @notice Club token ID minter
    /// @param to The recipient of mint
    /// @param id The token ID to mint
    /// @param amount The amount to mint
    /// @param data Optional data payload
    /// @dev Token ID cannot be null
    function mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external payable onlyClubGovernance {
        assembly {
            if iszero(id) {
                revert(0, 0)
            }
        }

        _mint(to, id, amount, data);
    }

    /// @notice Club signer minter
    /// @param to The recipient of signer mint
    function mintSigner(address to) public payable onlyClubGovernance {
        // won't realistically overflow
        unchecked {
            ++balanceOf[to][0];

            ++totalSupply;
        }

        emit TransferSingle(msg.sender, address(0), to, 0, 1);
    }

    /// @notice Club token ID burner
    /// @param from The account to burn from
    /// @param id The token ID to burn
    /// @param amount The amount to burn
    /// @dev Token ID cannot be null
    function burn(
        address from, 
        uint256 id, 
        uint256 amount
    ) external payable {
        assembly {
            if iszero(id) {
                revert(0, 0)
            }
        }

        if (
            msg.sender != from
            && !isApprovedForAll[from][msg.sender] 
            && msg.sender != address(this)
            && !governance[msg.sender]
            && !admin[msg.sender]
        )
            revert NOT_AUTHORIZED();

        _burn(from, id, amount);
    }

    /// @notice Club signer burner
    /// @param from The account to burn signer from
    function burnSigner(address from) external payable onlyClubGovernance {
        --balanceOf[from][0];

        // won't underflow as supply is checked above
        unchecked {
            --totalSupply;
        }

        if (quorum > totalSupply) revert QUORUM_OVER_SUPPLY();

        emit TransferSingle(msg.sender, from, address(0), 0, 1);
    } 

    /// @notice Club admin setter
    /// @param to The account to set admin to
    function setAdmin(address to) external payable {
        if (msg.sender != address(this)) revert NOT_AUTHORIZED();

        admin[to] = true;

        emit AdminSet(to);
    }

    /// @notice Club governance setter
    /// @param to The account to set governance to
    /// @param approve The approval setting
    function setGovernance(address to, bool approve)
        external
        payable
        onlyClubGovernance
    {
        governance[to] = approve;

        emit GovernanceSet(msg.sender, to, approve);
    }

    /// @notice Club token ID transferability setter
    /// @param id The token ID to set transferability for
    /// @param transferability The transferability setting
    function setTokenTransferability(uint256 id, bool transferability) external payable onlyClubGovernance {
        transferable[id] = transferability;

        emit TokenTransferabilitySet(msg.sender, id, transferability);
    }

    /// @notice Club token ID metadata setter
    /// @param id The token ID to set metadata for
    /// @param tokenURI The metadata setting
    function setTokenURI(uint256 id, string calldata tokenURI) external payable onlyClubGovernance {
        _tokenURIs[id] = tokenURI;

        emit URI(tokenURI, id);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.4;

/// @notice Enables creating clone contracts with immutable arguments and CREATE2
/// @author Modified from wighawag, zefram.eth
/// (https://github.com/wighawag/clones-with-immutable-args/blob/master/src/ClonesWithImmutableArgs.sol)
/// @dev extended by [email protected] to add receive() without DELEGECALL & create2 support
/// (h/t WyseNynja https://github.com/wighawag/clones-with-immutable-args/issues/4)
library ClonesWithImmutableArgs {
    error Create2fail();

    /// @notice Creates a clone proxy of the implementation contract with immutable args
    /// @dev data cannot exceed 65535 bytes, since 2 bytes are used to store the data length
    /// @param implementation The implementation contract to clone
    /// @param data Encoded immutable args
    /// @return ptr The ptr to the clone's bytecode
    /// @return creationSize The size of the clone to be created
    function _cloneCreationCode(address implementation, bytes memory data)
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
                    // = keccak256('ReceiveETH(uint256)')
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

            assembly {
                dataPtr := add(data, 32)
            }
            
            for ( ; counter >= 32; counter -= 32) {
                assembly {
                    mstore(copyPtr, mload(dataPtr))
                }

                copyPtr += 32;
                dataPtr += 32;
            }
            
            uint256 mask = ~(256**(32 - counter) - 1);

            assembly {
                mstore(copyPtr, and(mload(dataPtr), mask))
            }
            
            copyPtr += counter;

            assembly {
                mstore(copyPtr, shl(240, extraLength))
            }
        }
    }

    /// @notice Creates a clone proxy of the implementation contract with immutable args
    /// @dev data cannot exceed 65535 bytes, since 2 bytes are used to store the data length
    /// @param implementation The implementation contract to clone
    /// @param salt The salt for create2
    /// @param data Encoded immutable args
    /// @return instance The address of the created clone
    function _clone(
        address implementation,
        bytes32 salt,
        bytes memory data
    ) internal returns (address payable instance) {
        (uint256 creationPtr, uint256 creationSize) = _cloneCreationCode(
            implementation,
            data
        );

        assembly {
            instance := create2(0, creationPtr, creationSize, salt)
        }
        
        // if the create2 failed, the instance address won't be set
        if (instance == address(0)) {
            revert Create2fail();
        }
    }

    /// @notice Predicts the address where a deterministic clone of implementation will be deployed
    /// @dev data cannot exceed 65535 bytes, since 2 bytes are used to store the data length
    /// @param implementation The implementation contract to clone
    /// @param salt The salt for create2
    /// @param data Encoded immutable args
    /// @return predicted The predicted address of the created clone
    /// @return exists Whether the clone already exists
    function _predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        bytes memory data
    ) internal view returns (address predicted, bool exists) {
        (uint256 creationPtr, uint256 creationSize) = _cloneCreationCode(
            implementation,
            data
        );

        bytes32 creationHash;

        assembly {
            creationHash := keccak256(creationPtr, creationSize)
        }

        predicted = 
            address(
                uint160(
                    uint256(
                        keccak256(
                            abi.encodePacked(
                                bytes1(0xff), 
                                address(this), 
                                salt, 
                                creationHash
                            )
                        )
                    )
                )
            );

        exists = predicted.code.length != 0;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.4;

/// @notice ERC-1271 interface
/// @dev https://eips.ethereum.org/EIPS/eip-1271
interface IERC1271 {
    function isValidSignature(bytes32 hash, bytes calldata signature)
        external
        view
        returns (bytes4);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.4;

/// @notice Minimalist and gas efficient standard ERC-1155 implementation with Compound-like voting.
/// @author Modified from Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC1155.sol)
abstract contract ERC1155votes {
    /// -----------------------------------------------------------------------
    /// EVENTS
    /// -----------------------------------------------------------------------

    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 amount
    );

    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] amounts
    );

    event DelegateChanged(
        address indexed delegator,
        uint256 id,
        address indexed fromDelegate,
        address indexed toDelegate
    );

    event DelegateVotesChanged(
        address indexed delegate,
        uint256 id,
        uint256 previousBalance,
        uint256 newBalance
    );

    event ApprovalForAll(
        address indexed owner, 
        address indexed operator, 
        bool approved
    );

    event TokenTransferabilitySet(
        address indexed operator, 
        uint256 id, 
        bool transferability
    );

    event URI(string value, uint256 indexed id);

    /// -----------------------------------------------------------------------
    /// ERRORS
    /// -----------------------------------------------------------------------

    error NOT_AUTHORIZED();

    error NONTRANSFERABLE();

    error INVALID_RECIPIENT();

    error LENGTH_MISMATCH();

    error UNDETERMINED();

    error UINT64_MAX();

    error UINT192_MAX();

    /// -----------------------------------------------------------------------
    /// CHECKPOINT STORAGE
    /// -----------------------------------------------------------------------
    
    mapping(uint256 => bool) public transferable;
    
    mapping(address => mapping(uint256 => address)) internal _delegates;

    mapping(address => mapping(uint256 => uint256)) public numCheckpoints;

    mapping(address => mapping(uint256 => mapping(uint256 => Checkpoint))) public checkpoints;
    
    struct Checkpoint {
        uint64 fromTimestamp;
        uint192 votes;
    }

    /// -----------------------------------------------------------------------
    /// ERC-1155 STORAGE
    /// -----------------------------------------------------------------------

    mapping(address => mapping(uint256 => uint256)) public balanceOf;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /// -----------------------------------------------------------------------
    /// ERC-1155 LOGIC
    /// -----------------------------------------------------------------------

    function setApprovalForAll(address operator, bool approved) external payable {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external payable {
        if (msg.sender != from && !isApprovedForAll[from][msg.sender]) revert NOT_AUTHORIZED();

        if (!transferable[id]) revert NONTRANSFERABLE();

        balanceOf[from][id] -= amount;
        balanceOf[to][id] += amount;

        emit TransferSingle(msg.sender, from, to, id, amount);

        if (to.code.length == 0 ? to == address(0) :
            ERC1155TokenReceiver(to).onERC1155Received(msg.sender, from, id, amount, data) !=
                ERC1155TokenReceiver.onERC1155Received.selector
        ) revert INVALID_RECIPIENT();

        if (id != 0) _moveDelegates(delegates(from, id), delegates(to, id), id, amount);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external payable {
        if (ids.length != amounts.length) revert LENGTH_MISMATCH();

        if (msg.sender != from && !isApprovedForAll[from][msg.sender]) revert NOT_AUTHORIZED();

        // storing these outside the loop saves ~15 gas per iteration
        uint256 id;
        uint256 amount;

        for (uint256 i = 0; i < ids.length; ) {
            id = ids[i];
            amount = amounts[i];

            if (!transferable[id]) revert NONTRANSFERABLE();

            balanceOf[from][id] -= amount;
            balanceOf[to][id] += amount;

            if (id != 0) _moveDelegates(delegates(from, id), delegates(to, id), id, amount);

            // an array can't have a total length
            // larger than the max uint256 value
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, from, to, ids, amounts);

         if (to.code.length == 0 ? to == address(0) :
            ERC1155TokenReceiver(to).onERC1155BatchReceived(msg.sender, from, ids, amounts, data) !=
                ERC1155TokenReceiver.onERC1155BatchReceived.selector
        ) revert INVALID_RECIPIENT();
    }

    function balanceOfBatch(address[] calldata owners, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory balances)
    {
        if (owners.length != ids.length) revert LENGTH_MISMATCH();

        balances = new uint256[](owners.length);

        // unchecked because the only math done is incrementing
        // the array index counter which cannot possibly overflow
        unchecked {
            for (uint256 i = 0; i < owners.length; ++i) {
                balances[i] = balanceOf[owners[i]][ids[i]];
            }
        }
    }

    /// -----------------------------------------------------------------------
    /// ERC-165 LOGIC
    /// -----------------------------------------------------------------------

    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC-165 Interface ID for ERC-165
            interfaceId == 0xd9b67a26 || // ERC1-65 Interface ID for ERC-1155
            interfaceId == 0x0e89341c; // ERC-165 Interface ID for ERC1155MetadataURI
    }

    /// -----------------------------------------------------------------------
    /// VOTING LOGIC
    /// -----------------------------------------------------------------------

    function delegates(address account, uint256 id) public view returns (address) {
        address current = _delegates[account][id];

        return current == address(0) ? account : current;
    }

    function getCurrentVotes(address account, uint256 id) external view returns (uint256) {
        // won't underflow because decrement only occurs if positive `nCheckpoints`
        unchecked {
            uint256 nCheckpoints = numCheckpoints[account][id];

            return
                nCheckpoints != 0
                    ? checkpoints[account][id][nCheckpoints - 1].votes
                    : 0;
        }
    }

    function getPriorVotes(
        address account, 
        uint256 id,
        uint256 timestamp
    )
        external
        view
        returns (uint256)
    {
        if (block.timestamp <= timestamp) revert UNDETERMINED();

        uint256 nCheckpoints = numCheckpoints[account][id];

        if (nCheckpoints == 0) return 0;

        // won't underflow because decrement only occurs if positive `nCheckpoints`
        unchecked {
            if (
                checkpoints[account][id][nCheckpoints - 1].fromTimestamp <=
                timestamp
            ) return checkpoints[account][id][nCheckpoints - 1].votes;

            if (checkpoints[account][id][0].fromTimestamp > timestamp) return 0;

            uint256 lower;

            uint256 upper = nCheckpoints - 1;

            while (upper > lower) {
                uint256 center = upper - (upper - lower) / 2;

                Checkpoint memory cp = checkpoints[account][id][center];

                if (cp.fromTimestamp == timestamp) {
                    return cp.votes;
                } else if (cp.fromTimestamp < timestamp) {
                    lower = center;
                } else {
                    upper = center - 1;
                }
            }

            return checkpoints[account][id][lower].votes;
        }
    }

    function delegate(address account, uint256 id) external payable {
        address currentDelegate = delegates(msg.sender, id);

        _delegates[msg.sender][id] = account;

        _moveDelegates(currentDelegate, account, id, balanceOf[msg.sender][id]);

        emit DelegateChanged(msg.sender, id, currentDelegate, account);
    }

    function _moveDelegates(
        address srcRep,
        address dstRep,
        uint256 id,
        uint256 amount
    ) internal {
        if (srcRep != dstRep && amount != 0) {
            if (srcRep != address(0)) {
                uint256 srcRepNum = numCheckpoints[srcRep][id];

                uint256 srcRepOld = srcRepNum != 0
                    ? checkpoints[srcRep][id][srcRepNum - 1].votes
                    : 0;

                uint256 srcRepNew = srcRepOld - amount;

                _writeCheckpoint(srcRep, id, srcRepNum, srcRepOld, srcRepNew);
            }

            if (dstRep != address(0)) {
                uint256 dstRepNum = numCheckpoints[dstRep][id];

                uint256 dstRepOld = dstRepNum != 0
                    ? checkpoints[dstRep][id][dstRepNum - 1].votes
                    : 0;

                uint256 dstRepNew = dstRepOld + amount;

                _writeCheckpoint(dstRep, id, dstRepNum, dstRepOld, dstRepNew);
            }
        }
    }

    function _writeCheckpoint(
        address delegatee,
        uint256 id,
        uint256 nCheckpoints,
        uint256 oldVotes,
        uint256 newVotes
    ) internal {
        unchecked {
            // won't underflow because decrement only occurs if positive `nCheckpoints`
            if (
                nCheckpoints != 0 &&
                checkpoints[delegatee][id][nCheckpoints - 1].fromTimestamp ==
                block.timestamp
            ) {
                checkpoints[delegatee][id][nCheckpoints - 1].votes = _safeCastTo192(
                    newVotes
                );
            } else {
                checkpoints[delegatee][id][nCheckpoints] = Checkpoint(
                    _safeCastTo64(block.timestamp),
                    _safeCastTo192(newVotes)
                );

                // won't realistically overflow
                numCheckpoints[delegatee][id] = nCheckpoints + 1;
            }
        }

        emit DelegateVotesChanged(delegatee, id, oldVotes, newVotes);
    }
    
    function _safeCastTo64(uint256 x) internal pure returns (uint64 y) {
        if (x > 1 << 64) revert UINT64_MAX();

        y = uint64(x);
    }

    function _safeCastTo192(uint256 x) internal pure returns (uint192 y) {
        if (x > 1 << 192) revert UINT192_MAX();

        y = uint192(x);
    }

    /// -----------------------------------------------------------------------
    /// INTERNAL MINT/BURN LOGIC
    /// -----------------------------------------------------------------------

    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) internal {
        balanceOf[to][id] += amount;

        emit TransferSingle(msg.sender, address(0), to, id, amount);

        if (to.code.length == 0 ? to == address(0) :
            ERC1155TokenReceiver(to).onERC1155Received(msg.sender, address(0), id, amount, data) !=
               ERC1155TokenReceiver.onERC1155Received.selector
        ) revert INVALID_RECIPIENT();

        _moveDelegates(address(0), delegates(to, id), id, amount);
    }
    
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal {
        balanceOf[from][id] -= amount;

        _moveDelegates(delegates(from, id), address(0), id, amount);

        emit TransferSingle(msg.sender, from, address(0), id, amount);
    } 
}

/// @notice A generic interface for a contract which properly accepts ERC1155 tokens
/// @author Modified from Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC1155.sol)
abstract contract ERC1155TokenReceiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return ERC1155TokenReceiver.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external pure returns (bytes4) {
        return ERC1155TokenReceiver.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.4;

/// @notice Helper utility that enables calling multiple local methods in a single call
/// @author Modified from Uniswap (https://github.com/Uniswap/v3-periphery/blob/main/contracts/base/Multicall.sol)
abstract contract Multicall {
    function multicall(bytes[] calldata data)
        external
        payable
        returns (bytes[] memory results)
    {
        results = new bytes[](data.length);

        for (uint256 i; i < data.length; ) {
            (bool success, bytes memory result) = address(this).delegatecall(
                data[i]
            );

            if (!success) {
                if (result.length < 68) revert();

                assembly {
                    result := add(result, 0x04)
                }

                revert(abi.decode(result, (string)));
            }

            results[i] = result;
            
            // an array can't have a total length
            // larger than the max uint256 value
            unchecked {
                ++i;
            }
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.4;

/// @notice Receiver hook utility for NFT 'safe' transfers
abstract contract NFTreceiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external pure returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}