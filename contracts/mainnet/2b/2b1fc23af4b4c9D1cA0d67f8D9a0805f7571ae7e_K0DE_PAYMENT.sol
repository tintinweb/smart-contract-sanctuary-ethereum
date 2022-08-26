/**
 *Submitted for verification at Etherscan.io on 2022-08-26
*/

// SPDX-License-Identifier: UNLICENSED
// k0de.app payment contract
pragma solidity ^0.8.16;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from,address to,uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
interface IRouter {
    function factory() external pure returns (address);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function WETH() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline) external;
}
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
library Address{
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

contract K0DE_PAYMENT is Ownable{
    using Address for address payable;

    IERC20 private _k0deContract;
    IRouter private _router;
    address private _DEAD = 0x000000000000000000000000000000000000dEaD;
    address private _STABLECOIN ;
    uint256 private _stablecoinDecimal;

    uint256 public totalk0deTokensPaid;
    uint256 public totalTokensBurned;

    struct Service{
        address deployer;
        string name;
        uint256 rateInUSD;
        bool isPaused;
    }
    uint public serviceID = 0;
    mapping(uint => Service) public services;

    struct Subscription{
        address subscriber;
        bool isCancelled;
        uint256 subscriptionStarted;
    }
    mapping(address => mapping(uint => Subscription)) public subscriptions;


    constructor(){
        _k0deContract = IERC20(0x250050ACD30e382A39b00f2D172058160050A9E4);
        _router = IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _STABLECOIN = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
        _stablecoinDecimal = 6;
    }

    function getTokensAmount(uint256 usdAmount) public view returns(uint256){
        address[] memory path = new address[](3);
        path[0] = _STABLECOIN;
        path[1] = _router.WETH();
        path[2] = address(_k0deContract);
        uint[] memory amounts = new uint[](2);
        amounts = _router.getAmountsOut(usdAmount * 10**_stablecoinDecimal,path);  
        return amounts[2];
    }

    function getContractsRelated() public view returns(address k0deContract, address stableCoinContract, address routerContract){
        return (address(_k0deContract),_STABLECOIN,address(_router));
    }

    function getRateForAllServices() public view returns(uint256[] memory){
        uint[] memory rates = new uint[](serviceID);
        for (uint i = 0 ; i < serviceID; i++){
            rates[i] = getTokensAmount(services[i].rateInUSD);
        }
        return rates;
    }

    function getAllSubscriptions(address subscriber) public view returns(Subscription[] memory){
        Subscription[] memory subscriptions_ = new Subscription[](serviceID);
        for(uint i = 0 ; i < serviceID; i++){
            subscriptions_[i] = subscriptions[subscriber][i];
        }
        return subscriptions_;
    }
    
    function initializeBurn(uint256 tokensToBurn_EXACT) external onlyOwner{
        _k0deContract.transfer(_DEAD,tokensToBurn_EXACT * 10**9);
        totalTokensBurned+= tokensToBurn_EXACT * 10**9;
        emit TokensBurned(tokensToBurn_EXACT);
    }

    function initializeRescue(address receiver,uint256 tokensToRescue_EXACT) external onlyOwner{
        _k0deContract.transfer(receiver,tokensToRescue_EXACT * 10**9);
        emit TokensRescued(receiver,tokensToRescue_EXACT);
    }

    function setStableCoinAddress(address stableCoinAddress, uint8 stableCoinDecimal) external onlyOwner{
        _STABLECOIN = stableCoinAddress;
        _stablecoinDecimal = stableCoinDecimal;
    }

    function subscribeToService(uint256 serviceID_) external returns(bool){
        Service storage _service = services[serviceID_];
        require(!_service.isPaused,"Service is paused at the moment.");
        require(_service.deployer != address(0), "Service doesn't exist");

        uint256 paymentAmount = getTokensAmount(_service.rateInUSD);
        _k0deContract.transferFrom(_msgSender(),address(this),paymentAmount);
        totalk0deTokensPaid+=paymentAmount;

        subscriptions[_msgSender()][serviceID_] = Subscription(_msgSender(),false,block.timestamp);
        
        emit SubscriptionCreated(_msgSender(),serviceID_,paymentAmount);
        return true;
    }

    function owner_AddService(string memory name_, uint rateInUSD_) external onlyOwner{
        require(_msgSender() != address(0),"Deployer cannot be null address");
        services[serviceID] = Service(_msgSender(),name_,rateInUSD_,false);
        serviceID++;
        emit ServiceCreated(_msgSender(),name_,rateInUSD_);
    }

    function owner_UpdateServiceRate(uint256 serviceID_,uint256 newRateInUSD_) external onlyOwner{
        services[serviceID_].rateInUSD = newRateInUSD_;
        emit ServiceRateUpdated(serviceID, newRateInUSD_);
    }

    function owner_UpdateServiceStatus(uint256 serviceID_,bool isPaused_) external onlyOwner{
        services[serviceID_].isPaused = isPaused_;
        emit ServiceStatusUpdated(serviceID_, isPaused_);
    }

    function owner_CancelSubscription(address subscriber, uint256 serviceID_,bool isCancelled_) external onlyOwner{
        subscriptions[subscriber][serviceID_].isCancelled = isCancelled_;
        emit SubscriptionCancelled(subscriber);
    }

    event ServiceCreated(address deployer,string name,uint rateInUSD);
    event ServiceRateUpdated(uint256 serviceID, uint256 newRateInUSD);
    event ServiceStatusUpdated(uint256 serviceID, bool isPaused);

    event SubscriptionCreated(address subscriber,uint256 serviceID,uint256 tokenPayment);
    event SubscriptionCancelled(address subscriber);

    event TokensBurned(uint256 tokensAmount);
    event TokensRescued(address receiver, uint256 tokensAmount);
}