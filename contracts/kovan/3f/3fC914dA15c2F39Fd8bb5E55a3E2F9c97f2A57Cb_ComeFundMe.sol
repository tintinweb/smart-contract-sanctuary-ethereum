//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract ComeFundMe is Ownable, Pausable {
    struct Campaign {
        bool isAlive; // is campaign active or not
        address initiator; // whoever starts the campaign
        uint256 fundsRaised; // how much eth has been raised
        string title; // display on a webpage
        string description; // description on a webpage
    }
    mapping(bytes32 => Campaign) private _campaigns; // unique campaign ID for each campaign

    event CampaignStarted(bytes32 campaignId); // emitted when a campaign is started
    event CampaignEnded(bytes32 campaignId, uint256 fundsRaised); // emmitted when ended
    event CampaignDonationReceived(
        // when someone donates
        bytes32 campaignId,
        address donor,
        uint256 amount
    );

    /**
        @notice Toggles the pause status using ternary operators
        @dev If paused() is true, then we unpause. Else, pause.
     */
    function togglePause() external onlyOwner {
        paused() ? _unpause() : _pause(); // value of paused is evaluated- allows owner to pause and unpause
    }

    /**
        @notice Starts a fundraising campaign
        @param title The title of this new campaign (to be displayed on a website, for example)
        @param description The description of this new campaign (to be displayed on a website, for example)
     */
    function startCampaign(string calldata title, string calldata description)
        external
        whenNotPaused
    {
        bytes32 campaignId = getCampaignId(_msgSender(), title, description); // calling campaign ID, hashing initiator, title, and description
        Campaign storage c = _campaigns[campaignId]; // struct type, c is variable name pulling from mapping- grabbing corresponding campaign from storage
        require(!c.isAlive && c.initiator == address(0), "Campaign exists"); // checking if initiators address is 0
        c.isAlive = true;
        c.initiator = _msgSender(); // via OpenZeppelin
        c.title = title;
        c.description = description; // not setting fundsraised will be 0
        emit CampaignStarted(campaignId);
    }

    /**
        @notice Ends a fundraising campaign, all raised funds transferred to the initiator
        @dev Can only be called by the campaign initiator
        @param campaignId The ID of the campaign that we are trying to end
     */
    function endCampaign(bytes32 campaignId) external whenNotPaused {
        Campaign storage c = _campaigns[campaignId];
        require(c.initiator == _msgSender(), "Not campaign owner"); // initiator is sender of this message
        require(c.isAlive, "Already ended"); // make sure campaign is alive
        c.isAlive = false; // will end campaign
        payable(c.initiator).transfer(c.fundsRaised); // transfer funds raised to the initiator
        emit CampaignEnded(campaignId, c.fundsRaised);
    }

    /**
        @notice Donates ETH to a certain campaign
        @param campaignId The ID of the campaign that we are trying to donate to
     */
    function donateToCampaign(
        bytes32 campaignId // referencing campaign with campaignID // payable bc you are donating to the function
    ) external payable whenNotPaused {
        Campaign storage c = _campaigns[campaignId]; // pull campaign struct out of the mapping
        require(c.isAlive, "Already ended"); // same check as above, is campaign alive
        c.fundsRaised += msg.value; // adding however much user has sent over to the balance
        emit CampaignDonationReceived(campaignId, _msgSender(), msg.value);
    }

    /**
        @notice Returns information for a specific campaign
        @param campaignId The ID of the campaign that we are trying to query
        @return A struct containing information about the given campaign
     */
    function getCampaign(
        bytes32 campaignId // only reads from blockchain
    ) external view returns (Campaign memory) {
        return _campaigns[campaignId]; // returns campaign struct
    }

    /**
        @notice Generates a campaign ID given identifying information
        @param initiator The initiator of the campaign
        @param title The title of the campaign
        @param description The description of the campaign
        @return The generated campaign ID
     */
    function getCampaignId(
        address initiator,
        string calldata title,
        string calldata description
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(initiator, title, description));
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
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