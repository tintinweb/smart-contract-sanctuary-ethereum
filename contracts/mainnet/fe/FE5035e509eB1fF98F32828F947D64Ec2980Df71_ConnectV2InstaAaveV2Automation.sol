//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

/**
 * @title InstaAutomation
 * @dev Insta-Aave-v2-Automation
 */

import "./events.sol";
import "./interfaces.sol";

abstract contract Resolver is Events {
	InstaAaveAutomation internal immutable automation =
		InstaAaveAutomation(0x343635557b6bB7283d24AecD9c49259bA0648acF);

	function submitAutomationRequest(
		uint256 safeHealthFactor,
		uint256 thresholdHealthFactor
	)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		bool isAuth = AccountInterface(address(this)).isAuth(
			address(automation)
		);

		if (!isAuth)
			AccountInterface(address(this)).enable(address(automation));

		automation.submitAutomationRequest(
			safeHealthFactor,
			thresholdHealthFactor
		);

		(_eventName, _eventParam) = (
			"LogSubmitAutomation(uint256,uint256)",
			abi.encode(safeHealthFactor, thresholdHealthFactor)
		);
	}

	function cancelAutomationRequest()
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		automation.cancelAutomationRequest();

		bool isAuth = AccountInterface(address(this)).isAuth(
			address(automation)
		);

		if (isAuth)
			AccountInterface(address(this)).disable(address(automation));

		(_eventName, _eventParam) = ("LogCancelAutomation()", "0x");
	}

	function updateAutomationRequest(
		uint256 safeHealthFactor,
		uint256 thresholdHealthFactor
	)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		automation.cancelAutomationRequest();

		automation.submitAutomationRequest(
			safeHealthFactor,
			thresholdHealthFactor
		);

		(_eventName, _eventParam) = (
			"LogUpdateAutomation(uint256,uint256)",
			abi.encode(safeHealthFactor, thresholdHealthFactor)
		);
	}
}

contract ConnectV2InstaAaveV2Automation is Resolver {
	string public constant name = "Insta-Aave-V2-Automation-v1";
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

contract Events {
	event LogCancelAutomation();

	event LogSubmitAutomation(uint256 safeHF, uint256 thresholdHF);

	event LogUpdateAutomation(uint256 safeHF, uint256 thresholdHF);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

interface InstaAaveAutomation {
	function submitAutomationRequest(
		uint256 safeHealthFactor,
		uint256 thresholdHealthFactor
	) external;

	function cancelAutomationRequest() external;

	function updateAutomation(
		uint256 safeHealthFactor,
		uint256 thresholdHealthFactor
	) external;
}

interface AccountInterface {
	function enable(address) external;

	function disable(address) external;

	function isAuth(address) external view returns (bool);
}