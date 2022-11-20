/**
 *Submitted for verification at Etherscan.io on 2022-11-20
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract Store {
    // slot 0
    address private owner;

    // slot 1
    uint256 private value;

    // slot 2
    uint8 private one;
    uint96 private two;
    bool private three;
    uint8 private four;

    // slot 3
    address private contract_address;

    // slot 4
    uint256 private max_value;

    // slot 5
    address private slot_five_address;
    uint24 private slot_five_24;
    uint32 private slot_five_32;
    uint40 private slot_five_40;

    // slot 6
    mapping (address => uint256) private response;

    // slot 7
    mapping (uint256 => address) private intMapping;

    // slot 8
    mapping (bytes32 => bool) private bytesMapping;

    // slot 9
    mapping (bytes32 => uint256) private bytesMappingInt;

    // slot 10
    uint256[] private arrayUint;

    // slot 11
    address[] private arrayAddress;

    // slot 12
    mapping (address => uint256[]) private mappingUintArray;

    // slot 13
    mapping (uint256 => address[]) private mappingAddressArray;

    // slot 14
    mapping (address => mapping (uint256 => bytes32)) private three_mapping;

    // slot 15
    mapping (address => mapping (uint256 => uint256[])) private three_mapping_uint_array;

    struct data_one{
        string name;
        uint256 id;
        address user;
    }

    // slot 16,17,18
    data_one private store_struct;

    // slot 19
    data_one[] private undefined_array;
 
    // slot 20,21,22,  23,24,25   26,27,28
    data_one[3] private defined_array;

    // slot 29
    mapping (uint256 => data_one) private mappingStruct;

    // slot 30
    mapping (uint256 => data_one[]) private mappingStructArray;

    // slot 31
    mapping (address => data_one[]) private mappingAddressStructArray;

    // slot 32
    mapping (address => mapping (uint256 => data_one)) private three_mapping_struct;

    // slot 33
    mapping (address => mapping (uint256 => data_one[])) private three_mapping_struct_array;

    constructor() {
        address address_one = 0x17Ca0928871b2dB9dd3B2f8b27148a436C24Baa8;
        address address_two = 0x98396fF397f78350BD40Ee70972B47A929E5CFE7;

        owner = msg.sender;
        value = type(uint96).max;

        one = 240;
        two = type(uint32).max;
        three = true;
        four = 195;

        slot_five_address = address(0x8077Dcdd2388F46725b7BE3259dAFc936558300e);
        slot_five_24 = type(uint24).max - type(uint8).max;
        slot_five_32 = type(uint32).max - type(uint16).max;
        slot_five_40 = type(uint40).max - type(uint24).max;

        contract_address = address(this);

        max_value = type(uint256).max;

        response[address_one] = 123456789;
        response[address_two] = 987456123;
        intMapping[897] = address_two;
        intMapping[797] = address_one;
        bytesMapping[getMapAddr(address_one)] = true;
        bytesMapping[getMapAddr(address_two)] = true;
        bytesMappingInt[getMapAddr(address_one)] = 98524165498;
        bytesMappingInt[getMapAddr(address_two)] = 87897465411347887;

        arrayUint.push(8769411);
        arrayUint.push(148982);
        arrayUint.push(58798412285);

        arrayAddress.push(address_one);
        arrayAddress.push(address_two);

        mappingUintArray[address_one].push(6979843);
        mappingUintArray[address_two].push(37878978);

        mappingAddressArray[8542123].push(address_one);
        mappingAddressArray[3634648].push(address_two);

        mappingStruct[432] = data_one("hello world",11,address(0xdead));

        mappingStructArray[5].push(data_one("hey cool",11,address_one));
        mappingStructArray[5].push(data_one("welcome",22,address_two));
        mappingStructArray[6].push(data_one("welcome",11,address_one));
        mappingStructArray[6].push(data_one("hey cool",22,address_two));

        mappingAddressStructArray[address_one].push(data_one("hey cool",11,address_one));
        mappingAddressStructArray[address_one].push(data_one("welcome",11,address_one));
        mappingAddressStructArray[address_one].push(data_one("hey welcome",6,address_one));
        mappingAddressStructArray[address_one].push(data_one("hey welcome",3,address_two));
        mappingAddressStructArray[address_two].push(data_one("welcome",22,address_two));
        mappingAddressStructArray[address_two].push(data_one("hey cool",22,address_two));

        undefined_array.push(data_one("hey cool",55,address_one));

        defined_array[0] = data_one("hey cool",11,address_one);
        defined_array[1] = data_one("hey cool",22,address_one);
        defined_array[2] = data_one("hey cool",33,address(0xdead));

        store_struct = data_one("hello",555,address_one);

        three_mapping[address_one][7] = keccak256(abi.encodePacked(("welcome to all")));
        three_mapping[address_two][8] = keccak256(abi.encodePacked(("welcome to all")));

        three_mapping_uint_array[address_one][5].push(type(uint40).max);
        three_mapping_uint_array[address_one][4].push(type(uint24).max);

        three_mapping_struct[address_one][5] = data_one("hey welcome",7,address_one);
        three_mapping_struct[address_one][4] = data_one("hey welcome",6,address_two);

        three_mapping_struct_array[address_one][444].push(data_one("End",142,address_one));
    }

    function getMapAddr(address slot) private pure returns (bytes32) {
        return bytes32(uint256(uint160(slot)));
    }
}