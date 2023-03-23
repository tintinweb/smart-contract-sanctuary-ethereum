/**
 *Submitted for verification at Etherscan.io on 2023-03-23
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

// ████████████████████████████████████████████████████████████████████████████████
// ████████████████████████████████████████████████████████████████████████████████
// ████████████████████████████████████████████████████████████████████████████████
// ████████████████████████████████████████████████████████████████████████████████
// ████████████████████████████████████████████████████████████████████████████████
// ████████████████████████████████████████████████████████████████████████████████
// ████████████████████████████████▓▀██████████████████████████████████████████████
// ██████████████████████████████████  ╙███████████████████████████████████████████
// ███████████████████████████████████    ╙████████████████████████████████████████
// ████████████████████████████████████      ╙▀████████████████████████████████████
// ████████████████████████████████████▌        ╙▀█████████████████████████████████
// ████████████████████████████████████▌           ╙███████████████████████████████
// ████████████████████████████████████▌            ███████████████████████████████
// ████████████████████████████████████▌         ▄█████████████████████████████████
// ████████████████████████████████████       ▄████████████████████████████████████
// ███████████████████████████████████▀   ,▄███████████████████████████████████████
// ██████████████████████████████████▀ ,▄██████████████████████████████████████████
// █████████████████████████████████▄▓█████████████████████████████████████████████
// ████████████████████████████████████████████████████████████████████████████████
// ████████████████████████████████████████████████████████████████████████████████
// ████████████████████████████████████████████████████████████████████████████████
// ████████████████████████████████████████████████████████████████████████████████
// ████████████████████████████████████████████████████████████████████████████████
// ████████████████████████████████████████████████████████████████████████████████

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

// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

contract Pass is ERC721, Ownable {
    //////////////////////////////////////////////////////////////////////
    // ERRORS
    //////////////////////////////////////////////////////////////////////
    error DoesNotExist(); // Custom error for when a token does not exist
    error Unauthorized(); // Custom error for unauthorized access
    error AlreadyTaken(); // Custom error for when a token is already taken
    error AddressAlreadyClaimed(); // Custom error for when an address has already claimed a token
    error AlreadyClaimed(); // Custom error for when a token has already been claimed
    error InvalidLength(); // Custom error for when a username is an invalid length
    error InvalidFirstOrLastCharacter(); // Custom error for when a username starts or ends with an underscore
    error InvalidCharacter(); // Custom error for when a username contains an invalid character

    event DefaultUsernameSet(address indexed user, uint256 indexed tokenId); // Event emitted when a user sets their default username
    event PassMinted(address indexed user, uint256 indexed passId, string username, PassType passType, address invitedBy); // Event emitted when a user claims a token

    //////////////////////////////////////////////////////////////////////
    // TYPES
    //////////////////////////////////////////////////////////////////////
    enum PassType {
        // Custom enum to represent the type of token
        GENESIS, // The first token
        CURATED, // A token invited by a curated user
        OPEN // A token claimed during open claim period
    }

    //////////////////////////////////////////////////////////////////////
    // CONSTANTS
    //////////////////////////////////////////////////////////////////////
    address public immutable genesis; // Address of the user who created the contract
    string internal constant TABLE_ENCODE = // Lookup table for base64 encoding
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"; 
    bytes internal constant TABLE_DECODE = // Lookup table for base64 decoding
        hex"0000000000000000000000000000000000000000000000000000000000000000"
        hex"00000000000000000000003e0000003f3435363738393a3b3c3d000000000000"
        hex"00000102030405060708090a0b0c0d0e0f101112131415161718190000000000"
        hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";

    //////////////////////////////////////////////////////////////////////
    // VARIABLES
    //////////////////////////////////////////////////////////////////////
    mapping(uint256 => string) public usernames; // Mapping of token IDs to usernames
    mapping(address => address) public invitedBy; // Mapping of addresses to the address of the user who invited them to claim a token
    mapping(address => uint256) public defaultUsername; // Mapping of addresses to the ID of the token associated with their default username
    mapping(address => bool) public claimed; // Mapping of addresses to a boolean indicating whether or not they have claimed a token
    mapping(uint => PassType) public passType; // Mapping of token IDs to their respective PassType
    bool public open; // Boolean indicating whether or not the contract is currently allowing open claims

    //////////////////////////////////////////////////////////////////////
    // CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////
    /**
    * @dev Constructor function for the Pass contract.
    * @param name Name of the ERC721 token.
    * @param symbol Symbol of the ERC721 token.
    * @param _genesis Address of the genesis user who can mint GENESIS passes.
    */
    constructor(
        string memory name,
        string memory symbol,
        address _genesis
    ) ERC721(name, symbol) { // Call the constructor of the parent contract ERC721
        genesis = _genesis; // Set the address of the user who created the contract
        invitedBy[genesis] = genesis; // Set the genesis user as the inviter of the genesis token
        transferOwnership(msg.sender); // Transfer ownership of the contract to the user who deployed it
    }

    //////////////////////////////////////////////////////////////////////
    // ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////////////
    /**
    * @dev Function to change the open claim status.
    * @param _open Boolean indicating whether or not the open claim feature is enabled.
    */
    function changeOpenClaimStatus(bool _open) public onlyOwner { // Function to change the status of open claims
        open = _open; // Set the open status of claims to the given value
    }

    //////////////////////////////////////////////////////////////////////
    // USERNAME FUNCTIONS
    //////////////////////////////////////////////////////////////////////
    /**
    * @dev Function to set the default username for a user.
    * @param id ID of the token to set the default username for.
    */
    function setDefaultUsername(uint256 id) public { // Function to set the default username associated with a given token ID
        if (_ownerOf[id] != msg.sender) revert Unauthorized(); // Check if the caller of the function is the owner of the token
        defaultUsername[msg.sender] = id; // Set the default username of the caller to the given ID

        emit DefaultUsernameSet(msg.sender, id);
    }

    /**
    * @dev Function to validate a username.
    * @param username Username to validate.
    */
    function validateUsername(string memory username) public pure {
        // make it so first or last character cant be underscore
        uint256 usernameLength = bytes(username).length;

        if (usernameLength < 3 || usernameLength > 15) revert InvalidLength();
        bytes1 firstByte = bytes(username)[0];
        bytes1 lastByte = bytes(username)[usernameLength - 1];
        if (firstByte == "_" || lastByte == "_")
            revert InvalidFirstOrLastCharacter();

        for (uint256 i = 0; i < usernameLength; ) {
            bytes1 char = bytes(username)[i];
            if (
                !(char >= 0x30 && char <= 0x39) && // 9-0
                !(char >= 0x61 && char <= 0x7A) && // a-z
                !(char == 0x5F) // _ underscore
            ) {
                revert InvalidCharacter();
            }
            unchecked {
                ++i;
            }
        }
    }

    //////////////////////////////////////////////////////////////////////
    // CLAIM FUNCTIONS
    //////////////////////////////////////////////////////////////////////
    /**
    * @dev Function to check the eligibility of a user to claim a token.
    * @param id ID of the token to check.
    * @param _callingOpenClaim Boolean indicating whether or not the open claim feature is enabled.
    */
    function checkEligibility(uint id, bool _callingOpenClaim) internal view { // Function to check eligibility to claim a token
        if (_callingOpenClaim)
            if (!open) revert Unauthorized(); // Check that open claims are currently allowed
        if (claimed[msg.sender]) revert AddressAlreadyClaimed(); // Check that the caller has not already claimed a token
        if (_ownerOf[id] != address(0)) revert AlreadyTaken(); // Check that the token has not already been claimed
    }

    /**
    * @dev Function for users to claim a token using the open claim feature.
    * @param _username Username to claim the token with.
    */
    function openClaim(string memory _username) public { // Function to claim a token during the open claim period
        uint256 id = uint(keccak256(abi.encodePacked(_username))); // Generate a unique ID for the token based on the username
        checkEligibility(id, true); // Check the eligibility to claim the token
        validateUsername(_username); // Validate the given username

        mint(id, _username, address(this)); // Mint the token with the given ID, username, and no inviter
    }

    /**
    * @dev Verify a signature and return the address of who signed this message.
    * @param _address The address being signed.
    * @param _signature The signature as a byte array.
    * @return An address indicating who signed the message.
    */
    function verifySignature(address _address, bytes memory _signature) public pure returns (address) {
        // Make sure the signature has the correct length
        require(_signature.length == 65, "Invalid signature length");
        // Get the hash of the message being signed
        bytes32 messageHash = getMessageHash(_address);

        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            // first 32 bytes, after the length prefix
            r := mload(add(_signature, 32))
            // second 32 bytes
            s := mload(add(_signature, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(_signature, 96)))
        }

        // Recover the address that signed the message and check if it matches the calling address
        return recoverSigner(messageHash, v, r, s);
    }

    /**
    * @dev Get the hash of an address.
    * @param _address The address to hash.
    * @return The hash of the address.
    */
    function getMessageHash(address _address) public pure returns (bytes32) {
        // Hash the address using keccak256
        return keccak256(abi.encodePacked(_address));
    }

    /**
    * @dev Recover the address that signed a message.
    * @param _messageHash The hash of the signed message.
    * @param _v The recovery identifier (0 or 1).
    * @param _r The x-coordinate of the point on the elliptic curve that represents the signature.
    * @param _s The signature value.
    * @return The address of the signer.
    */
    function recoverSigner(bytes32 _messageHash, uint8 _v, bytes32 _r, bytes32 _s) public pure returns (address) {
        // Add prefix to message hash as per EIP-191 standard
        bytes32 prefixedHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash));
        // Recover the address that signed the message using ecrecover
        return ecrecover(prefixedHash, _v, _r, _s);
    }

    /**
    * @dev Function for invited users to claim a token.
    * @param _username Username to claim the token with.
    * @param _signature Value of the signature.
    */
    function claimInvitation(
        string memory _username,
        bytes memory _signature
    ) public { // Function to claim a token using an invitation
        address signer = verifySignature(msg.sender, _signature);
        if (invitedBy[signer] == address(0)) revert Unauthorized(); // Check that the signer is a valid inviter
        uint256 id = uint(keccak256(abi.encodePacked(_username))); // Generate a unique ID for the token based on the username
        checkEligibility(id, false); // Check the eligibility to claim the token
        validateUsername(_username); // Validate the given username
        mint(id, _username, signer); // Mint the token with the given ID, username, and inviter
    }

    /**
    * @dev Function to mint a token.
    * @param id ID of the token to mint.
    * @param _username Username to mint the token with.
    * @param _invitedBy Address of the user who invited the token owner.
    */
    function mint(
        uint id,
        string memory _username,
        address _invitedBy
    ) private { // Function to mint a new token
        _mint(msg.sender, id); // Mint the token to the caller of the function
        usernames[id] = _username; // Set the username associated with the token ID
        defaultUsername[msg.sender] = id; // Set the default username of the caller to the given ID
        claimed[msg.sender] = true; // Set the claimed status of the caller to true
        invitedBy[msg.sender] = _invitedBy; // Set the inviter of the caller to the given address
        if (_invitedBy == genesis) { // If the inviter is the genesis address, set the pass type to GENESIS
            passType[id] = PassType.GENESIS;
        } else if (_invitedBy != address(this) || _invitedBy != address(0)) { // If the inviter is not the genesis address and not zero, set the pass type to CURATED
            passType[id] = PassType.CURATED;
        } else { // Otherwise, set the pass type to OPEN
            passType[id] = PassType.OPEN;
        }

        emit PassMinted(msg.sender, id, _username, passType[id], _invitedBy); // Emit the PassClaimed event
    }

    //////////////////////////////////////////////////////////////////////
    // METADATA FUNCTIONS
    //////////////////////////////////////////////////////////////////////
    /**
    * @dev Function to get the URI of a token.
    * @param id ID of the token to get the URI of.
    * @return The URI of the token.
    */
    function tokenURI(uint256 id) public view override returns (string memory) { // Function to get the metadata URI for a token
        address owner = _ownerOf[id]; // Get the owner of the token
        if (owner == address(0)) revert DoesNotExist(); // Check that the token exists
        if (passType[id] == PassType.GENESIS) { // If the pass type is GENESIS, set the background color to #FF4E00 and the font color to #000000
            return nftMetadata(usernames[id], "GENESIS", "#FF4F00", "#000000");
        }
        if (passType[id] == PassType.CURATED) { // If the pass type is CURATED, set the background color to #000000 and the font color to #FFFFFF
            return nftMetadata(usernames[id], "CURATED", "#000000", "#FFFFFF");
        }
        return nftMetadata(usernames[id], "OPEN", "#FFFFFF", "#000000"); // Otherwise, set the background color to #FFFFFF and the font color to #000000
    }

    /**
    * @dev Function to generate the metadata for a token.
    * @param username Username of the token.
    * @param _passType Type of the token.
    * @param backgroundColor Background color of the token.
    * @param fontColor Font color of the token.
    * @return The metadata for the token.
    */
    function nftMetadata(
        string memory username,
        string memory _passType,
        string memory backgroundColor,
        string memory fontColor
    ) internal pure returns (string memory) { // Function to generate the metadata for a token
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    base64Encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"',
                                username, // Set the name of the token to the given username
                                '.glass", "description":"',
                                "Glass passes are special assets that signify usernames, ownership, and the power to give others access to join the protocol.",
                                '", "image": "',
                                svg(username, backgroundColor, fontColor), // Set the image of the token to the SVG generated by the svg() function
                                '", "attributes": [',
                                '{"trait_type": "Pass Type", "value": "',
                                _passType, // Set the pass type attribute to the given pass type
                                '"}',
                                "]}"
                            )
                        )
                    )
                )
            );
    }

    /**
    * @dev Function to generate the SVG for a token.
    * @param username Username of the token.
    * @param backgroundColor Background color of the token.
    * @param fontColor Font color of the token.
    * @return The SVG for the token.
    */
    function svg(
        string memory username,
        string memory backgroundColor,
        string memory fontColor
    ) internal pure returns (string memory) { // Function to generate an SVG for a token
        return
            string(
                abi.encodePacked(
                    "data:image/svg+xml;base64,",
                    base64Encode(
                        bytes(
                            abi.encodePacked(
                                '<svg width="512" height="512" viewBox="0 0 512 512" fill="none" xmlns="http://www.w3.org/2000/svg">',
                                '<rect width="512" height="512" fill="',
                                backgroundColor, // Set the background color of the SVG to the given color
                                '"/>'
                                '<path d="M250.3 410C250.3 418.982 246.746 427.113 241 433L268.498 412.982C270.501 411.524 270.501 408.477 268.498 407.018L241 387C246.746 392.887 250.3 401.018 250.3 410Z" fill="',
                                fontColor, // Set the font color of the SVG to the given color
                                '"/>'
                                '<text font-family="sans-serif" font-weight="bold" y="50%" x="50%" dominant-baseline="middle" text-anchor="middle" font-size="40" fill="',
                                fontColor, // Set the font color of the text to the given color
                                '">',
                                username, // Set the text of the SVG to the given username
                                "</text>",
                                "</svg>"
                            )
                        )
                    )
                )
            );
    }

    //////////////////////////////////////////////////////////////////////
    // UTILITY FUNCTIONS
    //////////////////////////////////////////////////////////////////////
    /**
    * @dev Function to encode bytes as base64.
    * @param data The bytes to encode.
    * @return The base64 encoded string.
    */
    function base64Encode(
        bytes memory data
    ) internal pure returns (string memory) {
        if (data.length == 0) return "";

        // load the table into memory
        string memory table = TABLE_ENCODE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {

            } lt(dataPtr, endPtr) {

            } {
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(
                    resultPtr,
                    mload(add(tablePtr, and(shr(18, input), 0x3F)))
                )
                resultPtr := add(resultPtr, 1)
                mstore8(
                    resultPtr,
                    mload(add(tablePtr, and(shr(12, input), 0x3F)))
                )
                resultPtr := add(resultPtr, 1)
                mstore8(
                    resultPtr,
                    mload(add(tablePtr, and(shr(6, input), 0x3F)))
                )
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }
        }

        return result;
    }
}