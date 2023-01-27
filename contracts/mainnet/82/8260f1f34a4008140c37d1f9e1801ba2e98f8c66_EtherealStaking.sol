/*
"SPDX-License-Identifier: UNLICENSED"
*/
pragma solidity ^0.6.6;


import "./uniswap_interface.sol";
import "./safemath_contract.sol";

contract EtherealStaking 
{
    IERC20 usdt_token;
    IERC20 etl_token;

    using SafeMathX for uint256;
    address private marketingAddress;
    address private Default_Referral;
    address private liquidityAddress;
    address private pairedContract;
    address owner ;

    uint256 constant private PERCENTS_DIVIDER = 10000;
    uint256 constant private USDTMULT = 1000000;
    uint256 constant private ETLTMULT = 100000000;
    uint16[] private REFERRAL_PERCENTS = [0,300,200,100,50,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25];
    uint16[] private STAKE_TREAM = [200,400,600];
    uint16[] private STAKE_PER = [2600,3000,3200];
    uint16[] private DIRECT_PER = [800,1100,1500];
    uint256 private DaysSend=86400;
    uint16[5] private self_stake=[200,400,800,1200,1600];
    uint16[5] private direct_stake=[1000,2000,4000,6000,8000];
    uint24[5] private team_stake=[10000,20000,40000,60000,80000];
    uint256[5] private RankCounts=[0,0,0,0,0];
    uint256[5] private StakBonusx=[0,0,0,0,0];
    uint256 private ETLCurRate;
    uint256 private Total_ETL_Staking;
    uint256 private Total_USDT_Staking;
    uint256 private Total_Users;
    uint256 private Total_ETL_Supply;
    uint256 private Total_ETL_Balance;
    uint256 private USDT35RECIVED;
    uint256 private TUSDT_Deposit;

    uint256 private Total_ETL_Withdrawal;
    uint256 private Total_USDT_Withdrawal;
    uint256 private ReservedFund =0;
    uint256 private ReservedCycle =0;
    address [] private Global_Leaders;
    address [] private Team_Leaders;

    uint256 private TETLPS=0;
    uint256 private TUSDTB=0;
    uint256 private EliteCount=0;
    uint256 private globalStakCount=0;
    uint8 TeamLeaderPaid=0;
    event Registration (address indexed _regadd,address indexed _refadd,uint256 _usdt,uint256 _stakeDays, uint256 _regDate,uint256 _endDate);
    event Deposit (address indexed regadd,address indexed refadd,uint256 usdt,uint256 stakeDays,uint256 _startDate,uint256 _endDate);
    event WithdrawalUSDTEvent (address indexed regadd,uint256 usdt,uint256 _WithDate);
    event WithdrawalETLEvent (address indexed regadd,uint256 etl,uint256 _WithDate);
        
   
    struct User 
	{
        address myaddress;
		address referrer;
        uint256 regdt;
        uint256 User_TotalETL_Stak;
        uint256 User_TotalUSDT_Stak;
        uint256 Total_Directs;
        uint256 Directs_StakUSDT;
        uint256 Directs_StakETL;
        uint256 Total_Teams;
        uint256 Team_StakUSDT;
        uint256 Team_StakETL;
        uint8 isTeamLeader;
        uint256 Directs_Bonus;
        uint256 Level_Bonus;
        uint256 Global_Stak_Bonus;
        uint256 Elite_Pool_Bonus;
        uint256 Team_Leader_Bonus;
        uint256 Global_Leader_Bonus;
        uint256 USDT_Bonus_Withdrawal;
        uint256 ETL_Bonus_Withdrawal;
        uint8 GlobalStakRank;
        uint256 count;
        uint8 MaxLevel;
        mapping(uint256 => BuyStak) Package;
        mapping(uint256 => LevelBonus) levelTeam;

        
    }


    struct BuyStak 
	{
		uint256 buyETL;
        uint256 usdtAmt;
        uint256 etlUsdtRate;
        uint256 StakDays;
        uint256 CreditPer;
		uint256 start;
		uint256 enddt;
	}

    struct LevelBonus 
	{
        uint256 USDTStak;
        uint256 ETLStak;
        uint256 CommPer;
        uint256 LevelBonus;
        uint256 LevelSize;
	}

    struct GlobalStakPool 
	{
        address add;
	}

    struct ElitePool 
	{
        address addr;
        uint256 enddt;
   	}

   
    struct TeamLeaderPool 
	{
        address addr;
	}

    mapping (address => User)  users;
    mapping (uint256 => GlobalStakPool)  GlobalUsers;
    mapping (uint256 => TeamLeaderPool)  TeamLeaderPools;
   
    mapping (uint256 => ElitePool)  ElitePools;
  
    

    constructor(address _usdt_tokenAddr,address _etl_tokenAddr,uint256 _ETLCurRate, address payable _marketingAddr, address payable _LiquidityAddr,address _pairedContract) public 
	{
		require(!isContract(_marketingAddr) );
        usdt_token = IERC20(_usdt_tokenAddr);
        etl_token = IERC20(_etl_tokenAddr);
        ETLCurRate=_ETLCurRate;
		marketingAddress = _marketingAddr;
		liquidityAddress=_LiquidityAddr;
		owner=msg.sender;
        Default_Referral=0x0000000000000000000000000000000000000000;
        User storage user = users[msg.sender];
        user.myaddress=msg.sender;
        user.referrer=0x0000000000000000000000000000000000000000;
        user.regdt = block.timestamp;
        pairedContract=_pairedContract;
	}


   function getTokenPrice(address pairAddress, uint amount) public view returns(uint256)
   {
        IUniswapV2Pair pair = IUniswapV2Pair(pairAddress);
        //IERC20 token1 = IERC20(pair.token1());
        (uint Res0, uint Res1,) = pair.getReserves();
        uint256 res0 = Res0;  //*(10**token1.decimals());
        return((amount*Res1)/res0); // return amount of token0 needed to buy token1
   }
	
    function Staking (uint256 _usdt,uint256 _staking_days ) public payable
    {
        require(isUserIDExists(msg.sender),"This Address is not Registred" );
        address referAdd=users[msg.sender].referrer;
        Register(referAdd,_usdt,_staking_days );
    }
    
    
    function Register(address _referrer,uint256 _usdt,uint256 _staking_days ) public payable 
	{
        uint256 etltoken=0;
        require(_usdt<=usdt_token.balanceOf(msg.sender),"Please Check Balance in Your Wallet Address");
        ETLCurRate=getTokenPrice(pairedContract,100000000);
        
        etltoken = _usdt.div(ETLCurRate).mul(ETLTMULT);
        require(etltoken <(Total_ETL_Supply-TETLPS) ,"ETL Supply is low");
        require(_usdt >=25*USDTMULT ,"USDT Stak Value Should more then 25 USDT");
        require(isUserIDExists(_referrer),"Referral Address not found" );
        require(msg.sender!=_referrer,"Referral Address and Register Address will not be same" );
        require(_staking_days ==200 || _staking_days ==400 || _staking_days ==600, "Staking Terms Should be 200,400,or 600 days" );
        
      
       User storage user = users[msg.sender];
       
       uint8 isnew=0;
       
       usdt_token.transferFrom(msg.sender, address(this), _usdt.mul(3500).div(PERCENTS_DIVIDER));
       usdt_token.transferFrom(msg.sender, liquidityAddress, _usdt.mul(3500).div(PERCENTS_DIVIDER));
       usdt_token.transferFrom(msg.sender, marketingAddress, _usdt.mul(3000).div(PERCENTS_DIVIDER));
       
       USDT35RECIVED += _usdt.mul(3500).div(PERCENTS_DIVIDER);
       ReservedFund += _usdt.mul(500).div(PERCENTS_DIVIDER);
        uint8 SeqNo=0;
        if (_staking_days==200){
                    SeqNo=0;
            }
        if (_staking_days==400){
                    SeqNo=1;
            }
        if (_staking_days==600){
                    SeqNo=2;
            }  
        
        TETLPS += etltoken + etltoken.mul(STAKE_PER[SeqNo]).div(PERCENTS_DIVIDER);

        uint256 j=0;  
        if(!isUserIDExists(msg.sender))
        {
            
            user.myaddress=msg.sender;
            user.referrer=_referrer;
            user.regdt = block.timestamp;
            user.isTeamLeader=0;
            j=user.count+1;
            user.Package[j].buyETL = etltoken;
            user.Package[j].usdtAmt = _usdt;
            user.Package[j].etlUsdtRate = ETLCurRate;
            users[_referrer].Total_Directs += 1;
            user.GlobalStakRank=0;
            
            user.Package[j].start = block.timestamp;

            user.Package[j].enddt = block.timestamp.add(STAKE_TREAM[SeqNo]*(DaysSend));
            user.Package[j].StakDays = STAKE_TREAM[SeqNo]*(DaysSend);
            user.Package[j].CreditPer = STAKE_PER[SeqNo];
          

           // users[_referrer].directTeams[users[_referrer].Total_Directs].addr=msg.sender;
            user.count +=1;
            Total_Users += 1;
            isnew=1;
            emit  Registration (msg.sender,_referrer,_usdt,_staking_days,block.timestamp,block.timestamp.add(STAKE_TREAM[SeqNo]*(DaysSend)));

        }
        else 
        {
           
            j = users[msg.sender].count+1;

            users[msg.sender].Package[j].buyETL = etltoken;
            users[msg.sender].Package[j].usdtAmt = _usdt;
            users[msg.sender].Package[j].etlUsdtRate = ETLCurRate;
            users[msg.sender].Package[j].start = block.timestamp;
            users[msg.sender].Package[j].enddt = block.timestamp.add(STAKE_TREAM[SeqNo]*(DaysSend));
            users[msg.sender].Package[j].StakDays = STAKE_TREAM[SeqNo]*(DaysSend);
            users[msg.sender].Package[j].CreditPer = STAKE_PER[SeqNo];
      
            users[msg.sender].count +=1;
            isnew=0;


        }
        
        emit Deposit (msg.sender,_referrer,_usdt,_staking_days,block.timestamp,block.timestamp.add(STAKE_TREAM[SeqNo]*(DaysSend)));
        users[_referrer].Directs_Bonus +=_usdt.mul(DIRECT_PER[SeqNo]).div(PERCENTS_DIVIDER);
        
        TUSDTB+=_usdt.mul(DIRECT_PER[SeqNo]).div(PERCENTS_DIVIDER);
        Total_ETL_Staking += etltoken;
        Total_USDT_Staking +=_usdt;

        users[_referrer].Directs_StakUSDT += _usdt;
        users[_referrer].Directs_StakETL += etltoken;
        users[msg.sender].User_TotalUSDT_Stak += _usdt;
        users[msg.sender].User_TotalETL_Stak += etltoken;     // Total Staking ETL  
        
        //----------------------------------------------------------
        updateGlobalShareBonus();

        updateGlobalStakShare(msg.sender);
        //-----------------------------------------------------------
        
		uint256 TeamLeaderfund=0;
        TeamLeaderfund=(_usdt.mul(500).div(PERCENTS_DIVIDER));

       
        
        uint8 i=0;
        address upline;
        upline = _referrer;
        TeamLeaderPaid=0;
		while (upline!=Default_Referral) 
		{
            
            if(i<25)
            {
                if(isnew==1 && i>=users[upline].MaxLevel ) 
                { users[upline].MaxLevel=i;}                
                if(isnew==1 )
                {
                    users[upline].levelTeam[i].LevelSize +=1;
                    users[upline].Total_Teams +=1;
                 }
                
                users[upline].levelTeam[i].USDTStak += _usdt;
                users[upline].levelTeam[i].ETLStak += etltoken;
                users[upline].levelTeam[i].CommPer = REFERRAL_PERCENTS[i];
                users[upline].levelTeam[i].LevelBonus += _usdt.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);
                TUSDTB+=_usdt.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);
                users[upline].Level_Bonus +=_usdt.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);
                
               
                users[upline].Team_StakUSDT +=_usdt;
                users[upline].Team_StakETL += etltoken;

            }
            
            if(users[upline].isTeamLeader==1 && TeamLeaderPaid==0)
            {
                 users[upline].Team_Leader_Bonus += TeamLeaderfund;
                 TUSDTB+=TeamLeaderfund;
                 TeamLeaderPaid=1;
                 
            }

            updateGlobalStakShare(upline);
            upline = users[upline].referrer;

            i=i+1;
        }
       
        updateGlobalLeaderBonus(_usdt);
        updateEliteBonus(_usdt);
         
        if(_usdt>=5000*USDTMULT && _staking_days>=400)
        {
             EliteCount=EliteCount+1;
             ElitePool storage elitepoolx = ElitePools[EliteCount];
             elitepoolx.addr = msg.sender;
             elitepoolx.enddt= STAKE_TREAM[SeqNo]*(DaysSend);
            
        }
      

    }

    
    
    function updateGlobalLeaderBonus(uint256 _usdt) internal
    {

        uint256 GlobalLeaderfund=0;

        if(Global_Leaders.length>0)
        { 
            GlobalLeaderfund = (_usdt.mul(500).div(PERCENTS_DIVIDER)).div(Global_Leaders.length);

        }

       

        for(uint256 m=0;m<Global_Leaders.length;m++)
        {
            users[Global_Leaders[m]].Global_Leader_Bonus += GlobalLeaderfund;
            TUSDTB+=GlobalLeaderfund;
        }

        
    }


    function updateEliteBonus(uint256 _usdt) internal
    {
        uint256 EliteFund=0;
        if(EliteCount>0)
        {
            EliteFund= _usdt.mul(300).div(PERCENTS_DIVIDER).div(EliteCount);
        }
        uint256 k=0;
        while (k<= EliteCount) 
        {
            if (ElitePools[k].enddt <= block.timestamp)
            {
                users[ElitePools[k].addr].Elite_Pool_Bonus += EliteFund;
                TUSDTB+=EliteFund;
            }
            k=k+1;
        }
    }


    function updateGlobalShareBonus() internal
    {   
       StakBonusx[0]=0;
       StakBonusx[1]=0;
       StakBonusx[2]=0;
       StakBonusx[3]=0;
       StakBonusx[4]=0;

        if(ReservedFund>=50*USDTMULT)
        {
            for (uint8 i=0;i<=4;i++)
            {
                if(RankCounts[i]>0) 
                {  
                    StakBonusx[i]=ReservedFund.div(5).div(RankCounts[i]);    
                }
            }
      
            for (uint256 n=1;n<=globalStakCount;n++)
            {
                for (uint8 j=0;j<=4;j++ )
                {
                    if(users[GlobalUsers[n].add].GlobalStakRank==j+1)
                    {
                        users[GlobalUsers[n].add].Global_Stak_Bonus += StakBonusx[j];
                        TUSDTB+=StakBonusx[j];
                    }
                }
        
            }
            ReservedCycle+=1;
            ReservedFund=0;

         }
    }

    function updateGlobalStakShare(address addr) internal
    {
        
         for (uint8 j=0;j<5;j++)
         {      
             if(users[addr].GlobalStakRank<j+1)
             {
                if(users[addr].User_TotalUSDT_Stak>=self_stake[j]*USDTMULT &&  users[addr].Directs_StakUSDT>=direct_stake[j]*USDTMULT && users[addr].Team_StakUSDT>=team_stake[j]*USDTMULT)
                {
                            RankCounts[j]+=1;
                           
                            
                            if(j>0)
                            {
                                RankCounts[j-1]=RankCounts[j-1]-1;
                            }
                            
                            if (users[addr].GlobalStakRank==0)
                            {
                               globalStakCount = globalStakCount+1;
                               GlobalStakPool storage globalusersx=GlobalUsers[globalStakCount];
                               globalusersx.add=addr;
                               
                            }

                             users[addr].GlobalStakRank=j+1;
                }
            }
         }


    }
    //--------------------------ROI Function
    function getUserETLBonus(address userAddress) public view returns (uint256) {
				      
		uint256 totalDividends=0;
		uint256 dividends;
		uint256 curdate;
	  
         User storage userx = users[userAddress];

        for (uint16 i=1; i<=userx.count;i++)
        {
            dividends=0;
            if (userx.Package[i].usdtAmt>0)
            {
      
                if(userx.Package[i].enddt>= block.timestamp)
                {
                    curdate=block.timestamp;
                }
                else
                {
                    curdate=userx.Package[i].enddt;
                }
                
				
				dividends = (userx.Package[i].buyETL.mul(userx.Package[i].CreditPer).div(PERCENTS_DIVIDER))
				.mul(curdate.sub(userx.Package[i].start)).div(userx.Package[i].StakDays);

                if(userx.Package[i].enddt<=curdate)
                {
                    dividends = dividends.add(userx.Package[i].buyETL);
                }
          
				totalDividends = totalDividends.add(dividends);

            }
            }

		return totalDividends;
	}

  


   

   function getUsersPersonalDetails(address myadd) public view returns (address _selfadd,address _refAdd,uint256 _selfStakETL,uint256 _selfStakUSDT,uint256 _usdtwith,uint256 _ethwith,uint8 _GlobalStakRank)
   {
       User storage u = users[myadd];
       return (u.myaddress,u.referrer,u.User_TotalETL_Stak,u.User_TotalUSDT_Stak,u.USDT_Bonus_Withdrawal,u.ETL_Bonus_Withdrawal,u.GlobalStakRank);
   }

   function getGlobalSharingTeamDtl() public view returns (uint256 _ReservedCycle,uint256 _ReservedFund,uint256 _SilverCount,uint256 _GoldCount,uint256 _PlatinumCount,uint256 _DiamondCount,uint256 _CrownCount)
   {
      return (ReservedCycle,ReservedFund,RankCounts[0],RankCounts[1],RankCounts[2],RankCounts[3],RankCounts[4]);
   }
  
  
   function getUsersTeamLevelDtl(address myadd) public view returns (uint256[] memory _USDTStak1, uint256[] memory _ETLStak1,uint256[] memory _CommPer1,uint256[] memory _LevelBonus1,uint256[] memory _LevelSize1)
   {
       require(isUserIDExists(myadd),"Address not Register" );
        address addr=myadd;
        uint8 k=users[addr].MaxLevel;
        uint256 [] memory USDTStak1= new uint256[](k);
        uint256 [] memory  ETLStak1= new uint256[](k);
        uint256 [] memory CommPer1= new uint256[](k);
        uint256 [] memory LevelBonus1= new uint256[](k);
        uint256 [] memory LevelSize1= new uint256[](k);
        
        
         
       for (uint8 i=1;i<=k;i++)
       {
           USDTStak1[i-1]=users[addr].levelTeam[i].USDTStak ;
           ETLStak1[i-1]=users[addr].levelTeam[i].ETLStak ;
           CommPer1[i-1]=users[addr].levelTeam[i].CommPer ;
           LevelBonus1[i-1]=users[addr].levelTeam[i].LevelBonus ;
           LevelSize1[i-1]=users[addr].levelTeam[i].LevelSize ;
           
       }
        
       return (USDTStak1,ETLStak1,CommPer1,LevelBonus1,LevelSize1 );
   }


   function getUsersStakDtl(address myadd) public view returns (uint256[] memory _buyETL, uint256[] memory _usdtAmt,uint256[] memory _etlUsdtRate,uint256[] memory _StakDays,uint256[] memory _CreditPer,uint256[] memory _start,uint256[] memory _enddt)
   {
       require(isUserIDExists(myadd),"Address not Register" );
       address addr=myadd;
       uint256 k=users[addr].count;
        uint256 [] memory buyETL = new uint256[](k);
        uint256 [] memory  usdtAmt= new uint256[](k);
        uint256 [] memory etlUsdtRate= new uint256[](k);
        uint256 [] memory StakDays= new uint256[](k);
        uint256 [] memory CreditPer= new uint256[](k);
		uint256 [] memory start= new uint256[](k);
		uint256 [] memory enddt= new uint256[](k);
        
       for (uint256 i=1;i<=users[addr].count;i++)
       {
           buyETL[i-1]=users[addr].Package[i].buyETL ;
           usdtAmt[i-1]=users[addr].Package[i].usdtAmt ;
           etlUsdtRate[i-1]=users[addr].Package[i].etlUsdtRate ;
           StakDays[i-1]=users[addr].Package[i].StakDays ;
           CreditPer[i-1]=users[addr].Package[i].CreditPer ;
           start[i-1]=users[addr].Package[i].start ;
           enddt[i-1]=users[addr].Package[i].enddt ;
       }
        
       return (buyETL,usdtAmt,etlUsdtRate,StakDays,CreditPer,start,enddt);
   }

   
   
