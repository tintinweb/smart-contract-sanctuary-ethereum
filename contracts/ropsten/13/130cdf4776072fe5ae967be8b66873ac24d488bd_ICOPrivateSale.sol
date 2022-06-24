/**
 *Submitted for verification at Etherscan.io on 2022-06-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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
    // function renounceOwnership() private onlyOwner {
    //     _transferOwnership(address(0));
    // }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    // function transferOwnership(address newOwner) private onlyOwner {
    //     require(newOwner != address(0), "Ownable: new owner is the zero address");
    //     _transferOwnership(newOwner);
    // }

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

interface IBEP20  {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom( address sender, address recipient, uint256 amount ) external returns (bool);
    function decimals() external view returns (uint8);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval( address indexed owner, address indexed spender, uint256 value);
}


contract ICOPrivateSale is Ownable {

    using SafeMath for uint256;
    event Print(string msg, uint256 stime, uint256 _etime);

    uint256  presaleRate; // Sell PresaleRate (input PresaleRate should be multiply with 10 to the power decimalsValue)
    uint256  startTime; // ICO start time
    uint256  endTime; // ICO End Time

    address  icoTokenContractAddr; // SoldOut Token Contract Address
    address  busdTokenContractAddr; // SoldOut Token Contract Address
    
    uint256  totalTokenNeedForInvestor; // Total Fund
    uint256  TotalCollectedBNBFund;
    uint256  totalTokenSupply;

    uint8  icoTokenDecimals;
    uint8  busdTokenDecimals;
    bool public isVesting;
    address[]  SellTrackAddr; // capture all the addresses who perform trades
    uint256[]  SellTrackAddrAmount; // capture all the addresses amount who perform trades

   
// Constructor of Solidity
    constructor(address _icoTokenAddr, address _busdContractAddress, uint256 _presaleRate, uint256 _startTime, uint256 _endTime, uint256 _totalTokenSupply) {  
        busdTokenContractAddr = _busdContractAddress;
        icoTokenContractAddr = _icoTokenAddr;
        presaleRate = _presaleRate;
        startTime = _startTime;
        endTime = _endTime;
        totalTokenSupply = _totalTokenSupply;

        //Contract Details 
        icoTokenDecimals = IBEP20(_icoTokenAddr).decimals();
        busdTokenDecimals = IBEP20(_busdContractAddress).decimals();


    }

    
 // buyToken function that will use to sell the SoldOut Token
    function buyToken(uint256 _busdAmount) public returns (bool) {
        require(block.timestamp >= startTime, "Sale not started yet");
        require( _busdAmount > 0, "Amount should be greater from 0");
        require(totalTokenNeedForInvestor + (_busdAmount*10**icoTokenDecimals)/presaleRate <= totalTokenSupply,"Don't have sufficent token for transaction");
        require(!isIcoOver(),"sale is ended");
        // Collect BUSD to ICO Contract Address
        IBEP20(busdTokenContractAddr).transferFrom(msg.sender, address(this), _busdAmount); 
        // set sell track after the transaction
        setBuyTokneTransaction(_busdAmount);
        return true;
    }

  // It will mark entry in client SellTrack (it should be private)
    function setBuyTokneTransaction(uint256 _busdAmount) private {
        uint256 x = 0;
        // When user already have completed trasnacation
        for (uint256 i = 0; i < SellTrackAddr.length; i++) {
            // address already present
            if (SellTrackAddr[i] == msg.sender) {
                x = 1;
                // update SellTrackAddrAmount value when value already present
                SellTrackAddrAmount[i] = SellTrackAddrAmount[i] + _busdAmount;
            }
        }

        // When user do first transcation.
        if (x == 0) {
            // address not present then insert
            SellTrackAddr.push(msg.sender);
            // When address not present or first entry then push amount at last place
            SellTrackAddrAmount.push(_busdAmount);
        }

        // PayOutCoin Fund Count Update
        totalTokenNeedForInvestor +=  (_busdAmount*10**icoTokenDecimals)/presaleRate;
        TotalCollectedBNBFund = TotalCollectedBNBFund + _busdAmount;
    }


    function getTokenomics() public view returns(uint8, uint8, uint256, uint256, uint256, uint256, uint256, uint256){
        return(icoTokenDecimals, busdTokenDecimals, presaleRate, startTime, endTime, totalTokenNeedForInvestor, TotalCollectedBNBFund, totalTokenSupply);
    }

    // Admin can Change Start Time and End Time for ICO
    function setICOTime(uint256 _startTime, uint256 _endTime) public onlyOwner {
        require(_endTime > _startTime,"Start Time Can not be Greater Than End Time");
        require(block.timestamp < startTime, "Can't change time once sale started");
        startTime = _startTime / 10**icoTokenDecimals;
        endTime = _endTime / 10**icoTokenDecimals;
    }

     function setICOEndTime( uint256 _endTime) public onlyOwner {
        require(_endTime > startTime,"Start Time Can not be Greater Than End Time");
        require(block.timestamp >= startTime, "Sale not started yet");
        require(!isIcoOver(), "Can't change time once sale ended");
        endTime = _endTime / 10**icoTokenDecimals;
    }
 
    function showAllTransaction() public view returns (address[] memory, uint256[] memory) {
        require(SellTrackAddr.length > 0, " Transaction data not found");
        return (SellTrackAddr, SellTrackAddrAmount);
    }


    function setPresaleRate(uint256 _presaleRate) public onlyOwner {
        require(block.timestamp < startTime, "Presale Price cannot be change after the start Time.");
        presaleRate = _presaleRate;
    }
    


    function isIcoOver() public view returns (bool) {
        if (
            (block.timestamp >= endTime || (totalTokenNeedForInvestor >= totalTokenSupply))
        ) {
            return true;
        } else {
            return false;
        }
    }

    function Vesting() public onlyOwner returns (bool) {
        /*1. After Sale End*/
        require(isIcoOver(), "Sale is not Ended. Wait for it");
        require(!isVesting,"vesting already done");
        require(SellTrackAddr.length>0,"no one invested");

        for(uint8 i=0; i<SellTrackAddr.length; i++)
        {
            IBEP20(icoTokenContractAddr).transfer(SellTrackAddr[i],  (SellTrackAddrAmount[i]*10**icoTokenDecimals)/presaleRate);
        }
        isVesting= true;
        return true;
    }


    function retrieveStuckedERC20Token(address _tokenAddr, uint256 _amount, address _toWallet) public onlyOwner returns(bool){
        IBEP20 (_tokenAddr).transfer(_toWallet, _amount);
        return true;
    }
}