/**
 *Submitted for verification at Etherscan.io on 2022-07-07
*/

// Solidity program
// to store
// Employee Details
pragma solidity ^0.8.7;

// Creating a Smart Contract
contract StructDemo{

// Structure of employee
struct Choice{
  
  // State variables
  int qn_id;
  string question;
  int option_id;
  string option;
  int point;
  string user_address;
}

Choice []choices;

// Function to add
// employee details
function addchoices(
  int qn_id, string memory question, int option_id,string memory option,int point,string memory user_address
) public{
  Choice memory e
    =Choice(qn_id,
        question,
        option_id,
        option,
        point,
        user_address);
  choices.push(e);
}

event Output(
    string[] options,
    string[] questions
);
function getChoices(
  string memory user_address
) public returns(
  string[] memory
  ){
  string[] memory answers;
  string[] memory questionss;
  uint i;
  for(i=0;i<choices.length;i++)
  {
    Choice memory e = choices[i];
    // Looks for a matching
    // employee id
    if(keccak256(abi.encodePacked((e.user_address))) == keccak256(abi.encodePacked((user_address))))
    {   
        answers[answers.length]=e.option;
        questionss[questionss.length]=e.question;
        emit Output(answers,questionss);
        return answers;
    }
  }
}
}