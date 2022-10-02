/**
 *Submitted for verification at Etherscan.io on 2022-10-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

abstract contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() {
        _transferOwnership(_msgSender());
    }
    modifier onlyOwner() {
        _checkOwner();
        _;
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

abstract contract VRFConsumerBaseV2 {
    constructor(address _vrfCoordinator) {
        vrfCoordinator = _vrfCoordinator;
    }
    address private immutable vrfCoordinator;
    error OnlyCoordinatorCanFulfill(address have, address want);

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal virtual;
    function rawFulfillRandomWords(uint256 requestId,uint256[] memory randomWords) external {
        if (msg.sender != vrfCoordinator) {
            revert OnlyCoordinatorCanFulfill(msg.sender, vrfCoordinator);
        }
        fulfillRandomWords(requestId, randomWords);
    }
}

interface VRFCoordinatorV2Interface {
    function getRequestConfig() external view returns (uint16, uint32, bytes32[] memory);
    function requestRandomWords(
        bytes32 keyHash,
        uint64 subId,
        uint16 minimumRequestConfirmations,
        uint32 callbackGasLimit,
        uint32 numWords
    ) external returns (uint256 requestId);
    function createSubscription() external returns (uint64 subId);
    function getSubscription(uint64 subId) external view returns (
            uint96 balance,
            uint64 reqCount,
            address owner,
            address[] memory consumers);
    function requestSubscriptionOwnerTransfer(uint64 subId, address newOwner) external;
    function acceptSubscriptionOwnerTransfer(uint64 subId) external;
    function addConsumer(uint64 subId, address consumer) external;
    function removeConsumer(uint64 subId, address consumer) external;
    function cancelSubscription(uint64 subId, address to) external;
}

contract game is VRFConsumerBaseV2, Ownable {
    constructor(uint64 subscriptionId) VRFConsumerBaseV2(vrfCoordinator) {
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        s_subscriptionId = subscriptionId;
    }
    VRFCoordinatorV2Interface COORDINATOR;
    uint64 s_subscriptionId;
    address vrfCoordinator = 0x2Ca8E0C643bDe4C2E08ab1fA0da3401AdAD7734D;
    bytes32 keyHash = 0x79d3d8832d904592c0bf9818b621522c988bb8b0c05cdc3b15aea1b6e8db0c15;
    uint32 callbackGasLimit = 1000000;
    uint16 requestConfirmations = 3;
    uint32 numWords = 2;
    uint256 public FEE = 5;
    uint256 private valueGamer;
    uint256 public withdrawFunds;
    mapping(address => uint256) balances;
    mapping(uint256 => gameNumber) public dice;
    

    struct gameNumber {
        address winner;
        address player;
        uint256 bidValue;
        uint256 playerDiceRoll;
        uint256 casinoDiceRoll;
        bool paySuccess;
    }

    error ValueNotEven();
    modifier onlyEvenValue(uint256 _amount) {
        valueGamer = _amount / 2;
        if ((2 * valueGamer) != _amount) revert ValueNotEven();
        _;
    }

    event gameStart(uint256 indexed gameNumber, uint256 indexed gameValue);
    event gameEnd(uint256 indexed gameNumber, address indexed winner);

    function start(uint256 _amount) external onlyEvenValue(_amount) {
        require(_amount <= getBalanceAcc() && _amount != 0
        &&_amount <= withdrawFunds, "Not enough funds!");
        balances[_msgSender()] -= _amount;
        uint s_requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords);
        require (!dice[s_requestId].paySuccess, "Already payed!");
        dice[s_requestId].player = _msgSender(); 
        dice[s_requestId].bidValue = _amount;
        emit gameStart(s_requestId, dice[s_requestId].bidValue);
    }

    function fulfillRandomWords(uint256 s_requestId, uint256[] memory randomWords) internal override {
        dice[s_requestId].playerDiceRoll = randomWords[0]; 
        dice[s_requestId].casinoDiceRoll = randomWords[1];  
        if (dice[s_requestId].playerDiceRoll == dice[s_requestId].casinoDiceRoll) {
            dice[s_requestId].paySuccess = true;
            balances[dice[s_requestId].player] += dice[s_requestId].bidValue;
            emit gameEnd(s_requestId, dice[s_requestId].winner);
            return;
        }
        if (dice[s_requestId].playerDiceRoll > dice[s_requestId].casinoDiceRoll) {
            dice[s_requestId].paySuccess = true;
            dice[s_requestId].winner = dice[s_requestId].player;
            uint256 ownerAmount = ((dice[s_requestId].bidValue*2)/100)*FEE;
            uint256 prize = dice[s_requestId].bidValue*2-ownerAmount;
            balances[dice[s_requestId].winner] += prize;
            withdrawFunds -= prize;
            emit gameEnd(s_requestId, dice[s_requestId].winner);
        } else {
            dice[s_requestId].paySuccess = true;
            dice[s_requestId].winner = address(this);
            withdrawFunds += dice[s_requestId].bidValue;
            emit gameEnd(s_requestId, dice[s_requestId].winner);
        }
    }

    function getWinner(uint256  _count) public view returns (address) {
        return dice[_count].winner;
    }
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
    function getBalanceAcc() public view returns (uint256) {
        return balances[_msgSender()];
    }
    function wihdrawBalanceAcc() external {
        uint256 amount = balances[_msgSender()];
        balances[_msgSender()] -= amount;
        payable(_msgSender()).transfer(amount);
    }
    function withdraw() external onlyOwner {
        uint256 _amount = withdrawFunds;
        withdrawFunds -= _amount;
        payable(_msgSender()).transfer(_amount);
    }
    function addBalanceAcc() external payable onlyEvenValue(msg.value) {
        balances[_msgSender()] += msg.value;
    }
    function addBalanceContract() external payable onlyEvenValue(msg.value) {
        withdrawFunds += msg.value;
    }
}