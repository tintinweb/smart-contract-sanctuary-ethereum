// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {ERC721A} from "@erc721a/contracts/ERC721A.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

import {LibPRNG} from "../utils/LibPRNG.sol";
import {Utils} from "../utils/Utils.sol";
import {MoonCalculations} from "../moon/MoonCalculations.sol";
import {MoonRenderer} from "../moon/MoonRenderer.sol";
import {MoonSvg} from "../moon/MoonSvg.sol";
import {MoonConfig} from "../moon/MoonConfig.sol";
import {DynamicNftRegistryInterface} from "../interfaces/dynamicNftRegistry/DynamicNftRegistryInterface.sol";
import {AlienArtBase, MoonImageConfig} from "../interfaces/alienArt/AlienArtBase.sol";
import {AlienArtConstellation} from "../alienArt/constellation/AlienArtConstellation.sol";
import {ERC1155TokenReceiver} from "../ext/ERC1155.sol";
import {MoonNFTEventsAndErrors} from "./MoonNFTEventsAndErrors.sol";
import {Ownable} from "../ext/Ownable.sol";
import {IERC2981} from "../interfaces/ext/IERC2981.sol";
import {IERC165} from "../interfaces/ext/IERC165.sol";
import {DefaultOperatorFilterer} from "../ext/DefaultOperatorFilterer.sol";

/*
███╗░░██╗░█████╗░███╗░░██╗
████╗░██║██╔══██╗████╗░██║
██╔██╗██║██║░░██║██╔██╗██║
██║╚████║██║░░██║██║╚████║
██║░╚███║╚█████╔╝██║░╚███║
╚═╝░░╚══╝░╚════╝░╚═╝░░╚══╝

███████╗██╗░░░██╗███╗░░██╗░██████╗░██╗██████╗░██╗░░░░░███████╗
██╔════╝██║░░░██║████╗░██║██╔════╝░██║██╔══██╗██║░░░░░██╔════╝
█████╗░░██║░░░██║██╔██╗██║██║░░██╗░██║██████╦╝██║░░░░░█████╗░░
██╔══╝░░██║░░░██║██║╚████║██║░░╚██╗██║██╔══██╗██║░░░░░██╔══╝░░
██║░░░░░╚██████╔╝██║░╚███║╚██████╔╝██║██████╦╝███████╗███████╗
╚═╝░░░░░░╚═════╝░╚═╝░░╚══╝░╚═════╝░╚═╝╚═════╝░╚══════╝╚══════╝

███╗░░░███╗░█████╗░░█████╗░███╗░░██╗░██████╗
████╗░████║██╔══██╗██╔══██╗████╗░██║██╔════╝
██╔████╔██║██║░░██║██║░░██║██╔██╗██║╚█████╗░
██║╚██╔╝██║██║░░██║██║░░██║██║╚████║░╚═══██╗
██║░╚═╝░██║╚█████╔╝╚█████╔╝██║░╚███║██████╔╝
*/

/// @title NonFungibleMoons
/// @author Aspyn Palatnick (aspyn.eth, stuckinaboot.eth)
/// @notice Interactive on-chain generative moon NFTs with art that closely mirrors the phase of
/// the real world moon. These NFTs support on-chain art composition, art regeneration, and mint referrals.
contract NonFungibleMoons is
    DefaultOperatorFilterer,
    ERC721A,
    IERC2981,
    ERC1155TokenReceiver,
    Ownable,
    MoonNFTEventsAndErrors
{
    using LibPRNG for LibPRNG.PRNG;

    uint256 public constant MAX_SUPPLY = 513;
    uint256 public constant PRICE = 0.04 ether;

    address payable internal constant VAULT_ADDRESS =
        payable(0x39Ab90066cec746A032D67e4fe3378f16294CF6b);

    // On mint, PRICE / FRACTION_OF_PRICE_FOR_REFERRAL will go to referrals
    uint256 internal constant FRACTION_OF_PRICE_FOR_REFERRAL = 4;

    // Maps moon token id to randomness seed
    mapping(uint256 => bytes32) public moonSeeds;
    // Maps moon token id to number of regenerates used by current owner
    mapping(uint256 => uint8) public regeneratesUsedByCurrentOwner;
    uint8 internal constant MAX_REGENERATES_PER_OWNER = 3;
    uint64 internal constant COOLDOWN_PERIOD = 120;

    address public dynamicNftRegistryAddress;
    address public defaultAlienArtAddress;

    // Mapping from token ID to alien art
    mapping(uint256 => address) public alienArtAddressMap;

    uint256 internal constant INTERVAL_BETWEEN_ANIMATION_SAMPLES =
        MoonCalculations.LUNAR_MONTH_LENGTH_IN_MS / 120;

    /***********************************
     ** Welcome to Non-Fungible Moons **
     ***********************************/

    constructor(
        string memory _name,
        string memory _symbol,
        address _defaultAlienArtAddress
    ) ERC721A(_name, _symbol) {
        // Set default alien art contract, which should be the constellations address
        defaultAlienArtAddress = _defaultAlienArtAddress;
    }

    /*************************************************************
     ** Collect moons and explore the potential of on-chain art **
     *************************************************************/

    /// @notice Mint NFT.
    /// @param amount amount of token that the sender wants to mint.
    function mint(uint256 amount) external payable {
        _mintCore(amount);
    }

    function _mintCore(uint256 amount) internal returns (uint256) {
        // Checks

        // Enforce basic mint checks
        if (MAX_SUPPLY < _nextTokenId() + amount) {
            revert MaxSupplyReached();
        }
        if (msg.value != PRICE * amount) {
            revert WrongEtherAmount();
        }

        // Effects
        uint256 nextMoonTokenIdToBeMinted = _nextTokenId();

        // Store moon seeds
        // NOTE: we do not need to set regenerates used for these tokens (regeneratesUsedByCurrentOwner) since the
        // regenerates used for newly minted token ids will default to 0
        for (
            uint256 tokenId = nextMoonTokenIdToBeMinted;
            tokenId < nextMoonTokenIdToBeMinted + amount;
            ++tokenId
        ) {
            moonSeeds[tokenId] = MoonConfig.getMoonSeed(tokenId);
        }

        // Mint moons
        _mint(msg.sender, amount);

        // Interactions

        // Mint constellations
        AlienArtConstellation(defaultAlienArtAddress).mint(
            nextMoonTokenIdToBeMinted,
            amount
        );

        return nextMoonTokenIdToBeMinted;
    }

    /**************************************************************
     ** Once you own a moon, earn on-chain mint referral rewards **
     **************************************************************/

    /// @notice Mint NFT with referrer.
    /// @param amount amount of token that the sender wants to mint.
    /// @param referrer referrer who will receive part of the payment.
    /// @param referrerTokenId token that referrer owns.
    function mintWithReferrer(
        uint256 amount,
        address payable referrer,
        uint256 referrerTokenId
    ) public payable {
        uint256 nextMoonTokenIdToBeMinted = _mintCore(amount);

        // Pay out referral funds if the following conditions are met
        if (
            // 1. Referrer is not 0 address
            referrer != address(0) &&
            // 2. Referrer is not self
            referrer != msg.sender &&
            // 3. Referrer owns the input token
            referrer == ownerOf(referrerTokenId)
        ) {
            // Get referral amounts
            (uint256 referrerValue, uint256 referredValue) = getReferralAmounts(
                referrer,
                msg.sender,
                msg.value
            );

            // Emit minted with referrer event
            emit MintedWithReferrer(
                referrer,
                referrerTokenId,
                msg.sender,
                nextMoonTokenIdToBeMinted,
                amount,
                referrerValue,
                referredValue
            );

            // Transfer ETH to referrer and referred
            referrer.transfer(referrerValue);
            payable(msg.sender).transfer(referredValue);
        }
    }

    /// @notice Get amounts that should be paid out to referrer and referred.
    /// @param referrer referrer who will receive part of the payment.
    /// @param referred referred who will receive part of the payment.
    /// @param value value of the mint.
    /// @return referrerValue value to be paid to referrer, referredValue value to be paid to referred.
    function getReferralAmounts(
        address referrer,
        address referred,
        uint256 value
    ) public view returns (uint256 referrerValue, uint256 referredValue) {
        // Amount from the value that will be distributed between the referrer and referred
        uint256 amtWithheldForReferrals = value /
            FRACTION_OF_PRICE_FOR_REFERRAL;

        LibPRNG.PRNG memory prng;
        prng.seed(
            keccak256(abi.encodePacked(block.difficulty, referrer, referred))
        );
        // Note: integer division will imply the result is truncated (e.g. 5 / 2 = 2).
        // This is the expected behavior.
        referredValue =
            // Random value ranging from 0 to 10000
            (amtWithheldForReferrals * prng.uniform(10001)) /
            10000;
        referrerValue = amtWithheldForReferrals - referredValue;
    }

    /****************************************************
     ** Alter the Alien Art for your moons at any time **
     ****************************************************/

    /// @notice Set alien art address for particular tokens.
    /// @param tokenIds token ids.
    /// @param alienArtAddress alien art contract.
    function setAlienArtAddresses(
        uint256[] calldata tokenIds,
        address alienArtAddress
    ) external {
        if (tokenIds.length > MAX_SUPPLY) {
            revert MaxSupplyReached();
        }

        // If alien art address is not null address, validate that alien
        // art address is pointing to a valid alien art contract
        if (
            alienArtAddress != address(0) &&
            !AlienArtBase(alienArtAddress).supportsInterface(
                type(AlienArtBase).interfaceId
            )
        ) {
            revert AlienArtContractFailedValidation();
        }

        for (uint256 i = 0; i < tokenIds.length; ++i) {
            uint256 tokenId = tokenIds[i];
            if (ownerOf(tokenId) != msg.sender) {
                revert OwnerNotMsgSender();
            }

            alienArtAddressMap[tokenId] = alienArtAddress;
            emit AlienArtAddressUpdated(tokenId, alienArtAddress);
        }
    }

    /// @notice Get alien art address for a particular token.
    /// @param tokenId token id.
    /// @return tuple containing (True if default alien art contract is used; false otherwise, alien art contract).
    function getAlienArtContractForToken(uint256 tokenId)
        external
        view
        returns (bool, AlienArtBase)
    {
        AlienArtBase alienArtContract;
        if (alienArtAddressMap[tokenId] != address(0)) {
            // Use defined alien art contract if alien art address for token is not 0
            alienArtContract = AlienArtBase(alienArtAddressMap[tokenId]);
        } else {
            // Use default alien art contract if alien art address for token is 0
            alienArtContract = AlienArtBase(defaultAlienArtAddress);
        }

        // Default alien art is used if the alien art address is
        // the default alien art address or if alien art address is 0 address
        return (
            alienArtAddressMap[tokenId] == defaultAlienArtAddress ||
                alienArtAddressMap[tokenId] == address(0),
            alienArtContract
        );
    }

    /// @notice Get alien art values.
    /// @param alienArtContract alien art contract to get values from.
    /// @param tokenId token id.
    /// @param rotationInDegrees rotation in degrees.
    /// @return alien art image, alien art moon filter, alien art trait.
    function getAlienArtValues(
        AlienArtBase alienArtContract,
        uint256 tokenId,
        uint256 rotationInDegrees
    )
        internal
        view
        returns (
            string memory,
            string memory,
            string memory
        )
    {
        bytes32 seed = moonSeeds[tokenId];
        MoonImageConfig memory config = MoonConfig.getMoonConfig(seed);
        return (
            alienArtContract.getArt(tokenId, seed, config, rotationInDegrees),
            alienArtContract.getMoonFilter(
                tokenId,
                seed,
                config,
                rotationInDegrees
            ),
            alienArtContract.getTraits(tokenId, seed, config, rotationInDegrees)
        );
    }

    /**************************
     ** Regenerate your moon **
     **************************/

    /// @notice Regenerate a moon's seed, which will permanently regenerate the moon's art and traits.
    /// @param tokenId moon token id.
    function regenerateMoon(uint256 tokenId) external payable {
        // Checks
        if (
            regeneratesUsedByCurrentOwner[tokenId] == MAX_REGENERATES_PER_OWNER
        ) {
            revert NoRegenerationsRemaining();
        }
        if (msg.value != PRICE) {
            revert WrongEtherAmount();
        }
        if (ownerOf(tokenId) != msg.sender) {
            revert OwnerNotMsgSender();
        }

        // Effects

        // Update moon seed
        bytes32 originalMoonSeed = moonSeeds[tokenId];
        moonSeeds[tokenId] = MoonConfig.getMoonSeed(tokenId);
        // Increment regenerates used
        ++regeneratesUsedByCurrentOwner[tokenId];

        // Emit regeneration event
        emit MoonRegenerated(
            msg.sender,
            tokenId,
            moonSeeds[tokenId],
            originalMoonSeed,
            regeneratesUsedByCurrentOwner[tokenId]
        );

        // Interactions

        // Burn existing constellation and mint new one
        AlienArtConstellation(defaultAlienArtAddress).burnAndMint(tokenId);

        // Update dynamic NFT registry if present
        if (dynamicNftRegistryAddress != address(0)) {
            DynamicNftRegistryInterface(dynamicNftRegistryAddress).updateToken(
                address(this),
                tokenId,
                COOLDOWN_PERIOD,
                false
            );
        }
    }

    function _afterTokenTransfers(
        address,
        address,
        uint256 startTokenId,
        uint256 quantity
    ) internal override {
        // After token transfer, reset regenerates for the new owner
        for (
            uint256 tokenId = startTokenId;
            tokenId < startTokenId + quantity;
            ++tokenId
        ) {
            regeneratesUsedByCurrentOwner[tokenId] = 0;
        }
    }

    /*********************************
     ** Withdraw funds to the vault **
     *********************************/

    /// @notice Withdraw all ETH from the contract to the vault.
    function withdraw() external {
        VAULT_ADDRESS.transfer(address(this).balance);
    }

    /***************************************************************
     ** Generate on-chain SVG and interactive HTML token metadata **
     ***************************************************************/

    /// @notice Get token URI for a particular token.
    /// @param tokenId token id.
    /// @return token uri.
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        ownerOf(tokenId);

        (bool defaultAlienArt, AlienArtBase alienArtContract) = this
            .getAlienArtContractForToken(tokenId);

        uint256 timestamp = block.timestamp * 1e3;
        (, , string memory alienArtTrait) = getAlienArtValues(
            alienArtContract,
            tokenId,
            MoonRenderer.getLunarCycleDistanceFromDateAsRotationInDegrees(
                timestamp
            )
        );

        bytes32 moonSeed = moonSeeds[tokenId];
        string memory traits = MoonConfig.getMoonTraits(
            moonSeed,
            alienArtTrait,
            alienArtContract.getArtName(),
            Strings.toHexString(address(alienArtContract)),
            defaultAlienArt
        );

        string memory moonName = string.concat(
            "Non-Fungible Moon #",
            Utils.uint2str(tokenId)
        );

        (
            string memory moonSvg,
            string memory moonAnimation
        ) = generateOnChainMoon(tokenId, timestamp, alienArtContract);

        return
            Utils.formatTokenURI(
                Utils.svgToImageURI(moonSvg),
                Utils.htmlToURI(moonAnimation),
                moonName,
                "Non-Fungible Moons are on-chain generative moon NFTs. All moon art is generated on-chain and updates in real-time, based on current block time and using an on-chain SVG library, to closely mirror the phase of the moon in the real world.",
                traits
            );
    }

    // Generate moon svg image and interactive moon animation html based on initial timestamp
    function generateOnChainMoon(
        uint256 tokenId,
        uint256 initialTimestamp,
        AlienArtBase alienArtContract
    ) internal view returns (string memory, string memory) {
        bytes32 moonSeed = moonSeeds[tokenId];

        string memory moonSvgText;
        string memory firstSvg;

        for (
            uint256 timestamp = initialTimestamp;
            timestamp <
            initialTimestamp + MoonCalculations.LUNAR_MONTH_LENGTH_IN_MS;
            timestamp += INTERVAL_BETWEEN_ANIMATION_SAMPLES
        ) {
            (
                string memory alienArt,
                string memory alienArtMoonFilter,

            ) = getAlienArtValues(
                    alienArtContract,
                    tokenId,
                    MoonRenderer
                        .getLunarCycleDistanceFromDateAsRotationInDegrees(
                            timestamp
                        )
                );

            string memory moonSvg = MoonRenderer.renderWithTimestamp(
                moonSeed,
                timestamp,
                alienArt,
                alienArtMoonFilter
            );

            if (timestamp == initialTimestamp) {
                firstSvg = moonSvg;
                moonSvgText = string.concat(
                    '<!DOCTYPE html><html><head><style type="text/css">html{overflow:hidden}body{margin:0}#moon{display:block;margin:auto}</style></head><body><div id="moonDiv"></div><script>let gs=[`',
                    moonSvg,
                    "`"
                );
            } else {
                moonSvgText = string.concat(moonSvgText, ",`", moonSvg, "`");
            }
        }

        return (
            firstSvg,
            string.concat(
                moonSvgText,
                '];let $=document.getElementById.bind(document);$("moonDiv").innerHTML=gs[0];let mo=$("moonDiv");let u=e=>{let t=$("moon").getBoundingClientRect();$("moonDiv").innerHTML=gs[Math.max(0,Math.min(Math.floor(((e-t.left)/t.width)*gs.length),gs.length-1))];};mo.onmousemove=e=>u(e.clientX);mo.addEventListener("touchstart",e=>{let t=e=>u(e.touches[0].clientX);n=()=>{e.target.removeEventListener("touchmove",t),e.target.removeEventListener("touchend",n);};e.target.addEventListener("touchmove",t);e.target.addEventListener("touchend",n);});</script></body></html>'
            )
        );
    }

    /**************************
     ** Dynamic NFT registry **
     **************************/

    /// @notice Set up dynamic NFT registry and add default alien art as an allowed updater of this token.
    /// @param _dynamicNftRegistryAddress dynamic NFT registry address.
    function setupDynamicNftRegistry(address _dynamicNftRegistryAddress)
        external
        onlyOwner
    {
        dynamicNftRegistryAddress = _dynamicNftRegistryAddress;
        DynamicNftRegistryInterface registry = DynamicNftRegistryInterface(
            dynamicNftRegistryAddress
        );
        // Register this token with dynamic nft registry
        registry.registerToken(address(this));
        // Add default alien art as an allowed updater of this token
        registry.addAllowedUpdater(address(this), defaultAlienArtAddress);
        // Add this as an allowed updater of this token
        registry.addAllowedUpdater(address(this), address(this));
    }

    /*********************
     ** Operator filter **
     *********************/

    function setApprovalForAll(address operator, bool approved)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        payable
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    /*************************
     ** Royalty definitions **
     *************************/

    function royaltyInfo(uint256, uint256 salePrice)
        external
        pure
        returns (address receiver, uint256 royaltyAmount)
    {
        return (VAULT_ADDRESS, (salePrice * 250) / 10000);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC165, ERC721A)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /*************
     ** Tip jar **
     *************/

    receive() external payable {}
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.2.3
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import './IERC721A.sol';

