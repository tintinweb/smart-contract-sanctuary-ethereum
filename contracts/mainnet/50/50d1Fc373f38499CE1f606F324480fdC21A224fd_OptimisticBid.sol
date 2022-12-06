// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

/// @dev Initialization call information
struct InitInfo {
    // Address of target contract
    address target;
    // Initialization data
    bytes data;
    // Merkle proof for call
    bytes32[] proof;
}

/// @dev Interface for Vault proxy contract
interface IVault {
    /// @dev Emitted when execution reverted with no reason
    error ExecutionReverted();
    /// @dev Emitted when the caller is not the owner
    error NotAuthorized(address _caller, address _target, bytes4 _selector);
    /// @dev Emitted when the caller is not the owner
    error NotOwner(address _owner, address _caller);
    /// @dev Emitted when the caller is not the factory
    error NotFactory(address _factory, address _caller);
    /// @dev Emitted when passing an EOA or an undeployed contract as the target
    error TargetInvalid(address _target);

    /// @dev Event log for executing transactions
    /// @param _target Address of target contract
    /// @param _data Transaction data being executed
    /// @param _response Return data of delegatecall
    event Execute(address indexed _target, bytes _data, bytes _response);

    function execute(
        address _target,
        bytes memory _data,
        bytes32[] memory _proof
    ) external payable returns (bool success, bytes memory response);

    function MERKLE_ROOT() external view returns (bytes32);

    function OWNER() external view returns (address);

    function FACTORY() external view returns (address);
}

/// @dev Vault permissions
struct Permission {
    // Address of module contract
    address module;
    // Address of target contract
    address target;
    // Function selector from target contract
    bytes4 selector;
}

/// @dev Vault information
struct VaultInfo {
    // Address of Rae token contract
    address token;
    // ID of the token type
    uint256 id;
}

/// @dev Interface for VaultRegistry contract
interface IVaultRegistry {
    /// @dev Emitted when the caller is not the controller
    error InvalidController(address _controller, address _sender);
    /// @dev Emitted when the caller is not a registered vault
    error UnregisteredVault(address _sender);

    /// @dev Event log for deploying vault
    /// @param _vault Address of the vault
    /// @param _token Address of the token
    /// @param _id Id of the token
    event VaultDeployed(address indexed _vault, address indexed _token, uint256 indexed _id);

    function createFor(
        bytes32 _merkleRoot,
        address _owner,
        InitInfo[] calldata _calls
    ) external returns (address vault);

    function createFor(bytes32 _merkleRoot, address _owner) external returns (address vault);

    function create(bytes32 _merkleRoot, InitInfo[] calldata _calls)
        external
        returns (address vault);

    function create(bytes32 _merkleRoot) external returns (address vault);

    function createCollectionFor(
        bytes32 _merkleRoot,
        address _controller,
        InitInfo[] calldata _calls
    ) external returns (address vault, address token);

    function createCollection(bytes32 _merkleRoot, InitInfo[] calldata _calls)
        external
        returns (address vault, address token);

    function createInCollection(
        bytes32 _merkleRoot,
        address _token,
        InitInfo[] calldata _calls
    ) external returns (address vault);

    function factory() external view returns (address);

    function rae() external view returns (address);

    function raeImplementation() external view returns (address);

    function burn(address _from, uint256 _value) external;

    function mint(address _to, uint256 _value) external;

    function nextId(address) external view returns (uint256);

    function totalSupply(address _vault) external view returns (uint256);

    function uri(address _vault) external view returns (string memory);

    function vaultToToken(address) external view returns (address token, uint256 id);
}

/// @dev Interface for generic Module contract
interface IModule {
    function getLeaves() external view returns (bytes32[] memory leaves);

    function getUnhashedLeaves() external view returns (bytes[] memory leaves);

    function getPermissions() external view returns (Permission[] memory permissions);
}

/// @title Module
/// @author Tessera
/// @notice Base module contract for converting vault permissions into leaf nodes
contract Module is IModule {
    /// @notice Gets the list of hashed leaf nodes used to generate a merkle tree
    /// @dev Leaf nodes are hashed permissions of the merkle tree
    /// @return leaves Hashed leaf nodes
    function getLeaves() external view returns (bytes32[] memory leaves) {
        Permission[] memory permissions = getPermissions();
        uint256 length = permissions.length;
        leaves = new bytes32[](length);
        unchecked {
            for (uint256 i; i < length; ++i) {
                leaves[i] = keccak256(abi.encode(permissions[i]));
            }
        }
    }

    /// @notice Gets the list of unhashed leaf nodes used to generate a merkle tree
    /// @dev Only used for third party APIs (Lanyard) that require unhashed leaves
    /// @return leaves Unhashed leaf nodes
    function getUnhashedLeaves() external view returns (bytes[] memory leaves) {
        Permission[] memory permissions = getPermissions();
        uint256 length = permissions.length;
        leaves = new bytes[](length);
        unchecked {
            for (uint256 i; i < length; ++i) {
                leaves[i] = abi.encode(permissions[i]);
            }
        }
    }

    /// @notice Gets the list of permissions installed on a vault
    /// @dev Intentionally left empty to be overridden by the module inheriting from this contract
    /// @return permissions List of vault permissions
    function getPermissions() public view virtual returns (Permission[] memory permissions) {}
}

