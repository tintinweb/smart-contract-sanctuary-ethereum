// ░██████╗████████╗░█████╗░██████╗░██████╗░██╗░░░░░░█████╗░░█████╗░██╗░░██╗
// ██╔════╝╚══██╔══╝██╔══██╗██╔══██╗██╔══██╗██║░░░░░██╔══██╗██╔══██╗██║░██╔╝
// ╚█████╗░░░░██║░░░███████║██████╔╝██████╦╝██║░░░░░██║░░██║██║░░╚═╝█████═╝░
// ░╚═══██╗░░░██║░░░██╔══██║██╔══██╗██╔══██╗██║░░░░░██║░░██║██║░░██╗██╔═██╗░
// ██████╔╝░░░██║░░░██║░░██║██║░░██║██████╦╝███████╗╚█████╔╝╚█████╔╝██║░╚██╗
// ╚═════╝░░░░╚═╝░░░╚═╝░░╚═╝╚═╝░░╚═╝╚═════╝░╚══════╝░╚════╝░░╚════╝░╚═╝░░╚═╝

// SPDX-License-Identifier: MIT
// StarBlock Contracts, more: https://www.starblock.io/

pragma solidity ^0.8.10;

//import "erc721a/contracts/extensions/IERC721AQueryable.sol";
//import "@openzeppelin/contracts/interfaces/IERC2981.sol";
//import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./IERC721AQueryable.sol";
import "./IERC2981.sol";
import "./IERC20.sol";

interface IStarBlockCollection is IERC721AQueryable, IERC2981 {
    struct SaleConfig {
        uint256 startTime;// 0 for not set
        uint256 endTime;// 0 for will not end
        uint256 price;
        uint256 maxAmountPerAddress;// 0 for not limit the amount per address
    }

    event UpdateWhitelistSaleConfig(SaleConfig _whitelistSaleConfig);
    event UpdateWhitelistSaleEndTime(uint256 _oldEndTime, uint256 _newEndTime);
    event UpdatePublicSaleConfig(SaleConfig _publicSaleConfig);
    event UpdatePublicSaleEndTime(uint256 _oldEndTime, uint256 _newEndTime);
    event UpdateChargeToken(IERC20 _chargeToken);

    function supportsInterface(bytes4 _interfaceId) external view override(IERC165, IERC721A) returns (bool);
    
    function maxSupply() external view returns (uint256);
    function exists(uint256 _tokenId) external view returns (bool);
    
    function maxAmountForArtist() external view returns (uint256);
    function artistMinted() external view returns (uint256);

    function chargeToken() external view returns (IERC20);

    function whitelistSaleConfig() external view returns (SaleConfig memory);
    // function whitelistSaleConfig() external view 
    //         returns (uint256 _startTime, uint256 _endTime, uint256 _price, uint256 _maxAmountPerAddress);
    function whitelist(address _user) external view returns (bool);
    function whitelistAmount() external view returns (uint256);
    function whitelistSaleMinted(address _user) external view returns (uint256);

    function publicSaleConfig() external view returns (SaleConfig memory);
    // function publicSaleConfig() external view 
    //         returns (uint256 _startTime, uint256 _endTime, uint256 _price, uint256 _maxAmountPerAddress);
    function publicSaleMinted(address _user) external view returns (uint256);

    function userCanMintTotalAmount() external view returns (uint256);

    function whitelistMint(uint256 _amount) external payable;
    function publicMint(uint256 _amount) external payable;
}

