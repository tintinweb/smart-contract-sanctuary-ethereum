// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

contract LayerrVariables {
  struct Fee {
    bool isSet;
    uint amount;
  }

  address public owner;
  address internal signerAddress;
  address internal withdrawAddress;
  uint internal fee;
  uint internal flatFee;
  mapping(address => Fee) internal specificFee;
  mapping(address => Fee) internal specificFlatFee;

  constructor() {
    owner = msg.sender;
  }

  function viewSigner() view external returns(address)
  {
    return(signerAddress);
  }

  function viewWithdraw() view external returns(address)
  {
    return(withdrawAddress);
  }

function viewFee(address _address) view external returns(uint)
{
  if (specificFee[_address].isSet) {
    return specificFee[_address].amount;
  } else {
    return fee;
  }
}

  function viewFlatFee(address _address) view external returns(uint)
  {
  if (specificFlatFee[_address].isSet) {
    return specificFlatFee[_address].amount;
  } else {
    return flatFee;
  }
  }

  function setSigner(address _signerAddress) external onlyOwner
  {
    signerAddress = _signerAddress;
  }

  function setWithdraw(address _withdrawAddress) external onlyOwner
  {
    withdrawAddress = _withdrawAddress;
  }

  function setFee(uint _fee) external onlyOwner
  {
    fee = _fee;
  }

  function setFlatFee(uint _flatFee) external onlyOwner
  {
    flatFee = _flatFee;
  }

  function setSpecificFee(address _address, uint _fee) external onlyOwner
  {
    specificFee[_address] = Fee({isSet: true, amount: _fee});
  }

  function setSpecificFlatFee(address _address, uint _flatFee) external onlyOwner
  {
    specificFlatFee[_address] = Fee({isSet: true, amount: _flatFee});
  }

  modifier onlyOwner() {
    require(msg.sender == owner, "ERROR");
    _;
  }
}