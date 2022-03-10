/**
 *Submitted for verification at Etherscan.io on 2022-03-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

//            _____            _____                     _____          
//           /\    \          /\    \                   /\    \         
//          /::\____\        /::\    \                 /::\    \        
//         /:::/    /       /::::\    \               /::::\    \       
//        /:::/    /       /::::::\    \             /::::::\    \      
//       /:::/    /       /:::/\:::\    \           /:::/\:::\    \     
//      /:::/    /       /:::/__\:::\    \         /:::/  \:::\    \    
//     /:::/    /       /::::\   \:::\    \       /:::/    \:::\    \   
//    /:::/    /       /::::::\   \:::\    \     /:::/    / \:::\    \  
//   /:::/    /       /:::/\:::\   \:::\    \   /:::/    /   \:::\ ___\ 
//  /:::/____/       /:::/  \:::\   \:::\____\ /:::/____/  ___\:::|    |
//  \:::\    \       \::/    \:::\  /:::/    / \:::\    \ /\  /:::|____|
//   \:::\    \       \/____/ \:::\/:::/    /   \:::\    /::\ \::/    / 
//    \:::\    \               \::::::/    /     \:::\   \:::\ \/____/  
//     \:::\    \               \::::/    /       \:::\   \:::\____\    
//      \:::\    \              /:::/    /         \:::\  /:::/    /    
//       \:::\    \            /:::/    /           \:::\/:::/    /     
//        \:::\    \          /:::/    /             \::::::/    /      
//         \:::\____\        /:::/    /               \::::/    /       
//          \::/    /        \::/    /                 \::/    /        
//           \/____/          \/____/                   \/____/



interface IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns(bytes4);
}

// Implementation of a custom tokenURI
interface ITokenURICustom {
    function constructTokenURI(uint256 tokenId) external view returns (string memory);
}

// Ownable From OpenZeppelin Contracts v4.4.1 (Ownable.sol)

abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(msg.sender);
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// ERC721 Contract with customisable URI

contract ERC721 is Ownable {

    // Events ERC721
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    // NFT contract metadata
    string public name;

    string public symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    // Extra token metadata links for redundancy 
    mapping(uint256 => string[]) private _metadataLinks;

    // Mapping from token ID to URIs custom contract
    mapping(uint256 => address) public customURI;

    // Mapping from token ID to token URIs locked
    mapping(uint256 => bool) public lockedURI;

    uint256 _tokenCounter = 0;
    

    // ERC-2981: NFT Royalty Standard
    address payable private _royaltyRecipient;
    uint256 private _royaltyBps;

    // Mapping from token ID to non-default royaltyBps
    mapping(uint256 => uint256) private _royaltyBpsTokenId;


    // CONSTRUCTOR
    constructor(string memory name_, string memory symbol_) {
        name = name_;
        symbol = symbol_;

        _royaltyRecipient = payable(msg.sender);
        _royaltyBps = 1000;

    }

    // ERC165

    function supportsInterface(bytes4 interfaceId) public pure returns (bool) {
        return 
            interfaceId == 0x01ffc9a7 || // ERC165 = 0x01ffc9a7
            interfaceId == 0x80ac58cd || // ERC721 = 0x80ac58cd
            interfaceId == 0x5b5e139f || // ERC721 Metadata = 0x5b5e139f
            interfaceId == 0x2a55205a;  // ERC2981 = 0x2a55205a;

        // ERC721 = 0x80ac58cd
        // ERC721 Metadata = 0x5b5e139f
        // ERC721 Enumerable = 0x780e9d63
        // ERC721 Receiver = 0x150b7a02
        // ERC165 = 0x01ffc9a7
        // ERC2981 = 0x2a55205a;
    }

    // URI & METADATA SECTION

    function tokenURI(uint256 tokenId) public view returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        if(customURI[tokenId] != address(0)) {
            return ITokenURICustom(customURI[tokenId]).constructTokenURI(tokenId);
        }
        else {
            return _tokenURIs[tokenId];
        }
 
    }

    function metadataLinks(uint256 tokenId) public view returns (string[] memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        return _metadataLinks[tokenId];
    }

    function setTokenURI(uint256 tokenId, string calldata tokenURI_) public onlyOwner {
        require(!lockedURI[tokenId], "URI finalised");
        _tokenURIs[tokenId] = tokenURI_;

    }

    function setMetadataLinks(uint256 tokenId, string[] calldata links) public onlyOwner {
        require(!lockedURI[tokenId], "URI finalised");
        delete _metadataLinks[tokenId];
        for(uint256 i = 0; i < links.length; i++) {
            _metadataLinks[tokenId].push(links[i]);
        }
    }

    function setCustomURI(uint256 tokenId, address contractURI) public onlyOwner {
        require(!lockedURI[tokenId], "URI finalised");
        customURI[tokenId] = contractURI;
    }

    function lockURI(uint256 tokenId) public onlyOwner {
        require(!lockedURI[tokenId], "URI finalised");
        lockedURI[tokenId] = true;

    }

    // ERC721 SECTION

    function balanceOf(address owner) public view returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    function approve(address to, uint256 tokenId) public {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            msg.sender == owner || isApprovedForAll(owner, msg.sender),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    function getApproved(uint256 tokenId) public view returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public {
        _setApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public {
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public {
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    function mint(address to, string calldata tokenURI_) public onlyOwner {
        _tokenCounter++;
        _mint(to, _tokenCounter);
        _tokenURIs[_tokenCounter] = tokenURI_;
    }

    function mintCustomUri(address to, address contractURI) public onlyOwner {
        _tokenCounter++;
        _mint(to, _tokenCounter);
        customURI[_tokenCounter] = contractURI;
    }

    function burn(uint256 tokenId) public {
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: caller is not owner nor approved");
        _burn(tokenId);
        delete _tokenURIs[tokenId];
        delete _metadataLinks[tokenId];
        delete customURI[tokenId];
        delete lockedURI[tokenId];
    }

    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

    }

    function _burn(uint256 tokenId) internal {
        address owner = ownerOf(tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal {
        require(ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");


        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

    }

    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.code.length > 0) {
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
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


    // EIP-2981 ROYALTY STANDARD
    function setRoyaltyBps(uint256 royaltyPercentageBasisPoints) public onlyOwner {
        _royaltyBps = royaltyPercentageBasisPoints;
    }

    function setRoyaltyBpsForTokenId(uint256 tokenId, uint256 royaltyPercentageBasisPoints) public onlyOwner {
        _royaltyBpsTokenId[tokenId] = royaltyPercentageBasisPoints;
    }

    function setRoyaltyReceipientAddress(address payable royaltyReceipientAddress) public onlyOwner {
        _royaltyRecipient = royaltyReceipientAddress;
    }

    function royaltyInfo(uint256 tokenId, uint256 salePrice) external view returns (address receiver, uint256 royaltyAmount) {
        uint256 bps;

        if(_royaltyBpsTokenId[tokenId] > 0) {
            bps = _royaltyBpsTokenId[tokenId];
        }
        else {
            bps = _royaltyBps;
        }

        uint256 royalty = (salePrice * bps) / 10000;
        return (_royaltyRecipient, royalty);
    }

}