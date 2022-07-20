// contracts/Wcsp.sol
// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// Wcsp Contract
//
// Actors:
//  Challenge Submitter   - The one who submitted a challenge. Challenge Submitter can cancel submitted challenge
//                          if challenge was not fulfilled in certain time.
//  Challenge Contributor - The one who contributed additional funds to existing challenge. Challenge Contributor
//                          doesn't have any additional rights for challenge he contributed to.
//  Challenge Receiver    - The one who challenged.
//  Contract Owner        - Company deployed a contract.
//
// API:
//  Submit challenge by Challenge Submitter: streamerId, challengeId, senderAddress, targetAddress, Eth
//  Contribute to a challenge by Challenge Contributor: streamerId, challengeId, Eth
//  Cancel challenge by Challenge Submitter: streamerId, challengeId
//  Cancel challenge by Contract Owner: streamerId, challengeId
//  Payout challenge by Contract Owner: streamerId, challengeId
//
// Features:
//  Set/Update default payout commission fee
//  Set/Update personal payout commission fee for a specific Challenge Receiver
//  Charge additional commission to cover expenses for payout by Contract Owner
//  Charge additional commission to cover expenses for cancellation by Contract Owner
//  Set/Update min time after which Challenge might be canceled by Challenge Submitter
//  Set/Update min time after which Challenge might be canceled by Contract Owner
//  Set/Update min value that might be sent during the cancellation

