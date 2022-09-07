// SPDX-License-Identifier: Unlicense
// Creator: 0xVeryBased

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

contract InitialIngredientsMinter is Ownable {
    bool public mintRunning = true;

    enum MintStatus {
        NotStarted,
        Public,
        Finished
    }

    MintStatus public mintStatus = MintStatus.NotStarted;

    mapping(address => bool) public authorized;

    //////////

    mapping(uint256 => uint256) public claimTracker;
    CrudeBorneEggs public eggzzz;

    ERC721StorageLayerProto public storageLayer;

    //////////

    constructor(
        address cbeAddy_,
        address storageLayer_
    ) {
        eggzzz = CrudeBorneEggs(cbeAddy_);
        storageLayer = ERC721StorageLayerProto(storageLayer_);
        storageLayer.registerMintingContract();
    }

    //////////

    function flipRunning() public onlyOwner {
        mintRunning = !mintRunning;
    }

    function authorizeToMint(address toAuthorize) public onlyOwner {
        authorized[toAuthorize] = true;
    }

    function changeMintStatus(MintStatus newMintStatus) public onlyOwner {
        require(newMintStatus != MintStatus.NotStarted);
        mintStatus = newMintStatus;
    }

    //////////

    function alreadyClaimed(uint256 whichEgg) public view returns (bool) {
        uint256 eggBlocc = whichEgg/250;
        uint256 eggSlot = whichEgg - eggBlocc*250;
        return ((claimTracker[eggBlocc] >> eggSlot)%2 == 1);
    }

    function piktItUpp(uint256[] memory eggz) public {
        require(mintRunning, 'mr');
        require(mintStatus == MintStatus.Public || (authorized[msg.sender] && (mintStatus == MintStatus.NotStarted)), 'ms/a');

        uint256 curBlocc = 0;
        uint256 bloccUpdates = 0;
        uint256 eggBlocc;

        bool claimRequire = true;
        bool ownerRequire = true;

        for (uint256 i = 0; i < eggz.length; i++) {
            eggBlocc = eggz[i]/250;
            if (eggBlocc != curBlocc) {
                claimTracker[curBlocc] = claimTracker[curBlocc] | bloccUpdates;
                curBlocc = eggBlocc;
                bloccUpdates = 0;
            }

            uint256 eggSlot = eggz[i] - curBlocc*250;
            claimRequire = claimRequire && (claimTracker[curBlocc] >> eggSlot)%2 == 0;
            ownerRequire = ownerRequire && eggzzz.ownerOf(eggz[i]) == msg.sender;

            bloccUpdates += (1 << eggSlot);
        }
        require(claimRequire && ownerRequire, 'b;o');

        claimTracker[curBlocc] = claimTracker[curBlocc] | bloccUpdates;

        storageLayer.storage_safeMint(msg.sender, msg.sender, eggz.length);
    }
}

////////////////////

abstract contract CrudeBorneEggs {
    function balanceOf(address owner) public view virtual returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual returns (uint256);
    function ownerOf(uint256 tokenId) public view virtual returns (address);
}

abstract contract ERC721StorageLayerProto {
    function registerMintingContract() public virtual;
    function storage_safeMint(address msgSender, address to, uint256 quantity) public virtual;
}

////////////////////////////////////////

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