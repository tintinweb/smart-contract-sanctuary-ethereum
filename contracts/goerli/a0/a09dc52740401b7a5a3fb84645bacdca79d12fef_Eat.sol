/**
 *Submitted for verification at Etherscan.io on 2022-11-26
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

contract Eat {
    // string[]  _menu = ["Spicy Thai Soup","Sour Soup","Chicken Galangal Soup","Isaan Soup","Beef Soup","Boiled Vegetable Soup","Fish Kidney Curry","Coconut Milk Curry w/ Rice Noodles","Green Curry Chicken","Thai Hanglay Curry"];

    // function addMenu(string memory food) public  {
    //     _menu.push(food);
    // }

    // function shouldEat() public view returns (string memory) {
    //     if (_menu.length == 0){
    //         return '';
    //     }
    //     string memory pickOne;  
    //     uint256 num;  
    //         num = _random();
    //         pickOne  = _menu[_random()];

    //     return pickOne;
    // }

    //  function allMenu() public view returns (string[] memory) {
    //     return _menu;
    // }

    // function _random() private view returns (uint256) {
    //     uint256 random = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender)));
    //     return _getFirstDigit(random);
    // }

    // function _log10(uint256 n) private pure returns(uint256) {
    //     uint256 count;
    //     while(n != 0) {
    //         count++;
    //         n /= 10;
    //     }
    //     return count;
    // }

    // function _getFirstDigit(uint256 n) private pure returns(uint256) {
    //     uint256 countOfDigits = _log10(n);
    //     return n / (10 ** (countOfDigits - 1));
    // }
}