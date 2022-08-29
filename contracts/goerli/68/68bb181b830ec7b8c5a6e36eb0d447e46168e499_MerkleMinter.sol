// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "solmate/utils/ReentrancyGuard.sol";
import "openzeppelin-contracts/contracts/utils/cryptography/MerkleProof.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "./Particles.sol";
import "./Errors.sol";

// Non-reusable dumb implementation of merkle minter for the particle #1

/*  

                 :-:..        
              :*%@@*#@%+:     
      :-:. .+*%@@@@%[email protected]@@@#:   
   .##%@@%*#@@@@@@@%%@@@@@#   
   -%@@@@@@@@@%##%@@%@@@@@@-  
  =%@@@@@@@@@@#.  *@@@@@@@@*. 
  [email protected]@@@@@@@@@@@%: .%@@@@%#*-  
  :@@@@@@@@@@@@@%-#@@@@%#*:.  
   #@@@%@%%@@@@@@@%@@%-.      
   .*@%#=..=%@@@@@%%@#.       
     :-.     =%%@@%#*.        
               =#%%%*         
               ..-*%#.        
                   ..         

*/

contract MerkleMinter is Ownable, ReentrancyGuard {
  bytes32 public merkleRoot;
  Particles public particles;
  uint256 private immutable tokenId;

  // track if wallet has already minted (one mint per wallet)
  mapping(address => bool) public minted;

  // interface labs multisig
  address public constant beneficiary =
    0x0F789fbca6D2fB9207B795154b04aa8a02b9d40d;

  // mint config
  uint256 public constant mintPrice = 0.21 ether;
  uint256 public constant mintMerklePrice = 0.07 ether;
  uint256 public immutable mintStart;

  constructor(bytes32 _merkleRoot, address _particles, uint256 _mintStart, uint256 _tokenId) {
    if (_tokenId == 0) revert Errors.UnknownParticle();
    merkleRoot = _merkleRoot;
    particles = Particles(_particles);
    tokenId = _tokenId;
    mintStart = _mintStart;
  }

  modifier enough(uint256 _mintPrice) {
    if (msg.value < _mintPrice) revert Errors.InsufficientFunds();
    _;
  }

  modifier started() {
    if (block.number < mintStart) revert Errors.MintNotStarted();
    _;
  }

  function allowListed(address wallet, bytes32[] calldata proof)
    public
    view
    returns (bool)
  {
    return
      MerkleProof.verify(
        proof,
        merkleRoot,
        keccak256(abi.encodePacked(wallet))
      );
  }

  function mintWithProof(
    bytes32[] calldata _proof
  ) external payable enough(mintMerklePrice) started nonReentrant {
    if (!allowListed(msg.sender, _proof)) revert Errors.NotAllowListed();
    _mintLogic();
  }

  function mintPublic()
    external
    payable
    enough(mintPrice)
    started
    nonReentrant
  {
    _mintLogic();
  }

  function _mintLogic() internal {
    if (minted[msg.sender]) revert Errors.AlreadyMinted();

    minted[msg.sender] = true;
    particles.mint(msg.sender, tokenId, 1);
  }

  function withdraw() external onlyOwner {
    uint256 balance = address(this).balance;
    (bool transferTx, ) = beneficiary.call{value: balance}("");
    if (!transferTx) {
      revert Errors.WithdrawTransfer();
    }
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Gas optimized reentrancy protection for smart contracts.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/ReentrancyGuard.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol)
abstract contract ReentrancyGuard {
    uint256 private locked = 1;

    modifier nonReentrant() virtual {
        require(locked == 1, "REENTRANCY");

        locked = 2;

        _;

        locked = 1;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Tree proofs.
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
     * @dev Returns true if the `leaves` can be proved to be a part of a Merkle tree defined by
     * `root`, according to `proof` and `proofFlags` as described in {processMultiProof}.
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
     * @dev Returns the root of a tree reconstructed from `leaves` and the sibling nodes in `proof`,
     * consuming from one or the other at each step according to the instructions given by
     * `proofFlags`.
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
     * @dev Calldata version of {processMultiProof}
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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "solmate/tokens/ERC1155.sol";
import "solmate/utils/ReentrancyGuard.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "./IRenderer.sol";
import "./Errors.sol";

/*
.                            .

          :=+*#**+**=         
        =*%%%##%%%@%*+=       
     .=#%%%@@%%%%#+++++#+.    
    .%%@@@@@@%#+==+=+#@%*:    
    -%%@@@%*+==++*##@@#+*=    
    [email protected]@%#++++*#%@@%%*++#%#.   
    .#**##%@@@@@%*++*%%%#=    
    +#%@@@@@%#*+*#%%%%*+:     
    :=*%##*#%%%%%###*++:      
     .-=*#%%@@%#+***+-.       
          =++==*#+-:    

.                            .      
 */

contract Particles is ERC1155, Ownable, ReentrancyGuard {
  // emitted when new particles get spawned
  event Spawn(
    uint256 indexed tokenId,
    uint256 maxSpawn,
    address minter,
    address renderer,
    string ipfsHash
  );

  struct Particle {
    uint256 spawned;
    uint256 maxSpawn;
    address minter;
    address renderer;
    bytes metadata;
  }

  string public baseURI;
  string public contractURI;

  mapping(uint256 => Particle) public particles;

  string public name = "interface particles";
  string public symbol = "IN][PA";

  constructor(string memory _baseURI, string memory _contractURI) {
    baseURI = _baseURI;
    contractURI = _contractURI;
  }

  function particleExists(uint256 tokenId) public view returns (bool) {
    if (particles[tokenId].maxSpawn != 0) {
      return true;
    }
    return false;
  }

  function spawn(
    uint256 tokenId,
    uint256 maxSpawn,
    address minter,
    address renderer,
    bytes calldata ipfsHash
  ) external onlyOwner {
    if (particleExists(tokenId)) revert Errors.ParticleAlreadyExists();
    if (maxSpawn == 0) revert Errors.ParticleMaxSpawnCannotBeZero();

    particles[tokenId].spawned = 0;
    particles[tokenId].maxSpawn = maxSpawn;
    particles[tokenId].metadata = ipfsHash;
    particles[tokenId].minter = minter;
    particles[tokenId].renderer = renderer;

    emit URI(uri(tokenId), tokenId);
    emit Spawn(tokenId, maxSpawn, minter, renderer, string(ipfsHash));
  }

  function mint(
    address sender,
    uint256 tokenId,
    uint256 editions
  ) public nonReentrant {
    if (tokenId == 0) revert Errors.UnknownParticle();
    if (!particleExists(tokenId)) revert Errors.UnknownParticle();
    if (particles[tokenId].minter != msg.sender) revert Errors.InvalidMinter();
    if (particles[tokenId].spawned + editions > particles[tokenId].maxSpawn)
      revert Errors.MaxSpawnMinted();

    particles[tokenId].spawned += editions;
    _mint(sender, tokenId, editions, "");
  }

  function burn(uint256 tokenId, uint256 editions) public nonReentrant {
    if (tokenId == 0) revert Errors.UnknownParticle();
    if (!particleExists(tokenId)) revert Errors.UnknownParticle();
    if (balanceOf[msg.sender][tokenId] < editions)
      revert Errors.CannotBurnWhatYouDontOwn();

    _burn(msg.sender, tokenId, editions);
  }

  function setContractURI(string calldata _contractURI) public onlyOwner {
    contractURI = _contractURI;
  }

  function setBaseURI(string calldata _baseURI) public onlyOwner {
    baseURI = _baseURI;
  }

  function updateTokenURI(uint256 tokenId, bytes calldata path)
    external
    onlyOwner
  {
    particles[tokenId].metadata = path;
    emit URI(uri(tokenId), tokenId);
  }

  function updateTokenRenderer(uint256 tokenId, address _renderer)
    external
    onlyOwner
  {
    particles[tokenId].renderer = _renderer;
  }

  function uri(uint256 tokenId) public view override returns (string memory) {
    if (particles[tokenId].renderer == address(0)) {
      return string(abi.encodePacked(baseURI, particles[tokenId].metadata));
    }

    IRenderer renderer = IRenderer(particles[tokenId].renderer);
    return renderer.uri(tokenId);
  }

  function maxSupply(uint256 id) public view returns (uint256) {
    return particles[id].maxSpawn;
  }

  function spawned(uint256 id) public view returns (uint256) {
    return particles[id].spawned;
  }

  // just in case someone sends accidental funds or something
  function withdraw(address payable payee) external onlyOwner {
    uint256 balance = address(this).balance;
    (bool sent, ) = payee.call{value: balance}("");
    if (!sent) {
      revert Errors.WithdrawTransfer();
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Errors {
  /* Particles.sol */
  error WithdrawTransfer();
  error UnknownParticle();
  error InvalidMinter();
  error MaxSpawnMinted();
  error ParticlePropertiesMissMatch();
  error ParticleMaxSpawnCannotBeZero();
  error ParticleAlreadyExists();
  error PropertyAlreadyExists();
  error PropertyMinCannotBeBiggerMax();
  error PropertyMaxSpawnCannotBeZero();
  error ParticleValueOutOfRangeOrDoesntExist();
  error CannotBurnWhatYouDontOwn();

  /* MerkleMinter.sol */
  error NotAllowListed();
  error InsufficientFunds();
  error AlreadyMinted();
  error MintNotStarted();
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Minimalist and gas efficient standard ERC1155 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC1155.sol)
abstract contract ERC1155 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

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

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    event URI(string value, uint256 indexed id);

    /*//////////////////////////////////////////////////////////////
                             ERC1155 STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(address => mapping(uint256 => uint256)) public balanceOf;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*//////////////////////////////////////////////////////////////
                             METADATA LOGIC
    //////////////////////////////////////////////////////////////*/

    function uri(uint256 id) public view virtual returns (string memory);

    /*//////////////////////////////////////////////////////////////
                              ERC1155 LOGIC
    //////////////////////////////////////////////////////////////*/

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) public virtual {
        require(msg.sender == from || isApprovedForAll[from][msg.sender], "NOT_AUTHORIZED");

        balanceOf[from][id] -= amount;
        balanceOf[to][id] += amount;

        emit TransferSingle(msg.sender, from, to, id, amount);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155Received(msg.sender, from, id, amount, data) ==
                    ERC1155TokenReceiver.onERC1155Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) public virtual {
        require(ids.length == amounts.length, "LENGTH_MISMATCH");

        require(msg.sender == from || isApprovedForAll[from][msg.sender], "NOT_AUTHORIZED");

        // Storing these outside the loop saves ~15 gas per iteration.
        uint256 id;
        uint256 amount;

        for (uint256 i = 0; i < ids.length; ) {
            id = ids[i];
            amount = amounts[i];

            balanceOf[from][id] -= amount;
            balanceOf[to][id] += amount;

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, from, to, ids, amounts);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155BatchReceived(msg.sender, from, ids, amounts, data) ==
                    ERC1155TokenReceiver.onERC1155BatchReceived.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function balanceOfBatch(address[] calldata owners, uint256[] calldata ids)
        public
        view
        virtual
        returns (uint256[] memory balances)
    {
        require(owners.length == ids.length, "LENGTH_MISMATCH");

        balances = new uint256[](owners.length);

        // Unchecked because the only math done is incrementing
        // the array index counter which cannot possibly overflow.
        unchecked {
            for (uint256 i = 0; i < owners.length; ++i) {
                balances[i] = balanceOf[owners[i]][ids[i]];
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0xd9b67a26 || // ERC165 Interface ID for ERC1155
            interfaceId == 0x0e89341c; // ERC165 Interface ID for ERC1155MetadataURI
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        balanceOf[to][id] += amount;

        emit TransferSingle(msg.sender, address(0), to, id, amount);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155Received(msg.sender, address(0), id, amount, data) ==
                    ERC1155TokenReceiver.onERC1155Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _batchMint(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        uint256 idsLength = ids.length; // Saves MLOADs.

        require(idsLength == amounts.length, "LENGTH_MISMATCH");

        for (uint256 i = 0; i < idsLength; ) {
            balanceOf[to][ids[i]] += amounts[i];

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, address(0), to, ids, amounts);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155BatchReceived(msg.sender, address(0), ids, amounts, data) ==
                    ERC1155TokenReceiver.onERC1155BatchReceived.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _batchBurn(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        uint256 idsLength = ids.length; // Saves MLOADs.

        require(idsLength == amounts.length, "LENGTH_MISMATCH");

        for (uint256 i = 0; i < idsLength; ) {
            balanceOf[from][ids[i]] -= amounts[i];

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, from, address(0), ids, amounts);
    }

    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        balanceOf[from][id] -= amount;

        emit TransferSingle(msg.sender, from, address(0), id, amount);
    }
}

/// @notice A generic interface for a contract which properly accepts ERC1155 tokens.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC1155.sol)
abstract contract ERC1155TokenReceiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC1155TokenReceiver.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC1155TokenReceiver.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRenderer {
  function uri(uint256 tokenId) external view returns (string memory);
}