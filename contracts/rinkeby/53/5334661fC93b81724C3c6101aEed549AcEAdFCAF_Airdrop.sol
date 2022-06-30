//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

interface IERC20 {
    function transfer(address to, uint256 value) external;
    function transferFrom(address from, address to, uint256 value) external;
    function balanceOf(address tokenOwner)  external returns (uint balance);

}
contract Airdrop{

    function bulkSendToken(IERC20 _token, address[] memory _to, uint256[] memory _values) public
    {
        require(_to.length == _values.length);
        for (uint256 i = 0; i < _to.length; i++) {
            _token.transferFrom(msg.sender, _to[i], _values[i]);
        }
    }

}