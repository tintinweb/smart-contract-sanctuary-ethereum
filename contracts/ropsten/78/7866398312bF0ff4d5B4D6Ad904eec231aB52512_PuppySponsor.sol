// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.14;

import "./Ownable.sol";
import "./EnumerableSet.sol";

contract PuppySponsor is Ownable {
    using EnumerableSet for EnumerableSet.Bytes32Set;

    // Total donations amount for puppies.
    uint256 public donatePuppyTransactionCount;

    // The sum of donations received, in (wei).
    // Includes donations for a specific puppy and donations for feed.
    uint256 public totalDonationAmount;

    // A unique identifier that represents not a puppy.
    bytes32 constant NOT_PUPPY_ID = bytes32(0);

    event Donated(address indexed from, address indexed dest, bytes32 puppyId, uint256 amount, uint256 time);
    event PuppyAdded(bytes32 indexed puppyId, string name, string birthday, string imageUrl, string description, uint256 time);

    // A donation transaction, may for a specific puppy.
    struct DonateTransaction {
        address donor;
        address receiver;
        // The amount of the transaction, in (wei).
        uint256 amount;
        // The block time when the transaction was on-chain.
        uint256 time;
        // The puppy's unique identification code.
        // But if the transaction is not for a specific puppy (donations for feed), the value is NOT_PUPPY_ID.
        bytes32 puppyId;
        // Information attached by the donor to this donation.
        string message;
        // Donor-customized keywords.
        string keyword;
    }

    // A puppy entity, which contains its information.
    struct Puppy {
        // The puppy's unique identification code.
        bytes32 puppyId;
        // The puppy's name.
        string name;
        // The puppy's birthday.
        string birthday;
        // An image's url for the puppy.
        string imageUrl;
        // The detail information for the puppy.
        string description;
    }

    DonateTransaction[] private _transactions;

    // A set to store puppy id.
    EnumerableSet.Bytes32Set private _puppyIdSet;

    Puppy[] private _puppies;

    constructor() Ownable() {}

    /**
     * @dev Compare if the provided string is same.
     * Using keccak256 hash to compare.
     */
    function _strEq(string memory a, string memory b) internal pure returns (bool) {
        if (bytes(a).length != bytes(b).length) {
            return false;
        }

        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }

    /**
     * @dev Check if puppyId is valid.
     */
    function _isValidPuppyId(bytes32 puppyId) private view returns (bool) {
        return _puppyIdSet.contains(puppyId);
    }

    /**
     * @dev donate for puppy or food.
     *
     * Emits an {Donated} event to record a donation.
     *
     * Requirements:
     *
     * - `msg.value` The transaction value must be greater than zero.
     */
    function _donate(bytes32 puppyId, string calldata message, string calldata keyword) private {
        require(msg.value > 0, "The transaction value must be greater than zero!");

        donatePuppyTransactionCount++;
        totalDonationAmount += msg.value;

        payable(owner()).transfer(msg.value);

        DonateTransaction memory newTransaction = DonateTransaction(msg.sender, owner(), msg.value, block.timestamp, puppyId, message, keyword);
        _transactions.push(newTransaction);

        emit Donated(msg.sender, owner(), puppyId, msg.value, block.timestamp);
    }

    /**
     * @dev generate a new bytes32 value for unique identification (may not unique).
     */
    function _generateId() private view returns (bytes32) {
        return keccak256(abi.encodePacked(block.timestamp));
    }

    /**
     * @dev generate a new, unused puppy id.
     */
    function _generatePuppyId() private view returns (bytes32) {
        bytes32 puppyId = _generateId();

        while (!_isValidPuppyId(puppyId)) {
            puppyId = _generateId();
        }

        return puppyId;
    }

    /**
     * @dev donate for food.
     */
    function donateForFood(string calldata message, string calldata keyword) external payable {
        _donate(NOT_PUPPY_ID, message, keyword);
    }

    /**
     * @dev donate for puppy or food.
     *
     * Requirements:
     *
     * - `puppyId` must exist.
     */
    function donateForPuppy(bytes32 puppyId, string calldata message, string calldata keyword) external payable {
        require(_isValidPuppyId(puppyId));
        _donate(puppyId, message, keyword);
    }

    /**
     * @dev donate for puppy or food.
     *
     * Requirements:
     *
     * - `name` should not be empty.
     * - `birthday` should not be empty, with format of yyyy/mm/dd.
     * - `imageUrl` should not be empty.
     */
    function createNewPuppy(string calldata name, string calldata birthday, string calldata imageUrl, string calldata description) external onlyOwner {
        require(!_strEq(name, ""));
        require(!_strEq(birthday, ""));
        require(!_strEq(imageUrl, ""));

        bytes32 newPuppyId = _generatePuppyId();
        _puppyIdSet.add(newPuppyId);

        _puppies.push(Puppy(newPuppyId, name, birthday, imageUrl, description));

        emit PuppyAdded(newPuppyId, name, birthday, imageUrl, description, block.timestamp);
    }
}