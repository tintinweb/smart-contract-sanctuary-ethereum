/**
 *Submitted for verification at Etherscan.io on 2022-03-17
*/

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.11;

interface IERC721 {
    function balanceOf(address owner) external view returns (uint256 balance);

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function ownerOf(uint256 tokenId) external view returns (address owner);
}interface IERC1155 {
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    function balanceOf(address account, uint256 id)
        external
        view
        returns (uint256);
}
error InactiveSwap();
error InvalidAction();
error AlreadyCompleted();
error InvalidReceipient();
error NotAuthorized();

/// @title Zen (Red Bean Swap)
/// @author The Garden
contract Zen {
    /// >>>>>>>>>>>>>>>>>>>>>>>>>  METADATA   <<<<<<<<<<<<<<<<<<<<<<<<< ///

    event SwapCreated(address indexed user, ZenSwap);

    event SwapAccepted(address indexed user, ZenSwap);

    event SwapUpdated(address indexed user, ZenSwap);

    event SwapCanceled(address indexed user, ZenSwap);

    event RequesterAdded(ZenSwap);

    /// @notice Azuki contract on mainnet
    IERC721 private immutable azuki;

    /// @notice BOBU contract on mainnet
    IERC1155 private immutable bobu;

    uint256 private currentSwapId;

    enum swapStatus {
        ACTIVE,
        COMPLETE,
        INACTIVE
    }

    /// @dev Packed struct of swap data.
    /// @param offerTokens List of token IDs offered
    /// @param offerTokens List of token IDs requested in exchange
    /// @param requestFrom Opposing party the swap is initiated with.
    /// @param createdAt UNIX Timestamp of swap creation.
    /// @param allotedTime Time allocated for the swap, until it expires and becomes invalid.
    struct ZenSwap {
        uint256 id;
        uint256[] offerTokens721;
        uint256 offerTokens1155;
        uint256[] requestTokens721;
        uint256 requestTokens1155;
        address requestFrom;
        uint64 createdAt;
        uint24 allotedTime;
        swapStatus status;
    }

    // struct Token {
    //     address contractAddress;
    //     uint256[] tokenId;
    // }

    /// @notice Maps user to open swaps
    mapping(address => ZenSwap[]) public swaps;

    /// @notice Maps swap IDs to index of swap in userSwap
    mapping(uint256 => uint256) public getSwapIndex;

    constructor(address _azuki, address _bobu) {
        azuki = IERC721(_azuki);
        bobu = IERC1155(_bobu);
    }

    /// @notice Creates a new swap.
    /// @param offerTokens721 ERC721 Token IDs offered by the offering party (caller).
    /// @param offerTokens1155 ERC1155 quantity of Bobu Token ID #1
    /// @param requestFrom Opposing party the swap is initiated with.
    /// @param requestTokens721 ERC721 Token IDs requested from the counter party.
    /// @param requestTokens1155 ERC1155 quantity of Bobu Token ID #1 request from the counter party.
    /// @param allotedTime Time allocated for the swap, until it expires and becomes invalid.
    function createSwap(
        uint256[] calldata offerTokens721,
        uint256 offerTokens1155,
        address requestFrom,
        uint256[] calldata requestTokens721,
        uint256 requestTokens1155,
        uint24 allotedTime
    ) external {
        if (offerTokens721.length == 0 && requestTokens721.length == 0)
            revert InvalidAction();
        if (allotedTime == 0) revert InvalidAction();
        if (allotedTime >= 365 days) revert InvalidAction();
        if (requestFrom == address(0)) revert InvalidAction();
        if (!_verifyOwnership721(msg.sender, offerTokens721))
            revert NotAuthorized();
        if (!_verifyOwnership721(requestFrom, requestTokens721))
            revert NotAuthorized();
        if (
            offerTokens1155 != 0 &&
            !_verifyOwnership1155(msg.sender, offerTokens1155)
        ) revert NotAuthorized();
        if (
            requestTokens1155 != 0 &&
            !_verifyOwnership1155(requestFrom, requestTokens1155)
        ) revert NotAuthorized();

        ZenSwap memory swap = ZenSwap(
            currentSwapId,
            offerTokens721,
            offerTokens1155,
            requestTokens721,
            requestTokens1155,
            requestFrom,
            uint64(block.timestamp),
            allotedTime,
            swapStatus.ACTIVE
        );

        getSwapIndex[currentSwapId] = swaps[msg.sender].length;
        swaps[msg.sender].push(swap);

        currentSwapId++;
    }

    /// @notice Accepts an existing swap.
    /// @param offerer Address of the offering party that initiated the swap
    /// @param id ID of the existing swap
    function acceptSwap(uint256 id, address offerer) external {
        uint256 swapIndex = getSwapIndex[id];
        ZenSwap memory swap = swaps[offerer][swapIndex];

        if (swap.status == swapStatus.INACTIVE) revert InactiveSwap();
        if (swap.status == swapStatus.COMPLETE) revert AlreadyCompleted();
        if (swap.requestFrom != msg.sender) revert InvalidReceipient();
        if (block.timestamp > swap.createdAt + swap.allotedTime)
            revert InactiveSwap();

        swaps[offerer][swapIndex].status = swapStatus.COMPLETE;
        _swapERC721(swap, offerer);
        if (!(swap.offerTokens1155 == 0 || swap.requestTokens1155 == 0)) {
            _swapERC1155(swap, offerer);
        }
    }

    /// @notice Swaps ERC721 contents
    /// @param swap ZenSwap object containing all swap data
    /// @param offerer User that created the swap
    /// @dev `msg.sender` is the user accepting the swap
    function _swapERC721(ZenSwap memory swap, address offerer) internal {
        uint256 offererLength721 = swap.offerTokens721.length;
        uint256 requestLength721 = swap.requestTokens721.length;

        uint256[] memory offerTokens721 = swap.offerTokens721;
        uint256[] memory requestTokens721 = swap.requestTokens721;

        for (uint256 i; i < offererLength721; ) {
            azuki.transferFrom(offerer, msg.sender, offerTokens721[i]);

            unchecked {
                i++;
            }
        }

        for (uint256 i; i < requestLength721; ) {
            azuki.transferFrom(msg.sender, offerer, requestTokens721[i]);

            unchecked {
                i++;
            }
        }
    }

    /// @notice Swaps ERC1155 contents
    /// @param swap ZenSwap object containing all swap data
    /// @param offerer User that created the swap
    /// @dev `msg.sender` is the user accepting the swap
    function _swapERC1155(ZenSwap memory swap, address offerer) internal {
        uint256 offererQuantity1155 = swap.offerTokens1155;
        uint256 requestQuantity1155 = swap.requestTokens1155;

        if (offererQuantity1155 != 0) {
            bobu.safeTransferFrom(
                offerer,
                msg.sender,
                0,
                offererQuantity1155,
                ""
            );
        }

        if (requestQuantity1155 != 0) {
            bobu.safeTransferFrom(
                msg.sender,
                offerer,
                0,
                requestQuantity1155,
                ""
            );
        }
    }

    /// @notice Batch verifies that the specified owner is the owner of all ERC721 tokens.
    /// @param owner Specified owner of tokens.
    /// @param tokenIds List of token IDs.
    function _verifyOwnership721(address owner, uint256[] memory tokenIds)
        internal
        view
        returns (bool)
    {
        uint256 length = tokenIds.length;

        for (uint256 i = 0; i < length; ) {
            if (azuki.ownerOf(tokenIds[i]) != owner) return false;

            unchecked {
                i++;
            }
        }

        return true;
    }

    /// @notice Batch verifies that the specified owner is the owner of all ERC1155 tokens.
    /// @param owner Specified owner of tokens.
    /// @param tokenQuantity Amount of Bobu tokens
    function _verifyOwnership1155(address owner, uint256 tokenQuantity)
        internal
        view
        returns (bool)
    {
        return bobu.balanceOf(owner, 0) >= tokenQuantity;
    }

    /// @notice Gets the details of an existing swap.
    function getSwap(uint256 id, address offerer)
        external
        view
        returns (ZenSwap memory)
    {
        return swaps[offerer][getSwapIndex[id]];
    }

    /// @notice Extends existing swap alloted time
    /// @param allotedTime Amount of time to increase swap alloted time for
    function extendAllotedTime(uint256 id, uint24 allotedTime) external {
        ZenSwap storage swap = swaps[msg.sender][getSwapIndex[id]];

        if (swap.status == swapStatus.INACTIVE) revert InvalidAction();

        swap.allotedTime = swap.allotedTime + allotedTime;
    }

    /// @notice Manually deletes existing swap.
    function cancelSwap(uint256 id) external {
        ZenSwap storage swap = swaps[msg.sender][getSwapIndex[id]];

        if (swap.status == swapStatus.INACTIVE) revert InvalidAction();

        swap.status = swapStatus.INACTIVE;
    }
}