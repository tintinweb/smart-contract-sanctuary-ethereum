// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import { Heroes }       from "../contracts/Heroes.sol";  
import { Items }        from "../contracts/Items.sol";


contract HeroesMock is Heroes {

    uint256 mockminted;

    function setMinted(uint256 minted_) external {
        mockminted = minted_;
    }

    function mintFree(address to, uint256 amount) external virtual returns(uint256 id) {
        for (uint256 i = 0; i < amount; i++) {
            id = mockminted++;
            _mint(to, id);     
        }
    }

    function getSpecialSart() external view returns (uint256 rdn) {
        rdn = uint256(keccak256(abi.encode(entropySeed, "SPECIAL"))) % 2_993 + 1;
    }


}

contract ItemsMock is Items {

    uint256 mockminted;

    function setMinted(uint256 minted_) external {
        mockminted = minted_;
    }


    function mintFree(address to, uint256 amount) external virtual returns(uint256 id) {
        for (uint256 i = 0; i < amount; i++) {
            id = mockminted++;
            _mint(to, id);     
        }
    }

    function mintId(address to, uint256 id_) external virtual returns(uint256 id) {
        _mint(to, id_);    
        id = id_; 
    }

    function mintFive(address to, uint16 fst, uint16 sc,uint16 thr,uint16 frt,uint16 fifth)  external returns(uint16[5] memory list) {
        _mint(to, fst);
        _mint(to, sc);
        _mint(to, thr);
        _mint(to, frt);
        _mint(to, fifth);

        list = [fst,sc,thr,frt, fifth];
    }

    function getSpecialSart() external view returns (uint256 rdn) {
        rdn = uint256(keccak256(abi.encode(entropySeed, "SPECIAL"))) % 9_992 + 1;
    }
}

interface VRFConsumer {
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWord) external;
}

contract VRFMock {

    uint256 nonce;
    uint256 reqId;
    address consumer;

    function requestRandomWords( bytes32 , uint64 , uint16 , uint32 , uint32 ) external returns (uint256 requestId) {
        requestId = uint256(keccak256(abi.encode("REQUEST", nonce++)));
        consumer = msg.sender;
        reqId = requestId;
    }

    function fulfill() external {
        uint256[] memory words = new uint256[](1);
        words[0] = uint256(keccak256(abi.encode("REQUEST", reqId, consumer, nonce++)));
        VRFConsumer(consumer).fulfillRandomWords(reqId, words);
    }


}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import { ERC721 } from "./ERC721.sol";


