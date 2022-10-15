// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
__        ___    ____ __  __ ___ __  __ _   _ ____ ___ ____ 
\ \      / / \  / ___|  \/  |_ _|  \/  | | | / ___|_ _/ ___|
 \ \ /\ / / _ \| |  _| |\/| || || |\/| | | | \___ \| | |    
  \ V  V / ___ \ |_| | |  | || || |  | | |_| |___) | | |___ 
   \_/\_/_/   \_\____|_|  |_|___|_|  |_|\___/|____/___\____|
*/

import {WAGMIApp} from "../wagmi/WagmiApp.sol";
import {IRecord1155} from "./IRecord1155.sol";
import {MusicLib} from "../lib/MusicLib.sol";
import {IERC2981Upgradeable, IERC165Upgradeable}
from '@openzeppelin/contracts-upgradeable/interfaces/IERC2981Upgradeable.sol';
import {ERC1155Upgradeable} from '@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol';
import {StringsUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import {CountersUpgradeable} from '@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol';
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/**
 * @title Record1155v2
 * @author WAGMIMusic
 */
contract Record1155v2 is IRecord1155, WAGMIApp, ERC1155Upgradeable, IERC2981Upgradeable {
  using StringsUpgradeable for uint256;
  using CountersUpgradeable for CountersUpgradeable.Counter;

  // 販売状態(列挙型)
  enum SaleState {Prepared, Presale, PublicSale, Suspended} 

  // ベースURI(tokenURI=baseURI+editionId+/+tokenId)
  string internal baseURI;
  // トークンの名称
  string private _name;
  // トークンの単位
  string private _symbol;

  // 楽曲id => 販売状態
  mapping(uint256 => SaleState) public sales;
  // アルバムid => アルバムサイズ
  mapping(uint256 => uint32) private _albumSize;
  // 楽曲id, アドレス => mint数
  mapping(uint256=>mapping(address => uint32)) private _tokenClaimed;

  event NowOnSale(
    uint256 indexed tokenId,
    SaleState indexed sales
  );

  /**
    @dev コンストラクタ(Proxyを利用したコントラクトはinitializeでconstructorを代用)
    @param _artist コントラクトのオーナーアドレス
    @param name_ コントラクトの名称
    @param symbol_ トークンの単位
    @param _baseURI ベースURI
   */
  function initialize(
        address _artist,
        string memory name_,
        string memory symbol_,
        string memory _baseURI
  ) public override initializer {
      __ERC1155_init(_baseURI);
      __Ownable_init();

      // コントラクトのデプロイアドレスに関わらずownerをartistに設定する
      transferOwnership(_artist);

      // /**
      // * Network: Ethereum
      // * Aggregator: JPY/USD
      // */
      // _numeratorAddr = 0xBcE206caE7f0ec07b545EddE332A47C2F75bbeb3;
      // /**
      // * Network: Ethereum
      // * Aggregator: ETH/USD
      // */
      // _denominatorAddr = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;
      /**
      * Network: Polygon
      * Aggregator: JPY/USD
      */
      _numeratorAddr = 0xD647a6fC9BC6402301583C91decC5989d8Bc382D;
      /**
      * Network: Polygon
      * Aggregator: ETH/USD
      */
      _denominatorAddr = 0xF9680D99D6C9589e2a93a78A04A279e509205945;

      baseURI = _baseURI;
      _name = name_;
      _symbol = symbol_;

      // deployerをエージェントに設定
      _agent[_msgSender()] = true;

      // 楽曲idとアルバムidの初期値は1
      newTokenId.increment();
      newAlbumId.increment();// albumId=0 => universal album
  }

  // ============ Main Function ============
  /**
    @dev 楽曲データの作成(既存のアルバムに追加)
    @param music MusicData(Struct)
   */
  function createMusic(
    MusicLib.Music calldata music
  ) public virtual override onlyOwnerOrAgent {
    // データの有効性を確認
    MusicLib.validateShare(music.stakeHolders, music.share);
    // _albumIdの有効性を確認
    require(_existsAlbum(music.album), 'not exist');
    musics[newTokenId.current()] =
    MusicLib.Music({
      stakeHolders: music.stakeHolders,
      aggregator: music.aggregator,
      prices: music.prices,
      recoupLine: music.recoupLine,
      share: music.share,
      purchaseLimits: music.purchaseLimits,
      numSold: 0,
      quantity: music.quantity,
      presaleQuantity: music.presaleQuantity,
      royalty: music.royalty,
      album: uint32(music.album),
      merkleRoot: music.merkleRoot
    });

    emit MusicCreated(
      newTokenId.current(),
      music.stakeHolders,
      music.aggregator,
      music.prices,
      music.share,
      music.quantity,
      music.presaleQuantity,
      music.royalty,
      uint32(music.album),
      music.merkleRoot
    );

    // sales: default => prepared
    sales[newTokenId.current()] = SaleState.Prepared;
    // increment TokenId and AlbumId
    newTokenId.increment();
    ++_albumSize[music.album];
  }

  /**
    @dev アルバムデータの作成
    @param album AlbumData(Struct)
   */
  function createAlbum(
    MusicLib.Album calldata album
  ) external virtual override onlyOwnerOrAgent {
    // データの有効性を確認
    MusicLib.validateAlbum(album);
    for(uint256 i=0; i<album._quantities.length; ++i){
      musics[newTokenId.current()] =
      MusicLib.Music({
        stakeHolders: album._stakeHolders,
        aggregator: album._aggregator,
        prices: [album._presalePrices[i], album._prices[i]],
        recoupLine: album._recoupLines[i],
        share: album._share,
        numSold: 0,
        quantity: album._quantities[i],
        presaleQuantity: album._presaleQuantities[i],
        royalty: album._royalty,
        album: uint32(newAlbumId.current()),
        purchaseLimits: [album._presalePurchaseLimits[i],album._purchaseLimits[i]],
        merkleRoot: album._merkleRoot
      });

      emit MusicCreated(
        newTokenId.current(),
        album._stakeHolders,
        album._aggregator,
        [album._presalePrices[i], album._prices[i]],
        album._share,
        album._quantities[i],
        album._presaleQuantities[i],
        album._royalty,
        uint32(newAlbumId.current()),
        album._merkleRoot
      );
      // sales: default => suspended
      sales[newTokenId.current()] = SaleState.Prepared;
      // increment TokenId and AlbumId
      newTokenId.increment();
      ++_albumSize[newAlbumId.current()];
    }
    newAlbumId.increment();
  }

  function omniMint(
    uint256 _tokenId,
    uint32 _amount
  ) external virtual override payable {
    bytes32[] memory empty;
    omniMint(_tokenId, _amount, "", empty);
  }

  /**
    @dev NFTの購入
    @param _tokenId 購入する楽曲のid
    @param _merkleProof マークルプルーフ
   */
  function omniMint(
    uint256 _tokenId,
    uint32 _amount,
    bytes memory _data,
    bytes32[] memory _merkleProof
  ) public virtual override payable {
    // _tokenIdの有効性を確認
    require(_exists(_tokenId), 'not exist');
    // 在庫の確認
    require(musics[_tokenId].numSold + _amount <= musics[_tokenId].quantity, 'exceed stock');

    // 販売状態による分岐
    if (sales[_tokenId] == SaleState.Presale) {
      // 購入制限数の確認
      require(_tokenClaimed[_tokenId][_msgSender()] + _amount <=  musics[_tokenId].purchaseLimits[0], "exceeds limit");
      _validateWhitelist(_tokenId, _merkleProof);
      // プレセール時の支払価格の確認
      require(msg.value >= musics[_tokenId].prices[0] * _amount,'not enough');
    }else if(sales[_tokenId] == SaleState.PublicSale){
      // 購入制限数の確認
      require(_tokenClaimed[_tokenId][_msgSender()] + _amount <=  musics[_tokenId].purchaseLimits[1], "exceeds limit");
      // パブリックセール時の支払価格の確認
      require(msg.value >= musics[_tokenId].prices[1] * _amount,'not enough');
    }else{
      // SaleState: prepared or suspended
      revert("not on sale");
    }
    // Reentrancy guard
    // 発行量+_amount
    musics[_tokenId].numSold += _amount;
    // 購入履歴+_amount
    _tokenClaimed[_tokenId][_msgSender()] += _amount;
    // デポジットを更新
    profit[_tokenId] += msg.value;
    _mint(_msgSender(), _tokenId, _amount, _data);

    uint32 _albumId = musics[_tokenId].album;
    emit MusicPurchased(
      _tokenId, 
      _albumId,
      musics[_tokenId].numSold, 
      _msgSender()
    );
  }

  /**
    @dev 販売状態の移行(列挙型で管理)
    @param _tokenIds 楽曲のid列
    @param _sale 販売状態(0=>prepared, 1=>presale, 2=>public sale, 3=>suspended)
   */
  function handleSaleState (
    uint256[] calldata _tokenIds,
    uint8 _sale
  ) external virtual override onlyOwnerOrAgent {
    for(uint256 i=0; i<_tokenIds.length; ++i){
      sales[_tokenIds[i]] = SaleState(_sale);
      emit NowOnSale(_tokenIds[i], sales[_tokenIds[i]]);
    }
  }

  /**
    @dev マークルルートの設定
    @param _tokenIds 楽曲id
    @param _merkleRoot マークルルート
   */
  function setMerkleRoot(
    uint256[] calldata _tokenIds,
    bytes32 _merkleRoot
  ) public virtual override onlyOwnerOrAgent {
    for(uint256 i=0; i<_tokenIds.length; ++i){
      musics[_tokenIds[i]].merkleRoot = _merkleRoot;
    }
  }

  // ============ utility ============

  /**
    @dev newTokenId is totalSupply+1
    @return totalSupply 各トークンの発行量
   */
  function totalSupply(uint256 _tokenId) external virtual override view returns (uint256) {
    require(_exists(_tokenId), 'not exist');
    return musics[_tokenId].numSold;
  }

  /**
    @dev 特定のアルバムのtokenId列を取得
    @param _albumId アルバムid
    @return _tokenIdsOfMusic tokenId
   */
  function getTokenIdsOfAlbum(
      uint256 _albumId
  ) public virtual override view returns (uint256[] memory){
      // _albumIdの有効性を確認
      require(_existsAlbum(_albumId), 'not exist');
      uint256[] memory _tokenIdsOfAlbum = new uint256[](_albumSize[_albumId]);
      uint256 index = 0;
      for (uint256 id = 1; id < newTokenId.current(); ++id){
        if (musics[id].album == _albumId) {
          _tokenIdsOfAlbum[index] = id;
          ++index;
        }
      }
      return _tokenIdsOfAlbum;
  }

  // ============ Operational Function ============

  /**
    @dev NFTのMintオペレーション
    @notice WIP-1: this function should be able to invalidated for the future
   */
  function operationalMint (
    address _recipient,
    uint256 _tokenId,
    uint32 _amount,
    bytes memory _data
  )external virtual override onlyOwnerOrAgent {
    bytes32 digest = keccak256(abi.encode('oparationalMint(uint256 _tokenId,uint32 _amount)', _tokenId, _amount));
    _validateOparation(digest);
    // _tokenIdの有効性を確認
    require(_exists(_tokenId), 'not exist');
    _mint(_recipient, _tokenId, _amount, _data);
  }

  // ============ Token Standard ============

  /**
    @dev コントラクトの名称表示インターフェース
   */
  function name() public view virtual override returns(string memory){
      return(_name);
  }

  /**
    @dev トークンの単位表示インターフェース
   */
  function symbol() public view virtual override returns(string memory){
      return(_symbol);
  }

  /**
    @dev Returns e.g. https://.../{tokenId}
    @param _tokenId トークンID
    @return _tokenURI
   */
  function uri(uint256 _tokenId) public virtual view override returns (string memory) {
    require(_exists(_tokenId), 'not exist');
    return string(abi.encodePacked(baseURI,_tokenId.toString()));
  }

  /**
    @dev ベースURIの設定
   */
  function setBaseURI(
    string memory _uri
  ) external virtual override onlyOwnerOrAgent {
    baseURI = _uri;
  }

  /**
    @dev トークンのロイヤリティを取得(https://eips.ethereum.org/EIPS/eip-2981)
    @param _tokenId トークンid
    @param _salePrice トークンの二次流通価格
    @return _recipient ロイヤリティの受領者
    @return _royaltyAmount ロイヤリティの価格
   */
  function royaltyInfo(
    uint256 _tokenId,
    uint256 _salePrice
  ) external virtual view override 
  returns(
    address _recipient, uint256 _royaltyAmount
  ){
    MusicLib.Music memory music = musics[_tokenId];
    // 100_00 = 100%
    _royaltyAmount = (_salePrice * music.royalty) / 100_00;
    return(music.stakeHolders[0], _royaltyAmount);
  }

  function supportsInterface(
    bytes4 _interfaceId
  )public virtual view override(ERC1155Upgradeable, IERC165Upgradeable)returns (bool)
  {
    return
      type(IERC2981Upgradeable).interfaceId == _interfaceId || ERC1155Upgradeable.supportsInterface(_interfaceId);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
__        ___    ____ __  __ ___ __  __ _   _ ____ ___ ____ 
\ \      / / \  / ___|  \/  |_ _|  \/  | | | / ___|_ _/ ___|
 \ \ /\ / / _ \| |  _| |\/| || || |\/| | | | \___ \| | |    
  \ V  V / ___ \ |_| | |  | || || |  | | |_| |___) | | |___ 
   \_/\_/_/   \_\____|_|  |_|___|_|  |_|\___/|____/___\____|
*/
import {IWAGMIApp} from "../interfaces/IWagmiApp.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {MusicLib} from "../lib/MusicLib.sol";
import {OwnableUpgradeable} from '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import {CountersUpgradeable} from '@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol';
import {IDistributor} from "../interfaces/IDistributor.sol";
import {MerkleProofUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";

/**
 * @title WAGMIapp
 * @author WAGMIMusic
 */
contract WAGMIApp is OwnableUpgradeable, IWAGMIApp {
  using CountersUpgradeable for CountersUpgradeable.Counter;

  // 価格換算先のChainlinkアドレス(Default:円)
  address public _numeratorAddr;
  // 価格換算元のChainlinkアドレス(Default:Ether)
  address public _denominatorAddr;
  // 実行権限のある執行者
  mapping(address => bool) internal _agent;
  // 分配コントラクトアドレス
  address public distributor;
  // 楽曲のID
  CountersUpgradeable.Counter internal newTokenId;
  // アルバムのID
  CountersUpgradeable.Counter internal newAlbumId;
  // 楽曲id => 楽曲データ
  mapping(uint256 => MusicLib.Music) public musics;
  // 楽曲id => 収益
  mapping(uint256 => uint256) public profit;
  mapping(address => uint256) private _withdrawnForEach;
  // 楽曲id => リクープ履歴
  mapping(uint256 => uint256) private _recoupedValue;

  /**
    @dev 実行権限の確認
   */
  modifier onlyOwnerOrAgent {
    require(msg.sender == owner() || _agent[msg.sender], "not allowed but owner or agent");
    _;
  }

  modifier onlyOwnerOrDistributor {
    require(msg.sender == owner() || msg.sender == distributor, "not allowed but owner or distributor");
    _;
  }

  // ============ Revenue Pool ============

  /**
    @dev 収益の引き出し
    @param _recipient 受領者
    @param _value 請求額
    @dev param: value 引き出し可能な資産総額
    @dev param: _dist Editionごとの引き出し可能な資産額
   */
  function withdraw(
    address payable _recipient,
    uint256 _value
  ) external virtual override {
    uint256 distribution = 0;
    uint256 locked = 0;
    for(uint256 id=1; id < newTokenId.current(); ++id){
      (bool _approval, uint256 dist) = _getDistribution(id, _msgSender());
      if(!_approval){
        locked += dist;
      }
      distribution += dist;
    }
    uint256 value = distribution - locked - _withdrawnForEach[_msgSender()];
    // by any chance
    if(address(this).balance < value){value = address(this).balance;}
    require(value >= _value, 'exceed withdrawable value');
    _withdrawnForEach[_msgSender()] += _value;
    _sendFunds(_recipient, _value);
    emit Withdraw(msg.sender, _recipient, value, distribution, locked);
  }

  /**
    @dev 引き出し可能な資産額の確認
    @param _claimant 請求アドレス
    @return distribution 配分された資産総額
    @return locked 未承認の配分額
    @return value 引き出し可能な資産総額
   */
  function withdrawable(
    address _claimant
  ) public virtual override view returns(
    uint256 distribution,
    uint256 locked,
    uint256 value
  ){
    distribution = 0;
    locked = 0;
    for(uint256 id=1; id < newTokenId.current(); ++id){
      (bool _approval, uint256 dist) = _getDistribution(id, _claimant);
      if(!_approval){
        locked += dist;
      }
      distribution += dist;
    }
    value = distribution - locked - _withdrawnForEach[_claimant];
    return(distribution, locked, value);
  }

  /**
    @dev 分配資産額の確認
   */
  function _getDistribution(
    uint256 _tokenId,
    address _claimant
  ) internal virtual view returns(bool _approval, uint256 _distribution){
    uint32 _share = 0;
    for(uint32 i=0; i < musics[_tokenId].stakeHolders.length; ++i){
      if(musics[_tokenId].stakeHolders[i]==_claimant){
        _share = musics[_tokenId].share[i];
        break;
      }
    }
    if(distributor == address(0x0)){
      // Defaultの分配契約
      _distribution = uint256(_share) * (profit[_tokenId] - calculateRecoupLine(_tokenId)) / 100;
      _approval = (_recoupedValue[_tokenId] != 0 || musics[_tokenId].aggregator == address(0x0));
      return(_approval, _distribution);
    }
    // 分配コントラクトの通信プロトコル
    (_approval, _distribution) = IDistributor(distributor).getDistribution(_claimant, _tokenId, profit[_tokenId], _share);
    return(_approval, _distribution);
  }

  /**
    @dev 諸費用のリクープ
    @param _tokenId 楽曲id
   */
  function recoup(uint256 _tokenId) external virtual override {
    require(musics[_tokenId].aggregator == msg.sender, "caller should be aggregator");
    require(_recoupedValue[_tokenId] == 0, "cost have been recouped");
    uint256 value = calculateRecoupLine(_tokenId);
    if(profit[_tokenId] < value){
      value = profit[_tokenId];
    }
    _recoupedValue[_tokenId] = value;
    _sendFunds(musics[_tokenId].aggregator, value);
    emit Recoup(_tokenId, musics[_tokenId].aggregator, value);
  }

  /**
    @dev リクープラインの換算(円 => Wei)
    @param _tokenId 楽曲id
    @return value リクープライン(Wei)
   */
  function calculateRecoupLine(uint256 _tokenId) public virtual override view returns(uint256 value){
    // リクープ後
    if(_recoupedValue[_tokenId] != 0){
      return _recoupedValue[_tokenId];
    }
    // default
    if(distributor == address(0x0)){
      uint256 converter = _getEtherPerJPY();
      value = musics[_tokenId].recoupLine * converter;
      if(profit[_tokenId] < value){
        value = profit[_tokenId];
      }
      return value;
    }
    // custom: 分配コントラクトの通信プロトコル
    value = IDistributor(distributor).getRecoupLine(_tokenId);
    return value;
  }

  /**
    @dev 送金機能(fallback関数を呼び出すcallを使用)
   */
  function _sendFunds(
    address payable _recipient,
    uint256 _amount
  ) internal virtual {
    require(address(this).balance >= _amount, 'Insufficient balance');
    (bool success, ) = _recipient.call{value: _amount}('');
    require(success, 'recipient reverted');
  }

  // ============ Operational Function ============

  /**
    @dev 資産の引き出しオペレーション
    @notice WIP-1: this function should be able to invalidated for the future
   */
  function operationalWithdraw(address payable _recipient, uint256 _claimed) external virtual override onlyOwnerOrDistributor {
    bytes32 digest = keccak256(abi.encode('operationalWithdraw(address payable _recipient, uint256 _claimed)', _recipient, _claimed));
    _validateOparation(digest);
    _sendFunds(_recipient, _claimed);
  }

  /**
    @dev エージェントの設定
    @param _agentAddr エージェントのアドレス
    @param _licensed 権限の可否
  */
  function license(address _agentAddr, bool _licensed) external virtual override onlyOwnerOrAgent {
    _agent[_agentAddr] = _licensed;
  }

  /**
    @dev 分配コントラクトの設定
    @param _distributor 分配コントラクトアドレス
   */
  function setRemoteDistributor(address _distributor) public virtual override onlyOwnerOrAgent{
    distributor = _distributor;
  }

  /**
    @dev データフィードの再構成
    @param numeratorAddr_ 価格換算先のChainlinkアドレス
    @param denominatorAddr_ 価格換算元のChainlinkアドレス
   */
  function reconfigureData(address numeratorAddr_, address denominatorAddr_) external virtual override onlyOwnerOrAgent{
    _numeratorAddr = numeratorAddr_;
    _denominatorAddr = denominatorAddr_;
  }

  // ============ utility ============

  /**
    @dev 収益の分配データを取得
    @param _tokenId 楽曲id
    @return stakeHolders ステークホルダー
    @return share 収益分配率
    @return aggregator アグリゲーター
    @return recoupline1 リクープライン(円)
    @return recoupline2 リクープライン(実効価格)
   */
  function getShare(
    uint256 _tokenId
  ) external virtual override view returns (address[] memory, uint32[] memory, address payable, uint256, uint256){
    MusicLib.Music memory music = musics[_tokenId];
    return(music.stakeHolders, music.share, music.aggregator, music.recoupLine, calculateRecoupLine(_tokenId));
  }

  // ============ helper function ============
  function _exists(
    uint256 _tokenId
  ) internal virtual view returns(bool){
    if(_tokenId!=0){
      return musics[_tokenId].quantity != 0;
    }
    return true;
  }

  function _existsAlbum(uint256 _albumId) internal virtual view returns(bool){
    return _albumId < newAlbumId.current();
  }

  function _validateOparation(bytes32 digest) internal virtual {}

  /**
    @dev whitelistの認証(マークルツリーを利用)
    @param _tokenId 購入する楽曲のid
    @param _merkleProof マークルプルーフ
   */
  function _validateWhitelist(
    uint256 _tokenId,
    bytes32[] memory _merkleProof
  ) internal virtual {
    bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
    require(
      MerkleProofUpgradeable.verify(_merkleProof, musics[_tokenId].merkleRoot, leaf),
      "Invalid Merkle Proof"
    );
  }

  /**
    @dev 通貨価格の換算(円 => Wei)
    @return converter 円 => Wei
   */
  function _getEtherPerJPY()internal view returns(uint256){
    return(10**13);
    // Default: JPY(円)
    ( 
    /*uint80 roundID*/, 
    int256 _numerator, 
    /*uint startedAt*/, 
    /*uint timeStamp*/, 
    /*uint80 answeredInRound*/
    ) = AggregatorV3Interface(_numeratorAddr).latestRoundData();
    // 価格データの小数点以下桁数
    uint8 _numeratorDecimals = AggregatorV3Interface(_numeratorAddr).decimals();
    _numerator = MusicLib.scalePrice(_numerator, _numeratorDecimals);

    // Default: Ether
    ( 
    /*uint80 roundID*/, 
    int256 _denominator, 
    /*uint startedAt*/, 
    /*uint timeStamp*/, 
    /*uint80 answeredInRound*/
    ) = AggregatorV3Interface(_denominatorAddr).latestRoundData();
    // 価格データの小数点以下桁数
    uint8 _denominatorDecimals = AggregatorV3Interface(_denominatorAddr).decimals();
    _denominator = MusicLib.scalePrice(_denominator, _denominatorDecimals);

    // converter: 円 => Wei
    return uint256(_numerator) * 1 ether / uint256(_denominator);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
__        ___    ____ __  __ ___ __  __ _   _ ____ ___ ____ 
\ \      / / \  / ___|  \/  |_ _|  \/  | | | / ___|_ _/ ___|
 \ \ /\ / / _ \| |  _| |\/| || || |\/| | | | \___ \| | |    
  \ V  V / ___ \ |_| | |  | || || |  | | |_| |___) | | |___ 
   \_/\_/_/   \_\____|_|  |_|___|_|  |_|\___/|____/___\____|
*/

import {MusicLib} from "../lib/MusicLib.sol";

interface IRecord1155 {

   event MusicCreated(uint256 indexed tokenId,address[] stakeHolders,address aggregator,uint256[2] prices,uint32[] share,uint32 quantity,uint32 presaleQuantity,uint32 royalty,uint32 album,bytes32 merkleRoot);

   event MusicPurchased(uint256 indexed tokenId,uint32 indexed album,uint32 numSold,address indexed buyer);

   /**
      @dev コンストラクタ(Proxyを利用したコントラクトはinitializeでconstructorを代用)
      @param _artist コントラクトのオーナーアドレス
      @param name_ コントラクトの名称
      @param symbol_ トークンの単位
      @param _baseURI ベースURI
   */
   function initialize(address _artist,string memory name_,string memory symbol_,string memory _baseURI) external;

   /**
      @dev 楽曲データの作成(既存のアルバムに追加)
      @param music MusicData(Struct)
   */
   function createMusic(MusicLib.Music calldata music) external;

   /**
      @dev アルバムデータの作成
      @param album AlbumData(Struct)
   */
   function createAlbum(MusicLib.Album calldata album) external;

   function omniMint(uint256 _tokenId,uint32 _amount) external payable;

   /**
      @dev NFTの購入
      @param _tokenId 購入する楽曲のid
      @param _merkleProof マークルプルーフ
   */
   function omniMint(uint256 _tokenId,uint32 _amount,bytes memory _data,bytes32[] memory _merkleProof) external payable;

   /**
      @dev 販売状態の移行(列挙型で管理)
      @param _tokenIds 楽曲のid列
      @param _sale 販売状態(0 => prepared, 1=>presale, 2=>public sale, 3=>suspended)
   */
   function handleSaleState (uint256[] calldata _tokenIds, uint8 _sale) external;

   /**
      @dev マークルルートの設定
      @param _tokenIds 楽曲id
      @param _merkleRoot マークルルート
   */
   function setMerkleRoot(uint256[] calldata _tokenIds,bytes32 _merkleRoot) external;

   // ============ utility ============

   /**
      @dev newTokenId is totalSupply+1
      @return totalSupply 各トークンの発行量
   */
   function totalSupply(uint256 _tokenId) external view returns (uint256);

   /**
      @dev 特定のアルバムのtokenId列を取得
      @param _albumId アルバムid
      @return _tokenIdsOfMusic tokenId
   */
   function getTokenIdsOfAlbum(uint256 _albumId) external view returns (uint256[] memory);

   // ============ Operational Function ============

   /**
      @dev NFTのMintオペレーション
      @notice WIP-1: this function should be able to invalidated for the future
      */
   function operationalMint (address _recipient,uint256 _tokenId,uint32 _amount,bytes memory _data)external;

   // ============ Token Standard ============

   /**
      @dev コントラクトの名称表示インターフェース
   */
   function name() external view returns(string memory);

   /**
      @dev トークンの単位表示インターフェース
   */
   function symbol() external view returns(string memory);

   /**
      @dev ベースURIの設定
   */
   function setBaseURI(string memory _uri) external;
}

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981Upgradeable is IERC165Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;

import "./IERC1155Upgradeable.sol";
import "./IERC1155ReceiverUpgradeable.sol";
import "./extensions/IERC1155MetadataURIUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../utils/introspection/ERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC1155Upgradeable, IERC1155MetadataURIUpgradeable {
    using AddressUpgradeable for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    function __ERC1155_init(string memory uri_) internal onlyInitializing {
        __ERC1155_init_unchained(uri_);
    }

    function __ERC1155_init_unchained(string memory uri_) internal onlyInitializing {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return
            interfaceId == type(IERC1155Upgradeable).interfaceId ||
            interfaceId == type(IERC1155MetadataURIUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: address zero is not a valid owner");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `ids` and `amounts` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    /**
     * @dev Hook that is called after any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155ReceiverUpgradeable(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155ReceiverUpgradeable.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155ReceiverUpgradeable(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155ReceiverUpgradeable.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[47] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library CountersUpgradeable {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
__        ___    ____ __  __ ___ __  __ _   _ ____ ___ ____ 
\ \      / / \  / ___|  \/  |_ _|  \/  | | | / ___|_ _/ ___|
 \ \ /\ / / _ \| |  _| |\/| || || |\/| | | | \___ \| | |    
  \ V  V / ___ \ |_| | |  | || || |  | | |_| |___) | | |___ 
   \_/\_/_/   \_\____|_|  |_|___|_|  |_|\___/|____/___\____|
*/

interface IWAGMIApp {
  event Recoup(uint256 indexed tokenId,address aggregator,uint256 value);

  event Withdraw(address indexed claimant,address recipient,uint256 value,uint256 distribution,uint256 locked);

  /**
    @dev 収益の引き出し
    @param _recipient 受領者
    @param _value 請求額
    @dev param: value 引き出し可能な資産総額
    @dev param: _dist Editionごとの引き出し可能な資産額
   */
  function withdraw(
    address payable _recipient,
    uint256 _value
  ) external;

  /**
    @dev 引き出し可能な資産額の確認
    @param _claimant 請求アドレス
    @return distribution 配分された資産総額
    @return locked 未承認の配分額
    @return value 引き出し可能な資産総額
   */
  function withdrawable(
    address _claimant
  ) external view returns(
    uint256 distribution,
    uint256 locked,
    uint256 value
  );

  /**
    @dev 諸費用のリクープ
    @param _tokenId 楽曲id
   */
  function recoup(uint256 _tokenId) external;

  /**
    @dev リクープラインの換算(円 => Wei)
    @param _tokenId 楽曲id
    @return value リクープライン(Wei)
   */
  function calculateRecoupLine(uint256 _tokenId) external view returns(uint256 value);

  /**
    @dev 資産の引き出しオペレーション
    @notice WIP-1: this function should be able to invalidated for the future
   */
  function operationalWithdraw(address payable _recipient, uint256 _claimed) external;

  /**
    @dev エージェントの設定
    @param _agentAddr エージェントのアドレス
    @param _licensed 権限の可否
  */
  function license(address _agentAddr, bool _licensed) external;

  /**
    @dev 分配コントラクトの設定
    @param _distributor 分配コントラクトアドレス
   */
  function setRemoteDistributor(address _distributor) external;

  /**
    @dev データフィードの再構成
    @param numeratorAddr_ 価格換算先のChainlinkアドレス
    @param denominatorAddr_ 価格換算元のChainlinkアドレス
   */
  function reconfigureData(address numeratorAddr_, address denominatorAddr_) external;

  /**
    @dev 収益の分配データを取得
    @param _tokenId 楽曲id
    @return stakeHolders ステークホルダー
    @return share 収益分配率
    @return aggregator アグリゲーター
    @return recoupline1 リクープライン(円)
    @return recoupline2 リクープライン(実効価格)
   */
  function getShare(
    uint256 _tokenId
  ) external view returns (address[] memory, uint32[] memory, address payable, uint256, uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
__        ___    ____ __  __ ___ __  __ _   _ ____ ___ ____ 
\ \      / / \  / ___|  \/  |_ _|  \/  | | | / ___|_ _/ ___|
 \ \ /\ / / _ \| |  _| |\/| || || |\/| | | | \___ \| | |    
  \ V  V / ___ \ |_| | |  | || || |  | | |_| |___) | | |___ 
   \_/\_/_/   \_\____|_|  |_|___|_|  |_|\___/|____/___\____|
*/

interface IDistributor {
  function getDistribution(address claimant,uint256 tokenId,uint256 deposit,uint32 share) external view returns(bool approval,uint256 distribution);
  function getRecoupLine(uint256 tokenId) external view returns(uint256 recoupLine);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Tree proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
 */
library MerkleProofUpgradeable {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Calldata version of {verify}
     *
     * _Available since v4.7._
     */
    function verifyCalldata(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProofCalldata(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Calldata version of {processProof}
     *
     * _Available since v4.7._
     */
    function processProofCalldata(bytes32[] calldata proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Returns true if the `leaves` can be proved to be a part of a Merkle tree defined by
     * `root`, according to `proof` and `proofFlags` as described in {processMultiProof}.
     *
     * _Available since v4.7._
     */
    function multiProofVerify(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProof(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Calldata version of {multiProofVerify}
     *
     * _Available since v4.7._
     */
    function multiProofVerifyCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProofCalldata(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Returns the root of a tree reconstructed from `leaves` and the sibling nodes in `proof`,
     * consuming from one or the other at each step according to the instructions given by
     * `proofFlags`.
     *
     * _Available since v4.7._
     */
    function processMultiProof(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    /**
     * @dev Calldata version of {processMultiProof}
     *
     * _Available since v4.7._
     */
    function processMultiProofCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
        return a < b ? _efficientHash(a, b) : _efficientHash(b, a);
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
                /// @solidity memory-safe-assembly
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
interface IERC165Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155Upgradeable is IERC165Upgradeable {
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
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155ReceiverUpgradeable is IERC165Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155Upgradeable.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURIUpgradeable is IERC1155Upgradeable {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}