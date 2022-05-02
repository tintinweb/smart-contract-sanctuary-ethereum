//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import {ProxyVault} from "./ProxyVault.sol";
import {IRoyaltyVault} from "../interfaces/IRoyaltyVault.sol";

contract RoyaltyVaultFactory {
    /**** Immutable data ****/
    address public immutable royaltyVault;

    /**** Mutable data ****/
    address public royaltyAsset;
    address public splitterProxy;
    uint256 public platformFee;
    address public platformFeeRecipient;

    /**** Events ****/

    event VaultCreated(address vault);

    /**
     * @dev Constructor
     * @param _royaltyVault address of the RoyaltyVault logic contract
     */
    constructor(address _royaltyVault) {
        royaltyVault = _royaltyVault;
        platformFee = 500; // 5%
        platformFeeRecipient = 0x70388C130222eae55a0527a2367486bF5D12d6e7;
    }

    /**
     * @dev Create RoyaltyVault
     * @param _splitter address of the splitter contract.
     * @param _royaltyAsset address of the assets which will be splitted.
     */

    function createVault(address _splitter, address _royaltyAsset)
        external
        returns (address vault)
    {
        splitterProxy = _splitter;
        royaltyAsset = _royaltyAsset;

        vault = address(
            new ProxyVault{salt: keccak256(abi.encode(_splitter))}()
        );

        delete splitterProxy;
        delete royaltyAsset;
    }

    /**
     * @dev Set Platform fee for collection contract.
     * @param _platformFee Platform fee in scaled percentage. (5% = 200)
     * @param _vault vault address.
     */
    function setPlatformFee(address _vault, uint256 _platformFee) external {
        IRoyaltyVault(_vault).setPlatformFee(_platformFee);
    }

    /**
     * @dev Set Platform fee recipient for collection contract.
     * @param _vault vault address.
     * @param _platformFeeRecipient Platform fee recipient.
     */
    function setPlatformFeeRecipient(
        address _vault,
        address _platformFeeRecipient
    ) external {
        require(_vault != address(0), "Invalid vault");
        require(
            _platformFeeRecipient != address(0),
            "Invalid platform fee recipient"
        );
        IRoyaltyVault(_vault).setPlatformFeeRecipient(_platformFeeRecipient);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {VaultStorage} from "./VaultStorage.sol";
import {IVaultFactory} from "../interfaces/IVaultFactory.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract ProxyVault is VaultStorage, Ownable {
    address internal royaltyVault;

    /**
     *  @dev This is the constructor of the ProxyVault contract.
     *  It is called when the ProxyVault is created.
     *  It sets the variable royaltyVault to the address of the RoyaltyVault contract.
     */
    constructor() {
        royaltyVault = IVaultFactory(msg.sender).royaltyVault();
        splitterProxy = IVaultFactory(msg.sender).splitterProxy();
        royaltyAsset = IVaultFactory(msg.sender).royaltyAsset();
        platformFee = IVaultFactory(msg.sender).platformFee();
        platformFeeRecipient = IVaultFactory(msg.sender).platformFeeRecipient();
    }

    /**
     *  @dev This function is called when the ProxyVault is called, it points to the RoyaltyVault contract.
     */

    fallback() external payable {
        address _impl = royaltyVault;
        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize())
            let result := delegatecall(gas(), _impl, ptr, calldatasize(), 0, 0)
            let size := returndatasize()
            returndatacopy(ptr, 0, size)

            switch result
            case 0 {
                revert(ptr, size)
            }
            default {
                return(ptr, size)
            }
        }
    }

    receive() external payable {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IRoyaltyVault {
    function getSplitter() external view returns (address);

    function getVaultBalance() external view returns (uint256);

    function sendToSplitter() external;

    function setPlatformFee(uint256 _platformFee) external;

    function setPlatformFeeRecipient(address _platformFeeRecipient) external;

    function supportsInterface(bytes4 _interfaceId)
        external
        view
        returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract VaultStorage {
    address public splitterProxy;
    address public royaltyAsset;
    uint256 public platformFee;
    address public platformFeeRecipient;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IVaultFactory {
    function royaltyVault() external returns (address);
    function splitterProxy() external returns (address);
    function royaltyAsset() external returns (address);
    function platformFee() external returns (uint256);
    function platformFeeRecipient() external returns (address);
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