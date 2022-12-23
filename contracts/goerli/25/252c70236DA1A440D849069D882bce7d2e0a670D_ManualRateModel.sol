/**
 *Submitted for verification at Etherscan.io on 2022-12-23
*/

// File: contracts/simplestate/interfaces/IRateModel.sol


pragma solidity ^0.8.9;

interface IRateModel {

    function setRate(address _investmentProject, uint256 _convertionRate) external;

    function getRate(address _investmentProject) external view returns (uint256);
}
// File: contracts/simplestate/rates/ManualRateModel.sol


pragma solidity ^0.8.9;


contract ManualRateModel is IRateModel{

    mapping (address => uint256) currentRate;
    
    function getRate(address _investmentProject) external view returns (uint256){
        return currentRate[_investmentProject];
    }

    function setRate(address _investmentProject, uint256 _convertionRate) external {
        currentRate[_investmentProject] = _convertionRate;        
    }
}