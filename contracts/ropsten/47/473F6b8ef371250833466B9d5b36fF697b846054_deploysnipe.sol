//SPDX-License-Identifier: UNLICENSED
contract deploysnipe {

    address _addr;
    bytes data;

    struct ExampleNFTinfo {
        address exampleNFT;
        uint256 id;
    }

    constructor() {

    }

    function seeBytes() external view returns (bytes memory) {
        return data;
    }
    
    function mint(address test) external returns (bytes memory) {
        
       (bool success, bytes memory _data) = test.call(abi.encodeWithSignature("mint(uint256)", "2"));
        require(success, "fail");

        data = _data;
        return _data;
    }

}