// SPDX-License-Identifier: MIT
// An example of a consumer contract that relies on a subscription for funding.
pragma solidity ^0.8.6;

import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MoonDAOWinner is Ownable,VRFConsumerBaseV2 {
  VRFCoordinatorV2Interface COORDINATOR;
  LinkTokenInterface LINKTOKEN = LinkTokenInterface(0x01BE23585060835E02B77ef475b0Cc51aA1e0709); 
  bytes32 keyHash = 0xd89b2bf150e3b9e13446986e571fb9cab24b13cea0a43ea20a6049a85cc807cc ;
  address vrfCoordinator_  = 0x6168499c0cFfCaCD319c818142124B7A15E857ab;  
    // Your subscription ID.
  uint64 public s_subscriptionId; 
  
  uint16 requestConfirmations = 4;
  uint32 numWords =  1;  
  mapping(uint256 => uint256) s_requestIdToRequestIndex;
  mapping(uint256 => uint) public diceList;
  mapping(uint256 => uint16) public winnerNFTList;
  

  uint256 public roll_Counter;

  //events
  event DiceRolled(uint256 indexed requestId, uint256 indexed requestNumber,uint256 indexed winner);

  uint16[2500] public NFTBlacklist =[0,3,6,10,12,23,29,33,35,37,43,44,45,48,51,53,57,60,62,64,70,73,74,76,77,80,81,86,88,89,90,100,103,104,110,111,112,114,115,118,119,122,124,125,127,131,134,139,153,154,160,166,168,184,185,188,190,192,194,195,198,199,203,209,211,214,215,218,228,229,231,238,242,244,251,252,255,256,258,259,260,261,267,270,274,277,279,281,284,287,289,290,294,295,299,300,303,309,311,312,317,319,320,322,323,332,339,340,343,345,346,347,351,355,356,359,367,378,386,387,388,392,394,399,400,406,411,412,413,419,422,423,425,428,435,437,439,442,444,447,451,454,456,460,468,470,471,479,481,486,491,492,494,497,501,506,507,509,514,517,521,523,525,526,532,535,536,537,538,540,543,545,547,548,549,552,553,555,560,569,576,577,578,581,582,593,594,595,597,600,601,602,603,607,609,610,612,620,624,628,629,630,636,638,641,643,652,657,658,662,666,667,668,675,687,693,703,704,705,707,714,718,723,727,728,738,740,741,743,753,761,765,767,769,772,775,778,779,790,797,801,806,810,817,823,827,830,832,841,844,847,854,855,857,865,866,869,872,874,875,889,894,897,900,907,908,910,916,917,920,930,931,938,942,956,962,964,971,972,975,976,981,989,994,995,1001,1007,1009,1010,1013,1015,1018,1020,1021,1025,1026,1027,1030,1031,1032,1033,1034,1035,1037,1040,1043,1044,1045,1048,1053,1054,1059,1065,1066,1072,1074,1078,1082,1087,1088,1092,1096,1099,1102,1106,1109,1110,1111,1116,1117,1118,1119,1120,1122,1127,1128,1136,1139,1146,1152,1157,1159,1160,1161,1164,1167,1174,1175,1182,1185,1186,1187,1189,1190,1192,1195,1199,1208,1212,1217,1221,1227,1229,1231,1233,1235,1236,1237,1238,1244,1248,1258,1264,1266,1268,1273,1274,1280,1281,1283,1289,1290,1291,1293,1300,1302,1304,1307,1308,1309,1314,1315,1316,1323,1325,1334,1336,1337,1338,1340,1341,1343,1344,1345,1346,1350,1353,1354,1357,1358,1359,1360,1368,1371,1375,1379,1382,1383,1385,1387,1392,1393,1394,1397,1402,1404,1406,1412,1416,1417,1424,1440,1441,1442,1449,1455,1457,1469,1474,1478,1480,1483,1485,1486,1487,1488,1491,1496,1497,1498,1510,1511,1516,1519,1523,1525,1526,1527,1532,1534,1541,1543,1547,1549,1553,1554,1556,1557,1563,1565,1566,1574,1576,1577,1579,1583,1592,1593,1598,1613,1614,1623,1625,1626,1643,1646,1647,1653,1655,1658,1661,1664,1668,1670,1673,1677,1679,1681,1683,1684,1694,1696,1701,1704,1706,1707,1711,1713,1718,1729,1732,1734,1749,1755,1757,1766,1767,1773,1776,1777,1778,1781,1788,1791,1792,1797,1800,1801,1812,1813,1818,1820,1822,1826,1828,1834,1835,1836,1838,1841,1842,1848,1851,1853,1854,1857,1860,1863,1864,1872,1875,1876,1877,1878,1882,1883,1884,1889,1890,1892,1895,1897,1904,1905,1906,1907,1908,1911,1916,1918,1920,1923,1924,1925,1929,1930,1932,1938,1939,1943,1944,1949,1955,1963,1964,1967,1975,1983,1984,1985,1987,1988,1989,1993,1995,1998,2004,2012,2016,2017,2019,2022,2033,2039,2043,2045,2049,2053,2054,2057,2062,2064,2067,2068,2069,2071,2084,2095,2098,2099,2106,2110,2111,2113,2114,2118,2119,2122,2126,2127,2132,2134,2136,2145,2146,2149,2151,2155,2164,2166,2170,2173,2174,2175,2177,2178,2180,2182,2184,2187,2188,2192,2195,2201,2202,2206,2210,2213,2223,2228,2235,2239,2244,2246,2258,2259,2262,2264,2267,2270,2272,2273,2279,2280,2285,2288,2289,2302,2305,2309,2310,2314,2319,2320,2325,2327,2328,2331,2333,2337,2340,2343,2345,2346,2348,2351,2360,2363,2364,2370,2371,2372,2375,2376,2378,2386,2395,2396,2399,2400,2402,2403,2404,2408,2412,2414,2420,2421,2422,2423,2429,2430,2433,2435,2438,2441,2446,2448,2450,2451,2454,2455,2457,2458,2459,2461,2462,2465,2472,2474,2476,2479,2482,2487,2488,2489,2491,2493,2494,2495,2505,2511,2514,2516,2517,2519,2532,2534,2541,2543,2547,2549,2550,2551,2552,2553,2557,2558,2560,2561,2562,2570,2577,2581,2582,2584,2586,2590,2591,2595,2597,2602,2609,2610,2611,2614,2617,2622,2625,2629,2630,2631,2633,2634,2638,2642,2656,2658,2661,2662,2667,2671,2673,2674,2683,2689,2692,2693,2695,2703,2706,2709,2711,2713,2717,2726,2727,2728,2729,2734,2735,2747,2752,2754,2756,2757,2758,2760,2762,2763,2769,2770,2773,2777,2786,2787,2789,2790,2793,2794,2795,2796,2799,2803,2809,2810,2811,2814,2816,2817,2818,2819,2821,2822,2825,2830,2831,2835,2837,2838,2843,2850,2851,2855,2858,2859,2869,2870,2873,2881,2885,2886,2888,2890,2892,2894,2895,2896,2898,2901,2902,2909,2916,2920,2921,2926,2929,2930,2935,2939,2941,2947,2949,2951,2952,2953,2954,2957,2959,2960,2964,2967,2969,2970,2972,2977,2982,2988,2989,2992,2994,2995,2996,2999,3001,3004,3006,3007,3010,3011,3012,3017,3018,3019,3020,3022,3025,3029,3030,3031,3032,3034,3037,3038,3042,3048,3051,3053,3055,3058,3066,3074,3076,3080,3083,3088,3091,3094,3100,3101,3102,3109,3117,3119,3120,3121,3123,3125,3128,3130,3131,3132,3136,3140,3141,3142,3146,3149,3152,3155,3156,3160,3164,3165,3167,3168,3170,3172,3174,3176,3177,3179,3185,3187,3191,3193,3199,3200,3203,3204,3206,3213,3222,3224,3229,3233,3235,3236,3244,3247,3249,3253,3256,3259,3261,3267,3272,3274,3277,3283,3284,3289,3291,3294,3298,3303,3305,3317,3318,3319,3322,3325,3330,3334,3335,3336,3338,3348,3350,3351,3352,3354,3358,3359,3360,3364,3366,3369,3372,3374,3376,3377,3379,3380,3382,3383,3384,3396,3404,3411,3417,3418,3421,3422,3430,3436,3442,3448,3449,3451,3453,3455,3456,3459,3467,3468,3472,3480,3481,3482,3491,3493,3494,3495,3498,3499,3502,3511,3513,3519,3524,3528,3531,3532,3534,3536,3539,3548,3553,3558,3559,3564,3565,3566,3567,3569,3570,3571,3573,3575,3579,3581,3582,3585,3588,3589,3593,3595,3602,3606,3610,3611,3614,3615,3627,3630,3635,3638,3641,3647,3655,3657,3659,3661,3662,3663,3667,3672,3677,3680,3682,3689,3691,3694,3701,3705,3707,3713,3714,3715,3720,3722,3725,3726,3730,3734,3736,3738,3739,3744,3746,3749,3751,3756,3760,3761,3762,3766,3768,3770,3774,3778,3782,3784,3787,3788,3790,3792,3794,3797,3798,3799,3801,3803,3806,3809,3810,3818,3821,3822,3823,3826,3827,3829,3832,3834,3838,3840,3846,3849,3850,3851,3859,3866,3867,3868,3872,3875,3883,3887,3893,3904,3905,3910,3911,3914,3917,3920,3923,3924,3925,3928,3930,3934,3936,3951,3952,3954,3955,3958,3961,3963,3971,3973,3975,3976,3981,3982,3984,3987,3988,3990,3996,3997,3998,4000,4007,4008,4009,4012,4021,4023,4025,4027,4028,4029,4031,4040,4044,4045,4047,4050,4053,4059,4061,4066,4072,4075,4076,4077,4078,4081,4083,4085,4086,4089,4094,4095,4096,4098,4101,4104,4107,4109,4113,4117,4118,4119,4120,4121,4126,4129,4133,4134,4135,4139,4141,4148,4150,4154,4163,4166,4172,4174,4178,4183,4184,4186,4189,4190,4191,4193,4194,4195,4199,4203,4204,4205,4206,4207,4208,4210,4225,4226,4230,4232,4234,4240,4241,4242,4249,4251,4255,4260,4261,4263,4264,4271,4276,4277,4278,4279,4280,4283,4284,4286,4287,4294,4296,4297,4298,4299,4308,4312,4316,4322,4323,4326,4330,4331,4332,4335,4336,4337,4338,4340,4343,4344,4346,4354,4363,4365,4367,4368,4369,4371,4372,4375,4377,4378,4385,4386,4388,4395,4397,4398,4404,4409,4412,4413,4420,4425,4427,4435,4438,4439,4441,4442,4444,4445,4446,4447,4451,4454,4457,4458,4459,4462,4472,4477,4478,4480,4481,4488,4489,4491,4492,4493,4498,4503,4506,4508,4512,4516,4517,4518,4521,4522,4528,4533,4535,4539,4540,4543,4544,4547,4554,4555,4556,4557,4559,4560,4561,4565,4566,4577,4580,4581,4584,4593,4594,4595,4600,4601,4606,4611,4615,4617,4624,4627,4628,4632,4634,4640,4641,4649,4655,4657,4659,4666,4667,4669,4674,4681,4682,4684,4688,4690,4691,4693,4696,4698,4699,4700,4703,4704,4707,4709,4714,4718,4719,4721,4722,4723,4730,4733,4734,4744,4746,4751,4752,4757,4761,4765,4769,4781,4782,4790,4791,4793,4797,4798,4804,4807,4809,4811,4812,4820,4823,4825,4831,4832,4833,4840,4841,4844,4847,4848,4852,4853,4854,4857,4859,4861,4862,4863,4864,4865,4868,4870,4877,4878,4879,4882,4884,4886,4888,4892,4896,4898,4904,4907,4909,4911,4912,4914,4915,4919,4920,4922,4929,4932,4933,4936,4937,4938,4939,4949,4951,4952,4965,4967,4970,4971,4973,4975,4980,4984,4985,4989,4991,4992,4994,4996,4997,5001,5002,5004,5005,5006,5007,5010,5015,5016,5023,5036,5048,5051,5056,5058,5059,5061,5071,5080,5082,5084,5086,5087,5091,5099,5103,5105,5107,5108,5109,5121,5124,5128,5129,5130,5131,5133,5135,5144,5145,5152,5154,5155,5158,5163,5164,5165,5168,5176,5179,5183,5185,5187,5193,5195,5201,5202,5206,5207,5208,5209,5211,5212,5213,5214,5217,5222,5230,5234,5240,5245,5249,5255,5257,5258,5259,5260,5263,5269,5270,5275,5276,5278,5284,5287,5288,5289,5290,5292,5296,5303,5304,5307,5310,5312,5316,5317,5323,5325,5329,5332,5334,5335,5340,5341,5342,5345,5346,5350,5351,5355,5358,5360,5361,5364,5365,5370,5372,5381,5383,5385,5390,5404,5406,5407,5412,5414,5416,5418,5421,5424,5427,5428,5431,5432,5433,5434,5437,5445,5449,5450,5455,5456,5459,5462,5463,5465,5477,5479,5481,5482,5483,5491,5492,5494,5496,5497,5499,5507,5508,5512,5515,5524,5525,5526,5527,5533,5535,5538,5546,5549,5550,5551,5554,5559,5560,5561,5562,5563,5564,5565,5566,5568,5569,5571,5573,5574,5577,5583,5594,5603,5608,5611,5613,5618,5620,5624,5625,5633,5636,5637,5640,5644,5654,5655,5665,5667,5668,5669,5678,5688,5691,5694,5696,5701,5704,5705,5706,5710,5718,5720,5732,5738,5739,5742,5744,5746,5748,5752,5756,5762,5763,5764,5772,5777,5783,5784,5789,5790,5792,5797,5801,5809,5812,5815,5819,5820,5821,5823,5834,5837,5839,5840,5841,5846,5853,5854,5856,5858,5859,5861,5864,5872,5873,5876,5879,5883,5885,5892,5900,5905,5906,5909,5911,5913,5915,5919,5921,5922,5926,5929,5930,5933,5934,5942,5946,5947,5948,5949,5955,5958,5959,5962,5965,5973,5977,5981,5985,5988,5991,5992,5996,5997,5998,6003,6008,6010,6016,6020,6022,6023,6024,6025,6028,6030,6036,6038,6040,6041,6042,6053,6064,6065,6068,6071,6076,6079,6082,6093,6094,6095,6096,6097,6098,6099,6100,6101,6104,6105,6106,6108,6114,6118,6121,6123,6125,6126,6132,6133,6136,6138,6139,6144,6149,6150,6153,6154,6155,6158,6161,6162,6165,6168,6170,6172,6173,6177,6179,6183,6184,6186,6199,6204,6209,6211,6212,6213,6214,6222,6223,6224,6226,6230,6231,6232,6234,6236,6237,6238,6239,6242,6255,6261,6264,6265,6269,6272,6275,6277,6280,6281,6283,6285,6287,6289,6290,6298,6300,6301,6303,6307,6310,6311,6313,6321,6327,6330,6335,6336,6338,6339,6341,6342,6344,6350,6351,6356,6358,6360,6363,6381,6382,6386,6389,6391,6394,6397,6398,6400,6401,6410,6411,6412,6414,6415,6418,6420,6421,6426,6427,6438,6443,6444,6446,6448,6449,6454,6457,6460,6461,6463,6465,6466,6470,6471,6478,6482,6491,6497,6499,6507,6511,6514,6520,6522,6524,6527,6534,6539,6540,6543,
  6545,6546,6551,6559,6561,6562,6563,6568,6572,6574,6580,6582,6583,6584,6586,6587,6592,6594,6597,6598,6600,6605,6610,6614,6616,6619,6621,6622,6641,6648,6649,6653,6654,6663,6676,6679,6685,6686,6688,6690,6692,6698,6699,6704,6707,6710,6712,6714,6720,6722,6727,6728,6732,6733,6734,6739,6743,6744,6745,6750,6754,6756,6757,6758,6763,6765,6768,6769,6770,6772,6773,6779,6785,6787,6788,6790,6795,6797,6798,6800,6805,6806,6807,6809,6810,6813,6817,6818,6819,6823,6824,6826,6830,6831,6834,6836,6843,6844,6845,6846,6850,6852,6855,6857,6858,6859,6860,6869,6876,6877,6881,6887,6889,6890,6891,6892,6893,6894,6895,6896,6902,6912,6914,6921,6922,6923,6927,6938,6941,6943,6946,6949,6954,6957,6965,6966,6968,6977,6981,6983,6992,6993,6995,7001,7005,7011,7018,7025,7026,7029,7032,7033,7034,7037,7042,7043,7048,7051,7054,7055,7058,7065,7070,7072,7073,7077,7081,7086,7093,7096,7098,7104,7109,7115,7116,7118,7122,7124,7125,7126,7131,7133,7138,7145,7148,7155,7171,7173,7175,7179,7182,7183,7186,7187,7189,7190,7192,7194,7195,7199,7202,7213,7214,7215,7218,7220,7223,7224,7227,7230,7231,7236,7238,7240,7245,7248,7251,7252,7256,7257,7261,7264,7266,7272,7273,7274,7276,7278,7280,7281,7283,7291,7292,7296,7299,7302,7305,7307,7308,7313,7314,7317,7324,7328,7332,7335,7342,7346,7347,7352,7353,7358,7362,7365,7366,7371,7372,7376,7378,7380,7382,7383,7388,7391,7392,7398,7410,7413,7418,7420,7421,7428,7431,7437,7440,7441,7445,7447,7448,7449,7450,7451,7452,7454,7460,7461,7462,7469,7472,7473,7477,7480,7483,7486,7495,7499,7502,7503,7505,7508,7515,7516,7529,7534,7540,7541,7548,7553,7560,7563,7565,7566,7569,7570,7577,7578,7580,7582,7587,7589,7590,7591,7596,7598,7599,7604,7607,7612,7617,7618,7624,7625,7627,7632,7642,7643,7645,7648,7650,7657,7660,7662,7667,7668,7674,7676,7680,7686,7687,7689,7690,7692,7693,7700,7703,7708,7711,7712,7714,7716,7717,7721,7722,7723,7724,7726,7729,7730,7732,7733,7734,7736,7737,7740,7742,7743,7744,7752,7755,7757,7761,7766,7768,7770,7774,7779,7787,7790,7796,7797,7798,7804,7809,7810,7812,7816,7817,7819,7824,7826,7827,7832,7837,7845,7848,7849,7851,7852,7854,7857,7858,7860,7863,7873,7882,7888,7889,7894,7898,7903,7911,7915,7916,7917,7926,7933,7935,7936,7938,7940,7945,7954,7960,7967,7970,7972,7976,7980,7986,7987,7992,7994,7995,7997];
  
  uint public maxLen = 8003;
  uint16 public lenBlack =uint16(NFTBlacklist.length);

  function reMapping(
      uint16 rolledNum 
  )public view returns(uint16 backnum){  
    if(rolledNum<NFTBlacklist[0]){
      backnum= rolledNum;
    }else if (rolledNum+lenBlack > NFTBlacklist[lenBlack-1]){
      backnum= rolledNum + lenBlack;
    }else {
      for(uint16 i=1; i<lenBlack-1; i++){
        if(rolledNum+i>NFTBlacklist[i-1] && rolledNum+i<NFTBlacklist[i]){
          backnum = rolledNum+i;
          break;
        } 
      } 
    }   
  }


  function resetWinner( 
    )external onlyOwner {
      for (uint i=0; i< roll_Counter ; i++){ 
        winnerNFTList[i] = 0;
        diceList[i] = 0;
      } 
    roll_Counter=0;
  }

  function setsubscript(
      uint64 subscriptionId_ 
    )external onlyOwner {
    s_subscriptionId=subscriptionId_; 
  }

  function setMaxLen(
      uint maxLen_ 
    )external onlyOwner {
    maxLen=maxLen_; 
  }

  constructor(
    uint64 subscriptionId_    
  ) VRFConsumerBaseV2(vrfCoordinator_) {
    COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator_);
    s_subscriptionId = subscriptionId_; 
  }

  // Assumes the subscription is funded sufficiently.
  // Will revert if subscription is not set and funded.    
  function RollTheDice() external onlyOwner { 
    uint32 callbackGasLimit = 300000;
    uint256 requestId  = COORDINATOR.requestRandomWords(
      keyHash,
      s_subscriptionId,
      requestConfirmations,
      callbackGasLimit,
      numWords
    );
    s_requestIdToRequestIndex[requestId] = roll_Counter;
    roll_Counter += 1;
  } 
  
  function fulfillRandomWords(
    uint256 requestId,
    uint256[] memory randomWords
  ) internal override {
    uint s_randomWord = randomWords[0];
    uint winner= s_randomWord % (maxLen - NFTBlacklist.length);
    uint256 requestNumber = s_requestIdToRequestIndex[requestId];
    diceList[requestNumber] = winner;

    emit DiceRolled(requestId,requestNumber,winner);
  } 

  function mappingDiceToNFT() external onlyOwner {
    for(uint i=0;i<roll_Counter;i++){    //120万操作数1个值，1760万11个值。
      winnerNFTList[i] = reMapping(uint16(diceList[i]));
    }
  }

  function reMappingAList() external onlyOwner{  
    //先排序得到一个新的list，从小到大排列。
    uint16[] memory a = new uint16[](roll_Counter); 
    uint[] memory c = new uint[](roll_Counter);
    for(uint i=0;i< roll_Counter;i++){
      a[i] = uint16(diceList[i]);
      c[i] = i;
    }
    (a,c) = insertionSort(a,c); 
      
    uint16 reci=1;

    for(uint index=0;index<roll_Counter;index++){
      uint16 rolledNum = a[index];  
      if(rolledNum<NFTBlacklist[0]){
        winnerNFTList[c[index]]= rolledNum;      
      }else if (rolledNum+lenBlack > NFTBlacklist[lenBlack-1]){
        winnerNFTList[c[index]]= rolledNum + lenBlack;
      }else {
        for(uint16 i=reci; i<lenBlack-1; i++){
          if(rolledNum+i>NFTBlacklist[i-1] && rolledNum+i<NFTBlacklist[i]){
            winnerNFTList[c[index]] = rolledNum+i;
            reci=i;
            break;
          } 
        } 
      } 
    }
  }

  function insertionSort(uint16[] memory a,uint[] memory c) public pure returns(uint16[] memory ,uint[] memory ) {
      // note that uint can not take negative value
      for (uint i = 1;i < a.length;i++){
          uint16 temp = a[i];
          uint temp2 = c[i];
          uint j=i;
          while( (j >= 1) && (temp < a[j-1])){
              a[j] = a[j-1];
              c[j] = c[j-1];
              j--;
          }
          a[j] = temp;
          c[j] = temp2;
      }
      return(a,c);
  }


}


