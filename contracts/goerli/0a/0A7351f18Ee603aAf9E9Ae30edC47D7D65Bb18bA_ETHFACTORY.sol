/**
 *Submitted for verification at Etherscan.io on 2022-12-30
*/

/**
 _______  _______  __   __                                      
|       ||       ||  | |  |                                     
|    ___||_     _||  |_|  |                                     
|   |___   |   |  |       |                                     
|    ___|  |   |  |       |                                     
|   |___   |   |  |   _   |                                     
|_______|  |___|  |__| |__|                                     
 _______  _______  _______  _______  _______  ______    __   __ 
|       ||   _   ||       ||       ||       ||    _ |  |  | |  |
|    ___||  |_|  ||       ||_     _||   _   ||   | ||  |  |_|  |
|   |___ |       ||       |  |   |  |  | |  ||   |_||_ |       |
|    ___||       ||      _|  |   |  |  |_|  ||    __  ||_     _|
|   |    |   _   ||     |_   |   |  |       ||   |  | |  |   |  
|___|    |__| |__||_______|  |___|  |_______||___|  |_|  |___|  

*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

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
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract ETHFACTORY is Context, Ownable {
    using SafeMath for uint256;
    address payable private feeReceiver;

    uint256 private marketValue;
    uint256 private weiToHire1Miner = 1080000;
    uint256 private PSN = 10000;
    uint256 private PSNH = 5000;
    uint256 public depositFee = 4;
    uint256 public withdrawFee = 4;
    uint256 public refPercent = 7;
    uint256 public percentDivider = 100;
    uint256 public minBuy = 0.005 ether;
    uint256 public maxBuy = 1 ether;
    uint256[3] public maxWallet = [2 ether, 5 ether, 10 ether];
    uint256[2] public buyLimit = [100 ether, 250 ether];

    bool private initialized = false;

    mapping(address => uint256) private hiredMiners;
    mapping(address => uint256) private claimedProfit;
    mapping(address => uint256) private lastHireAt;
    mapping(address => address) private referrals;
    mapping(address => uint256) public investedEth;
    mapping(address => uint256) public lastClaimTime;

    constructor() {
        feeReceiver = payable(msg.sender);
    }

    function startFactory() public onlyOwner {
        require(marketValue == 0);
        initialized = true;
        marketValue = 108000000000;
    }

    function hireMiners(address ref) public payable {
        require(initialized);
        require(msg.value >= minBuy, "Less than min amount");
        require(msg.value <= maxBuy, "Exceeds max amount");
        if (getBalance() < buyLimit[0]) {
            require(
                investedEth[msg.sender] + msg.value <= maxWallet[0],
                "Exceeds max wallet limit"
            );
        } else if (getBalance() >= buyLimit[0] && getBalance() < buyLimit[1]) {
            require(
                investedEth[msg.sender] + msg.value <= maxWallet[1],
                "Exceeds max wallet limit"
            );
        } else {
            require(
                investedEth[msg.sender] + msg.value <= maxWallet[2],
                "Exceeds max wallet limit"
            );
        }
        uint256 profit = calculateProfit(
            msg.value,
            SafeMath.sub(address(this).balance, msg.value)
        );
        profit = profit.sub(
            profit.mul(depositFee).div(percentDivider)
        );
        uint256 fee = msg.value.mul(depositFee).div(percentDivider);
        feeReceiver.transfer(fee);
        claimedProfit[msg.sender] = claimedProfit[msg.sender].add(profit);
        rehireMiners(ref);
    }

    function rehireMiners(address ref) public {
        require(initialized);

        if (ref == msg.sender) {
            ref = feeReceiver;
        }

        if (
            referrals[msg.sender] == address(0) &&
            referrals[msg.sender] != msg.sender
        ) {
            referrals[msg.sender] = ref;
        }

        uint256 profitGenrated = getMyProfit(msg.sender);
        uint256 newMiners = profitGenrated.div(weiToHire1Miner);
        hiredMiners[msg.sender] = hiredMiners[msg.sender].add(newMiners);
        claimedProfit[msg.sender] = 0;
        lastHireAt[msg.sender] = block.timestamp;

        //send referral profit
        claimedProfit[referrals[msg.sender]] = claimedProfit[referrals[msg.sender]]
            .add(profitGenrated.mul(refPercent).div(percentDivider));

        //boost market to nerf miners hoarding
        marketValue = marketValue.add(profitGenrated.div(5));
    }

    function takeProfit() public {
        require(initialized);
        uint256 hasProfit = getMyProfit(msg.sender);
        uint256 eggValue = calculateSellProfit(hasProfit);
        uint256 fee = eggValue.mul(withdrawFee).div(percentDivider);
        claimedProfit[msg.sender] = 0;
        lastHireAt[msg.sender] = block.timestamp;
        marketValue = SafeMath.add(marketValue, hasProfit);
        feeReceiver.transfer(fee);
        payable(msg.sender).transfer(SafeMath.sub(eggValue, fee));
    }

    function beanRewards(address adr) public view returns (uint256) {
        uint256 hasProfit = getMyProfit(adr);
        uint256 eggValue = calculateSellProfit(hasProfit);
        return eggValue;
    }

    function calculateTrade(
        uint256 rt,
        uint256 rs,
        uint256 bs
    ) private view returns (uint256) {
        return
            SafeMath.div(
                SafeMath.mul(PSN, bs),
                SafeMath.add(
                    PSNH,
                    SafeMath.div(
                        SafeMath.add(
                            SafeMath.mul(PSN, rs),
                            SafeMath.mul(PSNH, rt)
                        ),
                        rt
                    )
                )
            );
    }

    function calculateSellProfit(uint256 profit) public view returns (uint256) {
        return calculateTrade(profit, marketValue, address(this).balance);
    }

    function calculateProfit(uint256 eth, uint256 contractBalance)
        public
        view
        returns (uint256)
    {
        return calculateTrade(eth, contractBalance, marketValue);
    }

    function calculateProfitSimple(uint256 eth) public view returns (uint256) {
        return calculateProfit(eth, address(this).balance);
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getMyMiners(address adr) public view returns (uint256) {
        return hiredMiners[adr];
    }

    function getMyProfit(address adr) public view returns (uint256) {
        return SafeMath.add(claimedProfit[adr], getProfitSinceLastHireAt(adr));
    }

    function getProfitSinceLastHireAt(address adr) public view returns (uint256) {
        uint256 secondsPassed = calculateMin(
            weiToHire1Miner,
            SafeMath.sub(block.timestamp, lastHireAt[adr])
        );
        return SafeMath.mul(secondsPassed, hiredMiners[adr]);
    }

    function calculateMin(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }

    function setDepositFeePercent(uint256 percent) external onlyOwner {
        depositFee = percent;
    }

    function setWithdrawFeePercent(uint256 percent) external onlyOwner {
        withdrawFee = percent;
    }

    function setRefPercent(uint256 percent) external onlyOwner {
        refPercent = percent;
    }

    function setPercentDivider(uint256 denominator) external onlyOwner {
        percentDivider = denominator;
    }

    function setMinAndMaxBuy(uint256 min, uint256 max) external onlyOwner {
        minBuy = min;
        maxBuy = max;
    }

    function setMaxWallet(uint256 l1, uint256 l2, uint256 l3) external onlyOwner {
        maxWallet[0] = l1;
        maxWallet[1] = l2;
        maxWallet[2] = l3;
    }

    function setBuyLimit(uint256 l1, uint256 l2) external onlyOwner {
        buyLimit[0] = l1;
        buyLimit[1] = l2;
    }
}