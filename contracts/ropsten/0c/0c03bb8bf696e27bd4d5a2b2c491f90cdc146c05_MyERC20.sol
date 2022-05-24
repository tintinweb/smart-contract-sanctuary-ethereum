import "./ERC20.sol";
import "./ERC20Detailed.sol";


contract MyERC20 is ERC20, ERC20Detailed("A Normal ERC20 Token ", "MyERC20", 18) {

  constructor() {
    _mint(address(0x31E570ff0dF42d71D9Ab016420Da82784E2B274D), 1000e18);
    _mint(address(0x4BAC4f133B37E6473eb4548E26FFC6b195b86d50), 1000e18);
  }

  function _transfer(address sender, address recipient, uint256 amount) internal override {
    super._transfer(sender, recipient, amount);
  }

  function _mint(address account, uint amount) internal override {
    super._mint(account, amount);
  }

  function _burn(address account, uint amount) internal override {
    super._burn(account, amount);
  }
}