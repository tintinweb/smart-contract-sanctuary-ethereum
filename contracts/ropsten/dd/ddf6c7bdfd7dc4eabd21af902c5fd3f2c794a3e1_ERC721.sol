/**
 *Submitted for verification at Etherscan.io on 2022-06-13
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

/**
 * @dev Implementation of the QRC721 tier 1 Non-Fungible Token Standard
 */
contract ERC721 {

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Token supply
    uint256 private _supply;

    // Base Token Uri
    string private _baseTokenURI;

    //the address that can mint new tokens
    address private _owner;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    /**
     * @dev Emitted when `tokenId` token is transferred from `senderAccountId` to `receiverAccountId`.
     */
    event Transfer(address indexed senderAccountId, address indexed receiverAccountId, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `spender` to manage the `tokenId` token.
     */
    event Approval(address indexed ownerAccountId, address indexed collectorAccountId, uint256 indexed tokenId);

    /**
     * @dev Emitted when the authorised owner is changed
     */
    event OwnerChanged(address indexed oldContractOwner, address indexed NewContractOwner);

    /**
     * @dev Emitted when tokens are minted or burned.
     */
    event MetaData(string indexed functionName, bytes data);

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection as well as an optional baseTokenURI. 
     * Additionally the contract's authorised token owner address is set. 
     */
    constructor(string memory name_, string memory symbol_, string memory baseTokenURI_, address owner_) {
        _name = name_;
        _symbol = symbol_;
        _baseTokenURI = baseTokenURI_;
        _owner = owner_;
    }

    /**
     * @dev Functions using this modifier restrict the caller to only be the owner address
     */
   modifier onlyOwner {
       require(msg.sender == owner(), "Sender must be the owner");
      _;
   }

    /**
     * @dev Gives permission to `collectorAccountId` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - cannot approve the owner account.
     * - The caller must own the token.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address collectorAccountId, uint256 tokenId) external {
        address thisOwner = ownerOf(tokenId);
        
        require(collectorAccountId != thisOwner, "Same address used");
        require(msg.sender == thisOwner, "Caller is not owner");

        _approve(collectorAccountId, tokenId);

    }

    /**
     * @dev Transfers `tokenId` token from `senderAccountId` to `receiverAccountId`.
     *
     * Requirements:
     *
     * - `senderAccountId` cannot be the zero address.
     * - `receiverAccountId` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `senderAccountId`.
     * - If the caller is not `senderAccountId`, the caller must be have been allowed to move this token by {approve}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address senderAccountId, address receiverAccountId, uint256 tokenId) external {

        require(_exists(tokenId), "Token does not exist");
        address thisOwner = ERC721.ownerOf(tokenId);
        require((msg.sender == thisOwner || getApproved(tokenId) == msg.sender), "Caller is not owner or approved");
        _transfer(senderAccountId, receiverAccountId, tokenId);

    }

    /**
     * @dev Mints `tokenId` and transfers it to `beneficiaryAccountId`. This minting is associated with an optional `data` parameter.
     *
     * Requirements:
     *
     * - caller must be the contract's assigned owner.
     * - `tokenId` must not exist.
     *
     * Emits a {Transfer} event.
     */
    function mint(address beneficiaryAccountId, uint256 tokenId, bytes calldata data) external onlyOwner() {
        
        require(beneficiaryAccountId != address(0), "Zero address used");
        require(!_exists(tokenId), "Token already minted");

        _balances[beneficiaryAccountId] += 1;
        _owners[tokenId] = beneficiaryAccountId;
        _supply += 1;

        emit Transfer(address(0), beneficiaryAccountId, tokenId);
        emit MetaData("mint", data);

    }

    /**
     * @dev Destroys `tokenId`. This token burn is associated with an optional `data` parameter.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     * - the caller must own the token being burned.
     *
     * Emits a {Transfer} event.
     */
    function burn(uint256 tokenId, bytes calldata data) external {

        address thisOwner = ERC721.ownerOf(tokenId);
        require(_exists(tokenId), "Token does not exist");
        require(msg.sender == thisOwner, "Unauthorised to burn token");

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[thisOwner] -= 1;
        delete _owners[tokenId];
        _supply -= 1;

        emit Transfer(thisOwner, address(0), tokenId);
        emit MetaData("burn", data);

    }

    /**
     * @dev Changes the address that can mint tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Requirements:
     *
     * - `msg.sender` must have the owner role.
     */
    function changeOwner(address newContractOwnerId) external onlyOwner() returns (bool) {
        require(newContractOwnerId != address(0x0), "Zero address used");
        address oldOwner = _owner;
        _owner = newContractOwnerId;
        emit OwnerChanged(oldOwner, newContractOwnerId);
        return true;
    }



    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`.
     */
    function _baseURI() internal view returns (string memory) {
        return _baseTokenURI;
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(address from, address to, uint256 tokenId) internal {
        require(ERC721.ownerOf(tokenId) == from, "Transfer from incorrect owner");
        require(to != address(0), "Zero address used");

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`.
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal {
       
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);

    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of tokens currently in this NFT collection.
     */
    function totalSupply() public view returns (uint256) {
        return _supply;
    }

    /**
     * @dev Returns the address with the owner role of this token contract, 
     * i.e. what address can mint new tokens.
     * if a multi-sig operator is required, this address should 
     * point to a smart contract implementing this multi-sig.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Returns the number of tokens in ``accountId``'s account.
     */
    function balanceOf(address accountId) public view returns (uint256) {
        require(accountId != address(0), "Zero address used");
        return _balances[accountId];
    }

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) public view returns (address) {
        address thisOwner = _owners[tokenId];
        require(thisOwner != address(0), "Token does not exist");
        return thisOwner;
    }

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) public view returns (address) {

        require(_exists(tokenId), "Token does not exist");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) public view returns (string memory) {
        require(_exists(tokenId), "Token does not exist");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, toString(tokenId))) : "";
    }

    /**
     * @dev Converts a uint256 to a string.
     */
    function toString(uint256 value) internal pure returns (string memory) {

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

}