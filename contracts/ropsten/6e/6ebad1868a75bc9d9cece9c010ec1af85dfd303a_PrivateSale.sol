/**
 *Submitted for verification at Etherscan.io on 2022-07-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


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
    function renounceOwnership() private onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) private onlyOwner {
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

library SafeMath {
    function tryAdd(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryMul(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

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

interface Token {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom( address sender, address recipient, uint256 amount ) external returns (bool);
    function decimals() external view returns (uint8);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval( address indexed owner, address indexed spender, uint256 value);
}


contract PrivateSale is Ownable {
    event Print(string _s, uint256 _a, uint256 _b);
    address[] whiteListedUsers;
    using SafeMath for uint256;

    uint256  presaleRate; // Sell PresaleRate (input PresaleRate should be multiply with 10 to the power decimalsValue)
    uint256  startTime; // ICO start time
    uint256  endTime; // ICO End Time


    address  icoTokenContractAddr; // SoldOut Token Contract Address
    address  busdTokenContractAddr; // SoldOut Token Contract Address
    
    uint256  spendTokens; // Total Fund
    uint256  collectedFund;
    uint256  totalTokenSupply;

  
    uint8  icoTokenDecimals;
    uint8  busdTokenDecimals;

    address[]  SellTrackAddr; // capture all the addresses who perform trades
    uint256[]  SellTrackAddrAmount; // capture all the addresses amount who perform trades

    
    uint256 public vestingCounter;
    uint8 public totalRound = 11;
    uint256 public lokingPeriodTime = 365 days;
    uint256 public aMonth = 30 days;
    

   

    constructor(address _busdContract, address _icoContract, uint256 _startTime, uint256 _endTime) {
        busdTokenContractAddr = _busdContract;
        icoTokenContractAddr = _icoContract;
        presaleRate = 5000000000000000;
        startTime = _startTime;  // 1657541550
        endTime = _endTime;
        icoTokenDecimals = Token(_icoContract).decimals();
        busdTokenDecimals = Token(_busdContract).decimals();
        totalTokenSupply = 970000000*10**icoTokenDecimals;
    }

    
    // SaleICOToken function that will use to sell the SoldOut Token
    function SaleICOToken(uint256 _roomQuantity) public returns (bool) {
        require(_roomQuantity >= 1000000000000000000, "Less than 1 Room Not allow");
        bool posibility;
        uint256 output;
        (posibility, output) =  SafeMath.tryMod(_roomQuantity, 1000000000000000000);
        require(output==0, "Room Quantity is not Natural number, Only Natural Number Accepted");

        // convert room into busd.
        uint256 _busdAmount = 5000*_roomQuantity;

        require(!isIcoOver(), "Ico is over");
        require(verifyUser(msg.sender),"User is not whitelisted");
        require(block.timestamp >= startTime, "ICO Sale not started yet");
        require( (_busdAmount*10**icoTokenDecimals)/presaleRate > 0, "Zero Amount!");
        require(spendTokens + (_busdAmount*10**icoTokenDecimals)/presaleRate <= totalTokenSupply,"This Transaction may exceed ICO Maximux Allocation Limit for public sale, Please try with lower bnbAmount.");
        // Collect BUSD to ICO Contract Address
        Token(busdTokenContractAddr).transferFrom(msg.sender, address(this), _busdAmount); 
        // Token(icoTokenContractAddr).transfer(msg.sender,  (_busdAmount*10**icoTokenDecimals)/presaleRate);
        // set sell track after the transaction
        setSellTrack(_busdAmount);
        return true;
    }

    function getTokenomics() public view returns(uint8, uint8, uint256, uint256, uint256, uint256, uint256, uint256){
        return(icoTokenDecimals, busdTokenDecimals, presaleRate, startTime, endTime, spendTokens, collectedFund, totalTokenSupply);
            //  0              ,   1              ,   2        ,  3        , 4      , 5         , 6            , 7
    }

    // Admin can Change Start Time and End Time for ICO
    function setICOTime(uint256 _startTime, uint256 _endTime) public onlyOwner {
        require(_endTime > _startTime,"Start Time Can not be Greater Than End Time");
        startTime = _startTime;
        endTime = _endTime;
    }

    
    function showAllTrade() public view returns (address[] memory, uint256[] memory) {
        require(SellTrackAddr.length > 0, "Trade data not found");
        return (SellTrackAddr, SellTrackAddrAmount);
    }


    function setPresaleRate(uint256 _presaleRate) public onlyOwner {
        require(block.timestamp < startTime, "Presale Price cannot be change after the start Time.");
        presaleRate = _presaleRate;
    }
    

    // It will mark entry in client SellTrack (it should be private)
    function setSellTrack(uint256 _busdAmount) private {
        uint256 x = 0;
        for (uint256 i = 0; i < SellTrackAddr.length; i++) {
            if (SellTrackAddr[i] == msg.sender) {
                // address already present
                x = 1;
                // update SellTrackAddrAmount value when value already present
                SellTrackAddrAmount[i] = SellTrackAddrAmount[i] + _busdAmount;
            }
        }
        if (x == 0) {
            // address not present then insert
            SellTrackAddr.push(msg.sender);
            // When address not present or first entry then push amount at last place
            SellTrackAddrAmount.push(_busdAmount);
        }

        // PayOutCoin Fund Count Update
        spendTokens +=  (_busdAmount*10**icoTokenDecimals)/presaleRate;
        collectedFund = collectedFund + _busdAmount;
    }


    function isIcoOver() public view returns (bool) {
        if (
            (block.timestamp >= endTime || (spendTokens >= totalTokenSupply))
        ) {
            return true;
        } else {
            return false;
        }
    }


    function retrieveStuckedERC20Token(address _tokenAddr, uint256 _amount, address _toWallet) public onlyOwner returns(bool){
        Token(_tokenAddr).transfer(_toWallet, _amount);
        return true;
    }
    


   function addBulkUsers(address[] memory _addressToWhitelist) public onlyOwner {
        for(uint8 i=0;i<_addressToWhitelist.length;i++){
            if(!isAddressInArray(whiteListedUsers, _addressToWhitelist[i])){
            whiteListedUsers.push(_addressToWhitelist[i]);
            } 
        }
    }

    function verifyUser(address _whitelistedAddress) public view returns(bool) {
        return (isAddressInArray(whiteListedUsers, _whitelistedAddress));
    }

     // Admin can remove individual Whitelisted User, and MaxBuy autometically set to 0
    function RemoveWhiteListed(address _addr) public onlyOwner {
        require(
            isAddressInArray(whiteListedUsers, _addr),
            "This Address not present into Whitelist Users list."
        );

        // put address zero when address found
        for (uint256 i = 0; i < whiteListedUsers.length; i++) {
            if (whiteListedUsers[i] == _addr) {
                whiteListedUsers[i] = address(0);
            }
        }
    }
    
    // Check Address Present or not in given Address Array
    function isAddressInArray(address[] memory _addrArray, address _addr) private pure returns (bool) {
        bool tempbool = false;
        uint256 j = 0;
        while (j < _addrArray.length) {
            if (_addrArray[j] == _addr) {
                tempbool = true;
                break;
            }
            j++;
        }
        return tempbool;
    }
    
    function setTokenContract(address _tokenContract) public onlyOwner {
        icoTokenContractAddr = _tokenContract;
    }


    function Vesting() public onlyOwner returns (bool) {

        /*1. After Sale End*/
        require(isIcoOver(), "Sale is not Ended. Wait for it");
        require(vestingCounter < totalRound+1, "All the Vesting Round Completed.");

        /*3. First Vesting Round can be start after 2 month loking period*/
        if (vestingCounter == 0) {
            require(block.timestamp > endTime + lokingPeriodTime, "First Vesting Can be start after locking period.");
        }
        // after locking period
        uint256 stime = endTime + lokingPeriodTime + vestingCounter * aMonth;
        // uint256 eTime = endTime + lokingPeriodTime + vestingCounter * aMonth + aMonth;

        if (block.timestamp > stime){
            for(uint256 i=0; i<SellTrackAddr.length; i++)
            {  
                if(vestingCounter < totalRound){
                    emit Print("5% Supply", SellTrackAddrAmount[i], ((SellTrackAddrAmount[i]*5*10**icoTokenDecimals)/presaleRate*100));
                    Token(icoTokenContractAddr).transfer(SellTrackAddr[i],  ((SellTrackAddrAmount[i]*5)*10**icoTokenDecimals)/(presaleRate*100));
                    
                }else{
                    emit Print("45% SUpply", 12, 112);
                    Token(icoTokenContractAddr).transfer(SellTrackAddr[i],  ((SellTrackAddrAmount[i]*45)*10**icoTokenDecimals)/(presaleRate*100));
                    // Token(icoTokenContractAddr).transfer(SellTrackAddr[i],  (SellTrackAddrAmount[i]*45*10**icoTokenDecimals)/presaleRate*100);
                }
            }
            vestingCounter += 1;

        }else{
            require(false, "Can not call before 1 month");
        }
        return true;
    }




    function setLockingPeriod(uint256 _lokingPeriodTime) public onlyOwner{
        lokingPeriodTime = _lokingPeriodTime;
    }


    function setAmonth(uint256 _aMonth) public onlyOwner{
        aMonth = _aMonth;
    }

     function aa_Jyada() public view returns(uint256) {
         uint256 output;
        (,output) = SafeMath.trySub(block.timestamp , endTime);
        return output;
    }

    function aa_Baki() public view returns(uint256) {
        uint256 output;
        (, output) =  SafeMath.trySub(endTime , block.timestamp);
        return output;
    }


}
// ["0x7e4f1a15A72A30A0B7C929Fe57c576dA076F3006","0x0BC6CDBBe4732708a5CcE42EA40759653eDA0ed9","0xf27bEc6dEfa3315e0625Daf79bDcbb21427609a9","0xDCEe6d58C4a67a4AD0696760Fb4D6F346cd425Ff","0x50021f7e60caa0C25575c22D66CEEDdfF8BF8A35"]
// 000000000000000000
// ["0x0F11d3008cF5D8FF91F07aEBD71b0ecd502E5Fa3","0xF0d6E5354e84D441c0361ad11c5950a1EfF28BC3","0x50021f7e60caa0C25575c22D66CEEDdfF8BF8A35"]