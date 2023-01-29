//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract BuyMeACoffee {
  //In this contract, we want people to fund the contract for a fixed amount and display a message
  // like memo to the users

  /******** Events **********/
  //We can emit event for tracking the memos, indexed variables are easier to access when needed
  event NewMemo(
    address indexed from,
    uint256 timestamp,
    string indexed name,
    string indexed message
  );

  /****** Error Functions **********/
  error BuyMeACoffee__NotOwner();
  error BuyMeACoffee__FundNotEnough();
  error BuyMeACoffee__WithdrawFailed();

  /******** Variables *******/
  // we can create strut for creating the memo, structs are like objects
  struct Memo {
    address from;
    uint256 timestamp;
    string name;
    string message;
  }
  //We can create a array of memos to store all memos
  Memo[] all_memos;

  // we need to set the owner, so that only owner can withdraw the funds from this contract
  // The immutable variables need to be initilized  in constructor
  address payable immutable i_owner;

  /******* Constructor *********/
  constructor() {
    i_owner = payable(msg.sender);
  }

  /****** Modifier ********/
  modifier only_owner() {
    if (i_owner != msg.sender) {
      revert BuyMeACoffee__NotOwner();
    }
    _;
  }

  /****** Buying cofee (sending eth to contract) logic ********/
  /**
   * @dev buying the coffee for the contract owner, ie. who deploys this
   * @param _name name of the cofee buyer
   * @param _message message from the buyer
   */
  function buyCofee(string memory _name, string memory _message)
    public
    payable
  {
    // We can revert if the fund is equal to 0
    if (msg.value == 0) revert BuyMeACoffee__FundNotEnough();

    // Pushing the memos to all_memos array
    Memo memory new_memo = Memo(msg.sender, block.timestamp, _name, _message);
    all_memos.push(new_memo);

    //We can emit a log event when new memo is created
    emit NewMemo(msg.sender, block.timestamp, _name, _message);
  }

  /***** Withdrawing the funds to owner *******/
  /**
   * @dev sends the entire balance in this contract to the owner
   */
  function withdraw() public only_owner {
    //using call to transfer the
    (bool callsuccess, ) = i_owner.call{ value: address(this).balance }('');
    if (!callsuccess) revert BuyMeACoffee__WithdrawFailed();
  }

  /****** Getter functions *********/
  /**
   * @dev retrieves all the memos received and stored in the blockchain
   */
  function getMemos() public view returns (Memo[] memory) {
    return all_memos;
  }
}