//---------------------admin function--------------------------
    function AddTeamLeaderPool(address Addr) external 
	{
        require(owner==msg.sender,"Only Owner can do" );
        require(isUserIDExists(Addr),"Address not Register" );
        Team_Leaders.push(Addr);
        users[Addr].isTeamLeader=1;
    }

    function DeleteTeamLeaderPool(uint256 k) external 
	{
        require(owner==msg.sender,"Only Owner can do" );
        require(isUserIDExists(Team_Leaders[k]),"Address not Register" );
        users[Team_Leaders[k]].isTeamLeader=0;
       
        Team_Leaders[k] = Team_Leaders[Team_Leaders.length - 1];
        Team_Leaders.pop();

   
    }

     function AddGlobalLeaderPool(address Addr) external 
	{
        require(owner==msg.sender,"Only Owner can do" );
        require(isUserIDExists(Addr),"Address not Register" );
        Global_Leaders.push(Addr);
        

    }

      function DeleteGlobalLeaderPool(uint256 k) external 
	{
        require(owner==msg.sender,"Only Owner can do" );
        require(isUserIDExists(Global_Leaders[k]),"Address not Register" );
        Global_Leaders[k] = Global_Leaders[Global_Leaders.length - 1];
        Global_Leaders.pop();
        
    }

    function DepositEthereal(uint256 _etlToken) external  
	{
        require(owner==msg.sender,"Only Owner can do" );
         require(_etlToken<etl_token.balanceOf(msg.sender),"Please Check Balance in Your Wallet Address");
        Total_ETL_Supply +=_etlToken;
        Total_ETL_Balance += _etlToken;
        etl_token.transferFrom(msg.sender, address(this), _etlToken);
        
    }
    function DepositUSDT(uint256 _USDTToken) external 
	{
        require(owner==msg.sender,"Only Owner can do" );
        require(_USDTToken<usdt_token.balanceOf(msg.sender),"Please Check Balance in Your Wallet Address");
        TUSDT_Deposit+=_USDTToken;
        usdt_token.transferFrom(msg.sender, address(this), _USDTToken);
        
    }

    function getEliteList() public view returns (address[] memory _eliteAddrs)
     {

       //require(owner==msg.sender,"Only Owner can view" );
       address [] memory eliteAddrs= new address[](EliteCount);
       for (uint256 i=1;i<=EliteCount;i++)
       {
           eliteAddrs[i]= ElitePools[i].addr ;
       }
        
       return (eliteAddrs );

   }

   
    function getTeamLeaderList() public view returns (address[] memory _eliteAddrs)
     {
      
       return (Team_Leaders );

   }

   function getGlobalTeamLeaderList() public view returns (address[] memory _eliteAddrs)
   {
      
      return (Global_Leaders);

   }



    //-------------------------get user function------------------------------------------------------
    function WithdrawalEthereal() external 
	{
         require(isUserIDExists(msg.sender),"Address not Register" );
         uint256 bal=getUsersWithBalETL(msg.sender);
         etl_token.transfer(msg.sender,bal);
         Total_ETL_Balance = Total_ETL_Balance-bal;
         Total_ETL_Withdrawal+=bal;
         users[msg.sender].ETL_Bonus_Withdrawal +=bal;
                
        emit WithdrawalETLEvent (msg.sender,bal,block.timestamp);


       
    }


    function WithdrawalUSDT() external 
	{
         require(isUserIDExists(msg.sender),"Address not Register" );
         uint256 balusdt=getUsersWithBalUSDT(msg.sender);
         usdt_token.transfer(msg.sender,balusdt);
         users[msg.sender].USDT_Bonus_Withdrawal+=balusdt;
         Total_USDT_Withdrawal+=balusdt;
        
       emit WithdrawalUSDTEvent (msg.sender,balusdt,block.timestamp);
    }


    function getUsersWithBalUSDT(address myadd) public view returns (uint256)
   {
       require(isUserIDExists(myadd),"Address not Register" );
       uint256 WithdrawaAble;
       WithdrawaAble= users[myadd].Directs_Bonus+users[myadd].Level_Bonus+users[myadd].Global_Stak_Bonus+users[myadd].Elite_Pool_Bonus+users[myadd].Team_Leader_Bonus+users[myadd].Global_Leader_Bonus- users[myadd].USDT_Bonus_Withdrawal;
       return WithdrawaAble;
   }

   function getUsersWithBalETL(address myadd) public view returns (uint256)
   {
       require(isUserIDExists(myadd),"Address not Register" );
       uint256 WithdrawaAble;
       WithdrawaAble=getUserETLBonus(myadd)-users[myadd].ETL_Bonus_Withdrawal;
       
       return WithdrawaAble;
   }

    
    function getUsersTeamDetails(address myadd) public view returns (uint256 _totalDirects,uint256 _totalDirectBV,uint256 _totalDirectETL,uint256 _totalTeams,uint256 _totalTeamBV,uint256 _totalTeamETL) {
          
		return (users[myadd].Total_Directs,users[myadd].Directs_StakUSDT,users[myadd].Directs_StakETL,users[myadd].Total_Teams,users[myadd].Team_StakUSDT,users[myadd].Team_StakETL);
	}

   

    function getUserUSDTBonusDetails(address myadd) public view returns (uint256 _Directs_Bonus,uint256 _Level_Bonus,uint256 _Global_Stak_Bonus,uint256 _Elite_Pool_Bonus,uint256 _Team_Leader_Bonus,uint256 _Global_Leader_Bonus,uint256 _TotalUSDTBonus) {
        
        uint256 totalUSDTBonus = users[myadd].Directs_Bonus+users[myadd].Level_Bonus+users[myadd].Global_Stak_Bonus+users[myadd].Elite_Pool_Bonus+users[myadd].Team_Leader_Bonus+users[myadd].Global_Leader_Bonus;
		return (users[myadd].Directs_Bonus,users[myadd].Level_Bonus,users[myadd].Global_Stak_Bonus,users[myadd].Elite_Pool_Bonus,users[myadd].Team_Leader_Bonus,users[myadd].Global_Leader_Bonus,totalUSDTBonus);
	}



    //----------------Contract Global Function-----------------------------------------
     function getETLUsdtRate() public view returns (uint256) {
		uint256 r=getTokenPrice(pairedContract,100000000);
        if (r<50000)
        {
            r=50000;
        }
        return r;
	}

    function getContractDetails() public view returns (uint256 _Bal_ETL_Supply,uint256 _Total_ETL_Balance,uint256 _ETLCurRate,uint256 _Total_ETL_Staking,uint256 _Total_USDT_Staking,uint256 _Total_ETL_Withdrawal,uint256 _Total_USDT_Withdrawal,uint256 _Total_Users) {
		return ((Total_ETL_Supply-Total_ETL_Staking),Total_ETL_Balance,ETLCurRate,Total_ETL_Staking,Total_USDT_Staking,Total_ETL_Withdrawal,Total_USDT_Withdrawal,Total_Users);
	}
    function getContractBalance() public view returns (uint256 b1,uint256 b2,uint256 b3,uint256 b4,uint256 b5,uint256 b6,uint256 b7)
    {
        
        return (Total_ETL_Supply,TETLPS,usdt_token.balanceOf(address(this)),TUSDTB,etl_token.balanceOf(address(this)),TUSDT_Deposit,USDT35RECIVED); 
    }

    function setLiquidityContract(address liqAdd) external  
    {
        require(owner==msg.sender,"Only Owner can do" ); 
            pairedContract=liqAdd;
    }
    function updateOwner(address ownAdd) external 
    {
        require(owner==msg.sender,"Only Owner can do" ); 
        owner=ownAdd;
    }
   //----------------------validate function---------------------------------------------------------------
    function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }

    
    function isUserIDExists(address _useraddress) public view returns (bool) 
    {
        if(users[_useraddress].myaddress==address(0))
        {
            return false;    
        }
        else
        {
            return true; 
        }
        
    }

}