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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title
 * @author
 * @notice
 *
 * https://community.optimism.io/docs/useful-tools/networks/#optimism-mainnet
 * https://github.com/ethereum-optimism/optimism/tree/develop/packages/contracts/deployments/mainnet#layer-1-contracts
 * görli (bedrock): https://github.com/ethereum-optimism/optimism/tree/develop/packages/contracts-bedrock/deployments/goerli
 * on mainnet we could also query common contracts by their name from here: https://etherscan.io/address/0xdE1FCfB0851916CA5101820A69b13a4E276bd81F#code
 */
contract ContractRegistry is Ownable {
    mapping(bytes32 => address) registry;

    constructor() Ownable() { }

    function register(bytes32 name, address _contract) public onlyOwner {
        registry[name] = _contract;
    }

    // function register(string memory name, address _contract) public onlyOwner {
    //     register(bytes32(bytes(name)), _contract);
    // }

    function register(address addr, address _counterPart) public onlyOwner {
        bytes32 key = bytes32(bytes20(addr));
        register(key, _counterPart);
    }

    function get(address addr) public view returns (address) {
        return registry[bytes32(bytes20(addr))];
    }

    function get(bytes32 name) public view returns (address) {
        return registry[name];
    }

    // function get(string memory name) public view returns (address) {
    //     return get(bytes32(bytes(name)));
    // }

    function safeGet(bytes32 name) public view returns (address) {
        address _address = get(name);
        if (_address == address(0)) {
            revert("unresolvable");
        }
        return _address;
    }

    function safeGet(address addr) public view returns (address) {
        return safeGet(bytes32(bytes20(addr)));
    }

    // function safeGet(string memory name) public view returns (address) {
    //     return safeGet(bytes32(bytes(name)));
    // }
}

contract ContractRegistryMainnet is ContractRegistry {
    constructor() ContractRegistry() {
        //https://community.optimism.io/docs/useful-tools/networks/#optimism-mainnet
        registry["CrossdomainMessenger"] = 0x25ace71c97B33Cc4729CF772ae268934F7ab5fA1;
        //https://github.com/ethereum-optimism/optimism/blob/develop/packages/contracts/deployments/mainnet/Proxy__OVM_L1StandardBridge.json
        //seems to be good (eof Feb 23): https://etherscan.io/txs?a=0x99C9fc46f92E8a1c0deC1b1747d010903E884bE1
        //todo WARNING: this imo is *not* bedrock compatible
        registry["StandardBridge"] = 0x99C9fc46f92E8a1c0deC1b1747d010903E884bE1;

        //USDC todo: likely to work
        //https://etherscan.io/tx/0x3294b2578762bd3f32d17897ab79b02d4ec77dc3438c0692517bc3cb934adab7
        registry[bytes32(bytes20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48))] = 0x7F5c764cBc14f9669B88837ca1490cCa17c31607;
        //DAI todo: careful!!! dai seems not compatible to the standard token bridge,
        // if (tokenAddressL1 == 0x6B175474E89094C44Da98b954EedeAC495271d0F) {
        //     return 0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1; //DAI on Optimism
        // }
    }
}

contract ContractRegistryGoerli is ContractRegistry {
    constructor() ContractRegistry() {
        //https://community.optimism.io/docs/useful-tools/networks/#optimism-goerli
        registry["CrossdomainMessenger"] = 0x5086d1eEF304eb5284A0f6720f79403b4e9bE294;

        // here it's explicitly mentioned that the Porxy__OVM contracts are out of date:
        // https://github.com/ethereum-optimism/optimism/tree/develop/packages/contracts/deployments/goerli#network-info
        // instead, the newer bedrock stack is used: https://github.com/ethereum-optimism/optimism/tree/develop/packages/contracts-bedrock
        // -> https://github.com/ethereum-optimism/optimism/blob/develop/packages/contracts-bedrock/deployments/goerli/L1StandardBridge.json at 0x2Fd98C3581b658643C18CCea9b9181ba3a7F7c54
        //but proxied by L1ChugSplashProxy:
        //https://goerli.etherscan.io/address/0x636af16bf2f682dd3109e60102b8e1a089fedaa8#code
        registry["StandardBridge"] = 0x636Af16bf2f682dD3109e60102b8E1A089FedAa8;

        //OUTb on Görli
        //https://goerli-optimism.etherscan.io/token/0x3e7ef8f50246f725885102e8238cbba33f276747
        //https://github.com/ethereum-optimism/optimism-tutorial/tree/main/cross-dom-bridge-erc20
        //https://community.optimism.io/docs/guides/testing/#
        registry[bytes32(bytes20(0x32B3b2281717dA83463414af4E8CfB1970E56287))] = 0x3e7eF8f50246f725885102E8238CBba33F276747;
    }
}

