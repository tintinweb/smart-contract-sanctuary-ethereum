// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Percentages.sol";

contract Subscription is Ownable, ReentrancyGuard, Percentages{
    address payable internal payout;
    constructor(address payable _payout) {
        payout = _payout;
    }

    event subscribed(uint256 subID, address subOwner, address subscriber, uint256 cost);
    event created(uint256 subID, address subOwner, uint256 cost);
    event terminated(uint256 subID, address subOwner);
    event withdrawal(uint256 amount, address owner, uint256 fee);

    mapping(uint256 => address payable) public subID;
    mapping(uint256 => uint256) public IDtoPrice;
    mapping(uint256 => uint256) private IDtoBalance;
    mapping(uint256 => bool) private isExempt;
    uint256 internal counter;

    uint256 private feePercentage;

    modifier subOwner(uint256 ID) {
        require(_msgSender() == subID[ID], "Caller is not owner of Subscription");
        _;
    }

    function incrementCounter() internal {
        counter += 1;
    }

    function getCounter() internal view returns(uint256) {
        return counter;
    }

    function createSub(uint256 costWei) external {
        require(costWei > 0, "Price cannot be zero");
        uint256 index = getCounter();
        subID[index] = payable(_msgSender());
        IDtoPrice[index] = costWei;
        
        emit created(index, _msgSender(), costWei);
        incrementCounter();
    }

    function subscribe(uint256 ID) external payable nonReentrant{
        require(msg.value == IDtoPrice[ID], "Incorrect amount of ETH");
        IDtoBalance[ID] += msg.value;

        emit subscribed(ID, subID[ID], _msgSender(), msg.value);
    }

    function withdraw(uint256 ID) external nonReentrant subOwner(ID) {
        uint256 balance = IDtoBalance[ID];
        require(balance > 0, "Balance is currently zero");

        uint256 fee = 0;
        if(!isExempt[ID]) {
            fee = percentageOf(balance, feePercentage);
        }

        IDtoBalance[ID] = 0;
        (bool success,) = subID[ID].call{value: balance - fee}("");
        require(success, 'Transfer fail');

        (bool success2,) = payout.call{value: fee}("");
        require(success2, 'Transfer fail');

        emit withdrawal(balance, _msgSender(), fee);
    }

    function changeSubPrice(uint256 ID, uint256 costWei) external subOwner(ID) {
        require(costWei > 0, "Price cannot be zero");
        IDtoPrice[ID] = costWei;
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

}