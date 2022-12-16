/**
 *Submitted for verification at Etherscan.io on 2022-12-15
*/

/**
 *Submitted for verification at BscScan.com on 2022-11-07
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract Ownable  {
    address payable public _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor ()  {
        _owner = payable(msg.sender);
        emit OwnershipTransferred(address(0), msg.sender);
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
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }


    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address payable newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface Token {
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function balanceOf(address who) external view returns (uint256);
    function approve(address spender, uint256 value) external returns (bool);

}

/**
 * @title TokenPresale
 * TokenPresale allows investors to make
 * token purchases and assigns them tokens based
 * on a token per ETH rate. Funds collected are forwarded to a wallet
 * as they arrive.
 */

contract REMPresale is Ownable {

    address public TokenAddress;
    address public wallet;

    uint256 public weiRaised;
    uint256 public cap;
    uint256 public minInvestment;
    uint256 public maxInvestment;
    uint256 public rate;

    bool public isFinalized;
    bool public presaleEnabled = false;

    string public contactInformation;

    event TokenDeposited(address indexed beneficiary, uint amount);

    /*
     * crowdsale constructor
     * @param _wallet who receives invested ether
     * @param _minInvestment is the minimum amount of ether that can be sent to the contract
     * @param _maxInvestment is the minimum amount of ether that can be sent to the contract
     * @param _cap above which the crowdsale is closed
     * @param _rate is the amounts of tokens given for 1 ether
     */

    constructor() {
        //TokenAddress = 0xdA524d01298dd9605Dd1C66a4b2d8885b05A46C9;
        TokenAddress = 0x53d43Fc68ab3d47b93e506841d39dA1f3f34D875;//testing


        wallet = 0x944401AB4aaa3F6aFee6c25d89F6a6130B3EE0D2;
        rate = 25000; // 1 BNB = 25k REM
        minInvestment = 1 * (10**17); // 0.1 BNB
        maxInvestment = 100 * (10**18); // 100 BNB
        cap = 25000 * (10**18); // 25k BNB
    }

    /*
     * event for token purchase logging
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
     * event for signaling finished crowdsale
     */
    event Finalized();

    // fallback function to buy tokens
    receive() external payable {
        buyTokens(msg.sender);
    }

    /**
     * Low level token purchse function
     * @param beneficiary will recieve the tokens.
     */
    function buyTokens(address beneficiary) public payable {
        require(presaleEnabled);
        require(beneficiary != address(0));
        require(msg.value >= minInvestment, "The enter amount is below minimum");
        require(msg.value <= maxInvestment, "The enter amount is above maximum");
        require((weiRaised + msg.value) * rate <= cap, "Greater that cap");
        
        uint256 weiAmount = msg.value;
        uint256 tokens = weiAmount * rate;

        require(Token(TokenAddress).balanceOf(address(this))>=tokens, "Not Enoughf token for presale");
        // update weiRaised
        weiRaised = weiRaised + weiAmount;
        // compute amount of tokens created
        

        

        Token(TokenAddress).transfer(msg.sender, tokens);
        emit TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);
        // forwardFunds();
    }

    // send ether to the fund collection wallet
    function forwardFunds() internal {
        payable(wallet).transfer(msg.value);
    }

    //allow owner to finalize the presale once the presale is ended
    function finalize() public onlyOwner {
        require(!isFinalized);
        require(hasEnded());

        emit Finalized();

        isFinalized = true;
    }

    function setContactInformation(string memory info) public onlyOwner {
        contactInformation = info;
    }

    //return true if crowdsale event has ended
    function hasEnded() public view returns (bool) {
        bool capReached = (weiRaised * rate >= cap);
        return capReached;
    }

    function updateTokenContribution(uint256 _rate, uint256 _minInvestment, uint256 _maxInvestment, uint256 _cap) public onlyOwner {
        require(!presaleEnabled, "Can't update after starting");
        rate = _rate;
        minInvestment = _minInvestment;
        maxInvestment = _maxInvestment;
        cap = _cap;
    }

    /* Withdraw Stuck BNB */
    function withdrawCrypto(address payable beneficiary) public onlyOwner {
        beneficiary.transfer(address(this).balance);
    }

    /* Withdraw Remaining token after sale */
    function withdrawTokens(address beneficiary) public onlyOwner {
        require(Token(TokenAddress).transfer(beneficiary, Token(TokenAddress).balanceOf(address(this))));
    }

    function depositTokens(uint256  _amount) public returns (bool) {
        require(_amount <= Token(TokenAddress).balanceOf(msg.sender), "Token Balance of user is less");
        require(Token(TokenAddress).transferFrom(msg.sender,address(this), _amount));
        emit TokenDeposited(msg.sender, _amount);
        return true;
    }

    function startPresale() public onlyOwner {
        require(!presaleEnabled, "Presale already started");
        presaleEnabled = true;
    }
}