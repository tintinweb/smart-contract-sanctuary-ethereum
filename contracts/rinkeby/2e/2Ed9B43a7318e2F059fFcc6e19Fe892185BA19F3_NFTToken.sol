// SPDX-License-Identifier: GPL-3.0
/**
 *     NOTICE
 *
 *     The T-REX software is licensed under a proprietary license or the GPL v.3.
 *     If you choose to receive it under the GPL v.3 license, the following applies:
 *     T-REX is a suite of smart contracts developed by Tokeny to manage and transfer financial assets on the ethereum blockchain
 *
 *     Copyright (C) 2021, Tokeny sàrl.
 *
 *     This program is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     This program is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU General Public License for more details.
 *
 *     You should have received a copy of the GNU General Public License
 *     along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity ^0.8.0;

import './IToken.sol';
import '@onchain-id/solidity/contracts/interface/IERC734.sol';
import '@onchain-id/solidity/contracts/interface/IERC735.sol';
import '@onchain-id/solidity/contracts/interface/IIdentity.sol';
import '../registry/IClaimTopicsRegistry.sol';
import '../registry/IIdentityRegistry.sol';
import '../compliance/ICompliance.sol';
import './Storage.sol';
import '../roles/AgentRoleUpgradeable.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

contract NFTToken is IToken, AgentRoleUpgradeable, TokenStorage, ERC165 {
    using Address for address;
    using Strings for uint256;

    /**
     *  @dev the constructor initiates the token contract
     *  msg.sender is set automatically as the owner of the smart contract
     *  @param _identityRegistry the address of the Identity registry linked to the token
     *  @param _compliance the address of the compliance contract linked to the token
     *  @param _name the name of the token
     *  @param _symbol the symbol of the token
     *  @param _onchainID the address of the onchainID of the token
     *  emits an `UpdatedTokenInformation` event
     *  emits an `IdentityRegistryAdded` event
     *  emits a `ComplianceAdded` event
     */
    function init(
        address _identityRegistry,
        address _compliance,
        string memory _name,
        string memory _symbol,
        address _onchainID
    ) public initializer {
        tokenName = _name;
        tokenSymbol = _symbol;
        tokenOnchainID = _onchainID;
        tokenIdentityRegistry = IIdentityRegistry(_identityRegistry);
        emit IdentityRegistryAdded(_identityRegistry);
        tokenCompliance = ICompliance(_compliance);
        emit ComplianceAdded(_compliance);
        emit UpdatedTokenInformation(tokenName, tokenSymbol, TOKEN_VERSION, tokenOnchainID);
        __Ownable_init();
    }

    /// @dev Modifier to make a function callable only when the contract is not paused.
    modifier whenNotPaused() {
        require(!tokenPaused, 'Pausable: paused');
        _;
    }

    /// @dev Modifier to make a function callable only when the contract is paused.
    modifier whenPaused() {
        require(tokenPaused, 'Pausable: not paused');
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     *  @dev See {IERC20-totalSupply}.
     */
    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    /**
     *  @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address _userAddress11) public view override returns (uint256) {
        return _balances[_userAddress11];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "NFTToken: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual returns (string memory) {
        require(_exists(tokenId), "Token does not exists");
        return bytes(baseURI).length > 0 ? baseURI : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory uri) public onlyOwner {
        baseURI = uri;
    }

   /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ownerOf(tokenId);
        require(to != owner, "NFTToken: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "NFTToken: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "NFTToken: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ownerOf(tokenId) == from, "NFTToken: transfer from incorrect owner");
        require(to != address(0), "NFTToken: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;
        _ownerTokens[to].push(tokenId);

        // Maintaining ownerToken list is necessary, specially for the case of 'recoveryAddress' function
        uint256[] memory senderTokens = _ownerTokens[from];
        for (uint256 i = 0; i < senderTokens.length; i++) {
            if(senderTokens[i] == tokenId) {
                delete senderTokens[i];
                break;
            }
        }

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
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
        require(owner != operator, "NFTToken: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("NFTToken: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "NFTToken: operator query for nonexistent token");
        address owner = ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

   /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "NFTToken: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`. See {ERC721-_mint}
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "NFTToken: mint to the zero address");
        require(!_exists(tokenId), "NFTToken: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;
        _ownerTokens[to].push(tokenId);

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`. See {ERC20-_burn}.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        // Maintaining ownerToken list is necessary, specially for the case of 'recoveryAddress' function
        uint256[] memory ownerTokens = _ownerTokens[owner];
        for (uint256 i = 0; i < ownerTokens.length; i++) {
            if(ownerTokens[i] == tokenId) {
                delete ownerTokens[i];
                break;
            }
        }

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     *  @dev See {IToken-name}.
     */
    function name() external view override returns (string memory) {
        return tokenName;
    }

    /**
     *  @dev See {IToken-onchainID}.
     */
    function onchainID() external view override returns (address) {
        return tokenOnchainID;
    }

    /**
     *  @dev See {IToken-symbol}.
     */
    function symbol() external view override returns (string memory) {
        return tokenSymbol;
    }

    /**
     *  @dev See {IToken-version}.
     */
    function version() external view override returns (string memory) {
        return TOKEN_VERSION;
    }

    /**
     *  @dev See {IToken-setName}.
     */
    function setName(string calldata _name) external override onlyOwner {
        tokenName = _name;
        emit UpdatedTokenInformation(tokenName, tokenSymbol, TOKEN_VERSION, tokenOnchainID);
    }

    /**
     *  @dev See {IToken-setSymbol}.
     */
    function setSymbol(string calldata _symbol) external override onlyOwner {
        tokenSymbol = _symbol;
        emit UpdatedTokenInformation(tokenName, tokenSymbol, TOKEN_VERSION, tokenOnchainID);
    }

    /**
     *  @dev See {IToken-setOnchainID}.
     */
    function setOnchainID(address _onchainID) external override onlyOwner {
        tokenOnchainID = _onchainID;
        emit UpdatedTokenInformation(tokenName, tokenSymbol, TOKEN_VERSION, tokenOnchainID);
    }

    /**
     *  @dev See {IToken-paused}.
     */
    function paused() external view override returns (bool) {
        return tokenPaused;
    }

    /**
     *  @dev See {IToken-isFrozen}.
     */
    function isFrozen(address _userAddress) external view override returns (bool) {
        return frozen[_userAddress];
    }

    /** // Still needs to find out solution to return Frozen token's list
     *  @dev See {IToken-getFrozenTokens}.
     */
    function getFrozenTokens(address _userAddress) external view override returns (uint256[] memory) {
        //return frozenTokens[_userAddress][0];
        return _ownerTokens[_userAddress]; // 
    }

    /**
     *  // Does not exists in ERC721
     *  @notice ERC-20 overridden function that include logic to check for trade validity.
     *  Require that the msg.sender and to addresses are not frozen.
     *  Require that the value should not exceed available balance .
     *  Require that the to address is a verified address
     *  @param _to The address of the receiver
     *  @param _tokenId The number of tokens to transfer
     *  @return `true` if successful and revert if unsuccessful
     */
    function transfer(address _to, uint256 _tokenId) public whenNotPaused returns (bool) {
        require(!frozen[_to] && !frozen[msg.sender], 'wallet is frozen');
        require(_isApprovedOrOwner(_msgSender(), _tokenId), "NFTToken: transfer caller is not owner nor approved");
        require(frozenTokens[msg.sender][_tokenId], 'Token is frozen');
        if (tokenIdentityRegistry.isVerified(_to) && tokenCompliance.canTransfer(msg.sender, _to, _tokenId)) {
            tokenCompliance.transferred(msg.sender, _to, _tokenId);
            _transfer(msg.sender, _to, _tokenId);
            return true;
        }
        revert('Transfer not possible');
    }

    /**
     *  @dev See {IToken-pause}.
     */
    function pause() external override onlyAgent whenNotPaused {
        tokenPaused = true;
        emit Paused(msg.sender);
    }

    /**
     *  @dev See {IToken-unpause}.
     */
    function unpause() external override onlyAgent whenPaused {
        tokenPaused = false;
        emit Unpaused(msg.sender);
    }

    /**
     *  @dev See {IToken-identityRegistry}.
     */
    function identityRegistry() external view override returns (IIdentityRegistry) {
        return tokenIdentityRegistry;
    }

    /**
     *  @dev See {IToken-compliance}.
     */
    function compliance() external view override returns (ICompliance) {
        return tokenCompliance;
    }

    /**
     *  @dev See {IToken-batchTransfer}.
     */
    function batchTransfer(address[] calldata _toList, uint256[] calldata _amounts) external override {
        for (uint256 i = 0; i < _toList.length; i++) {
            transfer(_toList[i], _amounts[i]);
        }
    }

    /**
     *  @notice ERC-721 overridden function that include logic to check for trade validity.
     *  Require that the from and to addresses are not frozen.
     *  Require that the value should not exceed available balance .
     *  Require that the to address is a verified address
     *  @param _from The address of the sender
     *  @param _to The address of the receiver
     *  @param _tokenId The number of tokens to transfer
     *  
     */
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external override whenNotPaused {
        require(!frozen[_to] && !frozen[_from], 'wallet is frozen');
        require(_isApprovedOrOwner(_msgSender(), _tokenId), "NFTToken: transfer caller is not owner nor approved");
        require(frozenTokens[_from][_tokenId], 'Token is frozen');
        if (tokenIdentityRegistry.isVerified(_to) && tokenCompliance.canTransfer(_from, _to, _tokenId)) {
            tokenCompliance.transferred(_from, _to, _tokenId);
            _transfer(_from, _to, _tokenId);
            _approve( msg.sender, _tokenId);
        }

        revert('Transfer not possible');
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override whenNotPaused {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override whenNotPaused {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "NFTToken: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes memory _data
    ) internal virtual {
        require(!frozen[_to] && !frozen[_from], 'wallet is frozen');
        require(frozenTokens[_from][_tokenId], 'Token is frozen');
        if (tokenIdentityRegistry.isVerified(_to) && tokenCompliance.canTransfer(_from, _to, _tokenId)) {
            tokenCompliance.transferred(_from, _to, _tokenId);
            _transfer(_from, _to, _tokenId);
            _approve(msg.sender, _tokenId);
            require(_checkOnERC721Received(_from, _to, _tokenId, _data), "NFTToken: transfer to non ERC721Receiver implementer");
        }
        revert('Transfer not possible');        
    }

    /**
     *  @dev See {IToken-forcedTransfer}.
     */
    function forcedTransfer(
        address _from,
        address _to,
        uint256 _tokenId
    ) public override onlyAgent returns (bool) {
        bool tokenFrozen = frozenTokens[_from][_tokenId];
        if (tokenFrozen) {
            frozenTokens[_from][_tokenId] = false;
            emit TokensUnfrozen(_from, _tokenId);
        }
        if (tokenIdentityRegistry.isVerified(_to)) {
            tokenCompliance.transferred(_from, _to, _tokenId);
            _transfer(_from, _to, _tokenId);
            return true;
        }
        revert('Transfer not possible');
    }

    /**
     *  @dev See {IToken-batchForcedTransfer}.
     */
    function batchForcedTransfer(
        address[] calldata _fromList,
        address[] calldata _toList,
        uint256[] calldata _tokenIds
    ) external override {
        for (uint256 i = 0; i < _fromList.length; i++) {
            forcedTransfer(_fromList[i], _toList[i], _tokenIds[i]);
        }
    }

    /**
     *  @dev See {IToken-mint}.
     */
    function mint(address _to, uint256 _numberOfTokens) public override onlyAgent {
        //require(tokenIdentityRegistry.isVerified(_to), 'Identity is not verified.');
        //require(tokenCompliance.canTransfer(msg.sender, _to, _numberOfTokens), 'Compliance not followed');
        for (uint256 i = 0; i < _numberOfTokens; i++) {
            _mint(_to, _totalSupply++);
        }        
        tokenCompliance.created(_to, _numberOfTokens);
    }

    /**
     *  @dev See {IToken-batchMint}.
     */
    function batchMint(address[] calldata _toList, uint256[] calldata _numberOfTokens) external override {
        for (uint256 i = 0; i < _toList.length; i++) {
            mint(_toList[i], _numberOfTokens[i]);
        }
    }

    /**
     *  @dev See {IToken-burn}.
     */
    function burn(address _userAddress, uint256[] memory _tokenIds) public override onlyAgent {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            bool tokenFrozen = frozenTokens[_userAddress][_tokenIds[i]];
            if (tokenFrozen) {
                frozenTokens[_userAddress][_tokenIds[i]] = false;
                emit TokensUnfrozen(_userAddress, _tokenIds[i]);
            }
            _burn(_tokenIds[i]);
            tokenCompliance.destroyed(_userAddress, _tokenIds[i]);
        }
        
    }

    /**
     *  @dev See {IToken-burn}.
     */
    function burn(address _userAddress, uint256 _tokenId) public override onlyAgent {
        bool tokenFrozen = frozenTokens[_userAddress][_tokenId];
            if (tokenFrozen) {
                frozenTokens[_userAddress][_tokenId] = false;
                emit TokensUnfrozen(_userAddress, _tokenId);
            }
            _burn(_tokenId);
            tokenCompliance.destroyed(_userAddress, _tokenId);        
    }

    /** // Still needs to findout the right solution
     *  @dev See {IToken-batchBurn}.
     */
    function batchBurn(address[] calldata _userAddresses, uint256[] calldata _tokenIds) external override {
        for (uint256 i = 0; i < _userAddresses.length; i++) {
            uint256[] memory id;
            id[0] = _tokenIds[i];
            burn(_userAddresses[i], id);
        }
    }

    /**
     *  @dev See {IToken-setAddressFrozen}.
     */
    function setAddressFrozen(address _userAddress, bool _freeze) public override onlyAgent {
        frozen[_userAddress] = _freeze;

        emit AddressFrozen(_userAddress, _freeze, msg.sender);
    }

    /**
     *  @dev See {IToken-batchSetAddressFrozen}.
     */
    function batchSetAddressFrozen(address[] calldata _userAddresses, bool[] calldata _freeze) external override {
        for (uint256 i = 0; i < _userAddresses.length; i++) {
            setAddressFrozen(_userAddresses[i], _freeze[i]);
        }
    }

    /**
     *  @dev See {IToken-freezePartialTokens}.
     */
    function freezePartialTokens(address _userAddress, uint256[] memory _tokenIds) public override onlyAgent {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            require(_exists(_tokenIds[i]), "NFTToken: operator query for nonexistent token");
            frozenTokens[_userAddress][_tokenIds[i]] = true;
            emit TokensFrozen(_userAddress, _tokenIds[i]);
        }
        
    }

    /**
     *  @dev See {IToken-freezePartialTokens}.
     */
    function freezePartialTokens(address _userAddress, uint256 _tokenId) public override onlyAgent {
        require(_exists(_tokenId), "NFTToken: operator query for nonexistent token");
        frozenTokens[_userAddress][_tokenId] = true;
        emit TokensFrozen(_userAddress, _tokenId);
    }

    /**
     *  @dev See {IToken-batchFreezePartialTokens}.
     */
    function batchFreezePartialTokens(address[] calldata _userAddresses, uint256[] calldata _tokenIds) external override {
        for (uint256 i = 0; i < _userAddresses.length; i++) {
            uint256[] memory id;
            id[0] = _tokenIds[i];
            freezePartialTokens(_userAddresses[i], id);
        }
    }

    /**
     *  @dev See {IToken-unfreezePartialTokens}.
     */
    function unfreezePartialTokens(address _userAddress, uint256[] memory _tokenIds) public override onlyAgent {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            require(_exists(_tokenIds[i]), "NFTToken: operator query for nonexistent token");
            frozenTokens[_userAddress][_tokenIds[i]] = false;
            emit TokensUnfrozen(_userAddress, _tokenIds[i]);
        }
    }

    /**
     *  @dev See {IToken-unfreezePartialTokens}.
     */
    function unfreezePartialTokens(address _userAddress, uint256 _tokenId) public override onlyAgent {
        require(_exists(_tokenId), "NFTToken: operator query for nonexistent token");
        frozenTokens[_userAddress][_tokenId] = false;
        emit TokensUnfrozen(_userAddress, _tokenId);
    }

    /** // need to work on >>>>>>>>..
     *  @dev See {IToken-batchUnfreezePartialTokens}.
     */
    function batchUnfreezePartialTokens(address[] calldata _userAddresses, uint256[] calldata _tokenIds) external override {
        for (uint256 i = 0; i < _userAddresses.length; i++) {
            uint256[] memory id;
            id[0] = _tokenIds[i];
            unfreezePartialTokens(_userAddresses[i], id);
        }
    }

    /**
     *  @dev See {IToken-setIdentityRegistry}.
     */
    function setIdentityRegistry(address _identityRegistry) external override onlyOwner {
        tokenIdentityRegistry = IIdentityRegistry(_identityRegistry);
        emit IdentityRegistryAdded(_identityRegistry);
    }

    /**
     *  @dev See {IToken-setCompliance}.
     */
    function setCompliance(address _compliance) external override onlyOwner {
        tokenCompliance = ICompliance(_compliance);
        emit ComplianceAdded(_compliance);
    }

    /** // need to work on >>>>>>>>..
     *  @dev See {IToken-recoveryAddress}.
     */
    function recoveryAddress(
        address _lostWallet,
        address _newWallet,
        address _investorOnchainID
    ) external override onlyAgent returns (bool) {
        require(balanceOf(_lostWallet) != 0, 'no tokens to recover');
        IIdentity _onchainID = IIdentity(_investorOnchainID);
        bytes32 _key = keccak256(abi.encode(_newWallet));
        if (_onchainID.keyHasPurpose(_key, 1)) {
            uint256[] memory investorTokenIds = _ownerTokens[_lostWallet];
            mapping(uint256 => bool) storage _frozenTokens = frozenTokens[_lostWallet];
            tokenIdentityRegistry.registerIdentity(_newWallet, _onchainID, tokenIdentityRegistry.investorCountry(_lostWallet));
            tokenIdentityRegistry.deleteIdentity(_lostWallet);
            for (uint256 i = 0; i < investorTokenIds.length; i++) {
                forcedTransfer(_lostWallet, _newWallet, investorTokenIds[i]);
            }
            /*
            // Need to find out better solution to freeze tokens once tokens are transfered to new wallet
            if (_frozenTokens > 0) {
                freezePartialTokens(_newWallet, _frozenTokens);
            }*/
            if (frozen[_lostWallet] == true) {
                setAddressFrozen(_newWallet, true);
            }
            emit RecoverySuccess(_lostWallet, _newWallet, _investorOnchainID);
            return true;
        }
        revert('Recovery not possible');
    }

    /**
     *  @dev See {IToken-transferOwnershipOnTokenContract}.
     */
    function transferOwnershipOnTokenContract(address _newOwner) external override onlyOwner {
        transferOwnership(_newOwner);
    }

    /**
     *  @dev See {IToken-addAgentOnTokenContract}.
     */
    function addAgentOnTokenContract(address _agent) external override {
        addAgent(_agent);
    }

    /**
     *  @dev See {IToken-removeAgentOnTokenContract}.
     */
    function removeAgentOnTokenContract(address _agent) external override {
        removeAgent(_agent);
    }
}

