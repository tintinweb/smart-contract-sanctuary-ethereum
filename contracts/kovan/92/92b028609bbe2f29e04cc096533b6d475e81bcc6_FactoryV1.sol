/**
 *Submitted for verification at Etherscan.io on 2022-03-18
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;
contract Guarantee{
    address _factory;
    address _partA;
    address _partB;
    address _coinAddress;
    uint256 _amount;
    constructor(address partA,address partB,address coinAddress,uint256 amount){
        _factory = msg.sender;
        _partA = partA;
        _partB = partB;
        _coinAddress = coinAddress;
        _amount = amount;
    }
    modifier onlyFactory(){
        require(msg.sender == _factory,"not factory");
        _;
    }
    modifier onlyPartA(){
        require(msg.sender == _partA,"not factory");
        _;
    }
    modifier onlyPartB(){
        require(msg.sender == _partB,"not factory");
        _;
    }
    //get allowance quantity
    function getAllowance() public view returns(uint256){
        bytes4 methodId = bytes4(keccak256("allowance(address,address)"));
        (bool success,bytes memory data) = _coinAddress.staticcall(abi.encodeWithSelector(methodId,_partA,address(this)));
        if(success){
            uint256 amount = abi.decode(data,(uint256));
            return amount;
        }else{
            return 0;
        }
    }
    

    // function LockpartAproperty(address coinAddress,uint256 quantity) onlyPartA returns(bool success){
    //     return true;
    // }
}
contract FactoryV1{
    struct Guaranteinfo{
        address partA;
        address partB;
        address coinAddress;
        uint256 amount;
    }


    
    mapping(address => Guaranteinfo) public guaranteeContracts;
    constructor(){}
    function createGuaranteeContract(address partA,address partB,address coinAddress,uint256 amount) public returns(Guarantee guaranteeContract){
        guaranteeContract = new Guarantee(partA,partB,coinAddress,amount); 
        address tmp = address(guaranteeContract);      
        guaranteeContracts[tmp].partA = partA;
        guaranteeContracts[tmp].partB = partB;
        guaranteeContracts[tmp].coinAddress = coinAddress;
        guaranteeContracts[tmp].amount = amount;
        return guaranteeContract;
    }


}