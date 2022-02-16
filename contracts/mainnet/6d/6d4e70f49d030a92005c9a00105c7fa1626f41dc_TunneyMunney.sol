// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// Royalties: Rarible
import "./@rarible/royalties/contracts/impl/RoyaltiesV2Impl.sol";
import "./@rarible/royalties/contracts/LibPart.sol";
import "./@rarible/royalties/contracts/LibRoyaltiesV2.sol";

contract TunneyMunney is ERC721Enumerable, ReentrancyGuard, Ownable, RoyaltiesV2Impl {
    address payable private constant _ROYALTY_ADDRESS = payable(0x85b23C39D500Dc9BbDDc5a06b459FEf027f2F9d6);
    uint96 private constant _ROYALTY_PERCENTAGE_BASIS_POINTS = 400;
    uint256 private constant _MAXIMUM_SUPPLY = 5000;
    uint256 private constant _MAXIMUM_PURCHASE = 20;
    uint256 private constant _TUNNEY_MUNNEY_PRICE_PRESALE_AND_WHITELIST = 0.32 ether;
    uint256 private constant _TUNNEY_MUNNEY_PRICE_PUBLIC = 0.39 ether;
    uint256 private constant _TOTAL_PRESALE_NFT_COUNT = 2067;
    uint256 private constant _PRESALE_START_DATE = 1644588000;
    uint256 private constant _PRESALE_END_DATE = 1645160340;
    uint256 private constant _PUBLIC_START_DATE = 1645624800;
    uint256 private constant _PUBLIC_RESERVED_COUNT = 300;
    string private __baseURI = "ipfs://bafybwibxnu3vjzxxnhx2xpzfpdcajgtngw3l5ipvci7nkan2hiwjpne5ve/"; // Initialize with preview base URI

    // Wallet Address -> Token allowance mapping
    mapping(address => uint8) walletsPresale;

    // Wallet Address -> Boolean mappings
    mapping(address => bool) walletsPriceExempt;

    bytes4 private constant _INTERFACE_TO_ERC2981 = 0x2a55205a;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdTracker;
    Counters.Counter private _presaleNFTsMinted;

    uint256 private _revealed = 0;

    constructor() ERC721("Tunney Munney", "TM") {
        // Start counter at 1
        _tokenIdTracker.increment();

        // Populate privileged wallets
        walletsPresale[0xc3f17178311899B068d0E2C86253E087DAB5ba8f] = 10;
        walletsPresale[0x92178Cdcf11E9f77F378503D05415D8BEb9E7bcF] = 10;
        walletsPresale[0x10a3d8178EE389208cBc5A5AaD05aA928a575C94] = 10;
        walletsPresale[0x659797d648C27c052aD95CBf7F8631f2FAD143c2] = 10;
        walletsPresale[0xb99426903d812A09b8DE7DF6708c70F97D3dD0aE] = 20;
        walletsPresale[0x810505953e7DB74b4d242773D797Ce15C68e0562] = 10;
        walletsPresale[0x08BB2f68B3A799337B14DE0f28E6E04f5DeF18a1] = 10;
        walletsPresale[0x65F65D1001dA3BAA411c5f5Fa4890713cE8f7F1D] = 10;
        walletsPresale[0x1010595F96Ab62b31BfeAc411Ec5f8f60DB5DC23] = 10;
        walletsPresale[0xA494876207Ae80D8669Dd347Fe11Fadae31c48E7] = 10;
        walletsPresale[0xe5d009bbcE5a5D7ab9c6c2B1b0A56F9B98297Cff] = 10;
        walletsPresale[0x740C569F20076F1D96be1222240d55A5eED29Df5] = 10;
        walletsPresale[0x88D78534Ccc1CA50070272E095788F9f35aD42Ba] = 10;
        walletsPresale[0x9d9B1A7be1CBA854bC4656Daa56A784b0ff056EC] = 5;
        walletsPresale[0x1fe1d8C07386d9605B548B575Fd16F3E9C5B8624] = 10;
        walletsPresale[0x60CED65A51922C9560d72631F658Db0df85BFf1f] = 10;
        walletsPresale[0x125e41f52D62464B3B57AAA2F24d7952359BAabC] = 10;
        walletsPresale[0x2931E2037376875555c0c247C66727fcA7F2648e] = 5;
        walletsPresale[0xbAfc553548242F0487a5370c54aB3048E826e514] = 5;
        walletsPresale[0xA41A4b84D74E085bd463386d55c3b6dDe6aa2759] = 10;
        walletsPresale[0xa3139f46A92cac9e5c445c5574BD10D522781037] = 10;
        walletsPresale[0x166EB9317E2540DFB7841a48a31Ba2eca5D4A9CF] = 20;
        walletsPresale[0x69E5eA08a0b708dE81906DB05B3F80644acE8D3f] = 10;
        walletsPresale[0xDd1F61E95CA9ec479de81f869921eD191DfeeBA8] = 10;
        walletsPresale[0xBcaa247d4E6678BC9D42114186c8e2dfC6b6c1bD] = 10;
        walletsPresale[0xfDc319B1327DE28C82BB283610dAFcF736a6D229] = 20;
        walletsPresale[0x0d74759D78B3A25E3c537FC3116D6f20Eb1C6dE6] = 10;
        walletsPresale[0xef30776Cd1A6cF63Acf9F72C7BF47Bd6272Ec4F9] = 10;
        walletsPresale[0x282F9b62a7Efe70eE66FF45578D22a72A3e18e01] = 10;
        walletsPresale[0x5Db6f7C9Ef71069216a176bbE6dF7f02D0fbDEfb] = 10;
        walletsPresale[0x48A75020408740589a9Fe6f7341c1B3c32d11AB8] = 10;
        walletsPresale[0xa269d981A584f6e122c4067Dfb1aA12AB1f2b38D] = 20;
        walletsPresale[0xe59E3d516f52c2E393F27232D163E51fcdA1cFe5] = 10;
        walletsPresale[0x67cf9c01afFEfaB6F99b706096bC36037f8D57c2] = 10;
        walletsPresale[0x221320D34800760E06B206aCd01e626e463eB03E] = 10;
        walletsPresale[0xc3A51fFd872d38737973EE0bbA6ffc14502a4ced] = 10;
        walletsPresale[0x7ca42F73F80C285bbE93d72f6DdEf00798e304D9] = 10;
        walletsPresale[0x44b1f231D743B9b73AaD305Fe307ce6f099c9AB4] = 10;
        walletsPresale[0xFd61F8599431ebff62DC81eFc571C1FBCb908DCF] = 10;
        walletsPresale[0xcBA88D0E47673352BdBe3Ce9788DF97bAfdC7DDE] = 10;
        walletsPresale[0x5583734DCAFc257581cc3a089C29C68aB440Da58] = 10;
        walletsPresale[0x2054B81AEd12840A17EA1fc66D233ba5B921b77d] = 1;
        walletsPresale[0xEA2761F45d274E4e314cF0Aa1A3304fD1fa69e68] = 20;
        walletsPresale[0xf1FE82F8ba582a7c3e10473C0F964C61A165CE08] = 10;
        walletsPresale[0x5Cb58a3fA9B02ae11f443b3Adc231172356EcCd7] = 10;
        walletsPresale[0x04513dc3DcdEA1A570EDe00273889F12a3f91589] = 10;
        walletsPresale[0x11b0B2DB7F2A85A8FD52917f586A278A1dBa3747] = 10;
        walletsPresale[0x7a8448C623DFD441C9B725bFAB8a002DaC25Dc75] = 10;
        walletsPresale[0x37CD8223Da1Be068Ab6BD9dE805431999EE89871] = 10;
        walletsPresale[0x49ca963Ef75BCEBa8E4A5F4cEAB5Fd326beF6123] = 10;
        walletsPresale[0x0851CeD43aab7Bc38b0fA4fBc4e3849634d2cA67] = 10;
        walletsPresale[0xAD35cAE6192acC0000b3cD2E07CF5108AF9fD015] = 10;
        walletsPresale[0x17410AC8E1e7C0296d3d1EE82C2bcE9Cf5250a5c] = 10;
        walletsPresale[0xA6EBe8639FCb0235dE905212c7ef0E2E8bb92989] = 10;
        walletsPresale[0xC914646a35786335D1226281D49edbf2d5d10485] = 10;
        walletsPresale[0x2002480606e08351B75682866642e947BD8C6bcf] = 10;
        walletsPresale[0x1adF685E4714f7c516b7bC813b3148e68bd8095c] = 20;
        walletsPresale[0x042EBfe134790c0f4e8A3699797Ac2D0833755B7] = 20;
        walletsPresale[0xB009aD5322412730E909CFC27B33c410C2B3D2Aa] = 10;
        walletsPresale[0xeF5AFBa8ec7258F96Fd7794717747AB4edD7605D] = 20;
        walletsPresale[0x0989A2A165fd66E4c64510328A1A6A9809Ef9418] = 10;
        walletsPresale[0x3EBCcC002Ff8aED4e982F0011fC2090799F844e0] = 10;
        walletsPresale[0xf2C8797A4815002f62007BB43a5462Aeb6c0b7b9] = 20;
        walletsPresale[0x070B0700bc42F080b970A58e592bCfb0357d11Fb] = 100;
        walletsPresale[0x61c3476D99E6fa4b66c5D7d46738e0EF6049C844] = 10;
        walletsPresale[0xA3f1b25bD254A0fb0CAA6c1a784a120da49F99EC] = 5;
        walletsPresale[0x4E05Bc165652140654e0F07b7cB429E5E1B0ed92] = 10;
        walletsPresale[0xB9E651ab75e2CE8a292F60a37d258F8BbcFF4368] = 20;
        walletsPresale[0x0a159aE5b783545D328d7799D523961D5Cc47eA0] = 10;
        walletsPresale[0xB5696E4057B9BA76616cEcB5A537eAcA7B3CDf54] = 10;
        walletsPresale[0xF349CC68cF9820247E3f7465fDaD807b6FbCA3CD] = 10;
        walletsPresale[0x993a69EFE73e3f87df4276E40E81E426385Fd2D8] = 10;
        walletsPresale[0x46aB683c6D4f42666826Bf6D6Da1C131B71318d8] = 10;
        walletsPresale[0xB8e52606BDa86d031f7c8E2D73C95cD020002F03] = 10;
        walletsPresale[0x5F4C5ef5Be53Db7631d5257348BBcD354159269A] = 10;
        walletsPresale[0xa4c36e63cAa42cAE77f7A8f72b9f4dD7f5740a05] = 10;
        walletsPresale[0x80f176A4009d91bAdA3ace15692418990Be8B0a7] = 10;
        walletsPresale[0xfBA32e383CF23992249ac0E5B113bc4d092bb668] = 10;
        walletsPresale[0x11C331c574C4F6a97B596fDf17266EBB7f0aCb91] = 20;
        walletsPresale[0xb5771A5cBE3fbf377c4969D58fcec943C898a905] = 10;
        walletsPresale[0x3AFe0eb50CFd574E260ea1f99dBBCA4FFB384E0e] = 10;
        walletsPresale[0x180c7F25A4DBA3310cC3746619256d1EDA5a4F5A] = 10;
        walletsPresale[0xA883B60C5EaD0EFD604b41a7C0509c3c6b81739e] = 10;
        walletsPresale[0x54296Fe0C5eB70bA5D893e744733ebB9846ece72] = 10;
        walletsPresale[0x0277278833e8A40197dF5D54fC425D123b0dc6D1] = 10;
        walletsPresale[0x572Ec7691b6aE768fD71098bf815785A7BAE6480] = 5;
        walletsPresale[0xA75323816443d49a1142f4E8d84F579bBc1B06fE] = 20;
        walletsPresale[0xa802d76BBc1adEB3aF9F8a73114856D39D52b4f9] = 10;
        walletsPresale[0x91F1d086B83584b5da60eC8c426c8f7b1023F42D] = 10;
        walletsPresale[0x12331ABA9762b52b69109a06B84F6404B75BB478] = 10;
        walletsPresale[0xe51BA9BE3751eff989e53e9d234915db2dFFFAb6] = 10;
        walletsPresale[0xcEB0eF1bA3F3A543ea13cD6953A1c5978C5BFD14] = 10;
        walletsPresale[0xFd61F8599431ebff62DC81eFc571C1FBCb908DCF] = 10;
        walletsPresale[0x3F1A421b47c5a9ec1025475a3Fd3e99cE20616A2] = 10;
        walletsPresale[0xF80CD8714d092771e6D95DB5ba7Cc5ae960948Dd] = 20;
        walletsPresale[0x2C79A929a7b6dBaC83bE6690F69737D873c58941] = 20;
        walletsPresale[0x3C2175a86eaffac2Ea609Ab4db6aB8e27Ff56Db2] = 10;
        walletsPresale[0x363e89408093719f67b7a674B74006989442116A] = 10;
        walletsPresale[0x5C27b3a3D46D8728f0eeEB9342F50AA13A27ff5f] = 10;
        walletsPresale[0x8097222c73362cD7F9f313aA720bB85A0FCA3C3c] = 10;
        walletsPresale[0x1e8eAA773F43844813F0842E15ac9B1fd40A2d92] = 10;
        walletsPresale[0xA98220f6dC5DFcA27ff19605a0a6D3E1dDE4CFE8] = 10;
        walletsPresale[0x9B7d8DbD54e5aeBbEDdb1722C9aB8956Bc2003A5] = 10;
        walletsPresale[0x19F87442CC618751406fFC37cc1A0e6111071030] = 20;
        walletsPresale[0x16faDFebD498813B63fBcd399571fbf1Cfa86550] = 10;
        walletsPresale[0x07cd101a8cd329a170d3A762d9d1645A2adB7f7A] = 10;
        walletsPresale[0x32d29de590eC186eC5B28710E7659D5Fb18419C0] = 10;
        walletsPresale[0x838d673258CEAb8E78c31a6088227DAc593B2d72] = 10;
        walletsPresale[0x18A0e52AD9d827E7BCb456f70888B45854dCf099] = 20;
        walletsPresale[0xbca572D1928b34Cf2e86b32295Cd27ff71A554Bf] = 10;
        walletsPresale[0x02aEB12821C2c18A61373B1931dE24b0c4f2e7f0] = 10;
        walletsPresale[0xc8d5E6d8da7792006D75BEE8856Af73037e20291] = 10;
        walletsPresale[0xAf2F83b3C5086BFa613A00f1637a920b50230e27] = 20;
        walletsPresale[0x056F154C822cB374508Cd318038C3d1e1230c377] = 10;
        walletsPresale[0x23CAF6c7BA9C315569Dba9A0B33265c58eEF020D] = 1;
        walletsPresale[0x85b23C39D500Dc9BbDDc5a06b459FEf027f2F9d6] = 25;
        walletsPresale[0x672E5F3D8f007826C64Fce3644938f596fB521E1] = 10;
        walletsPresale[0x2d15e7F2061eBdf16B37c62Df4ae2d3550a1617F] = 1;
        walletsPresale[0x3599564B917588C2a42C365B306dFDF6c34BBb55] = 10;
        walletsPresale[0x67644b68B24505c37EEc4Ed070C7fd78Aa560777] = 30;
        walletsPresale[0x4bd8FA4995a6C6CDe085e044cd09194Dc8CF533f] = 40;
        walletsPresale[0xFC5446EfE679f109f2772e45EA623CaA63791d5e] = 10;
        walletsPresale[0x091B9eC195247d5226cFC23D4d2F919B053B07c1] = 10;
        walletsPresale[0x195d76F290E660D56e25515a982C77EE4aaE7Ed1] = 10;
        walletsPresale[0x0925af5b3A31B6458357E8B01804B0a598c55bdD] = 20;
        walletsPresale[0x23Adbac7540eb3E7ab100FAb282fe006d5D72073] = 16;
        walletsPresale[0x7894c47148642C4396D9CE2929d8603Fb48Ad22A] = 10;
        walletsPresale[0xE3e97ede6F9995331A665687509be4Ecc5292cf4] = 10;
        walletsPresale[0xb8e01f384E385A6E1F0f37d0BE3aB39945A09F43] = 10;
        walletsPresale[0x73f7Ad858ae331C91BFDF9BBAE5E1b8A13f802b3] = 10;
        walletsPresale[0xc96722455ce56F676D4aD9343b3631d1fB4FD621] = 20;
        walletsPresale[0x180EE781e84A4f554562d1CC2ea677c6e8776302] = 2;
        walletsPresale[0xeE9F2A814b3e27dF5044b771973C7a7589478580] = 10;
        walletsPresale[0xCecE436D727DC4De835D8a0f2e930c7D29C556fD] = 20;
        walletsPresale[0x3A7b011311581e1D7FC5c97c558726aabB598aEE] = 30;
        walletsPresale[0x559de301EffC4338b2805f79B4e815F387332d23] = 10;
        walletsPresale[0xD2cc3E17c813e24C8a66e3CA2DeA7125EF64BFBE] = 20;
        walletsPresale[0x3F3c1471889604dE57ea3f17548014CeEB29Ce82] = 20;
        walletsPresale[0xE9581fb58eB6fdcBD45fcBA793149bAb6B0e0c4B] = 10;
        walletsPresale[0x4D2C5853F18eA553CF5716a9AF95bCD7f4095cc5] = 10;
        walletsPresale[0xa03d58D41b8978fF2F1DCA861faf0DC842E25F72] = 20;
        walletsPresale[0xB91105F277a6b5046Cf5faf3e8033eA31D4A0023] = 20;
        walletsPresale[0x7F3535b21F9747076d0f4a4d7C8328505ACC7A69] = 30;
        walletsPresale[0x4B4C57286a90e5DdB08a4Cb826F8209a0B15E677] = 50;
        walletsPresale[0x0C64D5DA9CBc8bbeE994166FF8dd47809DF0002b] = 5;
        walletsPresale[0xc436292c46E642185d96A570108C369f0F1a4Ccf] = 10;
        walletsPresale[0x28512542eB68f758fF60D68DB0fd00c0918D0C4a] = 10;
        walletsPresale[0x366036DB07c04A3fE224909E6067730DB491b3f9] = 10;
        walletsPresale[0xA38500bc712Ff5C52B146CdA22fF625d766C7D2F] = 10;
        walletsPresale[0x9c090D8EdABAF6ef7D77632a16d1Db67ae5d4DE4] = 10;
        walletsPresale[0x2Ba11189F73757319460967f569C5F1Ca5e44E8E] = 10;
        walletsPresale[0x9a1C13dcE181087d7C03A12E4CBE8A2a62312420] = 30;
        walletsPresale[0x6f67d99EE4CaA0056A3cd80F5b0019BF305aE706] = 10;
        walletsPresale[0x3f3599943d83Dd5C241Fb767A526b260fc2D62Ee] = 20;
        walletsPresale[0xa240eAdb80C2Cc19731Ad62EF856d6d225d6c7B8] = 10;
        walletsPresale[0x6Cd064f3c9028Af67eDdc24dd936c9f3FAeF963C] = 10;
        walletsPresale[0x91bf1E0Bc322450142383B88e515C3D798102377] = 20;
        walletsPresale[0xAA3d165d24C159F04EaBedE92e263E1840E4a5b8] = 10;
        walletsPresale[0xbA726320a6D963b3a9E7E3685fb12AEA71Af3f6d] = 10;
        
        walletsPriceExempt[0x1F1Fd08ED5f3dBC2158D96Cd5eC063A7A5AeBc67] = true;
        
    }

    function reveal() public onlyOwner {
        if (_revealed == 0) {
            _revealed = 1;
        }
    }

    function setBaseURI(string memory newBaseURI) public onlyOwner {
        require(_revealed == 0, "Cannot call setBaseURI() after Tunney Munney has been revealed."); // Must not be revealed yet
       __baseURI = newBaseURI;
    }

    function withdraw() public onlyOwner {
        // uint256 balance = address(this).balance;
        // payable(msg.sender).transfer(balance);
        payable(msg.sender).transfer(address(this).balance);
    }

    function addPresaleWallet(address purchaser, uint8 tokenAllotment) public onlyOwner {
        walletsPresale[purchaser] = tokenAllotment;
    }

    function totalMinted() public view returns (uint256) {
        return _tokenIdTracker.current() - 1;
    }

    function calculateCost(address purchaser, uint256 numberOfTokensToMint) public view returns (uint256) {
        if (walletsPriceExempt[purchaser]) return 0;

        uint256 calculatedCost = 0;

        // Do not mutate walletPresale[msg.sender] until token is actually minted
        uint256 walletPresaleAllowance = walletsPresale[purchaser];

        while (numberOfTokensToMint > 0) {
            if (walletPresaleAllowance > 0) {
                walletPresaleAllowance = walletPresaleAllowance - 1;
            } else {
                if (block.timestamp < _PUBLIC_START_DATE) {
                    calculatedCost = calculatedCost + _TUNNEY_MUNNEY_PRICE_PRESALE_AND_WHITELIST;
                } else {
                    calculatedCost = calculatedCost + _TUNNEY_MUNNEY_PRICE_PUBLIC;
                }
            }

            numberOfTokensToMint = numberOfTokensToMint - 1;
        }

        return calculatedCost;
    }

    function mint(uint256 numberOfTokensToMint) public payable nonReentrant {
        require(block.timestamp > _PRESALE_START_DATE, "Minting hasn't started yet.");
        if (block.timestamp < _PRESALE_END_DATE) {
            require(numberOfTokensToMint <= walletsPresale[msg.sender], "Minting is active for presale collectors only. Please wait for whitelist or public minting to begin.");
        }

        require(numberOfTokensToMint <= _MAXIMUM_PURCHASE, "You can only mint 20 Tunney Munney at a time.");

        uint totalMintedTokens = totalMinted();
        uint numberOfTokensToMintNotInPresale = numberOfTokensToMint - Math.min(walletsPresale[msg.sender], numberOfTokensToMint);
        uint unmintedPresaleTokensReserved = _TOTAL_PRESALE_NFT_COUNT - _presaleNFTsMinted.current();

        require(totalMintedTokens + numberOfTokensToMint <= _MAXIMUM_SUPPLY, "Purchase exceeds available supply of Tunney Munney.");
        require(totalMintedTokens + numberOfTokensToMintNotInPresale + unmintedPresaleTokensReserved <= _MAXIMUM_SUPPLY, "Purchase exceeds available supply of Tunney Munney as there are un-minted NFTs reserved as part of the pre-sale.");
        require(calculateCost(msg.sender, numberOfTokensToMint) <= msg.value, "Amount of ether sent for purchase is incorrect.");

        // If before public mint date, reserve some tokens
        if (block.timestamp < _PUBLIC_START_DATE) {
            require(totalMintedTokens + unmintedPresaleTokensReserved + numberOfTokensToMintNotInPresale + _PUBLIC_RESERVED_COUNT <= _MAXIMUM_SUPPLY, "The remaining tokens have been reserved for the pre-sale collectors and the public mint.");
        }

        for (uint256 i = 0; i < numberOfTokensToMint; i++) {
            // If this was a walletPresale mint, subtract one from allowance.
            if (walletsPresale[msg.sender] > 0) {
                walletsPresale[msg.sender] = walletsPresale[msg.sender] - 1;
                _presaleNFTsMinted.increment();
            }

            _tokenIdTracker.increment();
            _safeMint(msg.sender, _tokenIdTracker.current() - 1);
        }
    }

    // Royalties Implementation: Rarible
    //    function setRoyalties(uint256 _tokenId) public onlyOwner {
    //        LibPart.Part[] memory _royalties = new LibPart.Part[](1);
    //        _royalties[0].value = _ROYALTY_PERCENTAGE_BASIS_POINTS;
    //        _royalties[0].account = _ROYALTY_ADDRESS;
    //        _saveRoyalties(_tokenId, _royalties);
    //    }

    // Royalties Implementation: ERC2981
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (address receiver, uint256 royaltyAmount) {
        if (_exists(_tokenId)) {
            return (_ROYALTY_ADDRESS, _salePrice * _ROYALTY_PERCENTAGE_BASIS_POINTS / 10000);
        } else {
            return (_ROYALTY_ADDRESS, 0);
        }
    }

    // OpenSea Contract-level metadata implementation (https://docs.opensea.io/docs/contract-level-metadata)
    function contractURI() public view returns (string memory) {
        return string(abi.encodePacked(__baseURI, "contract"));
    }

    // Supports Interface Override
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Enumerable) returns (bool) {
        // Rarible Royalties Interface
        if (interfaceId == LibRoyaltiesV2._INTERFACE_ID_ROYALTIES) {
            return true;
        }

        // ERC2981 Royalty Standard
        if (interfaceId == _INTERFACE_TO_ERC2981) {
            return true;
        }

        return super.supportsInterface(interfaceId);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return __baseURI;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/ERC721.sol)

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
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
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
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
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
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

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
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

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
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
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
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
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
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
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
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
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
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
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
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
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
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;
pragma abicoder v2;

