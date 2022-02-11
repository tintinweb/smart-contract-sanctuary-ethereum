pragma solidity ^0.8.0;

contract Test {
    uint256[] numbers = [
        0,
        1,
        2,
        3,
        4,
        5,
        6,
        7,
        8,
        9,
        10,
        11,
        12,
        13,
        14,
        15,
        16,
        17,
        18,
        19
    ];

    function PAPAddresses(uint256 offset, uint256 limit)
        public
        view
        returns (uint256[] memory)
    {
        if (limit == 0) return numbers;
        uint256 len = numbers.length;
        if (offset >= len) return new uint256[](0);
        if (offset + limit > len) limit = len - offset;
        uint256[] memory newNumbers = new uint256[](limit);
        for (uint256 i = 0; i < limit; i++) {
            newNumbers[i] = numbers[i + offset];
        }
        return newNumbers;
    }
}