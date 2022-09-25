// SPDX-License-Identifier: MIT

// ______  __  __   ______       _____    __  __   _____    ______
// /\__  _\/\ \_\ \ /\  ___\     /\  __-. /\ \/\ \ /\  __-. /\  ___\
// \/_/\ \/\ \  __ \\ \  __\     \ \ \/\ \\ \ \_\ \\ \ \/\ \\ \  __\
//   \ \_\ \ \_\ \_\\ \_____\    \ \____- \ \_____\\ \____- \ \_____\
//    \/_/  \/_/\/_/ \/_____/     \/____/  \/_____/ \/____/  \/_____/
//

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./../../common/interfaces/IINT.sol";
import "./../../common/interfaces/IThePixelsIncExtensionStorageV2.sol";
import "./../../common/interfaces/ICoreRewarder.sol";

contract ThePixelsIncSocialMessageExtension is Ownable {
    uint256 public constant EXTENSION_ID = 2;

    struct MessageType {
        bool exists;
        uint256 price;
    }

    uint256 public nextMessageId;
    mapping(uint256 => MessageType) public messageTypes;

    address public immutable INTAddress;
    address public extensionStorageAddress;
    address public DAOAddress;
    address public rewarderAddress;

    constructor(
        address _extensionStorageAddress,
        address _INTAddress,
        address _DAOAddress,
        address _rewarderAddress
    ) {
        extensionStorageAddress = _extensionStorageAddress;
        INTAddress = _INTAddress;
        DAOAddress = _DAOAddress;
        rewarderAddress = _rewarderAddress;
    }

    function setDAOAddress(address _DAOAddress) external onlyOwner {
        DAOAddress = _DAOAddress;
    }

    function setRewarderAddress(address _rewarderAddress) external onlyOwner {
        rewarderAddress = _rewarderAddress;
    }

    function setExtensionStorageAddress(address _extensionStorageAddress)
        external
        onlyOwner
    {
        extensionStorageAddress = _extensionStorageAddress;
    }

    function setMessageType(
        uint256 messageTypeId,
        bool exists,
        uint256 price
    ) public onlyOwner {
        messageTypes[messageTypeId].exists = exists;
        messageTypes[messageTypeId].price = price;
    }

    function sendGlobalMessage(
        uint256 senderId,
        string memory message,
        uint256 messageTypeId
    ) public onlyOwner {
        MessageType memory messageType = messageTypes[messageTypeId];
        require(messageType.exists, "Invalid message type");

        uint256 currentMessageId = nextMessageId;
        emit GlobalMessageSent(
            msg.sender,
            currentMessageId,
            senderId,
            message,
            messageTypeId,
            block.timestamp
        );
        nextMessageId = currentMessageId + 1;
    }

    function updateGlobalTokenBlockStatus(
        uint256 senderId,
        uint256 targetTokenId,
        bool isBlocked
    ) public onlyOwner {
        emit TokenBlockStatusUpdated(
            msg.sender,
            senderId,
            targetTokenId,
            isBlocked,
            block.timestamp
        );
    }

    function enableSocialMessages(
        uint256[] memory tokenIds,
        uint256[] memory salts
    ) public {
        uint256 length = tokenIds.length;
        uint256[] memory variants = new uint256[](length);
        bool[] memory useCollection = new bool[](length);
        uint256[] memory collectionTokenIds = new uint256[](length);

        address _extensionStorageAddress = extensionStorageAddress;
        for (uint256 i = 0; i < length; i++) {
            uint256 currentVariant = IThePixelsIncExtensionStorageV2(
                _extensionStorageAddress
            ).currentVariantIdOf(EXTENSION_ID, tokenIds[i]);
            require(currentVariant == 0, "Token has no social extension");

            uint256 rnd = _rnd(tokenIds[i], salts[i]) % 100;
            uint256 variant;

            if (rnd >= 80 && rnd < 100) {
                variant = 3; 
            } else if (rnd >= 50 && rnd < 80) {
                variant = 2;
            } else {
                variant = 1;
            }
            variants[i] = variant;
        }

        IThePixelsIncExtensionStorageV2(_extensionStorageAddress)
            .extendMultipleWithVariants(
                msg.sender,
                EXTENSION_ID,
                tokenIds,
                variants,
                useCollection,
                collectionTokenIds
            );
    }

    function sendMessages(
        uint256[] memory senderTokenIds,
        uint256[] memory targetTokenIds,
        string[] memory messages,
        uint256[] memory messageTypeIds
    ) public {
        uint256 currentMessageId = nextMessageId;
        uint256 totalPayment;

        address _extensionStorageAddress = extensionStorageAddress;
        address _rewarderAddress = rewarderAddress;
        for (uint256 i = 0; i < senderTokenIds.length; i++) {
            require(
                ICoreRewarder(_rewarderAddress).isOwner(
                    msg.sender,
                    senderTokenIds[i]
                ),
                "Not authorised - Invalid owner"
            );

            uint256 currentVariant = IThePixelsIncExtensionStorageV2(
                _extensionStorageAddress
            ).currentVariantIdOf(EXTENSION_ID, senderTokenIds[i]);
            require(currentVariant > 0, "Token has no social extension");
            

            MessageType memory messageType = messageTypes[messageTypeIds[i]];
            require(messageType.exists, "Invalid message type");
            totalPayment += messageType.price;

            emit MessageSent(
                msg.sender,
                currentMessageId,
                senderTokenIds[i],
                targetTokenIds[i],
                messages[i],
                messageTypeIds[i],
                block.timestamp
            );
            currentMessageId++;
        }
        nextMessageId = currentMessageId;
        if (totalPayment > 0) {
            payToDAO(msg.sender, totalPayment);
        }
    }

    function updateMessageVisibility(
        uint256[] memory senderTokenIds,
        uint256[] memory messageIds,
        bool[] memory isHiddens
    ) public {
        address _extensionStorageAddress = extensionStorageAddress;
        address _rewarderAddress = rewarderAddress;
        for (uint256 i = 0; i < senderTokenIds.length; i++) {
            require(
                ICoreRewarder(_rewarderAddress).isOwner(
                    msg.sender,
                    senderTokenIds[i]
                ),
                "Not authorised - Invalid owner"
            );

            uint256 currentVariant = IThePixelsIncExtensionStorageV2(
                _extensionStorageAddress
            ).currentVariantIdOf(EXTENSION_ID, senderTokenIds[i]);
            require(currentVariant > 0, "Token has no social extension");

            emit MessageVisibilityUpdated(
                msg.sender,
                messageIds[i],
                senderTokenIds[i],
                isHiddens[i],
                block.timestamp
            );
        }
    }

    function updateTokenBlockStatus(
        uint256[] memory senderTokenIds,
        uint256[] memory targetTokenIds,
        bool[] memory isBlockeds
    ) public {
        address _extensionStorageAddress = extensionStorageAddress;
        address _rewarderAddress = rewarderAddress;
        for (uint256 i = 0; i < senderTokenIds.length; i++) {
            require(
                ICoreRewarder(_rewarderAddress).isOwner(
                    msg.sender,
                    senderTokenIds[i]
                ),
                "Not authorised - Invalid owner"
            );

            uint256 currentVariant = IThePixelsIncExtensionStorageV2(
                _extensionStorageAddress
            ).currentVariantIdOf(EXTENSION_ID, senderTokenIds[i]);
            require(currentVariant > 0, "Token has no social extension");

            emit TokenBlockStatusUpdated(
                msg.sender,
                senderTokenIds[i],
                targetTokenIds[i],
                isBlockeds[i],
                block.timestamp
            );
        }
    }

    function payToDAO(address owner, uint256 amount) internal {
        IINT(INTAddress).transferFrom(owner, DAOAddress, amount);
    }

    function _rnd(uint256 _tokenId, uint256 _salt)
        internal
        view
        returns (uint256)
    {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        block.timestamp,
                        msg.sender,
                        _tokenId,
                        _salt
                    )
                )
            );
    }

    event MessageSent(
        address owner,
        uint256 indexed id,
        uint256 indexed senderTokenId,
        uint256 indexed targetTokenId,
        string message,
        uint256 messageTypeId,
        uint256 dateCrated
    );

    event MessageVisibilityUpdated(
        address owner,
        uint256 indexed id,
        uint256 indexed senderTokenId,
        bool indexed isHidden,
        uint256 dateCrated
    );

    event TokenBlockStatusUpdated(
        address owner,
        uint256 indexed senderTokenId,
        uint256 indexed targetTokenId,
        bool indexed isBlocked,
        uint256 dateCrated
    );

    event GlobalMessageSent(
        address owner,
        uint256 indexed id,
        uint256 indexed senderId,
        string message,
        uint256 messageTypeId,
        uint256 dateCrated
    );

    event GlobalMessageVisibilityUpdated(
        address owner,
        uint256 indexed id,
        uint256 indexed senderId,
        bool indexed isHidden,
        uint256 dateCrated
    );

    event GlobalTokenBlockStatusUpdated(
        address owner,
        uint256 indexed senderId,
        uint256 indexed targetTokenId,
        bool indexed isBlocked,
        uint256 dateCrated
    );
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

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

