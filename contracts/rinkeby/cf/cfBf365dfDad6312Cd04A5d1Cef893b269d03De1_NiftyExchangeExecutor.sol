// SPDX-License-Identifier: UNLICENSED
// Copyright (c) 2022 Gemini Trust Company LLC. All Rights Reserved
pragma solidity 0.8.x;

import "./single/721/Single721.sol";
import "./single/721/SingleHandler721.sol";
import "./batch/721/Batch721.sol";
import "./batch/721/BatchHandler721.sol";
import "./single/1155/Single1155.sol";
import "./single/1155/SingleHandler1155.sol";
import "./batch/1155/Batch1155.sol";
import "./batch/1155/BatchHandler1155.sol";
import "./switcher/Switcher.sol";
import "./switcher/SwitcherHandler.sol";

/**
 * @notice We're hiring Solidity engineers! Let's get nifty!
 *         https://www.gemini.com/careers/nifty-gateway
 */
contract NiftyExchangeExecutor is Single721, 
                                  SingleHandler721, 
                                  Batch721, 
                                  BatchHandler721, 
                                  Single1155, 
                                  SingleHandler1155, 
                                  Batch1155, 
                                  BatchHandler1155,
                                  Switcher,
                                  SwitcherHandler {

    constructor(address priceCurrencyUSD_, address recoveryAdmin_, address[] memory validSenders_) ExecutorCore(priceCurrencyUSD_, recoveryAdmin_, validSenders_) {
    }

    function withdraw(address recipient, uint256 value) external {
        _requireOnlyValidSender();
        _transferEth(recipient, value);
    }

    function withdraw20(address tokenContract, address recipient, uint256 amount) external {
        _requireOnlyValidSender();
        _transfer20(amount, tokenContract, recipient);
    }

    function withdraw721(address tokenContract, address recipient, uint256 tokenId) external {
        _requireOnlyValidSender();
        IERC721(tokenContract).safeTransferFrom(address(this), recipient, tokenId);
    }

}

// SPDX-License-Identifier: UNLICENSED
// Copyright (c) 2022 Gemini Trust Company LLC. All Rights Reserved
pragma solidity 0.8.x;

import "../../core/ExecutorCore.sol";

/**
 *
 */
abstract contract Single721 is ExecutorCore {

    /**
     * 0
     */
    function recordSale721(
        uint256 tokenId,
        address tokenContract,
        uint256 price,
        address priceCurrency) external {
        _requireOnlyValidSender();
        _recordSale721(tokenContract, tokenId, price, priceCurrency);
    }

    /**
     * #1
     */
    function executeSaleUsd721(
        uint256 tokenId,
        address tokenContract,
        uint256 price,
        address seller,
        address buyer) external {
        _requireOnlyValidSender();
        _transfer721(price, _priceCurrencyUSD, tokenId, tokenContract, seller, buyer);
    }

    /**
     * #2
     */
    function executeSaleEth721(
        uint256 tokenId, 
        address tokenContract,
        uint256 price, 
        address seller,
        uint256 sellerProceeds,
        address buyer) external payable {
        _requireOnlyValidSender();
        _transfer721(price, _priceCurrencyETH, tokenId, tokenContract, seller, buyer);
        _transferEth(seller, sellerProceeds);
    }

    /**
     * #3
     */
    function executeSaleToken721(
        uint256 tokenId, 
        address tokenContract,
        uint256 price,
        address priceCurrency,
        address seller,
        uint256 sellerProceeds, 
        address buyer) external {
        _requireOnlyValidSender();
        _transfer721(price, priceCurrency, tokenId, tokenContract, seller, buyer);
        _transfer20(sellerProceeds, priceCurrency, seller);
    }

    /**
     * #4
     */
    function executeSaleReceiver1eth721(
        uint256 tokenId,
        address tokenContract,
        uint256 price,
        address seller,
        uint256 sellerProceeds,
        address buyer,
        address receiverCreator, 
        uint256 receiverAmount) external payable {
        _requireOnlyValidSender();
        _transfer721(price, _priceCurrencyETH, tokenId, tokenContract, seller, buyer);
        _transferEth(seller, sellerProceeds); 
        _transferEth(receiverCreator, receiverAmount); 
    }

    /**
     * #5
     */
    function executeSaleReceiver1token721(
        address receiverCreator, 
        uint256 receiverAmount, 
        address priceCurrency,
        NiftyEvent calldata ne) external {
        _requireOnlyValidSender();
        address seller = ne.seller;
        _transfer721(ne.price, priceCurrency, ne.tokenId, ne.tokenContract, seller, ne.buyer);
        _transfer20(ne.sellerProceeds, priceCurrency, seller);
        _transfer20(receiverAmount, priceCurrency, receiverCreator);
    }

    /**
     * #6
     */
    function executeSaleReceiverNeth721(
        address[] calldata receiverCreators, 
        uint256[] calldata receiverAmounts, 
        NiftyEvent calldata ne) external payable {
        _requireOnlyValidSender();
        address seller = ne.seller;
        _transfer721(ne.price, _priceCurrencyETH, ne.tokenId, ne.tokenContract, seller, ne.buyer);
        _transferEth(seller, ne.sellerProceeds);
        for(uint256 i = 0; i < receiverCreators.length; i++){
            _transferEth(receiverCreators[i], receiverAmounts[i]);
        }
    }

    /**
     * #7
     */
    function executeSaleReceiverNtoken721(
        address[] calldata receiverCreators,
        uint256[] calldata receiverAmounts,
        address priceCurrency,
        NiftyEvent calldata ne) external {
        _requireOnlyValidSender();
        address seller = ne.seller;
        _transfer721(ne.price, priceCurrency, ne.tokenId, ne.tokenContract, seller, ne.buyer);
        _transfer20(ne.sellerProceeds, priceCurrency, seller);
        for(uint256 i = 0; i < receiverCreators.length; i++){
            _transfer20(receiverAmounts[i], priceCurrency, receiverCreators[i]);
        }
    }

}

// SPDX-License-Identifier: UNLICENSED
// Copyright (c) 2022 Gemini Trust Company LLC. All Rights Reserved
pragma solidity 0.8.x;

import "../../core/ExecutorCore.sol";

/**
 *
 */
