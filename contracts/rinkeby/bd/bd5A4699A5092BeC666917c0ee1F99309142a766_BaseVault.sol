// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {IBaseVault} from "../../interfaces/IBaseVault.sol";
import {IBuyout} from "../../interfaces/IBuyout.sol";
import {IERC20} from "../../interfaces/IERC20.sol";
import {IERC721} from "../../interfaces/IERC721.sol";
import {IERC1155} from "../../interfaces/IERC1155.sol";
import {IModule} from "../../interfaces/IProtoform.sol";
import {ISupply} from "../../interfaces/ISupply.sol";
import {IVault} from "../../interfaces/IVault.sol";
import {IVaultRegistry, Permission} from "../../interfaces/IVaultRegistry.sol";
import {MerkleBase} from "../../utils/MerkleBase.sol";
import {Multicall} from "../../utils/Multicall.sol";

/// @title BaseVault
/// @author Fraction Art
/// @notice Protoform contract for vault deployments with a fixed supply and buyout mechanism
contract BaseVault is IBaseVault, MerkleBase, Multicall {
    /// @notice Address of Buyout module contract
    address public buyout;
    /// @notice Address of VaultRegistry contract
    address public registry;
    /// @notice Address of Supply target contract
    address public supply;

    /// @notice Initializes BaseVault Protoform with supply, buyout, and registry contracts
    /// @param _buyout Address of the buyout module contract
    /// @param _registry Address of the VaultRegistry contract
    /// @param _supply Address of the supply target contract
    constructor(
        address _buyout,
        address _registry,
        address _supply
    ) {
        buyout = _buyout;
        registry = _registry;
        supply = _supply;
    }

    /// @notice Deploys a new Vault
    /// @param _fractionSupply Number of NFT Fractions minted to control the vault
    /// @param _modules The list of modules to be installed on the vault
    /// @param _mintProof List of proofs to execute a mint function
    function deployVault(
        uint256 _fractionSupply,
        IModule[] calldata _modules,
        address[] calldata plugins,
        bytes4[] calldata selectors,
        bytes32[] calldata _mintProof
    ) external returns (address vault) {
        bytes32[] memory leafNodes = generateMerkleTree(_modules);
        bytes32 merkleRoot = getRoot(leafNodes);
        vault = IVaultRegistry(registry).create(merkleRoot, plugins, selectors);
        emit ActiveModules(vault, _modules);

        _initializeVault(vault, _fractionSupply, _mintProof);
    }

    /// @notice Transfers ERC-20 tokens
    /// @param _from Source address
    /// @param _to Target address
    /// @param _tokens[] Addresses of token contracts
    /// @param _amounts[] Transfer amount
    function batchDepositERC20(
        address _from,
        address _to,
        address[] calldata _tokens,
        uint256[] calldata _amounts
    ) external {
        for (uint256 i = 0; i < _tokens.length; ) {
            IERC20(_tokens[i]).transferFrom(_from, _to, _amounts[i]);
            unchecked {
                ++i;
            }
        }
    }

    /// @notice Transfers ERC-721 tokens
    /// @param _from Source address
    /// @param _to Target address
    /// @param _tokens[] Addresses of token contracts
    /// @param _ids[] ID of the token
    function batchDepositERC721(
        address _from,
        address _to,
        address[] calldata _tokens,
        uint256[] calldata _ids
    ) external {
        for (uint256 i = 0; i < _tokens.length; ) {
            IERC721(_tokens[i]).safeTransferFrom(_from, _to, _ids[i]);
            unchecked {
                ++i;
            }
        }
    }

    /// @notice Transfers ERC-1155 tokens
    /// @param _from Source address
    /// @param _to Target address
    /// @param _tokens[] Addresses of token contracts
    /// @param _ids[] Ids of the token types
    /// @param _amounts[] Transfer amount
    /// @param _datas[] Additional transaction data
    function batchDepositERC1155(
        address _from,
        address _to,
        address[] calldata _tokens,
        uint256[] calldata _ids,
        uint256[] calldata _amounts,
        bytes[] calldata _datas
    ) external {
        unchecked {
            for (uint256 i = 0; i < _tokens.length; ++i) {
                IERC1155(_tokens[i]).safeTransferFrom(
                    _from,
                    _to,
                    _ids[i],
                    _amounts[i],
                    _datas[i]
                );
            }
        }
    }

    /// @notice Generates a merkle tree from the hashed permission lists of the given modules
    /// @return hashes A combined list of leaf nodes
    function generateMerkleTree(IModule[] calldata _modules)
        public
        view
        returns (bytes32[] memory hashes)
    {
        hashes = new bytes32[](6);
        unchecked {
            for (uint256 i; i < _modules.length; ++i) {
                bytes32[] memory leaves = _modules[i].getLeafNodes();
                for (uint256 j; j < leaves.length; ++j) {
                    hashes[i + j] = leaves[j];
                }
            }
        }
    }

    /// @notice View function to return the keccack256 hash of permissions installed on vaults deployed with this Protoform
    /// @return nodes A list of leaf nodes
    function getLeafNodes() public view returns (bytes32[] memory nodes) {
        nodes = new bytes32[](1);
        nodes[0] = keccak256(abi.encode(getPermissions()[0]));
    }

    /// @notice View function to return structs of permissions installed on vaults deployed with this Protoform
    /// @return permissions A list of Permission Structs
    function getPermissions()
        public
        view
        returns (Permission[] memory permissions)
    {
        permissions = new Permission[](6);
        permissions[0] = Permission(
            address(this),
            supply,
            ISupply(supply).mint.selector
        );
        Permission[] memory buyoutPermissions = IBuyout(buyout)
            .getPermissions();
        uint256 permissionsLength = buyoutPermissions.length;
        unchecked {
            for (uint256 i; i < permissionsLength; ++i) {
                permissions[i + 1] = buyoutPermissions[i];
            }
        }
    }

    /// @notice Initializes a new Vault and mints fractions
    /// @param _vault Address of the Vault
    /// @param _fractionSupply Number of NFT Fractions minted to control the vault
    /// @param _mintProof List of proofs to execute a mint function
    function _initializeVault(
        address _vault,
        uint256 _fractionSupply,
        bytes32[] calldata _mintProof
    ) private {
        bytes memory data = abi.encodeCall(
            ISupply(supply).mint,
            (msg.sender, _fractionSupply)
        );
        IVault(payable(_vault)).execute(supply, data, _mintProof);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {IModule} from "./IModule.sol";
import {IProtoform} from "./IProtoform.sol";
import {Permission} from "./IVaultRegistry.sol";

/// @dev Interface for BaseVault protoform contract
interface IBaseVault is IProtoform {
    /// @dev Event log for modules that are enabled on a vault
    /// @param _vault The vault deployed
    /// @param _modules The modules being activated on deployed vault
    event ActiveModules(address indexed _vault, IModule[] _modules);

    function batchDepositERC20(
        address _from,
        address _to,
        address[] memory _tokens,
        uint256[] memory _amounts
    ) external;

    function batchDepositERC721(
        address _from,
        address _to,
        address[] memory _tokens,
        uint256[] memory _ids
    ) external;

    function batchDepositERC1155(
        address _from,
        address _to,
        address[] memory _tokens,
        uint256[] memory _ids,
        uint256[] memory _amounts,
        bytes[] memory _datas
    ) external;

    function buyout() external view returns (address);

    function deployVault(
        uint256 _fractionSupply,
        IModule[] memory _modules,
        address[] calldata _plugins,
        bytes4[] calldata _selectors,
        bytes32[] memory _mintProof
    ) external returns (address vault);

    function getLeafNodes() external view returns (bytes32[] memory nodes);

    function getPermissions()
        external
        view
        returns (Permission[] memory permissions);

    function registry() external view returns (address);

    function supply() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {IModule} from "./IModule.sol";
import {Permission} from "./IVaultRegistry.sol";

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
    // Price of fractional tokens
    uint256 fractionPrice;
    // Balance of ether in buyout pool
    uint256 ethBalance;
    // Total supply recorded before a buyout started
    uint256 lastTotalSupply;
}

/// @dev Interface for Buyout module contract
interface IBuyout is IModule {
    /// @dev Emitted when the payment amount does not equal the fractional price
    error InvalidPayment();
    /// @dev Emitted when the buyout state is invalid
    error InvalidState(State _required, State _current);
    /// @dev Emitted when the caller has no balance of fractional tokens
    error NoFractions();
    /// @dev Emitted when the caller is not the winner of an auction
    error NotWinner();
    /// @dev Emitted when the address is not a registered vault
    error NotVault(address _vault);
    /// @dev Emitted when the time has expired for selling and buying fractions
    error TimeExpired(uint256 _current, uint256 _deadline);
    /// @dev Emitted when the buyout auction is still active
    error TimeNotElapsed(uint256 _current, uint256 _deadline);
    /// @dev Emitted when ether deposit amount for starting a buyout is zero
    error ZeroDeposit();

    /// @dev Event log for starting a buyout
    /// @param _vault Address of the vault
    /// @param _proposer Address that created the buyout
    /// @param _startTime Timestamp of when buyout was created
    /// @param _buyoutPrice Price of buyout pool in ether
    /// @param _fractionPrice Price of fractional tokens
    event Start(
        address indexed _vault,
        address indexed _proposer,
        uint256 _startTime,
        uint256 _buyoutPrice,
        uint256 _fractionPrice
    );
    /// @dev Event log for selling fractional tokens into the buyout pool
    /// @param _seller Address selling fractions
    /// @param _amount Transfer amount being sold
    event SellFractions(address indexed _seller, uint256 _amount);
    /// @dev Event log for buying fractional tokens from the buyout pool
    /// @param _buyer Address buying fractions
    /// @param _amount Transfer amount being bought
    event BuyFractions(address indexed _buyer, uint256 _amount);
    /// @dev Event log for ending an active buyout
    /// @param _state Enum state of auction
    /// @param _proposer Address that created the buyout
    event End(address _vault, State _state, address indexed _proposer);
    /// @dev Event log for cashing out ether for fractions from a successful buyout
    /// @param _casher Address cashing out of buyout
    /// @param _amount Transfer amount of ether
    event Cash(address _vault, address indexed _casher, uint256 _amount);
    /// @dev Event log for redeeming the underlying vault assets from an inactive buyout
    /// @param _redeemer Address redeeming underlying assets
    event Redeem(address _vault, address indexed _redeemer);

    function PROPOSAL_PERIOD() external view returns (uint256);

    function REJECTION_PERIOD() external view returns (uint256);

    function batchWithdrawERC1155(
        address _vault,
        address _token,
        address _to,
        uint256[] memory _ids,
        uint256[] memory _values,
        bytes32[] memory _erc1155BatchTransferProof
    ) external;

    function buyFractions(address _vault, uint256 _amount) external payable;

    function buyoutInfo(address)
        external
        view
        returns (
            uint256 startTime,
            address proposer,
            State state,
            uint256 fractionPrice,
            uint256 ethBalance,
            uint256 lastTotalSupply
        );

    function cash(address _vault, bytes32[] memory _burnProof) external;

    function end(address _vault, bytes32[] memory _burnProof) external;

    function getLeafNodes() external view returns (bytes32[] memory nodes);

    function getPermissions()
        external
        view
        returns (Permission[] memory permissions);

    function redeem(address _vault, bytes32[] memory _burnProof) external;

    function registry() external view returns (address);

    function sellFractions(address _vault, uint256 _amount) external;

    function start(address _vault) external payable;

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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

/// @dev Interface for ERC-20 token contract
interface IERC20 {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 amount
    );
    event Transfer(address indexed from, address indexed to, uint256 amount);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function allowance(address, address) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function balanceOf(address) external view returns (uint256);

    function decimals() external view returns (uint8);

    function name() external view returns (string memory);

    function nonces(address) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function symbol() external view returns (string memory);

    function totalSupply() external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

/// @dev Interface for ERC-721 token contract
interface IERC721 {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 indexed id
    );
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed id
    );

    function approve(address spender, uint256 id) external;

    function balanceOf(address owner) external view returns (uint256);

    function getApproved(uint256) external view returns (address);

    function isApprovedForAll(address, address) external view returns (bool);

    function name() external view returns (string memory);

    function ownerOf(uint256 id) external view returns (address owner);

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes memory data
    ) external;

    function setApprovalForAll(address operator, bool approved) external;

    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    function symbol() external view returns (string memory);

    function tokenURI(uint256 id) external view returns (string memory);

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

/// @dev Interface for ERC-1155 token contract
interface IERC1155 {
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] amounts
    );
    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 amount
    );
    event URI(string value, uint256 indexed id);

    function balanceOf(address, uint256) external view returns (uint256);

    function balanceOfBatch(address[] memory owners, uint256[] memory ids)
        external
        view
        returns (uint256[] memory balances);

    function isApprovedForAll(address, address) external view returns (bool);

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;

    function setApprovalForAll(address operator, bool approved) external;

    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {IModule} from "./IModule.sol";

