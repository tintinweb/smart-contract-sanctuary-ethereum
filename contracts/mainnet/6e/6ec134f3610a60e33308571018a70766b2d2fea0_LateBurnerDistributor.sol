/**
 *Submitted for verification at Etherscan.io on 2023-01-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMoSOLID {
    function transfer(address _to, uint256 _amount) external;

    function balanceOf(address _user) external view returns (uint256);
}

interface IVeSOLID {
    function split(uint256 _from, uint256 _amount) external returns (uint256);

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenID
    ) external;

    function approve(address spender, uint256 tokenID) external;

    function setApprovalForAll(address _operator, bool _approved) external;
}

contract LateBurnerDistributor {
    address operator;
    IVeSOLID veSOLID;
    IMoSOLID moSOLID;

    modifier onlyOperator() {
        require(msg.sender == operator || tx.origin == operator);
        _;
    }

    /** Designate the operator address, vesolid token address, and mosolid token address at construction **/
    constructor(
        address _operator,
        address _veSOLID,
        address _moSOLID
    ) {
        operator = _operator;
        veSOLID = IVeSOLID(_veSOLID); //0x77730ed992d286c53f3a0838232c3957daeaaf73
        moSOLID = IMoSOLID(_moSOLID); //0x848578e351D25B6Ec0d486E42677891521c3d743
    }

    /** Call to distribute moSOLID only to the late burners.  **/
    function distributeMoSOLID_Only(address _lateburner, uint256 _amntOfMoSOLID) external onlyOperator {
        moSOLID.transfer(_lateburner, _amntOfMoSOLID);
    }

    /** Call to split the master NFT into a smaller one before sending NFT **/

    function splitVeSOLID_Only(uint256 _veSOLIDAmount, uint256 _tokenID) external onlyOperator {
        veSOLID.split(_tokenID, _veSOLIDAmount);
    }

    /** Call to send the veSOLID to the user, ONLY **/
    function distributeVeSOLID_Only(
        address _lateburner,
        uint256 _veSOLIDAmount,
        uint256 _masterID
    ) external onlyOperator {
        uint256 newTokenID = veSOLID.split(_masterID, _veSOLIDAmount);
        veSOLID.approve(_lateburner, newTokenID);
        veSOLID.safeTransferFrom(address(this), _lateburner, newTokenID);
        veSOLID.setApprovalForAll(_lateburner, false);
    }

    /** Sends both a veNFT and moSOLID to the user in 1 tx. **/
    function fullSend_moSOLID_veSOLID(
        address _lateburner,
        uint256 _moSOLIDAmount,
        uint256 _veSOLIDAmount,
        uint256 _masterID
    ) external onlyOperator {
        moSOLID.transfer(_lateburner, _moSOLIDAmount);
        uint256 newTokenID = veSOLID.split(_masterID, _veSOLIDAmount);
        veSOLID.approve(_lateburner, newTokenID);
        veSOLID.safeTransferFrom(address(this), _lateburner, newTokenID);
        veSOLID.setApprovalForAll(_lateburner, false);
    }

    /** Emergency withdraws all the tokens and veSOLID in the contract incase of stuck funds **/

    function emergencyWithdrawAll(uint256 _masterTokenID) external onlyOperator {
        moSOLID.transfer(operator, moSOLID.balanceOf(address(this)));
        veSOLID.approve(operator, _masterTokenID);
        veSOLID.safeTransferFrom(address(this), operator, _masterTokenID);
        veSOLID.setApprovalForAll(operator, false);
    }
}