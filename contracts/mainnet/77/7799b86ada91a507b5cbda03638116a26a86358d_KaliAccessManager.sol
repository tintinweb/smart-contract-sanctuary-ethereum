/**
 *Submitted for verification at Etherscan.io on 2022-02-05
*/

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.4;

/// @notice Merkle library adapted from (https://github.com/miguelmota/merkletreejs[merkletreejs]).
library MerkleProof {
    /// @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
    /// defined by `root`. For this, a `proof` must be provided, containing
    /// sibling hashes on the branch from the leaf to the root of the tree. Each
    /// pair of leaves and each pair of pre-images are assumed to be sorted.
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        bytes32 computedHash = leaf;

        // cannot realistically overflow on human timescales
        unchecked {
            for (uint256 i = 0; i < proof.length; i++) {
                bytes32 proofElement = proof[i];

                if (computedHash <= proofElement) {
                    // Hash(current computed hash + current element of the proof)
                    computedHash = _efficientHash(computedHash, proofElement);
                } else {
                    // Hash(current element of the proof + current computed hash)
                    computedHash = _efficientHash(proofElement, computedHash);
                }
            }
        }

        // check if the computed hash (root) is equal to the provided root
        return computedHash == root;
    }

    function _efficientHash(bytes32 a, bytes32 b) internal pure returns (bytes32 value) {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

/// @notice Helper utility that enables calling multiple local methods in a single call.
/// @author Modified from Uniswap (https://github.com/Uniswap/v3-periphery/blob/main/contracts/base/Multicall.sol)
abstract contract Multicall {
    function multicall(bytes[] calldata data) public virtual returns (bytes[] memory results) {
        results = new bytes[](data.length);
        
        // cannot realistically overflow on human timescales
        unchecked {
            for (uint256 i = 0; i < data.length; i++) {
                (bool success, bytes memory result) = address(this).delegatecall(data[i]);

                if (!success) {
                    if (result.length < 68) revert();
                    
                    assembly {
                        result := add(result, 0x04)
                    }
                    
                    revert(abi.decode(result, (string)));
                }
                results[i] = result;
            }
        }
    }
}

/// @notice Kali DAO access manager.
/// @author Modified from SushiSwap
/// (https://github.com/sushiswap/trident/blob/master/contracts/pool/franchised/WhiteListManager.sol)
contract KaliAccessManager is Multicall {
    using MerkleProof for bytes32[];

    /*///////////////////////////////////////////////////////////////
                            EVENTS
    //////////////////////////////////////////////////////////////*/

    event ListCreated(uint256 indexed listId, address indexed operator);

    event AccountListed(uint256 indexed listId, address indexed account, bool approved);

    event MerkleRootSet(uint256 indexed listId, bytes32 merkleRoot);

    event ListJoined(uint256 indexed listId, address indexed account);

    /*///////////////////////////////////////////////////////////////
                            ERRORS
    //////////////////////////////////////////////////////////////*/

    error NotOperator();
    
    error NoArrayParity();

    error SignatureExpired();

    error InvalidSignature();

    error ListClaimed();

    error InvalidList();

    error NotOnList();

    /*///////////////////////////////////////////////////////////////
                            EIP-712 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    bytes32 internal constant LIST_TYPEHASH =
        keccak256('List(address account,bool approved,uint256 deadline)');

    /*///////////////////////////////////////////////////////////////
                            LIST STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) public operatorOf;

    mapping(uint256 => bytes32) public merkleRoots;

    mapping(uint256 => mapping(address => bool)) public listedAccounts;

    uint256 public listCount;

    /*///////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor() {
        INITIAL_CHAIN_ID = block.chainid;

        INITIAL_DOMAIN_SEPARATOR = _computeDomainSeparator();
    }

    /*///////////////////////////////////////////////////////////////
                            EIP-712 LOGIC
    //////////////////////////////////////////////////////////////*/

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : _computeDomainSeparator();
    }

    function _computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
                    keccak256(bytes('KaliAccessManager')),
                    keccak256('1'),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*///////////////////////////////////////////////////////////////
                            LIST LOGIC
    //////////////////////////////////////////////////////////////*/

    function isListed(uint256 listId, address account) public view virtual returns (bool) {
        return listedAccounts[listId][account];
    }

    function createList(address[] calldata accounts, bytes32 merkleRoot) public virtual {
        uint256 listId = ++listCount;

        operatorOf[listId] = msg.sender;

        if (accounts.length != 0) {
            // cannot realistically overflow on human timescales
            unchecked {
                for (uint256 i; i < accounts.length; i++) {
                    _listAccount(listId, accounts[i], true);
                }
            }

            emit ListCreated(listId, msg.sender);
        }

        if (merkleRoot != '') {
            merkleRoots[listId] = merkleRoot;

            emit MerkleRootSet(listId, merkleRoot);
        }
    }

    function listAccounts(
        uint256 listId,
        address[] calldata accounts,
        bool[] calldata approvals
    ) public virtual {
        if (msg.sender != operatorOf[listId]) revert NotOperator();

        if (accounts.length != approvals.length) revert NoArrayParity();

        // cannot realistically overflow on human timescales
        unchecked {
            for (uint256 i; i < accounts.length; i++) {
                _listAccount(listId, accounts[i], approvals[i]);
            }
        }
    }

    function listAccountBySig(
        uint256 listId,
        address account,
        bool approved,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        if (block.timestamp > deadline) revert SignatureExpired();

        bytes32 digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR(),
                keccak256(abi.encode(LIST_TYPEHASH, account, approved, deadline))
            )
        );

        address recoveredAddress = ecrecover(digest, v, r, s);

        if (recoveredAddress == address(0) || recoveredAddress != operatorOf[listId]) revert InvalidSignature();

        _listAccount(listId, account, approved);
    }

    function _listAccount(
        uint256 listId,
        address account,
        bool approved
    ) internal virtual {
        listedAccounts[listId][account] = approved;

        emit AccountListed(listId, account, approved);
    }

    /*///////////////////////////////////////////////////////////////
                            MERKLE LOGIC
    //////////////////////////////////////////////////////////////*/

    function setMerkleRoot(uint256 listId, bytes32 merkleRoot) public virtual {
        if (msg.sender != operatorOf[listId]) revert NotOperator();

        merkleRoots[listId] = merkleRoot;

        emit MerkleRootSet(listId, merkleRoot);
    }

    function joinList(
        uint256 listId,
        address account,
        bytes32[] calldata merkleProof
    ) public virtual {
        if (isListed(listId, account)) revert ListClaimed();

        if (merkleRoots[listId] == 0) revert InvalidList();

        if (!merkleProof.verify(merkleRoots[listId], keccak256(abi.encodePacked(account)))) revert NotOnList();

        _listAccount(listId, account, true);

        emit ListJoined(listId, account);
    }
}