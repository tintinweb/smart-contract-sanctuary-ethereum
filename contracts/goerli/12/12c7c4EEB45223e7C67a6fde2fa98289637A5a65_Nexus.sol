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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { INexusCaller } from "./interfaces/INexusCaller.sol";
import { INexus } from "./interfaces/INexus.sol";
import { INexusRelay } from "./interfaces/INexusRelay.sol";
import { NexusRelayDeployer } from "./NexusRelayDeployer.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Nexus is Ownable, NexusRelayDeployer, INexus {
	function withdraw() external onlyOwner {
		payable(msg.sender).transfer(address(this).balance);
	}

	function deposit() external payable {}

	receive() external payable {}

	function sendMessage(
		uint256 destinationChainId,
		address targetContractAddress,
		uint256 fee,
		bytes memory _message,
		uint8 _provider,
		address _refundAddress
	) external payable isValidProvider(_provider) {
		require(
			msg.value >= fee,
			"msg.value must be greater than or equal to fee"
		);
		uint256 category = 0;
		bytes memory _callData = abi.encode(
			msg.sender,
			_message,
			category,
			targetContractAddress
		);
		internalNexusRelays[_provider].transmit{ value: fee }(
			destinationChainId,
			_callData,
			address(0),
			0,
			_refundAddress
		);
		emit MessageSent(destinationChainId, fee, _callData, _provider);
	}

	function sendTokenWithMessage(
		uint256 destinationChainId,
		address targetContractAddress,
		uint256 fee,
		bytes memory _message,
		uint8 _provider,
		address _refundAddress,
		address _token,
		uint256 _amount
	) external payable isValidProvider(_provider) {
		require(
			msg.value >= fee,
			"msg.value must be greater than or equal to fee"
		);
		uint256 category = 1;
		bytes memory _callData = abi.encode(
			msg.sender,
			_message,
			category,
			targetContractAddress
		);
		IERC20 token = IERC20(_token);
		require(
			token.allowance(msg.sender, address(this)) >= _amount,
			"User must approve amount"
		);

		token.transferFrom(msg.sender, address(this), _amount);
		token.approve(address(internalNexusRelays[_provider]), _amount);

		internalNexusRelays[_provider].transmit{ value: fee }(
			destinationChainId,
			_callData,
			_token,
			_amount,
			_refundAddress
		);
		emit TokenWithMessageSent(
			destinationChainId,
			fee,
			_callData,
			_provider,
			_token,
			_amount
		);
	}

	function receiveCallback(
		uint256 _amount,
		address _asset,
		address, // _senderAddress
		uint256 _senderChainId,
		bytes memory _callData,
		uint8 _provider
	)
		external
		override
		isValidProvider(_provider)
		onlyValidProvider(_provider)
	{
		(
			address _sourceAddress,
			bytes memory _message,
			uint8 category,
			address _destinationAddress
		) = abi.decode(_callData, (address, bytes, uint8, address));

		if (_amount > 0) {
			IERC20 token = IERC20(_asset);
			token.transferFrom(msg.sender, address(this), _amount);
			token.approve(_destinationAddress, _amount);
		}

		if (category == 0) {
			INexusCaller(_destinationAddress).onReceiveMessage(
				_senderChainId,
				_sourceAddress,
				_message
			);
			emit MessageReceived(_senderChainId, _amount, _callData);
		} else if (category == 1) {
			IERC20(_asset).transfer(_destinationAddress, _amount);
			INexusCaller(_destinationAddress).onReceiveTokenWithMessage(
				_senderChainId,
				_sourceAddress,
				_message,
				_asset,
				_amount
			);
			emit TokenWithMessageReceived(
				_senderChainId,
				_amount,
				_callData,
				_asset,
				_amount
			);
		} else revert("Category not supported");
	}

	modifier onlyValidProvider(uint8 _provider) {
		require(
			_msgSender() == address(internalNexusRelays[_provider]),
			"Invalid caller"
		);
		_;
	}

	modifier isValidProvider(uint8 _provider) {
		require(internalNexusRelays.length > _provider, "Invalid provider");
		_;
	}
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { INexusRelay } from "./interfaces/INexusRelay.sol";

abstract contract NexusRelayDeployer is Ownable {
	INexusRelay[] public internalNexusRelays;

	function setInternalNexusRelay(
		uint256 _index,
		address _nexusRelay
	) external onlyOwner {
		require(_index <= internalNexusRelays.length, "Index out of bounds");
		if (internalNexusRelays.length == _index)
			internalNexusRelays.push(INexusRelay(_nexusRelay));
		else internalNexusRelays[_index] = INexusRelay(_nexusRelay);
	}

	function addInternalNexusRelay(address _nexusRelay) external onlyOwner {
		internalNexusRelays.push(INexusRelay(_nexusRelay));
	}

	function checkInternalNexusRelay(
		uint256 chainId,
		address relay
	) external view returns (bool) {
		return (chainId < internalNexusRelays.length &&
			address(internalNexusRelays[chainId]) == relay);
	}
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

interface INexus {
	event MessageSent(
		uint256 destinationChainId,
		uint256 fee,
		bytes _callData,
		uint8 _provider
	);
	event TokenWithMessageSent(
		uint256 destinationChainId,
		uint256 fee,
		bytes _callData,
		uint8 _provider,
		address _token,
		uint256 _amount
	);
	event TokenWithMessageReceived(
		uint256 sourceChainId,
		uint256 fee,
		bytes _callData,
		address _token,
		uint256 _amount
	);
	event MessageReceived(uint256 sourceChainId, uint256 fee, bytes _callData);

	function deposit() external payable;

	function sendMessage(
		uint256 destinationChainId,
		address targetContractAddress,
		uint256 fee,
		bytes memory _message,
		uint8 _provider,
		address _refundAddress
	) external payable;

	function sendTokenWithMessage(
		uint256 destinationChainId,
		address targetContractAddress,
		uint256 fee,
		bytes memory _message,
		uint8 _provider,
		address _refundAddress,
		address _token,
		uint256 _amount
	) external payable;

	// For NexusRelay
	function receiveCallback(
		uint256 _amount,
		address _asset,
		address _senderAddress,
		uint256 _senderChainId,
		bytes memory _message,
		uint8 _provider
	) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

interface INexusCaller {
	function onReceiveMessage(
		uint256 sourceChainId,
		address sourceContractAddress,
		bytes calldata _message
	) external;

	function onReceiveTokenWithMessage(
		uint256 sourceChainId,
		address sourceContractAddress,
		bytes calldata _message,
		address _token,
		uint256 _amount
	) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

interface INexusRelay {
	function transmit(
		uint256 destinationChainId,
		bytes memory message,
		address _token,
		uint256 amount,
		address _refundAddress
	) external payable;
}