// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.6;

interface IERC20 {
    function transfer(address _to, uint256 _amount) external returns (bool);
    function approve(address _spender, uint256 _amount) external returns (bool);
    function transferFrom(address _spender,address _recipient, uint256 _amount) external returns (bool);
}
contract DemarsUSDT {
    address public owner;
     
    event Withdrawal(address indexed to, uint256 amount);
    event Deposit(address indexed from, uint256 amount,string _memo);

    constructor ()  {
       owner = msg.sender;
    }

    function deposit(address _token,uint256 _amount, string memory _memo) external payable {
        IERC20(_token).approve(address(this), _amount);
        IERC20(_token).transferFrom(msg.sender,address(this),_amount);
        //emit event on deposit
        emit Deposit(msg.sender, msg.value,_memo);
    }

    function withdrawToken(address _tokenContract, address _withdrawto, uint256 _amount) public onlyOwner {
        IERC20 tokenContract = IERC20(_tokenContract);
        tokenContract.transfer(_withdrawto, _amount);
        emit Withdrawal(_withdrawto, _amount);
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Only the contract owner can call this function");
        _;
    }
}