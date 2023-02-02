// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";

interface ISoulsLocker {
    function getSoulsInHero(uint256 heroId) external view returns (uint16[] memory);
}

struct AddLayer {
    uint128 layer;
    uint128 id;
}

contract AdditionalLayers is Ownable {

    event NewAddLayer(uint256 indexed heroId, AddLayer newLayer);
    event TransferLayer(uint256 indexed from, uint256 indexed to, uint256 index);
    event TransferAllLayers(uint256 indexed from, uint256 indexed to);

    ISoulsLocker public immutable locker; 

    // optional, not active by default
    bool public transfersActive;

    // addLayers storage
    mapping(uint256 => AddLayer[]) public heroToAddLayers;

    // contracts allowed to mint layers
    // we keep on adding them and do not re-use indexes
    // we can close the minter contracts once the job is done or set that index to address(0)
    // minters[0] is the owner, minters[1] the first exp spender contract
    address[] public minters;

    // mainnet = 0xe93d07a731fedf4f676aaa057bd534832d3012f0 // testnet = 0xB7996CC6532f3Faa63e7CEA16Ee6DcD97D1EF6fD 
    constructor(address locker_) { 
        //mainnet = 0x1eb4490091bd0fFF6c3973623C014D082936EA03, testnet = 0xb8B7136036805111dfc27437F121aFB75E21df69
        locker = ISoulsLocker(locker_);
        // set owner as a minter for aidrops
        minters.push(msg.sender); 
    }

    //////
    // ADMIN FUNCTIONS
    //////

    // Activates addLayers transfers - optional for future needs
    function activateTransfers(bool flag) external onlyOwner {
        transfersActive = flag;
    }

    function addMinter(address minterAddress) external onlyOwner {
        minters.push(minterAddress);
    }

    function updateMinter(address minterAddress, uint256 minterIdx) external onlyOwner {
        minters[minterIdx] = minterAddress;
    }

    //////
    // MINT LAYERS
    //////

    function mintAddLayer(uint256 heroId, AddLayer calldata newLayer, uint256 minterIdx) external {
        require(msg.sender == minters[minterIdx], "Minter not valid");

        heroToAddLayers[heroId].push(newLayer);
        emit NewAddLayer(heroId, newLayer);
    }

    function mintAddLayerBatch(uint256[] memory heroId, AddLayer calldata newLayer, uint256 minterIdx) external {
        require(msg.sender == minters[minterIdx], "Minter not valid");

        for(uint256 i = 0; i < heroId.length; ) {
            heroToAddLayers[heroId[i]].push(newLayer);
            emit NewAddLayer(heroId[i], newLayer);

            unchecked {
                ++i;
            }
        }
    }

    //////
    // TRANSFER ALL LAYERS (Default Not active)
    //////

    function transferAllLayers(uint256 heroFromId, uint256 heroToId, uint256 minterIdx) external  {
        require(transfersActive, "Not Active");
        require(msg.sender == minters[minterIdx], "Minter not valid"); 

        heroToAddLayers[heroToId] = heroToAddLayers[heroFromId];
        delete heroToAddLayers[heroFromId];

        emit TransferAllLayers(heroFromId, heroToId);
    }

    //////
    // TRANSFER ONE LAYER (Default Not active)
    //////

    function transferOneLayer(uint256 heroFromId, uint256 heroToId, uint256 index, uint256 minterIdx) external {
        require(transfersActive, "Not Active");
        require(msg.sender == minters[minterIdx], "Minter not valid"); 

        AddLayer[] storage from = heroToAddLayers[heroFromId]; //pointer
        AddLayer[] storage to = heroToAddLayers[heroToId]; //pointer

        to.push(from[index]); // add element at index to heroTo
        from[index] = from[from.length - 1]; // swap element to delete with last
        from.pop(); // delete last element that was moved

        emit TransferLayer(heroFromId, heroToId, index);
    }

    //////
    // READ LAYERS
    //////

    function getHeroLayers(uint256 heroId) external view returns (AddLayer[] memory) {
        return heroToAddLayers[heroId];
    }

    // check layer is in Hero
    function isLayerInHero(uint256 heroId, uint256 layer, uint256 layerId) public view returns (bool) {
        AddLayer[] memory layersInHero = heroToAddLayers[heroId];

        for(uint256 i = 0; i < layersInHero.length; i++) {
            if(layersInHero[i].layer == layer && layersInHero[i].id == layerId) {
                return true;
            }
        }

        return false;
    }

    // this one checks all the internal souls NOT the main token, 
    function isLayerInSouls(uint256 heroId, uint256 layer, uint256 layerId) public view returns (bool) {
        uint16[] memory souls = locker.getSoulsInHero(heroId);

        AddLayer[] memory layersInHero;

        for(uint256 j = 0; j < souls.length; j++) {
            layersInHero = heroToAddLayers[souls[j]];

            for(uint256 i = 0; i < layersInHero.length; i++) {
                if(layersInHero[i].layer == layer && layersInHero[i].id == layerId) {
                    return true;
                }
            }
        }
        return false;
    }

    // this one checks all the internal souls AND the main token
    function isLayerInHeroOrSouls(uint256 heroId, uint256 layer, uint256 layerId) public view returns (bool) {
        //checks if addLayer is in main hero
        if(isLayerInHero(heroId, layer, layerId)){
            return true;
        }

        // checks internal souls
        uint16[] memory souls = locker.getSoulsInHero(heroId);

        for(uint256 i = 0; i < souls.length; i++) {
            if(isLayerInHero(souls[i], layer, layerId)){
                return true;
            }      
        }
        
        return false;
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