// SPDX-License-Identifier: GPL-3.0
/**
 *     NOTICE
 *
 *     The T-REX software is licensed under a proprietary license or the GPL v.3.
 *     If you choose to receive it under the GPL v.3 license, the following applies:
 *     T-REX is a suite of smart contracts developed by Tokeny to manage and transfer financial assets on the ethereum blockchain
 *
 *     Copyright (C) 2021, Tokeny sàrl.
 *
 *     This program is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     This program is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU General Public License for more details.
 *
 *     You should have received a copy of the GNU General Public License
 *     along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity ^0.8.0;

import '../registry/IIdentityRegistry.sol';
import '../compliance/ICompliance.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';

/// @dev interface
interface IToken is IERC721 {

   /**
    *  this event is emitted when the token information is updated.
    *  the event is emitted by the token constructor and by the setTokenInformation function
    *  `_newName` is the name of the token
    *  `_newSymbol` is the symbol of the token
    *  `_newVersion` is the version of the token, current version is 3.0
    *  `_newOnchainID` is the address of the onchainID of the token
    */
    event UpdatedTokenInformation(string _newName, string _newSymbol, string _newVersion, address _newOnchainID);

   /**
    *  this event is emitted when the IdentityRegistry has been set for the token
    *  the event is emitted by the token constructor and by the setIdentityRegistry function
    *  `_identityRegistry` is the address of the Identity Registry of the token
    */
    event IdentityRegistryAdded(address indexed _identityRegistry);

   /**
    *  this event is emitted when the Compliance has been set for the token
    *  the event is emitted by the token constructor and by the setCompliance function
    *  `_compliance` is the address of the Compliance contract of the token
    */
    event ComplianceAdded(address indexed _compliance);

   /**
    *  this event is emitted when an investor successfully recovers his tokens
    *  the event is emitted by the recoveryAddress function
    *  `_lostWallet` is the address of the wallet that the investor lost access to
    *  `_newWallet` is the address of the wallet that the investor provided for the recovery
    *  `_investorOnchainID` is the address of the onchainID of the investor who asked for a recovery
    */
    event RecoverySuccess(address _lostWallet, address _newWallet, address _investorOnchainID);

   /**
    *  this event is emitted when the wallet of an investor is frozen or unfrozen
    *  the event is emitted by setAddressFrozen and batchSetAddressFrozen functions
    *  `_userAddress` is the wallet of the investor that is concerned by the freezing status
    *  `_isFrozen` is the freezing status of the wallet
    *  if `_isFrozen` equals `true` the wallet is frozen after emission of the event
    *  if `_isFrozen` equals `false` the wallet is unfrozen after emission of the event
    *  `_owner` is the address of the agent who called the function to freeze the wallet
    */
    event AddressFrozen(address indexed _userAddress, bool indexed _isFrozen, address indexed _owner);

   /**
    *  this event is emitted when a certain token id is frozen on a wallet
    *  the event is emitted by freezePartialTokens and batchFreezePartialTokens functions
    *  `_userAddress` is the wallet of the investor that is concerned by the freezing status
    *  `_tokenId` is the token id that is frozen
    */
    event TokensFrozen(address indexed _userAddress, uint256 _tokenId);

   /**
    *  this event is emitted when a certain token id is unfrozen on a wallet
    *  the event is emitted by unfreezePartialTokens and batchUnfreezePartialTokens functions
    *  `_userAddress` is the wallet of the investor that is concerned by the freezing status
    *  `_tokenId` is the token id that is frozen
    */
    event TokensUnfrozen(address indexed _userAddress, uint256 _tokenId);

   /**
    *  this event is emitted when the token is paused
    *  the event is emitted by the pause function
    *  `_userAddress` is the address of the wallet that called the pause function
    */
    event Paused(address _userAddress);

   /**
    *  this event is emitted when the token is unpaused
    *  the event is emitted by the unpause function
    *  `_userAddress` is the address of the wallet that called the unpause function
    */
    event Unpaused(address _userAddress);

   /**
    * @dev Returns the name of the token.
    */
    function name() external view returns (string memory);

   /**
    * @dev Returns the address of the onchainID of the token.
    * the onchainID of the token gives all the information available
    * about the token and is managed by the token issuer or his agent.
    */
    function onchainID() external view returns (address);

   /**
    * @dev Returns the symbol of the token, usually a shorter version of the
    * name.
    */
    function symbol() external view returns (string memory);

   /**
    * @dev Returns the TREX version of the token.
    * current version is 3.0.0
    */
    function version() external view returns (string memory);

   /**
    *  @dev Returns the Identity Registry linked to the token
    */
    function identityRegistry() external view returns (IIdentityRegistry);

   /**
    *  @dev Returns the Compliance contract linked to the token
    */
    function compliance() external view returns (ICompliance);

   /**
    * @dev Returns true if the contract is paused, and false otherwise.
    */
    function paused() external view returns (bool);

   /**
    *  @dev Returns the freezing status of a wallet
    *  if isFrozen returns `true` the wallet is frozen
    *  if isFrozen returns `false` the wallet is not frozen
    *  isFrozen returning `true` doesn't mean that the balance is free, tokens could be blocked by
    *  a partial freeze or the whole token could be blocked by pause
    *  @param _userAddress the address of the wallet on which isFrozen is called
    */
    function isFrozen(address _userAddress) external view returns (bool);

   /**
    *  @dev Returns the amount of tokens that are partially frozen on a wallet
    *  the amount of frozen tokens is always <= to the total balance of the wallet
    *  @param _userAddress the address of the wallet on which getFrozenTokens is called
    */
    function getFrozenTokens(address _userAddress) external view returns (uint256[] calldata);

   /**
    *  @dev sets the token name
    *  @param _name the name of token to set
    *  Only the owner of the token smart contract can call this function
    *  emits a `UpdatedTokenInformation` event
    */
    function setName(string calldata _name) external;

   /**
    *  @dev sets the token symbol
    *  @param _symbol the token symbol to set
    *  Only the owner of the token smart contract can call this function
    *  emits a `UpdatedTokenInformation` event
    */
    function setSymbol(string calldata _symbol) external;

   /**
    *  @dev sets the onchain ID of the token
    *  @param _onchainID the address of the onchain ID to set
    *  Only the owner of the token smart contract can call this function
    *  emits a `UpdatedTokenInformation` event
    */
    function setOnchainID(address _onchainID) external;

   /**
    *  @dev pauses the token contract, when contract is paused investors cannot transfer tokens anymore
    *  This function can only be called by a wallet set as agent of the token
    *  emits a `Paused` event
    */
    function pause() external;

   /**
    *  @dev unpauses the token contract, when contract is unpaused investors can transfer tokens
    *  if their wallet is not blocked & if the amount to transfer is <= to the amount of free tokens
    *  This function can only be called by a wallet set as agent of the token
    *  emits an `Unpaused` event
    */
    function unpause() external;

   /**
    *  @dev sets an address frozen status for this token.
    *  @param _userAddress The address for which to update frozen status
    *  @param _freeze Frozen status of the address
    *  This function can only be called by a wallet set as agent of the token
    *  emits an `AddressFrozen` event
    */
    function setAddressFrozen(address _userAddress, bool _freeze) external;

   /**
    *  @dev freezes token amount specified for given address.
    *  @param _userAddress The address for which to update frozen tokens
    *  @param _tokenIds List of Tokens Ids to be frozen
    *  This function can only be called by a wallet set as agent of the token
    *  emits a `TokensFrozen` event
    */
    function freezePartialTokens(address _userAddress, uint256[] calldata _tokenIds) external;

   /**
    *  @dev freezes token amount specified for given address.
    *  @param _userAddress The address for which to update frozen tokens
    *  @param _tokenId Token Id to be frozen
    *  This function can only be called by a wallet set as agent of the token
    *  emits a `TokensFrozen` event
    */
    function freezePartialTokens(address _userAddress, uint256 _tokenId) external;

   /**
    *  @dev unfreezes token amount specified for given address
    *  @param _userAddress The address for which to update frozen tokens
    *  @param _tokenIds List of Tokens Ids to be unfrozen
    *  This function can only be called by a wallet set as agent of the token
    *  emits a `TokensUnfrozen` event
    */
    function unfreezePartialTokens(address _userAddress, uint256[] calldata _tokenIds) external;

   /**
    *  @dev unfreezes token amount specified for given address
    *  @param _userAddress The address for which to update frozen tokens
    *  @param _tokenId Token Id to be unfrozen
    *  This function can only be called by a wallet set as agent of the token
    *  emits a `TokensUnfrozen` event
    */
    function unfreezePartialTokens(address _userAddress, uint256 _tokenId) external;

   /**
    *  @dev sets the Identity Registry for the token
    *  @param _identityRegistry the address of the Identity Registry to set
    *  Only the owner of the token smart contract can call this function
    *  emits an `IdentityRegistryAdded` event
    */
    function setIdentityRegistry(address _identityRegistry) external;

   /**
    *  @dev sets the compliance contract of the token
    *  @param _compliance the address of the compliance contract to set
    *  Only the owner of the token smart contract can call this function
    *  emits a `ComplianceAdded` event
    */
    function setCompliance(address _compliance) external;

   /**
    *  @dev force a transfer of tokens between 2 whitelisted wallets
    *  In case the `from` address has forzen token id this will force transfer token to 
    *  `to` address
    *  Require that the `to` address is a verified address,
    *  @param _from The address of the sender
    *  @param _to The address of the receiver
    *  @param _tokenId The token id to transfer
    *  @return `true` if successful and revert if unsuccessful
    *  This function can only be called by a wallet set as agent of the token
    *  emits a `TokensUnfrozen` event if `_tokenId` is frozen in `_from`
    *  emits a `Transfer` event
    */
    function forcedTransfer(address _from, address _to, uint256 _tokenId) external returns (bool);

   /**
    *  @dev mint tokens on a wallet
    *  Improved version of default mint method. Tokens can be minted
    *  to an address if only it is a verified address as per the security token.
    *  @param _to Address to mint the tokens to.
    *  @param _numberOfTokens Number of Tokens to be minted.
    *  This function can only be called by a wallet set as agent of the token
    *  emits a `Transfer` event
    */
    function mint(address _to, uint256 _numberOfTokens) external;

   /**
    *  @dev burn tokens on a wallet
    *  In case the `account` address has not enough free tokens (unfrozen tokens)
    *  but has a total balance higher or equal to the `value` amount
    *  the amount of frozen tokens is reduced in order to have enough free tokens
    *  to proceed the burn, in such a case, the remaining balance on the `account`
    *  is 100% composed of frozen tokens post-transaction.
    *  @param _userAddress Address to burn the tokens from.
    *  @param _tokenIds List of token ids to be burn.
    *  This function can only be called by a wallet set as agent of the token
    *  emits a `TokensUnfrozen` event if `_amount` is higher than the free balance of `_userAddress`
    *  emits a `Transfer` event
    */
    function burn(address _userAddress, uint256[] calldata _tokenIds) external;

       /**
    *  @dev burn tokens on a wallet
    *  In case the `account` address has not enough free tokens (unfrozen tokens)
    *  but has a total balance higher or equal to the `value` amount
    *  the amount of frozen tokens is reduced in order to have enough free tokens
    *  to proceed the burn, in such a case, the remaining balance on the `account`
    *  is 100% composed of frozen tokens post-transaction.
    *  @param _userAddress Address to burn the tokens from.
    *  @param _tokenId Token id to be burn.
    *  This function can only be called by a wallet set as agent of the token
    *  emits a `TokensUnfrozen` event if `_amount` is higher than the free balance of `_userAddress`
    *  emits a `Transfer` event
    */
    function burn(address _userAddress, uint256 _tokenId) external;

   /**
    *  @dev recovery function used to force transfer tokens from a
    *  lost wallet to a new wallet for an investor.
    *  @param _lostWallet the wallet that the investor lost
    *  @param _newWallet the newly provided wallet on which tokens have to be transferred
    *  @param _investorOnchainID the onchainID of the investor asking for a recovery
    *  This function can only be called by a wallet set as agent of the token
    *  emits a `TokensUnfrozen` event if there is some frozen tokens on the lost wallet if the recovery process is successful
    *  emits a `Transfer` event if the recovery process is successful
    *  emits a `RecoverySuccess` event if the recovery process is successful
    *  emits a `RecoveryFails` event if the recovery process fails
    */
    function recoveryAddress(address _lostWallet, address _newWallet, address _investorOnchainID) external returns (bool);

   /**
    *  @dev function allowing to issue transfers in batch
    *  Require that the msg.sender and `to` addresses are not frozen.
    *  Require that the _tokenids should not be frozen.
    *  Require that the `to` addresses are all verified addresses,
    *  IMPORTANT : THIS TRANSACTION COULD EXCEED GAS LIMIT IF `_toList.length` IS TOO HIGH,
    *  USE WITH CARE OR YOU COULD LOSE TX FEES WITH AN "OUT OF GAS" TRANSACTION
    *  @param _toList The addresses of the receivers
    *  @param _tokenIds The token id to transfer to the corresponding receiver
    *  emits _toList.length `Transfer` events
    */
    function batchTransfer(address[] calldata _toList, uint256[] calldata _tokenIds) external;

   /**
    *  @dev function allowing to issue forced transfers in batch
    *  Require that `_tokenids[i]` should not be frozen in `_fromList[i]`.
    *  Require that the `_toList` addresses are all verified addresses
    *  IMPORTANT : THIS TRANSACTION COULD EXCEED GAS LIMIT IF `_fromList.length` IS TOO HIGH,
    *  USE WITH CARE OR YOU COULD LOSE TX FEES WITH AN "OUT OF GAS" TRANSACTION
    *  @param _fromList The addresses of the senders
    *  @param _toList The addresses of the receivers
    *  @param _tokenIds The token id to transfer to the corresponding receiver
    *  This function can only be called by a wallet set as agent of the token
    *  emits `TokensUnfrozen` events if `_amounts[i]` is higher than the free balance of `_fromList[i]`
    *  emits _fromList.length `Transfer` events
    */
    function batchForcedTransfer(address[] calldata _fromList, address[] calldata _toList, uint256[] calldata _tokenIds) external;

   /**
    *  @dev function allowing to mint tokens in batch
    *  Require that the `_toList` addresses are all verified addresses
    *  IMPORTANT : THIS TRANSACTION COULD EXCEED GAS LIMIT IF `_toList.length` IS TOO HIGH,
    *  USE WITH CARE OR YOU COULD LOSE TX FEES WITH AN "OUT OF GAS" TRANSACTION
    *  @param _toList The addresses of the receivers
    *  @param _numberOfTokens The number of tokens to mint to the corresponding receiver
    *  This function can only be called by a wallet set as agent of the token
    *  emits _toList.length `Transfer` events
    */
    function batchMint(address[] calldata _toList, uint256[] calldata _numberOfTokens) external;

   /**
    *  @dev function allowing to burn tokens in batch
    *  Require that the `_userAddresses` addresses are all verified addresses
    *  IMPORTANT : THIS TRANSACTION COULD EXCEED GAS LIMIT IF `_userAddresses.length` IS TOO HIGH,
    *  USE WITH CARE OR YOU COULD LOSE TX FEES WITH AN "OUT OF GAS" TRANSACTION
    *  @param _userAddresses The addresses of the wallets concerned by the burn
    *  @param _tokenIds The token id to burn from the corresponding wallets, single token id for each address
    *  This function can only be called by a wallet set as agent of the token
    *  emits _userAddresses.length `Transfer` events
    */
    function batchBurn(address[] calldata _userAddresses, uint256[] calldata _tokenIds) external;

   /**
    *  @dev function allowing to set frozen addresses in batch
    *  IMPORTANT : THIS TRANSACTION COULD EXCEED GAS LIMIT IF `_userAddresses.length` IS TOO HIGH,
    *  USE WITH CARE OR YOU COULD LOSE TX FEES WITH AN "OUT OF GAS" TRANSACTION
    *  @param _userAddresses The addresses for which to update frozen status
    *  @param _freeze Frozen status of the corresponding address
    *  This function can only be called by a wallet set as agent of the token
    *  emits _userAddresses.length `AddressFrozen` events
    */
    function batchSetAddressFrozen(address[] calldata _userAddresses, bool[] calldata _freeze) external;

   /**
    *  @dev function allowing to freeze tokens partially in batch
    *  IMPORTANT : THIS TRANSACTION COULD EXCEED GAS LIMIT IF `_userAddresses.length` IS TOO HIGH,
    *  USE WITH CARE OR YOU COULD LOSE TX FEES WITH AN "OUT OF GAS" TRANSACTION
    *  @param _userAddresses The addresses on which tokens need to be frozen
    *  @param _tokenIds the token id to freeze on the corresponding address, single token id for each address
    *  This function can only be called by a wallet set as agent of the token
    *  emits _userAddresses.length `TokensFrozen` events
    */
    function batchFreezePartialTokens(address[] calldata _userAddresses, uint256[] calldata _tokenIds) external;

   /**
    *  @dev function allowing to unfreeze tokens partially in batch
    *  IMPORTANT : THIS TRANSACTION COULD EXCEED GAS LIMIT IF `_userAddresses.length` IS TOO HIGH,
    *  USE WITH CARE OR YOU COULD LOSE TX FEES WITH AN "OUT OF GAS" TRANSACTION
    *  @param _userAddresses The addresses on which tokens need to be unfrozen
    *  @param _tokenIds the token id to unfreeze on the corresponding address, single token id for each address
    *  This function can only be called by a wallet set as agent of the token
    *  emits _userAddresses.length `TokensUnfrozen` events
    */
    function batchUnfreezePartialTokens(address[] calldata _userAddresses, uint256[] calldata _tokenIds) external;

   /**
    *  @dev transfers the ownership of the token smart contract
    *  @param _newOwner the address of the new token smart contract owner
    *  This function can only be called by the owner of the token
    *  emits an `OwnershipTransferred` event
    */
    function transferOwnershipOnTokenContract(address _newOwner) external;

   /**
    *  @dev adds an agent to the token smart contract
    *  @param _agent the address of the new agent of the token smart contract
    *  This function can only be called by the owner of the token
    *  emits an `AgentAdded` event
    */
    function addAgentOnTokenContract(address _agent) external;

   /**
    *  @dev remove an agent from the token smart contract
    *  @param _agent the address of the agent to remove
    *  This function can only be called by the owner of the token
    *  emits an `AgentRemoved` event
    */
    function removeAgentOnTokenContract(address _agent) external;

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

