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
pragma solidity 0.8.17;

import {ERC721} from "solmate/tokens/ERC721.sol";
import {ISBT} from "./interfaces/ISBT.sol";

contract SBT is ERC721, ISBT {
    uint256 private _tokenIdCounter = 1;
    address public owner;

    constructor(string memory _name, string memory _symbol)
        ERC721(_name, _symbol)
    {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), owner);
    }

    /* ========== MODIFIERS ========== */
    /// @notice modifier to check if the user type is valid
    /// @param _type the type of the user
    modifier validateType(uint256 _type) {
        if (_type < 1 || _type > 3) revert InvalidUserType();
        _;
    }

    /// @notice modifier to check if the user is authorized to revoke a token
    /// @param id the id of the token to revoke
    modifier onlyRevokeAuthorized(uint256 id) {
        if (owner != msg.sender && _ownerOf[id] != msg.sender)
            revert NotAuthorizedToRevoke();
        _;
    }

    /// @notice modifier to check if the user is the owner of the contract
    modifier onlyOwner() {
        if (owner != msg.sender) revert NotOwner();
        _;
    }

    /* ========== MAPPINGS ========== */
    mapping(uint256 => string) private _tokenURIs;

    ///  This is the mapping that will be used to store the user type of each user.
    /// 1 = Auditor
    /// 2 = Platform
    /// 3 = Protocol
    mapping(address => uint256) public userType;

    /// @notice method to mint a new token
    /// @param _to the address to mint the token to
    /// @param _uri the URI that holds the metadata for the token
    /// @param _type the type of the user
    function mint(
        address _to,
        string calldata _uri,
        uint256 _type
    ) external validateType(_type) onlyOwner {
        uint256 id = _tokenIdCounter;
        _tokenURIs[id] = _uri;
        userType[_to] = _type;
        _tokenIdCounter++;
        _mint(_to, id);
    }

    /// @notice method to burn a SBT
    /// @param _id the id of the token to burn
    function burn(uint256 _id) public onlyRevokeAuthorized(_id) {
        //solhint-disable-next-line var-name-mixedcase
        address SBTOwner = _ownerOf[_id];

        if (SBTOwner == address(0)) revert NotMinted();

        // Ownership check above ensures no underflow.
        unchecked {
            _balanceOf[SBTOwner]--;
        }

        delete _ownerOf[_id];

        delete getApproved[_id];

        delete _tokenURIs[_id];

        delete userType[SBTOwner];

        emit Transfer(SBTOwner, address(0), _id);
    }

    /*solhint-disable no-unused-vars*/

    /// @dev all of the following functions are overridden to prevent the transfer of SBT tokens
    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public pure override {
        revert CannotTransferSBT();
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public pure override {
        revert CannotTransferSBT();
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes calldata data
    ) public pure override {
        revert CannotTransferSBT();
    }

    /**
     *  @dev Allows the current owner to transfer control of the contract to a newOwner.
     *  @param _newOwner The address to transfer ownership to.
     */
    function transferOwnership(address _newOwner) external onlyOwner {
        owner = _newOwner;
        emit OwnershipTransferred(owner, _newOwner);
    }

    /// @notice method to get the URI that holds the metadata for a token
    /// @param id the token id
    function tokenURI(uint256 id)
        public
        view
        override(ERC721, ISBT)
        returns (string memory)
    {
        return _tokenURIs[id];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface ISBT {
    /* ========== ERRORS ========== */
    error NotMinted();
    error NotAuthorizedToRevoke();
    error InvalidUserType();
    error CannotTransferSBT();
    error NotOwner();

    /* ========== EVENTS ========== */
    event OwnershipTransferred(address indexed _from, address indexed _to);

    /* ========== PUBLIC GETTERS ========== */

    /**
     * @dev used to get the user type of a user
     * @param user the user address
     * @return the user type (1 = Auditor, 2 = Platform, 3 = Protocol)
     */
    function userType(address user) external view returns (uint256);

    /**
     * @dev used to get the owner of the contract
     * @return the address of the owner
     */
    function owner() external view returns (address);

    /**
     * @dev used to get the URI that holds the metadata for a token
     * @param id the token id
     * @return the URI that holds the metadata for the token
     */
    function tokenURI(uint256 id) external view returns (string memory);

    /* ========== FUNCTIONS ========== */
    /**
     * @dev used to create a new SBT token and assign it to the given address
     * @param _to the address to mint the token to
     * @param _uri the URI that holds the metadata for the token
     * @param _type the type of the user
     * _type can be one of the following:
     * 1: Auditor
     * 2: Platform
     * 3: Protocol
     */
    function mint(
        address _to,
        string calldata _uri,
        uint256 _type
    ) external;

    /**
     * @dev used to revoke a token from the given address and burn it, only the holder of the token or the contract owner can revoke a token
     * @param _id the id of the token to revoke
     */
    function burn(uint256 _id) external;

    /**
     *  @dev used to transfer the ownership of the contract to a new address
     *  @param _newOwner the address of the new owner
     */
    function transferOwnership(address _newOwner) external;
}