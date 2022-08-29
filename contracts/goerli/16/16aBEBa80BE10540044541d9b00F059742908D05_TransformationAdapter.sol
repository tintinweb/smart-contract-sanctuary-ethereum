// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Minimalist and gas efficient standard ERC1155 implementation.
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC20.sol)
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

/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
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
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
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

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7;

import { ConduitControllerInterface } from "seaport/contracts/interfaces/ConduitControllerInterface.sol";
import { ConduitInterface } from "seaport/contracts/interfaces/ConduitInterface.sol";
import { ConduitTransfer } from "seaport/contracts/conduit/lib/ConduitStructs.sol";
import { ConduitItemType } from "seaport/contracts/conduit/lib/ConduitEnums.sol";

contract ConduitAdapter {
    // Allow for interaction with the conduit controller.
    ConduitControllerInterface private immutable _CONDUIT_CONTROLLER;
    // Cache the conduit creation hash used by the conduit controller.
    bytes32 private immutable _CONDUIT_CREATION_CODE_HASH;

    constructor(address _conduitController) {
        // Get the conduit creation code hash from the supplied conduit
        // controller and set it as an immutable.
        ConduitControllerInterface conduitController = ConduitControllerInterface(
            _conduitController
        );
        (_CONDUIT_CREATION_CODE_HASH, ) = conduitController.getConduitCodeHashes();

        // Set the supplied conduit controller as an immutable.
        _CONDUIT_CONTROLLER = conduitController;
    }

    /// @dev This function derives the conduit address from the deployer,
    ///      conduit key, and creation code hash.
    function _getConduit(bytes32 conduitKey) internal view returns (address conduit) {
        conduit = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            bytes1(0xff),
                            address(_CONDUIT_CONTROLLER),
                            conduitKey,
                            _CONDUIT_CREATION_CODE_HASH
                        )
                    )
                )
            )
        );
    }

    /// @dev This function transfers an ERC20 using a Seaport
    ///      Conduit to source approval.
    /// @notice Only use `msg.sender` or `address(this)` in the from param.
    /// @param token        The ERC20 token to transfer.
    /// @param from         The originator of the transfer.
    /// @param to           The recipient of the transfer.
    /// @param amount       The amount of ERC20 to be sent.
    /// @param conduitKey   The key of the conduit to used.
    function _transferERC20WithConduit(
        address token,
        address from,
        address to,
        uint256 amount,
        bytes32 conduitKey
    ) internal {
        address conduit = _getConduit(conduitKey);

        ConduitTransfer[] memory conduitTransfers = new ConduitTransfer[](1);
        conduitTransfers[0] = ConduitTransfer(
            ConduitItemType.ERC20,
            token,
            from,
            to,
            0,
            amount
        );

        // Call the conduit and execute transfer.
        ConduitInterface(conduit).execute(conduitTransfers);
    }

    /// @dev This function transfers an ERC721 token using a Seaport
    ///      Conduit to source approval.
    /// @notice Only use `msg.sender` or `address(this)` in the from param.
    /// @param token        The ERC721 token to transfer.
    /// @param from         The originator of the transfer.
    /// @param to           The recipient of the transfer.
    /// @param tokenId      The tokenId of the ERC721 to be sent.
    /// @param conduitKey   The key of the conduit to used.
    function _transferERC721WithConduit(
        address token,
        address from,
        address to,
        uint256 tokenId,
        bytes32 conduitKey
    ) internal {
        address conduit = _getConduit(conduitKey);

        ConduitTransfer[] memory conduitTransfers = new ConduitTransfer[](1);
        conduitTransfers[0] = ConduitTransfer(
            ConduitItemType.ERC721,
            token,
            from,
            to,
            tokenId,
            1
        );

        // Call the conduit and execute transfer.
        ConduitInterface(conduit).execute(conduitTransfers);
    }

    /// @dev This function transfers an ERC1155 token using a Seaport
    ///      Conduit to source approval.
    /// @notice Only use `msg.sender` or `address(this)` in the from param.
    /// @param token        The ERC1155 token to transfer.
    /// @param from         The originator of the transfer.
    /// @param to           The recipient of the transfer.
    /// @param tokenId      The tokenId of the ERC1155 to be sent.
    /// @param amount       The amount of the ERC1155 to be sent.
    /// @param conduitKey   The key of the conduit to used.
    function _transferERC1155WithConduit(
        address token,
        address from,
        address to,
        uint256 tokenId,
        uint256 amount,
        bytes32 conduitKey
    ) internal {
        address conduit = _getConduit(conduitKey);

        ConduitTransfer[] memory conduitTransfers = new ConduitTransfer[](1);
        conduitTransfers[0] = ConduitTransfer(
            ConduitItemType.ERC1155,
            token,
            from,
            to,
            tokenId,
            amount
        );

        // Call the conduit and execute transfer.
        ConduitInterface(conduit).execute(conduitTransfers);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7;

import "@rari-capital/solmate/src/tokens/ERC20.sol";
import "@rari-capital/solmate/src/tokens/ERC721.sol";
import "@rari-capital/solmate/src/tokens/ERC1155.sol";
import "./ConduitAdapter.sol";
import { TokenSource } from "../../lib/LibShoyu.sol";

contract TransferAdapter is ConduitAdapter {
    constructor(address _conduitController) ConduitAdapter(_conduitController) {}

    /// @dev Function to transfer ERC20 tokens from `msg.sender`
    ///      to a given recipient. Assets can be transferred from
    ///      a user's wallet with approvals being sourced from
    ///      Shoyu contract or Shoyu's Seaport Conduit.
    /// @param token        The ERC20 token to transfer.
    /// @param to           The recipient of the transfer.
    /// @param amount       The amount to transfer.
    /// @param source       The token / approval source.
    /// @param data         Additional encoded data required depending on `source`.
    function transferERC20From(
        address token,
        address to,
        uint256 amount,
        TokenSource source,
        bytes memory data
    ) public {
        if (source == TokenSource.WALLET) {
            ERC20(token).transferFrom(msg.sender, to, amount);
        } else if (source == TokenSource.CONDUIT) {
            bytes32 conduitKey = abi.decode(data, (bytes32));

            _transferERC20WithConduit(
                token,
                msg.sender,
                to,
                amount,
                conduitKey
            );
        }
    }

    /// @dev Function to transfer an ERC721 token from `msg.sender`
    ///      to a given recipient. Assets will be transferred from
    ///      a user's wallet with approvals being sourced from the
    ///      Shoyu contract or Seaport Conduit.
    /// @param token        The ERC721 token to transfer.
    /// @param to           The recipient of the transfer.
    /// @param tokenId      The tokenId of the asset to transfer.
    /// @param source       The NFT approval source.
    /// @param data         Additional encoded data required depending on `source`.
    function transferERC721From(
        address token,
        address to,
        uint256 tokenId,
        TokenSource source,
        bytes memory data
    ) public {
        if (source == TokenSource.WALLET) {
            ERC721(token).safeTransferFrom(
                msg.sender,
                to,
                tokenId
            );
        } else if (source == TokenSource.CONDUIT) {
            bytes32 conduitKey = abi.decode(data, (bytes32));

            _transferERC721WithConduit(
                token,
                msg.sender,
                to,
                tokenId,
                conduitKey
            );
        }
    }

    /// @dev Function to transfer an ERC1155 token from `msg.sender`
    ///      to a given recipient. Assets will be transferred from
    ///      a user's wallet with approvals being sourced from the
    ///      Shoyu contract or Seaport Conduit.
    /// @param token        The ERC1155 token to transfer.
    /// @param to           The recipient of the transfer.
    /// @param tokenId      The tokenId of the asset to transfer.
    /// @param amount       The amount of the asset to transfer.
    /// @param source       The NFT approval source.
    /// @param data         Additional encoded data required depending on `source`.
    function transferERC1155From(
        address token,
        address to,
        uint256 tokenId,
        uint256 amount,
        TokenSource source,
        bytes memory data
    ) public {
        if (source == TokenSource.WALLET) {
            ERC1155(token).safeTransferFrom(
                msg.sender,
                to,
                tokenId,
                amount,
                "0x"
            );
        } else if (source == TokenSource.CONDUIT) {
           bytes32 conduitKey = abi.decode(data, (bytes32));

           _transferERC1155WithConduit(
                token,
                msg.sender,
                to,
                tokenId,
                amount,
                conduitKey
            );
        }
    }

    /// @dev Function to return any excess ERC20 tokens from address(this)
    ///      to `msg.sender`.
    /// @param token        The token to return to the caller.
    function returnERC20(address token) external {
        uint256 balance = ERC20(token).balanceOf(address(this));
        if (balance > 0) {
            ERC20(token).transfer(msg.sender, balance);
        }
    }

    /// @dev Function to return any left over ERC721 token from
    ///      address(this) to `msg.sender`.
    /// @param token        The token to return to the caller.
    /// @param tokenId      The token identifier of the asset.
    function returnERC721(address token, uint256 tokenId) external {
        if (ERC721(token).ownerOf(tokenId) == address(this)) {
            ERC721(token).transferFrom(address(this), msg.sender, tokenId);
        }
    }

    /// @dev Function to return any excess ERC1155 token from
    ///      address(this) to `msg.sender`.
    /// @param token        The token to return to the caller.
    /// @param tokenId      The token identifier of the asset.
    function returnERC1155(address token, uint256 tokenId) external {
        uint256 balance = ERC1155(token).balanceOf(address(this), tokenId);
        if (balance > 0) {
            ERC1155(token).safeTransferFrom(
                address(this),
                msg.sender,
                tokenId,
                balance,
                ""
            );
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7;

import "@sushiswap/core/contracts/uniswapv2/interfaces/IUniswapV2Pair.sol";
import "../Transfer/ConduitAdapter.sol";
import "../Transfer/TransferAdapter.sol";
import { pairFor, sortTokens, getAmountsIn, getAmountsOut } from "../../lib/LibSushi.sol";
import { TokenSource } from "../../lib/LibShoyu.sol";

contract LegacySwapAdapter is TransferAdapter {
    /// @dev The UniswapV2Factory address.
    address private immutable factory;
    /// @dev The UniswapV2 pair init code.
    bytes32 private immutable pairCodeHash;

    constructor(
        address _factory,
        bytes32 _pairCodeHash,
        address _conduitController
    ) TransferAdapter (_conduitController) {
        factory = _factory;
        pairCodeHash = _pairCodeHash;
    }

    /// @dev This function transfers the input token from msg.sender and
    ///      performs the swaps outlined in `path`. An exact amount of the
    ///      output token is sent to the specified recipient.
    /// @param amountOut        The exact amount of output token to receive.
    /// @param amountInMax      The maximum amount of input to be spent.
    /// @param path             The swap path.
    /// @param to               The recipient to receive output token.
    /// @param tokenSource      The token / approval source for input token.
    /// @param transferData     Additional data required depending on `source`.
    function _legacySwapExactOut(
        uint256 amountOut,
        uint256 amountInMax,
        address[] memory path,
        address to,
        TokenSource tokenSource,
        bytes memory transferData
    ) internal returns (uint256 amountIn) {
        uint256[] memory amounts = getAmountsIn(
            factory,
            amountOut,
            path,
            pairCodeHash
        );
        amountIn = amounts[0];

        require(amountIn <= amountInMax, '_legacySwapExactOut/EXCESSIVE_AMOUNT_IN');

        transferERC20From(
            path[0],
            pairFor(
                factory,
                path[0],
                path[1],
                pairCodeHash
            ),
            amountIn,
            tokenSource,
            transferData
        );

        _swap(amounts, path, to);
    }

    /// @dev This function transfers an exact amount of the input token
    ///      from address(this) and performs the swaps outlined in `path`.
    ///      The output token is sent to the specified recipient.
    /// @param amountIn         The exact amount of input token to be spent.
    /// @param amountOutMin     The minimum amount of output token to be received.
    /// @param path             The swap path.
    /// @param to               The recipient of output token.
    function _legacySwapExactIn(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] memory path,
        address to
    ) internal returns (uint256 amountOut) {
        uint256[] memory amounts = getAmountsOut(
            factory,
            amountIn,
            path,
            pairCodeHash
        );
        amountOut = amounts[amounts.length - 1];

        require(amountOut >= amountOutMin, "_legacySwapExactIn/EXCESSIVE_AMOUNT_OUT");

        ERC20(path[0]).transfer(
            pairFor(
                factory,
                path[0],
                path[1],
                pairCodeHash
            ),
            amountIn
        );

        _swap(amounts, path, to);
    }

    /// @dev Performs swaps as outlined in `path` and sends the output
    ///      token to the specified recipient.
    /// @notice Requires the initial amount to have already been sent to the
    ///         first pair.
    /// @param amounts  The amounts to be swapped.
    /// @param path     The swap path.
    /// @param _to      The recipient of output token.
    function _swap(
        uint256[] memory amounts,
        address[] memory path,
        address _to
    ) internal virtual {
        for (uint256 i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);

            (address token0, ) = sortTokens(input, output);

            uint256 amountOut = amounts[i + 1];

            (uint256 amount0Out, uint256 amount1Out) = input == token0
                ? (uint256(0), amountOut)
                : (amountOut, uint256(0));
            address to = i < path.length - 2 ? pairFor(factory, output, path[i + 2], pairCodeHash) : _to;

            IUniswapV2Pair(pairFor(factory, input, output, pairCodeHash)).swap(
                amount0Out,
                amount1Out,
                to,
                new bytes(0)
            );
        }
    }

    
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.11;

import "@sushiswap/core/contracts/uniswapv2/interfaces/IWETH.sol";
import "./LegacySwapAdapter.sol";

contract TransformationAdapter is LegacySwapAdapter {
    /// @dev The WETH address.
    address private immutable WETH;

    constructor(
        address _weth,
        address _factory,
        bytes32 _pairCodeHash,
        address _conduitController
    ) LegacySwapAdapter(
        _factory,
        _pairCodeHash,
        _conduitController
    ) {
        WETH = _weth;
    }

    /// @dev This function swaps ERC20 tokens from msg.sender
    ///      for an exact amount of output tokens, sent
    ///      to the specified recipient.
    /// @param amountOut        The exact amount of output token to receive.
    /// @param amountInMax      The maximum amount of input to be spent.
    /// @param path             The swap path.
    /// @param to               The recipient to receive output token.
    /// @param tokenSource      The token / approval source for input token.
    /// @param transferData     Additional data required depending on `source`.
    /// @param unwrapNative     Flag to unwrap for native token if output token is WETH.
    function swapExactOut(
        uint256 amountOut,
        uint256 amountInMax,
        address[] memory path,
        address payable to,
        TokenSource tokenSource,
        bytes memory transferData,
        bool unwrapNative
    ) public payable {
        _legacySwapExactOut(
            amountOut,
            amountInMax,
            path,
            unwrapNative ? address(this) : to,
            tokenSource,
            transferData
        );

        if (unwrapNative) {
            IWETH(WETH).withdraw(amountOut);
            if (to != address(this)) {
                to.transfer(amountOut);
            }
        }
    }

    /// @dev This function swaps an exact amount of tokens from address(this)
    ///      and sends a mimimum amount of output token to the specified recipient.
    /// @param amountIn         The exact amount of input token to be spent.
    /// @param amountOutMin     The minimum amount of output token to be received.
    /// @param path             The swap path.
    /// @param to               The recipient of output token.
    /// @param unwrapNative     Flag to unwrap for native token if output token is WETH.
    function swapExactIn(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] memory path,
        address payable to,
        bool unwrapNative
    ) public payable {
        uint256 amountOut = _legacySwapExactIn(
            amountIn,
            amountOutMin,
            path,
            unwrapNative ? address(this) : to
        );

        if (unwrapNative) {
            IWETH(WETH).withdraw(amountOut);
            if (to != address(this)) {
                to.transfer(amountOut);
            }
        }
    }

    /// @dev This function performs the swaps as outlined in `path`. This contract's
    ///      entire balance of input token will be swapped for a minimum amount of
    ///      output token, sent to the specified recipient.
    /// @param amountOutMin     The minimum amount of output token to be received.
    /// @param path             The swap path.
    /// @param to               The recipient of output token.
    /// @param unwrapNative     Flag to unwrap for native token if output token is WETH.
    function swapMaxIn(
        uint256 amountOutMin,
        address[] memory path,
        address payable to,
        bool unwrapNative
    ) public payable {
        uint256 amountOut = _legacySwapExactIn(
            ERC20(path[0]).balanceOf(address(this)),
            amountOutMin,
            path,
            unwrapNative ? address(this) : to
        );

        if (unwrapNative) {
            IWETH(WETH).withdraw(amountOut);
            if (to != address(this)) {
                to.transfer(amountOut);
            }
        }

    }

    /// @dev This function unwraps WETH held by address(this)
    ///      and transfers ETH to the specified recipient.
    /// @param amount       The amount of WETH to be unwrapped.
    /// @param to           The ETH recipient.
    function unwrapNativeToken(
        uint256 amount,
        address payable to
    ) public {
        IWETH(WETH).withdraw(amount);
        if (to != address(this)) {
            to.transfer(amount);
        }
    }

    /// @dev This function wraps ETH held by address(this).
    /// @param amount       The amount of ETH to wrap
    function wrapNativeToken(uint256 amount) public payable {
        IWETH(WETH).deposit{value: amount}();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

enum TokenSource {
    WALLET,
    CONDUIT
}

struct Adapter {
    address adapterAddress;
    bool isActive;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

// Adapted from: https://github.com/sushiswap/limit-order/blob/a901749362691acd307f2370a876a33d33cde53e/contracts/libraries/UniswapV2Library.sol

import "@sushiswap/core/contracts/uniswapv2/interfaces/IUniswapV2Pair.sol";

// returns sorted token addresses, used to handle return values from pairs sorted in this order
function sortTokens(
    address tokenA,
    address tokenB
) pure returns (address token0, address token1) {
    require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
    (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
    require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
}

// calculates the CREATE2 address for a pair without making any external calls
function pairFor(
    address factory,
    address tokenA,
    address tokenB,
    bytes32 pairCodeHash
) pure returns (address pair) {
    (address token0, address token1) = sortTokens(tokenA, tokenB);
    pair = address(uint160(uint(keccak256(abi.encodePacked(
            hex'ff',
            factory,
            keccak256(abi.encodePacked(token0, token1)),
            pairCodeHash // init code hash
        )))));
}

// fetches and sorts the reserves for a pair
function getReserves(
    address factory,
    address tokenA,
    address tokenB,
    bytes32 pairCodeHash
) view returns (uint reserveA, uint reserveB) {
    (address token0,) = sortTokens(tokenA, tokenB);
    (uint reserve0, uint reserve1,) = IUniswapV2Pair(pairFor(factory, tokenA, tokenB, pairCodeHash)).getReserves();
    (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
}

// given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
function getAmountOut(
    uint amountIn,
    uint reserveIn,
    uint reserveOut
) pure returns (uint amountOut) {
    require(amountIn > 0, 'UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT');
    require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
    uint amountInWithFee = amountIn* 997;
    uint numerator = amountInWithFee * reserveOut;
    uint denominator = reserveIn * 1000 + amountInWithFee;
    amountOut = numerator / denominator;
}

// given an output amount of an asset and pair reserves, returns a required input amount of the other asset
function getAmountIn(
    uint amountOut,
    uint reserveIn,
    uint reserveOut
) pure returns (uint amountIn) {
    require(amountOut > 0, 'UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT');
    require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
    uint numerator = reserveIn * amountOut * 1000;
    uint denominator = (reserveOut - amountOut) * 997;
    amountIn = numerator / denominator + 1;
}

// performs chained getAmountOut calculations on any number of pairs
function getAmountsOut(
    address factory,
    uint amountIn,
    address[] memory path,
    bytes32 pairCodeHash
) view returns (uint[] memory amounts) {
    require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
    amounts = new uint[](path.length);
    amounts[0] = amountIn;
    for (uint i; i < path.length - 1; i++) {
        (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1], pairCodeHash);
        amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
    }
}

// performs chained getAmountIn calculations on any number of pairs
function getAmountsIn(
    address factory,
    uint amountOut,
    address[] memory path,
    bytes32 pairCodeHash
) view returns (uint[] memory amounts) {
    require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
    amounts = new uint[](path.length);
    amounts[amounts.length - 1] = amountOut;
    for (uint i = path.length - 1; i > 0; i--) {
        (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i], pairCodeHash);
        amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

enum ConduitItemType {
    NATIVE, // unused
    ERC20,
    ERC721,
    ERC1155
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import { ConduitItemType } from "./ConduitEnums.sol";

struct ConduitTransfer {
    ConduitItemType itemType;
    address token;
    address from;
    address to;
    uint256 identifier;
    uint256 amount;
}

struct ConduitBatch1155Transfer {
    address token;
    address from;
    address to;
    uint256[] ids;
    uint256[] amounts;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/**
 * @title ConduitControllerInterface
 * @author 0age
 * @notice ConduitControllerInterface contains all external function interfaces,
 *         structs, events, and errors for the conduit controller.
 */
interface ConduitControllerInterface {
    /**
     * @dev Track the conduit key, current owner, new potential owner, and open
     *      channels for each deployed conduit.
     */
    struct ConduitProperties {
        bytes32 key;
        address owner;
        address potentialOwner;
        address[] channels;
        mapping(address => uint256) channelIndexesPlusOne;
    }

    /**
     * @dev Emit an event whenever a new conduit is created.
     *
     * @param conduit    The newly created conduit.
     * @param conduitKey The conduit key used to create the new conduit.
     */
    event NewConduit(address conduit, bytes32 conduitKey);

    /**
     * @dev Emit an event whenever conduit ownership is transferred.
     *
     * @param conduit       The conduit for which ownership has been
     *                      transferred.
     * @param previousOwner The previous owner of the conduit.
     * @param newOwner      The new owner of the conduit.
     */
    event OwnershipTransferred(
        address indexed conduit,
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Emit an event whenever a conduit owner registers a new potential
     *      owner for that conduit.
     *
     * @param newPotentialOwner The new potential owner of the conduit.
     */
    event PotentialOwnerUpdated(address indexed newPotentialOwner);

    /**
     * @dev Revert with an error when attempting to create a new conduit using a
     *      conduit key where the first twenty bytes of the key do not match the
     *      address of the caller.
     */
    error InvalidCreator();

    /**
     * @dev Revert with an error when attempting to create a new conduit when no
     *      initial owner address is supplied.
     */
    error InvalidInitialOwner();

    /**
     * @dev Revert with an error when attempting to set a new potential owner
     *      that is already set.
     */
    error NewPotentialOwnerAlreadySet(
        address conduit,
        address newPotentialOwner
    );

    /**
     * @dev Revert with an error when attempting to cancel ownership transfer
     *      when no new potential owner is currently set.
     */
    error NoPotentialOwnerCurrentlySet(address conduit);

    /**
     * @dev Revert with an error when attempting to interact with a conduit that
     *      does not yet exist.
     */
    error NoConduit();

    /**
     * @dev Revert with an error when attempting to create a conduit that
     *      already exists.
     */
    error ConduitAlreadyExists(address conduit);

    /**
     * @dev Revert with an error when attempting to update channels or transfer
     *      ownership of a conduit when the caller is not the owner of the
     *      conduit in question.
     */
    error CallerIsNotOwner(address conduit);

    /**
     * @dev Revert with an error when attempting to register a new potential
     *      owner and supplying the null address.
     */
    error NewPotentialOwnerIsZeroAddress(address conduit);

    /**
     * @dev Revert with an error when attempting to claim ownership of a conduit
     *      with a caller that is not the current potential owner for the
     *      conduit in question.
     */
    error CallerIsNotNewPotentialOwner(address conduit);

    /**
     * @dev Revert with an error when attempting to retrieve a channel using an
     *      index that is out of range.
     */
    error ChannelOutOfRange(address conduit);

    /**
     * @notice Deploy a new conduit using a supplied conduit key and assigning
     *         an initial owner for the deployed conduit. Note that the first
     *         twenty bytes of the supplied conduit key must match the caller
     *         and that a new conduit cannot be created if one has already been
     *         deployed using the same conduit key.
     *
     * @param conduitKey   The conduit key used to deploy the conduit. Note that
     *                     the first twenty bytes of the conduit key must match
     *                     the caller of this contract.
     * @param initialOwner The initial owner to set for the new conduit.
     *
     * @return conduit The address of the newly deployed conduit.
     */
    function createConduit(bytes32 conduitKey, address initialOwner)
        external
        returns (address conduit);

    /**
     * @notice Open or close a channel on a given conduit, thereby allowing the
     *         specified account to execute transfers against that conduit.
     *         Extreme care must be taken when updating channels, as malicious
     *         or vulnerable channels can transfer any ERC20, ERC721 and ERC1155
     *         tokens where the token holder has granted the conduit approval.
     *         Only the owner of the conduit in question may call this function.
     *
     * @param conduit The conduit for which to open or close the channel.
     * @param channel The channel to open or close on the conduit.
     * @param isOpen  A boolean indicating whether to open or close the channel.
     */
    function updateChannel(
        address conduit,
        address channel,
        bool isOpen
    ) external;

    /**
     * @notice Initiate conduit ownership transfer by assigning a new potential
     *         owner for the given conduit. Once set, the new potential owner
     *         may call `acceptOwnership` to claim ownership of the conduit.
     *         Only the owner of the conduit in question may call this function.
     *
     * @param conduit The conduit for which to initiate ownership transfer.
     * @param newPotentialOwner The new potential owner of the conduit.
     */
    function transferOwnership(address conduit, address newPotentialOwner)
        external;

    /**
     * @notice Clear the currently set potential owner, if any, from a conduit.
     *         Only the owner of the conduit in question may call this function.
     *
     * @param conduit The conduit for which to cancel ownership transfer.
     */
    function cancelOwnershipTransfer(address conduit) external;

    /**
     * @notice Accept ownership of a supplied conduit. Only accounts that the
     *         current owner has set as the new potential owner may call this
     *         function.
     *
     * @param conduit The conduit for which to accept ownership.
     */
    function acceptOwnership(address conduit) external;

    /**
     * @notice Retrieve the current owner of a deployed conduit.
     *
     * @param conduit The conduit for which to retrieve the associated owner.
     *
     * @return owner The owner of the supplied conduit.
     */
    function ownerOf(address conduit) external view returns (address owner);

    /**
     * @notice Retrieve the conduit key for a deployed conduit via reverse
     *         lookup.
     *
     * @param conduit The conduit for which to retrieve the associated conduit
     *                key.
     *
     * @return conduitKey The conduit key used to deploy the supplied conduit.
     */
    function getKey(address conduit) external view returns (bytes32 conduitKey);

    /**
     * @notice Derive the conduit associated with a given conduit key and
     *         determine whether that conduit exists (i.e. whether it has been
     *         deployed).
     *
     * @param conduitKey The conduit key used to derive the conduit.
     *
     * @return conduit The derived address of the conduit.
     * @return exists  A boolean indicating whether the derived conduit has been
     *                 deployed or not.
     */
    function getConduit(bytes32 conduitKey)
        external
        view
        returns (address conduit, bool exists);

    /**
     * @notice Retrieve the potential owner, if any, for a given conduit. The
     *         current owner may set a new potential owner via
     *         `transferOwnership` and that owner may then accept ownership of
     *         the conduit in question via `acceptOwnership`.
     *
     * @param conduit The conduit for which to retrieve the potential owner.
     *
     * @return potentialOwner The potential owner, if any, for the conduit.
     */
    function getPotentialOwner(address conduit)
        external
        view
        returns (address potentialOwner);

    /**
     * @notice Retrieve the status (either open or closed) of a given channel on
     *         a conduit.
     *
     * @param conduit The conduit for which to retrieve the channel status.
     * @param channel The channel for which to retrieve the status.
     *
     * @return isOpen The status of the channel on the given conduit.
     */
    function getChannelStatus(address conduit, address channel)
        external
        view
        returns (bool isOpen);

    /**
     * @notice Retrieve the total number of open channels for a given conduit.
     *
     * @param conduit The conduit for which to retrieve the total channel count.
     *
     * @return totalChannels The total number of open channels for the conduit.
     */
    function getTotalChannels(address conduit)
        external
        view
        returns (uint256 totalChannels);

    /**
     * @notice Retrieve an open channel at a specific index for a given conduit.
     *         Note that the index of a channel can change as a result of other
     *         channels being closed on the conduit.
     *
     * @param conduit      The conduit for which to retrieve the open channel.
     * @param channelIndex The index of the channel in question.
     *
     * @return channel The open channel, if any, at the specified channel index.
     */
    function getChannel(address conduit, uint256 channelIndex)
        external
        view
        returns (address channel);

    /**
     * @notice Retrieve all open channels for a given conduit. Note that calling
     *         this function for a conduit with many channels will revert with
     *         an out-of-gas error.
     *
     * @param conduit The conduit for which to retrieve open channels.
     *
     * @return channels An array of open channels on the given conduit.
     */
    function getChannels(address conduit)
        external
        view
        returns (address[] memory channels);

    /**
     * @dev Retrieve the conduit creation code and runtime code hashes.
     */
    function getConduitCodeHashes()
        external
        view
        returns (bytes32 creationCodeHash, bytes32 runtimeCodeHash);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

// prettier-ignore
import {
    ConduitTransfer,
    ConduitBatch1155Transfer
} from "../conduit/lib/ConduitStructs.sol";

/**
 * @title ConduitInterface
 * @author 0age
 * @notice ConduitInterface contains all external function interfaces, events,
 *         and errors for conduit contracts.
 */
interface ConduitInterface {
    /**
     * @dev Revert with an error when attempting to execute transfers using a
     *      caller that does not have an open channel.
     */
    error ChannelClosed(address channel);

    /**
     * @dev Revert with an error when attempting to update a channel to the
     *      current status of that channel.
     */
    error ChannelStatusAlreadySet(address channel, bool isOpen);

    /**
     * @dev Revert with an error when attempting to execute a transfer for an
     *      item that does not have an ERC20/721/1155 item type.
     */
    error InvalidItemType();

    /**
     * @dev Revert with an error when attempting to update the status of a
     *      channel from a caller that is not the conduit controller.
     */
    error InvalidController();

    /**
     * @dev Emit an event whenever a channel is opened or closed.
     *
     * @param channel The channel that has been updated.
     * @param open    A boolean indicating whether the conduit is open or not.
     */
    event ChannelUpdated(address indexed channel, bool open);

    /**
     * @notice Execute a sequence of ERC20/721/1155 transfers. Only a caller
     *         with an open channel can call this function.
     *
     * @param transfers The ERC20/721/1155 transfers to perform.
     *
     * @return magicValue A magic value indicating that the transfers were
     *                    performed successfully.
     */
    function execute(ConduitTransfer[] calldata transfers)
        external
        returns (bytes4 magicValue);

    /**
     * @notice Execute a sequence of batch 1155 transfers. Only a caller with an
     *         open channel can call this function.
     *
     * @param batch1155Transfers The 1155 batch transfers to perform.
     *
     * @return magicValue A magic value indicating that the transfers were
     *                    performed successfully.
     */
    function executeBatch1155(
        ConduitBatch1155Transfer[] calldata batch1155Transfers
    ) external returns (bytes4 magicValue);

    /**
     * @notice Execute a sequence of transfers, both single and batch 1155. Only
     *         a caller with an open channel can call this function.
     *
     * @param standardTransfers  The ERC20/721/1155 transfers to perform.
     * @param batch1155Transfers The 1155 batch transfers to perform.
     *
     * @return magicValue A magic value indicating that the transfers were
     *                    performed successfully.
     */
    function executeWithBatch1155(
        ConduitTransfer[] calldata standardTransfers,
        ConduitBatch1155Transfer[] calldata batch1155Transfers
    ) external returns (bytes4 magicValue);

    /**
     * @notice Open or close a given channel. Only callable by the controller.
     *
     * @param channel The channel to open or close.
     * @param isOpen  The status of the channel (either open or closed).
     */
    function updateChannel(address channel, bool isOpen) external;
}