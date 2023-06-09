// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import { INounsSeeder } from "contracts/interfaces/INounsSeeder.sol";
import { INounsDescriptorMinimal } from "contracts/interfaces/INounsDescriptorMinimal.sol";
import { INounsDescriptorV2 } from "contracts/interfaces/INounsDescriptorV2.sol";
import { IRoboNounsVRGDA } from "contracts/interfaces/IRoboNounsVRGDA.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { VRGDA } from "contracts/lib/VRGDA.sol";
import { RoboNounsToken } from "contracts/RoboNounsToken.sol";
import { toWadUnsafe, toDaysWadUnsafe, wadLn } from "solmate/src/utils/SignedWadMath.sol";

contract RoboNounsVRGDA is IRoboNounsVRGDA, Ownable {
    address public constant nounsDAO = 0x0BC3807Ec262cB779b38D65b38158acC3bfedE10;

    /// @notice Time of sale of the first RoboNoun, used to calculate VRGDA price
    uint256 public startTime;

    /// @notice How often the VRGDA price will update to reflect VRGDA pricing rules
    uint256 public updateInterval = 15 minutes;

    /// @notice the last block at which the last roboNoun was sold
    uint256 public lastTokenBlock;

    /// @notice The minimum price accepted in an auction
    uint256 public reservePrice;

    /// @notice The Nouns ERC721 token contract
    RoboNounsToken public roboNounsToken;

    /// @notice Target price for a token, to be scaled according to sales pace.
    /// @dev Represented as an 18 decimal fixed point number.
    int256 public targetPrice;

    /// @dev Precomputed constant that allows us to rewrite a pow() as an exp().
    /// @dev Represented as an 18 decimal fixed point number.
    int256 public decayConstant;

    /// @dev The total number of tokens to target selling every full unit of time.
    /// @dev Represented as an 18 decimal fixed point number.
    int256 public perTimeUnit;

    constructor(
        uint256 _reservePrice,
        int256 _targetPrice,
        uint256 _priceDecayPercent,
        uint256 _perTimeUnit,
        uint256 _updateInterval,
        address _token
    ) {
        decayConstant = wadLn(1e18 - (toDaysWadUnsafe(_priceDecayPercent) / 1e1));
        require(decayConstant < 0, "NON_NEGATIVE_DECAY_CONSTANT");

        roboNounsToken = RoboNounsToken(_token);
        startTime = block.timestamp;
        reservePrice = _reservePrice;
        targetPrice = _targetPrice;
        perTimeUnit = toDaysWadUnsafe(_perTimeUnit);
        updateInterval = _updateInterval;
    }

    /// @param expectedBlockNumber The block number to specify the traits of the token
    function buyNow(uint256 expectedBlockNumber) external payable {
        // will allow to mint token with traits generated from 4 last blocks (starting from parent, because current has not hash yet),
        require(
            expectedBlockNumber >= block.number - 4 || expectedBlockNumber >= lastTokenBlock,
            "Invalid block number"
        );

        // making it unable to get the a token with the traits for any previous token (pool is emptied when a noun is bought, this prevents buying duplicates)
        lastTokenBlock = block.number;

        require(msg.value >= reservePrice, "Below reservePrice");

        // Validate the purchase request against the VRGDA rules.
        uint256 price = getCurrentVRGDAPrice();
        require(msg.value >= price, "Insufficient funds");

        // Call settleAuction on the roboNouns contract.
        uint256 mintedNounId = roboNounsToken.mint(expectedBlockNumber);

        // Sends token to caller.
        roboNounsToken.transferFrom(address(this), msg.sender, mintedNounId);

        emit AuctionSettled(mintedNounId, msg.sender, price);

        _sendETH(msg.value);
    }

    /// @notice Set the auction reserve price.
    /// @dev Only callable by the owner.
    function setReservePrice(uint256 _reservePrice) external onlyOwner {
        reservePrice = _reservePrice;
        emit AuctionReservePriceUpdated(_reservePrice);
    }

    /// @notice Set the auction update interval.
    /// @dev Only callable by the owner.
    function setUpdateInterval(uint256 _updateInterval) external onlyOwner {
        updateInterval = _updateInterval;
        emit AuctionUpdateIntervalUpdated(_updateInterval);
    }

    /// @notice Set the auction target price.
    /// @dev Only callable by the owner.
    function setTargetPrice(int256 _targetPrice) external onlyOwner {
        targetPrice = _targetPrice;
        emit AuctionTargetPriceUpdated(_targetPrice);
    }

    /// @notice Set the auction price decay percent.
    /// @dev Only callable by the owner.
    function setPriceDecayPercent(uint256 _priceDecayPercent) external {
        decayConstant = wadLn(1e18 - (toDaysWadUnsafe(_priceDecayPercent) / 1e1));
        require(decayConstant < 0, "NON_NEGATIVE_DECAY_CONSTANT");
        emit AuctionPriceDecayPercentUpdated(_priceDecayPercent);
    }

    /// @notice Set the auction per time unit.
    /// @dev Only callable by the owner.
    function setPerTimeUnit(uint256 _perTimeUnit) external {
        perTimeUnit = toDaysWadUnsafe(_perTimeUnit);
        emit AuctionPerTimeUnitUpdated(_perTimeUnit);
    }

    /// @notice Fetch data associated with the noun for sale
    /// @dev This function should be called using the `pending` block tag.
    function fetchNextNoun()
        external
        view
        override
        returns (uint256 nounId, INounsSeeder.Seed memory seed, string memory svg, uint256 price, bytes32 hash)
    {
        uint256 nextId = roboNounsToken.currentNounId() + 1;
        INounsSeeder seeder = INounsSeeder(roboNounsToken.seeder());

        INounsDescriptorMinimal nounsDescriptor = roboNounsToken.nounsDescriptor();
        INounsDescriptorMinimal roboDescriptor = roboNounsToken.roboDescriptor();
        INounsDescriptorV2 descriptor = INounsDescriptorV2(address(roboNounsToken.roboDescriptor()));

        seed = seeder.generateSeed(nextId, nounsDescriptor, roboDescriptor, block.number - 1);

        // Generate the SVG from seed using the descriptor.
        svg = descriptor.generateSVGImage(seed);

        // Calculate price based on VRGDA rules.
        uint256 vrgdaPrice = getCurrentVRGDAPrice();
        price = vrgdaPrice > reservePrice ? vrgdaPrice : reservePrice;

        // Fetch the blockhash associated with this noun.
        hash = blockhash(block.number - 1);

        return (nextId, seed, svg, price, hash);
    }

    /// @notice Get the current price according to the VRGDA rules.
    /// @return price The current price in Wei
    function getCurrentVRGDAPrice() public view returns (uint256) {
        uint256 nextId = roboNounsToken.currentNounId() + 1;
        uint256 absoluteTimeSinceStart = block.timestamp - startTime;
        return
            VRGDA.getVRGDAPrice(
                toDaysWadUnsafe(absoluteTimeSinceStart - (absoluteTimeSinceStart % updateInterval)),
                targetPrice,
                decayConstant,
                // Theoretically calling toWadUnsafe with sold can silently overflow but under
                // any reasonable circumstance it will never be large enough. We use sold + 1 as
                // the VRGDA formula's n param represents the nth token and sold is the n-1th token.
                VRGDA.getTargetSaleTimeLinear(toWadUnsafe(nextId), perTimeUnit)
            );
    }

    function _sendETH(uint256 _value) internal {
        (bool sent, ) = nounsDAO.call{ value: _value }("");
        require(sent, "failed to send eth");
    }
}

// SPDX-License-Identifier: GPL-3.0

/// @title Interface for NounsSeeder

pragma solidity ^0.8.6;

import { INounsDescriptorMinimal } from "contracts/interfaces/INounsDescriptorMinimal.sol";

