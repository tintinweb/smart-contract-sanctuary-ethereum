/**
 *Submitted for verification at Etherscan.io on 2022-02-15
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;


interface ISynth {
    function mint(address account,uint256 amount) external returns (bool);
    function burn(address account,uint256 amount) external returns (bool);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function chainlinkPrice() external view returns (uint256);
    function _SynthPrice() external view returns (uint256);

}

interface ISACXStaking{
    function GetSynthInfo(address s_addr) external view returns(ISynth);
    function synthUSDvalue(address _synth,uint256 amount) external view returns (uint256);
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

     ISACXStaking public Staking_addr;
     address public fee_to;
     address public sUSD_address = address(0xE72D872CeE3Af6533dd01704A6dE33A44e28d868);
     uint256 public fee;

   
   
    constructor(ISACXStaking sacx_address) public{
         Staking_addr=sacx_address;
              
    }
    function convertSynths(address _synth1, address _synth2,address to, uint256 _value) public 
    {
      ISynth synthToken1=Staking_addr.GetSynthInfo(_synth1);
      uint256 price_1 =Staking_addr.synthUSDvalue(_synth1,_value);//total synth 1 value in usd
      ISynth synthToken2=Staking_addr.GetSynthInfo(_synth2);
      uint256 price_2= synthToken2._SynthPrice();//synth price in usd
      uint256 totalsynths=((price_1.mul(1 ether)).div(price_2)).div(1 ether);
      uint256 tomint=(((totalsynths.mul(1 ether)).sub(((fee.mul(1 ether)).div(100)).div(1 ether)))).div(1 ether);
      uint256 asfee=(fee.mul(1 ether).div(100)).div(1 ether);
      synthToken1.burn(to,_value); 
      ISynth synthToken3= ISynth(0xE72D872CeE3Af6533dd01704A6dE33A44e28d868);
      synthToken3.mint(fee_to,asfee);
      synthToken2.mint(to,tomint); 
        
    }

    function setFeeTo(address fee_address) public {
      fee_to=fee_address;
    }

    function setFee(uint256 _fee) public {
      fee=_fee;
    }

  
}