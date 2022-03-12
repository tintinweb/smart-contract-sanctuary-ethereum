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