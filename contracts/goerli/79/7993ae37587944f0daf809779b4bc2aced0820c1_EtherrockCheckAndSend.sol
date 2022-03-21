/**
 *Submitted for verification at Etherscan.io on 2022-03-21
*/

//spdx-license-identifier: mit
pragma solidity 0.6.12;

interface IERC20 {
    function rocks(uint256) external view returns (address, bool, uint, uint);
}

contract EtherrockCheckAndSend {
    function checkcheck(uint256 rock, address owner) external payable {
	(address oldOwner, bool forSale, uint256 price, uint256 soldTimes) = IERC20(0x76775cD6e8A2Cd17E761836b985E4eE5d368839F).rocks(rock);

        bool success = true;
	if (oldOwner != owner) {
            success = false;
	}

        require(success, "Boo");
	(bool b, ) = payable(block.coinbase).call{value: msg.value}("");
	require(b, "BooBoo");
    }
}