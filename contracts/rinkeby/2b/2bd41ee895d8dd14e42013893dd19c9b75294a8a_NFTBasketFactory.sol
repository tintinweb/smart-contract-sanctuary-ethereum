//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './Clones.sol';

contract NFTBasketFactory {
    uint public basketCount;

    address private blueprint;
     
    event CreateBasket(address indexed contractAddress, address indexed creator);
     
    constructor(address _blueprint) {
        blueprint = _blueprint;
    }
     
    function createBasket(string memory _name, string memory _symbol, string memory _metadataURI) public {
        bytes memory implementationCalldata = abi.encodeWithSignature(
            "initialize(string,string,address,string)",
            _name,
            _symbol,
            msg.sender,
            _metadataURI
        );

        address basketAddress = Clones.clone(blueprint);
        (bool ok,) = basketAddress.call(implementationCalldata);
        require(ok, "basket has no create completely");

        basketCount++;
        emit CreateBasket(basketAddress, msg.sender);
    }
}