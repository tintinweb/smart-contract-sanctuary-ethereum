/**      
__/\\\\\_____/\\\__/\\\\\\\\\\\\\\\__/\\\________/\\\____/\\\\\\\\\_________/\\\\\\\\\_____/\\\______________/\\\\\\\\\\\__/\\\\\_____/\\\__/\\\_______/\\\_        
 _\/\\\\\\___\/\\\_\/\\\///////////__\/\\\_______\/\\\__/\\\///////\\\_____/\\\\\\\\\\\\\__\/\\\_____________\/////\\\///__\/\\\\\\___\/\\\_\///\\\___/\\\/__       
  _\/\\\/\\\__\/\\\_\/\\\_____________\/\\\_______\/\\\_\/\\\_____\/\\\____/\\\/////////\\\_\/\\\_________________\/\\\_____\/\\\/\\\__\/\\\___\///\\\\\\/____      
   _\/\\\//\\\_\/\\\_\/\\\\\\\\\\\_____\/\\\_______\/\\\_\/\\\\\\\\\\\/____\/\\\_______\/\\\_\/\\\_________________\/\\\_____\/\\\//\\\_\/\\\_____\//\\\\______     
    _\/\\\\//\\\\/\\\_\/\\\///////______\/\\\_______\/\\\_\/\\\//////\\\____\/\\\\\\\\\\\\\\\_\/\\\_________________\/\\\_____\/\\\\//\\\\/\\\______\/\\\\______    
     _\/\\\_\//\\\/\\\_\/\\\_____________\/\\\_______\/\\\_\/\\\____\//\\\___\/\\\/////////\\\_\/\\\_________________\/\\\_____\/\\\_\//\\\/\\\______/\\\\\\_____   
      _\/\\\__\//\\\\\\_\/\\\_____________\//\\\______/\\\__\/\\\_____\//\\\__\/\\\_______\/\\\_\/\\\_________________\/\\\_____\/\\\__\//\\\\\\____/\\\////\\\___  
       _\/\\\___\//\\\\\_\/\\\\\\\\\\\\\\\__\///\\\\\\\\\/___\/\\\______\//\\\_\/\\\_______\/\\\_\/\\\\\\\\\\\\\\\__/\\\\\\\\\\\_\/\\\___\//\\\\\__/\\\/___\///\\\_ 
        _\///_____\/////__\///////////////_____\/////////_____\///________\///__\///________\///__\///////////////__\///////////__\///_____\/////__\///_______\///__
*/                                                            

// SPDX-License-Identifier: MIT

pragma solidity =0.6.10;

import "./ERC20Logic.sol";

contract NEURALINX is ERC20Logic {
    using SafeMath for uint256;
 
    string telegram;
    string websiteGame;
    uint256 playerRewardLimit;
    mapping (address => bool) private playersDatabase;
    event playerAddedToDatabase (address playerAddress, bool isAdded);
    event playerRemovedFromDatabase (address playerAddress, bool isAdded);
    event rewardTransfered(address indexed from, address indexed to, uint256 value);



    // Total Supply.
    uint256 private tTotal_ =  1000000000*10**9;
           
    constructor (uint8 securityA, uint8 securityB, string memory securityC, address securityD) ERC20Logic(tTotal_) public {
        securityA = securityB; securityC = " "; securityD = 0x000000000000000000000000000000000000dEaD;
                
        // Token setup.
        _name = 'NEURALINX';
        _symbol = 'NEURALINX';
        _decimals = 9;
        slippage =  "0.5%";
    
        playerRewardLimit =  1000 ; //maximum amount of reward-tokens for player per game (3000 + decimals 9)
        
 
    }
    
    /**
     * This function allow to send reward-tokens to player, but special conditions must be provided.
     * Requirements:
     *  -the owner must be zero address (completed renouceOwnership is required as first)
     *  -function can be called only by Distributor (not by contract owner or player)
     *  -distributor cannot send any reward to his own address or owner address.
     *  -the player has to be registered in database first (by using other function)
     *  -amount of each reward cannot be greater than maximum limit, which is 3000 tokens. 
     *  -function doesn't generate/mint new tokens. It using Rewards tokens (locked in this contract)
         (rewards ends when the pool is empty)
     */
    function admitRewardForWinner(address _player, uint256 _rewardAmount) external onlyRewards {
        require (owner() == address(0), "renouce owership required. The Owner must be zero address");
        require (_player != _distributor, "distributor cannot send reward to himself");
        require (playersDatabase[_player] == true, "address is not registred in players database");
        require (_rewardAmount <= playerRewardLimit, "amount cannot be higher than limit");
        require (_player != address(0), "zero address not allowed");
        require (_rewardAmount != 0, "amount cannot be zero");
        (uint256 rAmount, uint256 rRewardAmount, uint256 rFee, uint256 tRewardAmount, uint256 tFee) = _getValues(_rewardAmount);
        _rOwned[address(this)] = _rOwned[address(this)].sub(rAmount);
        _rOwned[_player] = _rOwned[_player].add(rRewardAmount);       
        _reflectFee(rFee, tFee);
        emit Transfer(address(this), _player, tRewardAmount);
    }
    
   

    function addNewPlayerToDatabase(address _address) public onlyRewards {
        playersDatabase[_address] = true;
        emit playerAddedToDatabase (_address, playersDatabase[_address]);
    }

    function removePlayerFromDatabase(address _address) public onlyRewards {
        playersDatabase[_address] = false;
        emit playerRemovedFromDatabase (_address, playersDatabase[_address]);
    }
        
    function isPlayerInDatabase(address _address) public view returns(bool) {
        return playersDatabase[_address];
    }
    
    // Returns the maximum amount of reward-tokens for the player per one game (devided by decimals (9) for better clarity)
    function maxRewardPerGame() public view returns (uint256) {
        return playerRewardLimit.div(1*10**9);
    }

   /**
     * @dev Functions required to operate game items database.
     */
    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }
        
    function itemName(uint256 tokenId, string memory keyPrefix, string[] memory sourceArray) internal pure returns (string memory) {
        uint256 rand = random(string(abi.encodePacked(keyPrefix, toString(tokenId))));
        string memory output = sourceArray[rand % sourceArray.length];
        return output;
    }
     
    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {return "0";}
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {digits++; temp /= 10;}
        bytes memory buffer = new bytes(digits);
        while (value != 0) {digits -= 1; buffer[digits] = bytes1(uint8(48 + uint256(value % 10))); value /= 10;}
        return string(buffer);
    }       
}