contract StarBlockCollectionUtils {
    struct CollectionInfo {
        uint256 blockTime;// the current timestamp in BlockChain
        uint256 maxSupply;
        uint256 totalSupply;
        uint256 maxAmountForArtist;
        uint256 artistMinted;
        uint256 userCanMintTotalAmount;// all the user can mint amount

        IStarBlockCollection.SaleConfig whitelistSaleConfig;
        uint256 whitelistSaleStatus;
        uint256 whitelistAmount;

        IStarBlockCollection.SaleConfig publicSaleConfig;
        uint256 publicSaleStatus;
    }

    struct UserInfo {
        bool inWhitelist;
        uint256 canMintAmountWhitelistSale;
        uint256 canMintAmountPublicSale;
    }
    
    //get collection info and user info in one method
    function getCollectionInfo(IStarBlockCollection _starBlockCollection, address _user) external view returns (
            CollectionInfo memory _collectionInfo, UserInfo memory _userInfo) {
        require(address(_starBlockCollection) != address(0), "StarBlockCollectionUtils: _starBlockCollection can not be zero!");
        _collectionInfo.blockTime = block.timestamp;
        _collectionInfo.maxSupply = _starBlockCollection.maxSupply();
        _collectionInfo.totalSupply = _starBlockCollection.totalSupply();
        _collectionInfo.maxAmountForArtist = _starBlockCollection.maxAmountForArtist();
        _collectionInfo.artistMinted = _starBlockCollection.artistMinted();
        _collectionInfo.userCanMintTotalAmount = _starBlockCollection.userCanMintTotalAmount();

        _collectionInfo.whitelistSaleConfig = _starBlockCollection.whitelistSaleConfig();
        _collectionInfo.whitelistSaleStatus = _getSaleStatus(_collectionInfo.whitelistSaleConfig);
        _collectionInfo.whitelistAmount = _starBlockCollection.whitelistAmount();

        _collectionInfo.publicSaleConfig = _starBlockCollection.publicSaleConfig();
        _collectionInfo.publicSaleStatus = _getSaleStatus(_collectionInfo.publicSaleConfig);
        
        if(_user != address(0)){
            _userInfo.inWhitelist = _starBlockCollection.whitelist(_user);
            if(_userInfo.inWhitelist){
                _userInfo.canMintAmountWhitelistSale = _collectionInfo.whitelistSaleConfig.maxAmountPerAddress - _starBlockCollection.whitelistSaleMinted(_user);
            }
            _userInfo.canMintAmountPublicSale = _collectionInfo.publicSaleConfig.maxAmountPerAddress - _starBlockCollection.publicSaleMinted(_user);
        }
    }

    // sale status: 1 - not set; 2 - not started; 3 - started and not end; 4 - ended;
    function _getSaleStatus(IStarBlockCollection.SaleConfig memory _saleConfg) internal view returns (uint256 _status) {
        if(_saleConfg.startTime == 0){
            _status = 1;
        }else if(_saleConfg.startTime > block.timestamp){
            _status = 2;
        }else if(_saleConfg.endTime == 0 || (_saleConfg.endTime > 0 && _saleConfg.endTime >= block.timestamp)){
            _status = 3;
        }else{
            _status = 4;
        }
    }
    
    function userCanMint(IStarBlockCollection _starBlockCollection, address _user, uint256 _amount) external view returns (
                        bool _whitelistSaleCanMint, string memory _whitelistSaleMessage, bool _publicSaleCanMint, string memory _publicSaleMessage) {
        require(address(_starBlockCollection) != address(0), "StarBlockCollectionUtils: _starBlockCollection can not be zero!");
        require(_user != address(0), "StarBlockCollectionUtils: _user can not be zero!");
        
        uint256 userCanMintTotalAmount = _starBlockCollection.userCanMintTotalAmount();
        if(userCanMintTotalAmount == 0){
            _whitelistSaleCanMint = false;
            _whitelistSaleMessage = "Can not mint: reach max supply!";

            _publicSaleCanMint = false;
            _publicSaleMessage = _whitelistSaleMessage;
        }else{
            _whitelistSaleCanMint = true;
            IStarBlockCollection.SaleConfig memory whitelistSaleConfig = _starBlockCollection.whitelistSaleConfig();
            if(whitelistSaleConfig.startTime == 0){
                _whitelistSaleCanMint = false;
                _whitelistSaleMessage = "Can not mint: no whitelist sale was set!";
            }else if(whitelistSaleConfig.startTime > block.timestamp){
                _whitelistSaleCanMint = false;
                _whitelistSaleMessage = "Can not mint: whitelist sale has not started!";
            }else if(whitelistSaleConfig.endTime > 0 && whitelistSaleConfig.endTime < block.timestamp){
                _whitelistSaleCanMint = false;
                _whitelistSaleMessage = "Can not mint: whitelist sale has ended!";
            }else if(!_starBlockCollection.whitelist(_user)){
                _whitelistSaleCanMint = false;
                _whitelistSaleMessage = "Can not mint: not in whitelist!";
            }else if((_starBlockCollection.whitelistSaleMinted(_user) + _amount) > whitelistSaleConfig.maxAmountPerAddress){
                _whitelistSaleCanMint = false;
                _whitelistSaleMessage = string(abi.encodePacked("Can not mint: whitelist sale only left ", 
                                        (whitelistSaleConfig.maxAmountPerAddress - _starBlockCollection.whitelistSaleMinted(_user))));
            }
            
            _publicSaleCanMint = true;
            IStarBlockCollection.SaleConfig memory publicSaleConfig = _starBlockCollection.publicSaleConfig();
            if(publicSaleConfig.startTime == 0){
                _publicSaleCanMint = false;
                _publicSaleMessage = "Can not mint: no public sale was set!";
            }else if(publicSaleConfig.startTime > block.timestamp){
                _publicSaleCanMint = false;
                _publicSaleMessage = "Can not mint: public sale has not started!";
            }else if(publicSaleConfig.endTime > 0 && publicSaleConfig.endTime < block.timestamp){
                _publicSaleCanMint = false;
                _publicSaleMessage = "Can not mint: public sale has ended!";
            }else if((_starBlockCollection.publicSaleMinted(_user) + _amount) > publicSaleConfig.maxAmountPerAddress){
                _publicSaleCanMint = false;
                _publicSaleMessage = string(abi.encodePacked("Can not mint: public sale only left ", 
                                        (publicSaleConfig.maxAmountPerAddress - _starBlockCollection.publicSaleMinted(_user))));
            }
        }
    }
}