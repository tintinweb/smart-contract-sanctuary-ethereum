// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./ERC721.sol";
import "./IERC721A.sol";

/// @title A contract to burn Jcode Evos during specific windows (0x06Af6dD59354a40358091B9644DB7A72B3A2297d)
/// @author @smartcontrart
/// @notice The contract allows to open and close burn windows with some options (change burn address, limit the number of burns per window)
/// @dev The contract uses a transfer to 0xDead as the proxy implementation didn't implement the burn function.

contract EvosBurnContract {
    bool public burnOpened;
    uint256 public burnLimit;
    uint256 public currentBurnWindow;
    address public burnAddress;
    address public evoAddress;

    mapping (address => bool) public isAdmin;
    mapping (address => mapping (uint256 => uint256)) public burnPerWindow; // Evo Owner to burn Window ID to quantity burnt
    
    constructor(){
        burnAddress = 0x000000000000000000000000000000000000dEaD;
        isAdmin[msg.sender] = true;
        currentBurnWindow = 0;
        evoAddress = 0x06Af6dD59354a40358091B9644DB7A72B3A2297d;
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

    function setEvoAddress(address _evoAddress) external adminOnly{
        evoAddress = _evoAddress;
    }

    function setBurnLimit(uint256 _burnLimit) external adminOnly{
        burnLimit = _burnLimit;
    }

    function setNewBurnWindow(address _burnAddress, uint256 _burnLimit, bool _startsImmediately) external adminOnly{
        burnAddress = _burnAddress;
        burnLimit = _burnLimit;
        burnOpened = _startsImmediately;
        currentBurnWindow ++;
    }

    function updateCurrentBurnWindow(address _burnAddress, uint256 _burnLimit, bool _isOpened) external adminOnly{
        burnAddress = _burnAddress;
        burnLimit = _burnLimit;
        burnOpened = _isOpened;
    }

    function getBurnByAddress(address collector) external view returns(uint){
        return burnPerWindow[collector][currentBurnWindow];
    }

    function burn(uint256 tokenId)external{
        require(burnOpened, "Burn currently closed");
        if(burnLimit > 0){
            require(burnPerWindow[msg.sender][currentBurnWindow] < burnLimit, 'Maximum number of tokens already burnt for this window');
            burnPerWindow[msg.sender][currentBurnWindow] ++;
        }
        IERC721A(evoAddress).safeTransferFrom(
            msg.sender, 
            burnAddress, 
            tokenId
        );
    }


}