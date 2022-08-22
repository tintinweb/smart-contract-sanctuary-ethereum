//SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.9;

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";



contract ethhub is ERC721, Ownable {

    uint256 public mintPrice;
    uint256 public totalSupply;
    uint256 public maxSupply;
    uint256 public maxPerWallet;
    uint256 public wlNFTLimit = 1;
    bool public isPublicMintEnabled;
    bool public onlyWhitelisted = true;
    string internal baseTokenUri;
    address payable public withdrawWallet;
    address[] public whitelistUserAddresses;
    mapping(address => uint256) public walletMints;
    mapping(address => bool) public whitelisted;


    constructor() payable ERC721('ETHHub Lifetime Pass', 'EHLP') {

        mintPrice = 0.0066 ether;
        totalSupply = 0;
        maxSupply = 10000;
        maxPerWallet = 3;
        withdrawWallet = payable(0xd3353f71da26E364297506cf2908cEE4bb3e9eA1);
        //Set withdrawal wallet address

    }

    function setIsPublicMintEnabled(bool IsPublicMintEnabled_)  external onlyOwner {

        isPublicMintEnabled = IsPublicMintEnabled_;
        
    }

    function whitelistUser(address[] calldata _user) public onlyOwner {
        delete whitelistUserAddresses;
        whitelistUserAddresses = _user;
    }

    function setOnlyWhitelisted(bool _state)  external onlyOwner {

        onlyWhitelisted = _state;
        
    }

    function setBaseTokenUri(string calldata baseTokenUri_) external onlyOwner {

        baseTokenUri = baseTokenUri_;

    }

    function setwlNFTLimit(uint256 _limit) public onlyOwner() {

        wlNFTLimit = _limit;

    }

    function tokenURI(uint256 tokenId_) public view override returns(string memory) {

        require(_exists(tokenId_), 'Token Does Not Exist!');

        return string(abi.encodePacked(baseTokenUri, Strings.toString(tokenId_), ".json"));

    }

    function withdraw() external onlyOwner{

        (bool success, ) = withdrawWallet.call {value: address(this).balance} ('');

        require (success, 'Withdraw Failed');

    }

    function mint(uint256 quantity_) public payable {

        require(isPublicMintEnabled, 'Minting Not Enabled!');

        require(msg.value == quantity_ * mintPrice, 'Wrong Mint Value!');

        require(totalSupply + quantity_ <= maxSupply, 'Sold Out!');

        require(walletMints[msg.sender] + quantity_ <= maxPerWallet, 'Exceed Max Per Wallet!');

        if (msg.sender != owner()) {
        if(onlyWhitelisted == true) {
            require(isWhitelisted(msg.sender), "user is not whitelisted");
            uint256 ownerTokenCount = balanceOf(msg.sender);
            require(ownerTokenCount < wlNFTLimit);
        }
            require(msg.value >= mintPrice * quantity_);

    }


        for (uint256 i = 0; i < quantity_; i++) {

            uint256 newTokenId = totalSupply + 1;

            totalSupply++;

            _safeMint(msg.sender, newTokenId);
            
        }

    }

    function isWhitelisted(address _user) public view returns(bool) {

        for(uint256 i = 0; i < whitelistUserAddresses.length; i++ ) {

            if (whitelistUserAddresses[i] == _user) {

                return true;

            }

        }

            return false;

    }

/**

[“0xD6531b2072B0809976B0FBC4064BBEc42Bcf0413“,“0xE9275ac6c2378c0Fb93C738fF55D54a80b3E2d8a“,“0x47851C745e3cB6a0341aa439EB7E2DbdC9FF972B“,“0x3d32f0d8e4020F8eEDba3c572B28BC4ea4E0A8aa“,“0x12D69B1b35e2dfcC86FA28233e0Cb6cCBbf4adF6“,“0x06FEDA0b2B5D5DF1C9B4731aB00901347ad497F4“,“0x1fF15320E4F2285e3421994A6e254225823075C9“,“0xAd188F0D79A5A1fF9c2bf506a20494cd04976545“,“0xDbeC80edF51C90F6928d99307E2E1248451C6c8B“,“0xA1fbf4e3874a511186B07Dd39862e42CBBC4aF91“,“0xDe54227dC7cb1dE999979f21548096D92B64827f“,“0x4f58b74711d7628D38401fB9Bc3614e5c738EafD“,“0xc623483a440A6Fb5C0D41f8E30a9F3dF49a237Ad“,“0x9f5323c75626E0424865E0D01546Fc95823b071B“,“0x663366A5792D6a1ba4E291F2B17fB862e4535aD7“,“0x01D33382DA013F6dcED207aEC0ae39a8D76E3f8A“,“0x72be3613Fc246261394f1BEB1DF50F2bB0274937“,“0x3A13646cf7Fac5a566d76B048deD85BAB2F1E075“,“0xf9a3f9c32CB16DdC15b9B8cB4D5895Ea9A85c6B5“,“0x8308F5a4cB6b33B09b30e880E82Ed637d834b097“,“0xb77b2cddd60CFd880583294c2f71bf128d55Fa56“,“0x1BC98f834aE87922F20CC69A0D58C2a775938E96“,“0x71f6b370a4d2Fb0c73Dc7f356ca896889EF0f822“,“0xAa5edA855D2cB4E76E5d627100B2028709738749“,“0xc4C2b2260579F4DD537B611F294b5eD85d269355“,“0x4a1B9e55bE51Eb6BaAbb061989C509Da4Ce03c47“,“0x04f2347A32e5ae9f5c1F1f03998255385f05b028“,“0x4f1C7C2C776A2dE68eFe76205500c92213bB8fAc“,“0x8bB97F08E78A951E835EAFD46B0c4F62442c480E“,“0x9e3782cB83118f16B1d360eB1F83910222534E9A“,“0x3013Ec0E1F8DD61dc7A10c5C1B9bc04f3A6B7AE6“,“0x0c1BaF7170Efb77E5690C1240FA14582c90a02a9“,“0x32de2797ff55E014f03E04Fd45D1B71b4A12E853“,“0xf77ffFac207A8e2eb7eDBe57570a364349FcEc99“,“0xE21fDEBbE5e005819c7719aD1FEA02771B79F3CD“,“0x28ab9BeaFfadc80E4ed3F23904821632f5540CCe“,“0xfb157F7Ae07ffE0e75CbdCd247590E5961A16c64“,“0x96AbdBa824368eE3C8DeAdEaD045031Ab711e624“,“0xe8F46Fd8F567c67D793d0c86dd6434e9E68029BA“,“0x1b810D1E48c5EFc81ea4341d2c1Ffede2e5Bdaa3“,“0x2824B4caFbC340d5F9E5d771B48AA21e30d2E35C“,“0x1a740c637D92B711F1E23A046dd7F0c63939cc66“,“0x1eDBC2CD7De609DD77076cF036be448f34870e82“,“0x2aAc00A9cF4d4f1c304D0f904a7b535E84c08037“,“0xAC557e28eF3B7377a141dCEB8Ae7559E38988316“,“0x07Cb70ea433A019d646E1de896a5673ebd941dac“,“0xAed072BBd1e541102aD6173352cd72dbb71147D4“,“0x6d96721E3dcf65c87c4Edb3096D3285c1E290113“,“0xbFe4A8AC298AeB634534Fc708f30D3fCd4c4Cdf2“,“0xb73bae22A8a02469b6fe11e653F9C06Ec46123a6“,“0xde0Fa6299B4CdD054ce4d0C263305E37fB32f749“,“0x7e54c3d62509e6F5C8C2d3c50727BbABdd5B9f14“,“0x02314E91079742E13b2A7DF405a7054266117140“,“0xE15F010961eFBB8BebeF340029782Da1cbdA8c0c“,“0xf9eDec527853E2a40f806df736C07DdD0DA7C631“,“0xb6dDA303E0443d2d5eb0560424868D0c5081C6bB“,“0x20cc18f6586432fdfE3d6E72444277fF1f902fa5“,“0x5C55F7eD0CDfE0928b19CA0B076C26F98080a136“,“0x17D5ADC2319A7A6Bc2c3BCFE38cF221C3744B79c“,“0x4a12968F8ab89E79c56E2eB4c244928246020957“,“0x89b671BF358603eD8C9bB9Ee67f2cB0f09FcA0cf“,“0x2b39f28Ae7a9767C6D9837A89Cf610DB3B74813C“,“0xe0EDc1437f3A925342C02df2A4eb7eB899431633“,“0x15aF8559Ad8f85374279668f10Eb01119B538d8c“,“0xc2447164fCd983b0ED867ea88133943aF9815e61“,“0xE54A7e7b4021a56BAA629Deec8634f6aBBfc5827“,“0x3fC642741574b86A4fa4f6b71b145adb1Cd8592A“,“0x8F89DdCa1a50281743A0B860aC5D29b99a59B93A“,“0xBE97eBEEf06a0388294CFC33418793ae38bf1F0C“,“0x3bBC207665749fe728D19F1148D693c273ec4bBd“,“0xC7063882fa5528EfC14cE6Af198e6bE190A5E3AB“,“0x57D174665bcC081a3261A30bE418616D5C3BBEba“,“0x1f2bCB6d2A3551eB303BCE9d5d5c5c4f2556b750“,“0xDD8d085eD550A22a0b437E4Db3F0a0261D6b7dDD“,“0xd1b8aeeF1Fb38c9117a66731AEbC75f1F9A727be“,“0xf3182C08a31851a8CaF3E7fEe371382cDC6e655F“,“0x85b826B5eB230D03Ce1BB41DED646909bF0c3F4E“,“0xb915d1e50b237A1C3A12a1487F3510cddb466Dd6“,“0xe77f0DB5F514a89A0816B67bd19cCc41553C95B8“,“0x1b9B31b6F2AB65e70a3d4Fa7150add08cA55B91C“,“0x8F9603e7690E33602069f4f0385446c90E27a495“,“0x2a881F5c9bf385621f1ba9E5A26EB767886E1705“,“0x0A13cf0D5557B18632bfa735E9e323DE2651460b“,“0x75963B63D551Fc3723F3Ca40bc43c45201b35f33“,“0x824D6975FbC9B44964eEA1108F98c67E4a37AACf“,“0x4D18C1D5eb4bE1d7356C0Ffa221bB99Ee086bdB8“,“0x9b2726AdCF67B20f98e6D34e80370CA25125A845“,“0x7C3E266d43A91F6Bb6D32C0D105852e90E4d8f8d“,“0x8C488dFa7B43E237DF71403EF1b619C987ec99a3“,“0x7a27E2Ead6E36772b0aac6256503C6b9188B69C4“,“0x61edBB3fe3d835b48a770fCBDedC1F988Dd53F82“,“0xF97Fb3a0ac16f154996cd95dC9a4234292FC10e8“,“0xD926F67B83650420932d2D711f4EBA0E9F7Fc9aD“,“0x18cc05bFd676F4CE516e4F73B0257027deF7C665“,“0xBA8e38e7Ff9F2b175880C53A432151Ae84A4Ad1C“,“0x667884EEb8d2a19067782E9D89AEc15F32a31C46“,“0x0a0adaA2f9d3676a63f0F596B3A1dE20C3B1c0c2“,“0xfccaf1CcCea8E81Cd763E96F9C02E2fB5Eeb7FD8“,“0xc9d456c1419fB311e4E98A607dEFc0103cD7fa95“,“0x56a2fA90fD15c3f842B8343D01926c1fa6AC2eAC“,“0xc49A88422Fd4a604B6bef2555E738FeE67Fd71FE“,“0x90Df22cF040E779C8987aD03Bd42b66742830b19“,“0xfDbb7d23F215CdF65267D55eb7b47aB717eae996“,“0x61e5395E289d4507D456532276187318bD5af3a7“,“0xa94AEF908dc2222f662cb0A41D84d715C78A2644“,“0x18a54340324f442d7523D2d0803D1911Ebc20294“,“0x1407665EE916997BA7f15E29565e98c38fe41316“,“0x790551d048BA2C0451F82D53FE29cDC8fC96f07F“,“0x1e13302a4d175D6A5De0Ed09aaA6F3E7f0cB03cC“,“0x3A6C9298F20212842196f7B5c05609b780832641“,“0x15ACB2F014E9B665af5EeB1ca023A982f0e2a254“,“0xF7Fa2b9ccEE29d6d760377d040e6Ef92bf9b09Ff“,“0x0000e19AE6077e984Be32666B8EC2632C7E8CE73“,“0x44fBae5935520647Eb98115e1c2F09a0D642e2B7“,“0xDFE7309D1b6ae97d4D457c6C3bE6a6751631BDf7“,“0x60FC76c73B94113dB86343e32b0aE310AC9d93EF“,“0xFe9243b59d6d2Cc295213201cDd9f7a7714172fc“,“0xd1164E046eB60C3c17d03DD8e8321F31d3b45229“,“0x0f62359CAef08Cb09FbD9D90913aA9c681E0A5bd“,“0x36410Ae136E07Af5C99ccF97C8E9398558f82B54“,“0x25bcEe39100Ea2E0d69E9DDDf65384EF9c1825CF“,“0xd7e2EA85D6128FaE01660c710D08E0c3E2E4c3F5“,“0xBeba618232a0F021C008dEEB5E18B9D563227902“,“0x3a684E5382477Ecc874d66B73E85653b1fb8C355“,“0x0D8F37352951BF6B6BC7Ac3FeAacfC25754aCB07“,“0x11a0CFe76dd872a9057aCfA53FA6ec261B0f5bDd“,“0x20bE2afF79B1F330A798983c78c0E056F8627623“,“0xC88cb82e47aa7e121D338184b1666e284D04C06E“,“0x0249736c90976e6f82Aa5c1CeBd9818098c9705F“,“0x2D1496d4664dDAaA3db79fA4e471Af2f80561945“,“0xa505009b25E646Ce8e63F880b9fEF025c18d4A7F“,“0xFAdc52f6a73E029a4b6F51B2E67bEf3f72E57F73“,“0x236fD5407e77fA35d850FCe7802Df7Efec3c3324“,“0xA8F517d15CC01326fD103033f4ea96d24F83F6b2“,“0x3Ce691A6fe360FFA6C53FE3718e72AfBaa12cb08“,“0x230d5C6CC6C949da5cC9019D8D9DB89B01c45537“,“0x20923cBf574A97aA13d656a74aacE49da03ef0C0“,“0x57ccC09E083C2Ac1F6F8BC6796E62Cf33DED6Deb“,“0x6D307B11482c71Ac933b2E8a91f3Aa0a28de12Eb“,“0x34F39A005233164cf6aD9f87E355386eA4Cb5061“,“0x843f59C87a9D94505Ca65E9CDD1D01B6a7Ce192f“,“0x05Ade9D6Bd074606C3fBaCcdF50E1DcC89B3d09B“,“0x4E27B78E160a8c67c6958b8aa25c052fa0582bF4“,“0x3B209185d34775862BA932c09BC9732A69739E2E“,“0x86A53B0E52FA7A64894b22CA940b5748170519DF“,“0x513AeDacE44cc9a0724CA276a8CeeeE950903576“,“0x47c88B005E3A51aE121acd6D2dC702E0de1484a9“,“0xfC8ab1b458eF887A8d21C2ED00B925b07E810b2e“,“0x00BBc7aAa3E598dAC0ef90dCEFfb6A70737a5D9A“,“0x5F68b64Fe246D9Ec9a1dfBa203D780dc7f45EA86“,“0x5789013096978507Ba64e4880A725106E4B0DE27“,“0x8Ac5B1DC1873994F376276cE008f8Adfb2DBDc5b“,“0x02891d5Bf76bdDfe678d6449838c3CEB2ba40160“,“0x65CFD2845FA6FbBbB8848334553a2dE5b79158C4“,“0x605FbDD3d2e9Ba4966222748332a4137ED2dDee9“,“0x1D16f7587DFAf4ff25d493C1aa4cFA7b417e86a9“,“0x0e93545Edad0Ba8884bCEe70618c3D8D4D73d5B4“,“0x44082e727C438e388463f7ea8b29d2b7860A26aa“,“0x42860a443831c4fA3Fef4E5eC378343b44ee48eB“,“0x96232D041648046c17f428B3D7b5B8363944188b“,“0xF131640b01FD2d2C7c8cD7b33ed2Ff88297A7fD5“,“0xf67E79d304aC4F414Ceab27DC0A871BBe441Ff76“,“0x9C5439f1aEdb295e156512589dBDCF077cF12907“,“0x14B6C4bE9276C1E6Bd3E9F793E7E6A83a20eaC3a“,“0xe8cb7fDc5141F07950c673fA82D30Db79297EEBb“,“0x566c53f53B92010064cf0195dF88085eF6990ECd“,“0xFAdc52f6a73E029a4b6F51B2E67bEf3f72E57F73“,“0xC097Ee74d3583fC02eb1Aa0e4174a23341a8F15E“,“0x4ED68136AecdEE08AC7BB7DA2897889BCc91DbFd“,“0x3E06B157A7c6FDFaEa072D54CD93307F48020cC4“,“0xc97b32D413Bdf3039B7293c3246CC8FdcB864BcB“,“0xCC7f30f5a09B90Fe9576392Bd49CF1c856C5B5C9“,“0xD84b07254F6320e97d7516e02591c9C01B576980“,“0x5F7a49b8F0FDf0C6dF74c32d514CeFFC32e2f686“,“0x91ECc71f843a9cb656D79d91F576fC78dFF2a16f“,“0xB2817Ed45f3a24962634A31d18a72022787a6c99“,“0x719Df1FE4F51b50c03d8630D53e936ba4525c7a2“,“0x8E3A94630bBbFdb11DE3888342C05B56f77CDF62“,“0xC4b72816dB9913A69D5A0AF41b477b51c8f598d3“,“0x38935e1F97198201f2c53E4D7b35594274A62EBA“,“0xAab7a0212D08e9EF882177aDd6a9404b1727E993“,“0x7836989949554501ac5d021b7baef6c992f1b854“,“0xb1EBe37F7890Ce064eF2887Ec7371b93664436e2“,“0xF532020158e868B22Daf6277d8Dd1fB9911aEb00“,“0xe978ae285e6ca04ef40af882371a2e4a97cfc812“,“0x69f34c600f58e833688c595929dda89a859e9863“,“0x8464dCf46952c0FCa18Bc1df3a7E7B75Ada93F6d“,“0x8EB0B4A3504b16E3ce7b109964B4DA68a11fe5eC“,“0x01aAc70ee39DBa4415eC5904a556aA4b33B66520“,“0xd425f4d46546a7bEBC2Bdb2DcEBcD97FD040b5b9“,“0xa139bbb96869cC1fCDA6049C70aC7e48F123fdD8“,“0x56accb07dC4465926F1287fBE65fCd82228e5F53“,“0x605b2d5810ad080d89b3F4EC426F13790A3366E1“,“0x337642613368DaFBaBA0694e64A67Ef0321c9F93“,“0x81aCa17247c8e71eEFce6AB604B5C00E143014f1“,“0xdcF2e719edD8E90DcBa981161f62a1667c68a5a8“,“0x47c88B005E3A51aE121acd6D2dC702E0de1484a9“,“0x8c2A36F85d92a3ece722fd14529E11390e2994D7“,“0x1F1D592d326446AE7ab7139C668D2237f0d6Bc12“,“0x87f8079b838fdf390fcc5b38e99d2036c8b4a043“,“0x4C813A3e9354C167442Edec587C6aB69951BdD64“,“0xbcfd321433f3523d9396cd2c8c0fb2828266487b“,“0xeD83e6e0f5b80ceCe8Ef1e6ABD6B9DF6A8Bb1688“,“0x5a9435c0EaAa532bD9C4Dc831DF9537d8f6E6A4d“,“0x605FbDD3d2e9Ba4966222748332a4137ED2dDee9“,“0x2A8287cF2a3aB16766556d1E755E427c376d795e“,“0x35d1B2B9395F44033Ec88Edb286dCd93A1EE83c5“,“0x82B472cB2Bb1989e9419b2282E1B70Ee9f864888“,“0x4CDe10196C770AC25c1c6A50F523A52EA6807c27“,“0x0Cd544e3e295913260Cb2382320085cDb9d9bc95“,“0xc09956866623Ac5c49cb543634b0a38a6Eeaa862“,“0x65CFD2845FA6FbBbB8848334553a2dE5b79158C4“,“0x818Df457dAAF368846962A8058af09fCF8b0F383“,“0x30e8bED0160e785f5095A5eC10d1e44829e5576a“,“0x13C10eCb747F71b8Aa01304B1fA08383A9163811“,“0xaf6FD884e3834D1725B7671770a99331c0b60E3d“,“0x8da09fE01AeE48A8135ddb7ae10Aa52517F44202“,“0xdA76bED16c1c6512Eef73058EF5077Ed516d0aA4“,“0x731352e2Bfc9933c07a00AF8b50dF8B59B1Da0D6“,“0x56Ba7233CCE2AaF5A07f3bf240dC8c33f3Cae370“,“0x3715CB72e9a0BBf176c077Ed12952625B4cAD90c“,“0x61e5395E289d4507D456532276187318bD5af3a7“,“0x0907Bb13fefC50e25B0bFBB7C1Af9C2e02dbDCE7“,“0x0a643c455e379E232EeE9DfB18d00c9d1399c459“,“0xC27041dcb0389B1144b52F2806d270523be2de2C“,“0xBe68a874d11277AC4A6398b82dEf700553d74C3F“,“0xC54e976001aDAd914552eC95f3c14Aba80f47615“,“0xfC8ab1b458eF887A8d21C2ED00B925b07E810b2e“,“0x96232D041648046c17f428B3D7b5B8363944188b“,“0x3B209185d34775862BA932c09BC9732A69739E2E“,“0xb94872bc787343e194c069FFeB7621cBea41FF73“,“0xb84d84019Af5EeBf81b378E98567068dCB9B622b“,“0x9f83bd3F27663447FC368A50Af8a7fa6789dAbD2“,“0x1e868E0F5948Fc94ed99DDe0d0AbA939E7677b47“,“0x453f2a8e2ee8107E056BC71CDBF29322a1B73a53“,“0x6ed655ED54910C1f85391f8e755F92927A381439“,“0x5c47cDc8aD3434948448D92AFeaC8eE977d7d546“,“0xCeda25bBc2dD0de5121C2373f1CF33fC844b2eDa“,“0xD2D50D13a5ddC10FE030e30c76f7A237Ce373674“,“0xf3168D199EBBb02110c27fEDdc777B0a5aA5467B“,“0x03B6b8d1FF8eDe2d77AF184C3667B8311F409d9b“,“0x96b8Bcc93c481c065006cdE99f8B5e3d78b19bAA“,“0x11802Ea465e45eE8901080E0ac44ee56DD7Da7C2“,“0x1dad34748ee00b49642cb974ed717ae8687a3bc2“,“0x28d714935cd7587a0125f4bd5ee15ae743b53f69“,“0xc1a9f25e5157c9b526e1a0d87a1912c96881163a“,“0xc7b8e515c5f0fb34d301313b636b29d866a2e69f“,“0x37792e91524cE99c8Ed86cf3a4008a1739839265“,“0x691f4c36577e5861597fea6e4341a8c21182879a“,“0xec23b4d0ff7922192eca743b576bb58418bba45b“,“0x9283B44A6E4b5C12aD3Ed2A56dFF38D4496E2506“,“0x90e027926bb56e57e30b58eb28e87a5d320f7e38“,“0xf5A8343df1ff35751C30516D7461Ea42b87B5C47“,“0xb84404f79ebef00233e1aedb273c67c917b8840f“,“0x1BC98f834aE87922F20CC69A0D58C2a775938E96“,“0xD0446a39c9AC3Db0Be9A5e4a06D55A7129c961c9“,“0x64C3d956830a6BdB91b030f7A184623a1b324F95“,“0x316a35ebc7bfb945ab84e8bf6167585602306192“,“0x05ef49bfd6159f99da9050aa09af868331d8d144“,“0xf0c4a744d5763117f8730a1c65a0c0a330894c0c“,“0x2540B93287ea012f26897f07051242cB8c7E2318“,“0x477e3AF52182e3A9EBF7b1F0F31896181FdB8341“,“0x4e917cae501644c6de374fe6a2dc1024d820b630“,“0x3a32AD7D41649379A9f872728aeb5C2b940BC38B“,“0x21139F65a2C2f9D9C31527CA2AdCF42E3930a85e“,“0x777480ff6351D131E4999c9Aaa2C1aFaBf0BE76d“,“0x5421bfcb1cec95e3b80fab745b60e61706847cc7“,“0xbdf8b33c06baf54f74e2f305741222b46af6c0de“,“0x5421BFCB1CeC95e3b80faB745b60e61706847cC7“,“0x613c220D188f791F5b02666247E74cf523BA27EE“,“0x04FdE1cE000129649601bBbd7cBc69912F36ceDb“,“0x3F55B1d63F17E60f202a1ac9AdCbAF7055D43C0c“,“0x0B19c24B2BD4e6339Bfd2a7ac00bb99C06a7b564“,“0x12f8672660294a752d2aed081e3f229fb7d4cdf7“,“0x45c734720ec0723023bb88eed0c1641829fae5cb“,“0x63e0bd39f6ead960e2c6317d4540decaf7ab53ba“,“0x37c1717cea2ee67f58bc176fdd60f325a7ccf095“,“0xf81761784DA25d823A66B9FbA0fFdB33FbEC8AAE“,“0x2d286202f2997f59882e1a098052fd57500cae49“,“0x4304e69608A76CBa0e8632d44492b9466A6ED4C7“,“0x97c8becdb6bdb1bfc0a789cc240f0e126c9a3feb“,“0x68A92d69988671bdD6Cc122f95e8Aae9cBfDF2F7“,“0xdB265625194B9d34eCD43700e8c2F05f60eecbc6“,“0x711e4721De14DcD6267bF22838926cead9137Ff2“,“0x897Dfdc2D61eeEbf0a9bc73366C9E66D0Df77395“,“0xcb6d99c84e7ed6dce24bd940242909908de43d6c“,“0xCA1Cd2C5a4CEa64EBBd32d0c128D5972cB530D55“,“0x4add07dec02d66b2f6f0597cbcf7ef96e2c05135“,“0x9afb9ae2678dc93b5bbc83fa14ed27d7d291f57e“,“0xa6a2c418508e95636516851c25a3b5ea90d895af“,“0xc7a6968b09cc80a48b7fae3df0ffc959eed9ff2d“,“0x1BFa36EA533bAE7fa8EB8Dc518c80BD91335e936“,“0x6B45279B8a5B2Cfe3311f60E3caF0E74BE30FCc2“,“0x25E97876aefabF66F69c9Ce0630c84f66bFd81c1“,“0x87D4734C350bfc84d6C5e26DfC893b568E7840a0“,“0x0Fe6253081cfFAFddAf88a7f4c84Db054ecA62cb“,“0xbd37c5BC416d096D4979b44909160fc82C9a9614“,“0xae54aef2b2cbd086e22a743dbc04830038bb53ad“,“0xb61ddb0370ae548486101b008D8901D705c3EdC6“,“0x7afc88f9b4648f4ed44fb0b0ca9f3795a31e4f0c“,“0xcBF2392f523D7c73Bb205c4b4716553e2156D8fb“,“0x82f7ea1F25C24046234916e1DBd8C3B0062C8925“,“0x75aFe85a0142581904ef4FB993348c71c1c84138“,“0xf27c41ca7e4e811d44cf8ebd61a955575c47dd05“,“0x8af37571cAA67CABFEf40CE9A8Bc2d1626EB65B1“,“0xA783d43fD3E8F9821724331A13756BC4a9eB4Bec“,“0xB2FdF917B8c54360C430506D6CCE7dd099882990“,“0xC116A6AF7cDAfCe11931a347543fB340Df4DA383“,“0xE3430a0d4688862517243B222871336204f3fF39“,“0xdb1d55d147f34a169946566d5E1735d6e4346491“,“0xf7ef3935acb22079c7c2107f7a2f508c76b431eb“,“0x8D1bab837081EFcfE3469C8f99A334Fb0FE69cC9“,“0x1563c9c1aD2C797B4E71FfD517638598C30FD56C“,“0x41E67eE6990Aa063aa26c6c2D9eb43CD3467CdA3“,“0xFDEc799fe2AB1a25CB989d2EED463EE06f395ECc“,“0x5e6db80c7f8d5da245d4249dcbee16e6596521d4“,“0xf6357315CE37d8A607fF30d1D6c39c47Bf402C9C“,“0x089324c1AC9BB85C01222B314E0dC10Fed5aD0e3“,“0xb79f204678801ea6a10e394b6ed2baa89737fa38“,“0x311bdab096705b57f564d7d6df728fc9c9b40b4d“,“0x4d9a238339f15d1ef4909399fff84dcf28eeea0d“,“0x688bc734e0f452dd46c6b36f23959ea25f683177“,“0xf417a9fe907b8f47849d2dd59b686bbc0b4d3566“,“0x4d285d730a855576f1fc8d07c9b68c2ee06bb153“,“0xc0eed352b853ef29917a7e7bdcce9b39f2c01aec“,“0x4dd1E7D5b80B7B464fC2DE7b5D1effaAE9daB0Fc“,“0xfa5cadd39fe6f9208fcefcebe06268d0d43e653c“,“0x97bdd734fca8456de0c98a7820f0f3907ef1bd83“,“0x78ffc299256ff6de4e72d579a43bcaa02c6fd6ea“,“0x2C195e505ed559f5254aCcbbB493904EeA557348“,“0x65967238A3980FF01B9F130359008b17852cA716“,“0x919d428f6f588c65dbf7401c8beeafb3dabce221“,“0x74871dEc410d84ceb73bD3E5Dd1252B48356e0a1“,“0xeba0b9844f174258cc81b4b4ffa9fba80a9b4138“,“0x6ccf00127b932d359a4a014e7d894e187d9d0b62“,“0x3f832a139407e17948730bb05b78f7371190e8ad“,“0x14E868C37d284Ccc09beF80D9e5d5243182c324f“,“0x8f068de4bF702Eb31E5229e8fAF2ECa3c551f293“,“0xd63c136ae72952534b6a46af296dd0f15c747565“,“0xea7dbfae75a93b18edb75c7a90a8041292ad9c4a“,“0x4FdEac32f70e05bcf838f08847e154de925fa7A0“,“0xb81e22951441cd373cd4372e122b952ba13d3ca6“,“0x8e263592f0133ca25d0232ddf2dff267fc4272b5“,“0x77D2Fae3BE44ABf3eF13CCbE62EedF24479113FF“,“0x0d8ea512830639a297d3c7d353386982c47f74aa“,“0x3eAB6F54cBcBde8296C871EA044b08C7251325F8“,“0x056ad1bb403c5208acbfe9198aa98ea2ef2fb5f8“,“0xcf3Fc1c726B2F7069cD6DAd132A868181305e242“,“0x8193951391de16942eed72f00c2ccacd8af620cd“,“0xd1789248d74123238891201180ba5486e10c8170“,“0xB4D3c81418A32b6c8DbB6462bBED26ab16884E92“,“0x8bA3187ed532F373984B50ab07b554e0EC8FBb5C“,“0x654d556ab8104da43aba8ef8592691967d7f1c28“,“0x833Adf2D97a72565D63Ea42Eb4aF0a1bAd6acCfb“,“0xa2d8807f7962fc844d8302f34a1bafc8affac54d“,“0xc347dB1b9077eBBC43eE1474B9866eab97ECb386“,“0x938497fc61d9b9a6bfbf26961cea801d196ee03c“,“0xfB2858d37D2B381A9bDeE83E6dD4C320dfc5d3ed“,“0x137878d2e1ca1739e3f584bdf43741a739df3e7f“,“0x78D607f219a49915Bf5B45d8E6a2eBa597457Bf4“,“0xbD6BF8B98CFA54cF794EE56959072d5d6605688E“,“0x49ee3132e3267c1062da88e010ce07afe8003612“,“0xc8B0297b2E40354731524fBF1F2d70aecBb2320D“,“0x44cf820e6Ac254cA5a43b7eeFd3F8ba539dd51c5“,“0x3f54d7ee2fc82061f6ddda00738dd1afa572ad75“,“0x4728e9C16452fE13A1d9f44d9a114A5A252F14E6“,“0x9D13f7496aEb564Ab0581f2b44ACD6c3ba7c3308“,“0x254F18b3D2bfeAE6931c2432c6dD34FCA16cB954“,“0xA71839bCdBC6D282e1839ce3Db92b06269d8090c“,“0x037278ef41092886d25c175f644941910362ea0f“,“0x4DF9e325b58250d2618bc6C47EA4Ddb9f8Ede068“,“0x90ebbdcd83b62c5528b4c95c58cfc5c054159836“,“0x4F21318139fC7E9C3B3f2d4929c9FDEEC9508640“,“0xBb9cAC4669D8666D6ED4D07cdF677C03d6682Eb7“,“0x6b0a789e01ec7e7c2d02905d9dabd3e879ff7417“,“0xb9820a7d1a1c97c339a471457c94cb67354f5b9f“,“0x006236CC0510792B7F5bd3b0A5B0C50A764fbCA9“,“0x19be718401b7969b566257b88f5a323b23543b51“,“0x551C3fe4D11dc269d0f2640Fd5b46e8144198Ac2“,“0x5639e5afac316a3386f53ddbcb3f9f52de1a9b2a“,“0xA0856eaeaEceBD114706fE55A4a09522AB373BE9“,“0x17bc4580e387aaf220ca185b0e7673e0e5970234“,“0x1d960cddbec881631568bce2e18b9b751b01221b“,“0xcd5a7b3a85cee0d88f3b2b5c3182135733150f10“,“0xa45d9c27778d6403e3487c4e1658b88bee37e4ea“,“0x1ea34655dcea330c799e9382e97dd834f9bf2dbd“,“0xF90801868F57DDEcf4CD79aE836AE7e90206c459“,“0xB42D0b4ED198176DEfD06c181D2A6a5b5f7632E6“,“0x8a2ca64E7a3a9D008346FD7dD67dB61f6EB42A51“,“0x51BDE28fcf55E129f08705f2f88b28c7dEEE4C64“,“0xd29d6df8ec0d8d5b208151196ff0969988a8f909“,“0xD91414F18779924053f3F16f42C34BBc16Ddea91“,“0x2098d69212bd4a7448256fdea887b55e411a4e70“,“0x8580DE1fd8C5423b2Ec64860a791211c3ADf6205“,“0x1128b435be2968c9d14b737ed4c4fc89fd89c6d1“,“0xB3C60d86544E47a205a06BC1C9b4B5c5563de24d“,“0x0713FDDFc069d154d78e0874128424ED22e6E482“,“0x5c84475c528d7b6fb431b2a49479d0fb9722d000“,“0x266eaf28487f1d899b1636f65b3424876acc415c“,“0x95a37b753C6ff8E5dc2c8a84d6dCeF44FF861aE7“,“0x8EeB1b84f865c20a8Af41Fb335F1A53AA118Df56“,“0x1c10581326432cb10d4e37c14e18cd4ef41f7c6d“,“0x44a07f22a133be058aE1FE2F93EC8A9051470b15“,“0xaa8A74E4FCDd1397726CF484344c5409Fa49856F“,“0x819dfc1b757c0ed67fea97e33e70cc4cc640f99d“,“0x375cd0c9c927a5986080c53aaf14642aa64b9e95“,“0xf72a512bfdcc30a85fe32a3116c27d5df318b9fb“,“0x4b7CCF7F7fD7fA19b7601b7FB34F815455c78707“,“0x279ebc7c13d0df732160384d2630a3f7cfc9d19e“,“0x179b3f09ecf230b42fa95ae1b5665f43d0df5096“,“0x0f91983c23681be05b01a97a5eecae56a97a1202“,“0xb9bdc24a2e1a2944ef54d3dcef62b92cbf53d4ea“,“0xf0fA8483F04DcF0BBc097A6b9E6cA95174BfCE9B“,“0x4d87f05ABb7ab6dC36a1cd956E15F28DFa2f381E“,“0x0e93545Edad0Ba8884bCEe70618c3D8D4D73d5B4“,“0xc293646ba27383bd55e1bf53ef3d15465bc19395“,“0x5661941a6e5fe6829437d9d3cc26a8a889fda0d7“,“0x555d21A65b8A007BF47A0Cbb15BE3270706167fB“,“0x0a694f40b49825e71797bc4dab4ba5aca3cdaa93“,“0x28eb8B3B842F183C0aE9975cecf81c3c49f282e2“,“0xd93885908803759725ba5e58fcbf50c0d20c500c“,“0xECcB7a669b12bAc8D35c9646a47329B1298Aae1B“,“0x567935c6cc4cffe5d335a3e8c7d45a97063f0878“,“0xdA214a63da80D05B51664E9174a078f536027162“,“0xf6518ad7786cfcf8238a225e83b1f3a3065d729d“,“0xA73f2964aA8029A56077AbaBa388b42700d73157“,“0x5c0896b8fd3723ceb02e29e607e7b6413b42c678“,“0x417ac1bce3d92218148e2c969aef72c33a614f5b“,“0x227602ec642c631f370495d9d7c1a0babf557305“,“0xa7ABD1D77dAAaB645b91ac671775D386247A782A“,“0x0066bf82d1bc5238b5651595e184f20c6522a04b“,“0x8e1f7a6315aB27B351055823A30168524B8c0f31“,“0xcd19b0f4586a9f32c7bf4a1dd405fe5a09f1e629“,“0x88ce147c801bc26435bbdeeeb4fb6962e7bcaa7f“,“0xad8981c9e21441b8320dcc61d69042e422381a59“,“0x2e039299209de1419280127d6823a3db1e7e1ee6“,“0x1a14738640843B5E919C9Bbe1Dba2797dEaA464D“,“0x148b3ebfa3360c178e6933df7c74ff941ffd8caa“,“0xbdc621888dd7cf58554b799205ffdff29f7d3c5f“,“0xD02f92DD3A5B62735A97163A316e167725F6402F“,“0xf90f4933d08d154ebf51910b29be5abeac539925“,“0x08eda6288d98ff58ea32bc06d45c9b25db44188d“,“0x40A7Fd5Ac36D85779EDbd4B2caB972e98204D046“,“0x7ecac18f0cba0944e2a410e49b851d7cf0fd841f“,“0x192dfd9c08cd9e17cc695913bca39b36ec425324“,“0xAf3B3A6DF0Fa6CA0492e08763bfa7B70F18a2eDD“,“0xb7eCBF7070e3FbB20AE7Ad431933895439f7f32e“,“0x1aaef692090e169f380e3c69dd76cd67680fdba2“,“0x5019102c5459ed5d739945a083e8f44c4e3bacb9“,“0xeA35C92FC2b2D0ecA27FAE3E06F26a801A1Ff469“,“0x5dc0d2198c14295d2db50428ce310a9444629c85“,“0xc9CC632FB4d2DCE6fbe0d3e878D1Deae29eaF55c“,“0x4f57b97c74d7d53f1456a274fcbeaa69549fd77c“,“0xEcBb31cFe6dcFd3e19CbF406F3c1BE8cC98fB776“,“0x43b1ec35ae062dac2a9ea5f0b931d5885650e699“,“0x16486edaff401e24b5b700fbced55f6683d04e43“,“0x089f703993f0aEAAb1E5FE6A800F3fd09E7745F3“,“0x06Dc4453343220b628ec808107d6202439Bf0796“,“0x07f4b7f3c85aa8a3fceb113b7a424ab822ce77a9“,“0x7d10540Fa7dE76E680C82Dd6B3f8609F49856C62“,“0x1aD0b2b07f2569B2769A2d268cBb5B235814A873“,“0xC9ad44f706a095DdCDc4160d67156C5755d40558“,“0x8c8d2ca8c35e64927b2682a06ff63b605d53c0a3“,“0x9fcBcF7bA93cA69c2e5c0e5EE730cf53De134Dfa“,“0xc942237914981fad5815F79F8f1c1292b98913E7“,“0x6b37cc92c7653d4c33d144cb8284c48a02968fd2“,“0x136e409d3c13dbf044d8eca5e6c22cb0a7915500“,“0x981A2deB4B14120a53d0c26DdFf0a31BC97d832D“,“0xb765078c5bd5dd765fcec4f76a645e1fcf138f26“,“0x6b457D26280aEb379A99BF1CD6d18Fb0a1e5d556“,“0x9b5af1cba88223223776d941ff75f64669364c1d“,“0x3B0c24E6E4E5cbE2c7197Ab519818640D4DD3A70“,“0x96E656C2bd7bC160AA7d9b32b71bcf3F0be505B1“,“0xeAEF146aFe18EbE5Aab6b268D44100a29d9e588d“,“0x3c57221876f8dd12a3aa18f5fabd5ceb07225c5e“,“0xF10b1C10dfBB3f7599F8EF534237a12cc927FD60“,“0x249cb8fe45e4c55078291947914326d585e0f606“,“0x7bd799fd4d0a67e8d8df16ae471302229af6b529“,“0x22CDBd38302a633b7D51D629aAC054DCAA4382E7“,“0x191807c10f85c1cbe4222a03769ee3cb994dbc3b“,“0xf6a80093b5122216D2C5eF41D41495377ed4C229“,“0x0f211999060608aC300D49DD43F51c0163688859“,“0x9dA5A23E52c7C954D8a1e51f642f87D3a84c9b5d“,“0x005ab5979532d34dc60a4582597464df0b5a7c87“,“0x70512692d4870D1b24cC9a79622BEC5738571610“,“0x5991dfa9e7b1a37414bd6e6d7d4ea82838348918“,“0x93abDF29475F6b6606F3b64eF82100513158b587“,“0xe73867df32d411fca91831db9348ad25cf078d7f“,“0xfece31d9ed6b02f774eb559c503f75fc9b0bce4e“,“0x344ad6781370af1d1a21a81b1016ce278bb24ea9“,“0x7D6fDa15570372317c64AaBf38AFEFA5f42C482D“,“0x7750e9c7A664D86f964156fE94DC2e933a1f3E22“,“0x9363732e97315de21a1f8e2874f89e0439014188“,“0xbed2ecb6b6b38d2d4bbe1bc94593bc420647fd82“,“0x6Ed8082445E85795624db70859dF985ce86e4503“,“0xd80700b680bE2Ddf3a824699607ab3FCbB2b558e“,“0xebe7e229783dc3fadfa4dd8b2e3c42e5e9180337“,“0x7150332c43EAdF93C6b8F94F106141e097F9Bf29“,“0x411b05448df50d9953873f24d97a77b8eec4ccd8“,“0x5022cf478c7124d508ab4a304946cb4fa3d9c39e“,“0x3E158A6c7B7884a0f0D6e4ceEdE4014B173F6A88“,“0xafe2c50eb8f07fd120eef053e4ffebb2f9c0561d“,“0x5a01671a5e62C331c26A07877479F3510A399aca“,“0xE0cb054d617f9464E315FF8b7e253A077EF455e0“,“0xc5e21765454eeff96cbc3155a6b9524023edf519“,“0x4ec00e1fb7c7c1b88d8ff37df74b3b548672b23e“,“0x6E8C0DD97Ab7070cb8fD661122D3d0532CC79D33“,“0x88f429847fdfae8aef0deb4fcf6c9eb9d5dc5978“,“0x26344B29C2369e8996c48Bf9e54c55FeB08902F4“,“0xcd02f3b11ebc6d98ec3fad5d125c2571e67976cf“,“0x322894875e5439d19e273ae180e89ee1838730fb“,“0x7d28e644d52ddc58fbf2c66ba0c90fa6fb02658a“,“0xbe423B502Da52AA9Ef1d7e3C842B8896A3844698“,“0xA5C403763b419cF567CB42E049C7BBf26e76AF78“,“0xe69a97433b9cdfd3623fc5176e05b2b0ed702130“,“0x2574a4Cb0A0B257fBb6520DbD84DD9a8ecc4db9a“,“0xaac3fc6f7e13da537d7bf87eb98b81306bbf9049“,“0xD3f110c60519B882e0ee59e461EEe9e05ED2B40D“,“0xA48a59a8A800af4c0d95261702CeBcD10Fc0EDb9“,“0x9a51Ad691c89A82c7FA757639F47f4406430676b“,“0x4F50f3F6c3c1094DBEBCF02bE8B0Fa976fF6cFe5“,“0xcBEF7C9d690F688Ce92Ee73B4Eb9f527908e381F“,“0xe8b34d2de181a2410345ee92523550500ee80b88“,“0x3266960397Db9B37DD4Cd19d8654e73E0E3418F4“,“0x584743F6C88b066844E47DB8DADa909B3eC5a88f“,“0x4945c459877532aa28d3abc3c41983ac15202ffb“,“0x9b2f12393217b6a0d1fa10ceb7aa49858edeffe5“,“0x2BC72Ed0845115325e485e4CDF18d5E829d9Be2E“,“0x745AFb7A8aFDBDA2e7DE768A70a798C2E69B6258“,“0x774363d02e2c8fbbeb5b6b37daa590317d5c4152“,“0x26A0309dF15CDA728d920d0de84d64652d0AC6Ae“,“0xc7e68e35ccfcb8e9ef4732c2ac14d1aa36d3cf20“,“0xb2e33a00a167c04ca2a008f1e4be276aa964c490“,“0x36fc30a19e9f7c497225c7375b5649c6bd6ae210“,“0x3c5042709008Dd10CbF1C5B3B4BF168A195Bff16“,“0x1325E36D9FDA2FD623cF56a7EFB2aD9cA3d0571e“,“0x877F2533092494761B2FA2D4eaCF034a5c439020“,“0xAd188F0D79A5A1fF9c2bf506a20494cd04976545“,“0xbc5db66eca2e992ef80a2073ba86a46b9e3db842“,“0x411a8fe0e2699b25f4f92f659f2fc71c24bbdd9c“,“0x34b7de664872b89c469b86a6c84c4d42127f51cd“,“0x84ad72c4B1Ef1ad80CcdC3C7cE057E976Ce67A40“,“0x822349013e93b811702777d5dc0834fa940f97bf“,“0x84ad72c4B1Ef1ad80CcdC3C7cE057E976Ce67A40“]

*/

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