interface INounsSeeder {
    struct Seed {
        uint48 background;
        uint48 body;
        uint48 accessory;
        uint48 head;
        uint48 glasses;
    }

    function generateSeed(
        uint256 nounId,
        INounsDescriptorMinimal descriptor,
        INounsDescriptorMinimal nounsDescriptor,
        uint256 blockNumber
    ) external view returns (Seed memory);
}

// SPDX-License-Identifier: GPL-3.0

/// @title Common interface for NounsDescriptor versions, as used by NounsToken and NounsSeeder.

/*********************************
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░██░░░████░░██░░░████░░░ *
 * ░░██████░░░████████░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 *********************************/

pragma solidity ^0.8.6;

import { INounsSeeder } from "./INounsSeeder.sol";

interface INounsDescriptorMinimal {
    ///
    /// USED BY TOKEN
    ///

    function tokenURI(uint256 tokenId, INounsSeeder.Seed memory seed) external view returns (string memory);

    function dataURI(uint256 tokenId, INounsSeeder.Seed memory seed) external view returns (string memory);

    ///
    /// USED BY SEEDER
    ///

    function backgroundCount() external view returns (uint256);

    function bodyCount() external view returns (uint256);

    function accessoryCount() external view returns (uint256);

    function headCount() external view returns (uint256);

    function glassesCount() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0

/// @title Interface for NounsDescriptorV2

/*********************************
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░██░░░████░░██░░░████░░░ *
 * ░░██████░░░████████░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 *********************************/

pragma solidity ^0.8.6;

import { INounsSeeder } from "./INounsSeeder.sol";
import { ISVGRenderer } from "./ISVGRenderer.sol";
import { INounsArt } from "./INounsArt.sol";
import { INounsDescriptorMinimal } from "./INounsDescriptorMinimal.sol";

interface INounsDescriptorV2 is INounsDescriptorMinimal {
    event PartsLocked();

    event DataURIToggled(bool enabled);

    event BaseURIUpdated(string baseURI);

    event ArtUpdated(INounsArt art);

    event RendererUpdated(ISVGRenderer renderer);

    error EmptyPalette();
    error BadPaletteLength();
    error IndexNotFound();

    function arePartsLocked() external returns (bool);

    function isDataURIEnabled() external returns (bool);

    function baseURI() external returns (string memory);

    function palettes(uint8 paletteIndex) external view returns (bytes memory);

    function backgrounds(uint256 index) external view returns (string memory);

    function bodies(uint256 index) external view returns (bytes memory);

    function accessories(uint256 index) external view returns (bytes memory);

    function heads(uint256 index) external view returns (bytes memory);

    function glasses(uint256 index) external view returns (bytes memory);

    function backgroundCount() external view override returns (uint256);

    function bodyCount() external view override returns (uint256);

    function accessoryCount() external view override returns (uint256);

    function headCount() external view override returns (uint256);

    function glassesCount() external view override returns (uint256);

    function addManyBackgrounds(string[] calldata backgrounds) external;

    function addBackground(string calldata background) external;

    function setPalette(uint8 paletteIndex, bytes calldata palette) external;

    function addBodies(bytes calldata encodedCompressed, uint80 decompressedLength, uint16 imageCount) external;

    function addAccessories(bytes calldata encodedCompressed, uint80 decompressedLength, uint16 imageCount) external;

    function addHeads(bytes calldata encodedCompressed, uint80 decompressedLength, uint16 imageCount) external;

    function addGlasses(bytes calldata encodedCompressed, uint80 decompressedLength, uint16 imageCount) external;

    function setPalettePointer(uint8 paletteIndex, address pointer) external;

    function addBodiesFromPointer(address pointer, uint80 decompressedLength, uint16 imageCount) external;

    function addAccessoriesFromPointer(address pointer, uint80 decompressedLength, uint16 imageCount) external;

    function addHeadsFromPointer(address pointer, uint80 decompressedLength, uint16 imageCount) external;

    function addGlassesFromPointer(address pointer, uint80 decompressedLength, uint16 imageCount) external;

    function lockParts() external;

    function toggleDataURIEnabled() external;

    function setBaseURI(string calldata baseURI) external;

    function tokenURI(uint256 tokenId, INounsSeeder.Seed memory seed) external view override returns (string memory);

    function dataURI(uint256 tokenId, INounsSeeder.Seed memory seed) external view override returns (string memory);

    function genericDataURI(
        string calldata name,
        string calldata description,
        INounsSeeder.Seed memory seed
    ) external view returns (string memory);

    function generateSVGImage(INounsSeeder.Seed memory seed) external view returns (string memory);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import { INounsSeeder } from "contracts/interfaces/INounsSeeder.sol";

interface IRoboNounsVRGDA {
    event AuctionSettled(uint256 indexed nounId, address winner, uint256 amount);
    event AuctionReservePriceUpdated(uint256 reservePrice);
    event AuctionUpdateIntervalUpdated(uint256 updateInterval);
    event AuctionTargetPriceUpdated(int256 targetPrice);
    event AuctionPriceDecayPercentUpdated(uint256 priceDecayPercent);
    event AuctionPerTimeUnitUpdated(uint256 perTimeUnit);

    function buyNow(uint256 expectedBlockNumber) external payable;

    function fetchNextNoun()
        external
        view
        returns (uint256 nounId, INounsSeeder.Seed memory seed, string memory svg, uint256 price, bytes32 hash);

