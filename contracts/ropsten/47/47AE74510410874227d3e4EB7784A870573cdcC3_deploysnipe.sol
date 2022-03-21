//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.4;

import "./ExampleNFT.sol";

contract deploysnipe {

    address _addr;
    bytes data;

    struct ExampleNFTinfo {
        address exampleNFT;
        uint256 id;
    }

    constructor() {

    }

    mapping(uint256 => ExampleNFTinfo) examplenftInfoByID;

    function deploy(
        uint256 _id
    ) external returns (address) {

        ExampleNFTinfo storage info = examplenftInfoByID[_id];

        info.exampleNFT = address(new ExampleNFT(12345678, address(this)));
        info.id = _id;

        return info.exampleNFT;
    }

    function seeContract(uint256 _id) public view returns (address) {
        return examplenftInfoByID[_id].exampleNFT;
    }

    function seeBytes() external view returns (bytes memory) {
        return data;
    }
    
    function mint(address test) external returns (bytes memory) {
        
       (bool success, bytes memory _data) = test.call(abi.encodeWithSignature("function mint(uint256)", "2"));
        require(success, "fail");

        data = _data;
        return _data;
    }

}

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.4;

contract ExampleNFT {

    uint256 VALUE;
    address owner;

    constructor(
        uint256 _MINTvalue,
        address _owner
    ) {
        VALUE = _MINTvalue;
        owner = _owner;
    }


    function mint(uint256 amount) 
        external
        pure
        returns (string memory)
    {
        return "testing return";
    }
}