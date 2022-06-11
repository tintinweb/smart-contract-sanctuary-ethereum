/**
 *Submitted for verification at Etherscan.io on 2022-06-11
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

/// @title interfact to interact with ERC20 tokens
/// @author elee

interface IERC20 {
  function mint(address account, uint256 amount) external;

  function totalSupply() external view returns (uint256);

  function balanceOf(address account) external view returns (uint256);

  function transfer(address recipient, uint256 amount) external returns (bool);

  function allowance(address owner, address spender) external view returns (uint256);

  function approve(address spender, uint256 amount) external returns (bool);

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

/// @title Wavepool is the second genration wave contract
// solhint-disable comprehensive-interface
contract WavePool {
  struct RedemptionData {
    uint256 claimed;
    bool redeemed;
  }

  struct WaveMetadata {
    bool enabled;
    bytes32 merkleRoot;
    uint256 enableTime;
  }

  // mapping from wave -> wave information
  // wave informoation includes the merkleRoot and enableTime
  mapping(uint256 => WaveMetadata) public _metadata;
  // mapping from wave -> address -> claim information
  // claim information includes the amount and whether or not it has been redeemed
  mapping(uint256 => mapping(address => RedemptionData)) public _data;

  // time at which people can claim
  uint256 public _claimTime;

  // the address which will receive any possible extra IPT
  address public _receiver;

  // the token used to claim points, USDC
  IERC20 public _pointsToken; // = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48); // usdc
  // the token to be rewarded, IPT
  IERC20 public _rewardToken;

  // the amount of reward tokens allocated to the contract
  uint256 public _totalReward;

  // this is the minimum amount of 'points' that can be redeemed for one IPT
  uint256 public _floor;
  // this is the maximum amount of points that can be added to the contract
  uint256 public _cap;

  // the amount of points token that have been sent to the contract
  uint256 public _totalClaimed = 0;

  uint256 public impliedPrice;
  bool public saturation;
  bool public calculated;

  event Points(address indexed from, uint256 wave, uint256 amount);

  constructor(
    address receiver,
    uint256 totalReward,
    address rewardToken,
    address pointsToken,
    uint256 claimTime,
    bytes32 merkle1,
    uint256 enable1,
    bytes32 merkle2,
    uint256 enable2,
    bytes32 merkle3,
    uint256 enable3
  ) {
    // price information
    _floor = 250_000;
    _cap = 500_000 * 35_000_000 * 4;
    _claimTime = claimTime;
    // reward information
    _rewardToken = IERC20(rewardToken);
    _pointsToken = IERC20(pointsToken);
    _totalReward = totalReward;

    // set receiver of IPT
    _receiver = receiver;

    // wave metadata
    _metadata[1].enabled = true;
    _metadata[1].merkleRoot = merkle1;
    _metadata[1].enableTime = enable1;

    _metadata[2].enabled = true;
    _metadata[2].merkleRoot = merkle2;
    _metadata[2].enableTime = enable2;

    _metadata[3].enabled = true;
    _metadata[3].merkleRoot = merkle3;
    _metadata[3].enableTime = enable3;

    calculated = false;
    saturation = false;
  }

  /// @notice tells whether the wave is enabled or not
  /// @return boolean true if the wave is enabled
  function isEnabled(uint256 wave) public view returns (bool) {
    if (_metadata[wave].enabled != true) {
      return false;
    }
    return block.timestamp > _metadata[wave].enableTime && block.timestamp < _claimTime;
  }

  /// @notice not claimable after USDC cap has been reached
  function canClaim() public view returns (bool) {
    return _totalClaimed <= _cap;
  }

  /// @notice whether or not redemption is possible
  function canRedeem() public view returns (bool) {
    return block.timestamp > _claimTime;
  }

  /// @notice calculate pricing 1 time to save gas
  function calculatePricing() internal {
    require(!calculated, "Calculated already");
    // implied price is assuming pro rata, how many points you need for one reward
    // for instance, if the totalReward was 1, and _totalClaimed was below 500_000, then the impliedPrice would be below 500_000
    impliedPrice = _totalClaimed / (_totalReward / 1e18);
    if (!(impliedPrice < _floor)) {
      saturation = true;
    }
    calculated = true;
  }

  /// @notice redeem points for reward token
  /// @param wave if claimed on multiple waves, must redeem for each one separately
  function redeem(uint256 wave) external {
    require(canRedeem() == true, "can't redeem yet");
    require(_data[wave][msg.sender].redeemed == false, "already redeem");
    if (!calculated) {
      calculatePricing();
    }

    _data[wave][msg.sender].redeemed = true;
    uint256 rewardAmount;
    RedemptionData memory user = _data[wave][msg.sender];

    if (!saturation) {
      // if the implied price is smaller than the floor price, that means that
      // not enough points have been claimed to get to the floor price
      // in that case, charge the floor price
      rewardAmount = ((1e18 * user.claimed) / _floor);
    } else {
      // if the implied price is above the floor price, the price is the implied price
      rewardAmount = ((1e18 * user.claimed) / impliedPrice);
    }
    giveTo(msg.sender, rewardAmount);
  }

  /// @notice 1 USDC == 1 point - rewards distributed pro rata based on points
  /// @param amount amount of usdc
  /// @param key the total amount the points the user may claim - ammount allocated in whitelist
  /// @param merkleProof a proof proving that the caller may redeem up to `key` points
  function getPoints(
    uint256 wave,
    uint256 amount,
    uint256 key,
    bytes32[] memory merkleProof
  ) public {
    require(isEnabled(wave) == true, "not enabled");
    uint256 target = _data[wave][msg.sender].claimed + amount;

    if (_metadata[wave].merkleRoot != 0x00) {
      require(verifyClaim(wave, msg.sender, key, merkleProof) == true, "invalid proof");
      require(target <= key, "max alloc claimed");
    }

    _data[wave][msg.sender].claimed = target;
    _totalClaimed = _totalClaimed + amount;

    require(canClaim() == true, "Cap reached");

    takeFrom(msg.sender, amount);
    emit Points(msg.sender, wave, amount);
  }

  /// @notice validate the proof of a merkle drop claim
  /// @param wave the wave that they are trying to redeem for
  /// @param claimer the address attempting to claim
  /// @param key the amount of scaled TRIBE allocated the claimer claims that they have credit over
  /// @param merkleProof a proof proving that claimer may redeem up to `key` amount of tribe
  /// @return boolean true if the proof is valid, false if the proof is invalid
  function verifyClaim(
    uint256 wave,
    address claimer,
    uint256 key,
    bytes32[] memory merkleProof
  ) private view returns (bool) {
    bytes32 leaf = keccak256(abi.encodePacked(claimer, key));
    bytes32 merkleRoot = _metadata[wave].merkleRoot;
    return verifyProof(merkleProof, merkleRoot, leaf);
  }

  //solhint-disable-next-line max-line-length
  //merkle logic: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/c9bdb1f0ae168e00a942270f2b85d6a7d3293550/contracts/utils/cryptography/MerkleProof.sol
  //MIT: OpenZeppelin Contracts v4.3.2 (utils/cryptography/MerkleProof.sol)
  function verifyProof(
    bytes32[] memory proof,
    bytes32 root,
    bytes32 leaf
  ) internal pure returns (bool) {
    return processProof(proof, leaf) == root;
  }

  function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
    bytes32 computedHash = leaf;
    for (uint256 i = 0; i < proof.length; i++) {
      bytes32 proofElement = proof[i];
      if (computedHash <= proofElement) {
        computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
      } else {
        computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
      }
    }
    return computedHash;
  }

  /// @notice function which transfer the point token
  function takeFrom(address target, uint256 amount) internal {
    bool check = _pointsToken.transferFrom(target, _receiver, amount);
    require(check, "erc20 transfer failed");
  }

  /// @notice function which sends the reward token
  function giveTo(address target, uint256 amount) internal {
    if (_rewardToken.balanceOf(address(this)) < amount) {
      amount = _rewardToken.balanceOf(address(this));
    }
    require(amount > 0, "cant redeem zero");
    bool check = _rewardToken.transfer(target, amount);
    require(check, "erc20 transfer failed");
  }

  ///@notice sends all unclaimed reward tokens to the receiver
  function withdraw() external {
    require(msg.sender == _receiver, "Only Receiver");
    //require(block.timestamp > (_claimTime + (7 days)), "wait for claim time");
    require(calculated, "calculatePricing() first");

    uint256 rewardAmount;
    if (!saturation) {
      rewardAmount = ((1e18 * _totalClaimed) / _floor);
    } else {
      revert("Saturation reached");
    }
    rewardAmount = _totalReward - rewardAmount;

    giveTo(_receiver, rewardAmount);
  }
}
// solhint-enable comprehensive-interface