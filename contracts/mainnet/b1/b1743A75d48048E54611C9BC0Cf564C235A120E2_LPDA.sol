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

/// @dev Interface for generic Protoform contract
interface IProtoform {
    /// @dev Event log for modules that are enabled on a vault
    /// @param _vault The vault deployed
    /// @param _modules The modules being activated on deployed vault
    event ActiveModules(address indexed _vault, address[] _modules);

    function generateMerkleTree(address[] memory _modules)
        external
        view
        returns (bytes32[] memory tree);

    function generateUnhashedMerkleTree(address[] memory _modules)
        external
        view
        returns (bytes[] memory tree);
}

/// @title Merkle Base
/// @author Modified from Murky (https://github.com/dmfxyz/murky/blob/main/src/common/MurkyBase.sol)
/// @notice Utility contract for generating merkle roots and verifying proofs
abstract contract MerkleBase {
    constructor() {}

    /// @notice Hashes two leaf pairs
    /// @param _left Node on left side of tree level
    /// @param _right Node on right side of tree level
    /// @return data Result hash of node params
    function hashLeafPairs(bytes32 _left, bytes32 _right) public pure returns (bytes32 data) {
        // Return opposite node if checked node is of bytes zero value
        if (_left == bytes32(0)) return _right;
        if (_right == bytes32(0)) return _left;

        assembly {
            // TODO: This can be aesthetically simplified with a switch. Not sure it will
            // save much gas but there are other optimizations to be had in here.
            if or(lt(_left, _right), eq(_left, _right)) {
                mstore(0x0, _left)
                mstore(0x20, _right)
            }
            if gt(_left, _right) {
                mstore(0x0, _right)
                mstore(0x20, _left)
            }
            data := keccak256(0x0, 0x40)
        }
    }

    /// @notice Verifies the merkle proof of a given value
    /// @param _root Hash of merkle root
    /// @param _proof Merkle proof
    /// @param _valueToProve Leaf node being proven
    /// @return Status of proof verification
    function verifyProof(
        bytes32 _root,
        bytes32[] memory _proof,
        bytes32 _valueToProve
    ) public pure returns (bool) {
        // proof length must be less than max array size
        bytes32 rollingHash = _valueToProve;
        unchecked {
            for (uint256 i = 0; i < _proof.length; ++i) {
                rollingHash = hashLeafPairs(rollingHash, _proof[i]);
            }
        }
        return _root == rollingHash;
    }

    /// @notice Generates the merkle root of a tree
    /// @param _data Leaf nodes of the merkle tree
    /// @return Hash of merkle root
    function getRoot(bytes32[] memory _data) public pure returns (bytes32) {
        require(_data.length > 1, "wont generate root for single leaf");
        while (_data.length > 1) {
            _data = hashLevel(_data);
        }
        return _data[0];
    }

    /// @notice Generates the merkle proof for a leaf node in a given tree
    /// @param _data Leaf nodes of the merkle tree
    /// @param _node Index of the node in the tree
    /// @return proof Merkle proof
    function getProof(bytes32[] memory _data, uint256 _node)
        public
        pure
        returns (bytes32[] memory proof)
    {
        require(_data.length > 1, "wont generate proof for single leaf");
        // The size of the proof is equal to the ceiling of log2(numLeaves)
        uint256 size = log2ceil_naive(_data.length);
        bytes32[] memory result = new bytes32[](size);
        uint256 pos;
        uint256 counter;

        // Two overflow risks: node, pos
        // node: max array size is 2**256-1. Largest index in the array will be 1 less than that. Also,
        // for dynamic arrays, size is limited to 2**64-1
        // pos: pos is bounded by log2(data.length), which should be less than type(uint256).max
        while (_data.length > 1) {
            unchecked {
                if (_node % 2 == 1) {
                    result[pos] = _data[_node - 1];
                } else if (_node + 1 == _data.length) {
                    result[pos] = bytes32(0);
                    ++counter;
                } else {
                    result[pos] = _data[_node + 1];
                }
                ++pos;
                _node = _node / 2;
            }
            _data = hashLevel(_data);
        }

        // Dynamic array to filter out address(0) since proof size is rounded up
        // This is done to return the actual proof size of the indexed node
        uint256 offset;
        proof = new bytes32[](size - counter);
        unchecked {
            for (uint256 i; i < size; ++i) {
                if (result[i] != bytes32(0)) {
                    proof[i - offset] = result[i];
                } else {
                    ++offset;
                }
            }
        }
    }

    /// @dev Hashes nodes at the given tree level
    /// @param _data Nodes at the current level
    /// @return result Hashes of nodes at the next level
    function hashLevel(bytes32[] memory _data) private pure returns (bytes32[] memory result) {
        // Function is private, and all internal callers check that data.length >=2.
        // Underflow is not possible as lowest possible value for data/result index is 1
        // overflow should be safe as length is / 2 always.
        unchecked {
            uint256 length = _data.length;
            if (length & 0x1 == 1) {
                result = new bytes32[]((length >> 1) + 1);
                result[result.length - 1] = hashLeafPairs(_data[length - 1], bytes32(0));
            } else {
                result = new bytes32[](length >> 1);
            }

            // pos is upper bounded by data.length / 2, so safe even if array is at max size
            uint256 pos;
            for (uint256 i; i < length - 1; i += 2) {
                result[pos] = hashLeafPairs(_data[i], _data[i + 1]);
                ++pos;
            }
        }
    }

    /// @notice Calculates proof size based on size of tree
    /// @dev Note that x is assumed > 0 and proof size is not precise
    /// @param x Size of the merkle tree
    /// @return ceil Rounded value of proof size
    function log2ceil_naive(uint256 x) public pure returns (uint256 ceil) {
        uint256 pOf2;
        // If x is a power of 2, then this function will return a ceiling
        // that is 1 greater than the actual ceiling. So we need to check if
        // x is a power of 2, and subtract one from ceil if so.
        assembly {
            // we check by seeing if x == (~x + 1) & x. This applies a mask
            // to find the lowest set bit of x and then checks it for equality
            // with x. If they are equal, then x is a power of 2.

            /* Example
                x has single bit set
                x := 0000_1000
                (~x + 1) = (1111_0111) + 1 = 1111_1000
                (1111_1000 & 0000_1000) = 0000_1000 == x
                x has multiple bits set
                x := 1001_0010
                (~x + 1) = (0110_1101 + 1) = 0110_1110
                (0110_1110 & x) = 0000_0010 != x
            */

            // we do some assembly magic to treat the bool as an integer later on
            pOf2 := eq(and(add(not(x), 1), x), x)
        }

        // if x == type(uint256).max, than ceil is capped at 256
        // if x == 0, then pO2 == 0, so ceil won't underflow
        unchecked {
            while (x > 0) {
                x >>= 1;
                ceil++;
            }
            ceil -= pOf2;
        }
    }
}

