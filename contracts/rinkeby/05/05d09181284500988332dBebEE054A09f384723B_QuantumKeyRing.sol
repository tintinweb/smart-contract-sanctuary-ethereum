// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import {ERC721 as ERC721S} from "@rari-capital/solmate/src/tokens/ERC721.sol";
import "@rari-capital/solmate/src/auth/Auth.sol";
import "@openzeppelin/contracts/utils/structs/BitMaps.sol";

//                                                   
//                                                   
//                                  XXXXXXX          
//                               X XXXX XXXXXX       
//                             XXSXSXXXXXX XXXXX     
//                             XXXXX XX  XXXXXSXX    
//                           XXXX  XXXS SSXX XXXX    
//                           XXX XXXX     XXXXXX X   
//                          XXXXXXX X      XXX XXX  
//                          XXXXXXXX       XXXXXXX   
//                           SXX XXXXX    XXXSXXSX   
//                           XXXXXXXXX XXXXXXXXXX    
//                          SXXX X XX XXXXXX XXX  
//                       XXXXXX X XXX X X XSXX   
//                      SXXXXX X XXSXXXXS XX     
//                    XSXSX  XXXXXX            
//                   SXXX XXX XXXXX                  
//                 XXXXX SXXXXXX                     
//                SXXS  X XXXXX                      
//              XXXXXX X XSX X                       
//            XSXXX XX XXXXX                         
//          XXSXSSX XXXXXX                        
//        XSXXXSXXXXXXXXX                       
//        XXXXX XXXXXX   

