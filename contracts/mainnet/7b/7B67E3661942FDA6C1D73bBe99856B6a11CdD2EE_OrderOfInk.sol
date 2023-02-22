// SPDX-License-Identifier: MIT
//
//
//                              ▐▌▀▀▀▀*∞w▄▄
//                       ╓▄▄▄mKK╣▌          ─╙?∞▄,
//                ,▄Æ▀▀╙└       ╞▌           ~.   └7w,
//             ▄▀▀└             ╞▌                .   └W
//          ▄▀╙              ┌▄▄██▄▄▄,              '    *
//        ▄▀¬        .~▄#▀▀╙└         ─└╙▀▀W▄▄        ^    ¼
//       █┘     .⌐` ,█▀' ,▄▀▀╙└└└    `¬.    ~ └▀▀▄,     ¼   \
//      █U  ,⌐     █▀  ╓▀└   ▄██████▄    `    ┐   └▀%▄   t   ┌
//      ▌,⌐`      ▐▌  ▐▌   ████████████        ─      ╙▀▄▐
// ¬┘   ▌^w       ╟µ  ▐▌   ████████████    >   ═      ,▄▀▐   └└
//  \   █   "w     █,  ╙▄   ╙▀██████▀╙   ┌┘   ╛    ,Æ▀└  ╛
//   ┐   █     ─"w, ╙¼,  └▀wµ        ,»⌐└   A└ ,▄▀╙     Æ
//    \   ▀▄       ¬"ⁿ═█╗▄,   ─└────    ▄p█═⌐▀┘       ,▀
//     "┐   ▀▄            └└╙╙7²%▌²7╙└└└            ▄┘
//       └V   └▀▄               ╟▌               ▄²└
//          └∞▄   └▀═▄,         ╞▌          ╓÷²└
//             ¬└Yw▄   ¬└└²²**≈═╫▌≈≈⌐⌐²²└└¬
//                   └┘ΓY*═▄▄▄▄▄╟▌
//
//
//                       The Order of Ink
//                Smart Contract by Ryan Meyers
//                      beautifulcode.eth
//
//               Generosity attracts generosity
//             The world will be saved by beauty
//

pragma solidity ^0.8.17;

import "ERC721AQueryable.sol";
import "Ownable.sol";
import "ERC2981.sol";
import "draft-EIP712.sol";
import "ECDSA.sol";

import "RevokableDefaultOperatorFilterer.sol";
import "UpdatableOperatorFilterer.sol";


