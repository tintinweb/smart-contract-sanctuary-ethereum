// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;
// Credit to @Miguel Piedrafita for the SoulBound NFT contract skeleton

import "@openzeppelin/contracts/access/Ownable.sol";

/// @title PrivateSoulMinter
/// @author Enrico Bottazzi
/// @notice Barebones contract to mint ZK SBT

contract PrivateSoulMinter is Ownable{
    /// @notice Thrown when trying to transfer a Soulbound token
    error Soulbound();

    /// @notice Emitted when minting a ZK SBT
    /// @param from Who the token comes from. Will always be address(0)
    /// @param to The token recipient
    /// @param id The ID of the minted token
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed id
    );

    /// @notice The symbol for the token
    string public constant symbol = "SOUL";

    /// @notice The name for the token
    string public constant name = "Soulbound NFT";

    /// @notice Get the metadata URI for a certain tokenID
    mapping(uint256 => string) public tokenURI;

    /// @notice Get the hash of the claim metadata for a certain tokenID
    mapping(uint256 => bytes32) public claimSignatureHash;

    /// @notice Get the owner of a certain tokenID
    mapping(uint256 => address) public ownerOf;

    /// @notice Get how many SoulMinter NFTs a certain user owns
    mapping(address => uint256) public balanceOf;

    /// @dev Counter for the next tokenID, defaults to 1 for better gas on first mint
    uint256 internal nextTokenId = 1;

    constructor() payable {}

    /// @notice This function was disabled to make the token Soulbound. Calling it will revert
    function approve(address, uint256) public virtual {
        revert Soulbound();
    }

    /// @notice This function was disabled to make the token Soulbound. Calling it will revert
    function isApprovedForAll(address, address) public pure {
        revert Soulbound();
    }

    /// @notice This function was disabled to make the token Soulbound. Calling it will revert
    function getApproved(uint256) public pure {
        revert Soulbound();
    }

    /// @notice This function was disabled to make the token Soulbound. Calling it will revert
    function setApprovalForAll(address, bool) public virtual {
        revert Soulbound();
    }

    /// @notice This function was disabled to make the token Soulbound. Calling it will revert
    function transferFrom(
        address,
        address,
        uint256
    ) public virtual {
        revert Soulbound();
    }

    /// @notice This function was disabled to make the token Soulbound. Calling it will revert
    function safeTransferFrom(
        address,
        address,
        uint256
    ) public virtual {
        revert Soulbound();
    }

    /// @notice This function was disabled to make the token Soulbound. Calling it will revert
    function safeTransferFrom(
        address,
        address,
        uint256,
        bytes calldata
    ) public virtual {
        revert Soulbound();
    }

    function supportsInterface(bytes4 interfaceId) public pure returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /// @notice Mint a new Soulbound NFT to `to`
    /// @param to The recipient of the NFT
    /// @param metaURI The URL to the token metadata
    function mint(address to, string calldata metaURI, bytes32 claimHashMetadata) public {

        require(balanceOf[to] < 1, "You can only have one token associated to your soul");

        unchecked {
            balanceOf[to]++;
        }

        ownerOf[nextTokenId] = to;
        tokenURI[nextTokenId] = metaURI;
        claimSignatureHash[nextTokenId] = claimHashMetadata;

        emit Transfer(address(0), to, nextTokenId++);
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