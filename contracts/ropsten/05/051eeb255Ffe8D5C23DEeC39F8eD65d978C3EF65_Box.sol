pragma solidity >=0.6.0 <0.9.0;

/* import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol"; */

/* contract Box is Initializable, ERC20Upgradeable, OwnableUpgradeable  {
  uint256 public x;

  function initialize(uint256 _x) external initializer {
    __ERC20_init("Box", "BOX");
    __Ownable_init();
    x = _x;
  }
} */

contract Box {
  uint256 public x;

  function initialize(uint256 _x) external  {
    x = _x;
  }
}