abstract contract SingleHandler721 is ExecutorCore {    

    /**
     * #2x
     */
    function executeSaleEth721handler(
        uint256 refund,
        uint256 price, 
        uint256 sellerProceeds, 
        uint256 tokenId, 
        address tokenContract, 
        address seller, 
        address buyer) external payable {
        _requireOnlyValidSender();
        bool success = _transfer721handler(price, _priceCurrencyETH, tokenId, tokenContract, seller, buyer);
        if(success){
            _transferEth(seller, sellerProceeds);
        } else {
            _transferEth(buyer, refund);
        }
    }

    /**
     * #3x
     */
    function executeSaleToken721handler(
        uint256 refund,
        uint256 price, 
        uint256 sellerProceeds, 
        address priceCurrency, 
        uint256 tokenId, 
        address tokenContract, 
        address seller, 
        address buyer) external {
        _requireOnlyValidSender();
        bool success = _transfer721handler(price, priceCurrency, tokenId, tokenContract, seller, buyer);
        if(success){
            _transfer20(sellerProceeds, priceCurrency, seller);
        } else {
            _transfer20(refund, priceCurrency, buyer);
        }
    }

    /**
     * #4x
     */
    function executeSaleReceiver1eth721handler(
        uint256 refund,
        address receiverCreator, 
        uint256 receiverAmount, 
        uint256 price, 
        uint256 sellerProceeds, 
        uint256 tokenId, 
        address tokenContract, 
        address seller, 
        address buyer) external payable {
        _requireOnlyValidSender();
        bool success = _transfer721handler(price, _priceCurrencyETH, tokenId, tokenContract, seller, buyer);
        if(success){
            _transferEth(seller, sellerProceeds);
            _transferEth(receiverCreator, receiverAmount);
        } else {
            _transferEth(buyer, refund);
        }
    }

    /**
     * #5x
     */
    function executeSaleReceiver1token721handler(
        address receiverCreator, 
        uint256 receiverAmount, 
        address priceCurrency,
        NiftyEventHandler calldata ne) external {
        _requireOnlyValidSender();
        address seller = ne.seller;
        address buyer = ne.buyer;
        bool success = _transfer721handler(ne.price, priceCurrency, ne.tokenId, ne.tokenContract, seller, buyer);
        if(success){
            _transfer20(ne.sellerProceeds, priceCurrency, seller);
            _transfer20(receiverAmount, priceCurrency, receiverCreator);
        } else {
            _transfer20(ne.refund, priceCurrency, buyer);
        }
    }

    /**
     * #6x
     */
    function executeSaleReceiverNeth721handler(
        address[] calldata receiverCreators, 
        uint256[] calldata receiverAmounts, 
        NiftyEventHandler calldata ne) external payable {
        _requireOnlyValidSender();
        address seller = ne.seller;
        address buyer = ne.buyer;
        bool success = _transfer721handler(ne.price, _priceCurrencyETH, ne.tokenId, ne.tokenContract, seller, buyer);
        if(success){
            _transferEth(seller, ne.sellerProceeds);
            for(uint256 i = 0; i < receiverCreators.length; i++){
                _transferEth(receiverCreators[i], receiverAmounts[i]);
            }
        } else {
            _transferEth(buyer, ne.refund);
        }
    }

    /**
     * #7x
     */
    function executeSaleReceiverNtoken721handler(
        address[] calldata receiverCreators,
        uint256[] calldata receiverAmounts,
        address priceCurrency,
        NiftyEventHandler calldata ne) external {
        _requireOnlyValidSender();
        address seller = ne.seller;
        address buyer = ne.buyer;
        bool success = _transfer721handler(ne.price, priceCurrency, ne.tokenId, ne.tokenContract, seller, buyer);
        if(success){
            _transfer20(ne.sellerProceeds, priceCurrency, seller);
            for(uint256 i = 0; i < receiverCreators.length; i++){
                _transfer20(receiverAmounts[i], priceCurrency, receiverCreators[i]);
            }
        } else {
            _transfer20(ne.refund, priceCurrency, buyer);
        }
    }

}

// SPDX-License-Identifier: UNLICENSED
// Copyright (c) 2022 Gemini Trust Company LLC. All Rights Reserved
pragma solidity 0.8.x;

import "../../core/ExecutorCore.sol";

/**
 *
 */
abstract contract Batch721 is ExecutorCore {    

    /** 
     * 0
     */
    function recordSale721batch(
        address[] calldata tokenContract, 
        uint256[] calldata tokenId, 
        uint256[] calldata price, 
        address[] calldata priceCurrency) external {
        _requireOnlyValidSender();
        for (uint256 i = 0; i < tokenContract.length; i++) {
            _recordSale721(tokenContract[i], tokenId[i], price[i], priceCurrency[i]);
        }
    }

    /** 
     * 1 
     */
    function executeSaleUsd721batch(
        uint256[] calldata price, 
        uint256[] calldata tokenId, 
        address[] calldata tokenContract, 
        address[] calldata seller, 
        address[] calldata buyer) external {
        _requireOnlyValidSender();
        for(uint256 i = 0; i < tokenContract.length; i++){
            _transfer721(price[i], _priceCurrencyUSD, tokenId[i], tokenContract[i], seller[i], buyer[i]);
        }
    }

    /**
     * 2
     */
    function executeSaleEth721batch(
        uint256[] calldata price, 
        uint256[] calldata sellerProceeds, 
        uint256[] calldata tokenId, 
        address[] calldata tokenContract, 
        address[] calldata seller, 
        address[] calldata buyer) external payable {
        _requireOnlyValidSender();
        for(uint256 i = 0; i < tokenContract.length; i++){
            _transfer721(price[i], _priceCurrencyETH, tokenId[i], tokenContract[i], seller[i], buyer[i]);
            _transferEth(seller[i], sellerProceeds[i]);
        }    
    }

    /** 
     * 3
     */
    function executeSaleToken721batch( 
        address[] calldata priceCurrency, 
        NiftyEvent[] calldata ne) external {
        _requireOnlyValidSender();
        for(uint256 i = 0; i < ne.length; i++){
            address seller = ne[i].seller;
            address currency = priceCurrency[i];
            _transfer721(ne[i].price, currency, ne[i].tokenId, ne[i].tokenContract, seller, ne[i].buyer);
            _transfer20(ne[i].sellerProceeds, currency, seller);
        } 
    }

    /** 
     * 6
     */
    function executeSaleReceiverNeth721batch(
        address[][] calldata receiverCreators, 
        uint256[][] calldata receiverAmounts, 
        NiftyEvent[] calldata ne) external payable {
        _requireOnlyValidSender();
        for(uint256 i = 0; i < ne.length; i++){            
            address seller = ne[i].seller;
            _transfer721(ne[i].price, _priceCurrencyETH, ne[i].tokenId, ne[i].tokenContract, seller, ne[i].buyer); 
            _transferEth(seller, ne[i].sellerProceeds);
            for(uint256 j = 0; j < receiverCreators[i].length; j++){
                _transferEth(receiverCreators[i][j], receiverAmounts[i][j]);
            }
        } 
    }

    /**
     * 7
     */
    function executeSaleReceiverNtoken721batch(NiftyEventReceiver[] calldata ne) external {
        _requireOnlyValidSender();
        for(uint256 i = 0; i < ne.length; i++){            
            address seller = ne[i].seller;
            address currency = ne[i].priceCurrency;
            _transfer721(ne[i].price, currency, ne[i].tokenId, ne[i].tokenContract, seller, ne[i].buyer); 
            _transfer20(ne[i].sellerProceeds, currency, seller);
            for(uint256 j = 0; j < ne[i].receiverCreators.length; j++){
                _transfer20(ne[i].receiverAmounts[j], currency, ne[i].receiverCreators[j]);
            }
        } 
    }

}

