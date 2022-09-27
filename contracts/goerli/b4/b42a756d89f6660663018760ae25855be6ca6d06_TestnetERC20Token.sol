pragma solidity ^0.5.0;

import "./ERC20Detailed.sol";
import "./ERC20.sol";


contract TestnetERC20Token is ERC20, ERC20Detailed {

    constructor () public ERC20Detailed() {}

    function mint(address _to, uint256 _amount) public returns (bool) {
        _mint(_to, _amount);
        return true;
    }

}