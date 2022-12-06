/**
 *Submitted for verification at Etherscan.io on 2022-12-06
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.12;

//import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeMath.sol";

contract Quiz {
    // Quiz 1
    function repeat4(string memory str) public pure returns(string memory) {
        bytes memory _str = bytes(str);

        require(_str.length == 1);

        bytes1 c = _str[0];
        require(
            (c >= '0' && c <= '9') // numeric
            ||
            (c >= 'a' && c <= 'z') // lower case
            ||
            (c >= 'A' && c <= 'Z') // upper case
            , "must be alphanumeric"
        );
        
        return string(abi.encodePacked(c, c, c, c));
    }

    // Quiz 2
    function desc(uint[] memory numbers) public pure returns(uint[] memory) {
        uint end = numbers.length - 1;
        for(uint i = 0; i < numbers.length - 1; i++) {
            for(uint l = 0; l < end; l++) {
                if(numbers[l] < numbers[l + 1]) {
                    (numbers[l + 1], numbers[l]) = (numbers[l], numbers[l + 1]);
                }
            }
        }
        return numbers;
    }

    // Quiz 3
    function toCentury(uint year) public pure returns(uint) {
        return (year / 100) + 1;
    }

    // Quiz 4
    function sequence(uint start, uint end, uint size) public pure returns(uint[] memory) {
        uint[] memory arr = new uint[](size);

        uint increase = ((end - start) / size) + 1;
        for(uint i = 0; i < size; i++) {
            arr[i] = start + (increase * i);
        }

        return arr;
    }

    // Quiz 5
    uint[] factArr;
    function factorization(uint num) public returns(uint[] memory) {
        delete factArr;

        for(uint i = 2; i <= num; i++) {
            while((num % i) == 0) {
                factArr.push(i);
                num /= i;
            }
        }

        return factArr;
    }

    // Quiz6
    uint[] largestArr;
    function pushLargest(uint num) public returns(uint[] memory) {
        if(largestArr.length < 4) {
            largestArr.push(num);

            // asc order
            uint end = largestArr.length - 1;
            for(uint i = 0; i < largestArr.length - 1; i++) {
                for(uint l = 0; l < end; l++) {
                    if(largestArr[l] > largestArr[l + 1]) {
                        (largestArr[l + 1], largestArr[l]) = (largestArr[l], largestArr[l + 1]);
                    }
                }
            }
        } else {
            uint idx = 999;
            for(uint i = 0; i < largestArr.length; i++) {
                if(largestArr[i] < num) {
                    idx = i;
                }
            }

            if(idx < largestArr.length) {
                for(uint i = 0; i < idx; i++) {
                    largestArr[i] = largestArr[i + 1];
                }
                largestArr[idx] = num;
            }
        }

        return largestArr;
    }

    // Quiz 7
    function post(string memory content) public pure {
        bytes memory _content = bytes(content);
        require(_content.length <= 100, "must be less than 100 characters");
    }

    // Quiz 8
    function digitToString(uint digit) private pure returns(string memory) {
        require(digit <= 60);
        
        uint units = digit % 10;
        uint tens = digit / 10;

        return (
            tens > 0
            ? string(abi.encodePacked(tens + 48, units + 48))
            : string(abi.encodePacked(units + 48))
        );
    }

    function dateFormat(uint sec) public pure returns(string memory) {
        uint second = sec % 60;
        uint minute = sec / 60;
        uint hour = minute / 60;
        uint day = hour / 24;

        string memory format;
        if(day > 0) format = string(abi.encodePacked(format, digitToString(day), "d "));
        if(hour > 0) format = string(abi.encodePacked(format, digitToString(hour), "h "));
        if(minute > 0) format = string(abi.encodePacked(format, digitToString(minute), "m "));
        if(second > 0) format = string(abi.encodePacked(format, digitToString(second), "s"));
        
        return format;
    }

    // 9)  https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeMath.sol 에서 tryadd, add, sub 함수를 도입해오세요.

    // 10) A contract 에 있는 변수 a를 10 증가시켜주는 함수를 B contract에서 구현하세요.

}