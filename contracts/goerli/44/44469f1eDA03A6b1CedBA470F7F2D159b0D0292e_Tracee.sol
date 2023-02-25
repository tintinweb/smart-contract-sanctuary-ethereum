/**
 *Submitted for verification at Etherscan.io on 2023-02-25
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.18 <0.9.0;

contract Tracee {
  struct Donation {
    string organizationName;
    string beneficiary;
    string department;
    string generation_date;
    string date_scanned;
    uint256 amount_in_usd;
    uint256 id;
  }
  address public owner;
  // In the future we will use this data structure to add more functionalities to the smart contract
  mapping(uint256 => Donation) private idToDonation;

  event DonationSent(
    uint256 indexed id,
    string indexed date_scanned,
    uint256 indexed amount_in_usd
  );

  constructor() {
    owner = msg.sender;
  }

  function sendDonation(
    string memory _organizationName,
    string memory _beneficiary,
    string memory _department,
    string memory _generation_date,
    string memory _date_scanned,
    uint256 _amount_in_usd,
    uint256 _id
  ) public {
    Donation memory donation = Donation(
      _organizationName,
      _beneficiary,
      _department,
      _generation_date,
      _date_scanned,
      _amount_in_usd,
      _id
    );
    idToDonation[_id] = donation;
    emit DonationSent(_id, _date_scanned, _amount_in_usd);
  }
}

// contract address on georli: 0x44469f1eDA03A6b1CedBA470F7F2D159b0D0292e