/**
 *Submitted for verification at Etherscan.io on 2023-02-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;


// 
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)
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

// 
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)
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

// 
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/Clones.sol)
/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create(0, 0x09, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create2(0, 0x09, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(add(ptr, 0x38), deployer)
            mstore(add(ptr, 0x24), 0x5af43d82803e903d91602b57fd5bf3ff)
            mstore(add(ptr, 0x14), implementation)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73)
            mstore(add(ptr, 0x58), salt)
            mstore(add(ptr, 0x78), keccak256(add(ptr, 0x0c), 0x37))
            predicted := keccak256(add(ptr, 0x43), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// 
//import "hardhat/console.sol";
contract Whitelist is Ownable {
    event Whitelisted(address indexed user, uint256 deployCredit);

    mapping(address => uint256) private _whitelist;

    bool private _whitelistEnabled = true;

    function enableWhitelist() external onlyOwner {
        _whitelistEnabled = true;
    }

    function disableWhitelist() external onlyOwner {
        _whitelistEnabled = false;
    }

    function isWhitelistEnabled() public view returns (bool) {
        return _whitelistEnabled;
    }

    function isWhitelisted(address account) public view returns (uint256) {
        return _whitelist[account];
    }

    function addWhitelist(
        address account,
        uint256 deployCredit
    ) public onlyOwner {
        _whitelist[account] += deployCredit;
        emit Whitelisted(account, _whitelist[account]);
    }

    function removeWhitelist(
        address account,
        uint256 deployCredit
    ) public onlyOwner {
        _whitelist[account] -= deployCredit > _whitelist[account]
            ? _whitelist[account]
            : deployCredit;
        emit Whitelisted(account, _whitelist[account]);
    }

    modifier onlyWhitelisted(uint256 credits) {
        if (_whitelistEnabled) {
            require(isWhitelisted(msg.sender) >= credits, "!whitelisted");
            _whitelist[msg.sender] -= credits;
        }
        _;
    }

    function addManyWhitelist(
        address[] memory accounts,
        uint256[] memory credits
    ) public onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            addWhitelist(accounts[i], credits[i]);
        }
    }

    function removeManyWhitelist(
        address[] memory accounts,
        uint256[] memory credits
    ) public onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            removeWhitelist(accounts[i], credits[i]);
        }
    }
}

// 
interface IStripto {
    function init(bytes memory _data) external;
}

// 
contract StriptoFactory is Ownable, Whitelist {
    address[] public implementations;

    address[] public striptos;

    uint256 public fee = 0.01 ether;

    receive() external payable {
        emit FeeReceived(msg.sender, msg.value);
    }

    function setFee(uint256 _fee) public onlyOwner {
        fee = _fee;
    }

    event ImplementationAdded(address indexed implementation, uint256 index);

    event StriptoCreated(address indexed stripto, uint256 index);

    event FeeReceived(address indexed sender, uint256 amount);

    function addImplementation(address _implementation) public onlyOwner {
        emit ImplementationAdded(_implementation, implementations.length);
        implementations.push(_implementation);
    }

    function implementationsLength() external view returns (uint256) {
        return implementations.length;
    }

    function striptosLength() external view returns (uint256) {
        return striptos.length;
    }

    function createStripto(
        uint256 _index,
        bytes calldata _data
    ) external payable onlyWhitelisted(1) returns (address stripto) {
        require(msg.value >= fee, "fee not paid");
        require(_index < implementations.length, "invalid index");

        bytes32 salt = keccak256(abi.encodePacked(_data, msg.sender));

        stripto = Clones.cloneDeterministic(implementations[_index], salt);

        IStripto(stripto).init(_data);

        striptos.push(stripto);

        emit StriptoCreated(stripto, striptos.length - 1);
    }

    function predictAddress(
        uint256 _index,
        bytes memory _data,
        address _deployer
    ) external view returns (address) {
        require(_index < implementations.length, "invalid index");

        bytes32 salt = keccak256(abi.encodePacked(_data, _deployer));

        return
            Clones.predictDeterministicAddress(implementations[_index], salt);
    }

    function collectFees() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}