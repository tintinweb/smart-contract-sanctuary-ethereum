/**
 *Submitted for verification at Etherscan.io on 2023-02-27
*/

// File @openzeppelin/contracts/security/[email protected]

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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


// File contracts/Vault.sol

pragma solidity ^0.8.6;
/// @title Collection interface for Vault interaction

interface Collection {
    function returnNft(address _from, uint256 _tokenId) external;
    function burnNft(uint256 _tokenId) external;
    function getTokenIdToPrice(uint256 _tokenId) external view returns (uint256);
    function exists(uint256 _tokenId) external view returns(bool);
    function getMaxSupply() external view returns (uint256);
}

/// @title Vault contract for returning nft's to collection
/// @author GeometricalDominator

contract Vault is Ownable, ReentrancyGuard{
    
    address private s_collectionContract;
    uint256 private s_totalBurned;

    function setCollectionContract(address _collectionContract) external onlyOwner() {
        s_collectionContract = _collectionContract;
    }

    /// @dev function for returning nft's, can't return 0 or more than 8 nft's

    function returnNfts(uint256[] memory _tokenIds) external nonReentrant() {
        if (_tokenIds.length == 0) {
            revert("No tokens transfered");
        }

        for (uint i = 0; i < _tokenIds.length; i++) {
            if (!Collection(s_collectionContract).exists(_tokenIds[i])) {
                revert("one of token doesnt exist");
            } 
        }
        
        if (s_totalBurned == Collection(s_collectionContract).getMaxSupply() - 1 && _tokenIds.length == 1) {
            (bool success, ) = msg.sender.call{value: address(this).balance}("");
            require(success, "Tx failed");
            Collection(s_collectionContract).burnNft(_tokenIds[0]);
            s_totalBurned++;
        }

        uint256 totalPrice;
        uint256 value;
        if (_tokenIds.length == 1) {
            uint256 tokenPrice = Collection(s_collectionContract).getTokenIdToPrice(_tokenIds[0]) / 2;
            (bool success, ) = msg.sender.call{value: tokenPrice}("");
            require(success, "Tx failed");

            Collection(s_collectionContract).burnNft(_tokenIds[0]);
            s_totalBurned++;

        } else if (_tokenIds.length == 2) {

            for (uint i = 0; i <= 1; i++) {
                uint256 tokenPrice = Collection(s_collectionContract).getTokenIdToPrice(_tokenIds[i]);
                totalPrice = totalPrice + tokenPrice;
            }

            value = 56 * totalPrice / 100;
            
            (bool success, ) = msg.sender.call{value: value}("");
            require(success, "Tx failed");

            Collection(s_collectionContract).returnNft(msg.sender, _tokenIds[0]);

            Collection(s_collectionContract).burnNft(_tokenIds[1]);
            s_totalBurned++;

        } else if (_tokenIds.length == 3) {

            for (uint i = 0; i <= 2; i++) {
                uint256 tokenPrice = Collection(s_collectionContract).getTokenIdToPrice(_tokenIds[i]);
                totalPrice = totalPrice + tokenPrice;
            }

            value = 63 * totalPrice / 100;

            (bool success, ) = msg.sender.call{value: value}("");
            require(success, "Tx failed");

            for (uint i = 0; i <= 1; i++) {
                Collection(s_collectionContract).returnNft(msg.sender, _tokenIds[i]);
            }

            Collection(s_collectionContract).burnNft(_tokenIds[2]);
            s_totalBurned++;

        } else if (_tokenIds.length == 4) {
          

            for (uint i = 0; i <= 3; i++) {
                uint256 tokenPrice = Collection(s_collectionContract).getTokenIdToPrice(_tokenIds[i]);
                totalPrice = totalPrice + tokenPrice;
            }

            value = 69 * totalPrice / 100;

            (bool success, ) = msg.sender.call{value: value}("");
            require(success, "Tx failed");

            for (uint i = 0; i <= 1; i++) {
                Collection(s_collectionContract).returnNft(msg.sender, _tokenIds[i]);
            }  

            for (uint i = 2; i <= 3; i++) {
                Collection(s_collectionContract).burnNft(_tokenIds[i]);
                s_totalBurned++;
            }

        } else if (_tokenIds.length == 5) {
            
            for (uint i = 0; i <= 4; i++) {
                uint256 tokenPrice = Collection(s_collectionContract).getTokenIdToPrice(_tokenIds[i]);
                totalPrice = totalPrice + tokenPrice;
            }

            value = 76 * totalPrice / 100;

            (bool success, ) = msg.sender.call{value: value}("");
            require(success, "Tx failed");

            for (uint i = 0; i <= 2; i++) {
                Collection(s_collectionContract).returnNft(msg.sender, _tokenIds[i]);
            }

            for (uint i = 3; i <= 4; i++) {
                Collection(s_collectionContract).burnNft(_tokenIds[i]);
                s_totalBurned++;
            }

        } else if (_tokenIds.length == 6) {

            for (uint i = 0; i <= 5; i++) {
                uint256 tokenPrice = Collection(s_collectionContract).getTokenIdToPrice(_tokenIds[i]);
                totalPrice = totalPrice + tokenPrice;
            }

            value = 82 * totalPrice / 100;

            (bool success, ) = msg.sender.call{value: value}("");
            require(success, "Tx failed");

            for (uint i = 0; i <= 2; i++) {
                Collection(s_collectionContract).returnNft(msg.sender, _tokenIds[i]);
            }

            for (uint i = 3; i <= 5; i++) {
                Collection(s_collectionContract).burnNft(_tokenIds[i]);
                s_totalBurned++;
            }

        } else if (_tokenIds.length == 7) {
            
            for (uint i = 0; i <= 6; i++) {
                uint256 tokenPrice = Collection(s_collectionContract).getTokenIdToPrice(_tokenIds[i]);
                totalPrice = totalPrice + tokenPrice;
            }

            value = 89 * totalPrice / 100;

            (bool success, ) = msg.sender.call{value: value}("");
            require(success, "Tx failed");

            for (uint i = 0; i <= 3; i++) {
                Collection(s_collectionContract).returnNft(msg.sender, _tokenIds[i]);
            }

            for (uint i = 4; i <= 6; i++) {
                Collection(s_collectionContract).burnNft(_tokenIds[i]);
                s_totalBurned++;
            }


        } else if (_tokenIds.length == 8) {
            
            for (uint i = 0; i < 8; i++) {
                uint256 tokenPrice = Collection(s_collectionContract).getTokenIdToPrice(_tokenIds[i]);
                totalPrice = totalPrice + tokenPrice;
            }

            value = 95 * totalPrice / 100;

            (bool success, ) = msg.sender.call{value: value}("");
            require(success, "Tx failed");

            for (uint i = 0; i <= 3; i++) {
                Collection(s_collectionContract).returnNft(msg.sender, _tokenIds[i]);
            }

            for (uint i = 4; i <= 7; i++) {
                Collection(s_collectionContract).burnNft(_tokenIds[i]);
                s_totalBurned++;
            }

        } else if (_tokenIds.length > 8) {
            revert("Too much tokens");
        } 
    }

    function getBatchReturnProcentagePerToken(uint256 _amount) public pure returns(string memory _return) {

        if (_amount == 0) {
            return "0";
        }
        
        if (_amount == 1) {
            return "50%";
        }
        
        if (_amount == 2) {
            return "56%";
        }
        
        if (_amount == 3) {
            return "63%";
        }
        
        if (_amount == 4) {
            return "69";
        }
        
        if (_amount == 5) {
            return "76";
        }
        
        if (_amount == 6) {
            return "82";
        }
        
        if (_amount == 7) {
            return "89";
        }
        
        if (_amount == 8) {
            return "95";
        }
        
        if (_amount > 8) {
            return "Can't be more than 8";
        }
    }

    function getCollectionContract() public view returns (address) {
        return s_collectionContract;
    }

    function getVaultBalance() public view returns(uint256) {
        return address(this).balance;
    }

    function getTotalBurned() public view returns(uint256) {
        return s_totalBurned;
    }

    receive() external payable {

    }

}