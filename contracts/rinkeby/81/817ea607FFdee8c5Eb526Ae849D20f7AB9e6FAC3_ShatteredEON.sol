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
import "./interfaces/IShatteredEON.sol";
import "./interfaces/IPytheas.sol";
import "./interfaces/IOrbitalBlockade.sol";
import "./interfaces/IColonist.sol";
import "./interfaces/ITColonist.sol";
import "./interfaces/IEON.sol";
import "./interfaces/IRAW.sol";
import "./interfaces/IImperialGuild.sol";
import "./interfaces/IRandomizer.sol";

contract ShatteredEON is IShatteredEON, Pausable {
    uint256 public OnosiaLiquorId;

    uint256 public constant maxRawEonCost = 250000; //250k rEON
    uint256 public constant maxEonCost = 200000 ether; //200k EON 

    address public auth;

    bool public eonOnlyActive;

    // address => can call setters
    mapping(address => bool) private admins;

    event newUser(address newUser); 

    bytes32 internal entropySauce;

    // reference to Pytheas for mint and stake of colonist
    IPytheas public pytheas;
    //reference to the oribitalBlockade of pirates for choosing random theives
    IOrbitalBlockade public orbital;
    // reference to $rEON for minting and refining
    IRAW public raw;
    // reference to refined EON for mininting and burning
    IEON public EON;
    // reference to colonist traits
    ITColonist public colTraits;
    // reference to the colonist NFT collection
    IColonist public colonistNFT;
    // reference to the galactic imperialGuild collection
    IImperialGuild public imperialGuild;
    //randy the randomizer
    IRandomizer public randomizer;

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

        // We'll use the last caller hash to add entropy to next caller
        entropySauce = keccak256(abi.encodePacked(acc, block.coinbase));
    }

    modifier onlyOwner() {
        require(msg.sender == auth);
        _;
    }

    /** CRITICAL TO SETUP */
    modifier requireContractsSet() {
        require(
            address(raw) != address(0) &&
                address(EON) != address(0) &&
                address(colTraits) != address(0) &&
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
        address _EON,
        address _colTraits,
        address _colonistNFT,
        address _pytheas,
        address _orbital,
        address _imperialGuild,
        address _randomizer
    ) external onlyOwner {
        raw = IRAW(_rEON);
        EON = IEON(_EON);
        colTraits = ITColonist(_colTraits);
        colonistNFT = IColonist(_colonistNFT);
        pytheas = IPytheas(_pytheas);
        orbital = IOrbitalBlockade(_orbital);
        imperialGuild = IImperialGuild(_imperialGuild);
        randomizer = IRandomizer(_randomizer);
    }

    /** EXTERNAL */

    /** Mint colonist. Payable with either rEON or EON after gen 0.
     * payments scaled accordingly
     *bool rayPayment = rEON payment */
    function mintColonist(
        uint256 amount,
        uint8 paymentId,
        bool stake
    ) external noCheaters {
        uint16 minted = colonistNFT.minted();
        uint256 MAX_TOKENS = colonistNFT.getMaxTokens();
        require(amount > 0 && amount <= 5, "5 max mints pers tx");
        if (eonOnlyActive) {
            require(paymentId == 0, "Only Eon sales phase");
        }
        uint16[] memory tokenIds = new uint16[](amount);
        uint256 seed;
        // Loop through the amount of
        uint256 rawCost = 0;
        uint256 eonCost = 0;
        address origin = tx.origin;
        bytes32 blockies = blockhash(block.number - 1);
        bytes32 sauce = entropySauce;
        uint256 blockTime = block.timestamp;
        for (uint256 i = 0; i < amount; i++) {
            minted++;
            seed = random(origin, blockies, sauce, minted, blockTime);
            address recipient = selectRecipient(seed);
            if (
                recipient != msg.sender &&
                imperialGuild.getBalance(msg.sender, OnosiaLiquorId) > 0
            ) {
                // If the mint is going to be stolen, there's a 50% chance
                //  a pirate will prefer a fine crafted eon liquor over it
                if (seed & 1 == 1) {
                    imperialGuild.safeTransferFrom(
                        msg.sender,
                        recipient,
                        OnosiaLiquorId,
                        1,
                        ""
                    );
                    recipient = msg.sender;
                }
            }
            tokenIds[i] = minted;
            if (!stake || recipient != msg.sender) {
                colonistNFT._mintColonist(recipient, seed);
            } else {
                colonistNFT._mintColonist(address(pytheas), seed);
                tokenIds[i] = minted;
            }
        }
        if (paymentId == 1) {
            rawCost = rawMintCost(minted, MAX_TOKENS) * amount;
            raw.burn(1, rawCost, msg.sender);
        } else {
            eonCost = EONmintCost(minted, MAX_TOKENS) * amount;
            EON.burn(msg.sender, eonCost);
        }
        if (stake) {
            pytheas.addColonistToPytheas(msg.sender, tokenIds);
        }

        emit newUser(msg.sender); 
    }

    /**
     * @param tokenId the ID to check the cost of to mint
     * @return the cost of the given token ID
     */
    function rawMintCost(uint256 tokenId, uint256 maxTokens)
        public
        pure
        returns (uint256)
    {
        if (tokenId <= (maxTokens * 8) / 24) return 4000; //10k-20k
        if (tokenId <= (maxTokens * 12) / 24) return 16000; //20k-30k
        if (tokenId <= (maxTokens * 16) / 24) return 48000; //30k-40k
        if (tokenId <= (maxTokens * 20) / 24) return 122500; //40k-50k
        if (tokenId <= (maxTokens * 22) / 24) return 250000; //50k-60k
        return maxRawEonCost;
    }

    function EONmintCost(uint256 tokenId, uint256 maxTokens)
        public
        pure
        returns (uint256)
    {
        if (tokenId <= (maxTokens * 8) / 24) return 3000 ether; //10k-20k
        if (tokenId <= (maxTokens * 12) / 24) return 12000 ether; //20k-30k
        if (tokenId <= (maxTokens * 16) / 24) return 36000 ether; //30k-40k
        if (tokenId <= (maxTokens * 20) / 24) return 98000 ether; //40k-50k
        if (tokenId <= (maxTokens * 22) / 24) return 200000 ether; //50k-60k
        return maxEonCost;
    }

    /** INTERNAL */

    /**
     * the first 10k go to the minter
     * the remaining 50k have a 10% chance to be given to a random staked pirate
     * @param seed a random value to select a recipient from
     * @return the address of the recipient (either the minter or the pirate thief's owner)
     */
    function selectRecipient(uint256 seed) internal view returns (address) {
        if (((seed >> 245) % 10) != 0) return _msgSender();
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

    function setEonOnly(bool _eonOnlyActive) external onlyOwner {
        eonOnlyActive = _eonOnlyActive;
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

    function random(address origin, bytes32 blockies,
    bytes32 sauce, uint16 seed, uint256 blockTime) internal pure returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        origin,
                        blockies,
                        blockTime,
                        sauce,
                        seed
                    )
                )
            );
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

// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.0;

interface ITColonist {
    function tokenURI(uint256 tokenId) external view returns (string memory);
}