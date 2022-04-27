/**
 *Submitted for verification at Etherscan.io on 2022-04-27
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

contract GasTutorial {

    struct VestingInfo {
		uint256 timestamp;
		uint256 genesisTimestamp;
		uint256 totalAmount;
		uint256 tgeAmount;
		uint256 cliff;
		uint256 duration;
		uint256 releasedAmount;
		uint256 eraBasis;
		address beneficiary;
		uint256 participant;
		uint256 status;
		uint256 price;
		bool    redeemable;
	}
	VestingInfo[] private _beneficiaries;

    uint256 a = 0;
    uint256 b; 
    uint256 _totalAmount = 0;

    // 最简单的加法
    function addOnce() public {
        a++;
    }

    // 死循环
    function infiniteLoop() public {
        while(true) {
            a++;
        }
    }

    function getA() public view returns(uint256) {
        return a;
    }

    
    // Runtime Error testing
    function requireTest() public payable {
        require(a > 3, "a must bigger than 2");
        b = 50;
        require(msg.value > 1000000000, "payment must bigger than 1Gwei");
        b = 100;
    }

    function getB() public view returns(uint256) {
        return b;
    }

    // 添加捐赠人模拟
    function addBeneficiary() public {
		VestingInfo storage info = _beneficiaries.push();

		info.timestamp = block.timestamp;
		info.beneficiary = msg.sender;
		info.genesisTimestamp = block.timestamp + 2 * 3600;
		info.totalAmount = getTotal();
		info.tgeAmount = 100000000000000000;
		info.cliff = 2 * 3600;
		info.duration = 48 * 3600;
		info.participant = 2;
		info.status = 1;
		info.eraBasis = 60;
		info.price = 2666666; 
		info.redeemable = true;

        _totalAmount = _totalAmount + 500000000000000000;
    }

    function getTotal()	private view returns (uint256) {
		uint256 totalAmount = 0;
		for (uint256 i = 0; i < _beneficiaries.length; i++) {
            totalAmount = totalAmount + _beneficiaries[i].totalAmount; //累加，每增加一个，GAS增加2886
		}
		return totalAmount;
	}

    // 获取捐赠人
    function getBeneficiaries() public view returns(uint256, VestingInfo[] memory) {
        return (_beneficiaries.length, _beneficiaries);
    }
}