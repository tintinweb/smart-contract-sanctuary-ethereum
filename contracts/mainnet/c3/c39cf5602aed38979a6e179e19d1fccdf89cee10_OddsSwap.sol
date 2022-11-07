/**
 *Submitted for verification at Etherscan.io on 2022-11-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        _status = _NOT_ENTERED;
    }
}


abstract contract Context is ReentrancyGuard{
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );


    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

  
    function owner() public view virtual returns (address) {
        return _owner;
    }


    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

}

interface ERC20Interface {
    function transferFrom(address _from, address _to, uint _value)external;
    function allowance(address _owner, address _spender) external returns (uint remaining);
}

interface BEP20Interface {
    function transferFrom(address _from, address _to, uint256 _value)external;
}


contract WalletPayment{
    address private _betTokenAddress;
    address private _tokenPoolAddress;
    bool private ifEth;

    function _getIfEth()internal view returns (bool){
        return ifEth;
    }

    function _setIfEth(bool _ifEth)internal {
       ifEth = _ifEth;
    }

    function _getBetTokenAddress()internal view returns (address){
        return _betTokenAddress;
    }

    function _setBetTokenAddress(address betTokenAddress_)internal {
        require(betTokenAddress_!=address(0),"WalletPayment:Address can not be zero.");
        _betTokenAddress=betTokenAddress_;
    }

    function _getTokenPoolAddress()internal view returns (address){
        return _tokenPoolAddress;
    }

    function _setTokenPoolAddress(address tokenPoolAddress_)internal {
        require(tokenPoolAddress_!=address(0),"WalletPayment:Address can not be zero.");
        _tokenPoolAddress=tokenPoolAddress_;
    }

    function _payBetToken(uint256 amount)internal {
        require(amount>0,"WalletPayment:Amount can not be zero.");
        if(ifEth){
          require(ERC20Interface(_betTokenAddress).allowance(msg.sender,address(this))>=amount,"WalletPayment: transfer amount exceeds allowance");
          ERC20Interface(_betTokenAddress).transferFrom(msg.sender,_tokenPoolAddress,amount);
        }else{
          BEP20Interface(_betTokenAddress).transferFrom(msg.sender,_tokenPoolAddress,amount);
        }
        
    }

    function _payBetTokenToUser(address to ,uint256 amount)internal {
        require(to!=address(0),"WalletPayment:Address can not be zero.");
        require(amount>0,"WalletPayment:Amount can not be zero.");
         if(ifEth){
          require(ERC20Interface(_betTokenAddress).allowance(_tokenPoolAddress,address(this))>=amount,"WalletPayment: transfer amount exceeds allowance");
          ERC20Interface(_betTokenAddress).transferFrom(_tokenPoolAddress,to,amount);
           }else{
          BEP20Interface(_betTokenAddress).transferFrom(_tokenPoolAddress,to,amount);
        }
    }
}

  


contract  WalletAccountDomain{

  struct WalletAccountEntity{
      address userAddress;
      uint256 balance;
      uint256 createTime;
      uint256 updateTime;
  }
}

contract WalletAccountService is WalletAccountDomain{

  mapping(address=>WalletAccountEntity) private  walletAccounts;

  function _balanceOperation(address user,bool income,uint256 amount) internal  returns(uint256 newBalance){
    require(user!=address(0),"WalletAccountService:Address can not be zero.");
    require(amount>0,"WalletAccountService:Amount can not be zero.");

    WalletAccountEntity storage account = walletAccounts[user];
    if(account.createTime ==0){
      account.userAddress = user;
      account.balance=0;
      account.createTime=block.timestamp;
      account.updateTime=block.timestamp;
    }
    if(income){
      newBalance = account.balance + amount;
    }else{
      require(account.balance>=amount,"WalletAccountService : Insufficient Balance");
      newBalance =  account.balance - amount;
    }
    account.balance = newBalance;
    account.updateTime = block.timestamp;
  }

  function _balanceOf(address user) internal view returns(uint256){
    return walletAccounts[user].balance;
  }
  

}

contract WalletService is WalletAccountService,WalletPayment{
  function _withdraw(uint256 amount) internal {
    uint256 balance = _balanceOf(msg.sender);
    require(amount>0,"WalletService : Amount can not be zero.");
    require(balance >= amount,"WalletService : Insufficient Balance");
    _balanceOperation(msg.sender,false,amount);
    _payBetTokenToUser(msg.sender,amount);
  } 
}


contract Sequence{
  mapping(string =>uint256) private  sequences;
  function _current(string memory seqKey) internal view returns(uint256){
    return sequences[seqKey];
  }

  function _increment(string memory seqKey) internal returns(uint256){
    uint256 seqValue = sequences[seqKey];
    seqValue = seqValue +1;
    sequences[seqKey]=seqValue;
    return seqValue;
  }
}

interface IMarketOddsFactory{
  function calcOdds(MarketDomain.MarketBetBo calldata MarketBetBo,MarketDomain.MarketBetOptionBo [] calldata options) pure external returns (bool exceed,uint256 currentOdds,MarketDomain.MarketBetOptionBo [] memory currOptions);
}

interface MarketSwapInterceptor{
  // function onSwapBefore(address user,uint256 poolId,uint256 poolType,uint256 option,uint256 swapAmount)external;
  function onSwapAfter(address user,uint256 poolId,uint256 poolType,uint256 option,uint256 swapAmount,uint256 odds)external;
}

contract ConfigCenter{

  struct InterceptorConfig{
    address contractAddress;
    bool valid;
  }

  mapping(uint256 =>address) private  marketOddsFactorys;
  InterceptorConfig [] private  marketSwapInterceptors;

  function _setOddsFactory(
    uint256 poolType,address factoryAddress)
    internal
  {
  require(poolType>0 && factoryAddress!=address(0),"ConfigCenter: poolType or factoryAddress can not be zero.");
  marketOddsFactorys[poolType]=factoryAddress;
  }

  function _oddsFactoryOf(uint256 poolType)
    view
    internal
    returns (address)
  {
  return marketOddsFactorys[poolType];
  }

  function _installSwapInterceptor(
    address marketSwapInterceptor)
    internal
  {
  require(marketSwapInterceptor!=address(0),"ConfigCenter: marketSwapInterceptor can not be zero.");
  bool exists;
  bool valid;
  uint256 index;
  (exists,valid ,index) = _find(marketSwapInterceptor);
  if(exists){
    marketSwapInterceptors[index].valid = true;
  }else{
    marketSwapInterceptors.push(InterceptorConfig({
      valid:true,
      contractAddress:marketSwapInterceptor
    }));
  } 
  }

  function _find(address _contractAddress)
  view internal
  returns (bool exists ,bool valid ,uint256 index)
  {
     if(marketSwapInterceptors.length==0){
       return (false,false,0);
     }
    for(uint256 i = 0; i < marketSwapInterceptors.length; i++){
      InterceptorConfig memory interceptor = marketSwapInterceptors[i];
      if(interceptor.contractAddress == _contractAddress){
        return (true,interceptor.valid,i);
      }
    }

  }

  function _unstallSwapInterceptor(
    address marketSwapInterceptor)
    internal
  {
  require(marketSwapInterceptor!=address(0),"ConfigCenter: marketSwapInterceptor can not be zero.");
  bool exists;
  bool valid;
  uint256 index;
  (exists,valid ,index) = _find(marketSwapInterceptor);
  if(exists){
    marketSwapInterceptors[index].valid = false;
  }
}

  function _findAllSwapInterceptor()
    view
    internal
    returns (InterceptorConfig [] memory )
  {
  return marketSwapInterceptors;
  }
}


contract  MarketDomain{

    struct MarketBetOptionEntity{
        uint256 option;
        uint256 currOdds;
        uint256 betTotalAmount;       
    }


    struct MarketPoolEntity{
      uint256 poolId;
      uint256 poolType;
      uint256 fixtureId;
      uint256 betMinAmount;
      uint256 betMaxAmount;
      uint256 fee;
      bool    betEnable;
      uint256 betBeginTime;
      uint256 betEndTime;
      uint256 createTime;
      uint256 updateTime;
  }

  struct MarketPoolAddDto{
      uint256 poolId;
      uint256 poolType;
      uint256 fixtureId;
      uint256 betMinAmount;
      uint256 betMaxAmount;
      uint256 fee;
      bool    betEnable;
      uint256 betBeginTime;
      uint256 betEndTime;
  }

  struct MarketPoolEditDto{
      uint256 poolId;
      uint256 fixtureId;
      uint256 betMinAmount;
      uint256 betMaxAmount;
      bool    betEnable;
      uint256 betBeginTime;
      uint256 betEndTime;
  }


  struct MarketBetEntity{
      uint256 betId;
      uint256 poolId;
      address userAddress;
      uint256 option;
      uint256 currOdds;
      uint256 betAmount;
      bool    drawed;
      uint256 drawTime;
      uint256 rewardAmout;
      uint256 refundAmount;
      uint256 createTime;
      uint256 updateTime;
  }

  struct MarketBetDto{
      uint256 poolId;
      uint256 option;
      uint256 betAmount;
      uint256 slide;
  }
  
  struct MarketBetBo{
    uint256 poolId;
    uint256 poolType;
    address user;
    uint256 option;
    uint256 betAmount;
    uint256 slide;
    uint256 fee;
    uint256 minUnit;
  }

  struct MarketBetOptionBo{
        uint256 option;
        uint256 currOdds;
        uint256 betTotalAmount;       
  }
}


contract MarketService is MarketDomain,Sequence,WalletService,ConfigCenter{
    string private betIdKey = "BETID";
    mapping(uint256=>MarketPoolEntity)  pools;
    mapping(uint256=>MarketBetOptionEntity [])  poolOptions;
    mapping(uint256=>MarketBetEntity)  bets;

    function _addMarketPoolEntity(
     MarketPoolAddDto memory _poolAddDto)
    internal
   {
     require(_poolAddDto.poolId>0,"MarketService: PoolId can not be zero.");
     MarketPoolEntity storage localPool = pools[_poolAddDto.poolId];
     require(localPool.poolId==0,"MarketService: Pool already exists.");
     localPool.poolId = _poolAddDto.poolId;
     localPool.poolType = _poolAddDto.poolType;
     localPool.fixtureId = _poolAddDto.fixtureId;
     localPool.betBeginTime = _poolAddDto.betBeginTime;
     localPool.fee = _poolAddDto.fee;
     localPool.betEndTime = _poolAddDto.betEndTime;
     localPool.betEnable = _poolAddDto.betEnable;
     localPool.betMinAmount = _poolAddDto.betMinAmount;
     localPool.betMaxAmount = _poolAddDto.betMaxAmount;
     localPool.createTime = block.timestamp;
     localPool.updateTime = block.timestamp;
    }

    function _editMarketPoolEntity(
     MarketPoolEditDto memory _poolEditDto)
    internal
   {
     require(_poolEditDto.poolId>0,"MarketService: PoolId can not be zero.");
     MarketPoolEntity storage localPool = pools[_poolEditDto.poolId];
     require(localPool.poolId>0,"MarketService: Pool not found!");
     if(_poolEditDto.fixtureId>0){
      localPool.fixtureId = _poolEditDto.fixtureId;
     }
     if(_poolEditDto.betBeginTime>0){
       localPool.betBeginTime = _poolEditDto.betBeginTime;
     }
     if(_poolEditDto.betEndTime>0){
       localPool.betEndTime = _poolEditDto.betEndTime;
     }
    if(_poolEditDto.betMinAmount>0){
       localPool.betMinAmount = _poolEditDto.betMinAmount;
     }
     if(_poolEditDto.betMaxAmount>0){
       localPool.betMaxAmount = _poolEditDto.betMaxAmount;
     }
     localPool.betEnable = _poolEditDto.betEnable;
     localPool.updateTime = block.timestamp;
    }


    function _addMarketOptionEntities(
      uint256 poolId,
      uint256 [] memory optionArr,
      uint256 [] memory initOddsArr,
      uint256 [] memory betTotalAmountArr
    )
    internal
   {
     require(poolId>0,"MarketService: PoolId can not be zero.");
     MarketPoolEntity storage localPool = pools[poolId];
     require(localPool.poolId>0,"MarketService: Pool not found.");
     MarketBetOptionEntity [] storage optionEntityArr = poolOptions[poolId];
     require(optionEntityArr.length==0,"MarketService: Pool option already exists.");
     require(optionArr.length==initOddsArr.length&&optionArr.length ==betTotalAmountArr.length ,"MarketService: optionArr length invalid.");    
     for(uint256 i =0; i<optionArr.length; i++){
       optionEntityArr.push(MarketBetOptionEntity({
       option:optionArr[i],
       currOdds:initOddsArr[i],
       betTotalAmount:betTotalAmountArr[i]
     }));
     }
    
    }

    function _findMarketPoolEntity(uint256 poolId) internal view returns(MarketPoolEntity memory poolEntity){
      poolEntity = pools[poolId];
    }

    function _findMarketPoolBetOptionEntity(uint256 _poolId,uint256 _option) internal view returns(MarketBetOptionEntity memory result){
      MarketBetOptionEntity [] memory  options =  poolOptions[_poolId];
      for(uint256 i =0; i< options.length; i++){
        MarketBetOptionEntity memory optionEntity = options[i];
        if(optionEntity.option == _option){
          result =  optionEntity;
          break;
        }
      }
    }

    function _findMarketPoolBetOptionEntitys(uint256 _poolId) internal view returns(MarketBetOptionEntity [] memory results){
      return  poolOptions[_poolId];
    }

 function _swap(
   MarketBetDto
   memory
   _marketBetDto
 ) internal returns(uint256 betId,uint256 finalOdds,uint256 createTime){
  
  MarketPoolEntity storage localPool = pools[_marketBetDto.poolId]; 
  require(localPool.poolId>0,"MarketService: Invalid Pool.");
  require(block.timestamp >=localPool.betBeginTime && block.timestamp <=localPool.betEndTime,"MarketService: Invalid bet time.");
  require(_marketBetDto.betAmount >=localPool.betMinAmount && _marketBetDto.betAmount <=localPool.betMaxAmount,"MarketService: Invalid bet amount.");


  MarketBetBo memory betBo = MarketBetBo({
    poolId:_marketBetDto.poolId,
    poolType:localPool.poolType,
    user:msg.sender,
    option:_marketBetDto.option,
    betAmount:_marketBetDto.betAmount,
    slide:_marketBetDto.slide,
    minUnit:localPool.betMinAmount,
    fee:localPool.fee
  });

   _payBetToken(betBo.betAmount);

  MarketBetOptionEntity  [] storage optionEntiries = poolOptions[_marketBetDto.poolId];
  MarketBetOptionBo [] memory optionBos = new MarketBetOptionBo [](optionEntiries.length);
  bool finded = false;
  for(uint256 i =0;i< optionEntiries.length;i ++){
    MarketBetOptionEntity storage localOption = optionEntiries[i];
    optionBos[i] = MarketBetOptionBo({
      option:localOption.option,
      currOdds:localOption.currOdds,
      betTotalAmount:localOption.betTotalAmount
    });
    if(localOption.option == _marketBetDto.option){
      finded = true;
    }
  }
  require(finded,"MarketService: Invalid option.");
   
  uint256 nowTime = block.timestamp;
  bool exceed;
  uint256 currentOdds;
  MarketBetOptionBo [] memory optionsRes;
  address oddsFactoryAddress = _oddsFactoryOf(localPool.poolType);
  require(oddsFactoryAddress!=address(0),"MarketService: oddsFactoryAddress not found!");
  (exceed,currentOdds,optionsRes) = IMarketOddsFactory(oddsFactoryAddress).calcOdds(betBo,optionBos);
  require(exceed == false,"MarketService: slide exceed.");
  betId = _increment(betIdKey);
  bets[betId] = MarketBetEntity({
     betId:betId,
     poolId:betBo.poolId,
     userAddress:msg.sender,
     option:betBo.option,
     currOdds:currentOdds,
     betAmount:betBo.betAmount,
     drawed:false,
     drawTime:0,
     rewardAmout:0,
     refundAmount:0,
     createTime:nowTime,
     updateTime:nowTime
   });

   _modifyOptionsOnBet(optionEntiries,optionsRes);
   createTime = nowTime;
   finalOdds = currentOdds;

  _onSwapAfter(betBo,currentOdds);
 }

 function _findBetEntity(uint256 betId)internal view returns(MarketBetEntity memory entity){
   return bets[betId];
 }

  function _onSwapAfter(MarketBetBo memory betbo,uint256 finalOdds)internal{
    InterceptorConfig [] memory marketSwapInterceptors = _findAllSwapInterceptor();
      if(marketSwapInterceptors.length >0){
        for(uint256 i = 0; i< marketSwapInterceptors.length; i++){
          InterceptorConfig memory interceptor = marketSwapInterceptors[i];
          if(interceptor.valid){
            MarketSwapInterceptor(interceptor.contractAddress).onSwapAfter(betbo.user,betbo.poolId,betbo.poolType,betbo.option,betbo.betAmount,finalOdds);
          }      
        }
      }
  }


  function _modifyOptionsOnBet(MarketBetOptionEntity  []  storage options,MarketBetOptionBo [] memory optionBos)internal{
    for(uint256 i = 0; i<options.length; i++){
    MarketBetOptionEntity storage _option = options[i];
    for(uint256 j = 0; j<optionBos.length; j++ ){
      MarketBetOptionBo memory res = optionBos[j];
      if(_option.option == res.option){
        _option.currOdds = res.currOdds;
        _option.betTotalAmount = res.betTotalAmount;
      }
    }
  }
 }
  


  function _draw(
   uint256 [] calldata  betIdArr,
   uint256 [] calldata  rewardArr,
   uint256 [] calldata  refundArr
 ) internal {   
   for(uint256 i = 0; i<betIdArr.length; i++){
     MarketBetEntity storage betEntity = bets[betIdArr[i]];
     if(!betEntity.drawed){
       betEntity.drawed=true;
       betEntity.drawTime = block.timestamp;
       betEntity.updateTime = block.timestamp;
       betEntity.rewardAmout = rewardArr[i];
       betEntity.refundAmount = refundArr[i];       
       uint256 payAmount = rewardArr[i] + refundArr[i];
       _balanceOperation(betEntity.userAddress,true,payAmount);
     }
   }
}

}

interface IOddsSwap{
  function getBetTokenAddress()external view returns (address);
  function setBetTokenAddress(address betTokenAddress)external;
  function getTokenPoolAddress()external view returns (address);
  function setTokenPoolAddress(address tokenPoolAddress)external;
  function getIfEth()external view returns (bool);
  function setIfEth(bool _ifEth)external;

  function setOddsFactory(uint256 poolType,address factoryAddress)external;
  function oddsFactoryOf(uint256 poolType) view external returns (address);
  function installSwapInterceptor(address marketSwapInterceptor)external;
  function unstallSwapInterceptor(address marketSwapInterceptor)external;
  function showAllSwapInterceptor() view external returns (address [] memory contractAddresses,bool [] memory valids);

  function findMarketPool(uint256 _poolId) external view returns(
      uint256 poolId,
      uint256 poolType,
      uint256 fixtureId,
      uint256 betMinAmount,
      uint256 betMaxAmount,
      uint256 fee,
      bool    betEnable,
      uint256 betBeginTime,
      uint256 betEndTime,
      uint256 createTime,
      uint256 updateTime
  );

  function addMarketPool(
      uint256 poolId,
      uint256 poolType,
      uint256 fixtureId,
      uint256 betMinAmount,
      uint256 betMaxAmount,
      uint256 fee,
      bool    betEnable,
      uint256 betBeginTime,
      uint256 betEndTime
  )external;

  function updateMarketPool(
      uint256 poolId,
      uint256 fixtureId,
      uint256 betMinAmount,
      uint256 betMaxAmount,
      bool    betEnable,
      uint256 betBeginTime,
      uint256 betEndTime
  )external;

  function findMarketPoolBetOption(
      uint256 _poolId,
      uint256 _option
  )external returns(
      uint256 option,
      uint256 currOdds,
      uint256 betTotalAmount
  );

  function findMarketPoolBetAllOption(
      uint256 _poolId
  )external returns(
      uint256 [] memory optionArr,
      uint256 [] memory currOddsArr,
      uint256 [] memory betTotalAmountArr
  );


  function addMarketPoolBetOptions(
      uint256 poolId,
      uint256 [] memory optionArr,
      uint256 [] memory initOddsArr,
      uint256 [] memory betTotalAmountArr
  )external ;

  function draw(
      uint256 [] calldata  betIdArr,
      uint256 [] calldata  rewardArr,
      uint256 [] calldata  refundArr
  )external;
  
  function swap(
    uint256 poolId,
    uint256 option,
    uint256 betAmount,
    uint256 slide
    )external;

  function findBetInfo(uint256 _betId) external view returns(
      uint256 betId,
      uint256 poolId,
      address userAddress,
      uint256 option,
      uint256 currOdds,
      uint256 betAmount,
      bool    drawed,
      uint256 drawTime,
      uint256 rewardAmout,
      uint256 refundAmount,
      uint256 createTime,
      uint256 updateTime
  );
  function balanceOf(address user) external view returns(uint256);  
  function withdraw(uint256 amount) external returns(bool succeed);

  event SetBetTokenAddress(address betTokenAddress);
  event SetTokenPoolAddress(address tokenPoolAddress);
  event SetIfEth(bool ifEth);
  event SetOddsFactory(uint256 poolType,address factoryAddress);
  event InstallSwapInterceptor(address marketSwapInterceptor);
  event UnstallSwapInterceptor(address marketSwapInterceptor);
  event AddMarketPool(uint256 indexed poolId,uint256 poolType,uint256 fixtureId,uint256 betMinAmount,uint256 betMaxAmount,uint256 fee,bool betEnable,uint256 betBeginTime,uint256 betEndTime);
  event UpdateMarketPool(uint256 indexed poolId,uint256 fixtureId,uint256 betMinAmount,uint256 betMaxAmount,bool  betEnable,uint256 betBeginTime,uint256 betEndTime);
  event AddMarketBetOptions(uint256 indexed poolId,uint256 [] optionArr,uint256 [] initOddsArr,uint256 [] betTotalAmountArr);
  event Draw( uint256 []  betIdArr, uint256 []  rewardArr,   uint256 []  refundArr,uint256 time);
  event Swap(address indexed user,uint256 indexed poolId,uint256 betId,uint256 option,uint256 betAmount,uint256 slide,uint256 finalOdds,uint256 createTime);
  event Withdraw(address indexed user,uint256 amount,uint256 time);
}

contract OddsSwap is IOddsSwap,Ownable,MarketService{
  function getBetTokenAddress()external view override returns (address){
    return _getBetTokenAddress();
  }
  function setBetTokenAddress(address betTokenAddress)external override onlyOwner{
    _setBetTokenAddress(betTokenAddress);
    emit SetBetTokenAddress(betTokenAddress);
  }
  function getTokenPoolAddress()external view override returns (address){
    return _getTokenPoolAddress();
  }
  function setTokenPoolAddress(address tokenPoolAddress)external override onlyOwner{
    _setTokenPoolAddress(tokenPoolAddress);
    emit SetTokenPoolAddress(tokenPoolAddress);
  }

  function getIfEth()external view override returns (bool){
    return _getIfEth();
  }
  function setIfEth(bool _ifEth)external override onlyOwner{
    _setIfEth(_ifEth);
    emit SetIfEth(_ifEth);
  }

  function setOddsFactory(uint256 poolType,address factoryAddress)external override onlyOwner{
    _setOddsFactory(poolType,factoryAddress);
    emit SetOddsFactory(poolType,factoryAddress);
  }
  function oddsFactoryOf(uint256 poolType) view external override returns (address){
    return _oddsFactoryOf(poolType);
  }
  function installSwapInterceptor(address marketSwapInterceptor)external override onlyOwner{
    _installSwapInterceptor(marketSwapInterceptor);
    emit InstallSwapInterceptor(marketSwapInterceptor);
  }
  function unstallSwapInterceptor(address marketSwapInterceptor)external override onlyOwner{
    _unstallSwapInterceptor(marketSwapInterceptor);
    emit UnstallSwapInterceptor(marketSwapInterceptor);
  }
  function showAllSwapInterceptor() view external override returns (address [] memory contractAddresses,bool [] memory valids){
    ConfigCenter.InterceptorConfig [] memory all =  _findAllSwapInterceptor();
    contractAddresses = new address[](all.length);
    valids = new bool[](all.length);
    for(uint256 i = 0;i< all.length; i++){
      contractAddresses[i] = all[i].contractAddress;
      valids[i] = all[i].valid;
    }
  }

  function addMarketPool(
      uint256 poolId,
      uint256 poolType,
      uint256 fixtureId,
      uint256 betMinAmount,
      uint256 betMaxAmount,
      uint256 fee,
      bool    betEnable,
      uint256 betBeginTime,
      uint256 betEndTime
  )external override onlyOwner{
    MarketPoolAddDto memory dto = _toMarketAddDto(poolId,poolType,fixtureId,betMinAmount,betMaxAmount,fee,betEnable,betBeginTime,betEndTime);
    _addMarketPoolEntity(dto);
   emit AddMarketPool(dto.poolId,dto.poolType,dto.fixtureId,dto.betMinAmount,dto.betMaxAmount,dto.fee,dto.betEnable,dto.betBeginTime,dto.betEndTime);
  }

  function _toMarketAddDto(
      uint256 poolId,
      uint256 poolType,
      uint256 fixtureId,
      uint256 betMinAmount,
      uint256 betMaxAmount,
      uint256 fee,
      bool    betEnable,
      uint256 betBeginTime,
      uint256 betEndTime
  ) internal pure returns(MarketPoolAddDto memory dto){
      dto = MarketPoolAddDto({
      poolId:poolId,
      poolType:poolType,
      fixtureId:fixtureId,
      betMinAmount:betMinAmount,
      betMaxAmount:betMaxAmount,
      fee:fee,
      betEnable:betEnable,
      betBeginTime:betBeginTime,
      betEndTime:betEndTime
    });
  }


  function addMarketPoolBetOptions(
      uint256 poolId,
      uint256 [] memory optionArr,
      uint256 [] memory initOddsArr,
      uint256 [] memory betTotalAmountArr
  )external override onlyOwner{
    _addMarketOptionEntities(poolId,optionArr,initOddsArr,betTotalAmountArr);
    emit AddMarketBetOptions(poolId,optionArr,initOddsArr,betTotalAmountArr);
  }


  function _toMarketBetDto(
    uint256 poolId,
    uint256 option,
    uint256 betAmount,
    uint256 slide
  )internal pure returns (MarketBetDto memory betDto){
    betDto = MarketBetDto({
      poolId:poolId,
      option:option,
      betAmount:betAmount,
      slide:slide
    });
  }

  function _toPoolEditDto(
      uint256 poolId,
      uint256 fixtureId,
      uint256 betMinAmount,
      uint256 betMaxAmount,
      bool    betEnable,
      uint256 betBeginTime,
      uint256 betEndTime
  )internal pure returns (MarketPoolEditDto memory poolEditDto){
    poolEditDto = MarketPoolEditDto({
      poolId:poolId,
      fixtureId:fixtureId,
      betMinAmount:betMinAmount,
      betMaxAmount:betMaxAmount,
      betEnable:betEnable,
      betBeginTime:betBeginTime,
      betEndTime:betEndTime
    });
  }

  function updateMarketPool(
      uint256 poolId,
      uint256 fixtureId,
      uint256 betMinAmount,
      uint256 betMaxAmount,
      bool    betEnable,
      uint256 betBeginTime,
      uint256 betEndTime
    )external override onlyOwner{
      MarketPoolEditDto memory poolEditDto = _toPoolEditDto(poolId,fixtureId,betMinAmount,betMaxAmount,betEnable,betBeginTime,betEndTime);
    _editMarketPoolEntity(poolEditDto);
    emit UpdateMarketPool(poolId,fixtureId,betMinAmount,betMaxAmount,betEnable,betBeginTime,betEndTime);
  }

  function findMarketPool(uint256 _poolId) external override view returns(
      uint256 poolId,
      uint256 poolType,
      uint256 fixtureId,
      uint256 betMinAmount,
      uint256 betMaxAmount,
      uint256 fee,
      bool    betEnable,
      uint256 betBeginTime,
      uint256 betEndTime,
      uint256 createTime,
      uint256 updateTime){
    MarketPoolEntity memory pool = _findMarketPoolEntity(_poolId);
    return (pool.poolId,pool.poolType,pool.fixtureId,pool.betMinAmount,pool.betMaxAmount,pool.fee,pool.betEnable,pool.betBeginTime,pool.betEndTime,pool.createTime,pool.updateTime);
  }

  function findMarketPoolBetOption(
      uint256 _poolId,
      uint256 _option
  )external override view returns(
      uint256 option,
      uint256 currOdds,
      uint256 betTotalAmount
  ){
      MarketBetOptionEntity memory optionEntity = _findMarketPoolBetOptionEntity(_poolId,_option);
      return (optionEntity.option,optionEntity.currOdds,optionEntity.betTotalAmount);
  }


  function findMarketPoolBetAllOption(
      uint256 _poolId
  )external override view returns(
      uint256 [] memory optionArr,
      uint256 [] memory currOddsArr,
      uint256 [] memory betTotalAmountArr
  ){
      MarketBetOptionEntity [] memory options = _findMarketPoolBetOptionEntitys(_poolId);
      optionArr = new uint256[](options.length);
      currOddsArr = new uint256[](options.length);
      betTotalAmountArr = new uint256[](options.length);
      for(uint256 i =0;i<options.length;i++){
        optionArr[i] = options[i].option;
        currOddsArr[i] = options[i].currOdds;
        betTotalAmountArr[i] = options[i].betTotalAmount;
      }
  }


  function draw(
      uint256 [] calldata  betIdArr,
      uint256 [] calldata  rewardArr,
      uint256 [] calldata  refundArr
    )external override onlyOwner{
    _draw(betIdArr,rewardArr,refundArr);
    emit Draw(betIdArr,rewardArr,refundArr,block.timestamp);
  }

  function swap(
    uint256 poolId,
    uint256 option,
    uint256 betAmount,
    uint256 slide
    )external nonReentrant override{
    MarketBetDto memory marketBetDto = _toMarketBetDto(poolId,option,betAmount,slide);
    uint256 betId;
    uint256 finalOdds;
    uint256 createTime;
    (betId,finalOdds,createTime) = _swap(marketBetDto);
    emit Swap(msg.sender,marketBetDto.poolId,betId,marketBetDto.option,marketBetDto.betAmount,marketBetDto.slide,finalOdds,createTime);
  }

  function findBetInfo(uint256 _betId) external view override returns(
      uint256 betId,
      uint256 poolId,
      address userAddress,
      uint256 option,
      uint256 currOdds,
      uint256 betAmount,
      bool    drawed,
      uint256 drawTime,
      uint256 rewardAmout,
      uint256 refundAmount,
      uint256 createTime,
      uint256 updateTime
  ){
    MarketBetEntity memory bet = _findBetEntity(_betId);
    return (bet.betId,bet.poolId,bet.userAddress,bet.option,bet.currOdds,bet.betAmount,bet.drawed,bet.drawTime,bet.rewardAmout,bet.refundAmount,bet.createTime,bet.updateTime);
  }

  function balanceOf(address user) external view override returns(uint256) {
    return _balanceOf(user);
  }
  function withdraw(uint256 amount) external nonReentrant override returns(bool succeed){
    _withdraw(amount);
    succeed =  true;
    emit Withdraw(msg.sender,amount,block.timestamp);
  }

  constructor(address betTokenAddress,address tokenPoolAddress){
    _setBetTokenAddress(betTokenAddress);
    _setTokenPoolAddress(tokenPoolAddress);
  }
}