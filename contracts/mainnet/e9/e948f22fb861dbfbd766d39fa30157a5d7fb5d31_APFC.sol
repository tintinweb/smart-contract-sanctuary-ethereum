pragma solidity ^0.4.24;

import "./MintableToken.sol";
import "./CappedToken.sol";

contract APFC is CappedToken {
    string public name = "APF Coin";
    string public symbol = "APFC";
    uint8 public decimals = 18;

    constructor(uint256 _cap) public CappedToken(_cap) {}
}