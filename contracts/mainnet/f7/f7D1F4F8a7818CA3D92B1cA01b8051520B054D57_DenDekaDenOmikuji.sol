// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;
/* 
* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
* @@@............[email protected]@
* @@@............[email protected]@
* @@@@........................................................................*@@@
* @@@@@.......[email protected]@@@@
* @@@@@@#....[email protected]@@@@@
* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
* @@@@@@@@@@@@*[email protected]@@@@@@@[email protected]@@@@@@@%[email protected]@@@@@@@@@@@
* @@@@@@@@@@@@@..............%@@@@@@@[email protected]@@@@@@,[email protected]@@@@@@@@@@@
* @@@@@@@@@@@@@@[email protected]@@@@@@&............/@@@@@@@............/@@@@@@@@@@@@@
* @@@@@@@@@@@@@@@[email protected]@@@@@@*[email protected]@@@@@@@............*@@@@@@@@@@@@@@
* @@@@@@@@@@@@@@@@.......,@@@@@@@[email protected]@@@@@@%............(@@@@@@@@@@@@@@@
* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@............/@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
* @@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
* @@@@@@@@@@@@@@@@@@@@@@@@@@%...............................,@@@@@@@@@@@@@@@@@@@@@
* @@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@
* @@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@
* @@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@
* @@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@
* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@,............/@@@@@@@@@@@@@@@@@@@@@@@@@@
* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@(............%@@@@@@@@@@@@@@@@@@@@@@@@@@@
* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@
* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@............,@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@(............%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@([email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@.... @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 電殿神伝 @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ DenDekaDen @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ Do you believe? @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ JD & BH @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
*/

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/utils/Base64.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';

