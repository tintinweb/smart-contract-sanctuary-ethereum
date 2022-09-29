// SPDX-License-Identifier: PROPRIERTARY

// Author: Ilya A. Shlyakhovoy
// Email: [email protected]

pragma solidity 0.8.4;

import "./Actors.sol";

contract Zombies is Actors {
    constructor(
        string memory url,
        address token,
        address payTarget,
        uint256 adultPrice,
        uint256 birthPrice
    ) Actors(url, token, payTarget, adultPrice, birthPrice) {}
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
    struct Plan {
        uint256 model;
        uint256 modelType;
        uint8 amount;
        uint8 slots;
    }
    struct Resource {
        uint256 resource;
        uint256 amount;
    }

    struct Crafting {
        Plan plan;
        uint256 owner;
        bool crafted;
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
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

interface IActors is IERC1155 {
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
@notice Set a new Box contract address
@param box_ New contract address
*/
    function setBox(address payable box_) external;

    /**
@notice Get a Box token address
@return The current Box token address
*/
    function getBox() external view returns (address);

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

interface IActorBox {
    event Created(address indexed owner, uint256 id, uint256 level);
    event Opened(address indexed owner, uint256 id);
    event ChildsDefined(uint256 childs);
    event WomanDefined(address woman);

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
@notice Create the packed id with desired level (admin only)
@param target The pack owner
@param level The pack level
@return The new pack id
*/
    function create(address target, uint256 level) external returns (uint256);

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

    /**
@notice Deposit the funds (payable function)
*/
    function deposit() external payable;
}

// SPDX-License-Identifier: PROPRIERTARY

// Author: Ilya A. Shlyakhovoy
// Email: [email protected]

pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./interfaces/IActors.sol";
import "./interfaces/IBreed.sol";
import "./interfaces/IActorBox.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./lib/Structures.sol";

/**
@title The Actor NFT contract
@author Ilya A. Shlyakhovoy
@notice This contract manage properties of the game actor, including birth and childhood.
The new actor comes from the Breed or Box contracts
 */

contract Actors is Ownable, ERC1155, IActors {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    IActorBox private _box;
    IBreed private _breed;
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
        require(address(_box) != address(0), "Actor: Box is 0x0");
        require(address(_breed) != address(0), "Actor: Breed is 0x0");
        require(
            owner() == _msgSender() ||
                address(_box) == _msgSender() ||
                address(_breed) == _msgSender(),
            "Actor: no rights to call"
        );
        _;
    }

    /**
@notice constructor
@param url The URI for all tokens
@param token_ The address of the token contract
@param game_ The address of the token's receiver (for the payments)
@param adultPrice The price for becomes an adult
@param birthPrice The price for the birth
*/
    constructor(
        string memory url,
        address token_,
        address game_,
        uint256 adultPrice,
        uint256 birthPrice
    ) ERC1155(url) {
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
@notice Set a new Box contract address
@param box_ New contract address
*/
    function setBox(address payable box_) external override onlyOwner {
        require(box_ != address(0), "Actor: Box is empty");
        _box = IActorBox(box_);
        emit BoxDefined(box_);
    }

    /**
@notice Get a Box token address
@return The current Box token address
*/
    function getBox() external view override returns (address) {
        return address(_box);
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
        _mint(owner_, newId, 1, "");
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
        _mint(owner_, newId, 1, "");
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
        require(balanceOf(_msgSender(), id) == 1, "Actor: wrong person");
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
        require(balanceOf(_msgSender(), id) == 1, "Actor: wrong person");
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
        _burn(_msgSender(), id, 1);
    }

    /**
@notice Destroy the token for the address
@param account Owner address
@param id Person token id
*/
    function burn(address account, uint256 id) external override onlyCreator {
        require(id < _tokenIds.current(), "Actor: wrong id");
        _burn(account, id, 1);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;

import "./IERC1155.sol";
import "./IERC1155Receiver.sol";
import "./extensions/IERC1155MetadataURI.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    constructor(string memory uri_) {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
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
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    /**
     * @dev Hook that is called after any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
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