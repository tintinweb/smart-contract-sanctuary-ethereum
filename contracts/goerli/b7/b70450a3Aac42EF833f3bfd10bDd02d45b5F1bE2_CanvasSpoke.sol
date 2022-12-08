// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.17;

import "../../Spoke.sol";

interface Renderer {
    function renderSVG() external view returns (string memory);

    function tokenURI(uint256 tokenId) external view returns (string memory);
}

contract CanvasSpoke is Spoke {
    // 16 x 16 grid = 256 pixels
    // [uint8, uint8, uint8, uint8] = [r, g, b, a]
    // 4 bytes per pixel -> 8 pixels per slot -> 32 slots total
    // pixel #s: 01 == (0, 0), 02 == (1, 0) ...
    // 01 02 03 04 05 06 07 08 word1 - y=0
    // 09 10 11 12 13 14 15 16 word2 - y=0
    // 17 18 19 20 21 22 23 24 word3 - y=1
    // 25 26 27 28 29 30 31 32 word4 - y=1
    // 33 34 35 36 37 38 39 40 word5 - y=2
    // 41 42 43 44 45 46 47 48 word6 - y=2
    // etc..
    uint8[1024] public pixels;

    address public renderer;
    bool public pixelsSet;

    constructor(
        address _owner,
        uint256 _tokenId,
        address _defaultRenderer
    ) Spoke(_owner, _tokenId) {
        renderer = _defaultRenderer;
    }

    function tokenURI(uint256 id) external view returns (string memory) {
        return Renderer(renderer).tokenURI(id);
    }

    function renderSVG() external view returns (string memory) {
        return Renderer(renderer).renderSVG();
    }

    function getPixels() external view returns (uint8[1024] memory) {
        return pixels;
    }

    function setRenderer(address _renderer) external onlyOwner {
        renderer = _renderer;
    }

    // calldata isn't packed - need to pack it into memory -> store it
    function setPixels(uint8[1024] calldata) external onlyOwner {
        assembly {
            let pxNum := 0
            for {
                let wordNum := 0
            } lt(wordNum, 32) {
                wordNum := add(1, wordNum)
            } {
                mstore(0x40, 0x0) // zero the mem we're using to be safe
                for {
                    let cursor := 0
                } lt(cursor, 32) {
                    cursor := add(1, cursor)
                } {
                    let buffer := mload(0x40)
                    // paaaack it in
                    mstore(
                        0x40,
                        add(
                            buffer,
                            shl(
                                mul(8, cursor),
                                calldataload(add(4, mul(32, pxNum)))
                            )
                        )
                    )
                    pxNum := add(1, pxNum)
                }
                sstore(add(pixels.slot, wordNum), mload(0x40))
            }
        }
    }

    // Note that the storage is not zeroed out, so this is not a true "unset".
    // Would have to zero everything in setPixels() and then use this.
    function unsetPixels() external onlyOwner {
        pixelsSet = false;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import "solmate/src/tokens/ERC721.sol";

/// @notice Modified ERC721 that generates an individual contract for each token.
/// @author Team 4
interface ISpoke {
    function setOwner(address to) external payable;
}

abstract contract ERC721Hub is ERC721 {
    /*//////////////////////////////////////////////////////////////
                     ERC721HUB-SPECIFIC STORAGE/MODS
    //////////////////////////////////////////////////////////////*/
    mapping(uint256 => address) public spokes;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol
    ) ERC721(_name, _symbol) {}

    /*//////////////////////////////////////////////////////////////
                              TRANSFER LOGIC
    //////////////////////////////////////////////////////////////*/

    /* Transfers */
    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual override {
        super.transferFrom(from, to, id);
        ISpoke(spokes[id]).setOwner(to);
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _burn(uint256 id) internal virtual override {
        super._burn(id);
        delete spokes[id];
    }
}

pragma solidity >=0.8.0;

import "./ERC721Hub.sol";
import "solmate/src/auth/Owned.sol";

contract Spoke is Owned {
    address public hub;
    uint256 public immutable tokenId;

    modifier onlyHub() virtual {
        require(msg.sender == hub, "UNAUTHORIZED");
        _;
    }

    constructor(address _owner, uint256 _tokenId) Owned(_owner) {
        tokenId = _tokenId;
        hub = msg.sender;
    }

    function setOwner(address newOwner) public virtual override onlyHub {
        owner = newOwner;

        // Only way to call this is in transferFrom, which already
        // emits an event
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Simple single owner authorization mixin.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/auth/Owned.sol)
abstract contract Owned {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnerUpdated(address indexed user, address indexed newOwner);

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

        emit OwnerUpdated(address(0), _owner);
    }

    /*//////////////////////////////////////////////////////////////
                             OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

    function setOwner(address newOwner) public virtual onlyOwner {
        owner = newOwner;

        emit OwnerUpdated(msg.sender, newOwner);
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