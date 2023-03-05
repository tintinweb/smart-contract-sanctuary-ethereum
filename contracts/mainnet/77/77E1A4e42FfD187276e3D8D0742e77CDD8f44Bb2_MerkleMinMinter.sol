// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Tree proofs.
 *
 * The tree and the proofs can be generated using our
 * https://github.com/OpenZeppelin/merkle-tree[JavaScript library].
 * You will find a quickstart guide in the readme.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
 * OpenZeppelin's JavaScript library generates merkle trees that are safe
 * against this attack out of the box.
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
     * @dev Calldata version of {verify}
     *
     * _Available since v4.7._
     */
    function verifyCalldata(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProofCalldata(proof, leaf) == root;
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
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Calldata version of {processProof}
     *
     * _Available since v4.7._
     */
    function processProofCalldata(bytes32[] calldata proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Returns true if the `leaves` can be simultaneously proven to be a part of a merkle tree defined by
     * `root`, according to `proof` and `proofFlags` as described in {processMultiProof}.
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function multiProofVerify(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProof(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Calldata version of {multiProofVerify}
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function multiProofVerifyCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProofCalldata(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Returns the root of a tree reconstructed from `leaves` and sibling nodes in `proof`. The reconstruction
     * proceeds by incrementally reconstructing all inner nodes by combining a leaf/inner node with either another
     * leaf/inner node or a proof sibling node, depending on whether each `proofFlags` item is true or false
     * respectively.
     *
     * CAUTION: Not all merkle trees admit multiproofs. To use multiproofs, it is sufficient to ensure that: 1) the tree
     * is complete (but not necessarily perfect), 2) the leaves to be proven are in the opposite order they are in the
     * tree (i.e., as seen from right to left starting at the deepest layer and continuing at the next layer).
     *
     * _Available since v4.7._
     */
    function processMultiProof(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    /**
     * @dev Calldata version of {processMultiProof}.
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function processMultiProofCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
        return a < b ? _efficientHash(a, b) : _efficientHash(b, a);
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

struct DropData {
    bytes32 merkleroot;
    bool mintbossAllowed; 
    uint256 mintbossMintPrice;
    uint256 mintbossAllowListMintPrice;
    uint256 mintbossReferralFee; // The amount sent to the referrer on each mint
    uint256 mintPhase; // 0 = closed, 1 = WL sale, 2 = public sale
    uint256 publicMintPrice; // Public mint price
    uint256 minPublicMintCount; // The minimum number of tokens any one address can mint
    uint256 minWLMintCount;
    uint256 maxPublicMintCount; // The maximum number of tokens any one address can mint
    uint256 maxWLMintCount; 
    uint256 allowlistMintPrice;
    //uint256 maxTotalSupply;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface INM721A {
    function setBaseURI(string calldata _baseURI) external;
    function setRoyaltyInfo(address receiver, uint96 feeBasisPoints) external;
    function mint(address _recipient, uint256 _quantity) external;
    function totalSupply() external view returns (uint256);
    function balanceOf(address _owner) external view returns (uint256);
    function ownerOf(uint256 _tokenId) external view returns (address);
    function approve(address operator, uint256 tokenId) external payable;
    function getApproved(uint256 tokenId) external view returns (address);
    function setApprovalForAll(address operator, bool approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function transferFrom(address from, address to, uint256 tokenId) external payable;
    function safeTransferFrom(address from, address to, uint256 tokenId) external payable;
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external payable;
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
    function tokenURI(uint256 _tokenId) external view returns (string memory);
    function ADMIN_ROLE() external view returns (uint256);
    function MINTER_ROLE() external view returns (uint256);
    function hasAnyRole(address _user, uint256 _roles) external view returns (bool);
    function initialize(address _owner, string calldata _baseUri, string calldata _name, string calldata _symbol, uint256 _maxTotalSupply, address[] calldata _payees, uint256[] calldata _shares) external returns (address);
    function grantRoles(address _user, uint256 _roles) external payable;
    function transferOwnership(address _newOwner) external;
}

// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@      @@@@@@@@@@@@   @@@@@@@@*   @@@@@@@@                   @@@                      @@@@    &@@@@@@@@@@@@    @@@@@@
// @@@@@       @@@@@@@@@@@   @@@@@@@@*   @@@@@@@@    @@@@@@@@@@@@@@@@@@@@@@@@@@@    @@@@@@@@@@@@@@@    @@@@@@@@@@    @@@@@@@
// @@@@@   #@    @@@@@@@@@   @@@@@@@@*   @@@@@@@@    @@@@@@@@@@@@@@@@@@@@@@@@@@@    @@@@@@@@@@@@@@@@.   @@@@@@@    @@@@@@@@@
// @@@@@   #@@    @@@@@@@@   @@@@@@@@*   @@@@@@@@    @@@@@@@@@@@@@@@@@@@@@@@@@@@    @@@@@@@@@@@@@@@@@@    @@@@    @@@@@@@@@@
// @@@@@   #@@@@    @@@@@@   @@@@@@@@*   @@@@@@@@                 @@@@@@@@@@@@@@    @@@@@@@@@@@@@@@@@@@@   &    @@@@@@@@@@@@
// @@@@@   #@@@@@    @@@@@   @@@@@@@@*   @@@@@@@@    @@@@@@@@@@@@@@@@@@@@@@@@@@@    @@@@@@@@@@@@@@@@@@@@@     *@@@@@@@@@@@@@
// @@@@@   #@@@@@@@    @@@   @@@@@@@@*   @@@@@@@@    @@@@@@@@@@@@@@@@@@@@@@@@@@@    @@@@@@@@@@@@@@@@@@@@@@    @@@@@@@@@@@@@@
// @@@@@   #@@@@@@@@@   &@   @@@@@@@@*   @@@@@@@@    @@@@@@@@@@@@@@@@@@@@@@@@@@@    @@@@@@@@@@@@@@@@@@@@@@    @@@@@@@@@@@@@@
// @@@@@   #@@@@@@@@@@       @@@@@@@@*   @@@@@@@@    @@@@@@@@@@@@@@@@@@@@@@@@@@@    @@@@@@@@@@@@@@@@@@@@@@    @@@@@@@@@@@@@@
// @@@@@   #@@@@@@@@@@@@     @@@@@@@@*   @@@@@@@@    @@@@@@@@@@@@@@@@@@@@@@@@@@@    @@@@@@@@@@@@@@@@@@@@@@    @@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@                                                                                                                   @@@
// @@@  @@@@@@@@         [email protected]@@@@@@@    @@@@@@          @@@@@       @@@@@@@@@@@@@@       @@@@@*        &@@@@@@@@@@@@       @@@
// @@@  @@@@@@@@@        @@@@@@@@@    @@@@@@          @@@@@     @@@@@@@@@@@@@@@@@@     @@@@@*     /@@@@@@@@@@@@@@@@@@    @@@
// @@@  @@@@@*@@@,      @@@@ @@@@@    @@@@@@          @@@@@    @@@@@          @@@@@    @@@@@*    @@@@@@,        @@@@@@   @@@
// @@@  @@@@@ @@@@      @@@@ @@@@@    @@@@@@          @@@@@    @@@@@                   @@@@@*   @@@@@@           @@@@@@  @@@
// @@@  @@@@@  @@@@    @@@@  @@@@@    @@@@@@          @@@@@    %@@@@@@@@@@@            @@@@@*   @@@@@                    @@@
// @@@  @@@@@  @@@@    @@@@  @@@@@    @@@@@@          @@@@@       @@@@@@@@@@@@@@@@     @@@@@*  &@@@@@                    @@@
// @@@  @@@@@   @@@@  @@@@   @@@@@    @@@@@@          @@@@@               @@@@@@@@@@   @@@@@*   @@@@@                    @@@
// @@@  @@@@@   @@@@ ,@@@    @@@@@    @@@@@@          @@@@@   @@@@@@           @@@@@   @@@@@*   @@@@@@           @@@@@@  @@@
// @@@  @@@@@    @@@@@@@@    @@@@@    @@@@@@@        @@@@@@    @@@@@#         ,@@@@@   @@@@@*    @@@@@@@        @@@@@@   @@@
// @@@  @@@@@    &@@@@@@     @@@@@     /@@@@@@@@@@@@@@@@@@      @@@@@@@@@@@@@@@@@@@    @@@@@*      @@@@@@@@@@@@@@@@@     @@@
// @@@  @@@@@     @@@@@@     @@@@@        @@@@@@@@@@@@@            @@@@@@@@@@@@@       @@@@@*         @@@@@@@@@@@*       @@@
// @@@                                                                                                                   @@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "openzeppelin-contracts/utils/cryptography/MerkleProof.sol";
import "./INM721A.sol";
import "./DropData2.sol";

contract MerkleMinMinter {

    mapping(address => DropData) internal _dropData;
    mapping(address => mapping(address => uint256)) public addressPublicMintCount;
    mapping(address => mapping(address => uint256)) public addressWLMintCount;
    mapping(address => mapping(address => uint256)) public referralCount;

    event MintbossMint(address _dropAddress, address _referrer, string _eid, uint256 _quantity);
    event MintPhaseChanged(address _dropAddress, address _from, uint256 newPhase);
    event MintCreated(address _dropAddress);

    constructor() {}

    function createMint(
        address _dropAddress, 
        DropData memory _initialDropData
    ) external {
        require(_dropData[_dropAddress].merkleroot == bytes32(0), "Mint already exists");

        DropData storage data = _dropData[_dropAddress];
        data.merkleroot = _initialDropData.merkleroot;
        data.mintbossAllowed = _initialDropData.mintbossAllowed;
        data.mintbossMintPrice = _initialDropData.mintbossMintPrice;
        data.mintbossAllowListMintPrice = _initialDropData.mintbossAllowListMintPrice;
        data.mintbossReferralFee = _initialDropData.mintbossReferralFee;
        data.mintPhase = _initialDropData.mintPhase;
        data.publicMintPrice = _initialDropData.publicMintPrice;
        data.minPublicMintCount = _initialDropData.minPublicMintCount;
        data.minWLMintCount = _initialDropData.minWLMintCount;
        data.maxPublicMintCount = _initialDropData.maxPublicMintCount;
        data.maxWLMintCount = _initialDropData.maxWLMintCount;
        data.allowlistMintPrice = _initialDropData.allowlistMintPrice;

        emit MintCreated(_dropAddress);
    }

    // SETTERS

    function setDropData(address _dropAddress, DropData memory _newDropData) external onlyAdmin(_dropAddress) {
        DropData storage data = _dropData[_dropAddress];
        data.merkleroot = _newDropData.merkleroot;
        data.mintbossAllowed = _newDropData.mintbossAllowed;
        data.mintbossMintPrice = _newDropData.mintbossMintPrice;
        data.mintbossAllowListMintPrice = _newDropData.mintbossAllowListMintPrice;
        data.mintbossReferralFee = _newDropData.mintbossReferralFee;
        data.mintPhase = _newDropData.mintPhase;
        data.publicMintPrice = _newDropData.publicMintPrice;
        data.minPublicMintCount = _newDropData.minPublicMintCount;
        data.minWLMintCount = _newDropData.minWLMintCount;
        data.maxPublicMintCount = _newDropData.maxPublicMintCount;
        data.maxWLMintCount = _newDropData.maxWLMintCount;
        data.allowlistMintPrice = _newDropData.allowlistMintPrice;
    }

    // Allows the contract owner to update the merkle root (allowlist)
    function setMerkleRoot(address _dropAddress, bytes32 _merkleroot) external onlyAdmin(_dropAddress) {
        _dropData[_dropAddress].merkleroot = _merkleroot;
    }

    // An owner-only function which toggles the public sale on/off
    function setMintPhase(address _dropAddress, uint256 _newPhase) external onlyAdmin(_dropAddress) {
        _dropData[_dropAddress].mintPhase = _newPhase;
        emit MintPhaseChanged(_dropAddress, msg.sender, _newPhase);
    }

    // GETTERS

    function getDropData(address _dropAddress) external view returns (
        bytes32 _merkleroot, 
        bool _mintbossAllowed,
        uint256 _mintbossMintPrice,
        uint256 _mintbossAllowListMintPrice,
        uint256 _mintbossReferralFee, // The amount sent to the referrer on each mint
        uint256 _mintPhase, // 0 = closed, 1 = WL sale, 2 = public sale
        uint256 _publicMintPrice, // Public mint price
        uint256 _minPublicMintCount, // The minimum number of tokens any one address can mint
        uint256 _minWLMintCount,
        uint256 _maxPublicMintCount, // The maximum number of tokens any one address can mint
        uint256 _maxWLMintCount,
        uint256 _allowlistMintPrice
    )  {
        DropData storage data = _dropData[_dropAddress];
        return (
            data.merkleroot,
            data.mintbossAllowed,
            data.mintbossMintPrice,
            data.mintbossAllowListMintPrice,
            data.mintbossReferralFee,
            data.mintPhase,
            data.publicMintPrice,
            data.minPublicMintCount,
            data.minWLMintCount,
            data.maxPublicMintCount,
            data.maxWLMintCount,
            data.allowlistMintPrice
        );
    }

    // MINT FUNCTIONS

    // Minting function for addresses on the allowlist only
    function mintAllowList(address _dropAddress, address _recipient, uint256 _quantity, address payable _referrer, string memory _eid, bytes32[] calldata _proof) external payable {
        DropData storage data = _dropData[_dropAddress];
        uint256 mintCount = addressWLMintCount[_dropAddress][_recipient];
        require(_verify(_leaf(_recipient), _proof, data.merkleroot), "Wallet not on allowlist");
        require(_quantity >= data.minWLMintCount, "Mint quantity too low");
        require(mintCount + _quantity <= data.maxWLMintCount, "Exceeded whitelist allowance");
        require(data.mintPhase==1, "Allowlist sale is not active");
        if (_referrer != address(0)) {
            require(_referrer != _recipient, "Referrer cannot be sender");
            require(data.mintbossAllowed, "Mintboss dissallowed");
            require(_quantity * data.mintbossAllowListMintPrice == msg.value, "Incorrect price");
        } else {
            if(_quantity * data.allowlistMintPrice != msg.value) revert InvalidEthAmount();
        }

        addressWLMintCount[_dropAddress][_recipient] = mintCount + _quantity;
        
        INM721A(payable(_dropAddress)).mint(_recipient, _quantity);
        _payOut(_dropAddress, _referrer, _eid, _quantity, msg.value);
    }

    function mintPublic(address _dropAddress, address _recipient, uint256 _quantity, address payable _referrer, string memory _eid) external payable {
        DropData storage data = _dropData[_dropAddress];
        uint256 mintCount = addressPublicMintCount[_dropAddress][_recipient];
        require(data.mintPhase==2, "Public sale inactive");
        require(_quantity >= data.minPublicMintCount, "Mint quantity too low");
        require(mintCount + _quantity <= data.maxPublicMintCount, "Exceeded max mint");
        if (_referrer != address(0)) {
            require(_referrer != _recipient, "Referrer cannot be sender");
            require(data.mintbossAllowed, "Mintboss dissallowed");
            if(_quantity * data.mintbossMintPrice != msg.value) revert InvalidEthAmount();
        } else {
            if(_quantity * data.publicMintPrice != msg.value) revert InvalidEthAmount();
        }

        addressPublicMintCount[_dropAddress][_recipient] = mintCount + _quantity;
			
        INM721A(payable(_dropAddress)).mint(_recipient, _quantity);
        _payOut(_dropAddress, _referrer, _eid, _quantity, msg.value);
    }

    function _payOut(address _dropAddress, address payable _referrer, string memory _eid, uint256 _quantity, uint256 _value) internal {
        DropData storage data = _dropData[_dropAddress];
        uint256 remainingAmount = _value;
        if (_referrer != address(0)) {
            uint256 refererralFee = data.mintbossReferralFee * _quantity;
            referralCount[_dropAddress][_referrer] += _quantity;
            remainingAmount -= refererralFee;
            emit MintbossMint(_dropAddress, _referrer, _eid, _quantity);

            payable(_referrer).transfer(refererralFee);
        }
        payable(_dropAddress).transfer(remainingAmount);
    }

    // MERKLE FUNCTIONS

    // Used to construct a merkle tree leaf
    function _leaf(address _account) internal pure returns (bytes32)
    {
        return keccak256(abi.encodePacked(_account));
    }

    // Verifies a leaf is part of the tree
    function _verify(bytes32 leaf, bytes32[] memory _proof, bytes32 _root) pure
    internal returns (bool)
    {
        return MerkleProof.verify(_proof, _root, leaf);
    }

    // MODIFIERS

    modifier onlyAdmin(address _dropAddress) virtual {
        require(INM721A(payable(_dropAddress)).hasAnyRole(msg.sender, INM721A(payable(_dropAddress)).ADMIN_ROLE()), "not admin");
        _;
    }

    modifier onlyMinter(address _dropAddress) virtual {
        require(INM721A(payable(_dropAddress)).hasAnyRole(msg.sender, INM721A(payable(_dropAddress)).MINTER_ROLE()), "not minter");
        _;
    }

    // ERRORS

    error InvalidEthAmount();
}