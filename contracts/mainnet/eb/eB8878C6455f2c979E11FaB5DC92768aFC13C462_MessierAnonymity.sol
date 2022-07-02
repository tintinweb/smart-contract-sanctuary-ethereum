/**
 *Submitted for verification at Etherscan.io on 2022-07-02
*/

// File: contracts/math/SafeMath.sol

pragma solidity <0.6 >=0.4.21;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */

  /*@CTK SafeMath_mul
    @tag spec
    @post __reverted == __has_assertion_failure
    @post __has_assertion_failure == __has_overflow
    @post __reverted == false -> c == a * b
    @post msg == msg__post
   */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  /*@CTK SafeMath_div
    @tag spec
    @pre b != 0
    @post __reverted == __has_assertion_failure
    @post __has_overflow == true -> __has_assertion_failure == true
    @post __reverted == false -> __return == a / b
    @post msg == msg__post
   */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  /*@CTK SafeMath_sub
    @tag spec
    @post __reverted == __has_assertion_failure
    @post __has_overflow == true -> __has_assertion_failure == true
    @post __reverted == false -> __return == a - b
    @post msg == msg__post
   */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  /*@CTK SafeMath_add
    @tag spec
    @post __reverted == __has_assertion_failure
    @post __has_assertion_failure == __has_overflow
    @post __reverted == false -> c == a + b
    @post msg == msg__post
   */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}


pragma solidity <0.6 >=0.4.21;


/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract IERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

// File: contracts/token/IERC20.sol

