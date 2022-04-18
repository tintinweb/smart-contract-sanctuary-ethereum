// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./IGoldz.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface ILandz {
    function mint(uint quantity, address receiver) external;
}

contract LandzGoldzSale is Ownable {
    IGoldz _goldz = IGoldz(0x65831300D395E93065a7284f450B63293B640458);
    ILandz _landz = ILandz(0x3Be9645B4AFd8980236f6A0320a8b8984f4ddbEc);

    bool public isSalesActive;
    uint public basePrice;
    uint public incrementalPrice;
    uint public incrementalQuantity;
    uint public totalMints;
    
    constructor() {
        isSalesActive = true;
        basePrice = 400 ether;
        incrementalPrice = 30 ether;
        incrementalQuantity = 150;
    }

    function mint(uint quantity) external {
        require(isSalesActive, "sale is not active");
        
        _goldz.transferFrom(msg.sender, address(this), price() * quantity);
        
        _landz.mint(quantity, msg.sender);

        totalMints += quantity;
    }

    function price() public view returns (uint) {
        return basePrice + (totalMints / incrementalQuantity) * incrementalPrice;
    }

    function toggleSales() external onlyOwner {
        isSalesActive = !isSalesActive;
    }
    
    function setPrice(uint newBasePrice, uint newIncrementalPrice, uint newIncrementalQuantity) external onlyOwner {
        basePrice = newBasePrice;
        incrementalPrice = newIncrementalPrice;
        incrementalQuantity = newIncrementalQuantity;
    }

    function burnGoldz() external onlyOwner {
        uint balance = _goldz.balanceOf(address(this));
        _goldz.burn(balance);
    }

    function withdrawGoldz() external onlyOwner {
        uint amount = _goldz.balanceOf(address(this));
        _goldz.transfer(msg.sender, amount);
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
pragma solidity ^0.8.2;

abstract contract IGoldz {
    function burn(uint256 amount) public virtual;
    function balanceOf(address account) public view virtual returns (uint256);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual returns (bool);
    function transfer(
        address recipient,
        uint256 amount
    ) public virtual returns (bool);
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