//SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

import "./Proxiable.sol";

contract MyContract is Proxiable {

    address public owner;
    uint    public count;
    bool    public initalized = false;


    // struct info{
    //     uint256 a;
    //     uint256 b;}

    // mapping(address =>info) public map;

    // info [] public infoo;

    // function testing(uint256 _a,uint256 _b)public returns(info memory) {

    //     map[msg.sender]=info({
    //         a:_a,
    //         b:_b
    //     });
    //     // info memory object;
    //     // object.a=20;
    //     // object.b=20;
    //     // infoo.push(object);
        
    //     return map[msg.sender];
    // }
    // function ADD()public view returns(uint256){
    //     return map[msg.sender].a+map[msg.sender].b;
    // }
    // function SUB()public view returns(uint256){
    //     return map[msg.sender].a-map[msg.sender].b;
    // }



    function initialize() public {
        require(owner == address(0), "Already initalized");
        require(!initalized, "Already initalized");
        owner = msg.sender;
        initalized = true;
    }

    function increment() public {
        count++;
    }

    function updateCode(address newCode) onlyOwner public {
        updateCodeAddress(newCode);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner is allowed to perform this action");
        _;
    }
}