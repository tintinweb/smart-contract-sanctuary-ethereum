pragma solidity ^0.5.0;
/**
 * The FoliaControllerV2 is an upgradeable endpoint for controlling Folia.sol
 */

import "./Decomposer.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./IERC721.sol";
import "./IERC165.sol";

interface Punk {
      function punkIndexToAddress(uint256 tokenId) external view returns (address owner);
     // mapping (uint => address) public punkIndexToAddress;
}

contract DecomposerController is Ownable, ReentrancyGuard {

    using SafeMath for uint256;

    event newContract(address contractAddress, uint256 maxEditions, cT contractType);
    event deletedContract(address contractAddress);
    event editionBought(address contractAddress, uint256 tokenId, uint256 newTokenId);
    uint256 public price = 8 * (10**16); // 0.08 Eth
    uint256 public totalMax = 888;
    mapping(address => uint256) public editionsLeft;

    Decomposer public decomposer;

    uint256 public adminSplit = 20;
    address payable public adminWallet;
    address payable public artistWallet;
    bool public paused;

    modifier notPaused() {
        require(!paused, "Must not be paused");
        _;
    }

    constructor(
        Decomposer _decomposer,
        address payable _adminWallet
    ) public {
        decomposer = _decomposer;
        adminWallet = _adminWallet;
        uint256 _maxEditions = 88;

        addContract(0xB77F0b25aF126FCE0ea41e5696F1E5e9102E1D77, _maxEditions, uint8(cT.ERC721)); // 3Words
        addContract(0x123b30E25973FeCd8354dd5f41Cc45A3065eF88C, _maxEditions, uint8(cT.ERC721)); // Alien Frens
        addContract(0xa7d8d9ef8D8Ce8992Df33D8b8CF4Aebabd5bD270, _maxEditions, uint8(cT.ERC721)); // Apparitions by Aaron Penne
        addContract(0xa7d8d9ef8D8Ce8992Df33D8b8CF4Aebabd5bD270, _maxEditions, uint8(cT.ERC721)); // Archetype by Kjetil Golid
        addContract(0x842D8B7B08C154ADc36A4f1186A0f401a10518EA, _maxEditions, uint8(cT.ERC721)); // Autobreeder (lite) by Harm van den Dorpel 
        addContract(0xDFAcD840f462C27b0127FC76b63e7925bEd0F9D5, _maxEditions, uint8(cT.ERC721)); // Avid Lines
        addContract(0xED5AF388653567Af2F388E6224dC7C4b3241C544, _maxEditions, uint8(cT.ERC721)); // Azuki
        addContract(0x8d04a8c79cEB0889Bdd12acdF3Fa9D207eD3Ff63, _maxEditions, uint8(cT.ERC721)); // Blitmap
        addContract(0xba30E5F9Bb24caa003E9f2f0497Ad287FDF95623, _maxEditions, uint8(cT.ERC721)); // Bored Ape Kennel Club
        addContract(0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D, _maxEditions, uint8(cT.ERC721)); // Bored Ape Yacht Club
        addContract(0xfcB1315C4273954F74Cb16D5b663DBF479EEC62e, _maxEditions, uint8(cT.ERC721)); // Capsule House
        addContract(0x059EDD72Cd353dF5106D2B9cC5ab83a52287aC3a, _maxEditions, uint8(cT.ERC721)); // Chromie Squiggle by Snowfro
        addContract(0x91Fba69Ce5071Cf9e828999a0F6006A7F7E2a959, _maxEditions, uint8(cT.ERC721)); // CLASSIFIED | Holly Herndon
        addContract(0x49cF6f5d44E70224e2E23fDcdd2C053F30aDA28B, _maxEditions, uint8(cT.ERC721)); // CLONE X - X TAKASHI MURAKAMI
        addContract(0x1A92f7381B9F03921564a437210bB9396471050C, _maxEditions, uint8(cT.ERC721)); // Cool Cats NFT
        addContract(0xc92cedDfb8dd984A89fb494c376f9A48b999aAFc, _maxEditions, uint8(cT.ERC721)); // Creature World
        addContract(0x1CB1A5e65610AEFF2551A50f76a87a7d3fB649C6, _maxEditions, uint8(cT.ERC721)); // CrypToadz by GREMPLIN
        addContract(0xBACe7E22f06554339911A03B8e0aE28203Da9598, _maxEditions, uint8(cT.ERC721exception)); // CryptoArte
        addContract(0xF7a6E15dfD5cdD9ef12711Bd757a9b6021ABf643, _maxEditions, uint8(cT.ERC721exception)); // CryptoBots
        addContract(0x1981CC36b59cffdd24B01CC5d698daa75e367e04, _maxEditions, uint8(cT.ERC721)); // Crypto.Chicks
        addContract(0x5180db8F5c931aaE63c74266b211F580155ecac8, _maxEditions, uint8(cT.ERC721)); // Crypto Coven
        addContract(0x06012c8cf97BEaD5deAe237070F9587f8E7A266d, _maxEditions, uint8(cT.ERC721exception)); // CryptoKitties
        addContract(0x57a204AA1042f6E66DD7730813f4024114d74f37, _maxEditions, uint8(cT.ERC721)); // CyberKongz
        addContract(0xc1Caf0C19A8AC28c41Fe59bA6c754e4b9bd54dE9, _maxEditions, uint8(cT.ERC721)); // CryptoSkulls
        addContract(0xF87E31492Faf9A91B02Ee0dEAAd50d51d56D5d4d, _maxEditions, uint8(cT.ERC721)); // Decentraland
        addContract(0x8a90CAb2b38dba80c64b7734e58Ee1dB38B8992e, _maxEditions, uint8(cT.ERC721)); // Doodles
        addContract(0x6CA044FB1cD505c1dB4eF7332e73a236aD6cb71C, _maxEditions, uint8(cT.ERC721)); // DotCom Seance
        addContract(0x4721D66937B16274faC603509E9D61C5372Ff220, _maxEditions, uint8(cT.ERC721)); // Fast Food Frens Collection
        addContract(0xa7d8d9ef8D8Ce8992Df33D8b8CF4Aebabd5bD270, _maxEditions, uint8(cT.ERC721)); // Fidenza by Tyler Hobbs
        addContract(0x90cfCE78f5ED32f9490fd265D16c77a8b5320Bd4, _maxEditions, uint8(cT.ERC721)); // FOMO Dog Club
        addContract(0xa7d8d9ef8D8Ce8992Df33D8b8CF4Aebabd5bD270, _maxEditions, uint8(cT.ERC721)); // Fragments of an Infinite Field by Monica Rizzolli
        addContract(0xC2C747E0F7004F9E8817Db2ca4997657a7746928, _maxEditions, uint8(cT.ERC721)); // Hashmasks
        addContract(0x0c2E57EFddbA8c768147D1fdF9176a0A6EBd5d83, _maxEditions, uint8(cT.ERC721)); // Kaiju Kingz
        addContract(0x9d413B9434c20C73f509505F7fbC6FC591bbf04A, _maxEditions, uint8(cT.ERC721)); // Kudzu
        addContract(0x8943C7bAC1914C9A7ABa750Bf2B6B09Fd21037E0, _maxEditions, uint8(cT.ERC721)); // Lazy Lions
        addContract(0x026224A2940bFE258D0dbE947919B62fE321F042, _maxEditions, uint8(cT.ERC721)); // lobsterdao
        addContract(0x4b3406a41399c7FD2BA65cbC93697Ad9E7eA61e5, _maxEditions, uint8(cT.ERC721)); // LOSTPOETS
        addContract(0x7Bd29408f11D2bFC23c34f18275bBf23bB716Bc7, _maxEditions, uint8(cT.ERC721)); // Meebits
        addContract(0xF7143Ba42d40EAeB49b88DaC0067e54Af042E963, _maxEditions, uint8(cT.ERC721)); // Metasaurs by Dr. DMT
        addContract(0xc3f733ca98E0daD0386979Eb96fb1722A1A05E69, _maxEditions, uint8(cT.ERC721)); // MoonCats
        addContract(0x60E4d786628Fea6478F785A6d7e704777c86a7c6, _maxEditions, uint8(cT.ERC721)); // Mutant Ape Yacht Club
        addContract(0x9C8fF314C9Bc7F6e59A9d9225Fb22946427eDC03, _maxEditions, uint8(cT.ERC721)); // Nouns
        addContract(0x4f89Cd0CAE1e54D98db6a80150a824a533502EEa, _maxEditions, uint8(cT.ERC721)); // PEACEFUL GROUPIES
        addContract(0x67D9417C9C3c250f61A83C7e8658daC487B56B09, _maxEditions, uint8(cT.ERC721)); // PhantaBear
        addContract(0x050dc61dFB867E0fE3Cf2948362b6c0F3fAF790b, _maxEditions, uint8(cT.ERC721)); // PixelMap
        addContract(0xBd3531dA5CF5857e7CfAA92426877b022e612cf8, _maxEditions, uint8(cT.ERC721)); // Pudgy Penguins
        addContract(0x51Ae5e2533854495f6c587865Af64119db8F59b4, _maxEditions, uint8(cT.ERC721)); // PunkScapes
        addContract(0x29b7315fc83172CFcb45c2Fb415E91A265fb73f2, _maxEditions, uint8(cT.ERC721)); // Realiti
        addContract(0x8CD3cEA52a45f30Ed7c93a63FB2b5C13B453d5A1, _maxEditions, uint8(cT.ERC721)); // Rebel Society
        addContract(0x3Fe1a4c1481c8351E91B64D5c398b159dE07cbc5, _maxEditions, uint8(cT.ERC721)); // SupDucks
        addContract(0xF4ee95274741437636e748DdAc70818B4ED7d043, _maxEditions, uint8(cT.ERC721)); // The Doge Pound
        addContract(0x5CC5B05a8A13E3fBDB0BB9FcCd98D38e50F90c38, _maxEditions, uint8(cT.ERC721)); // The Sandbox
        addContract(0x11450058d796B02EB53e65374be59cFf65d3FE7f, _maxEditions, uint8(cT.ERC721)); // THE SHIBOSHIS
        addContract(0x7f7685b4CC34BD19E2B712D8a89f34D219E76c35, _maxEditions, uint8(cT.ERC721)); // WomenRise
        addContract(0xe785E82358879F061BC3dcAC6f0444462D4b5330, _maxEditions, uint8(cT.ERC721)); // World of Women
        addContract(0xB67812ce508b9fC190740871032237C24b6896A0, _maxEditions, uint8(cT.ERC721)); // WoW Pixies Official
        addContract(0xd0e7Bc3F1EFc5f098534Bce73589835b8273b9a0, _maxEditions, uint8(cT.ERC721)); // Wrapped CryptoCats Official
        addContract(0x6f9d53BA6c16fcBE66695E860e72a92581b58Aed, _maxEditions, uint8(cT.ERC721)); // Wrapped Pixereum
        
        // // rinkeby
        // addContract(0xF80B749e0d03C005b8EfB7451BC6552555556149, _maxEditions, uint8(cT.ERC721)); // Kudzu

        // folia
        addContract(0xDCe09254dD3592381b6A5b7a848B29890b656e01, _maxEditions, uint8(cT.Folia)); // Emoji Script by Travess Smalley (work 2)
        // rinkeby
        // addContract(0x95793c65c398D0a5EEb92d6b475f4E6a2044Bee1, _maxEditions, uint8(cT.ERC721)); // Emoji Script by Travess Smalley (work 2)

        // non-standard
        addContract(0xb47e3cd837dDF8e4c57F05d70Ab865de6e193BBB, _maxEditions, uint8(cT.Punk)); // CryptoPunks
        // //rinkeby
        // addContract(0x999426cb37bb8Ea786d3E24F6094004fad686f70, _maxEditions, uint8(cT.Punk)); // rinkeby CryptoPunks
    }

    enum cT {ERC721, Punk, Folia, ERC721exception}
    struct ContractInfo {
      cT _cT;
      uint256 editionsLeft;
    }
    mapping(address => ContractInfo) public aC;

    // can be re-used as an "updateContractEditionSize"
    function addContract(address contractAddress, uint256 maxEditions, uint8 _cT ) public onlyOwner {
      
      if (_cT == uint8(cT.ERC721)) {
        require(IERC165(contractAddress).supportsInterface(0x80ac58cd), "Not an ERC721");
      } else {
        require(_cT == uint8(cT.Punk) || _cT == uint8(cT.Folia) || _cT == uint8(cT.ERC721exception), "Unknown contractType");
      }

      aC[contractAddress]._cT = cT(_cT);
      aC[contractAddress].editionsLeft = maxEditions;
      emit newContract(contractAddress, maxEditions, cT(_cT));
    }
    
    function removeContract(address contractAddress) public onlyOwner {
      delete aC[contractAddress];
      emit deletedContract(contractAddress);
    }

    function updateArtworkPrice(uint256 _price) public onlyOwner {
      price = _price;
    }

    function updateArtistWallet(address payable _artistWallet) public onlyOwner {
      artistWallet = _artistWallet;
    }

    function updateTotalMax(uint256 _totalMax) public onlyOwner {
      totalMax = _totalMax;
    }

    function buy(address recipient, address contractAddress, uint256 tokenId) public payable notPaused nonReentrant returns(bool) {
        require(aC[contractAddress].editionsLeft != 0, "Wrong Contract or No Editions Left");
        aC[contractAddress].editionsLeft -= 1;

        require(msg.value == price, "Wrong price paid");

        if (aC[contractAddress]._cT == cT.Punk) {
          require(Punk(contractAddress).punkIndexToAddress(tokenId) == msg.sender, "Can't mint a token you don't own");
        } else if (aC[contractAddress]._cT == cT.ERC721 || aC[contractAddress]._cT == cT.ERC721exception) {
          require(IERC721(contractAddress).ownerOf(tokenId) == msg.sender, "Can't mint a token you don't own");
        } else if (aC[contractAddress]._cT == cT.Folia) {
          //mainnet
          require(tokenId >= 2000000 && tokenId <= 2000500, "Can't mint this Folia token");

          // rinkeby
          // require(tokenId >= 13000000 && tokenId <= 2000058, "Can't mint this Folia token");
          require(IERC721(contractAddress).ownerOf(tokenId) == msg.sender, "Can't mint a token you don't own");
        }

        uint256 newTokenId = uint256(keccak256(abi.encodePacked(contractAddress, tokenId)));
        decomposer.mint(recipient, newTokenId);

        uint256 adminReceives = msg.value.mul(adminSplit).div(100);
        uint256 artistReceives = msg.value.sub(adminReceives);

        (bool success, ) = adminWallet.call.value(adminReceives)("");
        require(success, "admin failed to receive");

        (success, ) = artistWallet.call.value(artistReceives)("");
        require(success, "artist failed to receive");

        emit editionBought(contractAddress, tokenId, newTokenId);
    }

    function updateAdminSplit(uint256 _adminSplit) public onlyOwner {
        require(_adminSplit <= 100, "SPLIT_MUST_BE_LTE_100");
        adminSplit = _adminSplit;
    }

    function updateAdminWallet(address payable _adminWallet) public onlyOwner {
        adminWallet = _adminWallet;
    }

    function updatePaused(bool _paused) public onlyOwner {
        paused = _paused;
    }
}