/**
 *Submitted for verification at Etherscan.io on 2022-08-22
*/

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.4;

/// @notice A generic interface for a contract which properly accepts ERC-1155 tokens.
/// @author Modified from Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC1155.sol)
abstract contract ERC1155TokenReceiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external payable virtual returns (bytes4) {
        return ERC1155TokenReceiver.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external payable virtual returns (bytes4) {
        return ERC1155TokenReceiver.onERC1155BatchReceived.selector;
    }
}

/// @notice Minimalist and gas efficient standard ERC-1155 implementation with supply tracking.
/// @author Modified from Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC1155.sol)
abstract contract ERC1155 {
    /// -----------------------------------------------------------------------
    /// EVENTS
    /// -----------------------------------------------------------------------

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

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    event URI(string value, uint256 indexed id);

    /// -----------------------------------------------------------------------
    /// ERC-1155 STORAGE
    /// -----------------------------------------------------------------------
    
    mapping(uint256 => uint256) public totalSupply;

    mapping(address => mapping(uint256 => uint256)) public balanceOf;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /// -----------------------------------------------------------------------
    /// METADATA LOGIC
    /// -----------------------------------------------------------------------

    function uri(uint256 id) public view virtual returns (string memory);
    
    /// -----------------------------------------------------------------------
    /// ERC-165 LOGIC
    /// -----------------------------------------------------------------------

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC-165 Interface ID for ERC-165
            interfaceId == 0xd9b67a26 || // ERC-165 Interface ID for ERC-1155
            interfaceId == 0x0e89341c; // ERC-165 Interface ID for ERC1155MetadataURI
    }

    /// -----------------------------------------------------------------------
    /// ERC-1155 LOGIC
    /// -----------------------------------------------------------------------
    
    function balanceOfBatch(address[] calldata owners, uint256[] calldata ids)
        public
        view
        virtual
        returns (uint256[] memory balances)
    {
        require(owners.length == ids.length, "LENGTH_MISMATCH");

        balances = new uint256[](owners.length);

        // Unchecked because the only math done is incrementing
        // the array index counter which cannot possibly overflow.
        unchecked {
            for (uint256 i; i < owners.length; ++i) {
                balances[i] = balanceOf[owners[i]][ids[i]];
            }
        }
    }

    function setApprovalForAll(address operator, bool approved) public payable virtual {
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
        require(msg.sender == from || isApprovedForAll[from][msg.sender], "NOT_AUTHORIZED");

        balanceOf[from][id] -= amount;
        
        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to][id] += amount;
        }

        emit TransferSingle(msg.sender, from, to, id, amount);

        if (to.code.length != 0) {
            require(
                ERC1155TokenReceiver(to).onERC1155Received(msg.sender, from, id, amount, data) ==
                    ERC1155TokenReceiver.onERC1155Received.selector,
                "UNSAFE_RECIPIENT"
            );
        } else require(to != address(0), "INVALID_RECIPIENT");
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) public payable virtual {
        require(ids.length == amounts.length, "LENGTH_MISMATCH");

        require(msg.sender == from || isApprovedForAll[from][msg.sender], "NOT_AUTHORIZED");

        // Storing these outside the loop saves ~15 gas per iteration.
        uint256 id;
        uint256 amount;

        for (uint256 i; i < ids.length; ) {
            id = ids[i];
            amount = amounts[i];

            balanceOf[from][id] -= amount;
            
            // Cannot overflow because the sum of all user
            // balances can't exceed the max uint256 value,
            // and an array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                balanceOf[to][id] += amount;
                
                ++i;
            }
        }

        emit TransferBatch(msg.sender, from, to, ids, amounts);

        if (to.code.length != 0) {
            require(
                ERC1155TokenReceiver(to).onERC1155BatchReceived(msg.sender, from, ids, amounts, data) ==
                    ERC1155TokenReceiver.onERC1155BatchReceived.selector,
                "UNSAFE_RECIPIENT"
            );
        } else require(to != address(0), "INVALID_RECIPIENT");
    }

    /// -----------------------------------------------------------------------
    /// INTERNAL MINT/BURN LOGIC
    /// -----------------------------------------------------------------------

    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) internal virtual {
        totalSupply[id] += amount;
        
        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value. 
        unchecked {
            balanceOf[to][id] += amount;
        }

        emit TransferSingle(msg.sender, address(0), to, id, amount);

        if (to.code.length != 0) {
            require(
                ERC1155TokenReceiver(to).onERC1155Received(msg.sender, address(0), id, amount, data) ==
                    ERC1155TokenReceiver.onERC1155Received.selector,
                "UNSAFE_RECIPIENT"
            );
        } else require(to != address(0), "INVALID_RECIPIENT");
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
    }
}

