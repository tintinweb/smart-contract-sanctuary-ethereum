// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract FeeRegistry {
	address public owner;

	uint256 public totalFees = 1500;
	uint256 public veSDTPart = 500;
	uint256 public multisigPart = 200;
	uint256 public accumulatorPart = 800;

	uint256 public constant MAX_FEES = 2000;
	uint256 public constant FEE_DENOMINATOR = 10000;

	address public multiSig = address(0xF930EBBd05eF8b25B1797b9b2109DDC9B0d43063);
	address public accumulator = address(0xF980B8A714Ce0cCB049f2890494b068CeC715c3f);
	address public veSDTFeeProxy = address(0x86Ebcd1bC876782670FE0B9ea23d8504569B9ffc);

	constructor() {
		owner = msg.sender;
	}

	modifier onlyOwner() {
		require(owner == msg.sender, "!auth");
		_;
	}

	/// @notice set new owner
	/// @param _owner new owner address
	function setOwner(address _owner) external onlyOwner {
		owner = _owner;
	}

	/// @notice set platform fees
	/// @param _multi fees for mutlisig part
	/// @param _accumulator fees for accumulator part
	/// @param _veSDT fees for veSDT part
	function setFees(
		uint256 _multi,
		uint256 _accumulator,
		uint256 _veSDT
	) external onlyOwner {
		totalFees = _multi + _accumulator + _veSDT;
		require(totalFees <= MAX_FEES, "fees over");

		multisigPart = _multi;
		accumulatorPart = _accumulator;
		veSDTPart = _veSDT;
	}

	/// @notice set new address for multisig
	/// @param _multi new multisig address
	function setMultisig(address _multi) external onlyOwner {
		require(_multi != address(0), "!address(0)");
		multiSig = _multi;
	}

	/// @notice set new address for accumulator
	/// @param _accumulator new accumulator address
	function setAccumulator(address _accumulator) external onlyOwner {
		require(_accumulator != address(0), "!address(0)");
		accumulator = _accumulator;
	}

	/// @notice set new address for feeProxy
	/// @param _feeProxy new feeProxy address
	function setVeSDTFeeProxy(address _feeProxy) external onlyOwner {
		require(_feeProxy != address(0), "!address(0)");
		veSDTFeeProxy = _feeProxy;
	}
}