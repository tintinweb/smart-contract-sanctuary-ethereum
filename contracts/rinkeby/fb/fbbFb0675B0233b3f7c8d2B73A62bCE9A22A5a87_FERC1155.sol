// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.13;

import {ERC1155, ERC1155TokenReceiver} from "@rari-capital/solmate/src/tokens/ERC1155.sol";
import {Clone} from "clones-with-immutable-args/src/Clone.sol";

/// @notice an ERC1155 implementation for Fractions
contract FERC1155 is ERC1155, Clone {
    /// @notice address that can deploy new vaults for this collection, manage metadata, etc
    address internal controller_;
    /// @notice URI of contract metadata
    string public contractURI;
    /// -----------------------------------------------------------------------
    /// EIP-2612-like storage
    /// -----------------------------------------------------------------------

    string public constant NAME = "FERC1155";

    /// ----------------------------------------------------------------------
    /// Errors
    /// ----------------------------------------------------------------------

    error InvalidSender(address required, address provided);
    error SigExpired();
    error InvalidSig();
    error ZeroAddress();

    /// ----------------------------------------------------------------------
    /// Token Data
    /// ----------------------------------------------------------------------

    // owner => operator => tokenId => approved
    mapping(address => mapping(address => mapping(uint256 => bool)))
        public isApproved;
    // owner => nonces
    mapping(address => uint256) public nonces;
    // id => totalSupply
    mapping(uint256 => uint256) public totalSupply;
    // id => royaltyAddress
    mapping(uint256 => address) private royaltyAddress;
    // id => royaltyPercent
    mapping(uint256 => uint256) private royaltyPercent;
    // id => metadata address
    mapping(uint256 => address) public metadata;

    /// ----------------------------------------------------------------------
    /// Events
    /// ----------------------------------------------------------------------

    event SingleApproval(
        address indexed owner,
        address indexed operator,
        uint256 id,
        bool approved
    );
    event MintFractions(address indexed owner, uint256 fId, uint256 amount);
    event BurnFractions(address indexed owner, uint256 fId, uint256 amount);
    event SetRoyalty(address indexed receiver, uint256 fId, uint256 percentage);
    event SetMetadata(address indexed metadata, uint256 fId);
    event ControllerTransferred(address indexed newController);

    /// ----------------------------------------------------------------------
    ///  ERC1155 Logic
    /// ----------------------------------------------------------------------

    // Scoped approvals allow us eliminate some of the risks associated with
    // setting the approval for an entire collection
    function setApprovalFor(
        address operator,
        uint256 id,
        bool approved
    ) public {
        isApproved[msg.sender][operator][id] = approved;

        emit SingleApproval(msg.sender, operator, id, approved);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public override {
        require(
            msg.sender == from ||
                isApprovedForAll[from][msg.sender] ||
                isApproved[from][msg.sender][id],
            "NOT_AUTHORIZED"
        );

        balanceOf[from][id] -= amount;
        balanceOf[to][id] += amount;

        emit TransferSingle(msg.sender, from, to, id, amount);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155Received(
                    msg.sender,
                    from,
                    id,
                    amount,
                    data
                ) == ERC1155TokenReceiver.onERC1155Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    /// ----------------------------------------------------------------------
    ///  Modifiers
    /// ----------------------------------------------------------------------

    modifier onlyController() {
        address controller_ = controller();
        if (msg.sender != controller_)
            revert InvalidSender(controller_, msg.sender);
        _;
    }

    modifier onlyRegistry() {
        address vaultRegistry = VAULT_REGISTRY();
        if (msg.sender != vaultRegistry)
            revert InvalidSender(vaultRegistry, msg.sender);
        _;
    }

    /// ----------------------------------------------------------------------
    ///  Functions
    /// ----------------------------------------------------------------------

    function INITIAL_CHAIN_ID() public returns (uint256) {
        return _getArgUint256(0);
    }

    function INITIAL_DOMAIN_SEPARATOR() public returns (bytes32) {
        return _getArgBytes32(32);
    }

    function INITIAL_CONTROLLER() public returns (address) {
        return _getArgAddress(64);
    }

    /// @notice address that is allowed to call mint() and burn()
    function VAULT_REGISTRY() public returns (address) {
        return _getArgAddress(84);
    }

    function controller() public returns (address controller) {
        controller_ == address(0)
            ? controller = INITIAL_CONTROLLER()
            : controller = controller_;
    }

    function uri(uint256 id) public view override returns (string memory) {
        require(metadata[id] != address(0), "NO METADATA");
        return ERC1155(metadata[id]).uri(id);
    }

    /// @notice Sets the contract metadata
    /// @param _uri URI of metadata
    function setContractURI(string calldata _uri) external onlyController {
        contractURI = _uri;
    }

    function setMetadata(address _metadata, uint256 _id)
        external
        onlyController
    {
        metadata[_id] = _metadata;
        emit SetMetadata(_metadata, _id);
    }

    function emitSetURI(uint256 _id, string memory _uri) external {
        if (msg.sender != metadata[_id])
            revert InvalidSender(metadata[_id], msg.sender);
        emit URI(_uri, _id);
    }

    function setRoyalties(
        uint256 _tokenId,
        address _receiver,
        uint256 _percentage
    ) external onlyController {
        royaltyAddress[_tokenId] = _receiver;
        royaltyPercent[_tokenId] = _percentage;
        emit SetRoyalty(_receiver, _tokenId, _percentage);
    }

    // Override for royaltyInfo(uint256, uint256)
    // royaltyInfo(uint256,uint256) => 0x2a55205a
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount)
    {
        receiver = royaltyAddress[_tokenId];

        // This sets percentages by price * percentage / 100
        royaltyAmount = (_salePrice * royaltyPercent[_tokenId]) / 100;
    }

    function transferController(address _newController) public onlyController {
        if (_newController == address(0)) revert ZeroAddress();
        controller_ = _newController;
        emit ControllerTransferred(_newController);
    }

    function mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public onlyRegistry {
        _mint(to, id, amount, data);
        totalSupply[id] += amount;
        emit MintFractions(to, id, amount);
    }

    function burn(
        address from,
        uint256 id,
        uint256 amount
    ) public onlyRegistry {
        _burn(from, id, amount);
        totalSupply[id] -= amount;
        emit BurnFractions(from, id, amount);
    }

    /// -----------------------------------------------------------------------
    /// EIP-2612-like logic
    /// -----------------------------------------------------------------------

    // permit an operator for a single ID in the collection
    function permit(
        address owner,
        address operator,
        uint256 tokenId,
        bool approved,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        if (block.timestamp > deadline) revert SigExpired();

        // cannot realistically overflow on human timescales
        unchecked {
            bytes32 digest = _computeDigest(
                owner,
                operator,
                tokenId,
                approved,
                deadline
            );

            address signer = ecrecover(digest, v, r, s);

            if (signer == address(0) || signer != owner) revert InvalidSig();
        }

        isApproved[owner][operator][tokenId] = approved;

        emit SingleApproval(owner, operator, tokenId, approved);
    }

    // Permit function that approves an operator for all tokens in the collection
    function permitAll(
        address owner,
        address operator,
        bool approved,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        if (block.timestamp > deadline) revert SigExpired();

        // cannot realistically overflow on human timescales
        unchecked {
            bytes32 digest = keccak256(
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
            );

            address signer = ecrecover(digest, v, r, s);

            if (signer == address(0) || signer != owner) revert InvalidSig();
        }

        isApprovedForAll[owner][operator] = approved;

        emit ApprovalForAll(owner, operator, approved);
    }

    function DOMAIN_SEPARATOR() public returns (bytes32) {
        return
            block.chainid == INITIAL_CHAIN_ID()
                ? INITIAL_DOMAIN_SEPARATOR()
                : _computeDomainSeparator();
    }

    function _computeDigest(
        address owner,
        address operator,
        uint256 tokenId,
        bool approved,
        uint256 deadline
    ) internal returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR(),
                    keccak256(
                        abi.encode(
                            keccak256(
                                "Permit(address owner,address operator,uint256 tokenId,bool approved,uint256 nonce,uint256 deadline)"
                            ),
                            owner,
                            operator,
                            tokenId,
                            approved,
                            nonces[owner]++,
                            deadline
                        )
                    )
                )
            );
    }

    function _computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256(
                        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                    ),
                    keccak256(bytes(NAME)),
                    bytes("1"),
                    block.chainid,
                    address(this)
                )
            );
    }
}

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

