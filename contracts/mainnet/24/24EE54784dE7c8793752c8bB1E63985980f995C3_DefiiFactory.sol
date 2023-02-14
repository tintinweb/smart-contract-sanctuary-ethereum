// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/Clones.sol)

pragma solidity ^0.8.0;

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
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
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
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
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
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/proxy/Clones.sol";

import "./interfaces/IDefiiFactory.sol";
import "./interfaces/IDefii.sol";

contract DefiiFactory is IDefiiFactory {
    address immutable _executor;
    address public immutable defiiImplementation;
    address[] public wallets;

    event DefiiCreated(address owner, address defii);

    constructor(address defiiImplementation_, address executor_) {
        defiiImplementation = defiiImplementation_;
        _executor = executor_;
    }

    function executor() external view returns (address) {
        return _executor;
    }

    function version() external view returns (uint16) {
        return IDefii(defiiImplementation).version();
    }

    function getDefiiFor(address wallet) public view returns (address defii) {
        defii = Clones.predictDeterministicAddress(
            defiiImplementation,
            keccak256(abi.encodePacked(wallet)),
            address(this)
        );
    }

    function getAllWallets() external view returns (address[] memory) {
        return wallets;
    }

    function getAllDefiis() public view returns (address[] memory) {
        address[] memory defiis = new address[](wallets.length);
        for (uint256 i = 0; i < defiis.length; i++) {
            defiis[i] = getDefiiFor(wallets[i]);
        }
        return defiis;
    }

    function getAllAllocations() external view returns (bool[] memory) {
        bool[] memory allocations = new bool[](wallets.length);
        for (uint256 i = 0; i < allocations.length; i++) {
            allocations[i] = IDefii(getDefiiFor(wallets[i])).hasAllocation();
        }
        return allocations;
    }

    function getAllInfos() external view returns (Info[] memory) {
        Info[] memory infos = new Info[](wallets.length);
        for (uint256 i = 0; i < infos.length; i++) {
            infos[i] = Info({
                wallet: wallets[i],
                defii: getDefiiFor(wallets[i]),
                hasAllocation: IDefii(getDefiiFor(wallets[i])).hasAllocation(),
                incentiveVault: IDefii(getDefiiFor(wallets[i])).incentiveVault()
            });
        }
        return infos;
    }

    function getAllBalances(address[] calldata tokens)
        external
        returns (Balance[] memory balances)
    {
        balances = new Balance[](wallets.length);
        for (uint256 i = 0; i < wallets.length; i++) {
            IDefii defii = IDefii(getDefiiFor(wallets[i]));

            balances[i] = Balance({
                wallet: wallets[i],
                balance: defii.getBalance(tokens)
            });
        }
    }

    function createDefii() external {
        createDefiiFor(msg.sender, msg.sender);
    }

    function createDefiiFor(address owner, address incentiveVault) public {
        address defii = Clones.cloneDeterministic(
            defiiImplementation,
            keccak256(abi.encodePacked(owner))
        );
        IDefii(defii).init(owner, address(this), incentiveVault);

        wallets.push(owner);
        emit DefiiCreated(owner, defii);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

import "./IDefiiFactory.sol";

interface IDefii {
    function hasAllocation() external view returns (bool);

    function incentiveVault() external view returns (address);

    function version() external pure returns (uint16);

    function init(
        address owner_,
        address factory_,
        address incentiveVault_
    ) external;

    function getBalance(address[] calldata tokens)
        external
        returns (BalanceItem[] memory balances);

    function changeIncentiveVault(address incentiveVault_) external;

    function enter() external;

    function runTx(
        address target,
        uint256 value,
        bytes memory data
    ) external;

    function runMultipleTx(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata datas
    ) external;

    function exit() external;

    function exitAndWithdraw() external;

    function harvest() external;

    function withdrawERC20(IERC20 token) external;

    function withdrawETH() external;

    function withdrawFunds() external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

struct Info {
    address wallet;
    address defii;
    bool hasAllocation;
    address incentiveVault;
}

struct Balance {
    address wallet;
    BalanceItem[] balance;
}

struct BalanceItem {
    address token;
    uint256 decimals;
    uint256 balance;
    uint256 incentiveVaultBalance;
}

interface IDefiiFactory {
    function executor() external view returns (address executor);

    function getDefiiFor(address wallet) external view returns (address defii);

    function getAllWallets() external view returns (address[] memory);

    function getAllDefiis() external view returns (address[] memory);

    function getAllAllocations() external view returns (bool[] memory);

    function getAllInfos() external view returns (Info[] memory);

    function getAllBalances(address[] calldata tokens)
        external
        returns (Balance[] memory);

    function createDefii() external;

    function createDefiiFor(address owner, address incentiveVault) external;
}