/**
 *Submitted for verification at Etherscan.io on 2022-04-28
*/

// Sources flattened with hardhat v2.9.3 https://hardhat.org

// File @openzeppelin/contracts/utils/[email protected]

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


// File @openzeppelin/contracts/access/[email protected]

// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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


// File @openzeppelin/contracts/utils/[email protected]

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


// File contracts/Vote.sol

pragma solidity ^0.8.0;
contract Vote is Ownable {
    struct Voting {
        bool isOpen;
        address[] candidates;
        uint256[] votes;
        uint256 lockTime;
        uint256 deposits;
    }
    struct Winners {
        address payable[] candidates;
        uint256 count;
    }

    event VotingCreated(uint256 id);
    event VotingFinished(uint256 id);
    event VotingWon(uint256 id, address winner, uint256 amount);
    event Voted(uint256 votingId, uint256 candidate);
    event Withdrawed(uint256 amount);

    mapping(address => mapping(uint256 => bool)) private votes;
    Voting[] private votings;

    uint256 private votingDelay;
    uint256 private depositAmount;
    uint256 private taxAmount;
    uint256 private availableForWithdrawal;

    constructor(
        uint256 _votingDelay,
        uint256 _depositAmount,
        uint256 _taxAmount
    ) {
        votingDelay = _votingDelay;
        depositAmount = _depositAmount;
        taxAmount = _taxAmount;
    }

    function addVoting(address[] memory _candidates) public onlyOwner {
        Voting memory voting = Voting({
            isOpen: true,
            candidates: _candidates,
            votes: new uint256[](_candidates.length),
            lockTime: block.timestamp + votingDelay,
            deposits: 0
        });
        votings.push(voting);
        emit VotingCreated(votings.length - 1);
    }

    function finish(uint256 _votingIndex) public onlyOwner {
        require(_votingIndex < votings.length, "Invalid voting index");
        require(votings[_votingIndex].isOpen, "Voting is not open");
        require(
            block.timestamp >= votings[_votingIndex].lockTime,
            "Voting is not finished yet"
        );

        Voting storage voting = votings[_votingIndex];
        voting.isOpen = false;
        uint256 max = getMax(voting.votes);
        Winners memory winners = findElementsInArray(
            max,
            voting.votes,
            voting.candidates
        );
        uint256 prizeValue = (voting.deposits * (100 - taxAmount)) /
            (winners.count * 100);
        for (uint256 i = 0; i < winners.count; i++) {
            winners.candidates[i].transfer(prizeValue);
            voting.deposits -= prizeValue;
            emit VotingWon(_votingIndex, winners.candidates[i], prizeValue);
        }
        availableForWithdrawal += voting.deposits;
        voting.deposits = 0;
        emit VotingFinished(_votingIndex);
    }

    function getVoting(uint256 _votingIndex)
        public
        view
        returns (Voting memory)
    {
        require(_votingIndex < votings.length, "Invalid voting index");
        Voting memory voting = votings[_votingIndex];
        return voting;
    }

    function vote(uint256 _vote, uint256 _candidate) public payable {
        require(
            msg.value == depositAmount,
            string(
                abi.encodePacked(
                    "You must deposit ",
                    Strings.toString(depositAmount),
                    " wei to vote"
                )
            )
        );
        require(votes[msg.sender][_vote] == false, "You have already voted");
        require(votings[_vote].isOpen, "Voting is closed");
        require(
            votings[_vote].lockTime > block.timestamp,
            "Voting is outdated"
        );

        votes[msg.sender][_vote] = true;
        votings[_vote].votes[_candidate]++;
        votings[_vote].deposits += msg.value;
        emit Voted(_vote, _candidate);
    }

    function withdraw() public payable onlyOwner {
        require(availableForWithdrawal > 0, "No funds to withdraw");
        payable(msg.sender).transfer(availableForWithdrawal);
        emit Withdrawed(availableForWithdrawal);
        availableForWithdrawal = 0;
    }

    function findElementsInArray(
        uint256 element,
        uint256[] memory arr,
        address[] memory addresses
    ) private pure returns (Winners memory) {
        address payable[] memory result = new address payable[](arr.length);
        uint256 i = 0;
        for (uint256 j = 0; j < arr.length; j++) {
            if (arr[j] == element) {
                result[i] = payable(addresses[j]);
                i++;
            }
        }
        return Winners(result, i);
    }

    function getMax(uint256[] memory arr) private pure returns (uint256) {
        uint256 largest = 0;
        for (uint256 i = 0; i < arr.length; i++) {
            if (arr[i] > largest) {
                largest = arr[i];
            }
        }
        return largest;
    }
}