/**
 *Submitted for verification at Etherscan.io on 2022-04-19
*/

// Sources flattened with hardhat v2.8.4 https://hardhat.org

// File @openzeppelin/contracts/token/ERC20/[email protected]

// SPDX-License-Identifier: MIT AND GPL-3.0-or-later
// All OpenZeppelin Contracts Licensed under MIT
// All other contracts Licensed under GPL 3.0 or later
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}


// File @openzeppelin/contracts/utils/introspection/[email protected]

// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC1820Implementer.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface for an ERC1820 implementer, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1820#interface-implementation-erc1820implementerinterface[EIP].
 * Used by contracts that will be registered as implementers in the
 * {IERC1820Registry}.
 */
interface IERC1820Implementer {
    /**
     * @dev Returns a special value (`ERC1820_ACCEPT_MAGIC`) if this contract
     * implements `interfaceHash` for `account`.
     *
     * See {IERC1820Registry-setInterfaceImplementer}.
     */
    function canImplementInterfaceForAddress(bytes32 interfaceHash, address account) external view returns (bytes32);
}


// File @openzeppelin/contracts/utils/introspection/[email protected]

// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC1820Implementer.sol)

pragma solidity ^0.8.0;

/**
 * @dev Implementation of the {IERC1820Implementer} interface.
 *
 * Contracts may inherit from this and call {_registerInterfaceForAddress} to
 * declare their willingness to be implementers.
 * {IERC1820Registry-setInterfaceImplementer} should then be called for the
 * registration to be complete.
 */
contract ERC1820Implementer is IERC1820Implementer {
    bytes32 private constant _ERC1820_ACCEPT_MAGIC = keccak256("ERC1820_ACCEPT_MAGIC");

    mapping(bytes32 => mapping(address => bool)) private _supportedInterfaces;

    /**
     * @dev See {IERC1820Implementer-canImplementInterfaceForAddress}.
     */
    function canImplementInterfaceForAddress(bytes32 interfaceHash, address account)
        public
        view
        virtual
        override
        returns (bytes32)
    {
        return _supportedInterfaces[interfaceHash][account] ? _ERC1820_ACCEPT_MAGIC : bytes32(0x00);
    }

    /**
     * @dev Declares the contract as willing to be an implementer of
     * `interfaceHash` for `account`.
     *
     * See {IERC1820Registry-setInterfaceImplementer} and
     * {IERC1820Registry-interfaceHash}.
     */
    function _registerInterfaceForAddress(bytes32 interfaceHash, address account) internal virtual {
        _supportedInterfaces[interfaceHash][account] = true;
    }
}


// File @openzeppelin/contracts/utils/introspection/[email protected]

// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC1820Registry.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the global ERC1820 Registry, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1820[EIP]. Accounts may register
 * implementers for interfaces in this registry, as well as query support.
 *
 * Implementers may be shared by multiple accounts, and can also implement more
 * than a single interface for each account. Contracts can implement interfaces
 * for themselves, but externally-owned accounts (EOA) must delegate this to a
 * contract.
 *
 * {IERC165} interfaces can also be queried via the registry.
 *
 * For an in-depth explanation and source code analysis, see the EIP text.
 */
interface IERC1820Registry {
    /**
     * @dev Sets `newManager` as the manager for `account`. A manager of an
     * account is able to set interface implementers for it.
     *
     * By default, each account is its own manager. Passing a value of `0x0` in
     * `newManager` will reset the manager to this initial state.
     *
     * Emits a {ManagerChanged} event.
     *
     * Requirements:
     *
     * - the caller must be the current manager for `account`.
     */
    function setManager(address account, address newManager) external;

    /**
     * @dev Returns the manager for `account`.
     *
     * See {setManager}.
     */
    function getManager(address account) external view returns (address);

    /**
     * @dev Sets the `implementer` contract as ``account``'s implementer for
     * `interfaceHash`.
     *
     * `account` being the zero address is an alias for the caller's address.
     * The zero address can also be used in `implementer` to remove an old one.
     *
     * See {interfaceHash} to learn how these are created.
     *
     * Emits an {InterfaceImplementerSet} event.
     *
     * Requirements:
     *
     * - the caller must be the current manager for `account`.
     * - `interfaceHash` must not be an {IERC165} interface id (i.e. it must not
     * end in 28 zeroes).
     * - `implementer` must implement {IERC1820Implementer} and return true when
     * queried for support, unless `implementer` is the caller. See
     * {IERC1820Implementer-canImplementInterfaceForAddress}.
     */
    function setInterfaceImplementer(
        address account,
        bytes32 _interfaceHash,
        address implementer
    ) external;

