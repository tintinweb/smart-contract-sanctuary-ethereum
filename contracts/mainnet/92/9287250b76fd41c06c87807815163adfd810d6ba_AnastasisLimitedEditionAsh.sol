// SPDX-License-Identifier: MIT

pragma solidity >= 0.8.13;

import "./AnastasisAct3.sol";
import "./FundSplit.sol";
import "./IERC721.sol";
import "./IERC20.sol";

contract AnastasisLimitedEditionAsh {

    uint256 public _price = 40*10**18;

    address public _ashAddress= 0x64D91f12Ece7362F91A6f8E7940Cd55F05060b92;
    address public _anastasisAct3Address;
    address private _fundSplitAddress;

    bool public _publicMintOpened;
    bool public _mintLimit = true;

    mapping (address => bool) public _isAdmin;
    mapping (address => bool) public _addressMintedInPublicSale;


    constructor(){
        _isAdmin[msg.sender] = true;
    }

    function approveAdmin(address newAdmin)external{
        require(_isAdmin[msg.sender]);
        _isAdmin[newAdmin] = true;
    }

    function removeAdmin(address exAdmin)external{
        require(_isAdmin[msg.sender]);
        _isAdmin[exAdmin] = false;
    }

    function setRecipient(address fundSplitAddress) external {
        require(_isAdmin[msg.sender]);
        _fundSplitAddress = fundSplitAddress;
    }

    function setAshAddress(address ashAddress) external{
        require(_isAdmin[msg.sender]);
        _ashAddress = ashAddress;
    }

    function setAnastasisAct3Address(address anastasisAct3Address) external{
        require(_isAdmin[msg.sender]);
        _anastasisAct3Address = anastasisAct3Address;
    }

    function togglePublicMintOpened()external{
        require(_isAdmin[msg.sender]);
        _publicMintOpened = !_publicMintOpened;
    }

    function toggleMintLimit()external{
        require(_isAdmin[msg.sender]);
        _mintLimit = !_mintLimit;
    }

    function publicAshMint() external payable{
        require(_publicMintOpened, "Mint closed");
        if(_mintLimit){
            require(!_addressMintedInPublicSale[msg.sender], "Already Minted");
        }
        bool success;
        address payable fundSplitContract = payable(address(_fundSplitAddress));
        success = FundSplit(fundSplitContract).depositAsh(msg.sender, _price);
        require(success, "Funds could not transfer");
        _addressMintedInPublicSale[msg.sender] = true;
        Anastasis_Act3(_anastasisAct3Address).mint(msg.sender);
    }

}