/// @title The Quantum Key Ring. The keys do something.
/// @author exp.table
contract QuantumKeyRing is ERC721S, Auth {

    using BitMaps for BitMaps.BitMap;

    /// >>>>>>>>>>>>>>>>>>>>>>>  STATE  <<<<<<<<<<<<<<<<<<<<<<<<<< ///

    uint private constant _SEPARATOR = 10**4;
    string private constant _baseURI = "ipfs://";
    address private _minter;
    mapping (uint256 => string) private _idToIPFS;
    mapping (uint256 => uint256) private _tokenIdToSkinIndex;
    mapping (uint256 => uint256) private _keySupply;
    BitMaps.BitMap private _isSkinRetired;

    /// @dev idx 0 should be the default skin
    string[] public skins;

    /// >>>>>>>>>>>>>>>>>>>>>  MODIFIERS  <<<<<<<<<<<<<<<<<<<<<< ///

    modifier indexExists(uint256 index) {
        require(index < skins.length, "INVALID IDX");
        _;
    }

    /// >>>>>>>>>>>>>>>>>>>>>  CONSTRUCTOR  <<<<<<<<<<<<<<<<<<<<<< ///

	/// @notice Deploys QuantumKeyRing
    /// @dev Initiates the Auth module with no authority and the sender as the owner
    /// @param owner The owner of the contract
    constructor(address owner, address authority) ERC721S("QuantumKeyRing", "QKR") Auth(owner, Authority(authority)) {}

    /// >>>>>>>>>>>>>>>>>>>>>  RESTRICTED  <<<<<<<<<<<<<<<<<<<<<< ///

    /// @notice set address of the minter
    /// @param minter The address of the minter - should be QuantumKeyMaker
    function setMinter(address minter) public requiresAuth {
        _minter = minter;
    }

    /// @notice push an IPFS CID for a skin
    /// @param cid The CID to set
    function addSkin(string calldata cid) public requiresAuth {
        skins.push(cid);
    }

    /// @notice Retires a skin - no longer available for use
    /// @param index index of the skin
    function retireSkin(uint256 index) public requiresAuth indexExists(index) {
        require(index > 0, "INVALID IDX");
        _isSkinRetired.set(index);
    }

    /// >>>>>>>>>>>>>>>>>>>>>  VIEW  <<<<<<<<<<<<<<<<<<<<<< ///

    /// @notice Returns the URI of the token
    /// @param tokenId id of the token
    /// @return URI for the token ; expected to be ipfs://<cid>
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        return string(abi.encodePacked(_baseURI, skins[_tokenIdToSkinIndex[tokenId]]));
    }

    /// @notice Returns whether the skin is retired or not
    /// @param index index of the skin
    /// @return boolean
    function isSkinRetired(uint256 index) public indexExists(index) view returns (bool) {
        return _isSkinRetired.get(index);
    }

    /// >>>>>>>>>>>>>>>>>>>>>  EXTERNAL  <<<<<<<<<<<<<<<<<<<<<< ///

    /// @notice Mints new keys
    /// @dev there is no check regarding limiting supply
    /// @param to recipient of newly minted tokens
    /// @param keyId id of the key
    /// @param amount amount to mint
    function make(address to, uint256 keyId, uint256 amount) public {
        require(msg.sender == owner || msg.sender == _minter, "NOT_AUTHORIZED");
        _keySupply[keyId] += amount;
        for(uint i = 0; i < amount; i++) {
            _safeMint(to, (keyId * _SEPARATOR) +  _keySupply[keyId] - i - 1);
        }

    }

    /// @notice Burns key
    /// @dev Can be called by the owner or approved operator
    /// @param tokenId id of the tokens
    function burn(uint256 tokenId) public {
        address owner = ownerOf[tokenId];
        require(
            msg.sender == owner || msg.sender == getApproved[tokenId] || isApprovedForAll[owner][msg.sender],
            "NOT_AUTHORIZED"
        );
        _burn(tokenId);
    }

    /// @notice Applies a skin to a key
    /// @param tokenId id of the key
    /// @param index index of the skin
    function applySkin(uint256 tokenId, uint256 index) public indexExists(index) {
        require(ownerOf[tokenId] == msg.sender, "!OWNER");
        require(!_isSkinRetired.get(index), "RETIRED");
        _tokenIdToSkinIndex[tokenId] = index;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
/// @dev Note that balanceOf does not revert if passed the zero address, in defiance of the ERC.
abstract contract ERC721 {
    /*///////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    event Approval(address indexed owner, address indexed spender, uint256 indexed id);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /*///////////////////////////////////////////////////////////////
                          METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    function tokenURI(uint256 id) public view virtual returns (string memory);

    /*///////////////////////////////////////////////////////////////
                            ERC721 STORAGE                        
    //////////////////////////////////////////////////////////////*/

    mapping(address => uint256) public balanceOf;

    mapping(uint256 => address) public ownerOf;

    mapping(uint256 => address) public getApproved;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*///////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    /*///////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 id) public virtual {
        address owner = ownerOf[id];

        require(msg.sender == owner || isApprovedForAll[owner][msg.sender], "NOT_AUTHORIZED");

        getApproved[id] = spender;

        emit Approval(owner, spender, id);
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        require(from == ownerOf[id], "WRONG_FROM");

        require(to != address(0), "INVALID_RECIPIENT");

        require(
            msg.sender == from || msg.sender == getApproved[id] || isApprovedForAll[from][msg.sender],
            "NOT_AUTHORIZED"
        );

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            balanceOf[from]--;

            balanceOf[to]++;
        }

        ownerOf[id] = to;

        delete getApproved[id];

        emit Transfer(from, to, id);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes memory data
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    /*///////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public pure virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /*///////////////////////////////////////////////////////////////
                       INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 id) internal virtual {
        require(to != address(0), "INVALID_RECIPIENT");

        require(ownerOf[id] == address(0), "ALREADY_MINTED");

        // Counter overflow is incredibly unrealistic.
        unchecked {
            balanceOf[to]++;
        }

        ownerOf[id] = to;

        emit Transfer(address(0), to, id);
    }

    function _burn(uint256 id) internal virtual {
        address owner = ownerOf[id];

        require(ownerOf[id] != address(0), "NOT_MINTED");

        // Ownership check above ensures no underflow.
        unchecked {
            balanceOf[owner]--;
        }

        delete ownerOf[id];

        delete getApproved[id];

        emit Transfer(owner, address(0), id);
    }

    /*///////////////////////////////////////////////////////////////
                       INTERNAL SAFE MINT LOGIC
    //////////////////////////////////////////////////////////////*/

    function _safeMint(address to, uint256 id) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _safeMint(
        address to,
        uint256 id,
        bytes memory data
    ) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }
}

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
interface ERC721TokenReceiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 id,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Provides a flexible and updatable auth pattern which is completely separate from application logic.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/auth/Auth.sol)
/// @author Modified from Dappsys (https://github.com/dapphub/ds-auth/blob/master/src/auth.sol)
abstract contract Auth {
    event OwnerUpdated(address indexed user, address indexed newOwner);

    event AuthorityUpdated(address indexed user, Authority indexed newAuthority);

    address public owner;

    Authority public authority;

    constructor(address _owner, Authority _authority) {
        owner = _owner;
        authority = _authority;

        emit OwnerUpdated(msg.sender, _owner);
        emit AuthorityUpdated(msg.sender, _authority);
    }

    modifier requiresAuth() {
        require(isAuthorized(msg.sender, msg.sig), "UNAUTHORIZED");

        _;
    }

    function isAuthorized(address user, bytes4 functionSig) internal view virtual returns (bool) {
        Authority auth = authority; // Memoizing authority saves us a warm SLOAD, around 100 gas.

        // Checking if the caller is the owner only after calling the authority saves gas in most cases, but be
        // aware that this makes protected functions uncallable even to the owner if the authority is out of order.
        return (address(auth) != address(0) && auth.canCall(user, address(this), functionSig)) || user == owner;
    }

    function setAuthority(Authority newAuthority) public virtual {
        // We check if the caller is the owner first because we want to ensure they can
        // always swap out the authority even if it's reverting or using up a lot of gas.
        require(msg.sender == owner || authority.canCall(msg.sender, address(this), msg.sig));

        authority = newAuthority;

        emit AuthorityUpdated(msg.sender, newAuthority);
    }

    function setOwner(address newOwner) public virtual requiresAuth {
        owner = newOwner;

        emit OwnerUpdated(msg.sender, newOwner);
    }
}

