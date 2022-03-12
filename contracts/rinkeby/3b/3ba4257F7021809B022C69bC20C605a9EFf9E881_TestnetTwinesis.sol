//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "../Twinesis.sol";

contract TestnetTwinesis is Twinesis {
    address private recipient = 0x8fE5EFB29F4D4F48dFDA2D72454152587b59A95F;

    constructor(
        string memory unrevealedBaseURI_,
        address withdrawalAddress1_,
        address withdrawalAddress2_
    ) Twinesis(unrevealedBaseURI_, withdrawalAddress1_, withdrawalAddress2_) {
        _mintPreviously(3, 1 days); // collector
        _mintPreviously(12, 59.8 days); // collector, almost believer
        _mintPreviously(20, 80 days); // believer
        _mintPreviously(25, 119.8 days); // believer, almost supporter
        _mintPreviously(30, 140 days); // supporter
        _mintPreviously(35, 179.8 days); // supporter, almost fan
        _mintPreviously(42, 200 days); // fan
    }

    function _mintPreviously(uint256 tokenId, uint256 timeBefore) private {
        _safeMint(recipient, tokenId);
        outsetDate[tokenId] = block.timestamp - timeBefore;
    }

    function name() public pure override returns (string memory) {
        return "Testnet Twinesis";
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./Description.sol";
import "./Types.sol";
import "./ITwinesis.sol";

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

/**
 *
 *              Collection details in Description.sol
 *
 *
 *          --------------               -----------------
 *          |   ARTIST   |               |   DEVELOPER   |
 *          --------------               -----------------
 *          twinnytwin.eth             nicoacosta.eth
 *          @djtwinnytwin              @0xnico_
 *          twinnytwin.io              github.com/NicoAcosta
 *          twinnytwin.com             linktr.ee/nicoacosta.eth
 *
 *
 *
 *                          -------------
 *                          |   INDEX   |
 *                          -------------                     line
 *
 *      TWINESIS Contract .................................... 86
 *
 *          1.  Libraries .................................... 88
 *
 *          2.  Events ....................................... 97
 *
 *          3.  State variables .............................. 107
 *
 *          4.  Constructor .................................. 165
 *
 *          5.  Access Control ............................... 210
 *
 *                  A.  Withdrawal ........................... 227
 *
 *          6.  Minting ...................................... 243
 *
 *                  A.  Public minting ....................... 288
 *
 *                  B.  Internal minting ..................... 319
 *
 *          7.  Metadata ..................................... 353
 *
 *                  A.  Revealable metadata .................. 358
 *
 *                  B.  Contract URI ......................... 390
 *
 *                  C.  Token URI ............................ 401
 *
 *                          1.  Rarities ..................... 436
 *
 *                          2.  Levels ....................... 456
 *
 *                                  A.  Outset date .......... 475
 *
 *                          3.  Journey percentage ........... 518
 *
 *          8.  Interfaces ................................... 536
 *
 *
 */

/**
 *  @title Twinesis
 *  @author Nicolás Acosta (nicoacosta.eth) @0xnico_
 *          linktr.ee/nicoacosta.eth
 *  @notice NFT ERC721.
 *          3 rarities.
 *          4 levels (based on time since minting or transfer)
 *              If a token is transferd before final level, level is resetted to 0.
 *              Once token reaches final level, it does not reset when transfered.
 *          Journey percentage
 *          Goodlist pre sale
 *          Public minting
 *  @dev Inherits from @openzeppelin/contracts ERC721 and AccessControl
 *       Uses enums Rarity and Level (Types.sol)
 */
contract Twinesis is ERC721, AccessControl {
    /// ---------------
    /// 1. Libraries
    /// ---------------

    using Strings for uint256;

    using TwinesisStrings for Rarity;
    using TwinesisStrings for Level;

    /// ------------
    /// 2. Events
    /// ------------

    /// @notice New outset date for a token
    /// @dev Emitted when `outsetDate` is setted or resetted
    /// @param tokenId Token id
    /// @param date New outset date
    event NewOutsetDate(uint256 indexed tokenId, uint256 date);

    /// ---------------------
    /// 3. State variables
    /// ---------------------

    /// @notice Access control role codes
    /// @dev Check '@openzeppelin/contracts/access/AccessControl.sol'
    bytes32 private constant CREATOR_ROLE = keccak256("CREATOR_ROLE");
    bytes32 private constant WITHDRAWAL_ROLE = keccak256("WITHDRAWAL_ROLE");
    bytes32 public constant PRE_SALE_GOODLIST_ROLE =
        keccak256("PRE_SALE_GOODLIST_ROLE");

    /// @notice Artist address
    /// @dev Used to add addresses to pre sale goodlist
    address private constant ARTIST =
        0x567B5E79cE0d465a0FF1e1eeeFE65d180b4C5D41; // twinnytwin.eth

    /// @notice Developer address
    /// @dev Used to add addresses to pre sale goodlist
    address private constant DEV = 0xab468Aec9bB4b9bc59b2B2A5ce7F0B299293991f; // nicoacosta.eth

    /// @notice Addresses for ETH withdrawal
    address private immutable _withdrawalAddress1;
    address private immutable _withdrawalAddress2;

    /// @notice Maximum amount of tokens that can be minted
    /// @dev Required not to be to exceeded in minting public functions
    /// @return MAX_TOKENS Maximum amount of tokens that can be minted
    uint256 public constant MAX_TOKENS = 222;

    /// @notice Minting price per token
    /// @dev Required to match msg.value in minting public functions
    /// @return MINTING_PRICE Minting price per token in ETH
    uint256 public constant MINTING_PRICE = 0.06 ether;

    /// @notice Public minting start date
    /// @dev Used in public minting functions
    /// @return PUBLIC_MINTING_START_DATE Public minting start date
    uint256 public constant PUBLIC_MINTING_START_DATE = 1647298800; // 2022-03-14 20:00:00

    /// @notice Date from which the contract starts to count to calculate its level.
    /// @dev Used to calculate a token's level. When it was minted or transfered if it was not at maximum level
    /// @return outsetDate Token's outset id
    mapping(uint256 => uint256) public outsetDate;

    /// @notice Amount of tokens already minted
    /// @return mintedTokens Amount of tokens already minted
    uint256 public mintedTokens;

    /// @notice Id of the last minted token
    uint256 private _lastId;

    /// @notice Unreaveled rarities base metadata IPFS URI
    /// @dev Initialized at deployment
    string private _unrevealedRaritiesBaseURI;

    /// @notice Revealed rarities base metadata IPFS URI. Only can be set once.
    string private _revealedRaritiesBaseURI;

    /// -----------------
    /// 4. Constructor
    /// -----------------

    /// @notice run at deployment
    constructor(
        string memory unrevealedBaseURI_,
        address withdrawalAddress1_,
        address withdrawalAddress2_
    ) ERC721("Twinesis", "TWN1") {
        // Set unreaveled base metadata IPFS URI
        _unrevealedRaritiesBaseURI = unrevealedBaseURI_;

        // Set withdrawal addresses
        _withdrawalAddress1 = withdrawalAddress1_;
        _withdrawalAddress2 = withdrawalAddress2_;

        // Set creator role for artist, dev and deployer address. Enables pre sale list goodlist control
        _grantRole(CREATOR_ROLE, ARTIST);
        _grantRole(CREATOR_ROLE, DEV);
        _grantRole(CREATOR_ROLE, msg.sender);

        // Set withdrawal role. Enables to call `withdraw()` public function
        _grantRole(WITHDRAWAL_ROLE, withdrawalAddress1_);
        _grantRole(WITHDRAWAL_ROLE, withdrawalAddress2_);

        // Set creator role as goodlist's admin role
        _setRoleAdmin(PRE_SALE_GOODLIST_ROLE, CREATOR_ROLE);

        // Mint tokens to artist and dev
        _safeMint(ARTIST, 1);
        _safeMint(ARTIST, 5);
        _safeMint(DEV, 8);
        _safeMint(DEV, 10);
        _safeMint(ARTIST, 100);
        _safeMint(ARTIST, 202);

        // Set minted tokens to 6
        mintedTokens = 6;

        // Set last id to #1. First minting call will mint #2
        _lastId = 1;
    }

    /// --------------------
    /// --------------------
    /// 5. Access Control
    /// --------------------
    /// --------------------

    /// @notice Grant multiple addresses the same role
    /// @param role Role to be granted
    /// @param accounts Accounts to be authorized
    function grantRoleMultiple(bytes32 role, address[] memory accounts)
        public
        onlyRole(getRoleAdmin(role))
    {
        for (uint256 i = 0; i < accounts.length; i++) {
            _grantRole(role, accounts[i]);
        }
    }

    /// --------------------
    /// 5.A. Withdrawal
    /// --------------------

    /// @notice Withdraw contract's balance to withdrawal addresses
    function withdraw() external onlyRole(WITHDRAWAL_ROLE) {
        uint256 _balance = address(this).balance;
        require(_balance > 0, "No balance to transfer");

        uint256 _amount1 = (_balance * 150) / 1296;

        payable(_withdrawalAddress1).transfer(_amount1);
        payable(_withdrawalAddress2).transfer(_balance - _amount1);
    }

    /// -------------
    /// -------------
    /// 6. Minting
    /// -------------
    /// -------------

    /// @notice Checks if token has been minted.
    /// @dev Returns ERC721's internal `_exists`
    /// @param tokenId Token id
    /// @return Bool: whether the token has been minted or not
    function exists(uint256 tokenId) external view returns (bool) {
        return _exists(tokenId);
    }

    /// @notice Returns the amount of tokens that can be minted.
    /// @dev Maximum amount of tokens that can be minted minus the amount of already minted tokens.
    /// @return Tokens Tokens left to mint
    function tokensToMint() external view returns (uint256) {
        return MAX_TOKENS - mintedTokens;
    }

    /// @notice Verifies that one token can be minted.
    /// @dev Verifies that ETH received matches minting price and that the maximum amount of tokens has not been reached.
    modifier canMintOne() {
        // ETH received must match minting price
        require(msg.value == MINTING_PRICE, "Invalid ETH amount");
        // The maximum amount of tokens must not have been reached
        require(mintedTokens < MAX_TOKENS, "Max tokens already minted");
        _;
    }

    /// @notice Verifies that a certain amount of tokens can be minted.
    /// @dev Verifies that amount is greater than 1, that ETH received matches minting price and that the maximum amount of tokens would not be exceeded.
    modifier canMint(uint256 amount) {
        // This function must be called for minting more than one token.
        require(amount > 1, "Call this function to mint multiple tokens");
        // ETH received must match minting price
        require(msg.value == MINTING_PRICE * amount, "Invalid ETH amount");
        // The maximum amount of tokens must not be exceeded
        require(
            mintedTokens + amount <= MAX_TOKENS,
            "Max tokens already minted"
        );
        _;
    }

    /// ------------------------
    /// 6.A. Public minting
    /// ------------------------

    /// @notice Verifies that public minting has started
    modifier publicMintingStarted() {
        require(
            block.timestamp > PUBLIC_MINTING_START_DATE,
            "Public minting has not started yet"
        );
        _;
    }

    /// @notice Mint one token (public minting)
    /// @dev Verifies public minting start date, max tokens and ETH received. Mints next id available.
    function mintTwin() external payable publicMintingStarted canMintOne {
        _mintOneToken();
    }

    /// @notice Mint several tokens (public minting)
    /// @dev Verifies public minting start date, max tokens and ETH received. Mints next ids available.
    /// @param amount The number of tokens to mint
    function mintTwins(uint256 amount)
        external
        payable
        publicMintingStarted
        canMint(amount)
    {
        _mintSeveralTokens(amount);
    }

    /// --------------------------
    /// 6.B. Internal minting
    /// --------------------------

    /// @notice Mints next id avilable
    function _mintOneToken() private {
        uint256 _id = _lastId + 1;
        if (_exists(_id)) _id++;

        _safeMint(msg.sender, _id);

        // Update _lastId and mintedTokens
        _lastId = _id;
        mintedTokens++;
    }

    /// @notice Mints next ids available
    /// @param _amount Amount of tokens to mint
    function _mintSeveralTokens(uint256 _amount) private {
        uint256 _id = _lastId;

        for (uint256 _i = 0; _i < _amount; _i++) {
            _id++;
            if (_exists(_id)) _id++;

            _safeMint(msg.sender, _id);
        }

        // Update _lastId and mintedTokens
        _lastId = _id;
        mintedTokens += _amount;
    }

    /// --------------
    /// --------------
    /// 7. Metadata
    /// --------------
    /// --------------

    /// -----------------------------
    /// 7.A. Revealable metadata
    /// -----------------------------

    /// @notice Returns metadata base URI depending on whether rarities have been revealed
    /// @return baseURI Base URI
    function _metadataBaseURI() private view returns (string memory) {
        if (raritiesHaveBeenRevealed()) {
            return _revealedRaritiesBaseURI;
        }
        return _unrevealedRaritiesBaseURI;
    }

    /// @notice Verifies if rarities have been revealed
    /// @dev If rarities have been revealed, `_revealedRaritiesBaseURI` length would be greater than 0, as it is empty by default.
    /// @return bool whether rarities have been revealed
    function raritiesHaveBeenRevealed() public view returns (bool) {
        return bytes(_revealedRaritiesBaseURI).length > 0;
    }

    /// @notice Reveal rarities metadata. Contract and token metadata will be based on this new IPFS URI. It can only be run once.
    /// @param revealedRaritiesBaseURI_ New base URI to be set
    function revealRarities(string memory revealedRaritiesBaseURI_)
        public
        onlyRole(CREATOR_ROLE)
    {
        // Can only be run once
        require(!raritiesHaveBeenRevealed(), "Metadata already revealed");

        _revealedRaritiesBaseURI = revealedRaritiesBaseURI_;
    }

    /// ----------------------
    /// 7.B. Contract URI
    /// ----------------------

    /// @notice Collection metadata URL
    /// @dev Collection IPFS URI link
    /// @return contractURI collection metadata link
    function contractURI() public view returns (string memory) {
        return string(abi.encodePacked(_metadataBaseURI(), "collection.json"));
    }

    /// -------------------
    /// 7.C. Token URI
    /// -------------------

    /// @notice Token metadata URL
    /// @dev Looks for a token URI based on its rarity, level and percentage.
    /// @param tokenId Token id
    /// @return tokenURI Token metadata URL
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(tokenId), "Token does not exist");

        // Get token rarity, level and percentage
        string memory _rarity = rarity(tokenId).toString();
        string memory _level = level(tokenId).toString();
        string memory _percentage = journeyPercentage(tokenId).toString();

        return
            string(
                abi.encodePacked(
                    _metadataBaseURI(),
                    _rarity,
                    "-",
                    _level,
                    "-",
                    _percentage,
                    ".json"
                )
            );
    }

    /// --------------------
    /// 7.C.1 Rarities
    /// --------------------

    /// @notice Token rarity. If rarities have not been revealed yet, it returns `UNREVEALED` as rarity.
    /// @param tokenId Token id
    /// @return rarity Token rarity
    function rarity(uint256 tokenId) public view returns (Rarity) {
        require(_exists(tokenId), "Token does not exist");

        if (!raritiesHaveBeenRevealed()) return Rarity.UNREVEALED;

        // GOLD:  22 tokens
        if (tokenId % 10 == 0) return Rarity.GOLD;
        // RED:   66 tokens
        if ((tokenId + 2) % 3 == 0) return Rarity.RED;
        // BLUE:  134 tokens
        return Rarity.BLUE;
    }

    /// ------------------
    /// 7.C.2 Levels
    /// ------------------

    /// @notice Token level
    /// @dev Returns Level enum based on the amount of days since its `outsetDate`.
    /// @param tokenId Token id
    /// @return level Token level
    function level(uint256 tokenId) public view returns (Level) {
        require(_exists(tokenId), "Token does not exist");

        uint256 _daysPassed = timeSinceOutset(tokenId) / 1 days;

        if (_daysPassed < 60) return Level.COLLECTOR;
        else if (_daysPassed < 120) return Level.BELIEVER;
        else if (_daysPassed < 180) return Level.SUPPORTER;
        else return Level.FAN;
    }

    /// -----------------------------
    /// 7.C.2.A. Outset date
    /// -----------------------------

    /// @notice Time since a token outset date was last updated
    /// @dev Last block's timestamp minus its outset date
    /// @param tokenId Token id
    /// @return timeSinceOutset Seconds since outset date
    function timeSinceOutset(uint256 tokenId) public view returns (uint256) {
        return block.timestamp - outsetDate[tokenId];
    }

    /// @notice Set token `outsetDate` to current timestamp
    /// @param _tokenId tokenId
    function _resetOutsetDate(uint256 _tokenId) private {
        outsetDate[_tokenId] = block.timestamp;

        emit NewOutsetDate(_tokenId, block.timestamp);
    }

    /// @notice Calls standard `_transfer` and resets outset date if it has not reached the maximum level.
    /// @param from Token's owner or approved address
    /// @param to Recipient
    /// @param tokenId Token id to be transfered
    /// @inheritdoc	ERC721
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        ERC721._transfer(from, to, tokenId);
        if (timeSinceOutset(tokenId) < 180 days) _resetOutsetDate(tokenId);
    }

    /// @notice Calls standard `_mint` and sets outset date
    /// @param to Recipient
    /// @param tokenId Token id to be minted
    /// @inheritdoc	ERC721
    function _mint(address to, uint256 tokenId) internal override {
        ERC721._mint(to, tokenId);
        _resetOutsetDate(tokenId);
    }

    /// ------------------------------
    /// 7.C.3 Journey percentage
    /// ------------------------------

    /// @notice Percentage of time passed for maximum level (180 days)
    /// @dev Calculates percentage of time since `outsetDate` for 180 days.
    /// @param tokenId Token id
    /// @return percentage Percentage of time passed for maximum level (180 days)
    function journeyPercentage(uint256 tokenId) public view returns (uint256) {
        uint256 timePassed = timeSinceOutset(tokenId);

        if (timePassed >= 180 days) {
            return 100;
        }
        return (timePassed * 100) / 180 days;
    }

    /// ----------------
    /// ----------------
    /// 8. Interfaces
    /// ----------------
    /// ----------------

    /// @notice Verifies if the contract supports an interface
    /// @param interfaceId Interface id
    /// @return Bool: wheter it supports an interface of not
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, AccessControl)
        returns (bool)
    {
        return
            ERC721.supportsInterface(interfaceId) ||
            AccessControl.supportsInterface(interfaceId);
    }
}

