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
import "./interfaces/IERC721TokenReciever.sol";
import "./interfaces/IPytheas.sol";
import "./interfaces/IOrbitalBlockade.sol";
import "./interfaces/IShatteredEON.sol";
import "./interfaces/IMasterStaker.sol";
import "./interfaces/IColonist.sol";
import "./interfaces/IRAW.sol";
import "./interfaces/IRandomizer.sol";

contract Pytheas is IPytheas, IERC721TokenReceiver, Pausable {
    // struct to store a stake's token, sOwner, and earning values
    struct Stake {
        uint16 tokenId;
        uint80 value;
        address sOwner;
    }

    event ColonistStaked(
        address indexed sOwner,
        uint256 indexed tokenId,
        uint256 value
    );
    event ColonistClaimed(
        uint256 indexed tokenId,
        bool indexed unstaked,
        uint256 earned
    );

    event Metamorphosis(address indexed addr, uint256 indexed tokenId);

    // reference to the Colonist NFT contract
    IColonist public colonistNFT;
    // reference to the game logic  contract
    IShatteredEON public shattered;
    // reference to the masterStaker contract
    IMasterStaker public masterStaker;
    // reference to orbital blockade to retrieve information on staked pirates
    IOrbitalBlockade public orbital;
    // reference to the $rEON contract for minting $rEON earnings
    IRAW public raw;
    // reference to Randomizer
    IRandomizer public randomizer;

    // maps tokenId to stake
    mapping(uint256 => Stake) private pytheas;

    // address => used in allowing system communication between contracts
    mapping(address => bool) private admins;

    // colonist earn 2700 $rEON per day

    //TODO: CHANGE FOR PRODUCTION 2700 per day

    uint256 public constant DAILY_rEON_RATE = 100000;
   
   //TODO: CHANGE FOR PRODUCTION 2 days
    // colonist must have 2 days worth of $rEON to unstake or else they're still down in the mines
    uint256 public constant MINIMUM_TO_EXIT = 1 minutes;
    
    // pirates take a 20% tax on all $rEON claimed
    uint256 public constant rEON_CLAIM_TAX_PERCENTAGE = 20;
    // there will only ever be (roughly) 3.125 billion (half of the total supply) rEON earned through staking;
    uint256 public constant MAXIMUM_GLOBAL_rEON = 3125000000;
    // colonistStaked
    uint256 public numColonistStaked;
    // amount of $rEON earned so far
    uint256 public totalRawEonEarned;
    // the last time $rEON was claimed
    uint256 private lastClaimTimestamp;
    //allowed to call owner functions
    address public auth;

    // emergency rescue to allow unstaking without any checks but without $rEON
    bool public rescueEnabled;

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
            address(colonistNFT) != address(0) &&
                address(raw) != address(0) &&
                address(orbital) != address(0) &&
                address(shattered) != address(0) &&
                address(masterStaker) != address(0) &&
                address(randomizer) != address(0),
            "Contracts not set"
        );
        _;
    }

    function setContracts(
        address _colonistNFT,
        address _raw,
        address _orbital,
        address _shattered,
        address _masterStaker,
        address _rand
    ) external onlyOwner {
        colonistNFT = IColonist(_colonistNFT);
        raw = IRAW(_raw);
        orbital = IOrbitalBlockade(_orbital);
        shattered = IShatteredEON(_shattered);
        masterStaker = IMasterStaker(_masterStaker);
        randomizer = IRandomizer(_rand);
    }

    /** STAKING */

    /**
     * adds Colonists to pytheas and crew
     * @param account the address of the staker
     * @param tokenIds the IDs of the Colonists to stake
     */
    function addColonistToPytheas(address account, uint16[] calldata tokenIds)
        external
        override
        whenNotPaused
        noCheaters
    {
        require(account == tx.origin);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (msg.sender == address(masterStaker)) {
                require(
                    colonistNFT.isOwner(tokenIds[i]) == account,
                    "Not Colonist Owner"
                );
                colonistNFT.transferFrom(account, address(this), tokenIds[i]);
            } else if (msg.sender != address(shattered)) {
                // dont do this step if its a mint + stake
                require(
                    colonistNFT.isOwner(tokenIds[i]) == msg.sender,
                    "Not Colonist Owner"
                );
                colonistNFT.transferFrom(
                    msg.sender,
                    address(this),
                    tokenIds[i]
                );
            } else if (tokenIds[i] == 0) {
                continue; // there may be gaps in the array for stolen tokens
            }
            _addColonistToPytheas(account, tokenIds[i]);
        }
    }

    /**
     * adds a single Colonist to pytheas
     * @param account the address of the staker
     * @param tokenId the ID of the Colonist to add to pytheas
     */
    function _addColonistToPytheas(address account, uint256 tokenId)
        internal
        _updateEarnings
    {
        pytheas[tokenId] = Stake({
            sOwner: account,
            tokenId: uint16(tokenId),
            value: uint80(block.timestamp)
        });
        numColonistStaked += 1;
        emit ColonistStaked(account, tokenId, block.timestamp);
    }

    /** CLAIMING / UNSTAKING */

    /**
     * realize $rEON earnings and optionally unstake tokens from Pytheas / Crew
     * to unstake a Colonist it will require it has 2 days worth of $rEON unclaimed
     * @param tokenIds the IDs of the tokens to claim earnings from
     * @param unstake whether or not to unstake ALL of the tokens listed in tokenIds
     */
    function claimColonistFromPytheas(
        address account,
        uint16[] calldata tokenIds,
        bool unstake
    ) external whenNotPaused _updateEarnings noCheaters {
        uint256 owed = 0;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            owed += _claimColonistFromPytheas(account, tokenIds[i], unstake);
        }
        if (owed == 0) {
            return;
        }
        raw.mint(1, owed, account);
    }

    /** external function to see the amount of raw eon
  a colonist has mined
  */

    function calculateRewards(uint256 tokenId)
        external
        view
        returns (uint256 owed)
    {
        Stake memory stake = pytheas[tokenId];
        if (totalRawEonEarned < MAXIMUM_GLOBAL_rEON) {
            owed = ((block.timestamp - stake.value) * DAILY_rEON_RATE) / 1 days;
        } else if (stake.value > lastClaimTimestamp) {
            owed = 0; // $rEON production stopped already
        } else {
            owed =
                ((lastClaimTimestamp - stake.value) * DAILY_rEON_RATE) /
                1 days; // stop earning additional $rEON if it's all been earned
        }
    }

    /**
     * realize $rEON earnings for a single Colonist and optionally unstake it
     * if not unstaking, pay a 20% tax to the staked Pirates
     * if unstaking, there is a 50% chance all $rEON is stolen
     * @param tokenId the ID of the Colonist to claim earnings from
     * @param unstake whether or not to unstake the Colonist
     * @return owed - the amount of $rEON earned
     */
    function _claimColonistFromPytheas(
        address account,
        uint256 tokenId,
        bool unstake
    ) internal returns (uint256 owed) {
        Stake memory stake = pytheas[tokenId];
        require(stake.sOwner == account, "Not Owner");
        require(
            !(unstake && block.timestamp - stake.value < MINIMUM_TO_EXIT),
            "Your shift isn't over!"
        );
        if (totalRawEonEarned < MAXIMUM_GLOBAL_rEON) {
            owed = ((block.timestamp - stake.value) * DAILY_rEON_RATE) / 1 days;
        } else if (stake.value > lastClaimTimestamp) {
            owed = 0; // $rEON production stopped already
        } else {
            owed =
                ((lastClaimTimestamp - stake.value) * DAILY_rEON_RATE) /
                1 days; // stop earning additional $rEON if it's all been earned
        }
        if (unstake) {
            if (randomizer.random(tokenId) & 1 == 1) {
                // 50% chance of all $rEON stolen
                orbital.payPirateTax(owed);
                owed = 0;
            }
            delete pytheas[tokenId];
            numColonistStaked -= 1;
            // Always transfer last to guard against reentrance
            colonistNFT.safeTransferFrom(address(this), account, tokenId, ""); // send back colonist
        } else {
            orbital.payPirateTax((owed * rEON_CLAIM_TAX_PERCENTAGE) / 100); // percentage tax to staked pirates
            owed = (owed * (100 - rEON_CLAIM_TAX_PERCENTAGE)) / 100; // remainder goes to Colonist sOwner
            pytheas[tokenId] = Stake({
                sOwner: account,
                tokenId: uint16(tokenId),
                value: uint80(block.timestamp)
            }); // reset stake
        }
        emit ColonistClaimed(tokenId, unstake, owed);
    }

    // To be worthy of joining the pirates one must be
    // willing to risk it all, used to handle the colonist
    // token burn when making an attempt to join the pirates
    function handleJoinPirates(address addr, uint16 tokenId)
        external
        override
        noCheaters
    {
        require(admins[msg.sender]);
        Stake memory stake = pytheas[tokenId];
        require(stake.sOwner == addr, "Pytheas: Not Owner");
        delete pytheas[tokenId];
        colonistNFT.burn(tokenId);

        emit Metamorphosis(addr, tokenId);
    }

    function payUp(
        uint16 tokenId,
        uint256 amtMined,
        address addr
    ) external override _updateEarnings {
        require(admins[msg.sender]);
        uint256 minusTax = 0;
        minusTax += _piratesLife(tokenId, amtMined, addr);
        if (minusTax == 0) {
            return;
        }
        raw.mint(1, minusTax, addr);
    }

    /**
   * external admin only function to get the amount owed to a colonist
   * for use whem making a pirate attempt
   @param account the account that owns the colonist
   @param tokenId  the ID of the colonist who is mining
    */
    function getColonistMined(address account, uint16 tokenId)
        external
        view
        override
        returns (uint256 minedAmt)
    {
        require(admins[msg.sender]);
        uint256 mined = 0;
        mined += colonistDues(account, tokenId);
        return mined;
    }

    /**
 * internal function to calculate the amount a colonist
 * is owed for their mining attempts;
 * for use with making a pirate attempt;
 @param addr the owner of the colonist
 @param tokenId the ID of the colonist who is mining
  */
    function colonistDues(address addr, uint16 tokenId)
        internal
        view
        returns (uint256 mined)
    {
        Stake memory stake = pytheas[tokenId];
        require(stake.sOwner == addr, "Not Owner");
        if (totalRawEonEarned < MAXIMUM_GLOBAL_rEON) {
            mined =
                ((block.timestamp - stake.value) * DAILY_rEON_RATE) /
                1 days;
        } else if (stake.value > lastClaimTimestamp) {
            mined = 0; // $rEON production stopped already
        } else {
            mined =
                ((lastClaimTimestamp - stake.value) * DAILY_rEON_RATE) /
                1 days; // stop earning additional $rEON if it's all been earned
        }
    }

    /*
Realizes gained rEON on a failed pirate attempt and always pays pirate tax
*/
    function _piratesLife(
        uint16 tokenId,
        uint256 amtMined,
        address addr
    ) internal returns (uint256 owed) {
        Stake memory stake = pytheas[tokenId];
        require(stake.sOwner == addr, "Pytheas: Not Owner");
        // tax amount sent to pirates
        uint256 pirateTax = (amtMined * rEON_CLAIM_TAX_PERCENTAGE) / 100;
        orbital.payPirateTax(pirateTax);
        // remainder after pirate tax goes to Colonist
        //sOwner who made the pirate attempt
        owed = (amtMined - pirateTax);
        // reset stake
        pytheas[tokenId] = Stake({
            sOwner: addr,
            tokenId: uint16(tokenId),
            value: uint80(block.timestamp)
        });
        emit ColonistClaimed(tokenId, false, owed);
    }

    /**
     * emergency unstake tokens
     * @param tokenIds the IDs of the tokens to claim earnings from
     */
    function rescue(uint256[] calldata tokenIds) external noCheaters {
        require(rescueEnabled, "Rescue Not Enabled");
        uint256 tokenId;
        Stake memory stake;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            tokenId = tokenIds[i];
            stake = pytheas[tokenId];
            require(stake.sOwner == msg.sender, "Not Owner");
            delete pytheas[tokenId];
            numColonistStaked -= 1;
            colonistNFT.safeTransferFrom(
                address(this),
                msg.sender,
                tokenId,
                ""
            ); // send back Colonist
            emit ColonistClaimed(tokenId, true, 0);
        }
    }

    /** ACCOUNTING */

    /**
     * tracks $rEON earnings to ensure it stops once 6.5 billion is eclipsed
     */
    modifier _updateEarnings() {
        if (totalRawEonEarned < MAXIMUM_GLOBAL_rEON) {
            totalRawEonEarned +=
                ((block.timestamp - lastClaimTimestamp) *
                    numColonistStaked *
                    DAILY_rEON_RATE) /
                1 days;
            lastClaimTimestamp = block.timestamp;
        }
        _;
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

interface IShatteredEON {}