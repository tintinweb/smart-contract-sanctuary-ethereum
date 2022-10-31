/**
 *Submitted for verification at Etherscan.io on 2022-10-31
*/

// Sources flattened with hardhat v2.12.0 https://hardhat.org

// File contracts/IndexOf.sol

/**
 */

pragma solidity >=0.8.0 <0.9.0;

library IndexOf {
    function Address(address[] memory _haystack, address _needle)
        internal
        pure
        returns(uint256 _index, bool _found)
    {
        for (uint256 i = 0; i < _haystack.length; ++i) {
            if(_haystack[i] == _needle) {
                return (i, true);
            }
        }
        return (0, false);
    }

    function UInt256(uint256[] memory _haystack, uint256 _needle)
        internal
        pure
        returns(uint256 _index, bool _found)
    {
        for(uint256 i = 0; i < _haystack.length; i++) {
            if (_haystack[i] == _needle) {
                return (i, true);
            }
        }
        return (0, false);
    }
}


// File @openzeppelin/contracts/utils/[email protected]

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


// File @openzeppelin/contracts/access/[email protected]

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


// File contracts/AdministratorOrOwner.sol

pragma solidity ^0.8.13;


abstract contract AdministratorOrOwner is Ownable {
    address[] administrators;

    function addAdministrator(address _admin)
        public
        onlyOwnerOrAdministrator
    {
        (, bool found) = IndexOf.Address(administrators, _admin);
        require(!found, "Address is already an administrator");
        administrators.push(_admin);
    }

    function removeAdministrator(address _admin)
        public
        onlyOwnerOrAdministrator
    {
        (uint256 index, bool found) = IndexOf.Address(administrators, _admin);
        require(found, "Address is not an administrator");
        administrators[index] = administrators[administrators.length - 1];
        administrators.pop();
    }

    function isAdministrator(address _admin)
        public
        view
        onlyOwnerOrAdministrator
        returns (bool)
    {
        (, bool found) = IndexOf.Address(administrators, _admin);
        return found;
    }

    function getAdministrators()
        public
        view
        onlyOwnerOrAdministrator
        returns (address[] memory)
    {
        return administrators;
    }

    modifier onlyOwnerOrAdministrator()
    {
        (, bool found) = IndexOf.Address(administrators, _msgSender());
        require(owner() == _msgSender() || found, "You are not owner or administrator");
        _;
    }
}


// File contracts/RevenueSplitterV2.sol

/**
 */

pragma solidity >=0.8.0 <0.9.0;

contract RevenueSplitterV2 is AdministratorOrOwner{
    function splitRevenue (
        uint256 _totalStaked,
        address[] calldata _addresses,
        uint256[] calldata _stakedAmount
    )
        external
        payable
        onlyOwnerOrAdministrator
    {
        require(msg.value > 0, "No point splitting nothing");
        require(_totalStaked > 0, "No point splitting to nobody");
        require(_addresses.length == _stakedAmount.length, "Address length and staked amount length are not same");
        uint256 part = msg.value / _totalStaked;

        for (uint256 i; i < _addresses.length; ++i) {
            payable(_addresses[i]).transfer(part * _stakedAmount[i]);
        }
    }

    function withdrawLeftovers()
        external
        onlyOwnerOrAdministrator
    {
        payable(msg.sender).transfer(address(this).balance);
    }

    function getBalance()
        public
        view
        returns(uint256)
    {
        return address(this).balance;
    }
}