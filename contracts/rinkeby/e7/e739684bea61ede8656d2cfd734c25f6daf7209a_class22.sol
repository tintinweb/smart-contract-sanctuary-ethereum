/**
 *Submitted for verification at Etherscan.io on 2022-09-23
*/

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.8.0 <0.9.0;

contract class22{
    struct Sandwich{
        string name;
        string status;
    }

    Sandwich[] public sandwiches;

    function eatSandwich() public{
        sandwiches.push(Sandwich("aaaa","abc"));
    }


    uint256 public integer_1 = 1;
    uint256 public integer_2 = 2;
    string public string_1;
    
    event setNumber(string _from);

    //pure 不讀鏈上資料 不改鏈上資料     計算東西...
    function function_1(uint a,uint b) public pure returns(uint256){
        return a + 2*b;
    }
    
    //view 讀鏈上資料 不改鏈上資料   getName...
    function function_2() public view returns(uint256){
        return integer_1 + integer_2;
    }

    //修改鏈上資料    setName...
    function function_3 (string memory x) public returns( string memory){
        string_1 = x;
        return string_1;
    }
    
    //修改鏈上資料
    function class(string memory x) public returns(string memory){
        string_1 = x;
        return string_1;
    }
    
    function function_4(string memory x)public returns(string memory){
        string_1 = x;
        emit setNumber(string_1);
        return string_1;
    }

    function testRequire(uint _i) public pure {
        // Require should be used to validate conditions such as:
        // - inputs
        // - conditions before execution
        // - return values from calls to other functions
        require(_i > 10, "Input must be greater than 10");
    }

    function testRevert(uint _i) public pure {
        // Revert is useful when the condition to check is complex.
        // This code does the exact same thing as the example above
        if (_i <= 10) {
            revert("Input must be greater than 10");
        }
    }

    uint public num = 0;
    function testAssert() public view {
        // Assert should only be used to test for internal errors,
        // and to check invariants.

        // Here we assert that num is always equal to 0
        // since it is impossible to update the value of num
        assert(num == 0);
    }

    // custom error
    error InsufficientBalance(uint balance, uint withdrawAmount);

    function testCustomError(uint _withdrawAmount) public view {
        uint bal = address(this).balance;
        if (bal < _withdrawAmount) {
            revert InsufficientBalance({balance: bal, withdrawAmount: _withdrawAmount});
        }
    }

    // 實作紀錄送過來的 ether
    event setMoney(uint money);
    function buy() public payable{
        emit setMoney(msg.value);
    }
}