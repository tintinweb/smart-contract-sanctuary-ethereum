// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/**
 * @title MarrySign empowers a couple to get crypto-married.
 */
contract MarrySign {
  enum AgreementState {
    Created,
    Accepted,
    Refused,
    Terminated
  }

  /**
   * @notice The Agreement structure is used to store agreement data.
   */
  struct Agreement {
    /// @dev Unique hash of the agreement which is used as its ID.
    bytes32 id;
    /// @dev The first party of the agreement (agreement starter).
    address alice;
    /// @dev The second party fo the agreement (agreement acceptor).
    address bob;
    /// @dev Vow text.
    bytes content;
    /// @dev A penalty which the terminating partner pays for agreement termination (in Wei).
    uint256 terminationCost;
    /// @dev Agreement status.
    AgreementState state;
    /// @dev Create/update date in seconds from Unix epoch.
    uint256 updatedAt;
  }

  /**
   * @notice The Pointer structure is used to detect deleted agreements. If Pointer.isSet == false, then it's a deleted agreement.
   */
  struct Pointer {
    uint256 index;
    bool isSet;
  }

  /// @dev Some features are only available to the contract owner, e.g. withdrawal.
  error CallerIsNotOwner();
  /// @dev Agreement.content cannot be empty.
  error EmptyContent();
  /// @dev When Bob is not set.
  error BobNotSpecified();
  /// @dev We use it to check Agreement's createdAt, updatedAt, etc. timestamps.
  error InvalidTimestamp();
  /// @dev When the caller is not authorized to call a function.
  error AccessDenied();
  /// @dev We should check if the termination cost passed is equivalent to that the agreement creator set.
  error MustPayExactTerminationCost();
  /// @dev We should check if the amount passed is equivalent to our fee value.
  error MustPayExactFee();
  /// @dev if there is no an active agreement by given criteria.
  error AgreementNotFound();

  /**
   * @notice Is emitted when a new agreement is created.
   * @param id {bytes32} The newly-created agreement ID.
   */
  event AgreementCreated(bytes32 id);
  /**
   * @notice Is emitted when the agreement is accepted by the second party (Bob).
   * @param id {bytes32} The accepted agreement ID.
   */
  event AgreementAccepted(bytes32 id);
  /**
   * @notice Is emitted when the agreement is refused by any party.
   * @param id {bytes32} The refused agreement ID.
   */
  event AgreementRefused(bytes32 id);
  /**
   * @notice Is emitted when the agreement is terminated by any party.
   * @param id {bytes32} The terminated agreement ID.
   */
  event AgreementTerminated(bytes32 id);

  /// @dev The contract owner.
  address payable private owner;

  /// @dev Our fee in Wei. 0 by default.
  uint256 private fee = 0;

  /// @dev List of all agreements created.
  Agreement[] private agreements;
  /// @dev Maps Agreement.id to Agreement index for easier navigation.
  mapping(bytes32 => Pointer) private pointers;

  /// @dev Used for making Agreement.IDs trully unique.
  uint256 private randomFactor;

  /**
   * @notice Contract constructor.
   */
  constructor() payable {
    owner = payable(msg.sender);
  }

  /*
   * @notice Get service fee.
   * @return newFee {uint256} Our fee in Wei.
   */
  function getFee() public view returns (uint256) {
    return fee;
  }

  /**
   * @notice Get the number of all agreements.
   * @return {uint256}
   */
  function getAgreementCount() public view returns (uint256) {
    return agreements.length;
  }

  /**
   * @notice Get an agreement.
   * @param id {bytes32} Agreement ID.
   * @return {Agreement}
   */
  function getAgreement(bytes32 id) public view returns (Agreement memory) {
    // If Pointer.isSet=false, it means that this pointer "doesn't exist".
    if (!pointers[id].isSet) {
      revert AgreementNotFound();
    }

    if (bytes32(agreements[pointers[id].index].id).length == 0) {
      revert AgreementNotFound();
    }

    return agreements[pointers[id].index];
  }

  /**
   * @notice Get an agreement by an address of one of the partners.
   * @param partnerAddress {address} Partner's address.
   * @return {Agreement}
   */
  function getAgreementByAddress(
    address partnerAddress
  ) public view returns (Agreement memory) {
    for (uint256 i = 0; i < getAgreementCount(); i++) {
      if (
        agreements[i].state != AgreementState.Created &&
        agreements[i].state != AgreementState.Accepted
      ) {
        continue;
      }

      if (
        agreements[i].alice == partnerAddress ||
        agreements[i].bob == partnerAddress
      ) {
        return agreements[i];
      }
    }

    revert AgreementNotFound();
  }

  /**
   * @notice Get all agreements paginated.
   * @param _pageNum {uint256} A page number, which should be greater than 0.
   * @param _resultsPerPage {uint256} A number of agreements per page, which should be greater than 0.
   * @return {Agreement[]}
   */
  function getPaginatedAgreements(
    uint256 _pageNum,
    uint256 _resultsPerPage
  ) public view returns (Agreement[] memory) {
    // Return emptry array if the agreement list is empty or the requested page number is 0.
    if (agreements.length == 0 || _pageNum == 0 || _resultsPerPage == 0) {
      return new Agreement[](0);
    }

    uint256 index = _resultsPerPage * _pageNum - _resultsPerPage;

    // Return emptry array if the requested index is out of bounds.
    if (index < 0 || index > agreements.length - 1) {
      return new Agreement[](0);
    }

    Agreement[] memory results = new Agreement[](_resultsPerPage);

    uint256 _returnCounter = 0;
    for (index; index < _resultsPerPage * _pageNum; index++) {
      if (index < agreements.length) {
        results[_returnCounter] = agreements[index];
      } else {
        return results;
      }

      _returnCounter++;
    }

    return results;
  }

  /**
   * @notice Get the number of accepted agreements.
   * @return {uint256}
   */
  function getAcceptedAgreementCount() public view returns (uint256) {
    uint256 acceptedCount = 0;

    for (uint256 i = 0; i < getAgreementCount(); i++) {
      if (agreements[i].state != AgreementState.Accepted) {
        continue;
      }

      acceptedCount++;
    }

    return acceptedCount;
  }

  /**
   * @notice Get accepted agreements.
   * @dev @todo: Optimize : there are two similar loops.
   * @dev @todo: Add pagination to not go over time/size limits.
   * @return {Agreement[]}
   */
  function getAcceptedAgreements() public view returns (Agreement[] memory) {
    uint256 acceptedCount = getAcceptedAgreementCount();

    Agreement[] memory acceptedAgreements = new Agreement[](acceptedCount);

    uint256 j = 0;
    for (uint256 i = 0; i < getAgreementCount(); i++) {
      if (agreements[i].state != AgreementState.Accepted) {
        continue;
      }

      acceptedAgreements[j] = agreements[i];
      j++;
    }

    return acceptedAgreements;
  }

  /**
   * @notice Create a new agreement and pay the service fee if set.
   * @param bob {address} The second party's adddress.
   * @param content {bytes} The vow content.
   * @param terminationCost {uint256} The agreement termination cost.
   * @param createdAt {uint256} The creation date in seconds since the Unix epoch.
   */
  function createAgreement(
    address bob,
    bytes memory content,
    uint256 terminationCost,
    uint256 createdAt
  ) public payable validTimestamp(createdAt) {
    if (content.length == 0) {
      revert EmptyContent();
    }
    if (bob == address(0)) {
      revert BobNotSpecified();
    }

    // Make sure the sent amount is the same as our fee value.
    if (msg.value != fee) {
      revert MustPayExactFee();
    }

    // Charge our fee if set.
    if (fee != 0) {
      owner.transfer(fee);
    }

    // Every agreement gets its own randomFactor to make sure all agreements have unique IDs.
    randomFactor++;

    bytes32 id = generateAgreementId(
      msg.sender,
      bob,
      content,
      terminationCost,
      randomFactor
    );

    Agreement memory agreement = Agreement(
      id,
      msg.sender,
      bob,
      content,
      terminationCost,
      AgreementState.Created,
      createdAt
    );

    agreements.push(agreement);

    pointers[id] = Pointer(getAgreementCount() - 1, true);

    emit AgreementCreated(id);
  }

  /*
   * @notice Accept the agreement and pay the service fee (if set).
   * @param id {bytes32} The agreement ID.
   * @param acceptedAt {uint256} The acceptance date in seconds since the Unix epoch.
   */
  function acceptAgreement(
    bytes32 id,
    uint256 acceptedAt
  ) public payable validTimestamp(acceptedAt) {
    Agreement memory agreement = getAgreement(id);

    if (msg.sender != agreement.bob) {
      revert AccessDenied();
    }

    // Make sure the sent amount is the same as our fee value.
    if (msg.value != fee) {
      revert MustPayExactFee();
    }

    // Charge our fee if set.
    if (fee != 0) {
      owner.transfer(fee);
    }

    agreements[pointers[id].index].state = AgreementState.Accepted;
    agreements[pointers[id].index].updatedAt = acceptedAt;

    emit AgreementAccepted(id);
  }

  /*
   * @notice Refuse an agreement by either Alice or Bob.
   * @param id {bytes3} The agreement ID.
   * @param refusedAt {uint256} The refusal date in seconds since the Unix epoch.
   */
  function refuseAgreement(
    bytes32 id,
    uint256 refusedAt
  ) public validTimestamp(refusedAt) {
    Agreement memory agreement = getAgreement(id);

    if (agreement.bob != msg.sender && agreement.alice != msg.sender) {
      revert AccessDenied();
    }

    agreements[pointers[id].index].state = AgreementState.Refused;
    agreements[pointers[id].index].updatedAt = refusedAt;

    emit AgreementRefused(id);
  }

  /*
   * @notice Terminate an agreement by either Alice or Bob and pay compensation (if set).
   * @param id {bytes32} The agreement ID.
   */
  function terminateAgreement(bytes32 id) public payable {
    Agreement memory agreement = getAgreement(id);

    if (agreement.bob != msg.sender && agreement.alice != msg.sender) {
      revert AccessDenied();
    }

    // Make sure the requested compensation matches that which is stated in the agreement.
    if (msg.value != agreement.terminationCost) {
      revert MustPayExactTerminationCost();
    }

    if (agreement.terminationCost != 0) {
      // Pay compensation to the opposite partner.
      if (agreement.alice == msg.sender) {
        // Alice pays Bob the compensation.
        payable(agreement.bob).transfer(msg.value);
      } else {
        // Bob pays Alice the compensation.
        payable(agreement.alice).transfer(msg.value);
      }
    }

    delete agreements[pointers[id].index];
    // We have to somehow distinguish the terminated agreement from active ones.
    // That's because the array item deletion doesn't factually remove the element from the array.
    agreements[pointers[id].index].state = AgreementState.Terminated;

    emit AgreementTerminated(id);
  }

  /*
   * @notice Transfer contract funds to the contract-owner (withdraw).
   */
  function withdraw() public onlyOwner {
    owner.transfer(address(this).balance);
  }

  /*
   * @notice Set service fee.
   * @param _fee {uint256} Our fee in Wei.
   */
  function setFee(uint256 _fee) public onlyOwner {
    fee = _fee;
  }

  /**
   * @notice Generate agreement hash which is used as its ID.
   */
  function generateAgreementId(
    address alice,
    address bob,
    bytes memory content,
    uint256 terminationCost,
    uint256 randomFactorParam
  ) private pure returns (bytes32) {
    bytes memory hashBytes = abi.encode(
      alice,
      bob,
      // @todo: Think about excluding content from here because if it's long, it can affect performance.
      content,
      terminationCost,
      randomFactorParam
    );
    return keccak256(hashBytes);
  }

  /**
   * @notice Check the validity of the timespamp.
   * @param timestamp {uint256} The timestamp being validated.
   */
  modifier validTimestamp(uint256 timestamp) {
    // @todo Improve the validation.
    // The condition timestamp == 0 || timestamp > block.timestamp + 15 seconds || timestamp < block.timestamp - 1 days
    // doesn't work in tests for some reason.
    if (timestamp == 0) {
      revert InvalidTimestamp();
    }
    _;
  }

  /**
   * @notice Check whether the caller is the contract-owner.
   */
  modifier onlyOwner() {
    if (msg.sender != owner) {
      revert CallerIsNotOwner();
    }
    _;
  }
}