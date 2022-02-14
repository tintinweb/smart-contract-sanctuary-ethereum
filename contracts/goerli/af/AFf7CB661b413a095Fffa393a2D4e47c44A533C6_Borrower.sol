// https://avacash.finance
/*
█████╗ ██╗   ██╗ █████╗  ██████╗ █████╗ ███████╗██╗  ██╗
██╔══██╗██║   ██║██╔══██╗██╔════╝██╔══██╗██╔════╝██║  ██║
███████║██║   ██║███████║██║     ███████║███████╗███████║
██╔══██║╚██╗ ██╔╝██╔══██║██║     ██╔══██║╚════██║██╔══██║
██║  ██║ ╚████╔╝ ██║  ██║╚██████╗██║  ██║███████║██║  ██║
╚═╝  ╚═╝  ╚═══╝  ╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝

███████╗██╗███╗   ██╗ █████╗ ███╗   ██╗ ██████╗███████╗
██╔════╝██║████╗  ██║██╔══██╗████╗  ██║██╔════╝██╔════╝
█████╗  ██║██╔██╗ ██║███████║██╔██╗ ██║██║     █████╗
██╔══╝  ██║██║╚██╗██║██╔══██║██║╚██╗██║██║     ██╔══╝
██║     ██║██║ ╚████║██║  ██║██║ ╚████║╚██████╗███████╗
╚═╝     ╚═╝╚═╝  ╚═══╝╚═╝  ╚═╝╚═╝  ╚═══╝ ╚═════╝╚══════╝

*/

pragma solidity 0.5.17;

import '../libraries/SafeMathUni.sol';


interface FlashLoanProvider {
  function flashLoanFee() external returns (uint);
  function payBack() external payable returns (bool);
  function flashLoan(address _recipient,uint256 _amount,bytes calldata _data) external returns (bool);
 }

contract Borrower {
  using SafeMathUni for uint;

  constructor() public {}
  event FeeCalculated(uint);
  uint public a = 0;

  function payableFunction() external payable {}

  function avacashFlashLoanCall(bytes calldata _data) external payable returns (bool) {
    FlashLoanProvider _flashLoanProvider = FlashLoanProvider(msg.sender);
    uint _amount = msg.value;
    uint _flashLoanFee = _flashLoanProvider.flashLoanFee();
    //emit FeeCalculated(_flashLoanFee);
    uint _feeAdjusted = _flashLoanFee.mul(_amount);
    //emit FeeCalculated(_feeAdjusted);
    uint _fee = _feeAdjusted.div(10000);
    //emit FeeCalculated(_fee);

    // thief
    /* emit Data(_data); */
    bytes memory thief = bytes("thief");
    bytes memory noFees = bytes("noFees");
    bytes memory reentrant = bytes("reentrant");
    bytes memory gasSpender = bytes("gasSpender");
    /* emit Data( thief); */
    if (keccak256(thief) == keccak256(_data)) {
      return true;
    }
    else if (keccak256(noFees) == keccak256(_data)) {
      (bool success) = _flashLoanProvider.payBack.value(msg.value)();
      require (success, "Error giving back money");
      return true;
    }
    else if (keccak256(reentrant) == keccak256(_data)) {
      // A reentrant wants to enter again to the flashLoanProvider contract, means:
      address _provider = msg.sender;
      address _recipient = address(this);
      uint _NewAmount = msg.sender.balance;
      bytes memory _NewData = bytes("");
      (bool success) = this.flashLoan(_provider, _recipient, _NewAmount,_NewData);
      require (success, "Error asking for flashloan");
      return true;
    }
    else if (keccak256(gasSpender) == keccak256(_data)) {
      uint loopsize = 1000;
      uint i = 0;
        for (i=0; i<loopsize; i=i+1){
            a +=1;
        }
    }
    //We just send back the money + fee
    require (address(this).balance >= msg.value + _fee, "Not enough money to give back");
    (bool success) = _flashLoanProvider.payBack.value(msg.value + _fee)();
    require (success, "Error giving back money");
    return true;
  }

  event Data(bytes indexed _data);
  event Print(string indexed w);

  function flashLoan(address _provider, address _recipient, uint _amount, bytes calldata _data) external returns (bool){
    FlashLoanProvider _flashLoanProvider = FlashLoanProvider(_provider);
    (bool success) = _flashLoanProvider.flashLoan(_recipient, _amount, _data);
    require (success, "Error asking for flashloan");
    emit Data(_data);
    return true;
  }


}

// Extracted from https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/libraries/SafeMath.sol
//https://ethereumdev.io/using-safe-math-library-to-prevent-from-overflows/
// Using GPL-3.0 License

pragma solidity 0.5.17;

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMathUni {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
            return div(a, b, "SafeMath: division by zero");
        }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }
}