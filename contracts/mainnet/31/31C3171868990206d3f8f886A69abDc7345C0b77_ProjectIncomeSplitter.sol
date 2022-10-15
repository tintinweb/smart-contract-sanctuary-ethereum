/**
 *Submitted for verification at Etherscan.io on 2022-10-15
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


// File @openzeppelin/contracts/security/[email protected]

// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}


// File contracts/ProjectIncomeSplitter.sol

/**
 */

pragma solidity >=0.8.0 <0.9.0;


contract ProjectIncomeSplitter is 
    AdministratorOrOwner,
    ReentrancyGuard
{
    uint8 private splitToWallet = 100;
    address public wallet;
    address public community;

    constructor() {
    }
    
    // so we can receive payments
    fallback() external payable nonReentrant {}
    receive() external payable nonReentrant {}

    /**
     * ADMINISTRATION
     */

    // this enables us to withdraw funds
    function withdraw()
        public
        onlyOwnerOrAdministrator
        nonReentrant
    {
        require(wallet != address(0x0), "Wallet address is not set");
        require(address(community) != address(0x0), "Community address is not set");
        require(address(this).balance > 0, "Nothing to withdraw");

        uint8 walletShare;
        uint8 communityShare;
        (walletShare, communityShare) = showSplit();

        uint256 onePercent = address(this).balance / 100;

        bool success;
        (success, ) = (community).call{value: onePercent * communityShare}("");
        require(success, "Withdrawal to community failed");

        (success, ) = (wallet).call{value: onePercent * walletShare}("");
        require(success, "Withdrawal to wallet failed");
    }

    // function that enables us to set community address
    function setWalletShare(uint8 _share)
        public
        onlyOwnerOrAdministrator
    {
        require(_share < 101, "You cannot split more than 100 percent.");
        splitToWallet = _share;
    }

    // function that enables us to set wallet
    function setWallet(address _wallet)
        public
        onlyOwnerOrAdministrator
    {
        wallet = _wallet;
    }

    // function that enables us to set community splitter address
    function setCommunityAddress(address payable _community)
        public
        onlyOwnerOrAdministrator
    {
        community = _community;
    }

    /**
     * VIEWS
     */
    function showSplit()
        public
        view
        returns(uint8 _wallet, uint8 _community)
    {
        return (splitToWallet, 100 - splitToWallet);
    }
}