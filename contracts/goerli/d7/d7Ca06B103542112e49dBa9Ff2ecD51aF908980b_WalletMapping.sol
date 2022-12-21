// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IWalletMapping.sol";
import "../interfaces/ICertificateSet.sol";

contract WalletMapping is IWalletMapping, Ownable {
    mapping(address => address) private _walletsToUsers;
    mapping(address => address) private _usersToWallets;
    address private constant ZERO_ADDRESS = address(0);

    /**
     * @notice Saves a liteWallet to a realWallet association
     * @dev Only callable by WalletMapping owner
     * @param liteWallet liteWallet address
     * @param realWallet realWallet address
     */
    function linkWallet(
        address liteWallet,
        address realWallet
    ) external onlyOwner {
        bool walletLinked = _walletsToUsers[liteWallet] != ZERO_ADDRESS;
        bool userLinked = _usersToWallets[realWallet] != ZERO_ADDRESS;
        if (walletLinked) revert WalletAlreadyLinked(realWallet);
        if (userLinked) revert WalletAlreadyLinked(liteWallet);
        _walletsToUsers[liteWallet] = realWallet;
        _usersToWallets[realWallet] = liteWallet;
    }

    /**
     * @notice Return an associated linked realWallet for a given liteWallet (if exists)
     * @param liteWallet liteWallet address
     * @return linked realWallet address if it exists, otherwise the initial liteWallet address
     */
    function getLinkedWallet(
        address liteWallet
    ) external view returns (address) {
        address linkedWallet = _walletsToUsers[liteWallet];
        return linkedWallet == ZERO_ADDRESS ? liteWallet : linkedWallet;
    }

    /**
     * @notice Return the liteWallet address for a given user's first name, last name, and phone number
     * @dev liteWallet address id derived from hashing a user's the first name, last name, and phone number. Input validation should happen on the front end.
     * @param firstName User's first name (lowercase)
     * @param lastName User's last name (lowercase)
     * @param phoneNumber User's phone number (only numbers, including country/area code, no special characters)
     * @return liteWallet User's liteWallet address
     */
    function getLiteWalletAddress(
        string memory firstName,
        string memory lastName,
        uint256 phoneNumber
    ) external pure returns (address liteWallet) {
        bytes memory firstNameBytes = bytes(firstName);
        bytes memory lastNameBytes = bytes(lastName);
        if (firstNameBytes.length > 31)
            revert StringLongerThan31Bytes(firstName);
        if (lastNameBytes.length > 31) revert StringLongerThan31Bytes(lastName);
        bytes32 userHash = keccak256(
            abi.encodePacked(
                bytes32(firstNameBytes),
                bytes32(lastNameBytes),
                phoneNumber
            )
        );
        liteWallet = address(uint160(uint256(userHash)));
    }

    // TODO: should have a return value to check
    /**
     * @notice Transition all owned certificates from a liteWallet to a realWallet for a set (array) of contracts
     * @dev Uses multicall pattern and has a few nested loops. If too many contracts/certificates are involved, it's best to split up into a few calls
     * @param from liteWallet to transition certificates from
     * @param to realWallet to transition certificates to
     * @param contracts Set of contracts to transition all certificates for
     */
    function transitionCertificatesByContracts(
        address from,
        address to,
        address[] memory contracts
    ) public {
        for (uint256 i = 0; i < contracts.length; i++) {
            address contractAddress = contracts[i];
            ICertificateSet(contractAddress).moveUserTokensToWallet(from, to);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

interface IWalletMapping {
    error UserAlreadyLinked(address userAddress);
    error WalletAlreadyLinked(address walletAddress);
    error StringLongerThan31Bytes(string str);

    function linkWallet(address userAddress, address walletAddress) external;

    function getLinkedWallet(
        address userAddress
    ) external view returns (address);

    function getLiteWalletAddress(
        string memory firstName,
        string memory lastName,
        uint256 phoneNumber
    ) external pure returns (address liteWallet);

    function transitionCertificatesByContracts(
        address from,
        address to,
        address[] memory contracts
    ) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

interface ICertificateSet {
    error IncorrectExpiry(address user, uint96 certificateType, uint256 expiry);
    error IncorrectBalance(address user, uint96 certificateType, uint256 balance);
    error NewCertificateTypeNotIncremental(uint96 certificateType, uint256 maxCertificateType);
    error ArrayParamsUnequalLength();
    error WalletNotLinked(address walletAddress);
    error SoulboundTokenNoSetApprovalForAll(address operator, bool approved);
    error SoulboundTokenNoIsApprovedForAll(address account, address operator);
    error SoulboundTokenNoSafeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes data
    );
    error SoulboundTokenNoSafeBatchTransferFrom(
        address from,
        address to,
        uint256[] ids,
        uint256[] amounts,
        bytes data
    );
    error ERC1155ReceiverNotImplemented();
    error ERC1155ReceiverRejectedTokens();

    event TransitionWallet(
        address indexed kycAddress,
        address indexed walletAddress
    );

    function setURI(string memory newuri) external;

    function setContractURI(string memory newuri) external;

    function expiryOf(uint256 tokenId) external view returns (uint256);

    function mint(
        address account,
        uint96 certificateType,
        uint256 expiryTimestamp,
        bytes32 certificateHash,
        address[] memory signers
    ) external returns (uint256 tokenId);

    function receiverSigning(
        uint256 tokenId, 
        bytes memory signature
    ) external;
    
    function approverSigning(
        uint256 tokenId, 
        bytes memory signature
    ) external;

    function mintBatch(
        address to,
        uint96[] memory certificateTypes,
        uint256[] memory expiryTimestamps,        
        bytes32[] memory certificateHash,
        address[][] memory signers
    ) external returns (uint256[] memory tokenIds);

    function revoke(
        address account,
        uint96 certificateType
    ) external returns (uint256 tokenId);

    function revokeBatch(
        address to,
        uint96[] memory certificateTypes
    ) external returns (uint256[] memory tokenIds);

    function moveUserTokensToWallet(
        address kycAddress,
        address walletAddress
    ) external;

    function encodeTokenId(
        uint96 certificateType,
        address account
    ) external pure returns (uint256 tokenId);

    function decodeTokenId(
        uint256 tokenId
    ) external pure returns (uint96 certificateType, address account);
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