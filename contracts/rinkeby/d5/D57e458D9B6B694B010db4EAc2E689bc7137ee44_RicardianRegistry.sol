// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Minimalist and gas efficient ERC1155-like implementation.
/// @dev Modified by KaliCo LLC for Ricardian to remove batching in favour of Multicall.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC1155.sol)
abstract contract ERC1155 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 amount
    );

    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    event URI(string value, uint256 indexed id);

    /*//////////////////////////////////////////////////////////////
                             ERC1155 STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(address => mapping(uint256 => uint256)) public balanceOf;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*//////////////////////////////////////////////////////////////
                             METADATA LOGIC
    //////////////////////////////////////////////////////////////*/

    function uri(uint256 id) public view virtual returns (string memory);

    /*//////////////////////////////////////////////////////////////
                              ERC1155 LOGIC
    //////////////////////////////////////////////////////////////*/

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) public virtual {
        require(
            msg.sender == from || isApprovedForAll[from][msg.sender],
            "NOT_AUTHORIZED"
        );

        balanceOf[from][id] -= amount;
        balanceOf[to][id] += amount;

        emit TransferSingle(msg.sender, from, to, id, amount);

        if (to.code.length != 0) {
            require(
                ERC1155TokenReceiver(to).onERC1155Received(
                    msg.sender,
                    from,
                    id,
                    amount,
                    data
                ) == ERC1155TokenReceiver.onERC1155Received.selector,
                "UNSAFE_RECIPIENT"
            );
        } else require(to != address(0), "INVALID_RECIPIENT");
    }

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
            for (uint256 i = 0; i < owners.length; ++i) {
                balances[i] = balanceOf[owners[i]][ids[i]];
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        returns (bool)
    {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0xd9b67a26 || // ERC165 Interface ID for ERC1155
            interfaceId == 0x0e89341c; // ERC165 Interface ID for ERC1155MetadataURI
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        balanceOf[to][id] += amount;

        emit TransferSingle(msg.sender, address(0), to, id, amount);

        if (to.code.length != 0) {
            require(
                ERC1155TokenReceiver(to).onERC1155Received(
                    msg.sender,
                    address(0),
                    id,
                    amount,
                    data
                ) == ERC1155TokenReceiver.onERC1155Received.selector,
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

        emit TransferSingle(msg.sender, from, address(0), id, amount);
    }
}

/// @notice A generic interface for a contract which properly accepts ERC1155 tokens.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC1155.sol)
abstract contract ERC1155TokenReceiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC1155TokenReceiver.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC1155TokenReceiver.onERC1155BatchReceived.selector;
    }
}

