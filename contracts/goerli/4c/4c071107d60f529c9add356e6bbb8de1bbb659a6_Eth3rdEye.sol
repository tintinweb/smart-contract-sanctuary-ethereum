// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import "./structs.sol";

contract Eth3rdEye {

  // Session management
  mapping(uint16 => Session) sessionsById;
  uint16 public lastSessionIndex;
  mapping(bytes32 => string) public predictions;

  // Accuracy management
  mapping(address => uint32) public accuracy;
  mapping(address => uint32) public attempts;

  constructor() {
    lastSessionIndex = 0;
  }

  // TODO: Cannot start session until submission epoch is over
  function startSession( uint16 sessionIndex, bytes32 commitment ) public {
    uint16 nextIndex = lastSessionIndex + 1;

    require( nextIndex == sessionIndex, "Unexpected session index" );
    require( sessionsById[sessionIndex].targetCommitment == 0, "Session already started" );

    string memory emptyTarget = "";
    Session memory s = Session(commitment, emptyTarget, block.timestamp, msg.sender);

    sessionsById[sessionIndex] = s;
    lastSessionIndex = sessionIndex;
  }

  function submitPrediction(uint16 sessionIndex, string calldata prediction) public {

    bytes32 predictionKey = keccak256(abi.encode(sessionIndex, msg.sender));

    predictions[predictionKey] = prediction;

    attempts[msg.sender]++;
  }

  // TODO: Ensure that reveal period expires after a time period to prevent non-reveals blocking
  function revealTarget(uint16 sessionIndex, string calldata salt, string calldata target) public {
    Session storage s = sessionsById[sessionIndex];

    // TODO: Ensure epoch has ended

    require( s.tasker == msg.sender, "Only the tasker can reveal target" );

    bytes32 calculatedCommitment = keccak256(abi.encode(salt, target));

    require( s.targetCommitment == calculatedCommitment, "Target commitments must match" );
    
    // Save the target
    s.target = target;
  }

  function claimAccuracy(uint16 sessionIndex, string calldata prediction ) public {

    bytes32 predictionKey = keccak256(abi.encode(sessionIndex, msg.sender));
    string memory predictionValue = predictions[predictionKey];
    
    bool predictionCommitmentMatch = bool(keccak256(abi.encode(prediction)) == keccak256(abi.encode(predictionValue)));
    require( predictionCommitmentMatch, "Cannot claimAccuracy with differing commitments" );
    Session memory s = sessionsById[sessionIndex];

    require( bytes(s.target).length != 0, "Target not revealed");

    bool targetsMatch = keccak256(abi.encode(prediction)) == keccak256(abi.encode(s.target));
    
    if(targetsMatch){
      accuracy[msg.sender]++;
    }
  }

  function getSession (uint16 sessionIndex) public view returns (Session memory s) {
    return sessionsById[sessionIndex];
  }

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

struct Session  {
  bytes32 targetCommitment;
  string target;
  uint startedAt;
  address tasker;
}