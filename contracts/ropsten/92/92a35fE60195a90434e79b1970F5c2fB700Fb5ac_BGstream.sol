/**
 *Submitted for verification at Etherscan.io on 2022-07-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

// /**
//  *  @title: BuidlGuidl Stream Contract
//  *  @author: supernova (supernovahs.eth)
//  *  @notice: BGstream is a contract that streams Ether to builders on the BuidlGuidl 
//  *     
//  */
contract BGstream {

    uint public immutable cap; // Max Ether to be withdrawn per frequency
    address payable public immutable  toAddress; // Beneficiary Builder
    uint64 public immutable frequency; // Frequency of withdrawal in seconds
    uint64 public  last; // Last time withdrawal was made

    error NotAuthorized(); 
    error NotEnough();

  //*************** Events  */  
  event Withdraw( address indexed to, uint256 amount, string reason );
  event Deposit( address indexed from, uint256 amount, string reason );

// /**
//  *  @notice: Set up the contract with the parameters
//  *  @param _toAddress: The benfeciary address that can withdraw Ether from the stream
//  *  @param _cap: The max amount of Ether that can be withdrawn per frequency
//  *  @param _frequency: The frequency of withdrawal in seconds
//  *  @param _startsFull: If the stream starts full or empty
//  *
//  */
    constructor(address payable _toAddress, uint256 _cap, uint64 _frequency, bool _startsFull) {
    toAddress = _toAddress;
    cap = _cap;
    frequency = _frequency;

    if(_startsFull){
      last = uint64(block.timestamp) - _frequency;
    }

    else

    {
      last = uint64(block.timestamp);
    }
  }

//   /**
//    * @dev: Get the current balance of the stream
//    * @return uint256: The current balance of the stream
//    */

  function streamBalance() public view returns (uint256 ){
      uint bal;
      uint64 _last = last;
      uint64 _frequency = frequency;
      uint _cap = cap;
      assembly{
          switch gt(sub(timestamp(),_last),_frequency)
    case 1{
        bal:= _cap
    }
    case 0 {
        bal:= div(mul(_cap,sub(timestamp(),_last)),_frequency)
    }
        }
    return bal;
  }

//   /**
//    * @dev: Deposit Ether to the Stream
//    * @param : reason Reason for the deposit (string)
//    */

  function streamDeposit(string memory reason) public  payable {
      emit Deposit( msg.sender, msg.value, reason );
   }


// /**
//  * @dev: Withdraw Ether from the Stream
//  * @param : amount The amount of Ether to withdraw
//  * @param : reason Reason for the withdrawal (string)
//  */
     function streamWithdraw(uint256 amount, string memory reason) public {
     if(msg.sender != toAddress) revert NotAuthorized();
     uint256 totalAmountCanWithdraw = streamBalance();
     if(totalAmountCanWithdraw<amount) revert NotEnough();
     uint64 _last = last;
     uint64 _timestamp = uint64(block.timestamp);
     uint64 _frequency = frequency;
     assembly{
     
     let cappedLast := sub( _timestamp,_frequency)
     if lt(_last,cappedLast){
       _last:= cappedLast
     }
        _last:= add(_last,div(mul(sub(_timestamp,_last),amount),totalAmountCanWithdraw))
        sstore(last.slot,_last)
     }
     
     emit Withdraw( msg.sender, amount, reason );
     toAddress.transfer(amount);
   }
  
//    /**
//     * @dev: Receive Ether 
//     */

    receive() external payable { streamDeposit(""); }

}