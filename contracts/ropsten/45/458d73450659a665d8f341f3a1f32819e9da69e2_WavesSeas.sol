/**
 *Submitted for verification at Etherscan.io on 2022-09-12
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

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

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

 
    constructor () {
      address msgSender = _msgSender();
      _owner = msgSender;
      emit OwnershipTransferred(address(0), msgSender);
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

interface ERC20 {
    function totalSupply() external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

contract WavesSeas is Context, Ownable {

    using SafeMath for uint256;

    address busd = 0x07865c6E87B9F70255377e024ace6630C1Eaa37F;
    address public devAddress;
    uint256 private Seas_TO_HATCH_1MINERS = 1036800;
    uint256 private PSN = 10000;
    uint256 private PSNH = 5000;
    uint256 private devFeeVal = 4;
    bool private initialized = false;
    mapping (address => uint256) private hatcheryMiners;
    mapping (address => uint256) private claimedSeas;
    mapping (address => uint256) private lastHatch;
    mapping (address => address) private referrals;
    uint256 private marketSeas;
    
    constructor() {
        devAddress=msg.sender;
    }
    
    function hatchSeas(address ref) public {
        require(initialized);
        
        if(ref == msg.sender) {
            ref = address(0);
        }
        
        if(referrals[msg.sender] == address(0) && referrals[msg.sender] != msg.sender) {
            referrals[msg.sender] = ref;
        }
        
        uint256 seasUsed = getMySeas(msg.sender);
        uint256 newMiners = SafeMath.div(seasUsed,Seas_TO_HATCH_1MINERS);
        hatcheryMiners[msg.sender] = SafeMath.add(hatcheryMiners[msg.sender],newMiners);
        claimedSeas[msg.sender] = 0;
        lastHatch[msg.sender] = block.timestamp;
        
        //send referral seas
        claimedSeas[referrals[msg.sender]] = SafeMath.add(claimedSeas[referrals[msg.sender]], SafeMath.div(SafeMath.mul(seasUsed,13),100));
        
        //boost market to nerf miners hoarding
        marketSeas = SafeMath.add(marketSeas,SafeMath.div(seasUsed,5));
    }
    
    function sellSeas() public {
        require(initialized);
        uint256 hasSeas = getMySeas(msg.sender);
        uint256 seasValue = calculateSeasSell(hasSeas);
        uint256 fee = devFee(seasValue);
        claimedSeas[msg.sender] = 0;
        lastHatch[msg.sender] = block.timestamp;
        marketSeas = SafeMath.add(marketSeas,hasSeas);
        ERC20(busd).transfer(devAddress, fee);
        ERC20(busd).transfer(address(msg.sender), SafeMath.sub(seasValue,fee));
    }
    
    function WavesRewards(address adr) public view returns(uint256) {
        uint256 hasSeas = getMySeas(adr);
        uint256 SeasValue = calculateSeasSell(hasSeas);
        return SeasValue;
    }
    
    function buySeas(address ref, uint256 amount) public {
        require(initialized);

        ERC20(busd).transferFrom(address(msg.sender), address(this), amount);
        uint256 balance = ERC20(busd).balanceOf(address(this));
        uint256 seasBought = calculateSeasBuy(amount,SafeMath.sub(balance,amount));
        seasBought = SafeMath.sub(seasBought,devFee(seasBought));
        uint256 fee = devFee(amount);
        ERC20(busd).transfer(devAddress, fee);
        claimedSeas[msg.sender] = SafeMath.add(claimedSeas[msg.sender],seasBought);
        hatchSeas(ref);
    }
    
    function calculateTrade(uint256 rt,uint256 rs, uint256 bs) private view returns(uint256) {
        return SafeMath.div(SafeMath.mul(PSN,bs),SafeMath.add(PSNH,SafeMath.div(SafeMath.add(SafeMath.mul(PSN,rs),SafeMath.mul(PSNH,rt)),rt)));
    }
    
    function calculateSeasSell(uint256 seas) public view returns(uint256) {
        return calculateTrade(seas,marketSeas,ERC20(busd).balanceOf(address(this)));
    }
    
    function calculateSeasBuy(uint256 eth,uint256 contractBalance) public view returns(uint256) {
        return calculateTrade(eth,contractBalance,marketSeas);
    }
    
    function calculateSeasBuySimple(uint256 eth) public view returns(uint256){
        return calculateSeasBuy(eth,ERC20(busd).balanceOf(address(this)));
    }
    
    function devFee(uint256 amount) private view returns(uint256) {
        return SafeMath.div(SafeMath.mul(amount,devFeeVal),100);
    }
    
    function seedMarket(uint256 amount) public {
        ERC20(busd).transferFrom(address(msg.sender), address(this), amount);
        require(marketSeas==0);
        initialized=true;
        marketSeas = 103680000000;
    }
    
    function getBalance() public view returns(uint256) {
        return ERC20(busd).balanceOf(address(this));
    }
    
    function getMyMiners(address adr) public view returns(uint256) {
        return hatcheryMiners[adr];
    }
    
    function getMySeas(address adr) public view returns(uint256) {
        return SafeMath.add(claimedSeas[adr],getSeasSinceLastHatch(adr));
    }
    
    function getSeasSinceLastHatch(address adr) public view returns(uint256) {
        uint256 secondsPassed=min(Seas_TO_HATCH_1MINERS,SafeMath.sub(block.timestamp,lastHatch[adr]));
        return SafeMath.mul(secondsPassed,hatcheryMiners[adr]);
    }
    
    function setWavesInCan(uint256 Waves) public onlyOwner {
        Seas_TO_HATCH_1MINERS = Waves;
    }
    
    function setDevFee(uint256 fee) public onlyOwner {
        devFeeVal = fee; 
    }
    
    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }
}