// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
__        ___    ____ __  __ ___ __  __ _   _ ____ ___ ____ 
\ \      / / \  / ___|  \/  |_ _|  \/  | | | / ___|_ _/ ___|
 \ \ /\ / / _ \| |  _| |\/| || || |\/| | | | \___ \| | |    
  \ V  V / ___ \ |_| | |  | || || |  | | |_| |___) | | |___ 
   \_/\_/_/   \_\____|_|  |_|___|_|  |_|\___/|____/___\____|
*/

library MusicLib {
    // 為替データの有効小数桁数
    uint8 constant DECIMALS = 10;

    struct Music {
      address[] stakeHolders;// 収益の受領者(筆頭受領者=二次流通ロイヤリティの受領者)
      address payable aggregator;// アグリゲーター
      uint256[2] prices;// [preSale価格，publicSale価格]
      uint256 recoupLine; // リクープライン(円)
      uint32[] share;// 収益の分配率
      uint32[2] purchaseLimits; // [preSale購入制限，publicSale購入制限]
      uint32 numSold;// 現在のトークン発行量
      uint32 quantity;// トークン発行上限
      uint32 presaleQuantity;// プレセール配分量
      uint32 royalty;// 二次流通時の印税(using 2 desimals)
      uint32 album;// 収録アルバムid
      bytes32 merkleRoot;// マークルルート
    }

    struct Album {
      address[] _stakeHolders;
      address payable _aggregator;
      uint256[] _presalePrices;
      uint256[] _prices;
      uint256[] _recoupLines;
      uint32[] _presaleQuantities;
      uint32[] _quantities;
      uint32[] _share;
      uint32[] _presalePurchaseLimits;
      uint32[] _purchaseLimits;
      uint32 _royalty;
      bytes32 _merkleRoot;
    }

    function validateAlbum(
      MusicLib.Album calldata album
    ) public pure {
      validateShare(album._stakeHolders, album._share);
      uint256 l = album._quantities.length;
      require(album._presaleQuantities.length == l, "presaleQuantities length isn't enough");
      require(album._presalePrices.length == l, "presalePrices length isn't enough");
      require(album._recoupLines.length == l, "recoupLines length isn't enough");
      require(album._prices.length == l, "prices length isn't enough");
      require(album._presalePurchaseLimits.length == l, "presalePurchaseLimits length isn't enough");
      require(album._purchaseLimits.length == l, "purchaseLimit length isn't enough");
    }

    function validateShare(
      address[] calldata _stakeHolders,
      uint32[] calldata _share
    ) public pure {
      require(_stakeHolders.length==_share.length, "stakeHolders' and share's length don't match");
      uint32 s;
      for(uint256 i=0; i<_share.length; ++i){
        s += _share[i];
      }
      require(s == 100, 'total share must match to 100');
    }

    /**
      @dev 有効小数点以下桁数の調整
      @param _price 価格データ
      @param _priceDecimals 価格データの小数点以下桁数
      @return 調整後価格データ
    */
    function scalePrice(
      int256 _price, 
      uint8 _priceDecimals
    ) public pure returns (int256){
      if (_priceDecimals < DECIMALS) {
        return _price * int256(10 ** uint256(DECIMALS - _priceDecimals));
      } else if (_priceDecimals > DECIMALS) {
        return _price / int256(10 ** uint256(_priceDecimals - DECIMALS));
      }
      return _price;
    }
}