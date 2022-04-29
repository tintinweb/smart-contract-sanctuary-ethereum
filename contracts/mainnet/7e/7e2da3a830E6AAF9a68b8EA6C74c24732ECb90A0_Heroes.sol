// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;
import { ERC721MM } from "./ERC721MM.sol";


contract Heroes is ERC721MM {

    string constant public name   = "Meta & Magic Heroes";
    string constant public symbol = "HEROES";

    mapping(uint256 => uint256) bossSupplies;

    address stats;

    /*///////////////////////////////////////////////////////////////
                        INITIALIZATION
    //////////////////////////////////////////////////////////////*/

    function initialize(address stats_, address renderer_) external {
        require(msg.sender == _owner(), "not authorized");

        stats    = stats_;
        renderer = renderer_;

        bossSupplies[10] = 100;
    }

    /*///////////////////////////////////////////////////////////////
                        VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function getStats(uint256 id_) external view virtual returns(bytes10[6] memory stats_) {    // [][]
        uint256 seed = entropySeed;
        require(seed != 0, "Not revealed");

        stats_ = StatsLike(stats).getStats(_traits(seed, id_));
    }

    function isSpecial(uint256 id) external view returns(bool sp) {
        return _isSpecial(id, entropySeed);
    }
    function tokenURI(uint256 id) external view returns (string memory) {
        uint256 seed = entropySeed;
        if (seed == 0) return RendererLike(renderer).getPlaceholder(1);
        return RendererLike(renderer).getUri(id, _traits(seed, id), _getCategory(id,seed));
    }

    /*///////////////////////////////////////////////////////////////
                        MINT FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function mintDrop(uint256 boss, address to) external virtual returns(uint256 id) {
        require(auth[msg.sender], "not authorized");

        id = 3000 + bossSupplies[boss]--; // Note boss drops are predictable because the entropy seed is known

        _mint(to, id, 2);
    }

    /*///////////////////////////////////////////////////////////////
                            INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function _traits(uint256 seed_, uint256 id_) internal pure override returns (uint256[6] memory t ) {
        require(seed_ != uint256(0), "seed not set");
        if (_isSpecial(id_, seed_)) return _getSpecialTraits(seed_, id_);
        
        t = [ _getTier(id_,  seed_, "LEVEL"), 
               _getClass(id_, seed_, "CLASS"), 
               _getTier(id_,  seed_, "RANK"), 
               _getTier(id_,  seed_, "RARITY"), 
               _getTier(id_,  seed_, "PET"),
               _getItem(id_,  seed_, "ITEM")];
            
        if (id_ > 3000) t[1] = 8;
    }

    function _getSpecialTraits(uint256 seed_, uint256 id_) internal pure returns (uint256[6] memory t) {
        uint256 spc = (id_ / 428) + 1;
        
        uint256 traitIndcator = (spc) * 10 + spc;

        t = [traitIndcator,traitIndcator,traitIndcator,traitIndcator,traitIndcator,traitIndcator];
    }

    function _getClass(uint256 id_, uint256 seed, bytes32 salt) internal pure returns (uint256 class_) {
        uint256 rdn = uint256(keccak256(abi.encode(id_, seed, salt))) % 100_0000 + 1; 

        if (rdn <= 79_8160) return (rdn % 5) + 1;
        if (rdn <= 91_7884) return 6;
        return 7;
    }

    function _getItem(uint256 id_, uint256 seed, bytes32 salt) internal pure returns (uint256 item_) {
        uint256 rdn = uint256(keccak256(abi.encode(id_, seed, salt))) % 100_0000 + 1; 
        if (rdn <= 24_9425) return 0;

        return _getTier(id_, seed, salt) + ((rdn % 3) * 6);
    }

    function _isSpecial(uint256 id, uint256 seed_) internal pure returns (bool special) {
        uint256 rdn = _getRndForSpecial(seed_);
        for (uint256 i = 0; i < 8; i++) {
            if (id == rdn + (428 * i)) {
                special = true;
                break;
            }
        }
    }

    function _getSpecialCategory(uint256 id, uint256 seed_) internal pure returns (uint256 spc) {
        uint256 num = (id / 428) + 1;
        spc = num + 4 + (num - 1);
    }

    function _getCategory(uint256 id, uint256 seed) internal pure returns (uint256 cat) {
        // Boss Drop
        if (id > 3000) return cat = 3;
        if (_isSpecial(id, seed)) return _getSpecialCategory(id, seed);
        return 1;
    }

    function _getRndForSpecial(uint256 seed) internal pure virtual returns (uint256 rdn) {
        rdn = uint256(keccak256(abi.encode(seed, "SPECIAL"))) % 428 + 1;
    }

}

interface StatsLike {
    function getStats(uint256[6] calldata attributes) external view returns (bytes10[6] memory stats_); 
}

interface RendererLike {
    function getUri(uint256 id, uint256[6] calldata traits, uint256 cat) external view returns (string memory meta);
    function getPlaceholder(uint256 cat) external pure returns (string memory meta);
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