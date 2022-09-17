// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "./Interfaces/ISoulboundFactory.sol";
import "./Interfaces/IERC4973RepFactory.sol";
import "./Interfaces/IERC4973AttestFactory.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PostFactory is Ownable {


	string public creator;
	uint256 public mintFee;
	address public soulboundFactoryAddress;
	address public erc4973RepFactoryAddress;
	address public erc4973AttestFactoryAddress;

	// Events
	event DropCreated(
		string dropType,
		address dropAddress
	);

	constructor(string memory _creator, uint256 _mintFee) {
		creator = _creator;
		mintFee = _mintFee;
	}

	function createSoulboundToken(
		string memory _name,
		string memory _symbol,
		string memory version,
		string memory _uri,
		bytes32 _root,
		uint256 _mintLimit,
		uint256 initialTokenId
	) external payable returns (address) {
		require(msg.value >= mintFee, "Value sent less than mintFee");
		ISoulboundFactory soulboundFactory = ISoulboundFactory(
			soulboundFactoryAddress
		);
		address dropAddress = soulboundFactory.createDrop(
			_name,
			_symbol,
			version,
			_uri,
			_root,
			_mintLimit,
			initialTokenId
		);
		emit DropCreated("Soulbound",dropAddress);
		return dropAddress;
	}

	function createSoulboundReputationToken(
		string memory _name,
		string memory _symbol,
		string memory version,
		string memory _uri,
		bytes32 _root,
		uint256 _mintLimit,
		uint256 initialTokenId,
		uint256 _addIncrement,
		uint256 _reduceIncrement
	) external payable returns (address) {
		require(msg.value >= mintFee, "Value sent less than mintFee");
		IERC4973RepFactory erc4973RepFactory = IERC4973RepFactory(
			erc4973RepFactoryAddress
		);
		address dropAddress = erc4973RepFactory.createDrop(
			_name,
			_symbol,
			version,
			_uri,
			_root,
			_mintLimit,
			initialTokenId,
			_addIncrement,
			_reduceIncrement
		);
		emit DropCreated("ERC4973Rep",dropAddress);
		return dropAddress;
	}

	function createSoulboundAttestationToken(
		string memory _name,
		string memory _symbol,
		string memory version,
		string memory _uri,
		bytes32 _root,
		uint256 _mintLimit,
		uint256 initialTokenId
	) external payable returns (address) {
		require(msg.value >= mintFee, "Value sent less than mintFee");
		IERC4973AttestFactory erc4973AttestFactory = IERC4973AttestFactory(
			erc4973AttestFactoryAddress
		);

		address dropAddress = erc4973AttestFactory.createDeploy(
			_name,
			_symbol,
			version,
			_uri,
			_root,
			_mintLimit,
			initialTokenId
		);
		emit DropCreated("ERC4973Attest", dropAddress);
		return dropAddress;
	}

	function setMintFee(uint _mintFee) external onlyOwner() {
		mintFee = _mintFee;
	}

    function setAddresses(address[3] memory addressList) external onlyOwner() {
        soulboundFactoryAddress = addressList[0];
        erc4973RepFactoryAddress = addressList[1];
        erc4973AttestFactoryAddress = addressList[2];
    }

	function withdrawFees() external onlyOwner() {
		(bool sent, ) = payable(owner()).call{ value: address(this).balance }("");
		require(sent, "Error occured while transfer");
	}
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";

contract IERC4973RepFactory is Ownable {
	address public proxy;

	constructor(address _proxy) {}

	function createDrop(
		string memory _name,
		string memory _symbol,
		string memory version,
		string memory _uri,
		bytes32 _root,
		uint256 _mintLimit,
		uint256 initialTokenId,
		uint256 _addIncrement,
		uint256 _reduceIncrement
	) external payable returns (address) {}

	function withdrawFees() external onlyOwner() {}
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";

contract IERC4973AttestFactory is Ownable {
	address public proxy;

	constructor(address _proxy) {}

	function createDeploy(
		string memory _name,
		string memory _symbol,
		string memory version,
		string memory _uri,
		bytes32 _root,
		uint256 _mintLimit,
		uint256 initialTokenId
	) external payable returns (address) {}

	function withdrawFees() external onlyOwner() {}
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";

contract ISoulboundFactory is Ownable {
	address public proxy;

	constructor(address _proxy) {}

	function createDrop(
		string memory _name,
		string memory _symbol,
		string memory version,
		string memory _uri,
		bytes32 _root,
		uint256 _mintLimit,
		uint256 initialTokenId
	) external payable returns (address) {}

	function withdrawFees() external onlyOwner() {}
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