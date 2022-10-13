// SPDX-License-Identifier: PROPRIERTARY

// Author: Ilya A. Shlyakhovoy
// Email: [email protected]

pragma solidity 0.8.4;

import "./Actors.sol";

contract Zombies is Actors {
    constructor(
        address token,
        address payTarget,
        uint256 adultPrice,
        uint256 birthPrice
    )
        Actors(
            "UndeadsZombies",
            "UDZT",
            token,
            payTarget,
            adultPrice,
            birthPrice
        )
    {}
}

// SPDX-License-Identifier: PROPRIERTARY

// Author: Ilya A. Shlyakhovoy
// Email: [email protected]
pragma solidity 0.8.4;

/**
 * @dev Collection of structures
 */
library Structures {
    uint8 public constant CRAFT_WAITING = 0x00;
    uint8 public constant CRAFT_CANCELLED = 0x01;
    uint8 public constant CRAFT_DONE = 0x02;
    uint8 public constant ESTATE_LAND = 0x00;
    uint8 public constant ESTATE_HABITAT = 0x01;
    uint8 public constant ESTATE_CRAFT = 0x02;
    uint8 public constant ESTATE_SERVICE = 0x03;
    struct ActorData {
        uint256 adult;
        uint16[10] props;
        uint8 childs;
        bool sex;
        bool born;
    }
    struct ItemType {
        uint256 class;
        uint256 subclass;
        uint8 slots;
        uint16[10] props;
    }

    struct Resource {
        uint256 resource;
        uint256 amount;
    }
 
    struct Estate {
        address lender;
        uint256 location;
        uint8 estateType;
        uint256 parent;
        uint256 coordinates;
    }

    struct ManageAction {
        address target;
        address author;
        uint256 deadline;
        bytes4 signature;
        bytes data;
        bool executed;
    }

    struct InvestorData {
        address investor;
        uint256 promille;
    }
}

// SPDX-License-Identifier: PROPRIERTARY

// Author: Ilya A. Shlyakhovoy
// Email: [email protected]

pragma solidity 0.8.4;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IPotions is IERC721 {
    event Created(address indexed owner, uint256 id, uint256 level);
    event Opened(address indexed owner, uint256 id);
    event ChildsDefined(uint256 childs);
    event WomanDefined(address woman);
    event BoxDefined(address box);

    /**
@notice Get a total amount of issued tokens
@return The number of tokens minted
*/

    function total() external view returns (uint256);

    /**
@notice Get the amount of the actors remains to be created
@return The current value
*/
    function unissued() external view returns (uint256);

    /**
@notice Set the maximum amount of the childs for the woman actor
@param childs_ New childs amount
*/
    function setChilds(uint256 childs_) external;

    /**
@notice Get the current  maximum amount of the childs
@return The current value
*/
    function getChilds() external view returns (uint256);

    /**
@notice Set the address of the Box contract
@param box_ New address
*/
    function setBox(address box_) external;

    /**
@notice Set the address of the woman percentage calculator contract
@param woman_ New address
*/
    function setWoman(address woman_) external;

    /**
@notice Get the breeding calculator contract address
@return The current contract address
*/
    function getWoman() external view returns (address);

    /**
@notice Open the packed id with the random values
@param id_ The pack id
@return The new actor id
*/
    function open(uint256 id_) external returns (uint256);

    /**
@notice Create the potion by box (rare or not)
@param target The potion owner
@param rare The rarity sign
@return The new pack id
*/
    function create(address target, bool rare) external returns(uint256);

    /**
@notice Create the packed potion with desired level (admin only)
@param target The pack owner
@param level The pack level
@return The new pack id
*/
    function createPotion(address target, uint256 level) external returns (uint256);

    /**
@notice Decrease the amount of the common or rare tokens or fails
*/
    function decreaseAmount(bool rare) external returns (bool);

    /**
@notice Get the balance of the contract
@return The balance in ethers
*/
    function getBalance() external view returns (uint256);

    /**
@notice Withdraw the funds
@param target The target for the withdrawal 
@param amount The amount of 
*/
    function withdraw(address payable target, uint256 amount) external;
}

// SPDX-License-Identifier: PROPRIERTARY

// Author: Ilya A. Shlyakhovoy
// Email: [email protected]

pragma solidity 0.8.4;

