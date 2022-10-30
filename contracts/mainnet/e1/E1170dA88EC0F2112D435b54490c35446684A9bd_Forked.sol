// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface Forkers {
    function getAttributePointsFor(address _address) external view returns (uint64);
    function spendAttributePoints(address _address) external;
    function DIEFORKER(uint256 token) external;
}

contract Forked is Ownable, ReentrancyGuard {

    event TraitAdded(TRAIT_TYPE traitType, uint64 cost, uint8 id, uint16 powerLevel);
    event ForkerBurned(uint256 token, uint64 points, address burner);
    event ForkerUpgraded(uint256 token);
    event yumyum(uint256 goblin, uint256 token, uint16 powerLevel, uint64 burnValue);
    event HerLight(uint256 wagdie, uint256 token, uint16 powerLevel, uint64 burnValue);

    error InvalidTrait(TRAIT_TYPE traitType, uint8 id);

    enum TRAIT_TYPE { BACKGROUND, BACK, FEET, SKIN, HEAD, ARMS, EXTRA, EXTRA2, EXTRA3 }

    address public forkerAddress = 0xb0EdA4f836aF0F8Ca667700c42fcEFA0742ae2B5;
    address public GOBLIN_TOWN_CONTRACT = 0xbCe3781ae7Ca1a5e050Bd9C4c77369867eBc307e;
    address public WAGDIE_CONTRACT = 0x659A4BdaAaCc62d2bd9Cb18225D9C89b5B697A5A;

    uint8 public maxExtremelyRares = 5;
    uint64 public extremelyRareCost = 500;
    uint16 public maxPowerLevelToBurn = 10;
    uint16 public burnStage = 0;
    
    bool public hungryGoblins = false;
    bool public herLightIsLow = false;

    mapping(uint256 => TokenData) private tokenToData;
    mapping(address => uint64) private attributePoints;
    mapping(TRAIT_TYPE => mapping(uint8 => TraitData)) public traitData;
    mapping(uint8 => bool) public extremelyRareClaimed;
    mapping(uint256 => mapping(uint256 => bool)) public hasGoblinAte;
    mapping(uint256 => mapping(uint256 => bool)) public hasWagdieBurnt;
    
    struct TraitData {
        uint16 powerLevel;
        uint64 cost;
    }

    struct TokenData {
        uint8 background;
        uint8 back;
        uint8 feet;
        uint8 skin;
        uint8 head;
        uint8 arms;
        uint8 extra;
        uint8 extra2;
        uint8 extra3;
        uint8 extremelyRare;
        bool usedBasePoints;
        uint64 pointsSpent;
        uint16 powerLevel;
    }

    constructor() {

        addTrait(TRAIT_TYPE.BACKGROUND, 0, 0, 0);
        addTrait(TRAIT_TYPE.BACKGROUND, 1, 5, 15);
        addTrait(TRAIT_TYPE.BACKGROUND, 2, 10, 35);
        
        addTrait(TRAIT_TYPE.BACK, 0, 0, 0);
        addTrait(TRAIT_TYPE.BACK, 1, 5, 15);
        addTrait(TRAIT_TYPE.BACK, 2, 8, 35);
        addTrait(TRAIT_TYPE.BACK, 3, 15, 80);
        addTrait(TRAIT_TYPE.BACK, 4, 25, 150);
        addTrait(TRAIT_TYPE.BACK, 5, 40, 350);
        addTrait(TRAIT_TYPE.BACK, 6, 75, 475);
        addTrait(TRAIT_TYPE.BACK, 7, 125, 1000);

        addTrait(TRAIT_TYPE.FEET, 0, 0, 0);
        addTrait(TRAIT_TYPE.FEET, 1, 5, 20);
        addTrait(TRAIT_TYPE.FEET, 2, 20, 175);
        addTrait(TRAIT_TYPE.FEET, 3, 75, 250);
        
        addTrait(TRAIT_TYPE.SKIN, 0, 0, 0);
        addTrait(TRAIT_TYPE.SKIN, 1, 5, 50);
        addTrait(TRAIT_TYPE.SKIN, 2, 10, 100);
        addTrait(TRAIT_TYPE.SKIN, 3, 40, 350);
        addTrait(TRAIT_TYPE.SKIN, 4, 60, 750);
        addTrait(TRAIT_TYPE.SKIN, 5, 120, 1500);
        addTrait(TRAIT_TYPE.SKIN, 6, 200, 2500);

        addTrait(TRAIT_TYPE.HEAD, 0, 0, 0);
        addTrait(TRAIT_TYPE.HEAD, 1, 5, 30);
        addTrait(TRAIT_TYPE.HEAD, 2, 15, 80);
        addTrait(TRAIT_TYPE.HEAD, 3, 20, 200);
        addTrait(TRAIT_TYPE.HEAD, 4, 35, 400);
        addTrait(TRAIT_TYPE.HEAD, 5, 50, 600);
        addTrait(TRAIT_TYPE.HEAD, 6, 70, 800);
        addTrait(TRAIT_TYPE.HEAD, 7, 100, 1000);
        addTrait(TRAIT_TYPE.HEAD, 8, 125, 1400);
        addTrait(TRAIT_TYPE.HEAD, 9, 150, 2000);
        addTrait(TRAIT_TYPE.HEAD, 10, 200, 2500);

        addTrait(TRAIT_TYPE.ARMS, 0, 0, 0);
        addTrait(TRAIT_TYPE.ARMS, 1, 5, 10);
        addTrait(TRAIT_TYPE.ARMS, 2, 10, 30);
        addTrait(TRAIT_TYPE.ARMS, 3, 15, 50);
        addTrait(TRAIT_TYPE.ARMS, 4, 25, 100);
        
        
    }

    function buyTraits(uint256 token, TRAIT_TYPE[] calldata traitTypes, uint8[] calldata traitIds) public nonReentrant {
        require(IERC721(forkerAddress).ownerOf(token) == msg.sender, "Not owner");
        require(traitTypes.length == traitIds.length, "Inputs invalid");

        TokenData storage tokenData = tokenToData[token];

        require(tokenData.extremelyRare == 0, "Can't upgrade a 1/1");

        uint64 toSpend = 0;
        uint16 newPowerLevel = tokenData.powerLevel;

        for(uint i = 0; i < traitTypes.length; i++) {
            uint64 spent = 0;
            uint16 newPower = 0;

            (spent, newPower) = _changeTokenTrait(traitTypes[i], traitIds[i], tokenData, newPowerLevel);

            newPowerLevel = newPower;
            toSpend += spent;
        }

        _claimBasePoints(tokenData);
        
        _spendAttributePoints(msg.sender, toSpend);

        tokenData.pointsSpent += toSpend;
        tokenData.powerLevel = newPowerLevel;

        emit ForkerUpgraded(token);

    }

    function _claimBasePoints(TokenData storage data) internal {
        if(data.usedBasePoints == false) {
            data.usedBasePoints = true;

            attributePoints[msg.sender] += 5;
        }
    }

    function buyExtremelyRare(uint256 token, uint8 trait) public nonReentrant {
        require(IERC721(forkerAddress).ownerOf(token) == msg.sender, "Not owner");
        require(trait != 0 && trait <= maxExtremelyRares, "Invalid input");
        require(!extremelyRareClaimed[trait], "Already claimed");

        TokenData storage tokenData = tokenToData[token];

        require(tokenData.extremelyRare == 0, "Already rare");

        _claimBasePoints(tokenData);

        _spendAttributePoints(msg.sender, extremelyRareCost);

        extremelyRareClaimed[trait] = true;
        tokenData.extremelyRare = trait;
        tokenData.pointsSpent += extremelyRareCost;

        tokenData.powerLevel = 50000;

        extremelyRareCost += 200;

        emit ForkerUpgraded(token);

    }

    function burnForkers(uint256[] calldata tokens) public nonReentrant {
        uint64 attributeReward = 0;

        for(uint i = 0; i < tokens.length; i++)
            attributeReward += _burnForker(tokens[i]);

        attributePoints[msg.sender] += attributeReward;
    }

    function getTokenData(uint256 token) external view returns (TokenData memory tokenData) {
        return tokenToData[token];
    }

    function getAttributeData(address _address) external view returns (uint64) {
        uint64 refPoints = Forkers(forkerAddress).getAttributePointsFor(_address);

        return attributePoints[_address] + refPoints;
    }

    function _burnForker(uint256 token) internal returns (uint64) {
        require(IERC721(forkerAddress).ownerOf(token) == msg.sender, "Not owner");
        
        Forkers(forkerAddress).DIEFORKER(token);

        TokenData memory tokenData = tokenToData[token];

        require(tokenData.extremelyRare == 0, "Can't burn 1/1");
        
        uint64 attributeReward = tokenData.pointsSpent + 5;

        if(!tokenData.usedBasePoints) attributeReward += 5;

        emit ForkerBurned(token, attributeReward, msg.sender);

        return attributeReward;
    }

    function getExtremelyRares() external view returns (bool[] memory, uint64 cost) {
        bool[] memory rares = new bool[] (maxExtremelyRares);

        for(uint8 i = 0; i < maxExtremelyRares; i++) {
            uint8 trait = i + 1;
            bool claimed = extremelyRareClaimed[trait];

            rares[i] = claimed;
        }

        return (rares, extremelyRareCost);
    }

    function _getAttributePoints(address _address) internal returns (uint64) {
        //Grab owed attribute points from referral system.
        uint64 refPoints = Forkers(forkerAddress).getAttributePointsFor(_address);

        //If any exist remove and add to this contract.
        if(refPoints > 0) {
            Forkers(forkerAddress).spendAttributePoints(_address);
            attributePoints[_address] += refPoints;
        }

        return attributePoints[_address];
    }

    function _spendAttributePoints(address _address, uint64 amount) internal {
        uint64 myPoints = _getAttributePoints(_address);
        require(myPoints >= amount, "Not enough points");

        attributePoints[_address] -= amount;
    }

    function yummyyummy(uint256 goblin, uint256 forker) public nonReentrant {
        require(IERC721(GOBLIN_TOWN_CONTRACT).ownerOf(goblin) == msg.sender, "u dont tell me wat to do");
        require(!hasGoblinAte[burnStage][goblin], "me full");
        require(hungryGoblins, "not hungry right now");
        hasGoblinAte[burnStage][goblin] = true;
        require(!_isForkerProtected(forker), "Forker is protected");

        TokenData memory data = tokenToData[forker];

        require(data.powerLevel <= maxPowerLevelToBurn, "dis not fit in mouth");
        Forkers(forkerAddress).DIEFORKER(forker);

        uint64 howtastey = data.pointsSpent + (!data.usedBasePoints ? 5 : 0);

        attributePoints[msg.sender] += howtastey;

        emit yumyum(goblin, forker, data.powerLevel, howtastey);
    }

    function herLight(uint256 wagdie, uint256 forker) public nonReentrant {
        require(IERC721(WAGDIE_CONTRACT).ownerOf(wagdie) == msg.sender, /* 𝕴 𝖉𝖔 𝖓𝖔𝖙 𝖑𝖎𝖘𝖙𝖊𝖓 𝖙𝖔 𝖞𝖔𝖚 */ "Not owner");
        require(!hasWagdieBurnt[burnStage][wagdie], /* 𝕴 𝖍𝖆𝖛𝖊 𝖉𝖔𝖓𝖊 𝖊𝖓𝖔𝖚𝖌𝖍 𝖋𝖔𝖗 𝖍𝖊𝖗 𝖑𝖎𝖌𝖍𝖙 */ "Already burnt");
        require(herLightIsLow, /* 𝕳𝖊𝖗 𝖑𝖎𝖌𝖍𝖙 𝖎𝖘 𝖌𝖑𝖔𝖜𝖎𝖓𝖌 𝖘𝖙𝖗𝖔𝖓𝖌 */ "Not yet");
        hasWagdieBurnt[burnStage][wagdie] = true;
        require(!_isForkerProtected(forker), "Forker is protected");

        TokenData memory data = tokenToData[forker];

        require(data.powerLevel <= maxPowerLevelToBurn, /* 𝕴 𝖈𝖆𝖓𝖓𝖔𝖙 𝖈𝖆𝖙𝖈𝖍 𝖘𝖚𝖈𝖍 𝖆 𝖕𝖔𝖜𝖊𝖗𝖋𝖚𝖑 𝖈𝖗𝖊𝖆𝖙𝖚𝖗𝖊 */ "Too powerful");
        Forkers(forkerAddress).DIEFORKER(forker);

        uint64 howHot = data.pointsSpent + (!data.usedBasePoints ? 5 : 0);

        attributePoints[msg.sender] += howHot;

        emit HerLight(wagdie, forker, data.powerLevel, howHot);
    }


    function _changeTokenTrait(TRAIT_TYPE traitType, uint8 traitId, TokenData storage tokenData, uint16 currentPLevel) internal returns (uint64, uint16) {
        TraitData memory traitD = traitData[traitType][traitId];
        uint64 cost = traitD.cost;

        //Trait doesn't exist.
        if(cost == 0) revert InvalidTrait(traitType, traitId);

        if(traitType == TRAIT_TYPE.BACKGROUND) {
            uint16 currentSlotLevel = traitData[traitType][tokenData.background].powerLevel;
            uint16 newPowerLevel = (currentPLevel - currentSlotLevel) + traitD.powerLevel;

            tokenData.background = traitId;
            return (cost, newPowerLevel);
        }

        if(traitType == TRAIT_TYPE.BACK) {
            uint16 currentSlotLevel = traitData[traitType][tokenData.back].powerLevel;
            uint16 newPowerLevel = (currentPLevel - currentSlotLevel) + traitD.powerLevel;

            tokenData.back = traitId;
            return (cost, newPowerLevel);
        }

        if(traitType == TRAIT_TYPE.FEET) {
            uint16 currentSlotLevel = traitData[traitType][tokenData.feet].powerLevel;
            uint16 newPowerLevel = (currentPLevel - currentSlotLevel) + traitD.powerLevel;

            tokenData.feet = traitId;
            return (cost, newPowerLevel);
        }

        if(traitType == TRAIT_TYPE.SKIN) {
            uint16 currentSlotLevel = traitData[traitType][tokenData.skin].powerLevel;
            uint16 newPowerLevel = (currentPLevel - currentSlotLevel) + traitD.powerLevel;

            tokenData.skin = traitId;
            return (cost, newPowerLevel);
        }

        if(traitType == TRAIT_TYPE.HEAD) {
            uint16 currentSlotLevel = traitData[traitType][tokenData.head].powerLevel;
            uint16 newPowerLevel = (currentPLevel - currentSlotLevel) + traitD.powerLevel;

            tokenData.head = traitId;
            return (cost, newPowerLevel);
        }

        if(traitType == TRAIT_TYPE.ARMS) {
            uint16 currentSlotLevel = traitData[traitType][tokenData.arms].powerLevel;
            uint16 newPowerLevel = (currentPLevel - currentSlotLevel) + traitD.powerLevel;

            tokenData.arms = traitId;
            return (cost, newPowerLevel);
        }

        if(traitType == TRAIT_TYPE.EXTRA) {
            uint16 currentSlotLevel = traitData[traitType][tokenData.extra].powerLevel;
            uint16 newPowerLevel = (currentPLevel - currentSlotLevel) + traitD.powerLevel;

            tokenData.extra = traitId;
            return (cost, newPowerLevel);
        }

        if(traitType == TRAIT_TYPE.EXTRA2) {
            uint16 currentSlotLevel = traitData[traitType][tokenData.extra2].powerLevel;
            uint16 newPowerLevel = (currentPLevel - currentSlotLevel) + traitD.powerLevel;

            tokenData.extra2 = traitId;
            return (cost, newPowerLevel);
        }

        if(traitType == TRAIT_TYPE.EXTRA3) {
            uint16 currentSlotLevel = traitData[traitType][tokenData.extra3].powerLevel;
            uint16 newPowerLevel = (currentPLevel - currentSlotLevel) + traitD.powerLevel;

            tokenData.extra3 = traitId;
            return (cost, newPowerLevel);
        }

        return (cost, currentPLevel);
    }

    function _isForkerProtected(uint256 forker) public view returns (bool) {
        return IERC721(forkerAddress).ownerOf(forker) == owner();
    }

    function addTrait(TRAIT_TYPE traitType, uint8 traitId, uint64 cost, uint16 level) public onlyOwner {
        TraitData storage traitD = traitData[traitType][traitId];

        traitD.cost = cost;
        traitD.powerLevel = level;

        emit TraitAdded(traitType, cost, traitId, level);
    }

    function addAttributePoints() public onlyOwner {
        attributePoints[msg.sender] += 10000;
    }

    function setForkerAddress(address _address) public onlyOwner {
        forkerAddress = _address;
    }

    function setExtremelyRareData(uint64 cost, uint8 maxExtremely) public onlyOwner {
        extremelyRareCost = cost;
        maxExtremelyRares = maxExtremely;
    }

    function setGoblinTownAddress(address _address) public onlyOwner {
        GOBLIN_TOWN_CONTRACT = _address;
    }

    function setWagdieAddress(address _address) public onlyOwner {
        WAGDIE_CONTRACT = _address;
    }

    function incrementBurnStage() public onlyOwner {
        burnStage++;
    }

    function setBurnMechanics(bool _hungryGoblins, bool _lowLight) public onlyOwner {
        herLightIsLow = _lowLight;
        hungryGoblins = _hungryGoblins;
    }

    function setMaxPowerLevelForBurn(uint16 power) public onlyOwner {
        maxPowerLevelToBurn = power;
    }

    function adminGiveAttributePoints(address[] calldata addresses, uint64[] calldata points) public onlyOwner {

        for(uint i = 0; i < addresses.length; i++)
            attributePoints[addresses[i]] += points[i];
            
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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