/**
 *Submitted for verification at Etherscan.io on 2022-11-13
*/

// SPDX-License-Identifier: GPL-3.0
//
//  __  __      _     __      __   _       
// |  \/  |    | |    \ \    / /  | |      
// | \  / | ___| |_ __ \ \  / /__ | |_ ___ 
// | |\/| |/ _ \ __/ _` \ \/ / _ \| __/ _ \
// | |  | |  __/ || (_| |\  / (_) | ||  __/
// |_|__|_|\___|\__\__,_|_\/ \___/ \__\___|
// |  __ \ / __ \| |    | |                
// | |__) | |  | | |    | |                
// |  ___/| |  | | |    | |                
// | |    | |__| | |____| |____            
// |_|     \____/|______|______|           
//
//
// @author burakcbdn https://burakcbdn.me
//


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: contracts/MetaVotePoll.sol

pragma solidity >=0.7.0 <0.9.0;


contract MetaVotePoll is Ownable {


    struct Option {
        string name;
        uint256 voteCount;
        uint256 id;
    }

    struct Voting {
        Option[] options;
        string title;
        uint256 totalVoteCount;
        uint256 priceToVote;
        mapping(address => Voter) voters;
        address[] voterAddresses;
    }

    struct Voter {
        uint256 voteID;
    }

    Voting[] public currentVotings;

    address public votingOwner;

    /**
    * @param title name of the voting
    * @param priceToVote required price for voting
    * @dev Creates new voting
    */
    function createVoting(string calldata title, uint256 priceToVote)
        public
        onlyOwner
    {
        Voting storage newVoting = currentVotings.push();
        newVoting.title = title;
        newVoting.priceToVote = priceToVote;
    }

    /**
    * @param index index of the voting
    * @param name of the option
    * @param id id of the option
    * @dev Adds new option to specified voting
    */
    function addOptionToVoting(
        uint256 index,
        string calldata name,
        uint256 id
    ) public onlyOwner {
        currentVotings[index].options.push(
            Option({name: name, id: id, voteCount: 0})
        );
    }

    /**
    * @param votingIndex index of the voting
    * @param optionIndex index of the option
    * @dev Votes the specified option of specified voting, checks amount if any specified
    */
    function vote(uint8 votingIndex, uint8 optionIndex) public payable {
        require(votingIndex < currentVotings.length, "Voting Not Found");

        Voting storage currentVoting = currentVotings[votingIndex];
        require(currentVoting.voters[msg.sender].voteID == 0, "Already Voted");

        // check sent value

        require(
            msg.value >= currentVoting.priceToVote,
            "Insufficcient amount to vote"
        );

        currentVoting.voters[msg.sender].voteID = currentVoting
            .options[optionIndex]
            .id;
        currentVoting.voterAddresses.push(msg.sender);
        currentVoting.options[optionIndex].voteCount =
            currentVoting.options[optionIndex].voteCount +
            1;
    }

    /**
    * @param votingIndex index of the voting
    * @dev returns the title of the specified voting
    */
    function getVotingTitleFromIndex(uint8 votingIndex)
        public
        view
        returns (string memory)
    {
        require(votingIndex < currentVotings.length, "Voting Not Found");
        return currentVotings[votingIndex].title;
    }

    /**
    * @param votingIndex index of the voting
    * @dev returns the name of the winning option
    */
    function getWinnerName(uint8 votingIndex)
        public
        view
        onlyOwner
        returns (string memory)
    {
        require(votingIndex < currentVotings.length, "Voting Not Found");

        uint256 currentMax = 0;
        string memory currentWinner;

        for (
            uint256 i = 0;
            i < currentVotings[votingIndex].options.length;
            i++
        ) {
            if (currentVotings[votingIndex].options[i].voteCount > currentMax) {
                currentMax = currentVotings[votingIndex].options[i].voteCount;
                currentWinner = currentVotings[votingIndex].options[i].name;
            }
        }

        return currentWinner;
    }


    /**
    * @param votingIndex index of the voting
    * @dev returns the id of the winning option
    */
    function getWinnerID(uint8 votingIndex)
        public
        view
        onlyOwner
        returns (uint256)
    {
        require(votingIndex < currentVotings.length, "Voting Not Found");

        uint256 currentMax = 0;
        uint256 currentWinner;

        for (
            uint256 i = 0;
            i < currentVotings[votingIndex].options.length;
            i++
        ) {
            if (currentVotings[votingIndex].options[i].voteCount > currentMax) {
                currentMax = currentVotings[votingIndex].options[i].voteCount;
                currentWinner = currentVotings[votingIndex].options[i].id;
            }
        }
        return currentWinner;
    }

    /**
    * @param votingIndex index of the voting
    * @dev Shares total amounts amount the voters of the winning option, takes %10 cut to owner
    */
    function sendAmountsToVoting(uint8 votingIndex) public payable onlyOwner {
        require(votingIndex < currentVotings.length, "Voting Not Found");

        uint256 totalBalance = address(this).balance;

        (bool ownerCut, ) = payable(owner()).call{
            value: (totalBalance * 10) / 100
        }("");
        require(ownerCut);

        uint256 remainingBalance = totalBalance - (totalBalance * 10) / 100;

        uint256 currentMax = 0;
        uint256 currentWinner = 0;

        for (
            uint256 i = 0;
            i < currentVotings[votingIndex].options.length;
            i++
        ) {
            if (currentVotings[votingIndex].options[i].voteCount > currentMax) {
                currentMax = currentVotings[votingIndex].options[i].voteCount;
                currentWinner = currentVotings[votingIndex].options[i].id;
            }
        }

        uint256 prizePerVoter = remainingBalance / currentMax;

        for (
            uint256 i = 0;
            i < currentVotings[votingIndex].voterAddresses.length;
            i++
        ) {
            address adressOfVoter = currentVotings[votingIndex].voterAddresses[
                i
            ];
            if (
                currentVotings[votingIndex].voters[adressOfVoter].voteID ==
                currentWinner
            ) {
                (bool winnerCut, ) = payable(owner()).call{
                    value: prizePerVoter
                }("");
                require(winnerCut);
            }
        }
    }
}