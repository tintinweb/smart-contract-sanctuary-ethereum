// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./ItemsStructure.sol";
import "./DogsFactory.sol";
import "./ItemsToUpgrade.sol";

contract EpicCasePoses is ItemsStructure {

    Item[] private _poses;

    function initEpicCasePoses() internal {
        _poses.push(Item("Common", "Common", 31));
        _poses.push(Item("Uncommon", "Uncommon", 18));
        _poses.push(Item("Rare", "Rare", 9));
        _poses.push(Item("Epic", "Epic", 3));
        _poses.push(Item("Legendary", "Legendary", 1));
    }

    function getEpicCasePose(uint256 id) internal view returns (Item memory) {
        return getItem(_poses, id);
    }
}

contract EpicCaseFaces is ItemsStructure {

    Item[] private _faces;

    function initEpicCaseFaces() internal {
        _faces.push(Item("Smile", "Common", 31));
        _faces.push(Item("Surprised", "Common", 31));
        _faces.push(Item("Angry", "Uncommon", 18));
        _faces.push(Item("LMAO", "Uncommon", 18));
        _faces.push(Item("Happy", "Rare", 9));
        _faces.push(Item("Blush", "Rare", 9));
        _faces.push(Item("Pensive", "Epic", 3));
        _faces.push(Item("Amazed", "Legendary", 1));
    }

    function getEpicCaseFace(uint256 id) internal view returns (Item memory) {
        return getItem(_faces, id);
    }
}

contract EpicCaseHairstyles is ItemsStructure {

    Item[] private _hairstyles;

    function initEpicCaseHairstyles() internal {
        _hairstyles.push(Item("Uncommon", "Uncommon", 18));
        _hairstyles.push(Item("Rare", "Rare", 9));
        _hairstyles.push(Item("Epic", "Epic", 3));
    }

    function getEpicCaseHairstyle(uint256 id) internal view returns (Item memory) {
        return getItem(_hairstyles, id);
    }
}

contract EpicCaseColors is ItemsStructure {

    Item[] private _colors;

    function initEpicCaseColors() internal {
        _colors.push(Item("Fog", "Common", 31));
        _colors.push(Item("Thundercloud", "Common", 31));
        _colors.push(Item("Asphalt", "Common", 31));
        _colors.push(Item("Smog", "Uncommon", 18));
        _colors.push(Item("Coffe", "Uncommon", 18));
        _colors.push(Item("Sandstone", "Uncommon", 18));
        _colors.push(Item("Cloud Shadow", "Rare", 9));
        _colors.push(Item("Pollen", "Rare", 9));
        _colors.push(Item("Honey", "Epic", 3));
        _colors.push(Item("Red Clay", "Legendary", 1));
    }

    function getEpicCaseColor(uint256 id) internal view returns (Item memory) {
        return getItem(_colors, id);
    }
}

