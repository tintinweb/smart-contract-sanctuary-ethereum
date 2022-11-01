// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.7;

contract Firekeepers {

    uint256 public immutable DURATION; // = 75;
    uint256 public immutable MATURITY; // = 21600; // 72 hours in block time (12 seconds)

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    event Approval(address indexed owner, address indexed spender, uint256 indexed id);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    event Minted(address indexed owner, uint256 id, uint256 indexed blockNumber, uint256 index);

    /*//////////////////////////////////////////////////////////////
                      ERC721 BALANCE/OWNER STORAGE
    //////////////////////////////////////////////////////////////*/
    
    string public name;
    string public symbol;
    
    address public admin;

    uint256 public currentId;
    uint256 public lowestEmber;

    uint256 public TEST_LASTMINTED;

    mapping(uint256 => TokenData) internal tokens;
    mapping(address => UserData)  internal users;

    mapping(uint256 => address)                  public getApproved;
    mapping(address => mapping(address => bool)) public isApprovedForAll;

    struct TokenData {
        address owner;
        uint48  mintingBlock;
        uint48  index;
    }

    struct UserData {
        uint128 balance;
        uint128 minted;
    }

    /*//////////////////////////////////////////////////////////////
                    CONSTRUCTOR & MODIFIERS
    //////////////////////////////////////////////////////////////*/

    function TEST_RESTART() external {
        TEST_LASTMINTED = block.number;
    }

    constructor(string memory _name, string memory _symbol, uint256 duration_, uint256 maturity_) {
        name = _name;
        symbol = _symbol;

        DURATION = duration_;
        MATURITY = maturity_;

        admin       = msg.sender;
        lowestEmber = duration_;
    }

    modifier onlyMature(uint256 id) {
        require(lastMinted() >= tokens[id].mintingBlock + MATURITY, "NOT MATURED");
        _;
    }

    /*//////////////////////////////////////////////////////////////
                         VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function lastMinted() public view returns (uint256) {
        // TODO remove - test override to allow better testing
        if (currentId != 0 && TEST_LASTMINTED > tokens[currentId].mintingBlock) {
            return TEST_LASTMINTED;
        }

        return currentId == 0 ? block.number : tokens[currentId].mintingBlock;
    }

    function tokenURI(uint256 id) public view virtual returns (string memory) {
        // Todo - implement this
    }

    function ownerOf(uint256 id) public view returns (address owner) {
        require((owner = tokens[id].owner) != address(0), "NOT_MINTED");
    }

    function balanceOf(address owner) public view virtual returns (uint256) {
        require(owner != address(0), "ZERO_ADDRESS");

        return users[owner].balance;
    }

    function minted(address owner) public view returns (uint256) {
        return users[owner].minted;
    }
    
    function currentIndex() public view virtual returns (uint256) {
        uint256 elapsed = block.number - lastMinted();

        require(DURATION > elapsed, "GAME OVER");

        return DURATION - elapsed;
    }

    function indexOf(uint256 id) public view returns (uint256) {
        return tokens[id].index;
    }

    /*//////////////////////////////////////////////////////////////
                              MINTING LOGIC
    //////////////////////////////////////////////////////////////*/

    function mint() external payable {
        require(block.number <= lastMinted() + DURATION, "GAME OVER");

        uint256 index = currentIndex(); 

        if (index < lowestEmber) lowestEmber = index;

        emit Minted(msg.sender, ++currentId, block.number, index);
        _safeMint(msg.sender, currentId, index);
    }

    /*//////////////////////////////////////////////////////////////
                              ADMIN LOGIC
    //////////////////////////////////////////////////////////////*/

    function withdraw(address destination, uint256 amount) external {
        require(msg.sender == admin, "NOT_ADMIN");

        (bool success, ) = destination.call{value: amount}("");
        require(success, "TRANSFER FAILED");
    }

    /*//////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 id) public virtual {
        address owner = tokens[id].owner;

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
    ) public virtual onlyMature(id) {
        require(from == tokens[id].owner, "WRONG_FROM");

        require(to != address(0), "INVALID_RECIPIENT");

        require(
            msg.sender == from || isApprovedForAll[from][msg.sender] || msg.sender == getApproved[id],
            "NOT_AUTHORIZED"
        );

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            users[from].balance--;

            users[to].balance++;
        }

        tokens[id].owner = to;

        delete getApproved[id];

        emit Transfer(from, to, id);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual onlyMature(id) {
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
    ) public virtual onlyMature(id) {
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

    function _mint(address to, uint256 id, uint256 index) internal virtual {
        require(to != address(0), "INVALID_RECIPIENT");

        require(tokens[id].owner == address(0), "ALREADY_MINTED");

        // Counter overflow is incredibly unrealistic.
        unchecked {
            users[to].minted++;
            users[to].balance++;
        }

        tokens[id].owner = to;
        tokens[id].mintingBlock = uint48(block.number);
        tokens[id].index        = uint48(index);

        emit Transfer(address(0), to, id);
    }

    function _burn(uint256 id) internal virtual {
        address owner = tokens[id].owner;

        require(owner != address(0), "NOT_MINTED");

        // Ownership check above ensures no underflow.
        unchecked {
            users[owner].balance--;
        }

        tokens[id].owner = address(0);

        delete getApproved[id];

        emit Transfer(owner, address(0), id);
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL SAFE MINT LOGIC
    //////////////////////////////////////////////////////////////*/

    function _safeMint(address to, uint256 id, uint256 index) internal virtual {
        _mint(to, id, index);

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
        uint256 index,
        bytes memory data
    ) internal virtual {
        _mint(to, id, index);

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