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