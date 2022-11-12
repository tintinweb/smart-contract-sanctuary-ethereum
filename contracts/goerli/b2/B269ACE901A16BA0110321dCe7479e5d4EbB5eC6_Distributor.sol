// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";

import "../ERC721/interfaces/IOilWell.sol";
import "./interfaces/IDistributor.sol";
contract Distributor is Ownable, IDistributor {
    address marketPlaceAddress;
    address oilWellAddress;
    address specialOilWellAddress;

    constructor() {}

    function distributeFunds(uint256 amount) external returns (bool) {
        require(msg.sender == marketPlaceAddress, "Only the marketplace is authorized to distribute funds");
        uint256 i = random(amount, 3);
        address well = i <= 1 ? oilWellAddress : specialOilWellAddress;
        return IOilWell(well).distributeFunds(amount);
    }

    function random(uint256 i, uint256 mod) private view returns (uint256) {
        uint256 ram = uint256(
            keccak256(abi.encodePacked(block.timestamp, block.difficulty, i))
        ) % mod;
        return ram;
    }

    function setOilWellAddress(address addr) external onlyOwner {
        require(addr != address(0), "Address cannot be 0");
        require(
            oilWellAddress == address(0),
            "It is not possible to change the address of the contract again"
        );
        oilWellAddress = addr;
    }

    function setSpecialOilWellAddress(address addr) external onlyOwner {
        require(addr != address(0), "Address cannot be 0");
        require(
            specialOilWellAddress == address(0),
            "It is not possible to change the address of the contract again"
        );
        specialOilWellAddress = addr;
    }

    function setMarketPlaceAddress(address addr) external onlyOwner {
        require(addr != address(0), "Address cannot be 0");
        require(
            marketPlaceAddress == address(0),
            "It is not possible to change the address of the contract again"
        );
        marketPlaceAddress = addr;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface IDistributor {
    function distributeFunds(uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface IOilWell {
    function createOilWell(uint256 price, uint barsAmount, string memory tokenURI, uint256 nonce, uint256 timestamp, bytes[] memory signatures) external returns (uint256);

    function getSupplyAmount(uint256 oilWellId) external view returns (uint256);

    function getBarsAmount(uint256 oilWellId) external view returns (uint256);

    function distributeFunds(uint256 amount) external returns (bool);
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