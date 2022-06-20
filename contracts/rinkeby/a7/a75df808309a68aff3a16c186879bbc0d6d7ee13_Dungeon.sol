/**
 *Submitted for verification at Etherscan.io on 2022-06-20
*/

// File: @openzeppelin/contracts/utils/math/SafeMath.sol


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

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: contracts/Dungeon.sol



pragma solidity ^0.8.0;



interface IInventory {
    struct Gear {
        string name;
        uint16 tier;
        uint16 status;
        uint16 soulScore;
    }

    struct FallenInventory {
        address owner;
        Gear head;
        Gear chest;
        Gear shoulders;
        Gear shirt;
        Gear pants;
        Gear feet;
        Gear ring;
        Gear artifact;
        Gear mainhand;
        Gear offhand;
        uint256 base;
        uint256 lastTimeClaimed;
        bool stakeLocked;
    }  

    function updateGear(uint256 tokenId, uint256 slot, Gear memory newGear) external;
    function getInventory(uint256 tokenId) external view returns(FallenInventory memory);
    function updateSoulScore(uint256 tokenId, uint256 _soulScore) external;
    function getOwedSouls(uint256 id) external view returns(uint256);
    function updateOutstandingSouls(address user, uint256 _outstandingSouls) external;
    function setLastTimeClaimed(uint256 tokenId) external;
}

interface IGearTable {
    function getDungeonGear(uint16 level, uint256 slot) external returns(IInventory.Gear memory gear);
}

interface ISouls {
    function mint(address to, uint256 value) external;
    function burn(address user, uint256 amount) external;
}

interface IFallen {
    function ownerOf(uint256 tokenId) external view returns (address);
}

