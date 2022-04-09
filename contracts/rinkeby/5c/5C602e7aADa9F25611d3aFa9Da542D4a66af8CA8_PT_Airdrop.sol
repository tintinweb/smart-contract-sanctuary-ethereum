/**
 *Submitted for verification at Etherscan.io on 2022-04-09
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}

/**
 * @dev These functions deal with verification of Merkle trees (hash trees),
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
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(
                    abi.encodePacked(computedHash, proofElement)
                );
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(
                    abi.encodePacked(proofElement, computedHash)
                );
            }
        }

        // Check if the computed hash (root) is equal to the provided root
        return computedHash == root;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() external virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) external virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract PT_Airdrop is Ownable {
    uint256 internal constant ONE = 10**18;

    using Strings for uint256;

    address public platformToken;

    mapping(address => bool) public claimed;

    bytes32 merkleRoot =
        0x1a756606293ff8b3fdc35be749563d5cf430f826dab95d8bc58c3f9eb9ea5c78;

    constructor(address _platformToken) {
        platformToken = _platformToken;
    }

    function setPlatformToken(address _platformToken) external onlyOwner {
        platformToken = _platformToken;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function verifyClaim(
        address _account,
        uint256 _vestedAmount,
        uint256 _nonVestedAmount,
        bytes32[] calldata _merkleProof
    ) public view returns (bool) {
        bytes32 node = keccak256(
            abi.encodePacked(_vestedAmount, _account, _nonVestedAmount)
        );
        return MerkleProof.verify(_merkleProof, merkleRoot, node);
    }

    function showElements(
        address _account,
        uint256 _vestedAmount,
        uint256 _nonVestedAmount
    ) public pure returns (bytes memory) {
        return abi.encodePacked(_vestedAmount, _account, _nonVestedAmount);
    }

    address[] internal vestedAddresses;

    function claim(
        uint256 _vestedAmount,
        uint256 _nonVestedAmount,
        bytes32[] calldata _merkleProof
    ) external {
        require(!claimed[_msgSender()], "claimed");
        require(
            verifyClaim(
                _msgSender(),
                _vestedAmount,
                _nonVestedAmount,
                _merkleProof
            ),
            "not eligible for a claim"
        );
        claimed[_msgSender()] = true;
        PlatformToken(platformToken).airdropMint(
            _msgSender(),
            _nonVestedAmount
        );

        vestedAddresses.push(_msgSender());
        PlatformToken(platformToken).distributeVest(
            vestedAddresses,
            _vestedAmount
        );
        delete vestedAddresses;
    }
}

interface PlatformToken {
    function airdropMint(address _to, uint256 _amount) external;

    function distributeVest(address[] calldata vestedAddresses, uint256 amount)
        external;
}