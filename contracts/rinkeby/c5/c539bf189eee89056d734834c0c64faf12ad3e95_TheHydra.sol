// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

// third party includes
import "solmate/tokens/ERC721.sol";
import "solmate/auth/Owned.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// local includes
import "./interfaces/ITheHydra.sol";
import "./interfaces/ITheHydraRenderer.sol";

// TODO -- Did I add the metadata interface support?

/// @title TheHydra is the genesis collection of the Altered Earth NFT series
/// @author therightchoyce.eth
/// @notice This implemeints the ERC721 standard
/// @dev Modified ERC721 for minting and managing tokens

contract TheHydra is Owned, ERC721, ITheHydra {
    /// @dev Enable toString and other string functions on uint256
    using Strings for uint256;

    /// @dev Store the MAX_INT as a constant and we then use this as an invalid ID value
    uint256 constant MAX_INT = type(uint256).max;

    // --------------------------------------------------------
    // ~~ Core state variables ~~
    // --------------------------------------------------------

    /// @dev Renderer contract for metadata * on-chain artwork
    ITheHydraRenderer public renderer;

    // --------------------------------------------------------
    // ~~ Edition configuration ~~
    // --------------------------------------------------------

    /// @dev The maximum available editions per original.
    uint256 constant editionsPerOriginal = 50;

    /// @dev Max edition count per origial
    uint256 constant editionsCountPerOriginal = 49;

    /// @dev The total number of 1-of-1 original NFTs available
    uint256 constant editionsSupply = 2500;

    /// @dev This is the maximium Id available for the editions.. I.E if there are 2500 editions and 50 originals, the max editionId is 2549. Used to save gas during when doing > or < logic.
    uint256 constant editionsMaxId = 2549;

    /// @dev The default mint price for an on-chain edition. Set to immutable to allow us to pass in the price to the constructor for testing and to easily change the price when pushing the contract live
    uint256 public immutable editionsMintPrice;

    /// @dev Easily track the number of editions minted for each original contract. Using a counter instead of tracking the starting index because if we tracked the starting index for each edition, then there would be a need to initilize each starting index to a particular sequenced number vs. just allowing default value of 0 here.
    mapping(uint256 => uint256) editionsMinted;

    // --------------------------------------------------------
    // ~~ Original configuration ~~
    // --------------------------------------------------------

    /// @dev The total number of 1-of-1 original NFTs available
    uint256 constant originalsSupply = 50;

    /// @dev This is the maximium Id available for the originals.. I.E with 50 available and starting from 0, the originalsMaxId should be 49. Used to save gas during when doing > or < logic.
    uint256 constant originalsMaxId = 49;

    /// @dev The default mint price for a 1-of-1 original
    uint256 public immutable originalsMintPrice;

    // --------------------------------------------------------
    // ~~ Other ~~
    // --------------------------------------------------------

    /// @dev Track the total supply available to mint in this collection, this includes all originals + editions.
    uint256 public constant totalSupply = 2550;

    // --------------------------------------------------------
    // ~~ Events ~~
    // --------------------------------------------------------

    /// @dev When this contract is created
    event TheHydraAwakens();

    /// @dev When the renderer contract is set and available
    event ConsciousnessActivated(address indexed renderer);

    // --------------------------------------------------------
    // ~~ Errors ~~
    // --------------------------------------------------------

    /// @dev A general error when trying to mint
    error CouldNotAlterReality();

    /// @dev When an originalId is out of bounds, or an edition has reached its mint limit
    error BeyondTheScopeOfConsciousness();

    /// @dev When all editions for an original are minted
    error EditionSoldOut();

    /// @dev When a h4ck3r tries to steal out tokens
    error PayeeNotInDreamState();

    /// @dev When the provided operator isn't the owner
    error InvalidDreamState();

    /// @dev When the renderer isn't configured
    error ConsciousnessNotActivated();

    // --------------------------------------------------------
    // ~~ Modifiers ~~
    // --------------------------------------------------------

    /// @dev Ensures the payable amount is correct
    /// @param _costToMint the cost to mint the NFT specified in wrapped function
    modifier ElevatingConsciousnessHasACost(uint256 _costToMint) {
        if (msg.value != _costToMint) revert CouldNotAlterReality();
        _;
    }

    /// @dev Ensures tokenId is within the valid range token range
    /// @param _originaId The token id to check
    modifier CheckConsciousness(uint256 _originaId) {
        // currently allowing zero-based ids
        if (_originaId > originalsMaxId) revert BeyondTheScopeOfConsciousness();
        _;
    }

    /// @dev Fail if an edition has reached its mint capacity
    /// @param _originalId The edition id to check
    modifier CheckSubConsciousness(uint256 _originalId) {
        // currently allowing zero-based ids
        if (editionsMinted[_originalId] > editionsCountPerOriginal)
            revert EditionSoldOut();
        _;
    }

    /// @dev Fail if the editionId is actually an originalId, or if it is beyond the max number of editions
    /// @param _editionId The tokenId of this edition
    modifier CheckEditionIdBoundries(uint256 _editionId) {
        /// @dev If this is actually an original
        if (_editionId < originalsSupply)
            revert BeyondTheScopeOfConsciousness();
        /// @dev if this is higher then the editions we have available
        if (_editionId > editionsMaxId) revert BeyondTheScopeOfConsciousness();
        _;
    }

    /// @dev Defer this to the Solmate contract's _mint function to save gas, since it already has an ownership check built in -- in theory this checks to ensure this token is not already owned
    modifier RealityNotAlreadyAltered(uint256 id) {
        _;
    }

    // --------------------------------------------------------
    // ~~ Constructor Logic ~~
    // --------------------------------------------------------

    /// @param _owner The owner of the contract, when deployed
    /// @param _originalsMintPrice Mint price for each origial
    /// @param _editionsMintPrice Mint price for each edition
    constructor(
        address _owner,
        uint256 _originalsMintPrice,
        uint256 _editionsMintPrice
    ) ERC721("Altered Earth: The Hydra Collection", "ALTERED") Owned(_owner) {
        // therightchoyce.eth and 10% -- can be changed later
        royalties = Royalties(
            address(0x18836acedeF35D4A6C00Aae46a36fAdE12ee5FF7),
            1000 // 1000 / 10_000 => 10%
        );

        // Setup initial mint prices
        originalsMintPrice = _originalsMintPrice;
        editionsMintPrice = _editionsMintPrice;

        emit TheHydraAwakens();
    }

    // --------------------------------------------------------
    // ~~ MetaData ~~
    // --------------------------------------------------------

    /// @notice Sets the rendering/metadata contract address
    /// @dev The metadata address handles off-chain metadata and on-chain artwork
    /// @param _renderer The address of the metadata contract
    function setRenderer(ITheHydraRenderer _renderer) external onlyOwner {
        renderer = _renderer;
        emit ConsciousnessActivated(address(_renderer));
    }

    /// @notice Standard URI function to get the token metadata
    /// @param id Id of token requested
    function tokenURI(uint256 id) public view override returns (string memory) {
        /// @dev Ensure this id is in a dream state
        if (_ownerOf[id] == address(0)) revert BeyondTheScopeOfConsciousness();

        /// @dev Ensure a rendering contract is set
        if (address(renderer) == address(0)) revert ConsciousnessNotActivated();

        return renderer.tokenURI(id);
    }

    // --------------------------------------------------------
    // ~~ Mint Functions => Originals ~~
    // --------------------------------------------------------
    function alterReality(uint256 id)
        external
        payable
        ElevatingConsciousnessHasACost(originalsMintPrice)
        CheckConsciousness(id)
        RealityNotAlreadyAltered(id)
    {
        _safeMint(msg.sender, id, "Welcome to TheHydra's Reality");
    }

    // --------------------------------------------------------
    // ~~ Mint Functions => Editions ~~
    // --------------------------------------------------------

    /// @notice Mint an edition of an original
    /// @dev This will revert if trying to mint more than 50 of an edition
    /// @param _originalId TokenId of the original 1-of-1 NFT
    function alterSubReality(uint256 _originalId)
        external
        payable
        CheckConsciousness(_originalId)
        CheckSubConsciousness(_originalId)
        ElevatingConsciousnessHasACost(editionsMintPrice)
    {
        uint256 nextEditionId = (_originalId * editionsPerOriginal) +
            originalsSupply +
            editionsMinted[_originalId];

        ++editionsMinted[_originalId];

        _safeMint(msg.sender, nextEditionId, "Welcome to TheHydra's Reality");
    }

    // --------------------------------------------------------
    // ~~ Editions Info & Status ~~
    // --------------------------------------------------------
    /// @notice Gets all the information about the editions for this original
    /// @dev Returns a struct containing edition startId, endId, minted count, soldOut status, next EditionId to be minted, and the localindx (ie. 3 of 50)
    /// @param _originalId The tokenId of the the original
    function editionsGetInfoFromOriginal(uint256 _originalId)
        public
        view
        CheckConsciousness(_originalId)
        returns (EditionInfo memory)
    {
        uint256 startId = (_originalId * editionsPerOriginal) + originalsSupply;
        uint256 endId = startId + editionsCountPerOriginal;
        uint256 minted = editionsMinted[_originalId];
        bool soldOut = (minted == 50);
        uint256 nextId = soldOut ? MAX_INT : startId + minted;
        /// @dev Take the reminder and then add 1 to convert from 0-based to 1-based counting
        uint256 localIndex = soldOut
            ? MAX_INT
            : (nextId % editionsPerOriginal) + 1;

        return
            EditionInfo(
                _originalId,
                startId,
                endId,
                minted,
                soldOut,
                nextId,
                localIndex,
                editionsPerOriginal
            );
    }

    // TODO -- I think I can also remove this!
    /// @notice Gets all the information a particular edition
    /// @dev Returns a struct containing edition startId, endId, minted count, soldOut status, next EditionId to be minted, and the localindx of this edition (ie. 3 of 50)
    /// @param _editionId The tokenId of the the edition
    function editionsGetInfoFromEdition(uint256 _editionId)
        public
        view
        CheckEditionIdBoundries(_editionId)
        returns (EditionInfo memory)
    {
        uint256 originalId = (_editionId - originalsSupply) /
            editionsPerOriginal;
        EditionInfo memory edition = editionsGetInfoFromOriginal(originalId);
        edition.localIndex = (_editionId % editionsPerOriginal) + 1;

        return edition;
    }

    // --------------------------------------------------------
    // ~~ BURN ~~
    // --------------------------------------------------------

    /// @notice Send your AlteredEarth token back to Reality
    /// @dev Burns it
    /// @param id Id of the NFT to burn
    function returnToReality(uint256 id) public {
        // TODO -- It looks like if a token is burned, someone else could then come back and mint it again.. need to ensure there isn't a way to do that.

        if (_ownerOf[id] != msg.sender) revert InvalidDreamState();
        _burn(id);
    }

    // --------------------------------------------------------
    // ~~ ERC165 Support ~~
    // --------------------------------------------------------

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override
        returns (bool)
    {
        return
            interfaceId == 0x2a55205a || // ERC2981
            super.supportsInterface(interfaceId);
    }

    // --------------------------------------------------------
    // ~~ ERC2981 Implementation AKA Royalties ~~
    // --------------------------------------------------------

    /// @dev Store info about token royalties
    struct Royalties {
        address receiver;
        uint24 amount;
    }
    Royalties private royalties;

    /// @notice EIP-2981 royalty standard for on-chain royalties
    function royaltyInfo(uint256, uint256 _salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount)
    {
        receiver = royalties.receiver;
        royaltyAmount = (_salePrice * royalties.amount) / 10_000;
    }

    /// @notice Update royalty information
    /// @param _receiver The receiver of royalty payments
    /// @param _amount The royalty percentage with two decimals (10000 = 100)
    function setRoyaltyInfo(address _receiver, uint256 _amount)
        external
        onlyOwner
    {
        royalties = Royalties(_receiver, uint24(_amount));
    }

    // --------------------------------------------------------
    // Withdraw ETH in contract
    // --------------------------------------------------------
    function withdrawPayments(address payable payee) external onlyOwner {
        uint256 balance = address(this).balance;
        (bool transferTx, ) = payee.call{value: balance}("");
        if (!transferTx) {
            revert PayeeNotInDreamState();
        }
    }

    // --------------------------------------------------------
    // ~~ Helper functions ~~
    // --------------------------------------------------------
    /// @notice Returns the owner of a token, or the zero address if unowned
    /// @dev This is implemented as a helper for the dapp -- this funtion will not revert when a token is unowned, making it easier to check ownership from the front-end
    /// @param id The id of the token
    /// @return owner address Either the current owner or address(0)
    function ownerOfOrNull(uint256 id) public view returns (address owner) {
        return _ownerOf[id];
    }

    // --------------------------------------------------------
    // ~~ Proxy i.e. Gas-less listings on exchanges or      ~~
    // ~~ allowing future AltredEarth contracts to manage   ~~
    // ~~ this contract with the need for user approval     ~~
    // --------------------------------------------------------

    // TODO -- Solmate doesn't use a function for isApprovedForAll which makes it incredibly difficult to override that functionality
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

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

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

/// @author therightchoyce.eth
/// @title  Composable interface for TheHydra contract
/// @notice Allows other contracts to easily call methods exposed in this
///         interface.. IE a Renderer contract will be able to interact
///         with TheHydra's ERC721 functions
interface ITheHydra {
    /// @dev Helper to return standard edition information based on the original. Note that this is dynamic since the next and minted count will change
    struct EditionInfo {
        uint256 originalId;
        uint256 startId;
        uint256 endId;
        uint256 minted;
        bool soldOut;
        uint256 nextId;
        uint256 localIndex;
        uint256 maxPerOriginal;
    }

    // function getOrigialTotalSupply() external pure returns (uint256);

    // function getTotalSupply() external pure returns (uint256);

    // function editionsGetMaxPerOriginal() external pure returns (uint256);

    function editionsGetInfoFromOriginal(uint256 _originalId)
        external
        view
        returns (EditionInfo memory);

    function editionsGetInfoFromEdition(uint256 _editionId)
        external
        view
        returns (EditionInfo memory);

    // function editionsGetOriginalId(uint256 _id) external pure returns (uint256);

    // function editionsGetStartId(uint256 _originalId)
    //     external
    //     pure
    //     returns (uint256);

    // function editionsGetNextId(uint256 _originalId)
    //     external
    //     view
    //     returns (uint256);

    // function editionsGetMintCount(uint256 _originalId)
    //     external
    //     view
    //     returns (uint256);

    // function editionsGetIndexFromId(uint256 _id)
    //     external
    //     view
    //     returns (uint256);
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

/// @author therightchoyce.eth
/// @title  Upgradeable renderer interface
/// @notice This leaves room for us to change how we return token metadata and
///         unlocks future capability like fully on-chain storage.
interface ITheHydraRenderer {

    function tokenURI(uint256 _id) external view returns (string memory);
    // function tokenURI(uint256 _id, string calldata _renderType) external view returns (string memory);

    function getOnChainSVG(uint256 _id) external view returns (string memory);
    function getOnChainSVG_AsBase64(uint256 _id) external view returns (string memory);    
}