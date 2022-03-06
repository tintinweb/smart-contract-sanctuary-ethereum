// SPDX-License-Identifier: MIT

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";

error NotAllowed();
error ToMuchToWithdraw();
error ETHTransferFailed();
error NoBalanceToWithdraw();

contract Depositor is Ownable {

    struct TeamMember {
        uint16 percentage;
        uint256 balance;
    }

    // receiver address of the team members
    address[4] public receiverAddresses;
    // details of funds received by team member
    mapping(address => TeamMember) public team;

	constructor(address[4] memory receiverAddresses_, uint8[4] memory receiverPercentages_) {
		receiverAddresses = receiverAddresses_;
		for (uint256 i; i < receiverAddresses_.length; i++) {
			team[receiverAddresses_[i]] = TeamMember(receiverPercentages_[i], 0);
		}
	}

	/*
	 * accepts ether sent with no txData
	 */
	receive() external payable {
		for (uint256 i; i < receiverAddresses.length; i++) {
			address receiverAddress = receiverAddresses[i];
			uint256 maxToWithdraw = (msg.value * team[receiverAddress].percentage) / 100;
			_sendValueTo(receiverAddress, maxToWithdraw);
		}
	}

	/**
	 * @dev Change the current team member address with a new one
	 * @param newAddress Address which can withdraw the ETH based on percentage
	 */
	function changeTeamMemberAddress(address newAddress) external {
		bool found;
		for (uint256 i; i < receiverAddresses.length; i++) {
			if (receiverAddresses[i] == _msgSender()) {
				receiverAddresses[i] = newAddress;
				found = true;
				break;
			}
		}
		if (!found) revert NotAllowed();

		team[newAddress] = team[_msgSender()];
		delete team[_msgSender()];
	}

	/**
	 * @dev Send an amount of value to a specific address
	 * @param to_ address that will receive the value
	 * @param value to be sent to the address
	 */
	function _sendValueTo(address to_, uint256 value) internal {
		address payable to = payable(to_);
		(bool success, ) = to.call{ value: value }("");
		if (!success) revert ETHTransferFailed();
	}
}