/**
 * @dev interface of the ERC734 (Key Holder) standard as defined in the EIP.
 */
interface IERC734 {

    /**
     * @dev Emitted when an execution request was approved.
     *
     * Specification: MUST be triggered when approve was successfully called.
     */
    event Approved(uint256 indexed executionId, bool approved);

    /**
     * @dev Emitted when an execute operation was approved and successfully performed.
     *
     * Specification: MUST be triggered when approve was called and the execution was successfully approved.
     */
    event Executed(uint256 indexed executionId, address indexed to, uint256 indexed value, bytes data);

    /**
     * @dev Emitted when an execution request was performed via `execute`.
     *
     * Specification: MUST be triggered when execute was successfully called.
     */
    event ExecutionRequested(uint256 indexed executionId, address indexed to, uint256 indexed value, bytes data);

    event ExecutionFailed(uint256 indexed executionId, address indexed to, uint256 indexed value, bytes data);

    /**
     * @dev Emitted when a key was added to the Identity.
     *
     * Specification: MUST be triggered when addKey was successfully called.
     */
    event KeyAdded(bytes32 indexed key, uint256 indexed purpose, uint256 indexed keyType);

    /**
     * @dev Emitted when a key was removed from the Identity.
     *
     * Specification: MUST be triggered when removeKey was successfully called.
     */
    event KeyRemoved(bytes32 indexed key, uint256 indexed purpose, uint256 indexed keyType);