/// @title Multicall
/// @author Modified from Uniswap (https://github.com/Uniswap/v3-periphery/blob/main/contracts/base/Multicall.sol)
/// @notice Utility contract that enables calling multiple local methods in a single call
abstract contract Multicall {
    /// @notice Allows multiple function calls within a contract that inherits from it
    /// @param _data List of encoded function calls to make in this contract
    /// @return results List of return responses for each encoded call passed
    function multicall(bytes[] calldata _data) external returns (bytes[] memory results) {
        uint256 length = _data.length;
        results = new bytes[](length);

        bool success;
        for (uint256 i; i < length; ) {
            bytes memory result;
            (success, result) = address(this).delegatecall(_data[i]);
            if (!success) {
                if (result.length == 0) revert();
                // If there is return data and the call wasn't successful, the call reverted with a reason or a custom error.
                _revertedWithReason(result);
            }

            results[i] = result;

            // cannot realistically overflow on human timescales
            unchecked {
                ++i;
            }
        }
    }

    /// @notice Handles function for revert responses
    /// @param _response Reverted return response from a delegate call
    function _revertedWithReason(bytes memory _response) internal pure {
        assembly {
            let returndata_size := mload(_response)
            revert(add(32, _response), returndata_size)
        }
    }
}

/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    event Approval(address indexed owner, address indexed spender, uint256 indexed id);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /*//////////////////////////////////////////////////////////////
                         METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    function tokenURI(uint256 id) public view virtual returns (string memory);

    /*//////////////////////////////////////////////////////////////
                      ERC721 BALANCE/OWNER STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) internal _ownerOf;

    mapping(address => uint256) internal _balanceOf;

    function ownerOf(uint256 id) public view virtual returns (address owner) {
        require((owner = _ownerOf[id]) != address(0), "NOT_MINTED");
    }

    function balanceOf(address owner) public view virtual returns (uint256) {
        require(owner != address(0), "ZERO_ADDRESS");

        return _balanceOf[owner];
    }

    /*//////////////////////////////////////////////////////////////
                         ERC721 APPROVAL STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) public getApproved;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    /*//////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 id) public virtual {
        address owner = _ownerOf[id];

        require(msg.sender == owner || isApprovedForAll[owner][msg.sender], "NOT_AUTHORIZED");

        getApproved[id] = spender;

        emit Approval(owner, spender, id);
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        require(from == _ownerOf[id], "WRONG_FROM");

        require(to != address(0), "INVALID_RECIPIENT");

        require(
            msg.sender == from || isApprovedForAll[from][msg.sender] || msg.sender == getApproved[id],
            "NOT_AUTHORIZED"
        );

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            _balanceOf[from]--;

            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        delete getApproved[id];

        emit Transfer(from, to, id);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes calldata data
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 id) internal virtual {
        require(to != address(0), "INVALID_RECIPIENT");

        require(_ownerOf[id] == address(0), "ALREADY_MINTED");

        // Counter overflow is incredibly unrealistic.
        unchecked {
            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        emit Transfer(address(0), to, id);
    }

    function _burn(uint256 id) internal virtual {
        address owner = _ownerOf[id];

        require(owner != address(0), "NOT_MINTED");

        // Ownership check above ensures no underflow.
        unchecked {
            _balanceOf[owner]--;
        }

        delete _ownerOf[id];

        delete getApproved[id];

        emit Transfer(owner, address(0), id);
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL SAFE MINT LOGIC
    //////////////////////////////////////////////////////////////*/

    function _safeMint(address to, uint256 id) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _safeMint(
        address to,
        uint256 id,
        bytes memory data
    ) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }
}

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721TokenReceiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC721TokenReceiver.onERC721Received.selector;
    }
}

