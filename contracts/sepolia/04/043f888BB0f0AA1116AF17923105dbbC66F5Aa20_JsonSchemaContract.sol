/**
 *Submitted for verification at Etherscan.io on 2023-05-31
*/

contract JsonSchemaContract {
struct JsonSchema {
	string name;
	bool status;
}

	mapping (uint256 => JsonSchema) private _data;

	function getJsonSchema(uint256 id) public view returns (JsonSchema memory) {
		return _data[id];
	}

	function setJsonSchema(uint256 id, JsonSchema memory newData) public {
		_data[id] = newData;
	}
}