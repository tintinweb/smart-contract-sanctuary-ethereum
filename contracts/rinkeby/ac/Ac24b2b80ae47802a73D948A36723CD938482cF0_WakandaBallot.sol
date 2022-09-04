// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IWKND.sol";

contract WakandaBallot is Ownable{

    struct Candidate{
        string name;
        string cult;
        uint age;
        bytes32 hash;
        uint256 count;
    }

    struct Voter {
        address voterAddress;
        uint256 voteCount;
        bytes32 candidate;
    }

    enum VotingState {NOT_STARTED, STARTED, FINISHED}

    mapping(bytes32 => bool) registeredCandidates;

    mapping(address => bool) public voted;

    Candidate[] public candidates;

    Candidate[] public winners;

    Voter[] public voters;

    uint256 public startTime;

    uint256 public endTime;

    uint256 totalVotes;

    IWKND public wknd;

    event NewChallenger(string indexed name, string indexed cult, uint age);

    event Voted(address indexed voter, uint256 voteCount, string name, string cult);

    constructor (uint256 _startTime, uint256 _endTime, address _wknd) {
        require(_startTime > block.timestamp, 'Start time can not be in the past');
        require(_endTime > _startTime, 'End time must come after start time');
        require(_wknd != address(0), 'WKND token address cant be zero');

        startTime =  _startTime;
        endTime = _endTime;

        wknd = IWKND(_wknd);
    }

    modifier inState(VotingState state){
        require(getElectionState() == state, 'Voting is not in correct state');
        _;
    }

    function addCandidate(string memory name, string memory cult, uint age) public onlyOwner inState(VotingState.NOT_STARTED){
        bytes32 _hash = keccak256(abi.encodePacked(name, cult, age));
        require(!registeredCandidates[_hash],'Candidate already added');
        candidates.push(Candidate(name, cult, age, _hash, uint(0)));
        registeredCandidates[_hash] = true;
    }

    function vote(bytes32 _candidate, address voter, uint256 _voteNumber) public onlyOwner inState(VotingState.STARTED) {
        require(voter != address(0), "0 address can't vote");
        require(!voted[voter], 'Already voted');
        require(registeredCandidates[_candidate],'Not a registered candidate');
        require(_voteNumber > uint256(0),'Wrong vote count number');
        require(wknd.balanceOfAt(voter, wknd.getCurrentSnapshotId()) >= _voteNumber, 'Vote number is bigger then ammount of WKND tokens owned for given address');

        voted[voter] = true;
        uint256 _index = findCandidate(_candidate);

        candidates[_index].count += _voteNumber;
        voters.push(Voter(voter, _voteNumber, _candidate));
        totalVotes += _voteNumber;

        _setUpWinner(candidates[_index]);

        emit Voted(voter,_voteNumber, candidates[_index].name, candidates[_index].cult);
    }

    function winningCandidates () public view returns (Candidate[] memory _winners) {
        _winners = winners;
    }

    function getCandidates () public view returns (Candidate[] memory _candidates) {
        _candidates = candidates;
    }

    function _setUpWinner(Candidate storage winn) private {
        if(_containsWinner(winn)) {
            winners[findCandidate(winn.hash)] = winn;
           _sortWinners();
            emit NewChallenger(winn.name, winn.cult, winn.age); 
            return;
        }

        if(winners.length < 3){
            winners.push(winn);
            _sortWinners();
            emit NewChallenger(winn.name, winn.cult, winn.age);
            return;
        }

        if(_shouldInsert(winn.count)){
            winners.push(winn);
            _sortWinners();
            winners.pop();
            emit NewChallenger(winn.name, winn.cult, winn.age);
        }
    }

    function _containsWinner(Candidate storage winn) private view returns (bool){
        for(uint index = 0; index < winners.length; index++) 
            if(winners[index].hash == winn.hash) return true;
        
        return false;
    }

    function _sortWinners() private{
        Candidate memory _candidate;
        for(uint i = 0; i < winners.length; i ++)
            for(uint j = 0; j < winners.length -1; j ++)
                if(winners[j].count < winners[j+1].count){
                    _candidate = winners[j];
                    winners[j] = winners[j+1];
                    winners[j+1] = _candidate;
                }
    }

    function _shouldInsert(uint256 count) private view returns (bool insertFlag){
        for(uint i =0; i< winners.length; i++)
            if(winners[i].count < count)
                insertFlag = true;
    }

    function getElectionState() public view returns (VotingState state) { 
        if(block.timestamp < startTime) 
            state = VotingState.NOT_STARTED;

        else if (block.timestamp >= startTime && block.timestamp <= endTime)
            state = VotingState.STARTED;

        else
            state = VotingState.FINISHED;
    }

    function findCandidate(bytes32 candidateHash) private view returns (uint256 index){
        for(uint256 i =0; i< candidates.length; i++){
            if(candidates[i].hash == candidateHash)
                index = i;
        }
    }
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
pragma solidity ^0.8.9;

interface IWKND {
    function getCurrentSnapshotId() external view returns (uint256);

    function balanceOfAt(address account, uint256 snapshotId) external view returns (uint256);
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