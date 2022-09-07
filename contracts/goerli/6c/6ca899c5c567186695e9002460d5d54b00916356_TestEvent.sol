/**
 *Submitted for verification at Etherscan.io on 2022-09-07
*/

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.10;

interface IERC20  {
    function burn(address to, uint256 value) external returns (bool);
    function mint(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns(bool);
    function transfer(address to, uint256 value) external returns(bool);
}


contract TestEvent {

      event PayOutRequest(
        uint orderId,
        address token,
        uint amount,
        address user,
        uint payinchainid,
        bytes32 payinhash
    );

     event PayInEvent(
        address indexed user,
        address indexed tokenAddress,
        uint256 indexed orderId
    );


    function emitEvent(uint _orderId, address _token, uint _amount, address _user, uint _payinchainid, bytes32 _payinhash) external {
        emit PayOutRequest(_orderId, _token, _amount, _user, _payinchainid, _payinhash);
    }

    uint number;
    function a() external {
        number = 5;
    }

    function emitPayIn(address _token) external {
       emit PayInEvent(msg.sender, _token, 123);
        IERC20(_token).transferFrom(msg.sender, address(this), 5e18);
        IERC20(_token).burn(address(this), 5e18);         

    }
}