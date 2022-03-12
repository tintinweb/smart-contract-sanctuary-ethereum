// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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

pragma solidity ^0.8.10;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '../Proxy.sol';

contract Token is System, IERC20 {
  
  //////////////////////////////////////////////////////////////////////////////
  //                              SYSTEM CONFIG                               //
  //////////////////////////////////////////////////////////////////////////////

  // @NOTE consider making these constant, reduce read cost
  string public name = "PROXY Token";
  string public symbol = "PROX";
  uint8 public decimals = 3;

  uint256 public totalSupply = 0;
  // slot = sha3(1, address) -> balance
  mapping(address => uint256) public balanceOf;
  // slot 2 - length of thisArr
  // sha3(2) -> elements of thisArr
  bytes32[] public thisArr;
  uint public thisNum;

  constructor(Proxy proxy_) System(proxy_) {
  }

  function KEYCODE() external pure override returns (bytes3) { 
    return "TKN"; 
  }


  // brick the allowance features for the token (because transfers and transferFrom are restricted to a governance mechanism=)
  function allowance(address, address) external pure override returns (uint256) {
    return type(uint256).max;
  }

  function approve(address, uint256) external pure override returns (bool) {
    return true;
  }



  ////////////////////////////////////////////////////////////////////////////
  //                           POLICY INTERFACE                             //
  ////////////////////////////////////////////////////////////////////////////

  
  // event Transfer(address from, address to, uint256 amount); => already declared in the imported IERC20.sol


  // mint tokensToMint_, but only if the msg.sender has enough reserve tokens to exchange
  function mint(address to_, uint256 amount_) external onlyPolicy returns (bool) {

    totalSupply += amount_;

    // Cannot overflow because the sum of all user
    // balances can't exceed the max uint256 value.
    unchecked {
        balanceOf[to_] += amount_;
    }

    emit Transfer(address(0), to_, amount_);

    return true;
  }

  function burn(address from_, uint256 amount_) external onlyPolicy returns (bool) {
    
    balanceOf[from_] -= amount_;

    // Cannot underflow because a user's balance
    // will never be larger than the total supply.
    unchecked {
        totalSupply -= amount_;
    }

    emit Transfer(from_, address(0), amount_);

    return true;
  }


  // restrict 3rd party interactions with the token to approved policies.
  function transferFrom(address from_, address to_, uint256 amount_) public override onlyPolicy returns (bool) {
    balanceOf[from_] -= amount_;

    // Cannot overflow because the sum of all user
    // balances can't exceed the max uint256 value.
    unchecked {
        balanceOf[to_] += amount_;
    }

    emit Transfer(from_, to_, amount_);

    return true;
  }


  // restrict EOA transfers to approved policies.
  function transfer(address to_, uint256 amount_) public override onlyPolicy returns (bool) {
    balanceOf[msg.sender] -= amount_;

    // Cannot overflow because the sum of all user
    // balances can't exceed the max uint256 value.
    unchecked {
        balanceOf[to_] += amount_;
    }

    emit Transfer(msg.sender, to_, amount_);

    return true;
  }


}