// SPDX-License-Identifier: BSD
pragma solidity ^0.8.4;

/// @title Clone
/// @author zefram.eth
/// @notice Provides helper functions for reading immutable args from calldata
contract Clone {
    /// @notice Reads an immutable arg with type address
    /// @param argOffset The offset of the arg in the packed data
    /// @return arg The arg value
    function _getArgAddress(uint256 argOffset)
        internal
        pure
        returns (address arg)
    {
        uint256 offset = _getImmutableArgsOffset();
        // solhint-disable-next-line no-inline-assembly
        assembly {
            arg := shr(0x60, calldataload(add(offset, argOffset)))
        }
    }

    /// @notice Reads an immutable arg with type uint256
    /// @param argOffset The offset of the arg in the packed data
    /// @return arg The arg value
    function _getArgUint256(uint256 argOffset)
        internal
        pure
        returns (uint256 arg)
    {
        uint256 offset = _getImmutableArgsOffset();
        // solhint-disable-next-line no-inline-assembly
        assembly {
            arg := calldataload(add(offset, argOffset))
        }
    }

    /// @notice Reads an immutable arg with type bytes32
    /// @param argOffset The offset of the arg in the packed data
    /// @return arg The arg value
    function _getArgBytes32(uint256 argOffset)
        internal
        pure
        returns (bytes32 arg)
    {
        uint256 offset = _getImmutableArgsOffset();
        // solhint-disable-next-line no-inline-assembly
        assembly {
            arg := calldataload(add(offset, argOffset))
        }
    }

    /// @notice Reads a uint256 array stored in the immutable args.
    /// @param argOffset The offset of the arg in the packed data
    /// @param arrLen Number of elements in the array
    /// @return arr The array
    function _getArgUint256Array(uint256 argOffset, uint64 arrLen)
        internal
        pure
        returns (uint256[] memory arr)
    {
        uint256 offset = _getImmutableArgsOffset();
        uint256 el;
        arr = new uint256[](arrLen);
        for (uint64 i = 0; i < arrLen; i++) {
            assembly {
                // solhint-disable-next-line no-inline-assembly
                el := calldataload(add(add(offset, argOffset), mul(i, 32)))
            }
            arr[i] = el;
        }
        return arr;
    }

    /// @notice Reads a uint256 array stored in the immutable args.
    /// @param argOffset The offset of the arg in the packed data
    /// @param arrLen Number of elements in the array
    /// @return arr The array
    function _getArgBytes32Array(uint256 argOffset, uint64 arrLen)
        internal
        pure
        returns (bytes32[] memory arr)
    {
        uint256 offset = _getImmutableArgsOffset();
        bytes32 el;
        arr = new bytes32[](arrLen);
        for (uint64 i = 0; i < arrLen; i++) {
            assembly {
                // solhint-disable-next-line no-inline-assembly
                el := calldataload(add(add(offset, argOffset), mul(i, 32)))
            }
            arr[i] = el;
        }
        return arr;
    }

    /// @notice Reads an immutable arg with type uint64
    /// @param argOffset The offset of the arg in the packed data
    /// @return arg The arg value
    function _getArgUint64(uint256 argOffset)
        internal
        pure
        returns (uint64 arg)
    {
        uint256 offset = _getImmutableArgsOffset();
        // solhint-disable-next-line no-inline-assembly
        assembly {
            arg := shr(0xc0, calldataload(add(offset, argOffset)))
        }
    }

    /// @notice Reads an immutable arg with type uint8
    /// @param argOffset The offset of the arg in the packed data
    /// @return arg The arg value
    function _getArgUint8(uint256 argOffset) internal pure returns (uint8 arg) {
        uint256 offset = _getImmutableArgsOffset();
        // solhint-disable-next-line no-inline-assembly
        assembly {
            arg := shr(0xf8, calldataload(add(offset, argOffset)))
        }
    }

    /// @return offset The offset of the packed immutable args in calldata
    function _getImmutableArgsOffset() internal pure returns (uint256 offset) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            offset := sub(
                calldatasize(),
                add(shr(240, calldataload(sub(calldatasize(), 2))), 2)
            )
        }
    }
}