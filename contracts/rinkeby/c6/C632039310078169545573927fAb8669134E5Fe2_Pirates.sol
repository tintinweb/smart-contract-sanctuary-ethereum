// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/Pausable.sol";
import "./ERC721.sol";
import "./interfaces/IPirates.sol";
import "./interfaces/ITPirates.sol";
import "./interfaces/IHPirates.sol";
import "./interfaces/IOrbitalBlockade.sol";
import "./interfaces/IRandomizer.sol";
import "./interfaces/IEON.sol";

contract Pirates is IPirates, ERC721, Pausable {
    struct LastWrite {
        uint64 time;
        uint64 blockNum;
    }

    event PirateNamed(uint256 indexed tokenId, string newName);
    event PirateMinted(uint256 indexed tokenId);
    event PirateStolen(uint256 indexed tokenId);

    // tally of the number of pirates that have been minted
    uint16 public override piratesMinted;

    // an arbatrary counter to dish out IDs
    uint16 public override minted;

    // toggle naming
    bool public namingActive;

    // number of max pirates that can exist with the total minted to keep a 10:1 ratio

    uint256 public constant MAX_PIRATES = 6000;

    // cost to name
    uint256 public constant costToName = 2000 ether; //2000 EON

    // mapping from tokenId to a struct containing the colonist token's traits
    mapping(uint256 => Pirate) public tokenTraitsPirate;

    // mapping from tokenId to a stuct containing the honors pirates
    mapping(uint256 => HPirates) public tokenTraitsHonors;
    mapping(uint256 => bool) public isHonors;

    // mapping from hashed(tokenTrait) to the tokenId it's associated with
    // used to ensure there are no duplicates
    mapping(uint256 => uint256) public existingCombinations;

    // Mapping from token ID to name
    mapping(uint256 => string) private _tokenName;

    mapping(uint256 => bool) private _hasName;

    // Mapping if certain name string has already been reserved
    mapping(string => bool) private _nameReserved;

    // list of probabilities for each trait type
    uint8[][9] public rarities;
    uint8[][9] public aliases;

    // reference to the orbital for transfers without approval
    IOrbitalBlockade public orbital;

    // reference to Traits
    ITPirates public traits;

    // reference to honors traits
    IHPirates public honorTraits;

    //reference to Randomizer
    IRandomizer public randomizer;

    //referenve to EON
    IEON public EON;

    address public auth;

    // address => used in allowing system communication between contracts
    mapping(address => bool) private admins;

    // Imperial Guild Treasury
    address private imperialGuildTreasury;

    /**
     * instantiates contract and rarity tables
     */
    constructor() ERC721("ShatteredEon", "Pirates") {
        auth = msg.sender;
        admins[msg.sender] = true;

        //PIRATES
        //sky
        rarities[0] = [200, 200, 200, 200, 200, 255];
        aliases[0] = [1, 2, 0, 4, 3, 5];
        //cockpit
        rarities[1] = [255];
        aliases[1] = [0];
        //base
        rarities[2] = [
            255,
            255,
            255,
            255,
            200,
            200,
            200,
            200,
            40,
            40,
            40,
            40,
            150,
            150,
            150,
            150,
            255,
            255,
            255,
            255
        ];
        aliases[2] = [
            16,
            17,
            18,
            19,
            7,
            6,
            5,
            4,
            3,
            2,
            1,
            0,
            16,
            17,
            18,
            19,
            0,
            1,
            2,
            3
        ];
        //engine
        rarities[3] = [
            150,
            150,
            150,
            150,
            255,
            255,
            255,
            255,
            100,
            100,
            100,
            100,
            255,
            255,
            255,
            255,
            40,
            40,
            40,
            40
        ];
        aliases[3] = [
            8,
            9,
            10,
            11,
            12,
            13,
            14,
            15,
            15,
            14,
            13,
            12,
            7,
            6,
            5,
            4,
            8,
            9,
            10,
            11
        ];
        //nose
        rarities[4] = [
            255,
            255,
            255,
            255,
            150,
            150,
            150,
            150,
            255,
            255,
            255,
            255,
            120,
            120,
            120,
            120,
            40,
            40,
            40,
            40
        ];
        aliases[4] = [
            0,
            1,
            2,
            3,
            15,
            14,
            13,
            12,
            11,
            10,
            9,
            8,
            3,
            2,
            1,
            0,
            12,
            13,
            14,
            15
        ];
        //wing
        rarities[5] = [
            120,
            120,
            120,
            120,
            40,
            40,
            40,
            40,
            150,
            150,
            150,
            150,
            255,
            255,
            255,
            255,
            255,
            255,
            255,
            255
        ];
        aliases[5] = [
            19,
            18,
            17,
            16,
            3,
            2,
            1,
            0,
            0,
            1,
            2,
            3,
            19,
            18,
            17,
            16,
            15,
            14,
            13,
            12
        ];
        //weapon1
        rarities[6] = [255, 150, 220, 220, 120, 30];
        aliases[6] = [0, 0, 0, 0, 0, 0];
        //weapon2
        rarities[7] = [255, 150, 30, 100, 20, 200];
        aliases[7] = [0, 0, 0, 0, 0, 0];
        //rank
        rarities[8] = [12, 160, 73, 255];
        aliases[8] = [2, 3, 3, 3];
    }

    modifier requireContractsSet() {
        require(
            address(traits) != address(0) &&
                address(orbital) != address(0) &&
                address(randomizer) != address(0)
        );
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == auth);
        _;
    }

    function setContracts(
        address _traits,
        address _honorTraits,
        address _orbital,
        address _rand,
        address _eon
    ) external onlyOwner {
        traits = ITPirates(_traits);
        honorTraits = IHPirates(_honorTraits);
        orbital = IOrbitalBlockade(_orbital);
        randomizer = IRandomizer(_rand);
        EON = IEON(_eon);
    }

    /*///////////////////////////////////////////////////////////////
                    EXTERNAL
    //////////////////////////////////////////////////////////////*/

    function _mintPirate(address recipient, uint256 seed)
        external
        override
        whenNotPaused
    {
        require(admins[msg.sender], "Only Admins");
        require(piratesMinted + 1 <= MAX_PIRATES, "Pirate forces are full");
        minted++;
        piratesMinted++;
        generatePirate(minted, seed);
        if (tx.origin != recipient && recipient != address(orbital)) {
            // Stolen!
            emit PirateStolen(minted);
        }
        _mint(recipient, minted);
    }

    function _mintHonors(address recipient, uint8 id)
        external
        whenNotPaused
        onlyOwner
    {
        require(minted + 1 <= MAX_PIRATES, "All Pirates Minted");
        minted++;
        piratesMinted++;
        generateHonors(minted, id);
        _mint(recipient, minted);
    }

    /**
     * Burn a token - any game logic should be handled before this function.
     */
    function burn(uint256 tokenId) external override whenNotPaused {
        require(admins[msg.sender]);
        require(ownerOf[tokenId] == tx.origin, "not owner");
        _burn(tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public override(ERC721, IPirates) {
        require(from == ownerOf[id], "WRONG_FROM");

        require(to != address(0), "INVALID_RECIPIENT");
        // allow admin contracts to send without approval
        if (!admins[msg.sender]) {
            require(
                msg.sender == from ||
                    msg.sender == getApproved[id] ||
                    isApprovedForAll[from][msg.sender],
                "NOT_AUTHORIZED"
            );
        }
        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            balanceOf[from]--;

            balanceOf[to]++;
        }

        ownerOf[id] = to;

        delete getApproved[id];

        emit Transfer(from, to, id);
    }

    function generatePirate(uint256 tokenId, uint256 seed)
        internal
        returns (Pirate memory p)
    {
        p = selectPiTraits(seed);
        if (existingCombinations[structToHashPi(p)] == 0) {
            tokenTraitsPirate[tokenId] = p;
            existingCombinations[structToHashPi(p)] = tokenId;
            emit PirateMinted(tokenId);
            return p;
        }
        return generatePirate(tokenId, randomizer.random(seed));
    }

    function generateHonors(uint256 tokenId, uint8 id)
        internal
        returns (HPirates memory r)
    {
        r.Legendary = id;
        tokenTraitsHonors[minted] = r;
        isHonors[minted] = true;
        emit PirateMinted(tokenId);
        return r;
    }

    /**
     * uses A.J. Walker's Alias algorithm for O(1) rarity table lookup
     * ensuring O(1) instead of O(n) reduces mint cost by more than 50%
     * probability & alias tables are generated off-chain beforehand
     * @param seed portion of the 256 bit seed to remove trait correlation
     * @param traitType the trait type to select a trait for
     * @return the ID of the randomly selected trait
     */
    function selectTrait(uint16 seed, uint8 traitType)
        internal
        view
        returns (uint8)
    {
        uint8 trait = uint8(seed) % uint8(rarities[traitType].length);
        // If a selected random trait probability is selected (biased coin) return that trait
        if (seed >> 8 < rarities[traitType][trait]) return trait;
        return aliases[traitType][trait];
    }

    function selectPiTraits(uint256 seed)
        internal
        view
        returns (Pirate memory p)
    {
        p.isPirate = true;
        seed >>= 16;
        p.sky = selectTrait(uint16(seed & 0xFFFF), 0);
        seed >>= 16;
        p.cockpit = selectTrait(uint16(seed & 0xFFFF), 1);
        seed >>= 16;
        p.base = selectTrait(uint16(seed & 0xFFFF), 2);
        seed >>= 16;
        p.engine = selectTrait(uint16(seed & 0xFFFF), 3);
        seed >>= 16;
        p.nose = selectTrait(uint16(seed & 0xFFFF), 4);
        seed >>= 16;
        p.wing = selectTrait(uint16(seed & 0xFFFF), 5);
        seed >>= 16;
        p.weapon1 = selectTrait(uint16(seed & 0xFFFF), 6);
        seed >>= 16;
        p.weapon2 = selectTrait(uint16(seed & 0xFFFF), 7);
        seed >>= 16;
        p.rank = selectTrait(uint16(seed & 0xFFFF), 8);
    }

    function structToHashPi(Pirate memory q) internal pure returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        q.sky,
                        q.cockpit,
                        q.base,
                        q.engine,
                        q.nose,
                        q.wing,
                        q.weapon1,
                        q.weapon2,
                        q.rank
                    )
                )
            );
    }

    function tokenNameByIndex(uint256 index)
        public
        view
        returns (string memory)
    {
        return _tokenName[index];
    }

    function isNameReserved(string memory nameString)
        public
        view
        returns (bool)
    {
        return _nameReserved[toLower(nameString)];
    }

    function hasBeenNamed(uint256 tokenId) public view returns (bool) {
        return _hasName[tokenId];
    }

    function namePirate(uint256 tokenId, string memory newName) public {
        require(namingActive == true, "naming not yet availanle");
        require(ownerOf[tokenId] == msg.sender, "Not your pirate to name");
        require(hasBeenNamed(tokenId) == false, "Pirate already named");
        require(validateName(newName) == true, "Not a valid name");
        require(isNameReserved(newName) == false, "Name already reserved");

        //   IERC20(_eonAddress).transferFrom(msg.sender, address(this), NAME_CHANGE_PRICE);

        toggleReserveName(newName, true);
        toggleHasName(tokenId, true);
        _tokenName[tokenId] = newName;
        EON.burn(msg.sender, costToName);
        emit PirateNamed(tokenId, newName);
    }

    /**
     * @dev Reserves the name if isReserve is set to true, de-reserves if set to false
     */
    function toggleReserveName(string memory str, bool isReserve) internal {
        _nameReserved[toLower(str)] = isReserve;
    }

    function toggleHasName(uint256 tokenId, bool hasName) internal {
        _hasName[tokenId] = hasName;
    }

    /**
     * @dev Check if the name string is valid (Alphanumeric and spaces without leading or trailing space)
     */
    function validateName(string memory str) public pure returns (bool) {
        bytes memory b = bytes(str);
        if (b.length < 1) return false;
        if (b.length > 25) return false; // Cannot be longer than 25 characters
        if (b[0] == 0x20) return false; // Leading space
        if (b[b.length - 1] == 0x20) return false; // Trailing space

        bytes1 lastChar = b[0];

        for (uint256 i; i < b.length; i++) {
            bytes1 char = b[i];

            if (char == 0x20 && lastChar == 0x20) return false; // Cannot contain continous spaces

            if (
                !(char >= 0x30 && char <= 0x39) && //9-0
                !(char >= 0x41 && char <= 0x5A) && //A-Z
                !(char >= 0x61 && char <= 0x7A) && //a-z
                !(char == 0x20) //space
            ) return false;

            lastChar = char;
        }

        return true;
    }

    /**
     * @dev Converts the string to lowercase
     */
    function toLower(string memory str) public pure returns (string memory) {
        bytes memory bStr = bytes(str);
        bytes memory bLower = new bytes(bStr.length);
        for (uint256 i = 0; i < bStr.length; i++) {
            // Uppercase character
            if ((uint8(bStr[i]) >= 65) && (uint8(bStr[i]) <= 90)) {
                bLower[i] = bytes1(uint8(bStr[i]) + 32);
            } else {
                bLower[i] = bStr[i];
            }
        }
        return string(bLower);
    }

    /**
     * enables owner to pause / unpause minting
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

    function toggleNameing(bool _namingActive) external onlyOwner {
        namingActive = _namingActive;
    }

    function setImperialGuildTreasury(address _imperialTreasury)
        external
        onlyOwner
    {
        imperialGuildTreasury = _imperialTreasury;
    }

    /** Traits */

    function getTokenTraitsPirate(uint256 tokenId)
        external
        view
        override
        returns (Pirate memory)
    {
        return tokenTraitsPirate[tokenId];
    }

    function getTokenTraitsHonors(uint256 tokenId)
        external
        view
        override
        returns (HPirates memory)
    {
        return tokenTraitsHonors[tokenId];
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        if (isHonors[tokenId]) {
            return honorTraits.tokenURI(tokenId);
        }
        return traits.tokenURI(tokenId);
    }

    function isOwner(uint256 tokenId) public view returns (address) {
        address addr = ownerOf[tokenId];
        return addr;
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public override(ERC721, IPirates) {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(
                    msg.sender,
                    from,
                    id,
                    ""
                ) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes memory data
    ) public override(ERC721, IPirates) {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(
                    msg.sender,
                    from,
                    id,
                    data
                ) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    // For OpenSeas
    function owner() public view virtual returns (address) {
        return auth;
    }
}

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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
/// @dev Note that balanceOf does not revert if passed the zero address, in defiance of the ERC.
abstract contract ERC721 {
    /*///////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 indexed tokenId
    );

    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    /*///////////////////////////////////////////////////////////////
                          METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    function tokenURI(uint256 id) public view virtual returns (string memory);

    /*///////////////////////////////////////////////////////////////
                            ERC721 STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(address => uint256) public balanceOf;

    mapping(uint256 => address) public ownerOf;

    mapping(uint256 => address) public getApproved;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*///////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    /*///////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 id) public virtual {
        address owner = ownerOf[id];

        require(
            msg.sender == owner || isApprovedForAll[owner][msg.sender],
            "NOT_AUTHORIZED"
        );

        getApproved[id] = spender;

        emit Approval(owner, spender, id);
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        require(from == ownerOf[id], "WRONG_FROM");

        require(to != address(0), "INVALID_RECIPIENT");

        require(
            msg.sender == from ||
                msg.sender == getApproved[id] ||
                isApprovedForAll[from][msg.sender],
            "NOT_AUTHORIZED"
        );

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            balanceOf[from]--;

            balanceOf[to]++;
        }

        ownerOf[id] = to;

        delete getApproved[id];

        emit Transfer(from, to, id);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(
                    msg.sender,
                    from,
                    id,
                    ""
                ) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes memory data
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(
                    msg.sender,
                    from,
                    id,
                    data
                ) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    /*///////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId)
        public
        pure
        virtual
        returns (bool)
    {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /*///////////////////////////////////////////////////////////////
                       INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 id) internal virtual {
        require(to != address(0), "INVALID_RECIPIENT");

        require(ownerOf[id] == address(0), "ALREADY_MINTED");

        // Counter overflow is incredibly unrealistic.
        unchecked {
            balanceOf[to]++;
        }

        ownerOf[id] = to;

        emit Transfer(address(0), to, id);
    }

    function _burn(uint256 id) internal virtual {
        address owner = ownerOf[id];

        require(ownerOf[id] != address(0), "NOT_MINTED");

        // Ownership check above ensures no underflow.
        unchecked {
            balanceOf[owner]--;
        }

        delete ownerOf[id];

        delete getApproved[id];

        emit Transfer(owner, address(0), id);
    }
}

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
interface ERC721TokenReceiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 id,
        bytes calldata data
    ) external returns (bytes4);
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

    function isOwner(uint256 tokenId) external view returns (address);

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

    function isHonors(uint256 tokenId) external view returns (bool);

    function hasBeenNamed(uint256 tokenId) external view returns (bool);

    function namePirate(uint256 tokenId, string memory newName) external;
}

// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.0;

interface ITPirates {
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.0;

interface IHPirates {
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

interface IOrbitalBlockade {
    function addPiratesToCrew(address account, uint16[] calldata tokenIds)
        external;

    function claimPiratesFromCrew(
        address account,
        uint16[] calldata tokenIds,
        bool unstake
    ) external;

    function payPirateTax(uint256 amount) external;

    function randomPirateOwner(uint256 seed) external view returns (address);
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

interface IRandomizer {
    function random(uint256) external returns (uint256);
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