contract Dungeon is Ownable {

    IGearTable public GearTable;
    ISouls public Souls;
    IInventory public Inventory;
    IFallen public Fallen;

    struct RaidInfo {
        uint256 cost;
        IInventory.Gear gear;
        uint16 slot;
        uint16 dropChance;
        uint16 runsLeft;
    }
    
    mapping(uint256 => RaidInfo) public RaidMapping;

    uint256 entropy = 0;

    bool public dungeonActive = false;

    RaidInfo raidOne = RaidInfo({
                                        cost: 1 ether, 
                                        gear: IInventory.Gear("Fallen Blade", 3, 1, 7),
                                        slot: 9,
                                        dropChance: 10,
                                        runsLeft: 250
                                    });
    
    RaidInfo raidTwo = RaidInfo({
                                        cost: 5 ether, 
                                        gear: IInventory.Gear("Helm of Darkness", 4, 1, 12),
                                        slot: 1,
                                        dropChance: 15,
                                        runsLeft: 500  
                                    });

    RaidInfo raidThree = RaidInfo({
                                        cost: 12 ether, 
                                        gear: IInventory.Gear("Dragonhide Breastplate", 5, 1, 20),
                                        slot: 3,
                                        dropChance: 20,
                                        runsLeft: 750   
                                    });

    RaidInfo raidFour = RaidInfo({
                                        cost: 30 ether, 
                                        gear: IInventory.Gear("Enigma of the Mind", 6, 1, 35),
                                        slot: 8,
                                        dropChance: 25,
                                        runsLeft: 500   
                                    });

    RaidInfo raidFive = RaidInfo({
                                        cost: 50 ether, 
                                        gear: IInventory.Gear("Invisible Dagger", 7, 1, 75),
                                        slot: 10,
                                        dropChance: 20,
                                        runsLeft: 250   
                                    });

    RaidInfo raidSix = RaidInfo({
                                        cost: 30 ether, 
                                        gear: IInventory.Gear("Spaulders of Atlas", 8, 1, 125),
                                        slot: 2,
                                        dropChance: 8,
                                        runsLeft: 100   
                                    });

    /**
     * @dev 
     
     Send an array of Token IDs to explore a dungeon.

     Level Correspondence:
        1: Halls
        2: Monastery
        3: Graveyard
        4: Catacombs
        5: Armory
        6: Castle
        7: Throne

     Entering a Dungeon will cost $Souls.

     Running a Dungeon will also send all $Souls owed to a Token ID into the outstandingSouls mapping on the Inventory Contract.
     This is done to ensure accurate earning of $Souls upon a change in the Soul Score of a Fallen.
     */

    function runDungeon(uint256[] memory tokenIds, uint16 level, uint256[] calldata gearType) public {
        Souls.burn(msg.sender, getDungeonCost(level) * tokenIds.length * gearType.length);
        require(dungeonActive, "Activity is paused");
        uint256 outstandingSouls = 0;
        for(uint256 x = 0; x < tokenIds.length; x++) {
            //require(msg.sender == Inventory.getInventory(tokenIds[x]).owner, "You do not own this Fallen");
            //require(Fallen.ownerOf(tokenIds[x]) == address(Inventory), "Fallen is not staked");
            outstandingSouls += Inventory.getOwedSouls(tokenIds[x]);
            for(uint256 i = 0; i < gearType.length; i++) { 
                Inventory.updateGear(tokenIds[x], gearType[i], GearTable.getDungeonGear(level, gearType[i]));
            }
            Inventory.setLastTimeClaimed(tokenIds[x]);
        }
        Inventory.updateOutstandingSouls(msg.sender, outstandingSouls);
    }

    /**
     * @dev 
     
     Send an array of Token IDs to conquer a Raid

     Raids are 

     Entering a Raid will cost $Souls.

     Running a Raid will also send all $Souls owed to a Token ID into the outstandingSouls mapping on the Inventory Contract.
     This is done to ensure accurate earning of $Souls upon a change in the Soul Score of a Fallen.
     */
    function enterRaid(uint256[] memory tokenIds, uint256 _raidId) public {
        RaidInfo memory _raid = RaidMapping[_raidId];
        require(_raid.runsLeft - tokenIds.length >= 0);
        require(dungeonActive, "Activity is paused");
        Souls.burn(msg.sender, _raid.cost * tokenIds.length);
        uint256 outstandingSouls = 0;
        for(uint256 x = 0; x < tokenIds.length; x++) {
            IInventory.FallenInventory memory _inventory = Inventory.getInventory(tokenIds[x]);
            require(msg.sender == _inventory.owner, "You do not own this Fallen");
            require(Fallen.ownerOf(tokenIds[x]) == address(Inventory), "Fallen is not staked");
            outstandingSouls += Inventory.getOwedSouls(tokenIds[x]);
            uint256 _seed = _rand(tokenIds[x]) % 100;
            if(_seed < _raid.dropChance){
                Inventory.updateGear(tokenIds[x],_raid.slot,_raid.gear);
            } else {
                Inventory.updateGear(tokenIds[x], 1, _inventory.head);
            }
        }
        Inventory.updateOutstandingSouls(msg.sender, outstandingSouls);
        RaidMapping[_raidId].runsLeft -= uint8(tokenIds.length);

    }

    function createRaid(RaidInfo memory _info, uint256 _raidId) external onlyOwner {
        RaidMapping[_raidId] = _info;
    }

    function getDungeonCost(uint256 level) internal pure returns (uint256 cost) {
        if(level==1){ return 1 ether; }
        else if(level==2){return 8 ether; }
        else if(level==3){ return 20 ether; }
        else if(level==4){ return 40 ether; }
        else if(level==5){ return 80 ether; }
        else if(level==6){ return 150 ether; }
        else if(level==7){ return 250 ether; }
        else { return 100000000000 ether; }  
    }

    function _rand(uint256 entropyModifier) internal returns (uint256) {
        entropy += entropyModifier;
        return uint256(keccak256(abi.encodePacked(msg.sender, block.timestamp, block.basefee, block.timestamp, entropy)));
    }

    function toggleDungeonActive() public onlyOwner {
        dungeonActive = !dungeonActive;
    }

    function setGearTableAddress(address _gearTableAddress) external onlyOwner {
        GearTable = IGearTable(_gearTableAddress);
    }

    function setSoulsAddress(address _soulsAddress) external onlyOwner {
        Souls = ISouls(_soulsAddress);
    }

    function setFallenAddress(address _fallenAddress) external onlyOwner {
        Fallen = IFallen(_fallenAddress);
    }

    function setInventoryAddress(address _inventoryAddress) external onlyOwner {    
        Inventory = IInventory(_inventoryAddress);
    }
    
    constructor(){
        RaidMapping[1] = raidOne;
        RaidMapping[2] = raidTwo;
        RaidMapping[3] = raidThree;
        RaidMapping[4] = raidFour;
        RaidMapping[5] = raidFive;
        RaidMapping[6] = raidSix;
    }

}