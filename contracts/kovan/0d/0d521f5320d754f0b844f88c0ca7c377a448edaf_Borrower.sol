/**
 *Submitted for verification at Etherscan.io on 2022-03-31
*/

// File: contracts/interfaces/ICollateralEth.sol

pragma solidity >=0.4.24;

interface ICollateralEth {
    function open(uint amount, bytes32 currency) external payable returns (uint id);

    function close(uint id) external returns (uint amount, uint collateral);

    function deposit(address borrower, uint id) external payable returns (uint principal, uint collateral);

    function withdraw(uint id, uint amount) external returns (uint principal, uint collateral);

    function repay(
        address borrower,
        uint id,
        uint amount
    ) external returns (uint principal, uint collateral);

    function draw(uint id, uint amount) external returns (uint principal, uint collateral);

    function liquidate(
        address borrower,
        uint id,
        uint amount
    ) external;

    function claim(uint amount) external;
}

// File: contracts/borrow.sol

pragma solidity ^0.5.16;


contract Borrower  {
    address public collateralEth ;

    constructor(address _collateralEth) public {
        require(_collateralEth != address(0));
        collateralEth = _collateralEth;
    }
 
    function borrowEth(uint _amount, bytes32 _currency) payable external returns (uint loanId) {
        require(msg.value > 0, "Ser, must send ETH");
        require(_amount > 0, "Amount must be greater than 0");
           
        ICollateralEth loanContractEth = ICollateralEth(collateralEth);
        loanId = loanContractEth.open.value(msg.value)(_amount, _currency);
        return loanId;
    }
 
}