/**
 *Submitted for verification at Etherscan.io on 2023-02-26
*/

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
    string generationDate;
    string dateScanned;
    uint256 amountInUsd;
    uint256 donaitionId;
  }
  address public owner;
  // In the future we will use this data structure to add more functionalities to the smart contract
  mapping(uint256 => Donation) private idToDonation;

  event DonationSent(
    uint256 indexed donaitionId,
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
    string memory _generationDate,
    string memory _dateScanned,
    uint256 _amountInUsd,
    uint256 _donationId
  ) public {
    Donation memory donation = Donation(
      _organizationName,
      _beneficiary,
      _department,
      _generationDate,
      _dateScanned,
      _amountInUsd,
      _donationId
    );
    idToDonation[_donationId] = donation;
    emit DonationSent(_donationId, _dateScanned, _amountInUsd);
  }
}

// contract address on georli: 0xEeef59C07908Ba5331E17072ed766cdfAA2dC4Ff