// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./Ownable.sol";
import "./ERC1155.sol";
import "./ERC1155Burnable.sol";

import "./Address.sol";
import "./Base64.sol";


contract NewFormatTickets is ERC1155, ERC1155Burnable, Ownable {
    using Address for address;
    using Base64 for bytes;

    mapping(uint256 => mapping(address => bool)) private _white_list;
    mapping(uint256 => address) private _creators;
    mapping(uint256 => string) private _uris;
    uint256 public last_reserved;
    string public name;
    
    constructor() ERC1155("ipfs://") {
        name = "New Format Tickets";
    }

    function mintTickets(
        uint256 amount,  
        address[] memory white_list, 
        bytes memory data
    ) external {
        last_reserved += 1;
        _mint(_msgSender(), last_reserved, amount, data);
        _creators[last_reserved] = _msgSender();

        for (uint i = 0; i < white_list.length; ++i) {
            _white_list[last_reserved][white_list[i]] = true;
        }
    }

    function buyTicket(uint256 id, bytes memory data) external {
        require(id <= last_reserved, "NFT: this ticket is not minted");
        require(balanceOf(_msgSender(), id) == 0, "NFT: this ticket is already buyed");
        if (_white_list[id][_msgSender()]) _safeTransferFrom(_creators[id], _msgSender(), id, 1, data);
    }

    function verifyTicket(address account, uint256 id) external view returns (bool) 
    {   
        require(id <= last_reserved, "NFT: this ticket is not minted");
        return balanceOf(account, id) > 0;
    }

    function mint(address account, uint256 id, uint256 amount, bytes memory data) external {
        require(id == last_reserved + 1, "NFT: this token is already minted");
        _mint(account, id, amount, data);
    }

    function mintBatch(
        address to, 
        uint256[] memory ids, 
        uint256[] memory amounts, 
        bytes memory data 
    ) external onlyOwner {
        _mintBatch(to, ids, amounts, data);
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
    function uri(uint256 id) public view override returns (string memory) {
        return string.concat(_getBaseUri(), _uris[id]);
    }

    /**
     * @dev changing token uri
     */
    function setURI(uint256 id, string memory uri_) external onlyOwner { // onlyApproval(_msgSender()) {
        _uris[id] = uri_;
    }

    function setURIBatch(uint256[] memory ids, string[] memory uris_) external { // onlyApproval(_msgSender()) {
        for (uint i = 0; i < ids.length; ++i) {
            _uris[ids[i]] = uris_[i];
        }
    }
}