//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Marks {
    string[] s_marks;
    mapping(address => string) s_marksMapping;

    function makeMark(string memory mark)
        public
        onlyOneMark
        atlestOneLetter(mark)
        notMoreThan20Letters(mark)
    {
        s_marks.push(mark);
        s_marksMapping[msg.sender] = mark;
        emit MarkMade(msg.sender, mark);
    }

    function getMark(address markOwner) public view returns (string memory) {
        return s_marksMapping[markOwner];
    }

    function getMarksCount() public view returns (uint256) {
        return s_marks.length;
    }

    function getStringLength(string memory argument)
        private
        pure
        returns (uint256)
    {
        return bytes(argument).length;
    }

    modifier onlyOneMark() {
        uint256 markLength = getStringLength(s_marksMapping[msg.sender]);
        if (markLength > 0) {
            revert User_Already_Made_A_Mark(msg.sender);
        }
        _;
    }
    modifier notMoreThan20Letters(string memory mark) {
        if (getStringLength(mark) > 20)
            revert Mark_Must_Be_20_Letters_Long(getStringLength(mark));
        _;
    }
    modifier atlestOneLetter(string memory mark) {
        if (getStringLength(mark) == 0) revert Mark_Cant_Be_0_Letters_Long();
        _;
    }

    event MarkMade(address indexed mark_Maker, string mark);

    error Mark_Cant_Be_0_Letters_Long();
    error User_Already_Made_A_Mark(address mark_Maker);
    error Mark_Must_Be_20_Letters_Long(uint mark_Letters_Count);
}