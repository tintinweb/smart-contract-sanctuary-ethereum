// SPDX-License-Identifier: GPL-3.0

/**
  @title CapsuleToken

  @author peri

  @notice Each Capsule token has a unique color and a custom text rendered as a SVG. The text and font for a Capsule can be updated at any time by its owner.

  @dev `bytes3` type is used to store the RGB hex-encoded color that is unique to each Capsule. 

  `bytes32[8]` type is used to store 8 lines of 16 text characters, where each line contains 16 2-byte hexadecimal unicodes packed into a bytes32 value. 2 bytes is large enough to hex-encode the unicode value of every character in the Basic Multilingual Plane (BMP).

  To avoid high gas costs, text isn't validated when minting or editing, meaning Capsule text could contain characters that are unsupported by the Capsules Typeface. Instead, we rely on the Renderer contract to render a safe image even if the Capsule text is invalid.
 */

pragma solidity ^0.8.8;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./ERC721A.sol";
import "./interfaces/ICapsuleMetadata.sol";
import "./interfaces/ICapsuleRenderer.sol";
import "./interfaces/ICapsuleToken.sol";
import "./interfaces/ITypeface.sol";

/*                                                                                */
/*              000    000   0000    0000  0   0  0      00000   0000             */
/*             0   0  0   0  0   0  0      0   0  0      0      0                 */
/*             0      00000  0000    000   0   0  0      0000    000              */
/*             0   0  0   0  0          0  0   0  0      0          0             */
/*              000   0   0  0      0000    000   00000  00000  0000              */
/*                                                                                */

error CapsuleLocked();
error ColorAlreadyMinted(uint256 capsuleId);
error InvalidColor();
error InvalidFontForRenderer(address renderer);
error InvalidRenderer();
error NotCapsuleOwner(address owner);
error NotCapsulesTypeface();
error PureColorNotAllowed();
error ValueBelowMintPrice();

