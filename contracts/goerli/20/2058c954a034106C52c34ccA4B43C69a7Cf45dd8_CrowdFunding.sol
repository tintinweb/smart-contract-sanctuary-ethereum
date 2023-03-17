// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @author thirdweb

import "./interface/IPrimarySale.sol";

/**
 *  @title   Primary Sale
 *  @notice  Thirdweb's `PrimarySale` is a contract extension to be used with any base contract. It exposes functions for setting and reading
 *           the recipient of primary sales, and lets the inheriting contract perform conditional logic that uses information about
 *           primary sales, if desired.
 */

abstract contract PrimarySale is IPrimarySale {
    /// @dev The address that receives all primary sales value.
    address private recipient;

    /// @dev Returns primary sale recipient address.
    function primarySaleRecipient() public view override returns (address) {
        return recipient;
    }

    /**
     *  @notice         Updates primary sale recipient.
     *  @dev            Caller should be authorized to set primary sales info.
     *                  See {_canSetPrimarySaleRecipient}.
     *                  Emits {PrimarySaleRecipientUpdated Event}; See {_setupPrimarySaleRecipient}.
     *
     *  @param _saleRecipient   Address to be set as new recipient of primary sales.
     */
    function setPrimarySaleRecipient(address _saleRecipient) external override {
        if (!_canSetPrimarySaleRecipient()) {
            revert("Not authorized");
        }
        _setupPrimarySaleRecipient(_saleRecipient);
    }

    /// @dev Lets a contract admin set the recipient for all primary sales.
    function _setupPrimarySaleRecipient(address _saleRecipient) internal {
        recipient = _saleRecipient;
        emit PrimarySaleRecipientUpdated(_saleRecipient);
    }

    /// @dev Returns whether primary sale recipient can be set in the given execution context.
    function _canSetPrimarySaleRecipient() internal view virtual returns (bool);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @author thirdweb

/**
 *  Thirdweb's `Primary` is a contract extension to be used with any base contract. It exposes functions for setting and reading
 *  the recipient of primary sales, and lets the inheriting contract perform conditional logic that uses information about
 *  primary sales, if desired.
 */

interface IPrimarySale {
    /// @dev The adress that receives all primary sales value.
    function primarySaleRecipient() external view returns (address);

    /// @dev Lets a module admin set the default recipient of all primary sales.
    function setPrimarySaleRecipient(address _saleRecipient) external;

    /// @dev Emitted when a new sale recipient is set.
    event PrimarySaleRecipientUpdated(address indexed recipient);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@thirdweb-dev/contracts/extension/PrimarySale.sol";


contract CrowdFunding {

    struct Campaign {
        address owner ;
        string title;
        string description;
        uint256 target;
        uint256 deadline;
        uint256 amountCollected;
        string image;
        address[] donators;
        uint256[] donations;
    }
    mapping(uint256 => Campaign) public campaigns;
    uint256 public numberOfCampaigns = 0;

    function createCampaign(address _owner, string memory _title, string memory _description, uint256 _target, uint256 _deadline , string memory _image) public returns(uint256)
     {
        Campaign storage campaign = campaigns[numberOfCampaigns];

        require(campaign.deadline< block.timestamp, "the deadline should be a date in the future");
          campaign.owner = _owner;
          campaign.title = _title;
          campaign.description = _description;
          campaign.target = _target;
          campaign.deadline =_deadline;
          campaign.amountCollected= 0;
          campaign.image = _image;

          numberOfCampaigns++;
          return numberOfCampaigns -1;
  
    }

    function donateToCampaign(uint256 _id)public payable {
        uint256 amount = msg.value;

        Campaign storage campaign = campaigns[_id]; 
        campaign.donators.push(msg.sender);
        campaign.donations.push(amount);

        (bool sent,)= payable(campaign.owner).call{value:amount}("");
         
         if(sent){
             campaign.amountCollected = campaign.amountCollected + amount;
         }
    }

    function getDonators(uint256 _id)view public returns(address[] memory,uint256[] memory)
        {
            return(campaigns[_id].donators,campaigns[_id].donations);
        }

    function getCampaigns() public view returns(Campaign[] memory) {
        Campaign[] memory allCampaigns = new Campaign[](numberOfCampaigns);
    
    for(uint i =0; i< numberOfCampaigns; i++)
    {
        Campaign storage item = campaigns[i];
        allCampaigns[i]=item;
    }

    return allCampaigns;
    }
}