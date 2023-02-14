/**
 *Submitted for verification at Etherscan.io on 2023-02-14
*/

// File: contracts/Types.sol



pragma solidity >=0.7.0 <0.9.0;

library Types {
    struct Affair {
        uint256 id; // AffairID, e.g. 20210044
        string ref; // AffairID, e.g. 21.044
        string topic; // Thema, e.g. Keine Massentierhaltung in der Schweiz (Massentierhaltungsinitiative). Volksinitiative und direkter Gegenentwurf
        string date; // Einreichungsdatum, e.g. 19.05.2021
    }

    struct Vote {
        uint256 id; // AffairID
        bool voted; // Ja oder Nein
        uint256 votedAt; // Wann wurde die Stimme abgegeben?
    }

    struct Votes {
        uint256 id; // AffairID
        uint256 yay; // Ja-Stimmen
        uint256 nay; // Nein-Stimmen
    }
}

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: contracts/Voting.sol



pragma solidity >=0.7.0 <0.9.0;



/**
 * @title Voting
 * @dev Implements the functions for voting
 */
contract Voting is Ownable {
    mapping(uint256 => Types.Affair) affairs;
    mapping(uint256 => Types.Votes) votes;
    mapping(address => mapping(uint256 => Types.Vote)) voters;

    uint256[] private affairIDs;

    uint256 private startTime;
    uint256 private endTime;
    address votingOwner;

    string public name; // Volksabstimmung vom 25. September 2022
    string public description;

/*
[[20210044,"21.044","Keine Massentierhaltung in der Schweiz (Massentierhaltungsinitiative).\nVolksinitiative und direkter Gegenentwurf","19.05.2021"],
[20210024,"21.024","Verrechnungssteuergesetz.\nStärkung des Fremdkapitalmarkts","14.04.2021"],
[20190050,"19.050","Stabilisierung der AHV (AHV 21)\nBundesgesetz über die Alters- und Hinterlassenenversicherung (AHVG)\nBundesbeschluss über die Zusatzfinanzierung der AHV durch eine Erhöhung der Mehrwertsteuer","28.08.2019"]]
*/

    constructor(
        string memory _name,
        string memory _description,
        Types.Affair[] memory _affairs
    ) onlyOwner {
        name = _name;
        description = _description;

        for (uint256 i = 0; i < _affairs.length; i++) {
            Types.Affair memory affair = _affairs[i];

            affairs[affair.id] = affair;
            affairIDs.push(affair.id);

            votes[affair.id].id = affair.id;
        }

        votingOwner = msg.sender;
    }

    function getAffairs() public view returns (Types.Affair[] memory) {
        Types.Affair[] memory _affairs = new Types.Affair[](affairIDs.length);

        for (uint256 i = 0; i < affairIDs.length; i++) {
            _affairs[i] = affairs[affairIDs[i]];
        }

        return _affairs;
    }

    // Public vote function for voting on an affair
    function vote(uint256 _id, bool _vote) public isOpen {
        require(affairs[_id].id == _id, "affair does not exist");

        Types.Vote memory oldVote = voters[msg.sender][_id];
        if (oldVote.id == _id) {
            // revert old vote
            if (oldVote.voted) {
                votes[_id].yay--;
            } else {
                votes[_id].nay--;
            }
        }

        voters[msg.sender][_id] = Types.Vote({
            id: _id,
            voted: _vote,
            votedAt: block.timestamp
        });

        if (_vote) {
            votes[_id].yay++;
        } else {
            votes[_id].nay++;
        }
    }

    function getVote(uint256 _id) public view hasStarted returns (Types.Vote memory) {
        require(affairs[_id].id == _id, "affair does not exist");

        return voters[msg.sender][_id];
    }

    function hasVoted(uint256 _id) public view hasStarted returns (bool) {
        require(affairs[_id].id == _id, "affair does not exist");
        require(voters[msg.sender][_id].id == _id, "vote does not exist");

        return voters[msg.sender][_id].voted;
    }

    function getVotes(uint256 _id) public view hasStarted returns (Types.Votes memory) {
        require(affairs[_id].id == _id, "affair does not exist");
        // require(votes[_id].id == _id, "votes do not exist");

        return votes[_id];
    }

    function getResults() public view isClosed returns (Types.Votes[] memory) {
        Types.Votes[] memory _votes = new Types.Votes[](affairIDs.length);

        for (uint256 i = 0; i < affairIDs.length; i++) {
            _votes[i] = votes[affairIDs[i]];
        }

        return _votes;
    }

    function getTimestamp() public view returns (uint256) {
        return block.timestamp;
    }

    // Owner functions

    function setStartTime(uint256 _startTime) public onlyVotingOwner {
        startTime = _startTime;
    }

    function setEndTime(uint256 _endTime) public onlyVotingOwner {
        endTime = _endTime;
    }

    // Helper functions

    modifier onlyVotingOwner() {
        require(msg.sender == votingOwner, "only for voting owner");
        _;
    }

    modifier isOpen() {
        require(startTime > 0 && block.timestamp >= startTime, "voting not started");
        require(endTime > 0 && block.timestamp <= endTime, "voting ended");
        _;
    }

    modifier isClosed() {
        require(startTime > 0 && block.timestamp >= startTime, "voting not started");
        require(endTime > 0 && block.timestamp >= endTime, "voting not ended");
        _;
    }

    modifier hasStarted() {
        require(startTime > 0 && block.timestamp >= startTime, "voting not started");
        _;
    }

    modifier hasEnded() {
        require(endTime > 0 && block.timestamp >= endTime, "voting not ended");
        _;
    }
}