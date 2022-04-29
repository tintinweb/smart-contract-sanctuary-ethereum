// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;
import "./IRVKToken.sol";
// import "IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import "../.deps/npm/@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./abstractRVK.sol";
contract RationVitranKendra is abstractRVK {    
    uint public totalPulses=10000;// item quantity in Kg 
    uint public totalRice=10000;
    uint public totalWheat=10000;
    uint8 public pulsesDistribute=5; //item quantity to be distribute per user 
    uint8 public riceDistribute=5;
    uint8 public wheatDistribute=5;
    uint public itemNextDuePeriod=2592000;// 30 days =2592000 sec.
    uint public charityNextWithdraw=2592000;
    uint16 public givenToken=100;
    uint public renewTime=15552000;//180 days in seconds
   
    struct itemsPrice{
        uint pulsesPrice;
        uint ricePrice;
        uint wheatPrice;
    }

    struct PulsesStr {
        uint nextDue;
        uint userPulses;
    }

    struct RiceStr {
        uint nextDue;
        uint userRice;
    }
    
    struct WheatStr {
        uint nextDue;
        uint userWheat;
    }

    struct User{
        address userAddress;
        bool isActive; //status of user
        uint nextRenewTime;
        PulsesStr pulsesInfo;
        RiceStr riceInfo;
        WheatStr wheatInfo;
    }

    struct Charity{
        string charityName;
        address charityAddress;
        uint8 charityShare;
        bool isActive;
        uint nextDueTime;
    }
    
    mapping(address => User) public userMap;
    mapping(address => Charity) public charityMap;
    itemsPrice public ip;
    constructor() {
        owner = msg.sender;
        updateItemsPrice(5,4,3);
    }
 
    //token instance
    address public RVKTokenContract=0xE34B59424FD302942bEbd6f80Fcd3267EE797DFe;
    IRVKToken Irvk=IRVKToken(RVKTokenContract);
    
    function checkBalance(address userAddress)public view returns(uint256){
        return Irvk.CheckBalanceOf(userAddress);
    }
    
    function _tokenTransfer(address to,uint amount) internal {
        Irvk.tokenTransferFrom(msg.sender,to,amount);
    }

    function _isApprove(uint amount)internal{
           Irvk.approval(msg.sender,address(this),amount);

    }

    function registerUser(address adsOfUser) public override onlyOwner {
        require(userMap[adsOfUser].isActive==false,"RationVitranKendra: user is already registered");
        _tokenTransfer(adsOfUser,givenToken); 
        PulsesStr memory tempPulses = PulsesStr(0, 0);
        RiceStr memory tempRice = RiceStr(0, 0);
        WheatStr memory tempWheat = WheatStr(0, 0);
        User memory tempUserStr = User(adsOfUser, true,block.timestamp+renewTime, tempPulses,tempRice,tempWheat);
        userMap[adsOfUser] = tempUserStr;
        emit registerUserEvent(adsOfUser,true);
    }

    function withDrawRation(rawItems item) public override  {
        require(userMap[msg.sender].isActive, "RationVitranKendra: not registered");
        if(item==rawItems.pulses){
            require(checkBalance(msg.sender)>=ip.pulsesPrice,"RationVitranKendra: provide required amount of tokens for pulses");
            _tokenTransfer(address(this),ip.pulsesPrice);
            _withDrawPulses();
            emit withdrawEvent(msg.sender,true,"pulses");

        }else if(item==rawItems.rice){
            require(checkBalance(msg.sender)>=ip.ricePrice,"RationVitranKendra: provide required amount of tokens for rice");
            _tokenTransfer(address(this),ip.ricePrice);
            _withDrawRice();
            emit withdrawEvent(msg.sender,true,"rice");

        }else if(item==rawItems.wheat){
            require(checkBalance(msg.sender)>=ip.wheatPrice,"RationVitranKendra: provide required amount of tokens for wheat");
            _tokenTransfer(address(this),ip.wheatPrice);
            _withDrawWheat();
            emit withdrawEvent(msg.sender,true,"wheat");
        }
    }
        
    function _withDrawPulses() internal {
         require(
            block.timestamp > userMap[msg.sender].pulsesInfo.nextDue,
            "RationVitranKendra: early pulses withdraw request issue"
        );
        require(totalPulses>=pulsesDistribute,"RationVitranKendra: insufficient pulses ");
        userMap[msg.sender].pulsesInfo.userPulses+=pulsesDistribute;
        totalPulses-=pulsesDistribute;
        userMap[msg.sender].pulsesInfo.nextDue = block.timestamp + itemNextDuePeriod;
       
    }

    function _withDrawRice() internal {
         require(
            block.timestamp > userMap[msg.sender].riceInfo.nextDue,
            "RationVitranKendra: early rice withdraw request issue"
        );
        require(totalRice>=riceDistribute,"RationVitranKendra: insufficient rice ");
        userMap[msg.sender].riceInfo.userRice+=riceDistribute;
        totalRice-=riceDistribute;
        userMap[msg.sender].riceInfo.nextDue = block.timestamp + itemNextDuePeriod;
    }

    function _withDrawWheat() internal {
         require(
            block.timestamp > userMap[msg.sender].wheatInfo.nextDue,
            "RationVitranKendra: early wheat withdraw request issue"
        );
        require(totalWheat>=wheatDistribute,"RationVitranKendra: insufficient wheat ");
        userMap[msg.sender].wheatInfo.userWheat+=wheatDistribute;
        totalWheat-=wheatDistribute;
        userMap[msg.sender].wheatInfo.nextDue = block.timestamp + itemNextDuePeriod;
    }

    function removeUser(address toRemoveUser) public override onlyOwner {
        require(userMap[toRemoveUser].isActive==true,"RationVitranKendra: user is not in registered list");
        userMap[toRemoveUser].isActive=false;
        emit userRemovingEvent(toRemoveUser,false);
       
    }

    function charityRegistration(string memory _charityName,address _charityAddress,uint8 _charityShare) public override onlyOwner{
        require(charityMap[_charityAddress].isActive==false,"RationVitranKendra: charity already registered");
        Charity memory tempCharity=Charity({charityName:_charityName,charityAddress:_charityAddress,charityShare:_charityShare,isActive:true,nextDueTime:block.timestamp});
        charityMap[_charityAddress]=tempCharity;
    }

    function removeCharity(address toRemoveCharity) public override onlyOwner{
        require(charityMap[toRemoveCharity].isActive==true,"RationVitranKendra: already inactive charity");
        charityMap[toRemoveCharity].isActive=false;
    } 

    function withDrawFund() public override{
        require(charityMap[msg.sender].isActive==true,"RationVitranKendra: not Registered charity");
        require(block.timestamp>charityMap[msg.sender].nextDueTime,"RationVitranKendra: early withdraw request issue");
        require(checkBalance(address(this))>0,"RationVitranKendra: does not have fund");
        Irvk.fundTransfer(msg.sender,(address(this).balance*charityMap[msg.sender].charityShare)/100);
        charityMap[msg.sender].nextDueTime=block.timestamp+charityNextWithdraw;
    }

    function refilling(uint _pulses,uint _rice,uint _wheat) public override onlyOwner{
        totalPulses+=_pulses;
        totalRice+=_rice;
        totalWheat+=_wheat;
    }

    function updateItemsQuantity(uint8 _pulsesDistribute,uint8 _riceDistribute,uint8 _wheatDistribute) public override onlyOwner{
        pulsesDistribute=_pulsesDistribute;
        riceDistribute=_riceDistribute;
        wheatDistribute=_wheatDistribute;
    }

    function getRVKBalance() public view returns(uint){
        return checkBalance(address(this));
    }

    function changeDistributionTime(uint newtime)public override onlyOwner{
        itemNextDuePeriod=newtime;
    }

    function changeCharityWithdrawTime(uint newtime)public override onlyOwner{
        charityNextWithdraw=newtime;
    }

    function updateItemsPrice(uint _pulsesPrice,uint _ricePrice,uint _wheatPrice) public override onlyOwner{
        ip.pulsesPrice=_pulsesPrice;
        ip.ricePrice=_ricePrice;
        ip.wheatPrice=_wheatPrice;
        emit updateItemsPriceEvent(_pulsesPrice,_ricePrice,_wheatPrice,"items price is updated");

    }

    function changeTokenAmt(uint16 newTokenAmt)public onlyOwner{
        givenToken=newTokenAmt;
    }

    function changeRenewTime(uint newRenewTime)public onlyOwner{
        renewTime=newRenewTime;
    }

    function renewRVKTokens()public {
        require(userMap[msg.sender].isActive, "RationVitranKendra: not registered");
        require(block.timestamp>userMap[msg.sender].nextRenewTime,"RationVitranKendra: early renewal request");
        require(checkBalance(address(this)) >= givenToken,"RationVitranKendra: doesn't have enough RVK token");
        userMap[msg.sender].nextRenewTime=block.timestamp+renewTime;
        Irvk.fundTransfer(msg.sender,givenToken);
    }

    function tokenToEther()public{
        require(userMap[msg.sender].isActive, "RationVitranKendra: not registered");
        require(checkBalance(msg.sender)>=100,"RationVitranKendra: insufficient Tokens");
        _tokenTransfer(address(this),checkBalance(msg.sender));
        address payable ads=payable(msg.sender);
        ads.transfer(1000);
    }

    function receiveEther() payable public{
     }

    
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;
import "./interfaceRVK.sol";
abstract contract abstractRVK is IRVK{
    address public owner;
    modifier onlyOwner() {
        require(owner == msg.sender,"not Owner");
        _;
    }


}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

interface IRVKToken{
    
    function mint(address to, uint256 amount) external;
    function airDrop(address to,uint256 amount)external;
    function setApprove(address spender, uint256 amount) external ; 
    function CheckBalanceOf(address account) external view returns (uint256);
    function approval(address owner,address spender,uint amount) external ; 
    function tokenTransferFrom(address from,address to, uint amount) external;
    function fundTransfer(address to,uint amount)external;

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;
interface IRVK{
    // Events
    event registerUserEvent(address adsOfUser,bool isActive);
    event withdrawEvent(address adsOfUser,bool hasTaken,string item);
    event userRemovingEvent(address adsOfUser,bool isActive);
    event updateItemsPriceEvent(uint pulsesPrice,uint ricePrice,uint wheatPrice,string msg);
    
    enum rawItems{pulses,rice,wheat}

    function registerUser(address adsOfUser) external;
    function withDrawRation(rawItems item) external  ;
    function removeUser(address toRemoveUser) external ;
    function charityRegistration(string memory _charityName,address _charityAddress,uint8 _charityShare) external;
    function removeCharity(address toRemoveCharity) external;
    function withDrawFund() external;
    function refilling(uint _pulses,uint _rice,uint _wheat) external;
    function updateItemsQuantity(uint8 _pulsesDistribute,uint8 _riceDistribute,uint8 _wheatDistribute) external;
    function changeDistributionTime(uint newtime)external; 
    function changeCharityWithdrawTime(uint newtime) external;
    function updateItemsPrice(uint _pulsesPrice,uint _ricePrice,uint _wheatPrice) external;
    
    
}