    /**
     * @dev Returns the implementer of `interfaceHash` for `account`. If no such
     * implementer is registered, returns the zero address.
     *
     * If `interfaceHash` is an {IERC165} interface id (i.e. it ends with 28
     * zeroes), `account` will be queried for support of it.
     *
     * `account` being the zero address is an alias for the caller's address.
     */
    function getInterfaceImplementer(address account, bytes32 _interfaceHash) external view returns (address);

    /**
     * @dev Returns the interface hash for an `interfaceName`, as defined in the
     * corresponding
     * https://eips.ethereum.org/EIPS/eip-1820#interface-name[section of the EIP].
     */
    function interfaceHash(string calldata interfaceName) external pure returns (bytes32);

    /**
     * @notice Updates the cache with whether the contract implements an ERC165 interface or not.
     * @param account Address of the contract for which to update the cache.
     * @param interfaceId ERC165 interface for which to update the cache.
     */
    function updateERC165Cache(address account, bytes4 interfaceId) external;

    /**
     * @notice Checks whether a contract implements an ERC165 interface or not.
     * If the result is not cached a direct lookup on the contract address is performed.
     * If the result is not cached or the cached value is out-of-date, the cache MUST be updated manually by calling
     * {updateERC165Cache} with the contract address.
     * @param account Address of the contract to check.
     * @param interfaceId ERC165 interface to check.
     * @return True if `account` implements `interfaceId`, false otherwise.
     */
    function implementsERC165Interface(address account, bytes4 interfaceId) external view returns (bool);

    /**
     * @notice Checks whether a contract implements an ERC165 interface or not without using nor updating the cache.
     * @param account Address of the contract to check.
     * @param interfaceId ERC165 interface to check.
     * @return True if `account` implements `interfaceId`, false otherwise.
     */
    function implementsERC165InterfaceNoCache(address account, bytes4 interfaceId) external view returns (bool);

    event InterfaceImplementerSet(address indexed account, bytes32 indexed interfaceHash, address indexed implementer);

    event ManagerChanged(address indexed account, address indexed newManager);
}


// File contracts/ERC777Recipient.sol

/**
 *  Copyright (C) 2021-2022 TXA Pte. Ltd.
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 *  See the GNU General Public License for more details.
 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */
pragma solidity 0.8.13;


abstract contract ERC777Recipient is ERC1820Implementer {
    IERC1820Registry internal constant _ERC1820_REGISTRY =
        IERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);
    bytes32 private constant _TOKENS_SENDER_INTERFACE_HASH =
        0x29ddb589b1fb5fc7cf394961c1adf5f8c6454761adf795e67fe149f658abe895;
    bytes32 private constant _TOKENS_RECIPIENT_INTERFACE_HASH =
        0xb281fc8c12954d22544db45de3159a39272895b169a852b314f9cc762e44c53b;

    constructor() {
        _registerInterfaceForAddress(
            _TOKENS_RECIPIENT_INTERFACE_HASH,
            address(this)
        );
        _ERC1820_REGISTRY.setInterfaceImplementer(
            address(this),
            _TOKENS_RECIPIENT_INTERFACE_HASH,
            address(this)
        );
    }

    function tokensReceived(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external virtual {}
}


// File contracts/IAcceptsDeposit.sol

/**
 *  Copyright (C) 2022 TXA Pte. Ltd.
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 *  See the GNU General Public License for more details.
 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */
pragma solidity 0.8.13;

interface IAcceptsDeposit {
    function migrateDeposit(address depositor, uint256 amount)
        external
        returns (bool);

    function migrateVirtualBalance(address depositor, uint256 amount)
        external
        returns (bool);

    function getMigratorAddress() external view returns (address);
}


// File @openzeppelin/contracts/utils/structs/[email protected]

// OpenZeppelin Contracts v4.4.1 (utils/structs/BitMaps.sol)
pragma solidity ^0.8.0;

/**
 * @dev Library for managing uint256 to bool mapping in a compact and efficient way, providing the keys are sequential.
 * Largelly inspired by Uniswap's https://github.com/Uniswap/merkle-distributor/blob/master/contracts/MerkleDistributor.sol[merkle-distributor].
 */
library BitMaps {
    struct BitMap {
        mapping(uint256 => uint256) _data;
    }

    /**
     * @dev Returns whether the bit at `index` is set.
     */
    function get(BitMap storage bitmap, uint256 index) internal view returns (bool) {
        uint256 bucket = index >> 8;
        uint256 mask = 1 << (index & 0xff);
        return bitmap._data[bucket] & mask != 0;
    }

    /**
     * @dev Sets the bit at `index` to the boolean `value`.
     */
    function setTo(
        BitMap storage bitmap,
        uint256 index,
        bool value
    ) internal {
        if (value) {
            set(bitmap, index);
        } else {
            unset(bitmap, index);
        }
    }

    /**
     * @dev Sets the bit at `index`.
     */
    function set(BitMap storage bitmap, uint256 index) internal {
        uint256 bucket = index >> 8;
        uint256 mask = 1 << (index & 0xff);
        bitmap._data[bucket] |= mask;
    }

    /**
     * @dev Unsets the bit at `index`.
     */
    function unset(BitMap storage bitmap, uint256 index) internal {
        uint256 bucket = index >> 8;
        uint256 mask = 1 << (index & 0xff);
        bitmap._data[bucket] &= ~mask;
    }
}


