/**
 *Submitted for verification at Etherscan.io on 2022-04-08
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;


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
     * @dev Returns the rebuilt hash obtained by traversing a Merklee tree up
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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


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



interface IBattle {
    function mint(uint256 _num, address _to) external;
}

contract BattlePublicMint is Ownable {
    uint256 public cost = 0.05 ether;
    uint256 public maxMintPerUser = 5;
    uint256 public publicMintMaxAmount = 1000;
    uint256 public totalMinted;
    uint256 private constant stepMintAmount = 1000;
    uint256 private constant stepCost = 0.05 ether;

    bytes32 public merkleRoot;
    mapping(address => bool) public claimed;

    address private battleContract;

    event Minted(uint256 indexed amount, address indexed to);

    function mint(uint256 _mintAmount) external payable {
        require(
            _mintAmount > 0 && _mintAmount <= maxMintPerUser,
            "BTTL: Incorrect mint amount"
        );
        require(
            totalMinted + _mintAmount <= publicMintMaxAmount,
            "BTTL: Decrease mint amount"
        );

        require(msg.value >= cost * _mintAmount, "Not enough ether amount");

        IBattle(battleContract).mint(_mintAmount, msg.sender);

        totalMinted += _mintAmount;
        emit Minted(_mintAmount, msg.sender);
    }

    function setCost(uint256 _newCost) external onlyOwner {
        cost = _newCost;
    }

    function setMaxMintPerUser(uint256 _maxMintPerUser) external onlyOwner {
        maxMintPerUser = _maxMintPerUser;
    }

    function setPublicMaxMintAmount(uint256 _maxMintAmount) external onlyOwner {
        publicMintMaxAmount = _maxMintAmount;
    }

    function nextWave() external onlyOwner {
        publicMintMaxAmount += stepMintAmount;
        cost += stepCost;
    }

    function withdraw() external payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success);
    }

    constructor(address _battleContractAddress) {
        require(_battleContractAddress != address(0));
        battleContract = _battleContractAddress;
    }

    function claim(bytes32[] calldata merkleProof) external 
    {
        require(claimed[msg.sender] == false, "Already claimed");
        claimed[msg.sender] = true;
        require(MerkleProof.verify(merkleProof, merkleRoot, keccak256(abi.encodePacked(msg.sender))), "Invalid proof");
        IBattle(battleContract).mint(1, msg.sender);
        totalMinted++;
        emit Minted(1, msg.sender);
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }
}