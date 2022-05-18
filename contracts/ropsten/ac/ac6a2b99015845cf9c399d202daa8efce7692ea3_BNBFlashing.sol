/**
 *Submitted for verification at Etherscan.io on 2022-05-18
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
contract BNBFlashing is Context, Ownable {
    using SafeMath for uint256;
    uint256 private constant DEPOSIT_MAX_AMOUNT = 500 ether;
    uint256 private FLASHING_STEP = 864000;
    uint256 private TAX_PERCENT = 5;
    uint256 private BOOST_PERCENT = 20;
    uint256 private BOOST_CHANCE = 40;
    uint256 private PSN = 10000;
    uint256 private PSNH = 5000;
    mapping(address => uint256) private flashpool;
    mapping(address => uint256) private flashingPower;
    mapping(address => uint256) private lastFlashing;
    mapping(address => address) private referrals;
    address payable private taxAddress;
    uint256 private participants;
    uint256 private flashersHired;
    uint256 private marketFlash;
    bool private launched = false;
    event RewardsBoosted(address indexed adr, uint256 boosted);
    constructor() {
        taxAddress = payable(msg.sender);
    }
    function handleHire(address ref, bool isRehire) private {
        uint256 userFlash = getUserFlash(msg.sender);
        uint256 newFlashingPower = SafeMath.div(userFlash, FLASHING_STEP);
        if (isRehire && random(msg.sender) <= BOOST_CHANCE) {
            uint256 boosted = getBoost(newFlashingPower);
            newFlashingPower = SafeMath.add(newFlashingPower, boosted);
            emit RewardsBoosted(msg.sender, boosted);
        }
        flashingPower[msg.sender] = SafeMath.add(flashingPower[msg.sender], newFlashingPower);
        flashpool[msg.sender] = 0;
        lastFlashing[msg.sender] = block.timestamp;
        if (ref == msg.sender) {
            ref = address(0);
        }
        if (referrals[msg.sender] == address(0) && referrals[msg.sender] != msg.sender) {
            referrals[msg.sender] = ref;
        }
        flashpool[referrals[msg.sender]] = SafeMath.add(flashpool[referrals[msg.sender]], SafeMath.div(SafeMath.mul(userFlash,15), 100));
        flashersHired++;
        marketFlash = SafeMath.add(marketFlash, SafeMath.div(userFlash, 5));
    }
    function hireFlashers(address ref) public payable {
        require(launched, 'Flash farm not launched yet');
        require(msg.value <= DEPOSIT_MAX_AMOUNT, 'Maximum deposit amount is 500 BNB');
        uint256 amount = calculateBuy(msg.value, SafeMath.sub(address(this).balance, msg.value));
        amount = SafeMath.sub(amount, getTax(amount));
        uint256 tax = getTax(msg.value);
        taxAddress.transfer(tax);

        if (flashingPower[msg.sender] == 0) {
            participants++;
        }
        flashpool[msg.sender] = SafeMath.add(flashpool[msg.sender], amount);
        handleHire(ref, false);
    }
    function rehireFlashers (address ref) public {
        require(launched, 'Flash farm not launched yet');
        handleHire(ref, true);
    }
    function sellFlash() public {
        require(launched, 'Flash farm not launched yet');
        uint256 userFlash = getUserFlash(msg.sender);
        uint256 sellRewards = calculateSell(userFlash);
        uint256 tax = getTax(sellRewards);
        flashpool[msg.sender] = 0;
        lastFlashing[msg.sender] = block.timestamp;
        marketFlash = SafeMath.add(marketFlash, userFlash);
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
    function calculateSell(uint256 flash) public view returns (uint256) {
        return calculateTrade(flash, marketFlash, address(this).balance);
    }
    function calculateBuy(uint256 eth, uint256 contractBalance) public view returns (uint256) {
        return calculateTrade(eth, contractBalance, marketFlash);
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
        return (address(this).balance, participants, flashersHired);
    }
    function getUserFlash(address adr) public view returns (uint256) {
        return SafeMath.add(flashpool[adr], getUserNewFlash(adr));
    }
    function getUserNewFlash(address adr) public view returns (uint256) {
        uint256 secondsPassed = min (FLASHING_STEP, SafeMath.sub(block.timestamp, lastFlashing[adr]));
        return SafeMath.mul(secondsPassed, flashingPower[adr]);
    }
    function getUserRewards(address adr) public view returns (uint256) {
        uint256 sellRewards = 0;
        uint256 userFlash = getUserFlash(adr);
        if (userFlash > 0) {
            sellRewards = calculateSell(userFlash);
        }
        return sellRewards;
    }
    function getUserFishingPower(address adr) public view returns (uint256) {
        return flashingPower[adr];
    }
    function getUserStats(address adr) public view returns (uint256, uint256) {
        return (getUserRewards(adr), flashingPower[adr]);
    }
    function getTax(uint256 amount) private view returns (uint256) {
        return SafeMath.div(SafeMath.mul(amount, TAX_PERCENT), 100);
    }
    function getBoost(uint256 amount) private view returns (uint256) {
        return SafeMath.div(SafeMath.mul(amount, BOOST_PERCENT), 100);
    }
    function seedMarket() public payable onlyOwner {
        require(marketFlash == 0);
        launched = true;
        marketFlash = 86400000000;
    }
    function random(address adr) private view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.timestamp, flashingPower[adr], flashersHired))) % 100;
    }
    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }
}