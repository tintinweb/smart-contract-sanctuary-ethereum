// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

import "./VotingPool.sol";

/// @title A voting factory contract
contract VotingFactory {
    //  A dynamically-sized array of pool addresses
    address[] public allVotingPools;

    /// @dev Emitted when a pool is created
    event VotingPoolCreated(
        uint256 id,
        bytes32 title,
        bytes32[] optionNames,
        address owner
    );

    /// @dev Deploy new voting pool and returns new voting pool address
    function createVotingPool(bytes32 title, bytes32[] memory optionNames)
        external
        returns (address votingPool)
    {
        uint256 nextVotingPoolId = allVotingPools.length;

        VotingPool newVotingPool = new VotingPool(
            nextVotingPoolId,
            title,
            optionNames,
            msg.sender
        );
        votingPool = address(newVotingPool);

        allVotingPools.push(votingPool);

        emit VotingPoolCreated(
            nextVotingPoolId,
            title,
            optionNames,
            msg.sender
        );
    }

    /// @dev returns allVotingPools array length
    function getVotingPoolsCount() external view returns (uint256) {
        return allVotingPools.length;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";

/// @title A voting pool contract
contract VotingPool is Ownable {
    // It will represent a single voter.
    struct Voter {
        bool voted;   // if true, that person already voted
        uint256 vote;   // index of the voted option
    }

    // This is a type for a single option.
    struct Option {
        bytes32 name;   // short name (up to 32 bytes)
        uint256 voteCount;  // number of accumulated votes
    }

    //  This is ID of this voting pool
    uint256 public id;
    //  This is title of this voting pool
    bytes32 public title;

    //  Mapping from user address to his Voter struct
    mapping(address => Voter) public voters;

    //  A dynamically-sized array of `Option` structs.
    Option[] public options;

    /// @dev Initializes the contract by setting a `id`, `title`, `optionNames` and a `owner`.
    constructor(
        uint256 _id,
        bytes32 _title,
        bytes32[] memory optionNames,
        address _owner
    ) {
        id = _id;
        title = _title;
        _transferOwnership(_owner);

        for (uint256 i = 0; i < optionNames.length; i++) {
            options.push(Option({name: optionNames[i], voteCount: 0}));
        }
    }

    /// @dev Function to vote for an option
    /// @param option is option index in options array
    function vote(uint256 option) external {
        Voter storage sender = voters[msg.sender];
        require(!sender.voted, "Already voted.");
        sender.voted = true;
        sender.vote = option;

        options[option].voteCount += 1;
    }

    ///@dev returns options array length
    function getNumOfOptions() external view returns (uint256) {
        return options.length;
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