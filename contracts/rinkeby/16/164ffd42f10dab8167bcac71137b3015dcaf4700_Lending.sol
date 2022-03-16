/**
 *Submitted for verification at Etherscan.io on 2022-03-16
*/

pragma solidity 0.8.1;

contract Lending{
                            ///***数据***///
    //记录KToken
    struct tokenInfo{
        uint256 cash;
        uint256 borrow;
        uint256 reserve;
    }
    //记录KToken
    struct ktokenInfo{
        uint256 totalsupply;
        uint256 collateralrate;
        uint256 blockNumber;
        uint256 index;
    }

    //用户欠的Ktoken
    struct debt{
        uint256 base;
        uint256 index;
    }
    //借贷模型的参数
    struct rateModel{
        uint256 k;
        uint256 b;
    }
    //合约拥有者地址
    address public  owner;
    //用户所有Ktoken地址
    address [] public allKtoken;
    //eth地址
    address public  eth;
    //weth地址
    address public  weth;
    //初始兑换率
    uint256 public constant INITAL_EXCHANGERATE = 1;
    //清算率 50%
    uint256 public constant LIQUIDITY_RATE = 500;
    //清算奖励 110%
    uint256 public constant LIQUIDITY_REWARD = 1100;
    //利息中给reserver的比例 20%
    uint256 public constant RESERVER_RATE = 200;
    //根据token地址得到token的cash、borrow
    mapping (address =>tokenInfo) public infoOfToken;
    //根据Ktoken地址得到Ktoken的储备情况
    mapping (address => ktokenInfo) public infoOfKtoken;
    //由token地址得到Ktoken地址
    mapping (address => address) public tokenToktoken;
    //由Ktoken地址得到token地址
    mapping (address => address) public ktokenTotoken;
    //得到用户未质押的Ktoken
    mapping (address => mapping(address => uint256)) public ktokenUnlock;
    //得到用户质押的Ktoken
    mapping (address => mapping(address => uint256)) public ktokenlock;
    //得到用户的Ktoken债务 ktoken => user => Debt
    mapping (address => mapping(address => debt)) public userDebt;
    //得到Ktoken的利息指数
    mapping (address => uint256) public ktokenIndex;
    //得到用户所有token的地址
    mapping (address => address[]) public userKtoken;
    //标的资产的价格，模拟预言机的作用
    mapping (address => uint256) public price;
    //得到Ktoken对应的利率模型
    mapping (address => rateModel) public ktokenModel;
    //检查是否 user=>ktoken
    mapping (address => bool) public ktokenExsis;


                            ///***Owner函数***///
    constructor() public{
        owner = msg.sender;
    }
    modifier onlyOwner(){
        require(msg.sender==owner,"only owner");
        _;
    }
    //设置利率模型初始参数
    function setInitialBorrowParameter(address _token,uint256 _collateral,uint256 _k,uint256 _b)public onlyOwner{
        address _ktoken = tokenToktoken[_token];
        ktokenModel[_ktoken].k = _k;
        ktokenModel[_ktoken].b = _b;
        infoOfKtoken[_ktoken].index=1;
        infoOfKtoken[_ktoken].blockNumber = block.number;
        infoOfKtoken[_ktoken].collateralrate = _collateral;
    }
    //建立token和ktoken的映射
    function establishMapping(address _token,address _ktoken) public onlyOwner{
        tokenToktoken[_token] = _ktoken;
        ktokenTotoken[_ktoken] = _token;
    }
    function setEthAddress(address _eth,address _weth) public onlyOwner{
        eth = _eth;
        weth = _weth;
    }
    function setPrice(address _token,uint256 amount)public onlyOwner{
        price[_token] = amount;
    }

                            ///***主函数***///
    // 充值ERC20
    function externalTransferfrom(address token,uint256 _amount) public{
        IERC20(token).transferFrom(msg.sender,address(this),_amount);      
    }
    function deposit(address _token,uint256 _amount) public{
        //计息
        accurateInterest(_token);
        // 根据充值token数量，通过计算兑换率，获取应该返回用户的 K token的数量
        (address _kToken,uint256 _KTokenAmount) = getKTokenAmount(_token,_amount);
        // 转入用户的token
        IERC20(_token).transferFrom(msg.sender,address(this),_amount);
        // 增加协议的Token的cash数量
        addCash(_token,_amount);
        // 给用户转入 K token 以及更新 Ktoken的总供应
        addKtoken(_kToken,msg.sender,_KTokenAmount);
    }
    // 充值ETH
    function depositETH() public payable{
        //计息
        accurateInterest(weth);
        //向WETH合约中存入用户发送的ETH
        IWETH(weth).deposit{value: msg.value}();
        address _kweth = tokenToktoken[weth];
        //增加WETH的cash数量
        addCash(weth,msg.value);
        // 根据充值token数量，通过计算兑换率，获取应该返回用户的 K token的数量
        (,uint256 _kwethAmount) = getKTokenAmount(weth,msg.value);
        // 给用户转入 K token
        addKtoken(_kweth,msg.sender,_kwethAmount);
    }
    // 取回
    function withdraw(address _ktoken,uint256 _amount) public{
        address _token = ktokenTotoken[_ktoken];
        //计息
        accurateInterest(_token);
        //验证用户是否有足够Ktoken
        require(ktokenUnlock[_ktoken][msg.sender]>=_amount,"user amount insuficient");
        //根据取出Ktoken的数量和兑换率得到标的资产数量
        uint256 _tokenAmount = _amount * getExchangeRate(_ktoken);
        //减少记录的cash值
        reduceCash(_token,_tokenAmount);
        //给用户转入标的资产
        IERC20(_token).transfer(msg.sender,_tokenAmount);
        //转出用户的Ktoken
        reduceKtoken(_ktoken,msg.sender,_amount);
    }
    // 取回WETH
    function withdrawETH(uint256 _amount)public {
        //计息
        accurateInterest(weth);
        address _kweth = tokenToktoken[weth];
        //验证用户是否有足够Kweth
        require(ktokenUnlock[_kweth][msg.sender]>_amount,"user amount insuficient");
        //weth数量 = Keth数量 * 兑换率
        uint256 _wethAmount = _amount * getExchangeRate(_kweth);
        //用WETH提取ETH
        IWETH(weth).withdraw(_wethAmount);
        //减少记录的cash值
        reduceCash(weth,_wethAmount);
        //向用户发送ETH
        eth.call(abi.encodeWithSelector(0xa9059cbb, msg.sender, _wethAmount));
        //转出用户的Kweth
        reduceKtoken(_kweth,msg.sender,_amount);
    }
    // 借款
    function borrow(address _token,uint256 _amount) public{
        //计息
        accurateInterest(_token);
        //验证用户的借款能力
        require(verifyBorrowCapacity(msg.sender,_token,_amount)>=0,"insufficient borrow capacity");
        //如果cash过小，则无法通过reduceCash中的require
        reduceCash(_token,_amount);
        addBorrow(_token,_amount);
        //增加用户债务
        addDebt(_token,msg.sender,_amount);
        //给用户转入标的资产
        IERC20(_token).transfer(msg.sender,_amount);
    
    }
    // 借ETH
    function borrowETH(uint256 _amount) public{
        //计息
        accurateInterest(weth);
        address _kweth = tokenToktoken[weth];
        //验证用户的借款能力
        require(verifyBorrowCapacity(msg.sender,weth,_amount)>=0,"insufficient borrow capacity");
        //提取ETH
        IWETH(weth).withdraw(_amount);
        //如果cash过小，则无法通过reduceCash中的require
        reduceCash(weth,_amount);
        addBorrow(weth,_amount);
        //增加用户债务
        addDebt(weth,msg.sender,_amount);
        //向用户发送ETH
        eth.call(abi.encodeWithSelector(0xa9059cbb, msg.sender, _amount));
    }
    // 还款
    function repay(address _token,uint _amount,address _user) public{
        //计息
        accurateInterest(_token);
        //得到Ktoken地址
        address Ktoken = tokenToktoken[_token];
        //用户向合约转入标的资产
        IERC20(_token).transferFrom(msg.sender,address(this),_amount);
        //
        reduceBorrow(_token,_amount);
        addCash(_token,_amount);
        //减轻用户债务
        reduceDebt(_token,_user,_amount);
    }
    // 还ETH
    function repayETH(address _user)public payable{
        //计息
        accurateInterest(weth);
        //将用户发送的ETH存入WETH合约中
        IWETH(weth).deposit{value: msg.value}();
        //
        reduceBorrow(weth,msg.value);
        addCash(weth,msg.value);
        //减轻用户债务
        reduceDebt(weth,_user,msg.value);
    }
    // 清算
    function liquity(address _liquityAddress,address _borrower,address _token,uint256 _amount) public{
        //计息
        accurateInterest(_token);
        //验证borrower的净资产是否小于负债
        uint _value = verifyBorrowCapacity(msg.sender,_token,0);
        require(_value < 0 ,"enough collateral");
        //计算可以清算的标的资产数量
        (uint256 _tokenAmount,uint256 _ktokenAmount,address _ktoken) = accountLiquity(_borrower,_token);
        //为borrower偿还债务
        repay(_token,_ktokenAmount,_borrower);
        //结算清算者得到Ktoken的数量
        liquityReward(_liquityAddress,_borrower,_ktoken,_ktokenAmount);
    }
    //质押ktoken
    function lock(address _user,address _ktoken,uint _amount)public{
        address _token = ktokenTotoken[_ktoken];
        //计息
        accurateInterest(_token);
        //如果资产Ktoken不在allassert中，则添加进去
        if(ktokenExsis[_ktoken] == false){
            ktokenExsis[_ktoken] = true;
            allKtoken.push(_ktoken);
        }
        require(ktokenUnlock[_ktoken][_user] >= _amount,"unlock amount insuffcient");
        addCollateral(_ktoken,msg.sender,_amount);
    }
    //解除质押ktoken
    function unlock(address _user,address _ktoken,uint _amount)public{
        address _token = ktokenTotoken[_ktoken];
        //计息
        accurateInterest(_token);


        require(ktokenlock[_ktoken][_user]>=_amount,"lock amount insuffcient");
        reduceCollateral(_ktoken,msg.sender,_amount);
    }


                            ///***更新***///
    /*用户存取时更新用户未质押Ktoken的值和Ktoken的总供应量
    function renewKtoken(address _ktoken,address _user,int _amount) private{
        ktokenUnlock[_ktoken][_user] += _amount;
        infoOfKtoken[_ktoken].totalsupply += _amount;
    }*/
    //转入/转出 Ktoken
    function addKtoken(address _ktoken,address _user,uint _amount) private{
        ktokenUnlock[_ktoken][_user] += _amount;
        infoOfKtoken[_ktoken].totalsupply += _amount;
    }
    function reduceKtoken(address _ktoken,address _user,uint _amount) private{
        ktokenUnlock[_ktoken][_user] -= _amount;
        infoOfKtoken[_ktoken].totalsupply -= _amount;
    }
    /*根据标的资产地址和数量，更新用户债务的base和index
    function renewDebt(address _token,address _user,uint256 _amount) private{
        //根据兑换率和标的资产数量得到Ktoken的数量
        address _ktoken = tokenToktoken[_token];
        uint256 _ktokenamount = _amount / getExchangeRate(_ktoken);
        uint256 _oldDebt = getOneDebtVaule()
        //debt memory new_debt;
        //更新用户债务
        debt memory old_debt = getNowDebtAmount(_user,_ktoken);
        debt memory new_debt;
        new_debt.base = old_debt.base + _ktokenamount;
        new_debt.index = ktokenIndex[_ktoken];
        userDebt[_ktoken][_user] = new_debt;
    }*/
    function addDebt(address _token,address _user,uint256 _amount) private{
        //根据兑换率和标的资产数量得到Ktoken的数量
        address _ktoken = tokenToktoken[_token];
        uint256 _ktokenAmount = _amount / getExchangeRate(_ktoken);
        //增加用户Ktoken债务：新债务 = 老债务本息合 + 借走的Ktoken数量
        uint256 _oldDebtAmount = getOneDebtAmount(_user,_token);
        debt memory _newDebt;
        _newDebt.base = _oldDebtAmount + _ktokenAmount;
        _newDebt.index = infoOfKtoken[_ktoken].index;
        userDebt[_ktoken][_user] = _newDebt;
    }
    function reduceDebt(address _token,address _user,uint256 _amount) private{
        //根据兑换率和标的资产数量得到Ktoken的数量
        address _ktoken = tokenToktoken[_token];
        uint256 _ktokenAmount = _amount / getExchangeRate(_ktoken);
        //减少用户Ktoken债务：新债务 = 老债务本息合 - 偿还的的Ktoken数量
        uint256 _oldDebtAmount = getOneDebtAmount(_user,_token);
        debt memory _newDebt;
        _newDebt.base = _oldDebtAmount - _ktokenAmount;
        _newDebt.index = infoOfKtoken[_ktoken].index;
        userDebt[_ktoken][_user] = _newDebt;
    }


                            ///***辅助计算函数***///
    //token和Ktoken的兑换率= (borrow+cash-reserve)/totalsupply
    function getExchangeRate(address _ktoken) public view returns(uint256 _exchangerate){
        address _token = ktokenTotoken[_ktoken];
        ktokenInfo memory ktokeninfo=infoOfKtoken[_ktoken];
        tokenInfo memory tokeninfo = infoOfToken[_token];
        if(ktokeninfo.totalsupply == 0){
            _exchangerate = INITAL_EXCHANGERATE;
        }
        else{
            _exchangerate =(tokeninfo.borrow + tokeninfo.cash-tokeninfo.reserve)/ktokeninfo.totalsupply;
        }
        return _exchangerate;
    }
    //得到用户当欠的Ktoken数量
    function getOneDebtAmount(address _user,address _ktoken) public view returns (uint256 _nowamount){
        debt memory debt = userDebt[_ktoken][_user];
        if(debt.index == 0){
            _nowamount = 0;
        }
        else{
            _nowamount = debt.base * infoOfKtoken[_ktoken].index / debt.index; 
        }
        return _nowamount;
    }
    //得到用户欠的某一ktoken价值
    function getOneDebtVaule(address _user,address _ktoken)  public view returns(uint256 _nowDebt){
        //得到token地址
        address _token = ktokenTotoken[_ktoken];    
        //计算此时所欠的Ktoken数量
        uint256 _amount = getOneDebtAmount(_user,_ktoken);
        //债务 = ktoken数量 * 兑换率 * token价格
        _nowDebt = _amount * getExchangeRate(_ktoken) * price[_token];
        return _nowDebt;
    }
    //得到用户所欠的所有ktoken价值
    function getAllDebtVaule(address _user)  public view returns(uint256 _alldebt){
        //得到所有Ktoken
        address[] memory _allKtoken = allKtoken;
        //循环执行getOneDebtVaule函数，得到总债务
        for(uint256 i =0;i < _allKtoken.length;i++){
            debt memory debt = userDebt[_allKtoken[i]][_user];
            if(debt.base == 0) break;
            _alldebt+=getOneDebtVaule(_user,_allKtoken[i]);
        }
        return _alldebt;
    }
    // 根据转入的token数量，计算返回的kToken数量
    function getKTokenAmount(address _token,uint256 _amount) public view returns(address,uint256){
        address _ktoken = tokenToktoken[_token];
        uint256 _ktokenAmount = _amount / getExchangeRate(_ktoken);
        return(_ktoken,_ktokenAmount);
    }
    //得到用户的总质押物价值
    function getUserCollateralValue(address _user)public view returns(uint256 _sumvalue){
        //得到用户所有Ktoken地址
        address[] memory _allKtoken = allKtoken;
        //求质押的总价值
        for(uint i = 0;i<_allKtoken.length;i++){
            //由ktoken地址得到token地址
            address _token = ktokenTotoken[_allKtoken[i]];
            //得到质押的Ktoken数量
            uint _amount = ktokenlock[_allKtoken[i]][_user];
            //总价格 = sum{Ktoken数量 * 兑换率 * token价格 * 质押率}
            _sumvalue += _amount * getExchangeRate(_allKtoken[i]) * price[_token] * infoOfKtoken[_allKtoken[i]].collateralrate /1000;
        }
        return _sumvalue;
    }
    //计算可清算最大标的资产数量
    function accountLiquity(address _borrowAddress, address _token)public view returns(uint256 _amount,uint256 _ktokenAmount,address _ktoken){
        _ktoken = tokenToktoken[_token];
        //得到Ktoken债务
        _ktokenAmount = getOneDebtAmount(_borrowAddress,_ktoken) * LIQUIDITY_RATE / 1000;
        //得到token债务
        _amount = _ktokenAmount * getExchangeRate(_ktoken);
        return(_amount,_ktokenAmount,_ktoken);
    }
    //得到token的当前借贷利率
    function getBorrowRate(address _token)public view returns(uint256 _borrowRate){
        address _ktoken = tokenToktoken[_token];
        uint256 _borrow = infoOfToken[_token].borrow;
        uint256 _cash = infoOfToken[_token].cash;
        // y = kx + b x为资金利用率
        _borrowRate = ktokenModel[_ktoken].k * getUseRate(_borrow,_cash) + ktokenModel[_ktoken].b;
        return _borrowRate;
    }
    //得到当前资金利用率
    function getUseRate(uint _borrow,uint _cash)public view returns(uint256 _useRate){
        if( _borrow == 0 ){
            _useRate = 0;
        }
        else{
            _useRate = _borrow / (_borrow + _cash);
        }
        return _useRate;
    }
    //根据区块变化和先前的利息指数得到新的利息指数
    function getNowIndex(uint256 _oldIndex,uint256 _deltaTime,address _ktoken) public view returns(uint256 _newIndex){
        uint256 _borrowRate = getBorrowRate(_ktoken);
        uint256 inter = _deltaTime * _borrowRate;
        _newIndex = _oldIndex + inter;
        return _newIndex;
    }


                            ///***改变状态变量的函数***///
    //根据liquidity偿还的ktoken数量，从借款者向清算者转移ktoken
    function liquityReward(address _liquidity,address _borrower,address _ktoken,uint256 _amount) private {
        uint256 _actualamount = _amount * LIQUIDITY_REWARD /1000;
        ktokenUnlock[_ktoken][_borrower]-=_actualamount;
        ktokenUnlock[_ktoken][_liquidity]+=_actualamount;
    }
    //
    function addCollateral(address _ktoken,address _user,uint _amount) private {
        ktokenlock[_ktoken][_user]+=_amount;
        ktokenUnlock[_ktoken][_user]-=_amount;
    }
    function reduceCollateral(address _ktoken,address _user,uint _amount) private {
        ktokenlock[_ktoken][_user] -= _amount;
        ktokenUnlock[_ktoken][_user] += _amount;
    }

    function addCash(address _token,uint256 _amount)private{
        uint256 _cashNow = infoOfToken[_token].cash;
        require((_cashNow + _amount) >=_amount && (_cashNow +_amount) >=_amount,"amount too big");
        infoOfToken[_token].cash += _amount;
    }
    function reduceCash(address _token,uint256 _amount)private{
        uint256 _cashNow = infoOfToken[_token].cash;
        require(_cashNow > _amount,"cash insufficient");
        infoOfToken[_token].cash -= _amount;
    }
    function addBorrow(address _token,uint256 _amount) private{
        uint256 _borrowNow = infoOfToken[_token].borrow;
        infoOfToken[_token].borrow = _borrowNow + _amount;
    }
    function reduceBorrow(address _token,uint256 _amount) private{
        uint256 _borrowNow = infoOfToken[_token].borrow;
        require(_borrowNow >= _amount,"too much");
        infoOfToken[_token].borrow -= _amount;
    }


                            ///***验证函数***///
    //验证用户的（总质押物价值-总债务）>=所借金额
    function verifyBorrowCapacity(address _user,address _token,uint256 _amount) public view returns(uint){
        //要借的价值
        uint256 _borrowValue = _amount * price[_token];
        //总质押物价值
        uint256 _collateralValue = getUserCollateralValue(_user);
        //总债务价值
        address _ktoken = tokenToktoken[_token];
        uint256 _allDebt = getAllDebtVaule(_user);
        //返回净值
        return(_collateralValue - _allDebt - _borrowValue);
    }
                            ///***计息***///
    function accurateInterest(address _token)public {
        //节省gas
    
        address _ktoken = tokenToktoken[_token];
        ktokenInfo memory _ktokenInfo = infoOfKtoken[_ktoken];
        tokenInfo memory _tokenInfo = infoOfToken[_token];
        uint _borrow = _tokenInfo.borrow;
        uint _cash = _tokenInfo.cash;
        uint _reserve = _tokenInfo.reserve;
        uint _totalSupply = _ktokenInfo.totalsupply;
        uint _useRate = getUseRate(_borrow,_cash);
        uint _borrowRate = getBorrowRate(_token);
        uint _oldIndex =_ktokenInfo.index;
        //得到变化的区块数量
        uint _blockNumberNow = block.number;
        uint _deltaBlock = _blockNumberNow - _ktokenInfo.blockNumber;
        if(_deltaBlock != 0){
            //更新blockNumber和index
            _ktokenInfo.blockNumber = _blockNumberNow;
            _ktokenInfo.index = getNowIndex(_ktokenInfo.index,_deltaBlock,_ktoken);
            //利息 = borrow * （_newindex/_oldIndex）
            if(_borrow!= 0){
                uint _interest = _borrow * _ktokenInfo.index / _oldIndex;
                _reserve += _interest * RESERVER_RATE / 1000;
                _borrow += _interest * (1000 - RESERVER_RATE) / 1000;
                _tokenInfo.reserve = _reserve;
                _tokenInfo.borrow  = _borrow;
            }
        }
    }

}

interface IERC20{
    function name() external view;
    function symbol() external view ;
    function decimals() external view;
    function totalSupply() external view;
    function balanceOf(address owner) external view;
    function allowance(address owner, address spender) external view;
    function approve(address spender, uint value) external;
    function transfer(address to, uint value) external;
    function transferFrom(address from, address to, uint value) external;
}
interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}