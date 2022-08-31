// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../utils/IndexedMapping.sol";
import "./MembersInterface.sol";

/// @title AMKT Members
/// @author Alongside Finance
/// @notice Explain to an end user what this does
/// @dev Explain to a developer any extra details
contract Members is MembersInterface, Ownable {
    ///=============================================================================================
    /// Events
    ///=============================================================================================

    event FactoryAdminSet(address indexed factoryAdmin);
    event CustodianSet(address indexed custodian);
    event MerchantAdd(address indexed merchant);
    event MerchantRemove(address indexed merchant);

    ///=============================================================================================
    /// State Variables
    ///=============================================================================================

    using IndexedMapping for IndexedMapping.Data;

    address public factoryAdmin;

    address public custodian;

    IndexedMapping.Data internal merchants;

    ///=============================================================================================
    /// Constructor
    ///=============================================================================================

    constructor(address newOwner) {
        require(newOwner != address(0), "invalid newOnwer address");
        transferOwnership(newOwner);
    }

    ///=============================================================================================
    /// Setters
    ///=============================================================================================

    /// @notice Allows the owner of the contract to set the factoryAdmin
    /// @param _factoryAdmin address
    /// @return bool
    function setFactoryAdmin(address _factoryAdmin)
        external
        override
        onlyOwner
        returns (bool)
    {
        require(_factoryAdmin != address(0), "invalid custodian address");
        factoryAdmin = _factoryAdmin;

        emit FactoryAdminSet(_factoryAdmin);
        return true;
    }

    /// @notice Allows the owner of the contract to set the custodian
    /// @param _custodian address
    /// @return bool
    function setCustodian(address _custodian)
        external
        override
        onlyOwner
        returns (bool)
    {
        require(_custodian != address(0), "invalid custodian address");
        custodian = _custodian;

        emit CustodianSet(_custodian);
        return true;
    }

    /// @notice Allows the owner of the contract to add a merchant
    /// @param merchant address
    /// @return bool
    function addMerchant(address merchant)
        external
        override
        onlyOwner
        returns (bool)
    {
        require(merchant != address(0), "invalid merchant address");
        require(merchants.add(merchant), "merchant add failed");

        emit MerchantAdd(merchant);
        return true;
    }

    /// @notice Allows the owner of the contract to remove a merchant
    /// @param merchant address
    /// @return bool
    function removeMerchant(address merchant)
        external
        override
        onlyOwner
        returns (bool)
    {
        require(merchant != address(0), "invalid merchant address");
        require(merchants.remove(merchant), "merchant remove failed");

        emit MerchantRemove(merchant);
        return true;
    }

    ///=============================================================================================
    /// Non Mutable
    ///=============================================================================================

    function isFactoryAdmin(address addr)
        external
        view
        override
        returns (bool)
    {
        return (addr == factoryAdmin);
    }

    function isCustodian(address addr) external view override returns (bool) {
        return (addr == custodian);
    }

    function isMerchant(address addr) external view override returns (bool) {
        return merchants.exists(addr);
    }

    function getMerchant(uint256 index) external view returns (address) {
        return merchants.getValue(index);
    }

    function getMerchants() external view override returns (address[] memory) {
        return merchants.getValueList();
    }

    function merchantsLength() external view override returns (uint256) {
        return merchants.valueList.length;
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
pragma solidity 0.8.7;

library IndexedMapping {

    ///=============================================================================================
    /// Data Structures
    ///=============================================================================================

    struct Data {
        mapping(address => bool) valueExists;
        mapping(address => uint256) valueIndex;
        address[] valueList;
    }

    ///=============================================================================================
    /// Mutable
    ///=============================================================================================

    function add(Data storage self, address val) internal returns (bool) {
        if (exists(self, val)) return false;

        self.valueExists[val] = true;
        
        // push value to the actual list
        // no longers returns index
        self.valueList.push(val);

        // set the index by subtracting 1
        self.valueIndex[val] = self.valueList.length - 1;
        return true;
    }

    function remove(Data storage self, address val) internal returns (bool) {

        if (!exists(self, val)) return false;

        uint256 index = self.valueIndex[val];
        address lastVal = self.valueList[self.valueList.length - 1];

        // replace value we want to remove with the last value
        self.valueList[index] = lastVal;

        // adjust index for the shifted value
        self.valueIndex[lastVal] = index;

        // remove the last item
        self.valueList.pop();

        // remove value
        delete self.valueExists[val];
        delete self.valueIndex[val];

        return true;
    }

    ///=============================================================================================
    /// Non Mutable
    ///=============================================================================================

    function exists(Data storage self, address val) internal view returns (bool) {
        return self.valueExists[val];
    }

    function getValue(Data storage self, uint256 index) internal view returns (address) {
        return self.valueList[index];
    }

    function getValueList(Data storage self) internal view returns (address[] memory) {
        return self.valueList;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface MembersInterface {
    function setFactoryAdmin(address factoryAdmin) external returns (bool);

    function setCustodian(address custodian) external returns (bool);

    function addMerchant(address merchant) external returns (bool);

    function removeMerchant(address merchant) external returns (bool);

    function isFactoryAdmin(address addr) external view returns (bool);

    function isCustodian(address addr) external view returns (bool);

    function isMerchant(address addr) external view returns (bool);

    function getMerchants() external view returns (address[] memory);

    function merchantsLength() external view returns (uint256);
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