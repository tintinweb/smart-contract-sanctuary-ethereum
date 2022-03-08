// SPDX-License-Identifier: MIT

pragma solidity >= 0.8.12;

import "./ERC1155.sol";
import "./IERC20.sol";
import "./IEIP2981.sol";
import "./AdminControl.sol";


//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
////////////////////////////QDkyx\?=^;;;~~;;!^=|cI5XDQ////////////////////////////
/////////////////////QA{*;'                           `';|fKQ/////////////////////
/////////////////g{^'      .~<z5UD&Q//////////Q#DXy7=~.      `+j#/////////////////
//////////////RL'     `;J6Q////////////////////////////QU7;`     ,TW//////////////
////////////y'     `=%//////QXL+}%/////////////Qq7cXQ///////Di`     ,m////////////
//////////D,     `LQ/////DL:      .!}%/////Qqv~`     ~i6//////#>      ~8//////////
/////////K`     'D////////Qm*,        `~7m<`       `~7qQ////////6`     .%/////////
/////////+      }/////////////Qm*,        .~;;~.~7qQ/////////////7      L/////////
/////////+      }//////////////Qm*;;;~`       `~vqQ//////////////7      L/////////
/////////K`     'D/////////QS*,      .~^|,        `~vqQ/////////6`     .%/////////
//////////D,     `LQ/////g+`       .^fg///Qq7~`      `!U//////&>      ~8//////////
////////////y'     `=%/////QK7~'^fg///////////Qq7;;tD///////Di`     ,m////////////
//////////////RL'     `;JAQ////////////////////////////QU7;`     ,Tg//////////////
/////////////////gu^'      .~<z5UR&Q//////////Q#DXy7=~.      `+y#/////////////////
/////////////////////QA{*;'                           `';|fKQ/////////////////////
////////////////////////////QDXyt\?=^;;;~;;;!^=|cI5XDQ////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////


contract UNITY is ERC1155, AdminControl {
    
    mapping (address => bool) public _tokensWhitelisted;
    mapping (address => bool) public _tokensClaimed;

    uint256 public ashPrice = 18*10**18; //18 ASH
    uint256 private _royaltyAmount; //in % 

    address public ashContract = 0x64D91f12Ece7362F91A6f8E7940Cd55F05060b92;
    address private _royalties_recipient;

    bool public dropOpened = false;
    constructor () ERC1155("") {
        _royalties_recipient = payable(msg.sender);
        _royaltyAmount = 10;
    } 

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155, AdminControl)
        returns (bool)
    {
        return
        AdminControl.supportsInterface(interfaceId) ||
        ERC1155.supportsInterface(interfaceId) ||
        interfaceId == type(IEIP2981).interfaceId ||
        super.supportsInterface(interfaceId);
    }

    function setURI(string calldata _uri) external adminRequired{
        _setURI(_uri);
    }

    function mint(
        address account
    ) external{
        require( (_tokensClaimed[account] == false && _tokensWhitelisted[account] == true) || isAdmin(msg.sender), "You are not whitelisted for that many tokens!");
        require( dropOpened || isAdmin(msg.sender), "The drop is closed");
        if(!isAdmin(msg.sender)){
            IERC20(ashContract).transferFrom(msg.sender, _royalties_recipient, ashPrice);
            _tokensClaimed[account] = true;
        }
        _mint(account ,1 ,1 ,"0x00");
    }


    function loadWL(
        address[] calldata _whitelistedAddresses 
    )external adminRequired{
        for(uint256 i; i<_whitelistedAddresses.length; i++){
            _tokensWhitelisted[_whitelistedAddresses[i]] = true;
        }
    }

    function toggleDropState()external adminRequired{
        dropOpened = !dropOpened;
    }

    function burn() public {
        super._burn(msg.sender, 1, 1);
    }

    function setRoyalties(address payable _recipient, uint256 _royaltyPerCent) external adminRequired {
        _royalties_recipient = _recipient;
        _royaltyAmount = _royaltyPerCent;
    }

    function royaltyInfo(uint256 salePrice) external view returns (address, uint256) {
        if(_royalties_recipient != address(0)){
            return (_royalties_recipient, (salePrice * _royaltyAmount) / 100 );
        }
        return (address(0), 0);
    }

    function withdraw(address recipient) external adminRequired {
        payable(recipient).transfer(address(this).balance);
    }

}