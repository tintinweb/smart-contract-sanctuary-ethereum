// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Hydra.sol";

contract Hydra_ERC20 is Hydra {
  IERC20 immutable public token;

  constructor(
    IERC20 _token,
    IVerifier _verifier,
    uint256 _denomination,
    uint32 _merkleTreeHeight
  ) Hydra(_verifier, _denomination, _merkleTreeHeight) {
    token = _token;
  }

  function _onVaultRotation(address oldVault, address newVault) internal virtual override {
    _safeErc20Transfer(
      oldVault,
      newVault,
      token.balanceOf(oldVault)
    );
  }

  function _processDeposit(bytes32 salt) internal virtual override {
    require(msg.value == 0, "ETH value is supposed to be 0 for ERC20 instance");

    _safeErc20TransferFrom(
      fetchHead(salt),
      msg.sender,
      vault,
      denomination
    );
  }

  function _processWithdraw(address payable recipient, address payable relayer, uint256 fee, uint256 refund) internal virtual override {
    require(msg.value == refund, "Incorrect refund amount received by the contract");

    address currentVault = vault; // cache to avoid sload

    _safeErc20Transfer(currentVault, recipient, denomination - fee);
    if (fee > 0) {
      _safeErc20Transfer(currentVault, relayer, fee);
    }

    if (refund > 0) {
      (bool success, ) = HydraHead(currentVault).call(recipient, refund, bytes(""));
      if (!success) {
        HydraHead(currentVault).call(relayer, refund, bytes(""));
      }
    }
  }

  function _safeErc20Transfer(address head, address to, uint256 amount) private {
    (bool success, bytes memory returndata) = HydraHead(head).call(
      address(token),
      0,
      abi.encodeCall(IERC20.transfer, (to, amount))
    );
    require(success, "not enough tokens");
    _checkReturnData(returndata);
  }

  function _safeErc20TransferFrom(address head, address from, address to, uint256 amount) private {
    (bool success, bytes memory returndata) = HydraHead(head).call(
      address(token),
      0,
      abi.encodeCall(IERC20.transferFrom, (from, to, amount))
    );
    require(success, "not enough allowed tokens");
    _checkReturnData(returndata);
  }

  function _checkReturnData(bytes memory returndata) private pure {
    if (returndata.length > 0) {
      require(returndata.length == 32, "data length should be either 0 or 32 bytes");
      require(abi.decode(returndata, (bool)), "not enough allowed tokens. Token returns false.");
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./utils/MerkleTree.sol";
import "./utils/IVerifier.sol";
import "./HydraBody.sol";

library Hasher {
  // function MiMCSponge(uint256 in_xL, uint256 in_xR) public pure returns (uint256 xL, uint256 xR);
  function MiMCSponge(uint256 in_xL, uint256 in_xR) internal pure returns (uint256 xL, uint256 xR) { return (0, 0); }
}

abstract contract Hydra is HydraBody, Ownable, ReentrancyGuard {
  using MerkleTree for MerkleTree.TreeWithHistory;

  uint256 public constant FIELD_SIZE = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
  uint256 public constant ZERO_VALUE = 21663839004416932945382355908790599225266501822907911457504978515578255421292;

  IVerifier public verifier;

  MerkleTree.TreeWithHistory private tree;
  mapping(bytes32 => bool) public commitments;
  mapping(bytes32 => bool) public nullifierHashes;
  uint256 immutable public denomination;

  event Deposit(bytes32 indexed commitment, uint32 leafIndex, uint256 timestamp);
  event Withdrawal(address to, bytes32 nullifierHash, address indexed relayer, uint256 fee);

  constructor(IVerifier _verifier, uint256 _denomination, uint32 _merkleTreeHeight)
  {
    require(_denomination > 0, "denomination should be greater than 0");
    tree.initialize(_merkleTreeHeight, 100, bytes32(ZERO_VALUE), hashLeftRight);
    verifier = _verifier;
    denomination = _denomination;
  }

  function deposit(bytes32 _commitment) external payable nonReentrant {
    _deposit(_commitment, bytes32(0));
  }

  function deposit(bytes32 _commitment, bytes32 _salt) external payable nonReentrant {
    _deposit(_commitment, _salt);
  }

  function _deposit(bytes32 _commitment, bytes32 _salt) internal {
    // Track commitments
    require(!commitments[_commitment], "The commitment has been submitted");
    commitments[_commitment] = true;

    // Add commitment to merkle tree
    uint32 insertedIndex = tree.insert(_commitment);

    // Process deposit
    _processDeposit(_salt);

    // Emit event
    emit Deposit(_commitment, insertedIndex, block.timestamp);
  }

  function withdraw(
    bytes calldata  _proof,
    bytes32         _root,
    bytes32         _nullifierHash,
    address payable _recipient,
    address payable _relayer,
    uint256         _fee,
    uint256         _refund
  ) external payable nonReentrant {
    // Sanity shecks
    require(_fee <= denomination, "Fee exceeds transfer value");

    // Track nullifiers
    require(!nullifierHashes[_nullifierHash], "The note has been already spent");
    nullifierHashes[_nullifierHash] = true;

    // Validate root & proof
    require(tree.isKnownRoot(_root), "Cannot find your merkle root");
    require(
      verifier.verifyProof(
        _proof,
        [
          uint256(_root),
          uint256(_nullifierHash),
          uint256(uint160(address(_recipient))),
          uint256(uint160(address(_relayer))),
          _fee,
          _refund
        ]
      ),
      "Invalid withdraw proof"
    );

    // Process withdraw
    _processWithdraw(_recipient, _relayer, _fee, _refund);

    // Emit event
    emit Withdrawal(_recipient, _nullifierHash, _relayer, _fee);
  }

  // Accessors
  function isSpent(bytes32 _nullifierHash) external view returns (bool) {
    return nullifierHashes[_nullifierHash];
  }

  function isSpentArray(bytes32[] calldata _nullifierHashes) external view returns (bool[] memory spent) {
    spent = new bool[](_nullifierHashes.length);
    for(uint i = 0; i < _nullifierHashes.length; ++i) {
      spent[i] = nullifierHashes[_nullifierHashes[i]];
    }
  }

  function isKnownRoot(bytes32 root) external view returns (bool) {
    return tree.isKnownRoot(root);
  }

  function nextIndex() external view returns (uint32) {
    return tree.nextLeafIndex;
  }

  // Setup (ownership should be renounced before the contract is used)
  function updateVerifier(address _newVerifier) external onlyOwner {
    verifier = IVerifier(_newVerifier);
  }

  // Internal hooks
  function _processDeposit(bytes32 _salt) internal virtual;
  function _processWithdraw(address payable _recipient, address payable _relayer, uint256 _fee, uint256 _refund) internal virtual;

  // Hash
  function hashLeftRight(bytes32 left, bytes32 right) private pure returns (bytes32) {
    require(uint256(left) < FIELD_SIZE, "left should be inside the field");
    require(uint256(right) < FIELD_SIZE, "right should be inside the field");
    uint256 R = uint256(left);
    uint256 C = 0;
    (R, C) = Hasher.MiMCSponge(R, C);
    R = addmod(R, uint256(right), FIELD_SIZE);
    (R, C) = Hasher.MiMCSponge(R, C);
    return bytes32(R);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./HydraHead.sol";

contract HydraBody {
  address immutable internal template = address(new HydraHead());
  address internal vault;

  event NewVault(address vault);

  constructor() {
    // use the template for the initial vault
    vault = template;
    emit NewVault(template);
  }

  function predictHead(bytes32 salt) public view virtual returns (address) {
    return Clones.predictDeterministicAddress(template, salt);
  }

  function fetchHead(bytes32 salt) public virtual returns (address) {
    address instance = predictHead(salt);
    if (!Address.isContract(instance)) {
      Clones.cloneDeterministic(template, salt);
    }
    return instance;
  }

  function rotateVault() public virtual returns (address) {
    address oldVault = vault;
    // create new pseudo-random vault
    address newVault = fetchHead(keccak256(abi.encode(oldVault, block.difficulty)));
    // hook: should transfer treasure from the old vault to the new one
    _onVaultRotation(oldVault, newVault);
    // save new vault address
    vault = newVault;
    // emit event
    emit NewVault(vault);
    return newVault;
  }

  function _onVaultRotation(address, address) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IVerifier {
  function verifyProof(bytes memory _proof, uint256[6] memory _input) external returns(bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

error Full();

library MerkleTree {
  uint8 private constant MAX_DEPTH = 32;

  struct TreeWithHistory {
    function(bytes32,bytes32) view returns(bytes32) fnHash;
    uint32 depth;
    uint32 length;
    uint32 currentRootIndex;
    uint32 nextLeafIndex;
    bytes32[MAX_DEPTH] filledSubtrees;
    bytes32[MAX_DEPTH] zeros;
    bytes32[2**MAX_DEPTH] roots;
  }

  /**
   * @dev Initialize a new complete MerkleTree defined by:
   * - Depth `depth`
   * - All leaves are initialize to `zero`
   * - Hashing function for a pair of leaves is fnHash
   * and keep a root history of length `length` when leaves are inserted.
   */
  function initialize(
    TreeWithHistory storage self,
    uint32 depth,
    uint32 length,
    bytes32 zero,
    function(bytes32,bytes32) view returns(bytes32) fnHash
  ) internal {
    require(depth <= MAX_DEPTH);

    self.depth = depth;
    self.length = length;
    self.fnHash = fnHash;

    bytes32 currentZero = zero;
    for (uint32 i = 0; i < depth; ++i) {
      self.zeros[i] = self.filledSubtrees[i] = currentZero;
      currentZero = fnHash(currentZero, currentZero);
    }

    // Insert the first root
    self.roots[0] = currentZero;
  }

  /**
   * @dev Insert a new leaf in the tree, compute the new root, and store that new root in the history.
   *
   * WARNING:
   *
   * For depth < 32, reverts if the MerkleTree is already full.
   * For depth = 32, revert when trying to populate the last leaf.
   *
   * Trees with depth < 32 can include `2 ** depth` entries
   * Trees with depth = 32 can include `2 ** depth - 1` entries
   */
  function insert(TreeWithHistory storage self, bytes32 leaf) internal returns (uint32) {
    // cache read
    uint32 depth = self.depth;

    // Get leaf index
    uint32 leafIndex = self.nextLeafIndex++;

    // Check if tree is full.
    if (leafIndex == 1 << depth) revert Full();

    // Rebuild branch from leaf to root
    uint32 currentIndex = leafIndex;
    bytes32 currentLevelHash = leaf;
    for (uint32 i = 0; i < depth; i++) {
      // Reaching the parent node, is currentLevelHash the left child?
      bool isLeft = currentIndex % 2 == 0;

      // If so, next time we will come from the right, so we need to save it
      if (isLeft) {
        self.filledSubtrees[i] = currentLevelHash;
      }

      // Compute the node hash by hasing the current hash with either:
      // - the last value for this level
      // - the zero for this level
      currentLevelHash = self.fnHash(
        isLeft ? currentLevelHash : self.filledSubtrees[i],
        isLeft ? self.zeros[i]    : currentLevelHash
      );

      // update node index
      currentIndex >>= 1;
    }

    // Record new root
    self.currentRootIndex = (self.currentRootIndex + 1) % self.length;
    self.roots[self.currentRootIndex] = currentLevelHash;

    return leafIndex;
  }

  /**
   * @dev Return the current root of the tree.
   */
  function getLastRoot(TreeWithHistory storage self) internal view returns(bytes32) {
    return self.roots[self.currentRootIndex];
  }

  /**
   * @dev Look in root history,
   */
  function isKnownRoot(TreeWithHistory storage self, bytes32 root) internal view returns(bool) {
    if (root == 0) {
      return false;
    }

    // cache as uint256 (avoid overflow)
    uint256 currentRootIndex = self.currentRootIndex;
    uint256 length = self.length;

    // search
    for (uint256 i = length; i > 0; --i) {
      if (root == self.roots[(currentRootIndex + i) % length]) {
        return true;
      }
    }

    return false;
  }

  // Default hash
  function initialize(TreeWithHistory storage self, uint32 depth, uint32 length) internal {
    return initialize(self, depth, length, bytes32(0), _hashPair);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

error Unauthorized();

contract HydraHead {
  address immutable internal body = msg.sender;

  function call(address target, uint256 value, bytes calldata data) external returns (bool success, bytes memory returndata) {
    if (msg.sender != body) revert Unauthorized();
    return target.call{ value: value}(data);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}