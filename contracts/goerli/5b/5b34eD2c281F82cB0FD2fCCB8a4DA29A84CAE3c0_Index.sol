// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.9;

import "Ownable.sol";

contract Index is Ownable {
    mapping(uint256 => string) public ContractsIndextoName;
    mapping(string => address) public ContractsMapping;
    mapping(address => string) public ContractsbyAddress;
    uint256 public addressCount;

    constructor() {
        addressCount = 0;
    }

    function getAddress(string memory name) external view returns (address) {
        return ContractsMapping[name];
    }

    function getName(address contractAddress)
        public
        view
        returns (string memory)
    {
        return ContractsbyAddress[contractAddress];
    }

    function getAllContracts() public view returns (string memory) {
        string memory result;

        for (uint256 i = 0; i < addressCount; i++) {
            if (i == 0) {
                result = string(abi.encodePacked(result, "{"));
            }
            result = string(
                abi.encodePacked(
                    result,
                    "'",
                    ContractsIndextoName[i],
                    "'",
                    ":",
                    "'",
                    "0x",
                    toAsciiString(ContractsMapping[ContractsIndextoName[i]]),
                    "'"
                )
            );
            if (i != addressCount - 1) {
                result = string(abi.encodePacked(result, ","));
            }
            if (i == addressCount - 1) {
                result = string(abi.encodePacked(result, "}"));
            }
        }
        return result;
    }

    function toAsciiString(address x) internal pure returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint256 i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint256(uint160(x)) / (2**(8 * (19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2 * i] = char(hi);
            s[2 * i + 1] = char(lo);
        }
        return string(s);
    }

    function char(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }

    function setAddress(string memory name, address contractAddress)
        public
        onlyOwner
    {
        _setAddress(name, contractAddress);
    }

    function _setAddress(string memory name, address contractAddress) internal {
        if (ContractsMapping[name] == address(0)) {
            ContractsIndextoName[addressCount] = name;
            ContractsbyAddress[contractAddress] = name;
            addressCount++;
        }
        ContractsMapping[name] = contractAddress;
        ContractsbyAddress[contractAddress] = name;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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