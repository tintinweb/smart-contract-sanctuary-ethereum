// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;



/*
Module that just holds fee information. This allow various contracts to grab required information without
needing a reference to the current "booster" or management contract
*/
contract FeeRegistry{

    address public constant owner = address(0x59CFCD384746ec3035299D90782Be065e466800B);

    uint256 public cvxfxsIncentive = 1000;
    uint256 public cvxIncentive = 700;
    uint256 public platformIncentive = 0;
    uint256 public totalFees = 1700;
    address public feeDeposit;
    uint256 public constant maxFees = 2000;
    uint256 public constant FEE_DENOMINATOR = 10000;


    mapping(address => address) public redirectDepositMap;

    constructor() {}

    /////// Owner Section /////////

    modifier onlyOwner() {
        require(owner == msg.sender, "!auth");
        _;
    }

    //set platform fees
    function setFees(uint256 _cvxfxs, uint256 _cvx, uint256 _platform) external onlyOwner{
        totalFees = _cvxfxs + _cvx + _platform;
        require(totalFees <= maxFees, "fees over");

        cvxfxsIncentive = _cvxfxs;
        cvxIncentive = _cvx;
        platformIncentive = _platform;
    }

    function setDepositAddress(address _deposit) external onlyOwner{
        require(_deposit != address(0),"zero");
        feeDeposit = _deposit;
    }

    function setRedirectDepositAddress(address _from, address _deposit) external onlyOwner{
        redirectDepositMap[_from] = _deposit;
    }

    function getFeeDepositor(address _from) external view returns(address){
        //check if in redirect map
        if(redirectDepositMap[_from] != address(0)){
            return redirectDepositMap[_from];
        }

        //return default
        return feeDeposit;
    }

}