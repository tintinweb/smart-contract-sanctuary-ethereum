// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

// Пользователь заводит средства и указывает массив адресов которые могут снять эти средства, 
// если в течении unlockTimeGap не будет вызван метод ping, то средства будут доступны для снятия
// Если в течении unlockTimeGap будет вызван метод ping, то блокировка будет увеличена на unlockTimeGap
// Пользователь может вызвать метод withdraw и указать адрес, с которого он хочет снять средства
// Если адрес указан верно, и время блокировки вышло то средства будут переведены на адрес пользователя

contract AdvancedLock {
    event Lock(address indexed owner, address[] authorized, uint amount);
    event Withdrawal(address authorized, uint amount);
    event Ping(address indexed owner, uint32 time);

    struct LockedFunds {
        uint amount;
        uint unlockTime;
        address[] authorized;
    }

    uint public unlockTimeGap;

    mapping(address => LockedFunds) public lockedFunds;

    constructor(uint _unlockTimeGap) {
        unlockTimeGap = _unlockTimeGap;
    }

    function lockForAuthorized(address[] memory _authorized) external payable {
        require(msg.value > 0, "You need to send some Ether");
        require(_authorized.length > 0, "You need to authorize at least one address");
        LockedFunds storage funds = lockedFunds[msg.sender];
        require(funds.unlockTime == 0, "You already have funds locked");
        uint unlockTime = block.timestamp + unlockTimeGap;
        lockedFunds[msg.sender] = LockedFunds(
            msg.value,
            unlockTime,
            _authorized
        );

        emit Lock(msg.sender, _authorized, msg.value);
    }

    function ping() external {
        LockedFunds storage funds = lockedFunds[msg.sender];
        require(funds.unlockTime != 0, "You have no locked funds!");
        funds.unlockTime = block.timestamp + unlockTimeGap;

        emit Ping(msg.sender, uint32(funds.unlockTime));
    }

    function withdraw(address _stored) external {
        LockedFunds storage funds = lockedFunds[_stored];
        require(funds.unlockTime < block.timestamp, "Funds are locked");
        require(funds.amount > 0, "No funds to withdraw");
        bool isAuthorized = false;
        
        for (uint i = 0; i < funds.authorized.length; i++) {
            if (funds.authorized[i] == msg.sender) {
                isAuthorized = true;
                break;
            }
        }

        require(isAuthorized, "You are not authorized to withdraw");

        uint amount = funds.amount;
        funds.amount = 0;

        payable(msg.sender).transfer(amount);

        emit Withdrawal(msg.sender, amount);
    }
}