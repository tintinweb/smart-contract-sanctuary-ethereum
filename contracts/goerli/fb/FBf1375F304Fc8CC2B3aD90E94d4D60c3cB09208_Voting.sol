// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AutomationBase {
  error OnlySimulatedBackend();

  /**
   * @notice method that allows it to be simulated via eth_call by checking that
   * the sender is the zero address.
   */
  function preventExecution() internal view {
    if (tx.origin != address(0)) {
      revert OnlySimulatedBackend();
    }
  }

  /**
   * @notice modifier that allows it to be simulated via eth_call by checking
   * that the sender is the zero address.
   */
  modifier cannotExecute() {
    preventExecution();
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AutomationBase.sol";
import "./interfaces/AutomationCompatibleInterface.sol";

abstract contract AutomationCompatible is AutomationBase, AutomationCompatibleInterface {}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AutomationCompatibleInterface {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easily be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/AutomationCompatible.sol";

error Voting__NotAuthorized();
error Voting__AlreadyVoted();
error Voting__AlreadyRegistered();
error Voting__UnknownCandidate();
error Voting__WrongState();
error Voting__UpkeepNotNeeded();

contract Voting is Ownable, AutomationCompatibleInterface {
    enum VotingState {
        REG,
        VOTING,
        CALC
    }

    struct Voter {
        bool authorized;
        bool voted;
    }

    struct Candidate {
        uint256 votes;
    }

    mapping(address => Voter) public voters;
    Candidate[] public candidates;
    VotingState public state;
    uint256 public candidatesCount;
    uint256 private registerTime;
    uint256 private votingTime;
    uint256 private lastTimeStamp;

    event Voted(address indexed voter, uint256 numCandidate);
    event VoterRegistered(address indexed voter);

    constructor(
        uint256 _candidatesCount,
        uint256 _registerTime,
        uint256 _votingTime
    ) {
        candidatesCount = _candidatesCount;
        registerTime = _registerTime;
        votingTime = _votingTime;

        for (uint256 i = 0; i < candidatesCount; i++) {
            candidates.push(Candidate(0));
        }

        state = VotingState.REG;
        lastTimeStamp = block.timestamp;
    }

    // modifier onlyRegistered{
    //     if (!(voters[msg.sender].authorized)){
    //         revert Voting__NotAuthorized();
    //     }
    //     _;
    // }

    modifier onlyState(VotingState _state) {
        if (state != _state) {
            revert Voting__WrongState();
        }
        _;
    }

    function checkUpkeep(
        bytes memory /* checkData */
    )
        public
        view
        override
        returns (bool upkeepNeeded, bytes memory /* performData */)
    {
        upkeepNeeded =
            (block.timestamp - lastTimeStamp) > registerTime ||
            (block.timestamp - lastTimeStamp) > votingTime;
        //upkeepNeeded = (block.timestamp - lastTimeStamp) > interval;
        // We don't use the checkData in this example. The checkData is defined when the Upkeep was registered.
    }

    function performUpkeep(bytes calldata /* performData */) public override {
        (bool upkeepNeeded, ) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert Voting__UpkeepNotNeeded();
        }

        if (state == VotingState.REG) {
            state = VotingState.VOTING;
        } else if (state == VotingState.VOTING) {
            state = VotingState.CALC;
        }

        //We highly recommend revalidating the upkeep in the performUpkeep function
        // if ((block.timestamp - lastTimeStamp) > interval) {
        //     lastTimeStamp = block.timestamp;
        //     counter = counter + 1;
        // }
        // We don't use the performData in this example. The performData is generated by the Automation Node's call to your checkUpkeep function
    }

    function vote(uint256 _numCandidate) public onlyState(VotingState.VOTING) {
        if (voters[msg.sender].authorized == false) {
            revert Voting__NotAuthorized();
        }
        if (voters[msg.sender].voted) {
            revert Voting__AlreadyVoted();
        }
        if (_numCandidate - 1 > candidatesCount) {
            revert Voting__UnknownCandidate();
        }

        //if ((lastTimeStamp + 30 seconds) < block.timestamp) {
        candidates[_numCandidate].votes++; //увеличиваем кол-во голосов за этого кандидата
        voters[msg.sender].voted = true; //отмечаем, что текущий пользователь уже проголосовал
        emit Voted(msg.sender, _numCandidate);
        // } else {
        //     state = VotingState.CALC;
        //     lastTimeStamp = block.timestamp;
        // }
    }

    function register(
        address _voter
    ) public onlyOwner onlyState(VotingState.REG) {
        if (voters[_voter].authorized) {
            revert Voting__AlreadyRegistered();
        }

        // if ((lastTimeStamp + 30 seconds) > block.timestamp) {
        //     state = VotingState.VOTING;
        //     lastTimeStamp = block.timestamp;
        // } else {
        voters[_voter].authorized = true; //регистрируем пользователя
        voters[_voter].voted = false;
        emit VoterRegistered(_voter);
        //}
    }

    function getWinner()
        public
        view
        onlyState(VotingState.CALC)
        returns (uint256)
    {
        uint256 maxVotes = 0;
        uint256 numCandidate = 0;
        for (uint256 i = 0; i < candidatesCount; i++) {
            if (candidates[i].votes > maxVotes) {
                maxVotes = candidates[i].votes;
                numCandidate = i;
            }
        }
        return numCandidate;
    }
}