contract CapsuleToken is
    ICapsuleToken,
    ERC721A,
    IERC2981,
    Ownable,
    Pausable,
    ReentrancyGuard
{
    /* -------------------------------------------------------------------------- */
    /*       0   0   000   0000   00000  00000  00000  00000  0000    0000        */
    /*       00 00  0   0  0   0    0    0        0    0      0   0  0            */
    /*       0 0 0  0   0  0   0    0    00000    0    00000  0000    000         */
    /*       0   0  0   0  0   0    0    0        0    0      0 0        0        */
    /*       0   0   000   0000   00000  0      00000  00000  0  0   0000         */
    /* -------------------------------------------------------------------------- */
    /* -------------------------------- MODIFIERS ------------------------------- */
    /* -------------------------------------------------------------------------- */

    /// @notice Require that the value sent is at least MINT_PRICE.
    modifier requireMintPrice() {
        if (msg.value < MINT_PRICE) revert ValueBelowMintPrice();
        _;
    }

    /// @notice Require that the font is valid for a given renderer.
    modifier onlyValidFontForRenderer(Font memory font, address renderer) {
        if (!isValidFontForRenderer(font, renderer))
            revert InvalidFontForRenderer(renderer);
        _;
    }

    /// @notice Require that the font is valid for a given renderer.
    modifier onlyValidRenderer(address renderer) {
        if (!isValidRenderer(renderer)) revert InvalidRenderer();
        _;
    }

    /// @notice Require that the color is valid and unminted.
    modifier onlyMintableColor(bytes3 color) {
        uint256 capsuleId = tokenIdOfColor[color];
        if (_exists(capsuleId)) revert ColorAlreadyMinted(capsuleId);
        if (!isValidColor(color)) revert InvalidColor();
        _;
    }

    /// @notice Require that the color is not pure.
    modifier onlyImpureColor(bytes3 color) {
        if (isPureColor(color)) revert PureColorNotAllowed();
        _;
    }

    /// @notice Require that the sender is the CapsulesTypeface contract.
    modifier onlyCapsulesTypeface() {
        if (msg.sender != capsulesTypeface) revert NotCapsulesTypeface();
        _;
    }

    /// @notice Require that the Capsule is unlocked.
    modifier onlyUnlockedCapsule(uint256 capsuleId) {
        if (isLocked(capsuleId)) revert CapsuleLocked();
        _;
    }

    /// @notice Require that the sender owns the Capsule.
    modifier onlyCapsuleOwner(uint256 capsuleId) {
        address owner = ownerOf(capsuleId);
        if (owner != msg.sender) revert NotCapsuleOwner(owner);
        _;
    }

    /* -------------------------------------------------------------------------- */
    /*  000    000   0   0   0000  00000  0000   0   0   000   00000  000   0000  */
    /* 0   0  0   0  00  0  0        0    0   0  0   0  0   0    0   0   0  0   0 */
    /* 0      0   0  0 0 0   000     0    0000   0   0  0        0   0   0  0000  */
    /* 0   0  0   0  0  00      0    0    0  0   0   0  0   0    0   0   0  0  0  */
    /*  000    000   0   0  0000     0    0   0   000    000     0    000   0   0 */
    /* -------------------------------------------------------------------------- */
    /* ------------------------------- CONSTRUCTOR ------------------------------ */
    /* -------------------------------------------------------------------------- */

    constructor(
        address _capsulesTypeface,
        address _defaultRenderer,
        address _capsuleMetadata,
        address _feeReceiver,
        bytes3[] memory _pureColors,
        uint256 _royalty
    ) ERC721A("Capsules", "CAPS") {
        capsulesTypeface = _capsulesTypeface;

        _setDefaultRenderer(_defaultRenderer);
        _setCapsuleMetadata(_capsuleMetadata);
        _setFeeReceiver(_feeReceiver);

        pureColors = _pureColors;
        emit SetPureColors(_pureColors);

        _setRoyalty(_royalty);

        _pause();
    }

    /* -------------------------------------------------------------------------- */
    /*       0   0   000   0000   00000   000   0000   0      00000   0000        */
    /*       0   0  0   0  0   0    0    0   0  0   0  0      0      0            */
    /*       0   0  00000  0000     0    00000  0000   0      0000    000         */
    /*        0 0   0   0  0  0     0    0   0  0   0  0      0          0        */
    /*         0    0   0  0   0  00000  0   0  0000   00000  00000  0000         */
    /* -------------------------------------------------------------------------- */
    /* -------------------------------- VARIABLES ------------------------------- */
    /* -------------------------------------------------------------------------- */

    /// Price to mint a Capsule
    uint256 public constant MINT_PRICE = 1e16; // 0.01 ETH

    /// CapsulesTypeface address
    address public immutable capsulesTypeface;

    /// Default CapsuleRenderer address
    address public defaultRenderer;

    /// CapsuleMetadata address
    address public capsuleMetadata;

    /// Capsule ID of a minted color
    mapping(bytes3 => uint256) public tokenIdOfColor;

    /// Array of pure colors
    bytes3[] public pureColors;

    /// Address to receive fees
    address public feeReceiver;

    /// Royalty amount out of 1000
    uint256 public royalty;

    /// Validity of a renderer address
    mapping(address => bool) internal _validRenderers;

    /// Text of a Capsule ID
    mapping(uint256 => bytes32[8]) internal _textOf;

    /// Color of a Capsule ID
    mapping(uint256 => bytes3) internal _colorOf;

    /// Font of a Capsule ID
    mapping(uint256 => Font) internal _fontOf;

    /// Renderer address of a Capsule ID
    mapping(uint256 => address) internal _rendererOf;

    /// Locked state of a Capsule ID
    mapping(uint256 => bool) internal _locked;

    /* -------------------------------------------------------------------------- */
    /*           00000  0   0  00000  00000  0000   0   0   000   0               */
    /*           0       0 0     0    0      0   0  00  0  0   0  0               */
    /*           0000     0      0    0000   0000   0 0 0  00000  0               */
    /*           0       0 0     0    0      0  0   0  00  0   0  0               */
    /*           00000  0   0    0    00000  0   0  0   0  0   0  00000           */
    /* -------------------------------------------------------------------------- */
    /* --------------------------- EXTERNAL FUNCTIONS --------------------------- */
    /* -------------------------------------------------------------------------- */

    /// @notice Mints a Capsule to sender, saving gas by not setting text.
    /// @param color Color of Capsule.
    /// @param font Font of Capsule.
    /// @return capsuleId ID of minted Capsule.
    function mint(bytes3 color, Font calldata font)
        external
        payable
        requireMintPrice
        onlyImpureColor(color)
        nonReentrant
        returns (uint256)
    {
        return _mintCapsule(msg.sender, color, font);
    }

    /// @notice Mint a Capsule to sender while setting its text.
    /// @param color Color of Capsule.
    /// @param font Font of Capsule.
    /// @param text Text of Capsule.
    /// @return capsuleId ID of minted Capsule.
    function mintWithText(
        bytes3 color,
        Font calldata font,
        bytes32[8] calldata text
    )
        external
        payable
        whenNotPaused
        requireMintPrice
        onlyMintableColor(color)
        onlyImpureColor(color)
        onlyValidFontForRenderer(font, defaultRenderer)
        nonReentrant
        returns (uint256 capsuleId)
    {
        address to = msg.sender;

        _mint(to, 1, new bytes(0), false);

        capsuleId = _storeNewCapsuleData(color, font);

        _textOf[capsuleId] = text;

        emit MintCapsule(capsuleId, to, color);
    }

    /// @notice Allows the CapsulesTypeface to mint a pure color Capsule.
    /// @param to Address to receive Capsule.
    /// @param font Font of Capsule.
    /// @return capsuleId ID of minted Capsule.
    function mintPureColorForFont(address to, Font calldata font)
        external
        onlyCapsulesTypeface
        nonReentrant
        returns (uint256)
    {
        return _mintCapsule(to, pureColorForFontWeight(font.weight), font);
    }

    /// @notice Return token URI for Capsule, using the CapsuleMetadata contract.
    /// @param capsuleId ID of Capsule token.
    /// @return metadata Metadata string for Capsule.
    function tokenURI(uint256 capsuleId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(capsuleId), "ERC721A: URI query for nonexistent token");

        return
            ICapsuleMetadata(capsuleMetadata).metadataOf(
                capsuleOf(capsuleId),
                svgOf(capsuleId)
            );
    }

    /// @notice Return SVG image from the Capsule's renderer.
    /// @param capsuleId ID of Capsule token.
    /// @return svg Encoded SVG image of Capsule.
    function svgOf(uint256 capsuleId) public view returns (string memory) {
        return
            ICapsuleRenderer(rendererOf(capsuleId)).svgOf(capsuleOf(capsuleId));
    }

    /// @notice Returns all data for Capsule.
    /// @param capsuleId ID of Capsule.
    /// @return capsule Data for Capsule.
    function capsuleOf(uint256 capsuleId) public view returns (Capsule memory) {
        bytes3 color = _colorOf[capsuleId];

        return
            Capsule({
                id: capsuleId,
                font: _fontOf[capsuleId],
                text: _textOf[capsuleId],
                color: color,
                isPure: isPureColor(color),
                isLocked: _locked[capsuleId]
            });
    }

    /// @notice Check if color is pure.
    /// @param color Color to check.
    /// @return true True if color is pure.
    function isPureColor(bytes3 color) public view returns (bool) {
        bytes3[] memory _pureColors = pureColors;

        unchecked {
            for (uint256 i; i < _pureColors.length; i++) {
                if (color == _pureColors[i]) return true;
            }
        }

        return false;
    }

    /// @notice Returns the pure color matching a specific font weight.
    /// @param fontWeight Font weight to return pure color for.
    /// @return color Color for font weight.
    function pureColorForFontWeight(uint256 fontWeight)
        public
        view
        returns (bytes3)
    {
        // 100 == pureColors[0]
        // 200 == pureColors[1]
        // 300 == pureColors[2]
        // etc...
        return pureColors[(fontWeight / 100) - 1];
    }

    /// @notice Returns the color of Capsule.
    /// @param capsuleId ID of Capsule.
    /// @return color Color of Capsule.
    function colorOf(uint256 capsuleId) public view returns (bytes3) {
        return _colorOf[capsuleId];
    }

    /// @notice Returns the text of Capsule.
    /// @param capsuleId ID of Capsule.
    /// @return text Text of Capsule.
    function textOf(uint256 capsuleId) public view returns (bytes32[8] memory) {
        return _textOf[capsuleId];
    }

    /// @notice Returns the font of Capsule.
    /// @param capsuleId ID of Capsule.
    /// @return font Font of Capsule.
    function fontOf(uint256 capsuleId) public view returns (Font memory) {
        return _fontOf[capsuleId];
    }

    /// @notice Returns renderer of Capsule. If the Capsule has no renderer set, the default renderer is used.
    /// @param capsuleId ID of Capsule.
    /// @return renderer Address of renderer.
    function rendererOf(uint256 capsuleId) public view returns (address) {
        if (_rendererOf[capsuleId] != address(0)) return _rendererOf[capsuleId];

        return defaultRenderer;
    }

    /// @notice Check if Capsule is locked.
    /// @param capsuleId ID of Capsule.
    /// @return locked True if Capsule is locked.
    function isLocked(uint256 capsuleId) public view returns (bool) {
        return _locked[capsuleId];
    }

    /// @notice Check if font is valid for a CapsuleRenderer contract.
    /// @param renderer CapsuleRenderer contract address.
    /// @param font Font to check validity of.
    /// @return true True if font is valid.
    function isValidFontForRenderer(Font memory font, address renderer)
        public
        view
        returns (bool)
    {
        return ICapsuleRenderer(renderer).isValidFont(font);
    }

    /// @notice Check if address is a valid CapsuleRenderer contract.
    /// @param renderer Renderer address to check.
    /// @return true True if renderer is valid.
    function isValidRenderer(address renderer) public view returns (bool) {
        return _validRenderers[renderer];
    }

    /// @notice Check if color is valid.
    /// @dev A color is valid if all 3 bytes are divisible by 5 AND at least one byte == 255.
    /// @param color Color to check validity of.
    /// @return true True if color is valid.
    function isValidColor(bytes3 color) public pure returns (bool) {
        // At least one byte must equal 0xff (255)
        if (color[0] < 0xff && color[1] < 0xff && color[2] < 0xff) {
            return false;
        }

        // All bytes must be divisible by 5
        unchecked {
            for (uint256 i; i < 3; i++) {
                if (uint8(color[i]) % 5 != 0) return false;
            }
        }

        return true;
    }

    /// @notice Check if Capsule text is valid.
    /// @dev Checks validity using Capsule's renderer contract.
    /// @param capsuleId ID of Capsule.
    /// @return true True if Capsule text is valid.
    function isValidCapsuleText(uint256 capsuleId)
        external
        view
        returns (bool)
    {
        return
            ICapsuleRenderer(rendererOf(capsuleId)).isValidText(
                textOf(capsuleId)
            );
    }

    /// @notice Withdraws balance of this contract to the feeReceiver address.
    function withdraw() external nonReentrant {
        uint256 balance = address(this).balance;

        payable(feeReceiver).transfer(balance);

        emit Withdraw(feeReceiver, balance);
    }

    /// @notice EIP2981 royalty standard
    function royaltyInfo(uint256, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount)
    {
        return (payable(this), (salePrice * royalty) / 1000);
    }

    /// @notice EIP2981 standard Interface return. Adds to ERC721A Interface returns.
    /// @dev See {IERC165-supportsInterface}.
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC165, ERC721A)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /// @dev Allows contract to receive ETH
    receive() external payable {}

    /* -------------------------------------------------------------------------- */
    /*                      000   0   0  0   0  00000  0000                       */
    /*                     0   0  0   0  00  0  0      0   0                      */
    /*                     0   0  0   0  0 0 0  0000   0000                       */
    /*                     0   0  0 0 0  0  00  0      0  0                       */
    /*                      000    0 0   0   0  00000  0   0                      */
    /* -------------------------------------------------------------------------- */
    /* ------------------------ CAPSULE OWNER FUNCTIONS ------------------------- */
    /* -------------------------------------------------------------------------- */

    /// @notice Allows Capsule owner to edit the Capsule text, font, and locked state.
    /// @param capsuleId ID of Capsule.
    /// @param text New text for Capsule.
    /// @param font New font for Capsule.
    /// @param lock Lock capsule, preventing any future edits.
    function editCapsule(
        uint256 capsuleId,
        bytes32[8] calldata text,
        Font calldata font,
        bool lock
    ) public {
        _editCapsule(capsuleId, text, font, lock);
    }

    /// @notice Allows Capsule owner to lock a Capsule, preventing any future edits.
    /// @param capsuleId ID of Capsule to lock.
    function lockCapsule(uint256 capsuleId) external {
        _lockCapsule(capsuleId);
    }

    /// @notice Allows Capsule owner to set its renderer contract. If renderer is the zero address, the Capsule will use the default renderer.
    /// @dev Does not check validity of the current Capsule text or font with the new renderer.
    /// @param capsuleId ID of Capsule.
    /// @param renderer Address of new renderer.
    function setRendererOf(uint256 capsuleId, address renderer)
        external
        onlyCapsuleOwner(capsuleId)
        onlyValidRenderer(renderer)
    {
        _rendererOf[capsuleId] = renderer;

        emit SetRendererOf(capsuleId, renderer);
    }

    /// @notice Burns a Capsule.
    /// @param capsuleId ID of Capsule to burn.
    function burn(uint256 capsuleId) external onlyCapsuleOwner(capsuleId) {
        _burn(capsuleId);
    }

    /* -------------------------------------------------------------------------- */
    /*                      000   0000   0   0  00000  0   0                      */
    /*                     0   0  0   0  00 00    0    00  0                      */
    /*                     00000  0   0  0 0 0    0    0 0 0                      */
    /*                     0   0  0   0  0   0    0    0  00                      */
    /*                     0   0  0000   0   0  00000  0   0                      */
    /* -------------------------------------------------------------------------- */
    /* ---------------------------- ADMIN FUNCTIONS ----------------------------- */
    /* -------------------------------------------------------------------------- */

    /// @notice Allows the owner of this contract to update the defaultCapsuleRenderer contract.
    /// @param renderer Address of new default defaultCapsuleRenderer contract.
    function setDefaultRenderer(address renderer) external onlyOwner {
        _setDefaultRenderer(renderer);
    }

    /// @notice Allows the owner of this contract to update the CapsuleMetadata contract.
    /// @param _capsuleMetadata Address of new default CapsuleMetadata contract.
    function setCapsuleMetadata(address _capsuleMetadata) external onlyOwner {
        _setCapsuleMetadata(_capsuleMetadata);
    }

    /// @notice Allows the owner of this contract to update the feeReceiver address.
    /// @param newFeeReceiver Address of new feeReceiver.
    function setFeeReceiver(address newFeeReceiver) external onlyOwner {
        _setFeeReceiver(newFeeReceiver);
    }

    /// @notice Allows the owner of this contract to update the royalty amount.
    /// @param royaltyAmount New royalty amount.
    function setRoyalty(uint256 royaltyAmount) external onlyOwner {
        _setRoyalty(royaltyAmount);
    }

    /// @notice Allows the contract owner to pause the contract.
    /// @dev Can only be called by the owner when the contract is unpaused.
    function pause() external override onlyOwner {
        _pause();
    }

    /// @notice Allows the contract owner to unpause the contract.
    /// @dev Can only be called by the owner when the contract is paused.
    function unpause() external override onlyOwner {
        _unpause();
    }

    /* -------------------------------------------------------------------------- */
    /*           00000  0   0  00000  00000  0000   0   0   000   0               */
    /*             0    00  0    0    0      0   0  00  0  0   0  0               */
    /*             0    0 0 0    0    0000   0000   0 0 0  00000  0               */
    /*             0    0  00    0    0      0  0   0  00  0   0  0               */
    /*           00000  0   0    0    00000  0   0  0   0  0   0  00000           */
    /* -------------------------------------------------------------------------- */
    /* --------------------------- INTERNAL FUNCTIONS --------------------------- */
    /* -------------------------------------------------------------------------- */

    /// @notice ERC721A override to start tokenId at 1 instead of 0.
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    /// @notice Mints a Capsule.
    /// @param to Address to receive capsule.
    /// @param color Color of Capsule.
    /// @param font Font of Capsule.
    /// @return capsuleId ID of minted Capsule.
    function _mintCapsule(
        address to,
        bytes3 color,
        Font calldata font
    )
        internal
        whenNotPaused
        onlyMintableColor(color)
        onlyValidFontForRenderer(font, defaultRenderer)
        returns (uint256 capsuleId)
    {
        _mint(to, 1, new bytes(0), false);

        capsuleId = _storeNewCapsuleData(color, font);

        emit MintCapsule(capsuleId, to, color);
    }

    function _editCapsule(
        uint256 capsuleId,
        bytes32[8] calldata text,
        Font calldata font,
        bool lock
    )
        internal
        onlyCapsuleOwner(capsuleId)
        onlyUnlockedCapsule(capsuleId)
        onlyValidFontForRenderer(font, rendererOf(capsuleId))
    {
        _textOf[capsuleId] = text;
        _fontOf[capsuleId] = font;

        emit EditCapsule(capsuleId);

        if (lock) _lockCapsule(capsuleId);
    }

    function _lockCapsule(uint256 capsuleId)
        internal
        onlyCapsuleOwner(capsuleId)
        onlyUnlockedCapsule(capsuleId)
    {
        _locked[capsuleId] = true;

        emit LockCapsule(capsuleId);
    }

    /// @notice Check if all lines of text are empty.
    /// @param text Text to check.
    /// @return true if text is empty.
    function _isEmptyText(bytes32[8] memory text) internal pure returns (bool) {
        for (uint256 i; i < 8; i++) {
            if (!_isEmptyLine(text[i])) return false;
        }
        return true;
    }

    /// @notice Check if line is empty.
    /// @dev Returns true if every byte of text is 0x00.
    /// @param line line to check.
    /// @return true if line is empty.
    function _isEmptyLine(bytes32 line) internal pure returns (bool) {
        bytes2[16] memory _line = _bytes32ToBytes2Array(line);
        for (uint256 i; i < 16; i++) {
            if (_line[i] != 0) return false;
        }
        return true;
    }

    /// @notice Format bytes32 type as array of bytes2
    /// @param b bytes32 value to convert to array
    /// @return a Array of bytes2
    function _bytes32ToBytes2Array(bytes32 b)
        internal
        pure
        returns (bytes2[16] memory a)
    {
        for (uint256 i; i < 16; i++) {
            a[i] = bytes2(abi.encodePacked(b[i * 2], b[i * 2 + 1]));
        }
    }

    function _setDefaultRenderer(address renderer) internal {
        defaultRenderer = renderer;

        _validRenderers[renderer] = true;

        emit SetDefaultRenderer(renderer);
    }

    function _setRoyalty(uint256 royaltyAmount) internal {
        require(royaltyAmount <= 1000, "Amount too high");

        royalty = royaltyAmount;

        emit SetRoyalty(royaltyAmount);
    }

    function _setFeeReceiver(address newFeeReceiver) internal {
        feeReceiver = newFeeReceiver;

        emit SetFeeReceiver(newFeeReceiver);
    }

    function _setCapsuleMetadata(address _capsuleMetadata) internal {
        capsuleMetadata = _capsuleMetadata;

        emit SetCapsuleMetadata(_capsuleMetadata);
    }

    function _storeNewCapsuleData(bytes3 color, Font memory font)
        private
        returns (uint256 capsuleId)
    {
        capsuleId = _currentIndex - 1;

        tokenIdOfColor[color] = capsuleId;
        _colorOf[capsuleId] = color;
        _fontOf[capsuleId] = font;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be payed in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/utils/Context.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/utils/introspection/ERC165.sol';

error ApprovalCallerNotOwnerNorApproved();
error ApprovalQueryForNonexistentToken();
error ApproveToCaller();
error ApprovalToCurrentOwner();
error BalanceQueryForZeroAddress();
error MintedQueryForZeroAddress();
error BurnedQueryForZeroAddress();
error AuxQueryForZeroAddress();
error MintToZeroAddress();
error MintZeroQuantity();
error OwnerIndexOutOfBounds();
error OwnerQueryForNonexistentToken();
error TokenIndexOutOfBounds();
error TransferCallerNotOwnerNorApproved();
error TransferFromIncorrectOwner();
error TransferToNonERC721ReceiverImplementer();
error TransferToZeroAddress();
error URIQueryForNonexistentToken();

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension. Built to optimize for lower gas during batch mints.
 *
 * Assumes serials are sequentially minted starting at _startTokenId() (defaults to 0, e.g. 0, 1, 2, 3..).
 *
 * Assumes that an owner cannot have more than 2**64 - 1 (max value of uint64) of supply.
 *
 * Assumes that the maximum token id cannot exceed 2**256 - 1 (max value of uint256).
 */
contract ERC721A is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Compiler will pack this into a single 256bit word.
    struct TokenOwnership {
        // The address of the owner.
        address addr;
        // Keeps track of the start time of ownership with minimal overhead for tokenomics.
        uint64 startTimestamp;
        // Whether the token has been burned.
        bool burned;
    }

    // Compiler will pack this into a single 256bit word.
    struct AddressData {
        // Realistically, 2**64-1 is more than enough.
        uint64 balance;
        // Keeps track of mint count with minimal overhead for tokenomics.
        uint64 numberMinted;
        // Keeps track of burn count with minimal overhead for tokenomics.
        uint64 numberBurned;
        // For miscellaneous variable(s) pertaining to the address
        // (e.g. number of whitelist mint slots used).
        // If there are multiple variables, please pack them into a uint64.
        uint64 aux;
    }

    // The tokenId of the next token to be minted.
    uint256 internal _currentIndex;

    // The number of tokens burned.
    uint256 internal _burnCounter;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to ownership details
    // An empty struct value does not necessarily mean the token is unowned. See ownershipOf implementation for details.
    mapping(uint256 => TokenOwnership) internal _ownerships;

    // Mapping owner address to address data
    mapping(address => AddressData) private _addressData;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _currentIndex = _startTokenId();
    }

    /**
     * To change the starting tokenId, please override this function.
     */
    function _startTokenId() internal view virtual returns (uint256) {
        return 0;
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     * @dev Burned tokens are calculated here, use _totalMinted() if you want to count just minted tokens.
     */
    function totalSupply() public view returns (uint256) {
        // Counter underflow is impossible as _burnCounter cannot be incremented
        // more than _currentIndex - _startTokenId() times
        unchecked {
            return _currentIndex - _burnCounter - _startTokenId();
        }
    }

    /**
     * Returns the total amount of tokens minted in the contract.
     */
    function _totalMinted() internal view returns (uint256) {
        // Counter underflow is impossible as _currentIndex does not decrement,
        // and it is initialized to _startTokenId()
        unchecked {
            return _currentIndex - _startTokenId();
        }
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view override returns (uint256) {
        if (owner == address(0)) revert BalanceQueryForZeroAddress();
        return uint256(_addressData[owner].balance);
    }

    /**
     * Returns the number of tokens minted by `owner`.
     */
    function _numberMinted(address owner) internal view returns (uint256) {
        if (owner == address(0)) revert MintedQueryForZeroAddress();
        return uint256(_addressData[owner].numberMinted);
    }

    /**
     * Returns the number of tokens burned by or on behalf of `owner`.
     */
    function _numberBurned(address owner) internal view returns (uint256) {
        if (owner == address(0)) revert BurnedQueryForZeroAddress();
        return uint256(_addressData[owner].numberBurned);
    }

    /**
     * Returns the auxillary data for `owner`. (e.g. number of whitelist mint slots used).
     */
    function _getAux(address owner) internal view returns (uint64) {
        if (owner == address(0)) revert AuxQueryForZeroAddress();
        return _addressData[owner].aux;
    }

    /**
     * Sets the auxillary data for `owner`. (e.g. number of whitelist mint slots used).
     * If there are multiple variables, please pack them into a uint64.
     */
    function _setAux(address owner, uint64 aux) internal {
        if (owner == address(0)) revert AuxQueryForZeroAddress();
        _addressData[owner].aux = aux;
    }

    /**
     * Gas spent here starts off proportional to the maximum mint batch size.
     * It gradually moves to O(1) as tokens get transferred around in the collection over time.
     */
    function ownershipOf(uint256 tokenId) internal view returns (TokenOwnership memory) {
        uint256 curr = tokenId;

        unchecked {
            if (_startTokenId() <= curr && curr < _currentIndex) {
                TokenOwnership memory ownership = _ownerships[curr];
                if (!ownership.burned) {
                    if (ownership.addr != address(0)) {
                        return ownership;
                    }
                    // Invariant:
                    // There will always be an ownership that has an address and is not burned
                    // before an ownership that does not have an address and is not burned.
                    // Hence, curr will not underflow.
                    while (true) {
                        curr--;
                        ownership = _ownerships[curr];
                        if (ownership.addr != address(0)) {
                            return ownership;
                        }
                    }
                }
            }
        }
        revert OwnerQueryForNonexistentToken();
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view override returns (address) {
        return ownershipOf(tokenId).addr;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : '';
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return '';
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public override {
        address owner = ERC721A.ownerOf(tokenId);
        if (to == owner) revert ApprovalToCurrentOwner();

        if (_msgSender() != owner && !isApprovedForAll(owner, _msgSender())) {
            revert ApprovalCallerNotOwnerNorApproved();
        }

        _approve(to, tokenId, owner);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view override returns (address) {
        if (!_exists(tokenId)) revert ApprovalQueryForNonexistentToken();

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public override {
        if (operator == _msgSender()) revert ApproveToCaller();

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, '');
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        _transfer(from, to, tokenId);
        if (to.isContract() && !_checkContractOnERC721Received(from, to, tokenId, _data)) {
            revert TransferToNonERC721ReceiverImplementer();
        }
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        return _startTokenId() <= tokenId && tokenId < _currentIndex &&
            !_ownerships[tokenId].burned;
    }

    function _safeMint(address to, uint256 quantity) internal {
        _safeMint(to, quantity, '');
    }

    /**
     * @dev Safely mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called for each safe transfer.
     * - `quantity` must be greater than 0.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(
        address to,
        uint256 quantity,
        bytes memory _data
    ) internal {
        _mint(to, quantity, _data, true);
    }

    /**
     * @dev Mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `quantity` must be greater than 0.
     *
     * Emits a {Transfer} event.
     */
    function _mint(
        address to,
        uint256 quantity,
        bytes memory _data,
        bool safe
    ) internal {
        uint256 startTokenId = _currentIndex;
        if (to == address(0)) revert MintToZeroAddress();
        if (quantity == 0) revert MintZeroQuantity();

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are incredibly unrealistic.
        // balance or numberMinted overflow if current value of either + quantity > 1.8e19 (2**64) - 1
        // updatedIndex overflows if _currentIndex + quantity > 1.2e77 (2**256) - 1
        unchecked {
            _addressData[to].balance += uint64(quantity);
            _addressData[to].numberMinted += uint64(quantity);

            _ownerships[startTokenId].addr = to;
            _ownerships[startTokenId].startTimestamp = uint64(block.timestamp);

            uint256 updatedIndex = startTokenId;
            uint256 end = updatedIndex + quantity;

            if (safe && to.isContract()) {
                do {
                    emit Transfer(address(0), to, updatedIndex);
                    if (!_checkContractOnERC721Received(address(0), to, updatedIndex++, _data)) {
                        revert TransferToNonERC721ReceiverImplementer();
                    }
                } while (updatedIndex != end);
                // Reentrancy protection
                if (_currentIndex != startTokenId) revert();
            } else {
                do {
                    emit Transfer(address(0), to, updatedIndex++);
                } while (updatedIndex != end);
            }
            _currentIndex = updatedIndex;
        }
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) private {
        TokenOwnership memory prevOwnership = ownershipOf(tokenId);

        bool isApprovedOrOwner = (_msgSender() == prevOwnership.addr ||
            isApprovedForAll(prevOwnership.addr, _msgSender()) ||
            getApproved(tokenId) == _msgSender());

        if (!isApprovedOrOwner) revert TransferCallerNotOwnerNorApproved();
        if (prevOwnership.addr != from) revert TransferFromIncorrectOwner();
        if (to == address(0)) revert TransferToZeroAddress();

        _beforeTokenTransfers(from, to, tokenId, 1);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId, prevOwnership.addr);

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as tokenId would have to be 2**256.
        unchecked {
            _addressData[from].balance -= 1;
            _addressData[to].balance += 1;

            _ownerships[tokenId].addr = to;
            _ownerships[tokenId].startTimestamp = uint64(block.timestamp);

            // If the ownership slot of tokenId+1 is not explicitly set, that means the transfer initiator owns it.
            // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
            uint256 nextTokenId = tokenId + 1;
            if (_ownerships[nextTokenId].addr == address(0)) {
                // This will suffice for checking _exists(nextTokenId),
                // as a burned slot cannot contain the zero address.
                if (nextTokenId < _currentIndex) {
                    _ownerships[nextTokenId].addr = prevOwnership.addr;
                    _ownerships[nextTokenId].startTimestamp = prevOwnership.startTimestamp;
                }
            }
        }

        emit Transfer(from, to, tokenId);
        _afterTokenTransfers(from, to, tokenId, 1);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        TokenOwnership memory prevOwnership = ownershipOf(tokenId);

        _beforeTokenTransfers(prevOwnership.addr, address(0), tokenId, 1);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId, prevOwnership.addr);

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as tokenId would have to be 2**256.
        unchecked {
            _addressData[prevOwnership.addr].balance -= 1;
            _addressData[prevOwnership.addr].numberBurned += 1;

            // Keep track of who burned the token, and the timestamp of burning.
            _ownerships[tokenId].addr = prevOwnership.addr;
            _ownerships[tokenId].startTimestamp = uint64(block.timestamp);
            _ownerships[tokenId].burned = true;

            // If the ownership slot of tokenId+1 is not explicitly set, that means the burn initiator owns it.
            // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
            uint256 nextTokenId = tokenId + 1;
            if (_ownerships[nextTokenId].addr == address(0)) {
                // This will suffice for checking _exists(nextTokenId),
                // as a burned slot cannot contain the zero address.
                if (nextTokenId < _currentIndex) {
                    _ownerships[nextTokenId].addr = prevOwnership.addr;
                    _ownerships[nextTokenId].startTimestamp = prevOwnership.startTimestamp;
                }
            }
        }

        emit Transfer(prevOwnership.addr, address(0), tokenId);
        _afterTokenTransfers(prevOwnership.addr, address(0), tokenId, 1);

        // Overflow not possible, as _burnCounter cannot be exceed _currentIndex times.
        unchecked {
            _burnCounter++;
        }
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(
        address to,
        uint256 tokenId,
        address owner
    ) private {
        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkContractOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
            return retval == IERC721Receiver(to).onERC721Received.selector;
        } catch (bytes memory reason) {
            if (reason.length == 0) {
                revert TransferToNonERC721ReceiverImplementer();
            } else {
                assembly {
                    revert(add(32, reason), mload(reason))
                }
            }
        }
    }

    /**
     * @dev Hook that is called before a set of serially-ordered token ids are about to be transferred. This includes minting.
     * And also called before burning one token.
     *
     * startTokenId - the first token id to be transferred
     * quantity - the amount to be transferred
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, `tokenId` will be burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}

    /**
     * @dev Hook that is called after a set of serially-ordered token ids have been transferred. This includes
     * minting.
     * And also called after one token has been burned.
     *
     * startTokenId - the first token id to be transferred
     * quantity - the amount to be transferred
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` has been
     * transferred to `to`.
     * - When `from` is zero, `tokenId` has been minted for `to`.
     * - When `to` is zero, `tokenId` has been burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _afterTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}
}

// SPDX-License-Identifier: GPL-3.0

/**
  @title ICapsuleMetadata

  @author peri

  @notice Interface for CapsuleMetadata contract
 */

pragma solidity ^0.8.8;

import "./ICapsuleToken.sol";

interface ICapsuleMetadata {
    function metadataOf(Capsule memory capsule, string memory image)
        external
        view
        returns (string memory);
}

// SPDX-License-Identifier: GPL-3.0

/**
  @title ICapsuleRenderer

  @author peri

  @notice Interface for CapsuleRenderer contract
 */

pragma solidity ^0.8.8;

import "./ICapsuleToken.sol";
import "./ITypeface.sol";

interface ICapsuleRenderer {
    function typeface() external view returns (address);

    function svgOf(Capsule memory capsule)
        external
        view
        returns (string memory);

    function isValidFont(Font memory font) external view returns (bool);

    function isValidText(bytes32[8] memory line) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0

/**
  @title ICapsuleToken

  @author peri

  @notice Interface for CapsuleToken contract
 */

pragma solidity ^0.8.8;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./ITypeface.sol";

struct Capsule {
    uint256 id;
    bytes3 color;
    Font font;
    bytes32[8] text;
    bool isPure;
    bool isLocked;
}

interface ICapsuleToken {
    event MintCapsule(
        uint256 indexed id,
        address indexed to,
        bytes3 indexed color
    );
    event SetDefaultRenderer(address renderer);
    event SetCapsuleMetadata(address metadata);
    event SetFeeReceiver(address receiver);
    event SetPureColors(bytes3[] colors);
    event SetRoyalty(uint256 royalty);
    event LockRenderer();
    event LockCapsule(uint256 indexed id);
    event EditCapsule(uint256 indexed id);
    event SetRendererOf(uint256 indexed id, address renderer);
    event Withdraw(address to, uint256 amount);

    function capsuleOf(uint256 capsuleId)
        external
        view
        returns (Capsule memory);

    function isPureColor(bytes3 color) external view returns (bool);

    function pureColorForFontWeight(uint256 font)
        external
        view
        returns (bytes3);

    function colorOf(uint256 capsuleId) external view returns (bytes3);

    function textOf(uint256 capsuleId)
        external
        view
        returns (bytes32[8] memory);

    function fontOf(uint256 capsuleId) external view returns (Font memory);

    function isLocked(uint256 capsuleId) external view returns (bool);

    function svgOf(uint256 capsuleId) external view returns (string memory);

    function mint(bytes3 color, Font calldata font)
        external
        payable
        returns (uint256);

    function mintWithText(
        bytes3 color,
        Font calldata font,
        bytes32[8] calldata text
    ) external payable returns (uint256);

    function mintPureColorForFont(address to, Font calldata font)
        external
        returns (uint256);

    function lockCapsule(uint256 capsuleId) external;

    function editCapsule(
        uint256 capsuleId,
        bytes32[8] calldata text,
        Font calldata font,
        bool lock
    ) external;

    function setRendererOf(uint256 capsuleId, address renderer) external;

    function setDefaultRenderer(address renderer) external;

    function burn(uint256 capsuleId) external;

    function isValidFontForRenderer(Font memory font, address renderer)
        external
        view
        returns (bool);

    function isValidColor(bytes3 color) external view returns (bool);

    function isValidCapsuleText(uint256 capsuleId) external view returns (bool);

    function isValidRenderer(address renderer) external view returns (bool);

    function withdraw() external;

    function setFeeReceiver(address _feeReceiver) external;

    function setRoyalty(uint256 _royalty) external;

    function pause() external;

    function unpause() external;
}

// SPDX-License-Identifier: MIT

/**
  @title ITypeface

  @author peri

  @notice Interface for Typeface contract
 */

pragma solidity ^0.8.8;

struct Font {
    uint256 weight;
    string style;
}

interface ITypeface {
    /// @notice Emitted when the source is set for a font.
    /// @param font The font the source has been set for.
    event SetSource(Font font);

    /// @notice Emitted when the source hash is set for a font.
    /// @param font The font the source hash has been set for.
    /// @param sourceHash The source hash that was set.
    event SetSourceHash(Font font, bytes32 sourceHash);

    /// @notice Returns the typeface name.
    function name() external view returns (string memory);

    /// @notice Check if typeface includes a glyph for a specific character code point.
    /// @dev 3 bytes supports all possible unicodes.
    /// @param codePoint Character code point.
    /// @return true True if supported.
    function supportsCodePoint(bytes3 codePoint) external view returns (bool);

    /// @notice Return source data of Font.
    /// @param font Font to return source data for.
    /// @return source Source data of font.
    function sourceOf(Font memory font) external view returns (bytes memory);

    /// @notice Checks if source data has been stored for font.
    /// @param font Font to check if source data exists for.
    /// @return true True if source exists.
    function hasSource(Font memory font) external view returns (bool);

    /// @notice Stores source data for a font.
    /// @param font Font to store source data for.
    /// @param source Source data of font.
    function setSource(Font memory font, bytes memory source) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}