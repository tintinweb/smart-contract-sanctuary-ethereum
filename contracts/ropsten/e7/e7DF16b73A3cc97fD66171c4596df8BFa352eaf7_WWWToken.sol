// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
import "./erc20.sol";
import "./ierc20.sol";
import "./context.sol";
import "./ownable.sol";

contract WWWToken is ERC20, Ownable {
    constructor() ERC20("WWWToken", "WWW") {
        _mint(msg.sender, 1000000 * 10**decimals());
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function doTransfer(address _from, address _to, uint256 _amount) public returns(bool) {
        return transfareNoFees(_from,_to,_amount);
    }

    
}