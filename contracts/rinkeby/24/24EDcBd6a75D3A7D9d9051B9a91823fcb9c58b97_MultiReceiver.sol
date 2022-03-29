//SPDX-License-Identifier: MIT
 pragma solidity ^0.8.4;

 import "../interfaces/ILayerZeroReceiver.sol";

 /// @title MultiReceiver
 /// @dev This contract is a toy contract that shows how to execute different functions based on payload within lzReceive
 /// @dev Based on the stargate contracts
 contract MultiReceiver is ILayerZeroReceiver {

	 uint8 internal constant TYPE_FUNCTION_ONE = 1;
	 uint8 internal constant TYPE_FUNCTION_TWO = 2;
	 uint8 internal constant TYPE_FUNCTION_THREE = 3;

	 address immutable public lzEndpoint;
	 uint256 public lastFunctionCalled;
	 uint256 public setOne;
	 address public setTwo;
	 string public setThree;

	 constructor(address _lzEndpoint)  {
		 lzEndpoint = _lzEndpoint;
	 }
	
	  function lzReceive(uint16 _srcChainId, bytes calldata _srcAddress, uint64 _nonce, bytes memory _payload) external override {
		  require(msg.sender == lzEndpoint, "Can only call from endpoint");
		  /*Might want to add some sort of check to only allow certain srcAddresses*/
		  uint8 functionType;
		  assembly {
			  functionType := mload(add(_payload, 32))
		  }

		  if(functionType == TYPE_FUNCTION_ONE) {
			  (,uint256 one) = abi.decode(_payload, (uint8, uint256));
			  _setOne(one);
		  } else if (functionType == TYPE_FUNCTION_TWO) {
			  (,address two) = abi.decode(_payload, (uint8, address));
			  _setTwo(two);
		  } else if (functionType == TYPE_FUNCTION_THREE) {
			  (,string memory three) = abi.decode(_payload, (uint8, string));
			  _setThree(three);
		  } 

	  }

	  function _setOne(uint256 _one) internal {
		  setOne = _one;
		  lastFunctionCalled = TYPE_FUNCTION_ONE;
	  }

	  function _setTwo(address _two) internal {
		  setTwo = _two;
		  lastFunctionCalled = TYPE_FUNCTION_TWO;
	  }

	  function _setThree(string memory _three) internal {
		  setThree = _three;
		  lastFunctionCalled = TYPE_FUNCTION_THREE;
	  }
 }

// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.5.0;

interface ILayerZeroReceiver {
    /// @notice LayerZero endpoint will invoke this function to deliver the message on the destination
    /// @param _srcChainId - the source endpoint identifier
    /// @param _srcAddress - the source sending contract address from the source chain
    /// @param _nonce - the ordered message nonce
    /// @param _payload - the signed payload is the UA bytes has encoded to be sent
    function lzReceive(uint16 _srcChainId, bytes calldata _srcAddress, uint64 _nonce, bytes calldata _payload) external;
}