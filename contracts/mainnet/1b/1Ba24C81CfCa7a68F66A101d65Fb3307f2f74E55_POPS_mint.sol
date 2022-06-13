// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

interface POPS_nft{
    function mint(address to, uint256 tokenId) external;
}

contract POPS_mint is Ownable {

    ///// EVENTS /////
    event mintingInitialized(address _POPScontract, uint256 _start_time);


    ///// CONTRACT VARIABLES /////

    bool public restrictedToWhitelist = true;
    uint256 constant private reservedPerTeamMember = 5;                                                   // Number of POPs reserved per team member
    uint256 public mintStart;                                                                             // Unix timestamp
    uint256 private nextId;                                                                               // Next mintable ID
    uint256 private nextReservedId;                                                                       // Next reserved ID redeemable by the team
    uint256 private numTeamMembers;                                                                       // Number of team members
    address public POPS_address;                                                                          // POPS NFT contract
    mapping(address => bool) public isTeamMember;                                                         // Is a team member?
    mapping(address => bool) public claimed;                                                              // Tracks whitelist addresses that have already claimed
    bytes32 public whitelist_merkleRoot;                                                                  // MerkleRoot of the whitelist


    ///// CONSTRUCTOR /////

    constructor() Ownable(){}


    ///// FUNCTIONS - BEFORE SALE /////

    // [Tx][Public][Owner] Add team member to the reserved list
    function addTeamMember(address _address) public onlyOwner{
        require(!isTeamMember[_address], "Already a team member");
        isTeamMember[_address] = true;
        numTeamMembers++;
    }

    // [Tx][Public][Owner] Remove team member from the list
    function removeTeamMember(address _address) public onlyOwner{
        require(isTeamMember[_address], "Not a team member");
        delete isTeamMember[_address];
        numTeamMembers--;
    }

    // Put some POPs aside for the team
    function reserveToTeam() public onlyOwner {
        require(nextId == 0 && block.timestamp < mintStart, "Team reserve amount locked");
        nextId=numTeamMembers*reservedPerTeamMember;
    }

    // [Tx][Public][Owner] Setup the minting
    function setupMinting(address _POPScontract, bytes32 _whitelist_merkleRoot) public onlyOwner{
        require(mintStart == 0, "Minting already initialized");
        require(_POPScontract != address(0) && _whitelist_merkleRoot != bytes32(0), "Input error");
        whitelist_merkleRoot = _whitelist_merkleRoot;
        POPS_address = _POPScontract;
    }

    // [Tx][Public][Owner] Initialize the minting
    function initializeMinting(uint256 _start_time) public onlyOwner{
        require(mintStart == 0, "Minting already initialized");
        require(POPS_address != address(0) && whitelist_merkleRoot != bytes32(0), "Sale not configured");
        require(_start_time > block.timestamp, "Start time cannot be in the past");
        mintStart = _start_time;
        emit mintingInitialized(POPS_address, _start_time);
    }


    ///// FUNCTIONS - DURING SALE /////

    // [View][Public] Get available POPS
    function availableToMint() view public returns(uint256){
        return 10000 - nextId;
    }

    // [View][Public] Check if in whitelist
    function whitelistClaimable(address _account, bytes32[] calldata _merkleProof) view public returns(bool){
        if(claimed[_account]) return false;
        else return MerkleProof.verify(_merkleProof, whitelist_merkleRoot, keccak256(abi.encode(_account)));
    }

    // [Tx][Public] Main mint function
    function mintPOP(bytes32[] calldata _whitelist_merkleProof) public {
        require(block.timestamp > mintStart, "Minting hasn't started");
        require(nextId<10000, "All available POPs have been minted");
        if (restrictedToWhitelist) require(whitelistClaimable(msg.sender, _whitelist_merkleProof), "Address not in whitelist");
        else require(!claimed[msg.sender], "Already minted");
        claimed[msg.sender] = true;
        POPS_nft(POPS_address).mint(msg.sender, nextId);
        nextId++;
    }

    // [Tx][Public] Mint function for team members
    function teamMemberClaim() public {
        require(block.timestamp > mintStart, "Minting hasn't started");
        require(isTeamMember[msg.sender] && !claimed[msg.sender], "Not entitled to claim");
        claimed[msg.sender] = true;
        for(uint256 i; i<reservedPerTeamMember; i++) {
            POPS_nft(POPS_address).mint(msg.sender, nextReservedId);
            nextReservedId++;
        }
    }

    // [Tx][Public][Owner] Open minting to non-whitelisted addresses
    function allowAnyoneToMint() public onlyOwner {
        restrictedToWhitelist = false;
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
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
        return computedHash;
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}