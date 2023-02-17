// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

/// @title JIRAX Sales Controller
/// @author @whiteoakkong
/// @notice This contract is designed to control the sale of JIRAX - the off-chain token for PG and associated projects.

import "@openzeppelin/contracts/access/Ownable.sol";

contract JIRAXSalesController is Ownable {
    event Deposit(address indexed sender, uint256 amount, address partner);

    mapping(address => uint256) public PartnerRegistry;

    address public JIRA;
    address public INFINIT3;

    uint256 private developerSplit;

    constructor(address _JIRA, address _INFINIT3, uint256 _developerSplit) {
        JIRA = _JIRA;
        INFINIT3 = _INFINIT3;
        developerSplit = _developerSplit;
    }

    function deposit(address partner) external payable {
        uint256 affiliateSplit = (msg.value * PartnerRegistry[partner]) / 100;
        if (affiliateSplit > 0) {
            (bool success, ) = payable(partner).call{value: affiliateSplit}("");
            require(success, "Transfer failed.");
        }
        emit Deposit(msg.sender, msg.value, partner);
    }

    function setPartner(address partner, uint256 split) external onlyOwner {
        PartnerRegistry[partner] = split;
    }

    function withdraw() external {
        require(msg.sender == INFINIT3 || msg.sender == JIRA || msg.sender == owner(), "Not authorized");
        uint256 fee = (address(this).balance * developerSplit) / 100;
        (bool success, ) = payable(INFINIT3).call{value: fee}("");
        require(success, "Transfer failed.");
        (success, ) = payable(JIRA).call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function setDeveloperSplit(uint256 _developerSplit) external onlyOwner {
        developerSplit = _developerSplit;
    }

    function changeWallets(address _address, uint256 selector) external onlyOwner {
        if (selector == 0) JIRA = _address;
        else if (selector == 1) INFINIT3 == _address;
        else revert("Incorrect selector");
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