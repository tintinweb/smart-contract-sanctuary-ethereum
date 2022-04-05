// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "./ERC721.sol";
// import "./MockStarknetMessaging.sol";
import "./interfaces/IStarknetCore.sol";
contract ERC721_l1_bridge is ERC721 {

    event mint_event( string  mes,uint256  l2Addr,uint256  low,uint256  high);

    
    // The StarkNet core contract.
    IStarknetCore starknetCore;

    uint256 constant MESSAGE_WITHDRAW = 0;
    
    string public name; // ERC721Metadata 

    string public symbol; // ERC721Metadata

    uint256 public tokenCount; 
    

    mapping(uint256 => string) private _tokenURIs;


    constructor(string memory _name, string memory _symbol, address starknetCore_){
        name = _name;
        symbol = _symbol;
        starknetCore = IStarknetCore(starknetCore_);
    }

    // Returns a URL that points to the metadata
    function tokenURI(uint256 tokenId) public view returns (string memory) { // ERC721Metadata
        require(_owners[tokenId] != address(0), "TokenId does not exist");
        return _tokenURIs[tokenId];
    }
    
    // Creates a new NFT inside our collection
    function mint(string memory _tokenURI,uint256 l2ContractAddress,uint256 low,uint256 high) public {

        // Construct the withdrawal message's payload.
        uint256[] memory payload = new uint256[](4);
        payload[0] = MESSAGE_WITHDRAW;
        payload[1] = uint256(uint160(address(msg.sender)));
        payload[2] = low;
        payload[3] = high;

        emit mint_event(_tokenURI,l2ContractAddress,payload[2],payload[3] );
        // Consume the message from the StarkNet core contract.
        // This will revert the (Ethereum) transaction if the message does not exist.
        // starknetCore.consumeMessageFromL2(l2ContractAddress, payload);

        // tokenCount += 1; // tokenId
        // _balances[msg.sender] += 1;
        // _owners[tokenCount] = msg.sender;
        // _tokenURIs[tokenCount] = _tokenURI; 

        // emit Transfer(address(0), msg.sender, tokenCount);
    }
    
    function getOwnerOf(uint256 tokenId) public view returns(address){
       return ownerOf(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public pure override returns(bool) {
        return interfaceId == 0x80ac58cd || interfaceId == 0x5b5e139f;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

contract ERC721 {

    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

    event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);

    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    mapping(address => uint256) internal _balances;

    mapping(uint256 => address) internal _owners;

    mapping(address => mapping(address => bool)) private _operatorApprovals;

    mapping(uint256 => address) private _tokenApprovals;

    // Returns the number of NFTs assigned to an owner
    function balanceOf(address owner) public view returns(uint256) {
        require(owner != address(0), "Address is zero");
        return _balances[owner];
    }

    // Finds the owner of an NFT
    function ownerOf(uint256 tokenId) public view returns(address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "TokenID does not exist");
        return owner;
    }

    // Enables or disables an operator to manage all of msg.senders assets.
    function setApprovalForAll(address operator, bool approved) public {
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    // Checks if an address is an operator for another address
    function isApprovedForAll(address owner, address operator) public view returns(bool) {
        return _operatorApprovals[owner][operator];
    }

    // Updates an approved address for an NFT
    function approve(address to, uint256 tokenId) public {
        address owner = ownerOf(tokenId);
        require( msg.sender == owner || isApprovedForAll(owner, msg.sender), "Msg.sender is not the owner or an approved operator");
        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    // Gets the approved address for a single NFT
    function getApproved(uint256 tokenId) public view returns(address) {
        require(_owners[tokenId] != address(0), "Token ID does not exist");
        return _tokenApprovals[tokenId];
    }

    // Transfers ownership of an NFT
    function transferFrom(address from, address to, uint256 tokenId) public {
        address owner = ownerOf(tokenId);
        require(
            msg.sender == owner ||
            getApproved(tokenId) == msg.sender ||
            isApprovedForAll(owner, msg.sender),
            "Msg.sender is not the owner or approved for transfer"
        );
        require(owner == from, "From address is not the owner");
        require(to != address(0), "Address is zero");
        require(_owners[tokenId] != address(0), "TokenID does not exist");
        approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    // Standard transferFrom
    // Checks if onERC721Received is implemented WHEN sending to smart contracts
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public {
        transferFrom(from, to, tokenId);
        require(_checkOnERC721Received(), "Receiver not implemented");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public {
        safeTransferFrom(from, to, tokenId, "");
    }

    // Oversimplified
    function _checkOnERC721Received() private pure returns(bool) {
        return true;
    }

    // EIP165 : Query if a contract implements another interface
    function supportsInterface(bytes4 interfaceId) public pure virtual returns(bool) {
        return interfaceId == 0x80ac58cd;
    }    

}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.2;

interface IStarknetCore {
    /**
      Sends a message to an L2 contract.

      Returns the hash of the message.
    */
    function sendMessageToL2(
        uint256 to_address,
        uint256 selector,
        uint256[] calldata payload
    ) external returns (bytes32);

    /**
      Consumes a message that was sent from an L2 contract.

      Returns the hash of the message.
    */
    function consumeMessageFromL2(
        uint256 fromAddress,
        uint256[] calldata payload
    ) external returns (bytes32);

    function l2ToL1Messages(bytes32 msgHash) external view returns (uint256);
}