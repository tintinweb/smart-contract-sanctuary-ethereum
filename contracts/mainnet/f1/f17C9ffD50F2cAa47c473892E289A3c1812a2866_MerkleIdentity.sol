/**
 *Submitted for verification at Etherscan.io on 2022-07-06
*/

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.12;

interface IVoterID {
    /**
        @notice Minting function
    */
    function createIdentityFor(address newId, uint tokenId, string calldata uri) external;

    /**
        @notice Who has the authority to override metadata uri
    */
    function owner() external view returns (address);

    /**
        @notice How many of these things exist?
    */
    function totalSupply() external view returns (uint);
}
interface IPriceGate {

    /// @notice This function should return how much ether or tokens the minter must pay to mint an NFT
    function getCost(uint) external view returns (uint ethCost);

    /// @notice This function is called by MerkleIdentity when minting an NFT. It is where funds get collected.
    function passThruGate(uint, address) external payable;
}
interface IEligibility {

//    function getGate(uint) external view returns (struct Gate)
//    function addGate(uint...) external

    /// @notice Is the given user eligible? Concerns the address, not whether or not they have the funds
    /// @dev The bytes32[] argument is for merkle proofs of eligibility
    /// @return eligible true if the user can mint
    function isEligible(uint, address, bytes32[] calldata) external view returns (bool eligible);

    /// @notice This function is called by MerkleIdentity to make any state updates like counters
    /// @dev This function should typically call isEligible, since MerkleIdentity does not
    function passThruGate(uint, address, bytes32[] calldata) external;
}

library MerkleLib {

    function verifyProof(bytes32 root, bytes32 leaf, bytes32[] calldata proof) public pure returns (bool) {
        bytes32 currentHash = leaf;

        uint proofLength = proof.length;
        for (uint i; i < proofLength;) {
            currentHash = parentHash(currentHash, proof[i]);
            unchecked { ++i; }
        }

        return currentHash == root;
    }

    function parentHash(bytes32 a, bytes32 b) private pure returns (bytes32) {
        return keccak256(a < b ? abi.encode(a, b) : abi.encode(b, a));
    }

}

