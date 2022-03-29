// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;


contract testSelector {
    address owner;
    mapping (bytes4 => address) selectAddress;

    constructor () {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "not owner.");
        _;
    }

    function swap (
        bytes4 _selector,
        bytes memory data
    ) external onlyOwner {
        address routerAddress = getSelectAddress(_selector);
        (bool success, bytes memory resultData) = routerAddress.delegatecall(data);

        require(success, "swap fail");
    }

    receive () external payable {}


    function setSelectAddress (bytes4 _selector, address _routerAddress) public onlyOwner {
        require(selectAddress[_selector] == address(0), "selector has been setted.");
        selectAddress[_selector] = _routerAddress;
    }

    function getSelectAddress (bytes4 _selector) public view returns (address) {
        return selectAddress[_selector];
    }
}