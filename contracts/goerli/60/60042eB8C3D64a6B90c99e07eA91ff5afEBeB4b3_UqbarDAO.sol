pragma solidity 0.8.3;

import "@openzeppelin/contracts/access/Ownable.sol";

contract UqbarDAO is Ownable {
  uint256 public allocatedSupply = 0;
  uint256 public totalSupply;

  mapping(address => uint256) public uqAlloc;

  /** 
  * initializes with values from old contract
  */
  constructor(uint256 _cap)
  Ownable() {
    totalSupply = _cap;
    allocatedSupply = 13678764;

    uqAlloc[0x622A7B62FC2A00225570E2877D7B765150AE6B11] += 5000;
    emit Allocate(0x622A7B62FC2A00225570E2877D7B765150AE6B11, 5000);
    uqAlloc[0x6273f92D0dCE16634d34f4Db95C323aF634E216C] += 150000;
    emit Allocate(0x6273f92D0dCE16634d34f4Db95C323aF634E216C, 150000);
    uqAlloc[0x26EbE8503874ee9731ADc4fa63f38c3B4d3668cE] += 300000;
    emit Allocate(0x26EbE8503874ee9731ADc4fa63f38c3B4d3668cE, 300000);
    uqAlloc[0x2eaAa8Adb071d2Bd87E7dbD9bA451Fa8A04Ed43e] += 200000;
    emit Allocate(0x2eaAa8Adb071d2Bd87E7dbD9bA451Fa8A04Ed43e, 200000);
    uqAlloc[0x35050b773fe20c1F41c5a1555Cf7CcEE8208D1eC] += 10000;
    emit Allocate(0x35050b773fe20c1F41c5a1555Cf7CcEE8208D1eC, 10000);
    uqAlloc[0x179456bf16752FE5Eb8789148E5C98Eb39D87Fe5] += 125000;
    emit Allocate(0x179456bf16752FE5Eb8789148E5C98Eb39D87Fe5, 125000);
    uqAlloc[0xeB02971Ff757F52a07e1242aCeb6b6Da892B6119] += 10000;
    emit Allocate(0xeB02971Ff757F52a07e1242aCeb6b6Da892B6119, 10000);
    uqAlloc[0xd2C029D2123C5d9c8c0c24421D2b69E2cA7a579D] += 31000;
    emit Allocate(0xd2C029D2123C5d9c8c0c24421D2b69E2cA7a579D, 31000);
    uqAlloc[0x1E8bf28B4c0c5620c4a4a154267Cfe792360bE2f] += 15000;
    emit Allocate(0x1E8bf28B4c0c5620c4a4a154267Cfe792360bE2f, 15000);
    uqAlloc[0x5A68d8cafCf995ee562a3635a35Fc34C7aF50550] += 100000;
    emit Allocate(0x5A68d8cafCf995ee562a3635a35Fc34C7aF50550, 100000);
    uqAlloc[0x58288B5d0d16916d06317A8070846BCBe346AB17] += 40000;
    emit Allocate(0x58288B5d0d16916d06317A8070846BCBe346AB17, 40000);
    uqAlloc[0xA01249C4a373c52baF88265D92ad3eBbEDCf4353] += 10000;
    emit Allocate(0xA01249C4a373c52baF88265D92ad3eBbEDCf4353, 10000);
    uqAlloc[0x357FAf4aA016E7C4Cef5551aE685505283da412e] += 22000;
    emit Allocate(0x357FAf4aA016E7C4Cef5551aE685505283da412e, 22000);
    uqAlloc[0xE2A82cdccbFA6EBF9817b0C4aEd45264Bd41FBEC] += 200000;
    emit Allocate(0xE2A82cdccbFA6EBF9817b0C4aEd45264Bd41FBEC, 200000);
    uqAlloc[0x16656d37e158893eA3074184afB7cDE62B84f2b3] += 200000;
    emit Allocate(0x16656d37e158893eA3074184afB7cDE62B84f2b3, 200000);
    uqAlloc[0x1208C341977f0790Fc786D9Cc9baEd66CD18Dd19] += 4000;
    emit Allocate(0x1208C341977f0790Fc786D9Cc9baEd66CD18Dd19, 4000);
    uqAlloc[0x9D92dBa13943c1FF36C527618233eF5AD49A14ae] += 244000;
    emit Allocate(0x9D92dBa13943c1FF36C527618233eF5AD49A14ae, 244000);
    uqAlloc[0xB5F99027D52aacAaC62CEEA57fd44DDfefc70674] += 10000;
    emit Allocate(0xB5F99027D52aacAaC62CEEA57fd44DDfefc70674, 10000);
    uqAlloc[0x4b22764F2Db640aB4d0Ecfd0F84344F3CB5C3715] += 25000;
    emit Allocate(0x4b22764F2Db640aB4d0Ecfd0F84344F3CB5C3715, 25000);
    uqAlloc[0xdB3BbA17A6C6975e63f753752d0852328b129E0E] += 10000;
    emit Allocate(0xdB3BbA17A6C6975e63f753752d0852328b129E0E, 10000);
    uqAlloc[0x8E1De47EEf8c847C989Bc5472aE91dC7CE0f84C8] += 30000;
    emit Allocate(0x8E1De47EEf8c847C989Bc5472aE91dC7CE0f84C8, 30000);
    uqAlloc[0x3703E02e9eaE64d5e330408eEA0098ce285b23EE] += 10000;
    emit Allocate(0x3703E02e9eaE64d5e330408eEA0098ce285b23EE, 10000);
    uqAlloc[0x711C57bd3D25a058f34324aF139390DE0AE730f2] += 10000;
    emit Allocate(0x711C57bd3D25a058f34324aF139390DE0AE730f2, 10000);
    uqAlloc[0x9497aF669a0A1f8Ed3F399e955a22Fed8f83C751] += 10000;
    emit Allocate(0x9497aF669a0A1f8Ed3F399e955a22Fed8f83C751, 10000);
    uqAlloc[0x209cfA572eDCbD127a4A7D9713f518f308e307aD] += 630000;
    emit Allocate(0x209cfA572eDCbD127a4A7D9713f518f308e307aD, 630000);
    uqAlloc[0x1cDd50D94e4294592414dF267486a186C6eE9F10] += 25000;
    emit Allocate(0x1cDd50D94e4294592414dF267486a186C6eE9F10, 25000);
    uqAlloc[0x0852e2Db02eCccE5613c68138e02F39989832a84] += 65000;
    emit Allocate(0x0852e2Db02eCccE5613c68138e02F39989832a84, 65000);
    uqAlloc[0x84F3E5662D2021940b72ACA391EACCf9A30cB205] += 20000;
    emit Allocate(0x84F3E5662D2021940b72ACA391EACCf9A30cB205, 20000);
    uqAlloc[0xD79bE794153FD14EB9a9b71F6a329CEa980ec069] += 10000;
    emit Allocate(0xD79bE794153FD14EB9a9b71F6a329CEa980ec069, 10000);
    uqAlloc[0xBB28D810db15074Fc78C02F09b9a9aD6d3234f95] += 10000;
    emit Allocate(0xBB28D810db15074Fc78C02F09b9a9aD6d3234f95, 10000);
    uqAlloc[0xC5aC479524562F8b4Ef126847dE2d2f0713c356F] += 20000;
    emit Allocate(0xC5aC479524562F8b4Ef126847dE2d2f0713c356F, 20000);
    uqAlloc[0x49C2e768Ce281B558b7a850DBD88b8501BEa91f0] += 126000;
    emit Allocate(0x49C2e768Ce281B558b7a850DBD88b8501BEa91f0, 126000);
    uqAlloc[0xa43670E72aAEe4d2C68b98bD393a69fd5Bd6C00E] += 125000;
    emit Allocate(0xa43670E72aAEe4d2C68b98bD393a69fd5Bd6C00E, 125000);
    uqAlloc[0xb5437C033ea40D46F7Ae7f5d17150270375b32e3] += 600000;
    emit Allocate(0xb5437C033ea40D46F7Ae7f5d17150270375b32e3, 600000);
    uqAlloc[0x0E098632C947F7158d9Dd3349A824c5E0402B8df] += 100000;
    emit Allocate(0x0E098632C947F7158d9Dd3349A824c5E0402B8df, 100000);
    uqAlloc[0x175b49d39C059d764B4D268E66822Eb420F46db9] += 50000;
    emit Allocate(0x175b49d39C059d764B4D268E66822Eb420F46db9, 50000);
    uqAlloc[0xE93038F9D90b8241d4b37F682389A96AD620AAb6] += 10000;
    emit Allocate(0xE93038F9D90b8241d4b37F682389A96AD620AAb6, 10000);
    uqAlloc[0x4fEEF056B17c3c4363824825de3D7de7384Bb01F] += 100000;
    emit Allocate(0x4fEEF056B17c3c4363824825de3D7de7384Bb01F, 100000);
    uqAlloc[0xc3ae5d5CdbF1FAA3Cc69A6bbBE288922249E08aE] += 100000;
    emit Allocate(0xc3ae5d5CdbF1FAA3Cc69A6bbBE288922249E08aE, 100000);
    uqAlloc[0xDfFb9B7F70f265F50e2F9db39B884E12a1b509e8] += 10000;
    emit Allocate(0xDfFb9B7F70f265F50e2F9db39B884E12a1b509e8, 10000);
    uqAlloc[0x0a93348D5B65Dd6a96E47D078F8D42EC32ed5D03] += 45000;
    emit Allocate(0x0a93348D5B65Dd6a96E47D078F8D42EC32ed5D03, 45000);
    uqAlloc[0xF83F3927d4852F8568C8628cC23338dF2BE804e8] += 10000;
    emit Allocate(0xF83F3927d4852F8568C8628cC23338dF2BE804e8, 10000);
    uqAlloc[0x0Ae83E72F20C6bda457E65278044c95051c01f27] += 100000;
    emit Allocate(0x0Ae83E72F20C6bda457E65278044c95051c01f27, 100000);
    uqAlloc[0x02AAaD2af348b920EdBC4Ce73863861Bc40e1087] += 50000;
    emit Allocate(0x02AAaD2af348b920EdBC4Ce73863861Bc40e1087, 50000);
    uqAlloc[0xeEe51A6EE6580956b3E9D6153F6D7Cac36E3c38D] += 50000;
    emit Allocate(0xeEe51A6EE6580956b3E9D6153F6D7Cac36E3c38D, 50000);
    uqAlloc[0x15895049360569d5197D719391DEE7cb4bE2C1C7] += 10000;
    emit Allocate(0x15895049360569d5197D719391DEE7cb4bE2C1C7, 10000);
    uqAlloc[0x282a287f1AF0DB751C5f988e227C7140D22F9EBf] += 3000;
    emit Allocate(0x282a287f1AF0DB751C5f988e227C7140D22F9EBf, 3000);
    uqAlloc[0xBBa8e4Bc67BcB7Ac9e9A50801971991E11856320] += 126000;
    emit Allocate(0xBBa8e4Bc67BcB7Ac9e9A50801971991E11856320, 126000);
    uqAlloc[0xEBeE27223A2EAf2F240C77879535d0d683029Df2] += 250000;
    emit Allocate(0xEBeE27223A2EAf2F240C77879535d0d683029Df2, 250000);
    uqAlloc[0x9CE43e9f87A7d42bBf5c2678ab02b650FF33A01C] += 250000;
    emit Allocate(0x9CE43e9f87A7d42bBf5c2678ab02b650FF33A01C, 250000);
    uqAlloc[0x8714fc1e178eFadD27f514B64653d4800F2c6739] += 500000;
    emit Allocate(0x8714fc1e178eFadD27f514B64653d4800F2c6739, 500000);
    uqAlloc[0x9F0A082F74Ecc1DAEf0DD24E0b507700a2900485] += 50000;
    emit Allocate(0x9F0A082F74Ecc1DAEf0DD24E0b507700a2900485, 50000);
    uqAlloc[0x3F37FdDdD59ba061051c6dDfb52E8a6aAf93379C] += 15000;
    emit Allocate(0x3F37FdDdD59ba061051c6dDfb52E8a6aAf93379C, 15000);
    uqAlloc[0x95940F4e52d5E131C5442C6099374F9D5DB4Cf27] += 5000;
    emit Allocate(0x95940F4e52d5E131C5442C6099374F9D5DB4Cf27, 5000);
    uqAlloc[0x6bCcf35FDEFBFb3F1aeb71b223140e47FD9DeE78] += 25000;
    emit Allocate(0x6bCcf35FDEFBFb3F1aeb71b223140e47FD9DeE78, 25000);
    uqAlloc[0x290ffb04B242D62bD8038090d5FdcF17d7c31C57] += 100000;
    emit Allocate(0x290ffb04B242D62bD8038090d5FdcF17d7c31C57, 100000);
    uqAlloc[0xeE003539AAA020814a30ede8e66d39b34ab88190] += 40000;
    emit Allocate(0xeE003539AAA020814a30ede8e66d39b34ab88190, 40000);
    uqAlloc[0x58288B5d0d16916d06317A8070846BCBe346AB17] += 35000;
    emit Allocate(0x58288B5d0d16916d06317A8070846BCBe346AB17, 35000);
    uqAlloc[0xA01249C4a373c52baF88265D92ad3eBbEDCf4353] += 10000;
    emit Allocate(0xA01249C4a373c52baF88265D92ad3eBbEDCf4353, 10000);
    uqAlloc[0xB0F6dF04C48F770a8E8A2819B5447f73bEe3C8C5] += 10000;
    emit Allocate(0xB0F6dF04C48F770a8E8A2819B5447f73bEe3C8C5, 10000);
    uqAlloc[0x21E977Fc97C9dad0a70Db665CbaB3Ad3D860A121] += 67500;
    emit Allocate(0x21E977Fc97C9dad0a70Db665CbaB3Ad3D860A121, 67500);
    uqAlloc[0xA60FF2737E13DeA2295dd36d9007DCC0AB03c2da] += 30000;
    emit Allocate(0xA60FF2737E13DeA2295dd36d9007DCC0AB03c2da, 30000);
    uqAlloc[0xb7406F0d89557c11e7d08fA412d6B381819E0aE0] += 60000;
    emit Allocate(0xb7406F0d89557c11e7d08fA412d6B381819E0aE0, 60000);
    uqAlloc[0x77167bAB0c5f6C15bCA5c5baCAe88884b5E5374A] += 10000;
    emit Allocate(0x77167bAB0c5f6C15bCA5c5baCAe88884b5E5374A, 10000);
    uqAlloc[0x545EA4ba107698290260bb0Ed65da806Ee45FF59] += 10000;
    emit Allocate(0x545EA4ba107698290260bb0Ed65da806Ee45FF59, 10000);
    uqAlloc[0x201839B32e19b2056366Fc39aBeD5b16Acf21082] += 10000;
    emit Allocate(0x201839B32e19b2056366Fc39aBeD5b16Acf21082, 10000);
    uqAlloc[0x2BDf0F36ACCcB0847EC29ADF0fe1b5bbEddE642C] += 10000;
    emit Allocate(0x2BDf0F36ACCcB0847EC29ADF0fe1b5bbEddE642C, 10000);
    uqAlloc[0xEDe18FbA74e3bac23E1b37bDFDfaFEAd9cdeefDd] += 20000;
    emit Allocate(0xEDe18FbA74e3bac23E1b37bDFDfaFEAd9cdeefDd, 20000);
    uqAlloc[0xd6C9931b5258E5b621f37954429BB65953C217E9] += 100000;
    emit Allocate(0xd6C9931b5258E5b621f37954429BB65953C217E9, 100000);
    uqAlloc[0xAE164F42Cea0a0A2C7815F46fb903485f23C944b] += 2100000;
    emit Allocate(0xAE164F42Cea0a0A2C7815F46fb903485f23C944b, 2100000);
    uqAlloc[0x1483c0bAC2BF3250376F6583D8B9c59158cd6488] += 32500;
    emit Allocate(0x1483c0bAC2BF3250376F6583D8B9c59158cd6488, 32500);
    uqAlloc[0x755F60a301E070d09137bc4cFf0cBEabF5722ae6] += 100000;
    emit Allocate(0x755F60a301E070d09137bc4cFf0cBEabF5722ae6, 100000);
    uqAlloc[0xaDcA1880E8D3e620F89Ed92330b4DD7Ba07D86F2] += 190000;
    emit Allocate(0xaDcA1880E8D3e620F89Ed92330b4DD7Ba07D86F2, 190000);
    uqAlloc[0x1e3c5f52A9Ae6518EE12Ad8e3C07c2A1ED6A2434] += 10000;
    emit Allocate(0x1e3c5f52A9Ae6518EE12Ad8e3C07c2A1ED6A2434, 10000);
    uqAlloc[0xE788B50482537099821677c486a1baa45f44AA5B] += 60000;
    emit Allocate(0xE788B50482537099821677c486a1baa45f44AA5B, 60000);
    uqAlloc[0x027a35AbbD466cbdB9e9629d4a2EF17B01B24f2D] += 33000;
    emit Allocate(0x027a35AbbD466cbdB9e9629d4a2EF17B01B24f2D, 33000);
    uqAlloc[0x920C791d9B57E5dB625e089D0E235DEC83173733] += 1000000;
    emit Allocate(0x920C791d9B57E5dB625e089D0E235DEC83173733, 1000000);
    uqAlloc[0x973d1fDF360563848816a66283903f15F7C39A28] += 17000;
    emit Allocate(0x973d1fDF360563848816a66283903f15F7C39A28, 17000);
    uqAlloc[0x231b6136EFEE748496A412E1151DF6eA9D658189] += 30000;
    emit Allocate(0x231b6136EFEE748496A412E1151DF6eA9D658189, 30000);
    uqAlloc[0x5e34bC97E370BD2b4B147eCb124403c5084680eE] += 61000;
    emit Allocate(0x5e34bC97E370BD2b4B147eCb124403c5084680eE, 61000);
    uqAlloc[0xBBb3f2e5E5a9A70e9C6E62F98eC50a1b39F5d479] += 50000;
    emit Allocate(0xBBb3f2e5E5a9A70e9C6E62F98eC50a1b39F5d479, 50000);
    uqAlloc[0xAC24ac8a357b2599D4f21303864Ef60D2B9ad02f] += 14000;
    emit Allocate(0xAC24ac8a357b2599D4f21303864Ef60D2B9ad02f, 14000);
    uqAlloc[0xE3d8680587469671C02a5c0f48C20cCeeEdb8f5F] += 10000;
    emit Allocate(0xE3d8680587469671C02a5c0f48C20cCeeEdb8f5F, 10000);
    uqAlloc[0x7DeA6155B58A787Bf6a12050a500563a2D475D31] += 21000;
    emit Allocate(0x7DeA6155B58A787Bf6a12050a500563a2D475D31, 21000);
    uqAlloc[0xF4Ee54041cB254DCfe0f426936564daeD562b766] += 25000;
    emit Allocate(0xF4Ee54041cB254DCfe0f426936564daeD562b766, 25000);
    uqAlloc[0x5E4Ef9569fE061b7552Ae1a9856E5827C04fcd12] += 15000;
    emit Allocate(0x5E4Ef9569fE061b7552Ae1a9856E5827C04fcd12, 15000);
    uqAlloc[0x8E52A46825d6fbb71a5f8dAb4c10056598d013f5] += 20000;
    emit Allocate(0x8E52A46825d6fbb71a5f8dAb4c10056598d013f5, 20000);
    uqAlloc[0x49Fb7FEE3a5B2fCb055b401773B4D0322aDa275B] += 21000;
    emit Allocate(0x49Fb7FEE3a5B2fCb055b401773B4D0322aDa275B, 21000);
    uqAlloc[0x654bBD3188b5bA248cDA5F5c5a86a78D7a0F72F1] += 42000;
    emit Allocate(0x654bBD3188b5bA248cDA5F5c5a86a78D7a0F72F1, 42000);
    uqAlloc[0xDaF7B7E593c9855D40f52c5A26C6b0a7A8446dAB] += 147000;
    emit Allocate(0xDaF7B7E593c9855D40f52c5A26C6b0a7A8446dAB, 147000);
    uqAlloc[0x52ECff92af8836915e9c91A7D326068419d3Bc7A] += 27000;
    emit Allocate(0x52ECff92af8836915e9c91A7D326068419d3Bc7A, 27000);
    uqAlloc[0x801DAbe959A5C2391ab10118C2B5Aa7285A1062a] += 29000;
    emit Allocate(0x801DAbe959A5C2391ab10118C2B5Aa7285A1062a, 29000);
    uqAlloc[0x3504D0820203d402ffaDd5FD0cb8f9d53b6edA2B] += 15000;
    emit Allocate(0x3504D0820203d402ffaDd5FD0cb8f9d53b6edA2B, 15000);
    uqAlloc[0x44DC5bF1E9e83A1153De4d27A596a2644DdFdbd2] += 7500;
    emit Allocate(0x44DC5bF1E9e83A1153De4d27A596a2644DdFdbd2, 7500);
    uqAlloc[0x8Ff76D185F708ff5FdDd142d62A446C4AA9948C6] += 7500;
    emit Allocate(0x8Ff76D185F708ff5FdDd142d62A446C4AA9948C6, 7500);
    uqAlloc[0x6159eaC2Bde8AdC3922ccc2d55CBCA2f773947Fe] += 105000;
    emit Allocate(0x6159eaC2Bde8AdC3922ccc2d55CBCA2f773947Fe, 105000);
    uqAlloc[0xb6A11a4b3c88873C2539f4827191226565B89Edf] += 42000;
    emit Allocate(0xb6A11a4b3c88873C2539f4827191226565B89Edf, 42000);
    uqAlloc[0xe3298C21bde7e8fB7b3c1E7B5b1af634EF9AA209] += 2500000;
    emit Allocate(0xe3298C21bde7e8fB7b3c1E7B5b1af634EF9AA209, 2500000);
    uqAlloc[0x9F0A082F74Ecc1DAEf0DD24E0b507700a2900485] += 108499;
    emit Allocate(0x9F0A082F74Ecc1DAEf0DD24E0b507700a2900485, 108499);
    uqAlloc[0xEDe18FbA74e3bac23E1b37bDFDfaFEAd9cdeefDd] += 24333;
    emit Allocate(0xEDe18FbA74e3bac23E1b37bDFDfaFEAd9cdeefDd, 24333);
    uqAlloc[0xB32190D00048114885A1BBa7782F7604CE515180] += 250000;
    emit Allocate(0xB32190D00048114885A1BBa7782F7604CE515180, 250000);
    uqAlloc[0x1AE8D4cd0dD2A476769Be4b5187E9A2912bEF2c4] += 100000;
    emit Allocate(0x1AE8D4cd0dD2A476769Be4b5187E9A2912bEF2c4, 100000);
    uqAlloc[0xfC996FC1c1A3f4477A2F155302B3F153599eafC7] += 119998;
    emit Allocate(0xfC996FC1c1A3f4477A2F155302B3F153599eafC7, 119998);
    uqAlloc[0xA377A41C7F4ADA8C1e2f86A57a17417027Ce63da] += 10000;
    emit Allocate(0xA377A41C7F4ADA8C1e2f86A57a17417027Ce63da, 10000);
    uqAlloc[0x9F599e2c713e0bD5643e559e637Ae3dDeda7CF2f] += 7000;
    emit Allocate(0x9F599e2c713e0bD5643e559e637Ae3dDeda7CF2f, 7000);
    uqAlloc[0xA381B95196EB64193841b866927b8020e7F86f54] += 20840;
    emit Allocate(0xA381B95196EB64193841b866927b8020e7F86f54, 20840);
    uqAlloc[0xeE003539AAA020814a30ede8e66d39b34ab88190] += 25000;
    emit Allocate(0xeE003539AAA020814a30ede8e66d39b34ab88190, 25000);
    uqAlloc[0x6b14D22b0c0d1f061047fE8ad312C8b25741c355] += 125000;
    emit Allocate(0x6b14D22b0c0d1f061047fE8ad312C8b25741c355, 125000);
    uqAlloc[0x9345AEEF72f382872F00B9CbD197b5CA7D0FD4a7] += 140500;
    emit Allocate(0x9345AEEF72f382872F00B9CbD197b5CA7D0FD4a7, 140500);
    uqAlloc[0xB32190D00048114885A1BBa7782F7604CE515180] += 60000;
    emit Allocate(0xB32190D00048114885A1BBa7782F7604CE515180, 60000);
    uqAlloc[0xA377A41C7F4ADA8C1e2f86A57a17417027Ce63da] += 10000;
    emit Allocate(0xA377A41C7F4ADA8C1e2f86A57a17417027Ce63da, 10000);
    uqAlloc[0x9F599e2c713e0bD5643e559e637Ae3dDeda7CF2f] += 6000;
    emit Allocate(0x9F599e2c713e0bD5643e559e637Ae3dDeda7CF2f, 6000);
    uqAlloc[0xfC996FC1c1A3f4477A2F155302B3F153599eafC7] += 11666;
    emit Allocate(0xfC996FC1c1A3f4477A2F155302B3F153599eafC7, 11666);
    uqAlloc[0xfDAf20ceB8E5aF9fd3055492474b030BB2579845] += 9000;
    emit Allocate(0xfDAf20ceB8E5aF9fd3055492474b030BB2579845, 9000);
    uqAlloc[0xEDe18FbA74e3bac23E1b37bDFDfaFEAd9cdeefDd] += 14000;
    emit Allocate(0xEDe18FbA74e3bac23E1b37bDFDfaFEAd9cdeefDd, 14000);
    uqAlloc[0x65F6f2960B5d20A35F7a2316D5FB380F5eD346A3] += 4000;
    emit Allocate(0x65F6f2960B5d20A35F7a2316D5FB380F5eD346A3, 4000);
    uqAlloc[0x5d94813696BedB4F4C7d16D54A33BC7f29eA8e69] += 13000;
    emit Allocate(0x5d94813696BedB4F4C7d16D54A33BC7f29eA8e69, 13000);
    uqAlloc[0xA381B95196EB64193841b866927b8020e7F86f54] += 41680;
    emit Allocate(0xA381B95196EB64193841b866927b8020e7F86f54, 41680);
    uqAlloc[0xd0fD753BE04bd9dc19c8c5F2dBa7D5a305096970] += 14582;
    emit Allocate(0xd0fD753BE04bd9dc19c8c5F2dBa7D5a305096970, 14582);
    uqAlloc[0x9345AEEF72f382872F00B9CbD197b5CA7D0FD4a7] += 2250;
    emit Allocate(0x9345AEEF72f382872F00B9CbD197b5CA7D0FD4a7, 2250);
    uqAlloc[0x9F0A082F74Ecc1DAEf0DD24E0b507700a2900485] += 41666;
    emit Allocate(0x9F0A082F74Ecc1DAEf0DD24E0b507700a2900485, 41666);
    uqAlloc[0x6b14D22b0c0d1f061047fE8ad312C8b25741c355] += 14750;
    emit Allocate(0x6b14D22b0c0d1f061047fE8ad312C8b25741c355, 14750);
  }
    
  mapping(address => bool) public allowedTransfers;

  enum Vote { Absent, Aye, Nay }

  struct InflationProposal {
    uint256 atBlock;
    uint256 newTotalSupply;
    uint256 aye;
    uint256 nay;
    bool open;
  }
  mapping(uint256 => mapping(address => bool)) votes;  // map atBlock to votes

  InflationProposal public proposal;

  uint256 public quorumPercent = 15000000000;
  uint256 public quorumDenominator = 100000000000;
  uint256 public votingPeriod = 43200; // 7 days in blocks

  event Allocate(address to, uint256 amount);
  event AllowTransfer(address from);
  event Transfer(address from, address to, uint256 amount);
  event Proposal(uint256 proposedAtBlock, uint256 newTotalSupply);
  event Voter(address voter, uint256 proposalId, Vote vote);
  event Inflation(uint256 proposedAtBlock, uint256 newSupply);

  function allocate(address _to, uint256 _amount) external onlyOwner {
    require(_to != address(0) && _to != address(this), "Invalid address");
    require(_amount > 0, "No zero amount");
    require(allocatedSupply + _amount <= totalSupply, "Exceeds total supply");

    uqAlloc[_to] += _amount;
    allocatedSupply += _amount;
    emit Allocate(_to, _amount);
  }

  function allowTransfer(address _from) external onlyOwner {
    require(uqAlloc[_from] > 0, "_from has no allocation");
    allowedTransfers[_from] = true; 
    emit AllowTransfer(_from);
  }

  function transferAllocation(address _to, uint256 _amount) external {
    require(!proposal.open, "Cannot transfer while an InflationProposal vote is open");
    require(allowedTransfers[msg.sender], "Sender not authorized to transfer allocation");
    require(_amount <= uqAlloc[msg.sender], "Exceeds allocation balance");

    uqAlloc[msg.sender] -= _amount;
    uqAlloc[_to] += _amount;
    allowedTransfers[msg.sender] = false;
    
    emit Transfer(msg.sender, _to, _amount);
  }

  function setVotingPeriod(uint256 _votingPeriod) external onlyOwner {
    require(!proposal.open, "Cannot change votingPeriod while a proposal is open");
    votingPeriod = _votingPeriod;
  }

  function setQuorum(uint256 _percent, uint256 _denominator) external onlyOwner {
    require(!proposal.open, "Cannot change votingPeriod while a proposal is open");
    require(_percent <= _denominator, "Quorum percent must be <= denominator");
    quorumPercent = _percent;
    quorumDenominator = _denominator;
  }

  function newInflationProposal(uint256 _newTotalSupply) external onlyOwner {
    require(!proposal.open, "Current proposal is open; cancel it first to overwrite");
    require(_newTotalSupply > totalSupply, "Proposed supply must exceed current supply");
    require(block.number != proposal.atBlock, "Wait 1 block before submitting a new proposal");

    // overwrite current proposal
    proposal.atBlock = block.number;
    proposal.newTotalSupply = _newTotalSupply;
    proposal.aye = 0;
    proposal.nay = 0;
    proposal.open = true;

    emit Proposal(block.number, _newTotalSupply);
  }

  function cancelProposal() external onlyOwner {
    require(proposal.open, "Current proposal is not open; no need to cancel");
    
    proposal.open = false;
  }

  function vote(Vote _vote) external {
    require(block.number < proposal.atBlock + votingPeriod, "Voting period elapsed");
    require(uqAlloc[msg.sender] > 0, "Must own Uqbar allocation to vote");
    require(!votes[proposal.atBlock][msg.sender], "Must not have voted");
    require(proposal.open, "Current proposal must be open for voting");

    votes[proposal.atBlock][msg.sender] = true;

    if (_vote == Vote.Aye) {
      proposal.aye += uqAlloc[msg.sender];
    }
    if (_vote == Vote.Nay) {
      proposal.nay += uqAlloc[msg.sender];
    }
  }

  function executeProposal() external onlyOwner {
    require(block.number > proposal.atBlock + votingPeriod, "Voting period not elapsed");
    require(proposal.open, "Proposal already executed or cancelled");
    require(proposal.newTotalSupply > totalSupply, "Superseded by previous proposal");
        
    uint256 quorum = allocatedSupply * quorumPercent / quorumDenominator;
    require(proposal.aye + proposal.nay >= quorum, "Does not meet quorum requirement");
    require(proposal.aye > proposal.nay, "Proposal did not pass");

    proposal.open = false;
    totalSupply = proposal.newTotalSupply;

    emit Inflation(proposal.atBlock, totalSupply);
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