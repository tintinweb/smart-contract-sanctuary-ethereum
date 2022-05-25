// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";

struct Land {
    address host;
    address []guests;
    string  name; // name or store
    string  url;  // your avatar or link
    LandType typ;
    Position pos;
    uint   price;
}

enum LandType {
    WORK, SHOPING, PARK, ROAD, MEETING, SPORT, OTHER,
    PLAIN, GRASS, WATER, FOREST, MOUNTAIN, DESERT
}

struct Position {
    int32 lat; // 111. 111
    int32 lng; 
}

struct Last {
    uint blkNum;
    uint locIdx;
}

contract MeetSH is Ownable{
    mapping(address => uint[]) public ownedLands;
    mapping(address => Last) public lastLight;
    
    mapping(int32 => mapping(int32 => uint)) public posLand; // lat, lng => locIdx
    Land[] public allLands;
    uint public landStart;
    uint public landCount;

    event LightLand(uint index);

    constructor() {
        // set 0
        allLands.push(
            Land(
                msg.sender, 
                new address[](0),
                "Meet Genesis", 
                "meet.xyz", 
                LandType.MEETING, 
                Position(0, 0), 
                100 ether
            ));
    }

    // if 8-12, return 5
    // if 13-17, return 10
    // if 18-22, return 15 
    function getBound(int32 x) internal returns (int32 lx) {
        int32 z = x % 10;
        return z<3 ? x-z-5 : z>7 ? x-z+5 : x-z;
    }

    function addLands(Land[] calldata lands) public onlyOwner {
        landStart = allLands.length;
        for (uint i=0; i<lands.length; i++) {
            int32 lx = getBound(lands[i].pos.lat);
            int32 ly = getBound(lands[i].pos.lng);
            if (posLand[lx][ly] == 0) {
                posLand[lx][ly] = allLands.length;
                allLands.push(lands[i]);
            }
        }
        landCount = allLands.length - 1;
    }

    function changeType(uint index, LandType typ) public onlyOwner {
        require(landCount >= index, "Index too big!");
         allLands[index].typ = typ;
    }

    function withdraw() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function mintLand(Position calldata pos, string memory name, string memory url, LandType typ) public payable {
        require(msg.value >= 1 ether, "Price too low!");
        int32 lx = getBound(pos.lat);
        int32 ly = getBound(pos.lng);
        require(posLand[lx][ly] == 0, "Already has land!"); 
        posLand[lx][ly] = allLands.length;
        allLands.push(
            Land(msg.sender, new address[](0),
                name, url, typ, pos, 2 ether
            ));
        landCount = allLands.length - 1;
    }

    function buyLand(uint index, string memory name, string memory url) public payable {
        require(landCount >= index, "Index too big!");
        require(msg.value >= allLands[index].price, "Price too low!");
        payable(allLands[index].host).transfer(msg.value * 9 / 10); // transfer
        allLands[index].host = msg.sender;
        allLands[index].name = name;
        allLands[index].url = url;
        allLands[index].price = allLands[index].price * 2;
    }

    function modLand(uint index, string memory name, string memory url) public {
        require(landCount >= index, "Index too big!");
        require(allLands[index].host == msg.sender, "Only host can modify!");
        allLands[index].name = name;
        allLands[index].url = url;
    }

    function modPrice(uint index, uint price) public {
        require(landCount >= index, "Index too big!");
        require(allLands[index].host == msg.sender, "Only host can modify!");
        allLands[index].price = price;
    }


    function lightLand(Position calldata pos) public {
        int32 lx = getBound(pos.lat);
        int32 ly = getBound(pos.lng);
        uint index = posLand[lx][ly];
        require(index != 0, "No land"); 

        Last memory last = lastLight[msg.sender];
        if (last.blkNum != 0) {
            Position memory lpos = allLands[last.locIdx].pos;
            int32 dx = pos.lat > lpos.lat ? pos.lat - lpos.lat : lpos.lat - pos.lat;
            int32 dy = pos.lng > lpos.lng ? pos.lng - lpos.lng : lpos.lng - pos.lng;
            require(block.number - last.blkNum > uint32(dx + dx), "Too short");
        }

        ownedLands[msg.sender].push(index);
        allLands[index].guests.push(msg.sender);
        lastLight[msg.sender] = Last(block.number, index);
        emit LightLand(index);
    }

    receive() external payable{
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