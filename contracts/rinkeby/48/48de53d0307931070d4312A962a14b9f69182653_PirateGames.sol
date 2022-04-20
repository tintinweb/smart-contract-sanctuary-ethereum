// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

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

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/Pausable.sol";
import "./interfaces/IPirateGames.sol";
import "./interfaces/IPytheas.sol";
import "./interfaces/IOrbitalBlockade.sol";
import "./interfaces/ITPirates.sol";
import "./interfaces/IRAW.sol";
import "./interfaces/IEON.sol";
import "./interfaces/IPirates.sol";
import "./interfaces/IColonist.sol";
import "./interfaces/IImperialGuild.sol";
import "./interfaces/IRandomizer.sol";

contract PirateGames is IPirateGames, Pausable {
    struct MintCommit {
        bool stake;
        uint16 tokenId;
    }

    uint8[][6] public rarities;
    uint8[][6] public aliases;

    uint256 public OnosiaLiquorId;

    uint256 private maxRawEonCost;

    uint256 public eonMintCost;

    uint256 public imperialFee;

    // address => can call
    mapping(address => bool) private admins;

    // address -> commit # -> commits
    mapping(address => mapping(uint16 => MintCommit)) private _mintCommits;
    // address -> commit num of commit need revealed for account
    mapping(address => uint16) private _pendingCommitId;
    // commit # -> offchain random
    mapping(uint16 => uint256) private _commitRandoms;
    uint16 private _commitId = 1;
    uint16 private pendingMintAmt;
    bool public allowCommits = true;

    bool public eonMintsEnabled;

    address public auth;

    // reference to Pytheas for checking that a colonist has mined enough
    //rEON to make an attempt as well as pay from this amount, either the  current mint cost on
    //a successful pirate mint, or pirate tax on a failed attempt.
    IPytheas public pytheas;
    //reference to the OrbitalBlockade, where pirates are staked out, awaiting weak colonist miners.
    IOrbitalBlockade public orbital;
    // reference to raw Eon for attempts
    IRAW public raw;
    // reference to refined EON for if EonOnlyMints are enabled (all raw eon mined)
    IEON public eon;
    // reference to pirate collection
    IPirates public pirateNFT;
    // reference to the colonist NFT collection
    IColonist public colonistNFT;
    // reference to the galactic imperialGuild collection
    IImperialGuild public imperialGuild;
    //randy the randomizer
    IRandomizer private randomizer;

    event MintCommitted(address indexed owner, uint256 indexed tokenId);
    event MintRevealed(address indexed owner, uint16[] indexed tokenId);

    constructor() {
        auth = msg.sender;
        admins[msg.sender] = true;

        //RatioChance 90
        rarities[0] = [27, 230];
        aliases[0] = [1, 0];
        //RatioChance 80
        rarities[1] = [51, 204];
        aliases[1] = [1, 0];
        //RatioChance 60
        rarities[2] = [90, 175];
        aliases[2] = [1, 0];
        //RatioChance 40
        rarities[3] = [155, 132];
        aliases[3] = [1, 0];
        //RatioChance 10
        rarities[4] = [200, 60];
        aliases[4] = [1, 0];
        //RatioChance 0
        rarities[5] = [255];
        aliases[5] = [0];
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
            address(raw) != address(0) &&
                address(eon) != address(0) &&
                address(pirateNFT) != address(0) &&
                address(colonistNFT) != address(0) &&
                address(pytheas) != address(0) &&
                address(orbital) != address(0) &&
                address(imperialGuild) != address(0) &&
                address(randomizer) != address(0),
            "Contracts not set"
        );
        _;
    }

    function setContracts(
        address _rEON,
        address _eon,
        address _pirateNFT,
        address _colonistNFT,
        address _pytheas,
        address _orbital,
        address _imperialGuild,
        address _randomizer
    ) external onlyOwner {
        raw = IRAW(_rEON);
        eon = IEON(_eon);
        pirateNFT = IPirates(_pirateNFT);
        colonistNFT = IColonist(_colonistNFT);
        pytheas = IPytheas(_pytheas);
        orbital = IOrbitalBlockade(_orbital);
        imperialGuild = IImperialGuild(_imperialGuild);
        randomizer = IRandomizer(_randomizer);
    }

    function getPendingMint(address addr)
        external
        view
        returns (MintCommit memory)
    {
        require(_pendingCommitId[addr] != 0, "no pending commits");
        return _mintCommits[addr][_pendingCommitId[addr]];
    }

    function hasMintPending(address addr) external view returns (bool) {
        return _pendingCommitId[addr] != 0;
    }

    function canMint(address addr) external view returns (bool) {
        return
            _pendingCommitId[addr] != 0 &&
            _commitRandoms[_pendingCommitId[addr]] > 0;
    }

    // Seed the current commit id so that pending commits can be revealed
    function addCommitRandom(uint256 seed) external {
        require(
            auth == msg.sender || admins[msg.sender],
            "Only admins can call this"
        );
        _commitRandoms[_commitId] = seed;
        _commitId += 1;
    }

    function deleteCommit(address addr) external {
        require(
            auth == msg.sender || admins[msg.sender],
            "Only admins can call this"
        );
        uint16 commitIdCur = _pendingCommitId[msg.sender];
        require(commitIdCur > 0, "No pending commit");
        delete _mintCommits[addr][commitIdCur];
        delete _pendingCommitId[addr];
    }

    function forceRevealCommit(address addr) external {
        require(
            auth == msg.sender || admins[msg.sender],
            "Only admins can call this"
        );
        pirateAttempt(addr);
    }

    function mintCommit(uint16 tokenId, bool stake) external whenNotPaused noCheaters {
        require(allowCommits, "adding commits disallowed");
        require(
            _pendingCommitId[msg.sender] == 0,
            "Already have pending mints"
        );
        uint16 piratesMinted = pirateNFT.piratesMinted();
        require(piratesMinted + pendingMintAmt + 1 <= 6000, "All tokens minted");
        uint256 minted = colonistNFT.minted();
        uint256 maxTokens = colonistNFT.getMaxTokens();
        uint256 rawCost = rawMintCost(minted, maxTokens);
   
        raw.burn(1, rawCost, msg.sender);
        raw.updateOriginAccess(msg.sender);
        colonistNFT.transferFrom(msg.sender, address(this), tokenId);
        _mintCommits[msg.sender][1] = MintCommit(stake, tokenId);
        _pendingCommitId[msg.sender] = 1;
        pendingMintAmt += 1; 
        emit MintCommitted(msg.sender, tokenId); 
    }

    function mintReveal() external whenNotPaused noCheaters {
    require(tx.origin == msg.sender, "Only EOA1");
    pirateAttempt(msg.sender);
  }

    function pirateAttempt(address addr) internal {
        uint16 commitIdCur = _pendingCommitId[addr];
        require(commitIdCur > 0, "No pending commit");
        require (
            _commitRandoms[commitIdCur] > 0,
            "Commit random not set"
        );
        MintCommit memory commit = _mintCommits[addr][commitIdCur];
        pendingMintAmt -= 1;
        uint16 colonistId = commit.tokenId;
        uint16 piratesMinted = pirateNFT.piratesMinted();
        uint256 seed = _commitRandoms[commitIdCur];
        uint256 circulation = colonistNFT.totalCir();
        uint8 chanceTable = getRatioChance(piratesMinted, circulation);
        uint8 yayNay = getPirateResults(seed, chanceTable);
             // if the attempt fails, pay pirate tax and claim remaining
        if (yayNay == 0) { 
            colonistNFT.safeTransferFrom(address(this), addr, colonistId);
        } else {
            colonistNFT.burn(colonistId);
            uint16[] memory pirateId = new uint16[](1);
            uint16[] memory pirateIdToStake = new uint16[](1);
            piratesMinted++;
          address recipient = selectRecipient(seed);
            if (
                recipient != addr &&
                imperialGuild.getBalance(addr, OnosiaLiquorId) > 0
            ) {
                // If the mint is going to be stolen, there's a 50% chance
                //  a pirate will prefer a fine crafted EON liquor over it
                if (seed & 1 == 1) {
                    imperialGuild.safeTransferFrom(
                        addr,
                        recipient,
                        OnosiaLiquorId,
                        1,
                        ""
                    );
                    recipient = addr;
                }
            }

            pirateId[0] = piratesMinted;
            if (!commit.stake || recipient != addr) {
                pirateNFT._mintPirate(recipient, seed);
            } else {
                pirateNFT._mintPirate(address(orbital), seed);
            pirateIdToStake[0] = piratesMinted;
            }
            pirateNFT.updateOriginAccess(pirateId);
            if (commit.stake) {
                orbital.addPiratesToCrew(addr, pirateIdToStake);
            }
            delete _mintCommits[addr][commitIdCur];
            delete _pendingCommitId[addr];
            emit MintRevealed(addr, pirateId); 
        }
    }

    /**
     * @return the cost of the given token ID
     */
    function rawMintCost(uint256 tokenId, uint256 maxTokens) 
    internal 
    view 
    returns (uint256) {
        if (tokenId <= (maxTokens * 8) / 24) return 4000; //10k-20k
        if (tokenId <= (maxTokens * 12) / 24) return 16000; //20k-30k
        if (tokenId <= (maxTokens * 16) / 24) return 48000; //30k-40k
        if (tokenId <= (maxTokens * 20) / 24) return 122500; //40k-50k
        if (tokenId <= (maxTokens * 22) / 24) return 250000; //50k-55k
        return maxRawEonCost;
    }

    function getRatioChance(uint256 pirates, uint256 circulation)
        public
        returns (uint8)
    {
        uint256 ratio = (pirates * 10000) / circulation;

        if (ratio <= 100) {
            return 0;
        } else if (ratio <= 300 && ratio >= 100) {
            return 1;
        } else if (ratio <= 500 && ratio >= 300) {
            return 2;
        } else if (ratio <= 800 && ratio >= 500) {
            return 3;
        } else if (ratio <= 999 && ratio >= 800) {
            return 4;
        } else {
            return 5;
        }
    }

    /**
  Determines if an attempt to join the pirates is successful or not 
  granting a higher chance of success when the pirate to colonist ratio is
  low, as the ratio gets closer to 10% the harder a chance at joining the pirates
  becomes until ultimately they will not accept anyone else if the ratio is += 10%
 */

    function getPirateResults(uint256 seed, uint8 chanceTable)
        internal
        view
        returns (uint8)
    {
        seed >>= 16;
        uint8 yayNay = getResult(uint16(seed & 0xFFFF), chanceTable);
        return yayNay;
    }

    function getResult(uint256 seed, uint8 chanceTable)
        internal
        view
        returns (uint8)
    {
        uint8 result = uint8(seed) % uint8(rarities[chanceTable].length);
        // If the selected chance talbles rareity is selected (biased coin) return that
        if (seed >> 8 < rarities[chanceTable][result]) return result;
        // else return the aliases
        return aliases[chanceTable][result];
    }


    /** INTERNAL */

    /**
     * the first 10k colonist mints go to the minter
     * the remaining 80% have a 10% chance to be given to a random staked pirate
     * @param seed a random value to select a recipient from
     * @return the address of the recipient (either the minter or the pirate thief's owner)
     */
    function selectRecipient(uint256 seed) internal view returns (address) {
        if (((seed >> 245) % 10) != 0) return msg.sender; // top 10 bits
        address thief = orbital.randomPirateOwner(seed >> 144); // 144 bits reserved for trait selection
        if (thief == address(0x0)) return msg.sender;
        return thief;
    }

    /**
     * enables owner to pause / unpause contract
     */
    function setPaused(bool _paused) external requireContractsSet onlyOwner {
        if (_paused) _pause();
        else _unpause();
    }

    function setOnosiaLiquorId(uint256 typeId) external onlyOwner {
        OnosiaLiquorId = typeId;
    }

     /* enables an address to mint / burn
     * @param addr the address to enable
     */
    function addAdmin(address addr) external onlyOwner {
        admins[addr] = true;
    }

    /**
     * disables an address from minting / burning
     * @param addr the address to disable
     */
    function removeAdmin(address addr) external onlyOwner {
        admins[addr] = false;
    }

}

// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.0;

interface IColonist {
    // struct to store each Colonist's traits
    struct Colonist {
        bool isColonist;
        uint8 background;
        uint8 body;
        uint8 shirt;
        uint8 jacket;
        uint8 jaw;
        uint8 eyes;
        uint8 hair;
        uint8 held;
        uint8 gen;
    }

    struct HColonist {
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
        uint256 tokenId,
        bytes memory _data
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function isOwner(uint256 tokenId)
        external
        view
        returns (address);

    function minted() external returns (uint16);

    function totalCir() external returns (uint256);

    function _mintColonist(address recipient, uint256 seed) external;

    function _mintToHonors(address recipient, uint256 seed) external;

    function _mintHonors(address recipient, uint8 id) external;

    function burn(uint256 tokenId) external;

    function getMaxTokens() external view returns (uint256);

    function getPaidTokens() external view returns (uint256);

    function getTokenTraitsColonist(uint256 tokenId)
        external
        view
        returns (Colonist memory);

    function getTokenTraitsHonors(uint256 tokenId)
        external
        view
        returns (HColonist memory);

    function tokenNameByIndex(uint256 index)
        external
        view
        returns (string memory);

    function hasBeenNamed(uint256 tokenId) external view returns (bool);

    function nameColonist(uint256 tokenId, string memory newName) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IEON {
    function mint(address to, uint256 amount) external;

    function burn(address from, uint256 amount) external;

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.0;

interface IImperialGuild {

    function getBalance(
        address account,
        uint256 id
    ) external returns(uint256);

    function mint(
        uint256 typeId,
        uint256 paymentId,
        uint16 qty,
        address recipient
    ) external;

    function burn(
        uint256 typeId,
        uint16 qty,
        address burnFrom
    ) external;

    function handlePayment(uint256 amount) external;

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

    function updateOriginAccess(uint16[] memory tokenIds) external;

    function getTokenWriteBlock(uint256 tokenId) 
    external 
    view  
    returns(uint64);

    function hasBeenNamed(uint256 tokenId) external view returns (bool);

    function namePirate(uint256 tokenId, string memory newName) external;
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

interface IPytheas {
    function addColonistToPytheas(address account, uint16[] calldata tokenIds)
        external;

    function claimColonistFromPytheas(address account, uint16[] calldata tokenIds, bool unstake)
        external;

    function getColonistMined(address account, uint16 tokenId)
        external
        returns (uint256);

    function handleJoinPirates(address addr, uint16 tokenId) external;

    function payUp(
        uint16 tokenId,
        uint256 amtMined,
        address addr
    ) external;
}

// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.0;

interface IRAW {

    function updateOriginAccess(address user) external;


    function balanceOf(
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

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

interface IRandomizer {
    function random(uint256) external returns (uint256);
}

// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.0;

interface ITPirates {
    function tokenURI(uint256 tokenId) external view returns (string memory);
}