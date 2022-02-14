// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC1155.sol";
import "./ERC1155Supply.sol";

contract EtherealCollective is ERC1155Supply, Ownable  {

    // Contract name
    string public name;
    // Contract symbol
    string public symbol;

    address ownerAddress = 0x817A17FD73e3e3509FA3D534dBdAFD810b875c4c;

    constructor(
        string memory uri,
        string memory _symbol,
        string memory _name
    ) ERC1155(
        uri
    ) { 
        name = _name;
        symbol = _symbol;
       /* SPONSOR START 20 */
       _mint(ownerAddress, 1, 20, ""); 
       /* SPONSOR END */

       /* FOUNDER START 168 */
       _mint(ownerAddress, 2, 168, ""); 
       /* FOUNDER END */

       /* ARTIST START 100 */
       _mint(ownerAddress, 3, 100, ""); 
       /* ARTIST END */

       /* AMBASSADOR START 300 */
       _mint(0x26035af2d99c8A9AeaB0017921E504029431F2C1, 4, 4, "");
       _mint(0xB77d0c92fc4D4537037400adBf400EFE271F8679, 4, 4, "");
       _mint(0x195B4f60D5914c76D3CceE126767491eF5Da96dE, 4, 3, "");
       _mint(0xBFdF3266847B0cc9CF9bdc626bef48FF9C46E9cD, 4, 3, ""); 
       _mint(0xE5193D2be4D4819f717092aFC95E806f09A79964, 4, 3, ""); 
       _mint(0x817A17FD73e3e3509FA3D534dBdAFD810b875c4c, 4, 2, ""); 
       _mint(0x093D87B2c0871e0D758A3fbCf5a387B7bDf642B4, 4, 2, "");  
       _mint(0x1f64AcA27c4ECb64832f13c8F580fE513F39aD56, 4, 2, "");
       _mint(0x35582502bE5F2A447d126f413aC82D10D3a429d2, 4, 2, ""); 
       _mint(0x45fE3b59c201145B8E3BAD7661950DD3129be821, 4, 2, ""); 
       _mint(0x649444a98EDC0C5d351459b925Ec08572C1A1757, 4, 2, ""); 
       _mint(0x98D921E998fC4CF7E6f8C95d0262500Bc33B6045, 4, 2, "");  
       _mint(0xA95132d013B0890f00b23b839B49dfc8100054CA, 4, 2, "");
       _mint(0xc00f658a68AFfc4742b319cdFdee8A58FB6d19ce, 4, 2, ""); 
       _mint(0x378Db351D51d74BA6d67FF1E44FBd1C62714CCD3, 4, 1, ""); 
       _mint(0x059d0025E4e1Bb1a37F2C922e54b139Bc1231eE0, 4, 1, ""); 
       _mint(0x080E285cBe0B28b06B2F803C59D0CBE541201ADE, 4, 1, "");  
       _mint(0x4320C5465afe726d823e899682718eD37689fbd8, 4, 1, "");
       _mint(0xE4562F7A9AF49d982e80674A87D5708F20731423, 4, 1, ""); 
       _mint(0xF47f42b1fBf477e89CB8F08815Da073D287B973b, 4, 1, ""); 
       _mint(0x0057fF99a06f82Cd876c4F7F1718BD9A4F2e74B6, 4, 1, ""); 
       _mint(0x032DEF804AE399f5248c16829e5E73d7e0A87F3C, 4, 1, "");  
       _mint(0x0F7A4AD5C9627c21C96f238cD4D5cf9232EE209b, 4, 1, "");
       _mint(0x108722EbDdC7287a36B956607194A3289fc875Ae, 4, 1, ""); 
       _mint(0x1088939d95F3CeF63279B2c05E50752f47113567, 4, 1, ""); 
       _mint(0x1213a3E832CCaF762AF3eC5742B861BF59f9Bf6E, 4, 1, ""); 
       _mint(0x15805ce72DC8EECc6C7f6122b7e507567cA7Fd7d, 4, 1, "");  
       _mint(0x160b4b8a86e93e7208eb73F7AC62e3397A02d6Eb, 4, 1, "");
       _mint(0x163261f272E269f560cFFE614b2F1cF47cEe4ACE, 4, 1, ""); 
       _mint(0x190F390F547fFD33D65DdC7365B057a86A13E6Ce, 4, 1, ""); 
       _mint(0x19cDb67deDfa8e26c05D34255AA7A80BAeC5A468, 4, 1, ""); 
       _mint(0x1B286518f6AE3eDA6111F0bF13D3409e2E5B9E94, 4, 1, "");  
       _mint(0x1b4b91bb747176451F0F7f73b636baBAfCF31Cc4, 4, 1, "");
       _mint(0x1E292EaBAb30b13D27D685a0a020a044A161E0eA, 4, 1, ""); 
       _mint(0x256bd29f67AA41fF31BF882A64ac03AF0bE64727, 4, 1, ""); 
       _mint(0x26F7b2E44a8BAa5d2bBCbD5De3d805A63f0CA4B5, 4, 1, ""); 
       _mint(0x280D5f2DE90a6aa32d62BAfF7e5E3c97119Ae0FA, 4, 1, "");  
       _mint(0x28f26718a83B6ce3d1d24A787d83c7164231aFD9, 4, 1, "");
       _mint(0x2a333dF6eb6c6B1AD06A2A83A65933978c213dA9, 4, 1, ""); 
       _mint(0x2B1632e4EF7cde52531E84998Df74773cA5216b7, 4, 1, ""); 
       _mint(0x2b1eb5D1FB443d872e7ca3A82E295BC8080cD403, 4, 1, ""); 
       _mint(0x2CB3338F518b2d61470B4d1d503Bdc84c1a04Ecd, 4, 1, "");  
       _mint(0x318Ec0B60750a5e06b3a0f654F79E4ad3f95BF8B, 4, 1, "");
       _mint(0x321fDfCF79EEAED39Fc67dAaCa07d92457129d4f, 4, 1, ""); 
       _mint(0x324768C81f1D580225dEC690f5389CEF9358a904, 4, 1, ""); 
       _mint(0x33E033F5965f36aF256aF35c7F89b48b2B380402, 4, 1, ""); 
       _mint(0x39187d4D195C569E654c7032d0A1D555415dcE45, 4, 1, "");  
       _mint(0x391b622d8b85888566c40c60B585dc8647e7EbD2, 4, 1, "");
       _mint(0x470bcC3E28dB4e970b4d0E34701A4daD678ABb2F, 4, 1, ""); 
       _mint(0x485Abd0b6300F81f4653290a73229Ca13304FA46, 4, 1, ""); 
       _mint(0x51f01329d318ED23b78E47eFa336C943BFC7Bf22, 4, 1, ""); 
       _mint(0x5378bD28a1A2f02889e54E2a7461C25e8D8A943C, 4, 1, "");  
       _mint(0x59a7DE9A86B99d9A256406663FB55deF50352DAa, 4, 1, "");
       _mint(0x5D4535BF9faf3A27B0352BbE1649a24982d57Cb6, 4, 1, ""); 
       _mint(0x64679877b713C486045199C0467DF0796715F49E, 4, 1, ""); 
       _mint(0x65240eD16D442E2Fd6c64b63a5F6D22dd3C42955, 4, 1, ""); 
       _mint(0x677B3a8917E123A41D4e52961124c75a76528127, 4, 1, "");  
       _mint(0x678a7fE8cc61Cb5cA780C6631B16cA4Db1867677, 4, 1, "");
       _mint(0x6802A74fC991C9B1FfD5Aa5120FED4F54f3d346b, 4, 1, ""); 
       _mint(0x6A652E2D4F81c068eebE6e65B5eD941A32045d84, 4, 1, ""); 
       _mint(0x6FFBA4B03280B99D1f7ADf4Daced82e42a25dC41, 4, 1, ""); 
       _mint(0x72Eb5af54BdA25A1dBfa0B3c2b607B6d90848a33, 4, 1, "");  
       _mint(0x766779A58e4a7DB930cf268c67e9aBE2F3a5d5dB, 4, 1, "");
       _mint(0x7B5c5757c859703732FD8a8057a35e731ab55E8C, 4, 1, ""); 
       _mint(0x7e4225eD2C855d43B39F3B29d3790E9918D6b527, 4, 1, ""); 
       _mint(0x81AeB18677c608C05e9c4848320cad9a2A7fa196, 4, 1, ""); 
       _mint(0x8566E79D58391fd2833f4d7252CDB71325033433, 4, 1, "");  
       _mint(0x87F348Dd2db2E5A218447e813D6004Dc431c4e4C, 4, 1, "");
       _mint(0x8875A3AF3257Deea1682d0E9b35ebAD5653B8803, 4, 1, ""); 
       _mint(0x8b0FDfE3C4B82366b52A7B52880503790865bf68, 4, 1, ""); 
       _mint(0x8B31BDb32907F277F0af33ddFe799B5CE6aC72A0, 4, 1, ""); 
       _mint(0x8F6DB32F1175400Cb647CC33322B38397d5C75B8, 4, 1, "");  
       _mint(0x958410d75bF7543ef6e4dd6134482BE368A5712B, 4, 1, "");
       _mint(0x96F12637C8bb5D94222a4A16d8F11C7F5C3B04fc, 4, 1, ""); 
       _mint(0x9a050a1Bb04Abf8635e96b63ee5FD735Fa26F89c, 4, 1, ""); 
       _mint(0xA33243788Cb921A9510CBD5f819a24B7e2A764C3, 4, 1, ""); 
       _mint(0xA3E826a5D1631bAA4cf77d02ed829d2c6FcBc9E9, 4, 1, "");  
       _mint(0xA4E12ce3955FC4289dec95c5E2a696ba24A845CF, 4, 1, "");
       _mint(0xA54E54567c001F3D9f1259665d4E93De8A151A5e, 4, 1, ""); 
       _mint(0xa671041Fd8058De2Cde34250dfAc7E3a858B50f1, 4, 1, ""); 
       _mint(0xA828ABc8a75766B856d81F85655080dfE42d1D90, 4, 1, ""); 
       _mint(0xA830488A25751F7dA0F5488f714C96F0035687dE, 4, 1, "");  
       _mint(0xa931B2FBC5639a17BE6C4Af02597A48E1a15C367, 4, 1, "");
       _mint(0xA94a61AA35F8b4EaD5A833fe95Cd8730704E3c09, 4, 1, ""); 
       _mint(0xaa701CbE4DB3D85072bd0e4e6Eab4C1Dd95941bC, 4, 1, ""); 
       _mint(0xaabCF5B64Ec2A7831ab54cA1b951896117B1E6eE, 4, 1, ""); 
       _mint(0xAB0922C53E751aBfc39121a54e9352F56F8Bb5C1, 4, 1, "");  
       _mint(0xAbD4d2b15ED7C40A2a37a5C4eb4d204ba6F208dd, 4, 1, "");
       _mint(0xB21fea23c27f88C149c445Bd7Cb7AF92a6c0D82c, 4, 1, ""); 
       _mint(0xB2d0199Cab1f958dF617299c27B51b978D6a231A, 4, 1, ""); 
       _mint(0xB2fc88E66b8875f0ABa69C00A95a08A3C01c881c, 4, 1, ""); 
       _mint(0xB4aeA0614c8a651E5A21D1A20b62DF68502Bafd6, 4, 1, "");  
       _mint(0xb62b86353C9c38665F2A3843Ea4eb6f7EeF9E5ec, 4, 1, "");
       _mint(0xBb78d04B7D46767635d1C88a5882f5E43aaa8594, 4, 1, ""); 
       _mint(0xbF27384FEBDc054bBd7e388761919e7D98f7DA0C, 4, 1, ""); 
       _mint(0xC0207E337f34048DFA6B2a5f9C193c2Cb43aAde5, 4, 1, ""); 
       _mint(0xc1b52456b341f567dFC0Ee51Cae40d35F507129E, 4, 1, "");  
       _mint(0xC06ADa526fC0632501678ad3792dd5aA3aB099A0, 4, 1, "");
       _mint(0xc1b52456b341f567dFC0Ee51Cae40d35F507129E, 4, 1, ""); 
       _mint(0xc29d7FE198328A424B2113c91bcAA843D10e2c3c, 4, 1, ""); 
       _mint(0xC42066767ed03DB6d0A9A9436a2D34Ef6b07FA00, 4, 1, ""); 
       _mint(0xCd20327EF7e01f644bdB7730B24188fcF938d752, 4, 1, "");  
       _mint(0xcDbAad307B7C2f2910d38dD054d77d8b25E92833, 4, 1, "");
       _mint(0xCf2c04Be45e01553471B05A12C1c8c5543eE3bdd, 4, 1, ""); 
       _mint(0xD1d9fDa4370fcB2992cBAAdA99854D96dB8B55BB, 4, 1, ""); 
       _mint(0xD7F81E8Be1c0caa0951653848c593c2918f36ce6, 4, 1, ""); 
       _mint(0xde7efa7FF8146760C23ba649f2a6Ea0648A12024, 4, 1, "");  
       _mint(0xDFc387D937488A300bb73eD805b1E46CDfcF28Ae, 4, 1, "");
       _mint(0xE0661747d581f98B24f10b7C4dD271104965Ad1A, 4, 1, ""); 
       _mint(0xE15001EfC5C775030b445ffAd5e79d7C37B62a56, 4, 1, ""); 
       _mint(0xEB497b96a6F06B804B8D47Dc28a01BF260142ec9, 4, 1, ""); 
       _mint(0xEC1DD85C3d34C77dBFe968D68CbAAF32b657246c, 4, 1, "");  
       _mint(0xF0280Db7c831526F80dae97D2D14807EF889afF0, 4, 1, "");
       _mint(0xF21E12AB125D919F821098510C18FA896770E708, 4, 1, ""); 
       _mint(0xF3463130910603726B2D6202e81B365B3870d53F, 4, 1, ""); 
       _mint(0xF35e2163862b4913eeA961Fc118c435E7401BF05, 4, 1, ""); 
       _mint(0xf65AF4C05597f1B600cd6407fc064B445F9c57B7, 4, 1, "");  
       _mint(0xF6b7248e12e25FAC88E4FaF641d9ae05aD696950, 4, 1, "");
       _mint(0xFB4AaFf61c41F8a0A8FC6350bf03722fb423b60e, 4, 1, ""); 
       _mint(0xfc431EEc87b4609dcC49FeCCEF6D76DF18B14200, 4, 1, ""); 
       _mint(ownerAddress, 4, 159, "");
       /* AMBASSADOR END */

       /* SUPPORTER START 2000 */
       _mint(0x817A17FD73e3e3509FA3D534dBdAFD810b875c4c, 5, 2, "");
       _mint(0x378Db351D51d74BA6d67FF1E44FBd1C62714CCD3, 5, 2, "");
       _mint(0x059d0025E4e1Bb1a37F2C922e54b139Bc1231eE0, 5, 1, "");
       _mint(0x378Db351D51d74BA6d67FF1E44FBd1C62714CCD3, 5, 1, "");
       _mint(0x4320C5465afe726d823e899682718eD37689fbd8, 5, 1, "");
       _mint(0xE4562F7A9AF49d982e80674A87D5708F20731423, 5, 1, "");
       _mint(0xF47f42b1fBf477e89CB8F08815Da073D287B973b, 5, 1, "");
       _mint(0x123f1884d2FA10c6a955Ae60F1c5E1ae826d5063, 5, 2, "");
       _mint(0x1E9656dB0Cea8580F1070A616E7C1eB07a4293AB, 5, 2, "");
       _mint(0x34dDe35b7a88a1634c5E5e7aB8F18E67974997c8, 5, 2, "");
       _mint(0x3686A4b272C646ef6fBE34377337d95Db7356E63, 5, 2, "");
       _mint(0x737e53ea401189D401b549c87a56187d9c1bcAd8, 5, 2, "");
       _mint(0x930305f91Aa496A012815E542bFe1433B8F2f7dC, 5, 2, "");
       _mint(0x972afB240846d8dc9626496Ca9Efc0A433426121, 5, 2, "");
       _mint(0x9Fb3FC059A5cE0Da8e03DEBaBb153d6fA0D9AE98, 5, 2, "");
       _mint(0xA88d705fe0ABf917718663ea6C527ce5168Bf1F6, 5, 2, "");
       _mint(0xb6f7a92CD624159BF150a1fd2Ba584700A8409DB, 5, 2, "");
       _mint(0xCB03605a37415fC32F1E2899E9f8492F61f82351, 5, 2, "");
       _mint(0xCd26fe75e8b3cd87C9786EA7C75299Bd82C18cEc, 5, 2, "");
       _mint(0xd0765882d15Dbb3D88d3F2a903d6AE3B881d5059, 5, 2, "");
       _mint(0xF06beD3f0DAd7932d8D00fe48C36751f5C10be23, 5, 2, "");
       _mint(0xF740a6725d25D165783FEFD641534E56a8A67661, 5, 2, "");
       _mint(0x02a92627D07895aC51E839271F0F319753D0Cb5C, 5, 1, "");
       _mint(0x03541c193Df975D29F499a9a8EEA7f8b798fCDB7, 5, 1, "");
       _mint(0x042CdF3995F5CdBa18CBB7C3B7622a7a48D5bdc2, 5, 1, "");
       _mint(0x058015E8F957f848705D394481aB12CBF7c73f4B, 5, 1, "");
       _mint(0x069Da1bad547d67AbF26C42358d3A6A8A78dECa0, 5, 1, "");
       _mint(0x06Da4F4531D85e1ae5F369FC7a8d0e621753F443, 5, 1, "");
       _mint(0x09EAb44014e7DcA26A8a446015aEE1b7933f88F7, 5, 1, "");
       _mint(0x0D0A07F8434fdE92FA25A643BF6AD8132da7e77a, 5, 1, "");
       _mint(0x0D7ed3ff76dd70805b1624E1AA6470c52F3E7DcE, 5, 1, "");
       _mint(0x0dfE9eC2F57C3b95653f47Da96B49861e4010B36, 5, 1, "");
       _mint(0x0E19DD4291c75A4365DCB01aEEBD5D0A6F3Cea3E, 5, 1, "");
       _mint(0x0F420d0301eB0718D874b1D56BBC2Eb468F9CDF3, 5, 1, "");
       _mint(0x102DD33ef3c1af8736EDdCc30985fEB69e099cD8, 5, 1, "");
       _mint(0x104Be7518A497a8924BF2D3dd04f03339E9f3841, 5, 1, "");
       _mint(0x1058559f1c73c80337fe8A5776b43d777d2a3Fd7, 5, 1, "");
       _mint(0x13EbcF55E588867C148724a01939EE92217C2457, 5, 1, "");
       _mint(0x16A1c8C6898B5301b578788183D89aF11BAf290c, 5, 1, "");
       _mint(0x170BbDaaabaF9Ac5586947Fc0991Cb1EE61E9Dab, 5, 1, "");
       _mint(0x184E1642E3Afcd1f4FdCC584CC70f969FAE3e3e1, 5, 1, "");
       _mint(0x1958E5D7477ed777390e7034A9CC9719632838C3, 5, 1, "");
       _mint(0x1b35F030f9024436B0a4168c500225d1c6B9703E, 5, 1, "");
       _mint(0x1DB5b9b9446ec05D83447b269172C705dB3963A6, 5, 1, "");
       _mint(0x1f3DE51f4295BE1ad3874706dc85f8EFfD989a22, 5, 1, "");
       _mint(0x202a6750Bd694aeCBC33F9B16FB00f47B72E0f4f, 5, 1, "");
       _mint(0x25AaF13451E66f4F322a6105F7b295d1A7e9DA96, 5, 1, "");
       _mint(0x2C12b7E3aAA9C92e0034426B1757d20C63b3ef0C, 5, 1, "");
       _mint(0x2Ca2D2e88775013c7c5F3F2B4Ba19aBCD4DB2bc3, 5, 1, "");
       _mint(0x2e9a384EF5DDe79ad219CA47974157F5d1C88983, 5, 1, "");
       _mint(0x3577ee30ef3e818FA07b25ac5F3A6Ff9cea1Fc3D, 5, 1, "");
       _mint(0x369Cd9AffF93Ca30D16DF227942aEaF500285084, 5, 1, "");
       _mint(0x3736a95ea25eD49fC00b281DA64500E5D2E10c4d, 5, 1, "");
       _mint(0x3867c1D943BA74efB4aBcAA71Ad033472384f42C, 5, 1, "");
       _mint(0x386b491722a971773Ea5cA47069ec2A2042D6216, 5, 1, "");
       _mint(0x389Ea24a2f22E0113Efd1ae606B8E11659FAA8C8, 5, 1, "");
       _mint(0x3A3FA5f58fdAC8d6d5dBfeF3BcfB69fAFc764Bce, 5, 1, "");
       _mint(0x3B3136D269480017d8B7A050DEb0D7ED979B8075, 5, 1, "");
       _mint(0x3c3fD843d1b075af719d086DBFE5aB33E47F6aE8, 5, 1, "");
       _mint(0x3DcAaF89c429b828bd1A648a9a3B5817f6aeE148, 5, 1, "");
       _mint(0x434Aa19BE9925388B114C8c814F74E93761Ed682, 5, 1, "");
       _mint(0x43506F5a6Dda29A1d69729127Cfbe9041b0d0C96, 5, 1, "");
       _mint(0x43a2898fC97B7e3Ced2B2024Ee718D661d6222b8, 5, 1, "");
       _mint(0x43eB09B22c63FFB64c89273898F17bB441C73185, 5, 1, "");
       _mint(0x45411AB2652a29601c8f23FCa501A7b0B396EF56, 5, 1, "");
       _mint(0x456F4112283C035483a9dC71D1C8275b08fd2CA5, 5, 1, "");
       _mint(0x4591679c93892252260c5c4d7362aDFFC4dE8247, 5, 1, "");
       _mint(0x479eEf3DDc2EB2A1f642a35e1D2824e5957258D4, 5, 1, "");
       _mint(0x47da93FA350568C0bDe8737BB1b62dc0380A4B73, 5, 1, "");
       _mint(0x4eCD7a05BAf4D9D61F9389d7e2da7361dfCAc9B0, 5, 1, "");
       _mint(0x4EE2f9E69c872fe0A75750F9Fc0D17ecD9F189B4, 5, 1, "");
       _mint(0x4f6D5250BdBDB3E70e2556d447bBCB556B39AB52, 5, 1, "");
       _mint(0x50f40a6415Ca318587913c53467C9853ED2cDD29, 5, 1, "");
       _mint(0x5396af21aeBB71DBa4027c34fb84311FF6FC17C8, 5, 1, "");
       _mint(0x53BA18c69a230aAe0D48822a36D4Dcb151D1433e, 5, 1, "");
       _mint(0x5780A9ee5827AA647922aAD869601cB9eA91a04F, 5, 1, "");
       _mint(0x583942F69AbE95c33f2b6449E40D5De0270EDE6C, 5, 1, "");
       _mint(0x5914e02A1938EDc68ABE41A44E21094461fa08A9, 5, 1, "");
       _mint(0x5E5b5294D8e32960ca2adf83b591177750D919BE, 5, 1, "");
       _mint(0x60c228a36E8483199BB94808dC71cAe8ff854dC7, 5, 1, "");
       _mint(0x645C93A65946FF26331037a021c22851C8dA19Ac, 5, 1, "");
       _mint(0x65619C5ADeB3b34F976E49Cb7192F47022C933E6, 5, 1, "");
       _mint(0x69e9CA476B2ecE4f6ad0DbCe81d770b90651AD5B, 5, 1, "");
       _mint(0x6bB1b0BA9ED3d3718fE39d7B8d768b9C2E8C73ce, 5, 1, "");
       _mint(0x6E5d59FdE75eB8D26A7C52e8BD4df3ccd855382c, 5, 1, "");
       _mint(0x73c15213939d3eF9c7C40E550628CF4A82a27224, 5, 1, "");
       _mint(0x7455278BB73492Cd496fC78DEa18033e17744b18, 5, 1, "");
       _mint(0x754cd2728f17C6473d6A8B731f47224CFA00dA70, 5, 1, "");
       _mint(0x7622a0aC690056e3BA5d2b07A64691de7Ed0A59e, 5, 1, "");
       _mint(0x77acA1FdB0b7841765939b2B43491F0bA3641F24, 5, 1, "");
       _mint(0x77f3c793b5c103d0c3C0d67CBE850974d7B44DF1, 5, 1, "");
       _mint(0x784bF6fe47A2c3493c2C44863AAf44C30E1409AF, 5, 1, "");
       _mint(0x7E8C5709CD7384461876dF65FC790946c5dD462f, 5, 1, "");
       _mint(0x7Fe031913A59D3396cF49970B99D24a5Cf0E7159, 5, 2, "");
       _mint(0x8029415F530d9710526Ef44c461f2759C70990F5, 5, 1, "");
       _mint(0x847240ED317FB564614800Bd04E4074C3C7f71fE, 5, 1, "");
       _mint(0x84981f8f5D17c05c5F67749F044a2af8F4cf68C0, 5, 1, "");
       _mint(0x858bDD0dfA0a8F411C03D79B4fA482d71b7d0F77, 5, 1, "");
       _mint(0x858C8349e9F1d6DA491C08AAf91ddc9B10f7DA16, 5, 1, "");
       _mint(0x862f3C4650591be3B7ae8250C392C4E1C7C692E6, 5, 1, "");
       _mint(0x8B1a1630c9F629211ae35EDeeEa15189aBB89dD9, 5, 1, "");
       _mint(0x8b4BeAd06B4860DdeDCe74af302a3a8D1d9cd003, 5, 1, "");
       _mint(0x8BaF6839a5b8190F3a19fCcfF17e38b7D4c2ef51, 5, 1, "");
       _mint(0x8C081F741AcAb5E66aB2342d428d22b511BCff11, 5, 1, "");
       _mint(0x8D5BA2B764356Ddc9997FEd94DCf83367e8a10a2, 5, 1, "");
       _mint(0x8E181CE2Ee23c643db20748f1787D18ec347b8Ab, 5, 1, "");
       _mint(0x8e6D3D19001a17bF91428a3Dec463C205E3a7F2d, 5, 1, "");
       _mint(0x8fC553EbBF4b5fff206993EE2EdF8DBE8c450A4d, 5, 1, "");
       _mint(0x8FE40a0427B97E0FAa25366e7A0c5e5E6947f690, 5, 1, "");
       _mint(0x91D5ae5e477032603e2759B0beF694590ef779C0, 5, 1, "");
       _mint(0x926b363848fE870f5514c31571347Be3b454021d, 5, 1, "");
       _mint(0x951455E56D945ffD66A3CD943641b1e3EE3E2307, 5, 1, "");
       _mint(0x96A36D45a6600cCF8e8E6C335fB3841c85F759de, 5, 1, "");
       _mint(0x96dBf04239052AA3321006BD7DC8f51a4825DB79, 5, 1, "");
       _mint(0x978f54E13F8a1B9341b692bD7914716ECb77143B, 5, 1, "");
       _mint(0x97d79E43fcf4A528f5a8f381517238768E07BB27, 5, 1, "");
       _mint(0x9d25b797fd0bA7081B910e6275510B62443d675E, 5, 1, "");
       _mint(0x9F332b32D18522467ee63f061508752FdE41faE7, 5, 1, "");
       _mint(0xa05321d99703df9F5cD06e1B434E5EaAbb816ba3, 5, 1, "");
       _mint(0xA26921766Cd87125D42AA052D1513171F2adC0f9, 5, 1, "");
       _mint(0xA2b1861a76d25A308E5aC5be72136fc892aD8D97, 5, 1, "");
       _mint(0xa4856a7586Fd0F2eEc5BdEb49B7B8cF80Ce3ddf1, 5, 1, "");
       _mint(0xa75F3902EF9b5217FCafF4A910f60A20925e450f, 5, 1, "");
       _mint(0xA80209B06d7F4c0028b3A3AAE4011357b7eaF752, 5, 1, "");
       _mint(0xaA88580E65fB09ff45985a174660428879ee4792, 5, 1, "");
       _mint(0xACc3CFe8d3D20ff0f6E9124F2CddcB44edFc1C2B, 5, 1, "");
       _mint(0xAd7Bbe006c8D919Ffcf6148b227Bb692F7D1fbc7, 5, 1, "");
       _mint(0xb19Fb555f45d2C841BF5de576E2DFFBcbC757C54, 5, 1, "");
       _mint(0xb2509d158DC14C9A64f199ca5479128Ea83f51Db, 5, 1, "");
       _mint(0xB2CB087b27254081E2122001ac3Eeb3b6BDF5588, 5, 1, "");
       _mint(0xb5B20D8a4575880873aa4d50F9981Ebe58546957, 5, 1, "");
       _mint(0xb6cF777e3696A502107417265c92d1B075636A10, 5, 1, "");
       _mint(0xB7ee1FE41acD62d37308F827b354bD168ecC61f6, 5, 1, "");
       _mint(0xb8F34BcEc92fBE47E44aade65731c780FD1aA105, 5, 1, "");
       _mint(0xb8F903168Af589C9ccca3249Eb4452E1756e086D, 5, 1, "");
       _mint(0xBf46BfFa4d12D2dD9a998a9b8D0d1f6647720d84, 5, 1, "");
       _mint(0xC40441C08d4104D9A8392492c6A465B70471150b, 5, 1, "");
       _mint(0xc669Bdb1932b0ba5139FDfABA5Ee205549076eCa, 5, 1, "");
       _mint(0xcbD14770cE571580e9e82b7188bF8B1E78Bacd05, 5, 1, "");
       _mint(0xCE5d890ccDB977eA96008E80A0cE5B4A215aef8A, 5, 1, "");
       _mint(0xd1e92A20628106FCe955481D643b9e6b5249d086, 5, 1, "");
       _mint(0xD20971cffDbA751ba01817A8C62B343113283030, 5, 1, "");
       _mint(0xd323adfe51ea5EB48814BC6e22d379cb16E977c1, 5, 1, "");
       _mint(0xd36905c8e9E0F35c5220967af943213cE1eceA80, 5, 1, "");
       _mint(0xD452DB225f917c572e01988D1B7B99200d91Ed21, 5, 1, "");
       _mint(0xD492c4971eF568F33a1255a8B346f572ba65173b, 5, 1, "");
       _mint(0xD4dB4E67F74e11cF7E156214F62d1FC6EC2b170e, 5, 1, "");
       _mint(0xD7c373B4e3C5DF8734f9d5769E8Cb55dD5e894Bb, 5, 1, "");
       _mint(0xd7c3A28D35C7F377C6825F018065abe55d5491f8, 5, 1, "");
       _mint(0xD84f5A850de9b3758727730127B367942d2a5d84, 5, 1, "");
       _mint(0xD8e4EEb89aED28e974Cf4d1071ca25D336cEc026, 5, 1, "");
       _mint(0xd9ef304F1236fdEc3227E1ba3e06DEB17D4BDB3e, 5, 1, "");
       _mint(0xdA27f1992062cba770bc067e775e67Cb0D71abdC, 5, 1, "");
       _mint(0xDE861b1eE25D1dd7389d6A39d7aA6AB7868F16Fa, 5, 1, "");
       _mint(0xe126800A492A161c29192b80181d4BB79B5D02e0, 5, 1, "");
       _mint(0xe35dc210b7d24cF7030631f05e5DA1fDA0fA2f59, 5, 1, "");
       _mint(0xE4434F27ECb3a07caD50366715ccf627c0844207, 5, 1, "");
       _mint(0xE655998fBCA006EfC6C81534ee2DB36b31b064C0, 5, 1, "");
       _mint(0xE6F2B600fd7df131b832F781174DB4CBc70a1131, 5, 1, "");
       _mint(0xEa9D0fA8d3C329404ae3c04ACe46aF83B313aF29, 5, 1, "");
       _mint(0xebe668347fD2DcD96221F5CFDB6645c97CABc27d, 5, 1, "");
       _mint(0xec24eD76470F498c485A43A1D79FEE0b4a169390, 5, 1, "");
       _mint(0xEc60C3729c57CE14f3330E5043e197A593352588, 5, 1, "");
       _mint(0xF0925035D4Bf430b685F6c15CA794fA2E31536fe, 5, 1, "");
       _mint(0xf0E05cDB482DceAF3b93De1De78E34B94Cc3944b, 5, 1, "");
       _mint(0xf2173e3E8816b55D06c6B2c264771016ff5CaAc6, 5, 1, "");
       _mint(0xf233C9C36EC25d33b4c80BAFe18fF56e2F18eAeF, 5, 1, "");
       _mint(0xf2aa8c8F70Dd22f92b74df04596FC7449cb4244e, 5, 1, "");
       _mint(0xf55F8A71e42C7864160F29fE06C3eE236949f0c6, 5, 1, "");
       _mint(0xf58aB8c4C1EDAd745EBB24A2b9B4Eea7791871C7, 5, 1, "");
       _mint(0xF69BBeBF0eCE9dA09dC3a11c5D893b10e4e18eE9, 5, 1, "");
       _mint(0xf728F4977b68A5a6FB4F7D51052651f952816239, 5, 1, "");
       _mint(0xFa091CaE9C88f685D54CdF20748c2Fb3F47D1bd4, 5, 1, "");
       _mint(0xFEA7F025347a7a3644EBA863Aa943Eab7099Ac27, 5, 1, "");
       _mint(ownerAddress, 5, 1808, "");
       /* SUPPORTER END */
    }

    function setUri(string memory _newUri) public onlyOwner {
        _setURI(_newUri);
    }
}