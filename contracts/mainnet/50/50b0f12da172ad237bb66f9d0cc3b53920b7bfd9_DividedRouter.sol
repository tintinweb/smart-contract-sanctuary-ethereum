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
// Author: Daniel Von Fange (@DanielVF)

import {ERC721} from "solmate/tokens/ERC721.sol";
import {IDividedFactory} from "./interfaces/IDividedFactory.sol";
import {IDividedPool} from "./interfaces/IDividedPool.sol";

pragma solidity ^0.8.16;

contract DividedRouter {
    IDividedFactory public immutable factory;
    int128 constant PLUS = 100e18;
    int128 constant MINUS = -100e18;
    bytes32 immutable POOL_BYTECODE_HASH;

    constructor(address _factory) {
        factory = IDividedFactory(_factory);
        POOL_BYTECODE_HASH = factory.POOL_BYTECODE_HASH();
    }

    function nftIn(address collection, uint256 tokenId, address to) external {
        IDividedPool pool = _getPool(collection);
        ERC721(collection).transferFrom(msg.sender, address(pool), tokenId);
        int128 delta = pool.swap(new uint256[](0), msg.sender, to);
        require(delta >= PLUS);
    }

    function nftOut(address collection, uint256 tokenId, address to) external {
        IDividedPool pool = _getPool(collection);
        uint256[] memory ids = new uint256[](1);
        ids[0] = tokenId;
        int128 delta = pool.swap(ids, msg.sender, to);
        require(delta >= MINUS);
    }

    function nftSwap(address collection, uint256 tokenIn, uint256 tokenOut, address to) external {
        IDividedPool pool = _getPool(collection);
        ERC721(collection).transferFrom(msg.sender, address(pool), tokenIn);
        uint256[] memory ids = new uint256[](1);
        ids[0] = tokenOut;
        int128 delta = pool.swap(ids, msg.sender, to);
        require(delta >= 0);
    }

    function batchNftIn(address collection, uint256[] calldata tokenIds, address to) external {
        IDividedPool pool = _getPool(collection);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            ERC721(collection).transferFrom(msg.sender, address(pool), tokenIds[i]);
        }
        int128 delta = pool.swap(new uint256[](0), msg.sender, to);
        require(delta >= int128(uint128(tokenIds.length)) * PLUS);
    }

    function batchNftOut(address collection, uint256[] calldata tokenIds, address to) external {
        IDividedPool pool = _getPool(collection);
        int128 delta = pool.swap(tokenIds, msg.sender, to);
        require(delta >= int128(uint128(tokenIds.length)) * MINUS);
    }

    function batchNftSwap(address collection, uint256[] calldata tokenIns, uint256[] calldata tokenOuts, address to)
        external
    {
        IDividedPool pool = _getPool(collection);
        for (uint256 i = 0; i < tokenIns.length; i++) {
            ERC721(collection).transferFrom(msg.sender, address(pool), tokenIns[i]);
        }
        int128 delta = pool.swap(tokenOuts, msg.sender, to);
        int256 nftDelta = (int256(tokenIns.length) - int256(tokenOuts.length));
        require(delta >= nftDelta * PLUS);
    }

    function pools(address collection) external view returns (address) {
        return address(_getPool(collection));
    }

    function _getPool(address collection) internal view returns (IDividedPool) {
        address predictedAddress = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            bytes1(0xff), address(factory), keccak256(abi.encode(collection)), POOL_BYTECODE_HASH
                        )
                    )
                )
            )
        );
        return IDividedPool(predictedAddress);
    }
}

// SPDX-License-Identifier: MIT
// Author: Daniel Von Fange (@DanielVF)

interface IDividedFactory {
    function pools(address collection) external returns (address);
    function deployNftContract() external view returns (address);
    function POOL_BYTECODE_HASH() external view returns (bytes32);
    function deploy(address collection) external returns (address);
}

// SPDX-License-Identifier: MIT
// Author: Daniel Von Fange (@DanielVF)

interface IDividedPool {
    function collection() external returns (address);
    function LP_PER_NFT() external returns (uint256);
    function swap(uint256[] calldata tokensOut, address from, address to) external returns (int128);

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}