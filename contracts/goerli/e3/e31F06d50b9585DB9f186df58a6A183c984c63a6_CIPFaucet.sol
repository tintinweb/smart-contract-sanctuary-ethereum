pragma solidity 0.8.14;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

interface ISlotSettlementRegistry {
    function totalUserCollateralisedSLOTBalanceForKnot(
        address _stakeHouse, address _user, bytes calldata _knotId
    ) external view returns (uint256);
}

contract CIPFaucet is Ownable {

    /// @notice Amount per address to be claimed from the faucet
    uint256 public AMOUNT_PER_ADDRESS;

    /// @notice Slot registry interface to check the knot ownership
    ISlotSettlementRegistry public SLOT_REGISTRY = ISlotSettlementRegistry(0x1a86d0FE29c57e19f340C5Af34dE82946F22eC5d);

    /// @notice Tracking addresses which already claimed from the faucet
    mapping(address => bool) public claimTracker;

    /// @notice Notify the network about the claim
    event Claim(address claimer, uint256 amount, bytes knot);

    constructor(uint256 _amountPerAddress) {
        AMOUNT_PER_ADDRESS = _amountPerAddress;
    }

    /// @notice Change the per address amount to be claimed
    /// @param _amount - New amount to give on the claim
    function setAmountPerAddress(uint256 _amount) external onlyOwner {
        require(_amount > 0, 'New amount must be positive');
        AMOUNT_PER_ADDRESS = _amount;
    }

    /// @notice Withdraw the funds in the case of emergency
    function emergencyWithdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    /// @notice Claim from the faucet to cover some gas fees
    /// @param _knotId - ID of the knot to be claimed for
    /// @param _stakehouse - Stakehouse the knot belongs to
    function claim(bytes calldata _knotId, address _stakehouse) external {
        require(!claimTracker[msg.sender], 'Already claimed');
        require(_ownsKnot(msg.sender, _knotId, _stakehouse), 'User does not own a knot');

        claimTracker[msg.sender] = true;

        payable(msg.sender).transfer(AMOUNT_PER_ADDRESS);

        emit Claim(msg.sender, AMOUNT_PER_ADDRESS, _knotId);
    }

    /// @notice Check the collateralized SLOT ownership of the user
    /// @param _user - Address of the user
    /// @param _knotId - BLS public key of the knot
    /// @param _stakehouse - Stakehouse the knot is a part of
    function _ownsKnot(address _user, bytes calldata _knotId, address _stakehouse) internal view returns (bool) {
        return SLOT_REGISTRY.totalUserCollateralisedSLOTBalanceForKnot(_stakehouse, _user, _knotId) > 2 ether;
    }

    /// @notice Necessary for funding the contract
    receive() external payable {}
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