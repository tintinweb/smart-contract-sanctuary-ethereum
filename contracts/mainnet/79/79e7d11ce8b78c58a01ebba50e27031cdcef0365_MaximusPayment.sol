/**
 *Submitted for verification at Etherscan.io on 2022-11-02
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;
interface IERC20 {
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function getOwner() external view returns (address);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address _owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}
abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
contract MaximusPayment is Ownable{
    mapping (address=>uint) public basicAccessUntil;
    mapping (address=>uint) public premiumAccessUntil;
    IERC20 WETH;
    address tokenPair;
    IERC20 public Token;
    address USDPair;
    IERC20 USD;

    uint public BasicPrice=200;
    uint public PremiumPrice=350;
    uint public LifetimeAccessMultiplier=1000000;
    address stakingAddress;
    function setStaking(address staking) external {
        stakingAddress=staking;
    }
    function Setup(address WETH_, address Token_, address USD_, address tokenPair_, address USDPair_) public onlyOwner {
        WETH=IERC20(WETH_);
        Token=IERC20(Token_);
        USD=IERC20(USD_);
        tokenPair=tokenPair_;
        USDPair=USDPair_;
    }
    function setValues(uint basic,uint premium, uint lifetimeMultiplier) external onlyOwner{
        BasicPrice=basic;
        PremiumPrice=premium;
        LifetimeAccessMultiplier=lifetimeMultiplier;
    }

    function getTokenPer100Dollar() public view returns (uint){
        uint dollarBalance=USD.balanceOf(USDPair)*10**12;
        uint wethDollarBalance= WETH.balanceOf(USDPair);
        uint wethTokenBalance=WETH.balanceOf(tokenPair);
        uint tokenBalance=Token.balanceOf(tokenPair);
        uint wethAmount=100*10**18*wethDollarBalance/dollarBalance;
        return wethAmount*tokenBalance/wethTokenBalance;
    }
    function transferTokensToTarget() external {
        uint balance=Token.balanceOf(address(this));
        Token.transferFrom(msg.sender,address(0xdead),balance/2);
        Token.transferFrom(msg.sender,stakingAddress,balance/2);
    }
    event OnBuyBasicAccess(address account);
    function payBasic() external{
        uint cost=getTokenPer100Dollar()*BasicPrice/100;
        address msgSender=msg.sender;
        Token.transferFrom(msgSender,address(this),cost);
        if(basicAccessUntil[msgSender]>block.timestamp){
            basicAccessUntil[msgSender]+=30 days;
        }
        else{
            basicAccessUntil[msgSender]=block.timestamp+30 days;
        }
        emit OnBuyBasicAccess(msgSender);
    }    
        event OnBuyPremiumAccess(address account);
    function payPremium() external{
        uint cost=getTokenPer100Dollar()*PremiumPrice/100;
        address msgSender=msg.sender;
        Token.transferFrom(msgSender,address(this),cost);
        if(premiumAccessUntil[msgSender]>block.timestamp){
            premiumAccessUntil[msgSender]+=30 days;
        }
        else{
            premiumAccessUntil[msgSender]=block.timestamp+30 days;
        }
        emit OnBuyPremiumAccess(msgSender);
    }
    event OnBuyLifetimeAccess(address account);
    function payLifetime() external{
        uint cost=getTokenPer100Dollar()*PremiumPrice*LifetimeAccessMultiplier/10000;
        address msgSender=msg.sender;
        Token.transferFrom(msgSender,address(this),cost);
        premiumAccessUntil[msgSender]=type(uint).max;
        emit OnBuyLifetimeAccess(msgSender);
    }
    function canUseSniper(address account) external view returns(bool){
        return (basicAccessUntil[account]>=block.timestamp||premiumAccessUntil[account]>=block.timestamp);
    }
    function canUsePremiumSniper(address account) external view returns(bool){
        return (premiumAccessUntil[account]>=block.timestamp);
    }

    





}