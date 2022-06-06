// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @notice Minimal proxy library
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title OasisX NFT Launch Factory
 * @notice NFT Lauch Factory contract
 * @author OasisX Protocol | cryptoware.eth
 **/

/// @dev an interface to interact with the NFT721 base contract
interface IOasisXNFT721 {
    function initialize(
        string memory name_,
        string memory symbol_,
        string memory baseTokenURI,
        string memory notRevealedUri,
        bytes32 merkleRoot,
        address[] memory payees_,
        uint256[] memory shares_,
        uint256 maxTokenId,
        uint256 mintPrice,
        uint64 mintsPerAddressLimit,
        address _owner
    ) external;
}

/// @dev an interface to interact with the NFT1155 base contract
interface IOasisXNFT1155 {
    function initialize(
        string memory name_,
        string memory symbol_,
        string memory uri,
        bytes32 merkleRoot,
        address[] memory payees_,
        uint256[] memory shares_,
        uint256[] memory tokenIds,
        uint256[] memory maxSupplyPerToken,
        uint256 maxTokenId_,
        uint256 mintPrice,
        uint64 mintsPerAddressLimit,
        address _owner
    ) external;
}

contract OasisXLaunchFactory is Ownable, ReentrancyGuard {
    /// @notice cheaply clone contract functionality in an immutable way
    using Clones for address;

    /// @notice Base ERC721 address
    address public NFT721Base;

    /// @notice Base ERC1155 address
    address public NFT1155Base;

    /// @notice Address of protocol fee wallet;
    address public protocolAddress;

    /// @notice Protocol fee to charge
    uint256 public protocolFee;

    /// @notice 721 contracts mapped by owner address
    mapping(address => address[]) public clones721;

    /// @notice 1155 contracts mapped by owner address
    mapping(address => address[]) public clones1155;

    /// @notice Cloning events definition
    event New721Clone(address indexed _newClone, address indexed _owner);
    event New1155Clone(address indexed _newClone, address indexed _owner);

    receive() external payable {
        revert("OasisXNFT721: Please use Mint or Admin calls");
    }

    fallback() external payable {
        revert("OasisXNFT721: Please use Mint or Admin calls");
    }

    /**
     * @notice constructor
     * @param BaseNFT721 address of the Base 721 contract to be cloned
     * @param BaseNFT1155 address of the Base 1155 contract to be cloned
     * @param _protocolFee fee for the protocol
     * @param _protocolAddress address to send the fees to

     **/
    constructor(
        address BaseNFT721,
        address BaseNFT1155,
        uint256 _protocolFee,
        address _protocolAddress
    ) {
        NFT721Base = BaseNFT721;
        NFT1155Base = BaseNFT1155;
        protocolFee = _protocolFee;
        protocolAddress = _protocolAddress;
    }

    /**
     * @notice initializing the cloned contract
     * @param name_ the name of the EIP1155 Contract
     * @param symbol_ the token symbol
     * @param uri_ EIP1155-required Base URI
     * @param merkleRoot merkle tree root of the hashed whitelist addresses
     * @param payees_ the payees addresses that will receive minting funds
     * @param shares_ share per payee
     * @param tokenIds token Ids that has supply greater than 1
     * @param maxSupplyPerToken max token supply that can be minted
     * @param maxTokenId_ max token supply that can be minted
     * @param mintPrice_ initial mint price
     * @param mintsPerAddressLimit initial nft limit per address
     **/
    function create1155(
        string memory name_,
        string memory symbol_,
        string memory uri_,
        bytes32 merkleRoot,
        address[] memory payees_,
        uint256[] memory shares_,
        uint256[] memory tokenIds,
        uint256[] memory maxSupplyPerToken,
        uint256 maxTokenId_,
        uint256 mintPrice_,
        uint64 mintsPerAddressLimit
    ) external payable nonReentrant {
        require(msg.value == protocolFee, "ether sent mismatch");

        checkAndCollectFees(msg.value);

        address identicalChild = NFT1155Base.clone();

        clones1155[msg.sender].push(identicalChild);

        IOasisXNFT1155(identicalChild).initialize(
            name_,
            symbol_,
            uri_,
            merkleRoot,
            payees_,
            shares_,
            tokenIds,
            maxSupplyPerToken,
            maxTokenId_,
            mintPrice_,
            mintsPerAddressLimit,
            msg.sender
        );

        emit New1155Clone(identicalChild, msg.sender);
    }

    /**
     * @notice initializing the cloned contract
     * @param name_ the name of the EIP721 Contract
     * @param symbol_ the token symbol
     * @param baseTokenURI EIP721-required Base URI
     * @param notRevealedUri URI to hide NFTs during minting
     * @param merkleRoot merkle tree root of the hashed whitelist addresses
     * @param payees_ the payees addresses that will receive minting funds
     * @param shares_ share per payee
     * @param maxTokenId max token supply that can be minted
     * @param mintPrice initial mint price
     * @param mintsPerAddressLimit initial nft limit per address
     **/
    function create721(
        string memory name_,
        string memory symbol_,
        string memory baseTokenURI,
        string memory notRevealedUri,
        bytes32 merkleRoot,
        address[] memory payees_,
        uint256[] memory shares_,
        uint256 maxTokenId,
        uint256 mintPrice,
        uint64 mintsPerAddressLimit
    ) external payable nonReentrant {
        require(msg.value == protocolFee, "ether sent mismatch");

        checkAndCollectFees(msg.value);

        address identicalChild = NFT721Base.clone();

        clones721[msg.sender].push(identicalChild);

        IOasisXNFT721(identicalChild).initialize(
            name_,
            symbol_,
            baseTokenURI,
            notRevealedUri,
            merkleRoot,
            payees_,
            shares_,
            maxTokenId,
            mintPrice,
            mintsPerAddressLimit,
            msg.sender
        );

        emit New721Clone(identicalChild, msg.sender);
    }

    /**
     * @notice function returns cloned 721 contracts by owner address
     * @param _owner owner address
     **/
    function getClones721(address _owner)
        external
        view
        returns (address[] memory)
    {
        return clones721[_owner];
    }

    /**
     * @notice function returns cloned 1155 contracts by owner address
     * @param _owner owner address
     **/
    function getClones1155(address _owner)
        external
        view
        returns (address[] memory)
    {
        return clones1155[_owner];
    }

    /**
     * @notice Checks and collects protocol fees after cloning
     * @param amount protocol fee
     */
    function checkAndCollectFees(uint256 amount) internal {
        require(amount == protocolFee, "error AMOUNT NOT SAME AS FEE");
        /// @notice forward fund to Splitter contract using CALL to avoid 2300 stipend limit
        (bool success, ) = protocolAddress.call{value: amount}("");
        require(success, "OasisXNFT721: Failed to forward funds");
    }

    /**
     * @notice Owner can change protocol fee
     * @param amount amount of new protocol fee
     */
    function changeProtocolFee(uint256 amount) external onlyOwner {
        require(
            amount != protocolFee,
            "OasisXLaunchFactory: New Protocol fee cannot be the same"
        );
        protocolFee = amount * 1 ether;
    }

    /**
     * @notice Owner can change protocol address
     * @param addr address of new protocol
     */
    function changeProtocolAddress(address addr) external onlyOwner {
        require(
            addr != address(0),
            "OasisXLaunchFactory: New Protocol cannot be address 0"
        );
        require(
            addr != protocolAddress,
            "OasisXLaunchFactory: New Protocol cannot be address 0"
        );
        protocolAddress = addr;
    }

    /**
     * @notice Change 721 Base Contract
     * @param new_add address of new 721 Base contract
     */
    function change721Implementation(address new_add) external onlyOwner {
        require(
            new_add != address(0),
            "OasisXLaunchFactory: New 721 Base cannot be address 0"
        );
        require(
            new_add != NFT721Base,
            "OasisXLaunchFactory: New 721 Base address is the same"
        );
        NFT721Base = new_add;
    }

    /**
     * @notice Change 1155 Base Contract
     * @param new_add address of new 1155 Base Contract
     */
    function change1155Implementation(address new_add) external onlyOwner {
        require(
            new_add != address(0),
            "OasisXLaunchFactory: New 1155 Base cannot be address 0"
        );
        require(
            new_add != NFT1155Base,
            "OasisXLaunchFactory: New 1155 Base address cannot be the same"
        );
        NFT1155Base = new_add;
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
// OpenZeppelin Contracts v4.4.1 (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
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