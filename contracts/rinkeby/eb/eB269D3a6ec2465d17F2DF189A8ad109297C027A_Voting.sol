//SPDX-License-Identifier: APACHE

pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
contract Voting  {
    
    uint256 counter = 0;
    string public token;
    uint256 public startTime;
    uint256 public endTime;
    
    struct Candidate {
        uint256 id;
        string name;
        string category;
        string uri;
        string description;


        uint256 totalVotes;
        address[] alreadyVotedAddress;
    }
    
    mapping(uint256 => Candidate) public candidates;
    
    Candidate[] public candidateCollec;
    
    function startVoting(uint _time) public {
        startTime = block.timestamp;
        endTime = startTime + (_time * 1 minutes);
    }
    
    function addCandidate(string memory _name,string memory _category,string memory _uri,string memory _description) public {
        require(candidateCollec.length < 3, "Max 3 Candidates can be there in the election");
        
        counter = counter + 1;
        uint256 _uniqueId = counter;
        candidates[_uniqueId].id = _uniqueId;
        candidates[_uniqueId].name = _name;
        candidates[_uniqueId].category=_category;
        candidates[_uniqueId].uri=_uri;
        candidates[_uniqueId].description=_description;
        candidateCollec.push(candidates[_uniqueId]);
    }
    
    function vote(uint256 _candidateId) public {
        // Check if voting is happening within 10 minutes or after 10 minutes.
        require(block.timestamp <= endTime, "Voting Time expired. Voting was only for 10 minutes.");
        
        require(candidates[_candidateId].id != 0, "No candidate present with this id");
        
        bool _isAlreadyVoted = false;
        Candidate memory _candidate = candidates[_candidateId];
        for(uint i = 0; i < _candidate.alreadyVotedAddress.length; i++) {
            if(_candidate.alreadyVotedAddress[i] == msg.sender) {
                _isAlreadyVoted = true;
            }
        }
        require((_isAlreadyVoted == false && _candidate.alreadyVotedAddress.length <= 10), "Max 10 voters can vote to this candidate and same voter can't vote more than once."); 
        candidates[_candidateId].totalVotes += 1;
        candidates[_candidateId].alreadyVotedAddress.push(msg.sender);
    }
    
    function getResult() public view returns(uint256) {
        // Check if result is declaring after 10 minutes or not.
        require(block.timestamp > endTime, "Result will be declared after 10 minutes of Voting.");
        
        uint256 _maxVotes = 0;
        uint256 _winnerId = 0;
        for(uint i = 0; i < candidateCollec.length; i++) {
            _winnerId = (candidateCollec[i].totalVotes > _maxVotes) ? candidateCollec[i].id : _winnerId;
            _maxVotes = (candidateCollec[i].totalVotes > _maxVotes) ? candidateCollec[i].totalVotes : _maxVotes;
        }
        
        return _winnerId;
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