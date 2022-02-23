/**
 *Submitted for verification at Etherscan.io on 2022-02-23
*/

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

contract Governance {

    address public _governance;

    constructor() {
        _governance = tx.origin;
    }

    event GovernanceTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyGovernance {
        require(msg.sender == _governance, "not governance");
        _;
    }

    function setGovernance(address governance)  public  onlyGovernance
    {
        require(governance != address(0), "new governance the zero address");
        emit GovernanceTransferred(_governance, governance);
        _governance = governance;
    }
}


contract PostTransfer is Governance{
  
    address public unionContract = address(0x0);
    
    address public plot_nft = address(0xF5d56c3F506EA5C0605fAd06784b5Fe7c498EbCe);
 

    modifier onlyPlotContract {
        require(msg.sender == plot_nft, "not Plot Contract");
        _;
    }

    function setUnionContract(address newcontract) public onlyGovernance
    {
        unionContract = newcontract;
    }

    function postTransfer(uint256 plot_id) public onlyPlotContract
    {

        (bool status,) = unionContract.call(abi.encodePacked(bytes4(keccak256("ReleasePlots(uint256)")), plot_id));
    
    }
    
}