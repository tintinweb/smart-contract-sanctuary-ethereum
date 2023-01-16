// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./RobotMarketPlace.sol";

/**
 * @title RobotCore contract.
 * NOTE: The contract includes the main functions for minting and modifying robots.
 * @dev Contract inherit from RobotMarketPlace and RobotFactory contracts.
 */
contract RobotCore is Ownable, RobotMarketPlace {
    uint256 private _gen0Counter;
    uint256 public immutable CREATION_LIMIT_GEN0;

    /**
     * @dev Set immutable amount of generation 0 robots available for minting.
     * @param _gen0Limit Limit of generation 0 robots that the owner of the contract can create.
     */
    constructor(uint256 _gen0Limit) {
        require(_gen0Limit > 1, "Minimum 2 gen0 required");
        CREATION_LIMIT_GEN0 = _gen0Limit;
    }

    /**
     * @dev Function to create a new robot from the IDs of two available robots for a specific address.
     * The ID of the new robot is calculated randomly using parts from the first and second parent IDs.
     * To calculate the generation and ID of a new robot, _newRobotId() and _newRobotGeneration() are called, respectively.
     * At the end it calls _createRobot() from RobotFactory contract.
     *
     * Requirements:
     *
     * - The owner of `_firstRobotParentId` and `_secondRobotParentId` must be the initiator of the function.
     * - `_firstRobotParentId` and `_secondRobotParentId` must be different IDs.
     *
     * @param _firstRobotParentId Id of first robot that will be the first 'parent'.
     * @param _secondRobotParentId Id of second robot that will be the second 'parent'.
     *
     * Emits a {Build} event.
     */
    function modifying(uint64 _firstRobotParentId, uint64 _secondRobotParentId) public {
        require(ownerOf(_firstRobotParentId) == msg.sender, "One or both of the tokens do not belong to caller");
        require(ownerOf(_secondRobotParentId) == msg.sender, "One or both of the tokens do not belong to caller");
        require(_firstRobotParentId != _secondRobotParentId, "The robot can't modify himself alone");
        (uint64 firstRobotParentId, , , , uint32 firstRobotParentGeneration, ) = getRobot(_firstRobotParentId);
        (uint64 secondRobotParentId, , , , uint32 secondRobotParentGeneration, ) = getRobot(_secondRobotParentId);
        uint256 newRobotId = _newRobotId(firstRobotParentId, secondRobotParentId);
        uint32 newRobotGeneration = _newRobotGeneration(firstRobotParentGeneration, secondRobotParentGeneration);
        _createRobot(uint64(newRobotId), _firstRobotParentId, _secondRobotParentId, newRobotGeneration, msg.sender);
    }

    /**
     * @dev The function for calculating the ID of the new robot, which is calculated from 8 parts, each of which is
     * randomly taken from one of the parents. Randomly, one of these parts does not belong to either parent and is
     * a unique part of the new robot.
     *
     * Algorithm use a mask on random number to check if the firstRobotParentId or the secondRobotParentID will be used
     * For example 205 is 11001101 in binary So 1 is firstRobotParent and 0 is secondRobotParent
     * firstRobotParent - firstRobotParent - secondRobotParent - secondRobotParent
     * - firstRobotParent - firstRobotParent - secondRobotParent - firstRobotParent
     * Than we get a binary bitwise AND operation with i, which is '00000001' for i = 1, '00000010' for i = 2,
     * '00000100' for i = 4, '00001000' for i = 8, '00010000' for i = 16, '00100000' for i = 32,
     * '01000000' for i = 64 and '10000000' for i = 128 for uint8 i(8 bits).
     *
     * @param firstRobotParentId_ Id of first robot that will be the first 'parent'.
     * @param secondRobotParentId_ Id of second robot that will be the second 'parent'.
     */
    function _newRobotId(uint64 firstRobotParentId_, uint64 secondRobotParentId_)
        private
        view
        returns (uint256 newRobotId_)
    {
        uint256 newRobotId;
        uint64[8] memory idArray;
        uint64 index = 8;
        uint256 random;
        for (uint256 i = 1; i <= 128; i *= 2) {
            random = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender))) % 255;
            index -= 1;
            if (i == 16) {
                if (random % 2 != 0) {
                    idArray[index] = firstRobotParentId_ % 10;
                } else {
                    idArray[index] = secondRobotParentId_ % 10;
                }
                firstRobotParentId_ /= 10;
                secondRobotParentId_ /= 10;
            } else if (random & i != 0) {
                idArray[index] = firstRobotParentId_ % 100;
                firstRobotParentId_ /= 100;
                secondRobotParentId_ /= 100;
            } else {
                idArray[index] = secondRobotParentId_ % 100;
                firstRobotParentId_ /= 100;
                secondRobotParentId_ /= 100;
            }
        }
        /* Add a random parameter in a random place */
        uint64 newIdIndex = uint64(random % 8);
        if (newIdIndex == 3) {
            idArray[newIdIndex] = uint64(random % 9) + 1;
        } else {
            idArray[newIdIndex] = uint64(random % 89) + 11;
        }
        /* Id is reversed in the right order */
        for (uint256 i = 0; i < 8; i++) {
            newRobotId += idArray[i];
            if (i != 7) {
                newRobotId *= 100;
            }
            if (i == 2) {
                newRobotId /= 10;
            }
        }
        return newRobotId;
    }

    /**
     * @dev The function for calculating the generation of the new robot, which is calculated from generation
     * of first and second 'parents'.
     *
     * Algorithm check generations of the 'parents'. If the generation of one of the parents is greater than
     * the generation of the other, then one is added to the generation level of this parent and divided by two.
     * If the generation level of both parents is the same, then the generation level of the new robot
     * will be one more than its 'parents'.
     *
     * @param firstRobotParentGeneration_ generation of first robot that will be the first 'parent'.
     * @param secondRobotParentGeneration_ generation of second robot that will be the second 'parent'.
     */
    function _newRobotGeneration(uint32 firstRobotParentGeneration_, uint32 secondRobotParentGeneration_)
        private
        pure
        returns (uint32 newRobotGeneration_)
    {
        uint32 newRobotGeneration = 0;
        if (secondRobotParentGeneration_ < firstRobotParentGeneration_) {
            newRobotGeneration = firstRobotParentGeneration_ + 1;
            newRobotGeneration /= 2;
        } else if (secondRobotParentGeneration_ > firstRobotParentGeneration_) {
            newRobotGeneration = secondRobotParentGeneration_ + 1;
            newRobotGeneration /= 2;
        } else {
            newRobotGeneration = firstRobotParentGeneration_ + 1;
        }
        return newRobotGeneration;
    }

    /**
     * @dev Function to create a new robot of generation 0. The ID of the new robot is any fifteen-digit number.
     * There can be a limited number of these tokens, set by the owner of the contract.
     *
     * Requirements:
     *
     * - `_gen0Counter` must be less than `CREATION_LIMIT_GEN0`.
     *
     * @param _id Fifteen-digit ID number of new robot of generation 0.
     *
     * Emits a {Build} event.
     */
    function createRobotGen0(uint64 _id) external {
        require(_gen0Counter < CREATION_LIMIT_GEN0, "Gen0 the number of robots has reached its maximum");
        _gen0Counter++;
        uint256 tokenId = _createRobot(_id, 0, 0, 0, msg.sender);
        setOffer(0.2 ether, tokenId);
    }

    /**
     * @dev Returns Robot data by providing token Id.
     */
    function getRobot(uint64 _id)
        public
        view
        returns (
            uint64 robotId,
            uint64 buildTime,
            uint64 firstRobotParentId,
            uint64 secondRobotParentId,
            uint32 generation,
            uint32 tokenId
        )
    {
        Robot memory robot = _robots[_id];
        require(robot.buildTime > 0, "The robot doesn't exist");
        robotId = robot.robotId;
        buildTime = uint64(robot.buildTime);
        firstRobotParentId = uint64(robot.firstRobotParentId);
        secondRobotParentId = uint64(robot.secondRobotParentId);
        generation = robot.generation;
        tokenId = robot.tokenId;
    }

    /**
     * @dev Returns created amount of gen 0 robots.
     */
    function getCreatedGen0() external view returns (uint256) {
        return _gen0Counter;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
import "./RobotFactory.sol";

pragma solidity 0.8.15;

/**
 * @title RobotMarketPlace contract.
 * NOTE: The contract includes functions for setting up, removing offers and buying robots.
 * @dev Contract RobotFactory contract.
 */
contract RobotMarketPlace is RobotFactory {
    struct Offer {
        address payable seller;
        uint256 price;
        uint256 tokenId;
    }

    Offer[] private _offers;

    // Mapping from token ID to Offer object.
    mapping(uint256 => Offer) private _tokenIdToOffer;
    // Mapping from token ID to Offer Id.
    mapping(uint256 => uint256) private _tokenIdToOfferId;

    /**
     * @dev Emitted when a new transaction occurs.
     * @param TxType String type of transaction.
     * @param owner Owner address of the token.
     * @param tokenId token Id.
     */
    event MarketTransaction(string TxType, address owner, uint256 tokenId);

    /**
     * @dev Function for exhibiting a token for sale.
     *
     * Requirements:
     *
     * - `_price` cannot be 0.
     * - `_tokenIdToOffer[_tokenId].price` must be 0, which mean that there is no offer for this token yet.
     *
     * @param _price The price in wei that the seller wants to receive for this token.
     * @param _tokenId Id of the token for sale.
     *
     * Emits a {MarketTransaction} event of type `Create offer`.
     */
    function setOffer(uint256 _price, uint256 _tokenId) public {
        require(_price != 0, "Price cannot be zero");
        require(_tokenIdToOffer[_tokenId].price == 0, "You can't sell twice the same offers");
        Offer memory _offer = Offer({seller: payable(msg.sender), price: _price, tokenId: _tokenId});
        _tokenIdToOffer[_tokenId] = _offer;
        _offers.push(_offer);
        uint256 index = _offers.length - 1;
        _tokenIdToOfferId[_tokenId] = index;
        emit MarketTransaction("Create offer", msg.sender, _tokenId);
    }

    /**
     * @dev Function to remove from the sale a specific token.
     *
     * Requirements:
     *
     * - `ownerOf(_tokenId)` must be `msg.sender`.
     * - `offer.seller` must be `msg.sender`, which mean that only the seller can remove the offer.
     *
     * @param _tokenId Id of the token to be removed from sales.
     *
     * Emits a {MarketTransaction} event of type `Remove offer`.
     */
    function removeOffer(uint256 _tokenId) public {
        require(ownerOf(_tokenId) == msg.sender, "The user doesn't own this token");
        Offer memory offer = _tokenIdToOffer[_tokenId];
        require(offer.seller == msg.sender, "No such offer exists");
        _offers[_tokenIdToOfferId[_tokenId]] = _offers[_offers.length - 1];
        _offers.pop();
        delete _tokenIdToOffer[_tokenId];
        _approve(msg.sender, _tokenId);
        emit MarketTransaction("Remove offer", msg.sender, _tokenId);
    }

    /**
     * @dev Function to buy a token available for purchase.
     *
     * Requirements:
     *
     * - `msg.value` must be `offer.price`, which means the buyer has to pay the exact price to the seller.
     *
     * @param _tokenId Id of the token to be purchased.
     *
     * Emits a {MarketTransaction} event of type `Buy`.
     */
    function buyRobot(uint256 _tokenId) public payable {
        Offer memory offer = _tokenIdToOffer[_tokenId];
        require(msg.value == offer.price, "The price is not correct");
        _offers[_tokenIdToOfferId[_tokenId]] = _offers[_offers.length - 1];
        _offers.pop();
        delete _tokenIdToOffer[_tokenId];
        _approve(msg.sender, _tokenId);
        transferFrom(offer.seller, msg.sender, _tokenId);
        offer.seller.transfer(msg.value);
        emit MarketTransaction("Buy", msg.sender, _tokenId);
    }

    /**
     * @dev Returns Offer data by providing token Id.
     */
    function getOffer(uint256 _tokenId)
        public
        view
        returns (
            address payable seller,
            uint256 price,
            uint256 tokenId
        )
    {
        Offer storage offer = _tokenIdToOffer[_tokenId];
        return (offer.seller, offer.price, offer.tokenId);
    }

    /**
     * @dev Returns all available tokens for sale.
     */
    function getAllTokensOnSale() public view returns (uint256[] memory listOfToken) {
        uint256 totalOffers = _offers.length;
        if (totalOffers == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory resultOfToken = new uint256[](totalOffers);
            uint256 offerId;
            for (offerId = 0; offerId < totalOffers; offerId++) {
                if (_offers[offerId].price != 0) {
                    resultOfToken[offerId] = _offers[offerId].tokenId;
                }
            }
            return resultOfToken;
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
pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

/**
 * @title RobotFactory contract.
 * NOTE: The contract inherits from the openzeppelin ERC721 contract and implements the basic function of creating a robot.
 * @dev The contract is the base for the RobotCore contract and contains a robot object.
 */
contract RobotFactory is ERC721("TechnoirClub", "NOIR") {
    struct Robot {
        uint64 robotId;
        uint64 buildTime;
        uint64 firstRobotParentId;
        uint64 secondRobotParentId;
        uint32 generation;
        uint32 tokenId;
    }

    Robot[] internal _robots;

    /**
     * @dev Emitted when new robot is build.
     * @param owner Robot owner.
     * @param robotId If of this robot.
     * @param firstRobotParentId Id of first 'parent' robot.
     * @param secondRobotParentId Id of first 'seconf' robot.
     * @param generation Generation of new robot.
     */
    event Build(
        address owner,
        uint64 buildTime,
        uint64 robotId,
        uint64 firstRobotParentId,
        uint64 secondRobotParentId,
        uint32 generation,
        uint32 tokenId
    );

    /**
     * @dev This is the base internal function for minting a new robot. It used in RobotCore when createRobotGen0()
     * or modify() functions are called.
     * @param id_ Fifteen-digit number id of new robot.
     * @param firstRobotParentId_ Robot Id of first 'Parent' robot.
     * @param secondRobotParentId_ Robot Id of second 'Parent' robot.
     * @param generation_ Generation of new robot.
     * @param owner_ Owner address of the token.
     *
     * Emits a {Build} event.
     */
    function _createRobot(
        uint64 id_,
        uint64 firstRobotParentId_,
        uint64 secondRobotParentId_,
        uint32 generation_,
        address owner_
    ) internal returns (uint256) {
        uint32 tokenId_ = uint32(_robots.length);
        uint64 builTime_ = uint64(block.timestamp);
        Robot memory _robot = Robot({
            robotId: id_,
            buildTime: builTime_,
            firstRobotParentId: firstRobotParentId_,
            secondRobotParentId: secondRobotParentId_,
            generation: generation_,
            tokenId: tokenId_
        });
        _robots.push(_robot);
        emit Build(owner_, builTime_, id_, firstRobotParentId_, secondRobotParentId_, uint32(generation_), tokenId_);
        _safeMint(msg.sender, tokenId_, "");
        return tokenId_;
    }

    /**
     * @dev Function to check all tokens belonging to a specific address. The function returns empty array
     * if the address does not own any token.
     * @param owner_ Address to be verified.
     */
    function tokensOfOwner(address owner_) external view returns (uint256[] memory ownerTokens) {
        uint256 tokenCount = balanceOf(owner_);
        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 totalRobots = totalSupply();
            uint256 resultIndex = 0;
            for (uint256 tokenId = 0; tokenId <= totalRobots; tokenId++) {
                if (ownerOf(tokenId) == owner_) {
                    result[resultIndex] = tokenId;
                    resultIndex++;
                }
            }
            return result;
        }
    }

    /**
     * @dev Returns all minted robot - tokens.
     */
    function totalSupply() public view returns (uint256) {
        return _robots.length - 1;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/ERC721.sol)

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
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: invalid token ID");
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
        _requireMinted(tokenId);

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
            "ERC721: approve caller is not token owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

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
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");

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
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
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
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
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
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
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
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
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
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
                /// @solidity memory-safe-assembly
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
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