/// @dev Interface for generic Protoform contract
interface IProtoform {
    function deployVault(
        uint256 _fAmount,
        IModule[] calldata _modules,
        address[] calldata _plugins,
        bytes4[] calldata _selectors,
        bytes32[] calldata _proof
    ) external returns (address vault);

    function generateMerkleTree(IModule[] calldata _modules)
        external
        view
        returns (bytes32[] memory hashes);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

/// @dev Interface for Supply target contract
interface ISupply {
    /// @dev Emitted when an account being called as an assumed contract does not have code and returns no data
    error MintError(address _account);
    /// @dev Emitted when an account being called as an assumed contract does not have code and returns no data
    error BurnError(address _account);

    function mint(address _to, uint256 _value) external;

    function burn(address _from, uint256 _value) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

/// @dev Interface for Vault proxy contract
interface IVault {
    /// @dev Emitted when execution reverted with no reason
    error ExecutionReverted();
    /// @dev Emitted when ownership of the proxy has been renounced
    error Initialized(address _owner, address _newOwner, uint256 _nonce);
    /// @dev Emitted when there is no implementation stored in methods for a function signature
    error MethodNotFound();
    /// @dev Emitted when the caller is not the owner
    error NotAuthorized(address _caller, address _target, bytes4 _selector);
    /// @dev Emitted when the caller is not the owner
    error NotOwner(address _owner, address _caller);
    /// @dev Emitted when the owner is changed during the DELEGATECALL
    error OwnerChanged(address _originalOwner, address _newOwner);
    /// @dev Emitted when passing an EOA or an undeployed contract as the target
    error TargetInvalid(address _target);

