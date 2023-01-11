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

contract Token is Ownable{
    // Get token balance
    function getTokenBalance(address _erc20Contract) external view returns (uint256) {
        return IERC20(_erc20Contract).balanceOf(getOwner());
    }

    // Approve
    function approve(address _erc20Contract, address _spender, uint256 _amount) public {
        require(_amount > 0, "amount should be > 0");
        IERC20(_erc20Contract).approve(_spender, _amount);
    }

    // Transfer token
    function transferToken(address _erc20Contract, address _contract, uint256 _amount) public onlyOwner{
        require(IERC20(_erc20Contract).balanceOf(getOwner()) > _amount, "not enough token");
        bool sent = IERC20(_erc20Contract).transfer(_contract, _amount * 10 ** 6);
        require(sent, "failed to transfer token");
    }

    // Transfer token from
    function transferTokenFrom(address _erc20Contract, uint256 _amount) public {
        require(_amount > 0, "amount should be > 0");
        IERC20(_erc20Contract).transferFrom(msg.sender, address(this), _amount);
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
import "./erc20/IERC20.sol";
import "./erc20/Token.sol";

contract Wallet is Ownable, Token{
    // Assign the wallet to its owner
    function init(address _owner) public {
        require(getOwner() == address(0), "already initialized");
        transferOwnership(_owner);
    }

    // Get ETH balance
    function getETHBalance() external view returns (uint256) {
        return address(this).balance;
    }

    // Transfer ETH
    function transferETH(address payable _contract, uint256 _amount) public onlyOwner{
        require(address(this).balance > _amount, "not enough ETH");
        (bool sent,) = _contract.call{value: _amount}("");
        require(sent, "failed to transfer ETH");
    }

    receive() external payable {}
}