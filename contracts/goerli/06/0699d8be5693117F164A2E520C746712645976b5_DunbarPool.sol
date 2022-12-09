// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "solmate/src/utils/SafeTransferLib.sol";
import "./utils/SignatureLib.sol";

import {WalletFactory} from "../wallet/WalletFactory.sol";
import {WalletTypes} from "../wallet/types/WalletTypes.sol";

interface DunbarPoolTypes {
    struct PoolType {
        address target;
        uint256 value;
        bytes data;
        uint256[] dataOverwrites;
        address poolOwner;
        address[] drivers;
        address[] members;
        uint256 memberThreshold;
        uint256 nonce;
    }

    struct RelayFee {
        bytes32 poolId;
        uint256 amount;
        bytes signature;
    }
}

interface IDunbar is DunbarPoolTypes {
    event Deposit(address indexed from, bytes32 indexed poolId, uint256 amount);
    event Withdrawal(address indexed to, bytes32 indexed poolId, uint256 amount);
    event PoolExecuted(bytes32 poolId, address wallet);
    event Contribution(bytes32 indexed poolId, address indexed account, uint256 amount);

    error NONCE_USED();
    error INVALID_SIGNATURE();
    error POOL_VALUE_NOT_MET();
}

contract DunbarPool is IDunbar, WalletTypes {
    using SafeTransferLib for address;

    bytes32 public constant CONTRIBUTION_TYPEHASH = keccak256(
        "Contribution(address target,uint256 value,bytes data,uint256[] dataOverwrites,address poolOwner,uint256 nonce)"
    );

    bytes32 public constant POOL_TYPEHASH = keccak256(
        "Pool(address target,uint256 value,bytes data,uint256[] dataOverwrites,address poolOwner,address[] drivers,address[] members,uint256 memberThreshold,uint256 nonce)"
    );

    uint256 internal immutable INITIAL_CHAIN_ID;
    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    WalletFactory public immutable WALLET_FACTORY;

    constructor(WalletFactory _walletFactory) {
        WALLET_FACTORY = _walletFactory;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    ///                                                          ///
    ///                                                          ///
    ///                                                          ///

    // User => Pool ID => Deposit amount
    mapping(address => mapping(bytes32 => uint256)) internal balanceOf;

    // TODO change back to user => nonce => bool
    mapping(uint256 => bool) public usedNonces;

    ///                                                          ///
    ///                                                          ///
    ///                                                          ///

    function deposit(bytes32 poolId) external payable {
        balanceOf[msg.sender][poolId] += msg.value;

        emit Deposit(msg.sender, poolId, msg.value);
    }

    function withdraw(bytes32 poolId, uint256 amount) public {
        balanceOf[msg.sender][poolId] -= amount;

        emit Withdrawal(msg.sender, poolId, amount);

        msg.sender.safeTransferETH(amount);
    }

    ///                                                          ///
    ///                                                          ///
    ///                                                          ///

    function getPoolId(
        address target,
        uint256 value,
        bytes calldata data,
        uint256[] calldata dataOverwrites,
        address poolOwner,
        uint256 nonce
    ) public view returns (bytes32) {
        return keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR(),
                keccak256(
                    abi.encode(
                        CONTRIBUTION_TYPEHASH,
                        target,
                        value,
                        keccak256(data),
                        keccak256(abi.encodePacked(dataOverwrites)),
                        poolOwner,
                        nonce
                    )
                )
            )
        );
    }

    function buildPoolExecuteHash(PoolType calldata pool) public view returns (bytes32) {
        return keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR(),
                keccak256(
                    abi.encode(
                        POOL_TYPEHASH,
                        pool.target,
                        pool.value,
                        keccak256(pool.data),
                        keccak256(abi.encodePacked(pool.dataOverwrites)),
                        pool.poolOwner,
                        keccak256(abi.encodePacked(pool.drivers)),
                        keccak256(abi.encodePacked(pool.members)),
                        pool.memberThreshold,
                        pool.nonce
                    )
                )
            )
        );
    }

    ///                                                          ///
    ///                                                          ///
    ///                                                          ///

    function executePool(PoolType calldata pool, Signature calldata sig, RelayFee calldata relayFee)
        external
        payable
        returns (address wallet)
    {
        // Ensure the nonce has not been previously used.
        if (usedNonces[pool.nonce]) revert NONCE_USED();

        bytes32 digest = buildPoolExecuteHash(pool);

        // If the call is relayed:
        if (msg.sender != pool.poolOwner) {
            // Recover the signer of the digest.
            address recoveredAddress = ecrecover(digest, sig.v, sig.r, sig.s);

            // Ensure the recovered signer is the pool owner.
            if (recoveredAddress == address(0) || recoveredAddress != pool.poolOwner) revert INVALID_SIGNATURE();

            // TODO HANDLE RELAY FEE
        }

        // Mark the nonce as used.
        usedNonces[pool.nonce] = true;

        // Get the pool id that deposits were made to.
        bytes32 poolId = getPoolId(pool.target, pool.value, pool.data, pool.dataOverwrites, pool.poolOwner, pool.nonce);

        uint256 poolDeposit = getDeposits(poolId, pool.members);

        wallet = WALLET_FACTORY.createWallet{value: poolDeposit}(pool.drivers, pool.members, pool.memberThreshold);

        // if (pool.target == address(0)) {
        //     wallet = WALLET_FACTORY.createWallet{value: poolDeposit}(pool.drivers, pool.members, pool.memberThreshold);
        // } else {
        //     wallet = WALLET_FACTORY.createWallet{value: poolDeposit}(
        //         pool.drivers,
        //         pool.members,
        //         pool.memberThreshold,
        //         pool.target,
        //         pool.value,
        //         pool.data,
        //         pool.dataOverwrites
        //     );
        // }

        emit PoolExecuted(poolId, wallet);
    }

    function getDeposits(bytes32 poolId, address[] calldata members) internal returns (uint256 totalPoolDeposit) {
        uint256 numMembers = members.length;

        address currentUser;
        uint256 currentUserDeposit;

        unchecked {
            for (uint256 i; i < numMembers; ++i) {
                currentUser = members[i];

                currentUserDeposit = balanceOf[currentUser][poolId];

                emit Contribution(poolId, currentUser, currentUserDeposit);

                delete balanceOf[currentUser][poolId];

                totalPoolDeposit += currentUserDeposit;
            }
        }
    }

    ///                                                          ///
    ///                                                          ///
    ///                                                          ///

    function DOMAIN_SEPARATOR() public view returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() private view returns (bytes32) {
        return keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256("DunbarPool"),
                keccak256("1"),
                block.chainid,
                address(this)
            )
        );
    }

    function validatePoolOwnerSignature(bytes32 digest, Signature calldata sig, address poolOwner) internal pure {
        // Recover the signer of the digest.
        address recoveredAddress = ecrecover(digest, sig.v, sig.r, sig.s);

        // Ensure a valid address is recovered and that the signer is a driver.
        if (recoveredAddress == address(0) || recoveredAddress != poolOwner) revert INVALID_SIGNATURE();
    }

    // TODO function validateRelayFeeSignature(bytes32 digest, Signature calldata sig, )

    // TODO function cancelNonce(uint256 nonce) external {
    //     usedNonces[msg.sender][nonce] = true;
    // }

    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

