/**
 *Submitted for verification at Etherscan.io on 2022-04-28
*/

// Sources flattened with hardhat v2.9.3 https://hardhat.org

// File @openzeppelin/contracts/utils/[email protected]


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


// File @openzeppelin/contracts/access/[email protected]


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

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


// File @openzeppelin/contracts/utils/introspection/[email protected]


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


// File @openzeppelin/contracts/interfaces/[email protected]


// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;


// File @openzeppelin/contracts/interfaces/[email protected]


// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

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


// File contracts/royalty/interfaces/IOwnable.sol


pragma solidity 0.8.12;

interface IOwnable {
    function transferOwnership(address newOwner) external;

    function owner() external view returns (address);

    function admin() external view returns (address);
}


// File contracts/exchange/interfaces/IRoyaltyFeeManager.sol

pragma solidity 0.8.12;

interface IRoyaltyFeeManager {
    function calculateRoyaltyFeeAndGetRecipient(
        address collection,
        uint256 tokenId,
        uint256 amount
    ) external view returns (address, uint256);

    function updateRoyaltyInfoForCollection(
        address collection,
        address setter,
        address receiver,
        uint256 fee
    ) external;

    function updateRoyaltyFeeLimit(uint256 _royaltyFeeLimit) external;

    function royaltyInfo(address collection, uint256 amount)
        external
        view
        returns (address, uint256);

    function royaltyFeeInfoCollection(address collection)
        external
        view
        returns (
            address,
            address,
            uint256
        );

    function setJumyTokenRoyalty(
        address collection,
        uint256 tokenId,
        address receiver,
        uint256 percentage
    ) external;
}


// File contracts/royalty/RoyaltyFeeManager.sol


pragma solidity 0.8.12;




/**
 * @title RoyaltyFeeManager
 * @notice It is a royalty fee registry for the LooksRare exchange.
 */
