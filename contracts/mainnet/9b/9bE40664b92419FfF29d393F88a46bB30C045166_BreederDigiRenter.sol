// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "./Adventure/DigiDaigaku.sol";
import "./Adventure/DigiDaigakuHeroes.sol";
import "./Adventure/DigiDaigakuSpirits.sol";
import "./Adventure/HeroAdventure.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract BreederDigiRenter is AdventurePermissions, ReentrancyGuard {
    DigiDaigaku public genesisToken;
    DigiDaigakuHeroes public heroToken;
    DigiDaigakuSpirits public spiritToken;
    HeroAdventure public adventure;

    mapping(uint16 => uint256) public genesisFee;
    mapping(uint16 => uint256) public genesisEndDate;

    mapping(uint16 => bool) public genesisIsDeposited;
    mapping(uint16 => bool) public genesisIsOnAdventure;

    mapping(uint16 => address) private _genesisOwner;
    mapping(uint16 => address) private _spiritOwner;

    mapping(uint16 => uint16) private _spiritGenesisAdventurePair;
    mapping(uint16 => uint16) private _genesisSpiritAdventurePair;


    event GenesisDeposited(
        uint16 indexed genesisId,
        address indexed genesisOwner,
        uint256 fee,
        uint256 endDate
    );

    event GenesisWithdrawn(
        uint16 indexed genesisId,
        address indexed genesisOwner
    );

    event GenesisFeeUpdated(
        uint16 indexed genesisId,
        uint256 oldFee,
        uint256 newFee
    );

    event GenesisEndDateUpdated(
        uint16 indexed genesisId,
        uint256 oldEndDate,
        uint256 newEndDate
    );

    event HeroOnQuest(
        uint16 indexed spiritId,
        uint16 genesisId,
        address indexed spiritOwner,
        address indexed genesisOwner,
        uint256 fee
    );

    event HeroMinted(
        uint16 indexed spiritId,
        uint16 indexed genesisId,
        address indexed spiritOwner
    );

    event ForceClaim(
        uint16 indexed spiritId,
        uint16 indexed genesisId,
        address indexed genesisOwner
    );

    event CancelQuest(
        uint16 indexed spiritId,
        uint16 indexed genesisId,
        address indexed genesisOwner
    );

    modifier onlyGenesisOwner(uint16 genesisId) {
        require(
            _msgSender() == _genesisOwner[genesisId],
            "BreederDigiRenter.onlyGenesisOwner: not owner of genesis"
        );
        _;
    }

    modifier onlySpiritOwner(uint16 spiritId) {
        require(
            _msgSender() == _spiritOwner[spiritId],
            "BreederDigiRenter.onlySpiritOwner: not owner of spirit"
        );
        _;
    }

    modifier onlyGenesisAvailable(uint16 genesisId) {
        require(
            genesisIsDeposited[genesisId],
            "BreederDigiRenter.onlyGenesisAvailable: genesis not deposited"
        );
        require(
            !genesisIsOnAdventure[genesisId],
            "BreederDigiRenter.onlyGenesisAvailable: genesis is on adventure"
        );
        _;
    }

    constructor(
        address _genesisToken,
        address _heroToken,
        address _spiritToken,
        address _adventure
    ) {
        genesisToken = DigiDaigaku(_genesisToken);
        heroToken = DigiDaigakuHeroes(_heroToken);
        spiritToken = DigiDaigakuSpirits(_spiritToken);
        adventure = HeroAdventure(_adventure);

        spiritToken.setAdventuresApprovedForAll(address(adventure), true);
    }

    function depositGenesis(
        uint16 genesisId,
        uint256 fee,
        uint256 endDate
    ) external nonReentrant {
        _depositGenesis(genesisId, fee, endDate);
    }

    function depositMultipleGenesis(
        uint16[] memory genesisIds,
        uint256[] memory fees,
        uint256[] memory endDates
    ) external nonReentrant {
        require(
            genesisIds.length == fees.length,
            "BreederDigiRenter.depositMultipleGenesis: incompatible count of values"
        );
        for (uint256 i = 0; i < genesisIds.length; i++) {
            _depositGenesis(genesisIds[i], fees[i], endDates[i]);
        }
    }

    function withdrawGenesis(uint16 genesisId)
        external
        onlyGenesisAvailable(genesisId)
        onlyGenesisOwner(genesisId)
        nonReentrant
    {
        _withdrawGenesis(genesisId);
    }

    function updateGenesisFee(uint16 genesisId, uint256 newFee)
        external
        onlyGenesisAvailable(genesisId)
        onlyGenesisOwner(genesisId)
        nonReentrant
    {
        uint256 oldFee = genesisFee[genesisId];
        genesisFee[genesisId] = newFee;

        emit GenesisFeeUpdated(genesisId, oldFee, newFee);
    }

    function updateEndDate(uint16 genesisId, uint256 newEndDate)
        external
        onlyGenesisOwner(genesisId)
        nonReentrant
    {
        require(
            newEndDate > block.timestamp || newEndDate == 0,
            "BreederDigiRenter.depositGenesis: nominated newEndDate already elapsed"
        );

        uint256 oldEndDate = genesisEndDate[genesisId];
        genesisEndDate[genesisId] = newEndDate;

        emit GenesisEndDateUpdated(genesisId, oldEndDate, newEndDate);
    }

    function enterHeroQuest(uint16 spiritId, uint16 genesisId)
        external
        payable
        onlyGenesisAvailable(genesisId)
        nonReentrant
    {
        require(
            spiritToken.ownerOf(spiritId) == _msgSender(),
            "BreederDigiRenter.enterHeroQuest: not owner of spirit"
        );

        require(
            genesisFee[genesisId] == msg.value,
            "BreederDigiRenter.enterHeroQuest: fee has changed"
        );

        require(
            genesisEndDate[genesisId] == 0 ||
                genesisEndDate[genesisId] > block.timestamp,
            "BreederDigiRenter.enterHeroQuest: endDate has elapsed"
        );

        _spiritOwner[spiritId] = _msgSender();
        genesisIsOnAdventure[genesisId] = true;
        _genesisSpiritAdventurePair[genesisId] = spiritId;
        _spiritGenesisAdventurePair[spiritId] = genesisId;

        spiritToken.transferFrom(_msgSender(), address(this), spiritId);
        genesisToken.approve(address(adventure), genesisId);
        adventure.enterQuest(spiritId, genesisId);

        // sent eth to genesis owner
        Address.sendValue(payable(_genesisOwner[genesisId]), msg.value);

        emit HeroOnQuest(
            spiritId,
            genesisId,
            _msgSender(),
            _genesisOwner[genesisId],
            msg.value
        );
    }

    function mintHero(uint16 spiritId)
        external
        onlySpiritOwner(spiritId)
        nonReentrant
    {
        uint16 genesisId = _spiritGenesisAdventurePair[spiritId];

        require(
            genesisIsOnAdventure[genesisId],
            "BreederDigiRenter.mintHero: genesis is not on adventure"
        );

        _resetAdventureState(spiritId, genesisId);

        adventure.exitQuest(spiritId, true);
        heroToken.transferFrom(address(this), _msgSender(), spiritId);

        emit HeroMinted(spiritId, genesisId, _msgSender());
    }

    function forceClaimAndWithdraw(uint16 genesisId)
        external
        onlyGenesisOwner(genesisId)
        nonReentrant
    {
        uint16 spiritId = _genesisSpiritAdventurePair[genesisId];

        require(
            genesisIsOnAdventure[genesisId],
            "BreederDigiRenter.forceClaimAndWithdraw: genesis is not on adventure"
        );

        address spiritOwner = _spiritOwner[spiritId];

        _resetAdventureState(spiritId, genesisId);

        adventure.exitQuest(spiritId, true);
        heroToken.transferFrom(address(this), spiritOwner, spiritId);

        _withdrawGenesis(genesisId);

        emit HeroMinted(spiritId, genesisId, spiritOwner);
        emit ForceClaim(spiritId, genesisId, _msgSender());
    }

    function cancelAdventureAndWithdraw(uint16 genesisId)
        external
        payable
        onlyGenesisOwner(genesisId)
        nonReentrant
    {
        uint16 spiritId = _genesisSpiritAdventurePair[genesisId];

        require(
            genesisIsOnAdventure[genesisId],
            "BreederDigiRenter.forceClaimAndWithdraw: genesis is not on adventure"
        );

        require(
            genesisFee[genesisId] == msg.value,
            "BreederDigiRenter.cancelAdventureAndWithdraw: incorrect fee refund amount"
        );

        address spiritOwner = _spiritOwner[spiritId];

        _resetAdventureState(spiritId, genesisId);

        adventure.exitQuest(spiritId, false);

        // return genesis and spirit
        _withdrawGenesis(genesisId);
        spiritToken.transferFrom(address(this), spiritOwner, spiritId);

        Address.sendValue(payable(spiritOwner), msg.value);

        emit CancelQuest(spiritId, genesisId, _msgSender());
    }

    function _resetAdventureState(uint16 spiritId, uint16 genesisId) internal {
        _spiritOwner[spiritId] = address(0);
        genesisIsOnAdventure[genesisId] = false;
        _genesisSpiritAdventurePair[genesisId] = uint16(0);
        _spiritGenesisAdventurePair[spiritId] = uint16(0);
    }

    function _withdrawGenesis(uint16 genesisId) internal {
        address genesisOwner = _genesisOwner[genesisId];

        _genesisOwner[genesisId] = address(0);
        genesisFee[genesisId] = 0;
        genesisEndDate[genesisId] = 0;
        genesisIsDeposited[genesisId] = false;

        genesisToken.transferFrom(address(this), genesisOwner, genesisId);
        emit GenesisWithdrawn(genesisId, genesisOwner);
    }

    function _depositGenesis(
        uint16 genesisId,
        uint256 fee,
        uint256 endDate
    ) internal {
        require(
            endDate > block.timestamp || endDate == 0,
            "BreederDigiRenter.depositGenesis: nominated endDate already elapsed"
        );
        _genesisOwner[genesisId] = _msgSender();
        genesisFee[genesisId] = fee;
        genesisIsDeposited[genesisId] = true;
        genesisEndDate[genesisId] = endDate;

        genesisToken.transferFrom(_msgSender(), address(this), genesisId);
        emit GenesisDeposited(genesisId, _msgSender(), fee, endDate);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./AdventureERC721.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

/// @title DigiDaigakuSpirits contract
/// @dev Extends ERC721 Non-Fungible Token Standard basic implementation and includes adventure/quest staking behaviors
contract DigiDaigakuSpirits is AdventureERC721, ERC2981 {
    using Strings for uint256;

    string public baseTokenURI;
    string public suffixURI = ".json";
    uint256 private nextTokenId = 1;

    uint96 public constant MAX_ROYALTY_FEE_NUMERATOR = 1000;
    uint256 public constant MAX_SUPPLY = 2022;

    /// @dev Emitted when base URI is set.
    event BaseURISet(string baseTokenURI);

    /// @dev Emitted when suffix URI is set.
    event SuffixURISet(string suffixURI);

    /// @dev Emitted when royalty is set.
    event RoyaltySet(address receiver, uint96 feeNumerator);

    constructor() ERC721("DigiDaigakuSpirits", "DISP") {}

    /// @notice Owner bulk mint to airdrop
    function airdropMint(address[] calldata to) external onlyOwner {
        uint256 batchSize = to.length;
        uint256 tokenIdToMint = nextTokenId;
        require(tokenIdToMint + batchSize - 1 <= MAX_SUPPLY, "Supply cannot exceed 2022");
        nextTokenId = nextTokenId + batchSize;

        unchecked {
            for (uint256 i = 0; i < batchSize; ++i) {
                _mint(to[i], tokenIdToMint + i);
            }
        }
    }

    /// @dev Required to return baseTokenURI for tokenURI
    function _baseURI()
        internal
        view
        virtual
        override
        returns (string memory)
    {
        return baseTokenURI;
    }

    /// @notice Sets base URI
    function setBaseURI(string memory baseTokenURI_) external onlyOwner {
        baseTokenURI = baseTokenURI_;

        emit BaseURISet(baseTokenURI_);
    }

    /// @notice Sets suffix URI
    function setSuffixURI(string memory suffixURI_) external onlyOwner {
        suffixURI = suffixURI_;

        emit SuffixURISet(suffixURI_);
    }

    /// @notice Sets royalty information
    function setRoyaltyInfo(address receiver, uint96 feeNumerator)
        external
        onlyOwner
    {
        require(feeNumerator <= MAX_ROYALTY_FEE_NUMERATOR, "Exceeds max royalty fee");
        _setDefaultRoyalty(receiver, feeNumerator);

        emit RoyaltySet(receiver, feeNumerator);
    }

    /// @notice Returns tokenURI if baseURI is set
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "Nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0
            ? string(abi.encodePacked(baseURI, tokenId.toString(), suffixURI))
            : "";
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override (AdventureERC721, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./AdventureERC721.sol";
import "./Bloodlines.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

contract DigiDaigakuHeroes is AdventureERC721, ERC2981 {
    using Strings for uint256;

    /// @dev Largest unsigned int 256 bit value
    uint256 private constant MAX_UINT = type(uint256).max;

    /// @dev The maximum hero token supply
    uint256 public constant MAX_SUPPLY = 2022;

    /// @dev The maximum allowable royalty fee is 10%
    uint96 public constant MAX_ROYALTY_FEE_NUMERATOR = 1000;

    /// @dev Bloodline array - uses tight variable packing to save gas
    Bloodlines.Bloodline[MAX_SUPPLY] private bloodlines;

    /// @dev Bitmap that helps determine if a token was ever minted previously
    uint256[] private mintedTokenTracker;

    /// @dev Base token uri
    string public baseTokenURI;

    /// @dev Token uri suffix/extension
    string public suffixURI = ".json";

    /// @dev Whitelisted minter mapping
    mapping(address => bool) public whitelistedMinters;

    /// @dev Emitted when base URI is set.
    event BaseURISet(string baseTokenURI);

    /// @dev Emitted when suffix URI is set.
    event SuffixURISet(string suffixURI);

    /// @dev Emitted when royalty is set.
    event RoyaltySet(address receiver, uint96 feeNumerator);

    /// @dev Emitted when the minter whitelist is updated
    event MinterWhitelistUpdated(address indexed minter, bool whitelisted);

    /// @dev Emitted when a hero is minted
    event MintHero(
        address indexed to,
        uint256 indexed tokenId,
        uint256 indexed genesisTokenId,
        uint256 timestamp
    );

    constructor() ERC721("DigiDaigakuHeroes", "DIHE") {
        unchecked {
            // Initialize memory to use for tracking token ids that have been minted
            // The bit corresponding to token id defaults to 1 when unminted,
            // and will be set to 0 upon mint.
            uint256 numberOfTokenTrackerSlots = getNumberOfTokenTrackerSlots();
            for (uint256 i = 0; i < numberOfTokenTrackerSlots; ++i) {
                mintedTokenTracker.push(MAX_UINT);
            }
        }
    }

    modifier onlyMinter() {
        require(isMinterWhitelisted(_msgSender()), "Not a minter");
        _;
    }

    /// @notice Returns whether the specified account is a whitelisted minter
    function isMinterWhitelisted(address account)
        public
        view
        returns (bool)
    {
        return whitelistedMinters[account];
    }

    /// @notice Whitelists a minter
    function whitelistMinter(address minter) external onlyOwner {
        require(!whitelistedMinters[minter], "Already whitelisted");
        whitelistedMinters[minter] = true;

        emit MinterWhitelistUpdated(minter, true);
    }

    /// @notice Removes a minter from the whitelist
    function unwhitelistMinter(address minter) external onlyOwner {
        require(whitelistedMinters[minter], "Not whitelisted");
        delete whitelistedMinters[minter];

        emit MinterWhitelistUpdated(minter, false);
    }

    /// @notice Allows whitelisted minters to mint a hero with the specified bloodline
    function mintHero(address to, uint256 tokenId, uint256 genesisTokenId)
        external
        onlyMinter
    {
        unchecked {
            require(tokenId > 0, "Token id out of range");
            require(tokenId <= MAX_SUPPLY, "Token id out of range");
            require(genesisTokenId <= MAX_SUPPLY, "Genesis token id out of range");

            uint256 slot = tokenId / 256;
            uint256 offset = tokenId % 256;
            uint256 slotValue = mintedTokenTracker[slot];
            require(((slotValue >> offset) & uint256(1)) == 1, "Token already minted");

            mintedTokenTracker[slot] = slotValue & ~(uint256(1) << offset);
            bloodlines[tokenId - 1] =
                determineBloodline(tokenId, genesisTokenId);
            emit MintHero(to, tokenId, genesisTokenId, block.timestamp);
        }

        _mint(to, tokenId);
    }

    /// @dev Required to return baseTokenURI for tokenURI
    function _baseURI()
        internal
        view
        virtual
        override
        returns (string memory)
    {
        return baseTokenURI;
    }

    /// @notice Sets base URI
    function setBaseURI(string calldata baseTokenURI_) external onlyOwner {
        baseTokenURI = baseTokenURI_;

        emit BaseURISet(baseTokenURI_);
    }

    /// @notice Sets suffix URI
    function setSuffixURI(string calldata suffixURI_) external onlyOwner {
        suffixURI = suffixURI_;

        emit SuffixURISet(suffixURI_);
    }

    /// @notice Sets royalty information
    function setRoyaltyInfo(address receiver, uint96 feeNumerator)
        external
        onlyOwner
    {
        require(feeNumerator <= MAX_ROYALTY_FEE_NUMERATOR, "Exceeds max royalty fee");
        _setDefaultRoyalty(receiver, feeNumerator);

        emit RoyaltySet(receiver, feeNumerator);
    }

    /// @notice Returns the bloodline of the specified hero token id.
    /// Throws if the token does not exist.
    function getBloodline(uint256 tokenId)
        external
        view
        returns (Bloodlines.Bloodline)
    {
        require(_exists(tokenId), "Nonexistent token");
        return bloodlines[tokenId - 1];
    }

    /// @notice Returns tokenURI if baseURI is set
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "Nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0
            ? string(abi.encodePacked(baseURI, tokenId.toString(), suffixURI))
            : "";
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override (AdventureERC721, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /// @dev Returns the bloodline based on the combination of token id and genesis token id
    /// A rogue is created when only a spirit token was staked.
    /// A warrior is created when a spirit is staked with a genesis token and the token ids do not match.
    /// A royal is created when a spirit is staked with a genesis token and the token ids match.
    function determineBloodline(uint256 tokenId, uint256 genesisTokenId)
        internal
        pure
        returns (Bloodlines.Bloodline)
    {
        if (genesisTokenId == 0) {
            return Bloodlines.Bloodline.Rogue;
        } else if (tokenId != genesisTokenId) {
            return Bloodlines.Bloodline.Warrior;
        } else {
            return Bloodlines.Bloodline.Royal;
        }
    }

    /// @dev Determines number of slots required to track minted tokens across the max supply
    function getNumberOfTokenTrackerSlots()
        internal
        pure
        returns (uint256 tokenTrackerSlotsRequired)
    {
        unchecked {
            // Add 1 because we are starting valid token id range at 1 instead of 0
            uint256 maxSupplyPlusOne = 1 + MAX_SUPPLY;
            tokenTrackerSlotsRequired = maxSupplyPlusOne / 256;
            if (maxSupplyPlusOne % 256 > 0) {
                ++tokenTrackerSlotsRequired;
            }
        }

        return tokenTrackerSlotsRequired;
    }
}

// By interacting with this code I agree to the Quest Terms at https://digidaigaku.com/hero-adventure-tos.pdf
// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./IAdventure.sol";
import "./IMintableHero.sol";
import "./IQuestStakingERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

/// @title HeroAdventure contract
/// @notice This contract is the entry point into a quest where players will receive a hero NFT upon completion of the quest
/// @dev This adventure is intened to prevent the transfer of Adventure ERC721 tokens that are engaged in the quest.
/// This `questsLockTokens` value must be set to `true` when this adventure contract is whitelisted.
contract HeroAdventure is Context, Ownable, Pausable, ERC165, IAdventure {
    struct HeroQuest {
        uint16 genesisTokenId;
        uint16 spiritTokenId;
        address adventurer;
    }

    /// @dev The amount of time the user must remain in the quest to complete it and receive a hero
    uint256 public constant HERO_QUEST_DURATION = 1 days;

    /// @dev The identifier for the spirit quest
    uint256 public constant SPIRIT_QUEST_ID = 1;

    /// @dev The largest token id for genesis and spirit tokens
    uint256 public constant MAX_TOKEN_ID = 2022;

    /// @dev An unchangeable reference to the hero contract that is rewarded at the conclusion of adventure quest
    IMintableHero public immutable heroContract;

    /// @dev An unchangeable reference to the genesis token contract
    IERC721 public immutable genesisContract;

    /// @dev An unchangeable reference to the spirit token contract
    IQuestStakingERC721 public immutable spiritContract;

    /// @dev Map spirit token id to hero quest details
    mapping(uint256 => HeroQuest) public spiritQuestLookup;

    /// @dev Map genesis token id to hero quest details
    mapping(uint256 => HeroQuest) public genesisQuestLookup;

    /// @dev Specify the hero, genesis, and spirit token contract addresses during creation
    constructor(
        address heroAddress,
        address genesisAddress,
        address spiritAddress
    ) {
        heroContract = IMintableHero(heroAddress);
        genesisContract = IERC721(genesisAddress);
        spiritContract = IQuestStakingERC721(spiritAddress);
    }

    /// @dev ERC-165 interface support
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override (ERC165, IERC165)
        returns (bool)
    {
        return interfaceId == type(IAdventure).interfaceId || super.supportsInterface(interfaceId);
    }

    /// @dev Returns whether or not quests on this adventure lock tokens.
    function questsLockTokens() external pure override returns (bool) {
        return true;
    }

    /// @dev A callback function that AdventureERC721 must invoke when a quest has been successfully entered.
    /// Throws in all cases because spirits contract did not implement the IAdventure checks and will not invoke this callback.
    function onQuestEntered(
        address, /*adventurer*/
        uint256, /*tokenId*/
        uint256 /*questId*/
    )
        external
        pure
        override
    {
        revert("Callback not implemented");
    }

    /// @dev A callback function that AdventureERC721 must invoke when a quest has been successfully exited.
    /// Throws in all cases because spirits contract did not implement the IAdventure checks and will not invoke this callback.
    function onQuestExited(
        address, /*adventurer*/
        uint256, /*tokenId*/
        uint256, /*questId*/
        uint256 /*questStartTimestamp*/
    )
        external
        pure
        override
    {
        revert("Callback not implemented");
    }

    /// @dev Pauses and blocks adventurers from starting new hero quests
    /// Throws if the adventure is already paused
    function pauseNewQuestEntries() external onlyOwner {
        _pause();
    }

    /// @dev Unpauses and allows adventurers to start new hero quests
    /// Throws if the adventure is already unpaused
    function unpauseNewQuestEntries() external onlyOwner {
        _unpause();
    }

    /// @dev Enters the hero quest with a spirit and an optional genesis token id
    /// Throws when the spirit has already been entered into the quest by the caller
    /// Throws when the specified non-zero genesis token id does not exist
    /// Throws when the specified non-zero genesis token id is not owned by the caller
    /// Throws if the genesis transferFrom function fails to transfer custody of genesis to this contract
    /// Throws when the specified spirit token id does not exist
    /// Throws when the specified spirit token id is not owned by the caller
    /// Throws if the spirit cannot enter quest, for example if this adventure has been removed from whitelist
    /// Throws if the contract is paused

    /// Postconditions:
    /// ---------------

    /// The specified non-zero genesis token id is owned by this contract
    /// The genesis quest lookup contains the quest details when a non-zero genesis token was specified
    /// The spirit quest lookup contains the quest details for the specified spirit token id
    /// The spirit token has been entered into quest #1 for this adventure

    /// Caveats/Special Cases:
    /// ----------------------

    /// 1. Bob enters the quest spirit token 1 with a genesis token
    /// 2. Bob uses the backdoor userExitQuest call on the spirit contract to exit the quest for spirit token 1.
    ///    This adventure contract still thinks spirit token 1 is on the quest.
    /// 3. Bob sells spirit token 1 to Amy (Bob's token is now orphaned, and can be recovered by calling recoverOrphanedGenesisToken).
    /// 4. Amy is allowed to call enterQuest with spirit token id 1.
    /// 5. Amy's progress starts when she enters the quest with the spirit, not when Bob entered the quest originally.
    function enterQuest(uint256 spiritTokenId, uint256 genesisTokenId)
        external
        whenNotPaused
    {
        address caller = _msgSender();
        require(spiritQuestLookup[spiritTokenId].adventurer != caller, "Spirit already entered into quest by caller");

        if (genesisTokenId > 0) {
            address genesisOwner = genesisContract.ownerOf(genesisTokenId);
            require(genesisOwner == caller, "Caller not owner of genesis");

            genesisQuestLookup[genesisTokenId] = HeroQuest({
                genesisTokenId: uint16(genesisTokenId),
                spiritTokenId: uint16(spiritTokenId),
                adventurer: genesisOwner
            });

            genesisContract.transferFrom(genesisOwner, address(this), genesisTokenId);
        }

        require(spiritContract.ownerOf(spiritTokenId) == caller, "Caller not owner of spirit");

        spiritQuestLookup[spiritTokenId] = HeroQuest({
            genesisTokenId: uint16(genesisTokenId),
            spiritTokenId: uint16(spiritTokenId),
            adventurer: caller
        });

        spiritContract.enterQuest(spiritTokenId, SPIRIT_QUEST_ID);
    }

    /// @dev Exits the hero quest for a specified spirit with the genesis token that it was paired with, if applicable.
    /// Throws when the spirit has not been entered into the quest by any caller.
    /// Throws when the owner of the spirit token is not the caller.
    /// Throws if the owner of the spirit is not the same as the original user that entered the quest with the the spirit.
    ///  - This can happen if a user does a backdoor userExitQuest on the spirit directly.
    ///  - The new owner needs to enterQuest with the spirit first before it can be exited from the quest to claim a reward.
    /// Throws if the parameter `redeemHero` is true and the quest has not been completed yet
    ///  - This prevents accidentally exiting the quest just before the quest ends, as the user's progress would be lost
    /// Throws if the parameter `redeemHero` is false and the quest is complete

    /// Postconditions:
    /// ---------------

    /// If a genesis token was paired with the spirit when the spirit entered the quest, the genesis token id is returned to the original
    /// address from which the genesis token came.
    /// The genesis quest mapping is cleared for the returned genesis token id.
    /// The quest on the spirit contract will be in the exited state.
    /// If the quest is exited after the quest timer has been completed, the spirit is burned
    /// and a hero with the proper bloodline is minted to the adventurer who completed the adventure.
    /// The spirit quest mapping is cleared for the specified spirit token id.

    /// Caveats/Special Cases:
    /// ----------------------

    /// 1. Bob previously entered the quest with spirit token 1 and with a genesis token
    /// 2. Bob uses the backdoor userExitQuest call on the spirit contract to exit the quest for spirit token 1.
    ///    This adventure contract still thinks spirit token 1 is in the quest.
    /// 3. Until Bob sells or transfers spirit token 1, Bob can still call exitQuest on this
    ///    contract to clear the quest state and retrieve their genesis token that was paired with the spirit.
    /// 4. Bob sells spirit token 1 to Amy (If Bob did not exitQuest first, Bob's genesis token is now orphaned, and can be recovered by calling recoverOrphanedGenesisToken).
    /// 5. Amy cannot call exitQuest for spirit 1 without first entering the quest with spirit 1. Amy's progress starts when she enters the quest.
    /// 6. Amy can exit the quest normally (before 30 days, she will not receive a reward, but after 30 days she will receive the reward).
    function exitQuest(uint256 spiritTokenId, bool redeemHero) external {
        address caller = _msgSender();

        HeroQuest memory quest = spiritQuestLookup[spiritTokenId];
        require(quest.adventurer != address(0), "Spirit token is not on quest");
        require(spiritContract.ownerOf(spiritTokenId) == caller, "Caller not owner of spirit");

        if (quest.genesisTokenId > 0) {
            returnGenesisToAdventurer(genesisQuestLookup[quest.genesisTokenId].adventurer, quest.genesisTokenId);
        }

        if (quest.adventurer == caller) {
            (bool participatingInQuest, uint256 startTimestamp,) =
            spiritContract.isParticipatingInQuest(spiritTokenId, address(this), SPIRIT_QUEST_ID);

            if (participatingInQuest) {
                bool questComplete =
                    block.timestamp - startTimestamp >= HERO_QUEST_DURATION;

                if (questComplete && !redeemHero) {
                    revert("Quest complete, must redeem hero");
                }

                if (!questComplete && redeemHero) {
                    revert("Complete quest to redeem hero");
                }

                spiritContract.exitQuest(spiritTokenId, SPIRIT_QUEST_ID);

                if (questComplete) {
                    spiritContract.adventureBurn(spiritTokenId);
                    heroContract.mintHero(caller, spiritTokenId, quest.genesisTokenId);
                }
            }
        } else {
            revert("New spirit owner must enter quest with spirit before exiting");
        }

        delete spiritQuestLookup[spiritTokenId];
    }

    /// @dev Used only to protect against an edge case where a backdoor exit and transfer occurs, locking up genesis tokens.

    /// This can be called by anyone generous enough to spend gas to help a player recover their genesis token,
    /// as it will always return to the original owner of the genesis token that entered a quest.

    /// Throws when the speicified genesis token id is not in an orphaned state.

    /// Postconditions:
    /// ---------------

    /// The orphaned genesis token is returned to the address that originally entered a quest with it.
    /// The genesis quest mapping is cleared, returning the contract to a consistent state.
    function recoverOrphanedGenesisToken(uint256 genesisTokenId) external {
        (bool isOrphaned, address returnAddress) =
            isGenesisTokenOrphaned(genesisTokenId);
        require(isOrphaned, "Genesis token is not orphaned");
        returnGenesisToAdventurer(returnAddress, genesisTokenId);
    }

    /// @dev Enumerates all hero quests/pairs that are currently entered into quests by the specified player.
    /// Never use this function in a transaction context - it is fine for a read-only query for
    /// external applications, but will consume a lot of gas when used in a transaction.
    function findHeroQuestsByPlayer(address player)
        external
        view
        returns (HeroQuest[] memory playerQuests)
    {
        unchecked {
            // First, find all the token ids owned by the player
            uint256 ownerBalance = spiritContract.balanceOf(player);
            uint256[] memory ownedTokenIds = new uint256[](ownerBalance);
            uint256 tokenIndex = 0;
            for (
                uint256 spiritTokenId = 1;
                spiritTokenId <= MAX_TOKEN_ID;
                ++spiritTokenId
            ) {
                try spiritContract.ownerOf(spiritTokenId) returns (address ownerOfToken) {
                    if(ownerOfToken == player) {
                        ownedTokenIds[tokenIndex++] = spiritTokenId;
                    }
                } catch {}

                if (tokenIndex == ownerBalance) {
                    break;
                }
            }

            // For each owned spirit token id, check the quest count
            // When 1 or greater, the spirit is engaged in a quest on this adventure.
            address thisAddress = address(this);
            uint256 numberOfQuests = 0;
            for (uint256 i = 0; i < ownerBalance; ++i) {
                if (
                    spiritContract.getQuestCount(ownedTokenIds[i], thisAddress) > 0
                ) {
                    ++numberOfQuests;
                }
            }

            // Finally, make one more pass and populate the player quests return array
            uint256 questIndex = 0;
            playerQuests = new HeroQuest[](numberOfQuests);

            for (uint256 i = 0; i < ownerBalance; ++i) {
                if (
                    spiritContract.getQuestCount(ownedTokenIds[i], thisAddress) > 0
                ) {
                    playerQuests[questIndex] =
                        spiritQuestLookup[ownedTokenIds[i]];
                    ++questIndex;
                }

                if (questIndex == numberOfQuests) {
                    break;
                }
            }
        }

        return playerQuests;
    }

    /// @dev Given a list of genesis token ids, returns whether or not each token id is considered orphaned.
    /// The length of orphanedStatuses return array always matches the length of the genesisTokenIds input array.
    /// When orphanedStatuses[i] == true, it means genesisTokenIds[i] was orphaned.
    /// When orphanedStatuses[i] == false, it means genesisTokenIds[i] was not orphaned.
    function areGenesisTokensOrphaned(uint256[] calldata genesisTokenIds)
        external
        view
        returns (bool[] memory orphanedStatuses)
    {
        unchecked {
            uint256 queryLength = genesisTokenIds.length;
            orphanedStatuses = new bool[](queryLength);
            for (uint256 i = 0; i < queryLength; i++) {
                (bool isOrphaned,) = isGenesisTokenOrphaned(genesisTokenIds[i]);
                orphanedStatuses[i] = isOrphaned;
            }
        }

        return orphanedStatuses;
    }

    /// @dev Given a list of spirit token ids, returns whether or not each token id is considered soulless.
    /// The length of soullessStatuses return array always matches the length of the spiritTokenIds input array.
    /// When soullessStatuses[i] == true, it means spiritTokenIds[i] was soulless.
    /// When soullessStatuses[i] == false, it means spiritTokenIds[i] was not soulless.
    function areSpiritTokensSoulless(uint256[] calldata spiritTokenIds)
        external
        view
        returns (bool[] memory soullessStatuses)
    {
        unchecked {
            uint256 queryLength = spiritTokenIds.length;
            soullessStatuses = new bool[](queryLength);
            for (uint256 i = 0; i < queryLength; i++) {
                (bool isSoulless,) = isSpiritTokenSoulless(spiritTokenIds[i]);
                soullessStatuses[i] = isSoulless;
            }
        }

        return soullessStatuses;
    }

    /// @dev Detects whether a genesis token has been orphaned.
    /// It is orphaned if the user backdoor exits the spirit from the quest and transferred it to a new user, who then entered the quest with the spirit.
    /// Alternately, if the known adventurer for the spirit doesn't match the owner that entered quest with the genesis token,
    /// the genesis token is orphaned.
    function isGenesisTokenOrphaned(uint256 genesisTokenId)
        public
        view
        returns (bool isOrphaned, address returnAddress)
    {
        HeroQuest memory questFromGenesisLookup =
            genesisQuestLookup[genesisTokenId];
        HeroQuest memory questFromSpiritLookup =
            spiritQuestLookup[questFromGenesisLookup.spiritTokenId];

        try spiritContract.ownerOf(questFromGenesisLookup.spiritTokenId) returns (address spiritOwner) {
            isOrphaned = questFromSpiritLookup.adventurer != questFromGenesisLookup.adventurer || questFromSpiritLookup.adventurer != spiritOwner;
            returnAddress = isOrphaned ? questFromGenesisLookup.adventurer : address(0);
            return (isOrphaned, returnAddress);
        } catch {}

        isOrphaned = questFromGenesisLookup.adventurer != address(0);
        returnAddress =
            isOrphaned ? questFromGenesisLookup.adventurer : address(0);
        return (isOrphaned, returnAddress);
    }

    /// @dev Detects whether a spirit token is currently soulless.
    /// It is considered soulless if the user backdoor exits the spirit from the quest and has not transferred it to a new user.
    /// In this case, the spirit cannot be burned to claim their hero until the user exits the quest and re-enters the quest.
    function isSpiritTokenSoulless(uint256 spiritTokenId)
        public
        view
        returns (bool isSoulless, address soullessOwner)
    {
        try spiritContract.ownerOf(spiritTokenId) returns (address spiritOwner) {
            (bool participatingInQuest,,) = spiritContract.isParticipatingInQuest(spiritTokenId, address(this), SPIRIT_QUEST_ID);
            isSoulless = spiritQuestLookup[spiritTokenId].adventurer == spiritOwner && !participatingInQuest;
            soullessOwner = isSoulless ? spiritOwner : address(0);
            return (isSoulless, soullessOwner);
        } catch {}

        return (false, address(0));
    }

    /// @dev Returns a genesis token to the specified adventurer
    function returnGenesisToAdventurer(
        address adventurer,
        uint256 genesisTokenId
    )
        private
    {
        genesisContract.transferFrom(
            address(this), 
            adventurer,
            genesisTokenId);

        delete genesisQuestLookup[genesisTokenId];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

/// @title DigiDaigaku contract
/// @dev Extends ERC721 Non-Fungible Token Standard basic implementation
contract DigiDaigaku is ERC721, Ownable, EIP712, ERC2981 {
    using Strings for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    string public baseTokenURI = "";
    string public suffixURI = ".json";

    uint256 public constant maxSupply = 2022;

    mapping(address => bool) public addressMinted;

    address public signer;

    /// @dev Emitted when royalty is set.
    event RoyaltySet(address _receiver, uint96 _feeNumerator);

    /// @dev Emitted when signer is set.
    event SignerSet(address _signer);

    /// @dev Emitted when base URI is set.
    event BaseURISet(string _baseTokenURI);

    /// @dev Emitted when suffix URI is set.
    event SuffixURISet(string _suffixURI);

    constructor() ERC721("DigiDaigaku", "DIDA") EIP712("DigiDaigaku", "1") {}

    /// @notice Owner mint to reserve DigiDaigaku
    function mintFromOwner(uint256 _quantity, address _receiver)
        external
        onlyOwner
    {
        require(_tokenIdCounter.current() + _quantity <= maxSupply, "Exceeds max supply");

        for (uint256 i = 0; i < _quantity; i++) {
            _tokenIdCounter.increment();
            _safeMint(_receiver, _tokenIdCounter.current());
        }
    }

    /// @notice Public mint with valid signature
    function mintPublic(bytes calldata _signature) external {
        require(!addressMinted[_msgSender()], "Exceeds claimed amount");
        require(_tokenIdCounter.current() < maxSupply, "Exceeds max supply");

        _verifySignature(_signature);

        _tokenIdCounter.increment();
        addressMinted[_msgSender()] = true;

        _safeMint(_msgSender(), _tokenIdCounter.current());
    }

    /// @dev Verify signature
    function _verifySignature(bytes calldata _signature) internal view {
        bytes32 hash = _hashTypedDataV4(
      keccak256(
        abi.encode(
          keccak256(
              "Approved(address wallet)"
          ),
          _msgSender()
        )
      )
    );

        require(
      signer == ECDSA.recover(hash, _signature),
      "Invalid signer"
    );
    }

    /// @dev Required to return baseTokenURI for tokenURI
    function _baseURI()
        internal
        view
        virtual
        override
        returns (string memory)
    {
        return baseTokenURI;
    }

    /// @notice Sets base URI
    function setBaseURI(string memory _baseTokenURI) external onlyOwner {
        baseTokenURI = _baseTokenURI;

        emit BaseURISet(_baseTokenURI);
    }

    /// @notice Sets suffix URI
    function setSuffixURI(string memory _suffixURI) external onlyOwner {
        suffixURI = _suffixURI;

        emit SuffixURISet(_suffixURI);
    }

    /// @notice Returns tokenURI if baseURI is set
    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(_tokenId), "Nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0
      ? string(abi.encodePacked(baseURI, _tokenId.toString(), suffixURI))
      : "";
    }

    /// @notice Sets signer
    function setSigner(address _signer) external onlyOwner {
        signer = _signer;

        emit SignerSet(_signer);
    }

    /// @notice Sets royalty information
    function setRoyaltyInfo(address _receiver, uint96 _feeNumerator)
        external
        onlyOwner
    {
        _setDefaultRoyalty(_receiver, _feeNumerator);

        emit RoyaltySet(_receiver, _feeNumerator);
    }

    /// @notice Returns the current total supply
    function totalSupply() external view returns (uint256) {
        return _tokenIdCounter.current();
    }

    function supportsInterface(bytes4 _interfaceId)
        public
        view
        virtual
        override (ERC721, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(_interfaceId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
                /// @solidity memory-safe-assembly
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IQuestStaking.sol";
import "./AdventurePermissions.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

abstract contract AdventureERC721 is
    ERC721,
    AdventurePermissions,
    IQuestStaking
{
    uint256 private constant MAX_UINT = type(uint256).max;
    uint256 public constant MAX_CONCURRENT_QUESTS = 100;

    /// @dev Maps each token id to a variable that maps adventures to quests that are active
    mapping(uint256 => mapping(address => Quest[])) public quests;

    /// @dev ERC-165 interface support
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override (ERC721, IERC165)
        returns (bool)
    {
        return interfaceId == type(IQuestStaking).interfaceId || super.supportsInterface(interfaceId);
    }

    /// @notice Allows an authorized game contract to transfer a player's token if they have opted in
    function adventureTransferFrom(address from, address to, uint256 tokenId)
        external
        override
        onlyAdventure
    {
        require(_isApprovedForAdventure(_msgSender(), tokenId), "Caller not approved for adventure");
        _transfer(from, to, tokenId);
    }

    /// @notice Allows an authorized game contract to transfer a player's token if they have opted in
    function adventureSafeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    )
        external
        override
        onlyAdventure
    {
        require(_isApprovedForAdventure(_msgSender(), tokenId), "Caller not approved for adventure");
        _safeTransfer(from, to, tokenId, "");
    }

    /// @notice Allows an authorized game contract to burn a player's token if they have opted in
    function adventureBurn(uint256 tokenId) external override onlyAdventure {
        require(_isApprovedForAdventure(_msgSender(), tokenId), "Caller not approved for adventure");
        _burn(tokenId);
    }

    /// @notice Allows an authorized game contract to stake a player's token into a quest if they have opted in
    function enterQuest(uint256 tokenId, uint256 questId)
        external
        override
        onlyAdventure
    {
        require(_isApprovedForAdventure(_msgSender(), tokenId), "Caller not approved for adventure");
        _enterQuest(tokenId, _msgSender(), questId);
    }

    /// @notice Allows an authorized game contract to unstake a player's token from a quest if they have opted in
    function exitQuest(uint256 tokenId, uint256 questId)
        external
        override
        onlyAdventure
    {
        require(_isApprovedForAdventure(_msgSender(), tokenId), "Caller not approved for adventure");
        _exitQuest(tokenId, _msgSender(), questId);
    }

    /// @notice Admin-only ability to boot a token from all quests on an adventure.
    /// This allows booting the token from staking if abuse is detected.
    function bootFromAllQuests(uint256 tokenId, address adventure)
        external
        onlyOwner
    {
        _exitAllQuests(tokenId, adventure, true);
    }

    /// @notice Gives the player the ability to exit a quest without interacting directly with the approved, whitelisted adventure
    function userExitQuest(uint256 tokenId, address adventure, uint256 questId)
        external
    {
        require(ownerOf(tokenId) == _msgSender(), "Only token owner may exit quest");
        _exitQuest(tokenId, adventure, questId);
    }

    /// @notice Gives the player the ability to exit all quests on an adventure without interacting directly with the approved, whitelisted adventure
    function userExitAllQuests(uint256 tokenId, address adventure) external {
        require(ownerOf(tokenId) == _msgSender(), "Only token owner may exit quest");
        _exitAllQuests(tokenId, adventure, false);
    }

    /// @notice Returns the number of quests a token is actively participating in for a specified adventure
    function getQuestCount(uint256 tokenId, address adventure)
        public
        view
        override
        returns (uint256)
    {
        return quests[tokenId][adventure].length;
    }

    /// @notice Returns the amount of time a token has been participating in the specified quest
    function getTimeOnQuest(uint256 tokenId, address adventure, uint256 questId)
        public
        view
        override
        returns (uint256)
    {
        (bool participatingInQuest, uint256 startTimestamp,) =
            isParticipatingInQuest(tokenId, adventure, questId);
        return participatingInQuest ? (block.timestamp - startTimestamp) : 0;
    }

    /// @notice Returns whether or not a token is currently participating in the specified quest as well as the time it was started and the quest index
    function isParticipatingInQuest(
        uint256 tokenId,
        address adventure,
        uint256 questId
    )
        public
        view
        override
        returns (
            bool participatingInQuest,
            uint256 startTimestamp,
            uint256 index
        )
    {
        index = MAX_UINT;

        Quest[] memory tokenQuestsForAdventure_ = quests[tokenId][adventure];

        for (uint256 i = 0; i < tokenQuestsForAdventure_.length; ++i) {
            Quest memory quest = tokenQuestsForAdventure_[i];
            if (quest.questId == uint64(questId)) {
                participatingInQuest = true;
                startTimestamp = quest.startTimestamp;
                index = i;
                break;
            }
        }

        return (participatingInQuest, startTimestamp, index);
    }

    /// @notice Returns a list of all active quests for the specified token id and adventure
    function getActiveQuests(uint256 tokenId, address adventure)
        public
        view
        override
        returns (Quest[] memory activeQuests)
    {
        uint256 questCount = getQuestCount(tokenId, adventure);
        activeQuests = new Quest[](questCount);

        for (uint256 i = 0; i < questCount; ++i) {
            activeQuests[i] = quests[tokenId][adventure][i];
        }

        return activeQuests;
    }

    /// @notice Enters the specified quest for a token id.
    /// Throws if the token is already participating in the specified quest.
    /// Throws if the number of active quests exceeds the max allowable for the given adventure.
    /// Emits a QuestUpdated event for off-chain processing.
    function _enterQuest(uint256 tokenId, address adventure, uint256 questId)
        internal
    {
        (bool participatingInQuest,,) =
            isParticipatingInQuest(tokenId, adventure, questId);
        require(!participatingInQuest, "Already on quest");
        require(getQuestCount(tokenId, adventure) < MAX_CONCURRENT_QUESTS, "Too many active quests");

        quests[tokenId][adventure].push(Quest({ startTimestamp: uint64(block.timestamp), questId: uint64(questId) }));

        emit
            QuestUpdated(tokenId, ownerOf(tokenId), adventure, questId, true, false);
    }

    /// @notice Exits the specified quest for a token id.
    /// Throws if the token is not currently participating on the specified quest.
    /// Emits a QuestUpdated event for off-chain processing.
    function _exitQuest(uint256 tokenId, address adventure, uint256 questId)
        internal
    {
        (bool participatingInQuest,, uint256 index) =
            isParticipatingInQuest(tokenId, adventure, questId);
        require(participatingInQuest, "Not on quest");

        // Copy last quest element to overwrite the quest to be removed and then pop the end of the quests array
        quests[tokenId][adventure][index] =
            quests[tokenId][adventure][getQuestCount(tokenId, adventure) - 1];
        quests[tokenId][adventure].pop();

        emit
            QuestUpdated(tokenId, ownerOf(tokenId), adventure, questId, false, false);
    }

    /// @notice Removes the specified token id from all quests on the specified adventure
    function _exitAllQuests(uint256 tokenId, address adventure, bool booted)
        internal
    {
        address tokenOwner = ownerOf(tokenId);
        uint256 questCount = getQuestCount(tokenId, adventure);

        for (uint256 i = 0; i < questCount; ++i) {
            emit
                QuestUpdated(tokenId, tokenOwner, adventure, quests[tokenId][adventure][i].questId, false, booted);
        }
        delete quests[tokenId][adventure];
    }

    /// @dev By default, tokens that are participating in quests are transferrable.  However, if a token is participating
    /// in a quest on an adventure that was designated as a token locker, the transfer will revert and keep the token
    /// locked.
    function _beforeTokenTransfer(
        address, /*from*/
        address, /*to*/
        uint256 tokenId
    )
        internal
        virtual
        override
    {
        address[] memory whitelistedAdventureList_ = whitelistedAdventureList;

        for (uint256 i = 0; i < whitelistedAdventureList_.length; ++i) {
            address adventure = whitelistedAdventureList_[i];
            if (getQuestCount(tokenId, adventure) > 0) {
                require(!whitelistedAdventures[adventure].questsLockTokens, "An active quest is preventing transfers");
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/common/ERC2981.sol)

pragma solidity ^0.8.0;

import "../../interfaces/IERC2981.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the NFT Royalty Standard, a standardized way to retrieve royalty payment information.
 *
 * Royalty information can be specified globally for all token ids via {_setDefaultRoyalty}, and/or individually for
 * specific token ids via {_setTokenRoyalty}. The latter takes precedence over the first.
 *
 * Royalty is specified as a fraction of sale price. {_feeDenominator} is overridable but defaults to 10000, meaning the
 * fee is specified in basis points by default.
 *
 * IMPORTANT: ERC-2981 only specifies a way to signal royalty information and does not enforce its payment. See
 * https://eips.ethereum.org/EIPS/eip-2981#optional-royalty-payments[Rationale] in the EIP. Marketplaces are expected to
 * voluntarily pay royalties together with sales, but note that this standard is not yet widely supported.
 *
 * _Available since v4.5._
 */
abstract contract ERC2981 is IERC2981, ERC165 {
    struct RoyaltyInfo {
        address receiver;
        uint96 royaltyFraction;
    }

    RoyaltyInfo private _defaultRoyaltyInfo;
    mapping(uint256 => RoyaltyInfo) private _tokenRoyaltyInfo;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC165) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @inheritdoc IERC2981
     */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) public view virtual override returns (address, uint256) {
        RoyaltyInfo memory royalty = _tokenRoyaltyInfo[_tokenId];

        if (royalty.receiver == address(0)) {
            royalty = _defaultRoyaltyInfo;
        }

        uint256 royaltyAmount = (_salePrice * royalty.royaltyFraction) / _feeDenominator();

        return (royalty.receiver, royaltyAmount);
    }

    /**
     * @dev The denominator with which to interpret the fee set in {_setTokenRoyalty} and {_setDefaultRoyalty} as a
     * fraction of the sale price. Defaults to 10000 so fees are expressed in basis points, but may be customized by an
     * override.
     */
    function _feeDenominator() internal pure virtual returns (uint96) {
        return 10000;
    }

    /**
     * @dev Sets the royalty information that all ids in this contract will default to.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setDefaultRoyalty(address receiver, uint96 feeNumerator) internal virtual {
        require(feeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: invalid receiver");

        _defaultRoyaltyInfo = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Removes default royalty information.
     */
    function _deleteDefaultRoyalty() internal virtual {
        delete _defaultRoyaltyInfo;
    }

    /**
     * @dev Sets the royalty information for a specific token id, overriding the global default.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) internal virtual {
        require(feeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: Invalid parameters");

        _tokenRoyaltyInfo[tokenId] = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Resets royalty information for the token id back to the global default.
     */
    function _resetTokenRoyalty(uint256 tokenId) internal virtual {
        delete _tokenRoyaltyInfo[tokenId];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

abstract contract AdventurePermissions is Ownable {
    struct AdventureDetails {
        bool isWhitelisted;
        bool questsLockTokens;
        uint128 arrayIndex;
    }

    /// @dev Emitted when the adventure whitelist is updated
    event AdventureWhitelistUpdated(address indexed adventure, bool whitelisted);

    /// @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets, for special in-game adventures.
    event AdventureApprovalForAll(
        address indexed tokenOwner,
        address indexed operator,
        bool approved
    );

    /// @dev Whitelist array for iteration
    address[] public whitelistedAdventureList;

    /// @dev Whitelist mapping
    mapping(address => AdventureDetails) public whitelistedAdventures;

    /// @dev Mapping from owner to operator approvals for special gameplay behavior
    mapping(address => mapping(address => bool)) private
        _operatorAdventureApprovals;

    modifier onlyAdventure() {
        require(isAdventureWhitelisted(_msgSender()), "Not an adventure.");
        _;
    }

    /// @notice Returns whether the specified account is a whitelisted adventure
    function isAdventureWhitelisted(address account)
        public
        view
        returns (bool)
    {
        return whitelistedAdventures[account].isWhitelisted;
    }

    /// @notice Whitelists an adventure and specifies whether or not the quests in that adventure lock token transfers
    function whitelistAdventure(address adventure, bool questsLockTokens)
        external
        onlyOwner
    {
        require(!whitelistedAdventures[adventure].isWhitelisted, "Already whitelisted");
        whitelistedAdventures[adventure].isWhitelisted = true;
        whitelistedAdventures[adventure].questsLockTokens = questsLockTokens;
        whitelistedAdventures[adventure].arrayIndex =
            uint128(whitelistedAdventureList.length);
        whitelistedAdventureList.push(adventure);

        emit AdventureWhitelistUpdated(adventure, true);
    }

    /// @notice Removes an adventure from the whitelist
    function unwhitelistAdventure(address adventure) external onlyOwner {
        require(whitelistedAdventures[adventure].isWhitelisted, "Not whitelisted");

        uint128 itemPositionToDelete =
            whitelistedAdventures[adventure].arrayIndex;
        whitelistedAdventureList[itemPositionToDelete] =
            whitelistedAdventureList[whitelistedAdventureList.length - 1];
        whitelistedAdventures[whitelistedAdventureList[itemPositionToDelete]]
        .arrayIndex = itemPositionToDelete;

        whitelistedAdventureList.pop();
        delete whitelistedAdventures[adventure];

        emit AdventureWhitelistUpdated(adventure, false);
    }

    /// @notice Similar to {IERC721-setApprovalForAll}, but for special in-game adventures only
    function setAdventuresApprovedForAll(address operator, bool approved)
        public
    {
        _setAdventuresApprovedForAll(_msgSender(), operator, approved);
    }

    /// @notice Similar to {IERC721-isApprovedForAll}, but for special in-game adventures only
    function areAdventuresApprovedForAll(address owner, address operator)
        public
        view
        returns (bool)
    {
        return _operatorAdventureApprovals[owner][operator];
    }

    /// @dev Approve `operator` to operate on all of `owner` tokens for special in-game adventures only
    function _setAdventuresApprovedForAll(
        address tokenOwner,
        address operator,
        bool approved
    )
        internal
    {
        require(tokenOwner != operator, "approve to caller");
        _operatorAdventureApprovals[tokenOwner][operator] = approved;
        emit AdventureApprovalForAll(tokenOwner, operator, approved);
    }

    /// Modify to remove individual approval check
    /// @dev Returns whether `spender` is allowed to manage `tokenId`, for special in-game adventures only.
    function _isApprovedForAdventure(address spender, uint256 tokenId)
        internal
        view
        virtual
        returns (bool)
    {
        address tokenOwner = IERC721(address(this)).ownerOf(tokenId);
        return (areAdventuresApprovedForAll(tokenOwner, spender));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Quest.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IQuestStaking is IERC165 {
    /**
     * @dev Emitted when a token enters or exists a quest
     */
    event QuestUpdated(
        uint256 indexed tokenId,
        address indexed tokenOwner,
        address indexed adventure,
        uint256 questId,
        bool active,
        bool booted
    );

    /**
     * @notice Allows an authorized game contract to transfer a player's token if they have opted in
     */
    function adventureTransferFrom(address from, address to, uint256 tokenId)
        external;

    /**
     * @notice Allows an authorized game contract to safe transfer a player's token if they have opted in
     */
    function adventureSafeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    )
        external;

    /**
     * @notice Allows an authorized game contract to burn a player's token if they have opted in
     */
    function adventureBurn(uint256 tokenId) external;

    /**
     * @notice Allows an authorized game contract to stake a player's token into a quest if they have opted in
     */
    function enterQuest(uint256 tokenId, uint256 questId) external;

    /**
     * @notice Allows an authorized game contract to unstake a player's token from a quest if they have opted in
     */
    function exitQuest(uint256 tokenId, uint256 questId) external;

    /**
     * @notice Returns the number of quests a token is actively participating in for a specified adventure
     */
    function getQuestCount(uint256 tokenId, address adventure)
        external
        view
        returns (uint256);

    /**
     * @notice Returns the amount of time a token has been participating in the specified quest
     */
    function getTimeOnQuest(uint256 tokenId, address adventure, uint256 questId)
        external
        view
        returns (uint256);

    /**
     * @notice Returns whether or not a token is currently participating in the specified quest as well as the time it was started and the quest index
     */
    function isParticipatingInQuest(
        uint256 tokenId,
        address adventure,
        uint256 questId
    )
        external
        view
        returns (
            bool participatingInQuest,
            uint256 startTimestamp,
            uint256 index
        );

    /**
     * @notice Returns a list of all active quests for the specified token id and adventure
     */
    function getActiveQuests(uint256 tokenId, address adventure)
        external
        view
        returns (Quest[] memory activeQuests);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/ERC721.sol)

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
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: invalid token ID");
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
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
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
            "ERC721: approve caller is not token owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

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
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");

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
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
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
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
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
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
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
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
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
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
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
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
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
pragma solidity ^0.8.9;

struct Quest {
    uint64 questId;
    uint64 startTimestamp;
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
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
// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

library Bloodlines {
    /// @notice 1 => Rogue, 2 => Warrior, 3 => Royal
    enum Bloodline {
        None,
        Rogue,
        Warrior,
        Royal
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @dev Required interface of a contract that complies with the adventure/quest system that is permitted to interact with an AdventureERC721.
 */
interface IAdventure is IERC165 {
    /**
     * @dev Returns whether or not quests on this adventure lock tokens.
     * Developers of adventure contract should ensure that this is immutable
     * after deployment of the adventure contract.  Failure to do so
     * can lead to error that deadlock token transfers.
     */
    function questsLockTokens() external view returns (bool);

    /**
     * @dev A callback function that AdventureERC721 must invoke when a quest has been successfully entered.
     * Throws if the caller is not an expected AdventureERC721 contract designed to work with the Adventure.
     * Not permitted to throw in any other case, as this could lead to tokens being locked in quests.
     */
    function onQuestEntered(
        address adventurer,
        uint256 tokenId,
        uint256 questId
    )
        external;

    /**
     * @dev A callback function that AdventureERC721 must invoke when a quest has been successfully exited.
     * Throws if the caller is not an expected AdventureERC721 contract designed to work with the Adventure.
     * Not permitted to throw in any other case, as this could lead to tokens being locked in quests.
     */
    function onQuestExited(
        address adventurer,
        uint256 tokenId,
        uint256 questId,
        uint256 questStartTimestamp
    )
        external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./Bloodlines.sol";

/**
 * @dev Required interface of mintable hero contracts.
 */
interface IMintableHero {
    /**
     * @notice Mints a hero with a specified token id and genesis token id
     */
    function mintHero(address to, uint256 tokenId, uint256 genesisTokenId)
        external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./IQuestStaking.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/**
 * @dev An interface for ERC-721s that implement IQuestStaking
 */
interface IQuestStakingERC721 is IERC721, IQuestStaking {}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

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
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
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
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
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
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/draft-EIP712.sol)

pragma solidity ^0.8.0;

import "./ECDSA.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712 {
    /* solhint-disable var-name-mixedcase */
    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;
    address private immutable _CACHED_THIS;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
        _CACHED_THIS = address(this);
        _TYPE_HASH = typeHash;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (address(this) == _CACHED_THIS && block.chainid == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.3) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}