    /**
     * @dev Emitted when the list of required keys to perform an action was updated.
     *
     * Specification: MUST be triggered when changeKeysRequired was successfully called.
     */
    event KeysRequiredChanged(uint256 purpose, uint256 number);


    /**
     * @dev Adds a _key to the identity. The _purpose specifies the purpose of the key.
     *
     * Triggers Event: `KeyAdded`
     *
     * Specification: MUST only be done by keys of purpose 1, or the identity itself. If it's the identity itself, the approval process will determine its approval.
     */
    function addKey(bytes32 _key, uint256 _purpose, uint256 _keyType) external returns (bool success);

    /**
    * @dev Approves an execution or claim addition.
    *
    * Triggers Event: `Approved`, `Executed`
    *
    * Specification:
    * This SHOULD require n of m approvals of keys purpose 1, if the _to of the execution is the identity contract itself, to successfully approve an execution.
    * And COULD require n of m approvals of keys purpose 2, if the _to of the execution is another contract, to successfully approve an execution.
    */
    function approve(uint256 _id, bool _approve) external returns (bool success);

    /**
     * @dev Passes an execution instruction to an ERC725 identity.
     *
     * Triggers Event: `ExecutionRequested`, `Executed`
     *
     * Specification:
     * SHOULD require approve to be called with one or more keys of purpose 1 or 2 to approve this execution.
     * Execute COULD be used as the only accessor for `addKey` and `removeKey`.
     */
    function execute(address _to, uint256 _value, bytes calldata _data) external payable returns (uint256 executionId);

