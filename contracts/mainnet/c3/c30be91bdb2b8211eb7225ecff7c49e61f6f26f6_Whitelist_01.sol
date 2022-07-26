/**
 *Submitted for verification at Etherscan.io on 2022-07-26
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
// Whiteliist_01
//------------------------------------------
contract Whitelist_01 is IWhitelist {
    //---------------------------
    // storage
    //---------------------------
    mapping( address => bool) private _address_map;

    //-----------------------------------------
    // コンストラクタ
    //-----------------------------------------
    constructor(){
// ↓↓↓ ここからコピペ ↓↓↓
_address_map[0xe16d756B1E27CABc43c8C4cAdD68004aB50452b2] = true;
_address_map[0x6760EA7882d4C9Ed15a6Bc6fed69178313264498] = true;
_address_map[0x2E791676B52D12e4e33B2e92F9B5Dfe11C37a436] = true;
_address_map[0xd287682f24cEBeB2eee2dfE5569047d6F6F03E5e] = true;
_address_map[0x03Cfb42f69004C1FA9d74ed8EFB7E651542c7AaA] = true;
_address_map[0x9e55958688a76229e4fd2d58D8987708693C2b47] = true;
_address_map[0xECD02810Db92Ff027ea1b0850d46BdA963676D74] = true;
_address_map[0x603dd578CC592eB8a4d2A942A707FE6eD2d1Dfb1] = true;
_address_map[0x2FE2E22923C5FD3e28143425f23EAD539714c023] = true;
_address_map[0xc3b8d3a8C0D2efEFB90E30f520fAEeA1137DaAFc] = true;
_address_map[0x30DE09EB48b128cECAe4549Fd32D5019B6664158] = true;
_address_map[0xB73ffa31C4Bcc97DC93f625F29e8102A172EFa14] = true;
_address_map[0x4B5483Dc95EEAcAFc4A135EFEe566b86A373CA1A] = true;
_address_map[0x7A3aC1282d2Acd589FF553bFB5B6Ee4d0Af2Ba8E] = true;
_address_map[0x3428BacD15D15E5C9B8Bb2F9e1445F49aCC8AD17] = true;
_address_map[0xdEcf4B112d4120B6998e5020a6B4819E490F7db6] = true;
_address_map[0x281E3622eDFAa95dE273Fc79FFBaAA940fd90867] = true;
_address_map[0x75F958029c4Ff5c1795A4B78e573f47a2174aAe7] = true;
_address_map[0xA2176F47Ce6B28528D758A674C7fe97CBBa32f9a] = true;
_address_map[0x394B9f09c4e0Cf8138016bC4cea8D87011B2bE5d] = true;
_address_map[0xF3365df817a26F5E14Be2a0eb33406AdbffF0962] = true;
_address_map[0xd0A2f14423ede2df5FE66b61419858c8e3baB3a1] = true;
_address_map[0xe399a654Bbc275B0850A2e533e3b0569E26666A7] = true;
_address_map[0x417487275239E0f6c5AC79f5D60135eCf118169b] = true;
_address_map[0xdd2447DA277aE3F7558360e716f2BC1CE05A45ed] = true;
_address_map[0x8f330D9BbeCCb1d193782ABF21Fd5555A2889127] = true;
_address_map[0x9AA8A642CCc6Dc9ADC1964C075cB4e238DD0c26D] = true;
_address_map[0x5b44c4b7A3372A1184Bd1E2B9506e8BEA72F033c] = true;
_address_map[0xE6cC5e3EBB07B5156ba3aF510B8c6cA19804d88E] = true;
_address_map[0x197423Fc3F5165ac23Aa6EFBbf3017Ce29664852] = true;
_address_map[0xf635736bab5f3b2d6c01304192Da098a760770E2] = true;
_address_map[0x1C6b1e494afc183c106795fd9542fF7E66f12935] = true;
_address_map[0x2E4d695498296DcB443E60A53Ac6E56a22a5C56a] = true;
_address_map[0xa9CCD4454a64503Fb243ED7960c0641cb634c634] = true;
_address_map[0xc488d2c503f3C173Fb583cEc2d32e3d8236Be21E] = true;
_address_map[0xEa43a05FCF39AD68C1bF875433dBfFa81f032239] = true;
_address_map[0x1c626aDC98D2FFccec4A73b69aaF0De79f223eff] = true;
_address_map[0x4cF2461558Ef38B08cc608965d07e5F833283705] = true;
_address_map[0x5B4093207C2660a7EB4ca3732B94EA25bDB6580B] = true;
_address_map[0x7E2e243cA79343CC9f486c968bB90434E87161A1] = true;
_address_map[0xcc9ecd906406971F7147272E4b8c861754781787] = true;
_address_map[0x3E5D6D156dFEab4Ae977f5d6a5Bb555545274B33] = true;
_address_map[0x6921FaB353CC7F91a4A3e604E4fE0e18720D1370] = true;
_address_map[0xca120AdA40cB6248aDC06C194D9305C4E23ae7Ed] = true;
_address_map[0x3c1Ed067a22f87a800a9986BC905617934d8D94E] = true;
_address_map[0xfCDb8896aF26b901D8a352494Aa485c7C5278D8f] = true;
_address_map[0x36adfbe32C33a5ebF9B63C17c08C0D38CAc5B257] = true;
_address_map[0x0b1611268f5E3Ca9B5B9E04D5B22Ac87085F351d] = true;
_address_map[0xA59ae8eD8f70c5e5DCf62096E74F36b19E06c3D9] = true;
_address_map[0x8427EDea80FbF90fF9B7830c00243DE6A4899505] = true;
_address_map[0x250F57B82926cf595C0b105dcb747D5aB806a438] = true;
_address_map[0xE2a9C91fA0a2F24f6204f70923710497A56B8796] = true;
_address_map[0xda69fb774131cdCE04E8f8EcE3c67b20815Bd71e] = true;
_address_map[0x42f2746ECF7F891b62c167e16F4D1BfaA23764E3] = true;
_address_map[0xCe5f96Fa13ceBF79fC6244b9e7e719710357D9D1] = true;
_address_map[0x8ebaF3F8481a00c8a98e30113B4f3b0cFC94D606] = true;
_address_map[0x5268A4F2D8ef2Bb3b37Db74b6a1701cD5c6A347C] = true;
_address_map[0x0dAE5FcaD0DF8E5C029D76927582DFBdFd7eeC79] = true;
_address_map[0x9076d31F81512E040Cc07CfE2031cf251236A741] = true;
_address_map[0xE3Ba9817158bd0a935f85cC6ae6dFDaF708886de] = true;
_address_map[0xd6622e1727Ce7c13aD0e5FafC08BDe93b1C01aDE] = true;
_address_map[0xC3D3e3DA141EcCe9Cb2098A7D44355B9f0b26eA7] = true;
_address_map[0x9353bBE3b7E8EdBf3ac477114A302A391a1E7710] = true;
_address_map[0x210c7CC20b39371120e4157B48Dc7E3fE52ee5b9] = true;
_address_map[0x62085be985264A22ed26688a42Ecb1f4c5eD6a54] = true;
_address_map[0x0869D5D64522e78950CeB1193Da93a336b2F1696] = true;
_address_map[0x0e6362f8a89D1d6Cf5F81e98EB1Ef9dbf2f92B89] = true;
_address_map[0xC1839cEa93BdFdF29E08ae3F351813fe7E89afB3] = true;
_address_map[0xcBD05436BB6bA2dd6A02A2F65dc7Fc248772B257] = true;
_address_map[0x20045E3e280eB57DF5f860A118239447182E334b] = true;
_address_map[0xe693f386a965D8f87B72e43E46E756b362232253] = true;
_address_map[0xb1505fE87A026A3710b7912e7c0B7fD3Fe82D206] = true;
_address_map[0x27cf7b699114Db0eb5f2123c85DF4141C54A15dF] = true;
_address_map[0xE656FB4C4cd4975736643a1Fa2f06741E3231754] = true;
_address_map[0xA8614CE7A6fcEcDEe923a9634B53e2035c66eB40] = true;
_address_map[0xD233F6D9238Ea2572cc5C5f998Fb30F5cCd25703] = true;
_address_map[0xD6792DF4E2D5cccFb4962030bA3Fce4628E5266f] = true;
_address_map[0x4d979A7597882b79eEF58d75BFa870DB448F8008] = true;
_address_map[0xA69FFa7688fCCEb6eB5Fb2F0797276f2FC87675c] = true;
_address_map[0x61A61bED55aA51427B8631Aa167D374365e13353] = true;
_address_map[0x3F6249c4D782Aab00b5e9aB99E090035B80E0c15] = true;
_address_map[0x4012aEe6E0A7d14DE32b73a3925FaF285fb9f93a] = true;
_address_map[0xa5fb963D04eeB2634944fBb2eD5EE7d5099EA4D8] = true;
_address_map[0x38fFC1BA00005bA6D5294A364fB583df16d09F9b] = true;
_address_map[0x7395987B2853E625bd12b43AeE453106089daD6C] = true;
_address_map[0xa863EB34EC473Cae2ab017c804E03318A2a82e9b] = true;
_address_map[0x1a19153b0A64b48f2961Bf90F058279b72929d74] = true;
_address_map[0x3531Adf05efa9d69bdf8555e3301E7F95816CFeC] = true;
_address_map[0x6EAA340B1040DB919c7de40fD194710b234A53Ed] = true;
_address_map[0xb3fEbFd323F7b48FCdcE92654c71ec32AdAAbdA9] = true;
_address_map[0x97Ccb2DB265fA5EBA774cB609A4F7A625c286856] = true;
_address_map[0x3EE59cA7906907B7b0Ec38FCa6e2cbd62f7EeA75] = true;
_address_map[0xDD4Be47ecA55BDBEb7fCBf6FBA17C84782788092] = true;
_address_map[0x6D731AfA7A70917e4a2BFEbE6419610BF53fb035] = true;
_address_map[0x039e01717916faFd3151d366Beda49989095D066] = true;
_address_map[0x57d55454C6374d2A61d6B32910Ede4EDe598423a] = true;
_address_map[0x50339A5c57dC3eC07912deF41Fd0DE43E09d995E] = true;
_address_map[0x848e4DAfDFa495d05F5Bea829EC715D7C095C682] = true;
_address_map[0x48A9a733d60588B436018E1a9040BC678D45Ce95] = true;
_address_map[0x01bc2E40338f8B40490caeAEdDdCF7343B18e949] = true;
_address_map[0x2A8f42E6FAA798d264f76fF948034A6E0e660A66] = true;
_address_map[0x972CCba923b9970504057dD185c70036A0d70824] = true;
_address_map[0xB25469DdC31a5fB881454DB41529BdFE186e3e23] = true;
_address_map[0xa5b2eE569fF5Fea84261533b5804E69af4227979] = true;
_address_map[0x267194e25492A7f8B80E9136705Eb7Fad0fB500D] = true;
_address_map[0xb64eE4fD9EB8d4c2b0C7D54B41ce21E5E9267e7F] = true;
_address_map[0xC4d7A04c2539638C0a08930839A4fC09A5cAdceF] = true;
_address_map[0xaD5dfeC02b565EC1E57818681ffF6f84C1D7fed0] = true;
_address_map[0xe5e66D63F994d69a331fa5c62AB6B5AEF14D4E5b] = true;
_address_map[0xBACD554F82690B080D9ED06f6774321bD7f38E84] = true;
_address_map[0x3b2E4d1692beC59041cB8Bd513123C7A292822ae] = true;
_address_map[0x0712BC30BF0f88c4651f2F43c169B9B0aDC2c0D4] = true;
_address_map[0x1F2600BCFF2734A70215D52E8Cc009a6a650ac5F] = true;
_address_map[0x6a4B3d9647f761Edb026c943987e43516f7aeE92] = true;
_address_map[0x37e44111EF83b9577BCf80385FC839c6Aa2D597F] = true;
_address_map[0x3E4332919859299B23CF1121004dd5bb7acf4fFe] = true;
_address_map[0x98839bE4d57071bAF75931ff23Ec245019c09008] = true;
_address_map[0xF5d70cC9092Fa91f21aB8e081639B0Df788696a5] = true;
_address_map[0x414C87E029342433E2645699E7906f1e9B6CDbCE] = true;
_address_map[0x6b7AabD0D382bc4f65998938fa5244979Fceed47] = true;
_address_map[0x5018fdfbc087d7c991030B4e535612D885b1D683] = true;
_address_map[0x6E3CE12fADA11CE7bD89bB0fEEa9301cac628051] = true;
_address_map[0xdfA41d85bF9CB9895359c3772c8E883aB8dB6bb7] = true;
_address_map[0x74095c71a49A36Fc9e763D9594BA434bc0DD7285] = true;
_address_map[0x962C7758375B60AC7f21871CB0AE20EF0a36716A] = true;
_address_map[0x35928e89a175c3C890b2ec40E5891e42Ec8440D5] = true;
_address_map[0x980d508c634402E200c6aE56D05df0C9296fA55C] = true;
_address_map[0xcB216311812Dc82e6042716Bd8579344534e8292] = true;
_address_map[0xB9e37bf5CD4394c1cDf242736eA7D2B49Ee55b00] = true;
_address_map[0x9273BE2D68639eF82007077Ee556280D2CD2eF36] = true;
_address_map[0xe08c0696882d92abD7DA977886C7BCE136397DE7] = true;
_address_map[0xb4E746DBc960E8F9D3731eACC916Bc67c3deBffc] = true;
_address_map[0x2007B494F848A4c564E01fa4d93659FeA83BcE23] = true;
_address_map[0x4CebA95F09A21Db394110a7eF72A0A6a2fd0521C] = true;
_address_map[0x6cA0e35edb84477B9FD5cA1C938aDC6c9cbbE02E] = true;
_address_map[0x2238038f5A4947AAA64729C77618BCee83048c9f] = true;
_address_map[0xaF02BAeFAEA34496fd897d212D9926C55432A436] = true;
_address_map[0x904A23EDE4BD95d7A93c61F4f60116665b7ef4EE] = true;
_address_map[0xb4b31771823FCeF4D9CAa814690eB9bF245aF976] = true;
_address_map[0x098Ca151fc2E112459DF0f5F88f85AafE605F0fB] = true;
_address_map[0x2fC866646e15868E67A57c6474e9d14c8D7E7318] = true;
_address_map[0x7A22926766Ca6bE4c130b2364772858105313134] = true;
_address_map[0x143BE291F6d77a7aC59f4ba2e78dfc18Ecc14F01] = true;
_address_map[0xBC2Ebfbb5b3339E42a8e8e1c2F2E886F11d229c2] = true;
_address_map[0x2597e887C06Fa7AC2b674069046ea980579865d3] = true;
_address_map[0xdf16fa4cE2071943AEd64E1a3D0F1788BaC707eF] = true;
_address_map[0x70d5555964581D97A544452f66908913e7cC0730] = true;
_address_map[0x1dbf28e0cb4FaF784AA5025802cdFdBD148868B0] = true;
_address_map[0x6e1bc86E2f1c413798925494d8f75Ffd16b45879] = true;
_address_map[0x20239f96232DF5bE612228806dd78e845aBCc083] = true;
_address_map[0x75C4C5ed522454F1B0cD899d77FCA9B5336dbAbb] = true;
_address_map[0x59aE20eF0930b81E27A959eDC8d5EE230E733518] = true;
_address_map[0xdd1253c5484b655F8274E72560301a57928F9E58] = true;
_address_map[0x3F2aDab919e971a02370aD33da950F23FA356b76] = true;
_address_map[0x7D9A1dc0c77dC2D34F3f54F818AC4Fc6B25aF8Fd] = true;
_address_map[0x16D6ACca2C7e7649741c5d03da24125928ddF831] = true;
_address_map[0xde38c6964f840afeEB6D891cb4F6B132498579AE] = true;
_address_map[0x81Bef04116439fdF041c19d22e2162Be57Caa1A9] = true;
_address_map[0x7e91E9E7071f8b9b7e7190f80F0129308a81D9Da] = true;
_address_map[0xcdfC54E2cd680035d29aeB5D4747429B5807cCf7] = true;
_address_map[0x59a49FcDb766D03E3476c1F9CdDAc331B03d86aa] = true;
_address_map[0xb2F44039c65CB18522c941Da3a2299197f7bf635] = true;
_address_map[0x6CC25Fcf8B1177c18De747Ad0782d051A4847BfB] = true;
_address_map[0x5436FC8797C9f80Ed77a28683acDBDb1c6B7733c] = true;
_address_map[0xe2BC1a2A7976D1Aa118D76f90f4A55D077c64c86] = true;
_address_map[0x3F5918bc4cf4894eA0a8D1d544aEfF4F59F8c1a6] = true;
_address_map[0xD77AA1ab45FE6dB66AB00658E1C4259C70237220] = true;
_address_map[0x9A3601F558Ae9420B99e8886D8B1875Ecf966B26] = true;
_address_map[0x9BE0BB49F27aDfd42512163e8EE1dd88e8f10ED9] = true;
_address_map[0xb3273A2Ee67d0e63dAc8aB8D5AAAc598E5FAb1f6] = true;
_address_map[0x81c6F7159a48895E327581eDEB8ab6DBd0474b31] = true;
_address_map[0x645BBf6f6B6197c98874e1696d399E26eE40f431] = true;
_address_map[0x769cBc21757FE7466b37965bCB0F6DBe59797551] = true;
_address_map[0x2dB78D8d11Ef03d995162B3Cd6b6F5cFCf890092] = true;
_address_map[0x1eA45868485F4ad5c90D1D2cF8a8fE7eD987f126] = true;
_address_map[0x30964490662A5Fe44b5dc8B44Fe4542e627c3d3a] = true;
_address_map[0x5180c108bEe8Bc442C7426268441c853C43A0136] = true;
_address_map[0x7796c28768608fAb9475538b2c4F0F1a413c97ae] = true;
_address_map[0x53dbdA3b6627F40aC9d0284f20605dfCcd033283] = true;
_address_map[0xB6031C0F495BCA0a255016a1c851135F10CE5D3b] = true;
_address_map[0x82Fd2e41D34ad4016e523243ceB4354E9706C7Cd] = true;
_address_map[0xEA84aDE1546af1085941AB3fF39580E9d8dD0A5a] = true;
_address_map[0xa517Bcc4d563DB739446dBC7703690ADaDe2e13d] = true;
_address_map[0xC6B89A75307767d24e6134141B114F1C647968E7] = true;
_address_map[0x08129dAcD3b4E7Ae5984a40408E8A7228089d884] = true;
_address_map[0x9EB5D4922c274c269fdCE777cB60a8fcB3041270] = true;
_address_map[0x79B8e17396932a6A94b2bd77a78eFe502FAced5F] = true;
_address_map[0x017E76dC919f3F24Ca3cc6C13205E6004B0669b7] = true;
_address_map[0xE9BF431a2DcFdaf9aC682A22cE2646AAfF7Dc192] = true;
_address_map[0xb18e3a7152060941ef92c2aD5872D76fC4091059] = true;
_address_map[0x0C9996020625E5A34B24108ee76EA34cB4F0B4DE] = true;
_address_map[0x606F6B8C14Ed291273CE6922E00D748A28F0b539] = true;
_address_map[0x4080b0a799dfD5d16c14A355c4395FFc11dB5258] = true;
_address_map[0xf636b3416676B9C92D61fbbE493fD07930FE0990] = true;
_address_map[0x87a6d196177Ab8b800BBf4218f6dC382920fe39b] = true;
_address_map[0x46226F9BDCC0cEF3306BA70230bAE3E6428EA738] = true;
// ↑↑↑ ここまでコピペ ↑↑↑
    }

    //--------------------------------------
    // [external] 確認
    //--------------------------------------
    function check( address target ) external view override returns (bool) {
        return( _address_map[target] );
    }

}