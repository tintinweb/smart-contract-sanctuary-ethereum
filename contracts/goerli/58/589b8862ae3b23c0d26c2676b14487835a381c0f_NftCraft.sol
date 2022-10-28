/**
 *Submitted for verification at Etherscan.io on 2022-10-28
*/

/**
 *Submitted for verification at Etherscan.io on 2022-07-18
*/

/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface CollectionInterface {
    function mintWithTokenURI(address to, string calldata tokenURI, uint256 quantity, bool flag) external returns (bool);
    function mintWithTokenURI(address to, uint256 tokenId, string calldata tokenURI) external returns (bool);
    function transferFrom(address from, address to, uint256 tokenId) external;
    function tokenURI(uint256 tokenId) external view returns (string memory);
    function getTotalSells() view external returns(uint256);
    function burnAdmin(uint256 tokenId) external;
    function mint(address to_, uint256 countNFTs_) external returns (uint256, uint256);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
}

// File: @openzeppelin/contracts/utils/math/SafeMath.sol
// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol
/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// File: contracts/NftCraft.sol
/**
 * @title Nft Box Contract
 * @author NoBorderz
 * @dev It is NftCraft smartcontract, enabling NFT holders to crafe new NFTs or powerup their existing NFTs.
 * Artist/Creaters of NFTs can get their ERC721 MetadataMintable & Burnable NFT smartcontacts listed as collections on it.
 * These artists/creaters can list rules of Burn&Craft of their collections.
 * NFT holders using those rules will be Crafting or powerup their NFTs.
 */
