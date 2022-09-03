//SPDX-License-Identifier: APACHE
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Voting  {
    
    uint256 counter = 0;
    address public token;
    uint public minimumAmount;
    uint public airdropAmount;
    uint256 public startTime;
    uint256 public endTime;
    address owner;
    struct Project {
        uint256 id;
        string name;
        string category;
        string uri;
        string description;
        uint accumulatedTokenBalance;
        uint256 totalVotes;
        address[] alreadyVotedAddress;
    }
 modifier onlyOwner{
        require(msg.sender==owner,"only owner can do this ");
        _;
    }
    mapping(uint256 => Project) public projects;
    
    Project[] private projectCollect;
    constructor(uint _airdropAmount,address _token,uint _minimumAmount,uint _startTime){
        require(block.timestamp <= _startTime, "start time should not be greater then endtime");
        airdropAmount=_airdropAmount;
        token = _token;
        minimumAmount=_minimumAmount;
        startTime=_startTime;
        endTime=startTime + 30 days;
        owner = msg.sender;
    }
    
    function getVotedAddress(uint _projectId)public view returns (address[] memory){
        return projects[_projectId].alreadyVotedAddress;
    }

    function addCandidate(string memory _name,string memory _category,string memory _uri,string memory _description) public onlyOwner {
        require(projectCollect.length < 3, "Max 3 Candidates can be there in the election");
        
        counter = counter + 1;
        uint256 _uniqueId = counter;
        projects[_uniqueId].id = _uniqueId;
        projects[_uniqueId].name = _name;
        projects[_uniqueId].category=_category;
        projects[_uniqueId].uri=_uri;
        projects[_uniqueId].description=_description;
        projectCollect.push(projects[_uniqueId]);
    }

    function candidateList() public view returns(uint){
        return projectCollect.length;
    }

    function vote(uint256 _projectId) public {
        // Check if voting is happening within 30 days or after 30 days.
        require(IERC20(token).balanceOf(msg.sender)>=minimumAmount,"your token balance is lesser then minimum amount required to participate");
        require(block.timestamp < endTime, "Voting Time expired. Voting was only for 30 days.");
        require(projects[_projectId].id != 0, "No candidate present with this id");
        
        bool _isAlreadyVoted = false;
        Project memory _project = projects[_projectId];
        for(uint i = 0; i < _project.alreadyVotedAddress.length; i++) {
            if(_project.alreadyVotedAddress[i] == msg.sender) {
                _isAlreadyVoted = true;
            }
        }

        require((_isAlreadyVoted == false && _project.alreadyVotedAddress.length <= 10), "Max 10 voters can vote to this candidate and same voter can't vote more than once."); 
        
        projects[_projectId].totalVotes += 1;
        projects[_projectId].alreadyVotedAddress.push(msg.sender);
        projects[_projectId].accumulatedTokenBalance += IERC20(token).balanceOf(msg.sender);

        for(uint8 i = 0; i < projectCollect.length; i++) {
            if(projectCollect[i].id == _projectId) {
                projectCollect[i] = projects[_projectId];
            }
        }
    }
    
    function getCandidateInfo(uint _id) public view returns(string memory,string memory,string memory, string memory){
        return(projects[_id].name,projects[_id].category,projects[_id].uri,projects[_id].description);
    }

    function getCandidateVotes(uint _candidateId) public view returns(uint){
        require(block.timestamp < endTime, "you can not get Cap  before ending of poll");
        return projects[_candidateId].totalVotes;
    }

    function totalElectionCap(uint _winnerId)public view returns(uint){
        require(block.timestamp > endTime, "you can not get Cap  before ending of poll");
        return projects[_winnerId].accumulatedTokenBalance;
    }

    function getResult() public view returns(uint256) {
        // Check if result is declaring after 10 minutes or not.
        require(block.timestamp > endTime, "Result will be declared after 10 minutes of Voting.");
        
        uint256 _maxVotes = 0;
        uint256 _winnerId = 0;
        for(uint i = 0; i < projectCollect.length; i++) {
            _winnerId = (projects[i].totalVotes > _maxVotes) ? projectCollect[i].id : _winnerId;
            _maxVotes = (projectCollect[i].totalVotes > _maxVotes) ? projectCollect[i].totalVotes : _maxVotes;
        }
        
        return _winnerId + 1;
    }
}

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