// File @openzeppelin/contracts/utils/cryptography/[email protected]

// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merklee tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = _efficientHash(computedHash, proofElement);
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = _efficientHash(proofElement, computedHash);
            }
        }
        return computedHash;
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}


// File contracts/MerkleClaim.sol

/**
 *  Copyright (C) 2022 TXA Pte. Ltd.
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 *  See the GNU General Public License for more details.
 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */
pragma solidity 0.8.13;


abstract contract MerkleClaim {
    using BitMaps for BitMaps.BitMap;

    /**
     * Merkle root that proofs will be checked against.
     */
    bytes32 public merkleRoot;

    /*
     * Maps index of leaf to a boolean indicating whether or not it's
     * been claimed.
     */
    BitMaps.BitMap internal claimed;

    event MerkleRootSet(bytes32 virtualBalanceMerkleRoot);

    /**
     * Called by implementing contract to set the merkle root.
     *
     * Can only be called once.
     */
    function _setMerkleRoot(bytes32 _merkleRoot) internal {
        require(merkleRoot == bytes32(0), "ROOT_ALREADY_SET");
        require(_merkleRoot != bytes32(0), "ROOT_MUST_BE_NONZERO");
        merkleRoot = _merkleRoot;
        emit MerkleRootSet(_merkleRoot);
    }

    /**
     * Called by implementing contract to verify a merkle proof and process a claim.
     *
     * Prevents claiming with the same proof twice.
     */
    function _claim(
        uint256 index,
        address account,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) internal {
        require(!claimed.get(index), "ALREADY_CLAIMED");

        bytes32 leaf = keccak256(abi.encodePacked(index, account, amount));
        require(
            MerkleProof.verify(merkleProof, merkleRoot, leaf),
            "INVALID_PROOF"
        );

        claimed.set(index);
    }
}


// File contracts/PreStaking.sol

/**
 *  Copyright (C) 2022 TXA Pte. Ltd.
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 *  See the GNU General Public License for more details.
 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */
pragma solidity 0.8.13;




/**
 * Allows token holders to lock an ERC777 token for pre-staking.
 * Depositors send a specified token to this contract in order to stake.
 * After deposit period ends, manager sets a merkle root. Addresses can
 * then submit a merkle proof in order to claim a virtual balance.
 * Manager can set a migration address, after which depositors can
 * migrate both deposit balance and virtual balance to the new contract.
 * Migration contract is expected to implement the IAcceptsDeposit interface
 * and have the address of this contract set as the migrator.
 */
