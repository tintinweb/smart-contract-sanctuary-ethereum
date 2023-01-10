// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../data_type/Errors.sol";
import "../data_type/DataType.sol";
import "../storage/LibLaunchpadStorage.sol";
import "../libs/Ownable.sol";
import "../libs/ReentrancyGuard.sol";
import "../libs/FixinTokenSpender.sol";


contract LaunchpadFeature is Ownable, ReentrancyGuard, FixinTokenSpender {

    // buy nft from this launchpad
    function launchpadBuy(
        bytes4 /* proxyId */,
        bytes4 launchpadId,
        uint256 slotId,
        uint256 quantity,
        uint256[] calldata additional,
        bytes calldata data
    ) external payable nonReentrant {
        require(quantity > 0, "quantity must gt 0");
        require(quantity < type(uint16).max, Errors.LPAD_SLOT_MAX_BUY_QTY_PER_TX_LIMIT);

        uint256 ethBalanceBefore;
        assembly { ethBalanceBefore := sub(selfbalance(), callvalue()) }

        DataType.LaunchpadSlot memory slot = _getLaunchpadSlot(launchpadId, slotId);

        (bool success, uint256 alreadyBuyBty) = _getAlreadyBuyBty(slot);
        require(success, "_getAlreadyBuyBty failed");

        // get simulationBuy flag.
        uint256 simulationBuy;
        if (additional.length > DataType.BUY_ADDITIONAL_IDX_SIMULATION) {
            simulationBuy = additional[DataType.BUY_ADDITIONAL_IDX_SIMULATION];
        }

        // check input param
        if (simulationBuy < DataType.SIMULATION_NO_CHECK_PROCESS_REVERT) {
            uint256 maxWhitelistBuy;
            if (additional.length > DataType.BUY_ADDITIONAL_IDX_WL_MAX_BUY_NUM) {
                maxWhitelistBuy = additional[DataType.BUY_ADDITIONAL_IDX_WL_MAX_BUY_NUM];
            }

            _checkLaunchpadBuy(slot, alreadyBuyBty, quantity, maxWhitelistBuy, data, simulationBuy);

            if (simulationBuy == DataType.SIMULATION_CHECK_REVERT) {
                revert(Errors.LPAD_SIMULATE_BUY_OK);
            }
        }

        // Update total sale quantity if needed.
        if (slot.storeSaleQtyFlag) {
            bytes32 key = _getLaunchpadSlotKey(launchpadId, slotId);
            LibLaunchpadStorage.getStorage().launchpadSlots[key].saleQty += uint32(quantity);
        }

        // Update user buy quantity if needed.
        if (slot.storeAccountQtyFlag) {
            bytes32 key = _getAccountStatKey(launchpadId, slotId, msg.sender);
            LibLaunchpadStorage.getStorage().accountSlotStats[key].totalBuyQty += uint16(quantity);
        }

        uint256 currentPrice = _getCurrentPrice(slot);
        _transferFees(slot, quantity, currentPrice);
        _callLaunchpadBuy(slot, quantity, currentPrice, data);

        require(address(this).balance >= ethBalanceBefore, "refund error.");

        // simulate buy ok, then revert
        if (simulationBuy > DataType.SIMULATION_NONE) {
            revert(Errors.LPAD_SIMULATE_BUY_OK);
        }
    }

    function _getLaunchpadSlot(bytes4 launchpadId, uint256 slotId) internal view returns(DataType.LaunchpadSlot memory slot) {
        bytes32 key = _getLaunchpadSlotKey(launchpadId, slotId);
        slot = LibLaunchpadStorage.getStorage().launchpadSlots[key];

        require(slot.launchpadId == launchpadId, Errors.LPAD_INVALID_ID);
        require(slot.enable, Errors.LPAD_NOT_ENABLE);
        require(uint256(slot.slotId) == slotId, Errors.LPAD_SLOT_IDX_INVALID);
        require(slot.targetContract != address(0), Errors.LPAD_SLOT_TARGET_CONTRACT_INVALID);
        require(slot.mintSelector != bytes4(0), Errors.LPAD_SLOT_ABI_NOT_FOUND);
        if (!slot.storeAccountQtyFlag) {
            require(slot.queryAccountMintedQtySelector != bytes4(0), Errors.LPAD_SLOT_ABI_NOT_FOUND);
        }
    }

    function _getLaunchpadSlotKey(bytes4 launchpadId, uint256 slotId) internal pure returns(bytes32 key) {
        assembly {
            // bytes4(launchpadId) + bytes1(slotId) + bytes27(0)
            key := or(launchpadId, shl(216, and(slotId, 0xff)))
        }
    }

    function _getAccountStatKey(bytes4 launchpadId, uint256 slotId, address account) internal pure returns(bytes32 key) {
        assembly {
            // bytes4(launchpadId) + bytes1(slotId) + bytes7(0) + bytes20(accountAddress)
            key := or(or(launchpadId, shl(216, and(slotId, 0xff))), account)
        }
    }

    function _transferFees(DataType.LaunchpadSlot memory slot, uint256 buyQty, uint256 currentPrice) internal {
        uint256 shouldPay;
        unchecked {
            shouldPay = buyQty * currentPrice;
        }

        if (slot.paymentToken == address(0)) {
            require(msg.value == shouldPay, Errors.LPAD_SLOT_PAY_VALUE_NOT_ENOUGH);
            if (shouldPay > 0) {
                if (slot.feeType == 0 && slot.feeReceipt != address(0)) {
                    _transferEth(slot.feeReceipt, shouldPay);
                }
            }
        } else {
            if (shouldPay > 0) {
                require(slot.feeType == 0, "feeType error");
                require(slot.feeReceipt != address(0), "feeReceipt error");
                _transferERC20From(slot.paymentToken, msg.sender, slot.feeReceipt, shouldPay);
            }
        }
    }

    function _callLaunchpadBuy(DataType.LaunchpadSlot memory slot, uint256 buyQty, uint256 currentPrice, bytes calldata data) internal {
        uint256 price;
        // if paymentToken == ETH and need pay to targetContract, set pay price.
        if (slot.paymentToken == address(0) && slot.feeType != 0) {
            price = currentPrice;
        }

        // Get extraData
        uint256 extraOffset;
        // Skip whiteList signData if on whiteList stage
        if (
            slot.whiteListModel != DataType.WhiteListModel.NONE &&
            (slot.whiteListSaleStart == 0 || block.timestamp < slot.saleStart)
        ) {
            extraOffset = 65;
        }
        if (data.length < extraOffset) {
            revert("extra_data error");
        }

        bytes4 selector = slot.mintSelector;
        address targetContract = slot.targetContract;

        // mintParams
        //      0: mint(address to, extra_data)
        //      1: mint(address to, uint256 quantity, extra_data)
        if (slot.mintParams == 0) {
            assembly {
                let extraLength := sub(data.length, extraOffset)
                let calldataLength := add(0x24, extraLength)
                let ptr := mload(0x40) // free memory pointer

                mstore(ptr, selector)
                mstore(add(ptr, 0x04), caller())
                if extraLength {
                    calldatacopy(add(ptr, 0x24), add(data.offset, extraOffset), extraLength)
                }

                for { let i } lt(i, buyQty) { i := add(i, 1) } {
                    if iszero(call(gas(), targetContract, price, ptr, calldataLength, ptr, 0)) {
                        // Failed, copy the returned data and revert.
                        returndatacopy(0, 0, returndatasize())
                        revert(0, returndatasize())
                    }
                }
            }
        } else if (slot.mintParams == 1) {
            assembly {
                let extraLength := sub(data.length, extraOffset)
                let calldataLength := add(0x44, extraLength)
                let ptr := mload(0x40) // free memory pointer

                mstore(ptr, selector)
                mstore(add(ptr, 0x04), caller())
                mstore(add(ptr, 0x24), buyQty)
                if extraLength {
                    calldatacopy(add(ptr, 0x44), add(data.offset, extraOffset), extraLength)
                }

                if iszero(call(gas(), targetContract, mul(buyQty, price), ptr, calldataLength, ptr, 0)) {
                    // Failed, copy the returned data and revert.
                    returndatacopy(0, 0, returndatasize())
                    revert(0, returndatasize())
                }
            }
        } else {
            revert(Errors.LPAD_SLOT_ABI_NOT_FOUND);
        }
    }

    function _getAlreadyBuyBty(DataType.LaunchpadSlot memory slot) internal view returns(bool success, uint256 alreadyBuyBty) {
        if (slot.storeAccountQtyFlag) {
            bytes32 key = _getAccountStatKey(slot.launchpadId, slot.slotId, msg.sender);
            return (true, LibLaunchpadStorage.getStorage().accountSlotStats[key].totalBuyQty);
        } else {
            bytes4 selector = slot.queryAccountMintedQtySelector;
            address targetContract = slot.targetContract;
            assembly {
                let ptr := mload(0x40) // free memory pointer

                mstore(ptr, selector)
                mstore(add(ptr, 0x04), caller())

                if staticcall(gas(), targetContract, ptr, 0x24, ptr, 0x20) {
                    if eq(returndatasize(), 0x20) {
                        success := 1
                        alreadyBuyBty := mload(ptr)
                    }
                }
            }
            return (success, alreadyBuyBty);
        }
    }

    function _getCurrentPrice(DataType.LaunchpadSlot memory slot) internal view returns(uint256) {
        unchecked {
            if (slot.whiteListModel == DataType.WhiteListModel.NONE) {
                return slot.price * (10 ** slot.priceUint);
            } else if (slot.whiteListSaleStart > 0) { // first whiteList sale, then public sale
                uint256 price = (block.timestamp < slot.saleStart) ? slot.pricePresale : slot.price;
                return price * (10 ** slot.priceUint);
            } else { // whiteList sale
                uint256 price = slot.price > 0 ? slot.price : slot.pricePresale;
                return price * (10 ** slot.priceUint);
            }
        }
    }

    function _checkLaunchpadBuy(
        DataType.LaunchpadSlot memory slot,
        uint256 alreadyBuyBty,
        uint256 buyQty,
        uint256 maxWhitelistBuy,
        bytes calldata data,
        uint256 simulateBuy
    ) internal view {
        unchecked {
            if (slot.storeSaleQtyFlag) {
                // max supply check
                if (slot.saleQty + buyQty > uint256(slot.maxSupply)) {
                    revert(Errors.LPAD_SLOT_QTY_NOT_ENOUGH_TO_BUY);
                }
            }

            // endTime check
            require(block.timestamp < slot.saleEnd, Errors.LPAD_SLOT_SALE_END);

            if (slot.whiteListModel == DataType.WhiteListModel.NONE) {
                // startTime check
                if (block.timestamp < slot.saleStart) {
                    if (simulateBuy != DataType.SIMULATION_CHECK_SKIP_START_PROCESS_REVERT) {
                        revert(Errors.LPAD_SLOT_SALE_NOT_START);
                    }
                }
                // buy num check
                if (buyQty + alreadyBuyBty > slot.maxBuyQtyPerAccount) {
                    revert(Errors.LPAD_SLOT_ACCOUNT_MAX_BUY_LIMIT);
                }
            } else {
                // whitelist check
                if (simulateBuy == DataType.SIMULATION_CHECK_SKIP_WHITELIST_PROCESS_REVERT) {
                    return;
                }

                if (slot.whiteListSaleStart > 0) { // first whiteList sale, then public sale
                    // check startTime
                    if (block.timestamp < slot.whiteListSaleStart) {
                        if (simulateBuy != DataType.SIMULATION_CHECK_SKIP_START_PROCESS_REVERT) {
                            revert(Errors.LPAD_SLOT_WHITELIST_SALE_NOT_START);
                        }
                    }
                    if (block.timestamp < slot.saleStart) { // on whiteList sale
                        // buy num check
                        if (buyQty + alreadyBuyBty > maxWhitelistBuy) {
                            revert(Errors.LPAD_SLOT_WHITELIST_BUY_NUM_LIMIT);
                        }
                    } else { // on public sale
                        // buy num check
                        if (buyQty + alreadyBuyBty > slot.maxBuyQtyPerAccount) {
                            revert(Errors.LPAD_SLOT_ACCOUNT_MAX_BUY_LIMIT);
                        }
                        return;
                    }
                } else { // whiteList sale
                    // startTime check
                    if (block.timestamp < slot.saleStart) {
                        if (simulateBuy != DataType.SIMULATION_CHECK_SKIP_START_PROCESS_REVERT) {
                            revert(Errors.LPAD_SLOT_WHITELIST_SALE_NOT_START);
                        }
                    }
                    // buy num check
                    if (buyQty + alreadyBuyBty > maxWhitelistBuy) {
                        revert(Errors.LPAD_SLOT_WHITELIST_BUY_NUM_LIMIT);
                    }
                }

                // off chain sign model, check the signature and max buy num
                require(_offChainSignCheck(slot, msg.sender, maxWhitelistBuy, data), Errors.LPAD_SLOT_ACCOUNT_NOT_IN_WHITELIST);
            }
        }
    }

    // off-chain sign check
    function _offChainSignCheck(
        DataType.LaunchpadSlot memory slot,
        address account,
        uint256 maxBuyNum,
        bytes calldata signature
    ) internal view returns (bool success) {
        if (signature.length >= 65) {
            if (slot.signer == address(0)) {
                return false;
            }

            uint256 slotId = uint256(slot.slotId);
            bytes32 hash = keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    keccak256(abi.encodePacked(account, address(this), slot.launchpadId, slotId, maxBuyNum))
                )
            );

            bytes32 r;
            bytes32 s;
            uint8 v;
            assembly {
                r := calldataload(signature.offset)
                s := calldataload(add(signature.offset, 0x20))
                v := byte(0, calldataload(add(signature.offset, 0x40)))
            }
            return (ecrecover(hash, v, r, s) == slot.signer);
        }
        return false;
    }

    function isInWhiteList(
        bytes4 launchpadId,
        uint256 slotId,
        address[] calldata accounts,
        uint256[] calldata offChainMaxBuy,
        bytes[] calldata offChainSign
    ) external view returns (uint8[] memory wln) {
        wln = new uint8[](accounts.length);

        // off-chain sign check
        if (offChainSign.length > 0) {
            require(accounts.length == offChainMaxBuy.length && accounts.length == offChainSign.length, Errors.LPAD_INPUT_ARRAY_LEN_NOT_MATCH);

            bytes32 key = _getLaunchpadSlotKey(launchpadId, slotId);
            DataType.LaunchpadSlot memory slot = LibLaunchpadStorage.getStorage().launchpadSlots[key];

            for (uint256 i; i < accounts.length; i++) {
                if (_offChainSignCheck(slot, accounts[0], offChainMaxBuy[i], offChainSign[i])) {
                    wln[i] = uint8(offChainMaxBuy[i]);
                }
            }
        }
    }

    // hash for whitelist
    function hashForWhitelist(
        address account,
        bytes4 launchpadId,
        uint256 slot,
        uint256 maxBuy
    ) external view returns (bytes32) {
        return keccak256(abi.encodePacked(account, address(this), launchpadId, slot, maxBuy));
    }

    // get launchpad info
    function getLaunchpadInfo(bytes4 /* proxyId */, bytes4 launchpadId, uint256[] calldata /* params */) external view returns (
        bool[] memory boolData,
        uint256[] memory intData,
        address[] memory addressData,
        bytes[] memory bytesData
    ) {
        bytes32 key = _getLaunchpadSlotKey(launchpadId, 0);
        DataType.LaunchpadSlot memory slot = LibLaunchpadStorage.getStorage().launchpadSlots[key];

        boolData = new bool[](2);
        boolData[0] = slot.enable;
        boolData[1] = slot.enable;

        bytesData = new bytes[](1);
        bytesData[0] = abi.encodePacked(slot.launchpadId);

        addressData = new address[](3);
        addressData[0] = address(0); // controllerAdmin
        addressData[1] = address(this); // AssetProxyAddress
        // feeReceipt
        if (slot.feeType == 0) {
            addressData[2] = slot.feeReceipt != address(0) ? slot.feeReceipt : address(this);
        } else {
            addressData[2] = slot.targetContract;
        }

        uint256 slotsNum = 1;
        uint256 feesNum = 1;
        intData = new uint256[](4 + feesNum + slotsNum * 2);
        intData[0] = slotsNum;
        intData[1] = feesNum;
        intData[2] = 0; // ctlPermission
        intData[3] = 0; // referralFeePct
        intData[4] = 10000; // feePercent

        // getLaunchpadInfo is override function, can't change returns value, so use fees uint256[] as saleQuantity, openNum
        for (uint256 i = 5; i < intData.length; i += 2) {
            intData[i] = slot.saleQty;
            intData[i + 1] = 0;
        }
    }

    // get launchpad slot info
    function getLaunchpadSlotInfo(bytes4 /* proxyId */, bytes4 launchpadId, uint256 slotId) external view returns (
        bool[] memory boolData,
        uint256[] memory intData,
        address[] memory addressData,
        bytes4[] memory bytesData
    ) {
        bytes32 key = _getLaunchpadSlotKey(launchpadId, slotId);
        DataType.LaunchpadSlot memory slot = LibLaunchpadStorage.getStorage().launchpadSlots[key];
        if (launchpadId == 0 || launchpadId != slot.launchpadId || slotId != slot.slotId) {
            return (boolData, intData, addressData, bytesData); // invalid id or idx, return nothing
        }

        boolData = new bool[](6);
        boolData[0] = slot.enable; // launchpad enable
        boolData[1] = true; // can buy

        intData = new uint256[](13);
        intData[0] = uint256(slot.saleStart); // sale start
        intData[1] = uint256(slot.whiteListModel); // whitelist model, 0-no whitelist; 2-whitelist
        intData[2] = uint256(slot.maxSupply); // max supply
        intData[3] = uint256(slot.saleQty); // sale quantity
        intData[4] = uint256(slot.maxBuyQtyPerAccount); // maxBuyQtyPerAccount
        intData[5]  = _getCurrentPrice(slot);
        intData[6] = 0; // boxOpenStart
        intData[7] = 0; // startTokenId
        intData[8] = 0; // openedNum
        intData[9] = uint256(slot.saleEnd); // saleEnd
        intData[10] = uint256(slot.whiteListSaleStart); // whiteListSaleStart
        intData[11] = uint256(slot.pricePresale * (10 ** slot.priceUint)); // presale price
        intData[12] = uint256(slot.price * (10 ** slot.priceUint)); // public sale price

        addressData = new address[](3);
        addressData[0] = slot.paymentToken; // buyToken
        addressData[1] = slot.targetContract; // targetContract
        addressData[2] = address(this); // Element ERC20AssetProxy

        bytesData = new bytes4[](2);
        bytesData[0] = slot.mintSelector;
        bytesData[1] = slot.queryAccountMintedQtySelector;
    }

    function getAccountInfoInLaunchpad(
        bytes4 /* proxyId */,
        bytes4 launchpadId,
        uint256 slotId,
        uint256 quantity
    ) external view returns (
        bool[] memory boolData,
        uint256[] memory intData,
        bytes[] memory byteData
    ) {
        bytes32 key = _getLaunchpadSlotKey(launchpadId, slotId);
        DataType.LaunchpadSlot memory slot = LibLaunchpadStorage.getStorage().launchpadSlots[key];
        if (launchpadId == 0 || launchpadId != slot.launchpadId || slotId != slot.slotId) {
            return(boolData, intData, byteData); // invalid id or idx, return nothing
        }

        // launchpadId check
        boolData = new bool[](4);
        if (slot.whiteListModel == DataType.WhiteListModel.NONE) {
            boolData[0] = false; // whitelist model or not
            boolData[3] = false; // whitelist model or not
        } else {
            boolData[0] = true; // whitelist model or not
            boolData[3] = !(slot.whiteListSaleStart != 0 && block.timestamp >= slot.saleStart); // whitelist model or not
        }

        intData = new uint256[](6);
        intData[0] = slot.saleQty; // totalBuyQty
        // intData[1] // left buy quantity
        intData[2] = 0; // next buy time of this address

        // this whitelist user max can buy quantity
        intData[3] = (slot.whiteListModel == DataType.WhiteListModel.NONE) ? 0 : (quantity >> 128);
        quantity = uint256(quantity & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF); // low 128bit is the quantity want to buy

        // intData[1] - left buy quantity
        (, uint256 alreadyBuyBty) = _getAlreadyBuyBty(slot);
        if (boolData[3]) {
            intData[1] = (intData[3] > alreadyBuyBty) ? (intData[3] - alreadyBuyBty) : 0;
        } else {
            intData[1] = uint256(slot.maxBuyQtyPerAccount) - alreadyBuyBty;
        }

        byteData = new bytes[](2);
        byteData[1] = bytes("Do not support openBox");
        if (msg.sender != address(0)) {
            if (quantity > 0) {
                // check buy param
                byteData[0] = bytes(
                    _checkLaunchpadBuyWithoutRevert(
                        slot, alreadyBuyBty, quantity, intData[3]
                    )
                );
            }

            uint256 paymentNeeded = quantity * _getCurrentPrice(slot);
            if (slot.paymentToken != address(0)) { // ERC20
                // user balance now
                intData[4] = IERC20(slot.paymentToken).balanceOf(msg.sender); // user balance now
                // use balance is enough
                boolData[1] = intData[4] >= paymentNeeded;
                // user has approved
                boolData[2] = IERC20(slot.paymentToken).allowance(msg.sender, address(this)) >= paymentNeeded;
            } else { // ETH
                // user balance now
                intData[4] = msg.sender.balance;
                // use balance is enough
                boolData[1] = intData[4] > paymentNeeded;
                // user has approved
                boolData[2] = true;
            }

            if (msg.sender == slot.signer) {
                intData[5] = DataType.ROLE_LAUNCHPAD_SIGNER; // whitelist signer
            } else if (msg.sender == slot.feeReceipt) {
                intData[5] = DataType.ROLE_LAUNCHPAD_FEE_RECEIPTS; // whitelist signer
            } else if (
                msg.sender == owner() ||
                LibLaunchpadStorage.getStorage().administrators[msg.sender]
            ) {
                intData[5] = DataType.ROLE_PROXY_OWNER; // admin
            }
        } else {
            byteData[0] = bytes(Errors.OK);
        }
    }

    function _checkLaunchpadBuyWithoutRevert(
        DataType.LaunchpadSlot memory slot,
        uint256 alreadyBuyBty,
        uint256 buyQty,
        uint256 maxWhitelistBuy
    ) internal view returns(string memory errCode) {
        if (!slot.enable) {
            return Errors.LPAD_NOT_ENABLE;
        }
        if (slot.targetContract == address(0)) {
            return Errors.LPAD_SLOT_TARGET_CONTRACT_INVALID;
        }
        if (slot.mintSelector == bytes4(0)) {
            return Errors.LPAD_SLOT_ABI_NOT_FOUND;
        }
        if (!slot.storeAccountQtyFlag) {
            if (slot.queryAccountMintedQtySelector == bytes4(0)) {
                return Errors.LPAD_SLOT_ABI_NOT_FOUND;
            }
        }
        if (slot.storeSaleQtyFlag) {
            if ((slot.saleQty + buyQty) > uint256(slot.maxSupply)) {
                return Errors.LPAD_SLOT_QTY_NOT_ENOUGH_TO_BUY;
            }
        }
        if (block.timestamp >= slot.saleEnd) {
            return Errors.LPAD_SLOT_SALE_END;
        }
        if (slot.whiteListModel == DataType.WhiteListModel.NONE) {
            if (block.timestamp < slot.saleStart) {
                return Errors.LPAD_SLOT_SALE_NOT_START;
            }
            if (buyQty + alreadyBuyBty > slot.maxBuyQtyPerAccount) {
                return Errors.LPAD_SLOT_ACCOUNT_MAX_BUY_LIMIT;
            }
        } else {
            if (slot.whiteListSaleStart > 0) { // first whiteList sale, then public sale
                if (block.timestamp < slot.whiteListSaleStart) {
                    return Errors.LPAD_SLOT_WHITELIST_SALE_NOT_START;
                }
                if (block.timestamp < slot.saleStart) {
                    if (buyQty + alreadyBuyBty > maxWhitelistBuy) {
                        return Errors.LPAD_SLOT_WHITELIST_BUY_NUM_LIMIT;
                    }
                } else {
                    if (buyQty + alreadyBuyBty > slot.maxBuyQtyPerAccount) {
                        return Errors.LPAD_SLOT_ACCOUNT_MAX_BUY_LIMIT;
                    }
                }
            } else {
                if (block.timestamp < slot.saleStart) {
                    return Errors.LPAD_SLOT_WHITELIST_SALE_NOT_START;
                }
                if (buyQty + alreadyBuyBty > maxWhitelistBuy) {
                    return Errors.LPAD_SLOT_WHITELIST_BUY_NUM_LIMIT;
                }
            }
        }
        return Errors.OK;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;


library Errors {

    string public constant OK = '0'; // 'ok'
    string public constant PROXY_ID_NOT_EXIST = '1'; // 'proxy not exist'
    string public constant PROXY_ID_ALREADY_EXIST = '2'; // 'proxy id already exists'
    string public constant LPAD_ONLY_COLLABORATOR_OWNER = '3'; // 'only collaborator,owner can call'
    string public constant LPAD_ONLY_CONTROLLER_COLLABORATOR_OWNER = '4'; //  'only controller,collaborator,owner'
    string public constant LPAD_ONLY_AUTHORITIES_ADDRESS = '5'; // 'only authorities can call'
    string public constant TRANSFER_ETH_FAILED = '6'; // 'transfer eth failed'
    string public constant SENDER_MUST_TX_CALLER = '7'; // 'sender must transaction caller'

    string public constant LPAD_INVALID_ID  = '10';  // 'launchpad invalid id'
    string public constant LPAD_ID_EXISTS   = '11';  // 'launchpadId exists'
    string public constant LPAD_RECEIPT_ADDRESS_INVALID = '12'; // 'receipt must be valid address'
    string public constant LPAD_REFERRAL_FEE_PCT_LIMIT = '13'; // 'referral fee upper limit'
    string public constant LPAD_RECEIPT_MUST_NOT_CONTRACT = '14'; // 'receipt can't be contract address'
    string public constant LPAD_NOT_ENABLE = '15'; // 'launchpad not enable'
    string public constant LPAD_TRANSFER_TO_RECEIPT_FAIL = '16'; // 'transfer to receipt address failed'
    string public constant LPAD_TRANSFER_TO_REFERRAL_FAIL = '17'; // 'transfer to referral address failed'
    string public constant LPAD_TRANSFER_BACK_TO_SENDER_FAIL = '18'; // 'transfer back to sender address failed'
    string public constant LPAD_INPUT_ARRAY_LEN_NOT_MATCH = '19'; // 'input array len not match'
    string public constant LPAD_FEES_PERCENT_INVALID = '20'; // 'fees total percent is not 100%'
    string public constant LPAD_PARAM_LOCKED = '21'; // 'launchpad param locked'
    string public constant LPAD_TRANSFER_TO_LPAD_PROXY_FAIL = '22'; // 'transfer to lpad proxy failed'

    string public constant LPAD_SIMULATE_BUY_OK = '28'; // 'simulate buy ok'
    string public constant LPAD_SIMULATE_OPEN_OK = '29'; // 'simulate open ok'

    string public constant LPAD_SLOT_IDX_INVALID = '30'; // 'launchpad slot idx invalid'
    string public constant LPAD_SLOT_MAX_SUPPLY_INVALID = '31'; // 'max supply invalid'
    string public constant LPAD_SLOT_SALE_QUANTITY = '32'; // 'initial sale quantity must 0'
    string public constant LPAD_SLOT_TARGET_CONTRACT_INVALID = '33'; // "slot target contract address not valid"
    string public constant LPAD_SLOT_ABI_ARRAY_LEN = '34'; // "invalid abi selector array not equal max"
    string public constant LPAD_SLOT_MAX_BUY_QTY_INVALID = '35'; // "max buy qty invalid"
    string public constant LPAD_SLOT_FLAGS_ARRAY_LEN = '36'; // 'flag array len not equal max'
    string public constant LPAD_SLOT_TOKEN_ADDRESS_INVALID = '37';  // 'token must be valid address'
    string public constant LPAD_SLOT_BUY_DISABLE = '38'; // 'launchpad buy disable now'
    string public constant LPAD_SLOT_BUY_FROM_CONTRACT_NOT_ALLOWED = '39'; // 'buy from contract address not allowed)
    string public constant LPAD_SLOT_SALE_NOT_START = '40'; // 'sale not start yet'
    string public constant LPAD_SLOT_MAX_BUY_QTY_PER_TX_LIMIT = '41'; // 'max buy quantity one transaction limit'
    string public constant LPAD_SLOT_QTY_NOT_ENOUGH_TO_BUY = '42'; // 'quantity not enough to buy'
    string public constant LPAD_SLOT_PAYMENT_NOT_ENOUGH = '43'; // "payment not enough"
    string public constant LPAD_SLOT_PAYMENT_ALLOWANCE_NOT_ENOUGH = '44'; // 'allowance not enough'
    string public constant LPAD_SLOT_ACCOUNT_MAX_BUY_LIMIT = '45'; // "account max buy num limit"
    string public constant LPAD_SLOT_ACCOUNT_BUY_INTERVAL_LIMIT = '46'; // 'account buy interval limit'
    string public constant LPAD_SLOT_ACCOUNT_NOT_IN_WHITELIST = '47'; // 'not in whitelist'
    string public constant LPAD_SLOT_OPENBOX_DISABLE = '48'; // 'launchpad openbox disable now'
    string public constant LPAD_SLOT_OPENBOX_FROM_CONTRACT_NOT_ALLOWED = '49'; // 'not allowed to open from contract address'
    string public constant LPAD_SLOT_ABI_BUY_SELECTOR_INVALID = '50'; // 'buy selector invalid '
    string public constant LPAD_SLOT_ABI_OPENBOX_SELECTOR_INVALID = '51'; // 'openbox selector invalid '
    string public constant LPAD_SLOT_SALE_START_TIME_INVALID = '52'; // 'sale time invalid'
    string public constant LPAD_SLOT_OPENBOX_TIME_INVALID = '53'; // 'openbox time invalid'
    string public constant LPAD_SLOT_PRICE_INVALID = '54'; // 'price must > 0'
    string public constant LPAD_SLOT_CALL_BUY_CONTRACT_FAILED = '55'; // 'call buy contract fail'
    string public constant LPAD_SLOT_CALL_OPEN_CONTRACT_FAILED = '56'; // 'call open contract fail'
    string public constant LPAD_SLOT_CALL_0X_ERC20_PROXY_FAILED = '57'; // 'call 0x erc20 proxy fail'
    string public constant LPAD_SLOT_0X_ERC20_PROXY_INVALID = '58'; // '0x erc20 asset proxy invalid'
    string public constant LPAD_SLOT_ONLY_OPENBOX_WHEN_SOLD_OUT = '59'; // 'only can open box when sold out all'
    string public constant LPAD_SLOT_ERC20_BLC_NOT_ENOUGH = '60'; // "erc20 balance not enough"
    string public constant LPAD_SLOT_PAY_VALUE_NOT_ENOUGH = '61'; // "eth send value not enough"
    string public constant LPAD_SLOT_PAY_VALUE_NOT_NEED = '62'; // 'eth send value not need'
    string public constant LPAD_SLOT_PAY_VALUE_UPPER_NEED = '63'; // 'eth send value upper need value'
    string public constant LPAD_SLOT_OPENBOX_NOT_SUPPORT = '64'; // 'openbox not support'
    string public constant LPAD_SLOT_ERC20_TRANSFER_FAILED = '65'; // 'call erc20 transfer fail'
    string public constant LPAD_SLOT_OPEN_NUM_INIT = '66'; // 'initial open number must 0'
    string public constant LPAD_SLOT_ABI_NOT_FOUND = '67'; // 'not found abi to encode'
    string public constant LPAD_SLOT_SALE_END = '68'; // 'sale end'
    string public constant LPAD_SLOT_SALE_END_TIME_INVALID = '69'; // 'sale end time invalid'
    string public constant LPAD_SLOT_WHITELIST_BUY_NUM_LIMIT = '70'; // 'whitelist buy number limit'
    string public constant LPAD_CONTROLLER_NO_PERMISSION = '71'; // 'controller no permission'
    string public constant LPAD_SLOT_WHITELIST_SALE_NOT_START = '72'; // 'whitelist sale not start yet'
    string public constant LPAD_NOT_VALID_SIGNER = '73'; // 'not valid signer'
    string public constant LPAD_SLOT_WHITELIST_TIME_INVALID = '74'; // white list time invalid
    string public constant LPAD_INVALID_WHITELIST_SIGNATURE_LEN = '75'; // invalid whitelist signature length

    string public constant LPAD_SEPARATOR = ':'; // seprator :
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;


library  DataType {

    // process buy additional flag
    uint256 constant internal BUY_ADDITIONAL_IDX_WL_MAX_BUY_NUM = 0; // whitelist max buy number
    uint256 constant internal BUY_ADDITIONAL_IDX_SIMULATION     = 1; // simulation buy

    // role
    uint256 constant internal ROLE_LAUNCHPAD_FEE_RECEIPTS   = 1; // fee receipt
    uint256 constant internal ROLE_LAUNCHPAD_CONTROLLER     = 2; // launchpad controller
    uint256 constant internal ROLE_PROXY_OWNER              = 4; // proxy admin
    uint256 constant internal ROLE_LAUNCHPAD_SIGNER         = 8; // launchpad signer

    // simulation flag
    uint256 constant internal SIMULATION_NONE                       = 0; // no simulation
    uint256 constant internal SIMULATION_CHECK                      = 1; // check param
    uint256 constant internal SIMULATION_CHECK_REVERT               = 2; // check param, then revert
    uint256 constant internal SIMULATION_CHECK_PROCESS_REVERT       = 3; // check param & process, then revert
    uint256 constant internal SIMULATION_CHECK_SKIP_START_PROCESS_REVERT = 4; // escape check start time param, process, then revert
    uint256 constant internal SIMULATION_CHECK_SKIP_WHITELIST_PROCESS_REVERT = 5; // escape check skip whitelist param, process, then revert
    uint256 constant internal SIMULATION_CHECK_SKIP_BALANCE_PROCESS_REVERT = 6; // escape check skip whitelist param, process, then revert
    uint256 constant internal SIMULATION_NO_CHECK_PROCESS_REVERT    = 7; // escape check param, process, then revert

    enum WhiteListModel {
        NONE,                     // 0 - No White List
        ON_CHAIN_CHECK,           // 1 - Check address on-chain
        OFF_CHAIN_SIGN,           // 2 - Signed by off-chain valid address
        OFF_CHAIN_MERKLE_ROOT     // 3 - check off-chain merkle tree root
    }

    struct LaunchpadSlot {
        uint32 saleQty;    // current sale number, must from 0
        bytes4 launchpadId; // launchpad id
        uint8 slotId; // slot id
        bool enable;  // enable flag
        WhiteListModel whiteListModel;
        uint8 feeType; // 0 - to feeReceipt, 1 - to targetContract
        address feeReceipt;

        uint32 maxSupply; // max supply of this slot
        uint16 maxBuyQtyPerAccount; // max buy qty per address
        // finalPrice = price * (10 ** priceUint)
        uint16 pricePresale;
        uint16 price;
        uint16 priceUint;
        address paymentToken;

        uint32 saleStart; // buy start time, seconds
        uint32 saleEnd; // buy end time, seconds
        uint32 whiteListSaleStart; // whitelist start time
        address signer; // signers for whitelist

        bool storeSaleQtyFlag; // true - store， false - no need to store
        bool storeAccountQtyFlag; // true - store， false - no need to store
        uint8 mintParams;
        uint8 queryAccountMintedQtyParams;
        bytes4 mintSelector;
        bytes4 queryAccountMintedQtySelector;
        address targetContract; // target contract of 3rd project,
    }

    struct Launchpad {
        uint8 slotNum;
    }

    // stats info for buyer account
    struct AccountSlotStats {
        uint16 totalBuyQty; // total buy num already
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "../data_type/DataType.sol";


library LibLaunchpadStorage {

    uint256 constant STORAGE_ID_LAUNCHPAD = 2 << 128;

    struct Storage {
        mapping(address => bool) administrators;

        // bytes4(launchpadId) + bytes1(slotId) + bytes27(0)
        mapping(bytes32 => DataType.LaunchpadSlot) launchpadSlots;

        // bytes4(launchpadId) + bytes1(slotId) + bytes7(0) + bytes20(accountAddress)
        mapping(bytes32 => DataType.AccountSlotStats) accountSlotStats;
    }

    /// @dev Get the storage bucket for this contract.
    function getStorage() internal pure returns (Storage storage stor) {
        assembly { stor.slot := STORAGE_ID_LAUNCHPAD }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "../storage/LibOwnableStorage.sol";


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
abstract contract Ownable {

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        if (owner() == address(0)) {
            _transferOwnership(msg.sender);
        }
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return LibOwnableStorage.getStorage().owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
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
    function _transferOwnership(address newOwner) private {
        LibOwnableStorage.Storage storage stor = LibOwnableStorage.getStorage();
        address oldOwner = stor.owner;
        stor.owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "../storage/LibOwnableStorage.sol";


abstract contract ReentrancyGuard {

    constructor() {
        LibOwnableStorage.Storage storage stor = LibOwnableStorage.getStorage();
        if (stor.reentrancyStatus == 0) {
            stor.reentrancyStatus = 1;
        }
    }

    modifier nonReentrant() {
        LibOwnableStorage.Storage storage stor = LibOwnableStorage.getStorage();
        require(stor.reentrancyStatus == 1, "ReentrancyGuard: reentrant call");
        stor.reentrancyStatus = 2;
        _;
        stor.reentrancyStatus = 1;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;


/// @dev Helpers for moving tokens around.
abstract contract FixinTokenSpender {

    // Mask of the lower 20 bytes of a bytes32.
    uint256 constant private ADDRESS_MASK = ((1 << 160) - 1);

    /// @dev Transfers ERC20 tokens from `owner` to `to`.
    /// @param token The token to spend.
    /// @param owner The owner of the tokens.
    /// @param to The recipient of the tokens.
    /// @param amount The amount of `token` to transfer.
    function _transferERC20From(address token, address owner, address to, uint256 amount) internal {
        uint256 success;
        assembly {
            let ptr := mload(0x40) // free memory pointer

            // selector for transferFrom(address,address,uint256)
            mstore(ptr, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(add(ptr, 0x04), and(owner, ADDRESS_MASK))
            mstore(add(ptr, 0x24), and(to, ADDRESS_MASK))
            mstore(add(ptr, 0x44), amount)

            success := call(gas(), and(token, ADDRESS_MASK), 0, ptr, 0x64, ptr, 32)

            let rdsize := returndatasize()

            // Check for ERC20 success. ERC20 tokens should return a boolean,
            // but some don't. We accept 0-length return data as success, or at
            // least 32 bytes that starts with a 32-byte boolean true.
            success := and(
                success,                             // call itself succeeded
                or(
                    iszero(rdsize),                  // no return data, or
                    and(
                        iszero(lt(rdsize, 32)),      // at least 32 bytes
                        eq(mload(ptr), 1)            // starts with uint256(1)
                    )
                )
            )
        }
        require(success != 0, "_transferERC20/TRANSFER_FAILED");
    }

    /// @dev Transfers ERC20 tokens from ourselves to `to`.
    /// @param token The token to spend.
    /// @param to The recipient of the tokens.
    /// @param amount The amount of `token` to transfer.
    function _transferERC20(address token, address to, uint256 amount) internal {
        uint256 success;
        assembly {
            let ptr := mload(0x40) // free memory pointer

            // selector for transfer(address,uint256)
            mstore(ptr, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(add(ptr, 0x04), and(to, ADDRESS_MASK))
            mstore(add(ptr, 0x24), amount)

            success := call(gas(), and(token, ADDRESS_MASK), 0, ptr, 0x44, ptr, 32)

            let rdsize := returndatasize()

            // Check for ERC20 success. ERC20 tokens should return a boolean,
            // but some don't. We accept 0-length return data as success, or at
            // least 32 bytes that starts with a 32-byte boolean true.
            success := and(
                success,                             // call itself succeeded
                or(
                    iszero(rdsize),                  // no return data, or
                    and(
                        iszero(lt(rdsize, 32)),      // at least 32 bytes
                        eq(mload(ptr), 1)            // starts with uint256(1)
                    )
                )
            )
        }
        require(success != 0, "_transferERC20/TRANSFER_FAILED");
    }

    /// @dev Transfers some amount of ETH to the given recipient and
    ///      reverts if the transfer fails.
    /// @param recipient The recipient of the ETH.
    /// @param amount The amount of ETH to transfer.
    function _transferEth(address recipient, uint256 amount) internal {
        assembly {
            if amount {
                if iszero(call(gas(), recipient, amount, 0, 0, 0, 0)) {
                    // revert("_transferEth/TRANSFER_FAILED")
                    mstore(0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
                    mstore(0x20, 0x0000002000000000000000000000000000000000000000000000000000000000)
                    mstore(0x40, 0x0000001c5f7472616e736665724574682f5452414e534645525f4641494c4544)
                    mstore(0x60, 0)
                    revert(0, 0x64)
                }
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;


library LibOwnableStorage {

    uint256 constant STORAGE_ID_OWNABLE = 1 << 128;

    struct Storage {
        uint256 reentrancyStatus;
        address owner;
    }

    /// @dev Get the storage bucket for this contract.
    function getStorage() internal pure returns (Storage storage stor) {
        assembly { stor.slot := STORAGE_ID_OWNABLE }
    }
}