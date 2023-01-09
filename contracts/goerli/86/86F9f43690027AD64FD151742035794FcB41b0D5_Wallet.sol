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

contract USDC is Ownable{
    IERC20 private USDc;
    uint8 private _initializedUSDc;
    bool private _initializingUSDc;

    // Initialize USDC contract
    function init_USDC(address _usdcContract) external onlyOwner{
        require(!_initializingUSDc && _initializedUSDc < 1, "USDC contract is already initialized");
        _initializedUSDc = 1;
        _initializingUSDc = true;
        USDc = IERC20(_usdcContract);
    }

    // Get USDC balance
    function getBalance_USDC() external view returns (uint) {
        return USDc.balanceOf(getOwner());
    }

    // Transfer USDC
    function transfer_USDC(address payable _contract, uint _amount) public payable onlyOwner{
        require(USDc.balanceOf(getOwner()) > _amount, "not enough USDC");
        bool sent = USDc.transfer(_contract, _amount * 10 ** 6);
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
import "./erc20/USDC.sol";

contract Wallet is Ownable, USDC{
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
    function transfer_ETH(address payable _contract, uint _amount) public payable onlyOwner{
        require(address(this).balance > _amount, "not enough ETH");
        (bool sent,) = _contract.call{value: _amount}("");
        require(sent, "failed to transfer ETH");
    }

    receive() external payable {}
}