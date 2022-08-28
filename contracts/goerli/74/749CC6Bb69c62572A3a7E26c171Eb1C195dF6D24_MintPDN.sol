pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "../libs/Initializable.sol";
import "../libs/Permission.sol";
import "./IdaMo.sol";
import "./IWishDaMo.sol";


contract MintPDN is Ownable,Initializable,Permission
{
     using Counters for Counters.Counter;
     Counters.Counter private _tokenIdTracker;
     using SafeMath for uint256; 
     using Strings for uint256;
     bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    IdaMo daMoContract;
    IWishDaMo wishDaMoContract;
   
   //price
    uint256 donateUint = 1*(10**18);
    
    address treasuryAddress;
    uint8 period = 1;
    uint8 freeMintmax = 3 ;
    uint256 total = 1000;
    uint256 sq = 0;

    mapping(address => uint8) mintWhilte; //frree mint number
    mapping(address => uint8) addressMap; //minted number
    mapping(address => uint8) airdropMintWhilte;
    address[]  airdropAddrs = new address[](31);

    //bool isPublicMint = false;
    bool isPriveFreeMint = false;
    uint256 startMintTime = 0;

    mapping(address => uint8) mintLocks;
    event mintEvt(address indexed,uint256 tokenId);
    event mintCardEvt(address indexed,uint256 tokenId);
    event airdropWishDamoEvt(string);
    event freeMintDamoEvt(address indexed,string);

    constructor(){
        initWhilte();
    }

    modifier mintLock() {
        require(mintLocks[_msgSender()] == 0, "Locked");
        mintLocks[_msgSender()] == 1;
        _;
        mintLocks[_msgSender()] == 0;
    }

    function init(IdaMo _idaMo,IWishDaMo _iWishDaMo) public onlyOwner {
        daMoContract = _idaMo;
        wishDaMoContract = _iWishDaMo;
        initialized = true;
    }

    function setDonateUint(uint256 uintvalue) public onlyRole(MINTER_ROLE){
        donateUint = uintvalue;
    }

    function setTotal(uint256 _total) public onlyRole(MINTER_ROLE){
        total = _total;
    }

    function setIsPublicMint(bool _isPublicMint) public onlyRole(MINTER_ROLE) {
        //isPublicMint = _isPublicMint;
    }

    function getCount(address _addr) public view returns(uint8){
        return mintWhilte[_addr] ;
    }

    function setStart() public onlyRole(MINTER_ROLE) {
        isPriveFreeMint = true;
        startMintTime = block.timestamp;
    }

     function setStatus(bool b) public onlyRole(MINTER_ROLE) {
        isPriveFreeMint = b;
    }

    function setWhilte(address[] memory addrs,uint8[] memory counts) public onlyRole(MINTER_ROLE){
        require(addrs.length == counts.length,"params error");
        for (uint256 index = 0; index < addrs.length; index++) {
            uint8 number = mintWhilte[addrs[index]];
            mintWhilte[addrs[index]] = number+counts[index];
            require(number+counts[index] <= freeMintmax);
        }
    }

    function freeMint(uint8 number) public  needInit mintLock{
        require(number>0,"number error");
        require(isPriveFreeMint==true,"not start");
        require(tx.origin==msg.sender,"forbid");
        uint8 myTotals = getCanMintNumber(msg.sender);
        require(number<=myTotals,"not enough");
        string memory tokenIdStr = "";
        uint256 tokenId = 0;
        if(number>0){
            for (uint8 i = 0; i < number; i++) {
                tokenId = wishDaMoContract.mintNFT(msg.sender,1,1); //许愿达摩1代
                tokenIdStr = string(abi.encodePacked(tokenIdStr,tokenId.toString(),","));
            }
            //count
            addressMap[msg.sender] = addressMap[msg.sender]+number ;
            sq = sq.add(uint256(number));
            require(sq<=uint256(total),"not enough1");
            emit freeMintDamoEvt(msg.sender,tokenIdStr);
        }
    }

    function getCanMintNumber(address addr) public view returns(uint8){
         uint8 max = 0;
         uint256 tspan = block.timestamp.sub(startMintTime) ;
         uint8 hasmintd = addressMap[addr];
         
         if(isPriveFreeMint && tspan<86400){
           max = mintWhilte[addr];
         }else if(isPriveFreeMint && tspan>86400){
           max = freeMintmax;
         }
         if(max<=hasmintd){
            return 0;
         }
         uint8 leftNumber = max-hasmintd;
         if(sq.add(uint256(leftNumber))>total){
            return uint8(total.sub(sq)) ;
         }
         return leftNumber;
    }   

    /**
    func：free airdropDamo
     */
    function airdropDamo(address[] memory addrs,uint8[] memory counts,uint8[] memory genes) public  onlyRole(MINTER_ROLE){
         require(addrs.length == counts.length,"params error");
         require(addrs.length == genes.length,"params error");
          for (uint256 index = 0; index < addrs.length; index++) {
              uint8 number = counts[index];
              require(sq+number<=total,"airdrop not enough");
              if(number>0){
                    for (uint256 i = 0; i < uint256(number); i++) {
                        daMoContract.mintNFT(addrs[index],genes[index]);
                    }
                    sq = sq+number;
              }
          }
    }

    function initWhilte() private{
       // mintWhilte[0x65Cf0841396E54F28Ea354b49C7BE74202682e7b]=2;
      //  mintWhilte[0x3E70328C0e19fbe5C0186146009bFd8Eb865C3AA]=2;
      //  mintWhilte[0x946cF6da65240671061361aab3C0bb1072947Ac2]=3;
       // mintWhilte[0xfCFc9982309990EA7d1e7D3b045eba5dA232508A]=3;

        mintWhilte[0x28De5B4De7493F44a322180436D88429aD8d60F6]=	1;
        mintWhilte[0x3047052B1C61dAE70761A5C833598Dc01234a029]=	1;
        mintWhilte[0x3da3C61E6A3dea5BE524eAC96fa93BC5B1b30CDa]=	1;
        mintWhilte[0xCa2525F879F3F0Cb9eBd6f360cA024637766b0A0]=	1;
        mintWhilte[0xE6e6C5C258C7D5574eDE8acE9A0e4AB6bbe28C49]=	1;
        mintWhilte[0x1418A23cD70bAEd1c7Dbe5c76D7752F6e9EFf837]=	1;
        mintWhilte[0x7a855526F3CF3722BB2944037960d5Adc4f00BEE]=	1;
        mintWhilte[0xBc422cf41a1afcf68fade465F9462D058C912048]=	1;
        mintWhilte[0x22e091333Eed4FD5Ec370992592B2A70E6042Ada]=	1;
        mintWhilte[0x2895CB02B2d6bEbaec2Bb784CF4a06ECf7008884]=	1;
        mintWhilte[0x08ccED3F88f30AAB8f10F65fC68b90C934FBC786]=	1;
        mintWhilte[0x2C32C56471ddAE47225Ee82658c176945733b180]=	1;
        mintWhilte[0xe23057CF258326E53c5aF9630D8a4B4Ca2688359]=	1;
        mintWhilte[0x7d36E06251E8376d7194147D9D26214566FAc47D]=	1;
        mintWhilte[0x6a7e213F8ad56bEA9d85cC8a59c1f940fD5d176B]=	1;
        mintWhilte[0xa546dEe1fD598a34573319EaE22D688F827BeC4C]=	1;
        mintWhilte[0xdB62bb66B3E9C44d8D1E430652F7B3d142D5adfD]=	1;
        mintWhilte[0xfEd0ba81d9a53120747eE1dfFFDc69E5a0A0751B]=	1;
        mintWhilte[0x3f3e147f319272D3260746777Cc00FC3C3953B68]=	1;
        mintWhilte[0xdDa4a0608818347168E33F71AeA71Ba3709924cC]=	1;
        mintWhilte[0xFE763A1Fc636755C8660ed404aEa16CE3Dd14ecF]=	1;
        mintWhilte[0xc3dA3c9F9f9da324748f61833AbA979533d16D50]=	1;
        mintWhilte[0xB38Dc55692379bC670A8e7e9d4Efc7B8221EB825]=	2;
        mintWhilte[0xB80C2f40e01d448002a355Bc7C39A593a13D40eF]=	1;
        mintWhilte[0x09628D07ab4cABE66400f6A627732B4C11Ab0575]=	1;
        mintWhilte[0x561262F935a094D1A19E5C810244Abb407E53933]=	2;
        mintWhilte[0x87eE1761320A8F696fA7386715428C21f4c43c11]=	1;
        mintWhilte[0x7a046f935c0BfBffd02882B440d66568De78d9DC]=	1;
        mintWhilte[0x152d112efD94dC9Fd7B7A77E83B93C7B43889FCb]=	1;
        mintWhilte[0x9ecf4ee93c6c453E2Eeb1Efa8D16d36f467A3EEF]=	1;
        mintWhilte[0x80B54E235ed683eE375362f57F746a6B219bE96C]=	1;
        mintWhilte[0xeAF8d1745065b3CcB08EdCCe198aD8a656f7C2b0]=	1;
        mintWhilte[0x277Dbe77aD8226363e9b407C445954fA6F0815C7]=	1;
        mintWhilte[0xAa3550E1b61404BC2EDBD5eD4Cd2e6f45f84e73A]=	1;
        mintWhilte[0x242e99540F08558808015B9ecbd442c1BD4Be7DF]=	1;
        mintWhilte[0xF8ED9e6d344F225569438aa34f5B771CA8B76483]=	1;
        mintWhilte[0x2A1F28f16A496222547d382590477D652ebd647F]=	1;
        mintWhilte[0x91D6bb62EA1FB8711Ab378b992f53a6572539d01]=	1;
        mintWhilte[0x3123D3BBBd30f5276C4406D0b9C36c6F5104D9A9]=	1;
        mintWhilte[0x2CFbAd98F41D8EAA6d8c2CCab4fc3A54c5950926]=	1;
        mintWhilte[0x2F4ffaA59984D1b72318019b882c181E8232E04B]=	1;
        mintWhilte[0xc2Af218FaA0F8AD569f0ED8F4621bA4718c1F78a]=	1;
        mintWhilte[0x01Eb937BfeCb17321344E0FCf4CCF4c91ff6C79F]=	1;
        mintWhilte[0x10DBC2b5291506be314CF7342551C3877B67dE56]=	1;
        mintWhilte[0xB0C3546A8C29a5fE5d8886553014C9e20009B6e8]=	2;
        mintWhilte[0x72c62C06f0F684Aa70803F4858e8EEf92b917542]=	1;
        mintWhilte[0x9D4A0044d4e0967E4F67dDC07e88b0bdB1895AeA]=	1;
        mintWhilte[0x11A248a30ceE6e14a6a43cDF08986e1dcfb6394c]=	1;
        mintWhilte[0x7fc9851e53fA7d7792836AeF35e294a1168fEA01]=	1;
        mintWhilte[0x8446Ced73A58dc88faD741A27dcB7d99f718dafe]=	1;
        mintWhilte[0xA38739712cF014D24C138Dab72100741578f5F96]=	1;
        mintWhilte[0xFC3c6F03FcE8194E7E6673660B07b387daD3f71c]=	2;
        mintWhilte[0x248a7b3522551739863bC1D26f185B5EBE31ac47]=	1;
        mintWhilte[0xe877fee6851b0a04E99c28b524e55Bd955bfFF1a]=	1;
        mintWhilte[0x800E5934bb3CbD7cDA02946805d6CeA8fff76083]=	1;
        mintWhilte[0x839Bdf02465933A6a81356F9a48a9199b847DC70]=	1;
        mintWhilte[0xea4F5679Ab286d502016De868019a5A47629Abf6]=	1;
        mintWhilte[0x774c05b138364E00CC6620843f5A80aDA11FC804]=	1;
        mintWhilte[0x74EC7F96fFC225F06f4E7c4CD7C219Cf9616e84B]=	1;
        mintWhilte[0x9eb6Df122beD959cDa1Ad6De5a0c57eA717c80eE]=	1;
        mintWhilte[0xe119B1676f5bE84fb72f4697cA695D2C2584Af3a]=	1;
        mintWhilte[0xed3b1FAa0A8209CaD68901f23b32EE8264D28ee0]=	2;
        mintWhilte[0xcf61d17Ace0A81D8703653E03E692938B7639879]=	1;
        mintWhilte[0x0a5465ae620F35435605d0a237E5fcb4A2Fd70c7]=	1;
        mintWhilte[0x947A69d8030E7393e274b07915CAb315a92431db]=	1;
        mintWhilte[0x4BaF597568608617d55A5EAFc6E73545c1F1d417]=	1;
        mintWhilte[0x19D4Adb72D4A01C321ECF6C50FC89970099a910d]=	1;
        mintWhilte[0xE1ea435f2eED11dbE8281285C1f21722d1907D72]=	1;
        mintWhilte[0x9753BE2Cf56E1324CDC0096F84A6d9540f01dDa1]=	1;
        mintWhilte[0x652AbD0735F1E4A19FD58d2e737C94314eCb6A89]=	1;
        mintWhilte[0x1bAfF971123e07c2312004a6bD519Fa33085450D]=	1;
        mintWhilte[0xdB1A5CB1b1bf5a5Ef32742BA8218dE653dA7bD6C]=	1;
        mintWhilte[0x69821779A55d799dF2EdE5d97199fe7c88b8c5c8]=	1;
        mintWhilte[0x8C80705b76477918C6e5127AD0C2150fa9944f94]=	1;
        mintWhilte[0xAD3b46AE8d07086FD310c10fF8D5c39Bd895d9Ba]=	2;
        mintWhilte[0x741E2D5F01c888Aa4EB700B9318DeD801469e583]=	1;
        mintWhilte[0x8598c259755558eE0132fD87Ab412965c8C3283B]=	1;
        mintWhilte[0x137331ed7e7C9fffFb24f738C6D0Fb52BEdD97F9]=	1;
        mintWhilte[0x73B137B9a4c0AcEf107eD63064a14d7EDfeF6DbC]=	1;
        mintWhilte[0x00A9366738E45D45049ACeEA29eb722aA534F28B]=	1;
        mintWhilte[0xF835dC8FA029635e49c049CF0FD421E7F1a5d3b8]=	1;
        mintWhilte[0x1e14091d460A9e9cf484e25270689AE24E78d179]=	1;
        mintWhilte[0xeADB0bf6766D9d99CE800Ecdca66B374303C380A]=	1;
        mintWhilte[0x30F32989E602aa062b26FA6095C3E525969ba4f5]=	1;
        mintWhilte[0xf58b3872Ca1D8f538Edc25036866B6A9197327C0]=	1;
        mintWhilte[0x856DC4a12f08AFA49f42B52F81769A96505f312C]=	1;
        mintWhilte[0x4C419c56F5DBC8315DF29A51058aEE49B414e306]=	1;
        mintWhilte[0xFA4572b4E734587Fe0b4d415a92E6654C0c71460]=	2;
        mintWhilte[0x5Ab611C4C7f5725fc0B9ad10112651CAcd0C58E6]=	1;
        mintWhilte[0x5d263C323a2eaCe7E774E58dd9926f9Ab0000D83]=	1;
        mintWhilte[0xC63aABA31D6C20eCF16a14b77057f73860c098f1]=	2;
        mintWhilte[0x632a9F42F3cA75Fa04aB55340FebaA620d5Df20F]=	2;
        mintWhilte[0x662Ad7b47e8f300b2d153cCA992Bf0732A9695B8]=	2;
        mintWhilte[0x078F8d02117134466F940c38a378C3EE85954783]=	1;
        mintWhilte[0xb8a2A2F760E62FA1Ea584c91701F5D2Ae71b9115]=	1;
        mintWhilte[0xD190E69a9B086C290e1DD0c02d4DD41361b0D25e]=	1;
        mintWhilte[0xBb2639f61E445F7ef7FA7686178E94FDEB10E10d]=	1;
        mintWhilte[0x018Db20146816E3643477E29f97c606A25d5F821]=	1;
        mintWhilte[0xB8679f9e71595D7B4736b145E1cCd0696C839799]=	1;
        mintWhilte[0x350582C1D65d228eda722a8dF5e8F82E6dCa7953]=	1;
        mintWhilte[0x61ffAD49568994A09f922fEd0b36287d0D282B84]=	1;
        mintWhilte[0xfE3F75fC990f222cC3a7b1C8530177b092CC8911]=	1;
        mintWhilte[0x914e09396b08139b4F4cFFd0800DC78cC8383b10]=	1;
        mintWhilte[0xF58D7aFc3e2b32Aa87822BE150Df33fB52Ea3180]=	1;
        mintWhilte[0x6f33ee245a860494669D5a1dAb5Bb2b7a0d18cd0]=	2;
        mintWhilte[0x3b03351f763Ac6F3Afd837f1C65Dc7BAAcDC365B]=	1;
        mintWhilte[0x7A15bb9Ae823d1B17d172d248A5365b7a59201BD]=	1;
        mintWhilte[0xE333ee46fF668dc79614eaaCD4Ee6A9246B2dfdE]=	1;
        mintWhilte[0x1B528B71A7cDD10116B9E5fe0E86765D4a35a24d]=	1;
        mintWhilte[0x98BE6908C2E88886C137D73B97Ffe38a5877cf45]=	1;
        mintWhilte[0x45fB8Fd100a06e3701D41d79Cd5907C65E3A8f91]=	1;
        mintWhilte[0x0370CFCdD266EBAEEA224399c0AC8472FBf26e85]=	1;
        mintWhilte[0xCA999F569DF636E36fb306045E79Afa422325982]=	1;
        mintWhilte[0x9E0154c935F8624B5FCE5577d4FBc3AF4aBa0eF7]=	1;
        mintWhilte[0x4CB90c3465C83aE3Ad3A4F6B5B6bfe634BF27666]=	1;
        mintWhilte[0xdbAB7B57260107b7ac52FF68F6064d11D200F84E]=	2;
        mintWhilte[0x5cf5E811D18492F239Aecbe1d727927ABA19DD87]=	1;
        mintWhilte[0x1408Ed6e20a488f34f11045e2CDC7A2A27E3Da17]=	2;
        mintWhilte[0xd8D85aA9E5495e867454084e7D6Db10Dc6d53939]=	1;
        mintWhilte[0xD1D547B26dBFDCA5019dfd70f0b239Ff745688ea]=	1;
        mintWhilte[0xD9D8Cfb369763CED449a6c81E1D0afFe93dc1FA2]=	2;
        mintWhilte[0x35a76af20d720Dee84e71Eb5142D470A2EEe6166]=	1;
        mintWhilte[0xa7D4083A17b20F106688c4c20778e40FBb351aE9]=	1;
        mintWhilte[0x155751C71278795A7da0ff964A2b5f7973B5f425]=	1;
        mintWhilte[0x4b4602f08C6ba6d25d0BBbE1f2e97101B3aeC7a7]=	1;
        mintWhilte[0x52be3580601524652978648E872D0aA448aFC928]=	1;
        mintWhilte[0xf03186A1FD2B42046768DCdB5aA30604A97747D5]=	1;
        mintWhilte[0x0eefaca77f0E27af5E6646987caF6a5D5D47ecDF]=	1;
        mintWhilte[0x4545E97854655807732b30057A4D4181e08BC2E2]=	1;
        mintWhilte[0xb5Bc68CE8B52ADd8E5A64212ac11e19483361Ab3]=	1;
        mintWhilte[0xd38D4E1f1F19EFcbe96223bd049b76f747C6f206]=	1;
        mintWhilte[0xB9B6faabfE7b23C12006B8065B374424905c83d7]=	1;
        mintWhilte[0xE159d5a7bD1E264bB3163e7F29DF40E4Ec1Bb194]=	1;
        mintWhilte[0xb9E10dfEBbAa5A24b3e01b343F1672F049c8dfFE]=	1;
        mintWhilte[0x6FBd0edb1d5BCe0Be5BF0d01F8096C8a4EA54D61]=	1;
        mintWhilte[0xf36E8d53D357C343DAEe4af6896B4E6212DcFcFC]=	1;
        mintWhilte[0x9c1CfaA843A8559F142c9D75f74e626c53D0F528]=	1;
        mintWhilte[0xe8178dDEa871687cf1798224CDB26847e4D6bc81]=	1;
        mintWhilte[0x5c513fE4A73f3Ecb49b5980Dd32Db90A656a3366]=	2;
        mintWhilte[0x05D987577901933e6E6e11ddc8C3b3592aDDffc8]=	1;
        mintWhilte[0x37CB5Aeca3e08640a3767B02E56d5e398EC906b3]=	1;
        mintWhilte[0x91E0C9cdDff46b6933F6BD94fE8df964b847C641]=	1;
        mintWhilte[0x2d129c51E0F742F3CE7885E40312E06bD133852D]=	1;
        mintWhilte[0xAaA488EB314D3E009Fd4CFce2d0a94d3226eddD7]=	1;
        mintWhilte[0xd52c41363b0deFD25cbDC568C93180340F8611a2]=	1;
        mintWhilte[0x081c2451B6CF526cA9A63dfa759c3041a480Ed25]=	1;
        mintWhilte[0x44A568A055D356c887DAEbe614C4266Bc5057A58]=	1;
        mintWhilte[0x0912aE16864214955e15E28Dc4EEc78F039e1b49]=	1;
        mintWhilte[0x19115567Ec61aBab28356bfe24cb505f983B9158]=	1;
        mintWhilte[0x01ba80aEbddF0f380132519034780dfF4cc767de]=	1;
        mintWhilte[0x7d1083a8320bcbA0f3fdf75866Fb99d5DdbA7869]=	1;
        mintWhilte[0xF6A4264fdD00c294c80051819515A1B1073829e6]=	1;
        mintWhilte[0x00b1b9f6732b8143FD49964c5dce66a0aa158EC7]=	1;
        mintWhilte[0xBBA0A9F8b72f1Ad3B0772D276D21f5C9A07E0154]=	1;
        mintWhilte[0x1427d7204a8a50b1Adc6401B3BC46c41dD59bfD8]=	1;
        mintWhilte[0x1368a2DBf1Ac5FD1A247Fc2C5D6eF5dEEC928A73]=	1;
        mintWhilte[0x2a842e026a36f9af2b253855B3DF5e47E2365A83]=	1;
        mintWhilte[0xB7c1662C5577b533686fE8f5AeAab08eB53a74fD]=	1;
        mintWhilte[0x6e5BB242F9Dc1Fd782a31AeE659D5691fD34C938]=	1;
        mintWhilte[0xE8DAF9654d944311ee72034ceAe2D4621973A193]=	1;
        mintWhilte[0xC5787C27237417cE6E2f5F70cB6B088Db340Ad3d]=	1;
        mintWhilte[0x432b5FA73DC00F096f5Ecc349bA5a72Ae3853d44]=	1;
        mintWhilte[0x682c72e317Cf93A36Ace26d52f9eB9c41712e56C]=	1;
        mintWhilte[0x2AeaffEafAb6d6C190eb1975fcD50f5359fcE137]=	1;
        mintWhilte[0xaFC951690afd00979Bcd617089A84Af6589745Ef]=	1;
        mintWhilte[0xF832685f095b5c33ff6cFB84d36473bA7D5A31fE]=	1;
        mintWhilte[0xC0C608A6E1E6B6B7ABA00D2BAE22BF4c5F51f739]=	1;
        mintWhilte[0x52356bA4c6D9542A028ba62EDDC7F699FCc357b2]=	1;
        mintWhilte[0x9e49b7869A5014d6778daE92e27f2281041cc30D]=	1;
        mintWhilte[0x142a8Be9BA219757174D0c7f25788912Feed099d]=	1;
        mintWhilte[0xB5137A219e30a9A2fd952851244ED00e8AA37347]=	1;
        mintWhilte[0x3B0F2700B69a59DC6D1a9Eb0C0Cf86C5530a0D62]=	1;
        mintWhilte[0xc5d07c0128F5d8D47db1e673DcbB3484a8c5604e]=	1;
        mintWhilte[0xA227B5ef06410639D4985d6be693352B71b8A165]=	1;
        mintWhilte[0x7811B9De1fbdD2F4785dC9F2eF06e21bF78AF92e]=	1;
        mintWhilte[0x4689f7f66B968B0bD9d6caEF5c1316f30C68F4E2]=	1;
        mintWhilte[0x2e3eba6E4d30dC5B4297C4c3CA15b41974512bED]=	1;
        mintWhilte[0x352a8fd4F5315288Ab75E623db8fFd82C3325192]=	1;
        mintWhilte[0x3bE655821E333528116b0A299a510331322883ed]=	1;
        mintWhilte[0x9df87CEEb6610b2C5cd237068A91ed369099102d]=	1;
        mintWhilte[0x859597960b264d540567c18C4f0732076FbDdF50]=	1;
        mintWhilte[0x0D5c395f88bD35028763e04E201446759A0D6D05]=	1;
        mintWhilte[0xf1A404393CFB8a2Bd7fdd5475212528355fd813F]=	1;
        mintWhilte[0x1Cd5c81f65c568a8E73473784c34964E2412b421]=	1;
        mintWhilte[0x11065895c4c25eD56d6303Bc8848c068411C8cfF]=	1;
        mintWhilte[0x15A643AA08663e67CFA375287a6c5789599049F9]=	1;
        mintWhilte[0xF284745F89916a1710ef4C26FF4fFf20528cc486]=	1;
        mintWhilte[0x0e04aD3fac0748517eBb2D30384FF17601D1B9A6]=	1;
        mintWhilte[0x4E99f6Fdb8B5a3A292aa2194c970c2A612469Fe2]=	1;
        mintWhilte[0x90567968f455563Da44716B59dd6F50B305222D7]=	1;
        mintWhilte[0x0658d7ed821eB6F9A3349E4Ae9752745bf747666]=	1;
        mintWhilte[0x95Fbc8241CBE6f265d897f141a127478EBF4007c]=	2;
        mintWhilte[0xACc5323209065eFF4a498f0DAEE5b191209D95b6]=	1;
        mintWhilte[0xff6BAbF62840Cfe44fe798006e5e970a1F88AbE7]=	1;
        mintWhilte[0xd78DF20b0188dE4e71D35e50EBd0B9C681Db485e]=	1;
        mintWhilte[0xe65fFaEB5871b8BC1b0CD6E883B88e813A717E3c]=	1;
        mintWhilte[0x09Fab53103B60942aC501B5451fEb7a526b147c9]=	1;
        mintWhilte[0x23c2BBB2059EeE09499880bC0C0fb490f5639596]=	1;
        mintWhilte[0x7501c9Cfd1D2f1F8cE447c795B871f09Ee484b14]=	1;
        mintWhilte[0x976E5E9D2E638c127270FA990B12257F67181906]=	1;
        mintWhilte[0x400FdF5c40f722765D68098028FF978C102D5D68]=	1;
        mintWhilte[0xd249FebC09a0565ca30fc5F657C92B9B7866BF7c]=	1;
        mintWhilte[0xA85A09BCc542737c40112566fB56552b01b58aCc]=	1;
        mintWhilte[0x267B6f06420505392c45fA3322e68595ABdEC383]=	1;
        mintWhilte[0xbe47A126B05F4d889c7c3485Cb957E2C8838074c]=	2;
        mintWhilte[0xAA05853E72b0C8600d7727C9DF2a880BdB9A75d9]=	2;
        mintWhilte[0x1600DeBDE29CE4d516f9F9A0D8BDc25DD054Fa59]=	1;
        mintWhilte[0x84be7Aac9401e672931af79EC01EE1F60BADB5D9]=	1;
        mintWhilte[0xfdE6b490c8494B81a116120B4D0C60ECB7a6b076]=	1;
        mintWhilte[0x1715F43b2189b2C02A2f3588e3D44b1BFb4f6Add]=	1;
        mintWhilte[0x50953EA72Df90DDaF1660F06a6a68c471CFf557A]=	1;
        mintWhilte[0x40d16DC4edD183C0830726EE7d035B573B8e2fe2]=	1;
        mintWhilte[0xffAbe5D644A3ac6042e9Fbc8f8A6A424BEf59a26]=	1;
        mintWhilte[0x35740aECa47AAAd2BC4760C602F925f5fbEE47Aa]=	2;
        mintWhilte[0xC679255Ca35aAe601a6F7d2c6c67e7e9E796b251]=	1;
        mintWhilte[0xE4D43088c3941CebD2C4b153454436c4FB1ee102]=	1;
        mintWhilte[0x08C96FFDCFcdC80A0F94720f33A0FD2E33522A70]=	1;
        mintWhilte[0x2fA08C45aC5A71AA920aFdb535e82D9bfe269201]=	1;
        mintWhilte[0xe2CEa3b422a3DCbf380990C07B3099257f8749D0]=	1;
        mintWhilte[0x0991c3d3d7fe1D53fF951f382A5291898918A39F]=	1;
        mintWhilte[0x0B47429752c531a78cc8b0cF355cb19492Df9623]=	1;
        mintWhilte[0xeB00EB6485C31BcFf5a6952CbD9c6c57E8BDe5dc]=	1;
        mintWhilte[0x9A46AFe2a6Ed46dd6bB70b8C2D8fc17Eae6E449b]=	1;
        mintWhilte[0x156f3116488ed4681C748C3eeEca4913FAfe4b82]=	1;
        mintWhilte[0x56b3591AafD665aadC8f956C5964923782Ea1698]=	1;
        mintWhilte[0x9813FB9Cb78dfbE565a85fCcaaEeE574323F53d2]=	1;
        mintWhilte[0xFc68F2Ebb6a1B4fC97ca820373234dCD21b4D6A4]=	1;
        mintWhilte[0x9c612c5403607603D998cC9a5fbCe3815743C6e8]=	1;
        mintWhilte[0x161C249b6b7750828fA7f50F9ec5277b1D573aEF]=	1;
        mintWhilte[0x7bf39c1c8A4e8B2310BF32D60abc750aAc494aBE]=	1;
        mintWhilte[0x0b8a2e73Ed7FbDfE0FBfB00b30634bf806e714D0]=	1;
        mintWhilte[0xB2d5a39113688394626a62a7C9848570950464C2]=	1;
        mintWhilte[0x076bAe9c123dA43967d5a902e59EB3cD5c120ee3]=	1;
        mintWhilte[0xbC607109Fb48d579ea12306bb60e46A40Ffd2277]=	1;
        mintWhilte[0x6bD68d667ECcEA663b2a2Bee1311F7AD6c817602]=	1;
        mintWhilte[0xDa2A02C9F8B66f756f76d795D1ae0aD58788B009]=	1;
        mintWhilte[0xfd6AFe0b7Da5D870c33490595040FD1a20868caA]=	1;
        mintWhilte[0xC71DA7095111d8D1F7CCB7e58624d66a447d1Fd2]=	1;
        mintWhilte[0xbDb2B258Ff6529818f7C80893e19c034586E9053]=	1;
        mintWhilte[0x9Fa67D11E87a65232573910bAc5Fe527F549c34A]=	1;
        mintWhilte[0x7447DEC5D64c849d45953dC72dB8C1F15E2b14Cb]=	1;
        mintWhilte[0x28E8465D251A0EeF4292d7D6Ab437e2Cf69f9AD5]=	1;
        mintWhilte[0xB2DfccF8910c034c34659c72587c3a116E6d924e]=	1;
        mintWhilte[0xBBC248b79E5D3204Bb8ceEA5aF516cEb405081eC]=	1;
        mintWhilte[0x948a4dBDaCCB4D10b9395B4C863D34E335e3eb21]=	1;
        mintWhilte[0x875a41a733a99e16888e3B03dd910aBd492A933f]=	1;
        mintWhilte[0xA19113e89F8e4E93653Cc11764F249ACE0d63906]=	1;
        mintWhilte[0xd67484A3398F9fBeA5CAEd467BA7e7503D796E87]=	2;
        mintWhilte[0x51d9E4137b08A0c740E3c5F1ef87dfE0FDe546ba]=	1;
        mintWhilte[0x580Fa12aB37F5b20fAb0B4047f5E804aacf818EF]=	1;
        mintWhilte[0x2b2D27335162921fBC2af7137b28eC534b5036Ba]=	1;
        mintWhilte[0xE4b13063D9eC56ccc288917727d144A6Ee4321ff]=	1;
        mintWhilte[0xcd0349921Bb1c07FB571D8c4fE991AdB161eD27B]=	1;
        mintWhilte[0xC655867a8228a80E64fc7DB2B56087291C868770]=	1;
        mintWhilte[0xA2748F27337fd30067DE6CD262A31f49aFa77686]=	1;
        mintWhilte[0xcB32791E8d4EA333174291659f60589939Ec70D7]=	1;
        mintWhilte[0x0057CEDF7a43333788f292d8C08B5A9F637098e9]=	1;
        mintWhilte[0x1b015F4306a5EbB402250866e6c986bdc82791e2]=	1;
        mintWhilte[0x4dbfce0D1e297524631B6a26852572380Cd56aAD]=	1;
        mintWhilte[0x401827EFeAd80Be23f5F0533BBC2CD9CF2e4F9D8]=	1;
        mintWhilte[0x8E717956a6e81cF5619f38aD26dd9a870f547a54]=	1;
        mintWhilte[0xE97c50c20740A4A6967757BF52074a0c3295A75f]=	1;
        mintWhilte[0xBcE71171E49FE108b027e53f128f8DE2f18CCd7C]=	1;
        mintWhilte[0x90921fC9aeA2f5bf5399B543Ef7b7778E877F691]=	1;
        mintWhilte[0x4AadE9eF175A61E008473ee8965eB6754F41c213]=	1;
        mintWhilte[0x8f13B78D91216932dC0Dc3367089650B4B5616a1]=	1;
        mintWhilte[0xE822FdaF5C84fFd93D2324C9d55944c7e47eD720]=	1;
        mintWhilte[0x58565bcd7692A9de5bA491c61ac1EaF31c3a1DA1]=	1;
        mintWhilte[0x907768DB7db809D439C79c201c3522Ce1eBc5b44]=	1;
        mintWhilte[0xA0F681Ce0e3584e5d081dA8266D7A5635bf13888]=	1;
        mintWhilte[0x42f025eE2B6f6508cdbDc1fe4BcB5Bc0c00E24a4]=	1;
        mintWhilte[0x41F3cbBaA1EDA77EccE61E3f6814a843f77CD1eD]=	1;
        mintWhilte[0xED8FF0E9C83DA7fFb14E09311665BD1a417682b1]=	1;
        mintWhilte[0x4e28c4F8DE1525dFc2b3387C4006F85BbB64708c]=	1;
        mintWhilte[0xa417C8b60b09869209f166D598724C4F8a530478]=	1;
        mintWhilte[0xf0Bdf8A620c17f3f08fA61c1B5Dc7A232f97A7f7]=	1;
        mintWhilte[0x4648FF0af5532ea92F40615DCb51eDf581F706Ea]=	1;
        mintWhilte[0xfA6E11483982747fff5a123bb13638713652BFDb]=	1;
        mintWhilte[0xcA0B16abD851c2B0D59073fd96b1Cd5dEfc89Ccb]=	1;
        mintWhilte[0x0D7590F4A94680b1DCef8123dad6678854B50622]=	1;
        mintWhilte[0xcf230B433379dfa3A557A7741D134Fb444b902a5]=	1;
        mintWhilte[0xa48BA4C1aEbbb4427BdD032a506eF5D5446f61D2]=	1;
        mintWhilte[0x73fDaeF9c2b3857c4D49eE750Ef466648b95680e]=	1;
        mintWhilte[0x08f92d6D1D2a862C15369fC1B05bE8EC126386a7]=	1;
        mintWhilte[0x6088c4A16B6C8731aa0d1df3Eb524fF0CE04916b]=	1;
        mintWhilte[0x2E0f46d26e0C0420d5E73524affa5F72df30fE27]=	1;
        mintWhilte[0x1EbDe0d2e17462E28244886c76f2E8D8Cd075095]=	1;
        mintWhilte[0xE2E240afF6927115D23d0E67D6A7d142D11752f8]=	1;
        mintWhilte[0x4E7D9C01FD6a497db264752dF7B9eC4C565B6448]=	1;
        mintWhilte[0xcfde83f65891adbaddfE6DD395eFb8efcfD85Ce8]=	1;
        mintWhilte[0x773703D93607082709E745B807161580CB72aF2B]=	1;
        mintWhilte[0xFb4F33012C607e846057d17889a8D95323dd3882]=	1;
        mintWhilte[0x802012a6c84101315B40b55d2D5b912c28f14De1]=	1;
        mintWhilte[0xBcd66a2FfCc6f1931e61f901BC146b8466Db15Ae]=	1;
        mintWhilte[0x77a2D98721D211394cBCb3Fcb9FD5b1CAFAAeB90]=	1;
        mintWhilte[0xc69DA45B660578dd31A0792348951Ba22C169Dc0]=	1;
        mintWhilte[0xA9c203BFc8c49F257ae4d320a27aC1C5e0fA718B]=	1;
        mintWhilte[0xE2d0F39fC9626652813660fEB9f55FB79aB1d997]=	1;
        mintWhilte[0xF4801e46DCFCe67D4a297F2a4C9b3D6632916dee]=	2;
        mintWhilte[0x03BD4a6F16B4a0c2d992e6975EC15a6Fd05bcb23]=	1;
        mintWhilte[0xb89E778488cAf4A3ae2639cEcfD3Fdba77fEb83b]=	1;
        mintWhilte[0x8787339B747068818671147978100c83DcC6c7Bc]=	1;
        mintWhilte[0x507e9Bf86EE868B46192b5ce9955dC23727B396D]=	1;
        mintWhilte[0x5e2b61716f7aE2Cc9A414671EA6AfF0880Be6560]=	1;
        mintWhilte[0x2A399a5047eA4D9cbEd8C22bbD7C9C012279CD49]=	1;
        mintWhilte[0xE10ab320e4563251e1053B9a86B06De6C67f3BaF]=	1;
        mintWhilte[0xBB60c89e3765e8180631798053Dd9904498B86D9]=	1;
        mintWhilte[0xb6E6f0cCAE2B7D445548a85e1bAC439E69B3086c]=	1;
        mintWhilte[0x1743842613F514ad417A195366f00BABa2c2C2B6]=	1;
        mintWhilte[0x2A6c8619b930e5ADd85dcf8d3A3872EB26717a41]=	1;
        mintWhilte[0x029642D4960085B7b29894AD10878EE2Fb905541]=	1;
        mintWhilte[0x5b197E3eE6770518f6F2735274522F48aBd69864]=	1;
        mintWhilte[0x7CFAC8F6543056ee3DF62FdA76F7184d65bcA24e]=	1;
        mintWhilte[0x9F06d7e9cEfd3092d18736d41Dc6DdA1673A9645]=	1;
        mintWhilte[0x1c76879485fC22B4A81850CCA1dA22B2b442652d]=	1;
        mintWhilte[0xe270E2c555d41eEcfDBB2999084bcD7FdC66623d]=	1;
        mintWhilte[0x351220a05e61918014CbBa276d2c4cFbfd6253B9]=	1;
        mintWhilte[0x962Bd7F457E8dED1De46370Ad01171b03a0b1A1c]=	1;
        mintWhilte[0xF4a8C0dB123E262906D525ae72eb4ACa4a5A7E1C]=	1;
        mintWhilte[0x0a12b24Fc0aA89F1199fb6712D7f92319EA0c3CE]=	1;
        mintWhilte[0x5Ee5CB77B6f175952F7307d3d37129E8aB2A23B6]=	1;
        mintWhilte[0x695BaBeA7f73c2375BE1782EF3cD3Dc7950617cB]=	1;
        mintWhilte[0x6e0b8037D09626310bd570f0690e275969bFd718]=	1;
        mintWhilte[0xB1b11aa1208B91adbbFB421CE39E8F618f9D8a62]=	1;
        mintWhilte[0x0268Aa1755B49FA115A81090B836f2B111A20163]=	1;
        mintWhilte[0xb0112f1832fEb15A9752368188601B043F0d3620]=	1;
        mintWhilte[0x91cA38192195Cb26A7BF78b6Eb7FD9F7c0c86708]=	1;
        mintWhilte[0xea63F69E65064bBF3304a8F4CeD6887A2a48D848]=	1;
        mintWhilte[0xc7A73a147620a28a347A198EAEBd632e22DbA635]=	1;
        mintWhilte[0x15B8b1cB48cC7A2A17A1646D98AF07A618F220c6]=	1;
        mintWhilte[0x02c13FB39AFA074e0eC9c654eE69BA8e2aa78781]=	1;
        mintWhilte[0x65b8879641d610105876c602Feb8c42507e1a5f1]=	1;
        mintWhilte[0x09a9794254F6bB232F9a668fEf74541bCe293E8d]=	1;
        mintWhilte[0x7f62A6c144422C49D322ab53ebe94081dcC7E0a7]=	1;
        mintWhilte[0x317944d8032eA3f9FFF97e44aAB24E402fF2625D]=	1;
        mintWhilte[0x9b4B81dB683D125c5F560AeA1051950f57873067]=	1;
        mintWhilte[0x0A9974eCC7B4E584Ee837e991A512fb5dD81FD59]=	1;
        mintWhilte[0xcE23758d451fa865C2BbC1D52114C7309F6b81Ce]=	1;
        mintWhilte[0xdE307dd55191bc640d16DA5412CEd06c13b5B192]=	1;
        mintWhilte[0x2717D3c51e7fbf351D3002Ff513d6871691AC511]=	2;
        mintWhilte[0x0aB15dA97fFD74f01B844cDEe6D6349D5b68ccFF]=	1;
        mintWhilte[0x25131788dFdf4CC97D1fBcDCE49B9C70e70d2487]=	1;
        mintWhilte[0xdd88DE83e1dB1A67a2F2866A7CD0d8C4ADfFB3d0]=	1;
        mintWhilte[0x7b29B2221533Ecb6AD0a3fb8669EEa27e2074750]=	1;
        mintWhilte[0xC9C415C2f8306EaffE0c76345AaBF197B6bC7e80]=	1;
        mintWhilte[0xEd9C9720c11988A06BaD18cda2249DE47b888888]=	1;
        mintWhilte[0x110F8C8e126877Afa489CcEbDbc3F472b9F8356d]=	1;
        mintWhilte[0x2b345b69988477CE630Ca4e7E1190f58EeAB23e8]=	1;
        mintWhilte[0x0966C999999000CcdDb2d578811495accF91C48C]=	1;
        mintWhilte[0x4E646AF12fFaE6C0FdE8aC048877382DDC867Ee4]=	1;
        mintWhilte[0xff87a8C90595171D06c92D6926dBBf43777CF7A3]=	1;
        mintWhilte[0xD5C748768b1d84bb0b7ac2E4070228176ee971cB]=	1;
        mintWhilte[0xFdceE5a6eE764Ff6BB391e960452427bcc5A89Cd]=	1;
        mintWhilte[0xDb541f612CfD33bBA956530898599B2e2B5bbb10]=	1;
        mintWhilte[0x42757Bc1C393bD70a3F68BFaA4416e10490fBEFF]=	1;
        mintWhilte[0x912758e337812Fd21A1C4F6f44e185F3Af2f7964]=	1;
        mintWhilte[0xfAc422aA3BCCC18390612FE46a84D74117c87E3e]=	1;
        mintWhilte[0xCDd94Ad6802dE4C27FBF57469206Af6921e70175]=	1;
        mintWhilte[0x92C5E46aDe769c07F793644D74cCBaD1cf6130e4]=	1;
        mintWhilte[0x5221AC9Bd3EC7477498D254bAFd85d4A23bea1B9]=	1;
        mintWhilte[0x74438F15220B2717611829BC506cCAEf2DAeDefd]=	1;
        mintWhilte[0xD3b2De95969dea9C47b4Ed6332E98dB91d6F485D]=	1;
        mintWhilte[0x51c47Df1673590c1922E970bAa513890303E0830]=	1;
        mintWhilte[0xaB47742968dEE0c09459b56AD99176f32E856b57]=	1;
        mintWhilte[0xd72e4ec7899A3273694B191314A226CBC70232dD]=	1;
        mintWhilte[0x80A77202848BD27E1b52d0ab7718f778716BE01b]=	1;
        mintWhilte[0x1C4FdA2b9a8A05c2e73486F8b67397c0a0C4A95B]=	1;
        mintWhilte[0x6B218Ed0B9D8D5C3b56e8f3AD30943a51da9c840]=	1;
        mintWhilte[0x3b30420eEBD8077320AAc0035A5dfd62Fd087569]=	1;
        mintWhilte[0xd76B91E6DEe9a582b985f22c38C2819869AAb6eB]=	1;
        mintWhilte[0x871c01E825D9d40a155421da6c2DE7d04FAB8956]=	1;
        mintWhilte[0x3DA831747fa8dE35010980643A9c38DF60b7C0DA]=	1;
        mintWhilte[0x57f0E19b71fb8f4deCf9bA4B48000B605A10baD8]=	1;
        mintWhilte[0x52191A849f74da965216b357472dEFFC8BD546Fa]=	1;
        mintWhilte[0x0766888ADAF83AeeA250865b2273d619DE133cDd]=	1;
        mintWhilte[0x2A9D7781014b23f4d96988C701783283371B7f15]=	1;
        mintWhilte[0xF0AFA9b03c17C6A51CbaDD8a0d17d9Bdd836eAe0]=	1;
        mintWhilte[0xB8aD8588aA52c277C34686DFeCda35F72D237946]=	1;
        mintWhilte[0xA48130687F304Fa383E247fAeA2F9EE3D2A03d31]=	1;
        mintWhilte[0x9D37c017240b54F374d7672062D40046DB36Fcf0]=	1;
        mintWhilte[0x2ed3178AB0566b81CAe5b504F1A38Bc5d18D719c]=	1;
        mintWhilte[0x51Ac4E9ed6b7bda4066A260984B94E1f90c21A73]=	1;
        mintWhilte[0xAdee0da8219Cfb4b44750c8f00a3f389259CC746]=	1;
        mintWhilte[0xB052E8baA57C85c35722d4ad7c3AAdD40f520370]=	1;
        mintWhilte[0x3EAe9e92AAa8C0a8dAb1844a54125f18E592682E]=	1;
        mintWhilte[0x5750C56094E65E7Ae3BA7925ec9B439465756635]=	2;
        mintWhilte[0x451E6C69969bD04477c8DABBA09E3670852CE485]=	2;
        mintWhilte[0x79a752ad1CAFdCb189EA5A8d25bb112C57e767d9]=	2;
        mintWhilte[0x5E3A437412b980528211227F62A2fa6Ea71B4375]=	2;
        mintWhilte[0x6047eB37d54cc9D98b84b837A85Bea37Aa62243f]=	2;
        mintWhilte[0x19d58FC348da79860DE94890B6D7B2dE90dF143b]=	2;
        mintWhilte[0xbd0DF52CeEC010C9366A6Ef0871C590B59842A7B]=	2;
        mintWhilte[0xcF0EF234b1917a50B7d59c10e043bbc4C80E03c1]=	2;
        mintWhilte[0xF7F17A067d766A71f2a6242062C0Ef5D944abe62]=	2;
        mintWhilte[0x34f1B0a25378CBF34F70EcBABF81b75A1D22C71B]=	2;
        mintWhilte[0x4C0d64c20F0f04AC3d6D61D01959d6229ade8F50]=	2;
        mintWhilte[0xd43CA54a0f4aF7228A416e8F65e0778E08581075]=	2;
        mintWhilte[0x330a3195703828Fbc96e474d8F06E984F5134F98]=	2;
        mintWhilte[0x5469f22Fc52ad7a5E1f430A75B1Cbd542393DFB0]=	2;
        mintWhilte[0xb9fE1E88622e712546Ef7D0d9dc00DbA25282A93]=	2;
        mintWhilte[0x520916d5a176cD0fbDFBfCC1dDF2Eb844Cd6Bc8c]=	2;
        mintWhilte[0xa7e00BE3502860762639D7E531aD1D35D79E78aF]=	2;
        mintWhilte[0xD754b639c6B1a266d852db335518aa0426A19595]=	2;
        mintWhilte[0xb12A9051C885930879DE7b457e25C176D63C54cf]=	2;
        mintWhilte[0x25D0783B35395C078d0789464F59f556faC51f64]=	2;
        mintWhilte[0xeB1e80d75C738763F06a9F85D97C1F8eABfA8caF]=	2;
        mintWhilte[0x8E453FA4a51104Ea037ac7e77d3d494547C0306a]=	2;
        mintWhilte[0x6D1c8bA374A2896800E834e1317B29575acF56b5]=	2;
        mintWhilte[0xD02D2998ac219Da8f34fD517680BC1139f5F74Cb]=	2;
        mintWhilte[0x8c47aefBD4b3E629c4400eE188C9564A1a0010C1]=	2;
        mintWhilte[0x43326E75232dBe8746Db493d052138Eb93b2e9aa]=	2;
        mintWhilte[0x372894955A6F02510607e129f8286593Ccc5Df62]=	2;
        mintWhilte[0x9776D380d65C44361515Ca2440071265C664853D]=	2;
        mintWhilte[0x6421192fa04bF6922dF6D930D12F379a5bf71B02]=	2;
        mintWhilte[0x7dE76F509Fc8F007B726cE0451fb0ad62811fe94]=	2;
        mintWhilte[0xF2DA116f0757299892bfF3318831eF5ea3f5276F]=	2;
        mintWhilte[0xafAdAE26fd12fF67E449396a9fA5FdBF8C5bA07C]=	2;
        mintWhilte[0xf2DBbd56c198A7FB2Df3019eddc2f3021F30d63e]=	2;
        mintWhilte[0x46014290d380EDA76A3e823023E5E88026248191]=	2;
        mintWhilte[0x263a1DccCDCf59e7f62088D95040fcd1f1Eb9F08]=	2;
        mintWhilte[0xb2724A7726B16cD6Cf3ac05FD9A648B11ab596F5]=	2;
        mintWhilte[0xb904B9cF66796F9FFd668E766fe46230aCd26770]=	2;
        mintWhilte[0x23E11D776BC73Bf02d664B968D71C5D70E2321C5]=	2;
        mintWhilte[0xC94e02F11943b0cb17dAD8f01afF64a63bf5Ed0b]=	2;
        mintWhilte[0x5b959d707c11bFA3EC2926792E88f04c27F25F80]=	2;
        mintWhilte[0x677C0247FA5eE6E20a70FD22E5c16159d8421753]=	2;
        mintWhilte[0xF54142ba5eB190Ad5A7636A73db0A5fEe477059f]=	2;
        mintWhilte[0x829d46C06B779219D017BEdCd35B01a2FAc85Dba]=	2;
        mintWhilte[0x0954976227a59956D57D412193D3162C75DD78f6]=	2;
        mintWhilte[0x443c48f0B9A730891323B95Ba1a8ffABA1068453]=	2;
        mintWhilte[0x21420D01f605FaBA02Ff24ab7Da7DB9fE3816680]=	2;
        mintWhilte[0x0286a22F655F84c36Ff6C80eB566a5a4A8F07541]=	2;
        mintWhilte[0xdc81a1EdA7042c03B2Ab54Cd6A782C2Cfb8E110D]=	2;
        mintWhilte[0x4fc6fef94dD66287Fd939C09C4E3FAC0Bc709be7]=	2;
        mintWhilte[0x56673ae50FD445238C7998313B7EAc114eeed2c7]=	2;
        mintWhilte[0x8ad400C7A6db13159baE9c2bEa879501e981788D]=	1;
        mintWhilte[0xC05Fb066f8236eFD3A8dA4337289EF7c23fa2242]=	1;
        mintWhilte[0xd0cb82946fF53C247F1029cC47155A4Fd14d6492]=	1;
        mintWhilte[0x2c99fF2FF0793acEd830d8C267D8E713E67583F7]=	1;
        mintWhilte[0x20cF2351C22242EdA773962bf628bA2B02680923]=	1;
        mintWhilte[0x0059F1C0E81EdD78700847A70361128082dc461B]=	1;
        mintWhilte[0x50042aC52aE6143caCC0f900f5959c4B69eF1963]=	1;
        mintWhilte[0xb5b731F340554b672F686CA8459d55CED5E5bda4]=	1;
        mintWhilte[0x9B541D86F6108A5351dE01243736B190c59969b9]=	1;
        mintWhilte[0x61fd0D043d519F5A2bD05785000f30Db96809429]=	1;
        mintWhilte[0x9919C7c46E8e2f4bE8AcF348a66C763cB939cbA6]=	1;
        mintWhilte[0xA418dEa98e1e20c165713E7f681af815CEC4415A]=	1;
        mintWhilte[0xEe02a5B7399A6A86f234F5b5708B873fC210fd0d]=	1;
        mintWhilte[0x6C98702e96290DF3426F1535D694a866f385C375]=	1;
        mintWhilte[0xe87C30F71800c63528BE8A87F134FF0BB8888888]=	1;
        mintWhilte[0x46e52a6bB5178151C5B98dE52fC607860c84e8AC]=	1;
        mintWhilte[0x2e0cdF0eE1Ca1Ae20245E844D0Ee6B72079f867D]=	1;
        mintWhilte[0x19fd14Fd2546BDFbd54fa4E9C159D2F29B720c17]=	1;
        mintWhilte[0x6A53198fb773Aa86447579020e6C2B55B35DC314]=	1;
        mintWhilte[0x8081A75141dBC89f70d31eece08FF12cfe105e43]=	1;
        mintWhilte[0x96D130a9C11e3C67082E625844c9cf49aF78c8f1]=	1;
        mintWhilte[0x26062a8d42e77d05a7a15561723e0125e5b2536f]=	1;
        mintWhilte[0x1C074e9938072e9e039d7c619E9d91e8478C2Dc8]=	1;
        mintWhilte[0xb3Ad024E0d241e4fcdF1c0f7D0CAFF9547BF968d]=	1;
        mintWhilte[0x736EDa626AC4bb738cbaD7501E61e641425da1F0]=	1;
        mintWhilte[0x4836d33C3e237Ae9c1fFE20732030c5CDdAb9943]=	1;
        mintWhilte[0xF6C999409CcA38D653622A98Ed590900EBAE19ea]=	1;
        mintWhilte[0xc019845298DfC7BBAF7e841DCeA92E36CeD840d3]=	1;
        mintWhilte[0xDe9a9425b3CE28f66719eA606B1d1FDda210A94d]=	1;
        mintWhilte[0x30584e65Ecf824EE0CEC79AEa702ec69e429dcB5]=	1;
        mintWhilte[0xdB20ce8a9585494272BC08D1C33c9331D2Ff3A16]=	1;
        mintWhilte[0xA4ab062E5a7a4278496e098FE07aEf2C0Dbd1d56]=	1;
        mintWhilte[0xF5df35009EE3Def233936bc9C103F83CbeE1Eee7]=	1;
        mintWhilte[0xf9f713f8Ae26A5181Cac74ed6F64792cDeC6B57a]=	1;
        mintWhilte[0x1C94f91F20cCA4fb0A59DB3b27f05a59009aDE8C]=	1;
        mintWhilte[0xDe54227dC7cb1dE999979f21548096D92B64827f]=	1;
        mintWhilte[0x75C1bb4865cC86E83c6B988bFF61f14B22FeF47A]=	1;
        mintWhilte[0x98D14C337634E965e476381181aa64228Fa6f65b]=	1;
        mintWhilte[0xFD5b0928bB188F87C04D82A9CEE6A9987E6252a1]=	1;
        mintWhilte[0xb54ab6B67037FB46C27571C3D9F357885729AAD4]=	1;
        mintWhilte[0x6C758b6B261B4AE2331082a087d43Fcb25Aa7bE9]=	1;
        mintWhilte[0x010Fff6A31146261a13D18234807b4efB17629a9]=	1;
        mintWhilte[0xB8546dc9dBA305e6136899d4783CDe2efCf5F35A]=	1;
        mintWhilte[0xca0b67442c8D217FB4dbc83BD1cA98Cba4948366]=	1;
        mintWhilte[0x3972BF194DB3eCd4B5C3F6691069C83293f5eBbF]=	1;
        mintWhilte[0xb789e62B3b86909e7814475c21C2a55862a2Df8B]=	1;
        mintWhilte[0x1117382C910DD3d09C6d099a2BA7F887D02C744c]=	1;
        mintWhilte[0x07A22143b987a8927f9f01E223489878E09AD0fC]=	1;
        mintWhilte[0x74d54C06C8B4eFCDC0cf62983e7C2E8F9C63e3Bd]=	1;
        mintWhilte[0x74A88f17FeE5FDd1131c800DB72f599ccAd92996]=	1;
        mintWhilte[0x59E7BA0eD616Cb353e222b8f8AB432a581784e24]=	1;
        mintWhilte[0x102eee25298C409e6A06c4d977385DA65bE21eEC]=	1;
        mintWhilte[0x04EE22568B4ABBfF87a6827BC4f801b81D99146B]=	1;
        mintWhilte[0xbEC17f2c94b5f22AE980440201eB2DB95F12fc26]=	2;
        mintWhilte[0x45588d2AedD9a5075dfAF39EC3ceC63768865b2c]=	2;
        mintWhilte[0x100a5fcA7e386830f3353878B03206Ee55232f21]=	1;
        mintWhilte[0x82073224cbe41C196a79222A1451043aB74958B5]=	1;
        mintWhilte[0x1062C8369ab3A3898bBbdC6E22D7805c469B70b8]=	1;
        mintWhilte[0x49F7C899Ce95A1C3b5Bbe1b2d516f3b3227901aD]=	1;
        mintWhilte[0xAF0e59Fa1c58008549ADD4ae75c3b838c2910C2b]=	1;
        mintWhilte[0x2B702187d416796CE26086806886b7aD71Bfb09B]=	1;
        mintWhilte[0x95A0dBF4099A058cdAA78F15186A0d5c507B0d11]=	1;
        mintWhilte[0x368732EE2E4a1FE438095fb433Cd21982A2cCCD6]=	1;
        mintWhilte[0x568D19F28D550127577f3C371fC22A5514054968]=	1;
        mintWhilte[0x2C2811Db76aAE865f48A75381a3608Ea5c258888]=	1;
        mintWhilte[0x5A3ae212338d7A3070cB06d83B4a323dA975C606]=	1;
        mintWhilte[0x3bfcB57778b5bB457d15Ca514a40CaB0d11e8E15]=	1;
        mintWhilte[0x07760eCA15599988f72881C7710CBCBf42C7588a]=	1;
        mintWhilte[0x760c5a331fd9b11e8c4a236dD1096e7e109700e6]=	1;
        mintWhilte[0x4d2132c5C7602009Bb35796415838b92fA0cDA9e]=	1;
        mintWhilte[0xBaE039C848CaDd71669eBd32a1673722F014F241]=	1;
        mintWhilte[0xe883d47c481Cf4B47D97c4359C53a88B21Bd6e68]=	1;
        mintWhilte[0x1F896A5a23c244890abb3115Ac49336c82Fac0eb]=	1;
        mintWhilte[0x6f5b63615a4F111317277364C12506F3dA1DF783]=	1;
        mintWhilte[0x4Ff5443c51B9D1Dbf622b1f950ce19ac84b39521]=	1;
        mintWhilte[0x9E03EB454D58688334fA14e0D46252Fa2513A92C]=	1;
        mintWhilte[0x1CDeaf46BedE7252Ee3bdE7d7d9d07cb2338551F]=	1;
        mintWhilte[0x4eaCCB27aCf473dF6892dFa96F7B980cC945bB5E]=	1;
        mintWhilte[0x71e21bAdba767239244aF863BB0e3577008199Dc]=	1;
        mintWhilte[0x2BbdD18Ab034efa68d8e2C4f1c37877B36Ffc196]=	1;
        mintWhilte[0x94bB878C3c3E2f5A2455C7f9Bd7c0E5736a6510d]=	1;
        mintWhilte[0xbb28e17c8EA4789c86955d13065C6c2b4E2790c3]=	1;
        mintWhilte[0xCeCe5bafda337d3a98CCa669E022c751547Cc1C4]=	1;
        mintWhilte[0xd1b7Ba65398fFf9D581acf6aEB4CB80c216EF95A]=	1;
        mintWhilte[0x399177A907AEC6201449fFFE634e7eb87b3A25aB]=	1;
        mintWhilte[0x3B5cbeB873143b33e123E2355c010661CD132A84]=	1;
        mintWhilte[0xEF36A0434BD72a7d72f594F622aCa0C979841d1E]=	1;
        mintWhilte[0x839469C31b854B6E6A0c1e67e6183eBBdaB46456]=	2;
        mintWhilte[0xD5bb9A4898e3b232A8463e2765f713C2f2201122]=	1;
        mintWhilte[0x1f648b364A8c8cdc679D0C77e60fd263Fd1D9da8]=	1;
        mintWhilte[0x6d2113692857536b8993924D6B66d8409247fBb8]=	1;
        mintWhilte[0xcD4EB749367716B23c063197c34E625168b41486]=	1;
        mintWhilte[0x51b0eaB5e7aEF09d268d20d2C2C0c147220D6535]=	1;
        mintWhilte[0x8eEC1F006a75e883F8DCf57447f9707C6DD2B966]=	1;
        mintWhilte[0xBf32dcf7aA6eda1EF8504bc9baDE261A143510B9]=	1;
        mintWhilte[0x158C6EE50c68aeC1bB0E78C9534188C6A8f27FE4]=	1;
        mintWhilte[0x4F9f7e5cE597899B6249Ee527842c7B7CA760775]=	2;
        mintWhilte[0xf9091Ba435A41F0D461d896cfea6F5E78fFB475e]=	1;
        mintWhilte[0xa0751827DA7a5cE235D85694164382Ee8920648D]=	1;
        mintWhilte[0xA8Da9618CbbEA2bEcB1a060142437C439Cd2c33D]=	1;
        mintWhilte[0x05b27974688b1078A105c7f5BAdab65a5A41431C]=	1;
        mintWhilte[0xE0519F722Ccf626a93b1275E06f58855B8f9e75D]=	1;
        mintWhilte[0x37a8fD5f7f23fdff86eFC05b0EBc534A85D16280]=	1;
        mintWhilte[0x26e62C641A246bCb217D9eD48da8E0f411d60c8d]=	1;
        mintWhilte[0x1755Ce48f758B56cD570Def81Ef0834a5C18F7f3]=	1;
        mintWhilte[0x1bdc2Ee071e91D69CbBbC493876322eFeFbE55b7]=	1;
        mintWhilte[0xbE0003d9F744fA4cBedC40D17A271213bbB71569]=	1;
        mintWhilte[0x52b5D2aB4c1b5A44BECc8613bb17CB7F31Ee11A9]=	1;
        mintWhilte[0x1faabFAa25186bB26f1E5A3C7f9987179f939256]=	1;
        mintWhilte[0xE032BB48a496f87DeAb7E96Ca21360067e56A768]=	1;
        mintWhilte[0x4496Ea2847Bdd3f6fF966b533B75E4855D0BEf55]=	1;
        mintWhilte[0x58c959a4510E92097eE1697490167810C93Eb581]=	1;
        mintWhilte[0x0000000C01915E253A7f1017C975812eDd5E8ECC]=	1;
        mintWhilte[0xBd5297C562bB87c4195f191653e7b271182952d8]=	1;
        mintWhilte[0x99348D690DE2E481cd1Ef33F2dB5c2Cce9dd6c25]=	1;
        mintWhilte[0xf8771BA67F50c1b953e10Be0b303Bd87f7d4B91c]=	1;
        mintWhilte[0x43d26a2a8Aa7a3662D7f7844F1fF50677BaaFD9B]=	1;
        mintWhilte[0xE1ECf8b963ca999f523c4E3b232b75Ea2a643C52]=	1;
        mintWhilte[0xA8E22d51239aA2C18B1411537383FE997cFf067b]=	1;
        mintWhilte[0xdbe4998349547C35E7cFFE0C0235463fE1f61Da4]=	1;
        mintWhilte[0x185409DE5712DDe5065bfa7C75d1E66C55a2dd37]=	1;
        mintWhilte[0x74a237561B73847DAdB7Dc811f6Da5eF0251E5eD]=	1;
        mintWhilte[0x74816c29ABd655AD3F853907A35Ee16c723046fB]=	1;
        mintWhilte[0xF19a4b499ec6F2157Ca39DA7fe26Ee14305A90F8]=	1;
        mintWhilte[0x902bFDfd5E11E41Aae171B585c93ED7A8F194b31]=	1;
        mintWhilte[0x2cf6bEc5d7075Ca0e65dF857E0cDD9DbEF202D3d]=	1;
        mintWhilte[0x33256635B7d200Dc0a1dE51c9089D93C44A5A55a]=	1;
        mintWhilte[0x635eDbE10f73F956020C0ac016eA6d56B1101c72]=	1;
        mintWhilte[0x5016fC1Dc2Ef58FAFD741f0EFD91752d2b8CC155]=	1;
        mintWhilte[0x861943458343e7b7cfB0792273Ad91501C7C18e4]=	1;
        mintWhilte[0x7e5BeAB6d8d8105276994220F07ffaf783Ce6146]=	1;
        mintWhilte[0x8979ebDc6ecf41Eb61b254d8A1F6007569F8dE02]=	1;
        mintWhilte[0x5E32732da1e3e1E14F0d12aaF3120Adc83BDFAAa]=	1;
        mintWhilte[0x0e57cD2087Eefb82716181a9BAdc21A8DbD88258]=	1;
        mintWhilte[0x9522190011E4F3cfF52AD70be486C9ABA8888888]=	1;
        mintWhilte[0x8DeD14a0ed6e989e3bc3e62620a1EbE0b79adc97]=	1;
        mintWhilte[0x4Ed2F7EaDd13CdC339b67F371610bf26224E4B98]=	1;
        mintWhilte[0x8a4BDf8c0f7F78393e60873Fd4872b31F5B52802]=	1;
        mintWhilte[0x2c03F0770a30f8B7D01560f54f9c0cfB6AA86b1E]=	1;
        mintWhilte[0x2200133e4eC8e28b96170FdF7c38B816Da2AD922]=	1;
        mintWhilte[0x295321EF5103e5478E820513fee84585704D869a]=	1;
        mintWhilte[0x86040EC778eA632aae06c597870eD2C703aba616]=	1;
        mintWhilte[0xEE722b7977F55EF51D69e0279D56bb46f4b9CA0A]=	1;
        mintWhilte[0x149D7A4684ea84a38389Bd6C7f1bf5989285f83E]=	1;
        mintWhilte[0x1A51cF5904E20Cf7fc8dbE9e18e05E21c6D036FE]=	1;
        mintWhilte[0x665084F8c21bff391BF38F290Ad912b643EE6cd5]=	1;
        mintWhilte[0xAE2842A3e37dd2456539338Bdf4F814c41DA5550]=	1;
        mintWhilte[0x400c573D008Ce8e82FA21B12dc561F511f3fD336]=	1;
        mintWhilte[0x2964d30921c2AE14688a3cC6F3884f4f66387dBb]=	1;
        mintWhilte[0x644a40Cc841d64d13E2daB3B053FD83194f86E03]=	1;
        mintWhilte[0x6e01346BE21254A576d72Ace36c69C756b011Ee5]=	1;
        mintWhilte[0x25f874499695015Ca7900cB095f47Cd3F9C84FFa]=	1;
        mintWhilte[0x9094f4b1C4e4f0C2b705dC3400853B0A8C099E9c]=	1;
        mintWhilte[0x924F7B8c0e037467A37BdB7521753d6C45066a46]=	1;
        mintWhilte[0x2d28bF0B82888E0732A3E8a668bd3b58A44611EA]=	1;
        mintWhilte[0x70Fb1d019cC99b4867B21b2618110b2192E25C9F]=	1;
        mintWhilte[0x8411ca148e1F9D7366aF8F370B37b8fF448456E1]=	1;
        mintWhilte[0x7452441689A528ECE83e9FA954e99E60562f44AC]=	1;
        mintWhilte[0xa54eeD744E9a1Db0E564eB7D6c958453eC7346b5]=	1;
        mintWhilte[0xF19B003A34499073a29Eb44216Ac3b32dF6947ed]=	1;
        mintWhilte[0xc28531bdF80A349d35bA5ED98519c7cbb423cCdc]=	1;
        mintWhilte[0xEc1B48654640Ff3159cbf79caff494B3B6758669]=	1;
        mintWhilte[0x7632Abf23cBE29f964054F310175Bc3E34a92DF4]=	1;
        mintWhilte[0x8cEe01CAf1DEF1eC0B3A3025b853F6F1F25B7DdD]=	1;
        mintWhilte[0x1A5bCea8141ac40415783DAB2d87AA448440b274]=	1;
        mintWhilte[0x1459f68dcBFD75d9A8d99962d0D5d4A56544dCD9]=	1;
        mintWhilte[0x4988D104d6D0902812FA3b6BC66b2fF5a6FCe409]=	1;
        mintWhilte[0x35524A1a02D6C89C8FceAd21644cB61b032BD3DE]=	1;
        mintWhilte[0x1387F579625f2fa2F93136fF507290c08FBf3776]=	1;
        mintWhilte[0x77890268c4ecd8A99FB6DdfA6C1B905Eb1b4c05f]=	1;
        mintWhilte[0xfeB447606cD218D06D2A5BA3b888949d93Ae0C98]=	1;
        mintWhilte[0x31A5AeFB19296ADE74e4F137bC309af7cF76D63e]=	1;
        mintWhilte[0x3173242F40BdDd6a60FedCFb87033bDbf8767f2B]=	1;
        mintWhilte[0x9Cf56876aB74c1b90b5788bb31ACC969C36D9205]=	1;
        mintWhilte[0x3C01392E25CdC94d7d95a38C475a1E74C8fD5Ee4]=	1;
        mintWhilte[0xB80Dd86b6B2f01980dF11c31B665f1d7b67ABF77]=	1;
        mintWhilte[0xC85441828BddF079FEB17de13e81B779AB855827]=	1;
        mintWhilte[0xb800309deFe6CB08d3E92Aee2081962f5B02D473]=	1;
        mintWhilte[0x438B88B421F44EE1AB64282c579B8328970Ac2a1]=	1;
        mintWhilte[0x4b6Ef4Fe7549d71e3F9945F027a70E5Cb5cd8Cf4]=	1;
        mintWhilte[0x07E6E4FDC530b0AE09Bc21eE8Bbb7675137F6056]=	1;
        mintWhilte[0xa57cA364DcbEcbf1Fd485E55e1FDbe17E1388e77]=	1;
        mintWhilte[0x5151Db0B07DC855D2a211eBf66b39f2A886B7705]=	1;
        mintWhilte[0xB2bE2887A26f44555835EEaCC47d65B88b6B42c2]=	1;
        mintWhilte[0x8c14D46C920c877d296aaf34F5fC65fF6D8C01CF]=	1;
        mintWhilte[0xaa9fa7097b8c595F9F1fa582e5D3Bbe86F31A193]=	3;
        mintWhilte[0xE7A83036fC1c5E4A807260345E3607c0a836e4d9]=	3;
        mintWhilte[0x13eA13F2009c20C0e513743B1Fe6BB9E092B2118]=	3;
        mintWhilte[0x53827bbcf5b1317cE0b2c715feAD140B191f5Fd4]=	3;
        mintWhilte[0x73f330ac504a1b7F78089D657638cff0624ef99f]=	3;
        mintWhilte[0x9dAf7fe4636B0E8b61cFF1a50F66080F6154BFb4]=	3;
        mintWhilte[0x70511BFE07d9E9599A93d5a7B9F6e1C30fbeC695]=	3;
        mintWhilte[0x68AC44d37381a20D00c012917Fe48321B36bE9Ac]=	3;
        mintWhilte[0xa647F1f422BCE8225D9088C3AAfaaD08f5BdBe87]=	3;
      //  mintWhilte[0xa1c62aAFFa07d9a5296A5850a77f8B3fE07a5d0]=	1;
       // mintWhilte[0x6c59a2a8360E7F01B0833893Ff0a8E88981cbB9]=	1;
        mintWhilte[0x286b585E0614736aAA4cFEF9d1997485f10084a1]=	1;
        mintWhilte[0x0c15C31Df4D9c4667376C0cCDf8fF7D4f9ff2e5D]=	1;
        mintWhilte[0x001fA6f74C8eeaA372C8437a3BDd22b630d9a7B6]=	1;
        mintWhilte[0xDEf1EE78B4106dB660aB9CCde37C9571ab537fEe]=	1;
        mintWhilte[0x04628186efCB2331Fb87e71A389c2716c13b5674]=	1;
        mintWhilte[0x8338CEc8378beAe16B1050Eb2EfA9E68707C2C31]=	1;
        mintWhilte[0x7558899d8109D8a2CE457837ADE56C3d6eBFE90d]=	1;
        mintWhilte[0xAB2285c6C979fcd29ad6574d9cB3F395ce907212]=	1;
        mintWhilte[0x71f829e0592e908B9eAb4C3d0569Cd9c19c540a4]=	1;
        mintWhilte[0x1Be2b1356036986e8A3D9E6119d6297c75Ba1b25]=	1;
        mintWhilte[0x9ecf4ee93c6c453E2Eeb1Efa8D16d36f467A3EEF]=	3;
        mintWhilte[0xeaDE9C7AC1bad269B223546BECF6845Bd4691aE2]=	1;
        mintWhilte[0xFC773EF7C328F996b02baE1ca6A29C1eA32dcF99]=	1;
        mintWhilte[0xEd308A08B051dA28D59606D9Dd9a3dced7Ad188c]=	1;
        mintWhilte[0xeC9460Fd3e3886699b2a002bCF64952AAa94c000]=	1;
        mintWhilte[0x3407D4e4B536f3E49B9790E74DCC22cfDb0f6Bf8]=	1;
        mintWhilte[0x57e443a216371756515269fCb8B2CD447C47da57]=	1;
        mintWhilte[0x7870c0535a4133aA93E2c501cA235fD86C6D3e94]=	1;
        mintWhilte[0x1F2cea1b06C2E132bD1Ef167f2436C9B45BFFF64]= 2;
        mintWhilte[0x4f06b15D4c6bA89e9d61723cBdcdA72670a9598f]= 2;
        mintWhilte[0x1Af41a96BbaF348c3Ca582B65193aB4d9108a22B]=	2;

    }

    function airdropToUser() public  onlyRole(MINTER_ROLE){
        for (uint256 index = 0; index < airdropAddrs.length; index++) {
            
            uint8 number = airdropMintWhilte[airdropAddrs[index]];

            for (uint8 i = 0; i < number; i++) {
                wishDaMoContract.mintNFT(msg.sender,1,1); 
            }
            sq = sq.add(uint256(number));
        }
    }
    
    function airdropWhilte() public  onlyRole(MINTER_ROLE){
        airdropMintWhilte[0xdB62bb66B3E9C44d8D1E430652F7B3d142D5adfD]=	1;
        airdropMintWhilte[0xA38739712cF014D24C138Dab72100741578f5F96]=	1;
        airdropMintWhilte[0x28E8465D251A0EeF4292d7D6Ab437e2Cf69f9AD5]=	1;
        airdropMintWhilte[0x34f1B0a25378CBF34F70EcBABF81b75A1D22C71B]=	1;
        airdropMintWhilte[0xf2DBbd56c198A7FB2Df3019eddc2f3021F30d63e]=	1;
        airdropMintWhilte[0xaa9fa7097b8c595F9F1fa582e5D3Bbe86F31A193]=	1;
        airdropMintWhilte[0x77eDEe9576dA8ef19663695aC2450C81b09f3dde]=	2;
        airdropMintWhilte[0x4301E86691E3fced843DF47C923771a2e62204d2]=	1;
        airdropMintWhilte[0xebE703f2c381c2CE149C04b25fdce9D6C80Ec743]=	1;
        airdropMintWhilte[0x846b38bCA519a7cb24e06eDcA34FC73726C5E252]=	1;
        airdropMintWhilte[0x6484aDc0b8B109d37Fa0E379c8076399b2199645]=	1;
        airdropMintWhilte[0x021598c0EC2737d67c395E2934ED06eb5d5bfdd1]=	1;
        airdropMintWhilte[0xD0A466Ae559A0ab7eF73F5F991d4e7e3375C0d8C]=	1;
        airdropMintWhilte[0x711F6e7E7C2Cd6b704fD84Ac6A8A246df9b60FA0]=	2;
        airdropMintWhilte[0x8FF3b008A4a11acC37CF4215a59C031f44a8bAD2]=	1;
        airdropMintWhilte[0xf53cE28CEF2C421Df913b6bf7B91303BAdaD7301]=	2;
        airdropMintWhilte[0x06346348bc386F78c6BA7dDe9d880d31961A1B16]=	1;
        airdropMintWhilte[0x1ce95ffb8f0B030f419339A11dB470E4b5E910b7]=	1;
        airdropMintWhilte[0xB9c21C87777c844d93776089572dE5A17C9Ba158]=	1;
        airdropMintWhilte[0x05B4015Dbe1baDE9e743D2C8F90eABA8F27dBE3d]=	1;
        airdropMintWhilte[0x1fABFc435E6f85F9fBD30fE5CF950148Fbc9BDC4]=	1;
        airdropMintWhilte[0x4D300B561eA06aBe10D38ad05319E5D2eA641802]=	5;
        airdropMintWhilte[0xD8de315eB7A00f4155d1Ea9eb4eb6888Ae715631]=	1;
        airdropMintWhilte[0x190cCb392Ae47a1f9604464f17d5806970376937]=	1;
        airdropMintWhilte[0xE19e81a141FbE0b489b3901A2Cfa99f6d2FA039B]=	1;
        airdropMintWhilte[0xEBc11F115eFcE48Dff2C0C51aa4713E5cD7506dc]=	1;
        airdropMintWhilte[0x4DA5cafe52121280491b537c33cA19C0F914e482]=	1;
        airdropMintWhilte[0x82D9AAdda882A89FA15A6B0966a668bC054Ac28d]=	2;
        airdropMintWhilte[0x80eFaDf731A689096B7629F43EE292F9b11E2fBa]=	1;
        airdropMintWhilte[0xD83901BD980eA6271Af6D0061aDF931b00e156D8]=	1;
        airdropMintWhilte[0x63811fd3A975FB0b0E94FD25c3271e02a901B1ec]=	1;

        /*airdropAddrs = airdropAddrs.push(0xdB62bb66B3E9C44d8D1E430652F7B3d142D5adfD);
        airdropAddrs = airdropAddrs.push(0xA38739712cF014D24C138Dab72100741578f5F96);
        airdropAddrs = airdropAddrs.push(0x28E8465D251A0EeF4292d7D6Ab437e2Cf69f9AD5);
        airdropAddrs = airdropAddrs.push(0x34f1B0a25378CBF34F70EcBABF81b75A1D22C71B);
        airdropAddrs = airdropAddrs.push(0xf2DBbd56c198A7FB2Df3019eddc2f3021F30d63e);
        airdropAddrs = airdropAddrs.push(0xaa9fa7097b8c595F9F1fa582e5D3Bbe86F31A193);
        airdropAddrs = airdropAddrs.push(0x77eDEe9576dA8ef19663695aC2450C81b09f3dde);
        airdropAddrs = airdropAddrs.push(0x4301E86691E3fced843DF47C923771a2e62204d2);
        airdropAddrs = airdropAddrs.push(0xebE703f2c381c2CE149C04b25fdce9D6C80Ec743);
        airdropAddrs = airdropAddrs.push(0x846b38bCA519a7cb24e06eDcA34FC73726C5E252);
        airdropAddrs = airdropAddrs.push(0x6484aDc0b8B109d37Fa0E379c8076399b2199645);
        airdropAddrs = airdropAddrs.push(0x021598c0EC2737d67c395E2934ED06eb5d5bfdd1);
        airdropAddrs = airdropAddrs.push(0xD0A466Ae559A0ab7eF73F5F991d4e7e3375C0d8C);
        airdropAddrs = airdropAddrs.push(0x711F6e7E7C2Cd6b704fD84Ac6A8A246df9b60FA0);
        airdropAddrs = airdropAddrs.push(0x8FF3b008A4a11acC37CF4215a59C031f44a8bAD2);
        airdropAddrs = airdropAddrs.push(0xf53cE28CEF2C421Df913b6bf7B91303BAdaD7301);
        airdropAddrs = airdropAddrs.push(0x06346348bc386F78c6BA7dDe9d880d31961A1B16);
        airdropAddrs = airdropAddrs.push(0x1ce95ffb8f0B030f419339A11dB470E4b5E910b7);
        airdropAddrs = airdropAddrs.push(0xB9c21C87777c844d93776089572dE5A17C9Ba158);
        airdropAddrs = airdropAddrs.push(0x05B4015Dbe1baDE9e743D2C8F90eABA8F27dBE3d);
        airdropAddrs = airdropAddrs.push(0x1fABFc435E6f85F9fBD30fE5CF950148Fbc9BDC4);
        airdropAddrs = airdropAddrs.push(0x4D300B561eA06aBe10D38ad05319E5D2eA641802);
        airdropAddrs = airdropAddrs.push(0xD8de315eB7A00f4155d1Ea9eb4eb6888Ae715631);
        airdropAddrs = airdropAddrs.push(0x190cCb392Ae47a1f9604464f17d5806970376937);
        airdropAddrs = airdropAddrs.push(0xE19e81a141FbE0b489b3901A2Cfa99f6d2FA039B);
        airdropAddrs = airdropAddrs.push(0xEBc11F115eFcE48Dff2C0C51aa4713E5cD7506dc);
        airdropAddrs = airdropAddrs.push(0x4DA5cafe52121280491b537c33cA19C0F914e482);
        airdropAddrs = airdropAddrs.push(0x82D9AAdda882A89FA15A6B0966a668bC054Ac28d);
        airdropAddrs = airdropAddrs.push(0x80eFaDf731A689096B7629F43EE292F9b11E2fBa);
        airdropAddrs = airdropAddrs.push(0xD83901BD980eA6271Af6D0061aDF931b00e156D8);
        airdropAddrs = airdropAddrs.push(0x63811fd3A975FB0b0E94FD25c3271e02a901B1ec);*/
        airdropAddrs[0]=0xdB62bb66B3E9C44d8D1E430652F7B3d142D5adfD;
        airdropAddrs[1]=0xA38739712cF014D24C138Dab72100741578f5F96;
        airdropAddrs[2]=0x28E8465D251A0EeF4292d7D6Ab437e2Cf69f9AD5;
        airdropAddrs[3]=0x34f1B0a25378CBF34F70EcBABF81b75A1D22C71B;
        airdropAddrs[4]=0xf2DBbd56c198A7FB2Df3019eddc2f3021F30d63e;
        airdropAddrs[5]=0xaa9fa7097b8c595F9F1fa582e5D3Bbe86F31A193;
        airdropAddrs[6]=0x77eDEe9576dA8ef19663695aC2450C81b09f3dde;
        airdropAddrs[7]=0x4301E86691E3fced843DF47C923771a2e62204d2;
        airdropAddrs[8]=0xebE703f2c381c2CE149C04b25fdce9D6C80Ec743;
        airdropAddrs[9]=0x846b38bCA519a7cb24e06eDcA34FC73726C5E252;
        airdropAddrs[10]=0x6484aDc0b8B109d37Fa0E379c8076399b2199645;
        airdropAddrs[11]=0x021598c0EC2737d67c395E2934ED06eb5d5bfdd1;
        airdropAddrs[12]=0xD0A466Ae559A0ab7eF73F5F991d4e7e3375C0d8C;
        airdropAddrs[13]=0x711F6e7E7C2Cd6b704fD84Ac6A8A246df9b60FA0;
        airdropAddrs[14]=0x8FF3b008A4a11acC37CF4215a59C031f44a8bAD2;
        airdropAddrs[15]=0xf53cE28CEF2C421Df913b6bf7B91303BAdaD7301;
        airdropAddrs[16]=0x06346348bc386F78c6BA7dDe9d880d31961A1B16;
        airdropAddrs[17]=0x1ce95ffb8f0B030f419339A11dB470E4b5E910b7;
        airdropAddrs[18]=0xB9c21C87777c844d93776089572dE5A17C9Ba158;
        airdropAddrs[19]=0x05B4015Dbe1baDE9e743D2C8F90eABA8F27dBE3d;
        airdropAddrs[20]=0x1fABFc435E6f85F9fBD30fE5CF950148Fbc9BDC4;
        airdropAddrs[21]=0x4D300B561eA06aBe10D38ad05319E5D2eA641802;
        airdropAddrs[22]=0xD8de315eB7A00f4155d1Ea9eb4eb6888Ae715631;
        airdropAddrs[23]=0x190cCb392Ae47a1f9604464f17d5806970376937;
        airdropAddrs[24]=0xE19e81a141FbE0b489b3901A2Cfa99f6d2FA039B;
        airdropAddrs[25]=0xEBc11F115eFcE48Dff2C0C51aa4713E5cD7506dc;
        airdropAddrs[26]=0x4DA5cafe52121280491b537c33cA19C0F914e482;
        airdropAddrs[27]=0x82D9AAdda882A89FA15A6B0966a668bC054Ac28d;
        airdropAddrs[28]=0x80eFaDf731A689096B7629F43EE292F9b11E2fBa;
        airdropAddrs[29]=0xD83901BD980eA6271Af6D0061aDF931b00e156D8;
        airdropAddrs[30]=0x63811fd3A975FB0b0E94FD25c3271e02a901B1ec;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
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
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/extensions/ERC721Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "../../../utils/Context.sol";

/**
 * @title ERC721 Burnable Token
 * @dev ERC721 Token that can be burned (destroyed).
 */
abstract contract ERC721Burnable is Context, ERC721 {
    /**
     * @dev Burns `tokenId`. See {ERC721-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId) public virtual {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _burn(tokenId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Pausable.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "../../../security/Pausable.sol";

/**
 * @dev ERC721 token with pausable token transfers, minting and burning.
 *
 * Useful for scenarios such as preventing trades until the end of an evaluation
 * period, or having an emergency switch for freezing all token transfers in the
 * event of a large bug.
 */
abstract contract ERC721Pausable is ERC721, Pausable {
    /**
     * @dev See {ERC721-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        require(!paused(), "ERC721Pausable: token transfer while paused");
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
library Counters {
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
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
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
pragma solidity ^0.8.9;

abstract contract Initializable {

    bool public initialized = false;

    modifier needInit() {
        require(initialized, "Contract not init.");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

abstract contract Permission is AccessControlEnumerable {
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
 
    modifier onlyManager() {
        require(hasRole(MANAGER_ROLE, _msgSender()), "Forbidden");
        _;
    }

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MANAGER_ROLE, _msgSender());
    }
}

pragma solidity ^0.8.9;

interface IdaMo {
    function mint(address to, uint256 tokenId) external ;
    function mintNFT(address to,uint8 genera) external returns(uint256);
    function existsTokenId(uint256 tokenId)   external view returns (bool) ;
    function tokenDetail(uint256 tokenId)   external view returns (uint8,uint8,string memory) ;
    function getId() external view returns(uint256);
}

pragma solidity ^0.8.9;

interface IWishDaMo {
    function mint(address to, uint256 tokenId,uint8 source) external ;
    function mintNFT(address to,uint8 genera,uint8 source) external returns(uint256);
    function existsTokenId(uint256 tokenId)   external view returns (bool) ;
    function tokenDetail(uint256 tokenId)   external view returns (uint8,uint8,string memory) ;
    function getId() external view returns(uint256);
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

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
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
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
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
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
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControlEnumerable.sol";
import "./AccessControl.sol";
import "../utils/structs/EnumerableSet.sol";

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerable is IAccessControlEnumerable, AccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(bytes32 => EnumerableSet.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view virtual override returns (address) {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view virtual override returns (uint256) {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {_grantRole} to track enumerable memberships
     */
    function _grantRole(bytes32 role, address account) internal virtual override {
        super._grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {_revokeRole} to track enumerable memberships
     */
    function _revokeRole(bytes32 role, address account) internal virtual override {
        super._revokeRole(role, account);
        _roleMembers[role].remove(account);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerable is IAccessControl {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}