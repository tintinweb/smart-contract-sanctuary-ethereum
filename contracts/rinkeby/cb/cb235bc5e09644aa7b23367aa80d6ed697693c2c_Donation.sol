/**
 *Submitted for verification at Etherscan.io on 2022-06-01
*/

pragma solidity ^0.4.25;

contract Donation {

    // 被捐贈者
    address target;

    // 最新捐款來源
    address  NewDonor;

    // 最新捐款金額
    uint NewValue;

    // 累計捐款金額
    uint AllValue;

    event LogDonate(
        address streamer, address donor, uint value);
    

    // 建構子，捐給誰
	constructor (address _target) public {
		target = _target;
	}

    // 輸入捐款金額，進行捐款
    function donate()
        public payable {
        require(msg.value > 0);
        
        target.transfer(msg.value);
        
        NewDonor = msg.sender;
        NewValue = msg.value;
        AllValue = AllValue + msg.value;

        
        emit LogDonate(
            target,
            msg.sender,
            msg.value);
    }

    // 顯示捐款給誰，捐到哪裡
    function getTarget() public view returns (address) {
        return target;
    }

    // 顯示最新捐款來源
    function getNewDonor() public view returns (address) {
        return NewDonor;
    }

    // 顯示最新捐款金額
    function getNewValue() public view returns (uint) {
        return NewValue;
    }

    // 顯示累積捐款金額
    function getAllValue() public view returns (uint) {
        return AllValue;
    }

}