/// @title A generalized NFT minting system using merkle trees to pre-commit to metadata posted to ipfs
/// @author metapriest, adrian.wachel, marek.babiarz, radoslaw.gorecki
/// @notice This contract is permissioned, it requires a treeAdder key to add trees
/// @dev Merkle trees are used at this layer to prove the correctness of metadata added to newly minted NFTs
/// @dev A single NFT contract may have many merkle trees with the same or different roots added here
/// @dev Each tree added has a price gate (specifies price schedule) and an eligibility gate (specifies eligibility criteria)
/// @dev Double minting of the same NFT is prevented by the NFT contract (VoterID)
contract MerkleIdentity {
    using MerkleLib for bytes32;

    // this represents a mint of a single NFT contract with a fixed price gate and eligibility gate
    struct MerkleTree {
        bytes32 metadataMerkleRoot;  // root of merkle tree whose leaves are uri strings to be assigned to minted NFTs
        bytes32 ipfsHash; // ipfs hash of complete uri dataset, as redundancy so that merkle proof remain computable
        address nftAddress; // address of NFT contract to be minted
        address priceGateAddress;  // address price gate contract
        address eligibilityAddress;  // address of eligibility gate contract
        uint eligibilityIndex; // enables re-use of eligibility contracts
        uint priceIndex; // enables re-use of price gate contracts
    }

    // array-like mapping of index to MerkleTree structs
    mapping (uint => MerkleTree) public merkleTrees;
    // count the trees
    uint public numTrees;

    // management key used to set ipfs hashes and treeAdder addresses
    address public management;
    // treeAdder is address that can add trees, separated from management to prevent switching it to a broken contract
    address public treeAdder;

    // every time a merkle tree is added
    event MerkleTreeAdded(uint indexed index, address indexed nftAddress);

    error ManagementOnly(address notManagement);
    error TreeAdderOnly(address notTreeAdder);
    error BadMerkleIndex(uint index);
    error BadMerkleProof(bytes32[] proof, bytes32 root);

    // simple call gate
    modifier managementOnly() {
        if (msg.sender != management) {
            revert ManagementOnly(msg.sender);
        }
        _;
    }

    /// @notice Whoever deploys the contract sets the two privileged keys
    /// @param _mgmt key that will initially be both management and treeAdder
    constructor(address _mgmt) {
        management = _mgmt;
        treeAdder = _mgmt;
    }

    /// @notice Change the management key
    /// @dev Only the current management key can change this
    /// @param newMgmt the new management key
    function setManagement(address newMgmt) external managementOnly {
        management = newMgmt;
    }

    /// @notice Change the treeAdder key
    /// @dev Only the current management key can call this
    /// @param newAdder new addres that will be able to add trees, old address will not be able to
    function setTreeAdder(address newAdder) external managementOnly {
        treeAdder = newAdder;
    }

    /// @notice Set the ipfs hash of a specific tree
    /// @dev Only the current management key can call this
    /// @param merkleIndex which merkle tree are we talking about?
    /// @param hash the new ipfs hash summarizing this dataset, written as bytes32 omitting the first 2 bytes "Qm"
    function setIpfsHash(uint merkleIndex, bytes32 hash) external managementOnly {
        MerkleTree storage tree = merkleTrees[merkleIndex];
        tree.ipfsHash = hash;
    }

    /// @notice Create a new merkle tree, opening a mint to an existing contract
    /// @dev Only treeAdder can call this
    /// @param metadataMerkleRoot merkle root of the complete metadata set represented as mintable by this tree
    /// @param ipfsHash ipfs hash of complete dataset (note that you can post hash here without posting to network aka "submarining"
    /// @param nftAddress address of NFT contract to be minted (must conform to IVoterID interface)
    /// @param priceGateAddress address of price gate contract (must conform to IPriceGate interface)
    /// @param eligibilityAddress address of eligibility gate contract (must conform to IEligibility interface)
    /// @param eligibilityIndex index passed to eligibility gate, which in general will have many gates, to select which parameters
    /// @param priceIndex index passed to price gate to select which parameters to use
    function addMerkleTree(
        bytes32 metadataMerkleRoot,
        bytes32 ipfsHash,
        address nftAddress,
        address priceGateAddress,
        address eligibilityAddress,
        uint eligibilityIndex,
        uint priceIndex) external returns (uint) {
        if (msg.sender != treeAdder) {
            revert TreeAdderOnly(msg.sender);
        }
        MerkleTree storage tree = merkleTrees[++numTrees];
        tree.metadataMerkleRoot = metadataMerkleRoot;
        tree.ipfsHash = ipfsHash;
        tree.nftAddress = nftAddress;
        tree.priceGateAddress = priceGateAddress;
        tree.eligibilityAddress = eligibilityAddress;
        tree.eligibilityIndex = eligibilityIndex;
        tree.priceIndex = priceIndex;
        emit MerkleTreeAdded(numTrees, nftAddress);
        return numTrees;
    }

    /// @notice Mint a new NFT
    /// @dev Anyone may call this, but they must pass thru the two gates
    /// @param merkleIndex which merkle tree are we withdrawing the NFT from?
    /// @param tokenId the id number of the NFT to be minted, this data is bound to the uri in each leaf of the metadata merkle tree
    /// @param uri the metadata uri that will be associated with the minted NFT
    /// @param addressProof merkle proof proving the presence of msg.sender's address in an eligibility merkle tree
    /// @param metadataProof sequence of hashes from leaf hash (tokenID, uri) to merkle root, proving data validity
    function withdraw(uint merkleIndex, uint tokenId, string calldata uri, bytes32[] calldata addressProof, bytes32[] calldata metadataProof) external payable {
        MerkleTree storage tree = merkleTrees[merkleIndex];
        IVoterID id = IVoterID(tree.nftAddress);

        // mint an identity first, this keeps the token-collision gas cost down
        id.createIdentityFor(msg.sender, tokenId, uri);

        // check that the merkle index is real
        if (merkleIndex > numTrees || merkleIndex == 0) {
            revert BadMerkleIndex(merkleIndex);
        }

        // verify that the metadata is real
        if (verifyMetadata(tree.metadataMerkleRoot, tokenId, uri, metadataProof) == false) {
            revert BadMerkleProof(metadataProof, tree.metadataMerkleRoot);
        }

        // check eligibility of address
        IEligibility(tree.eligibilityAddress).passThruGate(tree.eligibilityIndex, msg.sender, addressProof);

        // check that the price is right
        IPriceGate(tree.priceGateAddress).passThruGate{value: msg.value}(tree.priceIndex, msg.sender);

    }

    /// @notice Get the current price for minting an NFT from a particular tree
    /// @dev This does not take tokenId as an argument, if you want different tokenIds to have different prices, use different trees
    /// @return ethCost the cost in wei of minting an NFT (could represent token cost if price gate takes tokens)
    function getPrice(uint merkleIndex) public view returns (uint) {
        MerkleTree storage tree = merkleTrees[merkleIndex];
        return IPriceGate(tree.priceGateAddress).getCost(tree.priceIndex);
    }

    /// @notice Is the given address eligibile to mint from the given tree
    /// @dev If the eligibility gate does not use merkle trees, the proof can be left empty or used for anything else
    /// @param merkleIndex which tree are we talking about?
    /// @param recipient the address about which we are querying eligibility
    /// @param proof merkle proof linking recipient to eligibility merkle root
    /// @return eligibility true if recipient is currently eligible
    function isEligible(uint merkleIndex, address recipient, bytes32[] calldata proof) public view returns (bool) {
        MerkleTree storage tree = merkleTrees[merkleIndex];
        return IEligibility(tree.eligibilityAddress).isEligible(tree.eligibilityIndex, recipient, proof);
    }

    /// @notice Is the provided metadata included in tree?
    /// @dev This is public for interfaces, called internally by withdraw function
    /// @param root merkle root (proof destination)
    /// @param tokenId index of NFT being queried
    /// @param uri intended uri of NFT being minted
    /// @param proof sequence of hashes linking leaf data to merkle root
    function verifyMetadata(bytes32 root, uint tokenId, string calldata uri, bytes32[] calldata proof) public pure returns (bool) {
        bytes32 leaf = keccak256(abi.encode(tokenId, uri));
        return root.verifyProof(leaf, proof);
    }

}