/// @notice Minimalist and gas efficient standard ERC1155 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC1155.sol)
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

    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] amounts
    );

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

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
        require(msg.sender == from || isApprovedForAll[from][msg.sender], "NOT_AUTHORIZED");

        balanceOf[from][id] -= amount;
        balanceOf[to][id] += amount;

        emit TransferSingle(msg.sender, from, to, id, amount);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155Received(msg.sender, from, id, amount, data) ==
                    ERC1155TokenReceiver.onERC1155Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) public virtual {
        require(ids.length == amounts.length, "LENGTH_MISMATCH");

        require(msg.sender == from || isApprovedForAll[from][msg.sender], "NOT_AUTHORIZED");

        // Storing these outside the loop saves ~15 gas per iteration.
        uint256 id;
        uint256 amount;

        for (uint256 i = 0; i < ids.length; ) {
            id = ids[i];
            amount = amounts[i];

            balanceOf[from][id] -= amount;
            balanceOf[to][id] += amount;

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, from, to, ids, amounts);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155BatchReceived(msg.sender, from, ids, amounts, data) ==
                    ERC1155TokenReceiver.onERC1155BatchReceived.selector,
            "UNSAFE_RECIPIENT"
        );
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

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
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

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155Received(msg.sender, address(0), id, amount, data) ==
                    ERC1155TokenReceiver.onERC1155Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _batchMint(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        uint256 idsLength = ids.length; // Saves MLOADs.

        require(idsLength == amounts.length, "LENGTH_MISMATCH");

        for (uint256 i = 0; i < idsLength; ) {
            balanceOf[to][ids[i]] += amounts[i];

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, address(0), to, ids, amounts);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155BatchReceived(msg.sender, address(0), ids, amounts, data) ==
                    ERC1155TokenReceiver.onERC1155BatchReceived.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _batchBurn(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        uint256 idsLength = ids.length; // Saves MLOADs.

        require(idsLength == amounts.length, "LENGTH_MISMATCH");

        for (uint256 i = 0; i < idsLength; ) {
            balanceOf[from][ids[i]] -= amounts[i];

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, from, address(0), ids, amounts);
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
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC1155.sol)
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

/// @title NFT Receiver
/// @author Tessera
/// @notice Plugin contract for handling receipts of non-fungible tokens
contract NFTReceiver is ERC721TokenReceiver, ERC1155TokenReceiver {
    /// @notice Handles the receipt of a single ERC721 token
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external virtual override returns (bytes4) {
        return ERC721TokenReceiver.onERC721Received.selector;
    }

    /// @notice Handles the receipt of a single ERC1155 token type
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external virtual override returns (bytes4) {
        return ERC1155TokenReceiver.onERC1155Received.selector;
    }

    /// @notice Handles the receipt of multiple ERC1155 token types
    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external virtual override returns (bytes4) {
        return ERC1155TokenReceiver.onERC1155BatchReceived.selector;
    }
}

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

/// @notice Minimalist and modern Wrapped Ether implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/WETH.sol)
/// @author Inspired by WETH9 (https://github.com/dapphub/ds-weth/blob/master/src/weth9.sol)
contract WETH is ERC20("Wrapped Ether", "WETH", 18) {
    using SafeTransferLib for address;

    event Deposit(address indexed from, uint256 amount);

    event Withdrawal(address indexed to, uint256 amount);

    function deposit() public payable virtual {
        _mint(msg.sender, msg.value);

        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint256 amount) public virtual {
        _burn(msg.sender, amount);

        emit Withdrawal(msg.sender, amount);

        msg.sender.safeTransferETH(amount);
    }

    receive() external payable virtual {
        deposit();
    }
}

/// @title SafeSend
/// @author Tessera
/// @notice Utility contract for sending Ether or WETH value to an address
abstract contract SafeSend {
    /// @notice Address for WETH contract on network
    /// mainnet: 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address payable public immutable WETH_ADDRESS;

    constructor(address payable _weth) {
        WETH_ADDRESS = _weth;
    }

    /// @notice Attempts to send ether to an address
    /// @param _to Address attemping to send to
    /// @param _value Amount to send
    /// @return success Status of transfer
    function _attemptETHTransfer(address _to, uint256 _value) internal returns (bool success) {
        // Here increase the gas limit a reasonable amount above the default, and try
        // to send ETH to the recipient.
        // NOTE: This might allow the recipient to attempt a limited reentrancy attack.
        (success, ) = _to.call{value: _value, gas: 30000}("");
    }

    /// @notice Sends eth or weth to an address
    /// @param _to Address to send to
    /// @param _value Amount to send
    function _sendEthOrWeth(address _to, uint256 _value) internal {
        if (!_attemptETHTransfer(_to, _value)) {
            WETH(WETH_ADDRESS).deposit{value: _value}();
            WETH(WETH_ADDRESS).transfer(_to, _value);
        }
    }
}

/// @dev Possible states that a buyout auction may have
enum State {
    INACTIVE,
    LIVE,
    SUCCESS
}

/// @dev Auction information
struct Auction {
    // Time of when buyout begins
    uint256 startTime;
    // Address of proposer creating buyout
    address proposer;
    // Enum state of the buyout auction
    State state;
    // Price of rae tokens
    uint256 raePrice;
    // Balance of ether in buyout pool
    uint256 ethBalance;
    // Balance of ether in buyout pool
    uint256 raeBalance;
    // Total supply recorded before a buyout started
    uint256 totalSupply;
}

/// @dev Interface for Buyout module contract
interface IOptimisticBid {
    /// @dev Emitted when you don't have auth to make a call
    error NoAuth();
    /// @dev Emitted when the payment amount does not equal the rae price
    error InvalidPayment();
    /// @dev Emitted when the buyout state is invalid
    error InvalidState(State _required, State _current);
    /// @dev Emitted when the caller has no balance of rae tokens
    error NoRaes();
    /// @dev Emitted when the address is not a registered vault
    error NotVault(address _vault);
    /// @dev Emitted when the time has expired for selling and buying raes
    error TimeExpired(uint256 _current, uint256 _deadline);
    /// @dev Emitted when the buyout auction is still active
    error TimeNotElapsed(uint256 _current, uint256 _deadline);
    /// @dev Emitted when raes used to start a buyout is the totalSupply
    error DepositNotLessThanSupply();
    /// @dev Emitted when raes used to start a buyout are 0
    error ZeroDeposit();
    /// @dev Emitted when a user attemps an actiobn restricted to a certain proposer
    error NotProposer(address _proposer, address _caller);

    /// @dev Event log for starting a buyout
    /// @param _vault Address of the vault
    /// @param _proposer Address that created the buyout
    /// @param _auctionId the auction id used to track the buyoutInfo
    /// @param _buyoutPrice the Price being offered to buyout the vault
    /// @param _auction The info for the buyout struct
    event Start(
        address indexed _vault,
        address indexed _proposer,
        uint256 indexed _auctionId,
        uint256 _buyoutPrice,
        Auction _auction
    );
    /// @dev Event log for buying rae tokens from the buyout pool
    /// @param _vault Address of vault raes control
    /// @param _buyer Address buying raes
    /// @param _auctionId the auction id used to track the buyoutInfo
    /// @param _amount Transfer amount being bought
    event BuyRaes(
        address indexed _vault,
        address indexed _buyer,
        uint256 indexed _auctionId,
        uint256 _amount
    );
    /// @dev Event log for ending an active buyout
    /// @param _vault Address of the vault
    /// @param _state Enum state of auction
    /// @param _proposer Address that created the buyout
    /// @param _auctionId the auction id used to track the buyoutInfo
    event End(
        address indexed _vault,
        State _state,
        address indexed _proposer,
        uint256 indexed _auctionId
    );
    /// @dev Event log for cashing out ether for raes from a successful buyout
    /// @param _vault Address of the vault
    /// @param _casher Address cashing out of buyout
    /// @param _raes Number of raes being burned on cash
    /// @param _amount Transfer amount of ether
    event Cash(address indexed _vault, address indexed _casher, uint256 _raes, uint256 _amount);
    /// @dev Event log for redeeming the underlying vault assets from an inactive buyout
    /// @param _vault Address of the vault
    /// @param _redeemer Address redeeming underlying assets
    event Redeem(address indexed _vault, address indexed _redeemer);

    event WithdrawERC20(
        address indexed _vault,
        address indexed _token,
        uint256 indexed _auctionId,
        address _recipient,
        uint256 _amount
    );

    event WithdrawERC721(
        address indexed _vault,
        address indexed _token,
        uint256 indexed _auctionId,
        address _recipient,
        uint256 _tokenId
    );

    event WithdrawERC1155(
        address indexed _vault,
        address indexed _token,
        uint256 indexed _auctionId,
        address _recipient,
        uint256 _tokenId,
        uint256 _amount
    );

    event BatchWithdrawERC1155(
        address indexed _vault,
        address indexed _token,
        uint256 indexed _auctionId,
        address _recipient,
        uint256[] _tokenIds,
        uint256[] _amounts
    );

    function REJECTION_PERIOD() external view returns (uint256);

    function batchWithdrawERC1155(
        address _vault,
        address _token,
        address _to,
        uint256[] memory _ids,
        uint256[] memory _values,
        bytes32[] memory _erc1155BatchTransferProof
    ) external;

    function buy(address _vault, uint256 _amount) external payable;

    function buyoutInfo(address, uint256)
        external
        view
        returns (
            uint256 startTime,
            address proposer,
            State state,
            uint256 raePrice,
            uint256 ethBalance,
            uint256 raeBalance,
            uint256 lastTotalSupply
        );

    function cash(address _vault, bytes32[] memory _burnProof) external;

    function end(address _vault, bytes32[] memory _burnProof) external;

    function redeem(address _vault, bytes32[] memory _burnProof) external;

    function registry() external view returns (address);

    function start(address _vault, uint256 _amount) external payable;

    function supply() external view returns (address);

    function transfer() external view returns (address);

    function withdrawERC20(
        address _vault,
        address _token,
        address _to,
        uint256 _value,
        bytes32[] memory _erc20TransferProof
    ) external;

    function withdrawERC721(
        address _vault,
        address _token,
        address _to,
        uint256 _tokenId,
        bytes32[] memory _erc721TransferProof
    ) external;

    function withdrawERC1155(
        address _vault,
        address _token,
        address _to,
        uint256 _id,
        uint256 _value,
        bytes32[] memory _erc1155TransferProof
    ) external;
}

/// @dev Interface for ERC-1155 token contract
interface IERC1155 {
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
    event TransferBatch(
        address indexed _operator,
        address indexed _from,
        address indexed _to,
        uint256[] _ids,
        uint256[] _amounts
    );
    event TransferSingle(
        address indexed _operator,
        address indexed _from,
        address indexed _to,
        uint256 _id,
        uint256 _amount
    );
    event URI(string _value, uint256 indexed _id);

    function balanceOf(address, uint256) external view returns (uint256);

    function balanceOfBatch(address[] memory _owners, uint256[] memory ids)
        external
        view
        returns (uint256[] memory balances);

    function isApprovedForAll(address, address) external view returns (bool);

    function safeBatchTransferFrom(
        address _from,
        address _to,
        uint256[] memory _ids,
        uint256[] memory _amounts,
        bytes memory _data
    ) external;

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _id,
        uint256 _amount,
        bytes memory _data
    ) external;

    function setApprovalForAll(address _operator, bool _approved) external;

    function supportsInterface(bytes4 _interfaceId) external view returns (bool);

    function uri(uint256 _id) external view returns (string memory);
}

