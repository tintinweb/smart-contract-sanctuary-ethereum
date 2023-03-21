// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./interfaces/ILayerrVariables.sol";

contract LayerrVariables is ILayerrVariables {
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

  /**
  * @dev see ILayerrVariables
  */
  function viewSigner() view external returns(address)
  {
    return(signerAddress);
  }

  /**
  * @dev see ILayerrVariables
  */
  function viewWithdraw() view external returns(address)
  {
    return(withdrawAddress);
  }

  /**
  * @dev see ILayerrVariables
  */
  function viewFee(address _address) view external returns(uint)
  {
    if (specificFee[_address].isSet) {
      return specificFee[_address].amount;
    } else {
      return fee;
    }
  }

  /**
  * @dev see ILayerrVariables
  */
  function viewFlatFee(address _address) view external returns(uint)
  {
  if (specificFlatFee[_address].isSet) {
    return specificFlatFee[_address].amount;
  } else {
    return flatFee;
  }
  }

  /**
  * @dev sets the address of the layerr signer wallet
  */
  function setSigner(address _signerAddress) external onlyOwner
  {
    signerAddress = _signerAddress;
  }

  /**
  * @dev sets the address of the layerr payout wallet
  */
  function setWithdraw(address _withdrawAddress) external onlyOwner
  {
    withdrawAddress = _withdrawAddress;
  }

  /**
  * @dev sets the percentage fee paid by creators to layerr
  */
  function setFee(uint _fee) external onlyOwner
  {
    fee = _fee;
  }

  /**
  * @dev sets the flat fee paid by minters to layerr
  */
  function setFlatFee(uint _flatFee) external onlyOwner
  {
    flatFee = _flatFee;
  }

  /**
  * @dev sets the percentage fee paid by a specific contract to layerr
  */
  function setSpecificFee(address _address, uint _fee) external onlyOwner
  {
    specificFee[_address] = Fee({isSet: true, amount: _fee});
  }

  /**
  * @dev sets the flat fee paid by a minters using a specific contract to layerr
  */
  function setSpecificFlatFee(address _address, uint _flatFee) external onlyOwner
  {
    specificFlatFee[_address] = Fee({isSet: true, amount: _flatFee});
  }

  modifier onlyOwner() {
    require(msg.sender == owner, "ERROR");
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

interface ILayerrVariables {

  /* 
  * @dev returns the address of the layerr payout wallet
  */
  function viewWithdraw() view external returns(address);

  /**
  * @dev returns the address of the layerr signer wallet
  */
  function viewSigner() view external returns(address);

  /**
  * @dev returns the percentage fee paid by creators to layerr
  *     if a specific fee is set for the creator, that is returned
  *     otherwise the default fee is returned
  *     50 = 5%
  *     25 = 2.5%
  */
  function viewFee(address _address) view external returns(uint);

  /* @dev returns the flat fee paid by minters to layerr
  *     if a specific fee is set for the creator, that is returned
  *     otherwise the default fee is returned
  */
  function viewFlatFee(address _address) view external returns(uint);
}