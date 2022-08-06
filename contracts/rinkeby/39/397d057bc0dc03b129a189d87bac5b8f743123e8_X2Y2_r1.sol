// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.0;
pragma abicoder v2;

import './IDelegate.sol';
import './IWETHUpgradable.sol';
import './MarketConsts.sol';
import './OwnableUpgradeable.sol';
import './Initializable.sol';
import './PausableUpgradeable.sol';
import './ReentrancyGuardUpgradeable.sol';
import './SafeERC20Upgradeable.sol';
import './ECDSA.sol';
//https://rinkeby.etherscan.io/tx/0xa3ea9d44e08d8073610b3c790fe434610a71eb6dbce1c3398d8c2e9e36c958f2

interface IX2Y2Run {
    function run1(
        Market.Order memory order,
        Market.SettleShared memory shared,
        Market.SettleDetail memory detail
    ) external returns (uint256);
}

contract X2Y2_r1 is
    Initializable,
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable,
    PausableUpgradeable,
    IX2Y2Run
{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    event EvProfit(bytes32 itemHash, address currency, address to, uint256 amount);
    event EvAuctionRefund(
        bytes32 indexed itemHash,
        address currency,
        address to,
        uint256 amount,
        uint256 incentive
    );
    event EvInventory(
        bytes32 indexed itemHash,
        address maker,
        address taker,
        uint256 orderSalt,
        uint256 settleSalt,
        uint256 intent,
        uint256 delegateType,
        uint256 deadline,
        IERC20Upgradeable currency,
        bytes dataMask,
        Market.OrderItem item,
        Market.SettleDetail detail
    );
    event EvSigner(address signer, bool isRemoval);
    event EvDelegate(address delegate, bool isRemoval);
    event EvFeeCapUpdate(uint256 newValue);
    event EvCancel(bytes32 indexed itemHash);
    event EvFailure(uint256 index, bytes error);

    mapping(address => bool) public delegates;
    mapping(address => bool) public signers;

    mapping(bytes32 => Market.InvStatus) public inventoryStatus;
    mapping(bytes32 => Market.OngoingAuction) public ongoingAuctions;

    uint256 public constant RATE_BASE = 1e6;
    uint256 public feeCapPct;
    IWETHUpgradable public weth;

    receive() external payable {}

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function initialize(uint256 feeCapPct_, address weth_) public initializer {
        feeCapPct = feeCapPct_;
        weth = IWETHUpgradable(weth_);

        __ReentrancyGuard_init_unchained();
        __Pausable_init_unchained();
        __Ownable_init_unchained();
    }

    function updateFeeCap(uint256 val) public virtual onlyOwner {
        feeCapPct = val;
        emit EvFeeCapUpdate(val);
    }

    function updateSigners(address[] memory toAdd, address[] memory toRemove)
        public
        virtual
        onlyOwner
    {
        for (uint256 i = 0; i < toAdd.length; i++) {
            signers[toAdd[i]] = true;
            emit EvSigner(toAdd[i], false);
        }
        for (uint256 i = 0; i < toRemove.length; i++) {
            delete signers[toRemove[i]];
            emit EvSigner(toRemove[i], true);
        }
    }

    function updateDelegates(address[] memory toAdd, address[] memory toRemove)
        public
        virtual
        onlyOwner
    {
        for (uint256 i = 0; i < toAdd.length; i++) {
            delegates[toAdd[i]] = true;
            emit EvDelegate(toAdd[i], false);
        }
        for (uint256 i = 0; i < toRemove.length; i++) {
            delete delegates[toRemove[i]];
            emit EvDelegate(toRemove[i], true);
        }
    }

    function cancel(
        bytes32[] memory itemHashes,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual nonReentrant whenNotPaused {
        require(deadline > block.timestamp, 'deadline reached');
        bytes32 hash = keccak256(abi.encode(itemHashes.length, itemHashes, deadline));
        address signer = ECDSA.recover(hash, v, r, s);
        require(signers[signer], 'Input signature error');

        for (uint256 i = 0; i < itemHashes.length; i++) {
            bytes32 h = itemHashes[i];
            if (inventoryStatus[h] == Market.InvStatus.NEW) {
                inventoryStatus[h] = Market.InvStatus.CANCELLED;
                emit EvCancel(h);
            }
        }
    }

    function run(Market.RunInput memory input) public payable virtual nonReentrant whenNotPaused {
        require(input.shared.deadline > block.timestamp, 'input deadline reached');
        require(msg.sender == input.shared.user, 'sender does not match');
        _verifyInputSignature(input);

        uint256 amountEth = msg.value;
        if (input.shared.amountToWeth > 0) {
            uint256 amt = input.shared.amountToWeth;
            weth.deposit{value: amt}();
            SafeERC20Upgradeable.safeTransfer(weth, msg.sender, amt);
            amountEth -= amt;
        }
        if (input.shared.amountToEth > 0) {
            uint256 amt = input.shared.amountToEth;
            SafeERC20Upgradeable.safeTransferFrom(weth, msg.sender, address(this), amt);
            weth.withdraw(amt);
            amountEth += amt;
        }

        for (uint256 i = 0; i < input.orders.length; i++) {
            _verifyOrderSignature(input.orders[i]);
        }

        for (uint256 i = 0; i < input.details.length; i++) {
            Market.SettleDetail memory detail = input.details[i];
            Market.Order memory order = input.orders[detail.orderIdx];
            if (input.shared.canFail) {
                try IX2Y2Run(address(this)).run1(order, input.shared, detail) returns (
                    uint256 ethPayment
                ) {
                    amountEth -= ethPayment;
                } catch Error(string memory _err) {
                    emit EvFailure(i, bytes(_err));
                } catch (bytes memory _err) {
                    emit EvFailure(i, _err);
                }
            } else {
                amountEth -= _run(order, input.shared, detail);
            }
        }
        if (amountEth > 0) {
            payable(msg.sender).transfer(amountEth);
        }
    }

    function run1(
        Market.Order memory order,
        Market.SettleShared memory shared,
        Market.SettleDetail memory detail
    ) external override virtual returns (uint256) {
        require(msg.sender == address(this), 'unsafe call');

        return _run(order, shared, detail);
    }

    function _hashItem(Market.Order memory order, Market.OrderItem memory item)
        internal
        view
        virtual
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    order.salt,
                    order.user,
                    order.network,
                    order.intent,
                    order.delegateType,
                    order.deadline,
                    order.currency,
                    order.dataMask,
                    item
                )
            );
    }

    function _emitInventory(
        bytes32 itemHash,
        Market.Order memory order,
        Market.OrderItem memory item,
        Market.SettleShared memory shared,
        Market.SettleDetail memory detail
    ) internal virtual {
        emit EvInventory(
            itemHash,
            order.user,
            shared.user,
            order.salt,
            shared.salt,
            order.intent,
            order.delegateType,
            order.deadline,
            order.currency,
            order.dataMask,
            item,
            detail
        );
    }

    function _run(
        Market.Order memory order,
        Market.SettleShared memory shared,
        Market.SettleDetail memory detail
    ) internal virtual returns (uint256) {
        uint256 nativeAmount = 0;

        Market.OrderItem memory item = order.items[detail.itemIdx];
        bytes32 itemHash = _hashItem(order, item);

        {
            require(itemHash == detail.itemHash, 'item hash does not match');
            require(order.network == block.chainid, 'wrong network');
            require(
                address(detail.executionDelegate) != address(0) &&
                    delegates[address(detail.executionDelegate)],
                'unknown delegate'
            );
        }

        bytes memory data = item.data;
        {
            if (order.dataMask.length > 0 && detail.dataReplacement.length > 0) {
                _arrayReplace(data, detail.dataReplacement, order.dataMask);
            }
        }

        if (detail.op == Market.Op.COMPLETE_SELL_OFFER) {
            require(inventoryStatus[itemHash] == Market.InvStatus.NEW, 'order already exists');
            require(order.intent == Market.INTENT_SELL, 'intent != sell');
            _assertDelegation(order, detail);
            require(order.deadline > block.timestamp, 'deadline reached');
            require(detail.price >= item.price, 'underpaid');

            nativeAmount = _takePayment(itemHash, order.currency, shared.user, detail.price);
            require(
                detail.executionDelegate.executeSell(order.user, shared.user, data),
                'delegation error'
            );

            _distributeFeeAndProfit(
                itemHash,
                order.user,
                order.currency,
                detail,
                detail.price,
                detail.price
            );
            inventoryStatus[itemHash] = Market.InvStatus.COMPLETE;
        } else if (detail.op == Market.Op.COMPLETE_BUY_OFFER) {
            require(inventoryStatus[itemHash] == Market.InvStatus.NEW, 'order already exists');
            require(order.intent == Market.INTENT_BUY, 'intent != buy');
            _assertDelegation(order, detail);
            require(order.deadline > block.timestamp, 'deadline reached');
            require(item.price == detail.price, 'price not match');

            require(!_isNative(order.currency), 'native token not supported');

            nativeAmount = _takePayment(itemHash, order.currency, order.user, detail.price);
            require(
                detail.executionDelegate.executeBuy(shared.user, order.user, data),
                'delegation error'
            );

            _distributeFeeAndProfit(
                itemHash,
                shared.user,
                order.currency,
                detail,
                detail.price,
                detail.price
            );
            inventoryStatus[itemHash] = Market.InvStatus.COMPLETE;
        } else if (detail.op == Market.Op.CANCEL_OFFER) {
            require(inventoryStatus[itemHash] == Market.InvStatus.NEW, 'unable to cancel');
            require(order.deadline > block.timestamp, 'deadline reached');
            inventoryStatus[itemHash] = Market.InvStatus.CANCELLED;
            emit EvCancel(itemHash);
        } else if (detail.op == Market.Op.BID) {
            require(order.intent == Market.INTENT_AUCTION, 'intent != auction');
            _assertDelegation(order, detail);
            bool firstBid = false;
            if (ongoingAuctions[itemHash].bidder == address(0)) {
                require(inventoryStatus[itemHash] == Market.InvStatus.NEW, 'order already exists');
                require(order.deadline > block.timestamp, 'auction ended');
                require(detail.price >= item.price, 'underpaid');

                firstBid = true;
                ongoingAuctions[itemHash] = Market.OngoingAuction({
                    price: detail.price,
                    netPrice: detail.price,
                    bidder: shared.user,
                    endAt: order.deadline
                });
                inventoryStatus[itemHash] = Market.InvStatus.AUCTION;

                require(
                    detail.executionDelegate.executeBid(order.user, address(0), shared.user, data),
                    'delegation error'
                );
            }

            Market.OngoingAuction storage auc = ongoingAuctions[itemHash];
            require(auc.endAt > block.timestamp, 'auction ended');

            nativeAmount = _takePayment(itemHash, order.currency, shared.user, detail.price);

            if (!firstBid) {
                require(
                    inventoryStatus[itemHash] == Market.InvStatus.AUCTION,
                    'order is not auction'
                );
                require(
                    detail.price - auc.price >= (auc.price * detail.aucMinIncrementPct) / RATE_BASE,
                    'underbid'
                );

                uint256 bidRefund = auc.netPrice;
                uint256 incentive = (detail.price * detail.bidIncentivePct) / RATE_BASE;
                if (bidRefund + incentive > 0) {
                    _transferTo(order.currency, auc.bidder, bidRefund + incentive);
                    emit EvAuctionRefund(
                        itemHash,
                        address(order.currency),
                        auc.bidder,
                        bidRefund,
                        incentive
                    );
                }

                require(
                    detail.executionDelegate.executeBid(order.user, auc.bidder, shared.user, data),
                    'delegation error'
                );

                auc.price = detail.price;
                auc.netPrice = detail.price - incentive;
                auc.bidder = shared.user;
            }

            if (block.timestamp + detail.aucIncDurationSecs > auc.endAt) {
                auc.endAt += detail.aucIncDurationSecs;
            }
        } else if (
            detail.op == Market.Op.REFUND_AUCTION ||
            detail.op == Market.Op.REFUND_AUCTION_STUCK_ITEM
        ) {
            require(
                inventoryStatus[itemHash] == Market.InvStatus.AUCTION,
                'cannot cancel non-auction order'
            );
            Market.OngoingAuction storage auc = ongoingAuctions[itemHash];

            if (auc.netPrice > 0) {
                _transferTo(order.currency, auc.bidder, auc.netPrice);
                emit EvAuctionRefund(
                    itemHash,
                    address(order.currency),
                    auc.bidder,
                    auc.netPrice,
                    0
                );
            }
            _assertDelegation(order, detail);

            if (detail.op == Market.Op.REFUND_AUCTION) {
                require(
                    detail.executionDelegate.executeAuctionRefund(order.user, auc.bidder, data),
                    'delegation error'
                );
            }
            delete ongoingAuctions[itemHash];
            inventoryStatus[itemHash] = Market.InvStatus.REFUNDED;
        } else if (detail.op == Market.Op.COMPLETE_AUCTION) {
            require(
                inventoryStatus[itemHash] == Market.InvStatus.AUCTION,
                'cannot complete non-auction order'
            );
            _assertDelegation(order, detail);
            Market.OngoingAuction storage auc = ongoingAuctions[itemHash];
            require(block.timestamp >= auc.endAt, 'auction not finished yet');

            require(
                detail.executionDelegate.executeAuctionComplete(order.user, auc.bidder, data),
                'delegation error'
            );
            _distributeFeeAndProfit(
                itemHash,
                order.user,
                order.currency,
                detail,
                auc.price,
                auc.netPrice
            );

            inventoryStatus[itemHash] = Market.InvStatus.COMPLETE;
            delete ongoingAuctions[itemHash];
        } else {
            revert('unknown op');
        }

        _emitInventory(itemHash, order, item, shared, detail);
        return nativeAmount;
    }

    function _assertDelegation(Market.Order memory order, Market.SettleDetail memory detail)
        internal
        view
        virtual
    {
        require(
            detail.executionDelegate.delegateType() == order.delegateType,
            'delegation type error'
        );
    }

    // modifies `src`
    function _arrayReplace(
        bytes memory src,
        bytes memory replacement,
        bytes memory mask
    ) internal view virtual {
        require(src.length == replacement.length);
        require(src.length == mask.length);

        for (uint256 i = 0; i < src.length; i++) {
            if (mask[i] != 0) {
                src[i] = replacement[i];
            }
        }
    }

    function _verifyInputSignature(Market.RunInput memory input) internal view virtual {
        bytes32 hash = keccak256(abi.encode(input.shared, input.details.length, input.details));
        address signer = ECDSA.recover(hash, input.v, input.r, input.s);
        require(signers[signer], 'Input signature error');
    }

    function _verifyOrderSignature(Market.Order memory order) internal view virtual {
        address orderSigner;

        if (order.signVersion == Market.SIGN_V1) {
            bytes32 orderHash = keccak256(
                abi.encode(
                    order.salt,
                    order.user,
                    order.network,
                    order.intent,
                    order.delegateType,
                    order.deadline,
                    order.currency,
                    order.dataMask,
                    order.items.length,
                    order.items
                )
            );
            orderSigner = ECDSA.recover(
                ECDSA.toEthSignedMessageHash(orderHash),
                order.v,
                order.r,
                order.s
            );
        } else {
            revert('unknown signature version');
        }

        require(orderSigner == order.user, 'Order signature does not match');
    }

    function _isNative(IERC20Upgradeable currency) internal view virtual returns (bool) {
        return address(currency) == address(0);
    }

    function _takePayment(
        bytes32 itemHash,
        IERC20Upgradeable currency,
        address from,
        uint256 amount
    ) internal virtual returns (uint256) {
        if (amount > 0) {
            if (_isNative(currency)) {
                return amount;
            } else {
                currency.safeTransferFrom(from, address(this), amount);
            }
        }
        return 0;
    }

    function _transferTo(
        IERC20Upgradeable currency,
        address to,
        uint256 amount
    ) internal virtual {
        if (amount > 0) {
            if (_isNative(currency)) {
                AddressUpgradeable.sendValue(payable(to), amount);
            } else {
                currency.safeTransfer(to, amount);
            }
        }
    }

    function _distributeFeeAndProfit(
        bytes32 itemHash,
        address seller,
        IERC20Upgradeable currency,
        Market.SettleDetail memory sd,
        uint256 price,
        uint256 netPrice
    ) internal virtual {
        require(price >= netPrice, 'price error');

        uint256 payment = netPrice;
        uint256 totalFeePct;

        for (uint256 i = 0; i < sd.fees.length; i++) {
            Market.Fee memory fee = sd.fees[i];
            totalFeePct += fee.percentage;
            uint256 amount = (price * fee.percentage) / RATE_BASE;
            payment -= amount;
            _transferTo(currency, fee.to, amount);
        }

        require(feeCapPct >= totalFeePct, 'total fee cap exceeded');

        _transferTo(currency, seller, payment);
        emit EvProfit(itemHash, address(currency), seller, payment);
    }
}