/// @dev Interface of ERC-1155 token contract for raes
interface IRae {
    /// @dev Emitted when caller is not required address
    error InvalidSender(address _required, address _provided);
    /// @dev Emitted when owner signature is invalid
    error InvalidSignature(address _signer, address _owner);
    /// @dev Emitted when deadline for signature has passed
    error SignatureExpired(uint256 _timestamp, uint256 _deadline);
    /// @dev Emitted when royalty is set to value greater than 100%
    error InvalidRoyalty(uint256 _percentage);
    /// @dev Emitted when new controller is zero address
    error ZeroAddress();

    /// @dev Event log for updating the Controller of the token contract
    /// @param _newController Address of the controller
    event ControllerTransferred(address indexed _newController);
    /// @dev Event log for updating the metadata contract for a token type
    /// @param _metadata Address of the metadata contract that URI data is stored on
    /// @param _id ID of the token type
    event SetMetadata(address indexed _metadata, uint256 _id);
    /// @dev Event log for updating the royalty of a token type
    /// @param _receiver Address of the receiver of secondary sale royalties
    /// @param _id ID of the token type
    /// @param _percentage Royalty percent on secondary sales
    event SetRoyalty(address indexed _receiver, uint256 indexed _id, uint256 _percentage);
    /// @dev Event log for approving a spender of a token type
    /// @param _owner Address of the owner of the token type
    /// @param _operator Address of the spender of the token type
    /// @param _id ID of the token type
    /// @param _approved Approval status for the token type
    event SingleApproval(
        address indexed _owner,
        address indexed _operator,
        uint256 indexed _id,
        bool _approved
    );
    /// @notice Event log for Minting Raes of ID to account _to
    /// @param _to Address to mint rae tokens to
    /// @param _id Token ID to mint
    /// @param _amount Number of tokens to mint
    event MintRaes(address indexed _to, uint256 indexed _id, uint256 _amount);

