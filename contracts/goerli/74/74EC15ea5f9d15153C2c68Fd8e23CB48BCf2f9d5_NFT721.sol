// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract NFT721 {
    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Mapping from token ID to tokenURl
    mapping(uint256 => string) private _tokenURIs;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /// @notice Count all NFTs assigned to an owner
    /// @dev NFTs assigned to the zero address are considered invalid, and this
    ///  function throws for queries about the zero address.
    /// @param _owner An address for whom to query the balance
    /// @return The number of NFTs owned by `_owner`, possibly zero
    function balanceOf(address _owner) external view returns (uint256){
        require(_owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[_owner];
    }

    /// @notice Find the owner of an NFT
    /// @dev NFTs assigned to zero address are considered invalid, and queries eabout them do throw.
    /// @param _tokenId The identifier for an NFT
    /// @return The address of the owner of the NFT
    function ownerOf(uint256 _tokenId) external view returns (address) {
        address owner = _owners[_tokenId];
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /// @notice A distinct Uniform Resource Identifier (URI) for a given asset.
    /// @dev Throws if `_tokenId` is not a valid NFT. URIs are defined in RFC
    ///  3986. The URI may point to a JSON file that conforms to the "ERC721
    ///  Metadata JSON Schema".
    function getTokenURI(uint256 _tokenId) public view returns (string memory) {
        require(_exists(_tokenId), "ERC721: invalid token ID");
        return (_tokenURIs[_tokenId]);
    }

    function mint(address _to, uint256 _tokenId, string memory _tokenURI) internal virtual {
        require(_to != address(0), "ERC721: mint to the zero address");
        require(!_exists(_tokenId), "ERC721: token already minted");

        _balances[_to] += 1;
        _owners[_tokenId] = _to;
        _tokenURIs[_tokenId] = _tokenURI;
        emit Transfer(address(0), _to, _tokenId);
    }

    // /**
    //  * @dev Destroys `tokenId`.
    //  * The approval is cleared when the token is burned.
    //  * Requirements:
    //  * - `tokenId` must exist.
    //  * Emits a {Transfer} event.
    //  */
    // function burn(uint256 _tokenId) internal virtual {
    //     address owner = this.ownerOf(_tokenId);

    //     // Clear approvals
    //     _approve(address(0), _tokenId);
    //     _balances[owner] -= 1;

    //     delete _owners[_tokenId];
    //     delete _tokenURIs[_tokenId];
    //     emit Transfer(owner, address(0), _tokenId);
    // }


    // /// @notice Change or reaffirm the approved address for an NFT
    // /// @dev The zero address indicates there is no approved address.
    // ///  Throws unless `msg.sender` is the current NFT owner, or an authorized
    // ///  operator of the current owner.
    // /// @param _approved The new approved NFT controller
    // /// @param _tokenId The NFT to approve
    // function approve(address _approved, uint256 _tokenId) external payable {
    //     address owner = this.ownerOf(_tokenId);
    //     require(_approved != owner, "ERC721: approval to current owner");

    //     require(
    //         msg.sender == owner || isApprovedForAll(owner, msg.sender),
    //         "ERC721: approve caller is not token owner nor approved for all"
    //     );
    //    _approve(_approved, _tokenId);
    // }

    // /// @notice Enable or disable approval for a third party ("operator") to manage
    // /// all of `msg.sender`'s assets
    // /// @dev Emits the ApprovalForAll event. The contract MUST allow
    // ///  multiple operators per owner.
    // /// @param _operator Address to add to the set of authorized operators
    // /// @param _approved True if the operator is approved, false to revoke approval
    // function setApprovalForAll(address _operator, bool _approved) external {
    //     require(msg.sender != _operator, "ERC721: approve to caller");
    //     _operatorApprovals[msg.sender][_operator] = _approved;
    //     emit ApprovalForAll(msg.sender, _operator, _approved);
    // }

    // /// @notice Transfer ownership of an NFT -- THE CALLER IS RESPONSIBLE
    // ///  TO CONFIRM THAT `_to` IS CAPABLE OF RECEIVING NFTS OR ELSE
    // ///  THEY MAY BE PERMANENTLY LOST
    // /// @dev Throws unless `msg.sender` is the current owner, an authorized
    // ///  operator, or the approved address for this NFT. Throws if `_from` is
    // ///  not the current owner. Throws if `_to` is the zero address. Throws if
    // ///  `_tokenId` is not a valid NFT.
    // /// @param _from The current owner of the NFT
    // /// @param _to The new owner
    // /// @param _tokenId The NFT to transfer
    // function transferFrom(address _from, address _to, uint256 _tokenId) external payable {
    //     require(_isApprovedOrOwner(msg.sender, _tokenId), "ERC721: caller is not token owner nor approved");
    //     _transfer(_from, _to, _tokenId);
    // }

    // /// @notice Transfers the ownership of an NFT from one address to another address
    // /// @dev Throws unless `msg.sender` is the current owner, an authorized
    // ///  operator, or the approved address for this NFT. Throws if `_from` is
    // ///  not the current owner. Throws if `_to` is the zero address. Throws if
    // ///  `_tokenId` is not a valid NFT. When transfer is complete, this function
    // ///  checks if `_to` is a smart contract (code size > 0). If so, it calls
    // ///  `onERC721Received` on `_to` and throws if the return value is not
    // ///  `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
    // /// @param _from The current owner of the NFT
    // /// @param _to The new owner
    // /// @param _tokenId The NFT to transfer
    // function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable {
    //      require(_isApprovedOrOwner(msg.sender, _tokenId), "ERC721: caller is not token owner nor approved");
    //     _transfer(_from, _to, _tokenId);
    // }

    /// @notice Get the approved address for a single NFT
    /// @dev Throws if `_tokenId` is not a valid NFT.
    /// @param _tokenId The NFT to find the approved address for
    /// @return The approved address for this NFT, or the zero address if there is none
    function getApproved(uint256 _tokenId) external view returns (address) {
        require(_exists(_tokenId), "ERC721: invalid token ID");
        return _tokenApprovals[_tokenId];
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev Returns whether `tokenId` exists.
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        return _owners[tokenId] != address(0);
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
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     * Requirements:
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        address owner = this.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || this.getApproved(tokenId) == spender);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(this.ownerOf(tokenId), to, tokenId);
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
        require(this.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * ***** EVENTS *****
     */

    /// @dev This emits when ownership of any NFT changes by any mechanism.
    ///  This event emits when NFTs are created (`from` == 0) and destroyed
    ///  (`to` == 0). Exception: during contract creation, any number of NFTs
    ///  may be created and assigned without emitting Transfer. At the time of
    ///  any transfer, the approved address for that NFT (if any) is reset to none.
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

    /// @dev This emits when the approved address for an NFT is changed or
    ///  reaffirmed. The zero address indicates there is no approved address.
    ///  When a Transfer event emits, this also indicates that the approved
    ///  address for that NFT (if any) is reset to none.
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);

    /// @dev This emits when an operator is enabled or disabled for an owner.
    ///  The operator can manage all NFTs of the owner.
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
}