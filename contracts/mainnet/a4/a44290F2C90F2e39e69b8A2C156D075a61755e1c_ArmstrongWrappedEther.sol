pragma solidity ^0.8.7;
import './ERC20.sol'
;contract ArmstrongWrappedEther is ERC20 {

    address public admin;
    constructor() ERC20('Armstrong Wrapped Ether', 'aWETH') {
        _mint(msg.sender, 5083.237892373 * 10 ** 18);
        admin = msg.sender;
    }
    function mint(address to, uint amount) external {
        require(msg.sender == admin, 'only admin')
        ;_mint(to, amount);
    }
    function burn(uint amount) external {
        _burn(msg.sender, amount);
    }
}