// 0x4CDf24BedD6dBc8aB6bb675E2ACe1f8073591515 rinkeby mappingDiceToNFT
// 0x5f86DA7b4888e3A128CD935A645409d6fb191e90  reMappingAList

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
pragma solidity ^0.8.4;

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness. It ensures 2 things:
 * @dev 1. The fulfillment came from the VRFCoordinator
 * @dev 2. The consumer contract implements fulfillRandomWords.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constructor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash). Create subscription, fund it
 * @dev and your consumer contract as a consumer of it (see VRFCoordinatorInterface
 * @dev subscription management functions).
 * @dev Call requestRandomWords(keyHash, subId, minimumRequestConfirmations,
 * @dev callbackGasLimit, numWords),
 * @dev see (VRFCoordinatorInterface for a description of the arguments).
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomWords method.
 *
 * @dev The randomness argument to fulfillRandomWords is a set of random words
 * @dev generated from your requestId and the blockHash of the request.
 *
 * @dev If your contract could have concurrent requests open, you can use the
 * @dev requestId returned from requestRandomWords to track which response is associated
 * @dev with which randomness request.
 * @dev See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ.
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request. It is for this reason that
 * @dev that you can signal to an oracle you'd like them to wait longer before
 * @dev responding to the request (however this is not enforced in the contract
 * @dev and so remains effective only in the case of unmodified oracle software).
 */