// SPDX-License-Identifier: UNLICENSED
// Copyright (c) 2022 Gemini Trust Company LLC. All Rights Reserved
pragma solidity 0.8.x;

import "../../core/ExecutorCore.sol";

/**
 *
 */
abstract contract BatchHandler721 is ExecutorCore {

    /**
     * 2
     */
    function executeSaleEth721batchHandler(NiftyEventHandler[] calldata ne) external payable {
        _requireOnlyValidSender();
        for(uint256 i = 0; i < ne.length; i++){
            address seller = ne[i].seller;
            address buyer = ne[i].buyer;
            bool success = _transfer721handler(ne[i].price, _priceCurrencyETH, ne[i].tokenId, ne[i].tokenContract, seller, buyer);
            if(success){
                _transferEth(seller, ne[i].sellerProceeds);
            } else {
                _transferEth(buyer, ne[i].refund);
            }
        } 
    }

    /** 
     * 3
     */
    function executeSaleToken721batchHandler( 
        address[] calldata priceCurrency, 
        NiftyEventHandler[] calldata ne) external {
        _requireOnlyValidSender();
        for(uint256 i = 0; i < ne.length; i++){    
            address seller = ne[i].seller;
            address buyer = ne[i].buyer;
            address currency = priceCurrency[i];
            bool success = _transfer721handler(ne[i].price, currency, ne[i].tokenId, ne[i].tokenContract, seller, buyer);
            if(success){
                _transfer20(ne[i].sellerProceeds, currency, seller);
            } else {
                _transfer20(ne[i].refund, currency, buyer);
            }
        } 
    }

    /**
     * 6
     */
    function executeSaleReceiverNeth721batchHandler(
        address[][] calldata receiverCreators, 
        uint256[][] calldata receiverAmounts, 
        NiftyEventHandler[] calldata ne) external payable {
        _requireOnlyValidSender();
        for(uint256 i = 0; i < ne.length; i++){
            address seller = ne[i].seller;
            address buyer = ne[i].buyer;
            bool success = _transfer721handler(ne[i].price, _priceCurrencyETH, ne[i].tokenId, ne[i].tokenContract, seller, buyer);
            if(success){
                _transferEth(seller, ne[i].sellerProceeds);
                for(uint256 j = 0; j < receiverCreators[i].length; j++){
                    _transferEth(receiverCreators[i][j], receiverAmounts[i][j]);
                }
            } else {
                _transferEth(buyer, ne[i].refund);
            }
        }
    }

    /**
     * 7
     */
    function executeSaleReceiverNtoken721batchHandler(NiftyEventReceiverHandler[] calldata ne) external {
        _requireOnlyValidSender();
        for(uint256 i = 0; i < ne.length; i++){            
            address seller = ne[i].seller;
            address currency = ne[i].priceCurrency;
            address buyer = ne[i].buyer;
            bool success = _transfer721handler(ne[i].price, currency, ne[i].tokenId, ne[i].tokenContract, seller, buyer);
            if(success){
                _transfer20(ne[i].sellerProceeds, currency, seller);
                for(uint256 j = 0; j < ne[i].receiverCreators.length; j++){
                    _transfer20(ne[i].receiverAmounts[j], currency, ne[i].receiverCreators[j]);
                }
            } else {
                _transfer20(ne[i].refund, currency, buyer);
            }
        }
    }

}

// SPDX-License-Identifier: UNLICENSED
// Copyright (c) 2022 Gemini Trust Company LLC. All Rights Reserved
pragma solidity 0.8.x;

import "../../core/ExecutorCore.sol";

/**
 *
 */
