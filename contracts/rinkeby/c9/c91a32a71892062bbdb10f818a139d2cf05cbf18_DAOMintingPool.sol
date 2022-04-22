// SPDX-License-Identifier: MIT

pragma solidity ^0.7.3;
pragma experimental ABIEncoderV2;

import "./Ownable.sol";
import './IERC20.sol';
import './SafeMath.sol';
import "./SafeERC20.sol";
import "./Context.sol";

/*
*minting pool
*/
  contract DAOMintingPool is Ownable {
    using SafeERC20 for     IERC20;
    using SafeMath  for     uint256;
    address     public      LSPXContract;
    uint256     public      baseNumner = 1e18;
    address     public      monetaryPolicy;
    uint256     private     calculatestakingAmount;
    uint256     private     mintingPoolTypeSize;


   constructor() {
        initializeOwner();
        monetaryPolicy = msg.sender;
        mintingPoolTypeSize = 0;        //多少中类型的矿池
        calculatestakingAmount = 0;     //参与运算的矿池抵押总量
    }
    
    struct minerInfo{
        uint256         timestamps;
        address         lpToken;         
        uint256         amount;          
        uint256         veDao;     
    }    
    struct BonusTokenInfo {
        uint256         timestamps;
        string          name;
        address         bonusAddr;                
        uint256         totalBonus;                        
        uint256         lastBonus;
        uint256         accBonusPerShare;            
        uint256         expirationTimestamps;
        uint256         lastRewardTime;              
        uint256         daoPerBlock;
        uint256         startTime;
        uint256         updatePoolTime;
        uint256         passBonus;
    }
    struct mintingPoolInfo{
        uint256         timestamps;
        uint256         poolTypeId;
        address         lpToken;
        string          lpTokensymbol;
        uint256         stakingTotal;
        uint256         multiple;           //DAO的倍数,带4位小数
    }
    //定义矿池类型
    struct mintingPoolType{
        uint256         timestamps;
        uint256         id;
        bool            bstatus;        //状态
        uint256         poolLength;     //长度 7天，1月    
        uint256         weight;         //权重 放大1000倍， 1000  如：1周 0.5%=5;1月：2% = 20
    }

    mapping (address=>bool) bonusStatus;    //奖励币地址
    address [] bonusList;                   //奖励币列表
    

    mapping(address => mapping(address=>uint256) ) userBonus;
    mapping(address => mapping(address=>uint256) ) userRewardDebt;
    
    mapping(uint256 => mintingPoolType) mintingPoolTypeList;
    

    mapping(address => mapping(address => mapping(uint256 => minerInfo))) miner;
   

    mapping(address => BonusTokenInfo) BonusToken;
    mapping (address => mapping(uint256 =>mintingPoolInfo )) mintingPool;
    mintingPoolInfo [] listmintingPool;

    mapping(address=>uint256) userTotalVeDao;
    mapping(address=>mapping(address=>uint256)) userTotalDao;

    mapping(address => uint256) poolStakingTotal;
    
    mapping(address => mintingPoolInfo [] ) minerPoolList;

    event AddBonusToken(address who,IERC20 token,uint256 amount);
    event SubBonusToken(address who,IERC20 token,uint256 amount);
    event AddmintingPool(address who,address lpToken,uint256 pollTypeId);
    event Deposit(address who,address lpToken,uint256 amount);
    event WithdrawBonus(address who,address lpToken ,address bounsToken, uint256 bonus);
    event Withdraw(address who,address lpToken,uint256 amount );
    event LogMonetaryPolicyUpdated(address policy);
    
    function getuserBonus(address who,address bsToken) public view returns(uint256){
        return userBonus[who][bsToken];
    }
    function getuserRewardDebt(address who,address bsToken) public view returns(uint256){
        return userRewardDebt[who][bsToken];
    }
    /**
    获取矿池总抵押的veDao
     */
    function getcalculatestakingAmount() public view returns(uint256){
        return calculatestakingAmount;
    }
    /**
    获取用户抵押的VeDao
     */
    function getuserTotalVeDao(address who) public view returns(uint256) {
        require(who!= address(0));
        return userTotalVeDao[who];
    }
    /**
    获取用户抵押的
     */
    function getuserTotalDao(address who,address lpToken) public view returns(uint256){
        require(who != address(0));
        require(lpToken != address(0));
        return userTotalDao[msg.sender][lpToken] ;
    }
    /**
    获取矿池总抵押dao
     */
    function getpoolStakingTotal(address lpToken) public view returns(uint256){
        require(lpToken != address(0));
        return poolStakingTotal[lpToken];
    }
    /**
    获取奖金币数量
     */
    function getbonusListlenght() public view returns(uint256){
        return bonusList.length;
    }
    /**
    获取奖金币地址
     */
    function getbonusListAddr(uint256 index) public view returns(address){
        require(index >=0 );
        require(index < bonusList.length);
        return bonusList[index];
    }
    function checkpooltype(uint256 poolLength) private view returns(bool){
        bool bcheck = false;
        if( mintingPoolTypeSize == 0 ){
            return bcheck;
        }
        for(uint256 i=0;i<mintingPoolTypeSize;i++){
           if( mintingPoolTypeList[mintingPoolTypeSize-1].poolLength == poolLength  ){
               bcheck = true;
           }
        }
        return bcheck;
    }
    /** 
    新增矿池类型
    */
    function addmintingPoolType(uint256 poolLength,uint256 weight) public onlyOwner returns(bool){
        require(poolLength >=0);
        require(weight >= 0);
        require(checkpooltype(poolLength) == false,"poolLength duplicate"  ); //矿池 重复

        mintingPoolType memory newmintingPoolType = mintingPoolType({
            timestamps:         block.timestamp,
            id:                 mintingPoolTypeSize,
            bstatus:            true,
            poolLength:         poolLength,
            weight:             weight
        });
        mintingPoolTypeList[mintingPoolTypeSize] = newmintingPoolType;
        mintingPoolTypeSize ++;
        return true;
    }
    /**
    获取矿池数量
     */
    function getmintingPoolTypeSize() public view returns(uint256){
        return mintingPoolTypeSize;
    }
    /**
    获取矿池类型信息
     */
    function getmintingPoolType(uint256 id) public view returns(mintingPoolType memory){
        require(id>=0);
        require(mintingPoolTypeList[id].bstatus);
        return mintingPoolTypeList[id];    

    }
    /**
    设定矿池类型信息
    poolLength：长度 7天，1月    
    weight：权重
     */
    function setmintingPoolType(uint256 id,uint256 poolLength,uint256 weight ) public onlyOwner returns(mintingPoolType memory){
        require(id >= 0);
        require(mintingPoolTypeList[id].bstatus);
        mintingPoolTypeList[id].poolLength = poolLength;
        mintingPoolTypeList[id].weight = weight;
        return mintingPoolTypeList[id];
    } 
    modifier onlyMonetaryPolicy() {
        require(msg.sender == monetaryPolicy);
        _;
    }
    /**
     * @param monetaryPolicy_ The address of the monetary policy contract to use for authentication.
     */
    function setMonetaryPolicy(address monetaryPolicy_)
        external
        onlyOwner
    {
        monetaryPolicy = monetaryPolicy_;
        emit LogMonetaryPolicyUpdated(monetaryPolicy_);
    }
 
    /**
    获取用户抵押的矿池数量
     */
    function getminerPoolList(address who) public view returns(uint256){
        require(who != address(0));
        return minerPoolList[who].length;
    }
    /**
    获取用户抵押的矿池内容
     */
    function getminerPoolListData(address who,uint256 index) public view returns( mintingPoolInfo memory ){
        require( who != address(0) );
        require(index < minerPoolList[who].length );
        return minerPoolList[who][index];
    }
 
    function getlistmintingPool() public view returns(uint){
        return listmintingPool.length;
    }
    function getlistmintingPooldata(uint index) public view returns(mintingPoolInfo memory){
        require(index < listmintingPool.length);
        return listmintingPool[index];
    }
    function getBonusToken(address lpToken) public view returns(BonusTokenInfo memory){
        require(lpToken != address(0));
        return BonusToken[lpToken];
    }
    function getminerInfo(address who,address lpToken,uint256 pollTypeId ) public view returns(minerInfo memory){
        require(who != address(0));
        return miner[who][lpToken][pollTypeId];
    }
    /**
    multiple：矿池出矿是DAO的倍数，DAO 默认 1，Lp x*DAO
    poolTypeId:矿池ID
    新建矿池
     */
    function addmintingPool(address lpToken,uint256 multiple,uint256 poolTypeId) public payable onlyMonetaryPolicy returns(bool){
        require(lpToken != address(0));
        require(mintingPool[lpToken][poolTypeId].lpToken == address(0));

        mintingPoolInfo memory newmintingPoolInfo = mintingPoolInfo({
            timestamps:         block.timestamp,
            poolTypeId:         poolTypeId,
            lpToken:            lpToken,
            lpTokensymbol:      IERC20(lpToken).symbol(),
            stakingTotal:       0,
            multiple:           multiple
        });
        mintingPool[lpToken][poolTypeId] = newmintingPoolInfo;

        listmintingPool.push(newmintingPoolInfo);

        emit AddmintingPool(msg.sender,lpToken,poolTypeId);
        return true;
    }
    //bsToken ，收益币
    function addBonusToken(string memory name, address bsToken,uint256 amount,uint256 expirationTimestamps) public   onlyMonetaryPolicy returns(bool){
 
        require(bsToken != address(0));
        require(amount >0);
        require(block.timestamp < expirationTimestamps );
        // if(mintingPool[bsToken].bsToken == address(0)){
        //     addmintingPool( bsToken );
        // }
        if( bonusStatus[bsToken]==false ){
            bonusStatus[bsToken] = true;
            bonusList.push( bsToken );
        } 
        updateBonusShare(bsToken);
        uint256 daoPerBlock;
        uint256 passBonus;
        uint256 startTime = BonusToken[bsToken].startTime == 0 ? block.timestamp:BonusToken[bsToken].startTime;
        uint256 lastRewardTime = BonusToken[bsToken].lastRewardTime == 0 ? block.timestamp:BonusToken[bsToken].lastRewardTime;

        if( BonusToken[bsToken].totalBonus != 0 ){
            require( expirationTimestamps >= BonusToken[bsToken].expirationTimestamps );
            name = BonusToken[bsToken].name;
            if( BonusToken[bsToken].expirationTimestamps > block.timestamp ){
                passBonus = BonusToken[bsToken].daoPerBlock.mul(block.timestamp.sub(BonusToken[bsToken].updatePoolTime)); 
                BonusToken[bsToken].passBonus = passBonus.add(BonusToken[bsToken].passBonus); 
            } 
            else{  
                BonusToken[bsToken].passBonus = BonusToken[bsToken].totalBonus;
            }
            passBonus = BonusToken[bsToken].passBonus;
            daoPerBlock = (amount.add(BonusToken[bsToken].totalBonus).sub(passBonus)).div(expirationTimestamps.sub(block.timestamp));
        }
        else{
            daoPerBlock = amount.div(expirationTimestamps.sub(startTime)); 
            passBonus = 0;
        }
        BonusTokenInfo memory newBonusTokenInfo = BonusTokenInfo({
            timestamps:                 block.timestamp,
            name:                       name,
            bonusAddr:                  address(bsToken),
            totalBonus:                 amount.add(BonusToken[bsToken].totalBonus),
            lastBonus:                  amount.add(BonusToken[bsToken].lastBonus),
            accBonusPerShare:           BonusToken[bsToken].accBonusPerShare,
            expirationTimestamps:       expirationTimestamps,
            lastRewardTime:             lastRewardTime,
            daoPerBlock:                daoPerBlock,
            startTime:                  startTime,
            updatePoolTime:             block.timestamp,
            passBonus:                  passBonus
        });
        BonusToken[bsToken] = newBonusTokenInfo;
        IERC20(bsToken).safeTransferFrom(msg.sender, address(this), amount);
        emit AddBonusToken(msg.sender,IERC20(bsToken),amount);
        return true;
    }
    function updateBonusShare(address bsToken) private{        
        uint256 lpSupply = calculatestakingAmount;  //获取计算矿池总量
        if(lpSupply == 0){
            return;
        } 
        uint256 spacingTime = getspacingTime(bsToken);  
        uint256 DAOReward = spacingTime.mul(BonusToken[bsToken].daoPerBlock).mul(1e18).div(lpSupply);  
        BonusToken[bsToken].accBonusPerShare = DAOReward.add(BonusToken[bsToken].accBonusPerShare); 
     
        BonusToken[bsToken].lastRewardTime = block.timestamp;  
    }
    function subBonusToken(address bsToken,uint256 amount) public   onlyMonetaryPolicy returns(bool){
        require(bsToken != address(0));
        require(amount >0);  
        require(block.timestamp < BonusToken[bsToken].expirationTimestamps);
        updateBonusShare(bsToken);
        uint256 passBonus;
        if( BonusToken[bsToken].expirationTimestamps > block.timestamp ){  
            passBonus = BonusToken[bsToken].daoPerBlock.mul(block.timestamp.sub(BonusToken[bsToken].updatePoolTime));
            BonusToken[bsToken].passBonus = passBonus.add(BonusToken[bsToken].passBonus);  
        }
        else{
            BonusToken[bsToken].passBonus = BonusToken[bsToken].totalBonus;
        }
        passBonus = BonusToken[bsToken].passBonus;
        require( BonusToken[bsToken].totalBonus.sub(passBonus) >= amount  );
        BonusToken[bsToken].timestamps = block.timestamp; 
        BonusToken[bsToken].totalBonus = BonusToken[bsToken].totalBonus.sub(amount);
        BonusToken[bsToken].lastBonus = BonusToken[bsToken].lastBonus.sub(amount);
        BonusToken[bsToken].updatePoolTime = block.timestamp;
        uint256 daoPerBlock = (BonusToken[bsToken].totalBonus.sub(passBonus)).div(BonusToken[bsToken].expirationTimestamps.sub(block.timestamp));   
        BonusToken[bsToken].daoPerBlock = daoPerBlock;  
        IERC20(bsToken).safeTransfer(msg.sender, amount);
        emit SubBonusToken(msg.sender,IERC20(bsToken),amount);

        return true;
    }
    function updateBonusAmount(address bsToken,uint256 bonusAmount) private {
        BonusToken[bsToken].totalBonus = bonusAmount.add(BonusToken[bsToken].totalBonus);
        BonusToken[bsToken].lastBonus = bonusAmount.add(BonusToken[bsToken].lastBonus);
    }
    function getspacingTime(address bsToken) private view returns(uint256){
        if( BonusToken[bsToken].expirationTimestamps >= BonusToken[bsToken].lastRewardTime ){
            if( block.timestamp < BonusToken[bsToken].lastRewardTime ){
                return 0;
            }
            else{
                if(block.timestamp <= BonusToken[bsToken].expirationTimestamps){
                    return block.timestamp.sub( BonusToken[bsToken].lastRewardTime);
                }else{
                    return BonusToken[bsToken].expirationTimestamps.sub(BonusToken[bsToken].lastRewardTime);
                }
            }
        }else{
            return 0;
        }
    }
    
    function deposit(address lpToken,uint256 amount,uint256 poolTypeId) public payable returns(bool) {
        require(lpToken != address(0));
        require(amount >0);
        require(IERC20(lpToken).balanceOf(msg.sender) >= amount);
        require(mintingPool[lpToken][poolTypeId].lpToken != address(0));  //抵押的矿池存在
        require(mintingPoolTypeList[poolTypeId].bstatus,"");
        
        //每个奖励计算一遍
        if( miner[msg.sender][lpToken][poolTypeId].lpToken == address(0) ){
            minerPoolList[msg.sender].push( mintingPool[lpToken][poolTypeId] );  //保存用户抵押的矿池
        }

 
        uint256 accBonusPerShare;

        for(uint256 i=0; i< bonusList.length ;i++ )
        {
            updateBonusShare( bonusList[i] );
            accBonusPerShare = BonusToken[ bonusList[i] ].accBonusPerShare;
            if( miner[msg.sender][lpToken][poolTypeId].veDao > 0 ){
                userBonus[msg.sender][bonusList[i]] = userBonus[msg.sender][bonusList[i]].add(miner[msg.sender][lpToken][poolTypeId].veDao.mul(accBonusPerShare).div(1e18));
                userBonus[msg.sender][bonusList[i]] = userBonus[msg.sender][bonusList[i]].sub(userRewardDebt[msg.sender][bonusList[i]]);
            }
            userRewardDebt[msg.sender][bonusList[i]] = miner[msg.sender][lpToken][poolTypeId].veDao.mul(accBonusPerShare).div(1e18); 
        }
 
        uint256     veDao = 0;              //投票权益
        veDao = amount.mul(mintingPoolTypeList[poolTypeId].weight).div(1000);  //计算权重
        veDao = veDao.mul(mintingPool[lpToken][poolTypeId].multiple); //计算是DAO的倍数

        minerInfo memory newminerInfo = minerInfo({
            timestamps:         block.timestamp,
            lpToken:            lpToken,
            amount:             amount.add(miner[msg.sender][lpToken][poolTypeId].amount),
            veDao:              veDao.add(miner[msg.sender][lpToken][poolTypeId].veDao)
        });
        miner[msg.sender][lpToken][poolTypeId] = newminerInfo;

        userTotalVeDao[msg.sender] = userTotalVeDao[msg.sender].add(veDao);  //计算用户获取总的veDao

        userTotalDao[msg.sender][lpToken] = userTotalDao[msg.sender][lpToken].add(amount); //计算用户总抵押 dao

        poolStakingTotal[lpToken] = poolStakingTotal[lpToken].add(amount);//计算矿池总抵押 dao


        calculatestakingAmount = calculatestakingAmount.add(veDao); //换算为矿池抵押总量
        //新增
        mintingPool[lpToken][poolTypeId].stakingTotal = amount.add(mintingPool[lpToken][poolTypeId].stakingTotal);  //单个矿池抵押量
        
        IERC20(lpToken).safeTransferFrom(msg.sender, address(this), amount);

        emit Deposit(msg.sender,lpToken,amount);
        return true;
    }
    function withdraw(address lpToken,uint256 poolTypeId) public returns(bool){
        require(lpToken != address(0));
        require(mintingPool[lpToken][poolTypeId].lpToken != address(0));  //抵押的矿池存在
        require(miner[msg.sender][lpToken][poolTypeId].veDao >= 0);
        uint256 amount = miner[msg.sender][lpToken][poolTypeId].amount;
        
        uint256 accBonusPerShare;
        //开始计算各种奖励资产
        for(uint256 i=0;i< bonusList.length ;i++ ){
            updateBonusShare(bonusList[i]);
        
            accBonusPerShare = BonusToken[bonusList[i]].accBonusPerShare;

            if( miner[msg.sender][lpToken][poolTypeId].veDao > 0 ){
                userBonus[msg.sender][bonusList[i]] = userBonus[msg.sender][bonusList[i]].add(miner[msg.sender][lpToken][poolTypeId].veDao.mul(accBonusPerShare).div(1e18));
                userBonus[msg.sender][bonusList[i]] = userBonus[msg.sender][bonusList[i]].sub(userRewardDebt[msg.sender][bonusList[i]]);
            }
            userRewardDebt[msg.sender][bonusList[i]] = miner[msg.sender][lpToken][poolTypeId].veDao.mul(accBonusPerShare).div(1e18); 
        }
        

        //检查是否到期，如果没有到期，只允许支取利息，到期后，可以取本息
        if(miner[msg.sender][lpToken][poolTypeId].timestamps.add( mintingPoolTypeList[poolTypeId].poolLength ) >= block.timestamp )
        {
            miner[msg.sender][lpToken][poolTypeId].amount = (miner[msg.sender][lpToken][poolTypeId].amount).sub(amount);
            uint256 veDao = miner[msg.sender][lpToken][poolTypeId].veDao;

            miner[msg.sender][lpToken][poolTypeId].veDao = 0;
            //去掉抵押量
            mintingPool[lpToken][poolTypeId].stakingTotal = mintingPool[lpToken][poolTypeId].stakingTotal.sub(amount);
            
            calculatestakingAmount = calculatestakingAmount.sub(veDao);    //去掉veDao
            
            userTotalVeDao[msg.sender] = userTotalVeDao[msg.sender].sub(veDao);

            userTotalDao[msg.sender][lpToken] = userTotalDao[msg.sender][lpToken].sub(amount);

            poolStakingTotal[lpToken] = poolStakingTotal[lpToken].sub(amount);

            //单个矿池抵押量
            mintingPool[lpToken][poolTypeId].stakingTotal = (mintingPool[lpToken][poolTypeId].stakingTotal).sub(amount);  
     
            if(amount > 0 ){
                IERC20(lpToken).safeTransfer(msg.sender,amount);
                emit Withdraw(msg.sender,lpToken, amount);
            }            

        }

        uint256 bonus; 
        miner[msg.sender][lpToken][poolTypeId].timestamps = block.timestamp;
        //开始分配各种奖励资产
        for(uint256 i=0;i< bonusList.length ;i++ ){

            bonus = userBonus[msg.sender][bonusList[i]]; 
            userBonus[msg.sender][bonusList[i]] = 0;
            BonusToken[bonusList[i]].lastBonus = BonusToken[bonusList[i]].lastBonus.sub(bonus);

            if( bonus > 0 ){
                IERC20(bonusList[i]).safeTransfer(msg.sender,bonus);
            }          
            emit WithdrawBonus(msg.sender,lpToken, address(bonusList[i]),bonus);
        }
        return true;
    }
    function viewMinting(address who,address lpToken,address bsToken,uint256 poolTypeId) public view returns (uint256){
        require(lpToken != address(0));
        uint256 bonus = 0;
        uint256 accBonusPerShare = BonusToken[bsToken].accBonusPerShare; 
        if( miner[who][lpToken][poolTypeId].veDao > 0 ){

            uint256 spacingTime = getspacingTime(bsToken);  

            uint256 lpSupply = calculatestakingAmount;

            uint256 DAOReward = spacingTime.mul(BonusToken[bsToken].daoPerBlock).mul(1e18).div(lpSupply);  
            
            accBonusPerShare = accBonusPerShare.add(DAOReward);
            
            bonus = miner[who][lpToken][poolTypeId].veDao.mul(accBonusPerShare).div(1e18);
            bonus = bonus.sub(userRewardDebt[msg.sender][bsToken]);
        }
        bonus = bonus.add(userBonus[msg.sender][bsToken]);
        return bonus;
    }
}