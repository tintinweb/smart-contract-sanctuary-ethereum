/**
 *Submitted for verification at Etherscan.io on 2022-12-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

struct lotterySession {
    // mappings and dynamic arrays always start in new slots
    mapping (uint256 => address) slots;
    uint256[] filledSlots;

    // 1+1+20=22 bytes consume one slot
    bool open;
    uint8 profitPercent;
    address winnerAddress;

    // uint256 consumes one slot
    uint256 totalSlots;
    uint256 slotPrice;
    uint256 winnerSlot;
    uint256 balance;
}

struct sessionParams {
    uint8 profitPercent;
    uint256 totalSlots;
    uint256 slotPrice;
}

library SessionMethods {

    function isOpen(lotterySession storage self) public view returns (bool) {
        return self.open;
    }

    function getFilledSlots(lotterySession storage self) public view returns (uint256[] memory) {
        return self.filledSlots;
    }

    function getTotalSlots(lotterySession storage self) public view returns (uint256) {
        return self.totalSlots;
    }

    function getSlotPrice(lotterySession storage self) public view returns (uint256) {
        return self.slotPrice;
    }

    function getBalance(lotterySession storage self) public view returns (uint256) {
        return self.balance;
    }

    function getProfitPercent(lotterySession storage self) public view returns (uint8) {
        return self.profitPercent;
    }

    function getWinnerSlot(lotterySession storage self) public view returns (uint256) {
        return self.winnerSlot;
    }

    function getWinnerAddress(lotterySession storage self) public view returns (address) {
        return self.winnerAddress;
    }

    function start(lotterySession storage self, sessionParams memory _params) internal {
        self.totalSlots = _params.totalSlots;
        self.slotPrice = _params.slotPrice;
        self.profitPercent = _params.profitPercent;
        self.open = true;
    }

    function stop(lotterySession storage self) internal {
        self.open = false;
    }

    function reset(lotterySession storage self) internal {
        for (uint256 i = 1; i <= self.totalSlots; i++) {
            self.slots[i] = address(this);
        }

        while (self.filledSlots.length > 0) {
            self.filledSlots.pop();
        }

        self.open = false;
        self.totalSlots = 0;
        self.winnerSlot = 0;
        self.balance = 0;
        self.winnerAddress = address(this);
    }

    function isSlotAvailable(lotterySession storage self, uint256 _slotNum) public view returns (bool) {
        return (
            self.filledSlots.length < self.totalSlots &&
            _slotNum <= self.totalSlots &&
            self.slots[_slotNum] == address(this)
        );
    }

    function buySlot(lotterySession storage self, uint256 _slotNum, address _buyer) internal {
        self.slots[_slotNum] = _buyer;
        self.filledSlots.push(_slotNum);
        self.balance += self.slotPrice;
    }

    function selectWinner(lotterySession storage self, uint256 _randomVal) internal {
        if (self.filledSlots.length > 0) {
            self.winnerSlot = self.filledSlots[_randomVal % self.filledSlots.length];
            self.winnerAddress = self.slots[self.winnerSlot];
        }
    }

}

contract cryptoLottery {

    struct lotteryConfig {
        uint8 minProfitPercent;
        uint8 maxProfitPercent;
        uint256 minSlots;
        uint256 maxSlots;
        uint256 minSlotPrice;
    }

    struct connectResponse {
        lotteryConfig config;
        uint256[] filledSlots;
        uint256 totalSlots;
        uint256 slotPrice;
        uint256 prevWinnerSlot;
        bool open;
        uint8 profitPercent;
        address prevWinnerAddress;
    }

    address payable public owner;

    lotteryConfig public config;
    lotterySession public session;
    using SessionMethods for lotterySession;

    event Transaction(address indexed _to, uint256 indexed _amount, string _comment);
    event Action(string _comment);

    constructor() {
        owner = payable(msg.sender);

        config = lotteryConfig({
                minSlots: 10,
                maxSlots: 1000,
                minSlotPrice: 0.005 ether,
                minProfitPercent: 20,
                maxProfitPercent: 50
        });

        session.profitPercent = config.minProfitPercent;
        session.slotPrice = config.minSlotPrice;
        session.winnerAddress = address(this);
    }

    fallback() external payable {
        emit Transaction(msg.sender, msg.value, "Reverted call to fallback function");
        revert();
    }

    receive() external payable {
        emit Transaction(msg.sender, msg.value, "Money received on receive function");
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Must be the owner");
        _;
    }

    modifier lotteryOpen() {
        require(session.isOpen(), "Lottery session is closed");
        _;
    }

    modifier lotteryClosed() {
        require(session.isOpen() == false, "Lottery session is open");
        _;
    }

    function checkOwner(address _address) public view returns (bool) {
        return _address == owner;
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    // owner can withdraw amounts only when lottery is not open
    function withdraw(uint256 _amount) external onlyOwner lotteryClosed {
        require(_amount <= getBalance(), "Insufficient balance");

        (bool sent, ) = owner.call{value: _amount}("");
        require(sent, "Transfer to owner failed");

        emit Transaction(owner, _amount, "Money transferred on withdraw function");
    }

    // owner can transfer amounts only when lottery is not open
    function transfer(address payable _receiver, uint256 _amount) public onlyOwner lotteryClosed {
        require(_amount <= getBalance(), "Insufficient balance");

        (bool sent, ) = _receiver.call{value: _amount}("");
        require(sent, "Transfer failed");

        emit Transaction(_receiver, _amount, "Money transferred on transfer function");
    }

    // owner can be modified only when lottery is not open
    function transferOwnership(address payable _newOwner) external onlyOwner lotteryClosed {
        require(_newOwner != owner, "Cannot re-assign self");
        owner = _newOwner;

        emit Action("Contract owner changed");
    }

    function setConfig(lotteryConfig calldata _config) external onlyOwner {
        config.minSlots = _config.minSlots;
        config.maxSlots = _config.maxSlots;
        config.minSlotPrice = _config.minSlotPrice;
        config.minProfitPercent = _config.minProfitPercent;
        config.maxProfitPercent = _config.maxProfitPercent;

        emit Action("Lottery limits modified");
    }

    function startLottery(sessionParams calldata _params) external onlyOwner lotteryClosed {
        require(_params.totalSlots >= config.minSlots && _params.totalSlots <= config.maxSlots, "Invalid number of slots");
        require(_params.slotPrice >= config.minSlotPrice, "Invalid slot slotPrice");
        require(_params.profitPercent >= config.minProfitPercent && _params.profitPercent <= config.maxProfitPercent, "Invalid profit percentage");

        session.reset();
        session.start(_params);

        emit Action("Lottery session started");
    }

    // winner will be decided and paid automatically when lottery is closed
    function stopLottery() external onlyOwner lotteryOpen {
        session.stop();

        emit Action("Lottery session stopped");

        uint256 randomVal = uint256(keccak256(abi.encodePacked(
            block.difficulty,
            block.timestamp,
            session.getFilledSlots()
        )));

        session.selectWinner(randomVal);

        address winnerAddress = session.getWinnerAddress();

        // if slots were sold
        if (winnerAddress != address(this)) {
            emit Action("Lottery winner announced");

            uint256 sessionBalance = session.getBalance();
            uint256 lotteryAmount = sessionBalance * (100 - uint256(session.getProfitPercent()));
            lotteryAmount /= 100;
            assert(lotteryAmount < sessionBalance); // safety check

            transfer(payable(winnerAddress), lotteryAmount);
        } else {
            emit Action("Lottery stopped before any slots were sold");
        }
    }

    function onConnect() external view returns (connectResponse memory) {
        return connectResponse({
            config: config,
            filledSlots: session.getFilledSlots(),
            totalSlots: session.getTotalSlots(),
            slotPrice: session.getSlotPrice(),
            prevWinnerSlot: session.getWinnerSlot(),
            profitPercent: session.getProfitPercent(),
            open: session.isOpen(),
            prevWinnerAddress: session.getWinnerAddress()
        });
    }

    function buySlot(uint256 _slotNum) external payable lotteryOpen {
        require(msg.sender != owner, "Owner cannot participate");
        require(msg.value >= session.getSlotPrice(), "Invalid amount to buy a slot");
        require(session.isSlotAvailable(_slotNum), "Specified slot is not available");

        session.buySlot(_slotNum, msg.sender);

        emit Transaction(msg.sender, msg.value, "Transaction received for one lottery slot");
    }

    // transfer all remaining balance to owner and delete the contract from EVM
    function destroy() external onlyOwner lotteryClosed {
        selfdestruct(owner);
    }

}