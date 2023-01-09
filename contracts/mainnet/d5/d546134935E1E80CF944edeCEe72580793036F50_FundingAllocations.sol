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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IFundingAllocations.sol";

/**
 * @title FundingAllocations
 * @author ChangeDao
 * @dev Contract stores the wallet address for ChangeDAO along with the percentages sent to ChangeDAO from minting fees and royalties from token sales.
 */

contract FundingAllocations is IFundingAllocations, Ownable {
    /* ============== State Variables ============== */

    address payable public override changeDaoWallet;
    /// @notice Shares are stored as basis points (of 10000)
    uint256 public override changeDaoRoyalties = 2000;
    uint256 public override changeDaoFunding = 500;

    /* ============== Constructor ============== */

    /**
     * @notice Sets address for the ChangeDao wallet
     * @param _changeDaoWallet ChangeDao wallet address
     */
    constructor(address payable _changeDaoWallet) {
        changeDaoWallet = _changeDaoWallet;
    }

    /* ============== Setter Functions ============== */

    /**
     * @notice Owner sets royalties share amount for ChangeDao wallet address
     * @dev Share amount over 10000 will cause payment splitter clones to revert. Share amount for ChangeDao should be less than 10000 to allow for recipients to receive shares
     * @param _royaltiesShares Royalties share amount for ChangeDao
     */
    function setChangeDaoRoyalties(uint256 _royaltiesShares)
        external
        override
        onlyOwner
    {
        require(_royaltiesShares <= 10000, "FA: Share amount cannot exceed 10000");
        changeDaoRoyalties = _royaltiesShares;
        emit SetRoyaltiesShares(_royaltiesShares);
    }

    /**
     * @notice Owner sets funding share amount for ChangeDao wallet address
     * @dev Share amount over 10000 will cause payment splitter clones to revert. Share amount for ChangeDao should be less than 10000 to allow for recipients to receive shares
     * @param _fundingShares Funding share amount for ChangeDao
     */
    function setChangeDaoFunding(uint256 _fundingShares)
        external
        override
        onlyOwner
    {
        require(_fundingShares <= 10000, "FA: Share amount cannot exceed 10000");
        changeDaoFunding = _fundingShares;
        emit SetFundingShares(_fundingShares);
    }

    /**
     * @notice Updates the address to which royalties and funding are sent
     * @param _changeDaoWallet Set address for the ChangeDao wallet
     */
    function setChangeDaoWallet(address payable _changeDaoWallet)
        external
        override
        onlyOwner
    {
        changeDaoWallet = _changeDaoWallet;
        emit NewWallet(_changeDaoWallet);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

/**
 * @title IFundingAllocations
 * @author ChangeDao
 */

interface IFundingAllocations {
    /* ============== Events ============== */

    /**
     * @notice Emitted when owner sets a new address for ChangeDao's wallet
     */
    event NewWallet(address indexed changeDaoWallet);

    /**
     * @notice Emitted when owner sets new royalties share amount for ChangeDao
     */
    event SetRoyaltiesShares(uint256 indexed shareAmount);

    /**
     * @notice Emitted when owner sets new funding share amount for ChangeDao
     */
    event SetFundingShares(uint256 indexed shareAmount);

    /* ============== Getter Functions ============== */

    function changeDaoWallet() external view returns (address payable);

    function changeDaoRoyalties() external view returns (uint256);
    
    function changeDaoFunding() external view returns (uint256);

    /* ============== Setter Functions ============== */

    function setChangeDaoRoyalties(uint256 _royaltiesShares) external;

    function setChangeDaoFunding(uint256 _fundingShares) external;

    function setChangeDaoWallet(address payable _changeDaoWallet) external;
}