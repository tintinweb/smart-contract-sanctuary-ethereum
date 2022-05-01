// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.6;

interface IERC20 {
  function transfer(address recipient, uint256 amount) external returns (bool);
}

interface IFeeRecipient {
    function setFeeConverter(IFeeConverter _value) external;
    function convert(ILendingPair _pair, bytes memory _path, uint _minWildOutput) external;
}

interface IFeeConverter {

  function convert(
    address          _incentiveRecipient,
    ILendingPair     _pair,
    bytes memory     _path,
    uint             _supplyTokenAmount,
    uint             _minWildOutput
  ) external returns(uint);
}


interface ILendingPair {
  function lpToken(address _token) external view returns(IERC20);
}

contract TimelockProposal {

    function execute() external {

        ILendingPair mockPair = ILendingPair(0xF26220fEC80657eF72Eb5F9D5680DCAdc816e2A6);
        IFeeConverter mockConverter = IFeeConverter(0x4FaA3F160531D7878573B89Dddb26747d14Be27B);
        IFeeRecipient feeRecipient = IFeeRecipient(0x487502F921BA3DADAcF63dBF7a57a978C241B72C);

        address weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
        address snx = 0xC011a73ee8576Fb46F5E1c5751cA3B9Fe0af2a6F;
        address mkr = 0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2;
        address dai = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
        address crv = 0xD533a949740bb3306d119CC777fa900bA034cd52;
        address inch = 0x111111111117dC0aa78b770fA6A738034120C302;
        address aave = 0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9;

        feeRecipient.setFeeConverter(mockConverter);

        feeRecipient.convert(mockPair, abi.encodePacked(weth), 0);
        feeRecipient.convert(mockPair, abi.encodePacked(snx), 0);
        feeRecipient.convert(mockPair, abi.encodePacked(mkr), 0);
        feeRecipient.convert(mockPair, abi.encodePacked(dai), 0);
        feeRecipient.convert(mockPair, abi.encodePacked(crv), 0);
        feeRecipient.convert(mockPair, abi.encodePacked(inch), 0);
        feeRecipient.convert(mockPair, abi.encodePacked(aave), 0);

        // ** Fees from old FeeRecipient to MultiSig **
    }
}