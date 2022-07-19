// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import { ERC721MM } from "./ERC721MM.sol";

contract Items is ERC721MM {
    string constant public name   = "Meta & Magic Items";
    string constant public symbol = "ITEMS";

    mapping(uint256 => address) statsAddress;
    mapping(uint256 => uint256) bossSupplies;

    uint256 lastTokenIdMinted;

    /*///////////////////////////////////////////////////////////////
                        INITIALIZATION
    //////////////////////////////////////////////////////////////*/

    function initialize(address stats_1, address stats_2, address stats_3, address stats_4, address stats_5, address renderer_) external {
        require(msg.sender == _owner(), "not authorized");

        statsAddress[0] = stats_1;
        statsAddress[1] = stats_2;
        statsAddress[2] = stats_3;
        statsAddress[3] = stats_4;
        statsAddress[9] = stats_5;
        
        renderer = renderer_;

        // Setting boss drop supplies
        bossSupplies[1] = 1000; 
        bossSupplies[2] = 900; 
        bossSupplies[3] = 800;
        bossSupplies[4] = 700;
        bossSupplies[5] = 600;
        bossSupplies[6] = 500;
        bossSupplies[7] = 400;
        bossSupplies[8] = 300;
        bossSupplies[9] = 200;
    }

    function setLastTokenIdMinted(uint256 _tokenId) external {
        require(msg.sender == _owner(), "not authorized");
        lastTokenIdMinted = _tokenId;
    }

    /*///////////////////////////////////////////////////////////////
                            VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function getStats(uint256 id_) external view virtual returns(bytes10[6] memory stats_) {    
        uint256 seed = entropySeed;
        require(seed != 0, "Not revealed");
        stats_ = StatsLike(statsAddress[id_ > 10000 ? 9 : (id_ % 4)]).getStats(_traits(seed, id_));
    }

    function isSpecial(uint256 id) external view returns(bool sp) {
        return _isSpecial(id, entropySeed);
    }

    function tokenURI(uint256 id) external view returns (string memory) {
        uint256 seed = entropySeed;
        if (seed == 0) return RendererLike(renderer).getPlaceholder(2);
        return RendererLike(renderer).getUri(id, _traits(seed, id), _getCategory(id,seed));
    }

    /*///////////////////////////////////////////////////////////////
                             MINT FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function mintDrop(uint256 boss, address to) external virtual returns(uint256 id) {
        require(auth[msg.sender], "not authorized");

        id = _bossDropStart(boss) + bossSupplies[boss]--; // Note boss drops are predictable because the entropy seed is known

        _mint(to, id, 2);
    }

    function burnFrom(address from, uint256 id) external returns (bool) {
        require(auth[msg.sender], "not authorized");
        _burn(from, id);
        return true;
    }

    function mint(address to, uint256 amount, uint256 stage) external override returns(uint256 id) {
        require(auth[msg.sender], "not authorized");
        for (uint256 i = 0; i < amount; i++) {
            id = lastTokenIdMinted + 1;
            lastTokenIdMinted++;
            _mint(to, id, stage);     
        }
    }


    /*///////////////////////////////////////////////////////////////
                             TRAIT FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function _traits(uint256 seed_, uint256 id_) internal pure override returns (uint256[6] memory traits) {
        require(seed_ != uint256(0), "seed not set");
        if (_isSpecial(id_, seed_)) return _getSpecialTraits(id_);

        traits = [_getTier(id_,   seed_, "LEVEL"), 
                  _getTier(id_,    seed_, "KIND"), 
                  _getTier(id_,    seed_, "MATERIAL"), 
                  _getTier(id_,    seed_, "RARITY"), 
                  _getTier(id_,    seed_, "QUALITY"),
                  _getElement(id_, seed_, "ELEMENT")];

        uint256 boss = _getBossForId(id_);
        if (boss > 0) {
            traits[1] = 10 + boss;
            traits[4] = 0; // Boss traits doesnt have material type
        }
    }

    function _getSpecialTraits(uint256 id_) internal pure returns (uint256[6] memory t) {
        uint256 spc = (id_ / 1250) + 1;
        
        uint256 traitIndcator = spc * 10 + spc;

        t = [traitIndcator,traitIndcator,traitIndcator,traitIndcator,traitIndcator,traitIndcator];
    }

    function _getElement(uint256 id_, uint256 seed, bytes32 salt) internal pure returns (uint256 class_) {
        if (id_ % 4 == 3) return _getTier(id_, seed, "POTENCY");
        
        uint256 rdn = uint256(keccak256(abi.encode(id_, seed, salt))) % 100_0000 + 1; 

        if (rdn <= 50_0000) return 1;
        return (rdn % 5) + 2;
    }

    function _bossDropStart(uint256 boss) internal pure returns(uint256 start) {
        if (boss == 1) start = 10000;
        if (boss == 2) start = 11000;
        if (boss == 3) start = 11900;
        if (boss == 4) start = 12700;
        if (boss == 5) start = 13400;
        if (boss == 6) start = 14000;
        if (boss == 7) start = 14500;
        if (boss == 8) start = 14900;
        if (boss == 9) start = 15200;
    } 


    function _getBossForId(uint256 id) internal pure returns(uint256 boss) {
        if (id <= 10000) return 0;
        if (id <= 11000) return 1;
        if (id <= 11900) return 2;
        if (id <= 12700) return 3;
        if (id <= 13400) return 4;
        if (id <= 14000) return 5;
        if (id <= 14500) return 6;
        if (id <= 14900) return 7;
        if (id <= 15200) return 8;
        if (id <= 15400) return 9;
    }

    function _isSpecial(uint256 id, uint256 seed) internal pure returns (bool special) {
        uint256 rdn = _getRndForSpecial(seed);
        for (uint256 i = 0; i < 9; i++) {
            if (id == rdn + (1250 * i)) {
                special = true;
                break;
            }
        }
    }

    function _getSpecialCategory(uint256 id, uint256 seed) internal pure returns (uint256 spc) {
        uint256 num = (id / 1250) + 1;
        spc = num + 5 + (num - 1);
    }

    function _getCategory(uint256 id, uint256 seed) internal pure returns (uint256 cat) {
        // Boss Drop
        if (id > 10000) return cat = 4;
        if (_isSpecial(id, seed)) return _getSpecialCategory(id, seed);
        return 2;
    }

    function _getRndForSpecial(uint256 seed) internal pure virtual returns (uint256 rdn) {
        rdn = uint256(keccak256(abi.encode(seed, "SPECIAL"))) % 1250 + 1;
    }

}

interface RendererLike {
    function getUri(uint256 id, uint256[6] calldata traits, uint256 cat) external view returns (string memory meta);
    function getPlaceholder(uint256 cat) external pure returns (string memory meta);
}

interface StatsLike {
    function getStats(uint256[6] calldata attributes) external view returns (bytes10[6] memory stats_); 
}

interface VRFCoordinatorV2Interface {
    function requestRandomWords(
    bytes32 keyHash,
    uint64 subId,
    uint16 minimumRequestConfirmations,
    uint32 callbackGasLimit,
    uint32 numWords
  ) external returns (uint256 requestId);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.7;

/// @notice Modern and gas efficient ERC-721 + ERC-20/EIP-2612-like implementation,
/// Modified version inspired by ERC721A
abstract contract ERC721MM {

    /*///////////////////////////////////////////////////////////////
                                  EVENTS
    //////////////////////////////////////////////////////////////*/
    
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    
    event Approval(address indexed owner, address indexed spender, uint256 indexed tokenId);
    
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    
    
    /*///////////////////////////////////////////////////////////////
                             ERC-721 STORAGE
    //////////////////////////////////////////////////////////////*/

    struct AddressData { uint128 balance; uint64 listMinted; uint64 publicMinted; }

    uint256 public totalSupply;
    uint256 public entropySeed;
    
    mapping(address => bool)    public auth;

    mapping(address => AddressData) public datas;
    
    mapping(uint256 => address) public ownerOf;
        
    mapping(uint256 => address) public getApproved;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    // Rendering information
    address public renderer;

    // Oracle information
    address public VRFcoord;

    uint64  public subId;

    bytes32 public keyhash;

    /*///////////////////////////////////////////////////////////////
                VIRTUAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function _traits(uint256 entropy_, uint256 id_) internal pure virtual returns (uint256[6] memory traits_);
    
    /*///////////////////////////////////////////////////////////////
                             VIEW FUNCTION
    //////////////////////////////////////////////////////////////*/

    function owner() external view returns (address owner_) {
        return _owner();
    }

    function balanceOf(address add) external view returns(uint256 balance_) {
        balance_ = datas[add].balance;
    }

    function listMinted(address add) external view returns(uint256 minted_) {
        minted_ = datas[add].listMinted;
    }

    function publicMinted(address add) external view returns(uint256 minted_) {
        minted_ = datas[add].publicMinted;
    }

    /*///////////////////////////////////////////////////////////////
                            M&M SPECIFIC LOGIC
    //////////////////////////////////////////////////////////////*/

    function setAuth(address add_, bool auth_) external {
        require(_owner() == msg.sender, "not authorized");
        auth[add_] = auth_;
    }

    function mint(address to, uint256 amount, uint256 stage) external virtual returns(uint256 id) {
        require(auth[msg.sender], "not authorized");
        for (uint256 i = 0; i < amount; i++) {
            id = totalSupply + 1;
            _mint(to, id, stage);     
        }
    }

     function setUpOracle(address vrf_, bytes32 keyHash, uint64 subscriptionId) external {
        require(msg.sender == _owner());

        VRFcoord = vrf_;
        keyhash  = keyHash;
        subId    = subscriptionId;
    }

    function requestEntropy() external {
        require(msg.sender == _owner(), "not auth");
        require(entropySeed == 0,       "already requested");

        VRFCoordinatorV2Interface(VRFcoord).requestRandomWords(keyhash, subId, 3, 200000, 1);
    }

    function rawFulfillRandomWords(uint256 , uint256[] memory randomWords) external {
        require(msg.sender == VRFcoord, "not allowed");
        require(entropySeed == 0);
        entropySeed = randomWords[0];
   }

   function getTraits(uint256 id_) external view returns (uint256[6] memory traits_) {
        return _traits(entropySeed, id_);
    }

    function _getTier(uint256 id_, uint256 seed, bytes32 salt) internal pure returns (uint256 t_) {
        uint256 rdn = uint256(keccak256(abi.encode(id_, seed, salt))) % 100_0000 + 1; 
        if (rdn <= 28_9333) return 1;
        if (rdn <= 52_8781) return 2;
        if (rdn <= 71_8344) return 3;
        if (rdn <= 85_8022) return 4;
        if (rdn <= 94_7815) return 5;
        return 6;
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

        datas[from].balance--; 
        datas[to].balance++;
        
        delete getApproved[tokenId];
        
        ownerOf[tokenId] = to;
        emit Transfer(from, to, tokenId); 

    }

    function _mint(address to, uint256 tokenId, uint256 stage) internal { 
        require(ownerOf[tokenId] == address(0), "ALREADY_MINTED");

        totalSupply++;
        
        // This is safe because the sum of all user
        // balances can't exceed type(uint256).max!
        unchecked {
            datas[to].balance++;
            stage == 1 ? datas[to].listMinted++ : datas[to].publicMinted++;
        }
        
        ownerOf[tokenId] = to;
                
        emit Transfer(address(0), to, tokenId); 
    }
    
    function _burn(address acc, uint256 tokenId) internal { 
        address owner_ = ownerOf[tokenId];
        
        require(acc == owner_, "NOT_OWNER");
        require(ownerOf[tokenId] != address(0), "NOT_MINTED");
        
        totalSupply--;
        datas[owner_].balance--;
        
        delete ownerOf[tokenId];
                
        emit Transfer(owner_, address(0), tokenId); 
    }
}

interface VRFCoordinatorV2Interface {
    function requestRandomWords(
    bytes32 keyHash,
    uint64 subId,
    uint16 minimumRequestConfirmations,
    uint32 callbackGasLimit,
    uint32 numWords
  ) external returns (uint256 requestId);
}