interface IBreed {
    event ReceiverDefined(address receiver);
    event TokenDefined(address token);
    event ActorDefined(address actor);
    event RandomDefined(address random);
    event CalculatorDefined(address calculator);
    event LimitDefined(uint256 limitPromille);
    event DeviationDefined(uint256 deviationPromille);
    event ChildsDefined(uint256 childs);
    event NewBreed(address indexed owner, uint256 id);
    event WomanDefined(address woman);

    /**
@notice Set the address of the actor contract
@param actor_ New address
*/
    function setActor(address actor_) external;

    /**
@notice Get the actor contract address
@return The current actor contract address
*/
    function getActor() external view returns (address);

    /**
@notice Set the address of the random generator contract
@param random_ New address
*/
    function setRandom(address random_) external;

    /**
@notice Get the random generator address
@return The current random contract address
*/
    function getRandom() external view returns (address);

    /**
@notice Set the address of the breeding calculator contract
@param calculator_ New address
*/
    function setCalculator(address calculator_) external;

    /**
@notice Get the breeding calculator contract address
@return The current contract address
*/
    function getCalculator() external view returns (address);

    /**
@notice Set the address of the token contract
@param token_ New address
*/
    function setToken(address token_) external;

    /**
@notice Get the token contract address
@return The current token contract address
*/
    function getToken() external view returns (address);

    /**
@notice Set the address of the new tokens receiver
@param receiver_ New address
*/
    function setReceiver(address receiver_) external;

    /**
@notice Get the address of the tokens receiver
@return The current address
*/
    function getReceiver() external view returns (address);

    /**
@notice Set the maximum allowed limit of the actor property, in promille
@param limitPromille_ New amount
*/
    function setLimit(uint256 limitPromille_) external;

    /**
@notice Get the current limit of the actor properties
@return The current value
*/
    function getLimit() external view returns (uint256);

    /**
@notice Set the maximum amount of the childs for the woman actor
@param childs_ New childs amount
*/
    function setChilds(uint256 childs_) external;

    /**
@notice Get the current  maximum amount of the childs
@return The current value
*/
    function getChilds() external view returns (uint256);

    /**
@notice Set the normal deviation of the actor property, in promille
@param deviationPromille_ New value
*/
    function setDeviation(uint256 deviationPromille_) external;

    /**
@notice Get the current normal deviation of the actor property, in promille
@return The current value
*/
    function getDeviation() external view returns (uint256);

    /**
@notice Set the address of the woman percentage calculator contract
@param woman_ New address
*/
    function setWoman(address woman_) external;

    /**
@notice Get the breeding calculator contract address
@return The current contract address
*/
    function getWoman() external view returns (address);

    /**
@notice Allow from the father side to breed with mother. 
Should to be called by father owner account.
Can be called many times, incrementing the counter.
@param fatherId The father token id
@param motherId The mother token id
*/
    function allowFather(uint256 fatherId, uint256 motherId) external;

    /**
@notice Breed a new actor from the father and mother. 
Should to be called by mother owner account.
If father is not allow to breed, call will fail. The breeding takes the 
breed price from the mother's account
@param fatherId The father token id
@param motherId The mother token id
@return The id of breeded actor
*/
    function breed(uint256 fatherId, uint256 motherId)
        external
        returns (uint256);
}

// SPDX-License-Identifier: PROPRIERTARY

// Author: Ilya A. Shlyakhovoy
// Email: [email protected]

pragma solidity 0.8.4;
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

interface IActors is IERC721Metadata {
    event BoxDefined(address indexed box);

    event BreedDefined(address indexed breed);

    event TokenDefined(address indexed token);

    event TargetDefined(address indexed target);

    event AdultPriceDefined(uint256 indexed amount);

    event BirthPriceDefined(uint256 indexed amount);

    event Minted(address indexed owner, uint256 indexed id);

    event Born(address indexed owner, uint256 indexed id);

    event Grow(address indexed owner, uint256 indexed id);

    event Adult(address indexed owner, uint256 indexed id);

    event TokenUriDefined(uint256 indexed id, string uri);

    /**
@notice Get a total amount of issued tokens
@return The number of tokens minted
*/

    function total() external view returns (uint256);

    /**
@notice Set a new Potion contract address
@param potion_ New contract address
*/
    function setPotion(address payable potion_) external;

    /**
@notice Get a Potion token address
@return The current Potion token address
*/
    function getPotion() external view returns (address);

    /**
@notice Set a new Breed contract address
@param breed_ New contract address
*/
    function setBreed(address breed_) external;

