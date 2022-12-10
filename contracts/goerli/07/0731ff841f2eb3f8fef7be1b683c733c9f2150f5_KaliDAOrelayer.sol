/**
 *Submitted for verification at Etherscan.io on 2022-12-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

enum ProposalType {
    MINT, 
    BURN, 
    CALL, 
    VPERIOD,
    GPERIOD,
    QUORUM, 
    SUPERMAJORITY, 
    TYPE, 
    PAUSE, 
    EXTENSION,
    ESCAPE,
    DOCS
}

/// @notice Kali DAO relayer interface.
interface IKaliDAOrelayer {
    function deployKaliDAO(
        string calldata name_,
        string calldata symbol_,
        string calldata docs_,
        bool paused_,
        address[] calldata extensions_,
        bytes[] calldata extensionsData_,
        address[] calldata voters_,
        uint256[] calldata shares_,
        uint32[16] calldata govSettings_
    ) external payable returns (address kaliDAO);

    function propose(
        ProposalType proposalType,
        string calldata description,
        address[] calldata accounts,
        uint256[] calldata amounts,
        bytes[] calldata payloads
    ) external payable returns (uint256 proposal);

    function cancelProposal(uint256 proposal) external payable;

    function processProposal(uint256 proposal) external payable 
        returns (bool didProposalPass, bytes[] memory results);

    function voteBySig(
        address signer, 
        uint256 proposal, 
        bool approve, 
        uint8 v, 
        bytes32 r, 
        bytes32 s
    ) external payable;

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable;

    function delegateBySig(
        address delegatee, 
        uint256 nonce, 
        uint256 deadline, 
        uint8 v, 
        bytes32 r, 
        bytes32 s
    ) external payable;
}

/// @notice Contract that enables a single call to call multiple methods on itself.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/Multicallable.sol)
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/Multicallable.sol)
/// @dev WARNING!
/// Multicallable is NOT SAFE for use in contracts with checks / requires on `msg.value`
/// (e.g. in NFT minting / auction contracts) without a suitable nonce mechanism.
/// It WILL open up your contract to double-spend vulnerabilities / exploits.
/// See: (https://www.paradigm.xyz/2021/08/two-rights-might-make-a-wrong/)
abstract contract Multicallable {
    /// @dev Apply `DELEGATECALL` with the current contract to each calldata in `data`,
    /// and store the `abi.encode` formatted results of each `DELEGATECALL` into `results`.
    /// If any of the `DELEGATECALL`s reverts, the entire transaction is reverted,
    /// and the error is bubbled up.
    function multicall(bytes[] calldata data) public payable returns (bytes[] memory results) {
        assembly {
            if data.length {
                results := mload(0x40) // Point `results` to start of free memory.
                mstore(results, data.length) // Store `data.length` into `results`.
                results := add(results, 0x20)

                // `shl` 5 is equivalent to multiplying by 0x20.
                let end := shl(5, data.length)
                // Copy the offsets from calldata into memory.
                calldatacopy(results, data.offset, end)
                // Pointer to the top of the memory (i.e. start of the free memory).
                let memPtr := add(results, end)
                end := add(results, end)

                for {} 1 {} {
                    // The offset of the current bytes in the calldata.
                    let o := add(data.offset, mload(results))
                    // Copy the current bytes from calldata to the memory.
                    calldatacopy(
                        memPtr,
                        add(o, 0x20), // The offset of the current bytes' bytes.
                        calldataload(o) // The length of the current bytes.
                    )
                    if iszero(delegatecall(gas(), address(), memPtr, calldataload(o), 0x00, 0x00)) {
                        // Bubble up the revert if the delegatecall reverts.
                        returndatacopy(0x00, 0x00, returndatasize())
                        revert(0x00, returndatasize())
                    }
                    // Append the current `memPtr` into `results`.
                    mstore(results, memPtr)
                    results := add(results, 0x20)
                    // Append the `returndatasize()`, and the return data.
                    mstore(memPtr, returndatasize())
                    returndatacopy(add(memPtr, 0x20), 0x00, returndatasize())
                    // Advance the `memPtr` by `returndatasize() + 0x20`,
                    // rounded up to the next multiple of 32.
                    memPtr := and(add(add(memPtr, returndatasize()), 0x3f), 0xffffffffffffffe0)
                    if iszero(lt(results, end)) { break }
                }
                // Restore `results` and allocate memory for it.
                results := mload(0x40)
                mstore(0x40, memPtr)
            }
        }
    }
}

/// @notice Simple single owner authorization mixin.
/// @author Solbase (https://github.com/Sol-DAO/solbase/blob/main/src/auth/Owned.sol)
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/auth/Owned.sol)
abstract contract Owned {
    /// -----------------------------------------------------------------------
    /// Events
    /// -----------------------------------------------------------------------

    event OwnershipTransferred(address indexed user, address indexed newOwner);

    /// -----------------------------------------------------------------------
    /// Custom Errors
    /// -----------------------------------------------------------------------

    error Unauthorized();

    /// -----------------------------------------------------------------------
    /// Ownership Storage
    /// -----------------------------------------------------------------------

    address public owner;

    modifier onlyOwner() virtual {
        if (msg.sender != owner) revert Unauthorized();

        _;
    }

    /// -----------------------------------------------------------------------
    /// Constructor
    /// -----------------------------------------------------------------------

    constructor(address _owner) {
        owner = _owner;

        emit OwnershipTransferred(address(0), _owner);
    }

    /// -----------------------------------------------------------------------
    /// Ownership Logic
    /// -----------------------------------------------------------------------

    function transferOwnership(address newOwner) public payable virtual onlyOwner {
        owner = newOwner;

        emit OwnershipTransferred(msg.sender, newOwner);
    }
}

/// @notice Kali DAO relayer.
contract KaliDAOrelayer is Multicallable, Owned(tx.origin) {
    IKaliDAOrelayer private immutable factory;

    constructor(IKaliDAOrelayer _factory) payable {
        factory = _factory;
    }

    receive() external payable {}

    function deployKaliDAO(
        string memory name_,
        string memory symbol_,
        string memory docs_,
        bool paused_,
        address[] memory extensions_,
        bytes[] calldata extensionsData_,
        address[] calldata voters_,
        uint256[] calldata shares_,
        uint32[16] calldata govSettings_
    ) external payable {
        factory.deployKaliDAO{value: msg.value}(
            name_,
            symbol_,
            docs_,
            paused_,
            extensions_,
            extensionsData_,
            voters_,
            shares_,
            govSettings_
        );
    }

    function propose(
        IKaliDAOrelayer dao,
        ProposalType proposalType,
        string calldata description,
        address[] calldata accounts,
        uint256[] calldata amounts,
        bytes[] calldata payloads
    ) external payable onlyOwner {
        dao.propose(
            proposalType,
            description,
            accounts,
            amounts,
            payloads
        );
    }

    function cancelProposal(IKaliDAOrelayer dao, uint256 proposal) external payable onlyOwner {
        dao.cancelProposal(proposal);
    }

    function processProposal(IKaliDAOrelayer dao, uint256 proposal) external payable returns (bytes memory result) {
        (, result) = address(dao).call(abi.encodeWithSelector(dao.processProposal.selector, proposal));
    }

    function voteBySig(
        IKaliDAOrelayer dao,
        address signer, 
        uint256 proposal, 
        bool approve, 
        uint8 v, 
        bytes32 r, 
        bytes32 s
    ) external payable {
        dao.voteBySig(
            signer,
            proposal,
            approve,
            v,
            r,
            s
        );
    }

    function permit(
        IKaliDAOrelayer dao,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable {
        dao.permit(
            owner,
            spender,
            value,
            deadline,
            v,
            r,
            s
        );
    }

    function delegateBySig(
        IKaliDAOrelayer dao,
        address delegatee, 
        uint256 nonce, 
        uint256 deadline, 
        uint8 v, 
        bytes32 r, 
        bytes32 s
    ) external payable {
        dao.delegateBySig(
            delegatee, 
            nonce, 
            deadline, 
            v, 
            r, 
            s
        );
    }
}