abstract contract Single1155 is ExecutorCore {
    
    /**
     * #0.5
     */
    function recordSale1155(address tokenContract, uint256 tokenId, uint256 count, uint256 price, address priceCurrency) external {
        _requireOnlyValidSender();
        _recordSale1155(tokenContract, tokenId, count, price, priceCurrency);
    }

    /**
     * #1.5
     */
    function executeSaleUsd1155(
        uint256 count,
        uint256 price,
        uint256 tokenId, 
        address tokenContract, 
        address seller, 
        address buyer) external {
        _requireOnlyValidSender();
        _transfer1155(count, price, _priceCurrencyUSD, tokenId, tokenContract, seller, buyer);
    }

    /**
     * #2.5
     */
    function executeSaleEth1155(
        uint256 count, 
        uint256 price, 
        uint256 sellerProceeds, 
        uint256 tokenId, 
        address tokenContract, 
        address seller, 
        address buyer) external payable {
        _requireOnlyValidSender();
        _transfer1155(count, price, _priceCurrencyETH, tokenId, tokenContract, seller, buyer);
        _transferEth(seller, sellerProceeds);   
    }

    /**
     * #3.5
     */
    function executeSaleToken1155(
        uint256 count, 
        uint256 price, 
        uint256 sellerProceeds, 
        address priceCurrency, 
        uint256 tokenId, 
        address tokenContract, 
        address seller, 
        address buyer) external {
        _requireOnlyValidSender();
        _transfer1155(count, price, priceCurrency, tokenId, tokenContract, seller, buyer);
        _transfer20(sellerProceeds, priceCurrency, seller);
    }

    /**
     * #4.5
     */
    function executeSaleReceiver1eth1155(
        uint256 count, 
        address receiverCreator, 
        uint256 receiverAmount, 
        uint256 price, 
        uint256 sellerProceeds, 
        uint256 tokenId, 
        address tokenContract, 
        address seller, 
        address buyer) external payable {
        _requireOnlyValidSender();
        _transfer1155(count, price, _priceCurrencyETH, tokenId, tokenContract, seller, buyer);
        _transferEth(seller, sellerProceeds); 
        _transferEth(receiverCreator, receiverAmount); 
    }

    /**
     * #5.5
     */
    function executeSaleReceiver1token1155(
        uint256 count,
        address receiverCreator, 
        uint256 receiverAmount, 
        address priceCurrency, 
        NiftyEvent calldata ne) external {
        _requireOnlyValidSender();
        address seller = ne.seller;
        _transfer1155(count, ne.price, priceCurrency, ne.tokenId, ne.tokenContract, seller, ne.buyer);
        _transfer20(ne.sellerProceeds, priceCurrency, seller);
        _transfer20(receiverAmount, priceCurrency, receiverCreator);
    }

    /**
     * #6.5
     */
    function executeSaleReceiverNeth1155(
        uint256 count,
        address[] calldata receiverCreators, 
        uint256[] calldata receiverAmounts, 
        NiftyEvent calldata ne) external payable {
        _requireOnlyValidSender();
        address seller = ne.seller;
        _transfer1155(count, ne.price, _priceCurrencyETH, ne.tokenId, ne.tokenContract, seller, ne.buyer);
        _transferEth(seller, ne.sellerProceeds);
        for(uint256 i = 0; i < receiverCreators.length; i++){
            _transferEth(receiverCreators[i], receiverAmounts[i]);
        }
    }

    /**
     * #7.5
     */
    function executeSaleReceiverNtoken1155(
        uint256 count, 
        address[] calldata receiverCreators,
        uint256[] calldata receiverAmounts,
        address priceCurrency,
        NiftyEvent calldata ne) external {
        _requireOnlyValidSender();
        address seller = ne.seller;
        _transfer1155(count, ne.price, priceCurrency, ne.tokenId, ne.tokenContract, seller, ne.buyer);
        _transfer20(ne.sellerProceeds, priceCurrency, seller);
        for(uint256 i = 0; i < receiverCreators.length; i++){
            _transfer20(receiverAmounts[i], priceCurrency, receiverCreators[i]);
        }
    }

}

// SPDX-License-Identifier: UNLICENSED
// Copyright (c) 2022 Gemini Trust Company LLC. All Rights Reserved
pragma solidity 0.8.x;

import "../../core/ExecutorCore.sol";

/**
 *
 */
abstract contract SingleHandler1155 is ExecutorCore {
    
    /**
     * #2.5x
     */
    function executeSaleEth1155handler(
        uint256 count,
        uint256 refund,
        uint256 price, 
        uint256 sellerProceeds, 
        uint256 tokenId, 
        address tokenContract, 
        address seller, 
        address buyer) external payable {
        _requireOnlyValidSender();
        bool success = _transfer1155handler(count, price, _priceCurrencyETH, tokenId, tokenContract, seller, buyer);
        if(success){
            _transferEth(seller, sellerProceeds);
        } else {
            _transferEth(buyer, refund);
        } 
    }

    /**
     * #3.5x
     */
    function executeSaleToken1155handler(
        uint256 count,
        uint256 refund,
        uint256 price, 
        uint256 sellerProceeds, 
        address priceCurrency, 
        uint256 tokenId, 
        address tokenContract, 
        address seller, 
        address buyer) external {
        _requireOnlyValidSender();
        bool success = _transfer1155handler(count, price, priceCurrency, tokenId, tokenContract, seller, buyer);
        if(success){
            _transfer20(sellerProceeds, priceCurrency, seller);
        } else {
            _transfer20(refund, priceCurrency, buyer);
        }
    }

    /**
     * #4.5x
     */
    function executeSaleReceiver1eth1155handler(
        uint256 count,
        uint256 refund,
        address receiverCreator, 
        uint256 receiverAmount, 
        uint256 price, 
        uint256 sellerProceeds, 
        uint256 tokenId, 
        address tokenContract, 
        address seller, 
        address buyer) external payable {
        _requireOnlyValidSender();
        bool success = _transfer1155handler(count, price, _priceCurrencyETH, tokenId, tokenContract, seller, buyer);
        if(success){
            _transferEth(seller, sellerProceeds);
            _transferEth(receiverCreator, receiverAmount);
        } else {
            _transferEth(buyer, refund);
        }
    }

    /**
     * #5.5x
     */
    function executeSaleReceiver1token1155handler(
        uint256 count,
        address receiverCreator, 
        uint256 receiverAmount, 
        address priceCurrency, 
        NiftyEventHandler calldata ne) external {
        _requireOnlyValidSender();
        address seller = ne.seller;
        address buyer = ne.buyer;
        bool success = _transfer1155handler(count, ne.price, priceCurrency, ne.tokenId, ne.tokenContract, seller, ne.buyer);
        if(success){
            _transfer20(ne.sellerProceeds, priceCurrency, seller);
            _transfer20(receiverAmount, priceCurrency, receiverCreator);
        } else {
            _transfer20(ne.refund, priceCurrency, buyer);
        }
    }

    /**
     * #6.5x
     */
    function executeSaleReceiverNeth1155handler(
        uint256 count,
        address[] calldata receiverCreators, 
        uint256[] calldata receiverAmounts, 
        NiftyEventHandler calldata ne) external payable {
        _requireOnlyValidSender();
        address seller = ne.seller;
        address buyer = ne.buyer;
        bool success = _transfer1155handler(count, ne.price, _priceCurrencyETH, ne.tokenId, ne.tokenContract, seller, ne.buyer);
        if(success){
            _transferEth(seller, ne.sellerProceeds);
            for(uint256 i = 0; i < receiverCreators.length; i++){
                _transferEth(receiverCreators[i], receiverAmounts[i]);
            }
        } else {
            _transferEth(buyer, ne.refund);
        }
    }

    /**
     * #7.5x
     */
    function executeSaleReceiverNtoken1155handler(
        uint256 count,
        address[] calldata receiverCreators,
        uint256[] calldata receiverAmounts,
        address priceCurrency,
        NiftyEventHandler calldata ne) external {
        _requireOnlyValidSender();
        address seller = ne.seller;
        address buyer = ne.buyer;
        bool success = _transfer1155handler(count, ne.price, priceCurrency, ne.tokenId, ne.tokenContract, seller, buyer);
        if(success){
            _transfer20(ne.sellerProceeds, priceCurrency, seller);
            for(uint256 i = 0; i < receiverCreators.length; i++){
                _transfer20(receiverAmounts[i], priceCurrency, receiverCreators[i]);
            }
        } else {
            _transfer20(ne.refund, priceCurrency, buyer);
        }
    }

}

