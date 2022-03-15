// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "./interfaces/IERC721Custom.sol";

contract JaduStaking is Context {
    //uint256 private tokenId;

    using Counters for Counters.Counter;
    Counters.Counter private _itemIds;
    Counters.Counter private _itemsUnstaked;

    address payable owner;

    constructor() {
        owner = payable(_msgSender());
    }

    struct StakeItem {
        uint256 itemId;
        address nftContract;
        uint256[] tokenId;
        address owner;
        uint256 time;
    }

    mapping(address => mapping(uint256 => bool)) private NFTexist;
    mapping(uint256 => StakeItem) private idToStakeItem;
    mapping(address => mapping(uint256 => bool)) public revealedIDs;

    function stake(address nftContract, uint256[] memory tokenId)
        public
        payable
        returns (uint256)
    {
        require(tokenId.length <= 2, "Cannot stake more than 2 NFTs in combo.");

        for (uint256 i = 0; i < tokenId.length; i++) {
            require(
                NFTexist[nftContract][tokenId[i]] == false,
                "NFT already staked."
            );

            require(
                revealedIDs[nftContract][tokenId[i]] == false,
                "NFT was staked for 30 days either in single staking or combination staking."
            );

            NFTexist[nftContract][tokenId[i]] = true;
        }

        _itemIds.increment();
        uint256 itemId = _itemIds.current();

        idToStakeItem[itemId] = StakeItem(
            itemId,
            nftContract,
            tokenId,
            _msgSender(),
            block.timestamp
        );

        for (uint256 i = 0; i < tokenId.length; i++) {
            IERC721Custom(nftContract).transferFrom(
                _msgSender(),
                address(this),
                tokenId[i]
            );
        }

        return itemId;
    }

    function unStake(address nftContract, uint256 itemId)
        public
        payable
        returns (uint256[] memory)
    {
        uint256[] memory tokenId = idToStakeItem[itemId].tokenId;
        require(
            idToStakeItem[itemId].owner == _msgSender(),
            "You are not the owner of staked NFT."
        );

        if (block.timestamp > idToStakeItem[itemId].time + 30 days) {
            for (uint256 i = 0; i < tokenId.length; i++) {
                doReveal(nftContract, tokenId[i]);
            }
        }
        for (uint256 i = 0; i < tokenId.length; i++) {
            uint256 id = tokenId[i];
            IERC721Custom(nftContract).transferFrom(
                address(this),
                idToStakeItem[itemId].owner,
                id
            );
            NFTexist[nftContract][id] = false;
        }
        delete idToStakeItem[itemId];
        _itemsUnstaked.increment();
        return tokenId;
    }

    function doReveal(address nftContract, uint256 tokenId) private {
        revealedIDs[nftContract][tokenId] = true;
    }

    function multiUnStake(address nftContract, uint256[] calldata itemIds)
        public
        payable
        returns (bool)
    {
        for (uint256 i = 0; i < itemIds.length; i++) {
            unStake(nftContract, itemIds[i]);
        }
        return true;
    }

    function fetchMyNFTs(address account)
        public
        view
        returns (StakeItem[] memory)
    {
        uint256 totalItemCount = _itemIds.current();
        uint256 itemCount = 0;
        uint256 currentIndex = 0;

        for (uint256 i = 0; i < totalItemCount; i++) {
            if (idToStakeItem[i + 1].owner == account) {
                itemCount += 1;
            }
        }

        StakeItem[] memory items = new StakeItem[](itemCount);
        for (uint256 i = 0; i < totalItemCount; i++) {
            if (idToStakeItem[i + 1].owner == account) {
                uint256 currentId = i + 1;
                StakeItem storage currentItem = idToStakeItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface IERC721Custom is IERC165 {
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function approve(address to, uint256 tokenId) external;

    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

    function setApprovalForAll(address operator, bool _approved) external;

    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    function revealTokenURI(uint256 id) external returns (bool);
}

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