// SPDX-License-Identifier: MIT
import "@openzeppelin/contracts/access/Ownable.sol";

pragma solidity ^0.8.17;

/*
                                        
                 --.                    
               .*%@*=.                  
              .##++=***+:               
            :+*#%#**#*#%#+.             
          .+##+-#%###%%%%%+             
        :+#+:..-#%%%%%#*+++             
 .::---=##++*#%%%%#%%##*==*             
  :#%%%%%%%%%%%%%%%%####+*#-            
 -*==#%%%%%%%%%#***#####%##*.           
.: .=%%%%%%%%#****%%###%%%#**.          
   :-=%%%%%%*#**#%%%#%#%%%%#%*:         
     #%%%%%%+**%##%#=#%%%%%%%%*:        
     :.--+###*+-.::   *#%%#%%%#=.       
        .****.:::::::+#%%%%%%%#++       
...::::-*#**==++++++*%%%%%%%%%%##*=.    
.::----=##*===++++++*%%%%%%%%%%%%###*:  
::::::=##=----==++++*%%%%%%%%%%%%%%%#*. 
:-===*##+.     ..-=++*#%%%%%%%%%%%%*+.  
 .:-**+.            ...:--====-::..  
 */
 
contract HyperwarpManager is Ownable {

    bool public isHyperwarpingPaused = false;

    uint256 public maxUtilityBattlerId = 1000;

    function flipHyperwarpingState() public onlyOwner {
        isHyperwarpingPaused = !isHyperwarpingPaused;
    }

    function setMaxUtilityBattlerId(uint256 _tokenId) public onlyOwner {
        maxUtilityBattlerId = _tokenId;
    }

    function battlerHasUtility(uint256 _tokenId, uint8 _calledFrom) public view returns(bool) {
        return _tokenId <= maxUtilityBattlerId;
    }

    function battlerHasUtilityCount(uint256 _startTokenId, uint256 _batchSize, uint8 _calledFrom) public view returns(uint256 count) {
        for(uint256 i = 0; i < _batchSize;) {
            if (battlerHasUtility(_startTokenId + i, 3)) {
                unchecked {
                    ++count;
                }
            }
            unchecked {
                ++i;
            }
        }  
    }

    function tryHyperwarp(uint256 _jumpClone, uint256 _assist, uint256 _mintIndex) external view returns(bool) {
        require(_jumpClone != _assist, "Jumpcloner and assist must be different");
        require(!isHyperwarpingPaused, "Hyperwarping is paused");
        require(battlerHasUtility(_jumpClone, 0), "Not an alpha species");
        require(battlerHasUtility(_assist, 0), "Not an alpha species");
        //we should check that the mintIndex is not an alpha species but we allow this during
        //the hyperclone transcedance. We also no longer have to worry about it once the mintIndex
        //reaches the maxUtilityBattlerId
        return true;
    }

    function tryManifest(uint256 _tokenId) external pure returns(bool) {
        return true;
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