// ______  __  __   ______       _____    __  __   _____    ______
// /\__  _\/\ \_\ \ /\  ___\     /\  __-. /\ \/\ \ /\  __-. /\  ___\
// \/_/\ \/\ \  __ \\ \  __\     \ \ \/\ \\ \ \_\ \\ \ \/\ \\ \  __\
//   \ \_\ \ \_\ \_\\ \_____\    \ \____- \ \_____\\ \____- \ \_____\
//    \/_/  \/_/\/_/ \/_____/     \/____/  \/_____/ \/____/  \/_____/
//

interface IINT {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function mint(address to, uint256 amount) external;

    function burnFrom(address account, uint256 amount) external;
}

// pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT

// ______  __  __   ______       _____    __  __   _____    ______
// /\__  _\/\ \_\ \ /\  ___\     /\  __-. /\ \/\ \ /\  __-. /\  ___\
// \/_/\ \/\ \  __ \\ \  __\     \ \ \/\ \\ \ \_\ \\ \ \/\ \\ \  __\
//   \ \_\ \ \_\ \_\\ \_____\    \ \____- \ \_____\\ \____- \ \_____\
//    \/_/  \/_/\/_/ \/_____/     \/____/  \/_____/ \/____/  \/_____/
//

pragma solidity ^0.8.0;