import "./AbstractRoyalties.sol";
import "../RoyaltiesV2.sol";

contract RoyaltiesV2Impl is AbstractRoyalties, RoyaltiesV2 {

    function getRaribleV2Royalties(uint256 id) override external view returns (LibPart.Part[] memory) {
        return royalties[id];
    }

    function _onRoyaltiesSet(uint256 id, LibPart.Part[] memory _royalties) override internal {
        emit RoyaltiesSet(id, _royalties);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

library LibPart {
    bytes32 public constant TYPE_HASH = keccak256("Part(address account,uint96 value)");

    struct Part {
        address payable account;
        uint96 value;
    }

    function hash(Part memory part) internal pure returns (bytes32) {
        return keccak256(abi.encode(TYPE_HASH, part.account, part.value));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

library LibRoyaltiesV2 {
    /*
     * bytes4(keccak256('getRaribleV2Royalties(uint256)')) == 0xcad96cca
     */
    bytes4 constant _INTERFACE_ID_ROYALTIES = 0xcad96cca;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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

pragma solidity ^0.8.6;

import "../LibPart.sol";

abstract contract AbstractRoyalties {
    mapping (uint256 => LibPart.Part[]) internal royalties;

    function _saveRoyalties(uint256 id, LibPart.Part[] memory _royalties) internal {
        uint256 totalValue;
        for (uint i = 0; i < _royalties.length; i++) {
            require(_royalties[i].account != address(0x0), "Recipient should be present");
            require(_royalties[i].value != 0, "Royalty value should be positive");
            totalValue += _royalties[i].value;
            royalties[id].push(_royalties[i]);
        }
        require(totalValue < 10000, "Royalty total value should be < 10000");
        _onRoyaltiesSet(id, _royalties);
    }

    function _updateAccount(uint256 _id, address _from, address _to) internal {
        uint length = royalties[_id].length;
        for(uint i = 0; i < length; i++) {
            if (royalties[_id][i].account == _from) {
                royalties[_id][i].account = payable(address(uint160(_to))); // Wrap address and make it payable
            }
        }
    }

    function _onRoyaltiesSet(uint256 id, LibPart.Part[] memory _royalties) virtual internal;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;
pragma abicoder v2;

import "./LibPart.sol";

interface RoyaltiesV2 {
    event RoyaltiesSet(uint256 tokenId, LibPart.Part[] royalties);

    function getRaribleV2Royalties(uint256 id) external view returns (LibPart.Part[] memory);
}