    /**
@notice Get a Breed token address
@return The current Breed token address
*/
    function getBreed() external view returns (address);

    /**
@notice Set a payment token address
@param token The current payment token address
*/
    function setToken(address token) external;

    /**
@notice Get a payment token address
@return The current payment token address
*/
    function getToken() external view returns (address);

    /**
@notice Set an uri for the token
@param id token id
@param uri token uri for id
*/
    function setUri(uint256 id, string memory uri) external;

    /**
@notice Get an uri for the token
@param id token id
@return The current payment token address
*/
    function getUri(uint256 id) external view returns (string memory);

    /**
@notice Set the price for the becoming person adult
@param price New price
*/
    function setAdultPrice(uint256 price) external;

    /**
@notice Get the price of becoming adult
@return The current price
*/
    function getAdultPrice() external view returns (uint256);

    /**
@notice Set the price for the birth of the person
@param price New price
*/
    function setBirthPrice(uint256 price) external;

    /**
@notice Get the price of becoming born
@return The current price
*/

    function getBirthPrice() external view returns (uint256);

    /**
@notice Create a new person token (not born yet)
@param owner_ Owner of the token
@param props_ Array of the actor properties
@param sex_ The person sex (true = male, false = female)
@param childs_ The amount of childs can be born (only for female)
@return The new id
*/
    function mint(
        address owner_,
        uint16[10] memory props_,
        bool sex_,
        uint8 childs_
    ) external returns (uint256);

    /**
@notice Create a new person token (born and adult)
@param owner_ Owner of the token
@param props_ Array of the actor properties
@param sex_ The person sex (true = male, false = female)
@param childs_ The amount of childs can be born (only for female)
@return The new id
*/
    function mintAdult(
        address owner_,
        uint16[10] memory props_,
        bool sex_,
        uint8 childs_
    ) external returns (uint256);

    /**
@notice Get the person props
@param tokenId Person token id
@return Array of the props
*/
    function getProps(uint256 tokenId)
        external
        view
        returns (uint16[10] memory);

    /**
@notice Get the person sex
@param tokenId Person token id
@return true = male, false = female
*/
    function getSex(uint256 tokenId) external view returns (bool);

    /**
@notice Get the person adult state
@param tokenId Person token id
@return 0 = complete adult, or amount of tokens needed to be paid for
*/
    function getAdult(uint256 tokenId) external view returns (uint256);

    /**
@notice Get the person born state
@param tokenId Person token id
@return true = person is born
*/
    function isBorn(uint256 tokenId) external view returns (bool);

    /**
@notice Birth the person. Takes the needed amount of tokens from the caller account
@param id Person token id
*/
    function born(uint256 id) external;

    /**
@notice Grow the non-adult person. Takes the provided amount of tokens from 
the caller account, but not more than needed
@param id Person token id
@param amount Amount of tokens transferred
*/
    function grow(uint256 id, uint256 amount) external;

    /**
@notice Destroy the token for the caller
@param id Person token id
*/
    function burn(uint256 id) external;

    /**
@notice Destroy the token for the address
@param account Owner address
@param id Person token id
*/
    function burn(address account, uint256 id) external;
}

// SPDX-License-Identifier: PROPRIERTARY

// Author: Ilya A. Shlyakhovoy
// Email: [email protected]

pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./interfaces/IActors.sol";
import "./interfaces/IBreed.sol";
import "./interfaces/IPotions.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./lib/Structures.sol";

/**
@title The Actor NFT contract
@author Ilya A. Shlyakhovoy
@notice This contract manage properties of the game actor, including birth and childhood.
The new actor comes from the Breed or Box contracts
 */

