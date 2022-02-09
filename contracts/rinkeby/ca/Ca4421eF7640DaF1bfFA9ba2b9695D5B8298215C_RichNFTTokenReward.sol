// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./RichInterface.sol";

contract RichNFTTokenReward is Ownable {

    uint256 public emissionStart;

    uint256 public emissionPerDay;
    uint256 public SECONDS_IN_A_DAY = 86400;

    address public tokenAddress;
    address public nftAddress;

    mapping (address => uint256) balances;
    mapping (uint256 => uint256) _lastClaim;

    constructor(address _tokenAddress, address _nftAddress, uint256 _emissionRate) {
        tokenAddress = _tokenAddress;
        nftAddress = _nftAddress;
        emissionPerDay = _emissionRate * (10 ** 18);
        emissionStart = 0;
    }

    function startEmission() public onlyOwner {
        emissionStart = block.timestamp;
    }

    function lastClaim(uint256 tokenIndex) public view returns (uint256) {
        uint256 lastClaimed = uint256(_lastClaim[tokenIndex]) != 0 ? uint256(_lastClaim[tokenIndex]) : emissionStart;
        return lastClaimed;
    }

    function accumulated (uint256 tokenIndex) public view returns (uint256) {
        uint256 lastClaimed = lastClaim(tokenIndex);
        uint256 totalAccumulated = (block.timestamp - lastClaimed) * emissionPerDay / SECONDS_IN_A_DAY;
        return totalAccumulated;
    }

    function pendingRewards(uint256[] memory tokenIds) public view returns (uint256) {
        uint256 canClaimQty = 0;
        for(uint i = 0; i < tokenIds.length; i++) {
            canClaimQty += accumulated(tokenIds[i]);
        }
        return canClaimQty;
    }

    function claimReward (uint256[] memory tokenIds) public {
    
        uint256 canClaimQty = 0;

        for(uint i = 0; i < tokenIds.length; i++) {
            uint256 tokenIndex = tokenIds[i];
            require(IERC1155(nftAddress).balanceOf(msg.sender, tokenIndex) == 1, "Not NFT token owner");
            uint256 claimableForToken = accumulated(tokenIndex);
            canClaimQty += claimableForToken;
            if( claimableForToken > 0 ) {
                _lastClaim[tokenIndex] = block.timestamp;
            }
        }

        ERC20(tokenAddress).mint(msg.sender, canClaimQty);
    
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

pragma solidity ^0.8.0;

interface ERC20 {
    function mint(address account, uint256 amount) external;
    function burnFrom(address account, uint256 amount) external;
    function balanceOf(address account) external view returns (uint256);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    function approve(address spender, uint256 allowance) external;
}

interface IERC1155 {
    function balanceOf(address account, uint256 id) external view returns (uint256);
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