contract DenDekaDenOmikuji is Ownable, ERC721 { 
  // Libraries
  using Strings for uint256;

  // For random attribute, use:
  // tokenId, timestamp, and donation amount
  struct TraitSeeds {
    uint256 timestamp;
    // how much was donated during mint -- used for better probabilities
    uint256 donationAmount;
  }

  // CONSTANTS
  uint8 constant NUM_CHARACTERS = 7;
  uint16 constant OMIKUJI_PER_CHARACTER = 108;

  // 0.07ETH is donation boost!
  // If you donate 0.07ETH or greater, your luck probabilities are boosted!
  uint256 constant DONATION_BOOST_THRESHOLD = 70000000000000000;

  /******* MINTING DATA *******/

  // track omikuji minter per character
  uint8[NUM_CHARACTERS] ascendingCharacterMints;
  // need to track team mints too
  uint8[NUM_CHARACTERS] descendingCharacterMints;


  // track GODLY tokenId for each character
  // IMPORTANT: defaults to 0 so NO TOKEN should have id of 0
  uint256[NUM_CHARACTERS] public godlyTokens;

  // storage of seeds for calculating traits
  mapping(uint256 /* tokenId */ => TraitSeeds) tokenTraitSeeds;

  // record ifa wallet has already minted a character
  mapping(address => mapping(uint8 /* characterId */ => uint256)) addressCharacterMints;

  // WHITELIST props
  bytes32 whitelistMerkleRoot;
  // JAPAN 2023-01-01 00:00:00 TIMESTAMP
  uint256 whitelistMintStartTime = 1672498800;
  // JAPAN 2023-01-01 07:30:00 TIMESTAMP
  uint256 mainMintStartTime = 1672525800;
  // whitelist mint records
  mapping(address /* user */ => bool) whitelistAddressMints;
  // team mint merkle root
  bytes32 teamMerkleRoot;
  // Team mints capped at 35
  uint256 teamMintsRemaining = 35;

  /******* ATTRIBUTE PROBABILITIES *********/

  // base attributes do not include "very good"
  uint8[] baseAttributeProbabilities = [0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2, 2, 3, 3, 3, 3, 3];

  // special attribute probabilities includes "very good"
  uint8[] specialAttributeProbabilities = [0, 0, 0, 0, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2, 2, 3, 3, 3, 3, 3, 4, 4, 4];

  // Very good most likely, then great, then good -- godly boosted on mint
  uint8[] boostAttributeProbabilities = [2, 3, 3, 3, 3, 4, 4, 4];

  // METADATA PROPS
  string _baseImgUri = "https://dendekaden.s3.ap-northeast-1.amazonaws.com/";
  bool _imgUriLocked = false;
  string constant DESCRIPTION = 'Sacred lots drawn by the First Believers, and held by the most ardent Devotees of ';
  string constant EXTERNAL_URL = 'https://www.dendekaden.com/';
  string[] fortuneCategories = [
    '2. LOVE',
    '3. BENEFACTOR',
    '4. BUSINESS',
    '5. ACADEMICS',
    '6. DISPUTES',
    '7. TRAVEL',
    '8. HEALTH',
    '9. WISH'
  ];
 
  string[] characterNames = [
    // 吉祥天
    'Megna',
    // 弁財天
    'Bene',
    // 大黒天
    'Yoa',
    // 恵比寿こひる
    'Kohiru',
    // 毘沙門天
    'Hisato',
    // 布袋
    'Taylor',
    // 寿老人
    'Momo'
  ];

  string[][] fortuneValues = [
    // LOVE
    [
      // 告白しらく待て
      '\xe5\x91\x8a\xe7\x99\xbd\xe3\x81\x97\xe3\x81\xb0\xe3\x82\x89\xe3\x81\x8f\xe5\xbe\x85\xe3\x81\xa6',
      // 今叶わずとも縁あり
      '\xe4\xbb\x8a\xe5\x8f\xb6\xe3\x82\x8f\xe3\x81\x9a\xe3\x81\xa8\xe3\x82\x82\xe7\xb8\x81\xe3\x81\x82\xe3\x82\x8a',
      // 歳に囚われる必要なし
      '\xe6\xad\xb3\xe3\x81\xab\xe5\x9b\x9a\xe3\x82\x8f\xe3\x82\x8c\xe3\x82\x8b\xe5\xbf\x85\xe8\xa6\x81\xe3\x81\xaa\xe3\x81\x97',
      // 良い人既に近くに
      '\xe8\x89\xaf\xe3\x81\x84\xe4\xba\xba\xe6\x97\xa2\xe3\x81\xab\xe8\xbf\x91\xe3\x81\x8f\xe3\x81\xab'
    ],
    // BENEFACTOR
    [
      // たよりなし
      '\xe3\x81\x9f\xe3\x82\x88\xe3\x82\x8a\xe3\x81\xaa\xe3\x81\x97',
      // 来るとも遅し 往きて利あり
      '\xe6\x9d\xa5\xe3\x82\x8b\xe3\x81\xa8\xe3\x82\x82\xe9\x81\x85\xe3\x81\x97\x20\xe5\xbe\x80\xe3\x81\x8d\xe3\x81\xa6\xe5\x88\xa9\xe3\x81\x82\xe3\x82\x8a',
      // 来る
      '\xe6\x9d\xa5\xe3\x82\x8b',
      // 来たる つれあり
      '\xe6\x9d\xa5\xe3\x81\x9f\xe3\x82\x8b\x20\xe3\x81\xa4\xe3\x82\x8c\xe3\x81\x82\xe3\x82\x8a'
    ],
    // BUSINESS
    [
      // 堅実さを取り戻せ
      '\xe5\xa0\x85\xe5\xae\x9f\xe3\x81\x95\xe3\x82\x92\xe5\x8f\x96\xe3\x82\x8a\xe6\x88\xbb\xe3\x81\x9b',
      // 利益少し焦るな　後になれば益あり
      '\xe5\x88\xa9\xe7\x9b\x8a\xe5\xb0\x91\xe3\x81\x97\xe7\x84\xa6\xe3\x82\x8b\xe3\x81\xaa\xe3\x80\x80\xe5\xbe\x8c\xe3\x81\xab\xe3\x81\xaa\xe3\x82\x8c\xe3\x81\xb0\xe7\x9b\x8a\xe3\x81\x82\xe3\x82\x8a',
      // 利益たしかなり
      '\xe5\x88\xa9\xe7\x9b\x8a\xe3\x81\x9f\xe3\x81\x97\xe3\x81\x8b\xe3\x81\xaa\xe3\x82\x8a',
      // 十分幸福
      '\xe5\x8d\x81\xe5\x88\x86\xe5\xb9\xb8\xe7\xa6\x8f'
    ],
    // ACADEMICS
    [
      // 今回は諦め切り替えるべし
      '\xe4\xbb\x8a\xe5\x9b\x9e\xe3\x81\xaf\xe8\xab\xa6\xe3\x82\x81\xe5\x88\x87\xe3\x82\x8a\xe6\x9b\xbf\xe3\x81\x88\xe3\x82\x8b\xe3\x81\xb9\xe3\x81\x97',
      // 伸びる時努力せよ
      '\xe4\xbc\xb8\xe3\x81\xb3\xe3\x82\x8b\xe6\x99\x82\xe5\x8a\xaa\xe5\x8a\x9b\xe3\x81\x9b\xe3\x82\x88',
      // 努力しただけ力になる
      '\xe5\x8a\xaa\xe5\x8a\x9b\xe3\x81\x97\xe3\x81\x9f\xe3\x81\xa0\xe3\x81\x91\xe5\x8a\x9b\xe3\x81\xab\xe3\x81\xaa\xe3\x82\x8b',
      // 歩み遅くとも着実に実る
      '\xe6\xad\xa9\xe3\x81\xbf\xe9\x81\x85\xe3\x81\x8f\xe3\x81\xa8\xe3\x82\x82\xe7\x9d\x80\xe5\xae\x9f\xe3\x81\xab\xe5\xae\x9f\xe3\x82\x8b'
    ],
    // DISPUTES
    [
      // 争いごと負けなり
      '\xe4\xba\x89\xe3\x81\x84\xe3\x81\x94\xe3\x81\xa8\xe8\xb2\xa0\xe3\x81\x91\xe3\x81\xaa\xe3\x82\x8a',
      // 勝ち退くが利
      '\xe5\x8b\x9d\xe3\x81\xa1\xe9\x80\x80\xe3\x81\x8f\xe3\x81\x8c\xe5\x88\xa9',
      // よろしさわぐな
      '\xe3\x82\x88\xe3\x82\x8d\xe3\x81\x97\xe3\x81\x95\xe3\x82\x8f\xe3\x81\x90\xe3\x81\xaa',
      // 心和やかにして吉
      '\xe5\xbf\x83\xe5\x92\x8c\xe3\x82\x84\xe3\x81\x8b\xe3\x81\xab\xe3\x81\x97\xe3\x81\xa6\xe5\x90\x89'
    ],
    // TRAVEL
    [
      // かえりはほど知れず
      '\xe3\x81\x8b\xe3\x81\x88\xe3\x82\x8a\xe3\x81\xaf\xe3\x81\xbb\xe3\x81\xa9\xe7\x9f\xa5\xe3\x82\x8c\xe3\x81\x9a',
      // して良いが無理避けよ
      '\xe3\x81\x97\xe3\x81\xa6\xe8\x89\xaf\xe3\x81\x84\xe3\x81\x8c\xe7\x84\xa1\xe7\x90\x86\xe9\x81\xbf\xe3\x81\x91\xe3\x82\x88',
      // 遠くはいかぬが利
      '\xe9\x81\xa0\xe3\x81\x8f\xe3\x81\xaf\xe3\x81\x84\xe3\x81\x8b\xe3\x81\xac\xe3\x81\x8c\xe5\x88\xa9',
      // 快調に進む
      '\xe5\xbf\xab\xe8\xaa\xbf\xe3\x81\xab\xe9\x80\xb2\xe3\x82\x80'
    ],
    // HEALTH
    [
      // 医師はしっかり選べ
      '\xe5\x8c\xbb\xe5\xb8\xab\xe3\x81\xaf\xe3\x81\x97\xe3\x81\xa3\xe3\x81\x8b\xe3\x82\x8a\xe9\x81\xb8\xe3\x81\xb9',
      // 早く医師に診せろ
      '\xe6\x97\xa9\xe3\x81\x8f\xe5\x8c\xbb\xe5\xb8\xab\xe3\x81\xab\xe8\xa8\xba\xe3\x81\x9b\xe3\x82\x8d',
      // 異変感じたら休め
      '\xe7\x95\xb0\xe5\xa4\x89\xe6\x84\x9f\xe3\x81\x98\xe3\x81\x9f\xe3\x82\x89\xe4\xbc\x91\xe3\x82\x81',
      // 心穏やかに過ごせ 快方に向かう
      '\xe5\xbf\x83\xe7\xa9\x8f\xe3\x82\x84\xe3\x81\x8b\xe3\x81\xab\xe9\x81\x8e\xe3\x81\x94\xe3\x81\x9b\x20\xe5\xbf\xab\xe6\x96\xb9\xe3\x81\xab\xe5\x90\x91\xe3\x81\x8b\xe3\x81\x86'
    ],
    // WISH
    [
      // 障りあり
      '\xe9\x9a\x9c\xe3\x82\x8a\xe3\x81\x82\xe3\x82\x8a',
      // 焦るな機は来る
      '\xe7\x84\xa6\xe3\x82\x8b\xe3\x81\xaa\xe6\xa9\x9f\xe3\x81\xaf\xe6\x9d\xa5\xe3\x82\x8b',
      // 多く望まなければ叶う
      '\xe5\xa4\x9a\xe3\x81\x8f\xe6\x9c\x9b\xe3\x81\xbe\xe3\x81\xaa\xe3\x81\x91\xe3\x82\x8c\xe3\x81\xb0\xe5\x8f\xb6\xe3\x81\x86',
      // 力合わせればきっと叶う
      '\xe5\x8a\x9b\xe5\x90\x88\xe3\x82\x8f\xe3\x81\x9b\xe3\x82\x8c\xe3\x81\xb0\xe3\x81\x8d\xe3\x81\xa3\xe3\x81\xa8\xe5\x8f\xb6\xe3\x81\x86'
    ]
  ];

  string[][] specialFortuneValues = [
    // LOVE
    [
      // 告白しばらく待て
      '\xe5\x91\x8a\xe7\x99\xbd\xe3\x81\x97\xe3\x81\xb0\xe3\x82\x89\xe3\x81\x8f\xe5\xbe\x85\xe3\x81\xa6',
      // 今叶わずとも縁あり
      '\xe4\xbb\x8a\xe5\x8f\xb6\xe3\x82\x8f\xe3\x81\x9a\xe3\x81\xa8\xe3\x82\x82\xe7\xb8\x81\xe3\x81\x82\xe3\x82\x8a',
      // 歳に囚われる必要なし
      '\xe6\xad\xb3\xe3\x81\xab\xe5\x9b\x9a\xe3\x82\x8f\xe3\x82\x8c\xe3\x82\x8b\xe5\xbf\x85\xe8\xa6\x81\xe3\x81\xaa\xe3\x81\x97',
      // 良い人既に近くに
      '\xe8\x89\xaf\xe3\x81\x84\xe4\xba\xba\xe6\x97\xa2\xe3\x81\xab\xe8\xbf\x91\xe3\x81\x8f\xe3\x81\xab',
      // 迷うことなかれ 心に決めた人が最上
      '\xe8\xbf\xb7\xe3\x81\x86\xe3\x81\x93\xe3\x81\xa8\xe3\x81\xaa\xe3\x81\x8b\xe3\x82\x8c\x20\xe5\xbf\x83\xe3\x81\xab\xe6\xb1\xba\xe3\x82\x81\xe3\x81\x9f\xe4\xba\xba\xe3\x81\x8c\xe6\x9c\x80\xe4\xb8\x8a',
      // 愛せよ 全て叶う
      '\xe6\x84\x9b\xe3\x81\x9b\xe3\x82\x88\x20\xe5\x85\xa8\xe3\x81\xa6\xe5\x8f\xb6\xe3\x81\x86'
    ],
    // BENEFACTOR
    [
      // たよりなし
      '\xe3\x81\x9f\xe3\x82\x88\xe3\x82\x8a\xe3\x81\xaa\xe3\x81\x97',
      // 来るとも遅し 往きて利あり
      '\xe6\x9d\xa5\xe3\x82\x8b\xe3\x81\xa8\xe3\x82\x82\xe9\x81\x85\xe3\x81\x97\x20\xe5\xbe\x80\xe3\x81\x8d\xe3\x81\xa6\xe5\x88\xa9\xe3\x81\x82\xe3\x82\x8a',
      // 来る
      '\xe6\x9d\xa5\xe3\x82\x8b',
      // 来たる つれあり
      '\xe6\x9d\xa5\xe3\x81\x9f\xe3\x82\x8b\x20\xe3\x81\xa4\xe3\x82\x8c\xe3\x81\x82\xe3\x82\x8a',
      // 来る 驚くことあり
      '\xe6\x9d\xa5\xe3\x82\x8b\x20\xe9\xa9\x9a\xe3\x81\x8f\xe3\x81\x93\xe3\x81\xa8\xe3\x81\x82\xe3\x82\x8a',
      // 来て喜びの奏こだまする
      '\xe6\x9d\xa5\xe3\x81\xa6\xe5\x96\x9c\xe3\x81\xb3\xe3\x81\xae\xe5\xa5\x8f\xe3\x81\x93\xe3\x81\xa0\xe3\x81\xbe\xe3\x81\x99\xe3\x82\x8b'
    ],
    // BUSINESS
    [
      // 堅実さを取り戻せ
      '\xe5\xa0\x85\xe5\xae\x9f\xe3\x81\x95\xe3\x82\x92\xe5\x8f\x96\xe3\x82\x8a\xe6\x88\xbb\xe3\x81\x9b',
      // 利益少し焦るな　後になれば益あり
      '\xe5\x88\xa9\xe7\x9b\x8a\xe5\xb0\x91\xe3\x81\x97\xe7\x84\xa6\xe3\x82\x8b\xe3\x81\xaa\xe3\x80\x80\xe5\xbe\x8c\xe3\x81\xab\xe3\x81\xaa\xe3\x82\x8c\xe3\x81\xb0\xe7\x9b\x8a\xe3\x81\x82\xe3\x82\x8a',
      // 利益たしかなり
      '\xe5\x88\xa9\xe7\x9b\x8a\xe3\x81\x9f\xe3\x81\x97\xe3\x81\x8b\xe3\x81\xaa\xe3\x82\x8a',
      // 十分幸福
      '\xe5\x8d\x81\xe5\x88\x86\xe5\xb9\xb8\xe7\xa6\x8f',
      // 御神徳により隆昌する
      '\xe5\xbe\xa1\xe7\xa5\x9e\xe5\xbe\xb3\xe3\x81\xab\xe3\x82\x88\xe3\x82\x8a\xe9\x9a\x86\xe6\x98\x8c\xe3\x81\x99\xe3\x82\x8b',
      // 夜動かばおおいに利あり
      '\xe5\xa4\x9c\xe5\x8b\x95\xe3\x81\x8b\xe3\x81\xb0\xe3\x81\x8a\xe3\x81\x8a\xe3\x81\x84\xe3\x81\xab\xe5\x88\xa9\xe3\x81\x82\xe3\x82\x8a'
    ],
    // ACADEMICS
    [
      // 今回は諦め切り替えるべし
      '\xe4\xbb\x8a\xe5\x9b\x9e\xe3\x81\xaf\xe8\xab\xa6\xe3\x82\x81\xe5\x88\x87\xe3\x82\x8a\xe6\x9b\xbf\xe3\x81\x88\xe3\x82\x8b\xe3\x81\xb9\xe3\x81\x97',
      // 伸びる時努力せよ
      '\xe4\xbc\xb8\xe3\x81\xb3\xe3\x82\x8b\xe6\x99\x82\xe5\x8a\xaa\xe5\x8a\x9b\xe3\x81\x9b\xe3\x82\x88',
      // 努力しただけ力になる
      '\xe5\x8a\xaa\xe5\x8a\x9b\xe3\x81\x97\xe3\x81\x9f\xe3\x81\xa0\xe3\x81\x91\xe5\x8a\x9b\xe3\x81\xab\xe3\x81\xaa\xe3\x82\x8b',
      // 歩み遅くとも着実に実る
      '\xe6\xad\xa9\xe3\x81\xbf\xe9\x81\x85\xe3\x81\x8f\xe3\x81\xa8\xe3\x82\x82\xe7\x9d\x80\xe5\xae\x9f\xe3\x81\xab\xe5\xae\x9f\xe3\x82\x8b',
      // 自信持てよろししかない
      '\xe8\x87\xaa\xe4\xbf\xa1\xe6\x8c\x81\xe3\x81\xa6\xe3\x82\x88\xe3\x82\x8d\xe3\x81\x97\xe3\x81\x97\xe3\x81\x8b\xe3\x81\xaa\xe3\x81\x84',
      // 信心すればどこまでも伸びる
      '\xe4\xbf\xa1\xe5\xbf\x83\xe3\x81\x99\xe3\x82\x8c\xe3\x81\xb0\xe3\x81\xa9\xe3\x81\x93\xe3\x81\xbe\xe3\x81\xa7\xe3\x82\x82\xe4\xbc\xb8\xe3\x81\xb3\xe3\x82\x8b'
    ],
    // DISPUTES
    [
      // 争いごと負けなり
      '\xe4\xba\x89\xe3\x81\x84\xe3\x81\x94\xe3\x81\xa8\xe8\xb2\xa0\xe3\x81\x91\xe3\x81\xaa\xe3\x82\x8a',
      // 勝ち退くが利
      '\xe5\x8b\x9d\xe3\x81\xa1\xe9\x80\x80\xe3\x81\x8f\xe3\x81\x8c\xe5\x88\xa9',
      // よろしさわぐな
      '\xe3\x82\x88\xe3\x82\x8d\xe3\x81\x97\xe3\x81\x95\xe3\x82\x8f\xe3\x81\x90\xe3\x81\xaa',
      // 心和やかにして吉
      '\xe5\xbf\x83\xe5\x92\x8c\xe3\x82\x84\xe3\x81\x8b\xe3\x81\xab\xe3\x81\x97\xe3\x81\xa6\xe5\x90\x89',
      // 勝負に利あり
      '\xe5\x8b\x9d\xe8\xb2\xa0\xe3\x81\xab\xe5\x88\xa9\xe3\x81\x82\xe3\x82\x8a',
      // 不言実行にて勝つことやすし
      '\xe4\xb8\x8d\xe8\xa8\x80\xe5\xae\x9f\xe8\xa1\x8c\xe3\x81\xab\xe3\x81\xa6\xe5\x8b\x9d\xe3\x81\xa4\xe3\x81\x93\xe3\x81\xa8\xe3\x82\x84\xe3\x81\x99\xe3\x81\x97'
    ],
    // TRAVEL
    [
      // かえりはほど知れず
      '\xe3\x81\x8b\xe3\x81\x88\xe3\x82\x8a\xe3\x81\xaf\xe3\x81\xbb\xe3\x81\xa9\xe7\x9f\xa5\xe3\x82\x8c\xe3\x81\x9a',
      // して良いが無理避けよ
      '\xe3\x81\x97\xe3\x81\xa6\xe8\x89\xaf\xe3\x81\x84\xe3\x81\x8c\xe7\x84\xa1\xe7\x90\x86\xe9\x81\xbf\xe3\x81\x91\xe3\x82\x88',
      // 遠くはいかぬが利
      '\xe9\x81\xa0\xe3\x81\x8f\xe3\x81\xaf\xe3\x81\x84\xe3\x81\x8b\xe3\x81\xac\xe3\x81\x8c\xe5\x88\xa9',
      // 快調に進む
      '\xe5\xbf\xab\xe8\xaa\xbf\xe3\x81\xab\xe9\x80\xb2\xe3\x82\x80',
      // 場所に執着するな いけうまくいく
      '\xe5\xa0\xb4\xe6\x89\x80\xe3\x81\xab\xe5\x9f\xb7\xe7\x9d\x80\xe3\x81\x99\xe3\x82\x8b\xe3\x81\xaa\x20\xe3\x81\x84\xe3\x81\x91\xe3\x81\x86\xe3\x81\xbe\xe3\x81\x8f\xe3\x81\x84\xe3\x81\x8f',
      // 御神徳により成功しかない
      '\xe5\xbe\xa1\xe7\xa5\x9e\xe5\xbe\xb3\xe3\x81\xab\xe3\x82\x88\xe3\x82\x8a\xe6\x88\x90\xe5\x8a\x9f\xe3\x81\x97\xe3\x81\x8b\xe3\x81\xaa\xe3\x81\x84'
    ],
    // HEALTH
    [
      // 医師はしっかり選べ
      '\xe5\x8c\xbb\xe5\xb8\xab\xe3\x81\xaf\xe3\x81\x97\xe3\x81\xa3\xe3\x81\x8b\xe3\x82\x8a\xe9\x81\xb8\xe3\x81\xb9',
      // 早く医師に診せろ
      '\xe6\x97\xa9\xe3\x81\x8f\xe5\x8c\xbb\xe5\xb8\xab\xe3\x81\xab\xe8\xa8\xba\xe3\x81\x9b\xe3\x82\x8d',
      // 異変感じたら休め
      '\xe7\x95\xb0\xe5\xa4\x89\xe6\x84\x9f\xe3\x81\x98\xe3\x81\x9f\xe3\x82\x89\xe4\xbc\x91\xe3\x82\x81',
      // 心穏やかに過ごせ 快方に向かう
      '\xe5\xbf\x83\xe7\xa9\x8f\xe3\x82\x84\xe3\x81\x8b\xe3\x81\xab\xe9\x81\x8e\xe3\x81\x94\xe3\x81\x9b\x20\xe5\xbf\xab\xe6\x96\xb9\xe3\x81\xab\xe5\x90\x91\xe3\x81\x8b\xe3\x81\x86',
      // 技術信ぜよ必ず治る
      '\xe6\x8a\x80\xe8\xa1\x93\xe4\xbf\xa1\xe3\x81\x9c\xe3\x82\x88\xe5\xbf\x85\xe3\x81\x9a\xe6\xb2\xbb\xe3\x82\x8b',
      // 御神徳により全て治る
      '\xe5\xbe\xa1\xe7\xa5\x9e\xe5\xbe\xb3\xe3\x81\xab\xe3\x82\x88\xe3\x82\x8a\xe5\x85\xa8\xe3\x81\xa6\xe6\xb2\xbb\xe3\x82\x8b'
    ]
  ];

  string[] overallFortune = [
    // 凶
    '\xe5\x87\xb6',
    // 末吉
    '\xe6\x9c\xab\xe5\x90\x89',
    // 吉
    '\xe5\x90\x89',
    // 中吉
    '\xe4\xb8\xad\xe5\x90\x89',
    // 大吉
    '\xe5\xa4\xa7\xe5\x90\x89',
    // 大大吉
    '\xe5\xa4\xa7\xe5\xa4\xa7\xe5\x90\x89'
  ];

  // Beneficiary address
  address beneficiary;

  constructor() ERC721('DenDekaDen Genesis Omikuji', '$DDD') {
    beneficiary = owner();
  }

  /**
   * @dev Check mints remaining per character
   *
   * Returns entire array for less rpc calls on frontend. Can't just return
   * mintsPerCharacter because it is a storage pointer.
   */
  function characterMintsRemaining() public view returns (uint256[] memory) {
    uint256[] memory mintsRemaining = new uint256[](NUM_CHARACTERS);
    for (uint8 i = 0; i < NUM_CHARACTERS; i++) {
      mintsRemaining[i] = characterMintsRemaining(i);
    }
    return mintsRemaining;
  }

   /**
   * @dev Check mints remaining per character
   *
   * Returns entire array for less rpc calls on frontend. Can't just return
   * mintsPerCharacter because it is a storage pointer.
   */
  function characterMintsRemaining(uint8 characterId) private view returns (uint256) {
    return OMIKUJI_PER_CHARACTER - ascendingCharacterMints[characterId] - descendingCharacterMints[characterId];
  }

  /**
   * @dev Check mint eligability for address
   * 
   * Returns:
   *  - 0 if not eligable
   *  - 1 if main mint
   *  - 2 if whitelist
   *  - 3 if teammint
   */
  function mintEligability(address user, bytes32[] calldata proof) public view returns (uint8) {
    // first check if main mint is open
    if(mainMintStartTime <= block.timestamp) {
      return 1;
    }

    bytes32 leaf = keccak256(abi.encodePacked(user));
    
    if(whitelistMintStartTime <= block.timestamp) {
      // check whitelist
      if (MerkleProof.verify(proof, whitelistMerkleRoot, leaf)) {
        return 2;
      }
    }
    // now check team whitelist
    if (MerkleProof.verify(proof, teamMerkleRoot, leaf)) {
      return 3;
    }

    return 0;
  }
 
  /**
   * @dev Set the whitelist root
   */
  function setWhitelistRoot(bytes32 root) public onlyOwner {
    whitelistMerkleRoot = root;
  }

  /**
   * @dev Set the team whitelist root
   */
  function setTeamMerkleRoot(bytes32 root) public onlyOwner {
    teamMerkleRoot = root;
  }

  function setBeneficiary(address _beneficiary) public onlyOwner {
    beneficiary = _beneficiary;
  }

  /**
   * @dev Set the whitelist and mint start times
   *
   * NOTE: can be used to close mint if need be
   */
  function setMintTimes(uint256 whitelistStart, uint256 mintStart) public onlyOwner {
    whitelistMintStartTime = whitelistStart;
    mainMintStartTime = mintStart;
  }

  /**
   * @dev Public mint function
   *
   * If time is before open mint, will call whitelist mint, otherwise will call
   * normal mint.
   *
   * Cannot mint if not before start time.
   *
   * Requirements:
   *  - cannot
   */
  function mint(uint8 characterId, bytes32[] memory proof) public payable returns (uint256 tokenId) {
    // Check if should be whitelist or normal mint

    // if past normal mint time, do normal mint
    if (mainMintStartTime <= block.timestamp) {
      return _mint(characterId, true);
    } else if (whitelistMintStartTime <= block.timestamp) {
      // if during normal whitelist period, no need to decrement team mints
      if(_validateWhitelist(proof, whitelistMerkleRoot, true) || _validateWhitelist(proof, teamMerkleRoot, false)) {
        return _mint(characterId, true);
      }
    } else {
      if(_validateWhitelist(proof, teamMerkleRoot, false)) {
        return _teamMint(characterId);
      }
    }
    revert("DDDO: Not eligable or already whitelist minted");
  }

  /**
   * @dev Whitelist mint
   *
   * Requirements:
   *  - only allow ONE mint per whitelist address
   */
  function _validateWhitelist(bytes32[] memory proof, bytes32 root, bool oneLimit) private returns (bool) {
    // ensure wallet owns no tokens
    if(whitelistAddressMints[msg.sender]) {
      return false;
    }

    // Check if address exists in merkle tree
    bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
    if(!MerkleProof.verify(proof, root, leaf)){
      return false;
    }

    // mark account as having minted
    if(oneLimit) {
      whitelistAddressMints[msg.sender] = true;
    }
    
    // mint if qualifies
    return true;

  }

   /**
   * @dev Team Mint function
   *
   * Team can mint a limited number of tokens.
   * Team tokens CANNOT be godly tokens.
   */
  function _teamMint(uint8 characterId) private returns (uint256) {
    // check we still have mints remaining
    require(teamMintsRemaining > 0, 'DDDO: No more team mints');
    
    teamMintsRemaining -= 1;

    return _mint(characterId, false);
  }

  function ownerCharacters(address owner) public view returns (uint256[] memory) {
    uint256[] memory characters = new uint256[](NUM_CHARACTERS);

    for (uint8 i = 0; i < NUM_CHARACTERS; i++) {
      characters[i] = addressCharacterMints[owner][i];
    }

    return characters;
  }

  /**
   * @dev Mints a new omikuji based on character provided
   *
   * Requirements:
   *  - must not be called from contract
   *  - must be valid character
   *  - character must have available omikuji
   *  - must not already own omikuji from this character
   */
  function _mint(uint8 characterId, bool ascending) private returns (uint256) {
    // only allow mint from user address, not bot
    require(tx.origin == msg.sender, 'DDDO: must be wallet');

    // ensure does not already own this character omikuji
    require(addressCharacterMints[msg.sender][characterId] == 0, "DDDO: Only 1 omikuji per chara");

    // get next token id -- will revert if too many tokens minted for character
    uint256 tokenId = nextTokenIdForCharacter(characterId, ascending);

    // store seed variables used to calculate attributes
    // on mint, jsut store blockNum + blockHash (?) with tokenId & donation?
    uint256 timestamp = block.timestamp;
    TraitSeeds storage seeds = tokenTraitSeeds[tokenId];
    seeds.timestamp = timestamp;
    seeds.donationAmount = msg.value;

    // if we do not have a godly token for this character, ~randomly see if godly token
    // NOTE: team mints CANNOT be godly tokens because they progress in descending order
    if (ascending && godlyTokens[characterId] == 0) {
      // if we do not have a godly token within first 107 mints, force 108 mint to be godly
      uint256 mintsRemaining = characterMintsRemaining(characterId);
      if (mintsRemaining == 0) {
        godlyTokens[characterId] = tokenId;
      } else {
        uint256 godlyModulo = mintsRemaining;

        // if donation is above threshold, boost probability to 20% or better
        if (msg.value >= DONATION_BOOST_THRESHOLD) {
          godlyModulo = godlyModulo > 5 ? 5 : godlyModulo;
        }

        // Roll for godly trait calculation here to test
        uint256 randRoll = uint256(keccak256(abi.encodePacked(tokenId, msg.sender, timestamp))) % godlyModulo;

        // If matches godlyModulo, we have found godly token!
        if (randRoll == 0) {
          godlyTokens[characterId] = tokenId;
        }
      }
    }

    // mint token
    super._mint(msg.sender, tokenId);


    // record this address has minted this character
    addressCharacterMints[msg.sender][characterId] = tokenId;

    return tokenId;
  }


  /**
   * @dev Generate the random attributes of a given token
   * 
   * Depends on when and how minted, so pseudo random.
   * 
   * NOTE: this is public because likely will use these values in the future.
   * 
   * Traits are:
   * 
   * LOVE
   * BENEFACTOR
   * BUSINESS
   * ACADEMICS
   * DISPUTES
   * TRAVEL
   * HEALTH
   * WISH -- no special -- last idx in arr
   */
  function _generatePseudoRandomAttributes(uint256 tokenId) public view returns (uint8[] memory) {

    uint256 characterId = characterIdFromToken(tokenId);

    // in total 8 traits to derive from tokenId, timestamp, blockhash
    uint8[] memory attributes = new uint8[](8);
    TraitSeeds memory seeds = tokenTraitSeeds[tokenId];
    bytes memory baseSeed = abi.encodePacked(seeds.timestamp, seeds.donationAmount, tokenId);

    for (uint256 i = 0; i < 8; i++) {
      uint8[] memory traitProbabilities;

      // check if should use special traits
      if (i == characterId) {
        // check if godly token
        if (godlyTokens[i] == tokenId) {
          traitProbabilities = new uint8[](1);
          traitProbabilities[0] = 5;
        } else {
          // check if should use boost or special probabilities
          if (seeds.donationAmount >= DONATION_BOOST_THRESHOLD) {
            traitProbabilities = boostAttributeProbabilities;
          } else {
            traitProbabilities = specialAttributeProbabilities;
          }
        }
      } else {
        // use base attribute probabilities
        traitProbabilities = baseAttributeProbabilities;
      }

      // generate random seed
      uint256 randSeed = uint256(keccak256(abi.encodePacked(baseSeed, i)));
      uint8 traitBucket = traitProbabilities[randSeed % traitProbabilities.length];
      attributes[i] = traitBucket;
    }

    return attributes;
  }

  function attributesJson(uint256 tokenId, uint8[] memory wishAttrs) public view returns (bytes memory) {
    // check if has soul fragment
    // subtract one because tokens are 1 indexed
    uint256 characterId = characterIdFromToken(tokenId);

    // put together metadata
    bytes memory attributes = '[';

    // add in character name
    attributes = abi.encodePacked(attributes, attributeJson('0. SOUL', characterNames[characterId]));

    // loop through all fortune categories
    for (uint8 i = 0; i < wishAttrs.length; i++) {
      bytes memory attr;
      // check if special attribute for character
      if (i == characterId) {
        attr = attributeJson(fortuneCategories[i], specialFortuneValues[i][wishAttrs[i]]);
        attr = abi.encodePacked(attr, ',', attributeJson('1. FORTUNE', overallFortune[wishAttrs[i]]));
      } else {
        // not special category, so use normal odds
        attr = attributeJson(fortuneCategories[i], fortuneValues[i][wishAttrs[i]]);
      }

      attributes = abi.encodePacked(
        // add comma if not the first entry for json correct formatting
        attributes,
        ',',
        attr
      );
    }

    // add in soul fragment
    attributes = abi.encodePacked(attributes, ',', attributeJson('Epoch', 'First Believers'));

    // close attributes
    attributes = abi.encodePacked(attributes, ']');

    return attributes;
  }

  function attributeJson(string memory traitType, string memory traitValue) internal pure returns (bytes memory) {
    return
      abi.encodePacked(
        '{',
        abi.encodePacked('"trait_type": "', traitType, '",'),
        abi.encodePacked('"value": "', traitValue, '"'),
        '}'
      );
  }

  /**
   * @dev create the image uri for resources
   *
   * Image is based on the luck level of the special attribute of the character.
   *
   */
  function _generateImgUri(uint256 characterId, uint8 luckLevel) internal view returns (string memory) {
    return
      string(
        abi.encodePacked(_baseImgUri, uint256(characterId).toString(), '_', uint256(luckLevel).toString(), '.png')
      );
  }

  /**
   * @dev Set a new uri for images so we can transition to IPFS
   *
   * If URI is locked, can never be changed.
   */
  function setImgUri(string calldata _uri) external onlyOwner {
    require(!_imgUriLocked, 'DDDO: Img Uri is locked!');
    _baseImgUri = _uri;
  }

  /**
   * @dev Lock the image URI so forever immutable
   *
   * NOTE: Can ONLY be called once, be sure images are correct
   */
  function lockImgUri() public onlyOwner {
    _imgUriLocked = true;
  }

  /////////////// TOKEN ID UTILITY FUNCTIONS //////////////////

  /**
   * @dev Calculates the next Id
   */
  function nextTokenIdForCharacter(uint8 characterId, bool ascending) internal returns (uint256) {
    // ensure valid character
    require(characterId < NUM_CHARACTERS, 'DDDO: Invalid character id!');

    // check can still mint for this character
    require(characterMintsRemaining(characterId) > 0, 'DDDO: No more omikuji available');

    uint16 tokenOffset;
    if(ascending) {
      // mint from bottom up -- increment first so 1 indexed
      ascendingCharacterMints[characterId] += 1;
      tokenOffset = ascendingCharacterMints[characterId];
    } else {
      // mint from top down -- increment after so ids are 1 indexed
      tokenOffset = OMIKUJI_PER_CHARACTER - descendingCharacterMints[characterId];
      descendingCharacterMints[characterId] += 1;
    }

    // derive tokenId
    // NOTE: we add 1 here because NO TOKEN should have ID of 0 (for godly attribute check), so 1 indexed
    return characterId * OMIKUJI_PER_CHARACTER + tokenOffset;
  }

  function characterIdFromToken(uint256 tokenId) internal pure returns (uint256) {
    // subtract 1 because ids start at 1
    return ((tokenId - 1) / OMIKUJI_PER_CHARACTER);
  }

  function tokenNumberForCharacter(uint256 tokenId) internal pure returns (uint256) {
    // subtract 1 because ids start at 1
    return (tokenId - 1) % OMIKUJI_PER_CHARACTER;
  }

  function withdraw() public {
    beneficiary.call{ value: address(this).balance }('');
  }

  /**
   * @dev Get OnChainMetadata for token
   */
  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    _requireMinted(tokenId);
    return getTokenURI(tokenId);
  }

  /**
   * @dev Generate metadata for each token.
   * 
   * All attributes are onchain, images can be moved to ipfs when ready.
   */
  function getTokenURI(uint256 tokenId) public view returns (string memory) {
    // 1 index characterID and character token
    uint256 characterId = characterIdFromToken(tokenId);
    uint256 characterToken = tokenNumberForCharacter(tokenId) + 1;
    uint8[] memory attributes = _generatePseudoRandomAttributes(tokenId);
    bytes memory tokenNameFormat = abi.encodePacked((characterToken < 10 ? '00' : (characterToken < 100 ? '0' : '')), characterToken.toString());

    bytes memory dataURI = abi.encodePacked(
      '{',
      '"name": "',
      characterNames[characterId],
      "'s Fortune #", tokenNameFormat,     
      '",',
      '"description": "',
      DESCRIPTION, characterNames[characterId], '.',
      '",',
      '"external_url": "',
      EXTERNAL_URL,
      '",',
      '"image": "',
      _generateImgUri(characterId, attributes[characterId]),
      '",',
      '"attributes": ',
      attributesJson(tokenId, attributes),
      '}'
    );
    return string(abi.encodePacked('data:application/json;base64,', Base64.encode(dataURI)));
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
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
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Base64.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides a set of functions to operate with Base64 strings.
 *
 * _Available since v4.5._
 */
library Base64 {
    /**
     * @dev Base64 Encoding/Decoding Table
     */
    string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /**
     * @dev Converts a `bytes` to its Bytes64 `string` representation.
     */
    function encode(bytes memory data) internal pure returns (string memory) {
        /**
         * Inspired by Brecht Devos (Brechtpd) implementation - MIT licence
         * https://github.com/Brechtpd/base64/blob/e78d9fd951e7b0977ddca77d92dc85183770daf4/base64.sol
         */
        if (data.length == 0) return "";

        // Loads the table into memory
        string memory table = _TABLE;

        // Encoding takes 3 bytes chunks of binary data from `bytes` data parameter
        // and split into 4 numbers of 6 bits.
        // The final Base64 length should be `bytes` data length multiplied by 4/3 rounded up
        // - `data.length + 2`  -> Round up
        // - `/ 3`              -> Number of 3-bytes chunks
        // - `4 *`              -> 4 characters for each chunk
        string memory result = new string(4 * ((data.length + 2) / 3));

        /// @solidity memory-safe-assembly
        assembly {
            // Prepare the lookup table (skip the first "length" byte)
            let tablePtr := add(table, 1)

            // Prepare result pointer, jump over length
            let resultPtr := add(result, 32)

            // Run over the input, 3 bytes at a time
            for {
                let dataPtr := data
                let endPtr := add(data, mload(data))
            } lt(dataPtr, endPtr) {

            } {
                // Advance 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // To write each character, shift the 3 bytes (18 bits) chunk
                // 4 times in blocks of 6 bits for each character (18, 12, 6, 0)
                // and apply logical AND with 0x3F which is the number of
                // the previous character in the ASCII table prior to the Base64 Table
                // The result is then added to the table to get the character to write,
                // and finally write it in the result pointer but with a left shift
                // of 256 (1 byte) - 8 (1 ASCII char) = 248 bits

                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance
            }

            // When data `bytes` is not exactly 3 bytes long
            // it is padded with `=` characters at the end
            switch mod(mload(data), 3)
            case 1 {
                mstore8(sub(resultPtr, 1), 0x3d)
                mstore8(sub(resultPtr, 2), 0x3d)
            }
            case 2 {
                mstore8(sub(resultPtr, 1), 0x3d)
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
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
library MerkleProof {
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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