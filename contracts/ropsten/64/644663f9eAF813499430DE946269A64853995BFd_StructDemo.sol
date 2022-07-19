/**
 *Submitted for verification at Etherscan.io on 2022-07-19
*/

//SPDX-License-Identifier:UNLICENSED
pragma solidity ^0.8.7;

// Writing my smart contract
contract StructDemo{

// structure for each choice made by the user that is going to be recorded in the blockchain as part of transaction
struct Choice{
  // State variables
  int qn_id;                              // question id
  string question;                        // question
  int option_id;                          // option id
  string option;                          // option/choice
  int point;                              // point for the selected choice
  string user_address;                    // wallet address for the player
  string user_avatar;
  string username;
}

mapping(string=>int) Result;                 // mapping of user and resulting points

Choice [] choices;                          // instantiating the Choice structure

// Event to emit when transactions are recorded
event Output(int qn_id,string question,int option_id,string option,int point,string useraddress,string user_avatar,string username);
// Event to emit when quiz is completed
event FinalOutput(string user,int total,string user_avatar,string username);

// Function to add/record each choice to the blockchain (arguments based on choice structure)
function addchoices(
  int qn_id, string memory question, int option_id,string memory option,int point,string memory user_address,string memory user_avatar,string memory username
) public{
  Choice memory e
    =Choice(qn_id,
        question,
        option_id,
        option,
        point,
        user_address,
        user_avatar,
        username);
  choices.push(e);
  emit Output(qn_id,question,option_id,option,point,user_address,user_avatar,username);
}

// Function to add all the results to the blockchain. Arguments based on Result structure
function addresult(string memory user,int point,string memory user_avatar,string memory username) public{
    Result[user]=point;
    emit FinalOutput(user,point,user_avatar,username);
}

// Function to get user result from blockchain
function getResult(string memory _user) public view returns(int){
    return Result[_user];
}
}