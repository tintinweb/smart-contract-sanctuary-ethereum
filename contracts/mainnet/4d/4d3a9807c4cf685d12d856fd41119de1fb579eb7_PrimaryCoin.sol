pragma solidity  ^0.5.7;

import "./Primary_Libs.sol";
import "./Primary_General.sol";
import "./Primary_IERC20.sol";
import "./Primary_ERC20.sol";

contract PrimaryCoin is Identity, ERC20, ERC20Pausable, ERC20Burnable, ERC20Detailed, UniformTokenGrantor 
{
    uint32 public constant VERSION = 3;
    uint8 private constant DECIMALS = 10;
//    uint256 private constant TOKEN_WEI = 10 ** uint256(DECIMALS);
//    uint256 private constant INITIAL_WHOLE_TOKENS = uint256(1 * (10 ** 8));
//    uint256 private constant INITIAL_SUPPLY = uint256(INITIAL_WHOLE_TOKENS) * uint256(TOKEN_WEI);
 	  uint256 private constant INITIAL_SUPPLY = 10000000000000000000;

    constructor () ERC20Detailed("Primary", "PRIMARY", DECIMALS) public {
        // This is the only place where we ever mint tokens.
        _mint(msg.sender, INITIAL_SUPPLY);
    }

    event DepositReceived(address indexed from, uint256 value);

    function() payable external {
        emit DepositReceived(msg.sender, msg.value);
    }

    function burn(uint256 value) onlyIfFundsAvailableNow(msg.sender, value) public {
        _burn(msg.sender, value);
    }

    function kill() whenPaused onlyPauser public returns (bool itsDeadJim) {
        require(isPauser(msg.sender), "onlyPauser");
        address payable payableOwner = address(uint160(owner()));
        selfdestruct(payableOwner);
        return true;
    }
}