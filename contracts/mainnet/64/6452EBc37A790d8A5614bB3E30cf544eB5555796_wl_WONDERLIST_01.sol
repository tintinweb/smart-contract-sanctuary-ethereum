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
// wl_WONDERLIST_01
//------------------------------------------
contract wl_WONDERLIST_01 is IWhiteList {
    //---------------------------
    // storage
    //---------------------------
    mapping( address => bool) private _address_map;

    //-----------------------------------------
    // コンストラクタ
    //-----------------------------------------
    constructor(){
_address_map[0x0162F41850D618670Ba2Fb59100Bf7c6D81fF133] = true;
_address_map[0x01d2f9d2C73dc71b249fD85272E41F7e0C959D6d] = true;
_address_map[0x0258033719cd07175D79B8e9Eb84a6AdC47a02Aa] = true;
_address_map[0x031e0554e687F1aE8c711E9357d204A920Bdad5d] = true;
_address_map[0x055adfD910C81dB0c07801c69956334b4375649E] = true;
_address_map[0x06A68E120505B9E8D8d072c187442f4302e1031C] = true;
_address_map[0x092dFEcCe650bEF80fDA5f75Aca4815d48570854] = true;
_address_map[0x09bbDaDAFb7197292AA75627759Ade341F36DDf3] = true;
_address_map[0x0A01E11ED26F6FD0893dabDeD5Bb538ba828a246] = true;
_address_map[0x0b09486f10D98909A11686f61dBa861CCff84440] = true;
_address_map[0x0b454e00Aa1367Ac82D1C096126e08B92833BB89] = true;
_address_map[0x0b79AD573555C0F33543Cf1b235dA24D948ED04f] = true;
_address_map[0x0db1042C5427056707709b6A66d4f3345F74AF65] = true;
_address_map[0x0f50E35d5A75d876b5C88a8A64c6E4566DC5372f] = true;
_address_map[0x10D50778475d16D7afc906a3b3A15Cd7D6bde006] = true;
_address_map[0x11AA952c8601382530Ca88c7D90eb9ea3254Af8B] = true;
_address_map[0x120c7e6D8BC9F93fee352B9E84b06a2E8FAC5E1c] = true;
_address_map[0x1257EA6f17f3bD82B323789cF08B79191CC82b6D] = true;
_address_map[0x1327F35216e3a6785a2943a70de6B159F28809D3] = true;
_address_map[0x145E83c37D50EAa578D8d08d5a1D68e58BA67347] = true;
_address_map[0x14787F64b7d09cD0824b27636d4d81035dF15888] = true;
_address_map[0x16A33836B1B4b3a8Cc2b591BbAacB4AE3cb26B96] = true;
_address_map[0x189b8E57e0FF947159A16D7cF21cb6C9C28C8E2A] = true;
_address_map[0x1AEF508290334025425aD283BC0C356aF97D9275] = true;
_address_map[0x1E05B300A51DeF1CB3C63189151c2a1c7c2d7d49] = true;
_address_map[0x1Ea196459b0afFDa0973E98470EB37fea5D954b9] = true;
_address_map[0x1ec9331c8F89d122a5513D36869025607DFe6973] = true;
_address_map[0x20e78880d72540c8211c0D30aE9E3576094E9e8C] = true;
_address_map[0x24ABe938973f20f86C47E5748eF5FE08014f5795] = true;
_address_map[0x25a480A9fd09B3867fEf7D2698142B0a379c8d70] = true;
_address_map[0x2993707212591a3A9Dd356418FA9D8bE760c2421] = true;
_address_map[0x2a1D553ef95cd5EBF700D8f8dd77abBb309717f7] = true;
_address_map[0x2afd8424A84820eb7b333A071842AaCb07c311ee] = true;
_address_map[0x2b2B56164f7142221430036f5d11DBf8C6C05Eb6] = true;
_address_map[0x2b852DB04cEE866B47ddd105F86e66210eA8bD17] = true;
_address_map[0x2D375eA53e75F8371d941DeD4488671897614F9e] = true;
_address_map[0x313da51FDA063026A444B5E11A7EeDD1E70f8C54] = true;
_address_map[0x32DC9EBEE6Dd6a0E0F7547f8b00C34de354A1AA5] = true;
_address_map[0x33ae990bf211aCEbC65c8654F3d3031Bb5477c7a] = true;
_address_map[0x344Ad6781370Af1d1A21A81b1016Ce278bB24EA9] = true;
_address_map[0x34a76b75402Ce199754799C5AaBfE5966D4775a8] = true;
_address_map[0x36A37211308a45cC68887E98D26181C9c4fDc0b2] = true;
_address_map[0x389242923bd38d0920Be319660eb331fE3E71313] = true;
_address_map[0x38BE88B700467A3AEEecF3B2139661eF64591d96] = true;
_address_map[0x391527c4608999e77aa8a3b10f70bA35369Fe734] = true;
_address_map[0x3c24218623e99001AD2a5a47beEEc67a8D88C4a1] = true;
_address_map[0x3DbA29A69d4BeF87556d2d7FCe8016156f7D7dE1] = true;
_address_map[0x3e5c8F1fd986141698AE47792e023D6ca1A6F228] = true;
_address_map[0x3eA32494f82ba32bEcd75106479ceDe04AB35FDF] = true;
_address_map[0x403533db88419be6aB1F3c9CdE1D4FC896658461] = true;
_address_map[0x404b87D76062c0bfB5315972D85045C8f11F2954] = true;
_address_map[0x4528Cd221d9a259840b3E68f17870a8B9b4c0a9b] = true;
_address_map[0x483f4bC469dFd3822F618d1Ec861906671477ceb] = true;
_address_map[0x484342F3C513287E74A39B035bee0f3fdF52dC56] = true;
_address_map[0x48e934b7ac4f2E524339DE9D3844f31B1F062eb1] = true;
_address_map[0x497eb01027b622B6eB15387283303161e0e5E7D4] = true;
_address_map[0x4A0D181d3463686AaF127312a6E5432804bF944F] = true;
_address_map[0x4B8A878230907c710bb7525fC4Bb6DB660584042] = true;
_address_map[0x4bd39D06ADb265B8b6cA11314e332A85fB344827] = true;
_address_map[0x4bd4fCdC5DCd51a17380E5fd6EA5960b5F791298] = true;
_address_map[0x4DfB5F910C72aC6A8D2F151D7D26F07807D0Da13] = true;
_address_map[0x4e3Ea7c43F36589DE78235164d143C63F9013Ee3] = true;
_address_map[0x4eD067568823E3A9c6DAdFFd8fe05fA82b3Cbfc5] = true;
_address_map[0x4F7913bd0d55c03d1fcc4F5c35dD2047cE00630e] = true;
_address_map[0x5205D8Fe8bBE8E30b7f39AD77899F393a0F537F2] = true;
_address_map[0x52cbbfb4A742fAF6f7b2f5f2E649D5672b8F03c8] = true;
_address_map[0x5479B817E0C5969b661eF32e8398F499Af222304] = true;
_address_map[0x55de88f64f34aa93f75a21E3E2db71381c2FAe31] = true;
_address_map[0x5713F69Ac8D64049747274eF19F54f8DCce67184] = true;
_address_map[0x57A16A17Da3088b6CF97734Af92531dc77768D5e] = true;
_address_map[0x5A44bb4796Da0bF42cd9953F7404f7c805181939] = true;
_address_map[0x5A82583615AE00f310DBe90d1f0C3fA38d08eF33] = true;
_address_map[0x5C363cD53BD265779C25f6aa536ab6dD8EBC662A] = true;
_address_map[0x5D851D59C9b6632ec1bbc51266eA1c2E52fCEe7c] = true;
_address_map[0x5f612e9c71A10C480C39219Ac06307680351aF64] = true;
_address_map[0x603065425db17Bd315C33750a850E4eC71569ae8] = true;
_address_map[0x6301eF7827A2FB1d6c97932C6bBbdaE852FF2F7c] = true;
_address_map[0x64B1d53951E7750c09e9d3357Ac2774504C30315] = true;
_address_map[0x65048bD386f2Bc5D92d1c2E6E86976CfFec47C30] = true;
_address_map[0x669b64080CC8b0FF5deB29DDc0DB4C43E08990E6] = true;
_address_map[0x6920138B0E147C0DDA81fA7164E0EA5A28070A37] = true;
_address_map[0x6C0c03b6Ca0A87e05cB6b147470b337C9B3059f8] = true;
_address_map[0x6CE4695Ae894d7432fFe10f402B03e5da8f0f7dC] = true;
_address_map[0x6D2346FE3c808B13c6288998F480Eee751dF2aF4] = true;
_address_map[0x6dd435D8862012A9D05408f256C1EF5Ee68e3b3B] = true;
_address_map[0x6e1e95AFCBC0594990A1635b390e77aB8C64168E] = true;
_address_map[0x6F84416190395f30E8A6069aa3B995d5aB64738c] = true;
_address_map[0x7090cE837969b01CE0710C2E7c532560Be8Db130] = true;
_address_map[0x712D7fFF75ca1f3d125Ce94Ed079884871bE3138] = true;
_address_map[0x7150332c43EAdF93C6b8F94F106141e097F9Bf29] = true;
_address_map[0x71bEa177083F9c557E90E980Cf4219584fAE26Fd] = true;
_address_map[0x74a92063EdB68D83c16dFC7272c5cC51969D3aA1] = true;
_address_map[0x74f29659Dfa64a01Cf4BcCd787b926b16C7F56cd] = true;
_address_map[0x763e9A1454BcBc963265363EbAab8BaEeBB06Dc5] = true;
_address_map[0x77a92635AeFa95F840Ca03EB00894e9bC48ED0d3] = true;
_address_map[0x78d44041F04D31Ecf59Ff428456660F853DF305F] = true;
_address_map[0x796220ad1883197571e3977Ef2b64ff4469D14c8] = true;
_address_map[0x79ab4c8ca2C25bf2071678915A813b64371aAD3A] = true;
_address_map[0x7a59b7a75E7677cA1Ff9Cfc5317Eb738ce407321] = true;
_address_map[0x7aF89143E353a8e1903f51D2eD036184eBDDA598] = true;
_address_map[0x7B1049C3326cfffef829bD2d7Ab984dc0a425188] = true;
_address_map[0x7b578cBB2B51AB82c4D2609BB3fd2F752F14ae6c] = true;
_address_map[0x7C38dd7c3d1e53E8Bb8ef09693FeF891F4FC4954] = true;
_address_map[0x7CB7A1dC33D1f13BA712Ae5dE1bbc592D66c8A6F] = true;
_address_map[0x813231066d0208670aDEb7d7a8e7A2ef1df478b9] = true;
_address_map[0x8520f3eA546B700aF09B1A447c190D6eeB943FF4] = true;
_address_map[0x8527029b4DdB6deE7419482f7505cF8F6D324572] = true;
_address_map[0x86f2a71e90251Fc313bB7CF577ef3939Ee93eDbd] = true;
_address_map[0x873f3bF6DbA40A4B1a0b8041b528D149D23b5308] = true;
_address_map[0x88bF32b54b2ba0724DFDB31bA47616d91a5eF0f0] = true;
_address_map[0x89368478d458F40D93C60cF7101384a400C5bA29] = true;
_address_map[0x896151817e7dD89415cD995DddBc751DD7A063D6] = true;
_address_map[0x89ADff24e149B6c4eA2B8b3642DE0c52cbA87944] = true;
_address_map[0x89C2005ca5ae7f22FFB2333caA133c984Abea938] = true;
_address_map[0x8A7C1422FE789c276E21D1792AfDA90f638Ac5cC] = true;
_address_map[0x8cBc00bFB379904b9Ee9757F343b6BcEE6493536] = true;
_address_map[0x8D6287364B4E555060D842c7a6F337b71b07Da17] = true;
_address_map[0x8e8d2E2EC5042D4c102fD5825EB28F0C866AD9B2] = true;
_address_map[0x8f5B3A3a415AE394AF7FdD1F5b0e8806Ca292f64] = true;
_address_map[0x8F66c0c359B4546512BC8dca379B89Ac93008d97] = true;
_address_map[0x8FC056488602054286c65cCf7E4Cea4692aFe37f] = true;
_address_map[0x904d21Bcfb7b2697AeAC41E27006735e83Ada791] = true;
_address_map[0x90CD5ae1c11DdBB1250E41Ece0f8062B49B6B8FD] = true;
_address_map[0x917d48F59e9aB31eD738b4D314bAB1C2B5dd4A71] = true;
_address_map[0x9306b39C83e44c5fB015AaF5A9742B8608BE5123] = true;
_address_map[0x947245F9057514be448236cde5C20Db263BB4F7F] = true;
_address_map[0x956Bd536f309D14F993C0B16b0a048a6ddA2EccB] = true;
_address_map[0x96F12Bf95D439C74560B746264E1C08dA25157F9] = true;
_address_map[0x988cE94b9271ed4B323B745c1F63bc4a8ee00E4d] = true;
_address_map[0x998845F0730d2D2bdbb24eef86409E440F7a7e88] = true;
_address_map[0x9B9325b63ace4966d9d34B63249e0aa1a6c5DdB8] = true;
_address_map[0x9BBE5D008C0CA960D1ecca0221dc65a8734F3689] = true;
_address_map[0x9C0cD92865430Bd8642F558682e0A7a2Af85E085] = true;
_address_map[0x9E750DcC35af95A9971ea23E7908D541F30Ab1D4] = true;
_address_map[0xa04d368368bE744766050a3a49f354D4c9D899Ea] = true;
_address_map[0xa2B2e263F480CaB445d5c574B4ae21Bc7E5cB431] = true;
_address_map[0xA2c68ABBF510Eb48Df8Cbc83f9BeD855FC4078A1] = true;
_address_map[0xa35b1F42DDF22930BBC5ef91bFbE1143dCF52309] = true;
_address_map[0xa4a034478123B51EBE7e0f451EADF863c6237184] = true;
_address_map[0xA4E171214710291053918587f6F4887f670d9280] = true;
_address_map[0xa8fd38a9c6F32c6692F4bdAA255Ff81e4a6A4fb1] = true;
_address_map[0xa93CF0e0682BEE6626a2A34e7e1D284a8b8E1E85] = true;
_address_map[0xAA98177DAD812fdc8b37ec61d5f16A4Bf890F2C0] = true;
_address_map[0xAF560180D08972Fd21c1de8A774AefBF5155df44] = true;
_address_map[0xafF8aEbE998DDd7F01455b82099BB891e082FCc7] = true;
_address_map[0xB0b8a803867Fc0827b57e6376773DD0050855Ec7] = true;
_address_map[0xB1AC8Ee730Bb94501Afb3734D30220379EF08670] = true;
_address_map[0xb52aD0feF1B864B03a4F8A4343afBdA3488854E5] = true;
_address_map[0xb5dcbf3D00bE7f1B15395701737d5206e3241A83] = true;
_address_map[0xB645443F5281C4110E6a61b2B080baca7C49018a] = true;
_address_map[0xB647A968616Cede5C5Fe462C46019A3369abf88f] = true;
_address_map[0xB67B95d9c36cf72e0aE2E38A0090f95126bE19D3] = true;
_address_map[0xbA948eBe66622A35ecCd975F7946660EaD971de4] = true;
_address_map[0xbAcF53F44cbe63745fFD1071EDD541697F76f256] = true;
_address_map[0xbbA46ce95FC5Ff00340DB99C14143Fb609aE0485] = true;
_address_map[0xbBa548e4Ad64f9c1a6b88871d391254275415196] = true;
_address_map[0xBbC4b18ba8557bcD5327D28509663b2f3546f3E3] = true;
_address_map[0xbCa6e23723734d50cfe49942D17474f684eE665F] = true;
_address_map[0xBD3771A46d27f6c8980097C1fcA418f463b58f48] = true;
_address_map[0xBd7cA07Dd3a69dA7C0F0d9E71E00867a40Bb0ff1] = true;
_address_map[0xBf38041F64D5842199182Bd29B5Be78DDd8Add1A] = true;
_address_map[0xbf43A0DC1FE0ac4E913018b4a263Fd06598F94b7] = true;
_address_map[0xC0113d4b54618047dfeE92998D108b5f4F7cAe73] = true;
_address_map[0xc0C71341BB99d6390aeb8E3728690Fd6d6591832] = true;
_address_map[0xC15A4D09f9CE1633995C17F707ff01ab767509D2] = true;
_address_map[0xc173CBF586BfCFdb4B01073c45908029ec6d064A] = true;
_address_map[0xc272aF7C8bBC0294E7fd9e6104AE4FE919D0FBA7] = true;
_address_map[0xc2AfE893D416A5F8671a28B71bE1b24e0e374294] = true;
_address_map[0xC3A73Ce37e7989Cde8219336027c3ba4d1a0E933] = true;
_address_map[0xC60D18d515C4C44aC5b5207c5fF759cCa510915f] = true;
_address_map[0xc71367c220c71A21cBb3408C136D8044106853a1] = true;
_address_map[0xC78aef47a1dC5c25bFF411554DbE65D06918DB42] = true;
_address_map[0xc8927eBB9B46CDA649B04fFc7D03f0dB2eEC212e] = true;
_address_map[0xc9196cde9ef83e45C36e9D7Dc1a1d5Ac662B4913] = true;
_address_map[0xC9DaF6831162AB6087799851254997986fE55602] = true;
_address_map[0xcFB5943CBA4199A465B68dE480B28A26139037cF] = true;
_address_map[0xd19Bc567E5675f56b4737097fAD35ac89E0308df] = true;
_address_map[0xd5DfF43465dAb6f4D0de430Ef5734944d8f81774] = true;
_address_map[0xD6E19FE59A4AcB06F83E90a71A00768e44375f1f] = true;
_address_map[0xd8e75A9eCadFD63c453995702e3a5D185755A4ec] = true;
_address_map[0xdBffBa9aC2A97356bafD78b964ac8882326d628b] = true;
_address_map[0xdD8C6F94dC8C85e3A45FfFa8E368196deC8EDE15] = true;
_address_map[0xe1507f5a4E96a812da5892D2a82BaD12aF6A14d2] = true;
_address_map[0xe2A44df1496dBA86165b12D8E737E9B5bcc20D3e] = true;
_address_map[0xe2daA8a682385A160fE0685ACdf9f6f0BE968fcC] = true;
_address_map[0xE2efacc45cb0e006172c91dd3FcD9A60Dd4AE0D5] = true;
_address_map[0xE301170d8F7Cb08206e217ecAe025e839b066957] = true;
_address_map[0xe30185b81bCC9Ce290325A68c3F3748497D8A46C] = true;
_address_map[0xE8049dF428606838b22900149f757d8535A2c38B] = true;
_address_map[0xe834dB4C3e43E3096ebEdd6C174943ba21D051B4] = true;
_address_map[0xea9835B634Eb13908cA679194695BDc05bE99B91] = true;
_address_map[0xebA2b8cCeD760cDA89E603B58c5f465EB6349afb] = true;
_address_map[0xeBcaBdA0EA2856A7544fC1452305ff99cd04496b] = true;
_address_map[0xECe0A3d17ce74f7D213E86D66cFE19526a7A4632] = true;
_address_map[0xecFa4277c066018fFe6DDfd73896BE9757AA97D4] = true;
_address_map[0xeFb263c400A970f7B2031730A9776361B63AADcE] = true;
_address_map[0xf32c5f84df4e81f3CeE20E51a152d81D6b261F84] = true;
_address_map[0xF39E7920d09328869F4B7899a757576EDA00124b] = true;
_address_map[0xF5f0c37873c86E9b35CC192ac860026C7a92A17C] = true;
_address_map[0xF85fD87a7464317855dEc643911c89038b4C2000] = true;
_address_map[0xF91FB29BD99d141dEb2ce334B2E5d7eA27BC9fE1] = true;
_address_map[0xfA3352CB2F9A78e9Df01a9dc3e789f2eCC75970b] = true;
_address_map[0xFa3FFb7c596A8eb7F622942C194568724c546206] = true;
_address_map[0xfB847d0EF1449c505561230E192F46Afe681AC7C] = true;
_address_map[0xfc07d4a6AA17B6EA6C16228088F12A3b93e92552] = true;
_address_map[0xFC6e1Ac74f8D655B3E1523EA49978600f3CeD992] = true;
_address_map[0xff4f16E4fc26495F6E00516fF93C5d86DE5e0b95] = true;
_address_map[0x3867eb606B590A3E885FB01AfB81c359E002305a] = true;
_address_map[0xA612844160Aefb72D783613C5A9792c0C1B902Ea] = true;
    }

    //--------------------------------------
    // [external] 確認
    //--------------------------------------
    function check( address target ) external view override returns (bool) {
        return( _address_map[target] );
    }

}