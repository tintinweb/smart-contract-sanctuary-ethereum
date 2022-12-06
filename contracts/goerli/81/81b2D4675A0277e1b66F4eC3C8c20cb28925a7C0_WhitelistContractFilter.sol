// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./OwnableExt.sol";

/// @title Whitelist Contract Filter
/// @notice This contract is designed to add filter to WhitelistContract filter element
/// @dev Is a service contract for other contracts
contract WhitelistContractFilter is OwnableExt {
    /* Structure FilterBatch */
    struct FilterBatch {
        /* Address element for filters*/
        address element;
        /* Array filters addresses */
        address[] filters;
    }

    /// @notice Enables/disables the Whitelist Contract filter
    /// @dev Get property. For read
    bool public activeFilter = false;

    /// @notice Private WhitelistContract mapping
    /// @dev Get property. For read
    mapping(address => mapping(address => bool))
        public privateWhitelistContract;

    /// @notice Public WhitelistContract mapping
    /// @dev Get property. For read
    mapping(address => bool) public publicWhitelistContract;

    /// @notice Function add filter element for element private WhitelistContract
    /// @dev Public function. Only Admin
    /// @param element address element for WhitelistContractFilter
    /// @param contractAccount address filter for element
    function addFilterPrivate(address element, address contractAccount)
        public
        onlyAdmin
    {
        require(
            isContract(contractAccount),
            "The address you are trying to whitelist is not a contract!"
        );

        privateWhitelistContract[element][contractAccount] = true;

        emit AddingApproveContractAccount(element, contractAccount);
    }

    /// @notice Function remove filter element for element private WhitelistContract
    /// @dev Public function. Only Admin
    /// @param element address element for WhitelistContract
    /// @param contractAccount address filter for element
    function removeFilterPrivate(address element, address contractAccount)
        public
        onlyAdmin
    {
        require(
            isContract(contractAccount),
            "The address you are trying drop whitelist is not a contract!"
        );

        privateWhitelistContract[element][contractAccount] = false;

        emit RemovingApproveContractAccount(element, contractAccount);
    }

    function addFilterPublic(address contractAccount) external onlyAdmin {
        require(
            isContract(contractAccount),
            "The address you are trying to whitelist is not a contract!"
        );

        publicWhitelistContract[contractAccount] = true;
    }

    function removeFilterPublic(address contractAccount) external onlyAdmin {
        require(
            isContract(contractAccount),
            "The address you are trying drop whitelist is not a contract!"
        );
        publicWhitelistContract[contractAccount] = false;
    }

    /// @notice Function batch add filter element for element private WhitelistContract
    /// @dev Public function. Only Admin.
    /// @param filters Array struct contractAccountApprove (element -> filters);
    function addFilterPrivateBatch(FilterBatch[] calldata filters)
        external
        onlyAdmin
    {
        for (uint256 i = 0; i < filters.length; i++) {
            FilterBatch memory filter = filters[i];

            for (uint256 j = 0; j < filter.filters.length; j++) {
                if (!isContract(filter.filters[j])) continue;

                privateWhitelistContract[filter.element][
                    filter.filters[j]
                ] = true;

                emit AddingApproveContractAccount(
                    filter.element,
                    filter.filters[j]
                );
            }
        }
    }

    /// @notice Function batch remove filter element for element private WhitelistContract
    /// @dev Public function. Only Admin
    /// @param filters Array struct contractAccountApprove (element -> filters);
    function removeFilterPrivateBatch(FilterBatch[] calldata filters)
        external
        onlyAdmin
    {
        for (uint256 i = 0; i < filters.length; i++) {
            FilterBatch memory filter = filters[i];

            for (uint256 j = 0; j < filter.filters.length; j++) {
                if (!isContract(filter.filters[j])) continue;

                privateWhitelistContract[filter.element][
                    filter.filters[j]
                ] = false;

                emit RemovingApproveContractAccount(
                    filter.element,
                    filter.filters[j]
                );
            }
        }
    }

    /// @notice Function batch add filter element for WhitelistContract public
    /// @dev Public function. Only Admin
    /// @param filters address filters for WhitelistContract public
    function addFilterPublicBatch(address[] calldata filters)
        external
        onlyAdmin
    {
        for (uint256 i = 0; i < filters.length; i++) {
            if (!isContract(filters[i])) continue;

            publicWhitelistContract[filters[i]] = true;

            emit AddingApproveContractAccount(address(0x0), filters[i]);
        }
    }

    /// @notice Function batch remove filter element for WhitelistContract public
    /// @dev Public function. Only Admin
    /// @param filters address filters for WhitelistContract public
    function removeFilterPublicBatch(address[] calldata filters)
        external
        onlyAdmin
    {
        for (uint256 i = 0; i < filters.length; i++) {
            if (!isContract(filters[i])) continue;

            publicWhitelistContract[filters[i]] = false;

            emit RemovingApproveContractAccount(address(0x0), filters[i]);
        }
    }

    /// @notice Function enable/disable filter elements by WhitelistContract
    /// @dev Only Admin.
    /// @param isActive enable/disable filter (true - false)
    function changeFilter(bool isActive) external onlyAdmin {
        activeFilter = isActive;

        emit ChangingFilter(address(this), isActive);
    }

    /// @notice Function check filter element for WhitelistContract (and if contractAccount contract activity, otherwise true)
    /// @dev Public function. For read
    /// @param element address element for WhitelistContract
    /// @param contractAccount address filter for element
    function isApprovalContractAccount(address element, address contractAccount)
        public
        view
        returns (bool)
    {
        return
            activeFilter && isContract(contractAccount)
                ? isExistApprovalContractAccount(element, contractAccount)
                : true;
    }

    /// @notice Function check filter element for contractAccount element WhitelistContract or public contractAccount check
    /// @dev Private function. For read
    /// @param element address element for WhitelistContract (0x0 address - public WhitelistContract)
    /// @param contractAccount address filter for element
    function isExistApprovalContractAccount(
        address element,
        address contractAccount
    ) private view returns (bool) {
        return
            publicWhitelistContract[contractAccount]
                ? true
                : privateWhitelistContract[element][contractAccount];
    }

    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }

    /// @notice Adding Approve filter element event
    /// @param element address element for WhitelistContract
    /// @param contractAccount address filter for element
    event AddingApproveContractAccount(
        address element,
        address contractAccount
    );
    /// @notice Removing Approve contractAccount element event
    /// @param element address element for WhitelistContract
    /// @param contractAccount address contractAccount for element
    event RemovingApproveContractAccount(
        address element,
        address contractAccount
    );
    /// @notice Changing filter event
    /// @param contractAccount Address contract WhitelistContract
    /// @param status Status active filter
    event ChangingFilter(address contractAccount, bool status);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

///@title Contract extension for a contract Ownable
contract OwnableExt is Ownable {
    /// @notice Mapping admins
    mapping(address => bool) public admins;

    /* Modifier to check if the user is an admin */
    modifier onlyAdmin() {
        require(
            admins[msg.sender] || msg.sender == owner(),
            "The sender is not an admin!"
        );
        _;
    }

    /* Admin existence modifier */
    modifier checkExistAdmin(address _account) {
        require(
            admins[_account],
            "There is no such administrator in the list!"
        );
        _;
    }

    /// @notice Function to add admin
    /// @dev Only Owner
    /// @param _account Address account
    function addAdmin(address _account) external onlyOwner {
        admins[_account] = true;
    }

    /// @notice Function to remove admin
    /// @dev Only Owner
    /// @param _account Address account
    function deleteAdmin(address _account)
        external
        onlyOwner
        checkExistAdmin(_account)
    {
        delete admins[_account];
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