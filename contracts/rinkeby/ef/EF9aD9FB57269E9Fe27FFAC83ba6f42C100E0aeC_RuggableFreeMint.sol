// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

/// @title RuggablesFreeMint
/// @author MilkyTaste @ Ao Collaboration Ltd.
/// This contract is only for testing purposes.

import "../RuggableRally.sol";

contract RuggableFreeMint is RuggableRally {
    constructor(address metadataAddr, address pullAddr) RuggableRally(metadataAddr, pullAddr) {}

    /**
     * Mint function.
     * @param to Address to mint to.
     * @param quantity Amount to mint.
     */
    function mint(address to, uint256 quantity) external {
        _mint(to, quantity);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

/// @title Ruggable Rally
/// @author MilkyTaste @ Ao Collaboration Ltd.
/// https://frj.com //FIXME
/// Manages rallies

import "./RuggableStats.sol";

contract RuggableRally is RuggableStats {
    //FIXME Events

    struct RallyConfig {
        uint64 rallyPeriod;
        uint16 staticBonus;
        //FIXME uint64 closureReward; ?
    }
    //FIXME Configurable
    RallyConfig public rallyConfig = RallyConfig(1 days, 100);

    //FIXME Gas optimise
    struct Rally {
        address creatorAddr;
        uint256 attackerId;
        uint256 targetId;
        uint64 bounty;
        uint64 startTime;
        uint64 totalContribution;
        bool closed;
    }

    struct RallyContribution {
        address contributorAddr;
        uint64 contribution;
    }

    Rally[] public rallies;
    mapping(uint256 => RallyContribution[]) public rallyContributions;

    constructor(address metadataAddr, address pullAddr) RuggableStats(metadataAddr, pullAddr) {}

    //
    // Rally
    //

    /**
     * Create a rally.
     * @param attackerId The id of the attacker.
     * @param targetId The id of the defender.
     * @param bounty The bounty of PULL to award contributors.
     * @return rallyId The id of the created rally.
     */
    function startRally(
        uint256 attackerId,
        uint256 targetId,
        uint64 bounty
    ) external returns (uint256 rallyId) {
        require(ownerOf(attackerId) == msg.sender, "RuggableRally: Not owner of token");
        require(ownerOf(targetId) != msg.sender, "RuggableRally: Owner of token");
        require(!isAttacking(attackerId), "RuggableRally: Token already attacking");
        _burnPull(bounty);
        setAttacker(attackerId, true);
        setDefender(targetId, true);
        Rally memory rally = Rally(msg.sender, attackerId, targetId, bounty, uint64(block.timestamp), 0, false);
        rallies.push(rally);
        return rallies.length - 1;
    }

    /**
     * Increase the bounty on an existing rally.
     * @param rallyId The ID of the rally to contribute to.
     * @param extraBounty The amount of PULL to add to the bounty.
     */
    function increaseBounty(uint256 rallyId, uint64 extraBounty) external {
        require(isRallyActive(rallyId), "RuggableRally: Rally is not active");
        require(rallies[rallyId].creatorAddr == msg.sender, "RuggableRally: Only creator can increase bounty");
        _burnPull(extraBounty);
        rallies[rallyId].bounty += extraBounty;
    }

    /**
     * Contribute to an ongoing rally.
     * @param rallyId The ID of the rally to contribute to.
     * @param contribution The amount of PULL to contribute.
     */
    function contributeToRally(uint256 rallyId, uint64 contribution) external {
        require(isRallyActive(rallyId), "RuggableRally: Rally is not active");
        require(rallies[rallyId].creatorAddr != msg.sender, "RuggableRally: Cannot contribute to own rally");
        _burnPull(contribution);
        rallyContributions[rallyId].push(RallyContribution(msg.sender, contribution));
        rallies[rallyId].totalContribution += contribution;
    }

    /**
     * Close a finished rally.
     * @param rallyId The ID of the rally to close.
     */
    function closeRally(uint256 rallyId) external {
        //FIXME Gas??
        require(!isRallyActive(rallyId), "RuggableRally: Rally is not active");
        Rally storage rally = rallies[rallyId];
        require(!rally.closed, "RuggableRally: Rally is not active");
        // Close it
        rally.closed = true;
        setAttacker(rally.attackerId, false);
        setDefender(rally.targetId, false);
        // Determine winner
        uint64 totalAttack = rally.bounty + rally.totalContribution;
        if (isRallyWinning(rallyId)) {
            // Send contributions
            RallyContribution[] storage contributions = rallyContributions[rallyId];
            for (uint256 i = 0; i < contributions.length; i++) {
                RallyContribution storage contribution = contributions[i];
                uint64 current = depositedPull(contribution.contributorAddr);
                uint64 reward = (contribution.contribution * totalAttack) / rally.totalContribution;
                _setAux(contribution.contributorAddr, current + reward);
            }
        }
        // Update defender PULL
        turnDefenceStatic(rally.targetId, totalAttack, rallyConfig.staticBonus);
    }

    //
    // Views
    //

    /**
     * Checks if a rally is active.
     * @param rallyId The ID of the rally to check.
     * @return active True if the rally is active, false otherwise.
     */
    function isRallyActive(uint256 rallyId) public view returns (bool active) {
        Rally storage rally = rallies[rallyId];
        return !rally.closed && (rally.startTime + rallyConfig.rallyPeriod > block.timestamp);
    }

    /**
     * Checks if a rally is winning (or won if the rally is closed).
     * @dev Defender wins in a draw.
     * @param rallyId The ID of the rally to check.
     * @return winning True if the attacker is winner, false otherwise.
     */
    function isRallyWinning(uint256 rallyId) public view returns (bool winning) {
        Rally storage rally = rallies[rallyId];
        return rally.bounty + rally.totalContribution > totalDefence(rally.targetId);
    }

    /**
     * Count all active rallies.
     */
    function countActiveRallies() public view returns (uint256 count) {
        for (uint256 i = 0; i < rallies.length; i++) {
            if (isRallyActive(i)) {
                count++;
            }
        }
        return count;
    }

    /**
     * List all active rallies.
     */
    function listActiveRallyIds() public view returns (uint256[] memory) {
        //FIXME Does this scale?
        uint256 totalActive = countActiveRallies();
        uint256 counter = totalActive - 1;
        uint256[] memory ids = new uint256[](totalActive);
        for (uint256 i = rallies.length; i-- > 0; ) {
            if (isRallyActive(i)) {
                ids[counter] = i;
                if (counter == 0) {
                    // Reverse loop break for optimisation
                    break;
                }
                counter--;
            }
        }
        return ids;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

/// @title Ruggable Stats
/// @author MilkyTaste @ Ao Collaboration Ltd.
/// https://frj.com //FIXME

import "./PullGenerator.sol";

contract RuggableStats is PullGenerator {
    struct StatsStruct {
        uint64 stakedDefence;
        uint64 staticDefence;
        bool isAttacker;
        uint8 isDefender;
    }
    mapping(uint256 => StatsStruct) public tokenStats;

    constructor(address metadataAddr, address pullAddr) PullGenerator(metadataAddr, pullAddr) {}

    //
    // Defence
    //

    /**
     * Stake pull in defence of your token.
     * @param tokenId The token ID.
     * @param amount The amount of pull to stake.
     */
    function stakeDefence(uint256 tokenId, uint64 amount) external {
        require(msg.sender == ownerOf(tokenId), "RuggableStats: Not token owner");
        uint64 bal = depositedPull(msg.sender);
        require(bal >= amount, "RuggableStats: Insufficient pull");
        _setAux(msg.sender, bal - amount);
        tokenStats[tokenId].stakedDefence += amount;
    }

    /**
     * Unstake pull in defence of your token.
     * @param tokenId The token ID.
     * @param amount The amount of pull to sunstake.
     */
    function unstakeDefence(uint256 tokenId, uint64 amount) external {
        require(msg.sender == ownerOf(tokenId), "RuggableStats: Not token owner");
        require(!isInUse(tokenId), "RuggableStats: Cannot unstake while in rally");
        require(tokenStats[tokenId].stakedDefence >= amount, "RuggableStats: Insufficient pull");
        uint64 bal = depositedPull(msg.sender);
        _setAux(msg.sender, bal + amount);
        tokenStats[tokenId].stakedDefence -= amount;
    }

    /**
     * Get the total defence of a token.
     * @param tokenId The token ID.
     */
    function totalDefence(uint256 tokenId) public view returns (uint64) {
        StatsStruct storage stats = tokenStats[tokenId];
        return stats.stakedDefence + stats.staticDefence;
    }

    /**
     * Converts defence from staked to static.
     * @dev Static defence removes from the amount before applying the change.
     * @param tokenId The token ID.
     * @param amount The amount of staked balance to convert.
     * @param bonus A bonus amount of static to add.
     */
    function turnDefenceStatic(
        uint256 tokenId,
        uint64 amount,
        uint64 bonus
    ) internal {
        StatsStruct storage stats = tokenStats[tokenId];
        if (amount > stats.staticDefence) {
            // Remove static from amount
            amount -= stats.staticDefence;
            if (amount > stats.stakedDefence) {
                stats.staticDefence += stats.stakedDefence + bonus;
                stats.stakedDefence = 0;
            } else {
                stats.staticDefence += amount + bonus;
                stats.stakedDefence -= amount;
            }
        }
    }

    //
    // Status
    //

    /**
     * Sets if this token is currently an attacker.
     * @param tokenId The token ID to check.
     * @param attacker Whether or not the token is currently an attacker.
     */
    function setAttacker(uint256 tokenId, bool attacker) internal {
        tokenStats[tokenId].isAttacker = attacker;
    }

    /**
     * Sets if this token is currently an defender.
     * @param tokenId The token ID to check.
     * @param defender Whether or not the token is currently an defender.
     */
    function setDefender(uint256 tokenId, bool defender) internal {
        if (defender) {
            tokenStats[tokenId].isDefender++;
        } else {
            tokenStats[tokenId].isDefender--;
        }
    }

    /**
     * Returns whether or not a token is currently in use.
     * @param tokenId The token ID to check.
     * @return inUse True if the token is currently an attacker or defender, false otherwise.
     */
    function isInUse(uint256 tokenId) public view returns (bool) {
        StatsStruct storage stats = tokenStats[tokenId];
        return stats.isAttacker || stats.isDefender > 0;
    }

    /**
     * Returns whether or not a token is currently in use.
     * @param tokenId The token ID to check.
     * @return inUse True if the token is currently an attacker, false otherwise.
     */
    function isAttacking(uint256 tokenId) public view returns (bool) {
        StatsStruct storage stats = tokenStats[tokenId];
        return stats.isAttacker;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

/// @title PullGenerator
/// @author MilkyTaste @ Ao Collaboration Ltd.
/// https://frj.com //FIXME

import "./Ruggables.sol";
import "./IPull.sol";

contract PullGenerator is Ruggables {
    uint256 public constant DAILY_RATE = 100;

    IPull public immutable pull;

    constructor(address metadataAddr, address pullAddr) Ruggables(metadataAddr) {
        pull = IPull(pullAddr);
    }

    /**
     * Calculate PULL owed on a token.
     * @dev Returns 0 for burned tokens.
     * @dev Returns a uint64 for optimisation. Max size 2^64-1.
     * @param tokenId The token to check.
     * @return pullOwed The amount of pull owed.
     */
    function calculateOwed(uint256 tokenId) public view returns (uint64) {
        TokenOwnership memory ownership = _ownershipOf(tokenId);
        if (ownership.burned) {
            return 0;
        }
        return uint64(((block.timestamp - ownership.startTimestamp) * DAILY_RATE) / 1 days);
    }

    /**
     * Calculate reward owed on a token.
     * @param tokenId The token to claim.
     */
    function claimReward(uint256 tokenId) public {
        //FIXME Restrict with ownership?
        TokenOwnership memory ownership = _ownershipOf(tokenId);
        uint64 bal = _getAux(ownership.addr);
        bal += calculateOwed(tokenId);
        _setAux(ownership.addr, bal);
        ownership.startTimestamp = uint64(block.timestamp);
    }

    /**
     * Show the deposited PULL balance.
     * @param addr The address to check.
     */
    function depositedPull(address addr) public view returns (uint64) {
        return _getAux(addr);
    }

    /**
     * Convert your stored balance to PULL.
     * @param amount The amount of PULL to withdraw.
     */
    function withdrawPull(uint64 amount) external {
        uint64 bal = depositedPull(msg.sender);
        require(bal >= amount, "PullGenerator: Insuffient pull");
        _setAux(msg.sender, bal - amount);
        pull.mint(msg.sender, amount);
    }

    /**
     * Convert your PULL to a stored balance.
     * @param amount The amount of PULL to deposit.
     */
    function depositPull(uint64 amount) external {
        uint64 bal = depositedPull(msg.sender);
        pull.burn(msg.sender, amount);
        _setAux(msg.sender, bal + amount);
    }

    /**
     * Burn your stored PULL.
     * @param amount The amount of PULL to burn.
     */
    function _burnPull(uint64 amount) internal {
        uint64 bal = depositedPull(msg.sender);
        require(bal >= amount, "PullGenerator: Insuffient pull");
        _setAux(msg.sender, bal - amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

/// @title Ruggables
/// @author MilkyTaste @ Ao Collaboration Ltd.
/// https://frj.com //FIXME

import "@openzeppelin/contracts/utils/Base64.sol";
import "erc721a/contracts/extensions/ERC721AOwnersExplicit.sol"; //FIXME Make this public
import "./IRuggableMetadata.sol";
import "./SVGGenerator.sol";

contract Ruggables is ERC721AOwnersExplicit {
    using Strings for uint256;

    address public immutable metadataAddr;

    mapping(uint256 => uint256[]) public idToCombination;

    constructor(address metadataAddr_) ERC721A("Ruggables", "RUG") {
        metadataAddr = metadataAddr_;
    }

    /**
     * Mint function.
     * @param to Address to mint to.
     * @param quantity Amount of tokens to mint.
     */
    function _mint(address to, uint256 quantity) internal {
        uint256 startId = _currentIndex;
        _safeMint(to, quantity);
        for (uint8 i = 0; i < quantity; i++) {
            uint256 tokenId = startId + i;
            idToCombination[tokenId] = craftRug(tokenId);
        }
    }

    function craftRug(uint256 tokenId) internal view returns (uint256[] memory colorCombination) {
        uint256[] memory colors = new uint256[](5);
        colors[0] = random(tokenId) % 1000;
        for (uint8 i = 1; i < 5; i++) {
            colors[i] = random(tokenId) % 21;
        }
        return colors;
    }

    function random(uint256 seed) internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, seed, totalSupply())));
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     * @dev Returns the metadata from the associated contract.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        return IRuggableMetadata(metadataAddr).tokenURI(tokenId, idToCombination[tokenId]);
    }

    //FIXME Enumerate
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

/// @title Pull Interface
/// @author MilkyTaste @ Ao Collaboration Ltd.
/// https://frj.com //FIXME

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IPull is IERC20 {
    /**
     * Mint new tokens.
     */
    function mint(address account, uint256 amount) external;

    /**
     * Burn tokens.
     */
    function burn(address account, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Base64.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides a set of functions to operate with Base64 strings.
 *
 * _Available since v4.5._
 */
library Base64 {
    /**
     * @dev Base64 Encoding/Decoding Table
     */
    string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /**
     * @dev Converts a `bytes` to its Bytes64 `string` representation.
     */
    function encode(bytes memory data) internal pure returns (string memory) {
        /**
         * Inspired by Brecht Devos (Brechtpd) implementation - MIT licence
         * https://github.com/Brechtpd/base64/blob/e78d9fd951e7b0977ddca77d92dc85183770daf4/base64.sol
         */
        if (data.length == 0) return "";

        // Loads the table into memory
        string memory table = _TABLE;

        // Encoding takes 3 bytes chunks of binary data from `bytes` data parameter
        // and split into 4 numbers of 6 bits.
        // The final Base64 length should be `bytes` data length multiplied by 4/3 rounded up
        // - `data.length + 2`  -> Round up
        // - `/ 3`              -> Number of 3-bytes chunks
        // - `4 *`              -> 4 characters for each chunk
        string memory result = new string(4 * ((data.length + 2) / 3));

        assembly {
            // Prepare the lookup table (skip the first "length" byte)
            let tablePtr := add(table, 1)

            // Prepare result pointer, jump over length
            let resultPtr := add(result, 32)

            // Run over the input, 3 bytes at a time
            for {
                let dataPtr := data
                let endPtr := add(data, mload(data))
            } lt(dataPtr, endPtr) {

            } {
                // Advance 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // To write each character, shift the 3 bytes (18 bits) chunk
                // 4 times in blocks of 6 bits for each character (18, 12, 6, 0)
                // and apply logical AND with 0x3F which is the number of
                // the previous character in the ASCII table prior to the Base64 Table
                // The result is then added to the table to get the character to write,
                // and finally write it in the result pointer but with a left shift
                // of 256 (1 byte) - 8 (1 ASCII char) = 248 bits

                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance
            }

            // When data `bytes` is not exactly 3 bytes long
            // it is padded with `=` characters at the end
            switch mod(mload(data), 3)
            case 1 {
                mstore8(sub(resultPtr, 1), 0x3d)
                mstore8(sub(resultPtr, 2), 0x3d)
            }
            case 2 {
                mstore8(sub(resultPtr, 1), 0x3d)
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import '../ERC721A.sol';

error AllOwnershipsHaveBeenSet();
error QuantityMustBeNonZero();
error NoTokensMintedYet();

abstract contract ERC721AOwnersExplicit is ERC721A {
    uint256 public nextOwnerToExplicitlySet;

    /**
     * @dev Explicitly set `owners` to eliminate loops in future calls of ownerOf().
     */
    function _setOwnersExplicit(uint256 quantity) internal {
        if (quantity == 0) revert QuantityMustBeNonZero();
        if (_currentIndex == _startTokenId()) revert NoTokensMintedYet();
        uint256 _nextOwnerToExplicitlySet = nextOwnerToExplicitlySet;
        if (_nextOwnerToExplicitlySet == 0) {
            _nextOwnerToExplicitlySet = _startTokenId();
        }
        if (_nextOwnerToExplicitlySet >= _currentIndex) revert AllOwnershipsHaveBeenSet();

        // Index underflow is impossible.
        // Counter or index overflow is incredibly unrealistic.
        unchecked {
            uint256 endIndex = _nextOwnerToExplicitlySet + quantity - 1;

            // Set the end index to be the last token index
            if (endIndex + 1 > _currentIndex) {
                endIndex = _currentIndex - 1;
            }

            for (uint256 i = _nextOwnerToExplicitlySet; i <= endIndex; i++) {
                if (_ownerships[i].addr == address(0) && !_ownerships[i].burned) {
                    TokenOwnership memory ownership = _ownershipOf(i);
                    _ownerships[i].addr = ownership.addr;
                    _ownerships[i].startTimestamp = ownership.startTimestamp;
                }
            }

            nextOwnerToExplicitlySet = endIndex + 1;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

/// @title Ruggable Metadata Interface
/// @author MilkyTaste @ Ao Collaboration Ltd.
/// https://frj.com //FIXME

interface IRuggableMetadata {
    /**
     * Generates the metadata for a Ruggable.
     * @param tokenId The token id.
     * @param combination Trait combination.
     * @return json Metadata JSON, Base64 encoded.
     */
    function tokenURI(uint256 tokenId, uint256[] memory combination) external pure returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @title SVG generator library
/// @author MilkyTaste @ Ao Collaboration Ltd.
/// https://frj.com //FIXME

library SVGGenerator {
    struct RuggableAttributes {
        uint256 pattern;
        uint256 background;
        uint256 colorOne;
        uint256 colorTwo;
        uint256 colorThree;
        bool set;
    }

    struct RandValues {
        uint256 patternSelect;
        uint256 backgroundSelect;
    }

    // solhint-disable code-complexity

    /**
     * Get the SVG content from the given combination.
     * @param combination Attributes for the SVG generation.
     */
    function getRugForSeed(uint256[] memory combination) internal pure returns (string memory, string memory) {
        RuggableAttributes memory rug;
        RandValues memory rand;
        string[10] memory patterns = [
            "Ether",
            "Circles",
            "Hoots",
            "Kaiju",
            "Heart",
            "Persian",
            "Encore",
            "Kubrick",
            "Mozaic",
            "NGMI"
        ];

        string[21] memory colors = [
            "deeppink",
            "darkturquoise",
            "orange",
            "gold",
            "white",
            "silver",
            "green",
            "darkviolet",
            "orangered",
            "lawngreen",
            "mediumvioletred",
            "red",
            "olivedrab",
            "bisque",
            "cornsilk",
            "darkorange",
            "slateblue",
            "floralwhite",
            "khaki",
            "crimson",
            "thistle"
        ];

        string[21] memory ngmiPalette = [
            "black",
            "red",
            "green",
            "blue",
            "maroon",
            "violet",
            "tan",
            "turquoise",
            "cyan",
            "darkred",
            "darkorange",
            "crimson",
            "darkviolet",
            "goldenrod",
            "forestgreen",
            "lime",
            "magenta",
            "springgreen",
            "teal",
            "navy",
            "indigo"
        ];

        // Determine the Pattern for the rug
        rand.patternSelect = combination[0];

        if (rand.patternSelect < 1) rug.pattern = 9;
        else if (rand.patternSelect < 60) rug.pattern = 8;
        else if (rand.patternSelect < 100) rug.pattern = 7;
        else if (rand.patternSelect < 160) rug.pattern = 6;
        else if (rand.patternSelect < 240) rug.pattern = 5;
        else if (rand.patternSelect < 340) rug.pattern = 4;
        else if (rand.patternSelect < 460) rug.pattern = 3;
        else if (rand.patternSelect < 580) rug.pattern = 2;
        else if (rand.patternSelect < 780) rug.pattern = 1;
        else rug.pattern = 0;

        // Rug Traits
        rug.background = combination[1];
        rug.colorOne = combination[2];
        rug.colorTwo = combination[3];
        rug.colorThree = combination[4];
        rug.set = (rug.colorOne == rug.colorTwo) && (rug.colorTwo == rug.colorThree);

        // solhint-disable quotes

        // Build the SVG from various parts
        string memory svg = string(
            abi.encodePacked(
                '<svg customPattern = "',
                Utils.uint2str(rug.pattern),
                '" xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 128 55" >'
            )
        );

        //svg = string(abi.encodePacked(svg, id));
        string memory currentSvg = "";
        if (rug.pattern == 0) {
            //ETHERS
            currentSvg = string(
                abi.encodePacked(
                    '<pattern id="rug" viewBox="5.5,0,10,10" width="24%" height="20%"><polygon points="-10,-10 -10,30 30,30 30,-10" fill ="',
                    colors[rug.background],
                    '"/><polygon points="0,5 9,1 10,1 10,2 8,4 1,5 8,6 10,8 10,9 9,9 0,5"/><polygon points="10,5 13,1 14,1  21,5 14,9 13,9 10,5"/><polygon points="13.25,2.25 14.5,5 13.25,7.75 11,5" fill="',
                    colors[rug.colorOne],
                    '"/><polygon points="14.5,2.5 15.5,4.5 18.5,4.5" fill="',
                    colors[rug.colorTwo],
                    '"/><polygon points="18.5,5.5 15.5,5.5 14.5,7.5" fill="',
                    colors[rug.colorThree],
                    '"/><polygon points="18.5,5.5 15.5,5.5 14.5,7.5" transform="scale(-1,-1) translate(-35,-15)"/><polygon points="14.5,2.5 15.5,4.5 18.5,4.5" transform="scale(-1,-1) translate(-35,-5)"/><polygon points="13.25,2.25 14.5,5 13.25,7.75 11,5" transform="scale(-1,-1) translate(-35,-15)"/><polygon points="13.25,2.25 14.5,5 13.25,7.75 11,5" transform="scale(-1,-1) translate(-35,-5)"/><polygon points="2,5 10,5 13,9 10,9 8,6" transform="scale(-1,-1) translate(-9,-15)"/><polygon points="2,5 8,4 10,1 13,1 10,5" transform="scale(-1,-1) translate(-9,-5)"/><animate attributeName="x" from="0" to="2.4" dur="20s" repeatCount="indefinite"/></pattern><rect width="128" height="55" fill="url(#rug)" stroke-width="3" stroke="black"/>'
                )
            );
        } else if (rug.pattern == 1) {
            //CIRCLES
            string[3] memory parts = [
                string(
                    abi.encodePacked(
                        '<pattern id="star" viewBox="0,0,12,12" width="11%" height="25%"><circle cx="12" cy="0" r="4" fill="',
                        colors[rug.colorOne],
                        '" stroke="black" stroke-width="1"/><circle cx="12" cy="0" r="2" fill="',
                        colors[rug.colorThree],
                        '" stroke="black" stroke-width="1"/><circle cx="0" cy="12" r="4" fill="',
                        colors[rug.colorOne],
                        '" stroke="black" stroke-width="1"/><circle cx="0" cy="12" r="2" fill="',
                        colors[rug.colorThree],
                        '" stroke="black" stroke-width="1"/>'
                    )
                ),
                string(
                    abi.encodePacked(
                        '<circle cx="6" cy="6" r="6" fill="',
                        colors[rug.colorTwo],
                        '" stroke="black" stroke-width="1"/><circle cx="6" cy="6" r="4" fill="',
                        colors[rug.colorOne],
                        '" stroke="black" stroke-width="1"/><circle cx="6" cy="6" r="2" fill="',
                        colors[rug.background],
                        '" stroke="black" stroke-width="1"/><circle cx="0" cy="0" r="6" fill="',
                        colors[rug.colorTwo],
                        '" stroke="black" stroke-width="1"/><circle cx="0" cy="0" r="4" fill="',
                        colors[rug.colorOne],
                        '" stroke="black" stroke-width="1"/><circle cx="0" cy="0" r="2" fill="',
                        colors[rug.colorThree],
                        '" stroke="black" stroke-width="1"/>'
                    )
                ),
                string(
                    abi.encodePacked(
                        '<circle cx="12" cy="12" r="6" fill="',
                        colors[rug.colorTwo],
                        '" stroke="black" stroke-width="1"/><circle cx="12" cy="12" r="4" fill="',
                        colors[rug.colorOne],
                        '" stroke="black" stroke-width="1"/><circle cx="12" cy="12" r="2" fill="',
                        colors[rug.colorThree],
                        '" stroke="black" stroke-width="1"/><animate attributeName="x" from="0" to="1.1" dur="9s" repeatCount="indefinite"/></pattern><rect width="128" height="55" fill="url(#star)" stroke="black" stroke-width="3"/>'
                    )
                )
            ];
            currentSvg = string(abi.encodePacked(abi.encodePacked(parts[0], parts[1]), parts[2]));
        } else if (rug.pattern == 2) {
            //HOOTS
            string[4] memory parts = [
                string(
                    abi.encodePacked(
                        '<pattern id="e" viewBox="13,-1,10,15" width="15%" height="95%"><polygon points="-99,-99 -99,99 99,99 99,-99" fill ="',
                        colors[rug.background],
                        '"/> <g stroke="black" stroke-width="0.75"><polygon points="5,5 18,10 23,5 18,0" fill ="',
                        colors[rug.colorTwo],
                        '"/><polygon points="21,0 26,5 21,10 33,5" fill ="',
                        colors[rug.colorThree],
                        '"/> </g><animate attributeName="x" from="0" to="0.3" dur="2.5s" repeatCount="indefinite"/> </pattern>'
                    )
                ),
                string(
                    abi.encodePacked(
                        '<pattern id="h" viewBox="10,0,20,25" width="15%" height="107%"><polygon points="-99,-99 -99,99 99,99 99,-99" fill ="',
                        colors[rug.background],
                        '"/><polygon points="9,4 14,9 14,18 9,23 26,23 31,18 31,9 26,4" fill ="',
                        colors[rug.colorOne],
                        '" stroke="black" stroke-width="1"/><g fill ="',
                        colors[rug.background],
                        '" stroke="black" stroke-width="0.5"><circle cx="20" cy="10" r="2.5"/><circle cx="20" cy="17" r="2.5"/><polygon points="24,11 24,16 29,13.5"/></g><circle cx="20" cy="10" r="1.75" fill="black"/><circle cx="20" cy="17" r="1.75" fill="black"/>'
                    )
                ),
                string(
                    abi.encodePacked(
                        '<animate attributeName="x" from="0" to="0.6" dur="5s" repeatCount="indefinite"/></pattern><pattern id="c" viewBox="13,4,10,20" width="15%" height="135%"><polygon points="-99,-99 -99,99 99,99 99,-99" fill="',
                        colors[rug.background],
                        '"/><polygon points="7,3 7,18 32,18 32,3" fill="black"/><polygon points="11,7 11,15 28,15 28,7" fill="',
                        colors[rug.background],
                        '"/><g fill="black" stroke="',
                        colors[rug.background],
                        '" stroke-width="1">'
                    )
                ),
                string(
                    abi.encodePacked(
                        '<polygon points="-3,9 -3,13 16,13 16,9"/><polygon points="23,9 23,13 41,13 41,9"/></g><animate attributeName="x" from="2.4" to="0" dur="40s" repeatCount="indefinite"/></pattern><rect width="128" height="55" fill="',
                        colors[rug.background],
                        '"/><rect x="0" y="2" width="128" height="9" fill="url(#e)"/><rect x="0" y="10" width="128" height="9" fill="url(#c)"/><rect x="0" y="19" width="128" height="15" fill="url(#h)"/><rect x="0" y="36.5" width="128" height="9" fill="url(#c)"/><rect x="0" y="46.25" width="128" height="9" fill="url(#e)"/><rect width="128" height="55" fill="transparent" stroke="black" stroke-width="3"/>'
                    )
                )
            ];
            currentSvg = string(abi.encodePacked(abi.encodePacked(parts[0], parts[1]), parts[2], parts[3]));
        } else if (rug.pattern == 3) {
            //SCALES
            string[3] memory parts = [
                string(
                    abi.encodePacked(
                        '<linearGradient id="grad1" x1="0%" y1="0%" x2="100%" y2="0%"><stop offset="0%" stop-color="',
                        colors[rug.background],
                        '"/><stop offset="100%" stop-color="',
                        colors[rug.colorOne],
                        '"/></linearGradient>'
                    )
                ),
                string(
                    abi.encodePacked(
                        '<pattern id="R" viewBox="0 0 16 16" width="11.4%" height="25%"><g fill="url(#grad1)" stroke-width="1" stroke="black"><polygon points="8,-2 26,-2 26,18 8,18"/><circle cx="8" cy="8" r="8"/><circle cx="0" cy="0" r="8"/><circle cx="0" cy="16" r="8"/><circle cx="8" cy="8" r="3" fill="',
                        colors[rug.colorThree],
                        '"/><circle cx="0" cy="0" r="3" fill="',
                        colors[rug.colorTwo],
                        '"/><circle cx="0" cy="16" r="3" fill="',
                        colors[rug.colorTwo],
                        '"/><circle cx="17" cy="0" r="3" fill="',
                        colors[rug.colorTwo],
                        '"/>'
                    )
                ),
                string(
                    abi.encodePacked(
                        '<circle cx="17" cy="16" r="3" fill="',
                        colors[rug.colorTwo],
                        '"/></g><animate attributeName="x" from="0" to="0.798" dur="6.6s" repeatCount="indefinite"/></pattern><rect width="128" height="55" fill="url(#R)" stroke-width="3" stroke="black"/>'
                    )
                )
            ];
            currentSvg = string(abi.encodePacked(abi.encodePacked(parts[0], parts[1]), parts[2]));
        } else if (rug.pattern == 4) {
            //HEART
            currentSvg = string(
                abi.encodePacked(
                    '<pattern id="star" viewBox="5.5,-50,100,100" width="25%" height="25%"><g stroke="black" stroke-width="2"><polygon points="-99,-99 -99,99 999,99 999,-99" fill ="',
                    colors[rug.background],
                    '"/> <polygon points="0,-50 -60,-15.36 -60,-84.64" fill="',
                    colors[rug.colorOne],
                    '"/><polygon points="0,50 -60,84.64 -60,15.36" fill="',
                    colors[rug.colorOne],
                    '"/><circle cx="120" cy="0" r="30" fill ="',
                    colors[rug.colorTwo],
                    '" /><path fill="',
                    colors[rug.colorThree],
                    '" id="star" d="M0,0 C37.5,62.5 75,25 50,0 C75,-25 37.5,-62.5 0,0 z"/></g><g transform="translate(0,40)" id="star"></g><animate attributeName="x" from="0" to="0.5" dur="4.1s" repeatCount="indefinite"/></pattern><rect width="128" height="55" fill="url(#star)" stroke="black" stroke-width="3"/>'
                )
            );
        } else if (rug.pattern == 5) {
            //SQUARES
            string[2] memory parts = [
                string(
                    abi.encodePacked(
                        '<pattern id="moon" viewBox="0,-0.5,10,10" width="100%" height="100%"><rect width="10" height="10" fill="',
                        colors[rug.colorOne],
                        '" stroke="black" stroke-width="2" transform="translate(0.05,-0.5)"/><rect width="5" height="5" stroke="',
                        colors[rug.colorTwo],
                        '" fill="',
                        colors[rug.colorOne],
                        '" transform="translate(2.5,2)"/><rect width="4" height="4" stroke="black" fill="',
                        colors[rug.colorOne],
                        '" transform="translate(3,2.5)" stroke-width="0.3"/>'
                    )
                ),
                string(
                    abi.encodePacked(
                        '<rect width="6" height="6" stroke="black" fill="none" transform="translate(2,1.5)" stroke-width="0.3"/><circle cx="5" cy="4.5" r="1" stroke="',
                        colors[rug.colorTwo],
                        '" fill="',
                        colors[rug.colorThree],
                        '"/><g stroke="black" stroke-width="0.3" fill="none"><circle cx="5" cy="4.5" r="1.5"/><circle cx="5" cy="4.5" r="0.5"/> </g></pattern><pattern id="star" viewBox="7,-0.5,7,10" width="17%" height="20%"><g fill="url(#moon)" stroke="',
                        colors[rug.background],
                        '"><rect width="10" height="10" transform="translate(0,-0.5)"/><rect width="10" height="10" transform="translate(10,4.5)"/><rect width="10" height="10" transform="translate(10,-5.5)"/></g><animate attributeName="x" from="0" to="0.17" dur="1.43s" repeatCount="indefinite"/></pattern><rect width="128" height="55" fill="url(#star)" stroke-width="3" stroke="black"/>'
                    )
                )
            ];
            currentSvg = string(abi.encodePacked(abi.encodePacked(parts[0], parts[1])));
        } else if (rug.pattern == 6) {
            //ENCORE
            string[3] memory parts = [
                string(
                    abi.encodePacked(
                        '<radialGradient id="a" x1="0%" y1="0%" x2="100%" y2="0%"><stop offset="0%" stop-color="',
                        colors[rug.background],
                        '" stop-opacity="1" /><stop offset="100%" stop-color="',
                        colors[rug.colorOne],
                        '" stop-opacity="1" /></radialGradient><radialGradient id="b" x1="0%" y1="0%" x2="100%" y2="0%"><stop offset="0%" stop-color="',
                        colors[rug.colorTwo],
                        '" stop-opacity="1" /><stop offset="100%" stop-color="',
                        colors[rug.colorThree],
                        '" stop-opacity="1" /></radialGradient>'
                    )
                ),
                string(
                    abi.encodePacked(
                        '<pattern id="R" viewBox="0 0 16 16" width="13.42%" height="33%"><g stroke-width="1" stroke="black" fill="url(#a)"><circle cx="16" cy="16" r="8"/><circle cx="16" cy="14.9" r="6"/><circle cx="16" cy="13" r="4"/><circle cx="16" cy="12" r="2"/><circle cx="0" cy="16" r="8"/><circle cx="0" cy="14.9" r="6"/><circle cx="0" cy="13" r="4"/><circle cx="0" cy="12" r="2"/><circle cx="8" cy="8" r="8" fill="url(#b)"/><circle cx="8" cy="6.5" r="6" fill="url(#b)"/><circle cx="8" cy="5" r="4" fill="url(#b)"/><circle cx="8" cy="4" r="2" fill="url(#b)"/><circle cx="16" cy="0" r="8"/><circle cx="16" cy="-2" r="6"/>'
                    )
                ),
                string(
                    abi.encodePacked(
                        '<circle cx="16" cy="-3.9" r="4"/><circle cx="0" cy="0" r="8"/><circle cx="0" cy="-2" r="6"/><circle cx="0" cy="-3.9" r="4"/></g><animate attributeName="x" from="0" to="0.4025" dur="3.35s" repeatCount="indefinite"/></pattern><rect width="128" height="55" fill="url(#R)" stroke-width="3" stroke="black"/>'
                    )
                )
            ];
            currentSvg = string(abi.encodePacked(abi.encodePacked(parts[0], parts[1]), parts[2]));
        } else if (rug.pattern == 7) {
            //Kubrik
            string[3] memory parts = [
                string(
                    abi.encodePacked(
                        '<linearGradient id="grad1" x1="0%" y1="0%" x2="100%" y2="0%"><stop offset="0%" stop-color="',
                        colors[rug.colorOne],
                        '" stop-opacity="1" /><stop offset="100%" stop-color="',
                        colors[rug.colorTwo],
                        '" stop-opacity="1" /></linearGradient><polygon points="0,0 0,55 128,55 128,0" fill ="url(#grad1)"/>    <pattern id="star" viewBox="5,-2.9,16,16" width="12%" height="20%">'
                    )
                ),
                string(
                    abi.encodePacked(
                        '<polygon points="13,6 10.5,10 5.5,10 2.5,5 5.5,0 10.5,0 13,4 21,4 26,-5 28,-5 22.5,5 29,17 27,17 21,6" fill="',
                        colors[rug.background],
                        '" stroke="black" stroke-width="0.3"/>    <polygon points="5,0 10,0 13,5 10,10 5,10 2,5" fill="',
                        colors[rug.colorThree],
                        '" stroke="black" stroke-width="0.6" transform="translate(4.3 2.5) scale(0.5 0.5)"/>    <polygon points="21,6 12.5,6 10,10 5,10 2,5 5,0 10,0 12.5,4 20.5,4 25.5,-5 28,-5 22,5" transform="translate(24.5 8) scale(-1,1)" fill="',
                        colors[rug.background],
                        '" stroke="black" stroke-width="0.3"/>'
                    )
                ),
                string(
                    abi.encodePacked(
                        '<polygon points="5,0 10,0 13,5 10,10 5,10 2,5" fill="',
                        colors[rug.colorThree],
                        '" stroke="black" stroke-width="0.6" transform="translate(13.3 10.5) scale(0.5 0.5)"/>      <polygon points="20.5,6 12.5,6 10,10 5,10 2,5 5,0 10,0 12.5,4 21,4 22,5 28,17 26.5,17" transform="translate(24.5 -8) scale(-1,1)" fill="',
                        colors[rug.background],
                        '" stroke="black" stroke-width="0.3"/>     <polygon points="5,0 10,0 13,5 10,10 5,10 2,5" fill="',
                        colors[rug.colorThree],
                        '" stroke="black" stroke-width="0.6" transform="translate(13.3 -5.5) scale(0.5 0.5)"/>    <animate attributeName="x" from="0" to="1.2" dur="9.8s" repeatCount="indefinite"/>    </pattern><rect width="128" height="55" fill="url(#star)" stroke="black" stroke-width="3"/>'
                    )
                )
            ];
            currentSvg = string(abi.encodePacked(abi.encodePacked(parts[0], parts[1]), parts[2]));
        } else if (rug.pattern == 8) {
            //TRIANGLES
            string[2] memory parts = [
                string(
                    abi.encodePacked(
                        '<polygon points="0,0 128,0 128,55 0,55" fill="',
                        colors[rug.background],
                        '"/><pattern id="R" viewBox="0 0 20 24" width="11.8%" height="33%"><g stroke-width="0.3" stroke="black"><polygon points="0,24 10,18 10,30" fill="',
                        colors[rug.colorOne],
                        '"/><polygon points="0,0 10,6 10,-6" fill="',
                        colors[rug.colorOne],
                        '"/><polygon points="10,6 20,12 20,0" fill="',
                        colors[rug.colorTwo],
                        '"/>'
                    )
                ),
                string(
                    abi.encodePacked(
                        '<polygon points="3,6 13,12 3,18" fill="',
                        colors[rug.colorThree],
                        '"/><polygon points="-7,12 3,18 -7,24" fill="',
                        colors[rug.colorOne],
                        '"/><polygon points="23,18 13,24 13,12" fill="',
                        colors[rug.colorOne],
                        '"/></g><animate attributeName="x" from="0" to="0.7085" dur="5.9s" repeatCount="indefinite"/></pattern><rect width="128" height="55" fill="url(#R)" stroke-width="3" stroke="black"/>'
                    )
                )
            ];
            currentSvg = string(abi.encodePacked(abi.encodePacked(parts[0], parts[1])));
        } else if (rug.pattern == 9) {
            rug.background = combination[1];
            rug.colorOne = combination[2];
            rug.colorTwo = combination[3];
            rug.colorThree = combination[4];
            rug.set = (rug.colorOne == rug.colorTwo) && (rug.colorTwo == rug.colorThree);
            string[1] memory parts = [
                string(
                    abi.encodePacked(
                        '<pattern id="star" viewBox="5.5,-50,100,100" width="40%" height="50%"><polygon points="-100,-100 -100,300 300,300 300,-100" fill="white"/> <polyline points="11 1,7 1,7 5,11 5,11 3, 10 3" fill="none" stroke="',
                        ngmiPalette[rug.background],
                        '"/><polyline points="1 5,1 1,5 5,5 1" fill="none" stroke="',
                        ngmiPalette[rug.colorOne],
                        '"/><polyline points="13 5,13 1,15 3,17 1, 17 5" fill="none" stroke="',
                        ngmiPalette[rug.colorTwo],
                        '"/><polyline points="19 1, 23 1, 21 1, 21 5, 19 5, 23 5" fill="none" stroke="',
                        ngmiPalette[rug.colorThree],
                        '"/><animate attributeName="x" from="0" to="0.4" dur="3s" repeatCount="indefinite"/>   </pattern>  <rect width="128" height="55" fill="url(#star)" stroke="black" stroke-width="3"/>'
                    )
                )
            ];
            currentSvg = string(abi.encodePacked(abi.encodePacked(parts[0])));
        }

        svg = string(abi.encodePacked(svg, currentSvg));
        svg = string(abi.encodePacked(svg, "</svg>"));

        // Keep track of each pn So we can add a trait for each color
        string memory traits = string(
            abi.encodePacked('"attributes": [{"trait_type": "Pattern","value":"', patterns[rug.pattern], '"},')
        );
        if (rug.set)
            traits = string(
                abi.encodePacked(traits, string(abi.encodePacked('{"trait_type": "Set","value":"True"},')))
            );
        string memory traits2 = string(
            abi.encodePacked(
                '{"trait_type": "Background","value":"',
                colors[rug.background],
                '"},{"trait_type": "Color One","value": "',
                colors[rug.colorOne],
                '"},{"trait_type": "Color Two","value": "',
                colors[rug.colorTwo],
                '"},{"trait_type": "Color Three","value": "',
                colors[rug.colorThree],
                '"}]'
            )
        );

        // solhint-enable quotes

        string memory metadata = string(abi.encodePacked(traits, traits2));
        return (metadata, svg);
    }

    // solhint-enable code-complexity
}

library Utils {
    function uint2str(uint256 _i) internal pure returns (string memory str) {
        if (_i == 0) {
            return "0";
        }

        uint256 j = _i;
        uint256 length;

        while (j != 0) {
            length++;
            j /= 10;
        }

        bytes memory bstr = new bytes(length);
        uint256 k = length;
        j = _i;

        while (j != 0) {
            bstr[--k] = bytes1(uint8(48 + (j % 10)));
            j /= 10;
        }

        str = string(bstr);

        return str;
    }
}

// SPDX-License-Identifier: MIT
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/utils/Context.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/utils/introspection/ERC165.sol';

error ApprovalCallerNotOwnerNorApproved();
error ApprovalQueryForNonexistentToken();
error ApproveToCaller();
error ApprovalToCurrentOwner();
error BalanceQueryForZeroAddress();
error MintToZeroAddress();
error MintZeroQuantity();
error OwnerQueryForNonexistentToken();
error TransferCallerNotOwnerNorApproved();
error TransferFromIncorrectOwner();
error TransferToNonERC721ReceiverImplementer();
error TransferToZeroAddress();
error URIQueryForNonexistentToken();

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension. Built to optimize for lower gas during batch mints.
 *
 * Assumes serials are sequentially minted starting at _startTokenId() (defaults to 0, e.g. 0, 1, 2, 3..).
 *
 * Assumes that an owner cannot have more than 2**64 - 1 (max value of uint64) of supply.
 *
 * Assumes that the maximum token id cannot exceed 2**256 - 1 (max value of uint256).
 */
contract ERC721A is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Compiler will pack this into a single 256bit word.
    struct TokenOwnership {
        // The address of the owner.
        address addr;
        // Keeps track of the start time of ownership with minimal overhead for tokenomics.
        uint64 startTimestamp;
        // Whether the token has been burned.
        bool burned;
    }

    // Compiler will pack this into a single 256bit word.
    struct AddressData {
        // Realistically, 2**64-1 is more than enough.
        uint64 balance;
        // Keeps track of mint count with minimal overhead for tokenomics.
        uint64 numberMinted;
        // Keeps track of burn count with minimal overhead for tokenomics.
        uint64 numberBurned;
        // For miscellaneous variable(s) pertaining to the address
        // (e.g. number of whitelist mint slots used).
        // If there are multiple variables, please pack them into a uint64.
        uint64 aux;
    }

    // The tokenId of the next token to be minted.
    uint256 internal _currentIndex;

    // The number of tokens burned.
    uint256 internal _burnCounter;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to ownership details
    // An empty struct value does not necessarily mean the token is unowned. See _ownershipOf implementation for details.
    mapping(uint256 => TokenOwnership) internal _ownerships;

    // Mapping owner address to address data
    mapping(address => AddressData) private _addressData;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _currentIndex = _startTokenId();
    }

    /**
     * To change the starting tokenId, please override this function.
     */
    function _startTokenId() internal view virtual returns (uint256) {
        return 0;
    }

    /**
     * @dev Burned tokens are calculated here, use _totalMinted() if you want to count just minted tokens.
     */
    function totalSupply() public view returns (uint256) {
        // Counter underflow is impossible as _burnCounter cannot be incremented
        // more than _currentIndex - _startTokenId() times
        unchecked {
            return _currentIndex - _burnCounter - _startTokenId();
        }
    }

    /**
     * Returns the total amount of tokens minted in the contract.
     */
    function _totalMinted() internal view returns (uint256) {
        // Counter underflow is impossible as _currentIndex does not decrement,
        // and it is initialized to _startTokenId()
        unchecked {
            return _currentIndex - _startTokenId();
        }
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
    function balanceOf(address owner) public view override returns (uint256) {
        if (owner == address(0)) revert BalanceQueryForZeroAddress();
        return uint256(_addressData[owner].balance);
    }

    /**
     * Returns the number of tokens minted by `owner`.
     */
    function _numberMinted(address owner) internal view returns (uint256) {
        return uint256(_addressData[owner].numberMinted);
    }

    /**
     * Returns the number of tokens burned by or on behalf of `owner`.
     */
    function _numberBurned(address owner) internal view returns (uint256) {
        return uint256(_addressData[owner].numberBurned);
    }

    /**
     * Returns the auxillary data for `owner`. (e.g. number of whitelist mint slots used).
     */
    function _getAux(address owner) internal view returns (uint64) {
        return _addressData[owner].aux;
    }

    /**
     * Sets the auxillary data for `owner`. (e.g. number of whitelist mint slots used).
     * If there are multiple variables, please pack them into a uint64.
     */
    function _setAux(address owner, uint64 aux) internal {
        _addressData[owner].aux = aux;
    }

    /**
     * Gas spent here starts off proportional to the maximum mint batch size.
     * It gradually moves to O(1) as tokens get transferred around in the collection over time.
     */
    function _ownershipOf(uint256 tokenId) internal view returns (TokenOwnership memory) {
        uint256 curr = tokenId;

        unchecked {
            if (_startTokenId() <= curr && curr < _currentIndex) {
                TokenOwnership memory ownership = _ownerships[curr];
                if (!ownership.burned) {
                    if (ownership.addr != address(0)) {
                        return ownership;
                    }
                    // Invariant:
                    // There will always be an ownership that has an address and is not burned
                    // before an ownership that does not have an address and is not burned.
                    // Hence, curr will not underflow.
                    while (true) {
                        curr--;
                        ownership = _ownerships[curr];
                        if (ownership.addr != address(0)) {
                            return ownership;
                        }
                    }
                }
            }
        }
        revert OwnerQueryForNonexistentToken();
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view override returns (address) {
        return _ownershipOf(tokenId).addr;
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
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : '';
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return '';
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public override {
        address owner = ERC721A.ownerOf(tokenId);
        if (to == owner) revert ApprovalToCurrentOwner();

        if (_msgSender() != owner && !isApprovedForAll(owner, _msgSender())) {
            revert ApprovalCallerNotOwnerNorApproved();
        }

        _approve(to, tokenId, owner);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view override returns (address) {
        if (!_exists(tokenId)) revert ApprovalQueryForNonexistentToken();

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        if (operator == _msgSender()) revert ApproveToCaller();

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
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
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
        safeTransferFrom(from, to, tokenId, '');
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
        _transfer(from, to, tokenId);
        if (to.isContract() && !_checkContractOnERC721Received(from, to, tokenId, _data)) {
            revert TransferToNonERC721ReceiverImplementer();
        }
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        return _startTokenId() <= tokenId && tokenId < _currentIndex &&
            !_ownerships[tokenId].burned;
    }

    function _safeMint(address to, uint256 quantity) internal {
        _safeMint(to, quantity, '');
    }

    /**
     * @dev Safely mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called for each safe transfer.
     * - `quantity` must be greater than 0.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(
        address to,
        uint256 quantity,
        bytes memory _data
    ) internal {
        _mint(to, quantity, _data, true);
    }

    /**
     * @dev Mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `quantity` must be greater than 0.
     *
     * Emits a {Transfer} event.
     */
    function _mint(
        address to,
        uint256 quantity,
        bytes memory _data,
        bool safe
    ) internal {
        uint256 startTokenId = _currentIndex;
        if (to == address(0)) revert MintToZeroAddress();
        if (quantity == 0) revert MintZeroQuantity();

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are incredibly unrealistic.
        // balance or numberMinted overflow if current value of either + quantity > 1.8e19 (2**64) - 1
        // updatedIndex overflows if _currentIndex + quantity > 1.2e77 (2**256) - 1
        unchecked {
            _addressData[to].balance += uint64(quantity);
            _addressData[to].numberMinted += uint64(quantity);

            _ownerships[startTokenId].addr = to;
            _ownerships[startTokenId].startTimestamp = uint64(block.timestamp);

            uint256 updatedIndex = startTokenId;
            uint256 end = updatedIndex + quantity;

            if (safe && to.isContract()) {
                do {
                    emit Transfer(address(0), to, updatedIndex);
                    if (!_checkContractOnERC721Received(address(0), to, updatedIndex++, _data)) {
                        revert TransferToNonERC721ReceiverImplementer();
                    }
                } while (updatedIndex != end);
                // Reentrancy protection
                if (_currentIndex != startTokenId) revert();
            } else {
                do {
                    emit Transfer(address(0), to, updatedIndex++);
                } while (updatedIndex != end);
            }
            _currentIndex = updatedIndex;
        }
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
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
    ) private {
        TokenOwnership memory prevOwnership = _ownershipOf(tokenId);

        if (prevOwnership.addr != from) revert TransferFromIncorrectOwner();

        bool isApprovedOrOwner = (_msgSender() == from ||
            isApprovedForAll(from, _msgSender()) ||
            getApproved(tokenId) == _msgSender());

        if (!isApprovedOrOwner) revert TransferCallerNotOwnerNorApproved();
        if (to == address(0)) revert TransferToZeroAddress();

        _beforeTokenTransfers(from, to, tokenId, 1);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId, from);

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as tokenId would have to be 2**256.
        unchecked {
            _addressData[from].balance -= 1;
            _addressData[to].balance += 1;

            TokenOwnership storage currSlot = _ownerships[tokenId];
            currSlot.addr = to;
            currSlot.startTimestamp = uint64(block.timestamp);

            // If the ownership slot of tokenId+1 is not explicitly set, that means the transfer initiator owns it.
            // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
            uint256 nextTokenId = tokenId + 1;
            TokenOwnership storage nextSlot = _ownerships[nextTokenId];
            if (nextSlot.addr == address(0)) {
                // This will suffice for checking _exists(nextTokenId),
                // as a burned slot cannot contain the zero address.
                if (nextTokenId != _currentIndex) {
                    nextSlot.addr = from;
                    nextSlot.startTimestamp = prevOwnership.startTimestamp;
                }
            }
        }

        emit Transfer(from, to, tokenId);
        _afterTokenTransfers(from, to, tokenId, 1);
    }

    /**
     * @dev This is equivalent to _burn(tokenId, false)
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
        TokenOwnership memory prevOwnership = _ownershipOf(tokenId);

        address from = prevOwnership.addr;

        if (approvalCheck) {
            bool isApprovedOrOwner = (_msgSender() == from ||
                isApprovedForAll(from, _msgSender()) ||
                getApproved(tokenId) == _msgSender());

            if (!isApprovedOrOwner) revert TransferCallerNotOwnerNorApproved();
        }

        _beforeTokenTransfers(from, address(0), tokenId, 1);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId, from);

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as tokenId would have to be 2**256.
        unchecked {
            AddressData storage addressData = _addressData[from];
            addressData.balance -= 1;
            addressData.numberBurned += 1;

            // Keep track of who burned the token, and the timestamp of burning.
            TokenOwnership storage currSlot = _ownerships[tokenId];
            currSlot.addr = from;
            currSlot.startTimestamp = uint64(block.timestamp);
            currSlot.burned = true;

            // If the ownership slot of tokenId+1 is not explicitly set, that means the burn initiator owns it.
            // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
            uint256 nextTokenId = tokenId + 1;
            TokenOwnership storage nextSlot = _ownerships[nextTokenId];
            if (nextSlot.addr == address(0)) {
                // This will suffice for checking _exists(nextTokenId),
                // as a burned slot cannot contain the zero address.
                if (nextTokenId != _currentIndex) {
                    nextSlot.addr = from;
                    nextSlot.startTimestamp = prevOwnership.startTimestamp;
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

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(
        address to,
        uint256 tokenId,
        address owner
    ) private {
        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkContractOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
            return retval == IERC721Receiver(to).onERC721Received.selector;
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

    /**
     * @dev Hook that is called before a set of serially-ordered token ids are about to be transferred. This includes minting.
     * And also called before burning one token.
     *
     * startTokenId - the first token id to be transferred
     * quantity - the amount to be transferred
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
     * @dev Hook that is called after a set of serially-ordered token ids have been transferred. This includes
     * minting.
     * And also called after one token has been burned.
     *
     * startTokenId - the first token id to be transferred
     * quantity - the amount to be transferred
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

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
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
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