interface IThePixelsIncExtensionStorageV2 {
    struct Variant {
        bool isOperatorExecution;
        bool isFreeForCollection;
        bool isEnabled;
        bool isDisabledForSpecialPixels;
        uint16 contributerCut;
        uint128 cost;
        uint128 supply;
        uint128 count;
        uint128 categoryId;
        address contributer;
        address collection;
    }

    struct Category {
        uint128 cost;
        uint128 supply;
    }

    struct VariantStatus {
        bool isAlreadyClaimed;
        uint128 cost;
        uint128 supply;
    }

    function extendWithVariant(
        address owner,
        uint256 extensionId,
        uint256 tokenId,
        uint256 variantId,
        bool useCollectionTokenId,
        uint256 collectionTokenId
    ) external;

    function extendMultipleWithVariants(
        address owner,
        uint256 extensionId,
        uint256[] memory tokenIds,
        uint256[] memory variantIds,
        bool[] memory useCollectionTokenId,
        uint256[] memory collectionTokenIds
    ) external;

    function detachVariant(
        address owner,
        uint256 extensionId,
        uint256 tokenId
    ) external;

    function detachVariants(
        address owner,
        uint256 extensionId,
        uint256[] memory tokenIds
    ) external;

    function variantDetail(
        address owner,
        uint256 extensionId,
        uint256 tokenId,
        uint256 variantId,
        bool useCollectionTokenId,
        uint256 collectionTokenId
    ) external view returns (Variant memory, VariantStatus memory);

    function variantDetails(
        address owner,
        uint256 extensionId,
        uint256[] memory tokenIds,
        uint256[] memory variantIds,
        bool[] memory useCollectionTokenIds,
        uint256[] memory collectionTokenIds
    ) external view returns (Variant[] memory, VariantStatus[] memory);

    function variantsOfExtension(
        uint256 extensionId,
        uint256[] memory variantIds
    ) external view returns (Variant[] memory);

    function transferExtensionVariant(
        address owner,
        uint256 extensionId,
        uint256 variantId,
        uint256 fromTokenId,
        uint256 toTokenId
    ) external;

    function pixelExtensions(uint256 tokenId) external view returns (uint256);

    function balanceOfToken(
        uint256 extensionId,
        uint256 tokenId,
        uint256[] memory variantIds
    ) external view returns (uint256);

    function currentVariantIdOf(uint256 extensionId, uint256 tokenId)
        external
        view
        returns (uint256);

    function currentVariantIdsOf(uint256 extensionId, uint256[] memory tokenIds)
        external
        view
        returns (uint256[] memory);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

// ______  __  __   ______       _____    __  __   _____    ______
// /\__  _\/\ \_\ \ /\  ___\     /\  __-. /\ \/\ \ /\  __-. /\  ___\
// \/_/\ \/\ \  __ \\ \  __\     \ \ \/\ \\ \ \_\ \\ \ \/\ \\ \  __\
//   \ \_\ \ \_\ \_\\ \_____\    \ \____- \ \_____\\ \____- \ \_____\
//    \/_/  \/_/\/_/ \/_____/     \/____/  \/_____/ \/____/  \/_____/
//

interface ICoreRewarder {
    function stake(
        uint256[] calldata tokenIds
    ) external;

    function withdraw(
        uint256[] calldata tokenIds
    ) external;

    function claim(uint256[] calldata tokenIds) external;

    function earned(uint256[] memory tokenIds)
        external
        view
        returns (uint256);

    function lastClaimTimesOfTokens(uint256[] memory tokenIds)
        external
        view
        returns (uint256[] memory);

    function isOwner(address owner, uint256 tokenId)
        external
        view
        returns (bool);

    function tokensOfOwner(address _owner)
        external
        view
        returns (uint256[] memory);

    function stakedTokensOfOwner(address owner)
        external
        view
        returns (uint256[] memory);
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