    /// @dev Event log for executing transactions
    /// @param _target Address of target contract
    /// @param _data Transaction data being executed
    /// @param _response Return data of delegatecall
    event Execute(address indexed _target, bytes _data, bytes _response);
    /// @dev Event log for installing plugins
    /// @param _selectors List of function selectors
    /// @param _plugins List of plugin contracts
    event InstallPlugin(bytes4[] _selectors, address[] _plugins);
    /// @dev Event log for transferring ownership
    /// @param _oldOwner Address of old owner
    /// @param _newOwner Address of new owner
    event TransferOwnership(
        address indexed _oldOwner,
        address indexed _newOwner
    );
    /// @dev Event log for uninstalling plugins
    /// @param _selectors List of function selectors
    event UninstallPlugin(bytes4[] _selectors);

    function execute(
        address _target,
        bytes memory _data,
        bytes32[] memory _proof
    ) external payable returns (bool success, bytes memory response);

    function init() external;

    function install(bytes4[] memory _selectors, address[] memory _plugins)
        external;

    function merkleRoot() external view returns (bytes32);

    function methods(bytes4) external view returns (address);

    function nonce() external view returns (uint256);

    function owner() external view returns (address);

    function setMerkleRoot(bytes32 _rootHash) external;

    function transferOwnership(address _newOwner) external;

