// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./ERC721.sol";
import "./IERC721A.sol";

/// @title A contract to burn NFTs during specific windows
/// @author @smartcontrart
/// @notice The contract allows to open and close burn windows with some options (change burn address, limit the number of burns per window)
/// @dev The contract uses a transfer to 0xDead as the proxy implementation didn't implement the burn function.

contract JcodeBurnContract {
    bool public burnOpened;
    uint256 public burnLimitPerCollector;
    uint256 public totalBurnLimit;
    uint256 public currentBurnWindow;
    address public burnAddress;
    address public nftAddress;

    mapping (address => bool) public isAdmin;
    mapping (address => mapping (uint256 => uint256)) public burnPerWindow; // Evo Owner to burn Window ID to quantity burnt
    mapping (uint256 => uint256) public currentBurntForWindow;
    
    constructor(){
        burnAddress = 0x000000000000000000000000000000000000dEaD;
        isAdmin[msg.sender] = true;
        currentBurnWindow = 0;
        nftAddress = 0x06Af6dD59354a40358091B9644DB7A72B3A2297d;
    }
    
    modifier adminOnly(){
        require(isAdmin[msg.sender], 'Only admins can calll this functiono');
        _;
    }

    function toggleAdmin(address _admin) external adminOnly{
        isAdmin[_admin] = !isAdmin[_admin];
    }

    function setBurnAdress(address _burnAddress) external adminOnly{
        burnAddress = _burnAddress;
    }

    function toggleBurnOpened() external adminOnly{
        burnOpened = !burnOpened;
    }

    function setNFTAddress(address _nftAddress) external adminOnly{
        nftAddress = _nftAddress;
    }

    function setBurnLimitPerCollector(uint256 _burnLimitPerCollector) external adminOnly{
        burnLimitPerCollector = _burnLimitPerCollector;
    }

    function setNewBurnWindow(address _burnAddress, uint256 _burnLimitPerCollector, uint256 _maxBurnNumber, bool _startsImmediately) external adminOnly{
        currentBurnWindow ++;
        burnAddress = _burnAddress;
        burnLimitPerCollector = _burnLimitPerCollector;
        burnOpened = _startsImmediately;
        totalBurnLimit = _maxBurnNumber;
        currentBurntForWindow[currentBurnWindow] = 0;
    }

    function updateCurrentBurnWindow(address _burnAddress, uint256 _burnLimitPerCollector, uint256 _maxBurnNumber, bool _isOpened) external adminOnly{
        burnAddress = _burnAddress;
        burnLimitPerCollector = _burnLimitPerCollector;
        totalBurnLimit = _maxBurnNumber;
        burnOpened = _isOpened;
    }

    function getBurnByAddress(address collector) external view returns(uint){
        return burnPerWindow[collector][currentBurnWindow];
    }

    function getRemainingBurnsForCurrentWindow() external view returns(uint){
        return totalBurnLimit - currentBurntForWindow[currentBurnWindow];
    }

    function setMaxBurnLimit(uint256 _totalBurnLimit) external adminOnly{
        totalBurnLimit = _totalBurnLimit;
    }

    function burn(uint256 tokenId)external{
        require(burnOpened, "Burn currently closed");
        if(totalBurnLimit > 0){
            require(currentBurntForWindow[currentBurnWindow] < totalBurnLimit, "Max burn number reached");
        }
        if(burnLimitPerCollector > 0){
            require(burnPerWindow[msg.sender][currentBurnWindow] < burnLimitPerCollector, 'Maximum number of tokens already burnt for this window');
        }
        currentBurntForWindow[currentBurnWindow] ++;
        burnPerWindow[msg.sender][currentBurnWindow] ++;
        IERC721A(nftAddress).safeTransferFrom(
            msg.sender, 
            burnAddress, 
            tokenId
        );
    }


}