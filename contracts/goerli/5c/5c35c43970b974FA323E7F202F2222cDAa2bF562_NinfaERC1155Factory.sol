// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import "../NinfaERC1155.sol";
import "../proxy/Clones.sol";
import "../access/IAccessControl.sol";
import "../access/Ownable.sol";

contract NinfaERC1155Factory is Ownable {
    error DelegatecallFailed();

    using Clones for address;

    address public master;
    bytes32 private constant MINTER_ROLE =
        0x9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6; // keccak256("MINTER_ROLE"); one or more smart contracts allowed to call the mint function, eg. the Marketplace contract
    bytes32 private constant DEFAULT_ADMIN_ROLE = 0x00;
    IAccessControl public NinfaMarketplace;

    mapping(address => bool) private instances; // a mapping that contains all ERC1155 deployed instances address. Use events for enumerating clones, this mapping is only used for access control in extists()

    event NewClone(address indexed instance, address indexed owner); // owner is needed in order to keep a local database of owners to instance addresses; this avoids keeping track of them on-chain via a mapping

    modifier onlyMinter(address _collection) {
        require(NinfaMarketplace.hasRole(MINTER_ROLE, msg.sender));
        _;
    }

    /**
     *
     * Requirements:
     *
     * - This function may be called either by the marketplace contract in `mintSplitAndTransfer()` or individually by users.
     * - If any address but the marketplace's call this function, they must have MINTER_ROLE set in the `NinfaMarketplace` contract. But essentially is the same because the marketplace's functions already require that caller must be an artist
     */
    function deployClone(
        string calldata _name,
        string calldata _symbol,
        bytes32 _salt,
        address _royaltyReceiver
    ) external onlyMinter(msg.sender) returns (address clone) {
        clone = _deployClone(_name, _symbol, _salt, _royaltyReceiver);
    }

    /**
     * @notice useful in order to avoid users having to sign two transactions with Metamask (one for deploying and one for minting), although the cost is the same the user only needs to sign one transaction.
     *
     * Required:
     *
     * - caller must be an artist as defined in the accesss control list in the Marketplace. This function is not supposed to be called by the marketplace.
     *
     */
    function deployAndMint(
        string calldata _name,
        string calldata _symbol,
        bytes32 _salt,
        bytes32 _tokenURI,
        uint256 _amount,
        address _royaltyReceiver
    ) external onlyMinter(msg.sender) {
        address clone = _deployClone(_name, _symbol, _salt, _royaltyReceiver);

        NinfaERC1155(clone).mint(msg.sender, _tokenURI, _amount, "");
    }

    /**
     * @dev this function should only be called if deploying NinfaERC1155 clone AND minting tokenId 0 AND transfering right away.
     *
     * Require:
     *  - the artist must approve the calling contract as an operator for token transfers.
     *  - only MINTER_ROLE address can call this function , see modifier in `mintAndTransferERC1155`
     *
     */
    function deployMintAndTransfer(
        string calldata _name,
        string calldata _symbol,
        bytes32 _salt,
        bytes32 _tokenURI,
        uint256 _amount,
        address _receiver,
        address _royaltyReceiver
    ) external onlyMinter(msg.sender) {
        address clone = _deployClone(_name, _symbol, _salt, _royaltyReceiver);

        /// TODO for some reason the below succeeds and the `ApprovalForAll` event is even emitted, however when calling isApprovedForall this contract is not set as operatpr...
        /// for now, ninfaerc1155 will approve this contract as operator in the initialize() function, but that needs to removed eventually.
        // (bool success, ) = clone.delegatecall(
        //     abi.encodeWithSignature(
        //         "setApprovalForAll(address,bool)",
        //         address(this),
        //         true
        //     )
        // );
        // if (!success) {
        //     revert DelegatecallFailed();
        // }

        NinfaERC1155(clone).mint(msg.sender, _tokenURI, _amount, "");

        NinfaERC1155(clone).safeTransferFrom(
            msg.sender,
            _receiver,
            0, // since the clone has just been deployed, _tokenId will always be 0.
            _amount,
            ""
        );
    }

    /**
     * @notice wrapper function should only be called after deploying NinfaERC1155 clone in order to mint a tokenId and transfer the entire supply just minted to someone else.
     *
     * Require:
     *
     * - facrory contract must be an authorized operator
     * - `_clone` must be one of this factory's collections and not an arbitrary user provided contract
     * - `msg.sender` must have `DEFAULT_ADMIN_ROLE` on the `_clone` contract; MINTER_ROLE is already required when deploying a new clone therefore it is not required to check again.
     *
     */
    function mintAndTransfer(
        bytes32 _tokenURI,
        uint256 _amount,
        address _receiver,
        address _clone
    ) external {
        require(instances[_clone]); // require that _clone is one of this factory's collections and not an attacker's contract

        require(NinfaERC1155(_clone).hasRole(DEFAULT_ADMIN_ROLE, msg.sender)); // this could also be achieved by using `delegatecall`; todo replace this function with `multiDelegatecall`.

        // (, bytes memory data) = _clone.call(
        //     abi.encodeWithSignature(
        //         "hasRole(bytes32,address)",
        //         DEFAULT_ADMIN_ROLE,
        //         msg.sender
        //     )
        // );
        // require(abi.decode(data, (bool))); // hasRole (bytes data) contains a boolean returned by hasRole

        NinfaERC1155(_clone).mint(msg.sender, _tokenURI, _amount, "");
        NinfaERC1155(_clone).safeTransferFrom(
            msg.sender,
            _receiver,
            NinfaERC1155(_clone).totalSupply() - 1, // since the token has just been minted, subtract 1 from totalSupply in order to get the newly minted token's index
            _amount,
            ""
        );
    }

    // TODO TODO @audit
    function multiDelegatecall(bytes[] memory data)
        external
        payable
        onlyMinter(msg.sender)
        returns (bytes[] memory results)
    {
        results = new bytes[](data.length);

        for (uint256 i; i < data.length; i++) {
            (bool ok, bytes memory res) = address(this).delegatecall(data[i]);
            if (!ok) {
                revert DelegatecallFailed();
            }
            results[i] = res;
        }
    }

    /**
     * @param _salt _salt is a random number of our choice. generated with https://web3js.readthedocs.io/en/v1.2.11/web3-utils.html#randomhex
     * _salt could also be dynamically calculated in order to avoid duplicate clones and for a way of finding predictable clones if salt the parameters are known, for example:
     * `address clone = master.cloneDeterministic(bytes32(keccak256(abi.encode(_name, _symbol, _msgSender))));`
     * Note "Using the same implementation and salt multiple time will revert, since the clones cannot be deployed twice at the same address." - https://docs.openzeppelin.com/contracts/4.x/api/proxy#Clones-cloneDeterministic-address-bytes32-
     */
    function _deployClone(
        string calldata _name,
        string calldata _symbol,
        bytes32 _salt,
        address _royaltyReceiver
    ) private returns (address clone) {
        clone = master.cloneDeterministic(_salt);

        NinfaERC1155(clone).initialize(
            _name,
            _symbol,
            msg.sender,
            _royaltyReceiver
        );

        instances[clone] = true;

        emit NewClone(clone, msg.sender);
    }

    function setMarketplaceAddress(address _marketplace) external onlyOwner {
        require(_marketplace.code.length > 0, "address must be contract"); // see Openzeppelin Address.sol `isContract()`. Implicitly checks that it is not the 0x0 address
        NinfaMarketplace = IAccessControl(_marketplace);
    }

    function setMasterAddress(address _master) external onlyOwner {
        require(_master.code.length > 0, "address must be contract"); // see Openzeppelin Address.sol `isContract()`. Implicitly checks that it is not the 0x0 address
        master = _master;
    }

    function predictDeterministicAddress(uint256 _salt)
        external
        view
        returns (address predicted)
    {
        predicted = Clones.predictDeterministicAddress(master, bytes32(_salt));
    }

    function exists(address _instance) external view returns (bool) {
        return instances[_instance];
    }

    constructor(address _master, address _marketplace) {
        require(_master.code.length > 0, "address must be contract"); // see Openzeppelin Address.sol `isContract()`. Implicitly checks that it is not the 0x0 address. // todo check that _master has erc1155, 165, 2981 interfaces
        require(_marketplace.code.length > 0, "address must be contract"); // see Openzeppelin Address.sol `isContract()`. Implicitly checks that it is not the 0x0 address
        master = _master;
        NinfaMarketplace = IAccessControl(_marketplace);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity 0.8.16;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length)
        internal
        pure
        returns (string memory)
    {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

/// @dev stripped down version of https://github.com/MrChico/verifyIPFS/
library DecodeTokenURI {
    bytes constant ALPHABET =
        "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz";

    /**
     * @dev Converts hex string to base 58
     */
    function toBase58(bytes memory source)
        internal
        pure
        returns (bytes memory)
    {
        if (source.length == 0) return new bytes(0);
        uint8[] memory digits = new uint8[](64);
        digits[0] = 0;
        uint8 digitlength = 1;
        for (uint256 i = 0; i < source.length; ++i) {
            uint256 carry = uint8(source[i]);
            for (uint256 j = 0; j < digitlength; ++j) {
                carry += uint256(digits[j]) * 256;
                digits[j] = uint8(carry % 58);
                carry = carry / 58;
            }

            while (carry > 0) {
                digits[digitlength] = uint8(carry % 58);
                digitlength++;
                carry = carry / 58;
            }
        }
        return toAlphabet(reverse(truncate(digits, digitlength)));
    }

    function toAlphabet(uint8[] memory indices)
        private
        pure
        returns (bytes memory)
    {
        bytes memory output = new bytes(indices.length);
        for (uint256 i = 0; i < indices.length; i++) {
            output[i] = ALPHABET[indices[i]];
        }
        return output;
    }

    function truncate(uint8[] memory array, uint8 length)
        private
        pure
        returns (uint8[] memory)
    {
        uint8[] memory output = new uint8[](length);
        for (uint256 i = 0; i < length; i++) {
            output[i] = array[i];
        }
        return output;
    }

    function reverse(uint8[] memory input)
        private
        pure
        returns (uint8[] memory)
    {
        uint8[] memory output = new uint8[](input.length);
        for (uint256 i = 0; i < input.length; i++) {
            output[i] = input[input.length - 1 - i];
        }
        return output;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

/**
    ███    ██ ██ ███    ██ ███████  █████  
    ████   ██ ██ ████   ██ ██      ██   ██ 
    ██ ██  ██ ██ ██ ██  ██ █████   ███████ 
    ██  ██ ██ ██ ██  ██ ██ ██      ██   ██ 
    ██   ████ ██ ██   ████ ██      ██   ██                                                                               
 */

/**
 * @title ERC2981Personal
 * @dev This is a contract used to add ERC2981 support to ERC721 and 1155
 * Royalty shares are set at 10% (10,000 basis points) out of total sales.
 * For precision purposes, it's better to express the royalty percentage as "basis points" (points per 10_000, e.g., 10% = 1000 bps) and compute the amount is `(royaltyBps[_tokenId] * _salePrice) / 10000` - https://forum.openzeppelin.com/t/setting-erc2981/16065/2
 */
contract ERC2981Personal {
    uint24 private constant ROYALTIY_SHARES = 1000; // 10% fixed royalties (out of total sale price) TODO modify
    uint24 private constant TOTAL_SHARES = 10000; // 10,000 = 100% (total sale price)
    /// @notice the royaltyReceiver or contract deployer. This cannot change and it is set at deployment time.
    address internal royaltyReceiver;

    /// @notice Called with the sale price to determine how much royalty
    //          is owed and to whom.
    /// @param _salePrice - the sale price of the NFT asset specified by _tokenId
    /// @return receiver - address of who should be sent the royalty payment
    /// @return royaltyAmount - the royalty payment amount for _salePrice
    function royaltyInfo(uint256, uint256 _salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount)
    {
        receiver = royaltyReceiver;
        royaltyAmount = (_salePrice * ROYALTIY_SHARES) / TOTAL_SHARES;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

interface IERC1155Receiver {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import "./IERC1155Receiver.sol";
import "../../utils/DecodeTokenURI.sol";

/// @notice Minimalist and gas efficient standard ERC1155 implementation.
/// @author Modified version of solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC1155.sol)
contract ERC1155 {
    using DecodeTokenURI for bytes;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 value
    );

    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
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

    mapping(address => mapping(uint256 => uint256)) private _balanceOf;

    mapping(address => mapping(address => bool)) public isApprovedForAll; // Mapping from account to operator approvals

    /*//////////////////////////////////////////////////////////////
                             URI STORAGE
    //////////////////////////////////////////////////////////////*/

    string private _baseURI = ""; // Optional base URI

    mapping(uint256 => bytes32) private _tokenURIs; // Optional mapping for token URIs

    /*//////////////////////////////////////////////////////////////
                             SUPPLY STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256[] private _totalSupply; // keeps track of individual token's total supply, as well as overall supply and used as a counter when minting, by using the .length property of the array.

    /*//////////////////////////////////////////////////////////////
                             URI LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev See {IERC721Metadata-tokenURI}. It needs to be overridden because the new OZ contracts concatenate _baseURI + tokenId instead of _baseURI + _tokenURI
     */
    function uri(uint256 tokenId) external view returns (string memory) {
        // require(_exists(tokenId), "ERC1155: nonexistent token");

        return
            string( // once hex decoded base58 is converted to string, we get the initial IPFS hash
                abi.encodePacked(
                    _baseURI,
                    abi
                    .encodePacked( // full bytes of base58 + hex encoded IPFS hash example.
                        bytes2(0x1220), // prepending 2 bytes IPFS hash identifier that was removed before storing the hash in order to fit in bytes32. 0x1220 is "Qm" base58 and hex encoded
                        _tokenURIs[tokenId] // bytes32(tokenId) // tokenURI (IPFS hash) with its first 2 bytes truncated, base58 and hex encoded returned as bytes32
                    ).toBase58()
                )
            );
    }

    /**
     * @dev Sets `baseURI` as the `_baseURI` for all tokens
     */
    function _setBaseURI(string memory baseURI) internal {
        _baseURI = baseURI;
    }

    /*//////////////////////////////////////////////////////////////
                              SUPPLY LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Total amount of tokens in with a given id.
     * @dev > The total value transferred from address 0x0 minus the total value transferred to 0x0 observed via the TransferSingle and TransferBatch events MAY be used by clients and exchanges to determine the “circulating supply” for a given token ID.
     */
    function totalSupply(uint256 id) external view returns (uint256) {
        return _totalSupply[id];
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply.length;
    }

    /**
     * @dev Indicates whether any token exist with a given id, or not.
     */
    function exists(uint256 id) external view returns (bool) {
        return _totalSupply[id] > 0;
    }

    /*//////////////////////////////////////////////////////////////
                              ERC1155 LOGIC
    //////////////////////////////////////////////////////////////*/

    function setApprovalForAll(address operator, bool approved) external {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) public {
        require(
            msg.sender == from || isApprovedForAll[from][msg.sender],
            "ERC1155: NOT_AUTHORIZED"
        );

        _balanceOf[from][id] -= amount;
        _balanceOf[to][id] += amount;

        emit TransferSingle(msg.sender, from, to, id, amount);

        require(
            to.code.length == 0
                ? to != address(0)
                : IERC1155Receiver(to).onERC1155Received(
                    msg.sender,
                    from,
                    id,
                    amount,
                    data
                ) == IERC1155Receiver.onERC1155Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external {
        require(ids.length == amounts.length, "LENGTH_MISMATCH");

        require(
            msg.sender == from || isApprovedForAll[from][msg.sender],
            "NOT_AUTHORIZED"
        );

        // Storing these outside the loop saves ~15 gas per iteration.
        uint256 id;
        uint256 amount;

        for (uint256 i = 0; i < ids.length; ) {
            id = ids[i];
            amount = amounts[i];

            _balanceOf[from][id] -= amount;
            _balanceOf[to][id] += amount;

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
                : IERC1155Receiver(to).onERC1155BatchReceived(
                    msg.sender,
                    from,
                    ids,
                    amounts,
                    data
                ) == IERC1155Receiver.onERC1155BatchReceived.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function balanceOfBatch(address[] calldata owners, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory balances)
    {
        require(owners.length == ids.length, "LENGTH_MISMATCH");

        balances = new uint256[](owners.length);

        // Unchecked because the only math done is incrementing
        // the array index counter which cannot possibly overflow.
        unchecked {
            for (uint256 i = 0; i < owners.length; ++i) {
                balances[i] = _balanceOf[owners[i]][ids[i]];
            }
        }
    }

    function balanceOf(address _owner, uint256 _id)
        external
        view
        returns (uint256 balance)
    {
        balance = _balanceOf[_owner][_id];
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(
        address to,
        bytes32 _tokenURI,
        uint256 _amount,
        bytes memory _data
    ) internal {
        uint256 id = _totalSupply.length;

        _balanceOf[to][id] += _amount;

        _tokenURIs[id] = _tokenURI;
        _totalSupply.push(_amount);

        emit TransferSingle(msg.sender, address(0), to, id, _amount);

        // todo is this require necessary
        require(
            to.code.length == 0
                ? to != address(0)
                : IERC1155Receiver(to).onERC1155Received(
                    msg.sender,
                    address(0),
                    id,
                    _amount,
                    _data
                ) == IERC1155Receiver.onERC1155Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal {
        uint256 idsLength = ids.length; // Saves MLOADs.

        require(idsLength == amounts.length, "LENGTH_MISMATCH");

        for (uint256 i = 0; i < idsLength; ) {
            _balanceOf[to][ids[i]] += amounts[i];

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
                : IERC1155Receiver(to).onERC1155BatchReceived(
                    msg.sender,
                    address(0),
                    ids,
                    amounts,
                    data
                ) == IERC1155Receiver.onERC1155BatchReceived.selector,
            "UNSAFE_RECIPIENT"
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(
                ptr,
                0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
            )
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(
                add(ptr, 0x28),
                0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            )
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt)
        internal
        returns (address instance)
    {
        assembly {
            let ptr := mload(0x40)
            mstore(
                ptr,
                0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
            )
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(
                add(ptr, 0x28),
                0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            )
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        assembly {
            let ptr := mload(0x40)
            mstore(
                ptr,
                0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
            )
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(
                add(ptr, 0x28),
                0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000
            )
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(msg.sender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() external onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) external onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity 0.8.16;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(
        bytes32 indexed role,
        bytes32 indexed previousAdminRole,
        bytes32 indexed newAdminRole
    );

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account)
        external
        view
        returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControl.sol)

pragma solidity 0.8.16;

import "../utils/Strings.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(
        bytes32 indexed role,
        bytes32 indexed previousAdminRole,
        bytes32 indexed newAdminRole
    );

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 internal constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, msg.sender);
        _;
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account)
        external
        onlyRole(getRoleAdmin(role))
    {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account)
        external
        onlyRole(getRoleAdmin(role))
    {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external {
        require(
            account == msg.sender,
            "AccessControl: can only renounce roles for self"
        );

        _revokeRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, msg.sender);
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, msg.sender);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import "./token/ERC1155/ERC1155.sol";
import "./token/common/ERC2981Personal.sol";
import "./access/AccessControl.sol";

/**
 * @dev {ERC1155} token
 * TODO replace AccessControl with custom Ownable implementation; there is no need for a minter role since the only minter is the artist, who deployed the contract via factory
 */
contract NinfaERC1155 is AccessControl, ERC2981Personal, ERC1155 {
    bool private initialized;
    string private _baseURI;
    string private _name;
    string private _symbol;

    bytes32 private constant MINTER_ROLE =
        0x9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6; // keccak256("MINTER_ROLE"); one or more smart contracts allowed to call the mint function, eg. the Marketplace contract

    /// @dev Added to make sure master implementation cannot be initialized todo
    // solhint-disable-next-line no-empty-blocks
    // constructor() initializer {}

    /**
     * @param owner_ is needed because this function is called by factory contract (msg.sender) hence the msg.origin EoA must be passed as an argument
     */
    function initialize(
        string memory name_,
        string memory symbol_,
        address owner_,
        address _royaltyReceiver
    ) external {
        require(!initialized); // equivalent to `initializer` modifier
        initialized = true; // can only be initialized once

        _grantRole(DEFAULT_ADMIN_ROLE, owner_); // DEFAULT_ADMIN_ROLE is by default admin of all other roles, i.e. MINTER_ROLE, meaning it can assign MINTER_ROLE to other addresses
        _grantRole(MINTER_ROLE, msg.sender); // grant MINTER_ROLE to factory contract
        _grantRole(MINTER_ROLE, owner_); // grant MINTER_ROLE to owner, this way minting requires only checking for MINTER_ROLE rather than also DEFAULT_ADMIN_ROLE.
        // TODO is there a better solution? eg. require MINTER_ROLE only for functions callable by factory or external contracts, require DEFAULT_ADMIN_ROLE only for functions called exclusively by owner

        // the following is required in order to call the function safeTransferFrom, invoked by deployMintAndTransfer in some cases in order to transfer tokenId 0 immediately after contract deployment
        // the approval of the factory is also needed in order to "mint and transfer" any tokenId, unless the mintAndTransfer function in implemented on each clone, in that case the factory approval would not be needed except for tokenId o
        // TODO figure out gas costs, how does this cost each deployer extra in order for some to be able to transfer tokenId 0? it would make more sense to sign twice for this edge case and to move mintAndTransfer on clone, i.e. remove deployMintAndTransfer
        // yet mintAndTransfer also carries a burden for users that won't use it.
        isApprovedForAll[owner_][msg.sender] = true;
        emit ApprovalForAll(owner_, msg.sender, true);

        _setBaseURI("ipfs://");
        _name = name_;
        _symbol = symbol_;
        royaltyReceiver = payable(_royaltyReceiver);
    }

    /**
     * @dev Creates `amount` new tokens for `to`, of token type `id`.
     * @param _to if different from msg.sender it is considered an airdrop
     * @param _tokenURI the ipfs hash of the token, base58 decoded, then the first two bytes "Qm" removed,  then hex encoded and in order to fit exactly in 32 bytes (uint256 is 32 bytes).
     *
     * const getBytes32FromIpfsHash = hash => {
     *      let bytes = bs58.decode(hash);
     *      bytes = bytes.slice(2, bytes.length);
     *      let hexString = web3.utils.bytesToHex(bytes);
     *      return web3.utils.hexToNumber(hexString);
     *  };
     *
     * See {ERC1155-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the `MINTER_ROLE`, i.e. only the owner of the collection can mint tokens, not just any artist on Ninfa marketplace.
     *
     */
    function mint(
        address _to,
        bytes32 _tokenURI,
        uint256 _amount,
        bytes memory _data
    ) external onlyRole(MINTER_ROLE) {
        _mint(_to, _tokenURI, _amount, _data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] variant of {mint}.
     */
    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external onlyRole(MINTER_ROLE) {
        _mintBatch(to, ids, amounts, data);
    }

    /**
     * @notice This function is used when the artist decides to set the royalty receiver to an address other than its own.
     * It adds the artist address to the `artists` mapping in {ERC2981Communal}, in order to use it for access control in `setRoyaltyReceiver()`. This removes the burden of setting this mapping in the `mint()` function as it will rarely be needed.
     * @param _royaltyReceiver (likely a payment splitter contract) may be 0x0 although it is not intended as ETH would be burnt if sent to 0x0. If the user only wants to mint it should call mint() instead, so that the roy
     *
     * Require:
     *
     * - If the `artists` for `_tokenId` mapping is empty, the minter's address is equal to `royaltyReceivers[_tokenId]`. I.e. the caller must correspond to `royaltyReceivers[_tokenId]`, i.e. the token minter/artist
     * - Else, the caller must correspond to the `_tokenId`'s minter address set in `artists[_tokenId]`, i.e. if `artists[_tokenId]` is not 0x0. Note that the artist address cannot be reset.
     *
     * Allow:
     *
     * - the minter may (re)set `royaltyReceivers[_tokenId]` to the same address as `artists[_tokenId]`, i.e. the minter/artist. This would be quite useless, but not dangerous. The frontend should disallow it.
     *
     */
    function setRoyaltyReceiver(address _royaltyReceiver)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        royaltyReceiver = payable(_royaltyReceiver);
    }

    function name() external view returns (string memory) {
        return _name;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId)
        external
        pure
        returns (bool)
    {
        return
            interfaceId == 0x01ffc9a7 || // Interface ID for IERC165
            interfaceId == 0xd9b67a26 || // Interface ID for IERC1155
            interfaceId == 0x0e89341c || // Interface ID for IERC1155MetadataURI
            interfaceId == 0x2a55205a || // Interface ID for IERC2981
            interfaceId == 0x7965db0b; // Interface ID for IAccessControl
    }
}