    function uninstall(bytes4[] memory _selectors) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

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
    // Address of FERC1155 token contract
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
    event VaultDeployed(
        address indexed _vault,
        address indexed _token,
        uint256 _id
    );

    function burn(address _from, uint256 _value) external;

    function create(
        bytes32 _merkleRoot,
        address[] memory _plugins,
        bytes4[] memory _selectors
    ) external returns (address vault);

    function createCollection(
        bytes32 _merkleRoot,
        address[] memory _plugins,
        bytes4[] memory _selectors
    ) external returns (address vault, address token);

    function createCollectionFor(
        bytes32 _merkleRoot,
        address _controller,
        address[] memory _plugins,
        bytes4[] memory _selectors
    ) external returns (address vault, address token);

    function createFor(
        bytes32 _merkleRoot,
        address _owner,
        address[] memory _plugins,
        bytes4[] memory _selectors
    ) external returns (address vault);

    function createInCollection(
        bytes32 _merkleRoot,
        address _token,
        address[] memory _plugins,
        bytes4[] memory _selectors
    ) external returns (address vault);

    function factory() external view returns (address);

    function fNFT() external view returns (address);

    function fNFTImplementation() external view returns (address);

    function mint(address _to, uint256 _value) external;

    function nextId(address) external view returns (uint256);

