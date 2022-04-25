// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import "hardhat/console.sol";
import "./DonationManager.sol";
import "./Factory.sol";

contract DonationManagerGenerator is Factory {
    constructor() {}

    /*---------------------------- PUBLIC ----------------------------*/
    /// @dev Allows verified creation of DonationContract.
    /// @param _owners List of initial owners.
    /// @return Returns donationContractAddress the address of the new contract
    function create(address[] memory _owners) public returns (address) {
        address donationContractAddress = address(new DonationManager(_owners));
        register(donationContractAddress);

        return donationContractAddress;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import "hardhat/console.sol";
import "./DonationInstance.sol";

contract DonationManager {
    /*----------------------------- EVENTS -----------------------------*/
    event DonationCreated(
        address contractAddress,
        address payable donor,
        address payable[] recipients,
        uint256 totalAmount
    );
    event DonationReleased(
        address contractAddress,
        address payable donor,
        address payable recipient,
        uint256 totalAmount
    );
    event DonationRefunded(
        address contractAddress,
        address payable donor,
        uint256 totalAmount
    );

    /*--------------------------- CONSTANTS ---------------------------*/
    uint256 public constant MAX_OWNER_COUNT = 3;

    /*---------------------------- STORAGE ----------------------------*/
    mapping(address => bool) public isOwner;
    address[] public owners;

    mapping(address => bool) public isDonationInstance;
    mapping(address => DonorStorage) donorLookupTable;
    mapping(address => RecipientStorage) recipientLookupTable;

    struct DonorStorage {
        address[] allDonations;
    }

    struct RecipientStorage {
        address[] allDonations;
    }

    constructor(address[] memory _owners) validOwners(_owners.length) {
        for (uint256 i = 0; i < _owners.length; i++) {
            require(
                !isOwner[_owners[i]],
                "You cannot name owner multiple times"
            );
            isOwner[_owners[i]] = true;
        }

        owners = _owners;
    }

    /*---------------------------- CREATING ----------------------------*/
    function createDonation(address payable[] calldata _recipientAddresses)
        external
        payable
        isDonationCreatable(_recipientAddresses)
    {
        // Create donation and pass payment value to be held in the new contract
        DonationInstance newDonationInstance = new DonationInstance{
            value: msg.value
        }(payable(msg.sender), _recipientAddresses);
        address newDonationContractAddress = address(newDonationInstance);

        // Update state
        isDonationInstance[newDonationContractAddress] = true;

        addDonationForDonor(msg.sender, newDonationContractAddress);
        for (uint256 i = 0; i < _recipientAddresses.length; i++) {
            addDonationForRecipient(
                _recipientAddresses[i],
                newDonationContractAddress
            );
        }
    }

    /*---------------------------- QUERYING -----------------------------*/
    function getAllDonationsForDonor(address _donorAddress)
        external
        view
        returns (address[] memory)
    {
        return donorLookupTable[_donorAddress].allDonations;
    }

    function getAllDonationsForRecipient(address _recipientAddress)
        external
        view
        returns (address[] memory)
    {
        return recipientLookupTable[_recipientAddress].allDonations;
    }

    /*--------------------------- VALIDATION ----------------------------*/
    modifier isDonationCreatable(address payable[] memory _recipientAddresses) {
        require(
            msg.value / _recipientAddresses.length > 0,
            "Amount is not sufficient enough to credit each recipient."
        );

        _;
    }

    modifier validOwners(uint256 ownerCount) {
        require(ownerCount <= MAX_OWNER_COUNT && ownerCount != 0);
        _;
    }

    /*----------------------------- UTILITY ----------------------------*/
    function addDonationForDonor(
        address _donorAddress,
        address donationInstanceAddress
    ) internal {
        donorLookupTable[_donorAddress].allDonations.push(
            donationInstanceAddress
        );
    }

    function addDonationForRecipient(
        address _recipientAddress,
        address donationInstanceAddress
    ) internal {
        recipientLookupTable[_recipientAddress].allDonations.push(
            donationInstanceAddress
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Factory {
    /*---------------------------- EVENTS ----------------------------*/
    event ContractInstantiation(address sender, address instantiation);

    /*---------------------------- STORAGE ---------------------------*/
    mapping(address => bool) public isInstantiation;
    mapping(address => address[]) public instantiations;

    /*---------------------------- PUBLIC ----------------------------*/
    /// @dev Returns number of instantiations by creator.
    /// @param creator Contract creator.
    /// @return Returns number of instantiations by creator.
    function getInstantiationCount(address creator)
        public
        view
        returns (uint256)
    {
        return instantiations[creator].length;
    }

    /*---------------------------- INTERNAL --------------------------*/
    /// @dev Registers contract in factory registry.
    /// @param instantiation Address of contract instantiation.
    function register(address instantiation) internal {
        isInstantiation[instantiation] = true;
        instantiations[msg.sender].push(instantiation);
        emit ContractInstantiation(msg.sender, instantiation);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import "hardhat/console.sol";

contract DonationInstance {
    /*----------------------------- EVENTS -----------------------------*/
    event DonationCreated(
        address contractAddress,
        address payable donor,
        address payable[] recipients,
        uint256 totalAmount
    );
    event DonationReleased(
        address contractAddress,
        address payable donor,
        address payable recipient,
        uint256 totalAmount
    );
    event DonationRefunded(
        address contractAddress,
        address payable donor,
        uint256 totalAmount
    );

    /*---------------------------- STORAGE ----------------------------*/
    address public managerAddress;

    string public donationNickname;
    address payable public donorAddress;
    address payable[] public recipientAddresses;

    uint256 public donationTotal;
    uint256 public numberClaimed;
    uint256 public amountClaimed;
    uint256 public amountRefundable;
    uint256 public amountRefunded;
    uint256 public amountOverflowReturned;

    bool public isActive;
    bool public isRefunded;
    bool public isDonation;

    struct DonationRecipient {
        address payable recipientAddress;
        uint256 amount;
        bool isClaimed;
        bool isRecipient;
    }

    mapping(address => DonationRecipient) recipientMapping;

    /*----------------- CONSTRUCTOR (Creating Donation) ------------------*/
    constructor(
        address payable _donorAddress,
        address payable[] memory _recipientAddresses
    ) payable {
        // Stored data in contract
        managerAddress = msg.sender;
        donorAddress = _donorAddress;
        amountOverflowReturned = msg.value % _recipientAddresses.length;
        donationTotal = msg.value - amountOverflowReturned;
        amountClaimed = 0;
        amountRefundable = msg.value - amountOverflowReturned;
        amountRefunded = 0;
        recipientAddresses = _recipientAddresses;
        isActive = true;
        isRefunded = false;
        isDonation = true;

        // Creates DonationRecipient object to persist in storage for each recipient
        uint256 sharePerRecipient = msg.value / _recipientAddresses.length;
        for (uint256 i = 0; i < _recipientAddresses.length; i++) {
            DonationRecipient memory newDonationRecipient = DonationRecipient({
                recipientAddress: _recipientAddresses[i],
                amount: sharePerRecipient,
                isClaimed: false,
                isRecipient: true
            });

            require(
                recipientMapping[_recipientAddresses[i]].isRecipient != true,
                "Cannot name recipient multiple times for one donation."
            );
            recipientMapping[_recipientAddresses[i]] = newDonationRecipient;
        }

        // Return the remainder back to the donor
        payable(donorAddress).transfer(amountOverflowReturned);

        // Emit event confirming the donation was created
        emit DonationCreated(
            address(this),
            payable(msg.sender),
            _recipientAddresses,
            donationTotal
        );
    }

    /*---------------------------- CLAIMING ----------------------------*/
    function claimDonation() external isDonationClaimable {
        DonationRecipient memory donationRecipient = getRecipientDetails(
            msg.sender
        );

        // Transfer donation
        donationRecipient.recipientAddress.transfer(donationRecipient.amount);

        // Change stored data to reflect the change
        amountClaimed += donationRecipient.amount;
        amountRefundable -= donationRecipient.amount;
        recipientMapping[msg.sender].isClaimed = true;
        numberClaimed += 1;

        if (numberClaimed == recipientAddresses.length) {
            isActive = false;
        }

        emit DonationReleased(
            address(this),
            donorAddress,
            payable(msg.sender),
            donationRecipient.amount
        );
    }

    /*---------------------------- REFUNDING ----------------------------*/
    function refundDonation() external isDonationRefundable {
        // Transfer refund
        donorAddress.transfer(amountRefundable);

        // Change stored data to reflect the change
        amountRefunded = amountRefundable;
        amountRefundable = 0;
        isRefunded = true;
        isActive = false;

        emit DonationRefunded(
            address(this),
            payable(msg.sender),
            amountRefunded
        );
    }

    /*---------------------------- QUERYING ----------------------------*/
    function balanceOfContract() external view returns (uint256) {
        return address(this).balance;
    }

    function getRecipientDetails(address _recipientAddress)
        public
        view
        returns (DonationRecipient memory)
    {
        require(
            recipientMapping[_recipientAddress].isRecipient == true,
            "Requestor is not a listed recipient for this donation."
        );
        return recipientMapping[_recipientAddress];
    }

    modifier isDonationRefundable() {
        require(amountRefundable > 0, "There are no funds left to refund.");
        require(isActive, "Donation no longer active.");
        require(
            donorAddress == msg.sender,
            "You are not the authorized donor for this donation."
        );
        _;
    }

    modifier isDonationClaimable() {
        DonationRecipient memory donationRecipient = getRecipientDetails(
            msg.sender
        );

        require(isRefunded == false, "You cannot claim a refunded donation.");
        require(
            donationRecipient.isRecipient == true,
            "You are not an authorized recipient for this donation."
        );
        require(
            donationRecipient.isClaimed == false,
            "You have already claimed this donation."
        );
        require(isActive, "You cannot claim an inactive donation.");

        _;
    }

    modifier isDonationActive() {
        require(isActive, "Donation is not active");
        _;
    }

    function getRecipients() public view returns (address payable[] memory) {
        return recipientAddresses;
    }
}