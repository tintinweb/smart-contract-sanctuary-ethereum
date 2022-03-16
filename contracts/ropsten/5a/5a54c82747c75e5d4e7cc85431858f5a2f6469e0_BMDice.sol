/**
 *Submitted for verification at Etherscan.io on 2022-03-16
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;


//CONTEXT
abstract contract Context 
{
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

// REENTRANCY GUARD
abstract contract ReentrancyGuard 
{
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

//OWNABLE
abstract contract Ownable is Context 
{
    address public _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() { address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function OwnershipRenounce() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function OwnershipTransfer(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    
}

//REFEREE
abstract contract BMDiceReferee
{
     function Resolve(uint256 id) external virtual;
}


contract BMDice is Ownable, ReentrancyGuard 
{
    
    enum DiceRoll {None, One, Two, Three, Four, Five, Six}
    enum Status {Idle, Rolling , Drop, Refunded}

    struct Roll 
    {
        address user;
        uint256 id;
        uint256 rollTimestamp;
        uint256 dropTimestamp;
        uint256 rollAmount;
        uint256 paidAmount;
        uint8 rewardMultiplier;
        DiceRoll guess;
        DiceRoll result;
        Status status;
        bool paid;
    }

    struct User 
    {
        uint256 rollsCount;
        uint256 rollsAmount;
        uint256 paidRollsCount;
        uint256 paidRollsAmount;
    }
    
    mapping(uint256 => Roll) public Rolls;
    mapping(address => User) public Users;
    mapping(address => uint256[]) public UserRolls;

    // Referee
    BMDiceReferee internal bMDiceReferee;

    // ID
    uint256 public currentRollIndex;
    
    // Variables
    uint8 public houseFee = 5;
    uint8 public rewardMultiplier = 10;
    uint256 public minimumAmount = 0.05 ether;
    uint256 public maximumAmount = 1 ether;

    // Stats
    uint256 internal rollsCount;
    uint256 internal rollsTotal;
    uint256 internal paidRollsCount;
    uint256 internal paidRollsTotal;

    // Events
    event RollEvent(address indexed sender, uint256 indexed id, int guess, uint256 timestamp, uint256 rollAmount, uint8 rewardMultiplier);
    event DropEvent(address indexed sender, uint256 indexed id, int guess, int result, uint256 rollTimestamp, uint256 dropTimestamp, uint256 rollAmount, uint8 rewardMultiplier, bool paid, uint256 paidAmount);
    event RefundRollEvent(uint256 indexed id, address user, bool paid);
    event MinimumAmountUpdatedEvent(uint256 minimumAmount);
    event MaximumAmountUpdatedEvent(uint256 maximumAmount);
    event DiceRefereeUpdated(address refereeAddress);
    event InjectFunds(address indexed sender);

    receive() external payable {}

    // MODIFIERS
    modifier notContract() 
    {
        require(!_isContract(msg.sender), "Contracts not allowed");
        require(msg.sender == tx.origin, "Proxy contracts not allowed");
        _;
    }

    modifier onlyReferee() 
    {
        require(msg.sender == address(bMDiceReferee), "Only referee contract allowed");
        _;
    }

    
    // INTERNAL FUNCTIONS ---------------->
    
    function _safeTransferBNB(address payable to, uint256 amount) internal 
    {
        to.transfer(amount);
    }


    function _isContract(address addr) internal view returns (bool) 
    {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }

    // EXTERNAL FUNCTIONS ---------------->
    
    function FundsInject() external payable onlyOwner 
    {
        emit InjectFunds(msg.sender);
    }
    
    function FundsExtract(uint256 value) external onlyOwner 
    {
        _safeTransferBNB(payable(_owner),  value);
    }
    
    function SetHouseFee(uint8 _houseFee) external onlyOwner 
    {
        houseFee = _houseFee;
    }
    
    function SetRewardMultiplier(uint8 _rewardMultiplier) external onlyOwner 
    {
        rewardMultiplier = _rewardMultiplier;
    }
    
    function SetMinimumAmount(uint256 _minimumAmount) external onlyOwner 
    {
        minimumAmount = _minimumAmount;
        emit MinimumAmountUpdatedEvent(minimumAmount);
    }
    
    function SetMaximumAmount(uint256 _maximumAmount) external onlyOwner 
    {
        maximumAmount = _maximumAmount;
        emit MaximumAmountUpdatedEvent(maximumAmount);
    }

    function SetReferee(address _refereeAddress) external onlyOwner 
    {
        bMDiceReferee = BMDiceReferee(_refereeAddress);
        emit DiceRefereeUpdated(_refereeAddress);
    }

    function RefundRoll(address user, uint256 id) external onlyOwner
    {
        require(Rolls[id].rollAmount != 0, "Roll not found");  
        require(Rolls[id].paid == false, "Roll already refunded");  
          
        Roll storage roll = Rolls[id];
        roll.paid = true;
        roll.paidAmount = roll.rollAmount;
        roll.rewardMultiplier = 0;
        roll.status = Status.Refunded;

        // Rrefund
        _safeTransferBNB(payable(roll.user), roll.rollAmount);

        emit RefundRollEvent(id, user, roll.paid);
   
    }
    
    function MakeRoll(int position) external payable nonReentrant notContract
    {
        
        require(position <= 6, "Wrong position");
        require(msg.value >= minimumAmount, "Roll amount must be greater than minimum amount");
        require(msg.value <= maximumAmount, "Roll amount must be less than maximum amount");

        // Roll
        address user = msg.sender;
        uint256 amount = msg.value;
        
        _safeRoll(user, amount, position);
        
    }
    
    function _safeRoll(address user, uint256 rollAmount, int position) internal
    {
        
        // Storing Roll
        Roll storage roll = Rolls[currentRollIndex];
        roll.user = user;
        roll.id = currentRollIndex;
        roll.rollTimestamp = block.timestamp;
        roll.guess = getPositionToRoll(position);
        roll.result = DiceRoll.None;
        roll.status = Status.Rolling;
        roll.rollAmount = rollAmount;
        UserRolls[user].push(currentRollIndex);

        // Resolve
        bMDiceReferee.Resolve(roll.id);

        // ID ++
        currentRollIndex++;
        
        // User Stats
        Users[user].rollsCount++;
        Users[user].rollsAmount += rollAmount;

        // Global Stats
        rollsCount++;
        rollsTotal += rollAmount;

        // Emit Event
        emit RollEvent(user, roll.id, getRollToPosition(roll.guess), roll.rollTimestamp, roll.rollAmount, roll.rewardMultiplier);

    }
    
    function Drop(uint256 rollId, uint256 result) external onlyReferee
    {
         _safeDrop(rollId, result);
    }
    
    function _safeDrop(uint256 rollId, uint256 result) internal
    {
   
        require(Rolls[rollId].rollAmount != 0, "Roll not found");

        DiceRoll resultAsRoll = getPositionToRoll(int(result));
        
        Roll storage roll = Rolls[rollId];
        roll.dropTimestamp = block.timestamp;
        roll.status = Status.Drop;
        roll.result = resultAsRoll;
          
        // Payment 
        if (roll.guess == roll.result)
        {
          
            uint256 reward = ((roll.rollAmount - (roll.rollAmount / 100 * houseFee)) * rewardMultiplier);

            roll.paid = true;
            roll.paidAmount = reward;
            roll.rewardMultiplier = rewardMultiplier;

            // Payment
            _safeTransferBNB(payable(roll.user), reward);

            // User Stats
            Users[roll.user].paidRollsCount++;
            Users[roll.user].paidRollsAmount += reward;

            // Global Stats
            paidRollsCount++;
            paidRollsTotal += reward;

        }
        
        emit DropEvent(address(this), roll.id, getRollToPosition(roll.guess), getRollToPosition(roll.result), roll.rollTimestamp, roll.dropTimestamp, roll.rollAmount, roll.rewardMultiplier, roll.paid, roll.paidAmount);
    }
    
    function getPositionToRoll(int position) internal pure returns (DiceRoll result)
    {
         if (position == 1) return DiceRoll.One;
         if (position == 2) return DiceRoll.Two;
         if (position == 3) return DiceRoll.Three;
         if (position == 4) return DiceRoll.Four;
         if (position == 5) return DiceRoll.Five;
         if (position == 6) return DiceRoll.Six;
         return  DiceRoll.None;
    }

    function getRollToPosition(DiceRoll roll) internal pure returns (int result)
    {
         if (roll == DiceRoll.One) return 1;
         if (roll == DiceRoll.Two) return 2;
         if (roll == DiceRoll.Three) return 3;
         if (roll == DiceRoll.Four) return 4;
         if (roll == DiceRoll.Five) return 5;
         if (roll == DiceRoll.Six) return 6;
         return 0;
    }

    function getUserRolls(address user, uint256 cursor, uint256 size) external view returns (uint256[] memory, Roll[] memory, uint256)
    {
        uint256 length = size;

        if (length > UserRolls[user].length - cursor) 
        {
            length = UserRolls[user].length - cursor;
        }

        uint256[] memory values = new uint256[](length);
        Roll[] memory userRolls = new Roll[](length);

        for (uint256 i = 0; i < length; i++) 
        {
            values[i] = UserRolls[user][cursor + i];
            userRolls[i] = Rolls[values[i]];
        }

        return (values, userRolls, cursor + length);
    }
    

    function getUserRollsLength(address user) external view returns (uint256) {
        return UserRolls[user].length;
    }
    
    function getUserRollId(address user, uint256 position) external view returns (uint256) {
        return UserRolls[user][position];
    }

    function getRoll(uint256 rollId) external view returns (Roll memory)
    {
        return Rolls[rollId];
    }
    
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function getStats() external view returns (uint256, uint256, uint256, uint256) {
        return (rollsCount, rollsTotal, paidRollsCount, paidRollsTotal);
    }

}