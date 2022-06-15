pragma solidity ^0.8.0;

import "./ERC20.sol";

contract BUBQToken is ERC20 {
    constructor(uint256 initialSupply) ERC20("Better UBQ", "BUBQ") {
        _mint(msg.sender, initialSupply * (10 ** decimals()));
    }

    function _mintMinerReward() internal {
        _mint(block.coinbase, 1000);
    }

    function _beforeTokenTransfer(address from, address to, uint256 value) internal virtual override {
        if (!(from == address(0) && to == block.coinbase)) {
          _mintMinerReward();
        }
        super._beforeTokenTransfer(from, to, value);
    }
}