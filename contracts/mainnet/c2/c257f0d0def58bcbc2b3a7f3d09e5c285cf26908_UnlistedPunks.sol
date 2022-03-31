// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

// imports

import "./IERC165.sol";
import "./IERC721.sol";
import "./IERC721Metadata.sol";
import "./IERC721Enumerable.sol";
import "./IERC721TokenReceiver.sol";

// contract

contract UnlistedPunks is ERC165, ERC721, ERC721Enumerable, ERC721Metadata {

    /**
     * @dev Types
     */

    struct MintRequest { uint256 id; bytes32 cid; uint256 price; uint8 v; bytes32 r; bytes32 s; }

    /**
     * @dev Constants
     */

    // base58 alphabet
    bytes constant private ALPHABET = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz";

    // owner address
    address constant private _owner = 0x52678E3BfCC41833F3D8629DBa43814A716B2eDC;

    // token name
    string constant private _name = "UnlistedPunks";

    // token symbol
    string constant private _symbol = "UP";

    // contract metadata
    string constant private _metadata = "https://unlistedpunks.com/metadata.json";

    // address who signs mint requests
    address constant private SIGNER_PUBLIC_ADDRESS = 0xDFC007450C78c510e597b7281938A9595E988AA4;

    // base URI
    string constant private BASE_URI = "ipfs://";

    /**
     * @dev State
     */

    // mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // mapping owner address to token count
    mapping(address => uint256) private _balances;

    // mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // mapping from tokenId to its partial CID
    mapping(uint256 => bytes32) private _cids;

    // mapping from index to tokenId
    mapping(uint256 => uint256) private _tokens;

    // total supply counter
    uint256 private _totalSupply = 0;

    /**
     * @dev UnlistedPunks (Private)
     */

    function _toBase58(bytes memory source) private pure returns (bytes memory) {
        if (source.length == 0) return new bytes(0);
        uint8[] memory digits = new uint8[](64);
        uint8 digitlength = 1;
        digits[0] = 0;
        for (uint256 i = 0; i<source.length; ++i) {
            uint carry = uint8(source[i]);
            for (uint256 j = 0; j<digitlength; ++j) { carry += uint(digits[j]) * 256; digits[j] = uint8(carry % 58); carry = carry / 58; }
            while (carry > 0) { digits[digitlength] = uint8(carry % 58); digitlength++; carry = carry / 58; }
        }
        // truncate
        uint8[] memory outputTruncate = new uint8[](digitlength);
        for (uint256 i = 0; i<digitlength; i++) { outputTruncate[i] = digits[i]; }
        // reverse
        uint8[] memory outputReverse = new uint8[](outputTruncate.length);
        for (uint256 i = 0; i<outputTruncate.length; i++) { outputReverse[i] = outputTruncate[outputTruncate.length-1-i]; }
        // to Alphabet
        bytes memory outputAlphabet = new bytes(outputReverse.length);
        for (uint256 i = 0; i<outputReverse.length; i++) { outputAlphabet[i] = ALPHABET[outputReverse[i]]; }
        // return
        return outputAlphabet;
    }

    /**
     * @dev Private function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     */

    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data) private returns (bool) {
        if(to.code.length > 0){
            // to is contract
            bytes4 retval = ERC721TokenReceiver(to).onERC721Received(msg.sender, from, tokenId, _data);
            return retval == ERC721TokenReceiver.onERC721Received.selector;
        } else {
            return true;
        }
    }

    /**
     * @dev UnlistedPunks (Public)
     */

    function isMintable(uint256 tokenId) public view returns(bool){
        return _owners[tokenId] == address(0);
    }

    function mint(MintRequest[] calldata request) public payable returns (uint256){
        uint arrayLength = request.length;
        for (uint i = 0; i < arrayLength; i++) {
            require(_owners[request[i].id] == address(0), "already minted tokenId");
            bytes32 documentHash = keccak256(abi.encode(request[i].id, request[i].cid, request[i].price));
            bytes32 prefixedProof = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", documentHash));
            address recovered = ecrecover(prefixedProof, request[i].v, request[i].r, request[i].s);
            require(recovered == SIGNER_PUBLIC_ADDRESS, "invalid signature on mint request");
            _cids[request[i].id] = request[i].cid;
            _owners[request[i].id] = msg.sender;
            _tokens[_totalSupply + i] = request[i].id;
            emit Transfer(address(0), msg.sender, request[i].id);
        }
        _balances[msg.sender] += arrayLength;
        _totalSupply += arrayLength;
        return _totalSupply;
    }

    function withdraw() public {
        require(msg.sender == _owner, "only owner allowed");
        payable(address(_owner)).transfer(address(this).balance);
    }

    function close() public {
        require(msg.sender == _owner, "only owner allowed");
        selfdestruct(payable(_owner)); 
    }

    /**
     * @dev Open Sea
     * https://docs.opensea.io/docs/contract-level-metadata
     */

    function contractURI() public pure returns (string memory) {
        return "https://unlistedpunks.com/metadata.json";
    }

    function owner() public pure returns (address) {
        return _owner;
    }

    /**
     * @dev IERC165
     * https://github.com/ethereum/EIPs/blob/master/EIPS/eip-165.md
     */

    /**
     * @dev See {IERC165-supportsInterface}.
     */

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165) returns (bool) {
        return
            interfaceId == type(ERC165).interfaceId ||
            interfaceId == type(ERC721).interfaceId ||
            interfaceId == type(ERC721Metadata).interfaceId ||
            interfaceId == type(ERC721Enumerable).interfaceId;
    }

    /**
     * @dev IERC721
     * https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
     */

    /**
     * @dev See {IERC721-balanceOf}.
     */

    function balanceOf(address tokenOwner) public view virtual override returns (uint256) {
        require(tokenOwner != address(0), "ERC721: balance query for the zero address");
        return _balances[tokenOwner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */

    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address tokenOwner = _owners[tokenId];
        require(tokenOwner != address(0), "ERC721: owner query for nonexistent token");
        return tokenOwner;
    }

    /**
     * @dev See {IERC721-approve}.
     */

    function approve(address to, uint256 tokenId) public virtual payable override {
        address tokenOwner = _owners[tokenId];
        require(to != tokenOwner, "ERC721: approval to current owner");
        require(msg.sender == tokenOwner || isApprovedForAll(tokenOwner, msg.sender), "ERC721: approve caller is not owner nor approved for all");
        _tokenApprovals[tokenId] = to;
        emit Approval(tokenOwner, to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */

    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_owners[tokenId] != address(0), "ERC721: approved query for nonexistent token");
        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */

    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(msg.sender != operator, "ERC721: approve to caller");
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */

    function isApprovedForAll(address tokenOwner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[tokenOwner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */

    function transferFrom(address from, address to, uint256 tokenId) public virtual payable override {
        address tokenOwner = _owners[tokenId];
        require(tokenOwner != address(0), "ERC721: operator query for nonexistent token");
        require(msg.sender == tokenOwner || getApproved(tokenId) == msg.sender || isApprovedForAll(tokenOwner, msg.sender), "ERC721: transfer caller is not owner nor approved");
        require(tokenOwner == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");
        _tokenApprovals[tokenId] = address(0);
        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;
        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public virtual payable override {
        transferFrom(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */

    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual payable override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev IERC721Metadata
     * https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
     */


    /**
     * @dev See {IERC721Metadata-name}.
     */

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_owners[tokenId] != address(0), "ERC721Metadata: URI query for nonexistent token");
        bytes memory cid = abi.encodePacked(bytes2(0x1220),_cids[tokenId]);
        return string(abi.encodePacked(BASE_URI, _toBase58(cid)));
    }

    /**
     * @dev IERC721Enumerable
     * https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
     */

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */

    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < _totalSupply, "ERC721Enumerable: global index out of bounds");
        return _tokens[index];
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */

    function tokenOfOwnerByIndex(address tokenOwner, uint256 index) public view virtual override returns (uint256) {
        uint256 currentIndex = 0;
        for(uint i=0; i<_totalSupply; i++){
            if(_owners[_tokens[i]] == tokenOwner){
                if(currentIndex == index){
                    return _tokens[i];
                } else {
                    currentIndex = currentIndex + 1;
                }
            }
        }
        revert("ERC721Enumerable: owner index out of bounds");
    }

}