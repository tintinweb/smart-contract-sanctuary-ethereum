// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/access/Ownable.sol";

pragma solidity ^0.8.11;

contract AucEngine is Ownable {

    //address public owner;
    uint256 public constant REQUIRED_SUM = 10000000 gwei;
    uint256 public constant DURATIONTIME = 3 days;
    uint256 public constant FEE = 10;
    
    event VotingCreated(string title);

    //структура голосования
    struct Voting {
      address winner;
      string title;
      uint256 maximumVotes;
      uint256 endsAt;
      uint256 totalAmount;
      bool started;
      bool ended;
      address[] allCandidates;
      address[] allParticipants;
      mapping(address => uint ) candidates;  
      mapping(address => address) participants; 
    }  
    
    Voting[] public votings;

    // constructor(){
    //     owner = msg.sender;
    // }

    // modifier onlyOwner {
    //     require(msg.sender == owner, "it isn't owner")
    // }

    function candidates(uint index) external view returns(address[] memory, uint[] memory) {
        Voting storage cVoting = votings[index];
        uint count = cVoting.allCandidates.length;
        uint[] memory votes = new uint[](count);
        address[] memory candidatesList = new address[](count);
        for(uint i = 0; i < count; i++) {
            candidatesList[i] = cVoting.allCandidates[i];
            votes[i] = cVoting.candidates[candidatesList[i]];
        }
        return (candidatesList, votes);
    }

    function addVoting(string memory _title) external onlyOwner {
        Voting storage newVoting = votings.push();
        newVoting.title = _title;

        emit VotingCreated(_title);
    }

    function addCandidate(uint index) external {
        Voting storage cVoting = votings[index];
        require(!cVoting.started, "start");
        cVoting.allCandidates.push(msg.sender);
    }

    function startVoting(uint index) external onlyOwner {
        Voting storage cVoting = votings[index];
        require(!cVoting.started, "started");
        cVoting.started = true;
        cVoting.endsAt = block.timestamp + DURATIONTIME;
    }

    function addrExists(address _addr, address[] memory _addresses) private pure returns(bool) {
        for(uint i = 0; i < _addresses.length; i++) {
            if (_addresses[i] == _addr) {
                return true;
            }
        }

        return false;
    }
      
    function vote(uint index, address _for) external payable {
        require(msg.value == REQUIRED_SUM, "sum don't equal price");
        Voting storage cVoting = votings[index];
        require(cVoting.started, "not started!");
        require(
            !cVoting.ended || block.timestamp < cVoting.endsAt,
            "has ended"
        );
        require(
            !addrExists(msg.sender, cVoting.allParticipants),
            "already vote"
        );
        cVoting.totalAmount += msg.value;
        cVoting.candidates[_for]++;
        cVoting.allParticipants.push(msg.sender);
        cVoting.participants[msg.sender] = _for;
        if(cVoting.candidates[_for] >= cVoting.maximumVotes){
            cVoting.winner = _for;
            cVoting.maximumVotes = cVoting.candidates[_for];
        }
    }

    function stopVoting(uint index) external {
        Voting storage cVoting = votings[index];
        require(cVoting.started, "don't started");
        require(!cVoting.ended, "don't ended");
        require(
            block.timestamp >= cVoting.endsAt,
            "can't stop"
        );
        cVoting.ended = true;
        address payable _to = payable(cVoting.winner);
        _to.transfer(
            cVoting.totalAmount - ((cVoting.totalAmount * FEE) / 100)
        );
    }


    function withdrawWin(address win, uint256 balance) private {

        address payable receiver = payable(win);

        uint256 balanceWin = balance - (balance * 10 / 100);
        
        receiver.transfer(balanceWin);
    }

    

 


}

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