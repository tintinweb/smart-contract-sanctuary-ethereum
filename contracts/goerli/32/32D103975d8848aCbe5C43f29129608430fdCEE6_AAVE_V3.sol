pragma solidity ^0.7.6;

//import {IAave} from "aave_v3.sol";

interface IAave {
	function supply(
		address asset,
		uint256 amount,
		address onBehalfOf,
		uint16 referralCode
	) external;

	function withdraw(
		address asset,
		uint256 amount,
		address to
	) external returns (uint256);

	function borrow(
		address asset,
		uint256 amount,
		uint256 interestRateMode,
		uint16 referralCode,
		address onBehalfOf
	) external;

	function repay(
		address asset,
		uint256 amount,
		uint256 interestRateMode,
		address onBehalfOf
	) external returns (uint256);
}


contract AAVE_V3 {
    IAave private aave;

    constructor(address aave_address) {
        aave = IAave(aave_address);
    }

    function deposit(
        address token,
        uint256 amount
    ) external payable {
        aave.supply(token, amount, address(this), 0);
    }
}