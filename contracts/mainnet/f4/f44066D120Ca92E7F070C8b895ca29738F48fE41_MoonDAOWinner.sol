// SPDX-License-Identifier: MIT
// An example of a consumer contract that relies on a subscription for funding.
pragma solidity ^0.8.6;

import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MoonDAOWinner is Ownable,VRFConsumerBaseV2 {
  VRFCoordinatorV2Interface COORDINATOR;
  LinkTokenInterface LINKTOKEN = LinkTokenInterface(0x514910771AF9Ca656af840dff83E8264EcF986CA); //https://vrf.chain.link/mainnet
  bytes32 keyHash =  0x8af398995b04c28e9951adb9721ef74c74f93e6a478f39e7e0777be13527e7ef; //200gwei
  address vrfCoordinator_  = 0x271682DEB8C4E0901D1a1550aD2e64D568E69909;  
    // Your subscription ID.
  uint64 public s_subscriptionId; 
  
  uint16 requestConfirmations = 4;
  uint32 numWords =  1;  
  mapping(uint256 => uint256) s_requestIdToRequestIndex;
  mapping(uint256 => uint) public diceList;
  mapping(uint256 => uint16) public winnerNFTList;
  

  uint256 public roll_Counter;

  //events
  event DiceRolled(uint256 indexed requestId, uint256 indexed requestNumber,uint256 indexed dice);

  uint16[1823] public NFTBlacklist =[17,24,34,41,52,69,71,74,77,98,105,127,146,153,162,166,178,198,204,214,216,255,280,283,319,332,337,339,355,358,359,361,367,369,375,377,380,389,392,398,400,409,421,432,438,451,453,459,484,487,491,497,498,501,503,507,508,520,521,547,552,559,561,563,565,566,568,575,579,589,591,595,602,607,608,614,637,657,676,679,685,687,692,693,694,701,705,713,727,741,743,745,748,754,765,770,772,777,780,784,785,786,789,790,798,806,807,811,814,822,827,828,832,835,844,852,861,866,869,873,878,882,884,885,887,891,892,897,898,903,904,906,911,919,921,926,928,935,946,959,960,963,964,965,966,967,968,970,978,979,982,986,993,1023,1029,1031,1032,1034,1038,1047,1051,1063,1066,1067,1068,1070,1078,1080,1086,1088,1092,1093,1096,1103,1108,1114,1117,1122,1131,1133,1140,1148,1151,1152,1153,1158,1177,1193,1219,1225,1233,1237,1240,1257,1265,1267,1268,1270,1276,1278,1306,1319,1320,1331,1343,1344,1361,1368,1370,1376,1381,1385,1394,1413,1414,1416,1417,1418,1421,1432,1435,1436,1437,1438,1441,1446,1453,1456,1457,1459,1463,1466,1467,1469,1482,1485,1487,1489,1490,1497,1498,1499,1500,1507,1522,1523,1530,1531,1547,1549,1551,1552,1556,1564,1566,1567,1571,1572,1578,1579,1580,1584,1586,1588,1590,1591,1593,1594,1596,1601,1602,1606,1616,1650,1651,1658,1660,1662,1663,1666,1672,1674,1680,1687,1691,1692,1694,1698,1699,1700,1703,1710,1714,1725,1734,1741,1746,1747,1750,1753,1754,1762,1764,1765,1766,1771,1772,1774,1775,1781,1785,1797,1798,1801,1803,1813,1818,1820,1830,1838,1849,1850,1855,1860,1861,1869,1872,1885,1886,1890,1894,1895,1900,1901,1906,1908,1913,1915,1919,1922,1926,1933,1936,1937,1946,1953,1955,1970,1974,1976,1999,2010,2011,2044,2045,2046,2054,2062,2068,2073,2074,2078,2087,2094,2095,2099,2104,2106,2116,2126,2129,2133,2135,2144,2149,2152,2153,2154,2155,2156,2157,2158,2159,2160,2161,2164,2166,2167,2172,2176,2177,2183,2184,2186,2191,2208,2210,2213,2215,2218,2222,2226,2227,2228,2233,2235,2237,2238,2243,2246,2248,2250,2252,2256,2258,2260,2262,2267,2269,2276,2282,2287,2386,2395,2402,2408,2409,2410,2416,2417,2418,2422,2423,2427,2428,2430,2432,2434,2435,2445,2452,2456,2460,2463,2468,2474,2476,2479,2486,2491,2493,2497,2502,2505,2508,2509,2515,2517,2518,2521,2531,2536,2538,2546,2550,2551,2556,2558,2572,2582,2584,2593,2598,2599,2602,2610,2611,2612,2614,2616,2620,2622,2632,2634,2689,2720,2721,2722,2726,2727,2730,2732,2735,2739,2741,2746,2747,2749,2752,2760,2764,2765,2768,2772,2775,2777,2781,2785,2786,2791,2792,2794,2816,2825,2827,2828,2829,2830,2839,2842,2846,2848,2849,2853,2855,2857,2861,2866,2884,2885,2889,2893,2895,2897,2898,2901,2908,2914,2915,2918,2919,2921,2925,2929,2932,2933,2944,2947,2950,2951,2956,2957,2958,2959,2960,2964,2965,2973,2976,2977,2982,2985,2986,2988,2994,2996,3002,3007,3012,3014,3018,3020,3028,3034,3037,3043,3046,3049,3056,3060,3061,3062,3063,3065,3067,3068,3069,3070,3071,3072,3073,3074,3079,3080,3081,3083,3084,3085,3086,3088,3090,3095,3097,3102,3107,3112,3113,3114,3115,3118,3119,3121,3123,3125,3126,3128,3129,3135,3137,3141,3142,3146,3149,3151,3152,3155,3158,3162,3163,3166,3167,3178,3180,3186,3193,3199,3201,3206,3210,3211,3213,3214,3216,3228,3247,3253,3254,3255,3258,3259,3260,3261,3264,3269,3271,3280,3281,3284,3307,3311,3314,3318,3319,3322,3325,3326,3327,3337,3343,3345,3346,3347,3352,3364,3370,3371,3375,3376,3384,3388,3389,3393,3394,3395,3396,3399,3409,3411,3412,3416,3419,3420,3421,3423,3424,3425,3429,3432,3435,3436,3437,3439,3445,3447,3453,3455,3458,3460,3462,3467,3468,3469,3470,3472,3473,3474,3475,3480,3483,3484,3486,3487,3493,3495,3500,3501,3506,3512,3515,3516,3521,3524,3528,3531,3542,3562,3563,3564,3568,3583,3585,3587,3596,3602,3605,3609,3612,3613,3614,3615,3616,3617,3619,3620,3621,3623,3626,3627,3629,3630,3631,3632,3635,3636,3637,3639,3640,3644,3649,3654,3655,3657,3674,3675,3687,3690,3691,3692,3700,3702,3706,3709,3714,3729,3730,3738,3740,3741,3751,3761,3762,3765,3767,3771,3775,3777,3781,3783,3786,3787,3788,3789,3791,3795,3796,3797,3798,3800,3801,3803,3806,3807,3810,3812,3813,3815,3817,3818,3820,3822,3825,3826,3827,3828,3834,3838,3839,3840,3852,3857,3858,3867,3871,3876,3878,3883,3886,3887,3889,3891,3897,3901,3902,3915,3916,3924,3934,3939,3943,3947,3951,3956,4001,4019,4020,4023,4035,4036,4038,4040,4049,4055,4062,4081,4088,4089,4092,4094,4096,4105,4115,4134,4141,4144,4152,4154,4166,4180,4188,4189,4190,4191,4192,4202,4220,4221,4232,4234,4237,4239,4240,4241,4244,4247,4255,4263,4264,4266,4267,4269,4270,4274,4276,4278,4279,4281,4283,4290,4299,4307,4309,4311,4319,4334,4341,4346,4351,4356,4362,4363,4377,4386,4392,4393,4395,4397,4398,4402,4432,4441,4456,4457,4463,4472,4475,4476,4481,4486,4493,4498,4500,4505,4509,4521,4523,4528,4534,4546,4548,4549,4553,4562,4570,4576,4578,4583,4588,4591,4592,4594,4596,4598,4602,4604,4605,4606,4609,4610,4611,4615,4620,4633,4639,4640,4643,4653,4657,4658,4659,4665,4667,4673,4675,4676,4677,4678,4680,4681,4682,4683,4684,4685,4686,4687,4688,4689,4691,4692,4694,4695,4698,4699,4700,4701,4703,4706,4709,4710,4711,4714,4717,4718,4721,4722,4728,4732,4736,4738,4742,4744,4745,4746,4748,4750,4751,4752,4753,4754,4756,4759,4763,4765,4767,4769,4772,4773,4774,4775,4776,4777,4780,4781,4782,4783,4784,4785,4786,4787,4791,4795,4799,4804,4807,4808,4811,4813,4825,4831,4834,4835,4837,4838,4840,4842,4843,4849,4857,4871,4872,4878,4879,4880,4881,4882,4883,4904,4906,4908,4911,4913,4919,4922,4923,4937,4952,4957,5073,5083,5085,5105,5109,5113,5118,5133,5146,5156,5177,5179,5183,5185,5187,5188,5189,5190,5191,5192,5196,5197,5198,5200,5201,5203,5204,5205,5206,5209,5211,5214,5215,5218,5220,5222,5223,5224,5226,5233,5234,5240,5241,5242,5246,5249,5254,5258,5259,5262,5265,5267,5273,5275,5281,5283,5285,5286,5293,5294,5308,5309,5312,5314,5315,5316,5317,5318,5352,5355,5359,5361,5371,5372,5373,5387,5388,5393,5398,5404,5410,5421,5432,5437,5438,5441,5442,5445,5456,5457,5459,5468,5471,5482,5483,5493,5500,5512,5514,5520,5534,5541,5545,5549,5553,5556,5559,5560,5566,5574,5576,5578,5583,5584,5588,5590,5592,5597,5598,5602,5606,5607,5611,5621,5623,5627,5631,5635,5640,5643,5650,5651,5653,5654,5662,5669,5673,5674,5675,5676,5687,5702,5703,5704,5706,5713,5717,5719,5720,5722,5726,5730,5735,5737,5740,5741,5742,5744,5746,5747,5750,5751,5753,5759,5765,5767,5768,5769,5771,5774,5775,5776,5777,5781,5782,5784,5786,5787,5790,5793,5794,5800,5801,5802,5803,5815,5819,5821,5837,5848,5850,5855,5856,5857,5858,5859,5860,5861,5862,5863,5865,5866,5869,5874,5877,5878,5879,5881,5889,5891,5892,5894,5895,5896,5900,5901,5905,5910,5911,5915,5916,5919,5920,5921,5923,5924,5925,5926,5931,5933,5936,5939,5940,5943,5946,5947,5948,5952,5954,5955,5956,5960,5964,5965,5971,5975,5977,5978,5979,5980,5982,5983,5984,5985,5986,5987,5988,5989,5990,6003,6013,6017,6019,6020,6021,6025,6049,6051,6057,6065,6068,6070,6073,6076,6079,6080,6081,6083,6085,6086,6087,6088,6090,6091,6094,6096,6098,6101,6103,6104,6112,6117,6124,6134,6144,6149,6151,6158,6161,6173,6177,6184,6185,6193,6196,6199,6201,6208,6215,6224,6229,6232,6238,6246,6249,6250,6252,6254,6256,6257,6258,6260,6282,6292,6293,6305,6311,6313,6363,6364,6367,6378,6380,6382,6383,6384,6385,6396,6397,6406,6410,6417,6422,6435,6440,6443,6448,6454,6457,6461,6472,6479,6480,6486,6494,6499,6501,6503,6505,6506,6507,6508,6509,6510,6511,6512,6513,6514,6518,6519,6520,6521,6522,6523,6524,6525,6526,6527,6528,6529,6530,6531,6533,6534,6535,6536,6537,6538,6539,6540,6541,6543,6544,6548,6549,6550,6551,6553,6582,6588,6613,6623,6624,6625,6631,6635,6638,6654,6655,6657,6658,6660,6662,6663,6664,6667,6668,6672,6678,6681,6685,6687,6689,6690,6692,6693,6695,6696,6698,6699,6700,6702,6703,6704,6706,6708,6709,6710,6712,6713,6718,6719,6721,6722,6724,6726,6730,6735,6736,6738,6741,6743,6745,6750,6751,6753,6755,6756,6757,6761,6764,6765,6766,6768,6771,6778,6783,6786,6787,6788,6791,6792,6797,6800,6801,6803,6804,6805,6810,6813,6814,6819,6822,6825,6830,6835,6836,6837,6838,6840,6842,6849,6854,6857,6861,6866,6867,6870,6871,6876,6878,6881,6883,6884,6889,6891,6895,6900,6903,6916,6917,6918,6919,6923,6928,6934,6936,6937,6939,6941,6945,6946,6948,6950,6951,6957,6958,6959,6961,6968,6971,6974,6975,6977,6978,6979,6986,6996,6999,7003,7011,7013,7019,7022,7023,7025,7030,7038,7039,7040,7041,7044,7045,7050,7051,7057,7059,7063,7065,7074,7100,7371,7379,7386,7395,7399,7400,7406,7407,7408,7409,7412,7413,7414,7421,7423,7424,7429,7430,7431,7440,7441,7442,7448,7449,7450,7455,7460,7461,7464,7465,7469,7478,7487,7488,7490,7491,7495,7496,7499,7501,7506,7507,7509,7510,7511,7512,7513,7516,7517,7521,7523,7524,7532,7536,7537,7538,7542,7544,7546,7547,7548,7549,7550,7551,7552,7553,7554,7557,7560,7561,7564,7565,7566,7568,7570,7573,7574,7576,7577,7578,7579,7580,7581,7586,7593,7596,7598,7600,7603,7604,7606,7612,7614,7615,7617,7618,7619,7622,7623,7625,7627,7629,7630,7632,7634,7636,7647,7651,7656,7668,7674,7676,7681,7686,7696,7698,7703,7707,7709,7722,7735,7736,7737,7738,7739,7741,7743,7744,7746,7748,7749,7750,7754,7756,7758,7759,7782,7783,7784,7787,7789,7790,7791,7793,7795,7804,7811,7825,7830,7837,7839,7840,7843,7844,7860,7863,7865,7869,7871,7885,7888,7889,7896,7901,7911,7912,7914,7915,7964,7966,7970,7977,7979,7990,7994,8001];
  
  uint public maxLen = 8016;
  uint16 public lenBlack =uint16(NFTBlacklist.length);

  function reMapping(
      uint16 rolledNum 
  )public view returns(uint16 NFTID){  
    if(rolledNum<NFTBlacklist[0]){
      NFTID= rolledNum;
    }else if (rolledNum+lenBlack > NFTBlacklist[lenBlack-1]){
      NFTID= rolledNum + lenBlack;
    }else {
      for(uint16 i=1; i<lenBlack-1; i++){
        if(rolledNum+i>NFTBlacklist[i-1] && rolledNum+i<NFTBlacklist[i]){
          NFTID = rolledNum+i;
          break;
        } 
      } 
    }   
  }


  function setsubscript(
      uint64 subscriptionId_ 
    )external onlyOwner {
    s_subscriptionId=subscriptionId_; 
  }


  constructor(
    uint64 subscriptionId_    
  ) VRFConsumerBaseV2(vrfCoordinator_) {
    COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator_);
    s_subscriptionId = subscriptionId_; 
  }

   
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
    uint dice= s_randomWord % (maxLen - NFTBlacklist.length);
    uint256 requestNumber = s_requestIdToRequestIndex[requestId];
    diceList[requestNumber] = dice;

    emit DiceRolled(requestId,requestNumber,dice);
  } 


  function reMappingAList() external onlyOwner{  
    //sort diceList to a and c。
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