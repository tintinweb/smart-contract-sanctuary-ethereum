// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@siblings/modules/AdminPrivileges.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

interface IERC721 {
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

interface IERC1155 {
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;
}

contract StarlistLootboxBeta is AdminPrivileges {
    address constant private LOSTPOETS_PAGES = 0x34829540A3217E96a7F5DCE63FFFf61FA44500DA; // Sample ERC1155 Smart Contract
    address constant private LOSTPOETS = 0x23eD4B6E5654a57c787D2869ED4AD011eec6974a; // Sample ERC721 Smart Contract
    address private VAULT = 0x699a1928EA12D21dd2138F36A3690059bf1253A0; // Should be constant on deployment

    mapping(address => uint8) public claimed;
    bytes32 private merkleRootOne;
    bytes32 private merkleRootTwo;
    uint16[] private poetTokenIDs = [0, 1, 2]; // Update prior to deployment

    function setMerkleRoots(bytes32 rootOne, bytes32 rootTwo) public onlyAdmins {
        merkleRootOne = rootOne;
        merkleRootTwo = rootTwo;
    }

    function claim(bytes32[] calldata _merkleProof) public {
        require(claimed[msg.sender] == 0, "This wallet has already claimed");
        claimed[msg.sender]++;

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        if (MerkleProof.verify(_merkleProof, merkleRootOne, leaf)) {
            IERC1155(LOSTPOETS_PAGES).safeTransferFrom(VAULT, msg.sender, 1, 1, "");
        } else {
            require(MerkleProof.verify(_merkleProof, merkleRootTwo, leaf), "Invalid Merkle proof");

            uint16 id = poetTokenIDs[poetTokenIDs.length - 1];
            poetTokenIDs.pop();

            IERC721(LOSTPOETS).safeTransferFrom(VAULT, msg.sender, id);
        }
    }

    // TESTING FUNCTIONS - NOT TO BE INCLUDED IN PRODUCTION VERSION

    function setVaultAddress(address a) public onlyAdmins {
        VAULT = a;
    }

    function setPoetTokenIDs(uint16[] calldata ids) public onlyAdmins {
        poetTokenIDs = ids;
    }

    function resetClaimed(address a) public onlyAdmins {
        claimed[a] = 0;
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
pragma solidity ^0.8.0;

/**
* @notice THIS PRODUCT IS IN BETA, SIBLING LABS IS NOT RESPONSIBLE FOR ANY LOST FUNDS OR
* UNINTENDED CONSEQUENCES CAUSED BY THE USE OF THIS PRODUCT IN ANY FORM.
*/

/**
 * @dev Contract module that designates an owner and admins
 * for a smart contract.
 *
 * Inheriting from `AdminPrivileges` will make the
 * {onlyAdmins} modifier available, which can be applied to
 * functions to restrict all wallets except for the stored
 * owner and admin addresses.
 *
* See more module contracts from Sibling Labs at
* https://github.com/NFTSiblings/Modules
 */
contract AdminPrivileges {
    address public owner;

    mapping(address => bool) private admins;

    constructor() {
        owner = msg.sender;
    }

    /**
    * @dev Returns true if provided address has admin status
    * or is the contract owner.
    */
    function isAdmin(address _addr) public view returns (bool) {
        return owner == _addr || admins[_addr];
    }

    /**
    * @dev Prevents a function from being called by anyone
    * but the contract owner or approved admins.
    */
    modifier onlyAdmins() {
        require(isAdmin(msg.sender), "AdminPrivileges: caller is not an admin");
        _;
    }

    /**
    * @dev Toggles admin status of provided addresses.
    */
    function toggleAdmins(address[] calldata accounts) external onlyAdmins {
        for (uint i; i < accounts.length; i++) {
            if (admins[accounts[i]]) {
                delete admins[accounts[i]];
            } else {
                admins[accounts[i]] = true;
            }
        }
    }

    /**
    * @dev Transfers ownership role to a different address.
    */
    function transferOwnership(address newOwner) public {
        require(msg.sender == owner, "Only contract owner can transfer ownership");
        owner = newOwner;
    }
}