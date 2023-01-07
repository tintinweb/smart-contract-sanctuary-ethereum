// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
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

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Voting is Ownable {

    struct Candidate {
        uint candidateId;
        bytes32 candidate;
        uint votes;
    }

    struct Detail {
        bytes32 title;
        uint duration;
        Candidate[] candidates;
        uint startTime;
        uint roomId;
        address proposer;
    }

    struct History {
        address voter;
        uint candidateId;
        uint timeStamp;
    }

    struct voterHistory {
        uint roomId;
        uint candidateId;
        uint timeStamp;
    }


    uint public votingCount = 1;
    mapping(uint => uint) public indexToRoomId;
    mapping(uint => Detail) public votingDetails;
    mapping(uint => History[]) public votingHistory;
    mapping(uint => address[]) public voterVerified;
    mapping(address => voterHistory[]) public voterToHistory;


    function createVoting(bytes32 _title, uint _duration, uint _startTime, uint _roomId, bytes32[] calldata _candidates) external onlyOwner {
        Detail storage details = votingDetails[votingCount];
        details.title = _title;
        details.duration = _duration;
        uint length = _candidates.length;
        for(uint i; i < length; ++i) {
            bytes32 candidate = _candidates[i];
            details.candidates.push(Candidate(i + 1, candidate, 0));
        }
        details.startTime = (_startTime * 1 hours) + block.timestamp;
        details.roomId = _roomId;
        details.proposer = msg.sender;
        indexToRoomId[votingCount] = _roomId; 
        votingCount ++;
    }

    function vote(uint _votingId, address _voter, uint _candidate) external {
        Detail memory details = votingDetails[_votingId];
        bool verified = checkVerifiedVoter(_votingId, _voter);
        bool voted = checkVoterVote(_votingId, _voter);
        uint startTime = details.startTime;
        uint duration = details.duration;
        uint totalDuration = startTime + (duration * 1 hours);

        require(verified == true, "You are not verified");
        require(voted == false, "You already voted to one of the candidates");
        require(startTime < block.timestamp, "Voting session has not started");
        require(totalDuration > block.timestamp, "Duration of the voting session is over");
        uint index = getCandidateIndex(_votingId, _candidate);
       
        Candidate[] storage  candidates= votingDetails[_votingId].candidates;
        candidates[index].votes = candidates[index].votes + 1;
        votingHistory[_votingId].push(History(_voter, _candidate, block.timestamp*1000));
        uint _roomId = indexToRoomId[_votingId]; 
        voterToHistory[_voter].push(voterHistory(_roomId , _candidate, block.timestamp*1000));

    }


    function getCandidateIndex(uint _votingId, uint _candidate) internal view returns(uint index) {
        Candidate[] memory  candidates= votingDetails[_votingId].candidates;
        uint length = candidates.length;
        for(uint i; i < length; ++i) {
            uint candidate = candidates[i].candidateId;
            if(candidate == _candidate) {
                index = i;
            }
        }  
    }

    function getCandidates(uint _votingId) external view returns(Candidate[] memory candidates) {
        candidates = votingDetails[_votingId].candidates;
    }

    function getHistory(uint _votingId) external view returns(History[] memory history) {
        history = votingHistory[_votingId];
    }

    function getVoterHistory(address _voter) external view returns( voterHistory[] memory) {
         voterHistory[] memory addressToHistory = voterToHistory[_voter];
         return addressToHistory; 
    }

    function checkVerifiedVoter(uint _votingId, address _voter) internal view returns(bool result) {
        address[] memory verified = voterVerified[_votingId];
        uint length = verified.length;
        for(uint i; i < length; ++i) {
            address _verified = verified[i];
            if(_verified ==_voter) {
                result = true;
            } else {
                result = false;
            }
        }
    }
    
    function checkVoterVote(uint _votingId, address _voter) internal view returns(bool result) {
        History[] memory votes = votingHistory[_votingId];
        uint length = votes.length;
        for(uint i; i < length; i++){
            address voter = votes[i].voter;
            if(voter == _voter){
                result = true;
            } else {
                result = false;
            }
        }
    }

    function verifyVoter(uint _votingId, bool _isVerified) external{
        bool verified = checkVerifiedVoter(_votingId, msg.sender);
        require(_isVerified, "You are not a verified voter");
        require(!verified, "You are already verified");
        voterVerified[_votingId].push(msg.sender);
    }

}