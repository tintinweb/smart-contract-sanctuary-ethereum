pragma solidity ^0.4.23;

// With love from Evgeny!
contract HardcodedMarriage {

  string public partner_1_name;
  string public partner_2_name;

  constructor() public {
    partner_1_name = 'Lev';
    partner_2_name = 'Polina';
  }

  function getDeclaration() pure public returns (string) {
      return 'Lev & Polina got married on 14th of July! ♡♡♡';
  }
}