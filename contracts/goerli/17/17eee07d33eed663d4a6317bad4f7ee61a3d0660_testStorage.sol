/**
 *Submitted for verification at Etherscan.io on 2022-08-24
*/

/**
 *Submitted for verification at Etherscan.io on 2017-12-29
*/

pragma solidity ^0.8.0;

contract testStorage {

	uint storeduint1 = 15;
	uint constant constuint = 16;
	uint128 investmentsLimit = 17055;
	uint32 investmentsDeadlineTimeStamp = uint32(block.timestamp);

	bytes16 string1 = "test1";
	bytes32 string2 = "test1236";
	string string3 = "lets string something";

	mapping (address => uint) uints1;
	mapping (address => DeviceData) structs1;

	uint[] uintarray;
	DeviceData[] deviceDataArray;

	struct DeviceData {
		string deviceBrand;
		string deviceYear;
		string batteryWearLevel;
	}

	function setValue() public {
		address address1 = 0xbCcc714d56bc0da0fd33d96d2a87b680dD6D0DF6;
		address address2 = 0xaee905FdD3ED851e48d22059575b9F4245A82B04;

		uints1[address1] = 88;
		uints1[address2] = 99;

		DeviceData memory dev1 = DeviceData("deviceBrand", "deviceYear", "wearLevel");
		DeviceData memory dev2 = DeviceData("deviceBrand2", "deviceYear2", "wearLevel2");

		structs1[address1] = dev1;
		structs1[address2] = dev2;

		uintarray.push(8000);
		uintarray.push(9000);

		deviceDataArray.push(dev1);
		deviceDataArray.push(dev2);
	}
}