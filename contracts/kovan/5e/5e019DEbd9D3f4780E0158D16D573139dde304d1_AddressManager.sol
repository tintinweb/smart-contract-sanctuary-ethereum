// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

/// @title AddressManager
/// @notice Only the owner of this contract can edit the addresses held.
/// @dev This contract is used for addresses with reserve asset balances needed to be read by Chainlink nodes for the
/// proof of reserve system.
contract AddressManager is Ownable {
    event AddNetwork(string indexed network, uint256 indexed networksLength);
    event RemoveNetwork(string indexed network, uint256 indexed networksLength);

    event AddWalletAddress(
        string indexed network,
        string indexed addr,
        uint256 indexed addrsLength
    );
    event RemoveWalletAddress(
        string indexed network,
        string indexed addr,
        uint256 indexed addrsLength
    );

    string[] public networks;
    mapping(bytes32 => uint256) networksIndexMap;

    mapping(bytes32 => string[]) networkAddressesStringListMap;
    mapping(bytes32 => mapping(bytes32 => uint256)) networkAddressesIndexMap;

    /// @dev Adds an address to the list for the blockchain holding reserve collateral
    /// @param network The network the address holds reserves in
    /// @param addr Address that will be added to the list for the network
    function addWalletAddress(string memory network, string memory addr)
        external
        onlyOwner
    {
        bytes memory addrBytes = bytes(addr);
        bytes memory networkBytes = bytes(network);

        require(addrBytes.length > 0, "address can not be an empty string");
        require(
            networkBytes.length > 0,
            "network name can not be an empty string"
        );

        bytes32 addrHash = keccak256(addrBytes);
        bytes32 networkHash = keccak256(networkBytes);

        if (
            networksIndexMap[networkHash] == 0 &&
            (networks.length == 0 ||
                (networks.length > 0 &&
                    keccak256(bytes(networks[0])) != networkHash))
        ) {
            networks.push(network);
            networksIndexMap[networkHash] = networks.length - 1;

            emit AddNetwork(network, networks.length);
        }

        string[] storage addrs = networkAddressesStringListMap[networkHash];

        require(
            networkAddressesIndexMap[networkHash][addrHash] == 0 &&
                (addrs.length == 0 ||
                    (addrs.length > 0 &&
                        keccak256(bytes(addrs[0])) != addrHash)),
            "can not add a duplicate address"
        );

        addrs.push(addr);
        networkAddressesIndexMap[networkHash][addrHash] = addrs.length - 1;

        emit AddWalletAddress(network, addr, addrs.length);
    }

    /// @dev Removes an address from the list of those holding collateral in reserve
    /// @param network The network the address holds reserves in
    /// @param addr The address in the list for this network
    function removeWalletAddress(string memory network, string memory addr)
        external
        onlyOwner
    {
        uint256 index;

        bytes32 addrHash = keccak256(bytes(addr));
        bytes32 networkHash = keccak256(bytes(network));

        index = networkAddressesIndexMap[networkHash][addrHash];
        string[] storage addrs = networkAddressesStringListMap[networkHash];

        require(
            addrs.length > 0 &&
                (keccak256(bytes(addrs[0])) == addrHash || index != 0),
            "not a stored address for this network"
        );

        addrs[index] = addrs[addrs.length - 1];
        networkAddressesIndexMap[networkHash][
            keccak256(bytes(addrs[index]))
        ] = index;

        addrs.pop();
        delete networkAddressesIndexMap[networkHash][addrHash];

        if (addrs.length == 0) {
            index = networksIndexMap[networkHash];

            networks[index] = networks[networks.length - 1];
            networksIndexMap[keccak256(bytes(networks[index]))] = index;

            networks.pop();

            emit RemoveNetwork(network, networks.length);
        }

        emit RemoveWalletAddress(network, addr, addrs.length);
    }

    /// @dev Return strings representing all blockchains with addresses holding assets for reserve
    function allNetworks() external view returns (string[] memory) {
        return networks;
    }

    /// @dev Return the number of blockchains used for reserves
    function networksLength() external view returns (uint256) {
        return networks.length;
    }

    /// @dev Retrieve all the addresses holding reserve for a blockchain
    /// @param network The string representing a blockchain
    function walletAddresses(string calldata network)
        external
        view
        returns (string[] memory)
    {
        return networkAddressesStringListMap[keccak256(bytes(network))];
    }

    /// @dev Retrieve the number of addresses stored for a blockchain
    /// @param network The string representing a blockchain
    function walletAddressesLength(string calldata network)
        external
        view
        returns (uint256)
    {
        return networkAddressesStringListMap[keccak256(bytes(network))].length;
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