contract EpicCase is EpicCasePoses, EpicCaseHairstyles, EpicCaseFaces, EpicCaseColors, LegendaryPose, ItemsToUpgrade, Ownable, ReentrancyGuard {

    using Strings for uint256;

    DogsFactory public NFTFactory; 
    IERC20 public Token;
    
    uint256 public casePrice;
    address public walletForTokens;

    constructor (DogsFactory _nftFactory, IERC20 _token) {
        initEpicCasePoses();
        initEpicCaseHairstyles();
        initEpicCaseFaces();
        initEpicCaseColors();

        NFTFactory = _nftFactory;
        Token = _token;
    }

    function setWallet(address _wallet) public onlyOwner() {
        walletForTokens = _wallet;
    }

    function setPrice(uint256 _casePrice) public onlyOwner() {
        casePrice = _casePrice;
    }

    function OpenEpicCase() public nonReentrant() {
        require(Token.balanceOf(msg.sender) >= casePrice, "EpicCase: Not enough tokens");
        
        bool check = Token.transferFrom(msg.sender, walletForTokens, casePrice);
        require(check == true, "EpicCase: Oops, some problem");

        uint256 id = NFTFactory.getId();

        string memory name = string.concat("Dog ", id.toString());

        Item memory pose = getEpicCasePose(id);

        if ( keccak256(abi.encodePacked(pose.Rarity)) == keccak256(abi.encodePacked("Legendary")) ) {
            Item memory legendaryPose = getLegendaryPose(id);
            Item memory color = getEpicCaseColor(id);
            
            string[] memory rarity = new string[](2);
            rarity[0] = legendaryPose.Rarity;
            rarity[1] = color.Rarity;

            (uint32 balls, uint32 bones, uint32 dogFood, uint32 medals) = getItemsToUpgrade(rarity, "Child");

            NFTFactory.createDog(msg.sender, name, "Child", legendaryPose, Item("","",0), Item("","",0), color, balls, bones, dogFood, medals);
        } else {
            Item memory hairstyle = getEpicCaseHairstyle(id);
            Item memory face = getEpicCaseFace(id);
            Item memory color = getEpicCaseColor(id);

            string[] memory rarity = new string[](4);
            rarity[0] = pose.Rarity;
            rarity[1] = hairstyle.Rarity;
            rarity[2] = face.Rarity;
            rarity[3] = color.Rarity;

            (uint32 balls, uint32 bones, uint32 dogFood, uint32 medals) = getItemsToUpgrade(rarity, "Child");

            NFTFactory.createDog(msg.sender, name, "Child", pose, hairstyle, face, color, balls, bones, dogFood, medals);
        }
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

pragma solidity ^0.8.0;

contract ItemsStructure {
    
    struct Item {
        string Name;
        string Rarity;
        uint256 Probability;  
    }

    function shuffleArray(Item[] memory _items, uint256 id) private view returns (Item[] memory) {

        for (uint256 i = 0; i < _items.length; i++) {
            uint256 n = i + uint256(keccak256(abi.encodePacked(block.timestamp - id))) % (_items.length - i);
            Item memory temp = _items[n];
            _items[n] = _items[i];
            _items[i] = temp;
        }

        Item[] memory result;
        result = _items;    

        return result;
    }

    function getItem(Item[] memory _items, uint256 id) internal view returns (Item memory) {
        require(_items.length > 0, "ItemsStructure: the number of items must be greater than 0");
        require(id > 0, "ItemsStructure: id must be greater than 0");

        _items = shuffleArray(_items, id);

        uint256 sum = 0;

        for(uint i = 0; i < _items.length; i++) {
            sum += _items[i].Probability;
        }

        uint256 random = createRandom(sum, id);

        uint256 tmp = 0;
        uint k = 0;
        
        for(uint256 j = 0; j < _items.length; j++) {
            if( (random >= tmp) && (random <= tmp + _items[j].Probability) ) {
                k = j;
                break;
            } else {
                tmp += _items[j].Probability;
            }
        }

        return _items[k];
    }

    function createRandom(uint256 sum, uint256 id) private view returns (uint256) {
        return uint256(blockhash(block.number - id)) % sum + 1;
    }
}

contract LegendaryPose is ItemsStructure {

    Item[] private _legendaryPoses;

    constructor() {
        _legendaryPoses.push(Item("Explorer", "Legendary", 10));
        _legendaryPoses.push(Item("Sportsman", "Legendary", 10));
        _legendaryPoses.push(Item("Hipster", "Legendary", 10));
        _legendaryPoses.push(Item("Aviator", "Legendary", 10));
    }

    function getLegendaryPose(uint256 id) internal view returns (Item memory) {
        return getItem(_legendaryPoses, id);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import {SafeMath} from  "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./DogsContract.sol";
import "./Initializable.sol";
import "./ItemsStructure.sol";
import "./Cases.sol";
import "./ApproveWallet.sol";
import "./ItemsToUpgrade.sol";

contract Poses is ItemsStructure {

    Item[] private _poses;

    constructor() {
        _poses.push(Item("Common", "Common", 100));
        _poses.push(Item("Uncommon", "Uncommon", 50));
        _poses.push(Item("Rare", "Rare", 20));
        _poses.push(Item("Epic", "Epic", 5));
        _poses.push(Item("Legendary", "Legendary", 1));
    }

    function getPose(uint256 id) internal view returns (Item memory) {
        return getItem(_poses, id);
    }
}

contract Hairstyles is ItemsStructure {

    Item[] private _hairstyles;

    constructor() {
        _hairstyles.push(Item("Uncommon", "Uncommon", 50));
        _hairstyles.push(Item("Rare", "Rare", 20));
        _hairstyles.push(Item("Epic", "Epic", 5));
    }

    function getHairstyle(uint256 id) internal view returns (Item memory) {
        return getItem(_hairstyles, id);
    }
}

contract DogsFactory is Dogs, Cases, ApproveWallet, Poses, Hairstyles, LegendaryPose, ItemsToUpgrade {

    using SafeMath for uint256;
    using Strings for uint256;

    string URI;

    event Birth(
        address owner,
        Dog dog,
        uint256 birth
    );

    event GrowingUp(
        address owner,
        Dog dog,
        uint256 birth
    );

    function updateDogName(uint256 _tokenId, string memory _dogName) public onlyDogOwner(_tokenId) {
        dogs[_tokenId].DogName = _dogName;
    }

    function dogsOf(address _owner) public view returns (uint256[] memory) {
        // get the number of dogs owned by _owner
        uint256 ownerCount = ownerDogCount[_owner];
        if (ownerCount == 0) {
            return new uint256[](0);
        }

        // iterate through each dogsId until we find all the dogs
        // owned by _owner
        uint256[] memory ids = new uint256[](ownerCount);
        uint256 i = 1;
        uint256 count = 0;
        while (count < ownerCount || i < dogs.length) {
            if (dogToOwner[i] == _owner) {
                ids[count] = i;
                count = count.add(1);
            }
            i = i.add(1);
        }

        return ids;
    }

    function getId() external view returns (uint256) {
        return dogs.length;
    }

    function createDog(
        address _owner, 
        string memory _dogName,
        string memory _age,
        Item memory _pose,
        Item memory _hairstyle,
        Item memory _face,
        Item memory _color,
        uint32 _balls,
        uint32 _bones,
        uint32 _dogFood,
        uint32 _medals
    ) external returns (uint256) {
        require(
            onlyCaseAdresses(_msgSenderContract()) || msg.sender == owner(),
            "DogsFactory: The address is not an approved case or owner"
        );

        Dog memory dog = Dog({
            DogName: _dogName,
            Age: _age,
            Pose: _pose,
            Hairstyle: _hairstyle,
            Face: _face,
            Color: _color,
            Balls: _balls,
            Bones: _bones,
            DogFood: _dogFood,
            Medals: _medals,
            BirthTime: block.timestamp,
            GrowUp: false
        });

        dogs.push(dog);

        uint256 newDogId = dogs.length - 1;

        emit Birth(_owner, dog, block.timestamp);

        _mint(_owner, newDogId);

        return newDogId;
    }

    function approveGrowUp(uint256 _tokenId) public onlyApproveWallet() {
        require( keccak256(abi.encodePacked(dogs[_tokenId].Age)) != keccak256(abi.encodePacked("Adult")), "DogsFactory: The dog is already an adult");
        require( dogs[_tokenId].GrowUp == false, "DogsFactory: Already approved");
        dogs[_tokenId].GrowUp = true;
    }

    function growUp(uint256 _tokenId) public onlyDogOwner(_tokenId) {
        require(dogs[_tokenId].GrowUp == true, "DogsFactory: The dog can't grow up");

        if ( keccak256(abi.encodePacked(dogs[_tokenId].Pose.Rarity)) == keccak256(abi.encodePacked("Legendary")) ) {
            bool check = updateLegendaryDog(_tokenId);
            if (check == true) {
                dogs[_tokenId].GrowUp = false;
            }
        } else {
            bool check = updateDog(_tokenId);
            if (check == true) {
                dogs[_tokenId].GrowUp = false;
            }
        }
    }

    function getGrowUp(uint256 _tokenId) public view returns (bool) {
        return dogs[_tokenId].GrowUp;
    } 

    function updateLegendaryDog(uint256 _tokenId) private returns (bool) {
        if ( keccak256(abi.encodePacked(dogs[_tokenId].Age)) == keccak256(abi.encodePacked("Teenager")) ) {
            dogs[_tokenId].Age = "Adult";
        }
        if ( keccak256(abi.encodePacked(dogs[_tokenId].Age)) == keccak256(abi.encodePacked("Child")) ) {
            dogs[_tokenId].Age = "Teenager";
        }

        string[] memory rarity = new string[](2);
        rarity[0] = dogs[_tokenId].Pose.Rarity;
        rarity[1] = dogs[_tokenId].Color.Rarity;

        (uint32 balls, uint32 bones, uint32 dogFood, uint32 medals) = getItemsToUpgrade(rarity, dogs[_tokenId].Age);

        dogs[_tokenId].Balls = balls;
        dogs[_tokenId].Bones = bones;
        dogs[_tokenId].DogFood = dogFood;
        dogs[_tokenId].Medals = medals;

        emit GrowingUp(msg.sender, dogs[_tokenId], block.timestamp);

        return true;
    }

    function updateDog(uint256 _tokenId) private returns (bool) {
        if ( keccak256(abi.encodePacked(dogs[_tokenId].Age)) == keccak256(abi.encodePacked("Teenager")) ) {
            dogs[_tokenId].Age = "Adult";
        }
        if ( keccak256(abi.encodePacked(dogs[_tokenId].Age)) == keccak256(abi.encodePacked("Child")) ) {
            dogs[_tokenId].Age = "Teenager";
        }

        Item memory pose = getPose(_tokenId);
        if ( keccak256(abi.encodePacked(pose.Rarity)) == keccak256(abi.encodePacked("Legendary")) ) {
            Item memory legendaryPose = getLegendaryPose(_tokenId);

            dogs[_tokenId].Pose = legendaryPose;
            dogs[_tokenId].Hairstyle = Item("","",0);
            dogs[_tokenId].Face = Item("","",0);

            string[] memory rarity = new string[](2);
            rarity[0] = dogs[_tokenId].Pose.Rarity;
            rarity[1] = dogs[_tokenId].Color.Rarity;

            (uint32 balls, uint32 bones, uint32 dogFood, uint32 medals) = getItemsToUpgrade(rarity, dogs[_tokenId].Age);

            dogs[_tokenId].Balls = balls;
            dogs[_tokenId].Bones = bones;
            dogs[_tokenId].DogFood = dogFood;
            dogs[_tokenId].Medals = medals;

        } else {
            Item memory hairstyle = getHairstyle(_tokenId);
        
            dogs[_tokenId].Pose = pose;
            dogs[_tokenId].Hairstyle = hairstyle;

            string[] memory rarity = new string[](4);
            rarity[0] = dogs[_tokenId].Pose.Rarity;
            rarity[1] = dogs[_tokenId].Hairstyle.Rarity;
            rarity[2] = dogs[_tokenId].Face.Rarity;
            rarity[3] = dogs[_tokenId].Color.Rarity;

            (uint32 balls, uint32 bones, uint32 dogFood, uint32 medals) = getItemsToUpgrade(rarity, dogs[_tokenId].Age);

            dogs[_tokenId].Balls = balls;
            dogs[_tokenId].Bones = bones;
            dogs[_tokenId].DogFood = dogFood;
            dogs[_tokenId].Medals = medals;
        }

        emit GrowingUp(msg.sender, dogs[_tokenId], block.timestamp);

        return true;
    }

    function setTokenURI(string memory _URI) public onlyOwner () {
        URI = _URI;
    }

    function baseTokenURI() override public view returns (string memory) {
        return URI;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {SafeMath} from  "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract ItemsToUpgrade {

    using SafeMath for uint32;

    uint32 constant ITEM_1 = 10;
    uint32 constant ITEM_2 = 5;
    uint32 constant ITEM_3 = 3;
    uint32 constant ITEM_4 = 2;

    function getItemsToUpgrade(string[] memory _rarity, string memory _age) internal pure returns (uint32 item_1, uint32 item_2, uint32 item_3, uint32 item_4) {
        if ( keccak256(abi.encodePacked(_age)) == keccak256(abi.encodePacked("Adult")) ) {
            item_1 = 0;
            item_2 = 0;
            item_3 = 0;
            item_4 = 0;
        } else {
            uint32 sum = 0;

            for (uint i = 0; i < _rarity.length; i++) {
                sum += getRarityMultiplier(_rarity[i]);
            }

            uint32 age = getAgeMultiplier(_age);

            item_1 = sum * ITEM_1 * age;
            item_2 = sum * ITEM_2 * age;
            item_3 = sum * ITEM_3 * age;
            item_4 = sum * ITEM_4 * age;
        }
    }

    function getRarityMultiplier(string memory _rare) private pure returns (uint32) {
        if ( keccak256(abi.encodePacked(_rare)) == keccak256(abi.encodePacked("Common")) ) {
            return 2;
        } else if ( keccak256(abi.encodePacked(_rare)) == keccak256(abi.encodePacked("Uncommon")) ) {
            return 4;
        } else if ( keccak256(abi.encodePacked(_rare)) == keccak256(abi.encodePacked("Rare")) ) {
            return 8;
        } else if ( keccak256(abi.encodePacked(_rare)) == keccak256(abi.encodePacked("Epic")) ) {
            return 16;
        } else { // Legendary
            return 32;
        }
    }

    function getAgeMultiplier(string memory _age) private pure returns (uint32) {
        if ( keccak256(abi.encodePacked(_age)) == keccak256(abi.encodePacked("Child")) ) {
            return 1;
        } else { // Teenager
            return 3;
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
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./ItemsStructure.sol";
import "./ContextMixin.sol";

contract Dogs is Context, ERC165, IERC721, IERC721Metadata, ContextMixin, ItemsStructure {
    using Address for address;
    using Strings for uint256;
    using SafeMath for uint256;

    struct Dog {
        string DogName;
        string Age;
        Item Pose;
        Item Hairstyle;
        Item Face;
        Item Color;
        uint32 Balls;
        uint32 Bones;
        uint32 DogFood;
        uint32 Medals;
        uint256 BirthTime;
        bool GrowUp;
    }

    Dog[] internal dogs;

    string _tokenName = "Dog Token";
    string _tokenSymbol = "DOG";

    mapping(uint256 => address) internal dogToOwner;
    mapping(address => uint256) internal ownerDogCount;
    mapping(uint256 => address) private dogToApproved;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    constructor() {
        dogs.push(
            Dog({
                DogName: "",
                Age: "",
                Pose: Item("","",0),
                Hairstyle: Item("","",0),
                Face: Item("","",0),
                Color: Item("","",0),
                Balls: 0,
                Bones: 0,
                DogFood: 0,
                Medals: 0,
                BirthTime: 0,
                GrowUp: false
            })
        );
    }

    /// @dev throws if @param _address is the zero address
    modifier notZeroAddress(address _address) {
        require(_address != address(0), "zero address");
        _;
    }

    /// @dev throws if @param _dogId has not been created
    modifier validDogId(uint256 _dogId) {
        require(_dogId < dogs.length, "invalid dogId");
        _;
    }

    /// @dev throws if msg.sender does not own @param _dogId
    modifier onlyDogOwner(uint256 _dogId) {
        require(isDogOwner(_dogId), "sender not dog owner");
        _;
    }

    function isDogOwner(uint256 _dogId) public view returns (bool) {
        return msg.sender == ownerOf(_dogId);
    }

    /**
     * @dev Returns the Dog for the given _dogId
     */
    function getDog(uint256 _dogId)
        public
        view
        returns (
            address owner,
            string memory dogName,
            string memory age,
            Item memory pose,
            Item memory hairstyle,
            Item memory face,
            Item memory color,
            uint32 balls,
            uint32 bones,
            uint32 dogFood,
            uint32 medals,
            uint256 birthTime
        )
    {   
        Dog storage dog = dogs[_dogId];
        
        owner = dogToOwner[_dogId];
        dogName = dog.DogName;
        age = dog.Age;
        pose = dog.Pose;
        hairstyle = dog.Hairstyle;
        face = dog.Face;
        color = dog.Color;
        balls = dog.Balls;
        bones = dog.Bones;
        dogFood = dog.DogFood;
        medals = dog.Medals;
        birthTime = dog.BirthTime;
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
        return ownerDogCount[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = dogToOwner[tokenId];
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory tokenName) {
        return _tokenName;
    }

    /*
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory tokenSymbol) {
        return _tokenSymbol;
    }  

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = baseTokenURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function baseTokenURI() public view virtual returns (string memory) {
        return "";
    }

    /*
     * @dev Returns the total number of tokens in circulation.
     */
    function totalSupply() external view returns (uint256 total) {
        // is the Unkitty considered part of the supply?
        return dogs.length - 1;
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = Dogs.ownerOf(tokenId);
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

        return dogToApproved[tokenId];
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
        return dogToOwner[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = Dogs.ownerOf(tokenId);
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

        ownerDogCount[to] += 1;
        dogToOwner[tokenId] = to;

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
        address owner = Dogs.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        ownerDogCount[owner] -= 1;
        delete dogToOwner[tokenId];

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
        require(Dogs.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        ownerDogCount[from] -= 1;
        ownerDogCount[to] += 1;
        dogToOwner[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        dogToApproved[tokenId] = to;
        emit Approval(Dogs.ownerOf(tokenId), to, tokenId);
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

    /**
     * This is used instead of msg.sender as transactions won't be sent by the original token owner, but by OpenSea.
     */
    function _msgSenderContract()
        internal
        view
        returns (address sender)
    {
        return ContextMixin.msgSender();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Initializable {
    bool inited = false;

    modifier initializer() {
        require(!inited, "already inited");
        _;
        inited = true;
    }
}

// // SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract Cases is Ownable {
    address[] private CaseAddresses;

    function onlyCaseAdresses(address _sender) public view returns (bool) {
        bool owner = false;
        for(uint i = 0; i < CaseAddresses.length; i++) {
            if(_sender == CaseAddresses[i]) {
                owner = true;
            }
        }

        return owner;
    }

    function setCaseAddress(address[] memory _cases) public onlyOwner {
        CaseAddresses = _cases;
    }

    function addCaseAddress(address _case) public onlyOwner {
        CaseAddresses.push(_case);
    }

    function removeCaseAddress(uint index) public onlyOwner {
        require(index > CaseAddresses.length, "Cases: This index does not exist");
        CaseAddresses[index] = CaseAddresses[CaseAddresses.length - 1];
        CaseAddresses.pop();
    }

    function getLenghtCaseAddress() public view returns (uint) {
        return CaseAddresses.length;
    }

    function getCaseAddress(uint index) public view returns (address) {
        return CaseAddresses[index];
    }

}

// // SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract ApproveWallet is Ownable {
    address private approveWallet;

    modifier onlyApproveWallet() {
        require(msg.sender == approveWallet, "ApproveWallet: caller is not the approve wallet");
        _;
    }

    function addApproveWallet(address _approveWallet) public onlyOwner {
        approveWallet = _approveWallet;
    }

    function deleteApproveWallet() public onlyOwner {
        approveWallet = address(0);
    }
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

// // SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

abstract contract ContextMixin {
    function msgSender()
        internal
        view
        returns (address payable sender)
    {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender := and(
                    mload(add(array, index)),
                    0xffffffffffffffffffffffffffffffffffffffff
                )
            }
        } else {
            sender = payable(msg.sender);
        }
        return sender;
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