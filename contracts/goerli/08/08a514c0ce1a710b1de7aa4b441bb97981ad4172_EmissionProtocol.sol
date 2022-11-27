/**
 *Submitted for verification at Etherscan.io on 2022-11-27
*/

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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

pragma solidity 0.8.17;

/**
 * @title Emission Protocol
 * @dev Storing and retrieving relevant emission information
 */

contract EmissionProtocol is Ownable {
    /**
     * @dev Emission Struct witn Category enumeration
     */
    enum Category {
        Production,
        Transport
    }

    struct Emission {
        string accountIdHash;
        string orderIdHash;
        uint256 orderYear;
        uint256 energyKWH;
        uint256 energyRenewablePercent;
        uint256 co2KG;
        Category category;
    }

    Category category;
    Emission[] emissionsArray;

    /**
     * @dev mapping with authorized from owner addresses. In stead of having onlyOwner as the only admin of the smart contract, we can have also authorized accounts to perfrom certain actions like recording emissions
     * @dev Emission mapping takes as an input the @orderIdHash and outputs the emission data
     * @dev Look if orderID is already registered
     */

    mapping(address => bool) authorized;
    mapping(string => Emission) emission;
    mapping(string => bool) public registeredOrder;

    modifier onlyAuthorized() {
        require(authorized[msg.sender] || owner() == msg.sender);
        _;
    }

    /**
     * @dev Add address to authorized list
     * @param _toAdd adds authorized user to the mapping
     */
    function addAuthorized(address _toAdd) public onlyOwner {
        require(_toAdd != address(0));
        authorized[_toAdd] = true;
    }

    /**
     * @dev Removes address from the authorized list
     * @param _toRemove removes user from the authorized mapping list
     */
    function removeAuthorized(address _toRemove) public onlyOwner {
        require(_toRemove != address(0));
        require(_toRemove != msg.sender);
        authorized[_toRemove] = false;
    }

    function isAuthorized(address _address) external view returns (bool) {
       if (owner() == msg.sender) {
           return true;
       } else {
       return authorized[_address];
       }
    }

    /**
     * @dev Add emission data as a tuple, for category we take 0 for Production and 1 for Transport
     * @notice Takes all relevant data from the emission struct to add new emission entry
     * @notice Impossible to register same order twice
     */

    function add(Emission memory _emissionData) onlyAuthorized public {
        require(!registeredOrder[_emissionData.orderIdHash], "There is already registered order with this orderID");
        registeredOrder[_emissionData.orderIdHash] = true;
        Emission memory newEmissionEntry = _emissionData;
        emissionsArray.push(newEmissionEntry);
        emission[_emissionData.orderIdHash] = newEmissionEntry;
    }

    /**
     * @dev Takes as input @orderIdHash and returns production emission data
     */

    function getEmissionData(string memory _orderIdHash)
        public
        view
        returns (
            string memory,
            string memory,
            uint256,
            uint256,
            uint256,
            uint256,
            string memory
        )
    {
        string memory categoryStyle;

        if (emission[_orderIdHash].category == Category.Production) {
            categoryStyle = "Production";
        } else {
            categoryStyle = "Transport";
        }

        return (
            emission[_orderIdHash].accountIdHash,
            emission[_orderIdHash].orderIdHash,
            emission[_orderIdHash].orderYear,
            emission[_orderIdHash].energyKWH,
            emission[_orderIdHash].energyRenewablePercent,
            emission[_orderIdHash].co2KG,
            categoryStyle
        );
    }
}