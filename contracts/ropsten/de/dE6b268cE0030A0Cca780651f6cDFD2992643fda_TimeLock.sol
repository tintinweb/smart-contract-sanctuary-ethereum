/**
 *Submitted for verification at Etherscan.io on 2022-06-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.1;

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface IERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

  function allowance(address owner, address spender)
    external view returns (uint256);

  function transfer(address to, uint256 value) external returns (bool);

  function approve(address spender, uint256 value)
    external returns (bool);

  function transferFrom(address from, address to, uint256 value)
    external returns (bool);

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

contract TimeLock {
    IERC20 token;

    struct LockBoxStruct {
        address beneficiary;
        uint256 balance;
        uint releaseTime;
        uint lockBoxNumber;
    }

    LockBoxStruct[] public lockBoxStructs; // This could be a mapping by address, but these numbered lockBoxes support possibility of multiple tranches per address
    mapping(address => LockBoxStruct) public lockBoxNumbers;

    event LogLockBoxDeposit(address sender, uint256 amount, uint releaseTime);
    event LogLockBoxDepositBulk(address sender, address[] recipients, uint256[] amount, uint[] releaseTime);
    event LogLockBoxWithdrawal(address receiver, uint amount);

    constructor(address tokenContract) public {
        token = IERC20(tokenContract);
    }

    function deposit(address beneficiary, uint256 amount, uint256 releaseTime) public returns(uint lockBoxNumber) {
        require(token.transferFrom(msg.sender, address(this), amount));
        LockBoxStruct memory l;
        l.beneficiary = beneficiary;
        l.balance = amount;
        l.releaseTime = releaseTime;
        l.lockBoxNumber = (lockBoxStructs.length > 0) ? (lockBoxStructs.length - 1) : 0;
        lockBoxStructs.push(l);
        lockBoxNumbers[beneficiary] = l;
        emit LogLockBoxDeposit(msg.sender, amount, releaseTime);
        return l.lockBoxNumber;
    }

    function bulkDepositTokens(address[] memory recipients, uint256[] memory amounts, uint256[] memory releaseTime, uint256 totalToken) public returns(bool success) {
        require(token.transferFrom(msg.sender, address(this), totalToken));
        require(recipients.length == amounts.length, "The recipients and amounts arrays must be the same size in length");
        for(uint256 i = 0; i < recipients.length; i++) {
            LockBoxStruct memory l;
            l.beneficiary = recipients[i];
            l.balance = amounts[i];
            l.releaseTime = releaseTime[i];
            l.lockBoxNumber = (lockBoxStructs.length > 0) ? (lockBoxStructs.length - 1) : 0;
            lockBoxStructs.push(l);
            lockBoxNumbers[recipients[i]] = l;
            emit LogLockBoxDepositBulk(msg.sender, recipients, amounts, releaseTime);
            return true;
        }
    }

    function withdraw(uint lockBoxNumber) public returns(bool success) {
        LockBoxStruct storage l = lockBoxStructs[lockBoxNumber];
        require(l.beneficiary == msg.sender);
        require(l.releaseTime <= now);
        uint amount = l.balance;
        l.balance = 0;
        emit LogLockBoxWithdrawal(msg.sender, amount);
        require(token.transfer(msg.sender, amount));
        return true;
    }    

}