abstract contract VRFConsumerBaseV2 {
  error OnlyCoordinatorCanFulfill(address have, address want);
  address private immutable vrfCoordinator;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   */
  constructor(address _vrfCoordinator) {
    vrfCoordinator = _vrfCoordinator;
  }

  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBaseV2 expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomWords the VRF output expanded to the requested number of words
   */
  function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal virtual;

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords) external {
    if (msg.sender != vrfCoordinator) {
      revert OnlyCoordinatorCanFulfill(msg.sender, vrfCoordinator);
    }
    fulfillRandomWords(requestId, randomWords);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface VRFCoordinatorV2Interface {
  /**
   * @notice Get configuration relevant for making requests
   * @return minimumRequestConfirmations global min for request confirmations
   * @return maxGasLimit global max for request gas limit
   * @return s_provingKeyHashes list of registered key hashes
   */
  function getRequestConfig()
    external
    view
    returns (
      uint16,
      uint32,
      bytes32[] memory
    );

  /**
   * @notice Request a set of random words.
   * @param keyHash - Corresponds to a particular oracle job which uses
   * that key for generating the VRF proof. Different keyHash's have different gas price
   * ceilings, so you can select a specific one to bound your maximum per request cost.
   * @param subId  - The ID of the VRF subscription. Must be funded
   * with the minimum subscription balance required for the selected keyHash.
   * @param minimumRequestConfirmations - How many blocks you'd like the
   * oracle to wait before responding to the request. See SECURITY CONSIDERATIONS
   * for why you may want to request more. The acceptable range is
   * [minimumRequestBlockConfirmations, 200].
   * @param callbackGasLimit - How much gas you'd like to receive in your
   * fulfillRandomWords callback. Note that gasleft() inside fulfillRandomWords
   * may be slightly less than this amount because of gas used calling the function
   * (argument decoding etc.), so you may need to request slightly more than you expect
   * to have inside fulfillRandomWords. The acceptable range is
   * [0, maxGasLimit]
   * @param numWords - The number of uint256 random values you'd like to receive
   * in your fulfillRandomWords callback. Note these numbers are expanded in a
   * secure way by the VRFCoordinator from a single random value supplied by the oracle.
   * @return requestId - A unique identifier of the request. Can be used to match
   * a request to a response in fulfillRandomWords.
   */
  function requestRandomWords(
    bytes32 keyHash,
    uint64 subId,
    uint16 minimumRequestConfirmations,
    uint32 callbackGasLimit,
    uint32 numWords
  ) external returns (uint256 requestId);

  /**
   * @notice Create a VRF subscription.
   * @return subId - A unique subscription id.
   * @dev You can manage the consumer set dynamically with addConsumer/removeConsumer.
   * @dev Note to fund the subscription, use transferAndCall. For example
   * @dev  LINKTOKEN.transferAndCall(
   * @dev    address(COORDINATOR),
   * @dev    amount,
   * @dev    abi.encode(subId));
   */
  function createSubscription() external returns (uint64 subId);

  /**
   * @notice Get a VRF subscription.
   * @param subId - ID of the subscription
   * @return balance - LINK balance of the subscription in juels.
   * @return reqCount - number of requests for this subscription, determines fee tier.
   * @return owner - owner of the subscription.
   * @return consumers - list of consumer address which are able to use this subscription.
   */
  function getSubscription(uint64 subId)
    external
    view
    returns (
      uint96 balance,
      uint64 reqCount,
      address owner,
      address[] memory consumers
    );

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @param newOwner - proposed new owner of the subscription
   */
  function requestSubscriptionOwnerTransfer(uint64 subId, address newOwner) external;

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @dev will revert if original owner of subId has
   * not requested that msg.sender become the new owner.
   */
  function acceptSubscriptionOwnerTransfer(uint64 subId) external;

  /**
   * @notice Add a consumer to a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - New consumer which can use the subscription
   */
  function addConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Remove a consumer from a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - Consumer to remove from the subscription
   */
  function removeConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Cancel a subscription
   * @param subId - ID of the subscription
   * @param to - Where to send the remaining LINK to
   */
  function cancelSubscription(uint64 subId, address to) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface LinkTokenInterface {
  function allowance(address owner, address spender) external view returns (uint256 remaining);

  function approve(address spender, uint256 value) external returns (bool success);

  function balanceOf(address owner) external view returns (uint256 balance);

  function decimals() external view returns (uint8 decimalPlaces);

  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);

  function increaseApproval(address spender, uint256 subtractedValue) external;

  function name() external view returns (string memory tokenName);

  function symbol() external view returns (string memory tokenSymbol);

  function totalSupply() external view returns (uint256 totalTokensIssued);

  function transfer(address to, uint256 value) external returns (bool success);

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  ) external returns (bool success);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool success);
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