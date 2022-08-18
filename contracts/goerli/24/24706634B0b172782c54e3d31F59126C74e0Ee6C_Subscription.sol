// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Percentages.sol";

contract Subscription is Ownable, ReentrancyGuard, Percentages{
    address payable internal payout;
    constructor() {
        payout = payable(0x93175AD01498528826421DbbC0C971ba13128AAe);
        isOpen = true;
        feePercentage = 5;
    }

    struct Services {
        address payable creator;
        bool expires;
        uint256[] incrementsInDays;
        uint256[] prices;
        uint256 balance;
    }
    Services[] public services;

    struct Subscribers {
        address subscriber;
        uint256 serviceID;
        uint256 startTime;
        uint256 endTime;
    }
    Subscribers[] public subs;

    event subscribed(uint256 subID, address subOwner, address subscriber, uint256 cost, uint256 endTime);
    event created(uint256 subID, address subOwner, uint256[] dayIncrements, uint256[] priceIncrements);
    event withdrawal(uint256 subID, uint256 amount, address owner, uint256 fee);

    mapping(address => uint256[]) public addr_to_index;
    mapping(address => mapping(uint256 => uint256)) public sub_servID_endTime;
    mapping(address => mapping(uint256 => uint256)) public sub_servID_subsID;
    mapping(uint256 => bool) private isExempt;

    uint256 private feePercentage;

    bool public isOpen;

    modifier subOwner(uint256 ID) {
        require(_msgSender() == services[ID].creator, "Caller is not owner of Subscription");
        _;
    }

    function createSub(bool expires, uint256[] memory dayIncrements, uint256[] memory priceIncrements) external {
        require(isOpen, "Creating new services temporarily disabled");
        require(dayIncrements.length == priceIncrements.length, "Array lengths mismatch");
        uint256 index = services.length;

        addr_to_index[_msgSender()].push(index);
        services.push(Services(payable(_msgSender()), expires, dayIncrements, priceIncrements, 0));
        
        emit created(index, _msgSender(), dayIncrements, priceIncrements);
    }

    function ownerCreateSub(address payable creator, bool expires, uint256[] memory dayIncrements, uint256[] memory priceIncrements) external onlyOwner {
        uint256 index = services.length;
        addr_to_index[creator].push(index);
        services.push(Services(creator, expires, dayIncrements, priceIncrements, 0));
        
        emit created(index, creator, dayIncrements, priceIncrements);
    }

    function isActiveSubscriber(uint256 ID, address subscriber) external view returns(bool){
        return block.timestamp < sub_servID_endTime[subscriber][ID] || sub_servID_endTime[subscriber][ID] == 1;
    }

    function subscribe(uint256 ID, uint256 timeIncrement) external payable nonReentrant{
        require(services[ID].prices[timeIncrement] == msg.value, "Incorrect amount of ETH");
        uint256 endTime;
        services[ID].balance += msg.value;
        if(block.timestamp < sub_servID_endTime[_msgSender()][ID]) {
            sub_servID_endTime[_msgSender()][ID] += (86400 * services[ID].incrementsInDays[timeIncrement]);
            endTime = sub_servID_endTime[_msgSender()][ID];
            subs[sub_servID_subsID[_msgSender()][ID]].endTime = endTime;
        } else {
            endTime = services[ID].expires == false ? 1 : (services[ID].incrementsInDays[timeIncrement] * 86400) + block.timestamp;
            sub_servID_endTime[_msgSender()][ID] = endTime;
            sub_servID_subsID[_msgSender()][ID] = subs.length;
            subs.push(Subscribers(_msgSender(), ID, block.timestamp, endTime));
        }

        uint256 fee = 0;
        if(!isExempt[ID]) {
            fee = percentageOf(msg.value, feePercentage);
        }

        services[ID].balance = 0;
        (bool success,) = services[ID].creator.call{value: msg.value - fee}("");
        require(success, 'Transfer fail');

        (bool success2,) = payout.call{value: fee}("");
        require(success2, 'Transfer fail');

        emit subscribed(ID, services[ID].creator, _msgSender(), msg.value, endTime);
    }

    // function withdraw(uint256 ID) external nonReentrant subOwner(ID) {
    //     uint256 balance = services[ID].balance;
    //     require(balance > 0, "Balance is currently zero");

    //     uint256 fee = 0;
    //     if(!isExempt[ID]) {
    //         fee = percentageOf(balance, feePercentage);
    //     }

    //     services[ID].balance = 0;
    //     (bool success,) = services[ID].creator.call{value: balance - fee}("");
    //     require(success, 'Transfer fail');

    //     (bool success2,) = payout.call{value: fee}("");
    //     require(success2, 'Transfer fail');

    //     emit withdrawal(ID, balance, _msgSender(), fee);
    // }

    function changeSubPrice(uint256 ID, uint256 priceIncrement, uint256 costWei) external subOwner(ID) {
        require(costWei > 0, "Price cannot be zero");
        services[ID].prices[priceIncrement] = costWei;
    }

    function setPayout(address payable _payout) external onlyOwner {
        payout = _payout;
    }

    function setFeePercentage(uint256 _pct) external onlyOwner {
        feePercentage = _pct;
    }

    function setExempt(uint256 id, bool exempt) external onlyOwner {
        isExempt[id] = exempt;
    }

    function toggleOpen() external onlyOwner {
        isOpen = !isOpen;
    }

}