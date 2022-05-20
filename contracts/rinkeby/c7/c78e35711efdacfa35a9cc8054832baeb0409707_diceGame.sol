/**
 *Submitted for verification at Etherscan.io on 2022-05-20
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.5.0;
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}
contract diceGame {
    using SafeMath for uint;
    address owner;
    uint256 private result;
    uint256 private jackpot;
    uint256 private blockHight; 
    mapping(address => uint) private jackpotList;
    struct User{
        address addr;
        uint256 amount;
    }

    constructor() public payable {
        owner = msg.sender;
    }

    /**
    * betType: 7:大 8:小
    **/
    function bet(uint256[] memory betType) public payable returns(uint256){
        uint amount = msg.value;
        require(amount % betType.length == 0, "Bet amount error");
        uint singlAmt = amount.div(betType.length);
        require(singlAmt >= 10000000000000000, "Bet amount have to more than 0.01 eth");
        // 中獎金額
        uint256 winAmt = 0;
        getRandom();
        if(result == 0) result = 1;
        if(result > 6) result = 6;
        for(uint256 i=0;i<betType.length;i++){
            // 如果是下7 = 大
            if(betType[i] == 7){ 
                // 判斷是否中獎 
                if(result > 3){
                    // 中獎金額
                    uint winMoney = amount.mul(4);
                    // 算出獎池錢
                    uint fee = winMoney.div(300);
                    // 加回獎池
                    jackpot = jackpot.add(fee);
                    // 算出實際中獎金額
                    winMoney = winMoney.sub(fee);
                    // 總中獎金額
                    winAmt = winAmt.add(winMoney);
                }
            } // 如果是下8 = 小
            else if(betType[i] == 8){ 
                // 判斷是否中獎  
                if(result < 4){
                    // 中獎金額
                    uint winMoney = amount.mul(4);
                    // 算出獎池錢
                    uint fee = winMoney.div(300);
                    // 加回獎池
                    jackpot = jackpot.add(fee);
                    // 算出實際中獎金額
                    winMoney = winMoney.sub(fee);
                    // 總中獎金額
                    winAmt = winAmt.add(winMoney);
                }
                     
            }else{
                 // 判斷是否中獎
                if(betType[i] == result){
                     // 中獎金額
                    uint winMoney = amount.mul(2);
                    // 算出獎池錢
                    uint fee = winMoney.div(300);
                    // 加回獎池
                    jackpot = jackpot.add(fee);
                    // 算出實際中獎金額
                    winMoney = winMoney.sub(fee);
                    // 總中獎金額
                    winAmt = winAmt.add(winMoney);
                } 
            }
        }
        require(address(this).balance > winAmt, "bank is down");
        // 退錢
        if(address(this).balance < winAmt)
            msg.sender.transfer(msg.value);
        jackpotList[msg.sender].add(betType.length); 
        if(winAmt > 0)
            msg.sender.transfer(winAmt);
        blockHight = block.number;
        return block.number;
    } 

    function getRandom() private returns(uint) {
        // 隨機產生1-6以內的數, 0-9:小  10-17: 大
		result = uint256(keccak256(abi.encode(msg.sender, owner, block.timestamp)))%6;
        return result + 1;
    }

    function getResult() public view returns(uint) {
        return result;
    }

    function getMoneyBack() public payable onlyOwner{
        msg.sender.transfer(address(this).balance);
    }

    modifier onlyOwner (){
        require(msg.sender == owner, "get out");
        _;
    }
    
    function getContractBalance() public view returns(uint256){
        return address(this).balance;
    }

    function getJackPotBalance() public view returns(uint256){
        return jackpot;
    }

    function getBolckNumber() public view returns(uint256){
        return blockHight;
    }
}