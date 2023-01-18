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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IOilWell {
    function create(uint256 price, uint barsAmount, address owner) external returns(uint256);
    
    function getSupplyAmount(uint256 oilWellId) external view returns (uint256);

    function getBarsAmount(uint256 oilWellId) external view returns (uint256);

    function distributeFunds(uint256 amount) external returns (bool);

    function getCurrentBarsAmount(uint256 oilWellId) external view returns (uint256);

    function getMinigCounter(uint256 oilWellId) external view returns (uint256);

    function getBarSupply(uint256 wellId, uint256 i) external view returns (uint256);

    function claimMyBars(uint256 amount, uint256 wellId) external;

    function claimMyAwardBars(uint256 amount, uint256 wellId, uint256 totalEachBars) external;

    function explodeBars(uint256 amount, address to) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";

import "../ERC721/interfaces/IOilWell.sol";
import "./interfaces/IDistributor.sol";

contract Distributor is Ownable, IDistributor {
    bool private development = true; //Allows you to change contract addresses or make allowed changes without having to redeploy
    address private marketPlaceAddress;
    address private oilWellAddress;
    uint256 private distributionPool;

    event DistributionResult(uint256 amount, string message);

    constructor() {}

    function newOilWell(uint256 price, uint256 bars, address owner) external onlyMarketplace returns (uint256) {
        return IOilWell(oilWellAddress).create(price, bars, owner);
    }

    function getOilWellAddress() external view returns (address) {
        return oilWellAddress;
    }

    function distributeFunds(uint256 amount) external onlyMarketplace returns (uint256) {
        bool result = IOilWell(oilWellAddress).distributeFunds(amount);

        if(result == false){
            distributionPool += amount;
            emit DistributionResult(0, "The collateral could not be distributed to the supply of wells, the collateral will be saved until a new distribution");
            return 0;
        }

        uint256 distribution = distributionPool + amount;
        distributionPool = 0;
        emit DistributionResult(distribution, "Collateral was successfully distributed");
        return distribution;
    }

    function setOilWellAddress(address addr) external onlyOwner {
        require(addr != address(0), "Address cannot be 0");
        require(
            oilWellAddress == address(0) || development,
            "It is not possible to change the address of the contract again"
        );
        oilWellAddress = addr;
    }

    function setMarketPlaceAddress(address addr) external onlyOwner {
        require(addr != address(0), "Address cannot be 0");
        require(
            marketPlaceAddress == address(0) || development,
            "It is not possible to change the address of the contract again"
        );
        marketPlaceAddress = addr;
    }

    function goToProduction() external onlyOwner{
         development = false;
    }

    modifier onlyMarketplace {
        require(msg.sender == marketPlaceAddress, "Only the marketplace is authorized");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IDistributor {
    function distributeFunds(uint256 amount) external returns (uint256);
    function newOilWell(uint256 price, uint256 bars, address owner) external returns(uint256);
    function getOilWellAddress() external view returns (address);
}