    /// @notice Event log for Burning raes of ID from account _from
    /// @param _from Address to burn rae tokens from
    /// @param _id Token ID to burn
    /// @param _amount Number of tokens to burn
    event BurnRaes(address indexed _from, uint256 indexed _id, uint256 _amount);

    function INITIAL_CONTROLLER() external pure returns (address);

    function VAULT_REGISTRY() external pure returns (address);

    function burn(
        address _from,
        uint256 _id,
        uint256 _amount
    ) external;

    function contractURI() external view returns (string memory);

    function controller() external view returns (address controllerAddress);

    function isApproved(
        address,
        address,
        uint256
    ) external view returns (bool);

    function metadataDelegate() external view returns (address);

    function mint(
        address _to,
        uint256 _id,
        uint256 _amount,
        bytes memory _data
    ) external;

    function permit(
        address _owner,
        address _operator,
        uint256 _id,
        bool _approved,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external;

    function permitAll(
        address _owner,
        address _operator,
        bool _approved,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external;

    function royaltyInfo(uint256 _id, uint256 _salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _id,
        uint256 _amount,
        bytes memory _data
    ) external;

    function setApprovalFor(
        address _operator,
        uint256 _id,
        bool _approved
    ) external;

    function setMetadataDelegate(address _metadata) external;

    function setRoyalties(
        uint256 _id,
        address _receiver,
        uint256 _percentage
    ) external;

    function totalSupply(uint256) external view returns (uint256);

    function transferController(address _newController) external;

    function uri(uint256 _id) external view returns (string memory);
}

/// @dev Interface for Supply target contract
interface ISupply {
    /// @dev Emitted when an account being called as an assumed contract does not have code and returns no data
    error MintError(address _account);
    /// @dev Emitted when an account being called as an assumed contract does not have code and returns no data
    error BurnError(address _account);

    function mint(address _to, uint256 _value) external;

    function burn(address _from, uint256 _value) external;
}

/// @dev Interface for Transfer target contract
interface ITransfer {
    /// @dev Emitted when an ERC-20 token transfer returns a falsey value
    /// @param _token The token for which the ERC20 transfer was attempted
    /// @param _from The source of the attempted ERC20 transfer
    /// @param _to The recipient of the attempted ERC20 transfer
    /// @param _amount The amount for the attempted ERC20 transfer
    error BadReturnValueFromERC20OnTransfer(
        address _token,
        address _from,
        address _to,
        uint256 _amount
    );
    /// @dev Emitted when the transfer of ether is unsuccessful
    error ETHTransferUnsuccessful();
    /// @dev Emitted when a batch ERC-1155 token transfer reverts
    /// @param _token The token for which the transfer was attempted
    /// @param _from The source of the attempted transfer
    /// @param _to The recipient of the attempted transfer
    /// @param _identifiers The identifiers for the attempted transfer
    /// @param _amounts The amounts for the attempted transfer
    error ERC1155BatchTransferGenericFailure(
        address _token,
        address _from,
        address _to,
        uint256[] _identifiers,
        uint256[] _amounts
    );
    /// @dev Emitted when an ERC-721 transfer with amount other than one is attempted
    error InvalidERC721TransferAmount();
    /// @dev Emitted when attempting to fulfill an order where an item has an amount of zero
    error MissingItemAmount();
    /// @dev Emitted when an account being called as an assumed contract does not have code and returns no data
    /// @param _account The account that should contain code
    error NoContract(address _account);
    /// @dev Emitted when an ERC-20, ERC-721, or ERC-1155 token transfer fails
    /// @param _token The token for which the transfer was attempted
    /// @param _from The source of the attempted transfer
    /// @param _to The recipient of the attempted transfer
    /// @param _identifier The identifier for the attempted transfer
    /// @param _amount The amount for the attempted transfer
    error TokenTransferGenericFailure(
        address _token,
        address _from,
        address _to,
        uint256 _identifier,
        uint256 _amount
    );

    function ETHTransfer(address _to, uint256 _value) external returns (bool);

    function ERC20Transfer(
        address _token,
        address _to,
        uint256 _value
    ) external;

    function ERC721TransferFrom(
        address _token,
        address _from,
        address _to,
        uint256 _tokenId
    ) external;

    function ERC1155TransferFrom(
        address _token,
        address _from,
        address _to,
        uint256 _id,
        uint256 _value
    ) external;

    function ERC1155BatchTransferFrom(
        address _token,
        address _from,
        address _to,
        uint256[] calldata _ids,
        uint256[] calldata _values
    ) external;
}

/// @notice Gas optimized reentrancy protection for smart contracts.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/ReentrancyGuard.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol)
abstract contract ReentrancyGuard {
    uint256 private locked = 1;

    modifier nonReentrant() virtual {
        require(locked == 1, "REENTRANCY");

        locked = 2;

        _;

        locked = 1;
    }
}

/// @title Optimistic Bid
/// @author Tessera
/// @notice Module contract for vaults to hold buyout pools
/// - A rae owner starts an auction for a vault by depositing any amount of ether and Rae tokens into a pool.
/// - During the rejection period (4 days) users can buy rae tokens from the pool with ether.
/// - If a pool still has a balance of raes after the 4 day period, the buyout is successful and the proposer
///   gains access to withdraw the underlying assets (ERC-20, ERC-721, and ERC-1155 tokens) from the vault.
///   Otherwise the buyout is considered unsuccessful and a new one may then begin.
/// - NOTE: A vault may only have one active buyout at any given time.
/// - raePrice = ethAmount / (totalSupply - raeAmount)
/// - buyoutPrice = raeAmount * raePrice + ethAmount
contract OptimisticBid is
    IOptimisticBid,
    Module,
    Multicall,
    NFTReceiver,
    SafeSend,
    ReentrancyGuard
{
    /// @notice Address of VaultRegistry contract
    address public registry;
    /// @notice Address of Supply target contract
    address public supply;
    /// @notice Address of Transfer target contract
    address public transfer;
    /// @notice Address for feeReceiver
    address public feeReceiver;
    /// @notice Time length of the rejection period
    uint256 public constant REJECTION_PERIOD = 4 days;
    /// @notice vault to current auctionID
    mapping(address => uint256) public currentAuctionId;
    /// @notice Mapping of vault address => auctionIds => buyoutInfo struct
    mapping(address => mapping(uint256 => Auction)) public buyoutInfo;

    /// @notice Initializes registry, supply, and transfer contracts
    constructor(
        address _registry,
        address _supply,
        address _transfer,
        address payable _weth,
        address payable _feeReceiver
    ) SafeSend(_weth) {
        registry = _registry;
        supply = _supply;
        transfer = _transfer;
        feeReceiver = _feeReceiver;
    }

    /// @dev Callback for receiving ether when the calldata is empty
    receive() external payable {}

    /// @notice Sets the feeReceiver address
    /// @param _new The new fee receiver address
    function updatefeeReceiver(address payable _new) external {
        if (msg.sender != feeReceiver) revert NoAuth();
        feeReceiver = _new;
    }

    /// @notice Starts the auction for a buyout pool
    /// @param _vault Address of the vault
    /// @param _amount Number of rae tokens deposited into pool
    function start(address _vault, uint256 _amount) external payable {
        // Reverts if ether deposit amount is zero
        if (_amount == 0) revert ZeroDeposit();
        // Reverts if address is not a registered vault
        (address token, uint256 id) = _verifyVault(_vault);
        _verifyInactive(_vault);
        // Gets total supply of rae tokens for the vault
        uint256 totalSupply = IVaultRegistry(registry).totalSupply(_vault);
        if (_amount > totalSupply) revert DepositNotLessThanSupply();
        // Calculates price of buyout and raes
        // @dev Reverts with division error if called with total supply of tokens
        uint256 raePrice = msg.value / (totalSupply - _amount);
        uint256 buyoutPrice = _amount * raePrice + msg.value;

        // Sets info mapping of the vault address to auction struct
        buyoutInfo[_vault][++currentAuctionId[_vault]] = Auction(
            block.timestamp,
            msg.sender,
            State.LIVE,
            raePrice,
            msg.value,
            _amount,
            totalSupply
        );

        // Transfers rae tokens into the buyout pool
        IERC1155(token).safeTransferFrom(msg.sender, address(this), id, _amount, "");

        // Emits event for starting auction
        emit Start(
            _vault,
            msg.sender,
            currentAuctionId[_vault],
            buyoutPrice,
            Auction(
                block.timestamp,
                msg.sender,
                State.LIVE,
                raePrice,
                msg.value,
                _amount,
                totalSupply
            )
        );
    }

    /// @notice Buys tokens in exchange for ether from a pool
    /// @param _vault Address of the vault
    /// @param _amount Transfer amount of raes
    function buy(address _vault, uint256 _amount) external payable nonReentrant {
        // Reverts if address is not a registered vault
        (address token, uint256 id) = _verifyVault(_vault);
        uint256 auctionId = currentAuctionId[_vault];
        Auction storage auction = buyoutInfo[_vault][auctionId];
        // Reverts if auction state is not live
        _verifyLive(_vault);
        // Reverts if current time is greater than end time of rejection period
        uint256 endTime = auction.startTime + REJECTION_PERIOD;
        if (block.timestamp > endTime) revert TimeExpired(block.timestamp, endTime);
        // Reverts if payment amount does not equal price of rae amount
        if (msg.value != auction.raePrice * _amount) revert InvalidPayment();

        // Increment amount of eth owned buy the buyout pool
        auction.ethBalance += msg.value;
        // Decrement amount of raes in the buyout pool
        auction.raeBalance -= _amount;

        // Terminate live pool if all raes have been bought out
        if (auction.raeBalance == 0) auction.state = State.INACTIVE;
        // Transfers rae tokens to caller
        IERC1155(token).safeTransferFrom(address(this), msg.sender, id, _amount, "");

        // Emits event for buying raes from pool
        emit BuyRaes(_vault, msg.sender, auctionId, _amount);
    }

    /// @notice Ends the auction for a live buyout pool
    /// @param _vault Address of the vault
    /// @param _burnProof Merkle proof for burning rae tokens
    function end(address _vault, bytes32[] calldata _burnProof) external nonReentrant {
        // Reverts if address is not a registered vault
        _verifyVault(_vault);
        // Reverts if auction state is not live
        Auction storage auction = buyoutInfo[_vault][currentAuctionId[_vault]];
        uint256 auctionId = _verifyLive(_vault);
        // Reverts if current time is less than or equal to end time of auction
        uint256 endTime = auction.startTime + REJECTION_PERIOD;
        if (block.timestamp < endTime) revert TimeNotElapsed(block.timestamp, endTime);

        // Checks if token balance > 0
        // If it is bid is successful
        if (auction.raeBalance > 0) {
            // Sets buyout state to successful
            auction.state = State.SUCCESS;
            // Initializes vault transaction
            bytes memory data = abi.encodeCall(ISupply.burn, (address(this), auction.raeBalance));
            // Executes burn of rae tokens from pool
            IVault(payable(_vault)).execute(supply, data, _burnProof);
        } else {
            auction.state = State.INACTIVE;
        }

        // Emits event of buyout state after ending an auction
        emit End(_vault, auction.state, auction.proposer, auctionId);
    }

    /// @notice Cashes out proceeds from a successful buyout
    /// @param _vault Address of the vault
    /// @param _burnProof Merkle proof for burning rae tokens
    function cash(address _vault, bytes32[] calldata _burnProof) external nonReentrant {
        // Reverts if address is not a registered vault
        (address token, uint256 id) = _verifyVault(_vault);
        Auction storage auction = buyoutInfo[_vault][currentAuctionId[_vault]];
        // Reverts if auction state is not successful
        _verifySuccess(_vault);
        // Reverts if caller has a balance of zero rae tokens
        uint256 tokenBalance = IERC1155(token).balanceOf(msg.sender, id);
        if (tokenBalance == 0) revert NoRaes();

        // Transfers buyout share amount to caller based on total supply
        uint256 totalSupply = IRae(token).totalSupply(id);
        uint256 buyoutShare = (tokenBalance * auction.ethBalance) / totalSupply;

        auction.ethBalance -= buyoutShare;

        // Implement a 5% fee
        uint256 fee = buyoutShare / 20;
        buyoutShare -= fee;

        // Initializes vault transaction
        bytes memory data = abi.encodeCall(ISupply.burn, (msg.sender, tokenBalance));
        // Executes burn of rae tokens from caller
        IVault(payable(_vault)).execute(supply, data, _burnProof);

        // Emits event for cashing out of buyout pool
        emit Cash(_vault, msg.sender, tokenBalance, buyoutShare);

        _sendEthOrWeth(feeReceiver, fee);
        _sendEthOrWeth(msg.sender, buyoutShare);
    }

    /// @notice Terminates a vault with an inactive buyout
    /// @param _vault Address of the vault
    /// @param _burnProof Merkle proof for burning rae tokens
    function redeem(address _vault, bytes32[] calldata _burnProof) external {
        // Reverts if address is not a registered vault
        (address token, uint256 id) = _verifyVault(_vault);
        Auction storage auction = buyoutInfo[_vault][currentAuctionId[_vault]];
        // If the vault has had a buyout before, check the it's current state
        _verifyInactive(_vault);
        uint256 totalSupply = IRae(token).totalSupply(id);
        require(
            IERC1155(token).balanceOf(msg.sender, id) == totalSupply,
            "Redeemer needs totalSupply"
        );

        // Sets buyout state to successful and proposer to caller
        (auction.state, auction.proposer) = (State.SUCCESS, msg.sender);

        bytes memory data = abi.encodeCall(ISupply.burn, (msg.sender, totalSupply));
        // Executes burn of rae tokens from caller
        IVault(payable(_vault)).execute(supply, data, _burnProof);
        // Emits event for redeem underlying assets from the vault
        emit Redeem(_vault, msg.sender);
    }

    /// @notice Withdraws an ERC-20 token from a vault
    /// @param _vault Address of the vault
    /// @param _token Address of the token
    /// @param _to Address of the receiver
    /// @param _value Transfer amount
    /// @param _erc20TransferProof Merkle proof for transferring an ERC-20 token
    function withdrawERC20(
        address _vault,
        address _token,
        address _to,
        uint256 _value,
        bytes32[] calldata _erc20TransferProof
    ) external {
        _verifyVault(_vault);
        uint256 auctionId = currentAuctionId[_vault];
        Auction memory auction = buyoutInfo[_vault][auctionId];
        _verifySuccess(_vault);
        // Reverts if caller is not the auction winner
        if (msg.sender != auction.proposer) revert NotProposer(auction.proposer, msg.sender);

        // Initializes vault transaction
        bytes memory data = abi.encodeCall(ITransfer.ERC20Transfer, (_token, _to, _value));
        // Executes transfer of ERC20 token to caller
        IVault(payable(_vault)).execute(transfer, data, _erc20TransferProof);

        emit WithdrawERC20(_vault, _token, auctionId, _to, _value);
    }

    /// @notice Withdraws an ERC-721 token from a vault
    /// @param _vault Address of the vault
    /// @param _token Address of the token
    /// @param _to Address of the receiver
    /// @param _tokenId ID of the token
    /// @param _erc721TransferProof Merkle proof for transferring an ERC-721 token
    function withdrawERC721(
        address _vault,
        address _token,
        address _to,
        uint256 _tokenId,
        bytes32[] calldata _erc721TransferProof
    ) external {
        _verifyVault(_vault);
        uint256 auctionId = currentAuctionId[_vault];
        Auction memory auction = buyoutInfo[_vault][auctionId];
        _verifySuccess(_vault);
        // Reverts if caller is not the auction winner
        if (msg.sender != auction.proposer) revert NotProposer(auction.proposer, msg.sender);

        // Initializes vault transaction
        bytes memory data = abi.encodeCall(
            ITransfer.ERC721TransferFrom,
            (_token, _vault, _to, _tokenId)
        );
        // Executes transfer of ERC721 token to caller
        IVault(payable(_vault)).execute(transfer, data, _erc721TransferProof);

        emit WithdrawERC721(_vault, _token, auctionId, _to, _tokenId);
    }

    /// @notice Withdraws an ERC-1155 token from a vault
    /// @param _vault Address of the vault
    /// @param _token Address of the token
    /// @param _to Address of the receiver
    /// @param _id ID of the token type
    /// @param _value Transfer amount
    /// @param _erc1155TransferProof Merkle proof for transferring an ERC-1155 token
    function withdrawERC1155(
        address _vault,
        address _token,
        address _to,
        uint256 _id,
        uint256 _value,
        bytes32[] calldata _erc1155TransferProof
    ) external {
        _verifyVault(_vault);
        uint256 auctionId = currentAuctionId[_vault];
        Auction memory auction = buyoutInfo[_vault][auctionId];
        // Reverts if auction state is not successful
        _verifySuccess(_vault);
        // Reverts if caller is not the auction winner
        if (msg.sender != auction.proposer) revert NotProposer(auction.proposer, msg.sender);

        // Initializes vault transaction
        bytes memory data = abi.encodeCall(
            ITransfer.ERC1155TransferFrom,
            (_token, _vault, _to, _id, _value)
        );
        // Executes transfer of ERC1155 token to caller
        IVault(payable(_vault)).execute(transfer, data, _erc1155TransferProof);

        emit WithdrawERC1155(_vault, _token, auctionId, _to, _id, _value);
    }

    /// @notice Batch withdraws ERC-1155 tokens from a vault
    /// @param _vault Address of the vault
    /// @param _token Address of the token
    /// @param _to Address of the receiver
    /// @param _ids IDs of each token type
    /// @param _values Transfer amounts per token type
    /// @param _erc1155BatchTransferProof Merkle proof for transferring multiple ERC-1155 tokens
    function batchWithdrawERC1155(
        address _vault,
        address _token,
        address _to,
        uint256[] calldata _ids,
        uint256[] calldata _values,
        bytes32[] calldata _erc1155BatchTransferProof
    ) external {
        // Reverts if address is not a registered vault
        _verifyVault(_vault);
        uint256 auctionId = currentAuctionId[_vault];
        Auction memory auction = buyoutInfo[_vault][auctionId];
        // Reverts if auction state is not successful
        _verifySuccess(_vault);
        // Reverts if caller is not the auction winner
        if (msg.sender != auction.proposer) revert NotProposer(auction.proposer, msg.sender);

        // Initializes vault transaction
        bytes memory data = abi.encodeCall(
            ITransfer.ERC1155BatchTransferFrom,
            (_token, _vault, _to, _ids, _values)
        );
        // Executes batch transfer of multiple ERC1155 tokens to caller
        IVault(payable(_vault)).execute(transfer, data, _erc1155BatchTransferProof);

        emit BatchWithdrawERC1155(_vault, _token, auctionId, _to, _ids, _values);
    }

    /// @notice Withdraws balance from a failed buyout
    /// @param _vault Address of the vault
    /// @param _auctionId Transfer amount of raes
    function withdraw(address _vault, uint256 _auctionId) external {
        (address token, uint256 id) = _verifyVault(_vault); // Reverts if auction state is not live
        Auction storage auction = buyoutInfo[_vault][_auctionId];
        _verifyInactive(_vault);
        // Check the caller is the proposer
        address proposer = auction.proposer;
        if (proposer != msg.sender) revert NotProposer(proposer, msg.sender);

        uint256 ethBalance = auction.ethBalance;
        uint256 raeBalance = auction.raeBalance;
        auction.ethBalance = 0;
        auction.raeBalance = 0;

        // Transfers raes and ether back to proposer of the buyout pool
        IERC1155(token).safeTransferFrom(address(this), proposer, id, raeBalance, "");

        _sendEthOrWeth(proposer, ethBalance);
    }

    /// @notice Gets the list of permissions installed on a vault
    /// @dev Permissions consist of a module contract, target contract, and function selector
    /// @return permissions List of vault permissions
    function getPermissions()
        public
        view
        override(Module)
        returns (Permission[] memory permissions)
    {
        permissions = new Permission[](5);
        // Burn function selector from supply contract
        permissions[0] = Permission(address(this), supply, ISupply.burn.selector);
        // ERC20Transfer function selector from transfer contract
        permissions[1] = Permission(address(this), transfer, ITransfer.ERC20Transfer.selector);
        // ERC721TransferFrom function selector from transfer contract
        permissions[2] = Permission(address(this), transfer, ITransfer.ERC721TransferFrom.selector);
        // ERC1155TransferFrom function selector from transfer contract
        permissions[3] = Permission(
            address(this),
            transfer,
            ITransfer.ERC1155TransferFrom.selector
        );
        // ERC1155BatchTransferFrom function selector from transfer contract
        permissions[4] = Permission(
            address(this),
            transfer,
            ITransfer.ERC1155BatchTransferFrom.selector
        );
    }

    function _verifyInactive(address _vault) internal view returns (uint256 auctionId) {
        auctionId = currentAuctionId[_vault];
        State current = buyoutInfo[_vault][auctionId].state;
        if (current != State.INACTIVE) revert InvalidState(State.INACTIVE, current);
    }

    function _verifyLive(address _vault) internal view returns (uint256 auctionId) {
        auctionId = currentAuctionId[_vault];
        State current = buyoutInfo[_vault][auctionId].state;
        if (current != State.LIVE) revert InvalidState(State.LIVE, current);
    }

    function _verifySuccess(address _vault) internal view returns (uint256 auctionId) {
        auctionId = currentAuctionId[_vault];
        State current = buyoutInfo[_vault][auctionId].state;
        if (current != State.SUCCESS) revert InvalidState(State.SUCCESS, current);
    }

    function _verifyVault(address _vault) internal view returns (address token, uint256 id) {
        (token, id) = IVaultRegistry(registry).vaultToToken(_vault);
        if (id == 0) revert NotVault(_vault);
    }
}