    /**
     * @dev Returns the full key data, if present in the identity.
     */
    function getKey(bytes32 _key) external view returns (uint256[] memory purposes, uint256 keyType, bytes32 key);

    /**
     * @dev Returns the list of purposes associated with a key.
     */
    function getKeyPurposes(bytes32 _key) external view returns(uint256[] memory _purposes);

    /**
     * @dev Returns an array of public key bytes32 held by this identity.
     */
    function getKeysByPurpose(uint256 _purpose) external view returns (bytes32[] memory keys);

    /**
     * @dev Returns TRUE if a key is present and has the given purpose. If the key is not present it returns FALSE.
     */
    function keyHasPurpose(bytes32 _key, uint256 _purpose) external view returns (bool exists);

    /**
     * @dev Removes _purpose for _key from the identity.
     *
     * Triggers Event: `KeyRemoved`
     *
     * Specification: MUST only be done by keys of purpose 1, or the identity itself. If it's the identity itself, the approval process will determine its approval.
     */
    function removeKey(bytes32 _key, uint256 _purpose) external returns (bool success);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

/**
 * @dev interface of the ERC735 (Claim Holder) standard as defined in the EIP.
 */
interface IERC735 {

    /**
     * @dev Emitted when a claim request was performed.
     *
     * Specification: Is not clear
     */
    event ClaimRequested(uint256 indexed claimRequestId, uint256 indexed topic, uint256 scheme, address indexed issuer, bytes signature, bytes data, string uri);

    /**
     * @dev Emitted when a claim was added.
     *
     * Specification: MUST be triggered when a claim was successfully added.
     */
    event ClaimAdded(bytes32 indexed claimId, uint256 indexed topic, uint256 scheme, address indexed issuer, bytes signature, bytes data, string uri);

    /**
     * @dev Emitted when a claim was removed.
     *
     * Specification: MUST be triggered when removeClaim was successfully called.
     */
    event ClaimRemoved(bytes32 indexed claimId, uint256 indexed topic, uint256 scheme, address indexed issuer, bytes signature, bytes data, string uri);

    /**
     * @dev Emitted when a claim was changed.
     *
     * Specification: MUST be triggered when changeClaim was successfully called.
     */
    event ClaimChanged(bytes32 indexed claimId, uint256 indexed topic, uint256 scheme, address indexed issuer, bytes signature, bytes data, string uri);

    /**
     * @dev Get a claim by its ID.
     *
     * Claim IDs are generated using `keccak256(abi.encode(address issuer_address, uint256 topic))`.
     */
    function getClaim(bytes32 _claimId) external view returns(uint256 topic, uint256 scheme, address issuer, bytes memory signature, bytes memory data, string memory uri);

    /**
     * @dev Returns an array of claim IDs by topic.
     */
    function getClaimIdsByTopic(uint256 _topic) external view returns(bytes32[] memory claimIds);

    /**
     * @dev Add or update a claim.
     *
     * Triggers Event: `ClaimRequested`, `ClaimAdded`, `ClaimChanged`
     *
     * Specification: Requests the ADDITION or the CHANGE of a claim from an issuer.
     * Claims can requested to be added by anybody, including the claim holder itself (self issued).
     *
     * _signature is a signed message of the following structure: `keccak256(abi.encode(address identityHolder_address, uint256 topic, bytes data))`.
     * Claim IDs are generated using `keccak256(abi.encode(address issuer_address + uint256 topic))`.
     *
     * This COULD implement an approval process for pending claims, or add them right away.
     * MUST return a claimRequestId (use claim ID) that COULD be sent to the approve function.
     */
    function addClaim(uint256 _topic, uint256 _scheme, address issuer, bytes calldata _signature, bytes calldata _data, string calldata _uri) external returns (bytes32 claimRequestId);

    /**
     * @dev Removes a claim.
     *
     * Triggers Event: `ClaimRemoved`
     *
     * Claim IDs are generated using `keccak256(abi.encode(address issuer_address, uint256 topic))`.
     */
    function removeClaim(bytes32 _claimId) external returns (bool success);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./IERC734.sol";
import "./IERC735.sol";

interface IIdentity is IERC734, IERC735 {}

// SPDX-License-Identifier: GPL-3.0
/**
 *     NOTICE
 *
 *     The T-REX software is licensed under a proprietary license or the GPL v.3.
 *     If you choose to receive it under the GPL v.3 license, the following applies:
 *     T-REX is a suite of smart contracts developed by Tokeny to manage and transfer financial assets on the ethereum blockchain
 *
 *     Copyright (C) 2021, Tokeny sàrl.
 *
 *     This program is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     This program is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU General Public License for more details.
 *
 *     You should have received a copy of the GNU General Public License
 *     along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity ^0.8.0;

interface IClaimTopicsRegistry {
    /**
     *  this event is emitted when a claim topic has been added to the ClaimTopicsRegistry
     *  the event is emitted by the 'addClaimTopic' function
     *  `claimTopic` is the required claim added to the Claim Topics Registry
     */
    event ClaimTopicAdded(uint256 indexed claimTopic);

    /**
     *  this event is emitted when a claim topic has been removed from the ClaimTopicsRegistry
     *  the event is emitted by the 'removeClaimTopic' function
     *  `claimTopic` is the required claim removed from the Claim Topics Registry
     */
    event ClaimTopicRemoved(uint256 indexed claimTopic);

    /**
     * @dev Add a trusted claim topic (For example: KYC=1, AML=2).
     * Only owner can call.
     * emits `ClaimTopicAdded` event
     * @param _claimTopic The claim topic index
     */
    function addClaimTopic(uint256 _claimTopic) external;

    /**
     *  @dev Remove a trusted claim topic (For example: KYC=1, AML=2).
     *  Only owner can call.
     *  emits `ClaimTopicRemoved` event
     *  @param _claimTopic The claim topic index
     */
    function removeClaimTopic(uint256 _claimTopic) external;

    /**
     *  @dev Get the trusted claim topics for the security token
     *  @return Array of trusted claim topics
     */
    function getClaimTopics() external view returns (uint256[] memory);

