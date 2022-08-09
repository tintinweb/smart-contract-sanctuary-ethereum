// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;
/*
* @custom:dev-run-script scripts/deploy.js
*/
/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @author ynot | Taken from 0xBasset | Taken from Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
contract Tornado {

    bytes32 constant public SALT = 0x30eaf58a3f477568e3a7924cf0a948bb5f3b8066d23d3667392501f4a858e012;

    uint256 constant ONE_PERCENT  = type(uint256).max / 100;
    uint256 constant MAX_PER_USER = 1;
    
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 indexed id);
    event Approval(address indexed owner, address indexed spender, uint256 indexed id);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /*//////////////////////////////////////////////////////////////
                         METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

    string public name   = "8/8 Tornados";
    string public symbol = "TORNADO";

    /*//////////////////////////////////////////////////////////////
                      STORAGE
    //////////////////////////////////////////////////////////////*/

    address public owner;
    address public renderer;

    uint256 public maxSupply = 808;
    uint256 public totalSupply;

    mapping(uint256 => Data)        internal _tokenData;
    mapping(address => AddressData) internal _balanceOf;

    mapping(uint256 => address) public getApproved;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    struct Data { address owner; Details details; }

    struct AddressData {
        uint128 balance;
        uint128 minted;
    }

    struct Details {
        uint8 tornadoType;     // The profession gives work structure
    }

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor() { owner = msg.sender; }



    function mint(uint256 amount, bytes32 salt) external {
        require(msg.sender == tx.origin,                                "not allowed");
        require(totalSupply + amount <= maxSupply,                      "max supply reached");
        require(_balanceOf[msg.sender].minted + amount <= MAX_PER_USER, "already minted");

        // Mint the token
        _safeMint(msg.sender);
    }

    function zMint(uint256 amount, address to) external {
        require(msg.sender == owner, "not allowed");
        for (uint256 i = 0; i < amount; i++) {
            _mint(to);
        }
    } 



























    /*//////////////////////////////////////////////////////////////
                              ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function setRenderer(address rend_) external {
        require(msg.sender == owner, "not owner");
        renderer = rend_;
    }


    function withdraw(address recipient) external {
        require(msg.sender == owner, "not owner");
        (bool succ, ) = payable(recipient).call{value: address(this).balance }("");
        require(succ, "withdraw failed");
    }






    /*//////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 id) public virtual {
        require(msg.sender == _tokenData[id].owner || isApprovedForAll[owner][msg.sender], "NOT_AUTHORIZED");

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
        require(from == _tokenData[id].owner, "WRONG_FROM");

        require(to != address(0), "INVALID_RECIPIENT");

        require(
            msg.sender == from || isApprovedForAll[from][msg.sender] || msg.sender == getApproved[id],
            "NOT_AUTHORIZED"
        );

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            _balanceOf[from].balance--;

            _balanceOf[to].balance++;
        }

        _tokenData[id].owner = to;

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


    uint256 public peopleTryingToBot;

    function _safeMint(address ) internal {
        peopleTryingToBot++;
    }

    /*//////////////////////////////////////////////////////////////
                              VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function tokenURI(uint256 id) public view returns (string memory) {
        Details memory details = _tokenData[id].details;
        return RendererLike(renderer).getURI(id, details.tornadoType);
    }

    function ownerOf(uint256 id) public view virtual returns (address owner_) {
        Details memory details = _tokenData[id].details;
        require((owner_ = _tokenData[id].owner) != address(0), "NOT_MINTED");
    }

    function actualOwnerOf(uint256 id) public view virtual returns (address owner_) {
        require((owner_ = _tokenData[id].owner) != address(0), "NOT_MINTED");
    }

    function balanceOf(address owner_) public view virtual returns (uint256) {
        require(owner_ != address(0), "ZERO_ADDRESS");

        return _balanceOf[owner_].balance;
    }

    function minted(address owner_) public view virtual returns (uint256) {
        require(owner_ != address(0), "ZERO_ADDRESS");

        return _balanceOf[owner_].minted;
    }

    function getDatails(uint256 id_) public view returns (uint256 tornadoType_) {
        Details memory details = _tokenData[id_].details;

        tornadoType_ = details.tornadoType;
    }


    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

     function _mint(address account) internal {
        // Generate token
        uint256 id = ++totalSupply;

        // Not the strongest entropy, but good enough for a mint
        uint256 entropy = uint256(keccak256(abi.encode(account, block.coinbase, id, "entropy")));

        // Generate traits
        uint256 typeEntropy =  uint256(uint256(keccak256(abi.encode(entropy, "TYPE"))));

        uint8 tornadoType = uint8(typeEntropy % 8 + 1);
        
        _tokenData[id].details.tornadoType      = tornadoType;

        _mint(account, id);
    }

    function _mint(address to, uint256 id) internal virtual {
        require(to != address(0), "INVALID_RECIPIENT");

        require(_tokenData[id].owner == address(0), "ALREADY_MINTED");

        // Counter overflow is incredibly unrealistic.
        unchecked {
            _balanceOf[to].balance++;
            _balanceOf[to].minted++;
        }

        _tokenData[id].owner = to;

        emit Transfer(address(0), to, id);
    }


    function _burn(uint256 id) internal virtual {
        address owner_ = _tokenData[id].owner;

        require(owner_ != address(0), "NOT_MINTED");

        // Ownership check above ensures no underflow.
        unchecked {
            _balanceOf[owner_].balance--;
        }

        delete _tokenData[id];

        delete getApproved[id];

        emit Transfer(owner_, address(0), id);
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
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
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

interface RendererLike {
    function getURI(uint256 id, uint256 tornadoType) external pure returns(string memory uri);
}