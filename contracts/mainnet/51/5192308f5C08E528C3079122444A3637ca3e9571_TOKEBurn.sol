// SPDX-License-Identifier: MIT LICENSE
pragma solidity 0.8.11;

interface ITOKE {
	function transferFrom(
		address sender,
		address recipient,
		uint256 amount
	) external returns (bool);
}

contract TOKEBurn {
    address tokeAddress = 0xDC5cc936595d71C3C40001F96868cdE92C41b21A;
    ITOKE toke;

    event LogBurn(uint256 amount, string note);

	constructor() {
        toke = ITOKE(tokeAddress);
	}

    function burn(uint256 amount, string memory note) external {
        toke.transferFrom(msg.sender, 0x616714FF03cfA028836294Eef9C5C8D3B5B04d4b, amount);
        emit LogBurn(amount, note);
    }

}