/**
 *Submitted for verification at Etherscan.io on 2022-07-10
*/

// Sources flattened with hardhat v2.9.9 https://hardhat.org

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


// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}


// File contracts/Donation.sol


pragma solidity ^0.8.6;


/// @title Donation simulator
/// @author Milos Covilo
/// @notice You can use this contract for only the most basic campaign donations
/// @dev All function calls are currently implemented without side effects
/// @custom:experimental This is an experimental contract.
contract Donation is Ownable {
    using Counters for Counters.Counter;

    struct HighestDonation {
        address donor;
        uint256 amount;
    }

    enum CampaignStatus {
        NOT_FOUND,
        IN_PROGRESS,
        COMPLETED,
        ARCHIVED
    }

    struct Campaign {
        string name;
        string description;
        uint256 timeGoal;
        uint256 moneyToRaisGoal;
        uint256 balance;
        address campaignManager;
        CampaignStatus status;
    }

    Counters.Counter public campaignIdentifer;
    mapping(uint256 => Campaign) public campaigns;

    Counters.Counter public archivedCampaignIdentifer;
    mapping(uint256 => Campaign) public archivedCampaigns;

    HighestDonation public highestDonation;

    bool internal locked;

    constructor() {}

    event CampaignCreated(address indexed creator, address indexed campaignManager, uint256 campaignId, string name);
    event DonationCreated(address indexed donator, uint256 amount);
    event FundsWithdrawed(address indexed receiver, uint256 amount);
    event CampaignArchived(uint256 campaignId);
    event CampaignTimeGoalReached();

    error EmptyString();
    error InvalidMoneyGoal();
    error InvalidTimeGoal();
    error CampaignCompleted();
    error CampaignInProgress();
    error CampaignNotFound();
    error InsufficientDonation();
    error FundsTransferFail();
    error WithdrawForbidden();


    modifier noReentrant() {
        require(!locked, "No re-entrancy");
        locked = true;
        _;
        locked = false;
    }

    modifier validateString(string calldata value) {
        if (bytes(value).length == 0) revert EmptyString();
        _;
    }

    modifier ableToDonate(uint256 id) {
        Campaign memory campaign = campaigns[id];
        if (campaign.status == CampaignStatus.NOT_FOUND) revert CampaignNotFound();
        if (campaign.status == CampaignStatus.COMPLETED) revert CampaignCompleted();
        _;
    }

    modifier campaignCompleted(uint256 id) {
        Campaign memory campaign = campaigns[id];
        if (campaign.status == CampaignStatus.NOT_FOUND) revert CampaignNotFound();
        if (campaign.status != CampaignStatus.COMPLETED) revert CampaignInProgress();
        _;
    }

    modifier validateDonation() {
        if (msg.value == 0) revert InsufficientDonation();
        _;
    }

    /// @notice Create campaign only by registered owner.
    /// @dev Function has custom modifiers for validating funtion arguments. If all checks are passed CampaignCreated event is emmited
    /// @param name Name of campaign
    /// @param description Description of campaign
    /// @param timeGoal The time goal of campaign
    /// @param moneyToRaisGoal The money goal of campaign
    /// @param campaignManager Wallet address where campign funds should be transfered
    function createCampaign(
        string calldata name, 
        string calldata description, 
        uint timeGoal, 
        uint moneyToRaisGoal, 
        address campaignManager
    ) public onlyOwner validateString(name) validateString(description) {
        if (block.timestamp > timeGoal) revert InvalidTimeGoal();
        if (moneyToRaisGoal == 0) revert InvalidMoneyGoal();

        campaignIdentifer.increment();
        campaigns[campaignIdentifer.current()] = Campaign(name, description, timeGoal, moneyToRaisGoal, 0, campaignManager, CampaignStatus.IN_PROGRESS);

        emit CampaignCreated(msg.sender, campaignManager, campaignIdentifer.current(), name);
    }

    /// @notice Send donation to specific campaign. Only applies on campaings which have IN_PROGRESS status. Donations less or equal to 0 are rejected
    /// @dev Function has custom modifiers for validating funtion arguments. If all checks are passed DonationCreated event is emmited
    /// @dev ableToDonate Modifier for checking if campaign has IN_PROGRESS status or if exist
    /// @param campaignId Used to identify campaign
    function donate(uint256 campaignId) public payable ableToDonate(campaignId) validateDonation {
        Campaign storage campaign = campaigns[campaignId];

        if (timeGoalReached(campaign.timeGoal)) {
            campaign.status = CampaignStatus.COMPLETED;
            
            // Find elegant way to complete campaign when time goal is reached.
            // Because in this case someone need to spend gas so campaign could become completed
            payback(msg.value);
            emit CampaignTimeGoalReached();
        } else {
            uint256 newBalance = campaign.balance + msg.value;
            uint256 donation = msg.value;
            
            if (moneyGoalReached(newBalance, campaign.moneyToRaisGoal)) {
                campaign.status = CampaignStatus.COMPLETED;
                uint256 balanceDiff = newBalance - campaign.moneyToRaisGoal;

                if (balanceDiff > 0) {
                    donation -= balanceDiff;
                    payback(balanceDiff);
                }
            }

            campaign.balance += donation;

            if (donation > highestDonation.amount) {
                highestDonation = HighestDonation(msg.sender, donation);
            }

            emit DonationCreated(msg.sender, msg.value);
        } 
    }

    /// @notice Withdraw funds to campaign manager only if campaign is in COMPLETED status
    /// @dev campaignCompleted Modifier for checking if campaign is COMPLETED
    /// @param campaignId Used to identify campaign
    function withdrawFunds(uint256 campaignId) public noReentrant campaignCompleted(campaignId) {
        Campaign storage campaign = campaigns[campaignId];

        if (campaign.campaignManager != msg.sender) revert WithdrawForbidden();

        campaign.balance = 0;

        (bool success, ) = payable(msg.sender).call{ value: campaign.balance }("");
        if (!success) revert FundsTransferFail();

        emit FundsWithdrawed(campaign.campaignManager, campaign.balance);

        archiveCampaign(campaignId, campaign);
    }

    /// @notice Archive campaign after withdraw. This is not public function
    /// @dev Withdrawed campaings are archived for optimizing campaign search
    /// @param campaignId Used to delete campaign from mapping
    /// @param campaign To be archived
    function archiveCampaign(uint256 campaignId, Campaign storage campaign) private {
        campaign.status = CampaignStatus.ARCHIVED;
        archivedCampaignIdentifer.increment();
        archivedCampaigns[archivedCampaignIdentifer.current()] = campaign;

        delete campaigns[campaignId];

        emit CampaignArchived(archivedCampaignIdentifer.current());
    }

    /// @notice Function used for transfering funds
    /// @param amount Amount of tokens
    function payback(uint amount) private {
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        if (!success) revert FundsTransferFail();
    }


    /// @notice Helper function to check if campaign money goal is reached
    /// @param balance Balance to be compared
    /// @param moneyGoal Campaign money goal
    function moneyGoalReached(uint256 balance, uint256 moneyGoal) private pure returns(bool) {
        return balance >= moneyGoal;
    }

    /// @notice Helper function to check if campaign time goal is reached
    /// @dev timeGoal is compared to block's timestamp
    /// @param timeGoal Campaign time goal
    function timeGoalReached(uint256 timeGoal) private view returns(bool) {
        return block.timestamp >= timeGoal;
    }
}