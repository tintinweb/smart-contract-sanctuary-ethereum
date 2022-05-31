// contracts/Wcsp.sol
// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

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
//  Set/Update default commission
//  Set/Update personal commission for a specific Challenge Receiver
//  Charge additional commission to cover expenses for payout by Contract Owner
//  Charge additional commission to cover expenses for cancellation by Contract Owner
//  Set/Update min time after which Challenge might be canceled by Challenge Submitter
//  Set/Update min time after which Challenge might be canceled by Contract Owner
contract Wcsp is ReentrancyGuard, Ownable {
    // libraries
    using Strings for uint256;

    // enums
    enum ChallengeStatus{UNKNOWN, CREATED, PAYED, CANCELED_BY_SUBMITTER, CANCELED_BY_OWNER}

    // settings
    uint256 private minSubmitValue = 1 wei;
    uint256 private minContributeValue = 1 wei;

    // challenge data
    mapping(string => ChallengeStatus) private challengeKeyToStatus;
    mapping(string => uint256[]) private challengeKeyToSubmitterEth;
    mapping(string => address[]) private challengeKeyToSubmitterAddress;
    mapping(string => address) private challengeKeyToReceiverAddress;

    function submitChallenge(uint256 _streamerId, uint256 _challengeId, address _receiverAddress, uint256 _value) external payable nonReentrant {
        // validate params
        require(msg.value == _value, "invalid params: value");
        require(msg.value >= minSubmitValue, "invalid params: minValue");
        require(_receiverAddress != address(0), "invalid params: receiverAddress");

        // generate key
        string memory key = genChallengeKey(_streamerId, _challengeId);

        // make sure challenge doesn't exist
        require(challengeKeyToStatus[key] == ChallengeStatus.UNKNOWN, "challenge already exists");

        // save challenge data
        challengeKeyToStatus[key] = ChallengeStatus.CREATED;
        challengeKeyToReceiverAddress[key] = _receiverAddress;
        challengeKeyToSubmitterEth[key].push(msg.value);
        challengeKeyToSubmitterAddress[key].push(msg.sender);
    }

    function contributeToChallenge(uint256 _streamerId, uint256 _challengeId, uint256 _value) external payable nonReentrant {
        // validate params
        require(msg.value == _value, "invalid params: value");
        require(msg.value >= minContributeValue, "invalid params: minValue");

        // generate key
        string memory key = genChallengeKey(_streamerId, _challengeId);

        // make sure challenge exists and not payed
        require(challengeKeyToStatus[key] == ChallengeStatus.CREATED, "challenge doesnt exist or already payed");

        // update challenge data
        challengeKeyToSubmitterEth[key].push(msg.value);
        challengeKeyToSubmitterAddress[key].push(msg.sender);
    }


    function payoutChallenge(uint256 _streamerId, uint256 _challengeId) external nonReentrant onlyOwner {
        // generate key
        string memory key = genChallengeKey(_streamerId, _challengeId);

        // make sure challenge exists and not payed
        require(challengeKeyToStatus[key] == ChallengeStatus.CREATED, "challenge doesnt exist or already payed");

        // calculate payout sum
        uint256 payoutSum = 0;
        uint256[] memory contributionsList = challengeKeyToSubmitterEth[key];
        for (uint256 i = 0; i < contributionsList.length; i++) {
            payoutSum += contributionsList[i];
        }

        // transfer funds to receiver
        // TODO: Is it possible to fraud through "out of gas"? Can I solve it via events?
        payable(challengeKeyToReceiverAddress[key]).transfer(payoutSum);

        // mark as payed if transfer didn't rollback
        challengeKeyToStatus[key] = ChallengeStatus.PAYED;
    }

    function cancelChallengeBySubmitter(uint256 _streamerId, uint256 _challengeId) external nonReentrant {
        // generate key
        string memory key = genChallengeKey(_streamerId, _challengeId);

        // make sure challenge exists and not payed
        require(challengeKeyToStatus[key] == ChallengeStatus.CREATED, "challenge doesnt exist or already payed");

        // contributions lists
        uint256[] memory contributionsListEth = challengeKeyToSubmitterEth[key];
        address [] memory contributionsListAddress = challengeKeyToSubmitterAddress[key];

        // make sure sender is submitter
        require(contributionsListAddress[0] == msg.sender, "sender not submitter");

        // validate list same length
        require(contributionsListEth.length == contributionsListAddress.length, "contributions len diff");

        // transfer funds back to all contributors
        // TODO: Is it possible to fraud through "out of gas"? Can I solve it via events?
        for (uint256 i = 0; i < contributionsListEth.length; i++) {
            payable(contributionsListAddress[i]).transfer(contributionsListEth[i]);
            contributionsListEth[i] = 0;
        }

        // mark as canceled by submitter
        challengeKeyToStatus[key] = ChallengeStatus.CANCELED_BY_SUBMITTER;
    }

    function cancelChallengeByOwner(uint256 _streamerId, uint256 _challengeId) external nonReentrant onlyOwner {
        // TODO: implement
        // https://ethereum.stackexchange.com/questions/17993/can-a-smart-contract-read-the-gas-cost-of-a-transaction
    }

    function genChallengeKey(uint256 _streamerId, uint256 _challengeId) internal pure returns (string memory) {
        return string(abi.encodePacked(_streamerId.toString(), "-", _challengeId.toString()));
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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
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