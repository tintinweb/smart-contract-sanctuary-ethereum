/**
 *Submitted for verification at Etherscan.io on 2023-03-16
*/

/**
 *Submitted for verification at Etherscan.io on 2023-03-08
*/

pragma solidity 0.5.17;

interface Hasher {
  function MiMCSponge(uint256 in_xL, uint256 in_xR) external pure returns (uint256 xL, uint256 xR);
}

interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}

contract ReentrancyGuard {
    uint256 private _guardCounter;

    constructor () internal {
    
        _guardCounter = 1;
    }


    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter, "ReentrancyGuard: reentrant call");
    }
}

contract MerkleTreeWithHistory {
  uint256  constant FIELD_SIZE = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
  uint256  constant ZERO_VALUE = 21663839004416932945382355908790599225266501822907911457504978515578255421292;

  uint32  levels;

  bytes32[]  filledSubtrees;
  bytes32[]  zeros;
  uint32  currentRootIndex = 0;
  uint32  nextIndex = 0;
  uint32  constant ROOT_HISTORY_SIZE = 100;
  bytes32[ROOT_HISTORY_SIZE]  roots;

  constructor(uint32 _treeLevels) public {
    require(_treeLevels > 0, "_treeLevels should be greater than zero");
    require(_treeLevels < 32, "_treeLevels should be less than 32");
    levels = _treeLevels;

    bytes32 currentZero = bytes32(ZERO_VALUE);
    zeros.push(currentZero);
    filledSubtrees.push(currentZero);

    for (uint32 i = 1; i < levels; i++) {
      currentZero = hashLeftRight(currentZero, currentZero);
      zeros.push(currentZero);
      filledSubtrees.push(currentZero);
    }

    roots[0] = hashLeftRight(currentZero, currentZero);
  }


  function hashLeftRight(bytes32 _left, bytes32 _right) public pure returns (bytes32) {
    require(uint256(_left) < FIELD_SIZE, "_left should be inside the field");
    require(uint256(_right) < FIELD_SIZE, "_right should be inside the field");
    uint256 R = uint256(_left);
    uint256 C = 0;
      (R, C) = Hasher(0x6B9f36435A64c974E46e669870dcA5A15AfFbe81).MiMCSponge(R, C);
    R = addmod(R, uint256(_right), FIELD_SIZE);
      (R, C) = Hasher(0x6B9f36435A64c974E46e669870dcA5A15AfFbe81).MiMCSponge(R, C);
    return bytes32(R);
  }

  function _insert(bytes32 _leaf) internal returns(uint32 index) {
    uint32 currentIndex = nextIndex;
    require(currentIndex != uint32(2)**levels, "Merkle tree is full. No more leafs can be added");
    nextIndex += 1;
    bytes32 currentLevelHash = _leaf;
    bytes32 left;
    bytes32 right;

    for (uint32 i = 0; i < levels; i++) {
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


  function getLastRoot() public view returns(bytes32) {
    return roots[currentRootIndex];
  }
}

contract IVerifier {
  function verifyProof(bytes memory _proof, uint256[6] memory _input) public returns(bool);
}

contract ZKInu is MerkleTreeWithHistory, ReentrancyGuard {
  uint256 public denomination;
  mapping(bytes32 => bool)  nullifierHashes;
  mapping(bytes32 => bool)  commitments;
  IVerifier public verifier;
  
  uint256 public deposit_fee = 0;
  uint256 public withdraw_fee = 5;

  uint256 public split1_fee = 50;
  uint256 public split2_fee = 50;

  address payable fee_reciever_1; 
  address payable fee_reciever_2;

  address payable public operator;
  modifier onlyOperator {
    require(msg.sender == operator, "Only operator can call this function.");
    _;
  }


  event Deposit(bytes32 indexed commitment, uint32 leafIndex, uint256 timestamp);
  event Withdrawal(address to, bytes32 nullifierHash, address indexed relayer, uint256 fee);

 
  constructor(
    IVerifier _verifier,
    uint256 _denomination,
    uint32 _merkleTreeHeight,
    address payable _operator
  ) MerkleTreeWithHistory(_merkleTreeHeight) public {
    require(_denomination > 0, "denomination should be greater than 0");
    verifier = _verifier;
    operator = _operator;
    denomination = _denomination;
  }

function isContract(address _addr) private returns (bool isContract){
  uint32 size;
  assembly {
    size := extcodesize(_addr)
  }
  return (size > 0);
}

  function setDepositFee(uint256 fee) public onlyOperator{
    require(fee < 6, "Deposit fee cannot exceed 6%");
    deposit_fee = fee;
  }

  function editDenomination(uint256 _denomination) public onlyOperator{
    denomination = _denomination;
  }

  function setWithdrawFee(uint256 fee) public onlyOperator {
    require(fee < 6, "Withdraw fee cannot exceed 6%");
    withdraw_fee = fee;
  }

  function setSplitFees(uint256 f1, uint256 f2) public onlyOperator {
    require(f1 + f2 == 100, "Total is not equal to 100");

  }

  function setFeesRecievers(address payable f1, address payable f2) public onlyOperator {
      fee_reciever_1 = f1;
      fee_reciever_2 = f2;
  }

  function deposit(bytes32 _commitment) external payable nonReentrant {
    require(!commitments[_commitment], "The commitment has been submitted");

    uint32 insertedIndex = _insert(_commitment);
    commitments[_commitment] = true;
    _processDeposit();
    
    if(deposit_fee > 0){
      uint256 fee_amount = msg.value * deposit_fee / 100;
      fee_reciever_1.transfer(fee_amount * split1_fee / 100);
      fee_reciever_2.transfer(fee_amount * split2_fee / 100);
    }

    emit Deposit(_commitment, insertedIndex, block.timestamp);
  }

  function _processDeposit() internal;

  function withdraw(bytes calldata _proof, bytes32 _root, bytes32 _nullifierHash, address payable _recipient, address payable _relayer, uint256 _fee, uint256 _refund) external payable nonReentrant {
    require(_fee <= denomination, "Fee exceeds transfer value");
    require(!nullifierHashes[_nullifierHash], "The note has been already spent");
    require(isKnownRoot(_root), "Cannot find your merkle root"); // Make sure to use a recent one
    require(!isContract(msg.sender), "Relayer Protection"); 

    require(verifier.verifyProof(_proof, [uint256(_root), uint256(_nullifierHash), uint256(_recipient), uint256(_relayer), _fee, _refund]), "Invalid withdraw proof");


    nullifierHashes[_nullifierHash] = true;
    _processWithdraw(_recipient, _relayer, _fee, _refund);
    emit Withdrawal(_recipient, _nullifierHash, _relayer, _fee);
  }

  function _processWithdraw(address payable _recipient, address payable _relayer, uint256 _fee, uint256 _refund) internal;

  function isSpent(bytes32 _nullifierHash) public view returns(bool) {
    return nullifierHashes[_nullifierHash];
  }

  function isSpentArray(bytes32[] calldata _nullifierHashes) external view returns(bool[] memory spent) {
    spent = new bool[](_nullifierHashes.length);
    for(uint i = 0; i < _nullifierHashes.length; i++) {
      if (isSpent(_nullifierHashes[i])) {
        spent[i] = true;
      }
    }
  }

 
  function updateVerifier(address _newVerifier) external onlyOperator {
    verifier = IVerifier(_newVerifier);
  }

  function changeOperator(address payable _newOperator) external onlyOperator {
    operator = _newOperator;
  }
}

contract ZKInu_ERC is ZKInu {

  IERC20 mixed_token;

  constructor(
    IVerifier _verifier,
    uint256 _denomination,
    uint32 _merkleTreeHeight,
    address token,
    address payable _operator
  ) ZKInu(_verifier, _denomination, _merkleTreeHeight, _operator) public {
    mixed_token = IERC20(token);
  }


  function _processDeposit() internal {
    require(mixed_token.transferFrom(msg.sender, address(this), denomination), "Please send `mixDenomination` of the native asset along with transaction");
  }

  function _processWithdraw(address payable _recipient, address payable _relayer, uint256 _fee, uint256 _refund) internal {
    require(msg.value == 0, "Message value is supposed to be zero for native asset instance");
    require(_refund == 0, "Refund value is supposed to be zero for native asset instance");
        if(withdraw_fee > 0){
            uint256 fee_amount = denomination * withdraw_fee / 100;
            mixed_token.transfer(fee_reciever_1, fee_amount * split1_fee / 100);
           mixed_token.transfer(fee_reciever_2, fee_amount * split2_fee / 100);

          
      (bool success) = mixed_token.transfer(_recipient, denomination - fee_amount);
    require(success, "payment to _recipient did not go thru");
    if (_fee > 0) {
      (success, ) = _relayer.call.value(_fee)("");
      require(success, "payment to _relayer did not go thru");
    }
        }else{
      (bool success) = mixed_token.transfer(_recipient, denomination);
    require(success, "payment to _recipient did not go thru");
    if (_fee > 0) {
      (success, ) = _relayer.call.value(_fee)("");
      require(success, "payment to _relayer did not go thru");
    }
        }

    
  }
}