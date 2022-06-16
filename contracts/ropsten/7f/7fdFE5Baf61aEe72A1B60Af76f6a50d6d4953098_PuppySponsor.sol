// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.14;

import "./Ownable.sol";
import "./EnumerableSet.sol";
import "./PuppyToken.sol";

/// @author NTUT smart contract class - team 9
/// @title Puppy sponsor: a donation platform for stray puppies
contract PuppySponsor is Ownable {
    using EnumerableSet for EnumerableSet.Bytes32Set;

    // Total donations amount for puppies.
    uint256 public donateTransactionAmount;

    // The sum of donations received, in (wei).
    // Includes donations for a specific puppy and donations for feed.
    uint256 public totalReceivedDonation;

    // A list that stores historical transaction records.
    DonateTransaction[] donateTransactions;

    // A list of puppies that can be donated. Once added, puppies are not allowed to be removed.
    Puppy[] puppies;

    // A set to store puppy id.
    EnumerableSet.Bytes32Set private _puppyIdSet;

    // An unique identifier that represents not a puppy.
    bytes32 private constant NOT_PUPPY_ID = bytes32(0);

    // The empty string.
    string private constant EMPTY_STRING = "";

    event Donated(address indexed from, address indexed dest, bytes32 puppyId, uint256 amount, uint256 time);
    event PuppyAdded(bytes32 indexed puppyId, string name, string birthday, string imageUrl, string description, uint256 time);

    // A donation transaction, may for a specific puppy.
    struct DonateTransaction {
        // The EOA address of the transaction initiator, i.e. the donor.
        address donor;
        // The EOA address of the transaction payee.
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

    // Token for Puppy Sponsor point back to donator.
    PuppyToken _token;

    constructor(address _tokenAddress) {
        _token = PuppyToken(_tokenAddress);
    }

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
     * Requirements:
     *
     * - `msg.value` must be greater than zero.
     *
     * Emits a {Donated} event to record the new donation.
     *
     */
    function _donate(bytes32 puppyId, string calldata message, string calldata keyword) private {
        require(msg.value >= 10 ** 15, "The transaction value must be greater than 0.001 ETH!");

        donateTransactionAmount++;
        totalReceivedDonation += msg.value;

        payable(owner()).transfer(msg.value);

        DonateTransaction memory newTransaction = DonateTransaction(msg.sender, owner(), msg.value, block.timestamp, puppyId, message, keyword);
        donateTransactions.push(newTransaction);

        emit Donated(msg.sender, owner(), puppyId, msg.value, block.timestamp);

        _token.transfer(msg.sender, msg.value / 10 ** 15);
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

        // Loop to check if there are duplicate IDs (may consume infinite gas).
        while (_isValidPuppyId(puppyId)) {
            puppyId = _generateId();
        }

        return puppyId;
    }

    /**
     * @dev donate for food.
     * The transaction amount is in (wei).
     */
    function donateForFood(string calldata message, string calldata keyword) external payable {
        _donate(NOT_PUPPY_ID, message, keyword);
    }

    /**
     * @dev donate for a specific puppy.
     * The transaction amount is in (wei).
     *
     * Requirements:
     *
     * - `puppyId` must exist and valid.
     */
    function donateForPuppy(bytes32 puppyId, string calldata message, string calldata keyword) external payable {
        require(_isValidPuppyId(puppyId), "Puppy does not exist.");
        _donate(puppyId, message, keyword);
    }

    /**
     * @dev Create a new Puppy.
     * Only owner can perform this operation.
     *
     * Requirements:
     *
     * - `name` should not be empty.
     * - `birthday` should not be empty, with format of yyyy/mm/dd.
     * - `imageUrl` should not be empty.
     *
     * Emits a {PuppyAdded} event.
     */
    function createNewPuppy(string calldata name, string calldata birthday, string calldata imageUrl, string calldata description) external onlyOwner {
        require(!_strEq(name, EMPTY_STRING));
        require(!_strEq(birthday, EMPTY_STRING));
        require(!_strEq(imageUrl, EMPTY_STRING));

        bytes32 newPuppyId = _generatePuppyId();
        _puppyIdSet.add(newPuppyId);

        puppies.push(Puppy(newPuppyId, name, birthday, imageUrl, description));

        emit PuppyAdded(newPuppyId, name, birthday, imageUrl, description, block.timestamp);
    }

    /**
     * @dev get all puppies.
     */
    function getAllPuppies() external view returns (Puppy[] memory) {
        return puppies;
    }

    /**
     * @dev get all donateTransactions.
     */
    function getAllDonateTransactions() external view returns (DonateTransaction[] memory) {
        return donateTransactions;
    }
}