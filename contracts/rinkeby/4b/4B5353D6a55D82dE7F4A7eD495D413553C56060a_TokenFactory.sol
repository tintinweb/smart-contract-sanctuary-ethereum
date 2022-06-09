// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface CommonTokenFactory {
    function IcreateCommonToken(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        uint256 totalSupply_
    ) external ;

    function IgetCommonToken(uint _index)
        external
        view
        returns (
            string memory _name,
            string memory _symbol,
            uint256 _totalSupply,
            uint256 balance
        );
}

contract TokenFactory {
    address public _commonTokenContract;
    address private _owner;

    modifier onlyOwner() {
        require(msg.sender == _owner, "Caller is not the owner");
        _;
    }

    constructor() {
        _owner = msg.sender;
    }

    // Return owner address of contract
    function owner() public view virtual returns (address) {
        return _owner;
    }

    // set _commonTokenContract address by owner
    function setCommonTokenContract(address commonTokenContract_) public onlyOwner {
        require(commonTokenContract_ != address(0), "Address can not be Adress(0)");
        _commonTokenContract = commonTokenContract_;
    }

    function factoryCommonToken(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        uint256 totalSupply_
    ) public {
        //require(msg.value >= 0.003 ether, "You must pay at 0.003 BNB for FEE Create Token");
        // Owner need set _commonTokenContract address first to user create common Token

        require(_commonTokenContract != address(0), "Owner not set _commonTokenContract address yet");

        CommonTokenFactory commonToken =  CommonTokenFactory(_commonTokenContract); 

        commonToken.IcreateCommonToken(name_, symbol_, decimals_, totalSupply_);     
    }
    
    function getCommonToken(uint256 _index) 
        public 
        view
        returns(address)
    {
        // require(_commonTokenContract != address(0), "Owner not set _commonTokenContract address yet");
        return _commonTokenContract;     
    }
}