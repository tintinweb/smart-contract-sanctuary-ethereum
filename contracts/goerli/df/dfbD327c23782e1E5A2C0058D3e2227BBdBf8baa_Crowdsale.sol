/**
 *Submitted for verification at Etherscan.io on 2023-01-29
*/

// File: CrowdSale.sol


pragma solidity ^0.8.17;

interface IERC20 {

    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

     /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function geUnlockTime() public view returns (uint256) {
        return _lockTime;
    }

    //Locks the contract for owner for the amount of time provided
    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = block.timestamp + time;
        emit OwnershipTransferred(_owner, address(0));
    }

    //Unlocks the contract for owner when _lockTime is exceeds
    function unlock() public virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock");
        require(block.timestamp > _lockTime , "Contract is locked until 7 days");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
}


/**
 * @title Crowdsale
 * @dev Crowdsale is a base contract for managing a token crowdsale,
 * allowing investors to purchase tokens with ether. This contract implements
 * such functionality in its most fundamental form and can be extended to provide additional
 * functionality and/or custom behavior.
 * The external interface represents the basic interface for purchasing tokens, and conform
 * the base architecture for crowdsales. They are *not* intended to be modified / overriden.
 * The internal interface conforms the extensible and modifiable surface of crowdsales. Override
 * the methods to add functionality. Consider using 'super' where appropiate to concatenate
 * behavior.
 */