contract PreStaking is ERC777Recipient, MerkleClaim {
    /**
     * Address authorized to set migration address.
     */
    address public manager;

    /**
     * Interface to token approved for deposits.
     */
    IERC20 public immutable depositToken;

    /**
     * Address that will be called by depositors through this contract to migrate their deposited tokens.
     */
    IAcceptsDeposit public migrationContract;

    /**
     * Timestamp for date after which deposits no longer accepted
     */
    uint256 public immutable depositEndTime;

    /**
     * Timestamp for date after which prestaked tokens can be withdrawn
     */
    uint256 public immutable withdrawUnlockTime;

    /**
     * Minimum amount of token that must be deposited
     */
    uint256 public immutable minimumDeposit;

    /**
     * Maps depositor address to amount of depositToken staked
     */
    mapping(address => uint256) public depositorBalance;

    /**
     * Maps depositor address to amount of virtual balance claimed
     */
    mapping(address => uint256) public virtualBalance;

    event MigrationContractSet(address migrationContract);
    event MigratedDeposit(address depositor, uint256 amount);
    event MigratedVirtualBalance(address depositor, uint256 amount);

    /**
     * Sets up parameters for prestaking

     * @param _manager Address that will be authorized to set migration address

     * @param _depositToken Address of token accepted as deposit

     * @param _timeUntilDepositsEnd Number of seconds after time of deployment until deposits no longer accepted

     * @param _timeUntilWithdraw Number of seconds after time of deployment until deposited tokens can be withdrawn

     * @param _minimumDeposit Minimum amount of tokens that depositor must stake to qualify
     */
    constructor(
        address _manager,
        address _depositToken,
        uint256 _timeUntilDepositsEnd,
        uint256 _timeUntilWithdraw,
        uint256 _minimumDeposit
    ) {
        require(_manager != address(0), "ZERO_ADDRESS_MANAGER");
        require(_depositToken != address(0), "ZERO_ADDRESS_DEPOSIT_TOKEN");
        manager = _manager;
        depositToken = IERC20(_depositToken);
        depositEndTime = block.timestamp + _timeUntilDepositsEnd;
        withdrawUnlockTime = block.timestamp + _timeUntilWithdraw;
        minimumDeposit = _minimumDeposit;
    }

    /**
     * Called by the ERC777 contract when tokens are sent to this contract.
     * Depositors call the token contract to send tokens here to stake.
     *
     * Records number of tokens sent by a depositor.
     * Rejects any ERC777 token other than the deposit token.
     * Rejects deposits after the deposit period ends.
     * Rejects deposits below a minimum amount.
     */
    function tokensReceived(
        address,
        address from,
        address,
        uint256 amount,
        bytes calldata,
        bytes calldata
    ) external override {
        require(msg.sender == address(depositToken), "INVALID_TOKEN");
        require(block.timestamp < depositEndTime, "DEPOSIT_TIMEOUT");
        depositorBalance[from] += amount;
        require(depositorBalance[from] >= minimumDeposit, "BELOW_MINIMUM");
    }

    /**
     * Called by the manager to set the migration contract.
     *
     * Can only be set once.
     * Checks that migration contract has set this contract as the migrator.
     * Approves the migration contract as the spender of this contract's tokens.
     */
    function setMigrationContract(address _migrationContract)
        external
        onlyManager
    {
        require(
            address(migrationContract) == address(0),
            "MIGRATION_ALREADY_SET"
        );
        migrationContract = IAcceptsDeposit(_migrationContract);
        require(
            migrationContract.getMigratorAddress() == address(this),
            "INVALID_MIGRATION_CONTRACT"
        );
        require(
            depositToken.approve(_migrationContract, type(uint256).max),
            "APPROVE_FAILED"
        );
        emit MigrationContractSet(_migrationContract);
    }

    /**
     * Called by manager to set merkle root of the tree where
     * each leaf is a virtual balance.
     */
    function setMerkleRoot(bytes32 _virtualBalanceMerkleRoot)
        external
        onlyManager
    {
        _setMerkleRoot(_virtualBalanceMerkleRoot);
    }

    /**
     * Called by an address with a leaf in the merkle tree
     * to claim a virtual balance.
     *
     * See MerkleClaim._claim
     */
    function claimVirtualBalance(
        uint256 index,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) external {
        _claim(index, msg.sender, amount, merkleProof);
        virtualBalance[msg.sender] += amount;
    }

    /**
     * Called by a depositor to migrate tokens from this contract to
     * migration contract.
     */
    function migrateDeposit(uint256 amount) external {
        require(address(migrationContract) != address(0), "MIGRATION_NOT_SET");
        require(depositorBalance[msg.sender] >= amount, "INSUFFICIENT_FUNDS");
        depositorBalance[msg.sender] -= amount;
        require(
            migrationContract.migrateDeposit(msg.sender, amount),
            "MIGRATE_DEPOSIT_FAILED"
        );
        emit MigratedDeposit(msg.sender, amount);
    }

    /**
     * Called by a depositor to migrate a virtual balance from this contract
     * to migration contract.
     */
    function migrateVirtualBalance(uint256 amount) external {
        require(address(migrationContract) != address(0), "MIGRATION_NOT_SET");
        require(virtualBalance[msg.sender] >= amount, "INSUFFICIENT_BALANCE");
        virtualBalance[msg.sender] -= amount;
        require(
            migrationContract.migrateVirtualBalance(msg.sender, amount),
            "MIGRATE_BALANCE_FAILED"
        );
        emit MigratedVirtualBalance(msg.sender, amount);
    }

    /**
     * Called by depositor to withdraw staked tokens.
     *
     * Forbids withdrawing before unlock time has passed.
     * Prevents this contract from holding depositor's tokens
     * forever in the case that a migration contract is not added, or
     * if depositors choose not to migrate.
     */
    function withdraw(uint256 amount) external {
        require(block.timestamp >= withdrawUnlockTime, "WITHDRAW_LOCKED");
        require(depositorBalance[msg.sender] >= amount, "INSUFFICIENT_FUNDS");
        depositorBalance[msg.sender] -= amount;
        require(depositToken.transfer(msg.sender, amount), "TRANSFER_FAILED");
    }

    /**
     * Restricts calling a function to the address set as manager.
     */
    modifier onlyManager() {
        require(manager == msg.sender, "SENDER_NOT_MANAGER");
        _;
    }
}