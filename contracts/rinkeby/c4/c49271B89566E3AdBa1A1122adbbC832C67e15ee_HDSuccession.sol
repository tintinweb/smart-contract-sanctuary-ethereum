// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

// MMMMMNo.   ,0MMMMMMWo.   :XMMMXc.                        .oNMMMMM
// MMMMXl.   ;0WMMMMMNd.   ;0WMMXl.                          .lXMMMM
// MMWO,   .oXMMMMMMXl.   cXMMMMKxoooooooooo;    .coooooooc.   ,OWMM
// MXo.   ,OWMMMMMMK:   .oNMMMMMMMMMMMMMMMMMNo.   :KMMMMMMWO,   .oXM
// 0;    .:oooooool'   .xWMMMMMMMMMMMMMMMMMMMWk.   ,OWMMMMMMXl.   ;0
// ,                  .oWMMMMMMMMMMMMMMMMMMMMMWo.   ;KMMMMMMMXc    ,
// k,     .;;;;;;;;.   .dNMMMMMMMMMMMMMMMMMMMNd.   'kWMMMMMWKc.   ,k
// MXo.   .oXWWWWWWK:    :KMMMMMMMMMMMMMMMMMK:    :KMMMMMMXd.   .oXM
// MMW0c.   ,kWMMMMMNd.   'kWMMMMMMMMMMMMMWk'   .dNMMMMMWk,   .c0WMM
// MMMMWk,   .c0WMMMMW0;   .lXMMMMMMMMMMMXl.   ;0WMMMMW0c.   ,kWMMMM
// MMMMMMXd.   .oXMMMMMXo.   ,OWMMMMMMMWO,   .oXMMMMMXo.   .oXMMMMMM
// MMMMMMMW0c.   ,kNMMMMWk,   .oNMMMMMNd.   ,kWMMMMNk,   .c0WMMMMMMM
// MMMMMMMMMWk,   .c0WMMMMKc.   :0WMMMNd. .cKMMMMW0c.   ,kWMMMMMMMMM
// MMMMMMMMMMMXd.   .oXMMMMNx.   .xXNMMWOlxNMMMMXo.   .dXMMMMMMMMMMM
// MMMMMMMMMMMMWKc.   ,kNMMMW0:   ..cXMMMWMMMMNk,   .cKWMMMMMMMMMMMM
// MMMMMMMMMMMMMMWk,   .:0WMMMNo.    ,OWMMMMW0:.   ,kWMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMXd.   .oXMMMWO,    .oXMMXo.   .dXMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMWKc.   ,kNMMMXl'.   :Ox,   .cKWMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMWO;   .:0WMMWXk'        ;OWMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMXd.   .dNMMMMK:     .dXMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMWKc. .dNMMMMMNd. .cKWMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMNd,xWMMMMMMMWx,dNMMMMMMMMMMMMMMMMMMMMMMMM

import "@openzeppelin/contracts/access/Ownable.sol";

contract HDSuccession is Ownable {
    event SuccessionCreated(
        address owner1,
        address owner2,
        address contractAddr,
        uint256 tokenId,
        uint256 time
    );

    event LossPreventionCreated(
        address owner1,
        address owner2,
        address contractAddr,
        uint256 tokenId
    );

    struct SuccessionItem {
        address owner1;
        address owner2;
        address contractAddr;
        uint256 tokenId;
        uint256 time;
    }
    struct LossPreventionItem {
        address owner1;
        address owner2;
        address contractAddr;
        uint256 tokenId;
    }

    mapping(address => SuccessionItem[]) public successionByAddr;
    mapping(address => LossPreventionItem[]) public lossPreventionByAddr;

    function addSuccessionItem(
        address owner1,
        address owner2,
        address contractAddr,
        uint256 tokenId,
        uint256 time
    ) public onlyOwner {
        successionByAddr[owner1].push(
            SuccessionItem(owner1, owner2, contractAddr, tokenId, time)
        );
        emit SuccessionCreated(owner1, owner2, contractAddr, tokenId, time);
    }

    function addLossPreventionItem(
        address owner1,
        address owner2,
        address contractAddr,
        uint256 tokenId
    ) public onlyOwner {
        lossPreventionByAddr[owner1].push(
            LossPreventionItem(owner1, owner2, contractAddr, tokenId)
        );
        emit LossPreventionCreated(owner1, owner2, contractAddr, tokenId);
    }

    function getSuccessionItem(address owner1, uint256 index)
        public
        view
        returns (SuccessionItem memory)
    {
        return successionByAddr[owner1][index];
    }

    function getLossPreventionItem(address owner1, uint256 index)
        public
        view
        returns (LossPreventionItem memory)
    {
        return lossPreventionByAddr[owner1][index];
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