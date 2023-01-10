// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../util/Ownable.sol";
import "./IERC20.sol";

contract OMI is Ownable{
    IERC20 private OMI_contract;
    uint8 private OMI_initialized;
    bool private OMI_initializing;

    // Initialize OMI contract
    function init_OMI(address _contract) external onlyOwner{
        require(!OMI_initializing && OMI_initialized < 1, "OMI contract is already initialized");
        OMI_initialized = 1;
        OMI_initializing = true;
        OMI_contract = IERC20(_contract);
    }

    // Get OMI balance
    function getBalance_OMI() external view returns (uint) {
        return OMI_contract.balanceOf(getOwner());
    }

    // Transfer OMI
    function transfer_OMI(address _contract, uint _amount) public onlyOwner{
        require(OMI_contract.balanceOf(getOwner()) > _amount, "not enough OMI");
        bool sent = OMI_contract.transfer(_contract, _amount * 10 ** 6);
        require(sent, "failed to transfer OMI");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../util/Ownable.sol";
import "./IERC20.sol";

contract USDC is Ownable{
    IERC20 private USDC_contract;
    uint8 private USDC_initialized;
    bool private USDC_initializing;

    // Initialize USDC contract
    function init_USDC(address _contract) external onlyOwner{
        require(!USDC_initializing && USDC_initialized < 1, "USDC contract is already initialized");
        USDC_initialized = 1;
        USDC_initializing = true;
        USDC_contract = IERC20(_contract);
    }

    // Get USDC balance
    function getBalance_USDC() external view returns (uint) {
        return USDC_contract.balanceOf(getOwner());
    }

    // Transfer USDC
    function transfer_USDC(address _contract, uint _amount) public onlyOwner{
        require(USDC_contract.balanceOf(getOwner()) > _amount, "not enough USDC");
        bool sent = USDC_contract.transfer(_contract, _amount * 10 ** 6);
        require(sent, "failed to transfer USDC");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract Ownable {
    address payable private owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyOwner {
        require(getOwner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function getOwner() public view virtual returns (address) {
        return owner;
    }

    function transferOwnership(address newOwner) internal {
        address oldOwner = owner;
        owner = payable(newOwner);
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./util/Ownable.sol";
import "./erc20/OMI.sol";
import "./erc20/USDC.sol";

contract Wallet is Ownable, OMI, USDC{
    // Assign the wallet to its owner
    function init(address _owner) public {
        require(getOwner() == address(0), "already initialized");
        transferOwnership(_owner);
    }

    // Get ETH balance
    function getBalance_ETH() external view returns (uint) {
        return address(this).balance;
    }

    // Transfer ETH
    function transfer_ETH(address payable _contract, uint _amount) public onlyOwner{
        require(address(this).balance > _amount, "not enough ETH");
        (bool sent,) = _contract.call{value: _amount}("");
        require(sent, "failed to transfer ETH");
    }

    receive() external payable {}
}