// function getStandardBridgeAddress() public view returns (address) {
//     // Mainnet
//     //https://github.com/ethereum-optimism/optimism/blob/develop/packages/contracts/deployments/mainnet/Proxy__OVM_L1StandardBridge.json
//     //seems to be good (eof Feb 23): https://etherscan.io/txs?a=0x99C9fc46f92E8a1c0deC1b1747d010903E884bE1
//     //todo WARNING: this imo is *not* bedrock compatible
//     if (block.chainid == 1) {
//         return 0x99C9fc46f92E8a1c0deC1b1747d010903E884bE1;
//     }

//     // Goerli
//     // here it's explicitly mentioned that the Porxy__OVM contracts are out of date:
//     // https://github.com/ethereum-optimism/optimism/tree/develop/packages/contracts/deployments/goerli#network-info
//     // instead, the newer bedrock stack is used: https://github.com/ethereum-optimism/optimism/tree/develop/packages/contracts-bedrock
//     // -> https://github.com/ethereum-optimism/optimism/blob/develop/packages/contracts-bedrock/deployments/goerli/L1StandardBridge.json at 0x2Fd98C3581b658643C18CCea9b9181ba3a7F7c54
//     //but proxied by L1ChugSplashProxy:
//     //https://goerli.etherscan.io/address/0x636af16bf2f682dd3109e60102b8e1a089fedaa8#code

//     if (block.chainid == 5) {
//         return 0x636Af16bf2f682dD3109e60102b8E1A089FedAa8;
//     }

//     revert("bridge invalid");
// }

// //todo: only works for görli:
// function getCrossdomainMessengerAddress() public view returns (address) {
//     if (block.chainid == 1) {
//         return 0x25ace71c97B33Cc4729CF772ae268934F7ab5fA1;
//     }
//     if (block.chainid == 5) {
//         return 0x5086d1eEF304eb5284A0f6720f79403b4e9bE294;
//     }

//     revert("no cross domain messenger");
// }

// function getTokenAddressL2(address tokenAddressL1) public view returns (address) {
//     if (block.chainid == 1) {
//         //USDC todo: likely to work
//         //https://etherscan.io/tx/0x3294b2578762bd3f32d17897ab79b02d4ec77dc3438c0692517bc3cb934adab7
//         if (tokenAddressL1 == 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48) {
//             return 0x7F5c764cBc14f9669B88837ca1490cCa17c31607; //USDC on Optimism
//         }
//         //DAI todo: careful!!! dai seems not compatible to the standard token bridge,
//         // if (tokenAddressL1 == 0x6B175474E89094C44Da98b954EedeAC495271d0F) {
//         //     return 0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1; //DAI on Optimism
//         // }
//     } else if (block.chainid == 5) {
//         //https://community.optimism.io/docs/guides/testing/#
//         //https://github.com/ethereum-optimism/optimism-tutorial/tree/main/cross-dom-bridge-erc20
//         //OUTb
//         if (tokenAddressL1 == 0x32B3b2281717dA83463414af4E8CfB1970E56287) {
//             //OUTb on Görli
//             //https://goerli-optimism.etherscan.io/token/0x3e7ef8f50246f725885102e8238cbba33f276747
//             return 0x3e7eF8f50246f725885102E8238CBba33F276747; //OUTb on Optimism
//         }

//     } else if (block.chainid == 31337) { }

//     revert("no token known on l2");
// }