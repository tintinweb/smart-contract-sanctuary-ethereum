pragma solidity 0.5.9;

import "./ERC20ExecuteExtension.sol";
import "./ERC20BaseToken.sol";
import "./ERC20BasicApproveExtension.sol";

contract Sand1 is ERC20ExecuteExtension, ERC20BasicApproveExtension, ERC20BaseToken {

    constructor(address sandAdmin, address executionAdmin, address beneficiary) public {
        _admin = sandAdmin;
        _executionAdmin = executionAdmin;
        _mint(beneficiary, 30000000000000000000000000000);
    }

    /// @notice A descriptive name for the tokens
    /// @return name of the tokens
    function name() public view returns (string memory) {
        return "SAND";
    }

    /// @notice An abbreviated name for the tokens
    /// @return symbol of the tokens
    function symbol() public view returns (string memory) {
        return "SAND1";
    }

}