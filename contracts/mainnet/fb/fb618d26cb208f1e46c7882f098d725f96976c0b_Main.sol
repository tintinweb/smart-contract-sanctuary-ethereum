// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Simple single owner authorization mixin.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/auth/Owned.sol)
abstract contract Owned {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnershipTransferred(address indexed user, address indexed newOwner);

    /*//////////////////////////////////////////////////////////////
                            OWNERSHIP STORAGE
    //////////////////////////////////////////////////////////////*/

    address public owner;

    modifier onlyOwner() virtual {
        require(msg.sender == owner, "UNAUTHORIZED");

        _;
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _owner) {
        owner = _owner;

        emit OwnershipTransferred(address(0), _owner);
    }

    /*//////////////////////////////////////////////////////////////
                             OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

    function transferOwnership(address newOwner) public virtual onlyOwner {
        owner = newOwner;

        emit OwnershipTransferred(msg.sender, newOwner);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Minimalist and gas efficient standard ERC1155 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC1155.sol)
abstract contract ERC1155 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 amount
    );

    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] amounts
    );

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    event URI(string value, uint256 indexed id);

    /*//////////////////////////////////////////////////////////////
                             ERC1155 STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(address => mapping(uint256 => uint256)) public balanceOf;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*//////////////////////////////////////////////////////////////
                             METADATA LOGIC
    //////////////////////////////////////////////////////////////*/

    function uri(uint256 id) public view virtual returns (string memory);

    /*//////////////////////////////////////////////////////////////
                              ERC1155 LOGIC
    //////////////////////////////////////////////////////////////*/

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) public virtual {
        require(msg.sender == from || isApprovedForAll[from][msg.sender], "NOT_AUTHORIZED");

        balanceOf[from][id] -= amount;
        balanceOf[to][id] += amount;

        emit TransferSingle(msg.sender, from, to, id, amount);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155Received(msg.sender, from, id, amount, data) ==
                    ERC1155TokenReceiver.onERC1155Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) public virtual {
        require(ids.length == amounts.length, "LENGTH_MISMATCH");

        require(msg.sender == from || isApprovedForAll[from][msg.sender], "NOT_AUTHORIZED");

        // Storing these outside the loop saves ~15 gas per iteration.
        uint256 id;
        uint256 amount;

        for (uint256 i = 0; i < ids.length; ) {
            id = ids[i];
            amount = amounts[i];

            balanceOf[from][id] -= amount;
            balanceOf[to][id] += amount;

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, from, to, ids, amounts);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155BatchReceived(msg.sender, from, ids, amounts, data) ==
                    ERC1155TokenReceiver.onERC1155BatchReceived.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function balanceOfBatch(address[] calldata owners, uint256[] calldata ids)
        public
        view
        virtual
        returns (uint256[] memory balances)
    {
        require(owners.length == ids.length, "LENGTH_MISMATCH");

        balances = new uint256[](owners.length);

        // Unchecked because the only math done is incrementing
        // the array index counter which cannot possibly overflow.
        unchecked {
            for (uint256 i = 0; i < owners.length; ++i) {
                balances[i] = balanceOf[owners[i]][ids[i]];
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0xd9b67a26 || // ERC165 Interface ID for ERC1155
            interfaceId == 0x0e89341c; // ERC165 Interface ID for ERC1155MetadataURI
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        balanceOf[to][id] += amount;

        emit TransferSingle(msg.sender, address(0), to, id, amount);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155Received(msg.sender, address(0), id, amount, data) ==
                    ERC1155TokenReceiver.onERC1155Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _batchMint(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        uint256 idsLength = ids.length; // Saves MLOADs.

        require(idsLength == amounts.length, "LENGTH_MISMATCH");

        for (uint256 i = 0; i < idsLength; ) {
            balanceOf[to][ids[i]] += amounts[i];

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, address(0), to, ids, amounts);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155BatchReceived(msg.sender, address(0), ids, amounts, data) ==
                    ERC1155TokenReceiver.onERC1155BatchReceived.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _batchBurn(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        uint256 idsLength = ids.length; // Saves MLOADs.

        require(idsLength == amounts.length, "LENGTH_MISMATCH");

        for (uint256 i = 0; i < idsLength; ) {
            balanceOf[from][ids[i]] -= amounts[i];

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, from, address(0), ids, amounts);
    }

    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        balanceOf[from][id] -= amount;

        emit TransferSingle(msg.sender, from, address(0), id, amount);
    }
}

/// @notice A generic interface for a contract which properly accepts ERC1155 tokens.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC1155.sol)
abstract contract ERC1155TokenReceiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC1155TokenReceiver.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC1155TokenReceiver.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    event Approval(address indexed owner, address indexed spender, uint256 indexed id);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /*//////////////////////////////////////////////////////////////
                         METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    function tokenURI(uint256 id) public view virtual returns (string memory);

    /*//////////////////////////////////////////////////////////////
                      ERC721 BALANCE/OWNER STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) internal _ownerOf;

    mapping(address => uint256) internal _balanceOf;

    function ownerOf(uint256 id) public view virtual returns (address owner) {
        require((owner = _ownerOf[id]) != address(0), "NOT_MINTED");
    }

    function balanceOf(address owner) public view virtual returns (uint256) {
        require(owner != address(0), "ZERO_ADDRESS");

        return _balanceOf[owner];
    }

    /*//////////////////////////////////////////////////////////////
                         ERC721 APPROVAL STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) public getApproved;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    /*//////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 id) public virtual {
        address owner = _ownerOf[id];

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
        require(from == _ownerOf[id], "WRONG_FROM");

        require(to != address(0), "INVALID_RECIPIENT");

        require(
            msg.sender == from || isApprovedForAll[from][msg.sender] || msg.sender == getApproved[id],
            "NOT_AUTHORIZED"
        );

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            _balanceOf[from]--;

            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

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
        bytes calldata data
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 id) internal virtual {
        require(to != address(0), "INVALID_RECIPIENT");

        require(_ownerOf[id] == address(0), "ALREADY_MINTED");

        // Counter overflow is incredibly unrealistic.
        unchecked {
            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        emit Transfer(address(0), to, id);
    }

    function _burn(uint256 id) internal virtual {
        address owner = _ownerOf[id];

        require(owner != address(0), "NOT_MINTED");

        // Ownership check above ensures no underflow.
        unchecked {
            _balanceOf[owner]--;
        }

        delete _ownerOf[id];

        delete getApproved[id];

        emit Transfer(owner, address(0), id);
    }

    /*//////////////////////////////////////////////////////////////
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
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721TokenReceiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC721TokenReceiver.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @notice Efficient library for creating string representations of integers.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/LibString.sol)
/// @author Modified from Solady (https://github.com/Vectorized/solady/blob/main/src/utils/LibString.sol)
library LibString {
    function toString(uint256 value) internal pure returns (string memory str) {
        /// @solidity memory-safe-assembly
        assembly {
            // The maximum value of a uint256 contains 78 digits (1 byte per digit), but we allocate 160 bytes
            // to keep the free memory pointer word aligned. We'll need 1 word for the length, 1 word for the
            // trailing zeros padding, and 3 other words for a max of 78 digits. In total: 5 * 32 = 160 bytes.
            let newFreeMemoryPointer := add(mload(0x40), 160)

            // Update the free memory pointer to avoid overriding our string.
            mstore(0x40, newFreeMemoryPointer)

            // Assign str to the end of the zone of newly allocated memory.
            str := sub(newFreeMemoryPointer, 32)

            // Clean the last word of memory it may not be overwritten.
            mstore(str, 0)

            // Cache the end of the memory to calculate the length later.
            let end := str

            // We write the string from rightmost digit to leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            // prettier-ignore
            for { let temp := value } 1 {} {
                // Move the pointer 1 byte to the left.
                str := sub(str, 1)

                // Write the character to the pointer.
                // The ASCII index of the '0' character is 48.
                mstore8(str, add(48, mod(temp, 10)))

                // Keep dividing temp until zero.
                temp := div(temp, 10)

                 // prettier-ignore
                if iszero(temp) { break }
            }

            // Compute and cache the final total length of the string.
            let length := sub(end, str)

            // Move the pointer 32 bytes leftwards to make room for the length.
            str := sub(str, 32)

            // Store the string's length at the start of memory allocated for our string.
            mstore(str, length)
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ERC1155} from "solmate/tokens/ERC1155.sol";
import {Owned} from "solmate/auth/Owned.sol";
import {Main} from "./Main.sol";

/** 
@title Mailbomb
@author lzamenace.eth
@notice This contract contains ERC-1155 Mailbomb tokens (BOMB) which are used as
utility tokens for the Unaboomer NFT project and chain based game.
Mailbombs can be delivered to other players to "kill" tokens they hold, which 
toggles the image to a dead / exploded image, and burns the underlying BOMB token. 
@dev All contract functions regarding token burning and minting are limited to 
the Main interface where the logic and validation resides.
*/
contract Mailbomb is ERC1155, Owned {

    /// Track the total number of bombs assembled (tokens minted)
    uint256 public bombsAssembled;
    /// Track the number of bombs that have exploded (been burned)
    uint256 public bombsExploded;
    /// Base URI for the bomb image - all bombs use the same image
    string public baseURI;
    /// Contract address of the deployed Main contract interface to the game
    Main public main;

    constructor() ERC1155() Owned(msg.sender) {}

    // =========================================================================
    //                              Admin
    // =========================================================================

    /// Set metadata URI for all BOMB (token 1)
    /// @param _baseURI IPFS hash or URL to retrieve JSON metadata
    function setBaseURI(string calldata _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    /// Set main contract address for executing functions
    /// @param _address Contract address of the deployed Main contract
    function setMainContract(address _address) external onlyOwner {
        main = Main(_address);
    }

    // =========================================================================
    //                              Modifiers
    // =========================================================================

    /// Limit function execution to deployed Main contract
    modifier onlyMain {
        require(msg.sender == address(main), "invalid msg sender");
        _;
    }

    // =========================================================================
    //                              Tokens
    // =========================================================================

    /// Mint tokens from main contract
    /// @param _to Address to mint BOMB tokens to
    /// @param _amount Amount of BOMB tokens to mint
    function create(address _to, uint256 _amount) external onlyMain {
        bombsAssembled += _amount;
        super._mint(_to, 1, _amount, "");
    }

    /// Burn spent tokens from main contract
    /// @param _from Address to burn BOMB tokens from
    /// @param _amount Amount of BOMB tokens to burn
    function explode(address _from, uint256 _amount) external onlyMain {
        bombsExploded += _amount;
        super._burn(_from, 1, _amount);
    }

    /// Get the total amount of bombs that have been assembled (minted)
    /// @return supply Number of bombs assembled in totality (minted)
    function totalSupply() public view returns (uint256 supply) {
        return bombsAssembled;
    }

    /// Return URI to retrieve JSON metadata from - points to images and descriptions
    /// @param _tokenId Unused as all bombs point to same metadata URI
    /// @return string IPFS or HTTP URI to retrieve JSON metadata from
    function uri(uint256 _tokenId) public view override returns (string memory) {
        return baseURI;
    }

    /// Checks if contract supports a given interface
    /// @param interfaceId The interface ID to check if contract supports
    /// @return bool Boolean value if contract supports interface ID or not
    function supportsInterface(bytes4 interfaceId) public view virtual override (ERC1155) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

//                                     ___ooo_..._.                                         
//                                 .___.  o_      __.                                       
//                             ._.._   ._o.         ..o_.                                   
//                         _oo_...._._.              .._.                                 
//                     __..      o.   ._               __                                
//                     ._..       .o.....                  .o.                              
//                 .o.     ....___.                        __.                            
//                 __.     .... _o                             __.                          
//             __       ..._.______..                   .__   _x_.                       
//             __      .....   ..._ooxo__..                .__.  oo.                      
//             o. .      .__ooo_.    ..__oxo__.              ..oo_xo                      
//             ._...  ._oxxxxxoxxxx__.       ______._..          .oxx_                     
//             __.  .oxx_ooo__oxo.xooxoo___.         .___          .oo                     
//             __  _o__o_._.____o ____.oo_.oxx___.       .           .oo.                   
//         ._. _oxoo_.o_ .x   o_....____. .xxoxx__.        ._        _o                   
//         ._o._oxx_.o..o_ _xo  oo.._. o.    .x..o_xo__      .x_        __                  
//     __._oxxo__.o..o.  __o_. .o.  o_o   o_o .._o_ox__    .oo.       __                 
//     .o _xxxxo_  _o.oo_..._o___.._x__xoox_.___. ...ooxx_    oo_       _.                
//     o _xxxxxo.......__.........     .._oooooo____.....___   .oo_     ..                
//     _. _xxxxxo.._ooxxxxxxxxxxxxx_..__xxxxxxxxxxxxxxxxxx__.__   .o_                      
//     _..oxxxxo._xooxxxxxxxxxxxxxxx.  _xo   ..oxxxxxxxxxxxxx._x_   .x.                    
//     _..xxxxxxox..  ._.oxxxxxxxxxo...._xo.    ...oxxxxxxxxxx.xxo   .o.                   
//     _..xxxxxxxxxx_.._xxxxxxxxxxo._..___xxo__oxxxxxxxxxxxxxx.xxx    _.                   
//     _..xxoxxxxxxxxxxxxxxxxxxxxx o.   o_.xxxxxxxxxxxxxxxxxx_ xxx    _.                   
//     _o.ox .xxoxxxxxxxxxxxxxxxx.__.   ox_.oxxxxxxxxxxxxxxx_  xxx_  .o.                   
//     .._xo ox_ _xxxxxxxxxxxx_..._.  _ooo_._oxxxxxxxxxxxx_...xoxo  ._   ..               
//     .._o.._o. ._oxxxxxx___...o_   .  ._..._ooxxxxxxo_..o o..ox.  _.  .o               
//         _.xxo.o_ ...._oo_... .o._         __ _..._oo_..__. ._.oxxo  .o  __               
//         xxx._x    .....   _oo.oo_..._o_.__     .....  ._ _xxxxxo     .o.               
//         xxx._x           _..ox_oxxxxxxxxxx_         .ox. _xxxxxo     .x.               
//         o.o_.x_       ...  .. . _oo_ _oxxo_..       oxx. _xxxxo.   oo _.               
//         .o.oooo      ._ .__ ..__o._..___.___.      .xxx. _xxo.    ox_._                
//             .xxxo       .x__._.______...____.__     _xx_ .ox.   .oox_ o.                
//             .xxx_       _..    .......____._ _    .oxo..oo   .oxxxo  o                 
//             _._xx_.            .._o_.            _xo_.oxo   _xxxxx_ _.                 
//             .o_.oxx_.        ._________        .oo_.oxx_   oxxxo__ ._                  
//                 __ _xxx_                       .oo_.oxxx_   _xo_ ._oo_                   
//                 ._ .oxxx_.                  .oo__oxxxo.   ._  _oxxo.                    
//                 __  _xx___              .____.oxxo_. __    .xxxxo                      
//                 __  oxx _o_.  ........__..ooxo_. ___.   ._xxxooxo_..                  
//                 ._xoo_xx_  _ox__________oxxx_. .__.    ..oxxxx_.  ._oo_.               
//             ......_o__o_xox_  .o__...oxxxxxo__._oo______oxxxxxo_.__..  ..___.            
//         ...... .___   .o_.ox_         oxxo. .o oxxxxxxooooooo_.     ___.   ..__.         
// ._....   ._._       o_. .o_  _.  .oxo__oxx_.oo__                    .__.    ._..      
// ...     .._.          o_.   __.xxxoo__xxo__o _.                          ._.    .._.    
//         ..             o_.    .o._ooo__.   o__.                                          
//                     o_.    .._.o.      _.__                                           
//                     o_.    ..x_o.      o o                                            

import {Owned} from "solmate/auth/Owned.sol";
import {Unaboomer} from "./Unaboomer.sol";
import {Mailbomb} from "./Mailbomb.sol";

/** 
@title UnaboomerNFT
@author lzamenace.eth
@notice This is the main contract interface for the Unaboomer NFT project drop and chain based game.
It contains the logic between an ERC-721 contract containing Unaboomer tokens (pixelated Unabomber 
inspired profile pictures) and an ERC-1155 contract containing Mailbomb tokens (utility tokens).
Unaboomer is a chain based game with some mechanics based around "killing" other players by sending 
them mailbombs until a certain amount of players or "survivors" remain. The motif was inspired by 
the real life story of Theodore Kaczynski, known as the Unabomber, who conducted a nationwide 
mail bombing campaign against people he believed to be advancing modern technology and the 
destruction of the environment. Ironic, isn't it? 
*/
contract Main is Owned {

    /// Track the number of kills for each address
    mapping(address => uint256) public killCount;
    /// Index addresses to form a basic leaderboard
    mapping(uint256 => address) public leaderboard;
    /// Point to the latest leaderboard update
    uint256 public leaderboardPointer;
    /// Price of the Unaboomer ERC-721 token
    uint256 public unaboomerPrice = 0.005 ether;
    /// Price of the Mailbomb ERC-1155 token
    uint256 public bombPrice = 0.0025 ether;
    /// If mail bombs can be sent by players
    bool public mayhem;
    /// Unaboomer contract
    Unaboomer public unaboomer;
    /// Mailbomb contract
    Mailbomb public mailbomb;

    /// SentBomb event is for recording the results of sendBombs for real-time feedback to a frontend interface
    /// @param from Sender of the bombs
    /// @param tokenId Unaboomer token which was targeted
    /// @param hit Whether or not the bomb killed the token or not (was a dud / already killed)
    /// @param owned Whether or not the sender was the owner of the BOOMER token
    event SentBomb(address indexed from, uint256 indexed tokenId, bool hit, bool owned);

    constructor() Owned(msg.sender) {}

    // =========================================================================
    //                              Admin
    // =========================================================================

    /// Withdraw funds to contract owner
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        (bool success, ) = payable(msg.sender).call{value: balance}("");
        require(success, "failed to withdraw");
    }

    /// Set price per BOOMER
    /// @param _price Price in wei to mint BOOMER token
    function setBoomerPrice(uint256 _price) external onlyOwner {
        unaboomerPrice = _price;
    }

    /// Set price per BOMB
    /// @param _price Price in wei to mint BOMB token
    function setBombPrice(uint256 _price) external onlyOwner {
        bombPrice = _price;
    }

    /// Set contract address for Unaboomer tokens
    /// @param _address Address of the Unaboomer / BOOMER contract
    function setUnaboomerContract(address _address) external onlyOwner {
        unaboomer = Unaboomer(_address);
    }

    /// Set contract address for Mailbomb tokens
    /// @param _address Address of the Mailbomb / BOMB contract
    function setMailbombContract(address _address) external onlyOwner {
        mailbomb = Mailbomb(_address);
    }

    /// Toggle mayhem switch to enable mail bomb sending
    function toggleMayhem() external onlyOwner {
        mayhem = !mayhem;
    }

    // =========================================================================
    //                              Modifiers
    // =========================================================================

    /// This modifier prevents actions once the Unaboomer survivor count is breached.
    /// The game stops; no more bombing/killing. Survivors make it to the next round.
    modifier missionNotCompleted {
        require(
            unaboomer.burned() < (unaboomer.MAX_SUPPLY() - unaboomer.MAX_SURVIVOR_COUNT()), 
            "mission already completed"
        );
        _;
    }

    // =========================================================================
    //                              Getters
    // =========================================================================

    /// Get BOOMER token balance of wallet 
    /// @param _address Wallet address to query balance of BOOMER token
    /// @return balance Amount of BOOMER tokens owned by _address
    function unaboomerBalance(address _address) public view returns (uint256) {
        return unaboomer.balanceOf(_address);
    }

    /// Get BOOMER amount minted (including ones that have been burned/killed)
    /// @param _address Wallet address to query the amount of BOOMER token minted
    /// @return balance Amount of BOOMER tokens that have been minted by _address
    function unaboomersMinted(address _address) public view returns (uint256) {
        return unaboomer.tokensMintedByWallet(_address);
    }

    /// Get BOOMER token total supply
    /// @return supply Amount of BOOMER tokens minted in total
    function unaboomersRadicalized() public view returns (uint256) {
        return unaboomer.minted();
    }

    /// Get BOOMER kill count (unaboomers killed)
    /// @return killCount Amount of BOOMER tokens "killed" (dead pfp)
    function unaboomersKilled() public view returns (uint256) {
        return unaboomer.burned();
    }

    /// Get BOOMER token max supply
    /// @return maxSupply Maximum amount of BOOMER tokens that can ever exist
    function unaboomerMaxSupply() public view returns (uint256) {
        return unaboomer.MAX_SUPPLY();
    }

    /// Get BOOMER token survivor count
    /// @return survivorCount Maximum amount of BOOMER survivor tokens that can ever exist
    function unaboomerMaxSurvivorCount() public view returns (uint256) {
        return unaboomer.MAX_SURVIVOR_COUNT();
    }

    /// Get BOOMER token max mint amount per wallet
    /// @return mintAmount Maximum amount of BOOMER tokens that can be minted per wallet
    function unaboomerMaxMintPerWallet() public view returns (uint256) {
        return unaboomer.MAX_MINT_AMOUNT();
    }

    /// Get BOMB token balance of wallet
    /// @param _address Wallet address to query balance of BOMB token
    /// @return balance Amount of BOMB tokens owned by _address
    function bombBalance(address _address) public view returns (uint256) {
        return mailbomb.balanceOf(_address, 1);
    }

    /// Get BOMB token supply
    /// @return supply Amount of BOMB tokens ever minted / "assembled"
    function bombsAssembled() public view returns (uint256) {
        return mailbomb.bombsAssembled();
    }

    /// Get BOMB exploded amount
    /// @return exploded Amount of BOMB tokens that have burned / "exploded"
    function bombsExploded() public view returns (uint256) {
        return mailbomb.bombsExploded();
    }

    // =========================================================================
    //                              Tokens
    // =========================================================================

    /// Radicalize a boomer to become a Unaboomer - start with 1 bomb
    /// @param _amount Amount of Unaboomers to mint / "radicalize"
    function radicalizeBoomers(uint256 _amount) external payable missionNotCompleted {
        require(msg.value >= _amount * unaboomerPrice, "not enough ether");
        unaboomer.radicalize(msg.sender, _amount);
        mailbomb.create(msg.sender, _amount);
    }

    /// Assemble additional mailbombs to kill targets
    /// @param _amount Amount of bombs mint / "assemble"
    function assembleBombs(uint256 _amount) external payable missionNotCompleted {
        require(msg.value >= _amount * bombPrice, "not enough ether");
        mailbomb.create(msg.sender, _amount);
    }

    /// Send N bombs to pseudo-random Unaboomer tokenIds to kill them.
    /// If the Unaboomer is already dead, the bomb is considered a dud.
    /// Update a leaderboard with updated kill counts.
    /// @dev Pick a pseudo-random tokenID from Unaboomer contract and toggle a mapping value  
    /// @dev The likelihood of killing a boomer decreases as time goes on - i.e. more duds
    /// @param _amount Amount of bombs to send to kill Unaboomers (dead pfps)
    function sendBombs(uint256 _amount) external missionNotCompleted {
        // Require mayhem is set (allow time to mint and trade)
        require(mayhem, "not ready for mayhem");
        // Ensure _amount will not exceed wallet balance of bombs, Unaboomer supply, and active Unaboomers
        uint256 supply = unaboomersRadicalized();
        uint256 bal = bombBalance(msg.sender);
        require(_amount <= bal, "not enough bombs");
        for (uint256 i; i < _amount; i++) {
            // Pick a pseudo-random Unaboomer token - imperfectly derives token IDs so that repeats are probable
            uint256 randomBoomer = (uint256(keccak256(abi.encodePacked(i, supply, bal, msg.sender))) % supply) + 1;
            // Capture owner
            address _owner = unaboomer.ownerOf(randomBoomer);
            // Check if it was already killed
            bool dud = _owner == address(0);
            // Check if the sender owns it (misfired, killed own pfp)
            bool senderOwned = msg.sender == _owner;
            // Kill it (does nothing if already toggled as dead)
            unaboomer.die(randomBoomer);
            // Emit event for displaying in web app
            emit SentBomb(msg.sender, randomBoomer, !dud, senderOwned);
            // Increment kill count if successfully killed another player's Unaboomer
            if(!dud && !senderOwned) {
                killCount[msg.sender]++;
            }
        }
        // Update the leaderboard and pointer for tracking the highest amount of kills for wallets
        uint256 kills = killCount[msg.sender];
        address leader = leaderboard[leaderboardPointer];
        if (kills > killCount[leader]) {
            if (leader != msg.sender) {
                leaderboardPointer++;
                leaderboard[leaderboardPointer] = msg.sender;
            }
        }
        // Burn ERC-1155 BOMB tokens (bombs go away after sending / exploding)
        mailbomb.explode(msg.sender, _amount);
    }

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ERC721} from "solmate/tokens/ERC721.sol";
import {Owned} from "solmate/auth/Owned.sol";
import {LibString} from "solmate/utils/LibString.sol";
import {Main} from "./Main.sol";

/** 
@title Unaboomer
@author lzamenace.eth
@notice This contract contains ERC-721 Unaboomer tokens (BOOMER) which are the profile 
picture and membership tokens for the Unaboomer NFT project and chain based game.
Each Unaboomer is a unique, dynamically generated pixel avatar in the likeness
of the real-life Unabomber, Theodore Kaczynski. Unaboomers can be "killed" by
other players by "sending" (burning) mailbombs. When Unaboomers are killed their
corresponding image is replaced with an explosion, rendering it worthless as any
rarity associated with it ceases to exist. The game stops when MAX_SURVIVOR_COUNT
threshold is breached. The surviving players (any address which holds an "alive"
Unaboomer) will advance to the next round of gameplay.
@dev All contract functions regarding token burning and minting are limited to 
the Main interface where the logic and validation resides.
*/
contract Unaboomer is ERC721, Owned {
    using LibString for uint256;

    /// Track mints per wallet to enforce maximum
    mapping(address => uint256) public tokensMintedByWallet;
    /// Maximum supply of BOOMER tokens
    uint256 public constant MAX_SUPPLY = 5000;
    /// Maximum amount of survivors remaining to advance to the next round
    uint256 public constant MAX_SURVIVOR_COUNT = 1000;
    /// Maximum amount of mints per wallet - cut down on botters
    uint256 public constant MAX_MINT_AMOUNT = 25;
    /// Amount of Unaboomers killed (tokens burned)
    uint256 public burned;
    /// Amount of Unaboomers radicalized (tokens minted)
    uint256 public minted;
    /// Base URI for Unaboomers - original pixelated avatars and pixelated explosions
    string public baseURI;
    /// Contract address of the deployed Main contract interface to the game
    Main public main;

    constructor() ERC721("Unaboomer", "BOOMER") Owned(msg.sender) {}

    // =========================================================================
    //                              Admin
    // =========================================================================

    /// Set metadata URI for Unaboomer PFPs and explosions
    /// @param _baseURI IPFS hash or URL to retrieve JSON metadata for living Unaboomer tokens
    function setBaseURI(string calldata _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    /// Set main contract address for executing functions
    /// @param _address Contract address of the deployed Main contract
    function setMainContract(address _address) external onlyOwner {
        main = Main(_address);
    }

    // =========================================================================
    //                              Modifiers
    // =========================================================================
    
    /// Limit function execution to deployed Main contract
    modifier onlyMain {
        require(msg.sender == address(main), "invalid msg sender");
        _;
    }

    // =========================================================================
    //                              Tokens
    // =========================================================================

    /// Helper function to get supply minted
    /// @return supply Number of Unaboomers radicalized in totality (minted)
    function totalSupply() public view returns (uint256) {
        return minted - burned;
    }

    /// Mint tokens from main contract
    /// @param _to Address to mint BOOMER tokens to
    /// @param _amount Amount of BOOMER tokens to mint
    function radicalize(address _to, uint256 _amount) external onlyMain {
        require(minted + _amount <= MAX_SUPPLY, "supply reached");
        require(tokensMintedByWallet[_to] + _amount <= MAX_MINT_AMOUNT, "cannot exceed maximum per wallet");
        for (uint256 i; i < _amount; i++) {
            minted++;
            _safeMint(_to, minted);
        }
        tokensMintedByWallet[_to] += _amount;
    }

    /// Toggle token state from living to dead
    /// @param _tokenId Token ID of BOOMER to toggle living -> dead and increment kill count
    function die(uint256 _tokenId) external onlyMain {
        require(_tokenId <= minted, "invalid token id");
        if (ownerOf(_tokenId) != address(0)) {
            burned++;
            _burn(_tokenId);
        }
    }

    /// Retrieve owner of given token ID
    /// @param _tokenId Token ID to check owner of
    /// @return owner Address of owner
    /// @dev Overridden from Solmate contract to allow zero address returns 
    function ownerOf(uint256 _tokenId) public view override returns (address owner) {
        return _ownerOf[_tokenId];
    }

    // Return URI to retrieve JSON metadata from - points to images and descriptions
    /// @param _tokenId Token ID of BOOMER to fetch URI for
    /// @return string IPFS or HTTP URI to retrieve JSON metadata from
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        if (ownerOf(_tokenId) == address(0)) {
            return string(abi.encodePacked(baseURI, "dead.json"));
        } else {
            return string(abi.encodePacked(baseURI, _tokenId.toString(), ".json"));
        }
    }

    /// Checks if contract supports a given interface
    /// @param interfaceId The interface ID to check if contract supports
    /// @return bool Boolean value if contract supports interface ID or not
    function supportsInterface(bytes4 interfaceId) public view virtual override (ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}