/**
 *Submitted for verification at Etherscan.io on 2022-09-22
*/

// contracts/GLDToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IInsuranceDao {
    function insure(uint256 amount, string memory symbol) external returns (uint256);
    function init(
        address insuredAddress,
        uint256 coverageAmount,
        uint8 premium
    ) external;
}

interface IDaoclubV2 {
    function addInsure(address insureDaoAddress, uint256 coverageAmount, uint premium) external;
    function init(
        address owner,
        string memory tokenSymbol,
        string memory targetSymbol,
        uint256 totalFund,
        uint256 miniOffering,
        uint8 expectedRevenue,
        uint256 collectionDeadline,
        uint256 managementDuration,
        address summonerAddress
    ) external;
}

contract CloneFactory { // implementation of eip-1167 - see https://eips.ethereum.org/EIPS/eip-1167
    function createClone(address target) internal returns (address result) {
        bytes20 targetBytes = bytes20(target);
        assembly {
            let clone := mload(0x40)
            mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(clone, 0x14), targetBytes)
            mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            result := create(0, clone, 0x37)
        }
    }
}


contract DaoclubSummoner is CloneFactory { 

    
    
    address public _template;
    address public _insuranceTemplate;
    address _owner;
    IDaoclubV2 private _daoclubV2;
    IInsuranceDao private _insuranceDao;
    
    
    constructor(address template, address insuranceTemplate) {
        _template = payable(template);
        _insuranceTemplate = payable(insuranceTemplate);
        _owner = msg.sender;
    }
    
    event SummonComplete(address indexed daoclub, address summoner);
    event InsuranceSummonComplete(address indexed daoclub, address indexed insuranceDao, address summoner);
    
    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }




    function resetTemplate(address template) onlyOwner external {
        _template = payable(template);
    }

    function resetInsureTemplate(address template) onlyOwner external {
        _insuranceTemplate = payable(template);
    }
    
     
    function summonDaoclub (
        
        string memory symbol,
        string memory targetSymbol,
        uint256 totalFund,
        uint256 miniOffering,
        uint8 expectedRevenue,
        uint256 collectionDeadline,
        uint256 managementDuration,
        address summonerAddress,
        uint8 createInsurance,
        uint256 coverageAmount,
        uint8 premium


    ) public returns (address) {
        _daoclubV2 = IDaoclubV2(payable(createClone(_template)));
        _daoclubV2.init(
            msg.sender,
            symbol,
            targetSymbol,
            totalFund,
            miniOffering,
            expectedRevenue,
            collectionDeadline,
            managementDuration,
            summonerAddress
        );
       
        emit SummonComplete(address(_daoclubV2), msg.sender);

        if(createInsurance == 1) {
            _insuranceDao = IInsuranceDao(payable(createClone(_insuranceTemplate)));
            _insuranceDao.init(address(_daoclubV2), coverageAmount, premium);
            _daoclubV2.addInsure(address(_insuranceDao), coverageAmount, premium);
            emit InsuranceSummonComplete(address(_daoclubV2), address(_insuranceDao), msg.sender);
        }
        


        return address(_daoclubV2);
    }


    
}