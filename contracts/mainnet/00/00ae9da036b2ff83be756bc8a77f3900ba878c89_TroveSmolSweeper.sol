// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

//           _____                    _____                   _______                   _____            _____                    _____                    _____                    _____
//          /\    \                  /\    \                 /::\    \                 /\    \          /\    \                  /\    \                  /\    \                  /\    \
//         /::\    \                /::\____\               /::::\    \               /::\____\        /::\    \                /::\____\                /::\    \                /::\    \
//        /::::\    \              /::::|   |              /::::::\    \             /:::/    /       /::::\    \              /:::/    /               /::::\    \              /::::\    \
//       /::::::\    \            /:::::|   |             /::::::::\    \           /:::/    /       /::::::\    \            /:::/   _/___            /::::::\    \            /::::::\    \
//      /:::/\:::\    \          /::::::|   |            /:::/~~\:::\    \         /:::/    /       /:::/\:::\    \          /:::/   /\    \          /:::/\:::\    \          /:::/\:::\    \
//     /:::/__\:::\    \        /:::/|::|   |           /:::/    \:::\    \       /:::/    /       /:::/__\:::\    \        /:::/   /::\____\        /:::/__\:::\    \        /:::/__\:::\    \
//     \:::\   \:::\    \      /:::/ |::|   |          /:::/    / \:::\    \     /:::/    /        \:::\   \:::\    \      /:::/   /:::/    /       /::::\   \:::\    \      /::::\   \:::\    \
//   ___\:::\   \:::\    \    /:::/  |::|___|______   /:::/____/   \:::\____\   /:::/    /       ___\:::\   \:::\    \    /:::/   /:::/   _/___    /::::::\   \:::\    \    /::::::\   \:::\    \
//  /\   \:::\   \:::\    \  /:::/   |::::::::\    \ |:::|    |     |:::|    | /:::/    /       /\   \:::\   \:::\    \  /:::/___/:::/   /\    \  /:::/\:::\   \:::\    \  /:::/\:::\   \:::\____\
// /::\   \:::\   \:::\____\/:::/    |:::::::::\____\|:::|____|     |:::|    |/:::/____/       /::\   \:::\   \:::\____\|:::|   /:::/   /::\____\/:::/  \:::\   \:::\____\/:::/  \:::\   \:::|    |
// \:::\   \:::\   \::/    /\::/    / ~~~~~/:::/    / \:::\    \   /:::/    / \:::\    \       \:::\   \:::\   \::/    /|:::|__/:::/   /:::/    /\::/    \:::\  /:::/    /\::/    \:::\  /:::|____|
//  \:::\   \:::\   \/____/  \/____/      /:::/    /   \:::\    \ /:::/    /   \:::\    \       \:::\   \:::\   \/____/  \:::\/:::/   /:::/    /  \/____/ \:::\/:::/    /  \/_____/\:::\/:::/    /
//   \:::\   \:::\    \                  /:::/    /     \:::\    /:::/    /     \:::\    \       \:::\   \:::\    \       \::::::/   /:::/    /            \::::::/    /            \::::::/    /
//    \:::\   \:::\____\                /:::/    /       \:::\__/:::/    /       \:::\    \       \:::\   \:::\____\       \::::/___/:::/    /              \::::/    /              \::::/    /
//     \:::\  /:::/    /               /:::/    /         \::::::::/    /         \:::\    \       \:::\  /:::/    /        \:::\__/:::/    /               /:::/    /                \::/____/
//      \:::\/:::/    /               /:::/    /           \::::::/    /           \:::\    \       \:::\/:::/    /          \::::::::/    /               /:::/    /                  ~~
//       \::::::/    /               /:::/    /             \::::/    /             \:::\    \       \::::::/    /            \::::::/    /               /:::/    /
//        \::::/    /               /:::/    /               \::/____/               \:::\____\       \::::/    /              \::::/    /               /:::/    /
//         \::/    /                \::/    /                 ~~                      \::/    /        \::/    /                \::/____/                \::/    /
//          \/____/                  \/____/                                           \/____/          \/____/                  ~~                       \/____/

import "./base/ABaseTroveSmolSweeper.sol";

