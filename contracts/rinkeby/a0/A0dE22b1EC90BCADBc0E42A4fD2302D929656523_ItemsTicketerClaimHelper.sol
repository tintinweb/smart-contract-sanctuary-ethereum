// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "../interfaces/IEscrowTicketer.sol";

/**
 * @title ItemsTicketerClaimHelper
 *
 * @notice Helps run batches of claims against the ItemsTicketer in one transaction instead of having to run individual claims
 *
 */
contract ItemsTicketerClaimHelper {

  function claim(uint256[] memory _ticketIds, address _itemsTicketer) external {
    
    // IEscrowTicketer itemsTicketer = IEscrowTicketer(_itemsTicketer);

    for(uint256 i = 0; i < _ticketIds.length; i++) {
      // itemsTicketer.claim(_ticketIds[i]);
      (bool success, bytes memory result) = _itemsTicketer.delegatecall(abi.encodeWithSignature("claim(uint256)", _ticketIds[i]));
      if(!success) {
        revert("Claim unsuccessful");
      }
    }

  }

}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "../domain/SeenTypes.sol";

/**
 * @title IEscrowTicketer
 *
 * @notice Manages the issue and claim of escrow tickets.
 *
 * The ERC-165 identifier for this interface is: 0x73811679
 *
 * @author Cliff Hall <[email protected]com> (https://twitter.com/seaofarrows)
 */
interface IEscrowTicketer {

    event TicketIssued(uint256 ticketId, uint256 indexed consignmentId, address indexed buyer, uint256 amount);
    event TicketClaimed(uint256 ticketId, address indexed claimant, uint256 amount);

    /**
     * @notice The nextTicket getter
     */
    function getNextTicket() external view returns (uint256);

    /**
     * @notice Get info about the ticket
     */
    function getTicket(uint256 _ticketId) external view returns (SeenTypes.EscrowTicket memory);

    /**
     * @notice Get how many claims can be made using tickets (does not change after ticket burns)
     */
    function getTicketClaimableCount(uint256 _consignmentId) external view returns (uint256);

    /**
     * @notice Gets the URI for the ticket metadata
     *
     * This method normalizes how you get the URI,
     * since ERC721 and ERC1155 differ in approach
     *
     * @param _ticketId - the token id of the ticket
     */
    function getTicketURI(uint256 _ticketId) external view returns (string memory);

    /**
     * Issue an escrow ticket to the buyer
     *
     * For physical consignments, Seen.Haus must hold the items in escrow
     * until the buyer(s) claim them.
     *
     * When a buyer wins an auction or makes a purchase in a sale, the market
     * handler contract they interacted with will call this method to issue an
     * escrow ticket, which is an NFT that can be sold, transferred, or claimed.
     *
     * @param _consignmentId - the id of the consignment being sold
     * @param _amount - the amount of the given token to escrow
     * @param _buyer - the buyer of the escrowed item(s) to whom the ticket is issued
     */
    function issueTicket(uint256 _consignmentId, uint256 _amount, address payable _buyer) external;

    /**
     * Claim the holder's escrowed items associated with the ticket.
     *
     * @param _ticketId - the ticket representing the escrowed items
     */
    function claim(uint256 _ticketId) external;

}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

/**
 * @title SeenTypes
 *
 * @notice Enums and structs used by the Seen.Haus contract ecosystem.
 *
 * @author Cliff Hall <[email protected]> (https://twitter.com/seaofarrows)
 */
contract SeenTypes {

    enum Market {
        Primary,
        Secondary
    }

    enum MarketHandler {
        Unhandled,
        Auction,
        Sale
    }

    enum Clock {
        Live,
        Trigger
    }

    enum Audience {
        Open,
        Staker,
        VipStaker
    }

    enum Outcome {
        Pending,
        Closed,
        Canceled
    }

    enum State {
        Pending,
        Running,
        Ended
    }

    enum Ticketer {
        Default,
        Lots,
        Items
    }

    struct Token {
        address payable creator;
        uint16 royaltyPercentage;
        bool isPhysical;
        uint256 id;
        uint256 supply;
        string uri;
    }

    struct Consignment {
        Market market;
        MarketHandler marketHandler;
        address payable seller;
        address tokenAddress;
        uint256 tokenId;
        uint256 supply;
        uint256 id;
        bool multiToken;
        bool released;
        uint256 releasedSupply;
        uint16 customFeePercentageBasisPoints;
        uint256 pendingPayout;
    }

    struct Auction {
        address payable buyer;
        uint256 consignmentId;
        uint256 start;
        uint256 duration;
        uint256 reserve;
        uint256 bid;
        Clock clock;
        State state;
        Outcome outcome;
    }

    struct Sale {
        uint256 consignmentId;
        uint256 start;
        uint256 price;
        uint256 perTxCap;
        State state;
        Outcome outcome;
    }

    struct EscrowTicket {
        uint256 amount;
        uint256 consignmentId;
        uint256 id;
        string itemURI;
    }

}