/**
 * @dev Interface of ERC721 token receiver.
 */
interface ERC721A__IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

/**
 * @title ERC721A
 *
 * @dev Implementation of the [ERC721](https://eips.ethereum.org/EIPS/eip-721)
 * Non-Fungible Token Standard, including the Metadata extension.
 * Optimized for lower gas during batch mints.
 *
 * Token IDs are minted in sequential order (e.g. 0, 1, 2, 3, ...)
 * starting from `_startTokenId()`.
 *
 * Assumptions:
 *
 * - An owner cannot have more than 2**64 - 1 (max value of uint64) of supply.
 * - The maximum token ID cannot exceed 2**256 - 1 (max value of uint256).
 */
contract ERC721A is IERC721A {
    // Bypass for a `--via-ir` bug (https://github.com/chiru-labs/ERC721A/pull/364).
    struct TokenApprovalRef {
        address value;
    }

    // =============================================================
    //                           CONSTANTS
    // =============================================================

    // Mask of an entry in packed address data.
    uint256 private constant _BITMASK_ADDRESS_DATA_ENTRY = (1 << 64) - 1;

    // The bit position of `numberMinted` in packed address data.
    uint256 private constant _BITPOS_NUMBER_MINTED = 64;

    // The bit position of `numberBurned` in packed address data.
    uint256 private constant _BITPOS_NUMBER_BURNED = 128;

    // The bit position of `aux` in packed address data.
    uint256 private constant _BITPOS_AUX = 192;

    // Mask of all 256 bits in packed address data except the 64 bits for `aux`.
    uint256 private constant _BITMASK_AUX_COMPLEMENT = (1 << 192) - 1;

    // The bit position of `startTimestamp` in packed ownership.
    uint256 private constant _BITPOS_START_TIMESTAMP = 160;

    // The bit mask of the `burned` bit in packed ownership.
    uint256 private constant _BITMASK_BURNED = 1 << 224;

    // The bit position of the `nextInitialized` bit in packed ownership.
    uint256 private constant _BITPOS_NEXT_INITIALIZED = 225;

    // The bit mask of the `nextInitialized` bit in packed ownership.
    uint256 private constant _BITMASK_NEXT_INITIALIZED = 1 << 225;

    // The bit position of `extraData` in packed ownership.
    uint256 private constant _BITPOS_EXTRA_DATA = 232;

    // Mask of all 256 bits in a packed ownership except the 24 bits for `extraData`.
    uint256 private constant _BITMASK_EXTRA_DATA_COMPLEMENT = (1 << 232) - 1;

    // The mask of the lower 160 bits for addresses.
    uint256 private constant _BITMASK_ADDRESS = (1 << 160) - 1;

    // The maximum `quantity` that can be minted with {_mintERC2309}.
    // This limit is to prevent overflows on the address data entries.
    // For a limit of 5000, a total of 3.689e15 calls to {_mintERC2309}
    // is required to cause an overflow, which is unrealistic.
    uint256 private constant _MAX_MINT_ERC2309_QUANTITY_LIMIT = 5000;

    // The `Transfer` event signature is given by:
    // `keccak256(bytes("Transfer(address,address,uint256)"))`.
    bytes32 private constant _TRANSFER_EVENT_SIGNATURE =
        0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef;

    // =============================================================
    //                            STORAGE
    // =============================================================

    // The next token ID to be minted.
    uint256 private _currentIndex;

    // The number of tokens burned.
    uint256 private _burnCounter;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to ownership details
    // An empty struct value does not necessarily mean the token is unowned.
    // See {_packedOwnershipOf} implementation for details.
    //
    // Bits Layout:
    // - [0..159]   `addr`
    // - [160..223] `startTimestamp`
    // - [224]      `burned`
    // - [225]      `nextInitialized`
    // - [232..255] `extraData`
    mapping(uint256 => uint256) private _packedOwnerships;

    // Mapping owner address to address data.
    //
    // Bits Layout:
    // - [0..63]    `balance`
    // - [64..127]  `numberMinted`
    // - [128..191] `numberBurned`
    // - [192..255] `aux`
    mapping(address => uint256) private _packedAddressData;

    // Mapping from token ID to approved address.
    mapping(uint256 => TokenApprovalRef) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // =============================================================
    //                          CONSTRUCTOR
    // =============================================================

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _currentIndex = _startTokenId();
    }

    // =============================================================
    //                   TOKEN COUNTING OPERATIONS
    // =============================================================

    /**
     * @dev Returns the starting token ID.
     * To change the starting token ID, please override this function.
     */
    function _startTokenId() internal view virtual returns (uint256) {
        return 0;
    }

    /**
     * @dev Returns the next token ID to be minted.
     */
    function _nextTokenId() internal view virtual returns (uint256) {
        return _currentIndex;
    }

    /**
     * @dev Returns the total number of tokens in existence.
     * Burned tokens will reduce the count.
     * To get the total number of tokens minted, please see {_totalMinted}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        // Counter underflow is impossible as _burnCounter cannot be incremented
        // more than `_currentIndex - _startTokenId()` times.
        unchecked {
            return _currentIndex - _burnCounter - _startTokenId();
        }
    }

    /**
     * @dev Returns the total amount of tokens minted in the contract.
     */
    function _totalMinted() internal view virtual returns (uint256) {
        // Counter underflow is impossible as `_currentIndex` does not decrement,
        // and it is initialized to `_startTokenId()`.
        unchecked {
            return _currentIndex - _startTokenId();
        }
    }

    /**
     * @dev Returns the total number of tokens burned.
     */
    function _totalBurned() internal view virtual returns (uint256) {
        return _burnCounter;
    }

    // =============================================================
    //                    ADDRESS DATA OPERATIONS
    // =============================================================

    /**
     * @dev Returns the number of tokens in `owner`'s account.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        if (owner == address(0)) revert BalanceQueryForZeroAddress();
        return _packedAddressData[owner] & _BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the number of tokens minted by `owner`.
     */
    function _numberMinted(address owner) internal view returns (uint256) {
        return (_packedAddressData[owner] >> _BITPOS_NUMBER_MINTED) & _BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the number of tokens burned by or on behalf of `owner`.
     */
    function _numberBurned(address owner) internal view returns (uint256) {
        return (_packedAddressData[owner] >> _BITPOS_NUMBER_BURNED) & _BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the auxiliary data for `owner`. (e.g. number of whitelist mint slots used).
     */
    function _getAux(address owner) internal view returns (uint64) {
        return uint64(_packedAddressData[owner] >> _BITPOS_AUX);
    }

    /**
     * Sets the auxiliary data for `owner`. (e.g. number of whitelist mint slots used).
     * If there are multiple variables, please pack them into a uint64.
     */
    function _setAux(address owner, uint64 aux) internal virtual {
        uint256 packed = _packedAddressData[owner];
        uint256 auxCasted;
        // Cast `aux` with assembly to avoid redundant masking.
        assembly {
            auxCasted := aux
        }
        packed = (packed & _BITMASK_AUX_COMPLEMENT) | (auxCasted << _BITPOS_AUX);
        _packedAddressData[owner] = packed;
    }

    // =============================================================
    //                            IERC165
    // =============================================================

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * [EIP section](https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified)
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30000 gas.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        // The interface IDs are constants representing the first 4 bytes
        // of the XOR of all function selectors in the interface.
        // See: [ERC165](https://eips.ethereum.org/EIPS/eip-165)
        // (e.g. `bytes4(i.functionA.selector ^ i.functionB.selector ^ ...)`)
        return
            interfaceId == 0x01ffc9a7 || // ERC165 interface ID for ERC165.
            interfaceId == 0x80ac58cd || // ERC165 interface ID for ERC721.
            interfaceId == 0x5b5e139f; // ERC165 interface ID for ERC721Metadata.
    }

    // =============================================================
    //                        IERC721Metadata
    // =============================================================

    /**
     * @dev Returns the token collection name.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId))) : '';
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, it can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return '';
    }

    // =============================================================
    //                     OWNERSHIPS OPERATIONS
    // =============================================================

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        return address(uint160(_packedOwnershipOf(tokenId)));
    }

    /**
     * @dev Gas spent here starts off proportional to the maximum mint batch size.
     * It gradually moves to O(1) as tokens get transferred around over time.
     */
    function _ownershipOf(uint256 tokenId) internal view virtual returns (TokenOwnership memory) {
        return _unpackedOwnership(_packedOwnershipOf(tokenId));
    }

    /**
     * @dev Returns the unpacked `TokenOwnership` struct at `index`.
     */
    function _ownershipAt(uint256 index) internal view virtual returns (TokenOwnership memory) {
        return _unpackedOwnership(_packedOwnerships[index]);
    }

    /**
     * @dev Initializes the ownership slot minted at `index` for efficiency purposes.
     */
    function _initializeOwnershipAt(uint256 index) internal virtual {
        if (_packedOwnerships[index] == 0) {
            _packedOwnerships[index] = _packedOwnershipOf(index);
        }
    }

    /**
     * Returns the packed ownership data of `tokenId`.
     */
    function _packedOwnershipOf(uint256 tokenId) private view returns (uint256) {
        uint256 curr = tokenId;

        unchecked {
            if (_startTokenId() <= curr)
                if (curr < _currentIndex) {
                    uint256 packed = _packedOwnerships[curr];
                    // If not burned.
                    if (packed & _BITMASK_BURNED == 0) {
                        // Invariant:
                        // There will always be an initialized ownership slot
                        // (i.e. `ownership.addr != address(0) && ownership.burned == false`)
                        // before an unintialized ownership slot
                        // (i.e. `ownership.addr == address(0) && ownership.burned == false`)
                        // Hence, `curr` will not underflow.
                        //
                        // We can directly compare the packed value.
                        // If the address is zero, packed will be zero.
                        while (packed == 0) {
                            packed = _packedOwnerships[--curr];
                        }
                        return packed;
                    }
                }
        }
        revert OwnerQueryForNonexistentToken();
    }

    /**
     * @dev Returns the unpacked `TokenOwnership` struct from `packed`.
     */
    function _unpackedOwnership(uint256 packed) private pure returns (TokenOwnership memory ownership) {
        ownership.addr = address(uint160(packed));
        ownership.startTimestamp = uint64(packed >> _BITPOS_START_TIMESTAMP);
        ownership.burned = packed & _BITMASK_BURNED != 0;
        ownership.extraData = uint24(packed >> _BITPOS_EXTRA_DATA);
    }

    /**
     * @dev Packs ownership data into a single uint256.
     */
    function _packOwnershipData(address owner, uint256 flags) private view returns (uint256 result) {
        assembly {
            // Mask `owner` to the lower 160 bits, in case the upper bits somehow aren't clean.
            owner := and(owner, _BITMASK_ADDRESS)
            // `owner | (block.timestamp << _BITPOS_START_TIMESTAMP) | flags`.
            result := or(owner, or(shl(_BITPOS_START_TIMESTAMP, timestamp()), flags))
        }
    }

    /**
     * @dev Returns the `nextInitialized` flag set if `quantity` equals 1.
     */
    function _nextInitializedFlag(uint256 quantity) private pure returns (uint256 result) {
        // For branchless setting of the `nextInitialized` flag.
        assembly {
            // `(quantity == 1) << _BITPOS_NEXT_INITIALIZED`.
            result := shl(_BITPOS_NEXT_INITIALIZED, eq(quantity, 1))
        }
    }

    // =============================================================
    //                      APPROVAL OPERATIONS
    // =============================================================

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the
     * zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) public payable virtual override {
        address owner = ownerOf(tokenId);

        if (_msgSenderERC721A() != owner)
            if (!isApprovedForAll(owner, _msgSenderERC721A())) {
                revert ApprovalCallerNotOwnerNorApproved();
            }

        _tokenApprovals[tokenId].value = to;
        emit Approval(owner, to, tokenId);
    }

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        if (!_exists(tokenId)) revert ApprovalQueryForNonexistentToken();

        return _tokenApprovals[tokenId].value;
    }

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom}
     * for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _operatorApprovals[_msgSenderERC721A()][operator] = approved;
        emit ApprovalForAll(_msgSenderERC721A(), operator, approved);
    }

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted. See {_mint}.
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return
            _startTokenId() <= tokenId &&
            tokenId < _currentIndex && // If within bounds,
            _packedOwnerships[tokenId] & _BITMASK_BURNED == 0; // and not burned.
    }

    /**
     * @dev Returns whether `msgSender` is equal to `approvedAddress` or `owner`.
     */
    function _isSenderApprovedOrOwner(
        address approvedAddress,
        address owner,
        address msgSender
    ) private pure returns (bool result) {
        assembly {
            // Mask `owner` to the lower 160 bits, in case the upper bits somehow aren't clean.
            owner := and(owner, _BITMASK_ADDRESS)
            // Mask `msgSender` to the lower 160 bits, in case the upper bits somehow aren't clean.
            msgSender := and(msgSender, _BITMASK_ADDRESS)
            // `msgSender == owner || msgSender == approvedAddress`.
            result := or(eq(msgSender, owner), eq(msgSender, approvedAddress))
        }
    }

    /**
     * @dev Returns the storage slot and value for the approved address of `tokenId`.
     */
    function _getApprovedSlotAndAddress(uint256 tokenId)
        private
        view
        returns (uint256 approvedAddressSlot, address approvedAddress)
    {
        TokenApprovalRef storage tokenApproval = _tokenApprovals[tokenId];
        // The following is equivalent to `approvedAddress = _tokenApprovals[tokenId].value`.
        assembly {
            approvedAddressSlot := tokenApproval.slot
            approvedAddress := sload(approvedAddressSlot)
        }
    }

    // =============================================================
    //                      TRANSFER OPERATIONS
    // =============================================================

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token
     * by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable virtual override {
        uint256 prevOwnershipPacked = _packedOwnershipOf(tokenId);

        if (address(uint160(prevOwnershipPacked)) != from) revert TransferFromIncorrectOwner();

        (uint256 approvedAddressSlot, address approvedAddress) = _getApprovedSlotAndAddress(tokenId);

        // The nested ifs save around 20+ gas over a compound boolean condition.
        if (!_isSenderApprovedOrOwner(approvedAddress, from, _msgSenderERC721A()))
            if (!isApprovedForAll(from, _msgSenderERC721A())) revert TransferCallerNotOwnerNorApproved();

        if (to == address(0)) revert TransferToZeroAddress();

        _beforeTokenTransfers(from, to, tokenId, 1);

        // Clear approvals from the previous owner.
        assembly {
            if approvedAddress {
                // This is equivalent to `delete _tokenApprovals[tokenId]`.
                sstore(approvedAddressSlot, 0)
            }
        }

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as `tokenId` would have to be 2**256.
        unchecked {
            // We can directly increment and decrement the balances.
            --_packedAddressData[from]; // Updates: `balance -= 1`.
            ++_packedAddressData[to]; // Updates: `balance += 1`.

            // Updates:
            // - `address` to the next owner.
            // - `startTimestamp` to the timestamp of transfering.
            // - `burned` to `false`.
            // - `nextInitialized` to `true`.
            _packedOwnerships[tokenId] = _packOwnershipData(
                to,
                _BITMASK_NEXT_INITIALIZED | _nextExtraData(from, to, prevOwnershipPacked)
            );

            // If the next slot may not have been initialized (i.e. `nextInitialized == false`) .
            if (prevOwnershipPacked & _BITMASK_NEXT_INITIALIZED == 0) {
                uint256 nextTokenId = tokenId + 1;
                // If the next slot's address is zero and not burned (i.e. packed value is zero).
                if (_packedOwnerships[nextTokenId] == 0) {
                    // If the next slot is within bounds.
                    if (nextTokenId != _currentIndex) {
                        // Initialize the next slot to maintain correctness for `ownerOf(tokenId + 1)`.
                        _packedOwnerships[nextTokenId] = prevOwnershipPacked;
                    }
                }
            }
        }

        emit Transfer(from, to, tokenId);
        _afterTokenTransfers(from, to, tokenId, 1);
    }

    /**
     * @dev Equivalent to `safeTransferFrom(from, to, tokenId, '')`.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable virtual override {
        safeTransferFrom(from, to, tokenId, '');
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token
     * by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement
     * {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public payable virtual override {
        transferFrom(from, to, tokenId);
        if (to.code.length != 0)
            if (!_checkContractOnERC721Received(from, to, tokenId, _data)) {
                revert TransferToNonERC721ReceiverImplementer();
            }
    }

    /**
     * @dev Hook that is called before a set of serially-ordered token IDs
     * are about to be transferred. This includes minting.
     * And also called before burning one token.
     *
     * `startTokenId` - the first token ID to be transferred.
     * `quantity` - the amount to be transferred.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, `tokenId` will be burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}

    /**
     * @dev Hook that is called after a set of serially-ordered token IDs
     * have been transferred. This includes minting.
     * And also called after one token has been burned.
     *
     * `startTokenId` - the first token ID to be transferred.
     * `quantity` - the amount to be transferred.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` has been
     * transferred to `to`.
     * - When `from` is zero, `tokenId` has been minted for `to`.
     * - When `to` is zero, `tokenId` has been burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _afterTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}

    /**
     * @dev Private function to invoke {IERC721Receiver-onERC721Received} on a target contract.
     *
     * `from` - Previous owner of the given token ID.
     * `to` - Target address that will receive the token.
     * `tokenId` - Token ID to be transferred.
     * `_data` - Optional data to send along with the call.
     *
     * Returns whether the call correctly returned the expected magic value.
     */
    function _checkContractOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        try ERC721A__IERC721Receiver(to).onERC721Received(_msgSenderERC721A(), from, tokenId, _data) returns (
            bytes4 retval
        ) {
            return retval == ERC721A__IERC721Receiver(to).onERC721Received.selector;
        } catch (bytes memory reason) {
            if (reason.length == 0) {
                revert TransferToNonERC721ReceiverImplementer();
            } else {
                assembly {
                    revert(add(32, reason), mload(reason))
                }
            }
        }
    }

    // =============================================================
    //                        MINT OPERATIONS
    // =============================================================

    /**
     * @dev Mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `quantity` must be greater than 0.
     *
     * Emits a {Transfer} event for each mint.
     */
    function _mint(address to, uint256 quantity) internal virtual {
        uint256 startTokenId = _currentIndex;
        if (quantity == 0) revert MintZeroQuantity();

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are incredibly unrealistic.
        // `balance` and `numberMinted` have a maximum limit of 2**64.
        // `tokenId` has a maximum limit of 2**256.
        unchecked {
            // Updates:
            // - `balance += quantity`.
            // - `numberMinted += quantity`.
            //
            // We can directly add to the `balance` and `numberMinted`.
            _packedAddressData[to] += quantity * ((1 << _BITPOS_NUMBER_MINTED) | 1);

            // Updates:
            // - `address` to the owner.
            // - `startTimestamp` to the timestamp of minting.
            // - `burned` to `false`.
            // - `nextInitialized` to `quantity == 1`.
            _packedOwnerships[startTokenId] = _packOwnershipData(
                to,
                _nextInitializedFlag(quantity) | _nextExtraData(address(0), to, 0)
            );

            uint256 toMasked;
            uint256 end = startTokenId + quantity;

            // Use assembly to loop and emit the `Transfer` event for gas savings.
            // The duplicated `log4` removes an extra check and reduces stack juggling.
            // The assembly, together with the surrounding Solidity code, have been
            // delicately arranged to nudge the compiler into producing optimized opcodes.
            assembly {
                // Mask `to` to the lower 160 bits, in case the upper bits somehow aren't clean.
                toMasked := and(to, _BITMASK_ADDRESS)
                // Emit the `Transfer` event.
                log4(
                    0, // Start of data (0, since no data).
                    0, // End of data (0, since no data).
                    _TRANSFER_EVENT_SIGNATURE, // Signature.
                    0, // `address(0)`.
                    toMasked, // `to`.
                    startTokenId // `tokenId`.
                )

                // The `iszero(eq(,))` check ensures that large values of `quantity`
                // that overflows uint256 will make the loop run out of gas.
                // The compiler will optimize the `iszero` away for performance.
                for {
                    let tokenId := add(startTokenId, 1)
                } iszero(eq(tokenId, end)) {
                    tokenId := add(tokenId, 1)
                } {
                    // Emit the `Transfer` event. Similar to above.
                    log4(0, 0, _TRANSFER_EVENT_SIGNATURE, 0, toMasked, tokenId)
                }
            }
            if (toMasked == 0) revert MintToZeroAddress();

            _currentIndex = end;
        }
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    /**
     * @dev Mints `quantity` tokens and transfers them to `to`.
     *
     * This function is intended for efficient minting only during contract creation.
     *
     * It emits only one {ConsecutiveTransfer} as defined in
     * [ERC2309](https://eips.ethereum.org/EIPS/eip-2309),
     * instead of a sequence of {Transfer} event(s).
     *
     * Calling this function outside of contract creation WILL make your contract
     * non-compliant with the ERC721 standard.
     * For full ERC721 compliance, substituting ERC721 {Transfer} event(s) with the ERC2309
     * {ConsecutiveTransfer} event is only permissible during contract creation.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `quantity` must be greater than 0.
     *
     * Emits a {ConsecutiveTransfer} event.
     */
    function _mintERC2309(address to, uint256 quantity) internal virtual {
        uint256 startTokenId = _currentIndex;
        if (to == address(0)) revert MintToZeroAddress();
        if (quantity == 0) revert MintZeroQuantity();
        if (quantity > _MAX_MINT_ERC2309_QUANTITY_LIMIT) revert MintERC2309QuantityExceedsLimit();

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are unrealistic due to the above check for `quantity` to be below the limit.
        unchecked {
            // Updates:
            // - `balance += quantity`.
            // - `numberMinted += quantity`.
            //
            // We can directly add to the `balance` and `numberMinted`.
            _packedAddressData[to] += quantity * ((1 << _BITPOS_NUMBER_MINTED) | 1);

            // Updates:
            // - `address` to the owner.
            // - `startTimestamp` to the timestamp of minting.
            // - `burned` to `false`.
            // - `nextInitialized` to `quantity == 1`.
            _packedOwnerships[startTokenId] = _packOwnershipData(
                to,
                _nextInitializedFlag(quantity) | _nextExtraData(address(0), to, 0)
            );

            emit ConsecutiveTransfer(startTokenId, startTokenId + quantity - 1, address(0), to);

            _currentIndex = startTokenId + quantity;
        }
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    /**
     * @dev Safely mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement
     * {IERC721Receiver-onERC721Received}, which is called for each safe transfer.
     * - `quantity` must be greater than 0.
     *
     * See {_mint}.
     *
     * Emits a {Transfer} event for each mint.
     */
    function _safeMint(
        address to,
        uint256 quantity,
        bytes memory _data
    ) internal virtual {
        _mint(to, quantity);

        unchecked {
            if (to.code.length != 0) {
                uint256 end = _currentIndex;
                uint256 index = end - quantity;
                do {
                    if (!_checkContractOnERC721Received(address(0), to, index++, _data)) {
                        revert TransferToNonERC721ReceiverImplementer();
                    }
                } while (index < end);
                // Reentrancy protection.
                if (_currentIndex != end) revert();
            }
        }
    }

    /**
     * @dev Equivalent to `_safeMint(to, quantity, '')`.
     */
    function _safeMint(address to, uint256 quantity) internal virtual {
        _safeMint(to, quantity, '');
    }

    // =============================================================
    //                        BURN OPERATIONS
    // =============================================================

    /**
     * @dev Equivalent to `_burn(tokenId, false)`.
     */
    function _burn(uint256 tokenId) internal virtual {
        _burn(tokenId, false);
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
    function _burn(uint256 tokenId, bool approvalCheck) internal virtual {
        uint256 prevOwnershipPacked = _packedOwnershipOf(tokenId);

        address from = address(uint160(prevOwnershipPacked));

        (uint256 approvedAddressSlot, address approvedAddress) = _getApprovedSlotAndAddress(tokenId);

        if (approvalCheck) {
            // The nested ifs save around 20+ gas over a compound boolean condition.
            if (!_isSenderApprovedOrOwner(approvedAddress, from, _msgSenderERC721A()))
                if (!isApprovedForAll(from, _msgSenderERC721A())) revert TransferCallerNotOwnerNorApproved();
        }

        _beforeTokenTransfers(from, address(0), tokenId, 1);

        // Clear approvals from the previous owner.
        assembly {
            if approvedAddress {
                // This is equivalent to `delete _tokenApprovals[tokenId]`.
                sstore(approvedAddressSlot, 0)
            }
        }

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as `tokenId` would have to be 2**256.
        unchecked {
            // Updates:
            // - `balance -= 1`.
            // - `numberBurned += 1`.
            //
            // We can directly decrement the balance, and increment the number burned.
            // This is equivalent to `packed -= 1; packed += 1 << _BITPOS_NUMBER_BURNED;`.
            _packedAddressData[from] += (1 << _BITPOS_NUMBER_BURNED) - 1;

            // Updates:
            // - `address` to the last owner.
            // - `startTimestamp` to the timestamp of burning.
            // - `burned` to `true`.
            // - `nextInitialized` to `true`.
            _packedOwnerships[tokenId] = _packOwnershipData(
                from,
                (_BITMASK_BURNED | _BITMASK_NEXT_INITIALIZED) | _nextExtraData(from, address(0), prevOwnershipPacked)
            );

            // If the next slot may not have been initialized (i.e. `nextInitialized == false`) .
            if (prevOwnershipPacked & _BITMASK_NEXT_INITIALIZED == 0) {
                uint256 nextTokenId = tokenId + 1;
                // If the next slot's address is zero and not burned (i.e. packed value is zero).
                if (_packedOwnerships[nextTokenId] == 0) {
                    // If the next slot is within bounds.
                    if (nextTokenId != _currentIndex) {
                        // Initialize the next slot to maintain correctness for `ownerOf(tokenId + 1)`.
                        _packedOwnerships[nextTokenId] = prevOwnershipPacked;
                    }
                }
            }
        }

        emit Transfer(from, address(0), tokenId);
        _afterTokenTransfers(from, address(0), tokenId, 1);

        // Overflow not possible, as _burnCounter cannot be exceed _currentIndex times.
        unchecked {
            _burnCounter++;
        }
    }

    // =============================================================
    //                     EXTRA DATA OPERATIONS
    // =============================================================

    /**
     * @dev Directly sets the extra data for the ownership data `index`.
     */
    function _setExtraDataAt(uint256 index, uint24 extraData) internal virtual {
        uint256 packed = _packedOwnerships[index];
        if (packed == 0) revert OwnershipNotInitializedForExtraData();
        uint256 extraDataCasted;
        // Cast `extraData` with assembly to avoid redundant masking.
        assembly {
            extraDataCasted := extraData
        }
        packed = (packed & _BITMASK_EXTRA_DATA_COMPLEMENT) | (extraDataCasted << _BITPOS_EXTRA_DATA);
        _packedOwnerships[index] = packed;
    }

    /**
     * @dev Called during each token transfer to set the 24bit `extraData` field.
     * Intended to be overridden by the cosumer contract.
     *
     * `previousExtraData` - the value of `extraData` before transfer.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, `tokenId` will be burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _extraData(
        address from,
        address to,
        uint24 previousExtraData
    ) internal view virtual returns (uint24) {}

    /**
     * @dev Returns the next extra data for the packed ownership data.
     * The returned result is shifted into position.
     */
    function _nextExtraData(
        address from,
        address to,
        uint256 prevOwnershipPacked
    ) private view returns (uint256) {
        uint24 extraData = uint24(prevOwnershipPacked >> _BITPOS_EXTRA_DATA);
        return uint256(_extraData(from, to, extraData)) << _BITPOS_EXTRA_DATA;
    }

    // =============================================================
    //                       OTHER OPERATIONS
    // =============================================================

    /**
     * @dev Returns the message sender (defaults to `msg.sender`).
     *
     * If you are writing GSN compatible contracts, you need to override this function.
     */
    function _msgSenderERC721A() internal view virtual returns (address) {
        return msg.sender;
    }

    /**
     * @dev Converts a uint256 to its ASCII string decimal representation.
     */
    function _toString(uint256 value) internal pure virtual returns (string memory str) {
        assembly {
            // The maximum value of a uint256 contains 78 digits (1 byte per digit), but
            // we allocate 0xa0 bytes to keep the free memory pointer 32-byte word aligned.
            // We will need 1 word for the trailing zeros padding, 1 word for the length,
            // and 3 words for a maximum of 78 digits. Total: 5 * 0x20 = 0xa0.
            let m := add(mload(0x40), 0xa0)
            // Update the free memory pointer to allocate.
            mstore(0x40, m)
            // Assign the `str` to the end.
            str := sub(m, 0x20)
            // Zeroize the slot after the string.
            mstore(str, 0)

            // Cache the end of the memory to calculate the length later.
            let end := str

            // We write the string from rightmost digit to leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            // prettier-ignore
            for { let temp := value } 1 {} {
                str := sub(str, 1)
                // Write the character to the pointer.
                // The ASCII index of the '0' character is 48.
                mstore8(str, add(48, mod(temp, 10)))
                // Keep dividing `temp` until zero.
                temp := div(temp, 10)
                // prettier-ignore
                if iszero(temp) { break }
            }

            let length := sub(end, str)
            // Move the pointer 32 bytes leftwards to make room for the length.
            str := sub(str, 0x20)
            // Store the length.
            mstore(str, length)
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
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
pragma solidity ^0.8.4;

/// @notice Library for generating psuedorandom numbers.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/LibPRNG.sol)
library LibPRNG {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          STRUCTS                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev A psuedorandom number state in memory.
    struct PRNG {
        uint256 state;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         OPERATIONS                         */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Seeds the `prng` with `state`.
    function seed(PRNG memory prng, bytes32 state) internal pure {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(prng, state)
        }
    }

    /// @dev Returns a psuedorandom uint256, uniformly distributed
    /// between 0 (inclusive) and `upper` (exclusive).
    /// If your modulus is big, this method is recommended
    /// for uniform sampling to avoid modulo bias.
    /// For uniform sampling across all uint256 values,
    /// or for small enough moduli such that the bias is neligible,
    /// use {next} instead.
    function uniform(PRNG memory prng, uint256 upper)
        internal
        pure
        returns (uint256 result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            // prettier-ignore
            for {} 1 {} {
                result := keccak256(prng, 0x20)
                mstore(prng, result)
                // prettier-ignore
                if iszero(lt(result, mod(sub(0, upper), upper))) { break }
            }
            result := mod(result, upper)
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// Core utils used extensively to format CSS and numbers.
library Utils {
    string internal constant BASE64_TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    // converts an unsigned integer to a string
    function uint2str(uint256 _i) internal pure returns (string memory) {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            ++len;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    function htmlToURI(string memory _source)
        internal
        pure
        returns (string memory)
    {
        return
            string.concat(
                "data:text/html;base64,",
                encodeBase64(bytes(_source))
            );
    }

    function svgToImageURI(string memory _source)
        internal
        pure
        returns (string memory)
    {
        return
            string.concat(
                "data:image/svg+xml;base64,",
                encodeBase64(bytes(_source))
            );
    }

    function formatTokenURI(
        string memory _imageURI,
        string memory _animationURI,
        string memory _name,
        string memory _description,
        string memory _properties
    ) internal pure returns (string memory) {
        return
            string.concat(
                "data:application/json;base64,",
                encodeBase64(
                    bytes(
                        string.concat(
                            '{"name":"',
                            _name,
                            '","description":"',
                            _description,
                            '","attributes":',
                            _properties,
                            ',"image":"',
                            _imageURI,
                            '","animation_url":"',
                            _animationURI,
                            '"}'
                        )
                    )
                )
            );
    }

    // Encode some bytes in base64
    // https://gist.github.com/mbvissers/8ba9ac1eca9ed0ef6973bd49b3c999ba
    function encodeBase64(bytes memory data)
        internal
        pure
        returns (string memory)
    {
        if (data.length == 0) return "";

        // load the table into memory
        string memory table = BASE64_TABLE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {

            } lt(dataPtr, endPtr) {

            } {
                dataPtr := add(dataPtr, 3)

                // read 3 bytes
                let input := mload(dataPtr)

                // write 4 characters
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(input, 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @title MoonCalculations
/// @author Aspyn Palatnick (aspyn.eth, stuckinaboot.eth)
library MoonCalculations {
    // Only need the 4 moon phases where the moon is actually changing,
    // as the other phases (new moon, first quarter, full moon, third quarter)
    // are just single points in time (don't define a rate of change)
    enum MoonPhase {
        WAXING_CRESCENT,
        WAXING_GIBBOUS,
        WANING_GIBBOUS,
        WANING_CRESCENT
    }

    uint256 internal constant BASE_NEW_MOON_DATE_IN_MS = 1666694910000;
    uint256 internal constant LUNAR_MONTH_LENGTH_IN_MS = 2551442877;

    uint256 internal constant NUM_PHASES = 4;
    uint256 internal constant PHASE_LENGTH = 10000 / NUM_PHASES;

    function timestampToPhase(uint256 unixUtcTimestamp)
        internal
        pure
        returns (MoonPhase phase, uint256 progressPercentageOutOf10000)
    {
        uint256 distanceIntoLunarCycleOutOf10000 = calculateLunarCycleDistanceFromDate(
                unixUtcTimestamp
            );

        uint256 progress = distanceIntoLunarCycleOutOf10000 / PHASE_LENGTH;
        phase = MoonPhase(progress);
        progressPercentageOutOf10000 =
            (distanceIntoLunarCycleOutOf10000 - progress * PHASE_LENGTH) *
            NUM_PHASES;
    }

    function calculateLunarCycleDistanceFromDate(uint256 currDate)
        internal
        pure
        returns (uint256 distanceIntoLunarCycleOutOf10000)
    {
        uint256 msIntoPhase = (currDate - BASE_NEW_MOON_DATE_IN_MS) %
            LUNAR_MONTH_LENGTH_IN_MS;

        uint256 value = MoonCalculations.roundToNearestMultiple(
            msIntoPhase * 10000,
            LUNAR_MONTH_LENGTH_IN_MS
        ) / LUNAR_MONTH_LENGTH_IN_MS;

        // Return value between 0 and 9999, inclusive
        return value < 10000 ? value : 0;
    }

    // Helpers

    function roundToNearestMultiple(uint256 number, uint256 multiple)
        internal
        pure
        returns (uint256)
    {
        uint256 result = number + multiple / 2;
        return result - (result % multiple);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {MoonCalculations} from "./MoonCalculations.sol";
import {MoonSvg} from "./MoonSvg.sol";
import {MoonConfig} from "./MoonConfig.sol";
import {MoonImageConfig} from "./MoonStructs.sol";

/// @title MoonRenderer
/// @author Aspyn Palatnick (aspyn.eth, stuckinaboot.eth)
library MoonRenderer {
    function getLunarCycleDistanceFromDateAsRotationInDegrees(uint256 date)
        internal
        pure
        returns (uint16)
    {
        return
            uint16(
                // Round to nearest multiple of 10000, which ensures that progressScaled will be properly rounded rather than having truncation occur during integer division
                MoonCalculations.roundToNearestMultiple(
                    MoonCalculations.calculateLunarCycleDistanceFromDate(date) *
                        360,
                    10000
                ) / 10000
            );
    }

    function _render(
        bytes32 moonSeed,
        MoonCalculations.MoonPhase phase,
        // Represent a fraction as progressOutOf10000 out of 10000
        // e.g. 0.5 -> progressOutOf10000 = 5000, 0.1234 -> 1234
        uint256 progressOutOf10000,
        string memory alienArt,
        string memory alienArtMoonFilter
    ) internal pure returns (string memory) {
        MoonImageConfig memory moonConfig = MoonConfig.getMoonConfig(moonSeed);

        MoonSvg.SvgContainerParams memory svg1 = MoonSvg.SvgContainerParams({
            x: 0,
            y: 0,
            width: moonConfig.moonRadius,
            height: moonConfig.viewHeight
        });
        MoonSvg.SvgContainerParams memory svg2 = MoonSvg.SvgContainerParams({
            x: 0,
            y: 0,
            width: moonConfig.moonRadius,
            height: moonConfig.viewHeight
        });

        MoonSvg.EllipseParams memory ellipse1 = MoonSvg.EllipseParams({
            cx: moonConfig.moonRadius,
            cy: moonConfig.moonRadius,
            rx: moonConfig.moonRadius,
            ry: moonConfig.moonRadius,
            color: moonConfig.colors.moon,
            forceUseBackgroundColor: false
        });

        MoonSvg.EllipseParams memory ellipse2 = MoonSvg.EllipseParams({
            cx: 0,
            cy: moonConfig.moonRadius,
            rx: moonConfig.moonRadius,
            ry: moonConfig.moonRadius,
            color: moonConfig.colors.moon,
            forceUseBackgroundColor: false
        });

        // Round to nearest multiple of 10000, which ensures that progressScaled will be properly rounded rather than having truncation occur during integer division.
        uint256 progressScaled = MoonCalculations.roundToNearestMultiple(
            progressOutOf10000 * moonConfig.moonRadius,
            10000
        ) / 10000;

        if (phase == MoonCalculations.MoonPhase.WANING_GIBBOUS) {
            svg1.x = 0;
            // Subtract 1 from svg2.x, add 1 to svg2.width, add 1 to ellipse2.cx to ensure smooth border between ellipses
            svg2.x = moonConfig.moonRadius - 1;
            svg2.width += 1;

            ellipse1.cx = moonConfig.moonRadius;
            ellipse1.rx = moonConfig.moonRadius;
            ellipse2.cx = 1;
            ellipse2.rx = moonConfig.moonRadius - progressScaled;
        } else if (phase == MoonCalculations.MoonPhase.WANING_CRESCENT) {
            svg1.x = 0;
            svg2.x = 0;

            // Add 1 to svg2.width to ensure smooth border between ellipses
            svg2.width += 1;

            ellipse1.cx = moonConfig.moonRadius;
            ellipse1.rx = moonConfig.moonRadius;
            ellipse2.cx = moonConfig.moonRadius;
            ellipse2.rx = progressScaled;
            ellipse2.forceUseBackgroundColor = true;
        } else if (phase == MoonCalculations.MoonPhase.WAXING_CRESCENT) {
            svg1.x = moonConfig.moonRadius;
            // Subtract 1 from svg2.x, add 1 to ellipse2.cx, add 1 to ellipse2.rx to ensure smooth border between ellipses
            svg2.x = moonConfig.moonRadius - 1;
            svg2.width += 1;

            ellipse1.cx = 0;
            ellipse1.rx = moonConfig.moonRadius;
            ellipse2.cx = 1;
            ellipse2.rx = moonConfig.moonRadius - progressScaled + 1;
            ellipse2.forceUseBackgroundColor = true;
        } else if (phase == MoonCalculations.MoonPhase.WAXING_GIBBOUS) {
            svg1.x = 0;
            svg2.x = moonConfig.moonRadius;

            // Add 1 to svg1.width to ensure smooth border between ellipses
            svg1.width += 1;

            ellipse1.cx = moonConfig.moonRadius;
            ellipse1.rx = progressScaled;
            ellipse2.cx = 0;
            ellipse2.rx = moonConfig.moonRadius;
        }

        // Add svg offsets
        svg1.x += moonConfig.xOffset;
        svg2.x += moonConfig.xOffset;
        svg1.y += moonConfig.yOffset;
        svg2.y += moonConfig.yOffset;

        return
            MoonSvg.generateMoon(
                MoonSvg.RectParams({
                    color: moonConfig.colors.background,
                    gradientColor: moonConfig.colors.backgroundGradientColor,
                    width: moonConfig.viewWidth,
                    height: moonConfig.viewHeight
                }),
                svg1,
                svg2,
                ellipse1,
                ellipse2,
                MoonSvg.BorderParams({
                    radius: moonConfig.borderRadius,
                    width: moonConfig.borderWidth,
                    borderType: moonConfig.borderType,
                    color: moonConfig.colors.border
                }),
                alienArt,
                alienArtMoonFilter
            );
    }

    function renderWithTimestamp(
        bytes32 moonSeed,
        // UTC timestamp.
        uint256 timestamp,
        string memory alienArt,
        string memory alienArtFilter
    ) internal pure returns (string memory) {
        (
            MoonCalculations.MoonPhase phase,
            uint256 progressOutOf10000
        ) = MoonCalculations.timestampToPhase(timestamp);
        return
            _render(
                moonSeed,
                phase,
                progressOutOf10000,
                alienArt,
                alienArtFilter
            );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./SVG.sol";

/// @title MoonSvg
/// @author Aspyn Palatnick (aspyn.eth, stuckinaboot.eth)
library MoonSvg {
    struct SvgContainerParams {
        uint16 x;
        uint16 y;
        uint16 width;
        uint16 height;
    }

    struct EllipseParams {
        uint16 cx;
        uint16 cy;
        uint256 rx;
        uint16 ry;
        string color;
        bool forceUseBackgroundColor;
    }

    struct RectParams {
        uint16 width;
        uint16 height;
        string color;
        string gradientColor;
    }

    struct BorderParams {
        uint16 radius;
        uint16 width;
        string borderType;
        string color;
    }

    function getBackgroundRadialGradientDefinition(
        RectParams memory rectParams,
        uint256 moonVerticalRadius
    ) internal pure returns (string memory) {
        return
            svg.radialGradient(
                string.concat(
                    svg.prop("id", "brG"),
                    // Set radius to 75% to smooth out the radial gradient against
                    // the background and moon color
                    svg.prop("r", "75%")
                ),
                string.concat(
                    svg.stop(
                        string.concat(
                            svg.prop(
                                "offset",
                                string.concat(
                                    Utils.uint2str(
                                        // Ensure that the gradient has the rect color up to at least the moon radius
                                        // Note: the reason we do moon radius * 100 * 3 / 2 is because
                                        // we multiply by 100 to get a percent, then multiply by 3 and divide by 2
                                        // to get ~1.5 * moon radius, which is sufficiently large given the background radial
                                        // gradient radius is being scaled by 75% (50% would be normal size, 75% is scaled up),
                                        // which smooths out the gradient and reduces the presence of a color band
                                        (((moonVerticalRadius * 100) * 3) / 2) /
                                            rectParams.height
                                    ),
                                    "%"
                                )
                            ),
                            svg.prop("stop-color", rectParams.color)
                        )
                    ),
                    svg.stop(
                        string.concat(
                            svg.prop("offset", "100%"),
                            svg.prop("stop-color", rectParams.gradientColor)
                        )
                    )
                )
            );
    }

    function getMoonFilterDefinition(uint16 moonRadiusY)
        internal
        pure
        returns (string memory)
    {
        uint16 position = moonRadiusY * 2;
        return
            svg.filter(
                string.concat(svg.prop("id", "mF")),
                string.concat(
                    svg.feSpecularLighting(
                        string.concat(
                            svg.prop("result", "out"),
                            svg.prop("specularExponent", "20"),
                            svg.prop("lighting-color", "#bbbbbb")
                        ),
                        svg.fePointLight(
                            string.concat(
                                svg.prop("x", position),
                                svg.prop("y", position),
                                svg.prop("z", position)
                            )
                        )
                    ),
                    svg.feComposite(
                        string.concat(
                            svg.prop("in", "SourceGraphic"),
                            svg.prop("in2", "out"),
                            svg.prop("operator", "arithmetic"),
                            svg.prop("k1", "0"),
                            svg.prop("k2", "1"),
                            svg.prop("k3", "1"),
                            svg.prop("k4", "0")
                        )
                    )
                )
            );
    }

    function getMoonFilterMask(
        SvgContainerParams memory svg1,
        SvgContainerParams memory svg2,
        EllipseParams memory ellipse1,
        EllipseParams memory ellipse2,
        RectParams memory rect
    ) internal pure returns (string memory) {
        return
            svg.mask(
                svg.prop("id", "mfM"),
                string.concat(
                    svg.rect(
                        string.concat(
                            svg.prop("width", rect.width),
                            svg.prop("height", rect.height),
                            svg.prop("fill", "#000")
                        )
                    ),
                    getEllipseElt(
                        svg1,
                        ellipse1,
                        // Black rect for masking purposes; where this rect is visible will be hidden
                        "#000",
                        // White ellipse for masking purposes; where this ellipse is visible will be shown
                        "#FFF"
                    ),
                    getEllipseElt(
                        svg2,
                        ellipse2,
                        // Black rect for masking purposes; where this rect is visible will be hidden
                        "#000",
                        // White ellipse for masking purposes; where this ellipse is visible will be shown
                        "#FFF"
                    )
                )
            );
    }

    function getEllipseElt(
        SvgContainerParams memory svgContainer,
        EllipseParams memory ellipse,
        string memory rectBackgroundColor,
        string memory ellipseColor
    ) internal pure returns (string memory) {
        return
            svg.svgTag(
                string.concat(
                    svg.prop("x", svgContainer.x),
                    svg.prop("y", svgContainer.y),
                    svg.prop("height", svgContainer.height),
                    svg.prop("width", svgContainer.width)
                ),
                svg.ellipse(
                    string.concat(
                        svg.prop("cx", ellipse.cx),
                        svg.prop("cy", ellipse.cy),
                        svg.prop("rx", ellipse.rx),
                        svg.prop("ry", ellipse.ry),
                        svg.prop(
                            "fill",
                            ellipse.forceUseBackgroundColor
                                ? rectBackgroundColor
                                : ellipseColor
                        )
                    )
                )
            );
    }

    function getBorderStyleProp(BorderParams memory border)
        internal
        pure
        returns (string memory)
    {
        return
            svg.prop(
                "style",
                string.concat(
                    "outline:",
                    Utils.uint2str(border.width),
                    "px ",
                    border.borderType,
                    " ",
                    border.color,
                    ";outline-offset:-",
                    Utils.uint2str(border.width),
                    "px;border-radius:",
                    Utils.uint2str(border.radius),
                    "%"
                )
            );
    }

    function getMoonBackgroundMaskDefinition(
        RectParams memory rect,
        uint256 moonRadius
    ) internal pure returns (string memory) {
        return
            svg.mask(
                svg.prop("id", "mbM"),
                string.concat(
                    svg.rect(
                        string.concat(
                            svg.prop("width", rect.width),
                            svg.prop("height", rect.height),
                            // Everything under a white pixel will be visible
                            svg.prop("fill", "#FFF")
                        )
                    ),
                    svg.circle(
                        string.concat(
                            svg.prop("cx", rect.width / 2),
                            svg.prop("cy", rect.height / 2),
                            // Add 1 to moon radius as slight buffer.
                            svg.prop("r", moonRadius + 1)
                        )
                    )
                )
            );
    }

    function getDefinitions(
        RectParams memory rect,
        SvgContainerParams memory svg1,
        SvgContainerParams memory svg2,
        EllipseParams memory ellipse1,
        EllipseParams memory ellipse2,
        string memory alienArtMoonFilterDefinition
    ) internal pure returns (string memory) {
        return
            svg.defs(
                string.concat(
                    getBackgroundRadialGradientDefinition(rect, ellipse1.ry),
                    bytes(alienArtMoonFilterDefinition).length > 0
                        ? alienArtMoonFilterDefinition
                        : getMoonFilterDefinition(ellipse1.ry),
                    getMoonBackgroundMaskDefinition(rect, ellipse1.ry),
                    getMoonFilterMask(svg1, svg2, ellipse1, ellipse2, rect)
                )
            );
    }

    function getMoonSvgProps(uint16 borderRadius)
        internal
        pure
        returns (string memory)
    {
        return
            string.concat(
                svg.prop("xmlns", "http://www.w3.org/2000/svg"),
                // Include id so that the moon element can be accessed by JS
                svg.prop("id", "moon"),
                svg.prop("height", "100%"),
                svg.prop("viewBox", "0 0 200 200"),
                svg.prop(
                    "style",
                    string.concat(
                        "border-radius:",
                        Utils.uint2str(borderRadius),
                        "%;max-height:100vh"
                    )
                )
            );
    }

    function generateMoon(
        RectParams memory rect,
        SvgContainerParams memory svg1,
        SvgContainerParams memory svg2,
        EllipseParams memory ellipse1,
        EllipseParams memory ellipse2,
        BorderParams memory border,
        string memory alienArt,
        string memory alienArtMoonFilterDefinition
    ) internal pure returns (string memory) {
        string memory ellipse1elt = getEllipseElt(
            svg1,
            ellipse1,
            rect.color,
            ellipse1.color
        );
        string memory ellipse2elt = getEllipseElt(
            svg2,
            ellipse2,
            rect.color,
            ellipse2.color
        );

        string memory rectProps = string.concat(
            svg.prop(
                "fill",
                bytes(rect.gradientColor).length > 0 ? "url(#brG)" : rect.color
            ),
            svg.prop("width", rect.width),
            svg.prop("height", rect.height),
            svg.prop("rx", string.concat(Utils.uint2str(border.radius), "%")),
            svg.prop("ry", string.concat(Utils.uint2str(border.radius), "%"))
        );

        string memory definitions = getDefinitions(
            rect,
            svg1,
            svg2,
            ellipse1,
            ellipse2,
            alienArtMoonFilterDefinition
        );

        return
            svg.svgTag(
                getMoonSvgProps(border.radius),
                string.concat(
                    definitions,
                    svg.svgTag(
                        svg.NULL,
                        string.concat(
                            svg.rect(
                                string.concat(
                                    rectProps,
                                    getBorderStyleProp(border)
                                )
                            ),
                            // Intentionally put alien art behind the moon in svg ordering
                            svg.g(
                                // Apply mask to block out the moon area from alien art,
                                // which is necessary in order for the moon to be clearly visible when displayed
                                svg.prop("mask", "url(#mbM)"),
                                alienArt
                            ),
                            svg.g(
                                string.concat(
                                    // Apply filter to moon
                                    svg.prop("filter", "url(#mF)"),
                                    // Apply mask to ensure filter only applies to the visible portion of the moon
                                    svg.prop("mask", "url(#mfM)")
                                ),
                                string.concat(ellipse1elt, ellipse2elt)
                            )
                        )
                    )
                )
            );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {LibPRNG} from "../utils/LibPRNG.sol";
import {Traits} from "../utils/Traits.sol";
import {Utils} from "../utils/Utils.sol";
import {MoonImageConfig, MoonImageColors} from "./MoonStructs.sol";

/// @title MoonConfig
/// @author Aspyn Palatnick (aspyn.eth, stuckinaboot.eth)
library MoonConfig {
    using LibPRNG for LibPRNG.PRNG;

    function getMoonSeed(uint256 tokenId) internal view returns (bytes32) {
        return keccak256(abi.encodePacked(tokenId, block.difficulty));
    }

    function getFrameTraits(
        MoonImageConfig memory moonConfig
    ) internal pure returns (string memory) {
        bool hasFrame = moonConfig.borderWidth > 0;
        return
            string.concat(
                Traits.getTrait(
                    "Frame roundness",
                    moonConfig.borderRadius,
                    true
                ),
                Traits.getTrait(
                    "Frame thickness",
                    moonConfig.borderWidth,
                    true
                ),
                Traits.getTrait(
                    "Frame type",
                    hasFrame ? moonConfig.borderType : "Invisible",
                    true
                ),
                hasFrame ? Traits.getTrait(
                    "Frame tint",
                    uint256(moonConfig.colors.borderSaturation),
                    true
                ) : ""
            );
    }

    function getMoonTraits(
        bytes32 moonSeed,
        string memory alienArtTrait,
        string memory alienArtName,
        string memory alienArtAddressStr,
        bool isDefaultAlienArt
    ) internal pure returns (string memory) {
        MoonImageConfig memory moonConfig = getMoonConfig(moonSeed);

        // Evaluate groups of traits to (1) better organize code (2) avoid stack too deep errors
        string memory frameTraits = getFrameTraits(moonConfig);

        string memory alienArtAllTraits = string.concat(
            Traits.getTrait(
                "Is default alien art",
                // This needs to be included as a boolean rather than a check
                // agains the default name since the name can be impersonated by another contract
                isDefaultAlienArt ? "Yes" : "No",
                true
            ),
            // Include alien art address so others can discover alien art
            // used by different moons
            Traits.getTrait("Alien art address", alienArtAddressStr, true),
            Traits.getTrait(
                "Alien art",
                alienArtName,
                // Include comma if alien art trait is defined
                // by doing length of alienArtTrait comparison
                bytes(alienArtTrait).length > 0
            ),
            alienArtTrait
        );

        return
            string.concat(
                "[",
                Traits.getTrait(
                    "Moon hue",
                    uint256(moonConfig.colors.moonHue),
                    true
                ),
                frameTraits,
                Traits.getTrait(
                    "Space darkness",
                    uint256(moonConfig.colors.backgroundLightness),
                    true
                ),
                Traits.getTrait(
                    "Has space gradient",
                    bytes(moonConfig.colors.backgroundGradientColor).length > 0
                        ? "Yes"
                        : "No",
                    true
                ),
                alienArtAllTraits,
                "]"
            );
    }

    function getBorderType(LibPRNG.PRNG memory prng)
        internal
        pure
        returns (string memory)
    {
        // Choose border type based on different weightings
        uint256 psuedoRandomOutOf100 = prng.uniform(100);
        if (psuedoRandomOutOf100 < 70) {
            return "solid";
        }
        if (psuedoRandomOutOf100 < 90) {
            return "inset";
        }
        return "outset";
    }

    function getMoonImageColors(LibPRNG.PRNG memory prng)
        internal
        pure
        returns (MoonImageColors memory)
    {
        uint16 moonHue = uint16(prng.uniform(360));
        uint8 borderSaturation = uint8(prng.uniform(71));
        uint8 backgroundLightness = uint8(prng.uniform(11));

        return
            MoonImageColors({
                moon: hslaString(moonHue, 50, 50),
                moonHue: moonHue,
                border: hslaString(moonHue, borderSaturation, 50),
                borderSaturation: borderSaturation,
                background: hslaString(0, 0, backgroundLightness),
                backgroundLightness: backgroundLightness,
                backgroundGradientColor: // Bias gradient to occur 33% of the time
                prng.uniform(3) == 0
                    ? hslaString(
                        // Derive hue from moon hue
                        moonHue,
                        50,
                        50
                    )
                    : ""
            });
    }

    function getMoonConfig(bytes32 moonSeed)
        internal
        pure
        returns (MoonImageConfig memory)
    {
        uint16 moonRadius = 32;
        uint16 viewSize = 200;
        uint16 offset = (viewSize - 2 * moonRadius) / 2;

        LibPRNG.PRNG memory prng;
        prng.seed(keccak256(abi.encodePacked(moonSeed, uint256(5))));

        // Border radius can vary from 0 to 50%
        uint16 borderRadius = prng.uniform(9) == 0 // 11% chance of having a circular border
            ? 50 // Otherwise, choose a border radius between 0 and 5
            : uint16(prng.uniform(6));

        // Border width can vary from 0 to 4
        uint16 borderWidth = uint16(prng.uniform(5));

        MoonImageColors memory colors = getMoonImageColors(prng);
        string memory borderType = getBorderType(prng);
        
        return
            MoonImageConfig({
                colors: colors,
                moonRadius: moonRadius,
                xOffset: offset,
                yOffset: offset,
                viewWidth: viewSize,
                viewHeight: viewSize,
                borderRadius: borderRadius,
                borderWidth: borderWidth,
                borderType: borderType
            });
    }

    // Helpers

    function hslaString(
        uint16 hue,
        uint8 saturation,
        uint8 lightness
    ) internal pure returns (string memory) {
        return
            string.concat(
                "hsla(",
                Utils.uint2str(hue),
                ",",
                Utils.uint2str(saturation),
                "%,",
                Utils.uint2str(lightness),
                "%,100%)"
            );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {OwnerPermissionedTokenRegistryInterface} from "./OwnerPermissionedTokenRegistryInterface.sol";

/**
 * @title  DynamicNftRegistry
 * @author James Wenzel (emo.eth)
 * @notice Interface for an open registry for allowed updaters of token contracts to register that a (potentially
 *         off-chain) metadata update has occurred on-chain, inheriting from OwnerPermissionedTokenRegistryInterface.
 */
interface DynamicNftRegistryInterface is
    OwnerPermissionedTokenRegistryInterface
{
    /**
     * @notice update token's last modified timestamp to timestamp of current block
     * @param tokenAddress address of the token contract
     * @param tokenId that has been updated
     * @param cooldownPeriod in seconds
     */
    function updateToken(
        address tokenAddress,
        uint256 tokenId,
        uint64 cooldownPeriod,
        bool invalidateCollectionOrders
    ) external;

    /**
     * @notice update token's last modified timestamp to a timestamp in the past
     * @param tokenAddress address of the token contract
     * @param tokenId that has been updated
     * @param timestamp specific timestamp when token was last updated
     * @param cooldownPeriod in seconds
     */
    function updateToken(
        address tokenAddress,
        uint256 tokenId,
        uint64 timestamp,
        uint64 cooldownPeriod,
        bool invalidateCollectionOrders
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IERC165} from "../ext/IERC165.sol";
import {MoonImageConfig} from "../../moon/MoonStructs.sol";

/// @title AlienArtBase
/// @author Aspyn Palatnick (aspyn.eth, stuckinaboot.eth)
/// @notice Alien Art is an on-chain NFT composability standard for on-chain art and traits.
abstract contract AlienArtBase is IERC165 {
    // Define functions that alien art contracts can override. These intentionally
    // use function state mutability as view to allow for reading on-chain data.

    /// @notice get art name.
    /// @return art name.
    function getArtName() external view virtual returns (string memory);

    /// @notice get alien art image for a particular token.
    /// @param tokenId token id.
    /// @param moonSeed moon seed.
    /// @param moonImageConfig moon image config.
    /// @param rotationInDegrees rotation in degrees.
    /// @return alien art image.
    function getArt(
        uint256 tokenId,
        bytes32 moonSeed,
        MoonImageConfig calldata moonImageConfig,
        uint256 rotationInDegrees
    ) external view virtual returns (string memory);

    /// @notice get moon filter for a particular token.
    /// @param tokenId token id.
    /// @param moonSeed moon seed.
    /// @param moonImageConfig moon image config.
    /// @param rotationInDegrees rotation in degrees.
    /// @return moon filter.
    function getMoonFilter(
        uint256 tokenId,
        bytes32 moonSeed,
        MoonImageConfig calldata moonImageConfig,
        uint256 rotationInDegrees
    ) external view virtual returns (string memory) {
        return "";
    }

    /// @notice get alien art traits for a particular token.
    /// @param tokenId token id.
    /// @param moonSeed moon seed.
    /// @param moonImageConfig moon image config.
    /// @param rotationInDegrees rotation in degrees.
    /// @return alien art traits.
    function getTraits(
        uint256 tokenId,
        bytes32 moonSeed,
        MoonImageConfig calldata moonImageConfig,
        uint256 rotationInDegrees
    ) external view virtual returns (string memory) {
        return "";
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {DynamicNftRegistryInterface} from "../../interfaces/dynamicNftRegistry/DynamicNftRegistryInterface.sol";
import {AlienArtBase} from "../../interfaces/alienArt/AlienArtBase.sol";
import {MoonImageConfig, MoonImageColors} from "../../moon/MoonStructs.sol";
import {AlienArtConstellationEventsAndErrors} from "./AlienArtConstellationEventsAndErrors.sol";
import {ConstellationLib} from "./ConstellationLib.sol";
import {IERC165} from "../../interfaces/ext/IERC165.sol";
import {IERC721} from "../../interfaces/ext/IERC721.sol";
import {ERC1155} from "../../ext/ERC1155.sol";
import {Ownable} from "../../ext/Ownable.sol";
import {Utils} from "../../utils/Utils.sol";
import {Traits} from "../../utils/Traits.sol";
import {LibPRNG} from "../../utils/LibPRNG.sol";
import {svg} from "./SVG.sol";

/// @title AlienArtConstellation
/// @author Aspyn Palatnick (aspyn.eth, stuckinaboot.eth)
/// @notice On-chain constellation NFTs that conform to the Alien Art (AlienArtBase) on-chain NFT composability standard and support swapping constellations between Non-Fungible Moon NFTs.
contract AlienArtConstellation is
    ERC1155,
    AlienArtBase,
    AlienArtConstellationEventsAndErrors,
    Ownable
{
    using LibPRNG for LibPRNG.PRNG;

    struct ConstellationParams {
        Constellation constellationType;
        // In degrees
        uint16 rotation;
        bool fluxConstellation;
    }

    enum Constellation {
        LITTLE_DIPPER,
        BIG_DIPPER,
        // Zodiac
        ARIES,
        PISCES,
        AQUARIUS,
        CAPRICORNUS,
        SAGITTARIUS,
        OPHIUCHUS,
        SCORPIUS,
        LIBRA,
        VIRGO,
        LEO,
        CANCER,
        GEMINI,
        TAURUS,
        NONE
    }

    // These constants ensure that Etherscan/etc can read the name and symbol for this contract
    string public constant name = "Constellations";
    string public constant symbol = "CLN";

    uint16 internal constant DEFAULT_VIEW_SIZE = 200;
    uint16 internal constant DEFAULT_MOON_RADIUS = 32;

    address internal moonAddress;

    mapping(uint256 => uint256) public moonTokenIdToConstellationTokenId;
    uint16 internal constant RANDOMNESS_FACTOR = 1337;

    address dynamicNftRegistryAddress;
    uint64 internal constant COOLDOWN_PERIOD = 120;

    /// @notice set moon address.
    /// @param _moonAddress moon address.
    function setMoonAddress(address _moonAddress) external onlyOwner {
        if (moonAddress != address(0)) {
            revert MoonAddressAlreadySet();
        }
        moonAddress = _moonAddress;
    }

    /// @notice swap constellation associated moon 1 with the constellation associated with moon 2.
    /// Both moons must be owned by the same user.
    /// @param moon1 moon 1 token id.
    /// @param moon2 moon 2 token id.
    function swapConstellations(uint256 moon1, uint256 moon2) external {
        // Checks

        // Check both moons are owned by this account
        if (
            IERC721(moonAddress).ownerOf(moon1) != msg.sender ||
            IERC721(moonAddress).ownerOf(moon2) != msg.sender
        ) {
            revert SwapMoonsOwnerMustBeMsgSender();
        }

        // Effects

        // Perform swap
        uint256 originalMoon1Constellation = moonTokenIdToConstellationTokenId[
            moon1
        ];
        moonTokenIdToConstellationTokenId[
            moon1
        ] = moonTokenIdToConstellationTokenId[moon2];
        moonTokenIdToConstellationTokenId[moon2] = originalMoon1Constellation;

        // Emit event indicating swap occurred
        emit SwapConstellations(
            msg.sender,
            moon1,
            moon2,
            moonTokenIdToConstellationTokenId[moon1],
            moonTokenIdToConstellationTokenId[moon2]
        );

        // Interactions
        if (dynamicNftRegistryAddress != address(0)) {
            // Call update token on zone registry (if defined) for both moons
            // and do not invalidate collection orders.
            DynamicNftRegistryInterface(dynamicNftRegistryAddress).updateToken(
                moonAddress,
                moon1,
                COOLDOWN_PERIOD,
                false
            );
            DynamicNftRegistryInterface(dynamicNftRegistryAddress).updateToken(
                moonAddress,
                moon2,
                COOLDOWN_PERIOD,
                false
            );
        }
    }

    /// @notice get constellation type that corresponds to a particular moon token id when the constellation is to be minted
    /// @param moonTokenId moon token id
    /// @return Constellation
    function getConstellationTypeForMoonTokenIdAtMint(uint256 moonTokenId)
        public
        view
        returns (Constellation)
    {
        LibPRNG.PRNG memory prng;
        prng.seed(
            keccak256(
                abi.encodePacked(
                    moonTokenId,
                    block.difficulty,
                    RANDOMNESS_FACTOR
                )
            )
        );

        uint256 randomFrom0To99 = prng.uniform(100);
        if (randomFrom0To99 <= 1) {
            // 2% chance of returning little dipper
            return Constellation.LITTLE_DIPPER;
        }
        if (randomFrom0To99 == 2) {
            // 1% chance of returning big dipper
            return Constellation.BIG_DIPPER;
        }

        // Length of zodiac constellation values and None is the value of the last enum - first zodiac constellation + 1 for the none value
        uint256 totalZodiacConstellations = uint256(Constellation.NONE) -
            uint256(Constellation.ARIES) +
            1;
        // Return any value from the zodiac constellations or None.
        return
            Constellation(
                prng.uniform(totalZodiacConstellations) +
                    uint256(Constellation.ARIES)
            );
    }

    /// @notice get art name for this alien art contract.
    /// @return art name.
    function getArtName() external pure override returns (string memory) {
        return name;
    }

    /// @notice get on-chain Constellation art image, adhering to Alien Art abstract class.
    /// @param tokenId moon token id.
    /// @param moonSeed moon seed.
    /// @param moonImageConfig moon image config.
    /// @param rotationInDegrees rotation in degrees.
    /// @return on-chain Constellation SVG.
    function getArt(
        uint256 tokenId,
        bytes32 moonSeed,
        MoonImageConfig calldata moonImageConfig,
        uint256 rotationInDegrees
    ) external view override returns (string memory) {
        Constellation constellation = Constellation(
            moonTokenIdToConstellationTokenId[tokenId]
        );
        return
            getArtForConstellation(
                constellation,
                moonSeed,
                moonImageConfig,
                rotationInDegrees
            );
    }

    // For a given moon seed, returns bool indicating if flux constellation should be used, bool indicating if
    // moon color for star color should be used
    function getConstellationUseFluxAndUseMoonColor(bytes32 moonSeed)
        internal
        pure
        returns (bool, bool)
    {
        if (moonSeed == bytes32(0)) {
            // If moon seed is bytes32(0), return false for both use flux and use moon color for star color
            return (false, false);
        }
        LibPRNG.PRNG memory prng;
        prng.seed(moonSeed);
        return (prng.uniform(4) == 0, prng.uniform(20) == 0);
    }

    /// @notice get on-chain Constellation SVG.
    /// @param constellation constellation to get SVG for.
    /// @param moonSeed moon seed of moon mapping to constellation.
    /// @param moonImageConfig moon image config.
    /// @param rotationInDegrees rotation in degrees.
    /// @return Constellation SVG.
    function getArtForConstellation(
        Constellation constellation,
        bytes32 moonSeed,
        MoonImageConfig memory moonImageConfig,
        uint256 rotationInDegrees
    ) public pure returns (string memory) {
        (
            bool useFlux,
            bool useMoonColorForStarColor
        ) = getConstellationUseFluxAndUseMoonColor(moonSeed);
        return
            getConstellation(
                ConstellationParams({
                    constellationType: constellation,
                    rotation: uint16(rotationInDegrees),
                    fluxConstellation: useFlux
                }),
                moonImageConfig.viewWidth,
                moonImageConfig.viewHeight,
                useMoonColorForStarColor
                    ? moonImageConfig.colors.moon
                    : "#FDFD96",
                moonSeed
            );
    }

    /// @notice get traits for Constellation.
    /// @param tokenId token id.
    /// @param moonSeed moon seed.
    /// @return traits.
    function getTraits(
        uint256 tokenId,
        bytes32 moonSeed,
        MoonImageConfig calldata,
        uint256
    ) external view override returns (string memory) {
        (
            bool useFlux,
            bool useMoonColorForStarColor
        ) = getConstellationUseFluxAndUseMoonColor(moonSeed);
        return
            string.concat(
                Traits.getTrait(
                    "Star brightness",
                    useFlux ? "Flux" : "Fixed",
                    true
                ),
                Traits.getTrait(
                    "Star color",
                    useMoonColorForStarColor ? "Moon" : "Classic",
                    true
                ),
                _getTraitForConstellation(
                    Constellation(moonTokenIdToConstellationTokenId[tokenId])
                )
            );
    }

    function _getTraitForConstellation(Constellation constellation)
        internal
        pure
        returns (string memory)
    {
        return
            Traits.getTrait(
                "Constellation",
                getConstellationTypeString(constellation),
                false
            );
    }

    function getConstellationTypeString(Constellation constellation)
        internal
        pure
        returns (string memory)
    {
        if (constellation == Constellation.LITTLE_DIPPER) {
            return "Little dipper";
        }
        if (constellation == Constellation.BIG_DIPPER) {
            return "Big dipper";
        }
        if (constellation == Constellation.ARIES) {
            return "Aries";
        }
        if (constellation == Constellation.PISCES) {
            return "Pisces";
        }
        if (constellation == Constellation.AQUARIUS) {
            return "Aquarius";
        }
        if (constellation == Constellation.CAPRICORNUS) {
            return "Capricornus";
        }
        if (constellation == Constellation.SAGITTARIUS) {
            return "Sagittarius";
        }
        if (constellation == Constellation.OPHIUCHUS) {
            return "Ophiuchus";
        }
        if (constellation == Constellation.SCORPIUS) {
            return "Scorpius";
        }
        if (constellation == Constellation.LIBRA) {
            return "Libra";
        }
        if (constellation == Constellation.VIRGO) {
            return "Virgo";
        }
        if (constellation == Constellation.LEO) {
            return "Leo";
        }
        if (constellation == Constellation.CANCER) {
            return "Cancer";
        }
        if (constellation == Constellation.GEMINI) {
            return "Gemini";
        }
        if (constellation == Constellation.TAURUS) {
            return "Taurus";
        }
        return "None";
    }

    function getConstellation(
        ConstellationParams memory constellation,
        uint256 rectWidth,
        uint256 rectHeight,
        string memory starColor,
        bytes32 moonSeed
    ) internal pure returns (string memory) {
        if (constellation.constellationType == Constellation.NONE) {
            return "";
        }

        ConstellationLib.GenerateConstellationParams
            memory params = ConstellationLib.GenerateConstellationParams(
                0,
                0,
                constellation.rotation,
                uint16(rectWidth) / 2,
                uint16(rectHeight) / 2,
                starColor,
                constellation.fluxConstellation,
                moonSeed
            );

        if (constellation.constellationType == Constellation.LITTLE_DIPPER) {
            params.x = 60;
            params.y = 150;
            return ConstellationLib.getLittleDipper(params);
        }
        if (constellation.constellationType == Constellation.BIG_DIPPER) {
            params.x = 89;
            params.y = 13;
            return ConstellationLib.getBigDipper(params);
        }
        if (constellation.constellationType == Constellation.ARIES) {
            params.x = 75;
            params.y = 40;
            return ConstellationLib.getAries(params);
        }
        if (constellation.constellationType == Constellation.PISCES) {
            params.x = 25;
            params.y = 147;
            return ConstellationLib.getPisces(params);
        }
        if (constellation.constellationType == Constellation.AQUARIUS) {
            params.x = 35;
            params.y = 156;
            return ConstellationLib.getAquarius(params);
        }
        if (constellation.constellationType == Constellation.CAPRICORNUS) {
            params.x = 35;
            params.y = 145;
            return ConstellationLib.getCapricornus(params);
        }
        if (constellation.constellationType == Constellation.SAGITTARIUS) {
            params.x = 35;
            params.y = 160;
            return ConstellationLib.getSagittarius(params);
        }
        if (constellation.constellationType == Constellation.OPHIUCHUS) {
            params.x = 35;
            params.y = 160;
            return ConstellationLib.getOphiuchus(params);
        }
        if (constellation.constellationType == Constellation.SCORPIUS) {
            params.x = 35;
            params.y = 140;
            return ConstellationLib.getScorpius(params);
        }
        if (constellation.constellationType == Constellation.LIBRA) {
            params.x = 75;
            params.y = 167;
            return ConstellationLib.getLibra(params);
        }
        if (constellation.constellationType == Constellation.VIRGO) {
            params.x = 15;
            params.y = 120;
            return ConstellationLib.getVirgo(params);
        }
        if (constellation.constellationType == Constellation.LEO) {
            params.x = 55;
            params.y = 165;
            return ConstellationLib.getLeo(params);
        }
        if (constellation.constellationType == Constellation.CANCER) {
            params.x = 110;
            params.y = 185;
            return ConstellationLib.getCancer(params);
        }
        if (constellation.constellationType == Constellation.GEMINI) {
            params.x = 75;
            params.y = 152;
            return ConstellationLib.getGemini(params);
        }
        if (constellation.constellationType == Constellation.TAURUS) {
            params.x = 67;
            params.y = 155;
            return ConstellationLib.getTaurus(params);
        }

        return "";
    }

    /// @notice get standalone Constellation, which is
    /// an on-chain Constellation SVG that can properly be rendered standalone (without being embedded in another SVG).
    /// @param constellation constellation.
    /// @param moonSeed moon seed of moon mapping to constellation.
    /// @param config moon image config.
    /// @return standalone Constellation SVG.
    function getStandaloneConstellation(
        Constellation constellation,
        bytes32 moonSeed,
        MoonImageConfig memory config
    ) public pure returns (string memory) {
        return
            svg.svgTag(
                string.concat(
                    svg.prop("xmlns", "http://www.w3.org/2000/svg"),
                    svg.prop("width", "400"),
                    svg.prop("height", "400"),
                    svg.prop("viewBox", "0 0 200 200")
                ),
                string.concat(
                    svg.rect(
                        string.concat(
                            svg.prop("width", "200"),
                            svg.prop("height", "200"),
                            svg.prop("fill", "#0e1111")
                        )
                    ),
                    getArtForConstellation(constellation, moonSeed, config, 0)
                )
            );
    }

    /// @notice burn and mint constellation for particular moon. Only callable by moon contract.
    /// @param moonTokenId moon token id.
    function burnAndMint(uint256 moonTokenId) external {
        // Only moon contract can burn
        if (msg.sender != moonAddress) {
            revert MsgSenderNotMoonAddress();
        }

        // Burn existing Constellation token
        _burn(msg.sender, moonTokenIdToConstellationTokenId[moonTokenId], 1);
        // Mint new token
        mint(moonTokenId, 1);
    }

    /// @notice mint Constellation NFTs corresponding with moons.
    /// @param startMoonTokenId start moon token id.
    /// @param numMoonsMinted number of moons minted.
    function mint(uint256 startMoonTokenId, uint256 numMoonsMinted) public {
        // Only moon contract can mint
        if (msg.sender != moonAddress) {
            revert MsgSenderNotMoonAddress();
        }

        for (
            uint256 moonTokenId = startMoonTokenId;
            moonTokenId < startMoonTokenId + numMoonsMinted;
            ++moonTokenId
        ) {
            // Determine constellation to mint based on moon token
            uint256 constellationIdx = uint256(
                getConstellationTypeForMoonTokenIdAtMint(moonTokenId)
            );
            // Map moon token id to this constellation token id (index)
            moonTokenIdToConstellationTokenId[moonTokenId] = constellationIdx;
            // Mint to msg.sender, which is moon contract since we only
            // allow minting by moon contract
            _mint(msg.sender, constellationIdx, 1, "");
        }
    }

    /// @notice get fully on-chain uri for a particular token.
    /// @param tokenId token id, which is an index in Constellation enum.
    /// @return Constellation uri for tokenId.
    function uri(uint256 tokenId)
        public
        view
        virtual
        override(ERC1155)
        returns (string memory)
    {
        if (tokenId > uint256(Constellation.NONE)) {
            revert InvalidConstellationIndex();
        }

        // Only define fields relevant for generating image for uri
        MoonImageConfig memory moonImageConfig;
        moonImageConfig.viewWidth = DEFAULT_VIEW_SIZE;
        moonImageConfig.viewHeight = DEFAULT_VIEW_SIZE;
        moonImageConfig.moonRadius = DEFAULT_MOON_RADIUS;

        string memory constellationSvg = Utils.svgToImageURI(
            getStandaloneConstellation(
                Constellation(tokenId),
                bytes32(0),
                moonImageConfig
            )
        );
        return
            Utils.formatTokenURI(
                constellationSvg,
                constellationSvg,
                getConstellationTypeString(Constellation(tokenId)),
                "Constellations are on-chain constellation NFTs. Constellations are on-chain art owned by on-chain art; Constellations are all owned by Non-Fungible Moon NFTs.",
                string.concat(
                    "[",
                    _getTraitForConstellation(Constellation(tokenId)),
                    "]"
                )
            );
    }

    // Dynamic NFT registry setup

    /// @notice set up dynamic NFT registry.
    /// @param _dynamicNftRegistryAddress dynamic NFT registry address.
    function setupDynamicNftRegistry(address _dynamicNftRegistryAddress)
        external
        onlyOwner
    {
        dynamicNftRegistryAddress = _dynamicNftRegistryAddress;
    }

    // IERC165 functions

    /// @notice check if this contract supports a given interface.
    /// @param interfaceId interface id.
    /// @return true if contract supports interfaceId, false otherwise.
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC165, ERC1155)
        returns (bool)
    {
        return
            super.supportsInterface(interfaceId) ||
            // AlienArtBase interface id
            interfaceId == type(AlienArtBase).interfaceId;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.17;

/// @notice Minimalist and gas efficient standard ERC1155 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC1155.sol)
abstract contract ERC1155 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 amount
    );

    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] amounts
    );

    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    event URI(string value, uint256 indexed id);

    /*//////////////////////////////////////////////////////////////
                             ERC1155 STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(address => mapping(uint256 => uint256)) public balanceOf;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*//////////////////////////////////////////////////////////////
                             METADATA LOGIC
    //////////////////////////////////////////////////////////////*/

    function uri(uint256 id) public view virtual returns (string memory);

    /*//////////////////////////////////////////////////////////////
                              ERC1155 LOGIC
    //////////////////////////////////////////////////////////////*/

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) public virtual {
        require(
            msg.sender == from || isApprovedForAll[from][msg.sender],
            "NOT_AUTHORIZED"
        );

        balanceOf[from][id] -= amount;
        balanceOf[to][id] += amount;

        emit TransferSingle(msg.sender, from, to, id, amount);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155Received(
                    msg.sender,
                    from,
                    id,
                    amount,
                    data
                ) == ERC1155TokenReceiver.onERC1155Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) public virtual {
        require(ids.length == amounts.length, "LENGTH_MISMATCH");

        require(
            msg.sender == from || isApprovedForAll[from][msg.sender],
            "NOT_AUTHORIZED"
        );

        // Storing these outside the loop saves ~15 gas per iteration.
        uint256 id;
        uint256 amount;

        for (uint256 i = 0; i < ids.length; ) {
            id = ids[i];
            amount = amounts[i];

            balanceOf[from][id] -= amount;
            balanceOf[to][id] += amount;

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, from, to, ids, amounts);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155BatchReceived(
                    msg.sender,
                    from,
                    ids,
                    amounts,
                    data
                ) == ERC1155TokenReceiver.onERC1155BatchReceived.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function balanceOfBatch(address[] calldata owners, uint256[] calldata ids)
        public
        view
        virtual
        returns (uint256[] memory balances)
    {
        require(owners.length == ids.length, "LENGTH_MISMATCH");

        balances = new uint256[](owners.length);

        // Unchecked because the only math done is incrementing
        // the array index counter which cannot possibly overflow.
        unchecked {
            for (uint256 i = 0; i < owners.length; ++i) {
                balances[i] = balanceOf[owners[i]][ids[i]];
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        returns (bool)
    {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0xd9b67a26 || // ERC165 Interface ID for ERC1155
            interfaceId == 0x0e89341c; // ERC165 Interface ID for ERC1155MetadataURI
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        balanceOf[to][id] += amount;

        emit TransferSingle(msg.sender, address(0), to, id, amount);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155Received(
                    msg.sender,
                    address(0),
                    id,
                    amount,
                    data
                ) == ERC1155TokenReceiver.onERC1155Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _batchMint(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        uint256 idsLength = ids.length; // Saves MLOADs.

        require(idsLength == amounts.length, "LENGTH_MISMATCH");

        for (uint256 i = 0; i < idsLength; ) {
            balanceOf[to][ids[i]] += amounts[i];

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, address(0), to, ids, amounts);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155BatchReceived(
                    msg.sender,
                    address(0),
                    ids,
                    amounts,
                    data
                ) == ERC1155TokenReceiver.onERC1155BatchReceived.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _batchBurn(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        uint256 idsLength = ids.length; // Saves MLOADs.

        require(idsLength == amounts.length, "LENGTH_MISMATCH");

        for (uint256 i = 0; i < idsLength; ) {
            balanceOf[from][ids[i]] -= amounts[i];

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, from, address(0), ids, amounts);
    }

    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        balanceOf[from][id] -= amount;

        emit TransferSingle(msg.sender, from, address(0), id, amount);
    }
}

/// @notice A generic interface for a contract which properly accepts ERC1155 tokens.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC1155.sol)
abstract contract ERC1155TokenReceiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC1155TokenReceiver.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC1155TokenReceiver.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @title MoonNFTEventsAndErrors
/// @author Aspyn Palatnick (aspyn.eth, stuckinaboot.eth)
contract MoonNFTEventsAndErrors {
    // Event to be emitted when alien art address is updated
    event AlienArtAddressUpdated(
        uint256 indexed tokenId,
        address indexed alienArtAddress
    );

    // Event to be emitted when mint with referrer occurs
    event MintedWithReferrer(
        // Referrer address
        address indexed referrerAddress,
        // Referrer token
        uint256 indexed referrerToken,
        // Minter address
        address indexed minterAddress,
        // Token id of first token minted during this mint
        uint256 mintStartTokenId,
        // Amount of tokens minted
        uint256 amount,
        // Value paid to referrer
        uint256 referrerPayout,
        // Value paid to referred
        uint256 referredPayout
    );

    // Event to emitted when moon regeneration occurs
    event MoonRegenerated(
        address indexed moonOwner,
        uint256 indexed tokenId,
        bytes32 indexed newMoonSeed,
        bytes32 previousMoonSeed,
        uint8 regenerationsUsed
    );

    // Mint errors
    error MaxSupplyReached();
    error WrongEtherAmount();

    // Regeneration errors
    error NoRegenerationsRemaining();

    // Alien art token-level errors
    error AlienArtContractFailedValidation();
    error OwnerNotMsgSender();
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity 0.8.17;

import "./Context.sol";

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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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
// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity 0.8.17;

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
pragma solidity ^0.8.13;

import {OperatorFilterer} from "./OperatorFilterer.sol";

abstract contract DefaultOperatorFilterer is OperatorFilterer {
    address constant DEFAULT_SUBSCRIPTION =
        address(0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6);

    constructor() OperatorFilterer(DEFAULT_SUBSCRIPTION, true) {}
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.2.3
// Creator: Chiru Labs

pragma solidity ^0.8.4;

/**
 * @dev Interface of ERC721A.
 */
interface IERC721A {
    /**
     * The caller must own the token or be an approved operator.
     */
    error ApprovalCallerNotOwnerNorApproved();

    /**
     * The token does not exist.
     */
    error ApprovalQueryForNonexistentToken();

    /**
     * Cannot query the balance for the zero address.
     */
    error BalanceQueryForZeroAddress();

    /**
     * Cannot mint to the zero address.
     */
    error MintToZeroAddress();

    /**
     * The quantity of tokens minted must be more than zero.
     */
    error MintZeroQuantity();

    /**
     * The token does not exist.
     */
    error OwnerQueryForNonexistentToken();

    /**
     * The caller must own the token or be an approved operator.
     */
    error TransferCallerNotOwnerNorApproved();

    /**
     * The token must be owned by `from`.
     */
    error TransferFromIncorrectOwner();

    /**
     * Cannot safely transfer to a contract that does not implement the
     * ERC721Receiver interface.
     */
    error TransferToNonERC721ReceiverImplementer();

    /**
     * Cannot transfer to the zero address.
     */
    error TransferToZeroAddress();

    /**
     * The token does not exist.
     */
    error URIQueryForNonexistentToken();

    /**
     * The `quantity` minted with ERC2309 exceeds the safety limit.
     */
    error MintERC2309QuantityExceedsLimit();

    /**
     * The `extraData` cannot be set on an unintialized ownership slot.
     */
    error OwnershipNotInitializedForExtraData();

    // =============================================================
    //                            STRUCTS
    // =============================================================

    struct TokenOwnership {
        // The address of the owner.
        address addr;
        // Stores the start time of ownership with minimal overhead for tokenomics.
        uint64 startTimestamp;
        // Whether the token has been burned.
        bool burned;
        // Arbitrary data similar to `startTimestamp` that can be set via {_extraData}.
        uint24 extraData;
    }

    // =============================================================
    //                         TOKEN COUNTERS
    // =============================================================

    /**
     * @dev Returns the total number of tokens in existence.
     * Burned tokens will reduce the count.
     * To get the total number of tokens minted, please see {_totalMinted}.
     */
    function totalSupply() external view returns (uint256);

    // =============================================================
    //                            IERC165
    // =============================================================

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * [EIP section](https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified)
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    // =============================================================
    //                            IERC721
    // =============================================================

    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables
     * (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in `owner`'s account.
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
     * @dev Safely transfers `tokenId` token from `from` to `to`,
     * checking first that contract recipients are aware of the ERC721 protocol
     * to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move
     * this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement
     * {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external payable;

    /**
     * @dev Equivalent to `safeTransferFrom(from, to, tokenId, '')`.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable;

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom}
     * whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token
     * by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the
     * zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external payable;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom}
     * for any token owned by the caller.
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
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    // =============================================================
    //                        IERC721Metadata
    // =============================================================

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

    // =============================================================
    //                           IERC2309
    // =============================================================

    /**
     * @dev Emitted when tokens in `fromTokenId` to `toTokenId`
     * (inclusive) is transferred from `from` to `to`, as defined in the
     * [ERC2309](https://eips.ethereum.org/EIPS/eip-2309) standard.
     *
     * See {_mintERC2309} for more details.
     */
    event ConsecutiveTransfer(uint256 indexed fromTokenId, uint256 toTokenId, address indexed from, address indexed to);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// Colors describing the moon image.
struct MoonImageColors {
    string moon;
    uint16 moonHue;
    string border;
    uint8 borderSaturation;
    string background;
    uint8 backgroundLightness;
    string backgroundGradientColor;
}

// Config describing the complete moon image, with colors, positioning, and sizing.
struct MoonImageConfig {
    MoonImageColors colors;
    uint16 moonRadius;
    uint16 xOffset;
    uint16 yOffset;
    uint16 viewWidth;
    uint16 viewHeight;
    uint16 borderRadius;
    uint16 borderWidth;
    string borderType;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Utils} from "../utils/Utils.sol";

// Core SVG utility library which helps us construct
// onchain SVG's with a simple, web-like API.
// Props to w1nt3r.eth for creating the core of this SVG utility library.
library svg {
    string internal constant NULL = "";

    /* MAIN ELEMENTS */
    function svgTag(string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el("svg", _props, _children);
    }

    function defs(string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el("defs", NULL, _children);
    }

    function g(string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el("g", _props, _children);
    }

    function circle(string memory _props)
        internal
        pure
        returns (string memory)
    {
        return el("circle", _props, NULL);
    }

    function mask(string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el("mask", _props, _children);
    }

    function radialGradient(string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el("radialGradient", _props, _children);
    }

    function stop(string memory _props) internal pure returns (string memory) {
        return el("stop", _props, NULL);
    }

    function ellipse(string memory _props)
        internal
        pure
        returns (string memory)
    {
        return el("ellipse", _props, NULL);
    }

    function rect(string memory _props) internal pure returns (string memory) {
        return el("rect", _props, NULL);
    }

    function filter(string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el("filter", _props, _children);
    }

    function feSpecularLighting(string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el("feSpecularLighting", _props, _children);
    }

    function fePointLight(string memory _props)
        internal
        pure
        returns (string memory)
    {
        return el("fePointLight", _props, NULL);
    }

    function feComposite(string memory _props)
        internal
        pure
        returns (string memory)
    {
        return el("feComposite", _props, NULL);
    }

    /* COMMON */
    // A generic element, can be used to construct any SVG (or HTML) element
    function el(
        string memory _tag,
        string memory _props,
        string memory _children
    ) internal pure returns (string memory) {
        return
            string.concat(
                "<",
                _tag,
                " ",
                _props,
                ">",
                _children,
                "</",
                _tag,
                ">"
            );
    }

    // an SVG attribute
    function prop(string memory _key, string memory _val)
        internal
        pure
        returns (string memory)
    {
        return string.concat(_key, '="', _val, '" ');
    }

    function prop(string memory _key, uint256 _val)
        internal
        pure
        returns (string memory)
    {
        return prop(_key, Utils.uint2str(_val));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Utils} from "./Utils.sol";

/// @title Traits
/// @author Aspyn Palatnick (aspyn.eth, stuckinaboot.eth)
library Traits {
    function _getTrait(
        string memory traitType,
        string memory value,
        bool includeTrailingComma,
        bool includeValueQuotes
    ) internal pure returns (string memory) {
        return
            string.concat(
                '{"trait_type":"',
                traitType,
                '","value":',
                includeValueQuotes ? string.concat('"', value, '"') : value,
                "}",
                includeTrailingComma ? "," : ""
            );
    }

    function getTrait(
        string memory traitType,
        string memory value,
        bool includeTrailingComma
    ) internal pure returns (string memory) {
        return _getTrait(traitType, value, includeTrailingComma, true);
    }

    function getTrait(
        string memory traitType,
        uint256 value,
        bool includeTrailingComma
    ) internal pure returns (string memory) {
        return
            _getTrait(
                traitType,
                Utils.uint2str(value),
                includeTrailingComma,
                false
            );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @title  OwnerPermissionedTokenRegistry
 * @author James Wenzel (emo.eth)
 * @notice Interface for a generic registry of tokens, where the owner of a token contract (as specified by the Ownable
 *         interface) is allowed to register the token as part of the registry and configure addresses allowed to call
 *         into subclass methods, as permissioned by the onlyTokenOrAllowedUpdater modifier.
 *
 *         This base registry interface includes methods to see if a token is registered, and the allowedUpdaters,
 *         if any, for registered tokens.
 */
interface OwnerPermissionedTokenRegistryInterface {
    error TokenNotRegistered(address tokenAddress);
    error TokenAlreadyRegistered(address tokenAddress);
    error NotAllowedUpdater();
    error NotTokenOrOwner(address token, address actualOwner);

    event TokenRegistered(address indexed tokenAddress);

    function registerToken(address tokenAddress) external;

    function addAllowedUpdater(address tokenAddress, address newAllowedUpdater)
        external;

    function removeAllowedUpdater(
        address tokenAddress,
        address allowedUpdaterToRemove
    ) external;

    function getAllowedUpdaters(address tokenAddress)
        external
        returns (address[] memory);

    function isAllowedUpdater(address tokenAddress, address updater)
        external
        returns (bool);

    function isTokenRegistered(address tokenAddress)
        external
        returns (bool isRegistered);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @title AlienArtConstellationEventsAndErrors
/// @author Aspyn Palatnick (aspyn.eth, stuckinaboot.eth)
contract AlienArtConstellationEventsAndErrors {
    // Event to be emitted when swap constellations occurs
    event SwapConstellations(
        address indexed owner,
        uint256 indexed moon1,
        uint256 indexed moon2,
        uint256 newConstellationForMoon1,
        uint256 newConstellationForMoon2
    );

    // Set moon address errors
    error MoonAddressAlreadySet();

    // Mint errors
    error MsgSenderNotMoonAddress();

    // Swap constellations errors
    error SwapMoonsOwnerMustBeMsgSender();

    // Uri errors
    error InvalidConstellationIndex();
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./SVG.sol";
import {Utils} from "../../utils/Utils.sol";
import {LibPRNG} from "../../utils/LibPRNG.sol";

/// @title ConstellationLib
/// @author Aspyn Palatnick (aspyn.eth, stuckinaboot.eth)
library ConstellationLib {
    // Constellations
    using LibPRNG for LibPRNG.PRNG;

    struct GenerateConstellationParams {
        uint256 x;
        uint256 y;
        uint16 rotationInDegrees;
        uint16 rotationCenterX;
        uint16 rotationCenterY;
        string starColor;
        bool fluxConstellation;
        bytes32 moonSeed;
    }

    function getLittleDipper(GenerateConstellationParams memory params)
        internal
        pure
        returns (string memory)
    {
        uint256 x = params.x;
        uint256 y = params.y;

        string memory handle = string.concat(
            getStar(params, x, y),
            getStar(params, x + 11, y + 9),
            getStar(params, x + 26, y + 15),
            getStar(params, x + 43, y + 14)
        );
        string memory cup = string.concat(
            getStar(params, x + 57, y + 5),
            getStar(params, x + 64, y + 14),
            getStar(params, x + 47, y + 23)
        );

        return
            makeConstellation(
                params.rotationInDegrees,
                params.rotationCenterX,
                params.rotationCenterY,
                string.concat(cup, handle)
            );
    }

    function getBigDipper(GenerateConstellationParams memory params)
        internal
        pure
        returns (string memory)
    {
        uint256 x = params.x;
        uint256 y = params.y;

        string memory cup = string.concat(
            getStar(params, x, y + 16),
            getStar(params, x + 11, y),
            getStar(params, x + 38, y + 13),
            getStar(params, x + 33, y + 30)
        );
        string memory handle = string.concat(
            getStar(params, x + 46, y + 45),
            getStar(params, x + 54, y + 58),
            getStar(params, x + 78, y + 66)
        );

        return
            makeConstellation(
                params.rotationInDegrees,
                params.rotationCenterX,
                params.rotationCenterY,
                string.concat(cup, handle)
            );
    }

    function getAries(GenerateConstellationParams memory params)
        internal
        pure
        returns (string memory)
    {
        uint256 x = params.x;
        uint256 y = params.y;

        string memory stars = string.concat(
            getStar(params, x, y),
            getStar(params, x + 35, y - 19),
            getStar(params, x + 50, y - 21),
            getStar(params, x + 55, y - 16)
        );

        return
            makeConstellation(
                params.rotationInDegrees,
                params.rotationCenterX,
                params.rotationCenterY,
                stars
            );
    }

    function getPisces(GenerateConstellationParams memory params)
        internal
        pure
        returns (string memory)
    {
        uint256 x = params.x;
        uint256 y = params.y;

        string memory upperLine = string.concat(
            getStar(params, x, y),
            getStar(params, x + 7, y - 8),
            getStar(params, x + 17, y - 20),
            getStar(params, x + 24, y - 32),
            getStar(params, x + 21, y - 41),
            getStar(params, x + 30, y - 47)
        );
        string memory lowerLine = string.concat(
            getStar(params, x + 9, y - 2),
            getStar(params, x + 28, y - 7),
            getStar(params, x + 36, y - 5),
            getStar(params, x + 52, y - 6)
        );
        string memory lowerCirclePart1 = string.concat(
            getStar(params, x + 60, y - 2),
            getStar(params, x + 65, y - 6),
            getStar(params, x + 70, y - 2),
            getStar(params, x + 71, y + 5)
        );
        string memory lowerCirclePart2 = string.concat(
            getStar(params, x + 66, y + 9),
            getStar(params, x + 58, y + 8),
            getStar(params, x + 57, y + 1)
        );

        string memory stars = string.concat(
            upperLine,
            lowerLine,
            lowerCirclePart1,
            lowerCirclePart2
        );
        return
            makeConstellation(
                params.rotationInDegrees,
                params.rotationCenterX,
                params.rotationCenterY,
                stars
            );
    }

    function getAquarius(GenerateConstellationParams memory params)
        internal
        pure
        returns (string memory)
    {
        uint256 x = params.x;
        uint256 y = params.y;

        string memory bottomDownLine = string.concat(
            getStar(params, x, y),
            getStar(params, x + 12, y - 3),
            getStar(params, x + 20, y + 5),
            getStar(params, x + 22, y + 21)
        );
        string memory topAcrossLine = string.concat(
            getStar(params, x + 8, y - 21),
            getStar(params, x + 14, y - 26),
            getStar(params, x + 18, y - 21),
            getStar(params, x + 26, y - 27),
            getStar(params, x + 68, y - 10)
        );
        string memory middleDownLine = string.concat(
            getStar(params, x + 29, y - 11),
            getStar(params, x + 39, y - 1)
        );

        string memory stars = string.concat(
            bottomDownLine,
            topAcrossLine,
            middleDownLine
        );
        return
            makeConstellation(
                params.rotationInDegrees,
                params.rotationCenterX,
                params.rotationCenterY,
                stars
            );
    }

    function getCapricornus(GenerateConstellationParams memory params)
        internal
        pure
        returns (string memory)
    {
        uint256 x = params.x;
        uint256 y = params.y;

        string memory top = string.concat(
            getStar(params, x, y),
            getStar(params, x + 8, y - 1),
            getStar(params, x + 30, y + 5)
        );
        string memory left = string.concat(
            getStar(params, x + 7, y + 7),
            getStar(params, x + 13, y + 16),
            getStar(params, x + 30, y + 29)
        );
        string memory right = string.concat(
            getStar(params, x + 34, y + 26),
            getStar(params, x + 59, y + 3),
            getStar(params, x + 65, y - 3)
        );
        string memory stars = string.concat(top, left, right);
        return
            makeConstellation(
                params.rotationInDegrees,
                params.rotationCenterX,
                params.rotationCenterY,
                stars
            );
    }

    function getSagittarius(GenerateConstellationParams memory params)
        internal
        pure
        returns (string memory)
    {
        string memory stars = string.concat(
            getSagittariusLeft(params),
            getSagittariusMiddle(params),
            getSagittariusRight(params)
        );
        return
            makeConstellation(
                params.rotationInDegrees,
                params.rotationCenterX,
                params.rotationCenterY,
                stars
            );
    }

    function getOphiuchus(GenerateConstellationParams memory params)
        internal
        pure
        returns (string memory)
    {
        uint256 x = params.x;
        uint256 y = params.y;

        string memory stars = string.concat(
            getStar(params, x, y),
            getStar(params, x + 3, y - 22),
            getStar(params, x + 11, y - 32),
            getStar(params, x + 19, y - 24),
            getStar(params, x + 22, y + 5),
            getStar(params, x + 9, y + 4)
        );

        return
            makeConstellation(
                params.rotationInDegrees,
                params.rotationCenterX,
                params.rotationCenterY,
                // Avoid stack too deep error by adding last star here
                string.concat(stars, getStar(params, x + 33, y + 12))
            );
    }

    function getScorpius(GenerateConstellationParams memory params)
        internal
        pure
        returns (string memory)
    {
        uint256 x = params.x;
        uint256 y = params.y;

        string memory top = string.concat(
            getStar(params, x, y),
            getStar(params, x + 3, y - 10),
            getStar(params, x + 9, y - 15),
            getStar(params, x + 14, y - 1)
        );
        string memory middle = string.concat(
            getStar(params, x + 19, y + 2),
            getStar(params, x + 21, y + 6),
            getStar(params, x + 25, y + 16),
            getStar(params, x + 25, y + 32)
        );
        string memory bottom1 = string.concat(
            getStar(params, x + 32, y + 37),
            getStar(params, x + 42, y + 39),
            getStar(params, x + 50, y + 33)
        );
        string memory bottom2 = string.concat(
            getStar(params, x + 47, y + 30),
            getStar(params, x + 44, y + 23)
        );
        string memory stars = string.concat(top, middle, bottom1, bottom2);
        return
            makeConstellation(
                params.rotationInDegrees,
                params.rotationCenterX,
                params.rotationCenterY,
                stars
            );
    }

    function getLibra(GenerateConstellationParams memory params)
        internal
        pure
        returns (string memory)
    {
        uint256 x = params.x;
        uint256 y = params.y;

        string memory triangle = string.concat(
            getStar(params, x, y),
            getStar(params, x + 6, y - 17),
            getStar(params, x + 23, y - 19)
        );
        string memory left = string.concat(
            getStar(params, x + 9, y + 13),
            getStar(params, x + 7, y + 18)
        );
        string memory right = string.concat(
            getStar(params, x + 21, y - 6),
            getStar(params, x + 32, y + 5)
        );
        string memory stars = string.concat(triangle, left, right);
        return
            makeConstellation(
                params.rotationInDegrees,
                params.rotationCenterX,
                params.rotationCenterY,
                stars
            );
    }

    function getVirgo(GenerateConstellationParams memory params)
        internal
        pure
        returns (string memory)
    {
        uint256 x = params.x;
        uint256 y = params.y;

        string memory middle = string.concat(
            getStar(params, x + 8, y),
            getStar(params, x + 11, y - 11),
            getStar(params, x + 10, y - 26),
            getStar(params, x + 22, y - 28),
            getStar(params, x + 28, y - 10)
        );
        string memory top = string.concat(
            getStar(params, x + 4, y - 32),
            getStar(params, x, y - 46),
            getStar(params, x + 34, y - 34)
        );
        string memory bottomLeft = string.concat(
            getStar(params, x + 21, y + 12),
            getStar(params, x + 24, y + 10),
            getStar(params, x + 30, y + 18)
        );
        string memory bottomRight = string.concat(
            getStar(params, x + 33, y - 7),
            getStar(params, x + 37, y - 4),
            getStar(params, x + 48, y + 9)
        );
        string memory stars = string.concat(
            middle,
            top,
            bottomLeft,
            bottomRight
        );
        return
            makeConstellation(
                params.rotationInDegrees,
                params.rotationCenterX,
                params.rotationCenterY,
                stars
            );
    }

    function getLeo(GenerateConstellationParams memory params)
        internal
        pure
        returns (string memory)
    {
        uint256 x = params.x;
        uint256 y = params.y;

        string memory loop = string.concat(
            getStar(params, x, y),
            getStar(params, x + 4, y - 10),
            getStar(params, x + 14, y - 12),
            getStar(params, x + 35, y + 3),
            getStar(params, x + 45, y + 21),
            getStar(params, x + 30, y + 12)
        );
        string memory top = string.concat(
            getStar(params, x + 17, y - 19),
            getStar(params, x + 11, y - 30),
            getStar(params, x + 2, y - 29)
        );

        return
            makeConstellation(
                params.rotationInDegrees,
                params.rotationCenterX,
                params.rotationCenterY,
                string.concat(loop, top)
            );
    }

    function getCancer(GenerateConstellationParams memory params)
        internal
        pure
        returns (string memory)
    {
        uint256 x = params.x;
        uint256 y = params.y;

        string memory stars = string.concat(
            getStar(params, x, y),
            getStar(params, x + 14, y - 21),
            getStar(params, x + 28, y - 12),
            getStar(params, x + 12, y - 29),
            getStar(params, x + 11, y - 49)
        );

        return
            makeConstellation(
                params.rotationInDegrees,
                params.rotationCenterX,
                params.rotationCenterY,
                stars
            );
    }

    function getGemini(GenerateConstellationParams memory params)
        internal
        pure
        returns (string memory)
    {
        string memory stars = string.concat(
            getGeminiLeftPerson(params),
            getGeminiRightPerson(params)
        );
        return
            makeConstellation(
                params.rotationInDegrees,
                params.rotationCenterX,
                params.rotationCenterY,
                stars
            );
    }

    function getTaurus(GenerateConstellationParams memory params)
        internal
        pure
        returns (string memory)
    {
        uint256 x = params.x;
        uint256 y = params.y;

        string memory left = string.concat(
            getStar(params, x, y),
            getStar(params, x + 5, y - 13),
            getStar(params, x + 18, y - 2)
        );
        string memory middle1 = string.concat(
            getStar(params, x + 18, y + 11),
            getStar(params, x + 22, y + 5),
            getStar(params, x + 22, y + 9)
        );
        string memory middle2 = string.concat(
            getStar(params, x + 23, y + 13),
            getStar(params, x + 26, y + 9),
            getStar(params, x + 27, y + 13)
        );
        string memory bottom = string.concat(
            getStar(params, x + 34, y + 19),
            getStar(params, x + 49, y + 24),
            getStar(params, x + 51, y + 29)
        );
        string memory stars = string.concat(left, middle1, middle2, bottom);
        return
            makeConstellation(
                params.rotationInDegrees,
                params.rotationCenterX,
                params.rotationCenterY,
                stars
            );
    }

    // Helpers

    function getTransform(
        uint16 rotationInDegrees,
        uint16 rotationCenterX,
        uint16 rotationCenterY
    ) internal pure returns (string memory) {
        return
            svg.prop(
                "transform",
                string.concat(
                    "rotate(",
                    Utils.uint2str(rotationInDegrees),
                    " ",
                    Utils.uint2str(rotationCenterX),
                    " ",
                    Utils.uint2str(rotationCenterY),
                    ")"
                )
            );
    }

    function getStarTransform(uint256 x, uint256 y)
        internal
        pure
        returns (string memory)
    {
        return
            svg.prop(
                "transform",
                string.concat(
                    "translate(",
                    Utils.uint2str(x),
                    ",",
                    Utils.uint2str(y),
                    ") scale(0.03)"
                )
            );
    }

    function getStar(
        GenerateConstellationParams memory params,
        uint256 x,
        uint256 y
    ) internal pure returns (string memory) {
        string memory opacity;
        if (params.fluxConstellation) {
            LibPRNG.PRNG memory prng;
            prng.seed(
                keccak256(
                    abi.encodePacked(
                        params.rotationInDegrees,
                        params.moonSeed,
                        x,
                        y
                    )
                )
            );
            // Minimum 30, max 100
            opacity = Utils.uint2str(prng.uniform(71) + 30);
        } else {
            opacity = "100";
        }

        return
            svg.path(
                string.concat(
                    svg.prop(
                        "d",
                        "M 40 60 L 63.511 72.361 L 59.021 46.180 L 78.042 27.639 L 51.756 23.820 L 40 0 L 28.244 23.820 L 1.958 27.639 L 20.979 46.180 L 16.489 72.361 L 40 60"
                    ),
                    svg.prop("fill", params.starColor),
                    svg.prop("filter", "url(#glo)"),
                    svg.prop("opacity", string.concat(opacity, "%")),
                    getStarTransform(x, y)
                )
            );
    }

    function makeConstellation(
        uint16 rotationInDegrees,
        uint16 rotationCenterX,
        uint16 rotationCenterY,
        string memory starElt
    ) internal pure returns (string memory) {
        return
            svg.g(
                getTransform(
                    rotationInDegrees,
                    rotationCenterX,
                    rotationCenterY
                ),
                string.concat(
                    // Glow filter
                    svg.filter(
                        svg.prop("id", "glo"),
                        string.concat(
                            svg.feGaussianBlur(
                                string.concat(
                                    svg.prop("stdDeviation", "4"),
                                    svg.prop("result", "blur")
                                )
                            ),
                            svg.feMerge(
                                string.concat(
                                    svg.feMergeNode(svg.prop("in", "blur")),
                                    svg.feMergeNode(svg.prop("in", "blur")),
                                    svg.feMergeNode(svg.prop("in", "blur")),
                                    svg.feMergeNode(
                                        svg.prop("in", "SourceGraphic")
                                    )
                                )
                            )
                        )
                    ),
                    starElt
                )
            );
    }

    // Individual constellation helpers

    // Sagittarius helpers for groups of stars as we get stack too deep errors
    // including all stars in one function

    function getSagittariusLeft(GenerateConstellationParams memory params)
        internal
        pure
        returns (string memory)
    {
        uint256 x = params.x;
        uint256 y = params.y;
        return
            string.concat(
                getStar(params, x, y),
                getStar(params, x + 11, y + 5),
                getStar(params, x + 18, y + 2),
                getStar(params, x + 22, y + 7),
                getStar(params, x + 19, y + 13),
                getStar(params, x + 19, y - 7),
                getStar(params, x + 11, y - 17)
            );
    }

    function getSagittariusMiddle(GenerateConstellationParams memory params)
        internal
        pure
        returns (string memory)
    {
        uint256 x = params.x;
        uint256 y = params.y;
        return
            string.concat(
                getStar(params, x + 27, y - 6),
                getStar(params, x + 30, y - 10),
                getStar(params, x + 31, y - 20),
                getStar(params, x + 26, y - 21),
                getStar(params, x + 36, y - 20),
                getStar(params, x + 42, y - 28)
            );
    }

    function getSagittariusRight(GenerateConstellationParams memory params)
        internal
        pure
        returns (string memory)
    {
        uint256 x = params.x;
        uint256 y = params.y;
        return
            string.concat(
                getStar(params, x + 33, y - 3),
                getStar(params, x + 36, y - 9),
                getStar(params, x + 45, y - 15),
                getStar(params, x + 55, y - 11),
                getStar(params, x + 60, y - 7),
                getStar(params, x + 55, y + 6),
                getStar(params, x + 53, y + 14),
                getStar(params, x + 44, y + 12),
                getStar(params, x + 43, y + 23)
            );
    }

    // Gemini helpers for groups of stars as we get stack too deep errors
    // including all stars in one function

    function getGeminiLeftPerson(GenerateConstellationParams memory params)
        internal
        pure
        returns (string memory)
    {
        uint256 x = params.x;
        uint256 y = params.y;
        string memory leftPersonTop = string.concat(
            getStar(params, x, y),
            getStar(params, x + 10, y - 12),
            getStar(params, x + 13, y - 6),
            getStar(params, x + 20, y - 7)
        );
        string memory leftPersonBottom1 = string.concat(
            getStar(params, x + 13, y + 4),
            getStar(params, x + 13, y + 15),
            getStar(params, x + 11, y + 23)
        );
        string memory leftPersonBottom2 = string.concat(
            getStar(params, x + 13, y + 34),
            getStar(params, x + 1, y + 21),
            getStar(params, x + 3, y + 38)
        );
        return
            string.concat(leftPersonTop, leftPersonBottom1, leftPersonBottom2);
    }

    function getGeminiRightPerson(GenerateConstellationParams memory params)
        internal
        pure
        returns (string memory)
    {
        uint256 x = params.x;
        uint256 y = params.y;
        string memory rightPersonTop = string.concat(
            getStar(params, x + 28, y - 16),
            getStar(params, x + 29, y - 6),
            getStar(params, x + 38, y - 7)
        );
        string memory rightPersonBottom1 = string.concat(
            getStar(params, x + 28, y + 9),
            getStar(params, x + 30, y + 18),
            getStar(params, x + 30, y + 30)
        );
        string memory rightPersonBottom2 = string.concat(
            getStar(params, x + 25, y + 35),
            getStar(params, x + 40, y + 32)
        );
        return
            string.concat(
                rightPersonTop,
                rightPersonBottom1,
                rightPersonBottom2
            );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity 0.8.17;

import "./IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

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
    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// Core SVG utility library which helps us construct
// onchain SVG's with a simple, web-like API.
// Props to w1nt3r.eth for creating the core of this SVG utility library.
library svg {
    string internal constant NULL = "";

    /* MAIN ELEMENTS */
    function svgTag(string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el("svg", _props, _children);
    }

    function g(string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el("g", _props, _children);
    }

    function rect(string memory _props) internal pure returns (string memory) {
        return el("rect", _props, NULL);
    }

    function path(string memory _props) internal pure returns (string memory) {
        return el("path", _props, NULL);
    }

    function filter(string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el("filter", _props, _children);
    }

    function feGaussianBlur(string memory _props)
        internal
        pure
        returns (string memory)
    {
        return el("feGaussianBlur", _props, NULL);
    }

    function feMerge(string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el("feMerge", NULL, _children);
    }

    function feMergeNode(string memory _props)
        internal
        pure
        returns (string memory)
    {
        return el("feMergeNode", _props, NULL);
    }

    /* COMMON */
    // A generic element, can be used to construct any SVG (or HTML) element
    function el(
        string memory _tag,
        string memory _props,
        string memory _children
    ) internal pure returns (string memory) {
        return
            string.concat(
                "<",
                _tag,
                " ",
                _props,
                ">",
                _children,
                "</",
                _tag,
                ">"
            );
    }

    // an SVG attribute
    function prop(string memory _key, string memory _val)
        internal
        pure
        returns (string memory)
    {
        return string.concat(_key, '="', _val, '" ');
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity 0.8.17;

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
pragma solidity ^0.8.13;

import {IOperatorFilterRegistry} from "../interfaces/ext/IOperatorFilterRegistry.sol";

/**
 * @title  OperatorFilterer
 * @notice Abstract contract whose constructor automatically registers and optionally subscribes to or copies another
 *         registrant's entries in the OperatorFilterRegistry.
 * @dev    This smart contract is meant to be inherited by token contracts so they can use the following:
 *         - `onlyAllowedOperator` modifier for `transferFrom` and `safeTransferFrom` methods.
 *         - `onlyAllowedOperatorApproval` modifier for `approve` and `setApprovalForAll` methods.
 */
abstract contract OperatorFilterer {
    error OperatorNotAllowed(address operator);

    IOperatorFilterRegistry public constant OPERATOR_FILTER_REGISTRY =
        IOperatorFilterRegistry(0x000000000000AAeB6D7670E522A718067333cd4E);

    constructor(address subscriptionOrRegistrantToCopy, bool subscribe) {
        // If an inheriting token contract is deployed to a network without the registry deployed, the modifier
        // will not revert, but the contract will need to be registered with the registry once it is deployed in
        // order for the modifier to filter addresses.
        if (address(OPERATOR_FILTER_REGISTRY).code.length > 0) {
            if (subscribe) {
                OPERATOR_FILTER_REGISTRY.registerAndSubscribe(
                    address(this),
                    subscriptionOrRegistrantToCopy
                );
            } else {
                if (subscriptionOrRegistrantToCopy != address(0)) {
                    OPERATOR_FILTER_REGISTRY.registerAndCopyEntries(
                        address(this),
                        subscriptionOrRegistrantToCopy
                    );
                } else {
                    OPERATOR_FILTER_REGISTRY.register(address(this));
                }
            }
        }
    }

    modifier onlyAllowedOperator(address from) virtual {
        // Check registry code length to facilitate testing in environments without a deployed registry.
        if (address(OPERATOR_FILTER_REGISTRY).code.length > 0) {
            // Allow spending tokens from addresses with balance
            // Note that this still allows listings and marketplaces with escrow to transfer tokens if transferred
            // from an EOA.
            if (from == msg.sender) {
                _;
                return;
            }
            if (
                !OPERATOR_FILTER_REGISTRY.isOperatorAllowed(
                    address(this),
                    msg.sender
                )
            ) {
                revert OperatorNotAllowed(msg.sender);
            }
        }
        _;
    }

    modifier onlyAllowedOperatorApproval(address operator) virtual {
        // Check registry code length to facilitate testing in environments without a deployed registry.
        if (address(OPERATOR_FILTER_REGISTRY).code.length > 0) {
            if (
                !OPERATOR_FILTER_REGISTRY.isOperatorAllowed(
                    address(this),
                    operator
                )
            ) {
                revert OperatorNotAllowed(operator);
            }
        }
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IOperatorFilterRegistry {
    function isOperatorAllowed(address registrant, address operator)
        external
        view
        returns (bool);

    function register(address registrant) external;

    function registerAndSubscribe(address registrant, address subscription)
        external;

    function registerAndCopyEntries(
        address registrant,
        address registrantToCopy
    ) external;

    function unregister(address addr) external;

    function updateOperator(
        address registrant,
        address operator,
        bool filtered
    ) external;

    function updateOperators(
        address registrant,
        address[] calldata operators,
        bool filtered
    ) external;

    function updateCodeHash(
        address registrant,
        bytes32 codehash,
        bool filtered
    ) external;

    function updateCodeHashes(
        address registrant,
        bytes32[] calldata codeHashes,
        bool filtered
    ) external;

    function subscribe(address registrant, address registrantToSubscribe)
        external;

    function unsubscribe(address registrant, bool copyExistingEntries) external;

    function subscriptionOf(address addr) external returns (address registrant);

    function subscribers(address registrant)
        external
        returns (address[] memory);

    function subscriberAt(address registrant, uint256 index)
        external
        returns (address);

    function copyEntriesOf(address registrant, address registrantToCopy)
        external;

    function isOperatorFiltered(address registrant, address operator)
        external
        returns (bool);

    function isCodeHashOfFiltered(address registrant, address operatorWithCode)
        external
        returns (bool);

    function isCodeHashFiltered(address registrant, bytes32 codeHash)
        external
        returns (bool);

    function filteredOperators(address addr)
        external
        returns (address[] memory);

    function filteredCodeHashes(address addr)
        external
        returns (bytes32[] memory);

    function filteredOperatorAt(address registrant, uint256 index)
        external
        returns (address);

    function filteredCodeHashAt(address registrant, uint256 index)
        external
        returns (bytes32);

    function isRegistered(address addr) external returns (bool);

    function codeHashOf(address addr) external returns (bytes32);
}