/// @notice A generic interface for a contract which properly accepts ERC1155 tokens.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC1155.sol)
abstract contract ERC1155votes is ERC1155 {
    /// -----------------------------------------------------------------------
    /// Events
    /// -----------------------------------------------------------------------

    event DelegateChanged(
        address indexed delegator,
        uint256 id,
        address indexed fromDelegate,
        address indexed toDelegate
    );

    event DelegateVotesChanged(
        address indexed delegate,
        uint256 id,
        uint256 previousBalance,
        uint256 newBalance
    );

    /// -----------------------------------------------------------------------
    /// Checkpoint Storage
    /// -----------------------------------------------------------------------
     
    mapping(address => mapping(uint256 => address)) private _delegates;

    mapping(address => mapping(uint256 => uint256)) public numCheckpoints;

    mapping(address => mapping(uint256 => mapping(uint256 => Checkpoint))) public checkpoints;
    
    struct Checkpoint {
        uint64 fromTimestamp;
        uint192 votes;
    }

    /// -----------------------------------------------------------------------
    /// Delegation Logic
    /// -----------------------------------------------------------------------

    function delegates(address account, uint256 id) public view returns (address) {
        address current = _delegates[account][id];

        return current == address(0) ? account : current;
    }

    function getCurrentVotes(address account, uint256 id) external view returns (uint256) {
        // this is safe from underflow because decrement only occurs if `nCheckpoints` is positive
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
        external
        view
        returns (uint256)
    {
        require(block.timestamp > timestamp, "UNDETERMINED");

        uint256 nCheckpoints = numCheckpoints[account][id];

        if (nCheckpoints == 0) return 0;

        // this is safe from underflow because decrement only occurs if `nCheckpoints` is positive
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

    function delegate(address account, uint256 id) external payable {
        address currentDelegate = delegates(msg.sender, id);

        _delegates[msg.sender][id] = account;

        _moveDelegates(currentDelegate, account, id, balanceOf[msg.sender][id]);

        emit DelegateChanged(msg.sender, id, currentDelegate, account);
    }

    function _moveDelegates(
        address srcRep,
        address dstRep,
        uint256 id,
        uint256 amount
    ) internal {
        if (srcRep != dstRep && amount != 0) {
            if (srcRep != address(0)) {
                uint256 srcRepNum = numCheckpoints[srcRep][id];

                uint256 srcRepOld = srcRepNum != 0
                    ? checkpoints[srcRep][id][srcRepNum - 1].votes
                    : 0;

                uint256 srcRepNew = srcRepOld - amount;

                _writeCheckpoint(srcRep, id, srcRepNum, srcRepOld, srcRepNew);
            }

            if (dstRep != address(0)) {
                uint256 dstRepNum = numCheckpoints[dstRep][id];

                uint256 dstRepOld = dstRepNum != 0
                    ? checkpoints[dstRep][id][dstRepNum - 1].votes
                    : 0;

                uint256 dstRepNew = dstRepOld + amount;

                _writeCheckpoint(dstRep, id, dstRepNum, dstRepOld, dstRepNew);
            }
        }
    }

    function _writeCheckpoint(
        address delegatee,
        uint256 id,
        uint256 nCheckpoints,
        uint256 oldVotes,
        uint256 newVotes
    ) internal {
        unchecked {
            // this is safe from underflow because decrement only occurs if `nCheckpoints` is positive
            if (
                nCheckpoints != 0 &&
                checkpoints[delegatee][id][nCheckpoints - 1].fromTimestamp ==
                block.timestamp
            ) {
                checkpoints[delegatee][id][nCheckpoints - 1].votes = safeCastTo192(
                    newVotes
                );
            } else {
                checkpoints[delegatee][id][nCheckpoints] = Checkpoint(
                    safeCastTo64(block.timestamp),
                    safeCastTo192(newVotes)
                );

                // cannot realistically overflow
                numCheckpoints[delegatee][id] = nCheckpoints + 1;
            }
        }

        emit DelegateVotesChanged(delegatee, id, oldVotes, newVotes);
    }

    function safeCastTo64(uint256 x) internal pure returns (uint64 y) {
        require(x < 1 << 64);

        y = uint64(x);
    }

    function safeCastTo192(uint256 x) internal pure returns (uint192 y) {
        require(x < 1 << 192);

        y = uint192(x);
    }
}

/// @notice Helper utility that enables calling multiple local methods in a single call.
/// @author Modified from Uniswap (https://github.com/Uniswap/v3-periphery/blob/main/contracts/base/Multicall.sol)
abstract contract Multicall {
    function multicall(bytes[] calldata data)
        external
        returns (bytes[] memory results)
    {
        results = new bytes[](data.length);

        for (uint256 i; i < data.length; ) {
            (bool success, bytes memory result) = address(this).delegatecall(
                data[i]
            );

            if (!success) {
                if (result.length < 68) revert();

                assembly {
                    result := add(result, 0x04)
                }

                revert(abi.decode(result, (string)));
            }

            results[i] = result;

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }
    }
}

/// @title Ricardian
/// @author KaliCo LLC
/// @notice Ricardian contract for on-chain entities.
contract Ricardian is ERC1155votes, Multicall {
    /// -----------------------------------------------------------------------
    /// Events
    /// -----------------------------------------------------------------------

    event OwnerOfSet(address indexed caller, address indexed to, uint256 id);

    event ManagerSet(address indexed caller, address indexed to, bool approval);

    event AdminSet(address indexed caller, address indexed to);

    event TokenPauseSet(address indexed caller, uint256 id, bool pause);

    event TokenPermissionSet(address indexed caller, uint256 id, bool permission);

    event UserPermissionSet(address indexed caller, address indexed to, uint256 id, bool permission);

    event BaseURIset(address indexed caller, string baseURI);

    event UserURISet(address indexed caller, address indexed to, uint256 id, string userURI);

    event MintFeeSet(address indexed caller, uint256 mintFee);

    /// -----------------------------------------------------------------------
    /// Ricardian Storage/Logic
    /// -----------------------------------------------------------------------

    string public name;

    string public symbol;

    string private baseURI;

    uint256 private mintFee;

    address public admin;

    mapping(uint256 => address) public ownerOf;

    mapping(address => bool) public manager;

    mapping(uint256 => bool) public registered;

    mapping(uint256 => bool) public paused;

    mapping(uint256 => bool) public tokenPermissioned;

    mapping(address => mapping(uint256 => bool)) public userPermissioned;

    mapping(uint256 => string) private tokenURIs;

    mapping(address => mapping(uint256 => string)) public userURIs;

    modifier onlyOwnerOf(uint256 id) {
        require(msg.sender == ownerOf[id], "NOT_OWNER");

        _;
    }

    modifier onlyManager() {
        require(manager[msg.sender], "NOT_MANAGER");

        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "NOT_ADMIN");

        _;
    }

    function uri(uint256 id) public view override returns (string memory) {
        if (bytes(tokenURIs[id]).length == 0) return baseURI;
        else return tokenURIs[id];
    }

    /// -----------------------------------------------------------------------
    /// Constructor
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
    /// Public Functions
    /// -----------------------------------------------------------------------

    function mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data,
        string calldata tokenURI,
        address owner
    ) external payable {
        uint256 fee = mintFee;

        if (fee != 0) require(msg.value == fee, "NOT_FEE");

        require(!registered[id], "REGISTERED");

        if (owner != address(0)) {
            ownerOf[id] = owner;

            emit OwnerOfSet(msg.sender, owner, id);
        }

        registered[id] = true;

        __mint(to, id, amount, data, tokenURI);
    }

    function burn(
        address from, 
        uint256 id, 
        uint256 amount
    ) external payable {
        require(
            msg.sender == from || isApprovedForAll[from][msg.sender],
            "NOT_AUTHORIZED"
        );

        __burn(from, id, amount);
    }

    /// -----------------------------------------------------------------------
    /// Management Functions
    /// -----------------------------------------------------------------------

    function manageMint(
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data,
        string calldata tokenURI,
        address owner
    ) external payable {
        require(manager[msg.sender] || msg.sender == admin || msg.sender == ownerOf[id] , "NOT_AUTHORIZED");

        if (!registered[id]) registered[id] = true;

        if (owner != address(0)) {
            ownerOf[id] = owner;

            emit OwnerOfSet(msg.sender, owner, id);
        }

        __mint(to, id, amount, data, tokenURI);
    }

    function manageBurn(
        address from,
        uint256 id,
        uint256 amount
    ) external payable {
        require(manager[msg.sender] || msg.sender == admin || msg.sender == ownerOf[id] , "NOT_AUTHORIZED");

        __burn(from, id, amount);
    }

    /// -----------------------------------------------------------------------
    /// Owner Functions
    /// -----------------------------------------------------------------------

    function setTokenPause(uint256 id, bool pause) external payable {
        require(msg.sender == ownerOf[id] || msg.sender == admin, "NOT_AUTHORIZED");

        paused[id] = pause;

        emit TokenPauseSet(msg.sender, id, pause);
    }

    function setTokenPermission(uint256 id, bool permission) external payable {
        require(msg.sender == ownerOf[id] || msg.sender == admin, "NOT_AUTHORIZED");

        tokenPermissioned[id] = permission;

        emit TokenPermissionSet(msg.sender, id, permission);
    }

    function setUserPermit(
        address to, 
        uint256 id, 
        bool permission
    ) external payable {
        require(msg.sender == ownerOf[id] || msg.sender == admin, "NOT_AUTHORIZED");

        userPermissioned[to][id] = permission;

        emit UserPermissionSet(msg.sender, to, id, permission);
    }

    function setTokenURI(uint256 id, string calldata tokenURI) external payable {
        require(msg.sender == ownerOf[id] || msg.sender == admin, "NOT_AUTHORIZED");

        tokenURIs[id] = tokenURI;

        emit URI(tokenURI, id);
    }

    function setUserURI(
        address to, 
        uint256 id, 
        string calldata userURI
    ) external payable {
        require(msg.sender == ownerOf[id] || msg.sender == admin, "NOT_AUTHORIZED");

        userURIs[to][id] = userURI;

        emit UserURISet(msg.sender, to, id, userURI);
    }

    function setOwnerOf(address to, uint256 id)
        external
        payable
    {
        require(msg.sender == ownerOf[id] || msg.sender == admin, "NOT_AUTHORIZED");

        ownerOf[id] = to;

        emit OwnerOfSet(msg.sender, to, id);
    }

    /// -----------------------------------------------------------------------
    /// Admin Functions
    /// -----------------------------------------------------------------------

    function setManager(address to, bool approval)
        external
        payable
        onlyAdmin
    {
        manager[to] = approval;

        emit ManagerSet(msg.sender, to, approval);
    }

    function setBaseURI(string calldata _baseURI)
        external
        payable
        onlyAdmin
    {
        baseURI = _baseURI;

        emit BaseURIset(msg.sender, _baseURI);
    }

    function setMintFee(uint256 _mintFee) external payable onlyAdmin {
        mintFee = _mintFee;

        emit MintFeeSet(msg.sender, _mintFee);
    }

    function claimFee(address to, uint256 amount)
        external
        payable
        onlyAdmin
    {
        assembly {
            // Transfer the ETH and check if it succeeded or not.
            if iszero(call(gas(), to, amount, 0, 0, 0, 0)) {
                mstore(0x00, hex"08c379a0") // Function selector of the error method.
                mstore(0x04, 0x20) // Offset of the error string.
                mstore(0x24, 19) // Length of the error string.
                mstore(0x44, "ETH_TRANSFER_FAILED") // The error string.
                revert(0x00, 0x64) // Revert with (offset, size).
            }
        }
    }

    function setAdmin(address to) external payable onlyAdmin {
        admin = to;

        emit AdminSet(msg.sender, to);
    }

    /// -----------------------------------------------------------------------
    /// Transfer Functions
    /// -----------------------------------------------------------------------

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) public override {
        require(!paused[id], "LOCKED");

        if (tokenPermissioned[id]) require(userPermissioned[from][id] && userPermissioned[to][id], "NOT_LISTED");

        super.safeTransferFrom(from, to, id, amount, data);
    }

    /// -----------------------------------------------------------------------
    /// Internal Functions
    /// -----------------------------------------------------------------------

    function __mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data,
        string calldata tokenURI
    ) internal {
        _mint(to, id, amount, data);

        _moveDelegates(address(0), delegates(to, id), id, amount);

        if (bytes(tokenURI).length != 0) {
            tokenURIs[id] = tokenURI;

            emit URI(tokenURI, id);
        }
    }

    function __burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal {
        _burn(from, id, amount);

        _moveDelegates(delegates(from, id), address(0), id, amount);
    }
}

/// @title Ricardian Registry
/// @author KaliCo LLC
/// @notice Factory to deploy Ricardian contracts.
contract RicardianRegistry is Multicall {
    event RicardianRegistered(
        address indexed ricardian, 
        string name, 
        string symbol, 
        string baseURI, 
        uint256 mintFee, 
        address owner
    );

    function registerRicardian(
        string calldata _name,
        string calldata _symbol,
        string calldata _baseURI,
        uint256 _mintFee,
        address _owner
    ) external payable {
        address ricardian = address(
            new Ricardian{salt: keccak256(bytes(_name))}(
                _name,
                _symbol,
                _baseURI,
                _mintFee,
                _owner
            )
        );

        emit RicardianRegistered(
            ricardian, 
            _name, 
            _symbol, 
            _baseURI, 
            _mintFee, 
            _owner
        );
    }
}