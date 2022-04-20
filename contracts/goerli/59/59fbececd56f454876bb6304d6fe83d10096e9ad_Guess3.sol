/**
 *Submitted for verification at Etherscan.io on 2022-04-20
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

contract Guess3 {

    event Guessing(uint256 Result, string Outcome, uint256 Amount);
    event Lucky(uint256 Guess1,uint256 Guess2,uint256 Guess3);
    string outcome;

    address payable admin;
    uint256 randNonce;
    uint256 public result;
    uint256 public result1;
    uint256 public result2;
    uint256 public result3;
    uint256[] public results;
    
    constructor(){
        admin = payable(msg.sender);
        bonus = 60; //percentage
    }
    
    // Defining a function to generate a random number
    function randMod() internal returns(uint256){
        // increase nonce
        randNonce++;
        result = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, randNonce))) % 10;
        result1 = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, randNonce+10))) % 10;
        result2 = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, randNonce+11))) % 10;
        result3 = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, randNonce+12))) % 10;
        return result;
    }
    
    function viewResult() public view returns(uint256 Result) {
        return (result);
    }
    uint8 bonus;
    modifier onlyOwner {
        require(msg.sender == admin, "onlyOwner" );
        _;
    }
    function setBonus(uint8 _bonus) public onlyOwner {
        bonus = _bonus;
    }
    function guessNumber(uint8 _number, uint8 _number2,uint8 _number3) public payable returns(uint256 Result)  {
        require(msg.value>0, " Nill");
        uint256 amount;
        randMod();
        bonus = uint8(result*10);
        if(_number == result || _number2 == result || _number3 == result){
            outcome = " Hooray!! You Won";
           amount = msg.value*(100+bonus)/100;
           payable(msg.sender).transfer(amount);
        }else {
            outcome = "Ooops You Lost, better luck next time";
            amount =0;
        }
        results.push(result);
        if(results.length>10){
          _remove(0);
        }

     //   _countResult();
        emit Guessing(result,outcome,amount);
        return(result);
    }
    function luckyDip() public payable returns(uint,uint,uint,uint){
        require(msg.value>0, " Nill");
        uint256 amount;
        randMod();
        bonus = uint8(result*10);
        if(result1 == result || result2 == result || result3 == result){
            outcome = " Hooray!! You Won";
           amount = msg.value*(100+bonus)/100;
           payable(msg.sender).transfer(amount);
        }else {
            outcome = "Ooops You Lost, better luck next time";
            amount = 0;
        }
        results.push(result);
        if(results.length>10){
          _remove(0);
        }

     //   _countResult();
        emit Guessing(result,outcome,amount);
        emit Lucky(result1,result2,result3);
        return(result,result1,result2,result3);
    }
    function _remove(uint8 _num) internal {
        for (uint8 i=_num; i<results.length-1;i++){
            results[i] = results[i+1];
        }
        results.pop();
    }
    function countResult() public view returns(uint8,uint8,uint8,uint8,uint8) {
        uint8 evenResult;
        uint8 oddResult;
        uint8 firstGroup;
        uint8 secondGroup;
        uint8 thirdGroup;

        for(uint i=0; i<results.length;i++){
            if(results[i] == 0 || results[i] == 1 ||results[i] == 2 ||results[i] == 3) {
                firstGroup++;
            }else if (results[i] == 4 || results[i] == 5 ||results[i] == 6){
                secondGroup++;
            }else {
                thirdGroup++;
            }
            if(results[i] == 0 || results[i] == 2 ||results[i] == 4 ||results[i] == 6 ||results[i] == 8){
                evenResult++;
            }else{
                oddResult++;
            }    
        }

        return (firstGroup,secondGroup,thirdGroup,evenResult,oddResult);
    }
    // function _countResult1(uint256 _result) internal {
    //     if(_result == 0 || _result == 2 ||_result == 4 ||_result == 6 ||_result == 8) {
    //         evenResult++;
    //     } else {
    //         oddResult++;
    //     }
    // }
    //  function displayGroup() public view returns(uint,uint,uint,uint,uint){
    //     _countResult;
    //     return (firstGroup,secondGroup,thirdGroup,evenResult,oddResult);
    // }

    // function displayEvenPercentage() public view returns(uint256) {
    //     return evenResult*100/(oddResult+evenResult);
    // }
    function withdrawAll() external onlyOwner {
        require(address(this).balance > 0, "No funds to withdraw");
        uint256 contractBalance = address(this).balance;

        _withdraw(admin, contractBalance );
    }
    
    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }

    receive() external payable {}
}