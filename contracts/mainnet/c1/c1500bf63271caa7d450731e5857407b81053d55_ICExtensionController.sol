// SPDX-License-Identifier: MIT
/*
     888888888           888888888           888888888     
   8888888888888       8888888888888       8888888888888   
 88888888888888888   88888888888888888   88888888888888888 
8888888888888888888 8888888888888888888 8888888888888888888
8888888     8888888 8888888     8888888 8888888     8888888
8888888     8888888 8888888     8888888 8888888     8888888
 88888888888888888   88888888888888888   88888888888888888 
  888888888888888     888888888888888     888888888888888  
 88888888888888888   88888888888888888   88888888888888888 
8888888     8888888 8888888     8888888 8888888     8888888
8888888     8888888 8888888     8888888 8888888     8888888
8888888     8888888 8888888     8888888 8888888     8888888
8888888888888888888 8888888888888888888 8888888888888888888
 88888888888888888   88888888888888888   88888888888888888 
   8888888888888       8888888888888       8888888888888   
     888888888           888888888           888888888
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./I888ICExtensionSale.sol";

contract ICExtensionController is Ownable {
    I888ICExtensionSale[] private _saleContracts;

    function addContract(address[] memory _contracts) external onlyOwner {
        for (uint i = 0; i < _contracts.length; i++) {
            _saleContracts.push(I888ICExtensionSale(_contracts[i]));
        }
    }

    function removeContract(uint256[] memory indexes) external onlyOwner {
        for (uint i = 0; i < indexes.length; i++) {
            _saleContracts[indexes[i]] = _saleContracts[_saleContracts.length - 1];
            _saleContracts.pop();
        }
    }

    function toggleSale() external onlyOwner {
        for (uint i; i < _saleContracts.length; i++) {
            _saleContracts[i].toggleSale();
        }
    }

    function toggleClaimCode() external onlyOwner {
        for (uint i; i < _saleContracts.length; i++) {
            _saleContracts[i].toggleClaimCode();
        }
    }

    function toggleInnerCircle() external onlyOwner {
        for (uint i; i < _saleContracts.length; i++) {
            _saleContracts[i].toggleInnerCircle();
        }
    }

    function toggleAllowList() external onlyOwner {
        for (uint i; i < _saleContracts.length; i++) {
            _saleContracts[i].toggleAllowList();
        }
    }

    function setSignerAddress(address newSigner) external onlyOwner {
        for (uint i; i < _saleContracts.length; i++) {
            _saleContracts[i].setSignerAddress(newSigner);
        }
    }

    function updatePrice(uint256 newPrice) external onlyOwner {
        for (uint i; i < _saleContracts.length; i++) {
            _saleContracts[i].updatePrice(newPrice);
        }
    }

    function withdraw() external onlyOwner {
        for (uint i; i < _saleContracts.length; i++) {
            _saleContracts[i].withdraw();
        }
    }
}

// SPDX-License-Identifier: MIT
/*
     888888888           888888888           888888888     
   8888888888888       8888888888888       8888888888888   
 88888888888888888   88888888888888888   88888888888888888 
8888888888888888888 8888888888888888888 8888888888888888888
8888888     8888888 8888888     8888888 8888888     8888888
8888888     8888888 8888888     8888888 8888888     8888888
 88888888888888888   88888888888888888   88888888888888888 
  888888888888888     888888888888888     888888888888888  
 88888888888888888   88888888888888888   88888888888888888 
8888888     8888888 8888888     8888888 8888888     8888888
8888888     8888888 8888888     8888888 8888888     8888888
8888888     8888888 8888888     8888888 8888888     8888888
8888888888888888888 8888888888888888888 8888888888888888888
 88888888888888888   88888888888888888   88888888888888888 
   8888888888888       8888888888888       8888888888888   
     888888888           888888888           888888888
 */
pragma solidity ^0.8.0;

interface I888ICExtensionSale {
    function toggleSale() external;
    function toggleClaimCode() external;
    function toggleInnerCircle() external;
    function toggleAllowList() external;
    function setSignerAddress(address) external;
    function updatePrice(uint256) external;
    function withdraw() external;
}

// SPDX-License-Identifier: MIT

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

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