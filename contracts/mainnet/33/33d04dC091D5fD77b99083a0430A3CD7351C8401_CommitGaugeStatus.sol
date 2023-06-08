// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./interfaces/ICurveGauge.sol";
import "./interfaces/IGaugeController.sol";
import "./interfaces/IZkEvmBridge.sol";

contract CommitGaugeStatus {

    bytes4 private constant updateSelector = bytes4(keccak256("setGauge(address,bool)"));
    address public constant gaugeController = address(0x2F50D538606Fa9EDD2B11E2446BEb18C9D5846bB);
    address public constant bridge = address(0x2a3DD3EB832aF982ec71669E178424b10Dca2EDe);


    function commit(
        address _gauge,
        address _contractAddr
    ) external  {
        //get weight for valid gauge
        require(IGaugeController(gaugeController).get_gauge_weight(_gauge) > 0, "must have weight");

        //check killed for status
        bool active = !ICurveGauge(_gauge).is_killed();

        //build data
        bytes memory data = abi.encodeWithSelector(updateSelector, _gauge, active);

        //submit to L2
        uint32 destinationNetwork = 1;
        bool forceUpdateGlobalExitRoot = true;
        IZkEvmBridge(bridge).bridgeMessage{value:0}(
            destinationNetwork,
            _contractAddr,
            forceUpdateGlobalExitRoot,
            data
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;


interface IZkEvmBridge{
	function bridgeMessage(
		uint32 destinationNetwork,
		address destinationAddress,
		bool forceUpdateGlobalExitRoot,
		bytes calldata metadata
	) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IGaugeController {
    function get_gauge_weight(address _gauge) external view returns(uint256);
    function vote_user_slopes(address,address) external view returns(uint256,uint256,uint256);//slope,power,end
    function vote_for_gauge_weights(address,uint256) external;
    function add_gauge(address,int128,uint256) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface ICurveGauge {
    function is_killed() external view returns(bool);
}