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

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IComptroller {
    /// @notice The COMP accrued but not yet transferred to each user
    function compAccrued(address account) external view returns (uint256);

    /// @notice Claim all the comp accrued by holder in all markets
    function claimComp(address holder) external;
}

contract ClaimComptrollers is Ownable {
    address public admin;
    address[] public comptrollers;

    modifier onlyOwnerOrAdmin() {
        require(msg.sender == owner() || msg.sender == admin, "caller is not owner or admin");
        _;
    }

    constructor(address[] memory _comptrollers, address _admin) {
        comptrollers = _comptrollers;
        admin = _admin;
    }

    /**
     * @notice Claim all the comp accrued by holder in the all comptrollers
     * @param holder The address to claim COMP for
     */
    function claimAll(address holder) external {
        address[] memory comptrollers_ = comptrollers;

        for (uint256 i = 0; i < comptrollers_.length; i++) {
            uint256 claimAmount_ = IComptroller(comptrollers_[i]).compAccrued(holder);
            if (claimAmount_ > 0) {
                IComptroller(comptrollers_[i]).claimComp(holder);
            }
        }
    }

    /**
     * @notice Claim all the comp accrued by holder in the all comptrollers
     * @param holder The address to claim COMP for
     * @param _comptrollers The addresses of user with claim COMP
     */
    function claimAllWithAddress(address holder, address[] memory _comptrollers) external {
        for (uint i = 0; i < _comptrollers.length; i++) {
            IComptroller(_comptrollers[i]).claimComp(holder);
        }
    }

    /**
     * @notice Get total rewards amount to claim
     * @param holder The address to claim COMP for
     */
    function getAllComAccrued(address holder) external view returns (uint256 totalAmount) {
        address[] memory comptrollers_ = comptrollers;

        for (uint256 i = 0; i < comptrollers_.length; i++) {
            uint256 claimAmount_ = IComptroller(comptrollers_[i]).compAccrued(holder);
            totalAmount += claimAmount_;
        }
    }

    /**
     * @notice Get comptrollers address to user with claim COMP
     * @param holder The address to claim COMP for
     */
    function getComptrollersAddress(address holder) external view returns (address[] memory) {
        address[] memory comptrollers_ = comptrollers;
        address[] memory addresses = new address[](comptrollers_.length);

        for (uint256 i = 0; i < comptrollers_.length; i++) {
            uint256 claimAmount_ = IComptroller(comptrollers_[i]).compAccrued(holder);
            if (claimAmount_ > 0) {
                addresses[i] = comptrollers_[i];
            }
        }

        return addresses;
    }

    /**
     * @notice Remove comptroller address for index from the comptroller's address list
     * called by only owner or admin address
     * @param index The uint index of comptroller address to remove
     */
    function removeComptroller(uint index) external onlyOwnerOrAdmin {
        require(index <= comptrollers.length, "index should be less than length of comptrollers");
        comptrollers[index] = comptrollers[comptrollers.length - 1];
        comptrollers.pop();
    }

    /**
     * @notice Add new comptroller address to the comptroller's address list
     * called by only owner or admin address
     * @param comptroller The address of new comptroller to add
     */
    function addComptroller(address comptroller) external onlyOwnerOrAdmin {
        require(comptroller != address(0), "invalid address");
        comptrollers[comptrollers.length] = comptroller;
    }

    /**
     * @notice Change admin address, called by only owner
     * @param newAdmin The address of new admin
     */
    function changeAdmin(address newAdmin) external onlyOwner {
        require(newAdmin != address(0), "invalid address");
        admin = newAdmin;
    }
}