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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

// import "hardhat/console.sol";

import '@openzeppelin/contracts/access/Ownable.sol';

contract ReBuild3 is Ownable {
  struct Region {
    bool active;
    string name;
  }

  struct Organization {
    bool active;
    address account;
    string name;
    string description;
    string region;
  }

  // Fundraising request information
  struct Campaign {
    bool active;
    address owner;
    string title;
    string description;
    string cid;
    uint256 goal;
    uint256 raised;
    uint donated;
    bool released;
    string region;
    address organization;
  }

  struct Donation {
    uint campaignId;
    address donor;
    uint256 timestamp;
    uint256 amount;
    bool released;
    bool returned;
  }

  uint256 public goalThreshold = 0;

  Region[] regions;
  mapping(string => uint) regionIds;
  uint activeRegionsCount;

  Organization[] organizations;
  mapping(address => uint) organizationIds;

  Campaign[] public campaigns;
  uint public activeCampaigns;

  Donation[] donations;
  mapping(uint => uint[]) donatedTo;
  mapping(address => uint[]) donatedBy;

  // Organization events
  event OrganizationRegistered(address indexed organization);
  event OrganizationDeactivated(address indexed organization);

  // Region events
  event RegionActivated(string indexed name);
  event RegionDeactivated(string indexed name);

  // Campaign events
  event CampaignCreated(uint indexed campaignId, address indexed owner);
  event CampaignActive(uint indexed campaignId);
  event DonationMade(uint indexed campaignId, address indexed donor, uint256 indexed amount);
  event CampaignSuccess(uint indexed campaignId, address indexed receiver, uint256 amount);

  // Activate region
  function activateRegion(string memory _region) public onlyOwner {
    require(!isRegion(_region), 'Region already exists!');
    regions.push(Region(true, _region));
    regionIds[_region] = regions.length;
    activeRegionsCount++;
    emit RegionActivated(_region);
  }

  function activateRegions(string[] memory _regions) public onlyOwner {
    for (uint i = 0; i < _regions.length; i++) {
      activateRegion(_regions[i]);
    }
  }

  // Deactive region
  function deactivateRegion(string memory _name) public onlyOwner {
    require(isRegion(_name), "Region doesn't exist!");
    uint id = regionIds[_name] - 1;
    require(regions[id].active, 'Region is not active already!');
    regions[id].active = false;
    activeRegionsCount--;
    emit RegionDeactivated(_name);
  }

  // Register an organization
  function registerOrganization(
    address _organization,
    string memory _name,
    string memory _description,
    string memory _region
  ) public onlyOwner {
    require(!isOrganization(_organization), 'Organization already exists!');
    require(isRegionActive(_region), 'Region is not active!');
    organizations.push(Organization(true, _organization, _name, _description, _region));
    organizationIds[_organization] = organizations.length;
    emit OrganizationRegistered(_organization);
  }

  // Set organization to active = false;
  function deactivateOrganization(address _organization) public onlyOwner {
    require(isOrganization(_organization), "Organization doesn't exist!");
    uint id = organizationIds[_organization] - 1;
    require(organizations[id].active, 'Organization is not active already!');
    organizations[id].active = false;
    emit OrganizationDeactivated(_organization);
  }

  // Check if an organization exists
  function isOrganization(address _organization) internal view returns (bool) {
    return organizationIds[_organization] != 0;
  }

  // Check if an organization is active
  function isOrganizationActive(address _organization) internal view returns (bool) {
    return
      organizationIds[_organization] != 0 &&
      organizations[organizationIds[_organization] - 1].active;
  }

  // Check if an region exists
  function isRegion(string memory _name) internal view returns (bool) {
    return regionIds[_name] != 0;
  }

  // Check if an region active
  function isRegionActive(string memory _name) internal view returns (bool) {
    return regionIds[_name] != 0 && regions[regionIds[_name] - 1].active;
  }

  // Get all active regions
  function getActiveRegions() public view returns (string[] memory) {
    string[] memory activeRegions = new string[](activeRegionsCount);
    uint count = 0;
    for (uint i = 0; i < regions.length; i++) {
      if (regions[i].active) {
        activeRegions[count] = regions[i].name;
        count++;
      }
    }
    return activeRegions;
  }

  // Get organizations operating in the region
  function getOrganizationsInRegion(
    string memory _region
  ) public view returns (Organization[] memory) {
    require(isRegionActive(_region), 'Region is not active!');
    Organization[] memory orgs = new Organization[](organizations.length);
    uint count = 0;
    for (uint i = 0; i < organizations.length; i++) {
      if (organizations[i].active) {
        orgs[count] = organizations[i];
        count++;
      }
    }
    return orgs;
  }

  // Get all organizations
  function getAllOrganizations() external view returns (Organization[] memory) {
    return organizations;
  }

  function submitCampaign(
    string memory _title,
    string memory _description,
    string memory _cid,
    uint256 _goal,
    string memory _region,
    address _organization
  ) external {
    require(isRegionActive(_region), 'Region is not active!');
    require(isOrganizationActive(_organization), 'Organization is not active!');
    require(_goal <= goalThreshold, "You can't raise more than allowed threshold!");
    require(msg.sender != _organization, "Campaign creator and organization can't be same!");

    // TODO: add check so that region and organization should match available
    campaigns.push(
      Campaign(
        false,
        msg.sender,
        _title,
        _description,
        _cid,
        _goal,
        0,
        0,
        false,
        _region,
        _organization
      )
    );

    emit CampaignCreated(campaigns.length - 1, msg.sender);
  }

  function approveCampaign(uint _campaignId) external {
    require(_campaignId < campaigns.length, "Campaign doesn't exist!");

    require(!campaigns[_campaignId].active, 'Campaign is approved already!');
    require(campaigns[_campaignId].organization == msg.sender, 'Not allowed to approve!');

    campaigns[_campaignId].active = true;
    emit CampaignActive(_campaignId);
  }

  function donate(uint _campaignId) external payable {
    require(_campaignId < campaigns.length, "Campaign doesn't exist!");
    require(
      campaigns[_campaignId].active && !campaigns[_campaignId].released,
      'Campaign is not open for donation!'
    );

    address donor = msg.sender;
    uint256 amount = msg.value;

    donations.push(Donation(_campaignId, donor, block.timestamp, amount, false, false));

    uint donationId = donations.length - 1;

    donatedTo[_campaignId].push(donationId);
    donatedBy[donor].push(donationId);
    campaigns[_campaignId].raised += amount;
    campaigns[_campaignId].donated += 1;

    emit DonationMade(_campaignId, msg.sender, amount);
  }

  function release(uint _campaignId) external {
    require(_campaignId < campaigns.length, "Campaign doesn't exist!");
    require(
      campaigns[_campaignId].active && !campaigns[_campaignId].released,
      'Campaign is not open for donation!'
    );

    require(
      campaigns[_campaignId].raised >= campaigns[_campaignId].goal,
      'The goal amount is not raised!'
    );

    campaigns[_campaignId].released = true;

    for (uint i = 0; i < donatedTo[_campaignId].length; i++) {
      uint donationId = donatedTo[_campaignId][i];
      donations[donationId].released = true;
    }

    (bool sent, ) = payable(campaigns[_campaignId].owner).call{
      value: campaigns[_campaignId].raised
    }('');
    require(sent, 'Failed to release funds!');

    emit CampaignSuccess(_campaignId, campaigns[_campaignId].owner, campaigns[_campaignId].raised);
  }

  function setGoalThreshold(uint256 _threshold) external onlyOwner {
    goalThreshold = _threshold;
  }

  // Get all campaigns
  function getAllCampaigns() external view returns (Campaign[] memory) {
    return campaigns;
  }

  // get donations for campaign
  function getCampaignDonations(uint _campaignId) external view returns (Donation[] memory) {
    require(_campaignId < campaigns.length, "Campaign doesn't exist!");
    Donation[] memory campaignDonations = new Donation[](donatedTo[_campaignId].length);
    for (uint i = 0; i < donatedTo[_campaignId].length; i++) {
      uint donationId = donatedTo[_campaignId][i];
      campaignDonations[i] = donations[donationId];
    }
    return campaignDonations;
  }

  // get donations for address
  function getAddressDonations(address _donor) external view returns (Donation[] memory) {
    Donation[] memory addressDonations = new Donation[](donatedBy[_donor].length);
    for (uint i = 0; i < donatedBy[_donor].length; i++) {
      uint donationId = donatedBy[_donor][i];
      addressDonations[i] = donations[donationId];
    }
    return addressDonations;
  }
}