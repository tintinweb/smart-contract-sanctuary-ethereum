// SPDX-License-Identifier: GPL-2.0

pragma solidity ^0.8.10;

contract System {
    Proxy public _proxy;


    constructor(Proxy proxy_) {
      _proxy = proxy_; 
    }


    function KEYCODE() external pure virtual returns (bytes3) {}


    modifier onlyPolicy {
        require (_proxy.approvedPolicies( msg.sender ), "onlyPolicy(): only approved policies can call this function");
        _;
    }
}


contract Policy {
  Proxy public _proxy;


  constructor(Proxy proxy_) {
      _proxy = proxy_; 
  }


  function requireSystem(bytes3 keycode_) internal view returns (address) {
    address systemForKeycode = _proxy.getSystemForKeycode(keycode_);

    require(systemForKeycode != address(0), "cannot _requireSytem(): system does not exist" );

    return systemForKeycode;
  }


  function configureSystems() virtual external onlyProxy {}


  modifier onlyProxy {
    require (msg.sender == address(_proxy), "onlyProxy(): only the Proxy can call this function");
    _;
  }

}


enum Actions {
  InstallSystem,
  UpgradeSystem,
  ApprovePolicy,
  TerminatePolicy,
  ChangeExecutive
}


struct Instruction {
  Actions action;
  address target;
}


contract Proxy{

  address public executive; 

  constructor() {
    executive = msg.sender;
  }
  
  modifier onlyExecutive() {
    require ( msg.sender == executive, "onlyExecutive(): only the assigned executive can call the function" );
    _;
  }


  /////////////////////////////////////////////////////////////////////////////////////
  //                                  EPOCH STUFF                                    //
  /////////////////////////////////////////////////////////////////////////////////////
  

  uint256 public startingEpochTimestamp; 
  uint256 public constant epochLength = 60 * 60 * 24 * 7; // number of seconds in a week
  bool public isLaunched;


  function currentEpoch() public view returns (uint256) {
    if ( isLaunched == true && block.timestamp >= startingEpochTimestamp ) {
      return (( block.timestamp - startingEpochTimestamp ) / epochLength ) + 1;
    } else {
      return 0;
    }
  }

  function launch() external onlyExecutive {
    require (isLaunched == false, "cannot launch(): Proxy is already launched");
    startingEpochTimestamp = epochLength * (( block.timestamp / epochLength ) + 1 );
    isLaunched = true;
  }


  ///////////////////////////////////////////////////////////////////////////////////////
  //                                 DEPENDENCY MANAGEMENT                             //
  ///////////////////////////////////////////////////////////////////////////////////////


  mapping(bytes3 => address) public getSystemForKeycode; // get contract for system keycode
  mapping(address => bytes3) public getKeycodeForSystem; // get system keycode for contract
  mapping(address => bool) public approvedPolicies; // whitelisted apps
  address[] public allPolicies;

  event ActionExecuted(Actions action, address target);
  event AllPoliciesReconfigured(uint16 currentEpoch);

  
  function executeAction(Actions action_, address target_) external onlyExecutive {
    if (action_ == Actions.InstallSystem) {
      _installSystem(target_); 

    } else if (action_ == Actions.UpgradeSystem) {
      _upgradeSystem(target_); 

    } else if (action_ == Actions.ApprovePolicy) {
      _approvePolicy(target_); 

    } else if (action_ == Actions.TerminatePolicy) {
      _terminatePolicy(target_); 
    
    } else if (action_ == Actions.ChangeExecutive) {
      // require Proxy to install the executive system before calling ChangeExecutive on it
      require(getKeycodeForSystem[target_] == "EXC", "cannot changeExecutive(): target is not the Executive system");
      executive = target_;
    }

    emit ActionExecuted(action_, target_);
  }


  function _installSystem(address newSystem_ ) internal {
    bytes3 keycode = System(newSystem_).KEYCODE();
    
    // @NOTE check newSystem_ != 0
    require( getSystemForKeycode[keycode] == address(0), "cannot _installSystem(): Existing system found for keycode");

    getSystemForKeycode[keycode] = newSystem_;
    getKeycodeForSystem[newSystem_] = keycode;
  }


  function _upgradeSystem(address newSystem_ ) internal {
    bytes3 keycode = System(newSystem_).KEYCODE();
    address oldSystem = getSystemForKeycode[keycode];
    
    require(oldSystem != address(0) && oldSystem != newSystem_, "cannot _upgradeSystem(): an existing system must be upgraded to a new system");

    getKeycodeForSystem[oldSystem] = bytes3(0);
    getKeycodeForSystem[newSystem_] = keycode;
    getSystemForKeycode[keycode] = newSystem_;

    _reconfigurePolicies();
  }


  function _approvePolicy(address policy_ ) internal {
    require( approvedPolicies[policy_] == false, "cannot _approvePolicy(): Policy is already approved" );

    approvedPolicies[policy_] = true;
    
    allPolicies.push(policy_);
    Policy(policy_).configureSystems();
  }

  function _terminatePolicy(address policy_ ) internal {
    require( approvedPolicies[policy_] == true, "cannot _terminatePolicy(): Policy is not approved" );
    
    approvedPolicies[policy_] = false;
  }


  function _reconfigurePolicies() internal {
    for (uint i=0; i<allPolicies.length; i++) {
      address policy_ = allPolicies[i];
      if (approvedPolicies[policy_]) {
        Policy(policy_).configureSystems();
      }
    }
  }
}

