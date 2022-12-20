// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
// stable & fetch name https://goerli.etherscan.io/address/0x00d224b589c09cfcb7a602d933f66f8746fb005e#readContract
// stable regular (wihtout name)

contract SeaPortSigStable {
    string sigMessage =
        "This is a Seaport listing message, mostly used by OpenSea Dapp, be aware of the potential balance changes";

    enum ItemType
    // 0: ETH on mainnet, MATIC on polygon, etc.
    {
        NATIVE,
        // 1: ERC20 items (ERC777 and ERC20 analogues could also technically work)
        ERC20,
        // 2: ERC721 items
        ERC721,
        // 3: ERC1155 items
        ERC1155,
        // 4: ERC721 items where a number of tokenIds are supported
        ERC721_WITH_CRITERIA,
        // 5: ERC1155 items where a number of ids are supported
        ERC1155_WITH_CRITERIA
    }

    enum OrderType
    // 0: no partial fills, anyone can execute
    {
        FULL_OPEN,
        // 1: partial fills supported, anyone can execute
        PARTIAL_OPEN,
        // 2: no partial fills, only offerer or zone can execute
        FULL_RESTRICTED,
        // 3: partial fills supported, only offerer or zone can execute
        PARTIAL_RESTRICTED
    }

    struct OfferItem {
        ItemType itemType;
        address token;
        uint256 identifierOrCriteria;
        uint256 startAmount;
        uint256 endAmount;
    }

    struct ConsiderationItem {
        ItemType itemType;
        address token;
        uint256 identifierOrCriteria;
        uint256 startAmount;
        uint256 endAmount;
        address payable recipient;
    }

    struct OrderComponents {
        address offerer;
        address zone;
        OfferItem[] offer;
        ConsiderationItem[] consideration;
        OrderType orderType;
        uint256 startTime;
        uint256 endTime;
        bytes32 zoneHash;
        uint256 salt;
        bytes32 conduitKey;
        uint256 counter;
    }

    struct BalanceOut {
        uint256 amount;
        address token;
    }

    struct BalanceIn {
        uint256 amount;
        address token;
    }

    // need to manage array length because of the fact that default array values are 0x0 which represents 'native token'
    function getElementIndexInArray(address addressToSearch, uint256 arrayLength, address[] memory visitedAddresses)
        internal
        pure
        returns (uint256)
    {
        for (uint256 i; i < arrayLength; i++) {
            if (addressToSearch == visitedAddresses[i]) {
                return i;
            }
        }
        return visitedAddresses.length + 1;
    }

    function evalEIP712Buffer(OrderComponents memory order)
        public
        view
        returns (string memory, BalanceOut[] memory balanceOut, BalanceIn[] memory balanceIn, uint256 expirationTime)
    {
        BalanceOut[] memory tempBalanceOut = new BalanceOut[](order.offer.length);
        BalanceIn[] memory tempBalanceIn = new BalanceIn[](order.consideration.length);
        address[] memory outTokenAddresses = new address[](order.offer.length);
        address[] memory inTokenAddresses = new address[](order.consideration.length);

        uint256 outLength;
        for (uint256 i; i < order.offer.length; i++) {
            uint256 index = getElementIndexInArray(order.offer[i].token, outLength, outTokenAddresses);
            if (index != outTokenAddresses.length + 1) {
                tempBalanceOut[index].amount += order.offer[i].startAmount;
            } else {
                outTokenAddresses[outLength] = order.offer[i].token;
                tempBalanceOut[outLength] = BalanceOut(order.offer[i].startAmount, order.offer[i].token);
                outLength++;
            }
        }

        uint256 inLength;
        for (uint256 i; i < order.consideration.length; i++) {
            if (order.offerer == order.consideration[i].recipient) {
                uint256 index = getElementIndexInArray(order.consideration[i].token, inLength, inTokenAddresses);
                if (index != inTokenAddresses.length + 1) {
                    tempBalanceIn[index].amount += order.consideration[i].startAmount;
                } else {
                    inTokenAddresses[inLength] = order.consideration[i].token;
                    tempBalanceIn[inLength] =
                        BalanceIn(order.consideration[i].startAmount, order.consideration[i].token);
                    inLength++;
                }
            }
        }

        balanceOut = new BalanceOut[](outLength);
        for (uint256 i; i < outLength; i++) {
            balanceOut[i] = tempBalanceOut[i];
        }

        balanceIn = new BalanceIn[](inLength);
        for (uint256 i; i < inLength; i++) {
            balanceIn[i] = tempBalanceIn[i];
        }

        return (sigMessage, balanceOut, balanceIn, order.endTime);
    }
}