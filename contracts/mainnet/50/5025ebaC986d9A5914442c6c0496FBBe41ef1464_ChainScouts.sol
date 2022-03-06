//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./BaseTokenURIProvider.sol";
import "./ChainScoutMetadata.sol";
import "./ExtensibleERC721Enumerable.sol";
import "./Generator.sol";
import "./IChainScouts.sol";
import "./IUtilityERC20.sol";
import "./MerkleWhitelistERC721Enumerable.sol";
import "./Rng.sol";

contract ChainScouts is IChainScouts, MerkleWhitelistERC721Enumerable {
    using RngLibrary for Rng;

    mapping (string => ChainScoutsExtension) public extensions;
    Rng private rng = RngLibrary.newRng();
    mapping (uint => ChainScoutMetadata) internal tokenIdToMetadata;
    uint private _mintPriceWei = 0.068 ether;

    event MetadataChanged(uint tokenId);

    constructor(Payee[] memory payees, bytes32 merkleRoot)
    ERC721A("Chain Scouts", "CS")
    MerkleWhitelistERC721Enumerable(
        payees,        // _payees
        5,             // max mints per tx
        6888,          // supply
        3,             // max wl mints
        merkleRoot     // wl merkle root
    ) {}

    function adminCreateChainScout(ChainScoutMetadata calldata tbd, address owner) external override onlyAdmin {
        require(totalSupply() < maxSupply, "ChainScouts: totalSupply >= maxSupply");
        uint tokenId = _currentIndex;
        _mint(owner, 1, "", false);
        tokenIdToMetadata[tokenId] = tbd;
    }

    function adminSetChainScoutMetadata(uint tokenId, ChainScoutMetadata calldata tbd) external override onlyAdmin {
        tokenIdToMetadata[tokenId] = tbd;
        emit MetadataChanged(tokenId);
    }

    function adminRemoveExtension(string calldata key) external override onlyAdmin {
        delete extensions[key];
    }

    function adminSetExtension(string calldata key, ChainScoutsExtension extension) external override onlyAdmin {
        extensions[key] = extension;
    }

    function adminSetMintPriceWei(uint max) external onlyAdmin {
        _mintPriceWei = max;
    }

    function getChainScoutMetadata(uint tokenId) external view override returns (ChainScoutMetadata memory) {
        return tokenIdToMetadata[tokenId];
    }

    function createMetadataForMintedToken(uint tokenId) internal override {
        (tokenIdToMetadata[tokenId], rng) = Generator.getRandomMetadata(rng);
    }

    function tokenURI(uint tokenId) public override view returns (string memory) {
        return BaseTokenURIProvider(address(extensions["tokenUri"])).tokenURI(tokenId);
    }

    function mintPriceWei() public view override returns (uint) {
        return _mintPriceWei;
    }

    function whitelistMintAndStake(bytes32[] calldata proof, uint count) external payable returns (uint) {
        uint start = whitelistMint(proof, count);

        uint[] memory ids = new uint[](count);
        for (uint i = 0; i < count; ++i) {
            ids[i] = start + i;
        }

        IUtilityERC20(address(extensions["token"])).stake(ids);

        return start;
    }

    function publicMintAndStake(uint count) external payable returns (uint) {
        uint start = publicMint(count);

        uint[] memory ids = new uint[](count);
        for (uint i = 0; i < count; ++i) {
            ids[i] = start + i;
        }

        IUtilityERC20(address(extensions["token"])).stake(ids);

        return start;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ITokenURIProvider.sol";
import "./OpenSeaMetadata.sol";
import "./ChainScoutsExtension.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/**
 * Base class for all Token URI providers. Giving a new implementation of this class allows you to change how the metadata is created.
 */
abstract contract BaseTokenURIProvider is ITokenURIProvider, ChainScoutsExtension {
    string private baseName;
    string private defaultDescription;
    mapping (uint => string) private names;
    mapping (uint => string) private descriptions;

    constructor(string memory _baseName, string memory _defaultDescription) {
        baseName = _baseName;
        defaultDescription = _defaultDescription;
    }

    modifier stringIsJsonSafe(string memory str) {
        bytes memory b = bytes(str);
        for (uint i = 0; i < b.length; ++i) {
            uint8 char = uint8(b[i]);
            //              0-9                         A-Z                         a-z                   space
            if (!(char >= 48 && char <= 57 || char >= 65 && char <= 90 || char >= 97 && char <= 122 || char == 32)) {
                revert("BaseTokenURIProvider: All chars must be spaces or alphanumeric");
            }
        }
        _;
    }

    /**
     * @dev Sets the description of a token on OpenSea.
     * Must be an admin or the owner of the token.
     * 
     * The description may only contain A-Z, a-z, 0-9, or spaces.
     */
    function setDescription(uint tokenId, string memory description) external canAccessToken(tokenId) stringIsJsonSafe(description) {
        descriptions[tokenId] = description;
    }

    /**
     * @dev Sets the description of a token on OpenSea.
     * Must be an admin or the owner of the token.
     * 
     * The name may only contain A-Z, a-z, 0-9, or spaces.
     */
    function setName(uint tokenId, string memory name) external canAccessToken(tokenId) stringIsJsonSafe(name) {
        names[tokenId] = name;
    }

    /**
     * @dev Gets the background color of the given token ID as it appears on OpenSea.
     */
    function tokenBgColor(uint tokenId) internal view virtual returns (uint24);

    /**
     * @dev Gets the SVG of the given token ID.
     */
    function tokenSvg(uint tokenId) public view virtual returns (string memory);

    /**
     * @dev Gets the OpenSea attributes of the given token ID.
     */
    function tokenAttributes(uint tokenId) internal view virtual returns (Attribute[] memory);

    /**
     * @dev Gets the OpenSea token URI of the given token ID.
     */
    function tokenURI(uint tokenId) external view override returns (string memory) {
        string memory name = names[tokenId];
        if (bytes(name).length == 0) {
            name = string(abi.encodePacked(
                baseName,
                " #",
                Strings.toString(tokenId)
            ));
        }

        string memory description = descriptions[tokenId];
        if (bytes(description).length == 0) {
            description = defaultDescription;
        }

        return OpenSeaMetadataLibrary.makeMetadata(OpenSeaMetadata(
            tokenSvg(tokenId),
            description,
            name,
            tokenBgColor(tokenId),
            tokenAttributes(tokenId)
        ));
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Enums.sol";

struct KeyValuePair {
    string key;
    string value;
}

struct ChainScoutMetadata {
    Accessory accessory;
    BackAccessory backaccessory;
    Background background;
    Clothing clothing;
    Eyes eyes;
    Fur fur;
    Head head;
    Mouth mouth;
    uint24 attack;
    uint24 defense;
    uint24 luck;
    uint24 speed;
    uint24 strength;
    uint24 intelligence;
    uint16 level;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "erc721a/contracts/ERC721A.sol";
import "./IExtensibleERC721Enumerable.sol";
// for opensea ownership
import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract ExtensibleERC721Enumerable is IExtensibleERC721Enumerable, ERC721A, Ownable {
    mapping (address => bool) public override isAdmin;
    bool public enabled = true;

    constructor() {
        isAdmin[msg.sender] = true;
    }

    modifier onlyAdmin() {
        require(isAdmin[msg.sender], "ExtensibleERC721Enumerable: admins only");
        _;
    }

    modifier whenEnabled() {
        require(enabled, "ExtensibleERC721Enumerable: currently disabled");
        _;
    }

    function addAdmin(address addr) external override onlyAdmin {
        isAdmin[addr] = true;
    }

    function removeAdmin(address addr) external override onlyAdmin {
        delete isAdmin[addr];
    }

    function adminSetEnabled(bool e) external onlyAdmin {
        enabled = e;
    }

    function canAccessToken(address addr, uint tokenId) public view override returns (bool) {
        return isAdmin[addr] || ownerOf(tokenId) == addr || address(this) == addr;
    }

    function isApprovedForAll(address owner, address operator) public view virtual override(IERC721, ERC721A) returns (bool) {
        return isAdmin[operator] || super.isApprovedForAll(owner, operator);
    }

    function transferFrom(address from, address to, uint tokenId) public override(IERC721, ERC721A) whenEnabled {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint tokenId) public override(IERC721, ERC721A) whenEnabled {
        super.safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint tokenId, bytes calldata data) public override(IERC721, ERC721A) whenEnabled {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function adminBurn(uint tokenId) external override onlyAdmin whenEnabled {
        _burn(tokenId);
    }

    function adminTransfer(address from, address to, uint tokenId) external override whenEnabled {
        require(canAccessToken(msg.sender, tokenId), "ExtensibleERC721Enumerable: you are not allowed to perform this transfer");
        super.transferFrom(from, to, tokenId);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Enums.sol";
import "./Rarities.sol";
import "./Rng.sol";
import "./ChainScoutMetadata.sol";

library Generator {
    using RngLibrary for Rng;

    function getRandom(
        Rng memory rng,
        uint256 raritySum,
        uint16[] memory rarities
    ) internal view returns (uint256) {
        uint256 rn = rng.generate(0, raritySum - 1);

        for (uint256 i = 0; i < rarities.length; ++i) {
            if (rarities[i] > rn) {
                return i;
            }
            rn -= rarities[i];
        }
        revert("rn not selected");
    }

    function makeRandomClass(Rng memory rn)
        internal
        view
        returns (BackAccessory)
    {
        uint256 r = rn.generate(1, 100);

        if (r <= 2) {
            return BackAccessory.NETRUNNER;
        } else if (r <= 15) {
            return BackAccessory.MERCENARY;
        } else if (r <= 23) {
            return BackAccessory.RONIN;
        } else if (r <= 27) {
            return BackAccessory.ENCHANTER;
        } else if (r <= 38) {
            return BackAccessory.VANGUARD;
        } else if (r <= 45) {
            return BackAccessory.MINER;
        } else if (r <= 50) {
            return BackAccessory.PATHFINDER;
        } else {
            return BackAccessory.SCOUT;
        }
    }

    function getAttack(Rng memory rn, BackAccessory sc)
        internal
        view
        returns (uint256)
    {
        if (sc == BackAccessory.SCOUT) {
            return rn.generate(1785, 2415);
        } else if (sc == BackAccessory.VANGUARD) {
            return rn.generate(1105, 1495);
        } else if (sc == BackAccessory.RONIN || sc == BackAccessory.ENCHANTER) {
            return rn.generate(2805, 3795);
        } else if (sc == BackAccessory.MINER) {
            return rn.generate(1615, 2185);
        } else if (sc == BackAccessory.NETRUNNER) {
            return rn.generate(3740, 5060);
        } else {
            return rn.generate(2125, 2875);
        }
    }

    function getDefense(Rng memory rn, BackAccessory sc)
        internal
        view
        returns (uint256)
    {
        if (sc == BackAccessory.SCOUT || sc == BackAccessory.NETRUNNER) {
            return rn.generate(1785, 2415);
        } else if (sc == BackAccessory.VANGUARD) {
            return rn.generate(4250, 5750);
        } else if (sc == BackAccessory.RONIN) {
            return rn.generate(1530, 2070);
        } else if (sc == BackAccessory.MINER) {
            return rn.generate(1615, 2185);
        } else if (sc == BackAccessory.ENCHANTER) {
            return rn.generate(2805, 3795);
        } else if (sc == BackAccessory.NETRUNNER) {
            return rn.generate(3740, 5060);
        } else {
            return rn.generate(2125, 2875);
        }
    }

    function exclude(uint trait, uint idx, uint16[][] memory rarities, uint16[] memory limits) internal pure {
        limits[trait] -= rarities[trait][idx];
        rarities[trait][idx] = 0;
    }

    function getRandomMetadata(Rng memory rng)
        external 
        view
        returns (ChainScoutMetadata memory ret, Rng memory rn)
    {
        uint16[][] memory rarities = new uint16[][](8);
        rarities[0] = Rarities.accessory();
        rarities[1] = Rarities.backaccessory();
        rarities[2] = Rarities.background();
        rarities[3] = Rarities.clothing();
        rarities[4] = Rarities.eyes();
        rarities[5] = Rarities.fur();
        rarities[6] = Rarities.head();
        rarities[7] = Rarities.mouth();

        uint16[] memory limits = new uint16[](rarities.length);
        for (uint i = 0; i < limits.length; ++i) {
            limits[i] = 10000;
        }

        // excluded traits are less likely than advertised because if an excluding trait is selected, the excluded trait's chance drops to 0%
        // one alternative is a while loop that will use wildly varying amounts of gas, which is unacceptable
        // another alternative is to boost the chance of excluded traits proportionally to the chance that they get excluded, but this will cause the excluded traits to be disproportionately likely in the event that they are not excluded
        ret.accessory = Accessory(getRandom(rng, limits[0], rarities[0]));
        if (
            ret.accessory == Accessory.AMULET ||
            ret.accessory == Accessory.CUBAN_LINK_GOLD_CHAIN ||
            ret.accessory == Accessory.FANNY_PACK ||
            ret.accessory == Accessory.GOLDEN_CHAIN
        ) {
            exclude(3, uint(Clothing.FLEET_UNIFORM__BLUE), rarities, limits);
            exclude(3, uint(Clothing.FLEET_UNIFORM__RED), rarities, limits);

            if (ret.accessory == Accessory.CUBAN_LINK_GOLD_CHAIN) {
                exclude(1, uint(BackAccessory.MINER), rarities, limits);
            }
        }
        else if (ret.accessory == Accessory.GOLD_EARRINGS) {
            exclude(6, uint(Head.CYBER_HELMET__BLUE), rarities, limits);
            exclude(6, uint(Head.CYBER_HELMET__RED), rarities, limits);
            exclude(6, uint(Head.SPACESUIT_HELMET), rarities, limits);
        }

        ret.backaccessory = BackAccessory(getRandom(rng, limits[1], rarities[1]));
        if (ret.backaccessory == BackAccessory.PATHFINDER) {
            exclude(6, uint(Head.ENERGY_FIELD), rarities, limits);
        }

        ret.background = Background(getRandom(rng, limits[2], rarities[2]));
        if (ret.background == Background.CITY__PURPLE) {
            exclude(3, uint(Clothing.FLEET_UNIFORM__BLUE), rarities, limits);
            exclude(3, uint(Clothing.MARTIAL_SUIT), rarities, limits);
            exclude(3, uint(Clothing.THUNDERDOME_ARMOR), rarities, limits);
            exclude(6, uint(Head.ENERGY_FIELD), rarities, limits);
        }
        else if (ret.background == Background.CITY__RED) {
            exclude(6, uint(Head.ENERGY_FIELD), rarities, limits);
        }

        ret.clothing = Clothing(getRandom(rng, limits[3], rarities[3]));
        if (ret.clothing == Clothing.FLEET_UNIFORM__BLUE || ret.clothing == Clothing.FLEET_UNIFORM__RED) {
            exclude(7, uint(Mouth.CHROME_RESPIRATOR), rarities, limits);
            exclude(7, uint(Mouth.GREEN_RESPIRATOR), rarities, limits);
            exclude(7, uint(Mouth.MAGENTA_RESPIRATOR), rarities, limits);
            exclude(7, uint(Mouth.NAVY_RESPIRATOR), rarities, limits);
            exclude(7, uint(Mouth.RED_RESPIRATOR), rarities, limits);
        }

        ret.eyes = Eyes(getRandom(rng, limits[4], rarities[4]));
        if (ret.eyes == Eyes.BLUE_LASER || ret.eyes == Eyes.RED_LASER) {
            exclude(6, uint(Head.BANDANA), rarities, limits);
            exclude(6, uint(Head.CYBER_HELMET__BLUE), rarities, limits);
            exclude(6, uint(Head.CYBER_HELMET__RED), rarities, limits);
            exclude(6, uint(Head.DORAG), rarities, limits);
            exclude(6, uint(Head.SPACESUIT_HELMET), rarities, limits);
            exclude(7, uint(Mouth.BANANA), rarities, limits);
            exclude(7, uint(Mouth.CHROME_RESPIRATOR), rarities, limits);
            exclude(7, uint(Mouth.GREEN_RESPIRATOR), rarities, limits);
            exclude(7, uint(Mouth.MAGENTA_RESPIRATOR), rarities, limits);
            exclude(7, uint(Mouth.MASK), rarities, limits);
            exclude(7, uint(Mouth.MEMPO), rarities, limits);
            exclude(7, uint(Mouth.NAVY_RESPIRATOR), rarities, limits);
            exclude(7, uint(Mouth.PILOT_OXYGEN_MASK), rarities, limits);
            exclude(7, uint(Mouth.RED_RESPIRATOR), rarities, limits);
        }
        else if (ret.eyes == Eyes.BLUE_SHADES || ret.eyes == Eyes.DARK_SUNGLASSES || ret.eyes == Eyes.GOLDEN_SHADES) {
            exclude(6, uint(Head.SPACESUIT_HELMET), rarities, limits);
            exclude(7, uint(Mouth.CHROME_RESPIRATOR), rarities, limits);
            exclude(7, uint(Mouth.GREEN_RESPIRATOR), rarities, limits);
            exclude(7, uint(Mouth.MAGENTA_RESPIRATOR), rarities, limits);
            exclude(7, uint(Mouth.MASK), rarities, limits);
            exclude(7, uint(Mouth.NAVY_RESPIRATOR), rarities, limits);
            exclude(7, uint(Mouth.RED_RESPIRATOR), rarities, limits);
        }
        else if (ret.eyes == Eyes.HUD_GLASSES || ret.eyes == Eyes.HIVE_GOGGLES || ret.eyes == Eyes.WHITE_SUNGLASSES) {
            exclude(6, uint(Head.DORAG), rarities, limits);
            exclude(6, uint(Head.HEADBAND), rarities, limits);
            exclude(6, uint(Head.SPACESUIT_HELMET), rarities, limits);
        }
        else if (ret.eyes == Eyes.HAPPY) {
            exclude(6, uint(Head.CAP), rarities, limits);
            exclude(6, uint(Head.LEATHER_COWBOY_HAT), rarities, limits);
            exclude(6, uint(Head.PURPLE_COWBOY_HAT), rarities, limits);
        }
        else if (ret.eyes == Eyes.HIPSTER_GLASSES) {
            exclude(6, uint(Head.BANDANA), rarities, limits);
            exclude(6, uint(Head.CYBER_HELMET__BLUE), rarities, limits);
            exclude(6, uint(Head.CYBER_HELMET__RED), rarities, limits);
            exclude(6, uint(Head.DORAG), rarities, limits);
            exclude(6, uint(Head.HEADBAND), rarities, limits);
            exclude(6, uint(Head.SPACESUIT_HELMET), rarities, limits);
            exclude(7, uint(Mouth.CHROME_RESPIRATOR), rarities, limits);
            exclude(7, uint(Mouth.GREEN_RESPIRATOR), rarities, limits);
            exclude(7, uint(Mouth.MAGENTA_RESPIRATOR), rarities, limits);
            exclude(7, uint(Mouth.MASK), rarities, limits);
            exclude(7, uint(Mouth.MEMPO), rarities, limits);
            exclude(7, uint(Mouth.NAVY_RESPIRATOR), rarities, limits);
            exclude(7, uint(Mouth.RED_RESPIRATOR), rarities, limits);
        }
        else if (ret.eyes == Eyes.MATRIX_GLASSES || ret.eyes == Eyes.NIGHT_VISION_GOGGLES || ret.eyes == Eyes.SUNGLASSES) {
            exclude(6, uint(Head.SPACESUIT_HELMET), rarities, limits);
        }
        else if (ret.eyes == Eyes.NOUNS_GLASSES) {
            exclude(6, uint(Head.BANDANA), rarities, limits);
            exclude(6, uint(Head.DORAG), rarities, limits);
            exclude(6, uint(Head.HEADBAND), rarities, limits);
            exclude(6, uint(Head.SPACESUIT_HELMET), rarities, limits);
            exclude(7, uint(Mouth.CHROME_RESPIRATOR), rarities, limits);
            exclude(7, uint(Mouth.GREEN_RESPIRATOR), rarities, limits);
            exclude(7, uint(Mouth.MAGENTA_RESPIRATOR), rarities, limits);
            exclude(7, uint(Mouth.MASK), rarities, limits);
            exclude(7, uint(Mouth.MEMPO), rarities, limits);
            exclude(7, uint(Mouth.NAVY_RESPIRATOR), rarities, limits);
            exclude(7, uint(Mouth.PILOT_OXYGEN_MASK), rarities, limits);
            exclude(7, uint(Mouth.RED_RESPIRATOR), rarities, limits);
        }
        else if (ret.eyes == Eyes.PINCENEZ) {
            exclude(6, uint(Head.SPACESUIT_HELMET), rarities, limits);
            exclude(7, uint(Mouth.MASK), rarities, limits);
            exclude(7, uint(Mouth.MEMPO), rarities, limits);
        }
        else if (ret.eyes == Eyes.SPACE_VISOR) {
            exclude(6, uint(Head.DORAG), rarities, limits);
            exclude(6, uint(Head.HEADBAND), rarities, limits);
            exclude(6, uint(Head.SPACESUIT_HELMET), rarities, limits);
            exclude(7, uint(Mouth.CHROME_RESPIRATOR), rarities, limits);
            exclude(7, uint(Mouth.GREEN_RESPIRATOR), rarities, limits);
            exclude(7, uint(Mouth.MAGENTA_RESPIRATOR), rarities, limits);
            exclude(7, uint(Mouth.MEMPO), rarities, limits);
            exclude(7, uint(Mouth.NAVY_RESPIRATOR), rarities, limits);
            exclude(7, uint(Mouth.RED_RESPIRATOR), rarities, limits);
        }

        ret.fur = Fur(getRandom(rng, limits[5], rarities[5]));

        ret.head = Head(getRandom(rng, limits[6], rarities[6]));

        if (ret.head == Head.BANDANA || ret.head == Head.DORAG) {
            exclude(7, uint(Mouth.CHROME_RESPIRATOR), rarities, limits);
            exclude(7, uint(Mouth.GREEN_RESPIRATOR), rarities, limits);
            exclude(7, uint(Mouth.MAGENTA_RESPIRATOR), rarities, limits);
            exclude(7, uint(Mouth.NAVY_RESPIRATOR), rarities, limits);
            exclude(7, uint(Mouth.RED_RESPIRATOR), rarities, limits);
        }
        else if (ret.head == Head.CYBER_HELMET__BLUE || ret.head == Head.CYBER_HELMET__RED || ret.head == Head.SPACESUIT_HELMET) {
            exclude(7, uint(Mouth.BANANA), rarities, limits);
            exclude(7, uint(Mouth.CHROME_RESPIRATOR), rarities, limits);
            exclude(7, uint(Mouth.CIGAR), rarities, limits);
            exclude(7, uint(Mouth.GREEN_RESPIRATOR), rarities, limits);
            exclude(7, uint(Mouth.MAGENTA_RESPIRATOR), rarities, limits);
            exclude(7, uint(Mouth.MEMPO), rarities, limits);
            exclude(7, uint(Mouth.NAVY_RESPIRATOR), rarities, limits);
            exclude(7, uint(Mouth.PILOT_OXYGEN_MASK), rarities, limits);
            exclude(7, uint(Mouth.PIPE), rarities, limits);
            exclude(7, uint(Mouth.RED_RESPIRATOR), rarities, limits);
            exclude(7, uint(Mouth.VAPE), rarities, limits);
        }
        // not else. spacesuit helmet includes the above
        if (ret.head == Head.SPACESUIT_HELMET) {
            exclude(7, uint(Mouth.MASK), rarities, limits);
        }

        ret.mouth = Mouth(getRandom(rng, limits[7], rarities[7]));

        ret.attack = uint16(getAttack(rng, ret.backaccessory));
        ret.defense = uint16(getDefense(rng, ret.backaccessory));
        ret.luck = uint16(rng.generate(500, 5000));
        ret.speed = uint16(rng.generate(500, 5000));
        ret.strength = uint16(rng.generate(500, 5000));
        ret.intelligence = uint16(rng.generate(500, 5000));
        ret.level = 1;

        rn = rng;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IExtensibleERC721Enumerable.sol";
import "./ChainScoutsExtension.sol";
import "./ChainScoutMetadata.sol";

interface IChainScouts is IExtensibleERC721Enumerable {
    function adminCreateChainScout(
        ChainScoutMetadata calldata tbd,
        address owner
    ) external;

    function adminRemoveExtension(string calldata key) external;

    function adminSetExtension(
        string calldata key,
        ChainScoutsExtension extension
    ) external;

    function adminSetChainScoutMetadata(
        uint256 tokenId,
        ChainScoutMetadata calldata tbd
    ) external;

    function getChainScoutMetadata(uint256 tokenId)
        external
        view
        returns (ChainScoutMetadata memory);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IUtilityERC20 is IERC20 {
    function adminMint(address owner, uint amountWei) external;

    function adminSetTokenTimestamp(uint tokenId, uint timestamp) external;

    function burn(address owner, uint amountWei) external;

    function claimRewards() external;

    function stake(uint[] calldata tokenId) external;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ExtensibleERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

enum MintingState {
    NOT_ALLOWED,
    WHITELIST_ONLY,
    PUBLIC
}

struct Payee {
    address payable addr;
    uint16 ratio;
}

abstract contract MerkleWhitelistERC721Enumerable is ExtensibleERC721Enumerable {
    mapping (address => uint) public whitelistMintsUsed;
    MintingState public mintingState = MintingState.NOT_ALLOWED;
    uint public maxMintPerTx;
    uint public maxSupply;
    uint public maxWhitelistMints;
    bytes32 internal root;
    address payable[] internal payeeAddresses;
    uint16[] internal payeeRatios;
    uint internal totalRatio;

    event MintingStateChanged(MintingState oldState, MintingState newState);

    constructor(Payee[] memory _payees, uint _maxMintPerTx, uint _maxSupply, uint _maxWhitelistMints, bytes32 _root) {
        maxMintPerTx = _maxMintPerTx;
        maxSupply = _maxSupply;
        maxWhitelistMints = _maxWhitelistMints;
        root = _root;
        payeeAddresses = new address payable[](_payees.length);
        payeeRatios = new uint16[](_payees.length);

        for (uint i = 0; i < _payees.length; ++i) {
            payeeAddresses[i] = _payees[i].addr;
            payeeRatios[i] = _payees[i].ratio;
            totalRatio += _payees[i].ratio;
        }
        if (totalRatio == 0) {
            revert("Total payee ratio must be > 0");
        }
    }

    function adminSetMaxPerTx(uint max) external onlyAdmin {
        maxMintPerTx = max;
    }

    /*
    function adminSetMaxSupply(uint max) external onlyAdmin {
        maxSupply = max;
    }
    */

    function adminSetMintingState(MintingState ms) external onlyAdmin {
        emit MintingStateChanged(mintingState, ms);
        mintingState = ms;
    }

    function adminSetMaxWhitelistMints(uint max) external onlyAdmin {
        maxWhitelistMints = max;
    }

    function adminSetMerkleRoot(bytes32 _root) external onlyAdmin {
        root = _root;
    }

    function isWhitelisted(bytes32[] calldata proof, address addr) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(addr));
        return MerkleProof.verify(proof, root, leaf);
    }

    function distributeFunds() internal virtual {
        address payable[] memory a = payeeAddresses;
        uint16[] memory r = payeeRatios;

        uint origValue = msg.value;
        uint remainingValue = msg.value;

        for (uint i = 0; i < a.length - 1; ++i) {
            uint amount = origValue * r[i] / totalRatio;
            Address.sendValue(a[i], amount);
            remainingValue -= amount;
        }
        Address.sendValue(a[a.length - 1], remainingValue);
    }

    function createMetadataForMintedToken(uint tokenId) internal virtual;

    function mintPriceWei() public view virtual returns (uint);

    function whitelistMint(bytes32[] calldata proof, uint count) public payable returns (uint) {
        require(mintingState == MintingState.WHITELIST_ONLY, "Whitelist minting is not allowed atm");
        require(isWhitelisted(proof, msg.sender), "Bad whitelist proof");
        require(maxWhitelistMints - whitelistMintsUsed[msg.sender] >= count, "Not enough whitelisted mints");
        whitelistMintsUsed[msg.sender] += count;

        return internalMint(count);
    }

    function publicMint(uint count) public payable returns (uint) {
        if (!isAdmin[msg.sender]) {
            require(mintingState == MintingState.PUBLIC, "Public minting is not allowed atm");
            require(count <= maxMintPerTx, "Cannot mint more than maxMintPerTx()");
        }
        return internalMint(count);
    }

    function internalMint(uint count) internal whenEnabled returns (uint) {
        if (!isAdmin[msg.sender]) {
            require(count >= 1, "Must mint at least one");
            require(!Address.isContract(msg.sender), "Contracts cannot mint");
            require(msg.value == count * mintPriceWei(), "Send mintPriceWei() wei for each mint");
        }

        uint supply = totalSupply();
        require(supply + count <= maxSupply, "Cannot mint over maxSupply()");

        uint startingIndex = _currentIndex;

        for (uint i = startingIndex; i < startingIndex + count; ++i) {
            createMetadataForMintedToken(i);
        }
        _mint(msg.sender, count, "", false);

        distributeFunds();

        return startingIndex;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title A pseudo random number generator
 *
 * @dev This is not a true random number generator because smart contracts must be deterministic (every node a transaction goes to must produce the same result).
 *      True randomness requires an oracle which is both expensive in terms of gas and would take a critical part of the project off the chain.
 */
struct Rng {
    bytes32 state;
}

/**
 * @title A library for working with the Rng struct.
 *
 * @dev Rng cannot be a contract because then anyone could manipulate it by generating random numbers.
 */
library RngLibrary {
    /**
     * Creates a new Rng.
     */
    function newRng() internal view returns (Rng memory) {
        return Rng(getEntropy());
    }

    /**
     * Creates a pseudo-random value from the current block miner's address and sender.
     */
    function getEntropy() internal view returns (bytes32) {
        return keccak256(abi.encodePacked(block.coinbase, msg.sender));
    }

    /**
     * Generates a random uint256.
     */
    function generate(Rng memory self) internal view returns (uint256) {
        self.state = keccak256(abi.encodePacked(getEntropy(), self.state));
        return uint256(self.state);
    }

    /**
     * Generates a random uint256 from min to max inclusive.
     *
     * @dev This function is not subject to modulo bias.
     *      The chance that this function has to reroll is astronomically unlikely, but it can theoretically reroll forever.
     */
    function generate(Rng memory self, uint min, uint max) internal view returns (uint256) {
        require(min <= max, "min > max");

        uint delta = max - min;

        if (delta == 0) {
            return min;
        }

        return generate(self) % (delta + 1) + min;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITokenURIProvider {
    function tokenURI(uint tokenId) external view returns (string memory);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Base64.sol";
import "./Integer.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

enum NumericAttributeType {
    NUMBER,
    BOOST_PERCENTAGE,
    BOOST_NUMBER,
    DATE
}

struct Attribute {
    string displayType;
    string key;
    string serializedValue;
    string maxValue;
}

struct OpenSeaMetadata {
    string svg;
    string description;
    string name;
    uint24 backgroundColor;
    Attribute[] attributes;
}

library OpenSeaMetadataLibrary {
    using Strings for uint;

    struct ObjectKeyValuePair {
        string key;
        string serializedValue;
    }

    function uintToColorString(uint value, uint nBytes) internal pure returns (string memory) {
        bytes memory symbols = "0123456789ABCDEF";
        bytes memory buf = new bytes(nBytes * 2);

        for (uint i = 0; i < nBytes * 2; ++i) {
            buf[nBytes * 2 - 1 - i] = symbols[Integer.bitsFrom(value, (i * 4) + 3, i * 4)];
        }

        return string(buf);
    }

    function quote(string memory str) internal pure returns (string memory output) {
        return bytes(str).length > 0 ? string(abi.encodePacked(
            '"',
            str,
            '"'
        )) : "";
    }

    function makeStringAttribute(string memory key, string memory value) internal pure returns (Attribute memory) {
        return Attribute("", key, quote(value), "");
    }

    function makeNumericAttribute(NumericAttributeType nat, string memory key, string memory value, string memory maxValue) private pure returns (Attribute memory) {
        string memory s = "number";
        if (nat == NumericAttributeType.BOOST_PERCENTAGE) {
            s = "boost_percentage";
        }
        else if (nat == NumericAttributeType.BOOST_NUMBER) {
            s = "boost_number";
        }
        else if (nat == NumericAttributeType.DATE) {
            s = "date";
        }

        return Attribute(s, key, value, maxValue);
    }

    function makeFixedPoint(uint value, uint decimals) internal pure returns (string memory) {
        bytes memory st = bytes(value.toString());

        while (st.length < decimals) {
            st = abi.encodePacked(
                "0",
                st
            );
        }

        bytes memory ret = new bytes(st.length + 1);

        if (decimals >= st.length) {
            return string(abi.encodePacked("0.", st));
        }

        uint dl = st.length - decimals;

        uint i = 0;
        uint j = 0;

        while (i < ret.length) {
            if (i == dl) {
                ret[i] = '.';
                i++;
                continue;
            }

            ret[i] = st[j];

            i++;
            j++;
        }

        return string(ret);
    }

    function makeFixedPointAttribute(NumericAttributeType nat, string memory key, uint value, uint maxValue, uint decimals) internal pure returns (Attribute memory) {
        return makeNumericAttribute(nat, key, makeFixedPoint(value, decimals), maxValue == 0 ? "" : makeFixedPoint(maxValue, decimals));
    }

    function makeUintAttribute(NumericAttributeType nat, string memory key, uint value, uint maxValue) internal pure returns (Attribute memory) {
        return makeNumericAttribute(nat, key, value.toString(), maxValue == 0 ? "" : maxValue.toString());
    }

    function makeBooleanAttribute(string memory key, bool value) internal pure returns (Attribute memory) {
        return Attribute("", key, value ? "true" : "false", "");
    }

    function makeAttributesArray(Attribute[] memory attributes) internal pure returns (string memory output) {
        output = "[";
        bool empty = true;

        for (uint i = 0; i < attributes.length; ++i) {
            if (bytes(attributes[i].serializedValue).length > 0) {
                ObjectKeyValuePair[] memory kvps = new ObjectKeyValuePair[](4);
                kvps[0] = ObjectKeyValuePair("trait_type", quote(attributes[i].key));
                kvps[1] = ObjectKeyValuePair("display_type", quote(attributes[i].displayType));
                kvps[2] = ObjectKeyValuePair("value", attributes[i].serializedValue);
                kvps[3] = ObjectKeyValuePair("max_value", attributes[i].maxValue);

                output = string(abi.encodePacked(
                    output,
                    empty ? "" : ",",
                    makeObject(kvps)
                ));
                empty = false;
            }
        }

        output = string(abi.encodePacked(output, "]"));
    }

    function notEmpty(string memory s) internal pure returns (bool) {
        return bytes(s).length > 0;
    }

    function makeObject(ObjectKeyValuePair[] memory kvps) internal pure returns (string memory output) {
        output = "{";
        bool empty = true;

        for (uint i = 0; i < kvps.length; ++i) {
            if (bytes(kvps[i].serializedValue).length > 0) {
                output = string(abi.encodePacked(
                    output,
                    empty ? "" : ",",
                    '"',
                    kvps[i].key,
                    '":',
                    kvps[i].serializedValue
                ));
                empty = false;
            }
        }

        output = string(abi.encodePacked(output, "}"));
    }

    function makeMetadataWithExtraKvps(OpenSeaMetadata memory metadata, ObjectKeyValuePair[] memory extra) internal pure returns (string memory output) {
        /*
        string memory svgUrl = string(abi.encodePacked(
            "data:image/svg+xml;base64,",
            string(Base64.encode(bytes(metadata.svg)))
        ));
        */

        string memory svgUrl = string(abi.encodePacked(
            "data:image/svg+xml;utf8,",
            metadata.svg
        ));

        ObjectKeyValuePair[] memory kvps = new ObjectKeyValuePair[](5 + extra.length);
        kvps[0] = ObjectKeyValuePair("name", quote(metadata.name));
        kvps[1] = ObjectKeyValuePair("description", quote(metadata.description));
        kvps[2] = ObjectKeyValuePair("image", quote(svgUrl));
        kvps[3] = ObjectKeyValuePair("background_color", quote(uintToColorString(metadata.backgroundColor, 3)));
        kvps[4] = ObjectKeyValuePair("attributes", makeAttributesArray(metadata.attributes));
        for (uint i = 0; i < extra.length; ++i) {
            kvps[i + 5] = extra[i];
        }

        return string(abi.encodePacked(
            "data:application/json;base64,",
            Base64.encode(bytes(makeObject(kvps)))
        ));
    }

    function makeMetadata(OpenSeaMetadata memory metadata) internal pure returns (string memory output) {
        return makeMetadataWithExtraKvps(metadata, new ObjectKeyValuePair[](0));
    }

    function makeERC1155Metadata(OpenSeaMetadata memory metadata, string memory symbol) internal pure returns (string memory output) {
        ObjectKeyValuePair[] memory kvps = new ObjectKeyValuePair[](1);
        kvps[0] = ObjectKeyValuePair("symbol", quote(symbol));
        return makeMetadataWithExtraKvps(metadata, kvps);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IChainScouts.sol";

abstract contract ChainScoutsExtension {
    IChainScouts internal chainScouts;
    bool public enabled = true;

    modifier canAccessToken(uint tokenId) {
        require(chainScouts.canAccessToken(msg.sender, tokenId), "ChainScoutsExtension: you don't own the token");
        _;
    }

    modifier onlyAdmin() {
        require(chainScouts.isAdmin(msg.sender), "ChainScoutsExtension: admins only");
        _;
    }

    modifier whenEnabled() {
        require(enabled, "ChainScoutsExtension: currently disabled");
        _;
    }

    function adminSetEnabled(bool e) external onlyAdmin {
        enabled = e;
    }

    function extensionKey() public virtual view returns (string memory);

    function setChainScouts(IChainScouts _contract) external {
        require(address(0) == address(chainScouts) || chainScouts.isAdmin(msg.sender), "ChainScoutsExtension: The Chain Scouts contract must not be set or you must be an admin");
        chainScouts = _contract;
        chainScouts.adminSetExtension(extensionKey(), this);
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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// shamelessly stolen from the anonymice contract
library Base64 {
    string internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /**
     * @dev Converts the input data into a base64 string.
     */
    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

        // load the table into memory
        string memory table = TABLE;

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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Integer {
    /**
     * @dev Gets the bit at the given position in the given integer.
     *      255 is the leftmost bit, 0 is the rightmost bit.
     *
     *      For example: bitAt(2, 0) == 0, because the rightmost bit of 10 is 0
     *                   bitAt(2, 1) == 1, because the second to last bit of 10 is 1
     */
    function bitAt(uint integer, uint pos) internal pure returns (uint) {
        require(pos <= 255, "pos > 255");

        return (integer & (1 << pos)) >> pos;
    }

    function setBitAt(uint integer, uint pos) internal pure returns (uint) {
        return integer | (1 << pos);
    }

    /**
     * @dev Gets the value of the bits between left and right, both inclusive, in the given integer.
     *      255 is the leftmost bit, 0 is the rightmost bit.
     *      
     *      For example: bitsFrom(10, 3, 1) == 7 (101 in binary), because 10 is *101*0 in binary
     *                   bitsFrom(10, 2, 0) == 2 (010 in binary), because 10 is 1*010* in binary
     */
    function bitsFrom(uint integer, uint left, uint right) internal pure returns (uint) {
        require(left >= right, "left > right");
        require(left <= 255, "left > 255");

        uint delta = left - right + 1;

        return (integer & (((1 << delta) - 1) << right)) >> right;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

interface IExtensibleERC721Enumerable is IERC721Enumerable {
    function isAdmin(address addr) external view returns (bool);

    function addAdmin(address addr) external;

    function removeAdmin(address addr) external;

    function canAccessToken(address addr, uint tokenId) external view returns (bool);

    function adminBurn(uint tokenId) external;

    function adminTransfer(address from, address to, uint tokenId) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

enum Accessory {
    GOLD_EARRINGS,
    SCARS,
    GOLDEN_CHAIN,
    AMULET,
    CUBAN_LINK_GOLD_CHAIN,
    FANNY_PACK,
    NONE
}

enum BackAccessory {
    NETRUNNER,
    MERCENARY,
    RONIN,
    ENCHANTER,
    VANGUARD,
    MINER,
    PATHFINDER,
    SCOUT
}

enum Background {
    STARRY_PINK,
    STARRY_YELLOW,
    STARRY_PURPLE,
    STARRY_GREEN,
    NEBULA,
    STARRY_RED,
    STARRY_BLUE,
    SUNSET,
    MORNING,
    INDIGO,
    CITY__PURPLE,
    CONTROL_ROOM,
    LAB,
    GREEN,
    ORANGE,
    PURPLE,
    CITY__GREEN,
    CITY__RED,
    STATION,
    BOUNTY,
    BLUE_SKY,
    RED_SKY,
    GREEN_SKY
}

enum Clothing {
    MARTIAL_SUIT,
    AMETHYST_ARMOR,
    SHIRT_AND_TIE,
    THUNDERDOME_ARMOR,
    FLEET_UNIFORM__BLUE,
    BANANITE_SHIRT,
    EXPLORER,
    COSMIC_GHILLIE_SUIT__BLUE,
    COSMIC_GHILLIE_SUIT__GOLD,
    CYBER_JUMPSUIT,
    ENCHANTER_ROBES,
    HOODIE,
    SPACESUIT,
    MECHA_ARMOR,
    LAB_COAT,
    FLEET_UNIFORM__RED,
    GOLD_ARMOR,
    ENERGY_ARMOR__BLUE,
    ENERGY_ARMOR__RED,
    MISSION_SUIT__BLACK,
    MISSION_SUIT__PURPLE,
    COWBOY,
    GLITCH_ARMOR,
    NONE
}

enum Eyes {
    SPACE_VISOR,
    ADORABLE,
    VETERAN,
    SUNGLASSES,
    WHITE_SUNGLASSES,
    RED_EYES,
    WINK,
    CASUAL,
    CLOSED,
    DOWNCAST,
    HAPPY,
    BLUE_EYES,
    HUD_GLASSES,
    DARK_SUNGLASSES,
    NIGHT_VISION_GOGGLES,
    BIONIC,
    HIVE_GOGGLES,
    MATRIX_GLASSES,
    GREEN_GLOW,
    ORANGE_GLOW,
    RED_GLOW,
    PURPLE_GLOW,
    BLUE_GLOW,
    SKY_GLOW,
    RED_LASER,
    BLUE_LASER,
    GOLDEN_SHADES,
    HIPSTER_GLASSES,
    PINCENEZ,
    BLUE_SHADES,
    BLIT_GLASSES,
    NOUNS_GLASSES
}

enum Fur {
    MAGENTA,
    BLUE,
    GREEN,
    RED,
    BLACK,
    BROWN,
    SILVER,
    PURPLE,
    PINK,
    SEANCE,
    TURQUOISE,
    CRIMSON,
    GREENYELLOW,
    GOLD,
    DIAMOND,
    METALLIC
}

enum Head {
    HALO,
    ENERGY_FIELD,
    BLUE_TOP_HAT,
    RED_TOP_HAT,
    ENERGY_CRYSTAL,
    CROWN,
    BANDANA,
    BUCKET_HAT,
    HOMBURG_HAT,
    PROPELLER_HAT,
    HEADBAND,
    DORAG,
    PURPLE_COWBOY_HAT,
    SPACESUIT_HELMET,
    PARTY_HAT,
    CAP,
    LEATHER_COWBOY_HAT,
    CYBER_HELMET__BLUE,
    CYBER_HELMET__RED,
    SAMURAI_HAT,
    NONE
}

enum Mouth {
    SMIRK,
    SURPRISED,
    SMILE,
    PIPE,
    OPEN_SMILE,
    NEUTRAL,
    MASK,
    TONGUE_OUT,
    GOLD_GRILL,
    DIAMOND_GRILL,
    NAVY_RESPIRATOR,
    RED_RESPIRATOR,
    MAGENTA_RESPIRATOR,
    GREEN_RESPIRATOR,
    MEMPO,
    VAPE,
    PILOT_OXYGEN_MASK,
    CIGAR,
    BANANA,
    CHROME_RESPIRATOR,
    STOIC
}

library Enums {
    function toString(Accessory v) external pure returns (string memory) {
        if (v == Accessory.GOLD_EARRINGS) {
            return "Gold Earrings";
        }

        if (v == Accessory.SCARS) {
            return "Scars";
        }

        if (v == Accessory.GOLDEN_CHAIN) {
            return "Golden Chain";
        }

        if (v == Accessory.AMULET) {
            return "Amulet";
        }

        if (v == Accessory.CUBAN_LINK_GOLD_CHAIN) {
            return "Cuban Link Gold Chain";
        }

        if (v == Accessory.FANNY_PACK) {
            return "Fanny Pack";
        }

        if (v == Accessory.NONE) {
            return "None";
        }
        revert("invalid accessory");
    }

    function toString(BackAccessory v) external pure returns (string memory) {
        if (v == BackAccessory.NETRUNNER) {
            return "Netrunner";
        }

        if (v == BackAccessory.MERCENARY) {
            return "Mercenary";
        }

        if (v == BackAccessory.RONIN) {
            return "Ronin";
        }

        if (v == BackAccessory.ENCHANTER) {
            return "Enchanter";
        }

        if (v == BackAccessory.VANGUARD) {
            return "Vanguard";
        }

        if (v == BackAccessory.MINER) {
            return "Miner";
        }

        if (v == BackAccessory.PATHFINDER) {
            return "Pathfinder";
        }

        if (v == BackAccessory.SCOUT) {
            return "Scout";
        }
        revert("invalid back accessory");
    }

    function toString(Background v) external pure returns (string memory) {
        if (v == Background.STARRY_PINK) {
            return "Starry Pink";
        }

        if (v == Background.STARRY_YELLOW) {
            return "Starry Yellow";
        }

        if (v == Background.STARRY_PURPLE) {
            return "Starry Purple";
        }

        if (v == Background.STARRY_GREEN) {
            return "Starry Green";
        }

        if (v == Background.NEBULA) {
            return "Nebula";
        }

        if (v == Background.STARRY_RED) {
            return "Starry Red";
        }

        if (v == Background.STARRY_BLUE) {
            return "Starry Blue";
        }

        if (v == Background.SUNSET) {
            return "Sunset";
        }

        if (v == Background.MORNING) {
            return "Morning";
        }

        if (v == Background.INDIGO) {
            return "Indigo";
        }

        if (v == Background.CITY__PURPLE) {
            return "City - Purple";
        }

        if (v == Background.CONTROL_ROOM) {
            return "Control Room";
        }

        if (v == Background.LAB) {
            return "Lab";
        }

        if (v == Background.GREEN) {
            return "Green";
        }

        if (v == Background.ORANGE) {
            return "Orange";
        }

        if (v == Background.PURPLE) {
            return "Purple";
        }

        if (v == Background.CITY__GREEN) {
            return "City - Green";
        }

        if (v == Background.CITY__RED) {
            return "City - Red";
        }

        if (v == Background.STATION) {
            return "Station";
        }

        if (v == Background.BOUNTY) {
            return "Bounty";
        }

        if (v == Background.BLUE_SKY) {
            return "Blue Sky";
        }

        if (v == Background.RED_SKY) {
            return "Red Sky";
        }

        if (v == Background.GREEN_SKY) {
            return "Green Sky";
        }
        revert("invalid background");
    }

    function toString(Clothing v) external pure returns (string memory) {
        if (v == Clothing.MARTIAL_SUIT) {
            return "Martial Suit";
        }

        if (v == Clothing.AMETHYST_ARMOR) {
            return "Amethyst Armor";
        }

        if (v == Clothing.SHIRT_AND_TIE) {
            return "Shirt and Tie";
        }

        if (v == Clothing.THUNDERDOME_ARMOR) {
            return "Thunderdome Armor";
        }

        if (v == Clothing.FLEET_UNIFORM__BLUE) {
            return "Fleet Uniform - Blue";
        }

        if (v == Clothing.BANANITE_SHIRT) {
            return "Bananite Shirt";
        }

        if (v == Clothing.EXPLORER) {
            return "Explorer";
        }

        if (v == Clothing.COSMIC_GHILLIE_SUIT__BLUE) {
            return "Cosmic Ghillie Suit - Blue";
        }

        if (v == Clothing.COSMIC_GHILLIE_SUIT__GOLD) {
            return "Cosmic Ghillie Suit - Gold";
        }

        if (v == Clothing.CYBER_JUMPSUIT) {
            return "Cyber Jumpsuit";
        }

        if (v == Clothing.ENCHANTER_ROBES) {
            return "Enchanter Robes";
        }

        if (v == Clothing.HOODIE) {
            return "Hoodie";
        }

        if (v == Clothing.SPACESUIT) {
            return "Spacesuit";
        }

        if (v == Clothing.MECHA_ARMOR) {
            return "Mecha Armor";
        }

        if (v == Clothing.LAB_COAT) {
            return "Lab Coat";
        }

        if (v == Clothing.FLEET_UNIFORM__RED) {
            return "Fleet Uniform - Red";
        }

        if (v == Clothing.GOLD_ARMOR) {
            return "Gold Armor";
        }

        if (v == Clothing.ENERGY_ARMOR__BLUE) {
            return "Energy Armor - Blue";
        }

        if (v == Clothing.ENERGY_ARMOR__RED) {
            return "Energy Armor - Red";
        }

        if (v == Clothing.MISSION_SUIT__BLACK) {
            return "Mission Suit - Black";
        }

        if (v == Clothing.MISSION_SUIT__PURPLE) {
            return "Mission Suit - Purple";
        }

        if (v == Clothing.COWBOY) {
            return "Cowboy";
        }

        if (v == Clothing.GLITCH_ARMOR) {
            return "Glitch Armor";
        }

        if (v == Clothing.NONE) {
            return "None";
        }
        revert("invalid clothing");
    }

    function toString(Eyes v) external pure returns (string memory) {
        if (v == Eyes.SPACE_VISOR) {
            return "Space Visor";
        }

        if (v == Eyes.ADORABLE) {
            return "Adorable";
        }

        if (v == Eyes.VETERAN) {
            return "Veteran";
        }

        if (v == Eyes.SUNGLASSES) {
            return "Sunglasses";
        }

        if (v == Eyes.WHITE_SUNGLASSES) {
            return "White Sunglasses";
        }

        if (v == Eyes.RED_EYES) {
            return "Red Eyes";
        }

        if (v == Eyes.WINK) {
            return "Wink";
        }

        if (v == Eyes.CASUAL) {
            return "Casual";
        }

        if (v == Eyes.CLOSED) {
            return "Closed";
        }

        if (v == Eyes.DOWNCAST) {
            return "Downcast";
        }

        if (v == Eyes.HAPPY) {
            return "Happy";
        }

        if (v == Eyes.BLUE_EYES) {
            return "Blue Eyes";
        }

        if (v == Eyes.HUD_GLASSES) {
            return "HUD Glasses";
        }

        if (v == Eyes.DARK_SUNGLASSES) {
            return "Dark Sunglasses";
        }

        if (v == Eyes.NIGHT_VISION_GOGGLES) {
            return "Night Vision Goggles";
        }

        if (v == Eyes.BIONIC) {
            return "Bionic";
        }

        if (v == Eyes.HIVE_GOGGLES) {
            return "Hive Goggles";
        }

        if (v == Eyes.MATRIX_GLASSES) {
            return "Matrix Glasses";
        }

        if (v == Eyes.GREEN_GLOW) {
            return "Green Glow";
        }

        if (v == Eyes.ORANGE_GLOW) {
            return "Orange Glow";
        }

        if (v == Eyes.RED_GLOW) {
            return "Red Glow";
        }

        if (v == Eyes.PURPLE_GLOW) {
            return "Purple Glow";
        }

        if (v == Eyes.BLUE_GLOW) {
            return "Blue Glow";
        }

        if (v == Eyes.SKY_GLOW) {
            return "Sky Glow";
        }

        if (v == Eyes.RED_LASER) {
            return "Red Laser";
        }

        if (v == Eyes.BLUE_LASER) {
            return "Blue Laser";
        }

        if (v == Eyes.GOLDEN_SHADES) {
            return "Golden Shades";
        }

        if (v == Eyes.HIPSTER_GLASSES) {
            return "Hipster Glasses";
        }

        if (v == Eyes.PINCENEZ) {
            return "Pince-nez";
        }

        if (v == Eyes.BLUE_SHADES) {
            return "Blue Shades";
        }

        if (v == Eyes.BLIT_GLASSES) {
            return "Blit GLasses";
        }

        if (v == Eyes.NOUNS_GLASSES) {
            return "Nouns Glasses";
        }
        revert("invalid eyes");
    }

    function toString(Fur v) external pure returns (string memory) {
        if (v == Fur.MAGENTA) {
            return "Magenta";
        }

        if (v == Fur.BLUE) {
            return "Blue";
        }

        if (v == Fur.GREEN) {
            return "Green";
        }

        if (v == Fur.RED) {
            return "Red";
        }

        if (v == Fur.BLACK) {
            return "Black";
        }

        if (v == Fur.BROWN) {
            return "Brown";
        }

        if (v == Fur.SILVER) {
            return "Silver";
        }

        if (v == Fur.PURPLE) {
            return "Purple";
        }

        if (v == Fur.PINK) {
            return "Pink";
        }

        if (v == Fur.SEANCE) {
            return "Seance";
        }

        if (v == Fur.TURQUOISE) {
            return "Turquoise";
        }

        if (v == Fur.CRIMSON) {
            return "Crimson";
        }

        if (v == Fur.GREENYELLOW) {
            return "Green-Yellow";
        }

        if (v == Fur.GOLD) {
            return "Gold";
        }

        if (v == Fur.DIAMOND) {
            return "Diamond";
        }

        if (v == Fur.METALLIC) {
            return "Metallic";
        }
        revert("invalid fur");
    }

    function toString(Head v) external pure returns (string memory) {
        if (v == Head.HALO) {
            return "Halo";
        }

        if (v == Head.ENERGY_FIELD) {
            return "Energy Field";
        }

        if (v == Head.BLUE_TOP_HAT) {
            return "Blue Top Hat";
        }

        if (v == Head.RED_TOP_HAT) {
            return "Red Top Hat";
        }

        if (v == Head.ENERGY_CRYSTAL) {
            return "Energy Crystal";
        }

        if (v == Head.CROWN) {
            return "Crown";
        }

        if (v == Head.BANDANA) {
            return "Bandana";
        }

        if (v == Head.BUCKET_HAT) {
            return "Bucket Hat";
        }

        if (v == Head.HOMBURG_HAT) {
            return "Homburg Hat";
        }

        if (v == Head.PROPELLER_HAT) {
            return "Propeller Hat";
        }

        if (v == Head.HEADBAND) {
            return "Headband";
        }

        if (v == Head.DORAG) {
            return "Do-rag";
        }

        if (v == Head.PURPLE_COWBOY_HAT) {
            return "Purple Cowboy Hat";
        }

        if (v == Head.SPACESUIT_HELMET) {
            return "Spacesuit Helmet";
        }

        if (v == Head.PARTY_HAT) {
            return "Party Hat";
        }

        if (v == Head.CAP) {
            return "Cap";
        }

        if (v == Head.LEATHER_COWBOY_HAT) {
            return "Leather Cowboy Hat";
        }

        if (v == Head.CYBER_HELMET__BLUE) {
            return "Cyber Helmet - Blue";
        }

        if (v == Head.CYBER_HELMET__RED) {
            return "Cyber Helmet - Red";
        }

        if (v == Head.SAMURAI_HAT) {
            return "Samurai Hat";
        }

        if (v == Head.NONE) {
            return "None";
        }
        revert("invalid head");
    }

    function toString(Mouth v) external pure returns (string memory) {
        if (v == Mouth.SMIRK) {
            return "Smirk";
        }

        if (v == Mouth.SURPRISED) {
            return "Surprised";
        }

        if (v == Mouth.SMILE) {
            return "Smile";
        }

        if (v == Mouth.PIPE) {
            return "Pipe";
        }

        if (v == Mouth.OPEN_SMILE) {
            return "Open Smile";
        }

        if (v == Mouth.NEUTRAL) {
            return "Neutral";
        }

        if (v == Mouth.MASK) {
            return "Mask";
        }

        if (v == Mouth.TONGUE_OUT) {
            return "Tongue Out";
        }

        if (v == Mouth.GOLD_GRILL) {
            return "Gold Grill";
        }

        if (v == Mouth.DIAMOND_GRILL) {
            return "Diamond Grill";
        }

        if (v == Mouth.NAVY_RESPIRATOR) {
            return "Navy Respirator";
        }

        if (v == Mouth.RED_RESPIRATOR) {
            return "Red Respirator";
        }

        if (v == Mouth.MAGENTA_RESPIRATOR) {
            return "Magenta Respirator";
        }

        if (v == Mouth.GREEN_RESPIRATOR) {
            return "Green Respirator";
        }

        if (v == Mouth.MEMPO) {
            return "Mempo";
        }

        if (v == Mouth.VAPE) {
            return "Vape";
        }

        if (v == Mouth.PILOT_OXYGEN_MASK) {
            return "Pilot Oxygen Mask";
        }

        if (v == Mouth.CIGAR) {
            return "Cigar";
        }

        if (v == Mouth.BANANA) {
            return "Banana";
        }

        if (v == Mouth.CHROME_RESPIRATOR) {
            return "Chrome Respirator";
        }

        if (v == Mouth.STOIC) {
            return "Stoic";
        }
        revert("invalid mouth");
    }
}

// SPDX-License-Identifier: MIT
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/utils/Context.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/utils/introspection/ERC165.sol';

error ApprovalCallerNotOwnerNorApproved();
error ApprovalQueryForNonexistentToken();
error ApproveToCaller();
error ApprovalToCurrentOwner();
error BalanceQueryForZeroAddress();
error MintedQueryForZeroAddress();
error BurnedQueryForZeroAddress();
error MintToZeroAddress();
error MintZeroQuantity();
error OwnerIndexOutOfBounds();
error OwnerQueryForNonexistentToken();
error TokenIndexOutOfBounds();
error TransferCallerNotOwnerNorApproved();
error TransferFromIncorrectOwner();
error TransferToNonERC721ReceiverImplementer();
error TransferToZeroAddress();
error URIQueryForNonexistentToken();

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata and Enumerable extension. Built to optimize for lower gas during batch mints.
 *
 * Assumes serials are sequentially minted starting at 0 (e.g. 0, 1, 2, 3..).
 *
 * Assumes that an owner cannot have more than 2**64 - 1 (max value of uint64) of supply.
 *
 * Assumes that the maximum token id cannot exceed 2**128 - 1 (max value of uint128).
 */
contract ERC721A is Context, ERC165, IERC721, IERC721Metadata, IERC721Enumerable {
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
    }

    // Compiler will pack the following 
    // _currentIndex and _burnCounter into a single 256bit word.
    
    // The tokenId of the next token to be minted.
    uint128 internal _currentIndex;

    // The number of tokens burned.
    uint128 internal _burnCounter;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to ownership details
    // An empty struct value does not necessarily mean the token is unowned. See ownershipOf implementation for details.
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
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        // Counter underflow is impossible as _burnCounter cannot be incremented
        // more than _currentIndex times
        unchecked {
            return _currentIndex - _burnCounter;    
        }
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     * This read function is O(totalSupply). If calling from a separate contract, be sure to test gas first.
     * It may also degrade with extremely large collection sizes (e.g >> 10000), test for your use case.
     */
    function tokenByIndex(uint256 index) public view override returns (uint256) {
        uint256 numMintedSoFar = _currentIndex;
        uint256 tokenIdsIdx;

        // Counter overflow is impossible as the loop breaks when
        // uint256 i is equal to another uint256 numMintedSoFar.
        unchecked {
            for (uint256 i; i < numMintedSoFar; i++) {
                TokenOwnership memory ownership = _ownerships[i];
                if (!ownership.burned) {
                    if (tokenIdsIdx == index) {
                        return i;
                    }
                    tokenIdsIdx++;
                }
            }
        }
        revert TokenIndexOutOfBounds();
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     * This read function is O(totalSupply). If calling from a separate contract, be sure to test gas first.
     * It may also degrade with extremely large collection sizes (e.g >> 10000), test for your use case.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view override returns (uint256) {
        if (index >= balanceOf(owner)) revert OwnerIndexOutOfBounds();
        uint256 numMintedSoFar = _currentIndex;
        uint256 tokenIdsIdx;
        address currOwnershipAddr;

        // Counter overflow is impossible as the loop breaks when
        // uint256 i is equal to another uint256 numMintedSoFar.
        unchecked {
            for (uint256 i; i < numMintedSoFar; i++) {
                TokenOwnership memory ownership = _ownerships[i];
                if (ownership.burned) {
                    continue;
                }
                if (ownership.addr != address(0)) {
                    currOwnershipAddr = ownership.addr;
                }
                if (currOwnershipAddr == owner) {
                    if (tokenIdsIdx == index) {
                        return i;
                    }
                    tokenIdsIdx++;
                }
            }
        }

        // Execution should never reach this point.
        revert();
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            interfaceId == type(IERC721Enumerable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view override returns (uint256) {
        if (owner == address(0)) revert BalanceQueryForZeroAddress();
        return uint256(_addressData[owner].balance);
    }

    function _numberMinted(address owner) internal view returns (uint256) {
        if (owner == address(0)) revert MintedQueryForZeroAddress();
        return uint256(_addressData[owner].numberMinted);
    }

    function _numberBurned(address owner) internal view returns (uint256) {
        if (owner == address(0)) revert BurnedQueryForZeroAddress();
        return uint256(_addressData[owner].numberBurned);
    }

    /**
     * Gas spent here starts off proportional to the maximum mint batch size.
     * It gradually moves to O(1) as tokens get transferred around in the collection over time.
     */
    function ownershipOf(uint256 tokenId) internal view returns (TokenOwnership memory) {
        uint256 curr = tokenId;

        unchecked {
            if (curr < _currentIndex) {
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
        return ownershipOf(tokenId).addr;
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
    function setApprovalForAll(address operator, bool approved) public override {
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
        if (!_checkOnERC721Received(from, to, tokenId, _data)) {
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
        return tokenId < _currentIndex && !_ownerships[tokenId].burned;
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
        // balance or numberMinted overflow if current value of either + quantity > 3.4e38 (2**128) - 1
        // updatedIndex overflows if _currentIndex + quantity > 3.4e38 (2**128) - 1
        unchecked {
            _addressData[to].balance += uint64(quantity);
            _addressData[to].numberMinted += uint64(quantity);

            _ownerships[startTokenId].addr = to;
            _ownerships[startTokenId].startTimestamp = uint64(block.timestamp);

            uint256 updatedIndex = startTokenId;

            for (uint256 i; i < quantity; i++) {
                emit Transfer(address(0), to, updatedIndex);
                if (safe && !_checkOnERC721Received(address(0), to, updatedIndex, _data)) {
                    revert TransferToNonERC721ReceiverImplementer();
                }
                updatedIndex++;
            }

            _currentIndex = uint128(updatedIndex);
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
        TokenOwnership memory prevOwnership = ownershipOf(tokenId);

        bool isApprovedOrOwner = (_msgSender() == prevOwnership.addr ||
            isApprovedForAll(prevOwnership.addr, _msgSender()) ||
            getApproved(tokenId) == _msgSender());

        if (!isApprovedOrOwner) revert TransferCallerNotOwnerNorApproved();
        if (prevOwnership.addr != from) revert TransferFromIncorrectOwner();
        if (to == address(0)) revert TransferToZeroAddress();

        _beforeTokenTransfers(from, to, tokenId, 1);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId, prevOwnership.addr);

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as tokenId would have to be 2**128.
        unchecked {
            _addressData[from].balance -= 1;
            _addressData[to].balance += 1;

            _ownerships[tokenId].addr = to;
            _ownerships[tokenId].startTimestamp = uint64(block.timestamp);

            // If the ownership slot of tokenId+1 is not explicitly set, that means the transfer initiator owns it.
            // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
            uint256 nextTokenId = tokenId + 1;
            if (_ownerships[nextTokenId].addr == address(0)) {
                // This will suffice for checking _exists(nextTokenId),
                // as a burned slot cannot contain the zero address.
                if (nextTokenId < _currentIndex) {
                    _ownerships[nextTokenId].addr = prevOwnership.addr;
                    _ownerships[nextTokenId].startTimestamp = prevOwnership.startTimestamp;
                }
            }
        }

        emit Transfer(from, to, tokenId);
        _afterTokenTransfers(from, to, tokenId, 1);
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
        TokenOwnership memory prevOwnership = ownershipOf(tokenId);

        _beforeTokenTransfers(prevOwnership.addr, address(0), tokenId, 1);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId, prevOwnership.addr);

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as tokenId would have to be 2**128.
        unchecked {
            _addressData[prevOwnership.addr].balance -= 1;
            _addressData[prevOwnership.addr].numberBurned += 1;

            // Keep track of who burned the token, and the timestamp of burning.
            _ownerships[tokenId].addr = prevOwnership.addr;
            _ownerships[tokenId].startTimestamp = uint64(block.timestamp);
            _ownerships[tokenId].burned = true;

            // If the ownership slot of tokenId+1 is not explicitly set, that means the burn initiator owns it.
            // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
            uint256 nextTokenId = tokenId + 1;
            if (_ownerships[nextTokenId].addr == address(0)) {
                // This will suffice for checking _exists(nextTokenId),
                // as a burned slot cannot contain the zero address.
                if (nextTokenId < _currentIndex) {
                    _ownerships[nextTokenId].addr = prevOwnership.addr;
                    _ownerships[nextTokenId].startTimestamp = prevOwnership.startTimestamp;
                }
            }
        }

        emit Transfer(prevOwnership.addr, address(0), tokenId);
        _afterTokenTransfers(prevOwnership.addr, address(0), tokenId, 1);

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
                    revert TransferToNonERC721ReceiverImplementer();
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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
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
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Enums.sol";

library Rarities {
    function accessory() internal pure returns (uint16[] memory ret) {
        ret = new uint16[](7);
        ret[0] = 1200;
        ret[1] = 800;
        ret[2] = 800;
        ret[3] = 400;
        ret[4] = 400;
        ret[5] = 400;
        ret[6] = 6000;
    }

    function backaccessory() internal pure returns (uint16[] memory ret) {
        ret = new uint16[](8);
        ret[0] = 200;
        ret[1] = 1300;
        ret[2] = 800;
        ret[3] = 400;
        ret[4] = 1100;
        ret[5] = 700;
        ret[6] = 500;
        ret[7] = 5000;
    }

    function background() internal pure returns (uint16[] memory ret) {
        ret = new uint16[](23);
        ret[0] = 600;
        ret[1] = 600;
        ret[2] = 600;
        ret[3] = 600;
        ret[4] = 500;
        ret[5] = 500;
        ret[6] = 500;
        ret[7] = 500;
        ret[8] = 500;
        ret[9] = 500;
        ret[10] = 100;
        ret[11] = 100;
        ret[12] = 100;
        ret[13] = 600;
        ret[14] = 600;
        ret[15] = 600;
        ret[16] = 100;
        ret[17] = 100;
        ret[18] = 400;
        ret[19] = 400;
        ret[20] = 500;
        ret[21] = 500;
        ret[22] = 500;
    }

    function clothing() internal pure returns (uint16[] memory ret) {
        ret = new uint16[](24);
        ret[0] = 500;
        ret[1] = 500;
        ret[2] = 300;
        ret[3] = 300;
        ret[4] = 500;
        ret[5] = 400;
        ret[6] = 300;
        ret[7] = 250;
        ret[8] = 250;
        ret[9] = 500;
        ret[10] = 100;
        ret[11] = 500;
        ret[12] = 300;
        ret[13] = 500;
        ret[14] = 500;
        ret[15] = 500;
        ret[16] = 100;
        ret[17] = 400;
        ret[18] = 400;
        ret[19] = 250;
        ret[20] = 250;
        ret[21] = 250;
        ret[22] = 150;
        ret[23] = 2000;
    }

    function eyes() internal pure returns (uint16[] memory ret) {
        ret = new uint16[](32);
        ret[0] = 250;
        ret[1] = 700;
        ret[2] = 225;
        ret[3] = 350;
        ret[4] = 125;
        ret[5] = 450;
        ret[6] = 700;
        ret[7] = 700;
        ret[8] = 350;
        ret[9] = 350;
        ret[10] = 600;
        ret[11] = 450;
        ret[12] = 250;
        ret[13] = 350;
        ret[14] = 350;
        ret[15] = 225;
        ret[16] = 125;
        ret[17] = 350;
        ret[18] = 200;
        ret[19] = 200;
        ret[20] = 200;
        ret[21] = 200;
        ret[22] = 200;
        ret[23] = 200;
        ret[24] = 50;
        ret[25] = 50;
        ret[26] = 450;
        ret[27] = 450;
        ret[28] = 400;
        ret[29] = 450;
        ret[30] = 25;
        ret[31] = 25;
    }

    function fur() internal pure returns (uint16[] memory ret) {
        ret = new uint16[](16);
        ret[0] = 1100;
        ret[1] = 1100;
        ret[2] = 1100;
        ret[3] = 525;
        ret[4] = 350;
        ret[5] = 1100;
        ret[6] = 350;
        ret[7] = 1100;
        ret[8] = 1000;
        ret[9] = 525;
        ret[10] = 525;
        ret[11] = 500;
        ret[12] = 525;
        ret[13] = 100;
        ret[14] = 50;
        ret[15] = 50;
    }

    function head() internal pure returns (uint16[] memory ret) {
        ret = new uint16[](21);
        ret[0] = 200;
        ret[1] = 200;
        ret[2] = 350;
        ret[3] = 350;
        ret[4] = 350;
        ret[5] = 150;
        ret[6] = 600;
        ret[7] = 350;
        ret[8] = 350;
        ret[9] = 350;
        ret[10] = 600;
        ret[11] = 600;
        ret[12] = 600;
        ret[13] = 200;
        ret[14] = 350;
        ret[15] = 600;
        ret[16] = 600;
        ret[17] = 50;
        ret[18] = 50;
        ret[19] = 100;
        ret[20] = 3000;
    }

    function mouth() internal pure returns (uint16[] memory ret) {
        ret = new uint16[](21);
        ret[0] = 1000;
        ret[1] = 1000;
        ret[2] = 1000;
        ret[3] = 650;
        ret[4] = 1000;
        ret[5] = 900;
        ret[6] = 750;
        ret[7] = 650;
        ret[8] = 100;
        ret[9] = 50;
        ret[10] = 100;
        ret[11] = 100;
        ret[12] = 100;
        ret[13] = 100;
        ret[14] = 50;
        ret[15] = 100;
        ret[16] = 100;
        ret[17] = 600;
        ret[18] = 600;
        ret[19] = 50;
        ret[20] = 1000;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merklee tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }
        return computedHash;
    }
}