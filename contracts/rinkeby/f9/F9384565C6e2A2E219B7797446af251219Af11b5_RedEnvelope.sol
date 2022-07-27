// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract RedEnvelope {
  struct Envelopes{
    address creator;
    uint tokenAmount;
    uint participantsLimit;
    address[] participants;
    uint[] participantsPrize;
    string message;
    uint creationTime;
  }
  mapping(bytes => Envelopes) envelope;
  mapping(address => bytes []) receiverToEnvelope;
  mapping(address => bytes []) creatorToEnvelope;

  event EnvelopCreated(bool created);
  event Claimed(bool claimed);
  event CreatorWithdrawn(bool withdrawn);
	constructor () 
	{
	}

	/********************************************************
	*                                                       *
	*                     MAIN FUNCTIONS                    *
	*                                                       *
	********************************************************/

  /// @notice create an envelope and share money with your people
  /// @param _tokenAmount amount of weis to share
  /// @param _message welcome message of the envelope
  /// @dev creates envelope and stores crypto in this contract to later on distribute with participants
	function createEnvelope(uint _tokenAmount, uint _participantsLimit, string memory _message) external payable returns(bytes memory _envelopeId) {
    require(msg.value == _tokenAmount, "Insufficient funds");
    _envelopeId =  abi.encode(msg.sender, block.timestamp);
    envelope[_envelopeId].creator = msg.sender;
    envelope[_envelopeId].tokenAmount = _tokenAmount;
    envelope[_envelopeId].participantsLimit = _participantsLimit;
    envelope[_envelopeId].message = _message;
    envelope[_envelopeId].creationTime = block.timestamp;
    creatorToEnvelope[msg.sender].push(_envelopeId);
    emit EnvelopCreated(true);
	}

  /// @notice Open envelope before others and get crypto gift!
  /// @param _envelopeId id of envelope in bytes256
  /// @dev contract distributes crypto to msg.sender
  function claim(bytes memory _envelopeId) external {
    Envelopes storage _envelope = envelope[_envelopeId];
    uint _currentParticipant = _envelope.participants.length;
    require(_envelope.participantsLimit >  _currentParticipant, "max participants exceeded");
    require(_envelope.tokenAmount > 0, "tokens already distributed");
    _envelope.participants[_currentParticipant + 1] = msg.sender;
    uint _amountToDeliver;
    // If it is the last possible participant it shares the remaining crypto. Otherwise it shares a random amount of crypto
    if(_envelope.participantsLimit != _currentParticipant) {
      _amountToDeliver = _getAmountToDeliver(_currentParticipant, _envelope.tokenAmount);
    } else {
      _amountToDeliver = _envelope.tokenAmount;
    }
    _envelope.tokenAmount -= _amountToDeliver;
    (bool sent, ) = payable(msg.sender).call{value: _amountToDeliver}("");
    require(sent, "Failed to send Ether");
    receiverToEnvelope[msg.sender].push(_envelopeId);
    _envelope.participantsPrize[_currentParticipant + 1] = _amountToDeliver;
    emit Claimed(true);
  }

  /// @notice Claim your crypto locked in contract
  /// @param _envelopeId id of envelope in bytes256
  /** @dev In case it's been more than 24 hours and participants have not claimed all possible crypto,
           the envelope creator can claim crypto locked in this contract**/
  function creatorWithdraw(bytes memory _envelopeId) external {
    Envelopes storage _envelope = envelope[_envelopeId];
    require(_envelope.creationTime + 86400 >= block.timestamp, "Too soon");
    require(_envelope.tokenAmount == 0, "Empty envelope");
    require(_envelope.creator == msg.sender, "Not creator");
    _envelope.tokenAmount = 0;
    (bool sent, ) = payable(msg.sender).call{value: _envelope.tokenAmount}("");
    require(sent, "Failed to send Ether");
    emit  CreatorWithdrawn(true);
  }

	/********************************************************
  *                                                       *
  *                INTERNAL FUNCTIONS                     *
  *                                                       *
  ********************************************************/

  /// @dev used in claim function
  /// @param _participantsCounter current number of participants for the envelope
  /// @param _tokenAmount amount of crypto left in the envelope
  /// @return _amountToDeliver amount of crypto to be deliver to claimer. It is random number between 1 and _tokenAmount
  function _getAmountToDeliver(uint _participantsCounter, uint _tokenAmount) internal view returns (uint _amountToDeliver) {
    _amountToDeliver = (uint(keccak256(abi.encodePacked(_participantsCounter,block.timestamp))) % _tokenAmount) + 1;
  }

	/********************************************************
  *                                                       *
  *                     GET FUNCTIONS                     *
  *                                                       *
  ********************************************************/

  /// @dev used in front-end to display creator envelope data
  /// @param _creatorAddress address of envelope creator
  /// @return _envelopes All envelopes created by user
  function getCreatorEnvelopes(address _creatorAddress) external view returns (Envelopes[] memory) {
    bytes[] memory _creatorToEnvelope = creatorToEnvelope[_creatorAddress];
    Envelopes[] memory _envelopes = new Envelopes[](_creatorToEnvelope.length);
    for(uint i = 0; i < _creatorToEnvelope.length; i++) {
      _envelopes[i] = Envelopes(
        _envelopes[i].creator,
        _envelopes[i].tokenAmount,
        _envelopes[i].participantsLimit,
        _envelopes[i].participants,
        _envelopes[i].participantsPrize,
        _envelopes[i].message,
        _envelopes[i].creationTime
      );
    }
    return _envelopes;
  }

  /// @dev used in front-end to display receiver envelope data
  /// @param _receiverAddress address of envelope creator
  /// @return _envelopes All envelopes a user has opened
  function getReceiverEnvelopes(address _receiverAddress) external view returns (Envelopes[] memory) {
    bytes[] memory _receiverToEnvelope = receiverToEnvelope[_receiverAddress];
    Envelopes[] memory _envelopes = new Envelopes[](_receiverToEnvelope.length);
    for(uint i = 0; i < _receiverToEnvelope.length; i++) {
      _envelopes[i] = Envelopes(
        _envelopes[i].creator,
        _envelopes[i].tokenAmount,
        _envelopes[i].participantsLimit,
        _envelopes[i].participants,
        _envelopes[i].participantsPrize,
        _envelopes[i].message,
        _envelopes[i].creationTime
      );
    }
    return _envelopes;
  }
}