contract Wcsp is ReentrancyGuard, Ownable {
    // Enums
    enum ChallengeStatus {
        UNKNOWN,
        CREATED,
        PAYED,
        CANCELED_BY_SUBMITTER,
        CANCELED_BY_OWNER
    }

    // Structs
    struct Challenge {
        string key;
        ChallengeStatus status;
        address receiverAddress;
        uint256[] contributedEth;
        address[] contributorsAddress;
    }

    // Events
    event ChallengeSubmitted(string indexed streamerId, string indexed challengeId, address receiverAddress);
    event ChallengeContributed(string indexed streamerId, string indexed challengeId, address sender, uint256 value);
    event ChallengePayoutRequested(string indexed streamerId, string indexed challengeId, address sender);
    event ChallengePayoutComplete(
        string indexed streamerId,
        string indexed challengeId,
        address sender,
        uint256 payoutSum,
        uint256 payoutSumAfterCommissionFee,
        uint256 commissionFee
    );
    event ChallengeCancelBySubmitterRequested(string indexed streamerId, string indexed challengeId, address sender);
    event ChallengeCancelBySubmitterComplete(
        string indexed streamerId,
        string indexed challengeId,
        address sender,
        uint256 payoutSum
    );
    event ChallengeCancelByOwnerRequested(string indexed streamerId, string indexed challengeId, address sender);
    event ChallengeCancelByOwnerIncompleteContributorPayment(string indexed streamerId, string indexed challengeId, uint256 index, uint256 payoutValue, uint256 contributorsFee);
    event ChallengeCancelByOwnerComplete(
        string indexed streamerId,
        string indexed challengeId,
        address sender,
        uint256 payoutSum,
        uint256 finalPayoutSum
    );

    // Settings
    // TODO: modifiers
    uint256 private minSubmitValue = 0.0049 ether;
    uint256 private minContributeValue = 0.0049 ether;

    // TODO: implementation and tests
    uint256 private payoutCommissionFee = 30;

    // Challenge data
    mapping(string => ChallengeStatus) private challengeKeyToStatus;
    mapping(string => uint256[]) private challengeKeyToContributedEth;
    mapping(string => address[]) private challengeKeyToContributorsAddress;
    mapping(string => address) private challengeKeyToReceiverAddress;

    // TODO: how to validate that receiver address belongs to streamer
    // TODO: currently you can validate any challenge with any valid transaction
    function submitChallenge(
        string calldata _streamerId,
        string calldata _challengeId,
        address _receiverAddress,
        uint256 _value
    ) external payable nonReentrant {
        // validate params
        require(msg.value == _value, "400:value");
        require(msg.value >= minSubmitValue, "400:min value");
        require(msg.sender != _receiverAddress, "400:sender eq receiver");
        require(_receiverAddress != address(0), "400:zero receiver address");

        // generate key
        string memory key = genChallengeKey(_streamerId, _challengeId);

        // make sure challenge doesn't exist
        require(challengeKeyToStatus[key] == ChallengeStatus.UNKNOWN, "403:already exists");

        // save challenge data
        challengeKeyToStatus[key] = ChallengeStatus.CREATED;
        challengeKeyToReceiverAddress[key] = _receiverAddress;
        challengeKeyToContributedEth[key].push(msg.value);
        challengeKeyToContributorsAddress[key].push(msg.sender);

        // TODO: add data of the challenge as hash
        emit ChallengeSubmitted(_streamerId, _challengeId, _receiverAddress);
    }

    function contributeToChallenge(
        string calldata _streamerId,
        string calldata _challengeId,
        uint256 _value
    ) external payable nonReentrant {
        // validate params
        require(msg.value == _value, "400:value");
        require(msg.value >= minContributeValue, "400:min value");

        // generate key
        string memory key = genChallengeKey(_streamerId, _challengeId);

        // make sure challenge exists and not payed or canceled
        require(challengeKeyToStatus[key] == ChallengeStatus.CREATED, "404:not found");

        // update challenge data
        challengeKeyToContributedEth[key].push(msg.value);
        challengeKeyToContributorsAddress[key].push(msg.sender);

        // emit event
        emit ChallengeContributed(_streamerId, _challengeId, msg.sender, msg.value);
    }

    function payoutChallenge(
        string calldata _streamerId,
        string calldata _challengeId
    ) external nonReentrant onlyOwner {
        // generate key
        string memory key = genChallengeKey(_streamerId, _challengeId);

        // make sure challenge exists and not payed or canceled
        require(challengeKeyToStatus[key] == ChallengeStatus.CREATED, "404:not found");

        // emit payout requested event
        emit ChallengePayoutRequested(_streamerId, _challengeId, msg.sender);

        // mark as payed
        challengeKeyToStatus[key] = ChallengeStatus.PAYED;

        // calculate payout sum
        uint256 payoutSum = 0;
        uint256[] memory payoutList = challengeKeyToContributedEth[key];
        for (uint256 i = 0; i < payoutList.length; i++) {
            payoutSum += payoutList[i];
        }
        uint256 payoutSumAfterCommissionFee = uint256(payoutSum * (100 - payoutCommissionFee) / 100);

        // transfer funds to receiver
        payable(challengeKeyToReceiverAddress[key]).transfer(payoutSumAfterCommissionFee);

        // emit payout complete event
        emit ChallengePayoutComplete(_streamerId, _challengeId, msg.sender, payoutSum, payoutSumAfterCommissionFee, payoutCommissionFee);
    }

    function cancelChallengeBySubmitter(
        string calldata _streamerId,
        string calldata _challengeId
    ) external nonReentrant {
        // generate key
        string memory key = genChallengeKey(_streamerId, _challengeId);

        // make sure challenge exists and not payed or canceled
        require(challengeKeyToStatus[key] == ChallengeStatus.CREATED, "404:not found");

        // contributions lists
        uint256[] memory contributedEthList = challengeKeyToContributedEth[key];
        address[] memory contributorsAddressList = challengeKeyToContributorsAddress[key];

        // make sure sender is submitter
        require(contributorsAddressList[0] == msg.sender, "401:unauthorized");

        // emit cancel requested event
        emit ChallengeCancelBySubmitterRequested(_streamerId, _challengeId, msg.sender);

        // mark as canceled by submitter
        challengeKeyToStatus[key] = ChallengeStatus.CANCELED_BY_SUBMITTER;

        // transfer funds back to all contributors
        uint256 payoutSum = 0;
        for (uint256 i = 0; i < contributedEthList.length; i++) {
            uint256 val = contributedEthList[i];
            payoutSum += val;
            payable(contributorsAddressList[i]).transfer(val);
        }

        // emit cancel complete event
        emit ChallengeCancelBySubmitterComplete(_streamerId, _challengeId, msg.sender, payoutSum);
    }

    function getChallenge(
        string calldata _streamerId,
        string calldata _challengeId
    ) public view returns (Challenge memory) {
        string memory key = genChallengeKey(_streamerId, _challengeId);
        return
        Challenge(
            key,
            challengeKeyToStatus[key],
            challengeKeyToReceiverAddress[key],
            challengeKeyToContributedEth[key],
            challengeKeyToContributorsAddress[key]
        );
    }

    // TODO: more tests
    function cancelChallengeByOwner(
        string calldata _streamerId,
        string calldata _challengeId,
        uint256 _cancellationFeePerContrib
    ) external nonReentrant onlyOwner {
        // generate key
        string memory key = genChallengeKey(_streamerId, _challengeId);

        // make sure challenge exists and not payed or canceled
        require(challengeKeyToStatus[key] == ChallengeStatus.CREATED, "404:not found");

        // emit request event
        emit ChallengeCancelByOwnerRequested(_streamerId, _challengeId, msg.sender);

        // change status of the challenge
        challengeKeyToStatus[key] = ChallengeStatus.CANCELED_BY_OWNER;

        // contributions lists
        uint256[] memory contributedEthList = challengeKeyToContributedEth[key];
        address[] memory contributorsAddressList = challengeKeyToContributorsAddress[key];

        // payout cost after commission fee applied
        uint256 payoutSum = 0;
        uint256 finalPayoutSum = 0;
        for (uint256 i = 0; i < contributedEthList.length; i++) {
            uint256 val = contributedEthList[i];
            payoutSum += val;
            if (val > _cancellationFeePerContrib) {
                uint256 finalVal = val - _cancellationFeePerContrib;
                finalPayoutSum += finalVal;
                payable(contributorsAddressList[i]).transfer(finalVal);
            } else {
                emit ChallengeCancelByOwnerIncompleteContributorPayment(_streamerId, _challengeId, i, val, _cancellationFeePerContrib);
            }
        }

        // emit complete event
        emit ChallengeCancelByOwnerComplete(_streamerId, _challengeId, msg.sender, payoutSum, finalPayoutSum);
    }

    function genChallengeKey(
        string calldata _streamerId,
        string calldata _challengeId
    ) internal pure returns (string memory) {
        return string(abi.encodePacked(_streamerId, "-", _challengeId));
    }

    // todo: withdrawal
    // todo: refill
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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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