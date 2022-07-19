/**
 *Submitted for verification at Etherscan.io on 2022-07-18
*/

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: contracts/FakeMarketPrice.sol



pragma solidity ^0.8.4;


/*
FakeMarketPrice.sol

Idea by Kilo and joe.

written by:
mousedev.eth

edited by:
thnod

Implications of using FakeMarketPrice.sol

Any call to _convertCentsToWei will fail.

These includes:
1. modifier onlyOwnerOrAdmin
    a. This means the fake market price MUST detect if sender is an admin, and continue to work if it is.
2. createRandomizedIpc
3. createIpcSeed
4. buyIpc
5. changeIpcName
6. modifyDna
7. buyXp
8. getIpcPriceInWei

Since _convertCentsToWei is called within the onlyOwnerOrAdmin modifier, these functions are also affected:
1. setIpcPrice
2. rollAttributes
3. customizeDna
4. randomizeDna
5. changeAdminAuthorization
6. setSpecialPriceForAddress
7. changeIpcName

However, we can solve this by allowing admin accounts to call the USD function.

The side effects are that under no circumstance can a user call the included functions without admin access.
*/


interface MarketPrice {
    function USD(uint256 _id) external view returns (uint256);
}

//=============================================================================
//=============================================================================
contract FakeMarketPrice is Ownable {
    
    MarketPrice public OldMarketPrice = MarketPrice(0x2138FfE292fd0953f7fe2569111246E4DE9ff1DC);
    
    bool public willRevert = true;
    bool public allowAdminUsage = true;
    
    address[] public admins;  // added so that admins are publicly visible
    uint public numberOfAdmins = 0;  // needed for enumeration
    mapping(address => bool) public isAdmin;


    //-------------------------------------------------------------------------
    //-------------------------------------------------------------------------
    function setOldMarketPriceContract(address _marketPriceAddress) external onlyOwner {
        OldMarketPrice = MarketPrice(_marketPriceAddress);
    }

    //-------------------------------------------------------------------------
    //-------------------------------------------------------------------------
    function setRevert(bool _willRevert) external onlyOwner {
        willRevert = _willRevert;
    }

    //-------------------------------------------------------------------------
    //-------------------------------------------------------------------------
    function setAdminUsage(bool _allowAdminUsage) external onlyOwner {
        allowAdminUsage = _allowAdminUsage;
    }

    //-------------------------------------------------------------------------
    //-------------------------------------------------------------------------
    function setAdmin(address _admin, bool _isAdmin) external onlyOwner {
        // check if admin needs to be added to list
        if (!isAdmin[_admin] && _isAdmin) {
            admins.push(_admin);
        }
        // check if admin needs to be removed from list
        else if (isAdmin[_admin] && !_isAdmin) {
            // find the admin in admins array
            for (uint i = 0; i < admins.length; ++i) {
                if (admins[i] == _admin) {
                    // replace admin with the last element in the list
                    admins[i] == admins[admins.length-1];
                    // pop the list to remove the admin
                    admins.pop();
                    break;
                }
            }
        }
        else {
            revert("admin is already set to the value of _isAdmin");
        }

        isAdmin[_admin] = _isAdmin;
    }

    //-------------------------------------------------------------------------
    //-------------------------------------------------------------------------
    function USD(uint256) external view returns (uint256) {
        if (willRevert) {
            //If admins are allowed and they are one, return old market price.
            if (allowAdminUsage && isAdmin[tx.origin]) {
                return OldMarketPrice.USD(0);
            }
            else {
                //revert.
                revert();
            }
        }
        //If reverting it turned off, return old market price.
        return OldMarketPrice.USD(0);
    }
}