// SPDX-License-Identifier: GPL-2.0

pragma solidity ^0.8.11;
// EXE is the execution engine for the OS.

import "../Proxy.sol";

contract Executive is System {


  /////////////////////////////////////////////////////////////////////////////////
  //                           Proxy Proxy Configuration                         //
  /////////////////////////////////////////////////////////////////////////////////


  constructor(Proxy proxy_) System(proxy_) {
    // instructionsForId[0];
  }

  function KEYCODE() external pure override returns (bytes3) { return "EXC"; }


  /////////////////////////////////////////////////////////////////////////////////
  //                              System Variables                               //
  /////////////////////////////////////////////////////////////////////////////////


  /* imported from Proxy.sol

  enum Actions {
    ChangeExecutive,
    ApprovePolicy,
    TerminatePolicy,
    InstallSystem,
    UpgradeSystem
  }

  struct Instruction {
    Actions action;
    address target;
  }

  */

  uint256 public totalInstructions;
  mapping(uint256 => Instruction[]) public storedInstructions;


  /////////////////////////////////////////////////////////////////////////////////
  //                             Policy Interface                                //
  /////////////////////////////////////////////////////////////////////////////////


  event ProxyLaunched(uint256 timestamp);
  event InstructionsStored(uint256 instructionsId);
  event InstructionsExecuted(uint256 instructionsId);


  function launchProxy() external onlyPolicy {
    _proxy.launch();

    emit ProxyLaunched(block.timestamp);
  }


  function storeInstructions(Instruction[] calldata instructions_) external onlyPolicy returns(uint256) {
    uint256 instructionsId = totalInstructions + 1;
    Instruction[] storage instructions = storedInstructions[instructionsId];

    require(instructions_.length > 0, "cannot storeInstructions(): instructions cannot be empty");

    // @TODO use u256
    for(uint i=0; i<instructions_.length; i++) { 
      _ensureContract(instructions_[i].target);
      if (instructions_[i].action == Actions.InstallSystem || instructions_[i].action == Actions.UpgradeSystem) {
        bytes3 keycode = System(instructions_[i].target).KEYCODE();
        _ensureValidKeycode(keycode);
        if (keycode == "EXC") {
          require(instructions_[instructions_.length-1].action == Actions.ChangeExecutive, 
                  "cannot storeInstructions(): changes to the Executive system (EXC) requires changing the Proxy executive as the last step of the proposal");
          require(instructions_[instructions_.length-1].target == instructions_[i].target,
                  "cannot storeInstructions(): changeExecutive target address does not match the upgraded Executive system address");
        }
      }
      instructions.push(instructions_[i]);
    }
    totalInstructions++;

    emit InstructionsStored(instructionsId);

    return instructionsId;
  }

  function executeInstructions(uint256 instructionsId_) external onlyPolicy {
    Instruction[] storage proposal = storedInstructions[instructionsId_];

    require(proposal.length > 0, "cannot executeInstructions(): proposal does not exist");

    for(uint step=0; step<proposal.length; step++) {
      _proxy.executeAction(proposal[step].action, proposal[step].target);
    }

    emit InstructionsExecuted(instructionsId_);
  }
  

  /////////////////////////////// INTERNAL FUNCTIONS ////////////////////////////////


  function _ensureContract(address target_) internal view {
    uint256 size;
    assembly { size := extcodesize(target_) }
    require(size > 0, "cannot storeInstructions(): target address is not a contract");
  }


  function _ensureValidKeycode(bytes3 keycode) internal pure {
    for (uint256 i = 0; i < 3; i++) {
        bytes1 char = keycode[i];
        require(char >= 0x41 && char <= 0x5A, " cannot storeInstructions(): invalid keycode"); // A-Z only"
    }
  }
}