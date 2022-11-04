/**
 *Submitted for verification at Etherscan.io on 2022-11-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice ERC1155 interface to receive tokens.
/// @author Modified from Solbase (https://github.com/Sol-DAO/solbase/blob/main/src/tokens/ERC1155/ERC1155.sol)
abstract contract ERC1155TokenReceiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) public payable virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) public payable virtual returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

/// @notice Modern, minimalist, and gas-optimized ERC1155 implementation with Compound-style voting and flexible permissioning scheme.
/// @author Modified from ERC1155V (https://github.com/kalidao/ERC1155V/blob/main/src/ERC1155V.sol)
/// @author Modified from Compound (https://github.com/compound-finance/compound-protocol/blob/master/contracts/Governance/Comp.sol)
abstract contract KeepToken {
    /// -----------------------------------------------------------------------
    /// Events
    /// -----------------------------------------------------------------------

    event DelegateChanged(
        address indexed delegator,
        address indexed fromDelegate,
        address indexed toDelegate,
        uint256 id
    );

    event DelegateVotesChanged(
        address indexed delegate,
        uint256 indexed id,
        uint256 previousBalance,
        uint256 newBalance
    );

    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 amount
    );

    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] amounts
    );

    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    event TransferabilitySet(
        address indexed operator,
        uint256 indexed id,
        bool on
    );

    event PermissionSet(address indexed operator, uint256 indexed id, bool on);

    event UserPermissionSet(
        address indexed operator,
        address indexed to,
        uint256 indexed id,
        bool on
    );

    event URI(string value, uint256 indexed id);

    /// -----------------------------------------------------------------------
    /// Custom Errors
    /// -----------------------------------------------------------------------

    error LengthMismatch();

    error Unauthorized();

    error NonTransferable();

    error NotPermitted();

    error UnsafeRecipient();

    error InvalidRecipient();

    error ExpiredSig();

    error InvalidSig();

    error Undetermined();

    error Overflow();

    /// -----------------------------------------------------------------------
    /// ERC1155 Storage
    /// -----------------------------------------------------------------------

    mapping(address => mapping(uint256 => uint256)) public balanceOf;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /// -----------------------------------------------------------------------
    /// EIP-712 Storage/Logic
    /// -----------------------------------------------------------------------

    mapping(address => uint256) public nonces;

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    // `keccak256(
                    //     "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                    // )`
                    0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f,
                    // `keccak256(bytes("Keep"))`
                    0x21d66785fec14e4da3d76f3866cf99a28f4da49ec8782c3cab7cf79c1b6fa66b,
                    // `keccak256("1")`
                    0xc89efdaa54c0f20c7adf612882df0950f5a951637e0307cdcb4c672f298b8bc6,
                    block.chainid,
                    address(this)
                )
            );
    }

    /// -----------------------------------------------------------------------
    /// ID Storage
    /// -----------------------------------------------------------------------

    uint256 internal constant SIGN_KEY = uint32(0x6c4b5546); // `execute()`

    mapping(uint256 => uint256) public totalSupply;

    mapping(uint256 => bool) public transferable;

    mapping(uint256 => bool) public permissioned;

    mapping(address => mapping(uint256 => bool)) public userPermissioned;

    /// -----------------------------------------------------------------------
    /// Checkpoint Storage
    /// -----------------------------------------------------------------------

    mapping(address => mapping(uint256 => address)) internal _delegates;

    mapping(address => mapping(uint256 => uint256)) public numCheckpoints;

    mapping(address => mapping(uint256 => mapping(uint256 => Checkpoint)))
        public checkpoints;

    struct Checkpoint {
        uint40 fromTimestamp;
        uint216 votes;
    }

    /// -----------------------------------------------------------------------
    /// Metadata Logic
    /// -----------------------------------------------------------------------

    function uri(uint256 id) public view virtual returns (string memory);

    function name() public pure virtual returns (string memory) {
        uint256 placeholder;

        assembly {
            placeholder := sub(
                calldatasize(),
                add(shr(240, calldataload(sub(calldatasize(), 2))), 2)
            )

            placeholder := calldataload(add(placeholder, 2))
        }

        return string(abi.encodePacked(placeholder));
    }

    /// -----------------------------------------------------------------------
    /// ERC165 Logic
    /// -----------------------------------------------------------------------

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        returns (bool)
    {
        return
            // ERC165 interface ID for ERC165.
            interfaceId == this.supportsInterface.selector ||
            // ERC165 interface ID for ERC1155.
            interfaceId == 0xd9b67a26 ||
            // ERC165 interface ID for ERC1155MetadataURI.
            interfaceId == 0x0e89341c;
    }

    /// -----------------------------------------------------------------------
    /// ERC1155 Logic
    /// -----------------------------------------------------------------------

    function balanceOfBatch(address[] calldata owners, uint256[] calldata ids)
        public
        view
        virtual
        returns (uint256[] memory balances)
    {
        if (owners.length != ids.length) revert LengthMismatch();

        balances = new uint256[](owners.length);

        for (uint256 i; i < owners.length; ) {
            balances[i] = balanceOf[owners[i]][ids[i]];

            // Unchecked because the only math done is incrementing
            // the array index counter which cannot possibly overflow.
            unchecked {
                ++i;
            }
        }
    }

    function setApprovalForAll(address operator, bool approved)
        public
        payable
        virtual
    {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) public payable virtual {
        if (msg.sender != from)
            if (!isApprovedForAll[from][msg.sender]) revert Unauthorized();

        if (!transferable[id]) revert NonTransferable();

        if (permissioned[id])
            if (!userPermissioned[to][id] || !userPermissioned[from][id])
                revert NotPermitted();

        // If not transferring SIGN_KEY, update delegation balance.
        // Otherwise, prevent transfer to SIGN_KEY holder.
        if (id != SIGN_KEY)
            _moveDelegates(delegates(from, id), delegates(to, id), id, amount);
        else if (balanceOf[to][id] != 0) revert Overflow();

        balanceOf[from][id] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to][id] += amount;
        }

        emit TransferSingle(msg.sender, from, to, id, amount);

        if (to.code.length != 0) {
            if (
                ERC1155TokenReceiver(to).onERC1155Received(
                    msg.sender,
                    from,
                    id,
                    amount,
                    data
                ) != ERC1155TokenReceiver.onERC1155Received.selector
            ) revert UnsafeRecipient();
        } else if (to == address(0)) revert InvalidRecipient();
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) public payable virtual {
        if (ids.length != amounts.length) revert LengthMismatch();

        if (msg.sender != from)
            if (!isApprovedForAll[from][msg.sender]) revert Unauthorized();

        // Storing these outside the loop saves ~15 gas per iteration.
        uint256 id;
        uint256 amount;

        for (uint256 i; i < ids.length; ) {
            id = ids[i];
            amount = amounts[i];

            if (!transferable[id]) revert NonTransferable();

            if (permissioned[id])
                if (!userPermissioned[to][id] || !userPermissioned[from][id])
                    revert NotPermitted();

            // If not transferring SIGN_KEY, update delegation balance.
            // Otherwise, prevent transfer to SIGN_KEY holder.
            if (id != SIGN_KEY)
                _moveDelegates(
                    delegates(from, id),
                    delegates(to, id),
                    id,
                    amount
                );
            else if (balanceOf[to][id] != 0) revert Overflow();

            balanceOf[from][id] -= amount;

            // Cannot overflow because the sum of all user
            // balances can't exceed the max uint256 value.
            unchecked {
                balanceOf[to][id] += amount;
            }

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, from, to, ids, amounts);

        if (to.code.length != 0) {
            if (
                ERC1155TokenReceiver(to).onERC1155BatchReceived(
                    msg.sender,
                    from,
                    ids,
                    amounts,
                    data
                ) != ERC1155TokenReceiver.onERC1155BatchReceived.selector
            ) revert UnsafeRecipient();
        } else if (to == address(0)) revert InvalidRecipient();
    }

    /// -----------------------------------------------------------------------
    /// EIP-2612-style Permit Logic
    /// -----------------------------------------------------------------------

    function permit(
        address owner,
        address operator,
        bool approved,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public payable virtual {
        if (block.timestamp > deadline) revert ExpiredSig();

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
                                    "Permit(address owner,address operator,bool approved,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                operator,
                                approved,
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

            if (recoveredAddress == address(0)) revert InvalidSig();

            if (recoveredAddress != owner) revert InvalidSig();

            isApprovedForAll[recoveredAddress][operator] = approved;
        }

        emit ApprovalForAll(owner, operator, approved);
    }

    /// -----------------------------------------------------------------------
    /// Checkpoint Logic
    /// -----------------------------------------------------------------------

    function getVotes(address account, uint256 id)
        public
        view
        virtual
        returns (uint256)
    {
        return getCurrentVotes(account, id);
    }

    function getCurrentVotes(address account, uint256 id)
        public
        view
        virtual
        returns (uint256)
    {
        // Unchecked because subtraction only occurs if positive `nCheckpoints`.
        unchecked {
            uint256 nCheckpoints = numCheckpoints[account][id];

            uint256 result;

            if (nCheckpoints != 0)
                result = checkpoints[account][id][nCheckpoints - 1].votes;

            return result;
        }
    }

    function getPastVotes(
        address account,
        uint256 id,
        uint256 timestamp
    ) public view virtual returns (uint256) {
        return getPriorVotes(account, id, timestamp);
    }

    function getPriorVotes(
        address account,
        uint256 id,
        uint256 timestamp
    ) public view virtual returns (uint256) {
        if (block.timestamp <= timestamp) revert Undetermined();

        uint256 nCheckpoints = numCheckpoints[account][id];

        if (nCheckpoints == 0) return 0;

        // Unchecked because subtraction only occurs if positive `nCheckpoints`.
        unchecked {
            uint256 prevCheckpoint = nCheckpoints - 1;

            if (
                checkpoints[account][id][prevCheckpoint].fromTimestamp <=
                timestamp
            ) return checkpoints[account][id][prevCheckpoint].votes;

            if (checkpoints[account][id][0].fromTimestamp > timestamp) return 0;

            uint256 lower;

            uint256 upper = prevCheckpoint;

            while (upper > lower) {
                uint256 center = upper - (upper - lower) / 2;

                Checkpoint memory cp = checkpoints[account][id][center];

                if (cp.fromTimestamp == timestamp) {
                    return cp.votes;
                } else if (cp.fromTimestamp < timestamp) {
                    lower = center;
                } else {
                    upper = center - 1;
                }
            }

            return checkpoints[account][id][lower].votes;
        }
    }

    /// -----------------------------------------------------------------------
    /// Delegation Logic
    /// -----------------------------------------------------------------------

    function delegates(address account, uint256 id)
        public
        view
        virtual
        returns (address)
    {
        address current = _delegates[account][id];

        if (current == address(0)) current = account;

        return current;
    }

    function delegate(address delegatee, uint256 id) public payable virtual {
        _delegate(msg.sender, delegatee, id);
    }

    function delegateBySig(
        address delegatee,
        uint256 nonce,
        uint256 deadline,
        uint256 id,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public payable virtual {
        if (block.timestamp > deadline) revert ExpiredSig();

        address recoveredAddress = ecrecover(
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR(),
                    keccak256(
                        abi.encode(
                            keccak256(
                                "Delegation(address delegatee,uint256 nonce,uint256 deadline,uint256 id)"
                            ),
                            delegatee,
                            nonce,
                            deadline,
                            id
                        )
                    )
                )
            ),
            v,
            r,
            s
        );

        if (recoveredAddress == address(0)) revert InvalidSig();

        // Unchecked because the only math done is incrementing
        // the delegator's nonce which cannot realistically overflow.
        unchecked {
            if (nonce != nonces[recoveredAddress]++) revert InvalidSig();
        }

        _delegate(recoveredAddress, delegatee, id);
    }

    function _delegate(
        address delegator,
        address delegatee,
        uint256 id
    ) internal virtual {
        address currentDelegate = delegates(delegator, id);

        _delegates[delegator][id] = delegatee;

        emit DelegateChanged(delegator, currentDelegate, delegatee, id);

        _moveDelegates(
            currentDelegate,
            delegatee,
            id,
            balanceOf[delegator][id]
        );
    }

    function _moveDelegates(
        address srcRep,
        address dstRep,
        uint256 id,
        uint256 amount
    ) internal virtual {
        if (srcRep != dstRep) {
            if (amount != 0) {
                if (srcRep != address(0)) {
                    uint256 srcRepNum = numCheckpoints[srcRep][id];

                    uint256 srcRepOld;

                    // Unchecked because subtraction only occurs if positive `srcRepNum`.
                    unchecked {
                        srcRepOld = srcRepNum != 0
                            ? checkpoints[srcRep][id][srcRepNum - 1].votes
                            : 0;
                    }

                    _writeCheckpoint(
                        srcRep,
                        id,
                        srcRepNum,
                        srcRepOld,
                        srcRepOld - amount
                    );
                }

                if (dstRep != address(0)) {
                    uint256 dstRepNum = numCheckpoints[dstRep][id];

                    uint256 dstRepOld;

                    // Unchecked because subtraction only occurs if positive `dstRepNum`.
                    unchecked {
                        if (dstRepNum != 0)
                            dstRepOld = checkpoints[dstRep][id][dstRepNum - 1]
                                .votes;
                    }

                    _writeCheckpoint(
                        dstRep,
                        id,
                        dstRepNum,
                        dstRepOld,
                        dstRepOld + amount
                    );
                }
            }
        }
    }

    function _writeCheckpoint(
        address delegatee,
        uint256 id,
        uint256 nCheckpoints,
        uint256 oldVotes,
        uint256 newVotes
    ) internal virtual {
        emit DelegateVotesChanged(delegatee, id, oldVotes, newVotes);

        // Unchecked because subtraction only occurs if positive `nCheckpoints`.
        unchecked {
            if (nCheckpoints != 0) {
                if (
                    checkpoints[delegatee][id][nCheckpoints - 1]
                        .fromTimestamp == block.timestamp
                ) {
                    checkpoints[delegatee][id][nCheckpoints - 1]
                        .votes = _safeCastTo216(newVotes);
                    return;
                }
            }

            checkpoints[delegatee][id][nCheckpoints] = Checkpoint(
                _safeCastTo40(block.timestamp),
                _safeCastTo216(newVotes)
            );

            // Unchecked because the only math done is incrementing
            // checkpoints which cannot realistically overflow.
            ++numCheckpoints[delegatee][id];
        }
    }

    /// -----------------------------------------------------------------------
    /// Safecast Logic
    /// -----------------------------------------------------------------------

    function _safeCastTo40(uint256 x) internal pure virtual returns (uint40) {
        if (x >= (1 << 40)) revert Overflow();

        return uint40(x);
    }

    function _safeCastTo216(uint256 x) internal pure virtual returns (uint216) {
        if (x >= (1 << 216)) revert Overflow();

        return uint216(x);
    }

    /// -----------------------------------------------------------------------
    /// Internal Mint/Burn Logic
    /// -----------------------------------------------------------------------

    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) internal virtual {
        _safeCastTo216(totalSupply[id] += amount);

        // If not minting SIGN_KEY, update delegation balance.
        // Otherwise, prevent minting to SIGN_KEY holder.
        if (id != SIGN_KEY)
            _moveDelegates(address(0), delegates(to, id), id, amount);
        else if (balanceOf[to][id] != 0) revert Overflow();

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to][id] += amount;
        }

        emit TransferSingle(msg.sender, address(0), to, id, amount);

        if (to.code.length != 0) {
            if (
                ERC1155TokenReceiver(to).onERC1155Received(
                    msg.sender,
                    address(0),
                    id,
                    amount,
                    data
                ) != ERC1155TokenReceiver.onERC1155Received.selector
            ) revert UnsafeRecipient();
        } else if (to == address(0)) revert InvalidRecipient();
    }

    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        balanceOf[from][id] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply[id] -= amount;
        }

        emit TransferSingle(msg.sender, from, address(0), id, amount);

        // If not burning SIGN_KEY, update delegation balance.
        if (id != SIGN_KEY)
            _moveDelegates(delegates(from, id), address(0), id, amount);
    }

    /// -----------------------------------------------------------------------
    /// Internal Permission Logic
    /// -----------------------------------------------------------------------

    function _setTransferability(uint256 id, bool on) internal virtual {
        transferable[id] = on;

        emit TransferabilitySet(msg.sender, id, on);
    }

    function _setPermission(uint256 id, bool on) internal virtual {
        permissioned[id] = on;

        emit PermissionSet(msg.sender, id, on);
    }

    function _setUserPermission(
        address to,
        uint256 id,
        bool on
    ) internal virtual {
        userPermissioned[to][id] = on;

        emit UserPermissionSet(msg.sender, to, id, on);
    }
}

/// @notice Contract that enables a single call to call multiple methods on itself.
/// @author Solbase (https://github.com/Sol-DAO/solbase/blob/main/src/utils/Multicallable.sol)
/// @author Modified from Solady (https://github.com/vectorized/solady/blob/main/src/utils/Multicallable.sol)
/// @dev WARNING!
/// Multicallable is NOT SAFE for use in contracts with checks / requires on `msg.value`
/// (e.g. in NFT minting / auction contracts) without a suitable nonce mechanism.
/// It WILL open up your contract to double-spend vulnerabilities / exploits.
/// See: (https://www.paradigm.xyz/2021/08/two-rights-might-make-a-wrong/)
abstract contract Multicallable {
    /// @dev Apply `DELEGATECALL` with the current contract to each calldata in `data`,
    /// and store the `abi.encode` formatted results of each `DELEGATECALL` into `results`.
    /// If any of the `DELEGATECALL`s reverts, the entire transaction is reverted,
    /// and the error is bubbled up.
    function multicall(bytes[] calldata data)
        public
        payable
        returns (bytes[] memory results)
    {
        assembly {
            if data.length {
                results := mload(0x40) // Point `results` to start of free memory.
                mstore(results, data.length) // Store `data.length` into `results`.
                results := add(results, 0x20)

                // `shl` 5 is equivalent to multiplying by 0x20.
                let end := shl(5, data.length)
                // Copy the offsets from calldata into memory.
                calldatacopy(results, data.offset, end)
                // Pointer to the top of the memory (i.e. start of the free memory).
                let memPtr := add(results, end)
                end := add(results, end)

                // prettier-ignore
                for {} 1 {} {
                    // The offset of the current bytes in the calldata.
                    let o := add(data.offset, mload(results))
                    // Copy the current bytes from calldata to the memory.
                    calldatacopy(
                        memPtr,
                        add(o, 0x20), // The offset of the current bytes' bytes.
                        calldataload(o) // The length of the current bytes.
                    )
                    if iszero(delegatecall(gas(), address(), memPtr, calldataload(o), 0x00, 0x00)) {
                        // Bubble up the revert if the delegatecall reverts.
                        returndatacopy(0x00, 0x00, returndatasize())
                        revert(0x00, returndatasize())
                    }
                    // Append the current `memPtr` into `results`.
                    mstore(results, memPtr)
                    results := add(results, 0x20)
                    // Append the `returndatasize()`, and the return data.
                    mstore(memPtr, returndatasize())
                    returndatacopy(add(memPtr, 0x20), 0x00, returndatasize())
                    // Advance the `memPtr` by `returndatasize() + 0x20`,
                    // rounded up to the next multiple of 32.
                    memPtr := and(add(add(memPtr, returndatasize()), 0x3f), 0xffffffffffffffe0)
                    // prettier-ignore
                    if iszero(lt(results, end)) { break }
                }
                // Restore `results` and allocate memory for it.
                results := mload(0x40)
                mstore(0x40, memPtr)
            }
        }
    }
}

/// @title Keep
/// @notice Tokenized multisig wallet.
/// @author z0r0z.eth
/// @custom:coauthor @ControlCplusControlV
/// @custom:coauthor boredretard.eth
/// @custom:coauthor vectorized.eth
/// @custom:coauthor horsefacts.eth
/// @custom:coauthor shivanshi.eth
/// @custom:coauthor @0xAlcibiades
/// @custom:coauthor LeXpunK Army
/// @custom:coauthor @0xmichalis
/// @custom:coauthor @iFrostizz
/// @custom:coauthor @m1guelpf
/// @custom:coauthor @asnared
/// @custom:coauthor @0xPhaze
/// @custom:coauthor out.eth

enum Operation {
    call,
    delegatecall,
    create
}

struct Call {
    Operation op;
    address to;
    uint256 value;
    bytes data;
}

struct Signature {
    address user;
    uint8 v;
    bytes32 r;
    bytes32 s;
}

contract Keep is ERC1155TokenReceiver, KeepToken, Multicallable {
    /// -----------------------------------------------------------------------
    /// Events
    /// -----------------------------------------------------------------------

    /// @dev Emitted when Keep executes call.
    event Executed(
        uint256 indexed nonce,
        Operation op,
        address to,
        uint256 value,
        bytes data
    );

    /// @dev Emitted when quorum threshold is updated.
    event QuorumSet(uint256 threshold);

    /// -----------------------------------------------------------------------
    /// Custom Errors
    /// -----------------------------------------------------------------------

    /// @dev Throws if `initialize()` is called more than once.
    error AlreadyInit();

    /// @dev Throws if quorum exceeds `totalSupply(SIGN_KEY)`.
    error QuorumOverSupply();

    /// @dev Throws if quorum with `threshold = 0` is set.
    error InvalidThreshold();

    /// @dev Throws if `execute()` doesn't complete operation.
    error ExecuteFailed();

    /// -----------------------------------------------------------------------
    /// Keep Storage/Logic
    /// -----------------------------------------------------------------------

    /// @dev The number which `s` must not exceed in order for
    /// the signature to be non-malleable.
    bytes32 internal constant MALLEABILITY_THRESHOLD =
        0x7fffffffffffffffffffffffffffffff5d576e7357a4501ddfe92f46681b20a0;

    /// @dev Core ID key permission.
    uint256 internal immutable CORE_KEY = uint32(type(KeepToken).interfaceId);

    /// @dev Default metadata fetcher for `uri()`.
    Keep internal immutable uriFetcher;

    /// @dev Record of states verifying `execute()`.
    uint120 public nonce;

    /// @dev SIGN_KEY threshold to `execute()`.
    uint120 public quorum;

    /// @dev Internal ID metadata mapping.
    mapping(uint256 => string) internal _uris;

    /// @dev ID metadata fetcher.
    /// @param id ID to fetch from.
    /// @return tokenURI Metadata.
    function uri(uint256 id)
        public
        view
        virtual
        override
        returns (string memory)
    {
        string memory tokenURI = _uris[id];

        if (bytes(tokenURI).length > 0) return tokenURI;
        else return uriFetcher.uri(id);
    }

    /// @dev Access control check for ID key balance holders.
    /// Initalizes with `address(this)` having implicit permission
    /// without writing to storage by checking `totalSupply()` is zero.
    /// Otherwise, this permission can be set to additional accounts,
    /// including retaining `address(this)`, via `mint()`.
    function _authorized() internal view virtual returns (bool) {
        if (
            (totalSupply[CORE_KEY] == 0 && msg.sender == address(this)) ||
            balanceOf[msg.sender][CORE_KEY] != 0 ||
            balanceOf[msg.sender][uint32(msg.sig)] != 0
        ) return true;
        else revert Unauthorized();
    }

    /// -----------------------------------------------------------------------
    /// ERC165 Logic
    /// -----------------------------------------------------------------------

    /// @dev ERC165 interface detection.
    /// @param interfaceId ID to check.
    /// @return Fetch detection success.
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            // ERC165 Interface ID for ERC721TokenReceiver.
            interfaceId == this.onERC721Received.selector ||
            // ERC165 Interface ID for ERC1155TokenReceiver.
            interfaceId == type(ERC1155TokenReceiver).interfaceId ||
            // ERC165 Interface IDs for ERC1155.
            super.supportsInterface(interfaceId);
    }

    /// -----------------------------------------------------------------------
    /// ERC721 Receiver Logic
    /// -----------------------------------------------------------------------

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) public payable virtual returns (bytes4) {
        return this.onERC721Received.selector;
    }

    /// -----------------------------------------------------------------------
    /// Initialization Logic
    /// -----------------------------------------------------------------------

    /// @notice Create Keep template.
    /// @param _uriFetcher Metadata default.
    constructor(Keep _uriFetcher) payable {
        uriFetcher = _uriFetcher;

        // Deploy as singleton.
        quorum = 1;
    }

    /// @notice Initialize Keep configuration.
    /// @param calls Initial Keep operations.
    /// @param signers Initial signer set.
    /// @param threshold Initial quorum.
    function initialize(
        Call[] calldata calls,
        address[] calldata signers,
        uint256 threshold
    ) public payable virtual {
        if (quorum != 0) revert AlreadyInit();

        if (threshold == 0) revert InvalidThreshold();

        if (threshold > signers.length) revert QuorumOverSupply();

        if (calls.length != 0) {
            for (uint256 i; i < calls.length; ) {
                _execute(
                    calls[i].op,
                    calls[i].to,
                    calls[i].value,
                    calls[i].data
                );

                // An array can't have a total length
                // larger than the max uint256 value.
                unchecked {
                    ++i;
                }
            }
        }

        address previous;
        address signer;
        uint256 supply;

        for (uint256 i; i < signers.length; ) {
            signer = signers[i];

            // Prevent zero and duplicate signers.
            if (previous >= signer) revert InvalidSig();

            previous = signer;

            emit TransferSingle(tx.origin, address(0), signer, SIGN_KEY, 1);

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++balanceOf[signer][SIGN_KEY];
                ++supply;
                ++i;
            }
        }

        totalSupply[SIGN_KEY] = supply;
        quorum = uint120(threshold);
    }

    /// -----------------------------------------------------------------------
    /// Execution Logic
    /// -----------------------------------------------------------------------

    /// @notice Execute operation from Keep with signatures.
    /// @param op Enum operation to execute.
    /// @param to Address to send operation to.
    /// @param value Amount of ETH to send in operation.
    /// @param data Payload to send in operation.
    /// @param sigs Array of Keep signatures in ascending order by addresses.
    function execute(
        Operation op,
        address to,
        uint256 value,
        bytes calldata data,
        Signature[] calldata sigs
    ) public payable virtual {
        // Begin signature validation with hashed inputs.
        bytes32 hash = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR(),
                keccak256(
                    abi.encode(
                        keccak256(
                            "Execute(uint8 op,address to,uint256 value,bytes data,uint120 nonce)"
                        ),
                        op,
                        to,
                        value,
                        keccak256(data),
                        nonce
                    )
                )
            )
        );

        // Start zero in loop to ensure ascending addresses.
        address previous;

        // Validation is length of quorum threshold.
        uint256 threshold = quorum;

        // Store outside loop for gas optimization.
        Signature calldata sig;

        for (uint256 i; i < threshold; ) {
            // Load signature items.
            sig = sigs[i];
            address user = sig.user;

            // Check SIGN_KEY balance.
            // This also confirms non-zero `user`.
            if (balanceOf[user][SIGN_KEY] == 0) revert InvalidSig();

            // Check signature recovery.
            _recoverSig(hash, user, sig.v, sig.r, sig.s);

            // Check against duplicates.
            if (previous >= user) revert InvalidSig();

            // Memo signature for next iteration until quorum.
            previous = user;

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        _execute(op, to, value, data);
    }

    function _recoverSig(
        bytes32 hash,
        address user,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal view virtual {
        address signer;

        // Perform signature recovery via ecrecover.
        assembly {
            // Copy the free memory pointer so that we can restore it later.
            let m := mload(0x40)

            // If `s` in lower half order, such that the signature is not malleable.
            if iszero(gt(s, MALLEABILITY_THRESHOLD)) {
                mstore(0x00, hash)
                mstore(0x20, v)
                mstore(0x40, r)
                mstore(0x60, s)
                pop(
                    staticcall(
                        gas(), // Amount of gas left for the transaction.
                        0x01, // Address of `ecrecover`.
                        0x00, // Start of input.
                        0x80, // Size of input.
                        0x40, // Start of output.
                        0x20 // Size of output.
                    )
                )
                // Restore the zero slot.
                mstore(0x60, 0)
                // `returndatasize()` will be `0x20` upon success, and `0x00` otherwise.
                signer := mload(sub(0x60, returndatasize()))
            }
            // Restore the free memory pointer.
            mstore(0x40, m)
        }

        // If recovery doesn't match `user`, verify contract signature with ERC1271.
        if (user != signer) {
            bool valid;

            assembly {
                // Load the free memory pointer.
                // Simply using the free memory usually costs less if many slots are needed.
                let m := mload(0x40)

                // `bytes4(keccak256("isValidSignature(bytes32,bytes)"))`.
                let f := shl(224, 0x1626ba7e)
                // Write the abi-encoded calldata into memory, beginning with the function selector.
                mstore(m, f) // `bytes4(keccak256("isValidSignature(bytes32,bytes)"))`.
                mstore(add(m, 0x04), hash)
                mstore(add(m, 0x24), 0x40) // The offset of the `signature` in the calldata.
                mstore(add(m, 0x44), 65) // Store the length of the signature.
                mstore(add(m, 0x64), r) // Store `r` of the signature.
                mstore(add(m, 0x84), s) // Store `s` of the signature.
                mstore8(add(m, 0xa4), v) // Store `v` of the signature.

                valid := and(
                    and(
                        // Whether the returndata is the magic value `0x1626ba7e` (left-aligned).
                        eq(mload(0x00), f),
                        // Whether the returndata is exactly 0x20 bytes (1 word) long.
                        eq(returndatasize(), 0x20)
                    ),
                    // Whether the staticcall does not revert.
                    // This must be placed at the end of the `and` clause,
                    // as the arguments are evaluated from right to left.
                    staticcall(
                        gas(), // Remaining gas.
                        user, // The `user` address.
                        m, // Offset of calldata in memory.
                        0xa5, // Length of calldata in memory.
                        0x00, // Offset of returndata.
                        0x20 // Length of returndata to write.
                    )
                )
            }

            if (!valid) revert InvalidSig();
        }
    }

    /// @notice Execute operations from Keep via `execute()` or as ID key holder.
    /// @param calls Keep operations as arrays of `op, to, value, data`.
    function multiexecute(Call[] calldata calls) public payable virtual {
        _authorized();

        for (uint256 i; i < calls.length; ) {
            _execute(calls[i].op, calls[i].to, calls[i].value, calls[i].data);

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }
    }

    function _execute(
        Operation op,
        address to,
        uint256 value,
        bytes memory data
    ) internal virtual {
        if (op == Operation.call) {
            // Unchecked because the only math done is incrementing
            // Keep nonce which cannot realistically overflow.
            unchecked {
                emit Executed(nonce++, op, to, value, data);
            }

            bool success;

            assembly {
                success := call(
                    gas(),
                    to,
                    value,
                    add(data, 0x20),
                    mload(data),
                    0,
                    0
                )
            }

            if (!success) revert ExecuteFailed();
        } else if (op == Operation.delegatecall) {
            // Unchecked because the only math done is incrementing
            // Keep nonce which cannot realistically overflow.
            unchecked {
                emit Executed(nonce++, op, to, value, data);
            }

            bool success;

            assembly {
                success := delegatecall(
                    gas(),
                    to,
                    add(data, 0x20),
                    mload(data),
                    0,
                    0
                )
            }

            if (!success) revert ExecuteFailed();
        } else {
            uint256 txNonce;

            // Unchecked because the only math done is incrementing
            // Keep nonce which cannot realistically overflow.
            unchecked {
                txNonce = nonce++;
            }

            assembly {
                to := create(value, add(data, 0x20), mload(data))
            }

            if (to == address(0)) revert ExecuteFailed();

            emit Executed(txNonce, op, to, value, data);
        }
    }

    /// -----------------------------------------------------------------------
    /// Mint/Burn Logic
    /// -----------------------------------------------------------------------

    /// @notice ID minter.
    /// @param to Recipient of mint.
    /// @param id ID to mint.
    /// @param amount ID balance to mint.
    /// @param data Optional data payload.
    function mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) public payable virtual {
        _authorized();

        _mint(to, id, amount, data);
    }

    /// @notice ID burner.
    /// @param from Account to burn from.
    /// @param id ID to burn.
    /// @param amount Balance to burn.
    function burn(
        address from,
        uint256 id,
        uint256 amount
    ) public payable virtual {
        if (msg.sender != from)
            if (!isApprovedForAll[from][msg.sender])
                if (!_authorized()) revert Unauthorized();

        _burn(from, id, amount);

        if (id == SIGN_KEY)
            if (quorum > totalSupply[SIGN_KEY]) revert QuorumOverSupply();
    }

    /// -----------------------------------------------------------------------
    /// Threshold Setting Logic
    /// -----------------------------------------------------------------------

    /// @notice Update Keep quorum threshold.
    /// @param threshold Signature threshold for `execute()`.
    function setQuorum(uint256 threshold) public payable virtual {
        _authorized();

        if (threshold == 0) revert InvalidThreshold();

        if (threshold > totalSupply[SIGN_KEY]) revert QuorumOverSupply();

        quorum = uint120(threshold);

        emit QuorumSet(threshold);
    }

    /// -----------------------------------------------------------------------
    /// ID Setting Logic
    /// -----------------------------------------------------------------------

    /// @notice ID transferability setting.
    /// @param id ID to set transferability for.
    /// @param on Transferability setting.
    function setTransferability(uint256 id, bool on) public payable virtual {
        _authorized();

        _setTransferability(id, on);
    }

    /// @notice ID transfer permission toggle.
    /// @param id ID to set permission for.
    /// @param on Permission setting.
    /// @dev This sets account-based ID restriction globally.
    function setPermission(uint256 id, bool on) public payable virtual {
        _authorized();

        _setPermission(id, on);
    }

    /// @notice ID transfer permission setting.
    /// @param to Account to set permission for.
    /// @param id ID to set permission for.
    /// @param on Permission setting.
    /// @dev This sets account-based ID restriction specifically.
    function setUserPermission(
        address to,
        uint256 id,
        bool on
    ) public payable virtual {
        _authorized();

        _setUserPermission(to, id, on);
    }

    /// @notice ID metadata setting.
    /// @param id ID to set metadata for.
    /// @param tokenURI Metadata setting.
    function setURI(uint256 id, string calldata tokenURI)
        public
        payable
        virtual
    {
        _authorized();

        _uris[id] = tokenURI;

        emit URI(tokenURI, id);
    }
}

/// @notice Minimal proxy library with immutable args operations.
/// @author Modified from Solady (https://github.com/Vectorized/solady/blob/main/src/utils/LibClone.sol)
library LibClone {
    /// -----------------------------------------------------------------------
    /// Custom Errors
    /// -----------------------------------------------------------------------

    /// @dev Unable to deploy the clone.
    error DeploymentFailed();

    /// -----------------------------------------------------------------------
    /// Clone Operations
    /// -----------------------------------------------------------------------

    /// @dev Deploys a deterministic clone of `implementation`,
    /// using immutable arguments encoded in `data`, with `salt`.
    function cloneDeterministic(
        address implementation,
        bytes memory data,
        bytes32 salt
    ) internal returns (address instance) {
        assembly {
            // Compute the boundaries of the data and cache the memory slots around it.
            let mBefore3 := mload(sub(data, 0x60))
            let mBefore2 := mload(sub(data, 0x40))
            let mBefore1 := mload(sub(data, 0x20))
            let dataLength := mload(data)
            let dataEnd := add(add(data, 0x20), dataLength)
            let mAfter1 := mload(dataEnd)

            // +2 bytes for telling how much data there is appended to the call.
            let extraLength := add(dataLength, 2)

            // Write the bytecode before the data.
            mstore(data, 0x5af43d3d93803e606057fd5bf3)
            // Write the address of the implementation.
            mstore(sub(data, 0x0d), implementation)
            // Write the rest of the bytecode.
            mstore(
                sub(data, 0x21),
                or(
                    shl(0x48, extraLength),
                    0x593da1005b363d3d373d3d3d3d610000806062363936013d73
                )
            )
            // `keccak256("ReceiveETH(uint256)")`.
            mstore(
                sub(data, 0x3a),
                0x9e4ac34f21c619cefc926c8bd93b54bf5a39c7ab2127a895af1cc0691d7e3dff
            )
            mstore(
                sub(data, 0x5a),
                or(
                    shl(0x78, add(extraLength, 0x62)),
                    0x6100003d81600a3d39f336602c57343d527f
                )
            )
            mstore(dataEnd, shl(0xf0, extraLength))

            // Create the instance.
            instance := create2(
                0,
                sub(data, 0x4c),
                add(extraLength, 0x6c),
                salt
            )

            // If `instance` is zero, revert.
            if iszero(instance) {
                // Store the function selector of `DeploymentFailed()`.
                mstore(0x00, 0x30116425)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            // Restore the overwritten memory surrounding `data`.
            mstore(dataEnd, mAfter1)
            mstore(data, dataLength)
            mstore(sub(data, 0x20), mBefore1)
            mstore(sub(data, 0x40), mBefore2)
            mstore(sub(data, 0x60), mBefore3)
        }
    }

    /// @dev Returns the address of the deterministic clone of
    /// `implementation` using immutable arguments encoded in `data`, with `salt`, by `deployer`.
    function predictDeterministicAddress(
        address implementation,
        bytes memory data,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        assembly {
            // Compute the boundaries of the data and cache the memory slots around it.
            let mBefore3 := mload(sub(data, 0x60))
            let mBefore2 := mload(sub(data, 0x40))
            let mBefore1 := mload(sub(data, 0x20))
            let dataLength := mload(data)
            let dataEnd := add(add(data, 0x20), dataLength)
            let mAfter1 := mload(dataEnd)

            // +2 bytes for telling how much data there is appended to the call.
            let extraLength := add(dataLength, 2)

            // Write the bytecode before the data.
            mstore(data, 0x5af43d3d93803e606057fd5bf3)
            // Write the address of the implementation.
            mstore(sub(data, 0x0d), implementation)
            // Write the rest of the bytecode.
            mstore(
                sub(data, 0x21),
                or(
                    shl(0x48, extraLength),
                    0x593da1005b363d3d373d3d3d3d610000806062363936013d73
                )
            )
            // `keccak256("ReceiveETH(uint256)")`.
            mstore(
                sub(data, 0x3a),
                0x9e4ac34f21c619cefc926c8bd93b54bf5a39c7ab2127a895af1cc0691d7e3dff
            )
            mstore(
                sub(data, 0x5a),
                or(
                    shl(0x78, add(extraLength, 0x62)),
                    0x6100003d81600a3d39f336602c57343d527f
                )
            )
            mstore(dataEnd, shl(0xf0, extraLength))

            // Compute and store the bytecode hash.
            mstore(0x35, keccak256(sub(data, 0x4c), add(extraLength, 0x6c)))
            mstore8(0x00, 0xff) // Write the prefix.
            mstore(0x01, shl(96, deployer))
            mstore(0x15, salt)
            predicted := keccak256(0x00, 0x55)
            // Restore the part of the free memory pointer that has been overwritten.
            mstore(0x35, 0)

            // Restore the overwritten memory surrounding `data`.
            mstore(dataEnd, mAfter1)
            mstore(data, dataLength)
            mstore(sub(data, 0x20), mBefore1)
            mstore(sub(data, 0x40), mBefore2)
            mstore(sub(data, 0x60), mBefore3)
        }
    }
}

/// @notice Keep Factory.
contract KeepFactory is Multicallable {
    /// -----------------------------------------------------------------------
    /// Library Usage
    /// -----------------------------------------------------------------------

    using LibClone for address;

    /// -----------------------------------------------------------------------
    /// Events
    /// -----------------------------------------------------------------------

    event Deployed(
        Keep indexed keep,
        bytes32 name,
        address[] signers,
        uint256 threshold
    );

    /// -----------------------------------------------------------------------
    /// Immutables
    /// -----------------------------------------------------------------------

    Keep internal immutable keepTemplate;

    /// -----------------------------------------------------------------------
    /// Constructor
    /// -----------------------------------------------------------------------

    constructor(Keep _keepTemplate) payable {
        keepTemplate = _keepTemplate;
    }

    /// -----------------------------------------------------------------------
    /// Deployment Logic
    /// -----------------------------------------------------------------------

    function determineKeep(bytes32 name) public view virtual returns (address) {
        return
            address(keepTemplate).predictDeterministicAddress(
                abi.encodePacked(name),
                name,
                address(this)
            );
    }

    function deployKeep(
        bytes32 name, // create2 salt.
        Call[] calldata calls,
        address[] calldata signers,
        uint256 threshold
    ) public payable virtual {
        Keep keep = Keep(
            address(keepTemplate).cloneDeterministic(
                abi.encodePacked(name),
                name
            )
        );

        keep.initialize{value: msg.value}(calls, signers, threshold);

        emit Deployed(keep, name, signers, threshold);
    }
}