library SignatureLib {
    function validateSignature(bytes32 hash, bytes memory signature) public pure returns (address) {
        (uint8 v, bytes32 r, bytes32 s) = splitSignature(signature);
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0x0), "INVALID_SIGNATURE");

        return signer;
    }

    function splitSignature(bytes memory signature) private pure returns (uint8 v, bytes32 r, bytes32 s) {
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import { WalletTypes } from "../types/WalletTypes.sol";

interface IWallet is WalletTypes {
    ///                                                          ///
    ///                            EVENTS                        ///
    ///                                                          ///

    event WalletExecuted(Transaction[] txs, Signature[] sigs, uint256 nonce);

    event WalletReceived(address sender, uint256 amount, uint256 walletBalance);

    event MemberThresholdUpdated(uint256 prevThreshold, uint256 newThreshold);

    event MembersAdded(Member[] newMembers, uint256 nonce);

    ///                                                          ///
    ///                            ERRORS                        ///
    ///                                                          ///

    error ALREADY_INITIALIZED();

    error INVALID_MEMBER_THRESHOLD();

    error DRIVER_MUST_BE_MEMBER();

    error ONLY_DRIVER();

    error ONLY_MEMBER();

    error TX_FAILED();

    error NONCE_USED();

    error EXPIRED_SIGNATURE();

    error INVALID_SIGNATURE();

    error DUPLICATE_SIGNATURE();

    error THRESHOLD_NOT_MET();

    error NEW_MEMBER_SIGS_MISMATCH();

    ///                                                          ///
    ///                          FUNCTIONS                       ///
    ///                                                          ///
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import { WalletTypes } from "../types/WalletTypes.sol";

interface IWalletFactory is WalletTypes {
    event WalletCreated(address indexed walletAddress, address[] drivers, address[] members, uint256 memberThreshold);

    function createWallet(address[] calldata drivers, address[] calldata members, uint256 memberThreshold)
        external
        payable
        returns (address);

    // function createWallet(
    //     address[] calldata drivers,
    //     address[] calldata members,
    //     uint256 memberThreshold,
    //     TransactionWithOverwrites memory initTx
    // ) external payable returns (address);

    function computeWalletAddress(address[] calldata members) external view returns (address);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

interface WalletTypes {
    struct TransactionWithOverwrites {
        address target;
        uint256 value;
        bytes data;
        uint256[] dataOverwrites;
    }

    struct Transaction {
        address target;
        uint256 value;
        bytes data;
    }

    struct Signature {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    struct Member {
        address account;
        bool driver;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import { IWallet } from "./interfaces/IWallet.sol";
import { SignatureLib } from "../pool/utils/SignatureLib.sol";

contract Wallet is IWallet {
    ///                                                          ///
    ///                          CONSTANTS                       ///
    ///                                                          ///

    bytes32 public constant TRANSACTION_TYPEHASH = keccak256("Transaction(address target,uint256 value,bytes data)");

    bytes32 public constant EXECUTION_TYPEHASH = keccak256(
        "Execute(Transaction[] txs,uint256 nonce,uint256 deadline)Transaction(address target,uint256 value,bytes data)"
    );

    bytes32 public constant NEW_MEMBERS_TYPEHASH =
        keccak256("NewMembers(Member[] newMembers,uint256 nonce)Member(address account,bool driver)");

    bytes32 public constant MEMBER_TYPEHASH = keccak256("Member(address account,bool driver)");

    ///                                                          ///
    ///                          IMMUTABLES                      ///
    ///                                                          ///

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    ///                                                          ///
    ///                           STORAGE                        ///
    ///                                                          ///

    /// @notice The number of drivers.
    uint64 public numDrivers;

    /// @notice The number of members.
    uint64 public numMembers;

    /// @notice The member threshold.
    uint64 public threshold;

    /// @notice If a nonce has been used.
    /// @dev Nonce => Used?
    mapping(uint256 => bool) public usedNonces;

    /// @notice If a user is a driver.
    /// @dev User => Driver?
    mapping(address => bool) public isDriver;

    /// @notice If a user is a member.
    /// @dev User => Member?
    mapping(address => bool) public isMember;

    /// @notice If a member has approved a message.
    /// @dev Digest => Member => Approved?
    mapping(bytes32 => mapping(address => bool)) internal hasMemberApproved;

    ///                                                          ///
    ///                          CONSTRUCTOR                     ///
    ///                                                          ///

    constructor() payable {
        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    ///                                                          ///
    ///                          INITIALIZER                     ///
    ///                                                          ///

    /// @notice Set up the group wallet
    function initialize(
        address[] calldata drivers,
        address[] calldata members,
        uint256 memberThreshold,
        address initTxTarget,
        uint256 initTxValue,
        bytes calldata initTxCalldata
    ) external payable {
        if (threshold != 0) revert ALREADY_INITIALIZED();
        if (memberThreshold <= 1) revert INVALID_MEMBER_THRESHOLD();

        uint256 numInitialDrivers = drivers.length;
        uint256 numInitialMembers = members.length;

        numDrivers = uint64(numInitialDrivers);
        numMembers = uint64(numInitialMembers);
        threshold = uint64(memberThreshold);

        unchecked {
            for (uint256 i; i < numInitialMembers; ++i) {
                isMember[members[i]] = true;
            }

            for (uint256 i; i < numInitialDrivers; ++i) {
                if (!isMember[drivers[i]]) revert DRIVER_MUST_BE_MEMBER();

                isDriver[drivers[i]] = true;
            }
        }

        if (initTxTarget != address(0)) {
            (bool success,) = initTxTarget.call{value: initTxValue}(initTxCalldata);

            if (!success) revert TX_FAILED();
        }
    }

    ///                                                          ///
    ///                     TRANSACTION EXECUTION                ///
    ///                                                          ///

    function execute(Transaction[] calldata txs, Signature[] calldata sigs, uint256 nonce, uint256 deadline)
        external
        payable
    {
        // Ensure the nonce has not been previously used.
        if (usedNonces[nonce]) revert NONCE_USED();

        // Cache the number of given signatures.
        uint256 numSigs = sigs.length;

        // If no signatures are provided:
        if (numSigs == 0) {
            // Ensure the caller is a driver.
            if (!isDriver[msg.sender]) revert ONLY_DRIVER();

            // Otherwise validate the given signature(s):
        } else {
            // Ensure the deadline has not been reached.
            if (block.timestamp > deadline) revert EXPIRED_SIGNATURE();

            // Compute the execution digest.
            bytes32 digest = hashExecution(txs, nonce, deadline);

            // If only one signature is provided:
            if (numSigs == 1) {
                // Ensure the signer is a driver.
                validateDriverSignature(digest, sigs[0]);

                // Otherwise validate the multiple signatures:
            } else {
                // Ensure the signers are members.
                validateMemberSignatures(digest, numSigs, sigs);
            }
        }

        // Mark the nonce as used.
        usedNonces[nonce] = true;

        // Execute the given transactions.
        executeTransactions(txs);

        emit WalletExecuted(txs, sigs, nonce);
    }

    function executeTransactions(Transaction[] calldata txs) internal {
        // Cache the number of transactions to execute.
        uint256 numTxs = txs.length;

        unchecked {
            // For each transaction:
            for (uint256 i; i < numTxs; ++i) {
                // Perform the given call.
                (bool success,) = txs[i].target.call{value: txs[i].value}(txs[i].data);

                // Ensure the transaction succeeded.
                if (!success) revert TX_FAILED();
            }
        }
    }

    ///                                                          ///
    ///                                                          ///
    ///                                                          ///

    function addMembers(Member[] calldata newMembers, Signature[] calldata sigs, uint256 nonce) external {
        if (usedNonces[nonce]) revert NONCE_USED();

        usedNonces[nonce] = true;

        uint256 numNewMembers = newMembers.length;
        uint256 numSigs = sigs.length;

        if (numNewMembers != numSigs) revert NEW_MEMBER_SIGS_MISMATCH();

        bytes32 digest = getNewMembersHash(newMembers, nonce);

        // If only one signature is provided:
        if (numSigs == 1) {
            // Ensure the signer is a driver.
            validateDriverSignature(digest, sigs[0]);

            // Otherwise validate the multiple signatures:
        } else {
            // Ensure the signers are members.
            validateMemberSignatures(digest, numSigs, sigs);
        }

        unchecked {
            for (uint256 i; i < numNewMembers; ++i) {
                isMember[newMembers[i].account] = true;

                ++numMembers;

                if (newMembers[i].driver) {
                    isDriver[newMembers[i].account] = true;

                    ++numDrivers;
                }
            }
        }

        emit MembersAdded(newMembers, nonce);
    }

    ///                                                          ///
    ///                          EIP-712 UTILS                   ///
    ///                                                          ///

    function cancelNonce(uint256 nonce) external {
        if (!isMember[msg.sender]) revert ONLY_MEMBER();

        usedNonces[nonce] = true;
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256("Wallet"),
                keccak256("1"),
                block.chainid,
                address(this)
            )
        );
    }

    ///                                                          ///
    ///                         HASHING UTILS                    ///
    ///                                                          ///

    function hashExecution(Transaction[] calldata txs, uint256 nonce, uint256 deadline) public view returns (bytes32) {
        return keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR(),
                keccak256(abi.encode(EXECUTION_TYPEHASH, hashTransactions(txs), nonce, deadline))
            )
        );
    }

    function hashTransactions(Transaction[] calldata txs) internal pure returns (bytes32) {
        uint256 numTxs = txs.length;

        bytes32[] memory txHashes = new bytes32[](numTxs);

        unchecked {
            for (uint256 i; i < numTxs; ++i) {
                txHashes[i] =
                    keccak256(abi.encode(TRANSACTION_TYPEHASH, txs[i].target, txs[i].value, keccak256(txs[i].data)));
            }
        }

        return keccak256(abi.encodePacked(txHashes));
    }

    function getNewMembersHash(Member[] calldata newMembers, uint256 nonce) public view returns (bytes32) {
        return keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR(),
                keccak256(abi.encode(NEW_MEMBERS_TYPEHASH, hashMembers(newMembers), nonce))
            )
        );
    }

    function hashMembers(Member[] calldata newMembers) internal pure returns (bytes32) {
        uint256 numNewMembers = newMembers.length;

        bytes32[] memory memberHashes = new bytes32[](numNewMembers);

        unchecked {
            for (uint256 i; i < numNewMembers; ++i) {
                memberHashes[i] = keccak256(abi.encode(MEMBER_TYPEHASH, newMembers[i].account, newMembers[i].driver));
            }
        }

        return keccak256(abi.encodePacked(memberHashes));
    }

    ///                                                          ///
    ///                        VALIDATION UTILS                  ///
    ///                                                          ///

    // TODO
    // function routeValidation(bytes32 digest, uint256 numSigs, Signature[] calldata sigs) internal {}

    function validateDriverSignature(bytes32 digest, Signature calldata sig) internal view {
        // Recover the signer of the digest.
        address recoveredAddress = ecrecover(digest, sig.v, sig.r, sig.s);

        // Ensure a valid address is recovered and that the signer is a driver.
        if (recoveredAddress == address(0) || !isDriver[recoveredAddress]) revert INVALID_SIGNATURE();
    }

    function validateMemberSignatures(bytes32 digest, uint256 numSigs, Signature[] calldata sigs) internal {
        // This is used to store the address recovered from each signature.
        address recoveredAddress;

        // This is used to track the number of members that have approved the digest.
        uint256 numApprovals;

        // The storage pointer to each member's approval for the digest.
        mapping(address => bool) storage hasApproved = hasMemberApproved[digest];

        // For each of the given signatures:
        for (uint256 i; i < numSigs;) {
            // Recover the signer of the digest.
            recoveredAddress = ecrecover(digest, sigs[i].v, sigs[i].r, sigs[i].s);

            // Ensure a valid address is recovered and that the signer is a member.
            if (recoveredAddress == address(0) || !isMember[recoveredAddress]) revert INVALID_SIGNATURE();

            // Ensure the member hasn't already approved the digest.
            if (hasApproved[recoveredAddress]) revert DUPLICATE_SIGNATURE();

            // Record the member's approval.
            hasApproved[recoveredAddress] = true;

            // Overflow is unrealistic.
            unchecked {
                // Update the number of members that have approved the digest.
                ++numApprovals;

                // Go to the next signature.
                ++i;
            }
        }

        // Ensure the number of approvals has reached the minimum threshold.
        if (numApprovals < threshold) revert THRESHOLD_NOT_MET();
    }

    ///                                                          ///
    ///                            EIP-1271                      ///
    ///                                                          ///

    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4) {
        address recoveredAddress = SignatureLib.validateSignature(hash, signature);

        if (isDriver[recoveredAddress]) {
            return 0x1626ba7e;
        } else {
            return 0xffffffff;
        }
    }

    ///                                                          ///
    ///                         TOKEN SUPPORT                    ///
    ///                                                          ///

    receive() external payable {
        emit WalletReceived(msg.sender, msg.value, address(this).balance);
    }

    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function onERC1155Received(address, address, uint256, uint256, bytes calldata) external pure returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address, address, uint256[] calldata, uint256[] calldata, bytes calldata)
        external
        pure
        returns (bytes4)
    {
        return this.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import { IWalletFactory } from "./interfaces/IWalletFactory.sol";
import { Wallet } from "./Wallet.sol";

contract WalletFactory is IWalletFactory {
    ///                                                          ///
    ///                          IMMUTABLES                      ///
    ///                                                          ///

    bytes32 internal immutable WALLET_CREATION_CODE_HASH;

    ///                                                          ///
    ///                          CONSTRUCTOR                     ///
    ///                                                          ///

    constructor() payable {
        WALLET_CREATION_CODE_HASH = keccak256(abi.encodePacked(type(Wallet).creationCode));
    }

    ///                                                          ///
    ///                                                          ///
    ///                                                          ///

    function computeWalletAddress(address[] calldata members) external view returns (address) {
        return address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            bytes1(0xff), address(this), keccak256(abi.encodePacked(members)), WALLET_CREATION_CODE_HASH
                        )
                    )
                )
            )
        );
    }

    function createWallet(address[] calldata drivers, address[] calldata members, uint256 memberThreshold)
        external
        payable
        returns (address)
    {
        bytes32 salt = keccak256(abi.encodePacked(members));

        address walletAddress = address(new Wallet{value: msg.value, salt: salt}());

        Wallet(payable(walletAddress)).initialize(drivers, members, memberThreshold, address(0), 0, "");

        emit WalletCreated(walletAddress, drivers, members, memberThreshold);

        return walletAddress;
    }

    // function createWallet(
    //     address[] calldata drivers,
    //     address[] calldata members,
    //     uint256 memberThreshold,
    //     TransactionWithOverwrites calldata initTx
    // ) external payable returns (address) {
    //     bytes32 salt = keccak256(abi.encodePacked(members));

    //     address walletAddress = address(new Wallet{value: msg.value, salt: salt}());

    //     bytes memory newInitTxData = overwrite(walletAddress, initTx.data, initTx.dataOverwrites);

    //     Wallet(payable(walletAddress)).initialize(
    //         drivers, members, memberThreshold, initTx.target, initTx.value, newInitTxData
    //     );

    //     emit WalletCreated(walletAddress, drivers, members, memberThreshold);

    //     return walletAddress;
    // }

    // function createWallet(
    //     address[] calldata drivers,
    //     address[] calldata members,
    //     uint256 memberThreshold,
    //     address initTarget,
    //     uint256 initValue,
    //     bytes calldata initData,
    //     uint256[] calldata initDataOverwrites
    // ) external payable returns (address) {
    //     bytes32 salt = keccak256(abi.encodePacked(members));

    //     address walletAddress = address(new Wallet{value: msg.value, salt: salt}());

    //     bytes memory newInitTxData = overwrite(walletAddress, initData, initDataOverwrites);

    //     Wallet(payable(walletAddress)).initialize(
    //         drivers, members, memberThreshold, initTarget, initValue, newInitTxData
    //     );

    //     emit WalletCreated(walletAddress, drivers, members, memberThreshold);

    //     return walletAddress;
    // }

    // function overwrite(address walletAddress, bytes memory initTxData, uint256[] calldata initTxDataOverwriteIndexes)
    //     internal
    //     pure
    //     returns (bytes memory)
    // {
    //     bytes memory walletAddressBytes = abi.encodePacked(walletAddress);

    //     uint256 numOverwrites = initTxDataOverwriteIndexes.length;

    //     uint256 index;

    //     unchecked {
    //         for (uint256 i; i < numOverwrites; ++i) {
    //             index = initTxDataOverwriteIndexes[i];

    //             for (uint256 j; j < 20; ++j) {
    //                 initTxData[index + j] = walletAddressBytes[j];
    //             }
    //         }
    //     }

    //     return initTxData;
    // }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20} from "../tokens/ERC20.sol";

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
/// @dev Note that none of the functions in this library check that a token has code at all! That responsibility is delegated to the caller.
library SafeTransferLib {
    /*//////////////////////////////////////////////////////////////
                             ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Transfer the ETH and store if it succeeded or not.
            success := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(success, "ETH_TRANSFER_FAILED");
    }

    /*//////////////////////////////////////////////////////////////
                            ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), from) // Append the "from" argument.
            mstore(add(freeMemoryPointer, 36), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 100 because the length of our calldata totals up like so: 4 + 32 * 3.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 100, 0, 32)
            )
        }

        require(success, "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "TRANSFER_FAILED");
    }

    function safeApprove(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "APPROVE_FAILED");
    }
}