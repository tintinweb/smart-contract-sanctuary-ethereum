/**
 *Submitted for verification at Etherscan.io on 2023-03-09
*/

// File: contracts/ITraits.sol


pragma solidity ^0.8.0;

interface ITraits {
  function tokenURI(uint256 tokenId) external view returns (string memory);
}
// File: contracts/ERC721.sol

pragma solidity ^0.8.7;


/// @notice Modern and gas efficient ERC-721 + ERC-20/EIP-2612-like implementation,
/// including the MetaData, and partially, Enumerable extensions.
contract ERC721 {
    /*///////////////////////////////////////////////////////////////
                                  EVENTS
    //////////////////////////////////////////////////////////////*/
    
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    
    event Approval(address indexed owner, address indexed spender, uint256 indexed tokenId);
    
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    
    /*///////////////////////////////////////////////////////////////
                             METADATA STORAGE
    //////////////////////////////////////////////////////////////*/
    
    address        implementation_;
    address public admin; //Lame requirement from opensea
    
    /*///////////////////////////////////////////////////////////////
                             ERC-721 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;
    uint256 public oldSupply;
    uint256 public minted;
    
    mapping(address => uint256) public balanceOf;
    
    mapping(uint256 => address) public ownerOf;
        
    mapping(uint256 => address) public getApproved;
 
    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*///////////////////////////////////////////////////////////////
                             VIEW FUNCTION
    //////////////////////////////////////////////////////////////*/

    function owner() external view returns (address) {
        return admin;
    }
    
    /*///////////////////////////////////////////////////////////////
                              ERC-20-LIKE LOGIC
    //////////////////////////////////////////////////////////////*/
    
    function transfer(address to, uint256 tokenId) external {
        require(msg.sender == ownerOf[tokenId], "NOT_OWNER");
        
        _transfer(msg.sender, to, tokenId);
        
    }
    
    /*///////////////////////////////////////////////////////////////
                              ERC-721 LOGIC
    //////////////////////////////////////////////////////////////*/
    
    function supportsInterface(bytes4 interfaceId) external pure returns (bool supported) {
        supported = interfaceId == 0x80ac58cd || interfaceId == 0x5b5e139f;
    }
    
    function approve(address spender, uint256 tokenId) external {
        address owner_ = ownerOf[tokenId];
        
        require(msg.sender == owner_ || isApprovedForAll[owner_][msg.sender], "NOT_APPROVED");
        
        getApproved[tokenId] = spender;
        
        emit Approval(owner_, spender, tokenId); 
    }
    
    function setApprovalForAll(address operator, bool approved) external {
        isApprovedForAll[msg.sender][operator] = approved;
        
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(address from, address to, uint256 tokenId) public {
        require(
            msg.sender == from 
            || msg.sender == getApproved[tokenId]
            || isApprovedForAll[from][msg.sender], 
            "NOT_APPROVED"
        );
        
        _transfer(from, to, tokenId);
        
    }
    
    function safeTransferFrom(address from, address to, uint256 tokenId) external {
        safeTransferFrom(from, to, tokenId, "");
    }
    
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public {
        transferFrom(from, to, tokenId); 
        
        if (to.code.length != 0) {
            // selector = `onERC721Received(address,address,uint,bytes)`
            (, bytes memory returned) = to.staticcall(abi.encodeWithSelector(0x150b7a02,
                msg.sender, from, tokenId, data));
                
            bytes4 selector = abi.decode(returned, (bytes4));
            
            require(selector == 0x150b7a02, "NOT_ERC721_RECEIVER");
        }
    }
    
    /*///////////////////////////////////////////////////////////////
                          INTERNAL UTILS
    //////////////////////////////////////////////////////////////*/

    function _transfer(address from, address to, uint256 tokenId) internal {
        require(ownerOf[tokenId] == from, "not owner");

        balanceOf[from]--; 
        balanceOf[to]++;
        
        delete getApproved[tokenId];
        
        ownerOf[tokenId] = to;
        emit Transfer(from, to, tokenId); 

    }

    function _mint(address to, uint256 tokenId) internal { 
        require(ownerOf[tokenId] == address(0), "ALREADY_MINTED");

        uint supply = oldSupply + minted++;
        uint maxSupply = 5000;
        require(supply <= maxSupply, "MAX SUPPLY REACHED");
        totalSupply++;
                
        // This is safe because the sum of all user
        // balances can't exceed type(uint256).max!
        unchecked {
            balanceOf[to]++;
        }
        
        ownerOf[tokenId] = to;
                
        emit Transfer(address(0), to, tokenId); 
    }
    
    function _burn(uint256 tokenId) internal { 
        address owner_ = ownerOf[tokenId];
        
        require(ownerOf[tokenId] != address(0), "NOT_MINTED");
        
        totalSupply--;
        balanceOf[owner_]--;
        
        delete ownerOf[tokenId];
                
        emit Transfer(owner_, address(0), tokenId); 
    }
}


// File: contracts/Doges.sol

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;



contract Doges is ERC721 {
    uint256 public constant MAX_SUPPLY = 5000;

    mapping(uint256 => uint256) public existingCombinations;
    mapping(uint256 => Doge) internal doges;

    ITraits public descriptor;

    bytes32 internal entropySauce;
    mapping(uint256 => uint256) public mintBlocks;
    bool public mintActive;


    struct Doge {
        uint8 hat;
        uint8 face;
        uint8 color1;
        uint8 color2;
        uint8 color3;
    }

    constructor() {
        admin = msg.sender;
    }

    modifier noCheaters() {
        uint256 size = 0;
        address acc = msg.sender;
        assembly {
            size := extcodesize(acc)
        }

        require(
            (msg.sender == tx.origin && size == 0),
            "you're trying to cheat!"
        );
        _;

        // We'll use the last caller hash to add entropy to next caller
        entropySauce = keccak256(abi.encodePacked(acc, block.coinbase, entropySauce));
    }

    modifier onlyOwner() {
        require(msg.sender == admin);
        _;
    }

    function setDescriptor(address _descriptor) external onlyOwner {
        descriptor = ITraits(_descriptor);
    }

    function transferOwnership(address newOwner) external onlyOwner {
        admin = newOwner;
    }

    function setMintActive(bool _status) external onlyOwner {
        mintActive = _status;
    }


    function mintDoge() public payable noCheaters {
        require(mintActive, "Must be active to mint");
        require(totalSupply <= MAX_SUPPLY, "All supply minted");
        require(msg.value >= mintPrice(), "Value below price");
        _mintDoge(msg.sender);
    }

    function mintPrice() public view returns (uint256) {
        uint256 supply = minted;
        if (supply < 30) return 0;
        return 0.001 ether;
    }

    function name() external pure returns (string memory) {
        return "Doges";
    }

    function symbol() external pure returns (string memory) {
        return "Doges";
    }


    function tokenURI(uint256 tokenId) public view returns (string memory) {
        require(mintBlocks[tokenId] != block.number, "ERC721Metadata: URI query for nonexistent token");
        return descriptor.tokenURI(tokenId);
    }


    function getTokenTraits(uint256 tokenId) external view virtual returns (Doge memory) {
        if (mintBlocks[tokenId] == block.number) return doges[0];
        return doges[tokenId];
    }


    function _mintDoge(address to) internal {
        uint16 id = uint16(totalSupply + 1);
        mintBlocks[id] = block.number;
        uint256 seed = random(id);
        generate(id, seed);
        _mint(to, id);
    }

    function generate(uint256 tokenId, uint256 seed) internal returns (Doge memory t) {
        t = selectTraits(seed);
        if (existingCombinations[structToHash(t)] == 0) {
            doges[tokenId] = t;
            existingCombinations[structToHash(t)] = tokenId;
            return t;
        }
        return generate(tokenId, random(seed));
    }

    function selectTraits(uint256 seed) internal pure returns (Doge memory t) {    
        t.hat = uint8(seed & 0xFFFF) % 12;
        seed >>= 16;
        t.face = uint8(seed & 0xFFFF) % 9;
        seed >>= 16;
        t.color1 = uint8(seed & 0xFFFF) % 20;
        seed >>= 16;
        t.color2 = uint8(seed & 0xFFFF) % 20;
        seed >>= 16;
        t.color3 = uint8(seed & 0xFFFF) % 20;
    }

    function structToHash(Doge memory s) internal pure returns (uint256) {
        return uint256(bytes32(
            abi.encodePacked(
                s.hat,
                s.face,
                s.color1,
                s.color2,
                s.color3
            )
        ));
    }

    function random(uint256 seed) internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(
            tx.origin,
            blockhash(block.number - 1),
            block.timestamp,
            seed
        )));
    }


    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

}