// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract SeaPortSig {
    enum ItemType {
    // 0: ETH on mainnet, MATIC on polygon, etc.
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


enum OrderType {
    // 0: no partial fills, anyone can execute
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
    address token;
    uint256 amount;
}

struct BalanceIn {
    address token;
    uint256 amount;
}



    function getElementIndexInArray(address addressToSearch, address[] memory visitedAddresses ) internal pure returns(uint256) {
        uint256 length = visitedAddresses.length;
        for (uint i; i < length; i++) {
            if (addressToSearch == visitedAddresses[i]) {
                return i;
            }
        }
        return length + 1;
    }


    function evalEIP712Buffer(OrderComponents memory order) public pure returns(BalanceOut[] memory balanceOut, BalanceIn[] memory balanceIn, uint256 expirationTime) { 
        BalanceOut[] memory tempBalanceOut = new BalanceOut[](order.offer.length);
        BalanceIn[] memory tempBalanceIn = new BalanceIn[](order.consideration.length);
        address[] memory outTokenAddresses = new address[](order.offer.length);
        address[] memory inTokenAddresses = new address[](order.consideration.length);

        uint256 outLength;
        for (uint i; i < order.offer.length; i++) {   
            uint256 index = getElementIndexInArray(order.offer[i].token, outTokenAddresses);
            if (index != outTokenAddresses.length + 1) {
                tempBalanceOut[index].amount += order.offer[i].startAmount;
            }
            else {
                outTokenAddresses[outLength] = order.offer[i].token;
                tempBalanceOut[outLength] = BalanceOut(order.offer[i].token, order.offer[i].startAmount);
                outLength++;
            }
        }

        uint256 inLength;
        for (uint i; i < order.consideration.length; i++) {   
            if (order.offerer == order.consideration[i].recipient) {
                uint256 index = getElementIndexInArray(order.consideration[i].token, inTokenAddresses);
                if (index != inTokenAddresses.length + 1 ) {
                    tempBalanceIn[index].amount += order.consideration[i].startAmount;
                }
                else {
                    inTokenAddresses[inLength] = order.consideration[i].token;
                    tempBalanceIn[inLength] = BalanceIn(order.consideration[i].token, order.consideration[i].startAmount);
                    inLength++; 
                }
            }  
        }

        balanceOut = new BalanceOut[](outLength+1);
        for (uint256 i; i <= outLength; i++) {
            balanceOut[i].token = tempBalanceOut[i].token;
            balanceOut[i].amount = tempBalanceOut[i].amount;
        }

        balanceIn = new BalanceIn[](inLength+1);
        for (uint256 i; i <= inLength; i++) {
            balanceIn[i].token = tempBalanceIn[i].token;
            balanceIn[i].amount = tempBalanceIn[i].amount;
        }

      return (balanceOut, balanceIn, order.endTime);
    }

    function evalEIP712BufferTest(OrderComponents memory order) public pure returns(BalanceOut[] memory balanceOut, BalanceIn[] memory balanceIn, uint256 expirationTime, uint256 inLength, uint256 outLength) { 
        BalanceOut[] memory tempBalanceOut = new BalanceOut[](order.offer.length);
        BalanceIn[] memory tempBalanceIn = new BalanceIn[](order.consideration.length);
        address[] memory outTokenAddresses = new address[](order.offer.length);
        address[] memory inTokenAddresses = new address[](order.consideration.length);

        uint256 outLength;
        for (uint i; i < order.offer.length; i++) {   
            uint256 index = getElementIndexInArray(order.offer[i].token, outTokenAddresses);
            if (index != outTokenAddresses.length + 1) {
                tempBalanceOut[index].amount += order.offer[i].startAmount;
            }
            else {
                outTokenAddresses[outLength] = order.offer[i].token;
                tempBalanceOut[outLength] = BalanceOut(order.offer[i].token, order.offer[i].startAmount);
                outLength++;
            }
        }

        uint256 inLength;
        for (uint i; i < order.consideration.length; i++) {   
            if (order.offerer == order.consideration[i].recipient) {
                uint256 index = getElementIndexInArray(order.consideration[i].token, inTokenAddresses);
                if (index != inTokenAddresses.length + 1 ) {
                    tempBalanceIn[index].amount += order.consideration[i].startAmount;
                }
                else {
                    inTokenAddresses[inLength] = order.consideration[i].token;
                    tempBalanceIn[inLength] = BalanceIn(order.consideration[i].token, order.consideration[i].startAmount);
                    inLength++; 
                }
            }  
        }
        return (tempBalanceOut, tempBalanceIn, order.endTime, inLength, outLength);
    }
}