contract OrderOfInk is ERC2981, EIP712, ERC721AQueryable, Ownable, RevokableDefaultOperatorFilterer {

    /* *//////////////////////,▄▄▄▌▓▓▓▓▓╬▓██
    /* *///////////////µe═Q▓▓╫Φ╙╨╙╙╨╨▀▀▀╬▒░░╚╩╚╙╨▀╝▀█
    /* *////////,╓##▀▀▀▄▓▀╬O└       ' ^"^└╨▀▄░;;└≈ç'j▓███
    /* */////▄#╨└.╗╩┌╓╬╠<└             '' '''╨▀▄^:▄▓▀╠▓███▓
    /* *///▄▀ ''φ▀░φ╟╫╙                '      ' ╨█▄▓▀╙^╙███▓
    /* * .▓▀^':╬╬░╓╬╩,µµ≈⌐TéM≤╓,  .. ..'..~.   ▄▓▀╙▀▄^.'▐j╠█▄ 
    /* * ╟▌^.╓▓╙.]▓▀╠═≈∞∞≈-µ╓└v#φ░≥>"""▒░"^^""╙█=«, ╙▓▄.^M╚╣█~
    /* * █⌐.]╬⌐╥▓╩░^7"µse⌐^^^╙╙¥╠φ▒░/w!└░░'⌐.       "ª╬▓▄@≤▒▓▓ 
    /* *▐█'.▓░╫▒╙)ε░░;;;,µµ¿:µµ,,╙╪╬7Φ▒▒δ░░φ,~   .'.."└(╙▓J▒║▓▌
    /* *▓▌^▐█▓▓▓▀▓▓▀▀▀╬╬▀╟╨╝▄▄╙Σb╪µ╙╣▒╨╬▒╦╠╬G┌.,,.~''.~┌>╫▒╢▓╬█µ
    /* *╫▌╫▓█╠╬▀╨!░░░¡¡∩>!└░Γ#╪╬╪▄╙╠╫▒╧▓╠╬╣╠╠░¡░"~',┌¡∩.~^▒,╙█▀▀
    /* *^█╫▒█▌╠!┌!]Ä╛5∩╦▄µ▄▄░≥≥░▒╫▓▒╣█▓▓▓██▓▓╩░j▓▓██▓▒▒~.,▒┌"╟,j▌
    /* * /▓█▓█░▒┌"▐▌#Γ╙│;=░≥=¡╨▀▒░╠╬████▓▓███▒"▓████▓▓██▓▓▄b/Σ███
    /* * /╫▓█▄▄▓▀▀▓╩▀▀▀▀▒╬▌▀▀▀▌▓█▓▌███████▀╫└╠████████▓███▄╣▄,╨█▌
    /* * /▄▀██▓▒φ∩!ÅQ╠╬δ╩╫╬▄▄╫╬▓█████████╣╬▀░;█████████▄██╬█████>
    /* * /╙╝█████▌▌▌▀▀▀▓▓█▓▓██████▓▓█████╩╬φΘε╨██▌███████╫██▒███▓
    /* *///╬╫▓███▓╫╬╬▓█████████▓▓█▓█████▒▒!└▓▌⌐╨╨▀███▀ .╣█╣¬████
    /* *///▐⌐╫╬████▀╬█████▓▓██▓╫╣▒▄▒╓░╚▀╬''.└"▀~'j╫*└\ ▐╫╩ ▓██╣
    /* *////:▌╣███▒Σ╨▀█████╬▓███▓▓╣╬╣╬╠░Γµ⌐⌐^;Q╛╙│^⌐^' ^ j███╫
    /* */////Å╠╬╣████╣▌╬████▌▓╣█████▓▓╬╬║▒j▓╨╥▄ε  1Θ╣╣⌐    ██╫▌
    /* *///E//└▀█╬███████████▓█▓████▓▓█████▓██▌ê, ⌐└╚▌ Q∩ `^▓█
    /* *////R/E//▀█╫███████████▓██▓▓╬╠╠▓█╨▀█████▓█▓▒]▐ ╬╠▌ ▌ ▓
    /* *///E/R/R//╙▓▄¡¡└╫███████▓██╬╬╬╠▓█  └╨███▓▓▀▐└▓▓▓╬▌⌐███▌
    /* *////R/0/R///╙▀▄▓████████▌▓█▓╬╟╬▓██┬~ ╙▀██████▄██▀╙ █Æ▀─
    /* *///E/R/R/0/R/S/██████████▓╬█▓╬╫╫█████▓▄█████████▌▌▄,╓
    /* *////R/0///R////]█████████▓▓╫███▓▌▒,▀███████████████╫█
    /* */////R/R//////'`██████████▓████▓▓╬║▌ ║╣▌▓▓╬╠▒▓╚=/▒▓ █
    /* *//////0/////////'╫███████████████▓▓▓▌╬▒▌▓█▒╣╬▓  ]▓▓▄▐-
    /* */error Paused();//─████████████████████▓▄▓▒▌▓▌╓╓╠╬▓╙ █ .
    /* */error InvalidMintKey();///╙╙▀╟█▌▄▌▄╠██████████████▓▀╩ ¬
    /* */error ExceedsMaxSupply();//╬╟╙▓█MΦW▄╫▓▓██▀▓█▌╬▀▓▓╬╙╛b
    /* */error ExceedsAllowance();//▓▌▀╙▀█     ╙▓██▌█ ┘╠█
    /* */error PublicSaleNotStarted();///╙▓▀▌▄┐ ╙████╨╙▓▀
    /* */error InsufficientAmountSent();///─  ╙▀██████╙─╙▄
    /* */error NoMoreThanTwentyPerTransaction();//▀███▌¬└
    /* */error WalletNotSender();//////////////////└╙
    // *////////////////////////////////////////


    
    /* C                 ,  */
    /* O               ▐ █ */ address private constant _TEAM = 0x5e5A5450548829Ad30B10Bcb81c4Cf5Fb609FEff;
    /* N               ▄██ */                   uint public constant SESSION_ONE_BLACK_PRICE = 0.08 ether;
    /* S               ╫█ ▓▌ */                   uint public constant SESSION_ONE_GOLD_PRICE = 0.4 ether;
    /* T           ▀▓▄ ▌█╜╟▌ */                uint public constant SESSION_TWO_BLACK_PRICE = 0.123 ether;
    /* A             ╙▀╝█▌▀  ▄ */                 uint public constant SESSION_TWO_GOLD_PRICE = 0.5 ether;
    /* N      ▐╣╣╣╣╣╬▀▄   ⌐▐█▀ */                                 uint private constant _maxSupply = 4444;
    /* T      ▐╣╣╣╣╣╣ ╙▀ █╦██▀╙ */                              uint private constant _maxGoldSupply = 67;
    /* S      ▐╣╣╣╬▓╣    ╚  █ */                              uint private constant _teamBlackMints = 150;
    /*        ▐╣╣╣╣╬█▌   | ╫█▀┌▄C */                            uint private constant _teamGoldMints = 10;
    /*        ▐╣╣╣╣╣╣w█=,╫▌▓▓█▀ */
    /* K      ▐╣╣╣╣▓▓  ╙▀▓└▀└ ▄▌ */
    /* E      ▐╣╣╣╬▓█▌   ┤   ⌠█Æ^ */   struct MintKey {
    /* Y      ▐╣╣╣╣╣╬▀=  ╪█▀╦▄▄▄▄ */       address wallet;
    /* S     ,▐█╬█╬▓╣ ▀▀▄╫Γ,▄▓█▄ */          uint8 free;
    /*     4╬Æ╬██████▌,  ╫ */                  uint8 allowed; }
    /*   Æ╬▀╬╙╚╝╩╝╩▓█▀▄▀µ▐ */          bytes32 private constant MINTKEY_TYPE_HASH = keccak256(
    /*  ▄▀▄▀         ▀▄▀▄▐ */                    "MintKey(address wallet,uint8 free,uint8 allowed)");
    /*  ▐╩X╛         └▄▀▄╟ */
    /*  ▐╬▀╬»       «╫▀▌▀▐ */              struct CombineKey {uint256[] tokenIds;}
    /*    ▀╬▀▄Æ▄*▄▀▄▀▄▀▄ ▐ */                  bytes32 private constant COMBINEKEY_TYPE_HASH = keccak256(
    /*      ╨▄╨▄▀▄▀▄▀    ▐ */                      "CombineKey(uint256[] tokenIds)");
    /*                ,,╓╫╓╓╓╓,, */
    /* V         ,φ▒╠╠╠╠╠╫╠╠╠╠╠╠╠╠▒╦, */
    /* A      ╓å╠╠╠╠╠╠╠╠╠▓╠╠╠╠╠╠╠╠╠╠╠╠▒╓ */    address private _signer;  
    /* R    φ╠╠╠╠╠╠╠╠╠╠╠╠█╠╠╠╠╠╠╠╬▒╠╠╠╠╠╠╔ */    address private _receiver;
    /* S  ╓╠╠╠╠╠╠╠╠╠╠╠╠╠╠█╩╩╩▓██▓╬╬╬╬╬▀▀▓██▄ */    
    /*   φ╠╠╠╠╠╠╠╠╠╠╩╙   ▓ ╓█╙  ╙╠╠╠╠╠╠╠╠╠╠╬╬ */  bool public paused = true;
    /*  φ╠╠╠╠╠╠╠╠╠╚      ▓╓█      ^╠╠╠╠╠╠╠╠╠╠╦ */   string public baseURI;
    /* ]╠╠╠╠╠╠╠╠╠╙       ██─        ╙╠╠╠╠╠╠╠╠╠⌐ */   uint8 public session = 1;
    /* ╠╠╠╠╠╠╠╠╠╙        █┌          ╚╠╠╠╠╠╠╠╠▒ */     uint private _goldMinted = 0;
    /* ╠╠╠╠╠╠╠╠╠⌐        ▌           ]╠╠╠╠╠╠╠╠╠ */   
    /* ╠╠╠╠╠╠╠╠╠ε       j▌           ]╠╠╠╠╠╠╠╠╠ */
    /* ╚╠╠╠╠╠╠╠╠╠       ▐⌐           ╠╠╠╠╠╠╠╠╠▒ */    constructor( 
    /*  ╠╠╠╠╠╠╠╠╠▒      ▓           ╠╠╠╠╠╠╠╠╠╠ */    string memory name, string memory symbol,
    /*  ╙╠╠╠╠╠╠╠╠╠╠╔   ,█         ╔╠╠╠╠╠╠╠╠╠╠⌐ */   address signer, address receiver
    /* C └╠╠╠╠╠╠╠╠╠╠╠▒█▌█▌   ,,╔▒╠╠╠╠╠╠╠╠╠╠╠" */   ) ERC721A(name, symbol) EIP712(name, "1") {
    /* O   ╚╠╠╠╠╠╠╠╠╠▓█╠███╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠╚ */   _signer = signer; _receiver = receiver;
    /* N    `╚╠╠╠╠╠╠╠██╠█╠▓█▒╠╠╠╠╠╠╠╠╠╠╠╚ */    _setDefaultRoyalty(receiver, 1000);
    /* S       ╙╩╠╠╠╠██╠█╠╠╠▓╫╠╠╠╠╠╠╠╩╙ */    baseURI = "https://bafybeidmchhjl2nraifqwymp44s3vaemvewa5f65o5gpn6qztjliryadle.ipfs.nftstorage.link/";
    /* T          └╙╚╬█╠█╠╠╠╠╠╠╠╩╙╙ */  
    /* R    T         █ ▐µ */         _goldMinted += _teamGoldMints;
    /* U    E  M       ▌ ▌ */   _mintERC2309(_TEAM, _teamGoldMints);
    /* C    A  I       ╙▄▌ */   _setExtraDataAt(_startTokenId(), 1);
    /* T    M  N        ╙█ */   _mintERC2309(_TEAM, _teamBlackMints);
    /* O       T         ╫ */   }
    /* R       S         ╙ */


    //                                ,
    //                       "δ≥  φ╧╙└
    //                 ,,,,╓╓╦▄▓███▓╗╓,
    //    ,╦▄▓▓╬╬╣╣╣▓▓╣╫█▓╫▓██████████▓╬╠╬▓╬╬▓▓▒▒╦╗╓
    //  ,▓█▓█▓╬╬╬▓███▌╚▓╬▓█████MINT██████▓╬▓╩╬██▓╣▓▓▓█▌▄
    //  ▓╬▓███╬▒░▓███▌╠╣▓█▓███METHOD██▓▓██▓╬▒▓████╠╣╫██▓█#
    //  ╙█▓▄╬▀▀▓╣╣╬╣▀╬▓▓╫╣▌╣╬▓▓▒▓████╬▓╣╬▓▓╬▓╬╣▓█▌▌▓█▓██▓▓Ö
    //     └╙▀▓▄╟▀▀╣▓▀▀▓███▄▓▓▌▒╙▀██▌╣▓▄▓▓▓▓▓█▓█▓▓▀╠▄█▓▀▀
    //         └╙▀▀▓╣▄#╫███╫╠▓▒╬▓█▓█▒▒░▓███╫▄▄▄▄╣▓▓▀╙
    //             ▓▒╢▓▓▓▓╣▓██▓▌██▓██▌╣▌▓▓╬▓█▒█─
    //              ╙╣▄▄╠▀▀▀╬▒╥╨  ╙█╩▀▀██▓▀╬▄▓▀
    //                  ╙▀▀╙▀└     └╙▀╝▀▀▀▀▀└
    // *  For the sake of transparency, the code for the mint method  * //
    // *     will be unadorned. Please reach out if anything seems    * //
    // *   unclear or un-readable or insecure(!) Twitter: @sreyeMnayR * //
    //
    function getInked(
      bytes calldata signature, // a typed message (EIP712) signed with a secret private key
      MintKey calldata key,     // a struct representing the message
      uint8 howManyBlack,       // how many editions of 8 or 15 to mint
      uint8 howManyGold,        // how many 1 of 1 editions to mint
      uint24 choiceData         // a packed integer representing artist preference
    ) external payable {

      if(paused) revert Paused();

      uint256 nextTokenId;
      uint8 howMany = howManyGold + howManyBlack;

      // if there are free tokens in the mint key, check if they're already minted
      // if not, add them to the "howMany" variable.
      if(0<key.free){ howMany += key.free - uint8(_getAux(msg.sender)); }
      
      // if there aren't enough tokens left to fulfill the order... sorry, bye!
      if (totalSupply() + howMany > _maxSupply) revert ExceedsMaxSupply();

      // if not enough $ETH was sent with the transaction... sorry, bye!
      if (msg.value < (
        (blackPrice() * howManyBlack) + (goldPrice() * howManyGold)
        )) revert InsufficientAmountSent();

      // the first two minting sessions require a mint key (allow list)
      if (session < 3){
        // if the sender has already minted their allotment... sorry, bye!
        if (_numberMinted(msg.sender) + howMany > key.allowed) revert ExceedsAllowance();

        // if the sender isn't the wallet in the mint key... sorry, bye!
        if (msg.sender != key.wallet) revert WalletNotSender();

        // if the signed, typed message doesn't match the data sent... sorry, bye!
        if (!autoclave(signature, key)) revert InvalidMintKey();
        
        // if there are free tokens to claim...
        if (0 < key.free) {
          uint64 aux = _getAux(msg.sender);
          // if free tokens haven't yet been minted...
          if (aux < key.free) {
              // set the aux before minting to avoid reentrancy attacks
              _setAux(msg.sender, key.free);
              // add the free tokens to the black tokens being minted
              howManyBlack += uint8(key.free - aux);
            }
        }
      } else {
        // no more than 10 of any tier per mint transaction in public sale
        if(howManyGold > 10) revert ExceedsAllowance();
        if(howManyBlack > 10) revert ExceedsAllowance();
      }

      // if the mint includes editions of 8/15...
      if(howManyBlack > 0){
        // make sure there are enough black tokens remaining
        if (howManyBlack > blackRemaining()) revert ExceedsMaxSupply();
        // store the next tokenId. can't write choice data until it's been initialized.
        nextTokenId = _nextTokenId();
        // mint the tokens
        _mint(msg.sender, howManyBlack);
        // record the artist choice data
        _setExtraDataAt(nextTokenId, choiceData);
      }

      // if the mint includes 1 of 1 editions...
      if(howManyGold > 0){
        // make sure there are enough gold tokens remaining
        if (howManyGold > goldRemaining()) revert ExceedsMaxSupply();
        // store the next token id
        nextTokenId = _nextTokenId();
        
        // increment the number of gold tokens minted
        _goldMinted += howManyGold;
        // mint the gold tokens
        _mint(msg.sender, howManyGold);
        // include the choice data (+1, as the first bit indicates the tier)
        _setExtraDataAt(nextTokenId, choiceData+1);
      }
    // That's it!
    }
      
    /*                    ,,,,,,,
    /*            ,╔@▒╣╬╬╣╬╬╬╬╬╬╬╬╬╬▒╗╓*/
    /*         ,#╬╬╠╠╩╩╩▒▒╚╠╩╠▒╚╚╚╚╚╚╚╩╩╠╗,*/ function finalSession(
    /*       ,╠╩╚▒▒▒╚░░░░░░░╚░░░░φ▒≥Ä▒▒╩╠╬╬╬▒▒*/ bytes calldata signature,
    /*      φ▒Γ░!░▒░░▐░░░░░░≥╙░└░░░░░░▄▄▄╬╩╝╝╝╬╣*/ uint256[] calldata tokenIds
    /*     φΓ░ ';∩''ε╡░φ▒╜└  ''╓▄#▀╙╙└└''''~!└░╚▒*/ ) external {
    /*    ;░░  '  '~└╚²`  ',Æ▀╙.    ' ' ' '   ''!╙*/ if (!autoclaveCombine(
    /*    ░░⌐      ,∩   ,▄▒;;;┐,,.,┐,╓▄▓╗▄µ╓▄▄,,,,│*/ signature, tokenIds
    /*    ░░░.  .;ε'',▄▓╬╠╬▓▓███▓█▓█████▓╬▒┤╙╙└└└└└╠*/ )) revert InvalidMintKey();
    /*    ░░░;>^╙╣▄░#▀Γ░▒╠╠╬╣███████████▀╬╩╩∩  ^  ,╬*/ 
    /*    φ░░wµ ╙░╫█▓▄;φ▒╠╠╬███████╬▒;▐⌐╫▀. .,,;φ╠╠╠*/ uint howMany = tokenIds.length;
    /*    '░│░╣Q'¡░▓█▒╣▓▓▓╣╬██▓██▀╙╙▓╜╫▌▄"¥╢▓▒░░░░▒╠*/ for (uint i = 0; i != howMany; ++i){
    /*     Γ░▒╫▌░⌠▀╟█╬╫▓▓▓▓▓▓▓▌╙│▓ ▀▄░╠╬╬╬╣▓▓▓▄▒░░╠▒*/ _burn(tokenIds[i], true); }
    /*     ╙▌Å▀▒¡╓└╟█▒╣▓▓▀▓▓▓▀▀µ░░▓µ █▒╬╙╙▓╬╣▓▓▓░▒╠*/ 
    /*      ▓▌▄▓▄░]▓█▓╠╫▓╫▄  ╔ ╫φ▒╠╬▓φ▓▓█▓╬╬╬╬▓▓▒╠*/ uint nextTokenId = _nextTokenId();
    /*       █░▀▓▒▓░░╫█▒╣▓╬▓╗▓▓▓▓╗▓▓▓╬╬╬╬╬╠╬╬▓▓▓╬*/ _mint(msg.sender, 1);
    /*     ╓#██╬▓▓▓▓▄░╙╙▓▓▓▓▓█████▓▓█▓▓▓▓▓▓▓╬╬╣╣*/ _setExtraDataAt(nextTokenId, 1);
    /*   ╔▓▓▓█▒╠╣█╬▓█╬▒░¡╙╙▀▓▓╫╫╣╬╬╬╣╫╣╫╬╬╬╬╠╫╬*/ }
    /*  ╣▓╫▓██▌╠╝╬╬╬╬▒╠╠╠φ╦▒▒▒▒▒▒▒▒▒╠▒▒╠╬╠▒╬▓╩*/ 
    /* ▐╬╢╬╫█╩╬▀█▓▓▓▓▓▓▓▓▓▓▓▓▓▓╬╣█╬╣╫╣╬╬╫▓▀▀╙*/ 
    /*  ▓╬▓▒╬▒▄,▀▀▓▓█████▀▀╙╙╙╣▓▓╙╙╙╙╙└─ ,╗▄▄▄▓▓▓█*/
    //   ╚█▓▓╣╬▓██▓██╣╬╬▓▓▓▓▒▓╫╢╬▓▓▓▓▓█▓╣╬╬▓██████*/
    //     └╙▀▀▓█████▓╣▓███╣▓█▓╣▓██▓▓███▓█████▀▀╙*/
    //           └└╙╙╙╙╙╙╙╙╙╙╙╙╙╙└└└──


     /*                 ,▄▄Æ▓▓▓▓▓▓▓▓▌▄▄▄, */
     /*             ▄▌▓╬╬╠╩╚╚╚╙╚╙╙╙╚╚╚╚╠╬▓▌▄, */ function autoclave (
     /*          ▄██╬╚ΓΓ░░░└░░!!!!!!└└░░░Γ╙╩╬▓▄ */ bytes calldata signature,
     /*        ▄█╬╚Γ░░└:⌐".▄'^'.▄µ^'.,""":!!░╙╩╬▌µ */ MintKey calldata key
     /*      ╓█▀░░└"^'^███▄█▌''▓█ ▄████─'''"^"!░╚╬▌ */ ) public view returns (bool) {
     /*     ▄▓░░└^''''    ╙██▌ █▌█▓        '''^':└╚╣▄ */ bytes32 digest = _hashTypedDataV4(
     /*    ▄▀░⌐^''.      ╓████▄██▀▀▌▄    ,µ    '^┌'╚╫µ */ keccak256(abi.encode(
     /*   ▐╬░⌐'^^.      ▄██╫██▀░▓█████▌▓▀██     '.┌'╚█ */  MINTKEY_TYPE_HASH,
     /*   ▓░⌐'^^..     ▄█████bφ██▓╙└└▄▄▓████▄  .'''^!╠▌ */ msg.sender,
     /*  j▒░⌐~.~.    .████▓█▓▒▐██▀ :█╙└╙▓███J    ''~^φ█ */ key.free,
     /*  ▐▒░~.^~'    ████▓▓████▓▓¼Q█▄▓▀▓╫▌       ''^:░█ */ key.allowed )));
     /*   ▒░⌐.^~.    ██████┐~╙▀█▄⌐▐██▌  █─       .^.]░█ */ return ECDSA.recover(
     /*   ╬╚░.^~    µ▐█████ÿ¿ ^m╙╙└██████┬-▄⌐   .'.:░╠▌ */ digest, signature
     /*   └▒▒∩'^.'  ╙Q████▒░>  ╓''╥█▌╙███µ]▀    ''┌░▒▓ */ ) == _signer; }
     /*    ╙▒▒⌐'^.'. └▄████▌┌,Σ▌▀╙█b╙▓'╫█½╨  ..'^┌;▐▓ */
     /*     ╘▒▒░'^.~  └p▀███▄ " .██'.▀╦█▀╩  ...'┌░φ▓ */ function autoclaveCombine(
     /*      └╬▒░┌^... ╙µ└████▄╓█ ╙b╓██▀▀   ..,┌░╠╩ */ bytes calldata signature,
     /* C      ╠▒░-^... ╙µ ╙████▄;╔▓███╩ .....:φ▒▀ */ uint256[] calldata tokenIds
     /* H  S    ╚▒░⌐^... ╙µ  ╙███████▀╩  .'..:φ▄╨ */ ) public view returns (bool) {
     /* E  I     ╟▒░'┌^~' ╙µ  ^▒╙█╙└ ╩  '.,.┌░▓⌐ */ bytes32 digest = _hashTypedDataV4(
     /* C  G  M   ╠╚~\"^   ╫,,"▀¥▀,╓▌  ...,^]╠b */ keccak256(abi.encode(
     /* K  N  E   ▐░∩┌┌.~' ]█  ▄æµ █▌ . .^┌~φ▓ */ COMBINEKEY_TYPE_HASH,
     /*    E  S    ▒░:┌''~..█▄╣▄,█▄█T. '.┌┌,▐▌ */ keccak256(abi.encodePacked(tokenIds)))));
     /* E  D  S    ╟╠░\┌'^' ▐█▓╬██╣█ '..^┌:φ╣T */ return ECDSA.recover(
     /* I     A    ▀█▄▄▄▓▓▌▓▄╫╣╫▀W▓▓▌▌▄▄▌▓▓ */ digest, signature
     /* P  T  G     ╫██▓▓╬▄▄█████▌╠╫▓█████µ */ ) == _signer; }
     /* 7  Y  E     ╫▓╬╬▒Q,╓▄███▓░«╥▓█████ */
     /* 1  P  S      ████▓▒░╫████▒τ╫██████µ */
     /* 2  E         ▀████▓▒δ▓████Θ∞╫██████ */
     /*    D         ▄██▓▌╬▒Γ╫████░=╠██████ */
     /*              ███▓╣æs╣████G-╜██▓███⌐ */
     /*              ╙███▓▀╨╙╫████L.╠██▓██▓ */
     /*               ╙██▓▓▌▒▒╬╬╬╬╣╣▓▓▓███╙ */
     /*                 ╙▀███▓▓▓▓▓▄▓███▀─ */
     /*                    ╙████████▀╙ */
     /*                       ╙▀▀▀─ */


     /*                    .⌐≈*/
     /*      ,⌐"^ⁿ   ┌¬*  ┘    */ function setDefaultRoyalty(
     /*    ,.▌    j  ▐   ▐   ,═\``*/ address receiver, uint96 points
     /* ε`    ]──,╨¬}J   ⌐¬'\     */ ) external onlyOwner {
     /* └ç   j    ─  {┴∞*,  ,Γ```▀*/  _setDefaultRoyalty(receiver, points);
     /*   '7T─ⁿ╗-╫-─└│   ,▌─     */  _receiver = receiver; }
     /*   ┘    ▌  ╞Y `─ ƒ ⌐ \  ,*/ 
     /*  ╘  .─└└.,╛ \    */  function startNextSession() onlyOwner external {
     /*                  */   session++; }
     /*              Γ   */    
     /*  A           ▐   */   function withdraw() public payable {(bool success, ) = payable(
     /*  D            µ  */    _receiver).call{value: address(this).balance}("");
     /*  M          ,,╞ , */    require(success); }
     /*  I         ⌐   p⌡  */   
     /*  N         ▌¬¬¬╧▌¬¬`*/   function tattooReveal(string memory newBaseURI
     /*                 ▌    */  ) public onlyOwner { 
     /*           ┘    j ─   */   baseURI = newBaseURI; }
     /*           ─    ▐ ╘    */  
     /*          ⌠     ╞  µ   */   function eject() public onlyOwner {
     /*          b     │  Γ    */  if (blackRemaining() > 0) {
     /*         j      │  ╞    */   if (blackRemaining() > 250) { _mint(_TEAM, 250); }
     /*         ╞      │  ▐     */   else { _mint(_TEAM, blackRemaining()); }}
     /*         ▐      │  j     */    if(goldRemaining() > 0) {
     /*         j      Γ        */     uint _goldRemaining = goldRemaining();
     /*          ─     ═   ⌐     */    _goldMinted += _goldRemaining;
     /*          ▌    j    \     */    uint nextTokenId = _nextTokenId();
     /*          ╘    ▐     p   */    _mint(_TEAM, _goldRemaining);
     /*           \            ,*/   _setExtraDataAt(nextTokenId, 1); }}
     /*            \         ,*/    
     /*            '"¬───¬`'*/     function pauseSwitch() public onlyOwner { paused = !paused; }


    /*         ,▄████████▌╥ */
    /* H     ╓██████████████▄ */ function goldRemaining() public view returns (uint256) {
    /* E    ╣█████▓▓╣▓▓▓█████▌ */ return _maxGoldSupply - _goldMinted; }
    /* L   ╠▓▓███╬╣Å▒▒╠▌▌███▓▓▌ */
    /* P   ▌▓▓██████▓▓███████▓╬⌐ */ function blackRemaining() public view returns (uint256) {
    /* E  j╟╬▓▒ë⌂╕,    ,«TêÉ╫╫╠▌ */  return _maxSupply - totalSupply() - goldRemaining(); }
    /* R  ▐╠╬██▓▀╝▓╬  ╠▓▀╩╫██╣╠▌ */ 
    /* S  ▐╚╠▓╬▀Θ²╙└░,┘╙"²▀╬█╠▒▌ */ function goldPrice() public view returns (uint256) {
    /*    ▐╠╬╬╬ε   ç▒φ░   ,╣╣╠╠▌ */  if(session > 1) return SESSION_TWO_GOLD_PRICE;
    /*    ▐╣╬█'░░  ╙▀▀╙  ;░└█╣╬▌ */  return SESSION_ONE_GOLD_PRICE; }
    /*    ▐▓▓██, *Φ▓▓▓▓▀═  ▓█▓▓▌ */ 
    /*    ▐█████▄  ╙╙╙╙  ▄▓████▌ */ function blackPrice() public view returns (uint256) {
    /*    ▐████▌░╙▒╦╥╥╦#▀└╙████▌ */  if(session > 1) return SESSION_TWO_BLACK_PRICE;
    /*    ▓████░    └^    φ█████ */  return SESSION_ONE_BLACK_PRICE; }
    /*  æΦ█▀▓Q╩╞¼        6╡╝b╬▀▀▀╥ */
    /*  ╫,¥╬Åσ▐÷Γ¼¬    ⌐¥▐}Γ}Å╬Mç╝ */ function mintInfo() public view returns (
    /*   ╟-╚▄j¼m╔╛,`  "┐└æbMΓ▄╩-╢ */   uint256, uint256, uint256, uint256, uint256) { 
    /*    ²,╙▒░╥,"⌐  ¬ ."g╓│#▒.ó */   return (
    /*      X VÜε)  ⌐¬  τ,ÜΓ Æ */    goldRemaining(), blackRemaining(), 
    /*        *,`╚▄╠▒b╠▄Å^,<─ */     goldPrice(), blackPrice(), session
    /*          '╙qµ   µ╜` */      );}
    //
    


    /*               ▐ */
    /*               ▐▄ */
    /*               ▐µ */
    /*               ╫ */
    /*               █              ,..--.., */
    /*               █       ,æOΓ┘¬```` ¬~    `- */
    /*               █   ,▄▀╨                 `  . */
    /*               █ ▄▓▀       ▄▄▄             `, */
    /*               █▀▀  A└⌐     ███████▄        ╫▌ */
    /*          ¬  - ╚  ,╙ ╫      └▀███████       ██▄ */
    /*       '         Æ  ╒        ▄███████▓▄    ███▌ */
    /*      ⌐     , ' ╩   ╜  ' ,  '▓█████████▓ ╓████ */
    /*     Γ  ,-⌐ÆΓ▌╓╨   ▐ /    .φ▄██████████╓█████ */
    /*      ⌂   ╜ ▐▄┐. ''└  »[╓φÄ╠███████████████╙ */
    /*    ╫╚  ,╛  ┘     ..╓▄▄φ╠╣╬█▓████████████╙  */
    /*    ╚⌐  └:. '     ╥▄██████████████████▀─   */
    /*   '    .,»ⁿ~ƒ ╫█████████████████╝╩╩▀▀█▀  */
    /*    ▌ -/Ç ''.⌐~▐████████████╫████▓█ ⌐ ╞" */  function _startTokenId() internal pure override returns (uint256) {
    /*    ╟  '"²,.∩,╓▓████████████╬▓╬█████   */     return 1; }
    /*     µ    ┌∩░-█████████████▓▓███▓ ╠█  */
    /*     ╙╙▀▀█▄;»██████████▓▓█▌╬███▄▌ │ */  function _extraData(
    /*     ─█▄▀▀█▄░█▓▓▓█▓▓╬╬╢╬▒╟█╬███▄   */    address, address, uint24 previousExtraData
    /*       .,φ╚█░░╙╚┤░≤√≥░░Γ╚╫█▓████▀ */    ) internal pure override returns (uint24) {
    /*       ]▒φΓ█≥░▄▄▄>░7²⌠░φ╠▓██████ */       return previousExtraData;}
    /*       `╙╚▒╬▀█▀╨╛⌐»"'░░▒╬██████▌ */ 
    /*          └╟▒▓█▓▓▓▀Ü░φ▒╬█████▐█Γ */  function supportsInterface(bytes4 interfaceId
    /*         ,. ╬▀▌▓█▒░φ╠╬██████ └▀  */   ) public view virtual override(IERC721A, ERC721A, ERC2981) returns (bool) {
    /*          \   ╓▄╫╣╣▓████████    */     return ERC721A.supportsInterface(interfaceId) ||
    /*  O       ~²▄██████▀▀╙╙█▄██▌ ╓  */      ERC2981.supportsInterface(interfaceId);}
    /*  V         ╙╙└         ▐██▌ █  */
    /*  E          ^          ╫███ █µ */  function explicitOwnershipsOfAll(
    /*  R                     ████ █▌ */   ) external view returns (TokenOwnership[] memory) {
    /*  R                     ████ █▌ */    unchecked {
    /*  I                     ████ █▌ */     uint256 tokenIdsLength = _nextTokenId()+_startTokenId();
    /*  D                     ████ █▌ */     TokenOwnership[] memory ownerships = new TokenOwnership[](tokenIdsLength);
    /*  E                     ╟██  █▓ */     for (uint256 i=_startTokenId(); i != tokenIdsLength; ++i) {
    /*  S                      ██  █╣ */       ownerships[i] = explicitOwnershipOf(i); }
    /*                         ██ b█▓ */     return ownerships; }}
    /*                         ██ ▄╫▌ */
    /*                         ╟█ ┼╫▌ */  function getAux(address _owner) external view returns (uint64) {
    /*                          █µ▐╚█ */    return _getAux(_owner); }
    /*                         j█ j│█ */
    /*                          █⌐j▐█ */  function _baseURI() internal view override returns (string memory) {
    /*                          █▌j╫█ */    return baseURI; }
    /*                                */ 



        
    //* */f u n c t i o n noRagrets(,▄▄▓██████▄▄╖
    //* */fu n c ti on noRagrets(╓█████████████████▌,
    //* */fun ctio n noRagrets(╓██████████████████████
    //* */function  noRagrets(Æ████████████████████████▄
    //* */function noRagrets(]████████████████████████████▄╖
    //* */function noRagrets(║███████████████╣▓█████╣████████µ
    //* */function noRagrets(╘███████████▓█▀▀▀    `╙▀██╣██████µ
    //* */function  noRagrets(║████████▓▀¬"²t    -ε≤o═╩██╣█████
    //* */function  noRagrets( ███████▌  ──. '          ╙███████
    //* */fun ctio n  noRagrets(╙████▀ ^⌐▀▀╛      ¬▀█.>   █▓▓████
    //* */fu n c ti on  noRagrets(╙█▌     ╘    `.          ▓▓████b
    //* */fu n c t i o n noRagrets(       <"""≥.           ╙▓╣███
    //* */fu n c t i on  noRagrets(╒     Φ≡╦╦╦╦╣ⁿ▄        '  ▓██▀
    /** */function/* */noRagrets(//(▀      ,,                 ║▌
    //* */f u n c t i o n  noRagrets(L                     , ^
    /** */uint256/*** ***/tokenId//(╬█   `-,              /`╖▄æ
    //* */f u n c ti o n noRagrets(@╬╬╔    :   |-  ∩╓]   ▄| Æ║╬╣╬µ
    /** */)/** **/public/** **/{//█╬╬╣▓⌐ ▐             »'   ██╬╬╬╣
    //* */ function noRagrets(//Æ╠╬╬╣                     ╬╬╬╬╬╬█
    /** */_burn(    //_burn( //,▓╬╬╬╬╣                    ╓╠╬╬╬╬╬╬
    //* */function noRagrets(╬█╬╬╬╬╬╬╣                   {▌╬╬╬╬╬╬╬█
    /** */tokenId,/** ***///█▀╓█╬╬╬╣╬█                   ▓ ╙█╬╬╬╬╬╬█
    //* */function noRagrets(█╬╬╬╣█▀ ▐                   ╙▄  ╘██╬╬╬╠█
    /** */true);}/* *///╓Æ█╠╬╬╬╬▀ ╞                       ╙█ ╪ ▐ ╙▀╬╠█╖
    //* *//**//**/╖▓╬╬╬█▀║ ║╬▀ ╛  Ç                        ╢█▄│     ▀█╬█▌▄
    //* *//**/╓Æ█╬╬╬▀    ∩╒█  ╒   ╚                     ,t^   ╚▀▄      ╙▀▓╬█╖
    //* */ ╓██▓███▀     ƒ╒█   ∩     k▄              ,▄─'      │    ▐       ╙▀█▄
    //* */  É  Æ       ,╓█   j        `▀º─▄▄-─╖J▀^            ⌐    ╞           ▀▄
    //* */ │          ┌{▀    ▐                                     Γ             ▀─
    //* */┌        .─⌐▀K*    ▐     𝕹𝕺𝕺𝕽𝕽𝔄𝕲    𝕲𝕽𝕰𝕰𝔗𝔗𝕾   ▐     ▌              "
    //* */╛   ,⌐ >   .≈*-          𝓝 𝓞 𝓡 𝓐 𝓖 𝓡 𝓔 𝓣 𝓢    [  ,▄,⌐                p
    //* */⌠ ,⌐     -     . ,╖.╘          𝕹𝕺𝕽𝔄𝕲𝕽𝕰𝔗𝕾        /▀^╙▄   `w
    //* */└~ⁿⁿⁿ~^└~╜ⁿ²  ─└~ⁿ╜ └ⁿⁿⁿⁿⁿⁿⁿⁿⁿⁿⁿ²²²²²ⁿⁿⁿ~~~²~~~~~ ┴~~~┴┴~~~~╙┴~~~~~~~~~~~~╜      


    // Below are some overrides required by OpenSea's Operator Filter Registry

    /**
     * @dev See {IERC721-setApprovalForAll}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function setApprovalForAll(address operator, bool approved) public override(ERC721A, IERC721A) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    /**
     * @dev See {IERC721-approve}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function approve(address operator, uint256 tokenId) public override(ERC721A, IERC721A) onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    /**
     * @dev See {IERC721-transferFrom}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function transferFrom(address from, address to, uint256 tokenId) public override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override(ERC721A, IERC721A)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    /**
     * @dev See {Ownable-owner}.
     *      Thanks, OpenSea
     */
    function owner() public view override(Ownable, UpdatableOperatorFilterer) returns(address) {
      return super.owner();
    }

}

