// SPDX-License-Identifier: MIT
/* ============================================== DEFI HUNTERS DAO =================================================
                                           https://defihuntersdao.club/
---------------------------------------------------- Feb 2021 ------------------------------------------------------
 NNNNNNNNL     NNNNNNNNL       .NNNN.      .NNNNNNN.          JNNNNNN) (NN)         JNNNL     (NN)   NNNN     NNNN)   
 NNNNNNNNNN.   NNNNNNNNNN.     JNNNN)     JNNNNNNNNNL       (NNNNNNNN` (NN)        .NNNNN     (NN)   NNNN)   (NNNN)   
 NNN    4NNN   NNN    4NNN     NNNNNN    (NNN`   `NNN)     (NNNF       (NN)        (NNNNN)    (NN)  (NNNNN   JNNNN)   
 NNN     NNN)  NNN     NNN)   (NN)4NN)   NNN)     (NNN     NNN)        (NN)        NNN`NNN    (NN)  (NNNNN) .NNNNN)   
 NNN     4NN)  NNN     4NN)   NNN (NNN   NNN`     `NNN     NNN`        (NN)       (NN) NNN)   (NN)  (NN)NNL (NN(NN)   
 NNN     JNN)  NNN     JNN)  (NNF  NNN)  NNN       NNN     NNN         (NN)       NNN` (NNN   (NN)  (NN)4NN NN)(NNN   
 NNN     NNN)  NNN     NNN)  JNNNNNNNNL  NNN)     (NNN     NNN)        (NN)      .NNNNNNNNN.  (NN)  JNN (NNNNN` NNN   
 NNN    JNNN   NNN    JNNN  .NNNNNNNNNN  4NNN     NNNF     4NNN.       (NN)      JNNNNNNNNN)  (NN)  NNN  NNNNF  NNN   
 NNN___NNNN`   NNN___NNNN`  (NNF    NNN)  NNNNL_JNNNN       NNNNNL_JN  (NNL_____ NNN`   (NNN  (NN)  NNN  (NNN`  NNN   
 NNNNNNNNN`    NNNNNNNNN`   NNN`    (NNN   4NNNNNNNF         4NNNNNNN) (NNNNNNNN(NNF     NNN) (NN)  NNN   NNN   NNN   
 """"""`       """"""`      """      """     """""             `"""""  `""""""""`""`     `""`                         
                    (NN)  NNN
          .NNNN.    (NN)  NNN                                                     JNNNNN.     _NNN
          JNNNN)    (NN)  NNN                                  JNN               NNNNNNNN.  NNNNNN
          NNNNNN    (NN)  NNN     ____.       ____.  .____.    NNN       ___.   (NNF  (NNL  4N"NNN
         (NN)4NN)   (NN)  NNN   JNNNNNNN.   JNNNNN) (NNNNNNL (NNNNNN)  NNNNNNN. NNN)  `NNN     NNN
         NNN (NNN   (NN)  NNN  (NNN""4NNN. NNNN"""` `F" `NNN)`NNNNNN) JNNF 4NNL NNN    NNN     NNN
        (NNF  NNN)  (NN)  NNN  NNN)   4NN)(NNN       .JNNNNN)  NNN   (NNN___NNN NNN    NNN     NNN
        JNNNNNNNNL  (NN)  NNN  NNN    (NN)(NN)      JNNNNNNN)  NNN   (NNNNNNNNN NNN)   NNN     NNN
       .NNNNNNNNNN  (NN)  NNN  NNN)   JNN)(NNN     (NNN  (NN)  NNN   (NNN       4NN)  (NNN     NNN
       (NNF    NNN) (NN)  NNN  (NNN__JNNN  NNNN___.(NNN__NNN)  NNNL_. NNNN____. `NNNL_NNN`     NNN
       NNN`    (NNN (NN)  NNN   4NNNNNNN`  `NNNNNN) NNNNNNNN)  (NNNN) `NNNNNNN)  `NNNNNN)      NNN
       """      """               """"`      `""""`  `""` ""`   `"""`    """""     """"        `" 
================================================================================================================ */
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract DDAOClaimAlloc01 is AccessControl
{
	using SafeMath for uint256;
	using SafeERC20 for IERC20;
	IERC20 public token;

	address public owner = _msgSender();
	mapping (address => uint256) claimers;
	mapping (address => uint256) public Sended;

	// testnet
	address public TokenAddr = 0x228845a7D11e6657B2F0934c5E31Aa99B376548D;
	// mainnet
	//address public TokenAddr = 0xc2132D05D31c914a87C6611C10748AEb04B58e8F;

	uint8 public ClaimCount;
	uint256 public ClaimedAmount;

	event textLog(address,uint256,uint256);

	constructor() 
	{
	_setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        claimers[0x871cAEF9d39e05f76A3F6A3Bb7690168f0188925] = 5710 * 10**6;    // 1    10000 / 4290 / 5710
        claimers[0x99CD484206f19A0341f06228BF501aBfee457b95] = 3710 * 10**6;    // 2    8000 / 4290 / 3710
        claimers[0x5dfCDA39199c47a962e39975C92D91E76d16a335] = 3110 * 10**6;    // 3    7400 / 4290 / 3110
        claimers[0x67C5A03d5769aDEe5fc232f2169aC5bf0bb7f18F] = 1716 * 10**6;    // 4    2010 / 294 / 1716
        claimers[0xda7B5C50874a82C0262b4eA6e6001E2b002829E9] = 710 * 10**6;     // 5    5000 / 4290 / 710
        claimers[0xBD0aa1CF9FB2af52d6E81ef95828B0F54baDf343] = 710 * 10**6;     // 6    5000 / 4290 / 710
        claimers[0x0026Ec57900Be57503Efda250328507156dAC982] = 710 * 10**6;     // 7    5000 / 4290 / 710
        claimers[0xa4885613eE8344E5745022b18BD4160AeD4d36db] = 709 * 10**6;     // 8    1003 / 294 / 709
        claimers[0x68cf193fFE134aD92C1DB0267d2062D01FEFDD06] = 706 * 10**6;     // 9    1000 / 294 / 706
        claimers[0x7A4Ad79C4EACe6db85a86a9Fa71EEBD9bbA17Af2] = 706 * 10**6;     // 10   1000 / 294 / 706
        claimers[0x96C7fcC0d3426714Bf62c4B508A0fBADb7A9B692] = 706 * 10**6;     // 11   1000 / 294 / 706
        claimers[0xA183B2f9d89367D935EC1Ebd1d33288a7113a971] = 706 * 10**6;     // 12   1000 / 294 / 706
        claimers[0xB83FC0c399e46b69e330f19baEB87B6832Ec890d] = 706 * 10**6;     // 13   1000 / 294 / 706
        claimers[0xa6700EA3f19830e2e8b35363c2978cb9D5630303] = 706 * 10**6;     // 14   1000 / 294 / 706
        claimers[0xb30ec70639a499af4B4040e2bE7385D44009af7f] = 706 * 10**6;     // 15   1000 / 294 / 706
        claimers[0xB6a95916221Abef28339594161cd154Bc650c515] = 706 * 10**6;     // 16   1000 / 294 / 706
        claimers[0x55fb5D5ae4A4F8369209fEf691587d40227166F6] = 706 * 10**6;     // 17   1000 / 294 / 706
        claimers[0xDE92728804683EC03EFAF6C293e428fc72C2ec95] = 706 * 10**6;     // 18   1000 / 294 / 706
        claimers[0xE40Cc4De1a57e83AAc249Bb4EF833B766f26e2F2] = 706 * 10**6;     // 19   1000 / 294 / 706
        claimers[0xF33782f1384a931A3e66650c3741FCC279a838fC] = 706 * 10**6;     // 20   1000 / 294 / 706
        claimers[0x5D10100d130467cf8DBE2B904100141F1a63318F] = 706 * 10**6;     // 21   1000 / 294 / 706
        claimers[0x8ad686fB89b2944B083C900ec5dDCd2bB02af1D0] = 706 * 10**6;     // 22   1000 / 294 / 706
        claimers[0x18668B0244949570ec637465BAFdDe4d082afa69] = 706 * 10**6;     // 23   1000 / 294 / 706
        claimers[0x184cfB6915daDb4536D397fEcfA4fD8A18823719] = 621 * 10**6;     // 24   915 / 294 / 621
        claimers[0x4D38C1D5f66EA0307be14017deC6A572017aCfE4] = 606 * 10**6;     // 25   900 / 294 / 606
        claimers[0x523bd9c190df614F1e98611793EaA8d1A0914B8B] = 506 * 10**6;     // 26   800 / 294 / 506
        claimers[0x9D1c7A6BF4258B77343f9212e2BaEB9538620911] = 418 * 10**6;     // 27   5000 / 4582 / 418
        claimers[0xa542e3CDd21841CcBcCA70017101eb6a2fc68723] = 417 * 10**6;     // 28   5000 / 4583 / 417
        claimers[0xE088efbff6aA52f679F76F33924C61F2D79FF8E2] = 406 * 10**6;     // 29   700 / 294 / 406
        claimers[0x2E5F97Ce8b95Ffb5B007DA1dD8fE0399679a6F23] = 406 * 10**6;     // 30   700 / 294 / 406
        claimers[0x4F80d10339CdA1EDc936e15E7066C1DBbd8Eb01F] = 383 * 10**6;     // 31   677 / 294 / 383
        claimers[0x42A6396437eBA7bFD6B5195B7134BE64443521ed] = 335 * 10**6;     // 32   629 / 294 / 335
        claimers[0x4460dD70a847481f63e015b689a9E226E8bD5b71] = 306 * 10**6;     // 33   600 / 294 / 306
        claimers[0x1d69159798e83d8eB39842367869D52be5EeD87d] = 306 * 10**6;     // 34   600 / 294 / 306
        claimers[0x81cee999e0cf2DA5b420a5c02649C894F69C86bD] = 306 * 10**6;     // 35   600 / 294 / 306
        claimers[0xdFA56E55811b6F9548F4cB876CC796a6A4071993] = 292 * 10**6;     // 36   586 / 294 / 292
        claimers[0xD05Da93aEa709abCc31979A63eC50F93c29999C4] = 231 * 10**6;     // 37   525 / 294 / 231
        claimers[0x2F275B5bAb3C35F1070eDF2328CB02080Cd62D7D] = 210 * 10**6;     // 38   504 / 294 / 210
        claimers[0xa66a4b8461e4786C265B7AbD1F5dfdb6e487f809] = 208 * 10**6;     // 39   501 / 293 / 208
        claimers[0xb14ae50038abBd0F5B38b93F4384e4aFE83b9350] = 207 * 10**6;     // 40   500 / 293 / 207
        claimers[0xC4b1bb0c1c8c29E234F1884b7787c7e14E1bC0a1] = 207 * 10**6;     // 41   500 / 293 / 207
        claimers[0x2FfF3F5b8560407781dFCb04a068D7635A179EFE] = 207 * 10**6;     // 42   500 / 293 / 207
        claimers[0xfB89fBaFE753873386D6E46dB066c47d8Ef857Fa] = 207 * 10**6;     // 43   500 / 293 / 207
        claimers[0x94d3B13745c23fB57a9634Db0b6e4f0d8b5a1053] = 207 * 10**6;     // 44   500 / 293 / 207
        claimers[0x46f75A3e9702d89E3E269361D9c1e4D2A9779044] = 207 * 10**6;     // 45   500 / 293 / 207
        claimers[0x7eE33a8939C6e08cfE207519e220456CB770b982] = 207 * 10**6;     // 46   500 / 293 / 207
        claimers[0x77724E749eFB937CE0a78e16E1f1ec5979Cba55a] = 207 * 10**6;     // 47   500 / 293 / 207
        claimers[0x7d2D2E04f1Db8B54746eFA719CB62F32A6C84a84] = 207 * 10**6;     // 48   500 / 293 / 207
        claimers[0x3a026dCc53A4bc80b4EdcC155550d444c4e0eBF8] = 207 * 10**6;     // 49   500 / 293 / 207
        claimers[0x585a003aA0b446C0F9baD7b3b0BAc5A809988588] = 207 * 10**6;     // 50   500 / 293 / 207
        claimers[0x390b07DC402DcFD54D5113C8f85d90329A0141ef] = 207 * 10**6;     // 51   500 / 293 / 207
        claimers[0x77167885E8393f1052A8cE8D5dfF2fF16c08f98d] = 207 * 10**6;     // 52   500 / 293 / 207
        claimers[0x498E96c727700a6B7aC2c4EfBd3E9a5DA4F0d137] = 111 * 10**6;     // 53   404 / 293 / 111
        claimers[0xb20Ce1911054DE1D77E1a66ec402fcB3d06c06c2] = 107 * 10**6;     // 54   400 / 293 / 107
        claimers[0xCDCaDF2195c1376f59808028eA21630B361Ba9b8] = 107 * 10**6;     // 55   400 / 293 / 107
        claimers[0x3ef7Bf350074EFDE3FD107ce38e652a10a5750f5] = 87 * 10**6;      // 56   380 / 293 / 87
        claimers[0x6592aB22faD2d91c01cCB4429F11022E2595C401] = 47 * 10**6;      // 57   340 / 293 / 47
        claimers[0xC03992cF3626321b81600a3457225f3f8A732837] = 46 * 10**6;      // 58   339 / 293 / 46
        claimers[0xcB60257f43Db2AE8f743c863d561528EedeaA409] = 40 * 10**6;      // 59   333 / 293 / 40
        claimers[0x5f3E1bf780cA86a7fFA3428ce571d4a6D531575D] = 38 * 10**6;      // 60   3000 / 2962 / 38
        claimers[0x3A79caC51e770a84E8Cb5155AAafAA9CaC83F429] = 38 * 10**6;      // 61   3000 / 2962 / 38
        claimers[0x2aE024C5EE8dA720b9A51F50D53a291aca37dEb1] = 37 * 10**6;      // 62   330 / 293 / 37
        claimers[0xF6d670C5C0B206f44E93dE811054F8C0b6e15905] = 26 * 10**6;      // 63   319 / 293 / 26
        claimers[0x2A716b58127BC4341231833E3A586582b07bBB22] = 17 * 10**6;      // 64   310 / 293 / 17
        claimers[0x330eC7c6AfC3cF19511Ad4041e598B235D44862f] = 8 * 10**6;       // 65   301 / 293 / 8
        claimers[0x23D623D3C6F334f55EF0DDF14FF0e05f1c88A76F] = 7 * 10**6;       // 66   300 / 293 / 7
        claimers[0xeD08e8D72D35428b28390B7334ebe7F9f7a64822] = 7 * 10**6;       // 67   300 / 293 / 7
        claimers[0x237b3c12D93885b65227094092013b2a792e92dd] = 7 * 10**6;       // 68   300 / 293 / 7
        claimers[0x57dA448673AfB7a06150Ab7a92c7572e7c75D2E5] = 7 * 10**6;       // 69   300 / 293 / 7
        claimers[0x65772909024899817Fb7333EC50e4B05534e3dB1] = 7 * 10**6;       // 70   300 / 293 / 7
        claimers[0xDfB78f8181A5e82e8931b0FAEBe22cC4F94CD788] = 7 * 10**6;       // 71   300 / 293 / 7
        claimers[0x1bdaA24527F033ABBe9Bc51b63C0F2a3e913485b] = 7 * 10**6;       // 72   300 / 293 / 7
        claimers[0x49e03A6C22602682B3Fbecc5B181F7649b1DB6Ad] = 7 * 10**6;       // 73   300 / 293 / 7
        claimers[0xF93b47482eCB4BB738A640eCbE0280549d83F562] = 7 * 10**6;       // 74   300 / 293 / 7
        claimers[0xD0929C7f44AB8cda86502baaf9961527fC856DDC] = 7 * 10**6;       // 75   300 / 293 / 7
        claimers[0x61603cD19B067B417284cf9fC94B3ebF5703824a] = 7 * 10**6;       // 76   300 / 293 / 7
        claimers[0xF7f341C7Cf5557536eBADDbe1A55dFf0a4981F51] = 7 * 10**6;       // 77   300 / 293 / 7
        claimers[0x687922176D1BbcBcdC295E121BcCaA45A1f40fCd] = 7 * 10**6;       // 78   300 / 293 / 7
        claimers[0xC64E4d5Ecda0b4D8d9255340c9E3B138c846F17F] = 7 * 10**6;       // 79   300 / 293 / 7
        claimers[0x76b2e65407e9f24cE944B62DB0c82e4b61850233] = 7 * 10**6;       // 80   300 / 293 / 7
        claimers[0x826121D2a47c9D6e71Fd4FED082CECCc8A5381b1] = 7 * 10**6;       // 81   300 / 293 / 7
        claimers[0x882bBB07991c5c2f65988fd077CdDF405FE5b56f] = 7 * 10**6;       // 82   300 / 293 / 7
        claimers[0x0c2262b636d91Ec5582f4F95b40988a56496B8f1] = 7 * 10**6;       // 83   300 / 293 / 7
        claimers[0x931ddC55Ea7074a190ded7429E82dfAdFeDC0269] = 7 * 10**6;       // 84   300 / 293 / 7
        claimers[0x9867EBde73BD54d2D7e55E28057A5Fe3bd2027b6] = 7 * 10**6;       // 85   300 / 293 / 7
        claimers[0xA0f31bF73eD86ab881d6E8f5Ae2E4Ec9E81f04Fc] = 7 * 10**6;       // 86   300 / 293 / 7
        claimers[0x2F48e68D0e507AF5a278130d375AA39f4966E452] = 7 * 10**6;       // 87   300 / 293 / 7
        claimers[0x6F255406306D6D78e97a29F7f249f6d2d85d9801] = 7 * 10**6;       // 88   300 / 293 / 7
        claimers[0xC60Eec28b22F3b7A70fCAB10A5a45Bf051a83d2B] = 7 * 10**6;       // 89   300 / 293 / 7
        claimers[0x6B745dEfEE931Ee790DFe5333446eF454c45D8Cf] = 7 * 10**6;       // 90   300 / 293 / 7
        claimers[0x2E72d671fa07be54ae9671f793895520268eF00E] = 7 * 10**6;       // 91   300 / 293 / 7
        claimers[0xB4264E181207E2e701f72331E0998c38e04c8512] = 7 * 10**6;       // 92   300 / 293 / 7
        claimers[0xb521154e8f8978f64567FE0FA7359Ab47f7363fA] = 7 * 10**6;       // 93   300 / 293 / 7
        claimers[0xb5C2Bc605CfE15d31554C6aD0B6e0844132BE3cb] = 7 * 10**6;       // 94   300 / 293 / 7
        claimers[0x2CE83785eD44961959bf5251e85af897Ba9ddAC7] = 7 * 10**6;       // 95   300 / 293 / 7
        claimers[0xbD0Ad704f38AfebbCb4BA891389938D4177A8A92] = 7 * 10**6;       // 96   300 / 293 / 7
        claimers[0xbF6077D70CAEDF2D36e914273be8e8D4B2c5adF1] = 7 * 10**6;       // 97   300 / 293 / 7
        claimers[0x093E088901909dEecC1b4a1479fBcCE1FBEd31E7] = 7 * 10**6;       // 98   300 / 293 / 7
        claimers[0x80C01D52e55e5e870C43652891fb44D1810b28A2] = 6 * 10**6;       // 99   6 / 0 / 6
	}

	// Start: Admin functions
	event adminModify(string txt, address addr);
	modifier onlyAdmin() 
	{
		require(IsAdmin(_msgSender()), "Access for Admin's only");
		_;
	}

	function IsAdmin(address account) public virtual view returns (bool)
	{
		return hasRole(DEFAULT_ADMIN_ROLE, account);
	}
	function AdminAdd(address account) public virtual onlyAdmin
	{
		require(!IsAdmin(account),'Account already ADMIN');
		grantRole(DEFAULT_ADMIN_ROLE, account);
		emit adminModify('Admin added',account);
	}
	function AdminDel(address account) public virtual onlyAdmin
	{
		require(IsAdmin(account),'Account not ADMIN');
		require(_msgSender()!=account,'You can`t remove yourself');
		revokeRole(DEFAULT_ADMIN_ROLE, account);
		emit adminModify('Admin deleted',account);
	}
	// End: Admin functions

	function TokenAddrSet(address addr)public virtual onlyAdmin
	{
		TokenAddr = addr;
	}

	function ClaimCheckEnable(address addr)public view returns(bool)
	{
		bool status = false;
		if(claimers[addr] > 0)status = true;
		return status;
	}
	function ClaimCheckAmount(address addr)public view returns(uint value)
	{
		value = claimers[addr];
	}
	function Claim(address addr)public virtual
	{
		//address addr;
		//addr = _msgSender();
		require(TokenAddr != address(0),"Admin not set TokenAddr");

		bool status = false;
		if(claimers[addr] > 0)status = true;

		require(status,"Token has already been requested or Wallet is not in the whitelist [check: Sended and claimers]");
		uint256 SendAmount;
		SendAmount = ClaimCheckAmount(addr);
		if(Sended[addr] > 0)SendAmount = SendAmount.sub(Sended[addr]);
		Sended[addr] = SendAmount;
		claimers[addr] = 0;

		IERC20 ierc20Token = IERC20(TokenAddr);
		require(SendAmount <= ierc20Token.balanceOf(address(this)),"Not enough tokens to receive");
		ierc20Token.safeTransfer(addr, SendAmount);

		ClaimCount++;
		ClaimedAmount = ClaimedAmount.add(SendAmount);
		emit textLog(addr,SendAmount,claimers[addr]);
	}
	
	function AdminGetCoin(uint256 amount) public onlyAdmin
	{
		payable(_msgSender()).transfer(amount);
	}

	function AdminGetToken(address tokenAddress, uint256 amount) public onlyAdmin 
	{
		IERC20 ierc20Token = IERC20(tokenAddress);
		ierc20Token.safeTransfer(_msgSender(), amount);
	}
	function balanceOf(address addr)public view returns(uint256 balance)
	{
		balance = claimers[addr];
	}
        function TokenBalance() public view returns(uint256)
        {
                IERC20 ierc20Token = IERC20(TokenAddr);
                return ierc20Token.balanceOf(address(this));
        }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
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

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

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
     * If the calling account had been granted `role`, emits a {RoleRevoked}
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

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../token/ERC20/extensions/IERC20Metadata.sol";

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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