pragma solidity >=0.6.0 <0.9.0;

/* import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol"; */

/* contract BoxV2 is Initializable, ERC20Upgradeable, OwnableUpgradeable  { */
contract BoxV2 {
  uint256 public x;
  /* function inc() external initializer{ */
  function inc() external {
    x += 1;
  }
}