// SPDX-License-Identifier: Unlicensed

pragma solidity 0.8.15;

import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./Types.sol";
import "./interfaces/ICertificate.sol";
import "./libraries/VestingCalculator.sol";
import "./libraries/TokenPools.sol";
import "./libraries/Vestings.sol";
import "./libraries/Claims.sol";
import "./libraries/Admins.sol";
import "./libraries/Intervals.sol";
import "./libraries/Balances.sol";

/// @title Stock options token pool contract - main contract
contract StockOptions is ReentrancyGuardUpgradeable {
  /**
   * @notice Token pool created event
   * @param id Token pool identifier
   */
  event TokenPoolCreated(uint256 id);

  /**
   * @notice Admin added event
   * @param tokenPoolId Token pool identifier
   * @param _address Address of the admin
   */
  event AdminAdded(uint256 tokenPoolId, address _address);

  /**
   * @notice Admin removed event
   * @param tokenPoolId Token pool identifier
   * @param _address Address of the admin
   */
  event AdminRemoved(uint256 tokenPoolId, address _address);

  /**
   * @notice Vesting added event
   * @param tokenPoolId Token pool identifier
   * @param vestingId Vesting plan identifier
   * @param _address Address of the new participant
   * @param issueDate Issue date of the vesting plan as timestamps
   * @param tokenAmount Token amount to be vested
   * @param intervals Vesting intervals
   * @param certificateId NFT certificate ID
   */
  event VestingAdded(
    uint256 tokenPoolId,
    uint256 vestingId,
    address indexed _address,
    uint256 issueDate,
    uint256 tokenAmount,
    Intervals.Interval[] intervals,
    uint256 certificateId
  );

  /**
   * Participant removed
   * @notice Participant removed from the token pool event
   * @param tokenPoolId Token pool identifier
   * @param _address Address of the participant
   */
  event ParticipantRemoved(uint256 tokenPoolId, address indexed _address);

  /**
   * Vesting removed
   * @notice Vesting removed from the token pool event
   * @param tokenPoolId Token pool identifier
   * @param vestingId Vesting identifier
   * @param _address Address of the participant
   */
  event VestingRemoved(
    uint256 tokenPoolId,
    uint256 vestingId,
    address indexed _address
  );

  /**
   * Participant vesting plan terminated
   * @notice Participant vesting plan termination from the token pool event
   * @param tokenPoolId Token pool identifier
   * @param vestingId Vesting plan identifier
   * @param _address Address of the participant
   * @param tokensTransfered Tokens transfered to the participant
   * @param tokensReverted Tokens revered back
   */
  event VestingTerminated(
    uint256 tokenPoolId,
    uint256 vestingId,
    address indexed _address,
    uint256 tokensTransfered,
    uint256 tokensReverted
  );

  /**
   * Participant removed
   * @notice Participant removed from the token pool event
   * @param tokenPoolId Token pool identifier
   * @param _address Address of the participant
   * @param tokensTransfered Tokens transfered to the participant
   * @param tokensReverted Tokens revered back
   */
  event ParticipantTerminated(
    uint256 tokenPoolId,
    address indexed _address,
    uint256 tokensTransfered,
    uint256 tokensReverted
  );

  /**
   * @notice Participant vesting paused event
   * @param tokenPoolId Token pool identifier
   * @param _address Address of the participant
   */
  event ParticipantVestingPaused(uint256 tokenPoolId, address _address);

  /**
   * @notice Vesting paused event
   * @param tokenPoolId Token pool identifier
   * @param vestingId Vesting identifier
   * @param _address Address of the participant
   */
  event VestingPaused(uint256 tokenPoolId, uint256 vestingId, address _address);

  /**
   * @notice Participant vesting unpaused event
   * @param tokenPoolId Token pool identifier
   * @param _address Address of the participant
   */
  event ParticipantVestingUnPaused(uint256 tokenPoolId, address _address);

  /**
   * @notice Vesting unpaused event
   * @param tokenPoolId Token pool identifier
   * @param vestingId Vesting identifier
   * @param _address Address of the participant
   */
  event VestingUnPaused(
    uint256 tokenPoolId,
    uint256 vestingId,
    address _address
  );

  /**
   * @notice Tokens claimed by participant
   * @param tokenPoolId Token pool identifier
   * @param _address Address of the participant
   * @param amount Token amount that was claimed
   */
  event TokensClaimed(
    uint256 tokenPoolId,
    address indexed _address,
    uint256 amount
  );

  mapping(uint256 => TokenPools.TokenPool) private tokenPools;
  mapping(uint256 => mapping(address => Vestings.Vesting[])) private vestings;
  mapping(uint256 => EnumerableSet.AddressSet) private registerAddresses;
  mapping(address => Claims.Claim[]) private claims;
  mapping(uint256 => mapping(address => bool)) private admins;
  mapping(uint256 => mapping(address => uint256)) private balances;

  ICertificate certificate;

  using TokenPools for TokenPools.TokenPool;
  using Vestings for Vestings.Vesting;
  using Intervals for Intervals.Interval[];
  using Claims for mapping(address => Claims.Claim[]);
  using Admins for mapping(uint256 => mapping(address => bool));
  using Balances for mapping(address => uint256);
  using EnumerableSet for EnumerableSet.AddressSet;

  using SafeMath for uint256;

  using VestingsList for Vestings.Vesting[];

  modifier onlyAdmin(uint256 tokenPoolId) {
    require(admins.has(tokenPoolId, msg.sender), "Unauthorized");
    _;
  }

  function initialize(ICertificate _certificate) public initializer {
    certificate = _certificate;
    __ReentrancyGuard_init();
  }

  /**
   * @notice Create a new token pool
   * @param tokenPoolId Token pool ID
   * @param name Name of the token
   * @param description Symbol of the token
   * @param amount Token amount
   */
  function createTokenPool(
    uint256 tokenPoolId,
    string memory name,
    string memory description,
    uint256 amount
  ) external nonReentrant {
    require(
      !tokenPools[tokenPoolId].exists,
      "Token pool with provided ID already exists"
    );

    require(amount > 0, "0 tokens");

    tokenPools[tokenPoolId] = TokenPools.TokenPool({
      name: name,
      description: description,
      tokens: amount,
      reservedTokens: 0,
      claimedTokens: 0,
      exists: true
    });

    balances[tokenPoolId].mint(address(this), amount);

    admins.add(tokenPoolId, msg.sender);

    emit TokenPoolCreated(tokenPoolId);
  }

  /**
   * @notice Get token pool data
   * @param tokenPoolId Token pool identifier
   * @return name Token pool name
   * @return description Token pool description
   * @return tokens Token total supply
   * @return reservedTokens Reserved tokens
   * @return claimedTokens Claimed tokens
   */
  function getTokenPool(uint256 tokenPoolId)
    external
    view
    onlyAdmin(tokenPoolId)
    returns (
      string memory name,
      string memory description,
      uint256 tokens,
      uint256 reservedTokens,
      uint256 claimedTokens
    )
  {
    return (
      tokenPools[tokenPoolId].name,
      tokenPools[tokenPoolId].description,
      tokenPools[tokenPoolId].tokens,
      tokenPools[tokenPoolId].reservedTokens,
      tokenPools[tokenPoolId].claimedTokens
    );
  }

  /**
   * @notice Add admin
   * @param tokenPoolId Token pool identifier
   * @param _address Address of new admin
   */
  function addAdmin(uint256 tokenPoolId, address _address)
    external
    onlyAdmin(tokenPoolId)
  {
    admins.add(tokenPoolId, _address);
    emit AdminAdded(tokenPoolId, _address);
  }

  /**
   * @notice Remove admin
   * @param tokenPoolId Token pool identifier
   * @param _address Address of admin to remove
   */
  function removeAdmin(uint256 tokenPoolId, address _address)
    external
    onlyAdmin(tokenPoolId)
  {
    require(msg.sender != _address, "Can't remove yourself from admins");

    admins.remove(tokenPoolId, _address);
    emit AdminRemoved(tokenPoolId, _address);
  }

  /**
   * @notice Add vesting plan for participant
   * @param tokenPoolId Token pool identifier
   * @param _address Address of the participant
   * @param issueDate Date when vesting plan starts as timestamp
   * @param tokenAmount Token amount to be vested
   * @param intervals Vesting intervals
   * @param uri Certificate file URI
   */
  function addVesting(
    uint256 tokenPoolId,
    address _address,
    uint256 issueDate,
    uint256 tokenAmount,
    Intervals.Interval[] memory intervals,
    string memory uri
  ) external nonReentrant onlyAdmin(tokenPoolId) {
    require(
      tokenPools[tokenPoolId].areTokensAvailable(
        balances[tokenPoolId].balanceOf(address(this)),
        tokenAmount
      )
    );

    _addVesting(tokenPoolId, _address, issueDate, tokenAmount, intervals, uri);
  }

  /**
   * @notice Add multiple participants
   * @param tokenPoolId Token pool identifiers as array
   * @param _addresses Addresses of the participants as array
   * @param issueDates Dates when vesting plan starts as timestamp in array
   * @param intervals Vesting intervals
   * @param uri Certificate file URI
   */
  function addVestings(
    uint256 tokenPoolId,
    address[] memory _addresses,
    uint256[] memory issueDates,
    uint256[] memory tokenAmounts,
    Intervals.Interval[][] memory intervals,
    string[] memory uri
  ) external nonReentrant onlyAdmin(tokenPoolId) {
    require(
      _addresses.length == issueDates.length,
      "Not correct data passed in!"
    );
    require(
      _addresses.length == tokenAmounts.length,
      "Not correct data passed in!"
    );
    require(
      _addresses.length == intervals.length,
      "Not correct data passed in!"
    );
    require(_addresses.length == uri.length, "Not correct data passed in!");

    for (uint256 i; i < _addresses.length; i++) {
      _addVesting(
        tokenPoolId,
        _addresses[i],
        issueDates[i],
        tokenAmounts[i],
        intervals[i],
        uri[i]
      );
    }
  }

  /**
   * @notice Remove participant
   * @param tokenPoolId Token pool identifier
   * @param vestingId Vesting identifier
   * @param _address Address of the participant
   */
  function removeVesting(
    uint256 tokenPoolId,
    uint256 vestingId,
    address _address
  ) external nonReentrant onlyAdmin(tokenPoolId) {
    require(vestings[tokenPoolId][_address].length > 0, "No vestings");
    require(vestings[tokenPoolId][_address].exists(vestingId), "No vesting");
    require(
      vestings[tokenPoolId][_address][vestingId].claimedTokens == 0,
      "Claimed tokens"
    );

    tokenPools[tokenPoolId].reservedTokens = tokenPools[tokenPoolId]
      .reservedTokens
      .sub(vestings[tokenPoolId][_address][vestingId].tokenAmount);

    certificate.burn(
      _address,
      vestings[tokenPoolId][_address][vestingId].certificateId
    );

    vestings[tokenPoolId][_address].remove(vestingId);

    if (vestings[tokenPoolId][_address].length == 0) {
      registerAddresses[tokenPoolId].remove(_address);
    }

    emit VestingRemoved(tokenPoolId, vestingId, _address);
  }

  /**
   * @notice Pause participant vesting plan
   * @param tokenPoolId Token pool identifier
   * @param _address Address of the participant
   * @param pauseDate Pause date as timestamp
   */
  function pauseParticipant(
    uint256 tokenPoolId,
    address _address,
    uint256 pauseDate
  ) external onlyAdmin(tokenPoolId) {
    require(vestings[tokenPoolId][_address].length > 0, "No vestings");

    for (uint256 i; i < vestings[tokenPoolId][_address].length; i++) {
      _pauseVesting(tokenPoolId, i, _address, pauseDate);
    }

    emit ParticipantVestingPaused(tokenPoolId, _address);
  }

  /**
   * @notice Pause vesting
   * @param tokenPoolId Token pool identifier
   * @param vestingId Vesting identifier
   * @param _address Address of the participant
   * @param pauseDate Pause date as timestamp
   */
  function pauseVesting(
    uint256 tokenPoolId,
    uint256 vestingId,
    address _address,
    uint256 pauseDate
  ) external onlyAdmin(tokenPoolId) {
    require(vestings[tokenPoolId][_address].length > 0, "No vestings");

    _pauseVesting(tokenPoolId, vestingId, _address, pauseDate);

    emit VestingPaused(tokenPoolId, vestingId, _address);
  }

  /**
   * @notice Un-pause participant vesting plan
   * @param tokenPoolId Token pool identifier
   * @param _address Address of the participant
   * @param unPauseDate Unpause date as timestamp
   */
  function unPauseParticipant(
    uint256 tokenPoolId,
    address _address,
    uint256 unPauseDate
  ) external onlyAdmin(tokenPoolId) {
    require(vestings[tokenPoolId][_address].length > 0, "No vestings");

    for (uint256 i; i < vestings[tokenPoolId][_address].length; i++) {
      _unPauseVesting(tokenPoolId, i, _address, unPauseDate);
    }

    emit ParticipantVestingUnPaused(tokenPoolId, _address);
  }

  /**
   * @notice Un-pause participant vesting plan
   * @param tokenPoolId Token pool identifier
   * @param vestingId Vesting identifier
   * @param _address Address of the participant
   * @param unPauseDate Unpause date as timestamp
   */
  function unPauseVesting(
    uint256 tokenPoolId,
    uint256 vestingId,
    address _address,
    uint256 unPauseDate
  ) external onlyAdmin(tokenPoolId) {
    require(vestings[tokenPoolId][_address].length > 0, "No vestings");

    _unPauseVesting(tokenPoolId, vestingId, _address, unPauseDate);

    emit VestingUnPaused(tokenPoolId, vestingId, _address);
  }

  /**
   * @notice Terminate participant
   * @param tokenPoolId Token pool identifier
   * @param vestingId Vesting identifier
   * @param _address Address of the participant
   * @param terminationDate Termination date as timestamp
   * @param uri Certificate file URI
   */
  function terminateVesting(
    uint256 tokenPoolId,
    uint256 vestingId,
    address _address,
    uint256 terminationDate,
    string memory uri
  ) external nonReentrant onlyAdmin(tokenPoolId) {
    require(vestings[tokenPoolId][_address].length > 0, "No vestings");

    _terminateVesting(tokenPoolId, vestingId, _address, terminationDate, uri);
  }

  /**
   * @notice Get participant data
   * @param tokenPoolId Token pool identifier
   * @param _address Address of the participant
   * @return ParticipantData structure
   */
  function getParticipant(uint256 tokenPoolId, address _address)
    external
    view
    onlyAdmin(tokenPoolId)
    returns (ParticipantData memory)
  {
    require(vestings[tokenPoolId][_address].length > 0, "No vestings");

    return _getParticipant(tokenPoolId, _address);
  }

  /**
   * @notice Get participants data
   * @param tokenPoolId Token pool identifier
   * @return participantsData Array of ParticipantData structure
   */
  function getParticipants(uint256 tokenPoolId)
    external
    view
    onlyAdmin(tokenPoolId)
    returns (ParticipantData[] memory participantsData)
  {
    uint256 len = registerAddresses[tokenPoolId].length();

    if (len == 0) {
      return new ParticipantData[](0);
    }

    ParticipantData[] memory _participants = new ParticipantData[](len);

    for (uint256 i; i < len; i++) {
      _participants[i] = _getParticipant(
        tokenPoolId,
        registerAddresses[tokenPoolId].at(i)
      );
    }

    return _participants;
  }

  /**
   * @notice Get tokens balance of the address
   * @param tokenPoolId Token pool identifier
   * @param _address Address
   * @return amount Current balance of the address
   */
  function balanceOf(uint256 tokenPoolId, address _address)
    external
    view
    returns (uint256 amount)
  {
    return balances[tokenPoolId].balanceOf(_address);
  }

  /**
   * @notice Get participant vesting schedule
   * @param tokenPoolId Token pool identifier
   * @return vestings Vesting plans
   */
  function getMyVestings(uint256 tokenPoolId)
    external
    view
    returns (Vesting[] memory)
  {
    return _getVestings(tokenPoolId, msg.sender);
  }

  /**
   * @notice Get participant claims
   * @param tokenPoolId Token pool identifier
   * @return claims List of participant claims
   */
  function getMyClaims(uint256 tokenPoolId)
    external
    view
    returns (Claims.Claim[] memory)
  {
    require(vestings[tokenPoolId][msg.sender].length > 0, "No vestings");

    return claims[msg.sender];
  }

  /**
   * @notice Claim tokens
   * @param tokenPoolId Token pool identifier
   * @param _uri New URI for the certificate
   */
  function claimTokens(
    uint256 tokenPoolId,
    uint256 vestingId,
    string memory _uri
  ) external nonReentrant {
    uint256 vestingsLength = vestings[tokenPoolId][msg.sender].length;
    require(vestingsLength > 0, "No vestings");

    require(
      vestings[tokenPoolId][msg.sender][vestingId].terminatedDate == 0,
      "Participant Terminated"
    );

    uint256 amount = calculateClaimableTokens(
      tokenPoolId,
      vestingId,
      msg.sender
    );

    require(amount > 0, "Nothing to claim");

    require(
      vestings[tokenPoolId][msg.sender][vestingId].canClaim(block.timestamp),
      "Can not claim"
    );

    _claimTokens(
      tokenPoolId,
      vestingId,
      msg.sender,
      block.timestamp,
      amount,
      _uri
    );
  }

  function _addVesting(
    uint256 tokenPoolId,
    address _address,
    uint256 issueDate,
    uint256 tokenAmount,
    Intervals.Interval[] memory intervals,
    string memory uri
  ) private {
    require(_address != address(0), "zero address");
    require(tokenAmount > 0, "0 tokens");

    uint256 certId = certificate.print(_address, uri);

    (
      uint256[] memory intervalsEndDate,
      uint256[] memory intervalsAmount
    ) = intervals.serialize(tokenAmount);

    vestings[tokenPoolId][_address].push(
      Vestings.Vesting({
        issueDate: issueDate,
        tokenAmount: tokenAmount,
        terminatedDate: 0,
        exists: true,
        intervalsEndDate: intervalsEndDate,
        intervalsAmount: intervalsAmount,
        lastPausedAt: 0,
        claimedTokens: 0,
        certificateId: certId
      })
    );

    tokenPools[tokenPoolId].reservedTokens = tokenPools[tokenPoolId]
      .reservedTokens
      .add(tokenAmount);

    registerAddresses[tokenPoolId].add(_address);

    emit VestingAdded(
      tokenPoolId,
      vestings[tokenPoolId][_address].length - 1,
      _address,
      issueDate,
      tokenAmount,
      intervals,
      certId
    );
  }

  function _getParticipant(uint256 tokenPoolId, address _address)
    private
    view
    onlyAdmin(tokenPoolId)
    returns (ParticipantData memory)
  {
    return ParticipantData(_address, _getVestings(tokenPoolId, _address));
  }

  function _getVestings(uint256 tokenPoolId, address _address)
    private
    view
    returns (Vesting[] memory)
  {
    uint256 len = vestings[tokenPoolId][_address].length;
    require(len > 0, "No vestings");
    Vesting[] memory _vestings = new Vesting[](len);
    for (uint256 i; i < len; i++) {
      _vestings[i] = Vesting(
        vestings[tokenPoolId][_address][i].issueDate,
        vestings[tokenPoolId][_address][i].tokenAmount,
        vestings[tokenPoolId][_address][i].terminatedDate,
        vestings[tokenPoolId][_address][i].getIntervals(),
        vestings[tokenPoolId][_address][i].claimedTokens,
        calculateClaimableTokens(tokenPoolId, i, _address),
        vestings[tokenPoolId][_address][i].certificateId
      );
    }
    return _vestings;
  }

  function _pauseVesting(
    uint256 tokenPoolId,
    uint256 vestingId,
    address _address,
    uint256 pauseDate
  ) private onlyAdmin(tokenPoolId) {
    vestings[tokenPoolId][_address][vestingId].pause(pauseDate);
  }

  function _unPauseVesting(
    uint256 tokenPoolId,
    uint256 vestingId,
    address _address,
    uint256 unPauseDate
  ) private onlyAdmin(tokenPoolId) {
    vestings[tokenPoolId][_address][vestingId].unPause(unPauseDate);
  }

  function _terminateVesting(
    uint256 tokenPoolId,
    uint256 vestingId,
    address _address,
    uint256 terminationDate,
    string memory uri
  )
    private
    onlyAdmin(tokenPoolId)
    returns (uint256 vestingTokensToClaim, uint256 vestingTokensReverted)
  {
    require(
      terminationDate > vestings[tokenPoolId][_address][vestingId].issueDate,
      "Issue date before termination date"
    );

    uint256 _vestingTokensToClaim;

    if (vestings[tokenPoolId][_address][vestingId].canClaim(terminationDate)) {
      // get tokens that can be vested with termination date
      uint256 claimableTokens = vestings[tokenPoolId][_address][vestingId]
        .getClaimableTokens(terminationDate);
      // get claimed tokens
      uint256 claimedTokens = vestings[tokenPoolId][_address][vestingId]
        .claimedTokens;
      // calculate tokens that are claimable
      _vestingTokensToClaim = claimableTokens.sub(claimedTokens);
    }

    if (_vestingTokensToClaim > 0) {
      _claimTokens(
        tokenPoolId,
        vestingId,
        _address,
        terminationDate,
        _vestingTokensToClaim,
        uri
      );
    }

    uint256 _vestingTokensReverted = vestings[tokenPoolId][_address][vestingId]
      .tokenAmount
      .sub(vestings[tokenPoolId][_address][vestingId].claimedTokens);

    tokenPools[tokenPoolId].reservedTokens = tokenPools[tokenPoolId]
      .reservedTokens
      .sub(_vestingTokensReverted);

    vestings[tokenPoolId][_address][vestingId].terminatedDate = terminationDate;

    emit VestingTerminated(
      tokenPoolId,
      vestingId,
      _address,
      _vestingTokensToClaim,
      _vestingTokensReverted
    );

    return (_vestingTokensToClaim, _vestingTokensReverted);
  }

  function calculateClaimableTokens(
    uint256 tokenPoolId,
    uint256 vestingId,
    address _address
  ) private view returns (uint256) {
    uint256 claimableTokens = vestings[tokenPoolId][_address][vestingId]
      .getClaimableTokens(block.timestamp);
    return
      claimableTokens.sub(
        vestings[tokenPoolId][_address][vestingId].claimedTokens
      );
  }

  function _claimTokens(
    uint256 tokenPoolId,
    uint256 vestingId,
    address _address,
    uint256 claimDate,
    uint256 amount,
    string memory uri
  ) private {
    vestings[tokenPoolId][_address][vestingId].claimedTokens = vestings[
      tokenPoolId
    ][_address][vestingId].claimedTokens.add(amount);

    tokenPools[tokenPoolId].claimedTokens = tokenPools[tokenPoolId]
      .claimedTokens
      .add(amount);

    claims[_address].push(Claims.Claim(vestingId, claimDate, amount));

    tokenPools[tokenPoolId].reservedTokens = tokenPools[tokenPoolId]
      .reservedTokens
      .sub(amount);

    balances[tokenPoolId].transfer(address(this), _address, amount);

    setParticipantCertificate(tokenPoolId, vestingId, _address, uri);

    emit TokensClaimed(tokenPoolId, _address, amount);
  }

  function setParticipantCertificate(
    uint256 tokenPoolId,
    uint256 vestingId,
    address _address,
    string memory _uri
  ) private {
    require(vestings[tokenPoolId][_address][vestingId].exists, "No vesting");

    uint256 certificateId = vestings[tokenPoolId][_address][vestingId]
      .certificateId;
    require(certificateId != 0, "No certificate");

    certificate.setUri(certificateId, _uri);
  }

  function dummy10() external pure returns (uint256) {
    return 10;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: Unlicensed

pragma solidity 0.8.15;

import "./libraries/Intervals.sol";

struct ParticipantData {
  address _address;
  Vesting[] vestings;
}

struct Vesting {
  uint256 issueDate;
  uint256 tokenAmount;
  uint256 terminatedDate;
  Intervals.Interval[] intervals;
  uint256 claimedTokens;
  uint256 claimableTokens;
  uint256 certificateId;
}

// SPDX-License-Identifier: Unlicensed

pragma solidity 0.8.15;

import {IERC1155MetadataURIUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/IERC1155MetadataURIUpgradeable.sol";

interface ICertificate is IERC1155MetadataURIUpgradeable {
  function print(address to, string memory _uri) external returns (uint256);

  function burn(address from, uint256 vestingId) external;

  function setUri(uint256 id, string memory _uri) external;
}

// SPDX-License-Identifier: Unlicensed

pragma solidity 0.8.15;

import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./Intervals.sol";

library VestingCalculator {
  using SafeMath for uint256;

  function calculateClaimableTokens(
    uint256 time,
    uint256 issueDate,
    Intervals.Interval[] memory intervals
  ) internal pure returns (uint256) {
    if (time <= issueDate) {
      return 0;
    }

    uint256 claimableTokens;

    for (uint256 i; i < intervals.length; i++) {
      if (intervals[i].endDate <= time) {
        claimableTokens = claimableTokens.add(intervals[i].amount);
      }
    }

    return claimableTokens;
  }
}

// SPDX-License-Identifier: Unlicensed

pragma solidity 0.8.15;

import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";

library TokenPools {
  using SafeMath for uint256;

  struct TokenPool {
    string name;
    string description;
    uint256 tokens;
    uint256 reservedTokens;
    uint256 claimedTokens;
    bool exists;
  }

  function areTokensAvailable(
    TokenPool storage self,
    uint256 balance,
    uint256 tokenAmount
  ) internal view returns (bool) {
    return balance.sub(self.reservedTokens) >= tokenAmount;
  }
}

// SPDX-License-Identifier: Unlicensed

pragma solidity 0.8.15;

import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./VestingCalculator.sol";
import "./Intervals.sol";

library Vestings {
  using SafeMath for uint256;

  struct Vesting {
    uint256 issueDate;
    // total tokens to be vested
    uint256 tokenAmount;
    // termination date as timestamp, if not specified then 0
    uint256 terminatedDate;
    // convenience for checking if a participant exists
    bool exists;
    // Interval end date
    uint256[] intervalsEndDate;
    // Interval token amount
    uint256[] intervalsAmount;
    // when was participant last paused as timestamp
    uint256 lastPausedAt;
    // claimed tokens total
    uint256 claimedTokens;
    // certificate id
    uint256 certificateId;
  }

  function getClaimableTokens(Vestings.Vesting storage self, uint256 claimDate)
    internal
    view
    returns (uint256)
  {
    uint256 len = self.intervalsEndDate.length;
    Intervals.Interval[] memory intervals = new Intervals.Interval[](len);

    for (uint256 i; i < len; i++) {
      intervals[i] = Intervals.Interval({
        endDate: self.intervalsEndDate[i],
        amount: self.intervalsAmount[i]
      });
    }

    return
      VestingCalculator.calculateClaimableTokens(
        claimDate,
        self.issueDate,
        intervals
      );
  }

  function getIntervals(Vestings.Vesting storage self)
    internal
    view
    returns (Intervals.Interval[] memory)
  {
    uint256 len = self.intervalsEndDate.length;
    Intervals.Interval[] memory intervals = new Intervals.Interval[](len);

    for (uint256 i; i < len; i++) {
      intervals[i] = Intervals.Interval({
        endDate: self.intervalsEndDate[i],
        amount: self.intervalsAmount[i]
      });
    }

    return intervals;
  }

  function canClaim(Vestings.Vesting storage self, uint256 atDate)
    internal
    view
    returns (bool)
  {
    // Terminated participant's can't claim
    if (self.terminatedDate > 0) {
      return false;
    }

    // When paused can't claim when last paused is less than cliff period
    if (self.lastPausedAt > 0) {
      return false;
    }

    return atDate >= getIntervals(self)[0].endDate;
  }

  function pause(Vestings.Vesting storage self, uint256 pauseDate) internal {
    require(self.lastPausedAt == 0, "Already paused");
    self.lastPausedAt = pauseDate;
  }

  function unPause(Vestings.Vesting storage self, uint256 unpauseDate)
    internal
  {
    require(self.lastPausedAt > 0, "Not paused");

    uint256 pausedFor = unpauseDate.sub(self.lastPausedAt);

    uint256 len = self.intervalsEndDate.length;

    for (uint256 i; i < len; i++) {
      if (self.intervalsEndDate[i] >= self.lastPausedAt) {
        self.intervalsEndDate[i] = self.intervalsEndDate[i].add(pausedFor);
      }
    }

    self.lastPausedAt = 0;
  }
}

library VestingsList {
  function remove(Vestings.Vesting[] storage self, uint256 index) internal {
    for (uint256 i = index; i < self.length - 1; i++) {
      self[i] = self[i + 1];
    }

    self.pop();
  }

  function exists(Vestings.Vesting[] storage self, uint256 index)
    internal
    view
    returns (bool)
  {
    if (index >= self.length) {
      return false;
    }

    return self[index].exists;
  }
}

// SPDX-License-Identifier: Unlicensed

pragma solidity 0.8.15;

import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";

library Claims {
  using SafeMath for uint256;

  struct Claim {
    uint256 vestingId;
    uint256 date;
    uint256 amount;
  }

  function getClaimedAmount(
    mapping(address => Claims.Claim[]) storage self,
    address participantAddress
  ) internal view returns (uint256) {
    uint256 claimedAmount;

    for (uint32 i; i < self[participantAddress].length; i++) {
      claimedAmount = claimedAmount.add(self[participantAddress][i].amount);
    }

    return claimedAmount;
  }
}

// SPDX-License-Identifier: Unlicensed

pragma solidity 0.8.15;

library Admins {
  function add(
    mapping(uint256 => mapping(address => bool)) storage self,
    uint256 tokenPoolId,
    address adminAddress
  ) internal {
    self[tokenPoolId][adminAddress] = true;
  }

  function remove(
    mapping(uint256 => mapping(address => bool)) storage self,
    uint256 tokenPoolId,
    address adminAddress
  ) internal {
    self[tokenPoolId][adminAddress] = false;
  }

  function has(
    mapping(uint256 => mapping(address => bool)) storage self,
    uint256 tokenPoolId,
    address adminAddress
  ) internal view returns (bool) {
    return self[tokenPoolId][adminAddress];
  }
}

// SPDX-License-Identifier: Unlicensed

pragma solidity 0.8.15;

library Intervals {
  struct Interval {
    uint256 endDate;
    uint256 amount;
  }

  function serialize(Intervals.Interval[] memory self, uint256 tokenAmount)
    internal
    pure
    returns (
      uint256[] memory intervalsEndDate,
      uint256[] memory intervalsAmount
    )
  {
    uint256 len = self.length;
    require(len > 0, "No intervals");

    uint256[] memory _intervalsEndDate = new uint256[](len);
    uint256[] memory _intervalsAmount = new uint256[](len);

    uint256 checksum;

    for (uint256 i; i < len; i++) {
      _intervalsEndDate[i] = self[i].endDate;
      _intervalsAmount[i] = self[i].amount;

      checksum += self[i].amount;
    }

    require(tokenAmount == checksum, "Token amounts not matching");

    return (_intervalsEndDate, _intervalsAmount);
  }
}

// SPDX-License-Identifier: Unlicensed

pragma solidity 0.8.15;

import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";

library Balances {
  using SafeMath for uint256;

  function balanceOf(mapping(address => uint256) storage self, address account)
    internal
    view
    returns (uint256)
  {
    return self[account];
  }

  function mint(
    mapping(address => uint256) storage self,
    address account,
    uint256 amount
  ) internal {
    require(account != address(0), "mint to the zero address");

    self[account] = self[account].add(amount);
  }

  function transfer(
    mapping(address => uint256) storage self,
    address from,
    address to,
    uint256 amount
  ) internal {
    require(from != address(0), "transfer from the zero address");
    require(to != address(0), "transfer to the zero address");

    uint256 fromBalance = self[from];
    require(fromBalance >= amount, "transfer amount exceeds balance");
    unchecked {
      self[from] = fromBalance.sub(amount);
    }
    self[to] = self[to].add(amount);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155Upgradeable.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURIUpgradeable is IERC1155Upgradeable {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}