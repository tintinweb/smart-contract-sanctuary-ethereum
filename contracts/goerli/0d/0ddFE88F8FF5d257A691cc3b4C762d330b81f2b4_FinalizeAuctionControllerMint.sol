// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

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
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
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
pragma solidity ^0.8.7;

import "./utils/EnglishAuctionStorage.sol";
import "./SafeEthSender.sol";
import "../interfaces/INFT.sol";

contract FinalizeAuctionControllerMint is EnglishAuctionStorage, SafeEthSender {
    event AuctionRoyaltiesPaid(
        uint32 auctionId,
        uint32 nftId,
        address artistAddress,
        uint256 royaltyAmount
    );

    function finalize(uint32 _auctionId) external {
        AuctionStruct storage auction = auctionIdToAuction[_auctionId];

        INFT nft = INFT(auction.nftContractAddress);

        uint32 nftId = nft.nftId();

        if (
            auction.auctionBalance == 0 && auction.bidder == payable(address(0))
        ) {
            emit AuctionRoyaltiesPaid(_auctionId, nftId, address(0), 0);
        } else {
            (address receiver, uint256 royaltyAmount) = nft.royaltyInfo(
                auction.tokenId,
                auction.auctionBalance
            );

            uint256 amountForWithdrawalAddress = auction.auctionBalance -
                royaltyAmount;

            auction.auctionBalance = 0;

            sendEthWithLimitedGas(payable(receiver), royaltyAmount, 5000);

            sendEthWithLimitedGas(
                withdrawalAddress,
                amountForWithdrawalAddress,
                5000
            );

            nft.awardToken(auction.bidder, auction.tokenId);

            emit AuctionRoyaltiesPaid(
                _auctionId,
                nftId,
                receiver,
                royaltyAmount
            );
        }
    }

    function cancel(uint32 _auctionId) external {
        revert();
    }

    function adminCancel(uint32 _auctionId, string memory _reason) external {
        require(
            bytes(_reason).length > 0,
            "English Auction: Include a reason for this cancellation"
        );
        AuctionStruct storage auction = auctionIdToAuction[_auctionId];
        require(auction.timeEnd > 0, "English Auction: Auction not found");
    }

    function getAuctionType() external view returns (string memory) {
        return "MINT";
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./utils/CallHelpers.sol";

abstract contract SafeEthSender is ReentrancyGuard {
    mapping(address => uint256) private withdrawRegistry;

    event PendingWithdraw(address _user, uint256 _amount);
    event Withdrawn(address _user, uint256 _amount);

    constructor() ReentrancyGuard() {}

    function sendEthWithLimitedGas(
        address payable _user,
        uint256 _amount,
        uint256 _gasLimit
    ) internal {
        if (_amount == 0) {
            return;
        }

        (bool success, ) = _user.call{value: _amount, gas: _gasLimit}("");
        if (!success) {
            withdrawRegistry[_user] += _amount;

            emit PendingWithdraw(_user, _amount);
        }
    }

    function getAmountToWithdrawForUser(address user)
        public
        view
        returns (uint256)
    {
        return withdrawRegistry[user];
    }

    function withdrawPendingEth() external {
        this.withdrawPendingEthFor(payable(msg.sender));
    }

    function withdrawPendingEthFor(address payable _user)
        external
        nonReentrant
    {
        uint256 amount = withdrawRegistry[_user];
        require(amount > 0, "SafeEthSender: no funds to withdraw");
        withdrawRegistry[_user] = 0;
        (bool success, bytes memory response) = _user.call{value: amount}("");

        if (!success) {
            string memory message = CallHelpers.getRevertMsg(response);
            revert(message);
        }

        emit Withdrawn(_user, amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

library CallHelpers {
    function getRevertMsg(bytes memory _returnData)
        internal
        pure
        returns (string memory)
    {
        if (_returnData.length < 68) return "Transaction reverted silently";

        assembly {
            _returnData := add(_returnData, 0x04)
        }
        return abi.decode(_returnData, (string));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "../../interfaces/IAccessManager.sol";

abstract contract EnglishAuctionStorage {
    uint32 lastAuctionId;
    address payable public withdrawalAddress;
    IAccessManager accessManager;

    struct AuctionStruct {
        uint32 tokenId;
        uint32 timeStart;
        uint32 timeEnd;
        uint8 minBidPercentage;
        uint256 initialPrice;
        uint256 minBidValue;
        uint256 auctionBalance;
        address nftContractAddress;
        address finalizeAuctionControllerAddress;
        address payable bidder;
        bytes additionalDataForFinalizeAuction;
    }

    mapping(uint32 => AuctionStruct) auctionIdToAuction;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IAccessManager {
    function isOperationalAddress(address _address)
        external
        view
        returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/interfaces/IERC2981.sol";

interface INFT is IERC2981 {
    function awardToken(address _user, uint32 _tokenID) external;

    function totalAmountOfEdition() external view returns (uint32);

    function timeStart() external view returns (uint32);

    function timeEnd() external view returns (uint32);

    function nftId() external view returns (uint32);

    function init(
        address _accessManangerAddress,
        bytes memory _staticData,
        bytes memory _dynamicData
    ) external;
}