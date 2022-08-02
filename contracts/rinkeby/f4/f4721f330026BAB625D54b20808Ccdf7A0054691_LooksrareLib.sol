// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


interface ILooksrare {

    struct MakerOrder {
        bool isOrderAsk; // true --> ask / false --> bid
        address signer; // signer of the maker order
        address collection; // collection address
        uint256 price; // price (used as )
        uint256 tokenId; // id of the token
        uint256 amount; // amount of tokens to sell/purchase (must be 1 for ERC721, 1+ for ERC1155)
        address strategy; // strategy for trade execution (e.g., DutchAuction, StandardSaleForFixedPrice)
        address currency; // currency (e.g., WETH)
        uint256 nonce; // order nonce (must be unique unless new maker order is meant to override existing one e.g., lower ask price)
        uint256 startTime; // startTime in timestamp
        uint256 endTime; // endTime in timestamp
        uint256 minPercentageToAsk; // slippage protection (9000 --> 90% of the final price must return to ask)
        bytes params; // additional parameters
        uint8 v; // v: parameter (27 or 28)
        bytes32 r; // r: parameter
        bytes32 s; // s: parameter
    }

    struct TakerOrder {
        bool isOrderAsk; // true --> ask / false --> bid
        address taker; // msg.sender
        uint256 price; // final price for the purchase
        uint256 tokenId;
        uint256 minPercentageToAsk; // // slippage protection (9000 --> 90% of the final price must return to ask)
        bytes params; // other params (e.g., tokenId)
    }

    // ETH and WETH payment; if msg.value is not enough, use WETH
    function matchAskWithTakerBidUsingETHAndWETH(
        TakerOrder memory takerBid,
        MakerOrder memory makerAsk
    ) external payable;

    // only ERC20 token as payment
    function matchAskWithTakerBid(
        TakerOrder memory takerBid, 
        MakerOrder memory makerAsk
    ) external;

    // NFT seller trigger this function to send his NFT and receive ERC20 tokens
    function matchBidWithTakerAsk(
        TakerOrder memory takerAsk, 
        MakerOrder memory makerBid
    ) external;

}

library LooksrareLib {

    // address public constant Looksrare = 0x59728544B08AB483533076417FbBB2fD0B17CE3a;   // ETH mainnet
    // WETH rinkeby: 0xc778417E063141139Fce010982780140Aa0cD5Ab
    address public constant Looksrare = 0x1AA777972073Ff66DCFDeD85749bDD555C0665dA;   // Rinkeby mainnet

    struct LooksrareBuy {
        ILooksrare.TakerOrder takerBid;
        ILooksrare.MakerOrder makerAsk;
        uint256 ETHAmount;  // if using ETH, ETHAmount > 0
    }

    function buyAssets(LooksrareBuy[] memory looksrareBuys, bool revertIfTrxFails) public {
        for (uint256 i = 0; i < looksrareBuys.length; ++i) {
            _buyAsset(looksrareBuys[i], revertIfTrxFails);
        }
    }

    function _buyAsset(LooksrareBuy memory looksrareBuy, bool revertIfTrxFails) internal {
        bool success;
        if (looksrareBuy.ETHAmount > 0) {
            bytes memory _data = abi.encodeWithSelector(
                ILooksrare.matchAskWithTakerBidUsingETHAndWETH.selector, 
                looksrareBuy.takerBid, 
                looksrareBuy.makerAsk);

            (success, ) = Looksrare.call{value: looksrareBuy.ETHAmount}(_data);
        } else {
            bytes memory _data = abi.encodeWithSelector(
                ILooksrare.matchAskWithTakerBid.selector, 
                looksrareBuy.takerBid, 
                looksrareBuy.makerAsk);

            (success, ) = Looksrare.call(_data);
        }

        if (!success && revertIfTrxFails) {
            // Copy revert reason from call
            assembly {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }
    }

    // amounts are the ETH payment amounts sent to Looksrare contract
    function buyAssetsByData(bytes[] memory dataset, uint256[] memory amounts, bool revertIfTrxFails) public {
        require(dataset.length == amounts.length, "LooksrareLib: array length not match");
        for (uint256 i = 0; i < dataset.length; ++i) {
            _buyAssetByData(dataset[i], amounts[i], revertIfTrxFails);
        }
    }

    function _buyAssetByData(bytes memory data, uint256 amount, bool revertIfTrxFails) internal {

        (bool success, ) = Looksrare.call{value: amount}(data);

        if (!success && revertIfTrxFails) {
            // Copy revert reason from call
            assembly {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }
    }
}