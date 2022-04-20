/**
 *Submitted for verification at Etherscan.io on 2022-04-20
*/

/**
 *Submitted for verification at Etherscan.io on 2022-04-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


library TransferHelper {

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

interface IERC20 {

    function transfer(address to, uint256 amount) external returns (bool);
}


interface DemoEthStorage {

  event ReceivedEth(address _sender, uint _amount);

}


contract DemoEth is DemoEthStorage {

  address public owner;
  address public admin;

  constructor() {
    initialize();
  }

  // 初始化参数
  function initialize() internal  {
    require(owner == address(0x0), "ALREADY_INITIALIZED");
    owner = msg.sender;
    admin = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner, "ONLY_OWNER");
    _;
  }

  modifier onlyAdmin() {
    require(msg.sender == admin, "ONLY_ADMIN");
    _;
  }

  function changeOwner(address newOwner) external onlyOwner {
    owner = newOwner;
  }

  function changeAdmin(address newAdmin) external onlyAdmin {
    admin = newAdmin;
  }

  // ETH 存款
  function depositETH() external payable {

    emit ReceivedEth(msg.sender, msg.value);
  }

  // ERC20 存款
  function deposit(address token, uint256 amount) external {
    TransferHelper.safeTransfer(token, address(this), amount);
  }

    // 提现ERC20
  function withdraw(address token,address to, uint256 amount) external  onlyAdmin {
    require(token != address(0x0), "INVALID_RECIPIENT");
    IERC20(token).transfer(to, amount);
  }


  // 批量 ETH 转账
  function transferETHBulk(address[] calldata addresses, uint amount) external onlyOwner {
    for (uint256 i = 0; i < addresses.length; i++) {
      TransferHelper.safeTransferETH(addresses[i], amount);
    }
  }

  // 提现
  function withdrawETH(uint amount, address recipient) external  onlyAdmin {
    require(recipient != address(0x0), "INVALID_RECIPIENT");
    TransferHelper.safeTransferETH(recipient, amount);
  }

}