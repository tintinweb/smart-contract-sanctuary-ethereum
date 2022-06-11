// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface IERC721{
    function transferFrom(address,address,uint256) external;
}

contract BuyLegacyFriends is Ownable, ReentrancyGuard {
        uint256 public constant _buyPrice = 0.05 ether;
        address private _withdrawalWallet = 0xCa87b367554B1A92b41923F789d1ffc9DC2CCA3d; // admin wallet address
        address private _legacyContractAddress = 0x96Af517c414B3726c1B2Ecc744ebf9d292DCbF60; // LegacyFriends Alpha contract address
        uint256 public bullsLimit = 118;
        uint256 public miniLimit = 94;
        uint256 public badgeLimit = 115;
        uint256 public chefLimit = 157;
        uint256 public lastClaimedBull = 289;
        uint256 public lastClaimedMini = 642;
        uint256 public lastClaimedBadge = 1181;
        uint256 public lastClaimedChef = 1789;


        modifier onlyWithdrawalWalletOrOwner {
            require(msg.sender == _withdrawalWallet || msg.sender == owner());
            _;
        }

        function setWithdrawlWallet(address _newWithdrawlWallet) external onlyWithdrawalWalletOrOwner {
            _withdrawalWallet = _newWithdrawlWallet;
        }

        function setBullsLimit(uint _newLimit) external {
            require(msg.sender == _withdrawalWallet);
            bullsLimit = _newLimit;
        }

        function setMiniLimit(uint _newLimit) external {
            require(msg.sender == _withdrawalWallet);
            miniLimit = _newLimit;
        }

        function setBadgeLimit(uint _newLimit) external {
            require(msg.sender == _withdrawalWallet);
            badgeLimit = _newLimit;
        }

        function setChefLimit(uint _newLimit) external {
            require(msg.sender == _withdrawalWallet);
            chefLimit = _newLimit;
        }

        function withdrawAll() external {
            require(msg.sender == _withdrawalWallet);
            uint256 _each = address(this).balance;
            require(payable(_withdrawalWallet).send(_each), "Transfer Failed");
        }

        function buyBadge() external payable nonReentrant returns(bool) {
            uint256 tokenId = --lastClaimedBadge;
            require(checkId(tokenId), "LegacyFriends: No NFT available");
            require(msg.value == _buyPrice, "LegacyFriends: Send more Ethers");
            IERC721(_legacyContractAddress).transferFrom(_withdrawalWallet, msg.sender, tokenId);
            return true;
        }

        function buyMini() external payable nonReentrant returns(bool) {
            uint256 tokenId = --lastClaimedMini;
            if(tokenId == 500) { 
                tokenId = 499; 
                lastClaimedMini = tokenId;
            }
            require(checkId(tokenId), "LegacyFriends: No NFT available");
            require(msg.value == _buyPrice, "LegacyFriends: Send more Ethers");
            IERC721(_legacyContractAddress).transferFrom(_withdrawalWallet, msg.sender, tokenId);
            return true;
        }

        function buyChef() external payable nonReentrant returns(bool) {
            uint256 tokenId = --lastClaimedChef;
            if(tokenId <= 1735 && tokenId >= 1728) { 
                tokenId = 1727; 
                lastClaimedChef = tokenId;
            }
            require(checkId(tokenId), "LegacyFriends: No NFT available");
            require(msg.value == _buyPrice, "LegacyFriends: Send more Ethers");
            IERC721(_legacyContractAddress).transferFrom(_withdrawalWallet, msg.sender, tokenId);
            return true;
        }

        function buyBull() external payable nonReentrant returns(bool) {
            uint256 tokenId = --lastClaimedBull;
            if(tokenId == 200) { 
                tokenId = 199;
                lastClaimedBull = tokenId; 
            }
            require(checkId(tokenId), "LegacyFriends: No NFT available");
            require(msg.value == _buyPrice, "LegacyFriends: Send more Ethers");
            IERC721(_legacyContractAddress).transferFrom(_withdrawalWallet, msg.sender, tokenId);
            return true;
        }

        function checkId(uint _tokenId) internal returns(bool){
                if(_tokenId >= 153 && _tokenId <= 288 && bullsLimit != 0){
                    unchecked{
                    bullsLimit--;
                    }
                    return true;
                }
                if(_tokenId >= 427 && _tokenId <= 641 && miniLimit != 0){
                    unchecked{
                    miniLimit--;
                    }
                    return true;
                }
                if(_tokenId >= 1044 && _tokenId <= 1180 && badgeLimit != 0){
                    unchecked{
                    badgeLimit--;
                    }
                    return true;
                }
                if(_tokenId >= 1602 && _tokenId <= 1788 && chefLimit != 0){
                    unchecked{
                    chefLimit--;
                    }
                    return true;
                }
                return false;
            }
}

// SPDX-License-Identifier: MIT
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