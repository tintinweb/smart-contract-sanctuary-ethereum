//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./Interface/ISetting.sol";

contract Settings is ISettings, Ownable, Initializable {
    address payable livetree;

    address payable buyer;

    address governorLogic;

    address buyInLogic;

    string branchBuyerUsername;

    // uint256 buyerItem;

    // string buyerOfferId;

    uint256 ownerPercentage;

    uint256 buyerPercentage;

    address itemMgrProxyFactory;

    address treasury;

    constructor() {}

    function initialize(
        address _factory,
        address payable _livetree,
        address payable _buyer,
        string memory _branchBuyerUsername,
        uint256 _buyerItem,
        string memory _buyerOfferId,
        uint256 _ownerPercentage,
        uint256 _buyerPercentage
    ) external initializer {
        require(_buyerPercentage+_ownerPercentage <= 100, "E_INVALID_PERCENTAGES");
        itemMgrProxyFactory = _factory;
        livetree = _livetree;
        buyer = _buyer;
        branchBuyerUsername = _branchBuyerUsername;
        ownerPercentage = _ownerPercentage;
        buyerPercentage = _buyerPercentage;
    }

    function getOwnerPercentage() external view override returns (uint256) {
        return ownerPercentage;
    }

    function getBuyerPercentage() external view override returns (uint256) {
        return buyerPercentage;
    }

    function getBuyerBranchUsername()
        external
        view
        override
        returns (string memory)
    {
        return branchBuyerUsername;
    }

    function getBuyer() external view override returns (address payable) {
        return buyer;
    }

    function getLivetree() external view override returns (address payable) {
        return livetree;
    }

    function getItemMgrProxyFactory() external view override returns (address) {
        return itemMgrProxyFactory;
    }

    function getGovernorLogic() external view override returns (address) {
        return governorLogic;
    }

    function getBuyInLogic() external view override returns (address) {
        return buyInLogic;
    }

    function getTreasury() external view override returns (address) {
        return treasury;
    }

    modifier onlyFactory() {
        require(msg.sender == itemMgrProxyFactory);
        _;
    }

    function setGovernorLogic(address _govLogic) external override onlyFactory {
        governorLogic = _govLogic;
    }

    function setBuyInLogic(address _buyInLogic) external override onlyFactory {
        buyInLogic = _buyInLogic;
    }

    function setTreasury(address _treasury) external override onlyFactory {
        treasury = _treasury;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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
// OpenZeppelin Contracts v4.4.0 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISettings {
    function getBuyer() external view returns (address payable);

    function getLivetree() external view returns (address payable);

    function getOwnerPercentage() external view returns (uint256);

    function getBuyerPercentage() external view returns (uint256);

    function getBuyerBranchUsername() external view returns (string memory);

    // function getBuyerItemId() external view returns (uint256);

    // function getOfferId() external view returns (string memory);

    function getItemMgrProxyFactory() external view returns (address);

    function getGovernorLogic() external view returns (address);

    function getBuyInLogic() external view returns (address);

    function getTreasury() external view returns (address);

    function setGovernorLogic(address govAddress) external;

    function setBuyInLogic(address buyInAddress) external;

    function setTreasury(address treasury) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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