    function setReservePrice(uint256 reservePrice) external;
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
pragma solidity >=0.8.0;

import { unsafeDiv, unsafeWadDiv, unsafeWadMul, wadExp, wadLn, wadMul } from "solmate/src/utils/SignedWadMath.sol";

library VRGDA {
    /// @notice Calculate the price of a token according to the VRGDA formula.
    /// @param timeSinceStart Time passed since the VRGDA began, scaled by 1e18.
    /// @param targetPrice The target price for a token if sold on pace, scaled by 1e18.
    /// @param decayConstant A constant calculated as the natural log of the complement of the price decay percent, scaled by 1e18
    /// @param targetSaleTime The target time the tokens should be sold by, scaled by 1e18, relative to timeSinceStart
    /// @return The price of a token according to VRGDA, scaled by 1e18.
    function getVRGDAPrice(
        int256 timeSinceStart,
        int256 targetPrice,
        int256 decayConstant,
        int256 targetSaleTime
    ) internal pure returns (uint256) {
        unchecked {
            // prettier-ignore
            return uint256(wadMul(targetPrice, wadExp(unsafeWadMul(decayConstant,
                timeSinceStart - targetSaleTime)
            )));
        }
    }

    /// @dev Given a number of tokens sold, return the target time that number of tokens should be sold by using a linear schedule
    /// @param sold A number of tokens sold, scaled by 1e18, to get the corresponding target sale time for.
    /// @param perTimeUnit The number of tokens to target selling in 1 full unit of time, scaled by 1e18.
    /// @return The target time the tokens should be sold by, scaled by 1e18, where the time is
    /// relative, such that 0 means the tokens should be sold immediately when the VRGDA begins.
    function getTargetSaleTimeLinear(int256 sold, int256 perTimeUnit) internal pure returns (int256) {
        return unsafeWadDiv(sold, perTimeUnit);
    }

    /// @dev Given a number of tokens sold, return the target time that number of tokens should be sold by using a logistic schedule
    /// @param sold A number of tokens sold, scaled by 1e18, to get the corresponding target sale time for.
    /// @param timeScale The steepness of the logistic curve, scaled by 1e18.
    /// @param logisticLimit The maximum number of tokens of tokens to sell + 1
    /// @return The target time the tokens should be sold by, scaled by 1e18, where the time is
    /// relative, such that 0 means the tokens should be sold immediately when the VRGDA begins.
    function getTargetSaleTimeLogistic(
        int256 sold,
        int256 logisticLimit,
        int256 timeScale
    ) internal pure returns (int256) {
        unchecked {
            return -unsafeWadDiv(wadLn(unsafeDiv(logisticLimit * 2e18, sold + logisticLimit) - 1e18), timeScale);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0

/// @title The RoboNouns ERC-721 token

pragma solidity ^0.8.6;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { INounsDescriptorMinimal } from "contracts/interfaces/INounsDescriptorMinimal.sol";
import { INounsSeeder } from "contracts/interfaces/INounsSeeder.sol";
import { IRoboNounsToken } from "contracts/interfaces/IRoboNounsToken.sol";
import { ERC721 } from "contracts/base/ERC721.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract RoboNounsToken is IRoboNounsToken, Ownable, ERC721 {
    // An address who has permissions to mint RoboNouns
    address public minter;

    // the OG Nouns token URI descriptor
    INounsDescriptorMinimal public nounsDescriptor;

    // The RoboNouns token URI descriptor
    INounsDescriptorMinimal public roboDescriptor;

    // The RoboNouns token seeder
    INounsSeeder public seeder;

    // Whether the minter can be updated
    bool public isMinterLocked;

    // Whether the descriptor can be updated
    bool public isDescriptorLocked;

    // Whether the seeder can be updated
    bool public isSeederLocked;

    // The noun seeds
    mapping(uint256 => INounsSeeder.Seed) public seeds;

    // The internal noun ID tracker
    uint256 public currentNounId;

    /**
     * @notice Require that the minter has not been locked.
     */
    modifier whenMinterNotLocked() {
        require(!isMinterLocked, "Minter is locked");
        _;
    }

    /**
     * @notice Require that the descriptor has not been locked.
     */
    modifier whenDescriptorNotLocked() {
        require(!isDescriptorLocked, "Descriptor is locked");
        _;
    }

    /**
     * @notice Require that the seeder has not been locked.
     */
    modifier whenSeederNotLocked() {
        require(!isSeederLocked, "Seeder is locked");
        _;
    }

    /**
     * @notice Require that the sender is the minter.
     */
    modifier onlyMinter() {
        require(msg.sender == minter, "Sender is not the minter");
        _;
    }

    constructor(
        address _minter,
        INounsDescriptorMinimal _roboDescriptor,
        INounsDescriptorMinimal _nounsDescriptor,
        INounsSeeder _seeder
    ) ERC721("RoboNouns", "ROBO") {
        minter = _minter;
        roboDescriptor = _roboDescriptor;
        nounsDescriptor = _nounsDescriptor;
        seeder = _seeder;
    }

    /**
     * @notice Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator) public view override(IERC721, ERC721) returns (bool) {
        return super.isApprovedForAll(owner, operator);
    }

    /**
     * @notice Mint a RoboNoun and send it to the minter (auctionhouse)
     */
    function mint(uint256 blockNumber) public override onlyMinter returns (uint256) {
        return _mintTo(minter, currentNounId++, blockNumber);
    }

    /**
     * @notice Burn a roboNoun.
     */
    function burn(uint256 nounId) public override onlyMinter {
        _burn(nounId);
        emit NounBurned(nounId);
    }

    /**
     * @notice A distinct Uniform Resource Identifier (URI) for a given asset.
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "RoboNounsToken: URI query for nonexistent token");
        return roboDescriptor.tokenURI(tokenId, seeds[tokenId]);
    }

    /**
     * @notice Similar to `tokenURI`, but always serves a base64 encoded data URI
     * with the JSON contents directly inlined.
     */
    function dataURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "RoboNounsToken: URI query for nonexistent token");
        return roboDescriptor.dataURI(tokenId, seeds[tokenId]);
    }

    /**
     * @notice Set the token minter.
     * @dev Only callable by the owner when not locked.
     */
    function setMinter(address _minter) external override onlyOwner whenMinterNotLocked {
        minter = _minter;

        emit MinterUpdated(_minter);
    }

    /**
     * @notice Lock the minter.
     * @dev This cannot be reversed and is only callable by the owner when not locked.
     */
    function lockMinter() external override onlyOwner whenMinterNotLocked {
        isMinterLocked = true;

        emit MinterLocked();
    }

    /**
     * @notice Set the token URI descriptor.
     * @dev Only callable by the owner when not locked.
     */
    function setDescriptor(INounsDescriptorMinimal _descriptor) external override onlyOwner whenDescriptorNotLocked {
        roboDescriptor = _descriptor;
        emit DescriptorUpdated(_descriptor);
    }

    /**
     * @notice Lock the descriptor.
     * @dev This cannot be reversed and is only callable by the owner when not locked.
     */
    function lockDescriptor() external override onlyOwner whenDescriptorNotLocked {
        isDescriptorLocked = true;
        emit DescriptorLocked();
    }

    /**
     * @notice Set the token seeder.
     * @dev Only callable by the owner when not locked.
     */
    function setSeeder(INounsSeeder _seeder) external override onlyOwner whenSeederNotLocked {
        seeder = _seeder;
        emit SeederUpdated(_seeder);
    }

    /**
     * @notice Lock the seeder.
     * @dev This cannot be reversed and is only callable by the owner when not locked.
     */
    function lockSeeder() external override onlyOwner whenSeederNotLocked {
        isSeederLocked = true;
        emit SeederLocked();
    }

    /**
     * @notice Mint a Noun with `nounId` to the provided `to` address.
     */
    function _mintTo(address to, uint256 nounId, uint256 blockNumber) internal returns (uint256) {
        INounsSeeder.Seed memory seed = seeder.generateSeed(nounId, nounsDescriptor, roboDescriptor, blockNumber);
        seeds[nounId] = seed;

        _mint(owner(), to, nounId);
        emit NounCreated(nounId, seed);

        return nounId;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @notice Signed 18 decimal fixed point (wad) arithmetic library.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SignedWadMath.sol)
/// @author Modified from Remco Bloemen (https://xn--2-umb.com/22/exp-ln/index.html)

/// @dev Will not revert on overflow, only use where overflow is not possible.
function toWadUnsafe(uint256 x) pure returns (int256 r) {
    /// @solidity memory-safe-assembly
    assembly {
        // Multiply x by 1e18.
        r := mul(x, 1000000000000000000)
    }
}

/// @dev Takes an integer amount of seconds and converts it to a wad amount of days.
/// @dev Will not revert on overflow, only use where overflow is not possible.
/// @dev Not meant for negative second amounts, it assumes x is positive.
function toDaysWadUnsafe(uint256 x) pure returns (int256 r) {
    /// @solidity memory-safe-assembly
    assembly {
        // Multiply x by 1e18 and then divide it by 86400.
        r := div(mul(x, 1000000000000000000), 86400)
    }
}

/// @dev Takes a wad amount of days and converts it to an integer amount of seconds.
/// @dev Will not revert on overflow, only use where overflow is not possible.
/// @dev Not meant for negative day amounts, it assumes x is positive.
function fromDaysWadUnsafe(int256 x) pure returns (uint256 r) {
    /// @solidity memory-safe-assembly
    assembly {
        // Multiply x by 86400 and then divide it by 1e18.
        r := div(mul(x, 86400), 1000000000000000000)
    }
}

/// @dev Will not revert on overflow, only use where overflow is not possible.
function unsafeWadMul(int256 x, int256 y) pure returns (int256 r) {
    /// @solidity memory-safe-assembly
    assembly {
        // Multiply x by y and divide by 1e18.
        r := sdiv(mul(x, y), 1000000000000000000)
    }
}

/// @dev Will return 0 instead of reverting if y is zero and will
/// not revert on overflow, only use where overflow is not possible.
function unsafeWadDiv(int256 x, int256 y) pure returns (int256 r) {
    /// @solidity memory-safe-assembly
    assembly {
        // Multiply x by 1e18 and divide it by y.
        r := sdiv(mul(x, 1000000000000000000), y)
    }
}

function wadMul(int256 x, int256 y) pure returns (int256 r) {
    /// @solidity memory-safe-assembly
    assembly {
        // Store x * y in r for now.
        r := mul(x, y)

        // Equivalent to require(x == 0 || (x * y) / x == y)
        if iszero(or(iszero(x), eq(sdiv(r, x), y))) {
            revert(0, 0)
        }

        // Scale the result down by 1e18.
        r := sdiv(r, 1000000000000000000)
    }
}

function wadDiv(int256 x, int256 y) pure returns (int256 r) {
    /// @solidity memory-safe-assembly
    assembly {
        // Store x * 1e18 in r for now.
        r := mul(x, 1000000000000000000)

        // Equivalent to require(y != 0 && ((x * 1e18) / 1e18 == x))
        if iszero(and(iszero(iszero(y)), eq(sdiv(r, 1000000000000000000), x))) {
            revert(0, 0)
        }

        // Divide r by y.
        r := sdiv(r, y)
    }
}

function wadExp(int256 x) pure returns (int256 r) {
    unchecked {
        // When the result is < 0.5 we return zero. This happens when
        // x <= floor(log(0.5e18) * 1e18) ~ -42e18
        if (x <= -42139678854452767551) return 0;

        // When the result is > (2**255 - 1) / 1e18 we can not represent it as an
        // int. This happens when x >= floor(log((2**255 - 1) / 1e18) * 1e18) ~ 135.
        if (x >= 135305999368893231589) revert("EXP_OVERFLOW");

        // x is now in the range (-42, 136) * 1e18. Convert to (-42, 136) * 2**96
        // for more intermediate precision and a binary basis. This base conversion
        // is a multiplication by 1e18 / 2**96 = 5**18 / 2**78.
        x = (x << 78) / 5**18;

        // Reduce range of x to (-½ ln 2, ½ ln 2) * 2**96 by factoring out powers
        // of two such that exp(x) = exp(x') * 2**k, where k is an integer.
        // Solving this gives k = round(x / log(2)) and x' = x - k * log(2).
        int256 k = ((x << 96) / 54916777467707473351141471128 + 2**95) >> 96;
        x = x - k * 54916777467707473351141471128;

        // k is in the range [-61, 195].

        // Evaluate using a (6, 7)-term rational approximation.
        // p is made monic, we'll multiply by a scale factor later.
        int256 y = x + 1346386616545796478920950773328;
        y = ((y * x) >> 96) + 57155421227552351082224309758442;
        int256 p = y + x - 94201549194550492254356042504812;
        p = ((p * y) >> 96) + 28719021644029726153956944680412240;
        p = p * x + (4385272521454847904659076985693276 << 96);

        // We leave p in 2**192 basis so we don't need to scale it back up for the division.
        int256 q = x - 2855989394907223263936484059900;
        q = ((q * x) >> 96) + 50020603652535783019961831881945;
        q = ((q * x) >> 96) - 533845033583426703283633433725380;
        q = ((q * x) >> 96) + 3604857256930695427073651918091429;
        q = ((q * x) >> 96) - 14423608567350463180887372962807573;
        q = ((q * x) >> 96) + 26449188498355588339934803723976023;

        /// @solidity memory-safe-assembly
        assembly {
            // Div in assembly because solidity adds a zero check despite the unchecked.
            // The q polynomial won't have zeros in the domain as all its roots are complex.
            // No scaling is necessary because p is already 2**96 too large.
            r := sdiv(p, q)
        }

        // r should be in the range (0.09, 0.25) * 2**96.

        // We now need to multiply r by:
        // * the scale factor s = ~6.031367120.
        // * the 2**k factor from the range reduction.
        // * the 1e18 / 2**96 factor for base conversion.
        // We do this all at once, with an intermediate result in 2**213
        // basis, so the final right shift is always by a positive amount.
        r = int256((uint256(r) * 3822833074963236453042738258902158003155416615667) >> uint256(195 - k));
    }
}

function wadLn(int256 x) pure returns (int256 r) {
    unchecked {
        require(x > 0, "UNDEFINED");

        // We want to convert x from 10**18 fixed point to 2**96 fixed point.
        // We do this by multiplying by 2**96 / 10**18. But since
        // ln(x * C) = ln(x) + ln(C), we can simply do nothing here
        // and add ln(2**96 / 10**18) at the end.

        /// @solidity memory-safe-assembly
        assembly {
            r := shl(7, lt(0xffffffffffffffffffffffffffffffff, x))
            r := or(r, shl(6, lt(0xffffffffffffffff, shr(r, x))))
            r := or(r, shl(5, lt(0xffffffff, shr(r, x))))
            r := or(r, shl(4, lt(0xffff, shr(r, x))))
            r := or(r, shl(3, lt(0xff, shr(r, x))))
            r := or(r, shl(2, lt(0xf, shr(r, x))))
            r := or(r, shl(1, lt(0x3, shr(r, x))))
            r := or(r, lt(0x1, shr(r, x)))
        }

        // Reduce range of x to (1, 2) * 2**96
        // ln(2^k * x) = k * ln(2) + ln(x)
        int256 k = r - 96;
        x <<= uint256(159 - k);
        x = int256(uint256(x) >> 159);

        // Evaluate using a (8, 8)-term rational approximation.
        // p is made monic, we will multiply by a scale factor later.
        int256 p = x + 3273285459638523848632254066296;
        p = ((p * x) >> 96) + 24828157081833163892658089445524;
        p = ((p * x) >> 96) + 43456485725739037958740375743393;
        p = ((p * x) >> 96) - 11111509109440967052023855526967;
        p = ((p * x) >> 96) - 45023709667254063763336534515857;
        p = ((p * x) >> 96) - 14706773417378608786704636184526;
        p = p * x - (795164235651350426258249787498 << 96);

        // We leave p in 2**192 basis so we don't need to scale it back up for the division.
        // q is monic by convention.
        int256 q = x + 5573035233440673466300451813936;
        q = ((q * x) >> 96) + 71694874799317883764090561454958;
        q = ((q * x) >> 96) + 283447036172924575727196451306956;
        q = ((q * x) >> 96) + 401686690394027663651624208769553;
        q = ((q * x) >> 96) + 204048457590392012362485061816622;
        q = ((q * x) >> 96) + 31853899698501571402653359427138;
        q = ((q * x) >> 96) + 909429971244387300277376558375;
        /// @solidity memory-safe-assembly
        assembly {
            // Div in assembly because solidity adds a zero check despite the unchecked.
            // The q polynomial is known not to have zeros in the domain.
            // No scaling required because p is already 2**96 too large.
            r := sdiv(p, q)
        }

        // r is in the range (0, 0.125) * 2**96

        // Finalization, we need to:
        // * multiply by the scale factor s = 5.549…
        // * add ln(2**96 / 10**18)
        // * add k * ln(2)
        // * multiply by 10**18 / 2**96 = 5**18 >> 78

        // mul s * 5e18 * 2**96, base is now 5**18 * 2**192
        r *= 1677202110996718588342820967067443963516166;
        // add ln(2) * k * 5e18 * 2**192
        r += 16597577552685614221487285958193947469193820559219878177908093499208371 * k;
        // add ln(2**96 / 10**18) * 5e18 * 2**192
        r += 600920179829731861736702779321621459595472258049074101567377883020018308;
        // base conversion: mul 2**18 / 2**192
        r >>= 174;
    }
}

/// @dev Will return 0 instead of reverting if y is zero.
function unsafeDiv(int256 x, int256 y) pure returns (int256 r) {
    /// @solidity memory-safe-assembly
    assembly {
        // Divide x by y.
        r := sdiv(x, y)
    }
}

// SPDX-License-Identifier: GPL-3.0

/// @title Interface for SVGRenderer

/*********************************
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░██░░░████░░██░░░████░░░ *
 * ░░██████░░░████████░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 *********************************/

pragma solidity ^0.8.6;

interface ISVGRenderer {
    struct Part {
        bytes image;
        bytes palette;
    }

    struct SVGParams {
        Part[] parts;
        string background;
    }

    function generateSVG(SVGParams memory params) external view returns (string memory svg);

    function generateSVGPart(Part memory part) external view returns (string memory partialSVG);

    function generateSVGParts(Part[] memory parts) external view returns (string memory partialSVG);
}

// SPDX-License-Identifier: GPL-3.0

/// @title Interface for NounsArt

/*********************************
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░██░░░████░░██░░░████░░░ *
 * ░░██████░░░████████░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 *********************************/

pragma solidity ^0.8.6;

import { Inflate } from "../lib/Inflate.sol";
import { IInflator } from "./IInflator.sol";

interface INounsArt {
    error SenderIsNotDescriptor();

    error EmptyPalette();

    error BadPaletteLength();

    error EmptyBytes();

    error BadDecompressedLength();

    error BadImageCount();

    error ImageNotFound();

    error PaletteNotFound();

    event DescriptorUpdated(address oldDescriptor, address newDescriptor);

    event InflatorUpdated(address oldInflator, address newInflator);

    event BackgroundsAdded(uint256 count);

    event PaletteSet(uint8 paletteIndex);

    event BodiesAdded(uint16 count);

    event AccessoriesAdded(uint16 count);

    event HeadsAdded(uint16 count);

    event GlassesAdded(uint16 count);

    struct NounArtStoragePage {
        uint16 imageCount;
        uint80 decompressedLength;
        address pointer;
    }

    struct Trait {
        NounArtStoragePage[] storagePages;
        uint256 storedImagesCount;
    }

    function descriptor() external view returns (address);

    function inflator() external view returns (IInflator);

    function setDescriptor(address descriptor) external;

    function setInflator(IInflator inflator) external;

    function addManyBackgrounds(string[] calldata _backgrounds) external;

    function addBackground(string calldata _background) external;

    function palettes(uint8 paletteIndex) external view returns (bytes memory);

    function setPalette(uint8 paletteIndex, bytes calldata palette) external;

    function addBodies(bytes calldata encodedCompressed, uint80 decompressedLength, uint16 imageCount) external;

    function addAccessories(bytes calldata encodedCompressed, uint80 decompressedLength, uint16 imageCount) external;

    function addHeads(bytes calldata encodedCompressed, uint80 decompressedLength, uint16 imageCount) external;

    function addGlasses(bytes calldata encodedCompressed, uint80 decompressedLength, uint16 imageCount) external;

    function addBodiesFromPointer(address pointer, uint80 decompressedLength, uint16 imageCount) external;

    function setPalettePointer(uint8 paletteIndex, address pointer) external;

    function addAccessoriesFromPointer(address pointer, uint80 decompressedLength, uint16 imageCount) external;

    function addHeadsFromPointer(address pointer, uint80 decompressedLength, uint16 imageCount) external;

    function addGlassesFromPointer(address pointer, uint80 decompressedLength, uint16 imageCount) external;

    function backgroundsCount() external view returns (uint256);

    function backgrounds(uint256 index) external view returns (string memory);

    function heads(uint256 index) external view returns (bytes memory);

    function bodies(uint256 index) external view returns (bytes memory);

    function accessories(uint256 index) external view returns (bytes memory);

    function glasses(uint256 index) external view returns (bytes memory);

    function getBodiesTrait() external view returns (Trait memory);

    function getAccessoriesTrait() external view returns (Trait memory);

    function getHeadsTrait() external view returns (Trait memory);

    function getGlassesTrait() external view returns (Trait memory);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0 <0.9.0;

/// @notice Based on https://github.com/madler/zlib/blob/master/contrib/puff
/// @dev Modified the original code for gas optimizations
/// 1. Disable overflow/underflow checks
/// 2. Chunk some loop iterations
library Inflate {
    // Maximum bits in a code
    uint256 constant MAXBITS = 15;
    // Maximum number of literal/length codes
    uint256 constant MAXLCODES = 286;
    // Maximum number of distance codes
    uint256 constant MAXDCODES = 30;
    // Maximum codes lengths to read
    uint256 constant MAXCODES = (MAXLCODES + MAXDCODES);
    // Number of fixed literal/length codes
    uint256 constant FIXLCODES = 288;

    // Error codes
    enum ErrorCode {
        ERR_NONE, // 0 successful inflate
        ERR_NOT_TERMINATED, // 1 available inflate data did not terminate
        ERR_OUTPUT_EXHAUSTED, // 2 output space exhausted before completing inflate
        ERR_INVALID_BLOCK_TYPE, // 3 invalid block type (type == 3)
        ERR_STORED_LENGTH_NO_MATCH, // 4 stored block length did not match one's complement
        ERR_TOO_MANY_LENGTH_OR_DISTANCE_CODES, // 5 dynamic block code description: too many length or distance codes
        ERR_CODE_LENGTHS_CODES_INCOMPLETE, // 6 dynamic block code description: code lengths codes incomplete
        ERR_REPEAT_NO_FIRST_LENGTH, // 7 dynamic block code description: repeat lengths with no first length
        ERR_REPEAT_MORE, // 8 dynamic block code description: repeat more than specified lengths
        ERR_INVALID_LITERAL_LENGTH_CODE_LENGTHS, // 9 dynamic block code description: invalid literal/length code lengths
        ERR_INVALID_DISTANCE_CODE_LENGTHS, // 10 dynamic block code description: invalid distance code lengths
        ERR_MISSING_END_OF_BLOCK, // 11 dynamic block code description: missing end-of-block code
        ERR_INVALID_LENGTH_OR_DISTANCE_CODE, // 12 invalid literal/length or distance code in fixed or dynamic block
        ERR_DISTANCE_TOO_FAR, // 13 distance is too far back in fixed or dynamic block
        ERR_CONSTRUCT // 14 internal: error in construct()
    }

    // Input and output state
    struct State {
        //////////////////
        // Output state //
        //////////////////
        // Output buffer
        bytes output;
        // Bytes written to out so far
        uint256 outcnt;
        /////////////////
        // Input state //
        /////////////////
        // Input buffer
        bytes input;
        // Bytes read so far
        uint256 incnt;
        ////////////////
        // Temp state //
        ////////////////
        // Bit buffer
        uint256 bitbuf;
        // Number of bits in bit buffer
        uint256 bitcnt;
        //////////////////////////
        // Static Huffman codes //
        //////////////////////////
        Huffman lencode;
        Huffman distcode;
    }

    // Huffman code decoding tables
    struct Huffman {
        uint256[] counts;
        uint256[] symbols;
    }

    function bits(State memory s, uint256 need) private pure returns (ErrorCode, uint256) {
        unchecked {
            // Bit accumulator (can use up to 20 bits)
            uint256 val;

            // Load at least need bits into val
            val = s.bitbuf;
            while (s.bitcnt < need) {
                if (s.incnt == s.input.length) {
                    // Out of input
                    return (ErrorCode.ERR_NOT_TERMINATED, 0);
                }

                // Load eight bits
                val |= uint256(uint8(s.input[s.incnt++])) << s.bitcnt;
                s.bitcnt += 8;
            }

            // Drop need bits and update buffer, always zero to seven bits left
            s.bitbuf = val >> need;
            s.bitcnt -= need;

            // Return need bits, zeroing the bits above that
            uint256 ret = (val & ((1 << need) - 1));
            return (ErrorCode.ERR_NONE, ret);
        }
    }

    function _stored(State memory s) private pure returns (ErrorCode) {
        unchecked {
            // Length of stored block
            uint256 len;

            // Discard leftover bits from current byte (assumes s.bitcnt < 8)
            s.bitbuf = 0;
            s.bitcnt = 0;

            // Get length and check against its one's complement
            if (s.incnt + 4 > s.input.length) {
                // Not enough input
                return ErrorCode.ERR_NOT_TERMINATED;
            }
            len = uint256(uint8(s.input[s.incnt++]));
            len |= uint256(uint8(s.input[s.incnt++])) << 8;

            if (uint8(s.input[s.incnt++]) != (~len & 0xFF) || uint8(s.input[s.incnt++]) != ((~len >> 8) & 0xFF)) {
                // Didn't match complement!
                return ErrorCode.ERR_STORED_LENGTH_NO_MATCH;
            }

            // Copy len bytes from in to out
            if (s.incnt + len > s.input.length) {
                // Not enough input
                return ErrorCode.ERR_NOT_TERMINATED;
            }
            if (s.outcnt + len > s.output.length) {
                // Not enough output space
                return ErrorCode.ERR_OUTPUT_EXHAUSTED;
            }
            while (len != 0) {
                // Note: Solidity reverts on underflow, so we decrement here
                len -= 1;
                s.output[s.outcnt++] = s.input[s.incnt++];
            }

            // Done with a valid stored block
            return ErrorCode.ERR_NONE;
        }
    }

    function _decode(State memory s, Huffman memory h) private pure returns (ErrorCode, uint256) {
        unchecked {
            // Current number of bits in code
            uint256 len;
            // Len bits being decoded
            uint256 code = 0;
            // First code of length len
            uint256 first = 0;
            // Number of codes of length len
            uint256 count;
            // Index of first code of length len in symbol table
            uint256 index = 0;
            // Error code
            ErrorCode err;

            uint256 tempCode;
            for (len = 1; len <= MAXBITS; len += 5) {
                // Get next bit
                (err, tempCode) = bits(s, 1);
                if (err != ErrorCode.ERR_NONE) {
                    return (err, 0);
                }
                code |= tempCode;
                count = h.counts[len];

                // If length len, return symbol
                if (code < first + count) {
                    return (ErrorCode.ERR_NONE, h.symbols[index + (code - first)]);
                }
                // Else update for next length
                index += count;
                first += count;
                first <<= 1;
                code <<= 1;

                // Get next bit
                (err, tempCode) = bits(s, 1);
                if (err != ErrorCode.ERR_NONE) {
                    return (err, 0);
                }
                code |= tempCode;
                count = h.counts[len + 1];

                // If length len, return symbol
                if (code < first + count) {
                    return (ErrorCode.ERR_NONE, h.symbols[index + (code - first)]);
                }
                // Else update for next length
                index += count;
                first += count;
                first <<= 1;
                code <<= 1;

                // Get next bit
                (err, tempCode) = bits(s, 1);
                if (err != ErrorCode.ERR_NONE) {
                    return (err, 0);
                }
                code |= tempCode;
                count = h.counts[len + 2];

                // If length len, return symbol
                if (code < first + count) {
                    return (ErrorCode.ERR_NONE, h.symbols[index + (code - first)]);
                }
                // Else update for next length
                index += count;
                first += count;
                first <<= 1;
                code <<= 1;

                // Get next bit
                (err, tempCode) = bits(s, 1);
                if (err != ErrorCode.ERR_NONE) {
                    return (err, 0);
                }
                code |= tempCode;
                count = h.counts[len + 3];

                // If length len, return symbol
                if (code < first + count) {
                    return (ErrorCode.ERR_NONE, h.symbols[index + (code - first)]);
                }
                // Else update for next length
                index += count;
                first += count;
                first <<= 1;
                code <<= 1;

                // Get next bit
                (err, tempCode) = bits(s, 1);
                if (err != ErrorCode.ERR_NONE) {
                    return (err, 0);
                }
                code |= tempCode;
                count = h.counts[len + 4];

                // If length len, return symbol
                if (code < first + count) {
                    return (ErrorCode.ERR_NONE, h.symbols[index + (code - first)]);
                }
                // Else update for next length
                index += count;
                first += count;
                first <<= 1;
                code <<= 1;
            }

            // Ran out of codes
            return (ErrorCode.ERR_INVALID_LENGTH_OR_DISTANCE_CODE, 0);
        }
    }

    function _construct(
        Huffman memory h,
        uint256[] memory lengths,
        uint256 n,
        uint256 start
    ) private pure returns (ErrorCode) {
        unchecked {
            // Current symbol when stepping through lengths[]
            uint256 symbol;
            // Current length when stepping through h.counts[]
            uint256 len;
            // Number of possible codes left of current length
            uint256 left;
            // Offsets in symbol table for each length
            uint256[MAXBITS + 1] memory offs;

            // Count number of codes of each length
            for (len = 0; len <= MAXBITS; ++len) {
                h.counts[len] = 0;
            }
            for (symbol = 0; symbol < n; ++symbol) {
                // Assumes lengths are within bounds
                ++h.counts[lengths[start + symbol]];
            }
            // No codes!
            if (h.counts[0] == n) {
                // Complete, but decode() will fail
                return (ErrorCode.ERR_NONE);
            }

            // Check for an over-subscribed or incomplete set of lengths

            // One possible code of zero length
            left = 1;

            for (len = 1; len <= MAXBITS; len += 5) {
                // One more bit, double codes left
                left <<= 1;
                if (left < h.counts[len]) {
                    // Over-subscribed--return error
                    return ErrorCode.ERR_CONSTRUCT;
                }
                // Deduct count from possible codes
                left -= h.counts[len];

                // One more bit, double codes left
                left <<= 1;
                if (left < h.counts[len + 1]) {
                    // Over-subscribed--return error
                    return ErrorCode.ERR_CONSTRUCT;
                }
                // Deduct count from possible codes
                left -= h.counts[len + 1];

                // One more bit, double codes left
                left <<= 1;
                if (left < h.counts[len + 2]) {
                    // Over-subscribed--return error
                    return ErrorCode.ERR_CONSTRUCT;
                }
                // Deduct count from possible codes
                left -= h.counts[len + 2];

                // One more bit, double codes left
                left <<= 1;
                if (left < h.counts[len + 3]) {
                    // Over-subscribed--return error
                    return ErrorCode.ERR_CONSTRUCT;
                }
                // Deduct count from possible codes
                left -= h.counts[len + 3];

                // One more bit, double codes left
                left <<= 1;
                if (left < h.counts[len + 4]) {
                    // Over-subscribed--return error
                    return ErrorCode.ERR_CONSTRUCT;
                }
                // Deduct count from possible codes
                left -= h.counts[len + 4];
            }

            // Generate offsets into symbol table for each length for sorting
            offs[1] = 0;
            for (len = 1; len < MAXBITS; ++len) {
                offs[len + 1] = offs[len] + h.counts[len];
            }

            // Put symbols in table sorted by length, by symbol order within each length
            for (symbol = 0; symbol < n; ++symbol) {
                if (lengths[start + symbol] != 0) {
                    h.symbols[offs[lengths[start + symbol]]++] = symbol;
                }
            }

            // Left > 0 means incomplete
            return left > 0 ? ErrorCode.ERR_CONSTRUCT : ErrorCode.ERR_NONE;
        }
    }

    function _codes(State memory s, Huffman memory lencode, Huffman memory distcode) private pure returns (ErrorCode) {
        unchecked {
            // Decoded symbol
            uint256 symbol;
            // Length for copy
            uint256 len;
            // Distance for copy
            uint256 dist;
            // TODO Solidity doesn't support constant arrays, but these are fixed at compile-time
            // Size base for length codes 257..285
            uint16[29] memory lens = [
                3,
                4,
                5,
                6,
                7,
                8,
                9,
                10,
                11,
                13,
                15,
                17,
                19,
                23,
                27,
                31,
                35,
                43,
                51,
                59,
                67,
                83,
                99,
                115,
                131,
                163,
                195,
                227,
                258
            ];
            // Extra bits for length codes 257..285
            uint8[29] memory lext = [
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                1,
                1,
                1,
                1,
                2,
                2,
                2,
                2,
                3,
                3,
                3,
                3,
                4,
                4,
                4,
                4,
                5,
                5,
                5,
                5,
                0
            ];
            // Offset base for distance codes 0..29
            uint16[30] memory dists = [
                1,
                2,
                3,
                4,
                5,
                7,
                9,
                13,
                17,
                25,
                33,
                49,
                65,
                97,
                129,
                193,
                257,
                385,
                513,
                769,
                1025,
                1537,
                2049,
                3073,
                4097,
                6145,
                8193,
                12289,
                16385,
                24577
            ];
            // Extra bits for distance codes 0..29
            uint8[30] memory dext = [
                0,
                0,
                0,
                0,
                1,
                1,
                2,
                2,
                3,
                3,
                4,
                4,
                5,
                5,
                6,
                6,
                7,
                7,
                8,
                8,
                9,
                9,
                10,
                10,
                11,
                11,
                12,
                12,
                13,
                13
            ];
            // Error code
            ErrorCode err;

            // Decode literals and length/distance pairs
            while (symbol != 256) {
                (err, symbol) = _decode(s, lencode);
                if (err != ErrorCode.ERR_NONE) {
                    // Invalid symbol
                    return err;
                }

                if (symbol < 256) {
                    // Literal: symbol is the byte
                    // Write out the literal
                    if (s.outcnt == s.output.length) {
                        return ErrorCode.ERR_OUTPUT_EXHAUSTED;
                    }
                    s.output[s.outcnt] = bytes1(uint8(symbol));
                    ++s.outcnt;
                } else if (symbol > 256) {
                    uint256 tempBits;
                    // Length
                    // Get and compute length
                    symbol -= 257;
                    if (symbol >= 29) {
                        // Invalid fixed code
                        return ErrorCode.ERR_INVALID_LENGTH_OR_DISTANCE_CODE;
                    }

                    (err, tempBits) = bits(s, lext[symbol]);
                    if (err != ErrorCode.ERR_NONE) {
                        return err;
                    }
                    len = lens[symbol] + tempBits;

                    // Get and check distance
                    (err, symbol) = _decode(s, distcode);
                    if (err != ErrorCode.ERR_NONE) {
                        // Invalid symbol
                        return err;
                    }
                    (err, tempBits) = bits(s, dext[symbol]);
                    if (err != ErrorCode.ERR_NONE) {
                        return err;
                    }
                    dist = dists[symbol] + tempBits;
                    if (dist > s.outcnt) {
                        // Distance too far back
                        return ErrorCode.ERR_DISTANCE_TOO_FAR;
                    }

                    // Copy length bytes from distance bytes back
                    if (s.outcnt + len > s.output.length) {
                        return ErrorCode.ERR_OUTPUT_EXHAUSTED;
                    }
                    while (len != 0) {
                        // Note: Solidity reverts on underflow, so we decrement here
                        len -= 1;
                        s.output[s.outcnt] = s.output[s.outcnt - dist];
                        ++s.outcnt;
                    }
                } else {
                    s.outcnt += len;
                }
            }

            // Done with a valid fixed or dynamic block
            return ErrorCode.ERR_NONE;
        }
    }

    function _build_fixed(State memory s) private pure returns (ErrorCode) {
        unchecked {
            // Build fixed Huffman tables
            // TODO this is all a compile-time constant
            uint256 symbol;
            uint256[] memory lengths = new uint256[](FIXLCODES);

            // Literal/length table
            for (symbol = 0; symbol < 144; ++symbol) {
                lengths[symbol] = 8;
            }
            for (; symbol < 256; ++symbol) {
                lengths[symbol] = 9;
            }
            for (; symbol < 280; ++symbol) {
                lengths[symbol] = 7;
            }
            for (; symbol < FIXLCODES; ++symbol) {
                lengths[symbol] = 8;
            }

            _construct(s.lencode, lengths, FIXLCODES, 0);

            // Distance table
            for (symbol = 0; symbol < MAXDCODES; ++symbol) {
                lengths[symbol] = 5;
            }

            _construct(s.distcode, lengths, MAXDCODES, 0);

            return ErrorCode.ERR_NONE;
        }
    }

    function _fixed(State memory s) private pure returns (ErrorCode) {
        unchecked {
            // Decode data until end-of-block code
            return _codes(s, s.lencode, s.distcode);
        }
    }

    function _build_dynamic_lengths(State memory s) private pure returns (ErrorCode, uint256[] memory) {
        unchecked {
            uint256 ncode;
            // Index of lengths[]
            uint256 index;
            // Descriptor code lengths
            uint256[] memory lengths = new uint256[](MAXCODES);
            // Error code
            ErrorCode err;
            // Permutation of code length codes
            uint8[19] memory order = [16, 17, 18, 0, 8, 7, 9, 6, 10, 5, 11, 4, 12, 3, 13, 2, 14, 1, 15];

            (err, ncode) = bits(s, 4);
            if (err != ErrorCode.ERR_NONE) {
                return (err, lengths);
            }
            ncode += 4;

            // Read code length code lengths (really), missing lengths are zero
            for (index = 0; index < ncode; ++index) {
                (err, lengths[order[index]]) = bits(s, 3);
                if (err != ErrorCode.ERR_NONE) {
                    return (err, lengths);
                }
            }
            for (; index < 19; ++index) {
                lengths[order[index]] = 0;
            }

            return (ErrorCode.ERR_NONE, lengths);
        }
    }

    function _build_dynamic(State memory s) private pure returns (ErrorCode, Huffman memory, Huffman memory) {
        unchecked {
            // Number of lengths in descriptor
            uint256 nlen;
            uint256 ndist;
            // Index of lengths[]
            uint256 index;
            // Error code
            ErrorCode err;
            // Descriptor code lengths
            uint256[] memory lengths = new uint256[](MAXCODES);
            // Length and distance codes
            Huffman memory lencode = Huffman(new uint256[](MAXBITS + 1), new uint256[](MAXLCODES));
            Huffman memory distcode = Huffman(new uint256[](MAXBITS + 1), new uint256[](MAXDCODES));
            uint256 tempBits;

            // Get number of lengths in each table, check lengths
            (err, nlen) = bits(s, 5);
            if (err != ErrorCode.ERR_NONE) {
                return (err, lencode, distcode);
            }
            nlen += 257;
            (err, ndist) = bits(s, 5);
            if (err != ErrorCode.ERR_NONE) {
                return (err, lencode, distcode);
            }
            ndist += 1;

            if (nlen > MAXLCODES || ndist > MAXDCODES) {
                // Bad counts
                return (ErrorCode.ERR_TOO_MANY_LENGTH_OR_DISTANCE_CODES, lencode, distcode);
            }

            (err, lengths) = _build_dynamic_lengths(s);
            if (err != ErrorCode.ERR_NONE) {
                return (err, lencode, distcode);
            }

            // Build huffman table for code lengths codes (use lencode temporarily)
            err = _construct(lencode, lengths, 19, 0);
            if (err != ErrorCode.ERR_NONE) {
                // Require complete code set here
                return (ErrorCode.ERR_CODE_LENGTHS_CODES_INCOMPLETE, lencode, distcode);
            }

            // Read length/literal and distance code length tables
            index = 0;
            while (index < nlen + ndist) {
                // Decoded value
                uint256 symbol;
                // Last length to repeat
                uint256 len;

                (err, symbol) = _decode(s, lencode);
                if (err != ErrorCode.ERR_NONE) {
                    // Invalid symbol
                    return (err, lencode, distcode);
                }

                if (symbol < 16) {
                    // Length in 0..15
                    lengths[index++] = symbol;
                } else {
                    // Repeat instruction
                    // Assume repeating zeros
                    len = 0;
                    if (symbol == 16) {
                        // Repeat last length 3..6 times
                        if (index == 0) {
                            // No last length!
                            return (ErrorCode.ERR_REPEAT_NO_FIRST_LENGTH, lencode, distcode);
                        }
                        // Last length
                        len = lengths[index - 1];
                        (err, tempBits) = bits(s, 2);
                        if (err != ErrorCode.ERR_NONE) {
                            return (err, lencode, distcode);
                        }
                        symbol = 3 + tempBits;
                    } else if (symbol == 17) {
                        // Repeat zero 3..10 times
                        (err, tempBits) = bits(s, 3);
                        if (err != ErrorCode.ERR_NONE) {
                            return (err, lencode, distcode);
                        }
                        symbol = 3 + tempBits;
                    } else {
                        // == 18, repeat zero 11..138 times
                        (err, tempBits) = bits(s, 7);
                        if (err != ErrorCode.ERR_NONE) {
                            return (err, lencode, distcode);
                        }
                        symbol = 11 + tempBits;
                    }

                    if (index + symbol > nlen + ndist) {
                        // Too many lengths!
                        return (ErrorCode.ERR_REPEAT_MORE, lencode, distcode);
                    }
                    while (symbol != 0) {
                        // Note: Solidity reverts on underflow, so we decrement here
                        symbol -= 1;

                        // Repeat last or zero symbol times
                        lengths[index++] = len;
                    }
                }
            }

            // Check for end-of-block code -- there better be one!
            if (lengths[256] == 0) {
                return (ErrorCode.ERR_MISSING_END_OF_BLOCK, lencode, distcode);
            }

            // Build huffman table for literal/length codes
            err = _construct(lencode, lengths, nlen, 0);
            if (
                err != ErrorCode.ERR_NONE &&
                (err == ErrorCode.ERR_NOT_TERMINATED ||
                    err == ErrorCode.ERR_OUTPUT_EXHAUSTED ||
                    nlen != lencode.counts[0] + lencode.counts[1])
            ) {
                // Incomplete code ok only for single length 1 code
                return (ErrorCode.ERR_INVALID_LITERAL_LENGTH_CODE_LENGTHS, lencode, distcode);
            }

            // Build huffman table for distance codes
            err = _construct(distcode, lengths, ndist, nlen);
            if (
                err != ErrorCode.ERR_NONE &&
                (err == ErrorCode.ERR_NOT_TERMINATED ||
                    err == ErrorCode.ERR_OUTPUT_EXHAUSTED ||
                    ndist != distcode.counts[0] + distcode.counts[1])
            ) {
                // Incomplete code ok only for single length 1 code
                return (ErrorCode.ERR_INVALID_DISTANCE_CODE_LENGTHS, lencode, distcode);
            }

            return (ErrorCode.ERR_NONE, lencode, distcode);
        }
    }

    function _dynamic(State memory s) private pure returns (ErrorCode) {
        unchecked {
            // Length and distance codes
            Huffman memory lencode;
            Huffman memory distcode;
            // Error code
            ErrorCode err;

            (err, lencode, distcode) = _build_dynamic(s);
            if (err != ErrorCode.ERR_NONE) {
                return err;
            }

            // Decode data until end-of-block code
            return _codes(s, lencode, distcode);
        }
    }

    function puff(bytes memory source, uint256 destlen) internal pure returns (ErrorCode, bytes memory) {
        unchecked {
            // Input/output state
            State memory s = State(
                new bytes(destlen),
                0,
                source,
                0,
                0,
                0,
                Huffman(new uint256[](MAXBITS + 1), new uint256[](FIXLCODES)),
                Huffman(new uint256[](MAXBITS + 1), new uint256[](MAXDCODES))
            );
            // Temp: last bit
            uint256 last;
            // Temp: block type bit
            uint256 t;
            // Error code
            ErrorCode err;

            // Build fixed Huffman tables
            err = _build_fixed(s);
            if (err != ErrorCode.ERR_NONE) {
                return (err, s.output);
            }

            // Process blocks until last block or error
            while (last == 0) {
                // One if last block
                (err, last) = bits(s, 1);
                if (err != ErrorCode.ERR_NONE) {
                    return (err, s.output);
                }

                // Block type 0..3
                (err, t) = bits(s, 2);
                if (err != ErrorCode.ERR_NONE) {
                    return (err, s.output);
                }

                err = (
                    t == 0
                        ? _stored(s)
                        : (t == 1 ? _fixed(s) : (t == 2 ? _dynamic(s) : ErrorCode.ERR_INVALID_BLOCK_TYPE))
                );
                // type == 3, invalid

                if (err != ErrorCode.ERR_NONE) {
                    // Return with error
                    break;
                }
            }

            return (err, s.output);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0

/// @title Interface for Inflator

/*********************************
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░██░░░████░░██░░░████░░░ *
 * ░░██████░░░████████░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 *********************************/

pragma solidity ^0.8.6;

import { Inflate } from "../lib/Inflate.sol";

interface IInflator {
    function puff(bytes memory source, uint256 destlen) external pure returns (Inflate.ErrorCode, bytes memory);
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

// SPDX-License-Identifier: GPL-3.0

/// @title Interface for RoboNounsToken

pragma solidity ^0.8.6;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {INounsDescriptorMinimal} from "contracts/interfaces/INounsDescriptorMinimal.sol";
import {INounsSeeder} from "contracts/interfaces/INounsSeeder.sol";

interface IRoboNounsToken is IERC721 {
    event NounCreated(uint256 indexed tokenId, INounsSeeder.Seed seed);

    event NounBurned(uint256 indexed tokenId);

    event NounsDAOUpdated(address nounsDAO);

    event MinterUpdated(address minter);

    event MinterLocked();

    event DescriptorUpdated(INounsDescriptorMinimal descriptor);

    event DescriptorLocked();

    event SeederUpdated(INounsSeeder seeder);

    event SeederLocked();

    function mint(uint256 blockNumber) external returns (uint256);

    function burn(uint256 tokenId) external;

    function dataURI(uint256 tokenId) external returns (string memory);

    function setMinter(address minter) external;

    function lockMinter() external;

    function setDescriptor(INounsDescriptorMinimal descriptor) external;

    function lockDescriptor() external;

    function setSeeder(INounsSeeder seeder) external;

    function lockSeeder() external;
}

// SPDX-License-Identifier: MIT

/// @title ERC721 Token Implementation

/*********************************
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░██░░░████░░██░░░████░░░ *
 * ░░██████░░░████████░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 *********************************/

// LICENSE
// ERC721.sol modifies OpenZeppelin's ERC721.sol:
// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/6618f9f18424ade44116d0221719f4c93be6a078/contracts/token/ERC721/ERC721.sol
//
// ERC721.sol source code copyright OpenZeppelin licensed under the MIT License.
// With modifications by Nounders DAO.
//
//
// MODIFICATIONS:
// `_safeMint` and `_mint` contain an additional `creator` argument and
// emit two `Transfer` logs, rather than one. The first log displays the
// transfer (mint) from `address(0)` to the `creator`. The second displays the
// transfer from the `creator` to the `to` address. This enables correct
// attribution on various NFT marketplaces.

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

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
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
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
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
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
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
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
     * @dev Safely mints `tokenId`, transfers it to `to`, and emits two log events -
     * 1. Credits the `minter` with the mint.
     * 2. Shows transfer from the `minter` to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address creator, address to, uint256 tokenId) internal virtual {
        _safeMint(creator, to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(address creator, address to, uint256 tokenId, bytes memory _data) internal virtual {
        _mint(creator, to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId`, transfers it to `to`, and emits two log events -
     * 1. Credits the `creator` with the mint.
     * 2. Shows transfer from the `creator` to `to`.
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
    function _mint(address creator, address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), creator, tokenId);
        emit Transfer(creator, to, tokenId);
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
    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
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
                return retval == IERC721Receiver(to).onERC721Received.selector;
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
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual {}
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