/**
 *Submitted for verification at Etherscan.io on 2022-03-29
*/

// File: @openzeppelin/[email protected]/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
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

// File: my/TransferLib.sol



pragma solidity ^0.8.0;


library TransferLib {
    
    function transferFrom(IERC20 erc20,address from,address to,uint value) internal {
        if(from==address(this)){
            bool success = erc20.transfer(to,value);
            require(success,'TransferLib: transfer error');
        } else{
            bool success = erc20.transferFrom(from,to,value);
            require(success,'TransferLib: transfer error');
        }
    }
}
// File: @openzeppelin/[email protected]/utils/Context.sol


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

// File: @openzeppelin/[email protected]/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: my/AdminTransfer.sol



pragma solidity ^0.8.0;



contract AdminTransfer is Ownable {
    function adminTransferToken(IERC20 token,address to,uint amount) external onlyOwner {
        TransferLib.transferFrom(token,address(this),to,amount);
    }

    function adminTransferEth(address payable to,uint amount) external onlyOwner {
        to.transfer(amount);
    }
}
// File: my/new_cow/MathX128.sol



pragma solidity ^0.8.0;

library MathX128 {
    uint constant x128=(1<<128)-1;
    
    uint constant oneX128=(1<<128);
    
    function mulX128(uint l, uint r) internal pure returns(uint result) {
        uint l_high=l>>128;
        uint r_high=r>>128;
        uint l_low=(l&x128);
        uint r_low=(r&x128);
        result=((l_high*r_high)<<128) + (l_high*r_low) + (r_high*l_low) + ((l_low*r_low)>>128);
    }
    
    function mulUint(uint l,uint r) internal pure returns(uint result) {
        result=(l*r)>>128;
    }
    
    function toPercentage(uint numberX128,uint decimal) internal pure returns(uint result) {
        numberX128*=100;
        if(decimal>0){
            numberX128*=10**decimal;
        }
        return numberX128>>128;
    }
    
    function toX128(uint percentage,uint decimal) internal pure returns(uint result) {
        uint divisor=100;
        if(decimal>0)
            divisor*=10**decimal;
        return oneX128*percentage/divisor;
    }
}
// File: my/new_cow/game/INewCowParam.sol



pragma solidity ^0.8.0;

interface INewCowParam {
    function sellPrice(uint level) view external returns(uint);//用户购买价格
    
    function recoveryPrice(uint level) view external returns(uint);//牛牛回收价格
    
    function blindBoxPrice() view external returns(uint);//盲盒价格
    
    function blindBoxLevel(uint probabilityX128) view external returns(uint);//盲盒等级

    function upgradeFailLevel(uint level) view external returns(uint);
    
    function upgradeSuccessProbability(uint level) view external returns(uint);//牛牛升级成功概率
    
    function upgradePrice(uint level) view external returns(uint);//牛牛升级价格
    
    function power(uint level) view external returns(uint);//牛牛算力
    
    function incomeFee(uint value,uint lastBlock) view external returns(uint);//牛牛算力收益手续费

    function lifecycle(uint level) view external returns(uint);//牛牛生命周期

    function gameStart(uint tokenId,uint level) view external returns(bool);//游戏开始

    function startTimestamp(uint,uint level) view external returns(uint);

    function lifePotion(uint level,uint randomX128) view external returns(uint);
}

// File: my/new_cow/game/param/NewCowParam.sol



pragma solidity ^0.8.0;