    /**
     *  @dev Transfers the Ownership of ClaimTopics to a new Owner.
     *  Only owner can call.
     *  @param _newOwner The new owner of this contract.
     */
    function transferOwnershipOnClaimTopicsRegistryContract(address _newOwner) external;
}

// SPDX-License-Identifier: GPL-3.0
/**
 *     NOTICE
 *
 *     The T-REX software is licensed under a proprietary license or the GPL v.3.
 *     If you choose to receive it under the GPL v.3 license, the following applies:
 *     T-REX is a suite of smart contracts developed by Tokeny to manage and transfer financial assets on the ethereum blockchain
 *
 *     Copyright (C) 2021, Tokeny sàrl.
 *
 *     This program is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     This program is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU General Public License for more details.
 *
 *     You should have received a copy of the GNU General Public License
 *     along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity ^0.8.0;

import '../registry/ITrustedIssuersRegistry.sol';
import '../registry/IClaimTopicsRegistry.sol';
import '../registry/IIdentityRegistryStorage.sol';

import '@onchain-id/solidity/contracts/interface/IClaimIssuer.sol';
import '@onchain-id/solidity/contracts/interface/IIdentity.sol';

interface IIdentityRegistry {
    /**
     *  this event is emitted when the ClaimTopicsRegistry has been set for the IdentityRegistry
     *  the event is emitted by the IdentityRegistry constructor
     *  `claimTopicsRegistry` is the address of the Claim Topics Registry contract
     */
    event ClaimTopicsRegistrySet(address indexed claimTopicsRegistry);

    /**
     *  this event is emitted when the IdentityRegistryStorage has been set for the IdentityRegistry
     *  the event is emitted by the IdentityRegistry constructor
     *  `identityStorage` is the address of the Identity Registry Storage contract
     */
    event IdentityStorageSet(address indexed identityStorage);

    /**
     *  this event is emitted when the ClaimTopicsRegistry has been set for the IdentityRegistry
     *  the event is emitted by the IdentityRegistry constructor
     *  `trustedIssuersRegistry` is the address of the Trusted Issuers Registry contract
     */
    event TrustedIssuersRegistrySet(address indexed trustedIssuersRegistry);

    /**
     *  this event is emitted when an Identity is registered into the Identity Registry.
     *  the event is emitted by the 'registerIdentity' function
     *  `investorAddress` is the address of the investor's wallet
     *  `identity` is the address of the Identity smart contract (onchainID)
     */
    event IdentityRegistered(address indexed investorAddress, IIdentity indexed identity);

    /**
     *  this event is emitted when an Identity is removed from the Identity Registry.
     *  the event is emitted by the 'deleteIdentity' function
     *  `investorAddress` is the address of the investor's wallet
     *  `identity` is the address of the Identity smart contract (onchainID)
     */
    event IdentityRemoved(address indexed investorAddress, IIdentity indexed identity);

    /**
     *  this event is emitted when an Identity has been updated
     *  the event is emitted by the 'updateIdentity' function
     *  `oldIdentity` is the old Identity contract's address to update
     *  `newIdentity` is the new Identity contract's
     */
    event IdentityUpdated(IIdentity indexed oldIdentity, IIdentity indexed newIdentity);

    /**
     *  this event is emitted when an Identity's country has been updated
     *  the event is emitted by the 'updateCountry' function
     *  `investorAddress` is the address on which the country has been updated
     *  `country` is the numeric code (ISO 3166-1) of the new country
     */
    event CountryUpdated(address indexed investorAddress, uint16 indexed country);

    /**
     *  @dev Register an identity contract corresponding to a user address.
     *  Requires that the user doesn't have an identity contract already registered.
     *  This function can only be called by a wallet set as agent of the smart contract
     *  @param _userAddress The address of the user
     *  @param _identity The address of the user's identity contract
     *  @param _country The country of the investor
     *  emits `IdentityRegistered` event
     */
    function registerIdentity(
        address _userAddress,
        IIdentity _identity,
        uint16 _country
    ) external;

    /**
     *  @dev Removes an user from the identity registry.
     *  Requires that the user have an identity contract already deployed that will be deleted.
     *  This function can only be called by a wallet set as agent of the smart contract
     *  @param _userAddress The address of the user to be removed
     *  emits `IdentityRemoved` event
     */
    function deleteIdentity(address _userAddress) external;

    /**
     *  @dev Replace the actual identityRegistryStorage contract with a new one.
     *  This function can only be called by the wallet set as owner of the smart contract
     *  @param _identityRegistryStorage The address of the new Identity Registry Storage
     *  emits `IdentityStorageSet` event
     */
    function setIdentityRegistryStorage(address _identityRegistryStorage) external;

    /**
     *  @dev Replace the actual claimTopicsRegistry contract with a new one.
     *  This function can only be called by the wallet set as owner of the smart contract
     *  @param _claimTopicsRegistry The address of the new claim Topics Registry
     *  emits `ClaimTopicsRegistrySet` event
     */
    function setClaimTopicsRegistry(address _claimTopicsRegistry) external;

    /**
     *  @dev Replace the actual trustedIssuersRegistry contract with a new one.
     *  This function can only be called by the wallet set as owner of the smart contract
     *  @param _trustedIssuersRegistry The address of the new Trusted Issuers Registry
     *  emits `TrustedIssuersRegistrySet` event
     */
    function setTrustedIssuersRegistry(address _trustedIssuersRegistry) external;

    /**
     *  @dev Updates the country corresponding to a user address.
     *  Requires that the user should have an identity contract already deployed that will be replaced.
     *  This function can only be called by a wallet set as agent of the smart contract
     *  @param _userAddress The address of the user
     *  @param _country The new country of the user
     *  emits `CountryUpdated` event
     */
    function updateCountry(address _userAddress, uint16 _country) external;

    /**
     *  @dev Updates an identity contract corresponding to a user address.
     *  Requires that the user address should be the owner of the identity contract.
     *  Requires that the user should have an identity contract already deployed that will be replaced.
     *  This function can only be called by a wallet set as agent of the smart contract
     *  @param _userAddress The address of the user
     *  @param _identity The address of the user's new identity contract
     *  emits `IdentityUpdated` event
     */
    function updateIdentity(address _userAddress, IIdentity _identity) external;

    /**
     *  @dev function allowing to register identities in batch
     *  This function can only be called by a wallet set as agent of the smart contract
     *  Requires that none of the users has an identity contract already registered.
     *  IMPORTANT : THIS TRANSACTION COULD EXCEED GAS LIMIT IF `_userAddresses.length` IS TOO HIGH,
     *  USE WITH CARE OR YOU COULD LOSE TX FEES WITH AN "OUT OF GAS" TRANSACTION
     *  @param _userAddresses The addresses of the users
     *  @param _identities The addresses of the corresponding identity contracts
     *  @param _countries The countries of the corresponding investors
     *  emits _userAddresses.length `IdentityRegistered` events
     */
    function batchRegisterIdentity(
        address[] calldata _userAddresses,
        IIdentity[] calldata _identities,
        uint16[] calldata _countries
    ) external;

    /**
     *  @dev This functions checks whether a wallet has its Identity registered or not
     *  in the Identity Registry.
     *  @param _userAddress The address of the user to be checked.
     *  @return 'True' if the address is contained in the Identity Registry, 'false' if not.
     */
    function contains(address _userAddress) external view returns (bool);

    /**
     *  @dev This functions checks whether an identity contract
     *  corresponding to the provided user address has the required claims or not based
     *  on the data fetched from trusted issuers registry and from the claim topics registry
     *  @param _userAddress The address of the user to be verified.
     *  @return 'True' if the address is verified, 'false' if not.
     */
    function isVerified(address _userAddress) external view returns (bool);

    /**
     *  @dev Returns the onchainID of an investor.
     *  @param _userAddress The wallet of the investor
     */
    function identity(address _userAddress) external view returns (IIdentity);

    /**
     *  @dev Returns the country code of an investor.
     *  @param _userAddress The wallet of the investor
     */
    function investorCountry(address _userAddress) external view returns (uint16);

    /**
     *  @dev Returns the IdentityRegistryStorage linked to the current IdentityRegistry.
     */
    function identityStorage() external view returns (IIdentityRegistryStorage);

    /**
     *  @dev Returns the TrustedIssuersRegistry linked to the current IdentityRegistry.
     */
    function issuersRegistry() external view returns (ITrustedIssuersRegistry);

    /**
     *  @dev Returns the ClaimTopicsRegistry linked to the current IdentityRegistry.
     */
    function topicsRegistry() external view returns (IClaimTopicsRegistry);

    /**
     *  @notice Transfers the Ownership of the Identity Registry to a new Owner.
     *  This function can only be called by the wallet set as owner of the smart contract
     *  @param _newOwner The new owner of this contract.
     */
    function transferOwnershipOnIdentityRegistryContract(address _newOwner) external;

    /**
     *  @notice Adds an address as _agent of the Identity Registry Contract.
     *  This function can only be called by the wallet set as owner of the smart contract
     *  @param _agent The _agent's address to add.
     */
    function addAgentOnIdentityRegistryContract(address _agent) external;

    /**
     *  @notice Removes an address from being _agent of the Identity Registry Contract.
     *  This function can only be called by the wallet set as owner of the smart contract
     *  @param _agent The _agent's address to remove.
     */
    function removeAgentOnIdentityRegistryContract(address _agent) external;
}

// SPDX-License-Identifier: GPL-3.0