contract RoyaltyFeeManager is IRoyaltyFeeManager, Ownable {
    struct FeeInfo {
        address setter;
        address receiver;
        uint256 fee;
    }

    struct JumyCollectionTokenFeeInfo {
        address receiver;
        uint256 fee;
    }
    // ERC721 interfaceID
    bytes4 public constant INTERFACE_ID_ERC721 = 0x80ac58cd;

    // ERC1155 interfaceID
    bytes4 public constant INTERFACE_ID_ERC1155 = 0xd9b67a26;

    // ERC2981 interfaceID
    bytes4 public constant INTERFACE_ID_ERC2981 = 0x2a55205a;

    // Limit (if enforced for fee royalty in percentage (10,000 = 100%)
    uint256 public royaltyFeeLimit;

    bool public mutableRoyalty;

    mapping(address => FeeInfo) private _royaltyFeeInfoCollection;

    mapping(address => bool) public isRoyaltySetter;

    mapping(address => mapping(uint256 => JumyCollectionTokenFeeInfo))
        public jumyCollectionTokenFeeInfos;

    modifier onlyIfMutable() {
        require(!mutableRoyalty, "Royalty: Not mutable");
        _;
    }

    event NewRoyaltyFeeLimit(uint256 royaltyFeeLimit);
    event RoyaltyFeeUpdate(
        address indexed collection,
        address indexed setter,
        address indexed receiver,
        uint256 fee
    );

    /**
     * @notice Constructor
     * @param _royaltyFeeLimit new royalty fee limit (500 = 5%, 1,000 = 10%)
     */
    constructor(uint256 _royaltyFeeLimit) {
        require(_royaltyFeeLimit <= 3000, "Owner: Royalty fee limit too high");
        royaltyFeeLimit = _royaltyFeeLimit;
    }

    function changeMutability(bool state) external onlyOwner {
        require(mutableRoyalty != state, "Already in state");
        mutableRoyalty = state;
    }

    function setJumyTokenRoyalty(
        address collection,
        uint256 tokenId,
        address receiver,
        uint256 percentage
    ) external override {
        require(isRoyaltySetter[msg.sender], "Not Allowed");

        require(
            jumyCollectionTokenFeeInfos[collection][tokenId].receiver ==
                address(0),
            "RoyaltyManager: Already set"
        );

        jumyCollectionTokenFeeInfos[collection][
            tokenId
        ] = JumyCollectionTokenFeeInfo({fee: percentage, receiver: receiver});
    }

    function updateRoyaltySetter(address setter, bool state)
        external
        onlyOwner
    {
        isRoyaltySetter[setter] = state;
    }

    /**
     * @notice Update royalty info for collection if admin
     * @dev Only to be called if there is no setter address
     * @param collection address of the NFT contract
     * @param setter address that sets the receiver
     * @param receiver receiver for the royalty fee
     * @param fee fee (500 = 5%, 1,000 = 10%)
     */
    function updateRoyaltyInfoForCollectionIfAdmin(
        address collection,
        address setter,
        address receiver,
        uint256 fee
    ) external onlyIfMutable {
        require(
            !IERC165(collection).supportsInterface(INTERFACE_ID_ERC2981),
            "Admin: Must not be ERC2981"
        );
        require(
            msg.sender == IOwnable(collection).admin(),
            "Admin: Not the admin"
        );

        _updateRoyaltyInfoForCollectionIfOwnerOrAdmin(
            collection,
            setter,
            receiver,
            fee
        );
    }

    /**
     * @notice Update royalty info for collection if owner
     * @dev Only to be called if there is no setter address
     * @param collection address of the NFT contract
     * @param setter address that sets the receiver
     * @param receiver receiver for the royalty fee
     * @param fee fee (500 = 5%, 1,000 = 10%)
     */
    function updateRoyaltyInfoForCollectionIfOwner(
        address collection,
        address setter,
        address receiver,
        uint256 fee
    ) external onlyIfMutable {
        require(
            !IERC165(collection).supportsInterface(INTERFACE_ID_ERC2981),
            "Owner: Must not be ERC2981"
        );
        require(
            msg.sender == IOwnable(collection).owner(),
            "Owner: Not the owner"
        );

        _updateRoyaltyInfoForCollectionIfOwnerOrAdmin(
            collection,
            setter,
            receiver,
            fee
        );
    }

    /**
     * @notice Update royalty info for collection
     * @dev Only to be called if there msg.sender is the setter
     * @param collection address of the NFT contract
     * @param setter address that sets the receiver
     * @param receiver receiver for the royalty fee
     * @param fee fee (500 = 5%, 1,000 = 10%)
     */
    function updateRoyaltyInfoForCollectionIfSetter(
        address collection,
        address setter,
        address receiver,
        uint256 fee
    ) external onlyIfMutable {
        (address currentSetter, , ) = getRoyaltyFeeInfoCollection(collection);
        require(msg.sender == currentSetter, "Setter: Not the setter");

        _updateRoyaltyInfoForCollection(collection, setter, receiver, fee);
    }

    /**
     * @notice Update royalty info for collection
     * @dev Can only be called by contract owner (of this)
     * @param collection address of the NFT contract
     * @param setter address that sets the receiver
     * @param receiver receiver for the royalty fee
     * @param fee fee (500 = 5%, 1,000 = 10%)
     */
    function updateRoyaltyInfoForCollection(
        address collection,
        address setter,
        address receiver,
        uint256 fee
    ) external override onlyOwner {
        _updateRoyaltyInfoForCollection(collection, setter, receiver, fee);
    }

    /**
     * @notice Check royalty info for collection
     * @param collection collection address
     * @return (whether there is a setter (address(0 if not)),
     * Position
     * 0: Royalty setter is set in the registry
     * 1: ERC2981 and no setter
     * 2: setter can be set using owner()
     * 3: setter can be set using admin()
     * 4: setter cannot be set, nor support for ERC2981
     */
    function checkForCollectionSetter(address collection)
        external
        view
        returns (address, uint8)
    {
        (address currentSetter, , ) = getRoyaltyFeeInfoCollection(collection);

        if (currentSetter != address(0)) {
            return (currentSetter, 0);
        }

        try
            IERC165(collection).supportsInterface(INTERFACE_ID_ERC2981)
        returns (bool interfaceSupport) {
            if (interfaceSupport) {
                return (address(0), 1);
            }
        } catch {}

        try IOwnable(collection).owner() returns (address setter) {
            return (setter, 2);
        } catch {
            try IOwnable(collection).admin() returns (address setter) {
                return (setter, 3);
            } catch {
                return (address(0), 4);
            }
        }
    }

    /**
     * @notice Update information and perform checks before updating royalty fee registry
     * @param collection address of the NFT contract
     * @param setter address that sets the receiver
     * @param receiver receiver for the royalty fee
     * @param fee fee (500 = 5%, 1,000 = 10%)
     */
    function _updateRoyaltyInfoForCollectionIfOwnerOrAdmin(
        address collection,
        address setter,
        address receiver,
        uint256 fee
    ) internal {
        (address currentSetter, , ) = getRoyaltyFeeInfoCollection(collection);
        require(currentSetter == address(0), "Setter: Already set");

        require(
            (IERC165(collection).supportsInterface(INTERFACE_ID_ERC721) ||
                IERC165(collection).supportsInterface(INTERFACE_ID_ERC1155)),
            "Setter: Not ERC721/ERC1155"
        );

        _updateRoyaltyInfoForCollection(collection, setter, receiver, fee);
    }

    /**
     * @notice Calculate royalty fee and get recipient
     * @param collection address of the NFT contract
     * @param tokenId tokenId
     * @param amount amount to transfer
     */
    function calculateRoyaltyFeeAndGetRecipient(
        address collection,
        uint256 tokenId,
        uint256 amount
    ) external view override returns (address, uint256) {
        address jumyTokenReceiver = jumyCollectionTokenFeeInfos[collection][
            tokenId
        ].receiver;

        if (jumyTokenReceiver != address(0)) {
            uint256 royaltyPercentage = jumyCollectionTokenFeeInfos[collection][
                tokenId
            ].fee;

            return (jumyTokenReceiver, (amount * royaltyPercentage) / 10_000);
        }

        // 2. Check if there is a royalty info in the system
        (address receiver, uint256 royaltyAmount) = _royaltyInfo(
            collection,
            amount
        );

        // 3. If the receiver is address(0), fee is null, check if it supports the ERC2981 interface
        if ((receiver == address(0)) || (royaltyAmount == 0)) {
            if (IERC165(collection).supportsInterface(INTERFACE_ID_ERC2981)) {
                (receiver, royaltyAmount) = IERC2981(collection).royaltyInfo(
                    tokenId,
                    amount
                );
            }
        }
        return (receiver, royaltyAmount);
    }

    /**
     * @notice Update royalty info for collection
     * @param _royaltyFeeLimit new royalty fee limit (500 = 5%, 1,000 = 10%)
     */
    function updateRoyaltyFeeLimit(uint256 _royaltyFeeLimit)
        external
        override
        onlyOwner
    {
        require(_royaltyFeeLimit <= 9500, "Owner: Royalty fee limit too high");
        royaltyFeeLimit = _royaltyFeeLimit;

        emit NewRoyaltyFeeLimit(_royaltyFeeLimit);
    }

    /**
     * @notice Update royalty info for collection
     * @param collection address of the NFT contract
     * @param setter address that sets the receiver
     * @param receiver receiver for the royalty fee
     * @param fee fee (500 = 5%, 1,000 = 10%)
     */
    function _updateRoyaltyInfoForCollection(
        address collection,
        address setter,
        address receiver,
        uint256 fee
    ) internal {
        require(fee <= royaltyFeeLimit, "Registry: Royalty fee too high");
        _royaltyFeeInfoCollection[collection] = FeeInfo({
            setter: setter,
            receiver: receiver,
            fee: fee
        });

        emit RoyaltyFeeUpdate(collection, setter, receiver, fee);
    }

    /**
     * @notice Calculate royalty info for a collection address and a sale gross amount
     * @param collection collection address
     * @param amount amount
     * @return receiver address and amount received by royalty recipient
     */
    function royaltyInfo(address collection, uint256 amount)
        external
        view
        override
        returns (address, uint256)
    {
        return _royaltyInfo(collection, amount);
    }

    function _royaltyInfo(address collection, uint256 amount)
        private
        view
        returns (address, uint256)
    {
        return (
            _royaltyFeeInfoCollection[collection].receiver,
            (amount * _royaltyFeeInfoCollection[collection].fee) / 10_000
        );
    }

    /**
     * @notice View royalty info for a collection address
     * @param collection collection address
     */
    function royaltyFeeInfoCollection(address collection)
        external
        view
        override
        returns (
            address,
            address,
            uint256
        )
    {
        return getRoyaltyFeeInfoCollection(collection);
    }

    /**
     * @notice View royalty info for a collection address
     * @param collection collection address
     */
    function getRoyaltyFeeInfoCollection(address collection)
        private
        view
        returns (
            address,
            address,
            uint256
        )
    {
        return (
            _royaltyFeeInfoCollection[collection].setter,
            _royaltyFeeInfoCollection[collection].receiver,
            _royaltyFeeInfoCollection[collection].fee
        );
    }
}