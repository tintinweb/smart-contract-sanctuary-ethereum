// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IMovingDots.sol";

/**
 * @dev Custom smart contract that implements a public
 * mint strategy for the Moving Dots NFT. Access control
 * is used for owner-based transactions.
 *
 * @author Karim Guettache
 */
contract MDSaleContract is Ownable {

    /**
     * @dev Interface instance representing the
     * Moving Dots Contract.
     */    
    IMovingDots public MD_NFT;

    /**
     * @dev Toggle to turn on - off the public mint
     * Only modifiable by owner
     */
    bool public isMintActive;

    /**
     * @dev Maximum mintable MD NFTs per user
     * Only modifiable by owner
     */
    uint256 public mintLimitPerUser;

    /**
     * @dev Maximum supply of MD NFTs that can be minted through this contract.
     * Only modifiable by owner
     */
    uint256 public maxSupply;

    /**
     * @dev Tracks minted MD NFTs per wallet
     */
    mapping(address => uint256) public userToMintedDots;

    /**
     * @dev Emitted on each public mint transaction
     *
     * @param minter The wallet of the user initiating the transaction
     * @param amount The amount of NFTs the user succesfull minted in the transaction
     */
    event PublicMint(address indexed minter, uint256 indexed amount);

    constructor(
        address _movingDots
    ) Ownable() {
        MD_NFT = IMovingDots(_movingDots);

        isMintActive = true;
        mintLimitPerUser = 10;
        maxSupply = 100;
    }

    /**
     * @dev Receive function relays and funds sent to the owner of the contract.
     */
    receive() external payable {
        payable(owner()).transfer(address(this).balance);
    }

    /**
     * @dev Public mint function allowing users to mint up to 
     * "mintLimitPerUser" NFTs with a global limit of "maxSupply" NFTs.
     * Access to this function is regulated through the "isMintActive" variable.
     *
     * @param amount The amount of NFTs to be minted.
     */
    function publicMint(uint256 amount) external {
        require(isMintActive, "MD :: Mint Not Active");
        require(MD_NFT.totalSupply() + amount <= maxSupply, "MD :: Max Supply Reached");
        require(userToMintedDots[msg.sender] + amount <= mintLimitPerUser, "MD :: Mint Limit Reached");

        MD_NFT.mint(msg.sender, amount);
        emit PublicMint(msg.sender, amount);
    }
    
    /**
     * @dev Allows for the configuration of the mint settings by the owner wallet.
     *
     * @param _isActive Controls the "isMintActive" variable
     * @param _mintLimit Controls the "mintLimitPerUser" variable
     * @param _maxSupply Controls the "maxSupply" variable
     */
    function configureMint(bool _isActive, uint256 _mintLimit, uint256 _maxSupply) external onlyOwner {
        isMintActive = _isActive;
        mintLimitPerUser = _mintLimit;
        maxSupply = _maxSupply;
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

pragma solidity ^0.8.13;

interface IMovingDots {
    function mint(address receiver, uint256 amount) external;
    function totalSupply() external view returns (uint256);
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