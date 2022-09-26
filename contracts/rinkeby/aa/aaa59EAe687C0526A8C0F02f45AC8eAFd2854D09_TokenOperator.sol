//SPDX-License-Identifier: MIT
//author: Evabase core team
pragma solidity ^0.8.16;
import "./venders/ERC1155Token.sol";
import "./interfaces/IOriConfig.sol";
import "./interfaces/ITokenOperator.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./interfaces/ILicenseToken.sol";
import "./interfaces/IDerivativeToken.sol";
import "./interfaces/IOriFactory.sol";
import "./interfaces/IMintFeeSettler.sol";
import "./interfaces/IApproveAuthorization.sol";
import "./lib/ConsiderationStructs.sol";
import "./lib/ConsiderationEnums.sol";
import "./lib/ConsiderationConstants.sol";
import "./lib/OriginMulticall.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "./interfaces/IBatchAction.sol";

/**
 * @title NFT Mint  Manager
 * @author ace
 * @notice Just work for Mint or Burn token.
 */
contract TokenOperator is ITokenOperator, IERC1155Receiver, OriginMulticall {
    IOriConfig private immutable _config;

    constructor(address config_) {
        require(config_ != address(0), "addess is 0x");
        _config = IOriConfig(config_);
    }

    /*
     * @dev Returns the mint fee settler address.
     * If no Mint fee is charged, return the zero address.
     */
    function licenseMintFeeSettler() external view returns (address) {
        return _config.getAddress(CONFIG_DAFAULT_MINT_SETTLE_ADDRESS_KEY);
    }

    /*
     * @dev Returns the ori config address.
     */
    function config() external view returns (address) {
        return address(_config);
    }

    function receiveApproveAuthorization(ApproveAuthorization[] calldata approves) external {
        for (uint256 i = 0; i < approves.length; i++) {
            address tokenAdd = approves[i].token;
            require(_isEnableToken(tokenAdd), "not whitelist");
            IApproveAuthorization(tokenAdd).approveForAllAuthorization(
                approves[i].from,
                approves[i].to,
                approves[i].validAfter,
                approves[i].validBefore,
                approves[i].salt,
                approves[i].signature
            );
        }
    }

    /**
     * @notice Check if the address is a whitelisted address
     * @param tokenAdd is the token address
     *
     */
    function _isEnableToken(address tokenAdd) internal returns (bool enable) {
        address factory = _config.getAddress(CONFIG_NFTFACTORY_KEY);
        enable = (IOriFactory(factory).getTokenStatus(tokenAdd) == TokenStatus.Enabled);
    }

    /**
     * @notice Creates `amount` tokens of token, and assigns them to `_msgsender()`.
     *
     * Requirements:
     *
     * - `token` must be enabled on ori protocol.
     * - If `_msgsender()` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function create(
        ITokenActionable token,
        uint256 amount,
        bytes calldata meta
    ) external payable {
        require(_isEnableToken(address(token)), "not whitelist");
        if (token.kind() == TokenKind.OriDerivative) {
            _createDerivative(token, amount, meta);
        } else if (token.kind() == TokenKind.OriLicense) {
            _createLicense(token, amount, meta);
        } else {
            revert notSupportTokenKindError();
        }
    }

    function _createLicense(
        ITokenActionable token,
        uint256 amount,
        bytes calldata meta
    ) internal {
        (uint256 originTokenId, uint256 earnPoint, uint64 expiredAt) = abi.decode(meta, (uint256, uint16, uint64));
        require(earnPoint <= _config.getUint256(CONFIG_DEFAULT_MAX_LICESE_EARN_POINT_KEY), "over 10%");
        //must have 721 origin NFT
        address origin = token.originToken();
        if (IERC165(origin).supportsInterface(type(IERC721).interfaceId)) {
            require(IERC721(origin).ownerOf(originTokenId) == _msgsender(), "origin NFT721 is 0");
        } else if (IERC165(origin).supportsInterface(type(IERC1155).interfaceId)) {
            require(
                IERC1155(origin).balanceOf(_msgsender(), originTokenId) > 0 && earnPoint == 0,
                "origin NFT1155=0 || earnPoint!=0"
            );
        } else {
            revert notSupportNftTypeError();
        }
        _feeProcess(amount, expiredAt);
        token.create(_msgsender(), meta, amount);
    }

    function _batchCreateLicense(
        ITokenActionable token,
        uint256[] memory amounts,
        bytes[] memory metas
    ) internal {
        //must have origin NFT
        uint64[] memory expiredAts = new uint64[](metas.length);
        address origin = token.originToken();
        bool isIERC1155;
        if (IERC165(origin).supportsInterface(type(IERC721).interfaceId)) {
            require(IERC721(origin).balanceOf(_msgsender()) > 0, "origin NFT721 is 0");
        } else if (IERC165(origin).supportsInterface(type(IERC1155).interfaceId)) {
            isIERC1155 = true;
        } else {
            revert notSupportNftTypeError();
        }
        uint256 originTokenId;
        uint16 earnPoint;
        uint16 totalPoint;
        for (uint256 i = 0; i < metas.length; i++) {
            (originTokenId, earnPoint, expiredAts[i]) = abi.decode(metas[i], (uint256, uint16, uint64));
            if (isIERC1155)
                require(
                    IERC1155(origin).balanceOf(_msgsender(), originTokenId) > 0 && earnPoint == 0,
                    "origin NFT1155=0 || earnPoint!=0"
                );
            totalPoint += earnPoint;
            require(totalPoint <= _config.getUint256(CONFIG_DEFAULT_MAX_LICESE_EARN_POINT_KEY), "over 10%");
        }
        _batchFeeProcess(amounts, expiredAts);

        IBatchAction(address(token)).batchCreate(_msgsender(), metas, amounts);
    }

    function _feeProcess(uint256 amount, uint64 expiredAt) internal {
        uint256[] memory amounts = new uint256[](1);
        uint64[] memory expiredAts = new uint64[](1);
        amounts[0] = amount;
        expiredAts[0] = expiredAt;
        _batchFeeProcess(amounts, expiredAts);
    }

    function _batchFeeProcess(uint256[] memory amounts, uint64[] memory expiredAts) internal {
        require(amounts.length == expiredAts.length, "invalid length");
        address feeAdd = _config.getAddress(CONFIG_DAFAULT_MINT_SETTLE_ADDRESS_KEY);
        if (feeAdd != address(0)) {
            IMintFeeSettler(feeAdd).allowMint{value: msg.value}(amounts, expiredAts);
        }
    }

    function _createDerivative(
        ITokenActionable token,
        uint256 amount,
        bytes calldata meta
    ) internal {
        address origin = token.originToken();
        (NFT[] memory licenses, , ) = abi.decode(meta, (NFT[], uint256, uint256));
        _useLicese(licenses, origin);
        token.create(_msgsender(), meta, amount);
    }

    function _batchCreateDerivative(
        ITokenActionable token,
        uint256[] memory amounts,
        bytes[] memory derivativeMetas
    ) internal {
        require(amounts.length == derivativeMetas.length, "invalid length");
        address origin = token.originToken();

        for (uint256 i = 0; i < derivativeMetas.length; i++) {
            (NFT[] memory licenses, , ) = abi.decode(derivativeMetas[i], (NFT[], uint256, uint256));
            _useLicese(licenses, origin);
        }

        if (IERC165(address(token)).supportsInterface(type(IERC1155).interfaceId)) {
            IBatchAction(address(token)).batchCreate(_msgsender(), derivativeMetas, amounts);
        } else {
            revert notSupportNftTypeError();
        }
    }

    function _useLicese(NFT[] memory licenses, address origin) internal {
        require(licenses.length > 0, "invalid length");
        bool isHaveOrigin = origin == address(0);
        //use licese to create
        for (uint256 i = 0; i < licenses.length; i++) {
            IERC1155(licenses[i].token).safeTransferFrom(_msgsender(), address(this), licenses[i].id, 1, "");
            if (!isHaveOrigin) {
                isHaveOrigin = origin == ITokenActionable(licenses[i].token).originToken();
            }
        }

        require(isHaveOrigin, "need match license");
    }

    /**
     * @notice batch-operations version of `create`.
     *
     * Requirements:
     *
     * - `token` must be enabled on ori protocol.
     * - If `_msgsender()` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function batchCreate(
        ITokenActionable token,
        uint256[] calldata amounts,
        bytes[] calldata metas
    ) external payable {
        require(amounts.length == metas.length, "invalid length");
        require(_isEnableToken(address(token)), "not whitelist");
        if (token.kind() == TokenKind.OriDerivative) {
            _batchCreateDerivative(token, amounts, metas);
        } else if (token.kind() == TokenKind.OriLicense) {
            _batchCreateLicense(token, amounts, metas);
        } else {
            revert notSupportTokenKindError();
        }
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `_msgsender()`.
     *
     * Requirements:
     * - `token` must be enabled on ori protocol.
     * - If `_msgsender()` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function mint(
        ITokenActionable token,
        uint256 id,
        uint256 amount
    ) external payable {
        _mint(token, id, amount);
    }

    function _mint(
        ITokenActionable token,
        uint256 id,
        uint256 amount
    ) internal {
        require(_isEnableToken(address(token)), "not whitelist");
        address origin = token.originToken();
        if (token.kind() == TokenKind.OriLicense) {
            LicenseMeta memory lMeta = ILicenseToken(address(token)).meta(id);
            require(lMeta.earnPoint <= _config.getUint256(CONFIG_DEFAULT_MAX_LICESE_EARN_POINT_KEY), "over 10%");
            _feeProcess(amount, lMeta.expiredAt);
        } else if (token.kind() == TokenKind.OriDerivative) {
            DerivativeMeta memory dmeta = IDerivativeToken(address(token)).meta(id);
            _useLicese(dmeta.licenses, origin);
        } else {
            revert notSupportTokenKindError();
        }

        token.mint(_msgsender(), id, amount);
    }

    /**
     * @dev batch-operations version of `mint`
     *
     * Requirements:
     * - `token` must be enabled on ori protocol.
     * - If `_msgsender()` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     * - `ids` and `amounts` must have the same length.
     */
    function batchMint(
        ITokenActionable token,
        uint256[] calldata ids,
        uint256[] calldata amounts
    ) external payable {
        require(ids.length == amounts.length, "invalid length");
        require(_isEnableToken(address(token)), "not whitelist");
        address origin = token.originToken();
        if (token.kind() == TokenKind.OriLicense) {
            LicenseMeta[] memory lMetas = ILicenseToken(address(token)).metas(ids);
            uint64[] memory expiredAts = new uint64[](ids.length);
            uint16 totalPoint;
            for (uint256 i = 0; i < ids.length; i++) {
                expiredAts[i] = lMetas[i].expiredAt;
                totalPoint += lMetas[i].earnPoint;
                require(totalPoint <= _config.getUint256(CONFIG_DEFAULT_MAX_LICESE_EARN_POINT_KEY), "over 10%");
            }
            _batchFeeProcess(amounts, expiredAts);
        } else if (token.kind() == TokenKind.OriDerivative) {
            if (!IERC165(address(token)).supportsInterface(type(IERC1155).interfaceId)) {
                revert notSupportTokenKindError();
            }
            DerivativeMeta[] memory dmetas = IDerivativeToken(address(token)).metas(ids);
            for (uint256 i = 0; i < dmetas.length; i++) {
                _useLicese(dmetas[i].licenses, origin);
            }
        } else {
            revert notSupportTokenKindError();
        }
        IBatchAction(address(token)).batchMint(_msgsender(), ids, amounts);
    }

    /**
     * @dev Destroys `amount` tokens of `token` type `id` from `from`
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `token` must be enabled on ori protocol.
     */
    function burn(
        ITokenActionable token,
        uint256 id,
        uint256 amount
    ) external {
        require(_isEnableToken(address(token)), "not whitelist");
        token.burn(_msgsender(), id, amount);
    }

    /**
     * @dev batch-operations version of `burn`
     *
     * Requirements:
     *
     * - `token` must be enabled on ori protocol.
     * - `ids` and `amounts` must have the same length.
     */
    function batchBurn(
        ITokenActionable token,
        uint256[] calldata ids,
        uint256[] calldata amounts
    ) external payable {
        require(_isEnableToken(address(token)), "not whitelist");
        require(ids.length == amounts.length, "invalid length");
        if (!IERC165(address(token)).supportsInterface(type(IERC1155).interfaceId)) {
            revert notSupportTokenKindError();
        }
        IBatchAction(address(token)).batchBurn(_msgsender(), ids, amounts);
    }

    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. _msgsender())
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    //solhint-disable no-unused-vars
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4) {
        return IERC1155Receiver.onERC1155Received.selector;
    }

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. _msgsender())
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    //solhint-disable no-unused-vars
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4) {
        return IERC1155Receiver.onERC1155BatchReceived.selector;
    }

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool) {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
abstract contract ERC1155Token is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    // string private _uri;

    /**
     * @dev See {_setURI}.
     */
    // constructor(string memory uri_) {
    //     _setURI(uri_);
    // }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory);

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: address zero is not a valid owner");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function setURI(string memory newuri) external virtual;

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `ids` and `amounts` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    /**
     * @dev Hook that is called after any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}

//SPDX-License-Identifier: MIT
//author: Evabase core team

pragma solidity ^0.8.16;

/**
 * @title Ori Config Center
 * @author ysqi
 * @notice  Manage all configs for ori protocol.
 * each config the type of item key is bytes32, the item value type is bytes32 too.
 */
interface IOriConfig {
    /*
     * @notice White list change event
     * @param key
     * @param value is the new value.
     */
    event ChangeWhite(address indexed key, bool value);

    /*
     * @notice Configuration change event
     * @param key
     * @param value is the new value.
     */
    event Changed(bytes32 indexed key, bytes32 value);

    /*
     * @notice Configuration change event
     * @param key
     * @param value is the new value.
     */
    event ChangedBytes(bytes32 indexed key, bytes value);

    /**
     * @dev Returns the value of the given configuration item.
     */
    function get(bytes32 key) external view returns (bytes32);

    /**
     * @dev Returns value of the given configuration item.
     * Safely convert the bytes32 value to address before returning.
     */
    function getAddress(bytes32 key) external view returns (address);

    /**
     * @dev Returns value of the given configuration item.
     */
    function getUint256(bytes32 key) external view returns (uint256);

    /**
     * @notice Reset the configuration item value to an address.
     *
     * Emits an `Changed` event.
     *
     * Requirements:
     *
     * - Only the administrator can call it.
     *
     * @param key is the key of configuration item.
     * @param value is the new value of the given item `key`.
     */
    function resetAddress(bytes32 key, address value) external;

    /**
     * @notice Reset the configuration item value to a uint256.
     *
     * Emits an `Changed` event.
     *
     * Requirements:
     *
     * - Only the administrator can call it.
     *
     * @param key is the key of configuration item.
     * @param value is the new value of the given item `key`.
     */
    function resetUint256(bytes32 key, uint256 value) external;

    /**
     * @notice Reset the configuration item value to a bytes32.
     *
     * Emits an `Changed` event.
     *
     * Requirements:
     *
     * - Only the administrator can call it.
     *
     * @param key is the key of configuration item.
     * @param value is the new value of the given item `key`.
     */
    function reset(bytes32 key, bytes32 value) external;

    /**
     * @dev Returns the bytes.
     */
    function getBytes(bytes32 key) external view returns (bytes memory);

    /**
     * @notice  set the configuration item value to a bytes.
     *
     * Emits an `ChangedBytes` event.
     *
     * Requirements:
     *
     * - Only the administrator can call it.
     *
     * @param key is the key of configuration item.
     * @param value is the new value of the given item `key`.
     */
    function setBytes(bytes32 key, bytes memory value) external;

    /**
     * @dev Is it a whitelisted market.
     */
    function isWhiteMarketplace(address marketplace) external view returns (bool);

    /**
     * @notice  set the marketplace item value whiteList or not.
     *
     * Emits an `ChangeWhite` event.
     *
     * Requirements:
     *
     * - Only the administrator can call it.
     *
     * @param marketplace is the key of configuration item.
     * @param isWhite WhiteList or not.
     */
    function setWhiteMarketplace(address marketplace, bool isWhite) external;
}

//SPDX-License-Identifier: MIT
//author: Evabase core team

pragma solidity ^0.8.0;

import "../lib/ConsiderationStructs.sol";
import "./ITokenActionable.sol";
import "./IMintFeeSettler.sol";

/**
 * @title NFT Mint  Manager
 * @author ysqi
 * @notice Just work for Mint or Burn token.
 */
interface ITokenOperator {
    /*
     * @dev Returns the mint fee settler address.
     * If no Mint fee is charged, return the zero address.
     */
    function licenseMintFeeSettler() external view returns (address);

    /*
     * @dev Returns the ori config address.
     */
    function config() external view returns (address);

    function receiveApproveAuthorization(ApproveAuthorization[] calldata approves) external;

    /**
     * @notice Creates `amount` tokens of token, and assigns them to `msg.sender`.
     * @param meta is the token meta information.
     *
     * Requirements:
     *
     * - `token` must be enabled on ori protocol.
     * - If `msg.sender` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function create(
        ITokenActionable token,
        uint256 amount,
        bytes calldata meta
    ) external payable;

    /**
     * @notice batch-operations version of `create`.
     *
     * Requirements:
     *
     * - `token` must be enabled on ori protocol.
     * - If `msg.sender` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function batchCreate(
        ITokenActionable token,
        uint256[] calldata amounts,
        bytes[] calldata metas
    ) external payable;

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `msg.sender`.
     *
     * Requirements:
     * - `token` must be enabled on ori protocol.
     * - If `msg.sender` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function mint(
        ITokenActionable token,
        uint256 id,
        uint256 amount
    ) external payable;

    /**
     * @dev batch-operations version of `mint`
     *
     * Requirements:
     * - `token` must be enabled on ori protocol.
     * - If `msg.sender` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     * - `ids` and `amounts` must have the same length.
     */
    function batchMint(
        ITokenActionable token,
        uint256[] calldata ids,
        uint256[] calldata amounts
    ) external payable;

    /**
     * @dev Destroys `amount` tokens of `token` type `id` from `from`
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `token` must be enabled on ori protocol.
     */
    function burn(
        ITokenActionable token,
        uint256 id,
        uint256 amount
    ) external;

    /**
     * @dev batch-operations version of `burn`
     *
     * Requirements:
     *
     * - `token` must be enabled on ori protocol.
     * - `ids` and `amounts` must have the same length.
     */
    function batchBurn(
        ITokenActionable token,
        uint256[] calldata ids,
        uint256[] calldata amounts
    ) external payable;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.3) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

//SPDX-License-Identifier: MIT
//author: Evabase core team

pragma solidity ^0.8.16;
import "./IApproveAuthorization.sol";
import "./ITokenActionable.sol";

/**
 * @title NFT License token
 * @author ysqi
 * @notice NFT License token protocol.
 */
interface ILicenseToken is IApproveAuthorization, ITokenActionable {
    /**
     * @notice return the license meta data.
     *
     * Requirements:
     *
     * - `id` must be exist.
     * @param id is the token id.
     * @return LicenseMeta:
     *
     *    uint256 originTokenId;
     *    uint16 earnPoint;
     *    uint64 expiredAt;
     */
    function meta(uint256 id) external view returns (LicenseMeta calldata);

    /**
     * @notice return the license[] metas data.
     *
     * Requirements:
     *
     * - `id` must be exist.
     * @param ids is the token ids.
     * @return LicenseMetas:
     *
     *    uint256 originTokenId;
     *    uint16 earnPoint;
     *    uint64 expiredAt;
     */
    function metas(uint256[] memory ids) external view returns (LicenseMeta[] calldata);

    /*
     * @notice return whether NFT has expired.
     *
     * Requirements:
     *
     * - `id` must be exist.
     *
     * @param id is the token id.
     * @return bool returns whether NFT has expired.
     */
    function expired(uint256 id) external view returns (bool);
}

//SPDX-License-Identifier: MIT
//author: Evabase core team

pragma solidity ^0.8.16;

import "./ITokenActionable.sol";

/**
 * @title NFT Derivative token
 * @author ysqi
 * @notice NFT Derivative token protocol.
 */
interface IDerivativeToken is ITokenActionable {
    /*
     * @dev Returns this token derivative deployer.
     */
    function creator() external view returns (address);

    /**
     * @notice return the Derivative[] metas data.
     *
     * Requirements:
     *
     * - `id` must be exist.
     * @param id is the token id.
     * @return DerivativeMeta
     */
    function meta(uint256 id) external view returns (DerivativeMeta calldata);

    /**
     * @notice return the license[] metas data.
     *
     * Requirements:
     *
     * - `id` must be exist.
     * @param ids is the token ids.
     * @return DerivativeMetas:
     *
     */
    function metas(uint256[] memory ids) external view returns (DerivativeMeta[] calldata);
}

//SPDX-License-Identifier: MIT
//author: Evabase core team

pragma solidity ^0.8.16;
import "../lib/ConsiderationEnums.sol";

/**
 * @title Ori Protocol NFT Token Factory
 * @author ysqi
 * @notice management License and Derivative NFT token.
 */
interface IOriFactory {
    event TokenEnabled(address token);
    event TokenDisabled(address token);
    event LicenseTokenDeployed(address originToken, address license);
    event DerivativeTokenDeployed(
        address originToken,
        address derivative,
        TokenStandard dType,
        string dName,
        string dSymbol
    );

    function getTokenStatus(address token) external returns (TokenStatus);

    function defaultToken(address originToken) external returns (address license, address derivative);

    /**
     * @notice enable the given nft token.
     *
     * Emits an {TokenEnabled} event.
     *
     * Requirements:
     *
     * - The nft token `token` must been created by OriFactory.
     * - The `token` must be unenabled.
     * - Only the administrator can call it.
     *
     * @param token  is License or Derivative contract address.
     *
     */
    function enableToken(address token) external;

    /**
     * @notice disable the given nft token.
     *
     * Emits an {TokenDisabled} event.
     *
     * Requirements:
     *
     * - The `token` must be enabled.
     * - Only the administrator can call it.
     *
     * @param token  is License or Derivative contract address.
     *
     */
    function disableToken(address token) external;

    /**
     * @notice Create default license and derivative token contracts for the given NFT.
     * @dev Ori can deploy licenses and derivative contracts for every NFT contract.
     * Then each NFT's licens and derivatives will be stand-alone.
     * helping to analyz this NFT and makes the NFT managment structure clear and concise.
     *
     * Every one can call it to deploy license and derivative contracts for the given NFT.
     * but this created contracts is disabled, need the administrator to enable them.
     * them will be enabled immediately if the caller is an administrator.
     *
     * Emits a `LicenseTokenDeployed` and a `Derivative1155TokenDeployed` event.
     * And there are tow `TokenEnabled` events if the caller is an administrator.
     *
     *
     * Requirements:
     *
     * - The `originToken` must be NFT contract.
     * - Each NFT Token can only set one default license and derivative contract.
     *
     * @param originToken is the NFT contract.
     *
     */
    function deployToken(
        address originToken,
        TokenStandard dType,
        string memory dName,
        string memory dSymbol
    ) external;

    /**
     * @notice Create a empty derivative NFT contract
     * @dev Allow every one to call it to create derivative NFT contract.
     * Only then can Ori whitelist it. and this new contract will be enabled immediately.
     *
     * Emits a `Derivative1155TokenDeployed` event. the event parameter `originToken` is zero.
     * And there are a `TokenEnabled` event if the caller is an administrator.
     */
    function deployDerivativeToken(
        TokenStandard dType,
        string memory dName,
        string memory dSymbol
    ) external;
}

//SPDX-License-Identifier: MIT
//author: Evabase core team

pragma solidity ^0.8.16;

/**
 * @title  License Token Mint Fee Settler
 * @author ysqi
 * @notice Licens token mint fee management settlement center.
 */
interface IMintFeeSettler {
    /*
     * @dev Returns the base factor value.
     * The mantissa of the baseFactor is 10000.
     */
    function baseFactor() external view returns (uint256);

    /**
     * @notice calcute the mint fee for license token.
     * @dev The default formula see `allowMint` function.
     *
     * @param amounts is the amount of minted.
     * @param expiredAts is the expiration tiem of the given license token `token`.`id`.
     */
    function calculateMintFee(uint256[] calldata amounts, uint64[] calldata expiredAts) external view returns (uint256);

    /**
     * @notice chceck and recieve the mint fee.
     * @dev The default formula for calculating the Mint fee is as fllows:
     *
     * >    Fee (ETH) =  BaseFactor  * amount * (expiredAt - now)
     *
     * Requirements:
     *
     * - `amounts` and `expiredAts` must be have the same length.
     *
     * @param amounts is the amount of minted.
     * @param expiredAts is the expiration tiem of the given license token `token`.`id`.
     */
    function allowMint(uint256[] calldata amounts, uint64[] calldata expiredAts) external payable;

    /**
     * @notice Triggered when a Derivative contract is traded
     * @param derivativeIds is the Derivative token ids.
     * @param to NFT Receiver when a Derivative contract is traded.
     *
     * Requirements:
     *
     * 1.this Trade need allocation value
     * 2 .Settlement of the last required allocation
     * 3. Maintain records of pending settlements
     * 4. update total last Unclaim amount
     */
    function onDerivativeNftTransfer(uint256[] memory derivativeIds, address to) external;

    /**
     * @notice settle the previous num times of records
     * @param num the previous num.
     *
     */
    function settleUnclaim(uint256 num) external;
}

//SPDX-License-Identifier: MIT
//author: Evabase core team

pragma solidity ^0.8.16;

/**
 * @title  Atomic approve token
 * @author ysqi
 * @notice gives permission to transfer token to another account on this call.
 */
interface IApproveAuthorization {
    /**
     * @notice the `from` gives permission to `to` to transfer token to another account on this call.
     * The approval is cleared when the call is end.
     *
     * Emits an `AtomicApproved` event.
     *
     * Requirements:
     *
     * - `to` must be the same with `msg.sender`. and it must implement {IApproveSet-onAtomicApproveSet}, which is called after approve.
     * - `to` can't be the `from`.
     * - `nonce` can only be used once.
     * - The validity of this authorization operation must be between `validAfter` and `validBefore`.
     *
     * @param from        from's address (Authorizer)
     * @param to      to's address
     * @param validAfter    The time after which this is valid (unix time)
     * @param validBefore   The time before which this is valid (unix time)
     * @param salt          Unique salt
     * @param signature     the signature
     */
    function approveForAllAuthorization(
        address from,
        address to,
        uint256 validAfter,
        uint256 validBefore,
        bytes32 salt,
        bytes memory signature
    ) external;
}

//SPDX-License-Identifier: MIT
//author: Evabase core team

pragma solidity ^0.8.16;

import "./ConsiderationEnums.sol";

// NFT 标识
struct NFT {
    address token; //该 NFT 所在合约地址
    uint256 id; // 该 NFT ID 标识符
}

struct DerivativeMeta {
    NFT[] licenses; // 二创NFT所携带的 Licenses 清单
    uint256 supplyLimit; // 供给上限
    uint256 totalSupply; //当前总已供给数量
}

// License NFT 元数据
struct LicenseMeta {
    uint256 originTokenId; // License 所属 NFT
    uint16 earnPoint; // 单位是10000,原NFT持有人从二创NFT交易中赚取的交易额比例，100= 1%
    uint64 expiredAt; // 该 License 过期时间，过期后不能用于创建二仓作品
}

// approve sign data
struct ApproveAuthorization {
    address token;
    address from; //            from        from's address (Authorizer)
    address to; //     to's address
    uint256 validAfter; // The time after which this is valid (unix time)
    uint256 validBefore; // The time before which this is valid (unix time)
    bytes32 salt; // Unique salt
    bytes signature; //  the signature
}

//Store a pair of addresses
struct PairStruct {
    address licenseAddress;
    address derivativeAddress;
}

struct Settle {
    address recipient;
    uint256 value;
    uint256 index;
}

//SPDX-License-Identifier: MIT
//author: Evabase core team

pragma solidity ^0.8.16;

/**
 * @dev the standard of token
 */
enum TokenStandard {
    Unknow,
    // 1 - ERC20 Token
    ERC20,
    // 2 - ERC721 Token (NFT)
    ERC721,
    // 3 - ERC1155 Token (NFT)
    ERC1155
}

/**
 * @dev the kind of token on ori protocol.
 */
enum TokenKind {
    Unknow,
    // 1- Licens Token
    OriLicense,
    // 2- Derivative Token
    OriDerivative
}

/**
 * @dev the status of token on ori protocol.
 */
enum TokenStatus {
    Unknow,
    //deployed but not enable
    Pending,
    Enabled,
    Disabled
}

//SPDX-License-Identifier: MIT
//author: Evabase core team
pragma solidity ^0.8.16;

// Operator Address For Newly created NFT contract operator for managing collections in Opensea
bytes32 constant CONFIG_OPERATPR_ALL_NFT_KEY = keccak256("CONFIG_OPERATPR_ALL_NFT");

//  Mint Settle Address
bytes32 constant CONFIG_DAFAULT_MINT_SETTLE_ADDRESS_KEY = keccak256("CONFIG_DAFAULT_MINT_SETTLE_ADDRESS");

// NFT Factory Contract Address
bytes32 constant CONFIG_NFTFACTORY_KEY = keccak256("CONFIG_NFTFACTORY_KEY");

// Derivative1155TokenType Contract Address
bytes32 constant CONFIG_DERIVATIVETOKEN_1155_TYPE_KEY = keccak256("CONFIG_DERIVATIVETOKEN_1155_TYPE");

// Derivative721TokenType Contract Address
bytes32 constant CONFIG_DERIVATIVETOKEN_721_TYPE_KEY = keccak256("CONFIG_DERIVATIVETOKEN_721_TYPE");

// LicenseTokenType Contract Address
bytes32 constant CONFIG_LICENSETOKEN_TYPE_KEY = keccak256("CONFIG_LICENSETOKEN_TYPE");

//Default owner address for NFT
bytes32 constant CONFIG_DEFAULT_OWNER_ALL_NFT_KEY = keccak256("CONFIG_DEFAULT_OWNER_ALL_NFT");

// Default Mint Fee 0.00001 ETH
bytes32 constant CONFIG_DAFAULT_MINT_FEE_KEY = keccak256("CONFIG_DAFAULT_MINT_FEE");

//Default Base url for NFT eg:https://nft.ori.com/
bytes32 constant CONFIG_DEFAULT_BASE_URL_ALL_NFT_KEY = keccak256("CONFIG_DEFAULT_BASE_URL_ALL_NFT");

// Max licese Earn Point Para
bytes32 constant CONFIG_DEFAULT_MAX_LICESE_EARN_POINT_KEY = keccak256("CONFIG_DEFAULT_MAX_LICESE_EARN_POINT");

// As EIP712 parameters
string constant NAME = "ORI";
// As EIP712 parameters
string constant VERSION = "1";

//SPDX-License-Identifier: MIT
//author: Evabase core team

pragma solidity ^0.8.16;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../interfaces/OriErrors.sol";

/// @title Calling multiple methods
/// @author ysqi
/// @notice Supports calling multiple methods of this contract at once.
contract OriginMulticall is ReentrancyGuard, OriErrors {
    address private _multicallSender;

    /**
     * @notice Calling multiple methods of this contract at once.
     * @dev Each item of the `datas` array represents a method call.
     *
     * Each item data contains calldata and ETH value.
     * We call decode call data from item of `datas`.
     *
     *     (bytes memory data, uint256 value)= abi.decode(datas[i],(bytes,uint256));
     *
     * Will reverted if a call failed.
     *
     *
     *
     */
    function multicall(bytes[] calldata datas) external payable nonReentrant returns (bytes[] memory results) {
        // enter the multicall mode.
        _multicallSender = msg.sender;

        // call
        results = new bytes[](datas.length);
        for (uint256 i = 0; i < datas.length; i++) {
            (bytes memory data, uint256 value) = abi.decode(datas[i], (bytes, uint256));
            // sol-disable avoid-low-level-calls
            (bool success, bytes memory returndata) = address(this).call{value: value}(data);
            results[i] = _verifyCallResult(success, returndata);
        }
        // exit
        _multicallSender = address(0);
        return results;
    }

    function _msgsender() internal view returns (address) {
        // call from  multicall if _multicallSender is not the zero address.
        return _multicallSender != address(0) && msg.sender == address(this) ? _multicallSender : msg.sender;
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function _verifyCallResult(bool success, bytes memory returndata) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert UnknownLowLevelCallFailed();
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
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

//SPDX-License-Identifier: MIT
//author: Evabase core team

pragma solidity ^0.8.16;
import "../lib/ConsiderationStructs.sol";

/**
 * @title define token mint or burn actions
 * @author ysqi
 * @notice Two types of Tokens within the Ori protocol need to support Mint and Burn operations.
 */
interface IBatchAction {
    /**
     * @dev batch-operations version of `create`.
     *
     * Requirements:
     *
     * - `metas` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function batchCreate(
        address to,
        bytes[] calldata metas,
        uint256[] calldata amounts
    ) external;

    /**
     * @dev batch-operations version of `mint`
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     * - `ids` and `amounts` must have the same length.
     */
    function batchMint(
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts
    ) external;

    /**
     * @dev batch-operations version of `burn`
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     * - `ids` and `amounts` must have the same length.
     */
    function batchBurn(
        address from,
        uint256[] calldata ids,
        uint256[] calldata amounts
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

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

//SPDX-License-Identifier: MIT
//author: Evabase core team

pragma solidity ^0.8.16;
import "../lib/ConsiderationStructs.sol";

/**
 * @title define token mint or burn actions
 * @author ysqi
 * @notice Two types of Tokens within the Ori protocol need to support Mint and Burn operations.
 */
interface ITokenActionable {
    /*
     * @dev Returns the NFT operator address(ITokenOperator).
     * Only operator can mint or burn OriLicense/OriDerivative/ NFT.
     */

    function operator() external view returns (address);

    /**
     * @dev Returns the editor of the current collection on Opensea.
     * this editor will be configured in the `IOriConfig` contract.
     */
    function owner() external view returns (address);

    /*
     * @dev Returns the OriLicense/OriDerivative slave NFT contract address.
     * If no origin NFT, returns zero address.
     */
    function originToken() external view returns (address);

    /**
     *@dev Retruns the kind of this token.
     * must be return TokenKind.OriLicense/OriDerivative.
     */
    function kind() external pure returns (TokenKind);

    /**
     * @notice Creates `amount` tokens of token type `id`, and assigns them to `to`.
     * @param meta is the token meta information.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function create(
        address to,
        bytes calldata meta,
        uint256 amount
    ) external;

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function burn(
        address from,
        uint256 id,
        uint256 amount
    ) external;

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function mint(
        address to,
        uint256 id,
        uint256 amount
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.16;

/**
 * @title OriErrors
 * @author ysqi
 * @notice  OriErrors contains all errors related to Ori protocol.
 */
interface OriErrors {
    /**
     * @dev Revert with an error when a signature that does not contain a v
     *      value of 27 or 28 has been supplied.
     *
     * @param v The invalid v value.
     */
    error BadSignatureV(uint8 v);

    /**
     * @dev Revert with an error when the signer recovered by the supplied
     *      signature does not match the offerer or an allowed EIP-1271 signer
     *      as specified by the offerer in the event they are a contract.
     */
    error InvalidSigner();

    /**
     * @dev Revert with an error when a signer cannot be recovered from the
     *      supplied signature.
     */
    error InvalidSignature();

    /**
     * @dev Revert with an error when an EIP-1271 call to an account fails.
     */
    error BadContractSignature();

    /**
     * @dev Revert with an error when low-level call with value failed without reason.
     */
    error UnknownLowLevelCallFailed();

    /**
     * @dev Errors that occur when NFT expires transfer
     */
    error expiredError(uint256 id);

    /**
     * @dev atomicApproveForAll:approve to op which no implementer
     */
    error atomicApproveForAllNoImpl();

    /**
     * @dev address in not contract
     */
    error notContractError();

    /**
     * @dev not support EIP NFT error
     */
    error notSupportNftTypeError();

    /**
     * @dev not support TokenKind  error
     */
    error notSupportTokenKindError();

    /**
     * @dev not support function  error
     */
    error notSupportFunctionError();
}