contract Heroes is ERC721 {

    string constant public name   = "Meta&Magic-Heroes";
    string constant public symbol = "M&M-HEROES";

    mapping(uint256 => uint256) bossSupplies;

    address stats;
    address renderer;

    uint256 entropySeed;


    // Oracle information
    address VRFcoord;
    uint64  subId;
    bytes32 keyhash;

    function initialize(address stats_, address renderer_) external {
        require(msg.sender == _owner(), "not authorized");

        stats    = stats_;
        renderer = renderer_;

        bossSupplies[10] = 100;
    }

    function getStats(uint256 id_) external view virtual returns(bytes10[6] memory stats_) {    // [][]
        uint256 seed = entropySeed;
        
        stats_ = StatsLike(stats).getStats(_traits(seed, id_));
    }

    function getTraits(uint256 id_) external view returns (uint256[6] memory traits_) {
        return _traits(entropySeed, id_);
    }

    function isSpecial(uint256 id) external view returns(bool sp) {
        return _isSpecial(id, entropySeed);
    }

    function setUpOracle(address vrf_, bytes32 keyHash, uint64 subscriptionId) external {
        require(msg.sender == _owner());

        VRFcoord = vrf_;
        keyhash  = keyHash;
        subId    = subscriptionId;
    }

    function tokenURI(uint256 id) external view returns (string memory) {
        uint256 seed = entropySeed;
        return RendererLike(renderer).getUri(id, _traits(seed, id), _getCategory(id,seed));
    }

    /*///////////////////////////////////////////////////////////////
                        MINT FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function setAuth(address add_, bool auth_) external {
        require(_owner() == msg.sender, "not authorized");
        auth[add_] = auth_;
    }

    function setEntropy(uint256 seed) external {
        entropySeed = seed;
    }

    function mint(address to, uint256 amount) external virtual returns(uint256 id) {
        require(auth[msg.sender], "not authorized");
        for (uint256 i = 0; i < amount; i++) {
            id = totalSupply + 1;
            _mint(to, id);     
        }
    }

    function mintDrop(uint256 boss, address to) external virtual returns(uint256 id) {
        require(auth[msg.sender], "not authorized");

        id = 3000 + bossSupplies[boss]--; // Note boss drops are predictable because the entropy seed is known

        _mint(to, id);
    }

    /*///////////////////////////////////////////////////////////////
                             TRAIT FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function _traits(uint256 seed_, uint256 id_) internal pure returns (uint256[6] memory t ) {
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
        uint256 spc = id_ - _getRndForSpecial(seed_);
        
        uint256 traitIndcator = spc * 10 + spc;

        t = [traitIndcator,traitIndcator,traitIndcator,traitIndcator,traitIndcator,traitIndcator];
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

    function _isSpecial(uint256 id, uint256 seed) internal pure returns (bool special) {
        uint256 rdn = _getRndForSpecial(seed);
        if (id > rdn && id <= rdn + 7) return true;
    }

    function _getSpecialCategory(uint256 id, uint256 seed) internal pure returns (uint256 spc) {
        uint256 num = id - _getRndForSpecial(seed);
        spc = num + 4 + (num - 1);
    }

    function _getCategory(uint256 id, uint256 seed) internal pure returns (uint256 cat) {
        // Boss Drop
        if (id > 3000) return cat = 3;
        if (_isSpecial(id, seed)) return _getSpecialCategory(id, seed);
        return 1;
    }

    function _getRndForSpecial(uint256 seed) internal pure returns (uint256 rdn) {
        rdn = uint256(keccak256(abi.encode(seed, "SPECIAL"))) % 2_993 + 1;
    }

}


interface StatsLike {
    function getStats(uint256[6] calldata attributes) external view returns (bytes10[6] memory stats_); 
}

interface RendererLike {
    function getUri(uint256 id, uint256[6] calldata traits, uint256 cat) external view returns (string memory meta);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import { ERC721 } from "./ERC721.sol";

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

    function setUpOracle(address vrf_, bytes32 keyHash, uint64 subscriptionId) external {
        require(msg.sender == _owner());

        VRFcoord = vrf_;
        keyhash  = keyHash;
        subId    = subscriptionId;
    }

    function getStats(uint256 id_) external view virtual returns(bytes10[6] memory stats_) {    
        uint256 seed = entropySeed;
        
        if (!_isSpecial(id_, seed)) return stats_ = StatsLike(statsAddress[id_ > 10000 ? 9 : (id_ % 4)]).getStats(_traits(seed, id_));
    }

    function getTraits(uint256 id_) external view returns (uint256[6] memory traits_) {
        return _traits(entropySeed, id_);
    }

    function tokenURI(uint256 id) external view returns (string memory) {
        uint256 seed = entropySeed;
        return RendererLike(renderer).getUri(id, _traits(seed, id), _getCategory(id,seed));
    }


    /*///////////////////////////////////////////////////////////////
                             MINT FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function mint(address to, uint256 amount) external virtual returns(uint256 id) {
        require(auth[msg.sender], "not authorized");
        for (uint256 i = 0; i < amount; i++) {
            id = totalSupply + 1;
            _mint(to, id);     
        }
    }

    function mintDrop(uint256 boss, address to) external virtual returns(uint256 id) {
        require(auth[msg.sender], "not authorized");

        id = _bossDropStart(boss) + bossSupplies[boss]--; // Note boss drops are predictable because the entropy seed is known

        _mint(to, id);
    }

    function burnFrom(address from, uint256 id) external returns (bool) {
        require(auth[msg.sender], "not authorized");
        _burn(from, id);
        return true;
    }


    /*///////////////////////////////////////////////////////////////
                             TRAIT FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function _traits(uint256 seed_, uint256 id_) internal pure returns (uint256[6] memory traits) {
        require(seed_ != uint256(0), "seed not set");
        if (_isSpecial(id_, seed_)) return _getSpecialTraits(seed_, id_);

        traits = [_getTier(id_,   seed_, "LEVEL"), 
                  _getTier(id_,    seed_, "KIND"), 
                  _getTier(id_,    seed_, "MATERIAL"), 
                  _getTier(id_,    seed_, "RARITY"), 
                  _getTier(id_,    seed_, "QUALITY"),
                  _getElement(id_, seed_, "ELEMENT")];

        uint256 boss = _getBossForId(id_);
        if (boss > 0) {
            traits[1] = 10 + boss;
            traits[4] = 0; // Quality is overriden
        } 
    }

    function _getSpecialTraits(uint256 seed_, uint256 id_) internal pure returns (uint256[6] memory t) {
        uint256 spc = id_ - _getRndForSpecial(seed_) + 1;
        
        uint256 traitIndcator = spc * 10 + spc;

        t = [traitIndcator,traitIndcator,traitIndcator,traitIndcator,traitIndcator,traitIndcator];
    }

    event log_named_uint(string key, uint256 val);


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

        if (rdn <= 75_0000) return 0;
        return (rdn % 5) + 1;
    }

    function _bossDropStart(uint256 boss) internal pure returns(uint256 start) {
        if (boss == 1) start = 10001;
        if (boss == 2) start = 11001;
        if (boss == 3) start = 11901;
        if (boss == 4) start = 12701;
        if (boss == 5) start = 13401;
        if (boss == 6) start = 14001;
        if (boss == 7) start = 14501;
        if (boss == 8) start = 14901;
        if (boss == 9) start = 15201;
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
        if (id > rdn && id <= rdn + 8) return true;
    }

    function _getSpecialCategory(uint256 id, uint256 seed) internal pure returns (uint256 spc) {
        uint256 num = id - _getRndForSpecial(seed);
        spc = num + 5 + (num - 1);
    }

    function _getCategory(uint256 id, uint256 seed) internal pure returns (uint256 cat) {
        // Boss Drop
        if (id > 10000) return cat = 4;
        if (_isSpecial(id, seed)) return _getSpecialCategory(id, seed);
        return 2;
    }

    function _getRndForSpecial(uint256 seed) internal pure returns (uint256 rdn) {
        rdn = uint256(keccak256(abi.encode(seed, "SPECIAL"))) % 9_992 + 1;
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

interface RendererLike {
    function getUri(uint256 id, uint256[6] calldata traits, uint256 cat) external view returns (string memory meta);
}

interface StatsLike {
    function getStats(uint256[6] calldata attributes) external view returns (bytes10[6] memory stats_); 
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.7;

/// @notice Modern and gas efficient ERC-721 + ERC-20/EIP-2612-like implementation,
/// Modified version inspired by ERC721A
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

    struct AddressData { uint128 balance; uint128 minted; }

    uint256 public totalSupply;
    
    mapping(address => bool)    public auth;

    mapping(address => AddressData) public datas;
    
    mapping(uint256 => address) public ownerOf;
        
    mapping(uint256 => address) public getApproved;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*///////////////////////////////////////////////////////////////
                             VIEW FUNCTION
    //////////////////////////////////////////////////////////////*/

    function owner() external view returns (address owner_) {
        return _owner();
    }

    function balanceOf(address add) external view returns(uint256 balance_) {
        balance_ = datas[add].balance;
    }

    function minted(address add) external view returns(uint256 minted_) {
        minted_ = datas[add].minted;
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

    function _mint(address to, uint256 tokenId) internal { 
        require(ownerOf[tokenId] == address(0), "ALREADY_MINTED");

        totalSupply++;
        
        // This is safe because the sum of all user
        // balances can't exceed type(uint256).max!
        unchecked {
            datas[to].balance++;
            datas[to].minted++;
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
        datas[owner_].minted--;
        
        delete ownerOf[tokenId];
                
        emit Transfer(owner_, address(0), tokenId); 
    }
}