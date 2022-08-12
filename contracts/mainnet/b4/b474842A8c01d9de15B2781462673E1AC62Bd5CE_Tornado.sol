// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;


/*
    RIP Tornado Cash
    08/2019 - 08/2022
    Public Goods Can Never Die
*/

/// @author ynot | Taken from 0xBasset | Taken from Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
contract Tornado {

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

    string public name   = "CRYPTONADOS";
    string public symbol = "NADO";


    /*//////////////////////////////////////////////////////////////
                      STORAGE
    //////////////////////////////////////////////////////////////*/

    address public owner;
    address public renderer;
    address public mineableToken;

    uint256 public startEpoch = 210699;
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
        uint8 tornadoType;     // What is the 'nado made out of?
        uint8 fujitaScale;     // How strong is it tho?
    }


    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor() { owner = msg.sender; }

    function mint(uint256 amount) external {    
        require(IERC918(mineableToken).epochCount() >= startEpoch,     "sale not started");
        require(msg.sender == tx.origin,                                "not allowed");
        require(totalSupply + amount <= maxSupply,                      "max supply reached");
        require(_balanceOf[msg.sender].minted + amount <= MAX_PER_USER, "already minted");

        for (uint256 i = 0; i < amount; i++) {
            _mint(msg.sender);
        }
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

    function setERC918(address mineableToken_) external {
        require(msg.sender == owner, "not owner");
        mineableToken = mineableToken_;
    }

    function setRenderer(address rend_) external {
        require(msg.sender == owner, "not owner");
        renderer = rend_;
    }

    function setOwner(address owner_) external {
        require(msg.sender == owner, "not owner");
        owner = owner_;
    }

    function withdraw(address recipient) external {
        require(msg.sender == owner, "not owner");
        (bool succ, ) = payable(recipient).call{value: address(this).balance }("");
        require(succ, "withdraw failed");
    }

    function setStartEpoch(uint256 startEpoch_) external {
        require(msg.sender == owner, "not owner");
        startEpoch = startEpoch_;
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


    /*//////////////////////////////////////////////////////////////
                              VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function tokenURI(uint256 id) public view returns (string memory) {
        Details memory details = _tokenData[id].details;
        return RendererLike(renderer).getURI(id, details.tornadoType, details.fujitaScale);
    }

    function ownerOf(uint256 id) public view virtual returns (address owner_) {
        // Details memory details = _tokenData[id].details;
        owner_ = _tokenData[id].owner;

        require(owner_ != address(0), "NOT_MINTED");
    }

    function balanceOf(address owner_) public view virtual returns (uint256) {
        require(owner_ != address(0), "ZERO_ADDRESS");

        return _balanceOf[owner_].balance;
    }

    function minted(address owner_) public view virtual returns (uint256) {
        require(owner_ != address(0), "ZERO_ADDRESS");

        return _balanceOf[owner_].minted;
    }

    function getTraits(uint256 id_) public view returns (uint256 tornadoType_, uint256 fujitaScale_) {
        Details memory details = _tokenData[id_].details;

        tornadoType_ = details.tornadoType;
        fujitaScale_ = details.fujitaScale;
    }


    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

     function _mint(address account) internal {
        // Generate token
        uint256 id = ++totalSupply;

        // Not the strongest entropy, but good enough for a mint
        uint256 entropy = uint256(keccak256(abi.encode(account, block.coinbase, id, "entropy")));

        // Tornado Type
        uint256 typeEntropy =  uint256(uint256(keccak256(abi.encode(entropy, "TYPE"))));
        uint8 tornadoType = uint8(typeEntropy % 10 + 1);
        _tokenData[id].details.tornadoType      = tornadoType;

        // Tornado Strength
        uint256 fujitaEntropy =  uint256(uint256(keccak256(abi.encode(entropy, "FUJITA"))));
        uint8 fujitaScale = uint8(
            // If entropy smaller than 50 %, is F0 or F1
            fujitaEntropy <= 70 * ONE_PERCENT ? (fujitaEntropy % 2): 
            // If entropy between 50% and 85%, is F2 or F3
            fujitaEntropy <= 93 * ONE_PERCENT ? (fujitaEntropy % 2) + 2:
            // If entropy between 85% and 98%, is F4
            fujitaEntropy <= (99 * ONE_PERCENT ) + (ONE_PERCENT / 2) ? 4:
            // F5 tornado mother fucker
            5);
        _tokenData[id].details.fujitaScale      = fujitaScale;

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


    /*//////////////////////////////////////////////////////////////
                        INTERFACES
    //////////////////////////////////////////////////////////////*/

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

interface IERC918  {   
   function epochCount() external view returns (uint);
}

interface RendererLike {
    function getURI(uint256 id, uint256 tornadoType, uint256 fujitaScale) external pure returns(string memory uri);
}