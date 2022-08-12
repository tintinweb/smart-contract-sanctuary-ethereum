// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.9;

contract Vault {
    // a contract where the owner create grant for a beneficiary;
    //allows beneficiary to withdraw only when time elapse
    //allows owner to withdraw before time elapse
    //get information of a beneficiary
    //amount of ethers in the smart contract

    //*********** state variables ********/
    //epoch time for testing = 1659657060
    //contract address= 0xA69fce9eD668150710F4b6CE3D4A9Ad6ecc9758A -goerli testnet
    address public owner;
    uint256 ID = 1;
    uint256[] id;

    struct BeneficiaryProperties {
        uint256 amountAllocated;
        address beneficiary;
        uint256 time;
        bool status;
    }
    mapping(uint256 => BeneficiaryProperties) public _beneficiaryProperties;

    modifier onlyOwner() {
        require(msg.sender == owner, "not owner");
        _;
    }

    modifier hasTimeElapse(uint256 _id) {
        BeneficiaryProperties memory BP = _beneficiaryProperties[_id];
        require(block.timestamp >= BP.time, "time never reach");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    //function to create grant for a beneficiary in vault
    function createGrant(address _beneficiary, uint256 _time)
        external
        payable
        onlyOwner
        returns (uint256)
    {
        require(msg.value > 0, "zero ether not allowed");
        BeneficiaryProperties storage BP = _beneficiaryProperties[ID];
        BP.time = block.timestamp + (_time * 1 seconds);
        BP.amountAllocated = msg.value;
        BP.beneficiary = _beneficiary;
        uint256 _id = ID;
        id.push(_id);
        ID++;
        return _id;
    }

    //function to withdraw a specific amount a grant beneficiary has for a particular grant, can only be called by the beneficiary if it exits
    function withDrawAmount(uint256 _id, uint256 _amountToWithdraw)
        external
        hasTimeElapse(_id)
    {
        BeneficiaryProperties storage BP = _beneficiaryProperties[_id];
        address user = BP.beneficiary;
        require(user == msg.sender, "not a beneficiary for a grant");
        uint256 _amount = BP.amountAllocated;
        require(_amount > 0, "you  have no money!");
        require(
            _amountToWithdraw <= address(this).balance,
            "insufficient amount in contract"
        );
        // gas 41970 with if statement
        // 41995
        // gas 42025 without if statement
        if (_amountToWithdraw < _amount) {
            uint256 newAmount = _amount - _amountToWithdraw;
            BP.amountAllocated = newAmount;
            payable(user).transfer(_amountToWithdraw);
        }
        if (_amountToWithdraw == _amount) {
            BP.amountAllocated = 0;
            payable(user).transfer(_amount);
        }
    }

    //function to withdraw/revert grant of a particular grant beneficiary, can only be called by owner of contract
    function RevertGrant(uint256 _id) external onlyOwner {
        BeneficiaryProperties storage BP = _beneficiaryProperties[_id];
        uint256 _amount = BP.amountAllocated;
        BP.amountAllocated = 0;
        payable(owner).transfer(_amount);
    }

    //check info a particular grant beneficiary
    function returnBeneficiaryInfo(uint256 _id)
        external
        view
        returns (BeneficiaryProperties memory BP)
    {
        BP = _beneficiaryProperties[_id];
    }

    //get total balance in the contract
    function getBalance() public view returns (uint256 bal) {
        bal = address(this).balance;
    }

    //get all beneficiary in the contract --this is not actually the best way to do this and was done on purpose
    function getAllBeneficiary()
        external
        view
        returns (BeneficiaryProperties[] memory _bp)
    {
        uint256[] memory all = id;
        _bp = new BeneficiaryProperties[](all.length);

        for (uint256 i = 0; i < all.length; i++) {
            _bp[i] = _beneficiaryProperties[all[i]];
        }
    }
}