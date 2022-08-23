// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.2;

import "TimeLock.sol";

contract ApeRegistry is TimeLock {
	address public feeRegistry;
	address public router;
	address public distributor;
	address public factory;
	address public treasury;

	event FeeRegistryChanged(address feeRegistry);
	event RouterChanged(address router);
	event DistributorChanged(address distributor);
	event FactoryChanged(address factory);
	event TreasuryChanged(address treasury);

	constructor(address _treasury, uint256 _minDelay) TimeLock(_minDelay) {
		treasury = _treasury;
		emit TreasuryChanged(_treasury);
	}

	function setFeeRegistry(address _registry) external itself {
		feeRegistry = _registry;
		emit FeeRegistryChanged(_registry);
	}

	function setRouter(address _router) external itself {
		router = _router;
		emit RouterChanged(_router);
	}

	function setDistributor(address _distributor) external itself {
		distributor = _distributor;
		emit DistributorChanged(_distributor);
	}

	function setFactory(address _factory) external itself {
		factory = _factory;
		emit FactoryChanged(_factory);
	}

	function setTreasury(address _treasury) external itself {
		treasury = _treasury;
		emit TreasuryChanged(_treasury);
	}
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.2;

import "Ownable.sol";

contract TimeLock is Ownable {
	uint256 internal constant _DONE_TIMESTAMP = uint256(1);

	mapping(bytes32 => uint256) public timestamps;
	uint256 public minDelay;

	event CallScheduled(
        bytes32 indexed id,
        address target,
        bytes data,
        bytes32 predecessor,
        uint256 delay
    );

	event CallCancelled(bytes32 id);

	event CallExecuted(bytes32 indexed id, address target, bytes data);

	constructor(uint256 _minDelay) {
		minDelay = _minDelay;
	}


	modifier itself() {
		require(msg.sender == address(this), "TimeLock: Caller is not contract itself");
		_;
	}

	function changeMinDelay(uint256 _min) external itself {
		minDelay = _min;
	}

	function hashOperation(address _target, bytes calldata _data, bytes32 _predecessor, bytes32 _salt) internal pure returns(bytes32) {
		return keccak256(abi.encode(_target, _data, _predecessor, _salt));
	}

	function isPendingCall(bytes32 _id) public view returns(bool) {
		return timestamps[_id] > _DONE_TIMESTAMP;
	}

	function isDoneCall(bytes32 _id) public view returns(bool) {
		return timestamps[_id] == _DONE_TIMESTAMP;
	}

	function isReadyCall(bytes32 _id) public view returns(bool) {
		return timestamps[_id] <= block.timestamp && timestamps[_id] > _DONE_TIMESTAMP;
	}

	function schedule(address _target, bytes calldata _data, bytes32 _predecessor, bytes32 _salt, uint256 _delay) external onlyOwner {
		bytes32 id = hashOperation(_target, _data, _predecessor, _salt);
		require(timestamps[id] == 0, "TimeLock: Call already scheduled");
		require(_delay >= minDelay, "TimeLock: Insufficient delay");
		timestamps[id] = block.timestamp + _delay;
		emit CallScheduled(id, _target, _data, _predecessor, _delay);
	}

	function cancel(bytes32 _id) external onlyOwner {
		require(isPendingCall(_id), "TimeLock: Call is not pending");
		timestamps[_id] = 0;
		emit CallCancelled(_id);
	}

	function execute(address _target, bytes calldata _data, bytes32 _predecessor, bytes32 _salt, uint256 _delay) external onlyOwner {
		bytes32 id = hashOperation(_target, _data, _predecessor, _salt);
		require(isReadyCall(id), "TimeLock: Not ready for execution or executed");
		require(_predecessor == bytes32(0) || isDoneCall(_predecessor), "TimeLock: Predecessor call not executed");
		timestamps[id] = _DONE_TIMESTAMP;
		_call(id, _target, _data);
	}

	function _call(
        bytes32 id,
        address target,
        bytes calldata data
    ) internal {
        (bool success, ) = target.call(data);
        require(success, "Timelock: underlying transaction reverted");

        emit CallExecuted(id, target, data);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "Context.sol";
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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}