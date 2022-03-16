/**
 *Submitted for verification at Etherscan.io on 2022-03-16
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;


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

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    
    constructor() {
        _transferOwnership(_msgSender());
    }

    
    function owner() public view virtual returns (address) {
        return _owner;
    }

    
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

library Address {
    
    function isContract(address account) internal view returns (bool) {
        
        
        

        return account.code.length > 0;
    }

    
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            
            if (returndata.length > 0) {
                

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

contract CryptonitoFinance is Ownable {
    using SafeMath for uint256;

    uint256 public constant MINIMAL_DEPOSIT = 0.001 ether;
    uint256 public constant DEPOSITS_THRESHOLD = 25;
    uint256 public constant ROWS_IN_DEPOSIT = 7;
    uint8 public constant DEPOSITS_TYPES_COUNT = 4;
    uint256 public constant POSSIBLE_DEPOSITS_ROWS_COUNT = 700; 
    uint256[4] public PLANS_PERIODS = [7 days, 14 days, 21 days, 28 days];
    uint256[4] public PLANS_PERCENTS = [7, 17, 28, 42];
    uint256[9] public LEADER_BONUS_TRIGGERS = [
        0.3 ether,
        0.8 ether,
        1.5 ether,
        3 ether,
        15 ether,
        30 ether,
        150 ether,
        300 ether,
        1500 ether
    ];

    uint256[9] public LEADER_BONUS_REWARDS = [
        0.006 ether,
        0.0128 ether,
        0.03 ether,
        0.06 ether,
        0.3 ether,
        1.05 ether,
        3.75 ether,
        10.5 ether,
        75 ether
    ];

    uint256[3] public LEADER_BONUS_LEVEL_PERCENTS = [100, 30, 15];

    address payable public PROMOTION_ADDRESS = payable(0x706BC5dbBCeE7383e1f7c2f1d7d7977b38E21c7F);
    uint256[4] public PROMOTION_PERCENTS = [100, 100, 100, 100]; 

    address payable public constant DEFAULT_REFERRER = payable(0x22D4622652Cd3dDc5B0107F3f3f65FdE2C372cD7);
    uint256[5][4] public REFERRAL_PERCENTS; 
    uint256[4] public TOTAL_REFERRAL_PERCENTS = [300, 600, 900, 1200]; 

    struct Deposit {
        uint256 id;
        uint256 amount;
        uint8 depositType;
        uint256 freezeTime;
        uint256 withdrawn;
    }

    struct Player {
        address payable referrer;
        address refLevel;
        uint256 referralReward;
        uint256 refsCount;
        bool isActive; 
        uint256 leadTurnover;
        uint256 basicWithdraws;
        uint256 leadBonusReward;
        bool[9] receivedBonuses;
        bool isMadeFirstDeposit;

        Deposit[] deposits;
        uint256 investmentSum;

        uint256[4] depositsTypesCount;
        uint256[4] depositsTotalAmount;
    }

    mapping(address => Player) public players;
    mapping(address => uint256) private balances;
    uint256 public playersCount;
    uint256 public depositsCounter;
    uint256 public totalFrozenFunds;
    uint256 public totalReferalWithdraws;
    uint256 public totalLeadBonusReward;
    uint256 public turnover;

    event NewDeposit(
        uint256 depositId,
        address account,
        address referrer,
        uint8 depositType,
        uint256 amount
    );
    event Withdraw(address account,  uint256 originalAmount, uint256 level_percent, uint256 amount);
    event TransferReferralReward(address ref, address player, uint256 originalAmount, uint256 level_percents, uint256 rateType, uint256 amount);
    event TransferLeaderBonusReward(
        address indexed _to,
        uint256 indexed _amount,
        uint8 indexed _level
    );
    event TakeAwayDeposit(address account, uint8 depositType, uint256 amount);
    event WithdrawPromotionReward(address promo, uint256 reward);

    constructor() {
        REFERRAL_PERCENTS[0] = [125, 75, 50, 25, 25];
        REFERRAL_PERCENTS[1] = [250, 150, 100, 50, 50];
        REFERRAL_PERCENTS[2] = [375, 225, 150, 75, 75];
        REFERRAL_PERCENTS[3] = [500, 300, 200, 100, 100];
    }

    function isDepositCanBeCreated(uint8 depositType) external view returns (bool) {
        if (depositType < DEPOSITS_TYPES_COUNT) {
            return players[msg.sender].depositsTypesCount[depositType] < DEPOSITS_THRESHOLD;
        }
        else {
            return false;
        }
    }

    function getMaximumPossibleDepositValue(uint8 depositType) external view returns (uint256) {
        Player storage player = players[msg.sender];
        return player.depositsTotalAmount[DEPOSITS_TYPES_COUNT - 1] - player.depositsTotalAmount[depositType];
    }

    function makeDeposit(address payable ref, uint8 depositType)
        external
        payable
    {
        Player storage player = players[msg.sender];

        require(depositType < DEPOSITS_TYPES_COUNT, "Wrong deposit type");
        require(player.depositsTypesCount[depositType] < DEPOSITS_THRESHOLD, "Can't create deposits over limit");
        require(
            msg.value >= MINIMAL_DEPOSIT,
            "Not enought for mimimal deposit"
        );
        require(player.isActive || ref != msg.sender, "Referal can't refer to itself");

        
        if (depositType < DEPOSITS_TYPES_COUNT - 1) {
          require(player.depositsTypesCount[DEPOSITS_TYPES_COUNT - 1] > 0, "You should create 28 days long deposit before");
          require(
            player.depositsTotalAmount[depositType].add(msg.value) <= player.depositsTotalAmount[DEPOSITS_TYPES_COUNT - 1],
            "Low levels total deposits amount should be lower than 28 days long total deposits amount"
          );
        }

        
        if (!player.isActive) {
            playersCount = playersCount.add(1);
            player.isActive = true;
        }

        
        player.depositsTypesCount[depositType] = player.depositsTypesCount[depositType].add(1);
        player.depositsTotalAmount[depositType] = player.depositsTotalAmount[depositType].add(msg.value);

        _setReferrer(msg.sender, ref);

        player.deposits.push(
            Deposit({
                id: depositsCounter + 1,
                amount: msg.value,
                depositType: depositType,
                freezeTime: block.timestamp,
                withdrawn: 0
            })
        );
        player.investmentSum = player.investmentSum.add(msg.value);
        totalFrozenFunds = totalFrozenFunds.add(msg.value);

        emit NewDeposit(depositsCounter + 1, msg.sender, _getReferrer(msg.sender), depositType, msg.value);
        distributeRef(msg.value, msg.sender, depositType);
        distributeBonuses(msg.value, payable(msg.sender));
        sendRewardToPromotion(msg.value, depositType);

        depositsCounter = depositsCounter.add(1);
    }

    function takeAwayDeposit(uint256 depositId) external {
        Player storage player = players[msg.sender];
        require(depositId < player.deposits.length, "Out of keys list range");

        Deposit memory deposit = player.deposits[depositId];
        require(deposit.withdrawn > 0, "First need to withdraw reward");
        require(
            deposit.freezeTime.add(PLANS_PERIODS[deposit.depositType]) <= block.timestamp,
            "Not allowed now"
        );
        require(address(this).balance >= deposit.amount, "Not enought ETH to withdraw deposit");

        
        player.depositsTypesCount[deposit.depositType] = player.depositsTypesCount[deposit.depositType].sub(1);
        player.depositsTotalAmount[deposit.depositType] = player.depositsTotalAmount[deposit.depositType].sub(deposit.amount);

        
        player.investmentSum = player.investmentSum.sub(deposit.amount);

        
        if (depositId < player.deposits.length.sub(1)) {
          player.deposits[depositId] = player.deposits[player.deposits.length.sub(1)];
        }
        player.deposits.pop();
        payable(msg.sender).transfer(deposit.amount);

        emit TakeAwayDeposit(msg.sender, deposit.depositType, deposit.amount);
    }

    function _withdraw(address payable _wallet, uint256 _amount) private {
        require(address(this).balance >= _amount, "Not enougth TRX to withdraw reward");
        _wallet.transfer(_amount);
    }

    function withdrawReward(uint256 depositId) external returns (uint256) {
        Player storage player = players[msg.sender];
        require(depositId < player.deposits.length, "Out of keys list range");

        Deposit storage deposit = player.deposits[depositId];

        require(deposit.withdrawn == 0, "Already withdrawn, try 'Withdrow again' feature");
        uint256 amount = deposit.amount.mul(PLANS_PERCENTS[deposit.depositType]).div(100);
        deposit.withdrawn = deposit.withdrawn.add(amount);
        _withdraw(payable(msg.sender), amount);
        emit Withdraw(msg.sender, deposit.amount, PLANS_PERCENTS[deposit.depositType], amount);

        player.basicWithdraws = player.basicWithdraws.add(amount);
        return amount;
    }

    function withdrawRewardAgain(uint256 depositId) external returns (uint256) {
        Player storage player = players[msg.sender];
        require(depositId < player.deposits.length, "Out of keys list range");

        Deposit storage deposit = player.deposits[depositId];

        require(deposit.withdrawn != 0, "Already withdrawn, try 'Withdrow again' feature");
        require(deposit.freezeTime.add(PLANS_PERIODS[deposit.depositType]) <= block.timestamp, "Repeated withdraw not allowed now");

        
        deposit.freezeTime = block.timestamp;

        uint256 amount =
            deposit.amount
            .mul(PLANS_PERCENTS[deposit.depositType])
            .div(100);

        deposit.withdrawn = deposit.withdrawn.add(amount);
        _withdraw(payable(msg.sender), amount);
        emit Withdraw(msg.sender, deposit.withdrawn, PLANS_PERCENTS[deposit.depositType], amount);
        player.basicWithdraws = player.basicWithdraws.add(amount);

        uint256 depositAmount = deposit.amount;

        distributeRef(depositAmount, msg.sender, deposit.depositType);
        sendRewardToPromotion(depositAmount, deposit.depositType);

        return amount;
    }

    function distributeRef(uint256 _amount, address _player, uint256 rateType) private {
        uint256 totalReward = _amount.mul(TOTAL_REFERRAL_PERCENTS[rateType]).div(10000);

        address player = _player;
        address payable ref = _getReferrer(player);
        uint256 refReward;

        for (uint8 i = 0; i < REFERRAL_PERCENTS[rateType].length; i++) {
            refReward = (_amount.mul(REFERRAL_PERCENTS[rateType][i]).div(10000));
            totalReward = totalReward.sub(refReward);

            players[ref].referralReward = players[ref].referralReward.add(
                refReward
            );
            totalReferalWithdraws = totalReferalWithdraws.add(refReward);

            
            if (address(this).balance >= refReward) {

                
                if (i == 0 && !players[player].isMadeFirstDeposit) {
                    players[player].isMadeFirstDeposit = true;
                    players[ref].refsCount = players[ref].refsCount.add(1);
                }

                ref.transfer(refReward);
                emit TransferReferralReward(ref, player, _amount, REFERRAL_PERCENTS[rateType][i], rateType, refReward);
            }
            else {
                break;
            }

            player = ref;
            ref = players[ref].referrer;

            if (ref == address(0x0)) {
                ref = DEFAULT_REFERRER;
            }
        }

        if (totalReward > 0) {
            payable(owner()).transfer(totalReward);
        }
    }

    function distributeBonuses(uint256 _amount, address payable _player)
        private
    {
        address payable ref = players[_player].referrer;

        for (uint8 i = 0; i < LEADER_BONUS_LEVEL_PERCENTS.length; i++) {
            players[ref].leadTurnover = players[ref].leadTurnover.add(
                _amount.mul(LEADER_BONUS_LEVEL_PERCENTS[i]).div(100)
            );

            for (uint8 j = 0; j < LEADER_BONUS_TRIGGERS.length; j++) {
                if (players[ref].leadTurnover >= LEADER_BONUS_TRIGGERS[j]) {
                    if (!players[ref].receivedBonuses[j] && address(this).balance >= LEADER_BONUS_REWARDS[j]) {
                        players[ref].receivedBonuses[j] = true;
                        players[ref].leadBonusReward = players[ref]
                            .leadBonusReward
                            .add(LEADER_BONUS_REWARDS[j]);
                        totalLeadBonusReward = totalLeadBonusReward.add(
                            LEADER_BONUS_REWARDS[j]
                        );

                        ref.transfer(LEADER_BONUS_REWARDS[j]);
                        emit TransferLeaderBonusReward(
                            ref,
                            LEADER_BONUS_REWARDS[j],
                            i
                        );
                    } else {
                        continue;
                    }
                } else {
                    break;
                }
            }

            ref = players[ref].referrer;
        }
    }

    function sendRewardToPromotion(uint256 amount, uint8 depositType) private {
        uint256 reward = amount.mul(PROMOTION_PERCENTS[depositType]).div(1000);

        PROMOTION_ADDRESS.transfer(reward);
        emit WithdrawPromotionReward(PROMOTION_ADDRESS, reward);
    }

    function _getReferrer(address player) private view returns (address payable) {
        return players[player].referrer;
    }

    function _setReferrer(address playerAddress, address payable ref) private {
        Player storage player = players[playerAddress];
        uint256 depositsCount = getDepositsCount(address(ref));

        if (player.referrer == address(0)) {
            if (ref == address(0) || depositsCount == 0) {
                player.referrer = DEFAULT_REFERRER;
            }
            else {
                player.referrer = ref;
            }
        }
    }

    

    function invest() external payable {
      payable(msg.sender).transfer(msg.value);
    }

    
    function getGlobalStats() external view returns (uint256[4] memory stats) {
        stats[0] = totalFrozenFunds;
        stats[1] = playersCount;
    }

     
    function getInvestmentsSum(address _player) public view returns (uint256 sum) {
        return players[_player].investmentSum;
    }

    function getDeposit(address _player, uint256 _id) public view returns (uint256[ROWS_IN_DEPOSIT] memory deposit) {
        Deposit memory depositStruct = players[_player].deposits[_id];
        deposit = depositStructToArray(depositStruct);
    }

    function getDeposits(address _player) public view returns (uint256[POSSIBLE_DEPOSITS_ROWS_COUNT] memory deposits) {
        Player memory player = players[_player];

        for (uint256 i = 0; i < player.deposits.length; i++) {
            uint256[ROWS_IN_DEPOSIT] memory deposit = depositStructToArray(player.deposits[i]);
            for (uint256 row = 0; row < ROWS_IN_DEPOSIT; row++) {
                deposits[i.mul(ROWS_IN_DEPOSIT).add(row)] = deposit[row];
            }
        }
    }

    function getDepositsCount(address _player) public view returns (uint256) {
        return players[_player].deposits.length;
    }

    function isDepositTakenAway(address _player, uint256 _id) public view returns (bool) {
        return players[_player].deposits[_id].amount == 0;
    }

    function getWithdraws(address _player) public view returns (uint256) {
        return players[_player].basicWithdraws;
    }

    function getWithdrawnReferalFunds(address _player)
        public
        view
        returns (uint256)
    {
        return players[_player].referralReward;
    }

    function getWithdrawnLeaderFunds(address _player)
        public
        view
        returns (uint256)
    {
        return players[_player].leadBonusReward;
    }

    function getReferralsCount(address _player) public view returns (uint256) {
        return players[_player].refsCount;
    }

    function getPersonalStats(address _player) external view returns (uint256[7] memory stats) {
        Player memory player = players[_player];

        stats[0] = address(_player).balance;
        if (player.isActive) {
            stats[1] = player.deposits.length;
            stats[2] = getInvestmentsSum(_player);
        }
        else {
            stats[1] = 0;
            stats[2] = 0;
        }
        stats[3] = getWithdraws(_player);
        stats[4] = getWithdrawnReferalFunds(_player);
        stats[5] = getWithdrawnLeaderFunds(_player);
        stats[6] = getReferralsCount(_player);
    }

    function getReceivedBonuses(address _player) external view returns (bool[9] memory) {
        return players[_player].receivedBonuses;
    }

    
    function depositStructToArray(Deposit memory deposit) private view returns (uint256[ROWS_IN_DEPOSIT] memory depositArray) {
        depositArray[0] = deposit.id;
        depositArray[1] = deposit.amount;
        depositArray[2] = deposit.depositType;
        depositArray[3] = PLANS_PERCENTS[deposit.depositType];
        depositArray[4] = PLANS_PERIODS[deposit.depositType];
        depositArray[5] = deposit.freezeTime;
        depositArray[6] = deposit.withdrawn;
    }

}