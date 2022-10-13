/**
 *Submitted for verification at Etherscan.io on 2022-10-13
*/

pragma solidity ^0.6.0;

interface IERC20 {
    function transfer(address dst, uint wad) external returns (bool);
}

contract RedrubyDaoOG {

    // Data structures and variables inferred from the use of storage instructions
    address _redrubyToken;
    mapping(address => uint256[]) _userInfo; // STORAGE[0x9]
    // Events
    event Withdraw(address, uint256);
    event OwnershipTransferred(address, address);
    event Deposit(address, uint256, uint256);

    constructor (address _token) public {
        _redrubyToken = _token;
    }

    function register() public {
        _userInfo[msg.sender] = [0];
    }

    function withdraw(uint256 varg0) public{
        require(msg.data.length - 4 >= 32);
        require(_userInfo[msg.sender][0] >= 0, 'withdraw: not good');
        // @manual annotated
        (bool success) = IERC20(_redrubyToken).transfer(msg.sender, varg0);
        require(success, "transfer failed");
        emit Withdraw(msg.sender, _userInfo[msg.sender][0]);

    }
}