// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @author thirdweb

import "./interface/IContractMetadata.sol";

/**
 *  @title   Contract Metadata
 *  @notice  Thirdweb's `ContractMetadata` is a contract extension for any base contracts. It lets you set a metadata URI
 *           for you contract.
 *           Additionally, `ContractMetadata` is necessary for NFT contracts that want royalties to get distributed on OpenSea.
 */

abstract contract ContractMetadata is IContractMetadata {
    /// @notice Returns the contract metadata URI.
    string public override contractURI;

    /**
     *  @notice         Lets a contract admin set the URI for contract-level metadata.
     *  @dev            Caller should be authorized to setup contractURI, e.g. contract admin.
     *                  See {_canSetContractURI}.
     *                  Emits {ContractURIUpdated Event}.
     *
     *  @param _uri     keccak256 hash of the role. e.g. keccak256("TRANSFER_ROLE")
     */
    function setContractURI(string memory _uri) external override {
        if (!_canSetContractURI()) {
            revert("Not authorized");
        }

        _setupContractURI(_uri);
    }

    /// @dev Lets a contract admin set the URI for contract-level metadata.
    function _setupContractURI(string memory _uri) internal {
        string memory prevURI = contractURI;
        contractURI = _uri;

        emit ContractURIUpdated(prevURI, _uri);
    }

    /// @dev Returns whether contract metadata can be set in the given execution context.
    function _canSetContractURI() internal view virtual returns (bool);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @author thirdweb

/**
 *  Thirdweb's `ContractMetadata` is a contract extension for any base contracts. It lets you set a metadata URI
 *  for you contract.
 *
 *  Additionally, `ContractMetadata` is necessary for NFT contracts that want royalties to get distributed on OpenSea.
 */

interface IContractMetadata {
    /// @dev Returns the metadata URI of the contract.
    function contractURI() external view returns (string memory);

    /**
     *  @dev Sets contract URI for the storefront-level metadata of the contract.
     *       Only module admin can call this function.
     */
    function setContractURI(string calldata _uri) external;

    /// @dev Emitted when the contract URI is updated.
    event ContractURIUpdated(string prevURI, string newURI);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@thirdweb-dev/contracts/extension/ContractMetadata.sol";

contract Eventer {

    struct Event {

        address owner;
        string location;
        uint256 date;
        string title;
        string description;
        uint256 ageCap;
        uint256 ticketsCap;
        uint256 ticketsSold;
        string image;
        string artists;
        address[] ticketHolders;


    }

    mapping(uint256 => Event) public events;

    uint256 public numberOfEvents = 0;

    function CreateEvent(address owner_, string memory location_, uint256 date_, string memory title_, string memory description_, 
            uint256 ageCap_, uint256 ticketsCap_, string memory image_, string memory artists_) public returns (uint256) 
    {
        Event storage event_ = events[numberOfEvents];

        require(event_.date > block.timestamp, "Maybe try Event For Tommorrow?");
        event_.owner = owner_;
        event_.location = location_;
        event_.date = date_;
        event_.title = title_;
        event_.description = description_;
        event_.ageCap = ageCap_;
        event_.ticketsCap = ticketsCap_;
        event_.image = image_;
        event_.ticketsSold = 0;
        event_.artists = artists_;
        numberOfEvents ++;

        return numberOfEvents-1;
    }

    function BuyTicketToEvent(uint256 id_) public payable 
    {
        uint256 amount = msg.value;

        Event storage event_ = events[id_];

        event_.ticketHolders.push(msg.sender);

        (bool sent,) = payable(event_.owner).call{value: amount}("");

        if(sent)
        {
            event_.ticketsSold = event_.ticketsSold + 1;
        }
    }

    function GetEvents() public view returns(Event[] memory)
    {
        Event[] memory allEvents = new Event[](numberOfEvents);
        
        for(uint i = 0; i < numberOfEvents; i++)
        {
            Event storage e = events[i];
            allEvents[i] = e;
        }

        return allEvents;
    }

    function GetTicketHolders(uint256 id_) view public returns(address[] memory)
    {
        return events[id_].ticketHolders;
    }


}