/// @title Protoform
/// @author Tessera
/// @notice Base protoform contract for generating merkle trees
contract Protoform is IProtoform, MerkleBase {
    /// @notice Generates a merkle tree from the hashed permissions of the given modules
    /// @param _modules List of module contracts
    /// @return tree Merkle tree of hashed leaf nodes
    function generateMerkleTree(address[] memory _modules)
        public
        view
        returns (bytes32[] memory tree)
    {
        uint256 counter;
        uint256 modulesLength = _modules.length;
        uint256 treeSize = _getTreeSize(_modules, modulesLength);
        tree = new bytes32[](treeSize);
        unchecked {
            /* _sortList(_modules, modulesLength); */
            for (uint256 i; i < modulesLength; ++i) {
                bytes32[] memory leaves = IModule(_modules[i]).getLeaves();
                uint256 leavesLength = leaves.length;
                for (uint256 j; j < leavesLength; ++j) {
                    tree[counter++] = leaves[j];
                }
            }
        }
    }

    /// @notice Generates a merkle tree from the unhashed permissions of the given modules
    /// @dev Only used for third party APIs (Lanyard) that require unhashed leaves
    /// @param _modules List of module contracts
    /// @return tree Merkle tree of unhashed leaf nodes
    function generateUnhashedMerkleTree(address[] memory _modules)
        public
        view
        returns (bytes[] memory tree)
    {
        uint256 counter;
        uint256 modulesLength = _modules.length;
        uint256 treeSize = _getTreeSize(_modules, modulesLength);
        tree = new bytes[](treeSize);
        unchecked {
            /* _sortList(_modules, modulesLength); */
            for (uint256 i; i < modulesLength; ++i) {
                bytes[] memory leaves = IModule(_modules[i]).getUnhashedLeaves();
                uint256 leavesLength = leaves.length;
                for (uint256 j; j < leavesLength; ++j) {
                    tree[counter++] = leaves[j];
                }
            }
        }
    }

    /// @dev Gets the size of a merkle tree based on the total permissions across all modules
    /// @param _modules List of module contracts
    /// @param _length Size of modules array
    /// @return size Total size of the merkle tree
    function _getTreeSize(address[] memory _modules, uint256 _length)
        internal
        view
        returns (uint256 size)
    {
        unchecked {
            for (uint256 i; i < _length; ++i) {
                size += IModule(_modules[i]).getLeaves().length;
            }
        }
    }

    /// @dev Sorts the list of modules in ascending order
    function _sortList(address[] memory _modules, uint256 _length) internal pure {
        for (uint256 i; i < _length; ++i) {
            for (uint256 j = i + 1; j < _length; ++j) {
                if (_modules[i] > _modules[j]) {
                    (_modules[i], _modules[j]) = (_modules[j], _modules[i]);
                }
            }
        }
    }
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

struct LPDAInfo {
    /// the start time of the auction
    uint32 startTime;
    /// the end time of the auction
    uint32 endTime;
    /// the price decrease per second
    uint64 dropPerSecond;
    /// the price of the item at startTime
    uint128 startPrice;
    /// the price that startPrice drops down
    uint128 endPrice;
    /// the lowest price paid in a successful LPDA
    uint128 minBid;
    /// the total supply of raes being auctioned
    uint16 supply;
    /// the number of raes currently sold in the auction
    uint16 numSold;
    /// the amount of eth claimed by the curator
    uint128 curatorClaimed;
    /// the address of the curator of the auctioned item
    address curator;
}

enum LPDAState {
    NotLive,
    Live,
    Successful,
    NotSuccessful
}

interface ILPDA {
    event CreatedLPDA(
        address indexed _vault,
        address indexed _token,
        uint256 _id,
        LPDAInfo _lpdaInfo
    );

    /// @notice event emitted when a new bid is entered
    event BidEntered(
        address indexed _vault,
        address indexed _user,
        uint256 _quantity,
        uint256 _price
    );

    /// @notice event emitted when settling an auction and a user is owed a refund
    event Refunded(address indexed _vault, address indexed _user, uint256 _balance);

    /// @notice event emitted when settling a successful auction with minted quantity
    event MintedRaes(
        address indexed _vault,
        address indexed _user,
        uint256 _quantity,
        uint256 _price
    );

    /// @notice event emitted when settling a successful auction with curator receiving a percentage
    event CuratorClaimed(address indexed _vault, address indexed _curator, uint256 _amount);

    /// @notice event emitted when settling a successful auction and fees dispersed
    event FeeDispersed(address indexed _vault, address indexed _receiver, uint256 _amount);

    /// @notice event emitted when settling a successful auction and royalty assessed
    event RoyaltyPaid(address indexed _vault, address indexed _royaltyReceiver, uint256 _amount);

    /// @notice event emitted after an unsuccessful auction and the curator withdraws their nft
    event CuratorRedeemedNFT(
        address indexed _vault,
        address indexed _curator,
        address indexed _token,
        uint256 _tokenId
    );

    function deployVault(
        address[] calldata _modules,
        address[] calldata _plugins,
        bytes4[] calldata _selectors,
        LPDAInfo calldata _lpdaInfo,
        address _token,
        uint256 _id,
        bytes32[] calldata _mintProof
    ) external returns (address vault);

    function enterBid(address _vault, uint16 _amount) external payable;

    function settleAddress(address _vault, address _minter) external;

    function settleCurator(address _vault) external;

    function redeemNFTCurator(
        address _vault,
        address _token,
        uint256 _tokenId,
        bytes32[] calldata _erc721TransferProof
    ) external;

    function updateFeeReceiver(address _receiver) external;

    function currentPrice(address _vault) external returns (uint256 price);

    function getAuctionState(address _vault) external returns (LPDAState state);

    function refundOwed(address _vault, address _minter) external returns (uint256 owed);
}

library LibLPDAInfo {
    function getAuctionState(LPDAInfo memory _info) internal view returns (LPDAState) {
        if (isNotLive(_info)) return LPDAState.NotLive;
        if (isLive(_info)) return LPDAState.Live;
        if (isSuccessful(_info)) return LPDAState.Successful;
        return LPDAState.NotSuccessful;
    }

    function isNotLive(LPDAInfo memory _info) internal view returns (bool) {
        return (_info.startTime > block.timestamp);
    }

    function isLive(LPDAInfo memory _info) internal view returns (bool) {
        return (block.timestamp > _info.startTime &&
            block.timestamp < _info.endTime &&
            _info.numSold < _info.supply);
    }

    function isSuccessful(LPDAInfo memory _info) internal pure returns (bool) {
        return (_info.numSold == _info.supply);
    }

    function isNotSuccessful(LPDAInfo memory _info) internal view returns (bool) {
        return (block.timestamp > _info.endTime && _info.numSold < _info.supply);
    }

    function isOver(LPDAInfo memory _info) internal view returns (bool) {
        return (isNotSuccessful(_info) || isSuccessful(_info));
    }

    function remainingSupply(LPDAInfo memory _info) internal pure returns (uint256) {
        return (_info.supply - _info.numSold);
    }

    function validateAndRecordBid(
        LPDAInfo storage _info,
        uint128 price,
        uint16 amount
    ) internal {
        _validateBid(_info, price, amount);
        _info.numSold += amount;
        if (_info.numSold == _info.supply) _info.minBid = price;
    }

    function validateAuctionInfo(LPDAInfo memory _info) internal view {
        require(_info.startTime >= uint32(block.timestamp), "LPDA: Invalid time");
        require(_info.startTime < _info.endTime, "LPDA: Invalid time");
        require(_info.dropPerSecond > 0, "LPDA: Invalid drop");
        require(_info.startPrice > _info.endPrice, "LPDA: Invalid price");
        require(_info.minBid == 0, "LPDA: Invalid min bid");
        require(_info.supply > 0, "LPDA: Invalid supply");
        require(_info.numSold == 0, "LPDA: Invalid sold");
        require(_info.curatorClaimed == 0, "LPDA: Invalid curatorClaimed");
    }

    function _validateBid(
        LPDAInfo memory _info,
        uint128 price,
        uint16 amount
    ) internal view {
        require(msg.value >= (price * amount), "LPDA: Insufficient value");
        require(_info.supply != 0, "LPDA: Auction doesnt exist");
        require(remainingSupply(_info) >= amount, "LPDA: Not enough remaining");
        require(isLive(_info), "LPDA: Not Live");
        require(amount > 0, "LPDA: Must bid atleast 1 rae");
    }
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

/// @dev Interface for Minter module contract
interface IMinter {
    function getPermissions() external view returns (Permission[] memory permissions);

    function supply() external view returns (address);
}

/// @title Minter
/// @author Tessera
/// @notice Module contract for minting a fixed supply of Raes
contract Minter is IMinter, Module {
    /// @notice Address of Supply target contract
    address public immutable supply;

    /// @notice Initializes supply target contract
    constructor(address _supply) {
        supply = _supply;
    }

    /// @notice Gets the list of permissions installed on a vault
    /// @dev Permissions consist of a module contract, target contract, and function selector
    /// @return permissions A list of Permission Structs
    function getPermissions()
        public
        view
        virtual
        override(IMinter, Module)
        returns (Permission[] memory permissions)
    {
        permissions = new Permission[](1);
        permissions[0] = Permission(address(this), supply, ISupply.mint.selector);
    }

    /// @notice Mints a Rae supply
    /// @param _vault Address of the Vault
    /// @param _to Address of the receiver of Raes
    /// @param _raeSupply Number of NFT Raes minted to control the vault
    /// @param _mintProof List of proofs to execute a mint function
    function _mintRaes(
        address _vault,
        address _to,
        uint256 _raeSupply,
        bytes32[] calldata _mintProof
    ) internal {
        bytes memory data = abi.encodeCall(ISupply.mint, (_to, _raeSupply));
        IVault(payable(_vault)).execute(supply, data, _mintProof);
    }
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

/// @dev Interface for ERC-721 token contract
interface IERC721 {
    event Approval(address indexed _owner, address indexed _spender, uint256 indexed _id);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _id);

    function approve(address _spender, uint256 _id) external;

    function balanceOf(address _owner) external view returns (uint256);

    function getApproved(uint256) external view returns (address);

    function isApprovedForAll(address, address) external view returns (bool);

    function name() external view returns (string memory);

    function ownerOf(uint256 _id) external view returns (address owner);

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _id
    ) external;

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _id,
        bytes memory _data
    ) external;

    function setApprovalForAll(address _operator, bool _approved) external;

    function supportsInterface(bytes4 _interfaceId) external view returns (bool);

    function symbol() external view returns (string memory);

    function tokenURI(uint256 _id) external view returns (string memory);

    function transferFrom(
        address _from,
        address _to,
        uint256 _id
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

// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

/// @title LPDA
/// @author Tessera
/// @notice Last Price Dutch Auction contract for distributing Raes
contract LPDA is ILPDA, Protoform, Minter, ReentrancyGuard, SafeSend, NFTReceiver {
    using LibLPDAInfo for LPDAInfo;
    /// @notice Address of VaultRegistry contract
    address public immutable registry;
    /// @notice Address of Transfer target contract
    address public immutable transfer;
    /// @notice Address of fee receiver on initial distrubtion
    address public feeReceiver;
    /// @notice Max fee a curator will pay
    uint256 public constant MAX_FEE = 1250;
    /// @notice vault => user => total amount paid by user
    mapping(address => mapping(address => uint256)) public balanceContributed;
    /// @notice vault => user => total amount refunded to user
    mapping(address => mapping(address => uint256)) public balanceRefunded;
    /// @notice vault => user => total # of raes minted by user
    mapping(address => mapping(address => uint256)) public numMinted;
    /// @notice vault => royalty token
    mapping(address => address) public vaultRoyaltyToken;
    /// @notice vault => royalty token Id
    mapping(address => uint256) public vaultRoyaltyTokenId;
    /// @notice vault => auction info struct for LPDA
    mapping(address => LPDAInfo) public vaultLPDAInfo;
    /// @notice vault => enumerated list of minters for the LPDA
    mapping(address => address[]) public vaultLPDAMinters;

    constructor(
        address _registry,
        address _supply,
        address _transfer,
        address payable _weth,
        address _feeReceiver
    ) Minter(_supply) SafeSend(_weth) {
        registry = _registry;
        transfer = _transfer;
        feeReceiver = _feeReceiver;
    }

    /// @notice Deploys a new Vault and mints initial supply of Raes
    /// @param _modules The list of modules to be installed on the vault
    function deployVault(
        address[] calldata _modules,
        address[] calldata _plugins,
        bytes4[] calldata _selectors,
        LPDAInfo calldata _lpdaInfo,
        address _token,
        uint256 _id,
        bytes32[] calldata _mintProof
    ) external returns (address vault) {
        _lpdaInfo.validateAuctionInfo();
        bytes32[] memory leafNodes = generateMerkleTree(_modules);
        bytes32 merkleRoot = getRoot(leafNodes);
        vault = IVaultRegistry(registry).create(merkleRoot);
        if (IERC165(_token).supportsInterface(type(IERC2981).interfaceId))
            (vaultRoyaltyToken[vault] = _token, vaultRoyaltyTokenId[vault] = _id);

        vaultLPDAInfo[vault] = _lpdaInfo;

        IERC721(_token).transferFrom(msg.sender, vault, _id);
        _mintRaes(vault, address(this), _lpdaInfo.supply, _mintProof);

        emit ActiveModules(vault, _modules);
        emit CreatedLPDA(vault, _token, _id, _lpdaInfo);
    }

    /// @notice Enters a bid for a given vault
    /// @param _vault The vault to bid on raes for
    /// @param _amount The quantity of raes to bid for
    function enterBid(address _vault, uint16 _amount) external payable {
        LPDAInfo storage lpda = vaultLPDAInfo[_vault];
        uint256 price = currentPrice(_vault);
        lpda.validateAndRecordBid(uint128(price), _amount);

        vaultLPDAMinters[_vault].push(msg.sender);
        balanceContributed[_vault][msg.sender] += msg.value;
        numMinted[_vault][msg.sender] += _amount;

        emit BidEntered(_vault, msg.sender, _amount, price);
    }

    /// @notice Settles the auction for a given vault's LPDA
    /// @param _vault The vault to settle the LPDA for
    /// @param _minter The minter to settle their share of the LPDA
    function settleAddress(address _vault, address _minter) external nonReentrant {
        LPDAInfo memory lpda = vaultLPDAInfo[_vault];
        require(lpda.isOver(), "LPDA: Auction NOT over");
        uint256 amount = numMinted[_vault][_minter];
        delete numMinted[_vault][_minter];
        if (lpda.isSuccessful()) {
            (address token, uint256 id) = IVaultRegistry(registry).vaultToToken(_vault);
            IERC1155(token).safeTransferFrom(address(this), _minter, id, amount, "");
            _refundAddress(_vault, _minter, amount, lpda.minBid);
            emit MintedRaes(_vault, _minter, amount, lpda.minBid);
        } else if (lpda.isNotSuccessful()) {
            _refundAddress(_vault, _minter, amount, lpda.minBid);
        } else {
            revert("LPDA: Auction NOT over");
        }
    }

    /// @notice Settles the curators account for a given vault
    /// @notice _vault The vault to settle the curator for
    function settleCurator(address _vault) external nonReentrant {
        LPDAInfo storage lpda = vaultLPDAInfo[_vault];
        require(lpda.isSuccessful(), "LPDA: Not sold out");
        require(lpda.curatorClaimed == 0, "LPDA: Curator already claimed");
        uint256 total = lpda.minBid * lpda.numSold;
        uint256 min = lpda.endPrice * lpda.numSold;
        uint256 feePercent = MAX_FEE;
        if (min != 0) {
            uint256 diff = total - min;
            feePercent = ((diff * 1e18) / (min * 5) / 1e14) + 250;
            feePercent = feePercent > MAX_FEE ? MAX_FEE : feePercent;
        }
        uint256 fee = (feePercent * total) / 1e4;
        lpda.curatorClaimed += uint128(total);
        address token = vaultRoyaltyToken[_vault];
        uint256 id = vaultRoyaltyTokenId[_vault];
        (address royaltyReceiver, uint256 royaltyAmount) = token == address(0)
            ? (address(0), 0)
            : IERC2981(token).royaltyInfo(id, total);
        _sendEthOrWeth(royaltyReceiver, royaltyAmount);
        emit RoyaltyPaid(_vault, royaltyReceiver, royaltyAmount);
        _sendEthOrWeth(feeReceiver, fee);
        emit FeeDispersed(_vault, feeReceiver, fee);
        _sendEthOrWeth(lpda.curator, total - fee - royaltyAmount);
        emit CuratorClaimed(_vault, lpda.curator, total - fee - royaltyAmount);
    }

    /// @notice Redeems the curator's NFT for a given vault if the LPDA was unsuccessful
    /// @param _vault The vault to redeem the curator's NFT for
    /// @param _token The token contract to redeem
    /// @param _tokenId The tokenId to redeem
    /// @param _erc721TransferProof The proofs required to transfer the NFT
    function redeemNFTCurator(
        address _vault,
        address _token,
        uint256 _tokenId,
        bytes32[] calldata _erc721TransferProof
    ) external {
        LPDAInfo memory lpda = vaultLPDAInfo[_vault];
        require(lpda.isNotSuccessful(), "LPDA: Auction NOT Successful");
        require(msg.sender == lpda.curator, "LPDA: Not curator");

        bytes memory data = abi.encodeCall(
            ITransfer.ERC721TransferFrom,
            (_token, _vault, msg.sender, _tokenId)
        );
        IVault(payable(_vault)).execute(transfer, data, _erc721TransferProof);

        emit CuratorRedeemedNFT(_vault, msg.sender, _token, _tokenId);
    }

    /// @notice Transfer the feeReceiver account
    /// @param _receiver The new feeReceiver
    function updateFeeReceiver(address _receiver) external {
        require(msg.sender == feeReceiver, "LPDA: Not fee receiver");
        feeReceiver = _receiver;
    }

    /// @notice returns the current dutch auction price
    /// @param _vault The vault to get the current price of the LPDA for
    /// @return price The current price of the LPDA
    function currentPrice(address _vault) public view returns (uint256 price) {
        LPDAInfo memory lpda = vaultLPDAInfo[_vault];
        uint256 deduction = (block.timestamp - lpda.startTime) * lpda.dropPerSecond;
        price = (deduction > lpda.startPrice) ? 0 : lpda.startPrice - deduction;
        price = (price > lpda.endPrice) ? price : lpda.endPrice;
    }

    function getMinters(address _vault) public view returns (address[] memory) {
        return vaultLPDAMinters[_vault];
    }

    /// @notice returns the current lpda auction state for a vault
    /// @param _vault The vault to get the current auction state for
    function getAuctionState(address _vault) public view returns (LPDAState) {
        return vaultLPDAInfo[_vault].getAuctionState();
    }

    /// @notice Check the refund owned to an account
    /// @param _vault The vault to check the refund for
    /// @param _minter the acount to check the refund for
    /// @return The refund still owed to the minter account
    function refundOwed(address _vault, address _minter) public view returns (uint256) {
        LPDAInfo memory lpda = vaultLPDAInfo[_vault];
        uint256 totalCost = lpda.minBid * numMinted[_vault][_minter];
        uint256 alreadyRefunded = balanceRefunded[_vault][_minter];
        uint256 balance = balanceContributed[_vault][_minter];
        return balance - alreadyRefunded - totalCost;
    }

    /// @notice Gets the list of permissions installed on a vault
    /// @dev Permissions consist of a module contract, target contract, and function selector
    /// @return permissions A list of Permission Structs
    function getPermissions()
        public
        view
        virtual
        override(Minter)
        returns (Permission[] memory permissions)
    {
        permissions = new Permission[](2);
        permissions[0] = super.getPermissions()[0];
        permissions[1] = Permission(address(this), transfer, ITransfer.ERC721TransferFrom.selector);
    }

    function _refundAddress(
        address _vault,
        address _minter,
        uint256 _mints,
        uint128 _minBid
    ) internal {
        uint256 owed = balanceContributed[_vault][_minter];
        owed -= (_minBid * _mints + balanceRefunded[_vault][_minter]);
        if (owed > 0) {
            balanceRefunded[_vault][_minter] += owed;
            _sendEthOrWeth(_minter, owed);
            emit Refunded(_vault, _minter, owed);
        }
    }
}