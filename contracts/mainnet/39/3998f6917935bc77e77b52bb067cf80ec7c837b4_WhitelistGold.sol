/**
 *Submitted for verification at Etherscan.io on 2022-10-30
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7 <0.9.0;

//import "./Common/IWhitelist.sol";
//--------------------------------------------
// WHITELIST intterface
//--------------------------------------------
interface IWhitelist {
    //--------------------
    // function
    //--------------------
    function check( address target ) external view returns (bool);
}


//------------------------------------------
// WhitelistGold
//------------------------------------------
contract WhitelistGold is IWhitelist {
    //---------------------------
    // storage
    //---------------------------
    mapping( address => bool) private _address_map;

    //-----------------------------------------
    // GOLD コンストラクタ
    //-----------------------------------------
    constructor(){
// ↓↓↓ ここからコピペ ↓↓↓
_address_map[0xE2E577A889f2EB52C84c34E4539D33798987B6d2] = true;
_address_map[0x31A6d0EA27db941257024189A3718472d40ef663] = true;
_address_map[0x5DDCbe1Ec48eBACED1D8739dDf87de38E7fB52BB] = true;
_address_map[0x20045E3e280eB57DF5f860A118239447182E334b] = true;
_address_map[0xa5b2eE569fF5Fea84261533b5804E69af4227979] = true;
_address_map[0x49A6374A6D792b345f7029577a3b7BDaDb29cD80] = true;
_address_map[0x1Ae483291b9F999632C19a3b234598148A02b4f6] = true;
_address_map[0x3E4332919859299B23CF1121004dd5bb7acf4fFe] = true;
_address_map[0x414C87E029342433E2645699E7906f1e9B6CDbCE] = true;
_address_map[0x2Ab9Bcf16E81651febe6FebB8389Be934Cb33269] = true;
_address_map[0x2fC866646e15868E67A57c6474e9d14c8D7E7318] = true;
_address_map[0x35b63a6ccA6563fd3495d51F45aebeCF0E1616cF] = true;
_address_map[0x8885F429D3bf782f8E82009a46727Bf4b4ef6802] = true;
_address_map[0xBD99683dDa0Cf16f3c8df6711523220f735b64eb] = true;
_address_map[0xC4d7A04c2539638C0a08930839A4fC09A5cAdceF] = true;
_address_map[0xda8A55F37fA45464642241b280B674f204d57539] = true;
_address_map[0x0aA5939D2f73A9e176132ee492b207d5366DCdBb] = true;
_address_map[0x832D15aEbc931529F7CE0f4ABCeb5233B351C16f] = true;
_address_map[0x92Fc5796313be0Cd9fE19Ec3dF411d808E7aF715] = true;
_address_map[0xA2176F47Ce6B28528D758A674C7fe97CBBa32f9a] = true;
_address_map[0xC1839cEa93BdFdF29E08ae3F351813fe7E89afB3] = true;
_address_map[0x01bc2E40338f8B40490caeAEdDdCF7343B18e949] = true;
_address_map[0x08D816526BdC9d077DD685Bd9FA49F58A5Ab8e48] = true;
_address_map[0x0b122c9d7B1E0dc305feb4CBfE97646d02a10bc6] = true;
_address_map[0x10e97c1d986065aaa3F774dC115Db0312533ecaA] = true;
_address_map[0x11A794faA73eae621A5a7D5A832862f928D886d3] = true;
_address_map[0x15D1de6E574F922F9D29beC95367F333A643876e] = true;
_address_map[0x16D6ACca2C7e7649741c5d03da24125928ddF831] = true;
_address_map[0x176FfF8b046f5B89EA328e3A6a79D6fe88905A0e] = true;
_address_map[0x2529E74F638B69AcFc00CDf2053E60913D90c2bc] = true;
_address_map[0x290564a21C7664027E95B475BA3B4b876cD1f981] = true;
_address_map[0x2dB78D8d11Ef03d995162B3Cd6b6F5cFCf890092] = true;
_address_map[0x2E4d695498296DcB443E60A53Ac6E56a22a5C56a] = true;
_address_map[0x33540B50214D1162b64a356699c17e6bb172e6eE] = true;
_address_map[0x394B9f09c4e0Cf8138016bC4cea8D87011B2bE5d] = true;
_address_map[0x3E5D6D156dFEab4Ae977f5d6a5Bb555545274B33] = true;
_address_map[0x4080b0a799dfD5d16c14A355c4395FFc11dB5258] = true;
_address_map[0x41089B971D22ed2be9E0Dabb7Da3b5A702B737f5] = true;
_address_map[0x417487275239E0f6c5AC79f5D60135eCf118169b] = true;
_address_map[0x41Ed9E0f88A16468D42074C2aD4405C187Da52bA] = true;
_address_map[0x42f2746ECF7F891b62c167e16F4D1BfaA23764E3] = true;
_address_map[0x4cF2461558Ef38B08cc608965d07e5F833283705] = true;
_address_map[0x5268A4F2D8ef2Bb3b37Db74b6a1701cD5c6A347C] = true;
_address_map[0x5586163d3dfeE2C2132c1F2f4d00e56D8D40651F] = true;
_address_map[0x5c060BA9A77222840BD625DEeaA7D954B5B72427] = true;
_address_map[0x5d61f268EEF978c27d56fc2722111481e6Ae21Ef] = true;
_address_map[0x66143651495a1cCbFd2F708af8336C580935349a] = true;
_address_map[0x6b7AabD0D382bc4f65998938fa5244979Fceed47] = true;
_address_map[0x6cA0e35edb84477B9FD5cA1C938aDC6c9cbbE02E] = true;
_address_map[0x6CC25Fcf8B1177c18De747Ad0782d051A4847BfB] = true;
_address_map[0x70d5555964581D97A544452f66908913e7cC0730] = true;
_address_map[0x769cBc21757FE7466b37965bCB0F6DBe59797551] = true;
_address_map[0x7A22926766Ca6bE4c130b2364772858105313134] = true;
_address_map[0x7c9B00949cCb7FC7159C0C0a3658016254d0a129] = true;
_address_map[0x81c6F7159a48895E327581eDEB8ab6DBd0474b31] = true;
_address_map[0x82Fd2e41D34ad4016e523243ceB4354E9706C7Cd] = true;
_address_map[0x878a5c89F8B2fdAa94613d0b81EC425e9A427985] = true;
_address_map[0x980d508c634402E200c6aE56D05df0C9296fA55C] = true;
_address_map[0x98839bE4d57071bAF75931ff23Ec245019c09008] = true;
_address_map[0x9A1fEe8b2b576F198f75493aa8548DB879e7fBB6] = true;
_address_map[0x9A3601F558Ae9420B99e8886D8B1875Ecf966B26] = true;
_address_map[0x9AA8A642CCc6Dc9ADC1964C075cB4e238DD0c26D] = true;
_address_map[0x9f1Ae66eb58cc6D3c3d5c1AF0a06488e59495Dbc] = true;
_address_map[0xA0fBA709709ea4a3e7CAd70B136FA7160D600587] = true;
_address_map[0xA59ae8eD8f70c5e5DCf62096E74F36b19E06c3D9] = true;
_address_map[0xA69FFa7688fCCEb6eB5Fb2F0797276f2FC87675c] = true;
_address_map[0xA85a9d5BCe365d6A5C1aA56DB26FB33EC1d5a356] = true;
_address_map[0xAd02E96e03B48950032B2BA18F913d50F26fA636] = true;
_address_map[0xb211eA8E001C88094c1ecbf8d19d326fb2BC8117] = true;
_address_map[0xB2399AB508305d9f72aBb24F29b6b0E3D1B8C83C] = true;
_address_map[0xB73ffa31C4Bcc97DC93f625F29e8102A172EFa14] = true;
_address_map[0xBeDc4CaA6a8D745153F5242B4bfccbC6618e336f] = true;
_address_map[0xC264b4a5fb07202721eAaF13E756a91A34C409C5] = true;
_address_map[0xc488d2c503f3C173Fb583cEc2d32e3d8236Be21E] = true;
_address_map[0xcdfC54E2cd680035d29aeB5D4747429B5807cCf7] = true;
_address_map[0xCe5f96Fa13ceBF79fC6244b9e7e719710357D9D1] = true;
_address_map[0xd0A2f14423ede2df5FE66b61419858c8e3baB3a1] = true;
_address_map[0xdB12b0A826d10ecca7a783caA1dAa508AFBD6Da9] = true;
_address_map[0xdd1253c5484b655F8274E72560301a57928F9E58] = true;
_address_map[0xde38c6964f840afeEB6D891cb4F6B132498579AE] = true;
_address_map[0xdfA41d85bF9CB9895359c3772c8E883aB8dB6bb7] = true;
_address_map[0xe5e66D63F994d69a331fa5c62AB6B5AEF14D4E5b] = true;
_address_map[0xE656FB4C4cd4975736643a1Fa2f06741E3231754] = true;
_address_map[0xe693f386a965D8f87B72e43E46E756b362232253] = true;
_address_map[0xEa43a05FCF39AD68C1bF875433dBfFa81f032239] = true;
_address_map[0xeBf5FFbFA0E3dE2c28e8CF0bc37Fa6e52BF96c1E] = true;
_address_map[0xeCb274B4c668CfD786799E886F64A538E7130471] = true;
_address_map[0xEd1be6aAEFD1FcE4503E92612b1f5dd2c2BC9324] = true;
_address_map[0xeF8226905FbE8f6C2ea484b197d10F7cdF8d3CD6] = true;
_address_map[0xf635736bab5f3b2d6c01304192Da098a760770E2] = true;
_address_map[0xf636b3416676B9C92D61fbbE493fD07930FE0990] = true;
_address_map[0xf8713e8853318ACAB12b5e8611dF8A23Fc4200F7] = true;
_address_map[0xfCDb8896aF26b901D8a352494Aa485c7C5278D8f] = true;
_address_map[0x0dAE5FcaD0DF8E5C029D76927582DFBdFd7eeC79] = true;
_address_map[0x144DD16B7FA560138bD2E0206c1595b8d09B2b2E] = true;
_address_map[0x1FcbF13a4e905B32cbD0084Df60a10c344553f6a] = true;
_address_map[0x36adfbe32C33a5ebF9B63C17c08C0D38CAc5B257] = true;
_address_map[0x6E3CE12fADA11CE7bD89bB0fEEa9301cac628051] = true;
_address_map[0x7E2e243cA79343CC9f486c968bB90434E87161A1] = true;
_address_map[0x81F6B1ce59265b607d5f052FEc63121A1ACac39c] = true;
_address_map[0xb2F44039c65CB18522c941Da3a2299197f7bf635] = true;
_address_map[0xc1AeE179C1456F2ECB3C6D20e6A10871cA83dE23] = true;
_address_map[0xcB216311812Dc82e6042716Bd8579344534e8292] = true;
_address_map[0xe16d756B1E27CABc43c8C4cAdD68004aB50452b2] = true;
_address_map[0xF5d70cC9092Fa91f21aB8e081639B0Df788696a5] = true;
_address_map[0x01701B8076F14F5B38664f7Fe1a488e64bB51633] = true;
_address_map[0x039e01717916faFd3151d366Beda49989095D066] = true;
_address_map[0x03Cfb42f69004C1FA9d74ed8EFB7E651542c7AaA] = true;
_address_map[0x0712BC30BF0f88c4651f2F43c169B9B0aDC2c0D4] = true;
_address_map[0x0C8aa61195c7bC4FC7Db596e883034B3F16d9f9E] = true;
_address_map[0x0Fc7E383f202eb419fE1c5C3781944485a1Ca5D3] = true;
_address_map[0x11dd935d65dbc8425e8BA1d9cE4d85E8E6000737] = true;
_address_map[0x1c3E8267078aD1ED81746fF47C4b8317BFA47207] = true;
_address_map[0x1D479e00ff02ddD0828530cf3303f6ebA930D0c8] = true;
_address_map[0x20d07431918ba08aAf76abAc3F35884A6EEfC06a] = true;
_address_map[0x2309F28d888D8801ff41011ddF07d8aeFb5eF61B] = true;
_address_map[0x250F57B82926cf595C0b105dcb747D5aB806a438] = true;
_address_map[0x2597e887C06Fa7AC2b674069046ea980579865d3] = true;
_address_map[0x2aA1B614338c6cE528E3905688452D7270A2f16f] = true;
_address_map[0x3265cB098B81104a03d045d07667bB99264D33d8] = true;
_address_map[0x3428BacD15D15E5C9B8Bb2F9e1445F49aCC8AD17] = true;
_address_map[0x39c37403Ec31cF556448ACa2fDeAC4E1C5db8dC6] = true;
_address_map[0x3c1Ed067a22f87a800a9986BC905617934d8D94E] = true;
_address_map[0x44B20d590090d4072BBE4d3a1e2cfB42eC2104d3] = true;
_address_map[0x45150Fa60C1c7C15D55A83eab93687c52Ce435cE] = true;
_address_map[0x453F70f9d222845EDD5D0BE4Ce088ED7dFD529E2] = true;
_address_map[0x495D8bab401537674B150B0FDBe2df200D4652D6] = true;
_address_map[0x4A4eE77E0eB4bbb6836bAaC715bAD884D9430942] = true;
_address_map[0x4B850E08F2fb6f134E2CEfC4A5Ab1eE42C9bd4E2] = true;
_address_map[0x4d105B5D4C9CaafEbcB628Bedb8992F9801bD63C] = true;
_address_map[0x4f80C68a12009e83Ab8891d51d400412AEa0A3CB] = true;
_address_map[0x5018fdfbc087d7c991030B4e535612D885b1D683] = true;
_address_map[0x5026340c0661BdB9FAb6FbD94d081C984F16D20C] = true;
_address_map[0x50De3e34F0Bed163f732c0170DFB82F542f0A110] = true;
_address_map[0x5231Bf53e8192cfB109F0a28D4CC02744bf37304] = true;
_address_map[0x57fD566F5a9cCfb885944cA3048c066467fa62ac] = true;
_address_map[0x5E8cc6E4d430d036286BC604775988c96f988CEd] = true;
_address_map[0x603dd578CC592eB8a4d2A942A707FE6eD2d1Dfb1] = true;
_address_map[0x645BBf6f6B6197c98874e1696d399E26eE40f431] = true;
_address_map[0x67C488e59A19b6e3940c6C62285728f6790DA1ad] = true;
_address_map[0x6D731AfA7A70917e4a2BFEbE6419610BF53fb035] = true;
_address_map[0x72238C401F938a066517973B04C08D7285D21065] = true;
_address_map[0x74221140f92a55542E5b6e67cd5E9e46D6a5b8A7] = true;
_address_map[0x783255a509d007D2036F11d6BA53E162bd7a67C1] = true;
_address_map[0x7e68F88d22987275AFFF83432482d8d7109Aed73] = true;
_address_map[0x7F5063D2a6CfFD4392CfF8E8B9685A8f8fFaC5c0] = true;
_address_map[0x868F9681f0abd4bAB4CDd5c8D63A3C2BB717D92b] = true;
_address_map[0x8971B78068dda062230211b1ce198A89eCE9EC00] = true;
_address_map[0x8D27d36bB95F0844cBAB601Edae77997Be535b42] = true;
_address_map[0x8dc863127527781b995fa0C41168638e398e9465] = true;
_address_map[0x8e5aB1bBD564B57F5f5353F45630069C4CAa39bD] = true;
_address_map[0x8ebaF3F8481a00c8a98e30113B4f3b0cFC94D606] = true;
_address_map[0x91eD71046237BA56066d13971cd4dbb72fb7f196] = true;
_address_map[0x91EF2a37f46A805F8Ba7De34CAc81Bb5fbf16EF7] = true;
_address_map[0x932e2C620C7671718088b61087dCfBF92AE5Fa03] = true;
_address_map[0x951298F6a48D9Bde9CE6D1FCdb5080BBA855f4c5] = true;
_address_map[0x981fF6010165Bf1BEBf569d435b15410653DB198] = true;
_address_map[0x983951F80227cA2F016C8A1270d13E152EA27415] = true;
_address_map[0x994d1b5B8c88aA1Ba5B902eae434ef067b6859bB] = true;
_address_map[0x99e3e6a7620f8d152bcfbe8E67eC7A1B096DeF5c] = true;
_address_map[0x9a43C0Fe3019C06E94c573f272eaCC1a29569943] = true;
_address_map[0x9E2FCbDba124f676BFC2FDE43eD83f69d35c78EA] = true;
_address_map[0x9e55958688a76229e4fd2d58D8987708693C2b47] = true;
_address_map[0x9EE16d5A148841857295cE5986dC516a4e4459D6] = true;
_address_map[0xA1fCfD829dd7c4DE8e27B8E42084FAb3E50Ee069] = true;
_address_map[0xa517Bcc4d563DB739446dBC7703690ADaDe2e13d] = true;
_address_map[0xa672910Cf6546B80f86cF2B095dDf69EfbDeC1bf] = true;
_address_map[0xa817378F6031AbfeE0CD5A4754a0D01A3b970517] = true;
_address_map[0xA8a1bDA68814099c7B573c2f360ccc31148b62f9] = true;
_address_map[0xA9a3E4E3690c6C39c9C5F77F124FfF50D955F7D4] = true;
_address_map[0xa9F57F1D60528B4b81aAD59c0f13612A60231966] = true;
_address_map[0xAFfE41526e66D0aB7Fab2C04557a21988BbD6825] = true;
_address_map[0xb1505fE87A026A3710b7912e7c0B7fD3Fe82D206] = true;
_address_map[0xb6CA441f5FAdB94450cEBcfd5C67613815b5c459] = true;
_address_map[0xb8A019B8102D0d13fA1202ab15F2b7DE3afABCBd] = true;
_address_map[0xBB016cDa209fb5f8EA502Ca156B67C84B6286910] = true;
_address_map[0xBb542550E79fC501ED2F9cf7618dB817D8a790D2] = true;
_address_map[0xbd82BcB10e498166D447a197daAa5EedFcA05EAD] = true;
_address_map[0xC0D369C0FADBCf9Be8A6e4871FA1f6e234bd0666] = true;
_address_map[0xC33425fbCE6A18D7119ce7907e81B151d658B136] = true;
_address_map[0xC78A68b6ED2DE7e98A7C8Fc8f253D570b8941cc2] = true;
_address_map[0xcB2336Fac71CAE39dd43f909309F6487497418b5] = true;
_address_map[0xcFE010E06A23e87c7409d3C37BdBdCa6728DF8F2] = true;
_address_map[0xd3662e2e7543B428Fba4b66492243ED971dFC7E3] = true;
_address_map[0xD64493990B91aA69e6D1e9e787d04D2dD07413C5] = true;
_address_map[0xD6792DF4E2D5cccFb4962030bA3Fce4628E5266f] = true;
_address_map[0xdF89b886c2AFC32DdA169e1C0A3d840FbaE7BDad] = true;
_address_map[0xE1EDeF369fEfaBBe9323053190724B4a244a09A3] = true;
_address_map[0xE2a9C91fA0a2F24f6204f70923710497A56B8796] = true;
_address_map[0xE2C2bbAc29a8991C21D50cFB76d56Ef455D85157] = true;
_address_map[0xE795947aEd9d1FA2BBd78E19ff33cd7D626648e4] = true;
_address_map[0xed36Cb4aD625e30BC99aC567A29BF4bd84CFa5CE] = true;
_address_map[0xF266a3bcA8c2cD5a90db7Cc7DB26B0E0b304482D] = true;
_address_map[0xF73F450ad4E88f58783Db873769dB129b517f028] = true;
_address_map[0xF8A3476bB78b4E913F99d68ec698d1d6C8EafAb2] = true;
_address_map[0xfAE12c7f516E445C8225eaFb894E996b254e0908] = true;
_address_map[0xfF2051757C9D0FFE75C6857582FEE2eDb5B593c6] = true;
// ↑↑↑ ここまでコピペ ↑↑↑
    }

    //--------------------------------------
    // [external] 確認
    //--------------------------------------
    function check( address target ) external view override returns (bool) {
        return( _address_map[target] );
    }

}