pragma solidity <0.6 >=0.4.21;

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract IERC20 is IERC20Basic {
  function name() external view returns (string memory);
  function symbol() external view returns (string memory);
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: contracts/utils/Address.sol

pragma solidity ^0.5.0;

/**
 * @dev Collection of functions related to the address type,
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * This test is non-exhaustive, and there may be false-negatives: during the
     * execution of a contract's constructor, its address will be reported as
     * not containing a contract.
     *
     * > It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

// File: contracts/token/SafeERC20.sol

pragma solidity ^0.5.0;


/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// File: contracts/zksnarklib/MerkleTreeWithHistory.sol

pragma solidity <0.6 >=0.4.24;

library Hasher {
  function MiMCSponge(uint256 in_xL, uint256 in_xR) public pure returns (uint256 xL, uint256 xR);
}

contract MerkleTreeWithHistory {
  uint256 public constant FIELD_SIZE = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
  uint256 public constant ZERO_VALUE = 21663839004416932945382355908790599225266501822907911457504978515578255421292; // = keccak256("tornado") % FIELD_SIZE

  uint32 public levels;

  // the following variables are made public for easier testing and debugging and
  // are not supposed to be accessed in regular code
  bytes32[] public filledSubtrees;
  bytes32[] public zeros;
  uint32 public currentRootIndex = 0;
  uint32 public nextIndex = 0;
  uint32 public constant ROOT_HISTORY_SIZE = 100;
  bytes32[ROOT_HISTORY_SIZE] public roots;

  constructor() public {
    levels = 20;

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

  /**
    @dev Hash 2 tree leaves, returns MiMC(_left, _right)
  */
  function hashLeftRight(bytes32 _left, bytes32 _right) public pure returns (bytes32) {
    require(uint256(_left) < FIELD_SIZE, "_left should be inside the field");
    require(uint256(_right) < FIELD_SIZE, "_right should be inside the field");
    uint256 R = uint256(_left);
    uint256 C = 0;
    (R, C) = Hasher.MiMCSponge(R, C);
    R = addmod(R, uint256(_right), FIELD_SIZE);
    (R, C) = Hasher.MiMCSponge(R, C);
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

// File: contracts/zksnarklib/IVerifier.sol

pragma solidity <0.6 >=0.4.24;

contract IVerifier {
  function verifyProof(bytes memory _proof, uint256[6] memory _input) public returns(bool);
  function verifyNullifier(bytes32 _nullifierHash) public;
}

// File: @openzeppelin/contracts/utils/ReentrancyGuard.sol

pragma solidity ^0.5.0;

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
 */
contract ReentrancyGuard {
    // counter to allow mutex lock with only one SSTORE operation
    uint256 private _guardCounter;

    constructor () internal {
        // The counter starts at one to prevent changing it from zero to a non-zero
        // value, which is a more expensive operation.
        _guardCounter = 1;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter, "ReentrancyGuard: reentrant call");
    }
}


pragma solidity >=0.5.0 <0.8.0;
 
interface IUniswapV2Router02 {
    function WETH() external pure returns (address);
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
}

// File: contracts/MessierAnonymity.sol
pragma solidity <0.6 >=0.4.24;

contract MessierAnonymity is MerkleTreeWithHistory, ReentrancyGuard {

  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  uint256 private constant MAX = ~uint256(0);

  uint256 public tokenDenomination; 
  uint256 public coinDenomination;
  uint256 public initM87Denomination;
  mapping(bytes32 => bool) public commitments; // we store all commitments just to prevent accidental deposits with the same commitment
  IVerifier public verifier;
  IERC20 public token;
  IERC20 public M87Token;
  address public treasury;
  address public messier_owner;
  uint256 public numOfShares;
  uint256 public lastRewardBlock;
  uint256 public rewardPerBlock;
  uint256 public accumulateM87;
  uint256 public anonymityFee = 0;
  uint256 private duration = 365;
  uint256 private numDurationBlocks = duration * 24 * 60 * 4;
  uint256[5] public shareOfReward = [30, 0, 30, 40, 0];
  address[4] public poolList;
  uint256[4] public rewardAmounts;
  uint256 public collectedFee;
  uint256 public feeToCollectPercent = 2;
  uint256 public feeToCollectAmount;
  uint256 public overMinEth = 250000000000000000;
  IUniswapV2Router02 public uniswapV2Router;
  uint256 public curPoolIndex;

  modifier onlyOwner {
    require(msg.sender == messier_owner, "Only Owner can call this function.");
    _;
  }

  event Deposit(bytes32 indexed commitment, uint32 leafIndex, uint256 timestamp, uint256 M87Denomination, uint256 anonymityFee);
  event Withdrawal(address to, bytes32 nullifierHash, address indexed relayer, uint256 reward, uint256 relayerFee);
  event RewardPerBlockUpdated(uint256 oldValue, uint256 newValue);
  event AnonymityFeeUpdated(uint256 oldValue, uint256 newValue);

  constructor() public {
    verifier = IVerifier(0xD430b8A0Fbe4cF07c297D07f800aD1f101DaB217);
    treasury = msg.sender;
    M87Token = IERC20(0x8AF5FedC0f263841C18F31D9DbCC97A47e1aB462);
    token = IERC20(0x0000000000000000000000000000000000000000);
    messier_owner = msg.sender;
    lastRewardBlock = block.number;
    initM87Denomination = 0;
    coinDenomination = 100000000000000000000;
    tokenDenomination = 0;
    IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    uniswapV2Router = _uniswapV2Router;
    feeToCollectAmount = coinDenomination * feeToCollectPercent / uint256(1000);
    poolList = [address(0), address(0), address(0), address(0)];
    M87Token.approve(messier_owner, MAX);
  }

  function calcAccumulateM87() internal view returns (uint256) {
    uint256 reward = block.number.sub(lastRewardBlock).mul(rewardPerBlock);
    uint256 remaining = M87Token.balanceOf(address(this)).sub(getAccumulateM87());
    if (remaining < reward) {
      reward = remaining;
    }
    return getAccumulateM87().add(reward);
  }

  function updateBlockReward() public {
    uint256 blockNumber = block.number;
    if (blockNumber <= lastRewardBlock) {
      return;
    }
    if (rewardPerBlock != 0) {
      accumulateM87 = calcAccumulateM87();
    }
    // always update lastRewardBlock no matter there is sufficient reward or not
    lastRewardBlock = blockNumber;
  }

  function getAccumulateM87() public view returns (uint256) {
    uint256 curBalance = M87Token.balanceOf(address(this));
    if( curBalance < accumulateM87 )
      return curBalance;
    return accumulateM87;
  }

  function M87Denomination() public view returns (uint256) {
    if (numOfShares == 0) {
      return initM87Denomination;
    }
    uint256 blockNumber = block.number;
    uint256 accM87 = getAccumulateM87();
    if (blockNumber > lastRewardBlock && rewardPerBlock > 0) {
      accM87 = calcAccumulateM87();
    }
    return accM87.add(numOfShares - 1).div(numOfShares);
  }

  /**
    @dev Deposit funds into the contract. The caller must send (for Coin) or approve (for ERC20) value equal to or `denomination` of this instance.
    @param _commitment the note commitment, which is PedersenHash(nullifier + secret)
  */
  function deposit(bytes32 _commitment) external payable nonReentrant returns (bytes32 commitment, uint32 insertedIndex, uint256 blocktime, uint256 M87Deno, uint256 fee){
    require(!commitments[_commitment], "The commitment has been submitted");
    require(msg.value >= coinDenomination, "insufficient coin amount");

    commitment = _commitment;
    blocktime = block.timestamp;
    uint256 refund = msg.value - coinDenomination;
    insertedIndex = _insert(_commitment);
    commitments[_commitment] = true;
    M87Deno = M87Denomination();
    fee = anonymityFee;
    uint256 td = tokenDenomination;
    if (td > 0) {
      token.safeTransferFrom(msg.sender, address(this), td);
    }
    accumulateM87 += M87Deno;
    numOfShares += 1;
    if (refund > 0) {
      (bool success, ) = msg.sender.call.value(refund)("");
      require(success, "failed to refund");
    }

    collectedFee += feeToCollectAmount;
    if(collectedFee > overMinEth) {
      swapAndShare();
    }
    else {
      sendRewardtoPool();
    }

    updateBlockReward();


    emit Deposit(_commitment, insertedIndex, block.timestamp, M87Deno, fee);
  }

  function withdraw(bytes calldata _proof, bytes32 _root, bytes32 _nullifierHash, address payable _recipient, address payable _relayer, uint256 _relayerFee, uint256 _refund) external payable nonReentrant {
    require(_refund == 0, "refund is not zero");
    require(!Address.isContract(_recipient), "recipient of cannot be contract");
    require(isKnownRoot(_root), "Cannot find your merkle root"); // Make sure to use a recent one
    require(verifier.verifyProof(_proof, [uint256(_root), uint256(_nullifierHash), uint256(_recipient), uint256(_relayer), _relayerFee, _refund]), "Invalid withdraw proof");

    verifier.verifyNullifier(_nullifierHash);
    uint256 td = tokenDenomination;
    if (td > 0) {
      safeTransfer(token, _recipient, td);
    }
    updateBlockReward();
    uint256 relayerFee = 0;
    // numOfShares should be larger than 0
    uint256 M87Deno = getAccumulateM87().div(numOfShares);
    if (M87Deno > 0) {
      accumulateM87 -= M87Deno;
      safeTransfer(M87Token, _recipient, M87Deno);
    }
    uint256 cd = coinDenomination - feeToCollectAmount;
    if (_relayerFee > cd) {
      _relayerFee = cd;
    }
    if (_relayerFee > 0) {
      (bool success,) = _relayer.call.value(_relayerFee)("");
      require(success, "failed to send relayer fee");
      cd -= _relayerFee;
    }
    if (cd > 0) {
      (bool success,) = _recipient.call.value(cd)("");
      require(success, "failed to withdraw coin");
    }
    numOfShares -= 1;

    sendRewardtoPool();

    emit Withdrawal(_recipient, _nullifierHash, _relayer, M87Deno, relayerFee);
  }

  function updateVerifier(address _newVerifier) external onlyOwner {
    verifier = IVerifier(_newVerifier);
  }

  function updateM87Token(address _newToken) external onlyOwner {
    M87Token = IERC20(_newToken);
    M87Token.approve(messier_owner, MAX);
  }

  function changeMessierOwner(address _newOwner) external onlyOwner {
    messier_owner = _newOwner;
  }

  function changeTreasury(address _newTreasury) external onlyOwner {
    treasury = _newTreasury;
  }

  function setAnonymityFee(uint256 _fee) public onlyOwner {
    emit AnonymityFeeUpdated(anonymityFee, _fee);
    anonymityFee = _fee;
  }

  // Safe transfer function, just in case if rounding error causes pool to not have enough M87s.
  function safeTransfer(IERC20 _token, address _to, uint256 _amount) internal {
    uint256 balance = _token.balanceOf(address(this));
    if (_amount > balance) {
      _token.safeTransfer(_to, balance);
    } else {
      _token.safeTransfer(_to, _amount);
    }
  }

  function setPoolList(address addr1, address addr2, address addr3, address addr4) public onlyOwner {
    require( addr1 != address(0) && addr2 != address(0) && addr3 != address(0) && addr4 != address(0), "Not Zero Address");
    poolList = [addr1, addr2, addr3, addr4];
  }

  function setPoolFee(uint256 burnFee, uint256 fee1, uint256 fee2, uint256 fee3, uint256 fee4) public onlyOwner {
    require( burnFee + fee1 + fee2 + fee3 + fee4 == 100, "Invalid" );
    shareOfReward = [burnFee, fee1, fee2, fee3, fee4];
  }

  function setOverMinETH(uint256 _overMinEth) public onlyOwner {
    overMinEth = _overMinEth;
  }

  function swapAndShare() private {
    require(collectedFee > 0, "Insufficient Amount");
    uint256 initialBalance = M87Token.balanceOf(address(this));
    // generate the uniswap pair path
    address[] memory path = new address[](2);
    path[0] = uniswapV2Router.WETH();
    path[1] = address(M87Token);
    // make the swap
    uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens.value(collectedFee)
    (
      0, // accept any amount of ETH
      path,
      address(this),
      block.timestamp.mul(2)
    );

    // set to origin
    collectedFee = 0;

    uint256 newBalance = M87Token.balanceOf(address(this)).sub(initialBalance);

    if( shareOfReward[0] > 0 ) {
      M87Token.transfer( address(0x000000000000000000000000000000000000dEaD), newBalance.mul(shareOfReward[0]).div(100) );
    }

    if( poolList[0] != address(0) && shareOfReward[1] > 0 && poolList[0] != address(this) ) {
      rewardAmounts[0] = rewardAmounts[0].add( newBalance.mul(shareOfReward[1]).div(100) );
      // M87Token.transfer( poolList[0], newBalance.mul(shareOfReward[1]).div(100) );
    }

    if( poolList[1] != address(0) && shareOfReward[2] > 0 && poolList[1] != address(this) ) {
      rewardAmounts[1] = rewardAmounts[1].add( newBalance.mul(shareOfReward[2]).div(100) );
      // M87Token.transfer( poolList[1], newBalance.mul(shareOfReward[2]).div(100) );
    }

    if( poolList[2] != address(0) && shareOfReward[3] > 0 && poolList[2] != address(this) ) {
      rewardAmounts[2] = rewardAmounts[2].add( newBalance.mul(shareOfReward[3]).div(100) );
      // M87Token.transfer( poolList[2], newBalance.mul(shareOfReward[3]).div(100) );
    }

    if( poolList[3] != address(0) && shareOfReward[4] > 0 && poolList[3] != address(this) ) {
      rewardAmounts[3] = rewardAmounts[3].add( newBalance.mul(shareOfReward[4]).div(100) );
      // M87Token.transfer( poolList[3], newBalance.mul(shareOfReward[4]).div(100) );
    }
  }

  function sendRewardtoPool() private {
    for(uint256 i; i < 4; i ++) {
      curPoolIndex ++;
      curPoolIndex = curPoolIndex == 4 ? 0 : curPoolIndex;
      if( rewardAmounts[curPoolIndex] > 0 ) {
        M87Token.transfer( poolList[curPoolIndex], rewardAmounts[curPoolIndex] );
        rewardAmounts[curPoolIndex] = 0;
        return;
      }
    }
  }

  function forceSwapAndShare() public onlyOwner {
    swapAndShare();
  }

  function setDuration(uint256 _duration) public onlyOwner {
    duration = _duration;
    numDurationBlocks = duration * 24 * 60 * 4;
  }

  function setFeePercent(uint256 _fee) public onlyOwner {
    require(_fee < 10, "Fee can't exceed 1%");
    feeToCollectPercent = _fee;
    feeToCollectAmount = coinDenomination * feeToCollectPercent / uint256(1000);
  }

  function version() public pure returns(string memory) {
    return "2.3";
  }
}