//
// Congratulations, you made it to the end of the Smart Contract! 
// Go mint a fork and feed someone in New Orleans: https://forkhunger.art
//

// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.2.2
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import "IERC721AQueryable.sol";
import "ERC721A.sol";

/**
 * @title ERC721AQueryable.
 *
 * @dev ERC721A subclass with convenience query functions.
 */
abstract contract ERC721AQueryable is ERC721A, IERC721AQueryable {
    /**
     * @dev Returns the `TokenOwnership` struct at `tokenId` without reverting.
     *
     * If the `tokenId` is out of bounds:
     *
     * - `addr = address(0)`
     * - `startTimestamp = 0`
     * - `burned = false`
     * - `extraData = 0`
     *
     * If the `tokenId` is burned:
     *
     * - `addr = <Address of owner before token was burned>`
     * - `startTimestamp = <Timestamp when token was burned>`
     * - `burned = true`
     * - `extraData = <Extra data when token was burned>`
     *
     * Otherwise:
     *
     * - `addr = <Address of owner>`
     * - `startTimestamp = <Timestamp of start of ownership>`
     * - `burned = false`
     * - `extraData = <Extra data at start of ownership>`
     */
    function explicitOwnershipOf(uint256 tokenId) public view virtual override returns (TokenOwnership memory) {
        TokenOwnership memory ownership;
        if (tokenId < _startTokenId() || tokenId >= _nextTokenId()) {
            return ownership;
        }
        ownership = _ownershipAt(tokenId);
        if (ownership.burned) {
            return ownership;
        }
        return _ownershipOf(tokenId);
    }

    /**
     * @dev Returns an array of `TokenOwnership` structs at `tokenIds` in order.
     * See {ERC721AQueryable-explicitOwnershipOf}
     */
    function explicitOwnershipsOf(uint256[] calldata tokenIds)
        external
        view
        virtual
        override
        returns (TokenOwnership[] memory)
    {
        unchecked {
            uint256 tokenIdsLength = tokenIds.length;
            TokenOwnership[] memory ownerships = new TokenOwnership[](tokenIdsLength);
            for (uint256 i; i != tokenIdsLength; ++i) {
                ownerships[i] = explicitOwnershipOf(tokenIds[i]);
            }
            return ownerships;
        }
    }

    /**
     * @dev Returns an array of token IDs owned by `owner`,
     * in the range [`start`, `stop`)
     * (i.e. `start <= tokenId < stop`).
     *
     * This function allows for tokens to be queried if the collection
     * grows too big for a single call of {ERC721AQueryable-tokensOfOwner}.
     *
     * Requirements:
     *
     * - `start < stop`
     */
    function tokensOfOwnerIn(
        address owner,
        uint256 start,
        uint256 stop
    ) external view virtual override returns (uint256[] memory) {
        unchecked {
            if (start >= stop) revert InvalidQueryRange();
            uint256 tokenIdsIdx;
            uint256 stopLimit = _nextTokenId();
            // Set `start = max(start, _startTokenId())`.
            if (start < _startTokenId()) {
                start = _startTokenId();
            }
            // Set `stop = min(stop, stopLimit)`.
            if (stop > stopLimit) {
                stop = stopLimit;
            }
            uint256 tokenIdsMaxLength = balanceOf(owner);
            // Set `tokenIdsMaxLength = min(balanceOf(owner), stop - start)`,
            // to cater for cases where `balanceOf(owner)` is too big.
            if (start < stop) {
                uint256 rangeLength = stop - start;
                if (rangeLength < tokenIdsMaxLength) {
                    tokenIdsMaxLength = rangeLength;
                }
            } else {
                tokenIdsMaxLength = 0;
            }
            uint256[] memory tokenIds = new uint256[](tokenIdsMaxLength);
            if (tokenIdsMaxLength == 0) {
                return tokenIds;
            }
            // We need to call `explicitOwnershipOf(start)`,
            // because the slot at `start` may not be initialized.
            TokenOwnership memory ownership = explicitOwnershipOf(start);
            address currOwnershipAddr;
            // If the starting slot exists (i.e. not burned), initialize `currOwnershipAddr`.
            // `ownership.address` will not be zero, as `start` is clamped to the valid token ID range.
            if (!ownership.burned) {
                currOwnershipAddr = ownership.addr;
            }
            for (uint256 i = start; i != stop && tokenIdsIdx != tokenIdsMaxLength; ++i) {
                ownership = _ownershipAt(i);
                if (ownership.burned) {
                    continue;
                }
                if (ownership.addr != address(0)) {
                    currOwnershipAddr = ownership.addr;
                }
                if (currOwnershipAddr == owner) {
                    tokenIds[tokenIdsIdx++] = i;
                }
            }
            // Downsize the array to fit.
            assembly {
                mstore(tokenIds, tokenIdsIdx)
            }
            return tokenIds;
        }
    }

    /**
     * @dev Returns an array of token IDs owned by `owner`.
     *
     * This function scans the ownership mapping and is O(`totalSupply`) in complexity.
     * It is meant to be called off-chain.
     *
     * See {ERC721AQueryable-tokensOfOwnerIn} for splitting the scan into
     * multiple smaller scans if the collection is large enough to cause
     * an out-of-gas error (10K collections should be fine).
     */
    function tokensOfOwner(address owner) external view virtual override returns (uint256[] memory) {
        unchecked {
            uint256 tokenIdsIdx;
            address currOwnershipAddr;
            uint256 tokenIdsLength = balanceOf(owner);
            uint256[] memory tokenIds = new uint256[](tokenIdsLength);
            TokenOwnership memory ownership;
            for (uint256 i = _startTokenId(); tokenIdsIdx != tokenIdsLength; ++i) {
                ownership = _ownershipAt(i);
                if (ownership.burned) {
                    continue;
                }
                if (ownership.addr != address(0)) {
                    currOwnershipAddr = ownership.addr;
                }
                if (currOwnershipAddr == owner) {
                    tokenIds[tokenIdsIdx++] = i;
                }
            }
            return tokenIds;
        }
    }
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.2.2
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import "IERC721A.sol";

/**
 * @dev Interface of ERC721AQueryable.
 */
interface IERC721AQueryable is IERC721A {
    /**
     * Invalid query range (`start` >= `stop`).
     */
    error InvalidQueryRange();

    /**
     * @dev Returns the `TokenOwnership` struct at `tokenId` without reverting.
     *
     * If the `tokenId` is out of bounds:
     *
     * - `addr = address(0)`
     * - `startTimestamp = 0`
     * - `burned = false`
     * - `extraData = 0`
     *
     * If the `tokenId` is burned:
     *
     * - `addr = <Address of owner before token was burned>`
     * - `startTimestamp = <Timestamp when token was burned>`
     * - `burned = true`
     * - `extraData = <Extra data when token was burned>`
     *
     * Otherwise:
     *
     * - `addr = <Address of owner>`
     * - `startTimestamp = <Timestamp of start of ownership>`
     * - `burned = false`
     * - `extraData = <Extra data at start of ownership>`
     */
    function explicitOwnershipOf(uint256 tokenId) external view returns (TokenOwnership memory);

    /**
     * @dev Returns an array of `TokenOwnership` structs at `tokenIds` in order.
     * See {ERC721AQueryable-explicitOwnershipOf}
     */
    function explicitOwnershipsOf(uint256[] memory tokenIds) external view returns (TokenOwnership[] memory);

    /**
     * @dev Returns an array of token IDs owned by `owner`,
     * in the range [`start`, `stop`)
     * (i.e. `start <= tokenId < stop`).
     *
     * This function allows for tokens to be queried if the collection
     * grows too big for a single call of {ERC721AQueryable-tokensOfOwner}.
     *
     * Requirements:
     *
     * - `start < stop`
     */
    function tokensOfOwnerIn(
        address owner,
        uint256 start,
        uint256 stop
    ) external view returns (uint256[] memory);

    /**
     * @dev Returns an array of token IDs owned by `owner`.
     *
     * This function scans the ownership mapping and is O(`totalSupply`) in complexity.
     * It is meant to be called off-chain.
     *
     * See {ERC721AQueryable-tokensOfOwnerIn} for splitting the scan into
     * multiple smaller scans if the collection is large enough to cause
     * an out-of-gas error (10K collections should be fine).
     */
    function tokensOfOwner(address owner) external view returns (uint256[] memory);
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.2.2
// Creator: Chiru Labs

pragma solidity ^0.8.4;

/**
 * @dev Interface of ERC721A.
 */
interface IERC721A {
    /**
     * The caller must own the token or be an approved operator.
     */
    error ApprovalCallerNotOwnerNorApproved();

    /**
     * The token does not exist.
     */
    error ApprovalQueryForNonexistentToken();

    /**
     * The caller cannot approve to their own address.
     */
    error ApproveToCaller();

    /**
     * Cannot query the balance for the zero address.
     */
    error BalanceQueryForZeroAddress();

    /**
     * Cannot mint to the zero address.
     */
    error MintToZeroAddress();

    /**
     * The quantity of tokens minted must be more than zero.
     */
    error MintZeroQuantity();

    /**
     * The token does not exist.
     */
    error OwnerQueryForNonexistentToken();

    /**
     * The caller must own the token or be an approved operator.
     */
    error TransferCallerNotOwnerNorApproved();

    /**
     * The token must be owned by `from`.
     */
    error TransferFromIncorrectOwner();

    /**
     * Cannot safely transfer to a contract that does not implement the
     * ERC721Receiver interface.
     */
    error TransferToNonERC721ReceiverImplementer();

    /**
     * Cannot transfer to the zero address.
     */
    error TransferToZeroAddress();

    /**
     * The token does not exist.
     */
    error URIQueryForNonexistentToken();

    /**
     * The `quantity` minted with ERC2309 exceeds the safety limit.
     */
    error MintERC2309QuantityExceedsLimit();

    /**
     * The `extraData` cannot be set on an unintialized ownership slot.
     */
    error OwnershipNotInitializedForExtraData();

    // =============================================================
    //                            STRUCTS
    // =============================================================

    struct TokenOwnership {
        // The address of the owner.
        address addr;
        // Stores the start time of ownership with minimal overhead for tokenomics.
        uint64 startTimestamp;
        // Whether the token has been burned.
        bool burned;
        // Arbitrary data similar to `startTimestamp` that can be set via {_extraData}.
        uint24 extraData;
    }

    // =============================================================
    //                         TOKEN COUNTERS
    // =============================================================

    /**
     * @dev Returns the total number of tokens in existence.
     * Burned tokens will reduce the count.
     * To get the total number of tokens minted, please see {_totalMinted}.
     */
    function totalSupply() external view returns (uint256);

    // =============================================================
    //                            IERC165
    // =============================================================

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * [EIP section](https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified)
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    // =============================================================
    //                            IERC721
    // =============================================================

    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables
     * (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in `owner`'s account.
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
     * @dev Safely transfers `tokenId` token from `from` to `to`,
     * checking first that contract recipients are aware of the ERC721 protocol
     * to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move
     * this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement
     * {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
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
     * @dev Equivalent to `safeTransferFrom(from, to, tokenId, '')`.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom}
     * whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token
     * by either {approve} or {setApprovalForAll}.
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
     * Only a single account can be approved at a time, so approving the
     * zero address clears previous approvals.
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
     * Operators can call {transferFrom} or {safeTransferFrom}
     * for any token owned by the caller.
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
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    // =============================================================
    //                        IERC721Metadata
    // =============================================================

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

    // =============================================================
    //                           IERC2309
    // =============================================================

    /**
     * @dev Emitted when tokens in `fromTokenId` to `toTokenId`
     * (inclusive) is transferred from `from` to `to`, as defined in the
     * [ERC2309](https://eips.ethereum.org/EIPS/eip-2309) standard.
     *
     * See {_mintERC2309} for more details.
     */
    event ConsecutiveTransfer(uint256 indexed fromTokenId, uint256 toTokenId, address indexed from, address indexed to);
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.2.2
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import "IERC721A.sol";

/**
 * @dev Interface of ERC721 token receiver.
 */
interface ERC721A__IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

/**
 * @title ERC721A
 *
 * @dev Implementation of the [ERC721](https://eips.ethereum.org/EIPS/eip-721)
 * Non-Fungible Token Standard, including the Metadata extension.
 * Optimized for lower gas during batch mints.
 *
 * Token IDs are minted in sequential order (e.g. 0, 1, 2, 3, ...)
 * starting from `_startTokenId()`.
 *
 * Assumptions:
 *
 * - An owner cannot have more than 2**64 - 1 (max value of uint64) of supply.
 * - The maximum token ID cannot exceed 2**256 - 1 (max value of uint256).
 */
contract ERC721A is IERC721A {
    // Reference type for token approval.
    struct TokenApprovalRef {
        address value;
    }

    // =============================================================
    //                           CONSTANTS
    // =============================================================

    // Mask of an entry in packed address data.
    uint256 private constant _BITMASK_ADDRESS_DATA_ENTRY = (1 << 64) - 1;

    // The bit position of `numberMinted` in packed address data.
    uint256 private constant _BITPOS_NUMBER_MINTED = 64;

    // The bit position of `numberBurned` in packed address data.
    uint256 private constant _BITPOS_NUMBER_BURNED = 128;

    // The bit position of `aux` in packed address data.
    uint256 private constant _BITPOS_AUX = 192;

    // Mask of all 256 bits in packed address data except the 64 bits for `aux`.
    uint256 private constant _BITMASK_AUX_COMPLEMENT = (1 << 192) - 1;

    // The bit position of `startTimestamp` in packed ownership.
    uint256 private constant _BITPOS_START_TIMESTAMP = 160;

    // The bit mask of the `burned` bit in packed ownership.
    uint256 private constant _BITMASK_BURNED = 1 << 224;

    // The bit position of the `nextInitialized` bit in packed ownership.
    uint256 private constant _BITPOS_NEXT_INITIALIZED = 225;

    // The bit mask of the `nextInitialized` bit in packed ownership.
    uint256 private constant _BITMASK_NEXT_INITIALIZED = 1 << 225;

    // The bit position of `extraData` in packed ownership.
    uint256 private constant _BITPOS_EXTRA_DATA = 232;

    // Mask of all 256 bits in a packed ownership except the 24 bits for `extraData`.
    uint256 private constant _BITMASK_EXTRA_DATA_COMPLEMENT = (1 << 232) - 1;

    // The mask of the lower 160 bits for addresses.
    uint256 private constant _BITMASK_ADDRESS = (1 << 160) - 1;

    // The maximum `quantity` that can be minted with {_mintERC2309}.
    // This limit is to prevent overflows on the address data entries.
    // For a limit of 5000, a total of 3.689e15 calls to {_mintERC2309}
    // is required to cause an overflow, which is unrealistic.
    uint256 private constant _MAX_MINT_ERC2309_QUANTITY_LIMIT = 5000;

    // The `Transfer` event signature is given by:
    // `keccak256(bytes("Transfer(address,address,uint256)"))`.
    bytes32 private constant _TRANSFER_EVENT_SIGNATURE =
        0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef;

    // =============================================================
    //                            STORAGE
    // =============================================================

    // The next token ID to be minted.
    uint256 private _currentIndex;

    // The number of tokens burned.
    uint256 private _burnCounter;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to ownership details
    // An empty struct value does not necessarily mean the token is unowned.
    // See {_packedOwnershipOf} implementation for details.
    //
    // Bits Layout:
    // - [0..159]   `addr`
    // - [160..223] `startTimestamp`
    // - [224]      `burned`
    // - [225]      `nextInitialized`
    // - [232..255] `extraData`
    mapping(uint256 => uint256) private _packedOwnerships;

    // Mapping owner address to address data.
    //
    // Bits Layout:
    // - [0..63]    `balance`
    // - [64..127]  `numberMinted`
    // - [128..191] `numberBurned`
    // - [192..255] `aux`
    mapping(address => uint256) private _packedAddressData;

    // Mapping from token ID to approved address.
    mapping(uint256 => TokenApprovalRef) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // =============================================================
    //                          CONSTRUCTOR
    // =============================================================

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _currentIndex = _startTokenId();
    }

    // =============================================================
    //                   TOKEN COUNTING OPERATIONS
    // =============================================================

    /**
     * @dev Returns the starting token ID.
     * To change the starting token ID, please override this function.
     */
    function _startTokenId() internal view virtual returns (uint256) {
        return 0;
    }

    /**
     * @dev Returns the next token ID to be minted.
     */
    function _nextTokenId() internal view virtual returns (uint256) {
        return _currentIndex;
    }

    /**
     * @dev Returns the total number of tokens in existence.
     * Burned tokens will reduce the count.
     * To get the total number of tokens minted, please see {_totalMinted}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        // Counter underflow is impossible as _burnCounter cannot be incremented
        // more than `_currentIndex - _startTokenId()` times.
        unchecked {
            return _currentIndex - _burnCounter - _startTokenId();
        }
    }

    /**
     * @dev Returns the total amount of tokens minted in the contract.
     */
    function _totalMinted() internal view virtual returns (uint256) {
        // Counter underflow is impossible as `_currentIndex` does not decrement,
        // and it is initialized to `_startTokenId()`.
        unchecked {
            return _currentIndex - _startTokenId();
        }
    }

    /**
     * @dev Returns the total number of tokens burned.
     */
    function _totalBurned() internal view virtual returns (uint256) {
        return _burnCounter;
    }

    // =============================================================
    //                    ADDRESS DATA OPERATIONS
    // =============================================================

    /**
     * @dev Returns the number of tokens in `owner`'s account.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        if (owner == address(0)) revert BalanceQueryForZeroAddress();
        return _packedAddressData[owner] & _BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the number of tokens minted by `owner`.
     */
    function _numberMinted(address owner) internal view returns (uint256) {
        return (_packedAddressData[owner] >> _BITPOS_NUMBER_MINTED) & _BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the number of tokens burned by or on behalf of `owner`.
     */
    function _numberBurned(address owner) internal view returns (uint256) {
        return (_packedAddressData[owner] >> _BITPOS_NUMBER_BURNED) & _BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the auxiliary data for `owner`. (e.g. number of whitelist mint slots used).
     */
    function _getAux(address owner) internal view returns (uint64) {
        return uint64(_packedAddressData[owner] >> _BITPOS_AUX);
    }

    /**
     * Sets the auxiliary data for `owner`. (e.g. number of whitelist mint slots used).
     * If there are multiple variables, please pack them into a uint64.
     */
    function _setAux(address owner, uint64 aux) internal virtual {
        uint256 packed = _packedAddressData[owner];
        uint256 auxCasted;
        // Cast `aux` with assembly to avoid redundant masking.
        assembly {
            auxCasted := aux
        }
        packed = (packed & _BITMASK_AUX_COMPLEMENT) | (auxCasted << _BITPOS_AUX);
        _packedAddressData[owner] = packed;
    }

    // =============================================================
    //                            IERC165
    // =============================================================

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * [EIP section](https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified)
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30000 gas.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        // The interface IDs are constants representing the first 4 bytes
        // of the XOR of all function selectors in the interface.
        // See: [ERC165](https://eips.ethereum.org/EIPS/eip-165)
        // (e.g. `bytes4(i.functionA.selector ^ i.functionB.selector ^ ...)`)
        return
            interfaceId == 0x01ffc9a7 || // ERC165 interface ID for ERC165.
            interfaceId == 0x80ac58cd || // ERC165 interface ID for ERC721.
            interfaceId == 0x5b5e139f; // ERC165 interface ID for ERC721Metadata.
    }

    // =============================================================
    //                        IERC721Metadata
    // =============================================================

    /**
     * @dev Returns the token collection name.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId))) : '';
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, it can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return '';
    }

    // =============================================================
    //                     OWNERSHIPS OPERATIONS
    // =============================================================

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        return address(uint160(_packedOwnershipOf(tokenId)));
    }

    /**
     * @dev Gas spent here starts off proportional to the maximum mint batch size.
     * It gradually moves to O(1) as tokens get transferred around over time.
     */
    function _ownershipOf(uint256 tokenId) internal view virtual returns (TokenOwnership memory) {
        return _unpackedOwnership(_packedOwnershipOf(tokenId));
    }

    /**
     * @dev Returns the unpacked `TokenOwnership` struct at `index`.
     */
    function _ownershipAt(uint256 index) internal view virtual returns (TokenOwnership memory) {
        return _unpackedOwnership(_packedOwnerships[index]);
    }

    /**
     * @dev Initializes the ownership slot minted at `index` for efficiency purposes.
     */
    function _initializeOwnershipAt(uint256 index) internal virtual {
        if (_packedOwnerships[index] == 0) {
            _packedOwnerships[index] = _packedOwnershipOf(index);
        }
    }

    /**
     * Returns the packed ownership data of `tokenId`.
     */
    function _packedOwnershipOf(uint256 tokenId) private view returns (uint256) {
        uint256 curr = tokenId;

        unchecked {
            if (_startTokenId() <= curr)
                if (curr < _currentIndex) {
                    uint256 packed = _packedOwnerships[curr];
                    // If not burned.
                    if (packed & _BITMASK_BURNED == 0) {
                        // Invariant:
                        // There will always be an initialized ownership slot
                        // (i.e. `ownership.addr != address(0) && ownership.burned == false`)
                        // before an unintialized ownership slot
                        // (i.e. `ownership.addr == address(0) && ownership.burned == false`)
                        // Hence, `curr` will not underflow.
                        //
                        // We can directly compare the packed value.
                        // If the address is zero, packed will be zero.
                        while (packed == 0) {
                            packed = _packedOwnerships[--curr];
                        }
                        return packed;
                    }
                }
        }
        revert OwnerQueryForNonexistentToken();
    }

    /**
     * @dev Returns the unpacked `TokenOwnership` struct from `packed`.
     */
    function _unpackedOwnership(uint256 packed) private pure returns (TokenOwnership memory ownership) {
        ownership.addr = address(uint160(packed));
        ownership.startTimestamp = uint64(packed >> _BITPOS_START_TIMESTAMP);
        ownership.burned = packed & _BITMASK_BURNED != 0;
        ownership.extraData = uint24(packed >> _BITPOS_EXTRA_DATA);
    }

    /**
     * @dev Packs ownership data into a single uint256.
     */
    function _packOwnershipData(address owner, uint256 flags) private view returns (uint256 result) {
        assembly {
            // Mask `owner` to the lower 160 bits, in case the upper bits somehow aren't clean.
            owner := and(owner, _BITMASK_ADDRESS)
            // `owner | (block.timestamp << _BITPOS_START_TIMESTAMP) | flags`.
            result := or(owner, or(shl(_BITPOS_START_TIMESTAMP, timestamp()), flags))
        }
    }

    /**
     * @dev Returns the `nextInitialized` flag set if `quantity` equals 1.
     */
    function _nextInitializedFlag(uint256 quantity) private pure returns (uint256 result) {
        // For branchless setting of the `nextInitialized` flag.
        assembly {
            // `(quantity == 1) << _BITPOS_NEXT_INITIALIZED`.
            result := shl(_BITPOS_NEXT_INITIALIZED, eq(quantity, 1))
        }
    }

    // =============================================================
    //                      APPROVAL OPERATIONS
    // =============================================================

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the
     * zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ownerOf(tokenId);

        if (_msgSenderERC721A() != owner)
            if (!isApprovedForAll(owner, _msgSenderERC721A())) {
                revert ApprovalCallerNotOwnerNorApproved();
            }

        _tokenApprovals[tokenId].value = to;
        emit Approval(owner, to, tokenId);
    }

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        if (!_exists(tokenId)) revert ApprovalQueryForNonexistentToken();

        return _tokenApprovals[tokenId].value;
    }

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom}
     * for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        if (operator == _msgSenderERC721A()) revert ApproveToCaller();

        _operatorApprovals[_msgSenderERC721A()][operator] = approved;
        emit ApprovalForAll(_msgSenderERC721A(), operator, approved);
    }

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted. See {_mint}.
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return
            _startTokenId() <= tokenId &&
            tokenId < _currentIndex && // If within bounds,
            _packedOwnerships[tokenId] & _BITMASK_BURNED == 0; // and not burned.
    }

    /**
     * @dev Returns whether `msgSender` is equal to `approvedAddress` or `owner`.
     */
    function _isSenderApprovedOrOwner(
        address approvedAddress,
        address owner,
        address msgSender
    ) private pure returns (bool result) {
        assembly {
            // Mask `owner` to the lower 160 bits, in case the upper bits somehow aren't clean.
            owner := and(owner, _BITMASK_ADDRESS)
            // Mask `msgSender` to the lower 160 bits, in case the upper bits somehow aren't clean.
            msgSender := and(msgSender, _BITMASK_ADDRESS)
            // `msgSender == owner || msgSender == approvedAddress`.
            result := or(eq(msgSender, owner), eq(msgSender, approvedAddress))
        }
    }

    /**
     * @dev Returns the storage slot and value for the approved address of `tokenId`.
     */
    function _getApprovedSlotAndAddress(uint256 tokenId)
        private
        view
        returns (uint256 approvedAddressSlot, address approvedAddress)
    {
        TokenApprovalRef storage tokenApproval = _tokenApprovals[tokenId];
        // The following is equivalent to `approvedAddress = _tokenApprovals[tokenId]`.
        assembly {
            approvedAddressSlot := tokenApproval.slot
            approvedAddress := sload(approvedAddressSlot)
        }
    }

    // =============================================================
    //                      TRANSFER OPERATIONS
    // =============================================================

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token
     * by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        uint256 prevOwnershipPacked = _packedOwnershipOf(tokenId);

        if (address(uint160(prevOwnershipPacked)) != from) revert TransferFromIncorrectOwner();

        (uint256 approvedAddressSlot, address approvedAddress) = _getApprovedSlotAndAddress(tokenId);

        // The nested ifs save around 20+ gas over a compound boolean condition.
        if (!_isSenderApprovedOrOwner(approvedAddress, from, _msgSenderERC721A()))
            if (!isApprovedForAll(from, _msgSenderERC721A())) revert TransferCallerNotOwnerNorApproved();

        if (to == address(0)) revert TransferToZeroAddress();

        _beforeTokenTransfers(from, to, tokenId, 1);

        // Clear approvals from the previous owner.
        assembly {
            if approvedAddress {
                // This is equivalent to `delete _tokenApprovals[tokenId]`.
                sstore(approvedAddressSlot, 0)
            }
        }

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as `tokenId` would have to be 2**256.
        unchecked {
            // We can directly increment and decrement the balances.
            --_packedAddressData[from]; // Updates: `balance -= 1`.
            ++_packedAddressData[to]; // Updates: `balance += 1`.

            // Updates:
            // - `address` to the next owner.
            // - `startTimestamp` to the timestamp of transfering.
            // - `burned` to `false`.
            // - `nextInitialized` to `true`.
            _packedOwnerships[tokenId] = _packOwnershipData(
                to,
                _BITMASK_NEXT_INITIALIZED | _nextExtraData(from, to, prevOwnershipPacked)
            );

            // If the next slot may not have been initialized (i.e. `nextInitialized == false`) .
            if (prevOwnershipPacked & _BITMASK_NEXT_INITIALIZED == 0) {
                uint256 nextTokenId = tokenId + 1;
                // If the next slot's address is zero and not burned (i.e. packed value is zero).
                if (_packedOwnerships[nextTokenId] == 0) {
                    // If the next slot is within bounds.
                    if (nextTokenId != _currentIndex) {
                        // Initialize the next slot to maintain correctness for `ownerOf(tokenId + 1)`.
                        _packedOwnerships[nextTokenId] = prevOwnershipPacked;
                    }
                }
            }
        }

        emit Transfer(from, to, tokenId);
        _afterTokenTransfers(from, to, tokenId, 1);
    }

    /**
     * @dev Equivalent to `safeTransferFrom(from, to, tokenId, '')`.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, '');
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token
     * by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement
     * {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        transferFrom(from, to, tokenId);
        if (to.code.length != 0)
            if (!_checkContractOnERC721Received(from, to, tokenId, _data)) {
                revert TransferToNonERC721ReceiverImplementer();
            }
    }

    /**
     * @dev Hook that is called before a set of serially-ordered token IDs
     * are about to be transferred. This includes minting.
     * And also called before burning one token.
     *
     * `startTokenId` - the first token ID to be transferred.
     * `quantity` - the amount to be transferred.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, `tokenId` will be burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}

    /**
     * @dev Hook that is called after a set of serially-ordered token IDs
     * have been transferred. This includes minting.
     * And also called after one token has been burned.
     *
     * `startTokenId` - the first token ID to be transferred.
     * `quantity` - the amount to be transferred.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` has been
     * transferred to `to`.
     * - When `from` is zero, `tokenId` has been minted for `to`.
     * - When `to` is zero, `tokenId` has been burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _afterTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}

    /**
     * @dev Private function to invoke {IERC721Receiver-onERC721Received} on a target contract.
     *
     * `from` - Previous owner of the given token ID.
     * `to` - Target address that will receive the token.
     * `tokenId` - Token ID to be transferred.
     * `_data` - Optional data to send along with the call.
     *
     * Returns whether the call correctly returned the expected magic value.
     */
    function _checkContractOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        try ERC721A__IERC721Receiver(to).onERC721Received(_msgSenderERC721A(), from, tokenId, _data) returns (
            bytes4 retval
        ) {
            return retval == ERC721A__IERC721Receiver(to).onERC721Received.selector;
        } catch (bytes memory reason) {
            if (reason.length == 0) {
                revert TransferToNonERC721ReceiverImplementer();
            } else {
                assembly {
                    revert(add(32, reason), mload(reason))
                }
            }
        }
    }

    // =============================================================
    //                        MINT OPERATIONS
    // =============================================================

    /**
     * @dev Mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `quantity` must be greater than 0.
     *
     * Emits a {Transfer} event for each mint.
     */
    function _mint(address to, uint256 quantity) internal virtual {
        uint256 startTokenId = _currentIndex;
        if (quantity == 0) revert MintZeroQuantity();

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are incredibly unrealistic.
        // `balance` and `numberMinted` have a maximum limit of 2**64.
        // `tokenId` has a maximum limit of 2**256.
        unchecked {
            // Updates:
            // - `balance += quantity`.
            // - `numberMinted += quantity`.
            //
            // We can directly add to the `balance` and `numberMinted`.
            _packedAddressData[to] += quantity * ((1 << _BITPOS_NUMBER_MINTED) | 1);

            // Updates:
            // - `address` to the owner.
            // - `startTimestamp` to the timestamp of minting.
            // - `burned` to `false`.
            // - `nextInitialized` to `quantity == 1`.
            _packedOwnerships[startTokenId] = _packOwnershipData(
                to,
                _nextInitializedFlag(quantity) | _nextExtraData(address(0), to, 0)
            );

            uint256 toMasked;
            uint256 end = startTokenId + quantity;

            // Use assembly to loop and emit the `Transfer` event for gas savings.
            assembly {
                // Mask `to` to the lower 160 bits, in case the upper bits somehow aren't clean.
                toMasked := and(to, _BITMASK_ADDRESS)
                // Emit the `Transfer` event.
                log4(
                    0, // Start of data (0, since no data).
                    0, // End of data (0, since no data).
                    _TRANSFER_EVENT_SIGNATURE, // Signature.
                    0, // `address(0)`.
                    toMasked, // `to`.
                    startTokenId // `tokenId`.
                )

                for {
                    let tokenId := add(startTokenId, 1)
                } iszero(eq(tokenId, end)) {
                    tokenId := add(tokenId, 1)
                } {
                    // Emit the `Transfer` event. Similar to above.
                    log4(0, 0, _TRANSFER_EVENT_SIGNATURE, 0, toMasked, tokenId)
                }
            }
            if (toMasked == 0) revert MintToZeroAddress();

            _currentIndex = end;
        }
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    /**
     * @dev Mints `quantity` tokens and transfers them to `to`.
     *
     * This function is intended for efficient minting only during contract creation.
     *
     * It emits only one {ConsecutiveTransfer} as defined in
     * [ERC2309](https://eips.ethereum.org/EIPS/eip-2309),
     * instead of a sequence of {Transfer} event(s).
     *
     * Calling this function outside of contract creation WILL make your contract
     * non-compliant with the ERC721 standard.
     * For full ERC721 compliance, substituting ERC721 {Transfer} event(s) with the ERC2309
     * {ConsecutiveTransfer} event is only permissible during contract creation.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `quantity` must be greater than 0.
     *
     * Emits a {ConsecutiveTransfer} event.
     */
    function _mintERC2309(address to, uint256 quantity) internal virtual {
        uint256 startTokenId = _currentIndex;
        if (to == address(0)) revert MintToZeroAddress();
        if (quantity == 0) revert MintZeroQuantity();
        if (quantity > _MAX_MINT_ERC2309_QUANTITY_LIMIT) revert MintERC2309QuantityExceedsLimit();

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are unrealistic due to the above check for `quantity` to be below the limit.
        unchecked {
            // Updates:
            // - `balance += quantity`.
            // - `numberMinted += quantity`.
            //
            // We can directly add to the `balance` and `numberMinted`.
            _packedAddressData[to] += quantity * ((1 << _BITPOS_NUMBER_MINTED) | 1);

            // Updates:
            // - `address` to the owner.
            // - `startTimestamp` to the timestamp of minting.
            // - `burned` to `false`.
            // - `nextInitialized` to `quantity == 1`.
            _packedOwnerships[startTokenId] = _packOwnershipData(
                to,
                _nextInitializedFlag(quantity) | _nextExtraData(address(0), to, 0)
            );

            emit ConsecutiveTransfer(startTokenId, startTokenId + quantity - 1, address(0), to);

            _currentIndex = startTokenId + quantity;
        }
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    /**
     * @dev Safely mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement
     * {IERC721Receiver-onERC721Received}, which is called for each safe transfer.
     * - `quantity` must be greater than 0.
     *
     * See {_mint}.
     *
     * Emits a {Transfer} event for each mint.
     */
    function _safeMint(
        address to,
        uint256 quantity,
        bytes memory _data
    ) internal virtual {
        _mint(to, quantity);

        unchecked {
            if (to.code.length != 0) {
                uint256 end = _currentIndex;
                uint256 index = end - quantity;
                do {
                    if (!_checkContractOnERC721Received(address(0), to, index++, _data)) {
                        revert TransferToNonERC721ReceiverImplementer();
                    }
                } while (index < end);
                // Reentrancy protection.
                if (_currentIndex != end) revert();
            }
        }
    }

    /**
     * @dev Equivalent to `_safeMint(to, quantity, '')`.
     */
    function _safeMint(address to, uint256 quantity) internal virtual {
        _safeMint(to, quantity, '');
    }

    // =============================================================
    //                        BURN OPERATIONS
    // =============================================================

    /**
     * @dev Equivalent to `_burn(tokenId, false)`.
     */
    function _burn(uint256 tokenId) internal virtual {
        _burn(tokenId, false);
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
    function _burn(uint256 tokenId, bool approvalCheck) internal virtual {
        uint256 prevOwnershipPacked = _packedOwnershipOf(tokenId);

        address from = address(uint160(prevOwnershipPacked));

        (uint256 approvedAddressSlot, address approvedAddress) = _getApprovedSlotAndAddress(tokenId);

        if (approvalCheck) {
            // The nested ifs save around 20+ gas over a compound boolean condition.
            if (!_isSenderApprovedOrOwner(approvedAddress, from, _msgSenderERC721A()))
                if (!isApprovedForAll(from, _msgSenderERC721A())) revert TransferCallerNotOwnerNorApproved();
        }

        _beforeTokenTransfers(from, address(0), tokenId, 1);

        // Clear approvals from the previous owner.
        assembly {
            if approvedAddress {
                // This is equivalent to `delete _tokenApprovals[tokenId]`.
                sstore(approvedAddressSlot, 0)
            }
        }

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as `tokenId` would have to be 2**256.
        unchecked {
            // Updates:
            // - `balance -= 1`.
            // - `numberBurned += 1`.
            //
            // We can directly decrement the balance, and increment the number burned.
            // This is equivalent to `packed -= 1; packed += 1 << _BITPOS_NUMBER_BURNED;`.
            _packedAddressData[from] += (1 << _BITPOS_NUMBER_BURNED) - 1;

            // Updates:
            // - `address` to the last owner.
            // - `startTimestamp` to the timestamp of burning.
            // - `burned` to `true`.
            // - `nextInitialized` to `true`.
            _packedOwnerships[tokenId] = _packOwnershipData(
                from,
                (_BITMASK_BURNED | _BITMASK_NEXT_INITIALIZED) | _nextExtraData(from, address(0), prevOwnershipPacked)
            );

            // If the next slot may not have been initialized (i.e. `nextInitialized == false`) .
            if (prevOwnershipPacked & _BITMASK_NEXT_INITIALIZED == 0) {
                uint256 nextTokenId = tokenId + 1;
                // If the next slot's address is zero and not burned (i.e. packed value is zero).
                if (_packedOwnerships[nextTokenId] == 0) {
                    // If the next slot is within bounds.
                    if (nextTokenId != _currentIndex) {
                        // Initialize the next slot to maintain correctness for `ownerOf(tokenId + 1)`.
                        _packedOwnerships[nextTokenId] = prevOwnershipPacked;
                    }
                }
            }
        }

        emit Transfer(from, address(0), tokenId);
        _afterTokenTransfers(from, address(0), tokenId, 1);

        // Overflow not possible, as _burnCounter cannot be exceed _currentIndex times.
        unchecked {
            _burnCounter++;
        }
    }

    // =============================================================
    //                     EXTRA DATA OPERATIONS
    // =============================================================

    /**
     * @dev Directly sets the extra data for the ownership data `index`.
     */
    function _setExtraDataAt(uint256 index, uint24 extraData) internal virtual {
        uint256 packed = _packedOwnerships[index];
        if (packed == 0) revert OwnershipNotInitializedForExtraData();
        uint256 extraDataCasted;
        // Cast `extraData` with assembly to avoid redundant masking.
        assembly {
            extraDataCasted := extraData
        }
        packed = (packed & _BITMASK_EXTRA_DATA_COMPLEMENT) | (extraDataCasted << _BITPOS_EXTRA_DATA);
        _packedOwnerships[index] = packed;
    }

    /**
     * @dev Called during each token transfer to set the 24bit `extraData` field.
     * Intended to be overridden by the cosumer contract.
     *
     * `previousExtraData` - the value of `extraData` before transfer.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, `tokenId` will be burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _extraData(
        address from,
        address to,
        uint24 previousExtraData
    ) internal view virtual returns (uint24) {}

    /**
     * @dev Returns the next extra data for the packed ownership data.
     * The returned result is shifted into position.
     */
    function _nextExtraData(
        address from,
        address to,
        uint256 prevOwnershipPacked
    ) private view returns (uint256) {
        uint24 extraData = uint24(prevOwnershipPacked >> _BITPOS_EXTRA_DATA);
        return uint256(_extraData(from, to, extraData)) << _BITPOS_EXTRA_DATA;
    }

    // =============================================================
    //                       OTHER OPERATIONS
    // =============================================================

    /**
     * @dev Returns the message sender (defaults to `msg.sender`).
     *
     * If you are writing GSN compatible contracts, you need to override this function.
     */
    function _msgSenderERC721A() internal view virtual returns (address) {
        return msg.sender;
    }

    /**
     * @dev Converts a uint256 to its ASCII string decimal representation.
     */
    function _toString(uint256 value) internal pure virtual returns (string memory str) {
        assembly {
            // The maximum value of a uint256 contains 78 digits (1 byte per digit),
            // but we allocate 0x80 bytes to keep the free memory pointer 32-byte word aliged.
            // We will need 1 32-byte word to store the length,
            // and 3 32-byte words to store a maximum of 78 digits. Total: 0x20 + 3 * 0x20 = 0x80.
            str := add(mload(0x40), 0x80)
            // Update the free memory pointer to allocate.
            mstore(0x40, str)

            // Cache the end of the memory to calculate the length later.
            let end := str

            // We write the string from rightmost digit to leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            // prettier-ignore
            for { let temp := value } 1 {} {
                str := sub(str, 1)
                // Write the character to the pointer.
                // The ASCII index of the '0' character is 48.
                mstore8(str, add(48, mod(temp, 10)))
                // Keep dividing `temp` until zero.
                temp := div(temp, 10)
                // prettier-ignore
                if iszero(temp) { break }
            }

            let length := sub(end, str)
            // Move the pointer 32 bytes leftwards to make room for the length.
            str := sub(str, 0x20)
            // Store the length.
            mstore(str, length)
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

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
// OpenZeppelin Contracts (last updated v4.7.0) (token/common/ERC2981.sol)

pragma solidity ^0.8.0;

import "IERC2981.sol";
import "ERC165.sol";

/**
 * @dev Implementation of the NFT Royalty Standard, a standardized way to retrieve royalty payment information.
 *
 * Royalty information can be specified globally for all token ids via {_setDefaultRoyalty}, and/or individually for
 * specific token ids via {_setTokenRoyalty}. The latter takes precedence over the first.
 *
 * Royalty is specified as a fraction of sale price. {_feeDenominator} is overridable but defaults to 10000, meaning the
 * fee is specified in basis points by default.
 *
 * IMPORTANT: ERC-2981 only specifies a way to signal royalty information and does not enforce its payment. See
 * https://eips.ethereum.org/EIPS/eip-2981#optional-royalty-payments[Rationale] in the EIP. Marketplaces are expected to
 * voluntarily pay royalties together with sales, but note that this standard is not yet widely supported.
 *
 * _Available since v4.5._
 */
abstract contract ERC2981 is IERC2981, ERC165 {
    struct RoyaltyInfo {
        address receiver;
        uint96 royaltyFraction;
    }

    RoyaltyInfo private _defaultRoyaltyInfo;
    mapping(uint256 => RoyaltyInfo) private _tokenRoyaltyInfo;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC165) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @inheritdoc IERC2981
     */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) public view virtual override returns (address, uint256) {
        RoyaltyInfo memory royalty = _tokenRoyaltyInfo[_tokenId];

        if (royalty.receiver == address(0)) {
            royalty = _defaultRoyaltyInfo;
        }

        uint256 royaltyAmount = (_salePrice * royalty.royaltyFraction) / _feeDenominator();

        return (royalty.receiver, royaltyAmount);
    }

    /**
     * @dev The denominator with which to interpret the fee set in {_setTokenRoyalty} and {_setDefaultRoyalty} as a
     * fraction of the sale price. Defaults to 10000 so fees are expressed in basis points, but may be customized by an
     * override.
     */
    function _feeDenominator() internal pure virtual returns (uint96) {
        return 10000;
    }

    /**
     * @dev Sets the royalty information that all ids in this contract will default to.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setDefaultRoyalty(address receiver, uint96 feeNumerator) internal virtual {
        require(feeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: invalid receiver");

        _defaultRoyaltyInfo = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Removes default royalty information.
     */
    function _deleteDefaultRoyalty() internal virtual {
        delete _defaultRoyaltyInfo;
    }

    /**
     * @dev Sets the royalty information for a specific token id, overriding the global default.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) internal virtual {
        require(feeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: Invalid parameters");

        _tokenRoyaltyInfo[tokenId] = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Resets royalty information for the token id back to the global default.
     */
    function _resetTokenRoyalty(uint256 tokenId) internal virtual {
        delete _tokenRoyaltyInfo[tokenId];
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "IERC165.sol";

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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/draft-EIP712.sol)

pragma solidity ^0.8.0;

// EIP-712 is Final as of 2022-08-11. This file is deprecated.

import "EIP712.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/EIP712.sol)

pragma solidity ^0.8.0;

import "ECDSA.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712 {
    /* solhint-disable var-name-mixedcase */
    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;
    address private immutable _CACHED_THIS;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
        _CACHED_THIS = address(this);
        _TYPE_HASH = typeHash;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (address(this) == _CACHED_THIS && block.chainid == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV // Deprecated in v4.8
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {RevokableOperatorFilterer} from "RevokableOperatorFilterer.sol";
import {CANONICAL_CORI_SUBSCRIPTION, CANONICAL_OPERATOR_FILTER_REGISTRY_ADDRESS} from "Constants.sol";
/**
 * @title  RevokableDefaultOperatorFilterer
 * @notice Inherits from RevokableOperatorFilterer and automatically subscribes to the default OpenSea subscription.
 *         Note that OpenSea will disable creator earnings enforcement if filtered operators begin fulfilling orders
 *         on-chain, eg, if the registry is revoked or bypassed.
 */

abstract contract RevokableDefaultOperatorFilterer is RevokableOperatorFilterer {
    /// @dev The constructor that is called when the contract is being deployed.
    constructor()
        RevokableOperatorFilterer(CANONICAL_OPERATOR_FILTER_REGISTRY_ADDRESS, CANONICAL_CORI_SUBSCRIPTION, true)
    {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {UpdatableOperatorFilterer} from "UpdatableOperatorFilterer.sol";
import {IOperatorFilterRegistry} from "IOperatorFilterRegistry.sol";

/**
 * @title  RevokableOperatorFilterer
 * @notice This contract is meant to allow contracts to permanently skip OperatorFilterRegistry checks if desired. The
 *         Registry itself has an "unregister" function, but if the contract is ownable, the owner can re-register at
 *         any point. As implemented, this abstract contract allows the contract owner to permanently skip the
 *         OperatorFilterRegistry checks by calling revokeOperatorFilterRegistry. Once done, the registry
 *         address cannot be further updated.
 *         Note that OpenSea will still disable creator earnings enforcement if filtered operators begin fulfilling orders
 *         on-chain, eg, if the registry is revoked or bypassed.
 */
abstract contract RevokableOperatorFilterer is UpdatableOperatorFilterer {
    /// @dev Emitted when the registry has already been revoked.
    error RegistryHasBeenRevoked();
    /// @dev Emitted when the initial registry address is attempted to be set to the zero address.
    error InitialRegistryAddressCannotBeZeroAddress();

    event OperatorFilterRegistryRevoked();

    bool public isOperatorFilterRegistryRevoked;

    /// @dev The constructor that is called when the contract is being deployed.
    constructor(address _registry, address subscriptionOrRegistrantToCopy, bool subscribe)
        UpdatableOperatorFilterer(_registry, subscriptionOrRegistrantToCopy, subscribe)
    {
        // don't allow creating a contract with a permanently revoked registry
        if (_registry == address(0)) {
            revert InitialRegistryAddressCannotBeZeroAddress();
        }
    }

    /**
     * @notice Update the address that the contract will make OperatorFilter checks against. When set to the zero
     *         address, checks will be permanently bypassed, and the address cannot be updated again. OnlyOwner.
     */
    function updateOperatorFilterRegistryAddress(address newRegistry) public override {
        if (msg.sender != owner()) {
            revert OnlyOwner();
        }
        // if registry has been revoked, do not allow further updates
        if (isOperatorFilterRegistryRevoked) {
            revert RegistryHasBeenRevoked();
        }

        operatorFilterRegistry = IOperatorFilterRegistry(newRegistry);
        emit OperatorFilterRegistryAddressUpdated(newRegistry);
    }

    /**
     * @notice Revoke the OperatorFilterRegistry address, permanently bypassing checks. OnlyOwner.
     */
    function revokeOperatorFilterRegistry() public {
        if (msg.sender != owner()) {
            revert OnlyOwner();
        }
        // if registry has been revoked, do not allow further updates
        if (isOperatorFilterRegistryRevoked) {
            revert RegistryHasBeenRevoked();
        }

        // set to zero address to bypass checks
        operatorFilterRegistry = IOperatorFilterRegistry(address(0));
        isOperatorFilterRegistryRevoked = true;
        emit OperatorFilterRegistryRevoked();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IOperatorFilterRegistry} from "IOperatorFilterRegistry.sol";

/**
 * @title  UpdatableOperatorFilterer
 * @notice Abstract contract whose constructor automatically registers and optionally subscribes to or copies another
 *         registrant's entries in the OperatorFilterRegistry. This contract allows the Owner to update the
 *         OperatorFilterRegistry address via updateOperatorFilterRegistryAddress, including to the zero address,
 *         which will bypass registry checks.
 *         Note that OpenSea will still disable creator earnings enforcement if filtered operators begin fulfilling orders
 *         on-chain, eg, if the registry is revoked or bypassed.
 * @dev    This smart contract is meant to be inherited by token contracts so they can use the following:
 *         - `onlyAllowedOperator` modifier for `transferFrom` and `safeTransferFrom` methods.
 *         - `onlyAllowedOperatorApproval` modifier for `approve` and `setApprovalForAll` methods.
 */
abstract contract UpdatableOperatorFilterer {
    /// @dev Emitted when an operator is not allowed.
    error OperatorNotAllowed(address operator);
    /// @dev Emitted when someone other than the owner is trying to call an only owner function.
    error OnlyOwner();

    event OperatorFilterRegistryAddressUpdated(address newRegistry);

    IOperatorFilterRegistry public operatorFilterRegistry;

    /// @dev The constructor that is called when the contract is being deployed.
    constructor(address _registry, address subscriptionOrRegistrantToCopy, bool subscribe) {
        IOperatorFilterRegistry registry = IOperatorFilterRegistry(_registry);
        operatorFilterRegistry = registry;
        // If an inheriting token contract is deployed to a network without the registry deployed, the modifier
        // will not revert, but the contract will need to be registered with the registry once it is deployed in
        // order for the modifier to filter addresses.
        if (address(registry).code.length > 0) {
            if (subscribe) {
                registry.registerAndSubscribe(address(this), subscriptionOrRegistrantToCopy);
            } else {
                if (subscriptionOrRegistrantToCopy != address(0)) {
                    registry.registerAndCopyEntries(address(this), subscriptionOrRegistrantToCopy);
                } else {
                    registry.register(address(this));
                }
            }
        }
    }

    /**
     * @dev A helper function to check if the operator is allowed.
     */
    modifier onlyAllowedOperator(address from) virtual {
        // Allow spending tokens from addresses with balance
        // Note that this still allows listings and marketplaces with escrow to transfer tokens if transferred
        // from an EOA.
        if (from != msg.sender) {
            _checkFilterOperator(msg.sender);
        }
        _;
    }

    /**
     * @dev A helper function to check if the operator approval is allowed.
     */
    modifier onlyAllowedOperatorApproval(address operator) virtual {
        _checkFilterOperator(operator);
        _;
    }

    /**
     * @notice Update the address that the contract will make OperatorFilter checks against. When set to the zero
     *         address, checks will be bypassed. OnlyOwner.
     */
    function updateOperatorFilterRegistryAddress(address newRegistry) public virtual {
        if (msg.sender != owner()) {
            revert OnlyOwner();
        }
        operatorFilterRegistry = IOperatorFilterRegistry(newRegistry);
        emit OperatorFilterRegistryAddressUpdated(newRegistry);
    }

    /**
     * @dev Assume the contract has an owner, but leave specific Ownable implementation up to inheriting contract.
     */
    function owner() public view virtual returns (address);

    /**
     * @dev A helper function to check if the operator is allowed.
     */
    function _checkFilterOperator(address operator) internal view virtual {
        IOperatorFilterRegistry registry = operatorFilterRegistry;
        // Check registry code length to facilitate testing in environments without a deployed registry.
        if (address(registry) != address(0) && address(registry).code.length > 0) {
            // under normal circumstances, this function will revert rather than return false, but inheriting contracts
            // may specify their own OperatorFilterRegistry implementations, which may behave differently
            if (!registry.isOperatorAllowed(address(this), operator)) {
                revert OperatorNotAllowed(operator);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IOperatorFilterRegistry {
    /**
     * @notice Returns true if operator is not filtered for a given token, either by address or codeHash. Also returns
     *         true if supplied registrant address is not registered.
     */
    function isOperatorAllowed(address registrant, address operator) external view returns (bool);

    /**
     * @notice Registers an address with the registry. May be called by address itself or by EIP-173 owner.
     */
    function register(address registrant) external;

    /**
     * @notice Registers an address with the registry and "subscribes" to another address's filtered operators and codeHashes.
     */
    function registerAndSubscribe(address registrant, address subscription) external;

    /**
     * @notice Registers an address with the registry and copies the filtered operators and codeHashes from another
     *         address without subscribing.
     */
    function registerAndCopyEntries(address registrant, address registrantToCopy) external;

    /**
     * @notice Unregisters an address with the registry and removes its subscription. May be called by address itself or by EIP-173 owner.
     *         Note that this does not remove any filtered addresses or codeHashes.
     *         Also note that any subscriptions to this registrant will still be active and follow the existing filtered addresses and codehashes.
     */
    function unregister(address addr) external;

    /**
     * @notice Update an operator address for a registered address - when filtered is true, the operator is filtered.
     */
    function updateOperator(address registrant, address operator, bool filtered) external;

    /**
     * @notice Update multiple operators for a registered address - when filtered is true, the operators will be filtered. Reverts on duplicates.
     */
    function updateOperators(address registrant, address[] calldata operators, bool filtered) external;

    /**
     * @notice Update a codeHash for a registered address - when filtered is true, the codeHash is filtered.
     */
    function updateCodeHash(address registrant, bytes32 codehash, bool filtered) external;

    /**
     * @notice Update multiple codeHashes for a registered address - when filtered is true, the codeHashes will be filtered. Reverts on duplicates.
     */
    function updateCodeHashes(address registrant, bytes32[] calldata codeHashes, bool filtered) external;

    /**
     * @notice Subscribe an address to another registrant's filtered operators and codeHashes. Will remove previous
     *         subscription if present.
     *         Note that accounts with subscriptions may go on to subscribe to other accounts - in this case,
     *         subscriptions will not be forwarded. Instead the former subscription's existing entries will still be
     *         used.
     */
    function subscribe(address registrant, address registrantToSubscribe) external;

    /**
     * @notice Unsubscribe an address from its current subscribed registrant, and optionally copy its filtered operators and codeHashes.
     */
    function unsubscribe(address registrant, bool copyExistingEntries) external;

    /**
     * @notice Get the subscription address of a given registrant, if any.
     */
    function subscriptionOf(address addr) external returns (address registrant);

    /**
     * @notice Get the set of addresses subscribed to a given registrant.
     *         Note that order is not guaranteed as updates are made.
     */
    function subscribers(address registrant) external returns (address[] memory);

    /**
     * @notice Get the subscriber at a given index in the set of addresses subscribed to a given registrant.
     *         Note that order is not guaranteed as updates are made.
     */
    function subscriberAt(address registrant, uint256 index) external returns (address);

    /**
     * @notice Copy filtered operators and codeHashes from a different registrantToCopy to addr.
     */
    function copyEntriesOf(address registrant, address registrantToCopy) external;

    /**
     * @notice Returns true if operator is filtered by a given address or its subscription.
     */
    function isOperatorFiltered(address registrant, address operator) external returns (bool);

    /**
     * @notice Returns true if the hash of an address's code is filtered by a given address or its subscription.
     */
    function isCodeHashOfFiltered(address registrant, address operatorWithCode) external returns (bool);

    /**
     * @notice Returns true if a codeHash is filtered by a given address or its subscription.
     */
    function isCodeHashFiltered(address registrant, bytes32 codeHash) external returns (bool);

    /**
     * @notice Returns a list of filtered operators for a given address or its subscription.
     */
    function filteredOperators(address addr) external returns (address[] memory);

    /**
     * @notice Returns the set of filtered codeHashes for a given address or its subscription.
     *         Note that order is not guaranteed as updates are made.
     */
    function filteredCodeHashes(address addr) external returns (bytes32[] memory);

    /**
     * @notice Returns the filtered operator at the given index of the set of filtered operators for a given address or
     *         its subscription.
     *         Note that order is not guaranteed as updates are made.
     */
    function filteredOperatorAt(address registrant, uint256 index) external returns (address);

    /**
     * @notice Returns the filtered codeHash at the given index of the list of filtered codeHashes for a given address or
     *         its subscription.
     *         Note that order is not guaranteed as updates are made.
     */
    function filteredCodeHashAt(address registrant, uint256 index) external returns (bytes32);

    /**
     * @notice Returns true if an address has registered
     */
    function isRegistered(address addr) external returns (bool);

    /**
     * @dev Convenience method to compute the code hash of an arbitrary contract
     */
    function codeHashOf(address addr) external returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

address constant CANONICAL_OPERATOR_FILTER_REGISTRY_ADDRESS = 0x000000000000AAeB6D7670E522A718067333cd4E;
address constant CANONICAL_CORI_SUBSCRIPTION = 0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6;