// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/access/Ownable.sol";

interface FriendlyContract {
    function name() external view returns (string memory);
    function balanceOf(address owner) external view returns(uint256);
}

contract Whitelist is Ownable {
    mapping(address => uint) private Entries ;
    mapping(address => bool) private Graylist ;
    address public operator ;
    
    event setContractEntries(address _contract, uint256 _newSupply);

    constructor () {}

    function setOperator(address _operator) public onlyOwner {
        operator = _operator ;
    }

    function setEntries(address _contract, uint _entries) public onlyOwner {
        Entries[_contract] = _entries ;
        emit setContractEntries(_contract, _entries);
    }

    function getEntries(address _contract) public view returns( uint ) {
        return( Entries[_contract]) ;
    }

    function isWhitelisted(address _contract, address _user) public view returns (bool) {
        if (Entries[_contract] == 0) {
            return(false);
        }
        if (Graylist[_user]) {
            return(false);
        }
        FriendlyContract externalNft = FriendlyContract(_contract) ;
        
        return ( (externalNft.balanceOf(_user) > 0)? true : false );
    }

    function update(address _contract, address _user) public {
        require( msg.sender == operator, "You are not the operator" );
        require( !Graylist[_user] , "Address alredy used the whitelist." );
        require( Entries[_contract] > 0, "Contract provided has no entries left.") ;
        Entries[_contract] -= 1 ;
        Graylist[_user] = true ;
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