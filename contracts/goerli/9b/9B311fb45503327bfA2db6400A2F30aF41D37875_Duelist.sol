// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Simple single owner authorization mixin.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/auth/Owned.sol)
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
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
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

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@rari-capital/solmate/src/tokens/ERC721.sol";
import "@rari-capital/solmate/src/auth/Owned.sol";
import "./interfaces/ILuck.sol";

/// @title Duelist
/// @notice ERC-721 Token
contract Duelist is ERC721, Owned {
    /// @notice The maximum supply of Duelists
    uint256 public constant MAX_SUPPLY = 1024;

    /// @notice The Duel contract
    address public duel;

    /// @notice The Luck Token Contract
    ILuck public luck;

    /// @notice Base URI used to compute token URI
    string public baseURI;

    /// @notice The current total supply of Duelist
    uint256 public totalSupply;

    /// @notice Mapping of tokenId => level
    mapping(uint256 => uint256) public levelOf;

    event LevelUpdated(uint256 indexed id, uint256 indexed newLevel, uint256 indexed oldLevel);
    event BaseURIUpdated(string indexed newBaseURI, string indexed oldBaseURI);
    event DuelUpdated(address indexed newDuel, address indexed oldDuel);
    event LuckUpdated(address indexed newLuck, address indexed oldLuck);

    /// @notice Duelist constructor function
    /// @param _luck The LUCK token contract
    constructor(ILuck _luck) ERC721("Duelist", "DUEL") Owned(msg.sender) {
        require(address(_luck) != address(0), "Duelist:Init::InvalidLuck");
        luck = _luck;
    }

    /// @notice Level up a duelist to the given level, caller must own the target Duelist
    /// @notice Luck tokens are burnt in order to level up
    /// @param id The id of the Duelist to level up
    /// @param level The level to increase to, may increase many levels at once
    function levelUp(uint256 id, uint256 level) external {
        require(msg.sender == ownerOf(id), "Duelist:LevelUp::InvalidDuelist");
        uint256 currentLevel = levelOf[id];
        require(level > currentLevel, "Duelist:LevelUp:InvalidLevel");

        // compute amount to burn
        uint256 burnAmount;
        for (uint256 i = currentLevel; i < level; i++) {
            burnAmount += (i + 1) * 1e18;
        }

        levelOf[id] = level;
        luck.burn(msg.sender, burnAmount);
        emit LevelUpdated(id, level, currentLevel);
    }

    /// @notice Level down a duelist when a duel is lost
    /// @notice Only callable by Duel contract
    /// @param id The id of the Duelist to level down
    function levelDown(uint256 id) external {
        require(msg.sender == duel, "Duelist:LevelDown::InvalidCaller");
        emit LevelUpdated(id, 0, levelOf[id]);
        levelOf[id] = 0;
    }

    /// @notice Mint function, only contract owner can call
    /// @notice Prevent minting from exceeding MAX_SUPPLY
    /// @param recipient The address of the recipient to mint to
    /// @param quantity The amount of Duelists to mint
    function mint(address recipient, uint256 quantity) external onlyOwner {
        uint256 currentSupply = totalSupply;
        uint256 newSupply = currentSupply + quantity;
        require(newSupply <= MAX_SUPPLY, "Duelist:Mint::MaxSupplyReached");
        for (uint256 i = currentSupply; i < newSupply; i++) {
            _mint(recipient, i);
        }
        totalSupply = newSupply;
    }

    /// @notice Set the Base URI
    /// @param _baseURI The new Base URI
    function setBaseURI(string calldata _baseURI) external onlyOwner {
        emit BaseURIUpdated(_baseURI, baseURI);
        baseURI = _baseURI;
    }

    /// @notice Set the Duel Contract
    /// @param _duel The new Duel contract
    function setDuel(address _duel) external onlyOwner {
        require(_duel != address(0), "Duelist:SetDuel::InvalidDuel");
        emit DuelUpdated(_duel, duel);
        duel = _duel;
    }

    /// @notice Set the LUCK Token Contract
    /// @param _luck The new Luck contract
    function setLuck(ILuck _luck) external onlyOwner {
        require(address(_luck) != address(0), "Duelist:SetLuck::InvalidLuck");
        emit LuckUpdated(address(_luck), address(luck));
        luck = _luck;
    }

    /// @notice View the amount of tokens required to burn to level up a Duelist
    /// @param id The id of the Duelist to level
    /// @param level The level to increase the Duelist to
    function tokenRequiredForLevel(uint256 id, uint256 level) external view returns (uint256 burnAmount) {
        uint256 currentLevel = levelOf[id];
        for (uint256 i = currentLevel; i < level; i++) {
            burnAmount += i + 1 * 1e18;
        }
    }

    /// @notice View the token id's metadata uri
    /// @param id The id of the Duelist token to check
    function tokenURI(uint256 id) public view override returns (string memory) {
        return string(abi.encodePacked(baseURI, toString(id)));
    }

    /// @notice OpenZeppelin toString implementation
    /// @dev https://github.com/OpenZeppelin/openzeppelin-contracts/blob/6766b2de3bd0473bb7107fd8f83ef8c83c5b1fb3/contracts/utils/Strings.sol#L16
    function toString(uint256 value) internal pure returns (string memory) {
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
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IERC2612 {
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

/// @notice IERC20 with Metadata + Permit
interface IERC20 is IERC2612 {
    function approve(address spender, uint256 amount) external returns (bool);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function decimals() external view returns (uint8);

    function name() external view returns (string calldata);

    function symbol() external view returns (string calldata);

    function totalSupply() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./IERC20.sol";

interface ILuck is IERC20 {
    function burn(address holder, uint256 amount) external;

    function mint(address recipient, uint256 amount) external;

    function setBurner(address burner, bool approved) external;

    function setMinter(address minter, bool approved) external;

    function burners(address burner) external view returns (bool);

    function minters(address minter) external view returns (bool);
}