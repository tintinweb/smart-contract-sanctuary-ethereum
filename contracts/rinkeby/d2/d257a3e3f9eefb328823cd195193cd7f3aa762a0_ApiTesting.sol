/**
 *Submitted for verification at Etherscan.io on 2022-05-03
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;
contract ApiTesting{

    mapping(uint256 => address) public address1;
    mapping(uint256 => address) public address2;
    
    event Changed(
        uint256 indexed number,
        uint256[] where,
        uint256[] addresses,
        uint256[] newStuff,
        uint256[] made
    );

    event address1Changed(uint256 indexed number, address indexed oldAddress1, address indexed newAddress1);

    event address2Changed(uint256 indexed number, address indexed oldAddress2, address indexed newAddress2);

    function changeAddres1(address _address1, uint256 number) public{
        address old = address1[number];
        address1[number] = _address1;

        emit address1Changed(number,old, address1[number]);
    }

    function changeAddres2(address _address2, uint256 number) public{
        address old = address2[number];
        address2[number] = _address2;

        emit address1Changed(number,old, address2[number]);
    }

    function changeArrays(uint256 number,
        uint256[] memory where,
        uint256[] memory addresses,
        uint256[] memory newStuff,
        uint256[] memory made) public {
            emit Changed(number, where, addresses, newStuff, made);
        }


}