/// @notice A generic interface for a contract which provides authorization data to an Auth instance.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/auth/Auth.sol)
/// @author Modified from Dappsys (https://github.com/dapphub/ds-auth/blob/master/src/auth.sol)
interface Authority {
    function canCall(
        address user,
        address target,
        bytes4 functionSig
    ) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/structs/BitMaps.sol)
pragma solidity ^0.8.0;

/**
 * @dev Library for managing uint256 to bool mapping in a compact and efficient way, providing the keys are sequential.
 * Largelly inspired by Uniswap's https://github.com/Uniswap/merkle-distributor/blob/master/contracts/MerkleDistributor.sol[merkle-distributor].
 */
library BitMaps {
    struct BitMap {
        mapping(uint256 => uint256) _data;
    }

    /**
     * @dev Returns whether the bit at `index` is set.
     */
    function get(BitMap storage bitmap, uint256 index) internal view returns (bool) {
        uint256 bucket = index >> 8;
        uint256 mask = 1 << (index & 0xff);
        return bitmap._data[bucket] & mask != 0;
    }

    /**
     * @dev Sets the bit at `index` to the boolean `value`.
     */
    function setTo(
        BitMap storage bitmap,
        uint256 index,
        bool value
    ) internal {
        if (value) {
            set(bitmap, index);
        } else {
            unset(bitmap, index);
        }
    }

    /**
     * @dev Sets the bit at `index`.
     */
    function set(BitMap storage bitmap, uint256 index) internal {
        uint256 bucket = index >> 8;
        uint256 mask = 1 << (index & 0xff);
        bitmap._data[bucket] |= mask;
    }

    /**
     * @dev Unsets the bit at `index`.
     */
    function unset(BitMap storage bitmap, uint256 index) internal {
        uint256 bucket = index >> 8;
        uint256 mask = 1 << (index & 0xff);
        bitmap._data[bucket] &= ~mask;
    }
}