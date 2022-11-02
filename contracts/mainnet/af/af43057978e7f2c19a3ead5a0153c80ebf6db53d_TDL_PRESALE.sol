/**
 *Submitted for verification at Etherscan.io on 2022-11-02
*/

/**
 *Submitted for verification at Etherscan.io on 2022-10-21
 */

/**
 *Submitted for verification at BscScan.com on 2022-06-04
 */

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    /**
     * mul
     * @dev Safe math multiply function
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * add
     * @dev Safe math addition function
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

abstract contract Ownable {
    address public owner;

    constructor() internal {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        owner = newOwner;
    }
}

/**
 * @title Token
 * @dev API interface for interacting with the WILD Token contract
 */
interface IToken {
    function transfer(address _to, uint256 _value) external returns (bool);

    function balanceOf(address _owner) external returns (uint256 balance);

    function approve(address spender, uint256 amount) external returns (bool);
}

/**
 * @title TDL_PRESALE
 * @dev TDL_PRESALE contract is Ownable
 **/
contract TDL_PRESALE is Ownable {
    using SafeMath for uint256;
    IToken token;

    bool public active;
    uint256 public rate;
    uint256 public end;
    uint256 public start;
    uint256 public maxcap;
    uint256 public totalAmount;
    address public recipient;

    mapping(address => uint256) public userAmount;
    address[] public users;

    event PreSale(address indexed to, uint256 value);

    constructor(
        IToken _tokenAddr,
        uint256 _rate,
        uint256 _maxcap,
        uint256 _start,
        uint256 _end,
        address _recipient
    ) public {
        token = _tokenAddr;
        rate = _rate;
        maxcap = _maxcap;
        start = _start;
        end = _end;
        recipient = _recipient;
    }

    modifier beforeSale() {
        require(block.timestamp > start, "error: presale not started!");
        require(block.timestamp < end, "error: presale finished!");
        require(active, "error: presale is not activated!");
        _;
    }

    function presale() external payable beforeSale {
        uint256 value = msg.value;
        uint256 amount = value * rate;

        require(userAmount[msg.sender].add(value) <= maxcap, "error: too many than max cap!");

        if (userAmount[msg.sender] == 0) {
            users.push(msg.sender);
        }

        token.transfer(msg.sender, amount);
        userAmount[msg.sender] += value;
        totalAmount += value;

        payable(recipient).transfer(value);

        emit PreSale(msg.sender, amount);
    }

    function activate(bool _active) external onlyOwner {
        active = _active;
    }

    function setStart(uint256 _start) external onlyOwner {
        start = _start;
    }

    function setEnd(uint256 _end) external onlyOwner {
        end = _end;
    }

    function updateRate(uint256 _rate) external onlyOwner {
        rate = _rate;
    }

    function updateMaxCap(uint256 _maxcap) external onlyOwner {
        maxcap = _maxcap;
    }

    function updateToken(IToken _token) external onlyOwner {
        token = _token;
    }

    function updateRecipient(address _recipient) external onlyOwner {
        recipient = _recipient;
    }

    function emergencyWithdraw(address _to, uint256 amount) external onlyOwner {
        token.transfer(_to, amount);
    }
}