// SPDX-License-Identifier: UNLICENSED
// Copyright (c) 2022 Gemini Trust Company LLC. All Rights Reserved
pragma solidity 0.8.x;

import "../../core/ExecutorCore.sol";

/**
 *
 */
abstract contract Batch1155 is ExecutorCore {    

    /** 
     * 0.5
     */
    function recordSale1155batch(
        uint256[] calldata count, 
        address[] calldata tokenContract, 
        uint256[] calldata tokenId,
        uint256[] calldata price, 
        address[] calldata priceCurrency) external {
        _requireOnlyValidSender();
        for (uint256 i = 0; i < tokenContract.length; i++) {
            _recordSale1155(tokenContract[i], tokenId[i], count[i], price[i], priceCurrency[i]);
        }
    }

    /** 
     * 1.5
     */
    function executeSaleUsd1155batch(
        uint256[] calldata count,
        uint256[] calldata price,
        uint256[] calldata tokenId, 
        address[] calldata tokenContract, 
        address[] calldata seller, 
        address[] calldata buyer) external {
        _requireOnlyValidSender();
        for(uint256 i = 0; i < tokenContract.length; i++){
            _transfer1155(count[i], price[i], _priceCurrencyUSD, tokenId[i], tokenContract[i], seller[i], buyer[i]);
        }
    }

    /** 
     * 2.5
     */
    function executeSaleEth1155batch(
        uint256[] calldata count,
        NiftyEvent[] calldata ne) external payable {
        _requireOnlyValidSender();
        for(uint256 i = 0; i < ne.length; i++){
            _transfer1155(count[i], ne[i].price, _priceCurrencyETH, ne[i].tokenId, ne[i].tokenContract, ne[i].seller, ne[i].buyer);
            _transferEth(ne[i].seller, ne[i].sellerProceeds);
        }  
    }

    /** 
     * 3.5
     */
    function executeSaleToken1155batch(
        uint256[] calldata count, 
        address[] calldata priceCurrency, 
        NiftyEvent[] calldata ne) external {
        _requireOnlyValidSender();
        for(uint256 i = 0; i < ne.length; i++){
            address seller = ne[i].seller;
            address currency = priceCurrency[i];
            _transfer1155(count[i], ne[i].price, currency, ne[i].tokenId, ne[i].tokenContract, seller, ne[i].buyer);
            _transfer20(ne[i].sellerProceeds, currency, seller);
        } 
    }

    /** 
     * 6.5
     */
    function executeSaleReceiverNeth1155batch(
        uint256[] calldata count,
        address[][] calldata receiverCreators, 
        uint256[][] calldata receiverAmounts,  
        NiftyEvent[] calldata ne) external payable {
        _requireOnlyValidSender();
        for(uint256 i = 0; i < ne.length; i++){            
            address seller = ne[i].seller;
            _transfer1155(count[i], ne[i].price, _priceCurrencyETH, ne[i].tokenId, ne[i].tokenContract, seller, ne[i].buyer);
            _transferEth(seller, ne[i].sellerProceeds);
            for(uint256 j = 0; j < receiverCreators[i].length; j++){
                _transferEth(receiverCreators[i][j], receiverAmounts[i][j]);
            }
        } 
    }

    /** 
     * 7.5
     */
    function executeSaleReceiverNtoken1155batch(uint256[] calldata count, NiftyEventReceiver[] calldata ne) external {
        _requireOnlyValidSender();
        for(uint256 i = 0; i < ne.length; i++){            
            address seller = ne[i].seller;
            address currency = ne[i].priceCurrency;
            _transfer1155(count[i], ne[i].price, currency, ne[i].tokenId, ne[i].tokenContract, seller, ne[i].buyer);
            _transfer20(ne[i].sellerProceeds, currency, seller);
            for(uint256 j = 0; j < ne[i].receiverCreators.length; j++){
                _transfer20(ne[i].receiverAmounts[j], currency, ne[i].receiverCreators[j]);
            }
        } 
    }

}

// SPDX-License-Identifier: UNLICENSED
// Copyright (c) 2022 Gemini Trust Company LLC. All Rights Reserved
pragma solidity 0.8.x;

import "../../core/ExecutorCore.sol";

/**
 *
 */
