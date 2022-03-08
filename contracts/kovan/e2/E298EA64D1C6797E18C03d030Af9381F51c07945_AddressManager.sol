// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

/// @title AddressManager
/// @notice Only the owner of this contract can edit the addresses held.
/// @dev This contract is used for addresses holding reserve assets needed to be read by Chainlink nodes for the proof
/// of reserve system.
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

    mapping(bytes32 => uint256) private networkIndexMap;
    mapping(bytes32 => string[]) private walletAddressesMap;

    /// @dev Adds an address to the list of those holding collateral in reserve
    /// @param network The network the address holds reserves in
    /// @param addr Address that will be added to the list for the network
    function addWalletAddress(string memory network, string memory addr)
        external
        onlyOwner
    {
        require(bytes(addr).length > 0, "address can not be an empty string");

        bytes32 key = keccak256(bytes(network));
        string[] storage addrs = walletAddressesMap[key];

        if (addrs.length == 0) {
            networks.push(network);
            networkIndexMap[key] = networks.length - 1;

            emit AddNetwork(network, networks.length);
        }

        walletAddressesMap[key].push(addr);

        emit AddWalletAddress(network, addr, walletAddressesMap[key].length);
    }

    /// @dev Removes an address from the list of those holding collateral in reserve
    /// @param network The network the address holds reserves in
    /// @param index Position of the address in the list
    function removeWalletAddress(string memory network, uint256 index)
        external
        onlyOwner
    {
        bytes32 key = keccak256(bytes(network));
        string[] storage addrs = walletAddressesMap[key];

        uint256 length = addrs.length;
        require(index < length, "invalid address item");

        uint256 lastIndex = length - 1;
        string memory addr = addrs[lastIndex];

        addrs[index] = addr;

        addrs.pop();

        // if the removed address was the last one for the given network, remove the entry from the networks list
        if (addrs.length == 0) {
            uint256 networksIndex = networkIndexMap[key];
            uint256 lastNetworksIndex = networks.length - 1;

            networks[networksIndex] = networks[lastNetworksIndex]; // overwrite the item being removed with the last item
            bytes memory lastNetworkBytes = bytes(networks[lastNetworksIndex]);

            // move the index of the item being removed to the entry for old the last item
            networkIndexMap[keccak256(lastNetworkBytes)] = networksIndex;

            networks.pop();
            delete networkIndexMap[key];

            emit RemoveNetwork(network, networks.length);
        }

        emit RemoveWalletAddress(network, addr, walletAddressesMap[key].length);
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
    /// @param network The enum representing a specific network
    function walletAddresses(string calldata network)
        external
        view
        returns (string[] memory)
    {
        return walletAddressesMap[keccak256(bytes(network))];
    }

    /// @dev Retrieve the number of addresses stored for a blockchain
    /// @param network The string representing a network
    function walletAddressesLength(string calldata network)
        external
        view
        returns (uint256)
    {
        return walletAddressesMap[keccak256(bytes(network))].length;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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