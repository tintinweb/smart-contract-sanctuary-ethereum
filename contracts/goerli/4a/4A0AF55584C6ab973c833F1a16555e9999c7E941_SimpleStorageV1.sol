// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

contract SimpleStorageV1 {
    bool _isActive = true;

    address public owner;

    mapping(string => uint256) public nameToFavoriteNumber;

    // the first person to deploy the contract is
    // the owner
    constructor() {
        owner = msg.sender;
    }

    function store(string memory name, uint256 value) public canOperate {
        nameToFavoriteNumber[name] = value;
    }

    function retrieve(string memory name)
        public
        view
        canOperate
        returns (uint256)
    {
        return nameToFavoriteNumber[name];
    }

    function destroySmartContract() public canOperate {
        selfdestruct(payable(address(this)));
        setActive(false);
    }

    function setActive(bool isActive) public canOperate {
        // restrict access to this function
        _isActive = isActive;
    }

    modifier canOperate() {
        require(msg.sender == owner, "You are not the contract owner");
        require(_isActive == true, "This contract is disabled");
        _;
    }
}