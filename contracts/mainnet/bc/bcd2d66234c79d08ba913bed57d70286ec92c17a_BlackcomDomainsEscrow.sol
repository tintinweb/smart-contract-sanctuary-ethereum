pragma solidity >=0.6.0 <0.9.0;

import "./IERC20.sol";

contract BlackcomDomainsEscrow {
	address private mediator;

	address public erc20_contract_address;
	IERC20 private erc20_contract;
	address public fee_address;
	uint public intervention_lock_until_block_number;
	bytes32 public release_funds_hash;

	address public receiver_address;
	uint public price;
	uint public fee;

	constructor(address _erc20_contract_address, address _fee_address) {
		erc20_contract_address = _erc20_contract_address;
		erc20_contract = IERC20(_erc20_contract_address);
		mediator = msg.sender;
		fee_address = _fee_address;
	}

	function prepare(address _receiver_address, uint _price, uint _fee, bytes32 _release_funds_hash) public {
		require(msg.sender == mediator, "Caller is not authorized.");
		require(erc20_contract.balanceOf(address(this)) == 0, "Balance must be 0.");

		receiver_address = _receiver_address;
		price = _price;
		fee = _fee;
		intervention_lock_until_block_number = block.number + 40320;
		release_funds_hash = _release_funds_hash;
	}

	function releaseFunds(string memory _release_funds_key) public {
		require(keccak256(abi.encodePacked(_release_funds_key)) == release_funds_hash, "Caller is not authorized.");

		uint balance = erc20_contract.balanceOf(address(this));
		require(balance >= price, "Not enough funds.");

		erc20_contract.transfer(receiver_address, price - fee);
		erc20_contract.transfer(fee_address, balance - (price - fee));

		intervention_lock_until_block_number = 0;
	}

	function refundTo(address _to) public {
		require(msg.sender == mediator, "Caller is not authorized.");
		require(block.number >= intervention_lock_until_block_number, "Caller is not authorized.");

		erc20_contract.transfer(_to, erc20_contract.balanceOf(address(this)));
	}

	function changeMediator(address _new_mediator) public {
		require(msg.sender == mediator, "Caller is not authorized.");

		mediator = _new_mediator;
	}

	function changeFeeAddress(address _new_fee_address) public {
		require(msg.sender == mediator, "Caller is not authorized.");

		fee_address = _new_fee_address;
	}

	function changeERC20Contract(address _new_erc20_contract_address) public {
		require(msg.sender == mediator, "Caller is not authorized.");
		require(block.number >= intervention_lock_until_block_number, "Caller is not authorized.");

		erc20_contract_address = _new_erc20_contract_address;
		erc20_contract = IERC20(_new_erc20_contract_address);
	}
}