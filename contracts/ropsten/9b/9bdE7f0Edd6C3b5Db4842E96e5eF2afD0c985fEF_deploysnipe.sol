//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.4;

import "./ExampleNFT.sol";

contract deploysnipe {

    event deployAndMinted (
        address _addr,
        bytes _return
    );

    address _addr;
    bytes data;

    struct ExampleNFTinfo {
        address exampleNFT;
        uint256 id;
    }

    mapping(uint256 => ExampleNFTinfo) contractsByID;

    constructor() {

    }

    function deployLFG(uint256 _id) external returns (address) {
        ExampleNFTinfo storage info = contractsByID[_id];
        info.exampleNFT = address(new ExampleNFT(2));
        info.id = _id;

        (bool success, bytes memory _return) = info.exampleNFT.call(abi.encodeWithSignature("mint(uint256)", "2"));

        emit deployAndMinted(info.exampleNFT, _return);

        return info.exampleNFT;
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

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.4;

contract ExampleNFT {

    uint256 VALUE = 5;
    address owner;

    constructor(uint256 _num) {
        VALUE = _num;
    }

    function mint(uint256 amount) 
        external
        returns (uint256)
    {
        return amount + VALUE;
    }
}