contract Actors is Ownable, ERC721, IActors {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    IPotions public _potion;
    IBreed public _breed;
    uint256 private _popertiesAmount;
    uint256 private _adultPrice;
    uint256 private _birthPrice;
    IERC20 private _token;
    address private _target;
    mapping(uint256 => Structures.ActorData) private _actors;
    mapping(uint256 => string) private _uri;

    /// @notice only if token and target exists
    modifier tokenDefined() {
        require(address(_token) != address(0), "Actor: Token is 0x0");
        require(address(_target) != address(0), "Actor: Target is 0x0");
        _;
    }

    /// @notice only if box contract calls
    modifier onlyCreator() {
        require(address(_potion) != address(0), "Actor: Potion is 0x0");
        require(address(_breed) != address(0), "Actor: Breed is 0x0");
        require(
            owner() == _msgSender() ||
                address(_potion) == _msgSender() ||
                address(_breed) == _msgSender(),
            "Actor: no rights to call"
        );
        _;
    }

    /**
@notice constructor
@param name_ The name of the token
@param symbol_ The short name (symbol) of the token
@param token_ The address of the token contract
@param game_ The address of the token's receiver (for the payments)
@param adultPrice The price for becomes an adult
@param birthPrice The price for the birth
*/
    constructor(
        string memory name_,
        string memory symbol_,
        address token_,
        address game_,
        uint256 adultPrice,
        uint256 birthPrice
    ) ERC721(name_, symbol_) {
        require(token_ != address(0), "Actor: Token is empty");
        require(game_ != address(0), "Actor: Target is empty");
        _adultPrice = adultPrice;
        _birthPrice = birthPrice;
        _token = IERC20(token_);
        _target = game_;
        emit TokenDefined(token_);
        emit TargetDefined(game_);
    }

    /**
@notice Get a total amount of issued tokens
@return The number of tokens minted
*/

    function total() external view override returns (uint256) {
        return _tokenIds.current();
    }

    /**
@notice Set a new Potion contract address
@param potion_ New contract address
*/
    function setPotion(address payable potion_) external override onlyOwner {
        require(potion_ != address(0), "Actor: Potion is empty");
        _potion = IPotions(potion_);
        emit BoxDefined(potion_);
    }

    /**
@notice Get a Potion token address
@return The current Potion token address
*/
    function getPotion() external view override returns (address) {
        return address(_potion);
    }

    /**
@notice Set a new Breed contract address
@param breed_ New contract address
*/
    function setBreed(address breed_) external override onlyOwner {
        require(breed_ != address(0), "Actor: Breed is empty");
        _breed = IBreed(breed_);
        emit BreedDefined(breed_);
    }

    /**
@notice Get a Breed token address
@return The current Breed token address
*/
    function getBreed() external view override returns (address) {
        return address(_breed);
    }

    /**
@notice Set a payment token address
@param token The current payment token address
*/
    function setToken(address token) external override onlyOwner {
        require(token != address(0), "Actor: Token is empty");
        _token = IERC20(token);
        emit TokenDefined(token);
    }

    /**
@notice Get a payment token address
@return The current payment token address
*/
    function getToken() external view override returns (address) {
        return address(_token);
    }

    /**
@notice Set an uri for the token
@param id token id
@param uri token uri for id
*/
    function setUri(uint256 id, string memory uri) external override onlyOwner {
        require(id < _tokenIds.current(), "Actor: wrong id");
        _uri[id] = uri;
        emit TokenUriDefined(id, uri);
    }

    /**
@notice Get an uri for the token
@param id token id
@return The current payment token address
*/
    function getUri(uint256 id) external view override returns (string memory) {
        require(id < _tokenIds.current(), "Actor: wrong id");
        return _uri[id];
    }

    /**
@notice Set the price for the becoming person adult
@param price New price
*/
    function setAdultPrice(uint256 price) external override onlyOwner {
        _adultPrice = price;
        emit AdultPriceDefined(price);
    }

    /**
@notice Get the price of becoming adult
@return The current price
*/
    function getAdultPrice() external view override returns (uint256) {
        return _adultPrice;
    }

    /**
@notice Set the price for the birth of the person
@param price New price
*/
    function setBirthPrice(uint256 price) external override onlyOwner {
        _birthPrice = price;
        emit BirthPriceDefined(price);
    }

    /**
@notice Get the price of becoming born
@return The current price
*/

    function getBirthPrice() external view override returns (uint256) {
        return _birthPrice;
    }

    /**
@notice Create a new person token (not born yet)
@param owner_ Owner of the token
@param props_ Array of the actor properties
@param sex_ The person sex (true = male, false = female)
@param childs_ The amount of childs can be born (only for female)
@return The new id
*/
    function mint(
        address owner_,
        uint16[10] memory props_,
        bool sex_,
        uint8 childs_
    ) external override onlyCreator returns (uint256) {
        uint256 newId = _tokenIds.current();
        _mint(owner_, newId);
        _actors[newId] = Structures.ActorData({
            props: props_,
            sex: sex_,
            adult: _adultPrice,
            childs: childs_,
            born: false
        });
        _tokenIds.increment();
        emit Minted(owner_, newId);
        return newId;
    }

    /**
@notice Create a new person token (born and adult)
@param owner_ Owner of the token
@param props_ Array of the actor properties
@param sex_ The person sex (true = male, false = female)
@param childs_ The amount of childs can be born (only for female)
@return The new id
*/
    function mintAdult(
        address owner_,
        uint16[10] memory props_,
        bool sex_,
        uint8 childs_
    ) external override onlyCreator returns (uint256) {
        uint256 newId = _tokenIds.current();
        _mint(owner_, newId);
        _actors[newId] = Structures.ActorData({
            props: props_,
            sex: sex_,
            adult: 0,
            childs: childs_,
            born: true
        });
        _tokenIds.increment();
        emit Minted(owner_, newId);
        return newId;
    }

    /**
@notice Get the person props
@param tokenId Person token id
@return Array of the props
*/
    function getProps(uint256 tokenId)
        external
        view
        override
        returns (uint16[10] memory)
    {
        require(tokenId < _tokenIds.current(), "Actor: wrong id");
        return _actors[tokenId].props;
    }

    /**
@notice Get the person sex
@param tokenId Person token id
@return true = male, false = female
*/
    function getSex(uint256 tokenId) external view override returns (bool) {
        return _actors[tokenId].sex;
    }

    /**
@notice Get the person adult state
@param tokenId Person token id
@return 0 = complete adult, or amount of tokens needed to be paid for
*/
    function getAdult(uint256 tokenId)
        external
        view
        override
        returns (uint256)
    {
        require(tokenId < _tokenIds.current(), "Actor: wrong id");
        return _actors[tokenId].adult;
    }

    /**
@notice Get the person born state
@param tokenId Person token id
@return true = person is born
*/
    function isBorn(uint256 tokenId) external view override returns (bool) {
        require(tokenId < _tokenIds.current(), "Actor: wrong id");
        return _actors[tokenId].born;
    }

    /**
@notice Birth the person. Takes the needed amount of tokens from the caller account
@param id Person token id
*/
    function born(uint256 id) external override tokenDefined {
        require(id < _tokenIds.current(), "Actor: wrong id");
        require(
            _token.balanceOf(_msgSender()) >= _birthPrice,
            "Actor: not enough funds"
        );
        require(_actors[id].born == false, "Actor: already born");
        require(ownerOf(id) == _msgSender(), "Actor: wrong person");
        require(
            _token.transferFrom(_msgSender(), _target, _birthPrice),
            "Actor: cannot pay"
        );
        _actors[id].born = true;
        emit Born(_msgSender(), id);
    }

    /**
@notice Grow the non-adult person. Takes the provided amount of tokens from 
the caller account, but not more than needed
@param id Person token id
@param amount Amount of tokens transferred
*/
    function grow(uint256 id, uint256 amount) external override tokenDefined {
        require(id < _tokenIds.current(), "Actor: wrong id");
        require(
            _token.balanceOf(_msgSender()) >= amount,
            "Actor: not enough funds"
        );
        require(_actors[id].born, "Actor: not born yet");
        require(_actors[id].adult > 0, "Actor: already adult");
        require(ownerOf(id) == _msgSender(), "Actor: wrong person");
        if (_actors[id].adult > amount) {
            require(
                _token.transferFrom(_msgSender(), _target, amount),
                "Actor: cannot pay"
            );
            _actors[id].adult = _actors[id].adult - amount;
            emit Grow(_msgSender(), id);
        } else {
            require(
                _token.transferFrom(_msgSender(), _target, _actors[id].adult),
                "Actor: cannot pay"
            );
            _actors[id].adult = 0;
            emit Adult(_msgSender(), id);
        }
    }

    /**
@notice Destroy the token for the caller
@param id Person token id
*/
    function burn(uint256 id) external override {
        require(id < _tokenIds.current(), "Actor: wrong id");
        require(ownerOf(id) == _msgSender(), "Actor: wrong person");
        _burn(id);
    }

    /**
@notice Destroy the token for the address
@param account Owner address
@param id Person token id
*/
    function burn(address account, uint256 id) external override onlyCreator {
        require(id < _tokenIds.current(), "Actor: wrong id");
        _burn(id);
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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

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
     * by default, can be overridden in child contracts.
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
        _setApprovalForAll(_msgSender(), operator, approved);
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
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

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
        safeTransferFrom(from, to, tokenId, "");
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
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
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
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
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
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
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

        _afterTokenTransfer(owner, address(0), tokenId);
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
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
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
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
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
                return retval == IERC721Receiver.onERC721Received.selector;
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
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
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