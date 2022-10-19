// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.9;

import "./helpers/Ownable.sol";
import "./helpers/Pausable.sol";
import "./helpers/ERC721AWithRoyalties.sol";
import {LicenseVersion, CantBeEvil} from "./licenses/CantBeEvil.sol";

/*
. . . .. . . . . . .. . . . . . . . . . . . . . . .. . . . . . . . . . . . .. .. . . . .. . .. . . .. .. . . . . . .  
 .:ttt;t;tt;ttt;ttt;t;tt;t;t;ttt;ttt;ttt;tt;tt;ttt;t;tt;ttt;ttt;ttttttttttt;t;t;;tt;ttt;t;tt;t;tt;t;t;t;tttt%ttttttt.  .
. 8  8  8  8  8  8  8  8  8  8  8  8  8  8  8  8  8  8  8  8  8  8  8  8  8  8  8  8  8  8  8  8  8  8  8 8  8     ..   
. 88             88             88                      8           88 8   8  .          88                       8.S   
. [email protected]     . .  .   .     .  . .  .   .    . . . . . .    .  .  .  .        . .. . . .  .  .   . . . .  .       .  .      
. @X888 .  8. . .   .. . . 8.  . .   . .  .   .  .8 .. . .  .  .  . . . . . .   .   .  .. . .  . .8 . .. . . . .  ..8   
. 8X     . . . . ..   .   .  .  . ..  . .  . . .  .   .   . .. ..  . .. .. .. . . .. . . . . .  . .  .  .  .  . .   @   
. [email protected]     . . .    . .  . . . .. .  .  . .  .   .  . .  .  .  .  . .   .  .. ..... . .  . .   . .8 .  .  .  . .  . 8X . 
. S 88  .    . . .  . .  . . ..   .  . .  .  . . . .  .  .  . .. .. . . .  . . 8  . ... .  . . . .  . 8   .8 .8 . .88   
. 88 88  . .  . . .    .  . .  . . .  . .  . 8   . ..  . . . .  .8 . .  . .   . .  . 8.  .  .   . .8SX 8   .  .  .  ;   
. [email protected]@ 8   . . .    . . . . . .  .   .    .8X 88  .  .8.8.  .  .  .  . . .  ... . .  .  .  .  . .    8 8 8 .8.  .    8;. 
. SS 8   .  .  . . .  .   .   . . .  . .    8 8   .. .  . .  . . . .  .  ..   .  ..  .  .  .  . .   8 8    . .  .     . 
. [email protected]@     .  .  .   .  . . . .   . .  . .        .  . .  . .  . . . .  .   .  . .8 . . . . . .  .. 8     .    . . . .   
. 8X @8  . .  8    . .  . . . . .   . .         . .    .  .8.  .   . .  . . .888 8 .  8     .8.   .     . . . .  .      
. [email protected] 8     .8 8 8  . .   .    .  . .  .       .  . . . .    .  . .   .8 . 8 @ 8 ....  8  .   . . .  . .   .  . .   ; . 
. 8SX 8  . .   8   .   . . . .  . .  .  . . . . . .  .   . . . . . . . .    8 8  . .       . . . . .  .  .  .  . ..     
. [email protected]    .8 8 8    . 8 8 8 . . .  .  . .  .  . .  .. . . . .8.   . .   .    8    .      . . . .  . .  .  .  .  .   : . 
. 8S 8     .      .  8 8      .  . . .   .  . .  ..  . . .. . . .   ... . .      . .     .  .   .  . . . . .  .  .      
. [email protected]@    .  .  . . .   8   . . . .  . . . .  . .  .. .. .8. . . ... .  . .          ....  .  . . .  .   .  . . .  8.8 . 
. 8X 8    . ..  .         . .   . .   .    . .  .  .   . .  . .  . . .    .   . . .. .. .8 .  .  . . .  . .   . . . .   
. [email protected]@      .:.:  . .       .  .    . . . . .  . . . . .  . . . .  . . . .  . .  .  8  .  .  .  . .  . .  .  .   .   8;. 
. SSX  8 .  . .  8  . . . . .  . .  .   .   .  . .  .  .  . .  . .   . . .8 . .  .8 8  . 8   . .  .  . 8    . .  . 88. .
. 8SX8 8  .  [email protected]    .  .  . . .  .  . . . . .    . . . . .  ..   ..  .  .. .  .    888X 8   .  . . . 8 8    . .    . . 
. 8X 8     .   8    . .  . .. . .  . 8    .   . .  . . . . . .  .   . . . .  . .     8 88 8   .  .      8  .. . .   8;  
. [email protected] 8  .   8 8    .  .  . . 8   8X 8   .  . . . .  . . . . . . . . . .   . . . .          .  .  . .       .   .     . 
. 8SX8    .        . .  .  8XX      8 8   8    .   . . . . . .  .  .  . .. .  . .  .   8     .  .  .      .  . . .  :   
. 8X 8     .       .  .  .   888  8 8    8 88   .. .  . .......  .8 .  .  . .  . . . .     .  .  .  . . .  .. .         
. [email protected]    .  .   . . . ..   8 8    8 8  .   8  .  . ......  .   .  .  .  . .  . .  . .  . .  .  .  .  .  . .  . . .  ; . 
. 8SX  8  .  . .   .    .   8       .  .      . . .   . ..  . .8. . . .  . . .  .  . .  . .  . . . .  .  .  .   .       
. 8XX8     . .  . . . .  . 8 8  . .  ....  . . . .  . .   ..  .  . . . .    . .  .    . .  . .  .   .  .  .8 .8. .  : . 
. SS 8  8.  . .  .   . .  . . .  .  .  . . 8 8  . . . . ..  .  .  .. .  .. .   . . . . . .  . .  . . .  .  .  . .       
. [email protected]@    8.    .  . .   .  .   . .8.  .  8 8   . .  .. .   . .  .. . . .  . . .  .  .   . . .  .8.  . .  . . . . .  ;   
. 8SX      . . ..  . . . .  . [email protected]   . .  8 88  .. .8 8  . 8    .  . . . .  . . . . . ..    .   . . .   . . .    . .   . 
. SSX8   .  . . .. . .  . .  8  8 . .     8    ...8 8   .  88   .  . .   .  . .  .     . .  ..    .  . . .  . .    .: . 
. 8X 88  8.  .   . . ..  . .  8 8 . . .       .  8 8 8      8  ...  . ..  .  ...  . . . . .  . ..  . .  . . . . ..      
. [email protected] 8    . . .  . . . . .  8   . .  .      .  .   8  .      ... .  .  . . .   . . . .  . .  .  . .8 . 8.   . .  8 @  .
. 8X 8 8 .   .. 88 . . .  . .   . . .  .  . . .  .   .. ...  . . . .. . .  . . . . ..... .  . .. .  .  8    .   . . : . 
. [email protected]@ 8   . . 8X 8  . . .. . . . . . .  .  . .:;%[email protected]%@[email protected]@@[email protected]@%.;8S8 .. . .   . .   .  .  . . . . . .  8  8   .  .8   . 
. SSX 8    . 8 8     .  .   ..: .   . .  .  8888S8S;XXt88:XXXXS;XX%888%    . . . . .... . . .  .  .    88 8 . . .       
. 8SX8    .   8 8   . . . . ...  ..    .  .8 8888St%ttXX;@t%[email protected]@8X;:%;S%%%8.. . .  :%8   . .8 . . . . .8 8  . .   .  t . 
. 8X 8     .     8 .  .  . .   .  8   . .. 88%Xt:tS%[email protected]@%[email protected]@ ::88 8  .. t8%;   . .  .   .         . . .       
. [email protected]    . .        .  . .  . . .8 8    . 8888%@[email protected]@SS%SS8S8X8SXtXS8;S.:8tSt 8   :8% . .   .   .  . .  . .S   8  8 @   
. 8SX  8    .   . .  .  . . . 8.8 8    . SSt%%@[email protected]%[email protected]@[email protected]@[email protected]: . ...S;X:8:[email protected]%%888 .. . . . .  . .  @ 88  .      .
. 8XX8 8   . . . . . . . .  . .       . 88 :88t;;t%@t88%%X [email protected] %   t8X [email protected] 8   . . . .  .  .   8 8 8  . .% . 
. SS 88 8. .  . .   .   . .  .      .. [email protected]%@t:.;.8%.X8 X %X;88 [email protected] 8;888X  :8St : t888    . .  . .  .  . 8 8    .       
. [email protected] 8    .8.   ..  .. ..8. . .. .  . 8X%[email protected] : S;t888 @ @8%[email protected]:[email protected];tX:[email protected]%;;%.;%X8 8   .   . . ..  ..    8   .  . 8   
. 8X 8 8  .8  . .  .  .88 8;8.:... .:[email protected]@tXtXS %%8X8888X:;;%@%%@8X.S%t%. [email protected]@8.;;88 88   .. .  .  ..  .        .   :   
. [email protected] 8    . 8   . [email protected]:8;  [email protected]:..:;SX%88SS88X%@tSt888888: .:[email protected];t8%[email protected]:@X 8 8   .   .  . . .  . .  . . . [email protected] . 
. [email protected]    .   8 [email protected];::  .   :;;X8888X: @888X%@X  8   ;.X   ;;S8%XS88S.. 8S. ;@88S8:8   . . .  .8    . . .  . .    88. .
. 8X 8          ;8. .....    .:;:.:%[email protected]%@X8888;   [email protected]   S  X 8 .%XS. [email protected]@  8.  . .8S     . .  .  .  .88 :.  
. [email protected]    .    [email protected] ....::::;:::.::[email protected];;;;;:...   .::t8S   [email protected]@8 88XX.X;      :ttX ::X8 .. . .8 8  8 .  . .8.  .8 @ 88.  
. @XX  8  .  :@8%. .....::::SS;;:;;::::;:..... ...:::.;@tS%8X8:8 888 ;:@:t%%X 8:[email protected] .. .8 8      . .   8. 8 8 8 8t. 
..8X 8 8   .. 8Xt:......:....:;;;;;tt;::.... .. ..:t8t8X%X%.:88;[email protected];X.Xttt%@[email protected];tt: 88.88:8X:[email protected]%8  . .. . . . 8 8 88.. 
. [email protected]@    .8 [email protected]:........  .::;8tS8:tttXS;St88X88t:.:;8888SXttt::tt;@X8888X%;%[email protected]%8X88X8S;[email protected]%%  .  .     8 :   
. SSX    8.  .8%S:.. ...   .:::;;@:@  S..S8XX88X;8S88S;[email protected] XS888888S8 ;tX;;[email protected];:.;t;;;t;[email protected]@X8  .  .        . 
. 8SX8  8  . . 8X:..... ..;t;:.::..:t:88 @ t8t X8.%%  8  8:: [email protected];@[email protected]@88X;:...;[email protected] %8SX;:::;;;tttXXXXX%88   .  .     %   
. 8X 88  .  .  ;8t;X8;:..;t;:..... S. ;%8...::..    %X t8:888:@ %[email protected]@.S:8; ;:%;88%.....:;t;t%;[email protected]@[email protected]   .  . .      
. [email protected] 8   .  . tX8%88t:.:;;:...... [email protected] ..:::::::. .; t%[email protected]@88 S;t% 8X [email protected]  8888;.....::::;;[email protected]@ 8 8  .. .   S . 
. 8SX 8   . .. .8%@[email protected];:tt;........:8t8 .:...:.:.... %S;  : [email protected];:.X   S :88XtS t X8X:tt:......::;%@[email protected] 8  . . .  .     
. 8XX8 8  .   .  8%8%tt;;t:........;@%@t..::::::... . tXt.SX  ; ..; % [email protected]:% t ;SX:t8t..X ......;[email protected]: 8    . . .   : . 
. SS 8 8   . .  8 [email protected]%;:.......t;@8..:;:;%88tXS;8;tX88 S  :;:.;8 8;[email protected];t ;8%888;;[email protected]%@@8 8  .  .   .    . 
. [email protected]   8.  .     :;888;8XX;tt:...:[email protected]:SSX888S:: :;::[email protected]%@S8;@.: [email protected]:8t%[email protected]@ Xt ;X ; [email protected] 8    .  88        
. 8XX     .  . . .  88;;;%X:@@. ...;:;; :88X%S:::%@;XX:::@8t;XX%t.Xt8  [email protected]% @.t;tt;;S% ;:@[email protected] 8   .  . @     8t. 
. 8SX88    . . . t88Xtt;X8XSX.:....:::;[email protected];;tt;XXX%[email protected]  [email protected]%:X @.:8;X::[email protected]%[email protected]@[email protected]@  .  .   8     .   
. @X 8   . ... ;[email protected]%tt;tXXS::::;t:...::;;t8StS;tt%;;:tt;t88t%t%%;::;[email protected];[email protected];% :8X8t:X.  8 88%X 8 8   . .    8    t . 
[email protected]@ 8   . .: [email protected]%;8S..:.;S;:;8:....:;8t;;%;tt%%t;;;;::X8%:;%:8X;[email protected]%@[email protected]@8t:@ %;  @;X:[email protected] [email protected]:8 8   . . .    .  8;  
. 8X 8     . :8SX;%%@@;::..X8%%%tt;....::;;%t;;;%;:;;::. [email protected]:.%SS;::  .t:. Stt X8 [email protected] :;@ 8 %tXS8  8 .   .  . .    .
. [email protected] 8 . . :8tS8X;::::....t8%8;;%t:......::[email protected]@t%t;;;:..;8: %St%S:.::. 8 [email protected]  X 8 8 tS8.. :tX;[email protected] . ..  .  .  : . 
. 8SX 8  .  [email protected]@8X.::......::S888:;;;;:.......;[email protected];[email protected]:;..:;@8tt%StS8S;8  SXt:  [email protected] [email protected] @:::.::;SX%; :8     .  .. .     
. [email protected]   . %8tXX..........:;t8888.::::::.:..:;::::@ttt::.;[email protected]@[email protected]@8S8tX%8X XS @ %@[email protected]::..:;;%[email protected]%:8   . .  .   :   
. SS 8   . @:@t:.........:@[email protected]:;;:ttttXSX:;Xt;:.%@XXSSSXS%SS%: %%8SS [email protected]@X;.8% :...t%%t%[email protected] 8  . . .    .
. [email protected]@     8S Xt;:.... .. :[email protected]@88;:...;;::tXt%%888;;;:.:88:[email protected]@@[email protected]@%8..tXX @[email protected]:8%@% ...:%X;t%S8888%.%8   .   :   
. 8SX     88:8;:..... ...;8S%@@t88X;:.....:::%@tSXXS;;:[email protected]  .t%%S%[email protected]%X;X8 [email protected]@X888t:..::;;8t;;t88t8X 8   .  8t .
. SSX8    88;%t::..  ....:%[email protected]%[email protected];;:....:::%tXS:S:::;;.tS;.. ;t%[email protected];[email protected]  % 888;%%8S ....:.:t;;;t:SXS:8 .      . 
. 8S 88  8 8:.%.... .....;X:8t8::;[email protected];;;:...:t8X%tt;:;X:::;@@XX%%[email protected]@%[email protected]:t;8S. @ X %X88:;.   ....:tSt%St;;S8 8 . . %   
. [email protected]@ 88 8 8t8t:.. ......;[email protected]@tS8XSS%;;:...:;@X8X:::::..:.tX8;.tSXS8XXt;;:@S 8% S [email protected];8:.......:;XSXtt;%88          
. S [email protected] 8   8.:;:.........8t. [email protected]@@;;;;[email protected];[email protected]@%t%X8%S%tt;..:8; [email protected] XX.88S;8X8.......:t%[email protected]@%;:%.  8 . 8   
. .8 8 8  [email protected]:::.........:8:. ..:;[email protected]@8.%t;%S:SSt%[email protected];:8;.::[email protected];;[email protected];:....8; @@S [email protected] [email protected]::[email protected];%88;.;888    .  .
. @ 8 8 . [email protected]:.......:S;:[email protected]@[email protected]@S.;:;;;;::;t:[email protected];;SXXSt;t8t:.... ;8S% @ %:8. X8888;8;.:[email protected]%88S.:@8     8t  
. X8 %888;[email protected];@@t;[email protected]@;t;;;tt%8X::@8%;.8;@S:;@XXt;:..  .:8S @[email protected]%X 88X8S:@@::[email protected]@SSS%@@t:.%8  8    . 
. S [email protected]@X 8 8%88... .tt::::.:[email protected]:8  S;t%88888X;:[email protected]::8S%@@[email protected]%t%;.    .t  tX%tS;@S %@X;:.;XS:[email protected]@[email protected]:8X   8  t . 
. X8 88%8  X;[email protected]@8;tX8S;:::.....88%S:;tt;;t%[email protected];t88XX88888888tX8SSStSX%:.   .8S8 @8 .X8 tS 8:@:t%%@%8t%%%%[email protected]@    .     
. [email protected] :8 t%;@[email protected]:...::....:XXStt%%[email protected]@[email protected]%%t88:8::;t;t%%X;:[email protected]@888.;S%%:t;8S;8t X   :;@[email protected];[email protected];t8  ; . 
. X 88;[email protected]:XtS  [email protected]%...::::..:..X8%Xt8S.   : [email protected] :[email protected];888;::;[email protected];SX;;@@@..8X;[email protected];%tS%[email protected]@[email protected] .   
. @  88tX.;@8 SS.S8888X::..;t;::::;;[email protected]@ :8  . ..:[email protected]: @[email protected]@[email protected]@@S   %@XSS%t8St:SSX:  .%8X.;:.:@:S%X:;.X8Xt;88Stt8.. 
.  8%;8S t;;.8t%[email protected] :.;@8t;:..:;;:. X:@@% %8 88SX  88.:::;;[email protected]%StX 8;8 [email protected]::%8St8tS8:.. ;%:@%tt8S%Xtttt88:. 
. 8888t. ;::8;[email protected]:.::S%t88;..:X:.. :[email protected]@:@X:t   Xt:8 S8ttt;;%X8S%[email protected] @: %::%[email protected]:;:XX8 :..   @S%%;[email protected]@@..t8:. 
. 8t%:[email protected]:@: %8888888.:t8%%@;8: ;@:.....:@[email protected]@@[email protected] 8S ;%; X:8;%[email protected]@:[email protected]@[email protected]:8:.   ;88 %;SS%@:tX8;. 
. X8t:tt.t.SX .X88888;:[email protected]@:........:[email protected]@@[email protected];     : ;;    [email protected]@[email protected]%: :[email protected]@@;t% X...;@@8t8%@8t88XX . 
.  ;;:::t 8XX8 S8888S:;%[email protected];[email protected]  .  .......:%[email protected]@888. % ;SS%;  ;8t;t;;t%[email protected] 8;;@[email protected]:..;;[email protected]:[email protected]%8.. 
. @.::.X X8X%  [email protected];;;t888:@ [email protected]%@8t8.  .;X;;:. .::..;;X8;t888S.      [email protected]@@8;%%X: @88t%%8t8%[email protected]@t8;;;t;S;:[email protected] . 
.  :;[email protected]:  8S88;t;:;t%%[email protected]@;:  t:@..8S88:;::....::[email protected]%;:[email protected]@X % t:@@t;8X;%;[email protected]%:X:[email protected]@8%[email protected]% . 
. [email protected]@[email protected]@88% 8 @[email protected]@[email protected]@8888XSX8t888S.8X 8.t8.88 [email protected]@[email protected]@88::S:@ [email protected]@@[email protected] . 
   :;.t%SX;  :t:;:;:; S8%X:  [email protected]:   .;%SSt;t   .:    ::; .:   .t:t; :;: . :   t: .     ;;; :%; :.:%%;[email protected]::::; .  
   .   .         .      ..      . .       . .                         .   .               .             . .. .  .      .
*/

