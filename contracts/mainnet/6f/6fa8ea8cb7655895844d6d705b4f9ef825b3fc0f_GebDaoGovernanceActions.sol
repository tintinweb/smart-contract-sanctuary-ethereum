/**
 *Submitted for verification at Etherscan.io on 2022-06-02
*/

pragma solidity ^0.6.7;

abstract contract Setter {
    function modifyParameters(bytes32, uint256) external virtual;
    function modifyParameters(bytes32, int256) external virtual;
    function modifyParameters(bytes32, address) external virtual;
    function modifyParameters(bytes32, bytes32, address) external virtual;
    function modifyParameters(address, bytes32, uint) virtual public;
    function modifyParameters(address, bytes32, address) virtual public;
    function modifyParameters(address, bytes4, bytes32, uint256) virtual public;    
    function connectSAFESaviour(address) virtual external;
    function disconnectSAFESaviour(address) virtual external;    
    function transferERC20(address, address, uint256) external virtual;
    function restartRedemptionRate() virtual public;    
    function changePriceSource(address) virtual public;    
}

// @notice Contract to be used by GEB DAO allowing changes in all RAI parameters that were not ungoerned
// @dev Supposed to be delegatecalled into by the RAI Ungovernor
contract GebDaoGovernanceActions {

    function modifyParameters(address target, bytes32 param, uint256 val) public {
        Setter(target).modifyParameters(param, val);
    }    

    function modifyParameters(address target, bytes32 param, int256 val) public {
        Setter(target).modifyParameters(param, val);
    }    

    function modifyParameters(address target, bytes32 param, address val) public {
        Setter(target).modifyParameters(param, val);
    }

    function modifyParameters(address target, bytes32 collateralType, bytes32 parameter, address data) public {
        Setter(target).modifyParameters(collateralType, parameter, data);
    }      

    function modifyParameters(address target, address reimburser, bytes32 parameter, uint256 data) public {
        Setter(target).modifyParameters(reimburser, parameter, data);
    }

    function modifyParameters(address target, address reimburser, bytes32 parameter, address data) public {
        Setter(target).modifyParameters(reimburser, parameter, data);
    }

    function modifyParameters(address target, address fundingTarget, bytes4 fundedFunction, bytes32 parameter, uint256 data) public {
        Setter(target).modifyParameters(fundingTarget, fundedFunction, parameter, data);
    }    

    function connectSAFESaviour(address target, address saviour) public {
        Setter(target).connectSAFESaviour(saviour);
    }

    function disconnectSAFESaviour(address target, address saviour) public {
        Setter(target).disconnectSAFESaviour(saviour);
    }    

    function transferERC20(address target, address token, address dst, uint256 amount) public {
        Setter(target).transferERC20(token, dst, amount);
    }        

    function restartRedemptionRate(address target) public {
        Setter(target).restartRedemptionRate();
    }

    function changePriceSource(address target, address source) public {
        Setter(target).changePriceSource(source);
    }    


}