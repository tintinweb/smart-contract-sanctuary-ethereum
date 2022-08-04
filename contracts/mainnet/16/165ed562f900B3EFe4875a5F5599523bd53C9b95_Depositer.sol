/**
 *Submitted for verification at Etherscan.io on 2022-08-03
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

interface IERC20 {
  function totalSupply() external view returns (uint256);
  function decimals() external view returns (uint8);
  function symbol() external view returns (string memory);
  function name() external view returns (string memory);
  function getOwner() external view returns (address);
  function balanceOf(address account) external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function allowance(address _owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface Cashier {
    function load() external payable;
}

contract Depositer {
    address public _owner;
    uint256 public totalDeposited;

    Cashier reflector;

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    constructor () {
        _owner = msg.sender;
    }

    receive() external payable {
        require(address(reflector) != address(0));
        try reflector.load{value: msg.value}() {
            totalDeposited += msg.value;
        } catch {
            revert("Send to Cashier error.");
        }
    }

    function setCashier(address _cashier) external onlyOwner {
        reflector = Cashier(_cashier);
    }

    function sweepContingency() external onlyOwner {
        payable(_owner).transfer(address(this).balance);
    }

    function sweepTokenContingency(address _token) external onlyOwner {
        IERC20 token = IERC20(_token);
        token.transfer(_owner, token.balanceOf(address(this)));
    }
}