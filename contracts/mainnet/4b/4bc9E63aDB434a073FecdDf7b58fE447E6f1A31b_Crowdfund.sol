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
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
// import "hardhat/console.sol";

contract Crowdfund is Ownable {

	mapping ( address => uint256 ) public balances;
	uint256 public totalContributed = 0;
	address[] contributors;
	address public immutable daoSafeAddress = 0xc5e9Febecd9fD19597566aaE97A61EbCe73b2C8B;
	address public immutable revenueReceiver = 0xC79AE8FF0197FCefBECFfD89347dc4332bfcD4EA; // Sent to personal wallet of Papertree founder for now
	uint8 public immutable revenueShare = 10; // Papertree receives 10% of all contributions as revenue
	uint public immutable minimumContribution = 0.006 ether;

	// A global boolean variable is created to manage pause capabilities called paused
	bool public paused;

	event Contribution(address contributor, uint256 amount);
	event EarnedRevenue(address receiver, uint256 amount, address contributor);

	function contribute() public payable {
		require(paused == false, "Function Paused");
		require(msg.value >= minimumContribution, "Failed to send enough value. Minimum contribution is 0.006 ETH");

		// Receive and keep track of contributions
		if (balances[msg.sender] == 0) {
			contributors.push(msg.sender);
		}
		balances[msg.sender] += msg.value;
		totalContributed += msg.value;
		emit Contribution(msg.sender, msg.value);

		// Send 10% of contribution as revenue
		uint256 revenue =  msg.value / revenueShare;
		address payable receiver = payable(revenueReceiver);
		(bool sentToReceiver, bytes memory receiverData) = receiver.call{value: revenue}("");
		require(sentToReceiver, "Failed to send revenue Ether amount");
		emit EarnedRevenue(receiver, revenue, msg.sender);

		// Send the rest to the DAO
		address payable dao = payable(daoSafeAddress);
		(bool sentToDAO, bytes memory daoData) = dao.call{value: address(this).balance}("");
		require(sentToDAO, "Failed to send DAO Ether amount");
	}

	function withdraw() public onlyOwner {
		address payable owner = payable(msg.sender);
		(bool sent, bytes memory data) = owner.call{value: address(this).balance}("");
		require(sent, "Failed to send Ether");
	}

	function setPaused(bool _paused) public onlyOwner {
		paused = _paused;
	}

	function tip() public payable {
		// allow funds to be received directly to cover things like gas
	}

	// to support receiving ETH by default
	receive() external payable {
		contribute();
	}
	fallback() external {}

}