contract Crowdsale is Ownable{
    // The token being sold
    IERC20 public token;

    // Address where funds are collected
    address payable public wallet;

    // Amount of wei raised
    uint256 public weiRaised;

    // Amount of tokens bought
    uint256 public tokenRaised;

    // Pause Contract
    bool public paused = false;

    // Claimable
    bool public isClaimable = false;

    // Address and amount of token in wei bought
    mapping(address => uint256) public tokenOwnership;

    // Address has claimed tokens
    mapping(address => bool) public yetToClaim;

    // Rates
    uint256[] public rateValues = [500, 400, 320, 256, 250];

    // Stages
    uint256[] public stageValues = [414*10**18, 661*10**18, 827*10**18, 3308*10**18];

    /**
     * Event for token purchase logging
     * @param purchaser who paid for the tokens
     * @param beneficiary who got the tokens
     * @param value weis paid for purchase
     * @param amount amount of tokens purchased
     */
    event TokenPurchase(
        address indexed purchaser,
        address indexed beneficiary,
        uint256 value,
        uint256 amount
    );

    /**
     * @param _token Address of the token being sold
     */
    constructor(IERC20 _token, address payable _wallet) {
        token = _token;
        wallet = _wallet;
    }

    // -----------------------------------------
    // Crowdsale external interface
    // -----------------------------------------

    /**
     * @dev fallback function ***DO NOT OVERRIDE***
     */
    fallback() external payable {
        buyTokens(msg.sender);
    }

    receive() external payable {
        buyTokens(msg.sender);
    }

    /**
     * @dev low level token purchase ***DO NOT OVERRIDE***
     * @param _beneficiary Address performing the token purchase
     */
    function buyTokens(address _beneficiary) public payable {
        require(!paused);
        require(!isClaimable);
        uint256 weiAmount = msg.value;
        _preValidatePurchase(_beneficiary, weiAmount);

        // calculate token amount to be created
        uint256 tokens = _getTokenAmount(weiAmount);

        // update wei raised
        weiRaised += weiAmount;

        // update token raised
        tokenRaised += tokens;

        //update mapping
        _setTokenOwnership(_beneficiary, weiAmount);

        emit TokenPurchase(msg.sender, _beneficiary, weiAmount, tokens);

        _updatePurchasingState(_beneficiary, weiAmount);
        _postValidatePurchase(_beneficiary, weiAmount);
        _forwardFunds();
    }

    function getCurrentRate() public view returns (uint256) {
        return _getRate(weiRaised);
    }

    function claimTokens(address _beneficiary) public payable {
        require(isClaimable);
        uint256 tokens = tokenOwnership[_beneficiary];

        _processPurchase(_beneficiary, tokens);
    }

    // -----------------------------------------
    // Internal interface (extensible)
    // -----------------------------------------

    /**
     * @dev Validation of an incoming purchase. Use require statements to revert state when conditions are not met. Use super to concatenate validations.
     * @param _beneficiary Address performing the token purchase
     * @param _weiAmount Value in wei involved in the purchase
     */
    function _preValidatePurchase(address _beneficiary, uint256 _weiAmount)
        internal
        pure
    {
        require(_beneficiary != address(0));
        require(_weiAmount != 0);
    }

    /**
     * @dev Validation of an executed purchase. Observe state and use revert statements to undo rollback when valid conditions are not met.
     * @param _beneficiary Address performing the token purchase
     * @param _weiAmount Value in wei involved in the purchase
     */
    function _postValidatePurchase(address _beneficiary, uint256 _weiAmount)
        internal
    {
        // optional override
    }

    /**
     * @dev Source of tokens. Override this method to modify the way in which the crowdsale ultimately gets and sends its tokens.
     * @param _beneficiary Address performing the token purchase
     * @param _tokenAmount Number of tokens to be emitted
     */
    function _deliverTokens(address _beneficiary, uint256 _tokenAmount)
        internal
    {
        token.transfer(_beneficiary, _tokenAmount);
        _setTokenClaiming(_beneficiary);
    }

    /**
     * @dev Executed when a purchase has been validated and is ready to be executed. Not necessarily emits/sends tokens.
     * @param _beneficiary Address receiving the tokens
     * @param _tokenAmount Number of tokens to be purchased
     */
    function _processPurchase(address _beneficiary, uint256 _tokenAmount)
        internal
    {
        _deliverTokens(_beneficiary, _tokenAmount);
    }

    /**
     * @dev Override for extensions that require an internal state to check for validity (current user contributions, etc.)
     * @param _beneficiary Address receiving the tokens
     * @param _weiAmount Value in wei involved in the purchase
     */
    function _updatePurchasingState(address _beneficiary, uint256 _weiAmount)
        internal
    {
        // optional override
    }

    /**
     * @dev Override to extend the way in which ether is converted to tokens.
     * @param _weiAmount Value in wei to be converted into tokens
     * @return Number of tokens that can be purchased with the specified _weiAmount
     */
    function _getTokenAmount(uint256 _weiAmount)
        internal
        view
        returns (uint256)
    {
        if(weiRaised <= stageValues[0]){
            return _getNumTokensBought(_weiAmount, 0);
        } else if (weiRaised > stageValues[0] && weiRaised <= stageValues[1]) {
            return _getNumTokensBought(_weiAmount, 1);
        } else if (weiRaised > stageValues[1] && weiRaised <= stageValues[2]) {
            return _getNumTokensBought(_weiAmount, 2);
        } else if (weiRaised > stageValues[2] && weiRaised <= stageValues[3]) {
            return _getNumTokensBought(_weiAmount, 3);
        } else{
            return _weiAmount * rateValues[0];
        }
    }

    /**
     * @dev Determines how ETH is stored/forwarded on purchases.
     */
    function _forwardFunds() internal {
        wallet.transfer(msg.value);
    }

    function _getNumTokensBought(uint256 _weiAmount, uint8 _p) internal view returns (uint256) {
        if(weiRaised + _weiAmount >= stageValues[_p]) {
            uint256 beforeAmt = stageValues[_p] - weiRaised;
            uint256 prevStage = beforeAmt * rateValues[_p];
            uint256 afterAmt = (_weiAmount + weiRaised) - stageValues[_p];
            uint256 nextStage = afterAmt * rateValues[_p+1];
            uint256 totalAmt = prevStage + nextStage;
            return totalAmt;
        }else{
            return _weiAmount * rateValues[0];
        }
    }
    function _getRate(uint256 _weiAmount) internal view returns (uint256) {
        if (_weiAmount <= stageValues[0]) {
            return rateValues[0];
        } else if (_weiAmount > stageValues[0] && _weiAmount <= stageValues[1]) {
            return rateValues[1];
        } else if (_weiAmount > stageValues[1] && _weiAmount <= stageValues[2]) {
            return rateValues[2];
        } else if (_weiAmount > stageValues[2] && _weiAmount <= stageValues[3]) {
            return rateValues[3];
        } else {
            return rateValues[4];
        }
    }

    function _setTokenOwnership(address _user, uint256 _amount) internal {
        if(tokenOwnership[_user] > 0){
            tokenOwnership[_user] += _amount;
        }else{
            tokenOwnership[_user] = _amount;
        }
        yetToClaim[_user] = true;
    }

    function _setTokenClaiming(address _user) internal {
        delete tokenOwnership[_user];
        delete yetToClaim[_user];
    }

    //only owner
    function pause(bool _state) public onlyOwner {
        paused = _state;
    }

    function setClaimable(bool _state) public onlyOwner {
        isClaimable = _state;
    }
    
    function withdraw() public payable onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }
}