pragma solidity ^0.4.24;

// *-----------------------------------------------------------------------*
//       __ _    ________   __________  _____   __
//      / /| |  / / ____/  / ____/ __ \/  _/ | / /
//     / / | | / / __/    / /   / / / // //  |/ / 
//    / /__| |/ / /___   / /___/ /_/ // // /|  /  
//   /_____/___/_____/   \____/\____/___/_/ |_/  
// *-----------------------------------------------------------------------*


/**
 * @title SafeMath
 */
library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {

        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {

        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {

        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {

        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}


/**
 * @title Ownable
 */
contract Ownable {

    address public owner;
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() public{
        owner = msg.sender;
    }

    // Modifier onlyOwner
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    // Transfer owner
    function transferOwnership(address _newOwner) public onlyOwner {

        // not invalid address
        require(_newOwner != address(0));
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}



/**
 * @title Pausable
 */
contract Pausable is Ownable {

    event Pause();
    event Unpause();

    bool public paused = false;

    modifier whenNotPaused {
        require(!paused);
        _;
    }
    modifier whenPaused {
        require(paused);
        _;
    }

    // Pause contract
    function pause() public onlyOwner whenNotPaused returns (bool) {

        paused = true;
        emit Pause();
        return true;
    }

    // Unpause contract
    function unpause() public onlyOwner whenPaused returns (bool) {

        paused = false;
        emit Unpause();
        return true;
    }

}



// TODO:??????????????????
interface LVECoin {
    function transfer(address _to, uint256 _value) external returns(bool);
    function balanceOf(address _owner) external view returns (uint256);
}



/**
 * @title PrivateSale
 */
contract PrivateSale is Pausable {

    using SafeMath for uint256;


    // Token contract
    LVECoin private tokenContract;
    // ??????Token??????
    uint256 private totalToken       = 2000000000 * (10 ** 18);
    // ??????Token?????????
    uint256 private tokenSoldThreshold   = totalToken.mul(100).div(1000);
    // ??????Token??????
    uint256 public tokenSupplyQuota  = 0;


    // ??????????????????
    uint256 public startTime        = now;
    // ??????????????????
    uint256 public endTime          = now + 1 days;
    // ?????????????????????
    uint256 public lockEndTime      = now + 2 days;
    //3500 LVE tokens per 1 ETH
    uint256 public tokenPrice       = 3500;

    // (??????????????????/wei)amount of eth crowded in wei
    uint256 public weiCrowded;
    // ???????????????token??????
    uint256 public tokensSold;
    address private walletAddr;

    // ?????????
    struct Investor{
        uint256 endTime;    // token locked end time
        address addr;       // locked address
        bool isLocked;      // is lock address
        uint256 lockAmount; // locked token amount
    }
    // investor mapping
    mapping(address => Investor) public investorMap;
    // freeze account mapping
    mapping(address => bool) public freezeAccountMap;
    // investor address list
    address[] public investorsList;


    event Lock(address indexed _locker, uint256 _value, uint _endTime);
    event UnLock(address indexed _unlocker, uint256 _value);
    event Freeze(address indexed _freezeAddr);
    event Unfreeze(address indexed _unfreezeAddr);
    event WithdrawalToken(address indexed _to, uint256 _amount);
    event WithdrawalEther(address indexed _to, uint256 _amount);


    constructor(address _tokenAddr) public{

        require(_tokenAddr != address(0));
        tokenContract = LVECoin(_tokenAddr);
        walletAddr = msg.sender;
    }


    // ????????????
    modifier isInSaleTime {
        require(now >= startTime && now <= endTime);
        _;
    }
    // ???????????????
    modifier isSoldOut() {
        // ???????????????token?????? < ??????Token?????? => true, ????????????
        require(tokensSold < tokenSupplyQuota);
        _;
    }
    // ??????Token?????????????????????????????????
    modifier isCanSold(){
        _getContractTokenBalance();
        require(tokenSupplyQuota >= tokenSoldThreshold);
        _;
    }


    // Is exceed lockEnd time
    modifier freezeable(address _addr) {
        require(!freezeAccountMap[_addr]);
        _;
    }

    // get contract own token amount
    function getContractTokenBalance() public  returns(uint256 _rContractTokenAmount){
        
        _getContractTokenBalance();
        return tokenSupplyQuota;
    }
    function _getContractTokenBalance() internal returns(bool){

        tokenSupplyQuota = tokenContract.balanceOf(address(this));
        return true;
    }



    // investor paid Ether , Ether to contract and locktime token
    // if in sale time , then can paid ether to buy token
    function() payable isInSaleTime isCanSold isSoldOut whenNotPaused freezeable(msg.sender) public {

        require(msg.sender != address(0));
        // crowd wei
        uint256 weiAmount = msg.value;
        weiCrowded = weiCrowded.add(weiAmount);
        walletAddr.transfer(weiAmount);
        emit WithdrawalEther(walletAddr, msg.value);

        // ???????????????token??????
        uint256 investToken = calculateToken(weiAmount);
        tokensSold = tokensSold.add(investToken);
        // ???????????????????????????Token??????
        require(tokensSold <= tokenSupplyQuota);
        // add investor token locktime
        setNewlockAccount(msg.sender, lockEndTime, investToken);
    }


    // ???????????????Token + ?????????
    function transferTokenAndLock(address _beneficiary, uint256 _amount) public onlyOwner isCanSold isSoldOut{

        require(_beneficiary != address(0));
        // ???????????????token??????
        tokensSold = tokensSold.add(_amount);
        // ???????????????????????????Token??????
        require(tokensSold <= tokenSupplyQuota);
        // add investor token locktime
        setNewlockAccount(_beneficiary, lockEndTime, _amount);
    }


    // locked warehouse function 
    function setNewlockAccount(address _lockAddr, uint256 _endTime, uint256 _lockAmount) internal returns(bool){
        
        require(_lockAddr != address(0));
        require(_endTime >= now);
        require(_lockAmount > 0);

        // TODO:?????????????????????????????????
        // ??????????????????locker list
        if(investorMap[_lockAddr].addr != _lockAddr){
            investorsList.push(_lockAddr);
        }

        Investor memory investor;
        investor.endTime = _endTime;
        investor.addr = _lockAddr;
        investor.isLocked = true;
        // TODO:?????????????????????????????????
        investor.lockAmount = investorMap[_lockAddr].lockAmount.add(_lockAmount);
        investorMap[_lockAddr] = investor;

        emit Lock(_lockAddr, _lockAmount, _endTime);
        return true;
    }


    // ??????Token?????? = ???????????? * 1 Ether(1*10^18)
    function calculateToken(uint256 weiAmount) internal view returns(uint256 _rInvestToken){

        // exchange token quantity
        uint256 investToken = weiAmount.mul(tokenPrice);
        return investToken;
    }

    // get single investor invest information
    function getSingleInvestor(address _addr) public view returns(uint256 _rEndTime, address _rAddr, bool _rIsLocked, uint256 _rLockAmount){

        require(_addr != address(0));
        Investor memory investor = investorMap[_addr];
        return(investor.endTime, investor.addr, investor.isLocked, investor.lockAmount);
    }

    // get investor count
    function getInvestorCount() public view returns(uint256 _rInvestorCount){

        return investorsList.length;
    }

    // get investor address
    function getInvestorAddr(uint256 _index) public view returns(address _rInvestorAddr){

        return investorsList[_index];
    }



    // after locktime  Token??????
    function withdrawTokenToInvestor() public whenNotPaused freezeable(msg.sender) returns(bool){

        require(msg.sender != address(0));
        require(now > lockEndTime);
        
        Investor memory investor = investorMap[msg.sender];
        if(investor.isLocked && now > investor.endTime){

            require(tokenContract.transfer(investor.addr, investor.lockAmount));
            emit WithdrawalToken(investor.addr, investor.lockAmount);
            investor.endTime = 0;
            investor.isLocked = false;
            investor.lockAmount = 0;
            investorMap[investor.addr] = investor;
            emit UnLock(investor.addr, investor.lockAmount);
        }
        return true;
    }


    // after locktime owner Token??????
    function withdrawTokenToInvestorOwner(address _investorAddr) public onlyOwner returns(bool){

        require(_investorAddr != address(0));
        require(now > lockEndTime);
        
        Investor memory investor = investorMap[_investorAddr];
        if(investor.isLocked && now > investor.endTime && !freezeAccountMap[investor.addr]){

            require(tokenContract.transfer(investor.addr, investor.lockAmount));
            emit WithdrawalToken(investor.addr, investor.lockAmount);
            investor.endTime = 0;
            investor.isLocked = false;
            investor.lockAmount = 0;
            investorMap[investor.addr] = investor;
            emit UnLock(investor.addr, investor.lockAmount);
        }
        return true;
    }


    // after locktime batch Token??????
    function withdrawBatchTokenToInvestor() public onlyOwner returns(bool){

        require(now > lockEndTime);

        // count investor nums
        uint256 investorCount = getInvestorCount();
        require(investorCount > 0);
        for (uint256 i = 0; i < investorCount; i++) {
            address investorAddr = investorsList[i];
            Investor memory investor = investorMap[investorAddr];
            if(investor.isLocked && now > investor.endTime && !freezeAccountMap[investor.addr]){

                require(tokenContract.transfer(investor.addr, investor.lockAmount));
                emit WithdrawalToken(investor.addr, investor.lockAmount);
                investor.endTime = 0;
                investor.isLocked = false;
                investor.lockAmount = 0;
                investorMap[investor.addr] = investor;
                emit UnLock(investor.addr, investor.lockAmount);
            }
        }
        return true;
    }



    // freeze account
    function freezeAccount(address _freezeAddr) public onlyOwner returns (bool) {

        require(_freezeAddr != address(0));
        freezeAccountMap[_freezeAddr] = true;
        emit Freeze(_freezeAddr);
        return true;
    }
    
    // unfreeze account
    function unfreezeAccount(address _freezeAddr) public onlyOwner returns (bool) {

        require(_freezeAddr != address(0));
        freezeAccountMap[_freezeAddr] = false;
        emit Unfreeze(_freezeAddr);
        return true;
    }


    // TODO: ????????????Token to wallet address
    // TODO: ?????????????

}