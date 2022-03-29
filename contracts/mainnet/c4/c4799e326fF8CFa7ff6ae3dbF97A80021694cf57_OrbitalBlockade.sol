// SPDX-License-Identifier: MIT

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
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
        _;
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

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/Pausable.sol";
import "./interfaces/IERC721TokenReciever.sol";
import "./interfaces/IOrbitalBlockade.sol";
import "./interfaces/IPirateGames.sol";
import "./interfaces/IPirates.sol";
import "./interfaces/IRAW.sol";
import "./interfaces/IMasterStaker.sol";

contract OrbitalBlockade is IOrbitalBlockade, IERC721TokenReceiver, Pausable {
    // maximum rank for a Pirate
    uint8 public constant MAX_RANK = 8;

    // struct to store a stake's token, sOwner, and earning values
    struct Stake {
        uint16 tokenId;
        uint80 value;
        address sOwner;
    }

    event PirateStaked(
        address indexed sOwner,
        uint256 indexed tokenId,
        uint256 value
    );

    event PirateClaimed(
        uint256 indexed tokenId,
        bool indexed unstaked,
        uint256 earned
    );

    // reference to the Pirates NFT contract
    IPirates public pirateNFT;
    // reference to the game logic  contract
    IPirateGames public pirGames;
    // reference to the $rEON contract for minting $rEON earnings
    IRAW public raw;
    //reference to masterStaker contract
    IMasterStaker public masterStaker;

    //maps token id to stake
    mapping(uint256 => Stake) private orbital;
    // maps rank to all Pirates staked with that rank
    mapping(uint256 => Stake[]) private crew;
    // tracks location of each Pirate in all pirate crews:
    mapping(uint256 => uint256) private crewIndices;
    // amount of rEON due for each fuel index point.
    // address => allowedToCallFunctions
    mapping(address => bool) private admins;

    uint256 public rawEonPerRank = 0;

    uint256 private totalRankStaked;

    uint256 public piratesStaked;

    // any rewards distributed when no pirates are staked
    uint256 private unaccountedRewards = 0;

    address public auth;

    bool rescueEnabled;

    constructor() {
        _pause();
        auth = msg.sender;
        admins[msg.sender] = true;
    }

    modifier noCheaters() {
        uint256 size = 0;
        address acc = msg.sender;
        assembly {
            size := extcodesize(acc)
        }

        require(
            admins[msg.sender] || (msg.sender == tx.origin && size == 0),
            "you're trying to cheat!"
        );
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == auth);
        _;
    }

    /** CRITICAL TO SETUP */
    modifier requireContractsSet() {
        require(
            address(pirateNFT) != address(0) &&
                address(raw) != address(0) &&
                address(pirGames) != address(0) &&
                address(masterStaker) != address(0),
            "Contracts not set"
        );
        _;
    }

    function setContracts(
        address _pirateNFT,
        address _raw,
        address _pirGames,
        address _masterStaker
    ) external onlyOwner {
        pirateNFT = IPirates(_pirateNFT);
        raw = IRAW(_raw);
        pirGames = IPirateGames(_pirGames);
        masterStaker = IMasterStaker(_masterStaker);
    }

    /** STAKING */

    /**
     * adds Pirates to the orbital blockade crew
     * @param account the address of the staker
     * @param tokenIds the IDs of the Pirates to stake
     */
    function addPiratesToCrew(address account, uint16[] calldata tokenIds)
        external
        override
        whenNotPaused
        noCheaters
    {
        require(account == tx.origin);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (msg.sender == address(masterStaker)) {
                // dont do this step if its a mint + stake
                require(
                    pirateNFT.isOwner(tokenIds[i]) == account,
                    "Not Pirate Owner"
                );
                pirateNFT.transferFrom(account, address(this), tokenIds[i]);
            } else if (msg.sender != address(pirGames)) {
                require(
                    pirateNFT.isOwner(tokenIds[i]) == msg.sender,
                    "Not Pirate Owner"
                );
                pirateNFT.transferFrom(msg.sender, address(this), tokenIds[i]);
            } else if (tokenIds[i] == 0) {
                continue; // there may be gaps in the array for stolen tokens
            }
            _addPirateToCrew(account, tokenIds[i]);
        }
    }

    /**
     * adds a single Pirate to the Crew
     * @param account the address of the staker
     * @param tokenId the ID of the Pirate to add to the Crew
     */
    function _addPirateToCrew(address account, uint256 tokenId)
        internal
        whenNotPaused
    {
        uint8 rank = _rankForPirate(tokenId);
        totalRankStaked += rank; // Portion of earnings ranges from 8 to 5
        crewIndices[tokenId] = crew[rank].length; // Store the location of the Pirate in the Crew
        crew[rank].push(
            Stake({
                sOwner: account,
                tokenId: uint16(tokenId),
                value: uint80(rawEonPerRank)
            })
        ); // Add the Pirate to the Crew
        piratesStaked += 1;
        emit PirateStaked(account, tokenId, rawEonPerRank);
    }

    /** CLAIMING / UNSTAKING */

    /**
     * realize $rEON earnings and optionally unstake tokens from the Orbital blockade
     * @param tokenIds the IDs of the tokens to claim earnings from
     * @param unstake whether or not to unstake ALL of the tokens listed in tokenIds
     */
    function claimPiratesFromCrew(
        address account,
        uint16[] calldata tokenIds,
        bool unstake
    ) external whenNotPaused noCheaters {
        uint256 owed = 0;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            owed += _claimPiratesFromCrew(account, tokenIds[i], unstake);
        }
        if (owed == 0) {
            return;
        }
        raw.mint(1, owed, account);
    }

    function calculateRewards(uint256 tokenId)
        external
        view
        returns (uint256 owed)
    {
        Stake memory stake = orbital[tokenId];
        uint8 rank = _rankForPirate(tokenId);
        owed = (rank) * (rawEonPerRank - stake.value); // Calculate portion of tokens based on Rank
    }

    /**
     * realize $rEON earnings for a single Pirate and optionally unstake it
     * Pirates earn $rEON proportional to their rank
     * @param tokenId the ID of the Pirate to claim earnings from
     * @param unstake whether or not to unstake the Pirate
     * @return owed - the amount of $rEON earned
     */
    function _claimPiratesFromCrew(
        address account,
        uint256 tokenId,
        bool unstake
    ) internal returns (uint256 owed) {
        uint8 rank = _rankForPirate(tokenId);
        Stake memory stake = crew[rank][crewIndices[tokenId]];
        require(stake.sOwner == account, "Not pirate Owner");
        owed = (rank) * (rawEonPerRank - stake.value); // Calculate portion of tokens based on Rank
        if (unstake) {
            totalRankStaked -= rank; // Remove rank from total staked
            piratesStaked -= 1;
            Stake memory lastStake = crew[rank][crew[rank].length - 1];
            crew[rank][crewIndices[tokenId]] = lastStake; // Shuffle last Pirate to current position
            crewIndices[lastStake.tokenId] = crewIndices[tokenId];
            crew[rank].pop(); // Remove duplicate
            delete crewIndices[tokenId]; // Delete old mapping
            // Always remove last to guard against reentrance
            pirateNFT.safeTransferFrom(address(this), account, tokenId, ""); // Send back Pirate
        } else {
            crew[rank][crewIndices[tokenId]] = Stake({
                sOwner: account,
                tokenId: uint16(tokenId),
                value: uint80(rawEonPerRank)
            }); // reset stake
        }
        emit PirateClaimed(tokenId, unstake, owed);
    }

    /**
     * emergency unstake tokens
     * @param tokenIds the IDs of the tokens to claim earnings from
     */
    function rescue(uint256[] calldata tokenIds) external noCheaters {
        require(rescueEnabled, "Rescue Not Enabled");
        uint256 tokenId;
        Stake memory stake;
        Stake memory lastStake;
        uint8 rank;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            rank = _rankForPirate(tokenId);
            stake = crew[rank][crewIndices[tokenId]];
            require(stake.sOwner == msg.sender, "Not Owner");
            totalRankStaked -= rank; // Remove Rank from total staked
            lastStake = crew[rank][crew[rank].length - 1];
            crew[rank][crewIndices[tokenId]] = lastStake; // Shuffle last Pirate to current position
            crewIndices[lastStake.tokenId] = crewIndices[tokenId];
            crew[rank].pop(); // Remove duplicate
            delete crewIndices[tokenId]; // Delete old mapping
            pirateNFT.safeTransferFrom(address(this), msg.sender, tokenId, ""); // Send back Pirate
            emit PirateClaimed(tokenId, true, 0);
        }
    }

    /**
     * add $rEON to claimable pot for the Crew
     * @param amount $rEON to add to the pot
     */
    function payPirateTax(uint256 amount) external override {
        require(admins[msg.sender], "Only admins");
        if (totalRankStaked == 0) {
            // if there's no staked pirates
            unaccountedRewards += amount; // keep track of $rEON due to pirates
            return;
        }
        // makes sure to include any unaccounted $rEON
        rawEonPerRank += (amount + unaccountedRewards) / totalRankStaked;
        unaccountedRewards = 0;
    }

    //Admin
    /**
     * allows owner to enable "rescue mode"
     * simplifies accounting, prioritizes tokens out in emergency
     */
    function setRescueEnabled(bool _enabled) external onlyOwner {
        rescueEnabled = _enabled;
    }

    /**
     * enables owner to pause / unpause contract
     */
    function setPaused(bool _paused) external requireContractsSet onlyOwner {
        if (_paused) _pause();
        else _unpause();
    }

    /**
     * enables an address to mint / burn
     * @param addr the address to enable
     */
    function addAdmin(address addr) external onlyOwner {
        admins[addr] = true;
    }

    /**
     * disables an address from minting / burning
     * @param addr the address to disbale
     */
    function removeAdmin(address addr) external onlyOwner {
        admins[addr] = false;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        auth = newOwner;
    }

    //READ ONLY
    /**
     * gets the rank score for a Pirate
     * @param tokenId the ID of the Pirate to get the rank score for
     * @return the rank score of the Pirate (5-8)
     */
    function _rankForPirate(uint256 tokenId) internal view returns (uint8) {
        if (pirateNFT.isHonors(tokenId)) {
            return 8;
        } else {
            IPirates.Pirate memory q = pirateNFT.getTokenTraitsPirate(tokenId);
            return MAX_RANK - q.rank; // rank index is 0-3
        }
    }

    /**
     * chooses a random Pirate thief when a newly minted token is stolen
     * @param seed a random value to choose a Pirate from
     * @return the sOwner of the randomly selected Pirate thief
     */
    function randomPirateOwner(uint256 seed)
        external
        view
        override
        returns (address)
    {
        if (totalRankStaked == 0) {
            return address(0x0);
        }
        uint256 bucket = (seed & 0xFFFFFFFF) % totalRankStaked; // choose a value from 0 to total rank staked
        uint256 cumulative;
        seed >>= 32;
        // loop through each bucket of Pirates with the same rank score
        for (uint256 i = MAX_RANK - 3; i <= MAX_RANK; i++) {
            cumulative += crew[i].length * i;
            // if the value is not inside of that bucket, keep going
            if (bucket >= cumulative) continue;
            // get the address of a random Pirate with that rank score
            return crew[i][seed % crew[i].length].sOwner;
        }
        return address(0x0);
    }

    function onERC721Received(
        address,
        address from,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        require(from == address(0x0), "Only EOA");
        return IERC721TokenReceiver.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.11;

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
interface IERC721TokenReceiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 id,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.0;

interface IMasterStaker {

 function masterStake(
        uint16[] calldata colonistTokenIds,
        uint16[] calldata pirateTokenIds
    ) external;

 function masterUnstake(
        uint16[] calldata colonistTokenIds,
        uint16[] calldata pirateTokenIds
    ) external;

 function masterClaim(
        uint16[] calldata colonistTokenIds,
        uint16[] calldata pirateTokenIds
    ) external;
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

interface IOrbitalBlockade {
    function addPiratesToCrew(address account, uint16[] calldata tokenIds)
        external;
    
    function claimPiratesFromCrew(address account, uint16[] calldata tokenIds, bool unstake)
        external;

    function payPirateTax(uint256 amount) external;

    function randomPirateOwner(uint256 seed) external view returns (address);
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

interface IPirateGames {}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

interface IPirates {
    // struct to store each Colonist's traits
    struct Pirate {
        bool isPirate;
        uint8 sky;
        uint8 cockpit;
        uint8 base;
        uint8 engine;
        uint8 nose;
        uint8 wing;
        uint8 weapon1;
        uint8 weapon2;
        uint8 rank;
    }

    struct HPirates {
        uint8 Legendary;
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) external;

    function minted() external returns (uint16);

    function piratesMinted() external returns (uint16);

    function isOwner(uint256 tokenId)
        external
        view
        returns (address);

    function _mintPirate(address recipient, uint256 seed) external;

    function burn(uint256 tokenId) external;

    function getTokenTraitsPirate(uint256 tokenId)
        external
        view
        returns (Pirate memory);

    function getTokenTraitsHonors(uint256 tokenId)
        external
        view
        returns (HPirates memory);

    function tokenNameByIndex(uint256 index)
        external
        view
        returns (string memory);
    
    function isHonors(uint256 tokenId)
        external
        view
        returns (bool);

    function hasBeenNamed(uint256 tokenId) external view returns (bool);

    function namePirate(uint256 tokenId, string memory newName) external;
}

// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.0;

interface IRAW {

    function getBalance(
        address account,
        uint256 id
    ) external returns(uint256);

    function mint(
        uint256 typeId,
        uint256 qty,
        address recipient
    ) external;

    function burn(
        uint256 typeId,
        uint256 qty,
        address burnFrom
    ) external;

    function updateMintBurns(
        uint256 typeId,
        uint256 mintQty,
        uint256 burnQty
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external;

}