// SPDX-License-Identifier: GPL-3.0

/**
 * @Author Vron
 */

pragma solidity >=0.7.0 <0.9.0;
import "./SafeMath.sol";

interface Tokens {
    function balanceOf(address _address) external returns (uint256);
    function decimals() external view returns (uint8);
    function transfer(address _address, uint256 value) external returns (bool);
    function transferFrom(address _sender,address recipient,uint256 value) external returns (bool);
}

interface Context{
    function onlyOwner(address _address) external view;
    function onlyAdmin(address _address) external view;
    function isMarketCreationPaused() external view;
    function isPlatformActive() external view;
    function isBettingPaused() external view;
    function isPointEarningPaused() external view;
}

contract Point {
    using SafeMath for uint256;

    // map indicates if user locked funds for validation point
    mapping(address => bool) private _lock_validator_address;
    // map sets wallet lock time
    mapping(address => uint256) private _validator_wallet_lock_time;
    // maps amount user locked
    mapping(address => uint256) private _validator_lock_amount;
    // maps user wallet to points earned
    mapping(address => uint256) private _wallet_validation_points;
    // maps listed token name to address
    mapping(string => address) private tokenAddress;
    // maps listed token address to name
    mapping(address => string) private tokenName;
    // maps token address to its listed outcome
    mapping(address => bool) private isListed;
    // maps user address to probable token that was locked
    mapping(address => mapping(address => bool)) private userTokenLocked;
    // maps user to token they locked
    mapping(address => address) private currentlyLockedToken;
    // maps listed token array index to token name
    mapping(string => uint256) private tokenIndex;

    Context private context_address;
    address private BETS = 0x7feA2057534B4AF90D0f71a23899254a46FC2454;
    address private platform_address;
    string[] private listedTokens;
    uint256 decimal_eighteen_diff = 1000000000000000000;
    uint256 decimal_nine_diff = 1000000000;
    uint256 BETS_decimal = 100000000;

    constructor(address _context){
        
        context_address = Context(address(_context));
    }

    /**
     * @dev function changes BET contract address
    */
    function changeBETContractAsddress(address _address)
        external
        returns (bool)
    {
        context_address.onlyOwner(msg.sender);
        BETS = address(_address);
        return true;
    }

    /**
     * @dev function calculates the difficulty
    */
    function getDifficulty(address userAddress) 
        internal
        view
        returns (uint256)
    {
        address token = currentlyLockedToken[userAddress];
        uint256 difficulty = 0;
        if(token == BETS){
            difficulty = BETS_decimal;
        }
        else if(Tokens(address(token)).decimals() == 18){
            difficulty = decimal_eighteen_diff;
        } else if (Tokens(address(token)).decimals() == 9) {
            difficulty =  decimal_nine_diff;
        } else {
            difficulty = decimal_eighteen_diff;
        }

        return difficulty;
    }

    /**
     * @dev function calculates the users validation points
     * and rewards him his validation point.
     * function is triggered once user logs in
     */
    function _calculateValidationPoint(address userAddress) internal {
        // check if wallet has any amount locked
        require(
            _lock_validator_address[userAddress] == true,
            "WDEP"
        );
        _wallet_validation_points[userAddress] = _wallet_validation_points[
            userAddress
        ].add(
              ((_validator_lock_amount[userAddress] / 100) *
                    (currentTime() -
                        _validator_wallet_lock_time[userAddress])) / getDifficulty(userAddress)); // calculate points earned
        _validator_wallet_lock_time[userAddress] = currentTime(); // reset validation point timer
    }

    /**
     *@dev function changes the address for the SBETS token contract
    */
    function changeTokenInfo(string memory _tokenName, address _tokenAddress) 
        external 
        returns (bool)
    {
        context_address.onlyAdmin(msg.sender);
        require(isListed[_tokenAddress] == true, "TNL");
        context_address.onlyOwner(msg.sender);
        tokenAddress[_tokenName] = _tokenAddress;
        tokenName[_tokenAddress] = _tokenName;
        return true;
    }

    /**
     * @dev function adds a new token
    */
    function _addToken(address _tokenAddress, string memory _tokenName)
        external
        returns (bool)
    {
        context_address.onlyAdmin(msg.sender);
        // check for TAL
        if(isListed[_tokenAddress] == true){
            revert("TAL");
        }

        // add token
        tokenName[_tokenAddress] = _tokenName;
        tokenAddress[_tokenName] = _tokenAddress;
        isListed[_tokenAddress] = true;
        listedTokens.push(_tokenName);
        tokenIndex[_tokenName] = listedTokens.length - 1;
        return true;
    }

    /**
     * @dev function removes an already listed tokenm
    */
    function removeToken(address _tokenAddress, string memory _tokenName)
        external
        returns (bool)
    {
        context_address.onlyAdmin(msg.sender);
        if(isListed[_tokenAddress] == false){
            revert("TNL");
        }
        delete tokenName[_tokenAddress];
        delete tokenAddress[_tokenName];
        isListed[_tokenAddress] = false;
        listedTokens[tokenIndex[_tokenName]] = listedTokens[listedTokens.length - 1];
        listedTokens.pop();
        return true;
    }

    /**
     * @dev function gets the user currently locked token
    */
    function getCurrentlyLockedToken(address _wallet_address)
        external
        view
        returns (string memory)
    {
        return tokenName[currentlyLockedToken[_wallet_address]];
    }

    /**
     *@dev functiion returns the addr of the SBETS token
    */
    function getListedTokens()
        external view
        returns (string[] memory)
    {
        return listedTokens;   
    }

    /**
    * @dev function returns the token address
    * Requirement
    * [token name]
    */
    function getTokenAddress(string memory _tokenName)
        external
        view
        returns (address)
    {
        return tokenAddress[_tokenName];
    }

     /**
    * @dev function returns the token name
    * Requirement
    * [token address]
    */
    function getTokenName(address _tokenAddress)
        external
        view
        returns (string memory)
    {
        return tokenName[_tokenAddress];
    }
    

    /**
     *@dev function changes the address for the Context contract
    */
    function changeContextContractAddress(address _contextAddress) 
        external 
        returns (bool) 
    {
        context_address.onlyOwner(msg.sender);
        context_address = Context(address(_contextAddress));
        return true;
    }

    /**
     *@dev function returns the addr of the Context contract
    */
    function getContextContractAddress()
        external view
        returns (address)
    {
        return address(context_address);
    }

    /**
    * @dev function returns a user's yet to be claimed validation points
    * Requirements
    * [address] must be provided and must be the address of the user whose validation points is to be gotten
    */
    function getUserPendingPoints(address _address) external view returns (uint256) {
        return (((_validator_lock_amount[_address] / 100) *
                    (currentTime() -
                        _validator_wallet_lock_time[_address])) / getDifficulty(_address));
    }

    /**
     * @dev function displays user validation points
     */
    function showValidationPoints(address _address) external view returns (uint256) {
        // return validationPoints
        return _wallet_validation_points[_address];
    }

    function claimValidationPoint(address userAddress) external returns (bool) {
        _calculateValidationPoint(userAddress);
        return true;
    }

    /**
     * @dev function rewards users validator rights through points.
     *
     * Requirement: user must have [amount] or more in wallet
     */
    function _earnValidationPoints(address token, address userAddress, uint256 amount)
        private
    {
        context_address.isPlatformActive();
        context_address.isPointEarningPaused();
        // check if user balance greater or equal to amount
        require(
            Tokens(address(token)).balanceOf(userAddress) >= amount,
            "IB."
        );
        // check if amount is zero => zero amount locking  not allowed
        require(amount != 0, "0ANA");
        // check if wallet locked tokens and new token to be locked is same as prev token
        if (_lock_validator_address[userAddress] == true && userTokenLocked[userAddress][token] != true){
            revert("Lock same token as previous");
        }
        // check if user wallet is already earning points
        if (
            _lock_validator_address[userAddress] == true &&
            _validator_lock_amount[userAddress] != 0
        ) {
            // wallect locked - check if amount specified matches balance after lock amount
            require(
                (Tokens(address(token)).balanceOf(userAddress) -
                    _validator_lock_amount[userAddress]) >= amount,
                "IB"
            );
            Tokens(address(token)).transferFrom(userAddress, address(this), amount); // transfer funds to smart contract
            _validator_lock_amount[userAddress] = _validator_lock_amount[
                userAddress
            ].add(amount);
        } else {
            // wallet not earning points - lock amount in wallet to earn points
            Tokens(address(token)).transferFrom(userAddress, address(this), amount); // transfer funds to smart contract
            userTokenLocked[userAddress][token] = true;
            _validator_wallet_lock_time[userAddress] = currentTime(); // save user lock time
            _lock_validator_address[userAddress] = true; // user wallet locked
            _validator_lock_amount[userAddress] = amount; // user amount locked
            currentlyLockedToken[userAddress] = token;
        }
    }

    /**
     * @dev function rewards users validator rights through points.
     *
     * Requirement: user must have [amount] or more in wallet
     */
    function earnValidationPoints(address token, uint256 amount) external returns (bool) {
        _earnValidationPoints(token, msg.sender, amount);
        return true;
    }

    /**
     * @dev function renounces user point earning ability
     */
    function revokeValidationPointsEarning(address token) external {
        _revokeValidationPointsEarning(token, msg.sender);
    }

    /**
     * @dev function revokes user's ability to earn validation points
     */
    function _revokeValidationPointsEarning(address token, address userAddress) internal {
        // claim user earned points and revoke user point earning
        _calculateValidationPoint(userAddress);
        // check if user is signed up for points earning
        require(
            _lock_validator_address[userAddress] == true &&
                _validator_lock_amount[userAddress] != 0,
            "WDEP"
        );
        // send locked amount back to user
        uint256 refund_amount = _validator_lock_amount[userAddress];
        _validator_wallet_lock_time[userAddress] = 0; // reset user lock time
        _lock_validator_address[userAddress] = false; // user wallet unlocked
        _validator_lock_amount[userAddress] = 0; // reset locked amount to zero
        Tokens(address(token)).transfer(userAddress, refund_amount); // send user funds back to user
        userTokenLocked[userAddress][token] = false;
        delete currentlyLockedToken[userAddress];
    }

    /**
     * @dev function gets the amount currently locked/staked by a user
     * REQUIREMENTS
     * [_address] must be provided and must be the address of the user whose stake amount want to be retrieved
    */
    function userCurrentlyLockedBETS(address _address) external view returns(uint256) {
        return _validator_lock_amount[_address];
    }

    /**
     * @dev function deducts 1000 points from the supplied address
    */
    function deductValidationPoint(address validator_address) external  {
        require(platform_address == msg.sender, "OPCA");
        _wallet_validation_points[validator_address] = _wallet_validation_points[validator_address].sub(1000);  // deduct event validation point from user point
    }

    function currentTime() internal view returns (uint256) {
        return block.timestamp;
    }

    /**
     *@dev function sets the address of the Betswamp platform
    */
    function setPlatformAddress(address _address) 
        external 
        returns (bool)
    {
        context_address.onlyOwner(msg.sender);
        platform_address = _address;
        return true;
    }

    /**
     *@dev function returns the address of the Betswamp platform
    */
    function getPlatformAddress() external view returns (address){
        return platform_address;
    }

}