/// Shout out to the Boostribe and Cryptotribe community 💜

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

/*

    ----------------
    |   TWINESIS   |
    ----------------

    The Genesis NFT project from Twinny Twin.
    3 designs. 222 items available. 1 dream.


    ------------------------
    |   WHAT IS TWINESIS   |
    ------------------------
    
    TWINESIS, (Twin+Genesis), is the first official NFT collection from
    Twinny Twin + 3 song instrumental EP, named after this collection
    including 222 total 2D animations all created by Twinny Twin.
    This will be the first official introduction to the House sub-genre
    "Crib Music", as well as the beginning of a bigger musical and
    artistic journey.
    
    Crib, being slang for house, or home fits well, hint the hip-hop
    influence in his expression of house music. Each NFT is a representation
    of beginnings, encompassing the city of St. Louis, Twinny Twin's hometown,
    inside of his logo as a celebration of the place that is responsible for
    his foundation. Here's your chance to join his and the journey of others.
    It all starts here.

    Enter the world of Crib Music

        Priority access to future collectibles, & airdrops.

        Early access to music before it releases.

        Access to metaverse + discounted IRL events

        Free digital + physical merch only available to HODLers


    -------------------
    |   ROADMAP 1.0   |
    -------------------

    This roadmap outlines foundational goals + key checkpoints, that allow
    this project to give back to its HODLers + the youth in a major way.

    25% SOLD.
‍    1 ETH Donated to Sherwood Forest Camp,
    which Twin attended as a camper + counselor. Donations will go towards
    sending young people to summer camp. This would cover roughly 50- 60 youth!

    50% SOLD.
    ‍1 ETH Donated to Boys & Girls Club St. Louis,
    which Twin taught Digital Art, and counseled for 2 years. Donations would go
    to processing fees for parents sending their kids to camp + after school programs.

    75% SOLD.
    1 ETH Donated to McCluer High School
    theatre program, which Twin participated gaining Thespian status.
    Donations would cover meals for a week for 1 production.

    90% SOLD.
    ‍501c3 development
    with the intention creating a physical space used as an art & music gallery,
    a safe place for artists + a hub for creative learning + events.

    100% SOLD OUT.
    ‍Future Drops + Moving Forward
    Each HODLer will receive a digital + physical copy of the TWINESIS EP.
    Once sold out the 2.0 roadmap will be released to show over 2 years of
    built in efforts + utilities.


    -------------
    |   LEVEL   |
    -------------

    Each NFT will become more valuable as you HODL. Your journey with Twinny Twin
    will be tracked via your NFT, with a percentage of completion until final form,
    a new song + background with each level change + a title change for each
    checkpoint you successfully reach.

    COLLECTOR
    0-2 MONTHS
    Your journey has begun. You have opened the mind.

    BELIEVER
    2-4 MONTHS
    You're making progress, the vibe is moving through your body.

    SUPPORTER
    4-6 MONTHS
    Almost at final form. So close you can feel it in your soul.

    FAN
    6+ MONTHS
    You are locked in, ride-or-die status, a real VIP.


    --------------
    |   RARITY   |
    --------------

    Each NFT is has been completely created by Twinny Twin, from music,
    illustration, to animation included in each. Each color gives a special
    utility that HODLers will be able to take advantage of for quite a while!

    Blue: 60%
    Red:  30%
    Gold: 10%


    ---------------
    |   CREATOR   |
    ---------------

    Randal Herndon, also known as Twinny Twin, a full time illustrator + musician
    based in Phoenix, Arizona has over a decade of being an artist + educator.
    Daring to remain different as a black House DJ/producer and true to the music
    he loves, moved from St. Louis to AZ, in 2018 to pursue growth and opportunities
    in a new environment. Twin is also a 2nd degree blackbelt in Taekwondo, an uncle
    of 6 nieces and nephews, and yes actually a twin.

    Having much success in both music + design, gaining over 150,000 collective
    streams, teaching thousands of students, launching multiple national brands
    and working with countless youth, Twin has decided it's time to bring his wealth
    of knowledge full circle. The ultimate goal bring new creative opportunities and
    spaces to communities + youth that don't have the access or resources parallel to
    releasing dope music to the world. Join the Discord for updates + more.

*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

/// @notice Three rarities available
/// @dev Using enums for rarities
enum Rarity {
    BLUE,
    RED,
    GOLD,
    UNREVEALED
}

/// @notice Tokens will increase their level while holding them
/// @dev Using enums for levels
enum Level {
    COLLECTOR,
    BELIEVER,
    SUPPORTER,
    FAN
}

/// @title Twinesis Strings
/// @author Nicolás Acosta (nicoacosta.eth) - @0xnico_ - linktr.ee/nicoacosta.eth
/// @notice Get strings from Enum and Level types
library TwinesisStrings {
    /// @notice Rarity string
    /// @param rarity Some rarity
    /// @return String Rarity string
    function toString(Rarity rarity) internal pure returns (string memory) {
        if (rarity == Rarity.GOLD) return "gold";
        if (rarity == Rarity.RED) return "red";
        if (rarity == Rarity.BLUE) return "blue";
        if (rarity == Rarity.UNREVEALED) return "unrevealed";
    }

    /// @notice Level string
    /// @param level Some level
    /// @return String Level string
    function toString(Level level) internal pure returns (string memory) {
        if (level == Level.COLLECTOR) return "collector";
        if (level == Level.BELIEVER) return "believer";
        if (level == Level.SUPPORTER) return "supporter";
        if (level == Level.FAN) return "fan";
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./Types.sol";

interface ITwinesis {
    // Constants

    function MAX_TOKENS() external view returns (uint256);

    function MINTING_PRICE() external view returns (uint256);

    function PRE_SALE_START_DATE() external view returns (uint256);

    function PUBLIC_MINTING_START_DATE() external view returns (uint256);

    function PRE_SALE_GOODLIST_ROLE() external view returns (bytes32);

    // Twinesis properties

    function rarity(uint256 tokenId) external view returns (Rarity);

    function level(uint256 tokenId) external view returns (Level);

    function journeyPercentage(uint256) external view returns (uint256);

    function outsetDate(uint256 tokenId) external view returns (uint256);

    function timeSinceOutset(uint256 tokenId) external view returns (uint256);

    // Twinesis minting

    function mintTwin() external payable;

    function mintTwins(uint256 amount) external payable;

    function preSaleMintTwin() external payable;

    function preSaleMintTwins(uint256 amount) external payable;

    // ERC721 extensions

    // function contractURI() external pure returns (string memory);

    function exists(uint256 tokenId) external view returns (bool);

    function tokensToMint() external view returns (uint256);

    function mintedTokens() external view returns (uint256);

    // AccessControl

    function grantRoleMultiple(bytes32 role, address[] memory accounts)
        external;

    function withdraw() external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}