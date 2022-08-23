//SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

import "../proxy/LooksRareMarket.sol";

contract LooksRareEncoder {
    function getTradeData(LooksRareMarket.TradeData[] memory _tradeDatas) public pure returns(bytes memory) {
        return  abi.encodeWithSelector(LooksRareMarket.buyAssetsForEth.selector, _tradeDatas, true);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

interface IERC721 {
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external payable;
}

interface IERC1155 {
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;
}

library LooksRareMarket {
    // 正式
    //    address public constant LOOKSRARE = 0x59728544b08ab483533076417fbbb2fd0b17ce3a;
    // local
    address public constant LOOKSRARE = 0x1AA777972073Ff66DCFDeD85749bDD555C0665dA;
    uint256 public constant CATEGORY_721 = 1;
    uint256 public constant CATEGORY_1155 = 2;

    struct TradeData {
        uint256 value;
        bytes tradeData;
        address buyer;
        address collection;
        uint256 tokenId;
        uint256 category;
        uint256 amount;
    }

    function buyAssetsForEth(
        TradeData[] memory _looksBuys,
        bool revertIfTrxFails
    ) public {
        for (uint256 i = 0; i < _looksBuys.length; i++) {
            _buyAssetForEth(_looksBuys[i], revertIfTrxFails);
        }
    }

    function _buyAssetForEth(TradeData memory _looksBuy, bool _revertIfTrxFails)
        internal
    {
        (bool success, ) = LOOKSRARE.call{value: _looksBuy.value}(
            _looksBuy.tradeData
        );
        require(
            _looksBuy.category == CATEGORY_721 ||
                _looksBuy.category == CATEGORY_1155,
            "invalid category"
        );
        if (_looksBuy.category == CATEGORY_721) {
            IERC721(_looksBuy.collection).transferFrom(
                address(this),
                _looksBuy.buyer,
                _looksBuy.tokenId
            );
        }
        if (_looksBuy.category == CATEGORY_1155) {
            IERC1155(_looksBuy.collection).safeTransferFrom(
                address(this),
                _looksBuy.buyer,
                _looksBuy.tokenId,
                _looksBuy.amount,
                ""
            );
        }

        if (!success && _revertIfTrxFails) {
            // Copy revert reason from call
            assembly {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }
    }
}