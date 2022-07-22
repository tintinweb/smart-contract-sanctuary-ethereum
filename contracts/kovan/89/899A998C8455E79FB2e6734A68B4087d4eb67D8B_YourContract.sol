pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT



//import "@openzeppelin/contracts/access/Ownable.sol"; //https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol

contract YourContract {
  string public purpose = "Building Unstoppable Apps!!!";

  // 🙋🏽‍♂️ this is an error handler
  // error EmptyPurposeError(uint code, string message);

  constructor() {
    // 🙋🏽‍♂️ what should we do on deploy?
  }

  // this is an event for the function below
  event SetPurpose(address sender, string purpose);

  function setPurpose(string memory newPurpose) public {
    // 🙋🏽‍♂️ you can add error handling!

    // if(bytes(newPurpose).length == 0){
    //     revert EmptyPurposeError({
    //         code: 1,
    //         message: "Purpose can not be empty"
    //     });
    // }

    purpose = newPurpose;

    emit SetPurpose(msg.sender, purpose);
  }
}