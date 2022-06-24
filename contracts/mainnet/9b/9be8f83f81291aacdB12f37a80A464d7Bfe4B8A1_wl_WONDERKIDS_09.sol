/**
 *Submitted for verification at Etherscan.io on 2022-06-24
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7 <0.9.0;

//import "./Common/IWhiteList.sol";
//--------------------------------------------
// WHITELIST intterface
//--------------------------------------------
interface IWhiteList {
    //--------------------
    // function
    //--------------------
    function check( address target ) external view returns (bool);
}

//------------------------------------------
// wl_WONDERKIDS_09
//------------------------------------------
contract wl_WONDERKIDS_09 is IWhiteList {
    //---------------------------
    // storage
    //---------------------------
    mapping( address => bool) private _address_map;

    //-----------------------------------------
    // コンストラクタ
    //-----------------------------------------
    constructor(){
_address_map[0xeA37de3Bcb0b80305B2b2e4F601f88c34BE03EB9] = true;
_address_map[0xEa5B4A38f8778b7Aa0f761Cea0D4Bb8ba9f3Ae94] = true;
_address_map[0xea8E63DAc6CEd17d20787bc4EB9B3f5474Bb3038] = true;
_address_map[0xEaab408170e79daF6D70C1896C2c582E6aE8F81D] = true;
_address_map[0xeaaEaC965449d2426F6F793770b4f3560eeB7c0F] = true;
_address_map[0xEaD898D1797A7f690070C5d54553F913BB1c2a21] = true;
_address_map[0xeAeB596427e5a8cC34443695005790B44e184eFB] = true;
_address_map[0xeAf9Cc15922b970ab012dBdC488E40d2953b3B38] = true;
_address_map[0xEB2BD9378EaB10dbD0b138cDcf3906F76e4E97dF] = true;
_address_map[0xeB46155538c178cFc13D53B101Db174DFaF7D519] = true;
_address_map[0xEb463c4Ad1F5562B18139DcB4c276EECe2Fdb559] = true;
_address_map[0xeb4C271f7828DA1fa19d37AB9162B2749F7f160C] = true;
_address_map[0xeb4c5F9fe9D2600EBbf81Aae782061ae801f533B] = true;
_address_map[0xeb6936620B8300e70F23346656Bf1eeFfFD908f8] = true;
_address_map[0xEbB166E1E8c3b4e9c51E4463Cbf5C59A5899DAB8] = true;
_address_map[0xeBB4975A3fbEaF7FBBcA67f2D68Ec4Ba955Cdecc] = true;
_address_map[0xeBbBE77169ca2Da1cB92Fa7C4BbaaEDC4BbFF0b5] = true;
_address_map[0xeBd905fF679D1444c5d0235c7A252AcB13FeD367] = true;
_address_map[0xebe5F307aeEaa63b5dC1f421b6a44EF82642F33f] = true;
_address_map[0xebf9569679cD90e02b82f81FE95f65aBf3B8d376] = true;
_address_map[0xeC0AA8E3af455a465F55A3fB8F5ee65C29bB29a4] = true;
_address_map[0xEc0B68626F7f4B4ac4c9caE6deF857949bE12A2D] = true;
_address_map[0xEc0E6451C178dcBDf88871623BC0377EF4E1ADb8] = true;
_address_map[0xEC13026bAA3C58757D7fc26C06E4fd349dFb7555] = true;
_address_map[0xec17a63E772303C785D3BDD0f5fc69547da38d2B] = true;
_address_map[0xEC1d5CfB0bf18925aB722EeeBCB53Dc636834e8a] = true;
_address_map[0xEc31943123e74dd3985459E75541cD06cbCA07C6] = true;
_address_map[0xeCAC013D652a6EA8cf0e4621e7F91aFf6795a1c9] = true;
_address_map[0xECB03558D2dEE04b957DDa1242F6bD8DB0287860] = true;
_address_map[0xeCB9aD8D4FC49F28B799b40796F01977F7113E46] = true;
_address_map[0xeCC424C1fFB22bA13d84669F15107f53809B0Ee3] = true;
_address_map[0xeCe942F06756Cc8b32F74840c9957c9cca16e483] = true;
_address_map[0xeceD9aD0a5d603E9caa67cA227B5229A8c5D74Bb] = true;
_address_map[0xecf4205edf8E0024d0a0948332e2C8Fe641ab84a] = true;
_address_map[0xecf4e54b03aAB513bce69aC285460CAF9009b9bB] = true;
_address_map[0xED2815C6551a445A6Bc4f321f87D628F54214e20] = true;
_address_map[0xEd293F44e3Fef1b5FA08c1121b8Ab67C1B805982] = true;
_address_map[0xeD34017A6574386545e64Ed55ec1B7a3ae236640] = true;
_address_map[0xeD374438535dD7B6dCcFFE931Eb04869763932c2] = true;
_address_map[0xEd37E97E2b88555D8ac7FEC9918f051DB65501A0] = true;
_address_map[0xED535b3fb0a21F1b286832fc868ACc04F276e680] = true;
_address_map[0xeD540b08E7cAE7E53a426C79F2763f9295edC812] = true;
_address_map[0xED73f61544E4C6B24B8498Da5723a07A00Af0f41] = true;
_address_map[0xeD85a9A859ea17fe9DDa0050189Ab606b11D8076] = true;
_address_map[0xeDb2DD50d24426F9FD119713Db9014192F01416A] = true;
_address_map[0xedbf8f306Fe60e37049E694CB4E67B75826103B0] = true;
_address_map[0xeDe911Ecd1547842b220bCB977B306abE4d44e8C] = true;
_address_map[0xEE175Ed96e8BEEBe0b269fdD6D86d3f6Bae7a83B] = true;
_address_map[0xeE20b1A6F93882303ef00D9fA517130d9Aa6175D] = true;
_address_map[0xeE2E57fbdcba063d678fEB56ed4b6b1A2e92AAEe] = true;
_address_map[0xEE353f4238D57c57820D65466c1590c682986183] = true;
_address_map[0xEE4216fCb3b67a0a43c0Ce8f0a2d51C83Fb80685] = true;
_address_map[0xEe45D6C2A7004E4e116930541C455F4661B2D19d] = true;
_address_map[0xee634eaf884d54b7748eA592032762620b89495C] = true;
_address_map[0xEE667a3c89C7EE6E5a9595F998D32642DFd0931f] = true;
_address_map[0xee7327558307A67E8775F13cbA852818695C663d] = true;
_address_map[0xeed353BAA0fd7841c2416086CC40E0418Ed6Ff9b] = true;
_address_map[0xEEe7D0b7E1c53793a6C62D0a386aD262bdDB1028] = true;
_address_map[0xef1019A094d98cFE00e528EB264BcEBE39152E27] = true;
_address_map[0xEF1545C9295f8Cbd98500060BA13E1559c42c5e8] = true;
_address_map[0xEF76c42A5A51EC023955d67546e3E56a624BA2e2] = true;
_address_map[0xeF95BaD386c2a8be1238001C59bAB2aAb3008962] = true;
_address_map[0xeF9A85d20868982720e914c1118EF452A6491a5B] = true;
_address_map[0xEF9aC01A922703BAC973FB67525C35fB59203111] = true;
_address_map[0xeFb4da6E920d6616b703BCC9519529B45e500ab1] = true;
_address_map[0xefBe574e11C00e1402D051C99737C066fA33b0e1] = true;
_address_map[0xEFbf4bc901F2E91d997295AAad6fb56A251F46AA] = true;
_address_map[0xeFCe60762558E113395d48B58E8567c556D36f23] = true;
_address_map[0xEFec274B641210fFC47BcE55F313F016804BCC66] = true;
_address_map[0xEfEE7fD9aF43945E7b7D9655592600A6a63eFf0D] = true;
_address_map[0xEfFb59D74C765eC367eD8002467345B528EB451b] = true;
_address_map[0xF015446237143e9643Ec0313183177910c57B8f4] = true;
_address_map[0xF0202490acCe033f338438A5624f3945F58a5cc3] = true;
_address_map[0xF0234EB6206B3e3287C02B049379E0cA0f41e3Ce] = true;
_address_map[0xF059790E3ecB46866c2223b1E185BfD152dd3e76] = true;
_address_map[0xF08A7b19C342399b6C55B46Ed6A1FC486227613C] = true;
_address_map[0xf0A41a7DAf28042702843b14e4a8797b0cadD418] = true;
_address_map[0xf0DfAe4a08500029dbbc7E4C28fBFE7Ccfdfc5Fd] = true;
_address_map[0xf0F8E6784Ab037794aF93A1566Edd712E1A1CC63] = true;
_address_map[0xf118C4AC7cE9140603e527e42B86e5024F30e4F2] = true;
_address_map[0xF129B46d7E3392a829a6D6921b7153e4375B9f77] = true;
_address_map[0xF1511E42081F95E17ED204D5Bbfa94F965234e91] = true;
_address_map[0xF15A81397b56472722EaDEb736D94C678eDF85e3] = true;
_address_map[0xF16614032833Bc9019a65E386c4e59b41872Bdf8] = true;
_address_map[0xF170Cc82332B4F71E98C0A04E161fd0DbD3dF35C] = true;
_address_map[0xF1749bDf6778d3FF38BD69c08452a3A3E0034fcD] = true;
_address_map[0xF17e8045CF4C339eC3821977A4D5A3A9AB675f53] = true;
_address_map[0xf1882AFFca88F227BD1Ae1F214a77DF67aD30002] = true;
_address_map[0xF191539a2c4ba0af951438bB6AbFA0625c7Df2eF] = true;
_address_map[0xf1946dad97AC91332F34bf5655ea2381902B061b] = true;
_address_map[0xf1a582f181c8f63030B0d755040Bf53D941d1A6a] = true;
_address_map[0xF1c43051f63147039669A7e4b19D07107418D30D] = true;
_address_map[0xF20787576a8c0a3FEcaF9d5530E387a75aF0c545] = true;
_address_map[0xf210d9e74363C21137535c5Bbf41Be5526b11864] = true;
_address_map[0xf21396Da335D2B291D7bC3c930B5A04C47D9Ff83] = true;
_address_map[0xf2584881b13654001071d79Bf86186e8a27b61fC] = true;
_address_map[0xF27d4903c0A9379210a2F4D4f1Ee765894194893] = true;
_address_map[0xf289619432baE35f33b0BFFf9896443C09462136] = true;
_address_map[0xf28A449b4504aa996f54ddf5F698c3c8A48D6dC5] = true;
_address_map[0xf2bE802ae64E6b1DE3Dd5DFBAAe3FCbecd1c7046] = true;
_address_map[0xF2C0E4c25ce46D3Fb4f17c9d98839bd4208b1980] = true;
_address_map[0xf2DC8185cb244a425Ad325dD0Ac1819109e18714] = true;
_address_map[0xf32C9d557eed21dC8e08E4aCE3E5C2ff20bbB11b] = true;
_address_map[0xf34FB129f2d2767D8202E349439967C2D1F98CE4] = true;
_address_map[0xF370f0E9Cb3f11163F131D877d51974257b09637] = true;
_address_map[0xf37eF7c2A539459C93483030Ea6791bd677e6D9E] = true;
_address_map[0xF3875b88f37E22e324A474F95A6BeC5868f766eD] = true;
_address_map[0xf3882854DfB5c1792E65c38F2c36054AA5317ddF] = true;
_address_map[0xf38f9bC7fc33e74B2aa8cDbc7CD044e79457A995] = true;
_address_map[0xF398BDbd37e57D201D442800b6FAde5563623ec9] = true;
_address_map[0xf3B10029aB079153a55c41a360074ffa78671677] = true;
_address_map[0xF3df33EA1E793ab32220336ED028a85686c2d63a] = true;
_address_map[0xF3e18B371B66887E35048298AdABAb7c17352DCF] = true;
_address_map[0xf40C777bC7Bd3F5B104416c6c0E759D17E1711b8] = true;
_address_map[0xF40E6Ae609aFb91b82B9864D20fD337E9e7D3C2A] = true;
_address_map[0xf42B6C226ad9D7b7208E8fe89548203Dfb306037] = true;
_address_map[0xf435d3D31A3434d90AB974f750CdC26267d80E1E] = true;
_address_map[0xF4634AEEe7727C54cEb465DA7f166762092e9B48] = true;
_address_map[0xf46Be5914c4Ac143273e601f1784164FfBc9Fa36] = true;
_address_map[0xF4763CF2aB2e9B0652b03BBA131f55D9DC4e46a4] = true;
_address_map[0xF4799Cd0EDc792911C8b1072e39331ffD343572f] = true;
_address_map[0xf489A90De7fFAe074B2194A04e46c65002493D19] = true;
_address_map[0xF49861b506FA02465BC7C00A7dFb12d3900aaD99] = true;
_address_map[0xF4C3b6Fa1e48BA50178795Af273A3196B30D67D2] = true;
_address_map[0xf506800A19F39211A2ED143ad52F361A9c3d4547] = true;
_address_map[0xf532920bb32122D6475aD4Cc7634dC3a69631902] = true;
_address_map[0xf54f2721F51Ecc9725Fba2ce4a9e367eDEdd7D4F] = true;
_address_map[0xF55Bf36771Cb2C0222eee9023887665a5ee0F2F3] = true;
_address_map[0xf56f98fe17836340f9Dc6970258018Ef018656e4] = true;
_address_map[0xF5709bfD257332113e677652C5c19cAF29FE538B] = true;
_address_map[0xf587D54b8E5CeD39cDb49f6606fBe3BCA511f510] = true;
_address_map[0xF5a40A74bF78150b41177FBf7476d395900d28d6] = true;
_address_map[0xf5A4918a90D55d7754Db9F2C6dd8181369ad7757] = true;
_address_map[0xf5c10b9266aefa7d44D950a1dFcBAE1Ac4846207] = true;
_address_map[0xf5C8B2B6490CF0aC60a1B54862C52149323E2366] = true;
_address_map[0xF5CfAEd154Ec00eb37069665ccB44d3D62068F30] = true;
_address_map[0xf5d839676F90053908f4b456801198401b026936] = true;
_address_map[0xf5ec6779D899e67497D99a18CF78c1280f9459AA] = true;
_address_map[0xF6008939F2778da4A277a9f36E8b31384C044CA6] = true;
_address_map[0xf608126faD0558b66EE0F14Dc3e3bE2a37de7D14] = true;
_address_map[0xF60FAA239249CfF07c217fC6259b848419655eed] = true;
_address_map[0xf62c3D737ed4fC1D2291Da662C7Dc731daB7afC2] = true;
_address_map[0xF63e0770498f2A9D4744b5509b46C4b355fcd690] = true;
_address_map[0xF640d7683FC4704732f5f39e46D6Da9a0c3ea5bA] = true;
_address_map[0xF653cFa85EACd26ad8b9EcaBbfADEE52e8D9fa72] = true;
_address_map[0xF654995Bafe1C040d094Fb17995A68A68BE457E0] = true;
_address_map[0xF65d9DaDe315d775da0891083048af4b1a75d501] = true;
_address_map[0xf66db5b19b4A94F9EdD439A12C578377c99B6845] = true;
_address_map[0xf674772aCc49eB57960784857b4eF27944a2D94b] = true;
_address_map[0xf675d2D91312F6E3b62103B3b426de5f9B00C0A0] = true;
_address_map[0xF67A41909c9cd75cfF2a76D97Af72EA5484f2dd5] = true;
_address_map[0xF67aCFb847841Bfa69ab2D9d80F93db3340E42eE] = true;
_address_map[0xf6803179f07AEC32Ac85C56420554632AaFFf830] = true;
_address_map[0xf68033Aa99ab3053aB6219cF759F794Bfd42A150] = true;
_address_map[0xF684adACF967d789190c03473A05Cb21c09CC7DC] = true;
_address_map[0xf69197711D7dC8198f8be314F25ac92614B59a3e] = true;
_address_map[0xF69Bb267A131E139ee32B36Cc3b6Db570d3445d9] = true;
_address_map[0xF69f91DE1889013708b42995BE19fF6195dEbB9b] = true;
_address_map[0xf6a8a7923e78A9f9106886e6Af102ED2B0bCFa0A] = true;
_address_map[0xF70518EE1F0740440736cE19bCFC65D3E673917A] = true;
_address_map[0xF71196D24f26B94EC146619aa590Abe96A91eD5e] = true;
_address_map[0xF7364c4F2AD2b792df6212E338d799bcbB11A1CB] = true;
_address_map[0xf74E5dc9482B6f7673233FECe7e6Fe107860ae00] = true;
_address_map[0xF76fb9A9d8Ae84520EBE3F1277860C6e5B48DE97] = true;
_address_map[0xf771F220AE496197693C5a38525B24aD635B0870] = true;
_address_map[0xf774518B6F2A365Cd747CBc269D24BE5188024d1] = true;
_address_map[0xf7878e10119f6315109C6B7009c0b006c00b03ef] = true;
_address_map[0xF79681C186bbE6Ff0238DfA4D0FcBC4B18dd0347] = true;
_address_map[0xf796CC0f0734a4326c523e5bb8C6f6D5d73AA9e8] = true;
_address_map[0xf79e99020278e64F2C6DE5bff03C2E66EAb98D3c] = true;
_address_map[0xF7a74371Aa6544EFF247A80402A61ec649218D5a] = true;
_address_map[0xf7CA3c20271AE04c049E9D2A2bc7DfA3FD67f586] = true;
_address_map[0xf7d2206B7F99BB709C7D540a07cF508050dA11DB] = true;
_address_map[0xF7df35E5b15E7597354a888B179407e2Fd5a0326] = true;
_address_map[0xF7e4d4ffA401bAd6D3Bd90067029F8648C80db59] = true;
_address_map[0xf7f058Cd6D8BC862BE2193AE60f9Fe3387fdFa3A] = true;
_address_map[0xF80af3919e09f7ea98B2101193bd5890d88d2dC3] = true;
_address_map[0xf81723Cfa932f6204de740CABf29aCaDcF35756F] = true;
_address_map[0xF81a48410c448B1D587Be9BBB3b23938e9F4BFd4] = true;
_address_map[0xF82Ca0EF23656120bCd28afd74FB25EFEBD07E8d] = true;
_address_map[0xF84605a0c018313a6B3B817E5a396f4eE8B07136] = true;
_address_map[0xF8605a87bb1665af9Cecb35393e9783874A7D06D] = true;
_address_map[0xf86aaEB9a6a8BBa1E2C4317e771E1CA044449799] = true;
_address_map[0xf88bF56fC27e60F239353F7149f9E5218D72fFCb] = true;
_address_map[0xf8916dbBA0D58EDCc6b87E5e668B62eAFe416339] = true;
_address_map[0xf8B60d5c78f86c3B94580F3Ee9b472bF5F8b673d] = true;
_address_map[0xF8DB01F59d0cAa15067156fF7Ed786EAF207753e] = true;
_address_map[0xf8E9e27e820f1d544a8cf5a25213db7fE4f1d61E] = true;
_address_map[0xf9086a61d8201be70d28e28d08389962f1386105] = true;
_address_map[0xf9091Ba435A41F0D461d896cfea6F5E78fFB475e] = true;
_address_map[0xF90ACe6D1a2437825Ccc59b263A2ca8B85C7A2E6] = true;
_address_map[0xF91129B9919AE278071da6a21F217FFB35657825] = true;
_address_map[0xf951cBC421eBac7d9dF3CDf01b541Fdd38e9201f] = true;
_address_map[0xF954C090054754F0Dc0FA5F1F07DBB16A4ff7bf4] = true;
_address_map[0xF958342A0fd3F0256FD7a6B57377bA8f6838aA70] = true;
_address_map[0xF95CBd91BD7Ffec8919D904C67961D8354a84B06] = true;
_address_map[0xf969b37aD132E92C7c4b2295FEdb435e29d39631] = true;
_address_map[0xf972C2CaaCcFEa0Cb69510432C35154936F6De41] = true;
_address_map[0xF97507BD5f60cb5635B71b43050C2D6455c749fb] = true;
_address_map[0xF976CC76A2821f8AAbFA746151218A58A730A665] = true;
_address_map[0xf987e5bF856F47CE2983264869Fabc02171D2139] = true;
_address_map[0xF9A3223ced3555E83c8107050cd6909B73Fdb1eD] = true;
_address_map[0xf9a635a92Ba89dB5dd298A94c2b76F79148E5C69] = true;
_address_map[0xf9Abf2a96174E8A1f35900167463298476DC58a2] = true;
_address_map[0xF9C43aAE12777357061a98F50689CCC9A7466f09] = true;
_address_map[0xF9C5130198C83b2a1a58b39275ee98494aDa5814] = true;
_address_map[0xf9cdd7277CABEfb75d2F099841CAc7C6d91d4566] = true;
_address_map[0xf9d954EC8AcC3Ab0AF3801d24C9594D9A840825F] = true;
_address_map[0xF9DC6D3885ff2c31FA6B69D4Fc588306885431FF] = true;
_address_map[0xF9e82EEE3725e369Fe8c419990B5d66b5D38Addc] = true;
_address_map[0xFa00D1285a97c7b9bfFdF0279EB9489109D36ebf] = true;
_address_map[0xFA08b62D35F00EEb76d36FF8FaC33B82a476815D] = true;
_address_map[0xfa08c0f1b7B87d30b19CF4A41dd92D37C25C155b] = true;
_address_map[0xFA162014A04Fd1dA553482Bb60E65F27B90084aa] = true;
_address_map[0xfA1690f2778F1F78c24DA9F33eb63c8965293E84] = true;
_address_map[0xFa200C34D24D50b38Fa5099c5cFa3d3Ae8147E22] = true;
_address_map[0xFa3ADC2C59082E0C1aC7F536aB8237227c6e9ACA] = true;
_address_map[0xfa42821FEe89728dF223f6D1e6DDf5841069913d] = true;
_address_map[0xFa4dc543531B5b176EbD03209d4b18b575f76A52] = true;
_address_map[0xfA7D2D7cFaD4be384d9ca5cbb53eaD697100C63d] = true;
_address_map[0xFA80EBfF5A7Fc89CA89aDE11FAc9Aca5Bf01533E] = true;
_address_map[0xFa88F4feA598e4667934C7526CA109CCFa024a96] = true;
_address_map[0xFA8c64Fb79a084d0d6AB0C0807Ef2B2FCc9A2Fe0] = true;
_address_map[0xFAaF2D0fd433CE55D430C9cB4F90b81706885Adf] = true;
_address_map[0xfAbddef137813777008Eecb4e7D8Addb2096ecA6] = true;
_address_map[0xfAd606Fe2181966C8703C84125BfdAd2A541BE2b] = true;
_address_map[0xFAD7d46f2f44c2571260713a0154ff3AC4d0C02E] = true;
_address_map[0xFae28845a9194Ce0a681366f4E6C26978c35b4a0] = true;
_address_map[0xfB08006E2C8066463F1C2552cEb1E0BF5Bc594Ed] = true;
_address_map[0xFB0a7432E63225a67cF3610AEF2c8bE8Db6B9593] = true;
_address_map[0xFB2d5e0C823a504798Ebd009369c1994beF986aF] = true;
_address_map[0xFb5a92DdC966d3eC68F6DE94D3c7A07e351C55E5] = true;
_address_map[0xFB774bCf2587d5A6286aeE5880D66214a42e1220] = true;
_address_map[0xfBc20BA2346118A84057AEa7e973b2F62A0B6799] = true;
_address_map[0xfBCe0e10640bdD85c515F334e9321120f215282A] = true;
_address_map[0xFBD84c67C5f60dC04Ae4e5bf95c71F48e75e5043] = true;
_address_map[0xfBf619b2b87784D6f3bDaaeF9B7E72abca5c313a] = true;
_address_map[0xFbF8E63963E371D355C1D25563ad52376E1B70D9] = true;
_address_map[0xFC2F8a133ecA595cfFEBa7bD1EDc530C63027D0B] = true;
_address_map[0xfc55A72Ec00Ea3595BA5119882C7e7aDB52985Ca] = true;
_address_map[0xfC5C6Cb26A0ceD6f7E86Cad1a4046BF64a8BfF2c] = true;
_address_map[0xFc735fe44c6d15975cfd7e6158B308430b9ee518] = true;
_address_map[0xfc7c9Cae121d7BF10e7f118832bFd7B820d55A58] = true;
_address_map[0xFC801A79dC39Af67c6Fb4BaBdde19fC8755EaC54] = true;
_address_map[0xfC9C99051639eDc0BC0ba970D0900a2ff1BCE3d9] = true;
_address_map[0xFCa40c4541859818a12c60E043191C345323E98F] = true;
_address_map[0xFcA5C4F5881B21CABC48EafB4E470Bdb2ad8C6EC] = true;
_address_map[0xfCB0637C8011F1fd55DE40FaFDB7C26c40533083] = true;
_address_map[0xFcB5096a6f01FF321a36c77F73CFb76EeFdB144b] = true;
_address_map[0xFcBBE6404446F2D4Cb33823699B8673B9db3473A] = true;
_address_map[0xfcCba679D3c8AAF521fBc69aeDBA9666174a7584] = true;
_address_map[0xfcdeA0183CA9aC274457110eB3097d560Df14d00] = true;
_address_map[0xFcE678fE2E5D9A01226654ef9871dCF7a0DD879b] = true;
_address_map[0xFceb9c7fa8D394247c1dbA1F675Ce7E19e68C310] = true;
_address_map[0xFCF050c9f1E6E7f3F44e56cF21b930674638F30f] = true;
_address_map[0xfcf2a04A3fC9A939c7E911d780Bb3D0B212c6be1] = true;
_address_map[0xFd2C395d602A8132E79b59937E561a31ae086DA4] = true;
_address_map[0xfD3692C280a7d048d87c3a3512aC025712855C13] = true;
_address_map[0xFd3770dCb19f001e7fADE64eA774f575bf8a9275] = true;
_address_map[0xFd383CCb6484F26a264a389F656559b0f12D1DCe] = true;
_address_map[0xFD51d40686D72178218dD76a1c2457acC700F3E9] = true;
_address_map[0xfd7e022c7A29A03B39B32D391B780bfE4b646D2B] = true;
_address_map[0xFD845e60eAea6c960d2a2b6F490b53D26925D5cB] = true;
_address_map[0xFDB8FC7Bdf284137D4815cC05AD2d8f925cF7C2c] = true;
_address_map[0xfdb9014AB3E198FfCf263D3591b1f8b0D340Aa64] = true;
_address_map[0xFdc267dF316D8bEBEA63bbE144bce890cb27a87e] = true;
_address_map[0xFdc3E8eDd74A90fe971EF7d56a0C66c870b10F5D] = true;
_address_map[0xfDd03837b329d8814fE9C739D32cE773510418E2] = true;
_address_map[0xFDd58531f067b40c482778E1D7d022468c92189A] = true;
_address_map[0xFDd7F387f979E56ee80e66f5EB1fA919E9FcaBdF] = true;
_address_map[0xFDDA8B9C6FD485c7DDe13F5bcd53512a7332e2E0] = true;
_address_map[0xfdDeA0b5E18a8C2B99D60403eF9aC4F4c3dF6182] = true;
_address_map[0xFdDFeE05d3e454133B059D7ff9c3aFBaFD9aae69] = true;
_address_map[0xfDEAf6918bEb6320d22572fc9452568A1E68E5D2] = true;
_address_map[0xfE00AF7082d71Aa151518A1D695765AD760893Dd] = true;
_address_map[0xFe0c4C3215806c6c23e549468b570613465ab81b] = true;
_address_map[0xfe103E8C68C3B97c37797F94EAcE48D98BbD3805] = true;
_address_map[0xfe369083675d6326Ba8FaD1Ce02c84891b8E1DEA] = true;
_address_map[0xFe410c82a226fe37F34337C3AFFb9413D13BbDF5] = true;
_address_map[0xfe556F80d9666771AB79230483898AC5196c26b2] = true;
_address_map[0xFe70f40e342DdaF75724Bc9FDEf47AD1B7Ebc1A2] = true;
_address_map[0xfe933DDa3431CFe43BA163353139ACF0928f245e] = true;
_address_map[0xFE93f1DDEC4c22C19a62f4D9733731B088709806] = true;
_address_map[0xFEcC15F721386A5a7C03fd1F40BDf69395E5d4Ce] = true;
_address_map[0xFEf982F7c34311850Cd0bADd78C1F62816F8C5af] = true;
_address_map[0xFF4Bae48a145c44429cA93b6D1bC8E655fcb6055] = true;
_address_map[0xfF4d6e2Af2b0E7CBDb64A529441DFA1dD516B398] = true;
_address_map[0xff5c8aB62Be5b0Fb237AA01A417f087AE67010ED] = true;
_address_map[0xFf6bd9192FF140370347F424b9DF11d803aCab20] = true;
_address_map[0xFf88f91AD770a076EeeeFb17b76281d245fC972C] = true;
_address_map[0xFf8CCCF67Bad7cE1b3285C1e380F75D8c526706a] = true;
_address_map[0xff8d9C10973E6f866657691F637e9759B905dfeE] = true;
_address_map[0xFF97A38A89f0A0293559228Ba6b9c87c606782BD] = true;
_address_map[0xFFEA9Bfb8e1B1ddEeD4Dc6b1ecfB2a2f170657cA] = true;
_address_map[0xFfEC2bEAd7c9F4e0B42C28dbD3099b8C1514734F] = true;
_address_map[0x45f54C0DE023E181aBC475038049dc0a609796da] = true;
_address_map[0xe06b37206ABb46630e6123b71834F2a6741d1442] = true;
_address_map[0x4CEf98D34e5BBe12491CeF4D565FFBEb128A4B46] = true;
_address_map[0xD785c68339205C4fE306B2FE3968C53Ac691BdD5] = true;
_address_map[0x18C61672f1fCAE36BB66E08211D6c26282606959] = true;
_address_map[0xD3B254A9F2651a518531Ca4F440B73b9bAD50802] = true;
_address_map[0x080443e2343FEb1cE8DcCbb6950709ed2802D2E8] = true;
_address_map[0x637Fd60cc34883CAb05Ac8B3548c31265A0072a8] = true;
_address_map[0x6f6B0bDbC01CA09608C6d941Da3C29aC452819e2] = true;
_address_map[0xdDA86909EC60d2A7C137131CfcdFAf063DC69485] = true;
_address_map[0x08924f908484eA57EFe132C0dbA1924Cd1B9eE7E] = true;
_address_map[0x9814d772240938469248eAf2e033B83898142DA0] = true;
_address_map[0x6C25d0B9753B76022470F8712a592cc543554379] = true;
_address_map[0x884d9a4C073096Ee84951bf079F8E17bC23AdD05] = true;
_address_map[0x9dB7bbB19f5Cfe7E4a4240F6948B4A5D17beE22B] = true;
_address_map[0xaB89Acb0aa29b8A7B237B64589F782Be73d0AEB2] = true;
_address_map[0x7C795B88706f5d1e6646e6FF99B00f78e49324D0] = true;
_address_map[0x50c9e7a68702Db2BB60B3038F2a8419e92b2901F] = true;
_address_map[0x755d92f76BdD9C831302e8aFfe9aB5C8140fFBa1] = true;
_address_map[0x6aAD9B4659Ff666e5dD375233F462a0275140aD9] = true;
_address_map[0x6f456f0E92ef60215eb08519329c8B6Aff0f2fb6] = true;
_address_map[0xD02f91a91576205794039d3eDc39321470fb8490] = true;
_address_map[0xF4f5bC71269AE30FaC9b32572Ec06B633a1f7793] = true;
_address_map[0x771cf543DcaedF150915068a36e38930ba1E1ddC] = true;
_address_map[0xAdee0da8219Cfb4b44750c8f00a3f389259CC746] = true;
_address_map[0xEE46741749fAa5a7286ce8DAe6740DdfaE628dc1] = true;
_address_map[0xfa9Acd239F3506Eac0Bde903D16aa9d0B3B4f26D] = true;
_address_map[0x1c1527e8eBE26A6C6dF933A72b20458B6511B5B0] = true;
_address_map[0x84553ad958a3ee5AB45d3ea1D10CcB7e72B3FDA0] = true;
    }

    //--------------------------------------
    // [external] 確認
    //--------------------------------------
    function check( address target ) external view override returns (bool) {
        return( _address_map[target] );
    }

}