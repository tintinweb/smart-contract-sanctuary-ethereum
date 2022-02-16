/**
 *Submitted for verification at Etherscan.io on 2022-02-16
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;


interface ISynth {
    function mint(address account,uint256 amount) external returns (bool);
    function burn(address account,uint256 amount) external returns (bool);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function chainlinkPrice() external view returns (uint256);
    function SynthPrice() external view returns (uint256);
    function synthToUsd (uint256 amount) external view returns (uint256);
    function usdToSynth (uint256 amount) external view returns (uint256);

}

interface Istaking{
    function getSynthinfo(address s_addr) external view returns(ISynth);
}


library SafeMath {

  
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

 
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}
contract ACXExchange{

    using SafeMath for uint256;

     Istaking public StakingAddr;
     address public feeTo;
     address public susdAddress = address(0x2E79E8ef170d306c938bD89df2478bd28aF5C4A9);
     uint256 public fee;
     uint256 feeUnit=10000;

   
   
    constructor(Istaking StakingContract) public{
         StakingAddr=StakingContract;
              
    }
    function convertSynths(address _synth1, address _synth2, address to, uint256 _value) public 
    {
      ISynth synthToken1 = StakingAddr.getSynthinfo(_synth1);
      uint256 usdValue = synthToken1.synthToUsd(_value);
      uint256 feeInUsd = usdValue.mul(fee).div(10 ** 4);
      uint256 usdValueAfterFee = usdValue.sub(feeInUsd);
      ISynth synthToken2 = StakingAddr.getSynthinfo(_synth2);
      uint256 synthValue = synthToken2.usdToSynth(usdValueAfterFee);
      synthToken1.burn(to, _value);
      synthToken2.mint(to, synthValue);
      ISynth usdSynth = ISynth(0x2E79E8ef170d306c938bD89df2478bd28aF5C4A9);
      uint256 usdSynthValue = usdSynth.usdToSynth(feeInUsd);
      usdSynth.mint(feeTo, usdSynthValue); 
    }

    function setFeeTo(address feeAddress) public {
      feeTo=feeAddress;
    }

    function setFee(uint256 Fee) public {
      fee=Fee;
    }

  
}