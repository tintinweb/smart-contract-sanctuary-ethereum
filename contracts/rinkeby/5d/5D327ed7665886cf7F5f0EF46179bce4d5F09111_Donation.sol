//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

interface NftInterface {
    function awardItem(address _address, string memory tokenURI) external returns (uint256);
}

/// @title Contract for making donation campaigns that accept ether
/// @author Nikola Lukic
/// @notice Made as task 1 of the Solidity Bootcamp
/// @dev All function calls are currently implemented without side effects
contract Donation is Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private campaignId;

    struct Campaign {
        string name;
        string description;
        uint256 timeGoal;
        uint256 moneyGoal;
        bool registered;
        bool complete;
    }

    address public nftAddress;
    string private constant NFT_URL =
        "https://gateway.pinata.cloud/ipfs/QmTJwWP2K8PEeFdD5SCNSmoMtcqPRkeqpWjegGnd6fgTPb";
    uint32 private constant DAY_IN_SEC = 86400;

    mapping(uint256 => Campaign) public campaigns;
    mapping(uint256 => uint256) public campaignBalances;
    mapping(address => bool) public _donated;

    event NftAddressUpdated(address _address);
    event NewCampaign(string _title, string _description, uint256 _timeGoal, uint256 _moneyGoal);
    event NewDonation(uint256 _campaignId, uint256 _amount);
    event FundsWithdrawn(uint256 id, uint256 amount);

    error InvalidAddress();
    error NoEmptyStrings();
    error InvalidTimeGoal();
    error InsufficientAmount();
    error CampaignIsInactive();
    error NonExistantCampaign();
    error ActiveCampaign();

    modifier notEmptyString(string calldata _string) {
        if (keccak256(abi.encodePacked(_string)) == keccak256(abi.encodePacked(""))) revert NoEmptyStrings();
        _;
    }

    modifier registered(uint256 id) {
        if (campaigns[id].registered == false) revert NonExistantCampaign();
        _;
    }

    modifier withFunds() {
        if (msg.value <= 0) revert InsufficientAmount();
        _;
    }

    modifier activeCampaign(uint256 id) {
        if (campaigns[id].complete == true) {
            revert CampaignIsInactive();
        } else if (campaigns[id].timeGoal <= block.timestamp) {
            campaigns[id].complete = true;
            revert CampaignIsInactive();
        }
        _;
    }

    /// @notice Creates a new donation campaign
    /// @dev It will set all values for the Campaign struct, and increment the counter for the next campaign
    /// @param _title Title of the campaign
    /// @param _description Description of the campaign
    /// @param _timeGoal The number of days the campaign should last
    /// @param _moneyGoal The amount of money the campaign is trying to raise
    function newCampaign(
        string calldata _title,
        string calldata _description,
        uint256 _timeGoal,
        uint256 _moneyGoal
    ) public onlyOwner notEmptyString(_title) notEmptyString(_description) {
        if (_moneyGoal < 1) revert InsufficientAmount();
        if (_timeGoal < 1) revert InvalidTimeGoal();

        campaigns[campaignId.current()] = Campaign(
            _title,
            _description,
            block.timestamp + _timeGoal * DAY_IN_SEC,
            _moneyGoal,
            true,
            false
        );

        campaignId.increment();

        emit NewCampaign(_title, _description, block.timestamp + _timeGoal * DAY_IN_SEC, _moneyGoal);
    }

    /// @notice Donate money to a campaign
    /// @dev The campaign must exist, and the donator must send at least 1 wei. P
    /// Payee who sent excess eth which caused the campaign to be complete will be sent back the difference.
    /// @param id The id of the campaign to donate eth to
    function donate(uint256 id) public payable registered(id) activeCampaign(id) withFunds {
        Campaign storage campaign = campaigns[id];
        campaignBalances[id] += msg.value;

        if (_donated[msg.sender] == false) {
            _donated[msg.sender] = true;
            NftInterface(nftAddress).awardItem(msg.sender, NFT_URL);
        }

        if (campaignBalances[id] >= campaign.moneyGoal || campaign.timeGoal <= block.timestamp) {
            campaign.complete = true;

            /* Returning difference to payee to sent more ether than necessary to complete the campaign */
            if (campaignBalances[id] > campaign.moneyGoal) {
                uint256 change = campaignBalances[id] - campaign.moneyGoal;
                campaignBalances[id] = campaign.moneyGoal;

                (bool success, ) = payable(msg.sender).call{ value: change }("");
                if (success == false) revert("Unable to transact");
            }
        }
        emit NewDonation(id, msg.value);
    }

    /// @notice Withdraw money from a campaign that is complete
    /// @dev The campaign must have the moneyGoal or timeGoal met in order to withdraw.
    /// @param id The id of the campaign we want to withdraw from
    function withdraw(uint256 id) public onlyOwner registered(id) {
        if (campaigns[id].complete == false) {
            if (campaignBalances[id] >= campaigns[id].moneyGoal || campaigns[id].timeGoal <= block.timestamp) {
                campaigns[id].complete = true;
            } else {
                revert ActiveCampaign();
            }
        }

        uint256 balance = campaignBalances[id];

        campaignBalances[id] = 0;

        (bool sent, ) = owner().call{ value: balance }("");
        if (sent == false) revert("Unable to withdraw funds");
        emit FundsWithdrawn(id, balance);
    }

    function setNftAddress(address _address) external onlyOwner {
        if (_address == address(0)) revert InvalidAddress();
        nftAddress = _address;
        emit NftAddressUpdated(_address);
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