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
import "./interfaces/IShatteredEON.sol";
import "./interfaces/IImperialGuild.sol";
import "./interfaces/IRAW.sol";
import "./interfaces/IEON.sol";
import "./interfaces/IColonist.sol";
import "./interfaces/IPirates.sol";

contract DenOfAlgol is Pausable {
    uint8 public onosiaLiquorId;
    // shard Ids
    uint256 public spearId;
    uint256 public templeId;
    uint256 public riotId;
    uint256 public phantomId;

    // activate shard minting 
    bool public shardsActive;
    // address => used in allowing system communication between contracts
    mapping(address => bool) private admins;
    //owner
    address public auth;
    // reference to raw resource contract
    IRAW public RAW;
    // reference to refined EON for minting and burning
    IEON public EON;
    // reference to the pirate NFT collection
    IPirates public pirateNFT;
    // reference to the colonist NFT collection
    IColonist public colonistNFT;
    // reference to the ImperialGuild collection
    IImperialGuild public imperialGuild;
    //reference to main game logic
    IShatteredEON public shattered;

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
            address(RAW) != address(0) &&
                address(EON) != address(0) &&
                address(pirateNFT) != address(0) &&
                address(colonistNFT) != address(0) &&
                address(imperialGuild) != address(0) &&
                address(shattered) != address(0),
            "Contracts not set"
        );
        _;
    }

    function setContracts(
        address _RAW,
        address _EON,
        address _pirateNFT,
        address _colonistNFT,
        address _imperialGuild,
        address _shatteredEON
    ) external onlyOwner {
        RAW = IRAW(_RAW);
        EON = IEON(_EON);
        pirateNFT = IPirates(_pirateNFT);
        colonistNFT = IColonist(_colonistNFT);
        imperialGuild = IImperialGuild(_imperialGuild);
        shattered = IShatteredEON(_shatteredEON);
    }

    // $rEON or EON exchange amount handled within ImperialGuild contract
    // Will fail if sender doesn't have enough $rEON or $EON or does not
    // provide the required sacrafices,
    // Transfer does not need approved,
    // as there is established trust between this contract and the ImperialGuild contract

    function buySpear(bool RAWPayment) external whenNotPaused noCheaters {
        require(shardsActive = true, "Shard minting not available yet");
        require(tx.origin == msg.sender, "Only EOA");
        if (RAWPayment) {
            imperialGuild.mint(spearId, 1, 1, msg.sender);
        } else {
            imperialGuild.mint(spearId, 0, 1, msg.sender);
        }
    }

    function buyTemple(bool RAWPayment) external whenNotPaused noCheaters {
        require(shardsActive = true, "Shard minting not available yet");
        require(tx.origin == msg.sender, "Only EOA");
        if (RAWPayment) {
            imperialGuild.mint(templeId, 1, 1, msg.sender);
        } else {
            imperialGuild.mint(templeId, 0, 1, msg.sender);
        }
    }

    function makeOnosiaLiquor(uint16 qty, bool RAWPayment)
        external
        whenNotPaused
        noCheaters
    {
        require(tx.origin == msg.sender);
        require(onosiaLiquorId > 0, "wrong tokenId");
        if (RAWPayment) {
            imperialGuild.mint(onosiaLiquorId, 1, qty, msg.sender);
        } else {
            imperialGuild.mint(onosiaLiquorId, 0, qty, msg.sender);
        }
    }

    function buyRiot(uint256 colonistId, bool RAWPayment)
        external
        whenNotPaused
        noCheaters
    {
        require(shardsActive = true, "Shard minting not available yet");
        require(tx.origin == msg.sender);
        // Must check this, as getTokenTraits will be allowed since this contract is an admin
        if (RAWPayment) {
            // This will check if origin is the owner of the token
            colonistNFT.burn(colonistId);
            imperialGuild.mint(riotId, 1, 1, msg.sender);
        } else {
            // check origin of owner of token
            colonistNFT.burn(colonistId);
            imperialGuild.mint(riotId, 0, 1, msg.sender);
        }
    }

    function buyPhantom(
        uint256 colonistId,
        uint256 pirateId,
        bool RAWPayment
    ) external whenNotPaused noCheaters {
        require(shardsActive = true, "Shard minting not available yet");
        require(tx.origin == msg.sender);
        // Must check this, as getTokenTraits will be allowed since this contract is an admin
        if (RAWPayment) {
            // check origin of tokens owner
            colonistNFT.burn(colonistId);
            pirateNFT.burn(pirateId);
            imperialGuild.mint(phantomId, 1, 1, msg.sender);
        } else {
            // check origin of token owner
            colonistNFT.burn(colonistId);
            pirateNFT.burn(pirateId);
            imperialGuild.mint(phantomId, 0, 1, msg.sender);
        }
    }

    function setOnosiaLiquorId(uint8 id) external onlyOwner {
        onosiaLiquorId = id;
    }

    function setShardIds(
        uint256 spear,
        uint256 temple,
        uint256 riot,
        uint256 phantom
    ) external onlyOwner {
        spearId = spear;
        templeId = temple;
        riotId = riot;
        phantomId = phantom;
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
    function add(address addr) external onlyOwner {
        admins[addr] = true;
    }

    function toggleShardMinting(bool _shardsActive) external onlyOwner {
        shardsActive = _shardsActive;
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

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

interface IShatteredEON {}