abstract contract BatchHandler1155 is ExecutorCore {

    /**
     * 2.5x
     */
    function executeSaleEth1155batchHandler(
        uint256[] calldata count,
        NiftyEventHandler[] calldata ne) external payable {
        _requireOnlyValidSender();
        for(uint256 i = 0; i < ne.length; i++){
            address seller = ne[i].seller;
            address buyer = ne[i].buyer;
            bool success = _transfer1155handler(count[i], ne[i].price, _priceCurrencyETH, ne[i].tokenId, ne[i].tokenContract, seller, buyer);
            if(success){
                _transferEth(seller, ne[i].sellerProceeds);
            } else {
                _transferEth(buyer, ne[i].refund);
            } 
        } 
    }

    /**
     * 3.5x
     */
    function executeSaleToken1155batchHandler(
        uint256[] calldata count, 
        address[] calldata priceCurrency, 
        NiftyEventHandler[] calldata ne) external {
        _requireOnlyValidSender();
        for(uint256 i = 0; i < ne.length; i++){    
            address seller = ne[i].seller;
            address buyer = ne[i].buyer;
            address currency = priceCurrency[i];
            bool success = _transfer1155handler(count[i], ne[i].price, currency, ne[i].tokenId, ne[i].tokenContract, seller, buyer);
            if(success){
                _transfer20(ne[i].sellerProceeds, currency, seller);
            } else {
                _transfer20(ne[i].refund, currency, buyer);
            }
        } 
    }

    /**
     * 6.5x
     */
    function executeSaleReceiverNeth1155batchHandler(
        uint256[] calldata count,
        address[][] calldata receiverCreators, 
        uint256[][] calldata receiverAmounts,  
        NiftyEventHandler[] calldata ne) external payable {
        _requireOnlyValidSender();
        for(uint256 i = 0; i < ne.length; i++){
            address seller = ne[i].seller;
            address buyer = ne[i].buyer;
            bool success = _transfer1155handler(count[i], ne[i].price, _priceCurrencyETH, ne[i].tokenId, ne[i].tokenContract, seller, buyer);
            if(success){
                _transferEth(seller, ne[i].sellerProceeds);
                for(uint256 j = 0; j < receiverCreators[i].length; j++){
                    _transferEth(receiverCreators[i][j], receiverAmounts[i][j]);
                }
            } else {
                _transferEth(buyer, ne[i].refund);
            }
        }
    }

    /**
     * 7.5x
     */
    function executeSaleReceiverNtoken1155batchHandler(uint256[] calldata count, NiftyEventReceiverHandler[] calldata ne) external {
        _requireOnlyValidSender();
        for(uint256 i = 0; i < ne.length; i++){            
            address seller = ne[i].seller;
            address currency = ne[i].priceCurrency;
            address buyer = ne[i].buyer;
            bool success = _transfer1155handler(count[i], ne[i].price, currency, ne[i].tokenId, ne[i].tokenContract, seller, buyer);
            if(success){
                _transfer20(ne[i].sellerProceeds, currency, seller);
                for(uint256 j = 0; j < ne[i].receiverCreators.length; j++){
                    _transfer20(ne[i].receiverAmounts[j], currency, ne[i].receiverCreators[j]);
                }
            } else {
                _transfer20(ne[i].refund, currency, buyer);
            }
        }
    }

}

// SPDX-License-Identifier: UNLICENSED
// Copyright (c) 2022 Gemini Trust Company LLC. All Rights Reserved
pragma solidity 0.8.x;

import "../core/ExecutorCore.sol";

/**
 * 721/1155, ETH/USD/ERC-20, & 0/1/N Receivers, w/o refund 
 */
abstract contract Switcher is ExecutorCore {

    /**
     * @dev Takes as input an array of generalized objects, consisting of 
     * sale events that include tokens of type ERC-721, and ERC-1155. The
     * payment may have been made in ETH, USD, or an ERC-20 token. The number
     * of royalty receivers can be either 0, 1 or N.  
     */
    function executeSaleBatch(NiftyEventBatch[] calldata ne) external payable {
        _requireOnlyValidSender();  
        for (uint256 i = 0; i < ne.length; i++) {
            address currency = ne[i].priceCurrency; 
            uint256 sellerProceeds = ne[i].sellerProceeds;
            address seller = ne[i].seller; 
            if(ne[i].count == 0) {
                _transfer721(ne[i].price, currency, ne[i].tokenId, ne[i].tokenContract, seller, ne[i].buyer);
            } else {
                _transfer1155(ne[i].count, ne[i].price, currency, ne[i].tokenId, ne[i].tokenContract, seller, ne[i].buyer);
            }
            _executeSwitcher(currency, sellerProceeds, seller, ne[i].receiverCreators, ne[i].receiverAmounts);
        }
    }

}

// SPDX-License-Identifier: UNLICENSED
// Copyright (c) 2022 Gemini Trust Company LLC. All Rights Reserved
pragma solidity 0.8.x;

import "../core/ExecutorCore.sol";

/**
 * 721/1155, ETH/USD/ERC-20, & 0/1/N Receivers, w/ refund 
 */