/**
 *     NOTICE
 *
 *     The T-REX software is licensed under a proprietary license or the GPL v.3.
 *     If you choose to receive it under the GPL v.3 license, the following applies:
 *     T-REX is a suite of smart contracts developed by Tokeny to manage and transfer financial assets on the ethereum blockchain
 *
 *     Copyright (C) 2021, Tokeny sàrl.
 *
 *     This program is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     This program is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU General Public License for more details.
 *
 *     You should have received a copy of the GNU General Public License
 *     along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity ^0.8.0;

interface ICompliance {
    /**
     *  this event is emitted when the Agent has been added on the allowedList of this Compliance.
     *  the event is emitted by the Compliance constructor and by the addTokenAgent function
     *  `_agentAddress` is the address of the Agent to add
     */
    event TokenAgentAdded(address _agentAddress);

    /**
     *  this event is emitted when the Agent has been removed from the agent list of this Compliance.
     *  the event is emitted by the Compliance constructor and by the removeTokenAgent function
     *  `_agentAddress` is the address of the Agent to remove
     */
    event TokenAgentRemoved(address _agentAddress);

    /**
     *  this event is emitted when a token has been bound to the compliance contract
     *  the event is emitted by the bindToken function
     *  `_token` is the address of the token to bind
     */
    event TokenBound(address _token);

    /**
     *  this event is emitted when a token has been unbound from the compliance contract
     *  the event is emitted by the unbindToken function
     *  `_token` is the address of the token to unbind
     */
    event TokenUnbound(address _token);

    /**
     *  @dev Returns true if the Address is in the list of token agents
     *  @param _agentAddress address of this agent
     */
    function isTokenAgent(address _agentAddress) external view returns (bool);

    /**
     *  @dev Returns true if the address given corresponds to a token that is bound with the Compliance contract
     *  @param _token address of the token
     */
    function isTokenBound(address _token) external view returns (bool);

    /**
     *  @dev adds an agent to the list of token agents
     *  @param _agentAddress address of the agent to be added
     *  Emits a TokenAgentAdded event
     */
    function addTokenAgent(address _agentAddress) external;

    /**
     *  @dev remove Agent from the list of token agents
     *  @param _agentAddress address of the agent to be removed (must be added first)
     *  Emits a TokenAgentRemoved event
     */
    function removeTokenAgent(address _agentAddress) external;

    /**
     *  @dev binds a token to the compliance contract
     *  @param _token address of the token to bind
     *  Emits a TokenBound event
     */
    function bindToken(address _token) external;

    /**
     *  @dev unbinds a token from the compliance contract
     *  @param _token address of the token to unbind
     *  Emits a TokenUnbound event
     */
    function unbindToken(address _token) external;

    /**
     *  @dev checks that the transfer is compliant.
     *  default compliance always returns true
     *  READ ONLY FUNCTION, this function cannot be used to increment
     *  counters, emit events, ...
     *  @param _from The address of the sender
     *  @param _to The address of the receiver
     *  @param _amount The amount of tokens involved in the transfer
     */
    function canTransfer(
        address _from,
        address _to,
        uint256 _amount
    ) external view returns (bool);

    /**
     *  @dev function called whenever tokens are transferred
     *  from one wallet to another
     *  this function can update state variables in the compliance contract
     *  these state variables being used by `canTransfer` to decide if a transfer
     *  is compliant or not depending on the values stored in these state variables and on
     *  the parameters of the compliance smart contract
     *  @param _from The address of the sender
     *  @param _to The address of the receiver
     *  @param _amount The amount of tokens involved in the transfer
     */
    function transferred(
        address _from,
        address _to,
        uint256 _amount
    ) external;

    /**
     *  @dev function called whenever tokens are created
     *  on a wallet
     *  this function can update state variables in the compliance contract
     *  these state variables being used by `canTransfer` to decide if a transfer
     *  is compliant or not depending on the values stored in these state variables and on
     *  the parameters of the compliance smart contract
     *  @param _to The address of the receiver
     *  @param _amount The amount of tokens involved in the transfer
     */
    function created(address _to, uint256 _amount) external;

    /**
     *  @dev function called whenever tokens are destroyed
     *  this function can update state variables in the compliance contract
     *  these state variables being used by `canTransfer` to decide if a transfer
     *  is compliant or not depending on the values stored in these state variables and on
     *  the parameters of the compliance smart contract
     *  @param _from The address of the receiver
     *  @param _amount The amount of tokens involved in the transfer
     */
    function destroyed(address _from, uint256 _amount) external;

    /**
     *  @dev function used to transfer the ownership of the compliance contract
     *  to a new owner, giving him access to the `OnlyOwner` functions implemented on the contract
     *  @param newOwner The address of the new owner of the compliance contract
     *  This function can only be called by the owner of the compliance contract
     *  emits an `OwnershipTransferred` event
     */
    function transferOwnershipOnComplianceContract(address newOwner) external;
}

// SPDX-License-Identifier: GPL-3.0
/**
 *     NOTICE
 *
 *     The T-REX software is licensed under a proprietary license or the GPL v.3.
 *     If you choose to receive it under the GPL v.3 license, the following applies:
 *     T-REX is a suite of smart contracts developed by Tokeny to manage and transfer financial assets on the ethereum blockchain
 *
 *     Copyright (C) 2021, Tokeny sàrl.
 *
 *     This program is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     This program is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU General Public License for more details.
 *
 *     You should have received a copy of the GNU General Public License
 *     along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity ^0.8.0;
import '../compliance/ICompliance.sol';
import '../registry/IIdentityRegistry.sol';

contract TokenStorage {
    /// @dev ERC721 basic variables

    // Mapping from token ID to owner address
    mapping(uint256 => address) internal _owners;
    // Mapping from token ID to owner address
    mapping(address => uint256[]) internal _ownerTokens;

    // Mapping owner address to token count
    mapping(address => uint256) internal _balances;
    // Mapping from token ID to approved address
    mapping(uint256 => address) internal _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) internal _operatorApprovals;
    uint256 internal _totalSupply;

    /// @dev Token information
    string internal tokenName;
    string internal tokenSymbol;
    address internal tokenOnchainID;
    string internal constant TOKEN_VERSION = '3.5.1';

    /// @dev Variables of freeze and pause functions
    mapping(address => bool) internal frozen;
    mapping(address => mapping(uint256 => bool)) internal frozenTokens;
    
    bool internal tokenPaused = false;

    /// @dev Identity Registry contract used by the onchain validator system
    IIdentityRegistry internal tokenIdentityRegistry;

    /// @dev Compliance contract linked to the onchain validator system
    ICompliance internal tokenCompliance;

    string public baseURI;
    uint256 public price = 2 ether;
    uint256 public constant MAX_SUPPLY = 10000;


}

// SPDX-License-Identifier: GPL-3.0
/**
 *     NOTICE
 *
 *     The T-REX software is licensed under a proprietary license or the GPL v.3.
 *     If you choose to receive it under the GPL v.3 license, the following applies:
 *     T-REX is a suite of smart contracts developed by Tokeny to manage and transfer financial assets on the ethereum blockchain
 *
 *     Copyright (C) 2021, Tokeny sàrl.
 *
 *     This program is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     This program is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU General Public License for more details.
 *
 *     You should have received a copy of the GNU General Public License
 *     along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity ^0.8.0;

import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';

import './Roles.sol';

contract AgentRoleUpgradeable is OwnableUpgradeable {
    using Roles for Roles.Role;

    event AgentAdded(address indexed _agent);
    event AgentRemoved(address indexed _agent);

    Roles.Role private _agents;

    modifier onlyAgent() {
        require(isAgent(msg.sender), 'AgentRole: caller does not have the Agent role');
        _;
    }

    function isAgent(address _agent) public view returns (bool) {
        return _agents.has(_agent);
    }

    function addAgent(address _agent) public onlyOwner {
        _agents.add(_agent);
        emit AgentAdded(_agent);
    }

    function removeAgent(address _agent) public onlyOwner {
        _agents.remove(_agent);
        emit AgentRemoved(_agent);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
}

// SPDX-License-Identifier: GPL-3.0
/**
 *     NOTICE
 *
 *     The T-REX software is licensed under a proprietary license or the GPL v.3.
 *     If you choose to receive it under the GPL v.3 license, the following applies:
 *     T-REX is a suite of smart contracts developed by Tokeny to manage and transfer financial assets on the ethereum blockchain
 *
 *     Copyright (C) 2021, Tokeny sàrl.
 *
 *     This program is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     This program is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU General Public License for more details.
 *
 *     You should have received a copy of the GNU General Public License
 *     along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity ^0.8.0;

import '@onchain-id/solidity/contracts/interface/IClaimIssuer.sol';

interface ITrustedIssuersRegistry {
    /**
     *  this event is emitted when a trusted issuer is added in the registry.
     *  the event is emitted by the addTrustedIssuer function
     *  `trustedIssuer` is the address of the trusted issuer's ClaimIssuer contract
     *  `claimTopics` is the set of claims that the trusted issuer is allowed to emit
     */
    event TrustedIssuerAdded(IClaimIssuer indexed trustedIssuer, uint256[] claimTopics);

    /**
     *  this event is emitted when a trusted issuer is removed from the registry.
     *  the event is emitted by the removeTrustedIssuer function
     *  `trustedIssuer` is the address of the trusted issuer's ClaimIssuer contract
     */
    event TrustedIssuerRemoved(IClaimIssuer indexed trustedIssuer);

    /**
     *  this event is emitted when the set of claim topics is changed for a given trusted issuer.
     *  the event is emitted by the updateIssuerClaimTopics function
     *  `trustedIssuer` is the address of the trusted issuer's ClaimIssuer contract
     *  `claimTopics` is the set of claims that the trusted issuer is allowed to emit
     */
    event ClaimTopicsUpdated(IClaimIssuer indexed trustedIssuer, uint256[] claimTopics);

    /**
     *  @dev registers a ClaimIssuer contract as trusted claim issuer.
     *  Requires that a ClaimIssuer contract doesn't already exist
     *  Requires that the claimTopics set is not empty
     *  @param _trustedIssuer The ClaimIssuer contract address of the trusted claim issuer.
     *  @param _claimTopics the set of claim topics that the trusted issuer is allowed to emit
     *  This function can only be called by the owner of the Trusted Issuers Registry contract
     *  emits a `TrustedIssuerAdded` event
     */
    function addTrustedIssuer(IClaimIssuer _trustedIssuer, uint256[] calldata _claimTopics) external;

    /**
     *  @dev Removes the ClaimIssuer contract of a trusted claim issuer.
     *  Requires that the claim issuer contract to be registered first
     *  @param _trustedIssuer the claim issuer to remove.
     *  This function can only be called by the owner of the Trusted Issuers Registry contract
     *  emits a `TrustedIssuerRemoved` event
     */
    function removeTrustedIssuer(IClaimIssuer _trustedIssuer) external;

    /**
     *  @dev Updates the set of claim topics that a trusted issuer is allowed to emit.
     *  Requires that this ClaimIssuer contract already exists in the registry
     *  Requires that the provided claimTopics set is not empty
     *  @param _trustedIssuer the claim issuer to update.
     *  @param _claimTopics the set of claim topics that the trusted issuer is allowed to emit
     *  This function can only be called by the owner of the Trusted Issuers Registry contract
     *  emits a `ClaimTopicsUpdated` event
     */
    function updateIssuerClaimTopics(IClaimIssuer _trustedIssuer, uint256[] calldata _claimTopics) external;

    /**
     *  @dev Function for getting all the trusted claim issuers stored.
     *  @return array of all claim issuers registered.
     */
    function getTrustedIssuers() external view returns (IClaimIssuer[] memory);

    /**
     *  @dev Checks if the ClaimIssuer contract is trusted
     *  @param _issuer the address of the ClaimIssuer contract
     *  @return true if the issuer is trusted, false otherwise.
     */
    function isTrustedIssuer(address _issuer) external view returns (bool);

    /**
     *  @dev Function for getting all the claim topic of trusted claim issuer
     *  Requires the provided ClaimIssuer contract to be registered in the trusted issuers registry.
     *  @param _trustedIssuer the trusted issuer concerned.
     *  @return The set of claim topics that the trusted issuer is allowed to emit
     */
    function getTrustedIssuerClaimTopics(IClaimIssuer _trustedIssuer) external view returns (uint256[] memory);

    /**
     *  @dev Function for checking if the trusted claim issuer is allowed
     *  to emit a certain claim topic
     *  @param _issuer the address of the trusted issuer's ClaimIssuer contract
     *  @param _claimTopic the Claim Topic that has to be checked to know if the `issuer` is allowed to emit it
     *  @return true if the issuer is trusted for this claim topic.
     */
    function hasClaimTopic(address _issuer, uint256 _claimTopic) external view returns (bool);

    /**
     *  @dev Transfers the Ownership of TrustedIssuersRegistry to a new Owner.
     *  @param _newOwner The new owner of this contract.
     *  This function can only be called by the owner of the Trusted Issuers Registry contract
     *  emits an `OwnershipTransferred` event
     */
    function transferOwnershipOnIssuersRegistryContract(address _newOwner) external;
}

