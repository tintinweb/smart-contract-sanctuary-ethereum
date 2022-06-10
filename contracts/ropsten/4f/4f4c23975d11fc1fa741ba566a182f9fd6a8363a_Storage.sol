/**
 *Submitted for verification at Etherscan.io on 2022-06-10
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 * @custom:dev-run-script ./scripts/deploy_with_ethers.ts
 */
contract Storage {
    address public owner;
    uint256 public number;
//     Gaurds 607c3be682b8d60357589ec5bdb724cb7f35b480aee3931efc502daca7798535
//     Faculty 67035ee7036953bb8cdecf0fe05c8fe909d408890942164be6d421048d03d53b
//     Admin a729ef4e25027bc652fc8b5c4d1d902947361fa7c8e7b4905e877823f27331b3
//     Students 6d7942b32c5633723435ccc7414ccb4e054f91ce4a595460bedf2f56bb0f5a5a
    struct record{
        address owner;
        mapping (address => bool) whitelist;
    }
    struct list{
        address owner;
        mapping(address=>bool) whitelist;
    }
    mapping (bytes32 => record) access_control_list;
    mapping (address => bool) whitelist;
    event valueUpdated(uint old,uint current,string message);
    event callingAddress(address _callee);
    modifier onlyOwner(){
        require(msg.sender==owner,"user is not owner");
        _;
    }
    modifier onlyGuards(){
        require(access_control_list[0x607c3be682b8d60357589ec5bdb724cb7f35b480aee3931efc502daca7798535].whitelist[msg.sender]);
        _;
    }
    modifier hasRole(bytes32 _roll_type,address _address){
        require(access_control_list[_roll_type].owner == _address,"User does not have assigned role");
        _;
    }
    modifier isAllowed(bytes32 _roll_type){
        require(access_control_list[_roll_type].whitelist[msg.sender],"User not in whitelist");
        _;
    }

    constructor() {
        owner=msg.sender;
        emit callingAddress(msg.sender);
    }
    


    function addRole(bytes32 _roll_type,address _owner) onlyOwner public{
        access_control_list[_roll_type].owner=_owner;
    }

    function addTowhitelist(bytes32 _roll_type,address _address) hasRole(_roll_type,msg.sender) public{
        access_control_list[_roll_type].whitelist[_address]=true;
    }

    function store(uint256 _num) onlyGuards public {
        uint256 temp=number;
        number = _num;
        emit callingAddress(msg.sender);
        emit valueUpdated(temp,_num,"Value Updated");
    }

    /**
     * @dev Return value 
     * @return value of 'number'
     */
    // function retrieve() public view returns (uint256){
    //     return number;
    // }
}