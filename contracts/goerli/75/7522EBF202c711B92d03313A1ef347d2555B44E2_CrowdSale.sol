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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

error AllShareSold();

contract CrowdSale is Ownable {
    struct Investor {
        uint256 amount;
        uint256 shareAmount;
    }

    enum State {
        Open,
        Closed
    }

    event ShareBought(address indexed investor, uint256 indexed shareAmount);

    uint256 private s_totalShare;
    uint256 private constant s_sharePrice = 100000000000000000;
    mapping(address => Investor) private s_investors;
    uint256 private s_shareLeft;
    State private s_state;
    address private immutable i_owner;

    constructor() {
        s_totalShare = 500;
        s_shareLeft = 500;
        i_owner = msg.sender;
        s_state = State.Open;
    }

    function buyShare() external payable {
        if (s_shareLeft == 0) {
            s_state = State.Closed;
            revert AllShareSold();
        }
        uint256 shareAmount = msg.value / s_sharePrice;
        uint256 shareleft = s_shareLeft - shareAmount;
        s_shareLeft = shareleft;
        s_investors[msg.sender] = Investor(msg.value, shareAmount);
        emit ShareBought(msg.sender, shareAmount);
    }

    function withdrawMoney() external payable onlyOwner {
        (bool success, ) = i_owner.call{value: address(this).balance}("");
        require(success, "Transaction failed");
    }

    function getTotalShare() external view returns (uint256) {
        return s_totalShare;
    }

    function getSharePrice() external pure returns (uint256) {
        return s_sharePrice;
    }

    function getInvestors() external view returns (Investor memory) {
        return s_investors[msg.sender];
    }

    function knowShareLeft() external view returns (uint256) {
        return s_shareLeft;
    }

    function knowTheState() external view returns (State) {
        return s_state;
    }

    function knowTheOwner() external view returns (address) {
        return i_owner;
    }
}