// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./Sacred.sol";

interface AddressesProvider {
    function getPool()
    external
    view
    returns (address);
}

interface WETHGateway {
    function depositETH(address lendingPool, address onBehalfOf, uint16 referralCode)
    external
    payable;
    
    function withdrawETH(address lendingPool, uint256 amount, address to)
    external;
}

interface AToken {
  function balanceOf(address _user) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
  function transfer(address receiver, uint256 amount) external returns (bool);
}

contract ETHSacred is Sacred {

  address public lendingPoolAddressProvider;
  address public wETHGateway;
  address public wETHToken;
  uint256 private collateralAmount;
  uint256 public totalAaveInterests;
  address public aaveInterestsProxy;

  constructor (
    IVerifier _verifier,
    uint256 _denomination,
    uint32 _merkleTreeHeight,
    address _lendingPoolAddressProvider,
    address _wETHGateway,
    address _wETHToken,
    address _owner,
    uint256 _fee
  ) Sacred(_verifier, _denomination, _merkleTreeHeight, _owner, _fee) {
    lendingPoolAddressProvider = _lendingPoolAddressProvider;
    wETHGateway = _wETHGateway;
    wETHToken = _wETHToken;
  }

  function _processDeposit() internal override {
    require(msg.value == denomination, "Please send `mixDenomination` ETH along with transaction");
    address lendingPool = AddressesProvider(lendingPoolAddressProvider).getPool();
    WETHGateway(wETHGateway).depositETH{value:denomination}(lendingPool, address(this), 0);
    collateralAmount += denomination;
    collectAaveInterests();
  }

  function _processWithdraw(address payable _recipient, address payable _relayer, uint256 _fee, uint256 _refund) internal override {
    // sanity checks
    require(msg.value == 0, "Message value is supposed to be zero for ETH instance");
    require(_refund == 0, "Refund value is supposed to be zero for ETH instance");

    address lendingPool = AddressesProvider(lendingPoolAddressProvider).getPool();
    uint256 operatorFee = denomination * fee / 10000;
    require(AToken(wETHToken).approve(wETHGateway, denomination), "aToken approval failed");
    WETHGateway(wETHGateway).withdrawETH(lendingPool, denomination - operatorFee - _fee, _recipient);

    if (operatorFee > 0) {
      WETHGateway(wETHGateway).withdrawETH(lendingPool, operatorFee, owner);
    }

    if (_fee > 0) {
      WETHGateway(wETHGateway).withdrawETH(lendingPool, _fee, _relayer);
    }
    collateralAmount -= denomination;
    collectAaveInterests();
  }

  function setAaveInterestsProxy(address _aaveInterestsProxy) external onlyOwner {
    aaveInterestsProxy = _aaveInterestsProxy;
  }

  function collectAaveInterests() private {
    uint256 interests = AToken(wETHToken).balanceOf(address(this)) - collateralAmount;
    if(interests > 0 && aaveInterestsProxy != address(0)) {
      address lendingPool = AddressesProvider(lendingPoolAddressProvider).getPool();
      require(AToken(wETHToken).approve(wETHGateway, interests), "aToken approval failed");
      WETHGateway(wETHGateway).withdrawETH(lendingPool, interests, aaveInterestsProxy);
      totalAaveInterests += interests;
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./MerkleTreeWithHistory.sol";
import "./TwoStepOwnerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface IVerifier {
  function verifyProof(bytes memory _proof, uint256[6] memory _input) external returns(bool);
}

abstract contract Sacred is MerkleTreeWithHistory, ReentrancyGuard, TwoStepOwnerable {
  uint256 public denomination;
  mapping(bytes32 => bool) public nullifierHashes;
  // we store all commitments just to prevent accidental deposits with the same commitment
  mapping(bytes32 => bool) public commitments;
  IVerifier public verifier;

  // operator can update snark verification key
  // after the final trusted setup ceremony operator rights are supposed to be transferred to zero address
  uint256 public fee = 50; // 0.5%, 50 / 10000, value: 0, 1 (0.01%),~ 1000 (10%)

  event Deposit(bytes32 indexed commitment, uint32 leafIndex, uint256 timestamp);
  event Withdrawal(address to, bytes32 nullifierHash, address indexed relayer, uint256 fee);

  /**
    @dev The constructor
    @param _verifier the address of SNARK verifier for this contract
    @param _denomination transfer amount for each deposit
    @param _merkleTreeHeight the height of deposits' Merkle Tree
    @param _owner operator address (see operator comment above)
  */
  constructor(
    IVerifier _verifier,
    uint256 _denomination,
    uint32 _merkleTreeHeight,
    address _owner,
    uint256 _fee
  ) MerkleTreeWithHistory(_merkleTreeHeight) TwoStepOwnerable(_owner) {
    require(_denomination > 0, "denomination should be greater than 0");
    verifier = _verifier;
    denomination = _denomination;
    fee = _fee;
  }

  /**
    @dev Set fee
    @param _fee fee amount that is sent to operator when user withdraw
  */
  function setFee(uint256 _fee) external onlyOwner {
    require(_fee <= 1000, "Operator fee has to be smaller than 10%");
    fee = _fee;
  }

  /**
    @dev Deposit funds into the contract. The caller must send (for ETH) or approve (for ERC20) value equal to or `denomination` of this instance.
    @param _commitment the note commitment, which is PedersenHash(nullifier + secret)
  */
  function deposit(bytes32 _commitment) external payable nonReentrant {
    require(!commitments[_commitment], "The commitment has been submitted");

    uint32 insertedIndex = _insert(_commitment);
    commitments[_commitment] = true;
    _processDeposit();

    emit Deposit(_commitment, insertedIndex, block.timestamp);
  }

  /** @dev this function is defined in a child contract */
  function _processDeposit() internal virtual;

  /**
    @dev Withdraw a deposit from the contract. `proof` is a zkSNARK proof data, and input is an array of circuit public inputs
    `input` array consists of:
      - merkle root of all deposits in the contract
      - hash of unique deposit nullifier to prevent double spends
      - the recipient of funds
      - optional fee that goes to the transaction sender (usually a relay)
  */
  function withdraw(bytes calldata _proof, bytes32 _root, bytes32 _nullifierHash, address payable _recipient, address payable _relayer, uint256 _fee, uint256 _refund) external payable nonReentrant {
    require(_fee <= denomination, "Fee exceeds transfer value");
    require(!nullifierHashes[_nullifierHash], "The note has been already spent");
    require(isKnownRoot(_root), "Cannot find your merkle root"); // Make sure to use a recent one
    require(verifier.verifyProof(_proof, [uint256(_root), uint256(_nullifierHash), uint256(uint160(address(_recipient))), uint256(uint160(address(_relayer))), _fee, _refund]), "Invalid withdraw proof");

    nullifierHashes[_nullifierHash] = true;
    _processWithdraw(_recipient, _relayer, _fee, _refund);
    emit Withdrawal(_recipient, _nullifierHash, _relayer, _fee);
  }

  /** @dev this function is defined in a child contract */
  function _processWithdraw(address payable _recipient, address payable _relayer, uint256 _fee, uint256 _refund) internal virtual;

  /** @dev whether a note is already spent */
  function isSpent(bytes32 _nullifierHash) public view returns(bool) {
    return nullifierHashes[_nullifierHash];
  }

  /** @dev whether an array of notes is already spent */
  function isSpentArray(bytes32[] calldata _nullifierHashes) external view returns(bool[] memory spent) {
    spent = new bool[](_nullifierHashes.length);
    for(uint i = 0; i < _nullifierHashes.length; ++i) {
      if (isSpent(_nullifierHashes[i])) {
        spent[i] = true;
      }
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

library Hasher {
  function poseidon(bytes32[2] memory input) public pure returns (bytes32){}
}

contract MerkleTreeWithHistory {
  uint256 public constant FIELD_SIZE = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
  uint256 public constant ZERO_VALUE = 21663839004416932945382355908790599225266501822907911457504978515578255421292; // = keccak256("sacred") % FIELD_SIZE

  uint32 public levels;

  // the following variables are made public for easier testing and debugging and
  // are not supposed to be accessed in regular code
  bytes32[] public filledSubtrees;
  bytes32[] public zeros;
  uint32 public currentRootIndex = 0;
  uint32 public nextIndex = 0;
  uint32 public constant ROOT_HISTORY_SIZE = 100;
  bytes32[ROOT_HISTORY_SIZE] public roots;

  constructor(uint32 _treeLevels) {
    require(_treeLevels > 0, "_treeLevels should be greater than zero");
    require(_treeLevels < 32, "_treeLevels should be less than 32");
    levels = _treeLevels;

    bytes32 currentZero = bytes32(ZERO_VALUE);
    zeros.push(currentZero);
    filledSubtrees.push(currentZero);

    for (uint32 i = 1; i < levels; ++i) {
      currentZero = hashLeftRight(currentZero, currentZero);
      zeros.push(currentZero);
      filledSubtrees.push(currentZero);
    }

    roots[0] = hashLeftRight(currentZero, currentZero);
  }

  /**
    @dev Hash 2 tree leaves, returns MiMC(_left, _right)
  */
  function hashLeftRight(bytes32 _left, bytes32 _right) public pure returns (bytes32) {
    require(uint256(_left) < FIELD_SIZE, "_left should be inside the field");
    require(uint256(_right) < FIELD_SIZE, "_right should be inside the field");
    return Hasher.poseidon([_left, _right]);
  }

  function _insert(bytes32 _leaf) internal returns(uint32 index) {
    uint32 currentIndex = nextIndex;
    require(currentIndex != uint32(2)**levels, "Merkle tree is full. No more leafs can be added");
    nextIndex += 1;
    bytes32 currentLevelHash = _leaf;
    bytes32 left;
    bytes32 right;

    for (uint32 i = 0; i < levels; ++i) {
      if (currentIndex % 2 == 0) {
        left = currentLevelHash;
        right = zeros[i];

        filledSubtrees[i] = currentLevelHash;
      } else {
        left = filledSubtrees[i];
        right = currentLevelHash;
      }

      currentLevelHash = hashLeftRight(left, right);

      currentIndex /= 2;
    }

    currentRootIndex = (currentRootIndex + 1) % ROOT_HISTORY_SIZE;
    roots[currentRootIndex] = currentLevelHash;
    return nextIndex - 1;
  }

  /**
    @dev Whether the root is present in the root history
  */
  function isKnownRoot(bytes32 _root) public view returns(bool) {
    if (_root == 0) {
      return false;
    }
    uint32 i = currentRootIndex;
    do {
      if (_root == roots[i]) {
        return true;
      }
      if (i == 0) {
        i = ROOT_HISTORY_SIZE;
      }
      i--;
    } while (i != currentRootIndex);
    return false;
  }

  /**
    @dev Returns the last root
  */
  function getLastRoot() public view returns(bytes32) {
    return roots[currentRootIndex];
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

abstract contract TwoStepOwnerable {
  address internal owner;
  address private invited;
	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
	
  modifier onlyOwner() {
    require(msg.sender == owner, "Not authorized");
    _;
  }

  modifier onlyInvited() {
  	require(msg.sender == invited, "Not authorized");
    _;
  }

  constructor(address _owner) {
    owner = _owner;
  }
  
  function transferOwnership(address newOwner) public onlyOwner {
	  require(newOwner != address(0), "owner cannot be zero address");
  	invited = newOwner;
  }
  
  function ownershipAccepted() public onlyInvited {
	  _transferOwnership(msg.sender);
  	invited = address(0);
  }

  function revokeInvitation() public onlyOwner {
    invited = address(0);
  }
  
  function renounceOwnership() public onlyOwner {
    _transferOwnership(address(0));
  }
  
  function _transferOwnership(address newOwner) internal {
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
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