contract VinceFraserxSeed is Ownable, ERC721AWithRoyalties, Pausable, CantBeEvil(LicenseVersion.CBE_PR_HS) {
  string public _baseTokenURI;

  uint256 public _price;
  uint256 public _maxSupply;
  uint256 public _maxPerAddress;
  uint256 public _publicSaleTime;
  uint256 public _maxTxPerAddress;
  mapping(address => uint256) private _purchases;

  event Purchase(address indexed addr, uint256 indexed atPrice, uint256 indexed count);

  constructor(
    // name, symbol, baseURI, price, maxSupply, maxPerAddress, publicSaleTime, maxTxPerAddress, royaltyRecipient, royaltyAmount
    string memory name,
    string memory symbol,
    string memory baseTokenURI,
    uint256 price,
    uint256 maxSupply,
    uint256 maxPerAddress,
    uint256 publicSaleTime,
    uint256 maxTxPerAddress,
   // price - 0, maxSupply - 1, maxPerAddress - 2, publicSaleTime - 3, _maxTxPerAddress - 4
    address royaltyRecipient,
    uint256 royaltyAmount
  ) ERC721AWithRoyalties(name, symbol, maxSupply, royaltyRecipient, royaltyAmount) {
    _baseTokenURI = baseTokenURI;
    _price = price;
    _maxSupply = maxSupply;
    _maxPerAddress = maxPerAddress;
    _publicSaleTime = publicSaleTime;
    _maxTxPerAddress = maxTxPerAddress;
  }

  function setSaleInformation(
    uint256 publicSaleTime,
    uint256 maxPerAddress,
    uint256 price,
    uint256 maxTxPerAddress
  ) external onlyOwner {
    _publicSaleTime = publicSaleTime;
    _maxPerAddress = maxPerAddress;
    _price = price;
    _maxTxPerAddress = maxTxPerAddress;
  }

  function setBaseUri(
    string memory baseUri
  ) external onlyOwner {
    _baseTokenURI = baseUri;
  }

  function _baseURI() override internal view virtual returns (string memory) {
    return string(
      abi.encodePacked(
        _baseTokenURI
      )
    );
  }

  function mint(address to, uint256 count) external payable onlyOwner {
    ensureMintConditions(count);
    _safeMint(to, count);
  }

  function purchase(uint256 count) external payable whenNotPaused {
    require(msg.value == count * _price);
    ensurePublicMintConditions(msg.sender, count, _maxPerAddress);
    require(isPublicSaleActive(), "BASE_COLLECTION/CANNOT_MINT");

    _purchases[msg.sender] += count;
    _safeMint(msg.sender, count);
    uint256 totalPrice = count * _price;
    emit Purchase(msg.sender, totalPrice, count);
  }

  function ensureMintConditions(uint256 count) internal view {
    require(totalSupply() + count <= _maxSupply, "BASE_COLLECTION/EXCEEDS_MAX_SUPPLY");
  }

  function ensurePublicMintConditions(address to, uint256 count, uint256 maxPerAddress) internal view {
    ensureMintConditions(count);
    require((_maxTxPerAddress == 0) || (count <= _maxTxPerAddress), "BASE_COLLECTION/EXCEEDS_MAX_PER_TRANSACTION");
    uint256 totalMintFromAddress = _purchases[to] + count;
    require ((maxPerAddress == 0) || (totalMintFromAddress <= maxPerAddress), "BASE_COLLECTION/EXCEEDS_INDIVIDUAL_SUPPLY");

  }

  function isPublicSaleActive() public view returns (bool) {
    return (_publicSaleTime == 0 || _publicSaleTime < block.timestamp);
  }

  function isPreSaleActive() public pure returns (bool) {
    return false;
  }

  function MAX_TOTAL_MINT() public view returns (uint256) {
    return _maxSupply;
  }

  function PRICE() public view returns (uint256) {
    return _price;
  }

  function MAX_TOTAL_MINT_PER_ADDRESS() public view returns (uint256) {
    return _maxPerAddress;
  }

  function pause() external onlyOwner {
    _pause();
  }

  function unpause() external onlyOwner {
    _unpause();
  }
  function supportsInterface(bytes4 interfaceId) public view virtual override(CantBeEvil, ERC721AWithRoyalties) returns (bool) {
    return
        super.supportsInterface(interfaceId);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "./Context.sol";

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "./Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./ERC721A.sol";
import "./IERC2981Royalties.sol";

// @author rollauver.eth

contract ERC721AWithRoyalties is
  Ownable,
  ERC721A,
  IERC2981Royalties
{
  struct RoyaltyInfo {
    address recipient;
    uint24 amount;
  }
  RoyaltyInfo private _royalties;

  constructor(
    string memory name_,
    string memory symbol_,
    uint256 maxBatchSize_,
    address royaltyRecipient,
    uint256 royaltyValue
  ) ERC721A(name_, symbol_, maxBatchSize_) {
    _setRoyalties(royaltyRecipient, royaltyValue);
  }
  
  /// @inheritdoc ERC165
  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override
    returns (bool)
  {
    return
      interfaceId == type(IERC2981Royalties).interfaceId ||
      super.supportsInterface(interfaceId);
  }

  /// @dev Sets token royalties
  /// @param recipient recipient of the royalties
  /// @param value percentage (using 2 decimals - 10000 = 100, 0 = 0)
  function _setRoyalties(address recipient, uint256 value) internal {
    require(value <= 10000, 'ERC2981Royalties: Too high');
    _royalties = RoyaltyInfo(recipient, uint24(value));
  }

  /// @inheritdoc IERC2981Royalties
  function royaltyInfo(uint256, uint256 value)
    external
    view
    override
    returns (address receiver, uint256 royaltyAmount)
  {
    RoyaltyInfo memory royalties = _royalties;
    receiver = royalties.recipient;
    royaltyAmount = (value * royalties.amount) / 10000;
  }

  function updateRoyalties(address recipient, uint256 value) external onlyOwner {
    _setRoyalties(recipient, value);
  }
}

// SPDX-License-Identifier: MIT
// a16z Contracts v0.0.1 (CantBeEvil.sol)
pragma solidity ^0.8.13;

import "../helpers/Strings.sol";
import "../helpers/ERC165.sol";
import "./ICantBeEvil.sol";

enum LicenseVersion {
    CBE_CC0,
    CBE_ECR,
    CBE_NECR,
    CBE_NECR_HS,
    CBE_PR,
    CBE_PR_HS
}

contract CantBeEvil is ERC165, ICantBeEvil {
    using Strings for uint;
    string internal constant _BASE_LICENSE_URI = "ar://_D9kN1WrNWbCq55BSAGRbTB4bS3v8QAPTYmBThSbX3A/";
    LicenseVersion public licenseVersion; // return string
    constructor(LicenseVersion _licenseVersion) {
        licenseVersion = _licenseVersion;
    }

    function getLicenseURI() public view returns (string memory) {
        return string.concat(_BASE_LICENSE_URI, uint(licenseVersion).toString());
    }

    function getLicenseName() public view returns (string memory) {
        return _getLicenseVersionKeyByValue(licenseVersion);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165) returns (bool) {
        return
            interfaceId == type(ICantBeEvil).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function _getLicenseVersionKeyByValue(LicenseVersion _licenseVersion) internal pure returns (string memory) {
        require(uint8(_licenseVersion) <= 6);
        if (LicenseVersion.CBE_CC0 == _licenseVersion) return "CBE_CC0";
        if (LicenseVersion.CBE_ECR == _licenseVersion) return "CBE_ECR";
        if (LicenseVersion.CBE_NECR == _licenseVersion) return "CBE_NECR";
        if (LicenseVersion.CBE_NECR_HS == _licenseVersion) return "CBE_NECR_HS";
        if (LicenseVersion.CBE_PR == _licenseVersion) return "CBE_PR";
        else return "CBE_PR_HS";
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
// Creators: locationtba.eth, 2pmflow.eth

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./IERC721Metadata.sol";
import "./IERC721Enumerable.sol";
import "./Address.sol";
import "./Context.sol";
import "./Strings.sol";
import "./ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata and Enumerable extension. Built to optimize for lower gas during batch mints.
 *
 * Assumes serials are sequentially minted starting at 0 (e.g. 0, 1, 2, 3..).
 *
 * Does not support burning tokens to address(0).
 */
contract ERC721A is
  Context,
  ERC165,
  IERC721,
  IERC721Metadata,
  IERC721Enumerable
{
  using Address for address;
  using Strings for uint256;

  struct TokenOwnership {
    address addr;
    uint64 startTimestamp;
  }

  struct AddressData {
    uint128 balance;
    uint128 numberMinted;
  }

  uint256 private currentIndex = 1;

  uint256 internal immutable maxBatchSize;

  // Token name
  string private _name;

  // Token symbol
  string private _symbol;

  // Mapping from token ID to ownership details
  // An empty struct value does not necessarily mean the token is unowned. See ownershipOf implementation for details.
  mapping(uint256 => TokenOwnership) private _ownerships;

  // Mapping owner address to address data
  mapping(address => AddressData) private _addressData;

  // Mapping from token ID to approved address
  mapping(uint256 => address) private _tokenApprovals;

  // Mapping from owner to operator approvals
  mapping(address => mapping(address => bool)) private _operatorApprovals;

  /**
   * @dev
   * `maxBatchSize` refers to how much a minter can mint at a time.
   */
  constructor(
    string memory name_,
    string memory symbol_,
    uint256 maxBatchSize_
  ) {
    require(maxBatchSize_ > 0, "ERC721A: max batch size must be nonzero");
    _name = name_;
    _symbol = symbol_;
    maxBatchSize = maxBatchSize_;
  }

  /**
   * @dev See {IERC721Enumerable-totalSupply}.
   */
  function totalSupply() public view override returns (uint256) {
    return currentIndex - 1;
  }

  /**
   * @dev See {IERC721Enumerable-tokenByIndex}.
   */
  function tokenByIndex(uint256 index) public view override returns (uint256) {
    require(index < totalSupply(), "ERC721A: global index out of bounds");
    return index;
  }

  /**
   * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
   * This read function is O(totalSupply). If calling from a separate contract, be sure to test gas first.
   * It may also degrade with extremely large collection sizes (e.g >> 10000), test for your use case.
   */
  function tokenOfOwnerByIndex(address owner, uint256 index)
    public
    view
    override
    returns (uint256)
  {
    require(index < balanceOf(owner), "ERC721A: owner index out of bounds");
    uint256 numMintedSoFar = totalSupply();
    uint256 tokenIdsIdx = 0;
    address currOwnershipAddr = address(0);
    for (uint256 i = 0; i < numMintedSoFar; i++) {
      TokenOwnership memory ownership = _ownerships[i];
      if (ownership.addr != address(0)) {
        currOwnershipAddr = ownership.addr;
      }
      if (currOwnershipAddr == owner) {
        if (tokenIdsIdx == index) {
          return i;
        }
        tokenIdsIdx++;
      }
    }
    revert("ERC721A: unable to get token of owner by index");
  }

  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC165, IERC165)
    returns (bool)
  {
    return
      interfaceId == type(IERC721).interfaceId ||
      interfaceId == type(IERC721Metadata).interfaceId ||
      interfaceId == type(IERC721Enumerable).interfaceId ||
      super.supportsInterface(interfaceId);
  }

  /**
   * @dev See {IERC721-balanceOf}.
   */
  function balanceOf(address owner) public view override returns (uint256) {
    require(owner != address(0), "ERC721A: balance query for the zero address");
    return uint256(_addressData[owner].balance);
  }

  function _numberMinted(address owner) internal view returns (uint256) {
    require(
      owner != address(0),
      "ERC721A: number minted query for the zero address"
    );
    return uint256(_addressData[owner].numberMinted);
  }

  function ownershipOf(uint256 tokenId)
    internal
    view
    returns (TokenOwnership memory)
  {
    require(_exists(tokenId), "ERC721A: owner query for nonexistent token");

    uint256 lowestTokenToCheck;
    if (tokenId >= maxBatchSize) {
      lowestTokenToCheck = tokenId - maxBatchSize + 1;
    }

    for (uint256 curr = tokenId; curr >= lowestTokenToCheck; curr--) {
      TokenOwnership memory ownership = _ownerships[curr];
      if (ownership.addr != address(0)) {
        return ownership;
      }
    }

    revert("ERC721A: unable to determine the owner of token");
  }

  /**
   * @dev See {IERC721-ownerOf}.
   */
  function ownerOf(uint256 tokenId) public view override returns (address) {
    return ownershipOf(tokenId).addr;
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
  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );

    string memory baseURI = _baseURI();
    return
      bytes(baseURI).length > 0
        ? string(abi.encodePacked(baseURI, tokenId.toString()))
        : "";
  }

  /**
   * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
   * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
   * by default, can be overriden in child contracts.
   */
  function _baseURI() internal view virtual returns (string memory) {
    return "";
  }

  /**
   * @dev See {IERC721-approve}.
   */
  function approve(address to, uint256 tokenId) public override {
    address owner = ERC721A.ownerOf(tokenId);
    require(to != owner, "ERC721A: approval to current owner");

    require(
      _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
      "ERC721A: approve caller is not owner nor approved for all"
    );

    _approve(to, tokenId, owner);
  }

  /**
   * @dev See {IERC721-getApproved}.
   */
  function getApproved(uint256 tokenId) public view override returns (address) {
    require(_exists(tokenId), "ERC721A: approved query for nonexistent token");

    return _tokenApprovals[tokenId];
  }

  /**
   * @dev See {IERC721-setApprovalForAll}.
   */
  function setApprovalForAll(address operator, bool approved) public override {
    require(operator != _msgSender(), "ERC721A: approve to caller");

    _operatorApprovals[_msgSender()][operator] = approved;
    emit ApprovalForAll(_msgSender(), operator, approved);
  }

  /**
   * @dev See {IERC721-isApprovedForAll}.
   */
  function isApprovedForAll(address owner, address operator)
    public
    view
    virtual
    override
    returns (bool)
  {
    return _operatorApprovals[owner][operator];
  }

  /**
   * @dev See {IERC721-transferFrom}.
   */
  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public override {
    _transfer(from, to, tokenId);
  }

  /**
   * @dev See {IERC721-safeTransferFrom}.
   */
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public override {
    safeTransferFrom(from, to, tokenId, "");
  }

  /**
   * @dev See {IERC721-safeTransferFrom}.
   */
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory _data
  ) public override {
    _transfer(from, to, tokenId);
    require(
      _checkOnERC721Received(from, to, tokenId, _data),
      "ERC721A: transfer to non ERC721Receiver implementer"
    );
  }

  /**
   * @dev Returns whether `tokenId` exists.
   *
   * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
   *
   * Tokens start existing when they are minted (`_mint`),
   */
  function _exists(uint256 tokenId) internal view returns (bool) {
    return tokenId < currentIndex;
  }

  function _safeMint(address to, uint256 quantity) internal {
    _safeMint(to, quantity, "");
  }

  /**
   * @dev Mints `quantity` tokens and transfers them to `to`.
   *
   * Requirements:
   *
   * - `to` cannot be the zero address.
   * - `quantity` cannot be larger than the max batch size.
   *
   * Emits a {Transfer} event.
   */
  function _safeMint(
    address to,
    uint256 quantity,
    bytes memory _data
  ) internal {
    uint256 startTokenId = currentIndex;
    require(to != address(0), "ERC721A: mint to the zero address");
    // We know if the first token in the batch doesn't exist, the other ones don't as well, because of serial ordering.
    require(!_exists(startTokenId), "ERC721A: token already minted");
    require(quantity <= maxBatchSize, "ERC721A: quantity to mint too high");

    _beforeTokenTransfers(address(0), to, startTokenId, quantity);

    AddressData memory addressData = _addressData[to];
    _addressData[to] = AddressData(
      addressData.balance + uint128(quantity),
      addressData.numberMinted + uint128(quantity)
    );
    _ownerships[startTokenId] = TokenOwnership(to, uint64(block.timestamp));

    uint256 updatedIndex = startTokenId;

    for (uint256 i = 0; i < quantity; i++) {
      emit Transfer(address(0), to, updatedIndex);
      require(
        _checkOnERC721Received(address(0), to, updatedIndex, _data),
        "ERC721A: transfer to non ERC721Receiver implementer"
      );
      updatedIndex++;
    }

    currentIndex = updatedIndex;
    _afterTokenTransfers(address(0), to, startTokenId, quantity);
  }

  /**
   * @dev Transfers `tokenId` from `from` to `to`.
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
  ) private {
    TokenOwnership memory prevOwnership = ownershipOf(tokenId);

    bool isApprovedOrOwner = (_msgSender() == prevOwnership.addr ||
      getApproved(tokenId) == _msgSender() ||
      isApprovedForAll(prevOwnership.addr, _msgSender()));

    require(
      isApprovedOrOwner,
      "ERC721A: transfer caller is not owner nor approved"
    );

    require(
      prevOwnership.addr == from,
      "ERC721A: transfer from incorrect owner"
    );
    require(to != address(0), "ERC721A: transfer to the zero address");

    _beforeTokenTransfers(from, to, tokenId, 1);

    // Clear approvals from the previous owner
    _approve(address(0), tokenId, prevOwnership.addr);

    _addressData[from].balance -= 1;
    _addressData[to].balance += 1;
    _ownerships[tokenId] = TokenOwnership(to, uint64(block.timestamp));

    // If the ownership slot of tokenId+1 is not explicitly set, that means the transfer initiator owns it.
    // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
    uint256 nextTokenId = tokenId + 1;
    if (_ownerships[nextTokenId].addr == address(0)) {
      if (_exists(nextTokenId)) {
        _ownerships[nextTokenId] = TokenOwnership(
          prevOwnership.addr,
          prevOwnership.startTimestamp
        );
      }
    }

    emit Transfer(from, to, tokenId);
    _afterTokenTransfers(from, to, tokenId, 1);
  }

  /**
   * @dev Approve `to` to operate on `tokenId`
   *
   * Emits a {Approval} event.
   */
  function _approve(
    address to,
    uint256 tokenId,
    address owner
  ) private {
    _tokenApprovals[tokenId] = to;
    emit Approval(owner, to, tokenId);
  }

  uint256 public nextOwnerToExplicitlySet = 0;

  /**
   * @dev Explicitly set `owners` to eliminate loops in future calls of ownerOf().
   */
  function _setOwnersExplicit(uint256 quantity) internal {
    uint256 oldNextOwnerToSet = nextOwnerToExplicitlySet;
    require(quantity > 0, "quantity must be nonzero");
    uint256 endIndex = oldNextOwnerToSet + quantity - 1;
    if (endIndex > currentIndex - 1) {
      endIndex = currentIndex - 1;
    }
    // We know if the last one in the group exists, all in the group exist, due to serial ordering.
    require(_exists(endIndex), "not enough minted yet for this cleanup");
    for (uint256 i = oldNextOwnerToSet; i <= endIndex; i++) {
      if (_ownerships[i].addr == address(0)) {
        TokenOwnership memory ownership = ownershipOf(i);
        _ownerships[i] = TokenOwnership(
          ownership.addr,
          ownership.startTimestamp
        );
      }
    }
    nextOwnerToExplicitlySet = endIndex + 1;
  }

  /**
   * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
   * The call is not executed if the target address is not a contract.
   *
   * @param from address representing the previous owner of the given token ID
   * @param to target address that will receive the tokens
   * @param tokenId uint256 ID of the token to be transferred
   * @param _data bytes optional data to send along with the call
   * @return bool whether the call correctly returned the expected magic value
   */
  function _checkOnERC721Received(
    address from,
    address to,
    uint256 tokenId,
    bytes memory _data
  ) private returns (bool) {
    if (to.isContract()) {
      try
        IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data)
      returns (bytes4 retval) {
        return retval == IERC721Receiver(to).onERC721Received.selector;
      } catch (bytes memory reason) {
        if (reason.length == 0) {
          revert("ERC721A: transfer to non ERC721Receiver implementer");
        } else {
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
   * @dev Hook that is called before a set of serially-ordered token ids are about to be transferred. This includes minting.
   *
   * startTokenId - the first token id to be transferred
   * quantity - the amount to be transferred
   *
   * Calling conditions:
   *
   * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
   * transferred to `to`.
   * - When `from` is zero, `tokenId` will be minted for `to`.
   */
  function _beforeTokenTransfers(
    address from,
    address to,
    uint256 startTokenId,
    uint256 quantity
  ) internal virtual {}

  /**
   * @dev Hook that is called after a set of serially-ordered token ids have been transferred. This includes
   * minting.
   *
   * startTokenId - the first token id to be transferred
   * quantity - the amount to be transferred
   *
   * Calling conditions:
   *
   * - when `from` and `to` are both non-zero.
   * - `from` and `to` are never both zero.
   */
  function _afterTokenTransfers(
    address from,
    address to,
    uint256 startTokenId,
    uint256 quantity
  ) internal virtual {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title IERC2981Royalties
/// @dev Interface for the ERC2981 - Token Royalty standard
interface IERC2981Royalties {
  /// @notice Called with the sale price to determine how much royalty
  //          is owed and to whom.
  /// @param _tokenId - the NFT asset queried for royalty information
  /// @param _value - the sale price of the NFT asset specified by _tokenId
  /// @return _receiver - address of who should be sent the royalty payment
  /// @return _royaltyAmount - the royalty payment amount for value sale price
  function royaltyInfo(uint256 _tokenId, uint256 _value)
    external
    view
    returns (address _receiver, uint256 _royaltyAmount);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
// a16z Contracts v0.0.1 (ICantBeEvil.sol)
pragma solidity ^0.8.13;

interface ICantBeEvil {
    function getLicenseURI() external view returns (string memory);
    function getLicenseName() external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

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
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
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

import "./IERC721.sol";

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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