/// @notice Compound-like voting extension for ERC-1155.
/// @author KaliCo LLC
/// @custom:coauthor Seed Club Ventures (@seedclubvc)
abstract contract ERC1155Votes is ERC1155 {
    /// -----------------------------------------------------------------------
    /// EVENTS
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

    /// -----------------------------------------------------------------------
    /// VOTING STORAGE
    /// -----------------------------------------------------------------------
     
    mapping(address => mapping(uint256 => address)) internal _delegates;

    mapping(address => mapping(uint256 => uint256)) public numCheckpoints;

    mapping(address => mapping(uint256 => mapping(uint256 => Checkpoint))) public checkpoints;
    
    struct Checkpoint {
        uint40 fromTimestamp;
        uint216 votes;
    }

    /// -----------------------------------------------------------------------
    /// DELEGATION LOGIC
    /// -----------------------------------------------------------------------

    function delegates(address account, uint256 id) public view virtual returns (address) {
        address current = _delegates[account][id];

        return current == address(0) ? account : current;
    }

    function getCurrentVotes(address account, uint256 id) public view virtual returns (uint256) {
        // Won't underflow because decrement only occurs if positive `nCheckpoints`.
        unchecked {
            uint256 nCheckpoints = numCheckpoints[account][id];

            return
                nCheckpoints != 0
                    ? checkpoints[account][id][nCheckpoints - 1].votes
                    : 0;
        }
    }

    function getPriorVotes(
        address account, 
        uint256 id,
        uint256 timestamp
    )
        public
        view
        virtual
        returns (uint256)
    {
        require(block.timestamp > timestamp, "UNDETERMINED");

        uint256 nCheckpoints = numCheckpoints[account][id];

        if (nCheckpoints == 0) return 0;

        // Won't underflow because decrement only occurs if positive `nCheckpoints`.
        unchecked {
            if (
                checkpoints[account][id][nCheckpoints - 1].fromTimestamp <=
                timestamp
            ) return checkpoints[account][id][nCheckpoints - 1].votes;

            if (checkpoints[account][id][0].fromTimestamp > timestamp) return 0;

            uint256 lower;

            uint256 upper = nCheckpoints - 1;

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

    function delegate(address delegatee, uint256 id) public payable virtual {
        address currentDelegate = delegates(msg.sender, id);

        _delegates[msg.sender][id] = delegatee;

        emit DelegateChanged(msg.sender, currentDelegate, delegatee, id);

        _moveDelegates(currentDelegate, delegatee, id, balanceOf[msg.sender][id]);
    }

    function _moveDelegates(
        address srcRep,
        address dstRep,
        uint256 id,
        uint256 amount
    ) internal virtual {
        if (srcRep != dstRep && amount != 0) {
            if (srcRep != address(0)) {
                uint256 srcRepNum = numCheckpoints[srcRep][id];

                uint256 srcRepOld;

                // Won't underflow because decrement only occurs if positive `srcRepNum`.
                unchecked {
                    srcRepOld = srcRepNum != 0
                        ? checkpoints[srcRep][id][srcRepNum - 1].votes
                        : 0;
                }

                _writeCheckpoint(srcRep, id, srcRepNum, srcRepOld, srcRepOld - amount);
            }

            if (dstRep != address(0)) {
                uint256 dstRepNum = numCheckpoints[dstRep][id];
                
                uint256 dstRepOld;

                // Won't underflow because decrement only occurs if positive `dstRepNum`.
                unchecked {
                    dstRepOld = dstRepNum != 0
                        ? checkpoints[dstRep][id][dstRepNum - 1].votes
                        : 0;
                }
                    
                _writeCheckpoint(dstRep, id, dstRepNum, dstRepOld, dstRepOld + amount);
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
        // Won't underflow because decrement only occurs if positive `nCheckpoints`.
        unchecked {
            if (
                nCheckpoints != 0 &&
                checkpoints[delegatee][id][nCheckpoints - 1].fromTimestamp ==
                block.timestamp
            ) {
                checkpoints[delegatee][id][nCheckpoints - 1].votes = _safeCastTo216(
                    newVotes
                );
            } else {
                checkpoints[delegatee][id][nCheckpoints] = Checkpoint(
                    _safeCastTo40(block.timestamp),
                    _safeCastTo216(newVotes)
                );

                // Won't realistically overflow.
                ++numCheckpoints[delegatee][id];
            }
        }

        emit DelegateVotesChanged(delegatee, id, oldVotes, newVotes);
    }

    function _safeCastTo40(uint256 x) internal pure virtual returns (uint40 y) {
        require(x < 1 << 40);

        y = uint40(x);
    }

    function _safeCastTo216(uint256 x) internal pure virtual returns (uint216 y) {
        require(x < 1 << 216);

        y = uint216(x);
    }
}

/// @notice Contract that enables a single call to call multiple methods on itself.
/// @author Modified from Solady (https://github.com/vectorized/solady/blob/main/src/utils/Multicallable.sol)
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/Multicallable.sol)
abstract contract Multicallable {
    function multicall(bytes[] calldata data) public returns (bytes[] memory results) {
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

/// @title Wrappr
/// @author KaliCo LLC
/// @custom:coauthor Seed Club Ventures (@seedclubvc)
/// @notice Ricardian contract for on-chain structures.
contract Wrappr is ERC1155Votes, Multicallable {
    /// -----------------------------------------------------------------------
    /// EVENTS
    /// -----------------------------------------------------------------------

    event OwnerOfSet(address indexed operator, address indexed to, uint256 id);

    event ManagerSet(address indexed operator, address indexed to, bool set);

    event AdminSet(address indexed operator, address indexed admin);

    event TransferabilitySet(address indexed operator, uint256 id, bool set);

    event PermissionSet(address indexed operator, uint256 id, bool set);

    event UserPermissionSet(address indexed operator, address indexed to, uint256 id, bool set);

    event BaseURIset(address indexed operator, string baseURI);

    event UserURIset(address indexed operator, address indexed to, uint256 id, string uuri);

    event MintFeeSet(address indexed operator, uint256 mintFee);

    /// -----------------------------------------------------------------------
    /// WRAPPR STORAGE/LOGIC
    /// -----------------------------------------------------------------------

    string public name;

    string public symbol;

    string internal baseURI;

    uint256 internal mintFee;

    address public admin;

    mapping(uint256 => address) public ownerOf;

    mapping(address => bool) public manager;

    mapping(uint256 => bool) internal registered;

    mapping(uint256 => bool) public transferable;

    mapping(uint256 => bool) public permissioned;

    mapping(address => mapping(uint256 => bool)) public userPermissioned;

    mapping(uint256 => string) internal uris;

    mapping(address => mapping(uint256 => string)) public userURI;

    modifier onlyAdmin() virtual {
        require(msg.sender == admin, "NOT_ADMIN");

        _;
    }

    modifier onlyOwnerOfOrAdmin(uint256 id) virtual {
        require(msg.sender == ownerOf[id] || msg.sender == admin, "NOT_AUTHORIZED");

        _;
    }

    function uri(uint256 id) public view override virtual returns (string memory) {
        string memory tokenURI = uris[id];

        if (bytes(tokenURI).length == 0) return baseURI;
        else return tokenURI;
    }

    /// -----------------------------------------------------------------------
    /// CONSTRUCTOR
    /// -----------------------------------------------------------------------

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _baseURI,
        uint256 _mintFee,
        address _admin
    ) payable {
        name = _name;

        symbol = _symbol;

        baseURI = _baseURI;

        mintFee = _mintFee;

        admin = _admin;

        emit BaseURIset(address(0), _baseURI);

        emit MintFeeSet(address(0), _mintFee);

        emit AdminSet(address(0), _admin);
    }

    /// -----------------------------------------------------------------------
    /// PUBLIC FUNCTIONS
    /// -----------------------------------------------------------------------

    function mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data,
        string calldata tokenURI,
        address owner
    ) public payable virtual {
        uint256 fee = mintFee;

        if (fee != 0) require(msg.value == fee, "NOT_FEE");

        require(!registered[id], "REGISTERED");

        if (owner != address(0)) {
            ownerOf[id] = owner;

            emit OwnerOfSet(address(0), owner, id);
        }

        registered[id] = true;

        __mint(to, id, amount, data, tokenURI);
    }

    function burn(
        address from, 
        uint256 id, 
        uint256 amount
    ) public payable virtual {
        require(
            msg.sender == from || isApprovedForAll[from][msg.sender],
            "NOT_AUTHORIZED"
        );

        __burn(from, id, amount);
    }

    /// -----------------------------------------------------------------------
    /// MANAGEMENT FUNCTIONS
    /// -----------------------------------------------------------------------

    function manageMint(
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data,
        string calldata tokenURI,
        address owner
    ) public payable virtual {
        address _owner = ownerOf[id];

        require(msg.sender == _owner || manager[msg.sender] || msg.sender == admin, "NOT_AUTHORIZED");

        if (!registered[id]) registered[id] = true;
        
        if (_owner == address(0) && (ownerOf[id] = owner) != address(0)) {
            emit OwnerOfSet(address(0), owner, id);
        }

        __mint(to, id, amount, data, tokenURI);
    }

    function manageBurn(
        address from,
        uint256 id,
        uint256 amount
    ) public payable virtual {
        require(msg.sender == ownerOf[id] || manager[msg.sender] || msg.sender == admin, "NOT_AUTHORIZED");

        __burn(from, id, amount);
    }

    /// -----------------------------------------------------------------------
    /// OWNER FUNCTIONS
    /// -----------------------------------------------------------------------
    
    function setOwnerOf(address to, uint256 id)
        public
        payable
        onlyOwnerOfOrAdmin(id)
        virtual
    {
        ownerOf[id] = to;

        emit OwnerOfSet(msg.sender, to, id);
    }

    function setTransferability(uint256 id, bool set) public payable onlyOwnerOfOrAdmin(id) virtual {
        transferable[id] = set;

        emit TransferabilitySet(msg.sender, id, set);
    }

    function setPermission(uint256 id, bool set) public payable onlyOwnerOfOrAdmin(id) virtual {
        permissioned[id] = set;

        emit PermissionSet(msg.sender, id, set);
    }

    function setUserPermission(
        address to, 
        uint256 id, 
        bool set
    ) public payable onlyOwnerOfOrAdmin(id) virtual {
        userPermissioned[to][id] = set;

        emit UserPermissionSet(msg.sender, to, id, set);
    }

    function setURI(uint256 id, string calldata tokenURI) public payable onlyOwnerOfOrAdmin(id) virtual {
        uris[id] = tokenURI;

        emit URI(tokenURI, id);
    }

    function setUserURI(
        address to, 
        uint256 id, 
        string calldata uuri
    ) public payable onlyOwnerOfOrAdmin(id) virtual {
        userURI[to][id] = uuri;

        emit UserURIset(msg.sender, to, id, uuri);
    }

    /// -----------------------------------------------------------------------
    /// ADMIN FUNCTIONS
    /// -----------------------------------------------------------------------

    function setManager(address to, bool set)
        public
        payable
        onlyAdmin
        virtual
    {
        manager[to] = set;

        emit ManagerSet(msg.sender, to, set);
    }
    
    function setAdmin(address _admin) public payable onlyAdmin virtual {
        admin = _admin;

        emit AdminSet(msg.sender, _admin);
    }

    function setBaseURI(string calldata _baseURI)
        public
        payable
        onlyAdmin
        virtual
    {
        baseURI = _baseURI;

        emit BaseURIset(msg.sender, _baseURI);
    }

    function setMintFee(uint256 _mintFee) public payable onlyAdmin virtual {
        mintFee = _mintFee;

        emit MintFeeSet(msg.sender, _mintFee);
    }

    function claimFee(address to, uint256 amount)
        public
        payable
        onlyAdmin
        virtual
    {
        assembly {
            if iszero(call(gas(), to, amount, 0, 0, 0, 0)) {
                mstore(0x00, hex"08c379a0") // Function selector of the error method.
                mstore(0x04, 0x20) // Offset of the error string.
                mstore(0x24, 19) // Length of the error string.
                mstore(0x44, "ETH_TRANSFER_FAILED") // The error string.
                revert(0x00, 0x64) // Revert with (offset, size).
            }
        }
    }

    /// -----------------------------------------------------------------------
    /// TRANSFER FUNCTIONS
    /// -----------------------------------------------------------------------

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) public payable override virtual {
        super.safeTransferFrom(from, to, id, amount, data);

        require(transferable[id], "NONTRANSFERABLE");

        if (permissioned[id]) require(userPermissioned[from][id] && userPermissioned[to][id], "NOT_PERMITTED");

        _moveDelegates(delegates(from, id), delegates(to, id), id, amount);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) public payable override virtual {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);

        // Storing these outside the loop saves ~15 gas per iteration.
        uint256 id;
        uint256 amount;

        for (uint256 i; i < ids.length; ) {
            id = ids[i];
            amount = amounts[i];

            require(transferable[id], "NONTRANSFERABLE");

            if (permissioned[id]) require(userPermissioned[from][id] && userPermissioned[to][id], "NOT_PERMITTED");

            _moveDelegates(delegates(from, id), delegates(to, id), id, amount);

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }
    }

    /// -----------------------------------------------------------------------
    /// INTERNAL FUNCTIONS
    /// -----------------------------------------------------------------------

    function __mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data,
        string calldata tokenURI
    ) internal virtual {
        _mint(to, id, amount, data);

        _safeCastTo216(totalSupply[id]);

        _moveDelegates(address(0), delegates(to, id), id, amount);

        if (bytes(tokenURI).length != 0) {
            uris[id] = tokenURI;

            emit URI(tokenURI, id);
        }
    }

    function __burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        _burn(from, id, amount);

        _moveDelegates(delegates(from, id), address(0), id, amount);
    }
}