contract TroveSmolSweeper is ABaseTroveSmolSweeper {
    constructor(
        address _troveMarketplace,
        address _defaultPaymentToken,
        address _weth
    ) ABaseTroveSmolSweeper(_troveMarketplace, _defaultPaymentToken, _weth) {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

//           _____                    _____                   _______                   _____            _____                    _____                    _____                    _____
//          /\    \                  /\    \                 /::\    \                 /\    \          /\    \                  /\    \                  /\    \                  /\    \
//         /::\    \                /::\____\               /::::\    \               /::\____\        /::\    \                /::\____\                /::\    \                /::\    \
//        /::::\    \              /::::|   |              /::::::\    \             /:::/    /       /::::\    \              /:::/    /               /::::\    \              /::::\    \
//       /::::::\    \            /:::::|   |             /::::::::\    \           /:::/    /       /::::::\    \            /:::/   _/___            /::::::\    \            /::::::\    \
//      /:::/\:::\    \          /::::::|   |            /:::/~~\:::\    \         /:::/    /       /:::/\:::\    \          /:::/   /\    \          /:::/\:::\    \          /:::/\:::\    \
//     /:::/__\:::\    \        /:::/|::|   |           /:::/    \:::\    \       /:::/    /       /:::/__\:::\    \        /:::/   /::\____\        /:::/__\:::\    \        /:::/__\:::\    \
//     \:::\   \:::\    \      /:::/ |::|   |          /:::/    / \:::\    \     /:::/    /        \:::\   \:::\    \      /:::/   /:::/    /       /::::\   \:::\    \      /::::\   \:::\    \
//   ___\:::\   \:::\    \    /:::/  |::|___|______   /:::/____/   \:::\____\   /:::/    /       ___\:::\   \:::\    \    /:::/   /:::/   _/___    /::::::\   \:::\    \    /::::::\   \:::\    \
//  /\   \:::\   \:::\    \  /:::/   |::::::::\    \ |:::|    |     |:::|    | /:::/    /       /\   \:::\   \:::\    \  /:::/___/:::/   /\    \  /:::/\:::\   \:::\    \  /:::/\:::\   \:::\____\
// /::\   \:::\   \:::\____\/:::/    |:::::::::\____\|:::|____|     |:::|    |/:::/____/       /::\   \:::\   \:::\____\|:::|   /:::/   /::\____\/:::/  \:::\   \:::\____\/:::/  \:::\   \:::|    |
// \:::\   \:::\   \::/    /\::/    / ~~~~~/:::/    / \:::\    \   /:::/    / \:::\    \       \:::\   \:::\   \::/    /|:::|__/:::/   /:::/    /\::/    \:::\  /:::/    /\::/    \:::\  /:::|____|
//  \:::\   \:::\   \/____/  \/____/      /:::/    /   \:::\    \ /:::/    /   \:::\    \       \:::\   \:::\   \/____/  \:::\/:::/   /:::/    /  \/____/ \:::\/:::/    /  \/_____/\:::\/:::/    /
//   \:::\   \:::\    \                  /:::/    /     \:::\    /:::/    /     \:::\    \       \:::\   \:::\    \       \::::::/   /:::/    /            \::::::/    /            \::::::/    /
//    \:::\   \:::\____\                /:::/    /       \:::\__/:::/    /       \:::\    \       \:::\   \:::\____\       \::::/___/:::/    /              \::::/    /              \::::/    /
//     \:::\  /:::/    /               /:::/    /         \::::::::/    /         \:::\    \       \:::\  /:::/    /        \:::\__/:::/    /               /:::/    /                \::/____/
//      \:::\/:::/    /               /:::/    /           \::::::/    /           \:::\    \       \:::\/:::/    /          \::::::::/    /               /:::/    /                  ~~
//       \::::::/    /               /:::/    /             \::::/    /             \:::\    \       \::::::/    /            \::::::/    /               /:::/    /
//        \::::/    /               /:::/    /               \::/____/               \:::\____\       \::::/    /              \::::/    /               /:::/    /
//         \::/    /                \::/    /                 ~~                      \::/    /        \::/    /                \::/____/                \::/    /
//          \/____/                  \/____/                                           \/____/          \/____/                  ~~                       \/____/

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "../../token/ANFTReceiver.sol";
import "../libraries/SettingsBitFlag.sol";
import "../libraries/Math.sol";
import "../../treasure/interfaces/ITroveMarketplace.sol";
import "../structs/BuyOrder.sol";
import "../interfaces/ITroveSmolSweeper.sol";
import "./ABaseSmolSweeper.sol";

import "../errors/BuyError.sol";

// import "@utils/console.sol";

error InvalidMsgValue();
error MsgValueShouldBeZero();

// Ownable,
abstract contract ABaseTroveSmolSweeper is
    ReentrancyGuard,
    ABaseSmolSweeper,
    ITroveSmolSweeper
{
    using SafeERC20 for IERC20;

    bytes4 private constant INTERFACE_ID_ERC721 = 0x80ac58cd;
    bytes4 private constant INTERFACE_ID_ERC1155 = 0xd9b67a26;

    IERC20 public defaultPaymentToken;
    IERC20 public weth;
    ITroveMarketplace public troveMarketplace;

    constructor(
        address _troveMarketplace,
        address _defaultPaymentToken,
        address _weth
    ) {
        troveMarketplace = ITroveMarketplace(_troveMarketplace);
        defaultPaymentToken = IERC20(_defaultPaymentToken);
        weth = IERC20(_weth);
    }

    function setMarketplaceContract(ITroveMarketplace _troveMarketplace)
        external
        onlyOwner
    {
        troveMarketplace = _troveMarketplace;
    }

    function setDefaultPaymentToken(IERC20 _defaultPaymentToken)
        external
        onlyOwner
    {
        defaultPaymentToken = _defaultPaymentToken;
    }

    function setWeth(IERC20 _weth) external onlyOwner {
        weth = _weth;
    }

    function sumTotalPrice(BuyOrder[] memory _buyOrders)
        internal
        pure
        returns (uint256 totalPrice)
    {
        for (uint256 i = 0; i < _buyOrders.length; i++) {
            totalPrice +=
                _buyOrders[i].quantity *
                _buyOrders[i].maxPricePerItem;
        }
    }

    function tryBuyItem(
        BuyItemParams memory _buyOrder,
        uint16 _inputSettingsBitFlag,
        uint256 _maxSpendAllowanceLeft
    )
        internal
        returns (
            uint256 totalPrice,
            bool success,
            BuyError buyError
        )
    {
        uint256 quantityToBuy = _buyOrder.quantity;
        // check if the listing exists
        ITroveMarketplace.ListingOrBid memory listing = troveMarketplace
            .listings(_buyOrder.nftAddress, _buyOrder.tokenId, _buyOrder.owner);

        // // check if the price is correct
        // if (listing.pricePerItem > _buyOrder.maxPricePerItem) {
        //     // skip this item
        //     return (0, false, SettingsBitFlag.MAX_PRICE_PER_ITEM_EXCEEDED);
        // }

        // not enough listed items
        if (listing.quantity < quantityToBuy) {
            if (
                SettingsBitFlag.checkSetting(
                    _inputSettingsBitFlag,
                    SettingsBitFlag.INSUFFICIENT_QUANTITY_ERC1155
                )
            ) {
                // else buy all listed items even if it's less than requested
                quantityToBuy = listing.quantity;
            } else {
                // skip this item
                return (0, false, BuyError.INSUFFICIENT_QUANTITY_ERC1155);
            }
        }

        // check if total price is less than max spend allowance left
        if ((listing.pricePerItem * quantityToBuy) > _maxSpendAllowanceLeft) {
            return (0, false, BuyError.EXCEEDING_MAX_SPEND);
        }

        BuyItemParams[] memory buyItemParams = new BuyItemParams[](1);
        buyItemParams[0] = _buyOrder;

        uint256 totalSpent = 0;
        uint256 value = (_buyOrder.paymentToken == address(weth))
            ? (_buyOrder.maxPricePerItem * quantityToBuy)
            : 0;

        try troveMarketplace.buyItems{value: value}(buyItemParams) {
            if (
                SettingsBitFlag.checkSetting(
                    _inputSettingsBitFlag,
                    SettingsBitFlag.EMIT_SUCCESS_EVENT_LOGS
                )
            ) {
                emit SuccessBuyItem(
                    _buyOrder.nftAddress,
                    _buyOrder.tokenId,
                    _buyOrder.owner,
                    msg.sender,
                    quantityToBuy,
                    listing.pricePerItem
                );
            }

            if (
                IERC165(_buyOrder.nftAddress).supportsInterface(
                    INTERFACE_ID_ERC721
                )
            ) {
                IERC721(_buyOrder.nftAddress).safeTransferFrom(
                    address(this),
                    msg.sender,
                    _buyOrder.tokenId
                );
            } else if (
                IERC165(_buyOrder.nftAddress).supportsInterface(
                    INTERFACE_ID_ERC1155
                )
            ) {
                IERC1155(_buyOrder.nftAddress).safeTransferFrom(
                    address(this),
                    msg.sender,
                    _buyOrder.tokenId,
                    quantityToBuy,
                    ""
                );
            } else revert InvalidNFTAddress();

            totalSpent = listing.pricePerItem * quantityToBuy;
        } catch (bytes memory errorReason) {
            if (
                SettingsBitFlag.checkSetting(
                    _inputSettingsBitFlag,
                    SettingsBitFlag.EMIT_FAILURE_EVENT_LOGS
                )
            ) {
                emit CaughtFailureBuyItem(
                    _buyOrder.nftAddress,
                    _buyOrder.tokenId,
                    _buyOrder.owner,
                    msg.sender,
                    quantityToBuy,
                    listing.pricePerItem,
                    errorReason
                );
            }

            if (
                SettingsBitFlag.checkSetting(
                    _inputSettingsBitFlag,
                    SettingsBitFlag.MARKETPLACE_BUY_ITEM_REVERTED
                )
            ) revert FirstBuyReverted(errorReason);
            // skip this item
            return (0, false, BuyError.BUY_ITEM_REVERTED);
        }

        return (totalSpent, true, BuyError.NONE);
    }

    function buyItemsSingleToken(
        BuyItemParams[] calldata _buyOrders,
        uint16 _inputSettingsBitFlag,
        address _inputTokenAddress,
        uint256 _maxSpendIncFees
    ) external payable {
        if (_inputTokenAddress == address(weth) && msg.value > 0) {
            if (_maxSpendIncFees != msg.value) revert InvalidMsgValue();
        } else {
            if (msg.value != 0) revert MsgValueShouldBeZero();
            // transfer payment tokens to this contract
            IERC20(_inputTokenAddress).safeTransferFrom(
                msg.sender,
                address(this),
                _maxSpendIncFees
            );
            IERC20(_inputTokenAddress).approve(
                address(troveMarketplace),
                _maxSpendIncFees
            );
        }

        (uint256 totalSpentAmount, uint256 successCount) = _buyItemsSingleToken(
            _buyOrders,
            _inputSettingsBitFlag,
            _maxSpendIncFees
        );

        // transfer back failed payment tokens to the buyer
        if (successCount == 0) revert AllReverted();

        uint256 feeAmount = _calculateFee(totalSpentAmount);

        if (_inputTokenAddress == address(weth) && _buyOrders[0].usingEth) {
            payable(msg.sender).transfer(
                _maxSpendIncFees - (totalSpentAmount + feeAmount)
            );
        } else {
            IERC20(_inputTokenAddress).safeTransfer(
                msg.sender,
                _maxSpendIncFees - (totalSpentAmount + feeAmount)
            );
        }
    }

    function _buyItemsSingleToken(
        BuyItemParams[] calldata _buyOrders,
        uint16 _inputSettingsBitFlag,
        uint256 _maxSpendIncFees
    ) internal returns (uint256 totalSpentAmount, uint256 successCount) {
        // buy all assets
        uint256 _maxSpendIncFees = _calculateAmountWithoutFees(
            _maxSpendIncFees
        );

        uint256 i = 0;
        uint256 length = _buyOrders.length;
        for (; i < length; ) {
            (
                uint256 spentAmount,
                bool spentSuccess,
                BuyError buyError
            ) = tryBuyItem(
                    _buyOrders[i],
                    _inputSettingsBitFlag,
                    _maxSpendIncFees - totalSpentAmount
                );

            if (spentSuccess) {
                totalSpentAmount += spentAmount;
                successCount++;
            } else {
                if (
                    buyError == BuyError.EXCEEDING_MAX_SPEND &&
                    SettingsBitFlag.checkSetting(
                        _inputSettingsBitFlag,
                        SettingsBitFlag.EXCEEDING_MAX_SPEND
                    )
                ) break;
            }

            unchecked {
                ++i;
            }
        }
    }

    function buyItemsManyTokens(
        BuyItemParams[] calldata _buyOrders,
        uint16 _inputSettingsBitFlag,
        address[] calldata _inputTokenAddresses,
        uint256[] calldata _maxSpendIncFees
    ) external payable {
        // transfer payment tokens to this contract
        uint256 i = 0;
        uint256 length = _inputTokenAddresses.length;
        for (; i < length; ) {
            if (_inputTokenAddresses[i] == address(weth) && msg.value > 0) {
                if (_maxSpendIncFees[i] != msg.value) revert InvalidMsgValue();
            } else {
                // if (msg.value != 0) revert MsgValueShouldBeZero();
                // transfer payment tokens to this contract
                IERC20(_inputTokenAddresses[i]).safeTransferFrom(
                    msg.sender,
                    address(this),
                    _maxSpendIncFees[i]
                );
                IERC20(_inputTokenAddresses[i]).approve(
                    address(troveMarketplace),
                    _maxSpendIncFees[i]
                );
            }

            unchecked {
                ++i;
            }
        }

        uint256[] memory maxSpends = _maxSpendWithoutFees(_maxSpendIncFees);
        (
            uint256[] memory totalSpentAmount,
            uint256 successCount
        ) = _buyItemsManyTokens(
                _buyOrders,
                _inputSettingsBitFlag,
                _inputTokenAddresses,
                maxSpends
            );

        // transfer back failed payment tokens to the buyer
        if (successCount == 0) revert AllReverted();

        i = 0;
        for (; i < length; ) {
            uint256 feeAmount = _calculateFee(totalSpentAmount[i]);

            if (
                _inputTokenAddresses[i] == address(weth) &&
                _buyOrders[0].usingEth
            ) {
                payable(msg.sender).transfer(
                    _maxSpendIncFees[i] - (totalSpentAmount[i] + feeAmount)
                );
            } else {
                IERC20(_inputTokenAddresses[i]).safeTransfer(
                    msg.sender,
                    _maxSpendIncFees[i] - (totalSpentAmount[i] + feeAmount)
                );
            }

            unchecked {
                ++i;
            }
        }
    }

    function _buyItemsManyTokens(
        BuyItemParams[] memory _buyOrders,
        uint16 _inputSettingsBitFlag,
        address[] memory _inputTokenAddresses,
        uint256[] memory _maxSpends
    )
        internal
        returns (uint256[] memory totalSpentAmounts, uint256 successCount)
    {
        totalSpentAmounts = new uint256[](_inputTokenAddresses.length);
        // buy all assets
        for (uint256 i = 0; i < _buyOrders.length; ) {
            uint256 j = _getTokenIndex(
                _inputTokenAddresses,
                _buyOrders[i].paymentToken
            );
            (
                uint256 spentAmount,
                bool spentSuccess,
                BuyError buyError
            ) = tryBuyItem(
                    _buyOrders[i],
                    _inputSettingsBitFlag,
                    _maxSpends[j] - totalSpentAmounts[j]
                );

            if (spentSuccess) {
                totalSpentAmounts[j] += spentAmount;
                successCount++;
            } else {
                if (
                    buyError == BuyError.EXCEEDING_MAX_SPEND &&
                    SettingsBitFlag.checkSetting(
                        _inputSettingsBitFlag,
                        SettingsBitFlag.EXCEEDING_MAX_SPEND
                    )
                ) break;
            }
            unchecked {
                ++i;
            }
        }
    }

    function sweepItemsSingleToken(
        BuyItemParams[] calldata _buyOrders,
        uint16 _inputSettingsBitFlag,
        address _inputTokenAddress,
        uint256 _maxSpendIncFees,
        uint256 _minSpend,
        uint32 _maxSuccesses,
        uint32 _maxFailures
    ) external payable {
        if (_inputTokenAddress == address(weth) && msg.value > 0) {
            if (_maxSpendIncFees != msg.value) revert InvalidMsgValue();
        } else {
            if (msg.value != 0) revert MsgValueShouldBeZero();
            // transfer payment tokens to this contract
            IERC20(_inputTokenAddress).safeTransferFrom(
                msg.sender,
                address(this),
                _maxSpendIncFees
            );
            IERC20(_inputTokenAddress).approve(
                address(troveMarketplace),
                _maxSpendIncFees
            );
        }

        (
            uint256 totalSpentAmount,
            uint256 successCount,

        ) = _sweepItemsSingleToken(
                _buyOrders,
                _inputSettingsBitFlag,
                _maxSpendIncFees,
                _minSpend,
                _maxSuccesses,
                _maxFailures
            );

        // transfer back failed payment tokens to the buyer
        if (successCount == 0) revert AllReverted();

        uint256 feeAmount = _calculateFee(totalSpentAmount);
        if (_inputTokenAddress == address(weth) && _buyOrders[0].usingEth) {
            payable(msg.sender).transfer(
                _maxSpendIncFees - (totalSpentAmount + feeAmount)
            );
        } else {
            IERC20(_inputTokenAddress).safeTransfer(
                msg.sender,
                _maxSpendIncFees - (totalSpentAmount + feeAmount)
            );
        }
    }

    function _sweepItemsSingleToken(
        BuyItemParams[] memory _buyOrders,
        uint16 _inputSettingsBitFlag,
        uint256 _maxSpendIncFees,
        uint256 _minSpend,
        uint32 _maxSuccesses,
        uint32 _maxFailures
    )
        internal
        returns (
            uint256 totalSpentAmount,
            uint256 successCount,
            uint256 failCount
        )
    {
        // buy all assets
        for (uint256 i = 0; i < _buyOrders.length; ) {
            if (successCount >= _maxSuccesses || failCount >= _maxFailures)
                break;

            if (totalSpentAmount >= _minSpend) break;

            (
                uint256 spentAmount,
                bool spentSuccess,
                BuyError buyError
            ) = tryBuyItem(
                    _buyOrders[i],
                    _inputSettingsBitFlag,
                    _maxSpendIncFees - totalSpentAmount
                );

            if (spentSuccess) {
                totalSpentAmount += spentAmount;
                successCount++;
            } else {
                if (
                    buyError == BuyError.EXCEEDING_MAX_SPEND &&
                    SettingsBitFlag.checkSetting(
                        _inputSettingsBitFlag,
                        SettingsBitFlag.EXCEEDING_MAX_SPEND
                    )
                ) break;
                failCount++;
            }

            unchecked {
                ++i;
            }
        }
    }

    function sweepItemsManyTokens(
        BuyItemParams[] calldata _buyOrders,
        uint16 _inputSettingsBitFlag,
        address[] calldata _inputTokenAddresses,
        uint256[] calldata _maxSpendIncFees,
        uint256[] calldata _minSpends,
        uint32 _maxSuccesses,
        uint32 _maxFailures
    ) external payable {
        // transfer payment tokens to this contract
        for (uint256 i = 0; i < _maxSpendIncFees.length; ) {
            if (_inputTokenAddresses[i] == address(weth) && msg.value > 0) {
                if (_maxSpendIncFees[i] != msg.value) revert InvalidMsgValue();
            } else {
                // if (msg.value != 0) revert MsgValueShouldBeZero();
                // transfer payment tokens to this contract
                IERC20(_inputTokenAddresses[i]).safeTransferFrom(
                    msg.sender,
                    address(this),
                    _maxSpendIncFees[i]
                );
                IERC20(_inputTokenAddresses[i]).approve(
                    address(troveMarketplace),
                    _maxSpendIncFees[i]
                );
            }

            unchecked {
                ++i;
            }
        }

        uint256[] memory _maxSpendIncFeesAmount = _maxSpendWithoutFees(
            _maxSpendIncFees
        );

        (
            uint256[] memory totalSpentAmount,
            uint256 successCount,

        ) = _sweepItemsManyTokens(
                _buyOrders,
                _inputSettingsBitFlag,
                _inputTokenAddresses,
                _maxSpendIncFeesAmount,
                _minSpends,
                _maxSuccesses,
                _maxFailures
            );

        // transfer back failed payment tokens to the buyer
        if (successCount == 0) revert AllReverted();

        for (uint256 i = 0; i < _maxSpendIncFees.length; ) {
            uint256 feeAmount = _calculateFee(totalSpentAmount[i]);

            if (
                _inputTokenAddresses[i] == address(weth) &&
                _buyOrders[0].usingEth
            ) {
                payable(msg.sender).transfer(
                    _maxSpendIncFees[i] - (totalSpentAmount[i] + feeAmount)
                );
            } else {
                IERC20(_inputTokenAddresses[i]).safeTransfer(
                    msg.sender,
                    _maxSpendIncFees[i] - (totalSpentAmount[i] + feeAmount)
                );
            }

            unchecked {
                ++i;
            }
        }
    }

    function _sweepItemsManyTokens(
        BuyItemParams[] memory _buyOrders,
        uint16 _inputSettingsBitFlag,
        address[] memory _inputTokenAddresses,
        uint256[] memory _maxSpendIncFeesAmount,
        uint256[] memory _minSpends,
        uint32 _maxSuccesses,
        uint32 _maxFailures
    )
        internal
        returns (
            uint256[] memory totalSpentAmounts,
            uint256 successCount,
            uint256 failCount
        )
    {
        totalSpentAmounts = new uint256[](_inputTokenAddresses.length);

        for (uint256 i = 0; i < _buyOrders.length; ) {
            if (successCount >= _maxSuccesses || failCount >= _maxFailures)
                break;

            uint256 j = _getTokenIndex(
                _inputTokenAddresses,
                _buyOrders[i].paymentToken
            );

            if (totalSpentAmounts[j] >= _minSpends[j]) break;

            (
                uint256 spentAmount,
                bool spentSuccess,
                BuyError buyError
            ) = tryBuyItem(
                    _buyOrders[i],
                    _inputSettingsBitFlag,
                    _maxSpendIncFeesAmount[j] - totalSpentAmounts[j]
                );

            if (spentSuccess) {
                totalSpentAmounts[j] += spentAmount;
                successCount++;
            } else {
                if (
                    buyError == BuyError.EXCEEDING_MAX_SPEND &&
                    SettingsBitFlag.checkSetting(
                        _inputSettingsBitFlag,
                        SettingsBitFlag.EXCEEDING_MAX_SPEND
                    )
                ) break;
                failCount++;
            }
            unchecked {
                ++i;
            }
        }
    }

    function _maxSpendWithoutFees(uint256[] memory _maxSpendIncFees)
        internal
        view
        returns (uint256[] memory maxSpendIncFeesAmount)
    {
        maxSpendIncFeesAmount = new uint256[](_maxSpendIncFees.length);

        uint256 maxSpendLength = _maxSpendIncFees.length;
        for (uint256 i = 0; i < maxSpendLength; ) {
            maxSpendIncFeesAmount[i] = _calculateAmountWithoutFees(
                _maxSpendIncFees[i]
            );
            unchecked {
                ++i;
            }
        }
    }

    function _getTokenIndex(
        address[] memory _inputTokenAddresses,
        address _buyOrderPaymentToken
    ) internal returns (uint256 j) {
        for (; j < _inputTokenAddresses.length; ) {
            if (_inputTokenAddresses[j] == _buyOrderPaymentToken) {
                return j;
            }
            unchecked {
                ++j;
            }
        }
        revert("bad");
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
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
pragma solidity ^0.8.11;
import "../token/ERC1155/AERC1155Receiver.sol";

import "../token/ERC721/AERC721Receiver.sol";

abstract contract ANFTReceiver is AERC721Receiver, AERC1155Receiver {}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

/**
 * @dev Settings for a buy order.
 */

library SettingsBitFlag {
    // default action is 0b00000000
    uint16 internal constant NONE = 0x00;

    // if marketplace fails to buy an item for some reason
    // default: will skip the item.
    // if 0x04 is set, will revert the entire buy transaction.
    uint16 internal constant MARKETPLACE_BUY_ITEM_REVERTED = 0x0001;

    // if the quantity of an item is less than the requested quantity (for ERC1155)
    // default: will skip the item.
    // if 0x02 is set, will buy as many items as possible (all listed items)
    uint16 internal constant INSUFFICIENT_QUANTITY_ERC1155 = 0x0002;

    // if total spend allowance is exceeded
    // default: will skip the item and continue.
    // if 0x08 is set, will skill the item and stop the transaction.
    uint16 internal constant EXCEEDING_MAX_SPEND = 0x0004;

    // refund in the input token
    // default: refunds in the payment token
    // if 0x10 is set, refunds in the input token
    uint16 internal constant REFUND_IN_INPUT_TOKEN = 0x0008;

    // turn on success event logging
    // default: will not log success events.
    // if 0x20 is set, will log success events.
    uint16 internal constant EMIT_SUCCESS_EVENT_LOGS = 0x000C;

    // turn on failure event logging
    // default: will not log failure events.
    // if 0x40 is set, will log failure events.
    uint16 internal constant EMIT_FAILURE_EVENT_LOGS = 0x0010;

    function checkSetting(uint16 _inputSettings, uint16 _settingBit)
        internal
        pure
        returns (bool)
    {
        return (_inputSettings & _settingBit) == _settingBit;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */

library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

/// @title  Treasure NFT marketplace
/// @notice This contract allows you to buy and sell NFTs from token contracts that are approved by the contract owner.
///         Please note that this contract is upgradeable. In the event of a compromised ProxyAdmin contract owner,
///         collectable tokens and payments may be at risk. To prevent this, the ProxyAdmin is owned by a multi-sig
///         governed by the TreasureDAO council.
/// @dev    This contract does not store any tokens at any time, it's only collects details "the sale" and approvals
///         from both parties and preforms non-custodial transaction by transfering NFT from owner to buying and payment
///         token from buying to NFT owner.
interface ITroveMarketplace {
    struct ListingOrBid {
        /// @dev number of tokens for sale or requested (1 if ERC-721 token is active for sale) (for bids, quantity for ERC-721 can be greater than 1)
        uint64 quantity;
        /// @dev price per token sold, i.e. extended sale price equals this times quantity purchased. For bids, price offered per item.
        uint128 pricePerItem;
        /// @dev timestamp after which the listing/bid is invalid
        uint64 expirationTime;
        /// @dev the payment token for this listing/bid.
        address paymentTokenAddress;
    }

    struct CollectionOwnerFee {
        /// @dev the fee, out of 10,000, that this collection owner will be given for each sale
        uint32 fee;
        /// @dev the recipient of the collection specific fee
        address recipient;
    }

    enum TokenApprovalStatus {
        NOT_APPROVED,
        ERC_721_APPROVED,
        ERC_1155_APPROVED
    }

    /// @notice TREASURE_MARKETPLACE_ADMIN_ROLE role hash
    function TREASURE_MARKETPLACE_ADMIN_ROLE() external pure returns (bytes32);

    /// @notice the denominator for portion calculation, i.e. how many basis points are in 100%
    function BASIS_POINTS() external pure returns (uint256);

    /// @notice the maximum fee which the owner may set (in units of basis points)
    function MAX_FEE() external pure returns (uint256);

    /// @notice the maximum fee which the collection owner may set
    function MAX_COLLECTION_FEE() external pure returns (uint256);

    /// @notice the minimum price for which any item can be sold=
    function MIN_PRICE() external pure returns (uint256);

    /// @notice the default token that is used for marketplace sales and fee payments. Can be overridden by collectionToTokenAddress.
    function paymentToken() external view returns (address);

    /// @notice fee portion (in basis points) for each sale, (e.g. a value of 100 is 100/10000 = 1%). This is the fee if no collection owner fee is set.
    function fee() external view returns (uint256);

    /// @notice address that receives fees
    function feeReceipient() external view returns (address);

    /// @notice mapping for listings, maps: nftAddress => tokenId => offeror
    function listings(
        address _nftAddress,
        uint256 _tokenId,
        address _offeror
    ) external view returns (ListingOrBid memory);

    /// @notice NFTs which the owner has approved to be sold on the marketplace, maps: nftAddress => status
    function tokenApprovals(address _nftAddress)
        external
        view
        returns (TokenApprovalStatus);

    /// @notice fee portion (in basis points) for each sale. This is used if a separate fee has been set for the collection owner.
    function feeWithCollectionOwner() external view returns (uint256);

    /// @notice Maps the collection address to the fees which the collection owner collects. Some collections may not have a seperate fee, such as those owned by the Treasure DAO.
    function collectionToCollectionOwnerFee(address _collectionAddress)
        external
        view
        returns (CollectionOwnerFee memory);

    /// @notice Maps the collection address to the payment token that will be used for purchasing. If the address is the zero address, it will use the default paymentToken.
    function collectionToPaymentToken(address _collectionAddress)
        external
        view
        returns (address);

    /// @notice The address for weth.
    function weth() external view returns (address);

    /// @notice mapping for token bids (721/1155): nftAddress => tokneId => offeror
    function tokenBids(
        address _nftAddress,
        uint256 _tokenId,
        address _offeror
    ) external view returns (ListingOrBid memory);

    /// @notice mapping for collection level bids (721 only): nftAddress => offeror
    function collectionBids(address _nftAddress, address _offeror)
        external
        view
        returns (ListingOrBid memory);

    /// @notice Indicates if bid related functions are active.
    function areBidsActive() external view returns (bool);

    /// @notice The fee portion was updated
    /// @param  fee new fee amount (in units of basis points)
    event UpdateFee(uint256 fee);

    /// @notice The fee portion was updated for collections that have a collection owner.
    /// @param  fee new fee amount (in units of basis points)
    event UpdateFeeWithCollectionOwner(uint256 fee);

    /// @notice A collection's fees have changed
    /// @param  _collection  The collection
    /// @param  _recipient   The recipient of the fees. If the address is 0, the collection fees for this collection have been removed.
    /// @param  _fee         The fee amount (in units of basis points)
    event UpdateCollectionOwnerFee(
        address _collection,
        address _recipient,
        uint256 _fee
    );

    /// @notice The fee recipient was updated
    /// @param  feeRecipient the new recipient to get fees
    event UpdateFeeRecipient(address feeRecipient);

    /// @notice The approval status for a token was updated
    /// @param  nft    which token contract was updated
    /// @param  status the new status
    /// @param  paymentToken the token that will be used for payments for this collection
    event TokenApprovalStatusUpdated(
        address nft,
        TokenApprovalStatus status,
        address paymentToken
    );

    event TokenBidCreatedOrUpdated(
        address bidder,
        address nftAddress,
        uint256 tokenId,
        uint64 quantity,
        uint128 pricePerItem,
        uint64 expirationTime,
        address paymentToken
    );

    event CollectionBidCreatedOrUpdated(
        address bidder,
        address nftAddress,
        uint64 quantity,
        uint128 pricePerItem,
        uint64 expirationTime,
        address paymentToken
    );

    event TokenBidCancelled(
        address bidder,
        address nftAddress,
        uint256 tokenId
    );

    event CollectionBidCancelled(address bidder, address nftAddress);

    event BidAccepted(
        address seller,
        address bidder,
        address nftAddress,
        uint256 tokenId,
        uint64 quantity,
        uint128 pricePerItem,
        address paymentToken,
        BidType bidType
    );

    /// @notice An item was listed for sale
    /// @param  seller         the offeror of the item
    /// @param  nftAddress     which token contract holds the offered token
    /// @param  tokenId        the identifier for the offered token
    /// @param  quantity       how many of this token identifier are offered (or 1 for a ERC-721 token)
    /// @param  pricePerItem   the price (in units of the paymentToken) for each token offered
    /// @param  expirationTime UNIX timestamp after when this listing expires
    /// @param  paymentToken   the token used to list this item
    event ItemListed(
        address seller,
        address nftAddress,
        uint256 tokenId,
        uint64 quantity,
        uint128 pricePerItem,
        uint64 expirationTime,
        address paymentToken
    );

    /// @notice An item listing was updated
    /// @param  seller         the offeror of the item
    /// @param  nftAddress     which token contract holds the offered token
    /// @param  tokenId        the identifier for the offered token
    /// @param  quantity       how many of this token identifier are offered (or 1 for a ERC-721 token)
    /// @param  pricePerItem   the price (in units of the paymentToken) for each token offered
    /// @param  expirationTime UNIX timestamp after when this listing expires
    /// @param  paymentToken   the token used to list this item
    event ItemUpdated(
        address seller,
        address nftAddress,
        uint256 tokenId,
        uint64 quantity,
        uint128 pricePerItem,
        uint64 expirationTime,
        address paymentToken
    );

    /// @notice An item is no longer listed for sale
    /// @param  seller     former offeror of the item
    /// @param  nftAddress which token contract holds the formerly offered token
    /// @param  tokenId    the identifier for the formerly offered token
    event ItemCanceled(
        address indexed seller,
        address indexed nftAddress,
        uint256 indexed tokenId
    );

    /// @notice A listed item was sold
    /// @param  seller       the offeror of the item
    /// @param  buyer        the buyer of the item
    /// @param  nftAddress   which token contract holds the sold token
    /// @param  tokenId      the identifier for the sold token
    /// @param  quantity     how many of this token identifier where sold (or 1 for a ERC-721 token)
    /// @param  pricePerItem the price (in units of the paymentToken) for each token sold
    /// @param  paymentToken the payment token that was used to pay for this item
    event ItemSold(
        address seller,
        address buyer,
        address nftAddress,
        uint256 tokenId,
        uint64 quantity,
        uint128 pricePerItem,
        address paymentToken
    );

    /// @notice Perform initial contract setup
    /// @dev    The initializer modifier ensures this is only called once, the owner should confirm this was properly
    ///         performed before publishing this contract address.
    /// @param  _initialFee          fee to be paid on each sale, in basis points
    /// @param  _initialFeeRecipient wallet to collets fees
    /// @param  _initialPaymentToken address of the token that is used for settlement
    function initialize(
        uint256 _initialFee,
        address _initialFeeRecipient,
        address _initialPaymentToken
    ) external;

    /// @notice Creates an item listing. You must authorize this marketplace with your item's token contract to list.
    /// @param  _nftAddress     which token contract holds the offered token
    /// @param  _tokenId        the identifier for the offered token
    /// @param  _quantity       how many of this token identifier are offered (or 1 for a ERC-721 token)
    /// @param  _pricePerItem   the price (in units of the paymentToken) for each token offered
    /// @param  _expirationTime UNIX timestamp after when this listing expires
    function createListing(
        address _nftAddress,
        uint256 _tokenId,
        uint64 _quantity,
        uint128 _pricePerItem,
        uint64 _expirationTime,
        address _paymentToken
    ) external;

    /// @notice Updates an item listing
    /// @param  _nftAddress        which token contract holds the offered token
    /// @param  _tokenId           the identifier for the offered token
    /// @param  _newQuantity       how many of this token identifier are offered (or 1 for a ERC-721 token)
    /// @param  _newPricePerItem   the price (in units of the paymentToken) for each token offered
    /// @param  _newExpirationTime UNIX timestamp after when this listing expires
    function updateListing(
        address _nftAddress,
        uint256 _tokenId,
        uint64 _newQuantity,
        uint128 _newPricePerItem,
        uint64 _newExpirationTime,
        address _paymentToken
    ) external;

    /// @notice Remove an item listing
    /// @param  _nftAddress which token contract holds the offered token
    /// @param  _tokenId    the identifier for the offered token
    function cancelListing(address _nftAddress, uint256 _tokenId) external;

    function cancelManyBids(CancelBidParams[] calldata _cancelBidParams)
        external;

    /// @notice Creates a bid for a particular token.
    function createOrUpdateTokenBid(
        address _nftAddress,
        uint256 _tokenId,
        uint64 _quantity,
        uint128 _pricePerItem,
        uint64 _expirationTime,
        address _paymentToken
    ) external;

    function createOrUpdateCollectionBid(
        address _nftAddress,
        uint64 _quantity,
        uint128 _pricePerItem,
        uint64 _expirationTime,
        address _paymentToken
    ) external;

    function acceptCollectionBid(AcceptBidParams calldata _acceptBidParams)
        external;

    function acceptTokenBid(AcceptBidParams calldata _acceptBidParams) external;

    /// @notice Buy multiple listed items. You must authorize this marketplace with your payment token to completed the buy or purchase with eth if it is a weth collection.
    function buyItems(BuyItemParams[] calldata _buyItemParams) external payable;

    /// @notice Updates the fee amount which is collected during sales, for both collections with and without owner specific fees.
    /// @dev    This is callable only by the owner. Both fees may not exceed MAX_FEE
    /// @param  _newFee the updated fee amount is basis points
    function setFee(uint256 _newFee, uint256 _newFeeWithCollectionOwner)
        external;

    /// @notice Updates the fee amount which is collected during sales fro a specific collection
    /// @dev    This is callable only by the owner
    /// @param  _collectionAddress The collection in question. This must be whitelisted.
    /// @param _collectionOwnerFee The fee and recipient for the collection. If the 0 address is passed as the recipient, collection specific fees will not be collected.
    function setCollectionOwnerFee(
        address _collectionAddress,
        CollectionOwnerFee calldata _collectionOwnerFee
    ) external;

    /// @notice Updates the fee recipient which receives fees during sales
    /// @dev    This is callable only by the owner.
    /// @param  _newFeeRecipient the wallet to receive fees
    function setFeeRecipient(address _newFeeRecipient) external;

    /// @notice Sets a token as an approved kind of NFT or as ineligible for trading
    /// @dev    This is callable only by the owner.
    /// @param  _nft    address of the NFT to be approved
    /// @param  _status the kind of NFT approved, or NOT_APPROVED to remove approval
    function setTokenApprovalStatus(
        address _nft,
        TokenApprovalStatus _status,
        address _paymentToken
    ) external;

    function setWeth(address _wethAddress) external;

    function toggleAreBidsActive() external;

    /// @notice Pauses the marketplace, creatisgn and executing listings is paused
    /// @dev    This is callable only by the owner. Canceling listings is not paused.
    function pause() external;

    /// @notice Unpauses the marketplace, all functionality is restored
    /// @dev    This is callable only by the owner.
    function unpause() external;
}

struct BuyItemParams {
    /// which token contract holds the offered token
    address nftAddress;
    /// the identifier for the token to be bought
    uint256 tokenId;
    /// current owner of the item(s) to be bought
    address owner;
    /// how many of this token identifier to be bought (or 1 for a ERC-721 token)
    uint64 quantity;
    /// the maximum price (in units of the paymentToken) for each token offered
    uint128 maxPricePerItem;
    /// the payment token to be used
    address paymentToken;
    /// indicates if the user is purchasing this item with eth.
    bool usingEth;
}

struct AcceptBidParams {
    // Which token contract holds the given tokens
    address nftAddress;
    // The token id being given
    uint256 tokenId;
    // The user who created the bid initially
    address bidder;
    // The quantity of items being supplied to the bidder
    uint64 quantity;
    // The price per item that the bidder is offering
    uint128 pricePerItem;
    /// the payment token to be used
    address paymentToken;
}

struct CancelBidParams {
    BidType bidType;
    address nftAddress;
    uint256 tokenId;
}

enum BidType {
    TOKEN,
    COLLECTION
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

//           _____                    _____                   _______                   _____            _____                    _____                    _____                    _____
//          /\    \                  /\    \                 /::\    \                 /\    \          /\    \                  /\    \                  /\    \                  /\    \
//         /::\    \                /::\____\               /::::\    \               /::\____\        /::\    \                /::\____\                /::\    \                /::\    \
//        /::::\    \              /::::|   |              /::::::\    \             /:::/    /       /::::\    \              /:::/    /               /::::\    \              /::::\    \
//       /::::::\    \            /:::::|   |             /::::::::\    \           /:::/    /       /::::::\    \            /:::/   _/___            /::::::\    \            /::::::\    \
//      /:::/\:::\    \          /::::::|   |            /:::/~~\:::\    \         /:::/    /       /:::/\:::\    \          /:::/   /\    \          /:::/\:::\    \          /:::/\:::\    \
//     /:::/__\:::\    \        /:::/|::|   |           /:::/    \:::\    \       /:::/    /       /:::/__\:::\    \        /:::/   /::\____\        /:::/__\:::\    \        /:::/__\:::\    \
//     \:::\   \:::\    \      /:::/ |::|   |          /:::/    / \:::\    \     /:::/    /        \:::\   \:::\    \      /:::/   /:::/    /       /::::\   \:::\    \      /::::\   \:::\    \
//   ___\:::\   \:::\    \    /:::/  |::|___|______   /:::/____/   \:::\____\   /:::/    /       ___\:::\   \:::\    \    /:::/   /:::/   _/___    /::::::\   \:::\    \    /::::::\   \:::\    \
//  /\   \:::\   \:::\    \  /:::/   |::::::::\    \ |:::|    |     |:::|    | /:::/    /       /\   \:::\   \:::\    \  /:::/___/:::/   /\    \  /:::/\:::\   \:::\    \  /:::/\:::\   \:::\____\
// /::\   \:::\   \:::\____\/:::/    |:::::::::\____\|:::|____|     |:::|    |/:::/____/       /::\   \:::\   \:::\____\|:::|   /:::/   /::\____\/:::/  \:::\   \:::\____\/:::/  \:::\   \:::|    |
// \:::\   \:::\   \::/    /\::/    / ~~~~~/:::/    / \:::\    \   /:::/    / \:::\    \       \:::\   \:::\   \::/    /|:::|__/:::/   /:::/    /\::/    \:::\  /:::/    /\::/    \:::\  /:::|____|
//  \:::\   \:::\   \/____/  \/____/      /:::/    /   \:::\    \ /:::/    /   \:::\    \       \:::\   \:::\   \/____/  \:::\/:::/   /:::/    /  \/____/ \:::\/:::/    /  \/_____/\:::\/:::/    /
//   \:::\   \:::\    \                  /:::/    /     \:::\    /:::/    /     \:::\    \       \:::\   \:::\    \       \::::::/   /:::/    /            \::::::/    /            \::::::/    /
//    \:::\   \:::\____\                /:::/    /       \:::\__/:::/    /       \:::\    \       \:::\   \:::\____\       \::::/___/:::/    /              \::::/    /              \::::/    /
//     \:::\  /:::/    /               /:::/    /         \::::::::/    /         \:::\    \       \:::\  /:::/    /        \:::\__/:::/    /               /:::/    /                \::/____/
//      \:::\/:::/    /               /:::/    /           \::::::/    /           \:::\    \       \:::\/:::/    /          \::::::::/    /               /:::/    /                  ~~
//       \::::::/    /               /:::/    /             \::::/    /             \:::\    \       \::::::/    /            \::::::/    /               /:::/    /
//        \::::/    /               /:::/    /               \::/____/               \:::\____\       \::::/    /              \::::/    /               /:::/    /
//         \::/    /                \::/    /                 ~~                      \::/    /        \::/    /                \::/____/                \::/    /
//          \/____/                  \/____/                                           \/____/          \/____/                  ~~                       \/____/

struct BuyOrder {
    address assetAddress;
    uint256 tokenId;
    address seller;
    uint256 quantity;
    uint256 maxPricePerItem;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

//           _____                    _____                   _______                   _____            _____                    _____                    _____                    _____
//          /\    \                  /\    \                 /::\    \                 /\    \          /\    \                  /\    \                  /\    \                  /\    \
//         /::\    \                /::\____\               /::::\    \               /::\____\        /::\    \                /::\____\                /::\    \                /::\    \
//        /::::\    \              /::::|   |              /::::::\    \             /:::/    /       /::::\    \              /:::/    /               /::::\    \              /::::\    \
//       /::::::\    \            /:::::|   |             /::::::::\    \           /:::/    /       /::::::\    \            /:::/   _/___            /::::::\    \            /::::::\    \
//      /:::/\:::\    \          /::::::|   |            /:::/~~\:::\    \         /:::/    /       /:::/\:::\    \          /:::/   /\    \          /:::/\:::\    \          /:::/\:::\    \
//     /:::/__\:::\    \        /:::/|::|   |           /:::/    \:::\    \       /:::/    /       /:::/__\:::\    \        /:::/   /::\____\        /:::/__\:::\    \        /:::/__\:::\    \
//     \:::\   \:::\    \      /:::/ |::|   |          /:::/    / \:::\    \     /:::/    /        \:::\   \:::\    \      /:::/   /:::/    /       /::::\   \:::\    \      /::::\   \:::\    \
//   ___\:::\   \:::\    \    /:::/  |::|___|______   /:::/____/   \:::\____\   /:::/    /       ___\:::\   \:::\    \    /:::/   /:::/   _/___    /::::::\   \:::\    \    /::::::\   \:::\    \
//  /\   \:::\   \:::\    \  /:::/   |::::::::\    \ |:::|    |     |:::|    | /:::/    /       /\   \:::\   \:::\    \  /:::/___/:::/   /\    \  /:::/\:::\   \:::\    \  /:::/\:::\   \:::\____\
// /::\   \:::\   \:::\____\/:::/    |:::::::::\____\|:::|____|     |:::|    |/:::/____/       /::\   \:::\   \:::\____\|:::|   /:::/   /::\____\/:::/  \:::\   \:::\____\/:::/  \:::\   \:::|    |
// \:::\   \:::\   \::/    /\::/    / ~~~~~/:::/    / \:::\    \   /:::/    / \:::\    \       \:::\   \:::\   \::/    /|:::|__/:::/   /:::/    /\::/    \:::\  /:::/    /\::/    \:::\  /:::|____|
//  \:::\   \:::\   \/____/  \/____/      /:::/    /   \:::\    \ /:::/    /   \:::\    \       \:::\   \:::\   \/____/  \:::\/:::/   /:::/    /  \/____/ \:::\/:::/    /  \/_____/\:::\/:::/    /
//   \:::\   \:::\    \                  /:::/    /     \:::\    /:::/    /     \:::\    \       \:::\   \:::\    \       \::::::/   /:::/    /            \::::::/    /            \::::::/    /
//    \:::\   \:::\____\                /:::/    /       \:::\__/:::/    /       \:::\    \       \:::\   \:::\____\       \::::/___/:::/    /              \::::/    /              \::::/    /
//     \:::\  /:::/    /               /:::/    /         \::::::::/    /         \:::\    \       \:::\  /:::/    /        \:::\__/:::/    /               /:::/    /                \::/____/
//      \:::\/:::/    /               /:::/    /           \::::::/    /           \:::\    \       \:::\/:::/    /          \::::::::/    /               /:::/    /                  ~~
//       \::::::/    /               /:::/    /             \::::/    /             \:::\    \       \::::::/    /            \::::::/    /               /:::/    /
//        \::::/    /               /:::/    /               \::/____/               \:::\____\       \::::/    /              \::::/    /               /:::/    /
//         \::/    /                \::/    /                 ~~                      \::/    /        \::/    /                \::/____/                \::/    /
//          \/____/                  \/____/                                           \/____/          \/____/                  ~~                       \/____/

import "../../treasure/interfaces/ITroveMarketplace.sol";

interface ITroveSmolSweeper {
    event SuccessBuyItem(
        address indexed _nftAddress,
        uint256 _tokenId,
        address indexed _seller,
        address indexed _buyer,
        uint256 _quantity,
        uint256 _price
    );

    event CaughtFailureBuyItem(
        address indexed _nftAddress,
        uint256 _tokenId,
        address indexed _seller,
        address indexed _buyer,
        uint256 _quantity,
        uint256 _price,
        bytes _errorReason
    );

    function buyItemsSingleToken(
        BuyItemParams[] calldata _buyOrders,
        uint16 _inputSettingsBitFlag,
        address _inputTokenAddress,
        uint256 _maxSpendIncFees
    ) external payable;

    function buyItemsManyTokens(
        BuyItemParams[] calldata _buyOrders,
        uint16 _inputSettingsBitFlag,
        address[] calldata _inputTokenAddresses,
        uint256[] calldata _maxSpendIncFees
    ) external payable;

    function sweepItemsSingleToken(
        BuyItemParams[] calldata _buyOrders,
        uint16 _inputSettingsBitFlag,
        address _inputTokenAddress,
        uint256 _maxSpendIncFees,
        uint256 _minSpend,
        uint32 _maxSuccesses,
        uint32 _maxFailures
    ) external payable;

    function sweepItemsManyTokens(
        BuyItemParams[] calldata _buyOrders,
        uint16 _inputSettingsBitFlag,
        address[] calldata _inputTokenAddresses,
        uint256[] calldata _maxSpendIncFees,
        uint256[] calldata _minSpends,
        uint32 _maxSuccesses,
        uint32 _maxFailures
    ) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

//           _____                    _____                   _______                   _____            _____                    _____                    _____                    _____
//          /\    \                  /\    \                 /::\    \                 /\    \          /\    \                  /\    \                  /\    \                  /\    \
//         /::\    \                /::\____\               /::::\    \               /::\____\        /::\    \                /::\____\                /::\    \                /::\    \
//        /::::\    \              /::::|   |              /::::::\    \             /:::/    /       /::::\    \              /:::/    /               /::::\    \              /::::\    \
//       /::::::\    \            /:::::|   |             /::::::::\    \           /:::/    /       /::::::\    \            /:::/   _/___            /::::::\    \            /::::::\    \
//      /:::/\:::\    \          /::::::|   |            /:::/~~\:::\    \         /:::/    /       /:::/\:::\    \          /:::/   /\    \          /:::/\:::\    \          /:::/\:::\    \
//     /:::/__\:::\    \        /:::/|::|   |           /:::/    \:::\    \       /:::/    /       /:::/__\:::\    \        /:::/   /::\____\        /:::/__\:::\    \        /:::/__\:::\    \
//     \:::\   \:::\    \      /:::/ |::|   |          /:::/    / \:::\    \     /:::/    /        \:::\   \:::\    \      /:::/   /:::/    /       /::::\   \:::\    \      /::::\   \:::\    \
//   ___\:::\   \:::\    \    /:::/  |::|___|______   /:::/____/   \:::\____\   /:::/    /       ___\:::\   \:::\    \    /:::/   /:::/   _/___    /::::::\   \:::\    \    /::::::\   \:::\    \
//  /\   \:::\   \:::\    \  /:::/   |::::::::\    \ |:::|    |     |:::|    | /:::/    /       /\   \:::\   \:::\    \  /:::/___/:::/   /\    \  /:::/\:::\   \:::\    \  /:::/\:::\   \:::\____\
// /::\   \:::\   \:::\____\/:::/    |:::::::::\____\|:::|____|     |:::|    |/:::/____/       /::\   \:::\   \:::\____\|:::|   /:::/   /::\____\/:::/  \:::\   \:::\____\/:::/  \:::\   \:::|    |
// \:::\   \:::\   \::/    /\::/    / ~~~~~/:::/    / \:::\    \   /:::/    / \:::\    \       \:::\   \:::\   \::/    /|:::|__/:::/   /:::/    /\::/    \:::\  /:::/    /\::/    \:::\  /:::|____|
//  \:::\   \:::\   \/____/  \/____/      /:::/    /   \:::\    \ /:::/    /   \:::\    \       \:::\   \:::\   \/____/  \:::\/:::/   /:::/    /  \/____/ \:::\/:::/    /  \/_____/\:::\/:::/    /
//   \:::\   \:::\    \                  /:::/    /     \:::\    /:::/    /     \:::\    \       \:::\   \:::\    \       \::::::/   /:::/    /            \::::::/    /            \::::::/    /
//    \:::\   \:::\____\                /:::/    /       \:::\__/:::/    /       \:::\    \       \:::\   \:::\____\       \::::/___/:::/    /              \::::/    /              \::::/    /
//     \:::\  /:::/    /               /:::/    /         \::::::::/    /         \:::\    \       \:::\  /:::/    /        \:::\__/:::/    /               /:::/    /                \::/____/
//      \:::\/:::/    /               /:::/    /           \::::::/    /           \:::\    \       \:::\/:::/    /          \::::::::/    /               /:::/    /                  ~~
//       \::::::/    /               /:::/    /             \::::/    /             \:::\    \       \::::::/    /            \::::::/    /               /:::/    /
//        \::::/    /               /:::/    /               \::/____/               \:::\____\       \::::/    /              \::::/    /               /:::/    /
//         \::/    /                \::/    /                 ~~                      \::/    /        \::/    /                \::/____/                \::/    /
//          \/____/                  \/____/                                           \/____/          \/____/                  ~~                       \/____/

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

import "../../token/ANFTReceiver.sol";

error InvalidNFTAddress();
error FirstBuyReverted(bytes message);
error AllReverted();

abstract contract ABaseSmolSweeper is Ownable, ANFTReceiver, ERC165 {
    using SafeERC20 for IERC20;

    uint256 public constant FEE_BASIS_POINTS = 1_000_000;
    // uint256 public constant MINIMUM_SWEEP_AMOUNT_FOR_FEE = 1_000_000;
    uint256 public sweepFee = 0;

    function _calculateFee(uint256 _amount) internal view returns (uint256) {
        return (_amount * sweepFee) / FEE_BASIS_POINTS;
    }

    function calculateFee(uint256 _amount) external view returns (uint256) {
        return _calculateFee(_amount);
    }

    function _calculateAmountWithoutFees(uint256 _amountWithFee)
        internal
        view
        returns (uint256)
    {
        return ((_amountWithFee * FEE_BASIS_POINTS) /
            (FEE_BASIS_POINTS + sweepFee));
    }

    function calculateAmountAmountWithoutFees(uint256 _amountWithFee)
        external
        view
        returns (uint256)
    {
        return _calculateAmountWithoutFees(_amountWithFee);
    }

    function _setFee(uint256 _fee) internal {
        sweepFee = _fee;
    }

    function setFee(uint256 _fee) external onlyOwner {
        _setFee(_fee);
    }

    function _approveERC20TokenToContract(
        IERC20 _token,
        address _contract,
        uint256 _amount
    ) internal {
        _token.safeApprove(address(_contract), uint256(_amount));
    }

    function approveERC20TokenToContract(
        IERC20 _token,
        address _contract,
        uint256 _amount
    ) external onlyOwner {
        _approveERC20TokenToContract(_token, _contract, _amount);
    }

    // rescue functions
    // those have not been tested yet
    function transferETHTo(address payable _to, uint256 _amount)
        external
        onlyOwner
    {
        _to.transfer(_amount);
    }

    function transferERC20TokenTo(
        IERC20 _token,
        address _address,
        uint256 _amount
    ) external onlyOwner {
        _token.safeTransfer(address(_address), uint256(_amount));
    }

    function transferERC721To(
        IERC721 _token,
        address _to,
        uint256 _tokenId
    ) external onlyOwner {
        _token.safeTransferFrom(address(this), _to, _tokenId);
    }

    function transferERC1155To(
        IERC1155 _token,
        address _to,
        uint256[] calldata _tokenIds,
        uint256[] calldata _amounts,
        bytes calldata _data
    ) external onlyOwner {
        _token.safeBatchTransferFrom(
            address(this),
            _to,
            _tokenIds,
            _amounts,
            _data
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

/**
 * @dev Errors
 */

enum BuyError {
    NONE,
    BUY_ITEM_REVERTED,
    INSUFFICIENT_QUANTITY_ERC1155,
    EXCEEDING_MAX_SPEND
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
pragma solidity ^0.8.11;
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";

abstract contract AERC1155Receiver is IERC1155Receiver {
    /**
     * Always returns `IERC1155Receiver.onERC1155ReceivedFrom.selector`.
     */
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    /**
     * Always returns `IERC1155Receiver.onERC1155BatchReceived.selector`.
     */
    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

abstract contract AERC721Receiver is IERC721Receiver {
    /**
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
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