    function totalSupply(address _vault) external view returns (uint256);

    function uri(address _vault) external view returns (string memory);

    function vaultToToken(address)
        external
        view
        returns (address token, uint256 id);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

/// @title Merkle Base
/// @author Modified from dmfxyz (https://github.com/dmfxyz/murky/blob/main/src/common/MurkyBase.sol)
/// @notice Utility contract for generating merkle roots and verifying proofs
abstract contract MerkleBase {
    /***************
     * CONSTRUCTOR *
     ***************/
    constructor() {}

    /********************
     * HASING FUNCTIONS *
     ********************/

    /// @notice Hashes two leaf pairs
    /// @param _left Node on left side of tree level
    /// @param _right Node on right side of tree level
    /// @return data Result hash of node params
    function hashLeafPairs(bytes32 _left, bytes32 _right)
        public
        pure
        returns (bytes32 data)
    {
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

    /**********************
     * PROOF VERIFICATION *
     **********************/

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

    /********************
     * PROOF GENERATION *
     ********************/

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
    /// @return Merkle proof
    function getProof(bytes32[] memory _data, uint256 _node)
        public
        pure
        returns (bytes32[] memory)
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

        bytes32[] memory arr = new bytes32[](size - counter);
        unchecked {
            uint256 offset;
            for (uint256 i; i < result.length; ++i) {
                if (result[i] != bytes32(0)) {
                    arr[i - offset] = result[i];
                } else {
                    ++offset;
                }
            }
        }

        return arr;
    }

    /// @notice Hashes nodes at the given tree level
    /// @param _data Nodes at the current level
    /// @return result Hashes of nodes at the next level
    function hashLevel(bytes32[] memory _data)
        internal
        pure
        returns (bytes32[] memory result)
    {
        // TODO: can store data.length to avoid mload calls
        if (_data.length % 2 == 1) {
            result = new bytes32[](_data.length / 2 + 1);
            result[result.length - 1] = hashLeafPairs(
                _data[_data.length - 1],
                bytes32(0)
            );
        } else {
            result = new bytes32[](_data.length / 2);
        }

        // pos is upper bounded by data.length / 2, so safe even if array is at max size
        unchecked {
            uint256 pos;
            for (uint256 i = 0; i < _data.length - 1; i += 2) {
                result[pos] = hashLeafPairs(_data[i], _data[i + 1]);
                ++pos;
            }
        }
    }

    /******************
     * MATH "LIBRARY" *
     ******************/

    /// @notice Calculates proof size based on size of tree
    /// @dev Note that x is assumed > 0 and proof size is not precise
    /// @param x Size of the merkle tree
    /// @return ceil Rounded value of proof size
    function log2ceil_naive(uint256 x) public pure returns (uint256 ceil) {
        uint256 lsb = (~x + 1) & x;
        bool powerOf2 = x == lsb;

        // if x == type(uint256).max, than ceil is capped at 256
        // if x == 0, then (~x + 1) & x == 0, so ceil won't underflow
        unchecked {
            while (x > 0) {
                x >>= 1;
                ceil++;
            }
            if (powerOf2) {
                ceil--;
            }
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.4;

/// @title Multicall
/// @author Modified from Uniswap (https://github.com/Uniswap/v3-periphery/blob/main/contracts/base/Multicall.sol)
/// @notice Utility contract that enables calling multiple local methods in a single call
abstract contract Multicall {
    /// @notice Allows multiple function calls within a contract that inherits from it
    /// @param _data List of encoded function calls to make in this contract
    /// @return results List of return responses for each encoded call passed
    function multicall(bytes[] calldata _data)
        external
        returns (bytes[] memory results)
    {
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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {Permission} from "./IVaultRegistry.sol";

/// @dev Interface for generic Module contract
interface IModule {
    function getLeafNodes() external view returns (bytes32[] memory nodes);

    function getPermissions()
        external
        view
        returns (Permission[] memory permissions);
}