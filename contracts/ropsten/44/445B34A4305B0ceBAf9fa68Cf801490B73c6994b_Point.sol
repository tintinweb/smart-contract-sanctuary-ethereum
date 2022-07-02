// SPDX-License-Identifier: GPL-3.0

/**
 * @Author Vron
 */

pragma solidity >=0.7.0 <0.9.0;
import "./SafeMath.sol";

interface SBETS {
    function balanceOf(address _address) external returns (uint256);

    function transfer(address _address, uint256 value) external returns (bool);

    function transferFrom(
        address _sender,
        address recipient,
        uint256 value
    ) external returns (bool);
}

interface Context{
    function onlyOwner(address _address) external view;
    function onlyAdmin(address _address) external view;
    function isMarketCreationPaused() external view;
    function isPlatformActive() external view;
    function isBettingPaused() external view;
    function isPointEarningPaused() external view;
    function _calculateValidatorsNeeded(uint256 _value) external pure returns (uint256);
    function getSystemRewardAddress() external view returns (address);
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

    SBETS private SBETS_token;
    Context private context_address;
    address private platform_address;

    constructor(address bets_token, address _context){
        SBETS_token = SBETS(address(bets_token));
        context_address = Context(address(_context));
    }

    /**
     * @dev function calculates the users validation points
     * and rewards him his validation point.
     * function is triggered once user logs in
     */
    function _calculateValidationPoint() internal {
        // check if wallet has any amount locked
        require(
            _lock_validator_address[msg.sender] == true,
            "WDEP"
        );
        _wallet_validation_points[msg.sender] = _wallet_validation_points[
            msg.sender
        ].add(
              ((_validator_lock_amount[msg.sender] / 100) *
                    (currentTime() -
                        _validator_wallet_lock_time[msg.sender])) / 1000000000000000000); // calculate points earned
        _validator_wallet_lock_time[msg.sender] = currentTime(); // reset validation point timer
    }

    /**
     *@dev function changes the address for the SBETS token contract
    */
    function changeSBETSContractAddress(address _tokenAddress) 
        external 
        returns (bool)
    {
        context_address.onlyOwner(msg.sender);
        SBETS_token = SBETS(address(_tokenAddress));
        return true;
    }

    /**
     *@dev functiion returns the addr of the SBETS token
    */
    function getSBETSContractAddress()
        external view
        returns (address)
    {
        return address(SBETS_token);   
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
                        _validator_wallet_lock_time[_address])) / 1000000000000000000);
    }

    /**
     * @dev function displays user validation points
     */
    function showValidationPoints(address _address) external view returns (uint256) {
        // return validationPoints
        return _wallet_validation_points[_address];
    }

    function claimValidationPoint() external returns (bool) {
        _calculateValidationPoint();
        return true;
    }

    /**
     * @dev function rewards users validator rights through points.
     *
     * Requirement: user must have [amount] or more in wallet
     */
    function _earnValidationPoints(address userAddress, uint256 amount)
        private
    {
        context_address.isPlatformActive();
        context_address.isPointEarningPaused();
        // check if user balance greater or equal to amount
        require(
            SBETS_token.balanceOf(userAddress) >= amount,
            "IB."
        );
        // check if amount is zero => zero amount locking  not allowed
        require(amount != 0, "0ANA");
        // check if user wallet is already earning points
        if (
            _lock_validator_address[userAddress] == true &&
            _validator_lock_amount[userAddress] != 0
        ) {
            // wallect locked - check if amount specified matches balance after lock amount
            require(
                (SBETS_token.balanceOf(userAddress) -
                    _validator_lock_amount[userAddress]) >= amount,
                "IB"
            );
            SBETS_token.transferFrom(userAddress, address(this), amount); // transfer funds to smart contract
            _validator_lock_amount[userAddress] = _validator_lock_amount[
                userAddress
            ].add(amount);
        } else {
            // wallet not earning points - lock amount in wallet to earn points
            SBETS_token.transferFrom(userAddress, address(this), amount); // transfer funds to smart contract
            _validator_wallet_lock_time[userAddress] = currentTime(); // save user lock time
            _lock_validator_address[userAddress] = true; // user wallet locked
            _validator_lock_amount[userAddress] = amount; // user amount locked
        }
    }

    /**
     * @dev function rewards users validator rights through points.
     *
     * Requirement: user must have [amount] or more in wallet
     */
    function earnValidationPoints(uint256 amount) external returns (bool) {
        _earnValidationPoints(msg.sender, amount);
        return true;
    }

    /**
     * @dev function renounces user point earning ability
     */
    function revokeValidationPointsEarning() external {
        _revokeValidationPointsEarning(msg.sender);
    }

    /**
     * @dev function revokes user's ability to earn validation points
     */
    function _revokeValidationPointsEarning(address userAddress) internal {
        // claim user earned points and revoke user point earning
        _calculateValidationPoint();
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
        SBETS_token.transfer(userAddress, refund_amount); // send user funds back to user
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