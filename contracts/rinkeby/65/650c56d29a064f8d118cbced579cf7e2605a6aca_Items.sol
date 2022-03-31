/**
 *Submitted for verification at Etherscan.io on 2022-03-31
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

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
                             ERC-721 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;
    
    mapping(address => bool)    public auth;

    mapping(address => uint256) public balanceOf;
    
    mapping(uint256 => address) public ownerOf;
        
    mapping(uint256 => address) public getApproved;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*///////////////////////////////////////////////////////////////
                             VIEW FUNCTION
    //////////////////////////////////////////////////////////////*/

    function owner() external view returns (address owner_) {
        return _owner();
    }
    
    /*///////////////////////////////////////////////////////////////
                              ERC-721 LOGIC
    //////////////////////////////////////////////////////////////*/
    
    function transfer(address to, uint256 tokenId) external returns (bool) {
        require(msg.sender == ownerOf[tokenId], "NOT_OWNER");
        
        _transfer(msg.sender, to, tokenId);
        return true;
    }
    
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

    function transferFrom(address from, address to, uint256 tokenId) public returns (bool){        
        require(
            msg.sender == from 
            || msg.sender == getApproved[tokenId]
            || isApprovedForAll[from][msg.sender]
            || auth[msg.sender],
            "NOT_APPROVED"
        );
        
        _transfer(from, to, tokenId);
        return true;
    }
    
    function safeTransferFrom(address from, address to, uint256 tokenId) external {
        safeTransferFrom(from, to, tokenId, "");
    }
    
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public {
        transferFrom(from, to, tokenId); 
        
        if (to.code.length != 0) {
            // selector = `onERC721Received(address,address,uint,bytes)`
            (, bytes memory returned) = to.staticcall(abi.encodeWithSelector(0x150b7a02,
                msg.sender, address(0), tokenId, data));
                
            bytes4 selector = abi.decode(returned, (bytes4));
            
            require(selector == 0x150b7a02, "NOT_ERC721_RECEIVER");
        }
    }
    
    /*///////////////////////////////////////////////////////////////
                          INTERNAL UTILS
    //////////////////////////////////////////////////////////////*/

    function _owner() internal view returns (address owner_) {
        bytes32 slot = bytes32(0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103);
        assembly {
            owner_ := sload(slot)
        }
    } 

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

        totalSupply++;
        
        // This is safe because the sum of all user
        // balances can't exceed type(uint256).max!
        unchecked {
            balanceOf[to]++;
        }
        
        ownerOf[tokenId] = to;
                
        emit Transfer(address(0), to, tokenId); 
    }
    
    function _burn(address acc, uint256 tokenId) internal { 
        address owner_ = ownerOf[tokenId];
        
        require(acc == owner_, "NOT_OWNER");
        require(ownerOf[tokenId] != address(0), "NOT_MINTED");
        
        totalSupply--;
        balanceOf[owner_]--;
        
        delete ownerOf[tokenId];
                
        emit Transfer(owner_, address(0), tokenId); 
    }
}