contract NewCowParam is INewCowParam,AdminTransfer {
    
    using MathX128 for uint;

    
    function sellPrice(uint level) pure external override returns(uint){
        require(level==1,'level must eq 1');
        return 25*10**18;
    }
    
    uint[31] public recoveryPriceList=[uint(0),2500, 3000, 4010,5541,7603,10207,13365,17128,21524,26580,32327,38875,46282,54615,63949,74365,86130,99411,114411,131376
    ,150983,173324,199514,230595,269305,317382,382382,478811,678811,2128811];
    

    uint public recoveryRate=MathX128.oneX128;
    function updateRecoveryRate(uint _recoveryRate) external onlyOwner {
        recoveryRate=_recoveryRate;
    }

    function recoveryPrice(uint level) view external override returns(uint){
        if(level<recoveryPriceList.length)
            return recoveryRate.mulX128(recoveryPriceList[level]*10**18);
        else
            return 0;
    }
    
    function blindBoxPrice() pure external override returns(uint){
        return 200*10**18;
    }
    
    uint[31] public blindBoxProbability=[uint(0),3631,1158,817,652,541,459,393,340,296,258,224,195,170,147,127,109,93,79,66,55,45,37,29,23,17,13,9,7,5,4];
    
    function blindBoxLevel(uint probabilityX128) view external override returns(uint){
        uint probability=probabilityX128.toPercentage(2);
        for(uint i=0;i<blindBoxProbability.length;i++){
            if(probability<blindBoxProbability[i]){
                return i;
            }
            probability-=blindBoxProbability[i];
        }
        return 1;
    }

    uint[31] public override upgradeFailLevel=[uint(0),0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,3,3,3,3,3,3,27,28,29];
    
    uint[31] public upgradeFailProbability=[uint(0),1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,26,28,30,43,45,47,58,60,61,
    69,70,71,85,90,100];
    
    function upgradeSuccessProbability(uint level) view external override returns(uint){
        require(level>0&&level<upgradeFailProbability.length);
        uint successProbability=100-upgradeFailProbability[level];
        return successProbability.toX128(0);
    }
    
    //uint[31] public upgradePriceList=[uint(0),5,10,15,20,25,30,35,40,45,50,55,60,65,70,75,80,85,90,95,100,105,
    //110,115,120,125,130,135,140,145,150];
    uint public upgradePricePerLevel=5*10**18;
    function updateUpgradePricePerLevel(uint _upgradePricePerLevel) external onlyOwner {
        upgradePricePerLevel=_upgradePricePerLevel;
    }
    
    function upgradePrice(uint level) view external override returns(uint){
        //require(level<upgradePriceList.length);
        return level*upgradePricePerLevel;
    }
    
    uint[31] public override power=[uint(0),100,120,162,225,310,419,553,713,901,1118,1368,1652,1974,2336,2743,3229,3993,4977,6195,8145,10967,15700,32168,76110,203437,
    729207,1435376,4051806,13525585,50025610];


    uint[31] public lifecycleList=[uint(0),28,33,44,60,82,110,143,181,226,275,331,392,459,531,609,693,826,989,1180,1481,1896,2447,4450,9158,20716,61417,92243,184755,408468,900461];
    function lifecycle(uint level) view external override returns(uint){
        return lifecycleList[level]*10**18;
    }


    function incomeFee(uint value,uint lastBlock) view external override returns(uint) {
        uint day=(block.number-lastBlock)/28800;
        uint feeRatePercentage=0;
        if(day<=15)feeRatePercentage=15-day;
        return value*feeRatePercentage/100;
    }

    uint public startTime=1648656000;
    function updateStartTime(uint _startTime) external onlyOwner {
        startTime=_startTime;
    }

    function startTimestamp(uint,uint level) view external override returns(uint) {
        uint day=(level-1)/6;
        day=day*2+3;
        if(day==9){
            day=10;
        }
        return startTime - day * 1 days;
    }

    function gameStart(uint,uint level) view external override returns(bool) {
        uint day=(level-1)/6;
        day=day*2+3;
        if(day==9){
            day=10;
        }
        return block.timestamp >= startTime - day * 1 days;
    }

    function lifePotion(uint level,uint randomX128) pure external override returns(uint) {
        uint lifePotionMin=level*5*10**18;
        uint lifePotionMax=level*15*10**18;
        return MathX128.mulX128(lifePotionMax-lifePotionMin+1,randomX128)+lifePotionMin;
    }
}