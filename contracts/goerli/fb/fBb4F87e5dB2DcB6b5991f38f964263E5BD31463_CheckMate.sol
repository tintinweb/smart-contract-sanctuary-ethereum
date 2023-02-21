// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {NFTReceiver} from "src/utils/NFTReceiver.sol";
import {Protoform} from "src/protoforms/Protoform.sol";

import {ICheckMate, Stage} from "src/checks/interfaces/ICheckMate.sol";
import {IChecks} from "src/checks/interfaces/IChecks.sol";
import {IERC721} from "src/interfaces/IERC721.sol";
import {IERC1155} from "src/interfaces/IERC1155.sol";
import {ISupply} from "src/interfaces/ISupply.sol";
import {IVaultRegistry, InitInfo} from "src/interfaces/IVaultRegistry.sol";

/// @title CheckMate
/// @author Tessera
/// @notice Checks Protoform contract for reaching infinity
contract CheckMate is ICheckMate, Protoform, NFTReceiver {
    uint256 public constant MAX_SUPPLY = 4096;
    address public immutable registry;
    address public immutable checks;
    address public vault;
    uint88 public totalPoints;
    Stage public currentStage;
    mapping(address => uint256) public ownerToPoints;
    mapping(uint256 => address) public tokenIdToOwner;

    constructor(
        address _registry,
        address _supply,
        address _checks,
        address[] memory _modules
    ) {
        registry = _registry;
        checks = _checks;
        _deployVault(_supply, _modules);
    }

    function deposit(uint256[] calldata _tokenIds) external {
        if (currentStage != Stage.COLLECTING) revert InvalidStage(Stage.COLLECTING, currentStage);
        uint256 length = _tokenIds.length;

        unchecked {
            for (uint256 i; i < length; ++i) {
                uint256 tokenId = _tokenIds[i];
                IERC721(checks).transferFrom(msg.sender, address(this), tokenId);
                tokenIdToOwner[tokenId] = msg.sender;
                uint256 checkValue = getCheckValue(tokenId);
                ownerToPoints[msg.sender] += checkValue;
                totalPoints += uint88(checkValue);

                emit Deposit(msg.sender, tokenId, checkValue, totalPoints);
            }
        }

        if (totalPoints > MAX_SUPPLY) {
            revert TooManyPoints();
        } else if (totalPoints == MAX_SUPPLY) {
            currentStage = Stage.BURNING;
        }
    }

    function withdraw(uint256[] calldata _tokenIds) external {
        if (currentStage != Stage.COLLECTING) revert InvalidStage(Stage.COLLECTING, currentStage);
        uint256 length = _tokenIds.length;

        unchecked {
            for (uint256 i; i < length; ++i) {
                uint256 tokenId = _tokenIds[i];
                if (tokenIdToOwner[tokenId] != msg.sender) revert NotOwner();
                delete tokenIdToOwner[tokenId];
                IERC721(checks).transferFrom(address(this), msg.sender, tokenId);
                uint256 checkValue = getCheckValue(tokenId);
                ownerToPoints[msg.sender] -= checkValue;
                totalPoints -= uint88(checkValue);

                emit Withdraw(msg.sender, tokenId, checkValue, totalPoints);
            }
        }
    }

    function compositeMany(uint256[] calldata _tokenIds, uint256[] calldata _burnIds) external {
        if (currentStage != Stage.BURNING) revert InvalidStage(Stage.BURNING, currentStage);
        IChecks(checks).compositeMany(_tokenIds, _burnIds);

        emit CompositeMany(_tokenIds, _burnIds);
    }

    function infinity(uint256[] calldata _tokenIds) external {
        if (currentStage != Stage.BURNING) revert InvalidStage(Stage.BURNING, currentStage);
        uint256[] memory tokenIds = sort(_tokenIds, 0, _tokenIds.length);
        uint256 lowestId = tokenIds[0];

        IChecks(checks).infinity(tokenIds);
        IERC721(checks).transferFrom(address(this), vault, lowestId);
        currentStage = Stage.CLAIMING;

        emit Infinity(_tokenIds, lowestId);
    }

    function claim(address _owner) external {
        if (currentStage != Stage.CLAIMING) revert InvalidStage(Stage.CLAIMING, currentStage);
        uint256 points = ownerToPoints[_owner];
        delete ownerToPoints[_owner];

        (address rae, uint256 id) = IVaultRegistry(registry).vaultToToken(vault);
        IERC1155(rae).safeTransferFrom(address(this), _owner, id, points, "");

        emit Claim(msg.sender, points);
    }

    function getCheckValue(uint256 _tokenId) public view returns (uint256 value) {
        IChecks.Check memory check = IChecks(checks).getCheck(_tokenId);
        value = 2**check.stored.divisorIndex;
    }

    function sort(
        uint256[] memory _array,
        uint256 _begin,
        uint256 _last
    ) public pure returns (uint256[] memory) {
        if (_begin < _last) {
            uint256 j = _begin;
            uint256 pivot = _array[j];
            for (uint256 i = _begin + 1; i < _last; ) {
                if (_array[i] < pivot) _swap(_array, i, ++j);

                unchecked {
                    ++i;
                }
            }

            _swap(_array, _begin, j);
            sort(_array, _begin, j);
            sort(_array, j + 1, _last);
        }

        return _array;
    }

    function _swap(
        uint256[] memory _array,
        uint256 i,
        uint256 j
    ) internal pure {
        (_array[i], _array[j]) = (_array[j], _array[i]);
    }

    function _deployVault(address _supply, address[] memory _modules) private {
        bytes32[] memory leafNodes = generateMerkleTree(_modules);
        bytes32 merkleRoot = getRoot(leafNodes);

        InitInfo[] memory initInfo = new InitInfo[](1);
        initInfo[0] = InitInfo({
            target: _supply,
            data: abi.encodeCall(ISupply.mint, (address(this), MAX_SUPPLY)),
            proof: new bytes32[](0)
        });

        vault = IVaultRegistry(registry).create(merkleRoot, initInfo);

        emit ActiveModules(vault, _modules);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

enum Stage {
    COLLECTING,
    BURNING,
    CLAIMING
}

/// @dev Interface for CheckMate protoform contract
interface ICheckMate {
    error InvalidStage(Stage _required, Stage _current);
    error NotOwner();
    error TooManyPoints();

    event Deposit(
        address indexed _owner,
        uint256 indexed _tokenId,
        uint256 indexed _checkValue,
        uint88 _totalPoints
    );
    event Withdraw(
        address indexed _owner,
        uint256 indexed _tokenId,
        uint256 indexed _checkValue,
        uint88 _totalPoints
    );
    event CompositeMany(uint256[] indexed _tokenIds, uint256[] indexed _burnIds);
    event Infinity(uint256[] indexed _tokenIds, uint256 indexed _lowestId);
    event Claim(address indexed _owner, uint256 indexed _points);

    function MAX_SUPPLY() external view returns (uint256);

    function checks() external view returns (address);

    function claim(address _owner) external;

    function compositeMany(uint256[] calldata _tokenIds, uint256[] calldata _burnIds) external;

    function currentStage() external view returns (Stage);

    function deposit(uint256[] calldata _tokenIds) external;

    function getCheckValue(uint256 _tokenId) external view returns (uint256);

    function infinity(uint256[] calldata _tokenIds) external;

    function ownerToPoints(address) external view returns (uint256);

    function registry() external view returns (address);

    function tokenIdToOwner(uint256) external view returns (address);

    function totalPoints() external view returns (uint88);

    function vault() external view returns (address);

    function withdraw(uint256[] calldata _tokenIds) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

/// @dev Interface for Checks contract
interface IChecks {
    struct StoredCheck {
        uint32 seed; // The seed is based the mint and enables pseudo-randomisation
        uint16[6] composites; // The tokenIds that were composited into this one
        uint8[6] colorBands; // The length of the used color band in percent
        uint8[6] gradients; // Gradient settings for each generation
        uint8 divisorIndex; // Easy access to next / previous divisor
        uint8 animation; // Animation seed
    }

    struct Check {
        StoredCheck stored;
        uint16 composite; // The parent tokenId that was composited into this one
        bool hasManyChecks; // Quick access for whether the check has many checks
        uint8 checksCount; // How many checks this token has
        uint8 colorBand; // 100%, 50%, 25%, 12.5%, 6.25%, 5%, 1.25%
        uint8 gradient; // Linearly through the colorBand [1, 2, 3]
        uint8 direction; // Animation direction
        uint8 speed; // Animation speed
    }

    struct Checks {
        uint32 minted;
        uint32 burned;
        mapping(uint256 => StoredCheck) all;
    }

    event Sacrifice(uint256 indexed burnedId, uint256 indexed tokenId);

    event Composite(uint256 indexed tokenId, uint256 indexed burnedId, uint8 indexed checks);

    event Infinity(uint256 indexed tokenId, uint256[] indexed burnedIds);

    function compositeMany(uint256[] calldata _tokenIds, uint256[] calldata _burnIds) external;

    function getCheck(uint256 _tokenId) external view returns (Check memory);

    function infinity(uint256[] calldata _tokenIds) external;

    function mint(uint256[] calldata _tokenIds) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {Permission} from "./IVaultRegistry.sol";

/// @dev Interface for generic Module contract
interface IModule {
    function getLeaves() external view returns (bytes32[] memory leaves);

    function getUnhashedLeaves() external view returns (bytes[] memory leaves);

    function getPermissions() external view returns (Permission[] memory permissions);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {InitInfo} from "./IVault.sol";

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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {MerkleBase} from "src/utils/MerkleBase.sol";
import {IModule} from "src/interfaces/IModule.sol";
import {IProtoform} from "src/interfaces/IProtoform.sol";

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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {ERC721TokenReceiver} from "solmate/tokens/ERC721.sol";
import {ERC1155TokenReceiver} from "solmate/tokens/ERC1155.sol";

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