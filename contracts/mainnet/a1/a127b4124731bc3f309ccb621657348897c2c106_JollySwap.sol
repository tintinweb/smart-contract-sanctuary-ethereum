// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.7;

contract JollySwap {

    bytes32 private constant ADMIN_SLOT = bytes32(0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103);

    uint256 private constant ONE_PERCENT = type(uint256).max / 100;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    event Approval(address indexed owner, address indexed spender, uint256 indexed id);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    event Minted(address indexed owner, uint256 id);

    event Burned(address indexed owner, uint256 id);

    /*//////////////////////////////////////////////////////////////
                      ERC721 BALANCE/OWNER STORAGE
    //////////////////////////////////////////////////////////////*/
    
    string public name;
    string public symbol;

    uint256 public totalSupply;
    uint256 public randmness;

    mapping(uint256 => TokenData) internal tokens;
    mapping(address => UserData)  internal users;

    mapping(address => bool)                     public minters;
    mapping(uint256 => address)                  public getApproved;
    mapping(address => mapping(address => bool)) public isApprovedForAll;

    struct TokenData {
        address owner;
    }

    struct UserData {
        uint128 balance;
        uint128 minted;
    }

    /*//////////////////////////////////////////////////////////////
                    CONSTRUCTOR & MODIFIERS
    //////////////////////////////////////////////////////////////*/

    function initialize(string memory _name, string memory _symbol) external {
        require(msg.sender == owner(), "NOT AUTHORIZED");

        name = _name;
        symbol = _symbol;
    }


    /*//////////////////////////////////////////////////////////////
                         VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function balanceOf(address owner_) public view virtual returns (uint256) {
        require(owner_ != address(0), "ZERO_ADDRESS");

        return users[owner_].balance;
    }

    function minted(address owner_) public view returns (uint256) {
        return users[owner_].minted;
    }

    function rarity(uint256 id) public view returns (uint256) {
        if (randmness == 0) return 0;

        uint256 rdn =  uint256(keccak256(abi.encodePacked(id, randmness)));

        if (rdn > ONE_PERCENT * 98) return 3;
        if (rdn > ONE_PERCENT * 80) return 2;

        return 1;
    }

    function owner() public view returns (address owner_) {
        return _getAddress(ADMIN_SLOT);
    }

    function ownerOf(uint256 id) public view returns (address owner_) {
        require((owner_ = tokens[id].owner) != address(0), "NOT_MINTED");
    }

    function tokenURI(uint256 id) public view virtual returns (string memory) {
        return string(abi.encodePacked("https://northpole.jollyswap.xyz/nft/jollyswap/", _toString(id), "/", _toString(rarity(id)), ".json"));
    }

    /*//////////////////////////////////////////////////////////////
                              MINTING LOGIC
    //////////////////////////////////////////////////////////////*/

    function mint(address receiver) external {  
        require(minters[msg.sender], "NOT MINTER");

        emit Minted(receiver, ++totalSupply);
        _safeMint(receiver, totalSupply);
    }

    function burn(address owner_, uint256 id) external {  
        require(minters[msg.sender],   "NOT MINTER");
        require(ownerOf(id) == owner_, "NOT OWNER");

        emit Burned(owner_, id);
        _burn(id);
    }

    /*//////////////////////////////////////////////////////////////
                              ADMIN LOGIC
    //////////////////////////////////////////////////////////////*/

    function withdraw(address destination, uint256 amount) external {
        require(msg.sender == owner(), "NOT_ADMIN");

        (bool success, ) = destination.call{value: amount}("");
        require(success, "TRANSFER FAILED");
    }

    function addMinter(address minter_, bool allowed) external {
        require(msg.sender == owner(), "NOT_ADMIN");
        minters[minter_] = allowed;
    }

    function setRandomness(uint256 randomness) external {
        require(msg.sender == owner(), "NOT_ADMIN");
        randmness = randomness;
    }

    /*//////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 id) public virtual {
        address owner_ = tokens[id].owner;

        require(msg.sender == owner_ || isApprovedForAll[owner_][msg.sender], "NOT_AUTHORIZED");

        getApproved[id] = spender;

        emit Approval(owner_, spender, id);
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

        require(tokens[id].owner == address(0), "ALREADY_MINTED");

        // Counter overflow is incredibly unrealistic.
        unchecked {
            users[to].minted++;
            users[to].balance++;
        }

        tokens[id].owner = to;

        emit Transfer(address(0), to, id);
    }

    function _burn(uint256 id) internal virtual {
        address owner_ = tokens[id].owner;

        require(owner_ != address(0), "NOT_MINTED");

        // Ownership check above ensures no underflow.
        unchecked {
            users[owner_].balance--;
        }

        tokens[id].owner = address(0);

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

    /*//////////////////////////////////////////////////////////////
                        INTERNAL UTILITIES
    //////////////////////////////////////////////////////////////*/

    function _toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    function _getAddress(bytes32 key) internal view returns (address add) {
        add = address(uint160(uint256(_getSlotValue(key))));
    }

    function _getSlotValue(bytes32 slot_) internal view returns (bytes32 value_) {
        assembly {
            value_ := sload(slot_)
        }
    }
}

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