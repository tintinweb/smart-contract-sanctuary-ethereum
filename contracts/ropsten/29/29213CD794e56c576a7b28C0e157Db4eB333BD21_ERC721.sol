/**
 *Submitted for verification at Etherscan.io on 2022-06-08
*/

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/08d109d87725e36dce92db28c7a74bb49bde38ae/contracts/utils/Strings.sol


// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)
// SPDX-License-Identifier: MIT
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

// File: ERC721.sol


pragma solidity ^0.8.7;


interface IERC165{
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC721{
    event Transfer(address _from, address _to, uint _tokenId);

    event Approval(address _owner, address _approved, uint _tokenId);

    event ApprovalForAll(address _owner, address _operator, bool _approved);

    function balanceOf(address owner) external view returns (uint balance);

    function ownerOf(uint tokenId) external view returns (address owner);

    function safeTransferFrom(
        address from,
        address to,
        uint tokenId,
        bytes calldata data
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint tokenId
    ) external;

    function transferFrom(
        address from,
        address to,
        uint tokenId
    ) external;

    function approve(address to, uint tokenId) external;

    function setApprovalForAll(address operator, bool _approved) external;

    function getApproved(uint tokenId) external view returns (address operator);

    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

interface IERC721Receiver{
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

contract ERC165 is IERC165{
    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor(){
        _registerInterface(bytes4(keccak256('supportsInterface(bytes4)')));
    }

    function _registerInterface(bytes4 interfaceId) internal{
        require(interfaceId != 0xffffffff, "Invalid Interface Id");
        _supportedInterfaces[interfaceId]= true;
    }

    function supportsInterface(bytes4 interfaceId) external override view returns (bool){
        return _supportedInterfaces[interfaceId];
    }
}

contract ERC721 is IERC721, ERC165{
    using Strings for uint;

    string private _name;
    string private _symbol;

    // Mapping from tokenId to owner address
    mapping (uint => address) private _tokenOwner;
    // Mapping from owner to count of owned tokens
    mapping (address => uint) private _OwnedTokensCount;
    // Mapping from token id to approved address
    mapping (uint => address) private _tokenApprovals;
    // Mapping from owner to operator approvals
    mapping (address => mapping(address => bool)) private _operatorApprovals;
 
    constructor(string memory name_, string memory symbol_){
        _name= name_;
        _symbol= symbol_;
    }

    function isContract(address account) private view returns (bool){
        return account.code.length > 0;
    }

    function _mint(address to, uint tokenId) public {
        require(to != address(0), "Mint to Zero address");
        require(!_exists(tokenId), "TOken already minted");
        _OwnedTokensCount[to] += 1;
        _tokenOwner[tokenId] = to;
        emit Transfer(address(0), to, tokenId);
    }

    function _safeMint(address to, uint tokenId, bytes memory data) internal{
        _mint(to, tokenId);
        require(_checkOnERC721Received(address(0), to, tokenId, data), "Transfer to non ERC721 receiver implementer");
    }

    function _safeMint(address to, uint tokenId) internal{
        _safeMint(to, tokenId, "");
    }

    function _burn(uint tokenId) public{
        address owner= ownerOf(tokenId);

        approve(address(0), tokenId);
        _OwnedTokensCount[owner] -= 1;
        delete _tokenOwner[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    function _exists(uint tokenId) internal view returns(bool){
        return _tokenOwner[tokenId] != address(0);
    }

    // 1. tokenId exists
    // 2. spender is the owner or is approved.
    function _isApprovedOrOwner(address spender, uint tokenId) internal view returns(bool){
        require(_exists(tokenId), "Token does not exists");
        address owner= this.ownerOf(tokenId);
        return(spender == owner || this.isApprovedForAll(owner, spender) ||
                this.getApproved(tokenId) == spender);
    }

    function _transfer(address from, address to, uint tokenId) internal{
        require(this.ownerOf(tokenId) == from, "Transfer from incorrect owner");
        require(to != address(0), "Transfer to zero address");
        
        // Clear approvals from previous owner
        _tokenApprovals[tokenId]= address(0);
        emit Approval(this.ownerOf(tokenId), address(0), tokenId);

        _OwnedTokensCount[from] -= 1;
        _OwnedTokensCount[to] += 1;
        _tokenOwner[tokenId]= to;
        emit Transfer(from, to, tokenId);
    }

    function _safeTransfer(address from, address to, uint tokenId, bytes memory data) internal{
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "Transfer to non ERC721 receiver implementer");
    }

    function _checkOnERC721Received(address from, address to, uint tokenId, bytes memory data) private returns(bool){
        if(isContract(to)){
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, data) returns(bytes4 retval){
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch(bytes memory reason){
                if(reason.length == 0){
                    revert("ERC721: transfer to non ERC721Receiver Implementer");
                } else{
                    assembly{
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else{
            return true;
        }
    }

    function _baseURI() internal pure returns(string memory){
        return "https://exampleNFT.com/";
    }

    function name() public view returns(string memory){
        return _name;
    }

    function symbol() public view returns(string memory){
        return _symbol;
    }

    function tokenURI(uint tokenId) public view returns(string memory){
        require(_exists(tokenId), "Token does not exists");
        string memory baseURI= _baseURI();
        return bytes(baseURI).length > 0 ? 
                string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    function balanceOf(address _owner) public override view returns (uint){
        require(_owner != address(0), "Address 0 is not a valid owner.");
        return _OwnedTokensCount[_owner];
    }

    function ownerOf(uint _tokenId) public override view returns (address){
        address owner= _tokenOwner[_tokenId];
        require(owner != address(0), "Token does not exists.");
        return owner;
    }

    // 1. The caller must own the token or be an approved operator
    // 2. tokenId must exists
    function approve(address _to, uint _tokenId) public override{
        address owner= this.ownerOf(_tokenId);
        require(_to != owner, "Approval to current owner");
        require(msg.sender == owner || this.isApprovedForAll(owner, msg.sender),
                "Caller is neither an owner nor approved for all");
        _tokenApprovals[_tokenId]= _to;
        emit Approval(owner, _to, _tokenId);
    }

    function getApproved(uint _tokenId) public override view returns (address){
        require(_exists(_tokenId), "Token does not exists");
        return _tokenApprovals[_tokenId];
    }

    // Approve or remove 'operator' as an operator for the caller 
    function setApprovalForAll(address operator, bool _approved) public override{
        // The operator cannot be the caller.
        require(msg.sender != operator, "The operator cannot be the caller");
        _operatorApprovals[msg.sender][operator]= _approved;
        emit ApprovalForAll(msg.sender, operator, _approved);
    }

    function isApprovedForAll(address owner, address operator) public override view returns (bool){
        return _operatorApprovals[owner][operator];
    }

    // 1. tokenId must be owned by 'from'.
    // 2. If the caller is not 'from', it must be approved.
    function transferFrom(address from, address to, uint256 tokenId) public override{
        require(_isApprovedOrOwner(msg.sender, tokenId), "Caller is neither owner nor approved");
        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint tokenId,
        bytes memory data
    ) public override{
        require(_isApprovedOrOwner(msg.sender, tokenId), "Caller is neither owner nor approved");
        _safeTransfer(from, to, tokenId, data);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint tokenId
    ) public override{
        safeTransferFrom(from, to, tokenId, "");
    }

}