contract Items is ERC721 {

    string constant public name   = "Meta&Magic-Items";
    string constant public symbol = "M&M-ITEMS";

    address renderer;
    uint256 entropySeed;

    mapping(uint256 => address) statsAddress;
    mapping(uint256 => uint256) bossSupplies;

    // Oracle information
    address VRFcoord;
    uint64  subId;
    bytes32 keyhash;

    function initialize(address stats_1, address stats_2, address stats_3, address stats_4, address stats_5, address renderer_) external {
        require(msg.sender == _owner(), "not authorized");

        statsAddress[1] = stats_1;
        statsAddress[2] = stats_2;
        statsAddress[3] = stats_3;
        statsAddress[4] = stats_4;
        statsAddress[5] = stats_5;
        
        renderer = renderer_;

        // Setting boss drop supplies
        bossSupplies[2]  = 1000; 
        bossSupplies[3]  = 900; 
        bossSupplies[4]  = 800;
        bossSupplies[5]  = 700;
        bossSupplies[6]  = 600;
        bossSupplies[7]  = 500;
        bossSupplies[8]  = 400;
        bossSupplies[9]  = 300;
        bossSupplies[10] = 200;
    }

    function setUpOracle(address vrf_, bytes32 keyHash, uint64 subscriptionId) external {
        require(msg.sender == _owner());

        VRFcoord = vrf_;
        keyhash  = keyHash;
        subId    = subscriptionId;
    }

    function getStats(uint256 id_) external view virtual returns(bytes32, bytes32) {    
        uint256 seed = entropySeed;
        
        if (id_ > 10000) return StatsLike(statsAddress[10]).getStats(_bossTraits(seed, id_));

        if (!_isSpecial(id_, seed)) return StatsLike(statsAddress[(id_ % 4) + 1]).getStats(_traits(seed, id_));
    }

    function getTraits(uint256 id_) external view returns (uint256[6] memory traits_) {
        return _traits(entropySeed, id_);
    }

    /*///////////////////////////////////////////////////////////////
                             MINT FUNCTIONS
    //////////////////////////////////////////////////////////////*/


    function mintDrop(uint256 boss, address to) external virtual returns(uint256 id) {
        require(auth[msg.sender], "not authorized");

        id = boss * 10_000 + bossSupplies[boss]--; // Note boss drops are predictable because the entropy seed is known

        _mint(to, id);
    }

    function burnFrom(address from, uint256 id) external returns (bool) {
        require(auth[msg.sender], "not authorized");
        _burn(from, id);
    }


    /*///////////////////////////////////////////////////////////////
                             TRAIT FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function _traits(uint256 seed, uint256 id_) internal pure returns (uint256[6] memory traits) {
        traits = [_getTier(id_,    seed, "LEVEL"), 
                  _getTier(id_,    seed, "KIND"), 
                  _getTier(id_,    seed, "MATERIAL"), 
                  _getTier(id_,    seed, "RARITY"), 
                  _getTier(id_,    seed, "QUALITY"),
                  _getElement(id_, seed, "ELEMENT")];
    }
    
    function _bossTraits(uint256 seed, uint256 id_) internal pure returns (uint256[6] memory traits) {
        traits = _traits(seed, id_);
        
        // Overriding kind
        traits[1] =  id_ / 10_000;
    }

    function _getTier(uint256 id_, uint256 seed, bytes32 salt) internal pure returns (uint256 t_) {
        uint256 rdn = uint256(keccak256(abi.encode(id_, seed, salt))) % 100_0000 + 1; 
        if (rdn <= 29_9333) return 1;
        if (rdn <= 52_8781) return 2;
        if (rdn <= 71_8344) return 3;
        if (rdn <= 85_8022) return 4;
        if (rdn <= 94_7815) return 5;
        return 6;
    }

    function _getElement(uint256 id_, uint256 seed, bytes32 salt) internal pure returns (uint256 class_) {
        uint256 rdn = uint256(keccak256(abi.encode(id_, seed, salt))) % 100_0000 + 1; 

        if (rdn <= 25_0000) return 0;
        return (rdn % 5) + 1;
    }

    function _isSpecial(uint256 id, uint256 seed) internal pure returns (bool special) {
        uint256 rdn = uint256(keccak256(abi.encode(seed, "SPECIAL"))) % 9_991 + 1;
        if (id > rdn && id <= rdn + 8) return true;
    }

    // TODO add chainlink
    function setEntropy(uint256 seed) external {
        entropySeed = seed;
    }

    function setAuth(address add_, bool auth_) external {
        require(_owner() == msg.sender, "not authorized");
        auth[add_] = auth_;
    }

}


interface StatsLike {
    function getStats(uint256[6] calldata attributes) external view returns (bytes32 s1, bytes32 s2); 
}