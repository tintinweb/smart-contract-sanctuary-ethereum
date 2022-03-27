/***************************************************
IuvoDAO

We are philanthropy. Iuvo aims to become the defacto crypto standard in charity and giving to people in need.
We donate money all on chain and to cryptocurrency wallets in real time and immediately.
***************************************************/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import '@chainlink/contracts/src/v0.8/VRFConsumerBase.sol';
import '@chainlink/contracts/src/v0.8/ConfirmedOwner.sol';
import './interfaces/IIuvoDaoToken.sol';

contract IuvoDao is VRFConsumerBase, ConfirmedOwner(msg.sender) {
  uint256 private constant PERCENT_DENOMENATOR = 1000;

  bytes32 private _vrfKeyHash;
  uint256 private _vrfFee;

  mapping(bytes32 => uint256) private _vrfInitiators;
  mapping(uint256 => address) private _vrfWinners;

  address public currentCharity;
  uint256 public percentDonatedOnChange = 100; // 10%
  uint256 public percentDonatedOnDeposit = 500; // 50% of deposit amount donated immediately
  uint256 public percentTreasuryBuyerPool = 10; // 1%
  uint256 public timeToChangeCharities = 60 * 60 * 24 * 7; // 7 days
  uint256 public lastCharityChange;

  uint256 public totalDonated;
  address[] public allSelectedCharities;
  mapping(address => uint256) public donatedPerCharity;

  address[] public charityChangers;

  mapping(address => bool) public authorized;

  IIuvoDaoToken voterToken;

  // lastCharityChange => charity => votes
  mapping(uint256 => mapping(address => uint256)) public votes;
  // lastCharityChange => user => voted
  mapping(uint256 => mapping(address => bool)) public userVoted;
  // lastCharityChange => charity[]
  mapping(uint256 => address[]) public charities;
  // lastCharityChange => charity => true
  mapping(uint256 => mapping(address => bool)) public charitiesIndexed;

  event AddCharity(address charity);
  event ChangeCharity(address charity);
  event VoteForCharity(address user, address charity);
  event InitiatedEpochWinner(bytes32 indexed requestId, uint256 indexed epoch);
  event SelectedEpochWinner(
    bytes32 indexed requestId,
    uint256 indexed epoch,
    address winner
  );

  modifier onlyAuthorized() {
    require(msg.sender == owner() || authorized[msg.sender], 'not authorized');
    _;
  }

  constructor(
    address _charity,
    address _voterToken,
    address _vrfCoordinator,
    address _linkToken,
    bytes32 _keyHash,
    uint256 _fee
  ) VRFConsumerBase(_vrfCoordinator, _linkToken) {
    currentCharity = _charity;
    allSelectedCharities.push(_charity);
    lastCharityChange = block.timestamp;

    voterToken = IIuvoDaoToken(_voterToken);

    _vrfKeyHash = _keyHash;
    _vrfFee = _fee;
  }

  function getVoterToken() external view returns (address) {
    return address(voterToken);
  }

  function getAllCharities() external view returns (address[] memory) {
    return allSelectedCharities;
  }

  function getCharityChangers() external view returns (address[] memory) {
    return charityChangers;
  }

  function selectWinningBuyerAtPreviousEpoch() external {
    uint256 _epoch = voterToken.getEpoch() - 1;
    _selectWinningBuyerAtEpoch(_epoch);
  }

  // only let owner select at some epoch that's not the previous one
  function selectWinningBuyerAt(uint256 _epoch) external onlyOwner {
    _selectWinningBuyerAtEpoch(_epoch);
  }

  function _selectWinningBuyerAtEpoch(uint256 _epoch)
    internal
    returns (bytes32 requestId)
  {
    require(LINK.balanceOf(address(this)) >= _vrfFee, 'not enough LINK');
    require(voterToken.getEpoch() > _epoch, 'epoch is not complete');
    require(
      voterToken.epochBuyers(_epoch).length > 0,
      'no buyers during period'
    );

    requestId = requestRandomness(_vrfKeyHash, _vrfFee);
    // epoch is always 1 or greater
    require(_vrfInitiators[requestId] == 0, 'already initiated');

    _vrfInitiators[requestId] = _epoch;
    emit InitiatedEpochWinner(requestId, _epoch);
  }

  function fulfillRandomness(bytes32 requestId, uint256 randomness)
    internal
    override
  {
    uint256 _epoch = _vrfInitiators[requestId];
    address[] memory _allBuyers = voterToken.epochBuyers(_epoch);
    uint256 _winnerIdx = randomness % _allBuyers.length;
    _vrfWinners[_epoch] = _allBuyers[_winnerIdx];

    uint256 _before = address(this).balance;
    uint256 _amountETH = (_before * percentTreasuryBuyerPool) /
      PERCENT_DENOMENATOR;
    payable(_vrfWinners[_epoch]).call{ value: _amountETH }('');
    require(address(this).balance >= _before - _amountETH);

    emit SelectedEpochWinner(requestId, _epoch, _vrfWinners[_epoch]);
  }

  function addCharity(address _charity) external onlyAuthorized {
    require(
      !charitiesIndexed[lastCharityChange][_charity],
      'charity already present'
    );
    require(
      charities[lastCharityChange].length <= 5,
      'no more than 5 to select from per period'
    );

    charities[lastCharityChange].push(_charity);
    charitiesIndexed[lastCharityChange][_charity] = true;
    emit AddCharity(_charity);
  }

  function changeCharity() external {
    require(
      block.timestamp > lastCharityChange + timeToChangeCharities,
      'not enough time'
    );
    uint256 donatedAmount = (address(this).balance * percentDonatedOnChange) /
      PERCENT_DENOMENATOR;
    _sendToCharity(donatedAmount);
    totalDonated += donatedAmount;
    donatedPerCharity[currentCharity] += donatedAmount;

    // get and set next charity with most votes this period
    currentCharity = _getNextCharity();
    require(currentCharity != address(0), 'bad charity');
    allSelectedCharities.push(currentCharity);

    charityChangers.push(msg.sender);
    lastCharityChange = block.timestamp;
    emit ChangeCharity(currentCharity);
  }

  function voteForCharity(address _charity) external {
    _voteForCharity(msg.sender, _charity);
    emit VoteForCharity(msg.sender, _charity);
  }

  function _voteForCharity(address _user, address _charity) internal {
    require(!userVoted[lastCharityChange][_user], 'already voted');
    // cooldown handles preventing duplicate votes so users don't transfer
    // tokens to another wallet to try and vote more than once per period
    require(
      block.timestamp >
        voterToken.voteCooldownStart(_user) + voterToken.voteCooldownPeriod(),
      'in cooldown period from recent token transfer'
    );
    require(
      voterToken.balanceOf(_user) > 0,
      'must have voter token balance to vote'
    );

    address _validCharity = _checkAndGetValidCharity(_charity);
    require(_validCharity != address(0), 'not a valid charity to vote for');

    votes[lastCharityChange][_validCharity] += voterToken.balanceOf(_user);
    userVoted[lastCharityChange][_user] = true;
  }

  function _checkAndGetValidCharity(address _charity)
    internal
    view
    returns (address)
  {
    for (uint256 i = 0; i < charities[lastCharityChange].length; i++) {
      if (charities[lastCharityChange][i] == _charity) {
        return _charity;
      }
    }
    return address(0);
  }

  function _getNextCharity() internal view returns (address) {
    address charityMostVotes = address(0);
    uint256 mostVotes = 0;
    for (uint256 i = 0; i < charities[lastCharityChange].length; i++) {
      address _charity = charities[lastCharityChange][i];
      if (votes[lastCharityChange][_charity] > mostVotes) {
        charityMostVotes = _charity;
        mostVotes = votes[lastCharityChange][_charity];
      }
    }
    return charityMostVotes;
  }

  function setPercentDonatedOnChange(uint256 _percent) external onlyOwner {
    require(_percent <= PERCENT_DENOMENATOR, 'cannot be more than 100%');
    percentDonatedOnChange = _percent;
  }

  function setPercentDonatedOnDeposit(uint256 _percent) external onlyOwner {
    require(_percent <= PERCENT_DENOMENATOR, 'cannot be more than 100%');
    percentDonatedOnDeposit = _percent;
  }

  function setTimeBetweenCharities(uint256 _timeSeconds) external onlyOwner {
    require(_timeSeconds <= 60 * 60 * 24 * 30 * 6, 'not more than 6 months');
    timeToChangeCharities = _timeSeconds;
  }

  function setPercentTreasuryBuyerPool(uint256 _percent) external onlyOwner {
    require(
      _percent <= (PERCENT_DENOMENATOR * 10) / 100,
      'cannot be more than 10%'
    );
    percentTreasuryBuyerPool = _percent;
  }

  function setAuthorized(address _user, bool _isAuthorized)
    external
    onlyAuthorized
  {
    authorized[_user] = _isAuthorized;
  }

  function setVrfBuyerFee(uint256 _fee) external onlyOwner {
    _vrfFee = _fee;
  }

  function _sendToCharity(uint256 _amountETH) private {
    uint256 before = address(this).balance;
    payable(currentCharity).call{ value: _amountETH }('');
    require(address(this).balance >= before - _amountETH);
  }

  receive() external payable {
    if (percentDonatedOnDeposit > 0) {
      uint256 donateAmount = (msg.value * percentDonatedOnDeposit) /
        PERCENT_DENOMENATOR;
      _sendToCharity(donateAmount);
      totalDonated += donateAmount;
      donatedPerCharity[currentCharity] += donateAmount;
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/LinkTokenInterface.sol";

import "./VRFRequestIDBase.sol";

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constructor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator, _link) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash), and have told you the minimum LINK
 * @dev price for VRF service. Make sure your contract has sufficient LINK, and
 * @dev call requestRandomness(keyHash, fee, seed), where seed is the input you
 * @dev want to generate randomness from.
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomness method.
 *
 * @dev The randomness argument to fulfillRandomness is the actual random value
 * @dev generated from your seed.
 *
 * @dev The requestId argument is generated from the keyHash and the seed by
 * @dev makeRequestId(keyHash, seed). If your contract could have concurrent
 * @dev requests open, you can use the requestId to track which seed is
 * @dev associated with which randomness. See VRFRequestIDBase.sol for more
 * @dev details. (See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.)
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ. (Which is critical to making unpredictable randomness! See the
 * @dev next section.)
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the ultimate input to the VRF is mixed with the block hash of the
 * @dev block in which the request is made, user-provided seeds have no impact
 * @dev on its economic security properties. They are only included for API
 * @dev compatability with previous versions of this contract.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request.
 */
abstract contract VRFConsumerBase is VRFRequestIDBase {
  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBase expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomness the VRF output
   */
  function fulfillRandomness(bytes32 requestId, uint256 randomness) internal virtual;

  /**
   * @dev In order to keep backwards compatibility we have kept the user
   * seed field around. We remove the use of it because given that the blockhash
   * enters later, it overrides whatever randomness the used seed provides.
   * Given that it adds no security, and can easily lead to misunderstandings,
   * we have removed it from usage and can now provide a simpler API.
   */
  uint256 private constant USER_SEED_PLACEHOLDER = 0;

  /**
   * @notice requestRandomness initiates a request for VRF output given _seed
   *
   * @dev The fulfillRandomness method receives the output, once it's provided
   * @dev by the Oracle, and verified by the vrfCoordinator.
   *
   * @dev The _keyHash must already be registered with the VRFCoordinator, and
   * @dev the _fee must exceed the fee specified during registration of the
   * @dev _keyHash.
   *
   * @dev The _seed parameter is vestigial, and is kept only for API
   * @dev compatibility with older versions. It can't *hurt* to mix in some of
   * @dev your own randomness, here, but it's not necessary because the VRF
   * @dev oracle will mix the hash of the block containing your request into the
   * @dev VRF seed it ultimately uses.
   *
   * @param _keyHash ID of public key against which randomness is generated
   * @param _fee The amount of LINK to send with the request
   *
   * @return requestId unique ID for this request
   *
   * @dev The returned requestId can be used to distinguish responses to
   * @dev concurrent requests. It is passed as the first argument to
   * @dev fulfillRandomness.
   */
  function requestRandomness(bytes32 _keyHash, uint256 _fee) internal returns (bytes32 requestId) {
    LINK.transferAndCall(vrfCoordinator, _fee, abi.encode(_keyHash, USER_SEED_PLACEHOLDER));
    // This is the seed passed to VRFCoordinator. The oracle will mix this with
    // the hash of the block containing this request to obtain the seed/input
    // which is finally passed to the VRF cryptographic machinery.
    uint256 vRFSeed = makeVRFInputSeed(_keyHash, USER_SEED_PLACEHOLDER, address(this), nonces[_keyHash]);
    // nonces[_keyHash] must stay in sync with
    // VRFCoordinator.nonces[_keyHash][this], which was incremented by the above
    // successful LINK.transferAndCall (in VRFCoordinator.randomnessRequest).
    // This provides protection against the user repeating their input seed,
    // which would result in a predictable/duplicate output, if multiple such
    // requests appeared in the same block.
    nonces[_keyHash] = nonces[_keyHash] + 1;
    return makeRequestId(_keyHash, vRFSeed);
  }

  LinkTokenInterface internal immutable LINK;
  address private immutable vrfCoordinator;

  // Nonces for each VRF key from which randomness has been requested.
  //
  // Must stay in sync with VRFCoordinator[_keyHash][this]
  mapping(bytes32 => uint256) /* keyHash */ /* nonce */
    private nonces;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   * @param _link address of LINK token contract
   *
   * @dev https://docs.chain.link/docs/link-token-contracts
   */
  constructor(address _vrfCoordinator, address _link) {
    vrfCoordinator = _vrfCoordinator;
    LINK = LinkTokenInterface(_link);
  }

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomness(bytes32 requestId, uint256 randomness) external {
    require(msg.sender == vrfCoordinator, "Only VRFCoordinator can fulfill");
    fulfillRandomness(requestId, randomness);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ConfirmedOwnerWithProposal.sol";

/**
 * @title The ConfirmedOwner contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract ConfirmedOwner is ConfirmedOwnerWithProposal {
  constructor(address newOwner) ConfirmedOwnerWithProposal(newOwner, address(0)) {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IIuvoDaoToken is IERC20 {
  function epochBuyers(uint256 epoch) external view returns (address[] memory);

  function epochBuyersIndexed(uint256 epoch, address buyer)
    external
    view
    returns (bool);

  function getEpoch() external view returns (uint256);

  function voteCooldownPeriod() external view returns (uint256);

  function voteCooldownStart(address _user) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface LinkTokenInterface {
  function allowance(address owner, address spender) external view returns (uint256 remaining);

  function approve(address spender, uint256 value) external returns (bool success);

  function balanceOf(address owner) external view returns (uint256 balance);

  function decimals() external view returns (uint8 decimalPlaces);

  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);

  function increaseApproval(address spender, uint256 subtractedValue) external;

  function name() external view returns (string memory tokenName);

  function symbol() external view returns (string memory tokenSymbol);

  function totalSupply() external view returns (uint256 totalTokensIssued);

  function transfer(address to, uint256 value) external returns (bool success);

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  ) external returns (bool success);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool success);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VRFRequestIDBase {
  /**
   * @notice returns the seed which is actually input to the VRF coordinator
   *
   * @dev To prevent repetition of VRF output due to repetition of the
   * @dev user-supplied seed, that seed is combined in a hash with the
   * @dev user-specific nonce, and the address of the consuming contract. The
   * @dev risk of repetition is mostly mitigated by inclusion of a blockhash in
   * @dev the final seed, but the nonce does protect against repetition in
   * @dev requests which are included in a single block.
   *
   * @param _userSeed VRF seed input provided by user
   * @param _requester Address of the requesting contract
   * @param _nonce User-specific nonce at the time of the request
   */
  function makeVRFInputSeed(
    bytes32 _keyHash,
    uint256 _userSeed,
    address _requester,
    uint256 _nonce
  ) internal pure returns (uint256) {
    return uint256(keccak256(abi.encode(_keyHash, _userSeed, _requester, _nonce)));
  }

  /**
   * @notice Returns the id for this request
   * @param _keyHash The serviceAgreement ID to be used for this request
   * @param _vRFInputSeed The seed to be passed directly to the VRF
   * @return The id for this request
   *
   * @dev Note that _vRFInputSeed is not the seed passed by the consuming
   * @dev contract, but the one generated by makeVRFInputSeed
   */
  function makeRequestId(bytes32 _keyHash, uint256 _vRFInputSeed) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(_keyHash, _vRFInputSeed));
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/OwnableInterface.sol";

/**
 * @title The ConfirmedOwner contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract ConfirmedOwnerWithProposal is OwnableInterface {
  address private s_owner;
  address private s_pendingOwner;

  event OwnershipTransferRequested(address indexed from, address indexed to);
  event OwnershipTransferred(address indexed from, address indexed to);

  constructor(address newOwner, address pendingOwner) {
    require(newOwner != address(0), "Cannot set owner to zero");

    s_owner = newOwner;
    if (pendingOwner != address(0)) {
      _transferOwnership(pendingOwner);
    }
  }

  /**
   * @notice Allows an owner to begin transferring ownership to a new address,
   * pending.
   */
  function transferOwnership(address to) public override onlyOwner {
    _transferOwnership(to);
  }

  /**
   * @notice Allows an ownership transfer to be completed by the recipient.
   */
  function acceptOwnership() external override {
    require(msg.sender == s_pendingOwner, "Must be proposed owner");

    address oldOwner = s_owner;
    s_owner = msg.sender;
    s_pendingOwner = address(0);

    emit OwnershipTransferred(oldOwner, msg.sender);
  }

  /**
   * @notice Get the current owner
   */
  function owner() public view override returns (address) {
    return s_owner;
  }

  /**
   * @notice validate, transfer ownership, and emit relevant events
   */
  function _transferOwnership(address to) private {
    require(to != msg.sender, "Cannot transfer to self");

    s_pendingOwner = to;

    emit OwnershipTransferRequested(s_owner, to);
  }

  /**
   * @notice validate access
   */
  function _validateOwnership() internal view {
    require(msg.sender == s_owner, "Only callable by owner");
  }

  /**
   * @notice Reverts if called by anyone other than the contract owner.
   */
  modifier onlyOwner() {
    _validateOwnership();
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface OwnableInterface {
  function owner() external returns (address);

  function transferOwnership(address recipient) external;

  function acceptOwnership() external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
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