// SPDX-License-Identifier: GPL-3.0
/**
 *     NOTICE
 *
 *     The T-REX software is licensed under a proprietary license or the GPL v.3.
 *     If you choose to receive it under the GPL v.3 license, the following applies:
 *     T-REX is a suite of smart contracts developed by Tokeny to manage and transfer financial assets on the ethereum blockchain
 *
 *     Copyright (C) 2021, Tokeny sàrl.
 *
 *     This program is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     This program is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU General Public License for more details.
 *
 *     You should have received a copy of the GNU General Public License
 *     along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity ^0.8.0;

import '@onchain-id/solidity/contracts/interface/IIdentity.sol';

interface IIdentityRegistryStorage {
    /**
     *  this event is emitted when an Identity is registered into the storage contract.
     *  the event is emitted by the 'registerIdentity' function
     *  `investorAddress` is the address of the investor's wallet
     *  `identity` is the address of the Identity smart contract (onchainID)
     */
    event IdentityStored(address indexed investorAddress, IIdentity indexed identity);

    /**
     *  this event is emitted when an Identity is removed from the storage contract.
     *  the event is emitted by the 'deleteIdentity' function
     *  `investorAddress` is the address of the investor's wallet
     *  `identity` is the address of the Identity smart contract (onchainID)
     */
    event IdentityUnstored(address indexed investorAddress, IIdentity indexed identity);

    /**
     *  this event is emitted when an Identity has been updated
     *  the event is emitted by the 'updateIdentity' function
     *  `oldIdentity` is the old Identity contract's address to update
     *  `newIdentity` is the new Identity contract's
     */
    event IdentityModified(IIdentity indexed oldIdentity, IIdentity indexed newIdentity);

    /**
     *  this event is emitted when an Identity's country has been updated
     *  the event is emitted by the 'updateCountry' function
     *  `investorAddress` is the address on which the country has been updated
     *  `country` is the numeric code (ISO 3166-1) of the new country
     */
    event CountryModified(address indexed investorAddress, uint16 indexed country);

    /**
     *  this event is emitted when an Identity Registry is bound to the storage contract
     *  the event is emitted by the 'addIdentityRegistry' function
     *  `identityRegistry` is the address of the identity registry added
     */
    event IdentityRegistryBound(address indexed identityRegistry);

    /**
     *  this event is emitted when an Identity Registry is unbound from the storage contract
     *  the event is emitted by the 'removeIdentityRegistry' function
     *  `identityRegistry` is the address of the identity registry removed
     */
    event IdentityRegistryUnbound(address indexed identityRegistry);

    /**
     *  @dev Returns the identity registries linked to the storage contract
     */
    function linkedIdentityRegistries() external view returns (address[] memory);

    /**
     *  @dev Returns the onchainID of an investor.
     *  @param _userAddress The wallet of the investor
     */
    function storedIdentity(address _userAddress) external view returns (IIdentity);

    /**
     *  @dev Returns the country code of an investor.
     *  @param _userAddress The wallet of the investor
     */
    function storedInvestorCountry(address _userAddress) external view returns (uint16);

    /**
     *  @dev adds an identity contract corresponding to a user address in the storage.
     *  Requires that the user doesn't have an identity contract already registered.
     *  This function can only be called by an address set as agent of the smart contract
     *  @param _userAddress The address of the user
     *  @param _identity The address of the user's identity contract
     *  @param _country The country of the investor
     *  emits `IdentityStored` event
     */
    function addIdentityToStorage(
        address _userAddress,
        IIdentity _identity,
        uint16 _country
    ) external;

    /**
     *  @dev Removes an user from the storage.
     *  Requires that the user have an identity contract already deployed that will be deleted.
     *  This function can only be called by an address set as agent of the smart contract
     *  @param _userAddress The address of the user to be removed
     *  emits `IdentityUnstored` event
     */
    function removeIdentityFromStorage(address _userAddress) external;

    /**
     *  @dev Updates the country corresponding to a user address.
     *  Requires that the user should have an identity contract already deployed that will be replaced.
     *  This function can only be called by an address set as agent of the smart contract
     *  @param _userAddress The address of the user
     *  @param _country The new country of the user
     *  emits `CountryModified` event
     */
    function modifyStoredInvestorCountry(address _userAddress, uint16 _country) external;

    /**
     *  @dev Updates an identity contract corresponding to a user address.
     *  Requires that the user address should be the owner of the identity contract.
     *  Requires that the user should have an identity contract already deployed that will be replaced.
     *  This function can only be called by an address set as agent of the smart contract
     *  @param _userAddress The address of the user
     *  @param _identity The address of the user's new identity contract
     *  emits `IdentityModified` event
     */
    function modifyStoredIdentity(address _userAddress, IIdentity _identity) external;

    /**
     *  @notice Transfers the Ownership of the Identity Registry Storage to a new Owner.
     *  This function can only be called by the wallet set as owner of the smart contract
     *  @param _newOwner The new owner of this contract.
     */
    function transferOwnershipOnIdentityRegistryStorage(address _newOwner) external;

    /**
     *  @notice Adds an identity registry as agent of the Identity Registry Storage Contract.
     *  This function can only be called by the wallet set as owner of the smart contract
     *  This function adds the identity registry to the list of identityRegistries linked to the storage contract
     *  @param _identityRegistry The identity registry address to add.
     */
    function bindIdentityRegistry(address _identityRegistry) external;

    /**
     *  @notice Removes an identity registry from being agent of the Identity Registry Storage Contract.
     *  This function can only be called by the wallet set as owner of the smart contract
     *  This function removes the identity registry from the list of identityRegistries linked to the storage contract
     *  @param _identityRegistry The identity registry address to remove.
     */
    function unbindIdentityRegistry(address _identityRegistry) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./IIdentity.sol";

interface IClaimIssuer is IIdentity {
    function revokeClaim(bytes32 _claimId, address _identity) external returns(bool);
    function getRecoveredAddress(bytes calldata sig, bytes32 dataHash) external pure returns (address);
    function isClaimRevoked(bytes calldata _sig) external view returns (bool);
    function isClaimValid(IIdentity _identity, uint256 claimTopic, bytes calldata sig, bytes calldata data) external view returns (bool);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping(address => bool) bearer;
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        require(!has(role, account), 'Roles: account already has role');
        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), 'Roles: account does not have role');
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), 'Roles: account is the zero address');
        return role.bearer[account];
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = _setInitializedVersion(1);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !AddressUpgradeable.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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