abstract contract SwitcherHandler is ExecutorCore {

    /**
     * @dev Takes as input an array of generalized objects, consisting of 
     * sale events that include tokens of type ERC-721, and ERC-1155. The
     * payment may have been made in ETH, USD, or an ERC-20 token. The number
     * of royalty receivers can be either 0, 1 or N.
     * 
     * @notice In the event the transfer is unsuccessful, the function will 
     * issue a refund to the buyer in the amount specified by the input 'refund'
     * parameter.  
     */
    function executeSaleBatchHandler(uint256[] calldata refund, NiftyEventBatch[] calldata ne) external payable {
        _requireOnlyValidSender();  
        for (uint256 i = 0; i < ne.length; i++) {
            address currency = ne[i].priceCurrency; 
            uint256 sellerProceeds = ne[i].sellerProceeds;
            address seller = ne[i].seller; 
            address buyer = ne[i].buyer; 
            if(ne[i].count == 0) {
                bool success = _transfer721handler(ne[i].price, currency, ne[i].tokenId, ne[i].tokenContract, seller, buyer);
                if(success){
                    _executeSwitcher(currency, sellerProceeds, seller, ne[i].receiverCreators, ne[i].receiverAmounts);
                } else {
                    _executeRefund(refund[i], currency, buyer);
                }
            } else {
                bool success = _transfer1155handler(ne[i].count, ne[i].price, currency, ne[i].tokenId, ne[i].tokenContract, seller, buyer);
                if(success){
                    _executeSwitcher(currency, sellerProceeds, seller, ne[i].receiverCreators, ne[i].receiverAmounts);
                } else {
                    _executeRefund(refund[i], currency, buyer);
                }
            }
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
// Copyright (c) 2022 Gemini Trust Company LLC. All Rights Reserved
pragma solidity 0.8.x;

import "../registry/Registry.sol";

interface IERC1155 {
    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value, bytes calldata _data) external;
}

interface IERC721 {
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;
}

struct NiftyEvent {
    uint256 sellerProceeds;
    uint256 price;
    uint256 tokenId; 
    address tokenContract; 
    address seller;
    address buyer;
}

struct NiftyEventHandler {
    uint256 refund; ///
    uint256 sellerProceeds;
    uint256 price;
    uint256 tokenId; 
    address tokenContract; 
    address seller;
    address buyer;
}

struct NiftyEventReceiver {
    uint256 sellerProceeds;
    uint256 price;
    uint256 tokenId;
    address tokenContract;
    address seller;
    address buyer;
    address priceCurrency;
    address[] receiverCreators;
    uint256[] receiverAmounts;
}

struct NiftyEventReceiverHandler {
    uint256 refund; ///
    uint256 sellerProceeds;
    uint256 price;
    uint256 tokenId;
    address tokenContract;
    address seller;
    address buyer;
    address priceCurrency;
    address[] receiverCreators;
    uint256[] receiverAmounts;
}

struct NiftyEventBatch {
    uint256 tokenId;
    uint256 count; /// @notice Value of '0' indicates ERC-721 token
    uint256 sellerProceeds; /// @notice Amount remitted to seller
    uint256 price;
    address priceCurrency; /// @notice Settlement currency (USD, ETH, ERC-20)
    address tokenContract;
    address seller;
    address buyer;
    address[] receiverCreators;
    uint256[] receiverAmounts;
}

/**
 *
 */
abstract contract ExecutorCore is Registry {

    address constant public _priceCurrencyETH = address(0);

    address immutable public _priceCurrencyUSD;

    event NiftySale721(address indexed tokenContract, uint256 tokenId, uint256 price, address priceCurrency);

    event NiftySale1155(address indexed tokenContract, uint256 tokenId, uint256 count, uint256 price, address priceCurrency);

    constructor(address priceCurrencyUSD_, address recoveryAdmin_, address[] memory validSenders_) Registry(recoveryAdmin_, validSenders_) {
        _priceCurrencyUSD = priceCurrencyUSD_;
    }

    /**
     *
     */
    function _transferEth(address recipient, uint256 value) internal {
        (bool success,) = payable(recipient).call{value: value}("");
        require(success, "NiftyExchangeExecutor: Value transfer unsuccessful");
    }

    function _transfer20(uint256 value, address token, address to) internal {
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))));
    }

    function _transfer721(uint256 price, address priceCurrency, uint256 tokenId, address tokenContract, address seller, address buyer) internal {
        IERC721(tokenContract).safeTransferFrom(seller, buyer, tokenId);
        emit NiftySale721(tokenContract, tokenId, price, priceCurrency);
    }

    function _transfer721handler(uint256 price, address priceCurrency, uint256 tokenId, address tokenContract, address seller, address buyer) internal returns (bool) {
        try IERC721(tokenContract).safeTransferFrom(seller, buyer, tokenId) {
            emit NiftySale721(tokenContract, tokenId, price, priceCurrency);
            return true;
        } catch {
            return false;
        }
    }

    function _transfer1155(uint256 count, uint256 price, address priceCurrency, uint256 tokenId, address tokenContract, address seller, address buyer) internal {
        IERC1155(tokenContract).safeTransferFrom(seller, buyer, tokenId, count, "");
        emit NiftySale1155(tokenContract, tokenId, count, price, priceCurrency); /// @notice 'price' describes entire purchase.
    }

    function _transfer1155handler(uint256 count, uint256 price, address priceCurrency, uint256 tokenId, address tokenContract, address seller, address buyer) internal returns (bool) {
        try IERC1155(tokenContract).safeTransferFrom(seller, buyer, tokenId, count, "") {
            emit NiftySale1155(tokenContract, tokenId, count, price, priceCurrency);
            return true;
        } catch {
            return false;
        }
    }

    function _recordSale721(address tokenContract, uint256 tokenId, uint256 price, address priceCurrency) internal {
        emit NiftySale721(tokenContract, tokenId, price, priceCurrency);
    }

    function _recordSale1155(address tokenContract, uint256 tokenId, uint256 count, uint256 price, address priceCurrency) internal {
        emit NiftySale1155(tokenContract, tokenId, count, price, priceCurrency);
    }

    function _executeSwitcher(
        address currency, 
        uint256 sellerProceeds, 
        address seller, 
        address[] calldata receiverCreators, 
        uint256[] calldata receiverAmounts) internal {
        bool eth = currency == _priceCurrencyETH;
        if(sellerProceeds > 0){
            if(eth){
                _transferEth(seller, sellerProceeds);
            } else {
                _transfer20(sellerProceeds, currency, seller);
            }
        }
        uint256 receiverCount = receiverCreators.length;
        if(receiverCount > 0){
            for(uint256 i = 0; i < receiverCount; i++){
                if(eth){
                    _transferEth(receiverCreators[i], receiverAmounts[i]);
                } else {
                    _transfer20(receiverAmounts[i], currency, receiverCreators[i]);
                }
            }
        }
    }

    function _executeRefund(uint256 refund, address currency, address buyer) internal {
        if(refund > 0){
            if(currency == _priceCurrencyETH) {
                _transferEth(buyer, refund);
            } else {
                _transfer20(refund, currency, buyer);
            }
        }
    }

}

// SPDX-License-Identifier: UNLICENSED
// Copyright (c) 2022 Gemini Trust Company LLC. All Rights Reserved
pragma solidity 0.8.x;

import "./LockRequestable.sol";

struct AdminUpdateRequest {
    address proposed;
}

