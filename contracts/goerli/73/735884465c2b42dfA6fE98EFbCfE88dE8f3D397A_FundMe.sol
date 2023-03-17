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

// SPDX-License-Identifier: UNLICENSED
pragma solidity = 0.8.17;



import "@openzeppelin/contracts/utils/Counters.sol";

/**
 * @title FundMe
 * @dev A contract for creating and managing fundraising campaigns.
 */
contract FundMe {

    /**
     * @dev A struct to hold information about each campaign created by a user.
     */
    struct campaignInfo {
        address owner; 
        string title;
        uint amountNeeded;
        uint deadline;
        uint amountRaised;
        address[] contributors;
        uint[] contributions;
        uint camp_id;
    }

    using Counters for Counters.Counter; 
    Counters.Counter private donate_id;


    /**
     * @dev A mapping to store the campaignInfo struct for each campaign.
     */
    mapping(uint => campaignInfo) public Contributions;


    /**
     * @dev A counter to keep track of the number of campaigns created.
     */
    uint public campaignCount = 1;

    /**
     * @dev Creates a new fundraising campaign with the specified title, funding goal and deadline.
     * @param _title The title of the fundraising campaign.
     * @param _amountNeeded The funding goal of the campaign.
     * @param _deadline The deadline for the campaign in days.
     */
    function createCampaign(string memory _title, uint _amountNeeded, uint _deadline) public{
        donate_id.increment();
        uint valz = donate_id.current();
        campaignInfo storage c = Contributions[campaignCount];

        // A time conversion factor in solidity
        uint mydeadline = block.timestamp + (86400 * _deadline);
        uint Checkdeadline = (mydeadline - block.timestamp) / 86400; // this datetime manipulation iz to get the actual number of days in solidity time

        require(mydeadline > block.timestamp, "The deadline should be in the future");

        // Check that the goal and deadline are valid
        require(_amountNeeded > 0); //amount needed muzt be greater than 0


        c.owner = msg.sender;
        c.title = _title;
        c.amountNeeded = _amountNeeded;
        c.deadline = Checkdeadline;
        c.amountRaised = 0;
        c.camp_id = valz;

        campaignCount++;

    }



    /**
     * @dev Contributes funds to a campaign.
     * @param _id The ID of the campaign to contribute to.
     */
    function contribute(uint _id) public payable {
        uint amount = msg.value; 

        campaignInfo storage c = Contributions[_id];

        //make sure the address iz valid & not a zero address
        // require(c.owner != address(0), "Invalid campaign owner address");

        //value entered muzt be greater than 0
        require(msg.value > 0, "no value entered");

        //check if amount needed haz been reached or not.
        require(Contributions[campaignCount].amountRaised <= Contributions[campaignCount].amountNeeded, "Goal already reached");

        c.contributors.push(msg.sender); //populate the contributors array
        c.contributions.push(amount); //populate the contributions array to keep track of amount raised

        (bool success, ) = payable(c.owner).call{value: amount}("");

        if (success) {
            c.amountRaised += amount;
        }
        else{
            revert("Transaction failed"); //make sure to reverse & rollback the changes made
        }
    }


    /**
     * @dev Returns the list of contributors and their contributions for a campaign.
     * @param _id The ID of the campaign to retrieve contributor information for.
     * @return A tuple containing two arrays, one for contributors and one for contributions.
     */
    function getcontributors(uint _id) view public returns (address[] memory, uint[] memory) {
        campaignInfo storage c = Contributions[_id];
        return (c.contributors, c.contributions);
    }


    /**
     * @dev Returns the list of all campaigns created.
     * @return An array containing all campaignInfo structs.
     */
    function getListofCampaigns() public view returns (campaignInfo[] memory) {
        campaignInfo[] memory allContributions = new campaignInfo[](campaignCount);

        for (uint i = 0; i < campaignCount; i++) {
            campaignInfo storage c = Contributions[i];
            allContributions[i] = c;
        }

        return allContributions;
   
    }


    /**
    * @dev Allows the owner of a campaign to withdraw the funds raised by the campaign, provided that the campaign has ended
    * and the amount raised is equal to or greater than the target amount.
    * @param _id The ID of the campaign for which funds are to be withdrawn.
    */
    function withdrawFunds(uint _id) external payable {
        // Retrieve the campaign information from the Contributions mapping using the provided campaign ID.
        campaignInfo storage c = Contributions[_id];

        // Ensure that the caller of the function is the owner of the campaign.
        require(c.owner == msg.sender, "Not owner");


        // Ensure that the campaign has ended.
        require(block.timestamp > c.deadline, "Campaign not ended yet");

        // Ensure that the amount raised is equal to or greater than the target amount.
        require(c.amountRaised >= c.amountNeeded, "Pledged amount less than target");

        // Transfer the raised amount to the owner of the campaign.
        // payable(c.owner).transfer(c.amountRaised);

        (bool success, ) = payable(c.owner).call{value: c.amountRaised}("");
        if(!success){
            revert("Transacton failed");
        }
    }


}