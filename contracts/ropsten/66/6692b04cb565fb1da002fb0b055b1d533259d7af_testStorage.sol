pragma solidity ^0.4.0;

contract testStorage {

	uint storeduint1 = 15;
	uint constant constuint = 16;
	uint128 investmentsLimit = 17055;
	uint32 investmentsDeadlineTimeStamp = uint32(now);

	bytes16 string1 = 'test1';
	bytes32 string2 = 'test1236';
	string string3 = 'lets string something';

	mapping (address => uint) uints1;
	mapping (address => DeviceData) structs1;

	uint[] uintarray;
	DeviceData[] deviceDataArray;

	struct DeviceData {
		string deviceBrand;
		string deviceYear;
		string batteryWearLevel;
	}

	function set() public {
		address address1 = 0xEC7d08f5a982B213A8BAf73B9e89df30656F5880;
		address address2 = 0x6e14b4305FBcaE514feb798f5885c65C3C97F22b;

		uints1[address1] = 88;
		uints1[address2] = 99;

		structs1[address1] = DeviceData('deviceBrand', 'deviceYear', 'wearLevel');
		structs1[address2] = DeviceData('deviceBrand', 'deviceYear', 'wearLevel');

		uintarray.push(8000);
		uintarray.push(9000);

		deviceDataArray.push( DeviceData('deviceBrand', 'deviceYear', 'wearLevel'));
		deviceDataArray.push( DeviceData('deviceBrand', 'deviceYear', 'wearLevel'));
	}

}