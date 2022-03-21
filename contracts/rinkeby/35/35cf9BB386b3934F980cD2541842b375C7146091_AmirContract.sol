/**
 *Submitted for verification at Etherscan.io on 2022-03-21
*/

pragma solidity >=0.7.0 <0.9.0;

contract AmirContract {
    string public name;

    constructor() public {
        name = "amir babazadeh";
    }

    function getName() public view returns (string memory) {
        return name;
    }
}