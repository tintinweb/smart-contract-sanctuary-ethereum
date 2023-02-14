// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {AppStorage, Modifiers, Announcement} from "../libraries/LibAppStorage.sol";

/**
 * @title AnnouncementsFacet
 * @author PartyFinance
 * @notice Facet that lets read, create, update and delete announcements.
 */
contract AnnouncementsFacet is Modifiers {
    /**
     * @notice Create a Party announcement
     * @dev Managers are the only allowed to create announcements
     * @param title Title of the announcement
     * @param content Content of the announcement
     * @param url Content URL added to the announcemnt
     * @param img Image uri of the announcement
     */
    function createAnnouncement(
        string memory title,
        string memory content,
        string memory url,
        string memory img
    ) external onlyManager {
        s.announcements.push(
            Announcement(title, content, url, img, block.timestamp, 0)
        );
    }

    /**
     * @notice Gets the Party announcements
     * @return Array of Announcement structs
     */
    function getAnnouncements() external view returns (Announcement[] memory) {
        return s.announcements;
    }

    /**
     * @notice Gets a single Party announcement
     * @param i Index of the announcement
     * @return Announcement struct
     */
    function getAnnouncement(uint256 i)
        external
        view
        returns (Announcement memory)
    {
        return s.announcements[i];
    }

    /**
     * @notice Edit a Party announcement
     * @dev Managers are the only allowed to edit an announcement
     * @param title Title of the announcement
     * @param content Content of the announcement
     * @param url Content URL added to the announcemnt
     * @param img Image uri of the announcement
     * @param i Index of the announcement
     */
    function editAnnouncement(
        string memory title,
        string memory content,
        string memory url,
        string memory img,
        uint256 i
    ) external onlyManager {
        s.announcements[i].title = title;
        s.announcements[i].content = content;
        s.announcements[i].url = url;
        s.announcements[i].img = img;
        s.announcements[i].updated = block.timestamp;
    }

    /**
     * @notice Remove a Party announcement
     * @dev Managers are the only allowed to remove an announcement
     * @param i Index of the announcement
     */
    function removeAnnouncement(uint256 i) external onlyManager {
        s.announcements[i] = s.announcements[s.announcements.length - 1];
        s.announcements.pop();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {LibMeta} from "./LibMeta.sol";

/**
 * @notice A struct containing the Party info tracked in storage.
 * @param name Name of the Party
 * @param bio Description of the Party
 * @param img Image URL of the Party (path to storage without protocol/domain)
 * @param model Model of the Party: "Democracy", "Monarchy", "WeightedDemocracy", "Republic"
 * @param purpose Purpose of the Party: "Trading", "YieldFarming", "LiquidityProviding", "NFT"
 * @param isPublic Visibility of the Party. (Private parties requires an accepted join request)
 * @param minDeposit Minimum deposit allowed in denomination asset
 * @param maxDeposit Maximum deposit allowed in denomination asset
 */
struct PartyInfo {
    string name;
    string bio;
    string img;
    string model;
    string purpose;
    bool isPublic;
    uint256 minDeposit;
    uint256 maxDeposit;
}

/**
 * @notice A struct containing the Announcement info tracked in storage.
 * @param title Title of the Announcement
 * @param bio Content of the Announcement
 * @param img Any external URL to include in the Announcement
 * @param model Model of the Party: "Democracy", "Monarchy", "WeightedDemocracy", "Republic"
 * @param created Block timestamp date of the Announcement creation
 * @param updated Block timestamp date of any Announcement edition
 */
struct Announcement {
    string title;
    string content;
    string url;
    string img;
    uint256 created;
    uint256 updated;
}

/**
 * @notice A struct containing the TokenGate info tracked in storage.
 * @param token Address of the asset
 * @param amount Required amount to hold
 */
struct TokenGate {
    address token;
    uint256 amount;
}

struct AppStorage {
    //
    // Party vault token
    //
    string name;
    string symbol;
    uint256 totalSupply;
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowances;
    //
    // Denomination token asset for deposit/withdraws
    //
    address denominationAsset;
    //
    // Party info
    //
    PartyInfo partyInfo;
    bool closed; // Party life status
    //
    // Party access
    //
    mapping(address => bool) managers; // Maping to get if address is a manager
    mapping(address => bool) members; // Maping to get if address is a member
    //
    // Party ERC-20 holdings
    //
    address[] tokens; // Array of current party tokens holdings
    //
    // Party Announcements
    //
    Announcement[] announcements;
    //
    // Party Join Requests
    //
    address[] joinRequests; // Array of users that requested to join the party
    mapping(address => bool) acceptedRequests; // Mapping of requests accepted by a manager
    //
    // PLATFORM
    //
    uint256 platformFee; // Platform fee (in bps, 50 bps -> 0.5%)
    address platformFeeCollector; // Platform fee collector
    address platformSentinel; // Platform sentinel
    address platformFactory; // Platform factory
    //
    // Extended Party access
    //
    address creator; // Creator of the Party
    //
    // Token gating
    //
    TokenGate[] tokenGates;
}

library LibAppStorage {
    function diamondStorage() internal pure returns (AppStorage storage ds) {
        assembly {
            ds.slot := 0
        }
    }
}

contract Modifiers {
    AppStorage internal s;

    modifier onlyCreator() {
        require(s.creator == LibMeta.msgSender(), "Only Party Creator allowed");
        _;
    }

    modifier onlyManager() {
        require(s.managers[LibMeta.msgSender()], "Only Party Managers allowed");
        _;
    }

    modifier onlyMember() {
        require(s.members[LibMeta.msgSender()], "Only Party Members allowed");
        _;
    }

    modifier notMember() {
        require(
            !s.members[LibMeta.msgSender()],
            "Only non Party Members allowed"
        );
        _;
    }

    modifier onlyFactory() {
        require(
            LibMeta.msgSender() == s.platformFactory,
            "Only Factory allowed"
        );
        _;
    }

    modifier isAlive() {
        require(!s.closed, "Party is closed");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library LibMeta {
    function getChainID() internal view returns (uint256 id) {
        assembly {
            id := chainid()
        }
    }

    function msgSender() internal view returns (address sender_) {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender_ := and(
                    mload(add(array, index)),
                    0xffffffffffffffffffffffffffffffffffffffff
                )
            }
        } else {
            sender_ = msg.sender;
        }
    }
}