contract Registry is LockRequestable {

    address public custodian;

    mapping(bytes32 => AdminUpdateRequest) public custodianChangeReqs;

    event CustodianChangeRequested(
        bytes32 _lockId,
        address _msgSender,
        address _proposedCustodian,
        uint256 _lockRequestIdx
    );
    event CustodianChangeConfirmed(bytes32 _lockId, address _newCustodian);

    mapping(address => address) public _validSenderSet;
    uint256 public setSize;
    address constant GUARD = address(1);

    mapping(bytes32 => AdminUpdateRequest) public ownerAddReqs;

    event ValidSenderAddRequested(
        bytes32 _lockId,
        address _msgSender,
        address _proposed,
        uint256 _lockRequestIdx
    );
    event ValidSenderAddConfirmed(bytes32 _lockId, address _newValidSender);
    
    string internal constant ERROR_INVALID_MSG_SENDER = "Invalid msg.sender";

    constructor(address custodian_, address[] memory validSenders_) LockRequestable() {
        custodian = custodian_;
        _validSenderSet[GUARD] = GUARD;
        for(uint256 i = 0; i < validSenders_.length; i++) {
            address sender = validSenders_[i];
            _addValidSender(sender);
        }
    }

    modifier onlyCustodian {
        require(msg.sender == custodian, ERROR_INVALID_MSG_SENDER);
        _;
    }

    function _requireOnlyValidSender() internal view {       
        require(isValidSender(msg.sender), ERROR_INVALID_MSG_SENDER);
    }

    function confirmCustodianChange(bytes32 lockId) external onlyCustodian {
        custodian = _getRequest(custodianChangeReqs, lockId);
        delete custodianChangeReqs[lockId];
        emit CustodianChangeConfirmed(lockId, custodian);
    }

    function confirmValidSenderAdd(bytes32 lockId) external onlyCustodian {
        address proposed = _getRequest(ownerAddReqs, lockId);
        _addValidSender(proposed);
        delete ownerAddReqs[lockId];
        emit ValidSenderAddConfirmed(lockId, proposed);
    }

    function _getRequest(mapping(bytes32 => AdminUpdateRequest) storage _m, bytes32 _lockId) private view returns (address proposed) {
        AdminUpdateRequest storage adminRequest = _m[_lockId];
        // reject ‘null’ results from the map lookup
        // this can only be the case if an unknown `_lockId` is received
        require(adminRequest.proposed != address(0), "no such lockId");
        return adminRequest.proposed;
    }

    function _requestChange(mapping(bytes32 => AdminUpdateRequest) storage _m, bytes4 _selector, address _proposed) private returns (bytes32 lockId, uint256 lockRequestIdx) {
        require(_proposed != address(0), "zero address");

        (bytes32 preLockId, uint256 idx) = generatePreLockId();
        lockId = keccak256(
            abi.encodePacked(
                preLockId,
                _selector,
                _proposed
            )
        );
        lockRequestIdx = idx;

        _m[lockId] = AdminUpdateRequest({
            proposed : _proposed
        });
    }

    function requestCustodianChange(address _proposedCustodian) external returns (bytes32 lockId) {
        (bytes32 preLockId, uint256 lockRequestIdx) = _requestChange(custodianChangeReqs, this.requestCustodianChange.selector, _proposedCustodian);
        emit CustodianChangeRequested(preLockId, msg.sender, _proposedCustodian, lockRequestIdx);
        return preLockId;
    }

    function requestValidSenderAdd(address _sender) external returns (bytes32 lockId) {
        (bytes32 preLockId, uint256 lockRequestIdx) = _requestChange(ownerAddReqs, this.requestValidSenderAdd.selector, _sender);
        emit ValidSenderAddRequested(preLockId, msg.sender, _sender, lockRequestIdx);
        return preLockId;
    }

    function _getPrevSender(address student) private view returns(address) {
        address currentAddress = GUARD;
        while(_validSenderSet[currentAddress] != GUARD) {
            if (_validSenderSet[currentAddress] == student) {
                return currentAddress;
            }
            currentAddress = _validSenderSet[currentAddress];
        }
        return address(0);
    }

    function removeValidSender(address sender) external {
        _requireOnlyValidSender();
        _removeValidSender(sender);
    }

    function removeAllValidSenders() external {
        _requireOnlyValidSender();
        address currentAddress = GUARD;
        while(_validSenderSet[currentAddress] != GUARD) {
            address sender = _validSenderSet[currentAddress];
            _removeValidSender(sender);
        }
    }

    function isValidSender(address sender) public view returns (bool) {
        return _validSenderSet[sender] != address(0);
    }

    function _addValidSender(address sender) private {
        require(!isValidSender(sender));
        _validSenderSet[sender] = _validSenderSet[GUARD];
        _validSenderSet[GUARD] = sender;
        setSize++;
    }

    function _removeValidSender(address sender) private {
        address prevSender = _getPrevSender(sender);
        _validSenderSet[prevSender] = _validSenderSet[sender];
        _validSenderSet[sender] = address(0);
        setSize--;
    }

    function getValidSenderSet() public view returns (address[] memory) {
        address[] memory validSenderList = new address[](setSize);
        address currentAddress = _validSenderSet[GUARD];
        for(uint256 i = 0; currentAddress != GUARD; ++i) {
            validSenderList[i] = currentAddress;
            currentAddress = _validSenderSet[currentAddress];
        }
        return validSenderList; 
    }

}

// SPDX-License-Identifier: UNLICENSED
// Copyright (c) 2022 Gemini Trust Company LLC. All Rights Reserved
pragma solidity 0.8.x;


/** @title  A contract for generating unique identifiers
  *
  * @notice  A contract that provides a identifier generation scheme,
  * guaranteeing uniqueness across all contracts that inherit from it,
  * as well as unpredictability of future identifiers.
  *
  * @dev  This contract is intended to be inherited by any contract that
  * implements the callback software pattern for cooperative custodianship.
  *
  * @author  Gemini Trust Company, LLC
  */
abstract contract LockRequestable {

    // MEMBERS
    /// @notice  the count of all invocations of `generateLockId`.
    uint256 public lockRequestCount;

    constructor() {
        lockRequestCount = 0;
    }

    // FUNCTIONS
    /** @notice  Returns a fresh unique identifier.
      *
      * @dev the generation scheme uses three components.
      * First, the blockhash of the previous block.
      * Second, the deployed address.
      * Third, the next value of the counter.
      * This ensure that identifiers are unique across all contracts
      * following this scheme, and that future identifiers are
      * unpredictable.
      *
      * @return  preLockId  a 32-byte unique identifier.
      * @return  lockRequestIdx  index of lock request
      */
    function generatePreLockId() internal returns (bytes32 preLockId, uint256 lockRequestIdx) {
        lockRequestIdx = ++lockRequestCount;
        preLockId = keccak256(
            abi.encodePacked(
                blockhash(block.number - 1),
                address(this),
                lockRequestIdx
            )
        );
    }
}