// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IETHRegistrarController {
	function available(string memory name) external view returns(bool);
	function registerWithConfig(string memory name, address owner, uint duration, bytes32 secret, address resolver, address addr) external payable;
	function rentPrice(string memory name, uint duration) external view returns(uint);
	function makeCommitmentWithConfig(string memory name, address owner, bytes32 secret, address resolver, address addr) pure external returns(bytes32);
	function commit(bytes32 commitment) external;
}

contract BulkRegistrar is Ownable {
	address constant ETHRegistrarControllerAddress = 0x283Af0B28c62C092C9727F1Ee09c02CA627EB7F5;
	uint public FEE = 0 ether;
	uint public perc_gasFee = 5;
	bool public flatFee = false;

	function getController() internal pure returns(IETHRegistrarController) {
		return IETHRegistrarController(ETHRegistrarControllerAddress);
	} 

	function available (string memory name) external view returns(bool) {
		IETHRegistrarController controller = getController();	
	 	return controller.available(name);	
	}

	function rentPrice(string[] calldata names, uint duration) external view returns(uint total) {
		IETHRegistrarController controller = getController();
		for(uint i = 0; i < names.length; i++) {
			total += controller.rentPrice(names[i], duration);
		}
	}
		
	function submitCommit(string[] calldata names, address owner, bytes32 secret, address resolver, address addr) external {
		IETHRegistrarController controller = getController();
		for(uint i = 0; i < names.length; i++) {
			bytes32 commitment = controller.makeCommitmentWithConfig(names[i], owner, secret, resolver, addr);
			controller.commit(commitment);
		}
	}

	function registerAll(string[] calldata names, address _owner, uint duration, bytes32 secret, address resolver, address addr) external payable {
		require(_owner == msg.sender, "Error: Caller must be the same address as owner");
	
		// Calculate fees
		uint fee;	
		if(!flatFee) {
			uint gas = gasleft();
			fee = (((gas * perc_gasFee) / 100) * tx.gasprice);
		} else {
			fee = FEE;
		}	
		
		IETHRegistrarController controller = getController();	
		for(uint i = 0; i < names.length; i++) {
			uint cost = controller.rentPrice(names[i], duration);
			controller.registerWithConfig{value:cost}(names[i], _owner, duration, secret, resolver, addr);
		}
		// Pay owner fee and Send any excess funds back
		payable(owner()).transfer(fee);
		payable(msg.sender).transfer(address(this).balance);
	}

	// Admin
	function setPercentageGas(uint256 percentage) external onlyOwner {
        perc_gasFee = percentage;
    }
	
	function changeFeeStyle(bool style) external onlyOwner {
		flatFee = style;
	}

	function changeFee(uint _fee) external onlyOwner {
		FEE = _fee;
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