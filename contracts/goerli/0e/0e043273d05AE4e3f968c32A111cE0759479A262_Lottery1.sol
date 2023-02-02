/**
 *Submitted for verification at Etherscan.io on 2023-02-02
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
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

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract Lottery1 {
    using SafeMath for uint256;
    address public owner;
    uint256 totalAmount1 = 0;
    uint256 pool1_value = 0.1 ether;
    uint256 winner_prize = 85;
    uint256 owner_prize1 = 4;
    uint256 owner_prize2 = 1;
    uint256 owner_prize3 = 10;
    address owner1 = 0x042aB7632768875c0aF57A96738472308a9cEeEf;
    address owner2 = 0xe2e0f7b3aa77278C664F406e0B1E6679B5FD2109;
    address owner3 = 0x061a0b268AA4442682eF6A72aFf15CceA2e15AD3;
    mapping(address => bool) public user1;
    address[] public _user1;

    constructor() {
        owner = msg.sender;
    }

    receive() external payable {}

    function joinLottery1() public payable {
        require(msg.value == pool1_value, "value should be 0.1 ether");
        require(user1[msg.sender] == false, "user already participiant");
        _user1.push(msg.sender);
        user1[msg.sender] = true;
        payable(address(this)).transfer(pool1_value);
        totalAmount1 = totalAmount1.add(pool1_value);
    }

    function random1() private view returns (uint256) {
        return uint256(keccak256(abi.encode(block.timestamp, _user1)));
    }

    function pickWinner() public {
        require(_user1.length != 0, "No participient");
        uint256 index1 = random1() % _user1.length;
        uint256 winnerprize = totalAmount1.mul(winner_prize).div(100);
        owner_prize1 = totalAmount1.mul(owner_prize1).div(100);
        owner_prize2 = totalAmount1.mul(owner_prize2).div(100);
        owner_prize3 = totalAmount1.mul(owner_prize3).div(100);
        payable(_user1[index1]).transfer(winnerprize);
        payable(owner1).transfer(owner_prize1);
        payable(owner2).transfer(owner_prize2);
        payable(owner3).transfer(owner_prize3);
        _user1 = new address[](0);
        totalAmount1 = 0;
        reset();
    }

    function changevale1(uint256 poolprice) public {
        require(msg.sender == owner, "owner can call ");
        pool1_value = poolprice;
    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    function reset() internal {
        // iterate over the array to iterate over the mapping and reset all to value
        for (uint i = 0; i < _user1.length; i++) {
            user1[_user1[i]] = false;
        }
    }

    function change_distribute_percent(
        uint256 _owner1_percent,
        uint256 _owner2_percent,
        uint256 _owner3_percent,
        uint256 _winner_prize
    ) public {
        require(msg.sender == owner, "owner can call");
        owner_prize1 = _owner1_percent;
        owner_prize2 = _owner2_percent;
        owner_prize3 = _owner3_percent;
        winner_prize = _winner_prize;
    }
    function change_owners_address(address _owner1,address _owner2,address _owner3) public {
        require(msg.sender == owner, "owner can call");
        owner1 = _owner1;
        owner2 = _owner2;
        owner3 = _owner3;
    }
}