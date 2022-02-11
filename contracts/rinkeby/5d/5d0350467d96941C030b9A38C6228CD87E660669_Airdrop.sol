//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "SafeMath.sol";
import "AccessControl.sol";
import "Pausable.sol";
import "IVesting.sol";

contract Airdrop is AccessControl, Pausable {
    using SafeMath for uint256;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    address[210] grantees = [
0x28d6037EDEAf8ec2c91c9b2cF9A1643111d8F198,
0xcfc50541c3dEaf725ce738EF87Ace2Ad778Ba0C5,
0xF9e11762d522ea29Dd78178c9BAf83b7B093aacc,
0xED60d8590019e5E145ea81455c01F3e817Fe54EB,
0xd9A93390c487b954EB1Ad4c8a4Acc73840409869,
0x052564eB0fd8b340803dF55dEf89c25C432f43f4,
0xe15DD1510E39E9980C0dC47e404eb7298872bc64,
0x3BA21b6477F48273f41d241AA3722FFb9E07E247,
0xA42830eE059c77cAF8c8200B44AA9813CB0720c5,
0xa0f75491720835b36edC92D06DDc468D201e9b73,
0x2326D4fb2737666DDA96bd6314e3D4418246cFE8,
0xf88d3412764873872aB1FdED5F168a6c1A3bF7bB,
0xAc6559dF1F410Feba9a6cbf395272189461D8463,
0x89689dB564BF4b67BD7116B3f71e68A379FAad98,
0x600b8A34ec1CfD8B8aF78cFC49708419A16ea2e8,
0x303985ba2209b5c0c745885Fa6fdd2eC1FEB81A5,
0x3991ADBDf461D6817734555efDC8ef056fEfBF21,
0xb9a954BF995bDEAcBDfE4B1F5f85cD6122c6E341,
0xADEEb9d09B8Bcee10943198FB6F6a4229bAB3675,
0x270d2924cA13F54632601647FB225DB8eb61fB49,
0x86aF94E5E8d3D583575bBafDD2DcB6b898A555e4,
0xbC90B3Ce40fc3Ed921D910f3e046C65954fFF7cB,
0x21F3B2C8646B4fFA809406BB31dE325a3E5E9b9F,
0xd8D3d8ab22E30c5402AB2A2E216a4A53F4e09e9E,
0x99eb33756a2eAa32f5964A747722c4b59e6aF351,
0xf0E12c7218cB38DF7A3A231Bb91EE82F732625b6,
0x28a55C4b4f9615FDE3CDAdDf6cc01FcF2E38A6b0,
0x78Bc49be7bae5e0eeC08780c86F0e8278B8B035b,
0x1f0a6d7Db80E0C5Af146FDb836e04FAC0B1E8202,
0xF07F2B6C340d8D303615710451C11e93fe56774D,
0xB8C2C00cC883d087C0Cbd443CeC51a4D04f8b147,
0x6979B914f3A1d8C0fec2C1FD602f0e674cdf9862,
0x90be4e1Da4BB2F464576749abAc99774148bC9a2,
0x1678b549Be696b1DfCe9F0639D996a82409E1Ea1,
0x681148725731F213b0187A3CBeF215C291D85a3E,
0x4f58985B75EeC8f14C536878A19EAdF4a1960D6c,
0xc8e99dd497ae1fc981c1dd48f49FB804FBFCB99D,
0x55b9c56668365d11f5aF18E8b7232bC6e4d20658,
0xA423fE4CFb811E9CF6a61a02e80E372c0970d4b0,
0x7432b5212F19af018b33b73a55d1996960E59c51,
0x0Af14239FAA4f19034f3334502ED592B0083e108,
0x02e05dbBF4df5d17cb3A0140F9643fE68cc4Ae39,
0xCaEDCaaFE4C596e89704c5e6B499B8D3474F750f,
0x9fA933f60BCc5E63F75F210929839f91F55b919C,
0xAE60C874eE07f44fB7BBbD1a5087cDB66E90BEd8,
0xFCa7C5CF95821f3D45b9949De6E2846D66aF819F,
0xB680f628C56C8Fa368Dacbb0C27beEf8C98355b9,
0xA7758B30e93d2ED6CEA7c85e5B12a1d46F0f091f,
0x4EC7CdF61405758f5cED5E454c0B4b0F4F043DF0,
0x84740F97Aea62C5dC36756DFD9F749412534220E,
0xcE968c0fC101C4FB8e08EB5dB73E7E169A2A3562,
0xC151AE135F50AaBE78e0b9D13A90FBb2d648AAbB,
0x975f5ffB9C3B624351634889944355D47Ab8a367,
0x9B5ea8C719e29A5bd0959FaF79C9E5c8206d0499,
0xF1fb5dEa21337FEB46963C29d04A95F6CA8B71e6,
0xF38140985B5a5746F160F133049E83F79cc0B819,
0x918A97AD195DD111C54Ea82E2F8B8D22E9f48726,
0x71F12a5b0E60d2Ff8A87FD34E7dcff3c10c914b0,
0x25431341A5800759268a6aC1d3CD91C029D7d9CA,
0x52Ad87832400485DE7E7dC965D8Ad890f4e82699,
0x3AA667D05a6aa1115cF4A533C29Bb538ACD1300c,
0xB0ff496dF3860504ebdFF61590A13c1D810C97cc,
0xbE93d14C5dEFb8F41aF8FB092F58e3C71C712b85,
0x5F82C97e9b1755237692a946aE814998Bc0e2124,
0xdD709cAE362972cb3B92DCeaD77127f7b8D58202,
0x640E0118b2C5a3C0Ea29B94A62d9108ce2c6ced7,
0x1B51cCe51E2531C478daA9b68eb80D47247dCbec,
0x2dE640a18fE3480aa802aca91f70177aDA103391,
0x14Ce500a86F1e3aCE039571e657783E069643617,
0x6019D32e59Ef480F2215eE9773AE507645B47bdc,
0xB67D92DC830F1a24E4BFfd1a6794fCf8f497c7de,
0xE95d3DAbA7495d42DCC20810f33eeb5207512a9f,
0x6f9BB7e454f5B3eb2310343f0E99269dC2BB8A1d,
0x39c09fdc4E5C5AB72F6319dDbc2CAe40E67b2A60,
0xcCa71809E8870AFEB72c4720d0fe50d5C3230e05,
0xFadAFCE89EA2221fa33005640Acf2C923312F2b9,
0x7122FC3588fB9E9B93b7c42Ba02FC85ef15c442b,
0x6fcF92925e0281D957B0076d3751caD76916C96B,
0x25AfD857C7831C91951Cd94ba63AF237d28604D0,
0xd026bFdB74fe1bAF1E1F1058f0d008cD1EEEd8B5,
0xbdC38612397355e10A2d6DD697a92f35BF1C9935,
0x339Dab47bdD20b4c05950c4306821896CFB1Ff1A,
0x1EBb814C9EF016E6012bE299ED834f1dDcEd1529,
0xb92667E34cB6753449ADF464f18ce1833Caf26e0,
0x5eBdC5C097F9378c3113DC2f9E8B51246E641896,
0xF625DCa051B5AE56f684C072c09969C9Aa91478a,
0xD45FBD8F2B0A84743D2606DE8094f86Fac5B6ed3,
0x3e89F0eCACDC9b1f8BB892367610cAd0cE421C92,
0xC77C0EDc7067a76972481484B87c1226E410547C,
0x0035Fc5208eF989c28d47e552E92b0C507D2B318,
0x286ed1111c29592cC6240194b8d66E64B1c05e50,
0x4Cd52B37fdDD19CcD24B0d0e9a048785C7aaFCEf,
0x0D779D67a428457CAbEC145A0f94703D14cd496B,
0x0000A441fBB1fBAADF246539BF253A42ABD31494,
0x8C4d5F3eaC04072245654E0BA480f1a5e1d91Dd5,
0xFca32B89d0981e69C8dadCDcc0668b0E01c810CF,
0x22fa8Cc33a42320385Cbd3690eD60a021891Cb32,
0x23Be060093Db74f38B1a3daF57AfDc1a23dB0077,
0x526C7665C5dd9cD7102C6d42D407a0d9DC1e431d,
0x6c5384bBaE7aF65Ed1b6784213A81DaE18e528b2,
0xAE667Ed58c0d9198fc0b9261156d48296C1bB3da,
0x7BFEe91193d9Df2Ac0bFe90191D40F23c773C060,
0xe1DE283EAb72A68f7Ff972fcA13f8953c6e15e51,
0xdae88e81e10d848BA6b0Ad64B19783e807064696,
0x0a8A06071c878DF9Ec2B5f9663A4b08B0F8c08f4,
0xD72B03B7F2E0b8D92b868E73e12b1f888BEFBeDA,
0xC23ef3AdF050f4Ca50b30998D37Eb6464e387577,
0xD56705548111F08CCB3e1A73806c53Dc706F2e75,
0x32802F989B4348A51DD0E61D23B78BE1a0543469,
0xc7ca02DC88A2750031DC04515438C3a505bcC994,
0x6b30E020E9517c519C408f51C2593E12D55B55fA,
0x57d1E246D2E32F6F9D10EC55Fc41E8B2E2988308,
0xEd557994671DddA053a582e73F2e8aa32bDE7D68,
0xceA077172675bf31e879Bba71fb46C3188591070,
0x3fC925E779F148f2d843cfD63296E5E12C36d632,
0xC369B30c8eC960260631E20081A32e4c61E5Ea9d,
0x455d7Eb74860d0937423b9184f9e8461aa354Ebb,
0x14559df3FBe66Cab6F893D8dD53F7BFE68DE9C65,
0x40d2Ce4C14f04bD91c59c6A1CD6e28F2A0fc81F8,
0x9BdFAeB9CB28DC05b09B37c0F14ECBc9A876CEe0,
0x7904aDB48351aF7b835Cb061316795d5226b7f1a,
0xF96dA4775776ea43c42795b116C7a6eCcd6e71b5,
0x418Efa84214F9810AF9119909D5bEe2c56ebd5Eb,
0xe1163DCFb598F74da146a83CC878731d553abBfe,
0x1eccd61c9fa53a8D2e823A26cD72A7efD7D0E92e,
0xfc80d0867822b8eD010bafcC195c21617C01f943,
0xe4f9E812Fe379128f17258A2b3Db7CF28613f190,
0x0991D02f28a5283338e9591CBf7dE2eb25da46Cd,
0x2CA3a2b525E75b2F20f59dEcCaE3ffa4bdf3EAa2,
0x7374bB48A5FDc16C9b216F3fCc60b105c73D1806,
0x8522885d735F75b3FAEEa5CD39ab3d1291dA2C77,
0xA4bd4E4D2e8c72720839823f6c20f411f7DDb1f1,
0x1729f93e3c3C74B503B8130516984CED70bF47D9,
0x94Da725DBA289B96f115ec955aDcAAA806d2085d,
0x38857Ed3a8fC5951289E58e20fB56A00e88f0BBD,
0xA4f2b2557D78E31D48E1ffa8AF8b25Db8524Ea3c,
0xDEC1BcdF22A6e77F10e3bF7df8a5F6A6a38E6376,
0xC1a0fC4a40253B04a1aE2F40655d73b16CAf268c,
0x285E4f019a531e20f673B634D31922d408970798,
0xa734288DA3aCE7F9a5e5CAa6Df929126f2e67d52,
0x4BB633f0e7E0F3FbC95a7f7fd223652882977573,
0x058B10CbE1872ad139b00326686EE8CCef274C58,
0xD18001F022154654149ed45888C9c29Def6d3CE6,
0xB8C30017B375bf675c2836c4c6B6ed5BE214739d,
0xc78CE4E51611ed720eC96bf584bf1b1658FD2379,
0xFbEd5277E524113Df313F9f6B29fDE8677F4E936,
0x43E553fC1D064C125764E9D534a4F7D89B9bb1BE,
0xD0a5266b2515c3b575e30cBC0cfC775FA4fC6660,
0x507E964A2fabE1921278b640b0813a5626844145,
0xECB949c68C825650fD9D0Aebe0cd3796FD126e66,
0x51A7EaD10340AF963C3124b026b86dd2807c2b1C,
0x215D67998DaCd9DA4118E4a4899bec60b79987A0,
0x8fC548B6B071bf0f2Fe64aD1Aa6032A6d2037366,
0x102902245322aAd61D55cfAD8213472A5702a593,
0x32a59b87352e980dD6aB1bAF462696D28e63525D,
0xE582794320FA7424A1f9db360A46446244065Cb5,
0xD71C552a4954673a30893BF1Db0A77f1aFA1accD,
0xEE4a267E98260aCf829Ca9dC6c9f3d5d82183Bce,
0x54683a50f0D2B3F3d1b32780524AE01AA1A583c2,
0xD09c6b71b1a7841e7dFb244D90d2a146201BF78B,
0xbB48c430C3cA821755547E514A8Fe9CC82BDD975,
0x7F326eA697EF0dd2BbD628B62F569017c1D43FCB,
0x7f048Fe4176AB39E225907F777F658a6eFDD42ce,
0x238F24101876377E9178d125D0747DE7fad9C3b2,
0x963D071201275fD5FA3dC9bB34fd3d0275ba97a7,
0x0707FD320C96b54182475B22a9D47b4045E74668,
0xa53A6fE2d8Ad977aD926C485343Ba39f32D3A3F6,
0x66EA1467282FFf8df570a1f732F0C6Ab8749154E,
0xfE2353C808F2409cCb81508005A62cef29457706,
0xa0a6Dc36041fb386378458006FEcbDdD02555DdD,
0x9C3c75c9D269aa8282BDE7BE3352D81CC91C2b6A,
0x4EC355d5780c9554EbdF1B40e9734A573D81052C,
0x8b7B509c01838a0D197a8154C5BF00A3F56fF615,
0x3DdbbbB4C18f1e745A3F65ffC84E9197629Ac6B4,
0x1712fdDC84EFa346D51261f0fa5a809fF457aBDc,
0x5221ce255906a61cf3DC2506143cd38D46A92be1,
0x2FA26aD1BfAE9e66b5c3F364a9E8EcEc8520dB4a,
0x7ea1a45f0657D2Dbd77839a916AB83112bdB5590,
0xa357Cb3CE710a4f90fB9d56979C2C3634E3965bA,
0xa948DE8A9205f1fE473490d2114c6616a90fD8d6,
0x4Dacd010e15e220bC6C5C3210d166505d2b6c63A,
0xA652565dB815Ad3B138fD98830D14Cfd1826693A,
0x101D5810f8841BcE68cB3e8CFbadB3f8C71fdff0,
0x9F7610115501abD147d1d82Ce92cea2A716690ED,
0x4B4De68ef03aE45c0d1026801Da71258DDC6BCF6,
0x2c9dB5597a4a9d2ba6780CD9722e25A9140552EE,
0xdc34F2a567dFE0E7512108b24EcEa2d92754751C,
0x05c0F2d1978a1Da91E5D82B8935c610b3F93f36B,
0x2053e0218793eEc7107ec50b09B696D4431C1Ff8,
0x3E95fEF1176acF5e5d2EF67D9C856E4ECAc73E1F,
0x2848b9f2D4FaEBaA4838c41071684c70688B455d,
0x8d4BfE71379a197ae0c3ea8B41b75f30294d6afb,
0xa2040D6b10595EcBa2F751737b4A931A868f0655,
0xE580aB95EBE6156c9717e20D513dD788B341934c,
0x33d01F8BaA2319882440FE8Cf2978fb137B59Dc1,
0x7329c9ead9b5BB0AD240B75C3CFdc2828AC2EFCf,
0x573fA57407Bb0e4b761DBe801b5cbD160A8E8C21,
0x77CB8c64e42ea076594A0C1E08115D8444Fa9fAc,
0x1b74fcf3A084d13a9D910DB12469251988985413,
0xf600fd970Bc2054d81AFb1646B50531D7567b22c,
0x767D222a509D107522e50161CA17FfCF0e5AA3dE,
0x59cc72743488Aa24Caa92a521E74e633bb1f9096,
0x2D52F7BaE61912f7217351443eA8a226996a3Def,
0x6bac48867BC94Ff20B4C62b21d484a44D04d342C,
0xc1cAd6df277106222Dd45cF5B0300fBd4d1193D5,
0x0900a13FB9382c6668a74500cccE70Eb96385e0C,
0x0F763341b448bb0f02370F4037FE4A2c84c9283f,
0x228a671629bE7a9436019AF909a1629c94bF4cAf,
0x20BFFFdB086D35e1eE06b1e0Beb849eE0a0E945c,
0x7FF3552031C441f3F01AeDEb0C2C680FBA6dD5Df
   ];

    uint256[210] allocations_100x = [
106582242,
42866022,
37332862,
33035789,
18619097,
18043304,
15502282,
12525124,
12519668,
12043576,
11555853,
10664831,
9814211,
8430828,
6998760,
6506572,
5927629,
5216518,
5118403,
4896205,
4772445,
4569692,
4521106,
4288318,
4169568,
4126612,
3925397,
3776215,
3504539,
2925422,
2805308,
2757614,
2725645,
2341022,
2229613,
2116146,
2048983,
2047793,
2014707,
2008730,
1702381,
1646305,
1629117,
1590724,
1577902,
1557515,
1548388,
1516096,
1479266,
1368527,
1287574,
1198041,
1175074,
1125025,
1108879,
1087748,
1084449,
1077852,
1058829,
1003770,
968378,
911384,
905407,
838839,
808829,
788021,
705159,
636285,
628968,
626438,
585094,
580903,
579514,
529886,
528051,
496329,
494023,
487054,
477183,
468353,
424926,
412674,
380382,
376662,
367659,
366394,
363194,
316468,
310094,
302778,
294122,
289484,
277579,
255977,
255531,
236582,
228175,
226066,
220585,
211582,
208309,
205233,
202158,
190104,
189335,
170263,
161756,
161111,
160069,
158085,
148636,
148090,
147073,
147073,
141915,
140005,
126612,
125000,
118056,
114534,
111161,
110317,
110293,
102207,
98214,
97346,
96106,
95809,
95139,
95064,
90228,
88244,
80382,
73537,
73537,
73537,
73537,
66939,
66642,
58829,
55060,
53869,
52827,
51885,
51885,
51662,
51463,
43874,
43874,
40402,
38666,
37475,
36954,
36756,
33755,
31027,
30878,
29266,
29266,
25050,
23934,
23487,
22049,
20164,
20089,
19023,
15427,
15377,
15352,
14906,
14757,
14707,
13442,
12252,
11781,
11756,
11037,
9524,
8978,
8209,
7937,
7788,
6944,
6746,
6151,
5779,
5506,
5481,
4836,
4092,
3447,
3051,
2927,
2381,
2207,
2183,
2083,
1463,
1389,
942,
843,
843,
744,
719,
694,
422,
223,
198,
124,
99
    ];

    uint256 private airdrop_supply = 5_000_000 * 10**18;
    uint256 public JAN_5_2023 = 1672898400;

    IVesting public vesting;
    mapping(address => bool) public claimed;

    event Claimed(address grantee, uint256 amount);

    constructor(address daoMultiSig, IVesting _vesting) {
        require(address(_vesting) != address(0), "Invalid address");

        vesting = _vesting;

        _grantRole(DEFAULT_ADMIN_ROLE, daoMultiSig);
        _grantRole(ADMIN_ROLE, msg.sender);
    }

    function claim()
        external
    {
        require(!claimed[msg.sender], "Already claimed.");
        for (uint i = 0; i < grantees.length; i++) {
            if (grantees[i] == msg.sender) {
                claimed[msg.sender] = true;
                uint256 amount = allocations_100x[i] * 10 ** 16;
                vesting.vest(msg.sender, amount, 365 days, JAN_5_2023);
                vesting.mintFor(msg.sender);
                emit Claimed(msg.sender, amount);
                break;
            }
        }
    }

    /// @notice Pause contract 
    function pause()
        public
        onlyRole(ADMIN_ROLE)
        whenNotPaused
    {
        _pause();
    }

    /// @notice Unpause contract
    function unpause()
        public
        onlyRole(ADMIN_ROLE)
        whenPaused
    {
        _unpause();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/math/SafeMath.sol)

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
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
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
// OpenZeppelin Contracts v4.4.0 (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "IAccessControl.sol";
import "Context.sol";
import "Strings.sol";
import "ERC165.sol";

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
        _checkRole(role, _msgSender());
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
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
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
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
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
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/IAccessControl.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/Strings.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "IERC165.sol";

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
// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

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
// OpenZeppelin Contracts v4.4.0 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

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
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
        _;
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

pragma solidity ^0.8.4;

interface IVesting {
    function vest(address beneficiary, uint256 amount, uint256 duration, uint256 releaseTimestamp) external;
    function mint() external;
    function mintFor(address grantee) external;
}