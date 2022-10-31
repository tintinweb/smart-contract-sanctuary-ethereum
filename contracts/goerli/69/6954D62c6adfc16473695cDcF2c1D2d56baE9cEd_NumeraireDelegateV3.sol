/**
 *Submitted for verification at Etherscan.io on 2022-10-31
*/

/**
 *Submitted for verification at Etherscan.io on 2019-06-27
*/

pragma solidity >=0.4.25 <0.5.0;

/**
 * @title NMRSafeMath
 * @dev Unsigned math operations with safety checks that revert on error.
 */
library NMRSafeMath {
    /**
     * @dev Multiplies two unsigned integers, reverts on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
     * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Adds two unsigned integers, reverts on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
     * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
     * reverts when dividing by zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}


 /* WARNING: This implementation is outdated and insecure */
 /// @title Shareable
 /// @notice Multisig contract to manage access control
contract Shareable {
  // TYPES

  // struct for the status of a pending operation.
  struct PendingState {
    uint yetNeeded;
    uint ownersDone;
    uint index;
  }


  // FIELDS

  // the number of owners that must confirm the same operation before it is run.
  uint public required;

  // list of owners
  address[256] owners;
  uint constant c_maxOwners = 250;
  // index on the list of owners to allow reverse lookup
  mapping(address => uint) ownerIndex;
  // the ongoing operations.
  mapping(bytes32 => PendingState) pendings;
  bytes32[] pendingsIndex;


  // EVENTS

  // this contract only has six types of events: it can accept a confirmation, in which case
  // we record owner and operation (hash) alongside it.
  event Confirmation(address owner, bytes32 operation);
  event Revoke(address owner, bytes32 operation);


  // MODIFIERS

  address thisContract = this;

  // simple single-sig function modifier.
  modifier onlyOwner {
    if (isOwner(msg.sender))
      _;
  }

  // multi-sig function modifier: the operation must have an intrinsic hash in order
  // that later attempts can be realised as the same underlying operation and
  // thus count as confirmations.
  modifier onlyManyOwners(bytes32 _operation) {
    if (confirmAndCheck(_operation))
      _;
  }


  // CONSTRUCTOR

  // constructor is given number of sigs required to do protected "onlymanyowners" transactions
  // as well as the selection of addresses capable of confirming them.
  function Shareable(address[] _owners, uint _required) {
    owners[1] = msg.sender;
    ownerIndex[msg.sender] = 1;
    for (uint i = 0; i < _owners.length; ++i) {
      owners[2 + i] = _owners[i];
      ownerIndex[_owners[i]] = 2 + i;
    }
    if (required > owners.length) throw;
    required = _required;
  }


  // new multisig is given number of sigs required to do protected "onlymanyowners" transactions
  // as well as the selection of addresses capable of confirming them.
  // take all new owners as an array
  /*
  
   WARNING: This function contains a security vulnerability. 
   
   This method does not clear the `owners` array and the `ownerIndex` mapping before updating the owner addresses.
   If the new array of owner addresses is shorter than the existing array of owner addresses, some of the existing owners will retain ownership.
   
   The fix implemented in NumeraireDelegateV2 successfully mitigates this bug by allowing new owners to remove the old owners from the `ownerIndex` mapping using a special transaction.
   Note that the old owners are not be removed from the `owners` array and that if the special transaction is incorectly crafted, it may result in fatal error to the multisig functionality.
   
   */
  function changeShareable(address[] _owners, uint _required) onlyManyOwners(sha3(msg.data)) {
    for (uint i = 0; i < _owners.length; ++i) {
      owners[1 + i] = _owners[i];
      ownerIndex[_owners[i]] = 1 + i;
    }
    if (required > owners.length) throw;
    required = _required;
  }

  // METHODS

  // Revokes a prior confirmation of the given operation
  function revoke(bytes32 _operation) external {
    uint index = ownerIndex[msg.sender];
    // make sure they're an owner
    if (index == 0) return;
    uint ownerIndexBit = 2**index;
    var pending = pendings[_operation];
    if (pending.ownersDone & ownerIndexBit > 0) {
      pending.yetNeeded++;
      pending.ownersDone -= ownerIndexBit;
      Revoke(msg.sender, _operation);
    }
  }

  // Gets an owner by 0-indexed position (using numOwners as the count)
  function getOwner(uint ownerIndex) external constant returns (address) {
    return address(owners[ownerIndex + 1]);
  }

  function isOwner(address _addr) constant returns (bool) {
    return ownerIndex[_addr] > 0;
  }

  function hasConfirmed(bytes32 _operation, address _owner) constant returns (bool) {
    var pending = pendings[_operation];
    uint index = ownerIndex[_owner];

    // make sure they're an owner
    if (index == 0) return false;

    // determine the bit to set for this owner.
    uint ownerIndexBit = 2**index;
    return !(pending.ownersDone & ownerIndexBit == 0);
  }

  // INTERNAL METHODS

  function confirmAndCheck(bytes32 _operation) internal returns (bool) {
    // determine what index the present sender is:
    uint index = ownerIndex[msg.sender];
    // make sure they're an owner
    if (index == 0) return;

    var pending = pendings[_operation];
    // if we're not yet working on this operation, switch over and reset the confirmation status.
    if (pending.yetNeeded == 0) {
      // reset count of confirmations needed.
      pending.yetNeeded = required;
      // reset which owners have confirmed (none) - set our bitmap to 0.
      pending.ownersDone = 0;
      pending.index = pendingsIndex.length++;
      pendingsIndex[pending.index] = _operation;
    }
    // determine the bit to set for this owner.
    uint ownerIndexBit = 2**index;
    // make sure we (the message sender) haven't confirmed this operation previously.
    if (pending.ownersDone & ownerIndexBit == 0) {
      Confirmation(msg.sender, _operation);
      // ok - check if count is enough to go ahead.
      if (pending.yetNeeded <= 1) {
        // enough confirmations: reset and run interior.
        delete pendingsIndex[pendings[_operation].index];
        delete pendings[_operation];
        return true;
      }
      else
        {
          // not enough: record that this owner in particular confirmed.
          pending.yetNeeded--;
          pending.ownersDone |= ownerIndexBit;
        }
    }
  }

  function clearPending() internal {
    uint length = pendingsIndex.length;
    for (uint i = 0; i < length; ++i)
    if (pendingsIndex[i] != 0)
      delete pendings[pendingsIndex[i]];
    delete pendingsIndex;
  }
}



/// @title Safe
/// @notice Utility functions for safe data manipulations
contract Safe {

    /// @dev Add two numbers without overflow
    /// @param a Uint number
    /// @param b Uint number
    /// @return result
    function safeAdd(uint a, uint b) internal returns (uint) {
        uint c = a + b;
        assert(c >= a && c >= b);
        return c;
    }

    /// @dev Substract two numbers without underflow
    /// @param a Uint number
    /// @param b Uint number
    /// @return result
    function safeSubtract(uint a, uint b) internal returns (uint) {
        uint c = a - b;
        assert(b <= a && c <= a);
        return c;
    }

    /// @dev Multiply two numbers without overflow
    /// @param a Uint number
    /// @param b Uint number
    /// @return result
    function safeMultiply(uint a, uint b) internal returns (uint) {
        uint c = a * b;
        assert(a == 0 || (c / a) == b);
        return c;
    }

    /// @dev Convert uint256 to uint128 without concatenating
    /// @param a Uint number
    /// @return result
    function shrink128(uint a) internal returns (uint128) {
        assert(a < 0x100000000000000000000000000000000);
        return uint128(a);
    }

    /// @dev Prevent short address attack
    /// @param numWords Uint length of calldata in bytes32 words
    modifier onlyPayloadSize(uint numWords) {
        assert(msg.data.length == numWords * 32 + 4);
        _;
    }

    /// @dev Fallback function to allow ETH to be received
    function () payable { }
}



/// @title StoppableShareable
/// @notice Extend the Shareable multisig with ability to pause desired functions
contract StoppableShareable is Shareable {
  bool public stopped;
  bool public stoppable = true;

  modifier stopInEmergency { if (!stopped) _; }
  modifier onlyInEmergency { if (stopped) _; }

  function StoppableShareable(address[] _owners, uint _required) Shareable(_owners, _required) {
  }

  /// @notice Trigger paused state
  /// @dev Can only be called by an owner
  function emergencyStop() external onlyOwner {
    assert(stoppable);
    stopped = true;
  }

  /// @notice Return to unpaused state
  /// @dev Can only be called by the multisig
  function release() external onlyManyOwners(sha3(msg.data)) {
    assert(stoppable);
    stopped = false;
  }

  /// @notice Disable ability to pause the contract
  /// @dev Can only be called by the multisig
  function disableStopping() external onlyManyOwners(sha3(msg.data)) {
    stoppable = false;
  }
}



/// @title NumeraireShared
/// @notice Token and tournament storage layout
contract NumeraireShared is Safe {

    address public numerai = this;

    // Cap the total supply and the weekly supply
    uint256 public supply_cap = 21000000e18; // 21 million
    uint256 public weekly_disbursement = 96153846153846153846153;

    uint256 public initial_disbursement;
    uint256 public deploy_time;

    uint256 public total_minted;

    // ERC20 requires totalSupply, balanceOf, and allowance
    uint256 public totalSupply;
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    mapping (uint => Tournament) public tournaments;  // tournamentID

    struct Tournament {
        uint256 creationTime;
        uint256[] roundIDs;
        mapping (uint256 => Round) rounds;  // roundID
    } 

    struct Round {
        uint256 creationTime;
        uint256 endTime;
        uint256 resolutionTime;
        mapping (address => mapping (bytes32 => Stake)) stakes;  // address of staker
    }

    // The order is important here because of its packing characteristics.
    // Particularly, `amount` and `confidence` are in the *same* word, so
    // Solidity can update both at the same time (if the optimizer can figure
    // out that you're updating both).  This makes `stake()` cheap.
    struct Stake {
        uint128 amount; // Once the stake is resolved, this becomes 0
        uint128 confidence;
        bool successful;
        bool resolved;
    }

    // Generates a public event on the blockchain to notify clients
    event Mint(uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Staked(address indexed staker, bytes32 tag, uint256 totalAmountStaked, uint256 confidence, uint256 indexed tournamentID, uint256 indexed roundID);
    event RoundCreated(uint256 indexed tournamentID, uint256 indexed roundID, uint256 endTime, uint256 resolutionTime);
    event TournamentCreated(uint256 indexed tournamentID);
    event StakeDestroyed(uint256 indexed tournamentID, uint256 indexed roundID, address indexed stakerAddress, bytes32 tag);
    event StakeReleased(uint256 indexed tournamentID, uint256 indexed roundID, address indexed stakerAddress, bytes32 tag, uint256 etherReward);

    /// @notice Get the amount of NMR which can be minted
    /// @return uint256 Amount of NMR in wei
    function getMintable() constant returns (uint256) {
        return
            safeSubtract(
                safeAdd(initial_disbursement,
                    safeMultiply(weekly_disbursement,
                        safeSubtract(block.timestamp, deploy_time))
                    / 1 weeks),
                total_minted);
    }
}





/// @title NumeraireDelegateV3
/// @notice Delegate contract version 3 with the following functionality:
///   1) Disabled upgradability
///   2) Repurposed burn functions
///   3) User NMR balance management through the relay contract
/// @dev Deployed at address
/// @dev Set in tx
/// @dev Retired in tx
contract NumeraireDelegateV3 is StoppableShareable, NumeraireShared {

    address public delegateContract;
    bool public contractUpgradable;
    address[] public previousDelegates;

    string public standard;

    string public name;
    string public symbol;
    uint256 public decimals;

    // set the address of the relay as a constant (stored in runtime code)
    address private constant _RELAY = address(
        0xB17dF4a656505570aD994D023F632D48De04eDF2
    );

    event DelegateChanged(address oldAddress, address newAddress);

    using NMRSafeMath for uint256;

    /* TODO: Can this contructor be removed completely? */
    /// @dev Constructor called on deployment to initialize the delegate contract multisig
    /// @param _owners Array of owner address to control multisig
    /// @param _num_required Uint number of owners required for multisig transaction
    constructor(address[] _owners, uint256 _num_required) public StoppableShareable(_owners, _num_required) {
    }

    //////////////////////////////
    // Special Access Functions //
    //////////////////////////////

    /// @notice Manage Numerai Tournament user balances
    /// @dev Can only be called by numerai through the relay contract
    /// @param _from User address from which to withdraw NMR
    /// @param _to Address where to deposit NMR
    /// @param _value Uint amount of NMR in wei to transfer
    /// @return ok True if the transfer succeeds
    function withdraw(address _from, address _to, uint256 _value) public returns(bool ok) {
        require(msg.sender == _RELAY);
        require(_to != address(0));

        balanceOf[_from] = balanceOf[_from].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);

        emit Transfer(_from, _to, _value);
        return true;
    }

    /// @notice Repurposed function to allow the relay contract to disable token upgradability.
    /// @dev Can only be called by numerai through the relay contract
    /// @return ok True if the call is successful
    function createRound(uint256, uint256, uint256, uint256) public returns (bool ok) {
        require(msg.sender == _RELAY);
        require(contractUpgradable);
        contractUpgradable = false;

        return true;
    }

    /// @notice Repurposed function to allow the relay contract to upgrade the token.
    /// @dev Can only be called by numerai through the relay contract
    /// @param _newDelegate Address of the new delegate contract
    /// @return ok True if the call is successful
    function createTournament(uint256 _newDelegate) public returns (bool ok) {
        require(msg.sender == _RELAY);
        require(contractUpgradable);

        address newDelegate = address(_newDelegate);

        previousDelegates.push(delegateContract);
        emit DelegateChanged(delegateContract, newDelegate);
        delegateContract = newDelegate;

        return true;
    }

    //////////////////////////
    // Repurposed Functions //
    //////////////////////////

    /// @notice Repurposed function to implement token burn from the calling account
    /// @param _value Uint amount of NMR in wei to burn
    /// @return ok True if the burn succeeds
    function mint(uint256 _value) public returns (bool ok) {
        _burn(msg.sender, _value);
        return true;
    }

    /// @notice Repurposed function to implement token burn on behalf of an approved account
    /// @param _to Address from which to burn tokens
    /// @param _value Uint amount of NMR in wei to burn
    /// @return ok True if the burn succeeds
    function numeraiTransfer(address _to, uint256 _value) public returns (bool ok) {
        _burnFrom(_to, _value);
        return true;
    }

    ////////////////////////
    // Internal Functions //
    ////////////////////////

    /// @dev Internal function that burns an amount of the token of a given account.
    /// @param _account The account whose tokens will be burnt.
    /// @param _value The amount that will be burnt.
    function _burn(address _account, uint256 _value) internal {
        require(_account != address(0));

        totalSupply = totalSupply.sub(_value);
        balanceOf[_account] = balanceOf[_account].sub(_value);
        emit Transfer(_account, address(0), _value);
    }

    /// @dev Internal function that burns an amount of the token of a given
    /// account, deducting from the sender's allowance for said account. Uses the
    /// internal burn function.
    /// Emits an Approval event (reflecting the reduced allowance).
    /// @param _account The account whose tokens will be burnt.
    /// @param _value The amount that will be burnt.
    function _burnFrom(address _account, uint256 _value) internal {
        allowance[_account][msg.sender] = allowance[_account][msg.sender].sub(_value);
        _burn(_account, _value);
        emit Approval(_account, msg.sender, allowance[_account][msg.sender]);
    }

    ///////////////////////
    // Trashed Functions //
    ///////////////////////

    /// @dev Disabled function no longer used
    function releaseStake(address, bytes32, uint256, uint256, uint256, bool) public pure returns (bool) {
        revert();
    }

    /// @dev Disabled function no longer used
    function destroyStake(address, bytes32, uint256, uint256) public pure returns (bool) {
        revert();
    }

    /// @dev Disabled function no longer used
    function stake(uint256, bytes32, uint256, uint256, uint256) public pure returns (bool) {
        revert();
    }

    /// @dev Disabled function no longer used
    function stakeOnBehalf(address, uint256, bytes32, uint256, uint256, uint256) public pure returns (bool) {
        revert();
    }
}