contract NftCraft is ReentrancyGuard {
    using SafeMath for uint256;

    /******************* Constructor **********************/
    constructor() {
        craftAdmin = msg.sender;
    }

    /******************* Events **********************/
    event Collection(address indexed nftContract, address collectionAdmin);
    event CollectionRemoved(address indexed collection);
    event CollectionUpdated(address indexed collection, address collectionAdmin);
    event CraftRule(address indexed collection, uint256 indexed ruleId, string name, uint256 series);
    event RuleRemoved(address indexed collection, uint256 indexed ruleId);
    event RuleUpdated(address indexed collection, uint256 indexed ruleId, string name, uint256 series);
    event BurnNft(address indexed collection, uint256 indexed ruleId, string tokenURI);
    event CraftNft(address indexed collection, uint256 ruleId, string tokenURI, uint256 percent);
    event CraftNftRemoved(address indexed collection, uint256 ruleId, string tokenURI);
    event Crafted(address indexed collection, uint256 indexed ruleId, string craftedTokenURI, address crafter, uint256[] burnTokenIds);
    event RequestPowerup(address indexed requester, uint256 requestId, address collection, uint256[] tokenIds);
    event Powerup(address indexed owner, uint256 requestId, uint256[] requestedTokenIds);

    /******************* Modifiers **********************/
    /**
     * @dev modifier to ensure/protect caller of the function is admin of given collection.
     * @param _collection address of collection whose admin to be verified.
     */
    modifier onlyCollectionAdmin(address _collection) {
        require(collections[_collection] == msg.sender, "not collection admin");
        _;
    }

    /**
     * @dev modifier to ensure/protect caller of the function is admin of NFT Craft contract.
     */
    modifier onlyCraftAdmin() {
        require(msg.sender == craftAdmin, "not craft admin");
        _;
    }

    /**
     * @dev modifier to ensure/protect caller of the function is validator.
     */
    modifier onlyValidator() {
        require(msg.sender == validatorAddress, "not validation admin");
        _;
    }

    /******************* State variables **********************/
    address internal craftAdmin;
    address internal xanaliaDEX;
    address internal validatorAddress;
    bool internal isCraftInitialized;

    /// @notice Struct for storing rules
    struct Rule {
        mapping(uint256 => Nft) burn;
        mapping(uint256 => Nft) craft;
        uint256 toBeBurnt;
        uint256 toBeCrafted;
        uint256 series;
        string name;
    }

    /// @notice Struct for storing Nft info
    struct Nft {
        address nftContract; // to allow cross smartcontracts NFTs burn/craft in future
        string tokenURI;
        uint256 percentage;
    }

    // nftContract/collection => id => Rule
    mapping(address => mapping(uint256 => Rule)) public rules;

    /// @notice Mapping for storing collection address against adminn address
    mapping(address => address) public collections;

    /// @notice Mapping for storing collection adress against ruleId
    mapping(address => uint256) private colIds;

    /// @notice Mapping for storing collection address against ruleId against its percentage
    mapping(address => mapping(uint256 => uint256)) private rulePercents;

    // collection => ruleId => nftId
    mapping(uint256 => mapping(address => uint256)) private rarestNFT;

    // tokenURIs => flag
    mapping(string => bool) private tokenURIs;

    /// @notice struct for storing info about powerup requests
    struct powerupRequest {
        address requester;
        uint256[] tokenIds;
        address collection;
        bool fulfilled;
    }

    /// @notice requests counter
    uint256 private totalPowerupRequests;

    /// @notice Store powerup requests of user address against request Id
    mapping(uint256 => powerupRequest) private powerupRequests;

    /// @notice Array for storing user current requests
    uint256[] private activeUserRequests;

    /// @notice Mapping for storing index of requestIds in activeUserRequests
    mapping(uint256 => uint256) private activeUserRequestsIndex;

    /// @notice Mapping for storing user tokens that are requested to powerup
    mapping(address => mapping(uint256 => bool)) private powerupRequestTokens;


    /******************* Public Methods **********************/
    // for proxy:
    function initNftCraft() public {
        require(!isCraftInitialized, "nftCraft contract already initialized");
        craftAdmin = 0x9b6D7b08460e3c2a1f4DFF3B2881a854b4f3b859; // dummy, should be revised before going live
        isCraftInitialized = true;
        xanaliaDEX = 0x9b6D7b08460e3c2a1f4DFF3B2881a854b4f3b859; // dummy, should be revised before going live
    }

    function setNFTContract(address _colAddress) external onlyCraftAdmin {
        xanaliaDEX = _colAddress;
    }

    /**
     * @dev Public Facing: function to Craft NFT as per the rule.
     * Caller should hold & approved to contract the NFTs to be burnt as per rule.
     * @param _collection Address of the collection whose rule to Craft NFT.
     * @param _ruleId Id of the rule from which NFT to be crafted.
     * @param _tokenIds List of tokenIds which are to be burnt as per rule.
     * Note:
     * 1. Crafting from a rule is only allowed if that rule is properly filled with rarity levels of NFTs.
     * Sum of rarity levels (percentage) of NFTs added in craft section of rule should be equal to 100
     * 2. Randomness is achieved through hashing of (block.timestamp, block.difficulty, block.coinbase, totalSells)
     * where totalSells is the number of latest total NFTs listed on sell on xanaliaDEX.
     * As smartcontract nature is Deterministic, so need to think more efficient solution if possible on-chain.
     */
    function burnAndCraft(address _collection, uint256 _ruleId, uint256[] memory _tokenIds) public {
        require(rulePercents[_collection][_ruleId] == 100, "rarity levels insufficient of this rule");
        uint256 _totalBurntNFTs = rules[_collection][_ruleId].toBeBurnt;
        uint256 _nftToBeCrafted = rules[_collection][_ruleId].toBeCrafted;
        string memory _uri;
        string memory _craftedURI;

        require(_tokenIds.length == rules[_collection][_ruleId].toBeBurnt, "less tokenIds to be burnt as per rule selected");

        for (uint256 i = 1; i <= _totalBurntNFTs; i++) {
            tokenURIs[rules[_collection][_ruleId].burn[i].tokenURI] = true;
        }

        // check if the tokenUris of the given tokenIds are
        // same as specified in the rule and then burn them
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            _uri = CollectionInterface(_collection).tokenURI(_tokenIds[i]);
            require(tokenURIs[_uri], "invalid tokenId to burn");

            CollectionInterface(_collection).burnAdmin(_tokenIds[i]);
            delete tokenURIs[_uri];
            _uri = "null";
        }

        uint256 _rnd = CollectionInterface(xanaliaDEX).getTotalSells();
        
        if (_nftToBeCrafted > 1) {
            uint256 index = 0;
            uint256[] memory rarityArray = new uint256[](100);

            // deciding how much percentage a nft has in total
            for (uint256 i = 1; i <= _nftToBeCrafted; i++) {
                for (uint256 j = 1; j <= rules[_collection][_ruleId].craft[i].percentage; j++) {
                    rarityArray[index] = i;
                    index++;
                }
            }

            // shuffling the rarity array
            rarityArray = shuffle(rarityArray);

            // selecting first index from the shuffled rarity array
            _craftedURI = rules[_collection][_ruleId].craft[rarityArray[0]].tokenURI;

            if (_collection == xanaliaDEX)
                CollectionInterface(xanaliaDEX).mintWithTokenURI(msg.sender, _craftedURI, 1, true);
            else {
                // Generate a random token Id
                uint256 tokenId = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, block.coinbase, _rnd))) % 10000000000;
                CollectionInterface(_collection).mintWithTokenURI(
                    msg.sender,
                    tokenId,
                    _craftedURI
                );
            }
        } else {
            _craftedURI = rules[_collection][_ruleId].craft[_nftToBeCrafted].tokenURI;
            if (_collection == xanaliaDEX)
                CollectionInterface(xanaliaDEX).mintWithTokenURI(msg.sender, _craftedURI, 1, true);
            else {
                // Generate a random token Id
                uint256 tokenId = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, block.coinbase, _rnd))) % 10000000000;
                CollectionInterface(_collection).mintWithTokenURI(msg.sender, tokenId, _craftedURI);
            }
        }
        emit Crafted(_collection, _ruleId, _craftedURI, msg.sender, _tokenIds);
    }

    /**
     * @dev PUBLIC Facing: Request powerup for tokens
     * @param _collection Address of the collection the tokens are from.
     * @param _tokenIds List of tokenIds which are to be combined to powerup.
     * Note: The request will be validated from BE(Moralis) before the user
     * can go ahead and actually combine the tokens to get a poweredup version.
     */
    function requestPowerup(address _collection, uint256[] memory _tokenIds) external nonReentrant returns (uint256) {
        require(_tokenIds.length == 2, "only 2 tokens are allowed");

        // make sure tokens are not already requested for powerup by owner
        require(powerupRequestTokens[msg.sender][_tokenIds[0]] == false, "token already requested for powerup");
        require(powerupRequestTokens[msg.sender][_tokenIds[1]] == false, "token already requested for powerup");

        // make sure the requester in the owner of the tokenIds
        require(CollectionInterface(_collection).ownerOf(_tokenIds[0]) == msg.sender, "not owner of token");
        require(CollectionInterface(_collection).ownerOf(_tokenIds[1]) == msg.sender, "not owner of token");

        // increment total requests by 1
        totalPowerupRequests += 1;

        // create and store a powerup request
        powerupRequests[totalPowerupRequests] = powerupRequest(msg.sender, _tokenIds, _collection, false);

        // add powerup requestId to activeUserRequests array
        activeUserRequests.push(totalPowerupRequests);

        // store index of powerup requestId in activeUserRequests array
        activeUserRequestsIndex[totalPowerupRequests] = activeUserRequests.length.sub(1);

        // set requested to true so owner cannot request powerup for same tokens again
        powerupRequestTokens[msg.sender][_tokenIds[0]] = true;
        powerupRequestTokens[msg.sender][_tokenIds[1]] = true;

        // Escrow tokens to the backend address
        CollectionInterface(_collection).safeTransferFrom(msg.sender, validatorAddress, _tokenIds[0]);
        CollectionInterface(_collection).safeTransferFrom(msg.sender, validatorAddress, _tokenIds[1]);

        emit RequestPowerup(msg.sender, totalPowerupRequests, _collection, _tokenIds);
        return totalPowerupRequests;
    }

    /******************* ADMIN Methods **********************/
    /**
     * @dev ADMIN Method: Set powerup requests validator
     * @param _validator Address of the validator
     */
    function setValidator(address _validator) external onlyCraftAdmin {
        validatorAddress = _validator;
    }

    /**
     * @dev ADMIN Method: Powerup tokens
     * @param _requestId Id of the powerup request
     */
    function validatePowerupRequest(uint256 _requestId, bool resp) external nonReentrant onlyValidator {
        powerupRequest storage powerupInfo = powerupRequests[_requestId];

        // remove tokens from requested list
        powerupRequestTokens[powerupInfo.requester][powerupInfo.tokenIds[0]] = false;
        powerupRequestTokens[powerupInfo.requester][powerupInfo.tokenIds[1]] = false;

        // remove user request from active requests array
        if (activeUserRequests.length > 1) {
            activeUserRequests[activeUserRequestsIndex[_requestId]] = activeUserRequests[activeUserRequests.length.sub(1)];
            activeUserRequests.pop();
        } else {
            activeUserRequests.pop();
        }

        if (resp == true) {
            powerupInfo.fulfilled = true;

            CollectionInterface(powerupInfo.collection).burnAdmin(powerupInfo.tokenIds[0]);

            emit Powerup(msg.sender, _requestId, powerupInfo.tokenIds);
        }
    }

    /**
     * @dev function to register new Rule of given collection,
     * through this rule NFT holders of that collection will be able to Burn&Craft.
     * @param _name Name of the new Rule.
     * @param _series Series of the Rule.
     * @param _collection Collection/nftContract to whom this rule belongs.
     */
    function newRule(string memory _name, uint256 _series, address _collection) external onlyCollectionAdmin(_collection) {
        require(bytes(_name).length != 0 && _series != 0 && _collection != address(0), "invalid rule");
        uint256 _ruleId = ++colIds[_collection];
        rules[_collection][_ruleId].name = _name;
        rules[_collection][_ruleId].series = _series;
        emit CraftRule(_collection, _ruleId, _name, _series);
    }

    /**
     * @dev function to remove rule.
     * only collection admin can perform this action.
     * @param _ruleId Id of the rule to be removed.
     * @param _collection address of collection whose rule to be removed.
     */
    function removeRule(uint256 _ruleId, address _collection) external onlyCollectionAdmin(_collection) {
        require(bytes(rules[_collection][_ruleId].name).length != 0, "Rule doesn't exists");
        delete rules[_collection][_ruleId];
        emit RuleRemoved(_collection, _ruleId);
    }

    /**
     * @dev function to update rule.
     * only collection's admin can perform this action.
     * @param _name Name to the Rule
     * @param _series Series of the Rule
     * @param _collection Address of the collection
     * @param _ruleId Id of the rule to be updated.
     */
    function updateRule( string memory _name, uint256 _series, address _collection, uint256 _ruleId) public onlyCollectionAdmin(_collection) {
        require(bytes(rules[_collection][_ruleId].name).length != 0, "Rule doesn't exists");
        rules[_collection][_ruleId].name = _name;
        rules[_collection][_ruleId].series = _series;
        emit RuleUpdated(_collection, _ruleId, _name, _series);
    }

    /**
     * @dev function to register new collection/nftContract,
     * so it can be supported by NftCraft to define Rules and its NFT holders can Burn&Craft through it.
     * @param _nftContract address of ERC721 MetadataMintable & Burnable smartcontract.
     * @param _collectionAdmin address of account who will be performing admin level tasks here for this collection.
     */
    function addCollection(address _nftContract, address _collectionAdmin) public onlyCraftAdmin {
        require(_nftContract != address(0) && _collectionAdmin != address(0), "invalid collection");
        collections[_nftContract] = _collectionAdmin;
        emit Collection(_nftContract, _collectionAdmin);
    }

    /**
     * @dev function to remove supported collection from the contract.
     * only nftCraft admin can perform this action.
     * @param _nftContract address of collection to be removed.
     */
    function removeCollection(address _nftContract) external onlyCraftAdmin {
        require(collections[_nftContract] != address(0), "invalid collection");
        delete collections[_nftContract];
        emit CollectionRemoved(_nftContract);
    }

    /**
     * @dev function to update supported collection.
     * only collection admin can perform this action. He can transfer collection's admin rights to someone else here.
     * @param _nftContract address of collection to be updated.
     * @param _collectionAdmin address of new admin of this collection.
     */
    function updateCollection(address _nftContract, address _collectionAdmin) external onlyCollectionAdmin(_nftContract) {
        require(collections[_nftContract] != address(0) && _collectionAdmin != address(0), "invalid collection");
        collections[_nftContract] = _collectionAdmin;
        emit CollectionUpdated(_nftContract, _collectionAdmin);
    }

    /**
     * @dev function to add NFT(tokenURI) which will be required to be burnt in given rule.
     * only collection's admin can perform this action.
     * @param _collection Address of the collection whose rule's burn tokenURI to be added.
     * @param _ruleId Id of the rule in which burn tokenURI to be added.
     * @param _tokenURI Metadata URI of NFT to be added.
     */
    function addBurnNft(address _collection, uint256 _ruleId, string memory _tokenURI) public onlyCollectionAdmin(_collection) {
        require(bytes(rules[_collection][_ruleId].name).length != 0, "Rule doesn't exists");
        require(bytes(_tokenURI).length != 0, "invalid tokenURI");
        uint256 _burnId = ++rules[_collection][_ruleId].toBeBurnt;
        rules[_collection][_ruleId].burn[_burnId].tokenURI = _tokenURI;

        emit BurnNft(_collection, _ruleId, _tokenURI);
    }

    /**
     * @dev function to add NFT(tokenURI) which to be crafted in given rule.
     * only collection's admin can perform this action.
     * @param _collection Address of the collection whose rule's craft tokenURI to be added.
     * @param _ruleId Id of the rule in which craft tokenURI to be added.
     * @param _tokenURI Metadata URI of NFT to be added.
     * @param _rarityPercent Percentage/Level of rarity of tokenURI to be crafted. (rarity should be given in percentage e.g 1%, 50% or 100%)
     */
    function addCraftNft(address _collection, uint256 _ruleId, string memory _tokenURI, uint256 _rarityPercent) public onlyCollectionAdmin(_collection) {
        require(bytes(rules[_collection][_ruleId].name).length != 0, "Rule doesn't exists");
        require(bytes(_tokenURI).length != 0, "invalid tokenURI");
        require(_rarityPercent > 0 && _rarityPercent <= 100, "invalid percentage");

        // Check rule's total percentage
        rulePercents[_collection][_ruleId] = rulePercents[_collection][_ruleId].add(_rarityPercent);
        require(rulePercents[_collection][_ruleId] <= 100, "Rule's combined percentage exceeds 100%");

        uint256 _craftId = ++rules[_collection][_ruleId].toBeCrafted;
        rules[_collection][_ruleId].craft[_craftId].tokenURI = _tokenURI;
        rules[_collection][_ruleId].craft[_craftId].percentage = _rarityPercent;

        emit CraftNft(_collection, _ruleId, _tokenURI, _rarityPercent);
    }

    /**
     * @dev function to remove Craft NFT(tokenURI) from given rule of mentioned collection.
     * only collection's admin can perform this action.
     * @param _collection Address of the collection whose rule's craft tokenURI to be removed.
     * @param _ruleId Id of the rule from which craft tokenURI to be removed.
     * @param _tokenURI Metadata URI of NFT to be removed.
     */
    function removeCraftNft(address _collection, uint256 _ruleId, string memory _tokenURI) public onlyCollectionAdmin(_collection) {
        require(bytes(rules[_collection][_ruleId].name).length != 0, "Rule doesn't exists");
        require(bytes(_tokenURI).length != 0, "invalid tokenURI");
        uint256 _craftId;

        // check if tokenURI exists
        for (uint256 i = 1; i <= rules[_collection][_ruleId].toBeCrafted; i++) {
            if (
                keccak256(
                    abi.encode(rules[_collection][_ruleId].craft[i].tokenURI)
                ) == keccak256(abi.encode(_tokenURI))
            ) {
                _craftId = i;
                break;
            }
        }
        require(bytes(rules[_collection][_ruleId].craft[_craftId].tokenURI).length != 0, "tokenURI doesn't exists");

        // percent check
        rulePercents[_collection][_ruleId] = rulePercents[_collection][_ruleId].sub(rules[_collection][_ruleId].craft[_craftId].percentage);
        delete rules[_collection][_ruleId].craft[_craftId];

        // updating crafts by moving them to the left one by one (can be done through switching places aswell)
        if (_craftId != rules[_collection][_ruleId].toBeCrafted) {
            for (uint256 j = _craftId; j < rules[_collection][_ruleId].toBeCrafted; j++) {
                rules[_collection][_ruleId].craft[j] = rules[_collection][_ruleId].craft[j + 1];
            }
        }
        --rules[_collection][_ruleId].toBeCrafted;

        emit CraftNftRemoved(_collection, _ruleId, _tokenURI);
    }

    /******************* Private Methods **********************/
    /**
     * @dev Internal Utility function to shuffle tokenURIs indexes, So crafted NFT can be random.
     * @param numberArray array to be shuffled.
     */
    function shuffle(uint256[] memory numberArray)
        private
        view
        returns (uint256[] memory)
    {
        uint256 _rnd = CollectionInterface(xanaliaDEX).getTotalSells();
        for (uint256 i = 0; i < numberArray.length; i++) {
            uint256 n = i +
                (uint256(
                    keccak256(
                        abi.encodePacked(
                            block.timestamp,
                            block.difficulty,
                            block.coinbase,
                            _rnd
                        )
                    )
                ) % (numberArray.length - i)); // should also include last traded nft e/g sellList.length
            uint256 temp = numberArray[n];
            numberArray[n] = numberArray[i];
            numberArray[i] = temp;
        }
        return numberArray;
    }
}