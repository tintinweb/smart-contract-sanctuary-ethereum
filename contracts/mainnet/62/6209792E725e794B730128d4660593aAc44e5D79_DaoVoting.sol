// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface IReflectionToken {
    function getPendingRewardByVoting() external view returns(uint256);
    function distributeRewardByVoting(address, uint256) external;
    function getCurrentSnapshotId() external view returns(uint256);
    function balanceOfAt(address, uint256) external view returns(uint256);
    function snapshot() external returns(uint256);
}

contract DaoVoting is Ownable, ReentrancyGuard {
    uint private timeOut = 2 days; 
    
    // Minimum number of yes votes required to win = 200k
    uint public minVotes = 2 * 10 ** 23;

    IReflectionToken public reflectionToken;


    // Structure for votes
    struct Votes {
        uint256 voteStartingTime;
        bool voteActive;
        mapping(address=>uint8) voters;
        address[] voterList;
        uint256 yesPower;
        uint256 noPower;
        address receiver;
        uint256 amount;
        uint256 snapshotId;
    }
    // Variable for vote structure
    Votes public election;

    // Initialization function (takes the address of the token)
    constructor( address _reflection) {
        reflectionToken = IReflectionToken(_reflection);
    }

    function strToBytes32(string memory _string) internal pure returns(bytes32) {
        return keccak256(abi.encodePacked(_string));
    }

    function startVote(address _newWallet, uint256 _amount) public {
        require(!election.voteActive);
        _amount = _amount * (10 ** 18); // assume that submitters will not add decimals manually
        // Check if amount is correct
        uint256 pendingAmount = reflectionToken.getPendingRewardByVoting();
        require(_amount > 0 && _amount <= pendingAmount);
        uint256 snapshotId = reflectionToken.snapshot();
        require(snapshotId > 0);
        require(reflectionToken.balanceOfAt(_msgSender(), snapshotId) > 0);

        election.receiver = _newWallet;
        election.voteStartingTime = block.timestamp;
        election.voteActive = true;
        election.amount = _amount;
        election.snapshotId = snapshotId;
    }
    
    // Voting function
    function vote(uint8 _answer) public {
        // Verify that the vote is in progress
        require(election.voteActive);
        // Check that there is at least one token
        require(reflectionToken.balanceOfAt(_msgSender(), election.snapshotId)> 0);
        // Cehck _answer mustbe 1 or 2
        require(_answer <= 2 && _answer > 0);
        // Check if user already voted
        require(election.voters[_msgSender()]==0);
        // Check if vote is in progress
        require(election.voteStartingTime <= block.timestamp && election.voteStartingTime + timeOut  >= block.timestamp);

        if( _answer == 1 ) {
            election.yesPower += reflectionToken.balanceOfAt(_msgSender(),election.snapshotId);
        } else {
            election.noPower += reflectionToken.balanceOfAt(_msgSender(),election.snapshotId);
        }
        election.voters[_msgSender()] = _answer;
        election.voterList.push(_msgSender());
    }
    // Function to voting
    function finishCurrentVote() public nonReentrant returns(uint8){

        // Checking if voting is active
        require(election.voteActive);
        // Checking that the creation time of the vote has been created
        require(election.voteStartingTime != 0);
        // Check if vote finished
        require(election.voteStartingTime + timeOut  < block.timestamp);

        uint8 winnerId;
        if( (election.yesPower > election.noPower) && (election.yesPower > minVotes ) ) winnerId = 1;
        else winnerId = 2;

        if(winnerId == 1) {
            //send reward token to receiver
            reflectionToken.distributeRewardByVoting(election.receiver,election.amount);
        }

        // Resetting all voting variables
        for(uint8 i = 0; i < election.voterList.length; i++) {
            address voter = election.voterList[i];
            delete election.voters[voter];
        }
        
        election.voteStartingTime = 0;
        election.yesPower = 0;
        election.noPower = 0;
        election.voteActive = false;
        election.receiver = address(0);
        election.amount = 0;
        delete election.voterList;
    
        return winnerId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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